/* --------------------------------------------------------------------
**
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
// File Version     :        $Revision: #27 $ 
// Revision: $Id: //dwh/DW_ocb/DW_axi_a2x/axi_dev_br/src/DW_axi_a2x.v#27 $ 
**
** --------------------------------------------------------------------
**
** File     : DW_axi_a2x.v
** Created  : Thu Jan 27 11:01:41 MET 2011
** Abstract :
**-------------------------------------------------------------------------------
**                  Architecture Diagram
**-------------------------------------------------------------------------------
**                                  Secondary Port
**
**  |------------------|      |--------------------------|
**  |                  |      |   Write Response Channel |    Write Response Channel
**  |                  |<-----|    DW_axi_a2x_b.v        |<-------------------------
**  |                  |      |--------------------------|
**  |                  |                  ^
**  |                  |                  |
**  |                  |      |--------------------------|
**  |                  |      |   Write Address Channel  |    Write Address Channel
**  |                  |----->|    DW_axi_a2x_aw.v       |------------------------->
**  |                  |      |--------------------------|
**  |                  |                  |
**  |                  |                  V
**  |                  |      |--------------------------|
**  |    AHB-AXI       |----->|    Write Data Channel    |    Write Data Channel
**  | DW_axi_a2x_h2x.v |      |      DW_axi_a2x_w.v      |------------------------->
**  |                  |      |--------------------------|
**  |                  |                  |
**  |                  |                  V
**  |                  |      |--------------------------|
**  |                  |----->|    Read Address Channel  |    Read Address Channel
**  |                  |      |      DW_axi_a2x_ar.v     |------------------------->
**  |                  |      |--------------------------|
**  |                  |                  |
**  |                  |                  V
**  |                  |      |--------------------------|
**  |                  |----->|    Read Data Channel     |    Read Data Channel
**  |                  |      |      DW_axi_a2x_r.v      |------------------------>
**  |------------------|      |--------------------------|
**
**--------------------------------------------------------------------------
*/
// spyglass disable_block Topology_02
// SMD: No asynchronous pin to pin paths
// SJ: hsel, awvalid_pp, wvalid_pp, arvalid_pp is used asynchronousl to evaluate cactive, which is as per the requirement

//==============================================================================
// Start License Usage
//==============================================================================
//==============================================================================
// End License Usage
//==============================================================================

