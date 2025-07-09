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
// File Version     :        $Revision: #9 $ 
// Revision: $Id: //dwh/DW_ocb/DW_axi_a2x/axi_dev_br/src/DW_axi_a2x_ar.v#9 $ 
**
** --------------------------------------------------------------------
**
** File     : DW_axi_a2x_ar.v
** Created  : Thu Jan 27 11:01:40 MET 2011
** Abstract :
**
** --------------------------------------------------------------------
*/

/*-------------------------------------------------------------------------------
**                  Address Channel Architecture Diagram
**-------------------------------------------------------------------------------
**
**
**   PP AR Channel   |----------|      |-----------|
**  ---------------->|    AR    |----->|  Address  | SP AR Channel
**                   |   FIFO   |      | Generator |--------------->
**                   |----------|      |-----------|
**                                          |
**                                          |  
**------------------------------------------|-------------------------------------
**            To Read Data Channel          |
**                                          V
**                                     Read Data 
**                                    control FIFO
** --------------------------------------------------------------------
*/

`include "DW_axi_a2x_all_includes.vh"

module i_axi_a2x_1_DW_axi_a2x_ar (/*AUTOARG*/
   // Outputs
   arready_pp, arvalid_sp, ar_pyld_sp, lock_req_o, unlock_req_o, os_unlock, 
   r_uid_fifo_push_n, ar_last_sp, sp_osar_pyld, osr_cnt_incr, osr_trans,
   ar_fifo_alen, ar_push_empty,
   // Inputs
   clk_pp, resetn_pp, clk_sp, resetn_sp, arvalid_pp, ar_pyld_pp, 
   arready_sp, rbuf_mode, r_osr_trans, 
   r_fifo_len, 
   r_uid_fifo_valid,  bypass_ar_ws, 
   unlock_req_i, lock_req_i, lock_grant, unlock_grant, lockseq_cmp,
   lp_mode
   );

  //*************************************************************************************
  // Parameters
  //*************************************************************************************
  parameter  A2X_PP_MODE              = 0;   // 0 = AHB 1 = AXI
  parameter  A2X_UPSIZE               = 0;   // 0 = Not Upsized 1 = Upsized
  parameter  A2X_DOWNSIZE             = 0;   // 0 = Not Downsized 1 Downsized
  parameter  A2X_LOCKED               = 0;   // A2X SUpports Locked Transactions

  parameter  BOUNDARY_W               = 12;  // 4K AXI Boundary
  parameter  A2X_AW                   = 32;  // Address Width
  parameter  A2X_BLW                  = 3;   // Burst Length Width
  parameter  A2X_AHB_RBLW             = 3;
  parameter  A2X_ARSBW                = 1;   // Address sideband width
  parameter  A2X_QOSW                 = 1;
  parameter  A2X_REGIONW              = 1;
  parameter  A2X_DOMAINW              = 1;
  parameter  A2X_RSNOOPW              = 1;
  parameter  A2X_BARW                 = 1;
  parameter  A2X_HINCR_HCBCNT         = 0; 
  parameter  A2X_HINCR_MAX_RBCNT      = 0;

  parameter  A2X_PP_DW                = 32;
  parameter  A2X_SP_DW                = 32;
  parameter  A2X_SP_MAX_SIZE          = 2;
  parameter  A2X_PP_MAX_SIZE          = 2;

  parameter  A2X_RS_RATIO_LOG2        = 0;
  parameter  A2X_SP_NUM_BYTES_LOG2    = 2;
  parameter  A2X_PP_NUM_BYTES_LOG2    = 2;

  parameter  A2X_CLK_MODE             = 0;
  parameter  A2X_AR_FIFO_DEPTH        = 32;
  parameter  A2X_AR_FIFO_DEPTH_LOG2   = 2;

  parameter  BYPASS_AR_AC             = 1; 
  parameter  BYPASS_AR_WS             = 1; 
  parameter  BYPASS_SNF_R             = 0; 

  // Primary Port Length 
  localparam BLW_PP                   = (A2X_PP_MODE==1) ? A2X_BLW : A2X_AHB_RBLW;

  // Address Channel Payload
  localparam A2X_AR_PYLD_W            = A2X_BARW + A2X_RSNOOPW + A2X_DOMAINW + A2X_REGIONW + A2X_QOSW + `i_axi_a2x_1_A2X_HBTYPE_W + 
                                        A2X_ARSBW + `i_axi_a2x_1_A2X_IDW +  A2X_AW   + `i_axi_a2x_1_A2X_RSW + A2X_BLW + `i_axi_a2x_1_A2X_BSW + 
                                       `i_axi_a2x_1_A2X_BTW   + `i_axi_a2x_1_A2X_LTW   + `i_axi_a2x_1_A2X_CTW + `i_axi_a2x_1_A2X_PTW;

  // Resize FIFO Payload - Address Bits taken for the larger of the Data Busses
  localparam A2X_RDS_PYLD_W            = `i_axi_a2x_1_A2X_RSW + 1 + `i_axi_a2x_1_A2X_BSW + A2X_PP_NUM_BYTES_LOG2 + 1; 
                                           

  localparam A2X_RUS_PYLD_W            = `i_axi_a2x_1_A2X_RSW + 1 + BLW_PP + `i_axi_a2x_1_A2X_BSW + 1 + A2X_SP_NUM_BYTES_LOG2;

  localparam A2X_SP_OSAR_PYLD_W        = (A2X_DOWNSIZE==1)? A2X_RDS_PYLD_W : (A2X_UPSIZE==1)? A2X_RUS_PYLD_W : `i_axi_a2x_1_A2X_BSW; 

  //*************************************************************************************
  // IO Decelaration
  //*************************************************************************************
  // spyglass disable_block W240
  // SMD: An input has been declared but is not read
  // SJ: These nets are used to connect the logic under certain configuration.
  // But this may not drive some of the nets. This will not cause any functional issue.
  input                                       clk_pp;
  input                                       resetn_pp;

  input                                       clk_sp;
  input                                       resetn_sp;

  input                                       bypass_ar_ws;

  // AXI Write Address
  output                                      arready_pp;        // AR Primary Port
  input                                       arvalid_pp;
  input  [A2X_AR_PYLD_W-1:0]                  ar_pyld_pp;

  input                                       arready_sp;        // AR Secondary Port
  output                                      arvalid_sp;
  output [A2X_AR_PYLD_W-1:0]                  ar_pyld_sp;
  
  input                                       lock_grant;            // Locked Control
  input                                       unlock_grant;            // Locked Control
  input                                       lockseq_cmp;                 
  output                                      os_unlock;                 
  output                                      lock_req_o;
  input                                       lock_req_i;
  output                                      unlock_req_o;
  input                                       unlock_req_i;

  input                                       rbuf_mode;
  // r_fifo_len is read only if BYPASS_SNF_R=0
  input  [31:0]                               r_fifo_len;         // Read Data FIFO Word Count

  output                                      r_uid_fifo_push_n;   // Unique Read FIFO Control
  input                                       r_uid_fifo_valid;
  input                                       r_osr_trans;
  
  output                                      ar_last_sp;
  output [A2X_SP_OSAR_PYLD_W-1:0]             sp_osar_pyld;
  output                                      osr_cnt_incr;       // Incremtn Outstanding Read Counter
  output [10:0]                               ar_fifo_alen; 
  output                                      ar_push_empty;
  output                                      osr_trans;
   
  input                                       lp_mode;
  // spyglass enable_block W240

  //*************************************************************************************
  // Signal Decelaration
  //*************************************************************************************
  //These are dummy wires used to connect the unconnected ports.
  //Hence will not drive any nets.
  wire   [`i_axi_a2x_1_A2X_IDW-1:0]                       aid_i;             // FIFO Payload
  wire   [A2X_AW-1:0]                         aaddr_i; 
  
  //These are dummy wires used to connect the unconnected ports.
  wire   [A2X_BLW-1:0]                        alen_i; 
  wire   [`i_axi_a2x_1_A2X_BSW-1:0]                       asize_i;
  wire   [`i_axi_a2x_1_A2X_BTW-1:0]                       aburst_i;   
  wire   [`i_axi_a2x_1_A2X_LTW-1:0]                       alock_i;   
  wire   [`i_axi_a2x_1_A2X_CTW-1:0]                       acache_i; 
  wire   [`i_axi_a2x_1_A2X_PTW-1:0]                       aprot_i; 
  wire   [A2X_ARSBW-1:0]                      asideband_i;
  wire   [A2X_QOSW-1:0]                       aqos_i;
  wire   [A2X_REGIONW-1:0]                    aregion_i;
  wire   [A2X_DOMAINW-1:0]                    adomain_i;
  wire   [A2X_RSNOOPW-1:0]                    asnoop_i;
  wire   [A2X_BARW-1:0]                       abar_i;
  wire   [`i_axi_a2x_1_A2X_RSW-1:0]                       aresize_i;
  wire                                        hburst_type; 

  //  FIFO Control
  wire                                        ar_fifo_push_n;      // AR FIFO
  wire                                        ar_fifo_pop_n;
  wire                                        ar_fifo_full;
  wire                                        ar_fifo_empty;

  //These are dummy wires used to connect the unconnected ports.
  wire  [A2X_AR_FIFO_DEPTH_LOG2:0]            ar_fifo_pop_count;  
  wire  [A2X_AR_FIFO_DEPTH_LOG2:0]            ar_fifo_push_count;

  wire                                        sp_os_fifo_valid;

  //  FIFO Payload's
  wire  [A2X_AR_PYLD_W-1:0]                   ar_pyld_fifo_o;

  wire                                        r_fifo_valid; 

  wire  [31:0]                                max_len;           // Maximum Length
  
  //These are dummy wires used to connect the unconnected ports.
  wire  [A2X_BLW-1:0]                         ar_alen_sp;        // Secondary Port Length
 
  wire                                        sp_add_active;     // Secondary Port Active

  //These are dummy wires used to connect the unconnected ports.
  wire                                        onek_exceed;
  wire  [A2X_AW-1:0]                          ws_addr;          // Wrap Splitter output Address

  wire  [BLW_PP-1:0]                          ws_alen;          // Wrap Splitter output Length
  wire  [`i_axi_a2x_1_A2X_BSW-1:0]                        ws_size;     
  wire  [`i_axi_a2x_1_A2X_RSW-1:0]                        ws_resize; 
  wire                                        ws_last;
  wire                                        ws_fixed;         // AXI Only Fixed Burst. 
  wire                                        unconn_2;

  wire                                        trans_en; // transaction enable

  // **************************************************************************************
  // Decode of Write Address FIFO 
  // **************************************************************************************
  assign {abar_i, asnoop_i, adomain_i, aregion_i, aqos_i, hburst_type, asideband_i, aid_i, aaddr_i, aresize_i, alen_i, asize_i,
  aburst_i, alock_i, acache_i, aprot_i} = ar_pyld_fifo_o;

  // **************************************************************************************
  // Resize FIFO Payload
  //
  // Payload Resize information for the 
  // - AW Downsizing Configs
  // - AR Downsizing Configs
  // - AR Upsizing Configs
  // **************************************************************************************
  generate
    if (A2X_UPSIZE==1) begin
      assign sp_osar_pyld   = {ws_resize, ws_fixed, ws_alen, ws_size, ws_addr[A2X_SP_NUM_BYTES_LOG2-1:0], ws_last};
    end else if (A2X_DOWNSIZE==1) begin
      assign sp_osar_pyld   = {ws_resize, ws_fixed, ws_size, ws_addr[A2X_PP_NUM_BYTES_LOG2-1:0], ws_last};
    end else begin
      assign sp_osar_pyld   = {ws_size};
    end
  endgenerate
  
  //*************************************************************************************
  // Address FIFO (AR) Control
  //*************************************************************************************
  assign arready_pp        = !(ar_fifo_full | lp_mode);
  assign ar_fifo_push_n    = !(arready_pp & arvalid_pp);

  //*************************************************************************************
  //                            AR FIFO
  //*************************************************************************************
  i_axi_a2x_1_DW_axi_a2x_fifo
   #(
     .DUAL_CLK                               (A2X_CLK_MODE)
    ,.PUSH_SYNC_DEPTH                        (`i_axi_a2x_1_A2X_PP_SYNC_DEPTH)
    ,.POP_SYNC_DEPTH                         (`i_axi_a2x_1_A2X_SP_SYNC_DEPTH)
    ,.DATA_W                                 (A2X_AR_PYLD_W)
    ,.DEPTH                                  (A2X_AR_FIFO_DEPTH)
    ,.LOG2_DEPTH                             (A2X_AR_FIFO_DEPTH_LOG2)
  ) U_a2x_ar_fifo (
     .clk_push_i                             (clk_pp)
    ,.resetn_push_i                          (resetn_pp)
    ,.push_req_n_i                           (ar_fifo_push_n)
    ,.data_i                                 (ar_pyld_pp)
    ,.push_full_o                            (ar_fifo_full)
    ,.push_empty_o                           (ar_push_empty)
    ,.clk_pop_i                              (clk_sp)
    ,.resetn_pop_i                           (resetn_sp)
    ,.pop_req_n_i                            (ar_fifo_pop_n)
    ,.pop_empty_o                            (ar_fifo_empty)
    ,.data_o                                 (ar_pyld_fifo_o)    
    ,.push_count                             (ar_fifo_push_count)
    ,.pop_count                              (ar_fifo_pop_count)
  );

  // Address is popped off the FIFO and placed into a holding Register in the
  // SP Address Generator 
  assign ar_fifo_pop_n       = !(arvalid_sp & arready_sp & (!sp_add_active));
  // Increment the Outstanding Read Counter when sending a SP address.
  assign osr_cnt_incr        = arvalid_sp & arready_sp;

  // Update for lint so all bits are driven
  generate
  if      ((A2X_PP_MODE==0) && (BLW_PP==11)) begin: FIFOLEN_1
    assign ar_fifo_alen = ws_alen;
  end // FIFOLEN_1
  else if ((A2X_PP_MODE==0) && (BLW_PP!=11)) begin: FIFOLEN_2
    assign ar_fifo_alen = {{(11-A2X_AHB_RBLW){1'b0}}, ws_alen};
  end // FIFOLEN_2
  else if ((A2X_PP_MODE==1) && (BLW_PP==11)) begin: FIFOLEN_3
    assign ar_fifo_alen = alen_i;
  end // FIFOLEN_3
  else if ((A2X_PP_MODE==1) && (BLW_PP!=11)) begin: FIFOLEN_4
    assign ar_fifo_alen = {{(11-A2X_BLW){1'b0}}, alen_i};
  end // FIFOLEN_4
  endgenerate // FIFOLEN

  //*************************************************************************************
  // Secondary Port Address Generation
  //*************************************************************************************
  i_axi_a2x_1_DW_axi_a2x_sp_add
   #(    
     .A2X_CHANNEL                            (1)            
    ,.A2X_PP_MODE                            (A2X_PP_MODE)
    ,.A2X_LOCKED                             (A2X_LOCKED) 
    ,.BOUNDARY_W                             (BOUNDARY_W)
    ,.A2X_AW                                 (A2X_AW) 
    ,.A2X_BLW                                (A2X_BLW) 
    ,.A2X_AHB_BLW                            (A2X_AHB_RBLW)
    ,.A2X_HINCR_HCBCNT                       (A2X_HINCR_HCBCNT)
    ,.A2X_HINCR_MAX_BCNT                     (A2X_HINCR_MAX_RBCNT)
    ,.A2X_ASBW                               (A2X_ARSBW)
    ,.A2X_QOSW                               (A2X_QOSW)
    ,.A2X_REGIONW                            (A2X_REGIONW)
    ,.A2X_DOMAINW                            (A2X_DOMAINW)
    ,.A2X_WSNOOPW                            (A2X_RSNOOPW)
    ,.A2X_BARW                               (A2X_BARW)
    ,.A2X_PP_DW                              (A2X_PP_DW) 
    ,.A2X_SP_DW                              (A2X_SP_DW) 
    ,.A2X_SP_MAX_SIZE                        (A2X_SP_MAX_SIZE) 
    ,.A2X_PP_MAX_SIZE                        (A2X_PP_MAX_SIZE) 
    ,.A2X_RS_RATIO_LOG2                      (A2X_RS_RATIO_LOG2) 
    ,.A2X_SP_NUM_BYTES_LOG2                  (A2X_SP_NUM_BYTES_LOG2) 
    ,.A2X_PP_NUM_BYTES_LOG2                  (A2X_PP_NUM_BYTES_LOG2) 
    ,.BYPASS_AC                              (BYPASS_AR_AC)
    ,.BYPASS_WS                              (BYPASS_AR_WS)
    ,.A2X_WSNF_PYLD_W                        (1)
  ) U_ar_add ( 
    // Outputs
     .a_pyld_o                               (ar_pyld_sp)    
    ,.onek_exceed                            (onek_exceed)
    ,.alen_sp                                (ar_alen_sp)
    ,.alast_sp                               (ar_last_sp)
    ,.a_active                               (sp_add_active)
    ,.lock_req_o                             (lock_req_o)
    ,.unlock_req_o                           (unlock_req_o)
    ,.os_unlock                              (os_unlock)
    ,.ws_addr                                (ws_addr)
    ,.ws_alen                                (ws_alen)
    ,.ws_size                                (ws_size)
    ,.ws_resize                              (ws_resize)
    ,.ws_fixed                               (ws_fixed)
    ,.ws_last                                (ws_last)
    ,.w_snf_pop_en                           (unconn_2)
    
    // Inputs
    ,.clk                                    (clk_sp)
    ,.resetn                                 (resetn_sp)
    ,.buf_mode                               (rbuf_mode)
    ,.max_len                                (max_len)    
    ,.lock_grant                             (lock_grant)
    ,.unlock_grant                           (unlock_grant)
    ,.unlock_req_i                           (unlock_req_i)
    ,.lock_req_i                             (lock_req_i)
    ,.lockseq_cmp                            (lockseq_cmp)
    ,.trans_en                               (trans_en)
    ,.a_pyld_i                               (ar_pyld_fifo_o)    
    ,.snf_pyld_i                             (1'b0)    
    ,.a_ready_i                              (arready_sp)
    ,.a_fifo_empty                           (ar_fifo_empty)
    ,.sp_os_fifo_valid                       (sp_os_fifo_valid)
    ,.bypass_ws                              (bypass_ar_ws)
  );

  // Maximum FIFO Length is dependand on Mode
  // - CT Mode maximum length is 2^A2X_BLW
  // - SNF Mode maximum length is 2^A2X_BLW
  assign max_len = (1 << A2X_BLW);

  //*************************************************************************************
  // Oustanding Secondary Read Transaction
  // This pin asserts when there is outstanding transactions on the SP or
  // when the Address generator is breaking an existing transaction into
  // multiple transactions. Or When there exists and address in the AR FIFO.
  //*************************************************************************************
  assign osr_trans = (trans_en & sp_add_active) | r_osr_trans;

  // Secondary Port Outstanding FIFo's are Valid
  // - Read Unique FIFO is not FUll 
  // - Maximum Outstanding Read
  assign sp_os_fifo_valid = r_uid_fifo_valid & r_fifo_valid;

  // A Valid AR Address can be sent on the SP if 
  // A Valid AR Address can be sent on the SP if 
  // - AR FIFO is not Empty and the SP OS FIFOs are valid and SP Add Generator is not generating an address
  // - SP address generator is generating an address and SP OS FIFOs are valid.
  // - If Generating a locked or unlocked transaction the trans_en is deasserted until all
  //   outstanding transactioni are returned to the A2X. 
  assign arvalid_sp   = trans_en & (((!sp_add_active) & (!ar_fifo_empty) & sp_os_fifo_valid) | (sp_add_active & sp_os_fifo_valid)); 

  //*************************************************************************************
  // Unique Read Channel FIFO Control
  //*************************************************************************************
  assign r_uid_fifo_push_n  = !(arvalid_sp & arready_sp);

  //*************************************************************************************
  // Read Data FIFO SNF Control
  //
  // If the Number of Free Spaces is greater than the SNF Length then generate
  // a SP Address. Otherwise wait until there is enough free spaces. 
  //*************************************************************************************
  // - SNF Mode maximum Length is calculated from amount of free space in RD FIFO

generate 
if (BYPASS_SNF_R==1) begin: BYPSNFR
assign r_fifo_valid = 1'b1;
end else begin
// If Not Bypassed Then in Store-Forward Mode. - Programmable Mode Removed. 
// Only take FIFO valid when the SP length is less than or Equal to the
// Number of free spaces in the FIFO.
// spyglass disable_block W362
// SMD: Reports an arithmetic comparison operator with unequal length
// SJ : This is not a functional issue, this is as per the requirement.
//      Hence this can be waived.  
assign r_fifo_valid = (rbuf_mode==1'b0)? 1'b1 : (r_fifo_len>ar_alen_sp) ? 1'b1 : 1'b0;
// spyglass enable_block W362
end
endgenerate  

endmodule
//Revision: $Id: //dwh/DW_ocb/DW_axi_a2x/axi_dev_br/src/DW_axi_a2x_ar.v#9 $
