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
// File Version     :        $Revision: #11 $ 
// Revision: $Id: //dwh/DW_ocb/DW_axi_a2x/axi_dev_br/src/DW_axi_a2x_b_uid.v#11 $ 
**
** --------------------------------------------------------------------
*/
//*************************************************************************************
// UID Response Control
//
// - Decodes the Write Response channel from the SP to Primary Port Responses. 
// - when Upsizing/Downsizing or in SNF Mode the Primary Port address can be
//   broken into multpiple SP address. The responses for these Address need to
//   be combined into one response for the Primary Port. 
//
// - In AHB Mode only responses for Non-Bufferable Transactions pushed into PP
//   FIFO. The a2x_h2x module generates the bufferable responses. 
//*************************************************************************************

`include "DW_axi_a2x_all_includes.vh"

module i_axi_a2x_2_DW_axi_a2x_b_uid (/*AUTOARG*/
   // Outputs
   uid_fifo_full, uid_fifo_empty, uid_b_fifo_push_n, uid_b_pyld, uid_fifo_match,
   // Inputs
   clk, resetn, awvalid_sp, awready_sp, awid_sp, aw_last_sp, aw_nbuf_sp, uid_wr_en,
   bvalid_sp, bready_sp, b_pyld_sp
   );

  //*************************************************************************************
  // Parameter Decelaration
  //*************************************************************************************
  parameter  A2X_PP_MODE          = 1; 
  parameter  A2X_BRESP_ORDER      = 1;
  parameter  A2X_OSW_LIMIT        = 4; 
  parameter  A2X_OSW_LIMIT_LOG2   = 2;
  parameter  A2X_EQSIZED          = 1; 

  parameter  A2X_BSBW             = 1;
  parameter  B_PYLD_W             = 32; 

  localparam A2X_B_W              = `i_axi_a2x_2_A2X_IDW + `i_axi_a2x_2_A2X_BRESPW;
  localparam AWLAST_PYLD_W        = 2;  // Non-Bufferable and AW Last

  //*************************************************************************************
  // I/O Decelaration
  //*************************************************************************************
  //spyglass disable_block W240
  //SMD: An input has been declared but is not read.
  //SJ : These inputs are used in specific config only 
  input                                      clk;
  input                                      resetn;
  input                                      awvalid_sp; 
  input                                      awready_sp;
  input  [`i_axi_a2x_2_A2X_IDW-1:0]                      awid_sp;
  input                                      aw_last_sp;
  input                                      aw_nbuf_sp; 
  input                                      bvalid_sp;
  input                                      bready_sp;
  input  [B_PYLD_W-1:0]                      b_pyld_sp;

  input                                      uid_wr_en;
  output                                     uid_fifo_full;
  output                                     uid_fifo_empty;
  output                                     uid_fifo_match;

  output                                     uid_b_fifo_push_n;
  output [B_PYLD_W-1:0]                      uid_b_pyld;

  //spyglass enable_block W240

  //*************************************************************************************
  // Signal Decelaration
  //*************************************************************************************
  wire  [`i_axi_a2x_2_A2X_IDW-1:0]                       bid_sp;
  wire  [`i_axi_a2x_2_A2X_BRESPW-1:0]                    bresp_sp;
  wire  [A2X_BSBW-1:0]                       bsideband_sp;

  wire                                       bid_match;
  wire                                       aid_match;

  //These nets are used to connect the logic under certain configuration.
  //But this may not drive some of the nets. This will not cause any functional issue.
  reg   [`i_axi_a2x_2_A2X_IDW-1:0]                       uid_r;
  reg                                        uid_active_r; 

  wire                                       awlast_fifo_o;  
  wire                                       aw_nbuf_fifo_o;  

  wire                                       fifo_push_n;
  wire                                       fifo_pop_n;
  wire                                       fifo_empty;
  wire                                       fifo_full;
  wire  [AWLAST_PYLD_W-1:0]                  fifo_pyld_i;
  //Unconnected wire for BCM
  wire  [A2X_OSW_LIMIT_LOG2:0]               fifo_pop_count;
  wire  [AWLAST_PYLD_W-1:0]                  fifo_pyld_o;
  wire                                       unconn_1;
  wire  [A2X_OSW_LIMIT_LOG2:0]               fifo_push_count;

  //These nets are used to connect the logic under certain configuration.
  //But this may not drive some of the nets. This will not cause any functional issue.
  reg   [`i_axi_a2x_2_A2X_BRESPW-1:0]                    uid_resp_r;
  wire  [`i_axi_a2x_2_A2X_BRESPW-1:0]                    uid_resp;
  wire  [A2X_BSBW-1:0]                       uid_sideband;

  wire                                       awlast_fifo_i;
  wire                                       b_last_int; 

 //*************************************************************************************
 // Payload Decode
 //*************************************************************************************
 assign {bsideband_sp, bid_sp, bresp_sp} = b_pyld_sp;

 //*************************************************************************************
 // UID Register
 //
 // If response returned in order then uid_r is not required. Since response
 // always returned in the same order as the Address is issued on the Secondary Port 
 // only one UID FIFO is required.
 //
 // If responses returned out of order only bid's matching this UID 
 // register are accepted. 
 //
 // Fifo count is used to reset uid_active, this is to ensure that no further
 // entries for the same ID exists in the UID FIFO. This A2X could have
 // sent out two PP AXI address exch broken into multiples. In this case we
 // don'y want to reset uid_active when arlast is seen for the first
 // transaction.
 //*************************************************************************************
 assign b_last_int = awlast_fifo_o & bvalid_sp & bready_sp & bid_match;

 always @(posedge clk or negedge resetn) begin: id_PROC
   if (resetn == 1'b0) begin
     uid_r        <= {(`i_axi_a2x_2_A2X_IDW){1'b0}};  
     uid_active_r <= 1'b0;
   end else begin
     if (uid_wr_en && awvalid_sp && awready_sp) begin
       uid_r        <= awid_sp;
       uid_active_r <= 1'b1;
     end else if ((fifo_push_count==1) && b_last_int) begin
       uid_r        <= {(`i_axi_a2x_2_A2X_IDW){1'b0}}; 
       uid_active_r <= 1'b0;
     end
   end
 end

 // Incoming Address/Data Matches Channel UID
 // Response returned in order then awid and bid are always valid. Otherwise
 // the awid and the bid must match the uid register.
 assign bid_match = (A2X_BRESP_ORDER==0) ? 1'b1 : (uid_r==bid_sp);
 assign aid_match = (A2X_BRESP_ORDER==0) ? 1'b1 : (uid_r==awid_sp);

 // Output ID matches to the uid_wr_en control logic
 assign uid_fifo_match = aid_match & uid_active_r;

  //*************************************************************************************
  // Response Control FIFO 
  //
  // This FIFO Stores information about the PP transaction Resizing.
  //
  // For Each SP Transaction Push the status of awlast into FIFO. When awlast
  // asserted high this indicates the last SP Transaction after resizing a PP
  // transaction.
  //
  // If in AHB Mode the Transaction Type must also be pushed into FIFO i.e
  // Bufferable or Non-Bufferable.
  //*************************************************************************************
  i_axi_a2x_2_DW_axi_a2x_fifo
   #(
     .DATA_W                                 (AWLAST_PYLD_W)
    ,.DEPTH                                  (A2X_OSW_LIMIT)
    ,.LOG2_DEPTH                             (A2X_OSW_LIMIT_LOG2)
  ) U_a2x_uid_b_fifo (
     .clk_push_i                             (clk)
    ,.resetn_push_i                          (resetn)
    ,.push_req_n_i                           (fifo_push_n)
    ,.data_i                                 (fifo_pyld_i)
    ,.push_full_o                            (fifo_full)
    ,.push_empty_o                           (unconn_1)
    ,.clk_pop_i                              (clk)
    ,.resetn_pop_i                           (resetn)
    ,.pop_req_n_i                            (fifo_pop_n)
    ,.pop_empty_o                            (fifo_empty)
    ,.data_o                                 (fifo_pyld_o)    
    ,.push_count                             (fifo_push_count)
    ,.pop_count                              (fifo_pop_count)
  );

  // Generate FIF Push if AW Channel Valid and Unique ID Valid
  assign fifo_push_n     = ~(uid_wr_en & awvalid_sp & awready_sp);

  // Generate Pop if B Channel Valid and Unidue ID Valid.
  assign fifo_pop_n      = !(bvalid_sp & bready_sp & bid_match & uid_active_r);

  // FIFO Input - awlast
  // For Equalled Sized configurations address never split into multiples hence awlast always 1. 
  assign awlast_fifo_i   = (A2X_EQSIZED==1)? 1'b1 : aw_last_sp;

  // FIFO Payload
  assign fifo_pyld_i     = (A2X_PP_MODE==0) ? {aw_nbuf_sp, awlast_fifo_i} : {1'b0, awlast_fifo_i};

  // FIFO Payload Output - awlast
  // For Equalled Sized configurations address never split into multiples hence awlast always 1. 
  assign awlast_fifo_o   = (A2X_EQSIZED==1)? 1'b1 : fifo_pyld_o[0];

  // Non-Bufferable Responses only considered in AHB Mode
  assign aw_nbuf_fifo_o  = (A2X_PP_MODE==0) ? fifo_pyld_o[1] : 1'b1;

 //*************************************************************************************
 // UID Response Flag Register
 // bresp_sp[1] - DECERR or SLVERR
 //
 // If an error returned on any of the B response for a particular PP
 // transaction store this result
 //
 // DECERR gets priroty over SLVERR
 //*************************************************************************************
 generate 
 if (A2X_EQSIZED!=1) begin: RESP
   always @(posedge clk or negedge resetn) begin: uid_resp_PROC
     if (resetn == 1'b0) begin
       uid_resp_r     <= `i_axi_a2x_2_AOKAY; 
     end else begin
       if ((~fifo_pop_n) && awlast_fifo_o) begin
         uid_resp_r     <= `i_axi_a2x_2_AOKAY; 
       end else if ((~fifo_pop_n) && bresp_sp[1]) begin
         uid_resp_r     <= bresp_sp | uid_resp_r;
       end
     end
   end

   // If Error detected on previous B responses return stored response otherwise
   // return SP B Channel  
   assign uid_resp     = bresp_sp | uid_resp_r;
   
   // Changing bsideband assign from
   // a) it is the last sideband data or if an error occures then this sideband data
   // to
   // b) it is always the last sideband data
   assign uid_sideband = bsideband_sp;
 end else begin
   assign uid_resp     = bresp_sp;
   assign uid_sideband = bsideband_sp;
 end
 endgenerate

  //*************************************************************************************
  // BRESP FIFO Control
  //*************************************************************************************
  // Only when awlast is seen is the UID Response pushed to the BRESP FIFO
  assign uid_b_fifo_push_n = !((!fifo_pop_n) & awlast_fifo_o & aw_nbuf_fifo_o);

  // Unique BID Payload 
  assign uid_b_pyld        = (bid_match)? {uid_sideband, bid_sp, uid_resp}          : {B_PYLD_W{1'b0}};

  // If SP AWID matches the UID then status of FIFO register must be sent to
  // AW Channel. If FIFO full then the SP cannot sent anyome addresses. 
  assign uid_fifo_full     = (aid_match & uid_active_r)? fifo_full : 1'b0;

  // Used by the SP Bresp Channel to drive bready_sp. If empty cannot accept
  // SP response channel. 
  assign uid_fifo_empty    = fifo_empty;

endmodule

