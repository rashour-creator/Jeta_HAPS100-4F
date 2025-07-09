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
// File Version     :        $Revision: #8 $ 
// Revision: $Id: //dwh/DW_ocb/DW_axi/axi_dev_br/sim/testbench/sim_svte/tb_initialize.sv#8 $ 
//------------------------------------------------------------------------

`ifndef TB_INITIALIZE_V
`define TB_INITIALIZE_V

/**
 * To hold the return 'is_valid' of set/get and other VIP calls.
 * Also used to check whether the return value is correct or not.
 */
reg is_valid;

/**
 * Variable used in VIP method calls - to temporarily store the handle.
 */
integer handle;
integer sys_cfg_handle;

/**
 * Defines used while initializing the VIP instances
 */
`define AXI_VIP_ACTIVE   1
`define AXI_VIP_PASSIVE  0

/** 
 * Set Up the Master's Configuration
 *   -- Get an integer handle that references a temporary copy of the Master's (default)
 *      internal configuration data object. Using this handle, the desired configuration
 *      settings will be applied to the properties of the temporary copy. 
 *
 */ 
`define AXI_SVT_CONFIGURE_VIP(transactor,xactor_id, mstr_slv_type, is_active_passive,handle,is_valid) \
  `GET_DATA_PROP_W_CHECK(transactor,xactor_id, `SVT_CMD_NULL_HANDLE, "cfg", handle, 0, is_valid) \
  `SET_DATA_PROP_W_CHECK(transactor,xactor_id, handle, "axi_port_kind", mstr_slv_type, 0, is_valid) \
  `ifdef AXI_HAS_AXI4 \
    `SET_DATA_PROP_W_CHECK(transactor,xactor_id, handle, "axi_interface_type", `SVT_AXI_INTERFACE_AXI4, 0, is_valid) \
  `endif \
  `ifdef AXI_HAS_AXI3 \
    `SET_DATA_PROP_W_CHECK(transactor,xactor_id, handle, "axi_interface_type", `SVT_AXI_INTERFACE_AXI3, 0, is_valid) \
  `endif \
  `ifdef AXI_HAS_AXI3 \
    `SET_DATA_PROP_W_CHECK(transactor,xactor_id, handle, "write_resp_wait_for_addr_accept",0, 0, is_valid) \
  `endif \
  `SET_DATA_PROP_W_CHECK(transactor,xactor_id, handle, "axi_interface_category", `SVT_AXI_READ_WRITE, 0, is_valid) \
  `SET_DATA_PROP_W_CHECK(transactor,xactor_id, handle, "addr_width",`AXI_AW, 0, is_valid) \
  `SET_DATA_PROP_W_CHECK(transactor,xactor_id, handle, "data_width",`AXI_DW, 0, is_valid) \
  `SET_DATA_PROP_W_CHECK(transactor,xactor_id, handle, "is_active",is_active_passive, 0, is_valid) \
  `SET_DATA_PROP_W_CHECK(transactor,xactor_id, handle, "exclusive_access_enable", 1, 0, is_valid) \
  `SET_DATA_PROP_W_CHECK(transactor,xactor_id, handle, "max_num_exclusive_access",4, 0, is_valid) \
  `SET_DATA_PROP_W_CHECK(transactor,xactor_id, handle, "axi_port_kind", mstr_slv_type, 0, is_valid) \
  `ifdef AXI_HAS_AXI4 \
  `ifdef AXI_INC_AWSB \
    `SET_DATA_PROP_W_CHECK(transactor,xactor_id, handle, "awuser_enable", 1, 0, is_valid) \
    `SET_DATA_PROP_W_CHECK(transactor,xactor_id, handle, "addr_user_width", `AXI_AW_SBW, 0, is_valid) \
  `endif \
  `ifdef AXI_INC_WSB \
    `SET_DATA_PROP_W_CHECK(transactor,xactor_id, handle, "wuser_enable", 1, 0, is_valid) \
    `SET_DATA_PROP_W_CHECK(transactor,xactor_id, handle, "data_user_width", `AXI_W_SBW, 0, is_valid) \
  `endif \
  `ifdef AXI_INC_BSB \
    `SET_DATA_PROP_W_CHECK(transactor,xactor_id, handle, "buser_enable", 1, 0, is_valid) \
    `SET_DATA_PROP_W_CHECK(transactor,xactor_id, handle, "resp_user_width", `AXI_B_SBW, 0, is_valid) \
  `endif \
  `ifdef AXI_INC_ARSB \
    `SET_DATA_PROP_W_CHECK(transactor,xactor_id, handle, "aruser_enable", 1, 0, is_valid) \
    `SET_DATA_PROP_W_CHECK(transactor,xactor_id, handle, "addr_user_width", `AXI_AR_SBW, 0, is_valid) \
  `endif \
  `ifdef AXI_INC_RSB \
    `SET_DATA_PROP_W_CHECK(transactor,xactor_id, handle, "ruser_enable", 1, 0, is_valid) \
    `SET_DATA_PROP_W_CHECK(transactor,xactor_id, handle, "data_user_width", `AXI_R_SBW, 0, is_valid) \
  `endif \
  `endif \
  `ifdef AXI_QOS \
    `ifdef AXI_HAS_AXI4 \
      `SET_DATA_PROP_W_CHECK(transactor,xactor_id, handle, "awqos_enable",1, 0, is_valid) \
      `SET_DATA_PROP_W_CHECK(transactor,xactor_id, handle, "arqos_enable",1, 0, is_valid) \
    `endif \
  `endif \
  if (mstr_slv_type == `SVT_AXI_SLAVE) begin \
  `SET_DATA_PROP_W_CHECK(transactor,xactor_id, handle, "id_width",`AXI_SIDW, 0, is_valid) \
  `SET_DATA_PROP_W_CHECK(transactor,xactor_id, handle, "default_awready",{$random(seed)}%2, 0, is_valid) \
  `SET_DATA_PROP_W_CHECK(transactor,xactor_id, handle, "default_arready",{$random(seed)}%2, 0, is_valid) \
  `SET_DATA_PROP_W_CHECK(transactor,xactor_id, handle, "default_wready",{$random(seed)}%2, 0, is_valid) \
  `SET_DATA_PROP_W_CHECK(transactor,xactor_id, handle, "num_outstanding_xact",-1, 0, is_valid) \
  `SET_DATA_PROP_W_CHECK(transactor,xactor_id, handle, "num_read_outstanding_xact",1000, 0, is_valid) \
  `SET_DATA_PROP_W_CHECK(transactor,xactor_id, handle, "num_write_outstanding_xact",1000, 0, is_valid) \
  `SET_DATA_PROP_W_CHECK(transactor,xactor_id, handle, "write_resp_reordering_depth",16, 0, is_valid) \
  `SET_DATA_PROP_W_CHECK(transactor,xactor_id, handle, "read_data_reordering_depth",16, 0, is_valid) \
  `SET_DATA_PROP_W_CHECK(transactor,xactor_id, handle, "reordering_algorithm", `SVT_AXI_REORDERING_RANDOM , 0, is_valid) \
  `ifdef AXI_HAS_AXI3 \
    if (slv_wid_array[xactor_id] > 8) \
      `SET_DATA_PROP_W_CHECK(transactor,xactor_id, handle, "write_data_interleave_depth",8, 0, is_valid) \
    else \
      `SET_DATA_PROP_W_CHECK(transactor,xactor_id, handle, "write_data_interleave_depth",slv_wid_array[xactor_id], 0, is_valid) \
  `endif \
  `ifdef AXI_HAS_AXI4 \
    `SET_DATA_PROP_W_CHECK(transactor,xactor_id, handle, "write_data_interleave_depth",1, 0, is_valid) \
    if (axi_has_region[xactor_id-1]) begin \
      `SET_DATA_PROP_W_CHECK(transactor,xactor_id, handle, "awregion_enable",1, 0, is_valid) \
      `SET_DATA_PROP_W_CHECK(transactor,xactor_id, handle, "arregion_enable",1, 0, is_valid) \
    end \
  `endif \
  if(ri_limit_m[`AXI_NUM_MASTERS-1:0] == {`AXI_NUM_MASTERS{1'b0}}) begin \
   if(slv_max_rd_transaction[xactor_id] > 8) \
     `SET_DATA_PROP_W_CHECK(transactor,xactor_id, handle, "read_data_interleave_size",8, 0, is_valid) \
   else  \
     `SET_DATA_PROP_W_CHECK(transactor,xactor_id, handle, "read_data_interleave_size",slv_max_rd_transaction[xactor_id], 0, is_valid) \
  end else begin \
     `SET_DATA_PROP_W_CHECK(transactor,xactor_id, handle, "read_data_interleave_size",1, 0, is_valid) \
      end \
  end \
  else if (mstr_slv_type == `SVT_AXI_MASTER) begin \
    if(xactor_id <= `AXI_NUM_ICM) \
      `SET_DATA_PROP_W_CHECK(transactor,xactor_id, handle, "id_width",`AXI_SIDW, 0, is_valid) \
    else \
      `SET_DATA_PROP_W_CHECK(transactor,xactor_id, handle, "id_width",`AXI_MIDW, 0, is_valid) \
  `SET_DATA_PROP_W_CHECK(transactor,xactor_id, handle, "default_rready",{$random(seed)}%2, 0,is_valid) \
  `SET_DATA_PROP_W_CHECK(transactor,xactor_id, handle, "default_bready",{$random(seed)}%2, 0,is_valid) \
  `SET_DATA_PROP_W_CHECK(transactor,xactor_id, handle, "num_outstanding_xact",-1, 0, is_valid) \
  `SET_DATA_PROP_W_CHECK(transactor,xactor_id, handle, "num_read_outstanding_xact",1000, 0, is_valid) \
  `SET_DATA_PROP_W_CHECK(transactor,xactor_id, handle, "num_write_outstanding_xact",1000, 0, is_valid) \
  `SET_DATA_PROP_W_CHECK(transactor,xactor_id, handle, "write_resp_reordering_depth",16, 0, is_valid) \
  `SET_DATA_PROP_W_CHECK(transactor,xactor_id, handle, "read_data_reordering_depth",16, 0, is_valid) \
  `SET_DATA_PROP_W_CHECK(transactor,xactor_id, handle, "reordering_algorithm", `SVT_AXI_REORDERING_RANDOM , 0, is_valid) \
  `SET_DATA_PROP_W_CHECK(transactor,xactor_id, handle, "write_data_interleave_depth",1, 0,is_valid) \
  end \
  `GET_DATA_PROP_W_CHECK(transactor,xactor_id, handle, "sys_cfg", sys_cfg_handle ,0,is_valid) \
  `SET_DATA_PROP_W_CHECK(transactor,xactor_id, sys_cfg_handle, "bus_inactivity_timeout", 10000000, 0, is_valid) \
  `SET_DATA_PROP_W_CHECK(transactor,xactor_id, sys_cfg_handle, "awready_watchdog_timeout", 50000, 0, is_valid) \
  `SET_DATA_PROP_W_CHECK(transactor,xactor_id, sys_cfg_handle, "arready_watchdog_timeout", 50000, 0, is_valid) \
  `SET_DATA_PROP_W_CHECK(transactor,xactor_id, sys_cfg_handle, "bready_watchdog_timeout", 10000, 0, is_valid) \
  `SET_DATA_PROP_W_CHECK(transactor,xactor_id, sys_cfg_handle, "rready_watchdog_timeout", 50000, 0, is_valid) \
  `SET_DATA_PROP_W_CHECK(transactor,xactor_id, sys_cfg_handle, "wready_watchdog_timeout", 50000, 0, is_valid) \
  `SET_DATA_PROP_W_CHECK(transactor,xactor_id, sys_cfg_handle, "rdata_watchdog_timeout", 300000, 0, is_valid) \
  `SET_DATA_PROP_W_CHECK(transactor,xactor_id, sys_cfg_handle, "bresp_watchdog_timeout", 20000, 0, is_valid) \
  `SET_DATA_PROP_W_CHECK(transactor,xactor_id, `SVT_CMD_NULL_HANDLE, "filter(The response got changed after driving the bresp, and it will not have the effect)", `SVT_CMD_NORMAL_SEVERITY, 0, is_valid) \
  `SET_DATA_PROP_W_CHECK(transactor,xactor_id, `SVT_CMD_NULL_HANDLE, "filter(Timed out waiting for wdata after Write address handshake assertion)", `SVT_CMD_NORMAL_SEVERITY, 0, is_valid)
/**
 * Demoting UVM_WARNING because the current version of the VIP is monitoring changes to bresp that happen after it has been sampled at bready.  
 * //UVM_WARNING /global/cust_apps_sgip001/dw_internal/vip/svt/amba_svt/V-2023.09/axi_slave_svt/sverilog/src/vcs/svt_axi_base_slave_common.svp(10711) @ 5231850000: test_DW_axi.axi_slave[3].AXI_SLAVE_AGENT [send_write_resp] {OBJECT_NUM('d100012) PORT_ID('d0) AUTO_GENERATED_XACT('b0) PORT_NAME(unset_inst) TYPE(WRITE) WLAST('b1) DATA_BEFORE_ADDR('b1) ID('h1) SECURE('d1) ADDR('hc00a477) CACHE_TYPE('d10) START_TIME(5229650000)} The response got changed after driving the bresp, and it will not have the effect.*/
/**
  * Demoting known UVM_ERROR due to VIP restriction -- STAR 9000777797.
  */                                               

/**
  * Method to Configure Masters VIP instances.
  */
task configure_master_vip;
  integer i;
  integer xfer_handle;
  reg is_valid;
  begin
    $display ("\n@%0d [TB_INFO] {%m} : Master configuration started\n",$time);
    for (i = 1 ; i <= `AXI_NUM_MASTERS; i++) begin
      `AXI_SVT_CONFIGURE_VIP("master",i, `SVT_AXI_MASTER, `AXI_VIP_ACTIVE,xfer_handle,is_valid)
      `TOP.vip_apply_data("master",i,xfer_handle);
      `GET_DATA_PROP_W_CHECK("master",i, `SVT_CMD_NULL_HANDLE, "cfg", xfer_handle, 0, is_valid) 
      if (test_debug) `TOP.vip_display_data("master",i,xfer_handle,"[TB_DEBUG] Master Configuration");
    end
    $display ("\n@%0d [TB_INFO] {%m} : Master configuration ended\n",$time);
  end
endtask

/**
  * Method to Configure Slave VIP instances.
  */
task configure_slave_vip;
  integer i;
  reg is_valid;
  integer xfer_handle;
  begin
    $display ("\n@%0d [TB_INFO] {%m} : Slave configuration Started\n",$time);
    for (i = 1 ; i <= `AXI_NUM_SLAVES; i++) begin
      `AXI_SVT_CONFIGURE_VIP("slave",i, `SVT_AXI_SLAVE, `AXI_VIP_ACTIVE,xfer_handle,is_valid)
      `TOP.vip_apply_data("slave",i,xfer_handle);
      `GET_DATA_PROP_W_CHECK("slave",i, `SVT_CMD_NULL_HANDLE, "cfg", xfer_handle, 0, is_valid) 
      if (test_debug) `TOP.vip_display_data("slave",i,xfer_handle,"[TB_DEBUG] Slave Configuration");
    end
    $display ("\n@%0d [TB_INFO] {%m} : Slaves configuration Ended\n",$time);
  end
endtask

/**
 * Method to start the Master transactors
 */
task start_all_masters;
  integer i;
  begin
    $display ("\n@%0d [TB_INFO] {%m} : Starting all masters\n",$time);
    for (i = 1; i <= `AXI_NUM_MASTERS; i++) begin
      `TOP.vip_start("master",i);
    end
  end
endtask

/**
 * Method to start the Slave transactors
 */
task start_all_slaves;
  integer i;
  begin
     $display ("\n@%0d [TB_INFO] {%m} : Starting all slaves\n",$time);
    for (i = 1; i <= `AXI_NUM_SLAVES; i++) begin
      `TOP.vip_start("slave",i);
    end
  end
endtask

/**
 * Method to stop the Master transactors
 */
task stop_all_masters;
  integer i;
  begin
    $display ("\n@%0d [TB_INFO] {%m} : Stoping all masters\n",$time);
    for (i = 1; i <= `AXI_NUM_MASTERS; i++) begin
      `TOP.vip_stop("master",i);
    end
  end
endtask

/**
 * Method to stop the Slave transactors
 */
task stop_all_slaves;
  integer i;
  begin
    $display ("\n@%0d [TB_INFO] {%m} : Stoping all slaves\n",$time);
    for (i = 1; i <= `AXI_NUM_SLAVES; i++) begin
      `TOP.vip_stop("slave",i);
    end
  end
endtask

`endif // TB_INITIALIZE_V
