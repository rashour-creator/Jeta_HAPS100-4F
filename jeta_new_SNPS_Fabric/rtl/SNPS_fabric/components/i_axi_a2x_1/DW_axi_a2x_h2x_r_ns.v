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
// File Version     :        $Revision: #3 $ 
// Revision: $Id: //dwh/DW_ocb/DW_axi_a2x/axi_dev_br/src/DW_axi_a2x_h2x_r_ns.v#3 $ 
// --------------------------------------------------------------------
*/

`include "DW_axi_a2x_all_includes.vh"
//*************************************************************************************
// AHB Read to AXI Read Translation Non-Split Config 
// - Accepts a Read and drives hready low 
// - Returns read when data available in buffer 
//*************************************************************************************
module i_axi_a2x_1_DW_axi_a2x_h2x_r_ns (/*AUTOARG*/
   // Outputs
   r_hready_resp, r_error_resp,
 arvalid, rready, flush, busy,
   // Inputs
   clk, resetn, hwrite, hsel, hready, htrans, hburst,
   rlast, rrvalid, rresp_err
   );

  //*************************************************************************************
  // Parameter Decelaration
  //*************************************************************************************

  // Read Data State Machine
  localparam  ST_AR                              = 2'b00;
  localparam  ST_WAIT                            = 2'b01;
  localparam  ST_READ                            = 2'b10;

  //*************************************************************************************
  // I/O Decelaration
  //*************************************************************************************
  input                                    clk;
  input                                    resetn;

  input                                    hwrite;
  input                                    hsel;
  input                                    hready;
  input  [1:0]                             htrans;       
  input  [`i_axi_a2x_1_A2X_HBLW-1:0]                   hburst; 

  output                                   r_hready_resp;   // Read ID Response
  output                                   r_error_resp;

    // AXI read request    
  output                                   arvalid; 
                      
  // AXI read response & read data                       
  input                                    rrvalid;      // AXI read response valid       
  output                                   rready;
  input                                    rlast;
  input                                    rresp_err;    // Read Reponse Error
  output                                   flush;
  output                                   busy;

  //*************************************************************************************
  //Signal Decelaration
  //*************************************************************************************
  reg    [1:0]                             state;        // AHB Read State-Machine
  reg    [1:0]                             nxt_state; 
  wire                                     st_change;

  reg                                      rflush_r;
  wire                                     rflush;

  reg                                      r_hready_resp;

  //*************************************************************************************
  // State Machine
  //*************************************************************************************
  always @(*) begin: nxt_state_PROC
    nxt_state = state;
    case (state)
      ST_AR: begin
        if (hsel && hready && (~hwrite) && (htrans==`i_axi_a2x_1_HTRANS_NSEQ))
          nxt_state = ST_WAIT;
        else if (hsel && hready && (~hwrite) && (htrans==`i_axi_a2x_1_HTRANS_SEQ) && (hburst==`i_axi_a2x_1_HBURST_INCR))
          nxt_state = ST_WAIT;
      end
      // WAIT for Data to Return - hready driven low in this case.
      ST_WAIT: begin
        if ((~rflush) && rrvalid && rlast)
          nxt_state =ST_AR;
        else if ((~rflush) && rrvalid && ((~hsel) || (hsel && (htrans==`i_axi_a2x_1_HTRANS_IDLE) || (htrans==`i_axi_a2x_1_HTRANS_NSEQ))))
          nxt_state = ST_AR;
        else if ((~rflush) && rrvalid && (~rlast))
          nxt_state = ST_READ;
      end
     ST_READ: begin
        if (hready && ((~hsel) || (hsel && hwrite) || (hsel && (~hwrite) && (htrans==`i_axi_a2x_1_HTRANS_IDLE))))
          nxt_state = ST_AR;
        else if (hsel && hready && (~hwrite) && (htrans==`i_axi_a2x_1_HTRANS_NSEQ))
          nxt_state = ST_WAIT;
        else if (hsel && hready && (~hwrite) && (htrans==`i_axi_a2x_1_HTRANS_SEQ) && (~rrvalid))
          nxt_state = ST_WAIT;
        else if (hsel && hready && (~hwrite) && (htrans==`i_axi_a2x_1_HTRANS_SEQ) && rlast && rrvalid)
          nxt_state = ST_AR;
      end
      default: begin
        nxt_state = state; 
      end
    endcase
  end

  // State Machine Clocked Procedure
  always @(posedge clk or negedge resetn) begin: state_PROC
    if (resetn == 1'b0) begin
      state <=  ST_AR;
    end else begin
      state <= nxt_state;
    end
  end

  assign st_change = (state!=nxt_state);

  // If not in AR State the A2X is busy
  assign busy = |state;

  //*************************************************************************************
  // AHB Read Address & Data Valid
  // - Address Valid when NSEQ or SEQ Detected and ID doesn't have an outstanding read 
  // - Data Valid when ID has outstanding Read and ID matches RID.
  //*************************************************************************************
  reg arvalid_r; 
  always @(*) begin: arvalid_PROC
    arvalid_r = 1'b0;
    if ((state==ST_AR) && st_change) 
      arvalid_r = 1'b1;
    else if (hsel && hready && (~hwrite) && (htrans==`i_axi_a2x_1_HTRANS_NSEQ))
      arvalid_r = 1'b1;
  end
  assign arvalid = arvalid_r;
  
  //*************************************************************************************
  //*************************************************************************************
  reg rready_r; 
  always @(*) begin: rready_PROC
    rready_r = 1'b0;
    if (rflush)
      rready_r = 1'b1;
    else if ((state==ST_WAIT) && rrvalid)
      rready_r = 1'b1;
    else if ((state==ST_READ) && hsel && (~hwrite) && hready && (htrans==`i_axi_a2x_1_HTRANS_SEQ) && rrvalid)
      rready_r = 1'b1;
  end
  assign rready = rready_r; 

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
      if (rrvalid && rlast)
        rflush_r <= 1'b0;
      else if ((state==ST_WAIT) && rrvalid && ((~hsel) || (hsel && ((htrans==`i_axi_a2x_1_HTRANS_NSEQ) || (htrans==`i_axi_a2x_1_HTRANS_IDLE)))))
        rflush_r <= 1'b1;
      else if ((state==ST_READ) && hready && ((~hsel) || (hsel && ((htrans==`i_axi_a2x_1_HTRANS_NSEQ) || (htrans==`i_axi_a2x_1_HTRANS_IDLE)))))
        rflush_r <= 1'b1;
    end
  end
  
  // Needed to stop 1 cycle drop in rready_sp for INCRs who need flushing of extra pre-fetched beats
  wire flush_early = (!rflush_r) && rrvalid && (state==ST_READ) && hready && ((~hsel) || (hsel && ((htrans==`i_axi_a2x_1_HTRANS_NSEQ) || (htrans==`i_axi_a2x_1_HTRANS_IDLE))));

  assign rflush = rflush_r || flush_early;
  assign flush  = rflush; // Send to module output 
   
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
    if (nxt_state==ST_WAIT)
      r_hready_resp = 1'b0; 
    else if ((~rflush) && rready && rrvalid && rresp_err)
      r_hready_resp = 1'b0; 
  end
    
  //*************************************************************************************
  // Return Error response when
  // - R Channel returns error response 
  //*************************************************************************************
  assign r_error_resp = rrvalid && rready && rresp_err && (~rflush);


endmodule

