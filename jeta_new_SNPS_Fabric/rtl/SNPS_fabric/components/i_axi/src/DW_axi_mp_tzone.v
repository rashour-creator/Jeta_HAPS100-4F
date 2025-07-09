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
// File Version     :        $Revision: #3 $ 
// Revision: $Id: //dwh/DW_ocb/DW_axi/axi_dev_br/src/DW_axi_mp_tzone.v#3 $ 
**
** ---------------------------------------------------------------------
**
** File     : DW_axi_mp_tzone.v
//
//
** Created  : Tue May 24 17:09:09 MEST 2005
** Modified : $Date: 2021/07/21 $
** Abstract : This block is responsible for implementing the trustzone
**            features. 
**
** ---------------------------------------------------------------------
*/

`include "DW_axi_all_includes.vh"
module i_axi_DW_axi_mp_tzone (
  // Inputs.
  slvnum_i,
  prot_i,
  bus_secure_i,
  
  // Outputs.
  slvnum_o
);

//----------------------------------------------------------------------
// MODULE PARAMETERS.
//----------------------------------------------------------------------
  parameter NUM_VIS_SP = 16; // Number of slave ports visible to
                             // this master port.

  parameter LOG2_NUM_VIS_SP = 4; // Log 2 of NUM_VIS_SP.

//----------------------------------------------------------------------
// LOCAL MACROS.
//----------------------------------------------------------------------

//----------------------------------------------------------------------
// PORT DECLARATIONS
//----------------------------------------------------------------------

//----------------------------------------------------------------------
// INPUTS
//----------------------------------------------------------------------
  input [LOG2_NUM_VIS_SP-1:0] slvnum_i;     // Incoming local slave 
                                            // number.

  input                       prot_i;       // Protection attributes of 
                                            // current transaction.

  input [NUM_VIS_SP-1:0]      bus_secure_i; // Secure bit for every 
                                            // system slave, including 
               // the default slave.

//----------------------------------------------------------------------
// OUTPUTS
//----------------------------------------------------------------------
  output [LOG2_NUM_VIS_SP-1:0] slvnum_o; // Output local slave number.


  //--------------------------------------------------------------------
  // REGISTER VARIABLES.
  //--------------------------------------------------------------------


  //--------------------------------------------------------------------
  // WIRE VARIABLES.
  //--------------------------------------------------------------------
  wire current_slv_secure_c; // Asserted if input slave number refers
                             // to a secure slave.
           
  wire secure_access_c; // Asserted if current transaction is secure.

  wire security_break_c; // Asserted if unsecure transaction to secure
                         // slave is attempted.
  

  // This module implements the security bit mux.
  i_axi_DW_axi_busmux
  
  #(NUM_VIS_SP,      // Number of inputs to the mux.
    1,               // Width of each input to the mux.
    LOG2_NUM_VIS_SP  // Width of select line for the mux.
  )
  U_lcltosys_mux (
    .sel  (slvnum_i),
    .din  (bus_secure_i), 
    .dout (current_slv_secure_c) 
  );
  

  // Is this a secure access.
  assign secure_access_c = !prot_i;


  // Is this a non secure access to a secure slave.
  assign security_break_c = (!secure_access_c && current_slv_secure_c)
                ? 1'b1 : 1'b0;


  // Send output slave number of 0 (default slave) if there is
  // a security break.
  assign slvnum_o = security_break_c ? {LOG2_NUM_VIS_SP{1'b0}}
                                     : slvnum_i;


endmodule
