
#########################################################################
# Configuration Parameters
#########################################################################
set low_power      [get_configuration_parameter A2X_LOWPWR_IF]
set pp_mode        [get_configuration_parameter A2X_PP_MODE]
set num_ahbm       [get_configuration_parameter A2X_NUM_AHBM]
set clk_mode       [get_configuration_parameter A2X_CLK_MODE]
set pp_sync_depth  [get_configuration_parameter A2X_PP_SYNC_DEPTH]
set sp_sync_depth  [get_configuration_parameter A2X_SP_SYNC_DEPTH]
set bresp_mode     [get_configuration_parameter A2X_BRESP_MODE]

# Primary Port Clock AHB(0) AXI (1)
if {$pp_mode==0} {
  set clock_pp  "hclk"
  set resetn_pp "hresetn"
} else {
  set clock_pp  "clk_pp"
  set resetn_pp "resetn_pp"
}

set_port_attribute  $clock_pp ClockName $clock_pp
set_clock_attribute $clock_pp FixHold   false
set_clock_attribute $clock_pp CycleTime 2.5ns

# If clock_mode is set to asynchronous or Quassi-Synchronous there will be 2 clocks in the
# A2X, if so generate a seperate slave port clock and constrain 
# slave port ports w.r.t. that clock. Otherwise constrain w.r.t. 
# master port clock.
if {$clk_mode != 0} {
  # Generate and constrain slave port clock.
  set clock_sp  "clk_sp"
  set resetn_sp "resetn_sp"
  set_port_attribute  $clock_sp ClockName $clock_sp
  set_clock_attribute $clock_sp FixHold   false
  set_clock_attribute $clock_sp CycleTime 2.5ns
} else {
  # Use master port clock. 
  set clock_sp $clock_pp
}

set_port_attribute $clock_pp  DftExistingSignalType ScanClock
set_port_attribute $resetn_pp DftExistingSignalType Reset
set_port_attribute $resetn_pp DftExistingSignalActiveState 0

if {$clk_mode != 0} {
  set_port_attribute $clock_sp  DftExistingSignalType ScanClock
  set_port_attribute $resetn_sp DftExistingSignalType Reset
  set_port_attribute $resetn_sp DftExistingSignalActiveState 0
}

set inputPorts  [all_inputs -no_clocks -no_reset] 
set outputPorts [all_outputs ] 
#*****************************************************************************************
# Constraints - Asynchronous Clock Domain Crossing 
#
# Following Methodology is followed for Clock Domain Crossing Signals
# 1. CDC Qualifier Signals 
#    Use set_max_delay constraint (of 1 destination clock period) for qualifier signals 
#    reaching first stage of double synchronizer in qualifier-based synchronizers
# 2. CDC Toggle Qualifier Signals
#    Use set_max_delay constraint (of 1 destination clock period) even for toggle signals 
#    reaching first stage of the BCM21/BCM41 inside a BCM22/BCM23 cell. This ensures 
#    that the pulse-synchronizer will work with minimal delay between two source pulses
# 3. CDC Qualified Data Signals
#    Use set_max_delay constraint (of (# of synchronizer stages - 0.5) * destination clock 
#    period) for qualified (data) signals in qualifier-based synchronizers. 
# 
# NOTE: 
# 1. This assumes the clocks are completely asynchronous and the false path is given 
#    set_max_delay constraint
# 2. The CDC Signals i.e. these false paths are not checked for hold. This is done 
#    through the set_false_path with hold check disabled.
#*****************************************************************************************
## Asychronous Paths between Primary/AHB Port and Secondary Port

