/******************************************************************************
 Copyright (C) 2018-2022 Synopsys, Inc.
 This IP and the associated documentation are confidential and
 proprietary to Synopsys, Inc. Your use or disclosure of this IP is 
 subject to the terms and conditions of a written license agreement 
 between you, or your company, and Synopsys, Inc.
 *******************************************************************************
 Title  : HAPS SoC
 Project: XTOR RISCV SOC
 Description: This module is the top module for SOC design
         It contains following modules:
         1) UART module                 : for communicating with external world
         2) RISC Processor              : device under test
         3) External memory controller  : for bootloading and memory for the
            processor
         Virtual uart are available for HAPS 100 only
 *******************************************************************************
 Date          Version        Author          Modification
 04Apr2022      1.00         khertig        Initial(in verilog file)
 05May2022      1.01         chitra         Porting into sv file, usage of
                                            interface and including the package
                                            files and Documentation
 ******************************************************************************/

`timescale 1ps / 1ps

import axi_assign::*;

module haps_soc #
  (
`ifdef SIMULATION
    parameter SYS_CLK_PERIOD = 40000,
    parameter TCK_CLK_PERIOD = 100000,
`endif

`ifdef RANKS
   parameter RANKS               = `RANKS,
`else
   parameter RANKS               = 2,
`endif
`ifdef RDIMM
   parameter CK_WIDTH            = 1,
`else
   parameter CK_WIDTH            = 2,
`endif
`ifdef SODIMM  // HAPS-100_12F only
   parameter DQ_WIDTH            = 72,
`else
 `ifdef ECC
   parameter DQ_WIDTH            = 72,
 `else
   parameter DQ_WIDTH            = 64,
 `endif
`endif
   parameter DDR_CLK_PERIOD      = 5000,
   parameter MEM_ADDR_WIDTH      = 17,
   parameter DQS_WIDTH           = DQ_WIDTH / 8,
   parameter BANK_WIDTH          = 2
    )
   (
`ifndef SIMULATION
    // clocks & resets
    input                       reset_n ,
    input                       sys_clk,
    input                       jtag_TCK ,
    input                       ddr_clk ,
    input                       ddr_clk_n ,   
    output                      ddr_clk_en_n ,
`endif
    
`ifndef HAPS80D
    // -- UART FLOW CONTROL
    input                       uart_rts_n,
    output                      uart_cts_n,
    input                       uart_sleep_n,
`endif
    input                       uart_rx,
    output                      uart_tx,

    // JTAG signals
    input                       jtag_TMS ,
    input                       jtag_TDI ,
    output                      jtag_TDO ,

    //  Memory Bus signals
    output                      mem_reset_n ,
    output [CK_WIDTH-1:0]       mem_ck_c ,
    output [CK_WIDTH-1:0]       mem_ck_t ,
    output [1:0]                mem_cke ,
    output [1:0]                mem_odt ,
    output [1:0]                mem_cs_n ,
    output                      mem_act_n ,
    output                      mem_parity ,
    output [BANK_WIDTH-1:0]     mem_ba ,
    output [BANK_WIDTH-1:0]     mem_bg ,
    output [MEM_ADDR_WIDTH-1:0] mem_a ,
    inout [DQS_WIDTH-1:0]       mem_dqs_c ,
    inout [DQS_WIDTH-1:0]       mem_dqs_t ,
    inout [DQS_WIDTH-1:0]       mem_dm_dbi_n ,
    inout [DQ_WIDTH-1:0]        mem_dq

    );

`ifdef SIMULATION
   // clocks & resets
   // incoming signals are tied off to the ground
   // outgoing singals are just declared
   reg                     reset_n        = 1'b0;
   reg                     sys_clk        = 1'b0;
   reg                     jtag_TCK       = 1'b0;
   reg                     ddr_clk        = 1'b0;
   wire                    ddr_clk_n            ;
   wire                    ddr_clk_en_n         ;

   
`endif
    
    // Clock
    wire        core_clk;

`ifdef ENABLE_GSV
    wire        trigger_in;
    wire        creset_out;
    zceiClockPort #(.clockName("Clock1_CCM"), .clockSource("MASTER_CLOCK"), .hiCycles(1), .loCycles(1), .resetCycles(5))
    ClockPort(.cclock(core_clk), .creset(creset_out));
    
    iice_trigger #("IICE_core_clk") trigger_inst0(trigger_in);
    ccm_gsv_clk_stop_user #(1) clk_stop_inst (trigger_in);
    
`else 
    assign core_clk = sys_clk;
