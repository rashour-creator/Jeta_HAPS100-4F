//------------------------------------------------------------------------
//--
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
// File Version     :        $Revision: #7 $ 
// Revision: $Id: //dwh/DW_ocb/DW_axi/axi_dev_br/sim/test_svte_axi/test.sv#7 $ 
//------------------------------------------------------------------------

`ifndef TEST_V
`define TEST_V

/** 
  * This is main module from which all the traffic is initiated.
  *  -- If QOS is enabled, then qos registers are programmed firstly.
  *  -- Since slave needs to be reactive respond to the incoming requests, 
  *     slave response thread is forked off.
  *  -- All the individual tests are called sequentially one after the other.
  */ 
module test;

  /** 
    * This task will be called from the top-level file test_DW_axi.v, which triggers
    * the start of test 
    */
  task run_test;
    integer i;  
    begin

      /**
       * If QOS is enabled, then program QOS registers for all Masters
       */
      `ifdef AXI_QOS
        for (i=1;i<=`AXI_NUM_MASTERS;i++) begin
          `TOP.qos_programming(i);  
        end
      `endif    

      /** Call the task to fork off slave random responses */
      `TOP.slaves_rand_response;

      /**
        * Generate traffic from a randomly selected Master to
        * a randomly selected slave.
        */
      `TOP.single_master_single_slave_test;

      /**
        * Generate traffic from all the Masters to 
        * all visible slaves.
        */
      `TOP.multi_master_multi_slave_test;

      /** 
        * Generate traffic targetting the address 
        * to default slave.
        */
      `TOP.default_slave_unaligned_addr_test(1);

      /** 
        * Generate unaligned transfers from a ranomly selected Master
        * to a randomly selected Slave. 
        */
      `TOP.default_slave_unaligned_addr_test(2);
     
      /** Generate exclusive access transfers*/
      `TOP.exclusive_test;
     
`ifdef DW_AXI_TB_ENABLE_QOS_INT
      /** Test Outstanding limit for Same ID's */
      `TOP.test_max_id_limit(0);

      /** Test Outstanding limit for Unique ID's */
      `TOP.test_max_id_limit(1);
`endif

       /** Test Outstanding limit for Unique ID's */
      //`TOP.test_max_id_outstanding_limit(1);
      `TOP.test_max_outstanding_uid(0);

      `TOP.test_max_outstanding_uid(1);

      /** Low Power test - Enabled based on parameter */
      `ifdef AXI_HAS_LOWPWR_HS_IF
        `TOP.axi_low_power_test;
        `TOP.axi_low_power_test_star9000792946;
      `endif

      `ifdef AXI_HAS_AXI3
        repeat (100) @(posedge `TOP.system_clk);
        `TOP.axi_bresp_before_addr_test;
       `endif

      /** Allow the system to be idle before completing simulation */ 
      repeat (1000) @(posedge `TOP.system_clk);
    end
  endtask

//------------------------------------------------------------------------

endmodule

`endif // TEST_V
