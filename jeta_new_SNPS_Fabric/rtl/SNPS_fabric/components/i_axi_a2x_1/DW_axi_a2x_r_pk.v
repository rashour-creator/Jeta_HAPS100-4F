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
// File Version     :        $Revision: #7 $ 
// Revision: $Id: //dwh/DW_ocb/DW_axi_a2x/axi_dev_br/src/DW_axi_a2x_r_pk.v#7 $ 
// --------------------------------------------------------------------
*/

`include "DW_axi_a2x_all_includes.vh"
//*********************************************************
// Read Data Packer
//
// Used by the Secondary Port to pack data into the Read Data FIFO. The packer
// uses a Shift register scaled to the number of Data bytes on the PP read Data bus.
//
// This shift register is also used to determine when to generate a push into
// the read Data FIFO. 
//
// Consider a downsizing config of PP DW 64 bits and a SP DW of 16 bits.
// This requires a shift register of 8 bits with each bit representing a bytes
// on the PP data bus. 
//
// The packer uses the transfer size and address to determine shift register decode value.  
// and to determine the number of bits to shift by after each valid SP read Data.
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
module i_axi_a2x_1_DW_axi_a2x_r_pk (/*AUTOARG*/
   // Outputs
   r_fifo_push_n, r_pyld_o, 
   // Inputs
   clk, resetn, rvalid_i, rready_i, rid_valid, r_pyld_i, rs_pyld_i, 
   rs_fifo_empty, arlast
   );

  //*********************************************************
  // Parameter Decelaration
  //*********************************************************
  parameter   A2X_RS_RATIO          = 1; 

  parameter   A2X_PP_DW             = 32; 
  parameter   A2X_PP_MAX_SIZE       = 2;
  parameter   A2X_PP_NUM_BYTES      = 4;
  parameter   A2X_PP_NUM_BYTES_LOG2 = 2;

  parameter   A2X_SP_DW             = 32;
  parameter   A2X_SP_MAX_SIZE       = 2;

  parameter   A2X_PP_PYLD_W         = 64; 
  parameter   A2X_SP_PYLD_W         = 64; 
  parameter   A2X_RS_PYLD_W         = 32; 

  parameter   A2X_RSBW              = 1; 

  localparam  PP_D_W                = A2X_PP_DW + 1;
  localparam  SP_D_W                = A2X_SP_DW + 1;

  //*********************************************************
  // I/O Decelaration
  //********************************************************* 
  input                                  clk;
  input                                  resetn;
   
  input                                  rvalid_i;    
  input                                  rready_i;  
  input                                  rid_valid;
  input                                  arlast;
  input  [A2X_SP_PYLD_W-1:0]             r_pyld_i;

  output                                 r_fifo_push_n;
  output [A2X_PP_PYLD_W-1:0]             r_pyld_o;

  input  [A2X_RS_PYLD_W-1:0]             rs_pyld_i;
  input                                  rs_fifo_empty;

  //********************************************************* 
  // Signal Decelaration
  //********************************************************* 
  wire  [`i_axi_a2x_1_A2X_IDW-1:0]                   rid_i;    
  wire  [A2X_SP_DW-1:0]                  rdata_i; 
  wire  [`i_axi_a2x_1_A2X_RRESPW-1:0]                rresp_i; 
  wire  [A2X_RSBW-1:0]                   rsideband_i;
  wire                                   rlast_i;   

  wire   [A2X_PP_DW-1:0]                 rdata_w; 
  wire   [A2X_PP_DW-1:0]                 rdata_pk; 
  wire                                   rlast_pp;

  wire   [A2X_PP_NUM_BYTES_LOG2-1:0]     align_addr;
  wire   [`i_axi_a2x_1_A2X_BSW-1:0]                  pp_size;     
  wire                                   resize;
  wire                                   ws_last;
  wire                                   ws_fixed; 

  wire   [A2X_PP_NUM_BYTES_LOG2-1:0]     addr_i;
  wire   [`i_axi_a2x_1_A2X_BSW-1:0]                  sp_size;
  wire                                   subsized;
  wire                                   shift_lsb;
  reg    [7:0]                           pp_size_1hot_r;
  reg    [7:0]                           pp_size_1hot;
  reg    [7:0]                           sp_size_1hot_r;
  reg    [7:0]                           sp_size_1hot;
  
  reg                                    load_r;
  reg    [A2X_PP_NUM_BYTES-1:0]          shift_r;
  wire   [A2X_PP_NUM_BYTES-1:0]          shift_w;
  wire   [A2X_PP_NUM_BYTES-1:0]          shift;

  wire                                   shift_msb;

  reg    [`i_axi_a2x_1_A2X_RRESPW-1:0]               rresp_r; 
  wire   [`i_axi_a2x_1_A2X_RRESPW-1:0]               rresp_w; 

  reg                                    r_fifo_push;
  wire   [A2X_PP_PYLD_W-1:0]             r_pyld_o_w;

  //********************************************************* 
  // Resize FIFO Decode
  // 
  // Resize information contains
  // - Primary Port transaction size
  // - Primary Port Transaction SP aligned address bits i.e. for a 64 bit
  //   SP DW the aligned address contains address bits [2:0] (8 bytes)
  // - Primary Port resize field. Transactions are only resized when this bit
  //   is high.
  //********************************************************* 
  assign {resize, ws_fixed, pp_size, addr_i, ws_last}   = rs_pyld_i;

  // Read Data Payload Decode
  assign {rsideband_i, rid_i, rresp_i, rdata_i, rlast_i} = r_pyld_i;

  // Generate SP Size
  //Signed and unsigned operands should not be used in same operation
  //It is a design requirement to use A2X_SP_MAX_SIZE in the following operation and it 
  //will not have any adverse effects on the design. So signed and unsigned operands are used.
  assign sp_size    = (pp_size>A2X_SP_MAX_SIZE)? A2X_SP_MAX_SIZE : pp_size; 

  //Generate aligned Address
  assign align_addr = addr_i & ({A2X_PP_NUM_BYTES_LOG2{1'b1}} << sp_size);

  // Determine if transfer is subsized.
  assign subsized   = (pp_size<=A2X_SP_MAX_SIZE)? 1'b1 : 1'b0;

  // **************************************************************************************
  // Fannout Size to Maximum
  // **************************************************************************************
  //spyglass disable_block W415a
  //SMD: Signal may be multiply assigned (beside initialization) in the same scope.
  //SJ : This is not an issue. It is initialized before assignment to avoid latches.
  always @(*) begin: size1hot_PROC
    integer i; 
    sp_size_1hot_r = 8'b0; 
    pp_size_1hot_r = 8'b0; 
    for (i=0; i<=A2X_SP_MAX_SIZE; i=i+1)
      if (i==sp_size) sp_size_1hot_r[i] = 1'b1;
    for (i=0; i<=A2X_PP_MAX_SIZE; i=i+1)
      if (i==pp_size) pp_size_1hot_r[i] = 1'b1;  // lint Warning Flags here.
  end   
 
  // Added size_1hot_w to improve coverage results on the case expression below
  always @(*) begin : sp_size_1hotw_PROC
    sp_size_1hot[7:0] = 8'b0;
    sp_size_1hot[A2X_SP_MAX_SIZE:0] = sp_size_1hot_r[A2X_SP_MAX_SIZE:0];
   end


 // assign pp_size_1hot[7:A2X_PP_MAX_SIZE+1] = 0;
 // assign pp_size_1hot[A2X_PP_MAX_SIZE:0] = pp_size_1hot_r[A2X_PP_MAX_SIZE:0];
  always @(*) begin : pp_size_1hotw_PROC
    pp_size_1hot[7:0] = 8'b0;
    pp_size_1hot[A2X_PP_MAX_SIZE:0] = pp_size_1hot_r[A2X_PP_MAX_SIZE:0];
  end


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
  reg [127:0] msb_dec;
  always @(*) begin: init_dec_PROC
    init_dec = {{127{1'b0}}, 1'b1};
    msb_dec  = {{127{1'b0}}, 1'b1};
    case (sp_size_1hot)
      8'b00000010:  msb_dec = {{126{1'b0}}, {2{1'b1}}};
      8'b00000100:  msb_dec = {{124{1'b0}}, {4{1'b1}}};
      8'b00001000:  msb_dec = {{120{1'b0}}, {8{1'b1}}};
      8'b00010000:  msb_dec = {{112{1'b0}}, {16{1'b1}}};
      8'b00100000:  msb_dec = {{96{1'b0}}, {32{1'b1}}};
      8'b01000000:  msb_dec = {{64{1'b0}}, {64{1'b1}}};
      8'b10000000:  msb_dec = {128{1'b1}};
      default: msb_dec = {{127{1'b0}}, 1'b1};            
    endcase
    init_dec = msb_dec << align_addr;
  end
  //spyglass enable_block W415a

  //********************************************************* 
  //Shift Register Load 
  //
  // Asserted high until the first SP Read Data transaction is accepted.
  //********************************************************* 
  wire r_valid = rready_i & rvalid_i & rid_valid;
  wire r_last  = r_valid & rlast_i;
  always @(posedge clk or negedge resetn) begin: load_PROC
    if (resetn == 1'b0) begin
      load_r <= 1'b1;
    end else begin
      if (!rs_fifo_empty && (ws_last || arlast) && r_last) 
        load_r <= 1'b1; 
      else if (r_valid) 
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
      shift_r <= {A2X_PP_NUM_BYTES{1'b1}};
    end else begin 
      if (r_valid) begin
        if (ws_fixed && (!r_fifo_push_n))
          shift_r <= init_dec[A2X_PP_NUM_BYTES-1:0]; 
        else if (shift_msb)
          shift_r <= msb_dec[A2X_PP_NUM_BYTES-1:0]; 
        else if (load_r)
          shift_r <= init_dec[A2X_PP_NUM_BYTES-1:0]  << (1 << sp_size); 
        else 
          shift_r <= shift << (1 << sp_size);
      end
    end
  end

  // The load register is used to select the initial decode value. 
  assign shift_w   = (load_r)? init_dec[A2X_PP_NUM_BYTES-1:0] : shift_r; 

  // If Transaction is not to be resized always enable Byte Packer.
  // Hence the Bype Packer will always drive the output directly from the
  // input and the byte clear bit will be high. 
  assign shift     = (resize)? shift_w : {A2X_PP_NUM_BYTES{1'b1}};

  //********************************************************* 
  // Packing 
  //********************************************************* 
  assign shift_lsb    = shift[0];
  assign shift_msb    = shift[A2X_PP_NUM_BYTES-1];

  // Fannout of Read Data to PP Data Width 
  assign rdata_w = {A2X_RS_RATIO{rdata_i}};

  // Byte Control Instantiation
  // - Used to store the Read Data Bytes from the SP until thew packer is
  //   ready to generate a push into the FIFO.
  generate
    genvar i;
    for (i = 0; i <A2X_PP_NUM_BYTES; i = i + 1) begin : pk_byte
      
      i_axi_a2x_1_DW_axi_a2x_r_pk_byte
      
      U_pk_byte (
         .clk               (clk)
        ,.resetn            (resetn)
        ,.rid_valid         (rid_valid)
        ,.rvalid            (rvalid_i)
        ,.rready            (rready_i)
        ,.byte_clr          (~r_fifo_push_n)
        ,.byte_en           (shift[i])
        ,.rdata_i           (rdata_w[(i*8)+7:(i*8)])
        ,.rdata_o           (rdata_pk[(i*8)+7:(i*8)])
      );
    end
  endgenerate

  //**********************************************************************
  // Read Response Error 
  //
  // DECERR Gets priorty over SLVERR
  //**********************************************************************
  always @(posedge clk or negedge resetn) begin: rresp_PROC
    if (resetn==1'b0) begin
      rresp_r <= {`i_axi_a2x_1_A2X_RRESPW{1'b0}};
    end else begin
      if (r_fifo_push_n==1'b0)
        rresp_r <= {`i_axi_a2x_1_A2X_RRESPW{1'b0}};
      else if (rresp_i[1] && rvalid_i)
        rresp_r <= rresp_i | rresp_r;
    end
  end

  assign rresp_w = rresp_r | rresp_i;

  //**********************************************************************
  // Decode Read Data FIFO Push for resized transactions
  // Example PP DW of 64 and SP DW of 16
  // PP Size of 3 (Full sized) Pop after 4 data beats or shift[7] high.
  // PP Size of 2 (32 bits)    Pop after 2 data beats or shift[7] or shift [3] high.
  // PP Size of 1 (16 bits)    Pop after every data beats or shift[7], shift[5], shift[3] or shift [1] high
  // PP Size of 0 (8 bits)     Pop after every data beats or any bit in shift[7:0] high
  //**********************************************************************
  // spyglass disable_block W164b
  // SMD: Identifies assignments in which the LHS width is greater than the RHS width
  // SJ : This is not a functional issue, this is as per the requirement.
  wire [127:0] shift_push = (A2X_PP_NUM_BYTES==128)? shift : { {(128-A2X_PP_NUM_BYTES){1'b0}}, shift[A2X_PP_NUM_BYTES-1:0]};
  // spyglass enable_block W164b

  //spyglass disable_block W415a
  //SMD: Signal may be multiply assigned (beside initialization) in the same scope.
  //SJ : This is initialized before assignment to avoid latches.
  always @(*) begin: fifo_push_PROC
    integer x;
    r_fifo_push = 1'b0;
    case (pp_size_1hot)
      8'b00000010:  begin
        // DW=16 Pop When bits [1], [3], [5], etc high 
        for (x=1; x<128 ; x=x+2) begin
          r_fifo_push = r_fifo_push | shift_push[x];
        end
      end
      8'b00000100: begin
        // DW=32 Pop When bits [3], [7], [11], etc high 
        for (x=3; x<128 ; x=x+4) begin
          r_fifo_push = r_fifo_push | shift_push[x];
        end
      end
      8'b00001000: begin
        // DW=64 Pop When bits [7], [15], etc high 
        for (x=7; x<128 ; x=x+8) begin
          r_fifo_push = r_fifo_push | shift_push[x];
        end
      end
      8'b00010000: begin
        // DW=128 Pop When bits [7], [15], etc high 
        for (x=15; x<128 ; x=x+16) begin
          r_fifo_push = r_fifo_push | shift_push[x];
        end
      end
      8'b00100000: begin
        // DW=256 Pop When bits [7], [15], etc high 
        for (x=31; x<128 ; x=x+32) begin
          r_fifo_push = r_fifo_push | shift_push[x];
        end
      end
      8'b01000000: begin
        // DW=512 Pop When bits [7], [15], etc high 
        for (x=63; x<128 ; x=x+64) begin
          r_fifo_push = r_fifo_push | shift_push[x];
        end
      end
      8'b10000000: begin
        // DW=1024 Pop When bits [7], [15], etc high 
        r_fifo_push = shift_push[127];
      end
      default: begin
        // Pop on every cycle i.e. if any bit high
        r_fifo_push = |shift_push;  
      end
    endcase
  end
  //spyglass enable_block W415a

  // Read Data FIFO Push Control 
  // Generate a push to read data fifo if rlast or r_fifo_push asserted.
  assign r_fifo_push_n = !((r_fifo_push | rlast_pp ) & (rvalid_i & rready_i & rid_valid));

  // Read Data FIFO payload
  assign rlast_pp        = arlast & rlast_i;
  assign r_pyld_o_w      = {rsideband_i, rid_i, rresp_w, rdata_pk, rlast_pp};
  assign r_pyld_o        = (r_fifo_push_n==1'b0) ? r_pyld_o_w : {A2X_PP_PYLD_W{1'b0}};

endmodule