#if {$clk_mode != 0} {
#  set_false_path -from {U_a2x_core/U_a2x_w/U_a2x_wd_fifo/DUAL_CLK_FIFO.U_dclk_fifo/U_FIFO_MEM/mem_array*} -to [find_item -type clock clk_sp]
#}
#
#if {($clk_mode==2) && ($pp_sync_depth > 0) && ($sp_sync_depth > 0)} {
#   if {$pp_sync_depth == 1} {
#      set sp_sync_perc [expr int(1 * 100)]
#   } else {
#      set sp_sync_perc  [expr int(($pp_sync_depth - 0.5)*100)]
#   }
#   if {$sp_sync_depth == 1} { 
#      set pp_sync_perc [expr int(1 * 100)]
#   } else {
#      set pp_sync_perc  [expr int(($sp_sync_depth - 0.5)*100)] 
#   }
#
#   set sp_sync_perc 100
#   set pp_sync_perc 100
#
#   set sp_sync_smdly "=percent_of_period $sp_sync_perc clk_sp"
#
#  if {$pp_mode==1} {
#  
#    read_sdc -script "set_clock_groups -asynchronous -group clk_pp -group clk_sp -allow_paths"
#
#    set pp_sync_smdly "=percent_of_period $pp_sync_perc clk_pp"
#
#    set_false_path -from [find_item -type clock clk_pp] -to [find_item -type clock clk_sp] -hold
#    set_max_delay -ignore_clock_latency $sp_sync_smdly -from [find_item -type clock clk_pp] -to [find_item -type clock clk_sp]
#    set_min_delay -ignore_clock_latency 0 -from [find_item -type clock clk_pp] -to [find_item -type clock clk_sp]
#
#    set_false_path -from [find_item -type clock clk_sp] -to [find_item -type clock clk_pp] -hold
#    set_max_delay -ignore_clock_latency $pp_sync_smdly -from [find_item -type clock clk_sp] -to [find_item -type clock clk_pp]
#    set_min_delay -ignore_clock_latency 0 -from [find_item -type clock clk_sp] -to [find_item -type clock clk_pp]
#
#    if {$low_power==1} {
#      set clk_sp_qual_smdly "=percent_of_period 100 clk_sp"
#      set clk_pp_qual_smdly "=percent_of_period 100 clk_pp"
#
#      set_max_delay $clk_sp_qual_smdly -from {U_a2x_core/LOWPWR.U_axi_a2x_lp/U_DW_axi_a2x_bcm21_pp2spl_pp_tog_spsyzr/data_s*} -to [find_item -type clock clk_sp]
#      set_max_delay $clk_pp_qual_smdly -from {U_a2x_core/LOWPWR.U_axi_a2x_lp/U_DW_axi_a2x_bcm21_sp2ppl_sp_tog_ppsyzr/data_s*} -to [find_item -type clock clk_pp]
#      
#      if {$bresp_mode!=1} {
#        set clk_pp_qual_smdly "=percent_of_period 100 clk_pp"
#        set_max_delay $clk_pp_qual_smdly -from {U_a2x_core/BUSY_STATUS.U_busy_status/SP_OS_WR_SYNC.U_DW_axi_a2x_bcm21_sp2ppl_aw_sp_active_ppsyzr/data_s*} -to [find_item -type clock clk_pp]
#      }
#    }    
#  } else {
#    
#    read_sdc -script "set_clock_groups -asynchronous -group hclk -group clk_sp -allow_paths"
#
#    set pp_sync_smdly "=percent_of_period $pp_sync_perc hclk"
#
#    set_false_path -from [find_item -type clock hclk] -to [find_item -type clock clk_sp] -hold
#    set_max_delay -ignore_clock_latency $sp_sync_smdly -from [find_item -type clock hclk] -to [find_item -type clock clk_sp]
#    set_min_delay -ignore_clock_latency 0 -from [find_item -type clock hclk] -to [find_item -type clock clk_sp]
#
#    set_false_path -from [find_item -type clock clk_sp] -to [find_item -type clock hclk] -hold
#    set_max_delay -ignore_clock_latency $pp_sync_smdly -from [find_item -type clock clk_sp] -to [find_item -type clock hclk]
#    set_min_delay -ignore_clock_latency 0 -from [find_item -type clock clk_sp] -to [find_item -type clock hclk]
#
#    if {$low_power==1} {
#      set clk_sp_qual_smdly "=percent_of_period 100 clk_sp"
#      set clk_pp_qual_smdly "=percent_of_period 100 hclk"
#
#      set_max_delay $clk_sp_qual_smdly -from {U_a2x_core/LOWPWR.U_axi_a2x_lp/U_DW_axi_a2x_bcm21_pp2spl_pp_tog_spsyzr/data_s*} -to [find_item -type clock clk_sp]
#      set_max_delay $clk_pp_qual_smdly -from {U_a2x_core/LOWPWR.U_axi_a2x_lp/U_DW_axi_a2x_bcm21_sp2ppl_sp_tog_ppsyzr/data_s*} -to [find_item -type clock hclk]
#
#      if {$bresp_mode!=1} {
#        set clk_pp_qual_smdly "=percent_of_period 100 hclk"
#        set_max_delay $clk_pp_qual_smdly -from {U_a2x_core/BUSY_STATUS.U_busy_status/SP_OS_WR_SYNC.U_DW_axi_a2x_bcm21_sp2ppl_aw_sp_active_ppsyzr/data_s*} -to [find_item -type clock hclk]
#      }
#    }
#  }
#}
if {($clk_mode==2) && ($pp_sync_depth > 0) && ($sp_sync_depth > 0)} {
  if {$pp_mode==1} {
    read_sdc -script "set_clock_groups -asynchronous -group clk_pp -group clk_sp -allow_paths" 
  } else {
    read_sdc -script "set_clock_groups -asynchronous -group hclk -group clk_sp -allow_paths"
  } 
} else {
  if {$pp_mode==1} {
    if {(($clk_mode==2) || ($clk_mode==1)) && ($pp_sync_depth == 0) && ($sp_sync_depth == 0)} {
      read_sdc -script "set_clock_groups -asynchronous -group {clk_pp clk_sp} -allow_paths" 
    } else {
      read_sdc -script "set_clock_groups -asynchronous -group clk_pp -allow_paths" 
    } 
  } else {
    if {(($clk_mode==2) || ($clk_mode==1)) && ($pp_sync_depth == 0) && ($sp_sync_depth == 0)} {
      read_sdc -script "set_clock_groups -asynchronous -group {hclk clk_sp} -allow_paths" 
    } else {
      read_sdc -script "set_clock_groups -asynchronous -group hclk -allow_paths"
    } 
  } 
}

