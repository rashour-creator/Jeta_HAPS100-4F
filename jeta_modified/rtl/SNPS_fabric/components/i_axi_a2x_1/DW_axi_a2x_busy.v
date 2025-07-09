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
// File Version     :        $Revision: #20 $ 
// Revision: $Id: //dwh/DW_ocb/DW_axi_a2x/amba_dev/src/DW_axi_a2x_busy.v#20 $ 
**
** --------------------------------------------------------------------
**
** File     : DW_axi_a2x_busy.v
** Created  : Thu Jan 27 11:01:40 MET 2011
** Abstract :
**
** --------------------------------------------------------------------
*/

//*********************************************************************
// DW_axi_a2x_busy:
//  Reports the busy status of the bridge in a single bit busy_status
//  output flag. 0=>NOT_BUSY : 1=>BUSY
//  This module uses outstanding transaction information and the write
//  address buffer empty status to know if the bridge is busy
//  processing transactions.
//*********************************************************************
`include "DW_axi_a2x_all_includes.vh"

module i_axi_a2x_1_DW_axi_a2x_busy ( /*AUTOARG*/
  // Outputs
  busy_status,
  // Inputs
  clk_pp, resetn_pp, bridge_sel, pp_osx_wr, pp_osx_rd, aw_sp_active,
  aw_fifo_push_empty, snf_fifo_push_empty, w_fifo_push_empty
  );

  // Lint flags this rule when any signal in the cross over path has more than one fanout or any object 
  // in the cross over path has more than one output. Signal aw_sp_active is reporting the violation
  // both no issue can be found with the implementation.
  parameter A2X_BRESP_MODE = 1;
  parameter A2X_CLK_MODE   = 0;

  //spyglass disable_block W240
  //SMD: An input has been declared but is not read.
  //SJ : Few ports are used in specific config only 
  input     clk_pp;                // Primary port clock
  input     resetn_pp;             // Primary port async resetn
  input     bridge_sel;            // Bridge select on the primary port       (sync to clk_pp)
  input     pp_osx_wr;             // Primary port outstanding write status   (sync to clk_pp)
  input     pp_osx_rd;             // Primary port outstanding read status    (sync to clk_pp)
  input     aw_sp_active;          // Write SP AW Channel status              (sync to clk_sp)
  input     aw_fifo_push_empty;
  input     snf_fifo_push_empty;
  // Input w_fifo_push_empty is not read when A2X_BRESP_MODE = 1.
  input     w_fifo_push_empty;
  output    busy_status;   // Bridge busy status flag                 (sync to clk_pp)
  //spyglass enable_block W240

  reg       busy_status;
  //not used if A2X_BRESP_MODE ==1
  wire      aw_sp_active_sync;
  
  // Synchronize secondary port clock signals into the primary port clock
  // domain.
  generate
    if(A2X_CLK_MODE==2 && A2X_BRESP_MODE!=1) begin: SP_OS_WR_SYNC
 // The following port(s) of this instance are intentionally unconnected.  So, disable lint from reporting warning.  
 // This instance design is shared by other module(s) that uses these port(s).
      wire sp2ppl_aw_sp_active;
      wire ssp2ppl_aw_sp_active;

      assign sp2ppl_aw_sp_active = aw_sp_active;
      assign aw_sp_active_sync   = ssp2ppl_aw_sp_active;

      i_axi_a2x_1_DW_axi_a2x_bcm21
       #(
         .WIDTH            (1)
        ,.F_SYNC_TYPE      (2)
        ,.VERIF_EN         (`A2X_VERIF_EN)
        ,.SVA_TYPE         (1)
      ) U_DW_axi_a2x_bcm21_sp2ppl_aw_sp_active_ppsyzr (
          .clk_d    (clk_pp)
         ,.rst_d_n  (resetn_pp)
         ,.data_s   (sp2ppl_aw_sp_active)
         ,.data_d   (ssp2ppl_aw_sp_active)
      );
    end else begin// if(A2X_CLK_MODE==2) begin
      assign aw_sp_active_sync = aw_sp_active;
    end
  endgenerate

// Register the busy status output
generate if (A2X_BRESP_MODE==1) begin: BRESP_MODE
  always @(posedge clk_pp or negedge resetn_pp) begin : BUSY_STATUS_1_PROC
    if(resetn_pp==1'b0) begin
      busy_status <= 1'b0;
    end else begin
      busy_status   <= bridge_sel | pp_osx_wr | pp_osx_rd | (~aw_fifo_push_empty) | (~snf_fifo_push_empty);
    end
  end
end // BRESP_MODE_1
else if (A2X_BRESP_MODE==0) begin
  always @(posedge clk_pp or negedge resetn_pp) begin : BUSY_STATUS_0_PROC
    if(resetn_pp==1'b0) begin
      busy_status <= 1'b0;
    end else begin
      busy_status <= bridge_sel | pp_osx_wr | pp_osx_rd | aw_sp_active_sync | (~aw_fifo_push_empty) | (~snf_fifo_push_empty) | (~w_fifo_push_empty);
    end
  end
end // BRESP_MODE_0
else begin
  always @(posedge clk_pp or negedge resetn_pp) begin : BUSY_STATUS_ELSE_PROC
    if(resetn_pp==1'b0) begin
      busy_status <= 1'b0;
    end else begin
      busy_status <= bridge_sel | pp_osx_wr | pp_osx_rd | aw_sp_active_sync | (~aw_fifo_push_empty) | (~snf_fifo_push_empty) | (~w_fifo_push_empty);
    end
  end
end // BRESP_MODE_ELSE
endgenerate // BRESP_MODE

endmodule // DW_axi_a2x_busy
//Revision: $Id: //dwh/DW_ocb/DW_axi_a2x/amba_dev/src/DW_axi_a2x_busy.v#20 $
