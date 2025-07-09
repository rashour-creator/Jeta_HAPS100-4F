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
// File Version     :        $Revision: #6 $ 
// Revision: $Id: //dwh/DW_ocb/DW_axi/axi_dev_br/src/DW_axi_lockdec.v#6 $ 
**
** ---------------------------------------------------------------------
**
** File     : DW_axi_lockdec.v
//
//
** Created  : Tue May 24 17:09:09 MEST 2005
** Modified : $Date: 2021/07/21 $
** Abstract : Decode a*lock bits from the ar and aw payloads from each 
**            visible master port.
**
** ---------------------------------------------------------------------
*/

`include "DW_axi_all_includes.vh"
module i_axi_DW_axi_lockdec (
  // Inputs.
  bus_awpayload_i,
  bus_arpayload_i,

  // Outputs.
  bus_awlocktx_o,
  bus_arlocktx_o
);

   
//----------------------------------------------------------------------
// MODULE PARAMETERS.
//----------------------------------------------------------------------
  parameter NUM_VIS_MP = 2; // Number of visible master ports.

  parameter BUS_AW_PYLD_S_W = 0; // Payload width of AW channel at 
                                 // slave port.
        
  parameter BUS_AR_PYLD_S_W = 0; // Payload width of AR channel at 
                                 // slave port.
         
//----------------------------------------------------------------------
// PORT DECLARATIONS
//----------------------------------------------------------------------

//----------------------------------------------------------------------
// INPUTS
//----------------------------------------------------------------------
  input [BUS_AW_PYLD_S_W-1:0] bus_awpayload_i;
  input [BUS_AR_PYLD_S_W-1:0] bus_arpayload_i;

//----------------------------------------------------------------------
// OUTPUTS
//----------------------------------------------------------------------
  output [NUM_VIS_MP-1:0] bus_awlocktx_o; // Bit for each visible master
  reg    [NUM_VIS_MP-1:0] bus_awlocktx_o; // port. Asserted if lock bits
              // decode to locked AW t/x.
           
  output [NUM_VIS_MP-1:0] bus_arlocktx_o; // Bit for each visible master
  reg    [NUM_VIS_MP-1:0] bus_arlocktx_o; // port. Asserted if lock bits
            // decode to locked AW t/x.
            

  //--------------------------------------------------------------------
  // REGISTER VARIABLES.
  //--------------------------------------------------------------------
  reg [`i_axi_AXI_AW_PYLD_S_W-1:0] awpayload; // Temporary variables for a 
  reg [`i_axi_AXI_AR_PYLD_S_W-1:0] arpayload; // single payload.

  
   
  // Decode if awlock bits from each mp signal a lock t/x.
  // spyglass disable_block W415a
  // SMD: Signal may be multiply assigned (beside initialization) in the same scope
  // SJ: This is not an issue
  // spyglass disable_block SelfDeterminedExpr-ML
  // SMD: Self determined expression found
  // SJ: The expression indexing the vector/array will never exceed the bound of the vector/array.
  always @(*)
  begin : bus_awlocktx_o_PROC
    integer mp, bt; 
    bus_awlocktx_o = {NUM_VIS_MP{1'b0}};

    for(mp=0 ; mp<=(NUM_VIS_MP-1) ; mp=mp+1) begin

      for(bt=0 ; bt<=(`i_axi_AXI_AW_PYLD_S_W-1) ; bt=bt+1) begin
  awpayload[bt] = bus_awpayload_i[(mp*`i_axi_AXI_AW_PYLD_S_W)+bt];
      end

      bus_awlocktx_o[mp] 
        = (     awpayload[`i_axi_AXI_AWPYLD_LOCK_LHS:`i_axi_AXI_AWPYLD_LOCK_RHS]
       == `i_axi_AXI_LT_LOCK
    );

    end
  end // bus_awlocktx_o_PROC
  

  // Decode if arlock bits from each mp signal a lock t/x.
  always @(*)
  begin : bus_arlocktx_o_PROC
    integer mp, bt; 
    bus_arlocktx_o = {NUM_VIS_MP{1'b0}};

    for(mp=0 ; mp<=(NUM_VIS_MP-1) ; mp=mp+1) begin

      for(bt=0 ; bt<=(`i_axi_AXI_AR_PYLD_S_W-1) ; bt=bt+1) begin
  arpayload[bt] = bus_arpayload_i[(mp*`i_axi_AXI_AR_PYLD_S_W)+bt];
      end

      bus_arlocktx_o[mp] 
        = (     arpayload[`i_axi_AXI_ARPYLD_LOCK_LHS:`i_axi_AXI_ARPYLD_LOCK_RHS]
       == `i_axi_AXI_LT_LOCK
    );

    end
  end // bus_arlocktx_o_PROC
  // spyglass enable_block SelfDeterminedExpr-ML
  // spyglass enable_block W415a


endmodule
