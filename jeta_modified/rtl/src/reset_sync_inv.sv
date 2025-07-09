/******************************************************************************
 Copyright (C) 2018-2022 Synopsys, Inc.
 This IP and the associated documentation are confidential and
 proprietary to Synopsys, Inc. Your use or disclosure of this IP is 
 subject to the terms and conditions of a written license agreement 
 between you, or your company, and Synopsys, Inc.
 *******************************************************************************
 Title  : Reset synchroniser 
 Project: 
 Description: This module is the used for synchronsing the inverted reset 
 							to the input clock to module
 
*******************************************************************************
 Date          Version        Author          Modification
   $            1.00            $           Initial(in verilog file)
 05May2022      1.01         chitra         Porting into sv file, usage of
                                            interface and including the package
                                            files and Documentation
******************************************************************************/

module reset_sync_inv (
   	input      clk, 
   	input      rst_async,
	 	output reg rst_sync
);

		reg [3:0] shift_reg;

	  always @(posedge clk)	 begin
				{rst_sync,shift_reg} <= {shift_reg,~rst_async}; 
		end

endmodule
