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
// File Version     :        $Revision: #14 $ 
// Revision: $Id: //dwh/DW_ocb/DW_axi_a2x/amba_dev/src/DW_axi_rs_tpi.v#14 $ 
**
** --------------------------------------------------------------------
**
** File     : DW_axi_rs_tpi.v
** Created  : 
** Abstract :
**
** --------------------------------------------------------------------
*/
`include "DW_axi_a2x_all_includes.vh"

module i_axi_a2x_1_DW_axi_rs_tpi (
 //inputs
  aclk_i,
  aresetn_i,
  valid_i,
  ready_i,
  payload_i,
  
 //outputs
  ready_o,
  valid_o,
  payload_o
);

  //parameters
  parameter TMO = 0; // 0 - pass through mode
                     // 1 - forward timing mode
                     // 2 - full timing mode
                     // 3 - backward timing mode
  parameter PLD_W = 32; // payload width

  // Timing mode Options
  localparam  RS_PSS_TMO = 0; 
  localparam  RS_FWD_TMO = 1; 
  localparam  RS_FUL_TMO = 2; 
  localparam  RS_BWD_TMO = 3; 

  //inputs
  input              aclk_i;    //clock
  input              aresetn_i; //reset
  input              ready_i;   //ready signal
  input              valid_i;   //valid signal
  input [PLD_W-1:0]  payload_i; //payload
  
  //outputs
  output             ready_o;
  output             valid_o;
  output [PLD_W-1:0] payload_o;

  wire             ready_o;
  wire             valid_o;
  wire [PLD_W-1:0] payload_o;
  
  generate if (TMO==1) begin: A_SP_PIPELINE 
  //////////////////////////////////////////////////////////////////////
  // forward timing mode
  // payload_i and valid_i have to be registered.
  //////////////////////////////////////////////////////////////////////
  reg              r_valid_fd;
  reg  [PLD_W-1:0] r_pld_fd;

  wire             s_ready_fd;
  wire             s_valid_fd;
  // wire [PLD_W-1:0] s_pld_fd;

  //--------------------------------------------------------------------
  //ready_o (s_ready_fd) generation
  //ready_o depends on ready_i and valid_o (r_valid_fd).
  //If valid_o low (no payload in register), ready_o should be high
  //which means the payload register can accept payload.
  //--------------------------------------------------------------------
  assign s_ready_fd = ready_i | (!r_valid_fd);

  
  //--------------------------------------------------------------------
  //valid_o (r_valid_fd) generation
  //valid_o depends on ready_o. If ready_o low (payload exists in the
  //register), keep previous value of valid_o.
  //--------------------------------------------------------------------
  assign s_valid_fd = s_ready_fd ? valid_i : r_valid_fd;

  always @( posedge aclk_i or negedge aresetn_i ) begin : r_valid_fd_PROC
    if ( !aresetn_i ) begin
      r_valid_fd <= 1'b0;
    end //if
    else begin
      r_valid_fd <= s_valid_fd;
    end //else
  end //always

  //--------------------------------------------------------------------
  //payload_o (r_pld_fd) loading
  //If ready_o high (payload register empty), payload_i loaded into the
  //payload register. If ready_o low, keep the payload in the register.
  //--------------------------------------------------------------------
  // assign s_pld_fd = s_ready_fd ? payload_i : r_pld_fd;

  always @( posedge aclk_i or negedge aresetn_i ) begin : r_pld_fd_PROC
    if ( !aresetn_i ) begin
      r_pld_fd <= {PLD_W{1'b0}};
    end //if
    else begin
      if (s_ready_fd) begin  
        r_pld_fd <= payload_i;
      end
    end //else
  end //always 

  assign ready_o   = s_ready_fd;
  assign valid_o   = r_valid_fd;
  assign payload_o = r_pld_fd;
  end //A_SP_PIPELINE_ONE
  

  else if(TMO==2) begin: A_SP_PIPELINE_TWO
  //////////////////////////////////////////////////////////////////////
  // full timing mode
  // all payload_i, ready_i and valid_i signals have to be registered.
  // use two payload registers to store payload and the two registers
  // organized as FIFO.
  //////////////////////////////////////////////////////////////////////
  reg              pointer_in;
  reg              pointer_out;
  reg  [1:0]       r_cnt;
  reg              r_ready_fl;
  reg              r_valid_fl;
  reg  [PLD_W-1:0] r_pld_fl_zero;
  reg  [PLD_W-1:0] r_pld_fl_one;

  wire             s_pointer_in;
  wire             s_pointer_out;
  wire [1:0]       s_cnt;
  wire [1:0]       ss_cnt;
  wire [1:0]       sss_cnt;
  wire             s_ready_fl;
  wire             ss_ready_fl;
  wire             s_ready_mux;
  wire             s_valid_fl;
  wire             ss_valid_fl;
  wire             s_valid_mux;
  wire [PLD_W-1:0] s_pld_fl;
  wire [PLD_W-1:0] s_pld_fl_zero;
  wire [PLD_W-1:0] s_pld_fl_one;
  
  //--------------------------------------------------------------------
  //pointer_in generation.Which payload register is for loading payload.
  //So if valid_i and ready_o high, pointer_in increases by 1.
  //--------------------------------------------------------------------
  assign s_pointer_in = ( valid_i & r_ready_fl ) ? 
                         !pointer_in : 
                          pointer_in;             

  always @( posedge aclk_i or negedge aresetn_i ) begin : pointer_in_PROC
    if ( !aresetn_i ) begin
      pointer_in <= 1'b0;
    end //if
    else begin
      pointer_in <= s_pointer_in;
    end //else
  end //always

  //--------------------------------------------------------------------
  //pointer_out generation. destination samples which payload register.
  //So if valid_o and ready_i high, pointer_out increases by 1.
  //--------------------------------------------------------------------
  assign s_pointer_out = ( r_valid_fl & ready_i ) ?
                          !pointer_out :
                           pointer_out;

  always @( posedge aclk_i or negedge aresetn_i ) begin : pointer_out_PROC
    if ( !aresetn_i ) begin
      pointer_out <= 1'b0;
    end //if
    else begin
      pointer_out <= s_pointer_out;
    end //else
  end //always

  //--------------------------------------------------------------------
  //r_cnt generation. Indicates the two registers full or empty.
  //If ready_i and valid_o high, r_cnt - 1;
  //If ready_o and valid_i high, r_cnt + 1;
  //If all the ready_i, ready_o, valid_i and valid_o high, r_cnt = r_cnt
  //If r_cnt = 2, two registers full.
  //If r_cnt = 0, two registers empty.
  //--------------------------------------------------------------------
  assign sss_cnt = ( ready_i & r_valid_fl ) ?
                   ( r_cnt - 2'h1 ) :
                     r_cnt;

  assign ss_cnt = ( r_ready_fl & valid_i ) ?
                  ( r_cnt + 2'h1 ) :
                    sss_cnt;

  assign s_cnt = ( valid_i & r_ready_fl & r_valid_fl & ready_i ) ?
                   r_cnt :
                   ss_cnt;

  always @( posedge aclk_i or negedge aresetn_i ) begin : r_cnt_PROC
    if ( !aresetn_i ) begin
      r_cnt <= 2'b0;
    end //if
    else begin
      r_cnt <= s_cnt;
    end //else
  end //always

  //--------------------------------------------------------------------
  //ready_o (r_ready_fl) generation
  //ready_o depends on ready_i and whether the two registers are full.
  //If ready_i and valid_o high (r_valid_fl) and r_cnt = 1, r_ready_fl
  //must go low at the next cycle if ready_i is not asserted.
  //default ready_o is 1'b1.
  //--------------------------------------------------------------------
  assign s_ready_mux = r_ready_fl & valid_i & (!(r_valid_fl & ready_i)) &
                       ( r_cnt == 2'b01 );

  assign ss_ready_fl = s_ready_mux ? 1'b0 : r_ready_fl;

  assign s_ready_fl = ready_i | ss_ready_fl;

  always @( posedge aclk_i or negedge aresetn_i ) begin : r_ready_fl_PROC
    if ( !aresetn_i ) begin
      r_ready_fl <= 1'b1;
    end //if
    else begin
      r_ready_fl <= s_ready_fl;
    end //else
  end //always

  //--------------------------------------------------------------------
  //valid_o (r_valid_fl) generation
  //valid_o depends on valid_i and whether the payload registers are
  //empty. So if ready_i and r_valid_fl(valid_o) are high and r_cnt=1,
  //r_valid_fl must go low at the next cycle if valid_i is not asserted.
  //--------------------------------------------------------------------
  assign s_valid_mux = r_valid_fl & ready_i & (!(valid_i & r_ready_fl)) &
                       ( r_cnt == 2'b01 );

  assign ss_valid_fl = s_valid_mux ? 1'b0 : r_valid_fl;

  assign s_valid_fl = valid_i | ss_valid_fl;

  always @( posedge aclk_i or negedge aresetn_i ) begin : r_valid_fl_PROC
    if ( !aresetn_i ) begin
      r_valid_fl <= 1'b0;
    end //if
    else begin
      r_valid_fl <= s_valid_fl;
    end //else
  end //always

  //--------------------------------------------------------------------
  //payload registers loading and sampling
  //If valid_i and ready_o high and pointer_in low, payload should be
  //loaded into payload register 0. If valid_i and ready_o high and 
  //pointer_in high, payload should go to payload register 1.
  //On the sampling side, if pointer_out low, pick up payload from
  //the payload register 0. If pointer_out high, pick up payload from
  //the payload register 1.
  //--------------------------------------------------------------------
  assign s_pld_fl_zero = ( valid_i & r_ready_fl & (!pointer_in) ) ?
                           payload_i :
                           r_pld_fl_zero;

  assign s_pld_fl_one = ( valid_i & r_ready_fl & pointer_in ) ?
                           payload_i :
                           r_pld_fl_one;

  always @( posedge aclk_i or negedge aresetn_i ) begin : r_pld_fl_zero_PROC
    if ( !aresetn_i ) begin
      r_pld_fl_zero <= {PLD_W{1'b0}};
    end //if
    else begin
      r_pld_fl_zero <= s_pld_fl_zero;
    end //else
  end //always
  
  always @( posedge aclk_i or negedge aresetn_i ) begin : r_pld_fl_one_PROC
    if ( !aresetn_i ) begin
      r_pld_fl_one <= {PLD_W{1'b0}};
    end //if
    else begin
      r_pld_fl_one <= s_pld_fl_one;
    end //else
  end //always

  assign s_pld_fl = pointer_out ? r_pld_fl_one : r_pld_fl_zero;
  
  assign payload_o = s_pld_fl;
  assign ready_o   = r_ready_fl;
  assign valid_o   = r_valid_fl;
  end //A_SP_PIPELINE_TWO

  else if (TMO==3) begin: A_SP_PIPELINE_THREE
  //////////////////////////////////////////////////////////////////////
  //backward register mode
  //only ready_i needs to be registered.
  //////////////////////////////////////////////////////////////////////
  reg              r_ready_bd;
  reg  [PLD_W-1:0] r_pld_bd;
  reg              r_sel;
  reg              r_valid_bd;

  wire             s_ready_bd;
  wire             s_valid_bd;
  wire             ss_valid_bd;
  wire             sss_valid_bd;
  wire [PLD_W-1:0] s_pld_bd;
  // wire [PLD_W-1:0] ss_pld_bd;
  wire             s_sel;
  wire             ss_sel;

  //--------------------------------------------------------------------
  //valid_o (s_valid_bd) generation
  //If ready_o low (one payload in the payload register), valid_o should
  //be high.
  //--------------------------------------------------------------------

  assign sss_valid_bd = r_ready_bd ? valid_i : r_valid_bd;

  always @( posedge aclk_i or negedge aresetn_i ) begin : r_valid_bd_PROC
    if ( !aresetn_i ) begin
      r_valid_bd <= 1'b0;
    end //if
    else begin
      r_valid_bd <= sss_valid_bd;
    end //else
  end //always

  assign ss_valid_bd = r_sel ? r_valid_bd : valid_i;

  
  assign s_valid_bd = ss_valid_bd | (!r_ready_bd);

  //--------------------------------------------------------------------
  //ready_o (r_ready_bd) generation
  //ready_o depends on ready_i and valid_o. If valid_o high (payload in
  //the register) and when ready_i high, the payload sampled. So
  //ready_o goes high at the next cycle (payload register empty).
  //default ready_o is 1'b1.
  //--------------------------------------------------------------------
  assign s_ready_bd = s_valid_bd ? ready_i : r_ready_bd;

  always @( posedge aclk_i or negedge aresetn_i ) begin : r_ready_bd_PROC
    if ( !aresetn_i ) begin
      r_ready_bd <= 1'b1;
    end //if
    else begin
      r_ready_bd <= s_ready_bd;
    end //else
  end //always

  //--------------------------------------------------------------------
  //r_sel generation. used to select payload from payload_i or from
  //payload register.
  //If ready_i low and valid_i high, payload not sampled by destination.
  //So s_sel goes high. If ready_i high, valid_i low and valid_o high,
  //payload sampled by destination. s_sel goes low.
  //--------------------------------------------------------------------
  assign ss_sel = ( s_valid_bd & ready_i & (!r_ready_bd) ) ? 1'b0 : r_sel;

  assign s_sel = ( valid_i & (!ready_i) ) | ss_sel;

  always @( posedge aclk_i or negedge aresetn_i ) begin : r_sel_PROC
    if ( !aresetn_i ) begin
      r_sel  <= 1'b0;
    end //if
    else begin
      r_sel  <= s_sel;
    end //else
  end //always

  //--------------------------------------------------------------------
  //payload loading and selection.
  //If r_sel is 0, payload_o (s_pld_bd) from payload_i.
  //If r_sel is 1, payload_o from payload register.
  //If ready_o high, payload_i always loaded to payload register.
  //--------------------------------------------------------------------
  // assign ss_pld_bd = r_ready_bd ? payload_i : r_pld_bd;

  always @( posedge aclk_i or negedge aresetn_i ) begin : r_pld_bd_PROC
    if ( !aresetn_i ) begin
      r_pld_bd <= {PLD_W{1'b0}};
    end //if
    else begin
      if (r_ready_bd) begin  
        r_pld_bd <= payload_i;
      end  
    end //else
  end //always

  assign s_pld_bd  = r_sel ? r_pld_bd : payload_i;
  
  assign payload_o = s_pld_bd;
  assign ready_o   = r_ready_bd;
  assign valid_o   = s_valid_bd;
  end //A_SP_PIPELINE_THREE

  else if (TMO==0) begin: A_SP_PIPELINE_ZERO
  assign payload_o = payload_i;
  assign ready_o   = ready_i;
  assign valid_o   = valid_i;
  end //A_SP_PIPELINE_ZERO
  endgenerate //TMO


endmodule
//Revision: $Id: //dwh/DW_ocb/DW_axi_a2x/amba_dev/src/DW_axi_rs_tpi.v#14 $
