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
// File Version     :        $Revision: #103 $ 
// Revision: $Id: //dwh/DW_ocb/DW_axi_a2x/amba_dev/src/DW_axi_a2x_w.v#103 $ 
**
** --------------------------------------------------------------------
**
** File     : DW_axi_a2x_w.v
** Created  : Thu Jan 27 11:01:40 MET 2011
** Abstract :
**
** --------------------------------------------------------------------
**
**
**
**-----------------------------------------------------------------------------------------------------------------
**                  Write Data Channel Architecture Diagram
**-----------------------------------------------------------------------------------------------------------------
**          |                                |                 |
**      PP AW Channel                   SP AW Channel     SP AW Channel
**          |                                |                 |
**          |                                |                 |
**          V                                |                 |
**      |--------|                      |----------|           |
**      | Resize |                      | Resize   |           |
**      | FIFO   |                      | FIFO     |           V
**      |--------|                      |----------|      |---------|
**           |                                |           |  Write  |
**           |                                |           | Control |
**           |     |------|        |-----|    |           |  FIFO   | 
**           |     | Push |        | Pop |    |           |---------|
**           |     |------|        |-----|    |                |
**           V       |               |        V                V
**      |---------|  |  |--------|   |  |-----------|     |---------|
**      |  Data   |  -->|  Data  |<---  |   Data    |     |  Write  | Write Data Channel
**      | Packer  |---->|  FIFO  |----->| Unpacker  |---->| Control |------------->
** ---->|         |     |        |      |           |     |         | 
**      |---------|     |--------|      |-----------|     |---------|
**                            
** This diagram shows the Write Data Path architecture of the A2X. Depending on the configuration upsizing ,downsizing or Non-Resized
** some of the blocks are unused in the design and may be removed from the RTL. 
**
** The following blocks are conditional based on the configuration selected. 
** - Data Unpacker        - For Downsizing Configs 
** - Data Packer          - For Upsizing Configs 
**
** To optimize performance on the Write Data Path the write data FIFO width is always set to the larger of the Primary Port v's 
** Secondary Port Data Buses.
**
** The rezsize FIFO takes information for the PP or SP AW Channel for use in resizing the write data from the Primary Port W Channel. 
** A seperate FIFO exists for Downsizing and Upsizing configurations as the Upsizing is implemented on the Primary POrt Clock and the 
** Downsizing on the Secondary Port Clock. 
**
** In Store-Forward Mode additional information needs to be stored so that the Write Control can correctly generate the write last on the SP.
**
** For Downsizing Configurations with Store-Forward the Resize FIFO and Write Control FIFO are combined into one SP Control FIFO to save logic. 
**                            
** For Upsizing Configs the Write Data cannot arrive before the AW Data.
**---------------------------------------------------------------------------------------------------------------------
*/
`include "DW_axi_a2x_all_includes.vh"

module i_axi_a2x_1_DW_axi_a2x_w (/*AUTOARG*/
   // Outputs
   snf_push_n, wready_pp, wvalid_sp, w_fifo_push_empty,
   w_pyld_sp, aw_snf_pyld_pp, pp_osaw_fifo_full, sp_osaw_fifo_full,
   // Inputs
   clk_pp, resetn_pp, clk_sp, resetn_sp, wbuf_mode, siu_snf_awlen, 
   sp_osaw_fifo_push_n, 
   snf_fifo_full, b_buf_fifo_full, 
   sp_osaw_pyld, wvalid_pp, w_pyld_pp, 
   wready_sp, 
   aw_pyld_pp, 
   awvalid_pp, awready_pp,
   pp_rst_n, sp_rst_n, lp_mode
   );

  //*************************************************************************************
  // Parameter Decelaration
  //*************************************************************************************
  parameter  A2X_PP_MODE                 = 0;
  parameter  A2X_UPSIZE                  = 0; 
  parameter  A2X_DOWNSIZE                = 0; 
  parameter  A2X_EQSIZED                 = 1; 
  parameter  A2X_BRESP_MODE              = 0; 
  parameter  A2X_LOCKED                  = 0;

  parameter  A2X_AW                      = 4;
  parameter  A2X_BLW                     = 4;
  parameter  A2X_AWSBW                   = 1; 

  parameter  A2X_WSBW                    = 1;  

  parameter  A2X_RS_RATIO                = 1; 
  parameter  A2X_RS_RATIO_LOG2           = 1; 

  parameter  A2X_PP_DW                   = 32;
  parameter  A2X_PP_WSTRB_DW             = 4;
  parameter  A2X_PP_MAX_SIZE             = 2;  
  parameter  A2X_PP_NUM_BYTES            = 4;
  parameter  A2X_PP_NUM_BYTES_LOG2       = 1;

  parameter  A2X_SP_DW                   = 32;
  parameter  A2X_SP_WSTRB_DW             = 4;
  parameter  A2X_SP_MAX_SIZE             = 2;  
  parameter  A2X_SP_NUM_BYTES            = 4;
  parameter  A2X_SP_NUM_BYTES_LOG2       = 1;

  parameter  A2X_CLK_MODE                = 0;
  parameter  A2X_PP_SYNC_DEPTH           = 2;
  parameter  A2X_SP_SYNC_DEPTH           = 2;

  parameter  A2X_PP_OSAW_LIMIT           = 4;
  parameter  A2X_PP_OSAW_LIMIT_LOG2      = 2;

  parameter  A2X_SP_OSAW_LIMIT           = 4;
  parameter  A2X_SP_OSAW_LIMIT_LOG2      = 2;

  parameter  A2X_WD_FIFO_DEPTH           = 4;
  parameter  A2X_WD_FIFO_DEPTH_LOG2      = 2;
  
  parameter  A2X_WSNF_PYLD_W             = 1;
  parameter  A2X_W_PP_PYLD_W             = 32;
  parameter  A2X_W_SP_PYLD_W             = 32;
  parameter  A2X_AW_PYLD_W               = 32;

  parameter  BYPASS_SNF_W                = 1; 

  // AHB/AXI Endian Convert
  parameter  A2X_PP_ENDIAN               = 0; 
  parameter  A2X_SP_ENDIAN               = 0; 

  // SP Outstanding FIFO Payload Width Parameter
  localparam SP_OSAW_FIFO_PYLD_W  = (A2X_DOWNSIZE==1)?  (`A2X_RSW + 1 + `A2X_BSW + A2X_PP_NUM_BYTES_LOG2 + 1 + A2X_BLW + 1) :
                                    ((A2X_UPSIZE==1) && (A2X_SP_ENDIAN==0))? (A2X_BLW + 1) :
                                    ((A2X_PP_MODE==1) && (A2X_UPSIZE==1) && (A2X_SP_ENDIAN==3))? (1 + 1 + `A2X_BSW + A2X_BLW + 1) :
                                    ((A2X_PP_MODE==0) && (A2X_UPSIZE==1) && (A2X_SP_ENDIAN==3))? (1 + `A2X_BSW + A2X_BLW + 1) :
                                    ((A2X_PP_MODE==0) && (A2X_SP_ENDIAN==3))? (`A2X_BSW + A2X_BLW + 1) :
                                    (A2X_PP_MODE==0)? (A2X_BLW + 1) : 
                                    (A2X_SP_ENDIAN==3)? `A2X_BSW : 
                                    ((A2X_LOCKED==1) && (A2X_BRESP_MODE==0))? 1 :0;
                                      
  // Primary Port OSAW FIFO Payload Width 
  localparam A2X_PP_OSAW_PYLD_W          =  1 + `A2X_BTW + `A2X_BSW + A2X_BLW + 13; 

  // Downsizing Payload & SP Control 
  localparam A2X_WDS_PYLD_W              = `A2X_RSW + 1 + `A2X_BSW + A2X_PP_NUM_BYTES_LOG2 + 1;
  localparam A2X_W_SPC_PYLD_W            =  A2X_BLW + 1;
     
  // Write data FIFO payload
  localparam A2X_W_FIFO_PYLD_W           = (A2X_UPSIZE==1)? A2X_W_SP_PYLD_W : A2X_W_PP_PYLD_W;
  localparam A2X_WLAST_PYLD_BIT          = 0;

  // Lint violation - Can't have A2X_PP_NUM_BYTES_LOG2 of 0 for A2X_PP_NUM_BYTES_LOG2-1
  localparam PP_NUM_BYTES_LOG2           = (A2X_PP_DW==8)? 1 : A2X_PP_NUM_BYTES_LOG2;
  localparam SP_NUM_BYTES_LOG2           = (A2X_SP_DW==8)? 1 : A2X_SP_NUM_BYTES_LOG2;

  // Secondary Port OSAW Payload Width 
  localparam A2X_SP_OSAW_PYLD_W          = `A2X_RSW + 1 + `A2X_BSW + PP_NUM_BYTES_LOG2 + 1 + A2X_BLW + 1;

  //*************************************************************************************
  //
  // I/O Decelaration
  //*************************************************************************************
  //spyglass disable_block W240
  //SMD: An input has been declared but is not read.
  //SJ : Few ports are used in specific config only 
  input                                       clk_pp;
  input                                       resetn_pp;

  input                                       clk_sp;
  input                                       resetn_sp;

  input                                       wbuf_mode;             // Store-Forward 
  input  [31:0]                               siu_snf_awlen;

  input                                       sp_osaw_fifo_push_n;   // SP Control FIFO
  output                                      snf_push_n;            // Store-Forward FIFO Control

  input                                       snf_fifo_full;
  output [A2X_WSNF_PYLD_W-1:0]                aw_snf_pyld_pp;

  output                                      pp_osaw_fifo_full;
  output                                      sp_osaw_fifo_full;
  output                                      w_fifo_push_empty;
  input                                       b_buf_fifo_full;

  input                                       awready_pp;            // PP W Channel
  input                                       awvalid_pp;
  input  [A2X_AW_PYLD_W-1:0]                  aw_pyld_pp;

  output                                      wready_pp;             // PP W Channel
  input                                       wvalid_pp;
  input  [A2X_W_PP_PYLD_W-1:0]                w_pyld_pp;

  input                                       wready_sp;             // SP W Channel
  output                                      wvalid_sp;
  output [A2X_W_SP_PYLD_W-1:0]                w_pyld_sp;

  input  [A2X_SP_OSAW_PYLD_W-1:0]             sp_osaw_pyld;

  input                                       pp_rst_n;
  input                                       sp_rst_n;
  input                                       lp_mode;
  //spyglass enable_block W240

  //*************************************************************************************
  // Signal Control
  //*************************************************************************************
  // Primary Port Outstanding Write FIFO Control
  wire                                        pp_osaw_fifo_push_n;
  wire                                        pp_osaw_fifo_pop_n;

  // Secondary Port Outstanding Write FIFO Control
  wire                                        sp_osaw_fifo_pop_n;              // SP Contrtol FIFO
  wire                                        sp_osaw_fifo_empty;

  // Secondary Port Control 
  wire                                        spc_strobe; 

  // Write Data FIFO control
  wire                                        w_fifo_push_n;              // Write data FIFO
  wire                                        w_fifo_pop_n; 
  wire                                        w_fifo_full;
  wire                                        w_fifo_empty;
  wire  [A2X_W_FIFO_PYLD_W-1:0]               w_pyld_fifo_i;
  wire  [A2X_W_FIFO_PYLD_W-1:0]               w_pyld_fifo_o;
  //These are dummy wires used to connect the unconnected ports.
  //     Hence will not drive any nets.
  wire  [A2X_WD_FIFO_DEPTH_LOG2:0]            w_fifo_push_count;
  wire  [A2X_WD_FIFO_DEPTH_LOG2:0]            w_fifo_pop_count;
  // Write Data Packer
  wire                                        pk_w_fifo_push_n;           // Write Data Packer
  wire  [A2X_W_SP_PYLD_W-1:0]                 pk_w_pyld_o;
  wire  [`A2X_BSW-1:0]                        pp_endian_size_i; 
  wire  [`A2X_BSW-1:0]                        sp_endian_size_i; 
  wire  [`A2X_BSW-1:0]                        upk_endian_size;     
  wire  [A2X_W_SP_PYLD_W-1:0]                 sp_endian_pyld_i;

  wire  [A2X_W_PP_PYLD_W-1:0]                 pp_endian_pyld_o;

  wire  [A2X_W_SP_PYLD_W-1:0]                 sp_endian_pyld_o;
  wire  [A2X_BLW-1:0]                         pk_w_wb_len;

  wire                                        upk_w_fifo_pop_n;           // Write Data Unpacker
  wire  [A2X_W_SP_PYLD_W-1:0]                 upk_w_pyld_o;

  wire                                        spc_w_fifo_pop_n;

  //     Hence will not drive any nets.
  wire                                        unconn_3;

  // Primary Port AW Payload Decode Control
  //These are dummy wires used to connect the unconnected ports.
  //     Hence will not drive any nets.
  wire   [`A2X_IDW-1:0]                       awid_pp;    
  wire   [`A2X_LTW-1:0]                       awlock_pp;   
  wire   [`A2X_CTW-1:0]                       awcache_pp; 
  wire   [`A2X_PTW-1:0]                       awprot_pp; 
  wire   [A2X_AWSBW-1:0]                      awsideband_pp;
  wire                                        aw_hburst_type_pp;
  wire   [A2X_AW-1:0]                         awaddr_pp; 
  wire   [A2X_BLW-1:0]                        awlen_pp; 
  wire   [`A2X_BSW-1:0]                       awsize_pp;     
  wire   [`A2X_BTW-1:0]                       awburst_pp;   
  wire                                        awresize_pp;

  // Outputs from SP OSAW FIFO. 
  wire  [`A2X_BSW-1:0]                        sp_osaw_size_o;     
  wire  [`A2X_RSW-1:0]                        sp_osaw_resize_o; 
  wire                                        sp_osaw_fixed_o;
  wire                                        sp_osaw_last_o;
  wire  [PP_NUM_BYTES_LOG2-1:0]               sp_osaw_addr_o;
  // Secondary Port Outputs 
  wire                                        sp_osaw_awlast_o;
  wire  [A2X_BLW-1:0]                         sp_osaw_awlen_o;

  // Downsizing Payload
  wire  [A2X_WDS_PYLD_W-1:0]                  ds_pyld_o; 

  // Outputs from PP OSAW FIFO. 
  wire  [A2X_PP_OSAW_PYLD_W-1:0]              pp_osaw_pyld_o;
  wire  [A2X_W_PP_PYLD_W-1:0]                 w_pyld_pp_i;
  wire                                        wvalid_pp_i;
  wire                                        wready_pp_i;
  reg                                         pp_wd_reg_full;
  reg   [A2X_W_PP_PYLD_W-1:0]                 pp_wd_pyld_reg;
  wire                                        pp_wd_reg_full_w;
  wire                                        pp_osaw_fifo_empty;

  //*************************************************************************************
  //                         Primary Port Control
  //*************************************************************************************
  assign wready_pp     = !(snf_fifo_full | b_buf_fifo_full | w_fifo_full | pp_wd_reg_full_w | lp_mode);

  //*************************************************************************************
  // Write Address Primary Port Payload - Decoded here so that the PP OSW FIFO Payload can be generated
  // spyglass disable_block W164a
  // SMD: Identifies assignments in which the LHS width is less than the RHS width
  // SJ : This is not a functional issue, this is as per the requirement.
  //      Hence this can be waived.  
  assign {aw_hburst_type_pp, awsideband_pp, awid_pp, awaddr_pp, awresize_pp, awlen_pp, awsize_pp, awburst_pp, awlock_pp, awcache_pp, awprot_pp} = aw_pyld_pp; 
  // spyglass enable_block W164a

  //*************************************************************************************
  // Primary Port OS Write FIFO 
  // - FIFO Required for AXI BE-8 Endian Conversion
  // - FIFO Required for Downsizing Mode with Store-Forward Enabled.
  // - FIFO Required for Upsizing Configurations. 
  //*************************************************************************************
  generate
  if ((A2X_PP_ENDIAN==3) || ((A2X_DOWNSIZE==1) && (BYPASS_SNF_W==0)) || (A2X_UPSIZE==1)) begin: PP_OW_FIFO
    
    wire                                        pp_osaw_fifo_full_w;
    wire                                        pp_osaw_fifo_empty_w;
    wire  [A2X_PP_OSAW_LIMIT_LOG2:0]            pp_osaw_fifo_push_count;
    wire  [A2X_PP_OSAW_LIMIT_LOG2:0]            pp_osaw_fifo_pop_count;

    wire  [A2X_PP_OSAW_PYLD_W-1:0]              us_pp_osaw_pyld;
    wire  [A2X_PP_OSAW_PYLD_W-1:0]              ds_pp_osaw_pyld;
    wire  [A2X_PP_OSAW_PYLD_W-1:0]              pp_osaw_pyld_i;
    wire  [A2X_PP_OSAW_PYLD_W-1:0]              pp_osaw_pyld_o_w;

    wire                                        pp_osaw_fifo_unconn;
    wire                                        axi_same_cycle; 
    wire                                        axi_same_cycle_push_n; 

    // Asserted when AW and W arrive on same cycle. 
    assign axi_same_cycle = (A2X_PP_MODE==0)? 1'b0 : (awready_pp & awvalid_pp & wready_pp & wvalid_pp & pp_osaw_fifo_empty_w);

    assign axi_same_cycle_push_n = (A2X_PP_MODE==0)? 1'b1 : ~(axi_same_cycle & (awlen_pp!={A2X_BLW{1'b0}}) & (!pp_wd_reg_full_w));

    // Push into FIFO when valid address on primary port
    // - In AHB Mode data always 1 Clock Cycle after address. Hence information can be pushed directly into FIFO.
    // - In AXI Mode data may arrive at the same time as the address. 
    // - If the AXI Length is zero then no push is done into the FIFO 
    // - If length is greater than zero a push is generated into FIFO.
    assign  pp_osaw_fifo_push_n  = (A2X_PP_MODE==0)? ~(awready_pp & awvalid_pp) : (axi_same_cycle)? axi_same_cycle_push_n : (~(awready_pp & awvalid_pp));

    // Upsizing FIFO Payload Input
    assign us_pp_osaw_pyld          = {awresize_pp, awburst_pp, awsize_pp, awlen_pp, awaddr_pp[12:0]};

    // Downsizing FIFO Payload Input
    assign ds_pp_osaw_pyld          = {1'b0,        awburst_pp, awsize_pp, awlen_pp, awaddr_pp[12:0]};

    // Primary Port OSW FIFO Pop
    assign pp_osaw_fifo_pop_n  = ~((!pp_osaw_fifo_empty_w) & wvalid_pp_i & wready_pp_i & w_pyld_pp_i[A2X_WLAST_PYLD_BIT]);

    // Primary Port OSW FIFO Empty & Full Status
    assign pp_osaw_fifo_full   = pp_osaw_fifo_full_w;
    assign pp_osaw_fifo_empty  = pp_osaw_fifo_empty_w;

    // Primary Port OSW FIFO Payload Input
    assign pp_osaw_pyld_i      =  ((A2X_DOWNSIZE==1) && (BYPASS_SNF_W==0))? ds_pp_osaw_pyld : 
                                  (A2X_UPSIZE==1)? us_pp_osaw_pyld : {1'b0, {`A2X_BTW{1'b0}}, awsize_pp, {A2X_BLW{1'b0}}, 13'd0}; 

    //*************************************************************************************
    // Primary Port OSW FIFO Instance
    //*************************************************************************************
    i_axi_a2x_1_DW_axi_a2x_fifo
     #(
       .DATA_W                                 (A2X_PP_OSAW_PYLD_W)
      ,.DEPTH                                  (A2X_PP_OSAW_LIMIT)
      ,.LOG2_DEPTH                             (A2X_PP_OSAW_LIMIT_LOG2)
    ) U_a2x_w_pp_osaw_fifo (
       .clk_push_i                             (clk_pp)
      ,.resetn_push_i                          (resetn_pp)
      ,.push_req_n_i                           (pp_osaw_fifo_push_n)
      ,.data_i                                 (pp_osaw_pyld_i)
      ,.push_full_o                            (pp_osaw_fifo_full_w)
      ,.push_empty_o                           (pp_osaw_fifo_unconn)
      ,.pop_req_n_i                            (pp_osaw_fifo_pop_n)
      ,.pop_empty_o                            (pp_osaw_fifo_empty_w)
      ,.data_o                                 (pp_osaw_pyld_o_w)    
      ,.clk_pop_i                              (clk_pp) // Unused - connected for lint
      ,.resetn_pop_i                           (resetn_pp)
      ,.push_count                             (pp_osaw_fifo_push_count)
      ,.pop_count                              (pp_osaw_fifo_pop_count)
      ,.push_rst_n                             (pp_rst_n)
      ,.pop_rst_n                              (pp_rst_n)
    );

    // Bypass FIFO output when empty so that W channel can accept data on same
    // clock cycle as AW. In AHB Mode this is not necessary as Data is
    // always 1 cycle after the address.
    assign pp_osaw_pyld_o = (A2X_PP_MODE==0)? pp_osaw_pyld_o_w : (axi_same_cycle) ? pp_osaw_pyld_i : pp_osaw_pyld_o_w;
    
    // A2X Endian Size.
    assign pp_endian_size_i =  pp_osaw_pyld_o[(`A2X_BSW+A2X_BLW+13)-1:A2X_BLW+13] ;

    // To accept write data on same clock cycle as AW Channel or before the AW Channel
    if (A2X_PP_MODE==1) begin: AXI_PYLD_REG                            
      // Write Data Payload Register
      always @(posedge clk_pp or negedge resetn_pp) begin: pp_pyld_PROC
        if (resetn_pp==1'b0) begin
          pp_wd_pyld_reg <= {A2X_W_PP_PYLD_W{1'b0}};
        end else begin
          if (pp_osaw_fifo_empty_w && wvalid_pp && wready_pp && (!(awvalid_pp && awready_pp))) begin
            pp_wd_pyld_reg <= w_pyld_pp;
          end
        end
      end
      assign w_pyld_pp_i = (pp_wd_reg_full_w)? pp_wd_pyld_reg : w_pyld_pp;

      // Valid Data for Write data FIFO
      assign wvalid_pp_i = (pp_wd_reg_full_w)? 1'b1 : (pp_osaw_fifo_empty_w & (!(awready_pp & awvalid_pp))) ? 1'b0 : wvalid_pp;

      // Used for the Write data FIFO Push and the Write Data packer. 
      // - This signal tells the write data register it can accept the data from its register
      assign wready_pp_i = (pp_wd_reg_full_w)? (!pp_osaw_fifo_empty_w) & (!w_fifo_full): wready_pp;

      // Generateion of Write Data B4 Address Register Flag
      always @(posedge clk_pp or negedge resetn_pp) begin: pp_pyld_flag_PROC
        if (resetn_pp==1'b0) begin
          pp_wd_reg_full <= 1'b0;
        end else begin
          // If valid data and 
          if (pp_osaw_fifo_empty_w && wvalid_pp && wready_pp && (!(awvalid_pp && awready_pp)))
            pp_wd_reg_full <= 1'b1;
          else if (!pp_osaw_fifo_empty_w)
            pp_wd_reg_full <= 1'b0;
        end
      end 
      assign pp_wd_reg_full_w = pp_wd_reg_full;

    end else begin // AXI_PYLD_REG
      assign pp_wd_reg_full_w = 1'b0;
      assign wvalid_pp_i         = wvalid_pp;
      assign w_pyld_pp_i         = w_pyld_pp;
      assign wready_pp_i         = (!w_fifo_full) & (!snf_fifo_full);
    end
    
    //--------------------------------------------------------------------
    // System Verilog Assertions
    //--------------------------------------------------------------------

  end else begin
    assign pp_wd_reg_full_w    = 1'b0;
    assign wvalid_pp_i         = wvalid_pp;
    assign w_pyld_pp_i         = w_pyld_pp;
    assign pp_osaw_fifo_push_n = 1'b1;
    assign pp_osaw_fifo_pop_n  = 1'b1;
    assign pp_osaw_fifo_full   = 1'b0;
    assign pp_osaw_fifo_empty  = 1'b1; // Always Empty
    assign wready_pp_i         = wready_pp;
    assign pp_osaw_pyld_o      = {A2X_PP_OSAW_PYLD_W{1'b0}}; 
  end
  endgenerate

  //*************************************************************************************
  // AXI Endian Convert 
  // - Only convert Big endian to Little Endian
  //*************************************************************************************
  generate 

  if ((A2X_PP_ENDIAN!=0) && (A2X_PP_MODE==1)) begin: BE_TO_LE   
    i_axi_a2x_1_DW_axi_a2x_x2x_et
     #(
       .A2X_PYLD_W             (A2X_W_PP_PYLD_W)
      ,.A2X_DW                 (A2X_PP_DW) 
      ,.WRITE_CH               (1)  // write channel
    ) U_a2x_w_pp_et (
      // Outputs
       .pyld_o                 (pp_endian_pyld_o) 
      // Inputs
      ,.pyld_i                 (w_pyld_pp_i) 
      ,.size_i                 (pp_endian_size_i)
    );
  end else begin
    assign pp_endian_pyld_o = w_pyld_pp_i;
  end
  endgenerate

  //*************************************************************************************
  //                           Write Data Resize FIFO
  //
  // Contains the Resize Information for the Write Data Channel. 
  //*************************************************************************************
  generate
    if (A2X_UPSIZE==1) begin: UPSIZE
      //*************************************************************************************
      //                          Data Packer
      //                          
      // Upsizes the Primary Port Write Data                          
      //*************************************************************************************
      i_axi_a2x_1_DW_axi_a2x_w_pk
       #( 
         .A2X_BLW                                (A2X_BLW)
        ,.A2X_RS_RATIO                           (A2X_RS_RATIO)
        ,.A2X_PP_DW                              (A2X_PP_DW)
        ,.A2X_PP_WSTRB_DW                        (A2X_PP_WSTRB_DW)
        ,.A2X_PP_MAX_SIZE                        (A2X_PP_MAX_SIZE)
        ,.A2X_PP_NUM_BYTES                       (A2X_PP_NUM_BYTES)
        ,.A2X_PP_NUM_BYTES_LOG2                  (A2X_PP_NUM_BYTES_LOG2)
        ,.A2X_SP_DW                              (A2X_SP_DW)
        ,.A2X_SP_WSTRB_DW                        (A2X_SP_WSTRB_DW)
        ,.A2X_SP_NUM_BYTES                       (A2X_SP_NUM_BYTES)
        ,.A2X_SP_NUM_BYTES_LOG2                  (A2X_SP_NUM_BYTES_LOG2)
        ,.A2X_PP_PYLD_W                          (A2X_W_PP_PYLD_W)
        ,.A2X_SP_PYLD_W                          (A2X_W_SP_PYLD_W)
        ,.A2X_PP_OSAW_PYLD_W                     (A2X_PP_OSAW_PYLD_W)
        ,.A2X_PP_MODE                            (A2X_PP_MODE)
       ) U_a2x_w_pk (
         // Outputs
          .w_fifo_push_n                         (pk_w_fifo_push_n)
         ,.w_pyld_o                              (pk_w_pyld_o)
         ,.wrap_ub_len                           (pk_w_wb_len)
         // Inputs 
         ,.clk                                   (clk_pp)
         ,.resetn                                (resetn_pp)
         ,.wready_i                              (wready_pp_i)
         ,.wvalid_i                              (wvalid_pp_i)
         ,.w_pyld_i                              (pp_endian_pyld_o)
         ,.rs_pyld_i                             (pp_osaw_pyld_o)
       );
       
       assign w_fifo_push_n = pk_w_fifo_push_n;
       assign w_pyld_fifo_i = pk_w_pyld_o;
     end else begin
       assign pk_w_wb_len   = {A2X_BLW{1'b0}};
       assign w_fifo_push_n = !(wready_pp_i & wvalid_pp_i);
       assign w_pyld_fifo_i =  pp_endian_pyld_o;
     end
   endgenerate

  //*************************************************************************************
  // Store and Forward Counter
  //
  // Counts the number of Primary Port Data beats and generates a push to the
  // Store-Forward FIFO when the store-forward count is reached. 
  //
  // The SP cannot send an address until siu_snf_awlen SP Data beats are
  // captured and stored in the Data FIFO. 
  //*************************************************************************************
  generate
    if (BYPASS_SNF_W==0) begin: SNF_W
      i_axi_a2x_1_DW_axi_a2x_w_snf
       #(
         .A2X_UPSIZE                            (A2X_UPSIZE)
        ,.A2X_DOWNSIZE                          (A2X_DOWNSIZE)
        ,.A2X_PP_MAX_SIZE                       (A2X_PP_MAX_SIZE)
        ,.A2X_SP_MAX_SIZE                       (A2X_SP_MAX_SIZE)
        ,.A2X_BLW                               (A2X_BLW)
        ,.A2X_RS_PYLD_W                         (A2X_PP_OSAW_PYLD_W)
        ,.A2X_RS_RATIO_LOG2                     (A2X_RS_RATIO_LOG2)
      ) U_a2x_w_snf (
        // Outputs
        .snf_push_n                             (snf_push_n)
        // Inputs
        ,.clk_pp                                (clk_pp)
        ,.resetn_pp                             (resetn_pp)
        ,.siu_buf_mode                          (wbuf_mode)
        ,.siu_snf_awlen                         (siu_snf_awlen)
        ,.wready_pp                             (wready_pp_i)
        ,.wvalid_pp                             (wvalid_pp_i)     
        ,.wlast_pp                              (w_pyld_fifo_i[A2X_WLAST_PYLD_BIT])
        ,.rs_pyld_i                             (pp_osaw_pyld_o)
        ,.pk_w_wb_len                           (pk_w_wb_len)  // Wrap Bouldary length from Write data Packer
      );
      // Write Store N Forward Payload 
      assign aw_snf_pyld_pp = w_pyld_fifo_i[A2X_WLAST_PYLD_BIT];
    end else begin
      assign snf_push_n = 1'b0;
      assign aw_snf_pyld_pp = 1'b0;
    end
  endgenerate

  //*************************************************************************************
  //                       Write Data FIFO
  //
  // In Store-Forward mode the depth of this FIFO cannot be less than the
  // Maximum Store-Forward count. 
  //*************************************************************************************
  i_axi_a2x_1_DW_axi_a2x_fifo
   #(
     .DUAL_CLK                               (A2X_CLK_MODE)
    ,.PUSH_SYNC_DEPTH                        (A2X_PP_SYNC_DEPTH)
    ,.POP_SYNC_DEPTH                         (A2X_SP_SYNC_DEPTH)
    ,.DATA_W                                 (A2X_W_FIFO_PYLD_W)
    ,.DEPTH                                  (A2X_WD_FIFO_DEPTH)
    ,.LOG2_DEPTH                             (A2X_WD_FIFO_DEPTH_LOG2)
  ) U_a2x_wd_fifo (
     .clk_push_i                             (clk_pp)
    ,.resetn_push_i                          (resetn_pp)
    ,.push_req_n_i                           (w_fifo_push_n)
    ,.data_i                                 (w_pyld_fifo_i)
    ,.push_full_o                            (w_fifo_full)
    ,.push_empty_o                           (w_fifo_push_empty)
    ,.clk_pop_i                              (clk_sp)
    ,.resetn_pop_i                           (resetn_sp)
    ,.pop_req_n_i                            (w_fifo_pop_n)
    ,.pop_empty_o                            (w_fifo_empty)
    ,.data_o                                 (w_pyld_fifo_o)    
    ,.push_count                             (w_fifo_push_count)
    ,.pop_count                              (w_fifo_pop_count)
    ,.push_rst_n                             (pp_rst_n)
    ,.pop_rst_n                              (sp_rst_n)
  );  

  //*************************************************************************************
  // Write Data Secondary Port outstanding FIFO
  //
  //*************************************************************************************
  generate 
  if ((A2X_PP_MODE==0) || (A2X_DOWNSIZE==1) || (A2X_UPSIZE==1) ||  (A2X_SP_ENDIAN!=0) || ((A2X_LOCKED==1) && (A2X_BRESP_MODE==0))) begin: SPOSAWFIFO
    
    wire   [SP_OSAW_FIFO_PYLD_W-1:0]            sp_osaw_fifo_pyld_i;
    wire   [SP_OSAW_FIFO_PYLD_W-1:0]            sp_osaw_fifo_pyld_o;
    wire   [A2X_SP_OSAW_LIMIT_LOG2:0]           sp_osaw_fifo_push_count;
    wire   [A2X_SP_OSAW_LIMIT_LOG2:0]           sp_osaw_fifo_pop_count;

    wire                                        sp_osaw_fifo_full_w;
    
    // Outputs from AW Channel's Address Splitter. 
    wire  [`A2X_BSW-1:0]                        sp_osaw_size_i;     
    wire  [`A2X_RSW-1:0]                        sp_osaw_resize_i; 
    wire                                        sp_osaw_last_i;
    wire                                        sp_osaw_fixed_i;
    wire  [PP_NUM_BYTES_LOG2-1:0]               sp_osaw_addr_i;
    // Secondary Port Outputs 
    wire                                        sp_osaw_awlast_i;
    wire  [A2X_BLW-1:0]                         sp_osaw_awlen_i;

    wire  [`A2X_BSW-1:0]                        us_endian_size;

    // Decode SP OSAW FIFO Payload 
    assign {sp_osaw_resize_i, sp_osaw_fixed_i, sp_osaw_size_i, sp_osaw_addr_i[PP_NUM_BYTES_LOG2-1:0], sp_osaw_last_i, sp_osaw_awlast_i, sp_osaw_awlen_i} = sp_osaw_pyld;

    // Decode the SP OSAW FIFO Input
    if (A2X_DOWNSIZE==1) begin
      assign sp_osaw_fifo_pyld_i = sp_osaw_pyld;
    end else if ((A2X_UPSIZE==1) && (A2X_SP_ENDIAN==0)) begin
      assign sp_osaw_fifo_pyld_i = {sp_osaw_awlast_i, sp_osaw_awlen_i};
    end else if ((A2X_PP_MODE==1) && (A2X_UPSIZE==1) && (A2X_SP_ENDIAN==3)) begin
      assign sp_osaw_fifo_pyld_i = {sp_osaw_resize_i, sp_osaw_fixed_i, sp_osaw_size_i,sp_osaw_awlast_i, sp_osaw_awlen_i};
    end else if ((A2X_PP_MODE==0) && (A2X_UPSIZE==1) && (A2X_SP_ENDIAN==3)) begin
      assign sp_osaw_fifo_pyld_i = {sp_osaw_resize_i, sp_osaw_size_i,sp_osaw_awlast_i, sp_osaw_awlen_i};
    end else if ((A2X_PP_MODE==0) && (A2X_SP_ENDIAN==3)) begin 
      assign sp_osaw_fifo_pyld_i = {sp_osaw_size_i,sp_osaw_awlast_i, sp_osaw_awlen_i};
    end else if (A2X_PP_MODE==0) begin
      assign sp_osaw_fifo_pyld_i = {sp_osaw_awlast_i, sp_osaw_awlen_i};
    end else if (A2X_SP_ENDIAN==3) begin
      assign sp_osaw_fifo_pyld_i = sp_osaw_size_i;
    end else if ((A2X_LOCKED==1) && (A2X_BRESP_MODE==0)) begin
      assign sp_osaw_fifo_pyld_i = sp_osaw_awlast_i;
    end else begin
      assign sp_osaw_fifo_pyld_i = {SP_OSAW_FIFO_PYLD_W{1'b0}};
    end

    // IF AXI Equalled Sized CT mode FIFO not in use. 
    wire sp_osaw_fifo_push_n_w    = sp_osaw_fifo_push_n;
    
    // IF AXI Equalled Sized CT mode FIFO not in use. 
    assign sp_osaw_fifo_full      = sp_osaw_fifo_full_w;

    i_axi_a2x_1_DW_axi_a2x_fifo
     #(
       .DATA_W                                 (SP_OSAW_FIFO_PYLD_W)
      ,.DEPTH                                  (A2X_SP_OSAW_LIMIT)
      ,.LOG2_DEPTH                             (A2X_SP_OSAW_LIMIT_LOG2)
    ) U_a2x_w_spc_fifo (
       .clk_push_i                             (clk_sp)
      ,.resetn_push_i                          (resetn_sp)
      ,.push_req_n_i                           (sp_osaw_fifo_push_n_w)
      ,.data_i                                 (sp_osaw_fifo_pyld_i)
      ,.push_full_o                            (sp_osaw_fifo_full_w)
      ,.push_empty_o                           (unconn_3)
      ,.pop_req_n_i                            (sp_osaw_fifo_pop_n)
      ,.pop_empty_o                            (sp_osaw_fifo_empty)
      ,.data_o                                 (sp_osaw_fifo_pyld_o)    
      ,.clk_pop_i                              (clk_sp)      // Unused ports in Sync mode - Connecting for lint Violations
      ,.resetn_pop_i                           (resetn_sp)
      ,.push_count                             (sp_osaw_fifo_push_count) // Unused ports
      ,.pop_count                              (sp_osaw_fifo_pop_count)  // Unused ports
      ,.push_rst_n                             (sp_rst_n)
      ,.pop_rst_n                              (sp_rst_n)
    );
    
    // Decode the SP OSAW FIFO Outputs
    if (A2X_DOWNSIZE==1) begin
      assign {sp_osaw_resize_o, sp_osaw_fixed_o, sp_osaw_size_o, sp_osaw_addr_o, sp_osaw_last_o, sp_osaw_awlast_o, sp_osaw_awlen_o} = sp_osaw_fifo_pyld_o;
    end else if ((A2X_UPSIZE==1) && (A2X_SP_ENDIAN==0)) begin
      assign {sp_osaw_awlast_o, sp_osaw_awlen_o} = sp_osaw_fifo_pyld_o;
      assign sp_osaw_size_o   = {`A2X_BSW{1'b0}}; 
    end else if ((A2X_PP_MODE==1) && (A2X_UPSIZE==1) && (A2X_SP_ENDIAN==3)) begin
      assign {sp_osaw_resize_o, sp_osaw_fixed_o, sp_osaw_size_o, sp_osaw_awlast_o, sp_osaw_awlen_o} = sp_osaw_fifo_pyld_o;
    end else if ((A2X_PP_MODE==0) && (A2X_UPSIZE==1) && (A2X_SP_ENDIAN==3)) begin
      assign {sp_osaw_resize_o, sp_osaw_size_o, sp_osaw_awlast_o, sp_osaw_awlen_o} = sp_osaw_fifo_pyld_o;
    end else if ((A2X_PP_MODE==0) && (A2X_SP_ENDIAN==3)) begin 
      assign {sp_osaw_size_o, sp_osaw_awlast_o, sp_osaw_awlen_o} = sp_osaw_fifo_pyld_o;
    end else if (A2X_PP_MODE==0) begin
      assign {sp_osaw_awlast_o, sp_osaw_awlen_o} = sp_osaw_fifo_pyld_o;
      assign sp_osaw_size_o   = {`A2X_BSW{1'b0}}; 
    end else if (A2X_SP_ENDIAN==3) begin
      assign sp_osaw_size_o = sp_osaw_fifo_pyld_o;
      assign sp_osaw_awlast_o = 1'b0; 
    end else if ((A2X_LOCKED==1) && (A2X_BRESP_MODE==0)) begin
      assign sp_osaw_awlast_o = sp_osaw_fifo_pyld_o;
      assign sp_osaw_size_o   = {`A2X_BSW{1'b0}}; 
    end

    // Constant condition expression
    // This module is used for in several instances and the value depends on the instantiation. 
    //      Hence below usage cannot be avoided. This will not cause any funcational issue. 
    if (A2X_DOWNSIZE==1) begin
      //--------------------------------------------------------------
      // Downsize FIFO Payload
      //--------------------------------------------------------------
      assign ds_pyld_o = sp_osaw_fifo_pyld_o[SP_OSAW_FIFO_PYLD_W-1:A2X_W_SPC_PYLD_W];
    end else begin
      assign ds_pyld_o = {A2X_WDS_PYLD_W{1'b0}};
    end
      
    //--------------------------------------------------------------
    // Endian Payload Input
    //--------------------------------------------------------------
    if (((A2X_PP_MODE==1)) && (A2X_UPSIZE==1) && (A2X_SP_ENDIAN==3)) begin
      assign us_endian_size = ((sp_osaw_fixed_o || (!sp_osaw_resize_o) || (sp_osaw_size_o!=A2X_PP_MAX_SIZE)))? sp_osaw_size_o : A2X_SP_MAX_SIZE; 
    end else if (((A2X_PP_MODE==0)) && (A2X_UPSIZE==1) && (A2X_SP_ENDIAN==3)) begin
      assign us_endian_size = ((!sp_osaw_resize_o) || (sp_osaw_size_o!=A2X_PP_MAX_SIZE))? sp_osaw_size_o : A2X_SP_MAX_SIZE; 
    end else begin
      assign us_endian_size = {`A2X_BSW{1'b0}};
    end
    assign sp_endian_size_i = (A2X_DOWNSIZE==1)? upk_endian_size  : (A2X_UPSIZE==1)? us_endian_size : sp_osaw_size_o; 

  end else begin 
    assign sp_osaw_fifo_empty     = 1'b0;
    assign sp_osaw_fifo_full      = 1'b0;
  end
  endgenerate

  //*************************************************************************************
  //                            Data Unpacker 
  //
  // Downsizes the Write Data from the Write Data FIFO. 
  //*************************************************************************************
  generate 
    if (A2X_DOWNSIZE==1) begin: DOWNSIZE
      i_axi_a2x_1_DW_axi_a2x_w_upk
       #(
        .A2X_PP_MODE                            (A2X_PP_MODE)
       ,.A2X_PP_DW                              (A2X_PP_DW)
       ,.A2X_PP_WSTRB_DW                        (A2X_PP_WSTRB_DW)
       ,.A2X_PP_MAX_SIZE                        (A2X_PP_MAX_SIZE)
       ,.A2X_SP_DW                              (A2X_SP_DW)
       ,.A2X_SP_WSTRB_DW                        (A2X_SP_WSTRB_DW)
       ,.A2X_SP_MAX_SIZE                        (A2X_SP_MAX_SIZE)
       ,.A2X_RS_RATIO                           (A2X_RS_RATIO)
       ,.A2X_PP_NUM_BYTES                       (A2X_PP_NUM_BYTES)
       ,.A2X_SP_NUM_BYTES                       (A2X_SP_NUM_BYTES)
       ,.A2X_PP_NUM_BYTES_LOG2                  (A2X_PP_NUM_BYTES_LOG2)
       ,.A2X_SP_NUM_BYTES_LOG2                  (A2X_SP_NUM_BYTES_LOG2)
       ,.A2X_PP_PYLD_W                          (A2X_W_PP_PYLD_W)
       ,.A2X_SP_PYLD_W                          (A2X_W_SP_PYLD_W)
       ,.A2X_RS_PYLD_W                          (A2X_WDS_PYLD_W)
      ) U_a2x_w_upk (
        // Outputs
         .w_fifo_pop_n                           (upk_w_fifo_pop_n)
        ,.w_pyld_o                               (upk_w_pyld_o)
        ,.sp_size                                (upk_endian_size)
        // Inputs
        ,.clk                                    (clk_sp)
        ,.resetn                                 (resetn_sp)
        ,.spc_strobe                             (spc_strobe)
        ,.spc_pop_n_i                            (spc_w_fifo_pop_n)
        ,.w_pyld_i                               (w_pyld_fifo_o)
        ,.rs_pyld_i                              (ds_pyld_o)
        ,.rs_fifo_empty                          (sp_osaw_fifo_empty)
        ,.wready_sp                              (wready_sp)
        ,.wvalid_sp                              (wvalid_sp)
        ,.wlast_sp                               (w_pyld_sp[0])
        ,.aw_last                                (sp_osaw_awlast_o)
      );
    end else begin
    end
  endgenerate
  
  assign w_fifo_pop_n     = (A2X_DOWNSIZE==1)? upk_w_fifo_pop_n : spc_w_fifo_pop_n;

  //*************************************************************************************
  //Endian Convert 
  // - converts Little Endian to Big Endian (BE-8)
  //*************************************************************************************
  // spyglass disable_block W164a
  // SMD: Identifies assignments in which the LHS width is less than the RHS width
  // SJ: w_pyld_fifo_o is of write width FIFO. However, only upto SP payload width is required for sp_endian_pyld_o.
  generate 
  if (A2X_SP_ENDIAN!=0) begin: LE_TO_BE_8
    assign sp_endian_pyld_i = (A2X_DOWNSIZE==1)? upk_w_pyld_o     : w_pyld_fifo_o;
    i_axi_a2x_1_DW_axi_a2x_x2x_et
     #(
       .A2X_PYLD_W             (A2X_W_SP_PYLD_W)
      ,.A2X_DW                 (A2X_SP_DW) 
      ,.WRITE_CH               (1)  // write channel
    ) U_a2x_w_sp_et (
      // Outputs
       .pyld_o                 (sp_endian_pyld_o) 
      // Inputs
      ,.pyld_i                 (sp_endian_pyld_i) 
      ,.size_i                 (sp_endian_size_i)
    );
  end else begin
    assign sp_endian_pyld_o = (A2X_DOWNSIZE==1)? upk_w_pyld_o     : w_pyld_fifo_o; 
  end
  endgenerate
  // spyglass enable_block W164a

  //*************************************************************************************
  //                             Write Data SP Control 
  //*************************************************************************************
  generate 
  if ((A2X_PP_MODE==0) || (A2X_DOWNSIZE==1) || (A2X_UPSIZE==1) ) begin: SPC
    i_axi_a2x_1_DW_axi_a2x_w_spc
     #(
       .A2X_PP_MODE                            (A2X_PP_MODE)
      ,.A2X_SP_DW                              (A2X_SP_DW)
      ,.A2X_SP_WSTRB_DW                        (A2X_SP_WSTRB_DW)  
      ,.A2X_WSBW                               (A2X_WSBW)  
      ,.A2X_W_AWLEN_PYLD_W                     (A2X_BLW)
      ,.A2X_W_SP_PYLD                          (A2X_W_SP_PYLD_W)
      ,.A2X_EQSIZED                            (A2X_EQSIZED)
    ) U_a2x_w_spctrl (
      // Outputs
       .w_pyld_o                               (w_pyld_sp)
      ,.w_fifo_pop_n                           (spc_w_fifo_pop_n)
      ,.spc_fifo_pop_n                         (sp_osaw_fifo_pop_n)
      ,.strobe                                 (spc_strobe)
      
      // Inputs
      ,.clk                                    (clk_sp)
      ,.resetn                                 (resetn_sp)
      ,.wready_i                               (wready_sp)
      ,.wvalid_i                               (wvalid_sp)     
      ,.awlen_i                                (sp_osaw_awlen_o)
      ,.awlast_sp                              (sp_osaw_awlast_o)
      ,.wbuf_mode                              (wbuf_mode)
      ,.w_pyld_i                               (sp_endian_pyld_o)
    );
    
  end else begin
    assign w_pyld_sp           = sp_endian_pyld_o;
    assign spc_w_fifo_pop_n    = ~(wready_sp & wvalid_sp);
    assign spc_strobe          = 1'b0; 
    assign sp_osaw_fifo_pop_n  = ~(wready_sp & wvalid_sp & w_pyld_sp[0]);
  end
  endgenerate
  
  // SP Write Data Valid - Equalled sized AXI Configs have no dependancy on SPC FIFO
  assign wvalid_sp         = !(w_fifo_empty | sp_osaw_fifo_empty);

endmodule
//Revision: $Id: //dwh/DW_ocb/DW_axi_a2x/amba_dev/src/DW_axi_a2x_w.v#103 $
