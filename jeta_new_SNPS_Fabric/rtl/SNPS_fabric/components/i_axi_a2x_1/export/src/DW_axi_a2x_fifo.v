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
// File Version     :        $Revision: #15 $ 
// Revision: $Id: //dwh/DW_ocb/DW_axi_a2x/axi_dev_br/src/DW_axi_a2x_fifo.v#15 $ 
**
** --------------------------------------------------------------------
**
** File     : DW_axi_a2x_fifo.v
** Created  : Thu Jan 27 11:01:40 MET 2011
** Abstract :
**
** --------------------------------------------------------------------
*/

`include "DW_axi_a2x_all_includes.vh"

module i_axi_a2x_1_DW_axi_a2x_fifo (
  // Inputs - Push Side 
  clk_push_i,
  resetn_push_i,

  push_req_n_i,
  data_i,
  
  // Outputs - Push Side
  push_full_o,
  push_empty_o,

  // Inputs - Pop Side 
  clk_pop_i,
  resetn_pop_i,

  pop_req_n_i,
  
  // Outputs - Pop Side
  pop_empty_o,
  data_o,

  pop_count,
  push_count
);

//----------------------------------------------------------------------
// MODULE PARAMETERS.
//----------------------------------------------------------------------

  // INTERFACE PARAMETERS - MUST BE SET BY INSTANTIATION
  parameter DUAL_CLK = 0; // Controls wether single or dual clock
                          // fifos are implemented.

  parameter PUSH_SYNC_DEPTH = 2; // Number of synchroniser registers to
                                 // use in push side of dual clock fifos.

  parameter POP_SYNC_DEPTH = 2; // Number of synchroniser registers to
                                // use in pop side of dual clock fifos.

  parameter DATA_W = 8; // Controls the width of each fifo.
  parameter DEPTH = 2; // Controls the depth of each fifo.
  parameter LOG2_DEPTH = 1; // Log base 2 of DEPTH.

  localparam LOG2_DEPTH_P1 = LOG2_DEPTH+1; // Log base 2 of DEPTH + 1.

  localparam REG_OUT = 1; //Registered data Outputs from Synchronous FIFO

//----------------------------------------------------------------------
// PORT DECLARATIONS
//----------------------------------------------------------------------
  
  // Inputs - Push Side 
  input clk_push_i; // Push side clk.
  input resetn_push_i; // Push side reset.

  //Signal used in only Asynchronous configurations
  input push_req_n_i; // Push request.

  input [DATA_W-1:0] data_i; // Data in for fifo.
  
  // Outputs - Push Side
  output push_full_o;   // Full status signal from fifo.
  output push_empty_o;  // Push empty status from fifo.


  // Inputs - Pop Side
  //spyglass disable_block W240
  //SMD: An input has been declared but is not read.
  //SJ : These inputs are read only in asynchrnous configuration or DUAL_CLK = 1.
  input clk_pop_i; // Pop side clk.
  input resetn_pop_i; // Pop side reset.
  //Signal used in only Asynchronous configurations
  input pop_req_n_i; // Pop request signal for fifo.
  //spyglass enable_block W240

  // Outputs - Pop Side
  output pop_empty_o; // Empty status signal from fifo.

  output [DATA_W-1:0] data_o; // Data out from fifo.

  output [LOG2_DEPTH_P1-1:0] pop_count;
  output [LOG2_DEPTH_P1-1:0] push_count;

  //--------------------------------------------------------------------
  // WIRE VARIABLES.
  //--------------------------------------------------------------------
  wire [DATA_W-1:0]        sclk_data_o; // Single clock fifo output signals.
  wire                     sclk_push_full_o;
  wire                     sclk_pop_empty_o;
  wire [LOG2_DEPTH_P1-1:0] sclk_pop_wcount;
  wire [LOG2_DEPTH_P1-1:0] sclk_push_wcount;
  wire                     sclk_push_req_n_i;
  wire                     sclk_pop_req_n_i;

  wire                     sclk_almost_empty;
  wire                     sclk_half_full;
  wire                     sclk_almost_full;
  wire                     sclk_error;

  // These nets are used to connect the logic under certain configuration.
  // But this may not drive any net in some other configuration. 
  wire [DATA_W-1:0]        dclk_data_o; // Dual clock fifo output signals.
  wire                     dclk_push_full_o;
  wire                     dclk_push_empty_o;
  wire                     dclk_pop_empty_o;
  wire [LOG2_DEPTH_P1-1:0] dclk_pop_wcount;
  wire [LOG2_DEPTH_P1-1:0] dclk_push_wcount;
  
  // These are dummy wires used to connect the unconnected ports.
  // Hence will not drive any nets.
  wire                     dclk_push_ae;
  wire                     dclk_push_hf;
  wire                     dclk_push_af;
  wire                     dclk_push_error;
  wire                     dclk_nxt_push_full;
  wire                     dclk_nxt_push_empty;
  wire                     we_n;
  wire [LOG2_DEPTH-1:0]    wr_addr; 
  wire                     dclk_pop_ae; 
  wire                     dclk_pop_hf;
  wire                     dclk_pop_af;
  wire                     dclk_pop_full;
  wire                     dclk_nxt_pop_full;
  wire                     dclk_nxt_pop_empty;
  wire                     dclk_pop_error;
  reg [LOG2_DEPTH_P1-1:0]  sclk_wcount;  

  
  //--------------------------------------------------------------------
  //System Verilog Assertions
  //--------------------------------------------------------------------

  //--------------------------------------------------------------------
  // Single Clock Push & Pop Word Count
  //--------------------------------------------------------------------
  wire [LOG2_DEPTH_P1-1:0] sclk_wcount_plus1;
  wire [LOG2_DEPTH_P1-1:0] sclk_wcount_minus1;
  wire CO_add_unconn;
  wire CO_sub_unconn;

  generate
    if (DUAL_CLK==0) begin: DW01
      DW01_add #(LOG2_DEPTH_P1) U_add (
        .A(sclk_wcount),
        .B({{(LOG2_DEPTH_P1 - 1){1'b0}}, 1'b1}),
        .CI(1'b0),
        .SUM(sclk_wcount_plus1),
        .CO(CO_add_unconn)
      );
  
      DW01_sub #(LOG2_DEPTH_P1) U_sub (
        .A(sclk_wcount),
        .B({{(LOG2_DEPTH_P1 - 1){1'b0}}, 1'b1}),
        .CI(1'b0),
        .DIFF(sclk_wcount_minus1),
        .CO(CO_sub_unconn)
      );
    end
  endgenerate

  generate
    if (DUAL_CLK==0) begin: SCLK_FIFO_CNT
      always @(posedge clk_push_i or negedge resetn_push_i) begin: wcount_PROC
        if (resetn_push_i == 1'b0) begin
          sclk_wcount <= {LOG2_DEPTH_P1{1'b0}};
        end else begin
          if (push_req_n_i ^ pop_req_n_i) begin
            if (!push_req_n_i)
              sclk_wcount <= sclk_wcount_plus1;
            else if (!pop_req_n_i) 
              sclk_wcount <= sclk_wcount_minus1;
          end
        end
      end 
      
      assign sclk_pop_wcount  = sclk_wcount;
      assign sclk_push_wcount = sclk_wcount;
    end else begin
      assign sclk_pop_wcount  = 0;
      assign sclk_push_wcount = 0;
    end  
  endgenerate

  //--------------------------------------------------------------------
  // Select Register Data Outs from FIFO
  //--------------------------------------------------------------------
    generate
    if (DUAL_CLK==0) begin: SCLK_FIFO
      
      //--------------------------------------------------------------------
      // Registered Output from FIFO. 
      //--------------------------------------------------------------------
      if (REG_OUT==1) begin: SCLK_REG_OUT
        wire                     sclk_push_req_n_w;
        wire                     sclk_pop_req_n_w;
        wire                     sclk_fifo_empty_w;
        wire [DATA_W-1:0]        sclk_data_w; 
        
        i_axi_a2x_1_DW_axi_a2x_fifo_sclk_r
         #(
          .DATA_W            (DATA_W)    // Word width.
        ) U_sclk_fifo_r (
          .clk            (clk_push_i),   
          .resetn         (resetn_push_i),
          
          // Inputs
          .push_req_n_i   (push_req_n_i),
          .pop_req_n_i    (pop_req_n_i),   
          .empty_i        (sclk_pop_empty_o),
          .data_i         (data_i),   
          .fifo_data      (sclk_data_o),   
          
          // Pop side - Outputs
          .push_req_n_o   (sclk_push_req_n_w),
          .pop_req_n_o    (sclk_pop_req_n_w),   
          .empty_o        (sclk_fifo_empty_w),
          .data_o         (sclk_data_w) 
        );
        
        assign sclk_push_req_n_i = sclk_push_req_n_w;
        assign sclk_pop_req_n_i  = sclk_pop_req_n_w;
        assign pop_empty_o       = sclk_fifo_empty_w;
        assign data_o            = sclk_data_w;

      end else begin  // REG_OUT==0 
        assign sclk_push_req_n_i = push_req_n_i;
        assign sclk_pop_req_n_i  = pop_req_n_i;
        assign pop_empty_o       = sclk_pop_empty_o;
        assign data_o            = sclk_data_o; 
      end

     //--------------------------------------------------------------------
     // Instantiate single clock fifo.
     //--------------------------------------------------------------------
// The following port(s) of this instance are intentionally unconnected.  So, disable lint from reporting warning.  
// This instance design is shared by other module(s) that uses these port(s).
     i_axi_a2x_1_DW_axi_a2x_bcm65
      #(
      .WIDTH             (DATA_W),    // Word width.
      .DEPTH             (DEPTH),     // Word depth.  
      .AE_LEVEL          (1),         // ae_level, don't care.
      .AF_LEVEL          (1),         // af_level, don't care.
      .ERR_MODE          (0),         // err_mode, don't care.
      .RST_MODE          (0),         // Reset mode, asynch. reset including memory.
      .ADDR_WIDTH        (LOG2_DEPTH) // Fifo address width.
     ) U_sclk_fifo (
      .clk            (clk_push_i),   
      .rst_n          (resetn_push_i),
      .init_n         (1'b1), // Synchronous reset, not used.
      
      // Push side - Inputs
      .push_req_n     (sclk_push_req_n_i),
      .data_in        (data_i),   
      
      // Push side - Outputs
      .full           (sclk_push_full_o), 

      // Pop side - Inputs
      .pop_req_n      (sclk_pop_req_n_i),   
    
      // Pop side - Outputs
      .data_out       (sclk_data_o),
      .empty          (sclk_pop_empty_o),

      // Unconnected or tied off.
      .diag_n         (1'b1), // Never using diagnostic mode.
      .almost_empty   (sclk_almost_empty), // not necessary here.
      .half_full      (sclk_half_full), //  not necessary here.
      .almost_full    (sclk_almost_full), // not necessary here.
      .error          (sclk_error)  //  not necessary here.
     );
    
     assign push_full_o  =  sclk_push_full_o;
     assign push_empty_o =  pop_empty_o;
     assign pop_count    =  sclk_pop_wcount;
     assign push_count   =  sclk_push_wcount;
     
    end else begin: DUAL_CLK_FIFO // DUAL_CLK==1
      
      //--------------------------------------------------------------------
      // Instantiate dual clock fifo.
      //--------------------------------------------------------------------
      wire [DATA_W-1:0]        push2popaf_data_i;
      wire [DATA_W-1:0]        spush2popaf_data_o;

      assign push2popaf_data_i = data_i;
      assign dclk_data_o       = spush2popaf_data_o;

// The following port(s) of this instance are intentionally unconnected.  So, disable lint from reporting warning.  
// This instance design is shared by other module(s) that uses these port(s).
      i_axi_a2x_1_DW_axi_a2x_bcm66
      
       #(
       .WIDTH              (DATA_W),           // Word width.
       .DEPTH              (DEPTH),            // Word depth.
       .ADDR_WIDTH         (LOG2_DEPTH),       // Fifo address width.
       .COUNT_WIDTH        (LOG2_DEPTH_P1),    // Count width.
       .PUSH_AE_LVL        (1),                // push ae_level, don't care.
       .PUSH_AF_LVL        (1),                // push af_level, don't care.
       .POP_AE_LVL         (1),                // pop ae_level, don't care.
       .POP_AF_LVL         (1),                // pop af_level, don't care.
       .ERR_MODE           (0),                // err_mode, don't care.
       .PUSH_SYNC          (PUSH_SYNC_DEPTH),  // Push sync mode.
       .POP_SYNC           (POP_SYNC_DEPTH),   // Pop sync mode.
       .RST_MODE           (0),                // Reset mode, asynch. reset including memory.
       .VERIF_EN           (`i_axi_a2x_1_A2X_VERIF_EN),    // Verification control enable 
       .MEM_MODE           (1),                // Mem mode
       .EARLY_DATA_EN      (1)                 // EARLY_DATA_EN 
      ) U_dclk_fifo (
       // Push side - Inputs
       .clk_push        (clk_push_i),
       .rst_push_n      (resetn_push_i),

       .push_req_n      (push_req_n_i),
       .data_in         (push2popaf_data_i),

       // Push side - Outputs
       .push_full       (dclk_push_full_o),
       .push_empty      (dclk_push_empty_o),

       // Push side - Unconnected / Tied off.
       .init_push_n     (1'b1), // Tied to 1'b1.
       .nxt_push_full   (dclk_nxt_push_full),
       .nxt_push_empty  (dclk_nxt_push_empty),
       .push_ae         (dclk_push_ae), // Unconnected, not necessary here.
       .push_hf         (dclk_push_hf), // Unconnected, not necessary here.
       .push_af         (dclk_push_af), // Unconnected, not necessary here.
       .push_error      (dclk_push_error), // Unconnected, not necessary here.
       .push_word_count (dclk_push_wcount), // Unconnected, not necessary here.
       .we_n            (we_n),
       .wr_addr         (wr_addr), 
       // Pop side - Inputs
       .clk_pop         (clk_pop_i),
       .rst_pop_n       (resetn_pop_i),
       .pop_req_n       (pop_req_n_i),

       // Pop side - Outputs
       .pop_empty       (dclk_pop_empty_o),
       .data_out        (spush2popaf_data_o),


       // Pop side - Unconnected / tied off
       .init_pop_n      (1'b1), // Never using diagnostic mode.
       .nxt_pop_full    (dclk_nxt_pop_full), // Unconnected, not necessary here.
       .nxt_pop_empty   (dclk_nxt_pop_empty),
       .pop_ae          (dclk_pop_ae), // Unconnected, not necessary here.
       .pop_hf          (dclk_pop_hf), // Unconnected, not necessary here.
       .pop_af          (dclk_pop_af), // Unconnected, not necessary here.
       .pop_full        (dclk_pop_full), // Unconnected, not necessary here.
       .pop_error       (dclk_pop_error), // Unconnected, not necessary here.
       .pop_word_count  (dclk_pop_wcount), // Unconnected, not necessary here.
       .rd_n            (),
       .rd_addr         ()
     );

     assign push_full_o  = dclk_push_full_o;
     assign push_empty_o = dclk_push_empty_o;
     assign pop_empty_o  = dclk_pop_empty_o; 

     assign data_o      = dclk_data_o; 
     assign pop_count   = dclk_pop_wcount;
     assign push_count  = dclk_push_wcount;
     
   end  // DUAL_CLK
 endgenerate
  
  //--------------------------------------------------------------------
  // Connect either dual or single clock fifo output signals.
  //--------------------------------------------------------------------

endmodule
//Revision: $Id: //dwh/DW_ocb/DW_axi_a2x/axi_dev_br/src/DW_axi_a2x_fifo.v#15 $

