/* --------------------------------------------------------------------
// ------------------------------------------------------------------------------
// 
// Copyright 2012 - 2020 Synopsys, INC.
// 
// This Synopsys IP and all associated documentation are proprietary to
// Synopsys, Inc. and may only be used pursuant to the terms and conditions of a
// written license agreement with Synopsys, Inc. All other use, reproduction,
// modification, or distribution of the Synopsys IP or the associated
// documentation is strictly prohibited.
// 
// Component Name   : DW_axi_a2x
// Component Version: 2.04a
// Release Type     : GA
// ------------------------------------------------------------------------------

// 
// Release version :  2.04a
// File Version     :        $Revision: #1 $ 
// Revision: $Id: //dwh/DW_ocb/DW_axi_a2x/amba_dev/src/DW_axi_a2x_h2x_r_id.v#1 $ 
// --------------------------------------------------------------------
*/

`include "DW_axi_a2x_all_includes.vh"
//*************************************************************************************
// AHB Read to AXI Read Translation Per ID 
// - Accepts a Read and Returns a split response
// - Recalls Read from Split when data rrvalid asserted.
// - Returns Read Data when recalled master sends a read request to the A2X
// - Returns split for FIFO Full status.
// - Recalls Split masters when FIFO space available. 
//*************************************************************************************
module i_axi_a2x_DW_axi_a2x_h2x_r_id (/*AUTOARG*/
   // Outputs
   r_hready_resp, r_split_resp, r_retry_resp, r_error_resp, r_hsplit, hburst_o, hburst_vld_o,
   arvalid, rready, flush, busy,
   // Inputs
   clk, resetn, hwrite, hsel, hready, htrans_nseq,
   htrans_seq, htrans_idle, recall_vld, hid_valid, rid_valid, rlast, hburst_i,
   arready, rrvalid, rresp_err
   );

  
  //*************************************************************************************
  // Parameter Decelaration
  //*************************************************************************************
  parameter   AR_BUF_FULL_EN                  = 0; 

  // Read Data State Machine
  localparam  AR                              = 3'b000;
  localparam  AR_FULL                         = 3'b001;
  localparam  RECALL                          = 3'b010;
  localparam  READ                            = 3'b011;
  localparam  R_SPLIT                         = 3'b100;
  localparam  RD_NSEQ                         = 3'b101;

  
  //*************************************************************************************
  // I/O Decelaration
  //*************************************************************************************
  input                                    clk;
  input                                    resetn;

  input                                    hwrite;
  input                                    hsel;
  input                                    hready;
  input                                    htrans_nseq;
  input                                    htrans_seq;
  input                                    htrans_idle;
  input                                    hid_valid;

  input                                    recall_vld;       
  input                                    rid_valid;       // ID Valid
  input                                    rlast;

  input  [`A2X_HBLW-1:0]                   hburst_i;
  output [`A2X_HBLW-1:0]                   hburst_o;
  output                                   hburst_vld_o;

  output                                   r_hready_resp;   // Read ID Response
  output                                   r_split_resp;
  output                                   r_retry_resp;
  output                                   r_error_resp;
  output                                   r_hsplit; 

  // AXI read request    
  input                                    arready;      // AXI read ready             
  output                                   arvalid; 
                      
  // AXI read response & read data                       
  input                                    rrvalid;      // AXI read response valid       
  output                                   rready;
  input                                    rresp_err;    // Read Reponse Error
  output                                   flush;
  output                                   busy;

  //*************************************************************************************
  //Signal Decelaration
  //*************************************************************************************
  reg                                      os_incr_r;    // Outstanding Read is an INCR
  wire                                     os_incr;      

  wire                                     hrvalid;      // Valid AHB Read Data

  reg    [2:0]                             state;        // AHB Read State-Machine
  reg    [2:0]                             nxt_state; 
  wire                                     st_change;

  wire                                     r_hsplit;     // Split Recall AHB Master
  reg                                      r_split_resp_d;

  reg                                      rflush_r;
  wire                                     rflush;

  reg                                      r_hready_resp;
  reg                                      resp_err_r;   // Read Response Returned ERROR
  reg                                      hburst_vld_r;

  wire                                     hburst_incr;
  wire                                     hburst_vld_w;
  reg    [`A2X_HBLW-1:0]                   hburst_r;       
  wire   [`A2X_HBLW-1:0]                   hburst_w;       

  //*************************************************************************************
  //*************************************************************************************
  assign hburst_incr = (hburst_vld_w)? (hburst_w==`HBURST_INCR) : (hburst_i==`HBURST_INCR);

  wire   h2x_valid   = hsel & hready & (~hwrite);
  assign hrvalid     = h2x_valid & hid_valid & (htrans_nseq | htrans_seq);

  // If not in AR state the A2X is busy.
  assign busy = |state;

  //*************************************************************************************
  // Read Data State Machine
  // - three Stages in returning the read data to master
  // 1. Recall the master from Split
  // 2. Return the read data
  // 3. Flush Read Data if INCR
  //
  // If ERROR Response is returned to the AHB Master and that AHB Master does not
  // return to retrieve its remaining read data, the read data is flushed from the PP R 
  // Channel. If HTRANS returns to the BUS with NSEQ or IDLE, the State Machine assumes
  // the AHB Master is not returning and flushes the read data. 
  //
  // AR State:(0) 
  // - Remain in this state until a successful AHB Read Address is accepted. When AR address
  //   accepted transtition to RECALL state. 
  //   If a valid AHB Address is detected and AR is inactive enter AR_FULL State. AHB Master 
  //   is split in this condition. 
  //
  // AR FUll State (1):
  // - Remain in this state until AR Channel becomes active again. Transtition
  //   back to AR state when AR Channel active. AHB Master is recalled from split.  
  //
  // READ SPLIT State (4):
  // - Remain in this state until read data becomes available.
  //
  // RECALL State (2):
  // - Remain in this state until valid read data for this ID is available on
  //   A2X PP R channel. When valid read data available recall AHB Master from
  //   Split and transtition to READ state.
  //
  //   If a previous Read Request required its data to be flushed from the PP R 
  //   Channel the AHB  Master will not be recalled until previous read data is 
  //   flushed from PP R Channel.
  //
  // READ State (3)
  // - Remain in this state until all read data is returned to AHB Master. 
  //
  // - If the PP R channel becomes inactive during a valid read data request
  //   the AHB Master will be split and a transtition to R_SPLIT state will
  //   occur. 
  //
  // - If the PP R Channel returns a different Read ID and the AHB Master is
  //   attempting to retrieve its data, this AHB Master is split. The state
  //   machine transitions to RECALL state. 
  //
  // - If the read Channel deasserts rready during the read data phase (FIFO
  //   Empty), the state machine transitions to the read empty state. The AHB
  //   Master is returned a split response in the condition. 
  //
  // - If an ERROR is returned to the AHB Master and the AHB Master does not
  //   return to retrieve the rest of its data the state machine transtitions
  //   to the AR State. A new AR address can be accepted but AHB  Master will
  //   not be recalled until previous read data is flushed from PP R Channel.
  //
  // - If initial read request was for an AHB INCR and the AHB INCR request
  //   completed before all the prefetched read data was retrieved from the
  //   R PP Channel, the state machine transtitions to the Flush state. A new 
  //   AR address can be accepted but AHB  Master will not be recalled until 
  //   previous read data is flushed from PP R Channel.
  //
  //*************************************************************************************

  always @(*) begin: nxt_state_PROC
    nxt_state = state;
    case (state)
      AR: begin
        if (hrvalid && (!arready) && (AR_BUF_FULL_EN==1))
             nxt_state = AR_FULL;
        else if (hrvalid && arready)
          nxt_state = R_SPLIT; 
      end
      AR_FULL: begin
         if (arready && (!r_split_resp_d))
          nxt_state = AR; 
      end
      R_SPLIT: begin
        // Can't generate hsplit while generating a split response.
        if (hready) nxt_state = RECALL;
      end
      RECALL: begin
        // Have to wait for previous read data to be flushed from FIFO before
        // continuing with the next read transaction.
        if (recall_vld && (!rflush)) begin
            nxt_state = RD_NSEQ;
        end
      end
      RD_NSEQ:begin
        // When AHB Master Recalled the First Beat is always returned to the AHB Master
        if (h2x_valid && hid_valid && htrans_nseq && rid_valid && rrvalid && rlast)
          nxt_state = AR;
        // When First Beat returned move to Read State.
        else if (h2x_valid && hid_valid && htrans_nseq && rid_valid && rrvalid)
          nxt_state = READ; 
        // If Different RID at head of Read Pipeline i.e. Master returned two soon.
        else if (hrvalid && ((!rrvalid) || (!rid_valid))) 
          nxt_state = R_SPLIT;
      end
      READ: begin
        // If INCR transaction and already received and NSEQ and another NSEQ appears. 
        // We need to generate a new address and flush data buffer.
        if (os_incr && h2x_valid && hid_valid && htrans_nseq && arready)
          nxt_state = R_SPLIT;
        else if ((AR_BUF_FULL_EN==1) && os_incr && h2x_valid && hid_valid && htrans_nseq && (!arready))
          nxt_state = AR_FULL;
        // If INCR Transaction Completed 
        else if (os_incr && ((!hsel) || (hready && ((!hid_valid) || hwrite || htrans_idle))))
          nxt_state = AR;
        // If error response returned and Master does not continue.
        else if (hready && resp_err_r && (htrans_idle || (!hsel) || hwrite || (!hid_valid))) 
          nxt_state = AR;
        // If error response returned and Master continues with new transaction
        else if (hready && resp_err_r && hid_valid && htrans_nseq && arready) 
          nxt_state = R_SPLIT;
        else if ((AR_BUF_FULL_EN==1) && hready && resp_err_r && hid_valid && htrans_nseq && (!arready)) 
          nxt_state = AR_FULL;
        // If Different RID at head of R PP Channel or R FIFO Empty
        else if (hrvalid && ((!rrvalid) || (!rid_valid))) 
          nxt_state = R_SPLIT;
        // If Last Beat of Read Data received
        else if (hrvalid && rid_valid && rlast && rrvalid)
          nxt_state = AR;
      end
      default: begin
        nxt_state = state; 
      end
    endcase
  end

  // State Machine Clocked Procedure
  always @(posedge clk or negedge resetn) begin: state_PROC
    if (resetn == 1'b0) begin
      state <=  AR;
    end else begin
      state <= nxt_state;
    end
  end

  assign st_change = (state!=nxt_state);

  //*************************************************************************************
  // AHB Read Address
  // - Address Valid when NSEQ or SEQ Detected and ID doesn't have an outstanding read 
  // - Data Valid when ID has outstanding Read and ID matches RID.
  //*************************************************************************************
  reg arvalid_r; 
  always @(*) begin: arvalid_PROC
    arvalid_r = 1'b0;
    if ((state==AR) && (nxt_state==R_SPLIT))
      arvalid_r = 1'b1;
    else if ((state==READ) && os_incr && h2x_valid && hid_valid && htrans_nseq)
      arvalid_r = 1'b1;
    else if ((state==READ) && h2x_valid && hid_valid && resp_err_r && htrans_nseq)
      arvalid_r = 1'b1;
  end
  assign arvalid = arvalid_r;
  
  //*************************************************************************************
  // AHB Read Data FIFO pop
  //*************************************************************************************
  reg rready_r; 
  always @(*) begin: rready_PROC
    rready_r = 1'b0;
    // Need to Pop when rlast detect on FIFO and EBT Condition as rflush will
    // not be asserted.
    if (rflush && rid_valid)
      rready_r = 1'b1;
    else if ((state==RD_NSEQ) && hrvalid && rid_valid && rrvalid)
      rready_r = 1'b1;
    else if ((state==READ) && hrvalid && rid_valid && rrvalid)
      rready_r = 1'b1; 
    else if ((state==READ) && (nxt_state==AR) && rid_valid && rrvalid)
      rready_r = 1'b1; 
  end
  assign rready = rready_r; 

  //*************************************************************************************
  // AHB Read INCR Registers
  //
  // When a INCR read is accepted on the PP this register is asserted.  
  // When an AHB INCR Read has completed this register is cleared. 
  //*************************************************************************************

  generate 
  if (AR_BUF_FULL_EN==1) begin: HB
    always @(posedge clk or negedge resetn) begin: burst_r_PROC
      if (resetn == 1'b0) begin
        hburst_r      <= {`A2X_HBLW{1'b0}}; 
        hburst_vld_r <= 1'b0; 
      end else begin
        if ((nxt_state==AR_FULL) && (~hburst_vld_r) && htrans_nseq && hid_valid && h2x_valid && (~hburst_incr)) begin
          hburst_r      <= hburst_i;
          hburst_vld_r  <= 1'b1; 
        end else if (state==RECALL) begin
          hburst_r     <= {`A2X_HBLW{1'b0}};    
          hburst_vld_r <= 1'b0; 
        end
      end
    end
    assign hburst_w      = hburst_r;
    assign hburst_vld_w  = hburst_vld_r;
    assign hburst_o      = (hid_valid)? hburst_r     : {(`A2X_HBLW){1'b0}}; 
    assign hburst_vld_o  = (hid_valid)? hburst_vld_r : 1'b0; 
  end else begin
    assign hburst_w      = {`A2X_HBLW{1'b0}};
    assign hburst_vld_w  = 1'b0;
    assign hburst_o      = {(`A2X_HBLW){1'b0}}; 
    assign hburst_vld_o  = 1'b0; 
  end
  endgenerate

  //*************************************************************************************
  // AHB Read INCR Registers
  //
  // When a INCR read is accepted on the PP this register is asserted.  
  // When an AHB INCR Read has completed this register is cleared. 
  //*************************************************************************************
  always @(posedge clk or negedge resetn) begin: os_incr_PROC
    if (resetn == 1'b0) begin
      os_incr_r <= 1'b0; 
    end else begin
      if (arvalid_r)
        os_incr_r <= hburst_incr | htrans_seq;
      else if ((~rflush) && hrvalid && rid_valid && rrvalid && rlast) 
        os_incr_r <= 1'b0;
    end
  end

  assign os_incr = os_incr_r;

  //*************************************************************************************
  // Error Response
  //
  // If the A2X returns an Error response this response is stored and used to
  // determine if the AHB Master resturns for the rest of its read data. 
  //
  // If an AHB Master does not return for the rest of its read data the
  // remaining read data is flushed from the read data buffer. 
  //*************************************************************************************
  always @(posedge clk or negedge resetn) begin: error_PROC
    if (resetn == 1'b0) begin
      resp_err_r  <= 1'b0; 
    end else begin
      if ((state==RD_NSEQ) && rrvalid && rresp_err && hrvalid)
        resp_err_r <= 1'b1;
      else if ((state==READ) && rrvalid && rresp_err && hrvalid)
        resp_err_r <= 1'b1;
      else if (hready)
        resp_err_r <= 1'b0;
    end
  end

  //*************************************************************************************
  // Read Data Flush 
  //
  // Flush Read Data from PP R Channel when Error returned to AHB Master and
  // that Master does not return to retrieve its data or if the AHB Master
  // does not require all the read prefetched data for a INCR Read. 
  //*************************************************************************************
  always @(posedge clk or negedge resetn) begin: arsplit_PROC
    if (resetn == 1'b0) begin
      rflush_r  <= 1'b0; 
    end else begin
      // When FIFO is empty output is unknown so must use the FIFO valid
      // status before deaserting.
      if (rid_valid && rlast && rrvalid)
        rflush_r <= 1'b0;
      else if ((state==READ) && arvalid_r) 
        rflush_r <= 1'b1;
      else if ((state==READ) && (nxt_state==AR)) 
        rflush_r <= 1'b1;
    end
  end
  
  assign rflush = rflush_r;
  assign flush  = rid_valid & rflush; // Send to module output 
   
  //*************************************************************************************
  // Read Split Recall- Split Recall AHB Master 
  //*************************************************************************************
  assign r_hsplit =  (((state==AR_FULL) || (state==RECALL)) && st_change);

  //*************************************************************************************
  // HREADY Response 
  //
  // In AHB Lite Mode hready remains low until read data returns. 
  // 
  // Otherwise the AHB Master is returned a split response when AR  acceppted
  // on A2X PPAR Channel or if during a read data phase the read channel is
  // inactive (rvalid low) or a different read id appears at head of PP
  // R Channel.
  //*************************************************************************************
  always @(*) begin: hready_PROC
    r_hready_resp = 1'b1; 
    if (st_change && (nxt_state==R_SPLIT || nxt_state==AR_FULL))
      r_hready_resp = 1'b0;
    else if (hrvalid && rresp_err && (state==READ))
      r_hready_resp = 1'b0; 
  end
    
  //*************************************************************************************
  // Return Split Response 
  // 
  // The AHB Master is returned a split response when AR acceppted
  // on A2X PP AR Channel or if during a read data phase the read channel is
  // inactive (rvalid low) or a different read id appears at head of PP
  // R Channel.
  //
  // Rising Edge indicates to the H2X response block to return a split
  // response.
  //*************************************************************************************
  reg r_split_resp_r; 
  always @(*) begin: split_resp_PROC
    r_split_resp_r = 1'b0;
    if (st_change && (nxt_state==R_SPLIT || nxt_state==AR_FULL))
      r_split_resp_r = 1'b1;
  end


  assign r_split_resp = r_split_resp_r;

  // Registered Version 
  always @(posedge clk or negedge resetn) begin: rsplit_PROC
    if (resetn == 1'b0) begin
      r_split_resp_d <= 1'b0; 
    end else begin
      r_split_resp_d <= r_split_resp; 
    end
  end


  //*************************************************************************************
  // Return Error response when
  // - R Channel returns error response 
  //*************************************************************************************
  assign r_error_resp  = (((state==RD_NSEQ) || (state==READ)) && rresp_err && hrvalid) ? 1'b1 : 1'b0;

  //*************************************************************************************
  // Return Retry response - Never
  //*************************************************************************************
  assign r_retry_resp = 1'b0; 

endmodule
