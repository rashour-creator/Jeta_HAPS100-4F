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
// File Version     :        $Revision: #15 $ 
// Revision: $Id: //dwh/DW_ocb/DW_axi_a2x/axi_dev_br/src/DW_axi_a2x_sp_add.v#15 $ 
**
** --------------------------------------------------------------------
**
** File     : DW_axi_a2x_sp_add.v
** Created  : Thu Jan 27 11:01:40 MET 2011
** Abstract : Address Generator For AR and AW Channel.
**
**
**      AW/R FIFO
**  ------------|       |----------|        |---------|      |------------|
**    | | | | | |       |          |        |         |      |            | SP AW/R Channel
**    | | | | | |------>|  Address |------->| Address |----->|   Address  |---------------->
**    | | | | | |       |   Wrap   |        | Resizer |      | Calculator |
**    | | | | | |       | Splitter |        |         |      |            |
**  ------------|       |----------|        |---------|      |------------|
**  
**  
**   Address Decoder
**   - This Address Decoder is used in both the AW & AR Channel
**
**   Wrap Splitter
**    - All Wrap Addresses are convertered to INCR Transactions. Except in a equaled sized CT Configuration.
**   Address Resizer
**    - Only in use for Upsizing/Downsizing Configs. 
**    - Generates the Resized Length, Size and Burst Type
**   Address Calculator
**    - Breaks the Transaction Address in to Transactions of Length equal to the SNF Length
**      or the Maximum SP Length (2^A2X_BLW).
**     
**   For AHB Configuration the A2X_HINCR_ARLEN Register is used to determine the AXI Read Prefetch Length.
**   This may required the Address Calculator to generate multiple address since the Maximum length it can send 
**   on the SP is 2^A2X_BLW or A2X_SNF_ARLEN. 
**   It is worth noting that if the A2X_HINCR_ARLEN is less than the 2^A2X_BLW in Hardcode CT Mode all the address
**   calculator logic can be blow away. 
**   For Write the AHB INCR Control is generated inside the H2X Block so no such restriction is required. 
** --------------------------------------------------------------------------------------------
*/
`include "DW_axi_a2x_all_includes.vh"

module i_axi_a2x_2_DW_axi_a2x_sp_add (/*AUTOARG*/
   // Outputs
   lock_req_o, unlock_req_o, os_unlock,
   trans_en, a_active, a_pyld_o, alen_sp, alast_sp, onek_exceed, 
   ws_addr, ws_alen, ws_resize, ws_fixed, ws_size, ws_last,
   w_snf_pop_en,
   // Inputs
   clk, resetn, buf_mode, 
   max_len, 
   a_ready_i, a_fifo_empty, sp_os_fifo_valid, a_pyld_i, snf_pyld_i, bypass_ws,
   lock_req_i, unlock_req_i, lock_grant, unlock_grant, lockseq_cmp 
   );

  // **************************************************************************************
  // Parameters
  // **************************************************************************************
  parameter  A2X_CHANNEL              = 0;   // 0 = Write 1 = Read
  parameter  A2X_PP_MODE              = 0;   // 0 = AHB 1 = AXI
  parameter  A2X_LOCKED               = 0;   // A2X SUpports Locked Transactions

  parameter  BOUNDARY_W               = 12; 
  parameter  A2X_AW                   = 32;  // Address Width
  parameter  A2X_BLW                  = 4;   // Burst Length Width
  parameter  A2X_ASBW                 = 1;   // Address Sideband Width
  parameter  A2X_QOSW                 = 1;
  parameter  A2X_REGIONW              = 1;
  parameter  A2X_DOMAINW              = 1;
  parameter  A2X_WSNOOPW              = 1;
  parameter  A2X_BARW                 = 1;

  parameter  A2X_PP_DW                = 32;
  parameter  A2X_SP_DW                = 32;
  parameter  A2X_SP_MAX_SIZE          = 2;
  parameter  A2X_PP_MAX_SIZE          = 2;

  parameter  A2X_RS_RATIO_LOG2        = 0;
  parameter  A2X_SP_NUM_BYTES_LOG2    = 2;
  parameter  A2X_PP_NUM_BYTES_LOG2    = 2;

  parameter  BYPASS_AC                 = 1; 
  parameter  BYPASS_WS                 = 1; 
  parameter  A2X_HINCR_HCBCNT          = 0; 
  parameter  A2X_HINCR_MAX_BCNT        = 0;
  parameter  A2X_AHB_BLW               = 4; 
  parameter  A2X_BRESP_MODE            = 0; 
  parameter  A2X_WSNF_PYLD_W           = 1; 

  // Bypass Address in AXI Mode if Wrap Splitter is Bypassed.
  localparam BYPASS_AS                = ((A2X_PP_MODE==1) & (BYPASS_WS))? 1 : 0;

  localparam A2X_EQSIZE               = (A2X_PP_DW==A2X_SP_DW)? 1 : 0; 
  localparam A2X_UPSIZE               = (A2X_PP_DW<A2X_SP_DW)?  1 : 0; 
  localparam A2X_DOWNSIZE             = (A2X_PP_DW>A2X_SP_DW)?  1 : 0; 

  // AXI Burst Length Output Width from Address Splitter. 
  // AHB Equalled Sized
  // - For Read  Transaction the BLW width is A2X_AHB_BLW as the Address Calculator breaks the address down.
  // - For Write Transaction the BLW Width is A2X_BLW as the Address Calculator is bypassed and AHB address 
  //   taken from AHB Bus. 
  // AXI Equalled Sized   
  // - For Read and Writes BLW Width set to A2X_BLW. Address Spliiter/Resizer Bypassed
  // AHB Upsized
  // - For Read  Transaction the BLW Width is A2X_AHB_BLW as the Address Calculator breaks the address down.
  // - For Write Transaction the BLW Width is A2X_AHB_BLW as the Resizer need to know the Transaction length  
  //   to divide by Resize Ratio. Output is always less than 2^A2X_BLW. Address Calculator always bypassed in 
  //   AHB Write Upsizing Configs. 
  //      
  //   Downzised Configs. Hence the BLW width increases by Log2 
  // - AHB Configuration. AHB INCR Length can be upto 1K i.e. 10 bits
  localparam BLW_AS                   = ((A2X_PP_MODE==0) && (A2X_EQSIZE==1)   && (A2X_CHANNEL==1))? A2X_AHB_BLW :
                                        ((A2X_PP_MODE==0) && (A2X_EQSIZE==1)   && (A2X_CHANNEL==0))? A2X_BLW     :
                                        ((A2X_PP_MODE==1) && (A2X_EQSIZE==1)   && (A2X_CHANNEL==1))? A2X_BLW     :
                                        ((A2X_PP_MODE==1) && (A2X_EQSIZE==1)   && (A2X_CHANNEL==0))? A2X_BLW     :
                                        ((A2X_PP_MODE==0) && (A2X_UPSIZE==1)   && (A2X_CHANNEL==1))? A2X_AHB_BLW :
                                        ((A2X_PP_MODE==0) && (A2X_UPSIZE==1)   && (A2X_CHANNEL==0))? A2X_AHB_BLW :
                                        ((A2X_PP_MODE==1) && (A2X_UPSIZE==1)   && (A2X_CHANNEL==1))? A2X_BLW     :
                                        ((A2X_PP_MODE==1) && (A2X_UPSIZE==1)   && (A2X_CHANNEL==0))? A2X_BLW     :
                                        ((A2X_PP_MODE==0) && (A2X_DOWNSIZE==1) && (A2X_CHANNEL==1))? A2X_AHB_BLW :
                                        ((A2X_PP_MODE==0) && (A2X_DOWNSIZE==1) && (A2X_CHANNEL==0))? A2X_AHB_BLW :
                                        ((A2X_PP_MODE==1) && (A2X_DOWNSIZE==1) && (A2X_CHANNEL==1))? A2X_BLW     :
                                        ((A2X_PP_MODE==1) && (A2X_DOWNSIZE==1) && (A2X_CHANNEL==0))? A2X_BLW     : A2X_BLW;

  // - Resize Ratio i.e. Resize Ratio of 2 implies length increases by 2 for Downsizing, decreases by 2 for Upsizing.
  localparam BLW_RS                   = ((A2X_PP_MODE==0) && (A2X_EQSIZE==1)   && (A2X_CHANNEL==1))? A2X_AHB_BLW :
                                        ((A2X_PP_MODE==0) && (A2X_EQSIZE==1)   && (A2X_CHANNEL==0))? A2X_BLW     :
                                        ((A2X_PP_MODE==1) && (A2X_EQSIZE==1)   && (A2X_CHANNEL==1))? A2X_BLW     :
                                        ((A2X_PP_MODE==1) && (A2X_EQSIZE==1)   && (A2X_CHANNEL==0))? A2X_BLW     :
                                        ((A2X_PP_MODE==0) && (A2X_UPSIZE==1)   && (A2X_CHANNEL==1))? A2X_AHB_BLW :
                                        ((A2X_PP_MODE==0) && (A2X_UPSIZE==1)   && (A2X_CHANNEL==0))? A2X_BLW     :
                                        ((A2X_PP_MODE==1) && (A2X_UPSIZE==1)   && (A2X_CHANNEL==1))? A2X_BLW     :
                                        ((A2X_PP_MODE==1) && (A2X_UPSIZE==1)   && (A2X_CHANNEL==0))? A2X_BLW     :
                                        ((A2X_PP_MODE==0) && (A2X_DOWNSIZE==1) && (A2X_CHANNEL==1))? A2X_AHB_BLW+A2X_RS_RATIO_LOG2 :
                                        ((A2X_PP_MODE==0) && (A2X_DOWNSIZE==1) && (A2X_CHANNEL==0))? A2X_AHB_BLW+A2X_RS_RATIO_LOG2 :
                                        ((A2X_PP_MODE==1) && (A2X_DOWNSIZE==1) && (A2X_CHANNEL==1))? A2X_BLW+A2X_RS_RATIO_LOG2     :
                                        ((A2X_PP_MODE==1) && (A2X_DOWNSIZE==1) && (A2X_CHANNEL==0))? A2X_BLW+A2X_RS_RATIO_LOG2     : A2X_BLW;
  
  // Address Channel Payload
  localparam A2X_A_PYLD_W             = A2X_BARW + A2X_WSNOOPW + A2X_DOMAINW + A2X_REGIONW + A2X_QOSW +
                                        `i_axi_a2x_2_A2X_HBTYPE_W +  A2X_ASBW  + `i_axi_a2x_2_A2X_IDW +  A2X_AW   + `i_axi_a2x_2_A2X_RSW + A2X_BLW + `i_axi_a2x_2_A2X_BSW + 
                                        `i_axi_a2x_2_A2X_BTW      + `i_axi_a2x_2_A2X_LTW   + `i_axi_a2x_2_A2X_CTW + `i_axi_a2x_2_A2X_PTW;      

  // Resize FIFO Payload - Address Bits taken for the larger of the Data Busses
  localparam A2X_RS_PYLD_W            = (A2X_UPSIZE==1)?  (`i_axi_a2x_2_A2X_RSW + `i_axi_a2x_2_A2X_BSW + A2X_SP_NUM_BYTES_LOG2) : 
                                                          (`i_axi_a2x_2_A2X_RSW + `i_axi_a2x_2_A2X_BSW + A2X_PP_NUM_BYTES_LOG2);

  // Address Splitter fanns out alen
  localparam A2X_AS_PYLD_W            = A2X_BARW + A2X_WSNOOPW + A2X_DOMAINW + A2X_REGIONW + A2X_QOSW +
                                        `i_axi_a2x_2_A2X_HBTYPE_W + A2X_ASBW + `i_axi_a2x_2_A2X_IDW +  A2X_AW  + `i_axi_a2x_2_A2X_RSW + BLW_AS + `i_axi_a2x_2_A2X_BSW + 
                                        `i_axi_a2x_2_A2X_BTW      + `i_axi_a2x_2_A2X_LTW + `i_axi_a2x_2_A2X_CTW + `i_axi_a2x_2_A2X_PTW;

  // Address Resizer fanns out alen 
  localparam A2X_AR_PYLD_W            = A2X_BARW + A2X_WSNOOPW + A2X_DOMAINW + A2X_REGIONW + A2X_QOSW +
                                        `i_axi_a2x_2_A2X_HBTYPE_W + A2X_ASBW + `i_axi_a2x_2_A2X_IDW +  A2X_AW  + `i_axi_a2x_2_A2X_RSW + BLW_RS + `i_axi_a2x_2_A2X_BSW + 
                                        `i_axi_a2x_2_A2X_BTW      + `i_axi_a2x_2_A2X_LTW + `i_axi_a2x_2_A2X_CTW + `i_axi_a2x_2_A2X_PTW;

  // Used For Bypassing Address Calculator                                      
  localparam ALEN_PYLD_TO_BIT         = `i_axi_a2x_2_A2X_BSW + `i_axi_a2x_2_A2X_BTW      + `i_axi_a2x_2_A2X_LTW   + `i_axi_a2x_2_A2X_CTW + `i_axi_a2x_2_A2X_PTW;
  localparam ALEN_PYLD_FROM_BIT       =  BLW_RS  + ALEN_PYLD_TO_BIT;

  // Used for Lock Transaction
  localparam ALOCK_PYLD_TO_BIT        =  `i_axi_a2x_2_A2X_CTW + `i_axi_a2x_2_A2X_PTW;
  localparam ALOCK_PYLD_FROM_BIT      =  `i_axi_a2x_2_A2X_LTW + ALOCK_PYLD_TO_BIT;

  // **************************************************************************************
  // I/O Decelaration
  // **************************************************************************************
  //spyglass disable_block W240
  //SMD: An input has been declared but is not read.
  //SJ : This input is used in specific config only 
  input                                       clk;
  input                                       resetn;

  input                                       buf_mode;            // Software Registers
  input  [31:0]                               max_len;
  input                                       bypass_ws;

  input                                       lock_req_i;
  //spyglass enable_block W240
  output                                      lock_req_o;
  //spyglass disable_block W240
  //SMD: An input has been declared but is not read.
  //SJ : This input is used in specific config only 
  input                                       lock_grant;
  input                                       unlock_req_i;
  //spyglass enable_block W240
  output                                      unlock_req_o;
  //spyglass disable_block W240
  //SMD: An input has been declared but is not read.
  //SJ : This input is used in specific config only 
  input                                       unlock_grant;
  //spyglass enable_block W240
  output                                      os_unlock; 
  //spyglass disable_block W240
  //SMD: An input has been declared but is not read.
  //SJ : This input is used in specific config only 
  input                                       lockseq_cmp; 
  //spyglass enable_block W240
  output                                      trans_en; 

  //spyglass disable_block W240
  //SMD: An input has been declared but is not read.
  //SJ : This input is used in specific config only 
  input                                       a_ready_i;          // SP Read and Valid
  input                                       a_fifo_empty;       // Address FIFO Status
  input                                       sp_os_fifo_valid;   // Outstanding FIFO status
  //spyglass enable_block W240
  output                                      a_active;           // SP Active 

  input  [A2X_A_PYLD_W-1:0]                   a_pyld_i;           // Payload 
  output [A2X_A_PYLD_W-1:0]                   a_pyld_o;
  output [A2X_BLW-1:0]                        alen_sp; 
  output                                      alast_sp;           // Last SP Transaction

  //spyglass disable_block W240
  //SMD: An input has been declared but is not read.
  //SJ : This input is used in specific config only 
  input  [A2X_WSNF_PYLD_W-1:0]                snf_pyld_i; 
  //spyglass enable_block W240

  output                                      onek_exceed;

  output [A2X_AW-1:0]                         ws_addr;          // Wrap Splitter output Address
  output [BLW_AS-1:0]                         ws_alen;          // Wrap Splitter output Length
  output [`i_axi_a2x_2_A2X_BSW-1:0]                       ws_size; 
  output [`i_axi_a2x_2_A2X_RSW-1:0]                       ws_resize; 
  output                                      ws_fixed;
  output                                      ws_last;
  output                                      w_snf_pop_en;

  // **************************************************************************************
  // Signal Decelaration
  //
  // _ac signals are from Address Calulator
  // _as signals are from Address Splitter
  // _rs signals are from Address Resizer
  // **************************************************************************************
  // These are dummy wires used to connect the unconnected ports.
  // Hence will not drive any nets.
  wire   [`i_axi_a2x_2_A2X_IDW-1:0]                       aid_i;             // Payload
  wire   [A2X_AW-1:0]                         aaddr_i; 
  wire   [A2X_BLW-1:0]                        alen_i; 
  wire   [`i_axi_a2x_2_A2X_BTW-1:0]                       aburst_i;   
  wire   [`i_axi_a2x_2_A2X_CTW-1:0]                       acache_i; 
  wire   [`i_axi_a2x_2_A2X_PTW-1:0]                       aprot_i; 
  wire   [A2X_ASBW-1:0]                       asideband_i;
  wire   [A2X_QOSW-1:0]                       aqos_i;
  wire   [A2X_REGIONW-1:0]                    aregion_i;
  wire   [A2X_DOMAINW-1:0]                    adomain_i;
  wire   [A2X_WSNOOPW-1:0]                    asnoop_i;
  wire   [A2X_BARW-1:0]                       abar_i;
  wire   [`i_axi_a2x_2_A2X_RSW-1:0]                       aresize_i;
  wire                                        hburst_type; 
  // These nets are used to connect the logic under certain configuration. 
  // But this may not drive any nets in some other configuration. 
  wire   [`i_axi_a2x_2_A2X_BSW-1:0]                       asize_i;     
  wire   [`i_axi_a2x_2_A2X_LTW-1:0]                       alock_i;   

  // Generated from Locked Control
  wire   [`i_axi_a2x_2_A2X_LTW-1:0]                       alock_o;   

  wire   [A2X_A_PYLD_W-1:0]                   a_pyld_i;
  wire   [A2X_AR_PYLD_W-1:0]                  a_pyld_rs;
  wire   [A2X_AS_PYLD_W-1:0]                  a_pyld_as;
  wire   [A2X_A_PYLD_W-1:0]                   a_pyld_lk;

  wire   [A2X_BLW-1:0]                        alen_ac;           // Address Calculator Length 
  wire   [A2X_BLW-1:0]                        nxt_alen_ac;       // Address Calculator Length 
  wire                                        wrap;
  wire   [A2X_WSNF_PYLD_W-1:0]                snf_pyld_w; 
  wire                                        active_ac;         // Address Calculator Active
  wire                                        active_as;         // Address Splitter Active
  wire                                        alast_ac;          // Address Calculator Last Address 
  wire                                        alast_as;

  wire   [2:0]                                rs_ratio;
  wire   [BLW_RS-1:0]                         ds_fixed_len;
  wire                                        ds_fixed_decomp;

  wire   [A2X_A_PYLD_W-1:0]                   a_pyld_o_w;

  // **************************************************************************************
  // Decode of Write Address FIFO 
  // **************************************************************************************
  assign {abar_i, asnoop_i, adomain_i, aregion_i, aqos_i, hburst_type, asideband_i, aid_i, aaddr_i, aresize_i, alen_i, asize_i, 
  aburst_i, alock_i, acache_i, aprot_i} = a_pyld_i;

  // SP Port Length- Address Calculator Length
  assign alen_sp      = alen_ac;  

  // **************************************************************************************
  // SP Locked Control
  //
  // Enabled this Control if in Locked mode and 
  // - AHB Mode configuration
  // - AXI Upsizing configuration
  // - AXI Downsizing Configuration
  // - AXI Bufferable Mode. 
  // **************************************************************************************
  generate
    if ( (A2X_LOCKED==1) && ((A2X_PP_MODE==0) || (A2X_LOCKED==1) || (A2X_UPSIZE==1) || (A2X_DOWNSIZE==1) || (A2X_BRESP_MODE==0))) begin: LK
      i_axi_a2x_2_DW_axi_a2x_sp_add_lk
       #(
        .A2X_CHANNEL       (A2X_CHANNEL) 
       ,.A2X_PP_MODE       (A2X_PP_MODE) 
       ,.A2X_DOWNSIZE      (A2X_DOWNSIZE)
       ,.A2X_UPSIZE        (A2X_UPSIZE)
       ,.A2X_AW            (A2X_AW)
       ,.A2X_BLW           (A2X_BLW)
       ,.A2X_ASBW          (A2X_ASBW)
       ,.A2X_QOSW          (A2X_QOSW)
       ,.A2X_REGIONW       (A2X_REGIONW)
       ,.A2X_DOMAINW       (A2X_DOMAINW)
       ,.A2X_WSNOOPW       (A2X_WSNOOPW)
       ,.A2X_BARW          (A2X_BARW)
       ,.A2X_PYLD_I        (A2X_A_PYLD_W)
      ) U_sp_ad_lk (
        // Outputs
         .trans_en         (trans_en)
        ,.lock_req_o       (lock_req_o)
        ,.unlock_req_o     (unlock_req_o)
        ,.os_unlock        (os_unlock)
        ,.alock_o          (alock_o)
        ,.a_pyld_o         (a_pyld_lk)
        
        // Inputs
        ,.clk              (clk)
        ,.resetn           (resetn)
        ,.a_active         (a_active)
        ,.a_fifo_empty     (a_fifo_empty)
        ,.sp_os_fifo_valid (sp_os_fifo_valid)
        ,.lock_req_i       (lock_req_i)
        ,.lock_grant       (lock_grant)
        ,.unlock_req_i     (unlock_req_i)
        ,.unlock_grant     (unlock_grant)
        ,.lockseq_cmp      (lockseq_cmp)
        ,.a_ready_i        (a_ready_i)
        ,.lock_last        (alast_sp)
        ,.a_pyld_i         (a_pyld_i)
      );
    end else begin
      assign lock_req_o   = 1'b0;
      assign unlock_req_o = 1'b0; 
      assign trans_en     = 1'b1;
      assign os_unlock    = 1'b0;
      assign alock_o      = alock_i;
      assign a_pyld_lk    = a_pyld_i;
    end
  endgenerate

  // **************************************************************************************
  // SP Address Generator is active if a
  // - Wrap Transaction is converted to INCR or
  // - INCR/Fixed Transaction broken into multiple addresses
  // **************************************************************************************
  assign a_active = active_ac | active_as; 

  // Last Secondary Port Address Generated 
  assign alast_sp = alast_as; 

  // **************************************************************************************
  // Wrap Address Decode & 1K AHB Boundary Decode
  //
  // Convert AXI Wrap Transaction into AXI INCR's Transactions.
  // Checkes that the AHB INCR Transaction does not exceed the 1K Boundary. 
  // **************************************************************************************
  generate
  if (BYPASS_AS==0) begin: ASBLK
    i_axi_a2x_2_DW_axi_a2x_sp_add_split
     #(
       .A2X_CHANNEL        (A2X_CHANNEL) 
      ,.A2X_PP_MODE        (A2X_PP_MODE) 
      ,.A2X_AW             (A2X_AW)
      ,.A2X_BLW            (A2X_BLW)
      ,.BLW_AS             (BLW_AS)
      ,.A2X_PP_MAX_SIZE    (A2X_PP_MAX_SIZE)
      ,.A2X_ASBW           (A2X_ASBW)
      ,.A2X_QOSW           (A2X_QOSW)
      ,.A2X_REGIONW        (A2X_REGIONW)
      ,.A2X_DOMAINW        (A2X_DOMAINW)
      ,.A2X_WSNOOPW        (A2X_WSNOOPW)
      ,.A2X_BARW           (A2X_BARW)
      ,.A2X_PYLD_I         (A2X_A_PYLD_W)
      ,.A2X_PYLD_O         (A2X_AS_PYLD_W)
      ,.BYPASS_WS          (BYPASS_WS)
      ,.A2X_BRESP_MODE     (A2X_BRESP_MODE)
      ,.A2X_UPSIZE         (A2X_UPSIZE)
      ,.A2X_DOWNSIZE       (A2X_DOWNSIZE)
      ,.A2X_WSNF_PYLD_W    (A2X_WSNF_PYLD_W)
      ,.A2X_HINCR_HCBCNT   (A2X_HINCR_HCBCNT)
      ,.A2X_HINCR_MAX_BCNT (A2X_HINCR_MAX_BCNT) 
    ) U_sp_ad_as (
      // Outputs
       .pyld_o            (a_pyld_as)
      ,.active_as         (active_as)
      ,.alast_as          (alast_as)
      ,.onek_exceed       (onek_exceed)
      ,.ws_addr           (ws_addr)
      ,.ws_alen           (ws_alen)
      ,.ws_size           (ws_size)
      ,.ws_resize         (ws_resize)
      ,.ws_fixed          (ws_fixed)
      ,.wrap              (wrap)
      
      // Inputs 
      ,.clk               (clk)
      ,.resetn            (resetn)
      ,.a_fifo_empty      (a_fifo_empty)
      ,.sp_os_fifo_vld    (sp_os_fifo_valid)
      ,.a_ready_i         (a_ready_i)
      ,.active_ac         (active_ac)
      ,.pyld_i            (a_pyld_lk)
      ,.alast_ac          (alast_ac)
      ,.bypass_ws         (bypass_ws)
      ,.snf_pyld_i        (snf_pyld_w) 
      ,.trans_en          (trans_en)
    );

    assign snf_pyld_w = (buf_mode==`i_axi_a2x_2_SNF_MODE)? snf_pyld_i : 0; 
    // Last Address from Wrap Splitter
    assign ws_last  = (wrap)? alast_ac : 1'b0;
  end else begin
    assign a_pyld_as   = a_pyld_lk;
    assign active_as   = 1'b0;
    assign alast_as    = alast_ac;
    assign onek_exceed = 1'b0;
    assign ws_last     = 1'b1;
    assign ws_addr     = {A2X_AW{1'b0}};
    assign ws_alen     = {BLW_AS{1'b0}};
    assign ws_size     = asize_i;
    assign ws_resize   = {`i_axi_a2x_2_A2X_RSW{1'b0}};
    assign ws_fixed    = 1'b0;
  end
  endgenerate

  // **************************************************************************************
  // Address Resize 
  //
  // - Generates a new Length, Size and Burst Type.
  // **************************************************************************************
  generate
    if ((A2X_UPSIZE==1) || (A2X_DOWNSIZE==1)) begin: RS_BLK
      i_axi_a2x_2_DW_axi_a2x_sp_add_rs
       #(
         .A2X_PP_MODE           (A2X_PP_MODE)
        ,.A2X_CHANNEL           (A2X_CHANNEL) 
        ,.A2X_BLW               (A2X_BLW)
        ,.A2X_AW                (A2X_AW)
        ,.BLW_AS                (BLW_AS)
        ,.BLW_RS                (BLW_RS)
        ,.A2X_SP_MAX_SIZE       (A2X_SP_MAX_SIZE)
        ,.A2X_PP_MAX_SIZE       (A2X_PP_MAX_SIZE)
        ,.A2X_SP_NUM_BYTES_LOG2 (A2X_SP_NUM_BYTES_LOG2)
        ,.A2X_PP_NUM_BYTES_LOG2 (A2X_PP_NUM_BYTES_LOG2)
        ,.A2X_RS_RATIO_LOG2     (A2X_RS_RATIO_LOG2)
        ,.A2X_UPSIZE            (A2X_UPSIZE)
        ,.A2X_DOWNSIZE          (A2X_DOWNSIZE)
        ,.A2X_ASBW              (A2X_ASBW)
        ,.A2X_QOSW              (A2X_QOSW)
        ,.A2X_REGIONW           (A2X_REGIONW)
        ,.A2X_DOMAINW           (A2X_DOMAINW)
        ,.A2X_WSNOOPW           (A2X_WSNOOPW)
        ,.A2X_BARW              (A2X_BARW)
        ,.A2X_PYLD_I            (A2X_AS_PYLD_W)
        ,.A2X_PYLD_O            (A2X_AR_PYLD_W)
      ) U_sp_ad_rs (
        // Outputs
         .pyld_o            (a_pyld_rs)
        ,.rs_ratio          (rs_ratio)
        ,.ds_fixed_len      (ds_fixed_len)
        ,.ds_fixed_decomp   (ds_fixed_decomp)
        // Inputs 
        ,.pyld_i            (a_pyld_as)
        ,.onek_exceed       (onek_exceed)
      );
    end else begin
      assign a_pyld_rs        = a_pyld_as;
      assign rs_ratio         = 3'b001; 
      assign ds_fixed_len     = {BLW_RS{1'b0}}; 
      assign ds_fixed_decomp  = 1'b0;
    end
  endgenerate

  // **************************************************************************************
  // Address Calculator
  //
  // - Breaks each address down into the SP Address requirments. 
  // -  i.e. If Length < Maximum Length generate new address until PP last address reached.  
  // **************************************************************************************
  generate 
    if (BYPASS_AC==0) begin: AC_BLK
      i_axi_a2x_2_DW_axi_a2x_sp_add_calc
       #(
         .A2X_CHANNEL        (A2X_CHANNEL) 
        ,.A2X_PP_MODE        (A2X_PP_MODE) 
        ,.A2X_DOWNSIZE       (A2X_DOWNSIZE)
        ,.A2X_AW             (A2X_AW) 
        ,.A2X_BLW            (A2X_BLW) 
        ,.A2X_SP_MAX_SIZE    (A2X_SP_MAX_SIZE)
        ,.A2X_PP_MAX_SIZE    (A2X_PP_MAX_SIZE)
        ,.BLW_RS             (BLW_RS)
        ,.A2X_ASBW           (A2X_ASBW)
        ,.A2X_QOSW           (A2X_QOSW)
        ,.A2X_REGIONW        (A2X_REGIONW)
        ,.A2X_DOMAINW        (A2X_DOMAINW)
        ,.A2X_WSNOOPW        (A2X_WSNOOPW)
        ,.A2X_BARW           (A2X_BARW)
        ,.BOUNDARY_W         (BOUNDARY_W)
        ,.A2X_PYLD_I         (A2X_AR_PYLD_W)
        ,.A2X_PYLD_O         (A2X_A_PYLD_W)
        ,.A2X_WSNF_PYLD_W    (A2X_WSNF_PYLD_W)
      ) U_sp_ad_ac (
        // Outputs
         .active            (active_ac)
        ,.pyld_o            (a_pyld_o_w)
        ,.len_o             (alen_ac)
        ,.nxt_len_o         (nxt_alen_ac)
        ,.alast_o           (alast_ac)
        ,.w_snf_pop_en      (w_snf_pop_en)
        
        // Inputs 
        ,.clk               (clk)
        ,.resetn            (resetn)
        ,.max_len           (max_len)
        ,.rs_ratio          (rs_ratio)
        ,.asize_pp          (ws_size)
        ,.buf_mode          (buf_mode)
        ,.a_fifo_empty      (a_fifo_empty)
        ,.sp_os_fifo_vld    (sp_os_fifo_valid)
        ,.a_ready_i         (a_ready_i)
        ,.active_as         (active_as)
        ,.pyld_i            (a_pyld_rs)
        ,.snf_pyld_i        (snf_pyld_i)
        ,.ws_fixed          (ws_fixed)
        ,.ds_fixed_len      (ds_fixed_len)
        ,.ds_fixed_decomp   (ds_fixed_decomp)
        ,.trans_en          (trans_en)
      );
      if (A2X_LOCKED==1) begin: LK1
        assign a_pyld_o[A2X_A_PYLD_W-1:ALOCK_PYLD_FROM_BIT]      = a_pyld_o_w[A2X_A_PYLD_W-1:ALOCK_PYLD_FROM_BIT];
        assign a_pyld_o[ALOCK_PYLD_FROM_BIT-1:ALOCK_PYLD_TO_BIT] = alock_o;
        assign a_pyld_o[ALOCK_PYLD_TO_BIT-1:0]                   = a_pyld_o_w[ALOCK_PYLD_TO_BIT-1:0];
      end else begin
        assign a_pyld_o = a_pyld_o_w;
      end
    end else begin
      assign active_ac   = 1'b0;
      // alen bus width increased for resized configs and read INCR's. The
      // alen passed in to the AC block is the total sp length.
      assign alast_ac     = 1'b1; // always last address bit when bypassed
      assign alen_ac      = a_pyld_rs[ALEN_PYLD_FROM_BIT-1:ALEN_PYLD_TO_BIT];
      assign w_snf_pop_en = 1'b1; 

      if (A2X_LOCKED==1) begin: LK2
        assign a_pyld_o[A2X_A_PYLD_W-1:ALOCK_PYLD_FROM_BIT]      = a_pyld_rs[A2X_A_PYLD_W-1:ALOCK_PYLD_FROM_BIT];
        assign a_pyld_o[ALOCK_PYLD_FROM_BIT-1:ALOCK_PYLD_TO_BIT] = alock_o;
        assign a_pyld_o[ALOCK_PYLD_TO_BIT-1:0]                   = a_pyld_rs[ALOCK_PYLD_TO_BIT-1:0];
      end else begin
        assign a_pyld_o = a_pyld_rs;
      end
    end  
  endgenerate

endmodule 
//Revision: $Id: //dwh/DW_ocb/DW_axi_a2x/axi_dev_br/src/DW_axi_a2x_sp_add.v#15 $

