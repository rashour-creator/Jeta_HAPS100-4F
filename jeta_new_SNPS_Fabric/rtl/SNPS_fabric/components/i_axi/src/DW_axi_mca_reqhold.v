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
// File Version     :        $Revision: #7 $ 
// Revision: $Id: //dwh/DW_ocb/DW_axi/axi_dev_br/src/DW_axi_mca_reqhold.v#7 $ 
**
** ---------------------------------------------------------------------
**
** File     : DW_axi_mca_reqhold.v
//
//
** Created  : Tue May 24 17:09:09 MEST 2005
** Modified : $Date: 2023/10/18 $
** Abstract : This block performs the arbiter input signal holding for
**            any arbiter that has multi-cycle arbitration enabled.
**
** ---------------------------------------------------------------------
*/

`include "DW_axi_all_includes.vh"
module i_axi_DW_axi_mca_reqhold (
  // Inputs - System.
  aclk_i,
  aresetn_i,

  // Inputs - Payload source.
  bus_req_i,
  bus_prior_i,
  
  // Inputs - Multi cycle arbitration control.
  new_req_i,

  // Outputs - Channel arbiter.
  bus_req_o,
  bus_prior_o
);

//----------------------------------------------------------------------
// MODULE PARAMETERS.
//----------------------------------------------------------------------
  parameter MCA_EN = 0; // 1 if multi cycle arbitration is enabled.

  parameter HOLD_PRIOR = 0; // 1 if this block should register priority
                            // values.
  
  parameter BUS_PRIOR_W = 0; // Width of priority input bus.

  parameter N = 2; // Numbre of request signals.

  parameter ARB_TYPE = 2; // Arbitration Type
       
//----------------------------------------------------------------------
// PORT DECLARATIONS
//----------------------------------------------------------------------
  // Inputs - System.
  input aclk_i;    // AXI system clock.
  input aresetn_i; // AXI system reset.

  // Inputs - Payload source.
  input [N-1:0]  bus_req_i; 
  input [BUS_PRIOR_W-1:0]  bus_prior_i; 

  // Inputs - Multi cycle arbitration control.
  input          new_req_i;

  // Outputs - Channel arbiter.
  output [N-1:0] bus_req_o; 
  output [BUS_PRIOR_W-1:0] bus_prior_o; 


  //--------------------------------------------------------------------
  // Register signals.
  //--------------------------------------------------------------------
  // Signal not used if MCA_EN is 0
  reg [N-1:0] bus_req_r;
  reg [BUS_PRIOR_W-1:0] bus_prior_r;



  //--------------------------------------------------------------------
  // Request hold and mux registers for request and priority signals.
  // Load registers with new request signals if new_req_i is 
  // asserted otherwise hold values.
  //--------------------------------------------------------------------
  assign bus_req_o = (MCA_EN == 0)
                     ? bus_req_i
         : bus_req_r;
 

 //spyglass disable_block FlopEConst
  //SMD: Reports permanently disabled or enabled flip-flop enable pins
  //SJ: This warning can be ignored.
  always @(posedge aclk_i or negedge aresetn_i)
  begin : bus_req_r_PROC
    if(!aresetn_i) begin
      bus_req_r <= {N{1'b0}};
    end else begin
      //ccx_cond: ; ; 0 ; multicycle arbitration not enabled in this configuration.
      bus_req_r <= (new_req_i ? bus_req_i : bus_req_r);
    end
  end // bus_req_r_PROC
  //spyglass enable_block FlopEConst

  // Registering of priority signals is not required unless user has
  // chosen to register external priority signals.
  assign bus_prior_o = ((MCA_EN == 0 | new_req_i) || (HOLD_PRIOR == 0 && ARB_TYPE != 4))
                       ? bus_prior_i
           : bus_prior_r;

  always @(posedge aclk_i or negedge aresetn_i)
  begin : bus_prior_r_PROC
    if(!aresetn_i) begin
      bus_prior_r <= {BUS_PRIOR_W{1'b0}};
    end else begin
      bus_prior_r <= (new_req_i ? bus_prior_i : bus_prior_r);
    end
  end // bus_prior_r_PROC


endmodule
