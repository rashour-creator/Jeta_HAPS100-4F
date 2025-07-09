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
// Revision: $Id: //dwh/DW_ocb/DW_axi_a2x/axi_dev_br/src/DW_axi_a2x_sp_add_onek.v#2 $ 
// --------------------------------------------------------------------
*/

`include "DW_axi_a2x_all_includes.vh"
// **************************************************************************************
// AHB 1K Boundary 
//
// Calculates next Address so mimus one to get last address in transaction.
// **************************************************************************************

module i_axi_a2x_2_DW_axi_a2x_sp_add_onek (/*AUTOARG*/
  addr_i, hincr_bcnt, size_i, onek_exceed  
);

  // **************************************************************************************
  // **************************************************************************************
  parameter HINCR_MAX_BCNT   = 10;
  parameter A2X_PP_MAX_SIZE  = 6;

  // **************************************************************************************
  // I/O Signals
  // **************************************************************************************
  input [9:0]          addr_i;
  input [10:0]         hincr_bcnt;
  input [`i_axi_a2x_2_A2X_BSW-1:0] size_i; 
  output               onek_exceed;
 
  // **************************************************************************************
  // Calculate (HINCR * Size)-1
  //
  // HINCR cannot be set to a value that will cross the 1K Bounary. i.e. 
  // a length of 1024 with size 1 is not allowed.
  // **************************************************************************************
  reg [10:0] onek_addr;

  //spyglass disable_block W415a
  //SMD: Signal may be multiply assigned (beside initialization) in the same scope.
  //SJ : onek_addr is initialized before assignment to avoid latches.
  // spyglass disable_block TA_09
  // SMD: Reports cause of uncontrollability or unobservability and estimates the number of nets whose controllability/ observability is impacted
  // SJ : Few bits of RHS are fixed, this is as per requirement 
  always @(*) begin: ONEK_PROC
    integer i,j; 
    onek_addr = 11'd0;
    for (i=0; i<=HINCR_MAX_BCNT; i=i+1 ) begin
      for (j=0; j<=A2X_PP_MAX_SIZE; j=j+1) begin
        if ( ((1<<i)==hincr_bcnt) && (j==size_i) ) begin
          onek_addr = {1'b0, addr_i[9:0]} + (((11'b1<<i) << j)-11'b1);
        end
      end
    end
  end
  // spyglass enable_block TA_09
 //spyglass enable_block W415a

  assign onek_exceed  = onek_addr[10];
  
endmodule
