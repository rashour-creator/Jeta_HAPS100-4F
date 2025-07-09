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
// File Version     :        $Revision: #11 $ 
// Revision: $Id: //dwh/DW_ocb/DW_axi/axi_dev_br/sim/testbench/sim_svte/tb_checker.sv#11 $ 
//------------------------------------------------------------------------

`ifndef TB_CHECKER_V
`define TB_CHECKER_V

// ------------------------------------------------------------------------------------------------------------------------------------

/** 
  * Checker for REGION signals
  * REGION signals are driven based on the memory map.
  * Expected values are computed as below:
  * - Based on the Slave address and memorymap, region value
  *   pre-calculated and stored as expected value.
  * - Actual value is sampled from the REGION signal seen on
  *   the interface
  */
task automatic check_region_decoding;
  input [31:0] slaveID;
  reg [3:0] awregion_actual,arregion_actual;
  reg [3:0] awregion_expected,arregion_expected;
  reg [`AXI_AW-1:0] awaddr_tmp,araddr_tmp;
begin
  if (test_debug) $display("@%0d [TB_DEBUG] {%m} : Calling check_region_decoding for Slave=%0d\n",$time,slaveID);
  fork
  begin //Write Address channel
    while (1) begin
      @(posedge `TOP.aclk);

      if (awvalid_s_bus[slaveID - 1]) begin
        if (test_debug) $display("@%0d [TB_DEBUG] {%m} : Detected valid write transaction for Slave=%0d\n",$time,slaveID);
        awregion_actual = awregion_s[slaveID];
        awaddr_tmp      = awaddr_s[slaveID];

        //Compute the expected region value
        if ( awaddr_tmp >= slv_region_start_array[slaveID][0] && awaddr_tmp <= slv_region_end_array[slaveID][0] ) awregion_expected = 0;
        else if ( awaddr_tmp >= slv_region_start_array[slaveID][1] && awaddr_tmp <= slv_region_end_array[slaveID][1] ) awregion_expected = 1;
        else if ( awaddr_tmp >= slv_region_start_array[slaveID][2] && awaddr_tmp <= slv_region_end_array[slaveID][2] ) awregion_expected = 2;
        else if ( awaddr_tmp >= slv_region_start_array[slaveID][3] && awaddr_tmp <= slv_region_end_array[slaveID][3] ) awregion_expected = 3;
        else if ( awaddr_tmp >= slv_region_start_array[slaveID][4] && awaddr_tmp <= slv_region_end_array[slaveID][4] ) awregion_expected = 4;
        else if ( awaddr_tmp >= slv_region_start_array[slaveID][5] && awaddr_tmp <= slv_region_end_array[slaveID][5] ) awregion_expected = 5;
        else if ( awaddr_tmp >= slv_region_start_array[slaveID][6] && awaddr_tmp <= slv_region_end_array[slaveID][6] ) awregion_expected = 6;
        else if ( awaddr_tmp >= slv_region_start_array[slaveID][7] && awaddr_tmp <= slv_region_end_array[slaveID][7] ) awregion_expected = 7;
    
        if (awregion_actual !== awregion_expected) begin
          $display("ERROR: %0d - SLV AWREGION CHECKER - Slave %0d: Received AWREGION value %0h, expected AWREGION value %0h;  Address value %0h", $time, slaveID, awregion_actual, awregion_expected, awaddr_tmp);
        end 
      end  
    end  
  end  
  begin //Read Address channel
    while (1) begin
      @(posedge `TOP.aclk);

      if (arvalid_s_bus[slaveID - 1]) begin
        if (test_debug) $display("@%0d [TB_DEBUG] {%m} : Detected valid read transaction for Slave=%0d\n",$time,slaveID);
        arregion_actual = arregion_s[slaveID];
        araddr_tmp      = araddr_s[slaveID];

        //Compute the expected region value
        if ( araddr_tmp >= slv_region_start_array[slaveID][0] && araddr_tmp <= slv_region_end_array[slaveID][0] ) arregion_expected = 0;
        else if ( araddr_tmp >= slv_region_start_array[slaveID][1] && araddr_tmp <= slv_region_end_array[slaveID][1] ) arregion_expected = 1;
        else if ( araddr_tmp >= slv_region_start_array[slaveID][2] && araddr_tmp <= slv_region_end_array[slaveID][2] ) arregion_expected = 2;
        else if ( araddr_tmp >= slv_region_start_array[slaveID][3] && araddr_tmp <= slv_region_end_array[slaveID][3] ) arregion_expected = 3;
        else if ( araddr_tmp >= slv_region_start_array[slaveID][4] && araddr_tmp <= slv_region_end_array[slaveID][4] ) arregion_expected = 4;
        else if ( araddr_tmp >= slv_region_start_array[slaveID][5] && araddr_tmp <= slv_region_end_array[slaveID][5] ) arregion_expected = 5;
        else if ( araddr_tmp >= slv_region_start_array[slaveID][6] && araddr_tmp <= slv_region_end_array[slaveID][6] ) arregion_expected = 6;
        else if ( araddr_tmp >= slv_region_start_array[slaveID][7] && araddr_tmp <= slv_region_end_array[slaveID][7] ) arregion_expected = 7;

        if (arregion_actual !== arregion_expected) begin
          $display("ERROR: %0d - SLV ARREGION CHECKER - Slave %0d: Received ARREGION value %0h, expected ARREGION value %0h;  Address value %0h", $time, slaveID, arregion_actual, arregion_expected, araddr_tmp);
        end 
      end  
    end  
  end    
  join_none
end
endtask : check_region_decoding

// ------------------------------------------------------------------------------------------------------------------------------------

/** 
  * Checker for ACE-LITE signals
  * ACELITE signals are just pass through in the interconnect
  * Expected values are computed as below:
  * AWBAR = ~AWBURST, AWDOMAIN = AWBURST, AWSNOOP = AWPROT
  * ARBAR = ~ARBURST, ARDOMAIN = ARBURST, ARSNOOP = ARCACHE
  */
task automatic check_acelite_signals;
  input [31:0] slaveID;
  reg [1:0] awdomain_actual, awdomain_expected;
  reg [1:0] ardomain_actual, ardomain_expected;
  reg [1:0] awbar_actual, awbar_expected;
  reg [1:0] arbar_actual, arbar_expected;
  reg [2:0] wsnoop_actual, wsnoop_expected;
  reg [3:0] rsnoop_actual, rsnoop_expected;
begin
  if (test_debug) $display("@%0d [TB_DEBUG] {%m} : Calling check_acelite_signals for Slave=%0d\n",$time,slaveID);
  fork
  begin //Write Address channel
    while (1) begin
      @(posedge `TOP.aclk);

      if (awvalid_s_bus[slaveID - 1]) begin
        awdomain_expected = awburst_s[slaveID];
        awdomain_actual   = awdomain_s[slaveID];
        awbar_expected    = ~awburst_s[slaveID];
        awbar_actual      = awbar_s[slaveID];  
        wsnoop_expected   = awprot_s[slaveID];
        wsnoop_actual     = awsnoop_s[slaveID];  
        if (awdomain_actual !== awdomain_expected) begin
          $display("ERROR: %0d - SLV AWDOMAIN CHECKER - Slave %0d: Received AWDOMAIN value %0h, expected AWDOMAIN value %0h", $time, slaveID, awdomain_actual, awdomain_expected);
        end 
        else begin
          if (test_debug) $display("DEBUG: %0d - SLV AWDOMAIN CHECKER - Slave %0d: Received AWDOMAIN value %0h, expected AWDOMAIN value %0h", $time, slaveID, awdomain_actual, awdomain_expected);
        end   
        if (awbar_actual !== awbar_expected) begin
          $display("ERROR: %0d - SLV AWBAR CHECKER - Slave %0d: Received AWBAR value %0h, expected AWBAR value %0h", $time, slaveID, awbar_actual, awbar_expected);
        end    
        else begin
          if (test_debug) $display("DEBUG: %0d - SLV AWBAR CHECKER - Slave %0d: Received AWBAR value %0h, expected AWBAR value %0h", $time, slaveID, awbar_actual, awbar_expected);
        end   
        if (wsnoop_actual !== wsnoop_expected) begin
          $display("ERROR: %0d - SLV AWSNOOP CHECKER - Slave %0d: Received AWSNOOP value %0h, expected AWSNOOP value %0h", $time, slaveID, wsnoop_actual, wsnoop_expected);
        end    
        else begin
          if (test_debug) $display("DEBUG: %0d - SLV AWSNOOP CHECKER - Slave %0d: Received AWSNOOP value %0h, expected AWSNOOP value %0h", $time, slaveID, wsnoop_actual, wsnoop_expected);
        end   
      end
    end  
  end
  begin
    while (1) begin
      @(posedge `TOP.aclk);

      if (arvalid_s_bus[slaveID - 1]) begin
        ardomain_expected = arburst_s[slaveID];
        ardomain_actual   = ardomain_s[slaveID];
        arbar_expected    = ~arburst_s[slaveID];
        arbar_actual      = arbar_s[slaveID];  
        rsnoop_expected   = arcache_s[slaveID];
        rsnoop_actual     = arsnoop_s[slaveID];

        if (ardomain_actual !== ardomain_expected) begin
          $display("ERROR: %0d - SLV ARDOMAIN CHECKER - Slave %0d: Received ARDOMAIN value %0h, expected ARDOMAIN value %0h", $time, slaveID, ardomain_actual, ardomain_expected);
        end    
        else begin
          if (test_debug) $display("DEBUG: %0d - SLV ARDOMAIN CHECKER - Slave %0d: Received ARDOMAIN value %0h, expected ARDOMAIN value %0h", $time, slaveID, ardomain_actual, ardomain_expected);
        end   
        if (arbar_actual !== arbar_expected) begin
          $display("ERROR: %0d - SLV ARBAR CHECKER - Slave %0d: Received ARBAR value %0h, expected ARBAR value %0h", $time, slaveID, arbar_actual, arbar_expected);
        end    
        else begin
          if (test_debug) $display("DEBUG: %0d - SLV ARBAR CHECKER - Slave %0d: Received ARBAR value %0h, expected ARBAR value %0h", $time, slaveID, arbar_actual, arbar_expected);
        end   
        if (rsnoop_actual !== rsnoop_expected) begin
          $display("ERROR: %0d - SLV ARSNOOP CHECKER - Slave %0d: Received ARSNOOP value %0h, expected ARSNOOP value %0h", $time, slaveID, rsnoop_actual, rsnoop_expected);
        end    
        else begin
          if (test_debug) $display("DEBUG: %0d - SLV ARSNOOP CHECKER - Slave %0d: Received ARSNOOP value %0h, expected ARSNOOP value %0h", $time, slaveID, rsnoop_actual, rsnoop_expected);
        end   
      end   
    end   
  end    
  join_none
end

endtask : check_acelite_signals

// ------------------------------------------------------------------------------------------------------------------------------------

/** 
  * Checker for sideband signals. The sideband signals are just pass through in the interconnect
  *   For AWSB - awaddr value is replicated twice and driven on awsideband_m*
  *   For ARSB - araddr value is replicated twice and driven on awsideband_m*
  *   For WSB -  wdata  value is replicated 8 times and driven on awsideband_m*
  */
task automatic check_aw_ar_w_sideband_signals;
  input [31:0] slaveID;
  begin
`ifdef AXI_INC_AWSB
    fork 
    begin : check_sideband_signals_awsb
      reg [`AXI_AW_SBW-1:0]   awsideband_expected_s;
      reg [`AXI_AW_SBW-1:0]   awsideband_received_s;
      while (1) begin
        @(posedge `TOP.aclk);
          if (awvalid_s_bus[slaveID - 1]) begin
            awsideband_expected_s = {2{awaddr_s[slaveID][`AXI_AW-1:0]}};
            awsideband_received_s = awsideband_s[slaveID];
            if (awsideband_expected_s !== awsideband_received_s) begin
              $display("ERROR: %0d - SLV AWSIDEBAND CHECKER - Slave %0d: FAIL : Received awsideband value %0h, expected awsideband value %0h", $time, slaveID, awsideband_received_s, awsideband_expected_s);
            end
            else begin
              if (test_debug) $display("DEBUG: %0d - SLV AWSIDEBAND CHECKER - Slave %0d: PASS : Received awsideband value %0h, expected awsideband value %0h", $time, slaveID, awsideband_received_s, awsideband_expected_s);
            end
          end
      end 
    end : check_sideband_signals_awsb
    join_none
`endif

`ifdef AXI_INC_ARSB
    fork 
    begin : check_sideband_signals_arsb
      reg [`AXI_AR_SBW-1:0]   arsideband_expected_s;
      reg [`AXI_AR_SBW-1:0]   arsideband_received_s;
      while (1) begin
        @(posedge `TOP.aclk);
          if (arvalid_s_bus[slaveID - 1]) begin
            arsideband_expected_s = {2{araddr_s[slaveID][`AXI_AW-1:0]}};
            arsideband_received_s = arsideband_s[slaveID];
            if (arsideband_expected_s !== arsideband_received_s) begin
              $display("ERROR: %0d - SLV ARSIDEBAND CHECKER - Slave %0d: FAIL : Received arsideband value %0h, expected arsideband value %0h", $time, slaveID, arsideband_received_s, arsideband_expected_s);
            end
            else begin
              if (test_debug) $display("DEBUG: %0d - SLV ARSIDEBAND CHECKER - Slave %0d: PASS : Received arsideband value %0h, expected arsideband value %0h", $time, slaveID, arsideband_received_s, arsideband_expected_s);
            end
          end
      end // while (1) begin
    end : check_sideband_signals_arsb
    join_none
