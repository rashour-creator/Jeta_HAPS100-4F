/******************************************************************************
   Copyright (C) 2018-2021 Synopsys, Inc.
   This IP and the associated documentation are confidential and
   proprietary to Synopsys, Inc. Your use or disclosure of this IP is 
   subject to the terms and conditions of a written license agreement 
   between you, or your company, and Synopsys, Inc.
 *******************************************************************************
     Title  : TestBench toplevel
     Project: XTOR RISCV SOC
 *******************************************************************************
         $Id: //chipit/chipit/main/dev/systems/examples/xtor_riscv_soc/rtl/sim/sim_tb.v#2 $
     $Author: khertig $
   $DateTime: 2021/11/03 06:47:38 $ 
 ******************************************************************************/

`timescale 1 ps/1 ps 

module sim_tb();
   // Interface for DDR4 Memory model 
   
   // -- parameter UMR_RESET_PERIOD  = `DEF_UMR_RESET_PERIOD; 
   parameter ACLK_PERIOD      = 20000;
   parameter UMR_RESET_PERIOD = 5*ACLK_PERIOD; 
   parameter DDR_CLK_PERIOD   = 5000;
   parameter RANKS            = 2;
   parameter CK_WIDTH         = 1;
   parameter DQ_WIDTH         = 72;
   parameter ROW_WIDTH        = 17;
   parameter MEM_ADDR_WIDTH   = 17;
   parameter BG_WIDTH         = 2;
   parameter BA_WIDTH         = 2;
   parameter DQS_WIDTH        = DQ_WIDTH / 8;

   reg                        clock;
   reg                        reset_n;
   reg                        reset_b;
   wire                       io_success;
   wire [1:0]                 uled_grn;
   wire [1:0]                 uled_red;
   reg                        jtag_TCK;
   reg                        jtag_TMS;
   reg                        jtag_TDI;
   wire                       jtag_TDO;
   wire                       tx;
   reg                        rx;
   wire [23:0]                led_counter;
   wire                       mem_reset_n ;
   wire [1:0]                 mem_cke ;
   wire [1:0]                 mem_odt ;
   wire [1:0]                 mem_cs_n ;
   wire [ROW_WIDTH-1:0]       mem_a ;
   
   wire [CK_WIDTH-1:0]        mem_ck_t ;
   wire [CK_WIDTH-1:0]        mem_ck_c ;
   wire [DQS_WIDTH-1:0]       mem_dqs_t /* synthesis syn_io_slew = "FAST" */;
   wire [DQS_WIDTH-1:0]       mem_dqs_c /* synthesis syn_io_slew = "FAST" */;
   wire [BG_WIDTH-1:0]        mem_bg ;
   wire [BA_WIDTH-1:0]        mem_ba ;
   wire                       mem_parity;
   wire                       mem_act_n;
   wire [DQS_WIDTH-1:0]       mem_dm_dbi_n;
   wire [DQ_WIDTH-1:0]        mem_dq; /* synthesis syn_io_slew = "FAST" */ 
   wire                       ddr_clk_en_n;
   reg                        ddr_clk_n;
   reg                        ddr_clk;

   // ---------------------------------------------------------------------------------
   // ------------- Top Module Instantiation --------------------
   // ---------------------------------------------------------------------------------
   
   haps_top 
     i_haps_top
       (
        .clock          (clock          )
        , .reset_n        (reset_n        )
        , .reset_b        (reset_b        )
        , .io_success     (io_success     )
        , .uled_grn       (uled_grn       )
        , .uled_red       (uled_red       )
        , .jtag_TCK       (jtag_TCK       )
        , .jtag_TMS       (jtag_TMS       )
        , .jtag_TDI       (jtag_TDI       )
        , .jtag_TDO       (jtag_TDO       )
        , .tx             (tx             )
        , .rx             (rx             )
        , .led_counter    (led_counter    )
        , .mem_reset_n    (mem_reset_n    )
        , .mem_cke        (mem_cke        )
        , .mem_odt        (mem_odt        )
        , .mem_cs_n       (mem_cs_n       )
        , .mem_a          (mem_a          )
        , .mem_ck_t       (mem_ck_t       )
        , .mem_ck_c       (mem_ck_c       )
        , .mem_dqs_t      (mem_dqs_t      )
        , .mem_dqs_c      (mem_dqs_c      )
        , .mem_bg         (mem_bg         )
        , .mem_ba         (mem_ba         )
        , .mem_parity     (mem_parity     )
        , .mem_act_n      (mem_act_n      )
        , .mem_dm_dbi_n   (mem_dm_dbi_n   )
        , .mem_dq         (mem_dq         )
        , .ddr_clk_en_n   (ddr_clk_en_n   )
        , .ddr_clk_n      (~ddr_clk       )
        , .ddr_clk        (ddr_clk        )
        );


   /******************************************************************************
    clock generator
    ******************************************************************************/
   initial begin
      clock = 1'b0;
      forever
        #(ACLK_PERIOD/2) clock = ~clock;
   end
   
   /******************************************************************************
    DDR clock generator
    ******************************************************************************/
   initial begin
      ddr_clk = 1'b0;
      forever
        #(DDR_CLK_PERIOD/2) ddr_clk = ~ddr_clk;
   end
   
   /******************************************************************************
    HAPS global reset generator
    ******************************************************************************/ 
   initial begin
      reset_n = 1'b0;
      #(UMR_RESET_PERIOD) reset_n = 1'b1;
   end
   
   // ---------------------------------------------------------------------------------
   // ------------- DDR4 DIMM Simulation Model Instantiation --------------------
   // ---------------------------------------------------------------------------------
   
   ddr4_rdimm_wrapper 
     #(
       .MC_DQ_WIDTH(DQ_WIDTH),                 // 72
       .MC_DQS_BITS(DQ_WIDTH / 8),             // 9
       .MC_DM_WIDTH(DQ_WIDTH / 8),             // 9
       .MC_CKE_NUM(RANKS),                     // 2
       .MC_ODT_WIDTH(RANKS),                   // 2
       .MC_ABITS(MEM_ADDR_WIDTH),              // 17
       //.MC_BANK_WIDTH(BANK_WIDTH_RDIMM),       // 2
       //.MC_BANK_GROUP(BANK_GROUP_WIDTH_RDIMM), // 2
       .MC_CS_NUM(RANKS),                      // 2
       .MC_RANKS_NUM(RANKS),                   // 2
       .NUM_PHYSICAL_PARTS(DQ_WIDTH / 8),      // 9 
       //.CALIB_EN("NO"),
       .tCK(1250), // 1250
       //.tPDM(),
       //.MIN_TOTAL_R2R_DELAY(),
       //.MAX_TOTAL_R2R_DELAY(),
       //.TOTAL_FBT_DELAY(),
       .MEM_PART_WIDTH("x8"),                  // x8
       .MC_CA_MIRROR("ON"),                    // "ON"
       //.SDRAM("DDR4"),
       //.DDR_SIM_MODEL("MICRON"),
       .DM_DBI("DM_NODBI"),                    // "DM_NODBI"
       .MC_REG_CTRL("ON")                      // "ON"
       )
   u_ddr4_rdimm_wrapper  
     (
      .ddr4_act_n(mem_act_n),          // input
      .ddr4_addr(mem_a),               // input
      .ddr4_ba(mem_ba),                // input
      .ddr4_bg(mem_bg),                // input
      .ddr4_par(mem_parity),           // input
      .ddr4_cke(mem_cke[RANKS-1:0]),   // input
      .ddr4_odt(mem_odt[RANKS-1:0]),   // input
      .ddr4_cs_n(mem_cs_n[RANKS-1:0]), // input
      .ddr4_ck_t(mem_ck_t),            // input
      .ddr4_ck_c(mem_ck_c),            // input
      .ddr4_reset_n(mem_reset_n),      // input
      .ddr4_dm_dbi_n(mem_dm_dbi_n),    // inout
      .ddr4_dq(mem_dq),                // inout
      .ddr4_dqs_t(mem_dqs_t),          // inout
      .ddr4_dqs_c(mem_dqs_c),          // inout
      .ddr4_alert_n(),                 // inout
      .scl(),                          // input
      .sa0(),                          // input
      .sa1(),                          // input
      .sa2(),                          // input
      .sda(),                          // inout
      .bfunc(),                        // input
      .vddspd()                        // input
      );

   // ---------------------------------------------------------------------------------
   // ------------- Dumping Variables --------------------
   // ---------------------------------------------------------------------------------
   
   // -- initial begin
   // --   $fsdbDumpvars(0, i_HAPSTOP, "+fsdbfile+HAPS_top.fsdb");
   // --   $fsdbDumpvars(0, u_ddr4_rdimm_wrapper, "+fsdbfile+DDR4_dimm_model.fsdb");
   // -- end
   
`ifndef NO_VCS_DUMP // dump for VCS DVE in VPD format
   initial
     if ( $test$plusargs("vpd_dump_all") )
       begin
        $vcdplusfile("i_HAPSTOP.vpd");
        $vcdpluson(0);
        $vcdplusdeltacycleon;
        $vcdplusglitchon;
        $vcdplusmemon(0);
      end
`endif
   // -- `ifndef NO_VERDI_DUMP // dump for VERDI in FSDB format
  // --    initial     
   // --      if ( $test$plusargs("fsdb_dump_all") )
   // --       begin
   // --         $fsdbDumpfile("ddr_top.fsdb");
   // --         $fsdbDumpvars(0);
   // --       end
   // -- `endif
   
   // --    always @(*)
   // --      if (ddr_phy_init_done)
   // --        begin
   // --           $display ("*************************************");
   // --           $display ("PHY_INIT: DONE completed at %t", $time);
   // --           $display ("*************************************");
   // --        end
   
endmodule
