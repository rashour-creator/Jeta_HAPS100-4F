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
// Revision: $Id: //dwh/DW_ocb/DW_axi_a2x/amba_dev/src/DW_axi_a2x_r_upk_dec.v#1 $ 
// --------------------------------------------------------------------
*/

`include "DW_axi_a2x_all_includes.vh"
//*********************************************************
// Read Data Unpacker Decode - This block resides inside the Read Data UID Control.
// 
// The function of the unpacker is to provide a tag bit with the read data 
// so that the read data unpacker can determine the valid PP data bytes within
// the SP data Transfer.
//
// When upsizing from a 16 bit PP to a 64 SP the read data FIFO would contain
// 4 tag bits with each bit indication which Primary Port Transfer is valid.
// 1 -> [15:0] Valid
// 2 -> [31:16] Valid
// 3 -> [15:0] & [31:16] Valid
//*********************************************************
module i_axi_a2x_1_DW_axi_a2x_r_upk_dec (/*AUTOARG*/
   // Outputs
   r_pyld_tag, 
   // Inputs
   clk, resetn, rvalid_i, rready_i, rid_valid, rlast_i, 
   rs_pyld_i
   );

  //*********************************************************
  // Parameter Decelaration
  //*********************************************************
  parameter   A2X_PP_MODE           = 1; 
  parameter   A2X_RS_PYLD_W         = 32; 

  parameter   A2X_BLW               = 4;
  parameter   A2X_RS_RATIO          = 1;

  parameter   A2X_PP_MAX_SIZE       = 2;
  parameter   A2X_PP_NUM_BYTES      = 4; 

  parameter   A2X_SP_NUM_BYTES      = 4; 
  parameter   A2X_SP_NUM_BYTES_LOG2 = 2; 
  
  // Address width                  =  Numer of address bits for Secondary Port Bits + 
  //                                   Number of Bits for Burst length + 
  //                                   Boundary  Bits as calculation will cross boundary
  //                                   Example Address 0x2, alen 0xf (16) Size 0x1 (2 Beats) = 0x34
  //                                   
  localparam  ADD_W                 = A2X_SP_NUM_BYTES_LOG2 + A2X_BLW + 1;

  //*********************************************************
  // I/O Decelaration
  //********************************************************* 
  input                                  clk;
  input                                  resetn;
   
  input                                  rvalid_i;    
  input                                  rready_i;  
  input                                  rid_valid;
  input                                  rlast_i;   
  input  [A2X_RS_PYLD_W-1:0]             rs_pyld_i;

  output [A2X_RS_RATIO-1:0]              r_pyld_tag;

  //********************************************************* 
  // Signal Decelaration
  //********************************************************* 
  wire   [A2X_SP_NUM_BYTES_LOG2-1:0]     align_addr;
  wire                                   resize;
  wire   [A2X_BLW-1:0]                   alen_pp; 
  wire   [`A2X_BSW-1:0]                  asize_pp;     
  wire                                   wrap_last;
  wire                                   arlast;
  wire                                   fixed;
  wire                                   fixed_i;

  wire   [A2X_SP_NUM_BYTES_LOG2-1:0]     addr_i;

  //The additional bits are defined to connect the unconnected nets.
  //     Hence few bits will not drive any net. This will not cause 
  //     any functional issue.
  wire   [ADD_W-1:0]                     last_addr;
  wire                                   subsized;

  reg                                    load_r;

  reg    [A2X_SP_NUM_BYTES-1:0]          shift_r;
  wire   [A2X_SP_NUM_BYTES-1:0]          shift;

  //The additional bits are defined to connect the unconnected nets.
  //     Hence few bits will not drive any net. This will not cause
  //     any functional issue.
  reg    [A2X_SP_NUM_BYTES-1:0]          r_tag_decode;
  reg    [A2X_RS_RATIO-1:0]              r_pyld_tag;

  //********************************************************* 
  // Resize FIFO Decode
  // 
  // Resize information contains
  // - Primary Port transaction size
  // - Primary Port Transaction aligned address bits i.e. for a 64 bit
  //   PP DW the aligned address contains address bits [2:0] (8 bytes)
  // - Primary Port resize field. Transactions are always resized for
  //   Downsized Configurations hence this bit is always set to 1'b0. 
  //********************************************************* 
  assign {resize, fixed_i, alen_pp, asize_pp, addr_i, wrap_last, arlast}   = rs_pyld_i;

  // No Fixed Transactions in AHB.
  assign fixed = (A2X_PP_MODE==0)? 1'b0 : fixed_i; 

  //Generate aligned Address
  assign align_addr = addr_i & ({A2X_SP_NUM_BYTES_LOG2{1'b1}} << asize_pp);

  // Subsized Transaction
  //Signed and unsigned operands should not be used in same operation.
  //It is a design requirement to use A2X_SP_MAX_SIZE in the following operation and it 
  //     will not have any adverse effects on the design. So signed and unsigned operands are used.
  assign subsized = (asize_pp==A2X_PP_MAX_SIZE)? 1'b0 : 1'b1;

  // Generate Last Address 
  //
  // For upsizing configs not all the data beats returned on the secondary
  // port are required for the Primary Port transaction.
  // Consider a 16 bit PP with alen 0x1 and address of 0x2 to 64 bit SP.
  // In-order to determine the number of valid PP data beats in the last
  // SP transaction the last address needs to be calculated.
  // spyglass disable_block W164a
  // SMD: Identifies assignments in which the LHS width is less than the RHS width
  // SJ : The length of the operand varies based on configuration. This will not cause functional issue.
  // spyglass disable_block TA_09
  // SMD: Reports cause of uncontrollability or unobservability and estimates the number of nets whose controllability/ observability is impacted
  // SJ : The length of the operand varies based on configuration. This will not cause functional issue.
  assign last_addr = ((alen_pp+1) << asize_pp) + align_addr; 
  // spyglass enable_block TA_09
  // spyglass enable_block W164a

  // **************************************************************************************
  // Fannout Size to Maximum
  // **************************************************************************************
  //The additional bits are defined to connect the unconnected nets.
  //     Hence few bits will not drive any net. This will not cause
  //     any functional issue.
  reg  [7:0]  size_1hot;
  reg  [7:0]  size_1hot_w;
  //spyglass disable_block W415a
  //SMD: Signal may be multiply assigned (beside initialization) in the same scope.
  //SJ : size_1hot is initialized before assignment to avoid latches.
  always @(*) begin: size1hot_PROC
    integer i; 
    size_1hot = 8'b0; 
    for (i=0; i<=A2X_PP_MAX_SIZE; i=i+1)
      if (i==asize_pp) size_1hot[i] = 1'b1;
  end   
  // Added size_1hot_w to improve coverage results on the case expression below
  always @(*) begin : size_1hotw_PROC
    size_1hot_w[7:0] = 8'b0;
    size_1hot_w[A2X_PP_MAX_SIZE:0] = size_1hot[A2X_PP_MAX_SIZE:0];
 end
  //spyglass enable_block W415a

  //********************************************************* 
  // Shift Register Decode Value.
  //
  // init_dec  -> initial values based on address alignment for subsized.
  // msb_dec   -> Used instead of wrapping shift register. If shift register
  //              MSB is set next value is msb_dec. Used for subsized.
  // first_dec -> For Fulled sized Transaction this indicates the first decode
  //              value of the read transaction. Data Beats valid from 1st Address.
  // last_dec  -> For Fulled sized Transaction this indicates the last decode
  //              value of the read transaction. Data Beats valid upto Last Address
  //********************************************************* 
  reg  [127:0] init_dec;
  reg  [127:0] msb_dec;
  reg  [127:0] last_dec; 
  reg  [127:0] first_dec; 

  always @(*) begin: init_dec_PROC
    init_dec = {{127{1'b0}}, 1'b1};
  // spyglass disable_block W415a
  // SMD: Signal may be multiply assigned (beside initialization) in the same scope.
  // SJ : init_dec contains initial decode value based on address alignment for subsized. It will be updated based on align_addr.
    msb_dec  = {{127{1'b0}}, 1'b1};
    case (size_1hot_w)
      8'd2 :  msb_dec = {{126{1'b0}}, {2{1'b1}}};
      8'd4 :  msb_dec = {{124{1'b0}}, {4{1'b1}}};
      8'd8 :  msb_dec = {{120{1'b0}}, {8{1'b1}}};
      8'd16:  msb_dec = {{112{1'b0}}, {16{1'b1}}};
      8'd32:  msb_dec = {{96{1'b0}},  {32{1'b1}}};
      8'd64:  msb_dec = {{64{1'b0}},  {64{1'b1}}};
      8'd128:  msb_dec = {128{1'b1}};
      default: msb_dec = {{127{1'b0}}, 1'b1};        
    endcase
    init_dec  = msb_dec      << align_addr;
    first_dec = {128{1'b1}}   << align_addr;
  // spyglass enable_block W415a
    // Next Aligned Address if transaction continued hence last address is this address minus 1.
    //Signed and unsigned operands should not be used in same operation.
    //It is a design requirement to use A2X_SP_MAX_SIZE in the following operation and it 
    //     will not have any adverse effects on the design. So signed and unsigned operands are used.
    last_dec  = (last_addr[A2X_SP_NUM_BYTES_LOG2:0]==A2X_SP_NUM_BYTES) ? ~({128{1'b1}} << A2X_SP_NUM_BYTES): ~({128{1'b1}} << last_addr[A2X_SP_NUM_BYTES_LOG2-1:0]); 
  end

  //********************************************************* 
  // Shift Register Load 
  //
  // When this register is asserted high the shift register loads the init_dec
  // value. This register is deasserted after the first data transaction has
  // completed.
  //********************************************************* 
  wire r_valid       = rready_i & rvalid_i & rid_valid;
  wire r_last        = r_valid & rlast_i;

  // For Upsizing Configurations condition wrap_last(0) and arlast(0) never
  wire osr_fifo_last = wrap_last | arlast;

  always @(posedge clk or negedge resetn) begin: load_PROC
    if (resetn == 1'b0) begin
      load_r <= 1'b1;
    end else begin
      if (osr_fifo_last && r_last) 
        load_r <= 1'b1; 
      else if (r_valid) 
        load_r <= 1'b0;
    end
  end

  //********************************************************* 
  // Shift Register
  // 
  // This shift register is only required for subsized transaction. 
  // Each bit in the shift register represents a data byte on the SP Read Data
  // Bus. A '1' in any of the data fields indicates that that byte is valid
  // for the current transfer. 
  // Consider a subsized transaction of size 0 (1 Bytes)
  // 1 -> Byte [0] Valid
  // 2 -> Byte [1] Valid ....
  // Consider a subsized transaction of size 1 (2 Bytes)
  // 3 -> Bytes [0] & [1] Valid
  // C -> Bytes [2] & [3] Valid
  //********************************************************* 
  always @(posedge clk or negedge resetn) begin: shift_PROC
    if (resetn == 1'b0) begin
      shift_r <= {A2X_SP_NUM_BYTES{1'b1}};
    end else begin 
      if (r_valid && (subsized || (!resize) || fixed)) begin
        if (fixed)
          shift_r <= init_dec[A2X_SP_NUM_BYTES-1:0]; 
        else if (shift[A2X_SP_NUM_BYTES-1])
          shift_r <= msb_dec[A2X_SP_NUM_BYTES-1:0]; 
        else if (load_r)
          shift_r <= init_dec[A2X_SP_NUM_BYTES-1:0]  << (1 << asize_pp); 
        else 
          shift_r <= shift << (1 << asize_pp);
      end
    end
  end

  assign shift = (load_r)? init_dec[A2X_SP_NUM_BYTES-1:0] : shift_r; 
  
  //********************************************************* 
  // Read Data Tag Bits
  //
  // The TAG Bits are pushed into the Read Data FIFO with the Read data to
  // indicate to the read data unpacker which data bytes are valid. 
  //
  // If the transaction is subsized then the tag decode is provided by the
  // shift register. Otherwise the tag decode bits are broken down as
  // described below.
  //********************************************************* 
  always @(*) begin: tag_dec_PROC
    r_tag_decode = {A2X_SP_NUM_BYTES{1'b1}};
    if (subsized || (!resize) || fixed) begin
      r_tag_decode = shift;
    end else begin
      // Consider 16 bit PP with alen 0x1 and address of 0x2 to 64 bit SP.
      // The SP has only one data transaction to return and only bit [5:2] are
      // valid. Hence bit [1:0] and [7:6] should be masked off so that the PP
      // read data unpacker knows not to return the data for these bits. 
      if (load_r && rlast_i && osr_fifo_last)
        // spyglass disable_block W164a
        // SMD: Identifies assignments in which the LHS width is less than the RHS width
        // SJ : The length of the operand first_dec and last_dec varies based on the configuration. But this logic requires
        //      only the lower A2X_SP_NUM_BYTES bits. This is not a functional issue, this is as per the requirement.
        //      Hence this can be waived.  
        r_tag_decode = first_dec & last_dec;
        // spyglass enable_block W164a
        // If First Transaction and SP alen greater than 0. This indicates the
        // starting point for the read data unpacker decoder. 
      else if (load_r) 
        // spyglass disable_block W164a
        // SMD: Identifies assignments in which the LHS width is less than the RHS width
        // SJ : The length of the operand first_dec varies based on the configuration. But this logic requires
        //      only the lower A2X_SP_NUM_BYTES bits. This is not a functional issue, this is as per the requirement.
        //      Hence this can be waived.  
        r_tag_decode = first_dec;
        // spyglass enable_block W164a
        // If Last Transactionan SP alen greater than 0. This indicates the last
        // valid data beat for the read data unpacker decoder.
      else if (rlast_i && arlast)
        // spyglass disable_block W164a
        // SMD: Identifies assignments in which the LHS width is less than the RHS width
        // SJ : The length of the operand last_dec varies based on the configuration. But this logic requires
        //      only the lower A2X_SP_NUM_BYTES bits. This is not a functional issue, this is as per the requirement.
        //      Hence this can be waived.  
        r_tag_decode = last_dec;
        // spyglass enable_block W164a
      else 
        // If in the middle of a Fulled Sized Transaction all data beats are
        // valid. 
        r_tag_decode = {A2X_SP_NUM_BYTES{1'b1}};
    end
  end

  //****************************************************************************
  // TAG Decode.
  //
  // The number of TAG bits sent with the read data is based on the resize
  // ratio. For a upsizing config of PP DW 16 and SP DW 32 the resize ratio
  // is 2. The read data unpacker uses these bits to determine how many data 
  // transactions to return on the primary port i.e. A TAG value of
  // 1 -> read data bit [31:0] are valid
  // 2 -> read data bit [63:32] are valid
  // 3 -> read data bit [63:32] and [31:0] are valid
  //****************************************************************************
  //spyglass disable_block W415a
  //SMD: Signal may be multiply assigned (beside initialization) in the same scope.
  //SJ : r_pyld_tag is initialized before entering into loop to avoid latches.
  // spyglass disable_block SelfDeterminedExpr-ML
  // SMD: Self determined expression found
  // SJ: The expression indexing the vector/array will never exceed the bound of the vector/array.
  always @(*) begin: tag_PROC    
    integer i,j; 
    r_pyld_tag = {A2X_RS_RATIO{1'b0}};
    for (i=0; i<A2X_RS_RATIO; i=i+1) begin
      for (j=0; j<A2X_PP_NUM_BYTES; j=j+1) begin       
        r_pyld_tag[i] = r_pyld_tag[i] | r_tag_decode[(i*A2X_PP_NUM_BYTES)  + j];
      end
    end
  end
  // spyglass enable_block SelfDeterminedExpr-ML
  //spyglass enable_block W415a

endmodule
