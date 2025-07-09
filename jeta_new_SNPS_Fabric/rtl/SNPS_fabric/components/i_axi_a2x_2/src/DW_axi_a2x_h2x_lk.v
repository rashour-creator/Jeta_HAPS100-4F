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
// File Version     :        $Revision: #2 $ 
// Revision: $Id: //dwh/DW_ocb/DW_axi_a2x/axi_dev_br/src/DW_axi_a2x_h2x_lk.v#2 $ 
// --------------------------------------------------------------------
*/

`include "DW_axi_a2x_all_includes.vh"
/* --------------------------------------------------------------------
**
** File     : DW_axi_a2x_h2x_lk.v
** Created  : Thu Jan 27 11:01:40 MET 2011
** Abstract : AXI SP Locked Control
**
** The A2X must wait for a locked sequence to be granted before generating
** locked AXI SP transaction. It must also wait for the unlock transaction 
** to be granted before generating an unlock transaction on SP. 
**
** In AHB mode to A2X generates a locked transaction only when all outstanding PP 
** addresses have been accetped on the AXI SP i.e. the A2X waits until the 
** AW and AR FIFOs are empty before starting a locked transaction. 
**
** When generating a unlock transaction the also waits for the AR and AW FIFO to 
** be empty before generating the unlock transaction on the AW Channel.
**
**
** No new transactions are generatd until the AW unlock transaction has been accepted 
** on the SP. 
** --------------------------------------------------------------------
*/

//*************************************************************************************
// AHB Locked Control
//*************************************************************************************
module i_axi_a2x_2_DW_axi_a2x_h2x_lk (/*AUTOARG*/
   // Outputs
   ar_lk_req, aw_lk_req, lk_grant, lk_seq, unlk_req, unlk_grant, 
   unlk_grant_d, unlk_seq, unlk_cmp, locked, unlk_aw_pyld, 
   unlk_w_pyld, 
   // Inputs
   hclk, hresetn, hsel, hmaster, hmaster_dp, htrans, hwrite, 
   hmastlock, hready, haw_unlk_pyld, aw_push_empty, ar_push_empty, 
   w_push_empty, w_buf_full, lp_mode
   );

  //*************************************************************************************
  // Parameter Decelaration
  //*************************************************************************************
  parameter    A2X_AW_PYLD_W    = 32; 
  parameter    A2X_W_PYLD_W     = 64; 

  parameter    A2X_PP_DW        = 32; 
  parameter    A2X_WSBW         = 1;

  localparam   A2X_PP_NUM_BYTES = A2X_PP_DW/8;

  // State Machine
  localparam [2:0] ST_IDLE        = 3'b000; 
  localparam [2:0] ST_LKGRANT     = 3'b001; 
  localparam [2:0] ST_LOCK        = 3'b010; 
  localparam [2:0] ST_UNLKGRANT   = 3'b011; 
  localparam [2:0] ST_UNLOCK      = 3'b100; 
  localparam [2:0] ST_BUF_FULL    = 3'b101; 

  //*************************************************************************************
  // I/O Decelaration
  //*************************************************************************************
  input                                       hclk; 
  input                                       hresetn; 

  input                                       hsel; 
  input  [`i_axi_a2x_2_A2X_IDW-1:0]                       hmaster;
  input  [`i_axi_a2x_2_A2X_IDW-1:0]                       hmaster_dp;
  input  [1:0]                                htrans;
  input                                       hwrite;
  input                                       hmastlock;
  input                                       hready;
  input  [A2X_AW_PYLD_W-1:0]                  haw_unlk_pyld;

  input                                       aw_push_empty;
  input                                       ar_push_empty;
  input                                       w_push_empty;
  input                                       w_buf_full;
  input                                       lp_mode; 

  output                                      ar_lk_req;
  output                                      aw_lk_req;
  output                                      lk_grant;
  output                                      lk_seq;
  output                                      unlk_req;
  output                                      unlk_grant;
  output                                      unlk_grant_d;
  output                                      unlk_seq;
  output                                      unlk_cmp;

  output                                      locked;
  output [A2X_AW_PYLD_W-1:0]                  unlk_aw_pyld; 
  output [A2X_W_PYLD_W-1:0]                   unlk_w_pyld; 

  //*************************************************************************************
  // Signal Decelaration
  //*************************************************************************************
  reg  [2:0]                                  state;
  reg  [2:0]                                  nxt_state;
  wire                                        stchange;

  reg                                         ar_lk_req_r; 
  reg                                         aw_lk_req_r; 
  reg                                         unlk_req_r; 
  reg    [A2X_AW_PYLD_W-1:0]                  unlk_aw_pyld_r; 
  reg    [A2X_W_PYLD_W-1:0]                   unlk_w_pyld_r; 

  reg    [A2X_AW_PYLD_W-1:0]                  nxt_unlk_aw_pyld_r; 
  reg    [A2X_W_PYLD_W-1:0]                   nxt_unlk_w_pyld_r; 
  wire   [A2X_AW_PYLD_W-1:0]                  nxt_unlk_aw_pyld; 
  wire   [A2X_W_PYLD_W-1:0]                   nxt_unlk_w_pyld; 

  reg                                         nxt_trans_lk_r;
  reg                                         nxt_hwrite;
  wire                                        nxt_trans_lk;
  wire                                        hlock_req;
  wire                                        htrans_nseq;
  reg                                         unlk_grant_r;

  //****************************************************************************************
  // Locked Sequence Control
  //
  // AHB starts a locked transaction by asserting hmastlock when a NSEQ is
  // on the bus. When a locked sequence starts the A2X latches the address
  // information from the AHB Bus. 
  //
  // AHB terminates a locked sequence by de-asserting hmastlock, hsel or by 
  // changing the Master ID on the Bus. 
  //
  // The unlocking command is a write to the first locking address with all data bits
  // strobed. While generating this unlocking transaction the A2X responds to
  // any AHB Master request by driving hready low. Once the unlocking command
  // has been accepted by the A2X FIFO's hready is asserted high. 
  //****************************************************************************************
  assign htrans_nseq    = (htrans==`i_axi_a2x_2_HTRANS_NSEQ);
  assign hlock_req      = hsel & hready & htrans_nseq & hmastlock;

  //****************************************************************************************
  // Locked Transaction State Machine
  // 
  // localparam   ST_IDLE        = 0; 
  // localparam   ST_LKGRANT     = 1; 
  // localparam   ST_LOCK        = 2; 
  // localparam   ST_UNLKGRANT   = 3; 
  // localparam   ST_UNLOCK      = 4; 
  //****************************************************************************************
  always @(*) begin: LKSM_PROC
    nxt_state = state;
    case (state)
      ST_IDLE: begin
        // Enter a Locked State. 
        if (hlock_req)
          nxt_state = ST_LKGRANT; 
      end
      ST_LKGRANT: begin
        // When Both Address FIFO's Empty Start LOCK Sequence.
        if (aw_push_empty && ar_push_empty && w_push_empty && (!w_buf_full) && (!lp_mode)) begin 
          nxt_state = ST_LOCK;        
        end
      end
      ST_LOCK: begin
        // When Unlock Request Generated
        if (hready && ((!hmastlock) || (!hsel) || (hmaster!=hmaster_dp)))
          nxt_state = (!w_buf_full)? ST_UNLKGRANT : ST_BUF_FULL;
      end
      ST_BUF_FULL: begin
        // Wait for all Locked transactions to complete before requesting unlock.
        if (!w_buf_full)
          nxt_state = ST_UNLKGRANT;
      end
      ST_UNLKGRANT: begin
        // Wait for all locking transactions to complete before granting
        // unlocking transaction. 
        if (ar_push_empty && aw_push_empty && w_push_empty && (!lp_mode)) begin 
          nxt_state = ST_UNLOCK;
        end
      end
      ST_UNLOCK: begin
        // Wait For Unlock Transaction to Complete i.e. AW FIFO Empty.
        if ( aw_push_empty && w_push_empty) begin
          if (hlock_req | nxt_trans_lk)
            nxt_state = ST_LKGRANT;
          else 
            nxt_state = ST_IDLE;
        end
      end
      default: begin
        nxt_state = state;
      end
    endcase
  end

  // Locked State Machine
  always @(posedge hclk or negedge hresetn) begin: SM_PROC
    if (hresetn==1'b0) begin
      state <= ST_IDLE;
    end else begin
      state <= nxt_state;
    end
  end

  assign stchange   = (nxt_state!=state);
  assign locked     = ~(state==ST_IDLE);
  assign unlk_seq   = (nxt_state==ST_UNLKGRANT) | (nxt_state==ST_UNLOCK) | (state==ST_UNLOCK);
  assign lk_seq     = (nxt_state==ST_LOCK) | (nxt_state==ST_LKGRANT);

  //****************************************************************************************
  // Next Transaction is a lock Transaction
  //
  // - If in the unlocking state and a new locked transaction appears on the
  //   AHB Bus. 
  //****************************************************************************************
  always @(posedge hclk or negedge hresetn) begin: nxt_trans_lk_PROC
    if (hresetn==1'b0) begin
      nxt_trans_lk_r <= 1'b0;
      nxt_hwrite     <= 1'b0;
    end else begin
      if (stchange && (state==ST_LOCK)) begin
        if (hlock_req) begin
          nxt_trans_lk_r <= 1'b1;
          nxt_hwrite     <= hwrite;
        end
      end else if (((state==ST_UNLKGRANT) || (state==ST_UNLOCK)) && (!nxt_trans_lk_r)) begin
        if (hlock_req) begin
          nxt_trans_lk_r <= 1'b1;
          nxt_hwrite     <= hwrite;
        end
      end else if (stchange && ((nxt_state==ST_LOCK) || (nxt_state==ST_IDLE))) begin
          nxt_trans_lk_r <= 1'b0;
      end
    end
  end
  assign nxt_trans_lk = nxt_trans_lk_r;

  //****************************************************************************************
  // Next AXI Unlocking Payload
  //****************************************************************************************
  always @(posedge hclk or negedge hresetn) begin: nxtawpyld_PROC
    if (hresetn==1'b0) begin
      nxt_unlk_aw_pyld_r <= {A2X_AW_PYLD_W{1'b0}};
      nxt_unlk_w_pyld_r  <= {A2X_W_PYLD_W{1'b0}}; 
    end else begin
      // If Unlock Transaction Detected - and next transaction is a lock
      // transaction. Need to capture the next unlocking address. 
      if ( (stchange && (state==ST_LOCK)) || (state==ST_UNLKGRANT) || (state==ST_UNLOCK) )  begin
        if (hlock_req) begin
          nxt_unlk_aw_pyld_r <= haw_unlk_pyld;
          nxt_unlk_w_pyld_r  <= {{A2X_WSBW{1'b0}}, hmaster, {(A2X_PP_DW/8){1'b0}}, {A2X_PP_DW{1'b0}}, 1'b1}; 
        end
      end
    end
  end

  assign nxt_unlk_aw_pyld = nxt_unlk_aw_pyld_r;
  assign nxt_unlk_w_pyld  = nxt_unlk_w_pyld_r;

  //****************************************************************************************
  // AXI Unlocking Payload
  // - Capture the address of the First Locked address for the  unlocking
  //   command. 
  //****************************************************************************************
  always @(posedge hclk or negedge hresetn) begin: awpyld_PROC
    if (hresetn==1'b0) begin
      unlk_aw_pyld_r <= {A2X_AW_PYLD_W{1'b0}};
      unlk_w_pyld_r  <= {A2X_W_PYLD_W{1'b0}}; 
    end else begin
      if (stchange && (state==ST_IDLE)) begin
        unlk_aw_pyld_r <= haw_unlk_pyld;
        unlk_w_pyld_r  <= {{A2X_WSBW{1'b0}}, hmaster, {(A2X_PP_DW/8){1'b0}}, {A2X_PP_DW{1'b0}}, 1'b1}; 
      end else if (stchange && (state==ST_UNLOCK)) begin
        unlk_aw_pyld_r <= nxt_trans_lk? nxt_unlk_aw_pyld : haw_unlk_pyld;
        unlk_w_pyld_r  <= nxt_trans_lk? nxt_unlk_w_pyld  : {{A2X_WSBW{1'b0}}, hmaster, {(A2X_PP_DW/8){1'b0}}, {A2X_PP_DW{1'b0}}, 1'b1};
      end
    end
  end

  assign unlk_aw_pyld = unlk_aw_pyld_r;
  assign unlk_w_pyld  = unlk_w_pyld_r;

  //****************************************************************************************
  // Generate  Locking Transaction
  //****************************************************************************************
  always @(posedge hclk or negedge hresetn) begin: lkreq_PROC
    if (hresetn==1'b0) begin
      aw_lk_req_r   <= 1'b0;
      ar_lk_req_r   <= 1'b0;
    end else begin
      if (lk_grant) begin
        aw_lk_req_r   <= 1'b0;
        ar_lk_req_r   <= 1'b0;
      end else if (stchange && (nxt_state==ST_LKGRANT)) begin
        if (nxt_trans_lk_r) begin
          aw_lk_req_r   <= nxt_hwrite? 1'b1 : 1'b0;
          ar_lk_req_r   <= nxt_hwrite? 1'b0 : 1'b1;
        end else begin
          aw_lk_req_r   <= hwrite? 1'b1 : 1'b0;
          ar_lk_req_r   <= hwrite? 1'b0 : 1'b1;
        end
      end
    end
  end
  
  // Lock Request need to remain high until the AW & AR Buffers are Empty. 
  // Also when a lock transaction is requested the H2X Write/Read path needs
  // to respond with hready low until the transaction is granted. 
  assign aw_lk_req   = (stchange & (nxt_state==ST_LKGRANT) & (hlock_req & hwrite))  | aw_lk_req_r;
  assign ar_lk_req   = (stchange & (nxt_state==ST_LKGRANT) & (hlock_req & (~hwrite))) | ar_lk_req_r;

  // Grant Locking Transaction
  assign lk_grant = stchange & ((state==ST_LKGRANT) || (nxt_trans_lk & nxt_hwrite & (state==ST_LOCK)));

  //****************************************************************************************
  // Generate Unlocking Transaction
  //****************************************************************************************
  always @(posedge hclk or negedge hresetn) begin: unlkreq_PROC
    if (hresetn==1'b0)
      unlk_req_r   <= 1'b0;
    else begin
      if (unlk_grant) begin
        unlk_req_r   <= 1'b0;
      end else if (stchange && (nxt_state==ST_UNLKGRANT)) begin
        unlk_req_r   <= 1'b1;
      end
    end
  end

  // After detecting an unlocked transaction the A2X needs to responds to any
  // new transaction by driving hready low until the unlock is granted. 
  assign unlk_req = ((stchange && (nxt_state==ST_UNLKGRANT)) | unlk_req_r) & (!w_buf_full);
  
  //****************************************************************************************
  // Generate Unlocking Grant
  //****************************************************************************************
  always @(posedge hclk or negedge hresetn) begin: unlkgrant_PROC
    if (hresetn==1'b0)
      unlk_grant_r   <= 1'b0;
    else begin
      unlk_grant_r   <= unlk_grant;
    end
  end
  assign unlk_grant_d = unlk_grant_r;

  // Grant UnLocking Transaction
  assign unlk_grant = (stchange && (state==ST_UNLKGRANT));

  // After generating the unlocking transaction the A2X needs to respond to
  // any nex transactions by driving hready low until the unlocking
  // transaction is complete.
  assign unlk_cmp   = stchange & (state==ST_UNLOCK);

endmodule
