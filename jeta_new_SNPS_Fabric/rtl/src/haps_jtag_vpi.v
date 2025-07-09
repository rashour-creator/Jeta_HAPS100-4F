/*

	This file replaces the default JTAGVPI implementation.
	Instead of driving JTAG signals from this module controlled by VCS using DPI,
	we will create cross-module references to the haps top-level.
	
	The goal is not to touch/modify the original RTL for prototoyping.
*/


module JTAGVPI
  #(
    parameter DEBUG_INFO = 0,
    parameter TP = 1,
    parameter TCK_HALF_PERIOD = 2, // 50, // Clock half period (Clock period = 100 ns => 10 MHz)
    parameter CMD_DELAY = 2,       // 1000
    parameter INIT_DELAY = 200
    )   
   (
    output jtag_TMS,
    output jtag_TCK,
    output jtag_TDI,
    input  jtag_TDO_data,
    input  jtag_TDO_driven,

    input  enable,
    input  init_done
    );
 
endmodule

 
