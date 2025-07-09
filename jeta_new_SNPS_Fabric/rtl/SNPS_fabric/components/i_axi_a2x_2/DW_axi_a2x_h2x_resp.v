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
// File Version     :        $Revision: #5 $ 
// Revision: $Id: //dwh/DW_ocb/DW_axi_a2x/axi_dev_br/src/DW_axi_a2x_h2x_resp.v#5 $ 
// --------------------------------------------------------------------
*/

`include "DW_axi_a2x_all_includes.vh"
//*************************************************************************************
// H2X Response
//  Generates the Registered Version of AHB Response
//*************************************************************************************
module i_axi_a2x_2_DW_axi_a2x_h2x_resp (/*AUTOARG*/
   // Outputs
   hsplit, hready_resp, hresp,    
   // Inputs
   clk, resetn, w_error_resp, w_split_resp,  
   r_error_resp, r_split_resp, r_hready_resp, 
   w_hready_resp, w_hsplit, r_hsplit
   );

  //*************************************************************************************
  // Parameter
  //*************************************************************************************
  parameter A2X_NUM_AHBM         = 1;
  parameter A2X_SPLIT_MODE       = 0; 

  //*************************************************************************************
  //I/O Decelaration
  //*************************************************************************************
  input                          clk;
  input                          resetn;

  input                          w_error_resp;    // AHB Write Responses
  //spyglass disable_block W240
  //SMD: An input has been declared but is not read.
  //SJ : These signals are used in specific config only 
  input                          w_split_resp;
  //spyglass enable_block W240

  input                          r_error_resp;    // AHB read Responses
  //spyglass disable_block W240
  //SMD: An input has been declared but is not read.
  //SJ : These signals are used in specific config only 
  input                          r_split_resp;
  //spyglass enable_block W240

  input                          r_hready_resp;   // Buffer Full Responses
  input                          w_hready_resp;

  //spyglass disable_block W240
  //SMD: An input has been declared but is not read.
  //SJ : These signals are used in specific config only 
  input  [A2X_NUM_AHBM-1:0]      w_hsplit;        // Split Recall 
  input  [A2X_NUM_AHBM-1:0]      r_hsplit;
  //spyglass enable_block W240

  output [15:0]                  hsplit;
  output                         hready_resp;
  output [`i_axi_a2x_2_A2X_HRESPW-1:0]       hresp; 


  //*************************************************************************************
  // Signal Decelaration
  //*************************************************************************************
  wire                           hready_w;
  reg                            hready_resp;
  reg    [`i_axi_a2x_2_A2X_HRESPW-1:0]       hresp;
  reg    [`i_axi_a2x_2_A2X_HRESPW-1:0]       hresp_w;
  reg    [A2X_NUM_AHBM-1:0]      hsplit_r;
  wire   [A2X_NUM_AHBM-1:0]      hsplit_w;

  wire                           split_resp_r;
  reg                            split_resp_r1;
  reg                            error_resp_r;
  wire                           split_resp_w;
  wire                           error_resp_w;

  //*************************************************************************************
  // Registered Version of Read/Write Response as hresp needs to be
  // driven low for two cycles
  //*************************************************************************************
  always @(posedge clk or negedge resetn) begin: resp_r_PROC
    if (resetn == 1'b0) begin
      split_resp_r1 <= 1'b0;
      error_resp_r <= 1'b0;
    end else begin  
      split_resp_r1 <= split_resp_w; 
      error_resp_r  <= error_resp_w;
    end
  end
  // Implemented on Q side of Flop for code coverage
  assign split_resp_r   = (A2X_SPLIT_MODE==0)? 1'b0 : split_resp_r1;

  assign split_resp_w   = (A2X_SPLIT_MODE==0)? 1'b0 : (w_split_resp | r_split_resp);
  assign error_resp_w   = (w_error_resp | r_error_resp);

  //*************************************************************************************
  // AHB Split Recall
  //************************************************************************************
  generate 
  if (A2X_SPLIT_MODE==1) begin: HSPLIT
    assign hsplit_w = w_hsplit | r_hsplit;
    
    always @(posedge clk or negedge resetn) begin: hsplit_PROC
      if (resetn == 1'b0) begin
        hsplit_r <=  {A2X_NUM_AHBM{1'b0}};
      end else begin
        hsplit_r <= hsplit_w; 
      end
    end
    
    // Constant condition expression
    // This module is used for in several instances and the value depends on the instantiation. 
    // Hence below usage cannot be avoided. This will not cause any funcational issue. 
    if (A2X_NUM_AHBM==16) begin
      assign hsplit[0]    = 1'b0;
      assign hsplit[15:1] = hsplit_r[15:1];
    end else begin
      assign hsplit[0] = 1'b0;
      assign hsplit[A2X_NUM_AHBM-1:1] = hsplit_r[A2X_NUM_AHBM-1:1];
      assign hsplit[15:A2X_NUM_AHBM]  = {(16-A2X_NUM_AHBM){1'b0}};
    end
  end else begin
    assign hsplit = 16'b0; 
  end
  endgenerate

  //*************************************************************************************
  // HREADY output  - Registered version of hready_w
  //
  // If in AHB Lite Mode Hready Driven low until AXI recalls the AHB Master.
  // If AW, AR or W channel cannot accept data drive hready low. 
  // Otherwise drive hready with  hready_w
  //*************************************************************************************
  assign hready_w = r_hready_resp & w_hready_resp;

  always @(posedge clk or negedge resetn) begin: hready_r_PROC
    if (resetn == 1'b0) begin
      hready_resp <=  1'b1;
    end else begin
      if (error_resp_w)
        hready_resp <=  1'b0;
      else if (split_resp_r || error_resp_r)
        hready_resp <=  1'b1;
      else
        hready_resp <= hready_w; 
    end
  end

  //*************************************************************************************
  // AHB Response
  //
  // Decodes the AHB response.
  // If hready asserted low on previous cycle drive AHB response with the
  // previous value. i.e. Keep error, retry and split for 2 cycles.
  //
  // If in AHB Lite Mode return OKAY Response 
  //*************************************************************************************
  always @(*) begin: hresp_PROC
    if (split_resp_w || split_resp_r)
      //spyglass disable_block W163
      //SMD: Truncation of bits in constant integer conversion.
      //SJ : 1-bit hresp_w is possible only in AHB Lite mode. Whereas AHB Lite does not support SPLIT/RETRY response, hence this loop will not be enetred. So truncation of bits in constant integer conversion will not happen.
      hresp_w = `i_axi_a2x_2_HRESP_SPLIT;
      // spyglass enable_block W163 
    else if (error_resp_w || error_resp_r)
      hresp_w =  `i_axi_a2x_2_HRESP_ERROR;
    else
      hresp_w = `i_axi_a2x_2_HRESP_OKAY;
  end  

  // Registered Version of HREADY Response
  always @(posedge clk or negedge resetn) begin: hresp_r_PROC
    if (resetn == 1'b0) begin
      hresp <= `i_axi_a2x_2_HRESP_OKAY;
    end else begin
      hresp <= hresp_w;
    end
  end


endmodule
