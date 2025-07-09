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
// File Version     :        $Revision: #3 $ 
// Revision: $Id: //dwh/DW_ocb/DW_axi_a2x/axi_dev_br/src/DW_axi_a2x_r_pk_byte.v#3 $ 
// --------------------------------------------------------------------
*/

`include "DW_axi_a2x_all_includes.vh"
//***************************************************************************
// Pack Byte Control - Used with Read Data Packer
//***************************************************************************
module i_axi_a2x_1_DW_axi_a2x_r_pk_byte (/*AUTOARG*/
   // Outputs
   rdata_o,
   // Inputs
   clk, resetn, byte_clr, byte_en, rdata_i,rvalid, rready, rid_valid
   );

  //********************************************************* 
  // I/O Decelaration
  //********************************************************* 
  input                                              clk;
  input                                              resetn;
  
  input                                              rid_valid; 
  input                                              rvalid; 
  input                                              rready; 
  input                                              byte_clr;
  input                                              byte_en;
  input  [7:0]                                       rdata_i;
  output [7:0]                                       rdata_o;

  reg    [7:0]                                       rdata_r; 

  //********************************************************* 
  // Read Data Generation
  //
  // Store the Read Data Byte when Byte Enable asserted.
  //********************************************************* 
  wire r_valid = rvalid & rready & rid_valid;
  always @(posedge clk or negedge resetn) begin: byte_PROC
    if (resetn == 1'b0) begin
      rdata_r <= 8'b0;
    end else begin       
      if (byte_clr)
        rdata_r <= 8'b0;
      else if (byte_en && r_valid)
        rdata_r <= rdata_i;
    end
  end

  // When Byte Enable asserted assign input to output otherwise assign output
  // to registered value. 
  assign rdata_o = (byte_en)? rdata_i : rdata_r; 

endmodule 
