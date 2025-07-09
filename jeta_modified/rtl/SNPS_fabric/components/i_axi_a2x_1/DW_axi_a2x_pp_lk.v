/* --------------------------------------------------------------------
**
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
// Revision: $Id: //dwh/DW_ocb/DW_axi_a2x/amba_dev/src/DW_axi_a2x_pp_lk.v#1 $ 
**
** --------------------------------------------------------------------
**
** File     : DW_axi_a2x_pp_lk.v
** Created  : Thu Jan 27 11:01:40 MET 2011
** Abstract : AXI PP Locked Control
**
** This Block is only in use for AXI Bufferabel Configurations. Its function is to 
** delay any new transaction on the primary port until the AW and AR FIFO is empty 
** before granting a locked transaction. Similarly for a unlock transaction its function 
** is to delay any further transactions on the primary port until the unlock transaction 
** is granted. 
** --------------------------------------------------------------------
*/
`include "DW_axi_a2x_all_includes.vh"

module i_axi_a2x_1_DW_axi_a2x_pp_lk (/*AUTOARG*/
   // Outputs
   awready_pp_o, arready_pp_o, awvalid_pp_o, arvalid_pp_o,
   // Inputs
   clk_pp, resetn_pp, awvalid_pp, arvalid_pp, arready_pp_i, 
   awready_pp_i, awlock_pp, arlock_pp, aw_fifo_empty, ar_fifo_empty
   );

  //*************************************************************************************
  // Parameter Decelaration
  //*************************************************************************************

  //*************************************************************************************
  // I/O Decelaration
  //*************************************************************************************
  input                                       clk_pp; 
  input                                       resetn_pp; 

  input                                       awvalid_pp;
  input                                       arvalid_pp;
  input                                       arready_pp_i;
  input                                       awready_pp_i;
  input  [`A2X_LTW-1:0]                       awlock_pp;   
  input  [`A2X_LTW-1:0]                       arlock_pp;   

  input                                       aw_fifo_empty;
  input                                       ar_fifo_empty;

  output                                      awready_pp_o;
  output                                      arready_pp_o;
  output                                      awvalid_pp_o;
  output                                      arvalid_pp_o;

  //*************************************************************************************
  // Signal Decelaration
  //*************************************************************************************
  reg                                         lock_start_r;
  reg                                         lock_seq_r;
  reg                                         unlock_seq_r;
  wire                                        lock_start;
  wire                                        lock_seq;
  wire                                        unlock_seq;

  wire                                        aw_lock_req;
  wire                                        ar_lock_req;
  wire                                        aw_unlock_req;
  wire                                        ar_unlock_req;

  //****************************************************************************************
  // Request Locked Transaction
  //****************************************************************************************
  assign ar_lock_req   = arvalid_pp & arready_pp_o & (arlock_pp==2'b10);
  assign aw_lock_req   = awvalid_pp & awready_pp_o & (awlock_pp==2'b10);
  
  assign ar_unlock_req = lock_seq & arvalid_pp & arready_pp_o & (arlock_pp!=2'b10);
  assign aw_unlock_req = lock_seq & awvalid_pp & awready_pp_o & (awlock_pp!=2'b10);

  //****************************************************************************************
  // Lock Start 
  //****************************************************************************************
  always @(posedge clk_pp or negedge resetn_pp) begin: lk_start_PROC
    if (resetn_pp==1'b0) begin
      lock_start_r  <= 1'b0;
    end else begin
      if (aw_lock_req || ar_lock_req)
        lock_start_r <= 1'b1;
      else if (aw_fifo_empty && ar_fifo_empty)
        lock_start_r <= 1'b0;
    end
  end

  assign lock_start = lock_start_r; 

  //****************************************************************************************
  // Lock Sequence
  //****************************************************************************************
  // spyglass disable_block FlopEConst
  // SMD: Reports permanently disabled or enabled flip-flop enable pins
  // SJ : This is not a functional issue, this is as per the requirement.
  //      Hence this can be waived.  
  always @(posedge clk_pp or negedge resetn_pp) begin: lk_seq_PROC
    if (resetn_pp==1'b0) begin
      lock_seq_r  <= 1'b0;
    end else begin
      if (aw_lock_req || ar_lock_req)
        lock_seq_r <= 1'b1;
      else if (aw_unlock_req || ar_unlock_req)
        lock_seq_r <= 1'b0;
    end
  end
  // spyglass enable_block FlopEConst

  assign lock_seq = lock_seq_r; 


  //****************************************************************************************
  // Unlock Sequence
  //****************************************************************************************
  // spyglass disable_block FlopEConst
  // SMD: Reports permanently disabled or enabled flip-flop enable pins
  // SJ : This is not a functional issue, this is as per the requirement.
  //      Hence this can be waived.  
  always @(posedge clk_pp or negedge resetn_pp) begin: unlk_seq_PROC
    if (resetn_pp==1'b0) begin
      unlock_seq_r  <= 1'b0;
    end else begin
      if (aw_unlock_req || ar_unlock_req) 
        unlock_seq_r <= 1'b1;
      else if (aw_fifo_empty && ar_fifo_empty)
        unlock_seq_r <= 1'b0;
    end
  end
  // spyglass enable_block FlopEConst

  assign unlock_seq = unlock_seq_r;

  //****************************************************************************************
  // Primary Port AW and AR Channel Ready
  //****************************************************************************************
  assign arready_pp_o = (unlock_seq | lock_start)? 1'b0 : arready_pp_i;
  assign awready_pp_o = (unlock_seq | lock_start)? 1'b0 : awready_pp_i;

  assign arvalid_pp_o = (unlock_seq | lock_start)? 1'b0 : arvalid_pp;
  assign awvalid_pp_o = (unlock_seq | lock_start)? 1'b0 : awvalid_pp;

endmodule
//Revision: $Id: //dwh/DW_ocb/DW_axi_a2x/amba_dev/src/DW_axi_a2x_pp_lk.v#1 $