`include "DW_axi_a2x_all_includes.vh"

module i_axi_a2x_DW_axi_a2x (

  //*************************************************************************************
  // Low Power Control
  //*************************************************************************************
                   busy_status,
                   //*************************************************************************************
                   // AXI Primary Port Clock & Reset Interface
                   //*************************************************************************************
                   clk_pp,
                   resetn_pp,
                   //*************************************************************************************
                   // AXI Write Address Primary Port Interface
                   //*************************************************************************************
                   awready_pp,
                   awvalid_pp,
                   awid_pp,
                   awaddr_pp,
                   awlen_pp,
                   awsize_pp,
                   awburst_pp,
                   awlock_pp,
                   awcache_pp,
                   awprot_pp,
                   //*************************************************************************************
                   // AXI Write Data Primary Port Interface
                   //*************************************************************************************
                   wready_pp,
                   wvalid_pp,
                   wlast_pp,
                   wdata_pp,
                   wstrb_pp,
                   //*************************************************************************************
                   // AXI Write Response Primary Port Interface
                   //*************************************************************************************
                   bready_pp,
                   bvalid_pp,
                   bid_pp,
                   bresp_pp,
                   //*************************************************************************************
                   // AXI Read Address Primary Port Interface
                   //*************************************************************************************
                   arready_pp,
                   arvalid_pp,
                   arid_pp,
                   araddr_pp,
                   arlen_pp,
                   arsize_pp,
                   arburst_pp,
                   arlock_pp,
                   arcache_pp,
                   arprot_pp,
                   //*************************************************************************************
                   // AXI Read Data Primary Port Interface
                   //*************************************************************************************
                   rready_pp,
                   rvalid_pp,
                   rlast_pp,
                   rid_pp,
                   rdata_pp,
                   rresp_pp,
                   //*************************************************************************************
                   // AXI Write Address Secondary Port Interface
                   //*************************************************************************************
                   awready_sp,
                   awvalid_sp,
                   awid_sp,
                   // The associated control signals are used to determine the addresses of the remaining transfers in a burst.
                   awaddr_sp,
                   awlen_sp,
                   awsize_sp,
                   awburst_sp,
                   awlock_sp,
                   awcache_sp,
                   awprot_sp,
                   //*************************************************************************************
                   // AXI Write Data Secondary Port Interface
                   //*************************************************************************************
                   wready_sp,
                   wvalid_sp,
                   wlast_sp,
                   wdata_sp,
                   wstrb_sp,
                   //*************************************************************************************
                   // AXI Write Response Secondary Port Interface
                   //*************************************************************************************
                   bready_sp,
                   bvalid_sp,
                   bid_sp,
                   bresp_sp,
                   //*************************************************************************************
                   // AXI Read Address Secondary Port Interface
                   //*************************************************************************************
                   arready_sp,
                   arvalid_sp,
                   arid_sp,
                   araddr_sp,
                   arlen_sp,
                   arsize_sp,
                   arburst_sp,
                   arlock_sp,
                   arcache_sp,
                   arprot_sp,
                   //*************************************************************************************
                   // AXI Read Data Secondary Port Interface
                   //*************************************************************************************
                   rready_sp,
                   rvalid_sp,
                   rlast_sp,
                   rid_sp,
                   rdata_sp,
                   rresp_sp
                   );


// spyglass enable_block Topology_02

  //*************************************************************************************
  //Derived Parameter Decelaration
  //*************************************************************************************
  parameter A2X_LOWPWR_IF = 0;
  parameter A2X_LOWPWR_NOPX_CNT = 2;

  parameter A2X_HCBUF_MODE = 1;
  parameter A2X_HCSNF_WLEN = 1;
  parameter A2X_HCSNF_RLEN = 1;
  parameter A2X_WBUF_MODE = 0;
  parameter A2X_RBUF_MODE = 0;
  parameter A2X_SNF_AWLEN_DFLT = 8;
  parameter A2X_SNF_ARLEN_DFLT = 8;
  parameter A2X_HINCR_HCBCNT = 1;
  parameter A2X_SINGLE_RBCNT = 1;
  parameter A2X_SINGLE_WBCNT = 1;
  parameter A2X_HINCR_WBCNT_MAX = 0;
  parameter A2X_HINCR_RBCNT_MAX = 0;

  parameter A2X_PP_MODE = 1;
  parameter A2X_UPSIZE = 0;
  parameter A2X_DOWNSIZE = 1;
  parameter A2X_LOCKED = 0;
  parameter A2X_AHB_LITE_MODE = 0;
  parameter A2X_NUM_AHBM = 8;
  parameter A2X_SPLIT_MODE = 1;
  parameter A2X_AHB_WBF_SPLIT = 1;

  parameter A2X_HREADY_LOW_PERIOD = 100;

  parameter A2X_RS_RATIO = 2;
  parameter A2X_RS_RATIO_LOG2 = 1;

  parameter A2X_NUM_UWID = 1;
  parameter A2X_NUM_URID = 1;

  parameter A2X_BRESP_MODE = 1;
  parameter A2X_BRESP_ORDER = 0;
  parameter A2X_READ_ORDER = 0;
  parameter A2X_READ_INTLEV = 0;

  parameter A2X_SP_OSAW_LIMIT = 2;
  parameter A2X_SP_OSAW_LIMIT_LOG2 = 1;

  parameter A2X_PP_OSAW_LIMIT = 15;
  parameter A2X_PP_OSAW_LIMIT_LOG2 = 4;

  parameter A2X_B_OSW_LIMIT = 15;
  parameter A2X_B_OSW_LIMIT_LOG2 = 4;

  parameter A2X_OSR_LIMIT = 15;
  parameter A2X_OSR_LIMIT_LOG2 = 4;

  parameter A2X_BOUNDARY_W = 12;
  parameter A2X_PP_AWIDTH = 32;
  parameter A2X_SP_AWIDTH = 32;
  parameter A2X_BLWIDTH = 8;
  parameter A2X_SP_BLWIDTH = 8;
  parameter A2X_HASBW = 0;
  parameter A2X_AWSBW = 0;
  parameter A2X_ARSBW = 0;
  parameter A2X_WSBW = 0;
  parameter A2X_RSBW = 0;
  parameter A2X_BSBW = 0;
  parameter A2X_QOS = 0;
  parameter A2X_REGION = 0;
  parameter A2X_INTERFACE_TYPE = 1;
  parameter A2X_AXI3 = 0;

  parameter A2X_PP_ENDIAN = 0;
  parameter A2X_SP_ENDIAN = 0;

  parameter A2X_PP_DWIDTH = 64;
  parameter A2X_PP_MAX_SIZE = 3;
  parameter A2X_PP_WSTRB_DW = 8;
  parameter A2X_PP_NUM_BYTES = 8;
  parameter A2X_PP_NUM_BYTES_LOG2 = 3;

  parameter A2X_SP_DWIDTH = 32;
  parameter A2X_SP_MAX_SIZE = 2;
  parameter A2X_SP_WSTRB_DW = 4;
  parameter A2X_SP_NUM_BYTES = 4;
  parameter A2X_SP_NUM_BYTES_LOG2 = 2;

  parameter A2X_CLK_MODE = 0;
  

  parameter A2X_AW_FIFO_DEPTH = 4;
  parameter A2X_AW_FIFO_DEPTH_LOG2 = 2;

  parameter A2X_AR_FIFO_DEPTH = 4;
  parameter A2X_AR_FIFO_DEPTH_LOG2 = 2;

  parameter A2X_WD_FIFO_DEPTH = 16;
  parameter A2X_WD_FIFO_DEPTH_LOG2 = 4;

  parameter A2X_RD_FIFO_DEPTH = 16;
  parameter A2X_RD_FIFO_DEPTH_LOG2 = 4;

  parameter A2X_LK_RD_FIFO_DEPTH = 4;
  parameter A2X_LK_RD_FIFO_DEPTH_LOG2 = 2;

  parameter A2X_BRESP_FIFO_DEPTH = 2;
  parameter A2X_BRESP_FIFO_DEPTH_LOG2 = 1;

  parameter A2X_RS_AW_TMO = 0;
  parameter A2X_RS_AR_TMO = 0;
  parameter A2X_RS_W_TMO = 0;
  parameter A2X_RS_B_TMO = 0;
  parameter A2X_RS_R_TMO = 0;

  // Sideband Bus always minimum of 1 bit internally. This is to facilitate
  // easier decoding of the A2X Payload buses. Bus driven to Zero if parameter
  // set to zero.
  localparam A2X_INT_HASBW                  = (`i_axi_a2x_A2X_A_UBW==0)? 1 : `i_axi_a2x_A2X_A_UBW;
  localparam A2X_INT_AWSBW                  = (A2X_PP_MODE==0)?  A2X_INT_HASBW : (A2X_AWSBW==0)? 1  : A2X_AWSBW;
  localparam A2X_INT_ARSBW                  = (A2X_PP_MODE==0)?  A2X_INT_HASBW : (A2X_ARSBW==0)? 1  : A2X_ARSBW;
  localparam A2X_INT_HWSBW                  = (`i_axi_a2x_A2X_W_UBW==0)? 1 : `i_axi_a2x_A2X_W_UBW;
  localparam A2X_INT_WSBW                   = (A2X_WSBW==0)?  1  : A2X_WSBW;
  localparam A2X_INT_HRSBW                  = (`i_axi_a2x_A2X_R_UBW==0)? 1 : `i_axi_a2x_A2X_R_UBW;
  localparam A2X_INT_RSBW                   = (A2X_RSBW==0)?  1  : A2X_RSBW;
  localparam A2X_INT_BSBW                   = (A2X_BSBW==0)?  1  : A2X_BSBW;

  // QOS,REGION and ACE-Lite(AXI4 related) signal bus minimum of 1 bit internally. 
  // This is to facilitate easier decoding of the A2X Payload buses.
  localparam A2X_INT_QOSW                  = (A2X_QOS==0)? 1  : 4;
  localparam A2X_INT_REGIONW               = (A2X_REGION==0)? 1  : 4;
  localparam A2X_INT_DOMAINW               = (A2X_INTERFACE_TYPE!=2)? 1  : 2;
  localparam A2X_INT_WSNOOPW               = (A2X_INTERFACE_TYPE!=2)? 1  : 3;
  localparam A2X_INT_RSNOOPW               = (A2X_INTERFACE_TYPE!=2)? 1  : 4;
  localparam A2X_INT_BARW                  = (A2X_INTERFACE_TYPE!=2)? 1  : 2;


  localparam A2X_HINCR_LEN_W                = 4;

  localparam A2X_INT_NUM_AHBM               = A2X_NUM_AHBM+1;  // Temporary Manager set to zero.    

  localparam A2X_HINCR_RBCNT_IDW            = (A2X_HINCR_HCBCNT==1)? 4 : (A2X_SINGLE_RBCNT==1)? 4 :  4*A2X_INT_NUM_AHBM; // AHB Read HINCR BCNT BUS Width
  localparam A2X_HINCR_WBCNT_IDW            = (A2X_HINCR_HCBCNT==1)? 4 : (A2X_SINGLE_WBCNT==1)? 4 :  4*A2X_INT_NUM_AHBM; // AHB Write HINCR BCNT BUS Width

  //*************************************************************************************
  // Software I/O Decelaration
  //*************************************************************************************

  //*************************************************************************************
  // Primary Port I/O Decelaration
  //*************************************************************************************
  input                                       clk_pp;
  input                                       resetn_pp;

  //-----------------------------AHB Interface------------------------------------------
  // AHB Interface



  //-----------------------------AXI Interface------------------------------------------
  output                                      awready_pp;
  input                                       awvalid_pp;
  input  [`i_axi_a2x_A2X_IDW-1:0]                       awid_pp;
  input  [A2X_PP_AWIDTH-1:0]                  awaddr_pp;
  input  [A2X_BLWIDTH-1:0]                    awlen_pp;
  input  [`i_axi_a2x_A2X_BSW-1:0]                       awsize_pp;
  input  [`i_axi_a2x_A2X_BTW-1:0]                       awburst_pp;
  input  [`i_axi_a2x_A2X_INT_LTW-1:0]                   awlock_pp;
  input  [`i_axi_a2x_A2X_CTW-1:0]                       awcache_pp;
  input  [`i_axi_a2x_A2X_PTW-1:0]                       awprot_pp;
  

  // AXI write data
  output                                      wready_pp;
  input                                       wvalid_pp;
  input                                       wlast_pp;
  input  [A2X_PP_DWIDTH-1:0]                  wdata_pp;
  input  [A2X_PP_WSTRB_DW-1:0]                wstrb_pp;

  // AXI write response
  input                                       bready_pp;
  output                                      bvalid_pp;
  output [`i_axi_a2x_A2X_IDW-1:0]                       bid_pp;
  output [`i_axi_a2x_A2X_BRESPW-1:0]                    bresp_pp;

  // AXI Address Read
  output                                      arready_pp;
  input                                       arvalid_pp;
  input  [`i_axi_a2x_A2X_IDW-1:0]                       arid_pp;
  input  [A2X_PP_AWIDTH-1:0]                  araddr_pp;
  input  [A2X_BLWIDTH-1:0]                    arlen_pp;
  input  [`i_axi_a2x_A2X_BSW-1:0]                       arsize_pp;
  input  [`i_axi_a2x_A2X_BTW-1:0]                       arburst_pp;
  input  [`i_axi_a2x_A2X_INT_LTW-1:0]                   arlock_pp;
  input  [`i_axi_a2x_A2X_CTW-1:0]                       arcache_pp;
  input  [`i_axi_a2x_A2X_PTW-1:0]                       arprot_pp;

  // AXI Read data
  input                                       rready_pp;
  output                                      rvalid_pp;
  output                                      rlast_pp;
  output [`i_axi_a2x_A2X_IDW-1:0]                       rid_pp;
  output [A2X_PP_DWIDTH-1:0]                  rdata_pp;
  output [`i_axi_a2x_A2X_RRESPW-1:0]                    rresp_pp;

  //*************************************************************************************
  // Secondary Port I/O Decelaration
  //*************************************************************************************

  input                                       awready_sp;
  output                                      awvalid_sp;
  output [`i_axi_a2x_A2X_SP_IDW-1:0]                    awid_sp;
  output [A2X_SP_AWIDTH-1:0]                  awaddr_sp;
  output [A2X_SP_BLWIDTH-1:0]                 awlen_sp;
  output [`i_axi_a2x_A2X_BSW-1:0]                       awsize_sp;
  output [`i_axi_a2x_A2X_BTW-1:0]                       awburst_sp;
  output [`i_axi_a2x_A2X_INT_LTW-1:0]                   awlock_sp;
  output [`i_axi_a2x_A2X_CTW-1:0]                       awcache_sp;
  output [`i_axi_a2x_A2X_PTW-1:0]                       awprot_sp;

  // AXI write data
  input                                       wready_sp;
  output                                      wvalid_sp;
  output                                      wlast_sp;
  output [A2X_SP_DWIDTH-1:0]                  wdata_sp;
  output [A2X_SP_WSTRB_DW-1:0]                wstrb_sp;

  // AXI write response
  output                                      bready_sp;
  input                                       bvalid_sp;
  input [`i_axi_a2x_A2X_SP_IDW-1:0]                     bid_sp;
  input [`i_axi_a2x_A2X_BRESPW-1:0]                     bresp_sp;

  // AXI Read Address
  input                                       arready_sp;
  output                                      arvalid_sp;
  output [`i_axi_a2x_A2X_SP_IDW-1:0]                    arid_sp;
  output [A2X_SP_AWIDTH-1:0]                  araddr_sp;
  output [A2X_SP_BLWIDTH-1:0]                 arlen_sp;
  output [`i_axi_a2x_A2X_BSW-1:0]                       arsize_sp;
  output [`i_axi_a2x_A2X_BTW-1:0]                       arburst_sp;
  output [`i_axi_a2x_A2X_INT_LTW-1:0]                   arlock_sp;
  output [`i_axi_a2x_A2X_CTW-1:0]                       arcache_sp;
  output [`i_axi_a2x_A2X_PTW-1:0]                       arprot_sp;

  // AXI Read data
  output                                      rready_sp;
  input                                       rvalid_sp;
  input                                       rlast_sp;
  input [`i_axi_a2x_A2X_SP_IDW-1:0]                     rid_sp;
  input [A2X_SP_DWIDTH-1:0]                   rdata_sp;
  input [`i_axi_a2x_A2X_RRESPW-1:0]                     rresp_sp;

  // Low Power Control
  output                                      busy_status; 

  //*************************************************************************************
  // Signal Decelaration
  //*************************************************************************************
  //These ports are used to connect the logic under certain configuration.
  //But this may not drive any net in some other configuration. 
  wire   [A2X_HINCR_LEN_W-1:0]                hincr_wbcnt_m0 = {A2X_HINCR_LEN_W{1'b0}};
  wire   [A2X_HINCR_LEN_W-1:0]                hincr_rbcnt_m0 = {A2X_HINCR_LEN_W{1'b0}};
  wire   [63:0]                               hincr_wbcnt_id;      // Setting to maximum of (15 Managers + Temporary Manager) * Width(4)
  wire   [63:0]                               hincr_rbcnt_id;  

  wire                                        hclk           = 1'b0;
  wire                                        hresetn        = 1'b1;
  wire                                        hsel           = 1'b0;
  wire   [`i_axi_a2x_A2X_IDW-1:0]                       hmaster        = {`i_axi_a2x_A2X_IDW{1'b0}};
  wire   [A2X_PP_AWIDTH-1:0]                  haddr          = {A2X_PP_AWIDTH{1'b0}};
  wire                                        hwrite         = 1'b0;
  wire                                        hmastlock      = 1'b0;
  wire   [`i_axi_a2x_A2X_HBLW-1:0]                      hburst         = {`i_axi_a2x_A2X_HBLW{1'b0}};
  wire                                        hresize        = 1'b0;
  wire   [1:0]                                htrans         = 2'b00;
  wire   [`i_axi_a2x_A2X_BSW-1:0]                       hsize          = {`i_axi_a2x_A2X_BSW{1'b0}};
  wire   [`i_axi_a2x_A2X_HPTW-1:0]                      hprot          = {`i_axi_a2x_A2X_HPTW{1'b0}};
  wire   [A2X_PP_DWIDTH-1:0]                  hwdata         = {A2X_PP_DWIDTH{1'b0}};

  wire                                        hready         = 1'b1;
  wire                                        hready_resp;
  wire   [`i_axi_a2x_A2X_HRESPW-1:0]                    hresp;
  wire   [A2X_PP_DWIDTH-1:0]                  hrdata;
  wire   [15:0]                               hsplit;

  wire   [A2X_INT_HASBW-1:0]                  hauser         = {A2X_INT_HASBW{1'b0}};
  wire   [A2X_INT_HWSBW-1:0]                  hwuser         = {A2X_INT_WSBW{1'b0}};
  wire   [A2X_INT_HRSBW-1:0]                  hruser;


  //-----------------------------AXI Interface------------------------------------------
    wire   [`i_axi_a2x_A2X_IDW-1:0]                     wid_pp              ={`i_axi_a2x_A2X_IDW{1'b0}};
    wire   [`i_axi_a2x_A2X_SP_IDW-1:0]                  wid_sp;
    wire   [`i_axi_a2x_A2X_LTW-1:0]                     awlock_core_pp      ={1'b0,awlock_pp};
    wire   [`i_axi_a2x_A2X_LTW-1:0]                     arlock_core_pp      ={1'b0,arlock_pp};

    wire   [A2X_INT_AWSBW-1:0]                awsideband_pp       = {A2X_INT_AWSBW{1'b0}};
    wire   [A2X_INT_AWSBW-1:0]                awsideband_sp;
    wire   [A2X_INT_AWSBW-1:0]                awuser_pp           = {A2X_INT_AWSBW{1'b0}};
    wire   [A2X_INT_AWSBW-1:0]                awuser_sp;

    wire   [A2X_INT_QOSW-1:0]                 awqos_pp            = {A2X_INT_QOSW{1'b0}};
    wire   [A2X_INT_QOSW-1:0]                 awqos_sp;            
    wire   [A2X_INT_REGIONW-1:0]              awregion_pp         = {A2X_INT_REGIONW{1'b0}};
    wire   [A2X_INT_REGIONW-1:0]              awregion_sp;
    wire   [A2X_INT_DOMAINW-1:0]              awdomain_pp         = {A2X_INT_DOMAINW{1'b0}};
    wire   [A2X_INT_WSNOOPW-1:0]              awsnoop_pp          = {A2X_INT_WSNOOPW{1'b0}};
    wire   [A2X_INT_BARW-1:0]                 awbar_pp            = {A2X_INT_BARW{1'b0}};
    wire   [A2X_INT_DOMAINW-1:0]              awdomain_sp;
    wire   [A2X_INT_WSNOOPW-1:0]              awsnoop_sp;
    wire   [A2X_INT_BARW-1:0]                 awbar_sp; 

    wire   [A2X_INT_WSBW-1:0]                 wsideband_pp       = {A2X_INT_WSBW{1'b0}};
    wire   [A2X_INT_WSBW-1:0]                 wsideband_sp;
    wire   [A2X_INT_WSBW-1:0]                 wuser_pp           = {A2X_INT_WSBW{1'b0}};
    wire   [A2X_INT_WSBW-1:0]                 wuser_sp;

    wire   [A2X_INT_BSBW-1:0]                 bsideband_pp;
    wire   [A2X_INT_BSBW-1:0]                 bsideband_sp        = {A2X_INT_BSBW{1'b0}};
    wire   [A2X_INT_BSBW-1:0]                 buser_pp;
    wire   [A2X_INT_BSBW-1:0]                 buser_sp            = {A2X_INT_BSBW{1'b0}};

    wire   [A2X_INT_ARSBW-1:0]                 arsideband_pp       = {A2X_INT_ARSBW{1'b0}};
    wire   [A2X_INT_ARSBW-1:0]                 arsideband_sp;
    wire   [A2X_INT_ARSBW-1:0]                 aruser_pp           = {A2X_INT_ARSBW{1'b0}};
    wire   [A2X_INT_ARSBW-1:0]                 aruser_sp;

    wire   [A2X_INT_QOSW-1:0]                 arqos_pp            = {A2X_INT_QOSW{1'b0}};
    wire   [A2X_INT_QOSW-1:0]                 arqos_sp;            
    wire   [A2X_INT_REGIONW-1:0]              arregion_pp         = {A2X_INT_REGIONW{1'b0}};
    wire   [A2X_INT_REGIONW-1:0]              arregion_sp;
    wire   [A2X_INT_DOMAINW-1:0]              ardomain_pp         = {A2X_INT_DOMAINW{1'b0}};
    wire   [A2X_INT_RSNOOPW-1:0]              arsnoop_pp          = {A2X_INT_RSNOOPW{1'b0}};
    wire   [A2X_INT_BARW-1:0]                 arbar_pp            = {A2X_INT_BARW{1'b0}};
    wire   [A2X_INT_DOMAINW-1:0]              ardomain_sp;
    wire   [A2X_INT_RSNOOPW-1:0]              arsnoop_sp;
    wire   [A2X_INT_BARW-1:0]                 arbar_sp;            

    wire   [A2X_INT_RSBW-1:0]                 rsideband_pp;
    wire   [A2X_INT_RSBW-1:0]                 rsideband_sp        = {A2X_INT_RSBW{1'b0}};
    wire   [A2X_INT_RSBW-1:0]                 ruser_pp;
    wire   [A2X_INT_RSBW-1:0]                 ruser_sp            = {A2X_INT_RSBW{1'b0}};

 
     wire                                     awresize_pp        =  1'b0;
     wire                                     arresize_pp        =  1'b0;


  // Low Power Control
  wire                                        csysreq           = 1'b1;
  wire                                        csysack;
  wire                                        cactive; 
  wire                                        busy_status;
  wire    [`i_axi_a2x_A2X_INT_LTW-1:0]                  awlock_core_sp;
  wire    [`i_axi_a2x_A2X_INT_LTW-1:0]                  arlock_core_sp;

  //*************************************************************************************
  // AHB Read INCR Ports
  //*************************************************************************************
  assign hincr_rbcnt_id = {60'd0, A2X_HINCR_RBCNT_MAX};
  //*************************************************************************************
  // AHB Write INCR Ports
  //*************************************************************************************
  assign hincr_wbcnt_id = {60'd0, A2X_HINCR_WBCNT_MAX};
     assign awlock_sp = awlock_core_sp;
     assign arlock_sp = arlock_core_sp;

  //*************************************************************************************
  // A2X Instance
  //*************************************************************************************
   i_axi_a2x_DW_axi_a2x_core
    #(
      .A2X_LOWPWR_IF                           (A2X_LOWPWR_IF)
     ,.A2X_LOWPWR_NOPX_CNT                     (A2X_LOWPWR_NOPX_CNT)

     ,.A2X_HCBUF_MODE                          (A2X_HCBUF_MODE)
     ,.A2X_HCSNF_WLEN                          (A2X_HCSNF_WLEN)
     ,.A2X_HCSNF_RLEN                          (A2X_HCSNF_RLEN)
     ,.A2X_WBUF_MODE                           (A2X_WBUF_MODE)
     ,.A2X_RBUF_MODE                           (A2X_RBUF_MODE)
     ,.A2X_SNF_AWLEN_DFLT                      (A2X_SNF_AWLEN_DFLT)
     ,.A2X_SNF_ARLEN_DFLT                      (A2X_SNF_ARLEN_DFLT)
     ,.A2X_HINCR_HCBCNT                        (A2X_HINCR_HCBCNT)
     ,.A2X_SINGLE_RBCNT                        (A2X_SINGLE_RBCNT)
     ,.A2X_SINGLE_WBCNT                        (A2X_SINGLE_WBCNT)  
     ,.A2X_HINCR_WBCNT_MAX                     (A2X_HINCR_WBCNT_MAX)
     ,.A2X_HINCR_RBCNT_MAX                     (A2X_HINCR_RBCNT_MAX)
     ,.A2X_PP_MODE                             (A2X_PP_MODE)
     ,.A2X_UPSIZE                              (A2X_UPSIZE)
     ,.A2X_DOWNSIZE                            (A2X_DOWNSIZE)
     ,.A2X_LOCKED                              (A2X_LOCKED)
     ,.A2X_AHB_LITE_MODE                       (A2X_AHB_LITE_MODE)
     ,.A2X_SPLIT_MODE                          (A2X_SPLIT_MODE)
     ,.A2X_AHB_WBF_SPLIT                       (A2X_AHB_WBF_SPLIT)
     ,.A2X_NUM_AHBM                            (A2X_INT_NUM_AHBM)
     ,.A2X_HREADY_LOW_PERIOD                   (A2X_HREADY_LOW_PERIOD)
     ,.A2X_RS_RATIO                            (A2X_RS_RATIO)
     ,.A2X_RS_RATIO_LOG2                       (A2X_RS_RATIO_LOG2)
     ,.A2X_NUM_UWID                            (A2X_NUM_UWID)
     ,.A2X_NUM_URID                            (A2X_NUM_URID) 
     ,.A2X_BRESP_MODE                          (A2X_BRESP_MODE) 
     ,.A2X_BRESP_ORDER                         (A2X_BRESP_ORDER) 
     ,.A2X_READ_ORDER                          (A2X_READ_ORDER) 
     ,.A2X_READ_INTLEV                         (A2X_READ_INTLEV) 
     ,.A2X_SP_OSAW_LIMIT                       (A2X_SP_OSAW_LIMIT) 
     ,.A2X_SP_OSAW_LIMIT_LOG2                  (A2X_SP_OSAW_LIMIT_LOG2) 
     ,.A2X_PP_OSAW_LIMIT                       (A2X_PP_OSAW_LIMIT) 
     ,.A2X_PP_OSAW_LIMIT_LOG2                  (A2X_PP_OSAW_LIMIT_LOG2) 
     ,.A2X_B_OSW_LIMIT                         (A2X_B_OSW_LIMIT) 
     ,.A2X_B_OSW_LIMIT_LOG2                    (A2X_B_OSW_LIMIT_LOG2) 
     ,.A2X_OSR_LIMIT                           (A2X_OSR_LIMIT) 
     ,.A2X_OSR_LIMIT_LOG2                      (A2X_OSR_LIMIT_LOG2) 
     ,.BOUNDARY_W                              (A2X_BOUNDARY_W)
     ,.A2X_PP_ENDIAN                           (A2X_PP_ENDIAN)
     ,.A2X_SP_ENDIAN                           (A2X_SP_ENDIAN)
     ,.A2X_AW                                  (A2X_PP_AWIDTH)
     ,.A2X_SP_AW                               (A2X_SP_AWIDTH)
     ,.A2X_BLW                                 (A2X_BLWIDTH)
     ,.A2X_SP_BLW                              (A2X_SP_BLWIDTH)
     ,.A2X_HASBW                               (A2X_INT_HASBW)
     ,.A2X_AWSBW                               (A2X_INT_AWSBW)
     ,.A2X_ARSBW                               (A2X_INT_ARSBW)
     ,.A2X_HWSBW                               (A2X_INT_HWSBW)
     ,.A2X_WSBW                                (A2X_INT_WSBW)
     ,.A2X_HRSBW                               (A2X_INT_HRSBW)
     ,.A2X_RSBW                                (A2X_INT_RSBW)
     ,.A2X_BSBW                                (A2X_INT_BSBW)
     ,.A2X_PP_DW                               (A2X_PP_DWIDTH)
     ,.A2X_PP_MAX_SIZE                         (A2X_PP_MAX_SIZE)
     ,.A2X_PP_WSTRB_DW                         (A2X_PP_WSTRB_DW)
     ,.A2X_PP_NUM_BYTES                        (A2X_PP_NUM_BYTES)
     ,.A2X_PP_NUM_BYTES_LOG2                   (A2X_PP_NUM_BYTES_LOG2)
     ,.A2X_SP_DW                               (A2X_SP_DWIDTH)
     ,.A2X_SP_MAX_SIZE                         (A2X_SP_MAX_SIZE)
     ,.A2X_SP_WSTRB_DW                         (A2X_SP_WSTRB_DW)
     ,.A2X_SP_NUM_BYTES                        (A2X_SP_NUM_BYTES)
     ,.A2X_SP_NUM_BYTES_LOG2                   (A2X_SP_NUM_BYTES_LOG2)
     ,.A2X_CLK_MODE                            (A2X_CLK_MODE)
     ,.A2X_AW_FIFO_DEPTH                       (A2X_AW_FIFO_DEPTH)
     ,.A2X_AW_FIFO_DEPTH_LOG2                  (A2X_AW_FIFO_DEPTH_LOG2)
     ,.A2X_AR_FIFO_DEPTH                       (A2X_AR_FIFO_DEPTH)
     ,.A2X_AR_FIFO_DEPTH_LOG2                  (A2X_AR_FIFO_DEPTH_LOG2)
     ,.A2X_WD_FIFO_DEPTH                       (A2X_WD_FIFO_DEPTH)
     ,.A2X_WD_FIFO_DEPTH_LOG2                  (A2X_WD_FIFO_DEPTH_LOG2)
     ,.A2X_RD_FIFO_DEPTH                       (A2X_RD_FIFO_DEPTH)
     ,.A2X_RD_FIFO_DEPTH_LOG2                  (A2X_RD_FIFO_DEPTH_LOG2)
     ,.A2X_LK_RD_FIFO_DEPTH                    (A2X_LK_RD_FIFO_DEPTH)
     ,.A2X_LK_RD_FIFO_DEPTH_LOG2               (A2X_LK_RD_FIFO_DEPTH_LOG2)
     ,.A2X_BRESP_FIFO_DEPTH                    (A2X_BRESP_FIFO_DEPTH)
     ,.A2X_BRESP_FIFO_DEPTH_LOG2               (A2X_BRESP_FIFO_DEPTH_LOG2)
     ,.A2X_RS_AW_TMO                           (A2X_RS_AW_TMO)
     ,.A2X_RS_AR_TMO                           (A2X_RS_AR_TMO)
     ,.A2X_RS_W_TMO                            (A2X_RS_W_TMO)
     ,.A2X_RS_B_TMO                            (A2X_RS_B_TMO)
     ,.A2X_RS_R_TMO                            (A2X_RS_R_TMO)
     ,.A2X_AXI3                                (A2X_AXI3)
     ,.A2X_QOSW                                (A2X_INT_QOSW)
     ,.A2X_REGIONW                             (A2X_INT_REGIONW)
     ,.A2X_DOMAINW                             (A2X_INT_DOMAINW)
     ,.A2X_WSNOOPW                             (A2X_INT_WSNOOPW)
     ,.A2X_RSNOOPW                             (A2X_INT_RSNOOPW)
     ,.A2X_BARW                                (A2X_INT_BARW)
   ) U_a2x_core (
     .clk_pp                                  (clk_pp),
     .resetn_pp                               (resetn_pp),

      // Primary Port AHB Interface
     .hsel                                    (hsel),
     .hmaster                                 (hmaster),
     .haddr                                   (haddr),
     .hwrite                                  (hwrite),
     .hmastlock                               (hmastlock),
     .hburst                                  (hburst),
     .hresize                                 (hresize),
     .htrans                                  (htrans),
     .hsize                                   (hsize),
     .hprot                                   (hprot),
     .hwdata                                  (hwdata),
     .hready                                  (hready),
     .hready_resp                             (hready_resp),
     .hresp                                   (hresp),
     .hrdata                                  (hrdata),
     .hsplit                                  (hsplit),
     .haddr_sb                                (hauser),
     .hwdata_sb                               (hwuser),
     .hrdata_sb                               (hruser),

     //  HINCR Ports
     .hincr_wbcnt_id                          (hincr_wbcnt_id[A2X_HINCR_WBCNT_IDW-1:0]),
     .hincr_rbcnt_id                          (hincr_rbcnt_id[A2X_HINCR_RBCNT_IDW-1:0]),

     // Primary Port AW Channel Interface
     .awready_pp                              (awready_pp),
     .awvalid_pp                              (awvalid_pp),
     .awid_pp                                 (awid_pp),
     .awaddr_pp                               (awaddr_pp),
     .awlen_pp                                (awlen_pp),
     .awsize_pp                               (awsize_pp),
     .awburst_pp                              (awburst_pp),
     .awlock_pp                               (awlock_core_pp),
     .awcache_pp                              (awcache_pp),
     .awprot_pp                               (awprot_pp),
     .awresize_pp                             (awresize_pp),
     .awsideband_pp                           (awsideband_pp),
     .awuser_pp                               (awuser_pp),
     .awqos_pp                                (awqos_pp),
     .awregion_pp                             (awregion_pp),
     .awdomain_pp                             (awdomain_pp),
     .awsnoop_pp                              (awsnoop_pp),
     .awbar_pp                                (awbar_pp),
     // Primary Port W Channel Interface
     .wvalid_pp                               (wvalid_pp),
     .wready_pp                               (wready_pp),
     .wid_pp                                  (wid_pp),
     .wlast_pp                                (wlast_pp),
     .wdata_pp                                (wdata_pp),
     .wstrb_pp                                (wstrb_pp),
     .wsideband_pp                            (wsideband_pp),
     .wuser_pp                                (wuser_pp),
     // Primary Port B Channel Interface
     .bready_pp                               (bready_pp),
     .bvalid_pp                               (bvalid_pp),
     .bid_pp                                  (bid_pp),
     .bresp_pp                                (bresp_pp),
     .bsideband_pp                            (bsideband_pp),
     .buser_pp                                (buser_pp),
     // Primary Port AR Channel Interface
     .arvalid_pp                              (arvalid_pp),
     .arready_pp                              (arready_pp),
     .arid_pp                                 (arid_pp),
     .araddr_pp                               (araddr_pp),
     .arlen_pp                                (arlen_pp),
     .arsize_pp                               (arsize_pp),
     .arburst_pp                              (arburst_pp),
     .arlock_pp                               (arlock_core_pp),
     .arcache_pp                              (arcache_pp),
     .arprot_pp                               (arprot_pp),
     .arresize_pp                             (arresize_pp),
     .arsideband_pp                           (arsideband_pp),
     .aruser_pp                               (aruser_pp),
     .arqos_pp                                (arqos_pp),
     .arregion_pp                             (arregion_pp),
     .ardomain_pp                             (ardomain_pp),
     .arsnoop_pp                              (arsnoop_pp),
     .arbar_pp                                (arbar_pp),

     // Primary Port R Channel Interface
     .rready_pp                               (rready_pp),
     .rvalid_pp                               (rvalid_pp),
     .rlast_pp                                (rlast_pp),
     .rid_pp                                  (rid_pp),
     .rdata_pp                                (rdata_pp),
     .rresp_pp                                (rresp_pp),
     .rsideband_pp                            (rsideband_pp),
     .ruser_pp                                (ruser_pp),

     // Secondary Port Interface
     .clk_sp                                  (clk_pp),
     .resetn_sp                               (resetn_pp),

     // Secondary Port AW Channel Interface
     .awvalid_sp                              (awvalid_sp),
     .awready_sp                              (awready_sp),
     .awid_sp                                 (awid_sp),
     .awaddr_sp                               (awaddr_sp),
     .awlen_sp                                (awlen_sp),
     .awsize_sp                               (awsize_sp),
     .awburst_sp                              (awburst_sp),
     .awlock_sp                               (awlock_core_sp),
     .awcache_sp                              (awcache_sp),
     .awprot_sp                               (awprot_sp),
     .awsideband_sp                           (awsideband_sp),
     .awuser_sp                               (awuser_sp),
     .awqos_sp                                (awqos_sp),
     .awregion_sp                             (awregion_sp),
     .awdomain_sp                             (awdomain_sp),
     .awsnoop_sp                              (awsnoop_sp),
     .awbar_sp                                (awbar_sp),
     // Secondary Port W Channel Interface
     .wready_sp                               (wready_sp),
     .wvalid_sp                               (wvalid_sp),
     .wlast_sp                                (wlast_sp),
     .wid_sp                                  (wid_sp),
     .wdata_sp                                (wdata_sp),
     .wstrb_sp                                (wstrb_sp),
     .wsideband_sp                            (wsideband_sp),
     .wuser_sp                                (wuser_sp),

     // Secondary Port B Channel Interface
     .bvalid_sp                               (bvalid_sp),
     .bready_sp                               (bready_sp),
     .bid_sp                                  (bid_sp[`i_axi_a2x_A2X_IDW-1:0]),
     .bresp_sp                                (bresp_sp),
     .bsideband_sp                            (bsideband_sp),
     .buser_sp                                (buser_sp),

     // Secondary Port AR Channel Interface
     .arvalid_sp                              (arvalid_sp),
     .arready_sp                              (arready_sp),
     .arid_sp                                 (arid_sp),
     .araddr_sp                               (araddr_sp),
     .arlen_sp                                (arlen_sp),
     .arsize_sp                               (arsize_sp),
     .arburst_sp                              (arburst_sp),
     .arlock_sp                               (arlock_core_sp),
     .arcache_sp                              (arcache_sp),
     .arprot_sp                               (arprot_sp),
     .arsideband_sp                           (arsideband_sp),
     .aruser_sp                               (aruser_sp),
     .arqos_sp                                (arqos_sp),
     .arregion_sp                             (arregion_sp),
     .ardomain_sp                             (ardomain_sp),
     .arsnoop_sp                              (arsnoop_sp),
     .arbar_sp                                (arbar_sp),

     // Secondary Port R Channel Interface
     .rvalid_sp                               (rvalid_sp),
     .rready_sp                               (rready_sp),
     .rlast_sp                                (rlast_sp),
     .rid_sp                                  (rid_sp[`i_axi_a2x_A2X_IDW-1:0]),
     .rdata_sp                                (rdata_sp),
     .rsideband_sp                            (rsideband_sp),
     .ruser_sp                                (ruser_sp),
     .rresp_sp                                (rresp_sp),

     .csysreq                                 (csysreq),
     .csysack                                 (csysack),
     .cactive                                 (cactive),
     .busy_status_o                           (busy_status)
   );

endmodule
//Revision: $Id: //dwh/DW_ocb/DW_axi_a2x/axi_dev_br/src/DW_axi_a2x.v#27 $

