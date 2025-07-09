
/******************************************************************************
  Copyright (C) 2020-2021 Synopsys, Inc.
  This IP and the associated documentation are confidential and
  proprietary to Synopsys, Inc. Your use or disclosure of this IP is 
  subject to the terms and conditions of a written license agreement 
  between you, or your company, and Synopsys, Inc.
*******************************************************************************
  Title      : UMR3 VIRTUAL UART TX module
  project    : Anaconda
  Description: This module is transmitter of virtual uart used in umr bus for 
               HAPS 100
*******************************************************************************
 Date          Version        Author          Modification
 17Jun2021      1.00         fakhrudd       Initial(in verilog file)
 05May2022      1.01         chitra         Porting into sv file, usage of
                                            interface and including the package
                                            files and Documentation
 ******************************************************************************/
 
module umr3_virtual_uart_tx 
  (
   
   input wire        umr3_clk, 
   input wire        umr3_reset,
   
   input             baud_clk,
   input wire [63:0] capi_dout,
   input wire        capi_dout_valid,
   output wire       tx_ready,
   input wire        uart_rts_n,
   input wire [7:0]  uart_line_ctrl_reg, 
   output reg        uart_tx_serial,
   output wire       uart_tx_done,
   output wire [1:0] uart_line_stat_reg_tx,
   input wire        flow_ctrl,
   input wire        reset_errors
   );

   // state control
   localparam CTRL_STATE_WIDTH = 3;
   // TODO : use enum for fsm state
   localparam [CTRL_STATE_WIDTH-1:0] 
     IDLE = 'd1,
     FIFO_READ = 'd2,
     START = 'd3,
     DATA = 'd4,
     PARITY = 'd5,
     STOP1 = 'd6,
     STOP2 = 'd7;
   reg [CTRL_STATE_WIDTH-1:0] ctrl_state;

   logic [31:0]               clk_cnt;
   logic [2:0]                bit_index;
   logic [7:0]                tx_data;
   logic                      tx_serial;
   logic                      tx_done;
   logic                      tx_active;
   logic                      calc_parity;
   
   // FIFO
   localparam    FIFO_DEPTH =1024;
   logic                      fifo_full_tx;
   logic                      fifo_write_tx;
   logic                      fifo_empty_tx;
   logic                      fifo_read_tx;
   logic [7:0]                fifo_data_out_tx;
   logic                      wr_rst_busy_tx;
   
   assign fifo_write_tx = ( (!fifo_full_tx) && (!wr_rst_busy_tx) && (~(|capi_dout[63:60])))?capi_dout_valid:1'b0;
   assign tx_ready = ((!fifo_full_tx) && (!wr_rst_busy_tx));

   //Line status registers
   assign uart_line_stat_reg_tx[0] = (reset_errors)?1'b0:fifo_empty_tx; // THRE
   assign uart_line_stat_reg_tx[1] = (reset_errors)?1'b0:fifo_empty_tx; // TEMT

   /* --------------------------------------------------------------------------------
	  UART TX FIFO Instantiation
    ------------------------------------------------------------------------------- */   
   
   // xpm_fifo_async: Asynchronous FIFO
   // Xilinx Parameterized Macro, version 2018.2
   // TODO : change xlnx async fifo to SNPS async fifo
   xpm_fifo_async 
     #(
       .CDC_SYNC_STAGES(4), // DECIMAL
       .DOUT_RESET_VALUE("0"), // String
       .ECC_MODE("no_ecc"), // String
       .FIFO_MEMORY_TYPE("auto"), // String
       .FIFO_READ_LATENCY(0), // DECIMAL
       .FIFO_WRITE_DEPTH(FIFO_DEPTH), // DECIMAL
       .FULL_RESET_VALUE(0), // DECIMAL
       .PROG_EMPTY_THRESH(10), // DECIMAL
       .PROG_FULL_THRESH(10), // DECIMAL
       .RD_DATA_COUNT_WIDTH(10), // DECIMAL
       .READ_DATA_WIDTH     (8), // DECIMAL          
       .READ_MODE("fwft"), // String
       .RELATED_CLOCKS(0), // DECIMAL
       .USE_ADV_FEATURES("1000"), // String
       .WAKEUP_TIME(0), // DECIMAL
       .WRITE_DATA_WIDTH(8), // DECIMAL
       .WR_DATA_COUNT_WIDTH(10) // DECIMAL
       )
   xpm_fifo_async_tx_inst 
     (
      .almost_empty(), // spyglass disable W287b // 1-bit output: Almost Empty : When asserted, this signal indicates that
      // only one more read can be performed before the FIFO goes to empty.
      .almost_full(), // spyglass disable W287b // 1-bit output: Almost Full: When asserted, this signal indicates that
      // only one more write can be performed before the FIFO is full.
      .data_valid(), // spyglass disable W287b // 1-bit output: Read Data Valid: When asserted, this signal indicates
      // that valid data is available on the output bus (dout).
      .dbiterr(), // spyglass disable W287b // 1-bit output: Double Bit Error: Indicates that the ECC decoder detected
      // a double-bit error and data in the FIFO core is corrupted.
      .dout(fifo_data_out_tx), // spyglass disable W528 // READ_DATA_WIDTH-bit output: Read Data: The output data bus is driven                          
      // when reading the FIFO.
      .empty(fifo_empty_tx), // 1-bit output: Empty Flag: When asserted, this signal indicates that the
      // FIFO is empty. Read requests are ignored when the FIFO is empty,
      // initiating a read while empty is not destructive to the FIFO.
      .full(fifo_full_tx), // 1-bit output: Full Flag: When asserted, this signal indicates that the
      // FIFO is full. Write requests are ignored when the FIFO is full,
      // initiating a write when the FIFO is full is not destructive to the
      // contents of the FIFO.
      .overflow(), // spyglass disable W287b // 1-bit output: Overflow: This signal indicates that a write request
      // (wren) during the prior clock cycle was rejected, because the FIFO is
      // full. Overflowing the FIFO is not destructive to the contents of the
      // FIFO.
      .prog_empty(),// spyglass disable W287b  // 1-bit output: Programmable Empty: This signal is asserted when the
      // number of words in the FIFO is less than or equal to the programmable
      // empty threshold value. It is de-asserted when the number of words in
      // the FIFO exceeds the programmable empty threshold value.
      .prog_full(), // spyglass disable W287b // 1-bit output: Programmable Full: This signal is asserted when the
      // number of words in the FIFO is greater than or equal to the
      // programmable full threshold value. It is de-asserted when the number of
      // words in the FIFO is less than the programmable full threshold value.
      .rd_data_count(), // spyglass disable W287b // RD_DATA_COUNT_WIDTH-bit output: Read Data Count: This bus indicates the
      // number of words read from the FIFO.
      .rd_rst_busy(), // 1-bit output: Read Reset Busy: Active-High indicator that the FIFO read
      // domain is currently in a reset state.
      .sbiterr(), // spyglass disable W287b // 1-bit output: Single Bit Error: Indicates that the ECC decoder detected
      // and fixed a single-bit error.
      .underflow(), // spyglass disable W287b // 1-bit output: Underflow: Indicates that the read request (rd_en) during
      // the previous clock cycle was rejected because the FIFO is empty. Under
      // flowing the FIFO is not destructive to the FIFO.
      .wr_ack(), // spyglass disable W287b // 1-bit output: Write Acknowledge: This signal indicates that a write
      // request (wr_en) during the prior clock cycle is succeeded.
      .wr_data_count(), // spyglass disable W287b // WR_DATA_COUNT_WIDTH-bit output: Write Data Count: This bus indicates
      // the number of words written into the FIFO.
      .wr_rst_busy(wr_rst_busy_tx), // 1-bit output: Write Reset Busy: Active-High indicator that the FIFO
      // write domain is currently in a reset state.
      .din(capi_dout[7:0]),      
      // writing the FIFO.
      .injectdbiterr(1'b0), // 1-bit input: Double Bit Error Injection: Injects a double bit error if
      // the ECC feature is used on block RAMs or UltraRAM macros.
      .injectsbiterr(1'b0), // 1-bit input: Single Bit Error Injection: Injects a single bit error if
      // the ECC feature is used on block RAMs or UltraRAM macros.
      .rd_clk(baud_clk), // 1-bit input: Read clock: Used for read operation. rd_clk must be a free
      // running clock.
      .rd_en(fifo_read_tx), // 1-bit input: Read Enable: If the FIFO is not empty, asserting this
      // signal causes data (on dout) to be read from the FIFO. Must be held
      // active-low when rd_rst_busy is active high. .
      .rst(umr3_reset), // 1-bit input: Reset: Must be synchronous to wr_clk. Must be applied only
      // when wr_clk is stable and free-running.
      .sleep(1'b0), // 1-bit input: Dynamic power saving: If sleep is High, the memory/fifo
      // block is in power saving mode.
      .wr_clk(umr3_clk), // 1-bit input: Write clock: Used for write operation. wr_clk must be a
      // free running clock.
      .wr_en(fifo_write_tx) // 1-bit input: Write Enable: If the FIFO is not full, asserting this
      // signal causes data (on din) to be written to the FIFO. Must be held
      // active-low when rst or wr_rst_busy is active high. .
      );

   // state control
    always @(posedge baud_clk or posedge umr3_reset) begin
      if (umr3_reset == 1'b1) begin
         ctrl_state       <= IDLE;
         tx_serial <= 1'b1;
         tx_data   <= 8'h00;
         tx_done <= 1'b0;
         clk_cnt <= 32'h00000000;
         bit_index <= 3'h0;
         calc_parity <= 1'b0;
         tx_done <= 1'b0;
         tx_active <= 1'b0;
         fifo_read_tx     <= 1'b0;
      end else begin
         case (ctrl_state) 

           IDLE : begin

              tx_serial <= 1'b1;
              tx_done <= 1'b0;
              clk_cnt <= 32'h00000000;
              bit_index <= 3'h0;
              if (!flow_ctrl) begin
                  if (!fifo_empty_tx) begin
                     ctrl_state       <= FIFO_READ;
                   end
                   else
                    ctrl_state       <= IDLE;
              end
              else begin
                    if ( (!fifo_empty_tx) &&  (!uart_rts_n) ) begin
                     ctrl_state       <= FIFO_READ;
                   end
                   else
                    ctrl_state       <= IDLE;
              end 
           end 

            FIFO_READ : begin
                tx_serial <= 1'b1;
              if (!fifo_empty_tx) begin
                 fifo_read_tx     <= 1'b1;
                 ctrl_state       <= START;
                 tx_data          <= fifo_data_out_tx;
                 tx_active        <= 1'b1;
                 calc_parity      <= ^fifo_data_out_tx; // calculate parity
              end
              else
                ctrl_state       <= FIFO_READ;
           end

           START : begin
                fifo_read_tx     <= 1'b0;
                tx_serial <= 1'b0; // send start bit
              if (clk_cnt < 15) begin
                    ctrl_state       <= START;
                    clk_cnt          <= clk_cnt + 1;
              end 
              else begin
                    ctrl_state       <= DATA;
                    clk_cnt <= 32'h00000000;
              end
           end

           DATA : begin
               tx_serial <= tx_data[bit_index]; // send data
             
              if (clk_cnt < 15) begin
                    ctrl_state       <= DATA;
                    clk_cnt          <= clk_cnt + 1;
              end 
              else begin
                    clk_cnt <= 32'h00000000;
                    if (bit_index < 7) begin
                       bit_index    <= bit_index + 1;
                       ctrl_state   <= DATA;
                    end
                    else begin
                       bit_index     <= 3'h0;
                        if (uart_line_ctrl_reg[`UMR3_VIRTUAL_UART_LCR_PEN])
                          ctrl_state   <= PARITY;
                        else
                          begin
                              if (uart_line_ctrl_reg[`UMR3_VIRTUAL_UART_LCR_STB]) 
                                  ctrl_state       <= STOP1;
                              else 
                                  ctrl_state       <= STOP2;   
                            end   
                    end
              end

           end

           PARITY : begin
                   case ({uart_line_ctrl_reg[`UMR3_VIRTUAL_UART_LCR_EPS],uart_line_ctrl_reg[`UMR3_VIRTUAL_UART_LCR_SP]})
						2'b00:	tx_serial <=  (calc_parity)?1'b0:1'b1; // odd Parity
						2'b01:	tx_serial <=  1'b1;  // Stick parity enable
						2'b10:	tx_serial <= (calc_parity)?1'b1:1'b0; // Even Parity
						2'b11:	tx_serial <=  1'b0;  // Stick Parity disable
				  	endcase

               if (clk_cnt < 15) begin         
                    ctrl_state       <= PARITY;
                    clk_cnt          <= clk_cnt + 1;
              end 
              else begin
                 
                  clk_cnt <= 32'h00000000;
                  if (uart_line_ctrl_reg[`UMR3_VIRTUAL_UART_LCR_STB]) 
                    ctrl_state       <= STOP1;
                  else 
                    ctrl_state       <= STOP2;                
                    
              end
           end


            STOP1 : begin
                tx_serial <= 1'b1; // send stop1 bit
              if (clk_cnt < 15) begin
                    ctrl_state       <= STOP1;
                    clk_cnt          <= clk_cnt + 1;
              end 
              else begin
                    ctrl_state       <= STOP2;
                     clk_cnt <= 32'h00000000;
              end
           end

            STOP2 : begin
                tx_serial <= 1'b1; // send stop2 bit
              if (clk_cnt < 15) begin
                    ctrl_state       <= STOP2;
                    clk_cnt          <= clk_cnt + 1;
              end 
              else begin
                    ctrl_state       <= IDLE;
                     clk_cnt <= 32'h00000000;
                    tx_done          <= 1'b1;
                    tx_active        <= 1'b0;
              end
           end

           default : begin
              ctrl_state       <= IDLE;
           end
         endcase
      end
   end

   assign uart_tx_serial = (uart_line_ctrl_reg[`UMR3_VIRTUAL_UART_LCR_BC])? 1'b0 : tx_serial;
   assign uart_tx_done = tx_done;


endmodule //umr3_virtual_uart_tx.v
