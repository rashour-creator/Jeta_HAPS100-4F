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
// File Version     :        $Revision: #5 $ 
// Revision: $Id: //dwh/DW_ocb/DW_axi_a2x/axi_dev_br/src/DW_axi_a2x_w_pk.v#5 $ 
// --------------------------------------------------------------------
*/

`include "DW_axi_a2x_all_includes.vh"
//*********************************************************
// Write Data Packer
//
// Used by the Primary Port to pack data into the Write Data FIFO. The packer
// uses a Shift register scaled to the number of Data bytes on the SP read Data bus.
//
// This shift register is also used to determine when to generate a push into
// the Write Data FIFO. 
//
// Consider a upsizing config of PP DW 16 bits and a SP DW of 64 bits.
// This requires a shift register of 8 bits with each bit representing a bytes
// on the SP data bus. 
//
// The packer uses the transfer size and address to determine shift register decode value.  
// and to determine the number of bits to shift by after each valid PP write Data.
//
// For a fulled sized transfer (Size 1) a shift value of 2 is used with a value of 
// 3 -> indicates bytes [0] & [1] are valid
// c -> indicates bytes [2] & [3] are valid ...
//
// For a subsized transfer (Size 0) a shift value of 1 is used with a value of
// 1 -> indicates byte [0] is valid
// 2 -> indicates byte [1]is valid ...
//
//*********************************************************
module i_axi_a2x_2_DW_axi_a2x_w_pk (/*AUTOARG*/
   // Outputs
   w_fifo_push_n, w_pyld_o, wrap_ub_len,
   // Inputs
   clk, resetn, wvalid_i, wready_i, w_pyld_i, rs_pyld_i
   );

  //*********************************************************
  // Parameter Decelaration
  //*********************************************************
  parameter   A2X_PP_PYLD_W         = 64; 
  parameter   A2X_SP_PYLD_W         = 64; 
  parameter   A2X_PP_OSAW_PYLD_W    = 32; 

  parameter   A2X_BLW               = 4;
  parameter   A2X_RS_RATIO          = 1;
  parameter   A2X_PP_DW             = 32;
  parameter   A2X_PP_WSTRB_DW       = 4;
  parameter   A2X_PP_MAX_SIZE       = 2;
  parameter   A2X_PP_NUM_BYTES      = 4;
  parameter   A2X_PP_NUM_BYTES_LOG2 = 0;
  parameter   A2X_SP_DW             = 32;
  parameter   A2X_SP_WSTRB_DW       = 4;
  parameter   A2X_SP_NUM_BYTES      = 4;
  parameter   A2X_SP_NUM_BYTES_LOG2 = 0; 
  parameter   A2X_PP_MODE           = 0;

  localparam  PP_D_W                = A2X_PP_DW + A2X_PP_WSTRB_DW + 1;

  // Can't have a signal decelaration of A2X_SP_NUM_BYTES_LOG2-1:0 when A2X_SP_NUM_BYTES_LOG2==0
  localparam  PP_NUM_BYTES_LOG2     = (A2X_PP_NUM_BYTES_LOG2==0)? 1 : A2X_PP_NUM_BYTES_LOG2;
  localparam  SP_NUM_BYTES_LOG2     = (A2X_SP_NUM_BYTES_LOG2==0)? 1 : A2X_SP_NUM_BYTES_LOG2;

  localparam  ADDR_MASKW            = 13;
  localparam  BLW_AS            = 13;

  //*********************************************************
  // I/O Decelaration
  //********************************************************* 
  input                                 clk;
  input                                 resetn;
   
  input                                 wvalid_i;    
  input                                 wready_i;    
  input  [A2X_PP_PYLD_W-1:0]            w_pyld_i;

  output                                w_fifo_push_n;
  output [A2X_SP_PYLD_W-1:0]            w_pyld_o;

  input  [A2X_PP_OSAW_PYLD_W-1:0]       rs_pyld_i;

  output [A2X_BLW-1:0]                  wrap_ub_len;

  //********************************************************* 
  // Signal Decelaration
  //********************************************************* 
  wire   [A2X_PP_DW-1:0]                wdata_i; 
  wire   [A2X_PP_WSTRB_DW-1:0]          wstrb_i;
  wire                                  wlast_i;   

  wire   [A2X_SP_DW-1:0]                wdata_w; 
  wire   [A2X_SP_WSTRB_DW-1:0]          wstrb_w;

  wire   [A2X_SP_DW-1:0]                wdata_pk; 
  wire   [A2X_SP_WSTRB_DW-1:0]          wstrb_pk;
  wire                                  wlast_pk; 

  wire   [12:0]                         addr_i;
  wire   [12:0]                         addr;
  wire   [`i_axi_a2x_2_A2X_BSW-1:0]                 size_i;     
  wire   [`i_axi_a2x_2_A2X_BTW-1:0]                 burst_i;     
  wire   [A2X_BLW-1:0]                  len_i;     
  wire                                  resize_i;

  wire   [SP_NUM_BYTES_LOG2-1:0]        align_addr;
  wire                                  pp_subsized;
  
  reg                                   load_r;
  reg    [A2X_SP_NUM_BYTES-1:0]         shift_r;
  wire   [A2X_SP_NUM_BYTES-1:0]         shift_w;
  wire   [A2X_SP_NUM_BYTES-1:0]         shift;

  wire                                  shift_msb;

  wire                                  w_fifo_push;
  wire                                  byte_clr; 
  wire                                  load; 


  //********************************************************* 
  // Resize FIFO Decode
  // 
  // Resize information contains
  // - Primary Port transaction size
  // - Secondary Port Transaction aligned address bits i.e. for a 64 bit
  //   SP DW the aligned address contains address bits [2:0] (8 bytes)
  // - Primary Port resize field. Transactions are only resized when this bit
  //   is high.
  //********************************************************* 
  assign {resize_i, burst_i, size_i, len_i, addr_i}   = rs_pyld_i;

  // Write Data Payload Decode
  // spyglass disable_block W164a
  // SMD: Identifies assignments in which the LHS width is less than the RHS width
  // SJ : This is not a functional issue, this is as per the requirement.
  //      Hence this can be waived.  
  assign {wstrb_i, wdata_i, wlast_i}  = w_pyld_i;
  // spyglass enable_block W164a

  // Generate aligned Address
  // spyglass disable_block W164a
  // SMD: Identifies assignments in which the LHS width is less than the RHS width
  // SJ : This is not a functional issue, this is as per the requirement.
  //      Hence this can be waived.  
  assign align_addr = addr_i & ({A2X_SP_NUM_BYTES_LOG2{1'b1}} << size_i);
  // spyglass enable_block W164a
  
  // Determine if transfer is subsized.
  //Signed and unsigned operands should not be used in same operation.
  //It is a design requirement to use A2X_PP_MAX_SIZE in the following operation and it 
  //     will not have any adverse effects on the design. So signed and unsigned operands are used.
  assign pp_subsized = (size_i!=A2X_PP_MAX_SIZE)? 1'b1 : 1'b0;

  // Used to assert load register and reset wrap count. 
  assign load = wlast_i & wready_i & wvalid_i;

  // **************************************************************************************
  // Fannout Size to Maximum
  // **************************************************************************************
  reg  [7:0]  size_1hot;
  reg  [7:0]  size_1hot_w;
  wire [31:0] len_w;

  //spyglass disable_block W415a
  //SMD: Signal may be multiply assigned (beside initialization) in the same scope.
  //SJ : size_1hot is initialized before assignment to avoid latches.
  always @(*) begin: size1hot_PROC
    integer i; 
    size_1hot = 8'b0;
    for (i=0; i<=A2X_PP_MAX_SIZE; i=i+1)
      //Signed and unsigned operands should not be used in same operation.
      //i can only be an integer, since it is a loop index. It is a design requirement to
      //     use i in the following operation and it will not have any adverse effects on the 
      //     design. So signed and unsigned operands are used to reduce the logic.
      if (i==size_i) size_1hot[i] = 1'b1;
  end   
 
  // Added size_1hot_w to improve coverage results on the case expression below
  always @(*) begin : size_1hotw_PROC
     size_1hot_w[7:0] = 8'b0;
     size_1hot_w[A2X_PP_MAX_SIZE:0] = size_1hot[A2X_PP_MAX_SIZE:0];
  end
  //spyglass enable_block W415a

  // Transaction Length
  assign len_w[31:A2X_BLW]  = {(32-A2X_BLW){1'b0}}; 
  assign len_w[A2X_BLW-1:0] = len_i; 

  //********************************************************* 
  //Wrap Decode
  //********************************************************* 
  wire                         wrap_b;   // WRap Boundary
  reg  [7:0]                   wrap_len; 
  reg  [7:0]                   wrap_cnt; 
  wire [SP_NUM_BYTES_LOG2-1:0] wrap_addr;
  reg  [12:0]                  addr_mask;
  
  always @(posedge clk or negedge resetn) begin: wrap_cnt_PROC
    if (resetn == 1'b0) begin
      wrap_cnt <= 8'd0;
    end else begin
      if (load)
        wrap_cnt <= 8'd0;
      else if ((burst_i==`i_axi_a2x_2_ABURST_WRAP) && wready_i && wvalid_i)
        wrap_cnt <= wrap_cnt + 8'd1;
    end
  end
    
  // Wrap Boundary Reached.
  assign wrap_b = (burst_i==`i_axi_a2x_2_ABURST_WRAP) && (wrap_cnt==wrap_len);

  assign addr = addr_i;
   
  // **************************************************************************************
  // Addess Decode 
  // **************************************************************************************
  assign wrap_addr = addr_i[SP_NUM_BYTES_LOG2-1:0] & addr_mask[SP_NUM_BYTES_LOG2-1:0];

      
   // **************************************************************************************
   // Addess Decode 
   //
   // Calculates the Second Address for a Wrap Transaction.
   // **************************************************************************************
   // Address Mask
   // spyglass disable_block W415a
   // SMD: Signal may be multiply assigned (beside initialization) in the same scope.
   // SJ : addr_mask is assigned in each iteration to decode the address. It is initialized to avoid latches.
   // spyglass disable_block W164a
   // SMD: Identifies assignments in which the LHS width is less than the RHS width
   // SJ : This is not a functional issue, this is as per the requirement.
   always @(*) begin : addr_mask_PROC
     integer i;
     integer j;
     addr_mask = {{(ADDR_MASKW-1){1'b1}},{1'b0}};
     for (j=1; j<= A2X_PP_MAX_SIZE; j=j+1)
       if (size_i==j) addr_mask = addr_mask<<j;
     for (i=1 ; i <= A2X_BLW; i=i+1)
       if (len_i==(1'b1<<(i+1))-1) addr_mask=addr_mask<<i;
     // spyglass enable_block W164a
   end
   
   reg [A2X_BLW-1:0] addr_size;
   // spyglass disable_block W486
   // SMD: Reports shift overflow operations
   // SJ : This is not a functional issue, this is as per the requirement.
   // spyglass disable_block W164a
   // SMD: Identifies assignments in which the LHS width is less than the RHS width
   // SJ : This is not a functional issue, this is as per the requirement.
   always @(*) begin : beat_addr_PROC
     integer i,j;
     wrap_len = 8'b0;
     addr_size = addr[A2X_BLW-1:0]; 
     for (j=1; j<= A2X_PP_MAX_SIZE;j=j+1)
       if (size_i==j) addr_size = addr >> j;
     for (i=0 ; i < A2X_BLW; i=i+1)
       if (len_i[i]==1'b1) wrap_len[i]= (~addr_size[i]); 
   end
   // spyglass enable_block W164a
   // spyglass enable_block W486
    
  assign wrap_ub_len = wrap_len[A2X_BLW-1:0];
 
  //********************************************************* 
  // Decode the shift register reset value and the initial value. 
  //
  // The Transaction size and address is used to determine the initial shift
  // register value. Transaction size of
  // 1 Byte  -> initial value of 8'h1
  // 2 Bytes -> initial value of 8'h3
  // 4 Bytes -> initial value of 8'hf ...
  //
  // The transaction address is then used to determine the initial shift
  // register starting position. 
  //*********************************************************
  reg [127:0] init_dec;
  reg [127:0] wrap_dec;
  reg [127:0] msb_dec;
  always @(*) begin: init_dec_PROC
    init_dec = {{127{1'b0}}, 1'b1};
    wrap_dec = {{127{1'b0}}, 1'b1};
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
    init_dec = msb_dec << align_addr;
    wrap_dec = msb_dec << wrap_addr;
  end
  // spyglass enable_block W415a

  //********************************************************* 
  // Shift Register Load 
  //
  // Asserted high until the first SP Read Data transaction is accepted.
  //********************************************************* 
  always @(posedge clk or negedge resetn) begin: load_PROC
    if (resetn == 1'b0) begin
      load_r <= 1'b1;
    end else begin
      if (load) 
        load_r <= 1'b1; 
      else if (wready_i && wvalid_i) 
        load_r <= 1'b0;
    end
  end

  //********************************************************* 
  // Shift Register
  //
  // - When shift register MSB is detected reset shift register.
  // - When load value asserted set the shift register to initial value
  //   shifted by transfer size.
  // - otherwise shift by the transfer size.
  //********************************************************* 
  always @(posedge clk or negedge resetn) begin: shift_PROC
    if (resetn == 1'b0) begin
      shift_r <= {A2X_SP_NUM_BYTES{1'b1}};
    end else begin 
      if ( wready_i && wvalid_i) begin
        if (burst_i==`i_axi_a2x_2_ABURST_FIXED && A2X_PP_MODE==1)
          shift_r <= init_dec[A2X_SP_NUM_BYTES-1:0]; 
        else if (wrap_b)
          shift_r <= wrap_dec[A2X_SP_NUM_BYTES-1:0]; 
        else if (shift_msb)
          shift_r <= msb_dec[A2X_SP_NUM_BYTES-1:0]; 
        else if (load_r)
          shift_r <= init_dec[A2X_SP_NUM_BYTES-1:0]  << (1 << size_i); 
        else
          shift_r <= shift << (1 << size_i);
      end
    end
  end

  // The load register is used to select the initial decode value. 
  assign shift_w = (load_r)? init_dec[A2X_SP_NUM_BYTES-1:0] : shift_r; 

  // If Transaction is not to be resized always enable Byte Packer.
  // Hence the Bype Packer will always drive the output directly from the
  // input and the byte clear bit will be high. 
  assign shift     =  shift_w;

  //********************************************************* 
  // Packing 
  //********************************************************* 
  assign byte_clr     = w_fifo_push;  // Byte Register cleared if not resized
  assign shift_msb    = shift[A2X_SP_NUM_BYTES-1];

  // Fannout of Write Data & Strobe to SP Data Width 
  assign wstrb_w      = {A2X_RS_RATIO{wstrb_i}};
  assign wdata_w      = {A2X_RS_RATIO{wdata_i}};

  // Byte Control Instantiation
  // - Used to store the Write Data Bytes from the SP until the packer is
  //   ready to generate a push into the FIFO.
  generate
    genvar i;
    for (i = 0; i <A2X_SP_NUM_BYTES; i = i + 1) begin : pk_byte
      
      i_axi_a2x_2_DW_axi_a2x_pk_byte
       
      U_pk_byte (
         .clk               (clk)
        ,.resetn            (resetn)
        ,.wvalid            (wvalid_i)
        ,.wready            (wready_i)
        ,.byte_clr          (byte_clr)
        ,.byte_en           (shift[i])
        ,.wstrb_i           (wstrb_w[i])
        ,.wdata_i           (wdata_w[(i*8)+7:(i*8)])
        
        ,.wstrb_o           (wstrb_pk[i])
        ,.wdata_o           (wdata_pk[(i*8)+7:(i*8)])
      );
    end
  endgenerate

  // Generate Write Last
  assign wlast_pk = wlast_i; 

  // If Full Sized Push when Shift Register MSB is set.
  // If Subsized or RESIZE is not set push on every cycle. 
  assign w_fifo_push   = (shift_msb | wlast_i | pp_subsized | (!resize_i) | wrap_b | (burst_i==`i_axi_a2x_2_ABURST_FIXED)) & wvalid_i & wready_i;
  assign w_fifo_push_n = !w_fifo_push;

  // Write Data Payload
  assign w_pyld_o      = {w_pyld_i[A2X_PP_PYLD_W-1:PP_D_W], wstrb_pk, wdata_pk, wlast_pk};

endmodule
