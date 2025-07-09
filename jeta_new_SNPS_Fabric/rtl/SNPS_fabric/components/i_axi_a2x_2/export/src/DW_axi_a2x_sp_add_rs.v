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
// File Version     :        $Revision: #6 $ 
// Revision: $Id: //dwh/DW_ocb/DW_axi_a2x/axi_dev_br/src/DW_axi_a2x_sp_add_rs.v#6 $ 
// --------------------------------------------------------------------
*/

`include "DW_axi_a2x_all_includes.vh"
// **************************************************************************************
// Resize Address
// **************************************************************************************
module i_axi_a2x_2_DW_axi_a2x_sp_add_rs (/*AUTOARG*/
   // Outputs
   pyld_o, 
   rs_ratio,
   ds_fixed_decomp,
   ds_fixed_len,
   // Inputs
   pyld_i,
   onek_exceed
   );

  // **************************************************************************************
  // Parameter Decelaration
  // **************************************************************************************
  parameter  A2X_PP_MODE           = 0; 
  parameter  A2X_BLW               = 4; 
  parameter  A2X_CHANNEL           = 0;
  parameter  A2X_AW                = 32;
  parameter  A2X_SP_MAX_SIZE       = 2;
  parameter  A2X_PP_MAX_SIZE       = 2;
  parameter  A2X_SP_NUM_BYTES_LOG2 = 0;
  parameter  A2X_PP_NUM_BYTES_LOG2 = 0;
  parameter  A2X_RS_RATIO_LOG2     = 0;
  parameter  A2X_UPSIZE            = 0;
  parameter  A2X_DOWNSIZE          = 0;
  parameter  BLW_AS                = 4;
  parameter  BLW_RS                = 4;
  parameter  A2X_ASBW              = 1;
  parameter  A2X_QOSW              = 1;
  parameter  A2X_REGIONW           = 1;
  parameter  A2X_DOMAINW           = 1;
  parameter  A2X_WSNOOPW           = 1;
  parameter  A2X_BARW              = 1;
  parameter  A2X_PYLD_I            = 32; 
  parameter  A2X_PYLD_O            = 32;

  localparam SP_NUM_BYTES_LOG2     = (A2X_SP_NUM_BYTES_LOG2==0)? 1 : A2X_SP_NUM_BYTES_LOG2; // Can't have decelaration of [0-1:0]

  localparam RS_RATIO_LOG2         = (A2X_RS_RATIO_LOG2==0)? 1 : A2X_RS_RATIO_LOG2;    

  // For Fullsized configs
  // 0 -> Always set size to SP Size.  
  // 1 -> If PP alen is less that the number of SP Bytes adjust size correctly, 
  localparam UPSIZE_SIZE           = 0; // 

  // **************************************************************************************
  // I/O Decelaration
  // **************************************************************************************
  input  [A2X_PYLD_I-1:0]                    pyld_i;
  output [A2X_PYLD_O-1:0]                    pyld_o;
  output [2:0]                               rs_ratio;
  //spyglass disable_block W240
  //SMD: An input has been declared but is not read.
  //SJ : This input is read only in selected config 
  input                                      onek_exceed;
  //spyglass enable_block W240

  output                                     ds_fixed_decomp;
  output [BLW_RS-1:0]                        ds_fixed_len;
  
  // **************************************************************************************
  // Signal Decelaration
  // **************************************************************************************
  wire   [`i_axi_a2x_2_A2X_IDW-1:0]                      id_i;            // Payload Decode
  wire   [A2X_AW-1:0]                        addr_i; 
  wire   [BLW_AS-1:0]                        len_i; 
  wire   [`i_axi_a2x_2_A2X_BSW-1:0]                      size_i;     
  wire   [`i_axi_a2x_2_A2X_BTW-1:0]                      burst_i;   
  wire   [`i_axi_a2x_2_A2X_LTW-1:0]                      lock_i;   
  wire   [`i_axi_a2x_2_A2X_CTW-1:0]                      cache_i; 
  wire   [`i_axi_a2x_2_A2X_PTW-1:0]                      prot_i; 
  wire   [A2X_ASBW-1:0]                      sideband_i;
  wire   [A2X_QOSW-1:0]                      qos_i;
  wire   [A2X_REGIONW-1:0]                   region_i;
  wire   [A2X_DOMAINW-1:0]                   domain_i;
  wire   [A2X_WSNOOPW-1:0]                   snoop_i;
  wire   [A2X_BARW-1:0]                      bar_i;
  wire   [`i_axi_a2x_2_A2X_RSW-1:0]                      resize_i;
  wire                                       hburst_type;

  wire   [BLW_RS:0]                          len_p1;          // Length plus 1

  wire   [`i_axi_a2x_2_A2X_BSW-1:0]                      ds_size;         // Downsized Size
  wire   [`i_axi_a2x_2_A2X_BSW-1:0]                      us_size;         // Upsized size
  wire   [`i_axi_a2x_2_A2X_BSW-1:0]                      rs_size;         // Resized Size
  wire   [BLW_RS-1:0]                        ds_len;          // Downsized Length
  reg    [BLW_RS-1:0]                        ds_len_r;        // Downsized Length
  wire   [2:0]                               ds_ratio;
  reg    [31:0]                              us_len;          // Upsized Length
  wire   [BLW_RS-1:0]                        rs_len;          // Resized Length
  wire   [`i_axi_a2x_2_A2X_BTW-1:0]                      rs_burst;   

  wire   [2:0]                               us_ratio;

  // **************************************************************************************
  // Decode Address Payload Bus
  // **************************************************************************************
  assign {bar_i, snoop_i, domain_i, region_i, qos_i, hburst_type, sideband_i, id_i, addr_i, resize_i, len_i, size_i, burst_i, lock_i, cache_i, prot_i} = pyld_i;

  // Number of Data Transfer on Primary Port 
  // spyglass disable_block W164a
  // SMD: Identifies assignments in which the LHS width is less than the RHS width
  // SJ : This is not a functional issue, this is as per the requirement.
  assign len_p1             = len_i + 1;
  // spyglass enable_block W164a

  generate
  if (A2X_DOWNSIZE==1) begin: DSBLK

    assign ds_size = (size_i<A2X_SP_MAX_SIZE) ? size_i:A2X_SP_MAX_SIZE;

    // **************************************************************************************
    // Downsize Length
    //  When Downsizing a Transaction the new length is calculated as
    //  - Downsized Ratio * Primary Port Length
    //
    //  The Downsized Ratio is dependant on the PP & SP Datawidths and the PP Transaction Size. 
    //  For a 64 bit PP DW downsized to a 16 bit PP DW we have to following rs_ratio
    //  PP Size 3 -> RS Ratio PP_DW/SP_DW = 4
    //  PP Size 2 -> RS Ratio PP Transaction Size in Bits/SP_DW (32/16) = 2
    //  PP Size 1 -> RS Ratio PP Transaction Size in Bits/SP_DW (16/16) = 1
    //  PP Size 0 -> Since the Size is less than MAX SP Size Rs Ration of 1 is used
    // **************************************************************************************
    // spyglass disable_block W164b
    // SMD: Identifies assignments in which the LHS width is greater than the RHS width
    // SJ : This is not a functional issue, this is as per the requirement.
    wire [31:0] pp_numbytes     = len_p1 << size_i;
    wire [31:0] pp_bytes_beat   = (1 << size_i);
  //  wire [5:0]  ds_addr_msk     = ~(6'b11_1111 << size_i) & (6'b11_1111 << A2X_SP_MAX_SIZE);
  //  wire [5:0]  ds_addr_sub     = (addr_i[5:0]&ds_addr_msk);
    wire [6:0]  ds_addr_msk     = ~(7'b111_1111 << size_i) & (7'b111_1111 << A2X_SP_MAX_SIZE);
    wire [6:0]  ds_addr_sub     = (addr_i[6:0]&ds_addr_msk);
    wire [31:0] max_sp_numbytes = (1<<A2X_BLW)  << ds_size;
    // spyglass disable_block W484
    // SMD: Possible loss of carry or borrow due to addition or subtraction
    // SJ: Carry/borrow loss will never happen functionaly
    // spyglass disable_block W164a
    // SMD: Identifies assignments in which the LHS width is less than the RHS width
    // SJ : This is not a functional issue, this is as per the requirement.
    wire [31:0] ds_numbytes     = pp_numbytes-ds_addr_sub;
    // spyglass enable_block W164a
    // spyglass enable_block W484 

    assign ds_ratio        = (size_i>=A2X_SP_MAX_SIZE) ? size_i-A2X_SP_MAX_SIZE : 3'b0;   

  // spyglass disable_block TA_09
  // SMD: Reports cause of uncontrollability or unobservability and estimates the number of nets whose controllability/ observability is impacted
  // SJ : Few bits of RHS may not be always required 
    always @(*) begin: dslen_PROC
      ds_len_r  = (ds_numbytes >> ds_size)-1;
      if ((A2X_PP_MODE==0) && (A2X_CHANNEL==0) && hburst_type) begin
        if (pp_bytes_beat>max_sp_numbytes)
          ds_len_r = (pp_bytes_beat >> ds_size)-1;
        else if (pp_numbytes>max_sp_numbytes)
          ds_len_r = (max_sp_numbytes >> ds_size)-1;
      end
    end
  // spyglass enable_block TA_09

    assign ds_len = ds_len_r; 
        
    assign ds_fixed_decomp = (burst_i==`i_axi_a2x_2_ABURST_FIXED) && (size_i>A2X_SP_MAX_SIZE);
   // assign ds_fixed_len    = ((pp_bytes_beat-ds_addr_sub[5:0])>>ds_size)-1;
    // spyglass disable_block SelfDeterminedExpr-ML
    // SMD: Self determined expression present in the design.
    // SJ: This is not a problem with respect to verilog and design requirement 
    // spyglass disable_block TA_09
    // SMD: Reports cause of uncontrollability or unobservability and estimates the number of nets whose controllability/ observability is impacted
    // SJ : The length of the operand varies based on configuration. This will not cause functional issue.
    assign ds_fixed_len    = ((pp_bytes_beat-ds_addr_sub[6:0])>>ds_size)-1;
    // spyglass enable_block TA_09
    // spyglass enable_block SelfDeterminedExpr-ML
      
    assign rs_ratio    =  ds_ratio;
    assign rs_size     =  ds_size;
    assign rs_len      =  ds_len;
    assign rs_burst    = ((size_i>A2X_SP_MAX_SIZE) && (burst_i==`i_axi_a2x_2_ABURST_FIXED))? `i_axi_a2x_2_ABURST_INCR : burst_i;
    // spyglass enable_block W164b

  end else begin// if (A2X_DOWNSIZE==1) begin: DSBLK
    assign ds_fixed_decomp = 1'b0;
    assign ds_fixed_len    = {BLW_RS{1'b0}};
  end
  endgenerate


  // **************************************************************************************
  // **************************************************************************************
  generate
  if (A2X_UPSIZE==1) begin: USBLK
    
    assign us_ratio = (size_i>=A2X_PP_MAX_SIZE) ? A2X_SP_MAX_SIZE-A2X_PP_MAX_SIZE : 3'b0;   

    // **************************************************************************************
    // Upsize Size
    // 
    // If Primary Port Size is Fullsized then SP Size equals Max SP Size.
    // Otherwise transaction remains as subsized.
    // **************************************************************************************
    assign us_size = ((size_i==A2X_PP_MAX_SIZE) && resize_i && (burst_i!=`i_axi_a2x_2_ABURST_FIXED))? A2X_SP_MAX_SIZE : size_i;

    // **************************************************************************************
    // Upsize Length
    //
    // If Primary Port Size is Fullsized then SP Length equals 
    // PP Length/Resize Ratio i.e PP Length/(SP_DW/PP_DW) Otherwise the
    // transaction length remains unchanged.
    // 
    // Divide by Resize Ratio & increment by 1 if remainder. 
    // PP Total Number of Bytes/ Max SP Numbytes
    // **************************************************************************************
    //spyglass disable_block W415a
    //SMD: Signal may be multiply assigned (beside initialization) in the same scope.
    //SJ : us_len is initialized before assignment to avoid latches.
    always @(*) begin: us_len_PROC
      us_len = 32'b0; 
      // Add 1 to division if unaligned address.
      // Or if division by RATIO results in remained.
      // Example upsizing from 16-> 64, alen 5(6) and address 0x6.
      // If AHB Write and Bufferable (len==0) for Non-Bufferable Subtract unaligned address
      if (hburst_type && (A2X_PP_MODE==0) && (A2X_CHANNEL==0) && (|len_i) & (~onek_exceed))
        // spyglass disable_block W116
        // SMD: Identifies the unequal length operands in the bit-wise logical, arithmetic, and ternary operators
        // SJ : This is not a functional issue, this is as per the requirement.
        // spyglass disable_block W164b
        // SMD: Identifies assignments in which the LHS width is greater than the RHS width
        // SJ : This is not a functional issue, this is as per the requirement.
        us_len =  len_i - addr_i[((A2X_SP_NUM_BYTES_LOG2-A2X_PP_NUM_BYTES_LOG2)-1)+A2X_PP_NUM_BYTES_LOG2:A2X_PP_NUM_BYTES_LOG2];
      else 
        us_len =  len_i + addr_i[((A2X_SP_NUM_BYTES_LOG2-A2X_PP_NUM_BYTES_LOG2)-1)+A2X_PP_NUM_BYTES_LOG2:A2X_PP_NUM_BYTES_LOG2];
      
      // Divide by RATIO and ignore the remainder
      if ((size_i==A2X_PP_MAX_SIZE) && resize_i && (burst_i!=`i_axi_a2x_2_ABURST_FIXED)) begin
        us_len = us_len[31:A2X_SP_NUM_BYTES_LOG2-A2X_PP_NUM_BYTES_LOG2];
      end else 
        us_len = len_i;
        // spyglass enable_block W164b
        // spyglass enable_block W116
      
      // Max Length in AHB is 2^BLW.
      if ((A2X_PP_MODE==0) && (A2X_CHANNEL==0) && (us_len>=(1<<A2X_BLW)) && hburst_type) begin
        us_len = (1<<A2X_BLW)-1;
      end
    end
    //spyglass enable_block W415a
    assign rs_ratio   =  us_ratio;
    assign rs_size    =  us_size;
    assign rs_len     =  us_len[BLW_RS-1:0];
    assign rs_burst   =  burst_i;

  end // if (A2X_UPSIZE==1) begin: USBLK
  endgenerate

  // **************************************************************************************
  // Payload 
  // **************************************************************************************
  assign pyld_o    = {bar_i, snoop_i, domain_i, region_i, qos_i, hburst_type, sideband_i, id_i, addr_i, resize_i, rs_len, rs_size, rs_burst, lock_i, cache_i, prot_i};

endmodule
