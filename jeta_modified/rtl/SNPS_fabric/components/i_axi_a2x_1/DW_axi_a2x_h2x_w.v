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
// Revision: $Id: //dwh/DW_ocb/DW_axi_a2x/amba_dev/src/DW_axi_a2x_h2x_w.v#1 $ 
// --------------------------------------------------------------------
*/

`include "DW_axi_a2x_all_includes.vh"

//*************************************************************************************
// AHB Write to AXI Write Translation
// - Accepts a Write when Space Available.
// - Breaks INCR's into Defined length AXI Transactions
// - Splits Non-Bufferable Write on Last Beat of Defined length or First Beat of INCR.
// - Recalls Non-Bufferable Writes from Split when response available.
// - Returns Non-Bufferable Response when recalled master returns.
// - Returns hready low for FIFO Full status.
// 
//                                        |----------|
//                |------------|      |-->|    AW    |---->
//             |-------------| |      |   |----------|
//             |    WID      | |------| 
//  ---------->|             |-|      |   |----------|
//             |-------------|        |-->|    WD    |---->
//                                        |----------|
//
//*************************************************************************************

module i_axi_a2x_1_DW_axi_a2x_h2x_w (/*AUTOARG*/
   // Outputs
   w_hready_resp, w_split_resp, w_retry_resp, w_error_resp, w_hsplit, 
   awvalid, aw_pyld, wvalid, w_pyld, bready, busy, w_buf_full,
   // Inputs
   clk, resetn, hsel, hready, hwrite, hburst, htrans, hburst_dp, hsize_dp,
   ha_pyld, hwdata, hwdata_sb, awready, wready, bvalid, b_pyld,
   lk_req, unlk_req, lk_grant, unlk_grant, unlk_grant_d, unlk_cmp, unlk_aw_pyld, unlk_w_pyld, 
   hmastlock, hready_resp_i, unlk_seq, lk_seq
   );
  //*************************************************************************************
  // Parameter Decelaration
  //*************************************************************************************
  parameter   A2X_RS_RATIO                    = 1;
  parameter   A2X_UPSIZE                      = 0; 
  parameter   A2X_DOWNSIZE                    = 0; 
  parameter   A2X_PP_ENDIAN                   = 0; 
  parameter   A2X_LOCKED                      = 0; 

  parameter   A2X_SPLIT_MODE                  = 0;
  parameter   A2X_AHB_LITE_MODE               = 0;
  parameter   A2X_NUM_AHBM                    = 1;
  parameter   A2X_BRESP_MODE                  = 1; 

  parameter   A2X_BLW                         = 4;
  parameter   A2X_AW                          = 32;

  parameter   A2X_HASBW                       = 1;
  parameter   A2X_BSBW                        = 1;
  parameter   A2X_WSBW                        = 1;

  parameter   A2X_PP_DW                       = 32;
  parameter   A2X_PP_NUM_BYTES                = 4;
  parameter   A2X_PP_WSTRB_DW                 = 4;
  parameter   A2X_PP_NUM_BYTES_LOG2           = 2;

  parameter   A2X_SP_DW                       = 32;
  parameter   A2X_SP_NUM_BYTES_LOG2           = 2;

  parameter   A2X_AW_PYLD_W                   = 32;  
  parameter   A2X_W_PYLD_W                    = 32;
  parameter   A2X_B_PYLD_W                    = 32;
  parameter   HREADY_LOW_PERIOD               = 8;
  parameter   A2X_AHB_WBF_SPLIT               = 0;  // 1 - Enable Split capability on Buffer Full

  parameter   AW_BUF_FULL_EN                  = 0;
  parameter   WD_BUF_FULL_EN                  = 0; 

  // Can't have a signal decelaration of A2X_PP_NUM_BYTES_LOG2-1:0 when (A2X_PP_NUM_BYTES_LOG2==0
  localparam  PP_NUM_BYTES_LOG2     = (A2X_PP_NUM_BYTES_LOG2==0)? 1 : A2X_PP_NUM_BYTES_LOG2;

  localparam  A2X_PP_MAX_SIZE       = (A2X_PP_DW==8)?0:(A2X_PP_DW==16)?1:(A2X_PP_DW==32)?2:(A2X_PP_DW==64)?3:(A2X_PP_DW==128)?4:(A2X_PP_DW==256)?5:(A2X_PP_DW==512)?6:7;

  localparam  A2X_SP_MAX_SIZE       = (A2X_SP_DW==8)?0:(A2X_SP_DW==16)?1:(A2X_SP_DW==32)?2:(A2X_SP_DW==64)?3:(A2X_SP_DW==128)?4:(A2X_SP_DW==256)?5:(A2X_PP_DW==512)?6:7;

  localparam  PP_AW                           = 0;
  localparam  PP_AWFULL                       = 1;

  // j: Write Data FSM States
  localparam  PP_W_NORMAL                     = 3'b011;
  localparam  PP_W_AP_BUSY                    = 3'b010;
  localparam  PP_W_BUF_FULL                   = 3'b001;
  localparam  PP_AW_BUF_FULL                  = 3'b000;
  localparam  PP_BF_SPLIT                     = 3'b100;
  localparam  PP_LOCK                         = 3'b101;
  
  //*************************************************************************************
  // I/O Decelaration
  //*************************************************************************************
  input                                    clk;
  input                                    resetn;

  input                                    hsel;         // AHB Select  
  input                                    hready;       // AHB Select  
  //spyglass disable_block W240
  //SMD: An input has been declared but is not read.
  //SJ : These signals are used in specific config only 
  input                                    hready_resp_i;
  //spyglass enable_block W240
  input                                    hwrite;       // AHB Select  
  input  [`A2X_HBLW-1:0]                   hburst;       // AHB burst             
  input  [1:0]                             htrans;       // AHB address phase     
  input                                    hmastlock; 
  input  [`A2X_HBLW-1:0]                   hburst_dp;  
  //spyglass disable_block W240
  //SMD: An input has been declared but is not read.
  //SJ : These signals are used in specific config only 
  input  [2:0]                             hsize_dp;  
  //spyglass enable_block W240
  input  [A2X_AW_PYLD_W-1:0]               ha_pyld;

  input  [A2X_PP_DW-1:0]                   hwdata;       // AHB write data        
  input  [A2X_WSBW-1:0]                    hwdata_sb;    // AHB Write Data Sideband Bus

  output                                   w_hready_resp; // AHB Write Response
  output                                   w_split_resp;
  output                                   w_retry_resp;
  output                                   w_error_resp;
  output [A2X_NUM_AHBM-1:0]                w_hsplit; 

  // AXI Write Request   
  input                                    awready;    // AXI write ready             
  output                                   awvalid;    // AXI write command valid        
  output [A2X_AW_PYLD_W-1:0]               aw_pyld;    // AXI write payload
                      
  // AXI read response & read data                       
  input                                    wready;     // AXI Write ready             
  output                                   wvalid;     // AXI Write response valid       
  output [A2X_W_PYLD_W-1:0]                w_pyld;     // AXI Write Payload

  // AXI write response                                  
  input                                    bvalid;     // AXI write response valid      
  output                                   bready;     // AXI write response ready            
  input [A2X_B_PYLD_W-1:0]                 b_pyld;     // AXI write response Payload   

  input                                    lk_req;
  input                                    unlk_req;
  input                                    lk_grant;
  //spyglass disable_block W240
  //SMD: An input has been declared but is not read.
  //SJ : These signals are used in specific config only 
  input                                    lk_seq;
  //spyglass enable_block W240
  input                                    unlk_grant;
  input                                    unlk_grant_d;
  input                                    unlk_cmp;
  input                                    unlk_seq;
  input [A2X_AW_PYLD_W-1:0]                unlk_aw_pyld;
  input [A2X_W_PYLD_W-1:0]                 unlk_w_pyld;

  output                                   busy;
  output                                   w_buf_full;

  //*************************************************************************************
  //Signal Decelaration
  //******************************************************************************** on*****
  wire    [`A2X_IDW-1:0]                       id;               // Payload Decode
  wire    [A2X_AW-1:0]                         addr;   
  wire    [2:0]                                size;  
  wire    [2:0]                                prot; 
  wire    [3:0]                                cache; 
  wire    [1:0]                                lock;  
  wire    [1:0]                                burst; 
  wire                                         resize;
  wire    [A2X_HASBW-1:0]                      addr_sb;
  wire    [A2X_BLW-1:0]                        alen;
  wire    [31:0]                               alen_w;
  reg     [A2X_BLW-1:0]                        alen_o;
  wire    [A2X_BLW-1:0]                        alen_bus [0:A2X_NUM_AHBM-1];
  wire    [31:0]                               hincr_wbcnt_dec;
  reg     [31:0]                               hincr_wbcnt;


  wire                                         h2x_valid;       // AHB IF 
  wire   [A2X_NUM_AHBM-1:0]                    hid_valid;
  wire   [A2X_NUM_AHBM-1:0]                    w_recall_state_id;
  wire                                         hburst_type; 

  wire                                         htrans_nseq;
  wire                                         htrans_seq;
  wire                                         htrans_busy;
  wire                                         hburst_single;
  wire                                         hburst_incr;

  wire   [A2X_NUM_AHBM-1:0]                    w_hready_resp_id;   // Write Response per ID
  wire   [A2X_NUM_AHBM-1:0]                    w_error_resp_id;
  wire   [A2X_NUM_AHBM-1:0]                    w_retry_resp_id;
  wire   [A2X_NUM_AHBM-1:0]                    w_split_resp_id;
  wire   [A2X_NUM_AHBM-1:0]                    w_buf_state_id;
  wire   [A2X_NUM_AHBM-1:0]                    w_nbuf_state_id;
  wire   [A2X_NUM_AHBM-1:0]                    w_busy_id;

  reg    [A2X_NUM_AHBM-1:0]                    hid_1hot_r;           // ID One-Hot Decode
  reg    [A2X_NUM_AHBM-1:0]                    bid_1hot_r;
  reg    [A2X_NUM_AHBM-1:0]                    bf_id_1hot_r;
  wire   [A2X_NUM_AHBM-1:0]                    hid_1hot_w;           // ID One-Hot Decode
  wire   [A2X_NUM_AHBM-1:0]                    bid_1hot_w;
  wire   [A2X_NUM_AHBM-1:0]                    bf_id_1hot_w;
  wire   [A2X_NUM_AHBM-1:0]                    bf_id_1hot;
  wire   [A2X_NUM_AHBM-1:0]                    hid_1hot;           // ID One-Hot Decode
  wire   [A2X_NUM_AHBM-1:0]                    bid_1hot;
  reg                                          wvalid_dp_r;
  wire                                         wvalid_dp;

  wire   [A2X_PP_WSTRB_DW-1:0]                 wstrb;              // AXI PP Write Channel
  wire   [A2X_PP_DW-1:0]                       wdata;     
  wire   [A2X_WSBW-1:0]                        wsideband; 
  wire                                         wlast;
  wire   [A2X_W_PYLD_W-1:0]                    w_pyld_i;

  wire   [A2X_NUM_AHBM-1:0]                    bid_valid;
  wire   [`A2X_IDW-1:0]                        bid;               // AXI PP B Channel 
  wire   [`A2X_BRESPW-1:0]                     bresp;
  wire   [A2X_BSBW-1:0]                        bsideband;

  reg    [`A2X_IDW-1:0]                        wid;              // Registered Version of last Write ID. 

  wire   [A2X_AW_PYLD_W-1:0]                   aw_pyld;          // AXI write payload
  reg    [A2X_AW_PYLD_W-1:0]                   aw_pyld_r;        // AXI write payload
  reg    [A2X_AW_PYLD_W-1:0]                   aw_pyld_f;        
  reg                                          aw_pyld_f_valid;
  wire   [A2X_NUM_AHBM-1:0]                    awvalid_id;       // AW Valid per ID

  wire   [A2X_NUM_AHBM-1:0]                    wvalid_id;        // W Valid per Id
  wire   [A2X_NUM_AHBM-1:0]                    wlast_id;         // Wlast per ID
  wire   [A2X_NUM_AHBM-1:0]                    bready_id;        // B Ready Per ID
  wire   [A2X_NUM_AHBM-1:0]                    hw_ebt_id;        // AHB Write EBT'd
  wire   [A2X_NUM_AHBM-1:0]                    hincr_last_id;    // AHB Write EBT'd
  wire   [A2X_NUM_AHBM-1:0]                    os_w_id;          // Outstanding AHB Defined length Write
  wire   [A2X_NUM_AHBM-1:0]                    hw_nbuf_id;       // AHB Non-Bufferable Write 
  reg                                          hw_nbuf_dp_r;
  wire                                         hw_nbuf_dp;

  wire   [PP_NUM_BYTES_LOG2-1:0]               align_addr;
  wire   [A2X_PP_NUM_BYTES-1:0]                wstrb_w;
  reg    [A2X_PP_NUM_BYTES-1:0]                wstrb_r;
  
  reg                                          wlast_dp;

  reg    [2:0]                                 bfstate;
  reg    [2:0]                                 nxt_bfstate;
  wire                                         st_bfchange;
  
  wire                                         w_split_resp_r;

  wire                                         bf_hready;
  reg                                          bf_hready_r;
  wire                                         bf_hready_red;
  wire                                         bf_hready_resp;
  reg                                          bf_hready_resp_r;

  reg   [7:0]                                  size_1hot;
  reg   [7:0]                                  size_1hot_w;           // j: Additional signal used to increase code coverage results
  wire  [7:0]                                  wrap_len; 
  reg   [3:0]                                  wrap_ub_len;

  wire                                         ebt_incr_last;         // j: Address and Data phase version of EBT condtion
  
  reg                                          holding_pyld_valid;    // j: Write data holding register is valid
  reg   [A2X_W_PYLD_W-1:0]                     holding_pyld_r;        // j: Write data holding register
  reg   [`A2X_IDW-1:0]                         bf_id_r;  
  wire  [A2X_W_PYLD_W-1:0]                     holding_pyld;        // j: Write data holding register

  reg   [7:0]                                  bfcnt;
  wire  [`A2X_IDW-1:0]                         bf_id;  
  wire                                         bf_timeout;

  wire                                         unlk_wvalid;
  wire                                         unlk_awvalid;
  wire                                         bvalid_w;
  wire                                         unlk_hready;
  wire                                         awready_s;

  //***************************************************************************************************************
  // Logic to latch the wdata when the address is BUSY

  reg  [A2X_PP_DW-1:0]                         hwdata_reg;             // register hwdata when BUSY 
  reg  [A2X_PP_WSTRB_DW-1:0]                   wstrb_w_reg;            // register wstrb when BUSY
  reg  [A2X_WSBW-1:0]                          hwdata_sb_reg;          // register sideband when BUSY
  wire [A2X_PP_DW-1:0]                         hwdata_busy_maintain;   // hwdata maintained during BUSY cycles           
  wire [A2X_PP_WSTRB_DW-1:0]                   wstrb_w_busy_maintain;  // strobe maintained during BUSY cycles           
  wire [A2X_WSBW-1:0]                          hwdata_sb_busy_maintain;// sideband maintained during BUSY cycles           

  reg                                          htrans_busy_reg;  // htrans is busy registred
  wire                                         load_hwdata;  // Load the hwdata register to maintain hwdata during BUSY cycles

  assign load_hwdata = htrans_busy & (~htrans_busy_reg);  // Start BUSY period pulse

  assign hwdata_busy_maintain      = htrans_busy_reg ? hwdata_reg : hwdata; 
  assign wstrb_w_busy_maintain     = htrans_busy_reg ? wstrb_w_reg : wstrb_w;
  assign hwdata_sb_busy_maintain   = htrans_busy_reg ? hwdata_sb_reg :hwdata_sb;
  
  // Maintained Version of Write Data when BUSY cycles
  always @(posedge clk or negedge resetn) begin: hwdata_r_SEQ_PROC
    if (resetn == 1'b0) begin
       htrans_busy_reg  <= 1'b0;
       hwdata_reg <=  {A2X_PP_DW{1'b1}};
       wstrb_w_reg  <=  {A2X_PP_WSTRB_DW{1'b1}};
       hwdata_sb_reg <= {A2X_WSBW{1'b1}};
    end 
    else begin
      htrans_busy_reg  <= htrans_busy;
      if (load_hwdata) begin 
        hwdata_reg <= hwdata;
        wstrb_w_reg  <= wstrb_w;
        hwdata_sb_reg <= hwdata_sb;
      end
   end
  end
  
  //*************************************************************************************
  // ID One-Hot Decode
  //
  // - Dummy Master is 0 so never assert bit zero,
  //*************************************************************************************
  //spyglass disable_block W415a
  //SMD: Signal may be multiply assigned (beside initialization) in the same scope.
  //SJ : This is not an issue. It is initialized before assignment to avoid latches.
  generate 
  if (A2X_NUM_AHBM>2) begin: ONEHOT
    always @(*) begin:id_1hot_PROC
      integer num;
      hid_1hot_r   = {A2X_NUM_AHBM{1'b0}}; 
      bid_1hot_r   = {A2X_NUM_AHBM{1'b0}}; 
      bf_id_1hot_r  = {A2X_NUM_AHBM{1'b0}}; 
      for(num=1; num<A2X_NUM_AHBM; num=num+1) begin
        if((bid==num) && (A2X_BRESP_MODE!=0)) bid_1hot_r[num] = 1'b1;
        if(id==num)    hid_1hot_r[num] = 1'b1;
        if((bf_id==num) && (A2X_SPLIT_MODE==1)) bf_id_1hot_r[num] = 1'b1;
      end
    end
    assign hid_1hot_w   = hid_1hot_r;
    assign bid_1hot_w   = bid_1hot_r;
    assign bf_id_1hot_w = bf_id_1hot_r;
  end else begin
    assign hid_1hot_w   = (id==1)?    2'b10 : {A2X_NUM_AHBM{1'b0}};
    assign bid_1hot_w   = (bid==1)?   2'b10 : {A2X_NUM_AHBM{1'b0}};
    assign bf_id_1hot_w = (bf_id==1)? 2'b10 : {A2X_NUM_AHBM{1'b0}};
  end
  endgenerate
  //spyglass enable_block W415a

  assign hid_1hot   = (A2X_AHB_LITE_MODE==1)? 2'b10 : hid_1hot_w; 
  assign bid_1hot   = (A2X_AHB_LITE_MODE==1)? 2'b10 : bid_1hot_w; 
  assign bf_id_1hot = (A2X_AHB_LITE_MODE==1)? 2'b10 : bf_id_1hot_w; 

  //*************************************************************************************
  // HTRANS Decode
  //*************************************************************************************
  assign htrans_nseq    = (hsel & htrans==`HTRANS_NSEQ); // j:
  assign htrans_seq     = (hsel & htrans==`HTRANS_SEQ);  // j:
  assign htrans_busy    = (hsel & hwrite & htrans==`HTRANS_BUSY); // j:
  assign hburst_single  = (hburst==`HBURST_SINGLE);
  assign hburst_incr    = (hburst==`HBURST_INCR);
  
  assign busy = |w_busy_id;

  //*************************************************************************************
  //Payload Decode
  //*************************************************************************************
  assign {hburst_type, addr_sb, id, addr, resize, alen, size, burst, lock, cache, prot} = ha_pyld;

  //*************************************************************************************
  // AHB Write INCR Reszie Decode. 
  //*************************************************************************************
  assign hincr_wbcnt_dec = (hburst_type==1'b1)? (1 << alen) : 0; 
  generate 
  //-------------------------------- Write Upsizing Configurations -----------------------
  // spyglass disable_block TA_09
  // SMD: Reports cause of uncontrollability or unobservability and estimates the number of nets whose controllability/ observability is impacted
  // SJ : Few bits of RHS may not be always required 
  if (A2X_UPSIZE==1) begin: US_HINCR
    always @(*) begin: us_hincr_wbcnt_PROC
      if ((size!=A2X_PP_MAX_SIZE) || (!resize))
        // spyglass disable_block W164b
        // SMD: Identifies assignments in which the LHS width is greater than the RHS width
        // SJ : This is not a functional issue, this is as per the requirement.
        // spyglass disable_block W164a
        // SMD: Identifies assignments in which the LHS width is less than the RHS width
        // SJ : This is not a functional issue, this is as per the requirement.
        // spyglass disable_block W484
        // SMD: Possible loss of carry or borrow due to addition or subtraction
        // SJ : This is not a functional issue, this is as per the requirement.
        hincr_wbcnt = (hincr_wbcnt_dec>=(1<<A2X_BLW))? (1<<A2X_BLW) : hincr_wbcnt_dec;
      // If Full Sized Transaction
      else if (hincr_wbcnt_dec>=((1<<A2X_BLW)*A2X_RS_RATIO))
        hincr_wbcnt = ((1<<A2X_BLW)*A2X_RS_RATIO)- addr[A2X_SP_NUM_BYTES_LOG2-1:A2X_PP_NUM_BYTES_LOG2];
      else 
        hincr_wbcnt = hincr_wbcnt_dec - addr[A2X_SP_NUM_BYTES_LOG2-1:A2X_PP_NUM_BYTES_LOG2];
        // spyglass enable_block W484
        // spyglass enable_block W164a
        // spyglass enable_block W164b
    end 
  // spyglass enable_block TA_09
  //-------------------------------- Write Downsizing Configurations -----------------------
  end else if (A2X_DOWNSIZE==1) begin: DS_HINCR
    wire   [2:0]                               sp_size; 
    wire   [2:0]                               size_ratio; 
    wire   [2:0]                               max_size_ratio; 
    wire   [31:0]                              pp_numbytes;
    wire   [31:0]                              pp_bytes_beat;
    wire   [31:0]                              max_sp_numbytes;

    // spyglass disable_block W164b
    // SMD: Identifies assignments in which the LHS width is greater than the RHS width
    // SJ : This is not a functional issue, this is as per the requirement.
    // spyglass disable_block W164a
    // SMD: Identifies assignments in which the LHS width is less than the RHS width
    // SJ : This is not a functional issue, this is as per the requirement.
    assign sp_size         = (size>=A2X_SP_MAX_SIZE)? A2X_SP_MAX_SIZE : size; 
    assign pp_numbytes     = hincr_wbcnt_dec << size;
    assign pp_bytes_beat   = (1 << size);
    assign max_sp_numbytes = (1<<A2X_BLW)  << sp_size;

    assign max_size_ratio  = A2X_PP_MAX_SIZE-A2X_SP_MAX_SIZE;
    assign size_ratio      = (size>=A2X_SP_MAX_SIZE)? size-A2X_SP_MAX_SIZE : 3'b0;   
    // spyglass enable_block W164a
    // spyglass enable_block W164b
    
    // HINCR Converted into Bytes 
    // - If total number of PP Bytes greater than Max SP Bytes then a new PP
    //   address is captured after Max SP Bytes Captured.
    // - If Number of PP Bytes per Beat is greater than max SP Bytes then
    //   a new address is captured on every AHB Transfer. 
    always @(*) begin: ds_hincr_wbcnt_PROC
      if (pp_bytes_beat>max_sp_numbytes)
        hincr_wbcnt = 1; 
      else if (pp_numbytes>max_sp_numbytes)
        hincr_wbcnt = max_sp_numbytes>>size;
      else 
        hincr_wbcnt = hincr_wbcnt_dec;
    end

  //-------------------------------- Write Equaled Sized Configurations -----------------------
  end else begin
    always @(*) begin: hincr_wbcnt_PROC
      hincr_wbcnt = (hincr_wbcnt_dec>=(1<<A2X_BLW))? (1<<A2X_BLW) : hincr_wbcnt_dec;
    end
  end
  endgenerate
  
  // Write ALEN Decode 
  // spyglass disable_block W164b
  // SMD: Identifies assignments in which the LHS width is greater than the RHS width
  // SJ : This is not a functional issue, this is as per the requirement.
  assign alen_w = (hburst_type==1'b0)? alen : (A2X_BRESP_MODE==0)? (hincr_wbcnt-1) : (A2X_BRESP_MODE==1)? 32'd0 : (cache[0])? (hincr_wbcnt-1) : 32'd0;
  // spyglass enable_block W164b

  // A2X Enabled for Write 
  assign h2x_valid = hsel & hready & hwrite;
  assign hid_valid = hid_1hot;

  assign bid_valid = bid_1hot; 

  //*************************************************************************************
  // PP B Channel Payload Decode
  //*************************************************************************************
  assign {bsideband, bid, bresp} = b_pyld;

  // Respond to B Channel to pop data from FIFO.
  assign bready = |bready_id; 

  //*************************************************************************************
  // AHB Master Write Instance
  // - Dummy Master is 0 so never assert bit zero,
  //*************************************************************************************
  generate
  genvar i;
    for (i = 1; i <A2X_NUM_AHBM; i=i+1) begin : UWID 
      
      i_axi_a2x_1_DW_axi_a2x_h2x_w_id
       #(
        .A2X_BRESP_MODE                 (A2X_BRESP_MODE) 
       ,.A2X_SPLIT_MODE                 (A2X_SPLIT_MODE)
       ,.A2X_BLW                        (A2X_BLW)
       ,.A2X_LOCKED                     (A2X_LOCKED)
      ) U_a2x_h2x_wid (
         .awvalid                       (awvalid_id[i])
        ,.alen_o                        (alen_bus[i])
        ,.os_w_o                        (os_w_id[i])
        ,.wvalid                        (wvalid_id[i])
        ,.wlast                         (wlast_id[i])
        ,.bready                        (bready_id[i])
        ,.w_hsplit                      (w_hsplit[i])
        ,.w_hready_resp                 (w_hready_resp_id[i])
        ,.w_split_resp                  (w_split_resp_id[i])
        ,.w_error_resp                  (w_error_resp_id[i])
        ,.w_retry_resp                  (w_retry_resp_id[i])
        ,.hw_ebt                        (hw_ebt_id[i])
        ,.hincr_last                    (hincr_last_id[i])
        ,.hw_nbuf                       (hw_nbuf_id[i])
        ,.w_buf_state                   (w_buf_state_id[i])
        ,.w_recall_state                (w_recall_state_id[i])
        ,.busy                          (w_busy_id[i])
        ,.nbuf_state                    (w_nbuf_state_id[i])
        
        // Inputs
        ,.clk                           (clk)
        ,.resetn                        (resetn)
        ,.hsel                          (hsel)
        ,.hwrite                        (hwrite)
        ,.hready                        (hready)
        ,.hid_valid                     (hid_valid[i])
        ,.hburst                        (hburst)
        ,.htrans                        (htrans)
        ,.hburst_dp                     (hburst_dp)
        ,.cache_i                       (cache)
        ,.alen_i                        (alen_w)
        ,.wrap_ub_len_i                 (wrap_ub_len)
        ,.bvalid                        (bvalid_w)
        ,.bid_valid                     (bid_valid[i])
        ,.bf_timeout                    (bf_timeout)
        ,.bresp                         (bresp)
        ,.hmastlock                     (hmastlock)
      );

    end
  endgenerate
  
  // Dummy Master
  assign w_hsplit[0]           = 1'b0; 
  assign hw_ebt_id[0]          = 1'b0;
  assign hw_nbuf_id[0]         = 1'b0;
  assign hincr_last_id[0]      = 1'b0;
  assign os_w_id[0]            = 1'b0;
  assign w_hready_resp_id[0]   = 1'b1;
  assign w_retry_resp_id[0]    = 1'b0;
  assign w_error_resp_id[0]    = 1'b0;
  assign w_split_resp_id[0]    = 1'b0;
  assign w_buf_state_id[0]     = 1'b0;
  assign w_nbuf_state_id[0]    = 1'b0;
  assign w_recall_state_id[0]  = 1'b0;
  assign w_busy_id[0]          = 1'b0;

  assign bready_id[0]          = 1'b0;
  assign wlast_id[0]           = 1'b0;
  assign wvalid_id[0]          = 1'b0;
  assign awvalid_id[0]         = 1'b0;
  assign alen_bus[0]           = {A2X_BLW{1'b0}};

  //*************************************************************************************
  // AXI Write Wrap Decode
  //
  // If an AHB Wrap is EBT'd then we need to generatat a wlast when the
  // address boundary is reached. This is done by calculating the last address
  // before the wrap occurs and asserting wlast when the AHB haddr equals this
  // address.
  //*************************************************************************************
  //spyglass disable_block W415a
  //SMD: Signal may be multiply assigned (beside initialization) in the same scope.
  //SJ : This is not an issue. It is initialized before assignment to avoid latches.
  always @(*) begin: size1hot_PROC
    integer k; 
    size_1hot = 8'b0; 
    for (k=0; k<=A2X_PP_MAX_SIZE; k=k+1)
      // Signed and unsigned operands should not be used in same operation.
      // k can only be an integer, since it is a loop index. It is a design requirement to
      // use k in the following operation and it will not have any adverse effects on the 
      // design. So signed and unsigned operands are used to reduce the logic.
      if (k==size) size_1hot[k] = 1'b1;
  end
  // j: Added size_1hot_w to improve coverage results on the case expression below
  always @(*) begin:h2xw_1hot_PROC
    size_1hot_w[7:0] = 8'h0;
    size_1hot_w[A2X_PP_MAX_SIZE:0] = size_1hot[A2X_PP_MAX_SIZE:0];
  end
  //spyglass enable_block W415a

  // spyglass disable_block W164b
  // SMD: Identifies assignments in which the LHS width is greater than the RHS width
  // SJ : This is not a functional issue, this is as per the requirement.
  // spyglass disable_block W164a
  // SMD: Identifies assignments in which the LHS width is greater than the RHS width
  // SJ : This is not a functional issue, this is as per the requirement.
  assign wrap_len = (A2X_BLW==4)?{4'd0, alen}:(A2X_BLW==5)?{3'd0, alen}:(A2X_BLW==6)?{2'd0, alen}:{1'd0, alen};
  // spyglass enable_block W164a
  // spyglass enable_block W164b

  // **************************************************************************************
  // Decode Wrap Upper boundary Address
  // **************************************************************************************
  always @(*) begin : upper_bound_wrap_PROC
    wrap_ub_len = 4'd0;
    case ({wrap_len,size_1hot_w}) // j:
      {8'd3,8'd1}   : wrap_ub_len[1:0] = ~addr[1:0]; // 4    beats of 8 bits
      {8'd7,8'd1}   : wrap_ub_len[2:0] = ~addr[2:0]; // 8    beats of 8 bits
      {8'd15,8'd1}  : wrap_ub_len[3:0] = ~addr[3:0]; // 16   beats of 8 bits        
      
      {8'd3,8'd2}   : wrap_ub_len[1:0] = ~addr[2:1]; // 4   beats of 16 bits
      {8'd7,8'd2}   : wrap_ub_len[2:0] = ~addr[3:1]; // 8   beats of 16 bits
      {8'd15,8'd2}  : wrap_ub_len[3:0] = ~addr[4:1]; // 16  beats of 16 bits
      
      {8'd3,8'd4}   : wrap_ub_len[1:0] = ~addr[3:2]; // 4   beats of 32 bits
      {8'd7,8'd4}   : wrap_ub_len[2:0] = ~addr[4:2]; // 8   beats of 32 bits
      {8'd15,8'd4}  : wrap_ub_len[3:0] = ~addr[5:2]; // 16  beats of 32 bits
      
      {8'd3,8'd8}   : wrap_ub_len[1:0] = ~addr[4:3]; // 4   beats of 64 bits
      {8'd7,8'd8}   : wrap_ub_len[2:0] = ~addr[5:3]; // 8   beats of 64 bits
      {8'd15,8'd8}  : wrap_ub_len[3:0] = ~addr[6:3]; // 16  beats of 64 bits
      
      {8'd3,8'd16}  : wrap_ub_len[1:0] = ~addr[5:4]; // 4   beats of 128 bits
      {8'd7,8'd16}  : wrap_ub_len[2:0] = ~addr[6:4]; // 8   beats of 128 bits
      {8'd15,8'd16} : wrap_ub_len[3:0] = ~addr[7:4]; // 16  beats of 128 bits
      
      {8'd3,8'd32}  : wrap_ub_len[1:0] = ~addr[6:5]; // 4   beats of 256 bits 
      {8'd7,8'd32}  : wrap_ub_len[2:0] = ~addr[7:5]; // 8   beats of 256 bits
      {8'd15,8'd32} : wrap_ub_len[3:0] = ~addr[8:5]; // 16  beats of 256 bits
      
      {8'd3,8'd64}  : wrap_ub_len[1:0] = ~addr[7:6]; // 4   beats of 512 bits 
      {8'd7,8'd64}  : wrap_ub_len[2:0] = ~addr[8:6]; // 8   beats of 512 bits
      {8'd15,8'd64} : wrap_ub_len[3:0] = ~addr[9:6]; // 16  beats of 512 bits

      {8'd3,8'd128}  : wrap_ub_len[1:0] = ~addr[8:7]; // 4   beats of 1024 bits 
      {8'd7,8'd128}  : wrap_ub_len[2:0] = ~addr[9:7]; // 8   beats of 1024 bits
      {8'd15,8'd128} : wrap_ub_len[3:0] = ~addr[10:7]; // 16  beats of 1024 bits

      default       : wrap_ub_len      = 4'd0;             
    endcase // case()
  end
  
  //*************************************************************************************
  // AXI Write Length Decode
  //*************************************************************************************
  //spyglass disable_block W415a
  //SMD: Signal may be multiply assigned (beside initialization) in the same scope.
  //SJ : This is not an issue. It is initialized before assignment to avoid latches.
  always @(*) begin: alenbus_PROC
    integer k; 
    alen_o = {A2X_BLW{1'b0}};
    for (k=0; k<A2X_NUM_AHBM; k=k+1) begin
      alen_o = (alen_bus[k] | alen_o);
    end
  end
  //spyglass enable_block W415a

  //*************************************************************************************
  // Write Strobe Generator
  // - Decode the AXI PP Write Strobe based on the AHB Address.
  //*************************************************************************************
  generate
    if (A2X_PP_NUM_BYTES==1) 
      assign align_addr = {PP_NUM_BYTES_LOG2{1'b0}};
    else
      assign align_addr = addr[PP_NUM_BYTES_LOG2-1:0];
  endgenerate

  reg [127:0] init_strb;
  always @(*) begin: wstrb_dec_PROC
    // j: Re-coded the case expression to improve coverage results
    case(size_1hot_w)
      8'd1   : init_strb = {{127{1'b0}}, 1'b1}       << align_addr; // 8
      8'd2   : init_strb = {{126{1'b0}}, {2{1'b1}}}  << align_addr; // 16
      8'd4   : init_strb = {{124{1'b0}}, {4{1'b1}}}  << align_addr; // 32
      8'd8   : init_strb = {{120{1'b0}}, {8{1'b1}}}  << align_addr; // 64
      8'd16  : init_strb = {{112{1'b0}}, {16{1'b1}}} << align_addr; // 128
      8'd32  : init_strb = {{96{1'b0}},  {32{1'b1}}} << align_addr; // 256
      8'd64  : init_strb = {{64{1'b0}},  {64{1'b1}}} << align_addr; // 512
      8'd128 : init_strb = {128{1'b1}}               << align_addr; // 1024
      default: init_strb = 128'b0;
    endcase
  end 

  // Registered Version of Write Strobe for PP Channel
  always @(posedge clk or negedge resetn) begin: wstrb_PROC
    if (resetn == 1'b0) begin
       wstrb_r <=  {A2X_PP_NUM_BYTES{1'b1}};
    end else begin
      if (hready && hwrite && (htrans_nseq || htrans_seq)) begin // j: Removed "&& hsel" from if expression
        wstrb_r <= init_strb[A2X_PP_NUM_BYTES-1:0];
      end
    end
  end

  assign wstrb_w = wstrb_r[A2X_PP_NUM_BYTES-1:0];

  //*************************************************************************************
  // AXI Write Data Channel
  // - If an AHB Master write transaction is EBT'd and a different AHB Master is attempting
  //   a write we need to generate a wlast for the EBT'd Master. Write last is used by the 
  //   SP Strobe generator to determine if the remaining data beats need to be
  //   strobed. 
  //   
  //   If Previous Transaction was a Busy Cycle and the write Transaction is
  //   EBT'd we need to generate a  write last with data beats strobed. If
  //   valid Data on bus and htrans is BUSY data is not pushed into FIFO until
  //   htrans transtitions to non-busy.
  //*************************************************************************************
  generate 
  if (A2X_PP_ENDIAN!=0) begin: W_ET
    i_axi_a2x_1_DW_axi_a2x_h2x_et
     #(
       .A2X_DW                 (A2X_PP_DW) 
    ) U_a2x_w_pp_et (
      // Outputs
       .data_o                 (wdata) 
      // Inputs
      ,.data_i                 (hwdata_busy_maintain) 
      ,.size_i                 (hsize_dp)
    );
  end else begin
    assign wdata   = hwdata_busy_maintain;
  end
  endgenerate

  assign wstrb     = wstrb_w_busy_maintain;
  assign wsideband = hwdata_sb_busy_maintain;

  //*************************************************************************************
  // This indicates that this AHB Transaction is a Last of a Non-Bufferable Transaction. 
  // - Data Phase version created and held until transaction is split or
  //   Buffer is no longer full
  //*************************************************************************************
  generate 
  if (A2X_BRESP_MODE!=0) begin: NB
    reg hw_nuf_dp_r;
    always @(posedge clk or negedge resetn) begin: nbuf_dp_PROC
      if (resetn == 1'b0) begin
        hw_nbuf_dp_r <= 1'b0;
      end else begin      
        if (|hw_nbuf_id)
          hw_nbuf_dp_r <= 1'b1;
        else if ((bfstate==PP_AW_BUF_FULL) && awready_s && w_split_resp_r && wvalid_dp_r && (!bf_timeout))
          hw_nbuf_dp_r <= 1'b0;
        // CRM_9000573691 fix
        // Added hready && !htrans_busy into clear condition
        else if (((!aw_pyld_f_valid) && (!holding_pyld_valid) && wready) || (hready && (!htrans_busy)))
          hw_nbuf_dp_r <= 1'b0;
      end
    end
    assign hw_nbuf_dp = hw_nbuf_dp_r; 
  end else begin
    assign hw_nbuf_dp = 1'b0; 
  end
  endgenerate

  //*************************************************************************************
  // AHB Write Data Valid
  //
  // If valid address on AHB then valid data will follow on the next clock
  // cycle. Hence the registering of the wvalid for the H2X ID module. 
  //
  // Register cleared if write data is pushed into FIFO or if AHB master is
  // split due to buffer full. 
  //
  // If valid data phase and htrans is busy then data remains on AHB Bus until
  // htrans status changes from busy. 
  //*************************************************************************************
  always @(posedge clk or negedge resetn) begin: wvalid_PROC
    if (resetn == 1'b0) begin
      wvalid_dp_r <= 1'b0;
    end else begin      
      if (|wvalid_id)
        wvalid_dp_r <= 1'b1;
      else if ((bfstate==PP_AW_BUF_FULL) && awready_s && w_split_resp_r && wvalid_dp_r && (!bf_timeout))
        wvalid_dp_r <= 1'b0;
      else if (bf_timeout || (hready && (~htrans_busy)) || (hw_nbuf_dp && (!aw_pyld_f_valid) && (!holding_pyld_valid) && wready))
        wvalid_dp_r <= 1'b0;
    end
  end

  // Signal to indicate a valid data phase while the address phase is NOT BUSY.
  // Do not push into FIFO if busy status on htrans bus, unless transaction is
  // last beat of non-bufferable transaction.
  assign wvalid_dp = wvalid_dp_r & ((hready & (~htrans_busy)) | (hw_nbuf_dp & (!aw_pyld_f_valid) & (!holding_pyld_valid) & wready));
    
  //*************************************************************************************
  // AHB Write Last Data
  //*************************************************************************************
  //  j: START
  //  During an INCR replay of a wrapping burst the _id module
  //  holds the wlast signal active (for the next address) during
  //  the cycles that BUSY is on the htrans bus. This causes the
  //  wlast for the stored busy transfer to be incorrectly asserted
  //  This signal is used to mask the wlast input when htrans==BUSY.
  //  This is safe to do as a BUSY cycle will never be the intended
  //  last transfer of a burst.

  // Indicates an EBT condition or INCR Last
  assign ebt_incr_last = (|hw_ebt_id) | (|hincr_last_id);

  // Registered version of wlast for AHB Write data Phase.
  always @(posedge clk or negedge resetn) begin: wlast_PROC
    if (resetn == 1'b0) begin
      wlast_dp  <= 1'b0; 
    end else begin
      if (|wlast_id)
        wlast_dp <= 1'b1;
      else if ((bfstate==PP_AW_BUF_FULL) && awready_s && w_split_resp_r && wvalid_dp_r && (!bf_timeout))
        wlast_dp <= 1'b0;
      else if (bf_timeout || (hready && (~htrans_busy)) || (hw_nbuf_dp && (!aw_pyld_f_valid) && (!holding_pyld_valid) && wready))
        wlast_dp <= 1'b0;
    end
  end

  // Generate wlast if Last beat of AHB Transaction, if transaction EBT, if
  // last beat of INCR or if transaction is split due to buffer full. 
  assign wlast  = wlast_dp | ebt_incr_last | bf_timeout;

  // Write Data Payload
  assign w_pyld_i    = {wsideband, wid, wstrb, wdata, wlast};

  //*************************************************************************************
  // Registered version of ID for W Channel
  //*************************************************************************************
  always @(posedge clk or negedge resetn) begin: wid_PROC
    if (resetn == 1'b0) begin
      wid <= {`A2X_IDW{1'b0}};
    end else begin      
      if (hready && hsel && hwrite && (htrans_nseq || htrans_seq)) begin // j:
        wid <= id;
      end
    end
  end

  //*************************************************************************************  
  // Scenario 1 Address Buffer Full:
  // - Address placed into a holding register and hready response driven low. 
  // - If awready comes high before hready low count is reaches address is
  // - pushed into FIFO. Otherwise address is disguarded and a split response
  // - is return to the AHB master. 
  //
  // - When hready driven low in response to an address buffer full the
  //   corresponding data is not pushed into the FIFO until address is pushed
  //   in. Hence both the address and data are disguarded when a split
  //   response is returned. 
  //
  // Scenario 2 Write Data Buffer Full:
  // - Write data is placed into a holding register and hready response driven
  //   low. If wready comes high before hready low count is reached data is
  // - pushed into FIFO. Otherwise split response is returned and data is
  //   stored in holding register until write data buffer becomes non-empty.
  //
  //   When hready driven low in response to write data buffer full and the
  //   next transaction on the AHB bus requires a push into the address FIFO,
  //   this push is delayed and the address placed into a holding register.
  //   Hence if the address is split due to buffer full condition both the
  //   address and the corresponding data are disguarded. 
  //
  // Default state PP_W_NORMAL:
  // - while in this state hready_resp is driven active. Only transition out 
  //   of this state if the write data buffer or address buffer becomes full
  //   or during an valid data phase, the address phase is BUSY.
  //
  // Buffer full state PP_W_BUF_FULL:
  // - While in this state hready_resp is driven in-active. Remain in this state
  //   until the write data or address buffer has space for a single data entry.
  // 
  // PP_W_AP_BUSY:
  // - If we have a valid data phase and the current address phase is BUSY, 
  //   we need to load the data into a holding register rather than push it
  //   directly into the data fifo. Until we see the next address phase we do not
  //   know if this current data beat will be the last in the transfer. At this point
  //   we cannot know if the transfer will receive an EBT. If the transfer does 
  //   receive an EBT (down the line) we need to tag the wlast bit onto the data 
  //   packet before pushing into the data fifo.
  //
  // PP_LOCK:
  // - In this state we wait for all current Transaction to complete before pushing into FIFO. 
  //   
  //   PP_W_NORMAL                     = 3;
  //   PP_W_AP_BUSY                    = 2;
  //   PP_W_BUF_FULL                   = 1;
  //   PP_AW_BUF_FULL                  = 0;
  //   PP_BF_SPLIT                     = 4;
  //   PP_LOCK                         = 5; 
  //*************************************************************************************  
  always @(*) begin: nxt_bfstate_PROC
    nxt_bfstate = bfstate;
    case (bfstate)
      PP_W_NORMAL : begin // hready_resp is ACTIVE while in this state
        if (holding_pyld_valid && (!wready) && (WD_BUF_FULL_EN==1)) begin
          nxt_bfstate = PP_W_BUF_FULL;
        end else if (wvalid_dp && hw_nbuf_dp && (!wready) && (WD_BUF_FULL_EN==1)) begin
          nxt_bfstate = PP_W_BUF_FULL;
        // Address phase is BUSY during active data phase
        end else if (wvalid_dp && htrans_busy) begin
          nxt_bfstate = PP_W_AP_BUSY;
        // Write Data Buffer Full during active data phase
        end else if (wvalid_dp && (!wready) && (WD_BUF_FULL_EN==1)) begin
          nxt_bfstate = PP_W_BUF_FULL;
        end else if ((A2X_LOCKED==1) && lk_req) begin
          nxt_bfstate = PP_LOCK;
        end else if ((!unlk_hready) && (A2X_LOCKED==1)) begin
          nxt_bfstate = PP_LOCK;
        // Address Buffer Full during active address phase
        end else if ((!awready_s) && (|awvalid_id) && (AW_BUF_FULL_EN==1)) begin
          nxt_bfstate = PP_AW_BUF_FULL;
        end
      end
      PP_W_BUF_FULL : begin // hready_resp is IN-ACTIVE while in this state
        if (bf_timeout)
          nxt_bfstate = PP_BF_SPLIT;
        else if ((A2X_SPLIT_MODE==1) && ((!unlk_hready) && (A2X_LOCKED==1)))
          nxt_bfstate = PP_LOCK;
        else if (holding_pyld_valid && wready ) begin
          if ( (unlk_req || lk_req) && (A2X_LOCKED==1)) begin
            nxt_bfstate = PP_LOCK;
          end else if (aw_pyld_f_valid || (|awvalid_id) && (AW_BUF_FULL_EN==1)) begin
            nxt_bfstate = PP_AW_BUF_FULL;
          end else begin 
            nxt_bfstate = PP_W_NORMAL;
          end
        end
      end
      PP_AW_BUF_FULL : begin // hready_resp is IN-ACTIVE while in this state
        // Write data & Address buffer has space
        if (bf_timeout)
          nxt_bfstate = PP_BF_SPLIT;
        else if (aw_pyld_f_valid && awready_s) begin
          // If Splitting a due to Last beat of Non-Bufferable
          if (w_split_resp_r && wvalid_dp_r)
            nxt_bfstate = PP_W_NORMAL;
          else if ((A2X_SPLIT_MODE==0) && hw_nbuf_dp && (!wready) && wvalid_dp_r)
            nxt_bfstate = PP_W_NORMAL;
          else if (htrans_busy && wvalid_dp_r)
            nxt_bfstate = PP_W_AP_BUSY;
          else
            nxt_bfstate = PP_W_NORMAL;
        end
      end
      PP_W_AP_BUSY : begin // hready_resp is ACTIVE while in this state
        if(!htrans_busy) begin
          // htrans has become NOT BUSY
          if (wvalid_dp && (!wready) && (WD_BUF_FULL_EN==1)) begin
            nxt_bfstate = PP_W_BUF_FULL;
          end else if ((A2X_LOCKED==1) && lk_req) begin
            nxt_bfstate = PP_LOCK;
          end else if ((!unlk_hready) && (A2X_LOCKED==1)) begin
            nxt_bfstate = PP_LOCK;
            // Address Buffer Full during active address phase
          end else if ((!awready_s) && (|awvalid_id) && (AW_BUF_FULL_EN==1)) begin
            nxt_bfstate = PP_AW_BUF_FULL;
          end else begin
            nxt_bfstate = PP_W_NORMAL;
          end
        end
      end
      PP_BF_SPLIT: begin
          // Not using wready since it is dependant on PP_OSAW FIFO empty
          // status. The PP OSAW remain empty until the AW FIFO is populated.
          if ((A2X_LOCKED==1) && (A2X_SPLIT_MODE==1) && (lk_req || (!unlk_hready)))
            nxt_bfstate = PP_LOCK;
          else if ((!aw_pyld_f_valid) && (A2X_SPLIT_MODE==1) && (!holding_pyld_valid) && awready_s)
            nxt_bfstate = PP_W_NORMAL;
      end
      // Primary Port Lock Transaction
      PP_LOCK: begin
        // Wait for all current Transaction to complete before pushing into FIFO. 
        if (lk_grant) begin
          if (htrans_busy)
            nxt_bfstate = PP_W_AP_BUSY;
          else if (holding_pyld_valid) begin
            nxt_bfstate = PP_W_BUF_FULL;
          end else begin
            nxt_bfstate = PP_W_NORMAL;
          end
        end
      end
      default : nxt_bfstate = PP_W_NORMAL;
    endcase
  end
        
  //  Registered Version of State
  always @(posedge clk or negedge resetn) begin: bfstate_PROC
    if (resetn == 1'b0) begin
      bfstate <=  PP_W_NORMAL;
    end else begin
      bfstate <= nxt_bfstate;
    end
  end

  // State Change
  assign st_bfchange = (bfstate!=nxt_bfstate);

  // bf_hready is registered (with other comb logic) to generate hready_resp
  // on the next cycle. We are able to drive hready_resp active on the AHB bus if the next state
  // is either PP_W_AP_BUSY or PP_W_NORMAL or not a locked state.
  assign bf_hready     = ((nxt_bfstate==PP_W_NORMAL) | (nxt_bfstate==PP_W_AP_BUSY) | (nxt_bfstate==PP_LOCK))? 1'b1 : 1'b0;
  
  // If the A2X received another Locking AHB transaction during the unlock phase it
  // responds with hready low to this transaction until the previous unlock phase has completed. 
  assign unlk_hready  = (unlk_seq & hready & hmastlock & hsel & hwrite & htrans_nseq & bf_hready_resp_r & (!(|w_buf_state_id)) & (!(|w_recall_state_id)))? 1'b0 : 1'b1; 

  // Generate AWVALID & WVALID for PP AW & W Channel when transaction granted.  
  assign unlk_awvalid = (unlk_grant   & unlk_seq );
  // Delayed version of unlock so that address information is pushed into PP OSAW FIFO
  assign unlk_wvalid  = (unlk_grant_d & unlk_seq);

  assign bvalid_w     = bvalid;

  // In the unlocked sequence we want the A2X to treat a new AHB transaction
  // as a buffer full condition. 
  assign awready_s    = (A2X_LOCKED==0)? awready : awready & (!unlk_seq);

  // Used in Locked mode to prevent unlocking transaction been generated until
  // all previous transactions completed. 
  assign w_buf_full   = (bfstate==PP_AW_BUF_FULL)  | (bfstate==PP_W_BUF_FULL);

  //*************************************************************************************  
  // Address Holding Register
  // When in the Locking or Unlocking state and a new transaction appears on
  // the AHB Bus the address of this transaction is captured and the hready is
  // driven low until the transaction can be pushed into the FIFO. 
  //*************************************************************************************  
  //  Registered Version of AW Payload
  always @(posedge clk or negedge resetn) begin: awfull_pyld_PROC
    if (resetn == 1'b0) begin
      aw_pyld_f_valid <= 1'b0;
      aw_pyld_f       <= {A2X_AW_PYLD_W{1'b0}};
    end else begin
      // If Lock transaction generated.
      if ((A2X_LOCKED==1) && st_bfchange && (nxt_bfstate==PP_LOCK)) begin
        aw_pyld_f_valid <= 1'b1;
        aw_pyld_f       <= aw_pyld_r;
      end else if (|awvalid_id) begin 
        if ((!awready_s)  || holding_pyld_valid  || ((!wready) && wvalid_dp && ((bfstate==PP_W_NORMAL) || (bfstate==PP_W_AP_BUSY)))) begin
          aw_pyld_f_valid <= 1'b1;
          aw_pyld_f       <= aw_pyld_r;
        end
      end else if (bf_timeout || (st_bfchange && (bfstate==PP_AW_BUF_FULL)) || (lk_req && lk_grant)) begin
        aw_pyld_f_valid <= 1'b0;
        aw_pyld_f       <= {A2X_AW_PYLD_W{1'b0}};
      end
    end
  end

  //*************************************************************************************  
  // Generate AW Payload
  // IF AHB has completed its locked transaction a unlock transaction is
  // pushed into the AXI PP. Otherwise Write ID's drives aw payload
  //*************************************************************************************  
  always @(*) begin: awpyld_PROC
    aw_pyld_r = {A2X_AW_PYLD_W{1'b0}}; 
    if (aw_pyld_f_valid)
      aw_pyld_r = aw_pyld_f;
    // Only do boundary checking for AHB INCR's not EBT'd master returning to
    // complete a Defined length transaction. 
    else if (|(awvalid_id & (~os_w_id)))
      aw_pyld_r  = {hburst_type, addr_sb, id, addr, resize, alen, size, burst, lock, cache, prot};
    // Previous Address is part of a Defined Length Write
    else if (|awvalid_id)
      aw_pyld_r  = {1'b0, addr_sb, id, addr, resize, alen_o, size, burst, lock, cache, prot};
    else
      aw_pyld_r = {A2X_AW_PYLD_W{1'b0}}; 
  end

  assign aw_pyld = (unlk_awvalid)? unlk_aw_pyld : aw_pyld_r; 

  // Generate AXI Write Address
  // - If Write Data buffer Full and valid address do not push address into FIFO until data is pushed. 
  //   This is bacause a Transaction might be split and the address disguarded.
  assign awvalid = unlk_awvalid? 1'b1 : ((nxt_bfstate==PP_LOCK) | unlk_seq)? 1'b0 :
                   (bf_timeout | holding_pyld_valid | (((bfstate==PP_W_NORMAL) | (bfstate==PP_W_AP_BUSY)) & wvalid_dp & (!wready)))? 1'b0 :
                   (aw_pyld_f_valid | (|awvalid_id));

  //*************************************************************************************  
  // Write data holding register. This register is loaded from the AHB data
  // bus under the following conditions:
  //
  // 1. We are in an active data phase and the address phase is BUSY.
  //    Data is stored in the holding register until we see what the next
  //    address phase is (could be an EBT condition)
  // 2. We are in an active data phase with hready high and the write data
  //    buffer is full
  //*************************************************************************************  
  always @(posedge clk or negedge resetn) begin: holding_pyld_reg_PROC
    if(resetn == 1'b0) begin
      holding_pyld_r <= {A2X_W_PYLD_W{1'b0}};
      holding_pyld_valid <= 1'b0;
    end else begin
      if (st_bfchange && (nxt_bfstate==PP_W_BUF_FULL) && (!holding_pyld_valid)) begin
        holding_pyld_r     <= w_pyld_i;
        holding_pyld_valid <= 1'b1;
      end else if ((bfstate==PP_AW_BUF_FULL) && w_split_resp_r && wvalid_dp_r && (!bf_timeout) && awready_s) begin
        holding_pyld_r     <= w_pyld_i;
        holding_pyld_valid <= 1'b1;
      end else if (holding_pyld_valid && wready) begin
        holding_pyld_r     <= {A2X_W_PYLD_W{1'b0}};
        holding_pyld_valid <= 1'b0;
      end else if ((A2X_LOCKED==1) && holding_pyld_valid && (!wready) && bf_timeout) begin
        holding_pyld_r[0]  <= holding_pyld_r[0] | bf_timeout;
      end
    end
  end

  // If Splitting AHB due to write buffer full generate wlast
  assign holding_pyld[0]                = holding_pyld_valid & (holding_pyld_r[0] | bf_timeout);
  assign holding_pyld[A2X_W_PYLD_W-1:1] = holding_pyld_r[A2X_W_PYLD_W-1:1]; 

  //*************************************************************************************  
  // AXI Primary Port W Channel
  //*************************************************************************************  
  // Generate AXI Write Data 
  assign wvalid      = unlk_wvalid? 1'b1 : (holding_pyld_valid)? 1'b1 : (hready & lk_req & lk_grant & wvalid_dp)? 1'b1 : (aw_pyld_f_valid)? 1'b0 : wvalid_dp;

  // Write Data Payload
  assign w_pyld      = unlk_wvalid? unlk_w_pyld : (holding_pyld_valid)? holding_pyld : w_pyld_i;

  //*************************************************************************************  
  // Hready Timeout Control
  //*************************************************************************************
  generate
  if ( (A2X_AHB_WBF_SPLIT==1) && (A2X_SPLIT_MODE==1) ) begin
    always @(posedge clk or negedge resetn) begin: bfcnt_PROC
      if (resetn==1'b0) begin
        bfcnt <= HREADY_LOW_PERIOD;
      end else begin
        if (bf_hready || (hready_resp_i && (!bf_timeout)))
          bfcnt <= HREADY_LOW_PERIOD-2;
        else if ((!bf_timeout) && (!lk_seq) && (!hready_resp_i))
          bfcnt <= bfcnt - 8'd1;
      end
    end
    assign bf_timeout = (A2X_LOCKED==0)? (bfcnt==8'h00) : (unlk_hready & (!lk_seq)) & (bfcnt==8'h00);
  end else begin
    assign bf_timeout = 1'b0;
  end
  endgenerate  

  //*************************************************************************************
  // Registered Version of the AHB Master to be recalled. 
  //*************************************************************************************
  generate
  if (A2X_SPLIT_MODE==1) begin: BFS
    always @(posedge clk or negedge resetn) begin: bf_id_PROC
      if (resetn==1'b0) begin
        bf_id_r <= {`A2X_IDW{1'b0}};
      end else begin
        if (hready && hsel && hwrite && (htrans_nseq || htrans_seq) && (!bf_hready) && (!bf_timeout))
          bf_id_r <= id;
      end
    end
    assign bf_id = bf_id_r;
  end else begin
    assign bf_id = {`A2X_IDW{1'b0}};
  end
  endgenerate

  //*************************************************************************************
  // Write Response Responses
  //
  // If Buffer becomes Full at same time as a split response is received. The
  // A2X will drive the hready low first and then return a split responses.
  // Since the split responses from each H2X_W instance is only a single cycle
  // the A2X needs to store this split response until the buffer becomes
  // non-empty. 
  //*************************************************************************************
  generate
  if (A2X_SPLIT_MODE==1) begin: BFSPLIT
    reg w_split_resp_r1;
    always @(posedge clk or negedge resetn) begin: bfsplit_PROC
      if (resetn == 1'b0) begin
       w_split_resp_r1 <=  1'b0;
      end else begin
        if ((|w_split_resp_id) && ((!bf_timeout) && (!bf_hready)))
          w_split_resp_r1 <= 1'b1;
        else if (bf_hready || bf_timeout)
          w_split_resp_r1 <= 1'b0;
      end
    end
    assign w_split_resp_r = w_split_resp_r1;
  end else begin
    assign w_split_resp_r = 1'b0;
  end
  endgenerate

  //*************************************************************************************
  // Registered Version of bf_hready
  //*************************************************************************************
  always @(posedge clk or negedge resetn) begin: bfhready_r_PROC
    if (resetn == 1'b0) begin
      bf_hready_r <=  1'b0;
    end else begin
      bf_hready_r <=  bf_hready;
    end
  end
  
  // Rising & Falling Edge Detect
  assign bf_hready_red = (bf_hready  & (!bf_hready_r));
  
  //*************************************************************************************
  // Buffer Full Response
  // - Only respond with hready low if valid AHB Write request on Bus.
  // - If in unlocking state an valid request on AHB bus.
  //*************************************************************************************
  always @(posedge clk or negedge resetn) begin: bf_resp_PROC
    if (resetn == 1'b0) begin
      bf_hready_resp_r <=  1'b1;
    end else begin
      if ((!unlk_hready) && (!unlk_cmp))
        bf_hready_resp_r <= 1'b0;
      else if ((!bf_hready) && (!bf_timeout) && (|w_recall_state_id) && h2x_valid && htrans_nseq && (!hburst_single) && (!hburst_incr)) 
        bf_hready_resp_r <= 1'b0;
      else if ((!bf_hready) && (!bf_timeout) && (!(|w_buf_state_id)) && (!(|w_recall_state_id)) && h2x_valid && (htrans_nseq | htrans_seq))
        bf_hready_resp_r <= 1'b0;
      else if (bf_hready_red || bf_timeout || unlk_cmp)
        bf_hready_resp_r <= 1'b1;
    end
  end

  // If active transaction on AHB Bus when buffer becomes full - respond with hready low
  assign bf_hready_resp = (!bf_hready & (!bf_timeout) & (|w_recall_state_id) & h2x_valid & htrans_nseq && (!hburst_single) && (!hburst_incr))?    1'b0 : 
                          ((!bf_hready) & (!bf_timeout) & (!(|w_buf_state_id)) & (!(|w_recall_state_id)) & h2x_valid & (htrans_nseq | htrans_seq))? 1'b0 :
                           bf_hready_red | bf_hready_resp_r | bf_timeout;

  // Only high for one clock cycle.
  assign w_split_resp  =  (!bf_hready_resp)? 1'b0 : (w_split_resp_r | (|w_split_resp_id));

  //  Generate one response from multiple write ID's
  assign w_hready_resp =  (lk_req)? 1'b0 : (!unlk_hready)? 1'b0 : (!bf_hready_resp)? 1'b0 : (!w_split_resp_r & (&w_hready_resp_id));

  assign w_error_resp  =  |w_error_resp_id;
  assign w_retry_resp  =  |w_retry_resp_id;
  
endmodule

