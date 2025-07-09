/* ---------------------------------------------------------------------
**
// ------------------------------------------------------------------------------
// 
// Copyright 2001 - 2023 Synopsys, INC.
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
// Component Name   : DW_axi
// Component Version: 4.06a
// Release Type     : GA
// Build ID         : 18.26.9.4
// ------------------------------------------------------------------------------

// 
// Release version :  4.06a
// File Version     :        $Revision: #5 $ 
// Revision: $Id: //dwh/DW_ocb/DW_axi/axi_dev_br/src/DW_axi_lp.v#5 $ 
**
** ---------------------------------------------------------------------
**
** File     : DW_axi_lp.v
//
//
** Created  : Tue May 11 15:54:00 MEST 2010
** Modified : $Date: 2022/10/31 $
** Abstract : The purpose of this block is to implementn low power
**            interface compliant with axi protocol.
**
** ---------------------------------------------------------------------
*/
`include "DW_axi_all_includes.vh"
module i_axi_DW_axi_lp (
  aclk_i,
  aresetn_i,
  awpendtrans_i,
  arpendtrans_i,
  awvalid_m_i,
  arvalid_m_i,

  csysreq_i,
  csysack_o,
  cactive_o,
  ready_en_o,
  active_trans_o
  
);

  input      aclk_i;                                // AXI system clock
  input      aresetn_i;                             // AXI system reset

  input      [`i_axi_AXI_NUM_MASTERS-1:0] awpendtrans_i;  // Number of pending transitions on write address channel of all Masters
  input      [`i_axi_AXI_NUM_MASTERS-1:0] arpendtrans_i;  // Number of pending transitions on read address channel of all Masters

  input      [`i_axi_AXI_NUM_MASTERS-1:0] awvalid_m_i;    // Masters awvalid bus
  input      [`i_axi_AXI_NUM_MASTERS-1:0] arvalid_m_i;    // Masters arvalid_m bus

  input      csysreq_i;                             // System low-power request
  output     csysack_o;                             // Low-power request acknowledgement
  output     cactive_o;                             // Clock active
  output     ready_en_o;                            // Ready enable
  output     active_trans_o;                        // Active Transfer debug signal

  wire       cactive_o;
  wire       csysack_o;

  wire       active_trans_o;

  wire       ready_en_o;

  assign active_trans_o = (|awpendtrans_i) | (|arpendtrans_i) | (|awvalid_m_i) | (|arvalid_m_i) ;



  i_axi_DW_axi_lpfsm
   #(
    `i_axi_AXI_LOWPWR_NOPX_CNT,
    `i_axi_AXI_LOG2_LOWPWR_NOPX_CNT
  )
  U_DW_axi_lpfsm (
     // Inputs
     .aclk         (aclk_i),
     .aresetn      (aresetn_i),
     .active_trans (active_trans_o),
     .csysreq      (csysreq_i),

     // Outputs
     .cactive      (cactive_o),
     .csysack      (csysack_o),
     .ready        (ready_en_o)
  );


endmodule
