//////////////////////////////////////////////////////////////////////////////
//
// ------------------------------------------------------------------------------
// 
// Copyright 2001 - 2023 Synopsys, INC.
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
// Component Name   : DW_axi
// Component Version: 4.06a
// Release Type     : GA
// Build ID         : 18.26.9.4
// ------------------------------------------------------------------------------

// 
// Release version :  4.06a
// File Version     :        $Revision: #8 $ 
// Revision: $Id: //dwh/DW_ocb/DW_axi/axi_dev_br/src/DW_axi_fifo_s1_sf.v#8 $ 
//
// Filename    : DW_axi_fifo_s1_sf.v
// Author      : ALS         04/28/04
// Description : DW_axi_fifo_s1_sf.v Verilog module for DW_axi
//
//
//
// DesignWare IP ID: 5bf0f11f
//
////////////////////////////////////////////////////////////////////////////////

`include "DW_axi_all_includes.vh"

//VCS coverage exclude_file

module i_axi_DW_axi_fifo_s1_sf 
    (clk, rst_n, init_n, push_req_n, pop_req_n, diag_n, data_in, empty, 
     nxt_empty, almost_empty, half_full, almost_full, full, error, data_out
    );
  parameter WIDTH      = 8;           // RANGE 1 TO 256
  parameter DEPTH      = 4;           // RANGE 2 TO 256
  parameter AE_LEVEL   = 1;           // RANGE 0 TO 255
  parameter AF_LEVEL   = 1;           // RANGE 0 TO 255
  parameter ERR_MODE   = 0;           // RANGE 0 TO 2
  parameter RST_MODE   = 0;           // RANGE 0 TO 1
  parameter ADDR_WIDTH = 2;           // RANGE 1 TO 8
 
  input                clk;           // clock input
  input                rst_n;         // active low async. reset
  //spyglass disable_block W240
  //SMD: An input has been declared but is not read
  //SJ: Not used when FIFO depth is set to 1 
  input                init_n;        // active low sync. reset (FIFO flush)
  //spyglass enable_block W240
  input                push_req_n;    // active low push request
  input                pop_req_n;     // active low pop request
  //spyglass disable_block W240
  //SMD: An input has been declared but is not read
  //SJ: Not used when FIFO depth is set to 1 
  input                diag_n;        // active low diagnostic input
  //spyglass enable_block W240
  input  [WIDTH-1 : 0] data_in;       // FIFO input data bus
  output               empty;         // empty status flag
  output               nxt_empty;     // Next empty status flag
  output               almost_empty;  // almost empty status flag
  output               half_full;     // half full status flag
  output               almost_full;   // almost full status flag
  output               full;          // full status flag
  output               error;         // error status flag
  output [WIDTH-1 : 0] data_out;      // FIFO outptu data bus


 generate 
 if ( DEPTH > 1) begin : generate_fifo
  wire                    ram_async_rst_n;
  wire [ADDR_WIDTH-1 : 0] ram_rd_addr, ram_wr_addr;
  wire           [31 : 0] ae_level_i;
  wire           [31 : 0] af_thresh_i; 
  wire                    ram_we_n;
  wire                    nxt_empty_n;
 
  // Wires for unconnected sub module outputs.
  wire [ADDR_WIDTH-1:0] wrd_count_unconn;
  wire nxt_full_unconn;
  wire nxt_error_unconn;

  assign ae_level_i  = AE_LEVEL;
  assign af_thresh_i = DEPTH - AF_LEVEL; 

  assign ram_async_rst_n = (RST_MODE == 0) ? rst_n : 1'b1;
 
  //spyglass disable_block W528
  //SMD: A signal or variable is set but never read  
  //SJ: This warning can be ignored. 
  i_axi_DW_axi_bcm06
   #(DEPTH, ERR_MODE, ADDR_WIDTH) U_FIFO_CTL(
      .clk(clk),
      .rst_n(rst_n),
      .init_n(init_n),
      .push_req_n(push_req_n),
      .pop_req_n(pop_req_n),
      .ae_level(ae_level_i[ADDR_WIDTH-1:0]),
      .af_thresh(af_thresh_i[ADDR_WIDTH-1:0]),
      .diag_n(diag_n),
      .empty(empty),
      .almost_empty(almost_empty),
      .half_full(half_full),
      .almost_full(almost_full),
      .full(full),
      .error(error),
      .we_n(ram_we_n),
      .wr_addr(ram_wr_addr),
      .rd_addr(ram_rd_addr),
      .wrd_count(wrd_count_unconn),
      .nxt_empty_n(nxt_empty_n),
      .nxt_full(nxt_full_unconn),
      .nxt_error(nxt_error_unconn)
      );
 
  //spyglass enable_block W528
  i_axi_DW_axi_bcm57
   #(WIDTH, DEPTH, 0, ADDR_WIDTH) U_FIFO_MEM( 
      .clk(clk),
      .rst_n(ram_async_rst_n),
      .wr_n(ram_we_n),
      .rd_addr(ram_rd_addr),
      .wr_addr(ram_wr_addr),
      .data_in(data_in),
      .data_out(data_out)
      );

  assign nxt_empty = !nxt_empty_n;     
 end else begin : generate_no_fifo
  reg [WIDTH-1 : 0] data_reg;
  reg               empty_stat_reg;


  always @(posedge clk or negedge rst_n)
  begin : data_reg_PROC  
    if(!rst_n) begin
      data_reg  <= {WIDTH{1'b0}};
    end else if (push_req_n == 1'b0 & (empty_stat_reg == 1'b1 || pop_req_n == 1'b0))begin 
      data_reg  <= data_in;
    end
  end

  always @(posedge clk or negedge rst_n)
  begin : empty_stat_reg_PROC  
    if(!rst_n) begin
      empty_stat_reg  <= 1'b1;
    end else if (push_req_n == 1'b0 && pop_req_n == 1'b1)begin 
      empty_stat_reg  <= 1'b0;
    end else if (pop_req_n == 1'b0) begin   
      empty_stat_reg  <= 1'b1;
    end
  end

  assign empty        =  empty_stat_reg;
  assign nxt_empty    =  (push_req_n & (empty_stat_reg || pop_req_n == 1'b0)); 
  assign data_out     =  data_reg;

  //Unconnected outputs
  assign almost_empty = 1'b0;
  assign half_full    = 1'b0;
  assign almost_full  = 1'b0;
  assign full         = ~empty_stat_reg;
  assign error        = 1'b0;

 end 
 endgenerate 
  
endmodule
