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
// Revision: $Id: //dwh/DW_ocb/DW_axi_a2x/axi_dev_br/src/DW_axi_a2x_r_upk.v#3 $ 
// --------------------------------------------------------------------
*/

`include "DW_axi_a2x_all_includes.vh"
// **************************************************************************************
// Read Data Unpacker
//
// This block resides on the primary Port side of the read data FIFO and determines the number of 
// valid PP transfers within the Secondary Port Transfer. The unpacker uses the read data tag bits to 
// determine which SP data bytes to transfer to the Primary Port. The unpacker
// also determines when to pop the data from the read data fifo based on the
// tag bits. 
//
// When upsizing from a 16 bit PP to a 64 SP the read data FIFO would contain
// 4 tag bits with each bit indication which Primary Port Transfer is valid.
// 1 -> [15:8]  Valid            - pop after 1 PP Transfer
// 2 -> [31:16] Valid            - pop after 1 PP Transfers
// 3 -> [15:8] & [31:16] Valid   - pop after 2 PP transfers
// 6 -> [31:16] & [47:32] Valid  - pop after 2 PP transfers
// f -> all PP Transfer Valid    - pop after 4 PP Transfers 
// **************************************************************************************
module i_axi_a2x_DW_axi_a2x_r_upk (/*AUTOARG*/
   // Outputs
   r_pyld_o, r_fifo_pop_n, 
   // Inputs
   clk, resetn, rready_i, rvalid_i, r_fifo_empty, r_pyld_i, flush
   );

  //*********************************************************
  // Parameter Decelaration
  //*********************************************************
  parameter   A2X_PP_PYLD_W         = 64; 
  parameter   A2X_R_FIFO_PYLD_W     = 32; 

  parameter   A2X_RSBW              = 1; 
  parameter   A2X_SP_DW             = 64;
  parameter   A2X_PP_DW             = 32;
  parameter   A2X_RS_RATIO          = 2; 

  //*********************************************************
  // I/O Decelaration
  //********************************************************* 
  input                                  clk;
  input                                  resetn;
   
  input                                  rready_i;    
  input                                  rvalid_i;  

  input                                  flush; 
  
  input                                  r_fifo_empty;
  input  [A2X_R_FIFO_PYLD_W-1:0]         r_pyld_i;
  output [A2X_PP_PYLD_W-1:0]             r_pyld_o;
  output                                 r_fifo_pop_n;

  //********************************************************* 
  // Signal Decelaration
  //********************************************************* 
  wire                                   rlast_i;   
  wire   [`i_axi_a2x_A2X_IDW-1:0]                  rid_i;    
  wire   [A2X_SP_DW-1:0]                 rdata_i; 
  wire   [`i_axi_a2x_A2X_RRESPW-1:0]               rresp_i; 
  wire   [A2X_RSBW-1:0]                  rsideband_i;

  wire   [A2X_RS_RATIO-1:0]              r_upk_tag;

  reg    [A2X_RS_RATIO-1:0]              init_val;
  reg    [A2X_RS_RATIO-1:0]              last_val;
  reg    [A2X_RS_RATIO-1:0]              shift_r;
  reg    [A2X_RS_RATIO-1:0]              shift;
  reg                                    load_r;

  wire   [A2X_PP_DW-1:0]                 rdata_upk; 
  wire                                   rlast_upk;

  reg                                    r_fifo_pop_n;

  //********************************************************* 
  // Unpacking Architecture
  //********************************************************* 
  // read Data Payload
  assign {r_upk_tag, rsideband_i, rresp_i, rid_i, rdata_i, rlast_i}  = r_pyld_i;

  //********************************************************* 
  // Decode Initial Load Value 
  //
  // - Priorty Decoded to determine the first valid data Transfer
  //   from the FIFO Tag bits
  //********************************************************* 
  always @(*) begin: init_val_PROC
    integer i; 
    init_val = {{(A2X_RS_RATIO-1){1'b0}}, 1'b1}; 
    for (i=A2X_RS_RATIO-1; i>=0; i=i-1) begin
      if (r_upk_tag[i])
        //Signed and unsigned operands should not be used in same operation.
        //Unrecommended blocking assignment (converting integer to unsigned).
        //i can only be an integer, since it is a loop index. It is a design requirement to
        //     use i in the following operation and it will not have any adverse effects on the 
        //     design. So signed and unsigned operands are used to reduce the logic.
        // spyglass disable_block W486
        // SMD: Reports shift overflow operations
        // SJ : This is not a functional issue, this is as per the requirement.
        //      Hence this can be waived.  
        // spyglass disable_block W164a
        // SMD: Identifies assignments in which the LHS width is less than the RHS width
        // SJ : The length of the net varies based on configuration. This will not cause functional issue.
        //      Hence this can be waived. 
        // spyglass disable_block W415a
        // SMD: Signal may be multiply assigned (beside initialization) in the same scope.
        // SJ : Here we are trying to decode the initial load value to determine the first valid data Transfer from the FIFO Tag bits
        init_val = 1 << i; 
        // spyglass enable_block W415a
        // spyglass enable_block W164a
        // spyglass enable_block W486
    end
  end

  //********************************************************* 
  // Decode Last Initial Load Value 
  //
  // - Priorty Decoded to determine the lasat valid data Transfer
  //   from the FIFO Tag bits
  //********************************************************* 
  always @(*) begin: last_val_PROC
    integer i; 
    last_val = {1'b1, {(A2X_RS_RATIO-1){1'b0}}}; 
    for (i=0; i<A2X_RS_RATIO; i=i+1) begin
      if (r_upk_tag[i])
        // spyglass disable_block W486
        // SMD: Reports shift overflow operations
        // SJ : This is not a functional issue, this is as per the requirement.
        //      Hence this can be waived.  
        // spyglass disable_block W164a
        // SMD: Identifies assignments in which the LHS width is less than the RHS width
        // SJ : The length of the net varies based on configuration. This will not cause functional issue.
        //      Hence this can be waived.
        // spyglass disable_block W415a
        // SMD: Signal may be multiply assigned (beside initialization) in the same scope.
        // SJ : Here we are trying to decode the initial load value to determine the last valid data Transfer from the FIFO Tag bits
        last_val = 1 << i; 
        // spyglass enable_block W415a
        // spyglass enable_block W164a
        // spyglass enable_block W486
    end
  end
 
  //********************************************************* 
  // Shift Register Load Value
  //
  // Asserted high to indicate a new shift value.
  //********************************************************* 
  always @(posedge clk or negedge resetn) begin: load_PROC
    if (resetn == 1'b0) begin
      load_r <= 1'b1;
    end else begin
      if (r_fifo_empty || (!r_fifo_pop_n))
        load_r <= 1'b1; 
      else if (rready_i) 
        load_r <= 1'b0;
    end
  end

  //********************************************************* 
  // Data Beat Shift
  //
  // Single Bit shift register to select the valid PP Data Bytes from the Read
  // Data FIFO (SP)
  //********************************************************* 
  always @(*) begin: shift_PROC
    shift = {{(A2X_RS_RATIO-1){1'b0}}, 1'b1};
    if (load_r) 
      shift = init_val; 
    else 
      shift = shift_r;
  end

  // Registered Version
  // Inferred a shift register
  // A Shift Register is required here to unpack all the read data from the
  // FIFO Data Bus
  // spyglass disable_block W486
  // SMD: Reports shift overflow operations
  // SJ : This is not a functional issue, this is as per the requirement.
  //      Hence this can be waived.  
  always @(posedge clk or negedge resetn) begin: cnt_r_PROC
    if (resetn == 1'b0) begin
      shift_r <= {A2X_RS_RATIO{1'b0}};
    end else begin
      if (rready_i && rvalid_i) begin
        if (load_r)
          shift_r <= init_val << 1; 
        else 
          shift_r <= shift_r << 1;
      end
    end
  end
  // spyglass enable_block W486

  //**********************************************************************
  // Bus Multiplexer's 
  //
  // - One Hot Decode Multiplexer. 
  //**********************************************************************
  // Data Mux One-Hot Decode
   i_axi_a2x_DW_axi_a2x_busmux_ohsel
    #(
     .BUS_COUNT                   (A2X_RS_RATIO),
     .MUX_WIDTH                   (A2X_PP_DW)
   ) a2x_r_upk_ohsel (
     .sel                         (shift),
     .din                         (rdata_i),
     .dout                        (rdata_upk)
   );


  //**********************************************************************
  //Decode Read Data FIFO Pop
  //
  // Need to generate Pop when last tag bit detected high.
  // Upsizing from a 32 to 64 with a subsized transfer of 16 bits. Tag value
  // of 01, 01, 10, 10,
  //**********************************************************************
  always @(*) begin : r_fifo_pop_PROC
    r_fifo_pop_n = ~(rvalid_i & (flush | (rready_i & (shift==last_val))));
  end

  // Rlast only sent with last data beat
  assign rlast_upk = (flush | (shift==last_val)) & rlast_i;
  
  // Read Data Payload
  assign r_pyld_o = {rsideband_i, rresp_i, rid_i, rdata_upk, rlast_upk};
endmodule
