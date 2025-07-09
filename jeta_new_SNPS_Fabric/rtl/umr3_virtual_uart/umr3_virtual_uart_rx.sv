/******************************************************************************
   Copyright (C) 2020-2021 Synopsys, Inc.
   This IP and the associated documentation are confidential and
   proprietary to Synopsys, Inc. Your use or disclosure of this IP is 
   subject to the terms and conditions of a written license agreement 
   between you, or your company, and Synopsys, Inc.
*******************************************************************************
   Title      : UMR3 VIRTUAL UART RX module
   Project    : Anaconda
   Description: This module is reciever of virtual uart used in umr bus for 
                 HAPS 100

*******************************************************************************
Date          Version        Author          Modification
13Nov2020      1.00            $           Initial(in verilog file)
03Aug2021      1.06         fakhrudd       Updates
05May2022      1.02         chitra         Porting into sv file, usage of
                                           interface and including the package
                                           files and Documentation
******************************************************************************/
// --CDB TODO: put additional comments for few sections

module umr3_virtual_uart_rx  
  (
   
   input wire        umr3_clk, 
   input wire        umr3_reset,
   
   input             baud_clk,
   input wire        uart_rx_serial,
   input wire [7:0]  uart_line_ctrl_reg,
   output wire [7:0] uart_rx_byte,
   output wire       uart_cts_n,
   output wire [5:0] uart_line_stat_reg_rx,
   output wire       uart_fifo_read,
   input wire        flow_ctrl,
   input wire        reset_errors,
   input wire        fifo_full_1k 
   );
   
   logic [31:0]      full_word_trans_time;

   localparam ERR_BITS=3;
   
   // state control
   // TODO : we can use enum for state
   localparam CTRL_STATE_WIDTH = 4;
   localparam [CTRL_STATE_WIDTH-1:0] 
     IDLE = 'd1,
     START = 'd2,
     DATA = 'd3,
     PARITY_REC = 'd4,
     STOP = 'd5;
   reg [CTRL_STATE_WIDTH-1:0] ctrl_state;
   
   logic [31:0]               clk_cnt;
   logic [2:0]                bit_index;
   logic [7:0]                rx_byte;
   logic                      rx_drive;
   logic                      rec_parity;
   logic                      calc_parity;
   logic                      parity_err;
   logic                      frame_err;
   logic                      break_err;
   logic                      overrun_err;
   logic                      fifo_parity_err;
   logic                      fifo_frame_err;
   logic                      fifo_break_err;
   logic [31:0]               rxd_low_cnt;
   logic [15:0]               rxfifoe;         
   
   // FIFO
   localparam    FIFO_DEPTH =16;
   logic                      fifo_full_rx;
   logic                      fifo_write_rx;
   logic                      fifo_empty_rx;
   logic                      fifo_read_rx;
   logic [7:0]                fifo_data_out_rx;
   logic                      wr_rst_busy_rx;
   logic                      byte_finished;
   
   logic                      start_bit;
   logic                      data_bit;
   logic                      parity_bit;
   logic                      stop_bit;
   logic                      uart_rx_serial_1ff;
   logic                      uart_rx_serial_ff;
   
   assign full_word_trans_time =  (uart_line_ctrl_reg[`UMR3_VIRTUAL_UART_LCR_PEN]) ? ((16/2) + (8*16) + 16 + 16) : ((16/2) + (8*16) + 16);  // Total time for START + DATA (+ PARITY) + STOP
   
   assign fifo_write_rx = ( (!fifo_full_rx) && (!wr_rst_busy_rx) && (byte_finished) )? 1'b1:1'b0;

   assign fifo_read_rx = ~fifo_empty_rx & ~fifo_full_1k;
   
   assign overrun_err = fifo_full_rx & (ctrl_state!=IDLE);
   assign uart_fifo_read = fifo_read_rx;
   
   // Flow Control
   assign uart_cts_n = (!fifo_full_rx)? 1'b0:1'b1;
   
   //Line status registers
   assign uart_line_stat_reg_rx[0] = (reset_errors)?1'b0:~fifo_empty_rx; // DR
   assign uart_line_stat_reg_rx[1] = (reset_errors)?1'b0:overrun_err; // OE
   assign uart_line_stat_reg_rx[2] = (reset_errors)?1'b0:fifo_parity_err; // PE
   assign uart_line_stat_reg_rx[3] = (reset_errors)?1'b0:fifo_frame_err; // FE
   assign uart_line_stat_reg_rx[4] = (reset_errors)?1'b0:fifo_break_err; // BI
   assign uart_line_stat_reg_rx[5] = (reset_errors)?1'b0:| (rxfifoe[15:0]); // RXFIFOE   
  
   /* --------------------------------------------------------------------------------
	  UART RX FIFO Instantiation
    ------------------------------------------------------------------------------- */   
   
   // xpm_fifo_async: Asynchronous FIFO
   // Xilinx Parameterized Macro, version 2018.2
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
       .READ_DATA_WIDTH     (8+ERR_BITS), // DECIMAL          
       .READ_MODE("fwft"), // String
       .RELATED_CLOCKS(0), // DECIMAL
       .USE_ADV_FEATURES("1000"), // String
       .WAKEUP_TIME(0), // DECIMAL
       .WRITE_DATA_WIDTH(8+ERR_BITS), // DECIMAL
       .WR_DATA_COUNT_WIDTH(10) // DECIMAL
       )
   xpm_fifo_async_rx_inst 
     (
      .almost_empty(), // spyglass disable W287b // 1-bit output: Almost Empty : When asserted, this signal indicates that
      // only one more read can be performed before the FIFO goes to empty.
      .almost_full(), // spyglass disable W287b // 1-bit output: Almost Full: When asserted, this signal indicates that
      // only one more write can be performed before the FIFO is full.
      .data_valid(), // spyglass disable W287b // 1-bit output: Read Data Valid: When asserted, this signal indicates
      // that valid data is available on the output bus (dout).
      .dbiterr(), // spyglass disable W287b // 1-bit output: Double Bit Error: Indicates that the ECC decoder detected
      // a double-bit error and data in the FIFO core is corrupted.
      .dout({fifo_data_out_rx,fifo_parity_err,fifo_frame_err,fifo_break_err}), // spyglass disable W528 // READ_DATA_WIDTH-bit output: Read Data: The output data bus is driven                          
      // when reading the FIFO.
      .empty(fifo_empty_rx), // 1-bit output: Empty Flag: When asserted, this signal indicates that the
      // FIFO is empty. Read requests are ignored when the FIFO is empty,
      // initiating a read while empty is not destructive to the FIFO.
      .full(fifo_full_rx), // 1-bit output: Full Flag: When asserted, this signal indicates that the
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
      .wr_rst_busy(wr_rst_busy_rx), // 1-bit output: Write Reset Busy: Active-High indicator that the FIFO
      // write domain is currently in a reset state.
      .din({rx_byte,parity_err,frame_err,break_err}),    
      // writing the FIFO.
      .injectdbiterr(1'b0), // 1-bit input: Double Bit Error Injection: Injects a double bit error if
      // the ECC feature is used on block RAMs or UltraRAM macros.
      .injectsbiterr(1'b0), // 1-bit input: Single Bit Error Injection: Injects a single bit error if
      // the ECC feature is used on block RAMs or UltraRAM macros.
      .rd_clk(umr3_clk), // 1-bit input: Read clock: Used for read operation. rd_clk must be a free
      // running clock.
      .rd_en(fifo_read_rx), // 1-bit input: Read Enable: If the FIFO is not empty, asserting this
      // signal causes data (on dout) to be read from the FIFO. Must be held
      // active-low when rd_rst_busy is active high. .
      .rst(umr3_reset), // 1-bit input: Reset: Must be synchronous to wr_clk. Must be applied only
      // when wr_clk is stable and free-running.
      .sleep(1'b0), // 1-bit input: Dynamic power saving: If sleep is High, the memory/fifo
      // block is in power saving mode.
      .wr_clk(baud_clk), // 1-bit input: Write clock: Used for write operation. wr_clk must be a
      // free running clock.
      .wr_en(fifo_write_rx) // 1-bit input: Write Enable: If the FIFO is not full, asserting this
      // signal causes data (on din) to be written to the FIFO. Must be held
      // active-low when rst or wr_rst_busy is active high. .
      );
   // End of xpm_fifo_async_inst instantiation
  
   // state control
   always @(posedge baud_clk or posedge umr3_reset) begin
      if (umr3_reset == 1'b1) begin
         
         ctrl_state    <= IDLE;
         rx_byte       <= 8'h00;
         rx_drive      <= 1'b0;
         clk_cnt       <= 32'h00000000;
         bit_index     <= 3'h0;
         rec_parity    <= 1'b0;
         calc_parity   <= 1'b0;
         parity_err    <= 1'b0;
         frame_err     <= 1'b0;
         byte_finished <= 1'b0;
         rxfifoe       <= 16'h0000;
         start_bit     <= 1'b0;
         data_bit      <= 1'b0;
         parity_bit    <= 1'b0;
         stop_bit      <= 1'b0;
         uart_rx_serial_1ff <= 1'b0;
         uart_rx_serial_ff <= 1'b0;
      end else begin
         uart_rx_serial_1ff <= uart_rx_serial;
         uart_rx_serial_ff <= uart_rx_serial_1ff;
         case (ctrl_state) 
           
           IDLE : begin
              rec_parity <= 1'b0;
              calc_parity <= 1'b0;
              rx_drive <= 1'b0;
              clk_cnt <= 32'h00000000;
              bit_index <= 3'h0;
              byte_finished <= 1'b0; 
              start_bit <= 1'b0;
              data_bit <= 1'b0;
              parity_bit <= 1'b0;
              stop_bit <= 1'b0;
              if (!uart_rx_serial_ff) begin // start bit detected
                 ctrl_state       <= START;
                 clk_cnt <= 32'h00000000;
              end
              else begin
                 ctrl_state       <= IDLE;
              end
           end
           
           START : begin
              
              if (clk_cnt == (16 - 2)) begin // oversampling
                 if (start_bit) begin
                    ctrl_state       <= DATA;
                    clk_cnt <= 32'h00000000;
                    start_bit <= 1'b0;
                 end
                 else
                   ctrl_state       <= IDLE;
              end
              else begin
                 ctrl_state       <= START;
                 clk_cnt          <= clk_cnt + 1;
                 if ( (!uart_rx_serial_ff) && (clk_cnt==6) ) begin
                    start_bit <= 1'b1;
                 end
              end 
           end 
           
           DATA : begin
              if (clk_cnt < 15) begin
                 ctrl_state       <= DATA;
                 clk_cnt          <= clk_cnt + 1;
                 if (clk_cnt==7) begin
                    data_bit <= uart_rx_serial_ff;
                 end
                 
              end 
              else begin
                 clk_cnt <= 32'h00000000;
                 rx_byte[bit_index]  <= data_bit;
                 if (bit_index < 7) begin
                    bit_index    <= bit_index + 1;
                    ctrl_state   <= DATA;
                 end
                 else begin
                    bit_index     <= 3'h0;
                    
                    if (uart_line_ctrl_reg[`UMR3_VIRTUAL_UART_LCR_PEN])
                      ctrl_state   <= PARITY_REC;
                    else
                      ctrl_state   <= STOP;  
                 end
              end
              
           end 
           
           PARITY_REC : begin
              if (clk_cnt < 15) begin
                 ctrl_state       <= PARITY_REC;
                 clk_cnt          <= clk_cnt + 1;
                 if (clk_cnt==7) begin
                    parity_bit <= uart_rx_serial_ff;
                 end
              end 
              else begin
                 ctrl_state       <= STOP;
                 clk_cnt <= 32'h00000000;
                 rec_parity       <= parity_bit;
              end
           end 
           
           STOP : begin
              if (clk_cnt < 15) begin
                 ctrl_state       <= STOP;
                 clk_cnt          <= clk_cnt + 1;
                 if (clk_cnt==7) begin
                    stop_bit <= uart_rx_serial_ff;
                 end
              end 
              else begin
                 ctrl_state       <= IDLE;
                 clk_cnt <= 32'h00000000; 
                 rx_drive         <= 1'b1;
                 byte_finished    <= 1'b1;
                 rxfifoe[15:0]    <= {rxfifoe[15:1],(parity_err|frame_err|break_err)};
                 
                 if (stop_bit) begin
                    frame_err        <= 1'b0; 
                 end
                 else begin
                    frame_err        <= 1'b1; 
                 end
              end 
              
              // calculate and check parity in next 2 clock cycles
              if (clk_cnt == 0) begin //  calculate parity
                 calc_parity       <= ^{rx_byte, rec_parity};
              end
              else if (clk_cnt == 1) begin  //  check parity
                 case ({uart_line_ctrl_reg[`UMR3_VIRTUAL_UART_LCR_EPS],uart_line_ctrl_reg[`UMR3_VIRTUAL_UART_LCR_SP]})
						       2'b00:	parity_err <=  (!calc_parity)?1'b1:1'b0; // odd parity
						       2'b01:	parity_err <=  ~rec_parity; // stick parity enabled
						       2'b10:	parity_err <=  (calc_parity)?1'b1:1'b0; // even parity
						       2'b11:	parity_err <=  rec_parity; // stick parity disabled
				  	     endcase
              end
              
           end
           
           default : begin
              ctrl_state       <= IDLE;
              byte_finished <= 1'b0;
           end
         endcase
      end
   end

   assign uart_rx_byte = fifo_data_out_rx;
   
   // Calculate Break error
   always @(posedge baud_clk or posedge umr3_reset) begin
      if (umr3_reset == 1'b1) begin
         rxd_low_cnt <= 32'h00000000;
         break_err <= 1'b0;
      end 
      else begin
         if (!uart_rx_serial_ff)  begin
            rxd_low_cnt <= rxd_low_cnt + 1;
            if (rxd_low_cnt>=full_word_trans_time) begin
               rxd_low_cnt <= 32'h00000000;
               break_err <= 1'b1;
            end
         end
         else begin
            rxd_low_cnt <= 32'h00000000;
            break_err <= 1'b0;
         end
      end
   end
   
endmodule  // umr3_virtual_uart_rx.v
