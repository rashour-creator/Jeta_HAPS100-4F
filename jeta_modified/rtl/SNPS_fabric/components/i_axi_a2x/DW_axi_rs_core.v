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
// File Version     :        $Revision: #10 $ 
// Revision: $Id: //dwh/DW_ocb/DW_axi_a2x/amba_dev/src/DW_axi_rs_core.v#10 $ 
**
** --------------------------------------------------------------------
**
** File     : DW_axi_a2x_rs_core.v
** Created  : Thu Jan 27 11:01:40 MET 2011
** Abstract :
**-----------------------------------------------------------------------------------------------------------------*/
`include "DW_axi_a2x_all_includes.vh"

module i_axi_a2x_DW_axi_rs_core (/*AUTOARG*/
   // Outputs
   awready_p, awvalid_s, aw_pyld_s, wready_p, wvalid_s, w_pyld_s, 
   bvalid_p, b_pyld_p, bready_s, arready_p, arvalid_s, ar_pyld_s, 
   rvalid_p, r_pyld_p, rvalid_s, 
   // Inputs
   aclk, 
   aresetn, 
   awvalid_p, aw_pyld_p, awready_s, wvalid_p, 
   w_pyld_p, wready_s, bready_p, bvalid_s, b_pyld_s, arvalid_p, 
   ar_pyld_p, arready_s, rready_p, rready_s, r_pyld_s
   );

//******************************************************************************
// Parameters
//******************************************************************************
  parameter  RS_AW_TMO   = 0;
  parameter  RS_AW_PLD_W = 32;
  parameter  RS_AR_TMO   = 0;
  parameter  RS_AR_PLD_W = 32;
  parameter  RS_B_TMO    = 0;
  parameter  RS_B_PLD_W  = 32;
  parameter  RS_W_TMO    = 0;
  parameter  RS_W_PLD_W  = 32;
  parameter  RS_R_TMO    = 0;
  parameter  RS_R_PLD_W  = 32;

//******************************************************************************
// I/O Decelaration
//******************************************************************************
  // Global
  //spyglass disable_block W240
  //SMD: An input has been declared but is not read.
  //SJ : aclk and aresetn are read only when RS_AW_TMO !=0 or RS_AR_TMO != 0.
  input                                        aclk;
  input                                        aresetn;
  //spyglass enable_block W240

  input                                        awvalid_p;
  output                                       awready_p;
  input  [RS_AW_PLD_W-1:0]                     aw_pyld_p;

  output                                       awvalid_s;
  input                                        awready_s; 
  output [RS_AW_PLD_W-1:0]                     aw_pyld_s;

  input                                        wvalid_p; 
  output                                       wready_p;
  input  [RS_W_PLD_W-1:0]                      w_pyld_p;

  output                                       wvalid_s; 
  input                                        wready_s;
  output [RS_W_PLD_W-1:0]                      w_pyld_s;

  output                                       bvalid_p; 
  input                                        bready_p;
  output [RS_B_PLD_W-1:0]                      b_pyld_p;

  input                                        bvalid_s; 
  output                                       bready_s;
  input  [RS_B_PLD_W-1:0]                      b_pyld_s;

  input                                        arvalid_p;
  output                                       arready_p;
  input  [RS_AR_PLD_W-1:0]                     ar_pyld_p;

  output                                       arvalid_s;
  input                                        arready_s; 
  output [RS_AR_PLD_W-1:0]                     ar_pyld_s;
 
  output                                       rvalid_p;
  input                                        rready_p; 
  output [RS_R_PLD_W-1:0]                      r_pyld_p;

  input                                        rvalid_s;
  output                                       rready_s; 
  input  [RS_R_PLD_W-1:0]                      r_pyld_s;

//******************************************************************************
//instantiate DW_axi_tpi for write address channel
//******************************************************************************
generate
if (RS_AW_TMO!=0) begin: BYPAW
  i_axi_a2x_DW_axi_rs_tpi
   #(
    .TMO             (RS_AW_TMO)
   ,.PLD_W           (RS_AW_PLD_W)
  ) U_aw_tpi (
    //input signals
    .aclk_i           ( aclk),
    .aresetn_i        ( aresetn),
    .valid_i          ( awvalid_p),
    .ready_i          ( awready_s),
    .payload_i        ( aw_pyld_p),
    
    //output signals
    .valid_o          ( awvalid_s),
    .ready_o          ( awready_p),
    .payload_o        ( aw_pyld_s)
  );
end else begin
  assign awvalid_s = awvalid_p;
  assign awready_p = awready_s;
  assign aw_pyld_s = aw_pyld_p;
end
endgenerate

//******************************************************************************
//instantiate DW_axi_tpi for read address channel
//******************************************************************************
generate
if (RS_AR_TMO!=0) begin: BYPAR
  i_axi_a2x_DW_axi_rs_tpi
   #(
    .TMO             (RS_AR_TMO)
   ,.PLD_W           (RS_AR_PLD_W)
 ) U_ar_tpi (
   //input signals
   .aclk_i           ( aclk),
   .aresetn_i        ( aresetn),
   .valid_i          ( arvalid_p),
   .ready_i          ( arready_s),
   .payload_i        ( ar_pyld_p),
   
   //output signals
   .valid_o          ( arvalid_s),
   .ready_o          ( arready_p),
   .payload_o        ( ar_pyld_s)
 );
end else begin
  assign arvalid_s = arvalid_p;
  assign arready_p = arready_s;
  assign ar_pyld_s = ar_pyld_p;
end
endgenerate

//******************************************************************************
//instantiate DW_axi_tpi for write data channel
//******************************************************************************
generate
if (RS_W_TMO!=0) begin: BYPW
  i_axi_a2x_DW_axi_rs_tpi
   #(
    .TMO             (RS_W_TMO)
   ,.PLD_W           (RS_W_PLD_W)
  ) U_w_tpi (
    //input signals
    .aclk_i           ( aclk),
    .aresetn_i        ( aresetn),
    .valid_i          ( wvalid_p),
    .ready_i          ( wready_s),
    .payload_i        ( w_pyld_p),
  
    //output signals
    .valid_o          ( wvalid_s),
    .ready_o          ( wready_p),
    .payload_o        ( w_pyld_s)
    );
end else begin
  assign wvalid_s = wvalid_p;
  assign wready_p = wready_s;
  assign w_pyld_s = w_pyld_p;
end
endgenerate

//******************************************************************************
//instantiate DW_axi_tpi for read data channel
//******************************************************************************
generate
if (RS_R_TMO!=0) begin: BYPR
  i_axi_a2x_DW_axi_rs_tpi
   #(
     .TMO             (RS_R_TMO)
    ,.PLD_W           (RS_R_PLD_W)
  ) U_r_tpi (
    //input signals
    .aclk_i           ( aclk),
    .aresetn_i        ( aresetn),
    .valid_i          ( rvalid_s),
    .ready_i          ( rready_p),
    .payload_i        ( r_pyld_s),
  
    //output signals
    .valid_o          ( rvalid_p),
    .ready_o          ( rready_s),
    .payload_o        ( r_pyld_p)
    );
end else begin
  assign rvalid_p = rvalid_s;
  assign rready_s = rready_p;
  assign r_pyld_p = r_pyld_s;
end
endgenerate
//******************************************************************************
//instantiate DW_axi_tpi for write response channel
//******************************************************************************
generate
if (RS_R_TMO!=0) begin: BYPB
  i_axi_a2x_DW_axi_rs_tpi
   #(
     .TMO             (RS_B_TMO)
    ,.PLD_W           (RS_B_PLD_W)
  ) U_b_tpi (
    //input signals
    .aclk_i           ( aclk),
    .aresetn_i        ( aresetn),
    .valid_i          ( bvalid_s),
    .ready_i          ( bready_p),
    .payload_i        ( b_pyld_s),
  
    //output signals
    .valid_o          ( bvalid_p),
    .ready_o          ( bready_s),
    .payload_o        ( b_pyld_p)
    );
end else begin
  assign bvalid_p = bvalid_s;
  assign bready_s = bready_p;
  assign b_pyld_p = b_pyld_s;
end
endgenerate


endmodule
//Revision: $Id: //dwh/DW_ocb/DW_axi_a2x/amba_dev/src/DW_axi_rs_core.v#10 $
