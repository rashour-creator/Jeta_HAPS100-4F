//import uvm_pkg::*;

//typedef enum bit {SIDE_B, SIDE_A} components_side_e;
`timescale 1ps/1ps
module ddr4_rdimm_wrapper #(
			    parameter MC_DQ_WIDTH = 16, // Memory DQ bus width
			    parameter MC_DQS_BITS = 4, // Number of DQS bits
			    parameter MC_DM_WIDTH = 4, // Number of DM bits
			    parameter MC_CKE_NUM = 1, // Number of CKE outputs to memory
			    parameter MC_ODT_WIDTH = 1, // Number of ODT pins
			    parameter MC_ABITS = 18, // Number of Address bits
			    parameter MC_BANK_WIDTH = 2, // Memory Bank address bits
			    parameter MC_BANK_GROUP = 2, // Memory Bank Groups
			    parameter MC_CS_NUM = 1, // Number of unique CS output to Memory
			    parameter MC_RANKS_NUM = 1, // Number of Ranks
			    parameter NUM_PHYSICAL_PARTS = 4, // Number of SDRAMs in a Single Rank
			    parameter CALIB_EN = "NO", // When is set to "YES" ,R2R and FBT delays will be added
			    parameter tCK = 1000, // CK clock period in ps
			    parameter tPDM = 0, // Propagation delay Timing - range= from 1000 to 1300 ps.
			    parameter MIN_TOTAL_R2R_DELAY = 150, // Parameter shows the min range of Rank to Rank delay 
			    parameter MAX_TOTAL_R2R_DELAY = 1000, // Parameter shows the max range of Rank to Rank delay 
			    parameter TOTAL_FBT_DELAY = 2700, // Total Fly-by-Topology delay
		            parameter MEM_PART_WIDTH = "x4", // Single Device width
			    parameter MC_CA_MIRROR = "OFF", // Address Mirroring "ON"/"OFF"
			    // Shows which SDRAMs are connected to side A(first half) and side B(second half) of RCD.
			    //parameter components_side_e [NUM_PHYSICAL_PARTS-1:0] SDRAM = { {(NUM_PHYSICAL_PARTS/2){SIDE_B}}, {(NUM_PHYSICAL_PARTS/2){SIDE_A}} }, // SDRAM
			    parameter DDR_SIM_MODEL = "MICRON", // "MICRON" or "DENALI" memory model
			    parameter DM_DBI = "", // Disables dm_dbi_n if set to NONE
			    parameter MC_REG_CTRL = "ON" // Implement "ON" or "OFF" the RCD in rdimm wrapper
			    )
  (
   input 		     ddr4_act_n,
   input [MC_ABITS-1:0]      ddr4_addr,
   input [MC_BANK_WIDTH-1:0] ddr4_ba,
   input [MC_BANK_GROUP-1:0] ddr4_bg,
   input 		     ddr4_par,
   input [MC_CKE_NUM-1:0]    ddr4_cke,
   input [MC_ODT_WIDTH-1:0]  ddr4_odt,
   input [MC_CS_NUM-1:0]     ddr4_cs_n,
   input 		     ddr4_ck_t,
   input 		     ddr4_ck_c,
   input 		     ddr4_reset_n,
  
   inout [MC_DM_WIDTH-1:0]   ddr4_dm_dbi_n,
   inout [MC_DQ_WIDTH-1:0]   ddr4_dq,
   inout [MC_DQS_BITS-1:0]   ddr4_dqs_t,
   inout [MC_DQS_BITS-1:0]   ddr4_dqs_c,

   inout 		     ddr4_alert_n,
  
   input 		     scl, // I2C Bus Clock
   input 		     sa0, // I2C Bus Address signals
   input 		     sa1, // I2C Bus Address signals
   input 		     sa2, // I2C Bus Address signals
   inout 		     sda, // I2C Bus Data
   input 		     bfunc, // Function pin. BFUNC=VSS for primary register, BFUNC=VDD for secondary register
   input 		     vddspd // I2C Bus power input
   );


  // Local parameters
  // input/output ports of idt_ddr4_rcd is not parameterized - they are static max values of the signals.
  // Redundants bits from idt_ddr4_rcd's signals
  localparam            RCD_ADDR_REDUNDANTS_BITS = 18 - MC_ABITS;
  localparam            RCD_BG_REDUNDANTS_BITS = 2 - MC_BANK_GROUP;
  localparam            RCD_CS_N_REDUNDANTS_BITS = 4 - MC_CS_NUM;
  localparam            RCD_CKE_REDUNDANTS_BITS = 2 - MC_CKE_NUM;
  localparam            RCD_ODT_REDUNDANTS_BITS = 2 - MC_ODT_WIDTH;
  
  //Inputs of idt_ddr4_rcd - static max values of the signals
  wire [17:0] 		  rcd_da;
  wire [1:0] 		  rcd_dbg;
  wire [3:0] 		  rcd_cs_n;
  wire [1:0] 		  rcd_dcke;
  wire [1:0] 		  rcd_dodt;
  
  // Outputs of idt_ddr4_rcd (inputs for ddr4_dimm)
  // Side A of the RCD
  wire 			  qa_act_n;
  wire [17:0] 		  qa_addr;
  wire [1:0] 		  qa_ba;
  wire [1:0] 		  qa_bg;
  wire 			  qa_par;
  wire [1:0] 		  qa_cke;
  wire [1:0] 		  qa_odt;
  wire [3:0] 		  qa_cs_n;
  // Side B of the RCD
  wire 			  qb_act_n;
  wire [17:0] 		  qb_addr;
  wire [1:0] 		  qb_ba;
  wire [1:0] 		  qb_bg;
  wire 			  qb_par;
  wire [1:0] 		  qb_cke;
  wire [1:0] 		  qb_odt;
  wire [3:0] 		  qb_cs_n;
  //  outputs of the RCD - one pair ck to each rank
  wire [7:0] 		  ck; // ck[0]->ck_c; ck[1]->ck_t
  wire 			  reset_n;

  //************** These generate blocks are valid only if MC_REG_CTRL=="ON" *********************//
  // In case ddr4_addr signal have less than 18 bits, to upper bits will be added static zeroes.
  generate
    if (MC_REG_CTRL == "ON")
      begin: addr_only_with_rcd
	if(RCD_ADDR_REDUNDANTS_BITS>0) // ddr4_addr<18
	  begin
	    assign rcd_da = {{RCD_ADDR_REDUNDANTS_BITS{1'b0}}, ddr4_addr};
	  end
	else
	  begin
	    assign rcd_da = ddr4_addr;
	  end
      end // begin: addr_only_with_rcd
  endgenerate

  // In case ddr4_bg signal have less than 2 bits, to upper bit will be added static zeroe.
  generate
    if (MC_REG_CTRL == "ON")
      begin: bg_only_with_rcd
	if(RCD_BG_REDUNDANTS_BITS>0) // ddr4_bg<2
	  begin
	    assign rcd_dbg = {{RCD_BG_REDUNDANTS_BITS{1'b0}}, ddr4_bg};
	  end
	else
	  begin
	    assign rcd_dbg = ddr4_bg;
	  end
      end // begin: bg_only_with_rcd
  endgenerate

  // In case ddr4_cs_n signal have less than 4 bits, to upper bits will be added static 1'b1.
  generate
    if (MC_REG_CTRL == "ON")
      begin: cs_n_only_with_rcd
	if(RCD_CS_N_REDUNDANTS_BITS>0) // ddr4_cs_n<4
	  begin
	    assign rcd_cs_n = {{RCD_CS_N_REDUNDANTS_BITS{1'b0}},ddr4_cs_n };
	  end
	else
	  begin
	    assign rcd_cs_n = ddr4_cs_n;
	  end
      end // begin: cs_n_only_with_rcd
  endgenerate

  // In case ddr4_cke signal have less than 2 bits, to upper bit will be added static zeroe.
  generate
    if (MC_REG_CTRL == "ON")
      begin: cke_only_with_rcd
	if(RCD_CKE_REDUNDANTS_BITS>0) // ddr4_cke<2
	  begin
	    assign rcd_dcke = {{RCD_CKE_REDUNDANTS_BITS{1'b0}}, ddr4_cke};
	  end
	else
	  begin
	    assign rcd_dcke = ddr4_cke;
	  end
      end // begin: cke_only_with_rcd
  endgenerate

  // In case ddr4_odt signal have less than 2 bits, to upper bit will be added static zeroe.
  generate
    if (MC_REG_CTRL == "ON")
      begin: odt_only_with_rcd
	if(RCD_ODT_REDUNDANTS_BITS>0) // ddr4_odt<2
	  begin
	    assign rcd_dodt = {{RCD_ODT_REDUNDANTS_BITS{1'b0}}, ddr4_odt};
	  end
	else
	  begin
	    assign rcd_dodt = ddr4_odt;
	  end
      end // begin: odt_only_with_rcd
  endgenerate
  //**********************************************************************************************//

  // Integration of the DDR4 RCD and the DDR4 DIMM
  generate
    if (MC_REG_CTRL == "ON") // RDIMM Wrapper with DDR4 RCD
      begin: rcd_enabled
	//Intergration of the RCD model
  	ddr4_rcd_model #(
			 .tCK (tCK),
			 .tPDM (tPDM),
			 .MC_CA_MIRROR (MC_CA_MIRROR)
			 )
	u_ddr4_rcd_model (
			  .BCKE (), // output
			  .BCK_c (), // output
			  .BCK_t (), // output
			  .BCOM (), // output [3:0]
			  .BODT (), // output
			  .BVREFCA (), // output
			  .CPCAP (), // output
			  .NU3 (), // output
	  
			  .QAA (qa_addr), // output [17:0]
			  .QAACT_n (qa_act_n), // output
			  .QABA (qa_ba), // output [1:0]
			  .QABG (qa_bg), // output [1:0]
			  .QAC0 (qa_cs_n[2]), // output
			  .QAC1 (qa_cs_n[3]), // output
			  .QAC2 (), // output
			  .QACKE (qa_cke), // output [1:0]
			  .QACS0_n (qa_cs_n[0]), // output
			  .QACS1_n (qa_cs_n[1]), // output
			  .QAODT (qa_odt), // output [1:0]
			  .QAPAR (qa_par), // output
	  
			  .QBA (qb_addr), // output [17:0]
			  .QBACT_n (qb_act_n), // output
			  .QBBA (qb_ba), // output [1:0]
			  .QBBG (qb_bg), // output [1:0]
			  .QBC0 (qb_cs_n[2]), // output
			  .QBC1 (qb_cs_n[3]), // output
			  .QBC2 (), // output
			  .QBCKE (qb_cke), // output [1:0]
			  .QBCS0_n (qb_cs_n[0]), // output
			  .QBCS1_n (qb_cs_n[1]), // output
			  .QBODT (qb_odt), // output [1:0]
			  .QBPAR (qb_par), // output
	  
			  .QRST_n (reset_n), // output
			  .QVREFCA (), // output
			  .Y0_c (ck[0]), // output
			  .Y0_t (ck[1]), // output
			  .Y1_c (ck[2]), // output
			  .Y1_t (ck[3]), // output
			  .Y2_c (ck[4]), // output
			  .Y2_t (ck[5]), // output
			  .Y3_c (ck[6]), // output
			  .Y3_t (ck[7]), // output
	  
			  .ALERT_n (ddr4_alert_n), // inout
			  .ERROR_IN_n (), // inout
			  .NU1 (), // inout
			  .RFU1 (), // inout
			  .SDA (sda), // inout
	  
			  .AVDD (), // input
			  .AVSS (), // input
			  .BFUNC (bfunc), // input
			  .CK_c (ddr4_ck_c), // input
			  .CK_t (ddr4_ck_t), // input
			  .DA (rcd_da), // input [17:0]
			  //.DA (ddr4_addr), // input [17:0]
			  .DACT_n (ddr4_act_n), // input
			  .DBA (ddr4_ba), // input [1:0]
			  .DBG (rcd_dbg), // input [1:0]
			  .DC0 (rcd_cs_n[2]), // input
			  .DC1 (rcd_cs_n[3]), // input
			  .DC2 (), // input
			  .DCKE (rcd_dcke), // input [1:0]
			  .DCS0_n (rcd_cs_n[0]), // input
			  .DCS1_n (rcd_cs_n[1]), // input
			  .DODT (rcd_dodt), // input [1:0]
			  .DPAR (ddr4_par), // input
			  .DRST_n (ddr4_reset_n), // input
			  .NU0 (), // input
			  .NU2 (), // input
			  .PVDD (), // input
			  .PVSS (), // input
			  .RFU0 (), // input
			  .RFU2 (), // input
			  .RFU3 (), // input
			  .SA0 (sa0), // input
			  .SA1 (sa1), // input
			  .SA2 (sa2), // input
			  .SCL (scl), // input
			  .VDD (), // input
			  .VDD1 (), // input
			  .VDDSPD (vddspd), // input
			  .VREFCA (), // input
			  .VSS (), // input
			  .VSS1 (), // input
			  .ZQCAL () // input
			  );
	
	// Integration of ddr4_dimm.v
	ddr4_dimm #(
	      	    .MC_DQ_WIDTH (MC_DQ_WIDTH),
	      	    .MC_DQS_BITS (MC_DQS_BITS),
		    .MC_DM_WIDTH (MC_DM_WIDTH),
	      	    .MC_CKE_NUM (MC_CKE_NUM),
	      	    .MC_ODT_WIDTH (MC_ODT_WIDTH),
	      	    .MC_ABITS (MC_ABITS),
	      	    .MC_BANK_WIDTH (MC_BANK_WIDTH),
	      	    .MC_BANK_GROUP (MC_BANK_GROUP),
	      	    .MC_CS_NUM (MC_CS_NUM),
	      	    .MC_RANKS_NUM (MC_RANKS_NUM),
	      	    .NUM_PHYSICAL_PARTS (NUM_PHYSICAL_PARTS),
		    .CALIB_EN (CALIB_EN),
		    .MIN_TOTAL_R2R_DELAY (MIN_TOTAL_R2R_DELAY),
		    .MAX_TOTAL_R2R_DELAY (MAX_TOTAL_R2R_DELAY),
		    .TOTAL_FBT_DELAY (TOTAL_FBT_DELAY),
	      	    .MEM_PART_WIDTH (MEM_PART_WIDTH),
	      	    .MC_CA_MIRROR (MC_CA_MIRROR),
	      	    //.SDRAM (SDRAM),
	      	    .DDR_SIM_MODEL (DDR_SIM_MODEL),
		    .DM_DBI (DM_DBI),
		    .MC_REG_CTRL (MC_REG_CTRL)
		    ) 
	u_ddr4_dimm (
	       	     .qa_act_n (qa_act_n), // input
	       	     .qa_addr (qa_addr[MC_ABITS-1:0]), // input [MC_ABITS-1:0]
	       	     .qa_ba (qa_ba[MC_BANK_WIDTH-1:0]), // input [MC_BANK_WIDTH-1:0]
	       	     .qa_bg (qa_bg[MC_BANK_GROUP-1:0]), // input [MC_BANK_GROUP-1:0]
	       	     .qa_par (qa_par), // input
	       	     .qa_cke (qa_cke[MC_CKE_NUM-1:0]), // input [MC_CKE_NUM-1:0]
	       	     .qa_odt (qa_odt[MC_ODT_WIDTH-1:0]), // input [MC_ODT_WIDTH-1:0]
	       	     .qa_cs_n (qa_cs_n[MC_CS_NUM-1:0]), // input [MC_CS_NUM-1:0]
	  
	       	     .qb_act_n (qb_act_n), // input
	       	     .qb_addr (qb_addr[MC_ABITS-1:0]), // input [MC_ABITS-1:0]
	       	     .qb_ba (qb_ba[MC_BANK_WIDTH-1:0]), // input [MC_BANK_WIDTH-1:0]
	       	     .qb_bg (qb_bg[MC_BANK_GROUP-1:0]), // input [MC_BANK_GROUP-1:0]
	       	     .qb_par (qb_par), // input
	       	     .qb_cke (qb_cke[MC_CKE_NUM-1:0]), // input [MC_CKE_NUM-1:0]
	       	     .qb_odt (qb_odt[MC_ODT_WIDTH-1:0]), // input [MC_ODT_WIDTH-1:0]
	       	     .qb_cs_n (qb_cs_n[MC_CS_NUM-1:0]), // input [MC_CS_NUM-1:0]
	  
	       	     .ck (ck[MC_CS_NUM*2-1:0]), // input [MC_CS_NUM*2-1:0]
	       	     .reset_n (reset_n), // input
	  
	       	     .dm_dbi_n (ddr4_dm_dbi_n[MC_DM_WIDTH-1:0]), // inout [MC_DQS_BITS-1:0]
	       	     .dq (ddr4_dq[MC_DQ_WIDTH-1:0]), // inout [MC_DQ_WIDTH-1:0]
	       	     .dqs_t (ddr4_dqs_t[MC_DQS_BITS-1:0]), // inout [MC_DQS_BITS-1:0]
	       	     .dqs_c (ddr4_dqs_c[MC_DQS_BITS-1:0]), // inout [MC_DQS_BITS-1:0]
		     .alert_n (ddr4_alert_n) // output
		     );
      end // block: rcd_enabled
    else // if (MC_REG_CTRL == "OFF") // RDIMM Wrapper without DDR4 RCD - in that case RDIMM Wrapper will work like UDIMM
      begin: rcd_disabled
	// Integration of ddr4_dimm.v
	ddr4_dimm #(
	      	    .MC_DQ_WIDTH (MC_DQ_WIDTH),
	      	    .MC_DQS_BITS (MC_DQS_BITS),
		    .MC_DM_WIDTH (MC_DM_WIDTH),
	      	    .MC_CKE_NUM (MC_CKE_NUM),
	      	    .MC_ODT_WIDTH (MC_ODT_WIDTH),
	      	    .MC_ABITS (MC_ABITS),
	      	    .MC_BANK_WIDTH (MC_BANK_WIDTH),
	      	    .MC_BANK_GROUP (MC_BANK_GROUP),
	      	    .MC_CS_NUM (MC_CS_NUM),
	      	    .MC_RANKS_NUM (MC_RANKS_NUM),
	      	    .NUM_PHYSICAL_PARTS (NUM_PHYSICAL_PARTS),
		    .CALIB_EN (CALIB_EN),
		    .MIN_TOTAL_R2R_DELAY(MIN_TOTAL_R2R_DELAY),
		    .MAX_TOTAL_R2R_DELAY(MAX_TOTAL_R2R_DELAY),
		    .TOTAL_FBT_DELAY (TOTAL_FBT_DELAY),
	      	    .MEM_PART_WIDTH (MEM_PART_WIDTH),
	      	    .MC_CA_MIRROR ("OFF"),
	      	   // .SDRAM ({NUM_PHYSICAL_PARTS{1'b0}}), // All of the components will be connected to side A
	      	    .DDR_SIM_MODEL(DDR_SIM_MODEL),
		    .DM_DBI (DM_DBI),
		    .MC_REG_CTRL (MC_REG_CTRL)
		    ) 
	u_ddr4_dimm (
	       	     .qa_act_n (ddr4_act_n), // input
	       	     .qa_addr (ddr4_addr), // input [MC_ABITS-1:0]
	       	     .qa_ba (ddr4_ba), // input [MC_BANK_WIDTH-1:0]
	       	     .qa_bg (ddr4_bg), // input [MC_BANK_GROUP-1:0]
	       	     .qa_par (ddr4_par), // input
	       	     .qa_cke (ddr4_cke), // input [MC_CKE_NUM-1:0]
	       	     .qa_odt (ddr4_odt), // input [MC_ODT_WIDTH-1:0]
	       	     .qa_cs_n (ddr4_cs_n), // input [MC_CS_NUM-1:0]

		     // qb_* signals are connected to static values. These signals are not used without RCD.
	       	     .qb_act_n (1'b1), // input
	       	     .qb_addr ({(MC_ABITS){1'b0}}), // input [MC_ABITS-1:0]
	       	     .qb_ba ({(MC_BANK_WIDTH){1'b0}}), // input [MC_BANK_WIDTH-1:0]
	       	     .qb_bg ({(MC_BANK_GROUP){1'b0}}), // input [MC_BANK_GROUP-1:0]
	       	     .qb_par (1'b0), // input
	       	     .qb_cke ({(MC_CKE_NUM){1'b0}}), // input [MC_CKE_NUM-1:0]
	       	     .qb_odt ({(MC_ODT_WIDTH){1'b0}}), // input [MC_ODT_WIDTH-1:0]
	       	     .qb_cs_n ({(MC_CS_NUM){1'b1}}), // input [MC_CS_NUM-1:0]
	  
	       	     .ck (ck[MC_CS_NUM*2-1:0]), // input [MC_CS_NUM*2-1:0]
	       	     .reset_n (ddr4_reset_n), // input
	  
	       	     .dm_dbi_n (ddr4_dm_dbi_n), // inout [MC_DQS_BITS-1:0]
	       	     .dq (ddr4_dq), // inout [MC_DQ_WIDTH-1:0]
	       	     .dqs_t (ddr4_dqs_t), // inout [MC_DQS_BITS-1:0]
	       	     .dqs_c (ddr4_dqs_c), // inout [MC_DQS_BITS-1:0]
		     .alert_n (ddr4_alert_n) // output
		     );

	// In case without RCD, there are replication of the incoming ddr4_ck signal
	assign ck = {(MC_CS_NUM){ddr4_ck_t, ddr4_ck_c}};
      end // block: rcd_disabled
  endgenerate


  // Check values of some parameter, Show information about SDRAM components side A/side B
  //initial
  //  begin: rdimm_initial_block

  //    // Check the correct values of parameters MC_CA_MIRROR and MC_RANKS_NUM
  //    // Note: MC_CA_MIRROR cannot be enabled when only one Rank is available.
  //    if(MC_CA_MIRROR=="YES")
  //  begin: check_number_of_ranks
  //    assert(MC_RANKS_NUM!=1)
  //      else
  //        `uvm_fatal("ddr4_rdimm_wrapper.sv",$psprintf("Incorrect values of parameters: MC_CA_MIRROR='%0s' and MC_RANKS_NUM='%0d'", MC_CA_MIRROR, MC_RANKS_NUM))
  //  end

  //    // Check the correct values of parameters MC_CKE_NUM and MC_ODT_WIDTH
  //    // Note: RCD width of each port for signals CKE and ODT is maximum two bits.
  //    if(MC_REG_CTRL=="ON")
  //  begin: check_cke_odt_signals
  //    assert( (MC_CKE_NUM<=2)&&(MC_ODT_WIDTH<=2) )
  //      else
  //        `uvm_fatal("ddr4_rdimm_wrapper.sv",$psprintf("Incorrect values of parameters, when RCD is ednabled: MC_CKE_NUM='%0d' and MC_ODT_WIDTH='%0d'", MC_CKE_NUM, MC_ODT_WIDTH))
  //  end
  //                
  //    // Shows to which side of the RCD are connected SDRAM components
  //    for(int component_i=0; component_i<NUM_PHYSICAL_PARTS; component_i=component_i+1)
  //  begin: shows_components_side
  //    `uvm_info("ddr4_rdimm_wrapper.sv",$psprintf("In each Rank component SDRAM[%0d] is connected to '%0s' of the DDR4 RCD", component_i, SDRAM[component_i].name()), UVM_LOW)
  //  end
  //    
  //  end // block: rdimm_initial_block
  
endmodule // ddr4_rdimm_wrapper
