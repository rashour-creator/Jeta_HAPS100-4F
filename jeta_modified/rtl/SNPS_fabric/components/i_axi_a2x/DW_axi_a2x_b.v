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
// File Version     :        $Revision: #69 $ 
// Revision: $Id: //dwh/DW_ocb/DW_axi_a2x/amba_dev/src/DW_axi_a2x_b.v#69 $ 
**
** --------------------------------------------------------------------
**
** File     : DW_axi_a2x_b.v
** Created  : Thu Jan 27 11:01:40 MET 2011
** Abstract :
**
** --------------------------------------------------------------------
*/

/*-------------------------------------------------------------------------------
**                  Response Channel Architecture Diagram
**-------------------------------------------------------------------------------
**
**                 /|            |-------------|
**                | |<-----------|    Dynamic  |<-----|
**                | |            |-------------|      |  SP B Channel
**   PP B Channel | |                                 |----------------
** <--------------| |            |-------------|      |
**                | |<-----------|  Bufferable |<-----|
**                | |            |-------------| 
**                 \|     
**
** The A2X Offers two modes of operation:
**
** Bufferable Mode with AXI Configuration
**  - This mode only returns bufferable responses from the A2X. All Non-Bufferable requests
**    are ignored and treated as bufferable requests. 
**
** Bufferable Mode with AHN Configuration
**  - The A2X's a2x_h2x module is responsible for generating the responses to the AHB. 
**    The a2x_b module channel is not required.
**
** Dynamic Mode with AXI Configuration
**  - In this mode the A2X does not issue any bufferable response and replies on the SP Channel to 
**    return reposnses for both bufferable and non-bufferable transactions. These response are then 
**    returned to the Primary Port.
**
**  - For the A2X to return bufferable responses along with non-bufferable responses the A2X would 
**    have to maintain the order of the responses for each Write ID. i.e. a bufferable response cannot 
**    be returned before a non-bufferable response. Consider a series of write transactions BW1, NB-W, BW2
**    BW2 cannot be returned before NB-W. 
**    BW   - bufferable Write
**    NB-W - Non-Bufferable Write
**
** Dynamic Mode with AHB Configuration
**  - In this mode the A2X returns replies on the SP Channel to return reposnses for both bufferable
**    and non-bufferable transactions. Since the a2x_h2x module generates the bufferable responses the 
**    Dynamic control only return non-bufferable responses on the primary port. Since the AHB master is 
**    split after the last beat of a non-bufferable transaction there can only be one outstanding write 
**    response per AHB master
**-------------------------------------------------------------------------------
*/

//Reduction of a single bit expression is redundant. 
//This is acceptable in the A2X.

