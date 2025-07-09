/* --------------------------------------------------------------------
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
// File Version     :        $Revision: #6 $ 
// Revision: $Id: //dwh/DW_ocb/DW_axi_a2x/axi_dev_br/src/DW_axi_a2x_h2x_w_id.v#6 $ 
// --------------------------------------------------------------------
*/

`include "DW_axi_a2x_all_includes.vh"
//*************************************************************************************
// AHB Write Control per AHB Master
//*************************************************************************************
module i_axi_a2x_DW_axi_a2x_h2x_w_id (/*AUTOARG*/
   // Outputs
   awvalid, alen_o, wvalid, wlast, bready, w_hready_resp, w_split_resp, 
   w_error_resp, w_retry_resp,  w_hsplit, hw_ebt, hw_nbuf, hincr_last, w_buf_state, w_recall_state,
   os_w_o, busy, nbuf_state,
   // Inputs
   clk, resetn, hsel, hwrite, hready, hid_valid, hburst, htrans, hburst_dp,
   cache_i, alen_i, bvalid, bid_valid, bresp, wrap_ub_len_i,
   bf_timeout, hmastlock
   );

  //*************************************************************************************
  // Parameters
  //*************************************************************************************
  parameter   A2X_BRESP_MODE                  = 0; 
  parameter   A2X_SPLIT_MODE                  = 0;
  parameter   A2X_BLW                         = 4;
  parameter   A2X_LOCKED                      = 0;

  localparam  PP_W                            = 3'b000;
  localparam  PP_WRAPU                        = 3'b001;
  localparam  PP_WRAPL                        = 3'b010;
  localparam  W_NBUF                          = 3'b011;
  localparam  RECALL                          = 3'b100;
  localparam  BF_SPLIT                        = 3'b101;
  localparam  W_NBUF_LK                       = 3'b110;


  //*************************************************************************************
  // I/O Decelaration
  //*************************************************************************************
  input                                    clk;
  input                                    resetn;

  input                                    hsel;
  input                                    hwrite;
  input                                    hready;
  input                                    hid_valid;
  input                                    hmastlock;
  input  [`i_axi_a2x_A2X_HBLW-1:0]                   hburst;       // AHB burst             
  input  [1:0]                             htrans;       // AHB address phase     
  input  [`i_axi_a2x_A2X_HBLW-1:0]                   hburst_dp;    // AHB burst             

  //spyglass disable_block W240
  //SMD: An input has been declared but is not read.
  //SJ : This signal is used in specific config only 
  input                                    bf_timeout; 
  //spyglass enable_block W240

  output                                   hw_ebt;
  output                                   hincr_last;
  output                                   os_w_o; 
  output                                   hw_nbuf;

  //spyglass disable_block W240
  //SMD: An input has been declared but is not read.
  //SJ : This signal is used in specific config only 
  input  [3:0]                             cache_i; 
  //spyglass enable_block W240
  input  [31:0]                            alen_i;
  input  [3:0]                             wrap_ub_len_i;

  output                                   awvalid;
  output [A2X_BLW-1:0]                     alen_o;

  output                                   wvalid;
  output                                   wlast;

  output                                   bready;      // AXI PP B Channel
  input                                    bvalid;
  input                                    bid_valid;
  input  [`i_axi_a2x_A2X_BRESPW-1:0]                 bresp;

  output                                   w_hready_resp;  // AHB Response
  output                                   w_split_resp;
  output                                   w_error_resp;
  output                                   w_retry_resp;
  output                                   w_hsplit;
  output                                   w_buf_state;
  output                                   w_recall_state;

  output                                   busy;
  output                                   nbuf_state;

  //*************************************************************************************
  //Signal Decelaration
  //*************************************************************************************
  reg    [2:0]                             state;         // Write State Machine
  reg    [2:0]                             nxt_state;
  reg    [2:0]                             bf_prev_state_r;         
  wire   [2:0]                             bf_prev_state;         
  wire                                     st_change;

  reg                                      os_w_r;        // Outstanding Write
  wire                                     os_w; 
  reg                                      os_w_ebt_r;    // Outstanding Write was EBT'd
  wire                                     os_w_ebt;

  reg    [31:0]                            wcount_r;      // AHB Write Count
  reg    [31:0]                            wcount;

  reg    [4:0]                             bcount_r;      // Burst Response Count - Maximum number of times a write can be EBT'd is 16.
  wire   [4:0]                             bcount_w;
  wire                                     wcnt_zero;
  reg                                      wcnt_zero_dp;
  wire                                     bcnt_zero;

  reg                                      w_hready_resp;
  
  //     But this may not drive any net in some other configuration. 
  reg                                      w_error_resp_r;
 
  reg     [A2X_BLW-1:0]                    alen_o;          // AXI Length
  reg                                      wlast;

  reg     [3:0]                            wrap_ub_len;
  reg     [3:0]                            wrap_ub_len_r;
  wire                                     wrapu_cnt_zero;
  reg                                      wrapu_cnt_zero_dp;

  reg                                      hawvalid_r;      // AHB Write Valid
  wire                                     hawvalid;        // AHB Write Valid
  reg                                      first_beat; 
  reg                                      hwvalid_dp;
  reg                                      hawvalid_dp;
  wire                                     hwvalid;
  wire                                     h2x_valid;

  wire                                     hburst_incr;     // AHB Burst & Transaction Type Decode
  wire                                     hburst_single;
  wire                                     hburst_wrap;
  wire                                     htrans_nseq;
  wire                                     htrans_seq;
  wire                                     htrans_idle;
  wire                                     htrans_busy;

  wire                                     hburst_dp_wrap;

  wire                                     hincr_last;

  wire                                     nbuf;            // Non-Bufferable Write
  reg                                      nbuf_dp;         // Non-Bufferable Write
  reg                                      bresp_error;     // Burst Error Response

  reg                                      hincr_r;
  reg                                      wb_beat; 

  wire                                     bf_timeout_i; 

  //*************************************************************************************
  // AHB HTRANS Decode
  // _dp -> Data Phase
  //*************************************************************************************
  assign h2x_valid         = hsel & hwrite & hready;

  assign hburst_incr       = (hburst==`i_axi_a2x_HBURST_INCR);
  assign hburst_single     = (hburst==`i_axi_a2x_HBURST_SINGLE);
  assign hburst_wrap       = ((hburst==`i_axi_a2x_HBURST_WRAP4) || (hburst==`i_axi_a2x_HBURST_WRAP8) || (hburst==`i_axi_a2x_HBURST_WRAP16));
  assign htrans_nseq       = (htrans==`i_axi_a2x_HTRANS_NSEQ);
  assign htrans_seq        = (htrans==`i_axi_a2x_HTRANS_SEQ);
  assign htrans_idle       = (htrans==`i_axi_a2x_HTRANS_IDLE);
  assign htrans_busy       = (htrans==`i_axi_a2x_HTRANS_BUSY);

  assign hburst_dp_wrap    = ((hburst_dp==`i_axi_a2x_HBURST_WRAP4) || (hburst_dp==`i_axi_a2x_HBURST_WRAP8) || (hburst_dp==`i_axi_a2x_HBURST_WRAP16));

  assign busy = |state;

  // State Machine is waiting for Non-Bufferable Response State.
  assign nbuf_state = ((state==W_NBUF) | (state==W_NBUF_LK));

  //  In Non-Split Mode signal not in use as A2X is not split configurable. 
  assign bf_timeout_i =  (A2X_SPLIT_MODE==1)? bf_timeout : 1'b0; 

  //*************************************************************************************
  // Indicated the Bufferable Status of the Transaction 
  //*************************************************************************************
  // AHB Write Data Non-Bufferable - Ignored in Bufferable Mode
  assign nbuf = (A2X_BRESP_MODE==0)? 1'b0 : (A2X_BRESP_MODE==1)? 1'b1 : ~cache_i[0]; 

  // AHB Write Data Non-Bufferable - Ignored in Bufferable Mode
  // Generate a push into WD FIFO for last data beat.
  assign hw_nbuf = st_change & ((nxt_state==W_NBUF) | (nxt_state==W_NBUF_LK)); 

  //*************************************************************************************
  // AHB Write Address Valid
  // Indicates a new AHB to AXI Write Address is valid 
  // - If NSEQ and start of transaction (!os)
  // - If previous Write was EBT'd by another write (os_w_ebt)
  // - If Transaction an AHB INCR and INCR to AXI Length count is zero. 
  // - If NSEQ and previous AHB Master has not been split due to buffer ful. 
  //*************************************************************************************
  always @(*) begin: hawvalid_PROC
    hawvalid_r = 1'b0; 
    if (h2x_valid && hid_valid) begin
      if ((state==RECALL) && htrans_nseq && (!hburst_incr) && (!hburst_single)) begin
        hawvalid_r = 1'b1;
      end else if ((state==PP_W) || (state==PP_WRAPU) || (state==PP_WRAPL)) begin
        if (htrans_nseq)
          hawvalid_r = 1'b1; 
        else if (htrans_seq && hburst_incr && wcnt_zero_dp)
          hawvalid_r = 1'b1;
        else
          hawvalid_r = 1'b0;
      end
    end
  end

  assign hawvalid = hawvalid_r & (!bf_timeout_i);
    
  //*************************************************************************************
  // Address Data Phase
  //
  // This register indicates that the Write Data Phase.
  //*************************************************************************************
  always @(posedge clk or negedge resetn) begin: dp_PROC
    if (resetn == 1'b0) begin
     hwvalid_dp <= 1'b0; 
     nbuf_dp    <= 1'b0;
    end else begin
      if (hwvalid) begin
        hwvalid_dp <= 1'b1;
        nbuf_dp    <= nbuf;
      // Push into WD FIFO not generated when busy on bus.
      end else if (hready && ((~htrans_busy) || (!hsel))) begin
        hwvalid_dp <= 1'b0;
        nbuf_dp    <= 1'b0;
      end
    end
  end

  //*************************************************************************************
  // First Address Data Phase
  //
  // This register indicates the First Write Address Data Phase.
  //*************************************************************************************
  always @(posedge clk or negedge resetn) begin: hawvalid_dp_PROC
    if (resetn == 1'b0) begin
     hawvalid_dp <= 1'b0; 
    end else begin
      if (hawvalid)
        hawvalid_dp <= 1'b1;
      else if (hready && ((~htrans_busy) || (!hsel)))
        hawvalid_dp <= 1'b0;
    end
  end

  //*************************************************************************************
  // AHB Write Data Valid 
  // Indicates Valid Write data for AXI Write if
  // -AHB Master is not returning for its non-bufferable response.
  //*************************************************************************************
  wire hwvalid_w = h2x_valid & hid_valid & (htrans_nseq | htrans_seq);
  assign hwvalid = (!bf_timeout_i) & hwvalid_w & ((state==PP_W) | (state==PP_WRAPU) | (state==PP_WRAPL)
                   | ((state==RECALL) & (!hburst_incr) & (!hburst_single)));

  //*************************************************************************************
  // Write Counter
  //
  // The counter counter the transactions based on the HTRANS. 
  //
  // Increments for each accepted AHB Write.
  //  - Resets when new AW Address Accepted and Count equals Zero. 
  //  - when count equals zero asserted a new address has to be placed on the AW Channel
  //  - If wsplit asserted transaction is retreiving Non-Bufferable Response
  //*************************************************************************************
  always @(*) begin : wcount_PROC
    if (hawvalid && ((!os_w) || (os_w && wcnt_zero_dp)))
      wcount = alen_i;
    else if (hwvalid && (!wcnt_zero_dp))
      wcount = wcount_r-1;
    else
      wcount = wcount_r; 
  end

  // Generate Write Count Zero
  assign wcnt_zero = ~(|wcount); 

  //*************************************************************************************
  // Registered Version of wcnt_zero & wcount 
  //*************************************************************************************
  always @(posedge clk or negedge resetn) begin: wcount_r_PROC
    if (resetn == 1'b0) begin
      wcount_r     <= 32'b0; 
      wcnt_zero_dp <= 1'b0; 
    end else begin
      if (hready) begin
        wcount_r     <= wcount;
        wcnt_zero_dp <= wcnt_zero;
      end else if ((A2X_SPLIT_MODE==1) && st_change && (nxt_state==BF_SPLIT)) begin
        wcount_r     <= wcount_r+1;
        wcnt_zero_dp <= 1'b0;
      end
    end
  end

  //*************************************************************************************
  //AHB Wrap Decode
  //- In the event of an EBT'd Write the A2X needs to know how many beats to
  //  the boundary so it can adjust the transaction length of the returning
  //  AHB Master. This length is the AXI length so need to add 1 to determine
  //  number of remaining beats.
  //*************************************************************************************
  always @(*) begin: WULEN_PROC
    if (hawvalid_r && hburst_wrap && ((!os_w) || (os_w && wcnt_zero_dp)))
      wrap_ub_len = wrap_ub_len_i;
    else if (hwvalid && (!wrapu_cnt_zero_dp))
       wrap_ub_len = wrap_ub_len_r-1;
     else
       wrap_ub_len = wrap_ub_len_r; 
  end
  assign wrapu_cnt_zero = ~(|wrap_ub_len);

  // Registered version of Wrap Length. 
  always @(posedge clk or negedge resetn) begin: wrapu_len_PROC
    if (resetn == 1'b0) begin
      wrap_ub_len_r       <= 4'b0;
      wrapu_cnt_zero_dp   <= 1'b0; 
    end else begin
      if (hready) begin
        wrap_ub_len_r       <= wrap_ub_len;
        wrapu_cnt_zero_dp   <= wrapu_cnt_zero;
      end else if ( ((state==PP_W) && hburst_dp_wrap) || ((state==PP_WRAPU) && hwvalid_dp) || ((state==PP_WRAPL) && hwvalid_dp)) begin
        if ((A2X_SPLIT_MODE==1) && st_change && (nxt_state==BF_SPLIT) && (!wb_beat)) begin
          wrap_ub_len_r       <= wrap_ub_len_r+1;
          wrapu_cnt_zero_dp   <= 1'b0;
        end
      end
    end
  end

  //*************************************************************************************
  // Store the Transaction Type for the AHB Data Phase
  //*************************************************************************************
  always @(posedge clk or negedge resetn) begin: hincr_PROC
    if (resetn == 1'b0) begin
      hincr_r <= 1'b0; 
    end else begin
      if (hawvalid && hburst_incr && ((!os_w) || (os_w && wcnt_zero_dp)))
        hincr_r <= 1'b1; 
      else if (hincr_last | wlast)
        hincr_r <= 1'b0; 
    end
  end
  
  // Outstanding Write required for transaction returning for a non-bufferable
  // response.
  assign hincr_last     = hincr_r & hready & (htrans_idle | htrans_nseq | (!hsel) | (!hid_valid));
  
  //*************************************************************************************
  //Register to indicate the first beat of a Write Transactions.
  //- When splitting AHB Master dueto buffer full and the transaction been
  //  split is the first beat of the transaction then the A2X does not record
  //  any information about the transaction.
  //*************************************************************************************
  always @(posedge clk or negedge resetn) begin: firstbeat_PROC
    if (resetn == 1'b0) begin
      first_beat <= 1'b0; 
    end else begin
      if (hawvalid && ((!os_w) || (os_w && wcnt_zero_dp)))
        first_beat <= 1'b1;
      else if (hready && (~htrans_busy))
        first_beat <= 1'b0;
    end 
  end

  //*************************************************************************************
  // Asserted high when last data beat of Wrap Bounday has been pushd into FIFO
  //*************************************************************************************
  always @(posedge clk or negedge resetn) begin: wdbeat_PROC
    if (resetn == 1'b0) begin
      wb_beat <= 1'b0; 
    end else begin
      if ((hwvalid && wcnt_zero) || (hwvalid_dp && wcnt_zero_dp)) begin
        wb_beat <= 1'b0;
      end else if ((state==PP_W) && hwvalid_dp && hburst_dp_wrap && wrapu_cnt_zero_dp && (!bf_timeout_i) && hready) begin 
        wb_beat <= 1'b1;
      end else if ((state==PP_WRAPL) && hwvalid_dp && wrapu_cnt_zero_dp && (!bf_timeout_i) && hready) begin
        wb_beat <= 1'b1;
      end
    end 
  end  
  
  //*************************************************************************************
  // AHB Outstanding Write Registers
  // 
  // This register indicates the start of an AHB Write transaction. When the
  // AHB transaction has completed this register is deasserted. 
  //
  // In the case of INCR transactions this register is not set as an EBT'd
  // INCR could also indicate the end of the current transaction.
  //*************************************************************************************
  // Registered Version
  always @(posedge clk or negedge resetn) begin: os_PROC
    if (resetn == 1'b0) begin
      os_w_r <= 1'b0; 
    end else begin
      // IF not INCR or SINGLE
      if (hawvalid && (!hburst_incr) && (!wcnt_zero))
        os_w_r <= 1'b1; 
      // If First Beat Split then disguard transaction.
      else if (first_beat && (~hready) && bf_timeout_i)
        os_w_r <= 1'b0;
      // Clear when wcnt equals zero
      else if ((A2X_BRESP_MODE==0) && hready && hwvalid_dp && wcnt_zero_dp && (!bf_timeout_i))
        os_w_r <= 1'b0;
      else if ((A2X_BRESP_MODE!=0) && hready && hwvalid_dp && wcnt_zero_dp && (!bf_timeout_i) && (!nbuf_dp))
        os_w_r <= 1'b0;
      else if ((A2X_BRESP_MODE!=0) && (nxt_state==PP_W) && (state==RECALL) && (A2X_SPLIT_MODE==1))
        os_w_r <= 1'b0;
      else if ((A2X_BRESP_MODE!=0) && (A2X_LOCKED==1) && (nxt_state==PP_W) && (state==W_NBUF_LK) )
        os_w_r <= 1'b0;
      else if ((A2X_BRESP_MODE!=0) && (nxt_state==PP_W) && (state==W_NBUF) && (A2X_SPLIT_MODE==0))
        os_w_r <= 1'b0;
    end
  end

  assign os_w = os_w_r;

  // Outstanding Write Output - Since register is deasserted low one clock
  // after write count goes zero.  
  assign os_w_o = os_w & (!wcnt_zero_dp);

  //*************************************************************************************
  // Outstanding Write has been EBT'd
  //
  // This register indicates that the AHB Master Defined Length Write Transaction has been
  // previously EBT'd. 
  //*************************************************************************************
  always @(posedge clk or negedge resetn) begin: os_ebt_PROC
    if (resetn == 1'b0) begin
      os_w_ebt_r <= 1'b0; 
    end else begin
      if (os_w && h2x_valid && hid_valid)
        os_w_ebt_r <= 1'b0;
      else if (hw_ebt)
        os_w_ebt_r <= 1'b1;
    end
  end

  assign os_w_ebt = os_w_ebt_r;

  // Rising edge Detect - hw_ebt only asserted for one clock cycle.
  assign hw_ebt  =  os_w & (state!=BF_SPLIT) & (!os_w_ebt) & (!hincr_r) & hwvalid_dp & (!wcnt_zero_dp) & hready & (htrans_idle | (!hsel) | (!hid_valid) | htrans_nseq); //rising edge detect

  //*************************************************************************************
  // Write State Machine
  //
  // Primary Port Write PP_W:
  // - When in this state the A2X will generate an AXI write for this AHB
  //   Master.
  // - If the AXI Channel cannot accept the AHB write transaction the state
  //   transtitions to the BF_SPLIT state. 
  //
  // Non-Bufferable Write: W_NBUF
  // - When the AHB is configured for Non-Bufferable response, a write transaction is 
  //   split on the last data beat of a defined length transaction i.e INCR16 or on the
  //   first beat of an INCR transaction. 
  //
  // Recall Split Master: RECALL
  // - When a Non-Bufferable response is returned the AHB Master is recalled. 
  //
  // - In EBT the A2X adjusts the length of an EBT'd AHB Master so that the length
  //   is up to the AHB Boundary for the fist NSEQ and number of remaining
  //   beats after the next NSEQ
  //
  //   Consider a WRAP8 EBT'd after 2 beats and
  //   there are 2 beats remaining to the boundary and 4 to complete the
  //   burst. The A2X will send three transactions 
  //   1st for Wrap8 AXI length 7
  //   2nd for returning AHB Master in EBT the A2X will generate
  //   an AXI length of 1 to complete the burst to the boundary. 
  //   3rd for the remaining burst with an AXI length of 3.
  //*************************************************************************************
  always @(*) begin: nxt_state_PROC
    nxt_state = state;
    case (state)
      PP_W: begin
        // If Transaction Split due to Buffer FUll
        if ((A2X_SPLIT_MODE==1) && bf_timeout_i && (hwvalid_dp || hwvalid_w))
          nxt_state = BF_SPLIT;
        // Wrap has not reached the upper boundary
        else if (hburst_dp_wrap && hw_ebt && (!wrapu_cnt_zero_dp))
          nxt_state = PP_WRAPU;
        // Wrap has reached lower boundary
        else if (hburst_dp_wrap && hw_ebt && wrapu_cnt_zero_dp)
          nxt_state = PP_WRAPL;
        else if ((A2X_BRESP_MODE!=0) && (A2X_LOCKED==1) && (A2X_SPLIT_MODE==1) && hwvalid && wcnt_zero && nbuf && hmastlock)
          nxt_state = W_NBUF_LK;
        // Last Beat of Non-Bufferable Transaction
        else if ((A2X_BRESP_MODE!=0) && hwvalid && wcnt_zero && nbuf)
          nxt_state = W_NBUF;
      end
      // Processing the Upper Boundary 
      PP_WRAPU: begin
        if ((A2X_SPLIT_MODE==1) && bf_timeout_i && (hwvalid_dp || hwvalid_w))
          nxt_state = BF_SPLIT;
        else if ((A2X_BRESP_MODE!=0) && (A2X_LOCKED==1) && (A2X_SPLIT_MODE==1) && hwvalid && wcnt_zero && nbuf && hmastlock)
          nxt_state = W_NBUF_LK;
        else if ((A2X_BRESP_MODE!=0) && hwvalid && wcnt_zero && nbuf)
          nxt_state = W_NBUF;
        else if (hwvalid && wcnt_zero)
          nxt_state = PP_W;
        else if (hwvalid && wrapu_cnt_zero && (!wcnt_zero))
          nxt_state = PP_WRAPL;
      end
      // Processing the Lower Boundary 
      PP_WRAPL: begin
        if ((A2X_SPLIT_MODE==1) && bf_timeout_i && (hwvalid_dp || hwvalid_w))
          nxt_state = BF_SPLIT;
        else if ((A2X_BRESP_MODE!=0) && (A2X_LOCKED==1) && (A2X_SPLIT_MODE==1) && hwvalid && wcnt_zero && nbuf && hmastlock)
          nxt_state = W_NBUF_LK;
        else if ((A2X_BRESP_MODE!=0) && hwvalid && wcnt_zero && nbuf)
          nxt_state = W_NBUF;
        else if (hwvalid && wcnt_zero) 
          nxt_state = PP_W;
      end
      BF_SPLIT:begin
        // Recall All Split States
        if ((A2X_SPLIT_MODE==1) && (!bf_timeout_i))
          nxt_state = bf_prev_state;
      end
      W_NBUF_LK: begin   
        if ((A2X_BRESP_MODE!=0) && (A2X_LOCKED==1) && bcnt_zero) nxt_state = PP_W;
      end
      W_NBUF: begin
        if (bf_timeout_i && hwvalid_dp) begin
          nxt_state = BF_SPLIT;
        end else if (bcnt_zero) begin 
          nxt_state = (A2X_SPLIT_MODE==0) ? PP_W: RECALL;
        end
      end
      RECALL: begin
        if ((A2X_SPLIT_MODE==1) && bf_timeout_i && (!hburst_incr) && (!hburst_single) && (hwvalid_dp || hwvalid_w))
          nxt_state = BF_SPLIT;
        else if (h2x_valid && hid_valid && (A2X_SPLIT_MODE==1))
          nxt_state = PP_W;
      end
      default: begin
        nxt_state = state;
      end
    endcase
  end

  //  Registered Version of State
  always @(posedge clk or negedge resetn) begin: state_PROC
    if (resetn == 1'b0) begin
      state <=  PP_W;
    end else begin
      state <= nxt_state;
    end
  end

  //********************************************************************************
  // Registered Version of Previous State
  // - This register holds the state of the A2X before a buffer full response
  //   is generated. 
  //********************************************************************************
  generate 
  if (A2X_SPLIT_MODE==1) begin: BFS
    always @(posedge clk or negedge resetn) begin: pstate_PROC
      if (resetn == 1'b0) begin
        bf_prev_state_r <=  PP_W;
      end else begin
        if (first_beat) begin 
          bf_prev_state_r <= PP_W;
        end else if ((!first_beat) && st_change && (nxt_state==BF_SPLIT)) begin
          if ((state==PP_W) && hwvalid_dp && hburst_dp_wrap && (!wb_beat)) begin
            bf_prev_state_r <= PP_WRAPU;
          end else if ((state==PP_W) && hwvalid_dp && hburst_dp_wrap && wb_beat) begin
            bf_prev_state_r <= PP_WRAPL;
          end else if ((state==PP_WRAPL) && hwvalid_dp && wrapu_cnt_zero_dp && (!wb_beat)) begin
            bf_prev_state_r <= PP_WRAPU;
          end else if ((state==PP_WRAPL) && hwvalid_dp && wrapu_cnt_zero_dp && wb_beat) begin
            bf_prev_state_r <= PP_WRAPL;
          end  else if ((state==PP_W) || (state==PP_WRAPU) || (state==PP_WRAPL)) begin 
            bf_prev_state_r <= state;
          end else if ((state==RECALL) && bf_timeout_i) begin
            bf_prev_state_r <= state;
          end
        end
      end
    end
    assign bf_prev_state = bf_prev_state_r; 
  end else begin
    assign bf_prev_state = PP_W; 
  end
  endgenerate

  // State Change
  assign st_change = (state!=nxt_state);

  // write ID in Buffer Full State is in a 
  assign w_buf_state = hid_valid & (state==W_NBUF);
  assign w_recall_state = hid_valid & (state==RECALL);

  //*************************************************************************************
  // AXI Write Address Channel
  // - When an AHB Master is returning from an EBT'd the transaction length is
  //   set to the remaining transaction length. 
  //*************************************************************************************
  assign awvalid = hawvalid;

  // AHB Master Write alen
  always @(*) begin: alen_o_PROC
    if (hid_valid && (state==PP_WRAPU))
      // spyglass disable_block W164b
      // SMD: Identifies assignments in which the LHS width is greater than the RHS width
      // SJ : This is not a functional issue, this is as per the requirement.
      //      Hence this can be waived.  
      alen_o  = (hburst_incr)? wrap_ub_len : alen_i[A2X_BLW-1:0];
    else if (hid_valid)
      alen_o  = (hburst_incr)? wcount[A2X_BLW-1:0]: alen_i[A2X_BLW-1:0];
      // spyglass enable_block W164b
    else 
      alen_o  = {A2X_BLW{1'b0}};
  end

  //*************************************************************************************
  // AXI Write Data Channel
  //*************************************************************************************
  // Write Data Valid  - Registered in h2x_w
  assign wvalid  = hwvalid; 

  // Assert Wlast when write count set to zero. 
  // Registered in h2x_w for Data Phase
  //
  // If an AHB Wrap transaction is EBt'd. The AHB master will return with to
  // transactions one to complete the burst up to the boundary and another to 
  // complete the burst from the lower boundary. To prevent the A2X from
  // writing to incorrect locations a wlast needs to be generated for the last
  // beat of the upper boundary. When the AHB returns to complete its burst
  // the A2X will generate an alen for the remaining beats. Hence the
  // incrementing burst will not wrap at the burst boundary causing incorrect
  // writes. 
  always @(*) begin:wlast_PROC
    if (hid_valid && h2x_valid && (htrans_nseq || htrans_seq)) begin
      if (state==PP_WRAPU)
        wlast = wrapu_cnt_zero;
      else if ((state==PP_WRAPL) || (state==PP_W))
        wlast = wcnt_zero;
      else 
        wlast = 1'b0; 
    end else begin
      wlast = 1'b0;
    end
  end
  
  //*************************************************************************************
  // Burst Response Counter
  //
  // This Counter contains the number of Responses to to be returned on
  // primary Port before recalling the master from Split. 
  //
  // This counter is incremented when an EBT condition is detect i.e. when we
  // have an outstanding write and awvalid is asserted. 
  //*************************************************************************************
  // spyglass disable_block FlopEConst
  // SMD: Reports permanently disabled or enabled flip-flop enable pins
  // SJ : This is not a functional issue, this is as per the requirement.
  //      Hence this can be waived.  
  always @(posedge clk or negedge resetn) begin: bcount_r_PROC
    if (resetn == 1'b0) begin
      bcount_r <= 5'b0; 
    end else begin
      // If Valid address and response returned then dont increment/decrement counter
      if (!(hawvalid && nbuf && bid_valid && bvalid)) begin 
        // If valid Address Phase increment
        if (hawvalid && nbuf) 
          bcount_r <= bcount_r + 1;
        // If Address Phase split due to buffer Full  and response returned from SP decrement by 2.
        else if ((A2X_SPLIT_MODE==1) && hawvalid_dp && st_change && (nxt_state==BF_SPLIT) && (!bcnt_zero) && bid_valid && bvalid)
          bcount_r <= bcount_r - 2;
        // If Address Phase split due to buffer Full decrement. 
        else if ((A2X_SPLIT_MODE==1) && hawvalid_dp && st_change && (nxt_state==BF_SPLIT) && (!bcnt_zero))
          bcount_r <= bcount_r - 1;
        // If valid response decrement
        else if (bid_valid && bvalid && (!bcnt_zero))
          bcount_r <= bcount_r -1;
      end
    end
  end
  // spyglass enable_block FlopEConst
  
  assign bcount_w = (A2X_BRESP_MODE==0)? 5'b0 : bcount_r;

  assign bcnt_zero = ~(|bcount_w);

  // Pop response from FIFO when available in FIFO 
  // - In Locked Mode we don't want to pop the unlock response.
  assign bready    = ((A2X_LOCKED==1) & (A2X_BRESP_MODE==1) & bid_valid & bvalid & (!bcnt_zero))? 1'b1 : (bid_valid & bvalid)? 1'b1 : 1'b0; 

  //*************************************************************************************
  // Burst Response  
  // -IF any of the AXI PP Burst response returns an error we need to store
  //  this error and return error response to the AHB Master. 
  //*************************************************************************************
  always @(posedge clk or negedge resetn) begin: bresp_r_PROC
    if (resetn == 1'b0) begin
      bresp_error <= 1'b0;
    end else begin
      if ( ((A2X_LOCKED==0) || ((A2X_LOCKED==1) & (~bcnt_zero))) && bid_valid && bvalid && bresp[1])
        bresp_error <= 1'b1;
      // A2X  will stay in PP_W State until last nbuf beat accepted. 
      // If EBT'd multiple responses may return to A2X before all addresses
      // are accepted.
      else if (state==PP_W && (!os_w))
        bresp_error <= 1'b0;
    end
  end

  //*************************************************************************************
  // HREADY Response 
  //
  // In AHB Lite Mode hready remains low until read data returned. 
  // 
  // Otherwise the AHB Master is returned a split response when W Channel accepts
  // the last beat of a Non-Bufferable Write Transaction. 
  //*************************************************************************************
  generate 
    if (A2X_SPLIT_MODE==1)
    begin
      always @(*) begin: hready_PROC
      w_hready_resp = 1'b1; 
        if ((A2X_LOCKED==1) && (nxt_state==W_NBUF_LK))
          w_hready_resp = 1'b0;
        else if (st_change && ((nxt_state==W_NBUF) || ((A2X_SPLIT_MODE==1) && (nxt_state==BF_SPLIT))) || w_error_resp)
          w_hready_resp = 1'b0; 
      end
    end
    else
    begin
      always @(*) begin: hready_PROC
        w_hready_resp = 1'b1; 
        if (nxt_state==W_NBUF)
          w_hready_resp = 1'b0;
      end
    end
  endgenerate  

  //*************************************************************************************
  // Return Split response when
  // - Last Write of Non-Bufferable Transaction
  //*************************************************************************************
  generate 
  if (A2X_SPLIT_MODE==1) begin: SPL
    assign w_split_resp =  st_change & ((nxt_state==W_NBUF) | (nxt_state==BF_SPLIT));
  end else begin
    assign w_split_resp =  1'b0;
  end
  endgenerate

  //*************************************************************************************
  // Return Error Response when
  // - B Channel returns Error
  //*************************************************************************************
  generate 
  if (A2X_BRESP_MODE==0) begin: RESP
    assign w_error_resp =  1'b0;
  end else begin
    always @(*) begin: w_error_PROC
      w_error_resp_r = 1'b0;
      if ((A2X_SPLIT_MODE==1) && st_change && (state==RECALL) && bresp_error)
        w_error_resp_r = 1'b1;
      else if ((A2X_SPLIT_MODE==1) && (A2X_BRESP_MODE!=0) && (A2X_LOCKED==1) && st_change && (state==W_NBUF_LK) && bresp_error)
        w_error_resp_r = 1'b1;
      else if ((A2X_SPLIT_MODE==0) && st_change && (state==W_NBUF) && bresp_error)
        w_error_resp_r = 1'b1;
    end
    assign w_error_resp =  w_error_resp_r;
  end
  endgenerate

  //*************************************************************************************
  // Return Retry Response - Never
  //*************************************************************************************
  assign w_retry_resp = 1'b0; 

  //*************************************************************************************
  // Split Recall
  // - When all responses are returned from the AXI PP recall AHB Master from
  //   Split. 
  //*************************************************************************************
  generate 
  if (A2X_SPLIT_MODE==1) begin: HSP
    assign w_hsplit = st_change & ((state==BF_SPLIT) | ((state==W_NBUF) & (nxt_state==RECALL)));
  end else begin
    assign w_hsplit = 1'b0;
  end
  endgenerate


endmodule

