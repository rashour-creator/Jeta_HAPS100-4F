
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
// Description : DW_axi_bcm36_nhs.v Verilog module for DW_axi
//
// DesignWare IP ID: e3faf16b
//
////////////////////////////////////////////////////////////////////////////////



module i_axi_DW_axi_bcm36_nhs (
`ifndef SYNTHESIS
    clk_d,
    rst_d_n,
`endif
    data_s,
    data_d
    );

parameter integer WIDTH        = 1;  // RANGE 1 to 1024
// spyglass disable_block W175
// SMD: A parameter is declared but not used
// SJ: The following parameter(s) are not used in certain GCCM or GSCM configurations.
parameter integer DATA_DELAY   = 0;  // RANGE 0 to 3
// spyglass enable_block W175
// spyglass disable_block W175
// SMD: A parameter is declared but not used
// SJ: The following parameter(s) are not used in certain GCCM or GSCM configurations.
parameter integer SVA_TYPE     = 1;
// spyglass enable_block W175

`ifndef SYNTHESIS
`endif



`ifndef SYNTHESIS
input                   clk_d;      // clock input from destination domain
input                   rst_d_n;    // active low asynchronous reset from destination domain
`endif
input  [WIDTH-1:0]      data_s;     // data to be synchronized from source domain
output [WIDTH-1:0]      data_d;     // data synchronized to destination domain

wire   [WIDTH-1:0]      data_s_int;
wire   [WIDTH-1:0]      data_d_int;

`ifndef SYNTHESIS
`endif



`ifdef SYNTHESIS
  assign data_s_int = data_s;
`else
  assign data_s_int = data_s;
`endif


// spyglass disable_block Ac_conv04
// SMD: Checks all the control-bus clock domain crossings which do not follow gray encoding
// SJ: The clock domain crossing bus is between the register file and the read-mux of a RAM, which do not need a gray encoding.
  assign data_d_int = data_s_int;

assign data_d = data_d_int;


// spyglass enable_block Ac_conv04

`ifndef SYNTHESIS


`endif

endmodule
