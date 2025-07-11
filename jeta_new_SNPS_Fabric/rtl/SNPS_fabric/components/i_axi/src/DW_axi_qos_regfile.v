/* ---------------------------------------------------------------------

// ------------------------------------------------------------------------------
// 
// Copyright 2001 - 2023 Synopsys, INC.
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
// Component Name   : DW_axi
// Component Version: 4.06a
// Release Type     : GA
// Build ID         : 18.26.9.4
// ------------------------------------------------------------------------------

// 
// Release version :  4.06a
// File Version     :        : #1 $ 
// Revision: : //dwh/DW_ocb/DW_axi/amba_dev/src/DW_axi_qos_regfile.v#1 $ 

 ---------------------------------------------------------------------

 File     : DW_axi_qos_regfile.v
 Created  : Thu Nov 17 13:27:47 MEST 2011
 Revision : $Id: //dwh/DW_ocb/DW_axi/axi_dev_br/src/DW_axi_qos_regfile.v#7 $
 Modified : $Date: 2022/08/11 $
 Abstract : QOS register Output module
  * Module generated QOS registers signal on output ports
  * Implements read and write operation for QOS registers
            
 ---------------------------------------------------------------------
*/ 
`include "DW_axi_all_includes.vh"
 module i_axi_DW_axi_qos_regfile
    (
     aclk,
     aresetn,
     internal_reg_rst,
     wr_en,
     rd_en,
     addr,
     wdata,
     command_en_aclk,
     reg_awqos_m1,
     reg_arqos_m1,
     reg_awqos_m2,
     reg_arqos_m2,
 err_bit, 
  rdata ); 
  
       
       
  //Ports decalration
     //spyglass disable_block W240
     //SMD: An input has been declared but is not read
     //SJ: This port is used in specific configuration only 
     input                              aclk; //axi clock
     input                              aresetn; //axi reset
     input                              internal_reg_rst; //soft reset
     input                              wr_en; //wr enable signal for qos register--sync with aclk
     input                              rd_en; //read enable signal for qos register--sync with aclk
     input  [7:0]                       addr ; //qos register offset--decoded by commonad regiter values
     input  [31:0]                      wdata; //data register content to be written on qos regs
     input                              command_en_aclk; //aclk synced version of command_en
     //spyglass enable_block W240
     
     output [`i_axi_AXI_QOSW-1:0]           reg_awqos_m1;
     output [`i_axi_AXI_QOSW-1:0]           reg_arqos_m1;
  
     output [`i_axi_AXI_QOSW-1:0]           reg_awqos_m2;
     output [`i_axi_AXI_QOSW-1:0]           reg_arqos_m2;
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  

     output                            err_bit;
     output [31:0]                     rdata ; 
     
 //wire and register declaration 
 reg [31:0]                   rdata ; 
 reg [`i_axi_AXI_NUM_MASTERS-1:0]  errbit_r_m; 
 reg                          errbit_r_m_default; 
 reg                          err_bit_w; 
 reg                          err_bit_r; 
 wire                         errbit_r; 
 reg                          err_bit; 

     reg    [`i_axi_REG_XCT_RATE_W-1:0]     reg_xct_rate_aw_m1;
     reg    [`i_axi_REG_BURSTINESS_W-1:0]   reg_burstiness_aw_m1;
     reg    [`i_axi_REG_PEAK_RATE_W-1:0]    reg_peak_rate_aw_m1;
     reg                              reg_regulation_enable_aw_m1;
     reg                              reg_slv_rdy_aw_m1;
     reg    [`i_axi_AXI_QOSW-1:0]           reg_awqos_m1;
     reg    [`i_axi_REG_XCT_RATE_W-1:0]     reg_xct_rate_ar_m1;
     reg    [`i_axi_REG_BURSTINESS_W-1:0]   reg_burstiness_ar_m1;
     reg    [`i_axi_REG_PEAK_RATE_W-1:0]    reg_peak_rate_ar_m1;
     reg                              reg_regulation_enable_ar_m1;
     reg                              reg_slv_rdy_ar_m1;
     reg    [`i_axi_AXI_QOSW-1:0]           reg_arqos_m1; 

     reg    [`i_axi_REG_XCT_RATE_W-1:0]     reg_xct_rate_aw_m2;
     reg    [`i_axi_REG_BURSTINESS_W-1:0]   reg_burstiness_aw_m2;
     reg    [`i_axi_REG_PEAK_RATE_W-1:0]    reg_peak_rate_aw_m2;
     reg                              reg_regulation_enable_aw_m2;
     reg                              reg_slv_rdy_aw_m2;
     reg    [`i_axi_AXI_QOSW-1:0]           reg_awqos_m2;
     reg    [`i_axi_REG_XCT_RATE_W-1:0]     reg_xct_rate_ar_m2;
     reg    [`i_axi_REG_BURSTINESS_W-1:0]   reg_burstiness_ar_m2;
     reg    [`i_axi_REG_PEAK_RATE_W-1:0]    reg_peak_rate_ar_m2;
     reg                              reg_regulation_enable_ar_m2;
     reg                              reg_slv_rdy_ar_m2;
     reg    [`i_axi_AXI_QOSW-1:0]           reg_arqos_m2; 

     reg    [`i_axi_REG_XCT_RATE_W-1:0]     reg_xct_rate_aw_m3;
     reg    [`i_axi_REG_BURSTINESS_W-1:0]   reg_burstiness_aw_m3;
     reg    [`i_axi_REG_PEAK_RATE_W-1:0]    reg_peak_rate_aw_m3;
     reg                              reg_regulation_enable_aw_m3;
     reg                              reg_slv_rdy_aw_m3;
     reg    [`i_axi_AXI_QOSW-1:0]           reg_awqos_m3;
     reg    [`i_axi_REG_XCT_RATE_W-1:0]     reg_xct_rate_ar_m3;
     reg    [`i_axi_REG_BURSTINESS_W-1:0]   reg_burstiness_ar_m3;
     reg    [`i_axi_REG_PEAK_RATE_W-1:0]    reg_peak_rate_ar_m3;
     reg                              reg_regulation_enable_ar_m3;
     reg                              reg_slv_rdy_ar_m3;
     reg    [`i_axi_AXI_QOSW-1:0]           reg_arqos_m3; 

     reg    [`i_axi_REG_XCT_RATE_W-1:0]     reg_xct_rate_aw_m4;
     reg    [`i_axi_REG_BURSTINESS_W-1:0]   reg_burstiness_aw_m4;
     reg    [`i_axi_REG_PEAK_RATE_W-1:0]    reg_peak_rate_aw_m4;
     reg                              reg_regulation_enable_aw_m4;
     reg                              reg_slv_rdy_aw_m4;
     reg    [`i_axi_AXI_QOSW-1:0]           reg_awqos_m4;
     reg    [`i_axi_REG_XCT_RATE_W-1:0]     reg_xct_rate_ar_m4;
     reg    [`i_axi_REG_BURSTINESS_W-1:0]   reg_burstiness_ar_m4;
     reg    [`i_axi_REG_PEAK_RATE_W-1:0]    reg_peak_rate_ar_m4;
     reg                              reg_regulation_enable_ar_m4;
     reg                              reg_slv_rdy_ar_m4;
     reg    [`i_axi_AXI_QOSW-1:0]           reg_arqos_m4; 

     reg    [`i_axi_REG_XCT_RATE_W-1:0]     reg_xct_rate_aw_m5;
     reg    [`i_axi_REG_BURSTINESS_W-1:0]   reg_burstiness_aw_m5;
     reg    [`i_axi_REG_PEAK_RATE_W-1:0]    reg_peak_rate_aw_m5;
     reg                              reg_regulation_enable_aw_m5;
     reg                              reg_slv_rdy_aw_m5;
     reg    [`i_axi_AXI_QOSW-1:0]           reg_awqos_m5;
     reg    [`i_axi_REG_XCT_RATE_W-1:0]     reg_xct_rate_ar_m5;
     reg    [`i_axi_REG_BURSTINESS_W-1:0]   reg_burstiness_ar_m5;
     reg    [`i_axi_REG_PEAK_RATE_W-1:0]    reg_peak_rate_ar_m5;
     reg                              reg_regulation_enable_ar_m5;
     reg                              reg_slv_rdy_ar_m5;
     reg    [`i_axi_AXI_QOSW-1:0]           reg_arqos_m5; 

     reg    [`i_axi_REG_XCT_RATE_W-1:0]     reg_xct_rate_aw_m6;
     reg    [`i_axi_REG_BURSTINESS_W-1:0]   reg_burstiness_aw_m6;
     reg    [`i_axi_REG_PEAK_RATE_W-1:0]    reg_peak_rate_aw_m6;
     reg                              reg_regulation_enable_aw_m6;
     reg                              reg_slv_rdy_aw_m6;
     reg    [`i_axi_AXI_QOSW-1:0]           reg_awqos_m6;
     reg    [`i_axi_REG_XCT_RATE_W-1:0]     reg_xct_rate_ar_m6;
     reg    [`i_axi_REG_BURSTINESS_W-1:0]   reg_burstiness_ar_m6;
     reg    [`i_axi_REG_PEAK_RATE_W-1:0]    reg_peak_rate_ar_m6;
     reg                              reg_regulation_enable_ar_m6;
     reg                              reg_slv_rdy_ar_m6;
     reg    [`i_axi_AXI_QOSW-1:0]           reg_arqos_m6; 

     reg    [`i_axi_REG_XCT_RATE_W-1:0]     reg_xct_rate_aw_m7;
     reg    [`i_axi_REG_BURSTINESS_W-1:0]   reg_burstiness_aw_m7;
     reg    [`i_axi_REG_PEAK_RATE_W-1:0]    reg_peak_rate_aw_m7;
     reg                              reg_regulation_enable_aw_m7;
     reg                              reg_slv_rdy_aw_m7;
     reg    [`i_axi_AXI_QOSW-1:0]           reg_awqos_m7;
     reg    [`i_axi_REG_XCT_RATE_W-1:0]     reg_xct_rate_ar_m7;
     reg    [`i_axi_REG_BURSTINESS_W-1:0]   reg_burstiness_ar_m7;
     reg    [`i_axi_REG_PEAK_RATE_W-1:0]    reg_peak_rate_ar_m7;
     reg                              reg_regulation_enable_ar_m7;
     reg                              reg_slv_rdy_ar_m7;
     reg    [`i_axi_AXI_QOSW-1:0]           reg_arqos_m7; 

     reg    [`i_axi_REG_XCT_RATE_W-1:0]     reg_xct_rate_aw_m8;
     reg    [`i_axi_REG_BURSTINESS_W-1:0]   reg_burstiness_aw_m8;
     reg    [`i_axi_REG_PEAK_RATE_W-1:0]    reg_peak_rate_aw_m8;
     reg                              reg_regulation_enable_aw_m8;
     reg                              reg_slv_rdy_aw_m8;
     reg    [`i_axi_AXI_QOSW-1:0]           reg_awqos_m8;
     reg    [`i_axi_REG_XCT_RATE_W-1:0]     reg_xct_rate_ar_m8;
     reg    [`i_axi_REG_BURSTINESS_W-1:0]   reg_burstiness_ar_m8;
     reg    [`i_axi_REG_PEAK_RATE_W-1:0]    reg_peak_rate_ar_m8;
     reg                              reg_regulation_enable_ar_m8;
     reg                              reg_slv_rdy_ar_m8;
     reg    [`i_axi_AXI_QOSW-1:0]           reg_arqos_m8; 

     reg    [`i_axi_REG_XCT_RATE_W-1:0]     reg_xct_rate_aw_m9;
     reg    [`i_axi_REG_BURSTINESS_W-1:0]   reg_burstiness_aw_m9;
     reg    [`i_axi_REG_PEAK_RATE_W-1:0]    reg_peak_rate_aw_m9;
     reg                              reg_regulation_enable_aw_m9;
     reg                              reg_slv_rdy_aw_m9;
     reg    [`i_axi_AXI_QOSW-1:0]           reg_awqos_m9;
     reg    [`i_axi_REG_XCT_RATE_W-1:0]     reg_xct_rate_ar_m9;
     reg    [`i_axi_REG_BURSTINESS_W-1:0]   reg_burstiness_ar_m9;
     reg    [`i_axi_REG_PEAK_RATE_W-1:0]    reg_peak_rate_ar_m9;
     reg                              reg_regulation_enable_ar_m9;
     reg                              reg_slv_rdy_ar_m9;
     reg    [`i_axi_AXI_QOSW-1:0]           reg_arqos_m9; 

     reg    [`i_axi_REG_XCT_RATE_W-1:0]     reg_xct_rate_aw_m10;
     reg    [`i_axi_REG_BURSTINESS_W-1:0]   reg_burstiness_aw_m10;
     reg    [`i_axi_REG_PEAK_RATE_W-1:0]    reg_peak_rate_aw_m10;
     reg                              reg_regulation_enable_aw_m10;
     reg                              reg_slv_rdy_aw_m10;
     reg    [`i_axi_AXI_QOSW-1:0]           reg_awqos_m10;
     reg    [`i_axi_REG_XCT_RATE_W-1:0]     reg_xct_rate_ar_m10;
     reg    [`i_axi_REG_BURSTINESS_W-1:0]   reg_burstiness_ar_m10;
     reg    [`i_axi_REG_PEAK_RATE_W-1:0]    reg_peak_rate_ar_m10;
     reg                              reg_regulation_enable_ar_m10;
     reg                              reg_slv_rdy_ar_m10;
     reg    [`i_axi_AXI_QOSW-1:0]           reg_arqos_m10; 

     reg    [`i_axi_REG_XCT_RATE_W-1:0]     reg_xct_rate_aw_m11;
     reg    [`i_axi_REG_BURSTINESS_W-1:0]   reg_burstiness_aw_m11;
     reg    [`i_axi_REG_PEAK_RATE_W-1:0]    reg_peak_rate_aw_m11;
     reg                              reg_regulation_enable_aw_m11;
     reg                              reg_slv_rdy_aw_m11;
     reg    [`i_axi_AXI_QOSW-1:0]           reg_awqos_m11;
     reg    [`i_axi_REG_XCT_RATE_W-1:0]     reg_xct_rate_ar_m11;
     reg    [`i_axi_REG_BURSTINESS_W-1:0]   reg_burstiness_ar_m11;
     reg    [`i_axi_REG_PEAK_RATE_W-1:0]    reg_peak_rate_ar_m11;
     reg                              reg_regulation_enable_ar_m11;
     reg                              reg_slv_rdy_ar_m11;
     reg    [`i_axi_AXI_QOSW-1:0]           reg_arqos_m11; 

     reg    [`i_axi_REG_XCT_RATE_W-1:0]     reg_xct_rate_aw_m12;
     reg    [`i_axi_REG_BURSTINESS_W-1:0]   reg_burstiness_aw_m12;
     reg    [`i_axi_REG_PEAK_RATE_W-1:0]    reg_peak_rate_aw_m12;
     reg                              reg_regulation_enable_aw_m12;
     reg                              reg_slv_rdy_aw_m12;
     reg    [`i_axi_AXI_QOSW-1:0]           reg_awqos_m12;
     reg    [`i_axi_REG_XCT_RATE_W-1:0]     reg_xct_rate_ar_m12;
     reg    [`i_axi_REG_BURSTINESS_W-1:0]   reg_burstiness_ar_m12;
     reg    [`i_axi_REG_PEAK_RATE_W-1:0]    reg_peak_rate_ar_m12;
     reg                              reg_regulation_enable_ar_m12;
     reg                              reg_slv_rdy_ar_m12;
     reg    [`i_axi_AXI_QOSW-1:0]           reg_arqos_m12; 

     reg    [`i_axi_REG_XCT_RATE_W-1:0]     reg_xct_rate_aw_m13;
     reg    [`i_axi_REG_BURSTINESS_W-1:0]   reg_burstiness_aw_m13;
     reg    [`i_axi_REG_PEAK_RATE_W-1:0]    reg_peak_rate_aw_m13;
     reg                              reg_regulation_enable_aw_m13;
     reg                              reg_slv_rdy_aw_m13;
     reg    [`i_axi_AXI_QOSW-1:0]           reg_awqos_m13;
     reg    [`i_axi_REG_XCT_RATE_W-1:0]     reg_xct_rate_ar_m13;
     reg    [`i_axi_REG_BURSTINESS_W-1:0]   reg_burstiness_ar_m13;
     reg    [`i_axi_REG_PEAK_RATE_W-1:0]    reg_peak_rate_ar_m13;
     reg                              reg_regulation_enable_ar_m13;
     reg                              reg_slv_rdy_ar_m13;
     reg    [`i_axi_AXI_QOSW-1:0]           reg_arqos_m13; 

     reg    [`i_axi_REG_XCT_RATE_W-1:0]     reg_xct_rate_aw_m14;
     reg    [`i_axi_REG_BURSTINESS_W-1:0]   reg_burstiness_aw_m14;
     reg    [`i_axi_REG_PEAK_RATE_W-1:0]    reg_peak_rate_aw_m14;
     reg                              reg_regulation_enable_aw_m14;
     reg                              reg_slv_rdy_aw_m14;
     reg    [`i_axi_AXI_QOSW-1:0]           reg_awqos_m14;
     reg    [`i_axi_REG_XCT_RATE_W-1:0]     reg_xct_rate_ar_m14;
     reg    [`i_axi_REG_BURSTINESS_W-1:0]   reg_burstiness_ar_m14;
     reg    [`i_axi_REG_PEAK_RATE_W-1:0]    reg_peak_rate_ar_m14;
     reg                              reg_regulation_enable_ar_m14;
     reg                              reg_slv_rdy_ar_m14;
     reg    [`i_axi_AXI_QOSW-1:0]           reg_arqos_m14; 

     reg    [`i_axi_REG_XCT_RATE_W-1:0]     reg_xct_rate_aw_m15;
     reg    [`i_axi_REG_BURSTINESS_W-1:0]   reg_burstiness_aw_m15;
     reg    [`i_axi_REG_PEAK_RATE_W-1:0]    reg_peak_rate_aw_m15;
     reg                              reg_regulation_enable_aw_m15;
     reg                              reg_slv_rdy_aw_m15;
     reg    [`i_axi_AXI_QOSW-1:0]           reg_awqos_m15;
     reg    [`i_axi_REG_XCT_RATE_W-1:0]     reg_xct_rate_ar_m15;
     reg    [`i_axi_REG_BURSTINESS_W-1:0]   reg_burstiness_ar_m15;
     reg    [`i_axi_REG_PEAK_RATE_W-1:0]    reg_peak_rate_ar_m15;
     reg                              reg_regulation_enable_ar_m15;
     reg                              reg_slv_rdy_ar_m15;
     reg    [`i_axi_AXI_QOSW-1:0]           reg_arqos_m15; 

     reg    [`i_axi_REG_XCT_RATE_W-1:0]     reg_xct_rate_aw_m16;
     reg    [`i_axi_REG_BURSTINESS_W-1:0]   reg_burstiness_aw_m16;
     reg    [`i_axi_REG_PEAK_RATE_W-1:0]    reg_peak_rate_aw_m16;
     reg                              reg_regulation_enable_aw_m16;
     reg                              reg_slv_rdy_aw_m16;
     reg    [`i_axi_AXI_QOSW-1:0]           reg_awqos_m16;
     reg    [`i_axi_REG_XCT_RATE_W-1:0]     reg_xct_rate_ar_m16;
     reg    [`i_axi_REG_BURSTINESS_W-1:0]   reg_burstiness_ar_m16;
     reg    [`i_axi_REG_PEAK_RATE_W-1:0]    reg_peak_rate_ar_m16;
     reg                              reg_regulation_enable_ar_m16;
     reg                              reg_slv_rdy_ar_m16;
     reg    [`i_axi_AXI_QOSW-1:0]           reg_arqos_m16; 
     reg                              command_en_aclk_d; 
     wire                             wr_en_stb; 
     wire                             internal_rst; 

  always @(posedge aclk or negedge aresetn) begin : QOSDEC_PROC
       if  (aresetn == 1'b0) begin
    // Reg outputs are assigned to default value on system reset 

     reg_awqos_m1                <={(`i_axi_AXI_QOSW){1'b0}};
     reg_arqos_m1                <={(`i_axi_AXI_QOSW){1'b0}};

     reg_awqos_m2                <={(`i_axi_AXI_QOSW){1'b0}};
     reg_arqos_m2                <={(`i_axi_AXI_QOSW){1'b0}};














 //rdata                             <=32'b0;
     err_bit_w                 <= 1'b0; 
 end 
 else  if (internal_rst == 1'b1) begin 
 // Reg outputs are assigned to default value on soft reset

     reg_awqos_m1                <={(`i_axi_AXI_QOSW){1'b0}};
     reg_arqos_m1                <={(`i_axi_AXI_QOSW){1'b0}};

     reg_awqos_m2                <={(`i_axi_AXI_QOSW){1'b0}};
     reg_arqos_m2                <={(`i_axi_AXI_QOSW){1'b0}};














//     rdata                             <=32'b0;
     err_bit_w              <= 1'b0;
  
 end 
 else  if ( wr_en_stb == 1'b1) begin 
 // Write opertaion on Reg outputs, Qualified at command_en  
 case (addr) 
 
   8'd0 : begin
            err_bit_w <= 1'b1 ;
            end 
 
   8'd1 : begin
             err_bit_w <= 1'b1 ;
            end 
 
   8'd2 : begin 
            reg_arqos_m1                <= wdata [`i_axi_AXI_QOSW-1:0];  
            err_bit_w <= 1'b0 ; 
            end 
 
   8'd3 :  begin 
             err_bit_w <= 1'b1 ;
             end 
 
   8'd8 : begin
            err_bit_w <= 1'b1 ;
            end 
 
   8'd9 : begin
            err_bit_w <= 1'b1 ;
              end
     
 
   8'd10 :  begin  
              reg_awqos_m1            <= wdata [`i_axi_AXI_QOSW-1:0];  
             err_bit_w <= 1'b0 ; 
               end 
 
   8'd11 :  begin
            err_bit_w <= 1'b1 ;
               end 
 
   8'd16 : begin
            err_bit_w <= 1'b1 ;
            end 
 
   8'd17 : begin
             err_bit_w <= 1'b1 ;
            end 
 
   8'd18 : begin 
            reg_arqos_m2                <= wdata [`i_axi_AXI_QOSW-1:0];  
            err_bit_w <= 1'b0 ; 
            end 
 
   8'd19 :  begin 
             err_bit_w <= 1'b1 ;
             end 
 
   8'd24 : begin
            err_bit_w <= 1'b1 ;
            end 
 
   8'd25 : begin
            err_bit_w <= 1'b1 ;
              end
     
 
   8'd26 :  begin  
              reg_awqos_m2            <= wdata [`i_axi_AXI_QOSW-1:0];  
             err_bit_w <= 1'b0 ; 
               end 
 
   8'd27 :  begin
            err_bit_w <= 1'b1 ;
               end 
 
  default : begin
      err_bit_w                         <= 1'b1;
      end
       
 endcase 
 end 
 end  //end  proc

  always@(*) begin :qos_reg_rd_PROC
       
 // err bit will be asserted if enabler parameter for regiters field is not defined and command read is asserted. 
  rdata                             = 32'b0 ;
          err_bit_r               = 1'b0;  
 if (rd_en == 1'b1) begin 
 case (addr) 

   8'd0 : begin
            rdata    = 32'b0;
            err_bit_r  =  1'b1;
      end 
 
   8'd1 : begin 
            rdata    = 32'b0;
            err_bit_r  =  1'b1;
      end 
 
   8'd2 : begin
             rdata[31:0]  = {{(32-`i_axi_AXI_QOSW){1'b0}},
                             reg_arqos_m1 };
           err_bit_r  =  1'b0; 
               end 
 
   8'd3 : begin
            rdata    = 32'b0;
            err_bit_r  = 1'b1 ;
      end 
 
   8'd8 : begin 
            rdata    = 32'b0;
            err_bit_r  =  1'b1;
      end 
 
   8'd9 : begin
            rdata    = 32'b0;
            err_bit_r  =  1'b1;
      end 
 
   8'd10 : begin
              rdata[31:0]  = {{(32-`i_axi_AXI_QOSW){1'b0}},
                             reg_awqos_m1 };
            err_bit_r  =  1'b0 ; 
               end 
 
   8'd11 : begin
          rdata    = 32'b0;
          err_bit_r  =  1'b1;
      end 

   8'd16 : begin
            rdata    = 32'b0;
            err_bit_r  =  1'b1;
      end 
 
   8'd17 : begin 
            rdata    = 32'b0;
            err_bit_r  =  1'b1;
      end 
 
   8'd18 : begin
             rdata[31:0]  = {{(32-`i_axi_AXI_QOSW){1'b0}},
                             reg_arqos_m2 };
           err_bit_r  =  1'b0; 
               end 
 
   8'd19 : begin
            rdata    = 32'b0;
            err_bit_r  = 1'b1 ;
      end 
 
   8'd24 : begin 
            rdata    = 32'b0;
            err_bit_r  =  1'b1;
      end 
 
   8'd25 : begin
            rdata    = 32'b0;
            err_bit_r  =  1'b1;
      end 
 
   8'd26 : begin
              rdata[31:0]  = {{(32-`i_axi_AXI_QOSW){1'b0}},
                             reg_awqos_m2 };
            err_bit_r  =  1'b0 ; 
               end 
 
   8'd27 : begin
          rdata    = 32'b0;
          err_bit_r  =  1'b1;
      end 














 
  default : begin 
      rdata                   = 32'b0 ;
      err_bit_r               = 1'b1;
      end
       
 endcase 
 end 
 end  //PROC

//  /*---------------------------------------------------------
//   Clocking status of err_bit when write/read enable is asserted
//  ---------------------------------------------------------*/
 
  always@(posedge aclk or negedge aresetn) begin: SYNC_ERR_BIT_PROC
    if (aresetn ==1'b0) 
      err_bit <= 1'b0 ;
    else  if (internal_rst == 1'b1) 
      err_bit <= 1'b0 ;
    else      err_bit <=  (wr_en && err_bit_w) || (rd_en && err_bit_r) || ( (~wr_en) && (~rd_en) && (err_bit) )  ;
  end 

  always@(posedge aclk or negedge aresetn) begin: CMD_EN_ACLK_DLY_PROC
    if (aresetn ==1'b0) begin
      command_en_aclk_d <= 1'b0;
    end else begin
      command_en_aclk_d <= command_en_aclk;
    end
  end

  assign wr_en_stb = wr_en & (~command_en_aclk_d) & command_en_aclk;
  assign internal_rst = internal_reg_rst & (~command_en_aclk_d) & command_en_aclk;
   
 endmodule 