`endif
   
   // The reset signals
   wire                    reset_sync   /* synthesis syn_keep=1 */;   
   wire                    RocketSystem_reset;

    // JTAG signals 
   	wire                    RocketSystem_debug_systemjtag_reset;
   	wire [10:0]             RocketSystem_debug_systemjtag_mfr_id;
   	wire                    RocketSystem_debug_ndreset;
   	wire [1:0]              RocketSystem_interrupts;
    /*
    wire                    RocketSystem_debug_systemjtag_jtag_TMS;
    wire                    RocketSystem_debug_systemjtag_jtag_TCK;
    wire                    RocketSystem_debug_systemjtag_jtag_TDI;
    wire                    RocketSystem_debug_systemjtag_jtag_TDO_data;
    wire                    RocketSystem_debug_systemjtag_jtag_TDO_driven;
    */

   	// clock and reset to ext memory (DDR)
   	//
  	wire                    ui_clk /* synthesis syn_noclockbuf=1 */;
   	wire                    ui_clk_sync_rst;
   
   	// Interrupt  request from uart
   	wire                    irq_uart;
   	// Initialisation phase done for DDR
   	wire                    ddr_phy_init_done;
   
    // AXI signals used as wires to axi_extmem module
    //
    axi_mm #(.DWDT(64),.AWDT(32),.IDWDT(5))axi_ext_mem    (.clk(core_clk), .resetn(~RocketSystem_reset)); // Rocket System -> i_axi_extmem
    axi_mm #(.DWDT(64),.AWDT(32),.IDWDT(5))axi_xtor_extmem(.clk(core_clk), .resetn(~reset_sync)); // AXI Xtor -> i_axi_extmem
    axi_mm #(.DWDT(64),.AWDT(32),.IDWDT(5))axi_DDR        (.clk(ui_clk),   .resetn(~ui_clk_sync_rst)); // i_axi_extmem -> DDR MIG IP
   
    // AXI signals used as wires to SNPS fabric module
    //
    axi_mm #(.DWDT(64),.AWDT(32),.IDWDT(5))axi_mmio     (.clk(core_clk), .resetn(~RocketSystem_reset)); // Rocket System -> i_SNPS_fabric
    axi_mm #(.DWDT(64),.AWDT(32),.IDWDT(5))axi_xtor_mmio(.clk(core_clk), .resetn(~reset_sync)); // AXI Xtor -> i_SNPS_fabric
    axi_mm #(.DWDT(32),.AWDT(32),.IDWDT(5))axi_bram_ctrl(.clk(core_clk), .resetn(~reset_sync)); // i_SNPS_fabric -> i_axi_mmio
    axi_mm #(.DWDT(32),.AWDT(32),.IDWDT(5))axi_uart_mm  (.clk(core_clk), .resetn(~reset_sync)); // i_SNPS_fabric -> i_axi_mmio
   
    // AXI signals used as wires between Rocket System and frontend bus 
    // Currently unused so tied up to fixed value
    //
    axi_mm #(.DWDT(64),.AWDT(32),.IDWDT(8))RocketSystem_l2_frontend_bus (.clk(core_clk),.resetn( ~RocketSystem_reset));

   // control capim signals for User control
   // capim_wr is controlled by capim_ui
   // when capim_wr is asserted software reset is possible by capim_do reg from capim_ui
   // capim_di are input to the capim_ui IP with following status bits
   // +------------------------------------------------------------------------------+
   // |     5      |      4     |      3     |      2     |      1     |      0      |
   // +------------------------------------------------------------------------------+
   // |  sw_rst_n  |  phy_vuart |   sw_rst   | ui_clk_rst | reset_sync |ddr_init_done|
   // +------------------------------------------------------------------------------+
   //
   wire                    umr_clk_int; 
   wire                    umrReset;
   wire                    capim_wr;
   wire [31:0]             capim_do; 
   logic                   capim_rd;
   logic                   capim_inta;
   logic   [31:0]          capim_din;
   logic                   capim_intr;
   logic   [15:0]          capim_inttype;
   logic  [31:0]           capim_reg;
   logic                   phys_virt_uart;
   logic                   sw_rst_n;
   logic                   sw_rst_sync;

`ifdef HAPS100
   logic                   uart_vuart_rx;
