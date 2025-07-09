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
// Revision: $Id: //dwh/DW_ocb/DW_axi_a2x/axi_dev_br/src/DW_axi_a2x_sp_lk.v#2 $ 
// --------------------------------------------------------------------
*/
/** --------------------------------------------------------------------
**
** File     : DW_axi_a2x_sp_lk.v
** Created  : Thu Jan 27 11:01:40 MET 2011
** Abstract : AXI SP Locked Control
**
** The A2X must wait for a locked sequence to be granted before generating
** locked AXI SP transactioin. It must also wait for the unlock transaction 
** to be granted before generating an unlock transaction on SP. 

** --------------------------------------------------------------------
*/

`include "DW_axi_a2x_all_includes.vh"
module i_axi_a2x_2_DW_axi_a2x_sp_lk (/*AUTOARG*/
   // Outputs
   lock_grant, 
                         unlock_grant, 
                         lockseq_cmp, 
                         sp_locked, 
                         unlock_seq, 
                         // Inputs
                         clk_sp, 
                         resetn_sp, 
                         ar_osr_trans, 
                         aw_osw_trans, 
                         aw_lock_req, 
                         ar_lock_req, 
                         aw_unlock_req, 
                         ar_unlock_req, 
                         ar_os_unlock, 
                         aw_os_unlock
                         );

  //*************************************************************************************
  // I/O Decelaration
  //*************************************************************************************
  input                                       clk_sp; 
  input                                       resetn_sp; 

  input                                       ar_osr_trans;
  input                                       aw_osw_trans;

  input                                       aw_lock_req;
  input                                       ar_lock_req;
  input                                       aw_unlock_req;
  input                                       ar_unlock_req;
  input                                       ar_os_unlock;
  input                                       aw_os_unlock;

  output                                      lock_grant;
  output                                      unlock_grant;
  output                                      lockseq_cmp;
  output                                      sp_locked;
  output                                      unlock_seq; 

  reg                                         sp_locked_r;
  reg                                         unlock_seq_r; 
  reg                                         lock_grant_r;
  reg                                         unlock_grant_r;
  reg                                         lockseq_cmp_r;

  //****************************************************************************************
  // Grant SP Locked Transaction
  //****************************************************************************************
  always @(posedge clk_sp or negedge resetn_sp) begin: lk_grant_PROC
    if (resetn_sp==1'b0) begin
      lock_grant_r  <= 1'b0;
    end else begin
      // IF Read Lock Request Wait for All writes to complete
      // IF Write Lock Request Wait for All reads to complete
      if ( (ar_lock_req || aw_lock_req) && ((~aw_osw_trans) && (~ar_osr_trans)) )
        lock_grant_r <= 1'b1;
      // Only Want the grant high for one cycle
      else if (lock_grant_r)
        lock_grant_r <= 1'b0;
    end
  end

  assign lock_grant = lock_grant_r; 

  //****************************************************************************************
  // Grant SP UnLocked Transaction
  //****************************************************************************************
  always @(posedge clk_sp or negedge resetn_sp) begin: arunlk_grant_PROC
    if (resetn_sp==1'b0) begin
      unlock_grant_r  <= 1'b0;
    end else begin
      // IF Write UnLock Request Wait for outstanding transactions to complete
      if ( (aw_unlock_req || ar_unlock_req) && ((~ar_osr_trans) && (~aw_osw_trans)) )
        unlock_grant_r <= 1'b1;
      // Only Want the grant high for one cycle
      else if (unlock_grant_r)
        unlock_grant_r <= 1'b0;
    end
  end
  assign unlock_grant = unlock_grant_r; 

  //****************************************************************************************
  // Acknowledge Completion of SP UnLocked Transaction
  //****************************************************************************************
  // Locked Sequence is complete when there is no outstanding Read/Write Transactions. 
  always @(posedge clk_sp or negedge resetn_sp) begin: lkseqcmp_PROC
    if (resetn_sp==1'b0) begin
      lockseq_cmp_r  <= 1'b0;
    end else begin
      // IF UnLock set Wait for response to complete
      if ((aw_os_unlock && (~aw_osw_trans)) || (ar_os_unlock && (~ar_osr_trans)) )
        lockseq_cmp_r <= 1'b1;
      // Only Want the grant high for one cycle
      else if (lockseq_cmp_r)
        lockseq_cmp_r <= 1'b0;
    end
  end
  assign lockseq_cmp  = lockseq_cmp_r;

  //****************************************************************************************
  //Locked Sequence Control
  //
  // AXI can only issue a locked transfer when 
  // 1. all outstanding write have completed. 
  // 2. all outstanding reads have completed.
  // 3. the write data for the locked ahb master is at the head of the data FIFO 
  //****************************************************************************************
  always @(posedge clk_sp or negedge resetn_sp) begin: lk_PROC
    if (resetn_sp==1'b0) begin
      sp_locked_r <= 1'b0;
    end else begin
      if (lock_grant)
        sp_locked_r <= 1'b1;
      else if (lockseq_cmp)
        sp_locked_r <= 1'b0;
    end
  end

  assign sp_locked = sp_locked_r;

  //****************************************************************************************
  // SP UnLock Sequence
  //****************************************************************************************
  always @(posedge clk_sp or negedge resetn_sp) begin: unlk_seq_PROC
    if (resetn_sp==1'b0) begin
      unlock_seq_r <= 1'b0;
    end else begin
      if (unlock_grant)
        unlock_seq_r <= 1'b1;
      else if (lockseq_cmp)
        unlock_seq_r <= 1'b0;
    end
  end

  assign unlock_seq = unlock_seq_r; 


endmodule

