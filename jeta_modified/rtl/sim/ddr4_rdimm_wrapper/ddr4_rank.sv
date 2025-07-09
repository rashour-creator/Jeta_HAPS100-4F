//import uvm_pkg::*;

//typedef enum bit {SIDE_B, SIDE_A} components_side_e;
`timescale 1ps/1ps
module ddr4_rank #(
		   parameter MC_DQ_WIDTH = 16, // Memory DQ bus width
		   parameter MC_DQS_BITS = 4, // Number of DQS bits
		   parameter MC_DM_WIDTH = 4, // Number of DM bits
		   parameter MC_ABITS = 18, // Number of Address bits
		   parameter MC_BANK_WIDTH = 2, // Memory Bank address bits
		   parameter MC_BANK_GROUP = 2, // Memory Bank Groups
		   parameter NUM_PHYSICAL_PARTS = 4, // Number of SDRAMs in a Single Rank
		   parameter CALIB_EN = "NO", // When is set to "YES" ,R2R and FBT delays will be added 
		   parameter TOTAL_FBT_DELAY = 2700, // Total Fly-by-Topology delay		   
		   parameter MEM_PART_WIDTH = "x4", // Single Device width
		   // Shows which SDRAMs are connected to side A(first half) and side B(second half) of RCD.
		   parameter DDR_SIM_MODEL = "MICRON", // "MICRON" or "DENALI" memory model
		   parameter DM_DBI = "" // Disables dm_dbi_n if set to NONE
		   )
  (
   // side A of the RCD
   input 		     qa_act_n,
   input [MC_ABITS-1:0]      qa_addr,
   input [MC_BANK_WIDTH-1:0] qa_ba,
   input [MC_BANK_GROUP-1:0] qa_bg,
   input 		     qa_par,
   input 		     qa_cke,
   input 		     qa_odt,
   input 		     qa_cs_n,
   // side B of the RCD
   input 		     qb_act_n,
   input [MC_ABITS-1:0]      qb_addr,
   input [MC_BANK_WIDTH-1:0] qb_ba,
   input [MC_BANK_GROUP-1:0] qb_bg,
   input 		     qb_par,
   input 		     qb_cke,
   input 		     qb_odt,
   input 		     qb_cs_n,
  
   input [1:0] 		     ck, // ck[0]->ck_c, ck[1]->ck_t
   input 		     reset_n,

   inout [MC_DM_WIDTH-1:0]   dm_dbi_n,
   inout [MC_DQ_WIDTH-1:0]   dq,
   inout [MC_DQS_BITS-1:0]   dqs_t,
   inout [MC_DQS_BITS-1:0]   dqs_c,

   output reg 		     alert_n		  
   );

  genvar 		     device_x; // used in for loop in generate block (shows number of current device)
  
  // Local parameters
  localparam DRAM_WIDTH = (MEM_PART_WIDTH=="x4") ? 4 : 
                          (MEM_PART_WIDTH=="x8") ? 8 : 
			              16;

  localparam SDRAM_ADDR_BITS = 18 - MC_ABITS; // Redundants Address bits to SDRAM devices
  localparam DQ_PER_DEVICE = (MEM_PART_WIDTH=="x4") ? 4 : // DQ per Device is 4-bits
                             (MEM_PART_WIDTH=="x8") ? 8 : // DQ per Device is 8-bits
			     16; // DQ per Device is 16-bits
  localparam DM_PER_DEVICE  = (MEM_PART_WIDTH=="x16") ? 2 : 1; // DM per Device ==2 only for x16 Devices
  localparam DQS_PER_DEVICE = (MEM_PART_WIDTH=="x16") ? 2 : 1; // DQS per Device ==2 only for x16 Devices

  localparam MAX_NUM_COMPONENTS = (MEM_PART_WIDTH == "x4") ? 18 : // Max number of components for single Rank
                                  (MEM_PART_WIDTH == "x8") ? 9  :
				  5; // If MEM_PART_WIDTH == "x16"
  localparam RANK_FBT_DELAY = (TOTAL_FBT_DELAY*NUM_PHYSICAL_PARTS)/MAX_NUM_COMPONENTS; // FBT delay for a single Rank
  //localparam components_side_e [NUM_PHYSICAL_PARTS-1:0] SDRAM = { {(NUM_PHYSICAL_PARTS/2){SIDE_B}}, {(NUM_PHYSICAL_PARTS/2){SIDE_A}} }; // SDRAM
  localparam [NUM_PHYSICAL_PARTS-1:0] SDRAM = { {(NUM_PHYSICAL_PARTS/2){1'b1}}, {(NUM_PHYSICAL_PARTS/2){1'b0}} }; // SDRAM
  
  // sdram ddr4_model have static ports for address bits 0-17.
  // In case that the incoming from MC address signals have less than 18 bits, to upper bits will be added static 1'b1.
  wire [17:0] 		     ddr4_model_qa_addr;
  wire [17:0] 		     ddr4_model_qb_addr;
  
  wire 			     dm_pull_up; // used when DM_DBI="NONE". In that case to dm_dbi_n pin will be connected 1'b1.

  int 			     fbt_delay [NUM_PHYSICAL_PARTS]; // each word store the delay for a single device
    
  assign dm_pull_up = 1'b1; // used for dm_dbi_n pin of SDRAM when DM_DBI="NONE"

  // Add Redundants Address bits to SDRAM devices
  generate
    if(SDRAM_ADDR_BITS>0) // address signal is less than 18 bits
      begin: qx_addr_less_than_18_bits
	assign ddr4_model_qa_addr = {{SDRAM_ADDR_BITS{1'b1}}, qa_addr};
	assign ddr4_model_qb_addr = {{SDRAM_ADDR_BITS{1'b1}}, qb_addr};
      end
    else // qx_addr=18 bits
      begin: qx_addr_qual_to_18_bits
	assign ddr4_model_qa_addr = qa_addr;
	assign ddr4_model_qb_addr = qb_addr;
      end
  endgenerate 

  // Create the handle for the DIMM FBT delay generation constraint class
 // generate
 //   if(CALIB_EN=="YES")
 //     begin: create_fbt_delays

 //   // Create the handle DDR4_FBT_DELAYS
 //   rdimm_fbt_delays #(.TOTAL_DIMM_DLY(RANK_FBT_DELAY), .NO_OF_COMP (NUM_PHYSICAL_PARTS), .ENABLE(1) ) DDR4_FBT_DELAYS; //ENABLE FTB delay

 //   initial
 //     begin: initial_block_fbt_delays    
 //       DDR4_FBT_DELAYS = new();
 //       DDR4_FBT_DELAYS.reset_value();

 //       assert(DDR4_FBT_DELAYS.randomize()) // Randomize FBT delays for all SDRAM components		
 //   	  else
 //   	    `uvm_error("ddr4_rank.sv", "Randomization of DDR4_FBT_DELAYS FAILED")

 //       foreach(fbt_delay[i]) 
 //         fbt_delay[i] = DDR4_FBT_DELAYS.delay[i]; // Store the FBT delays for each components

 //     end // block: initial_block_fbt_delays
 //   	
 //     end // block: create_fbt_delays 
 // endgenerate
  
  // Instance of SDRAM Devices (parameterized for x4, x8 and x16 Devices)
  generate
    for(device_x=0; device_x<NUM_PHYSICAL_PARTS; device_x=device_x+1)
      begin: instance_of_sdram_devices
	
	DDR4_if #(.CONFIGURED_DQ_BITS (DRAM_WIDTH)) iDDR4(); // create iDDR4 interface	

	// Current SDRAM component will be connected to side A of the RCD
	if(SDRAM[device_x]==1'b0) // connect SDRAM to side A of the RCD
	  begin: sdram_to_side_a

	    // Add FBT delays
	    if(CALIB_EN=="YES") // Calibration is enabled
	      begin: add_fbt_delays_side_a
		
		always@(*)
		  begin: always_block_fbt_delays_side_a
		    iDDR4.CK        <= #(fbt_delay[device_x]) ck; // CK[0]==CK_c CK[1]==CK_t
		    iDDR4.ACT_n     <= #(fbt_delay[device_x]) qa_act_n; // input
		    iDDR4.RAS_n_A16 <= #(fbt_delay[device_x]) ddr4_model_qa_addr[16]; // input
		    iDDR4.CAS_n_A15 <= #(fbt_delay[device_x]) ddr4_model_qa_addr[15]; // input
		    iDDR4.WE_n_A14  <= #(fbt_delay[device_x]) ddr4_model_qa_addr[14]; // input
		    alert_n         <= #(fbt_delay[device_x]) iDDR4.ALERT_n; // output
		    iDDR4.PARITY    <= #(fbt_delay[device_x]) qa_par; // input
		    iDDR4.RESET_n   <= #(fbt_delay[device_x]) reset_n; // input
		    iDDR4.TEN       <= #(fbt_delay[device_x]) 1'b0; // input
		    iDDR4.CS_n      <= #(fbt_delay[device_x]) qa_cs_n; // input
		    iDDR4.CKE       <= #(fbt_delay[device_x]) qa_cke; // input
		    iDDR4.ODT       <= #(fbt_delay[device_x]) qa_odt; // input
		    iDDR4.C         <= #(fbt_delay[device_x]) 1'b0; // input [MAX_RANK_BITS-1:0]
		    iDDR4.BG        <= #(fbt_delay[device_x]) qa_bg; // input [MAX_BANK_GROUP_BITS-1:0]
		    iDDR4.BA        <= #(fbt_delay[device_x]) qa_ba; // input [MAX_BANK_BITS-1:0]
		    iDDR4.ADDR      <= #(fbt_delay[device_x]) ddr4_model_qa_addr[13:0]; // input [13:0]
		    iDDR4.ADDR_17   <= #(fbt_delay[device_x]) ddr4_model_qa_addr[17]; // input
		  end // block: always_block_fbt_delays_side_a
	      end // block: add_fbt_delays_side_a
	    else // !if(CALIB_EN=="YES")
	      // Calibration is disabled
	      begin: without_fbt_delays_side_a
		always@(*)
		  begin: always_block_without_fbt_delays_side_a
      	    	    iDDR4.CK        <= ck; // CK[0]==CK_c CK[1]==CK_t
		    iDDR4.ACT_n     <= qa_act_n; // input
		    iDDR4.RAS_n_A16 <= ddr4_model_qa_addr[16]; // input
		    iDDR4.CAS_n_A15 <= ddr4_model_qa_addr[15]; // input
		    iDDR4.WE_n_A14  <= ddr4_model_qa_addr[14]; // input
		    alert_n         <= iDDR4.ALERT_n; // output
		    iDDR4.PARITY    <= qa_par; // input
		    iDDR4.RESET_n   <= reset_n; // input
		    iDDR4.TEN       <= 1'b0; // input
		    iDDR4.CS_n      <= qa_cs_n; // input
		    iDDR4.CKE       <= qa_cke; // input
		    iDDR4.ODT       <= qa_odt; // input
		    iDDR4.C         <= 1'b0; // input [MAX_RANK_BITS-1:0]
		    iDDR4.BG        <= qa_bg; // input [MAX_BANK_GROUP_BITS-1:0]
		    iDDR4.BA        <= qa_ba; // input [MAX_BANK_BITS-1:0]
		    iDDR4.ADDR      <= ddr4_model_qa_addr[13:0]; // input [13:0]
		    iDDR4.ADDR_17   <= ddr4_model_qa_addr[17]; // input
		  end // block: always_ddr4_model_block_without_fbt_delays_side_a
	      end // block: without_fbt_delays_side_a

	  end // block: sdram_to_side_a
	else // !if(SDRAM[device_x]==SIDE_A)
	  // Current SDRAM component will be connected to side B of the RCD
	  begin: sdram_to_side_b

	    // Add FBT delays
	    if(CALIB_EN=="YES") // Calibration is enabled
	      begin: add_fbt_delays_side_b

		always@(*)				       
	          begin: always_block_fbt_delays_side_b
		    iDDR4.CK        <= #(fbt_delay[device_x]) ck; // CK[0]==CK_c CK[1]==CK_t
		    iDDR4.ACT_n     <= #(fbt_delay[device_x]) qb_act_n; // input
		    iDDR4.RAS_n_A16 <= #(fbt_delay[device_x]) ddr4_model_qb_addr[16]; // input
		    iDDR4.CAS_n_A15 <= #(fbt_delay[device_x]) ddr4_model_qb_addr[15]; // input
		    iDDR4.WE_n_A14  <= #(fbt_delay[device_x]) ddr4_model_qb_addr[14]; // input
		    alert_n         <= #(fbt_delay[device_x]) iDDR4.ALERT_n; // output
		    iDDR4.PARITY    <= #(fbt_delay[device_x]) qb_par; // input
		    iDDR4.RESET_n   <= #(fbt_delay[device_x]) reset_n; // input
		    iDDR4.TEN       <= #(fbt_delay[device_x]) 1'b0; // input
		    iDDR4.CS_n      <= #(fbt_delay[device_x]) qb_cs_n; // input
		    iDDR4.CKE       <= #(fbt_delay[device_x]) qb_cke; // input
		    iDDR4.ODT       <= #(fbt_delay[device_x]) qb_odt; // input
		    iDDR4.C         <= #(fbt_delay[device_x]) 1'b0; // input [MAX_RANK_BITS-1:0]
		    iDDR4.BG        <= #(fbt_delay[device_x]) qb_bg; // input [MAX_BANK_GROUP_BITS-1:0]
		    iDDR4.BA        <= #(fbt_delay[device_x]) qb_ba; // input [MAX_BANK_BITS-1:0]
		    // The RCD output inversion to side B address signal invert qb_addr[13]=1'b1.
		    // This is issue because the address to SDRAM will be out of bounds (max range is addr[13:0]='h1FFF), to resolve this issue we set qb_addr[13] to 1'b0.
		    iDDR4.ADDR      <= #(fbt_delay[device_x]) {1'b0, ddr4_model_qb_addr[13:0]}; // input [13:0]
		    iDDR4.ADDR_17   <= #(fbt_delay[device_x]) ddr4_model_qb_addr[17]; // input
		  end // block: always_block_fbt_delays_side_b
	      end // block: add_fbt_delays_side_b
	    else // !if(CALIB_EN=="YES")
	      // Calibration is disabled
	      begin: without_fbt_delays_side_b
		always@(*)
		  begin: always_block_without_fbt_delays_side_b
		    iDDR4.CK        <= ck; // CK[0]==CK_c CK[1]==CK_t
		    iDDR4.ACT_n     <= qb_act_n; // input
		    iDDR4.RAS_n_A16 <= ddr4_model_qb_addr[16]; // input
		    iDDR4.CAS_n_A15 <= ddr4_model_qb_addr[15]; // input
		    iDDR4.WE_n_A14  <= ddr4_model_qb_addr[14]; // input
		    alert_n         <= iDDR4.ALERT_n; // output
		    iDDR4.PARITY    <= qb_par; // input
		    iDDR4.RESET_n   <= reset_n; // input
		    iDDR4.TEN       <= 1'b0; // input
		    iDDR4.CS_n      <= qb_cs_n; // input
		    iDDR4.CKE       <= qb_cke; // input
		    iDDR4.ODT       <= qb_odt; // input
		    iDDR4.C         <= 1'b0; // input [MAX_RANK_BITS-1:0]
		    iDDR4.BG        <= qb_bg; // input [MAX_BANK_GROUP_BITS-1:0]
		    iDDR4.BA        <= qb_ba; // input [MAX_BANK_BITS-1:0]
		    // The RCD output inversion to side B address signal invert qb_addr[13]=1'b1.
		    // This is issue because the address to SDRAM will be out of bounds (max range is addr[13:0]='h1FFF), to resolve this issue we set qb_addr[13] to 1'b0.
		    iDDR4.ADDR      <= {1'b0, ddr4_model_qb_addr[13:0]}; // input [13:0]
		    iDDR4.ADDR_17   <= ddr4_model_qb_addr[17]; // input
		  end // block: always_block_without_fbt_delays_side_b		
	      end // block: without_fbt_delays_side_b
	    	    	    
	  end // block: sdram_to_side_b

	// Data bus signals are the same for side A and side B
	// Connecting of bi-directional data signals - dm, dq, dqs_t and dqs_c
	if (DM_DBI == "NONE")
	  begin: no_dm_dbi_n_side_b
	    assign dm_dbi_n[DM_PER_DEVICE*device_x+:DM_PER_DEVICE] = {(DM_PER_DEVICE){dm_pull_up}};
	    assign iDDR4.DM_n = {(DM_PER_DEVICE){dm_pull_up}};
	  end
	else
	  begin: enable_dm_dbi_n_side_b
      `ifdef XILINX_SIMULATOR
	    short bidiDM_n[DM_PER_DEVICE-1:0] (dm_dbi_n[DM_PER_DEVICE*device_x+:DM_PER_DEVICE], iDDR4.DM_n[DM_PER_DEVICE-1:0]); // inout [MC_CONFIGURED_DM_BITS-1:0]	
	  `else
        tran bidiDM_n[DM_PER_DEVICE-1:0] (dm_dbi_n[DM_PER_DEVICE*device_x+:DM_PER_DEVICE], iDDR4.DM_n[DM_PER_DEVICE-1:0]); // inout [MC_CONFIGURED_DM_BITS-1:0]	
	  `endif
      end
	      
    `ifdef XILINX_SIMULATOR
	short  bidiDQ[DQ_PER_DEVICE-1:0] (dq[DQ_PER_DEVICE*device_x+:DQ_PER_DEVICE], iDDR4.DQ[DQ_PER_DEVICE-1:0]); // inout [MC_CONFIGURED_DQ_BITS-1:0]
	short  bidiDQS_t[DQS_PER_DEVICE-1:0] (dqs_t[DQS_PER_DEVICE*device_x+:DQS_PER_DEVICE], iDDR4.DQS_t[DQS_PER_DEVICE-1:0]); // inout [MC_CONFIGURED_DQS_BITS-1:0]
	short  bidiDQS_c[DQS_PER_DEVICE-1:0] (dqs_c[DQS_PER_DEVICE*device_x+:DQS_PER_DEVICE], iDDR4.DQS_c[DQS_PER_DEVICE-1:0]); // inout [MC_CONFIGURED_DQS_BITS-1:0]
	`else
    tran bidiDQ[DQ_PER_DEVICE-1:0] (dq[DQ_PER_DEVICE*device_x+:DQ_PER_DEVICE], iDDR4.DQ[DQ_PER_DEVICE-1:0]); // inout [MC_CONFIGURED_DQ_BITS-1:0]
	tran bidiDQS_t[DQS_PER_DEVICE-1:0] (dqs_t[DQS_PER_DEVICE*device_x+:DQS_PER_DEVICE], iDDR4.DQS_t[DQS_PER_DEVICE-1:0]); // inout [MC_CONFIGURED_DQS_BITS-1:0]
	tran bidiDQS_c[DQS_PER_DEVICE-1:0] (dqs_c[DQS_PER_DEVICE*device_x+:DQS_PER_DEVICE], iDDR4.DQS_c[DQS_PER_DEVICE-1:0]); // inout [MC_CONFIGURED_DQS_BITS-1:0]
	`endif
	
	assign iDDR4.ZQ = 1'b1; // input
	assign iDDR4.PWR = 1'b1; // input
	assign iDDR4.VREF_CA = 1'b1; // input
	assign iDDR4.VREF_DQ = 1'b1; // input 
	
	// Instance of MICRON ddr4_model
	if (DDR_SIM_MODEL == "MICRON") // instance of ddr4_model provided from MICRON
	  begin: micron_mem_model
        ddr4_model  #
          (
           .CONFIGURED_DQ_BITS (DRAM_WIDTH)
           ) u_ddr4_model(
				     .model_enable (), // inout
				     .iDDR4 (iDDR4)
				     );
	  end
	else // !if (DDR_SIM_MODEL == "MICRON") // instance of ddr4_model provided from Denali
	      begin: denali_mem_model
	    	// Instance of DENALI ddr4_model
		ddr4_model u_ddr4_model (
				  	 .model_enable (), // inout
				  	 .iDDR4 (iDDR4)
				  	 );
	      end
	
      end // block: instance_of_sdram_devices
  endgenerate

endmodule // ddr4_rank
