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
// File Version     :        $Revision: #6 $ 
// Revision: $Id: //dwh/DW_ocb/DW_axi_a2x/axi_dev_br/src/DW_axi_a2x_h2x_r.v#6 $ 
// --------------------------------------------------------------------
*/

`include "DW_axi_a2x_all_includes.vh"
//*************************************************************************************
// AHB Read to AXI Read Translation
// - Accepts a Read and Returns a split response
// - Recalls Read from Split when data rrvalid asserted.
// - Returns Read Data when recalled master sends a read request to the A2X//
// - Returns split for FIFO Full status.
// - Recalls Split masters when FIFO space available. 
// - Need to prevent Deadlock by splitting read on AR FIFO Full
//   - If AR is Full OSR is Full and RD FIFO full then can't recall a master
//     to drain the read data
//*************************************************************************************
module i_axi_a2x_1_DW_axi_a2x_h2x_r (/*AUTOARG*/
   // Outputs
   r_split_resp, r_retry_resp, r_error_resp, r_hsplit, r_hready_resp, 
   hrdata, hrdata_sb, arvalid, ar_pyld, rready, rready_lk, flush, busy,
   // Inputs
   clk, resetn, hsel, hready, hwrite, htrans, hburst, hmastlock, hsize, 
   ha_pyld, arready, rrvalid, r_pyld, rrvalid_lk, r_pyld_lk, 
   lk_req, lk_grant, unlk_cmp, unlk_seq, lock_seq, lp_mode
   );

  
  //*************************************************************************************
  // Parameter Decelaration
  //*************************************************************************************
  parameter   A2X_SPLIT_MODE                = 0; 
  parameter   A2X_NUM_AHBM                  = 1;
  parameter   A2X_PP_DW                     = 32; 
  parameter   A2X_PP_ENDIAN                 = 0; 
  parameter   A2X_LOCKED                    = 0; 
  parameter   A2X_LOWPWR_IF                 = 0;

  parameter   A2X_BLW                       = 4;
  parameter   A2X_AW                        = 32;
  parameter   A2X_HASBW                     = 1;
  parameter   A2X_RSBW                      = 1;


  parameter   A2X_AR_PYLD_W                 = 32;  
  parameter   A2X_R_PYLD_W                  = 32;

  parameter   AR_BUF_FULL_EN                = 0; 

  //*************************************************************************************
  // I/O Decelaration
  //*************************************************************************************
  input                                    clk;
  input                                    resetn;

  input                                    hsel;         // AHB Select  
  input                                    hready;       // AHB Select  
  input                                    hwrite;       // AHB Select  
  //spyglass disable_block W240
  //SMD: An input has been declared but is not read.
  //SJ : These signals are used in specific config only 
  input                                    hmastlock; 
  //spyglass enable_block W240
  input  [1:0]                             htrans;       // AHB address phase     
  input  [`i_axi_a2x_1_A2X_HBLW-1:0]                   hburst; 
  input  [A2X_AR_PYLD_W-1:0]               ha_pyld;
  //spyglass disable_block W240
  //SMD: An input has been declared but is not read.
  //SJ : These signals are used in specific config only 
  input  [2:0]                             hsize;
  //spyglass enable_block W240

  output                                   r_split_resp;
  output                                   r_retry_resp;
  output                                   r_error_resp;
  output [A2X_NUM_AHBM-1:0]                r_hsplit; 
  output                                   r_hready_resp;
  output [A2X_PP_DW-1:0]                   hrdata;       // AHB read data 
  output [A2X_RSBW-1:0]                    hrdata_sb;    // AHB Read Data Sideband Bus
  output                                   flush;
  output                                   busy;

    // AXI read request    
  input                                    arready;      // AXI read ready             
  output                                   arvalid;      // AXI read command valid        
  output [A2X_AR_PYLD_W-1:0]               ar_pyld;      // AXI read payload
                      
  // AXI read response & read data                       
  input                                    rrvalid;      // AXI read response valid       
  output                                   rready;       // AXI read ready             
  input  [A2X_R_PYLD_W-1:0]                r_pyld;       // AXI read Payload

  // AXI read response & read data for Locked Transactions                      
  //spyglass disable_block W240
  //SMD: An input has been declared but is not read.
  //SJ : These signals are used in specific config only 
  input                                    rrvalid_lk;      // AXI read response valid       
  //spyglass enable_block W240
  output                                   rready_lk;       // AXI read ready             
  input  [A2X_R_PYLD_W-1:0]                r_pyld_lk;       // AXI read Payload

  //spyglass disable_block W240
  //SMD: An input has been declared but is not read.
  //SJ : These signals are used in specific config only 
  input                                    lk_req;
  input                                    lk_grant;
  input                                    unlk_seq;
  input                                    unlk_cmp;
  input                                    lock_seq;
  input                                    lp_mode;
  //spyglass enable_block W240

  //*************************************************************************************
  //Signal Decelaration
  //*************************************************************************************
  wire                                     hsel_s; 
  wire                                     hsel_lk;

  wire    [`i_axi_a2x_1_A2X_IDW-1:0]                   id;               // Payload Decode
  wire    [A2X_AW-1:0]                     addr;   
  wire    [2:0]                            size;  
  wire    [2:0]                            prot; 
  wire    [3:0]                            cache; 
  wire    [1:0]                            lock;  
  wire    [1:0]                            burst_i; 
  reg     [1:0]                            burst_r; 
  wire    [1:0]                            burst; 
  wire                                     resize;
  wire    [A2X_HASBW-1:0]                  addr_sb;
  wire    [A2X_BLW-1:0]                    alen_i;
  reg     [A2X_BLW-1:0]                    alen_r;
  wire    [A2X_BLW-1:0]                    alen;
  wire                                     hburst_type_i;
  reg                                      hburst_type_r;
  wire                                     hburst_type;

  reg     [`i_axi_a2x_1_A2X_HBLW-1:0]                  hburst_o_r; 
  wire    [`i_axi_a2x_1_A2X_HBLW-1:0]                  hburst_o; 
  wire    [`i_axi_a2x_1_A2X_HBLW-1:0]                  hburst_sel; 
  wire                                     hburst_vld_o;

  reg    [A2X_NUM_AHBM-1:0]                hid_1hot_r;     // ID converted to 1-Hot
  reg    [A2X_NUM_AHBM-1:0]                rid_1hot_r;
  wire   [A2X_NUM_AHBM-1:0]                hid_1hot;     // ID converted to 1-Hot
  wire   [A2X_NUM_AHBM-1:0]                rid_1hot;
  wire                                     rlast;   
                                                         // AXI Read data
  wire  [`i_axi_a2x_1_A2X_IDW-1:0]                     rid;    
  wire  [`i_axi_a2x_1_A2X_RRESPW-1:0]                  rresp; 
  wire  [A2X_PP_DW-1:0]                    rdata; 
  wire  [A2X_RSBW-1:0]                     rsideband;
  wire  [A2X_RSBW-1:0]                     rsideband_et;

  wire                                     rlast_lk;   
  wire  [`i_axi_a2x_1_A2X_IDW-1:0]                     rid_lk;    
  wire  [A2X_PP_DW-1:0]                    rdata_lk; 
  wire  [`i_axi_a2x_1_A2X_RRESPW-1:0]                  rresp_lk; 
  wire  [A2X_RSBW-1:0]                     rsideband_lk;
  wire  [A2X_RSBW-1:0]                     rsideband_lk_et;
  wire                                     flush_lk;
  
  wire  [A2X_PP_DW-1:0]                    rdata_et_i; 

  wire  [A2X_PP_DW-1:0]                    rdata_et; 

  wire                                     htrans_nseq;     // AHB Transaction Type
  wire                                     htrans_seq;
  wire                                     htrans_idle;

  wire [A2X_NUM_AHBM-1:0]                  r_hready_resp_id;
  wire [A2X_NUM_AHBM-1:0]                  r_retry_resp_id;
  wire [A2X_NUM_AHBM-1:0]                  r_error_resp_id;
  wire [A2X_NUM_AHBM-1:0]                  r_split_resp_id;
  wire [A2X_NUM_AHBM-1:0]                  arvalid_id;
  wire [A2X_NUM_AHBM-1:0]                  rready_id;
  wire [A2X_NUM_AHBM-1:0]                  flush_id;
  wire [A2X_NUM_AHBM-1:0]                  busy_id;
  wire                                     flush_w;
  wire                                     busy_lk;
  wire                                     busy_ns;

  reg  [A2X_PP_DW-1:0]                     hrdata;       // AHB read data             
  reg  [A2X_RSBW-1:0]                      hrdata_sb;    // AHB Read Data Sideband Bus

  wire [A2X_NUM_AHBM-1:0]                  r_hsplit_w; 
 
  reg  [A2X_AR_PYLD_W-1:0]                 lk_ar_pyld_r;
  reg                                      lk_pyld_valid_r;
  wire [A2X_AR_PYLD_W-1:0]                 lk_ar_pyld;
  wire                                     lk_pyld_valid;
  wire                                     arvalid_lk;
  reg                                      lk_hready_r;
  wire                                     lk_hready;
  wire                                     lk_hready_resp;
  wire                                     lk_error_resp;
  
  wire                                     arready_s; 
  wire                                     arvalid_w;

  //*************************************************************************************
  // Read payload Decode
  //*************************************************************************************
  assign {rsideband, rid, rresp, rdata, rlast} = r_pyld;

  assign {rsideband_lk, rid_lk, rresp_lk, rdata_lk, rlast_lk} = r_pyld_lk;

  //*************************************************************************************
  // Register the Next AHB Transaction if A2X waiting for unlock response. 
  //*************************************************************************************
  generate 
  if (A2X_LOCKED==1) begin: LK
    wire lk_pyld_valid_w;
    // If a new Transaction detected while in an Unlocking Phase.
    // - Non-Split Mode
    //   - H2X responds by capturing the address driving hready_low
    // - Split Mode
    //   - H2X retruns a split response to non-locking transaction (treated as  buffer full)
    //   - H2X responds by capturing the address and driving hready_low to a locked transaction
    // If a Locking transaction detected. 
    // - H2X responds by capturing the address and driving hready low. 
    // Constant condition expression
    // This module is used for in several instances and the value depends on the instantiation. 
    // Hence below usage cannot be avoided. This will not cause any funcational issue. 
    if (A2X_SPLIT_MODE==1) begin
      assign arready_s        = (!unlk_seq) & arready; 
      assign lk_pyld_valid_w  = (unlk_seq & arvalid_w) | lk_req;
    end else begin
      assign lk_pyld_valid_w  = ((unlk_seq | unlk_cmp) & hsel & hready & (!hwrite) & (htrans==`i_axi_a2x_1_HTRANS_NSEQ)) | lk_req;
    end

    always @(posedge clk or negedge resetn) begin: lkarpyld_PROC
      if (resetn == 1'b0) begin
        lk_pyld_valid_r <= 1'b0;
        lk_ar_pyld_r    <= {A2X_AR_PYLD_W{1'b0}};
      end else begin
        if (arready && arvalid) begin
          lk_pyld_valid_r <= 1'b0;
          lk_ar_pyld_r    <= {A2X_AR_PYLD_W{1'b0}};
        // If lock transaction detected capture the Address and wait for lock
        // sequence to be granted. 
        end else if (lk_pyld_valid_w && (!lk_pyld_valid_r)) begin               
          lk_pyld_valid_r <= 1'b1;
          lk_ar_pyld_r    <= ha_pyld;
        end 
      end
    end
    assign lk_pyld_valid = lk_pyld_valid_r;
    assign lk_ar_pyld    = lk_ar_pyld_r; 

    //*************************************************************************************
    // Additional Logic for AHB Split Mode
    //*************************************************************************************
    if (A2X_SPLIT_MODE==1) begin: LKSPLIT
      //*************************************************************************************
      // AXI Read Channel Decode
      // - In Locked Mode we can reuse the NS Module for Locking Transactions. 
      //*************************************************************************************
      // spyglass disable_block W287b
      // SMD: Output port to an instance is not connected
      // SJ : hexokay_r is not connected, as this signal is not required/present when A2X_SPLIT_MODE==1.
      i_axi_a2x_1_DW_axi_a2x_h2x_r_ns
       U_a2x_h2x_r_lk (
        // Outputs
         .r_hready_resp                (lk_hready_resp)
        ,.r_error_resp                 (lk_error_resp)
        ,.arvalid                      (arvalid_w)
        ,.rready                       (rready_lk)
        ,.flush                        (flush_lk)
        ,.busy                         (busy_lk)
        
        // Inputs
        ,.clk                          (clk)
        ,.resetn                       (resetn)
        ,.hwrite                       (hwrite) 
        ,.hsel                         (hsel_lk)
        ,.hready                       (hready)
        ,.htrans                       (htrans)
        ,.hburst                       (hburst)
        ,.rrvalid                      (rrvalid_lk)
        ,.rlast                        (rlast_lk)
        ,.rresp_err                    (rresp_lk[1])
      );
      // spyglass enable_block W287b
      
      assign arvalid_lk = (lk_req & lk_grant)? lk_pyld_valid: (unlk_cmp | lk_req | unlk_seq)? 1'b0:  (lk_pyld_valid | arvalid_w);

      //*************************************************************************************
      // Registered Version of lk_hready
      //*************************************************************************************
      always @(posedge clk or negedge resetn) begin: bfhready_r_PROC
        if (resetn == 1'b0) begin
          lk_hready_r <=  1'b0;
        end else begin
          if (unlk_cmp)
            lk_hready_r <=  1'b1;
          else if (unlk_seq & hsel & hready & (!hwrite) & (htrans==`i_axi_a2x_1_HTRANS_NSEQ))
            lk_hready_r <=  1'b0;
        end
      end
      
      // If Generating an unlock transaction and new transaction appears on bus.
      // Respond with hready low until unlock response returned.
      assign lk_hready = (lk_req | lock_seq)? lk_hready_resp : unlk_seq? (lk_hready_r | (!lk_pyld_valid_w)): 1'b1; 

    end else begin // A2X_SPLIT_MODE==1
      assign arvalid_lk     = 1'b0;
      assign rready_lk      = 1'b0; 
      assign busy_lk        = 1'b0;
    end

  end  else begin
    assign lk_hready      = 1'b1; 
    assign lk_ar_pyld     = {A2X_AR_PYLD_W{1'b0}}; 
    assign rready_lk      = 1'b0;
    assign arready_s      = arready; 
    assign busy_lk        = 1'b0; 
  end
  endgenerate

  //*************************************************************************************
  //*************************************************************************************

  //*************************************************************************************
  // Non-Split or Locked Reads Reads
  //*************************************************************************************
  genvar i;
  generate
  if (A2X_SPLIT_MODE==0) begin: RNS_BLK
    reg   [A2X_AR_PYLD_W-1:0]                 lp_ar_pyld_r;
    wire  [A2X_AR_PYLD_W-1:0]                 lp_ar_pyld;
    reg                                       lp_ar_valid_r;
    wire                                      lp_ar_valid;
    wire                                      lp_mode_i;

    if (A2X_LOWPWR_IF==1) begin: LP_BLK
    

      always @(posedge clk or negedge resetn) begin: lp_pyld_PROC
        if (resetn == 1'b0) begin
          lp_ar_valid_r <= 1'b0;
          lp_ar_pyld_r  <= {A2X_AR_PYLD_W{1'b0}};
        end else begin
          if ((!lp_mode) && lp_ar_valid && arready) begin
            lp_ar_valid_r <= 1'b0;
            lp_ar_pyld_r  <= {A2X_AR_PYLD_W{1'b0}};
          end else if (lp_mode && hsel & hready & (!hwrite) & (htrans==`i_axi_a2x_1_HTRANS_NSEQ)) begin               
            lp_ar_valid_r <= 1'b1;
            lp_ar_pyld_r  <= ha_pyld;
          end 
        end
      end
      assign lp_ar_valid = lp_ar_valid_r;
      assign lp_ar_pyld  = lp_ar_pyld_r;
      assign lp_mode_i   = lp_mode; 

    end else begin 
      assign lp_ar_valid = 1'b0;
      assign lp_ar_pyld  = {A2X_AR_PYLD_W{1'b0}};
      assign lp_mode_i   = 1'b0; 
    end

    //*************************************************************************************
    // AXI Read Channel Decode
    //*************************************************************************************
    i_axi_a2x_1_DW_axi_a2x_h2x_r_ns
    
    U_h2x_a2x_r_ns (
        // Outputs
         .r_hready_resp                (r_hready_resp)
        ,.r_error_resp                 (r_error_resp)
        ,.arvalid                      (arvalid_w)
        ,.rready                       (rready)
        ,.flush                        (flush_w)
        ,.busy                         (busy_ns)
        
        // Inputs
        ,.clk                          (clk)
        ,.resetn                       (resetn)
        ,.hwrite                       (hwrite) 
        ,.hsel                         (hsel)
        ,.hready                       (hready)
        ,.htrans                       (htrans)
        ,.hburst                       (hburst)
        ,.rrvalid                      (rrvalid)
        ,.rlast                        (rlast)
        ,.rresp_err                    (rresp[1])
    );


    assign r_split_resp = 1'b0;
    assign r_retry_resp = 1'b0;
    assign r_hsplit     = {A2X_NUM_AHBM{1'b0}};
    assign flush        = flush_w; 

    // If in locked Mode generate push into FIFO when lock granted. Do not
    // generatet a push into FIFO when in unlock mode. 
    // Constant condition expression
    // This module is used for in several instances and the value depends on the instantiation. 
    // Hence below usage cannot be avoided. This will not cause any funcational issue. 
    if (A2X_LOCKED==1) begin
      assign arvalid = (lk_req & lk_grant)? lk_pyld_valid: (unlk_seq | lk_req | unlk_cmp)? 1'b0 : lk_pyld_valid | lp_ar_valid | arvalid_w;
      assign ar_pyld = lp_ar_valid? lp_ar_pyld  : (lk_pyld_valid)? lk_ar_pyld : ha_pyld;
    end else begin
      assign arvalid = lp_mode_i? 1'b0 : lp_ar_valid | arvalid_w;
      assign ar_pyld = lp_ar_valid? lp_ar_pyld  : ha_pyld;
    end
      
    //*************************************************************************************
    // Endian Transform 
    // Little Endian (LE) to BE-23 or BE-A
    //*************************************************************************************
    if (A2X_PP_ENDIAN!=0) begin: RNS_ET
      // Need to created a registered version of hsize. 
      reg  [2:0]                             et_size_r;
      wire [2:0]                             et_size;
      always @(posedge clk or negedge resetn) begin: et_size_PROC
        if (resetn == 1'b0) begin
          et_size_r <=  3'b0;
        end else begin
          if (hready) begin
            et_size_r  <=  hsize; 
          end
        end
      end
      assign et_size = (hready)? hsize : et_size_r;

      i_axi_a2x_1_DW_axi_a2x_h2x_et
       #(
         .A2X_DW                 (A2X_PP_DW) 
      ) U_a2x_r_pp_et (
        // Outputs
        .data_o                  (rdata_et) 
        // Inputs
        ,.data_i                 (rdata) 
        ,.size_i                 (et_size)
      );
     
    assign rsideband_et = rsideband;
    end else begin
      assign rdata_et     = rdata;
      assign rsideband_et = rsideband;
    end
    
    //*************************************************************************************
    // Registered AHB Read Data Outputs 
    //*************************************************************************************
    always @(posedge clk or negedge resetn) begin: hrdata_PROC
      if (resetn == 1'b0) begin
        hrdata    <=  {A2X_PP_DW{1'b0}}; 
        hrdata_sb <=  {A2X_RSBW{1'b0}};
      end else begin
        //if (!flush_w && rrvalid && rready) begin
        // rrvalid used in r_ns block to generate rready.
        if ((!flush_w) && rready) begin
          hrdata    <=  rdata_et; 
          hrdata_sb <=  rsideband_et;
        end else if (hready) begin
          hrdata    <=  {A2X_PP_DW{1'b0}}; 
          hrdata_sb <=  {A2X_RSBW{1'b0}};
        end
      end
    end

    assign busy = busy_ns;

  end else begin: RS_BLK

      assign busy_ns = 1'b0;
      //*************************************************************************************
      // Split Reads
      //*************************************************************************************
      // Signals
      integer                                  num;

      wire  [3:0]                              rstat;
      reg   [A2X_NUM_AHBM-1:0]                 recall_vld;
      wire                                     hrvalid;
      wire                                     hrvalid_lk;

      wire                                     r4_rvalid;
      reg   [A2X_R_PYLD_W-1:0]                 rdpyld_r1,     rdpyld_r2,     rdpyld_r3,     rdpyld_r4;

      wire                                     r0_rlast,      r1_rlast,      r2_rlast,      r3_rlast,     r4_rlast;   
      wire  [`i_axi_a2x_1_A2X_IDW-1:0]                     r0_rid,        r1_rid,        r2_rid,        r3_rid,       r4_rid;    
      wire  [A2X_PP_DW-1:0]                    r0_rdata,      r1_rdata,      r2_rdata,      r3_rdata,     r4_rdata; 
      wire  [`i_axi_a2x_1_A2X_RRESPW-1:0]                  r0_resp,       r1_resp,       r2_resp,       r3_resp,      r4_resp; 
      wire  [A2X_RSBW-1:0]                     r0_rsideband,  r1_rsideband,  r2_rsideband,  r3_rsideband, r4_rsideband, r4_rsideband_et; 

      wire  [A2X_NUM_AHBM-1:0]                 hburst_vld_bus; 
      wire  [`i_axi_a2x_1_A2X_HBLW-1:0]                    hburst_bus     [0:A2X_NUM_AHBM-1]; 

      //*************************************************************************************
      // Split Reads
      //*************************************************************************************
      // If in Locked Mode then Module not enabled. 
      assign hsel_lk = hmastlock & hsel; 
      assign hsel_s = !hmastlock & hsel; 

      assign {hburst_type_i, addr_sb, id, addr, resize, alen_i, size, burst_i, lock, cache, prot} = ha_pyld;

      // Decode the AXI Burst Type
      if (AR_BUF_FULL_EN==1) begin: HB1
        always @(*) begin: burst_PROC
          if (hburst_vld_o) begin
            burst_r       = ((hburst_o==`i_axi_a2x_1_HBURST_WRAP4) || (hburst_o==`i_axi_a2x_1_HBURST_WRAP8) || (hburst_o==`i_axi_a2x_1_HBURST_WRAP16))? `i_axi_a2x_1_AWRAP: `i_axi_a2x_1_AINCR;
            hburst_type_r =  (hburst_o==`i_axi_a2x_1_HBURST_INCR)? 1'b1: 1'b0;
          end else begin
            burst_r       = burst_i;
            hburst_type_r = hburst_type_i;
          end
        end
        assign burst       = burst_r;
        assign hburst_type = hburst_type_r; 
      
        // Decode the AXI Length
        assign hburst_sel =  (hburst_vld_o)? hburst_o : hburst;
        always@(*) begin: arlenPROC
          alen_r = {A2X_BLW{1'b0}}; 
          case(hburst_sel)
            // spyglass disable_block W164b
            // SMD: Identifies assignments in which the LHS width is greater than the RHS width
            // SJ : This is not a functional issue, this is as per the requirement.
            //      Hence this can be waived.  
            `i_axi_a2x_1_HBURST_WRAP4:  alen_r = 4'h3;
            `i_axi_a2x_1_HBURST_INCR4:  alen_r = 4'h3;
            `i_axi_a2x_1_HBURST_WRAP8:  alen_r = 4'h7;
            `i_axi_a2x_1_HBURST_INCR8:  alen_r = 4'h7;
            `i_axi_a2x_1_HBURST_WRAP16: alen_r = 4'hf;
            `i_axi_a2x_1_HBURST_INCR16: alen_r = 4'hf;
            `i_axi_a2x_1_HBURST_INCR:   alen_r = alen_i;
            // spyglass enable_block W164b
            default:        alen_r = {A2X_BLW{1'b0}}; 
          endcase 
        end
        assign alen = alen_r; 
      end else begin
        assign alen        = alen_i; 
        assign burst       = burst_i;
        assign hburst_type = hburst_type_i; 
      end     

      //*************************************************************************************
      // AHB HTRANS Decode
      // _dp -> Data Phase version of signal. 
      //*************************************************************************************
      assign htrans_nseq    = (htrans==`i_axi_a2x_1_HTRANS_NSEQ);
      assign htrans_seq     = (htrans==`i_axi_a2x_1_HTRANS_SEQ);
      assign htrans_idle    = (htrans==`i_axi_a2x_1_HTRANS_IDLE);
      
      //*************************************************************************************
      // ID One-Hot Decode
      // - Dummy Master is 0 so never assert bit zero,
      //*************************************************************************************
      //spyglass disable_block W415a
      //SMD: Signal may be multiply assigned (beside initialization) in the same scope.
      //SJ : This is not an issue. It is initialized before assignment to avoid latches.
      if (A2X_NUM_AHBM>2) begin: ONEHOTR
        always @(*) begin:id_1hot_PROC
          hid_1hot_r   = {A2X_NUM_AHBM{1'b0}}; 
          rid_1hot_r   = {A2X_NUM_AHBM{1'b0}}; 
          for(num=1 ; num<A2X_NUM_AHBM; num=num+1) begin
            if(id==num)  hid_1hot_r[num] = 1'b1;
            if(r4_rid==num) rid_1hot_r[num] = 1'b1;
          end
        end    
        assign hid_1hot = hid_1hot_r; 
        assign rid_1hot = rid_1hot_r; 
      end else begin
        assign hid_1hot = (id==1)?     2'b10 : {A2X_NUM_AHBM{1'b0}}; 
        assign rid_1hot = (r4_rid==1)? 2'b10 : {A2X_NUM_AHBM{1'b0}}; 
      end
      //spyglass enable_block W415a
      
      //*************************************************************************************
      // A2X Enabled for Read Transaction
      //*************************************************************************************
      assign hrvalid    = hsel_s & hready & (!hwrite) & (htrans_nseq | htrans_seq);

      assign hrvalid_lk = lock_seq & hsel & hready & (!hwrite) & (htrans_nseq | htrans_seq);

      //*************************************************************************************
      // AHB Master Read Instance
      // - Dummy Master is 0 so never assert bit zero,
      //*************************************************************************************
      for (i = 1; i <A2X_NUM_AHBM; i=i+1) begin : URID 
        i_axi_a2x_1_DW_axi_a2x_h2x_r_id
         #(
          .AR_BUF_FULL_EN                (AR_BUF_FULL_EN)
        ) U_a2x_h2x_r_id (
           .r_hready_resp                (r_hready_resp_id[i])
          ,.r_split_resp                 (r_split_resp_id[i])
          ,.r_retry_resp                 (r_retry_resp_id[i])
          ,.r_error_resp                 (r_error_resp_id[i])
          ,.r_hsplit                     (r_hsplit_w[i])
          ,.arvalid                      (arvalid_id[i])
          ,.rready                       (rready_id[i])
          ,.flush                        (flush_id[i])
          ,.hburst_o                     (hburst_bus[i])
          ,.hburst_vld_o                 (hburst_vld_bus[i])
          ,.busy                         (busy_id[i])
          
          ,.clk                          (clk)
          ,.resetn                       (resetn)
          ,.hwrite                       (hwrite) 
          ,.hsel                         (hsel_s)
          ,.hid_valid                    (hid_1hot[i])   
          ,.rid_valid                    (rid_1hot[i])
          ,.hburst_i                     (hburst)
          ,.hready                       (hready)
          ,.htrans_nseq                  (htrans_nseq)
          ,.htrans_seq                   (htrans_seq)
          ,.htrans_idle                  (htrans_idle)
          ,.arready                      (arready_s)
          ,.recall_vld                   (recall_vld[i])
          ,.rrvalid                      (r4_rvalid)
          ,.rlast                        (r4_rlast)
          ,.rresp_err                    (r4_resp[1])
        );
      end
      
      // Dummy Master
      assign r_hready_resp_id[0]   = 1'b1;
      assign r_split_resp_id[0]    = 1'b0;
      assign r_retry_resp_id[0]    = 1'b0;
      assign r_error_resp_id[0]    = 1'b0;
      assign r_hsplit_w[0]         = 1'b0;
      assign arvalid_id[0]         = 1'b0;
      assign rready_id[0]          = 1'b0;
      assign flush_id[0]           = 1'b0;
      assign hburst_vld_bus[0]     = 1'b0;      
      assign hburst_bus[0]         = {(`i_axi_a2x_1_A2X_HBLW){1'b0}};      
      assign busy_id[0]            = 1'b0;
      
      // Read Channel Responses - Only one AHB Master can response at any time so
      // we can just Gate the responses from all Read ID's.
      // In Locked Configurations only the Locked or Non-Locking Block can respond at any time. 
      // we can just Gate the responses from all Read ID's.
      assign r_hready_resp  = (A2X_LOCKED==0)? (&r_hready_resp_id) : lk_hready & (&r_hready_resp_id);
      // If during a unlocking transactioin an new Non-Locked Read Transaction appears then the A2X responds with hready low until the 
      // unlock transaction has completed. 
      assign r_split_resp   = (A2X_LOCKED==0)? (|r_split_resp_id)  : (|r_split_resp_id);
      assign r_retry_resp   = (A2X_LOCKED==0)? (|r_retry_resp_id)  : (|r_retry_resp_id);

      assign r_error_resp   = (A2X_LOCKED==0)? (|r_error_resp_id)  : (rready_lk && (!flush_lk))? lk_error_resp : (|r_error_resp_id);

      // Read HSPLIT
      assign r_hsplit = r_hsplit_w;
      
      //*************************************************************************************
      // Read Address 
      //*************************************************************************************
      // If in locked Mode generate push into FIFO when lock granted. Do not
      // generatet a push into FIFO when in unlock mode. 
      // Constant condition expression
      // This module is used for in several instances and the value depends on the instantiation. 
      // Hence below usage cannot be avoided. This will not cause any funcational issue. 
      if (A2X_LOCKED==1) begin
        assign arvalid = (unlk_seq) ? 1'b0 : (arvalid_lk | (|arvalid_id));
        assign ar_pyld = (lk_pyld_valid)? lk_ar_pyld : arvalid_lk? ha_pyld : {hburst_type, addr_sb, id, addr, resize, alen, size, burst, lock, cache, prot};
      end else begin
        assign arvalid = (|arvalid_id);
        assign ar_pyld = {hburst_type, addr_sb, id, addr, resize, alen, size, burst, lock, cache, prot};
      end
      
      // Decode AHB Burst Type
      //spyglass disable_block W415a
      //SMD: Signal may be multiply assigned (beside initialization) in the same scope.
      //SJ : This is not an issue. It is initialized before assignment to avoid latches.
      always @(*) begin: burstbus_PROC
        integer j; 
        hburst_o_r     = {(`i_axi_a2x_1_A2X_HBLW){1'b0}};
        for (j=0; j<A2X_NUM_AHBM; j=j+1) begin
          hburst_o_r     = hburst_bus[j] | hburst_o_r;
        end
      end
      //spyglass enable_block W415a

      assign hburst_vld_o = |hburst_vld_bus;
      assign hburst_o     = hburst_o_r;
      
      //*************************************************************************************
      // AXI Read Data Channel
      //*************************************************************************************
      assign flush_w   = |flush_id;
      assign flush     = 1'b0; 
        
      //*************************************************************************************
      // Read Data Pipe Line. 
      // 
      // The Read Data Pipeline allows the A2X to stream read Data on the AHB
      // Bus. To achieve this the A2X initally pops the First data beat from
      // the Read data FIFO at the same time it recalls the AHB Master. From
      // when the AHB Master is recalled to when it appears on the AHB Bus
      // with a NSEQ takes three clock cycles. In this time the A2X pops off
      // the next three data beats from the FIFO
      //
      // When the 3 stage pipeline is full and AHB Master returns with for its
      // data the A2X continues to pop data from the FIFO into the pipeline. Once
      // a new AHB Master is seen at the head of the FIFO the A2X recalls the
      // next AHB Master. This allows read data to be streamed as the next AHB
      // Master can retrn with its NSEQ when the last data beat is returned
      // for the current AHB Master.
      //
      // In the example below we have a two INCR 4 transaction to Master 1 and
      // Master 2. The A2X recalls M1 when its data is at the head of the Read
      // DAta FIFO and pops the 1st three data beats into the Pipeline. When
      // M1 returns the A2X returns the data at head of Pipeline and
      // countinues to pop data from the FIFO. When the 2nd transaction (SEQ)
      // is seen for M1, M2's data is at the head of the FIFO. At this point
      // the A2X will recall M2 and by the time arbiter has returned granted
      // M2, M1 will have completed its last data beat and M2'sdata will be at
      // the head of the read Pipeline 
      //
      // hmaster     |       M1      |       M2      |
      // htrans      |   |   | N | S | S | S | N | S | S | S |
      // hsplit      |RM1|   |   |   |RM2| 
      // hrdata                  |D0 |D1 |D2 |D3 |A0 |A1 |A2 | A3 | 
      //
      // RD FIFO |D0 |D1 |D2 |D3 |A0 |A1 |A2 |A3 |
      //
      // The A2X can only stream defined length Bursts. Because of the nature of the AHB
      // Bus the A2X cannot stream INCR's unless the HINCR ARLEN is eqial the AHB INCR Burst
      // length. If the AHB Master's INCR Burst is greater than or less than the HINCR_ARLEN
      // then the A2X will need to flush additional read data from FIFO or generate a new
      // AXI write address and return a split response to AHB Master. 
      //
      // Also the A2X cannot stream INCR's unless the AHB Masters. 
      //*************************************************************************************
      
      //--------------------------------------------------------------------
      //System Verilog Assertions
      //--------------------------------------------------------------------

      always @(posedge clk or negedge resetn) begin: rdr1_PROC
        if (resetn == 1'b0) begin
          rdpyld_r1 <= {A2X_R_PYLD_W{1'b0}};
          rdpyld_r2 <= {A2X_R_PYLD_W{1'b0}};
          rdpyld_r3 <= {A2X_R_PYLD_W{1'b0}};
        end else begin
          // If poping data from FIF0 or Pipeline Stage 3 not full
          // shift data along pipeline. If no data in FIFO when shifting set
          // pipeline stage 1 to zero. 
          if (rready || ((~rstat[3]) && (|rstat[2:1]))) begin
            rdpyld_r1 <= rstat[0]? r_pyld : {A2X_R_PYLD_W{1'b0}};
            rdpyld_r2 <= rdpyld_r1;
            rdpyld_r3 <= rdpyld_r2;
          end
        end
      end

      // *************************************************************************************
      // AXI Read Pipeline Decode
      // *************************************************************************************
      assign {r0_rsideband, r0_rid, r0_resp, r0_rdata, r0_rlast} = r_pyld;
      assign {r1_rsideband, r1_rid, r1_resp, r1_rdata, r1_rlast} = rdpyld_r1;
      assign {r2_rsideband, r2_rid, r2_resp, r2_rdata, r2_rlast} = rdpyld_r2;
      assign {r3_rsideband, r3_rid, r3_resp, r3_rdata, r3_rlast} = rdpyld_r3;

      // Output from last (3rd) Pipeline stage. 
      assign {r4_rsideband, r4_rid, r4_resp, r4_rdata, r4_rlast} = rdpyld_r3;

      // Pipeline Stage valid data.
      assign r4_rvalid = (rstat[3])? 1'b1: 1'b0;

      // Read Data Pipeline Stage Status. 
      assign rstat[0] = rrvalid;
      assign rstat[1] = r1_rid!={`i_axi_a2x_1_A2X_IDW{1'b0}};
      assign rstat[2] = r2_rid!={`i_axi_a2x_1_A2X_IDW{1'b0}};
      assign rstat[3] = r3_rid!={`i_axi_a2x_1_A2X_IDW{1'b0}};

      //*************************************************************************************
      //Read Data FIFO Pop Control
      //
      //- If valid read data and Pipeline Stage 3 not full pop data from FIFO.
      //- If Flushing data for RID pop data from FIFO. 
      //- Otherwise pop control driven from RID Instance.
      //*************************************************************************************
      reg rready_r; 
      always @(*) begin : rready_PROC
        rready_r = 1'b0; 
        if ((rrvalid && (!rstat[3])) || flush_w)
          rready_r = 1'b1; 
        else
          rready_r = |rready_id;
      end

      assign rready = rready_r;       

      //*************************************************************************************
      //AHB Master Recall. 
      //
      //- If Read Data Pipeline is empty recall AHB Master at head of Read Data FIFO.
      //- If Data in Read Pipeline all have the same ID then recall next AHB
      //  Master at head of FIFO. 
      //- Otherwise A2X cannot stream read data so only recall data at head of
      //  Pipeline after current AHB Master returns for its data. 
      //*************************************************************************************
      //spyglass disable_block W415a
      //SMD: Signal may be multiply assigned (beside initialization) in the same scope.
      //SJ : This is not an issue. It is initialized before assignment to avoid latches.
      always @(*) begin: recall_PROC
        recall_vld  = {A2X_NUM_AHBM{1'b0}}; 
        for(num=1 ; num<A2X_NUM_AHBM; num=num+1) begin
          if (((~(|rstat[3:1])) && rrvalid)  || ((r3_rid==r2_rid) && (r3_rid==r1_rid) && (hrvalid && rrvalid && (r3_rid==id)))) begin
            if (r0_rid==num) recall_vld[num] = 1'b1;
          end else if (hrvalid && (r4_rid==id)) begin
            if (r3_rid==num) recall_vld[num] = 1'b1;
          end else begin 
            if (r4_rid==num) recall_vld[num] = 1'b1;
          end
        end
      end
      //spyglass enable_block W415a

      //*************************************************************************************
      // Endian Transform 
      // Little Endian (LE) to BE-23 or BE-A
      //*************************************************************************************
      assign rdata_et_i = (A2X_LOCKED==0)? r4_rdata: (rready_lk && (!flush_lk))? rdata_lk : r4_rdata;
      if (A2X_PP_ENDIAN!=0) begin: RS_ET
        // Need to created a registered version of hsize. 
        reg  [2:0]                             et_size_r;
        wire [2:0]                             et_size;
        always @(posedge clk or negedge resetn) begin: et_size_PROC
          if (resetn == 1'b0) begin
            et_size_r <=  3'b0;
          end else begin
            if (hready) begin
              et_size_r  <=  hsize; 
            end
          end
        end
        assign et_size = (hready)? hsize : et_size_r;        

        i_axi_a2x_1_DW_axi_a2x_h2x_et
         #(
           .A2X_DW                 (A2X_PP_DW) 
        ) U_a2x_r_pp_et (
          // Outputs
          .data_o                  (rdata_et) 
          // Inputs
          ,.data_i                 (rdata_et_i) 
          ,.size_i                 (et_size)
        );

        assign r4_rsideband_et = r4_rsideband;
        assign rsideband_lk_et = rsideband_lk;
      end else begin
        assign rdata_et     = (A2X_LOCKED==0)? r4_rdata: (rready_lk && (!flush_lk))? rdata_lk : r4_rdata;
        assign r4_rsideband_et = r4_rsideband;
        assign rsideband_lk_et = rsideband_lk;
      end

      //*************************************************************************************
      // Registered AHB Read Data Outputs 
      //*************************************************************************************
      if (A2X_LOCKED==0) begin: HRDATDA_LK
        // When not in locked mode data is taken from the PP R Channel when
        // valid read data available and AHB Master returs
        always @(posedge clk or negedge resetn) begin: hrdata_PROC
          if (resetn == 1'b0) begin
            hrdata    <=  {A2X_PP_DW{1'b0}}; 
            hrdata_sb <=  {A2X_RSBW{1'b0}};
          end else begin
            if ((!flush_w) && hrvalid && (|rready_id)) begin
              hrdata    <=  rdata_et; 
              hrdata_sb <=  r4_rsideband_et;
            end else if (hready) begin
              hrdata    <=  {A2X_PP_DW{1'b0}}; 
              hrdata_sb <=  {A2X_RSBW{1'b0}};
            end
          end
        end

      end else begin

        // When not in locked mode data is taken from the PP R Channel when
        // valid read data available and AHB Master returs
        // When in locked mode data taken from the PP Locked R Channel when
        // data available.
        always @(posedge clk or negedge resetn) begin: hrdata_PROC
          if (resetn == 1'b0) begin
            hrdata    <=  {A2X_PP_DW{1'b0}}; 
            hrdata_sb <=  {A2X_RSBW{1'b0}};
          end else begin
            if ((!flush_w) && hrvalid && (|rready_id)) begin
              hrdata    <=  rdata_et; 
              hrdata_sb <=  r4_rsideband_et;
            end else if ((!flush_lk) && rrvalid_lk && rready_lk) begin
              hrdata    <=  rdata_et; 
              hrdata_sb <=  rsideband_lk_et;
            end else if (hready) begin
              hrdata    <=  {A2X_PP_DW{1'b0}}; 
              hrdata_sb <=  {A2X_RSBW{1'b0}};
            end
          end
        end

      end

      // Busy status output used for Low Power.
      assign busy = busy_lk | (|busy_id) | rstat[3]; 

      //--------------------------------------------------------------------
      // System Verilog Assertions
      //--------------------------------------------------------------------
  end
  endgenerate

endmodule
