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
// File Version     :        $Revision: #24 $ 
// Revision: $Id: //dwh/DW_ocb/DW_axi_a2x/amba_dev/src/DW_axi_a2x_lp.v#24 $ 
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
module i_axi_a2x_DW_axi_a2x_lp (/*AUTOARG*/
   // Outputs
   cactive, 
                      csysack, 
                      pp_rst_n, 
                      sp_rst_n, 
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
  parameter [7:0] LOWPWR_RST_CNT    = 2;
  
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
  
  output                         pp_rst_n;
  output                         lp_mode; 
  output                         sp_rst_n;

  //*********************************************************************************
  // Signal Decelaration
  //*********************************************************************************
  wire                           csysreq_fed;
  wire                           csysack_fed;
  wire                           rst_seq_cmp_red;
  wire                           csysreq_red;

  reg                            csysreq_d;
  reg                            csysack_d;
  reg                            rst_seq_cmp_d;

  wire                           nopx_zero;

  reg                            csysack_r;
  wire                           axi_active;
  wire                           ahb_active;

  reg                            pp_rst_n;
  reg  [7:0]                     pp_rst_cnt;
  wire                           pp_rst_cnt_zero;
  wire                           rst_seq_cmp;

  wire                           sp_rst_n;

  wire                           sp_rst_cmp;

  reg                            lp_mode; 

  // Lint flags this rule when any signal in the cross over path has more than one fanout or any object 
  // in the cross over path has more than one output. 
  // Both pp_tog and sp_tog are driven into the respective synchroniser and also used in there own clock 
  // domain. This lint rule can be ignored here since the un-synchronised version is not used in the other 
  // target clock domain. 

  //*********************************************************************************
  // Rising and Falling Edge Detection Primary Port 
  //*********************************************************************************
  always@(posedge clk_pp or negedge resetn_pp) begin : edp_PROC
    if(~resetn_pp)  begin
      csysreq_d       <= 1'b1;
      csysack_d       <= 1'b1;
      rst_seq_cmp_d   <= 1'b0;
    end else begin
      csysreq_d       <= csysreq;
      csysack_d       <= csysack_r;
      rst_seq_cmp_d   <= rst_seq_cmp;
    end
  end  
  
  // Falling Edge Detect
  assign csysreq_fed        = ~csysreq       & csysreq_d;
  assign csysack_fed        = ~csysack_r     & csysack_d;

  // Rising Edge Detect
  assign csysreq_red        = ~csysreq_d     & csysreq;
  assign rst_seq_cmp_red    = ~rst_seq_cmp_d & rst_seq_cmp;

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
    assign nopx_zero =  ~active_trans;

  //*********************************************************************************
  //Low Power CACTIVE
  //*********************************************************************************
  assign cactive = (axi_active | ahb_active | active_trans) ? 1'b1: ~nopx_zero;
  
  //*********************************************************************************
  // Low Power Acknowledge
  // - Request Entry - Wait for Reset Sequence to Complete and ACK
  // - Request Entry - Reject Request and ACK Imediately.
  // - Request Exit
  //*********************************************************************************
  assign  axi_active = (awvalid | wvalid | arvalid);
  assign  ahb_active = 1'b0;

  always@(posedge clk_pp or negedge resetn_pp)
  begin : csysack_PROC
    if (~resetn_pp) begin
      csysack_r <= 1'b1;
    end else begin
      if ((csysreq_fed && (active_trans || axi_active ||  ahb_active)))
        csysack_r <= 1'b0;
      else if ((~csysreq) && rst_seq_cmp_red)
        csysack_r <= 1'b0;
      else if (csysreq_red)
        csysack_r <= 1'b1;
    end
  end

  assign csysack = csysack_r;

  //*********************************************************************************
  // Primary Port Synchronous Reset.
  //*********************************************************************************
  always@(posedge clk_pp or negedge resetn_pp)
  begin : sync_rst_PROC
    if (~resetn_pp) begin
      pp_rst_n <= 1'b1;
    end else begin
      if (csysreq_fed && (~(active_trans || axi_active ||  ahb_active)))
        pp_rst_n <= 1'b0;
      else if (pp_rst_cnt_zero && sp_rst_cmp) 
        pp_rst_n <= 1'b1;
    end
  end

  assign rst_seq_cmp = sp_rst_cmp & pp_rst_n;

  //*********************************************************************************
  // Primary Port synchronous Reset counter.
  // - Hold the sync_rst_pp low for a defined number of clock cycles. 
  //*********************************************************************************
  always@(posedge clk_pp or negedge resetn_pp) begin: pp_rst_cnt_PROC
    if (~resetn_pp)
      pp_rst_cnt <= 8'b0;
    else begin
      if (csysreq_fed && (~(active_trans || axi_active ||  ahb_active)))
        pp_rst_cnt <= LOWPWR_RST_CNT;
      else if (~pp_rst_cnt_zero)
        pp_rst_cnt <= pp_rst_cnt-1;
    end
  end

  assign pp_rst_cnt_zero = ~(|pp_rst_cnt);

  //*********************************************************************************
  // Secondary Port Reset Sequence
  //*********************************************************************************

    //*********************************************************************************
    // Synchronize the primary Port Toggle to SP Clock Domain - U_pp_rst_sync
    //*********************************************************************************


  
  // U_sp_rst_sync



    assign sp_rst_cmp = 1'b1;
    assign sp_rst_n   = pp_rst_n; 

 endmodule
//Revision: $Id: //dwh/DW_ocb/DW_axi_a2x/amba_dev/src/DW_axi_a2x_lp.v#24 $
