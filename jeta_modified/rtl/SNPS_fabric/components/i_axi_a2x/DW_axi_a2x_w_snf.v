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
// Revision: $Id: //dwh/DW_ocb/DW_axi_a2x/amba_dev/src/DW_axi_a2x_w_snf.v#1 $ 
// --------------------------------------------------------------------
*/

`include "DW_axi_a2x_all_includes.vh"
//*************************************************************************************
// Write Data Store-Forward
//
// Counts the number of Data Beats on Primary Port and generates a push to SNF
// FIFO when SNF Count reached. 
//*************************************************************************************
module i_axi_a2x_DW_axi_a2x_w_snf (/*AUTOARG*/
   // Outputs
   snf_push_n, 
   // Inputs
   clk_pp, resetn_pp, siu_buf_mode, siu_snf_awlen, wready_pp, wvalid_pp, 
   wlast_pp, rs_pyld_i, pk_w_wb_len
   );

    //*************************************************************************************
    // Parameter Decelaration
    //*************************************************************************************
    parameter  A2X_UPSIZE                       = 0;
    parameter  A2X_DOWNSIZE                     = 0;
    parameter  A2X_RS_RATIO_LOG2                = 0;
    
    parameter  A2X_BLW                          = 4;
    parameter  A2X_RS_PYLD_W                    = 32; 
    parameter  A2X_PP_MAX_SIZE                  = 2;
    parameter  A2X_SP_MAX_SIZE                  = 2;

    localparam SNF_W                            = 32;

    //*************************************************************************************
    // IO Decelaration
    //*************************************************************************************
    input                                       clk_pp;
    input                                       resetn_pp;
    
    input                                       siu_buf_mode;
    input  [31:0]                               siu_snf_awlen;

    input                                       wready_pp;
    input                                       wvalid_pp;
    input                                       wlast_pp;

    input  [A2X_RS_PYLD_W-1:0]                  rs_pyld_i;

    //spyglass disable_block W240
    //SMD: An input has been declared but is not read.
    //SJ : This input is used in specific config only 
    input  [A2X_BLW-1:0]                        pk_w_wb_len;
    //spyglass enable_block W240
    output                                      snf_push_n; 

    //*************************************************************************************
    // Signal Decelaration
    //*************************************************************************************
    reg   [SNF_W-1:0]                            snf_cnt_max;
    reg   [SNF_W-1:0]                            snf_cnt;
    wire                                         max_cnt;

    reg   [7:0]                                  wrap_cnt;
    wire  [7:0]                                  ds_wb_len;
    wire                                         wrap_max_cnt;

    // Upsize FIFO 
    wire   [12:0]                                addr;
    wire   [A2X_BLW-1:0]                         len;     
    wire   [`A2X_BSW-1:0]                        size;     
    wire   [`A2X_BTW-1:0]                        burst;     
    wire                                         resize;
    wire                                         wrap_ds; 
    wire                                         wrap_us; 
    wire                                         wlast_int; 
    
   //*************************************************************************************
   // FIFO Decode
   //*************************************************************************************
    assign {resize, burst, size, len, addr}   = rs_pyld_i;
    assign wrap_us = (A2X_UPSIZE==1)? (burst==`ABURST_WRAP) : 1'b0;
    assign wrap_ds = (A2X_DOWNSIZE==1)? (burst==`ABURST_WRAP) : 1'b0;

   //*************************************************************************************
   // Store-Forward Primary Port Count
   // SNF Count is in terms of SP Transaction Length so need to convert this
   // into Primary Port Count before pushing into FIFO.
   // www. can be registered to improve timing since SNF is a static value. 
   //*************************************************************************************
   wire [31:0] pp_bytes_beat    = (32'b1 << size);
   wire [31:0] max_snf_numbytes = (1<<A2X_BLW) << A2X_SP_MAX_SIZE;
   
   always @(*) begin: snf_rs_PROC
     snf_cnt_max = {SNF_W{1'b0}}; 
     // Signed and unsigned operands should not be used in same operation.
     // It is a design requirement to use parameters in the following operation and it 
     //     will not have any adverse effects on the design. So signed and unsigned operands are used.
     if ((A2X_UPSIZE==1) && ((size==A2X_PP_MAX_SIZE) && resize)) begin
       // For Upsizing Length divided by Resize Ratio. Since SNF Length is
       // always a power of 2 value we can use a shift register.
       snf_cnt_max = siu_snf_awlen << A2X_RS_RATIO_LOG2; 
     end else if ((A2X_DOWNSIZE==1) && (size>A2X_SP_MAX_SIZE)) begin
       if (burst==`ABURST_FIXED)
         snf_cnt_max = {{(SNF_W-1){1'b0}}, 1'b1};
       else if (pp_bytes_beat > max_snf_numbytes)
         snf_cnt_max = {{(SNF_W-1){1'b0}}, 1'b1};
       else 
       // spyglass disable_block TA_09
       // SMD: Reports cause of uncontrollability or unobservability and estimates the number of nets whose controllability/ observability is impacted
       // SJ : Few bits of RHS may not be always required 
         snf_cnt_max = siu_snf_awlen >> (size-A2X_SP_MAX_SIZE);
       // spyglass enable_block TA_09
     end else begin
       snf_cnt_max = siu_snf_awlen;
     end
   end

  //*************************************************************************************
  // Wrap Count
  //
  // - Increment when W channel valid.
  // - Reset if wlast or count equals Store-Forward Value
  //*************************************************************************************
  generate 
  if ((A2X_DOWNSIZE==1) || (A2X_UPSIZE==1)) begin: RS_SNF
    always @(posedge clk_pp or negedge resetn_pp) begin: wrap_cnt_PROC
      if (resetn_pp == 1'b0) begin 
        wrap_cnt <= 0;            
      end else begin
        if (siu_buf_mode==`SNF_MODE) begin
          if (wready_pp && wvalid_pp) begin
            if (wlast_pp)
              wrap_cnt <= 0; 
            else if (wrap_ds || wrap_us)
              wrap_cnt <= wrap_cnt + 1;
          end
        end
      end
    end
    
    // spyglass disable_block W362
    // SMD: Reports an arithmetic comparison operator with unequal length
    // SJ : This is not a functional issue, this is as per the requirement.
    //      Hence this can be waived.  
    assign wrap_max_cnt   = (siu_buf_mode==`CT_MODE)? 1'b0 : (wrap_ds)? (wrap_cnt==ds_wb_len) : (wrap_us)? (wrap_cnt==pk_w_wb_len) : 1'b0; 
    // spyglass enable_block W362
    
    // spyglass disable_block SelfDeterminedExpr-ML
    // SMD: Self determined expression found
    // SJ : This is not a functional issue, this is as per the requirement.
    //      Hence this can be waived.  
    assign max_cnt   = (snf_cnt==(snf_cnt_max-1));
    // spyglass enable_block SelfDeterminedExpr-ML
    
  end else begin
    assign wrap_max_cnt = 1'b0; 
    
    // In Equalled Sized Configurations the Max Count is set to 2^BLW 
    // So for Write Transactions wlast will be asserted when max count is
    // reached by the AXI Master or the H2X.
    assign max_cnt      = 1'b0; 
  end
  endgenerate

  //*************************************************************************************
  // Store-Forward Counter
  //
  // - Increment when W channel valid.
  // - Reset if wlast or count equals Store-Forward Value
  //*************************************************************************************
  assign wlast_int = wlast_pp | max_cnt | wrap_max_cnt;

  always @(posedge clk_pp or negedge resetn_pp) begin: wr_cnt_PROC
    if (resetn_pp == 1'b0) begin 
      snf_cnt <= {SNF_W{1'b0}};
    end else begin
      if (siu_buf_mode==`SNF_MODE) begin
        if (wready_pp & wvalid_pp) begin
          if (wlast_int) begin 
            snf_cnt <= {SNF_W{1'b0}}; 
          end else begin
            snf_cnt <= snf_cnt + 1;
          end
        end
      end
    end
  end  

  //*************************************************************************************
  // Store & Forward FIFO Push
  //
  // - Generate a push when Store-Forward Count reached or PP Wlast Detected
  // and W Channel valid. 
  //*************************************************************************************
  assign snf_push_n = (siu_buf_mode==`SNF_MODE)? !(wready_pp & wvalid_pp & wlast_int) : 1'b1;

  // **************************************************************************************
  // Decode Wrap Upper boundary Length
  // **************************************************************************************
  generate
  //spyglass disable_block W415a
  //SMD: Signal may be multiply assigned (beside initialization) in the same scope.
  //SJ : This is not an issue. It is initialized before assignment to avoid latches.
  if (A2X_DOWNSIZE==1) begin: DSWR
    reg [A2X_BLW-1:0] addr_size;
    reg [7:0]         ds_len;
    always @(*) begin : beat_addr_PROC
      integer i,j;
      ds_len =  8'b0;
      addr_size = addr[A2X_BLW-1:0]; 
      for (j=1; j<= A2X_PP_MAX_SIZE;j=j+1)
        // spyglass disable_block W486
        // SMD: Reports shift overflow operations
        // SJ : This is not a functional issue, this is as per the requirement.
        //      Hence this can be waived.  
        // spyglass disable_block W164a
        // SMD: Identifies assignments in which the LHS width is less than the RHS width
        // SJ : This is not a functional issue, this is as per the requirement.
        //      Hence this can be waived.  
        if (size==j) addr_size = addr >> j;
        // spyglass enable_block W164a
        // spyglass enable_block W486
        for (i=0 ; i < A2X_BLW; i=i+1)
          if (len[i]==1'b1) ds_len[i]=~addr_size[i]; 
    end
    assign ds_wb_len = ds_len;
  end else begin
    assign ds_wb_len = 8'b0;
  end 
  //spyglass enable_block W415a
  endgenerate

endmodule
