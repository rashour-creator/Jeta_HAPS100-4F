/* --------------------------------------------------------------------
**
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
// Revision: $Id: //dwh/DW_ocb/DW_axi_a2x/amba_dev/src/DW_axi_a2x_h2x_et.v#1 $ 
**
** --------------------------------------------------------------------*/

`include "DW_axi_a2x_all_includes.vh"
//*********************************************************
// AHB Endian Conversion 
//*********************************************************
module i_axi_a2x_1_DW_axi_a2x_h2x_et (/*AUTOARG*/
  // Outputs
  data_o, 
  // Inputs
  data_i, 
  size_i
  );
  
  //*********************************************************
  // Parameter Decelaration
  //*********************************************************
  parameter   A2X_DW                = 512;

  localparam  A2X_STRBW             = A2X_DW/8;
  
  localparam  A2X_MAX_SIZE         = (A2X_DW==8)?0:(A2X_DW==16)?1:(A2X_DW==32)?2:(A2X_DW==64)?3:(A2X_DW==128)?4:(A2X_DW==256)?5:(A2X_DW==512)?6:7;

  //*********************************************************
  // I/O Decelaration
  //********************************************************* 
  input   [2:0]                         size_i;
  input   [A2X_DW-1:0]                  data_i;
  output  [A2X_DW-1:0]                  data_o;

  //*********************************************************
  // Signal Decelaration
  //********************************************************* 
  reg    [A2X_DW-1:0]                   data_swap;
  reg    [7:0]                          size_1hot;
  reg    [7:0]                          size_1hot_w;           // j: Additional signal used to increase code coverage results

  //********************************************************* 
  // Write Data Output
  //********************************************************* 
  assign data_o      = data_swap;

  //********************************************************************
  // DW_axi_a2x provides support for endianness conversion from AHB to AXI.
  // The endianness of both the AHB and AXI busses is configured by setting two hardware
  // configuration parameters, A2X_PP_ENDIAN and A2X_ENDIAN_O.
  //
  // A2X_PP_ENDIAN         Description
  //       0               Little Endian (LE) 
  //       1               Big Endian (BE32) 
  //       2               Big Endian (BEA)
  //********************************************************************
  //spyglass disable_block W415a
  //SMD: Signal may be multiply assigned (beside initialization) in the same scope.
  //SJ : size_1hot is initialized before assignment to avoid latches.
  always @(*) begin: size1hot_PROC
    integer i; 
    size_1hot = 8'b0; 
    for (i=0; i<=A2X_MAX_SIZE; i=i+1)
      //Signed and unsigned operands should not be used in same operation
      //operation works correctly, warning can be ignored
      if (i==size_i) size_1hot[i] = 1'b1;
  end 
  
  // Added size_1hot_w to improve coverage results on the case expression below
  always @(*) begin: size_1hotw_PROC
      size_1hot_w[7:0]  = 8'h0;
      size_1hot_w[A2X_MAX_SIZE:0] = size_1hot[A2X_MAX_SIZE:0];
  end
  //spyglass enable_block W415a

  // This module is used for in several instances and the value depends on the instantiation. 
  generate if (`A2X_PP_ENDIAN==1) begin: PP_ENDIAN
  // Constant condition expression
  // The RTL is implemented as per the requirement. The following code is necessary 
  // to support different data widths under different configurations. Hence this 
  // can be waived
  always@(*) begin: data_swap_1_PROC
    data_swap = {(A2X_DW){1'b0}};
      // BE32-LE  
      case(size_1hot_w)
        8'd2  :  if (A2X_DW>8)   data_swap = be32_swap_16(data_i);
        8'd4  :  if (A2X_DW>16)  data_swap = data_i;
        8'd8  :  if (A2X_DW>32)  data_swap = data_i;
        8'd16 :  if (A2X_DW>64)  data_swap = data_i;
        8'd32 :  if (A2X_DW>128) data_swap = data_i;
        8'd64 :  if (A2X_DW>256) data_swap = data_i;
        8'd128 : if (A2X_DW>512) data_swap = data_i;
        default:                 data_swap = be32_swap_8(data_i); 
      endcase // case(size_i)
  end

  // spyglass disable_block W499
  // SMD: Ensure that all bits of a function are set
  // SJ : This is not a functional issue, this is as per the requirement.
  //      Hence this can be waived.  
  // spyglass disable_block SelfDeterminedExpr-ML
  // SMD: Self determined expression found
  // SJ: The expression indexing the vector/array will never exceed the bound of the vector/array.
  //********************************************************* 
  // Function: Swap bytes within a 8-bit Byte BE-32 Invariance
  //********************************************************* 
  function automatic [A2X_DW-1:0] be32_swap_8;
    input [A2X_DW-1:0] data; // Unconverted data input
    integer i,j,k;
    begin
        if (A2X_DW<32) begin
          be32_swap_8 = data;
        end else begin
          for(i=0; i<A2X_DW/32; i=i+1) begin
            for (k=0; k<4; k=k+1) begin
              for (j=0; j<8; j=j+1) begin
                be32_swap_8[(i*32)+(k*8)+j]     = data[(i*32)+((3-k)*8)+j];
              end
            end
          end
        end
    end
  endfunction // be32_swap_8

  //********************************************************* 
  // Function: Swap bytes within a 16bit half-word BE-32 Invariance
  // 32-hABCD -> 32'hCDAB
  //********************************************************* 
  function automatic [A2X_DW-1:0] be32_swap_16;
    input [A2X_DW-1:0] data; // Unconverted data input
    integer i,j,k;
    begin
        if (A2X_DW<32) begin
          be32_swap_16 = data;
        end else begin
          for(i=0; i<A2X_DW/32; i=i+1) begin
            for (k=0; k<2; k=k+1) begin
              for (j=0; j<16; j=j+1) begin
                be32_swap_16[(i*32)+(k*16)+j]     = data[(i*32)+((1-k)*16)+j];
              end
            end
          end
        end
    end
  endfunction // be32_swap_16
  // spyglass enable_block SelfDeterminedExpr-ML
  // spyglass enable_block W499
  end // PP_ENDIAN_ONE

  else if (`A2X_PP_ENDIAN==2) begin 
  always@(*) begin: data_swap_2_PROC
    data_swap = {(A2X_DW){1'b0}};  
    // BEA to LE
      case(size_1hot_w)
        8'd1  :                  data_swap = swap_all(data_i);
        8'd2  :  if (A2X_DW>8)   data_swap = swap_all(data_i);
        8'd4  :  if (A2X_DW>16)  data_swap = swap_all(data_i);
        8'd8  :  if (A2X_DW>32)  data_swap = swap_all(data_i);
        8'd16 :  if (A2X_DW>64)  data_swap = swap_all(data_i);
        8'd32 :  if (A2X_DW>128) data_swap = swap_all(data_i);
        8'd64 :  if (A2X_DW>256) data_swap = swap_all(data_i);
        8'd128 : if (A2X_DW>512) data_swap = swap_all(data_i);
        default:                 data_swap = data_i;
      endcase // case(size_i)            
  end
    // BE32-LE
  //Function: Swap all bytes on the data bus
  //********************************************************* 
  // spyglass disable_block W499
  // SMD: Ensure that all bits of a function are set
  // SJ : This is not a functional issue, this is as per the requirement.
  //      Hence this can be waived.  
  // spyglass disable_block SelfDeterminedExpr-ML
  // SMD: Self determined expression found
  // SJ: The expression indexing the vector/array will never exceed the bound of the vector/array.
  function automatic [A2X_DW-1:0] swap_all;
    input [A2X_DW-1:0] data; // Unconverted data input
    integer i,j;
    begin
        for(i=0; i<A2X_DW/8; i=i+1)
          for(j=0; j<8; j=j+1)
            swap_all[A2X_DW-8*(i+1)+j] = data[i*8+j];
    end
  endfunction // swap_all
  end // PP_ENDIAN_TWO
  // spyglass enable_block W499
  // spyglass enable_block SelfDeterminedExpr-ML
 endgenerate // PP_ENDIAN
endmodule
// Revision: $Id: //dwh/DW_ocb/DW_axi_a2x/amba_dev/src/DW_axi_a2x_h2x_et.v#1 $ 
