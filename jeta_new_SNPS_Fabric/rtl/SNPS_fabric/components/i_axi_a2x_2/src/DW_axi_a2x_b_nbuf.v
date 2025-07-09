/* --------------------------------------------------------------------
**
// ------------------------------------------------------------------------------
// 
// Copyright 2012 - 2023 Synopsys, INC.
// 
// This Synopsys IP and all associated documentation are proprietary to
// Synopsys, Inc. and may only be used pursuant to the terms and conditions of a
// written license agreement with Synopsys, Inc. All other use, reproduction,
// modification, or distribution of the Synopsys IP or the associated
// documentation is strictly prohibited.
// Inclusivity & Diversity - Visit SolvNetPlus to read the "Synopsys Statement on
//            Inclusivity and Diversity" (Refer to article 000036315 at
//                        https://solvnetplus.synopsys.com)
// 
// Component Name   : DW_axi_a2x
// Component Version: 2.06a
// Release Type     : GA
// Build ID         : 15.22.13.5
// ------------------------------------------------------------------------------

// 
// Release version :  2.06a
// File Version     :        $Revision: #11 $ 
// Revision: $Id: //dwh/DW_ocb/DW_axi_a2x/axi_dev_br/src/DW_axi_a2x_b_nbuf.v#11 $ 
**
** --------------------------------------------------------------------
*/
//*************************************************************************************
// Non-Bufferable Response
// 
//
//            |----------|        /|
//  PP B CH   | Response |       | |            |---------|  
// <----------|   FIFO   |-------| | <-----  |----------| |
//            |          |       | |      |-----------| |-| SP B CH
//            |----------|        \|      |   UID     |-|<-----------  
//               ^    ^                   |-----------| 
//   |-----|     |    |  |------|              ^
//   | Pop |-----|    |--| Push |              |
//   |-----|             |------|              |
//                                             V SP AW Channel
//
// Transaction resizing and Store-Forward features may required the A2X to break a PP Transaction into multiple SP Transactions. 
// The UID block store information for each unique ID sent on the SP so that it can combined the SP responses into a single PP response.
//
// Since the Write Responses can be returned in a different order from the transactions issued on the AW Channel, the 
// architecture offers a Unique ID block. This block contains the resize and store-forward information for each outstanding 
// Unique Write ID. The number of Unique WID's that the A2X can support will affect the number of outstanding Unigue AWID's that 
// the A2X send on the AW Channel. 
//
// If a system is guaranteed to always return the write response in the same order as the transactions issued on the AW Channel.
// The A2X can be configured such that the number of outstanding UWID's are not a factor when issuing transaction on the SP AW 
// Channel. In this case the number of unique ID blocks is reduced to one but the WID is not factored into the equation when 
// analysing the write responses data.
//                                              
//*************************************************************************************

