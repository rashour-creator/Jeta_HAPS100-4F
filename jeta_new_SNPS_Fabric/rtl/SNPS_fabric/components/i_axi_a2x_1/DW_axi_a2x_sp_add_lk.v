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
// Revision: $Id: //dwh/DW_ocb/DW_axi_a2x/axi_dev_br/src/DW_axi_a2x_sp_add_lk.v#2 $ 
// --------------------------------------------------------------------
*/

`include "DW_axi_a2x_all_includes.vh"
// **************************************************************************************
// SP Locked Control
//
// When a Locked Transaction is detected on the AW/AR FIFO the A2X must ensure
// that the are no outstanding transaction on AXI SP before sending the locked
// transaction. 
//
// When an unlock transaction is detected on the AW/AR FIFO the A2X must ensure
// that the are no outstanding transaction on AXI SP before sending the locked
// transaction. 
//
// The A2X must then wait for the unlock response to be returned to the A2X 
// before sending any additional transactions. 
//
// **************************************************************************************
module i_axi_a2x_1_DW_axi_a2x_sp_add_lk(/*AUTOARG*/
  // Outputs
  trans_en, lock_req_o, unlock_req_o, os_unlock, alock_o, a_pyld_o,
  // Inputs
  clk, resetn, a_active, a_fifo_empty, sp_os_fifo_valid,
  lock_req_i, lock_grant, 
  unlock_req_i, 
  unlock_grant, lockseq_cmp, 
  a_ready_i, lock_last, a_pyld_i
);

  // **************************************************************************************
  // Parameter Decelaration
  // **************************************************************************************
  parameter A2X_PP_MODE       = 0; 
  parameter A2X_CHANNEL       = 0; 
  parameter A2X_DOWNSIZE      = 0; 
  parameter A2X_UPSIZE        = 0; 
  parameter A2X_AW            = 32;
  parameter A2X_BLW           = 4;
  parameter A2X_ASBW          = 1;
  parameter A2X_QOSW          = 1;
  parameter A2X_REGIONW       = 1;
  parameter A2X_DOMAINW       = 1;
  parameter A2X_WSNOOPW       = 1;
  parameter A2X_BARW          = 1;
  parameter A2X_PYLD_I        = 32;

  // locked State Machine
  localparam [2:0] IDLE                     = 3'b000; 
  localparam [2:0] LOCK_REQ                 = 3'b001; 
  localparam [2:0] LOCK                     = 3'b010; 
  localparam [2:0] UNLOCK_REQ               = 3'b011; 
  localparam [2:0] UNLOCK_TRANS             = 3'b100; 
  localparam [2:0] UNLOCK_CMP               = 3'b101; 
  localparam [2:0] UNLOCK_RS                = 3'b110; 

  // **************************************************************************************
  // I/O Decelaration
  // **************************************************************************************
  input                                      clk;               // clock
  input                                      resetn;            // asynchronous reset

  input                                      a_active;          // SP Active 
  input                                      a_fifo_empty;      // Address FIFO
  input                                      sp_os_fifo_valid;  // Address FIFO
  input  [A2X_PYLD_I-1:0]                    a_pyld_i;

  input                                      lock_req_i;        // Lock Request From Another channel
  input                                      lock_grant;        // Lock Grant
  //spyglass disable_block W240
  //SMD: An input has been declared but is not read.
  //SJ : This signal is used in specific config only 
  input                                      unlock_req_i;      // Unlock Request From Another channe
  //spyglass enable_block W240
  input                                      unlock_grant;      // Unlock Grant
  input                                      lockseq_cmp;       // Lock Sequence Complete
  input                                      a_ready_i;         // Secondary Port Channel Ready
  input                                      lock_last;         // Last Lock Transaction - Used for Downsizing and Upsizing

  output                                     trans_en;          // Enable Transaction
  output                                     lock_req_o;        // Lock Request From this Channel
  output                                     unlock_req_o;      // UnLock Request From this Channel
  output                                     os_unlock;         // Outstanding Unlock Transaction from this channel. 
  output [`i_axi_a2x_1_A2X_LTW-1:0]                      alock_o;           // Lock bits Output
  output [A2X_PYLD_I-1:0]                    a_pyld_o;

  // **************************************************************************************
  // Signal Decelaration
  // **************************************************************************************
  reg   [2:0]                                nxtlk_state;
  reg   [2:0]                                lk_state;
  wire                                       lk_stchange;

  reg                                        lock_req_r;
  reg                                        unlock_req_r;
  reg                                        os_unlock_r; 

  wire   [`i_axi_a2x_1_A2X_IDW-1:0]                      aid_i;             // Payload
  wire   [A2X_AW-1:0]                        aaddr_i; 
  wire   [A2X_BLW-1:0]                       alen_i; 
  wire   [`i_axi_a2x_1_A2X_BSW-1:0]                      asize_i;     
  wire   [`i_axi_a2x_1_A2X_BTW-1:0]                      aburst_i;   
  wire   [`i_axi_a2x_1_A2X_LTW-1:0]                      alock_i;   
  wire   [`i_axi_a2x_1_A2X_CTW-1:0]                      acache_i; 
  wire   [`i_axi_a2x_1_A2X_PTW-1:0]                      aprot_i; 
  wire   [A2X_ASBW-1:0]                      asideband_i;
  wire   [A2X_QOSW-1:0]                      aqos_i;
  wire   [A2X_REGIONW-1:0]                   aregion_i;
  wire   [A2X_DOMAINW-1:0]                   adomain_i;
  wire   [A2X_WSNOOPW-1:0]                   asnoop_i;
  wire   [A2X_BARW-1:0]                      abar_i;
  wire   [`i_axi_a2x_1_A2X_RSW-1:0]                      aresize_i;
  wire                                       hburst_type;

  assign {abar_i, asnoop_i, adomain_i, aregion_i, aqos_i, hburst_type, asideband_i, aid_i, aaddr_i, aresize_i, alen_i, 
  asize_i, aburst_i, alock_i, acache_i, aprot_i} = a_pyld_i;
  assign a_pyld_o = {abar_i, asnoop_i, adomain_i, aregion_i, aqos_i,hburst_type, asideband_i, aid_i, aaddr_i, aresize_i,
  alen_i, asize_i, aburst_i, alock_o, acache_i, aprot_i};

  // **************************************************************************************
  // Locked Transactions
  // - In AHB Mode the A2X responds to a locked transaction by driving hready
  //   low. So if a locked read is generated by the AHB then all write
  //   transaction must be completed i.e. no transaction in AW FIFO and not
  //   outstanding transactions. 
  // 
  //   IDLE                     = 0; 
  //   LOCK_REQ                 = 1; 
  //   LOCK                     = 2; 
  //   UNLOCK_REQ               = 3; 
  //   UNLOCK_TRANS             = 4; 
  //   UNLOCK_CMP               = 5; 
  //   UNLOCK_RS                = 6; 
  // **************************************************************************************
  //spyglass disable_block W415a
  //SMD: Signal may be multiply assigned (beside initialization) in the same scope.
  //SJ : nxtlk_state is initialized to lk_state before updating based on value of lk_state
  always @(*) begin: LKSM_PROC
    nxtlk_state = lk_state;
    case (lk_state)
      IDLE: begin
        // A Lock Transaction detected.
        if ((!a_active) && (((!a_fifo_empty) && sp_os_fifo_valid && (alock_i==2'b10)) || lock_req_i))
          nxtlk_state = LOCK_REQ; 
      end
      LOCK_REQ: begin
        // Wait until Request granted.  
        // - Request Granted when both AR and AW has no more OS transactions. 
        if (lock_grant) 
          nxtlk_state = LOCK; 
      end
      LOCK: begin
        //  Constant condition expression
        //  This module is used for in several instances and the value depends on the instantiation. 
        //  Hence below usage cannot be avoided. This will not cause any funcational issue. 
        // Remain in this state until unlock request detected.
        if (A2X_PP_MODE==0) begin
          // In AHB Unlock Transaction generated on PP Write channel
          // and does not need to be broken into multiple transactions. 
          if (A2X_CHANNEL==0) begin
            if ((!a_active) && ((!a_fifo_empty) && sp_os_fifo_valid && (alock_i!=2'b10)))
              nxtlk_state = UNLOCK_REQ;           
          end else begin 
            if (unlock_req_i && a_fifo_empty && sp_os_fifo_valid && (!a_active))
              nxtlk_state = UNLOCK_CMP;          
          end
        end else begin
          // In AXI Unlock Transaction generated from Write/Read Channel. 
          // and can be broken into multiples i.e. Upsizing or Downsizing Config.
          // Boolean expression in conditional statement is always false.
          // Under certain configuration this branch will become true. 
          // This will not cause any functional issue.
          if ( (A2X_DOWNSIZE==1) || (A2X_UPSIZE==1) ) begin
            if ((!a_active) && (!a_fifo_empty) && sp_os_fifo_valid && (alock_i!=2'b10)) begin
              nxtlk_state = UNLOCK_RS;
            end if (unlock_req_i) begin
              nxtlk_state = UNLOCK_CMP;
            end 
          end else begin
            // In AXI Unlock Transaction generated from Write/Read Channel. 
            // and is not broken into multiples
            if (unlock_req_i)
              nxtlk_state = UNLOCK_CMP;
            else if ((!a_active) && (!a_fifo_empty) && sp_os_fifo_valid && (alock_i!=2'b10)) begin
              nxtlk_state = UNLOCK_REQ;
            end
          end
        end
      end
      UNLOCK_RS: begin
        // If Last transaction of an Locking Sequence Generate a unlock request. 
        // NTL_CDC03: Divergence found in clock domain crossing path
        // In AHB Mode the Unlock transaction is a single SP Transaction. So
        // we'll never be in this state in AHB. However its worth noting that
        // a path exists from the write SNF FIFO wlast bit to this lock_last
        // in AHB Configs. The SNF FIFO wlast bit is used to determmine if
        // a transaction was ebt'd early, thus asserting alast early. The
        // singal trans_en is generated from this state and used to control
        // the popping of the FIFO's. This logic may have to be revised if
        // lint reports this as an error.
        if (lock_last)
          nxtlk_state = UNLOCK_REQ;
      end
      UNLOCK_REQ: begin
        if (unlock_grant)
          nxtlk_state = UNLOCK_TRANS; 
      end
      UNLOCK_TRANS: begin
        //  This module is used for in several instances and the value depends on the instantiation. 
        //  Hence below usage cannot be avoided. This will not cause any funcational issue. 
        if (A2X_PP_MODE==0) begin
          if ((A2X_CHANNEL==1) && lockseq_cmp)
            nxtlk_state = IDLE;
          else if ((A2X_CHANNEL==0) && a_ready_i && (!a_fifo_empty) && sp_os_fifo_valid)
            nxtlk_state = UNLOCK_CMP;
        end else begin
          if (a_ready_i && sp_os_fifo_valid && (((!a_active) && (!a_fifo_empty)) || a_active))
            nxtlk_state = UNLOCK_CMP;
        end
      end
      UNLOCK_CMP: begin
        // Unlock Transaction Completed.
        if (lockseq_cmp) begin 
          nxtlk_state = IDLE;
        end
      end
      default: begin
        nxtlk_state = lk_state;
      end
    endcase
  end
    // spyglass enable_block W415a
  
  // State Machine Register Procedure
  always @ (posedge clk or negedge resetn) begin: lksm_PROC
    if (resetn == 1'b0) begin
      lk_state <= 3'b0;
    end else  begin
      lk_state <= nxtlk_state;
    end 
  end
  
  assign lk_stchange = (nxtlk_state != lk_state); 
  
  // **************************************************************************************
  // Enabled Transactions when 
  // - Not requesting a locked transaction or 
  // - Not requesting an unlock transaction
  // - Not waiting for a unlock response. 
  // **************************************************************************************
  assign trans_en    = ((lk_state==IDLE) & (~lk_stchange)) | ((lk_state==LOCK) & (~lk_stchange)) | (lk_state==UNLOCK_TRANS) | ((lk_state==UNLOCK_RS) & (~lk_stchange));
  
  // **************************************************************************************
  // Generate Lock Output
  // **************************************************************************************
  reg [1:0] alock_r;
  always @ (posedge clk or negedge resetn) begin: alock_r_PROC
    if (resetn == 1'b0) begin
      alock_r <= 2'b0;
    end else  begin
      if ((lk_state==IDLE) && (!a_fifo_empty) && (!a_active)) 
        alock_r <= alock_i;
      else if ((lk_state==LOCK_REQ) && lock_grant)
        alock_r <= 2'b10;
    end 
  end 

  reg [1:0] alock_r2;
  always @ (posedge clk or negedge resetn) begin: alock_r2_PROC
    if (resetn == 1'b0) begin
      alock_r2 <= 2'b0;
    end else  begin
      if ((lk_state!=IDLE) && (!a_fifo_empty) && (!a_active)) 
        alock_r2 <= alock_i;
    end 
  end 

  assign alock_o = (lk_state==UNLOCK_TRANS)? alock_r2 : (lk_state!=IDLE)? alock_r : (a_active)? alock_r : alock_i; 

  // **************************************************************************************
  // Generate Locked Request
  // **************************************************************************************
  always @ (posedge clk or negedge resetn) begin: lock_req_PROC
    if (resetn == 1'b0) begin
      lock_req_r <= 1'b0;
    end else  begin
      if (lock_grant)
        lock_req_r <= 1'b0;
      else if ( (lk_state==IDLE) && (!a_active) && ((!a_fifo_empty) && sp_os_fifo_valid && (alock_i==2'b10)))
        lock_req_r <= 1'b1;
    end 
  end 
  assign lock_req_o =  lock_req_r;
  
  // **************************************************************************************
  // Generate UnLock Request
  // **************************************************************************************
  always @ (posedge clk or negedge resetn) begin: unlock_req_PROC
    if (resetn == 1'b0) begin
      unlock_req_r <= 1'b0;
    end else begin
      if (unlock_grant)
        unlock_req_r <= 1'b0;
      else if (nxtlk_state==UNLOCK_REQ)
        unlock_req_r <= 1'b1;
    end 
  end

  // In AHB Only write Channel Generates Unlock Request
  assign unlock_req_o = (A2X_PP_MODE==1)? unlock_req_r : (A2X_CHANNEL==0)? unlock_req_r : 1'b0;
  
  // **************************************************************************************
  // Assert to indicate Outstanding unlock transaction 
  // **************************************************************************************
  // In AHB Unlock Transaction is generated from the AW Channel  
  always @ (posedge clk or negedge resetn) begin: osunlock_PROC
    if (resetn == 1'b0) begin
      os_unlock_r <= 1'b0;
    end else begin
      if (lockseq_cmp) 
        os_unlock_r <= 1'b0;
      else if ((A2X_PP_MODE==0) && (lk_state==UNLOCK_TRANS) && a_ready_i && (!a_fifo_empty) && sp_os_fifo_valid)
        os_unlock_r <= 1'b1;
      else if ((A2X_PP_MODE==1) && (lk_state==UNLOCK_TRANS) && a_ready_i && sp_os_fifo_valid && (((!a_active) && (!a_fifo_empty)) || a_active))
        os_unlock_r <= 1'b1;
    end 
  end
  assign os_unlock = (A2X_PP_MODE==1)? os_unlock_r : (A2X_CHANNEL==0)? os_unlock_r : 1'b0;

endmodule
