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
// Revision: $Id: //dwh/DW_ocb/DW_axi_a2x/amba_dev/src/DW_axi_a2x_busy_osx.v#1 $ 
// --------------------------------------------------------------------
*/

`include "DW_axi_a2x_all_includes.vh"
//*********************************************************************
// DW_axi_a2x_busy_os:
//  Module used to keep track of outstanding transactions in the
//  bridge. A counter is used to keep track of ongoing transfers
//*********************************************************************
module i_axi_a2x_DW_axi_a2x_busy_osx (
  // Outputs
  osx_status,
  // Inputs
  clk, resetn, inc, dec
  );

  parameter CNT_WIDTH = 16;

  input      clk;
  input      resetn;      // Async reset
  input      inc;         // Condition to increment the counter
  input      dec;         // Condition to decrement the counter
  output     osx_status;  // Flag to indicate outstanding transactions 0=>No outstanding : 1=> Has outstanding
  //These nets are used to connect the logic under certain configuration.
  //But this may not drive some of the nets. This will not cause any functional issue.
  reg   [CNT_WIDTH-1:0] cntr; // Counter to keep track of outstanding transactions

  always @(posedge clk or negedge resetn) begin : cntr_PROC
    if(resetn==1'b0) begin
      cntr <= {CNT_WIDTH{1'b0}};
    end else begin
      if(inc && (!dec)) begin
        cntr <= cntr + 1;
      end else if((!inc) && dec) begin
        cntr <= cntr - 1;
      end
    end
  end
  assign osx_status = |cntr;

endmodule // DW_axi_a2x_busy_osx