####################################################################################
# Primary Port AHB Constraints
####################################################################################
if {$pp_mode == 0} {
  # AHB Primary Port Inputs.
  set pHInputPorts [find_item -quiet $inputPorts -filter "Name=~h.*"]
  set_port_attribute $pHInputPorts MinInputDelay\[$clock_pp\] "=percent_of_period 20"
  set_port_attribute $pHInputPorts MaxInputDelay\[$clock_pp\] "=percent_of_period 20"

  # AHB Primary Port Outputs.
  set pHOutputPorts [find_item -quiet $outputPorts -filter "Name=~h.*"]
  set_port_attribute $pHOutputPorts MinOutputDelay\[$clock_pp\] "=percent_of_period 30"
  set_port_attribute $pHOutputPorts MaxOutputDelay\[$clock_pp\] "=percent_of_period 30"
} 

####################################################################################
# Primary Port AXI Constraints
####################################################################################
if {$pp_mode == 1} {
  # AXI Primary Port Write address channel.
  set pAWInputPorts [find_item -type port -filter {PortDirection==in} aw*_pp*]
  set_port_attribute $pAWInputPorts MinInputDelay\[$clock_pp\] "=percent_of_period 30"
  set_port_attribute $pAWInputPorts MaxInputDelay\[$clock_pp\] "=percent_of_period 30"
  
  set pAWOutputPorts [find_item -type port -filter {PortDirection==out} aw*_pp*]
  set_port_attribute $pAWOutputPorts MinOutputDelay\[$clock_pp\] "=percent_of_period 30"
  set_port_attribute $pAWOutputPorts MaxOutputDelay\[$clock_pp\] "=percent_of_period 30"
  
  # Secondary Port Write data channel.
  set pWInputPorts [find_item -type port -filter {PortDirection==in} w*_pp*]
  set_port_attribute $pWInputPorts MinInputDelay\[$clock_pp\] "=percent_of_period 30"
  set_port_attribute $pWInputPorts MaxInputDelay\[$clock_pp\] "=percent_of_period 30"
  
  set pWOutputPorts [find_item -type port -filter {PortDirection==out} w*_pp*]
  set_port_attribute $pWOutputPorts MinOutputDelay\[$clock_pp\] "=percent_of_period 30"
  set_port_attribute $pWOutputPorts MaxOutputDelay\[$clock_pp\] "=percent_of_period 30"

  # Secondary Port Write Response Channel.
  set pBInputPorts [find_item -type port -filter {PortDirection==in} b*_pp*]
  set_port_attribute $pBInputPorts MinInputDelay\[$clock_pp\] "=percent_of_period 30"
  set_port_attribute $pBInputPorts MaxInputDelay\[$clock_pp\] "=percent_of_period 30"
  
  set pBOutputPorts [find_item -type port -filter {PortDirection==out} b*_pp*]
  set_port_attribute $pBOutputPorts MinOutputDelay\[$clock_pp\] "=percent_of_period 30"
  set_port_attribute $pBOutputPorts MaxOutputDelay\[$clock_pp\] "=percent_of_period 30"
  
  # AXI Primary Port Read address channel.
  set pARInputPorts [find_item -type port -filter {PortDirection==in} ar*_pp*]
  set_port_attribute $pARInputPorts MinInputDelay\[$clock_pp\] "=percent_of_period 30"
  set_port_attribute $pARInputPorts MaxInputDelay\[$clock_pp\] "=percent_of_period 30"
  
  set pAROutputPorts [find_item -type port -filter {PortDirection==out} ar*_pp*]
  set_port_attribute $pAROutputPorts MinOutputDelay\[$clock_pp\] "=percent_of_period 30"
  set_port_attribute $pAROutputPorts MaxOutputDelay\[$clock_pp\] "=percent_of_period 30"  

  # Secondary Port Read data channel.
  set pRInputPorts [find_item -type port -filter {PortDirection==in} r*_pp*]
  set_port_attribute $pRInputPorts MinInputDelay\[$clock_pp\] "=percent_of_period 30"
  set_port_attribute $pRInputPorts MaxInputDelay\[$clock_pp\] "=percent_of_period 30"
  
  set pROutputPorts [find_item -type port -filter {PortDirection==out} r*_pp*]
  set_port_attribute $pROutputPorts MinOutputDelay\[$clock_pp\] "=percent_of_period 30"
  set_port_attribute $pROutputPorts MaxOutputDelay\[$clock_pp\] "=percent_of_period 30"
  
}

