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
// File Version     :        $Revision: #5 $ 
// Revision: $Id: //dwh/DW_ocb/DW_axi_a2x/axi_dev_br/src/DW_axi_a2x_r_uid.v#5 $ 
// --------------------------------------------------------------------
*/

`include "DW_axi_a2x_all_includes.vh"
//*************************************************************************************
// Unique Read ID Module 
//
// This module controls the 
// - Read Data Packing for Downsizing Configurations.
// - Read Data Unpacking Decoder for Upsizing Configs 
//   (Generates the Tag Bits to send with read Data)
// - Primary Port Read Data rlast generation.  As SP transaction can be broken
//   into multiple transactions we need to combin this into one Primary Port
//   transaction. 
//
//*************************************************************************************
module i_axi_a2x_2_DW_axi_a2x_r_uid (/*AUTOARG*/
   // Outputs
   r_pyld_o, r_fifo_push_n, uid_fifo_full, uid_fifo_empty, uid_fifo_match,
   // Inputs
   clk_sp, resetn_sp, arready_sp, arvalid_sp, arid_sp, 
   arlast_sp, sp_osar_pyld, rready_sp, rvalid_sp, 
   r_pyld_i, uid_wr_en
   );

  // **************************************************************************************
  // Parameter
  // **************************************************************************************
  parameter  A2X_PP_MODE                 = 0;
  parameter  A2X_UPSIZE                  = 0; 
  parameter  A2X_DOWNSIZE                = 0; 
  parameter  A2X_BLW                     = 4;
  parameter  A2X_RSBW                    = 1;  

  parameter  A2X_PP_ENDIAN               = 0; 
  parameter  A2X_SP_ENDIAN               = 0; 

  parameter  A2X_READ_ORDER              = 1;

  parameter  A2X_RS_RATIO                = 1; 

  parameter  A2X_PP_DW                   = 32;
  parameter  A2X_PP_MAX_SIZE             = 2;  
  parameter  A2X_PP_NUM_BYTES            = 4;
  parameter  A2X_PP_NUM_BYTES_LOG2       = 1;

  parameter  A2X_SP_DW                   = 32;
  parameter  A2X_SP_MAX_SIZE             = 2;  
  parameter  A2X_SP_NUM_BYTES            = 4;
  parameter  A2X_SP_NUM_BYTES_LOG2       = 1;

  parameter  A2X_OSR_LIMIT               = 4;
  parameter  A2X_OSR_LIMIT_LOG2          = 2;

  parameter  A2X_PP_PYLD_W               = 32;
  parameter  A2X_SP_PYLD_W               = 32;
  parameter  A2X_RUS_PYLD_W              = 32;
  parameter  A2X_RDS_PYLD_W              = 32;

  localparam A2X_R_FIFO_PYLD_W           = (A2X_UPSIZE==1)? (A2X_SP_PYLD_W + A2X_RS_RATIO) : (A2X_DOWNSIZE==1)? A2X_PP_PYLD_W : A2X_SP_PYLD_W;

  localparam A2X_URID_PYLD_W             = (A2X_UPSIZE==1)? A2X_RUS_PYLD_W + 1 : (A2X_DOWNSIZE==1)? A2X_RDS_PYLD_W +1 : `i_axi_a2x_2_A2X_BSW+1;

  localparam A2X_SP_OSAR_PYLD_W          = (A2X_DOWNSIZE==1)? A2X_RDS_PYLD_W : (A2X_UPSIZE==1)? A2X_RUS_PYLD_W : `i_axi_a2x_2_A2X_BSW; 

  localparam PP_ENDIAN_PYLD              = (A2X_DOWNSIZE==1)? A2X_PP_PYLD_W : A2X_SP_PYLD_W; 
  localparam PP_ENDIAN_DW                = (A2X_DOWNSIZE==1)? A2X_PP_DW     : A2X_SP_DW; 
  
  // **************************************************************************************
  // I/O Decelaration 
  // **************************************************************************************
  input                                       clk_sp;
  input                                       resetn_sp;

  input                                       arready_sp;         // SP AR Channel
  input                                       arvalid_sp;
  input  [`i_axi_a2x_2_A2X_IDW-1:0]                       arid_sp;

  input                                       arlast_sp;         // SP AR Last - Indicates the last SP transaction for a give PP transaction
  input  [A2X_SP_OSAR_PYLD_W-1:0]             sp_osar_pyld;           // Transaction resize Information. 

  input                                       rready_sp;         // SP R channel
  input                                       rvalid_sp;
  input  [A2X_SP_PYLD_W-1:0]                  r_pyld_i;
  output [A2X_R_FIFO_PYLD_W-1:0]              r_pyld_o;
  output                                      r_fifo_push_n;

  input                                       uid_wr_en;         // Unique RID Control
  output                                      uid_fifo_full;
  output                                      uid_fifo_empty;
  output                                      uid_fifo_match;

  // **************************************************************************************
  // Signal Decelaration
  // **************************************************************************************
  reg    [`i_axi_a2x_2_A2X_IDW-1:0]                       uid_r;                 // Unique ID Value
  reg                                         uid_active_r;
  wire                                        rid_match;
  wire                                        aid_match;

  wire                                        uid_fifo_push_n;       // UID FIFO Control
  wire                                        uid_fifo_pop_n;
  wire                                        uid_fifo_full_w;
  wire  [A2X_URID_PYLD_W-1:0]                 uid_pyld_i;
  wire  [A2X_URID_PYLD_W-1:0]                 uid_pyld_o;
  wire  [A2X_OSR_LIMIT_LOG2:0]                uid_fifo_pop_count;
  wire  [A2X_OSR_LIMIT_LOG2:0]                uid_fifo_push_count;

  wire   [A2X_RUS_PYLD_W-1:0]                 us_pyld_fifo_o;       // Resize FIFO 
  wire   [A2X_RDS_PYLD_W-1:0]                 ds_pyld_fifo_o;       // Resize FIFO 
  wire                                        arlast_fifo_o;        // Last AR Transaction

  //      Secondary Port Payload
  wire                                        rlast_sp;             // SP Read Data channel
  wire  [`i_axi_a2x_2_A2X_IDW-1:0]                        rid_sp;    
  wire  [A2X_SP_DW-1:0]                       rdata_sp; 
  wire  [`i_axi_a2x_2_A2X_RRESPW-1:0]                     rresp_sp; 
  wire  [A2X_RSBW-1:0]                        rsideband_sp;

  wire                                        rlast_pp;

  // Read Data Payload
  wire   [A2X_R_FIFO_PYLD_W-1:0]              r_pyld_pk;            // Read Data Packer/Unpacker 
  wire   [PP_ENDIAN_PYLD-1:0]                 r_pyld_pp_et_i;         
  wire   [PP_ENDIAN_PYLD-1:0]                 r_pyld_pp_et_o;         
  wire   [A2X_SP_PYLD_W-1:0]                  r_pyld_sp_i;         
  wire   [A2X_SP_PYLD_W-1:0]                  r_pyld_sp_et_o;         
  wire   [A2X_SP_PYLD_W-1:0]                  r_pyld_spc;
  wire   [A2X_RS_RATIO-1:0]                   r_pyld_tag;
  wire   [A2X_RS_RATIO-1:0]                   r_pyld_tag_w;
  wire                                        r_fifo_push_n_pk;
  wire                                        r_fifo_push_n_spc;

  wire                                        unconn_1;

  wire   [`i_axi_a2x_2_A2X_BSW-1:0]                       r_pp_size;
  wire   [`i_axi_a2x_2_A2X_BSW-1:0]                       r_sp_ds_size;
  wire   [`i_axi_a2x_2_A2X_BSW-1:0]                       r_sp_us_size;
  wire   [`i_axi_a2x_2_A2X_BSW-1:0]                       r_sp_size;
  wire                                        r_last_int;

  //*************************************************************************************
  // Decode Secondary Port Read Data Payload
  //*************************************************************************************
  assign {rsideband_sp, rid_sp, rresp_sp, rdata_sp, rlast_sp} = r_pyld_i;

  //*************************************************************************************
  // UID Register
  //
  // If reads returned in order or interleaved then uid_r is not required. Since response
  // always returned in the same order as the Address is issued on the Secondary Port only 
  // one URID FIFO is required.
  //
  // If responses returned out of order or interleaved then only rid's matching this UID register are accepted. 
  //
  // Fifo count is used to reset uid_active, this is to ensure that no further
  // entries for the same ID exists in the UID FIFO. This A2X could have
  // sent out two PP AXI address exch broken into multiples. In this case we
  // don'y want to reset uid_active when arlast is seen for the first
  // transaction.
  //
  // Push count equal to 1 used here to allow the registering of the uid_r.
  // When push count equals 1 and the condition below is true a pop is issued to the fifo. 
  //*************************************************************************************
  assign r_last_int =  rvalid_sp & rready_sp & rid_match & rlast_sp;
  always @(posedge clk_sp or negedge resetn_sp) begin: id_PROC
    if (resetn_sp == 1'b0) begin
      uid_r        <= {`i_axi_a2x_2_A2X_IDW{1'b0}}; 
      uid_active_r <= 1'b0;
    end else begin
      if (uid_wr_en && arvalid_sp && arready_sp) begin
        uid_r        <= arid_sp;
        uid_active_r <= 1'b1;
      end else if ((uid_fifo_push_count==1) && arlast_fifo_o && r_last_int) begin
        uid_r        <= {`i_axi_a2x_2_A2X_IDW{1'b0}}; 
        uid_active_r <= 1'b0;
      end
    end
  end

  // Incoming Address/Data are only matched if there is something in the UID fifo
  assign rid_match = (A2X_READ_ORDER==0) ? 1'b1 : (uid_r==rid_sp) & uid_active_r;
  assign aid_match = (A2X_READ_ORDER==0) ? 1'b1 : (uid_r==arid_sp);

  // Output ID match to the uid_wr_en control logic
  assign uid_fifo_match = aid_match & uid_active_r;
 
  //*************************************************************************************
  //                           URID FIFO
  //
  // Resize Information and Read Last information pushed into FIFO when AR
  // accepted on Secondary Port. Information popped off FIFO when read last received.
  //*************************************************************************************
  i_axi_a2x_2_DW_axi_a2x_fifo
   #(
     .DATA_W                                 (A2X_URID_PYLD_W)
    ,.DEPTH                                  (A2X_OSR_LIMIT)
    ,.LOG2_DEPTH                             (A2X_OSR_LIMIT_LOG2)
  ) U_a2x_r_osar_fifo (
     .clk_push_i                             (clk_sp)
    ,.resetn_push_i                          (resetn_sp)
    ,.push_req_n_i                           (uid_fifo_push_n)
    ,.data_i                                 (uid_pyld_i)
    ,.push_full_o                            (uid_fifo_full_w)
    ,.push_empty_o                           (unconn_1)
    ,.pop_req_n_i                            (uid_fifo_pop_n)
    ,.pop_empty_o                            (uid_fifo_empty)
    ,.data_o                                 (uid_pyld_o)    
    ,.clk_pop_i                              (clk_sp)      // Unused ports in Sync mode - Connecting for Lint Violations
    ,.resetn_pop_i                           (resetn_sp)
    ,.push_count                             (uid_fifo_push_count)
    ,.pop_count                              (uid_fifo_pop_count)
  );

  // UID Payload 
  // - PP Transaction Length (arlen_fifo_pp) only used for Upsized
  //   Configurations. Value driven to zero for all other configurations. 
  // - If non-Resizing Configuration rs_pyld driven to zero from sp_add module. 
  assign uid_pyld_i          = (A2X_UPSIZE==1) ? {sp_osar_pyld, arlast_sp} : (A2X_DOWNSIZE==1)? {sp_osar_pyld, arlast_sp} : {sp_osar_pyld,arlast_sp};

  // Generate Push  & Pop for URID FIFO. 
  assign uid_fifo_push_n     = !(arvalid_sp & arready_sp & uid_wr_en);
  assign uid_fifo_pop_n      = !(r_last_int & uid_active_r);

  assign arlast_fifo_o       = uid_pyld_o[0];
  // spyglass disable_block W164a
  // SMD: Identifies assignments in which the LHS width is less than the RHS width
  // SJ : This is not a functional issue, this is as per the requirement.
  //      Hence this can be waived.  
  // spyglass disable_block W164b
  // SMD: Identifies assignments in which the LHS width is greater than the RHS width
  // SJ : This is not a functional issue, this is as per the requirement.
  //      Hence this can be waived.  
  assign us_pyld_fifo_o      = (A2X_UPSIZE==0)  ? {A2X_RUS_PYLD_W{1'b0}} : uid_pyld_o[A2X_URID_PYLD_W-1:1];
  assign ds_pyld_fifo_o      = (A2X_DOWNSIZE==0)? {A2X_RDS_PYLD_W{1'b0}} : uid_pyld_o[A2X_URID_PYLD_W-1:1];
  // spyglass enable_block W164b
  // spyglass enable_block W164a

  //*************************************************************************************
  // Read Data FIFO 
  //*************************************************************************************
  // Primary Port Read data RLast
  assign rlast_pp        = rlast_sp & arlast_fifo_o;

  // Read Data FIFO Push 
  assign r_fifo_push_n_spc = !(rvalid_sp  & rready_sp  & rid_match);
  assign r_pyld_spc        = (rid_match)? {r_pyld_sp_et_o[A2X_SP_PYLD_W-1:1], rlast_pp}    : {A2X_SP_PYLD_W{1'b0}};

  // If SP ARID matches the UID then status of FIFO register must be sent to
  // AR Channel. If FIFO full then the SP cannot send anymore addresses. 
  assign uid_fifo_full  = (aid_match & uid_active_r)? uid_fifo_full_w : 1'b0;

  //*************************************************************************************
  // AXI Endian Convert 
  // - Only convert Little Endian to Big Endian BE8
  //*************************************************************************************
  // spyglass disable_block W164a
  // SMD: Identifies assignments in which the LHS width is less than the RHS width
  // SJ : The length of the net varies based on configuration. This will not cause functional issue.
  // spyglass disable_block W164b
  // SMD: Identifies assignments in which the LHS width is greater than the RHS width
  // SJ : This is not a functional issue, this is as per the requirement.
  generate
  if ((A2X_PP_MODE==1) && (A2X_PP_ENDIAN!=0)) begin: LE_TO_BE8     

    // Constant condition expression
    // This module is used for in several instances and the value depends on the instantiation. 
    // Hence below usage cannot be avoided. This will not cause any funcational issue. 
    if (A2X_DOWNSIZE==1) begin
      assign r_pp_size = uid_pyld_o[(`i_axi_a2x_2_A2X_BSW+A2X_PP_NUM_BYTES_LOG2+2)-1:A2X_PP_NUM_BYTES_LOG2+2];
    end else if (A2X_UPSIZE==1) begin
      assign r_pp_size =  uid_pyld_o[(`i_axi_a2x_2_A2X_BSW+A2X_SP_NUM_BYTES_LOG2+2)-1:A2X_SP_NUM_BYTES_LOG2+2];
    end else begin
      assign r_pp_size =  uid_pyld_o[A2X_URID_PYLD_W-1:1];
    end

    assign r_pyld_pp_et_i = (A2X_DOWNSIZE==1)? r_pyld_pk  : r_pyld_spc;
    i_axi_a2x_2_DW_axi_a2x_x2x_et
     #(
       .A2X_PYLD_W             (PP_ENDIAN_PYLD)
      ,.A2X_DW                 (PP_ENDIAN_DW) 
      ,.WRITE_CH               (0)  // write channel
    ) U_a2x_r_pp_et (
      // Outputs
       .pyld_o                 (r_pyld_pp_et_o) 
      // Inputs
      ,.pyld_i                 (r_pyld_pp_et_i) 
      ,.size_i                 (r_pp_size)
    );
    assign r_pyld_o = (A2X_DOWNSIZE==1)? r_pyld_pp_et_o   : (A2X_UPSIZE==1)? {r_pyld_tag_w, r_pyld_pp_et_o} : r_pyld_pp_et_o;
  end else begin
    assign r_pyld_o = (A2X_DOWNSIZE==1)? r_pyld_pk        : (A2X_UPSIZE==1)? {r_pyld_tag_w, r_pyld_spc} : r_pyld_spc;
  end
  endgenerate
  // spyglass enable_block W164b
  // spyglass enable_block W164a

  // Multiplex Read data FIFO Inputs based on configuration parameters. 
  assign r_fifo_push_n  = (A2X_DOWNSIZE==1)? r_fifo_push_n_pk : r_fifo_push_n_spc;

  //*************************************************************************************
  //Read Data Unpacker Dec
  //
  //- Generates a Tag to send with Read data for Upsizing Configs
  //*************************************************************************************
  generate 
    if (A2X_UPSIZE==1) begin: UPSIZE_UNPK
      i_axi_a2x_2_DW_axi_a2x_r_upk_dec
       #(
         .A2X_PP_MODE                           (A2X_PP_MODE)
        ,.A2X_RS_PYLD_W                         (A2X_URID_PYLD_W)

        ,.A2X_BLW                               (A2X_BLW)
        ,.A2X_RS_RATIO                          (A2X_RS_RATIO)
        
        ,.A2X_PP_MAX_SIZE                       (A2X_PP_MAX_SIZE)
        ,.A2X_PP_NUM_BYTES                      (A2X_PP_NUM_BYTES) 
        
        ,.A2X_SP_NUM_BYTES                      (A2X_SP_NUM_BYTES) 
        ,.A2X_SP_NUM_BYTES_LOG2                 (A2X_SP_NUM_BYTES_LOG2)
      ) U_a2x_r_upk_dec (
        // Outputs
        .r_pyld_tag                             (r_pyld_tag)
        // Inputs
        ,.clk                                   (clk_sp) 
        ,.resetn                                (resetn_sp)
        ,.rvalid_i                              (rvalid_sp)
        ,.rready_i                              (rready_sp)
        ,.rid_valid                             (rid_match)
        ,.rlast_i                               (rlast_sp)
        ,.rs_pyld_i                             (uid_pyld_o)
      );
      assign r_pyld_tag_w      = (rid_match)? r_pyld_tag : {A2X_RS_RATIO{1'b0}};
    end
  endgenerate

  //*************************************************************************************
  // Read Data Packer
  //
  // Stores the Read Data until enopugh data is captured to push into the Read
  // Data FIFO. SP DW smaller so data stored in packer until PP DW Transactions
  // captured. 
  //*************************************************************************************
  generate 
    if (A2X_DOWNSIZE==1) begin: DOWNSIZE_RPK
      i_axi_a2x_2_DW_axi_a2x_r_pk
       #(
         .A2X_RS_RATIO                        (A2X_RS_RATIO)
        ,.A2X_PP_DW                           (A2X_PP_DW)
        ,.A2X_PP_MAX_SIZE                     (A2X_PP_MAX_SIZE)     
        ,.A2X_PP_NUM_BYTES                    (A2X_PP_NUM_BYTES)
        ,.A2X_PP_NUM_BYTES_LOG2               (A2X_PP_NUM_BYTES_LOG2)
        
        ,.A2X_SP_DW                           (A2X_SP_DW)
        ,.A2X_SP_MAX_SIZE                     (A2X_SP_MAX_SIZE)     
        
        ,.A2X_PP_PYLD_W                       (A2X_PP_PYLD_W)
        ,.A2X_SP_PYLD_W                       (A2X_SP_PYLD_W)
        ,.A2X_RS_PYLD_W                       (A2X_RDS_PYLD_W)
        ,.A2X_RSBW                            (A2X_RSBW)
      ) U_r_pk (
        // Outputs
        .r_fifo_push_n                        (r_fifo_push_n_pk)
        ,.r_pyld_o                            (r_pyld_pk)
        // Inputs
        ,.clk                                 (clk_sp)
        ,.resetn                              (resetn_sp)
        ,.rvalid_i                            (rvalid_sp)
        ,.rready_i                            (rready_sp)
        ,.rid_valid                           (rid_match)
        ,.r_pyld_i                            (r_pyld_sp_et_o)
        ,.rs_pyld_i                           (ds_pyld_fifo_o)
        ,.rs_fifo_empty                       (uid_fifo_empty)
        ,.arlast                              (arlast_fifo_o)
      );
    end
  endgenerate

  //*************************************************************************************
  // AXI Endian Convert 
  // - Only convert Big endian (BE8) to Little Endian
  //*************************************************************************************
  generate
  if (A2X_SP_ENDIAN!=0) begin: BE8_TO_LE     
    wire   [`i_axi_a2x_2_A2X_BSW-1:0]                       r_pp_ds_size_w1;
    wire   [`i_axi_a2x_2_A2X_BSW-1:0]                       r_pp_us_size_w1;
    wire   [`i_axi_a2x_2_A2X_BSW-1:0]                       r_pp_size_w1;

    if (A2X_DOWNSIZE==1) begin
      assign r_pp_ds_size_w1 = uid_pyld_o[(`i_axi_a2x_2_A2X_BSW+A2X_PP_NUM_BYTES_LOG2+2)-1:A2X_PP_NUM_BYTES_LOG2+2];
      assign r_sp_size    = (r_pp_ds_size_w1<A2X_SP_MAX_SIZE) ? r_pp_ds_size_w1:A2X_SP_MAX_SIZE;
    end else if (A2X_UPSIZE==1) begin
      assign r_pp_us_size_w1 = uid_pyld_o[(`i_axi_a2x_2_A2X_BSW+A2X_SP_NUM_BYTES_LOG2+2)-1:A2X_SP_NUM_BYTES_LOG2+2];
      // If Size Equals PP size and resize bit high and not a Fixed burst transaction
      assign r_sp_size = ((r_pp_us_size_w1==A2X_PP_MAX_SIZE) & uid_pyld_o[A2X_URID_PYLD_W-1] & (!uid_pyld_o[A2X_URID_PYLD_W-2]))? A2X_SP_MAX_SIZE : r_pp_us_size_w1;
    end else begin
      assign r_sp_size    = (A2X_DOWNSIZE==1)? r_sp_ds_size : (A2X_UPSIZE==1)? r_sp_us_size : uid_pyld_o[A2X_URID_PYLD_W-1:1];
    end
     

    i_axi_a2x_2_DW_axi_a2x_x2x_et
     #(
       .A2X_USER_WIDTH         (A2X_RSBW)
      ,.A2X_UBB                (`i_axi_a2x_2_A2X_RUSER_BITS_PER_BYTE)      
      ,.A2X_PYLD_W             (A2X_SP_PYLD_W)
      ,.A2X_DW                 (A2X_SP_DW) 
      ,.WRITE_CH               (0)  // write channel
    ) U_a2x_r_sp_et (
      // Outputs
       .pyld_o                 (r_pyld_sp_et_o) 
      // Inputs
      ,.pyld_i                 (r_pyld_sp_i) 
      ,.size_i                 (r_sp_size)
    );
  end else begin
    assign r_pyld_sp_et_o = r_pyld_sp_i;
  end
  endgenerate
  
  //*************************************************************************************
  // SP Read Data Payload 
  //*************************************************************************************
  assign r_pyld_sp_i        = (rid_match)? r_pyld_i : {A2X_SP_PYLD_W{1'b0}};

endmodule
