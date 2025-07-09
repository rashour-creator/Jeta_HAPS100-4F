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
// Revision: $Id: //dwh/DW_ocb/DW_axi_a2x/amba_dev/src/DW_axi_a2x_pk_byte.v#1 $ 
// --------------------------------------------------------------------
*/

`include "DW_axi_a2x_all_includes.vh"
//***************************************************************************
// Upsize Byte Control
//***************************************************************************
module i_axi_a2x_DW_axi_a2x_pk_byte (/*AUTOARG*/
   // Outputs
   wstrb_o, wdata_o, 
   // Inputs
   clk, resetn, wvalid, wready, byte_clr, byte_en, wstrb_i, wdata_i
   );

  //********************************************************* 
  // I/O Decelaration
  //********************************************************* 
  input                     clk;
  input                     resetn;
  
  input                     wvalid;
  input                     wready;
  input                     byte_clr;
  input                     byte_en;

  input                     wstrb_i;
  input  [7:0]              wdata_i;

  output                    wstrb_o;
  output [7:0]              wdata_o;

  reg                       wstrb_r;
  reg    [7:0]              wdata_r; 

  //********************************************************* 
  // Write Data Generation
  //********************************************************* 
  always @(posedge clk or negedge resetn) begin: byte_PROC
    if (resetn == 1'b0) begin
      wdata_r <= 8'b0;
    end else begin       
      if (byte_clr)
        wdata_r <= 8'b0;
      else if (byte_en && wvalid && wready)
        wdata_r <= wdata_i;
    end
  end

  assign wdata_o = (byte_en)? wdata_i : wdata_r; 

  //********************************************************* 
  // Write Strobe Generation
  //********************************************************* 
  always @(posedge clk or negedge resetn) begin: strb_PROC
    if (resetn == 1'b0) begin
      wstrb_r <= 1'b0;
    end else begin
      if (byte_clr)
        wstrb_r <= 1'b0;
      else if (byte_en && wvalid && wready)
        wstrb_r <= wstrb_i;
    end
  end

  assign wstrb_o = (byte_en)? wstrb_i : wstrb_r; 

endmodule
