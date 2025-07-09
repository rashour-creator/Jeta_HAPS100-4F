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
// Revision: $Id: //dwh/DW_ocb/DW_axi_a2x/amba_dev/src/DW_axi_a2x_h2x_decode.v#1 $ 
// --------------------------------------------------------------------
*/

`include "DW_axi_a2x_all_includes.vh"
//*************************************************************************************
// AHB Decode Module 
// - Converts the AHB Address Channel into AXI transaction
// - Generates a Data Phase version of AHB Address Channel. 
//*************************************************************************************
module i_axi_a2x_DW_axi_a2x_h2x_decode (/*AUTOARG*/
   // Outputs
   haw_pyld, har_pyld, haw_unlk_pyld, htrans_dp, hburst_dp, hwrite_dp, hsize_dp, 
   hmaster_dp, hmastlock_dp,
   // Inputs
   clk, resetn, hmaster, hmastlock, haddr, hwrite, hresize, hburst, 
   hready, htrans, hsize, hprot, haddr_sb, hincr_wbcnt_id, hincr_rbcnt_id
   );
  
  //*************************************************************************************
  // Parameter Decelaration
  //*************************************************************************************
  parameter    A2X_LOCKED         = 0;
  parameter    A2X_NUM_AHBM       = 2;
  parameter    A2X_HASBW          = 1; 
  parameter    A2X_BLW            = 4;
  parameter    A2X_AW             = 32; 

  parameter    A2X_AW_PYLD_W      = 32; 
  parameter    A2X_AR_PYLD_W      = 32; 

  parameter   A2X_HINCR_HCBCNT    = 1;
  parameter   A2X_SINGLE_RBCNT    = 1;
  parameter   A2X_SINGLE_WBCNT    = 1;
  parameter   A2X_HINCR_WBCNT_MAX = 1;
  parameter [3:0]  A2X_HINCR_RBCNT_MAX = 1;

  localparam  A2X_HINCR_RBCNT_IDW            = (A2X_HINCR_HCBCNT==1)? 4 : (A2X_SINGLE_RBCNT==1)? 4 :  4*A2X_NUM_AHBM; // AHB Read HINCR BCNT BUS Width
  localparam  A2X_HINCR_WBCNT_IDW            = (A2X_HINCR_HCBCNT==1)? 4 : (A2X_SINGLE_WBCNT==1)? 4 :  4*A2X_NUM_AHBM; // AHB Write HINCR BCNT BUS Width

  //*************************************************************************************
  // I/O Decelaration
  //*************************************************************************************
  // AHB Interface
  input                                       clk;
  input                                       resetn; 

  input  [`A2X_IDW-1:0]                       hmaster;      // AHB Master ID Bus
  input                                       hmastlock;    // AHB lock              

  input                                       hready;       // j: AHB ready input
  input  [A2X_AW-1:0]                         haddr;        // AHB Address Bus
  input                                       hwrite;       // AHB write indicator   
  input                                       hresize;      // AHB resize              
  input  [`A2X_HBLW-1:0]                      hburst;       // AHB burst             
  input  [1:0]                                htrans;       // AHB address phase     
  input  [2:0]                                hsize;        // AHB size              
  input  [3:0]                                hprot;        // AHB protection        
  input  [A2X_HASBW-1:0]                      haddr_sb;     // AHB Address Sideband Bus

  input  [A2X_HINCR_RBCNT_IDW-1:0]            hincr_rbcnt_id;
  input  [A2X_HINCR_WBCNT_IDW-1:0]            hincr_wbcnt_id;
   
  output  [A2X_AW_PYLD_W-1:0]                 haw_pyld;
  output  [A2X_AR_PYLD_W-1:0]                 har_pyld;
  output  [A2X_AW_PYLD_W-1:0]                 haw_unlk_pyld;
  output  [1:0]                               htrans_dp;
  output  [`A2X_HBLW-1:0]                     hburst_dp;
  output                                      hwrite_dp;
  output  [2:0]                               hsize_dp;        // AHB size              
  output  [`A2X_IDW-1:0]                      hmaster_dp;
  output                                      hmastlock_dp;

  //*************************************************************************************
  // I/O Decelaration
  //*************************************************************************************
  wire    [`A2X_IDW-1:0]                      id;
  wire    [A2X_AW-1:0]                        addr;   
  wire    [2:0]                               size;  
  wire    [2:0]                               prot; 
  wire    [3:0]                               cache; 
  wire    [1:0]                               lock;  
  wire    [1:0]                               burst; 
  wire                                        resize;
  reg     [A2X_BLW-1:0]                       alen; 
  wire                                        burst_type;

  reg     [1:0]                               htrans_dp;   
  reg     [`A2X_HBLW-1:0]                     hburst_dp; 
  reg                                         hwrite_dp;
  reg     [2:0]                               hsize_dp;
  reg                                         hmastlock_dp;
  reg     [`A2X_IDW-1:0]                      hmaster_dp;

  wire    [3:0]                               wbcnt_array         [0:A2X_NUM_AHBM-1];
  wire    [3:0]                               rbcnt_array         [0:A2X_NUM_AHBM-1];
  wire    [3:0]                               hincr_wbcnt_w;
  wire    [3:0]                               hincr_rbcnt_w;
  wire    [3:0]                               hincr_wbcnt;
  wire    [3:0]                               hincr_rbcnt;

  //*************************************************************************************
  // Decode Read INCR Beat Count
  //*************************************************************************************
  // Possible range overflow. 
  // There is no possibility of range overflows. This logic will implement as desired as the range is contained through A2X_NUM_AHBM.
  // Use fully assigned variables in function bodies
  // Even though the variable is not fully assigned (based on configuration), but the logic implemented will be as per the requirement.  
  // spyglass disable_block ImproperRangeIndex-ML
  // SMD: Reports a violation if the number of bits required to cover index does not match log2N.
  // SJ : This is not a functional issue, this is as per the requirement.                  
  genvar gvar;
  generate
  if ((A2X_HINCR_HCBCNT==0) && (A2X_SINGLE_RBCNT==0)) begin: RBCNT
    for (gvar=0; gvar<A2X_NUM_AHBM; gvar=gvar+1) begin:RBCNT_A
      assign rbcnt_array[gvar] = hincr_rbcnt_id[(gvar*4)+:4];
    end
    assign  hincr_rbcnt_w = rbcnt_array[hmaster]; //FM_2_35 flags here 
  end else begin
    assign  hincr_rbcnt_w = hincr_rbcnt_id[3:0]; 
  end
  endgenerate
  assign  hincr_rbcnt   = (hincr_rbcnt_w>A2X_HINCR_RBCNT_MAX)? A2X_HINCR_RBCNT_MAX : hincr_rbcnt_w;

  //*************************************************************************************
  // Decode Write INCR Beat Count
  //*************************************************************************************
  generate
  if ((A2X_HINCR_HCBCNT==0) && (A2X_SINGLE_WBCNT==0)) begin: WBCNT
    for (gvar=0; gvar<A2X_NUM_AHBM; gvar=gvar+1) begin: WBCNT_A
      assign wbcnt_array[gvar] = hincr_wbcnt_id[(gvar*4)+:4];
    end
    assign  hincr_wbcnt_w = wbcnt_array[hmaster]; //FM_2_35 flags here
  end else begin
    assign  hincr_wbcnt_w = hincr_wbcnt_id[3:0]; 
  end
  endgenerate
  // spyglass enable_block ImproperRangeIndex-ML
  assign  hincr_wbcnt   = (hincr_wbcnt_w>A2X_HINCR_WBCNT_MAX)? A2X_HINCR_WBCNT_MAX : hincr_wbcnt_w;

  //*************************************************************************************
  // Translating AHB Ports to AXI 
  //*************************************************************************************
  assign   id          = hmaster;
  assign   addr        = haddr;
  assign   size        = hsize;
  assign   prot        = {~hprot[0], 1'b0, hprot[1]};
  assign   cache       = {2'b00, hprot[3], hprot[2]};
  assign   lock        = (A2X_LOCKED==1) ? {hmastlock, 1'b0} : 2'b00;
  assign   resize      = hresize;
  assign   burst       = ((hburst==`HBURST_WRAP4)||(hburst==`HBURST_WRAP8)|| (hburst==`HBURST_WRAP16))? `AWRAP: `AINCR;

  assign   burst_type  = (hburst==`HBURST_INCR)? 1'b1: 1'b0;

  //*************************************************************************************
  // AHB-AXI Length Decode
  //
  // For INCR Writes
  //  -Bufferable Writes converted to AWLEN register
  //  -Non-Bufferable Writes converted to Singles
  // For INCR Reads 
  //  -Read Length converted to RPREFETCH register 
  //*************************************************************************************
  always@(*) begin: alen_PROC
    alen = {A2X_BLW{1'b0}}; 
    case(hburst)
      // spyglass disable_block W164b
      // SMD: Identifies assignments in which the LHS width is greater than the RHS width
      // SJ : This is not a functional issue, this is as per the requirement.
      //      Hence this can be waived.  
      `HBURST_WRAP4:  alen = 4'h3;
      `HBURST_INCR4:  alen = 4'h3;
      `HBURST_WRAP8:  alen = 4'h7;
      `HBURST_INCR8:  alen = 4'h7;
      `HBURST_WRAP16: alen = 4'hf;
      `HBURST_INCR16: alen = 4'hf;
      `HBURST_INCR:   alen = (hwrite)? hincr_wbcnt : hincr_rbcnt; 
      // spyglass enable_block W164b
      default:        alen = {A2X_BLW{1'b0}}; 
    endcase 
  end 

  // Burst Type not used by SP for Write Address calculation. 
  assign   haw_pyld   = {burst_type, haddr_sb, id, addr, resize, alen, size, burst, lock, cache, prot};
  assign   har_pyld   = {burst_type, haddr_sb, id, addr, resize, alen, size, burst, lock, cache, prot};

  // AXI Unlock Payload
  assign   haw_unlk_pyld   = {1'b0, haddr_sb, id, addr, 1'b0, {A2X_BLW{1'b0}}, 3'h0, `AINCR, 2'b00, cache, prot};

  //*************************************************************************************
  // Data Phase Control Signals
  //*************************************************************************************
  always @(posedge clk or negedge resetn) begin: dp_PROC
    if (resetn==1'b0) begin
      htrans_dp    <= 2'b0; 
      hburst_dp    <= {`A2X_HBLW{1'b0}}; 
      hwrite_dp    <= 1'b0;
      hsize_dp     <= 3'b0;
      hmaster_dp   <= {`A2X_IDW{1'b0}};
      hmastlock_dp <= 1'b0;
    end else begin
      if(hready) begin
        htrans_dp    <= htrans;
        hburst_dp    <= hburst; 
        hwrite_dp    <= hwrite;
        hsize_dp     <= hsize; 
        hmaster_dp   <= hmaster;
        hmastlock_dp <= hmastlock;
      end
    end
  end

endmodule