`include "DW_axi_a2x_all_includes.vh"

module i_axi_a2x_DW_axi_a2x_b (/*AUTOARG*/
   // Inputs
   clk_pp, 
   resetn_pp, 
   clk_sp, 
   resetn_sp, 
   awvalid_sp, 
   awready_sp, 
   awid_sp,
   aw_last_sp, 
   aw_nbuf_sp, 
   wvalid_pp, 
   wready_pp, 
   wlast_pp, 
   wid_pp, 
   bready_pp, 
   bvalid_sp, 
   b_pyld_sp, 
   pp_rst_n, 
   sp_rst_n, 
   unlk_seq,
   // Outputs
   bvalid_pp, 
   b_pyld_pp, 
   bready_sp, 
   b_buf_fifo_full, 
   b_osw_fifo_valid, 
   b_osw_trans
   );

  //*************************************************************************************
  //Parameter Decelaration
  //*************************************************************************************
  parameter  A2X_PP_MODE                 = 1; 
  parameter  A2X_EQSIZED                 = 1;
  parameter  A2X_BRESP_ORDER             = 1;
  parameter  A2X_BRESP_MODE              = 1;

  parameter  A2X_LOCKED                  = 0; 

  parameter  A2X_NUM_UWID                = 1;
  parameter  A2X_OSW_LIMIT               = 4; 
  parameter  A2X_OSW_LIMIT_LOG2          = 2;

  parameter  A2X_CLK_MODE                = 0;
  parameter  A2X_SP_SYNC_DEPTH           = 2; 
  parameter  A2X_PP_SYNC_DEPTH           = 2;

  parameter  A2X_BRESP_FIFO_DEPTH        = 4;
  parameter  A2X_BRESP_FIFO_DEPTH_LOG2   = 2;

  parameter  A2X_BSBW                    = 1;
  parameter  A2X_B_PYLD_W                = 32;   

  parameter  BYPASS_UBID_FIFO            = 1; 

  //*************************************************************************************
  // I/O Decelaration
  //*************************************************************************************
  //spyglass disable_block W240
  //SMD: An input has been declared but is not read.
  //SJ : This input is used in specific config only 
  input                                       clk_pp;
  input                                       resetn_pp;
  
  input                                       clk_sp;
  input                                       resetn_sp;

  // AXI Secondary Port AW Channel
  input                                       awvalid_sp;          // SP AW Channel
  input                                       awready_sp;
  input                                       aw_last_sp;
  input                                       aw_nbuf_sp; 
  input  [`A2X_IDW-1:0]                       awid_sp;    
  input                                       wvalid_pp;           // PP W channel (Bufferable Mode)
  input                                       wlast_pp;   
  input  [`A2X_IDW-1:0]                       wid_pp;    
  input                                       wready_pp;   
  // AXI Primary Port Write response                                  
  input                                       bready_pp;           // PP B Channel
  //spyglass enable_block W240                        
  output                                      bvalid_pp;     
  output [A2X_B_PYLD_W-1:0]                   b_pyld_pp;

  

  // AXI Secondary Port Write Response 
  output                                      bready_sp;           // SP B Channel
  //spyglass disable_block W240
  //SMD: An input has been declared but is not read.
  //SJ : This input is used in specific config only 
  input                                       bvalid_sp;     
  input  [A2X_B_PYLD_W-1:0]                   b_pyld_sp;
  //spyglass enable_block W240                        

  output                                      b_buf_fifo_full;     // B Resp Buffer Control for AW Channel
  output                                      b_osw_fifo_valid;
  output                                      b_osw_trans;

  //spyglass disable_block W240
  //SMD: An input has been declared but is not read.
  //SJ : This input is used in specific config only 
  input                                       pp_rst_n;
  input                                       sp_rst_n;
  input                                       unlk_seq;
  //spyglass enable_block W240                        

  //*************************************************************************************
  // Signal Decelaration
  //*************************************************************************************
  //These nets are used to connect the logic under certain configuration. 
  //But this may not drive any nets in some other configuration. 
  wire                                       bready_sp_w;
  wire                                       b_osw_fifo_valid_w;
  wire                                       b_osw_trans_w;
  wire                                       b_buf_fifo_full_w; 

  //These are dummy wires used to connect the unconnected ports.
  //Hence will not drive any nets.
  wire                                       b_osw_fifo_full_w;
  wire                                       b_osw_fifo_empty;
  
  wire                                       b_osw_fifo_empty_w;
  
  //Only used when A2X_LOCKED selected
  reg  [3:0]                                 osw_cnt;
  wire [3:0]                                 osw_cnt_i;
  wire                                       osw_cnt_zero;
  wire                                       osw_cnt_max;

  //*************************************************************************************
  // Bufferable Response Channel FIFO
  // - Response returns as soon as wlast last detected on Primary Port.
  //
  // - FIFO not required in AHB Mode. 
  //*************************************************************************************
  generate 
    if (A2X_BRESP_MODE==0) begin: BUF_RESP
      if (A2X_PP_MODE==1) begin: BUF_RESP_PP_MODE
        i_axi_a2x_DW_axi_a2x_b_buf
         #(
           .BRESP_FIFO_DEPTH                  (A2X_BRESP_FIFO_DEPTH)
          ,.BRESP_FIFO_DEPTH_LOG2             (A2X_BRESP_FIFO_DEPTH_LOG2) 
          ,.A2X_BSBW                          (A2X_BSBW)
        ) U_a2x_b_buf (
          // Outputs
          .bvalid_o                          (bvalid_pp)
          ,.fifo_full                         (b_buf_fifo_full_w)
          ,.b_pyld_o                          (b_pyld_pp)
          // Inputs 
          ,.clk                               (clk_pp)
          ,.resetn                            (resetn_pp)
          ,.wlast_i                           (wlast_pp)
          ,.wvalid_i                          (wvalid_pp)
          ,.wready_i                          (wready_pp)
          ,.wid_i                             (wid_pp)
          ,.bready_i                          (bready_pp)
          ,.pp_rst_n                          (pp_rst_n)
          ,.sp_rst_n                          (sp_rst_n)
        );
      end else begin
        assign b_buf_fifo_full_w  = 1'b0; 
        assign bvalid_pp          = 1'b0;
        assign b_pyld_pp          = {A2X_B_PYLD_W{1'b0}};
      end
      
      //****************************************************************************************
      // Outstanding Write Transaction counter in bufferable Mode
      // 
      // If Locked is supported in the A2X, the A2X must keep track of the
      // number of outstanding write transactions on AXI SP. The A2X will not
      // start a locked or unlocking transaction until this counter is zero. 
      //****************************************************************************************
      if (A2X_LOCKED==1) begin : LK_OSWCNT
        assign osw_cnt_i = osw_cnt;  
        always @(posedge clk_sp or negedge resetn_sp) begin: osw_cnt_PROC
          if (resetn_sp==1'b0)
            osw_cnt <= 4'b0;
          else begin
            if (awvalid_sp && awready_sp && bvalid_sp && bready_sp)
              osw_cnt <= osw_cnt_i;
            else if (awvalid_sp && awready_sp)
              osw_cnt <= osw_cnt_i + 1;
            else if (bvalid_sp && bready_sp) 
              osw_cnt <= osw_cnt_i -1; 
          end
        end
        assign osw_cnt_zero = ~(|osw_cnt);
        assign osw_cnt_max  = &osw_cnt;
      end else begin
        assign osw_cnt_zero = 1'b1;
        assign osw_cnt_max  = 1'b0;
      end

    end  // A2X_BRESP_MODE
  endgenerate  

  //*************************************************************************************
  // Non-Bufferable Response Channel FIFO
  // - Response returns from Secondary Port.
  //*************************************************************************************
  generate 
    if (A2X_BRESP_MODE!=0) begin: NBUF_RESP
      i_axi_a2x_DW_axi_a2x_b_nbuf
       #( 
        .A2X_PP_MODE                       (A2X_PP_MODE) 
        ,.A2X_EQSIZED                       (A2X_EQSIZED)
        ,.A2X_BRESP_ORDER                   (A2X_BRESP_ORDER)
        ,.A2X_LOCKED                        (A2X_LOCKED)
        
        ,.A2X_NUM_UWID                      (A2X_NUM_UWID)
        ,.A2X_OSW_LIMIT                     (A2X_OSW_LIMIT) 
        ,.A2X_OSW_LIMIT_LOG2                (A2X_OSW_LIMIT_LOG2)
        
        ,.A2X_CLK_MODE                      (A2X_CLK_MODE)
        ,.A2X_SP_SYNC_DEPTH                 (A2X_SP_SYNC_DEPTH) 
        ,.A2X_PP_SYNC_DEPTH                 (A2X_PP_SYNC_DEPTH)
        
        ,.A2X_BRESP_FIFO_DEPTH              (A2X_BRESP_FIFO_DEPTH)
        ,.A2X_BRESP_FIFO_DEPTH_LOG2         (A2X_BRESP_FIFO_DEPTH_LOG2)
        
        ,.A2X_BSBW                          (A2X_BSBW)
        ,.A2X_B_PYLD_W                      (A2X_B_PYLD_W)
        
        ,.BYPASS_UBID_FIFO                  (BYPASS_UBID_FIFO)
      ) U_a2x_b_nbuf (
        // Outputs
        .bvalid_pp                         (bvalid_pp)
        ,.b_pyld_pp                         (b_pyld_pp)
        ,.bready_sp                         (bready_sp_w)
        ,.b_osw_fifo_full                   (b_osw_fifo_full_w)
        ,.b_osw_fifo_valid                  (b_osw_fifo_valid_w)
        ,.b_osw_fifo_empty                  (b_osw_fifo_empty_w)
        ,.b_osw_trans                       (b_osw_trans_w)
        
        // Inputs
        ,.clk_pp                            (clk_pp)
        ,.resetn_pp                         (resetn_pp)
        ,.clk_sp                            (clk_sp)
        ,.resetn_sp                         (resetn_sp)
        ,.awvalid_sp                        (awvalid_sp)
        ,.awready_sp                        (awready_sp)
        ,.awid_sp                           (awid_sp)
        ,.aw_last_sp                        (aw_last_sp)
        ,.aw_nbuf_sp                        (aw_nbuf_sp)
        ,.bready_pp                         (bready_pp)
        ,.bvalid_sp                         (bvalid_sp)
        ,.b_pyld_sp                         (b_pyld_sp)
        ,.pp_rst_n                          (pp_rst_n)
        ,.sp_rst_n                          (sp_rst_n)
        ,.unlk_seq                          (unlk_seq)
      );
    end
  endgenerate

   // Bufferable FIFO never full in Non-Bufferable Mode
   assign b_buf_fifo_full   = (A2X_BRESP_MODE==0) ? b_buf_fifo_full_w : 1'b0;
   // Outstanding Burst response FIFO always valid in Bufferable Mode
   assign b_osw_fifo_valid  = ((A2X_LOCKED==1) && (A2X_BRESP_MODE==0))? ~osw_cnt_max : (A2X_BRESP_MODE==0) ? 1'b1 : b_osw_fifo_valid_w;
   // Outstanding Burst response FIFO always empty in Bufferable Mode
   assign b_osw_fifo_empty  = (A2X_BRESP_MODE==0) ? 1'b1 : b_osw_fifo_empty_w;
   // Always accept SP B responses in Bufferable Mode. 
   assign bready_sp         = (A2X_BRESP_MODE==0) ? 1'b1 : bready_sp_w;

   assign b_osw_trans       = (A2X_BRESP_MODE==0)? ~osw_cnt_zero : b_osw_trans_w; 

endmodule 
//Revision: $Id: //dwh/DW_ocb/DW_axi_a2x/amba_dev/src/DW_axi_a2x_b.v#69 $
