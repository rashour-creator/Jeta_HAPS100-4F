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
// File Version     :        $Revision: #2 $ 
// Revision: $Id: //dwh/DW_ocb/DW_axi_a2x/axi_dev_br/src/DW_axi_a2x_fifo_sclk_r.v#2 $ 
// --------------------------------------------------------------------
*/

`include "DW_axi_a2x_all_includes.vh"

//**********************************************************************
// Single Clock Outputs Registered
// - This module registers the outputs of the SCLK FIFO without adding any
//   additional Latency to the design.
//**********************************************************************
module i_axi_a2x_DW_axi_a2x_fifo_sclk_r (
  // Inputs - Push Side 
  clk,
  resetn,

  push_req_n_i,
  pop_req_n_i,
  empty_i,
  data_i,
  fifo_data,
  
  // Outputs
  push_req_n_o,
  pop_req_n_o,
  data_o,
  empty_o

);

 //----------------------------------------------------------------------
 // MODULE PARAMETERS.
 //----------------------------------------------------------------------

  // INTERFACE PARAMETERS - MUST BE SET BY INSTANTIATION
  parameter              DATA_W = 8; // Controls the width of each fifo.

  //----------------------------------------------------------------------
  // PORT DECLARATIONS
  //----------------------------------------------------------------------
  
  // Inputs - Push Side 
  input                      clk;    
  input                      resetn; 

  input                      push_req_n_i; // Push request.
  input                      pop_req_n_i;  // Pop request signal for fifo.
  input                      empty_i;      // Empty status signal from fifo.
  input [DATA_W-1:0]         data_i;       // Data in for fifo.
  input [DATA_W-1:0]         fifo_data;       // Data in for fifo.
  
  // Outputs - Pop Side
  output                     push_req_n_o;
  output                     pop_req_n_o;
  output [DATA_W-1:0]        data_o;       // Data out from fifo.
  output                     empty_o; 

  //--------------------------------------------------------------------
  // Signal Decelaration
  //--------------------------------------------------------------------
  reg    [DATA_W-1:0]     data_r;
  reg                     reg_empty;

  //--------------------------------------------------------------------
  // Fifo Data Output
  //--------------------------------------------------------------------
  always @(posedge clk or negedge resetn) begin: data_o_PROC
    if (resetn == 1'b0) begin
      data_r    <= {DATA_W{1'b0}};
    end else begin
      if (empty_i && (!push_req_n_i) && (!pop_req_n_i))
        data_r <= data_i;
      else if (reg_empty && (!push_req_n_i))
        data_r <= data_i;
      else if (!pop_req_n_i)
        data_r <= fifo_data;
    end
  end
 
  assign data_o = data_r;

  //--------------------------------------------------------------------
  // Register Status
  //--------------------------------------------------------------------
 always @(posedge clk or negedge resetn) begin: status_o_PROC
   if (resetn == 1'b0) begin
     reg_empty <= 1'b1;
    end else begin
      if (!push_req_n_i)
        reg_empty <= 1'b0;
      else if (empty_i && (!pop_req_n_i))
        reg_empty <= 1'b1;
    end
  end

  assign empty_o = reg_empty;

  // Push into FIFO if data in output register.
  assign push_req_n_o = (empty_i && (!push_req_n_i) && (!pop_req_n_i))? 1'b1 : (!reg_empty)? push_req_n_i : 1'b1;
  
  // Pop from FIFO
  assign pop_req_n_o  =  (empty_i) ? 1'b1 : pop_req_n_i;

endmodule
