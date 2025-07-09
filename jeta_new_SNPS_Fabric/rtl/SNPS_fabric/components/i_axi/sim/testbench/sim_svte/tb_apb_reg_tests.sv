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
// Revision: $Id: //dwh/DW_ocb/DW_axi/axi_dev_br/sim/testbench/sim_svte/tb_apb_reg_tests.sv#3 $ 
*/
`ifdef DW_AXI_TB_ENABLE_QOS_INT
   // SNPS: used if code invisible in release database
   //  controled by SNPS_INTERNAL_ON
    $display("\n +------------------------------------------------------------------------------------- ");
    $display("\n           BEGIN REGISTER READ-WRITE TEST - APB INTERFACE                               ");
    $display("\n +------------------------------------------------------------------------------------- ");

   //++-----------------------------------------------------
   // TEST - All QOS reg - Indirect read/writes - AW Chann
   //++-----------------------------------------------------
   for(i=1;i<=`AXI_NUM_MASTERS;i=i+1) begin
    test_qos_reg_back2back(i,1'b1);
   end
   
   //++-----------------------------------------------------
   // TEST - All QOS reg - Indirect read/writes - AR Chann
   //++-----------------------------------------------------
   for(i=1;i<=`AXI_NUM_MASTERS;i=i+1) begin
    test_qos_reg_back2back(i,1'b0);
   end
   
   //++-------------------------------------------------
   // TEST - All QOS reg - Direct read/writes
   //++-------------------------------------------------
   for(i=1;i<=`AXI_NUM_MASTERS;i=i+1) begin
    test_qos_reg_direct(i);
   end
   
   //++-------------------------------------------------
   // TEST - Soft Reset TESTS
   //++-------------------------------------------------
   for(i=1;i<=`AXI_NUM_MASTERS;i=i+1) begin
    soft_reset_test(i);
   end
   
   //++-------------------------------------------------
   // TEST - HARD Reset TESTS
   //++-------------------------------------------------
    reset_test(1'b1,1'b0); // FOR AW channels/APB reset
    reset_test(1'b0,1'b0); // FOR AR channels/APB reset
    
    reset_test(1'b1,1'b1); // FOR AW channels/APB-AXI reset
    reset_test(1'b0,1'b1); // FOR AR channels/APB-AXI reset
   
   //++-------------------------------------------------
   // TEST - Check if CMD disable works 
   //++-------------------------------------------------
   for(i=1;i<=`AXI_NUM_MASTERS;i=i+1) begin
    do_cmd_test(i,0,1);//AW channel
    do_cmd_test(i,0,0); //AR Channel
   end 
   
   //++-------------------------------------------------
   // TEST - Check if back to back CMD enable 
   //++-------------------------------------------------
   for(i=1;i<=`AXI_NUM_MASTERS;i=i+1) begin
    do_cmd_test(i,1,1);
    do_cmd_test(i,1,0);
   end 
   
   //++-------------------------------------------------
   // Error bit generation TEST
   //++-------------------------------------------------
     cmd_reg_err_bit_gen(1'b1); // AW channel
     cmd_reg_err_bit_gen(1'b0); //AR channel
   
   //++-------------------------------------------------
   // Reg test for VERSION ID / HW CFG 
   //++-------------------------------------------------
     test_version_hwcfg_reg();  
   $display("\n +----------- DONE REGISTER READ/WRITE TEST ------------------------------------------+\n");

`endif
