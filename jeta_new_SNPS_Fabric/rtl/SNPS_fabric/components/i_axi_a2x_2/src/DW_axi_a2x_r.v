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
// File Version     :        $Revision: #22 $ 
// Revision: $Id: //dwh/DW_ocb/DW_axi_a2x/axi_dev_br/src/DW_axi_a2x_r.v#22 $ 
**
** --------------------------------------------------------------------
**
** File     : DW_axi_a2x_r.v
** Created  : Thu Jan 27 11:01:40 MET 2011
** Abstract :
**-----------------------------------------------------------------------------------------------------------------
**                  Read Data Channel Architecture Diagram
**-----------------------------------------------------------------------------------------------------------------
**                                                                   |
**                                                              AR Channel
**                                                                   |
**                                                                   |
**                                             |----------------------------------------------------|
**                                             |                     |                              |
**                                         |-----------------------------------------------------|  |
**                                         |       URID              |                           |  |
**                                         |  Unique Read ID         V                           |  |
**                                         |                    |----------|                     |  |
**                                         |                    | Resize   |                     |  |
**                                         |                    |  FIFO    |                     |  |
**                                         |                    |----------|                     |  |
**                                         |                         |                           |  |
**                                         |         |---------------|-----------------|         |  |
**               |------|        |-----|   |         |               |                 |         |  |
**               | Pop  |        |Push |   |         |               |                 |         |  |
**               |------|        |-----|   |         |               |                 |         |  |
**                   |              |      |         V               V                 V         |  | 
**      |---------|  |>|--------|   |      |   |-----------|     |---------|      |---------|    |  | 
**      |  Data   |    |  Data  |<---      |   |   Data    |     |  Data   |      |  Read   | Read Data Channel
** <----| Unpacker|<---|  FIFO  |<---------|<--| Unpacker  |<----| Packer  |<-----| Control |<------------
**      |         |    |        |          |   |  Decode   |     |         |      |         |    |  |
**      |---------|    |--------|          |   |-----------|     |---------|      |---------|    |--|
**                                         |                                                     |
**                                         |------------------------------------------------------
**
** This diagram shows the Read Data Path architecture of the A2X. Depending on the configuration upsizing ,downsizing or Non-Resized
** some of the blocks are unused in the design and may be removed from the RTL. 
**
** The following blocks are conditional based on the configuration selected. 
** - Data Unpacker        - For Upsizing Configs 
** - Data Unpacker Decode - For Upsizing Configs 
** - Data Packer          - For Downsizing Configs 
**
** To optimize performance on the Read Data Path the read data FIFO width is always set to the larger of the Primary Port v's 
** Secondary Port Data Buses.
** 
** Since the Read Data can be returned interlaved or in a different order from the transactions issued on the AR Channel, the 
** architecture offers a Unique Read ID block. This block contains the resize and store-forward information for each outstanding 
** Unique Read ID. The number of Unique RID's that the A2X can support will affect the number of outstanding Unigue ARID's that 
** the A2X send on the AR Channel. 
**
** If a system is guaranteed to always return the read data in the same order as the transactions issued on the AR Channel and if 
** that system does not return data interleaved. The A2X can be configured such that the number of outstanding URID's are not a 
** factor when issuing transaction on the SP AR Channel. In this case the number of unique RID blocks is reduced to one but the RID 
** is not factored into and the  equation when analysing the read data.
**
** Upsizing Configs 
**   The Data Unpacker is implemented in two parts the first part generates a Decode Mask Bit that is Tagged with 
**   the read Data and pushed into the read data FIFO. The Second part usaes this Mask bit to unpack the Data. 
**   The implemented in designed this way so that the Primary Port has no dependancies the number of URID's it can accept.
**
** AHB Locked Support
**   When the A2X is configured for AHB Mode with locked support an additional read data Locked FIFO is added to the Architecture. This FIFO
**   sits in parallel with the read dta FIFO and is used to return the read data for an AHB Locked Transaction. In locked mode the depth of the 
**   read data FIFO is configured such that the FIFO can always accept and store any outstanding SP AXI read Data transaction. When the locked 
**   transaction has completed this read data is returned to the AHB. 
** ----------------------------------------------------------------------------------------------------------------------------------------------
*/
`include "DW_axi_a2x_all_includes.vh"

module i_axi_a2x_2_DW_axi_a2x_r (/*AUTOARG*/
   // Outputs
   rvalid_pp, r_pyld_pp, rvalid_pp_lk, r_pyld_pp_lk, rready_sp, r_uid_fifo_valid,
   r_osr_fifo_empty, r_fifo_len,
   // Inputs
   clk_pp, resetn_pp, clk_sp, resetn_sp, 
   siu_rbuf_mode, 
   bypass_urid_fifo,
   arready_sp, arvalid_sp, arid_sp, rready_pp, 
   rready_pp_lk, 
   rvalid_sp, r_pyld_sp, 
   arlen_sp, 
   arlast_sp, sp_osar_pyld,  
   sp_locked, 
   osr_cnt_incr, 
   flush 
   );

  //*************************************************************************************
  // Parameter Decelaration
  //*************************************************************************************
  parameter  A2X_PP_MODE                 = 0; 
  parameter  A2X_UPSIZE                  = 0; 
  parameter  A2X_DOWNSIZE                = 0; 
  parameter  A2X_BLW                     = 4;
  parameter  A2X_AHB_RBLW                = 4;
  parameter  A2X_RSBW                    = 1;  

  parameter  A2X_LOCKED                  = 0; 
  parameter  A2X_AHB_LK_RD_FIFO          = 0; 

  parameter  A2X_READ_ORDER              = 1;
  parameter  A2X_NUM_URID                = 1; 

  parameter  A2X_RS_RATIO                = 1; 

  parameter  A2X_PP_DW                   = 32;
  parameter  A2X_PP_MAX_SIZE             = 2;  
  parameter  A2X_PP_NUM_BYTES            = 4;
  parameter  A2X_PP_NUM_BYTES_LOG2       = 1;

  parameter  A2X_SP_DW                   = 32;
  parameter  A2X_SP_MAX_SIZE             = 2;  
  parameter  A2X_SP_NUM_BYTES            = 4;
  parameter  A2X_SP_NUM_BYTES_LOG2       = 1;

  parameter  A2X_CLK_MODE                = 0;

  parameter  A2X_OSR_LIMIT               = 4;
  parameter  A2X_OSR_LIMIT_LOG2          = 2;

  parameter  A2X_RD_FIFO_DEPTH           = 4;
  parameter  A2X_RD_FIFO_DEPTH_LOG2      = 2;

  parameter  A2X_LK_RD_FIFO_DEPTH        = 4;
  parameter  A2X_LK_RD_FIFO_DEPTH_LOG2   = 2;
  
  parameter  A2X_PP_PYLD_W               = 32;
  parameter  A2X_SP_PYLD_W               = 32;

  parameter  BYPASS_URID_FIFO            = 1; 
  parameter  BYPASS_SNF_R                = 1; 
   
  parameter  A2X_PP_ENDIAN               = 0; 
  parameter  A2X_SP_ENDIAN               = 0; 

  // Primary Port Length 
  localparam BLW_PP                      = (A2X_PP_MODE==1) ? A2X_BLW : A2X_AHB_RBLW;

  // Resize FIFO AR Payload - Address Bits taken for the larger of the Data Busses
  localparam A2X_RDS_PYLD_W              = `i_axi_a2x_2_A2X_RSW + 1 + `i_axi_a2x_2_A2X_BSW + A2X_PP_NUM_BYTES_LOG2 + 1;

  localparam A2X_RUS_PYLD_W              = `i_axi_a2x_2_A2X_RSW + 1 + BLW_PP + `i_axi_a2x_2_A2X_BSW + A2X_SP_NUM_BYTES_LOG2 + 1;

  localparam A2X_SP_OSAR_PYLD_W          = (A2X_DOWNSIZE==1)? A2X_RDS_PYLD_W : (A2X_UPSIZE==1)? A2X_RUS_PYLD_W : `i_axi_a2x_2_A2X_BSW; 
  
  localparam A2X_R_FIFO_PYLD_W           = (A2X_UPSIZE==1)? (A2X_SP_PYLD_W + A2X_RS_RATIO) : (A2X_DOWNSIZE==1)? A2X_PP_PYLD_W : A2X_SP_PYLD_W;
  localparam A2X_RD_FIFO_DEPTH_LOG2_P1   = A2X_RD_FIFO_DEPTH_LOG2+1;
  localparam A2X_LKRD_FIFO_DEPTH_LOG2_P1 = A2X_LK_RD_FIFO_DEPTH_LOG2+1;

  //*************************************************************************************
  // I/O Decelaration
  //*************************************************************************************
  input                                       clk_pp;
  input                                       resetn_pp;

  input                                       clk_sp;
  input                                       resetn_sp;

  //spyglass disable_block W240
  //SMD: An input has been declared but is not read.
  //SJ: This signal is used in specific config only 
  input                                       bypass_urid_fifo;
  //Input siu_rbuf_mode is read only when BYPASS_SNF_R = 0. 
  input                                       siu_rbuf_mode;      // Read Buffer Mode
  //spyglass enable_block W240
  output [31:0]                               r_fifo_len;         // Number of Free Spaces in Read Data FIFO

  //spyglass disable_block W240
  //SMD: An input has been declared but is not read.
  //SJ: This signal is used in specific config only 
  input                                       arready_sp;         // SP AR Channel
  input                                       arvalid_sp;
  input  [`i_axi_a2x_2_A2X_IDW-1:0]                       arid_sp;
  //Input arlen_sp is read only when BYPASS_SNF_R = 0.
  input [A2X_BLW-1:0]                         arlen_sp;           // SP AR Length
  input                                       arlast_sp;          // Last SP Transaction from PP Transaction. 

  input                                       rready_pp;          // PP R Channel
  //spyglass enable_block W240
  output                                      rvalid_pp;
  output  [A2X_PP_PYLD_W-1:0]                 r_pyld_pp;
  //spyglass disable_block W240
  //SMD: An input has been declared but is not read.
  //SJ : Input rready_pp_lk is read only when A2X_AHB_LK_RD_FIFO = 1. 
  input                                       rready_pp_lk;          // PP R Channel
  //spyglass enable_block W240
  output                                      rvalid_pp_lk;
  output  [A2X_PP_PYLD_W-1:0]                 r_pyld_pp_lk;

  output                                      rready_sp;          // SP R Channel
  //spyglass disable_block W240
  //SMD: An input has been declared but is not read.
  //SJ : This signal is used in specific config only 
  input                                       rvalid_sp;
  input [A2X_SP_PYLD_W-1:0]                   r_pyld_sp;
  //spyglass enable_block W240

  output                                      r_uid_fifo_valid;
  output                                      r_osr_fifo_empty;

  //spyglass disable_block W240
  //SMD: An input has been declared but is not read.
  //SJ : This signal is used in specific config only 
  input [A2X_SP_OSAR_PYLD_W-1:0]              sp_osar_pyld;       // Resize FIFO Payload
  input                                       sp_locked;          // SP Channel Locked
  input                                       osr_cnt_incr;       // Incremtn Outstanding Read Counter
  input                                       flush;
  //spyglass enable_block W240

  //*************************************************************************************
  // Signal Decelaration
  //*************************************************************************************
  wire                                             r_fifo_push_n;                // Read Data FIFO
  wire                                             r_fifo_full; 
  wire                                             r_fifo_pop_n; 
  reg    [A2X_R_FIFO_PYLD_W-1:0]                   r_pyld_fifo_i; 
  wire   [A2X_R_FIFO_PYLD_W-1:0]                   r_pyld_fifo_i_w; 
  wire   [A2X_R_FIFO_PYLD_W-1:0]                   r_pyld_fifo_o;
  wire   [31:0]                                    r_fifo_push_count;
  wire   [31:0]                                    r_fifo_pop_count;

  wire                                             r_fifo_push_n_w; 
  wire                                             r_fifo_full_w; 
  wire                                             r_fifo_pop_n_w; 
  wire                                             r_fifo_empty_w; 
  wire   [A2X_R_FIFO_PYLD_W-1:0]                   r_pyld_fifo_o_w; 
  wire   [A2X_RD_FIFO_DEPTH_LOG2_P1-1:0]           r_fifo_push_count_w;
  wire   [A2X_RD_FIFO_DEPTH_LOG2_P1-1:0]           r_fifo_pop_count_w;

  wire   [A2X_NUM_URID-1:0]                        uid_r_fifo_push_n;          // Unique RID 
  wire   [A2X_NUM_URID-1:0]                        uid_fifo_empty;
  wire   [A2X_NUM_URID-1:0]                        uid_fifo_full;
  wire   [A2X_NUM_URID-1:0]                        uid_wr_en;
  wire   [(A2X_R_FIFO_PYLD_W*A2X_NUM_URID)-1:0]    uid_r_pyld;

  wire                                             r_uid_fifo_full;
  wire                                             r_uid_fifo_empty;
  
  wire                                             unconn_1;
  wire                                             unconn_2;

  //*************************************************************************************
  // Read Data Unpacker 
  //
  // - Unpackes the Read Data from the Read Data FIFO. 
  //*************************************************************************************
  generate
    if (A2X_UPSIZE==1) begin: RUPSIZE
      i_axi_a2x_2_DW_axi_a2x_r_upk
       #(
         .A2X_R_FIFO_PYLD_W                (A2X_R_FIFO_PYLD_W)
        ,.A2X_PP_PYLD_W                    (A2X_PP_PYLD_W)
        
        ,.A2X_RSBW                         (A2X_RSBW)
        ,.A2X_SP_DW                        (A2X_SP_DW)
        ,.A2X_PP_DW                        (A2X_PP_DW)
        ,.A2X_RS_RATIO                     (A2X_RS_RATIO)
      ) U_a2x_r_upk (
        // Outputs
         .r_pyld_o                         (r_pyld_pp)
        ,.r_fifo_pop_n                     (r_fifo_pop_n)
        // Inputs
        ,.clk                              (clk_pp)
        ,.resetn                           (resetn_pp) 
        ,.rready_i                         (rready_pp)
        ,.rvalid_i                         (rvalid_pp)
        ,.flush                            (flush)
        ,.r_fifo_empty                     (r_fifo_empty_w)
        ,.r_pyld_i                         (r_pyld_fifo_o)
      );
    end else begin
      assign r_pyld_pp     = r_pyld_fifo_o;
      assign r_fifo_pop_n  = !(rready_pp & rvalid_pp);
    end
  endgenerate

  //*************************************************************************************
  //                     Read Data FIFO
  //*************************************************************************************
  i_axi_a2x_2_DW_axi_a2x_fifo
   #(
     .DUAL_CLK                               (A2X_CLK_MODE)
    ,.PUSH_SYNC_DEPTH                        (`i_axi_a2x_2_A2X_SP_SYNC_DEPTH)
    ,.POP_SYNC_DEPTH                         (`i_axi_a2x_2_A2X_PP_SYNC_DEPTH)
    ,.DATA_W                                 (A2X_R_FIFO_PYLD_W)
    ,.DEPTH                                  (A2X_RD_FIFO_DEPTH)
    ,.LOG2_DEPTH                             (A2X_RD_FIFO_DEPTH_LOG2)
  ) U_a2x_rd_fifo (
     .clk_push_i                             (clk_sp)
    ,.resetn_push_i                          (resetn_sp)
    ,.push_req_n_i                           (r_fifo_push_n_w)
    ,.data_i                                 (r_pyld_fifo_i_w)
    ,.push_full_o                            (r_fifo_full_w)
    ,.push_empty_o                           (unconn_1)
    ,.clk_pop_i                              (clk_pp)
    ,.resetn_pop_i                           (resetn_pp)
    ,.pop_req_n_i                            (r_fifo_pop_n_w)
    ,.pop_empty_o                            (r_fifo_empty_w)
    ,.data_o                                 (r_pyld_fifo_o_w)    
    ,.push_count                             (r_fifo_push_count_w)
    ,.pop_count                              (r_fifo_pop_count_w)
  );  

  //*************************************************************************************
  // Locked Response Control FIFO (AHB Mode Only) 
  //*************************************************************************************
  generate
    if (A2X_AHB_LK_RD_FIFO==1) begin: LK_RD_FIFO
      wire                                             rlk_fifo_pop_n; 

      wire                                             r_fifo_lk_push_n;            // Read Data locked FIFO
      wire                                             r_fifo_lk_full; 
      wire                                             r_fifo_lk_pop_n; 
      wire                                             r_fifo_lk_empty; 
      wire   [A2X_R_FIFO_PYLD_W-1:0]                   r_pyld_lk_fifo_o; 
      wire   [A2X_LKRD_FIFO_DEPTH_LOG2_P1-1:0]         r_fifo_lk_push_count;
      wire   [A2X_LKRD_FIFO_DEPTH_LOG2_P1-1:0]         r_fifo_lk_pop_count;

      //*************************************************************************************
      // Locked Configs - Unpacking Read Data
      //*************************************************************************************
      if (A2X_UPSIZE==1) begin: RUPSIZE_LK
        i_axi_a2x_2_DW_axi_a2x_r_upk
         #(
           .A2X_R_FIFO_PYLD_W                (A2X_R_FIFO_PYLD_W)
          ,.A2X_PP_PYLD_W                    (A2X_PP_PYLD_W)
          
          ,.A2X_RSBW                         (A2X_RSBW)
          ,.A2X_SP_DW                        (A2X_SP_DW)
          ,.A2X_PP_DW                        (A2X_PP_DW)
          ,.A2X_RS_RATIO                     (A2X_RS_RATIO)
        ) U_a2x_rlk_upk (
          // Outputs
           .r_pyld_o                         (r_pyld_pp_lk)
          ,.r_fifo_pop_n                     (r_fifo_lk_pop_n)
          // Inputs
          ,.clk                              (clk_pp)
          ,.resetn                           (resetn_pp) 
          ,.rready_i                         (rready_pp_lk)
          ,.rvalid_i                         (rvalid_pp_lk)
          ,.flush                            (1'b0)
          ,.r_fifo_empty                     (r_fifo_lk_empty)
          ,.r_pyld_i                         (r_pyld_lk_fifo_o)
        );


        assign rvalid_pp_lk       = !r_fifo_lk_empty;
      end else begin
        assign rvalid_pp_lk       = !r_fifo_lk_empty;
        assign r_pyld_pp_lk       = r_pyld_lk_fifo_o;
        assign r_fifo_lk_pop_n    = !(rready_pp_lk & rvalid_pp_lk);
      end

      //*************************************************************************************
      // Locked Configs - Read Data FIFO
      //*************************************************************************************
      i_axi_a2x_2_DW_axi_a2x_fifo
       #(
         .DUAL_CLK                               (A2X_CLK_MODE)
        ,.PUSH_SYNC_DEPTH                        (`i_axi_a2x_2_A2X_SP_SYNC_DEPTH)
        ,.POP_SYNC_DEPTH                         (`i_axi_a2x_2_A2X_PP_SYNC_DEPTH)
        ,.DATA_W                                 (A2X_R_FIFO_PYLD_W)
        ,.DEPTH                                  (A2X_LK_RD_FIFO_DEPTH)
        ,.LOG2_DEPTH                             (A2X_LK_RD_FIFO_DEPTH_LOG2)
      ) U_a2x_rd_lk_fifo (
         .clk_push_i                             (clk_sp)
        ,.resetn_push_i                          (resetn_sp)
        ,.push_req_n_i                           (r_fifo_lk_push_n)
        ,.data_i                                 (r_pyld_fifo_i_w)
        ,.push_full_o                            (r_fifo_lk_full)
        ,.push_empty_o                           (unconn_2)
        ,.clk_pop_i                              (clk_pp)
        ,.resetn_pop_i                           (resetn_pp)
        ,.pop_req_n_i                            (r_fifo_lk_pop_n)
        ,.pop_empty_o                            (r_fifo_lk_empty)
        ,.data_o                                 (r_pyld_lk_fifo_o)    
        ,.push_count                             (r_fifo_lk_push_count)
        ,.pop_count                              (r_fifo_lk_pop_count)
      );  

      // Select Control from the Read Data locked FIFO when the A2X enters locked
      // Mode. 
      assign rvalid_pp          = !r_fifo_empty_w;    
      assign r_fifo_pop_n_w     = r_fifo_pop_n;
      assign r_pyld_fifo_o      = r_pyld_fifo_o_w;
    
      assign r_fifo_full        = (sp_locked)? r_fifo_lk_full  : r_fifo_full_w;
      // spyglass disable_block W164a
      // SMD: Identifies assignments in which the LHS width is less than the RHS width
      // SJ : The length of the operand r_fifo_lk_push_count/r_fifo_push_count_w varies based on the configuration. But this logic requires
      //      only the lower A2X_RD_FIFO_DEPTH_LOG2_P1 bits. This is not a functional issue, this is as per the requirement.
      //      Hence this can be waived.  
      // spyglass disable_block W164b
      // SMD: Identifies assignments in which the LHS width is greater than the RHS width
      // SJ : The length of the operand r_fifo_lk_push_count/r_fifo_push_count_w varies based on the configuration. 
      //      This is not a functional issue, this is as per the requirement. Hence this can be waived.  
      assign r_fifo_push_count  = (sp_locked)? r_fifo_lk_push_count : r_fifo_push_count_w;
      // spyglass enable_block W164b
      // spyglass enable_block W164a

      assign r_fifo_lk_push_n   = (sp_locked)? r_fifo_push_n : 1'b1; 
      assign r_fifo_push_n_w    = (sp_locked)? 1'b1          : r_fifo_push_n;

    end else begin // if (A2X_AHB_LK_RD_FIFO==1) begin
      
      // Signal Assignment 
      assign rvalid_pp          = !r_fifo_empty_w;
      assign r_pyld_fifo_o      = r_pyld_fifo_o_w;
    
      assign r_fifo_pop_n_w     = r_fifo_pop_n;
      assign r_fifo_push_n_w    = r_fifo_push_n;
      assign r_fifo_full        = r_fifo_full_w;
    
      assign r_fifo_push_count[31:A2X_RD_FIFO_DEPTH_LOG2_P1]  = {(32-A2X_RD_FIFO_DEPTH_LOG2_P1){1'b0}};
      assign r_fifo_push_count[A2X_RD_FIFO_DEPTH_LOG2_P1-1:0] = r_fifo_push_count_w;

      assign r_fifo_pop_count[31:A2X_RD_FIFO_DEPTH_LOG2_P1]   = {(32-A2X_RD_FIFO_DEPTH_LOG2_P1){1'b0}};
      assign r_fifo_pop_count[A2X_RD_FIFO_DEPTH_LOG2_P1-1:0]  = r_fifo_pop_count_w;
      
      assign rvalid_pp_lk       = 1'b0;
      assign r_pyld_pp_lk       = {A2X_PP_PYLD_W{1'b0}};
    end
  endgenerate
  
  //*************************************************************************************
  // Store & Forward Control
  //*************************************************************************************
  // spyglass disable_block W484
  // SMD: Possible loss of carry or borrow due to addition or subtraction
  // SJ: The length of the net varies based on configuration. This will not cause functional issue.
  generate
    if (BYPASS_SNF_R==1) begin: SNF_BYPASS 
      assign r_fifo_len   = {32'b0};
    end else begin: SNF
      reg    [A2X_RD_FIFO_DEPTH_LOG2_P1-1:0]           osr_rd_sp;
      wire   [A2X_RD_FIFO_DEPTH_LOG2_P1-1:0]           r_fifo_occ;
      reg    [31:0]                                    r_fifo_len_r;     // Number of Free Spaces in Read Data FIFO
      wire   [31:0]                                    r_fifo_depth;     // Number of Free Spaces in Read Data FIFO
  
      
      //*************************************************************************************
      // Number of Outstanding Read Data Transactions. 
      //
      // The maximum number of Outstanding Read Data Transactions the A2X can support is defined 
      // by the Depth of the Read Data FIFO. This counter determines the number of expected read 
      // data transactions to receive on the R Channel. 
      //
      // The counter is priorty encoded as follows
      //  1 . When an AR Transaction is sent on the SP and a R Transaction is accepted on the SP counter
      //      is incremented by SP AR Channel Length minus 1. 
      //  2.  When an AR Transaction is sent on the SP counter increments by the SP AR Channel Length.
      //  3.  When a R Transaction is accepted on the SP counter decrements by 1. 
      //*************************************************************************************
      // spyglass disable_block TA_09
      // SMD: Reports cause of uncontrollability or unobservability and estimates the number of nets whose controllability/ observability is impacted
      // SJ : The length of the operand varies based on configuration. This will not cause functional issue.
      // spyglass disable_block W164a
      // SMD: Identifies assignments in which the LHS width is less than the RHS width
      // SJ : This is not a functional issue, this is as per the requirement.                  
      if (A2X_DOWNSIZE==0) begin:OSR
        always @(posedge clk_sp or negedge resetn_sp) begin: osr_data_PROC
          if (resetn_sp == 1'b0) begin
            osr_rd_sp <= {A2X_RD_FIFO_DEPTH_LOG2_P1{1'b0}};
          end else begin
            if (siu_rbuf_mode) begin 
              if (osr_cnt_incr && (!r_fifo_push_n_w))
                osr_rd_sp <= osr_rd_sp + arlen_sp;
              else if (osr_cnt_incr)
                osr_rd_sp <= osr_rd_sp + arlen_sp     + 1;
              else if (!r_fifo_push_n_w) 
                osr_rd_sp <= osr_rd_sp -1; 
            end else begin
              osr_rd_sp <= {A2X_RD_FIFO_DEPTH_LOG2_P1{1'b0}};
            end
          end
        end

      end else begin // IF Downsizing Config
        // Using the secondary port rvalid_sp && rready_sp instead of the
        // FIFO push as the read data is packed into multiple bytes before
        // a fifo push is generated. Hence this makes the assumption that all
        // outstanding read transaction are subsized transactions. 
        always @(posedge clk_sp or negedge resetn_sp) begin: osr_data_PROC
          if (resetn_sp == 1'b0) begin
            osr_rd_sp <= {A2X_RD_FIFO_DEPTH_LOG2_P1{1'b0}};
          end else begin
            if (siu_rbuf_mode) begin 
              if (osr_cnt_incr && (rvalid_sp && rready_sp))
                osr_rd_sp <= osr_rd_sp + arlen_sp;
              else if (osr_cnt_incr)
                osr_rd_sp <= osr_rd_sp + arlen_sp     + 1;
              else if (rvalid_sp && rready_sp) 
                osr_rd_sp <= osr_rd_sp -1; 
            end else begin
              osr_rd_sp <= {A2X_RD_FIFO_DEPTH_LOG2_P1{1'b0}};
            end
          end
        end
      end    
      // spyglass enable_block W164a
      // spyglass enable_block TA_09
            
      // Determines the Number of occupied spaces in the Read Data FIFO. This is
      // based on the number of spaces already taken up and the number of spaces
      // the outstanding reads will take up.       
      assign r_fifo_occ = r_fifo_push_count[A2X_RD_FIFO_DEPTH_LOG2_P1-1:0];

      //*************************************************************************************
      // Read Data FIFO SNF Control
      // 
      // Determines the number of Free spaces available in the Read Data FIFO. 
      // Number of Free FIFO Spaces equals 
      // Maximum Depth of Read Data FIFO minus (Number of Outstanding Read Data Transactions + Number of occupied Spaces in Read Data FIFO)
      // 
      // The (Number of Outstanding Read Data Transactions + Number of occupied Spaces in Read Data FIFO)
      // should never be greater than the Read Data FIFO Depth.
      //*************************************************************************************
      //assign r_fifo_depth = (A2X_DOWNSIZE==1)? (A2X_RD_FIFO_DEPTH*A2X_RS_RATIO) : A2X_RD_FIFO_DEPTH;
      assign r_fifo_depth = A2X_RD_FIFO_DEPTH;
      // spyglass disable_block W164a
      // SMD: Identifies assignments in which the LHS width is less than the RHS width
      // SJ : This is not a functional issue, this is as per the requirement.                  
      always @(*) begin: maxlen_PROC
        r_fifo_len_r =  r_fifo_depth - (osr_rd_sp + r_fifo_occ);
      end
      // spyglass enable_block W164a
      assign r_fifo_len = r_fifo_len_r;

    end // if (BYPASS_SNF_R==1) begin      
  endgenerate
  // spyglass enable_block W484 

  //*************************************************************************************
  // UID Control
  // 
  // If a particular UID is not active then the outputs are driven to zero. Hence all UID
  // outputs can be gated to determine which UID drives the Read Data FIFO inputs and 
  // Read Data Channel.
  //*************************************************************************************
  generate
  genvar i;
    if (BYPASS_URID_FIFO==0) begin: URID_EN 

      // Depending on configuration only one UID may exists 
      assign r_fifo_push_n      = (bypass_urid_fifo)? !(rready_sp & rvalid_sp) : &uid_r_fifo_push_n;
      
      // Only one UID active when SP Active 
      // Gate all UID FIFO Payloads to determine value fro Read Data FIFO
      always @(*) begin: fifo_pyld_sel_PROC 
        integer k,j;
        r_pyld_fifo_i = {A2X_R_FIFO_PYLD_W{1'b0}};
        //spyglass disable_block W415a
        //SMD: Signal may be multiply assigned (beside initialization) in the same scope.
        //SJ : r_pyld_fifo_i is initialized before entering into loop to avoid latches.
        if (bypass_urid_fifo) begin
          // spyglass disable_block W164b
          // SMD: Identifies assignments in which the LHS width is greater than the RHS width
          // SJ : This is not a functional issue, this is as per the requirement.
          r_pyld_fifo_i = r_pyld_sp;
          // spyglass enable_block W164b
        // spyglass disable_block SelfDeterminedExpr-ML
        // SMD: Self determined expression found
        // SJ: The expression indexing the vector/array will never exceed the bound of the vector/array.
        end else begin
          for (k=0; k<A2X_NUM_URID; k=k+1) begin
            for (j=0; j<A2X_R_FIFO_PYLD_W; j=j+1) begin
              r_pyld_fifo_i[j] = (uid_r_pyld[(k*A2X_R_FIFO_PYLD_W)+j] | r_pyld_fifo_i[j]);
            end
          end    
        end
        // spyglass enable_block SelfDeterminedExpr-ML
        //spyglass enable_block W415a
      end
      assign r_pyld_fifo_i_w = r_pyld_fifo_i;
      
      // Depending on configuration only one UID may exists 
      assign r_uid_fifo_full = (bypass_urid_fifo)? 1'b0 :  |uid_fifo_full;
      
      // Depending on configuration only one UID may exists 
      assign r_uid_fifo_empty = (bypass_urid_fifo)? 1'b1 : |uid_fifo_empty;
      
      // UID FIFO Valid asserts when a write FIFO can accept a write. 
      assign r_uid_fifo_valid = (bypass_urid_fifo)? 1'b1 : (|uid_wr_en) & (~r_uid_fifo_full);

      // Depending on configuration only one UID may exists 
      assign r_osr_fifo_empty = &uid_fifo_empty;
      
      // Do not accept Read Data on SP if Read Data FIFO is Full or if the OSR
      // FIFO's are Empty. 
      assign rready_sp        =  (bypass_urid_fifo)?  (!r_fifo_full) : (!(r_fifo_full |  &uid_fifo_empty));

      //*************************************************************************************
      // UID Arbitrate
      // 
      // When more that one UID FIFO's empty enable UID with highest priorty. Used
      // to select which UID the ARID is written into.
      // UID[0] - Highest Priorty.
      // UID[N] - Lowest Priotry.
      // 
      // - If read data returned in order and not interleaved number of Unique ID set to 1. 
      //*************************************************************************************
      reg  [A2X_NUM_URID-1:0] uid_empty_priority;
      wire [A2X_NUM_URID-1:0] uid_fifo_match;
      
      //spyglass disable_block W415a
      //SMD: Signal may be multiply assigned (beside initialization) in the same scope.
      //SJ : uid_empty_priority is initialized before for loop to avoid latches and it is assigned with 0 in each iteration in order to determine the priority.
      always @(*) begin: urid_arb_PROC
        integer k;
        uid_empty_priority = {A2X_NUM_URID{1'b0}};
        if (bypass_urid_fifo) begin
          uid_empty_priority = {A2X_NUM_URID{1'b0}};
        end else begin
          for (k = A2X_NUM_URID-1; k>=0; k = k - 1) begin 
            if (uid_fifo_empty[k]==1'b1) begin
              uid_empty_priority    = {A2X_NUM_URID{1'b0}}; 
              uid_empty_priority[k] = 1'b1;
            end
          end
        end
      end
      //spyglass enable_block W415a  
      
      // If the incomming ID matches the ID of a fifo  in use then use that fifo
      // If configured for In-Order Responses then only one FIFO and we don't
      // care about the ID. 

      assign uid_wr_en = (A2X_READ_ORDER==0)? 1 : (~(|uid_fifo_match))? uid_empty_priority : (~(|uid_fifo_full))? uid_fifo_match : {A2X_NUM_URID{1'b0}};
      
      //--------------------------------------------------------------------
      // System Verilog Assertions
      //--------------------------------------------------------------------

      //*************************************************************************************
      // Unique Read ID Instantiation 
      // - Fanned out for the number of Unique read ID's that the A2X can Support. 
      // - If read data returned in order and not interleaved number of Unique ID set to 1. 
      //*************************************************************************************
      for (i = 0; i <A2X_NUM_URID; i=i+1) begin: URID 
        i_axi_a2x_2_DW_axi_a2x_r_uid
         #(
           .A2X_PP_MODE                             (A2X_PP_MODE)
          ,.A2X_UPSIZE                              (A2X_UPSIZE) 
          ,.A2X_DOWNSIZE                            (A2X_DOWNSIZE) 
          ,.A2X_BLW                                 (BLW_PP)
          ,.A2X_RSBW                                (A2X_RSBW)  
          
          ,.A2X_PP_ENDIAN                           (A2X_PP_ENDIAN)
          ,.A2X_SP_ENDIAN                           (A2X_SP_ENDIAN)

          ,.A2X_READ_ORDER                          (A2X_READ_ORDER)
          
          ,.A2X_RS_RATIO                            (A2X_RS_RATIO) 
          
          ,.A2X_PP_DW                               (A2X_PP_DW)
          ,.A2X_PP_MAX_SIZE                         (A2X_PP_MAX_SIZE)  
          ,.A2X_PP_NUM_BYTES                        (A2X_PP_NUM_BYTES)
          ,.A2X_PP_NUM_BYTES_LOG2                   (A2X_PP_NUM_BYTES_LOG2)
          
          ,.A2X_SP_DW                               (A2X_SP_DW)
          ,.A2X_SP_MAX_SIZE                         (A2X_SP_MAX_SIZE)  
          ,.A2X_SP_NUM_BYTES                        (A2X_SP_NUM_BYTES)
          ,.A2X_SP_NUM_BYTES_LOG2                   (A2X_SP_NUM_BYTES_LOG2)
          
          ,.A2X_OSR_LIMIT                           (A2X_OSR_LIMIT)
          ,.A2X_OSR_LIMIT_LOG2                      (A2X_OSR_LIMIT_LOG2)
          
          ,.A2X_PP_PYLD_W                           (A2X_PP_PYLD_W)
          ,.A2X_SP_PYLD_W                           (A2X_SP_PYLD_W)
          ,.A2X_RUS_PYLD_W                          (A2X_RUS_PYLD_W)
          ,.A2X_RDS_PYLD_W                          (A2X_RDS_PYLD_W)
        ) U_a2x_r_uid (
          // Outputs
           .uid_fifo_full                           (uid_fifo_full[i])
          ,.uid_fifo_empty                          (uid_fifo_empty[i])
          ,.uid_fifo_match                          (uid_fifo_match[i])
          ,.r_fifo_push_n                           (uid_r_fifo_push_n[i])
          ,.r_pyld_o                                (uid_r_pyld[((i+1)*A2X_R_FIFO_PYLD_W)-1:i*A2X_R_FIFO_PYLD_W])
          // Inputs
          ,.clk_sp                                  (clk_sp)
          ,.resetn_sp                               (resetn_sp)
          ,.arvalid_sp                              (arvalid_sp)
          ,.arready_sp                              (arready_sp)
          ,.arid_sp                                 (arid_sp)
          ,.uid_wr_en                               (uid_wr_en[i])
          ,.rvalid_sp                               (rvalid_sp)
          ,.rready_sp                               (rready_sp)
          ,.r_pyld_i                                (r_pyld_sp)
          ,.arlast_sp                               (arlast_sp)
          ,.sp_osar_pyld                            (sp_osar_pyld)
        );
      end // for (i = 0; i <A2X_NUM_URID; i=i+1)      
    end else begin //URID_BYPASS0
      assign rready_sp        = !r_fifo_full;
      assign r_fifo_push_n    = ~(rready_sp & rvalid_sp);
      assign r_pyld_fifo_i_w  = r_pyld_sp;

      // When in Locked mode the A2X needs to keep a count on the number of OS
      // Read transactions. This is required to generate the locking and
      // unlock command. 
      if (A2X_LOCKED==1) begin: LK_OSCNT
        reg  [A2X_OSR_LIMIT_LOG2-1:0] osr_cnt; 
        wire [A2X_OSR_LIMIT_LOG2-1:0] osr_cnt_i;
        assign osr_cnt_i =  osr_cnt;
        always @(posedge clk_sp or negedge resetn_sp) begin : osr_cnt_PROC
          if (resetn_sp==1'b0) begin
            osr_cnt <= 0;
          end else begin
            if (arvalid_sp && arready_sp && rvalid_sp && rready_sp && r_pyld_sp[0])
              osr_cnt <= osr_cnt_i; 
            else if (arvalid_sp && arready_sp)
              osr_cnt <= osr_cnt_i + 1; 
            else if (rvalid_sp && rready_sp && r_pyld_sp[0])
              osr_cnt <= osr_cnt_i - 1; 
          end
        end
        assign r_osr_fifo_empty = ~(|osr_cnt);
        // When max count reached A2X cannot send any more AR Addresses
        assign r_uid_fifo_valid = ~(&osr_cnt);  
      end else begin
        assign r_osr_fifo_empty = 1'b1;
        assign r_uid_fifo_valid = 1'b1;
      end
    end
  endgenerate  

endmodule

//Revision: $Id: //dwh/DW_ocb/DW_axi_a2x/axi_dev_br/src/DW_axi_a2x_r.v#22 $

