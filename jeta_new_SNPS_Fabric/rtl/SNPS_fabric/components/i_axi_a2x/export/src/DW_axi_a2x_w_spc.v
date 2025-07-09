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
// Revision: $Id: //dwh/DW_ocb/DW_axi_a2x/axi_dev_br/src/DW_axi_a2x_w_spc.v#5 $ 
// --------------------------------------------------------------------
*/

`include "DW_axi_a2x_all_includes.vh"
//*************************************************************************************
// Secondary Port Write Control
//
// The SPC fifo contains the AWLEN issued on the AW SP. This value is used
// to generate the SP Write Last. This information is popped from the SPC
// FIFO. 
//
// In AHB Mode this module also generates the write data strobes for AHB transaction
// that were EBT'd or for INCR's less than the defined length. 
//*************************************************************************************
module i_axi_a2x_DW_axi_a2x_w_spc (/*AUTOARG*/
   // Outputs
   spc_fifo_pop_n, w_pyld_o, w_fifo_pop_n, strobe,
   // Inputs
   clk, resetn, wready_i, wvalid_i, w_pyld_i, awlen_i, awlast_sp, wbuf_mode
   );

  // **************************************************************************************
  // Parameters
  // **************************************************************************************
  parameter A2X_PP_MODE           = 0;
  parameter A2X_SP_DW             = 32;
  parameter A2X_SP_WSTRB_DW       = 4;  
  parameter A2X_WSBW              = 1;  
  parameter A2X_W_AWLEN_PYLD_W    = 32; 
  parameter A2X_W_SP_PYLD         = 32;
  parameter A2X_EQSIZED           = 1; 

  // **************************************************************************************
  // I/O Decelaration
  // **************************************************************************************
  input                                       clk;
  input                                       resetn;

  input                                       wready_i;
  input                                       wvalid_i;
  input  [A2X_W_SP_PYLD-1:0]                  w_pyld_i;

  output                                      spc_fifo_pop_n;
  input  [A2X_W_AWLEN_PYLD_W-1:0]             awlen_i;
  //spyglass disable_block W240
  //SMD: An input has been declared but is not read.
  //SJ : Input awlast_sp is read only when A2X_PP_MODE is 0.
  input                                       awlast_sp;
  //spyglass enable_block W240
  input                                       wbuf_mode;

  output [A2X_W_SP_PYLD-1:0]                  w_pyld_o;
  output                                      w_fifo_pop_n;
  output                                      strobe; 
  
  // **************************************************************************************
  // Signal Decelaration
  // **************************************************************************************
  wire                                        wlast_i;   
  wire  [`i_axi_a2x_A2X_IDW-1:0]                        wid_i;    
  wire  [A2X_SP_DW-1:0]                       wdata_i; 
  wire  [A2X_SP_WSTRB_DW-1:0]                 wstrb_i;
  wire  [A2X_WSBW-1:0]                        wsideband_i;

  wire                                        wlast_o;   
  wire  [A2X_SP_DW-1:0]                       wdata_o; 
  wire  [A2X_SP_WSTRB_DW-1:0]                 wstrb_o;

  reg   [A2X_W_AWLEN_PYLD_W-1:0]              wr_cnt; 
  wire                                        wr_cnt_max;

  wire                                        strobe;
  reg                                         w_fifo_pop_n_r;

  // **************************************************************************************
  // Write Payload Decode
  // **************************************************************************************
  assign {wsideband_i, wid_i, wstrb_i, wdata_i, wlast_i} = w_pyld_i;

  // **************************************************************************************
  // Write Last Counter
  //
  // Increment counter until SP AWLEN Reached. 
  // **************************************************************************************
  always @(posedge clk or negedge resetn) begin: wr_cnt_PROC
    if (resetn==1'b0) begin
      wr_cnt <= {A2X_W_AWLEN_PYLD_W{1'b0}}; 
    end else begin
      if ((A2X_PP_MODE==1) && (A2X_EQSIZED==1) && (wbuf_mode==1'b0)) begin
        wr_cnt <= {A2X_W_AWLEN_PYLD_W{1'b0}};
      end else if (wvalid_i && wready_i ) begin 
        if (wr_cnt_max)
          wr_cnt <= {A2X_W_AWLEN_PYLD_W{1'b0}};
        else
          wr_cnt <= wr_cnt + 1;
      end
    end
  end

  // Compare with AW SP ALEN value. 
  assign wr_cnt_max = (wr_cnt==awlen_i)? 1'b1 :1'b0;

  // **************************************************************************************
  // Write Strobe - AHB Mode Only
  // - Only when wlast detected early and count not set to max is Data strobed.
  // **************************************************************************************
  generate 
  if (A2X_PP_MODE==0) begin: STRB
    reg strobe_r; 
    always @(posedge clk or negedge resetn) begin: strb_PROC
      if (resetn==1'b0) begin
        strobe_r <= 1'b0; 
      end else begin
        if (wvalid_i && wready_i && (A2X_PP_MODE==0)) begin
          if (wr_cnt_max && awlast_sp)
            strobe_r <= 1'b0;
          else if (wlast_i)
            strobe_r <= 1'b1;
        end
      end
    end
    assign strobe = strobe_r; 
  end else begin
    assign strobe = 1'b0; 
  end
  endgenerate
  // **************************************************************************************
  // SP Control FIFO Pop - when Write count max reached 
  // **************************************************************************************
  assign spc_fifo_pop_n  = ((A2X_PP_MODE==1) && (A2X_EQSIZED==1) && (wbuf_mode==1'b0))? 1'b1 : !(wr_cnt_max & wvalid_i & wready_i);

  // **************************************************************************************
  // Write Data Payload
  // **************************************************************************************
  // SP Write Last generated when write count max reached. 
  assign wlast_o = ((A2X_PP_MODE==1) && (A2X_EQSIZED==1) && (wbuf_mode==1'b0))? wlast_i : wr_cnt_max;

  // If Strobe asserted generate strobed data beats for AHB Mode. 
  assign wdata_o = ((A2X_PP_MODE==0) && strobe)? {A2X_SP_DW{1'b0}}       : wdata_i;
  assign wstrb_o = ((A2X_PP_MODE==0) && strobe)? {A2X_SP_WSTRB_DW{1'b0}} : wstrb_i; 
    
  assign w_pyld_o = {wsideband_i, wid_i, wstrb_o, wdata_o, wlast_o};

  // **************************************************************************************
  // Write Data Payload FIFO Pop
  //
  // When generating strobe data want to leave last data transfer in FIFO until write last 
  // generated on SP, this alows the WID to be driven from the FIFO. Hence no
  // need for register to WID. 
  // **************************************************************************************
  generate 
  if (A2X_PP_MODE==1) begin: POP
    assign w_fifo_pop_n = !(wvalid_i & wready_i);
  end else begin
    always @(*) begin : w_fifo_pop_PROC
      // Leave Last Data Beat in FIFO until all strobes generated.
      if (wvalid_i & wready_i) begin
        if (wlast_o & awlast_sp) 
          w_fifo_pop_n_r = 1'b0; 
        else if (strobe || wlast_i)
          w_fifo_pop_n_r = 1'b1;
        else
          w_fifo_pop_n_r = 1'b0; 
      end else begin
        w_fifo_pop_n_r = 1'b1; 
      end
    end // always 
    assign w_fifo_pop_n = w_fifo_pop_n_r;

  end
  endgenerate

endmodule
