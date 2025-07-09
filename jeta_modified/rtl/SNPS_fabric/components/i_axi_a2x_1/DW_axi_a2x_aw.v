/* --------------------------------------------------------------------
**
// ------------------------------------------------------------------------------
// 
// Copyright 2012 - 2020 Synopsys, INC.
// 
// This Synopsys IP and all associated documentation are proprietary to
// Synopsys, Inc. and may only be used pursuant to the terms and conditions of a
// written license agreement with Synopsys, Inc. All other use, reproduction,
// modification, or distribution of the Synopsys IP or the associated
// documentation is strictly prohibited.
// 
// Component Name   : DW_axi_a2x
// Component Version: 2.04a
// Release Type     : GA
// ------------------------------------------------------------------------------

// 
// Release version :  2.04a
// File Version     :        $Revision: #90 $ 
// Revision: $Id: //dwh/DW_ocb/DW_axi_a2x/amba_dev/src/DW_axi_a2x_aw.v#90 $ 
**
** --------------------------------------------------------------------
**
** File     : DW_axi_a2x_aw.v
** Created  : Thu Jan 27 11:01:40 MET 2011
** Abstract :
**
** --------------------------------------------------------------------
*/

/* --------------------------------------------------------------------
**                  Address Channel Architecture Diagram
**-------------------------------------------------------------------------------
**  
**                                  To Write Bresp Channel
**                                           ^
**                                           |
**-------------------------------------------|-------------------------------------
**                                           |
**                                           |
**   PP AW Channel   |----------|      |-----------|
**  ---------------->|    AW    |----->|           |
**                   |   FIFO   |      |           |
**  |------|         |----------|      |  Address  |   
**  | FIFO |             ^             |           | SP AW Channel
**  |Pusher|-------------|             | Generator |--------------->
**  |------|             V             |           |
**     |             |----------|      |           |
**     |             |    SNF   |      |           |
**     |             |   FIFO   |----->|           |
**     |             |----------|      |-----------|
**     |                                     |
**     |                                     |  
**-----|-------------------------------------|-------------------------------------
**     |       To Write Data Channel         |
**     V                                     V
**   Resize                            Write Data control
**    FIFO                                   FIFO
**
**
**-------------------------------------------------------------------------------
*/

