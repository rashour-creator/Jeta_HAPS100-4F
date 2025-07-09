
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
// Description : DW_axi_bcm99.v Verilog module for DW_axi
//
// DesignWare IP ID: b2582607
//
////////////////////////////////////////////////////////////////////////////////

module i_axi_DW_axi_bcm99 (
  clk_d,
  rst_d_n,
  data_s,
  data_d
);

// spyglass disable_block W175
// SMD: A parameter is declared but not used
// SJ: The following parameter(s) are not used in certain GCCM or GSCM configurations.
parameter integer ACCURATE_MISSAMPLING = 0; // RANGE 0 to 1
// spyglass enable_block W175

input  clk_d;      // clock input from destination domain
input  rst_d_n;    // active low asynchronous reset from destination domain
input  data_s;     // data to be synchronized from source domain
output data_d;     // data synchronized to destination domain

`ifdef SYNTHESIS
//######################### NOTE ABOUT TECHNOLOGY CELL MAPPING ############################
// Replace code between "DOUBLE FF SYNCHRONIZER BEGIN" and "DOUBLE FF SYNCHRONIZER END"
// with one of the following two options of customized register cell(s):
//   Option 1: One instance of a 2-FF cell
//     Macro cell must have an instance name of "sample_meta".
//
//     Example: (TECH_SYNC_2FF is example name of a synchronizer macro cell found in a technology library)
//         TECH_SYNC_2FF sample_meta ( .D(data_s), .CP(clk_d), .RSTN(rst_d_n), .Q(data_d) );
//
//   Option 2: Two instances of single-FF cells connected serially
//     The first stage synchronizer cell must have an instance name of "sample_meta".
//     The second stage synchronizer cell must have an instance name of "sample_syncl".
//
//     Example: (in GTECH)
//         wire n9;
//         GTECH_FD2 sample_meta ( .D(data_s), .CP(clk_d), .CD(rst_d_n), .Q(n9) );
//         GTECH_FD2 sample_syncl ( .D(n9), .CP(clk_d), .CD(rst_d_n), .Q(data_d) );
//
//####################### END NOTE ABOUT TECHNOLOGY CELL MAPPING ##########################
// DOUBLE FF SYNCHRONIZER BEGIN
  reg sample_meta;
  reg sample_syncl;
  always @(posedge clk_d or negedge rst_d_n) begin : a1000_PROC
    if (!rst_d_n) begin
      sample_meta <= 1'b0;
      sample_syncl <= 1'b0;
    end else begin
// spyglass disable_block Reset_sync04
// SMD: Asynchronous resets that are synchronized more than once in the same clock domain
// SJ: Spyglass recognizes every multi-flop synchronizer as a reset synchronizer, hence any design with a reset that feeds more than one synchronizer gets reported as violating this rule. This rule is waivered temporarily.
      sample_meta <= data_s;
// spyglass enable_block Reset_sync04
      sample_syncl <= sample_meta;
    end
  end
  assign data_d = sample_syncl;
// DOUBLE FF SYNCHRONIZER END
`else
//#####################################################################################
// NOTE: This section is for zero-time delay functional simulation
//#####################################################################################
  reg sample_meta;
  reg sample_syncl;
  always @(posedge clk_d or negedge rst_d_n) begin : a1001_PROC
    if (!rst_d_n) begin
      sample_meta <= 1'b0;
      sample_syncl <= 1'b0;
    end else begin
// spyglass disable_block Reset_sync04
// SMD: Asynchronous resets that are synchronized more than once in the same clock domain
// SJ: Spyglass recognizes every multi-flop synchronizer as a reset synchronizer, hence any design with a reset that feeds more than one synchronizer gets reported as violating this rule. This rule is waivered temporarily.
      sample_meta <= data_s;
// spyglass enable_block Reset_sync04
      sample_syncl <= sample_meta;
    end
  end
  assign data_d = sample_syncl;
`endif

endmodule