`endif

`ifdef AXI_INC_WSB
    fork 
    begin : check_sideband_signals_wsb
      reg [`AXI_W_SBW-1:0]   wsideband_expected_s;
      reg [`AXI_W_SBW-1:0]   wsideband_received_s;
      while (1) begin
        @(posedge `TOP.aclk);
          if (wvalid_s[slaveID]) begin
            wsideband_expected_s = {8{wdata_s[slaveID][`AXI_DW-1:0]}};
            wsideband_received_s = wsideband_s[slaveID];
            if (wsideband_expected_s !== wsideband_received_s) begin
              $display("ERROR: %0d - SLV WSIDEBAND CHECKER - Slave %0d: FAIL : Received wsideband value %0h, expected wsideband value %0h", $time, slaveID, wsideband_received_s, wsideband_expected_s);
            end
            else begin
              if (test_debug) $display("DEBUG: %0d - SLV WSIDEBAND CHECKER - Slave %0d: PASS : Received wsideband value %0h, expected wsideband value %0h", $time, slaveID, wsideband_received_s, wsideband_expected_s);
            end
          end
      end // while (1) begin
    end : check_sideband_signals_wsb
    join_none
`endif

  end
endtask : check_aw_ar_w_sideband_signals

// ------------------------------------------------------------------------------------------------------------------------------------

/** 
  * Checker for sideband signals. The sideband signals are just pass through in the interconnect
  *   For BSB - bid value is replicated on bsideband bus
  *   For RSB - rdata value is replicated on the bus
  */
task automatic check_b_r_sideband_signals;
  input [31:0] masterID;
  begin
`ifdef AXI_INC_BSB
    fork 
    begin : check_sideband_signals_bsb
      reg [`AXI_B_SBW-1:0]   bsideband_expected_m;
      reg [`AXI_B_SBW-1:0]   bsideband_received_m;
      while (1) begin
        @(posedge `TOP.aclk);
          if (bvalid_m[masterID]) begin
            bsideband_expected_m = {64{bid_m[masterID][`AXI_MIDW-1:0]}};
            bsideband_received_m = bsideband_m[masterID];
            // additionally check for response value to distingiush the response comming from default slave,
            //  default slave will not drive sideband, hence the value will not match if the response is from default slave
            if ((bsideband_expected_m !== bsideband_received_m) && (bresp_m[masterID] !== 3)) begin
              $display("ERROR: %0d - MSTR BSIDEBAND CHECKER - Master %0d: FAIL : Received bsideband value %0h, expected bsideband value %0h", $time, masterID, bsideband_received_m, bsideband_expected_m);
            end
            else begin
              if (test_debug) $display("DEBUG: %0d - MSTR BSIDEBAND CHECKER - Master %0d: PASS : Received bsideband value %0h, expected bsideband value %0h, bresp = 'b%0b", $time, masterID, bsideband_received_m, bsideband_expected_m, bresp_m[masterID]);
            end
          end
      end // while (1) begin
    end : check_sideband_signals_bsb
    join_none
`endif

`ifdef AXI_INC_RSB
    fork 
    begin : check_sideband_signals_rsb
      reg [`AXI_R_SBW-1:0]   rsideband_expected_m;
      reg [`AXI_R_SBW-1:0]   rsideband_received_m;
      while (1) begin
        @(posedge `TOP.aclk);
          if (rvalid_m[masterID]) begin
            rsideband_expected_m = {8{rdata_m[masterID][`AXI_DW-1:0]}};
            rsideband_received_m = rsideband_m[masterID];
            // additionally check for response value to distingiush the response comming from default slave,
            //  default slave will not drive sideband, hence the value will not match if the response is from default slave
            if ((rsideband_expected_m !== rsideband_received_m) && (bresp_m[masterID] !== 3)) begin
              $display("ERROR: %0d - MSTR RSIDEBAND CHECKER - Master %0d: FAIL : Received rsideband value %0h, expected rsideband value %0h", $time, masterID, rsideband_received_m, rsideband_expected_m);
            end
            else begin
              if (test_debug) $display("DEBUG: %0d - MSTR RSIDEBAND CHECKER - Master %0d: PASS : Received rsideband value %0h, expected rsideband value %0h, bresp = 'b%0b", $time, masterID, rsideband_received_m, rsideband_expected_m, bresp_m[masterID]);
            end
          end
      end // while (1) begin
    end : check_sideband_signals_rsb
    join_none