####################################################################################
# Secondary Port Constraints
####################################################################################
# Secondary Port Write address channel.
set sAWInputPorts [find_item -type port -filter {PortDirection==in} aw*_sp*]
set_port_attribute $sAWInputPorts MinInputDelay\[$clock_sp\] "=percent_of_period 30"
set_port_attribute $sAWInputPorts MaxInputDelay\[$clock_sp\] "=percent_of_period 30"

set sAWOutputPorts [find_item -type port -filter {PortDirection==out} aw*_sp*]
set_port_attribute $sAWOutputPorts MinOutputDelay\[$clock_sp\] "=percent_of_period 30"
set_port_attribute $sAWOutputPorts MaxOutputDelay\[$clock_sp\] "=percent_of_period 30"

# Secondary Port Write data channel.
set sWInputPorts [find_item -type port -filter {PortDirection==in} w*_sp*]
set_port_attribute $sWInputPorts MinInputDelay\[$clock_sp\] "=percent_of_period 30"
set_port_attribute $sWInputPorts MaxInputDelay\[$clock_sp\] "=percent_of_period 30"

set sWOutputPorts [find_item -type port -filter {PortDirection==out} w*_sp*]
set_port_attribute $sWOutputPorts MinOutputDelay\[$clock_sp\] "=percent_of_period 30"
set_port_attribute $sWOutputPorts MaxOutputDelay\[$clock_sp\] "=percent_of_period 30"

