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
// File Version     :        $Revision: #12 $ 
// Revision: $Id: //dwh/DW_ocb/DW_axi_a2x/axi_dev_br/src/DW_axi_a2x_core.v#12 $ 
**
** --------------------------------------------------------------------
**
** File     : DW_axi_a2x_core.v
** Created  : Thu Jan 27 11:01:41 MET 2011
** Abstract :
**
** --------------------------------------------------------------------
*/

/* --------------------------------------------------------------------
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
`include "DW_axi_a2x_all_includes.vh"

module i_axi_a2x_1_DW_axi_a2x_core (/*AUTOARG*/
   // Outputs
   hready_resp, hresp, hrdata, hsplit, hrdata_sb, awready_pp, 
   wready_pp, bvalid_pp, bid_pp, bresp_pp, bsideband_pp,buser_pp, arready_pp, 
   rvalid_pp, rlast_pp, rid_pp, rdata_pp, rresp_pp, rsideband_pp, ruser_pp,
   awvalid_sp, awid_sp, awaddr_sp, awlen_sp, awsize_sp, awburst_sp, 
   awlock_sp, awcache_sp, awprot_sp, awsideband_sp, awuser_sp, awqos_sp,
   awregion_sp, awdomain_sp, awsnoop_sp, awbar_sp,wvalid_sp, 
   wlast_sp, wid_sp, wdata_sp, wstrb_sp, wsideband_sp, wuser_sp, bready_sp, 
   arvalid_sp, arid_sp, araddr_sp, arlen_sp, arsize_sp, arburst_sp, 
   arlock_sp, arcache_sp, arprot_sp, arsideband_sp, aruser_sp, arqos_sp,
   arregion_sp, ardomain_sp, arsnoop_sp, arbar_sp, rready_sp, 
   busy_status_o, cactive, csysack,

   // Inputs
   hincr_wbcnt_id, hincr_rbcnt_id, clk_pp, resetn_pp, hsel, hmaster, 
   haddr, hwrite, hmastlock, hburst, hresize, htrans, hsize, hprot, 
   hwdata, hready, haddr_sb, hwdata_sb, awvalid_pp, 
   awid_pp, 
   awaddr_pp, 
   awlen_pp, 
   awsize_pp, 
   awburst_pp,
   awlock_pp, 
   awcache_pp, 
   awprot_pp, 
   awresize_pp, 
   awsideband_pp,
   awuser_pp,
   awqos_pp,
   awregion_pp,
   awdomain_pp,
   awsnoop_pp,
   awbar_pp,
   wvalid_pp, 
   wlast_pp,
   wid_pp, 
   wdata_pp, 
   wstrb_pp,
   wsideband_pp,
   wuser_pp, 
   bready_pp, 
   arvalid_pp, 
   arid_pp, 
   araddr_pp, 
   arlen_pp, 
   arsize_pp, 
   arburst_pp, 
   arlock_pp, 
   arcache_pp, 
   arprot_pp, 
   arresize_pp, 
   arsideband_pp,
   aruser_pp,
   arqos_pp,
   arregion_pp,
   ardomain_pp,
   arsnoop_pp,
   arbar_pp,
   rready_pp, 
   clk_sp, resetn_sp, awready_sp, wready_sp, bvalid_sp, 
   bid_sp, 
   bresp_sp, bsideband_sp,
   buser_sp, 
   arready_sp, rvalid_sp, rlast_sp, 
   rid_sp, 
   rdata_sp, rresp_sp, rsideband_sp,
   ruser_sp,
   csysreq 
   );

  //*************************************************************************************
  //Derived Parameter Decelaration
  //*************************************************************************************
  parameter  A2X_LOWPWR_IF                 = 0;
  parameter  A2X_LOWPWR_NOPX_CNT           = 2;

  parameter  A2X_HCBUF_MODE                 = 0; 
  parameter  A2X_HCSNF_WLEN                 = 0; 
  parameter  A2X_HCSNF_RLEN                 = 0; 
  parameter  A2X_WBUF_MODE                  = 0; 
  parameter  A2X_RBUF_MODE                  = 0; 
  parameter  A2X_SNF_AWLEN_DFLT             = 4; 
  parameter  A2X_SNF_ARLEN_DFLT             = 4; 
  parameter  A2X_HINCR_WBCNT_MAX            = 8; 
  parameter  A2X_HINCR_RBCNT_MAX            = 8; 

  parameter  A2X_HINCR_HCBCNT               = 1; 
  parameter  A2X_SINGLE_RBCNT               = 0;
  parameter  A2X_SINGLE_WBCNT               = 0;

  parameter  A2X_PP_MODE                    = 1;   // 0 = AHB 1 = AXI
  parameter  A2X_UPSIZE                     = 0;   // 0 = Not Upsized 1 = Upsized
  parameter  A2X_DOWNSIZE                   = 0;   // 0 = Not Downsized 1 Downsized
  parameter  A2X_LOCKED                     = 0;   // A2X Supports Locked Transactions
  
  parameter  A2X_AHB_LITE_MODE              = 0;   
  parameter  A2X_NUM_AHBM                   = 2;   
  parameter  A2X_SPLIT_MODE                 = 1;
  parameter  A2X_AHB_WBF_SPLIT              = 1;
  parameter  A2X_HREADY_LOW_PERIOD          = 8; 

  parameter  A2X_RS_RATIO                   = 1; 
  parameter  A2X_RS_RATIO_LOG2              = 1;

  
  parameter  A2X_NUM_UWID                   = 1;
  parameter  A2X_NUM_URID                   = 1; 

  parameter  A2X_BRESP_MODE                 = 1;
  parameter  A2X_BRESP_ORDER                = 1;
  parameter  A2X_READ_ORDER                 = 1; 
  parameter  A2X_READ_INTLEV                = 1; 

  parameter  A2X_PP_OSAW_LIMIT              = 8;
  parameter  A2X_PP_OSAW_LIMIT_LOG2         = 3;

  parameter  A2X_B_OSW_LIMIT                = 8;
  parameter  A2X_B_OSW_LIMIT_LOG2           = 3;

  parameter  A2X_SP_OSAW_LIMIT              = 8;
  parameter  A2X_SP_OSAW_LIMIT_LOG2         = 3;
  
  parameter  A2X_OSR_LIMIT                  = 8;
  parameter  A2X_OSR_LIMIT_LOG2             = 3;
  
  parameter  BOUNDARY_W                     = 12; 
  parameter  A2X_AW                         = 32;  // Address Width
  parameter  A2X_SP_AW                      = 32;  // Address Width
  parameter  A2X_BLW                        = 4;   // Burst Length Width
  parameter  A2X_SP_BLW                     = 4;   // Burst Length Width
  
  parameter  A2X_HASBW                      = 1;   // Address Sideband Width
  parameter  A2X_AWSBW                      = 1;   // Address Sideband Width
  parameter  A2X_ARSBW                      = 1;   // Address sideband width
  parameter  A2X_HWSBW                      = 1;   // Write data Sideband Width
  parameter  A2X_WSBW                       = 1;  
  parameter  A2X_HRSBW                      = 1;   // Read data Sideband Width
  parameter  A2X_RSBW                       = 1;  
  parameter  A2X_BSBW                       = 1;  

  
  parameter  A2X_PP_DW                      = 32;
  parameter  A2X_PP_MAX_SIZE                = 2;
  parameter  A2X_PP_WSTRB_DW                = 4;
  parameter  A2X_PP_NUM_BYTES               = 4;
  parameter  A2X_PP_NUM_BYTES_LOG2          = 2;

  
  parameter  A2X_SP_DW                      = 32;
  parameter  A2X_SP_MAX_SIZE                = 2;
  parameter  A2X_SP_WSTRB_DW                = 4;
  parameter  A2X_SP_NUM_BYTES               = 4;
  parameter  A2X_SP_NUM_BYTES_LOG2          = 2;

  
  parameter  A2X_CLK_MODE                   = 0;

  
  parameter  A2X_AW_FIFO_DEPTH              = 8;
  parameter  A2X_AW_FIFO_DEPTH_LOG2         = 3;

  
  parameter  A2X_AR_FIFO_DEPTH              = 8;
  parameter  A2X_AR_FIFO_DEPTH_LOG2         = 3;

  
  parameter  A2X_WD_FIFO_DEPTH              = 8;
  parameter  A2X_WD_FIFO_DEPTH_LOG2         = 3;

  
  parameter  A2X_RD_FIFO_DEPTH              = 8;
  parameter  A2X_RD_FIFO_DEPTH_LOG2         = 3;

  
  parameter  A2X_LK_RD_FIFO_DEPTH           = 8;
  parameter  A2X_LK_RD_FIFO_DEPTH_LOG2      = 3;
  
  
  parameter  A2X_BRESP_FIFO_DEPTH           = 4;
  parameter  A2X_BRESP_FIFO_DEPTH_LOG2      = 2;

  // AHB/AXI Endian Convert
  parameter  A2X_PP_ENDIAN                  = 0; 
  parameter  A2X_SP_ENDIAN                  = 0; 

  // Register Slice Parameters
  // 0 - pass through mode
  // 1 - forward timing mode
  // 2 - full timing mode
  // 3 - backward timing mode
  parameter A2X_RS_AW_TMO                   = 0;
  parameter A2X_RS_AR_TMO                   = 0;
  parameter A2X_RS_W_TMO                    = 0;
  parameter A2X_RS_B_TMO                    = 0;
  parameter A2X_RS_R_TMO                    = 0;
  
  //AXI3 configuration parameter
  parameter A2X_AXI3                        = 1;
  // AXI4 Related parameters
  parameter  A2X_QOSW                       = 1; 
  parameter  A2X_REGIONW                    = 1;
  parameter  A2X_DOMAINW                    = 1;
  parameter  A2X_WSNOOPW                    = 1;
  parameter  A2X_RSNOOPW                    = 1;
  parameter  A2X_BARW                       = 1;

  // Creating Local Parameters to override parameters based on Configuration
  localparam AHB_SPLIT_MODE                 = (A2X_AHB_LITE_MODE==1)? 0 : A2X_SPLIT_MODE;
  localparam BRESP_ORDER                    = (A2X_AHB_LITE_MODE==1)? 0 : A2X_BRESP_ORDER;
  localparam READ_ORDER                     = (A2X_AHB_LITE_MODE==1)? 0 : (A2X_READ_INTLEV==1)? 1 : A2X_READ_ORDER;

  // Sideband Bus always minimum of 1 bit internally. This is to facilitate
  // easier decoding of the A2X Payload buses. Bus driven to Zero if parameter
  // set to zero.
  localparam A2X_INT_HASBW                  = (`i_axi_a2x_1_A2X_A_UBW==0)? 1 : `i_axi_a2x_1_A2X_A_UBW;   
  localparam A2X_INT_AWSBW                  = (A2X_PP_MODE==0)?  A2X_INT_HASBW : (A2X_AWSBW==0)? 1  : A2X_AWSBW;   
  localparam A2X_INT_ARSBW                  = (A2X_PP_MODE==0)?  A2X_INT_HASBW : (A2X_ARSBW==0)? 1  : A2X_ARSBW;
  localparam A2X_INT_HWSBW                  = (`i_axi_a2x_1_A2X_W_UBW==0)? 1 : `i_axi_a2x_1_A2X_W_UBW;
  localparam A2X_INT_WSBW                   = (A2X_WSBW==0)?  1  : A2X_WSBW;
  localparam A2X_INT_PPWSBW                 = (A2X_PP_MODE==0)? A2X_INT_HWSBW : A2X_INT_WSBW; 
  localparam A2X_INT_HRSBW                  = (`i_axi_a2x_1_A2X_R_UBW==0)? 1 : `i_axi_a2x_1_A2X_R_UBW;
  localparam A2X_INT_RSBW                   = (A2X_RSBW==0)?  1  : A2X_RSBW;  
  localparam A2X_INT_PPRSBW                 = (A2X_PP_MODE==0)? A2X_INT_HRSBW : A2X_INT_RSBW;
  localparam A2X_INT_BSBW                   = (A2X_BSBW==0)?  1  : A2X_BSBW;

  // Max SNF Lengths 
  // - Cannot be greater that A2X_BLW
  // - cannot be greather than Read FIFO Depth for SNF ARLEN
  localparam SNF_AWLEN_DFLT                 = (A2X_BLW<A2X_SNF_AWLEN_DFLT) ? A2X_BLW : A2X_SNF_AWLEN_DFLT; 
  localparam SNF_ARLEN_DFLT                 = (A2X_BLW<A2X_SNF_ARLEN_DFLT) ? A2X_BLW : A2X_SNF_ARLEN_DFLT; 

  // Configuration Parameter
  localparam A2X_EQSIZED                    = (A2X_PP_DW==A2X_SP_DW)? 1 : 0; 

  // Bresp Payload
  localparam A2X_B_PYLD_W                   = A2X_INT_BSBW + `i_axi_a2x_1_A2X_IDW + `i_axi_a2x_1_A2X_BRESPW;

  // AW payload in AXI
  localparam A2X_AW_PYLD_W                  = A2X_BARW + A2X_WSNOOPW + A2X_DOMAINW + A2X_REGIONW + A2X_QOSW +`i_axi_a2x_1_A2X_HBTYPE_W  +
                                              A2X_INT_AWSBW + `i_axi_a2x_1_A2X_IDW + A2X_AW  + `i_axi_a2x_1_A2X_RSW + A2X_BLW + `i_axi_a2x_1_A2X_BSW + 
                                              `i_axi_a2x_1_A2X_BTW + `i_axi_a2x_1_A2X_LTW + `i_axi_a2x_1_A2X_CTW + `i_axi_a2x_1_A2X_PTW;
  // AW payload in AHB
  localparam A2X_AW_PYLD_W_AHB              = `i_axi_a2x_1_A2X_HBTYPE_W + A2X_INT_AWSBW + `i_axi_a2x_1_A2X_IDW + A2X_AW  + `i_axi_a2x_1_A2X_RSW + A2X_BLW + `i_axi_a2x_1_A2X_BSW + 
                                              `i_axi_a2x_1_A2X_BTW + `i_axi_a2x_1_A2X_LTW + `i_axi_a2x_1_A2X_CTW + `i_axi_a2x_1_A2X_PTW;
  // AR Payload in AXI                                     
  localparam A2X_AR_PYLD_W                  = A2X_BARW + A2X_RSNOOPW + A2X_DOMAINW + A2X_REGIONW + A2X_QOSW + `i_axi_a2x_1_A2X_HBTYPE_W +
                                              A2X_INT_ARSBW + `i_axi_a2x_1_A2X_IDW + A2X_AW  + `i_axi_a2x_1_A2X_RSW + A2X_BLW + `i_axi_a2x_1_A2X_BSW + 
                                              `i_axi_a2x_1_A2X_BTW + `i_axi_a2x_1_A2X_LTW + `i_axi_a2x_1_A2X_CTW + `i_axi_a2x_1_A2X_PTW;
  // AR Payload in AHB                                     
  localparam A2X_AR_PYLD_W_AHB              = `i_axi_a2x_1_A2X_HBTYPE_W + A2X_INT_ARSBW + `i_axi_a2x_1_A2X_IDW + A2X_AW  + `i_axi_a2x_1_A2X_RSW + A2X_BLW + `i_axi_a2x_1_A2X_BSW + 
                                              `i_axi_a2x_1_A2X_BTW + `i_axi_a2x_1_A2X_LTW + `i_axi_a2x_1_A2X_CTW + `i_axi_a2x_1_A2X_PTW;
 // Primary & Secondary Port W Payload
  localparam A2X_W_PP_PYLD_W                = A2X_INT_PPWSBW + `i_axi_a2x_1_A2X_IDW + A2X_PP_DW + A2X_PP_WSTRB_DW + 1;
  localparam A2X_W_SP_PYLD_W                = A2X_INT_WSBW + `i_axi_a2x_1_A2X_IDW + A2X_SP_DW + A2X_SP_WSTRB_DW + 1;

  // Primary & Secondary Port R Payload
  localparam A2X_R_PP_PYLD_W                = A2X_INT_PPRSBW + `i_axi_a2x_1_A2X_IDW + A2X_PP_DW + `i_axi_a2x_1_A2X_RRESPW + 1;
  localparam A2X_R_SP_PYLD_W                = A2X_INT_RSBW + `i_axi_a2x_1_A2X_IDW + A2X_SP_DW + `i_axi_a2x_1_A2X_RRESPW + 1;

  // Store and Forward Payload                                      
  localparam A2X_WSNF_PYLD_W                = 1; // SNF Status                      

  // Lint Violation when PP_DW=8 as Log2 = 0 hence A2X_PP_NUM_BYTES_LOG2-1 is a violation
  localparam PP_NUM_BYTES_LOG2              = ((A2X_EQSIZED==1) && (A2X_PP_DW==8))? 1 : A2X_PP_NUM_BYTES_LOG2;
  localparam SP_NUM_BYTES_LOG2              = ((A2X_EQSIZED==1) && (A2X_PP_DW==8))? 1 : A2X_SP_NUM_BYTES_LOG2;

  // SP OSAW FIFO Payload 
  localparam W_PP_NUM_BYTES_LOG2           = (A2X_PP_DW==8)? 1 : A2X_PP_NUM_BYTES_LOG2;
  localparam A2X_SP_OSAW_PYLD_W            = `i_axi_a2x_1_A2X_RSW + 1 + `i_axi_a2x_1_A2X_BSW + W_PP_NUM_BYTES_LOG2 + 1 + A2X_BLW + 1; 

  // Primary Port Length 
  localparam A2X_AHB_RBLW                   = (A2X_BLW>A2X_HINCR_RBCNT_MAX) ? A2X_BLW : A2X_HINCR_RBCNT_MAX;
  localparam A2X_AHB_WBLW                   = (A2X_BLW>A2X_HINCR_WBCNT_MAX) ? A2X_BLW : A2X_HINCR_WBCNT_MAX;

  // Primary Port Length 
  localparam BLW_PP                         = (A2X_PP_MODE==1) ? A2X_BLW : A2X_AHB_RBLW;

  // Resize FIFO AR Payload - Address Bits taken for the larger of the Data Busses
  localparam A2X_RDS_PYLD_W                 = `i_axi_a2x_1_A2X_RSW + 1 + `i_axi_a2x_1_A2X_BSW + PP_NUM_BYTES_LOG2 + 1;                                            

  localparam A2X_RUS_PYLD_W                 = `i_axi_a2x_1_A2X_RSW + 1 + BLW_PP + `i_axi_a2x_1_A2X_BSW + 1 + A2X_SP_NUM_BYTES_LOG2;

  localparam A2X_SP_OSAR_PYLD_W             = (A2X_DOWNSIZE==1)? A2X_RDS_PYLD_W : (A2X_UPSIZE==1)? A2X_RUS_PYLD_W : `i_axi_a2x_1_A2X_BSW; 

  localparam A2X_HINCR_LEN_W               = 4;

  // ID From-To Bits
  localparam AWID_FROM_BIT                  = `i_axi_a2x_1_A2X_IDW + A2X_AW  + `i_axi_a2x_1_A2X_RSW + A2X_BLW + `i_axi_a2x_1_A2X_BSW + `i_axi_a2x_1_A2X_BTW + `i_axi_a2x_1_A2X_LTW + `i_axi_a2x_1_A2X_CTW + `i_axi_a2x_1_A2X_PTW;
  localparam AWID_TO_BIT                    =  A2X_AW  + `i_axi_a2x_1_A2X_RSW + A2X_BLW + `i_axi_a2x_1_A2X_BSW + `i_axi_a2x_1_A2X_BTW + `i_axi_a2x_1_A2X_LTW + `i_axi_a2x_1_A2X_CTW + `i_axi_a2x_1_A2X_PTW;

  localparam ARID_FROM_BIT                  = `i_axi_a2x_1_A2X_IDW + A2X_AW  + `i_axi_a2x_1_A2X_RSW + A2X_BLW + `i_axi_a2x_1_A2X_BSW + `i_axi_a2x_1_A2X_BTW + `i_axi_a2x_1_A2X_LTW + `i_axi_a2x_1_A2X_CTW + `i_axi_a2x_1_A2X_PTW;
  localparam ARID_TO_BIT                    = A2X_AW  + `i_axi_a2x_1_A2X_RSW + A2X_BLW + `i_axi_a2x_1_A2X_BSW + `i_axi_a2x_1_A2X_BTW + `i_axi_a2x_1_A2X_LTW + `i_axi_a2x_1_A2X_CTW + `i_axi_a2x_1_A2X_PTW;
  
  localparam ARLEN_FROM_BIT                 =  A2X_BLW + `i_axi_a2x_1_A2X_BSW + `i_axi_a2x_1_A2X_BTW + `i_axi_a2x_1_A2X_LTW + `i_axi_a2x_1_A2X_CTW + `i_axi_a2x_1_A2X_PTW;
  localparam ARLEN_TO_BIT                   =  `i_axi_a2x_1_A2X_BSW + `i_axi_a2x_1_A2X_BTW + `i_axi_a2x_1_A2X_LTW + `i_axi_a2x_1_A2X_CTW + `i_axi_a2x_1_A2X_PTW;

  // Bresp FIFO Depth
  // In AHB Mode the H2X has a response counter for each AHB Master hence when response returned it is popped from FIFO.
  localparam BRESP_FIFO_DEPTH               = (A2X_PP_MODE==0)? 2 : A2X_BRESP_FIFO_DEPTH;
  localparam BRESP_FIFO_DEPTH_LOG2          = (A2X_PP_MODE==0)? 1 : A2X_BRESP_FIFO_DEPTH_LOG2;

  localparam HCBUF_MODE                     = A2X_HCBUF_MODE;

  localparam NUM_URID                       = ((A2X_PP_MODE==0) && (AHB_SPLIT_MODE==0))? 1 : A2X_NUM_URID; 

  // Bypass URID Block - don't Bypass under following conditions
  localparam BYPASS_URID_FIFO               = ((A2X_PP_MODE==1) && (A2X_PP_ENDIAN!=0))? 0 : 
                                              (A2X_SP_ENDIAN!=0)? 0 : 
                                              (A2X_UPSIZE==1)? 0 :
                                              (A2X_DOWNSIZE==1)? 0 : 
                                              ((A2X_PP_MODE==0) && (A2X_BLW<A2X_HINCR_RBCNT_MAX))? 0 : 1;

  // Bypass URID Block
  // ((A2X_PP_MODE==0) && (A2X_BRESP_MODE==1) && (A2X_EQSIZED==1) && (A2X_LOCKED==1)? 0 :
  localparam BYPASS_UBID_FIFO               = (A2X_BRESP_MODE==0) ? 1 :
                                              ((A2X_BRESP_MODE==1) && (A2X_EQSIZED==1) && (((HCBUF_MODE==1) && (A2X_WBUF_MODE==0)) || (A2X_HCSNF_WLEN==1)))? 1 : 0;

  // Bypass SNF logic                                              
  localparam BYPASS_SNF_W                   = ( (HCBUF_MODE==1) && (A2X_WBUF_MODE==0)) ? 1 : 0; 
  localparam BYPASS_SNF_R                   = ( (HCBUF_MODE==1) && (A2X_RBUF_MODE==0)) ? 1 : 0;

  // Bypass AW Channel Calculate Address Block
  // Equalled Sized and Hardcoded to Cut-Through
  // Equalled Sized and Hardcoded to Store-Forward and using the A2X hardcoded Lenght i.e. 2^BLW
  localparam BYPASS_AW_AC                   = ((A2X_EQSIZED==1) && (((HCBUF_MODE==1) && (A2X_WBUF_MODE==0))|| (A2X_HCSNF_WLEN==1))) ? 1 : 
                                              ((A2X_UPSIZE==1)  && (((HCBUF_MODE==1) && (A2X_WBUF_MODE==0))|| (A2X_HCSNF_WLEN==1))) ? 1 : 0;

  // Bypass AW Channel Wrap Address Spliiter
  // Equalled Sized Configuration Bypass WRAP Splitter. Store-Forward value
  // always greater than 16 hence wraps do not need to be split into INCRs
  localparam BYPASS_AW_WS                   = (A2X_EQSIZED==1)? 1 : 0;
  
  // Bypass AR Channel Calculate Address Block
  // AHB Equalled Sized and Hardcoded to Cut-Through with Max AHB INCR Length less than 2^BLW
  // AXI Equalled Sized and Hardcoded to Cut-Through and using the A2X hardcoded Lenght i.e. 2^BLW
  // AHB Equalled Sized and Hardcoded to Store-Forward and using the A2X hardcoded Lenghtand with Max AHB INCR Length less than 2^BLW
  // AXI Equalled Sized and Hardcoded to Store-Forward and using the A2X hardcoded Lenght i.e. 2^BLW
  localparam BYPASS_AR_AC = ((A2X_PP_MODE==1) && (A2X_EQSIZED==1) && (((HCBUF_MODE==1) && (A2X_RBUF_MODE==0)) || (A2X_HCSNF_RLEN==1))) ? 1 : 
                            ((A2X_PP_MODE==1) && (A2X_UPSIZE==1)  && (((HCBUF_MODE==1) && (A2X_RBUF_MODE==0)) || (A2X_HCSNF_RLEN==1))) ? 1 :
                            ((A2X_PP_MODE==0) && (A2X_EQSIZED==1) && (((HCBUF_MODE==1) && (A2X_RBUF_MODE==0)) || (A2X_HCSNF_RLEN==1)) && (A2X_BLW>=A2X_HINCR_RBCNT_MAX))? 1 :  
                            ((A2X_PP_MODE==0) && (A2X_UPSIZE==1)  && (((HCBUF_MODE==1) && (A2X_RBUF_MODE==0)) || (A2X_HCSNF_RLEN==1)) && (A2X_BLW>=A2X_HINCR_RBCNT_MAX))? 1 : 0; 

  // Bypass AR Address Wrap Splitter
  // Equalled Sized Configuration Bypass WRAP Splitter. Store-Forward value
  // always greater than 16 hence wraps do not need to be split into INCRs
  localparam BYPASS_AR_WS                   = (A2X_EQSIZED==1)? 1 : 0; 

  // Locked FIFO only required for Split configs. In non-split mode read data
  // is always returned before next transaction.
  localparam A2X_AHB_LK_RD_FIFO             = ((A2X_PP_MODE==0) && (A2X_LOCKED==1) && (AHB_SPLIT_MODE==1))? 1 : 0;
  
  localparam A2X_HINCR_RBCNT_IDW            = (A2X_HINCR_HCBCNT==1)? 4 : (A2X_SINGLE_RBCNT==1)? 4 :  4*A2X_NUM_AHBM; // AHB Read HINCR BCNT BUS Width
  localparam A2X_HINCR_WBCNT_IDW            = (A2X_HINCR_HCBCNT==1)? 4 : (A2X_SINGLE_WBCNT==1)? 4 :  4*A2X_NUM_AHBM; // AHB Write HINCR BCNT BUS Width
  
  // AHB Mode - Enable Logic for Buffer Full Conditions
  // Write address Buffer Full conditions.
  // - Buffer never full in Non-Bufferable Mode Non-Split Mode 
  //   - AW FIFO Depth must be 3 in this case to cater for wrap transactions EBT'd.
  //   - AW FIFO Depth must be 16 or less for INCR16 transactions EBT'd
  // - Buffer never full in Non-Bufferable Mode Split Mode & Number of AHB Masters equal to Address FIFO Depth. 
  localparam AW_BUF_FULL_EN                 = (A2X_PP_MODE==1)? 1 : (A2X_LOWPWR_IF==1)? 1 : (A2X_LOCKED==1)? 1: 1;

  // Read address Buffer Full conditions.
  // - Buffer never full in Non-Split Mode
  // - In cases where the Number of AHB Masters equal FIFO Depth.
  localparam AR_BUF_FULL_EN                 = (A2X_PP_MODE==1)? 1 : (A2X_LOWPWR_IF==1)? 1 : (A2X_LOCKED==1)? 1 : (AHB_SPLIT_MODE==0)? 0 : 
                                              (A2X_AR_FIFO_DEPTH==A2X_NUM_AHBM)? 0 : 1;

  // Write Data buffer Full Conditions
  // - In AHB Non-Bufferable Mode where FIFO Depth is 16 * Number of AHB Masters
  // - In AHB Non-Bufferable Mode and not Split Capable and FIFO_DEPTH equals 2^BLW - not true with EBT conditions
  localparam WD_BUF_FULL_EN = (A2X_PP_MODE==1)? 1 : (A2X_LOWPWR_IF==1)? 1 : (A2X_LOCKED==1)? 1 : 1;

  //*************************************************************************************
  // AHB HINCR Ports
  //*************************************************************************************
  //spyglass disable_block W240
  //SMD: An input has been declared but is not read.
  //SJ : Few ports are used only in specific config 
  input  [A2X_HINCR_WBCNT_IDW-1:0]            hincr_wbcnt_id;
  input  [A2X_HINCR_RBCNT_IDW-1:0]            hincr_rbcnt_id;
  //*************************************************************************************
  // Primary Port I/O Decelaration
  //*************************************************************************************
  input                                       clk_pp;
  input                                       resetn_pp;
  
  //-----------------------------AHB Interface------------------------------------------
  // AHB Interface
  input                                       hsel;        // AHB Select  
  input  [`i_axi_a2x_1_A2X_IDW-1:0]                       hmaster;     // AHB Master ID Bus
  input  [A2X_AW-1:0]                         haddr;       // AHB Address Bus
  input                                       hwrite;      // AHB write indicator   
  input                                       hmastlock;   // AHB lock              
  input  [`i_axi_a2x_1_A2X_HBLW-1:0]                      hburst;      // AHB burst             
  input                                       hresize;     // AHB Resize Data
  input  [1:0]                                htrans;      // AHB address phase     
  input  [`i_axi_a2x_1_A2X_BSW-1:0]                       hsize;       // AHB size              
  input  [`i_axi_a2x_1_A2X_HPTW-1:0]                      hprot;       // AHB protection        
  input  [A2X_PP_DW-1:0]                      hwdata;      // AHB write data        

  input                                       hready;      // AHB ready
  output                                      hready_resp; // AHB ready                 
  output [`i_axi_a2x_1_A2X_HRESPW-1:0]                    hresp;       // AHB response              
  output [A2X_PP_DW-1:0]                      hrdata;      // AHB read data 
  output [15:0]                               hsplit;      // AHB Split 
  input  [A2X_INT_HASBW-1:0]                  haddr_sb;    // AHB Address Sideband Bus
  input  [A2X_INT_HWSBW-1:0]                  hwdata_sb;   // AHB Write Data Sideband Bus
  output [A2X_INT_HRSBW-1:0]                  hrdata_sb;   // AHB Read Data Sideband Bus

  //-----------------------------AXI Interface------------------------------------------
  // These nets are used to connect the logic under certain configuration.
  // But this may not drive some of the nets. This will not cause any functional issue.
  output                                      awready_pp; 
  input                                       awvalid_pp;
  input  [`i_axi_a2x_1_A2X_IDW-1:0]                       awid_pp;    
  input  [A2X_AW-1:0]                         awaddr_pp; 
  input  [A2X_BLW-1:0]                        awlen_pp; 
  input  [`i_axi_a2x_1_A2X_BSW-1:0]                       awsize_pp;     
  input  [`i_axi_a2x_1_A2X_BTW-1:0]                       awburst_pp;   
  input  [`i_axi_a2x_1_A2X_CTW-1:0]                       awcache_pp; 
  input  [`i_axi_a2x_1_A2X_PTW-1:0]                       awprot_pp; 
  input                                       awresize_pp;
  input  [A2X_INT_AWSBW-1:0]                  awsideband_pp;
  input  [A2X_INT_AWSBW-1:0]                  awuser_pp; 
  input  [A2X_QOSW-1:0]                       awqos_pp;
  input  [A2X_REGIONW-1:0]                    awregion_pp;
  input  [A2X_DOMAINW-1:0]                    awdomain_pp;
  input  [A2X_WSNOOPW-1:0]                    awsnoop_pp;
  input  [A2X_BARW-1:0]                       awbar_pp;
  input  [`i_axi_a2x_1_A2X_LTW-1:0]                       awlock_pp;   

  // AXI write data
  output                                      wready_pp;    
  input                                       wvalid_pp;   
  input                                       wlast_pp;   
  input  [`i_axi_a2x_1_A2X_IDW-1:0]                       wid_pp;    
  input  [A2X_PP_DW-1:0]                      wdata_pp; 
  input  [A2X_PP_WSTRB_DW-1:0]                wstrb_pp;
  input  [A2X_INT_WSBW-1:0]                   wsideband_pp;
  input  [A2X_INT_WSBW-1:0]                   wuser_pp;  
  // AXI write response                                  
  input                                       bready_pp; 
  output                                      bvalid_pp;     
  output [`i_axi_a2x_1_A2X_IDW-1:0]                       bid_pp;       
  output [`i_axi_a2x_1_A2X_BRESPW-1:0]                    bresp_pp;    
  output [A2X_INT_BSBW-1:0]                   bsideband_pp;  
  output [A2X_INT_BSBW-1:0]                   buser_pp;  

  // AXI Address Read
  output                                      arready_pp; 
  input                                       arvalid_pp;
  input  [`i_axi_a2x_1_A2X_IDW-1:0]                       arid_pp;    
  input  [A2X_AW-1:0]                         araddr_pp; 
  input  [A2X_BLW-1:0]                        arlen_pp; 
  input  [`i_axi_a2x_1_A2X_BSW-1:0]                       arsize_pp;     
  input  [`i_axi_a2x_1_A2X_BTW-1:0]                       arburst_pp;   
  input  [`i_axi_a2x_1_A2X_CTW-1:0]                       arcache_pp; 
  input  [`i_axi_a2x_1_A2X_PTW-1:0]                       arprot_pp; 
  input                                       arresize_pp;
  input  [A2X_INT_ARSBW-1:0]                  arsideband_pp; 
  input  [A2X_INT_ARSBW-1:0]                  aruser_pp; 
  input  [A2X_QOSW-1:0]                       arqos_pp;
  input  [A2X_REGIONW-1:0]                    arregion_pp;
  input  [A2X_DOMAINW-1:0]                    ardomain_pp;
  input  [A2X_RSNOOPW-1:0]                    arsnoop_pp;
  input  [A2X_BARW-1:0]                       arbar_pp;

  input  [`i_axi_a2x_1_A2X_LTW-1:0]                       arlock_pp;   
  
  // AXI Read data
  input                                       rready_pp;    
  output                                      rvalid_pp;   
  output                                      rlast_pp;   
  output [`i_axi_a2x_1_A2X_IDW-1:0]                       rid_pp;    
  output [A2X_PP_DW-1:0]                      rdata_pp; 
  output [`i_axi_a2x_1_A2X_RRESPW-1:0]                    rresp_pp; 
  output [A2X_INT_RSBW-1:0]                   rsideband_pp;  
  output [A2X_INT_RSBW-1:0]                   ruser_pp;  

  //*************************************************************************************
  // Secondary Port I/O Decelaration
  //*************************************************************************************
  input                                       clk_sp;
  input                                       resetn_sp;

  input                                       awready_sp; 
  output                                      awvalid_sp;
  output [`i_axi_a2x_1_A2X_SP_IDW-1:0]                    awid_sp;    
  output [A2X_SP_AW-1:0]                      awaddr_sp; 
  output [A2X_SP_BLW-1:0]                     awlen_sp; 
  output [`i_axi_a2x_1_A2X_BSW-1:0]                       awsize_sp;     
  output [`i_axi_a2x_1_A2X_BTW-1:0]                       awburst_sp;   
  output [`i_axi_a2x_1_A2X_INT_LTW-1:0]                   awlock_sp;   
  output [`i_axi_a2x_1_A2X_CTW-1:0]                       awcache_sp; 
  output [`i_axi_a2x_1_A2X_PTW-1:0]                       awprot_sp; 
  output [A2X_INT_AWSBW-1:0]                  awsideband_sp; 
  output [A2X_INT_AWSBW-1:0]                  awuser_sp; 
  output [A2X_QOSW-1:0]                       awqos_sp;
  output [A2X_REGIONW-1:0]                    awregion_sp;
  output [A2X_DOMAINW-1:0]                    awdomain_sp;
  output [A2X_WSNOOPW-1:0]                    awsnoop_sp;
  output [A2X_BARW-1:0]                       awbar_sp;

  // AXI write data
  input                                       wready_sp;    
  output                                      wvalid_sp;   
  output                                      wlast_sp;   
  output [`i_axi_a2x_1_A2X_SP_IDW-1:0]                    wid_sp;    
  output [A2X_SP_DW-1:0]                      wdata_sp; 
  output [A2X_SP_WSTRB_DW-1:0]                wstrb_sp;
  output [A2X_INT_WSBW-1:0]                   wsideband_sp;  
  output [A2X_INT_WSBW-1:0]                   wuser_sp;  
                          
  // AXI write response                                  
  output                                      bready_sp;
  input                                       bvalid_sp;     
  input [`i_axi_a2x_1_A2X_IDW-1:0]                        bid_sp;       
  input [`i_axi_a2x_1_A2X_BRESPW-1:0]                     bresp_sp;    
  input [A2X_INT_BSBW-1:0]                    bsideband_sp; 
  input [A2X_INT_BSBW-1:0]                    buser_sp;  
  // AXI Read Address
  input                                       arready_sp; 
  output                                      arvalid_sp;
  output [`i_axi_a2x_1_A2X_SP_IDW-1:0]                    arid_sp;    
  output [A2X_SP_AW-1:0]                      araddr_sp; 
  output [A2X_SP_BLW-1:0]                     arlen_sp; 
  output [`i_axi_a2x_1_A2X_BSW-1:0]                       arsize_sp;     
  output [`i_axi_a2x_1_A2X_BTW-1:0]                       arburst_sp;   
  output [`i_axi_a2x_1_A2X_INT_LTW-1:0]                   arlock_sp;   
  output [`i_axi_a2x_1_A2X_CTW-1:0]                       arcache_sp; 
  output [`i_axi_a2x_1_A2X_PTW-1:0]                       arprot_sp; 
  output [A2X_INT_ARSBW-1:0]                  arsideband_sp; 
  output [A2X_INT_ARSBW-1:0]                  aruser_sp; 
  output [A2X_QOSW-1:0]                       arqos_sp;
  output [A2X_REGIONW-1:0]                    arregion_sp;
  output [A2X_DOMAINW-1:0]                    ardomain_sp;
  output [A2X_RSNOOPW-1:0]                    arsnoop_sp;
  output [A2X_BARW-1:0]                       arbar_sp;

  // AXI Read data
  output                                      rready_sp;    
  input                                       rvalid_sp;   
  input                                       rlast_sp;   
  input [`i_axi_a2x_1_A2X_IDW-1:0]                        rid_sp;    
  input [A2X_SP_DW-1:0]                       rdata_sp; 
  input [`i_axi_a2x_1_A2X_RRESPW-1:0]                     rresp_sp; 
  input [A2X_INT_RSBW-1:0]                    rsideband_sp; 
  input [A2X_INT_RSBW-1:0]                    ruser_sp;  
  // Low Power Control
  input                                       csysreq;
  output                                      csysack;
  output                                      cactive; 
  output                                      busy_status_o;
  //spyglass enable_block W240

  //*************************************************************************************
  // Signal Decelaration
  //*************************************************************************************
  wire  [`i_axi_a2x_1_A2X_IDW-1:0]                        awid_sp_w;
  wire  [`i_axi_a2x_1_A2X_IDW-1:0]                        arid_sp_w;
  wire  [`i_axi_a2x_1_A2X_IDW-1:0]                        wid_sp_w;
  wire  [`i_axi_a2x_1_A2X_IDW-1:0]                        bid_sp_w;
  wire  [`i_axi_a2x_1_A2X_IDW-1:0]                        rid_sp_w;

  wire  [A2X_AW-1:0]                          awaddr_sp_o;
  wire  [A2X_AW-1:0]                          araddr_sp_o;

  wire  [A2X_BLW-1:0]                         awlen_sp_o; 
  wire  [A2X_BLW-1:0]                         arlen_sp_o; 

  wire                                        bypass_aw_ws;
  wire                                        bypass_ar_ws;

  wire                                        rready_pp_lk_w;
  wire                                        rready_pp_w;
  wire                                        arvalid_pp_w;
  // These are dummy wires used to connect the unconnected ports.
  // Hence will not drive any nets.
  wire                                        rvalid_pp_lk;
  wire                                        arvalid_pp_lk;

  wire                                        bready_pp_w;
  wire                                        wvalid_pp_w;
  wire                                        awvalid_pp_w;
  wire                                        awvalid_pp_lk;
  // Signal not used under certain configurations
  wire                                        hrready_pp;
  wire                                        hrready_pp_lk;
  wire                                        harvalid_pp;
  wire                                        hbready_pp;
  wire                                        hwvalid_pp;
  wire                                        hawvalid_pp;

  wire                                        hresize_w;
  wire                                        awresize_sp;


  // These are dummy wires used to connect the unconnected ports.
  // Hence will not drive any nets.
  wire                                        arresize_sp;
  wire                                        w_fifo_push_empty;

  // AW && W FIFO Controls
  wire                                        w_sp_osaw_fifo_push_n;
  wire                                        w_sp_osaw_fifo_full;
  wire                                        w_pp_osaw_fifo_full;

  wire                                        aw_snf_fifo_full;
  wire                                        aw_snf_fifo_push_n;

  // Write Response Fifo Controls
  wire                                        b_buf_fifo_full;
  wire                                        b_osw_fifo_valid;
  wire                                        b_osw_trans;

  // FIFO Payload's
  wire  [A2X_AW_PYLD_W-1:0]                   aw_pyld_pp;
  wire  [A2X_AW_PYLD_W-1:0]                   aw_pyld_sp;

  wire  [A2X_AR_PYLD_W-1:0]                   ar_pyld_pp;
  wire  [A2X_AR_PYLD_W-1:0]                   ar_pyld_sp;

  wire  [A2X_WSNF_PYLD_W-1:0]                 aw_snf_pyld_pp;

  wire  [A2X_SP_OSAW_PYLD_W-1:0]              w_sp_osaw_pyld;
  
  wire  [A2X_W_PP_PYLD_W-1:0]                 w_pyld_pp;
  wire  [A2X_W_SP_PYLD_W-1:0]                 w_pyld_sp;

  wire  [A2X_B_PYLD_W-1:0]                    b_pyld_pp;
  wire  [A2X_B_PYLD_W-1:0]                    b_pyld_sp;

  wire  [A2X_R_PP_PYLD_W-1:0]                 r_pyld_pp;
  wire  [A2X_R_PP_PYLD_W-1:0]                 r_pyld_pp_lk;
  wire  [A2X_R_SP_PYLD_W-1:0]                 r_pyld_sp;

  // Register slice 
  wire                                        awvalid_sp_rs;
  wire                                        awready_sp_rs;
  wire  [A2X_AW_PYLD_W-1:0]                   aw_pyld_sp_rs;

  wire                                        arvalid_sp_rs;
  wire                                        arready_sp_rs;
  // These nets are used to connect the logic under certain configuration.
  // But this may not drive some of the nets. This will not cause any functional issue.
  wire  [A2X_AR_PYLD_W-1:0]                   ar_pyld_sp_rs;

  wire                                        wvalid_sp_rs;
  wire                                        wready_sp_rs;
  wire  [A2X_W_SP_PYLD_W-1:0]                 w_pyld_sp_rs;

  wire                                        bvalid_sp_rs;
  wire                                        bready_sp_rs;
  wire  [A2X_B_PYLD_W-1:0]                    b_pyld_sp_rs;

  wire                                        rvalid_sp_rs;
  wire                                        rready_sp_rs;
  wire  [A2X_R_SP_PYLD_W-1:0]                 r_pyld_sp_rs;

  // Software Control Signals
  wire                                        siu_wbuf_mode; 
  wire                                        siu_rbuf_mode; 
  wire   [31:0]                               siu_snf_awlen;

  wire   [A2X_HINCR_WBCNT_IDW-1:0]            h2x_hincr_wbcnt;
  wire   [A2X_HINCR_RBCNT_IDW-1:0]            h2x_hincr_rbcnt;

  wire                                        aw_last_sp;
  wire                                        aw_nbuf_sp; 
  wire   [`i_axi_a2x_1_A2X_IDW-1:0]                       aw_id_sp;   
  wire   [`i_axi_a2x_1_A2X_IDW-1:0]                       ar_id_sp;   
  wire   [A2X_BLW-1:0]                        ar_len_sp;

  // Internal Sideband Buses

  wire [A2X_INT_BSBW-1:0]                     bsideband_sp_w;  
  wire [A2X_INT_RSBW-1:0]                     rsideband_sp_w;  

  wire [A2X_INT_HASBW-1:0]                    haddr_sb_w;
  wire [A2X_INT_HWSBW-1:0]                    hwdata_sb_w;
  wire [A2X_INT_HRSBW-1:0]                    hrdata_sb_w; 

  wire                                        wlast_pp_w;
  wire [`i_axi_a2x_1_A2X_IDW-1:0]                         wid_pp_w;    

  wire                                        r_osr_fifo_empty;
  wire                                        r_uid_fifo_valid;
  // These are dummy wires used to connect the unconnected ports.
  // Hence will not drive any nets.
  wire                                        r_uid_fifo_push_n;
  wire                                        ar_last_sp;
  wire [A2X_SP_OSAR_PYLD_W-1:0]               r_sp_osar_pyld;

  wire [31:0]                                 r_fifo_len;

  wire                                        aw_lock_req;
  wire                                        ar_lock_req;
  wire                                        aw_unlock_req;
  wire                                        ar_unlock_req;
  wire                                        aw_os_unlock;
  wire                                        ar_os_unlock;
  wire                                        lock_grant;
  wire                                        unlock_grant;
  wire                                        unlock_seq; 
  wire                                        lockseq_cmp; 
  wire                                        aw_osw_trans;
  wire                                        ar_osr_trans;
  wire                                        ar_push_empty;

  wire                                        pp_locked;
  wire                                        sp_locked;
  wire                                        ar_hburst_type_sp;
  wire                                        aw_hburst_type_sp;

  wire                                        nbuf_pp;
  wire                                        aw_sp_active;
  wire                                        aw_fifo_push_empty;
  wire                                        snf_fifo_push_empty;
  wire                                        bridge_select;
  wire                                        pp_osx_wr;
  wire                                        pp_osx_rd;
  wire                                        sp_osx_wr;
  wire                                        busy_status;
  wire                                        h2x_busy;

  wire                                        bypass_urid_fifo;

  wire                                        flush;
  wire                                        osr_cnt_incr;       // Incremtn Outstanding Read Counter
  wire   [10:0]                               ar_fifo_alen; 

  wire                                        lp_mode;

  wire  [`i_axi_a2x_1_A2X_LTW-1:0]                        awlock_core_sp;
  wire  [`i_axi_a2x_1_A2X_LTW-1:0]                        arlock_core_sp;

  //***********************************************************************************
  // Sideband and User signals
  //***********************************************************************************
  generate 
  if (A2X_AXI3==1) begin: SUS
    assign buser_pp   = {(A2X_INT_BSBW){1'b0}};
    assign ruser_pp   = {(A2X_INT_RSBW){1'b0}};
    assign awuser_sp  = {(A2X_INT_AWSBW){1'b0}};
    assign aruser_sp  = {(A2X_INT_ARSBW){1'b0}};
    assign wuser_sp   = {(A2X_INT_WSBW){1'b0}};
  end else begin
    assign bsideband_pp  = {(A2X_INT_BSBW){1'b0}}; 
    assign rsideband_pp  = {(A2X_INT_RSBW){1'b0}};
    assign awsideband_sp = {(A2X_INT_AWSBW){1'b0}};
    assign arsideband_sp = {(A2X_INT_ARSBW){1'b0}};
    assign wsideband_sp  = {(A2X_INT_WSBW){1'b0}};
  end
  endgenerate


  //***********************************************************************************
  // Lock signals
  //***********************************************************************************
       assign awlock_sp = awlock_core_sp[0];
       assign arlock_sp = arlock_core_sp[0];
  //*************************************************************************************
  // ID Widths
  //*************************************************************************************
  generate 
  if (`i_axi_a2x_1_A2X_IDW==`i_axi_a2x_1_A2X_SP_IDW) begin: IDW
    assign awid_sp   = awid_sp_w;
    assign arid_sp   = arid_sp_w;
    assign wid_sp    = wid_sp_w;
    assign bid_sp_w  = bid_sp;
    assign rid_sp_w  = rid_sp;
  end else begin
    // A2X_SP_IDW always greater than A2X_IDW i.e. A2X_PP_IDW
    assign awid_sp   = {{(`i_axi_a2x_1_A2X_SP_IDW-`i_axi_a2x_1_A2X_IDW){1'b0}}, awid_sp_w};
    assign arid_sp   = {{(`i_axi_a2x_1_A2X_SP_IDW-`i_axi_a2x_1_A2X_IDW){1'b0}}, arid_sp_w};
    assign wid_sp    = {{(`i_axi_a2x_1_A2X_SP_IDW-`i_axi_a2x_1_A2X_IDW){1'b0}}, wid_sp_w};
    assign bid_sp_w  = bid_sp[`i_axi_a2x_1_A2X_IDW-1:0];
    assign rid_sp_w  = rid_sp[`i_axi_a2x_1_A2X_IDW-1:0];
  end
  endgenerate

  //*************************************************************************************
  // Address Widths
  //*************************************************************************************
  generate 
  if (A2X_AW==A2X_SP_AW) begin: AW
    assign awaddr_sp = awaddr_sp_o;
    assign araddr_sp = araddr_sp_o;
  end else begin
    // A2X_SP_AW always greater than A2X_AW i.e. A2X_PP_AW
    assign awaddr_sp = {{(A2X_SP_AW-A2X_AW){1'b0}}, awaddr_sp_o};
    assign araddr_sp = {{(A2X_SP_AW-A2X_AW){1'b0}}, araddr_sp_o};
  end
  endgenerate

  //*************************************************************************************
  // ARLEN/AWLEN Widths
  //*************************************************************************************
  generate 
  if (A2X_SP_BLW == A2X_BLW) begin: BLW
    assign awlen_sp = awlen_sp_o;
    assign arlen_sp = arlen_sp_o;
  end else begin
    // A2X_SP_AW always greater than A2X_AW i.e. A2X_PP_AW
    assign awlen_sp = {{(A2X_SP_BLW-A2X_BLW){1'b0}}, awlen_sp_o};
    assign arlen_sp = {{(A2X_SP_BLW-A2X_BLW){1'b0}}, arlen_sp_o};
  end
  endgenerate


  //*************************************************************************************
  // FIFO Bypass Conditions
  //*************************************************************************************
  // Equalled Sized Configuration Bypass WRAP Splitter. Store-Forward value
  // always greater than 16 hence wraps do not need to be split into INCRs
  assign bypass_aw_ws     = (A2X_EQSIZED==1)? 1'b1 : 1'b0;
  
  assign bypass_ar_ws     = (A2X_EQSIZED==1)? 1'b1 : 1'b0;

  generate 
  if (BYPASS_URID_FIFO==1) begin:BYPUR
    assign bypass_urid_fifo = 1'b1;
  end else begin
    //assign bypass_urid_fifo = ((siu_rbuf_mode==0) && (A2X_EQSIZED==1) && (A2X_BLW>=A2X_HINCR_RBCNT_MAX))? 1 : 0;
    assign bypass_urid_fifo = ((A2X_PP_MODE==1) && (A2X_PP_ENDIAN!=0))? 0 :
                              (A2X_SP_ENDIAN!=0)? 0 :
                              (A2X_UPSIZE==1)? 0 :
                              (A2X_DOWNSIZE==1)? 0 :
                              ((A2X_PP_MODE==0) && (A2X_BLW<A2X_HINCR_RBCNT_MAX))? 0 : 1; 
  end
  endgenerate

  //*************************************************************************************
  // Output Ports Assignment  
  //*************************************************************************************
  assign rready_pp_lk_w = (A2X_PP_MODE==1)? 1'b0  : hrready_pp_lk;
  assign rready_pp_w    = (A2X_PP_MODE==1)? rready_pp  : hrready_pp;
  assign bready_pp_w    = (A2X_PP_MODE==1)? bready_pp  : hbready_pp;
  assign wvalid_pp_w    = (A2X_PP_MODE==1)? wvalid_pp  : hwvalid_pp;

  assign arvalid_pp_w   = (A2X_PP_MODE==1)? arvalid_pp : harvalid_pp;
  assign awvalid_pp_w   = (A2X_PP_MODE==1)? awvalid_pp : hawvalid_pp;
   
  //*************************************************************************************
  // Busy status of the bridge
  //*************************************************************************************
  assign busy_status_o = busy_status;
  generate
    if(A2X_LOWPWR_IF==1) begin: BUSY_STATUS
      
      // Lint flags this rule when any signal in the cross over path has more than one fanout or any object 
      // in the cross over path has more than one output. 
      reg                                         aw_sp_active_r;
      // Keep track of outstanding primary port Read transactions
      i_axi_a2x_1_DW_axi_a2x_busy_osx
       #(.CNT_WIDTH (16)) U_pp_os_rd (
         .clk        (clk_pp)
        ,.resetn     (resetn_pp)
        ,.inc        (arvalid_pp_w & arready_pp)
        ,.dec        (rvalid_pp & rready_pp_w & rlast_pp)
        ,.osx_status (pp_osx_rd)
      );

      assign bridge_select = (A2X_PP_MODE==0) ? (hsel & (|htrans)) | h2x_busy : (awvalid_pp | arvalid_pp | wvalid_pp);

      // Generating a SP Registered version. This is to ensure the input to
      // the PP Syncroniser comes from a register. 
      always @(posedge clk_sp or negedge resetn_sp) begin: aw_sp_active_PROC
        if (resetn_sp==1'b0) 
          aw_sp_active_r <= 1'b0;
        else begin
          aw_sp_active_r <= b_osw_trans | sp_osx_wr | aw_sp_active;
        end
      end

      // Merge outstanding transaction results into single primary port
      // clock domain busy status bit.
      i_axi_a2x_1_DW_axi_a2x_busy
       #( .A2X_BRESP_MODE(A2X_BRESP_MODE), .A2X_CLK_MODE(A2X_CLK_MODE) ) U_busy_status (
         .clk_pp                (clk_pp)
        ,.resetn_pp             (resetn_pp)
        ,.bridge_sel            (bridge_select)
        ,.aw_fifo_push_empty    (aw_fifo_push_empty)
        ,.snf_fifo_push_empty   (snf_fifo_push_empty)
        ,.w_fifo_push_empty     (w_fifo_push_empty)
        ,.pp_osx_wr             (pp_osx_wr)
        ,.pp_osx_rd             (pp_osx_rd)
        ,.aw_sp_active          (aw_sp_active_r)
        ,.busy_status           (busy_status)
      );
    end else begin // if(A2X_BUSY_LOGIC==1) begin
      assign busy_status = 1'b0;
    end
  endgenerate
  
  generate
    if((A2X_LOWPWR_IF==1) && ((A2X_BRESP_MODE==1) || (A2X_BRESP_MODE==2))) begin: PP_WR_OS
      // Keep track of outstanding primary port Write transactions
      // This is only required when non-bufferable writes are enabled
      i_axi_a2x_1_DW_axi_a2x_busy_osx
       #(.CNT_WIDTH (16)) U_pp_os_wr (
         .clk        (clk_pp)
        ,.resetn     (resetn_pp)
        ,.inc        (awvalid_pp_w & awready_pp & nbuf_pp) // only increment for non-buffered writes (we won't get a response for the buffered writes)
        ,.dec        (bvalid_pp & bready_pp_w)
        ,.osx_status (pp_osx_wr)
      );
    end else begin
      assign pp_osx_wr = 1'b0;
    end
  endgenerate

  generate
    if((A2X_LOWPWR_IF==1) && A2X_BRESP_MODE!=1) begin: SP_WR_OS
      // Keep track of outstanding secondary port Write transactions
      // This is only required when bufferable writes are enabled
      i_axi_a2x_1_DW_axi_a2x_busy_osx
       #(.CNT_WIDTH (16)) U_sp_os_wr (
         .clk        (clk_sp)
        ,.resetn     (resetn_sp)
        ,.inc        (awvalid_sp_rs & awready_sp_rs)
        ,.dec        (bvalid_sp & bready_sp)
        ,.osx_status (sp_osx_wr)
      );
    end else begin
      assign sp_osx_wr = 1'b0;
    end
  endgenerate
  
  //*************************************************************************************
  // Control Signals
  //*************************************************************************************
  assign siu_wbuf_mode        = (A2X_WBUF_MODE==0)? 1'b0 : 1'b1;  
  assign siu_rbuf_mode        = (A2X_RBUF_MODE==0)? 1'b0 : 1'b1;  
  assign siu_snf_awlen        = 1 << SNF_AWLEN_DFLT;  

  // Signed and unsigned operands should not be used in same operation.
  // It is a design requirement to use A2X_HINCR_WBCNT_MAX in the following 
  // operation and it will not have any adverse effects on the 
  // design. So signed and unsigned operands are used in the logic.        
  assign h2x_hincr_wbcnt      = (A2X_HINCR_HCBCNT==0)? hincr_wbcnt_id[A2X_HINCR_WBCNT_IDW-1:0] : A2X_HINCR_WBCNT_MAX;

  assign h2x_hincr_rbcnt      = (A2X_HINCR_HCBCNT==0)? hincr_rbcnt_id[A2X_HINCR_RBCNT_IDW-1:0] : A2X_HINCR_RBCNT_MAX;

  //*************************************************************************************
  // Low Power Instantiation
  //*************************************************************************************
  generate 
    if (A2X_LOWPWR_IF==1) begin: LOWPWR
      i_axi_a2x_1_DW_axi_a2x_lp
       #(
         .LOWPWR_NOPX_CNT                       (A2X_LOWPWR_NOPX_CNT)
      ) U_axi_a2x_lp (
      // Outputs
       .cactive(cactive),
                      .csysack(csysack),
                      .lp_mode(lp_mode)// Inputs
                      ,
                      .clk_pp(clk_pp),
                      .resetn_pp(resetn_pp),
                      .active_trans(busy_status),
                      .csysreq(csysreq),
                      .awvalid(awvalid_pp),
                      .arvalid(arvalid_pp),
                      .wvalid(wvalid_pp),
                      .hsel(hsel)
                      );
   end else begin
     assign cactive     = 1'b1;
     assign csysack     = 1'b0;
     assign lp_mode     = 1'b0;
   end
  endgenerate

  //*************************************************************************************
  // H2X Instantiation
  //*************************************************************************************
  generate 
    if (A2X_PP_MODE==0) begin: H2X
      i_axi_a2x_1_DW_axi_a2x_h2x
       #(
         .A2X_BRESP_MODE                        (A2X_BRESP_MODE) 
        ,.A2X_LOCKED                            (A2X_LOCKED)
        ,.A2X_LOWPWR_IF                         (A2X_LOWPWR_IF)
     
        ,.A2X_AHB_LITE_MODE                     (A2X_AHB_LITE_MODE)
        ,.A2X_NUM_AHBM                          (A2X_NUM_AHBM)
        ,.A2X_SPLIT_MODE                        (AHB_SPLIT_MODE)
        ,.A2X_AHB_WBF_SPLIT                     (A2X_AHB_WBF_SPLIT)
        ,.A2X_HREADY_LOW_PERIOD                 (A2X_HREADY_LOW_PERIOD)
        ,.A2X_PP_ENDIAN                         (A2X_PP_ENDIAN)
     
        ,.A2X_HINCR_HCBCNT                      (A2X_HINCR_HCBCNT)
        ,.A2X_SINGLE_RBCNT                      (A2X_SINGLE_RBCNT)
        ,.A2X_SINGLE_WBCNT                      (A2X_SINGLE_WBCNT)
        ,.A2X_HINCR_WBCNT_MAX                   (A2X_HINCR_WBCNT_MAX)
        ,.A2X_HINCR_RBCNT_MAX                   (A2X_HINCR_RBCNT_MAX)

        ,.A2X_BLW                               (A2X_BLW)
        ,.A2X_AW                                (A2X_AW)
     
        ,.A2X_HASBW                             (A2X_INT_HASBW)
        ,.A2X_BSBW                              (A2X_INT_BSBW)
        ,.A2X_WSBW                              (A2X_INT_HWSBW)
        ,.A2X_RSBW                              (A2X_INT_HRSBW)
     
        ,.A2X_PP_DW                             (A2X_PP_DW)
        ,.A2X_PP_NUM_BYTES                      (A2X_PP_NUM_BYTES)
        ,.A2X_PP_WSTRB_DW                       (A2X_PP_WSTRB_DW)
        ,.A2X_PP_NUM_BYTES_LOG2                 (PP_NUM_BYTES_LOG2)

        ,.A2X_SP_DW                             (A2X_SP_DW)
        ,.A2X_SP_NUM_BYTES_LOG2                 (SP_NUM_BYTES_LOG2)

        ,.A2X_AW_PYLD_W                         (A2X_AW_PYLD_W_AHB)
        ,.A2X_AR_PYLD_W                         (A2X_AR_PYLD_W_AHB)
        ,.A2X_W_PYLD_W                          (A2X_W_PP_PYLD_W)
        ,.A2X_R_PYLD_W                          (A2X_R_PP_PYLD_W)
        ,.A2X_B_PYLD_W                          (A2X_B_PYLD_W)
        
        ,.A2X_RS_RATIO                          (A2X_RS_RATIO)
        ,.A2X_UPSIZE                            (A2X_UPSIZE) 
        ,.A2X_DOWNSIZE                          (A2X_DOWNSIZE) 

        ,.AW_BUF_FULL_EN                        (AW_BUF_FULL_EN)
        ,.AR_BUF_FULL_EN                        (AR_BUF_FULL_EN)
        ,.WD_BUF_FULL_EN                        (WD_BUF_FULL_EN)

      ) U_a2x_h2x (
         .clk                                   (clk_pp)
        ,.resetn                                (resetn_pp)
        // AXI Primary Port
        ,.awvalid                               (hawvalid_pp)
        ,.awready                               (awready_pp)
        ,.aw_pyld                               (aw_pyld_pp[A2X_AW_PYLD_W_AHB-1:0])
        ,.wvalid                                (hwvalid_pp)
        ,.wready                                (wready_pp)
        ,.w_pyld                                (w_pyld_pp)
        ,.bready                                (hbready_pp)
        ,.bvalid                                (bvalid_pp)
        ,.b_pyld                                (b_pyld_pp)
        ,.arvalid                               (harvalid_pp)
        ,.arready                               (arready_pp)
        ,.ar_pyld                               (ar_pyld_pp[A2X_AR_PYLD_W_AHB-1:0])
        ,.rready                                (hrready_pp)
        ,.rrvalid                               (rvalid_pp)
        ,.r_pyld                                (r_pyld_pp)
        ,.rready_lk                             (hrready_pp_lk)
        ,.rrvalid_lk                            (rvalid_pp_lk)
        ,.r_pyld_lk                             (r_pyld_pp_lk)
        ,.pp_locked                             (pp_locked)
        ,.flush                                 (flush)
        
        // AHB Ports
        ,.hmaster                               (hmaster)
        ,.hmastlock                             (hmastlock)
        ,.hsel                                  (hsel)
        ,.haddr                                 (haddr)
        ,.hwrite                                (hwrite)
        ,.hresize                               (hresize_w)
        ,.hburst                                (hburst)
        ,.htrans                                (htrans)
        ,.hsize                                 (hsize)
        ,.hprot                                 (hprot)
        ,.hwdata                                (hwdata)
        ,.haddr_sb                              (haddr_sb_w)
        ,.hwdata_sb                             (hwdata_sb_w)
        ,.hrdata                                (hrdata)
        ,.hrdata_sb                             (hrdata_sb_w)
        ,.hready                                (hready)
        ,.hready_resp                           (hready_resp)
        ,.hresp                                 (hresp)
        ,.hsplit                                (hsplit)
        ,.hincr_wbcnt_id                        (h2x_hincr_wbcnt)
        ,.hincr_rbcnt_id                        (h2x_hincr_rbcnt)
        ,.busy                                  (h2x_busy)
        ,.aw_push_empty                         (aw_fifo_push_empty)
        ,.w_push_empty                          (w_fifo_push_empty)
        ,.ar_push_empty                         (ar_push_empty)
        ,.lp_mode                               (lp_mode) 
      );
    
      // HRESIZE only available for Upsizing Configs
      assign hresize_w   = (A2X_UPSIZE==1)? hresize : (A2X_DOWNSIZE==1)? 1'b1 : 1'b0;
 
      //---------------------------------------------------
      // AHB Address Sideband
      assign haddr_sb_w  = (A2X_HASBW==0)? 1'b0 : haddr_sb; 
 
      //---------------------------------------------------
      // AHB Write Data Sideband
      assign hwdata_sb_w = (A2X_HWSBW==0)? 1'b0 : hwdata_sb;
 
      //---------------------------------------------------
      // AHB Read Data Sideband
      assign hrdata_sb   = hrdata_sb_w;

    end else begin
      assign hready_resp  = 1'b0; 
      assign hresp        = {`i_axi_a2x_1_A2X_HRESPW{1'b0}};
      assign hrdata       = {A2X_PP_DW{1'b0}};
      assign hsplit       = {16{1'b0}}; 
      assign hrdata_sb    = {A2X_INT_HRSBW{1'b0}};
      assign h2x_busy     = 1'b0;
      assign hresize_w    = 1'b0;
      assign flush        = 1'b0; 
    end
  endgenerate

  //*************************************************************************************
  // Address Channel Payload
  //*************************************************************************************
  generate
    if (A2X_PP_MODE==1) begin: AWCH
      //The length of the operands will vary by configuration. This will nor cause functional issue.       
      wire   [A2X_INT_AWSBW-1:0] awsideband_pp_w;
      assign awsideband_pp_w = ((A2X_AWSBW==0)? 1'b0 : ((A2X_AXI3==1)? awsideband_pp : awuser_pp));
      
      wire   awresize_pp_w;
      // AWRESIZE only available in Upsizing Configs. Always resize for Downsizing. 
      assign awresize_pp_w     = (A2X_UPSIZE==1)? ((A2X_AXI3==1)? awresize_pp :(awresize_pp & awcache_pp[1])) : (A2X_DOWNSIZE==1)? 1'b1 : 1'b0;
      
      // Write Address Primary Port Payload
      assign aw_pyld_pp    = {awbar_pp, awsnoop_pp, awdomain_pp, awregion_pp, awqos_pp, 1'b0, awsideband_pp_w, awid_pp, awaddr_pp, awresize_pp_w, awlen_pp, awsize_pp, awburst_pp, awlock_pp, awcache_pp, awprot_pp}; 
      
      assign pp_locked = 1'b0; // Only of use in AHB Mode
    end else begin
      assign aw_pyld_pp[A2X_AW_PYLD_W-1:A2X_AW_PYLD_W_AHB] = {(A2X_AW_PYLD_W - A2X_AW_PYLD_W_AHB){1'b0}};
      assign ar_pyld_pp[A2X_AR_PYLD_W-1:A2X_AR_PYLD_W_AHB] = {(A2X_AR_PYLD_W - A2X_AR_PYLD_W_AHB){1'b0}};
    end
  endgenerate

  // Signal to decode if the primary port transfer is non-bufferable
  // Taken from cache bit [0] in the payload when RESP_MODE is dynamic
  assign nbuf_pp = (A2X_BRESP_MODE==0) ? 1'b0 : (A2X_BRESP_MODE==1) ? 1'b1 : ~aw_pyld_pp[3];
  
  // AW SP ID 
  assign aw_id_sp = aw_pyld_sp_rs[AWID_FROM_BIT-1:AWID_TO_BIT];

  // Write Address Secondary Port Payload
  generate
    if(A2X_AXI3==1) begin: AXI3_MODE
      assign {awbar_sp, awsnoop_sp, awdomain_sp, awregion_sp, awqos_sp, aw_hburst_type_sp, awsideband_sp, awid_sp_w, 
      awaddr_sp_o, awresize_sp, awlen_sp_o, awsize_sp, awburst_sp, awlock_core_sp, awcache_sp, awprot_sp} = aw_pyld_sp;
    end else begin
      assign {awbar_sp, awsnoop_sp, awdomain_sp, awregion_sp, awqos_sp, aw_hburst_type_sp, awuser_sp, awid_sp_w, 
      awaddr_sp_o, awresize_sp, awlen_sp_o, awsize_sp, awburst_sp, awlock_core_sp, awcache_sp, awprot_sp} = aw_pyld_sp;
    end
  endgenerate

  //*************************************************************************************
  // AW Channel Instantiation 
  // *************************************************************************************
   i_axi_a2x_1_DW_axi_a2x_aw
    #(
     .A2X_PP_MODE                            (A2X_PP_MODE)
    ,.A2X_UPSIZE                             (A2X_UPSIZE)
    ,.A2X_DOWNSIZE                           (A2X_DOWNSIZE)
    ,.A2X_SP_ENDIAN                          (A2X_SP_ENDIAN)
    ,.A2X_LOCKED                             (A2X_LOCKED)
    
    ,.BOUNDARY_W                             (BOUNDARY_W)
    ,.A2X_AW                                 (A2X_AW)
    ,.A2X_BLW                                (A2X_BLW)
    ,.A2X_AHB_WBLW                           (A2X_AHB_WBLW)
    ,.A2X_AWSBW                              (A2X_INT_AWSBW)
    ,.A2X_QOSW                               (A2X_QOSW)
    ,.A2X_REGIONW                            (A2X_REGIONW)
    ,.A2X_DOMAINW                            (A2X_DOMAINW)
    ,.A2X_WSNOOPW                            (A2X_WSNOOPW)
    ,.A2X_BARW                               (A2X_BARW)
    ,.A2X_HINCR_HCBCNT                       (A2X_HINCR_HCBCNT)
    ,.A2X_HINCR_MAX_WBCNT                    (A2X_HINCR_WBCNT_MAX)
          
    ,.A2X_PP_DW                              (A2X_PP_DW)
    ,.A2X_SP_DW                              (A2X_SP_DW)
    ,.A2X_SP_MAX_SIZE                        (A2X_SP_MAX_SIZE)
    ,.A2X_PP_MAX_SIZE                        (A2X_PP_MAX_SIZE)
    
    ,.A2X_WSNF_PYLD_W                        (A2X_WSNF_PYLD_W)
    
    ,.A2X_RS_RATIO_LOG2                      (A2X_RS_RATIO_LOG2)
    ,.A2X_SP_NUM_BYTES_LOG2                  (A2X_SP_NUM_BYTES_LOG2)
    ,.A2X_PP_NUM_BYTES_LOG2                  (PP_NUM_BYTES_LOG2)
    
    ,.A2X_CLK_MODE                           (A2X_CLK_MODE)

    ,.A2X_AW_FIFO_DEPTH                      (A2X_AW_FIFO_DEPTH)
    ,.A2X_AW_FIFO_DEPTH_LOG2                 (A2X_AW_FIFO_DEPTH_LOG2)

    ,.A2X_SNF_FIFO_DEPTH                     (A2X_WD_FIFO_DEPTH)
    ,.A2X_SNF_FIFO_DEPTH_LOG2                (A2X_WD_FIFO_DEPTH_LOG2)
    ,.BYPASS_AW_AC                           (BYPASS_AW_AC)
    ,.BYPASS_AW_WS                           (BYPASS_AW_WS)
    ,.BYPASS_SNF_W                           (BYPASS_SNF_W)
    ,.A2X_BRESP_MODE                         (A2X_BRESP_MODE)
   ) U_a2x_aw (
     // Outputs
      .awready_pp                            (awready_pp)
     ,.awvalid_sp                            (awvalid_sp_rs)
     ,.aw_pyld_sp                            (aw_pyld_sp_rs)
     ,.snf_fifo_full                         (aw_snf_fifo_full)
     ,.awlast_sp                             (aw_last_sp)
     ,.sp_osaw_fifo_push_n                   (w_sp_osaw_fifo_push_n)
     ,.sp_osaw_pyld                          (w_sp_osaw_pyld)
     ,.aw_sp_active                          (aw_sp_active)
     ,.aw_push_empty                         (aw_fifo_push_empty)
     ,.snf_push_empty                        (snf_fifo_push_empty)
     ,.osw_trans                             (aw_osw_trans)
     ,.lock_req_o                            (aw_lock_req)
     ,.unlock_req_o                          (aw_unlock_req)
     ,.os_unlock                             (aw_os_unlock)
     ,.aw_nbuf_sp                            (aw_nbuf_sp)

     // Inputs
     ,.clk_pp                                (clk_pp)
     ,.resetn_pp                             (resetn_pp)
     ,.clk_sp                                (clk_sp)
     ,.resetn_sp                             (resetn_sp)
     ,.awvalid_pp                            (awvalid_pp_w)
     ,.aw_pyld_pp                            (aw_pyld_pp)
     ,.snf_pyld_pp                           (aw_snf_pyld_pp)
     ,.awready_sp                            (awready_sp_rs)
     ,.lock_grant                            (lock_grant)
     ,.unlock_grant                          (unlock_grant)
     ,.lockseq_cmp                           (lockseq_cmp)
     ,.wbuf_mode                             (siu_wbuf_mode)
     ,.sp_osaw_fifo_full                     (w_sp_osaw_fifo_full)
     ,.pp_osaw_fifo_full                     (w_pp_osaw_fifo_full)
     ,.snf_fifo_push_n                       (aw_snf_fifo_push_n)
     ,.b_osw_fifo_valid                      (b_osw_fifo_valid)
     ,.b_osw_trans                           (b_osw_trans)
     ,.bypass_aw_ws                          (bypass_aw_ws)
     ,.lock_req_i                            (ar_lock_req)
     ,.unlock_req_i                          (ar_unlock_req)
     ,.lp_mode                               (lp_mode)
   );

  //*************************************************************************************
  // Write Data Payload 
  //*************************************************************************************
  generate
    if (A2X_PP_MODE==1) begin: WCH
      //The length of the operands will vary by configuration. This will nor cause functional issue.       
      wire [A2X_INT_WSBW-1:0] wsideband_pp_w;  
      assign wsideband_pp_w = ((A2X_WSBW==0) ? 1'b0 : ((A2X_AXI3==1)? wsideband_pp : wuser_pp));
      
      // Primary Port Write Data Payload
      assign w_pyld_pp         = {wsideband_pp_w, wid_pp, wstrb_pp, wdata_pp, wlast_pp};
    end
  endgenerate

  
  // Secondary Port Write Data Payload
  generate
     if (A2X_AXI3==1) begin: WDP
       assign {wsideband_sp, wid_sp_w, wstrb_sp, wdata_sp, wlast_sp} = w_pyld_sp;
     end else begin
       assign {wuser_sp, wid_sp_w, wstrb_sp, wdata_sp, wlast_sp} = w_pyld_sp;
     end
  endgenerate

  // Assigned from payload since the payload is driven from ther H2X or the
  // AXI PP Interface
  assign wlast_pp_w = w_pyld_pp[0];
  assign wid_pp_w   = w_pyld_pp[A2X_W_PP_PYLD_W-A2X_INT_PPWSBW-1:A2X_W_PP_PYLD_W-A2X_INT_PPWSBW-`i_axi_a2x_1_A2X_IDW];

  //*************************************************************************************
  // Write Path Instantiation
  //*************************************************************************************
  i_axi_a2x_1_DW_axi_a2x_w
   #(
      .A2X_PP_MODE                          (A2X_PP_MODE)
     ,.A2X_UPSIZE                           (A2X_UPSIZE)
     ,.A2X_DOWNSIZE                         (A2X_DOWNSIZE)
     ,.A2X_EQSIZED                          (A2X_EQSIZED)
     ,.A2X_BRESP_MODE                       (A2X_BRESP_MODE)
     ,.A2X_LOCKED                           (A2X_LOCKED)

     ,.A2X_AW                               (A2X_AW)
     ,.A2X_BLW                              (A2X_BLW)
     ,.A2X_AWSBW                            (A2X_AWSBW)
     ,.A2X_WSBW                             (A2X_INT_WSBW)
     
     ,.A2X_RS_RATIO                         (A2X_RS_RATIO)
     ,.A2X_RS_RATIO_LOG2                    (A2X_RS_RATIO_LOG2)

     ,.A2X_PP_DW                            (A2X_PP_DW)
     ,.A2X_PP_WSTRB_DW                      (A2X_PP_WSTRB_DW)
     ,.A2X_PP_MAX_SIZE                      (A2X_PP_MAX_SIZE)
     ,.A2X_PP_NUM_BYTES                     (A2X_PP_NUM_BYTES)
     ,.A2X_PP_NUM_BYTES_LOG2                (PP_NUM_BYTES_LOG2)
     
     ,.A2X_SP_DW                            (A2X_SP_DW)
     ,.A2X_SP_WSTRB_DW                      (A2X_SP_WSTRB_DW)
     ,.A2X_SP_MAX_SIZE                      (A2X_SP_MAX_SIZE)
     ,.A2X_SP_NUM_BYTES                     (A2X_SP_NUM_BYTES)
     ,.A2X_SP_NUM_BYTES_LOG2                (A2X_SP_NUM_BYTES_LOG2)
      
     ,.A2X_CLK_MODE                         (A2X_CLK_MODE)
        
     ,.A2X_PP_OSAW_LIMIT                    (A2X_PP_OSAW_LIMIT)
     ,.A2X_PP_OSAW_LIMIT_LOG2               (A2X_PP_OSAW_LIMIT_LOG2)
     ,.A2X_SP_OSAW_LIMIT                    (A2X_SP_OSAW_LIMIT)
     ,.A2X_SP_OSAW_LIMIT_LOG2               (A2X_SP_OSAW_LIMIT_LOG2)
       
     ,.A2X_WD_FIFO_DEPTH                    (A2X_WD_FIFO_DEPTH)
     ,.A2X_WD_FIFO_DEPTH_LOG2               (A2X_WD_FIFO_DEPTH_LOG2)

     ,.A2X_WSNF_PYLD_W                      (A2X_WSNF_PYLD_W)
     ,.A2X_W_PP_PYLD_W                      (A2X_W_PP_PYLD_W)
     ,.A2X_W_SP_PYLD_W                      (A2X_W_SP_PYLD_W)
     ,.A2X_AW_PYLD_W                        (A2X_AW_PYLD_W)
     ,.BYPASS_SNF_W                         (BYPASS_SNF_W)
     ,.A2X_PP_ENDIAN                        (A2X_PP_ENDIAN)
     ,.A2X_SP_ENDIAN                        (A2X_SP_ENDIAN)
  ) U_a2x_w (
    // Outputs
     .wready_pp                              (wready_pp)
    ,.wvalid_sp                              (wvalid_sp_rs)
    ,.w_pyld_sp                              (w_pyld_sp_rs)
    ,.sp_osaw_fifo_full                      (w_sp_osaw_fifo_full)
    ,.pp_osaw_fifo_full                      (w_pp_osaw_fifo_full)
    ,.snf_push_n                             (aw_snf_fifo_push_n)
    ,.w_fifo_push_empty                      (w_fifo_push_empty)
   
    // Inputs
    ,.clk_pp                                 (clk_pp)
    ,.resetn_pp                              (resetn_pp)
    ,.clk_sp                                 (clk_sp)
    ,.resetn_sp                              (resetn_sp)
    ,.wbuf_mode                              (siu_wbuf_mode)
    ,.siu_snf_awlen                          (siu_snf_awlen)
    ,.sp_osaw_fifo_push_n                    (w_sp_osaw_fifo_push_n)
    ,.sp_osaw_pyld                           (w_sp_osaw_pyld)
    ,.wvalid_pp                              (wvalid_pp_w)
    ,.awvalid_pp                             (awvalid_pp_w)
    ,.awready_pp                             (awready_pp)
    ,.wready_sp                              (wready_sp_rs)
    ,.w_pyld_pp                              (w_pyld_pp)
    ,.aw_pyld_pp                             (aw_pyld_pp)
    ,.snf_fifo_full                          (aw_snf_fifo_full)
    ,.b_buf_fifo_full                        (b_buf_fifo_full)
    ,.aw_snf_pyld_pp                         (aw_snf_pyld_pp)
    ,.lp_mode                                (lp_mode)
   );   

  //*************************************************************************************
  // Write Response Channel Payload
  //*************************************************************************************
  // IF A2X has Burst response Sideband Bus
  assign bsideband_sp_w = ((A2X_BSBW==0)? {A2X_INT_BSBW{1'b0}} : ((A2X_AXI3==1)? bsideband_sp : buser_sp));

  // Secondary Port Payload
  assign b_pyld_sp      = {bsideband_sp_w, bid_sp_w, bresp_sp};

  // Primary Port Payload
  generate
     if(A2X_AXI3==1) begin:BSB
       assign {bsideband_pp, bid_pp, bresp_pp} = b_pyld_pp; 
     end else begin
       assign {buser_pp, bid_pp, bresp_pp} = b_pyld_pp;
     end
   endgenerate

  // A2X Write Response
  i_axi_a2x_1_DW_axi_a2x_b
   #(
    .A2X_PP_MODE                             (A2X_PP_MODE) 
   ,.A2X_EQSIZED                             (A2X_EQSIZED)
   ,.A2X_BRESP_ORDER                         (BRESP_ORDER)
   ,.A2X_BRESP_MODE                          (A2X_BRESP_MODE)   
   ,.A2X_LOCKED                              (A2X_LOCKED)

   ,.A2X_NUM_UWID                            (A2X_NUM_UWID)
   ,.A2X_OSW_LIMIT                           (A2X_B_OSW_LIMIT) 
   ,.A2X_OSW_LIMIT_LOG2                      (A2X_B_OSW_LIMIT_LOG2)

   ,.A2X_CLK_MODE                            (A2X_CLK_MODE)

   ,.A2X_BRESP_FIFO_DEPTH                    (BRESP_FIFO_DEPTH)
   ,.A2X_BRESP_FIFO_DEPTH_LOG2               (BRESP_FIFO_DEPTH_LOG2)

   ,.A2X_BSBW                                (A2X_INT_BSBW)
   ,.A2X_B_PYLD_W                            (A2X_B_PYLD_W)
   ,.BYPASS_UBID_FIFO                        (BYPASS_UBID_FIFO)
  ) U_a2x_b (
    // Outputs
     .bvalid_pp                              (bvalid_pp)
    ,.b_pyld_pp                              (b_pyld_pp)
    ,.bready_sp                              (bready_sp_rs)
    ,.b_buf_fifo_full                        (b_buf_fifo_full)
    ,.b_osw_fifo_valid                       (b_osw_fifo_valid)
    ,.b_osw_trans                            (b_osw_trans)

    // Inputs 
    ,.clk_pp                                 (clk_pp)
    ,.resetn_pp                              (resetn_pp)
    ,.clk_sp                                 (clk_sp)
    ,.resetn_sp                              (resetn_sp)
    ,.awvalid_sp                             (awvalid_sp_rs)
    ,.awready_sp                             (awready_sp_rs)
    ,.aw_last_sp                             (aw_last_sp)
    ,.aw_nbuf_sp                             (aw_nbuf_sp)
    ,.awid_sp                                (aw_id_sp) 
    ,.wvalid_pp                              (wvalid_pp)
    ,.wready_pp                              (wready_pp)
    ,.wlast_pp                               (wlast_pp_w)
    ,.wid_pp                                 (wid_pp_w)
    ,.bready_pp                              (bready_pp_w)
    ,.bvalid_sp                              (bvalid_sp_rs)
    ,.b_pyld_sp                              (b_pyld_sp_rs)
    ,.unlk_seq                               (unlock_seq)
   );

  //*************************************************************************************
  // AR Channel Instantiation 
  // *************************************************************************************
  generate 
    if (A2X_PP_MODE==1) begin: ARCH
      wire [A2X_INT_ARSBW-1:0] arsideband_pp_w;
      assign arsideband_pp_w = ((A2X_ARSBW==0)? {A2X_INT_ARSBW{1'b0}} : ((A2X_AXI3==1)? arsideband_pp : aruser_pp));
      
      wire   arresize_pp_w;
      assign arresize_pp_w   = (A2X_UPSIZE==1)? ((A2X_AXI3==1)? arresize_pp : (arresize_pp & arcache_pp[1]))  : (A2X_DOWNSIZE==1) ? 1'b1 : 1'b0;
      
      // Read Address Primary Port Payload
      // HBURST TYPE set to zero
      assign ar_pyld_pp    = {arbar_pp, arsnoop_pp, ardomain_pp, arregion_pp, arqos_pp, 1'b0, arsideband_pp_w, arid_pp, araddr_pp,
      arresize_pp_w, arlen_pp, arsize_pp, arburst_pp, arlock_pp, arcache_pp, arprot_pp}; 
    end
  endgenerate

  // AR SP ID 
  assign ar_id_sp = ar_pyld_sp_rs[ARID_FROM_BIT-1:ARID_TO_BIT];

  // AR Lenght 
  assign ar_len_sp = ar_pyld_sp_rs[ARLEN_FROM_BIT-1:ARLEN_TO_BIT];

  // Read Address Secondary Port Payload
  generate
     if(A2X_AXI3==1) begin: ARSB
       assign {arbar_sp, arsnoop_sp, ardomain_sp, arregion_sp, arqos_sp, ar_hburst_type_sp, arsideband_sp, arid_sp_w, 
       araddr_sp_o, arresize_sp, arlen_sp_o, arsize_sp, arburst_sp, arlock_core_sp, arcache_sp, arprot_sp} = ar_pyld_sp;
     end else begin
       assign {arbar_sp, arsnoop_sp, ardomain_sp, arregion_sp, arqos_sp, ar_hburst_type_sp, aruser_sp, arid_sp_w, 
       araddr_sp_o, arresize_sp, arlen_sp_o, arsize_sp, arburst_sp, arlock_core_sp, arcache_sp, arprot_sp} = ar_pyld_sp;
     end
   endgenerate
       

                                  
  i_axi_a2x_1_DW_axi_a2x_ar
   #(
     .A2X_PP_MODE                            (A2X_PP_MODE)
    ,.A2X_UPSIZE                             (A2X_UPSIZE)
    ,.A2X_DOWNSIZE                           (A2X_DOWNSIZE)
    ,.A2X_LOCKED                             (A2X_LOCKED)
    
    ,.BOUNDARY_W                             (BOUNDARY_W)
    ,.A2X_AW                                 (A2X_AW)
    ,.A2X_BLW                                (A2X_BLW)
    ,.A2X_AHB_RBLW                           (A2X_AHB_RBLW)
    ,.A2X_ARSBW                              (A2X_INT_ARSBW)
    ,.A2X_QOSW                               (A2X_QOSW)
    ,.A2X_REGIONW                            (A2X_REGIONW)
    ,.A2X_DOMAINW                            (A2X_DOMAINW)
    ,.A2X_RSNOOPW                            (A2X_RSNOOPW)
    ,.A2X_BARW                               (A2X_BARW)
    ,.A2X_HINCR_HCBCNT                       (A2X_HINCR_HCBCNT)
    ,.A2X_HINCR_MAX_RBCNT                    (A2X_HINCR_RBCNT_MAX)
    
    ,.A2X_PP_DW                              (A2X_PP_DW)
    ,.A2X_SP_DW                              (A2X_SP_DW)
    ,.A2X_SP_MAX_SIZE                        (A2X_SP_MAX_SIZE)
    ,.A2X_PP_MAX_SIZE                        (A2X_PP_MAX_SIZE)
    
    ,.A2X_RS_RATIO_LOG2                      (A2X_RS_RATIO_LOG2)
    ,.A2X_SP_NUM_BYTES_LOG2                  (A2X_SP_NUM_BYTES_LOG2)
    ,.A2X_PP_NUM_BYTES_LOG2                  (PP_NUM_BYTES_LOG2)
    
    ,.A2X_CLK_MODE                           (A2X_CLK_MODE)

    ,.A2X_AR_FIFO_DEPTH                      (A2X_AR_FIFO_DEPTH)
    ,.A2X_AR_FIFO_DEPTH_LOG2                 (A2X_AR_FIFO_DEPTH_LOG2)     
    ,.BYPASS_AR_AC                           (BYPASS_AR_AC)
    ,.BYPASS_AR_WS                           (BYPASS_AR_WS)
    ,.BYPASS_SNF_R                           (BYPASS_SNF_R)
   ) U_a2x_ar (
     // Outputs
      .arready_pp                            (arready_pp)
     ,.arvalid_sp                            (arvalid_sp_rs)
     ,.ar_pyld_sp                            (ar_pyld_sp_rs)
     ,.r_uid_fifo_push_n                     (r_uid_fifo_push_n)
     ,.ar_last_sp                            (ar_last_sp)
     ,.sp_osar_pyld                          (r_sp_osar_pyld)
     ,.osr_cnt_incr                          (osr_cnt_incr)
     ,.ar_fifo_alen                          (ar_fifo_alen)
     ,.osr_trans                             (ar_osr_trans)
     ,.lock_req_o                            (ar_lock_req)
     ,.unlock_req_o                          (ar_unlock_req)
     ,.os_unlock                             (ar_os_unlock)
     ,.ar_push_empty                         (ar_push_empty)

     // Inputs
     ,.clk_pp                                (clk_pp)
     ,.resetn_pp                             (resetn_pp)
     ,.clk_sp                                (clk_sp)
     ,.resetn_sp                             (resetn_sp)
     ,.arvalid_pp                            (arvalid_pp_w)
     ,.ar_pyld_pp                            (ar_pyld_pp)
     ,.arready_sp                            (arready_sp_rs)
     ,.lock_grant                            (lock_grant)
     ,.unlock_grant                          (unlock_grant)
     ,.lockseq_cmp                           (lockseq_cmp)
     ,.rbuf_mode                             (siu_rbuf_mode)
     ,.r_uid_fifo_valid                      (r_uid_fifo_valid)
     ,.r_fifo_len                            (r_fifo_len)
     ,.bypass_ar_ws                          (bypass_ar_ws)
     ,.lock_req_i                            (aw_lock_req)
     ,.unlock_req_i                          (aw_unlock_req)
     ,.r_osr_trans                           (~r_osr_fifo_empty)
     ,.lp_mode                               (lp_mode)
   );

  //*************************************************************************************
  // Read Data Payload 
  //*************************************************************************************
  assign rsideband_sp_w = ((A2X_RSBW==0)? {A2X_INT_RSBW{1'b0}} : ((A2X_AXI3==1)? rsideband_sp : ruser_sp));
 
  // Secondary Port Read Data Payload
  assign r_pyld_sp  =  {rsideband_sp_w, rid_sp_w, rresp_sp, rdata_sp, rlast_sp};

  // spyglass disable_block W164a
  // SMD: Identifies assignments in which the LHS width is less than the RHS width
  // SJ: This implmentation is as per the design requirement. There will not be any functional issue.
  // spyglass disable_block W164b
  // SMD: Identifies assignments in which the LHS width is greater than the RHS width
  // SJ : This is not a functional issue, this is as per the requirement.
  // Primary Port Read Data Payload
  generate
     if(A2X_AXI3==1) begin: RSB
       assign {rsideband_pp, rid_pp, rresp_pp, rdata_pp, rlast_pp} = r_pyld_pp;  
     end else begin
       assign {ruser_pp, rid_pp, rresp_pp, rdata_pp, rlast_pp} = r_pyld_pp;  
     end
  endgenerate
   // spyglass enable_block W164b
   // spyglass enable_block W164a

  // *************************************************************************************
  // Read Data Channel
  // *************************************************************************************
  i_axi_a2x_1_DW_axi_a2x_r
   #(
     .A2X_PP_MODE                             (A2X_PP_MODE)
    ,.A2X_UPSIZE                              (A2X_UPSIZE) 
    ,.A2X_DOWNSIZE                            (A2X_DOWNSIZE) 
    ,.A2X_BLW                                 (A2X_BLW)
    ,.A2X_AHB_RBLW                            (A2X_AHB_RBLW)
    ,.A2X_RSBW                                (A2X_INT_RSBW)  
    ,.A2X_LOCKED                              (A2X_LOCKED)
    
    ,.A2X_AHB_LK_RD_FIFO                      (A2X_AHB_LK_RD_FIFO)

    ,.A2X_READ_ORDER                          (READ_ORDER)
    ,.A2X_NUM_URID                            (NUM_URID) 
    
    ,.A2X_RS_RATIO                            (A2X_RS_RATIO) 
    
    ,.A2X_CLK_MODE                            (A2X_CLK_MODE)

    ,.A2X_PP_DW                               (A2X_PP_DW)
    ,.A2X_PP_MAX_SIZE                         (A2X_PP_MAX_SIZE)  
    ,.A2X_PP_NUM_BYTES                        (A2X_PP_NUM_BYTES)
    ,.A2X_PP_NUM_BYTES_LOG2                   (PP_NUM_BYTES_LOG2)
    
    ,.A2X_SP_DW                               (A2X_SP_DW)
    ,.A2X_SP_MAX_SIZE                         (A2X_SP_MAX_SIZE)  
    ,.A2X_SP_NUM_BYTES                        (A2X_SP_NUM_BYTES)
    ,.A2X_SP_NUM_BYTES_LOG2                   (A2X_SP_NUM_BYTES_LOG2)
    
    ,.A2X_OSR_LIMIT                           (A2X_OSR_LIMIT)
    ,.A2X_OSR_LIMIT_LOG2                      (A2X_OSR_LIMIT_LOG2)
    
    ,.A2X_RD_FIFO_DEPTH                       (A2X_RD_FIFO_DEPTH)
    ,.A2X_RD_FIFO_DEPTH_LOG2                  (A2X_RD_FIFO_DEPTH_LOG2)
    
    ,.A2X_LK_RD_FIFO_DEPTH                    (A2X_LK_RD_FIFO_DEPTH)
    ,.A2X_LK_RD_FIFO_DEPTH_LOG2               (A2X_LK_RD_FIFO_DEPTH_LOG2)
    
    ,.A2X_PP_PYLD_W                           (A2X_R_PP_PYLD_W)
    ,.A2X_SP_PYLD_W                           (A2X_R_SP_PYLD_W)

    ,.BYPASS_URID_FIFO                        (BYPASS_URID_FIFO)
    ,.BYPASS_SNF_R                            (BYPASS_SNF_R)
    ,.A2X_PP_ENDIAN                           (A2X_PP_ENDIAN)
    ,.A2X_SP_ENDIAN                           (A2X_SP_ENDIAN)
  ) U_a2x_r (
   // Outputs
    .rready_sp                   (rready_sp_rs)
   ,.rvalid_pp_lk                (rvalid_pp_lk)
   ,.r_pyld_pp_lk                (r_pyld_pp_lk)
   ,.rvalid_pp                   (rvalid_pp)
   ,.r_pyld_pp                   (r_pyld_pp)
   ,.r_uid_fifo_valid            (r_uid_fifo_valid)
   ,.r_osr_fifo_empty            (r_osr_fifo_empty)
   ,.r_fifo_len                  (r_fifo_len)

   // Inputs 
   ,.clk_pp                      (clk_pp)
   ,.resetn_pp                   (resetn_pp)
   ,.clk_sp                      (clk_sp)
   ,.resetn_sp                   (resetn_sp)
   ,.bypass_urid_fifo            (bypass_urid_fifo)
   ,.siu_rbuf_mode               (siu_rbuf_mode)
   ,.arvalid_sp                  (arvalid_sp_rs)
   ,.arready_sp                  (arready_sp_rs)
   ,.arid_sp                     (ar_id_sp)
   ,.arlast_sp                   (ar_last_sp)
   ,.arlen_sp                    (ar_len_sp)
   ,.sp_osar_pyld                (r_sp_osar_pyld)
   ,.rvalid_sp                   (rvalid_sp_rs)
   ,.rready_pp                   (rready_pp_w)
   ,.rready_pp_lk                (rready_pp_lk_w)
   ,.r_pyld_sp                   (r_pyld_sp_rs)
   ,.sp_locked                   (sp_locked)
   ,.flush                       (flush)
   ,.osr_cnt_incr                (osr_cnt_incr)
  );

  generate
    if (A2X_LOCKED==1) begin: LK
      //****************************************************************************************
      //Locked Sequence Control
      //
      // AXI can only issue a locked transfer when 
      // 1. all outstanding write have completed. 
      // 2. all outstanding reads have completed.
      // 3. the write data for the locked ahb master is at the head of the data FIFO 
      //****************************************************************************************
      i_axi_a2x_1_DW_axi_a2x_sp_lk
       
      U_a2x_lk (
        // Outputs
        .sp_locked(sp_locked),
                .lock_grant(lock_grant),
                .unlock_grant(unlock_grant),
                .lockseq_cmp(lockseq_cmp),
                .unlock_seq(unlock_seq)// Inputs
                ,
                .clk_sp(clk_sp),
                .resetn_sp(resetn_sp),
                .aw_lock_req(aw_lock_req),
                .ar_lock_req(ar_lock_req),
                .aw_unlock_req(aw_unlock_req),
                .ar_unlock_req(ar_unlock_req),
                .aw_os_unlock(aw_os_unlock),
                .ar_os_unlock(ar_os_unlock),
                .aw_osw_trans(aw_osw_trans),
                .ar_osr_trans(ar_osr_trans)
                );
    end else begin
      assign sp_locked    = 1'b0;
      assign lock_grant   = 1'b0;
      assign unlock_grant = 1'b0;
      assign lockseq_cmp  = 1'b0;
      assign unlock_seq   = 1'b0; 
    end

    if ((A2X_LOCKED==1) && (A2X_BRESP_MODE==0)) begin: PPLK
      //****************************************************************************************
      // Primary Port Locked Sequence Control
      // - After the fisrt locked sequence is detect the A2X drives awready_pp & arready_pp
      //   low until the transaction is accepted on SP.
      // - After the fisrt unlocked sequence is detect the A2X drives awready_pp & arready_pp
      //   low until the transaction is accepted on SP.
      //****************************************************************************************
      wire  arready_pp_lk_i = 1'b0;
      wire  awready_pp_lk_i = 1'b0;
      i_axi_a2x_1_DW_axi_a2x_pp_lk
       
      U_a2x_pp_lk (
        // Outputs
        //spyglass disable_block W287b
        //SMD: Output port to an instance is not connected.
        //SJ : This is as per design requirement. Warning can be ignored.
         .awready_pp_o                    ()
        ,.arready_pp_o                    ()
        //spyglass enable_block W287b
        ,.awvalid_pp_o                    (awvalid_pp_lk)
        ,.arvalid_pp_o                    (arvalid_pp_lk)
        // Inputs
        ,.clk_pp                          (clk_pp)
        ,.resetn_pp                       (resetn_pp)
        ,.awvalid_pp                      (awvalid_pp)
        ,.arvalid_pp                      (arvalid_pp)
        ,.arready_pp_i                    (arready_pp_lk_i)
        ,.awready_pp_i                    (awready_pp_lk_i)
        ,.awlock_pp                       (awlock_pp)
        ,.arlock_pp                       (arlock_pp)
        ,.aw_fifo_empty                   (aw_fifo_push_empty)
        ,.ar_fifo_empty                   (ar_push_empty)
      );
    end else begin
      assign awvalid_pp_lk = awvalid_pp_w;
      assign arvalid_pp_lk = arvalid_pp_w;
    end 
  endgenerate

  //****************************************************************************************
  // Register Slice
  //****************************************************************************************
  i_axi_a2x_1_DW_axi_rs_core
   #(
    .RS_AW_TMO    (A2X_RS_AW_TMO)
   ,.RS_AW_PLD_W  (A2X_AW_PYLD_W)
   ,.RS_AR_TMO    (A2X_RS_AR_TMO)
   ,.RS_AR_PLD_W  (A2X_AR_PYLD_W)
   ,.RS_B_TMO     (A2X_RS_B_TMO)
   ,.RS_B_PLD_W   (A2X_B_PYLD_W)
   ,.RS_W_TMO     (A2X_RS_W_TMO)
   ,.RS_W_PLD_W   (A2X_W_SP_PYLD_W)
   ,.RS_R_TMO     (A2X_RS_R_TMO)
   ,.RS_R_PLD_W   (A2X_R_SP_PYLD_W)
  ) U_a2x_rs (
    .aclk             (clk_sp)
   ,.aresetn          (resetn_sp)
   
   ,.awvalid_p        (awvalid_sp_rs)
   ,.awready_p        (awready_sp_rs)
   ,.aw_pyld_p        (aw_pyld_sp_rs)
   
   ,.awvalid_s        (awvalid_sp)
   ,.awready_s        (awready_sp)
   ,.aw_pyld_s        (aw_pyld_sp)
   
   ,.wvalid_p         (wvalid_sp_rs)
   ,.wready_p         (wready_sp_rs)
   ,.w_pyld_p         (w_pyld_sp_rs)
   
   ,.wvalid_s         (wvalid_sp)
   ,.wready_s         (wready_sp)
   ,.w_pyld_s         (w_pyld_sp)
   
   ,.bvalid_p         (bvalid_sp_rs)
   ,.bready_p         (bready_sp_rs)
   ,.b_pyld_p         (b_pyld_sp_rs)
   
   ,.bvalid_s         (bvalid_sp)
   ,.bready_s         (bready_sp)
   ,.b_pyld_s         (b_pyld_sp)
   
   ,.arvalid_p        (arvalid_sp_rs)
   ,.arready_p        (arready_sp_rs)
   ,.ar_pyld_p        (ar_pyld_sp_rs)
   
   ,.arvalid_s        (arvalid_sp)
   ,.arready_s        (arready_sp)
   ,.ar_pyld_s        (ar_pyld_sp)
   
   ,.rvalid_p         (rvalid_sp_rs)
   ,.rready_p         (rready_sp_rs)
   ,.r_pyld_p         (r_pyld_sp_rs)
   
   ,.rvalid_s         (rvalid_sp)
   ,.rready_s         (rready_sp)
   ,.r_pyld_s         (r_pyld_sp)
    
  );

endmodule
//Revision: $Id: //dwh/DW_ocb/DW_axi_a2x/axi_dev_br/src/DW_axi_a2x_core.v#12 $
