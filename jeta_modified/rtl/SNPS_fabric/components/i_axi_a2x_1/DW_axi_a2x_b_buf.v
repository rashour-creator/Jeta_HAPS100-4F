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
// File Version     :        $Revision: #4 $ 
// Revision: $Id: //dwh/DW_ocb/DW_axi_a2x/amba_dev/src/DW_axi_a2x_b_buf.v#4 $ 
**
** --------------------------------------------------------------------
*/
//*************************************************************************************
// Bufferable Only Response
//
// 
//            |----------|        
//  PP B CH   | Response |       
// <----------|   FIFO   |<-|
//       |--->|          |  |    
//       |    |----------|  |    
//       |                  |      
//   |-----|             |------|  
//   | Pop |             | Push |  
//   |-----|             |------|  
//                          ^      
//                          | wlast_pp
//
// AXI Bufferable Response Mode
//  - Returns Response to PP AXI Channel when write last detected on Primary
//    Port. 
//*************************************************************************************

`include "DW_axi_a2x_all_includes.vh"

module i_axi_a2x_1_DW_axi_a2x_b_buf (/*AUTOARG*/
   // Outputs
   bvalid_o, fifo_full, b_pyld_o,
   // Inputs
   clk, resetn, wlast_i, wvalid_i, wready_i, wid_i, bready_i,
   pp_rst_n, sp_rst_n
   );

  //*************************************************************************************
  // Parameter Decelaration
  //*************************************************************************************
  parameter  BRESP_FIFO_DEPTH                = 4;
  parameter  BRESP_FIFO_DEPTH_LOG2           = 2;
  parameter  A2X_BSBW                        = 1; 

  localparam A2X_IDW                         = `A2X_IDW;
  localparam A2X_BRESPW                      = `A2X_BRESPW;

  localparam DUAL_CLK                        = 0;  // Synchronous Clock Mode

  localparam BRESP_PYLD_W                    = A2X_BSBW + A2X_IDW + A2X_BRESPW;
  localparam FIFO_PYLD_W                     = A2X_IDW;

  //*************************************************************************************
  // I/O Decelaration
  //*************************************************************************************
  //spyglass disable_block W240
  //SMD: An input has been declared but is not read.
  //SJ : This input is used in specific config only 
  input                                      clk;
  input                                      resetn;

  input                                      wlast_i;
  input                                      wvalid_i;
  input                                      wready_i;
  input  [A2X_IDW-1:0]                       wid_i; 

  input                                      bready_i;
  //These nets are used to connect the logic under certain configuration.
  //But this may not drive some of the nets. This will not cause any functional issue.
  output                                     bvalid_o;

  output                                     fifo_full;
  output [BRESP_PYLD_W-1:0]                  b_pyld_o;

  input                                      pp_rst_n;
  input                                      sp_rst_n; 
  //spyglass enable_block W240

  //*************************************************************************************
  // Signal Decelaration
  //*************************************************************************************
  wire                                       fifo_push_n;
  wire                                       fifo_pop_n;
  wire                                       fifo_empty;
  wire   [FIFO_PYLD_W-1:0]                   fifo_pyld_i;
  wire   [FIFO_PYLD_W-1:0]                   fifo_pyld_o;

  //These nets are used to connect the logic under certain configuration.
  //But this may not drive any net in some other configuration. 
  wire   [BRESP_FIFO_DEPTH_LOG2:0]           fifo_pop_count;
  wire   [BRESP_FIFO_DEPTH_LOG2:0]           fifo_push_count;
  wire                                       unconn_1;

  wire   [A2X_IDW-1:0]                       bid_o;    
  wire   [A2X_BRESPW-1:0]                    bresp_o;
  wire   [A2X_BSBW-1:0]                      bsideband_o;

  //*************************************************************************************
  // Bufferable Response Channel FIFO 
  //*************************************************************************************
  i_axi_a2x_1_DW_axi_a2x_fifo
   #(
     .DUAL_CLK                               (DUAL_CLK)
    ,.DATA_W                                 (FIFO_PYLD_W)
    ,.DEPTH                                  (BRESP_FIFO_DEPTH)
    ,.LOG2_DEPTH                             (BRESP_FIFO_DEPTH_LOG2)
  ) U_a2x_b_fifo (
     .clk_push_i                             (clk)
    ,.resetn_push_i                          (resetn)
    ,.push_req_n_i                           (fifo_push_n)
    ,.data_i                                 (fifo_pyld_i)
    ,.push_full_o                            (fifo_full)
    ,.push_empty_o                           (unconn_1)
    ,.clk_pop_i                              (clk)
    ,.resetn_pop_i                           (resetn)
    ,.pop_req_n_i                            (fifo_pop_n)
    ,.pop_empty_o                            (fifo_empty)
    ,.data_o                                 (fifo_pyld_o)    
    ,.push_count                             (fifo_push_count)
    ,.pop_count                              (fifo_pop_count)
    ,.push_rst_n                             (pp_rst_n)
    ,.pop_rst_n                              (pp_rst_n)
  );

  // FIFO  Control
  // Push when write last detected on Primary Port. 
  assign fifo_push_n  = !(wvalid_i & wlast_i & wready_i);

  // Pop when PP B Channel active
  assign fifo_pop_n   = !(bready_i & bvalid_o);

  // Push Write ID into FIFO and return on B Channel. 
  assign fifo_pyld_i  = {wid_i};

  //*************************************************************************************
  // Primary Port Burst Response Channel
  //*************************************************************************************
  // Return OK Response
  assign bresp_o     = `AOKAY;
  // Return Write ID 
  assign bid_o       = fifo_pyld_o;
  // B sideband not required in this mode so return 0's. 
  assign bsideband_o = {A2X_BSBW{1'b0}};

  // PP B Channel valid when FIFO not empty
  assign bvalid_o    = !fifo_empty;

  // PP B Channel Payload
  assign b_pyld_o   = {bsideband_o, bid_o, bresp_o};

endmodule