# Secondary Port Write Response Channel.
set sBInputPorts [find_item -type port -filter {PortDirection==in} b*_sp*]
set_port_attribute $sBInputPorts MinInputDelay\[$clock_sp\] "=percent_of_period 30"
set_port_attribute $sBInputPorts MaxInputDelay\[$clock_sp\] "=percent_of_period 30"

set sBOutputPorts [find_item -type port -filter {PortDirection==out} b*_sp*]
set_port_attribute $sBOutputPorts MinOutputDelay\[$clock_sp\] "=percent_of_period 30"
set_port_attribute $sBOutputPorts MaxOutputDelay\[$clock_sp\] "=percent_of_period 30"

# Secondary Port Read address channel.
set sARInputPorts [find_item -type port -filter {PortDirection==in} ar*_sp*]
set_port_attribute $sARInputPorts MinInputDelay\[$clock_sp\] "=percent_of_period 30"
set_port_attribute $sARInputPorts MaxInputDelay\[$clock_sp\] "=percent_of_period 30"

set sAROutputPorts [find_item -type port -filter {PortDirection==out} ar*_sp*]
set_port_attribute $sAROutputPorts MinOutputDelay\[$clock_sp\] "=percent_of_period 30"
set_port_attribute $sAROutputPorts MaxOutputDelay\[$clock_sp\] "=percent_of_period 30"

# Secondary Port Write data channel.
set sRInputPorts [find_item -type port -filter {PortDirection==in} r*_sp*]
set_port_attribute $sRInputPorts MinInputDelay\[$clock_sp\] "=percent_of_period 30"
set_port_attribute $sRInputPorts MaxInputDelay\[$clock_sp\] "=percent_of_period 30"

set sROutputPorts [find_item -type port -filter {PortDirection==out} r*_sp*]
set_port_attribute $sROutputPorts MinOutputDelay\[$clock_sp\] "=percent_of_period 30"
set_port_attribute $sROutputPorts MaxOutputDelay\[$clock_sp\] "=percent_of_period 30"

####################################################################################
# Low Power Constraints
####################################################################################
if {$low_power == 1} {
  set pLPActivePorts [find_item -quiet $inputPorts -filter "Name==csysreq"]
  set_port_attribute $pLPActivePorts MinInputDelay\[$clock_pp\] "=percent_of_period 30"
  set_port_attribute $pLPActivePorts MaxInputDelay\[$clock_pp\] "=percent_of_period 30"

  # Low Power Primary Port Outputs.
  set pLPOutputPorts [find_item -quiet $outputPorts -filter "Name==cactive"]
  set_port_attribute $pLPOutputPorts MinOutputDelay\[$clock_pp\] "=percent_of_period 30"
  set_port_attribute $pLPOutputPorts MaxOutputDelay\[$clock_pp\] "=percent_of_period 30"

  # Low Power Primary Port Outputs.
  set pLPOutputPorts [find_item -quiet $outputPorts -filter "Name==csysack"]
  set_port_attribute $pLPOutputPorts MinOutputDelay\[$clock_pp\] "=percent_of_period 30"
  set_port_attribute $pLPOutputPorts MaxOutputDelay\[$clock_pp\] "=percent_of_period 30"
}

# Busy_status port Outputs.
set pBusyStatPorts [find_item -quiet $outputPorts -filter "Name==busy_status"]
set_port_attribute $pBusyStatPorts MinOutputDelay\[$clock_pp\] "=percent_of_period 30"
set_port_attribute $pBusyStatPorts MaxOutputDelay\[$clock_pp\] "=percent_of_period 30"

