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
// File Version     :        $Revision: #3 $ 
// Revision: $Id: //dwh/DW_ocb/DW_axi_a2x/axi_dev_br/src/DW_axi_a2x_sp_add_split.v#3 $ 
// --------------------------------------------------------------------
*/

`include "DW_axi_a2x_all_includes.vh"
// **************************************************************************************
// Address Decode
//
// All Wrap Transactions are converted into AXI INCR's. This block decodes the AXI
// length to the upper boundary, the boundary address and the AXI length from
// the boundary address to the orginal address. 
//
// For AHB INCR Transactions this logic determines if the transaction is going
// to cross the 1K boundary. If an AHB INCR Transaction crosses the 1K
// boundary the AXI length is updated such that the Transaction is only upto
// the 1K boundary. 
//
//              |---------|  
//           |->|  AHB 1K |------|\
//--------|  |  | Boundary|      | |   |---------|
// Address|  |  |---------|      | |   | Address |
//  FIFO  |--|                   | |---| Decode  |------>
// -------|  |  |---------|      | |   |---------|
//           |->|   Wrap  |------|/
//              | Splitter|
//              |---------| 
// **************************************************************************************
module i_axi_a2x_2_DW_axi_a2x_sp_add_split (/*AUTOARG*/
   // Outputs
   active_as, alast_as, pyld_o, onek_exceed, 
   ws_addr, ws_alen, ws_size, ws_resize, ws_fixed, wrap, 
   // Inputs
   clk, resetn, a_ready_i, bypass_ws,
   a_fifo_empty, sp_os_fifo_vld, active_ac, alast_ac, pyld_i, 
   snf_pyld_i, trans_en
   );

  // **************************************************************************************
  // Parameter Decelaration
  // **************************************************************************************
  parameter A2X_PP_MODE          = 1;
  parameter A2X_CHANNEL          = 0; 
  parameter A2X_AW               = 32;
  parameter A2X_BLW              = 4;
  parameter BLW_AS               = 4;
  parameter A2X_PP_MAX_SIZE      = 2;
  parameter A2X_ASBW             = 1;
  parameter A2X_QOSW             = 1;
  parameter A2X_REGIONW          = 1;
  parameter A2X_DOMAINW          = 1;
  parameter A2X_WSNOOPW          = 1;
  parameter A2X_BARW             = 1;
  parameter A2X_PYLD_I           = 32;                          
  parameter A2X_PYLD_O           = 32;
  parameter BYPASS_WS            = 0; 
  parameter A2X_BRESP_MODE       = 0; 
  parameter A2X_WSNF_PYLD_W      = 1;
  parameter A2X_HINCR_HCBCNT     = 1; 
  parameter A2X_HINCR_MAX_BCNT   = 10; 
  
  parameter A2X_UPSIZE           = 0;
  parameter A2X_DOWNSIZE         = 0; 

  localparam WRAP_DECODE         = 1;  

  // **************************************************************************************
  // I/O Decelaration
  // **************************************************************************************
  input                                      clk;              // clock
  input                                      resetn;           // asynchronous reset


  //spyglass disable_block W240
  //SMD: An input has been declared but is not read.
  //SJ: This input is used in specific config only 
  input                                      bypass_ws;
  // Handshaking
  input                                      a_ready_i;
  input                                      a_fifo_empty;
  input                                      sp_os_fifo_vld;
  //spyglass enable_block W240
  input                                      alast_ac;
  input                                      active_ac;        // Address Calculator Active
  output                                     active_as;        // Address Splitter Active
  output                                     alast_as;
  output                                     onek_exceed;      // 1K Boundary Exceed for AHB

  output [A2X_AW-1:0]                        ws_addr;          // Wrap Splitter output Address
  output [BLW_AS-1:0]                        ws_alen;          // Wrap Splitter output Length
  output [`i_axi_a2x_2_A2X_BSW-1:0]                      ws_size;          
  output                                     wrap;
  output [`i_axi_a2x_2_A2X_RSW-1:0]                      ws_resize; 
  output                                     ws_fixed;

  input  [A2X_PYLD_I-1:0]                    pyld_i;
  output [A2X_PYLD_O-1:0]                    pyld_o;

  //spyglass disable_block W240
  //SMD: An input has been declared but is not read.
  //SJ: This input is used in specific config only 
  input  [A2X_WSNF_PYLD_W-1:0]               snf_pyld_i;
  input                                      trans_en; 
  //spyglass enable_block W240
  
  // **************************************************************************************
  // Signal Decelaration
  // **************************************************************************************
  wire   [A2X_PYLD_I-1:0]                    pyld_w;         // Payload
  reg    [A2X_PYLD_I-1:0]                    pyld_r;         // Payload
  wire   [`i_axi_a2x_2_A2X_IDW-1:0]                      id_i;  
  wire   [A2X_AW-1:0]                        addr_i; 
  wire   [A2X_BLW-1:0]                       len_i; 
  wire   [`i_axi_a2x_2_A2X_BSW-1:0]                      size_i;     
  wire   [`i_axi_a2x_2_A2X_BTW-1:0]                      burst_i;   
  wire   [`i_axi_a2x_2_A2X_LTW-1:0]                      lock_i;   
  wire   [`i_axi_a2x_2_A2X_CTW-1:0]                      cache_i; 
  wire   [`i_axi_a2x_2_A2X_PTW-1:0]                      prot_i; 
  wire   [A2X_ASBW-1:0]                      sideband_i;
  wire   [A2X_QOSW-1:0]                      qos_i;
  wire   [A2X_REGIONW-1:0]                   region_i;
  wire   [A2X_DOMAINW-1:0]                   domain_i;
  wire   [A2X_WSNOOPW-1:0]                   snoop_i;
  wire   [A2X_BARW-1:0]                      bar_i;
  wire   [`i_axi_a2x_2_A2X_RSW-1:0]                      resize_i;
  wire                                       hburst_type;      // AHB is of Type INCR
  wire                                       hburst_type_w;    // AHB is of Type INCR
  wire   [BLW_AS-1:0]                        ws_alen_i;        // Wrap Splitter output Length

  wire                                       second_burst;     // Second Wrap Burst
  wire                                       split;
  wire                                       wrap;             // Transaction is Wrap

  reg    [31:0]                              alen1;            // First Transaction Length
  wire   [7:0]                               alen2;            // Second Transaction Length
  wire   [A2X_AW-1:0]                        addr2;            // Second Transaction Length

  wire   [`i_axi_a2x_2_A2X_BTW-1:0]                      ws_burst;         // Wrap Splitter output Burst

  reg    [7:0]                               size_1hot; 
  wire   [31:0]                              alen_w;
  wire   [10:0]                              hincr_alen;
  reg    [7:0]                               size_1hot_w;

  wire   [10:0]                              hincr_bcnt_i;
  wire   [10:0]                              hincr_bcnt;
  wire                                       onek_exceed;      // 1K Boundary Exceed for AHB
  wire   [31:0]                              ws_len_i; 


  // **************************************************************************************
  // Payload 
  // 
  // Registered Version of Payload, This allows the Wrap SPlitter to generate
  // a new address and the FIFO to pop off the current address. The Address
  // calculator will use the information stored in the registered version for
  // decoding the SP Address.
  // **************************************************************************************
  // spyglass disable_block FlopEConst
  // SMD: Reports permanently disabled or enabled flip-flop enable pins
  // SJ : This is not a functional issue, this is as per the requirement.
  //      Hence this can be waived.  
  always @(posedge clk or negedge resetn) begin: pyld_PROC
    if (resetn==1'b0) 
      pyld_r <= {A2X_PYLD_I{1'b0}};
    else begin
      if ((!active_as) && (!active_ac))
        pyld_r <= pyld_i;
    end
  end
  // spyglass enable_block FlopEConst
      
  // Seclect Payload Input for First Address Otherwise selected registered
  // version
  assign pyld_w = (active_as || active_ac) ? pyld_r : pyld_i; 

  // Payload Decode
  assign {bar_i, snoop_i, domain_i, region_i, qos_i, hburst_type, sideband_i, id_i, addr_i, resize_i, len_i, 
  size_i, burst_i, lock_i, cache_i, prot_i} = pyld_w;

  // Burst Type Decode
  assign  wrap     = (burst_i==`i_axi_a2x_2_ABURST_WRAP)? 1'b1 : 1'b0;

  // AXI Fixed Burst 
  assign  ws_fixed = (A2X_PP_MODE==0)? 1'b0: (burst_i==`i_axi_a2x_2_ABURST_FIXED)? 1'b1 : 1'b0;

  // **************************************************************************************
  // Fannout Size to Maximum
  // **************************************************************************************
  //spyglass disable_block W415a
  //SMD: Signal may be multiply assigned (beside initialization) in the same scope.
  //SJ : size_1hot is initialized before assignment to avoid latches.
  always @(*) begin: size1hot_PROC
    integer i; 
    size_1hot = 8'b0; 
    for (i=0; i<=A2X_PP_MAX_SIZE; i=i+1)
       // Signed and unsigned operands should not be used in same operation.
       // i can only be an integer, since it is a loop index. It is a design requirement to
       // use i in the following operation and it will not have any adverse effects on the 
       // design. So signed and unsigned operands are used to reduce the logic.
       if (i==size_i) size_1hot[i] = 1'b1;
  end   
  // Added size_1hot_w to improve coverage results on the case expression below
  always @(*) begin : size_1hotw_PROC
     size_1hot_w[7:0] = 8'b0;
     size_1hot_w[A2X_PP_MAX_SIZE:0] = size_1hot[A2X_PP_MAX_SIZE:0];
  end
  //spyglass enable_block W415a

  // **************************************************************************************
  // AHB 1K Boundary Check for INCR's
  // **************************************************************************************
  generate
  if (A2X_PP_MODE==0) begin: ONEK_BLK
    
    assign hburst_type_w = hburst_type; 

    // **************************************************************************************
    // Decode the Log2 HINCR 
    // **************************************************************************************
    assign hincr_bcnt_i = (A2X_HINCR_HCBCNT==1)? (1<<A2X_HINCR_MAX_BCNT) : hburst_type? (11'b1 << len_i) : 11'b0;

    // **************************************************************************************
    // Fannout Length to Maximum
    // - Only select relavent bits so that additioinal logic is removed during Synthesis
    // When Bypassing Split-Configs the A2X is configured for 
    // Equalled sized AHB Mode
    // ***************************************************************************************
    wire        onek_exceed_w;
    
    assign hincr_bcnt  = (A2X_CHANNEL==1)?                      hincr_bcnt_i :
                         (A2X_BRESP_MODE==1)?                   {10'b0,1'b1} : 
                         ((A2X_BRESP_MODE==2) &&  ~cache_i[0])? {10'b0,1'b1} : 
                         (A2X_UPSIZE==1)?                       hincr_bcnt_i :          
                         (A2X_DOWNSIZE==1)?                     hincr_bcnt_i :          
                         (hincr_bcnt_i>(1<<A2X_BLW))?           (1<<A2X_BLW) : hincr_bcnt_i;

    assign hincr_alen  = hincr_bcnt-1;

    i_axi_a2x_2_DW_axi_a2x_sp_add_onek
     #(
      .HINCR_MAX_BCNT          (A2X_HINCR_MAX_BCNT)
     ,.A2X_PP_MAX_SIZE         (A2X_PP_MAX_SIZE)     
    ) U_sp_ad_as_onek (
       .addr_i                 (addr_i[9:0])  
      ,.hincr_bcnt             (hincr_bcnt)
      ,.size_i                 (size_i)
      ,.onek_exceed            (onek_exceed_w)
    );
    
    // Only assert 1K if Burst Type in INCR.
    assign onek_exceed =  onek_exceed_w & hburst_type_w;

  end else begin
    assign hburst_type_w = 1'b0; 
    assign onek_exceed   = 1'b0;
    assign hincr_bcnt    = 11'b0;
    assign hincr_alen    = 11'b0;
  end
  endgenerate

  // **************************************************************************************
  // Wrap Splitter
  // **************************************************************************************
  assign ws_len_i[31:A2X_BLW]   = {(32-A2X_BLW){1'b0}};
  assign ws_len_i[A2X_BLW-1:0]  = len_i;

  generate
  if (BYPASS_WS==0) begin: WSBLK
    wire   [`i_axi_a2x_2_A2X_BTW-1:0]                      ws_burst_w;
    wire                                       alast_as_w;
    wire                                       active_as_w;
    wire                                       second_burst_w;
    wire                                       split_w;
    wire   [A2X_AW-1:0]                        addr2_w;
    wire   [7:0]                               alen2_w;

    i_axi_a2x_2_DW_axi_a2x_sp_add_ws
     #(
       .A2X_PP_MODE            (A2X_PP_MODE)
      ,.A2X_AW                 (A2X_AW)
      ,.A2X_BLW                (A2X_BLW) 
      ,.A2X_PP_MAX_SIZE        (A2X_PP_MAX_SIZE)
    ) U_sp_ad_as_ws (
       .clk                    (clk)
      ,.resetn                 (resetn)
      ,.wrap                   (wrap)
      ,.addr_i                 (addr_i)
      ,.alast_ac               (alast_ac)
      ,.a_ready_i              (a_ready_i)
      ,.a_fifo_empty           (a_fifo_empty)
      ,.sp_os_fifo_vld         (sp_os_fifo_vld)
      ,.active_ac              (active_ac)
      ,.alen_i                 (ws_len_i)
      ,.size_i                 (size_i)
      ,.alast_as               (alast_as_w)
      ,.addr2                  (addr2_w)
      ,.alen2                  (alen2_w)
      ,.active_r               (active_as_w)
      ,.second_burst           (second_burst_w)
      ,.split                  (split_w)
      ,.snf_wlast              (snf_pyld_i)
      ,.trans_en               (trans_en)
    );

    // AXI Burst type
    assign ws_burst_w   = (wrap | second_burst)? `i_axi_a2x_2_ABURST_INCR: burst_i; 

    assign ws_burst     = (bypass_ws)? burst_i         : ws_burst_w;
    assign split        = (bypass_ws)? 1'b0            : split_w;
    //assign active_as  = (bypass_ws)? 1'b0            : active_as_w;
    assign active_as    = active_as_w;
    assign second_burst = (bypass_ws)? 1'b0            : second_burst_w;
    assign alast_as     = (bypass_ws)? alast_ac        : alast_as_w;
    assign addr2        = (bypass_ws)? {A2X_AW{1'b0}}  : addr2_w;
    assign alen2        = (bypass_ws)? {8{1'b0}}       : alen2_w;

  end else begin
    assign split        = 1'b0;
    assign active_as    = 1'b0;
    assign second_burst = 1'b0;
    assign alast_as     = alast_ac;
    assign addr2        = {A2X_AW{1'b0}};
    assign alen2        = {8{1'b0}};
    
    // AXI Burst type
    assign  ws_burst     = burst_i; 

  end
  endgenerate

  // **************************************************************************************
  // - Boundary check for AHB 1K 
  // - Wrap Transactions.
  // **************************************************************************************
  reg [BLW_AS-1:0] alen_r; 
  // spyglass disable_block W164a
  // SMD: Identifies assignments in which the LHS width is less than the RHS width
  // SJ : This is not a functional issue, this is as per the requirement.
  // spyglass disable_block W164b
  // SMD: Identifies assignments in which the LHS width is greater than the RHS width
  // SJ : This is not a functional issue, this is as per the requirement.
  always @(*) begin: alen_PROC
    alen_r = {BLW_AS{1'b0}};
    if (wrap)
      alen_r = len_i;
    else if (hburst_type_w)
      alen_r = hincr_alen;
  end
  // spyglass enable_block W164b
  // spyglass enable_block W164a
  
  assign alen_w[31:BLW_AS]   = {(32-BLW_AS){1'b0}};
  assign alen_w[BLW_AS-1:0]  = alen_r[BLW_AS-1:0];

   // **************************************************************************************
   // Addess Decode 
   // **************************************************************************************
   reg [BLW_AS-1:0] addr_size;
  //spyglass disable_block W415a
  //SMD: Signal may be multiply assigned (beside initialization) in the same scope.
  //SJ : This is not an issue. It is initialized before assignment to avoid latches.
  //spyglass disable_block W486
  //SMD: Reports shift overflow operations
  //SJ : This is not a functional issue, this is as per the requirement.
  //spyglass disable_block W164a
  //SMD: Identifies assignments in which the LHS width is less than the RHS width
  //SJ : This is not a functional issue, this is as per the requirement.
   always @(*) begin : beat_addr_PROC
     integer i,j;
     alen1 =  32'b0;
     addr_size = addr_i[BLW_AS-1:0]; 
     for (j=1; j<= A2X_PP_MAX_SIZE;j=j+1)
       if (size_i==j) addr_size = addr_i >> j;
     for (i=0 ; i < BLW_AS; i=i+1)
       if (alen_w[i]==1'b1) alen1[i]=~addr_size[i];
   end
  //spyglass enable_block W164a
  //spyglass enable_block W486
  //spyglass enable_block W415a

  // **************************************************************************************
  // Select the First or Second Address
  // **************************************************************************************
  assign  ws_addr      = (second_burst) ? addr2 : addr_i;

  // If Wrap or 1k Boundary exceeded.
  // spyglass disable_block W164a
  // SMD: Identifies assignments in which the LHS width is less than the RHS width
  // SJ : This is not a functional issue, this is as per the requirement.
  assign  ws_alen_i    = (second_burst) ? {24'd0, alen2} : (split | onek_exceed) ? alen1[BLW_AS-1:0] : hburst_type_w ? alen_w[BLW_AS-1:0] : ws_len_i[BLW_AS-1:0];
  assign  ws_alen      = ((A2X_CHANNEL==1) ? ws_alen_i : {BLW_AS{1'b0}});
  // spyglass enable_block W164a

  // Output from pyld register or pyld_i
  assign ws_size       = size_i; 
  assign ws_resize     = resize_i;

  // **************************************************************************************
  // Payload Output
  // **************************************************************************************
  assign pyld_o = {bar_i, snoop_i, domain_i, region_i, qos_i, hburst_type_w, sideband_i, id_i, ws_addr, resize_i, ws_alen_i, size_i, ws_burst, lock_i, cache_i, prot_i};

endmodule
