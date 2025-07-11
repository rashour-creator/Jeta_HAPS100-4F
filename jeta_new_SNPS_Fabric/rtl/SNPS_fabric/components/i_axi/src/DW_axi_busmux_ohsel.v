/*
------------------------------------------------------------------------
--
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
// File Version     :        $Revision: #6 $ 
// Revision: $Id: //dwh/DW_ocb/DW_axi/axi_dev_br/src/DW_axi_busmux_ohsel.v#6 $ 
--
-- File :                       DW_axi_busmux_ohsel.v
-- Author:                      See CVS log.
//
//
-- Date :                       $Date: 2021/07/21 $
--
-- Description :     Parameterized one-hot mux that will
--                   multiplex several buses (quantity specified
--                   at compile time, and controlled by a parameter)
--                   of a particular width (which is also specified at
--                   compile time by a parameter). For example, the same
--                   module would be able to mux three 12-bit buses, or
--                   seven 5-bit buses, or any other combination,
--                   depending on the parameter values used when the
--                   module is instantiated.
--
-- Modification History:
-- Date                 By      Version Change  Description
-- =====================================================================
-- See CVS log
-- =====================================================================
*/

`include "DW_axi_all_includes.vh"

module i_axi_DW_axi_busmux_ohsel ( sel, din, dout );

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
  // SMD: Signal may be multiply assigned (beside initialization) in the same scope
  // SJ : This is not an issue.
  // spyglass disable_block SelfDeterminedExpr-ML
  // SMD: Self determined expression found
  // SJ : The expression indexing the vector/array will never exceed the bound of the vector/array.        
  always @ (*) begin : mux_logic_PROC
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


endmodule // DW_axi_busmux_ohsel

