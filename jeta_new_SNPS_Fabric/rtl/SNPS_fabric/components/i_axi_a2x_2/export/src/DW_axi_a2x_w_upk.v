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
// Revision: $Id: //dwh/DW_ocb/DW_axi_a2x/axi_dev_br/src/DW_axi_a2x_w_upk.v#7 $ 
// --------------------------------------------------------------------
*/

`include "DW_axi_a2x_all_includes.vh"
// **************************************************************************************
// Write Data Unpacker
//
// This block resides on the secondary Port side of the write data FIFO and determines the number of 
// valid PP transfers within the Secondary Port Transfer. The unpacker uses the resize FIFO (SPC FIFO) 
// to determine which PP data bytes to transfer to the Secondary Port. The unpacker
// also determines when to pop the data from the write data fifo based on the
// resize information.
//
// When Downsizing from a 64 bit PP to a 16 SP the write data unpacker uses a shift reqister along with 
// the SP aligned address bits and the Primary Port size to select the appropiate data bytes from the 
// write data fifo. 
// **************************************************************************************
module i_axi_a2x_2_DW_axi_a2x_w_upk (/*AUTOARG*/
   // Outputs
   w_pyld_o, w_fifo_pop_n, sp_size,
   // Inputs
   clk, resetn, spc_pop_n_i, w_pyld_i, rs_pyld_i, spc_strobe,
   rs_fifo_empty, wready_sp, wvalid_sp, wlast_sp, aw_last
   );

  //*********************************************************
  // Parameter Decelaration
  //*********************************************************
  parameter   A2X_PP_MODE           = 0; 
  parameter   A2X_PP_PYLD_W         = 64; 
  parameter   A2X_SP_PYLD_W         = 64; 
  parameter   A2X_RS_PYLD_W         = 32; 

  parameter   A2X_PP_DW             = 32;
  parameter   A2X_PP_WSTRB_DW       = 4;
  parameter   A2X_PP_MAX_SIZE       = 2;
  parameter   A2X_PP_NUM_BYTES      = 4;
  parameter   A2X_PP_NUM_BYTES_LOG2 = 2;
  parameter   A2X_SP_DW             = 32;
  parameter   A2X_SP_WSTRB_DW       = 4;
  parameter   A2X_SP_MAX_SIZE       = 2;
  parameter   A2X_RS_RATIO          = 1;
  parameter   A2X_SP_NUM_BYTES      = 4;
  parameter   A2X_SP_NUM_BYTES_LOG2 = 2;

  localparam  PP_D_W                = A2X_PP_DW + A2X_PP_WSTRB_DW + 1;

  // Can't have a signal decelaration of A2X_SP_NUM_BYTES_LOG2-1:0 when (A2X_SP_NUM_BYTES_LOG2==0
  localparam  SP_NUM_BYTES_LOG2     = (A2X_SP_NUM_BYTES_LOG2==0)? 1 : A2X_SP_NUM_BYTES_LOG2;
  localparam  PP_NUM_BYTES_LOG2     = (A2X_PP_NUM_BYTES_LOG2==0)? 1 : A2X_PP_NUM_BYTES_LOG2;

  //*********************************************************
  // I/O Decelaration
  //********************************************************* 
  input                                  clk;
  input                                  resetn;
   
  input                                  wready_sp;    
  input                                  wvalid_sp;    
  input                                  wlast_sp;    
  
  input  [A2X_PP_PYLD_W-1:0]             w_pyld_i;
  output [A2X_SP_PYLD_W-1:0]             w_pyld_o;
  output                                 w_fifo_pop_n;

  input                                  spc_pop_n_i;
  //spyglass disable_block W240
  //SMD: An input has been declared but is not read.
  //SJ : This input is read only in selected config 
  input                                  spc_strobe; 
  //spyglass enable_block W240
  input                                  aw_last;
  input  [A2X_RS_PYLD_W-1:0]             rs_pyld_i;
  input                                  rs_fifo_empty;

  output [`i_axi_a2x_2_A2X_BSW-1:0]                  sp_size;     

  //********************************************************* 
  // Signal Decelaration
  //********************************************************* 
  wire   [A2X_PP_DW-1:0]                 wdata_i; 
  wire   [A2X_PP_WSTRB_DW-1:0]           wstrb_i;
  wire                                   wlast_i;   
  wire   [A2X_SP_DW-1:0]                 wdata_upk; 
  wire   [A2X_SP_WSTRB_DW-1:0]           wstrb_upk;
  wire                                   wlast_upk;

  wire   [PP_NUM_BYTES_LOG2-1:0]         addr_i;
  wire   [`i_axi_a2x_2_A2X_BSW-1:0]                  pp_size;
  wire                                   resize;
  wire                                   ws_last;
  wire                                   ws_fixed;

  wire   [PP_NUM_BYTES_LOG2-1:0]         align_addr;

  reg                                    load_r;
  reg    [A2X_PP_NUM_BYTES-1:0]          shift_r;
  wire   [A2X_PP_NUM_BYTES-1:0]          shift;

  reg                                    w_fifo_pop;
  wire                                   w_fifo_pop_n;

  wire                                   spc_strobe_i; 

  //********************************************************* 
  // Resize FIFO Decode
  // 
  // Resize information contains
  // - Primary Port transaction size
  // - Primary Port Transaction aligned address bits i.e. for a 64 bit
  //   PP DW the aligned address contains address bits [2:0] (8 bytes)
  // - Primary Port resize field. Transactions are only resized when this bit
  //   is high. This field is unused for Downsized configs and driven static
  //   value.
  //********************************************************* 
  assign {resize, ws_fixed, pp_size, addr_i, ws_last}   = rs_pyld_i;

  // Write Data Payload
  assign {wstrb_i, wdata_i, wlast_i}  = w_pyld_i[PP_D_W-1:0];

  //Generate aligned Address
  assign align_addr = addr_i & ({A2X_PP_NUM_BYTES_LOG2{1'b1}} << sp_size);

  // Generate SP Size
  assign sp_size    = (pp_size>A2X_SP_MAX_SIZE)? A2X_SP_MAX_SIZE : pp_size; 

  assign spc_strobe_i = (A2X_PP_MODE==0)? spc_strobe : 1'b0; 

  // **************************************************************************************
  // Fannout Size to Maximum
  // **************************************************************************************
  reg  [7:0] pp_size_1hot_r;
  reg  [7:0] pp_size_1hot;
  reg  [7:0] sp_size_1hot_r;
  reg  [7:0] sp_size_1hot;

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
      if (i==pp_size) pp_size_1hot_r[i] = 1'b1;  // lint warning flags here.
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
  // Byte counter Load 
  //
  // Asserted high until the first SP Write Data transaction is accepted. 
  //********************************************************* 
  wire w_last_int = wready_sp & wvalid_sp & wlast_sp;
  always @(posedge clk or negedge resetn) begin: load_PROC
    if (resetn == 1'b0) begin
      load_r <= 1'b1;
    end else begin
      if ((!rs_fifo_empty) && (ws_last || aw_last) && w_last_int && w_fifo_pop && (!spc_pop_n_i)) 
        load_r <= 1'b1; 
      else if (!spc_pop_n_i) 
        load_r <= 1'b0;
    end
  end

  //********************************************************* 
  // Shift Register
  //
  // When shift register MSB is detected reset shift register.
  // - When load value asserted set the shift register to initial value
  //   shifted by transfer size.
  // - otherwise shift by the transfer size.
  //********************************************************* 
  always @(posedge clk or negedge resetn) begin: shift_PROC
    if (resetn == 1'b0) begin
      shift_r <= {A2X_PP_NUM_BYTES{1'b1}};
    end else begin 
      if ((!spc_pop_n_i) && (!spc_strobe_i)) begin
        if (ws_fixed && (!w_fifo_pop_n)) 
          shift_r <= init_dec[A2X_PP_NUM_BYTES-1:0];
        else if (shift[A2X_PP_NUM_BYTES-1])
          shift_r <= msb_dec[A2X_PP_NUM_BYTES-1:0];
        else if (load_r)
          shift_r <= init_dec[A2X_PP_NUM_BYTES-1:0] << (1 << sp_size);
        else
          shift_r <= shift_r << (1 << sp_size);
      end
    end
  end

  // The load register is used to select the initial decode value.   
  assign shift = (load_r)? init_dec[A2X_PP_NUM_BYTES-1:0] : shift_r; 

  //**********************************************************************
  // One Hot Multiplexer select Decode
  //
  // The shift register contains a status bit for each byte with the Primary
  // Port Data bus. Dependind on the resize ratio the multiplexer select bits
  // can be decoded from the shift register. 
  //
  // consider a downsizing configuration of PP DW 64 and SP DW 16. This
  // implies a Rssize Ratio of 4. Hence the following bits are selected
  // [15:0]  - shift[0] or shift[1] high
  // [31:16] - shift[2] or shift[3] high
  // [47:32] - shift[4] or shift[5] high
  // [63:48] - shift[6] or shift[7] high
  //**********************************************************************
  reg [A2X_RS_RATIO-1:0]   sel_oh;
  //spyglass disable_block W415a
  //SMD: Signal may be multiply assigned (beside initialization) in the same scope.
  //SJ : This is not an issue. It is initialized before assignment to avoid latches.
  // spyglass disable_block SelfDeterminedExpr-ML
  // SMD: Self determined expression found
  // SJ: The expression indexing the vector/array will never exceed the bound of the vector/array.
  always @(*) begin: sel_oh_PROC
    integer i, x; 
    sel_oh = {A2X_RS_RATIO{1'b0}};
    for (i=0; i<A2X_RS_RATIO; i=i+1) begin
      for (x=0; x<A2X_SP_NUM_BYTES ; x=x+1) begin
        sel_oh[i] = sel_oh[i] | shift[(i*A2X_SP_NUM_BYTES) + x];
      end
    end
  end
  // spyglass enable_block SelfDeterminedExpr-ML
  //spyglass enable_block W415a

  //**********************************************************************
  // Bus Multiplexer's 
  //**********************************************************************
  // Data Mux One-Hot Decode
   i_axi_a2x_2_DW_axi_a2x_busmux_ohsel
    #(
     .BUS_COUNT                   (A2X_RS_RATIO),
     .MUX_WIDTH                   (A2X_SP_DW)
   ) a2x_w_upk_ohsel (
     .sel                         (sel_oh),
     .din                         (wdata_i),
     .dout                        (wdata_upk)
   );

  // Data Strobe Mux One-Hot Decode
   i_axi_a2x_2_DW_axi_a2x_busmux_ohsel
    #(
     .BUS_COUNT                   (A2X_RS_RATIO),
     .MUX_WIDTH                   (A2X_SP_WSTRB_DW)
   ) a2x_ws_upk_ohsel (
     .sel                         (sel_oh),
     .din                         (wstrb_i),
     .dout                        (wstrb_upk)
   );
  //**********************************************************************
  // Write Data FIFO pop.
  //
  // Example PP DW of 64 and SP DW of 16
  // PP Size of 3 (Full sized) Pop after 4 data beats or shift[7] high.
  // PP Size of 2 (32 bits)    Pop after 2 data beats or shift[7] or shift [3] high.
  // PP Size of 1 (16 bits)    Pop after every data beats or shift[7], shift[5], shift[3] or shift [1] high
  // PP Size of 0 (8 bits)     Pop after every data beats or any bit in shift[7:0] high
  //**********************************************************************
  wire [127:0] shift_pop;
  
  generate
    if (A2X_PP_NUM_BYTES==128)
      assign shift_pop = shift ;
    else
      assign shift_pop = { {(128-A2X_PP_NUM_BYTES){1'b0}}, shift[A2X_PP_NUM_BYTES-1:0]};
  endgenerate

  //spyglass disable_block W415a
  //SMD: Signal may be multiply assigned (beside initialization) in the same scope.
  //SJ : This is not an issue. It is initialized before assignment to avoid latches.
  always @(*) begin: fifo_pop_PROC
    integer x;
    w_fifo_pop = 1'b0;
    case (pp_size_1hot)
      8'b00000010:  begin
        // DW=16 Pop When bits [1], [3], [5], etc high 
        for (x=1; x<128 ; x=x+2) begin
          w_fifo_pop = w_fifo_pop | shift_pop[x];
        end
      end
      8'b00000100: begin
        // DW=32 Pop When bits [3], [7], [11], etc high 
        for (x=3; x<128 ; x=x+4) begin
          w_fifo_pop = w_fifo_pop | shift_pop[x];
        end
      end
      8'b00001000: begin
        // DW=64 Pop When bits [7], [15], etc high 
        for (x=7; x<128 ; x=x+8) begin
          w_fifo_pop = w_fifo_pop | shift_pop[x];
        end
      end
      8'b00010000: begin
        // DW=128 Pop When bits [7], [15], etc high 
        for (x=15; x<128 ; x=x+16) begin
          w_fifo_pop = w_fifo_pop | shift_pop[x];
        end
      end
      8'b00100000: begin
        // DW=256 Pop When bits [7], [15], etc high 
        for (x=31; x<128 ; x=x+32) begin
          w_fifo_pop = w_fifo_pop | shift_pop[x];
        end
      end
      8'b01000000: begin
        // DW=512 Pop When bits [7], [15], etc high 
        for (x=63; x<128 ; x=x+64) begin
          w_fifo_pop = w_fifo_pop | shift_pop[x];
        end
      end
      8'b10000000: begin
        // DW=1024 Pop When bits [7], [15], etc high 
        w_fifo_pop = shift_pop[127];
      end
      default: begin
        // Pop on every cycle i.e. if any bit high
        w_fifo_pop = |shift_pop;  
      end
    endcase
  end
  //spyglass enable_block W415a
  
  assign w_fifo_pop_n = (spc_strobe_i)? spc_pop_n_i : !((!spc_pop_n_i) & w_fifo_pop);
  
  // Generate Unpacked Write Last
  assign wlast_upk = w_fifo_pop & wlast_i;

  // Write Data Downsized
  
  assign w_pyld_o = {w_pyld_i[A2X_PP_PYLD_W-1:PP_D_W], wstrb_upk, wdata_upk, wlast_upk};
endmodule
