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
// Revision: $Id: //dwh/DW_ocb/DW_axi_a2x/axi_dev_br/src/DW_axi_a2x_lp.v#9 $ 
**
** --------------------------------------------------------------------
**
** File     : DW_axi_a2x_lp.v
** Created  : 
** Abstract :
**
** --------------------------------------------------------------------
*/
`include "DW_axi_a2x_all_includes.vh"
module i_axi_a2x_2_DW_axi_a2x_lp (/*AUTOARG*/
   // Outputs
   cactive, 
                      csysack, 
                      lp_mode, 
                      // Inputs
                      clk_pp, 
                      resetn_pp, 
                      active_trans, 
                      csysreq, 
                      awvalid,
                      arvalid, 
                      wvalid, 
                      hsel
                      );
  
  // -------------------------------------------------------------------
  // Parameters
  // -------------------------------------------------------------------

  parameter [7:0] LOWPWR_NOPX_CNT   = 0;
  
  // -------------------------------------------------------------------
  // I/O Decelaration
  // -------------------------------------------------------------------
  
  // Global signals  
  input                          clk_pp;         // clock 
  input                          resetn_pp;      // asynchronous reset 
  
  input                          active_trans; // active transaction  
  input                          csysreq;      // low power request 

  input                          awvalid;      // AXI AW Channel
  input                          arvalid;      // AXI AR Channel
  input                          wvalid;       // AXI W Channel
  //spyglass disable_block W240
  //SMD: An input has been declared but is not read.
  //SJ : Input hsel is read only when A2X_PP_MODE = 0.
  input                          hsel;         // AHB Select
  //spyglass enable_block W240
  output                         cactive;      // low power clock active 
  output                         csysack;      // low power acknowledge 
  
  output                         lp_mode; 

  //*********************************************************************************
  // Signal Decelaration
  //*********************************************************************************
  wire                           csysreq_fed;
  wire                           csysack_fed;
  wire                           csysreq_red;

  reg                            csysreq_d;
  reg                            csysack_d;

  reg  [7:0]                     nopx_cnt;
  wire                           nopx_zero;

  reg                            csysack_r;
  wire                           axi_active;
  wire                           ahb_active;

  reg                            lp_mode; 

  //*********************************************************************************
  // Rising and Falling Edge Detection Primary Port 
  //*********************************************************************************
  always@(posedge clk_pp or negedge resetn_pp) begin : edp_PROC
    if(~resetn_pp)  begin
      csysreq_d       <= 1'b1;
      csysack_d       <= 1'b1;
    end else begin
      csysreq_d       <= csysreq;
      csysack_d       <= csysack_r;
    end
  end  
  
  // Falling Edge Detect
  assign csysreq_fed        = ~csysreq       & csysreq_d;
  assign csysack_fed        = ~csysack_r     & csysack_d;

  // Rising Edge Detect
  assign csysreq_red        = ~csysreq_d     & csysreq;

  //*********************************************************************************
  // Low Power Mode
  //*********************************************************************************
  always@(posedge clk_pp or negedge resetn_pp) begin : lpmode_PROC
    if (~resetn_pp)
      lp_mode <= 1'b0;
    else begin
      if (csysreq_fed && (~(axi_active | ahb_active | active_trans)))
        lp_mode <= 1'b1;
      else if ((csysack_fed && cactive) || (csysreq && csysack))
        lp_mode <= 1'b0;
    end
  end
    
  //*********************************************************************************
  // Low Power Nopx count
  //*********************************************************************************
    always@(posedge clk_pp or negedge resetn_pp) begin : nopx_cnt_PROC
      if (~resetn_pp)
        nopx_cnt <= 8'b0;
      else begin  
        if (active_trans)
          nopx_cnt <= LOWPWR_NOPX_CNT;
        else if ((~active_trans) && (~nopx_zero))
          nopx_cnt <= nopx_cnt-1;
      end
    end
    assign nopx_zero =  ~(|nopx_cnt);

  //*********************************************************************************
  //Low Power CACTIVE
  //*********************************************************************************
  assign cactive = (axi_active | ahb_active | active_trans) ? 1'b1: ~nopx_zero;
  
  assign  axi_active = (awvalid | wvalid | arvalid);
  assign  ahb_active = 1'b0;

  always@(posedge clk_pp or negedge resetn_pp)
  begin : csysack_PROC
    if (~resetn_pp) begin
      csysack_r <= 1'b1;
    end else begin
      csysack_r <= csysreq;
    end
  end

  assign csysack = csysack_r;

 endmodule
//Revision: $Id: //dwh/DW_ocb/DW_axi_a2x/axi_dev_br/src/DW_axi_a2x_lp.v#9 $ 