`include "DW_axi_a2x_all_includes.vh"

module i_axi_a2x_1_DW_axi_a2x_aw (/*AUTOARG*/
   // Outputs
   awready_pp, awvalid_sp, aw_pyld_sp, awlast_sp, 
   lock_req_o, unlock_req_o, os_unlock, 
   sp_osaw_fifo_push_n, snf_fifo_full, sp_osaw_pyld, aw_sp_active, 
   snf_push_empty, osw_trans, aw_push_empty, aw_nbuf_sp, 
   // Inputs
   clk_pp, resetn_pp, clk_sp, resetn_sp, awvalid_pp, aw_pyld_pp, 
   snf_pyld_pp, awready_sp, wbuf_mode, 
   snf_fifo_push_n, sp_osaw_fifo_full, pp_osaw_fifo_full,
   b_osw_fifo_valid, bypass_aw_ws, b_osw_trans, 
   lock_req_i, unlock_req_i, lock_grant, unlock_grant, lockseq_cmp,
   pp_rst_n, sp_rst_n, lp_mode
   );

  //*************************************************************************************
  // Parameters
  //*************************************************************************************
  parameter  A2X_WSNF_PYLD_W          = 8;

  parameter  A2X_PP_MODE              = 0;   // 0 = AHB 1 = AXI
  parameter  A2X_UPSIZE               = 0;   // 0 = Not Upsized 1 = Upsized
  parameter  A2X_DOWNSIZE             = 0;   // 0 = Not Downsized 1 Downsized
  parameter  A2X_SP_ENDIAN            = 0; 
  parameter  A2X_LOCKED               = 0;   // A2X SUpports Locked Transactions

  parameter  BOUNDARY_W               = 12;  // 4K AXI Boundary
  parameter  A2X_AW                   = 32;  // Address Width
  parameter  A2X_BLW                  = 3;   // Burst Length Width
  parameter  A2X_AHB_WBLW             = 4; 
  parameter  A2X_AWSBW                = 1;   // Address Sideband Width
  parameter  A2X_QOSW                 = 1;   // QOS Signal Width
  parameter  A2X_REGIONW              = 1;   // Region Signal Width
  parameter  A2X_DOMAINW              = 1;   // Domain Signal Width
  parameter  A2X_WSNOOPW              = 1;   // Snoop Signal width
  parameter  A2X_BARW                 = 1;   // Bar Signal Width
  parameter  A2X_HINCR_HCBCNT         = 0; 
  parameter  A2X_HINCR_MAX_WBCNT      = 0;

  parameter  A2X_PP_DW                = 32;
  parameter  A2X_SP_DW                = 32;
  parameter  A2X_SP_MAX_SIZE          = 2;
  parameter  A2X_PP_MAX_SIZE          = 2;

  parameter  A2X_RS_RATIO_LOG2        = 0;
  parameter  A2X_SP_NUM_BYTES_LOG2    = 2;
  parameter  A2X_PP_NUM_BYTES_LOG2    = 2;

  parameter  A2X_CLK_MODE             = 0;
  parameter  A2X_PP_SYNC_DEPTH        = 2;
  parameter  A2X_SP_SYNC_DEPTH        = 2;

  parameter  A2X_AW_FIFO_DEPTH        = 32;
  parameter  A2X_AW_FIFO_DEPTH_LOG2   = 5;

  parameter  A2X_SNF_FIFO_DEPTH       = 32;
  parameter  A2X_SNF_FIFO_DEPTH_LOG2  = 5;

  parameter  BYPASS_AW_AC             = 1;
  parameter  BYPASS_AW_WS             = 1;
  parameter  BYPASS_SNF_W             = 1; 

  parameter  A2X_BRESP_MODE           = 0;

  // Primary Port Length 
  localparam BLW_PP                   = ((A2X_PP_MODE==1) || (A2X_PP_DW==A2X_SP_DW)) ? A2X_BLW : A2X_AHB_WBLW;

  // Address Channel Payload
  localparam A2X_AW_PYLD_W            = A2X_BARW + A2X_WSNOOPW + A2X_DOMAINW + A2X_REGIONW + A2X_QOSW + 
                                        `A2X_HBTYPE_W +  A2X_AWSBW + `A2X_IDW +  A2X_AW   + `A2X_RSW + A2X_BLW + `A2X_BSW + 
                                        `A2X_BTW      + `A2X_LTW   + `A2X_CTW + `A2X_PTW;

  // Lint Warning - Can't have A2X_PP_NUM_BYTES_LOG2-1:0
  localparam PP_NUM_BYTES_LOG2 = (A2X_PP_NUM_BYTES_LOG2==0)? 1 : A2X_PP_NUM_BYTES_LOG2; 

  // SP Control FIFO Payload 
  localparam A2X_SP_OSAW_PYLD_W       = `A2X_RSW + 1 + `A2X_BSW + PP_NUM_BYTES_LOG2 + 1 + A2X_BLW + 1; 

  // SPC FIFO Control
  localparam SPC_IDLE                 = 1'b0; 
  localparam SPC_WAIT                 = 1'b1;

  //*************************************************************************************
  // IO Decelaration
  //*************************************************************************************
  // spyglass disable_block W240
  // SMD: An input has been declared but is not read
  // SJ: These nets are used to connect the logic under certain configuration.
  input                                       clk_pp;
  input                                       resetn_pp;

  input                                       clk_sp;
  input                                       resetn_sp;

  input                                       bypass_aw_ws; 
  // AXI Write Address
  //These nets are used to connect the logic under certain configuration.
  //But this may not drive some of the nets. This will not cause any functional issue.
  output                                      awready_pp;             // Primary Port Payload
  input                                       awvalid_pp;
  input  [A2X_AW_PYLD_W-1:0]                  aw_pyld_pp;
  input  [A2X_WSNF_PYLD_W-1:0]                snf_pyld_pp;

  input                                       awready_sp;             // Secondary Port Payload
  output                                      awvalid_sp;
  output [A2X_AW_PYLD_W-1:0]                  aw_pyld_sp;
  output                                      awlast_sp;
  
  // Locked Control
  input                                       lock_grant;                 // Locked Control
  input                                       unlock_grant;                 
  input                                       lockseq_cmp;                 
  output                                      os_unlock;                 
  output                                      lock_req_o;
  input                                       lock_req_i;
  output                                      unlock_req_o;
  input                                       unlock_req_i;

  // Software Control
  input                                       wbuf_mode;

  // FIFO Control
  input                                       snf_fifo_push_n;        // FIFO Controls
  output                                      sp_osaw_fifo_push_n;

  output                                      snf_fifo_full;
  input                                       sp_osaw_fifo_full;
  input                                       pp_osaw_fifo_full;
  input                                       b_osw_fifo_valid;
  input                                       b_osw_trans; 

  output [A2X_SP_OSAW_PYLD_W-1:0]             sp_osaw_pyld;          // Resize information - Generated from output of AW FIFO. 

  output                                      aw_sp_active;          // SP AW Channel is not actively generating SP transactions. 
  output                                      aw_push_empty;
  output                                      snf_push_empty;
  output                                      osw_trans;
  output                                      aw_nbuf_sp;

  input                                       pp_rst_n;
  input                                       sp_rst_n;
  input                                       lp_mode;
  // spyglass enable_block W240

  //*************************************************************************************
  // Signal Decelaration
  //*************************************************************************************
  //  FIFO Control
  //These are dummy wires used to connect the unconnected ports.
  wire   [`A2X_IDW-1:0]                       awid_pp;    
  wire   [A2X_AW-1:0]                         awaddr_pp; 
  wire   [A2X_BLW-1:0]                        awlen_pp; 
  wire   [`A2X_BSW-1:0]                       awsize_pp;     
  wire   [`A2X_BTW-1:0]                       awburst_pp;   
  wire   [`A2X_LTW-1:0]                       awlock_pp;   
  wire   [`A2X_CTW-1:0]                       awcache_pp; 
  wire   [`A2X_PTW-1:0]                       awprot_pp; 
  wire                                        awresize_pp;
  wire   [A2X_AWSBW-1:0]                      awsideband_pp;
  wire   [A2X_QOSW-1:0]                       awqos_pp;
  wire   [A2X_REGIONW-1:0]                    awregion_pp;
  wire   [A2X_DOMAINW-1:0]                    awdomain_pp;
  wire   [A2X_BARW-1:0]                       awbar_pp;
  wire   [A2X_WSNOOPW-1:0]                    awsnoop_pp;
  wire                                        aw_hburst_type_pp;

  wire                                        aw_fifo_push_n;
  wire                                        snf_fifo_push_n;

  wire                                        aw_fifo_pop;
  wire                                        aw_fifo_pop_n;
  wire                                        snf_fifo_pop_n;

  wire                                        aw_fifo_full;

  wire                                        aw_fifo_empty;
  wire                                        snf_fifo_empty;
  wire                                        snf_push_empty_w;
  wire                                        snf_push_empty;

  wire                                        snf_fifo_push_n_w;
  wire                                        snf_fifo_pop_n_w;
  wire                                        snf_fifo_full_w;
  wire                                        snf_fifo_empty_w;

  wire  [A2X_AW_FIFO_DEPTH_LOG2:0]            aw_fifo_pop_count;
  wire  [A2X_AW_FIFO_DEPTH_LOG2:0]            aw_fifo_push_count;
  wire  [A2X_SNF_FIFO_DEPTH_LOG2:0]           snf_fifo_pop_count;
  wire  [A2X_SNF_FIFO_DEPTH_LOG2:0]           snf_fifo_push_count;

  wire                                        sp_osaw_fifo_full_w;

  //  FIFO Payload's
  wire  [A2X_AW_PYLD_W-1:0]                   aw_pyld_fifo_o;
  wire  [A2X_WSNF_PYLD_W-1:0]                 snf_pyld_fifo_o;

  //Not used in certain configurations
  wire  [A2X_BLW-1:0]                         awlen_sp;

  wire                                        sp_add_active;        // Address Generator Active i.e. In process of breaking down a PP Address
  wire  [31:0]                                sp_max_len;           // Maximum SP AW Length
  wire                                        sp_osw_fifo_valid;    // Secondary Port Outstanding FIFO's Valid;

  //Not used in certain configurations
  reg                                         spc_state;
  reg                                         spc_nxt_state;
  wire                                        spc_stchange;

  //These are dummy wires used to connect the unconnected ports.
  wire                                        onek_exceed;

  wire  [A2X_AW-1:0]                          ws_addr;          // Wrap Splitter output Address
  wire  [`A2X_BSW-1:0]                        ws_size;     
  wire  [`A2X_RSW-1:0]                        ws_resize; 
  wire                                        ws_last;
  wire                                        ws_fixed;
  
  //These are dummy wires used to connect the unconnected ports.
  wire  [BLW_PP-1:0]                          ws_alen;          // Wrap Splitter output Length

  wire                                        w_snf_pop_en;
  //These nets are used to connect the logic under certain configuration.
  //But this may not drive some of the nets. This will not cause any functional issue.
  wire                                        trans_en; // transaction enable
  wire                                        aw_fifos_pop_empty;

  //*************************************************************************************
  // Address and SNF FIFO Control
  //*************************************************************************************
  // Primary Port Ready to accept AW Address when 
  // - AW FIFO is not FUll or 
  // - Upsizing FIFO is not Full for Upsizing Configs. 
  assign awready_pp       = !(aw_fifo_full | pp_osaw_fifo_full | lp_mode);

  // Generate Push when -
  // - PP AW Channel is ready to accept Data
  // - PP AW Channel has Valid Data
  assign aw_fifo_push_n   = !(awready_pp & awvalid_pp);

  // Write Address Primary Port Payload - Decoded here so that the UPSIZING payload can be extracted for AHB Configs
  assign {awbar_pp, awsnoop_pp, awdomain_pp, awregion_pp, awqos_pp, aw_hburst_type_pp, awsideband_pp, awid_pp, awaddr_pp,
  awresize_pp, awlen_pp, awsize_pp, awburst_pp, awlock_pp, awcache_pp, awprot_pp} = aw_pyld_pp; 

  //*************************************************************************************
  // SP AW Channel Active - For Software Use
  //*************************************************************************************
  assign aw_sp_active = sp_add_active | (!aw_fifo_empty) | (wbuf_mode & (!snf_fifo_empty)); 

  //*************************************************************************************
  //                            AW FIFO
  // - Store the AW Payload pushed in from the AW PP Channel                           
  //*************************************************************************************
  i_axi_a2x_1_DW_axi_a2x_fifo
   #(
    .DUAL_CLK                               (A2X_CLK_MODE)
    ,.PUSH_SYNC_DEPTH                        (A2X_PP_SYNC_DEPTH)
    ,.POP_SYNC_DEPTH                         (A2X_SP_SYNC_DEPTH)
    ,.DATA_W                                 (A2X_AW_PYLD_W)
    ,.DEPTH                                  (A2X_AW_FIFO_DEPTH)
    ,.LOG2_DEPTH                             (A2X_AW_FIFO_DEPTH_LOG2)
  ) U_a2x_aw_fifo (
     .clk_push_i                             (clk_pp)
    ,.resetn_push_i                          (resetn_pp)
    ,.push_req_n_i                           (aw_fifo_push_n)
    ,.data_i                                 (aw_pyld_pp)
    ,.push_full_o                            (aw_fifo_full)
    ,.push_empty_o                           (aw_push_empty)
    ,.clk_pop_i                              (clk_sp)
    ,.resetn_pop_i                           (resetn_sp)
    ,.pop_req_n_i                            (aw_fifo_pop_n)
    ,.pop_empty_o                            (aw_fifo_empty)
    ,.data_o                                 (aw_pyld_fifo_o)    
    ,.push_count                             (aw_fifo_push_count)
    ,.pop_count                              (aw_fifo_pop_count)
    ,.push_rst_n                             (pp_rst_n)
    ,.pop_rst_n                              (sp_rst_n)
  );
  
  // All AW FIFOs Empty
  // - In SNF Mode indicates if both the SNF and AW FIFO is empty
  //    Otherwise only ther AW FIFO is considered.
  assign aw_fifos_pop_empty  =   (wbuf_mode==`SNF_MODE)? (aw_fifo_empty | snf_fifo_empty) : aw_fifo_empty;

  // Only Pop Data from AW FIFO when 
  // - SP AW Channel Ready 
  // - SNF FIFO is not Empty and
  // - AW FIFO is not Empty and
  // - Burst Response FIFO not Full and
  // - SP Write control FIFO not Full and
  // - SP Address Generator is inactive i.e. It is not is process of breaking
  //   down a previous PP Address
  assign aw_fifo_pop    = awready_sp & trans_en & ((!sp_add_active) & (!(aw_fifos_pop_empty | sp_osaw_fifo_full_w)) & b_osw_fifo_valid);
  assign aw_fifo_pop_n  = !aw_fifo_pop;

  //*************************************************************************************
  //                                 SNF FIFO
  // 
  // FIFO only exists when A2X is set to Store-forward. This FIFO does not
  // exists when the A2X is Hardcoded for Cut-Through (CT) 
  //*************************************************************************************
    generate
    if (BYPASS_SNF_W==1) begin: SNF_FIFO
      assign snf_fifo_push_n_w =  1'b1;
      assign snf_fifo_pop_n_w  =  1'b1;
      assign snf_fifo_full     =  1'b0;
      assign snf_fifo_empty    =  1'b0;
      assign snf_push_empty    =  1'b1;
      assign snf_pyld_fifo_o   =  {(A2X_WSNF_PYLD_W){1'b0}}; 
    end else begin: SNF_FIFO_1
      
      assign snf_fifo_push_n_w =  (wbuf_mode==`SNF_MODE)? snf_fifo_push_n      : 1'b1;
      assign snf_fifo_pop_n_w  =  (wbuf_mode==`SNF_MODE)? snf_fifo_pop_n       : 1'b1;
      assign snf_fifo_full     =  (wbuf_mode==`SNF_MODE)? snf_fifo_full_w      : 1'b0;
      assign snf_fifo_empty    =  (wbuf_mode==`SNF_MODE)? snf_fifo_empty_w     : 1'b0;
      assign snf_push_empty    =  (wbuf_mode==`SNF_MODE)? snf_push_empty_w     : 1'b1;
      
      i_axi_a2x_1_DW_axi_a2x_fifo
       #(
        .DUAL_CLK                               (A2X_CLK_MODE)
        ,.PUSH_SYNC_DEPTH                        (A2X_PP_SYNC_DEPTH)
        ,.POP_SYNC_DEPTH                         (A2X_SP_SYNC_DEPTH)
        ,.DATA_W                                 (A2X_WSNF_PYLD_W)
        ,.DEPTH                                  (A2X_SNF_FIFO_DEPTH)
        ,.LOG2_DEPTH                             (A2X_SNF_FIFO_DEPTH_LOG2)
      ) U_a2x_aw_snf_fifo (
         .clk_push_i                             (clk_pp)
        ,.resetn_push_i                          (resetn_pp)
        ,.push_req_n_i                           (snf_fifo_push_n_w)
        ,.data_i                                 (snf_pyld_pp)
        ,.push_full_o                            (snf_fifo_full_w)
        ,.push_empty_o                           (snf_push_empty_w)
        ,.clk_pop_i                              (clk_sp)
        ,.resetn_pop_i                           (resetn_sp)
        ,.pop_req_n_i                            (snf_fifo_pop_n_w)
        ,.pop_empty_o                            (snf_fifo_empty_w)
        ,.data_o                                 (snf_pyld_fifo_o)    
        ,.push_count                             (snf_fifo_push_count)
        ,.pop_count                              (snf_fifo_pop_count)
        ,.push_rst_n                             (pp_rst_n)
        ,.pop_rst_n                              (sp_rst_n)
      );
      
      // Store-Forward FIFO Pop
      // - When address accepted on SP & burst length is equal to snf length or PP wlast is seen in the SNF FIFO
      // - For INCR & FIXED transactions we only require the SP address to be accepted on SP to generate a SNF FIFO pop
      wire snf_fifo_pop;
      //assign snf_fifo_pop    = awvalid_sp & awready_sp & w_snf_pop_en & (~snf_pyld_fifo_o[0] | (snf_pyld_fifo_o[0] & awlast_sp));
      assign snf_fifo_pop    = awvalid_sp & awready_sp & w_snf_pop_en;

      assign snf_fifo_pop_n  = ~snf_fifo_pop;



    end // if (BYPASS_SNF_W==1) begin
    endgenerate

  //*************************************************************************************
  // Secondary Port Address Generation
  // - Converts Wrap Transactions in INCR's for Upsizing/Downsizing and SNF Configs.
  // - Generates Resized Length, Size and Burst Type for Upsizing/Downsizing Configs.
  // - Generates Sp Address from SNF & resizing information
  //*************************************************************************************
  i_axi_a2x_1_DW_axi_a2x_sp_add
   #(    
     .A2X_CHANNEL                            (0)            
    ,.A2X_PP_MODE                            (A2X_PP_MODE)
    ,.A2X_LOCKED                             (A2X_LOCKED) 
    ,.BOUNDARY_W                             (BOUNDARY_W)
    ,.A2X_AW                                 (A2X_AW) 
    ,.A2X_BLW                                (A2X_BLW) 
    ,.A2X_HINCR_HCBCNT                       (A2X_HINCR_HCBCNT)
    ,.A2X_HINCR_MAX_BCNT                     (A2X_HINCR_MAX_WBCNT)
    ,.A2X_AHB_BLW                            (A2X_AHB_WBLW)
    ,.A2X_ASBW                               (A2X_AWSBW)
    ,.A2X_QOSW                               (A2X_QOSW)
    ,.A2X_REGIONW                            (A2X_REGIONW)
    ,.A2X_DOMAINW                            (A2X_DOMAINW)
    ,.A2X_WSNOOPW                            (A2X_WSNOOPW)
    ,.A2X_BARW                               (A2X_BARW)
    ,.A2X_PP_DW                              (A2X_PP_DW) 
    ,.A2X_SP_DW                              (A2X_SP_DW) 
    ,.A2X_SP_MAX_SIZE                        (A2X_SP_MAX_SIZE) 
    ,.A2X_PP_MAX_SIZE                        (A2X_PP_MAX_SIZE) 
    ,.A2X_RS_RATIO_LOG2                      (A2X_RS_RATIO_LOG2) 
    ,.A2X_SP_NUM_BYTES_LOG2                  (A2X_SP_NUM_BYTES_LOG2) 
    ,.A2X_PP_NUM_BYTES_LOG2                  (A2X_PP_NUM_BYTES_LOG2) 
    ,.BYPASS_AC                              (BYPASS_AW_AC)
    ,.BYPASS_WS                              (BYPASS_AW_WS)
    ,.A2X_BRESP_MODE                         (A2X_BRESP_MODE)
    ,.A2X_WSNF_PYLD_W                        (A2X_WSNF_PYLD_W)
  ) U_aw_add ( 
    // Outputs
     .a_pyld_o                               (aw_pyld_sp)    
    ,.a_active                               (sp_add_active)
    ,.alen_sp                                (awlen_sp)
    ,.alast_sp                               (awlast_sp)
    ,.onek_exceed                            (onek_exceed)   
    ,.ws_addr                                (ws_addr)
    ,.ws_alen                                (ws_alen)
    ,.ws_size                                (ws_size)
    ,.ws_resize                              (ws_resize)
    ,.ws_fixed                               (ws_fixed)
    ,.ws_last                                (ws_last)
    ,.w_snf_pop_en                           (w_snf_pop_en)
    ,.lock_req_o                             (lock_req_o)
    ,.unlock_req_o                           (unlock_req_o)
    ,.os_unlock                              (os_unlock)
    
    // Inputs
    ,.clk                                    (clk_sp)
    ,.resetn                                 (resetn_sp)
    ,.buf_mode                               (wbuf_mode)
    ,.max_len                                (sp_max_len)    
    ,.lock_grant                             (lock_grant)
    ,.unlock_req_i                           (unlock_req_i)
    ,.lock_req_i                             (lock_req_i)
    ,.unlock_grant                           (unlock_grant)
    ,.lockseq_cmp                            (lockseq_cmp)
    ,.trans_en                               (trans_en)
    ,.a_pyld_i                               (aw_pyld_fifo_o)    
    ,.snf_pyld_i                             (snf_pyld_fifo_o)    
    ,.a_fifo_empty                           (aw_fifo_empty)
    ,.sp_os_fifo_valid                       (sp_osw_fifo_valid)
    ,.a_ready_i                              (awready_sp)
    ,.bypass_ws                              (bypass_aw_ws)
  );

  // Maximum SP Length 
  // - CT Mode maximum length is 2^A2X_BLW
  // - SNF Mode maximum length is 2^A2X_BLW
  assign sp_max_len = (1 << A2X_BLW);

  //*************************************************************************************
  // Oustanding Secondary Write Transaction
  // This pin asserts when there is outstanding transactions on the SP or
  // when the Address generator is breaking an existing transaction into
  // multiple transactions. 
  //*************************************************************************************
  assign osw_trans = (trans_en & sp_add_active) | b_osw_trans;

  //*************************************************************************************
  // AW SP Bufferable Transaction Type
  //*************************************************************************************
  // - BRESP_MODE 0 - Response always bufferable
  // - BRESP_MODE 1 - Response always non-bufferable
  // - BRESP_MODE 2 - Response always Dynamic
  // - Locked mode  - We want to disguard the respone type for Locking Transaction
  assign aw_nbuf_sp = (A2X_BRESP_MODE==0) ? 1'b0 : (A2X_BRESP_MODE==1) ? 1'b1 : ((A2X_PP_MODE==0) && (A2X_LOCKED==1) && unlock_grant)? 1'b0 :~aw_pyld_sp[3];

  //*************************************************************************************
  // Secondary Port has a valid address when 
  // - SP Write control FIFO is not empty
  // - B Outstand Writes FIFO is not empty
  // When the SP Address Generator is not active the status of the AW and SNF
  // FIFO must also be considered 
  // - AW FIFO has Data and
  // - SNF FIFO has data in SNF MODE
  // - If Generating a locked or unlocked transaction the trans_en is deasserted until all
  //   outstanding transactioni are returned to the A2X. 
  //*************************************************************************************
  // When asserted the A2X can generate a valid AW Address.
  assign sp_osw_fifo_valid = (!snf_fifo_empty) & (!sp_osaw_fifo_full_w) & b_osw_fifo_valid; 

  assign awvalid_sp = trans_en & ((sp_add_active & sp_osw_fifo_valid) | ((!sp_add_active) & (!aw_fifo_empty) & sp_osw_fifo_valid));  

  //*************************************************************************************
  // An AXI Slave may not respond with an awready until it knows valid data
  // is availabe. In this scenario we need to push into the SP OSAW FIFO when AW data
  // is available on the SP so that wvalid can be asserted.
  //*************************************************************************************
  generate 
  // Only required if SP OSAW FIFO Exists
  if ((A2X_PP_MODE==0) || (A2X_DOWNSIZE==1) || (A2X_UPSIZE==1) ||  (A2X_SP_ENDIAN!=0) || ((A2X_LOCKED==1) && (A2X_BRESP_MODE==0)) ) begin: bypass_SPOSAWFIFO
    always @(*) begin: spc_push_PROC
      spc_nxt_state = spc_state;
      case (spc_state)
        SPC_IDLE: begin
          // Push into SPC FIFO when Address Available
          if (awvalid_sp && (!awready_sp))
            spc_nxt_state = SPC_WAIT;
        end
        SPC_WAIT: begin
          if (awready_sp)
            spc_nxt_state = SPC_IDLE;
        end
      endcase
    end
    
    always @(posedge clk_sp or negedge resetn_sp) begin: spc_state_PROC
      if (resetn_sp==1'b0) 
        spc_state <= SPC_IDLE;
      else begin
        spc_state <= spc_nxt_state;
      end
    end
    
    // State Change
    assign spc_stchange = (spc_state!=spc_nxt_state);
    
    // If the AW channel has not accepted the AW Address but a push has already
    // been generated to the SPC FIFO. Then we do not want to consider the SPC
    // FIFO status for generating awvalid. 
    assign sp_osaw_fifo_full_w = (spc_state==SPC_IDLE)? sp_osaw_fifo_full : 1'b0; 

    // Write Channel SP Control FIFO 
    // - Push when AW Address accepted.
    assign sp_osaw_fifo_push_n = (spc_stchange && (spc_state==SPC_IDLE))? 1'b0 : (spc_state==SPC_WAIT)? 1'b1 : !(awvalid_sp & awready_sp);

    // FIFO Width scaled based on configuration as resize information is not
    // required for downsized configs. 
    assign sp_osaw_pyld    = {ws_resize, ws_fixed, ws_size, ws_addr[PP_NUM_BYTES_LOG2-1:0], ws_last, awlast_sp, awlen_sp};
  end else begin
    assign sp_osaw_fifo_full_w = 1'b0; 
    assign sp_osaw_fifo_push_n = 1'b1;
    assign sp_osaw_pyld        = 0; 
  end
  endgenerate

endmodule
//Revision: $Id: //dwh/DW_ocb/DW_axi_a2x/amba_dev/src/DW_axi_a2x_aw.v#90 $
