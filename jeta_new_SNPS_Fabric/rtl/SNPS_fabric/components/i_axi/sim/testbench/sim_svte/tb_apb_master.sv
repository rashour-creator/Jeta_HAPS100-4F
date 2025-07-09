/*
 ------------------------------------------------------------------------
--
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
// File Version     :        $Revision: #3 $ 
// Revision: $Id: //dwh/DW_ocb/DW_axi/axi_dev_br/sim/testbench/sim_svte/tb_apb_master.sv#3 $ 
*/
`include "apb_if.sv"
module apb_master_vip(apb_if sig_if);

task read(input  bit   [31:0] addr,
           output logic [31:0] data);

  sig_if.master_cb.psel    <= '0;
  sig_if.master_cb.penable <= '0 ;
  sig_if.master_cb.pwrite  <= '0;
  @ (sig_if.master_cb);

  if(`APB_DATA_WIDTH == 32) begin
    sig_if.master_cb.paddr   <= addr;
    sig_if.master_cb.pwrite  <= '0;
    sig_if.master_cb.psel    <= '1;
    sig_if.master_cb.penable    <= '0;//Addr Phase
    @ (sig_if.master_cb);
    sig_if.master_cb.penable <= '1;
    @ (sig_if.master_cb);
    data = sig_if.master_cb.prdata;
    sig_if.master_cb.psel    <= '0;
    sig_if.master_cb.penable <= '0;
  end

  if(`APB_DATA_WIDTH == 16) begin
    sig_if.master_cb.paddr   <= addr;
    sig_if.master_cb.pwrite  <= '0;
    sig_if.master_cb.psel    <= '1;
    @ (sig_if.master_cb);
    sig_if.master_cb.penable <= '1;
    @ (sig_if.master_cb);
    data[15:0] = sig_if.master_cb.prdata[15:0];
    sig_if.master_cb.paddr   <= addr+2;
    sig_if.master_cb.penable <= '0;
    @ (sig_if.master_cb);
    sig_if.master_cb.penable <= '1;
    @ (sig_if.master_cb);
    data[31:16] = sig_if.master_cb.prdata[15:0];
    sig_if.master_cb.psel    <= '0;
    sig_if.master_cb.penable <= '0;
  end

  if(`APB_DATA_WIDTH == 8) begin
    sig_if.master_cb.paddr   <= addr;
    sig_if.master_cb.pwrite  <= '0;
    sig_if.master_cb.psel    <= '1;
    @ (sig_if.master_cb);
    sig_if.master_cb.penable <= '1;
    @ (sig_if.master_cb);
    data[7:0] = sig_if.master_cb.prdata[7:0];
    sig_if.master_cb.paddr   <= addr+1;
    sig_if.master_cb.penable <= '0;
    @ (sig_if.master_cb);
    sig_if.master_cb.penable <= '1;
    @ (sig_if.master_cb);
    data[15:8] = sig_if.master_cb.prdata[7:0];
    sig_if.master_cb.paddr   <= addr+2;
    sig_if.master_cb.penable <= '0;
    @ (sig_if.master_cb);
    sig_if.master_cb.penable <= '1;
    @ (sig_if.master_cb);
    data[23:16] = sig_if.master_cb.prdata[7:0];
    sig_if.master_cb.paddr   <= addr+3;
    sig_if.master_cb.penable <= '0;
    @ (sig_if.master_cb);
    sig_if.master_cb.penable <= '1;
    @ (sig_if.master_cb);
    data[31:24] = sig_if.master_cb.prdata[7:0];
    sig_if.master_cb.psel    <= '0;
    sig_if.master_cb.penable <= '0;
  end
endtask: read

task write(input bit [31:0] addr,
                     input bit [31:0] data);

  sig_if.master_cb.psel    <= '0;
  sig_if.master_cb.penable <= '0 ;
  sig_if.master_cb.pwrite  <= '0;
  @ (sig_if.master_cb);
  if(`APB_DATA_WIDTH == 32) begin
    sig_if.master_cb.paddr         <= addr;
    sig_if.master_cb.pwdata        <= data;
    sig_if.master_cb.pwrite        <= '1;
    sig_if.master_cb.psel          <= '1;
    sig_if.master_cb.penable    <= '0;//Addr Phase
    @ (sig_if.master_cb);
    sig_if.master_cb.penable       <= '1;
    @ (sig_if.master_cb);
    sig_if.master_cb.psel          <= '0;
    sig_if.master_cb.penable       <= '0;
  end
 if(`APB_DATA_WIDTH == 16) begin
   sig_if.master_cb.paddr         <= addr;
   sig_if.master_cb.pwdata[15:0]  <= data[15:0];
   sig_if.master_cb.pwrite        <= '1;
   sig_if.master_cb.psel          <= '1;
   @ (sig_if.master_cb);
   sig_if.master_cb.penable       <= '1;
   @ (sig_if.master_cb);
   sig_if.master_cb.paddr         <= addr+2;
   sig_if.master_cb.pwdata[15:0]  <= data[31:16];
   sig_if.master_cb.penable       <= '0;
   @ (sig_if.master_cb);
   sig_if.master_cb.penable       <= '1;
   @ (sig_if.master_cb);
   sig_if.master_cb.psel          <= '0;
   sig_if.master_cb.penable       <= '0;
 end
 if(`APB_DATA_WIDTH == 8) begin
   sig_if.master_cb.paddr         <= addr;
   sig_if.master_cb.pwdata[7:0]   <= data[7:0];
   sig_if.master_cb.pwrite        <= '1;
   sig_if.master_cb.psel          <= '1;
   @ (sig_if.master_cb);
   sig_if.master_cb.penable       <= '1;
   @ (sig_if.master_cb);
   sig_if.master_cb.paddr         <= addr+1;
   sig_if.master_cb.pwdata[7:0]   <= data[15:8];
   sig_if.master_cb.penable       <= '0;
   @ (sig_if.master_cb);
   sig_if.master_cb.penable       <= '1;
   @ (sig_if.master_cb);
   sig_if.master_cb.paddr         <= addr+2;
   sig_if.master_cb.pwdata[7:0]   <= data[23:16];
   sig_if.master_cb.penable       <= '0;
   @ (sig_if.master_cb);
   sig_if.master_cb.penable       <= '1;
   @ (sig_if.master_cb);
   sig_if.master_cb.paddr         <= addr+3;
   sig_if.master_cb.pwdata[7:0]   <= data[31:24];
   // Delay one more cycle 
   @ (sig_if.master_cb);
   sig_if.master_cb.psel          <= '0;
   sig_if.master_cb.penable       <= '0;
 end
          
endtask: write




endmodule
