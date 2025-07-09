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
// File Version     :        $Revision: #10 $ 
// Revision: $Id: //dwh/DW_ocb/DW_axi_a2x/axi_dev_br/src/DW_axi_a2x_h2x.v#10 $ 
**
** --------------------------------------------------------------------
**
** File     : DW_axi_a2x_h2x.v
** Created  : Thu Jan 27 11:01:41 MET 2011
** Abstract :Top-Level File for AHB-AXI.
** Block consists of 
**  DW_axi_a2x_h2x_decode: Decode AHB Address
**  DW_axi_a2x_h2x_w     : Generate AHB Write to AXI Write. 
**  DW_axi_a2x_h2x_r     : Generate AHB Read to AXI Read
**  DW_axi_a2x_h2x_hresp : Returns AXI Response from AXI
**  DW_axi_a2x_h2x_lock  : Generate AXI Unlocking Transaction
**
**                      |<--------|-------|<--A2X PP B--------
**          ----------  |   |---->| Write |
**          |        |  |   |     |-------|---A2X PP AW & W-->
** --AHB--->| Decode |------|
**          |        |  |   |     |-------|---A2X PP AR-->
**          ----------  |   |---->| Read  |
**                      |         |-------|<--A2X PP R---- 
**                      |             |
**          |-------|<---             |
** <-Resp---| HRESP |                 |
**          |-------|<-----------------
**
** AHB Writes
**  - Defined Length Transfers converted to AXI and sent to AW & W Channel 
**  - Non-Bufferable Writes Split on Last Data Beat of Transaction & recalled when response returned on A2X PP B Ch
**  - Hready Driven low when AXI cannot accept transaction. 
**  - INCR's converted to defined length transaction. 
**  - Write Data strobed for EBT'd conditions and INCR's not equals to defined length. 
**
** AHB Reads
**  - Read Transaction Split on 1st Transaction and recalled when read data available on PP R Channel. 
**  - AHB Master SPlit when AXI cannot accept transaction. 
**  - INCR's converted to defined length AXI Read Transaction
**  - Read Data flushed from PP R Channel if INCR's not equal to defined length.
**  - Read Data Flushed if AHB Master does not return for its read data after error returned. 
** --------------------------------------------------------------------
*/

// Reduction of a single bit expression is redundant. 
// This is acceptable in the A2X

