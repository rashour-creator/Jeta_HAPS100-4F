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
// File Version     :        $Revision: #3 $ 
// Revision: $Id: //dwh/DW_ocb/DW_axi_a2x/axi_dev_br/src/DW_axi_a2x_busmux_ohsel.v#3 $ 
**
** --------------------------------------------------------------------
**
** File     : DW_axi_a2x_busmux_ohsel.v
** Created  : Thu Jan 27 11:01:40 MET 2011
** Abstract : Parameterized one-hot demux that will
**            demultiplex several buses (quantity specified
**            at compile time, and controlled by a parameter)
**            of a particular width (which is also specified at
**            compile time by a parameter). 
**
** ---------------------------------------------------------------------
*/
//**********************************************************************************
// One Hot Decode Mux
//**********************************************************************************
`include "DW_axi_a2x_all_includes.vh"

module i_axi_a2x_DW_axi_a2x_busmux_ohsel ( sel, din, dout );

  parameter BUS_COUNT = 2;   // number of input buses
  parameter MUX_WIDTH = 3;   // bit width of data buses

  input [BUS_COUNT-1:0] sel;            // one-hot select signals
  input [MUX_WIDTH*BUS_COUNT-1:0] din;  // concatenated input buses

  output [MUX_WIDTH-1:0] dout;          // output data bus

  wire [BUS_COUNT-1:0]   sel;           // one-hot select signals
  wire [MUX_WIDTH*BUS_COUNT-1:0] din;   // concatenated input buses

  reg [MUX_WIDTH-1:0] dout;             // output data bus


  // One of the subtleties that might not be obvious that makes this work so well 
  // is the use of the blocking assignment (=) that allows dout to be built up 
  // incrementally. The one-hot select builds up into the wide "or" function 
  // you'd code by hand.
  // spyglass disable_block W415a
  // SMD: Signal may be multiply assigned (beside initialization) in the same scope.
  // SJ : dout is initialized before entering into loop to avoid latches.
  // spyglass disable_block SelfDeterminedExpr-ML
  // SMD: Self determined expression found
  // SJ: The expression indexing the vector/array will never exceed the bound of the vector/array.
  always @ (sel or din) begin : mux_logic_PROC
     integer i, j;
     dout = {MUX_WIDTH{1'b0}};
     for (i = 0; i <= (BUS_COUNT-1); i = i + 1) begin
       for (j = 0; j <= (MUX_WIDTH-1); j = j + 1) begin
         dout[j] = dout[j] | din[MUX_WIDTH*i +j]&sel[i];
       end
     end
  end // always
  // spyglass enable_block SelfDeterminedExpr-ML
  // spyglass enable_block W415a
endmodule
//Revision: $Id: //dwh/DW_ocb/DW_axi_a2x/axi_dev_br/src/DW_axi_a2x_busmux_ohsel.v#3 $
