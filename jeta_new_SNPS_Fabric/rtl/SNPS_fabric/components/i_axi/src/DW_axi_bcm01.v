
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
// Description : DW_axi_bcm01.v Verilog module for DW_axi
//
// DesignWare IP ID: 99b91577
//
////////////////////////////////////////////////////////////////////////////////


  module i_axi_DW_axi_bcm01 (
      // Inputs
        a,
        tc,
        min_max,
      // Outputs
        value,
        index
);

parameter integer WIDTH =               4;      // element WIDTH
parameter integer NUM_INPUTS =          8;      // number of elements in input array
parameter integer INDEX_WIDTH =         3;      // size of index pointer = ceil(log2(NUM_INPUTS))


input  [NUM_INPUTS*WIDTH-1 : 0]         a;      // Concatenated input vector
input                                   tc;     // 0 = unsigned, 1 = signed
input                                   min_max;// 0 = find min, 1 = find max
output [WIDTH-1:0]                      value;  // mon or max value found
output [INDEX_WIDTH-1:0]                index;  // index to value found

  DW_minmax #(WIDTH,NUM_INPUTS) U1(
        .a(a),
        .tc(tc),
        .min_max(min_max),
        .value(value),
        .index(index) );


endmodule