`include "DW_axi_a2x_all_includes.vh"

module i_axi_a2x_DW_axi_a2x_h2x (/*AUTOARG*/
   // Outputs
   hready_resp, hresp, hrdata, hsplit, hrdata_sb, awvalid, aw_pyld, 
   wvalid, w_pyld, bready, arvalid, ar_pyld, rready, rready_lk, 
   pp_locked, busy, flush,
   // Inputs
   clk, resetn, hmaster, hmastlock, hsel, haddr, hwrite, hresize, 
   hburst, htrans, hsize, hprot, hwdata, hready, haddr_sb, hwdata_sb, 
   awready, wready, bvalid, b_pyld, arready, rrvalid, r_pyld, 
   rrvalid_lk, r_pyld_lk, w_push_empty, aw_push_empty, ar_push_empty,
   lp_mode, hincr_wbcnt_id, hincr_rbcnt_id
   );

  //*************************************************************************************
  // Parameter Decelaration 
  //*************************************************************************************  
  parameter   A2X_BRESP_MODE                  = 1; 
  parameter   A2X_LOCKED                      = 0;
  parameter   A2X_LOWPWR_IF                   = 0; 
  parameter   A2X_HREADY_LOW_PERIOD           = 8; 

  parameter   A2X_PP_ENDIAN                   = 0; 

  parameter   A2X_AHB_LITE_MODE               = 0;
  parameter   A2X_SPLIT_MODE                  = 1;
  parameter   A2X_AHB_WBF_SPLIT               = 1;  // 1 - Enable Split capability on Buffer Full
  parameter   A2X_NUM_AHBM                    = 2;

  parameter   A2X_HINCR_HCBCNT                = 1;
  parameter   A2X_SINGLE_RBCNT                = 1;
  parameter   A2X_SINGLE_WBCNT                = 1;
  parameter   A2X_HINCR_WBCNT_MAX             = 1;
  parameter   A2X_HINCR_RBCNT_MAX             = 1;

  parameter   A2X_BLW                         = 4;
  parameter   A2X_AW                          = 32;

  parameter   A2X_HASBW                       = 1;
  parameter   A2X_BSBW                        = 1;
  parameter   A2X_WSBW                        = 1;
  parameter   A2X_RSBW                        = 1;

  parameter   A2X_PP_DW                       = 32;
  parameter   A2X_PP_NUM_BYTES                = 4;
  parameter   A2X_PP_WSTRB_DW                 = 4;
  parameter   A2X_PP_NUM_BYTES_LOG2           = 2;

  parameter   A2X_SP_DW                       = 32;
  parameter   A2X_SP_NUM_BYTES_LOG2           = 2;

  parameter   A2X_AW_PYLD_W                   = 32; 
  parameter   A2X_AR_PYLD_W                   = 32;  
  parameter   A2X_W_PYLD_W                    = 32;  
  parameter   A2X_R_PYLD_W                    = 32;
  parameter   A2X_B_PYLD_W                    = 32;

  parameter   A2X_RS_RATIO                    = 1;
  parameter   A2X_UPSIZE                      = 0; 
  parameter   A2X_DOWNSIZE                    = 0; 

  parameter   AW_BUF_FULL_EN                  = 0;
  parameter   AR_BUF_FULL_EN                  = 0;
  parameter   WD_BUF_FULL_EN                  = 0;

  localparam  A2X_HINCR_RBCNT_IDW             = (A2X_HINCR_HCBCNT==1)? 4 : (A2X_SINGLE_RBCNT==1)? 4 :  4*A2X_NUM_AHBM; // AHB Read HINCR BCNT BUS Width
  localparam  A2X_HINCR_WBCNT_IDW             = (A2X_HINCR_HCBCNT==1)? 4 : (A2X_SINGLE_WBCNT==1)? 4 :  4*A2X_NUM_AHBM; // AHB Write HINCR BCNT BUS Width

  //*************************************************************************************
  // Signal Decelaration 
  //*************************************************************************************
  //spyglass disable_block W240
  //SMD: An input has been declared but is not read.
  //SJ : Some signals are used in specific config only 

  // Clocks and Resets
  input                                       clk;         // AHB Clock
  input                                       resetn;      // AHB Reset

  // AHB Interface
  input  [`i_axi_a2x_A2X_IDW-1:0]                       hmaster;      // AHB Master ID Bus
  input                                       hmastlock;    // AHB lock              

  input                                       hsel;         // AHB Select     
  input  [A2X_AW-1:0]                         haddr;        // AHB Address Bus
  input                                       hwrite;       // AHB write indicator   
  input                                       hresize;      // AHB resize              
  input  [`i_axi_a2x_A2X_HBLW-1:0]                      hburst;       // AHB burst             
  input  [1:0]                                htrans;       // AHB address phase     
  input  [2:0]                                hsize;        // AHB size              
  input  [3:0]                                hprot;        // AHB protection        
  input  [A2X_PP_DW-1:0]                      hwdata;       // AHB write data        

  input                                       hready;
  output                                      hready_resp;  // AHB ready                 
  output [`i_axi_a2x_A2X_HRESPW-1:0]                    hresp;        // AHB response              
  output [A2X_PP_DW-1:0]                      hrdata;       // AHB read data 
  output [15:0]                               hsplit;       // AHB Split 

  input  [A2X_HASBW-1:0]                      haddr_sb;     // AHB Address Sideband Bus
  input  [A2X_WSBW-1:0]                       hwdata_sb;    // AHB Write Data Sideband Bus
  output [A2X_RSBW-1:0]                       hrdata_sb;    // AHB Read Data Sideband Bus
                         
  //---------------------------AXI Master/Interface-------------------------------- 
  // AXI write request
  input                                       awready;    // AXI write ready         
  output                                      awvalid;    // AXI write valid    
  output [A2X_AW_PYLD_W-1:0]                  aw_pyld;    // AXI Write Address Payload

  // AXI write data
  input                                       wready;     // AXI write ready            
  output                                      wvalid;     // AXI write data valid        
  output [A2X_W_PYLD_W-1:0]                   w_pyld;     // AXI Write Data Payload
                          
  // AXI write response                                  
  input                                       bvalid;     // AXI write response valid      
  output                                      bready;     // AXI write response ready            
  input [A2X_B_PYLD_W-1:0]                    b_pyld;     // AXI write response Payload   
                      
  // AXI read request    
  input                                       arready;    // AXI read ready             
  output                                      arvalid;    // AXI read command valid        
  output [A2X_AR_PYLD_W-1:0]                  ar_pyld;    // AXI read payload
                      
  // AXI read response & read data                       
  input                                       rrvalid;    // AXI read response valid       
  output                                      rready;     // AXI read ready             
  input  [A2X_R_PYLD_W-1:0]                   r_pyld;     // AXI read Payload

  input                                       rrvalid_lk; // AXI Locked read response valid       
  output                                      rready_lk;  // AXI Locked read ready             
  input  [A2X_R_PYLD_W-1:0]                   r_pyld_lk;  // AXI Locked read Payload
  output                                      pp_locked;  // Hand shaking between H2X and X2X

  // Software Interface
  input  [A2X_HINCR_WBCNT_IDW-1:0]            hincr_wbcnt_id;
  input  [A2X_HINCR_RBCNT_IDW-1:0]            hincr_rbcnt_id;

  output                                      busy;
  output                                      flush; 
  input                                       aw_push_empty;
  input                                       ar_push_empty;
  input                                       w_push_empty;

  input                                       lp_mode;    // A2X in Low Power Mode
  //spyglass enable_block W240

  //*************************************************************************************
  // Signal Decelaration
  //*************************************************************************************
  // These are dummy wires used to connect the unconnected ports.
  // Hence will not drive any nets.
  wire  [1:0]                                 htrans_dp;
  wire                                        hwrite_dp;
  wire  [`i_axi_a2x_A2X_HBLW-1:0]                       hburst_dp;            
  wire  [2:0]                                 hsize_dp;        // AHB size              
  // These nets are used to connect the logic under certain configuration.
  // But this may not drive any net in some other configuration. 
  wire  [`i_axi_a2x_A2X_IDW-1:0]                        hmaster_dp;      // AHB Master ID Bus
  // These are dummy wires used to connect the unconnected ports.
  // Hence will not drive any nets.
  wire                                        hmastlock_dp;

  wire  [A2X_AW_PYLD_W-1:0]                   haw_pyld;
  // These nets are used to connect the logic under certain configuration.
  // But this may not drive any net in some other configuration. 
  wire  [A2X_AW_PYLD_W-1:0]                   haw_unlk_pyld;
  wire  [A2X_AR_PYLD_W-1:0]                   har_pyld;

  wire  [A2X_NUM_AHBM-1:0]                    w_hsplit;         // Split recall 
  wire  [A2X_NUM_AHBM-1:0]                    r_hsplit;

  wire                                        r_retry_resp;     // AHB Responses Type
  wire                                        r_error_resp;
  wire                                        r_split_resp;
  wire                                        w_retry_resp;
  wire                                        w_error_resp;
  wire                                        w_split_resp;

  wire                                        w_hready_resp;   
  wire                                        r_hready_resp;


  wire                                        ar_lk_req;
  wire                                        aw_lk_req;
  wire                                        lk_grant;
  wire                                        lk_seq;
  wire                                        unlk_req;
  wire                                        unlk_seq;
  wire                                        unlk_cmp;
  wire                                        unlk_grant;
  wire                                        unlk_grant_d;
  wire  [A2X_AW_PYLD_W-1:0]                   unlk_aw_pyld;
  wire  [A2X_W_PYLD_W-1:0]                    unlk_w_pyld;

  wire                                        write_busy;
  wire                                        read_busy;

  wire                                        awready_w;    
  wire                                        wready_w;    
  wire                                        w_buf_full;

  //*************************************************************************************
  // H2X Busy
  //*************************************************************************************
  assign busy = write_busy | read_busy;

  //*************************************************************************************
  // Decodes the AHB Channel
  //
  // - Decodes the AHB Transaction and generates an AXI Transaction. 
  //*************************************************************************************
  i_axi_a2x_DW_axi_a2x_h2x_decode
   #(
      .A2X_LOCKED                             (A2X_LOCKED)
     ,.A2X_NUM_AHBM                           (A2X_NUM_AHBM)
     ,.A2X_HASBW                              (A2X_HASBW) 
     ,.A2X_BLW                                (A2X_BLW)
     ,.A2X_AW                                 (A2X_AW) 
     ,.A2X_AW_PYLD_W                          (A2X_AW_PYLD_W)
     ,.A2X_AR_PYLD_W                          (A2X_AR_PYLD_W)
     ,.A2X_HINCR_HCBCNT                       (A2X_HINCR_HCBCNT)
     ,.A2X_SINGLE_RBCNT                       (A2X_SINGLE_RBCNT)
     ,.A2X_SINGLE_WBCNT                       (A2X_SINGLE_WBCNT)
     ,.A2X_HINCR_WBCNT_MAX                    (A2X_HINCR_WBCNT_MAX)
     ,.A2X_HINCR_RBCNT_MAX                    (A2X_HINCR_RBCNT_MAX)
  ) U_h2x_decode (
    // Outputs
     .har_pyld                                (har_pyld)
    ,.haw_pyld                                (haw_pyld)
    ,.haw_unlk_pyld                           (haw_unlk_pyld)
    ,.htrans_dp                               (htrans_dp)
    ,.hburst_dp                               (hburst_dp)
    ,.hwrite_dp                               (hwrite_dp)
    ,.hsize_dp                                (hsize_dp)
    ,.hmaster_dp                              (hmaster_dp)
    ,.hmastlock_dp                            (hmastlock_dp)
    // Inputs
    ,.clk                                     (clk)
    ,.resetn                                  (resetn)
    ,.hready                                  (hready)  // j:
    ,.hmaster                                 (hmaster)
    ,.hmastlock                               (hmastlock)
    ,.haddr                                   (haddr)
    ,.hwrite                                  (hwrite)
    ,.hresize                                 (hresize)
    ,.hburst                                  (hburst)
    ,.htrans                                  (htrans)
    ,.hsize                                   (hsize)
    ,.hprot                                   (hprot)
    ,.haddr_sb                                (haddr_sb)
    ,.hincr_rbcnt_id                          (hincr_rbcnt_id)
    ,.hincr_wbcnt_id                          (hincr_wbcnt_id)
   );

  //*************************************************************************************
  // AHB-AXI Write Instance.
  //
  // - Generates AXI WRites and responds to AHB Write Transactions
  //*************************************************************************************
  i_axi_a2x_DW_axi_a2x_h2x_w
   #(
     .A2X_RS_RATIO                            (A2X_RS_RATIO) 
    ,.A2X_UPSIZE                              (A2X_UPSIZE)
    ,.A2X_DOWNSIZE                            (A2X_DOWNSIZE)
    ,.A2X_PP_ENDIAN                           (A2X_PP_ENDIAN)
    ,.A2X_SPLIT_MODE                          (A2X_SPLIT_MODE)
    ,.A2X_AHB_LITE_MODE                       (A2X_AHB_LITE_MODE)
    ,.A2X_AHB_WBF_SPLIT                       (A2X_AHB_WBF_SPLIT)
    ,.A2X_BRESP_MODE                          (A2X_BRESP_MODE) 
    ,.A2X_NUM_AHBM                            (A2X_NUM_AHBM)
    ,.HREADY_LOW_PERIOD                       (A2X_HREADY_LOW_PERIOD)
    ,.A2X_LOCKED                              (A2X_LOCKED)
    
    ,.A2X_BLW                                 (A2X_BLW)
    ,.A2X_AW                                  (A2X_AW)
    
    ,.A2X_HASBW                               (A2X_HASBW)
    ,.A2X_BSBW                                (A2X_BSBW)
    ,.A2X_WSBW                                (A2X_WSBW)
    
    ,.A2X_PP_DW                               (A2X_PP_DW)
    ,.A2X_PP_NUM_BYTES                        (A2X_PP_NUM_BYTES)
    ,.A2X_PP_WSTRB_DW                         (A2X_PP_WSTRB_DW)
    ,.A2X_PP_NUM_BYTES_LOG2                   (A2X_PP_NUM_BYTES_LOG2)

    ,.A2X_SP_DW                               (A2X_SP_DW)
    ,.A2X_SP_NUM_BYTES_LOG2                   (A2X_SP_NUM_BYTES_LOG2)

    ,.A2X_AW_PYLD_W                           (A2X_AW_PYLD_W)
    ,.A2X_W_PYLD_W                            (A2X_W_PYLD_W)
    ,.A2X_B_PYLD_W                            (A2X_B_PYLD_W)
    ,.AW_BUF_FULL_EN                          (AW_BUF_FULL_EN)
    ,.WD_BUF_FULL_EN                          (WD_BUF_FULL_EN)
  ) U_h2x_w (
    // Outputs
     .w_hready_resp                           (w_hready_resp)
    ,.w_split_resp                            (w_split_resp)
    ,.w_retry_resp                            (w_retry_resp)
    ,.w_error_resp                            (w_error_resp)
    ,.w_hsplit                                (w_hsplit)
    ,.awvalid                                 (awvalid) 
    ,.aw_pyld                                 (aw_pyld)
    ,.wvalid                                  (wvalid)
    ,.w_pyld                                  (w_pyld)
    ,.bready                                  (bready) 
    ,.busy                                    (write_busy)
    ,.w_buf_full                              (w_buf_full)
    // Inputs
    ,.clk                                     (clk)
    ,.resetn                                  (resetn)
    ,.hsel                                    (hsel)
    ,.hready                                  (hready)
    ,.hready_resp_i                           (hready_resp)
    ,.hwrite                                  (hwrite)
    ,.hburst                                  (hburst)  // Do not need _dec signal as writes not split when Buffer Full
    ,.htrans                                  (htrans)
    ,.hburst_dp                               (hburst_dp)
    ,.hsize_dp                                (hsize_dp)
    ,.ha_pyld                                 (haw_pyld)
    ,.hwdata                                  (hwdata)
    ,.hwdata_sb                               (hwdata_sb)
    ,.awready                                 (awready_w)
    ,.wready                                  (wready_w)
    ,.bvalid                                  (bvalid)
    ,.b_pyld                                  (b_pyld)
    ,.lk_req                                  (aw_lk_req)
    ,.lk_grant                                (lk_grant)
    ,.unlk_req                                (unlk_req)
    ,.unlk_grant                              (unlk_grant)
    ,.unlk_grant_d                            (unlk_grant_d)
    ,.unlk_cmp                                (unlk_cmp)
    ,.unlk_aw_pyld                            (unlk_aw_pyld)
    ,.unlk_w_pyld                             (unlk_w_pyld)
    ,.hmastlock                               (hmastlock)
    ,.lk_seq                                  (lk_seq)
    ,.unlk_seq                                (unlk_seq)
   );

  //*************************************************************************************
  // AHB-AXI Read Translation
  //
  // - Generates AHB Read Transactions and Responds to AHB read Transactions. 
  //*************************************************************************************
  i_axi_a2x_DW_axi_a2x_h2x_r
   #(
     .A2X_SPLIT_MODE                          (A2X_SPLIT_MODE) 
    ,.A2X_NUM_AHBM                            (A2X_NUM_AHBM)
    ,.A2X_PP_DW                               (A2X_PP_DW)
    ,.A2X_PP_ENDIAN                           (A2X_PP_ENDIAN)
    ,.A2X_LOCKED                              (A2X_LOCKED)
    ,.A2X_LOWPWR_IF                           (A2X_LOWPWR_IF)

    ,.A2X_BLW                                 (A2X_BLW)
    ,.A2X_AW                                  (A2X_AW)

    ,.A2X_HASBW                               (A2X_HASBW)
    ,.A2X_RSBW                                (A2X_RSBW)

    ,.A2X_AR_PYLD_W                           (A2X_AR_PYLD_W)
    ,.A2X_R_PYLD_W                            (A2X_R_PYLD_W)
    ,.AR_BUF_FULL_EN                          (AR_BUF_FULL_EN)
  ) U_h2x_r (  
    // Outputs
     .r_hready_resp                           (r_hready_resp)
    ,.r_split_resp                            (r_split_resp)
    ,.r_retry_resp                            (r_retry_resp)
    ,.r_error_resp                            (r_error_resp)
    ,.r_hsplit                                (r_hsplit)
    ,.arvalid                                 (arvalid)
    ,.ar_pyld                                 (ar_pyld)
    ,.rready                                  (rready)
    ,.rready_lk                               (rready_lk)
    ,.hrdata                                  (hrdata)
    ,.hrdata_sb                               (hrdata_sb)
    ,.flush                                   (flush)
    ,.busy                                    (read_busy)
    // Inputs
    ,.clk                                     (clk)
    ,.resetn                                  (resetn)
    ,.hsel                                    (hsel)
    ,.hready                                  (hready)
    ,.hwrite                                  (hwrite)
    ,.htrans                                  (htrans)
    ,.hburst                                  (hburst)
    ,.hmastlock                               (hmastlock)
    ,.hsize                                   (hsize)
    ,.ha_pyld                                 (har_pyld)
    ,.arready                                 (arready)
    ,.rrvalid                                 (rrvalid)
    ,.r_pyld                                  (r_pyld)
    ,.rrvalid_lk                              (rrvalid_lk)
    ,.r_pyld_lk                               (r_pyld_lk)
    ,.lk_req                                  (ar_lk_req)
    ,.lk_grant                                (lk_grant)
    ,.unlk_cmp                                (unlk_cmp)
    ,.unlk_seq                                (unlk_seq)
    ,.lock_seq                                (pp_locked)
    ,.lp_mode                                 (lp_mode) 
   );

  //*************************************************************************************
  // H2X Response
  //
  // Generate AHB response based on response type returned from AHB Wreite and
  // Read Control. 
  //*************************************************************************************
  i_axi_a2x_DW_axi_a2x_h2x_resp
   #(
      .A2X_NUM_AHBM                       (A2X_NUM_AHBM)
     ,.A2X_SPLIT_MODE                     (A2X_SPLIT_MODE) 
  ) U_h2x_resp (
    // Outputs
     .hsplit                              (hsplit)
    ,.hready_resp                         (hready_resp)
    ,.hresp                               (hresp)
    // Inputs 
    ,.clk                                 (clk)
    ,.resetn                              (resetn)
    ,.w_hready_resp                       (w_hready_resp)
    ,.r_hready_resp                       (r_hready_resp)
    ,.w_error_resp                        (w_error_resp)
    ,.w_split_resp                        (w_split_resp)
    ,.r_error_resp                        (r_error_resp)
    ,.r_split_resp                        (r_split_resp)
    ,.w_hsplit                            (w_hsplit)
    ,.r_hsplit                            (r_hsplit)
   );

  generate 
  if (A2X_LOCKED==1) begin: H2X_LOCKED
    //*************************************************************************************
    // H2X Locked Generation
    //*************************************************************************************
    i_axi_a2x_DW_axi_a2x_h2x_lk
     #(
       .A2X_AW_PYLD_W                 (A2X_AW_PYLD_W)
      ,.A2X_W_PYLD_W                  (A2X_W_PYLD_W)
      ,.A2X_PP_DW                     (A2X_PP_DW)
      ,.A2X_WSBW                      (A2X_WSBW)
    ) U_h2x_lock (
      // Outputs
       .locked                        (pp_locked)
      ,.aw_lk_req                     (aw_lk_req)
      ,.ar_lk_req                     (ar_lk_req)
      ,.lk_grant                      (lk_grant)
      ,.unlk_req                      (unlk_req)
      ,.unlk_grant                    (unlk_grant)
      ,.unlk_grant_d                  (unlk_grant_d)
      ,.unlk_seq                      (unlk_seq)
      ,.lk_seq                        (lk_seq)
      ,.unlk_cmp                      (unlk_cmp)
      ,.unlk_aw_pyld                  (unlk_aw_pyld)
      ,.unlk_w_pyld                   (unlk_w_pyld)
      // Inputs
      ,.hclk                          (clk)
      ,.hresetn                       (resetn)
      ,.hsel                          (hsel)
      ,.hmaster                       (hmaster)
      ,.hmaster_dp                    (hmaster_dp)
      ,.htrans                        (htrans)
      ,.hwrite                        (hwrite)
      ,.hmastlock                     (hmastlock)
      ,.hready                        (hready)
      ,.haw_unlk_pyld                 (haw_unlk_pyld)
      ,.aw_push_empty                 (aw_push_empty)
      ,.ar_push_empty                 (ar_push_empty)
      ,.w_push_empty                  (w_push_empty)
      ,.w_buf_full                    (w_buf_full)
      ,.lp_mode                       (lp_mode)
   );
    assign awready_w    = awready;
    assign wready_w     = wready; 
  end else begin
    assign awready_w    = awready;
    assign wready_w     = wready; 
    assign pp_locked    = 1'b0;
    assign ar_lk_req    = 1'b0;
    assign aw_lk_req    = 1'b0;
    assign lk_grant     = 1'b0;
    assign unlk_req     = 1'b0;
    assign unlk_grant   = 1'b0;
    assign unlk_grant_d = 1'b0;
    assign unlk_cmp     = 1'b0;
    assign unlk_seq     = 1'b0; 
    assign lk_seq       = 1'b0; 
    assign unlk_aw_pyld = {A2X_AW_PYLD_W{1'b0}};
    assign unlk_w_pyld  = {A2X_W_PYLD_W{1'b0}};
  end
  endgenerate
  
endmodule
//Revision: $Id: //dwh/DW_ocb/DW_axi_a2x/axi_dev_br/src/DW_axi_a2x_h2x.v#10 $