`include "DW_axi_a2x_all_includes.vh"

module i_axi_a2x_2_DW_axi_a2x_b_nbuf (/*AUTOARG*/
   // Outputs
   bvalid_pp, b_pyld_pp, bready_sp, b_osw_fifo_full, b_osw_fifo_valid, b_osw_fifo_empty,
   b_osw_trans,
   // Inputs
   clk_pp, resetn_pp, clk_sp, resetn_sp, awvalid_sp, awready_sp,
   awid_sp, 
   aw_nbuf_sp, 
   aw_last_sp, 
   bready_pp, bvalid_sp, b_pyld_sp, 
   unlk_seq
   );
  //*************************************************************************************
  // Parameter Decelaration
  //*************************************************************************************
  parameter  A2X_PP_MODE                 = 1; 
  parameter  A2X_EQSIZED                 = 1;
  parameter  A2X_BRESP_ORDER             = 1;
  parameter  A2X_BSBW                    = 1;
  parameter  A2X_LOCKED                  = 0; 

  parameter  A2X_NUM_UWID                = 1;
  parameter  A2X_OSW_LIMIT               = 4; 
  parameter  A2X_OSW_LIMIT_LOG2          = 2;


  parameter  A2X_CLK_MODE                = 0;

  parameter  A2X_BRESP_FIFO_DEPTH        = 4;
  parameter  A2X_BRESP_FIFO_DEPTH_LOG2   = 2;

  parameter  A2X_B_PYLD_W                = 32; 

  parameter  BYPASS_UBID_FIFO            = 1;

  //*************************************************************************************
  // I/O Decelaration
  //*************************************************************************************
  //spyglass disable_block W240
  //SMD: An input has been declared but is not read.
  //SJ: This input is used in specific config only 
  input                                       clk_pp;
  input                                       resetn_pp;
  
  input                                       clk_sp;
  input                                       resetn_sp;

  // AXI Secondary Port AW Channel
  input                                       awvalid_sp;         // SP AW CH
  input                                       awready_sp;
  input  [`i_axi_a2x_2_A2X_IDW-1:0]                       awid_sp;
  input                                       aw_nbuf_sp; 
  input                                       aw_last_sp;
  input                                       unlk_seq;          // Unlock Sequence.
  // AXI Primary Port Write response                                  
  input                                       bready_pp;         // PP B CH
  //These nets are used to connect the logic under certain configuration.
  //But this may not drive some of the nets. This will not cause any functional issue.
  output                                      bvalid_pp;     
  output  [A2X_B_PYLD_W-1:0]                  b_pyld_pp;

  // AXI Secondary Port Write Response 
  output                                      bready_sp;         // SP B CH
  input                                       bvalid_sp;     
  input  [A2X_B_PYLD_W-1:0]                   b_pyld_sp;

  output                                      b_osw_fifo_full;   // B Response FIFO 
  output                                      b_osw_fifo_valid;   
  output                                      b_osw_fifo_empty;
  output                                      b_osw_trans;
  //spyglass enable_block W240

  //*************************************************************************************
  // Signal Decelaration
  //*************************************************************************************
  wire                                        b_fifo_push_n;        // B FIFO Push
  wire                                        b_fifo_full;
  
  //These nets are used to connect the logic under certain configuration.
  //But this may not drive any net in some other configuration. 
  wire                                        b_fifo_empty;

  wire                                        b_fifo_nbuf_push_n;   // Non-Bufferable Response FIFO
  wire                                        b_fifo_nbuf_pop_n;
  wire                                        b_fifo_nbuf_full;
  wire                                        b_fifo_nbuf_empty;
  wire   [A2X_B_PYLD_W-1:0]                   b_pyld_nbuf_pp;

  //These nets are used to connect the logic under certain configuration.
  //But this may not drive any net in some other configuration. 
  wire   [A2X_BRESP_FIFO_DEPTH_LOG2:0]        b_fifo_pop_count;
  wire   [A2X_BRESP_FIFO_DEPTH_LOG2:0]        b_fifo_push_count;
  reg    [A2X_B_PYLD_W-1:0]                   b_fifo_pyld_i_r; 
  wire   [A2X_B_PYLD_W-1:0]                   b_fifo_pyld_i;

  //These are dummy wires/regs used to connect the undriven internal 
  //net under certain configuration. Hence this may not drive any 
  //nets in some other configuration. 
  wire   [A2X_NUM_UWID-1:0]                   uid_wr_en;            // Unique ID 
  wire   [A2X_NUM_UWID-1:0]                   uid_fifo_full;
  wire   [A2X_NUM_UWID-1:0]                   uid_fifo_empty;
  wire   [A2X_NUM_UWID-1:0]                   uid_b_fifo_push_n;
  wire   [A2X_B_PYLD_W-1:0]                   uid_b_pyld          [0:A2X_NUM_UWID-1];
  reg    [A2X_NUM_UWID-1:0]                   uid_empty_priority;
  wire   [A2X_NUM_UWID-1:0]                   uid_fifo_match;

  wire                                        unconn_1;

  //Local Parameter
  localparam [A2X_NUM_UWID-1:0]               ONE  = 1;
  localparam [A2X_NUM_UWID-1:0]               ZERO = 0;

  //*************************************************************************************
  // Non-B Response Control FIFO 
  //
  // - Stores the PP Responses to be returned to the PP B Channel
  //*************************************************************************************
  i_axi_a2x_2_DW_axi_a2x_fifo
   #(
     .DUAL_CLK                               (A2X_CLK_MODE)
    ,.PUSH_SYNC_DEPTH                        (`i_axi_a2x_2_A2X_SP_SYNC_DEPTH)
    ,.POP_SYNC_DEPTH                         (`i_axi_a2x_2_A2X_PP_SYNC_DEPTH)
    ,.DATA_W                                 (A2X_B_PYLD_W)
    ,.DEPTH                                  (A2X_BRESP_FIFO_DEPTH)
    ,.LOG2_DEPTH                             (A2X_BRESP_FIFO_DEPTH_LOG2)
  ) U_a2x_nb_fifo (
     .clk_push_i                             (clk_sp)
    ,.resetn_push_i                          (resetn_sp)
    ,.push_req_n_i                           (b_fifo_nbuf_push_n)
    ,.data_i                                 (b_fifo_pyld_i)
    ,.push_full_o                            (b_fifo_nbuf_full)
    ,.push_empty_o                           (unconn_1)
    ,.clk_pop_i                              (clk_pp)
    ,.resetn_pop_i                           (resetn_pp)
    ,.pop_req_n_i                            (b_fifo_nbuf_pop_n)
    ,.pop_empty_o                            (b_fifo_nbuf_empty)
    ,.data_o                                 (b_pyld_nbuf_pp)    
    ,.push_count                             (b_fifo_push_count)
    ,.pop_count                              (b_fifo_pop_count)
  );

  assign bvalid_pp          = !b_fifo_nbuf_empty;
  assign b_pyld_pp          = b_pyld_nbuf_pp;

  assign b_fifo_nbuf_pop_n  = !(bready_pp & bvalid_pp);
  assign b_fifo_nbuf_push_n = b_fifo_push_n;

  assign b_fifo_empty       = b_fifo_nbuf_empty;
  assign b_fifo_full        = b_fifo_nbuf_full;


  //--------------------------------------------------------------------
  // System Verilog Assertions
  //--------------------------------------------------------------------
  
  //*************************************************************************************
  // UID Instantiation 
  //
  // - Multiple Unique BID's for the number of outstanding unique ID's the SP
  //   Channel can support. 
  //*************************************************************************************
  genvar i;
  generate
    if (BYPASS_UBID_FIFO==1) begin: UWID
      reg  [3:0]                                 osw_cnt;
      wire [3:0]                                 osw_cnt_i;
      wire                                       osw_cnt_zero;
      wire                                       osw_cnt_max;

      assign b_osw_fifo_empty = 1'b0;
      assign b_osw_fifo_valid = ((A2X_PP_MODE==0) && (A2X_LOCKED==1))? ~osw_cnt_max : 1'b1;
      assign b_osw_fifo_full  = 1'b0;
      assign b_fifo_pyld_i    = b_pyld_sp;
      assign bready_sp        = ~b_fifo_full;
      assign b_fifo_push_n    = (A2X_PP_MODE==1)? (~(bready_sp & bvalid_sp)) :  (~(bready_sp & bvalid_sp & (!unlk_seq)));

      //****************************************************************************************
      // Outstanding Write Transaction counter in bufferable Mode
      //
      // In cases where the UBID FIFO is Bypassed - (AXI Equalled Sized Non-Bufferable Mode)
      // a counter is used to deetermine the number of outstanding SP responses in Locked Mode. 
      //
      // If Locked is supported in the A2X, the A2X must keep track of the
      // number of outstanding write transactions on AXI SP. The A2X will not
      // start a locked or unlocking transaction until this counter is zero. 
      //****************************************************************************************
      // Constant condition expression
      // This module is used for in several instances and the value depends on the instantiation. 
      // Hence below usage cannot be avoided. This will not cause any funcational issue. 
      if (A2X_LOCKED==1) begin : LK_OSWCNT
        assign osw_cnt_i = osw_cnt;  
        always @(posedge clk_sp or negedge resetn_sp) begin: osw_cnt_PROC
          if (resetn_sp==1'b0)
            osw_cnt <= 4'b0;
          else begin
            if (awvalid_sp && awready_sp && bvalid_sp && bready_sp)
              osw_cnt <= osw_cnt_i;
            else if (awvalid_sp && awready_sp)
              osw_cnt <= osw_cnt_i + 1;
            else if (bvalid_sp && bready_sp)
              osw_cnt <= osw_cnt_i-1; 
          end
        end

        assign osw_cnt_zero = ~|osw_cnt;
        assign osw_cnt_max  = &osw_cnt;
        assign b_osw_trans  = ~osw_cnt_zero;
      end else begin
        assign b_osw_trans = 1'b0; 
      end // A2X_LOCKED

    end else begin
      
      for (i = 0; i <A2X_NUM_UWID; i = i + 1) begin : UWID 
        i_axi_a2x_2_DW_axi_a2x_b_uid
         #(
           .A2X_PP_MODE                             (A2X_PP_MODE) 
          ,.A2X_EQSIZED                             (A2X_EQSIZED)
          ,.A2X_BRESP_ORDER                         (A2X_BRESP_ORDER)
          ,.A2X_OSW_LIMIT                           (A2X_OSW_LIMIT) 
          ,.A2X_OSW_LIMIT_LOG2                      (A2X_OSW_LIMIT_LOG2)
          ,.A2X_BSBW                                (A2X_BSBW)
          ,.B_PYLD_W                                (A2X_B_PYLD_W)
        ) U_a2x_b_uid (
          // Outputs
           .uid_fifo_full                           (uid_fifo_full[i])
          ,.uid_fifo_empty                          (uid_fifo_empty[i])
          ,.uid_fifo_match                          (uid_fifo_match[i])
          ,.uid_b_fifo_push_n                       (uid_b_fifo_push_n[i])
          ,.uid_b_pyld                              (uid_b_pyld[i])
          // Inputs
          ,.clk                                     (clk_sp)
          ,.resetn                                  (resetn_sp)
          ,.awvalid_sp                              (awvalid_sp)
          ,.awready_sp                              (awready_sp)
          ,.aw_last_sp                              (aw_last_sp)
          ,.aw_nbuf_sp                              (aw_nbuf_sp)
          ,.uid_wr_en                               (uid_wr_en[i])
          ,.awid_sp                                 (awid_sp)
          ,.bvalid_sp                               (bvalid_sp)
          ,.bready_sp                               (bready_sp)
          ,.b_pyld_sp                               (b_pyld_sp)
        );
      end

      //*************************************************************************************
      // UID Arbitrate
      // 
      // When more that one UID FIFO's empty enable UID with highest priorty. used
      // to select which UID the AWID is written into.
      // UID[0] - Highest Priorty.
      // UID[N] - Lowest Priotry.
      //*************************************************************************************
      //spyglass disable_block W415a
      //SMD: Signal may be multiply assigned (beside initialization) in the same scope.
      //SJ : uid_empty_priority is initialized before for loop to avoid latches and it is assigned with 0 in each iteration in order to determine the priority.
      always @(*) begin: uid_arb_PROC
        integer j;
        uid_empty_priority = {A2X_NUM_UWID{1'b0}};
        for (j = A2X_NUM_UWID-1; j>=0; j = j - 1) begin 
          if (uid_fifo_empty[j]==1'b1) begin
            uid_empty_priority    = {A2X_NUM_UWID{1'b0}}; 
            uid_empty_priority[j] = 1'b1;
          end
        end
      end
      //spyglass enable_block W415a      
      // If the incomming ID matches the ID of a fifo in use then use the full status of that fifo.
      // If FIFO is full AW address cannot be issued. 
      assign uid_wr_en = (A2X_BRESP_ORDER==0)? ONE : ~(|uid_fifo_match)? uid_empty_priority : ~(|uid_fifo_full)? uid_fifo_match : ZERO;

      //*************************************************************************************
      // UID Control
      // 
      // When SP response channel active (bvalid & bready), the UID will attempt
      // to issue a push into the BRESP FIFO if the SP response is the last
      // expected response for that BID. 
      // 
      // If AW Channel breaks PP AW into multiple SP AW Transactions the UID
      // Control combines these BID responses into 1 response on the PP. After
      // the last response is received for a given transaction the UID will
      // attempt to push into the BRESP FIFO. 
      //
      // If UID is not active then the outputs are driven to zero. Hence all UID
      // outputs can be gated to determine which UID drives the BRESP inputs.
      //*************************************************************************************
  
      // If B FIFO or any UID FIFO Full don't accept SP Responses
      // If Equalled Sized CT Config and non in dynamic response mode bypass UWID FIFOs
      assign bready_sp          = !(b_fifo_full | b_osw_fifo_empty);

      // Depending on configuration bus may be single bit. 
      assign b_fifo_push_n      = (A2X_PP_MODE==1) ? &uid_b_fifo_push_n : ((A2X_LOCKED==1) &&unlk_seq)? 1'b1 : (&uid_b_fifo_push_n);
  
      // If UID is not active then the outputs are driven to zero. Hence all UID
      // outputs can be gated to determine which UID drives the B FIFO inputs
      //spyglass disable_block W415a
      //SMD: Signal may be multiply assigned (beside initialization) in the same scope.
      //SJ : b_fifo_pyld_i_r is initialized to 0 before assignment inside a for loop to avoid latches. Here each bit of b_fifo_pyld_i_r is gated with uid_b_pyld to determine which UID drives the B FIFO inputs.
      always @(*) begin: fifo_pyld_sel_PROC 
        integer j;
        b_fifo_pyld_i_r = {A2X_B_PYLD_W{1'b0}};
        for (j=0; j<A2X_NUM_UWID; j=j+1) begin
          b_fifo_pyld_i_r = (uid_b_pyld[j] | b_fifo_pyld_i_r);
        end
      end
      //spyglass enable_block W415a
      assign b_fifo_pyld_i = b_fifo_pyld_i_r;

      // Only one UID active when SP Active 
      // The AW has no dependancy on the B Channel for Equalled sized CT Configs
      assign b_osw_fifo_full   = |uid_fifo_full;

      // FIFO is Valid when AWID (uid_wr_en) match the UWID in the FIFO or when the OSW FIFO
      // is empty. In NBUF Equalled Sized AHB Mode OSW always Valid as OSW FIFO is
      // bypassed.
      assign b_osw_fifo_valid  = |uid_wr_en & ~b_osw_fifo_full;

      // Only one UID active when SP Active 
      assign b_osw_fifo_empty  =  &uid_fifo_empty;

      // Currently Used For locked Transactions. Asseeted if an of the FIFOs
      // are non-empty. 
      assign b_osw_trans       = ~&uid_fifo_empty;

    end // if (BYPASS_UBID_FIFO==1) begin
  endgenerate

endmodule

