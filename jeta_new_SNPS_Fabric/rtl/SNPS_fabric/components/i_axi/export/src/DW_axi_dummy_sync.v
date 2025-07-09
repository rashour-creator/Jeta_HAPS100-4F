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
// File Version     :        $Revision: #4 $ 
// Revision: $Id: //dwh/DW_ocb/DW_axi/axi_dev_br/src/DW_axi_dummy_sync.v#4 $ 
**
** ---------------------------------------------------------------------
**
** File     : DW_axi_dummy_sync.v
//
//
** Created  : Thu Nov 17 13:27:47 MEST 2011
** Modified : $Date: 2021/07/21 $
** Abstract : Dummy module kept for CDC check purpose.
**            This module list all the signals corssing clock domain.
**            All the CDC signals are qualified by a qualifier (handshake mechanism)
**            hence synchronization is not required.
** ---------------------------------------------------------------------
*/

`include "DW_axi_all_includes.vh"

module i_axi_DW_axi_dummy_sync (
     aclk,
     aresetn,
     pclk,
     presetn,
     data_reg_in_aclk,
     data_reg_o_pclk,
     qos_reg_wen_pclk,
     qos_reg_rdn_pclk,
     qos_reg_offset_pclk,
     data_reg_in_pclk,
     data_reg_o_aclk,
     qos_reg_wen_aclk,
     qos_reg_rdn_aclk,
     qos_reg_offset_aclk,
     internal_reg_rst_pclk,
     internal_reg_rst_aclk
     );
   // spyglass disable_block W240
   // SMD: A signal or variable is set but never read
   // SJ: This warning can be ignored.
   //----------------------------------------------------
   //---Port declaraion-----------------
   //------------------------------------------------------
    input             aclk;
    input             aresetn;    
    input             pclk;
    input             presetn;    
    input  [31:0]     data_reg_in_aclk; // data reg 
    input  [31:0]     data_reg_o_pclk; 
    input             qos_reg_wen_pclk; 
    input             qos_reg_rdn_pclk; 
    input  [7:0]      qos_reg_offset_pclk;
    input             internal_reg_rst_pclk;
    output            internal_reg_rst_aclk;
    output [31:0]     data_reg_o_aclk; 
    output            qos_reg_wen_aclk; // qos register write enable 
    output            qos_reg_rdn_aclk;  // qos register read enable
    output [7:0]      qos_reg_offset_aclk; // qos registers offset
    output [31:0]     data_reg_in_pclk; 
   // spyglass enable_block W240
   // ----------------------------------------------------------
   // -- local registers and wires
   // ----------------------------------------------------------
   //
     wire [31:0]                      data_reg_o_pclk; 
     wire                             qos_reg_wen_pclk; 
     wire [7:0]                       qos_reg_offset_pclk; 
     wire [31:0]                      data_reg_in_aclk; 
     
     i_axi_DW_axi_bcm36_nhs
      # (
       .WIDTH         (32),
       .DATA_DELAY    (3)
      ) U_DW_axi_bcm36_nhs_data_reg_o_pclk_dummy (
       `ifndef SYNTHESIS
        .clk_d    (aclk),
        .rst_d_n  (aresetn),
       `endif
       .data_s    (data_reg_o_pclk) ,
       .data_d    (data_reg_o_aclk)
     );  



     i_axi_DW_axi_bcm36_nhs
      # (
       .WIDTH         (1),
       .DATA_DELAY    (3)
      ) U_DW_axi_bcm36_nhs_qos_reg_wen_pclk_dummy (
       `ifndef SYNTHESIS
        .clk_d    (aclk),
        .rst_d_n  (aresetn),
       `endif
       .data_s    (qos_reg_wen_pclk) ,
       .data_d    (qos_reg_wen_aclk)
     );
 
     i_axi_DW_axi_bcm36_nhs
      # (
       .WIDTH         (1),
       .DATA_DELAY    (3)
      ) U_DW_axi_bcm36_nhs_qos_reg_rdn_pclk_dummy (
       `ifndef SYNTHESIS
        .clk_d    (aclk),
        .rst_d_n  (aresetn),
       `endif
       .data_s   (qos_reg_rdn_pclk) ,
       .data_d   (qos_reg_rdn_aclk)
     ); 
          
     i_axi_DW_axi_bcm36_nhs
      # (
       .WIDTH         (8),
       .DATA_DELAY    (3)
      ) U_DW_axi_bcm36_nhs_qos_reg_offset_pclk_dummy (
       `ifndef SYNTHESIS
        .clk_d    (aclk),
        .rst_d_n  (aresetn),
       `endif
       .data_s   (qos_reg_offset_pclk) ,
       .data_d   (qos_reg_offset_aclk)
     );  

    i_axi_DW_axi_bcm36_nhs
     # (
       .WIDTH         (32),
       .DATA_DELAY    (3)
      ) U_DW_axi_bcm36_nhs_data_reg_in_aclk_dummy (
       `ifndef SYNTHESIS
        .clk_d    (pclk               ),
        .rst_d_n  (presetn            ),
       `endif
       .data_s    (data_reg_in_aclk) ,
       .data_d    (data_reg_in_pclk)
     ); 

    i_axi_DW_axi_bcm36_nhs
     # (
       .WIDTH         (1),
       .DATA_DELAY    (3)
      ) U_DW_axi_bcm36_nhs_internal_reg_rst_dummy (
       `ifndef SYNTHESIS
        .clk_d    (aclk               ),
        .rst_d_n  (aresetn            ),
       `endif
       .data_s    ( internal_reg_rst_pclk) ,
       .data_d    ( internal_reg_rst_aclk)
     ); 
              
  endmodule
