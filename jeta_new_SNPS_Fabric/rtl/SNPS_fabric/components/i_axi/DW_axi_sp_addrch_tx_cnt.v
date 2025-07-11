/* ---------------------------------------------------------------------
**
// ------------------------------------------------------------------------------
// 
// Copyright 2001 - 2023 Synopsys, INC.
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
// Component Name   : DW_axi
// Component Version: 4.06a
// Release Type     : GA
// Build ID         : 18.26.9.4
// ------------------------------------------------------------------------------

// 
// Release version :  4.06a
// File Version     :        $Revision: #5 $ 
// Revision: $Id: //dwh/DW_ocb/DW_axi/axi_dev_br/src/DW_axi_sp_addrch_tx_cnt.v#5 $ 
**
** ---------------------------------------------------------------------
**
** File     : DW_axi_sp_addrch_tx_cnt.v
//
** Created  : Tue May 24 17:09:09 MEST 2005
** Modified : $Date: 2023/10/04 $
**
** ---------------------------------------------------------------------
*/

`include "DW_axi_all_includes.vh"

// Local module to count outstanding transactions.
module i_axi_DW_axi_sp_addrch_tx_cnt (
  clk_i,
  resetn_i,
  tx_acc_i,
  tx_cpl_i,
  cnt_max_o,
  cnt_nz_o
);

  parameter CNT_W = 1; // Count width.
  parameter CNT_MAX = 1; // Count max.
  parameter [0:0] REG_OUTPUT = 1; // Registered or combinatorial output.

  localparam [CNT_W-1:0] COUNT_MAX = CNT_MAX;

  input clk_i;
  input resetn_i;
  input tx_acc_i; // T/x accepted.
  input tx_cpl_i; // T/x completed.
  output cnt_max_o; // T/x count at max.
  output cnt_nz_o; // T/x count non zero.
  
  // signal not used in read channel instantiations
  reg [CNT_W-1:0] txcount; // Pre reg tx count.
  //LMD: Change on net has no effect on any of the outputs 
  //LJ: register not used if REG_OUTPUT==0
  reg  [CNT_W-1:0] txcount_r; // T/x count register.

  always @(*) 
  begin : txcount_PROC
    case({tx_cpl_i, tx_acc_i})
      // No tx's accepted or completed, or
      // tx accepted and another completed in the same cycle.
      // Both imply no change to transaction count.
      2'b00,
      2'b11 : txcount = txcount_r;

      // Transaction accepted, increment transaction count.
      2'b01 : txcount = txcount_r + 1'b1;
  
      // Transaction completed, decrement transaction count.
      2'b10 : txcount = txcount_r - 1'b1;
    endcase
  end // txcount_PROC

  always @(posedge clk_i or negedge resetn_i)
  begin : txcount_r_PROC
    if(!resetn_i) begin
      txcount_r <= {CNT_W{1'b0}};
    end else begin
      txcount_r <= txcount;
    end
  end // txcount_r_PROC

  assign cnt_max_o = (REG_OUTPUT ? txcount_r : txcount) == COUNT_MAX;
  assign cnt_nz_o = (REG_OUTPUT ? txcount_r : txcount) != {CNT_W{1'b0}};

endmodule
