/******************************************************************************
   Copyright (C) 2020-2021 Synopsys, Inc.
   This IP and the associated documentation are confidential and
   proprietary to Synopsys, Inc. Your use or disclosure of this IP is 
   subject to the terms and conditions of a written license agreement 
   between you, or your company, and Synopsys, Inc.
*******************************************************************************
   Title      : UMR3 VIRTUAL UART TOP module
   Project    : Anaconda
   Description: This module is top module virtual uart containing
                UART receiver, UART transmitter, Baud Clock generator, MCAPIM,
                rx circular buffer 
*******************************************************************************
 Date          Version        Author          Modification
 22Feb2022      1.00         fakhrudd       Initial(in verilog file)
 05May2022      1.01         chitra         Porting into sv file, usage of
                                            interface and including the package
                                            files and Documentation
 ******************************************************************************/
// --CDB TODO: put additional comments for few sections

module umr3_virtual_uart_top #(
   parameter UMR3_MCAPIM_NAME = "uart_mcapim_0")
  (

   // UART TX and RX
   output wire uart_tx_serial,
   input wire  uart_rx_serial,
   // UART Flow Control 
   input wire  uart_rts_n,
   output wire uart_cts_n,
   
   input wire  uart_sleep_n
   );

   localparam UMR3_DATA_BITWIDTH = 256;
   localparam FIFO_DEPTH_RX = 1024;

   logic [31:0] divisor;
   logic        umr3_clk;
   logic        umr3_reset;

   logic        uart_tx_done;
   logic [7:0]  uart_rx_byte;
   logic        uart_fifo_read;

   // UART Registers
   logic [7:0]  uart_line_ctrl_reg;   // LCR = DLAB[1 bit] + BC[1 bit] + SP[1 bit] + EPS[1 bit] + PEN[1 bit] + STB[1 bit] + WLS[2 bits]
   logic [7:0]  uart_line_stat_reg;  // LSR = RXFIFOE[1 bit] + TEMT[1 bit] + THRE[1 bit] + BI[1 bit] + FE[1 bit] + PE[1 bit] + OE[1 bit] + DR [1 bit]
   logic [5:0]  uart_line_stat_reg_rx;
   logic [1:0]  uart_line_stat_reg_tx;

    // RX  
   logic [7:0]  rx_data_to_mapi;

   logic        flow_ctrl;
   logic        reset_errors;

   logic        fifo_full_rx;
   logic        fifo_write_rx;
   logic        fifo_empty_rx;
   logic        fifo_read_rx;
   logic [7:0]  fifo_data_out_rx;
   logic        wr_rst_busy_rx;
   
   // MCAPIM
   
   /* --------------------------------------------------------------------------------
    local parameters
    ------------------------------------------------------------------------------- */ 
   //localparam UMR3_MCAPIM_NAME   = "uart_mcapim";
   // Enable CAPI Interface - 1=enabled (default) / 0=disabled
   localparam UMR3_MCAPIM_CAPI_ENABLE        = 1;
   // Enable MAPI Interface for offset DMA mode - 1=enabled (default) / 0=disabled
   localparam UMR3_MCAPIM_MAPI_OFFSET_ENABLE = 1;
   // Enable MAPI Interface for direct DMA mode - 1=enabled (default) / 0=disabled
   localparam UMR3_MCAPIM_MAPI_DIRECT_ENABLE = 0;
   // Enable INTI Interface - 1=enabled (default) / 0=disabled
   localparam UMR3_MCAPIM_INTI_ENABLE        = 0;
   // Enable UMRBus 2.0 compatibility mode - 0=disabled (default) / 1=enabled
   localparam UMR3_MCAPIM_COMPATIBILITY      = 0;      
   // MCAPIM placement priority (for implementation tool) - 0=no priority (default) / 1=on top of the UMRBus tree / 2=second level after top on the tree / ...
   localparam UMR3_MCAPIM_PRIORITY           = 1;
   
   /* --------------------------------------------------------------------------------
    wire & reg
    ------------------------------------------------------------------------------- */ 
   wire [`UMR3_NAME-1:0] umr3_mcapim_name;
    
   // MCAPIM Signals
   wire [UMR3_DATA_BITWIDTH/32 -1:0] capi_dout_valid;	
   wire [UMR3_DATA_BITWIDTH -1:0]    capi_dout;
   
   wire [UMR3_DATA_BITWIDTH/8-1:0]   capi_status;
   wire [UMR3_DATA_BITWIDTH-1:0]     capi_din;
   wire                              capi_din_ready;
   
   logic                             mapi_trf_req;
   logic                             mapi_trf_ack;
   reg [1:0]                         mapi_trf_op;
   logic [19:0]                      mapi_trf_length;
   reg [7:0]                         mapi_trf_id=1;
   logic [63:0]                      mapi_trf_addr;
   logic                             mapi_trf_last;
   wire [7:0]                        mapi_rsp_id;
   wire                              mapi_rsp_id_valid;
   logic [UMR3_DATA_BITWIDTH-1:0]    mapi_din;
   
   wire                              mapi_din_ready;
   wire [UMR3_DATA_BITWIDTH/8-1:0]   mapi_status;
   
   wire                              tx_ready;
   
   logic [11:0]                      cir_buff_fill_cnt;
   logic                             wait_1k;
   logic                             first_value;
   
   // Reset fifo in case fifo full but app not started as last 16 words is already stored in rx module as per UART 16550
   logic                             overflow_reset;  
   
   assign  capi_din = { {247{1'b0}},tx_ready, uart_line_stat_reg};
   
   assign  uart_line_stat_reg = {uart_line_stat_reg_rx[5],uart_line_stat_reg_tx,uart_line_stat_reg_rx[4:0]} ;
   
   // Control ans status registers
   always @(posedge umr3_clk or posedge umr3_reset) begin
      if (umr3_reset == 1'b1) begin
         uart_line_ctrl_reg <= 8'b00001111; // LCR register
         flow_ctrl <= 1'b0;
         reset_errors <= 1'b0;
         divisor <= 67;
      end 
      else begin
         if ( (capi_dout_valid[1]) && (capi_dout[63]) ) begin
            divisor <= capi_dout[31:0]; // New divisor can be written over capi_dout   
         end
         
         if ( (capi_dout_valid[1]) && (capi_dout[62]) ) begin
            uart_line_ctrl_reg <=  capi_dout[7:0]; // control paramters can be written over capi_dout 
         end
         
         if ( (capi_dout_valid[1]) && (capi_dout[61]) ) begin
            flow_ctrl <=  capi_dout[0]; // Flow control can be enable/disable over capi_dout 
         end
         
         if ( (capi_dout_valid[1]) && (capi_dout[60]) ) begin
            reset_errors <=  capi_dout[0]; // Errors can be reset over capi_dout 
         end
         else begin
            reset_errors <= 1'b0;
         end
         
      end
   end 
   
   // Baud Clock  generator
   // divisor = UART Input Clock Frequency / (Desired Baud Rate × 16)    calculated in cpp and input it during configuration
   logic           baud_clk; 
   logic           baud_clk_ff;   
   logic [15:0]    baudRateReg         ; // Register used to count
   
   always @(posedge umr3_clk or posedge umr3_reset) begin
      if (umr3_reset) begin
         baudRateReg <= 16'b1;
         baud_clk <= 1'b0;
         baud_clk_ff <= 1'b0;
      end         
      else if (baud_clk) baudRateReg <= 16'b1;
      else baudRateReg <= baudRateReg + 1'b1;
      baud_clk <= (baudRateReg == (divisor-1))?1'b1:1'b0;
      baud_clk_ff <= baud_clk;
   end
   
   /* --------------------------------------------------------------------------------
    uart_tx and uart_rx instantiation
    ------------------------------------------------------------------------------- */
   umr3_virtual_uart_tx   umr3_virtual_uart_tx_inst
     (.umr3_clk(umr3_clk),
      .umr3_reset(umr3_reset),
      .baud_clk (baud_clk_ff),
      .capi_dout (capi_dout[63:0]),
      .capi_dout_valid(capi_dout_valid[0]),
      .tx_ready(tx_ready),     
      .uart_rts_n(uart_rts_n),
      .uart_line_ctrl_reg(uart_line_ctrl_reg),   
      .uart_tx_serial(uart_tx_serial),
      .uart_tx_done(uart_tx_done),
      .uart_line_stat_reg_tx(uart_line_stat_reg_tx),
      .flow_ctrl(flow_ctrl),
      .reset_errors(reset_errors)
      );
   
   umr3_virtual_uart_rx   umr3_virtual_uart_rx_inst
     (.umr3_clk(umr3_clk),
      .umr3_reset(umr3_reset),
      .baud_clk (baud_clk_ff),
      .uart_rx_serial(uart_rx_serial),
      .uart_line_ctrl_reg(uart_line_ctrl_reg), 
      .uart_rx_byte(uart_rx_byte),
      .uart_cts_n(uart_cts_n),
      .uart_line_stat_reg_rx(uart_line_stat_reg_rx),
      .uart_fifo_read(uart_fifo_read),
      .flow_ctrl(flow_ctrl),
      .reset_errors(reset_errors),
      .fifo_full_1k(wait_1k)
      );

   assign wait_1k = (cir_buff_fill_cnt < 900)?1'b0:1'b1; // wait if 90 % of circular buffer is full

   assign umr3_mcapim_name = UMR3_MCAPIM_NAME;
 
   /* --------------------------------------------------------------------------------
    MCAPIM
    ------------------------------------------------------------------------------- */   
   umr3_mcapim_ui
     #(
       // UMRBus data bit width - 32 (default), 64, 128, 256, 512, 1024
       .UMR3_DATA_BITWIDTH             (UMR3_DATA_BITWIDTH),
       // Enable CAPI Interface - 1=enabled (default) / 0=disabled
       .UMR3_MCAPIM_CAPI_ENABLE        (UMR3_MCAPIM_CAPI_ENABLE),
       // Enable MAPI Interface for offset DMA mode - 1=enabled (default) / 0=disabled
       .UMR3_MCAPIM_MAPI_OFFSET_ENABLE (UMR3_MCAPIM_MAPI_OFFSET_ENABLE),
       // Enable MAPI Interface for direct DMA mode - 1=enabled (default) / 0=disabled
       .UMR3_MCAPIM_MAPI_DIRECT_ENABLE (UMR3_MCAPIM_MAPI_DIRECT_ENABLE),
       // Enable INTI Interface - 1=enabled (default) / 0=disabled
       .UMR3_MCAPIM_INTI_ENABLE        (UMR3_MCAPIM_INTI_ENABLE),  
       // MCAPIM placement priority (for implementation tool) - 0=no priority (default) / 1=on top of the UMRBus tree / 2=second level after top on the tree / ...
       .UMR3_MCAPIM_PRIORITY           (UMR3_MCAPIM_PRIORITY)
       )
   I_umr3_mcapim_ui
     (
      /* --------------------------------------------------------------------------------
       UMRBus Infrastructure
       ------------------------------------------------------------------------------- */       
      // UMRBus clock & reset
      .umr3_clk                       (umr3_clk),
      .umr3_reset                     (umr3_reset),
      // Name of the MCAPIM 16 characters
      .umr3_mcapim_name               (umr3_mcapim_name),
      
      /* --------------------------------------------------------------------------------
       Client APplication Interface (CAPI)
       ------------------------------------------------------------------------------- */       
      // data out for H_WR (bit width is equal to UMR_DATA_BITWIDTH)
      .capi_dout                      (capi_dout),
      // 32bit word enable  
      .capi_dout_valid                (capi_dout_valid),
      // data in for H_RD (bit width is equal to UMR_DATA_BITWIDTH)
      .capi_din                       (capi_din),

      // indicates, if capi_din_valid=1, that the data on capi_din was read (H_RD) and that the next data can be assigned
      .capi_din_ready                 (capi_din_ready),
      // error and status information (always valid)
      .capi_status                    (capi_status),
      /* --------------------------------------------------------------------------------
       Master APplication Interface (MAPI)
       ------------------------------------------------------------------------------- */       
      // transfer request
      .mapi_trf_req                   (mapi_trf_req),
      // transfer operation (b00 – offset DMA write to host / b01 – offset DMA read from host / b10 – direct DMA write to host / b11 – direct DMA read from host)
      .mapi_trf_op                    (mapi_trf_op),
      // transfer acknowledge
      .mapi_trf_ack                   (mapi_trf_ack),
      // transfer length (number of 32bit words, maximum depends on control register settings)
      .mapi_trf_length                (mapi_trf_length),
      // transfer ID 
      .mapi_trf_id                    (mapi_trf_id),
      // offset address or memory address (depends on mapi_trf_op)
      .mapi_trf_addr                  (mapi_trf_addr),
      // indicates the last part of a data transfer
      .mapi_trf_last                  (mapi_trf_last),
      // transfer response ID
      .mapi_rsp_id                    (mapi_rsp_id),
      // transfer response ID valid
      .mapi_rsp_id_valid              (mapi_rsp_id_valid),
      // data out (bit width is equal to UMR_DATA_BITWIDTH)
      .mapi_dout                      (),
      // 32bit word enable         
      .mapi_dout_valid                (),
      // data in (bit width is equal to UMR_DATA_BITWIDTH)
      .mapi_din                       (mapi_din),
      // indicates, if mapi_din_valid=1, that the data on mapi_din was read and that the next data can be assigned
      .mapi_din_ready                 (mapi_din_ready),
      // error and status information (always valid)
      .mapi_status                    (mapi_status),
      /* --------------------------------------------------------------------------------
       Interrupt Interface (INTI)
       ------------------------------------------------------------------------------- */       
      // interrupt request
      .inti_req                       (1'b0),
      // interrupt acknowledge
      .inti_ack                       (),
      // interrupt type
      .inti_type                      (32'h0 ),
      // INTI enabled (1=yes / 0=no)
      .inti_status                    ()
      );

   // MAPI Interface signal generation
   always @(posedge umr3_clk or posedge umr3_reset ) begin
	    if (umr3_reset) begin
		     rx_data_to_mapi <= 8'b0;
         mapi_trf_req <= 1'b0;
         mapi_trf_length <= 20'h1;
         mapi_trf_addr <= {64{1'b0}};
         mapi_trf_last <= 1'b1;
         mapi_trf_op   <= 2'b00;
         mapi_trf_id   <= 1;
         cir_buff_fill_cnt <= {12{1'b0}};        
         first_value <= 1'b0;
	    end 
      else begin 
         
			   if (fifo_read_rx) begin 
			      rx_data_to_mapi <= fifo_data_out_rx;
         end                       
         
         // mapi_trf_req
         if (fifo_read_rx) begin
            mapi_trf_req <= 1'b1;
            first_value <= 1'b1;
            if (first_value) begin
               mapi_trf_addr <= mapi_trf_addr + 4;
               if (mapi_trf_addr==40'hFFC) begin // 4*1024 - 4
                  mapi_trf_addr <= {64{1'b0}};
               end
            end
         end
         else if (mapi_trf_ack) begin
            mapi_trf_req <= 1'b0;
         end
         
         // Circular buffer counter
         if  (fifo_write_rx) begin //mapi_trf_req
            cir_buff_fill_cnt <= cir_buff_fill_cnt + 1;
         end 

          if ( (fifo_read_rx) && (cir_buff_fill_cnt!=0) ) begin
            cir_buff_fill_cnt <= cir_buff_fill_cnt - 1;
         end
          else if (overflow_reset) begin
             cir_buff_fill_cnt <= {12{1'b0}};     
         end      
         
		  end
	 end
   
   assign  fifo_write_rx = ( ( (!fifo_full_rx) & (!wr_rst_busy_rx)  & (uart_fifo_read) ) && (cir_buff_fill_cnt < 900) )?1'b1:1'b0;
   assign fifo_read_rx = (~fifo_empty_rx  & (mapi_status[0]) ) ;
   
   assign mapi_din =  ( (fifo_read_rx)  && (mapi_status[0]) )? { {(248){1'b0}},fifo_data_out_rx} : {{(248){1'b0}}, rx_data_to_mapi};

   // reset 1k fifo if fifo_full but app not started
   assign overflow_reset = ( (wait_1k)  & (~mapi_status[0]) ) ;
   
   /* --------------------------------------------------------------------------------
	  UART RX FIFO as circular buffer
    ------------------------------------------------------------------------------- */   
   xpm_fifo_sync
     #(
       .DOUT_RESET_VALUE    ("0"), // String
       .ECC_MODE            ("no_ecc"), // String
       .FIFO_MEMORY_TYPE    ("auto"), // String
       .FIFO_READ_LATENCY   (0), // DECIMAL
       .FIFO_WRITE_DEPTH    (FIFO_DEPTH_RX), // DECIMAL
       .FULL_RESET_VALUE    (0), // DECIMAL
       .PROG_EMPTY_THRESH   (10), // DECIMAL
       .PROG_FULL_THRESH    (10), // DECIMAL
       .RD_DATA_COUNT_WIDTH (10), // DECIMAL     
       .READ_DATA_WIDTH     (8), // DECIMAL
       .READ_MODE           ("fwft"), // String
       .USE_ADV_FEATURES    ("1000"), // String
       .WAKEUP_TIME         (0), // DECIMAL
       .WRITE_DATA_WIDTH    (8), // DECIMAL
       .WR_DATA_COUNT_WIDTH (10) // DECIMAL
       )
   xpm_fifo_sync_rx_inst
     (
      .almost_empty      (), // spyglass disable W287b
      .almost_full       (), // spyglass disable W287b // 1-bit output: Almost Full: When asserted, this signal indicates that
      .data_valid        (), // spyglass disable W287b // 1-bit output: Read Data Valid: When asserted, this signal indicates
      .dbiterr           (), // spyglass disable W287b // 1-bit output: Double Bit Error: Indicates that the ECC decoder detected
      .dout              (fifo_data_out_rx), // spyglass disable W528 // READ_DATA_WIDTH-bit output: Read Data: The output data bus is driven
      .empty             (fifo_empty_rx), // 1-bit output: Empty Flag: When asserted, this signal indicates that the
      .full              (fifo_full_rx), // 1-bit output: Full Flag: When asserted, this signal indicates that the
      .overflow          (), // spyglass disable W287b // 1-bit output: Overflow: This signal indicates that a write request
      .prog_empty        (), // spyglass disable W287b // 1-bit output: Programmable Empty: This signal is asserted when the
      .prog_full         (), // spyglass disable W287b // 1-bit output: Programmable Full: This signal is asserted when the
      .rd_data_count     (), // spyglass disable W287b // RD_DATA_COUNT_WIDTH-bit output: Read Data Count: This bus indicates the
      .rd_rst_busy       (), // spyglass disable W287b // 1-bit output: Read Reset Busy: Active-High end_running_frame_tx that the FIFO read
      .sbiterr           (), // spyglass disable W287b // 1-bit output: Single Bit Error: Indicates that the ECC decoder detected
      .underflow         (), // spyglass disable W287b // 1-bit output: Underflow: Indicates that the read request (rd_en) during
      .wr_ack            (), // spyglass disable W287b // 1-bit output: Write Acknowledge: This signal indicates that a write
      .wr_data_count     (), // spyglass disable W287b // WR_DATA_COUNT_WIDTH-bit output: Write Data Count: This bus indicates
      .wr_rst_busy       (wr_rst_busy_rx), // 1-bit output: Write Reset Busy: Active-High end_running_frame_tx that the FIFO
      .din               (uart_rx_byte),     
      .injectdbiterr     (1'b0), // 1-bit input: Double Bit Error Injection: Injects a double bit error if
      .injectsbiterr     (1'b0), // 1-bit input: Single Bit Error Injection: Injects a single bit error if
      .rd_en             (fifo_read_rx), // 1-bit input: Read Enable: If the FIFO is not empty, asserting this
      .rst               (umr3_reset | overflow_reset), // 1-bit input: Reset: Must be synchronous to wr_clk. Must be applied only
      .sleep             (1'b0), // 1-bit input: Dynamic power saving- If sleep is High, the memory/fifo
      .wr_clk            (umr3_clk), // 1-bit input: Write clock: Used for write operation. wr_clk must be a
      .wr_en             (fifo_write_rx) // 1-bit input: Write Enable: If the FIFO is not full, asserting this
      );

endmodule   // umr3_virtual_uart_top
