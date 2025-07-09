/* --------------------------------------------------------------------
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
// File Version     :        $Revision: #1 $ 
// Revision: $Id: //dwh/DW_ocb/DW_axi_a2x/amba_dev/src/DW_axi_a2x_sp_add_ws.v#1 $ 
// --------------------------------------------------------------------
*/

`include "DW_axi_a2x_all_includes.vh"
// **************************************************************************************
// Wrap Splitter 
//
// Calculates next Address so mimus one to get last address in transaction.
// **************************************************************************************
module i_axi_a2x_DW_axi_a2x_sp_add_ws (/*AUTOARG*/
  clk, resetn, wrap, addr_i, alast_ac, a_ready_i, a_fifo_empty, sp_os_fifo_vld, active_ac,
  size_i, alen_i, alast_as, active_as, second_burst, split, addr2, alen2, snf_wlast,
  trans_en
);
    
  // **************************************************************************************
  // Parameters
  // **************************************************************************************
  parameter  A2X_PP_MODE         = 0; 
  parameter  A2X_AW              = 32;
  parameter  A2X_PP_MAX_SIZE     = 6; 
  parameter  A2X_BLW             = 4; 

  // State Machine Encodings
  localparam STATE_W             = 1;
  localparam IDLE                = 1'b0;  
  localparam SPLIT               = 1'b1;  

  localparam ADDR_MASKW          = 13;

  // **************************************************************************************
  // I/O & Signal Decelaration
  // **************************************************************************************
  input                                      clk;
  input                                      resetn;
  input                                      a_ready_i;
  input                                      trans_en; 
  input                                      a_fifo_empty;
  input                                      sp_os_fifo_vld;
  input                                      active_ac;
  input   [A2X_AW-1:0]                       addr_i;
  input                                      alast_ac;
  input   [31:0]                             alen_i;
  output                                     alast_as;
  input                                      wrap;             // Transaction is Wrap
  //spyglass disable_block W240
  //SMD: An input has been declared but is not read.
  //SJ : Input siu_rbuf_mode is read only when BYPASS_SNF_R = 0.
  input                                      snf_wlast; 
  input   [`A2X_BSW-1:0]                     size_i;   
  //spyglass enable_block W240
  output                                     active_as;
  output                                     second_burst;     // Second Wrap Burst
  output                                     split;
  output [A2X_AW-1:0]                        addr2;            // Second Transaction Length
  output [7:0]                               alen2;            // Second Transaction Length
  
  reg    [STATE_W-1:0]                       nxt_state;        // state Machine
  reg    [STATE_W-1:0]                       state_r;

  reg                                        active_r;         // Active

  reg    [7:0]                               beat_addr;        // Beat address (Address within Data Width)

  reg    [ADDR_MASKW-1:0]                    addr_mask;        // Second Transaction Mask (Boundary Address)
  reg    [A2X_AW-1:0]                        addr2;            // Second Transaction Length
  reg    [7:0]                               alen2;            // Second Transaction Length

  wire                                       ahb_wrap_ebt;
  
  // **************************************************************************************
  // **************************************************************************************
  wire   aligned  = (beat_addr==8'd0) ? 1'b1 : 1'b0;

  // snf_wlast used to indicate transaction EBT'd before the wrap boundary. 
  // If true then wrap boundary address not transmitted. 
  assign ahb_wrap_ebt = (A2X_PP_MODE==1)? 1'b0 : (state_r==IDLE) & snf_wlast; 

  assign split        = wrap & (~aligned); 
  assign alast_as     = ((!split) | ahb_wrap_ebt)? alast_ac : (split & second_burst)? alast_ac : 1'b0;

  // **************************************************************************************
  // State Machine
  //    
  // IDLE State:
  // - If Transaction is a Wrap generate First Address and transtition to SPLIT
  //   state.
  //   Address is PP Address with length adjusted to issue an INCR
  //   transaction to the Upper Boundary
  // Split State:
  // - When Address Calculator has completed generate secondar address and
  //   transtition to IDLE State. 
  //   Address is from the Lower Boundary with length adjusted to issue an
  //   INCR transaction upto to the Orginal PP address
  //
  // Example: PP Address: 0x93AA4
  //          PP Length:  0xF
  //          PP size:    2
  //          PP Burst:   WRAP
  // This translates to two SP transactions, the 1st with
  //          SP Address: 0x93AA4
  //          SP Length:  0x6
  //          SP Size:    2    
  //          PP Burst:   INCR 
  // and a second transaction with          
  //          SP Address: 0x93A80
  //          SP Length:  0x8
  //          SP Size:    2    
  //          PP Burst:   INCR 
  //
  // **************************************************************************************
  // Combinatorial Procedure
  wire a_valid_init = trans_en & (((!active_ac) & alast_ac & (!a_fifo_empty) & sp_os_fifo_vld) | (active_ac & alast_ac & sp_os_fifo_vld));
  always @(*) begin: stnxt_PROC
    nxt_state = state_r;
    case (state_r)
      IDLE: begin
        if (split && a_ready_i && a_valid_init && (!ahb_wrap_ebt)) begin
          nxt_state = SPLIT;
        end
      end
      default: begin
        if (trans_en && a_ready_i && sp_os_fifo_vld && alast_ac) begin
          nxt_state = IDLE;
        end
      end
    endcase // case(state_r)
  end // always @ (*)
  
  // Registered Procedure
  always @ (posedge clk or negedge resetn) begin: st_PROC
    if (resetn == 1'b0) begin
      state_r <= IDLE;         
    end else  begin
      state_r <= nxt_state;      
    end 
  end 

  assign  second_burst = (state_r == IDLE) ? 1'b0 : 1'b1;

  // **************************************************************************************
  // Wrap Splitter Active
  //  
  // When asserted this indicates that the Wrap Splitted in Active and
  // splitting a wrapped transaction into INCR.
  // **************************************************************************************
  always @ (posedge clk or negedge resetn) begin: active_PROC
    if (resetn==1'b0) begin
      active_r <= 1'b0; 
    end else begin
      if (nxt_state==SPLIT)
        active_r <= 1'b1; 
      else 
        active_r <= 1'b0; 
    end
  end
  
  assign active_as = active_r;
      
   // **************************************************************************************
   // Addess Decode 
   //
   // Calculates the Second Address for a Wrap Transaction.
   // **************************************************************************************
   // Address Mask
   //spyglass disable_block W415a
   //SMD: Signal may be multiply assigned (beside initialization) in the same scope.
   //SJ : addr_mask is assigned in each iteration to decode the address. It is initialized to avoid latches.
   always @(*) begin : addr_mask_PROC
     integer i;
     integer j;
     addr_mask = {{(ADDR_MASKW-1){1'b1}},{1'b0}};
     for (j=1; j<= A2X_PP_MAX_SIZE; j=j+1)
       if (size_i==j) addr_mask = addr_mask<<j;
     for (i=1 ; i <= A2X_BLW; i=i+1)
       if (alen_i==(1'b1<<(i+1))-1) addr_mask=addr_mask<<i;
   end
      
   // Beat Address
   //spyglass disable_block W486
   //SMD: Reports shift overflow operations
   //SJ : This is not a functional issue, this is as per the requirement.
   //spyglass disable_block W164a
   //SMD: Identifies assignments in which the LHS width is less than the RHS width
   //SJ : This is not a functional issue, this is as per the requirement.
   always @(*) begin : beat_addr_PROC
     integer i;
     integer j;
     reg [A2X_BLW-1:0] addr_size;
     beat_addr = 8'b0;
     addr_size = addr_i[A2X_BLW-1:0]; 
     for (j=1; j<= A2X_PP_MAX_SIZE;j=j+1) 
       if (size_i==j) addr_size = addr_i>>j;
     for (i=0 ; i < A2X_BLW; i=i+1)
       if (alen_i[i]==1'b1) beat_addr[i]=addr_size[i];
   end
   //spyglass enable_block W164a
   //spyglass enable_block W486
   //spyglass enable_block W415a

   // **************************************************************************************
   // Second SPlit Address Generation
   // PP Address is the Lower Boundary Address
   // **************************************************************************************
   always @(posedge clk or negedge resetn) begin: addr2_PROC
     if (resetn == 1'b0) begin
       addr2      <= {A2X_AW{1'b0}};
       alen2      <= 8'd0;
     end else  begin
       addr2      <= {addr_i[A2X_AW-1:ADDR_MASKW], addr_i[ADDR_MASKW-1:0]&addr_mask};
       alen2      <= beat_addr-1;
     end 
   end

endmodule