`endif

   
    assign capim_intr    = 1'b0;
    assign capim_inttype = 1'b0;

    always @(posedge umr_clk_int) begin
       if(umrReset == 1'b1) begin
             capim_din      <= 32'h0;
             phys_virt_uart <= 1'b0;
             sw_rst_n       <= 1'b0;
        end
       else begin             
            if ( capim_wr == 1'b1 ) begin // reset from capim_ui
                {sw_rst_n,phys_virt_uart} <= capim_do[5:4];
            end

            capim_din[5:0] <= {sw_rst_n,phys_virt_uart,sw_rst_sync,ui_clk_sync_rst,reset_sync,ddr_phy_init_done};
        end
    end // always @ (posedge umr_clk_int)

// CAPIM 
// for providing the user control over the design
//
`ifdef XACTORS_UMR3
    umr3_capim_ui
`else    
    capim_ui
`endif   
    #(
        .UMR_CAPIM_ADDRESS        (3),
        .UMR_CAPIM_TYPE           (16'h8001),
        .UMR_CAPIM_COMMENT_STRING ("ctrl_capim") 
    ) 
    I_ctrl_capim 
    (
        .umr_clk   (),
        .umr_reset (),
        .wr        (capim_wr),
        .dout      (capim_do),
        .rd        (capim_rd),
        .din       (capim_din),
        .intr      (capim_intr),
        .inta      (capim_inta),
        .inttype   (capim_inttype)
    );
   //assign capim_inttype   = 16'b0;
   //assign capim_intr      = 1'b0;

   //assign capim_din[0]     = ddr_phy_init_done ;   
   //assign capim_din[1]     = ~ui_clk_sync_rst ;
   //assign capim_din[2]     = ui_clk_sync_rst ;
   //assign capim_din[7:3]   = 'b0 ;
   //assign capim_din[14:8]  = 16  ;
   //assign capim_din[15]    = 1 ;      
   //assign capim_din[31:24] = 'b0 ;

    xactor_connect I_xactors_connect
    (
        .reset         (1'b0),
        .umr_reset_out (umrReset),
        .umr_clk_out   (umr_clk_int)
    );

`ifdef HAPS100
    // Adding umr3_virtual uart
    // in HAPS100 there is option to use virtual uart
    // used for putty connection
    // UART Flow Control 
    logic   vuart_tx;
    logic   vuart_rts;
    logic   vuart_cts;

    assign  vuart_rx      = uart_tx;
    assign  uart_vuart_rx = phys_virt_uart ? uart_rx : vuart_tx;
    assign  vuart_rts     = uart_cts_n;

    umr3_virtual_uart_top #(
        .UMR3_MCAPIM_NAME("uart_mcapim_0")
    ) 
    umr3_virtual_uart_top_inst_0
    (
        .uart_tx_serial ( vuart_tx  ),
        .uart_rx_serial ( vuart_rx  ),
        .uart_rts_n     ( vuart_rts ),
        .uart_cts_n     ( vuart_cts ),
        .uart_sleep_n   ()
    );

`endif

`ifndef HAPS80D
    // -- Supporting UART Flow Control
    assign uart_cts_n = 1'b0;
`endif

   
    // reset synchroniser
    reset_sync_inv 
    resetSyncInvSystemReset
    (
        .clk       (core_clk),
        .rst_async (reset_n),
        .rst_sync  (reset_sync)
    );

    // Reset synchronizer
    //
    reset_sync_inv 
    resetSyncInvCapimUiReset
    (
        .clk       (core_clk),
        .rst_async (sw_rst_n),
        .rst_sync  (sw_rst_sync)
    );

    // RISCv based CPU Rocket system RTL
    ExampleRocketSystem 
    RocketSystem
    (
        .clock                                ( core_clk           ),
        .reset                                ( RocketSystem_reset ),
        .debug_systemjtag_jtag_TCK            (jtag_TCK),//(RocketSystem_debug_systemjtag_jtag_TCK),
        .debug_systemjtag_jtag_TMS            (jtag_TMS),//(RocketSystem_debug_systemjtag_jtag_TMS),
        .debug_systemjtag_jtag_TDI            (jtag_TDI),//(RocketSystem_debug_systemjtag_jtag_TDI),
        .debug_systemjtag_jtag_TDO_data       (jtag_TDO),//(RocketSystem_debug_systemjtag_jtag_TDO_data),
        .debug_systemjtag_jtag_TDO_driven     (/*open*/),//(RocketSystem_debug_systemjtag_jtag_TDO_driven),
        .debug_systemjtag_reset               ( RocketSystem_debug_systemjtag_reset ),
        .debug_systemjtag_mfr_id              ( RocketSystem_debug_systemjtag_mfr_id),
        .debug_ndreset                        ( RocketSystem_debug_ndreset          ),
        .interrupts                           ( RocketSystem_interrupts             ),
        `RESP_PORT(mem_axi4_0,axi_ext_mem),
        `REQ_PORT(mem_axi4_0,axi_ext_mem),
        `RESP_PORT(mmio_axi4_0,axi_mmio),
        `REQ_PORT(mmio_axi4_0,axi_mmio),
        `REQ_PORT(l2_frontend_bus_axi4_0,RocketSystem_l2_frontend_bus)
    );  
    `undef REQ_PORT
    `undef RESP_PORT
/*
`ifndef SIMULATION
   BUFG BUFG_CLK
    (
      .I( jtag_TCK      ),
      .O( jtag_TCK_BUFG )
    );
   
   // JTAG XMRS (Cross Module References)         
   assign JTAGVPI.jtag_TCK        = jtag_TCK_BUFG;
   assign JTAGVPI.jtag_TMS        = jtag_TMS;
   assign JTAGVPI.jtag_TDI        = jtag_TDI;
   assign jtag_TDO                = JTAGVPI.jtag_TDO_data;
   assign JTAGVPI.jtag_TDO_driven = 1'b1;   
`endif

*/
   
    assign RocketSystem_reset = reset_sync | sw_rst_sync | RocketSystem_debug_ndreset;
    assign RocketSystem_debug_systemjtag_reset = reset_sync | sw_rst_sync;
    assign RocketSystem_debug_systemjtag_mfr_id = 11'h0;
   
    // Interrupt for Rocket system
    // The Currently only UART available
    // TODO : Add different system/interface
    assign RocketSystem_interrupts = { irq_uart, 1'b0 }; 
   
    // Tieing up unused signals
    `AXI_MM_TIEOFF(RocketSystem_l2_frontend_bus)
   
   // XLNX DDR MIG IP instance to connect to external DDR chip
   // It is used to convert the AXI memory mapped IO to the DDR Chip 
   // c0_ddr4_* are coming from/going to external memory
   // c0_ddr4_s_axi_* are coming from/going to the AXI interconnect instance i_axi_extmem
   // c0_ddr4_s_axi_ctrl_* are used for controlling the CSR of the MIG IP but currently its unused
   // c0_ddr4_interrupt is unused thus tied off to ground
   // TODO : Change XLNX AXI interface to SNPS AXI interface
   //
    assign ddr_clk_en_n = 1'b0; // enable 200MHz clock generator on DDR4
    mig_ddr4
    i_mig
    (
        .sys_rst                        ( ~reset_n                 ),
        // Memory interface ports                                  
        .c0_sys_clk_p                   ( ddr_clk                  ),
        .c0_sys_clk_n                   ( ddr_clk_n                ),
        .c0_ddr4_act_n                  ( mem_act_n                ),
        .c0_ddr4_adr                    ( mem_a                    ),
        .c0_ddr4_ba                     ( mem_ba                   ),
        .c0_ddr4_bg                     ( mem_bg                   ),
        .c0_ddr4_cke                    ( mem_cke[RANKS-1:0]       ),
        .c0_ddr4_odt                    ( mem_odt[RANKS-1:0]       ),
        .c0_ddr4_cs_n                   ( mem_cs_n[RANKS-1:0]      ),
        .c0_ddr4_ck_t                   ( mem_ck_t[CK_WIDTH-1:0]   ),
        .c0_ddr4_ck_c                   ( mem_ck_c[CK_WIDTH-1:0]   ),
        .c0_ddr4_reset_n                ( mem_reset_n              ),
        .c0_ddr4_parity                 ( mem_parity               ),
        .c0_ddr4_dm_dbi_n               ( mem_dm_dbi_n             ),
        .c0_ddr4_dq                     ( mem_dq                   ),
        .c0_ddr4_dqs_c                  ( mem_dqs_c                ),
        .c0_ddr4_dqs_t                  ( mem_dqs_t                ),
        .c0_init_calib_complete         ( ddr_phy_init_done        ), 
        // Application interface ports     
        .c0_ddr4_ui_clk                 ( ui_clk                   ),
        .c0_ddr4_ui_clk_sync_rst        ( ui_clk_sync_rst          ),
        //.c0_ddr4_ui_clk               (  ),
        //.addn_ui_clkout1              ( ui_clk                   ),
        .addn_ui_clkout1                (  ),
        .dbg_clk                        (  ),
        .dbg_bus                        (  ),
        .c0_ddr4_aresetn                ( ~ui_clk_sync_rst         ),
        // Axi Port from AXI interconnect
        `AXI_MM(c0_ddr4_s_axi,axi_DDR)
	);
   
    // AXI interconnect for connecting XACTOR and DDR external memory
    // to  Rocket System
    // TODO : Change XLNX AXI interface to SNPS AXI interface
    //
    axi_extmem
    i_axi_extmem
    (
        // Clock and System
        .M_ACLK                     ( ui_clk           ),
        .M_ARESETN                  ( ~ui_clk_sync_rst ),
        .S_ACLK                     ( core_clk         ),
        .S_RESETN                   ( reset_n          ),
        // interface from the Rocket System for external memory
        `AXI_MM(AXI,axi_ext_mem),
        // DDR side
        `AXI_MM(DDR,axi_DDR),
        // XTOR instance
        `AXI_MM(XTOR_AXI,axi_xtor_extmem)
    );

    // XACTOR SNPS IP
    // For user controlling purpose
    //
    `define CAP 1
    axi_master_xactor
    i_axi_master_xactor
    (
        // i_axi_master (axi_master) signal_prefix='M1_'
        // Clock and Systems
        .M1_ACLK                  (core_clk),
        .M1_ARESETn               (~reset_sync),
        // Ports
        `AXI_MM(M1,axi_xtor_extmem),
        .M1_CSYSREQ               (1'b0),
        .M1_CSYSACK               (M1_CSYSACK),
        .M1_CACTIVE               (M1_CACTIVE)
    );
   `undef CAP
   
    // AXI interconnect + UARTLITE + BRAM CTRL and BRAM (i_axi_mmio)
    // for connecting BRAM CNTRL
    // and UART interface for putty  to  Rocket System
    //
    logic dut_i_axi_a2x_busy_status;
    logic dut_i_axi_a2x_1_busy_status;

    SNPS_fabric
    i_SNPS_fabric
        (
        .ACLK_aclk                     (core_clk),
        .ARESETn_aresetn               (reset_n ),
        `AXI_MM(axi_bram_Slave02,axi_bram_ctrl),
        `AXI_MM(axi_mmio_Master01,axi_mmio),
        `AXI_MM(axi_uart_Slave01,axi_uart_mm),
        `AXI_MM(xtor_mmio_Master02,axi_xtor_mmio),
        .i_axi_dbg_araddr_s0            (),
        .i_axi_dbg_arburst_s0           (),
        .i_axi_dbg_arcache_s0           (),
        .i_axi_dbg_arid_s0              (),
        .i_axi_dbg_arlen_s0             (),
        .i_axi_dbg_arlock_s0            (),
        .i_axi_dbg_arprot_s0            (),
        .i_axi_dbg_arready_s0           (),
        .i_axi_dbg_arsize_s0            (),
        .i_axi_dbg_arvalid_s0           (),
        .i_axi_dbg_awaddr_s0            (),
        .i_axi_dbg_awburst_s0           (),
        .i_axi_dbg_awcache_s0           (),
        .i_axi_dbg_awid_s0              (),
        .i_axi_dbg_awlen_s0             (),
        .i_axi_dbg_awlock_s0            (),
        .i_axi_dbg_awprot_s0            (),
        .i_axi_dbg_awready_s0           (),
        .i_axi_dbg_awsize_s0            (),
        .i_axi_dbg_awvalid_s0           (),
        .i_axi_dbg_bid_s0               (),
        .i_axi_dbg_bready_s0            (),
        .i_axi_dbg_bresp_s0             (),
        .i_axi_dbg_bvalid_s0            (),
        .i_axi_dbg_rdata_s0             (),
        .i_axi_dbg_rid_s0               (),
        .i_axi_dbg_rlast_s0             (),
        .i_axi_dbg_rready_s0            (),
        .i_axi_dbg_rresp_s0             (),
        .i_axi_dbg_rvalid_s0            (),
        .i_axi_dbg_wdata_s0             (),
        .i_axi_dbg_wid_s0               (),
        .i_axi_dbg_wlast_s0             (),
        .i_axi_dbg_wready_s0            (),
        .i_axi_dbg_wstrb_s0             (),
        .i_axi_dbg_wvalid_s0            (),
        .i_axi_a2x_busy_status          (dut_i_axi_a2x_busy_status),
        .i_axi_a2x_1_busy_status        (dut_i_axi_a2x_1_busy_status)
    );

    axi_mmio
    i_axi_mmio
    (
        // system clock and reset
        .clk         (core_clk),
        .resetn      (~reset_sync),
        //
        `AXI_MM(BRAM_CTRL,axi_bram_ctrl),
        //
        `AXI_MM(UART_MM,axi_uart_mm),
    `ifdef HAPS100
        .rx              (uart_vuart_rx),
    `else
        .rx              (uart_rx),
    `endif
        .tx              (uart_tx),
        .irq_uart0       (irq_uart)
    );

    // XACTOR SNPS IP
    // For user control purpose
    //
    `define CAP 1
    axi_mmio_master_xactor 
    i_axi_mmio_master_xactor
    (
        // i_axi_master (axi_master) signal_prefix='M1_'
        .M1_ACLK                  (core_clk         ),
        .M1_ARESETn               (  reset_n        ),
        // Axi port
        `AXI_MM(M1,axi_xtor_mmio),
        .M1_CSYSREQ               (1'b0             ),
        .M1_CSYSACK               (M1_MMIO_CSYSACK  ),
        .M1_CACTIVE               (M1_MMIO_CACTIVE  )
    );
    `undef CAP

	`define AXI_DEBUG(if_port)\
        $dumpvars(1, ``if_port``.aw.valid);\
        $dumpvars(1, ``if_port``.awready);\
        $dumpvars(1, ``if_port``.awaddr);\
        $dumpvars(1, ``if_port``.awid);\
        $dumpvars(1, ``if_port``.aw.len);\
        $dumpvars(1, ``if_port``.ar.valid);\
        $dumpvars(1, ``if_port``.arready);\
        $dumpvars(1, ``if_port``.araddr);\
        $dumpvars(1, ``if_port``.arid);\
        $dumpvars(1, ``if_port``.ar.len);\
        $dumpvars(1, ``if_port``.wdata);\
        $dumpvars(1, ``if_port``.wstrb);\
        $dumpvars(1, ``if_port``.w.valid);\
        $dumpvars(1, ``if_port``.wready);\
        $dumpvars(1, ``if_port``.b.valid);\
        $dumpvars(1, ``if_port``.bready);\
        $dumpvars(1, ``if_port``.r.valid);\
        $dumpvars(1, ``if_port``.rready);\
        $dumpvars(1, ``if_port``.rdata)

    `ifdef ENABLE_DEBUG
        initial begin: IICE_core_clk
            $dumpvars(1, haps_soc.reset_sync);
            $dumpvars(1, haps_soc.RocketSystem_reset);
            `AXI_DEBUG(axi_ext_mem);
            `AXI_DEBUG(axi_xtor_extmem);
            `AXI_DEBUG(axi_mmio);
            `AXI_DEBUG(axi_xtor_mmio);
            `AXI_DEBUG(axi_bram_ctrl);
            `AXI_DEBUG(axi_uart_mm);
        end
        initial begin: IICE_axi_DDR
            $dumpvars(1, haps_soc.ui_clk_sync_rst);
            `AXI_DEBUG(axi_DDR);
        end
    `endif

    `ifdef ENABLE_DF
        initial begin : IICE_DF
            (* haps_force *) $dumpvars (1, haps_soc.sw_rst_sync);
            (* haps_force *) $dumpvars (1, haps_soc.RocketSystem.mem_axi4_0_b_ready);
        end
    `endif

    // synthesis translate_off

    //-----------------------------------------------------------------------------
    // Simulation: connections, signals and messages
    //-----------------------------------------------------------------------------

    // reset generator
    initial begin
        #(120000) reset_n = 1'b1 ;
    end

    // mclk clock
    initial begin
        forever
        #(SYS_CLK_PERIOD/2.0) sys_clk = ~sys_clk ;
    end

    // jtag_TCK clock
    initial begin
        forever
        #(TCK_CLK_PERIOD/2.0) jtag_TCK = ~jtag_TCK ;
    end

    // ddr_clk clock (AXI, DFI, controller clock)
    initial begin
        forever
        #(DDR_CLK_PERIOD/2.0) ddr_clk = ~ddr_clk ;
    end
    assign ddr_clk_n = ~ddr_clk ;

    //===========================================================================
    //                         Memory Model instantiation
    //===========================================================================
    ddr4_rdimm_wrapper 
    #(
        .MC_DQ_WIDTH(DQ_WIDTH),                 // 72
        .MC_DQS_BITS(DQ_WIDTH / 8),             // 9
        .MC_DM_WIDTH(DQ_WIDTH / 8),             // 9
        .MC_CKE_NUM(RANKS),                     // 2
        .MC_ODT_WIDTH(RANKS),                   // 2
        .MC_ABITS(MEM_ADDR_WIDTH),              // 17
        //.MC_BANK_WIDTH(BANK_WIDTH_RDIMM),       // 2
        //.MC_BANK_GROUP(BANK_GROUP_WIDTH_RDIMM), // 2
        .MC_CS_NUM(RANKS),                      // 2
        .MC_RANKS_NUM(RANKS),                   // 2
        .NUM_PHYSICAL_PARTS(DQ_WIDTH / 8),      // 9 
        //.CALIB_EN("NO"),
        .tCK(1250), // 1250
        //.tPDM(),
        //.MIN_TOTAL_R2R_DELAY(),
        //.MAX_TOTAL_R2R_DELAY(),
        //.TOTAL_FBT_DELAY(),
        .MEM_PART_WIDTH("x8"),                  // x8
        .MC_CA_MIRROR("ON"),                    // "ON"
        //.SDRAM("DDR4"),
        //.DDR_SIM_MODEL("MICRON"),
        .DM_DBI("DM_NODBI"),                    // "DM_NODBI"
        .MC_REG_CTRL("ON")                      // "ON"
    )
    u_ddr4_rdimm_wrapper  
    (
        .ddr4_act_n(mem_act_n),          // input
        .ddr4_addr(mem_a),               // input
        .ddr4_ba(mem_ba),                // input
        .ddr4_bg(mem_bg),                // input
        .ddr4_par(mem_parity),           // input
        .ddr4_cke(mem_cke[RANKS-1:0]),   // input
        .ddr4_odt(mem_odt[RANKS-1:0]),   // input
        .ddr4_cs_n(mem_cs_n[RANKS-1:0]), // input
        .ddr4_ck_t(mem_ck_t),            // input
        .ddr4_ck_c(mem_ck_c),            // input
        .ddr4_reset_n(mem_reset_n),      // input
        .ddr4_dm_dbi_n(mem_dm_dbi_n),    // inout
        .ddr4_dq(mem_dq),                // inout
        .ddr4_dqs_t(mem_dqs_t),          // inout
        .ddr4_dqs_c(mem_dqs_c),          // inout
        .ddr4_alert_n(),                 // inout
        .scl(),                          // input
        .sa0(),                          // input
        .sa1(),                          // input
        .sa2(),                          // input
        .sda(),                          // inout
        .bfunc(),                        // input
        .vddspd()                        // input
    );

`ifndef NO_VCS_DUMP // dump for VCS DVE in VPD format
    initial
        if ( $test$plusargs("vpd_dump_all") ) begin
            $vcdplusfile("ddr_top.vpd");
            $vcdpluson(0);
            $vcdplusdeltacycleon;
            $vcdplusglitchon;
            $vcdplusmemon(0);
        end
`endif
`ifndef NO_VERDI_DUMP // dump for VERDI in FSDB format
    initial     
        if ( $test$plusargs("fsdb_dump_all") ) begin
            $fsdbDumpfile("ddr_top.fsdb");
            $fsdbDumpvars(0);
        end
`endif

    always @(*)
        if (ddr_phy_init_done) begin
            $display ("*************************************");
            $display ("PHY_INIT: DONE completed at %t", $time);
            $display ("*************************************");
        end
   
    // synthesis translate_on
   
endmodule