`endif
  end
endtask : check_b_r_sideband_signals

/**
   Method: check_arida_awida_param
   1. Used to verify AXI_MAX_UWIDA_Mx, AXI_MAX_URIDA_Mx, AXI_MAX_WCA_ID_Mx and AXI_MAX_RCA_ID_Mx 
   2. Method contains counters each for read and write req
   3. In UID testcase, Write counter increase when there is awvalid and awready signal high on primary port
      and decrease when there is bvalid and bready signal high on primary port.
  */
task automatic check_arida_awida_param;
  input [31:0] masterID;
  begin
    fork 
    begin : check_outstanding_req
      reg     [31:0]         cnt_wr_trans_m = 0;
      reg     [31:0]         cnt_rd_trans_m = 0;
      int wid_value[*];
      int rid_value[*];

      while (1) begin
        @(posedge `TOP.aclk);
          if(outstanding_check_en) begin
            if (awvalid_m_bus[masterID-1] && awready_m_bus[masterID-1]) begin
              wid_value[awid_m_bus[(masterID-1)*`SVT_AXI_MAX_ID_WIDTH+:`SVT_AXI_MAX_ID_WIDTH]] = wid_value[awid_m_bus[(masterID-1)*`SVT_AXI_MAX_ID_WIDTH+:`SVT_AXI_MAX_ID_WIDTH]] + 1;
              if(arida_awida_test == 1) begin
                /**
                   1.wid_value will store the number of request with same ID
                   2.Counter(cnt_wr_trans_m,cnt_rd_trans_m) will increase on first request for specific Id
                   3. In case of outstanding request with same ID, below counter(cnt_wr_trans_m,cnt_rd_trans_m) will not increase in ARIDA/AWIDA test case
                   4. Variabe value(wid_value[ID]) increase on each req with same ID and decrease on response/read data for that ID
               */
                if(wid_value[awid_m_bus[(masterID-1)*`SVT_AXI_MAX_ID_WIDTH+:`SVT_AXI_MAX_ID_WIDTH]] == 1) begin
                  /** Counter to track num of outstanding reqeust with Unique ID
                      Increase once receive request with Unique ID
                  */
                  cnt_wr_trans_m = cnt_wr_trans_m + 1;
                end
              end
              if(rca_wca_test) begin
                  /** Counter to track num of outstanding reqeust with Same ID
                      Increase once receive request with Same ID
                   */
                cnt_wr_trans_m = cnt_wr_trans_m + 1;
              end
            end
            if (bvalid_m_bus[masterID-1] && bready_m_bus[masterID-1]) begin
              if(wid_value[bid_m_bus[(masterID-1)*`SVT_AXI_MAX_ID_WIDTH+:`SVT_AXI_MAX_ID_WIDTH]] == 1 &&  arida_awida_test == 1) begin
                cnt_wr_trans_m = cnt_wr_trans_m - 1; 
              end
              if(rca_wca_test) begin
                cnt_wr_trans_m = cnt_wr_trans_m - 1; 
              end
              wid_value[bid_m_bus[(masterID-1)*`SVT_AXI_MAX_ID_WIDTH+:`SVT_AXI_MAX_ID_WIDTH]] = wid_value[bid_m_bus[(masterID-1)*`SVT_AXI_MAX_ID_WIDTH+:`SVT_AXI_MAX_ID_WIDTH]] - 1;
            end
            if (arvalid_m_bus[masterID-1] && arready_m_bus[masterID-1]) begin
              rid_value[arid_m_bus[(masterID-1)*`SVT_AXI_MAX_ID_WIDTH+:`SVT_AXI_MAX_ID_WIDTH]] = rid_value[arid_m_bus[(masterID-1)*`SVT_AXI_MAX_ID_WIDTH+:`SVT_AXI_MAX_ID_WIDTH]] + 1;
              if(arida_awida_test == 1) begin
                if(rid_value[arid_m_bus[(masterID-1)*`SVT_AXI_MAX_ID_WIDTH+:`SVT_AXI_MAX_ID_WIDTH]] == 1) begin
                  cnt_rd_trans_m = cnt_rd_trans_m + 1;
                end
              end
              if(rca_wca_test) begin
                cnt_rd_trans_m = cnt_rd_trans_m + 1;
              end
            end
            if (rvalid_m_bus[masterID-1] && rready_m_bus[masterID-1] && rlast_m_bus[masterID-1]) begin
              if(rid_value[rid_m_bus[(masterID-1)*`SVT_AXI_MAX_ID_WIDTH+:`SVT_AXI_MAX_ID_WIDTH]] == 1 &&  arida_awida_test == 1) begin
                cnt_rd_trans_m = cnt_rd_trans_m - 1; 
              end
              if(rca_wca_test) begin
                cnt_rd_trans_m = cnt_rd_trans_m - 1; 
              end
              rid_value[rid_m_bus[(masterID-1)*`SVT_AXI_MAX_ID_WIDTH+:`SVT_AXI_MAX_ID_WIDTH]] = rid_value[rid_m_bus[(masterID-1)*`SVT_AXI_MAX_ID_WIDTH+:`SVT_AXI_MAX_ID_WIDTH]] - 1;
            end
            if(arida_awida_test == 1) begin
              `ifdef AXI_HAS_M1
              if(masterID == 1) begin
                if(cnt_wr_trans_m > `AXI_MAX_UWIDA_M1 + `AXI_AW_PL_ARB + `PL_BUF_AW) begin
                  $display("!ERROR MAX_UWIDA_M1_CHECK Master %0d Outstanding Write requests %0d increased more than parameter AXI_MAX_UWIDA_M1 %0t",masterID,cnt_wr_trans_m,$time);
                end
                if(cnt_rd_trans_m > `AXI_MAX_URIDA_M1 +  `AXI_AR_PL_ARB + `PL_BUF_AR) begin
                  $display("!ERROR MAX_URIDA_M1_CHECK Master %0d Outstanding Read requests %0d increased more than parameter AXI_MAX_URIDA_M1 %0t",masterID,cnt_rd_trans_m,$time);
                end
              end
              `endif
              `ifdef AXI_HAS_M2
              if(masterID == 2) begin
                if(cnt_wr_trans_m > `AXI_MAX_UWIDA_M2 +  `AXI_AW_PL_ARB + `PL_BUF_AW) begin
                  $display("!ERROR MAX_UWIDA_M2_CHECK Master %0d Outstanding Write requests %0d increased more than parameter AXI_MAX_UWIDA_M2 %0t",masterID,cnt_wr_trans_m,$time);
                end
                if(cnt_rd_trans_m > `AXI_MAX_URIDA_M2 +  `AXI_AR_PL_ARB + `PL_BUF_AR) begin
                  $display("!ERROR MAX_URIDA_M2_CHECK Master %0d Outstanding Read requests %0d increased more than parameter AXI_MAX_URIDA_M2 %0t",masterID,cnt_rd_trans_m,$time);
                end
              end
              `endif
              `ifdef AXI_HAS_M3
              if(masterID == 3) begin
                if(cnt_wr_trans_m > `AXI_MAX_UWIDA_M3 +  `AXI_AW_PL_ARB + `PL_BUF_AW) begin
                  $display("!ERROR MAX_UWIDA_M3_CHECK Master %0d Outstanding Write requests %0d increased more than parameter AXI_MAX_UWIDA_M3 %0t",masterID,cnt_wr_trans_m,$time);
                end
                if(cnt_rd_trans_m > `AXI_MAX_URIDA_M3 +  `AXI_AR_PL_ARB + `PL_BUF_AR) begin
                  $display("!ERROR MAX_URIDA_M3_CHECK Master %0d Outstanding Read requests %0d increased more than parameter AXI_MAX_URIDA_M3 %0t",masterID,cnt_rd_trans_m,$time);
                end
              end
              `endif
              `ifdef AXI_HAS_M4
              if(masterID == 4) begin
                if(cnt_wr_trans_m > `AXI_MAX_UWIDA_M4 + `AXI_AW_PL_ARB + `PL_BUF_AW) begin
                  $display("!ERROR MAX_UWIDA_M4_CHECK Master %0d Outstanding Write requests %0d increased more than parameter AXI_MAX_UWIDA_M4 %0t",masterID,cnt_wr_trans_m,$time);
                end
                if(cnt_rd_trans_m > `AXI_MAX_URIDA_M4 + `AXI_AR_PL_ARB + `PL_BUF_AR) begin
                  $display("!ERROR MAX_URIDA_M4_CHECK Master %0d Outstanding Read requests %0d increased more than parameter AXI_MAX_URIDA_M4 %0t",masterID,cnt_rd_trans_m,$time);
                end
              end
              `endif
              `ifdef AXI_HAS_M5
              if(masterID == 5) begin
                if(cnt_wr_trans_m > `AXI_MAX_UWIDA_M5 + `AXI_AW_PL_ARB + `PL_BUF_AW) begin
                  $display("!ERROR MAX_UWIDA_M5_CHECK Master %0d Outstanding Write requests %0d increased more than parameter AXI_MAX_UWIDA_M5 %0t",masterID,cnt_wr_trans_m,$time);
                end
                if(cnt_rd_trans_m > `AXI_MAX_URIDA_M5 + `AXI_AR_PL_ARB + `PL_BUF_AR) begin
                  $display("!ERROR MAX_URIDA_M5_CHECK Master %0d Outstanding Read requests %0d increased more than parameter AXI_MAX_URIDA_M5 %0t",masterID,cnt_rd_trans_m,$time);
                end
              end
              `endif
              `ifdef AXI_HAS_M6
              if(masterID == 6) begin
                if(cnt_wr_trans_m > `AXI_MAX_UWIDA_M6 + `AXI_AW_PL_ARB + `PL_BUF_AW) begin
                  $display("!ERROR MAX_UWIDA_M6_CHECK Master %0d Outstanding Write requests %0d increased more than parameter AXI_MAX_UWIDA_M6 %0t",masterID,cnt_wr_trans_m,$time);
                end
                if(cnt_rd_trans_m > `AXI_MAX_URIDA_M6 + `AXI_AR_PL_ARB + `PL_BUF_AR) begin
                  $display("!ERROR MAX_URIDA_M6_CHECK Master %0d Outstanding Read requests %0d increased more than parameter AXI_MAX_URIDA_M6 %0t",masterID,cnt_rd_trans_m,$time);
                end
              end
              `endif
              `ifdef AXI_HAS_M7
              if(masterID == 7) begin
                if(cnt_wr_trans_m > `AXI_MAX_UWIDA_M7 + `AXI_AW_PL_ARB + `PL_BUF_AW) begin
                  $display("!ERROR MAX_UWIDA_M7_CHECK Master %0d Outstanding Write requests %0d increased more than parameter AXI_MAX_UWIDA_M7 %0t",masterID,cnt_wr_trans_m,$time);
                end
                if(cnt_rd_trans_m > `AXI_MAX_URIDA_M7 + `AXI_AR_PL_ARB + `PL_BUF_AR) begin
                  $display("!ERROR MAX_URIDA_M7_CHECK Master %0d Outstanding Read requests %0d increased more than parameter AXI_MAX_URIDA_M7 %0t",masterID,cnt_rd_trans_m,$time);
                end
              end
              `endif
              `ifdef AXI_HAS_M8
              if(masterID == 8) begin
                if(cnt_wr_trans_m > `AXI_MAX_UWIDA_M8 + `AXI_AW_PL_ARB + `PL_BUF_AW) begin
                  $display("!ERROR MAX_UWIDA_M8_CHECK Master %0d Outstanding Write requests %0d increased more than parameter AXI_MAX_UWIDA_M8 %0t",masterID,cnt_wr_trans_m,$time);
                end
                if(cnt_rd_trans_m > `AXI_MAX_URIDA_M8 + `AXI_AR_PL_ARB + `PL_BUF_AR) begin
                  $display("!ERROR MAX_URIDA_M8_CHECK Master %0d Outstanding Read requests %0d increased more than parameter AXI_MAX_URIDA_M8 %0t",masterID,cnt_rd_trans_m,$time);
                end
              end
              `endif
              `ifdef AXI_HAS_M9
              if(masterID == 9) begin
                if(cnt_wr_trans_m > `AXI_MAX_UWIDA_M9 + `AXI_AW_PL_ARB + `PL_BUF_AW) begin
                  $display("!ERROR MAX_UWIDA_M9_CHECK Master %0d Outstanding Write requests %0d increased more than parameter AXI_MAX_UWIDA_M9 %0t",masterID,cnt_wr_trans_m,$time);
                end
                if(cnt_rd_trans_m > `AXI_MAX_URIDA_M9 + `AXI_AR_PL_ARB + `PL_BUF_AR) begin
                  $display("!ERROR MAX_URIDA_M9_CHECK Master %0d Outstanding Read requests %0d increased more than parameter AXI_MAX_URIDA_M9 %0t",masterID,cnt_rd_trans_m,$time);
                end
              end
              `endif
              `ifdef AXI_HAS_M10
              if(masterID == 10) begin
                if(cnt_wr_trans_m > `AXI_MAX_UWIDA_M10 + `AXI_AW_PL_ARB + `PL_BUF_AW) begin
                  $display("!ERROR MAX_UWIDA_M10_CHECK Master %0d Outstanding Write requests %0d increased more than parameter AXI_MAX_UWIDA_M10 %0t",masterID,cnt_wr_trans_m,$time);
                end
                if(cnt_rd_trans_m > `AXI_MAX_URIDA_M10 + `AXI_AR_PL_ARB + `PL_BUF_AR) begin
                  $display("!ERROR MAX_URIDA_M10_CHECK Master %0d Outstanding Read requests %0d increased more than parameter AXI_MAX_URIDA_M10 %0t",masterID,cnt_rd_trans_m,$time);
                end
              end
              `endif
              `ifdef AXI_HAS_M11
              if(masterID == 11) begin
                if(cnt_wr_trans_m > `AXI_MAX_UWIDA_M11 + `AXI_AW_PL_ARB + `PL_BUF_AW) begin
                  $display("!ERROR MAX_UWIDA_M11_CHECK Master %0d Outstanding Write requests %0d increased more than parameter AXI_MAX_UWIDA_M11 %0t",masterID,cnt_wr_trans_m,$time);
                end
                if(cnt_rd_trans_m > `AXI_MAX_URIDA_M11 + `AXI_AR_PL_ARB + `PL_BUF_AR) begin
                  $display("!ERROR MAX_URIDA_M11_CHECK Master %0d Outstanding Read requests %0d increased more than parameter AXI_MAX_URIDA_M11 %0t",masterID,cnt_rd_trans_m,$time);
                end
              end
              `endif
              `ifdef AXI_HAS_M12
              if(masterID == 12) begin
                if(cnt_wr_trans_m > `AXI_MAX_UWIDA_M12 + `AXI_AW_PL_ARB + `PL_BUF_AW) begin
                  $display("!ERROR MAX_UWIDA_M12_CHECK Master %0d Outstanding Write requests %0d increased more than parameter AXI_MAX_UWIDA_M12 %0t",masterID,cnt_wr_trans_m,$time);
                end
                if(cnt_rd_trans_m > `AXI_MAX_URIDA_M12 + `AXI_AR_PL_ARB + `PL_BUF_AR) begin
                  $display("!ERROR MAX_URIDA_M12_CHECK Master %0d Outstanding Read requests %0d increased more than parameter AXI_MAX_URIDA_M12 %0t",masterID,cnt_rd_trans_m,$time);
                end
              end
              `endif
              `ifdef AXI_HAS_M13
              if(masterID == 13) begin
                if(cnt_wr_trans_m > `AXI_MAX_UWIDA_M13 + `AXI_AW_PL_ARB + `PL_BUF_AW) begin
                  $display("!ERROR MAX_UWIDA_M13_CHECK Master %0d Outstanding Write requests %0d increased more than parameter AXI_MAX_UWIDA_M13 %0t",masterID,cnt_wr_trans_m,$time);
                end
                if(cnt_rd_trans_m > `AXI_MAX_URIDA_M13 + `AXI_AR_PL_ARB + `PL_BUF_AR) begin
                  $display("!ERROR MAX_URIDA_M13_CHECK Master %0d Outstanding Read requests %0d increased more than parameter AXI_MAX_URIDA_M13 %0t",masterID,cnt_rd_trans_m,$time);
                end
              end
              `endif
              `ifdef AXI_HAS_M14
              if(masterID == 14) begin
                if(cnt_wr_trans_m > `AXI_MAX_UWIDA_M14 + `AXI_AW_PL_ARB + `PL_BUF_AW) begin
                  $display("!ERROR MAX_UWIDA_M14_CHECK Master %0d Outstanding Write requests %0d increased more than parameter AXI_MAX_UWIDA_M14 %0t",masterID,cnt_wr_trans_m,$time);
                end
                if(cnt_rd_trans_m > `AXI_MAX_URIDA_M14 + `AXI_AR_PL_ARB + `PL_BUF_AR) begin
                  $display("!ERROR MAX_URIDA_M14_CHECK Master %0d Outstanding Read requests %0d increased more than parameter AXI_MAX_URIDA_M14 %0t",masterID,cnt_rd_trans_m,$time);
                end
              end
              `endif
              `ifdef AXI_HAS_M15
              if(masterID == 15) begin
                if(cnt_wr_trans_m > `AXI_MAX_UWIDA_M15 + `AXI_AW_PL_ARB + `PL_BUF_AW) begin
                  $display("!ERROR MAX_UWIDA_M15_CHECK Master %0d Outstanding Write requests %0d increased more than parameter AXI_MAX_UWIDA_M15 %0t",masterID,cnt_wr_trans_m,$time);
                end
                if(cnt_rd_trans_m > `AXI_MAX_URIDA_M15 + `AXI_AR_PL_ARB + `PL_BUF_AR) begin
                  $display("!ERROR MAX_URIDA_M15_CHECK Master %0d Outstanding Read requests %0d increased more than parameter AXI_MAX_URIDA_M15 %0t",masterID,cnt_rd_trans_m,$time);
                end
              end
              `endif
              `ifdef AXI_HAS_M16
              if(masterID == 16) begin
                if(cnt_wr_trans_m > `AXI_MAX_UWIDA_M16 + `AXI_AW_PL_ARB + `PL_BUF_AW) begin
                  $display("!ERROR MAX_UWIDA_M16_CHECK Master %0d Outstanding Write requests %0d increased more than parameter AXI_MAX_UWIDA_M16 %0t",masterID,cnt_wr_trans_m,$time);
                end
                if(cnt_rd_trans_m > `AXI_MAX_URIDA_M16 + `AXI_AR_PL_ARB + `PL_BUF_AR) begin
                  $display("!ERROR MAX_URIDA_M16_CHECK Master %0d Outstanding Read requests %0d increased more than parameter AXI_MAX_URIDA_M16 %0t",masterID,cnt_rd_trans_m,$time);
                end
              end
              `endif
            end

            if(rca_wca_test == 1) begin
              `ifdef AXI_HAS_M1
              if(masterID == 1) begin
                if(cnt_wr_trans_m > `AXI_MAX_WCA_ID_M1 + `AXI_AW_PL_ARB + `PL_BUF_AW) begin
                  $display("!ERROR MAX_WCA_ID_M1_CHECK Master %0d Outstanding Write requests %0d increased more than parameter AXI_MAX_WCA_ID_M1 %0t",masterID,cnt_wr_trans_m,$time);
                end
                if(cnt_rd_trans_m > `AXI_MAX_RCA_ID_M1 + `AXI_AR_PL_ARB + `PL_BUF_AR) begin
                  $display("!ERROR MAX_RCA_ID_M1_CHECK Master %0d Outstanding Read requests %0d increased more than parameter AXI_MAX_RCA_ID_M1 %0t",masterID,cnt_rd_trans_m,$time);
                end
              end
              `endif
              `ifdef AXI_HAS_M2
              if(masterID == 2) begin
                if(cnt_wr_trans_m > `AXI_MAX_WCA_ID_M2 + `AXI_AW_PL_ARB + `PL_BUF_AW) begin
                  $display("!ERROR MAX_WCA_ID_M2_CHECK Master %0d Outstanding Write requests %0d increased more than parameter AXI_MAX_WCA_ID_M2 %0t",masterID,cnt_wr_trans_m,$time);
                end
                if(cnt_rd_trans_m > `AXI_MAX_RCA_ID_M2 + `AXI_AR_PL_ARB + `PL_BUF_AR) begin
                  $display("!ERROR MAX_RCA_ID_M2_CHECK Master %0d Outstanding Read requests %0d increased more than parameter AXI_MAX_RCA_ID_M2 %0t",masterID,cnt_rd_trans_m,$time);
                end
              end
              `endif
              `ifdef AXI_HAS_M3
              if(masterID == 3) begin
                if(cnt_wr_trans_m > `AXI_MAX_WCA_ID_M3 + `AXI_AW_PL_ARB + `PL_BUF_AW) begin
                  $display("!ERROR MAX_WCA_ID_M3_CHECK Master %0d Outstanding Write requests %0d increased more than parameter AXI_MAX_WCA_ID_M3 %0t",masterID,cnt_wr_trans_m,$time);
                end
                if(cnt_rd_trans_m > `AXI_MAX_RCA_ID_M3 + `AXI_AR_PL_ARB + `PL_BUF_AR) begin
                  $display("!ERROR MAX_RCA_ID_M3_CHECK Master %0d Outstanding Read requests %0d increased more than parameter AXI_MAX_RCA_ID_M3 %0t",masterID,cnt_rd_trans_m,$time);
                end
              end
              `endif
              `ifdef AXI_HAS_M4
              if(masterID == 4) begin
                if(cnt_wr_trans_m > `AXI_MAX_WCA_ID_M4 + `AXI_AW_PL_ARB + `PL_BUF_AW) begin
                  $display("!ERROR MAX_WCA_ID_M4_CHECK Master %0d Outstanding Write requests %0d increased more than parameter AXI_MAX_WCA_ID_M4 %0t",masterID,cnt_wr_trans_m,$time);
                end
                if(cnt_rd_trans_m > `AXI_MAX_RCA_ID_M4 + `AXI_AR_PL_ARB + `PL_BUF_AR) begin
                  $display("!ERROR MAX_RCA_ID_M4_CHECK Master %0d Outstanding Read requests %0d increased more than parameter AXI_MAX_RCA_ID_M4 %0t",masterID,cnt_rd_trans_m,$time);
                end
              end
              `endif
               `ifdef AXI_HAS_M5
              if(masterID == 5) begin
                if(cnt_wr_trans_m > `AXI_MAX_WCA_ID_M5 + `AXI_AW_PL_ARB + `PL_BUF_AW) begin
                  $display("!ERROR MAX_WCA_ID_M5_CHECK Master %0d Outstanding Write requests %0d increased more than parameter AXI_MAX_WCA_ID_M5 %0t",masterID,cnt_wr_trans_m,$time);
                end
                if(cnt_rd_trans_m > `AXI_MAX_RCA_ID_M5 + `AXI_AR_PL_ARB + `PL_BUF_AR) begin
                  $display("!ERROR MAX_RCA_ID_M5_CHECK Master %0d Outstanding Read requests %0d increased more than parameter AXI_MAX_RCA_ID_M5 %0t",masterID,cnt_rd_trans_m,$time);
                end
              end
              `endif
              `ifdef AXI_HAS_M6
              if(masterID == 6) begin
                if(cnt_wr_trans_m > `AXI_MAX_WCA_ID_M6 + `AXI_AW_PL_ARB + `PL_BUF_AW) begin
                  $display("!ERROR MAX_WCA_ID_M6_CHECK Master %0d Outstanding Write requests %0d increased more than parameter AXI_MAX_WCA_ID_M6 %0t",masterID,cnt_wr_trans_m,$time);
                end
                if(cnt_rd_trans_m > `AXI_MAX_RCA_ID_M6 + `AXI_AR_PL_ARB + `PL_BUF_AR) begin
                  $display("!ERROR MAX_RCA_ID_M6_CHECK Master %0d Outstanding Read requests %0d increased more than parameter AXI_MAX_RCA_ID_M6 %0t",masterID,cnt_rd_trans_m,$time);
                end
              end
              `endif
              `ifdef AXI_HAS_M7
              if(masterID == 7) begin
                if(cnt_wr_trans_m > `AXI_MAX_WCA_ID_M7 + `AXI_AW_PL_ARB + `PL_BUF_AW) begin
                  $display("!ERROR MAX_WCA_ID_M7_CHECK Master %0d Outstanding Write requests %0d increased more than parameter AXI_MAX_WCA_ID_M7 %0t",masterID,cnt_wr_trans_m,$time);
                end
                if(cnt_rd_trans_m > `AXI_MAX_RCA_ID_M7 + `AXI_AR_PL_ARB + `PL_BUF_AR) begin
                  $display("!ERROR MAX_RCA_ID_M7_CHECK Master %0d Outstanding Read requests %0d increased more than parameter AXI_MAX_RCA_ID_M7 %0t",masterID,cnt_rd_trans_m,$time);
                end
              end
              `endif
              `ifdef AXI_HAS_M8
              if(masterID == 8) begin
                if(cnt_wr_trans_m > `AXI_MAX_WCA_ID_M8 + `AXI_AW_PL_ARB + `PL_BUF_AW) begin
                  $display("!ERROR MAX_WCA_ID_M8_CHECK Master %0d Outstanding Write requests %0d increased more than parameter AXI_MAX_WCA_ID_M8 %0t",masterID,cnt_wr_trans_m,$time);
                end
                if(cnt_rd_trans_m > `AXI_MAX_RCA_ID_M8 + `AXI_AR_PL_ARB + `PL_BUF_AR) begin
                  $display("!ERROR MAX_RCA_ID_M8_CHECK Master %0d Outstanding Read requests %0d increased more than parameter AXI_MAX_RCA_ID_M8 %0t",masterID,cnt_rd_trans_m,$time);
                end
              end
              `endif
              `ifdef AXI_HAS_M9
              if(masterID == 9) begin
                if(cnt_wr_trans_m > `AXI_MAX_WCA_ID_M9 + `AXI_AW_PL_ARB + `PL_BUF_AW) begin
                  $display("!ERROR MAX_WCA_ID_M9_CHECK Master %0d Outstanding Write requests %0d increased more than parameter AXI_MAX_WCA_ID_M9 %0t",masterID,cnt_wr_trans_m,$time);
                end
                if(cnt_rd_trans_m > `AXI_MAX_RCA_ID_M9 + `AXI_AR_PL_ARB + `PL_BUF_AR) begin
                  $display("!ERROR MAX_RCA_ID_M9_CHECK Master %0d Outstanding Read requests %0d increased more than parameter AXI_MAX_RCA_ID_M9 %0t",masterID,cnt_rd_trans_m,$time);
                end
              end
              `endif
              `ifdef AXI_HAS_M10
              if(masterID == 10) begin
                if(cnt_wr_trans_m > `AXI_MAX_WCA_ID_M10 + `AXI_AW_PL_ARB + `PL_BUF_AW) begin
                  $display("!ERROR MAX_WCA_ID_M10_CHECK Master %0d Outstanding Write requests %0d increased more than parameter AXI_MAX_WCA_ID_M10 %0t",masterID,cnt_wr_trans_m,$time);
                end
                if(cnt_rd_trans_m > `AXI_MAX_RCA_ID_M10 + `AXI_AR_PL_ARB + `PL_BUF_AR) begin
                  $display("!ERROR MAX_RCA_ID_M10_CHECK Master %0d Outstanding Read requests %0d increased more than parameter AXI_MAX_RCA_ID_M10 %0t",masterID,cnt_rd_trans_m,$time);
                end
              end
              `endif
              `ifdef AXI_HAS_M11
              if(masterID == 11) begin
                if(cnt_wr_trans_m > `AXI_MAX_WCA_ID_M11 + `AXI_AW_PL_ARB + `PL_BUF_AW) begin
                  $display("!ERROR MAX_WCA_ID_M11_CHECK Master %0d Outstanding Write requests %0d increased more than parameter AXI_MAX_WCA_ID_M11 %0t",masterID,cnt_wr_trans_m,$time);
                end
                if(cnt_rd_trans_m > `AXI_MAX_RCA_ID_M11 + `AXI_AR_PL_ARB + `PL_BUF_AR) begin
                  $display("!ERROR MAX_RCA_ID_M11_CHECK Master %0d Outstanding Read requests %0d increased more than parameter AXI_MAX_RCA_ID_M11 %0t",masterID,cnt_rd_trans_m,$time);
                end
              end
              `endif
              `ifdef AXI_HAS_M12
              if(masterID == 12) begin
                if(cnt_wr_trans_m > `AXI_MAX_WCA_ID_M12 + `AXI_AW_PL_ARB + `PL_BUF_AW) begin
                  $display("!ERROR MAX_WCA_ID_M12_CHECK Master %0d Outstanding Write requests %0d increased more than parameter AXI_MAX_WCA_ID_M12 %0t",masterID,cnt_wr_trans_m,$time);
                end
                if(cnt_rd_trans_m > `AXI_MAX_RCA_ID_M12 + `AXI_AR_PL_ARB + `PL_BUF_AR) begin
                  $display("!ERROR MAX_RCA_ID_M12_CHECK Master %0d Outstanding Read requests %0d increased more than parameter AXI_MAX_RCA_ID_M12 %0t",masterID,cnt_rd_trans_m,$time);
                end
              end
              `endif
              `ifdef AXI_HAS_M13
              if(masterID == 13) begin
                if(cnt_wr_trans_m > `AXI_MAX_WCA_ID_M13 + `AXI_AW_PL_ARB + `PL_BUF_AW) begin
                  $display("!ERROR MAX_WCA_ID_M13_CHECK Master %0d Outstanding Write requests %0d increased more than parameter AXI_MAX_WCA_ID_M13 %0t",masterID,cnt_wr_trans_m,$time);
                end
                if(cnt_rd_trans_m > `AXI_MAX_RCA_ID_M13 + `AXI_AR_PL_ARB + `PL_BUF_AR) begin
                  $display("!ERROR MAX_RCA_ID_M13_CHECK Master %0d Outstanding Read requests %0d increased more than parameter AXI_MAX_RCA_ID_M13 %0t",masterID,cnt_rd_trans_m,$time);
                end
              end
              `endif
              `ifdef AXI_HAS_M14
              if(masterID == 14) begin
                if(cnt_wr_trans_m > `AXI_MAX_WCA_ID_M14 + `AXI_AW_PL_ARB + `PL_BUF_AW) begin
                  $display("!ERROR MAX_WCA_ID_M14_CHECK Master %0d Outstanding Write requests %0d increased more than parameter AXI_MAX_WCA_ID_M14 %0t",masterID,cnt_wr_trans_m,$time);
                end
                if(cnt_rd_trans_m > `AXI_MAX_RCA_ID_M14 + `AXI_AR_PL_ARB + `PL_BUF_AR) begin
                  $display("!ERROR MAX_RCA_ID_M14_CHECK Master %0d Outstanding Read requests %0d increased more than parameter AXI_MAX_RCA_ID_M14 %0t",masterID,cnt_rd_trans_m,$time);
                end
              end
              `endif
               `ifdef AXI_HAS_M15
              if(masterID == 15) begin
                if(cnt_wr_trans_m > `AXI_MAX_WCA_ID_M15 + `AXI_AW_PL_ARB + `PL_BUF_AW) begin
                  $display("!ERROR MAX_WCA_ID_M15_CHECK Master %0d Outstanding Write requests %0d increased more than parameter AXI_MAX_WCA_ID_M15 %0t",masterID,cnt_wr_trans_m,$time);
                end
                if(cnt_rd_trans_m > `AXI_MAX_RCA_ID_M15 + `AXI_AR_PL_ARB + `PL_BUF_AR) begin
                  $display("!ERROR MAX_RCA_ID_M15_CHECK Master %0d Outstanding Read requests %0d increased more than parameter AXI_MAX_RCA_ID_M15 %0t",masterID,cnt_rd_trans_m,$time);
                end
              end
              `endif
              `ifdef AXI_HAS_M16
              if(masterID == 16) begin
                if(cnt_wr_trans_m > `AXI_MAX_WCA_ID_M16 + `AXI_AW_PL_ARB + `PL_BUF_AW) begin
                  $display("!ERROR MAX_WCA_ID_M16_CHECK Master %0d Outstanding Write requests %0d increased more than parameter AXI_MAX_WCA_ID_M16 %0t",masterID,cnt_wr_trans_m,$time);
                end
                if(cnt_rd_trans_m > `AXI_MAX_RCA_ID_M16 + `AXI_AR_PL_ARB + `PL_BUF_AR) begin
                  $display("!ERROR MAX_RCA_ID_M16_CHECK Master %0d Outstanding Read requests %0d increased more than parameter AXI_MAX_RCA_ID_M16 %0t",masterID,cnt_rd_trans_m,$time);
                end
              end
              `endif
            end
          end
      end // while (1) begin
    end : check_outstanding_req
    join_none
  end
endtask : check_arida_awida_param

/**
   Method: check_farc_fawc_param
   1. Used to verify forwarding limit parameter for each slave
   2. Method contains 2 counter each for read and write req
   3. Write counter increase when there is awvalid and awready signal high on secondary port
      and decrease when there is bvalid and bready signal high on secondary port.
  */
task automatic check_farc_fawc_param;
  input [31:0] slaveID;
  begin
    fork 
    begin : check_outstanding_req
      reg     [31:0]         cnt_wr_trans_s = 0;
      reg     [31:0]         cnt_rd_trans_s = 0;
    
      while (1) begin
        @(posedge `TOP.aclk);
          if(outstanding_check_en) begin
            if(`AXI_NUM_MASTERS > 1 || `AXI_MAX_FAC_EN == 1) begin
              if (awvalid_s_bus[slaveID-1] && awready_s_bus[slaveID-1]) begin
                cnt_wr_trans_s = cnt_wr_trans_s + 1; 
              end
              if (bvalid_s_bus[slaveID-1] && bready_s_bus[slaveID-1]) begin
                cnt_wr_trans_s = cnt_wr_trans_s - 1; 
              end
              if (arvalid_s_bus[slaveID-1] && arready_s_bus[slaveID-1]) begin
                cnt_rd_trans_s = cnt_rd_trans_s + 1; 
              end
              if (rvalid_s_bus[slaveID-1] && rready_s_bus[slaveID-1] && rlast_s_bus[slaveID-1]) begin
                cnt_rd_trans_s = cnt_rd_trans_s - 1; 
              end
              if(fawc_farc_test == 1) begin
                `ifdef AXI_HAS_S1
                if(slaveID == 1 && `AXI_NMV_S1 >1 ) begin
                  if(cnt_wr_trans_s > `AXI_MAX_FAWC_S1) begin
                    $display("!ERROR MAX_FAWC_S1_CHECK Slave %0d Outstanding Write requests %0d increased more than parameter AXI_MAX_FAWC_S1 %0t",slaveID,cnt_wr_trans_s,$time);
                  end
                  if(cnt_rd_trans_s > `AXI_MAX_FARC_S1) begin
                    $display("!ERROR MAX_FARC_S1_CHECK Slave %0d Outstanding Read requests %0d increased more than parameter AXI_MAX_FARC_S1 %0t",slaveID,cnt_rd_trans_s,$time);
                  end
                end
                `endif
                `ifdef AXI_HAS_S2
                if(slaveID == 2 && `AXI_NMV_S2 >1) begin
                  if(cnt_wr_trans_s > `AXI_MAX_FAWC_S2) begin
                    $display("!ERROR MAX_FAWC_S2_CHECK Slave %0d Outstanding Write requests %0d increased more than parameter AXI_MAX_FAWC_S2 %0t",slaveID,cnt_wr_trans_s,$time);
                  end
                  if(cnt_rd_trans_s > `AXI_MAX_FARC_S2) begin
                    $display("!ERROR MAX_FARC_S2_CHECK Slave %0d Outstanding Read requests %0d increased more than parameter AXI_MAX_FARC_S2 %0t",slaveID,cnt_rd_trans_s,$time);
                  end
                end
                `endif
                `ifdef AXI_HAS_S3
                if(slaveID == 3 && `AXI_NMV_S3 >1) begin
                  if(cnt_wr_trans_s > `AXI_MAX_FAWC_S3) begin
                    $display("!ERROR MAX_FAWC_S3_CHECK Slave %0d Outstanding Write requests %0d increased more than parameter AXI_MAX_FAWC_S3 %0t",slaveID,cnt_wr_trans_s,$time);
                  end
                  if(cnt_rd_trans_s > `AXI_MAX_FARC_S3) begin
                    $display("!ERROR MAX_FARC_S3_CHECK Slave %0d Outstanding Read requests %0d increased more than parameter AXI_MAX_FARC_S3 %0t",slaveID,cnt_rd_trans_s,$time);
                  end
                end
                `endif
                `ifdef AXI_HAS_S4
                if(slaveID == 4 && `AXI_NMV_S4 >1 ) begin
                  if(cnt_wr_trans_s > `AXI_MAX_FAWC_S4) begin
                    $display("!ERROR MAX_FAWC_S4_CHECK Slave %0d Outstanding Write requests %0d increased more than parameter AXI_MAX_FAWC_S4 %0t",slaveID,cnt_wr_trans_s,$time);
                  end
                  if(cnt_rd_trans_s > `AXI_MAX_FARC_S4) begin
                    $display("!ERROR MAX_FARC_S4_CHECK Slave %0d Outstanding Read requests %0d increased more than parameter AXI_MAX_FARC_S4 %0t",slaveID,cnt_rd_trans_s,$time);
                  end
                end
                `endif
                `ifdef AXI_HAS_S5
                if(slaveID == 5 && `AXI_NMV_S5 >1 ) begin
                  if(cnt_wr_trans_s > `AXI_MAX_FAWC_S5) begin
                    $display("!ERROR MAX_FAWC_S5_CHECK Slave %0d Outstanding Write requests %0d increased more than parameter AXI_MAX_FAWC_S5 %0t",slaveID,cnt_wr_trans_s,$time);
                  end
                  if(cnt_rd_trans_s > `AXI_MAX_FARC_S5) begin
                    $display("!ERROR MAX_FARC_S5_CHECK Slave %0d Outstanding Read requests %0d increased more than parameter AXI_MAX_FARC_S5 %0t",slaveID,cnt_rd_trans_s,$time);
                  end
                end
                `endif
                 `ifdef AXI_HAS_S6
                if(slaveID == 6 && `AXI_NMV_S6 >1) begin
                  if(cnt_wr_trans_s > `AXI_MAX_FAWC_S6) begin
                    $display("!ERROR MAX_FAWC_S6_CHECK Slave %0d Outstanding Write requests %0d increased more than parameter AXI_MAX_FAWC_S6 %0t",slaveID,cnt_wr_trans_s,$time);
                  end
                  if(cnt_rd_trans_s > `AXI_MAX_FARC_S6) begin
                    $display("!ERROR MAX_FARC_S6_CHECK Slave %0d Outstanding Read requests %0d increased more than parameter AXI_MAX_FARC_S6 %0t",slaveID,cnt_rd_trans_s,$time);
                  end
                end
                `endif
                `ifdef AXI_HAS_S7
                if(slaveID == 7 && `AXI_NMV_S7 >1) begin
                  if(cnt_wr_trans_s > `AXI_MAX_FAWC_S7) begin
                    $display("!ERROR MAX_FAWC_S7_CHECK Slave %0d Outstanding Write requests %0d increased more than parameter AXI_MAX_FAWC_S7 %0t",slaveID,cnt_wr_trans_s,$time);
                  end
                  if(cnt_rd_trans_s > `AXI_MAX_FARC_S7) begin
                    $display("!ERROR MAX_FARC_S7_CHECK Slave %0d Outstanding Read requests %0d increased more than parameter AXI_MAX_FARC_S7 %0t",slaveID,cnt_rd_trans_s,$time);
                  end
                end
                `endif
                 `ifdef AXI_HAS_S8
                if(slaveID == 8 && `AXI_NMV_S8 >1) begin
                  if(cnt_wr_trans_s > `AXI_MAX_FAWC_S8) begin
                    $display("!ERROR MAX_FAWC_S8_CHECK Slave %0d Outstanding Write requests %0d increased more than parameter AXI_MAX_FAWC_S8 %0t",slaveID,cnt_wr_trans_s,$time);
                  end
                  if(cnt_rd_trans_s > `AXI_MAX_FARC_S8) begin
                    $display("!ERROR MAX_FARC_S8_CHECK Slave %0d Outstanding Read requests %0d increased more than parameter AXI_MAX_FARC_S8 %0t",slaveID,cnt_rd_trans_s,$time);
                  end
                end
                `endif
                `ifdef AXI_HAS_S9
                if(slaveID == 9 && `AXI_NMV_S9 >1) begin
                  if(cnt_wr_trans_s > `AXI_MAX_FAWC_S9) begin
                    $display("!ERROR MAX_FAWC_S9_CHECK Slave %0d Outstanding Write requests %0d increased more than parameter AXI_MAX_FAWC_S9 %0t",slaveID,cnt_wr_trans_s,$time);
                  end
                  if(cnt_rd_trans_s > `AXI_MAX_FARC_S9) begin
                    $display("!ERROR MAX_FARC_S9_CHECK Slave %0d Outstanding Read requests %0d increased more than parameter AXI_MAX_FARC_S9 %0t",slaveID,cnt_rd_trans_s,$time);
                  end
                end
                `endif
                `ifdef AXI_HAS_S10
                if(slaveID == 10 && `AXI_NMV_S10 >1) begin
                  if(cnt_wr_trans_s > `AXI_MAX_FAWC_S10) begin
                    $display("!ERROR MAX_FAWC_S10_CHECK Slave %0d Outstanding Write requests %0d increased more than parameter AXI_MAX_FAWC_S10 %0t",slaveID,cnt_wr_trans_s,$time);
                  end
                  if(cnt_rd_trans_s > `AXI_MAX_FARC_S10) begin
                    $display("!ERROR MAX_FARC_S10_CHECK Slave %0d Outstanding Read requests %0d increased more than parameter AXI_MAX_FARC_S10 %0t",slaveID,cnt_rd_trans_s,$time);
                  end
                end
                `endif
                `ifdef AXI_HAS_S11
                if(slaveID == 11 && `AXI_NMV_S11 >1 ) begin
                  if(cnt_wr_trans_s > `AXI_MAX_FAWC_S11) begin
                    $display("!ERROR MAX_FAWC_S11_CHECK Slave %0d Outstanding Write requests %0d increased more than parameter AXI_MAX_FAWC_S11 %0t",slaveID,cnt_wr_trans_s,$time);
                  end
                  if(cnt_rd_trans_s > `AXI_MAX_FARC_S11) begin
                    $display("!ERROR MAX_FARC_S11_CHECK Slave %0d Outstanding Read requests %0d increased more than parameter AXI_MAX_FARC_S11 %0t",slaveID,cnt_rd_trans_s,$time);
                  end
                end
                `endif
                `ifdef AXI_HAS_S12
                if(slaveID == 12 && `AXI_NMV_S12 >1) begin
                  if(cnt_wr_trans_s > `AXI_MAX_FAWC_S12) begin
                    $display("!ERROR MAX_FAWC_S12_CHECK Slave %0d Outstanding Write requests %0d increased more than parameter AXI_MAX_FAWC_S12 %0t",slaveID,cnt_wr_trans_s,$time);
                  end
                  if(cnt_rd_trans_s > `AXI_MAX_FARC_S12) begin
                    $display("!ERROR MAX_FARC_S12_CHECK Slave %0d Outstanding Read requests %0d increased more than parameter AXI_MAX_FARC_S12 %0t",slaveID,cnt_rd_trans_s,$time);
                  end
                end
                `endif
                `ifdef AXI_HAS_S13
                if(slaveID == 13 &&  `AXI_NMV_S13 >1) begin
                  if(cnt_wr_trans_s > `AXI_MAX_FAWC_S13) begin
                    $display("!ERROR MAX_FAWC_S13_CHECK Slave %0d Outstanding Write requests %0d increased more than parameter AXI_MAX_FAWC_S13 %0t",slaveID,cnt_wr_trans_s,$time);
                  end
                  if(cnt_rd_trans_s > `AXI_MAX_FARC_S13) begin
                    $display("!ERROR MAX_FARC_S13_CHECK Slave %0d Outstanding Read requests %0d increased more than parameter AXI_MAX_FARC_S13 %0t",slaveID,cnt_rd_trans_s,$time);
                  end
                end
                `endif
                 `ifdef AXI_HAS_S14
                if(slaveID == 14 && `AXI_NMV_S14 >1) begin
                  if(cnt_wr_trans_s > `AXI_MAX_FAWC_S14) begin
                    $display("!ERROR MAX_FAWC_S14_CHECK Slave %0d Outstanding Write requests %0d increased more than parameter AXI_MAX_FAWC_S14 %0t",slaveID,cnt_wr_trans_s,$time);
                  end
                  if(cnt_rd_trans_s > `AXI_MAX_FARC_S14) begin
                    $display("!ERROR MAX_FARC_S14_CHECK Slave %0d Outstanding Read requests %0d increased more than parameter AXI_MAX_FARC_S14 %0t",slaveID,cnt_rd_trans_s,$time);
                  end
                end
                `endif
                `ifdef AXI_HAS_S15
                if(slaveID == 15 && `AXI_NMV_S15 >1) begin
                  if(cnt_wr_trans_s > `AXI_MAX_FAWC_S15) begin
                    $display("!ERROR MAX_FAWC_S15_CHECK Slave %0d Outstanding Write requests %0d increased more than parameter AXI_MAX_FAWC_S15 %0t",slaveID,cnt_wr_trans_s,$time);
                  end
                  if(cnt_rd_trans_s > `AXI_MAX_FARC_S15) begin
                    $display("!ERROR MAX_FARC_S15_CHECK Slave %0d Outstanding Read requests %0d increased more than parameter AXI_MAX_FARC_S15 %0t",slaveID,cnt_rd_trans_s,$time);
                  end
                end
                `endif
                 `ifdef AXI_HAS_S16
                if(slaveID == 16 && `AXI_NMV_S16 >1) begin
                  if(cnt_wr_trans_s > `AXI_MAX_FAWC_S16) begin
                    $display("!ERROR MAX_FAWC_S16_CHECK Slave %0d Outstanding Write requests %0d increased more than parameter AXI_MAX_FAWC_S16 %0t",slaveID,cnt_wr_trans_s,$time);
                  end
                  if(cnt_rd_trans_s > `AXI_MAX_FARC_S16) begin
                    $display("!ERROR MAX_FARC_S16_CHECK Slave %0d Outstanding Read requests %0d increased more than parameter AXI_MAX_FARC_S16 %0t",slaveID,cnt_rd_trans_s,$time);
                  end
                end
                `endif
              end
            end
          end
      end // while (1) begin
    end : check_outstanding_req
    join_none
  end
endtask : check_farc_fawc_param


// ------------------------------------------------------------------------------------------------------------------------------------

`ifdef AXI_HAS_VALID_READY_PAR_EN
/** 
  * Checker for the parity of valid and ready parity
  *   For ODD  - parity must be opposite of the associated valid/ready
  *   For EVEN - parity must be same as the associated valid/ready
  */
task automatic check_valid_ready_parity_signals;
  input       is_master;
  input [3:0] portID;

  begin
    while(1) begin
      @(posedge `TOP.aclk);
      `ifdef AXI_HAS_ODD_PARITY
      if (is_master) begin
        if (awvalid_m[portID] != ~awvalid_m_parity[portID]) begin
          $display("WARNING[%0t]: ODD Parity Mismatch on AW Channel: MasterID[%0d] FAIL : Received valid is %0d, expected valid_parity value %0d", $time, portID, awvalid_m[portID], awvalid_m_parity[portID]);
        end
        if (wvalid_m[portID] != ~wvalid_m_parity[portID]) begin
          $display("WARNING[%0t]: ODD Parity Mismatch on W Channel: MasterID[%0d] FAIL : Received valid is %0d, expected valid_parity value %0d", $time, portID, wvalid_m[portID], wvalid_m_parity[portID]);
        end
        if (arvalid_m[portID] != ~arvalid_m_parity[portID]) begin
          $display("WARNING[%0t]: ODD Parity Mismatch on AR Channel: MasterID[%0d] FAIL : Received valid is %0d, expected valid_parity value %0d", $time, portID, arvalid_m[portID], arvalid_m_parity[portID]);
        end
        if (rvalid_m[portID] != ~rvalid_m_parity[portID]) begin
          $display("ERROR[%0t]: ODD Parity Mismatch on R Channel: MasterID[%0d] FAIL : Received valid is %0d, expected valid_parity value %0d", $time, portID, rvalid_m[portID], rvalid_m_parity[portID]);
        end
        if (bvalid_m[portID] != ~bvalid_m_parity[portID]) begin
          $display("ERROR[%0t]: ODD Parity Mismatch on B Channel: MasterID[%0d] FAIL : Received valid is %0d, expected valid_parity value %0d", $time, portID, bvalid_m[portID], bvalid_m_parity[portID]);
        end

        if (awready_m[portID] != ~awready_m_parity[portID]) begin
          $display("ERROR[%0t]: ODD Parity Mismatch on AW Channel: MasterID[%0d] FAIL : Received ready is %0d, expected ready_parity value %0d", $time, portID, awready_m[portID], awready_m_parity[portID]);
        end
        if (wready_m[portID] != ~wready_m_parity[portID]) begin
          $display("ERROR[%0t]: ODD Parity Mismatch on W Channel: MasterID[%0d] FAIL : Received ready is %0d, expected ready_parity value %0d", $time, portID, wready_m[portID], wready_m_parity[portID]);
        end
        if (arready_m[portID] != ~arready_m_parity[portID]) begin
          $display("ERROR[%0t]: ODD Parity Mismatch on AR Channel: MasterID[%0d] FAIL : Received ready is %0d, expected ready_parity value %0d", $time, portID, arready_m[portID], arready_m_parity[portID]);
        end
        if (rready_m[portID] != ~rready_m_parity[portID]) begin
          $display("WARNING[%0t]: ODD Parity Mismatch on R Channel: MasterID[%0d] FAIL : Received ready is %0d, expected ready_parity value %0d", $time, portID, rready_m[portID], rready_m_parity[portID]);
        end
        if (bready_m[portID] != ~bready_m_parity[portID]) begin
          $display("WARNING[%0t]: ODD Parity Mismatch on B Channel: MasterID[%0d] FAIL : Received ready is %0d, expected ready_parity value %0d", $time, portID, bready_m[portID], bready_m_parity[portID]);
        end
      end
      else begin
        if (awvalid_s[portID] != ~awvalid_s_parity[portID]) begin
          $display("ERROR[%0t]: ODD Parity Mismatch on AW Channel: SlaveID[%0d] FAIL : Received valid is %0d, expected valid_parity value %0d", $time, portID, awvalid_s[portID], awvalid_s_parity[portID]);
        end
        if (wvalid_s[portID] != ~wvalid_s_parity[portID]) begin
          $display("ERROR[%0t]: ODD Parity Mismatch on W Channel: SlaveID[%0d] FAIL : Received valid is %0d, expected valid_parity value %0d", $time, portID, wvalid_s[portID], wvalid_s_parity[portID]);
        end
        if (arvalid_s[portID] != ~arvalid_s_parity[portID]) begin
          $display("ERROR[%0t]: ODD Parity Mismatch on AR Channel: SlaveID[%0d] FAIL : Received valid is %0d, expected valid_parity value %0d", $time, portID, arvalid_s[portID], arvalid_s_parity[portID]);
        end
        if (rvalid_s[portID] != ~rvalid_s_parity[portID]) begin
          $display("WARNING[%0t]: ODD Parity Mismatch on R Channel: SlaveID[%0d] FAIL : Received valid is %0d, expected valid_parity value %0d", $time, portID, rvalid_s[portID], rvalid_s_parity[portID]);
        end
        if (bvalid_s[portID] != ~bvalid_s_parity[portID]) begin
          $display("WARNING[%0t]: ODD Parity Mismatch on B Channel: SlaveID[%0d] FAIL : Received valid is %0d, expected valid_parity value %0d", $time, portID, bvalid_s[portID], bvalid_s_parity[portID]);
        end

        if (awready_s[portID] != ~awready_s_parity[portID]) begin
          $display("WARNING[%0t]: ODD Parity Mismatch on AW Channel: SlaveID[%0d] FAIL : Received ready is %0d, expected ready_parity value %0d", $time, portID, awready_s[portID], awready_s_parity[portID]);
        end
        if (wready_s[portID] != ~wready_s_parity[portID]) begin
          $display("WARNING[%0t]: ODD Parity Mismatch on W Channel: SlaveID[%0d] FAIL : Received ready is %0d, expected ready_parity value %0d", $time, portID, wready_s[portID], wready_s_parity[portID]);
        end
        if (arready_s[portID] != ~arready_s_parity[portID]) begin
          $display("WARNING[%0t]: ODD Parity Mismatch on AR Channel: SlaveID[%0d] FAIL : Received ready is %0d, expected ready_parity value %0d", $time, portID, arready_s[portID], arready_s_parity[portID]);
        end
        if (rready_s[portID] != ~rready_s_parity[portID]) begin
          $display("ERROR[%0t]: ODD Parity Mismatch on R Channel: SlaveID[%0d] FAIL : Received ready is %0d, expected ready_parity value %0d", $time, portID, rready_s[portID], rready_s_parity[portID]);
        end
        if (bready_s[portID] != ~bready_s_parity[portID]) begin
          $display("ERROR[%0t]: ODD Parity Mismatch on B Channel: SlaveID[%0d] FAIL : Received ready is %0d, expected ready_parity value %0d", $time, portID, bready_s[portID], bready_s_parity[portID]);
        end
      end
      `endif  //AXI_HAS_ODD_PARITY

      `ifdef AXI_HAS_EVEN_PARITY
      if (is_master) begin
        if (awvalid_m[portID] != awvalid_m_parity[portID]) begin
          $display("WARNING[%0t]: EVEN Parity Mismatch on AW Channel: MasterID[%0d] FAIL : Received valid is %0d, expected valid_parity value %0d", $time, portID, awvalid_m[portID], awvalid_m_parity[portID]);
        end
        if (wvalid_m[portID] != wvalid_m_parity[portID]) begin
          $display("WARNING[%0t]: EVEN Parity Mismatch on W Channel: MasterID[%0d] FAIL : Received valid is %0d, expected valid_parity value %0d", $time, portID, wvalid_m[portID], wvalid_m_parity[portID]);
        end
        if (arvalid_m[portID] != arvalid_m_parity[portID]) begin
          $display("WARNING[%0t]: EVEN Parity Mismatch on AR Channel: MasterID[%0d] FAIL : Received valid is %0d, expected valid_parity value %0d", $time, portID, arvalid_m[portID], arvalid_m_parity[portID]);
        end
        if (rvalid_m[portID] != rvalid_m_parity[portID]) begin
          $display("ERROR[%0t]: EVEN Parity Mismatch on R Channel: MasterID[%0d] FAIL : Received valid is %0d, expected valid_parity value %0d", $time, portID, rvalid_m[portID], rvalid_m_parity[portID]);
        end
        if (bvalid_m[portID] != bvalid_m_parity[portID]) begin
          $display("ERROR[%0t]: EVEN Parity Mismatch on B Channel: MasterID[%0d] FAIL : Received valid is %0d, expected valid_parity value %0d", $time, portID, bvalid_m[portID], bvalid_m_parity[portID]);
        end

        if (awready_m[portID] != awready_m_parity[portID]) begin
          $display("ERROR[%0t]: EVEN Parity Mismatch on AW Channel: MasterID[%0d] FAIL : Received ready is %0d, expected ready_parity value %0d", $time, portID, awready_m[portID], awready_m_parity[portID]);
        end
        if (wready_m[portID] != wready_m_parity[portID]) begin
          $display("ERROR[%0t]: EVEN Parity Mismatch on W Channel: MasterID[%0d] FAIL : Received ready is %0d, expected ready_parity value %0d", $time, portID, wready_m[portID], wready_m_parity[portID]);
        end
        if (arready_m[portID] != arready_m_parity[portID]) begin
          $display("ERROR[%0t]: EVEN Parity Mismatch on AR Channel: MasterID[%0d] FAIL : Received ready is %0d, expected ready_parity value %0d", $time, portID, arready_m[portID], arready_m_parity[portID]);
        end
        if (rready_m[portID] != rready_m_parity[portID]) begin
          $display("WARNING[%0t]: EVEN Parity Mismatch on R Channel: MasterID[%0d] FAIL : Received ready is %0d, expected ready_parity value %0d", $time, portID, rready_m[portID], rready_m_parity[portID]);
        end
        if (bready_m[portID] != bready_m_parity[portID]) begin
          $display("WARNING[%0t]: EVEN Parity Mismatch on B Channel: MasterID[%0d] FAIL : Received ready is %0d, expected ready_parity value %0d", $time, portID, bready_m[portID], bready_m_parity[portID]);
        end
      end
      else begin
        if (awvalid_s[portID] != awvalid_s_parity[portID]) begin
          $display("ERROR[%0t]: EVEN Parity Mismatch on AW Channel: SlaveID[%0d] FAIL : Received valid is %0d, expected valid_parity value %0d", $time, portID, awvalid_s[portID], awvalid_s_parity[portID]);
        end
        if (wvalid_s[portID] != wvalid_s_parity[portID]) begin
          $display("ERROR[%0t]: EVEN Parity Mismatch on W Channel: SlaveID[%0d] FAIL : Received valid is %0d, expected valid_parity value %0d", $time, portID, wvalid_s[portID], wvalid_s_parity[portID]);
        end
        if (arvalid_s[portID] != arvalid_s_parity[portID]) begin
          $display("ERROR[%0t]: EVEN Parity Mismatch on AR Channel: SlaveID[%0d] FAIL : Received valid is %0d, expected valid_parity value %0d", $time, portID, arvalid_s[portID], arvalid_s_parity[portID]);
        end
        if (rvalid_s[portID] != rvalid_s_parity[portID]) begin
          $display("WARNING[%0t]: EVEN Parity Mismatch on R Channel: SlaveID[%0d] FAIL : Received valid is %0d, expected valid_parity value %0d", $time, portID, rvalid_s[portID], rvalid_s_parity[portID]);
        end
        if (bvalid_s[portID] != bvalid_s_parity[portID]) begin
          $display("WARNING[%0t]: EVEN Parity Mismatch on B Channel: SlaveID[%0d] FAIL : Received valid is %0d, expected valid_parity value %0d", $time, portID, bvalid_s[portID], bvalid_s_parity[portID]);
        end

        if (awready_s[portID] != awready_s_parity[portID]) begin
          $display("WARNING[%0t]: EVEN Parity Mismatch on AW Channel: SlaveID[%0d] FAIL : Received ready is %0d, expected ready_parity value %0d", $time, portID, awready_s[portID], awready_s_parity[portID]);
        end
        if (wready_s[portID] != wready_s_parity[portID]) begin
          $display("WARNING[%0t]: EVEN Parity Mismatch on W Channel: SlaveID[%0d] FAIL : Received ready is %0d, expected ready_parity value %0d", $time, portID, wready_s[portID], wready_s_parity[portID]);
        end
        if (arready_s[portID] != arready_s_parity[portID]) begin
          $display("WARNING[%0t]: EVEN Parity Mismatch on AR Channel: SlaveID[%0d] FAIL : Received ready is %0d, expected ready_parity value %0d", $time, portID, arready_s[portID], arready_s_parity[portID]);
        end
        if (rready_s[portID] != rready_s_parity[portID]) begin
          $display("ERROR[%0t]: EVEN Parity Mismatch on R Channel: SlaveID[%0d] FAIL : Received ready is %0d, expected ready_parity value %0d", $time, portID, rready_s[portID], rready_s_parity[portID]);
        end
        if (bready_s[portID] != bready_s_parity[portID]) begin
          $display("ERROR[%0t]: EVEN Parity Mismatch on B Channel: SlaveID[%0d] FAIL : Received ready is %0d, expected ready_parity value %0d", $time, portID, bready_s[portID], bready_s_parity[portID]);
        end
      end
      `endif  //AXI_HAS_EVEN_PARITY

    end
  end
endtask : check_valid_ready_parity_signals

`endif //AXI_HAS_VALID_READY_PAR_EN

`ifdef SNPS_INTERNAL_ON
`ifdef AXI_QOS
// ------------------------------------------------------------------------------------------------------------------------------------
/** 
  * Checker for QoS priority arbitration
  * When AW/AR arb type value is 4
  */
//------------------------------------------------------------------------------------------------------------------------------------
task automatic check_qos_priority;
  reg [31:0]                                  SlaveId;
  reg [3:0]                                   awregion_actual,arregion_actual;
  reg [3:0]                                   awregion_expected,arregion_expected;
  reg [`AXI_AW-1:0]                           awaddr_tmp,araddr_tmp;
  reg [(`SVT_AXI_QOS_WIDTH+`AXI_LOG2_NM-1):0] awqos_id_mst_slv_q [`AXI_NUM_MASTERS] [`AXI_NUM_SLAVES] [$] ;
  reg [(`SVT_AXI_QOS_WIDTH+`AXI_LOG2_NM-1):0] arqos_id_mst_slv_q [`AXI_NUM_MASTERS] [`AXI_NUM_SLAVES] [$] ;
  reg [(`SVT_AXI_QOS_WIDTH-1):0]              awqos_pop_val;
  reg [(`SVT_AXI_QOS_WIDTH-1):0]              arqos_pop_val;
  reg [(`AXI_LOG2_NM-1):0]                    awmid_pop_val;
  reg [(`AXI_LOG2_NM-1):0]                    armid_pop_val;
  reg [(`SVT_AXI_QOS_WIDTH+`AXI_LOG2_NM-1):0] awqos_id_push_val;
  reg [(`SVT_AXI_QOS_WIDTH+`AXI_LOG2_NM-1):0] arqos_id_push_val;
  
  reg [`AXI_LOG2_NM-1:0]                      awmngr_id='h0;
  reg [`AXI_LOG2_NM-1:0]                      actual_awid='h0;
  reg [`AXI_LOG2_NM-1:0]                      armngr_id;

  // For AW channel
  reg [`SVT_AXI_MAX_ID_WIDTH-1:0]             issued_awmngr_id ='h0;
  reg [`SVT_AXI_QOS_WIDTH-1:0]                issued_awqos='h0;
  reg [`SVT_AXI_QOS_WIDTH-1:0]                actual_awqos='h0;
  reg [`SVT_AXI_QOS_WIDTH-1:0]                pop_issued_awqos;
  reg [`SVT_AXI_QOS_WIDTH-1:0]                pop_expected_awqos;
  reg [`SVT_AXI_MAX_ID_WIDTH-1:0]             pop_issued_awid;
  reg [`SVT_AXI_MAX_ID_WIDTH-1:0]             pop_expected_awid;
  reg [`SVT_AXI_QOS_WIDTH-1:0]                awqos_slv_sp_q[`AXI_NUM_SLAVES:1] [$];
  reg [`AXI_LOG2_NM:0]                        awid_slv_sp_q[`AXI_NUM_SLAVES:1] [$]; 
  reg [`SVT_AXI_QOS_WIDTH-1:0]                awqos_mst_slv_q[`AXI_NUM_SLAVES:1] [$];
  reg [`AXI_LOG2_NM-1:0]                      awid_mst_slv_q[`AXI_NUM_SLAVES:1] [$];

  //For AR Channel
  reg [`SVT_AXI_MAX_ID_WIDTH-1:0]             issued_armngr_id= 'h0;
  reg [`SVT_AXI_QOS_WIDTH-1:0]                issued_arqos='h0;
  reg [`SVT_AXI_QOS_WIDTH-1:0]                actual_arqos='h0;
  reg [`SVT_AXI_QOS_WIDTH-1:0]                pop_issued_arqos;
  reg [`SVT_AXI_QOS_WIDTH-1:0]                pop_expected_arqos;
  reg [`SVT_AXI_MAX_ID_WIDTH-1:0]             pop_issued_arid;
  reg [`SVT_AXI_MAX_ID_WIDTH-1:0]             pop_expected_arid;
  reg [`SVT_AXI_QOS_WIDTH-1:0]                arqos_slv_sp_q[`AXI_NUM_SLAVES:1] [$];
  reg [`AXI_LOG2_NM:0]                        arid_slv_sp_q[`AXI_NUM_SLAVES:1] [$]; 
  reg [`SVT_AXI_QOS_WIDTH-1:0]                arqos_mst_slv_q[`AXI_NUM_SLAVES:1] [$];
  reg [`AXI_LOG2_NM-1:0]                      arid_mst_slv_q[`AXI_NUM_SLAVES:1] [$];
  
  // post-pop
  reg                                         pop_arqos_completed[`AXI_NUM_SLAVES:1];
  reg                                         pop_arid_completed[`AXI_NUM_SLAVES:1];
  // post-pop
  reg                                         pop_awqos_completed[`AXI_NUM_SLAVES:1];
  reg                                         pop_awid_completed[`AXI_NUM_SLAVES:1];

  reg [`AXI_AW-1:0]                           awaddr;
  reg [`AXI_AW-1:0]                           araddr;
  reg [`SVT_AXI_QOS_WIDTH-1:0]                awqos;
  reg [`SVT_AXI_QOS_WIDTH-1:0]                arqos;
  reg                                         is_valid_wr_m[`AXI_NUM_MASTERS:0];
  reg                                         is_valid_wr_s[`AXI_NUM_SLAVES:0];
  reg                                         is_valid_rd_m[`AXI_NUM_MASTERS:0];
  reg                                         is_valid_rd_s[`AXI_NUM_SLAVES:0];
  
  integer                                     i,mngr,mst;
  integer                                     callback_handle_wr_m[`AXI_NUM_MASTERS:0];
  integer                                     callback_handle_wr_s[`AXI_NUM_SLAVES:0];
  integer                                     callback_handle_rd_m[`AXI_NUM_MASTERS:0];
  integer                                     callback_handle_rd_s[`AXI_NUM_SLAVES:0];

  logic [`SVT_AXI_QOS_WIDTH-1:0]              highest_priority = 'h0;
  logic [`SVT_AXI_QOS_WIDTH-1:0]              prev_highest_priority = 'h0;
  logic [`AXI_NUM_MASTERS:0]                  highest_priority_master = 4'h0;
  logic [`AXI_NUM_MASTERS:0]                  prev_highest_priority_master = 4'h0;
  logic [`AXI_NUM_MASTERS:0]                  prev_awid = 'h0;
  logic [`SVT_AXI_QOS_WIDTH-1:0]              prev_awqos = 'h0;
  logic [`AXI_NUM_MASTERS:0]                  prev_arid = 'h0;
  logic [`SVT_AXI_QOS_WIDTH-1:0]              prev_arqos = 'h0;

  reg [`AXI_LOG2_NM:0]                        visible_masters_q[`AXI_NUM_SLAVES:1] [$];  
  integer                                     mstid,slvid,i;
  bit                                         valid_aw_qos_id_values = 'h0;
  bit                                         valid_ar_qos_id_values = 'h0;

//Store the Visible masters for a particular slave 
begin
  for (mstid = 1; mstid <= `AXI_NUM_MASTERS; mstid++) begin
    for(slvid = 1; slvid <= `AXI_NUM_SLAVES; slvid++ ) begin
      if (visible_slaves[mstid][slvid] == 1) begin
          visible_masters_q[slvid].push_back(mstid);
          $display("@%0t,Visible masters[%0d]=%0p",$time,slvid,visible_masters_q); 
          end
      end
  end
end

begin
  /*if (test_debug) */$display("@%0t [TB_DEBUG] {%m} : Calling check_qos_priority\n",$time);
  fork

// To calculate the start of qos tests
  begin 
   for (i=1;i<=`AXI_NUM_SLAVES;i++) begin
    fork
    automatic integer slv_no = i;
     wait_for_awqos_arb_start_on_slv (slv_no);
     wait_for_arqos_arb_start_on_slv (slv_no); 
    join_none
   end    
  end

  `ifndef AXI_AW_SHARED_LAYER
  //============================
  // Write Address Channel
  //============================

  begin //Write Address channel - Subordinate port
    for (i=1;i<=`AXI_NUM_SLAVES;i++) begin : loop_aws
      fork
      automatic integer awsub_id = i;
      begin : fork_aws
        while (1) begin
         @(negedge `TOP.aclk);
         wait (qos_arb_check_en == 1); 
          if (slv_port_awready[awsub_id] && slv_port_awvalid[awsub_id] && (!aw_shared_en[awsub_id])) begin
           issued_awqos=slv_port_awqos[awsub_id];
           issued_awmngr_id=slv_port_awid[awsub_id];
           $display("@%0t,SLAVE PORT AWQOS when awvalid and awready is asserted for slave[%0h]=%0h",$time,awsub_id,issued_awqos);
           $display("@%0t,SLAVE PORT AWID when awvalid and awready is asserted for slave[%0h]=%0h",$time,awsub_id,issued_awmngr_id);
           awqos_mst_slv_q[awsub_id].push_back(issued_awqos);
           awid_mst_slv_q[awsub_id].push_back(issued_awmngr_id);
           $display("@%0t,displaying AWqos queue of slv port [%0h]=%0p",$time,awsub_id,awqos_mst_slv_q);
           $display("@%0t,displaying AWid queue of slv port [%0h]=%0p",$time,awsub_id,awid_mst_slv_q); end
        end
      end  
      join_none
    end //loop_aws 
  end //Write Address channel - Subordinate port

  begin // Write Address channel From DW_axi_SP module
    for (i=1;i<=`AXI_NUM_SLAVES;i++) begin 
      fork
      automatic integer aw_pre_arb = i;
      begin 
        while (1) begin
          @(negedge `TOP.aclk);
          if(qos_arb_check_en && qos_awarb_chk_en_s[aw_pre_arb] && (!aw_shared_en[aw_pre_arb])) begin
            highest_priority = 4'h0;
            valid_aw_qos_id_values = 'h0;
            for(int j=1;j<=`AXI_NUM_MASTERS;j++) begin
               if ((bus_awvalid_i[aw_pre_arb][j-1] == 1) && ((bus_awqos_i[aw_pre_arb][(j-1)*4 +: 4]) > (highest_priority)))  begin
                highest_priority_master = j;
                highest_priority=bus_awqos_i[aw_pre_arb][(j-1)*4 +: 4];
                valid_aw_qos_id_values = 1;
                $display("@%0t, Calculated (Expected) for slave on AW Channel =%0h highest_priority_master=%0h,highest_priority=%0h",$time,aw_pre_arb,highest_priority_master,highest_priority);
               end
                else if (bus_awqos_i[aw_pre_arb][(j-1)*4 +: 4] == bus_awqos_i[aw_pre_arb][(highest_priority_master-1)*4 +: 4] && (j < highest_priority_master) && bus_awvalid_i[aw_pre_arb][j-1] == 1) begin
                highest_priority_master = j;
                highest_priority=bus_awqos_i[aw_pre_arb][(j-1)*4 +: 4];
                valid_aw_qos_id_values = 1;
                $display("@%0t,Calculated for slave on AW channel =%0h for Equal priority highest_priority_master=%0h,highest_priority=%0h",$time,aw_pre_arb,highest_priority_master,highest_priority); 
               end
            end // for-loop
          
            for (mst=1;mst<=`AXI_NUM_MASTERS;mst++) begin
                if (valid_aw_qos_id_values == 1 &&  awqos_slv_sp_q[aw_pre_arb].size == 0 && ((slv_port_awvalid[aw_pre_arb] && aw_post_arb_pl_en && aw_mca_en[aw_pre_arb]) || (slv_port_awvalid[aw_pre_arb] && !aw_post_arb_pl_en && !aw_mca_en[aw_pre_arb]) || (!slv_port_awvalid[aw_pre_arb] && aw_post_arb_pl_en && !aw_mca_en[aw_pre_arb] && aw_mask_grant[aw_pre_arb]) || (slv_port_awvalid[aw_pre_arb] && aw_post_arb_pl_en && !aw_mca_en[aw_pre_arb] && !aw_mask_grant[aw_pre_arb]) || (aw_new_req[aw_pre_arb] && !aw_post_arb_pl_en && aw_mca_en[aw_pre_arb] && slv_port_awvalid[aw_pre_arb])) && ((`TOP.awqos_arb_test_started[aw_pre_arb] == 1 && `TOP.awqos_arb_test_started_dly[aw_pre_arb] != 1) || pop_awqos_completed[aw_pre_arb] == 1 || bus_awvalid_i[aw_pre_arb][mst-1] == 1)) begin
                  awqos_slv_sp_q[aw_pre_arb].push_back(highest_priority);
                  if (highest_priority_master == 1) 
                      awid_slv_sp_q[aw_pre_arb].push_back(visible_masters_q[aw_pre_arb][0]);
                  else if (highest_priority_master == 2)
                      awid_slv_sp_q[aw_pre_arb].push_back(visible_masters_q[aw_pre_arb][1]);
                  else if (highest_priority_master == 3)
                      awid_slv_sp_q[aw_pre_arb].push_back(visible_masters_q[aw_pre_arb][2]);
                  else if (highest_priority_master == 4)
                      awid_slv_sp_q[aw_pre_arb].push_back(visible_masters_q[aw_pre_arb][3]);
                  else if (highest_priority_master == 5)
                      awid_slv_sp_q[aw_pre_arb].push_back(visible_masters_q[aw_pre_arb][4]);
                  else if (highest_priority_master == 6)
                      awid_slv_sp_q[aw_pre_arb].push_back(visible_masters_q[aw_pre_arb][5]);
                  else if (highest_priority_master == 7)
                      awid_slv_sp_q[aw_pre_arb].push_back(visible_masters_q[aw_pre_arb][6]);
                  else if (highest_priority_master == 8)
                      awid_slv_sp_q[aw_pre_arb].push_back(visible_masters_q[aw_pre_arb][7]);
                  else if (highest_priority_master == 9)
                      awid_slv_sp_q[aw_pre_arb].push_back(visible_masters_q[aw_pre_arb][8]);
                  else if (highest_priority_master == 'ha)
                      awid_slv_sp_q[aw_pre_arb].push_back(visible_masters_q[aw_pre_arb][9]);
                  else if (highest_priority_master == 'hb)
                      awid_slv_sp_q[aw_pre_arb].push_back(visible_masters_q[aw_pre_arb][10]);
                  else if (highest_priority_master == 'hc)
                      awid_slv_sp_q[aw_pre_arb].push_back(visible_masters_q[aw_pre_arb][11]);
                  else if (highest_priority_master == 'hd)
                      awid_slv_sp_q[aw_pre_arb].push_back(visible_masters_q[aw_pre_arb][12]);
                  else if (highest_priority_master == 'he)
                      awid_slv_sp_q[aw_pre_arb].push_back(visible_masters_q[aw_pre_arb][13]);
                  else if (highest_priority_master == 'hf)
                      awid_slv_sp_q[aw_pre_arb].push_back(visible_masters_q[aw_pre_arb][14]);
                  $display("@%0t,Displaying AWqos queue of slv sp module [%0h]=%0p",$time,aw_pre_arb,awqos_slv_sp_q);
                  $display("@%0t,Displaying AWid queue of slv sp module [%0h]=%0p",$time,aw_pre_arb,awid_slv_sp_q);
              end // valid_aw_qos_id_values
              if (awqos_slv_sp_q[aw_pre_arb].size >0) begin
                  prev_awqos = awqos_slv_sp_q[aw_pre_arb][0];
                  $display("@%0t,Prev pushed AWQOS value[%0h] = %0h",$time,aw_pre_arb,prev_awqos);
              end
            end
            
       end // qos_arb_check_en
      end //while
   end
  join_none
  end //for loop 
  end //Write Address channel  From DW_axi_SP module

  // Comparing the Actual and Expected Qos and ID
  begin
      for (int s=1;s<=`AXI_NUM_SLAVES;s++) begin
      fork
      automatic integer num_slv = s;
      begin
        while (1) begin
            @(posedge `TOP.aclk);

         // ***** Check AWQOS value *******
         if (awqos_mst_slv_q[num_slv].size > 0 && awqos_slv_sp_q[num_slv].size >0) begin
             pop_issued_awqos=awqos_mst_slv_q[num_slv].pop_front();
             $display("@%0t,**** POP the AWQOS Value from slave port [%0h] AWQOS queue **** = %0h",$time,num_slv,pop_issued_awqos);
             pop_expected_awqos=awqos_slv_sp_q[num_slv].pop_front();
             $display("@%0t,**** POP the AWQOS Value from slave sp module [%0h] AWQOS queue **** = %0h",$time,num_slv,pop_expected_awqos);
             pop_awqos_completed[num_slv] = 1;
             if ( pop_issued_awqos != pop_expected_awqos ) begin
                 $display("===================================================================================");
                 $display("ERROR[%0t]-Incorrect AWQos value for Subordinate=%0h, Expected AWQoS=%0h, Actual=%0h",$time,num_slv,pop_expected_awqos,pop_issued_awqos);
                 $display("==================================================================================="); end
             else
                 $display("MATCH_FOUND[%0t]-AWQos value for Subordinate=%0h, Expected AWQoS=%0h, Actual=%0h",$time,num_slv,pop_expected_awqos,pop_issued_awqos);
         end

         // ***** Check AWID value *******
         if (awid_mst_slv_q[num_slv].size > 0 && awid_slv_sp_q[num_slv].size >0) begin
             pop_issued_awid=awid_mst_slv_q[num_slv].pop_front();
             $display("@%0t,**** POP the AWID Value from slave port [%0h] ID queue **** = %0h",$time,num_slv,pop_issued_awid+1);
             pop_expected_awid=awid_slv_sp_q[num_slv].pop_front();
             $display("@%0t,**** POP the AWID Value from slave sp module [%0h] ID queue **** = %0h",$time,num_slv,pop_expected_awid);
             pop_awid_completed[num_slv] = 1;
             if (pop_issued_awid+1 != pop_expected_awid ) begin
                 $display("===================================================================================");
                 $display("ERROR[%0t]-Incorrect AWID value for Subordinate=%0h, Expected AWID=%0h, Actual=%0h",$time,num_slv,pop_expected_awid,pop_issued_awid+1);
                 $display("==================================================================================="); end
             else
                 $display("MATCH_FOUND[%0t]-AWID value for Subordinate=%0h, Expected AWID=%0h, Actual=%0h",$time,num_slv,pop_expected_awid,pop_issued_awid+1);
         end

        end //while
      end
      join_none
      end // for-loop
  end

  `endif // AXI_AW_SHARED_LAYER
 
  `ifndef AXI_AR_SHARED_LAYER
  //============================
  // Read Address Channel
  //============================
  begin //Read Address channel - Subordinate port
    for (i=1;i<=`AXI_NUM_SLAVES;i++) begin : loop_ars  // For all Managers
      fork
      automatic integer arsub_id = i;
      begin : fork_ars
        while (1) begin
         @(negedge `TOP.aclk);
         wait (qos_arb_check_en == 1); 
          
          if (slv_port_arready[arsub_id] && slv_port_arvalid[arsub_id] && (!ar_shared_en[arsub_id])) begin
           issued_arqos=slv_port_arqos[arsub_id];
           issued_armngr_id=slv_port_arid[arsub_id];
           $display("@%0t,SLAVE PORT ARQOS when arvalid and arready is asserted for slave[%0h]=%0h",$time,arsub_id,issued_arqos);
           $display("@%0t,SLAVE PORT ARID when arvalid and arready is asserted for slave[%0h]=%0h",$time,arsub_id,issued_armngr_id);
           arqos_mst_slv_q[arsub_id].push_back(issued_arqos);
           arid_mst_slv_q[arsub_id].push_back(issued_armngr_id);
           $display("@%0t,Displaying ARqos queue of slv port [%0h]=%0p",$time,arsub_id,arqos_mst_slv_q);
           $display("@%0t,Displaying ARid queue of slv port [%0h]=%0p",$time,arsub_id,arid_mst_slv_q); end
        end
      end  
      join_none
    end //loop_ars 
  end //Read Address channel - Subordinate port

  begin // Read Address channel- From DW_axi_SP module
    for (i=1;i<=`AXI_NUM_SLAVES;i++) begin 
      fork
      automatic integer ar_pre_arb = i;
      begin 
        while (1) begin
          @(negedge `TOP.aclk);
          if(qos_arb_check_en && qos_ararb_chk_en_s[ar_pre_arb] && (!ar_shared_en[ar_pre_arb])) begin

            highest_priority = 4'h0;
            valid_ar_qos_id_values = 'h0;
            for(int j=1;j<=`AXI_NUM_MASTERS;j++) begin
               if ((bus_arvalid_i[ar_pre_arb][j-1] == 1) && ((bus_arqos_i[ar_pre_arb][(j-1)*4 +: 4]) > (highest_priority)))  begin
                highest_priority_master = j;
                highest_priority=bus_arqos_i[ar_pre_arb][(j-1)*4 +: 4];
                valid_ar_qos_id_values = 1;
                $display("@%0t, Expected Value for slave on AR Channel =%0h highest_priority_master=%0h,highest_priority=%0h",$time,ar_pre_arb,highest_priority_master,highest_priority);
               end
                else if (bus_arqos_i[ar_pre_arb][(j-1)*4 +: 4] == bus_arqos_i[ar_pre_arb][(highest_priority_master-1)*4 +: 4] && (j < highest_priority_master) && (bus_arvalid_i[ar_pre_arb][j-1] == 1)) begin
                highest_priority_master = j;
                highest_priority=bus_arqos_i[ar_pre_arb][(j-1)*4 +: 4];
                valid_ar_qos_id_values = 1;
                $display("@%0t,Expected value for slave on AR Channel =%0h for Equal priority highest_priority_master=%0h,highest_priority=%0h",$time,ar_pre_arb,highest_priority_master,highest_priority); 
               end
            end // for-loop

            for (mst=1;mst<=`AXI_NUM_MASTERS;mst++) begin
                if (valid_ar_qos_id_values == 1 &&  arqos_slv_sp_q[ar_pre_arb].size == 0 && ((slv_port_arvalid[ar_pre_arb] && ar_post_arb_pl_en && ar_mca_en[ar_pre_arb]) || (slv_port_arvalid[ar_pre_arb] && !ar_post_arb_pl_en && !ar_mca_en[ar_pre_arb]) || (!slv_port_arvalid[ar_pre_arb] && ar_post_arb_pl_en && !ar_mca_en[ar_pre_arb] && ar_mask_grant[ar_pre_arb]) || (slv_port_arvalid[ar_pre_arb] && ar_post_arb_pl_en && !ar_mca_en[ar_pre_arb] && !ar_mask_grant[ar_pre_arb]) || (ar_new_req[ar_pre_arb] && !ar_post_arb_pl_en && ar_mca_en[ar_pre_arb] && slv_port_arvalid[ar_pre_arb])) && ((`TOP.arqos_arb_test_started[ar_pre_arb] == 1 && `TOP.arqos_arb_test_started_dly[ar_pre_arb] != 1) || pop_arqos_completed[ar_pre_arb] == 1 || bus_arvalid_i[ar_pre_arb][mst-1])) begin
                 arqos_slv_sp_q[ar_pre_arb].push_back(highest_priority);
                 if (highest_priority_master == 1) 
                     arid_slv_sp_q[ar_pre_arb].push_back(visible_masters_q[ar_pre_arb][0]);
                 else if (highest_priority_master == 2)
                     arid_slv_sp_q[ar_pre_arb].push_back(visible_masters_q[ar_pre_arb][1]);
                 else if (highest_priority_master == 3)
                     arid_slv_sp_q[ar_pre_arb].push_back(visible_masters_q[ar_pre_arb][2]);
                 else if (highest_priority_master == 4)
                     arid_slv_sp_q[ar_pre_arb].push_back(visible_masters_q[ar_pre_arb][3]);
                 else if (highest_priority_master == 5)
                     arid_slv_sp_q[ar_pre_arb].push_back(visible_masters_q[ar_pre_arb][4]);
                 else if (highest_priority_master == 6)
                     arid_slv_sp_q[ar_pre_arb].push_back(visible_masters_q[ar_pre_arb][5]);
                 else if (highest_priority_master == 7)
                     arid_slv_sp_q[ar_pre_arb].push_back(visible_masters_q[ar_pre_arb][6]);
                 else if (highest_priority_master == 8)
                     arid_slv_sp_q[ar_pre_arb].push_back(visible_masters_q[ar_pre_arb][7]);
                 else if (highest_priority_master == 9)
                     arid_slv_sp_q[ar_pre_arb].push_back(visible_masters_q[ar_pre_arb][8]);
                 else if (highest_priority_master == 'ha)
                     arid_slv_sp_q[ar_pre_arb].push_back(visible_masters_q[ar_pre_arb][9]);
                 else if (highest_priority_master == 'hb)
                     arid_slv_sp_q[ar_pre_arb].push_back(visible_masters_q[ar_pre_arb][10]);
                 else if (highest_priority_master == 'hc)
                     arid_slv_sp_q[ar_pre_arb].push_back(visible_masters_q[ar_pre_arb][11]);
                 else if (highest_priority_master == 'hd)
                     arid_slv_sp_q[ar_pre_arb].push_back(visible_masters_q[ar_pre_arb][12]);
                 else if (highest_priority_master == 'he)
                     arid_slv_sp_q[ar_pre_arb].push_back(visible_masters_q[ar_pre_arb][13]);
                 else if (highest_priority_master == 'hf)
                     arid_slv_sp_q[ar_pre_arb].push_back(visible_masters_q[ar_pre_arb][14]);
                 $display("@%0t,Displaying ARqos queue of slv sp module [%0h]=%0p",$time,ar_pre_arb,arqos_slv_sp_q);
                 $display("@%0t,Displaying ARid queue of slv sp module [%0h]=%0p",$time,ar_pre_arb,arid_slv_sp_q);
                end //valid_ar_qos_id_values
                if ( arqos_slv_sp_q[ar_pre_arb].size >0) begin
                    prev_arqos = arqos_slv_sp_q[ar_pre_arb][0];
                    $display("@%0t,Prev pushed ARQOS value[%0h] = %0h",$time,ar_pre_arb,prev_arqos);
                end
            end
            
       end // qos_arb_check_en
      end //while
   end
  join_none
  end //for loop
  end // Read Address channel- From DW_axi_SP module

 // Comparing the Actual and Expected Qos and ID
  begin
      for (int s=1;s<=`AXI_NUM_SLAVES;s++) begin
      fork
      automatic integer num_slv = s;
      begin
        while (1) begin
            @(posedge `TOP.aclk);

         // ***** Check ARQOS value *******
         if (arqos_mst_slv_q[num_slv].size > 0 && arqos_slv_sp_q[num_slv].size >0) begin
             pop_issued_arqos=arqos_mst_slv_q[num_slv].pop_front();
             $display("@%0t,**** POP the ARQOS Value from slave port [%0h] ARQOS queue **** = %0h",$time,num_slv,pop_issued_arqos);
             pop_expected_arqos=arqos_slv_sp_q[num_slv].pop_front();
             $display("@%0t,**** POP the ARQOS Value from slave sp module [%0h] ARQOS queue **** = %0h",$time,num_slv,pop_expected_arqos);
             pop_arqos_completed[num_slv] = 1;
             if ( pop_issued_arqos != pop_expected_arqos ) begin
                 $display("===================================================================================");
                 $display("ERROR:[%0t]-Incorrect ARQos value for Subordinate=%0h, Expected ARQoS=%0h, Actual=%0h",$time,num_slv,pop_expected_arqos,pop_issued_arqos);
                 $display("==================================================================================="); end
             else
                 $display("MATCH_FOUND:[%0t]-ARQos value for Subordinate=%0h, Expected ARQoS=%0h, Actual=%0h",$time,num_slv,pop_expected_arqos,pop_issued_arqos);
         end

         // ***** Check ARID value *******
         if (arid_mst_slv_q[num_slv].size > 0 && arid_slv_sp_q[num_slv].size >0) begin
             pop_issued_arid=arid_mst_slv_q[num_slv].pop_front();
             $display("@%0t,**** POP the ARID Value from slave port [%0h] ID queue **** = %0h",$time,num_slv,pop_issued_arid+1);
             pop_expected_arid=arid_slv_sp_q[num_slv].pop_front();
             $display("@%0t,**** POP the ARID Value from slave sp module [%0h] ID queue **** = %0h",$time,num_slv,pop_expected_arid);
             pop_arid_completed[num_slv] = 1;
             if (pop_issued_arid+1 != pop_expected_arid ) begin
                 $display("===================================================================================");
                 $display("ERROR[%0t]-Incorrect ARID value for Subordinate=%0h, Expected ARID=%0h, Actual=%0h",$time,num_slv,pop_expected_arid,pop_issued_arid+1); 
                 $display("==================================================================================="); end
             else
                 $display("MATCH_FOUND[%0t]-ARID value for Subordinate=%0h, Expected ARID=%0h, Actual=%0h",$time,num_slv,pop_expected_arid,pop_issued_arid+1);
         end

        end //while
      end
      join_none
      end // for-loop
  end

  `endif // AXI_AR_SHARED_LAYER
 
  join_none
end 
endtask : check_qos_priority

task automatic get_subordinate_id_based_on_addr;
  input [`AXI_AW-1:0] addr_tmp;
  input [31:0] masterID;
  output [31:0] SlaveId;
  integer i,r;
  reg brk;
begin
  SlaveId = 0;
  for (i=1; i<= `AXI_NUM_SLAVES; i=i+1) begin
    for (r=0; r< slv_num_regions[i]; r++) begin
      if (test_debug) $display("@%0d [TB_DEBUG] {%m} : Slave ID=%0d Region ID=%0d for the Addr %0x Start %0x End %0x Visibility %0d Manager %0d\n",$time,i,r,addr_tmp,slv_region_start_array[i][r],slv_region_end_array[i][r],visible_slaves[masterID][i],masterID);
      if ((addr_tmp >= slv_region_start_array[i][r]) && (addr_tmp <= slv_region_end_array[i][r]) && visible_slaves[masterID][i]) begin
        SlaveId = i;
        brk = 1;
        break;
      end  
    end
    if (brk)
      break;
  end
end
endtask : get_subordinate_id_based_on_addr

/** Task to wait for the qos test to start on AW channel */
task automatic wait_for_awqos_arb_start_on_slv;
  input integer slv_num;

  begin 
   wait (qos_arb_check_en == 1); 
   wait ((bus_awvalid_i[slv_num] != 0));
   //@(posedge `TOP.aclk);
    begin
    `TOP.awqos_arb_test_started[slv_num] =  1;
    $display("@%0t ****** AW STARTED on slv[%0h]",$time,slv_num);
    @(posedge `TOP.aclk);
    `TOP.awqos_arb_test_started_dly[slv_num] = 1; end
  end
endtask

/** Task to wait for the qos test to start on AR channel */
task automatic wait_for_arqos_arb_start_on_slv;
  input integer slv_num;

  begin 
   wait (qos_arb_check_en == 1); 
   wait ((bus_arvalid_i[slv_num] != 0));
   //@(posedge `TOP.aclk);
    begin
    `TOP.arqos_arb_test_started[slv_num] =  1;
    $display("@%0t ******AR STARTED on slv[%0h] ",$time,slv_num);
    @(posedge `TOP.aclk);
    `TOP.arqos_arb_test_started_dly[slv_num] = 1; end
  end
endtask
`endif // AXI_QOS
`endif // SNPS_INTERNAL_ON

`endif //TB_CHECKER_V

