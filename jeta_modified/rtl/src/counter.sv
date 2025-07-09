/******************************************************************************
 Copyright (C) 2018-2022 Synopsys, Inc.
 This IP and the associated documentation are confidential and
 proprietary to Synopsys, Inc. Your use or disclosure of this IP is 
 subject to the terms and conditions of a written license agreement 
 between you, or your company, and Synopsys, Inc.
 *******************************************************************************
 Title  : Counter
 Project: XTOR RISCV SOC
 Description: This module is a 24 bit counter with asynchronous active low reset
 
*******************************************************************************
 Date          Version        Author          Modification
   $            1.00            $           Initial(in verilog file)
 05May2022      1.01         chitra         Porting into sv file, usage of
                                            interface and including the package
                                            files and Documentation
******************************************************************************/

module counter
  (
   input             clk,
   input             reset_n,
   output reg [23:0] count
   );
   
   always @(posedge clk or negedge reset_n) begin
      if (~reset_n) begin
         count <= '0;
      end
      else begin
         count <= count + 1'b1;
      end
   end
 	 
endmodule
