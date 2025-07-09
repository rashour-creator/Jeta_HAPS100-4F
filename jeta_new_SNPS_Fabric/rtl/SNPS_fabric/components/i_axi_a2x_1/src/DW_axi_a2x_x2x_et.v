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
// File Version     :        $Revision: #4 $ 
// Revision: $Id: //dwh/DW_ocb/DW_axi_a2x/axi_dev_br/src/DW_axi_a2x_x2x_et.v#4 $ 
// --------------------------------------------------------------------
*/

`include "DW_axi_a2x_all_includes.vh"
//*********************************************************
// AHB Endian Conversion 
//*********************************************************
module i_axi_a2x_1_DW_axi_a2x_x2x_et (/*AUTOARG*/
  // Outputs
  pyld_o, 
  // Inputs
  pyld_i, 
  size_i
  );
  
  //*********************************************************
  // Parameter Decelaration
  //*********************************************************
  parameter   A2X_USER_WIDTH        = 0;
  parameter   A2X_UBB               = 0;
  parameter   A2X_PYLD_W            = 1024; 
  parameter   A2X_DW                = 512;
  parameter   WRITE_CH              = 0;  // Indicates if Write or Read Endian Conversion

  localparam  A2X_STRBW             = A2X_DW/8;

  localparam  A2X_MAX_SIZE         = (A2X_DW==8)?0:(A2X_DW==16)?1:(A2X_DW==32)?2:(A2X_DW==64)?3:(A2X_DW==128)?4:(A2X_DW==256)?5:(A2X_DW==512)?6:7;

  //*********************************************************
  // I/O Decelaration
  //********************************************************* 
  input   [2:0]                         size_i;
  input   [A2X_PYLD_W-1:0]              pyld_i;
  output  [A2X_PYLD_W-1:0]              pyld_o;

  //*********************************************************
  // Signal Decelaration
  //*********************************************************
  wire   [A2X_USER_WIDTH-1:0]           data_sb_i;
  wire   [A2X_DW-1:0]                   data_i; 
  wire   [A2X_STRBW-1:0]                strb_i; 
  wire                                  last_i;  
  wire   [A2X_USER_WIDTH-1:0]           data_sb_swap;

  reg    [A2X_DW-1:0]                   data_swap;
  reg    [A2X_STRBW-1:0]                strb_swap;
  
  reg    [7:0]                          size_1hot;
  reg    [7:0]                          size_1hot_w;           // j: Additional signal used to increase code coverage results

  //********************************************************* 
  // Write Data Payload Decode
  //********************************************************* 
  // spyglass disable_block W164a
  // SMD: Identifies assignments in which the LHS width is less than the RHS width
  // SJ : The payload's lower bits are extracted and assigned to last_i, data_i, and strb_i.
  //      This is not a functional issue, this is as per the requirement.
  //      Hence this can be waived.  
  generate 
  if (WRITE_CH==1) begin : WRITE_CH_1
    assign {strb_i, data_i, last_i}  = pyld_i;
    assign pyld_o                    = {pyld_i[A2X_PYLD_W-1:A2X_STRBW+A2X_DW+1], strb_i, data_swap, last_i};
    //assign pyld_o                    = {pyld_i[A2X_PYLD_W-1:A2X_STRBW+A2X_DW+1], strb_swap, data_swap, last_i};
  end else begin : WRITE_CH_ELSE
    assign {data_i, last_i}  = pyld_i;
    assign pyld_o            = {pyld_i[A2X_PYLD_W-1:A2X_DW+1], data_swap, last_i};
  end
  endgenerate
  // spyglass enable_block W164a

  //********************************************************************
  // DW_axi_a2x provides support for endianness conversion from AHB to AXI.
  // The endianness of both the AHB and AXI busses is configured by setting two hardware
  // configuration parameters, A2X_PP_ENDIAN and A2X_ENDIAN_O.
  //
  // A2X_PP_ENDIAN         Description
  //       0               Little Endian (LE) 
  //       3               Big Endian (BE8)
  //********************************************************************
  //spyglass disable_block W415a
  //SMD: Signal may be multiply assigned (beside initialization) in the same scope.
  //SJ : size_1hot is initialized before assignment to avoid latches.
  always @(*) begin: size1hot_PROC
    integer i; 
    size_1hot = 8'b0; 
    for (i=0; i<=A2X_MAX_SIZE; i=i+1)
      // Signed and unsigned operands should not be used in same operation
      // i can only be an integer, since it is a loop index. It is a design requirement to
      // use i in the following operation and it will not have any adverse effects on the 
      // design. So signed and unsigned operands are used to reduce the logic.
      if (i==size_i) size_1hot[i] = 1'b1;
  end 
  
  // j: Added size_1hot_w to improve coverage results on the case expression below
  always @(*) begin: size1hotw_PROC
      size_1hot_w[7:0] = 8'b0;
      size_1hot_w[A2X_MAX_SIZE:0] = size_1hot[A2X_MAX_SIZE:0];
  end

  always@(*) begin: data_swap_PROC      
    // BE8 to LE or LE to BE8
    data_swap = {(A2X_DW){1'b0}};
    case(size_1hot_w)
      8'd2  :  if (A2X_DW>8)   data_swap = swap_16(data_i);
      8'd4  :  if (A2X_DW>16)  data_swap = swap_32(data_i);
      8'd8  :  if (A2X_DW>32)  data_swap = swap_64(data_i);
      8'd16 :  if (A2X_DW>64)  data_swap = swap_128(data_i);
      8'd32 :  if (A2X_DW>128) data_swap = swap_256(data_i);
      8'd64 :  if (A2X_DW>256) data_swap = swap_512(data_i);
      8'd128 : if (A2X_DW>512) data_swap = swap_1024(data_i);
      default:                 data_swap = data_i; 
     endcase // case(size_i)
  end
  //spyglass enable_block W415a

  //********************************************************************
  // Write Strobe Endianess
  //********************************************************************
  generate 
  if ( WRITE_CH==1 ) begin: STRB_EN
    always@(*) begin: strb_swap_PROC
        strb_swap = {(A2X_STRBW){1'b0}};  
      // BE8 to LE or LE to BE8
      case(size_1hot_w)
        8'd2  : if  (A2X_DW>8 && WRITE_CH==1)   strb_swap = swap_16_strb(strb_i);
        8'd4  : if  (A2X_DW>16 && WRITE_CH==1)  strb_swap = swap_32_strb(strb_i);
        8'd8  : if  (A2X_DW>32 && WRITE_CH==1)  strb_swap = swap_64_strb(strb_i);
        8'd16 : if  (A2X_DW>64 && WRITE_CH==1)  strb_swap = swap_128_strb(strb_i);
        8'd32 : if  (A2X_DW>128 && WRITE_CH==1) strb_swap = swap_256_strb(strb_i);
        8'd64 : if  (A2X_DW>256 && WRITE_CH==1) strb_swap = swap_512_strb(strb_i);
        8'd128 : if (A2X_DW>512 && WRITE_CH==1) strb_swap = swap_1024_strb(strb_i);
        default:                                strb_swap = strb_i; 
      endcase // case(size_i)
    end

  end  // End of WRITE_CH==1
  endgenerate
  
  
  //********************************************************* 
  // Function: Swap bytes within a 16bit half-word
  //********************************************************* 
  // spyglass disable_block W499
  // SMD: Ensure that all bits of a function are set
  // SJ : This is not a functional issue, this is as per the requirement.
  //      Hence this can be waived.  
  // spyglass disable_block SelfDeterminedExpr-ML
  // SMD: Self determined expression found
  // SJ: The expression indexing the vector/array will never exceed the bound of the vector/array.
  // spyglass disable_block STARC05-2.1.1.2
  // SMD: A function description must assign return values to all possible states of the function. (Verilog)
  // SJ : The minimum data width is 32 bit and hence the 'else' part is not required to write, as per design intent.
  function automatic [A2X_DW-1:0] swap_16;
    input [A2X_DW-1:0] data; // Unconverted data input
    integer i,j,k;
    integer ssize;
    begin
      if (A2X_DW>8) begin
        ssize = 16;
        swap_16 = data;
        for(i=0; i<A2X_DW/16; i=i+1)
          for(k=0; k<2; k=k+1)
            for(j=0; j<8; j=j+1)
              swap_16[j+k*8+i*ssize] = data[j+(2-1-k)*8+i*ssize];
      end
    end
  endfunction // swap_16
 
  //********************************************************* 
  // Function: Swap Strobes within a 16bit half-word
  //********************************************************* 
  function automatic [A2X_STRBW-1:0] swap_16_strb;
    input [A2X_STRBW-1:0] strb; // Unconverted data input
    integer i,k;
    integer ssize;
    begin
      if (A2X_DW>8 && WRITE_CH==1) begin
        ssize = 16;
        swap_16_strb = strb;
        for(i=0; i<A2X_STRBW/2; i=i+1)
          for(k=0; k<2; k=k+1)
            swap_16_strb[(i*2)+k] = strb[(i*2)+((2-1)-k)];
      end
    end
  endfunction // swap_16

  //********************************************************* 
  //Function: Swap bytes within word
  //********************************************************* 
    function automatic [A2X_DW-1:0] swap_32;
      input [A2X_DW-1:0] data; // Unconverted data input
      integer i,j,k;
      integer ssize;
      begin
        if (A2X_DW>16) begin
          ssize = 32;
          swap_32 = data;
          for(i=0; i<A2X_DW/32; i=i+1)
            for(k=0; k<4; k=k+1)
              for(j=0; j<8; j=j+1)
                swap_32[j+k*8+i*ssize] = data[j+(4-1-k)*8+i*ssize];
        end
      end
    endfunction // swap_32
 
  //********************************************************* 
  //Function: Swap bytes within word
  //********************************************************* 
    function automatic [A2X_STRBW-1:0] swap_32_strb;
      input [A2X_STRBW-1:0] strb; // Unconverted data input
      integer i,k;
      begin
        if (A2X_DW>16 && WRITE_CH==1) begin
          swap_32_strb = strb;
          for(i=0; i<A2X_STRBW/4; i=i+1)
            for(k=0; k<4; k=k+1)
              swap_32_strb[(i*4)+k] = strb[(i*4)+((4-1)-k)];
        end
      end
    endfunction // swap_32

  //********************************************************* 
  //Function: Swap bytes within 64bit double-word
  //********************************************************* 
    function automatic [A2X_DW-1:0] swap_64;
      input [A2X_DW-1:0] data; // Unconverted data input
      integer i,j,k;
      integer ssize;
      begin
        if (A2X_DW>32) begin
          ssize = 64;
          swap_64 = data;
          for(i=0; i<A2X_DW/64; i=i+1)
            for(k=0; k<8; k=k+1)
              for(j=0; j<8; j=j+1)
                swap_64[j+k*8+i*ssize] = data[j+(8-1-k)*8+i*ssize];
        end
      end
    endfunction // swap_64
 
  //********************************************************* 
  //Function: Swap bytes within 64bit double-word
  //********************************************************* 
    function automatic [A2X_STRBW-1:0] swap_64_strb;
      input [A2X_STRBW-1:0] strb; // Unconverted data input
      integer i,k;
      begin
        if (A2X_DW>32 && WRITE_CH==1) begin
          swap_64_strb = strb;
          for(i=0; i<A2X_STRBW/8; i=i+1)
            for(k=0; k<8; k=k+1)
              swap_64_strb[(i*8)+k] = strb[(i*8)+((8-1)-k)];
        end
      end
    endfunction // swap_64
    

  //********************************************************* 
  //Function: Swap bytes within 128bit word
  //********************************************************* 
    function automatic [A2X_DW-1:0] swap_128;
      input [A2X_DW-1:0] data; // Unconverted data input
      integer i,j,k;
      integer ssize;
      begin
        if (A2X_DW>64) begin
          ssize = 128;
          swap_128 = data;
          for(i=0; i<A2X_DW/128; i=i+1)
            for(k=0; k<16; k=k+1)
              for(j=0; j<8; j=j+1)
                swap_128[j+k*8+i*ssize] = data[j+(16-1-k)*8+i*ssize];
        end
      end
    endfunction // swap_128
 
  //********************************************************* 
  //Function: Swap bytes within 128bit word
  //********************************************************* 
    function automatic [A2X_STRBW-1:0] swap_128_strb;
      input [A2X_STRBW-1:0] strb; // Unconverted data input
      integer i,k;
      begin
        if (A2X_DW>64 && WRITE_CH==1) begin
          swap_128_strb = strb;
          for(i=0; i<A2X_STRBW/16; i=i+1)
            for(k=0; k<16; k=k+1)
              swap_128_strb[(i*16)+k] = strb[(i*16)+((16-1)-k)];
        end
      end
    endfunction // swap_128    

  //********************************************************* 
  //Function: Swap bytes within 256bit word
  //********************************************************* 
    function automatic [A2X_DW-1:0] swap_256;
      input [A2X_DW-1:0] data; // Unconverted data input
      integer i,j,k;
      integer ssize;
      begin
        if (A2X_DW>128) begin
          ssize = 256;
          swap_256 = data;
          for(i=0; i<A2X_DW/256; i=i+1)
            for(k=0; k<32; k=k+1)
              for(j=0; j<8; j=j+1)
                swap_256[j+k*8+i*ssize] = data[j+(32-1-k)*8+i*ssize];
        end
      end
    endfunction // swap_256
 
  //********************************************************* 
  //Function: Swap bytes within 256bit word
  //********************************************************* 
    function automatic [A2X_STRBW-1:0] swap_256_strb;
      input [A2X_STRBW-1:0] strb; // Unconverted data input
      integer i,k;
      begin
        if (A2X_DW>128 && WRITE_CH==1) begin
          swap_256_strb = strb;
          for(i=0; i<A2X_STRBW/32; i=i+1)
            for(k=0; k<32; k=k+1)
              swap_256_strb[(i*32)+k] = strb[(i*32)+((32-1)-k)];
        end
      end
    endfunction // swap_256    

  //********************************************************* 
  //Function: Swap bytes within 512bit word
  //********************************************************* 
    function automatic [A2X_DW-1:0] swap_512;
      input [A2X_DW-1:0] data; // Unconverted data input
      integer i,j,k;
      integer ssize;
      begin
        if (A2X_DW>256) begin
          ssize = 512;
          swap_512 = data;
          for(i=0; i<A2X_DW/512; i=i+1)
            for(k=0; k<64; k=k+1)
              for(j=0; j<8; j=j+1)
                swap_512[j+k*8+i*ssize] = data[j+(64-1-k)*8+i*ssize];
        end
      end
    endfunction // swap_512
 
  //********************************************************* 
  //Function: Swap Strobes within 512bit word
  //********************************************************* 
    function automatic [A2X_STRBW-1:0] swap_512_strb;
      input [A2X_STRBW-1:0] strb; // Unconverted data input
      integer i,k;
      begin
        if (A2X_DW>256) begin
          swap_512_strb = strb;
          for(i=0; i<A2X_STRBW/64; i=i+1)
            for(k=0; k<64; k=k+1)
              swap_512_strb[(i*64)+k] = strb[(i*64)+((64-1)-k)]; 
        end
      end
    endfunction // swap_512_strb

  //********************************************************* 
  //Function: Swap bytes within 1024bit word
  //********************************************************* 
    function automatic [A2X_DW-1:0] swap_1024;
      input [A2X_DW-1:0] data; // Unconverted data input
      integer i,j,k;
      integer ssize;
      begin
        if (A2X_DW>512) begin
          ssize = 1024;
          swap_1024 = data;
          for(i=0; i<A2X_DW/1024; i=i+1)
            for(k=0; k<128; k=k+1)
              for(j=0; j<8; j=j+1)
                swap_1024[j+k*8+i*ssize] = data[j+(128-1-k)*8+i*ssize];
        end
      end
    endfunction // swap_1024

  //********************************************************* 
  //Function: Swap Strobes within 1024bit word
  //********************************************************* 
    function automatic [A2X_STRBW-1:0] swap_1024_strb;
      input [A2X_STRBW-1:0] strb; // Unconverted data input
      integer i,k;
      begin
        if (A2X_DW>512) begin
          swap_1024_strb = strb;
          for(i=0; i<A2X_STRBW/128; i=i+1)
            for(k=0; k<128; k=k+1)
              swap_1024_strb[(i*128)+k] = strb[(i*128)+((128-1)-k)]; 
        end
      end
    endfunction // swap_1024_strb
    // spyglass enable_block STARC05-2.1.1.2
    // spyglass enable_block SelfDeterminedExpr-ML
    // spyglass enable_block W499
endmodule
 
