# Revision: $Id: //dwh/DW_ocb/DW_axi/axi_dev_br/pkg/pkg_script/DW_axi.elab.tcl#14 $

# --------------------------------------------------------------------
#
# Abstract : Post elaboration synthesis intent script for DW_axi.
#            Mainly setting constraints for conditional ports.
#
# --------------------------------------------------------------------

set clock "aclk"
#set_port_attribute aclk DftExistingSignalType ScanClock
#set_port_attribute aresetn DftExistingSignalType Reset
#set_port_attribute aresetn DftExistingSignalActiveState 0



set vld_rdy_par_prot [get_configuration_parameter AXI_VLD_RDY_PARITY_PROT]

if {$vld_rdy_par_prot == 1} {
  set vld_rdy_parity_i [find_item -type port -filter {PortDirection==in} *_parity_*]
  set_port_attribute $vld_rdy_parity_i MaxInputDelay\[$clock\] "=percent_of_period 20"
  set_port_attribute $vld_rdy_parity_i MinInputDelay\[$clock\] "=percent_of_period 20"

  set vld_rdy_parity_o [find_item -type port -filter {PortDirection==out} *_parity_*]
  set_port_attribute $vld_rdy_parity_o MaxOutputDelay\[$clock\] "=percent_of_period 20"
  set_port_attribute $vld_rdy_parity_o MinOutputDelay\[$clock\] "=percent_of_period 20"
}

set remap [get_configuration_parameter AXI_REMAP_EN]

if {$remap == 1} {
  set_port_attribute remap_n MaxInputDelay\[$clock\] "=percent_of_period 20"
  set_port_attribute remap_n MinInputDelay\[$clock\] "=percent_of_period 20"
}


set trustzone [get_configuration_parameter AXI_HAS_TZ_SUPPORT]

if {$trustzone == 1} {
  set secureInputs [find_item -type port -filter {PortDirection==in} tz_secure_s*]
  set_port_attribute $secureInputs MaxInputDelay\[$clock\] "=percent_of_period 20"
  set_port_attribute $secureInputs MinInputDelay\[$clock\] "=percent_of_period 20"
}


set xdcdr [get_configuration_parameter AXI_HAS_XDCDR]

if {$xdcdr == 1} {
  set xdcdrInputs [find_item -type port -filter {PortDirection==in} xdcdr_slv_num*]
  set_port_attribute $xdcdrInputs MaxInputDelay\[$clock\] "=percent_of_period 20"
  set_port_attribute $xdcdrInputs MinInputDelay\[$clock\] "=percent_of_period 20"
}

set axi_interface [get_configuration_parameter AXI_INTERFACE_TYPE]
set arsideband [get_configuration_parameter AXI_HAS_ARSB]

if {$arsideband == 1} {
   if {$axi_interface == 0} {
     set arsb [find_item -type port -filter {PortDirection==in} arsideband_m*]
     set_port_attribute $arsb MaxInputDelay\[$clock\] "=percent_of_period 20"
     set_port_attribute $arsb MinInputDelay\[$clock\] "=percent_of_period 20"
   } else {
     set arub [find_item -type port -filter {PortDirection==in} aruser_m*]
     set_port_attribute $arub MaxInputDelay\[$clock\] "=percent_of_period 20"
     set_port_attribute $arub MinInputDelay\[$clock\] "=percent_of_period 20"
   }
}


if {$arsideband == 1} {
  if {$axi_interface == 0} {
     set arsb [find_item -type port -filter {PortDirection==out} arsideband_s*]
     set_port_attribute $arsb MaxOutputDelay\[$clock\] "=percent_of_period 20"
     set_port_attribute $arsb MinOutputDelay\[$clock\] "=percent_of_period 20"
  } else {
     set arub [find_item -type port -filter {PortDirection==out} aruser_s*]
     set_port_attribute $arub MaxOutputDelay\[$clock\] "=percent_of_period 20"
     set_port_attribute $arub MinOutputDelay\[$clock\] "=percent_of_period 20"
  }
}


set awsideband [get_configuration_parameter AXI_HAS_AWSB]

if {$awsideband == 1} {
  if {$axi_interface == 0} {
    set awsb [find_item -type port -filter {PortDirection==in} awsideband_m*]
    set_port_attribute $awsb MaxInputDelay\[$clock\] "=percent_of_period 20"
    set_port_attribute $awsb MinInputDelay\[$clock\] "=percent_of_period 20"
  } else {
    set awub [find_item -type port -filter {PortDirection==in} awuser_m*]
    set_port_attribute $awub MaxInputDelay\[$clock\] "=percent_of_period 20"
    set_port_attribute $awub MinInputDelay\[$clock\] "=percent_of_period 20"
  }
}



if {$awsideband == 1} {
   if {$axi_interface == 0} {
    set awsb [find_item -type port -filter {PortDirection==out} awsideband_s*]
    set_port_attribute $awsb MaxOutputDelay\[$clock\] "=percent_of_period 20"
    set_port_attribute $awsb MinOutputDelay\[$clock\] "=percent_of_period 20"
  } else {
    set awub [find_item -type port -filter {PortDirection==out} awuser_s*]
    set_port_attribute $awub MaxOutputDelay\[$clock\] "=percent_of_period 20"
    set_port_attribute $awub MinOutputDelay\[$clock\] "=percent_of_period 20"
  }
}


set rsideband [get_configuration_parameter AXI_HAS_RSB]

if {$rsideband == 1} {
  if {$axi_interface == 0} {
    set rsb [find_item -type port -filter {PortDirection==out} rsideband_m*]
    set_port_attribute $rsb MaxOutputDelay\[$clock\] "=percent_of_period 20"
    set_port_attribute $rsb MinOutputDelay\[$clock\] "=percent_of_period 20"
  } else {
    set rub [find_item -type port -filter {PortDirection==out} ruser_m*]
    set_port_attribute $rub MaxOutputDelay\[$clock\] "=percent_of_period 20"
    set_port_attribute $rub MinOutputDelay\[$clock\] "=percent_of_period 20"
  }
}



if {$rsideband == 1} {
  if {$axi_interface == 0} {
    set rsb [find_item -type port -filter {PortDirection==in} rsideband_s*]
    set_port_attribute $rsb MaxInputDelay\[$clock\] "=percent_of_period 20"
    set_port_attribute $rsb MinInputDelay\[$clock\] "=percent_of_period 20"
  } else {
    set rub [find_item -type port -filter {PortDirection==in} ruser_s*]
    set_port_attribute $rub MaxInputDelay\[$clock\] "=percent_of_period 20"
    set_port_attribute $rub MinInputDelay\[$clock\] "=percent_of_period 20"
  }
}


set wsideband [get_configuration_parameter AXI_HAS_WSB]

if {$wsideband == 1} {
  if {$axi_interface == 0} {
    set wsb [find_item -type port -filter {PortDirection==in} wsideband_m*]
    set_port_attribute $wsb MaxInputDelay\[$clock\] "=percent_of_period 20"
    set_port_attribute $wsb MinInputDelay\[$clock\] "=percent_of_period 20"
  } else {
    set wub [find_item -type port -filter {PortDirection==in} wuser_m*]
    set_port_attribute $wub MaxInputDelay\[$clock\] "=percent_of_period 20"
    set_port_attribute $wub MinInputDelay\[$clock\] "=percent_of_period 20"
  }
}


if {$wsideband == 1} {
  if {$axi_interface == 0} {
    set wsb [find_item -type port -filter {PortDirection==out} wsideband_s*]
    set_port_attribute $wsb MaxOutputDelay\[$clock\] "=percent_of_period 20"
    set_port_attribute $wsb MinOutputDelay\[$clock\] "=percent_of_period 20"
  } else {
    set wub [find_item -type port -filter {PortDirection==out} wuser_s*]
    set_port_attribute $wub MaxOutputDelay\[$clock\] "=percent_of_period 20"
    set_port_attribute $wub MinOutputDelay\[$clock\] "=percent_of_period 20"
  }
}

set bsideband [get_configuration_parameter AXI_HAS_BSB]

if {$bsideband == 1} {
  if {$axi_interface == 0} {
    set bsb [find_item -type port -filter {PortDirection==out} bsideband_m*]
    set_port_attribute $bsb MaxOutputDelay\[$clock\] "=percent_of_period 20"
    set_port_attribute $bsb MinOutputDelay\[$clock\] "=percent_of_period 20"
  } else {
    set bub [find_item -type port -filter {PortDirection==out} buser_m*]
    set_port_attribute $bub MaxOutputDelay\[$clock\] "=percent_of_period 20"
    set_port_attribute $bub MinOutputDelay\[$clock\] "=percent_of_period 20"
  }
}


if {$bsideband == 1} {
  if {$axi_interface == 0} {
    set bsb [find_item -type port -filter {PortDirection==in} bsideband_s*]
    set_port_attribute $bsb MaxInputDelay\[$clock\] "=percent_of_period 20"
    set_port_attribute $bsb MinInputDelay\[$clock\] "=percent_of_period 20"
  } else {
    set bub [find_item -type port -filter {PortDirection==in} buser_s*]
    set_port_attribute $bub MaxInputDelay\[$clock\] "=percent_of_period 20"
    set_port_attribute $bub MinInputDelay\[$clock\] "=percent_of_period 20"
  }
}


set ext_priority [get_configuration_parameter AXI_HAS_EXT_PRIORITY]
set shrd_lyr_m_pri_en [get_configuration_parameter AXI_SHARED_LAYER_MASTER_PRIORITY_EN]
set shrd_lyr_s_pri_en [get_configuration_parameter AXI_SHARED_LAYER_SLAVE_PRIORITY_EN]

if {$ext_priority == 1} {
  set ext_priority_in [find_item -type port -filter {PortDirection==in} *_priority_*]
  set_port_attribute $ext_priority_in MaxInputDelay\[$clock\] "=percent_of_period 20"
  set_port_attribute $ext_priority_in MinInputDelay\[$clock\] "=percent_of_period 20"

  if {$shrd_lyr_m_pri_en} {
    set_port_attribute mst_priority_shared MaxInputDelay\[$clock\] "=percent_of_period 20"
    set_port_attribute mst_priority_shared MinInputDelay\[$clock\] "=percent_of_period 20"
  }
  if {$shrd_lyr_s_pri_en} {
    set_port_attribute slv_priority_shared MaxInputDelay\[$clock\] "=percent_of_period 20"
    set_port_attribute slv_priority_shared MinInputDelay\[$clock\] "=percent_of_period 20"
  }
}

set lowpwr_hs_if [get_configuration_parameter AXI_LOWPWR_HS_IF]
if {$lowpwr_hs_if == 1} {
  set_port_attribute csysreq MaxInputDelay\[$clock\] "=percent_of_period 60"
  set_port_attribute csysreq MinInputDelay\[$clock\] "=percent_of_period 60"
  set_port_attribute cactive MaxOutputDelay\[$clock\] "=percent_of_period 60"
  set_port_attribute cactive MinOutputDelay\[$clock\] "=percent_of_period 60"
  set_port_attribute csysack MaxOutputDelay\[$clock\] "=percent_of_period 60"
  set_port_attribute csysack MinOutputDelay\[$clock\] "=percent_of_period 60"
}

set dlock_notify [get_configuration_parameter AXI_DLOCK_NOTIFY_EN]
if {$dlock_notify == 1} {
  set dlock [find_item -type port -filter {PortDirection==out} dlock_*]
  set_port_attribute $dlock MaxOutputDelay\[$clock\] "=percent_of_period 50"
  set_port_attribute $dlock MinOutputDelay\[$clock\] "=percent_of_period 50"
}

#APB configuration
set qos_en    [get_configuration_parameter AXI_HAS_QOS]
set safety_en [get_configuration_parameter AXI_INTF_PAR_EN]

if {$qos_en==1 || $safety_en==1} {
# Setting the default apb clock period as 50 MHZ
set apbclock "pclk"
set_port_attribute  $apbclock ClockName $apbclock
set_clock_attribute $apbclock FixHold   false
set_clock_attribute $apbclock CycleTime 20ns

# SET INPUT / OUTPUT DELAYS.
set_port_attribute presetn MinInputDelay\[$apbclock\] "=percent_of_period 0"
set_port_attribute presetn MaxInputDelay\[$apbclock\] "=percent_of_period 0"

# APB Interface
set_port_attribute penable      MinInputDelay\[$apbclock\]  "=percent_of_period 20"                   
set_port_attribute penable      MaxInputDelay\[$apbclock\]  "=percent_of_period 20"                   
set_port_attribute psel         MinInputDelay\[$apbclock\]  "=percent_of_period 20"                     
set_port_attribute psel         MaxInputDelay\[$apbclock\]  "=percent_of_period 20"                     
set_port_attribute pwrite       MinInputDelay\[$apbclock\]  "=percent_of_period 20"                     
set_port_attribute pwrite       MaxInputDelay\[$apbclock\]  "=percent_of_period 20"                     
set_port_attribute paddr        MinInputDelay\[$apbclock\]  "=percent_of_period 20"                    
set_port_attribute paddr        MaxInputDelay\[$apbclock\]  "=percent_of_period 20"                    
set_port_attribute pwdata       MinInputDelay\[$apbclock\]  "=percent_of_period 20"                    
set_port_attribute pwdata       MaxInputDelay\[$apbclock\]  "=percent_of_period 20"

set apb3 [get_configuration_parameter  AXI_HAS_APB3]
if {$apb3 == 1} {
set_port_attribute pready       MinOutputDelay\[$apbclock\] "=percent_of_period 20"                    
set_port_attribute pready       MaxOutputDelay\[$apbclock\] "=percent_of_period 20"                    
set_port_attribute pslverr      MinOutputDelay\[$apbclock\] "=percent_of_period 20"                    
set_port_attribute pslverr      MaxOutputDelay\[$apbclock\] "=percent_of_period 20"     
}
set_port_attribute prdata       MinOutputDelay\[$apbclock\] "=percent_of_period 20"                     
set_port_attribute prdata       MaxOutputDelay\[$apbclock\] "=percent_of_period 20"                     
}

if {$qos_en == 1} {
set awqosm1 [get_configuration_parameter  AXI_HAS_AWQOS_EXT_M1]
set arqosm1 [get_configuration_parameter  AXI_HAS_ARQOS_EXT_M1]
if  {$awqosm1 == 1} {
set_port_attribute awqos_m1          MinInputDelay\[$clock\]  "=percent_of_period 20"                  
set_port_attribute awqos_m1          MaxInputDelay\[$clock\]  "=percent_of_period 20"   
}
if  {$arqosm1 == 1} {
set_port_attribute arqos_m1          MinInputDelay\[$clock\]  "=percent_of_period 20"                  
set_port_attribute arqos_m1          MaxInputDelay\[$clock\]  "=percent_of_period 20"                  
}

set awqosm2 [get_configuration_parameter  AXI_HAS_AWQOS_EXT_M2]
set arqosm2 [get_configuration_parameter  AXI_HAS_ARQOS_EXT_M2]
if  {$awqosm2 == 1} {
set_port_attribute awqos_m2          MinInputDelay\[$clock\]  "=percent_of_period 20"                  
set_port_attribute awqos_m2          MaxInputDelay\[$clock\]  "=percent_of_period 20"                  
}
if  {$arqosm2 == 1} {
set_port_attribute arqos_m2          MinInputDelay\[$clock\]  "=percent_of_period 20"                  
set_port_attribute arqos_m2          MaxInputDelay\[$clock\]  "=percent_of_period 20"                  
}

set awqosm3 [get_configuration_parameter  AXI_HAS_AWQOS_EXT_M3]
set arqosm3 [get_configuration_parameter  AXI_HAS_ARQOS_EXT_M3]
if  {$awqosm3 == 1} {
set_port_attribute awqos_m3          MinInputDelay\[$clock\]  "=percent_of_period 20"                  
set_port_attribute awqos_m3          MaxInputDelay\[$clock\]  "=percent_of_period 20"                  
}
if  {$arqosm3 == 1} {
set_port_attribute arqos_m3          MinInputDelay\[$clock\]  "=percent_of_period 20"                  
set_port_attribute arqos_m3          MaxInputDelay\[$clock\]  "=percent_of_period 20"                  
}

set awqosm4 [get_configuration_parameter  AXI_HAS_AWQOS_EXT_M4]
set arqosm4 [get_configuration_parameter  AXI_HAS_ARQOS_EXT_M4]
if  {$awqosm4 == 1} {
set_port_attribute awqos_m4          MinInputDelay\[$clock\]  "=percent_of_period 20"                  
set_port_attribute awqos_m4          MaxInputDelay\[$clock\]  "=percent_of_period 20"                  
}
if  {$arqosm4 == 1} {
set_port_attribute arqos_m4          MinInputDelay\[$clock\]  "=percent_of_period 20"                  
set_port_attribute arqos_m4          MaxInputDelay\[$clock\]  "=percent_of_period 20"                  
}
set awqosm5 [get_configuration_parameter  AXI_HAS_AWQOS_EXT_M5]
set arqosm5 [get_configuration_parameter  AXI_HAS_ARQOS_EXT_M5]
if  {$awqosm5 == 1} {
set_port_attribute awqos_m5          MinInputDelay\[$clock\]  "=percent_of_period 20"                  
set_port_attribute awqos_m5          MaxInputDelay\[$clock\]  "=percent_of_period 20"                  
}
if  {$arqosm5 == 1} {
set_port_attribute arqos_m5          MinInputDelay\[$clock\]  "=percent_of_period 20"                  
set_port_attribute arqos_m5          MaxInputDelay\[$clock\]  "=percent_of_period 20"                  
}
set awqosm6 [get_configuration_parameter  AXI_HAS_AWQOS_EXT_M6]
set arqosm6 [get_configuration_parameter  AXI_HAS_ARQOS_EXT_M6]
if  {$awqosm6 == 1} {
set_port_attribute awqos_m6          MinInputDelay\[$clock\]  "=percent_of_period 20"                  
set_port_attribute awqos_m6          MaxInputDelay\[$clock\]  "=percent_of_period 20"                 
}
if  {$arqosm6 == 1} {
set_port_attribute arqos_m6          MinInputDelay\[$clock\]  "=percent_of_period 20"                  
set_port_attribute arqos_m6          MaxInputDelay\[$clock\]  "=percent_of_period 20"                  
}
set awqosm7 [get_configuration_parameter  AXI_HAS_AWQOS_EXT_M7]
set arqosm7 [get_configuration_parameter  AXI_HAS_ARQOS_EXT_M7]
if  {$awqosm7 == 1} {
set_port_attribute awqos_m7          MinInputDelay\[$clock\]  "=percent_of_period 20"                  
set_port_attribute awqos_m7          MaxInputDelay\[$clock\]  "=percent_of_period 20"                  
}
if  {$arqosm7 == 1} {
set_port_attribute arqos_m7          MinInputDelay\[$clock\]  "=percent_of_period 20"                  
set_port_attribute arqos_m7          MaxInputDelay\[$clock\]  "=percent_of_period 20"                  
}
set awqosm8 [get_configuration_parameter  AXI_HAS_AWQOS_EXT_M8]
set arqosm8 [get_configuration_parameter  AXI_HAS_ARQOS_EXT_M8]
if  {$awqosm8 == 1} {
set_port_attribute awqos_m8          MinInputDelay\[$clock\]  "=percent_of_period 20"                  
set_port_attribute awqos_m8          MaxInputDelay\[$clock\]  "=percent_of_period 20"                  
}
if  {$arqosm8 == 1} {
set_port_attribute arqos_m8          MinInputDelay\[$clock\]  "=percent_of_period 20"                  
set_port_attribute arqos_m8          MaxInputDelay\[$clock\]  "=percent_of_period 20"                  
}
set awqosm9 [get_configuration_parameter  AXI_HAS_AWQOS_EXT_M9]
set arqosm9 [get_configuration_parameter  AXI_HAS_ARQOS_EXT_M9]
if  {$awqosm9 == 1} {
set_port_attribute awqos_m9          MinInputDelay\[$clock\]  "=percent_of_period 20"                  
set_port_attribute awqos_m9          MaxInputDelay\[$clock\]  "=percent_of_period 20"                  
}
if  {$arqosm9 == 1} {
set_port_attribute arqos_m9          MinInputDelay\[$clock\]  "=percent_of_period 20"                  
set_port_attribute arqos_m9          MaxInputDelay\[$clock\]  "=percent_of_period 20"                  
}
set awqosm10 [get_configuration_parameter  AXI_HAS_AWQOS_EXT_M10]
set arqosm10 [get_configuration_parameter  AXI_HAS_ARQOS_EXT_M10]
if  {$awqosm10 == 1} {
set_port_attribute awqos_m10          MinInputDelay\[$clock\]  "=percent_of_period 20"                  
set_port_attribute awqos_m10          MaxInputDelay\[$clock\]  "=percent_of_period 20"                  
}
if  {$arqosm10 == 1} {
set_port_attribute arqos_m10          MinInputDelay\[$clock\]  "=percent_of_period 20"                  
set_port_attribute arqos_m10          MaxInputDelay\[$clock\]  "=percent_of_period 20"                  
}
set awqosm11 [get_configuration_parameter  AXI_HAS_AWQOS_EXT_M11]
set arqosm11 [get_configuration_parameter  AXI_HAS_ARQOS_EXT_M11]
if  {$awqosm11 == 1} {
set_port_attribute awqos_m11          MinInputDelay\[$clock\]  "=percent_of_period 20"                  
set_port_attribute awqos_m11          MaxInputDelay\[$clock\]  "=percent_of_period 20"                  
}
if  {$arqosm11 == 1} {
set_port_attribute arqos_m11          MinInputDelay\[$clock\]  "=percent_of_period 20"                  
set_port_attribute arqos_m11          MaxInputDelay\[$clock\]  "=percent_of_period 20"                  
}
set awqosm12 [get_configuration_parameter  AXI_HAS_AWQOS_EXT_M12]
set arqosm12 [get_configuration_parameter  AXI_HAS_ARQOS_EXT_M12]
if  {$awqosm12 == 1} {
set_port_attribute awqos_m12          MinInputDelay\[$clock\]  "=percent_of_period 20"                  
set_port_attribute awqos_m12          MaxInputDelay\[$clock\]  "=percent_of_period 20"                  
}
if  {$arqosm12 == 1} {
set_port_attribute arqos_m12          MinInputDelay\[$clock\]  "=percent_of_period 20"                  
set_port_attribute arqos_m12          MaxInputDelay\[$clock\]  "=percent_of_period 20"                  
}
set awqosm13 [get_configuration_parameter  AXI_HAS_AWQOS_EXT_M13]
set arqosm13 [get_configuration_parameter  AXI_HAS_ARQOS_EXT_M13]
if  {$awqosm13 == 1} {
set_port_attribute awqos_m13          MinInputDelay\[$clock\]  "=percent_of_period 20"                  
set_port_attribute awqos_m13          MaxInputDelay\[$clock\]  "=percent_of_period 20"                  
}
if  {$arqosm13 == 1} {
set_port_attribute arqos_m13          MinInputDelay\[$clock\]  "=percent_of_period 20"                  
set_port_attribute arqos_m13          MaxInputDelay\[$clock\]  "=percent_of_period 20"                  
}
set awqosm14 [get_configuration_parameter  AXI_HAS_AWQOS_EXT_M14]
set arqosm14 [get_configuration_parameter  AXI_HAS_ARQOS_EXT_M14]
if  {$awqosm14 == 1} {
set_port_attribute awqos_m14          MinInputDelay\[$clock\]  "=percent_of_period 20"                  
set_port_attribute awqos_m14          MaxInputDelay\[$clock\]  "=percent_of_period 20"                  
}
if  {$arqosm14 == 1} {
set_port_attribute arqos_m14          MinInputDelay\[$clock\]  "=percent_of_period 20"                  
set_port_attribute arqos_m14          MaxInputDelay\[$clock\]  "=percent_of_period 20"                  
}
set awqosm15 [get_configuration_parameter  AXI_HAS_AWQOS_EXT_M15]
set arqosm15 [get_configuration_parameter  AXI_HAS_ARQOS_EXT_M15]
if  {$awqosm15 == 1} {
set_port_attribute awqos_m15          MinInputDelay\[$clock\]  "=percent_of_period 20"                  
set_port_attribute awqos_m15          MaxInputDelay\[$clock\]  "=percent_of_period 20"                  
}
if  {$awqosm15 == 1} {
set_port_attribute arqos_m15          MinInputDelay\[$clock\]  "=percent_of_period 20"                  
set_port_attribute arqos_m15          MaxInputDelay\[$clock\]  "=percent_of_period 20"                  
}

set sqos [find_item -type port -filter {PortDirection==out} a*qos_s*]
set_port_attribute $sqos MaxOutputDelay\[$clock\] "=percent_of_period 20"
set_port_attribute $sqos MinOutputDelay\[$clock\] "=percent_of_period 20"

}

if {$safety_en == 1} {
  set_port_attribute axi_id_par_intr MaxOutputDelay\[$apbclock\] "=percent_of_period 20"
  set_port_attribute axi_id_par_intr MinOutputDelay\[$apbclock\] "=percent_of_period 20"
}


#*****************************************************************************************
# Constraints - Ayschronous Clock Domain Crossing 
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
#set num_sync_ff [get_configuration_parameter AXI_NUM_SYNC_FF]
#set low_power   [get_configuration_parameter AXI_LOWPWR_HS_IF]
read_sdc -script "set_clock_groups -asynchronous -group aclk -allow_paths"
#
if {$qos_en==1 || $safety_en==1} {
#
  read_sdc -script "set_clock_groups -asynchronous -group pclk -allow_paths"
#
#  #set num_sync_ff_perc  [expr int(($num_sync_ff - 0.5)*100)]
#  #set aclk_num_sync_ff_smdly "=percent_of_period $num_sync_ff_perc aclk"
#  #set pclk_num_sync_ff_smdly "=percent_of_period $num_sync_ff_perc pclk"
#
#  set aclk_num_sync_ff_smdly "=percent_of_period 100 aclk"
#  set pclk_num_sync_ff_smdly "=percent_of_period 100 pclk"
# 
#  set_false_path -from [find_item -type clock pclk] -to [find_item -type clock aclk] -hold
#  set_max_delay -ignore_clock_latency $aclk_num_sync_ff_smdly -from [find_item -type clock pclk] -to [find_item -type clock aclk]
#  set_min_delay -ignore_clock_latency 0 -from [find_item -type clock pclk] -to [find_item -type clock aclk]
#
#  set_false_path -from [find_item -type clock aclk] -to [find_item -type clock pclk] -hold
#  set_max_delay -ignore_clock_latency $pclk_num_sync_ff_smdly -from [find_item -type clock aclk] -to [find_item -type clock pclk]
#  set_min_delay -ignore_clock_latency 0 -from [find_item -type clock aclk] -to [find_item -type clock pclk]

  #set aclk_qual_smdly "=percent_of_period 100 aclk"
  #set pclk_qual_smdly "=percent_of_period 100 pclk"

  #set_max_delay $aclk_qual_smdly -from {U_DW_axi_apbif/U_DW_axi_bcm21_command_en_aclk/data_s*} -to [find_item -type clock aclk]
  #set_max_delay $pclk_qual_smdly -from {U_DW_axi_apbif/U_DW_axi_bcm21_command_en_pclk/data_s*} -to [find_item -type clock pclk]
  #set_max_delay $pclk_qual_smdly -from {U_DW_axi_apbif/U_DW_axi_bcm21_err_bit_pclk/data_s*} -to [find_item -type clock pclk]

  #if {$low_power == 1} {
  #  set_max_delay $aclk_qual_smdly -from {U_DW_axi_apbif/U_DW_axi_bcm21_apb_busy/data_s*} -to [find_item -type clock aclk]
  #}
}


set acelite [get_configuration_parameter AXI_INTERFACE_TYPE]
if {$acelite == 2} {
  set snoop [find_item -type port -filter {PortDirection==in} a*snoop_m*]
  set_port_attribute $snoop MaxInputDelay\[$clock\] "=percent_of_period 20"
  set_port_attribute $snoop MinInputDelay\[$clock\] "=percent_of_period 20"
  set domain [find_item -type port -filter {PortDirection==in} a*domain_m*]
  set_port_attribute $domain MaxInputDelay\[$clock\] "=percent_of_period 20"
  set_port_attribute $domain MinInputDelay\[$clock\] "=percent_of_period 20"
  set bar [find_item -type port -filter {PortDirection==in} a*bar_m*]
  set_port_attribute $bar MaxInputDelay\[$clock\] "=percent_of_period 20"
  set_port_attribute $bar MinInputDelay\[$clock\] "=percent_of_period 20"

  set snoop [find_item -type port -filter {PortDirection==out} a*snoop_s*]
  set_port_attribute $snoop MaxOutputDelay\[$clock\] "=percent_of_period 20"
  set_port_attribute $snoop MinOutputDelay\[$clock\] "=percent_of_period 20"
  set domain [find_item -type port -filter {PortDirection==out} a*domain_s*]
  set_port_attribute $domain MaxOutputDelay\[$clock\] "=percent_of_period 20"
  set_port_attribute $domain MinOutputDelay\[$clock\] "=percent_of_period 20"
  set bar [find_item -type port -filter {PortDirection==out} a*bar_s*]
  set_port_attribute $bar MaxOutputDelay\[$clock\] "=percent_of_period 20"
  set_port_attribute $bar MinOutputDelay\[$clock\] "=percent_of_period 20"
}


set region1 [get_configuration_parameter AXI_HAS_REGIONS_S1]
if {$region1 == 1} {
set sregion1 [find_item -type port -filter {PortDirection==out} a*region_s1]
set_port_attribute $sregion1 MaxOutputDelay\[$clock\] "=percent_of_period 20"
set_port_attribute $sregion1 MinOutputDelay\[$clock\] "=percent_of_period 20"
}
set region2 [get_configuration_parameter AXI_HAS_REGIONS_S2]
if {$region2 == 1} {
set sregion2 [find_item -type port -filter {PortDirection==out} a*region_s2]
set_port_attribute $sregion2 MaxOutputDelay\[$clock\] "=percent_of_period 20"
set_port_attribute $sregion2 MinOutputDelay\[$clock\] "=percent_of_period 20"
}
set region3 [get_configuration_parameter AXI_HAS_REGIONS_S3]
if {$region3 == 1} {
set sregion3 [find_item -type port -filter {PortDirection==out} a*region_s3]
set_port_attribute $sregion3 MaxOutputDelay\[$clock\] "=percent_of_period 20"
set_port_attribute $sregion3 MinOutputDelay\[$clock\] "=percent_of_period 20"
}
set region4 [get_configuration_parameter AXI_HAS_REGIONS_S4]
if {$region4 == 1} {
set sregion4 [find_item -type port -filter {PortDirection==out} a*region_s4]
set_port_attribute $sregion4 MaxOutputDelay\[$clock\] "=percent_of_period 20"
set_port_attribute $sregion4 MinOutputDelay\[$clock\] "=percent_of_period 20"
}
set region5 [get_configuration_parameter AXI_HAS_REGIONS_S5]
if {$region5 == 1} {
set sregion5 [find_item -type port -filter {PortDirection==out} a*region_s5]
set_port_attribute $sregion5 MaxOutputDelay\[$clock\] "=percent_of_period 20"
set_port_attribute $sregion5 MinOutputDelay\[$clock\] "=percent_of_period 20"
}
set region6 [get_configuration_parameter AXI_HAS_REGIONS_S6]
if {$region6 == 1} {
set sregion6 [find_item -type port -filter {PortDirection==out} a*region_s6]
set_port_attribute $sregion6 MaxOutputDelay\[$clock\] "=percent_of_period 20"
set_port_attribute $sregion6 MinOutputDelay\[$clock\] "=percent_of_period 20"
}
set region7 [get_configuration_parameter AXI_HAS_REGIONS_S7]
if {$region7 == 1} {
set sregion7 [find_item -type port -filter {PortDirection==out} a*region_s7]
set_port_attribute $sregion7 MaxOutputDelay\[$clock\] "=percent_of_period 20"
set_port_attribute $sregion7 MinOutputDelay\[$clock\] "=percent_of_period 20"
}
set region8 [get_configuration_parameter AXI_HAS_REGIONS_S8]
if {$region8 == 1} {
set sregion8 [find_item -type port -filter {PortDirection==out} a*region_s8]
set_port_attribute $sregion8 MaxOutputDelay\[$clock\] "=percent_of_period 20"
set_port_attribute $sregion8 MinOutputDelay\[$clock\] "=percent_of_period 20"
}
set region9 [get_configuration_parameter AXI_HAS_REGIONS_S9]
if {$region9 == 1} {
set sregion9 [find_item -type port -filter {PortDirection==out} a*region_s9]
set_port_attribute $sregion9 MaxOutputDelay\[$clock\] "=percent_of_period 20"
set_port_attribute $sregion9 MinOutputDelay\[$clock\] "=percent_of_period 20"
}
set region10 [get_configuration_parameter AXI_HAS_REGIONS_S10]
if {$region10 == 1} {
set sregion10 [find_item -type port -filter {PortDirection==out} a*region_s10]
set_port_attribute $sregion10 MaxOutputDelay\[$clock\] "=percent_of_period 20"
set_port_attribute $sregion10 MinOutputDelay\[$clock\] "=percent_of_period 20"
}
set region11 [get_configuration_parameter AXI_HAS_REGIONS_S11]
if {$region11 == 1} {
set sregion11 [find_item -type port -filter {PortDirection==out} a*region_s11]
set_port_attribute $sregion11 MaxOutputDelay\[$clock\] "=percent_of_period 20"
set_port_attribute $sregion11 MinOutputDelay\[$clock\] "=percent_of_period 20"
}
set region12 [get_configuration_parameter AXI_HAS_REGIONS_S12]
if {$region12 == 1} {
set sregion12 [find_item -type port -filter {PortDirection==out} a*region_s12]
set_port_attribute $sregion12 MaxOutputDelay\[$clock\] "=percent_of_period 20"
set_port_attribute $sregion12 MinOutputDelay\[$clock\] "=percent_of_period 20"
}
set region13 [get_configuration_parameter AXI_HAS_REGIONS_S13]
if {$region13 == 1} {
set sregion13 [find_item -type port -filter {PortDirection==out} a*region_s13]
set_port_attribute $sregion13 MaxOutputDelay\[$clock\] "=percent_of_period 20"
set_port_attribute $sregion13 MinOutputDelay\[$clock\] "=percent_of_period 20"
}
set region14 [get_configuration_parameter AXI_HAS_REGIONS_S14]
if {$region14 == 1} {
set sregion14 [find_item -type port -filter {PortDirection==out} a*region_s14]
set_port_attribute $sregion14 MaxOutputDelay\[$clock\] "=percent_of_period 20"
set_port_attribute $sregion14 MinOutputDelay\[$clock\] "=percent_of_period 20"
}
set region15 [get_configuration_parameter AXI_HAS_REGIONS_S15]
if {$region15 == 1} {
set sregion15 [find_item -type port -filter {PortDirection==out} a*region_s15]
set_port_attribute $sregion15 MaxOutputDelay\[$clock\] "=percent_of_period 20"
set_port_attribute $sregion15 MinOutputDelay\[$clock\] "=percent_of_period 20"
}
set region16 [get_configuration_parameter AXI_HAS_REGIONS_S16]
if {$region16 == 1} {
set sregion16 [find_item -type port -filter {PortDirection==out} a*region_s16]
set_port_attribute $sregion16 MaxOutputDelay\[$clock\] "=percent_of_period 20"
set_port_attribute $sregion16 MinOutputDelay\[$clock\] "=percent_of_period 20"
}
  
# Multi Cycle Arbitration Constraints
set num_msts [get_configuration_parameter AXI_NUM_MASTERS]
set num_slvs [get_configuration_parameter AXI_NUM_SLAVES]

# Store master/slave visibility data in an array.
# Arbitration logic will be removed if there is only 1 client
# to an arbiter so we will not add the multi-cycle arbitration
# constraints in this case, as an error would occur if the 
# constraints were applied after the logic had been optimised away.
set nmv(0) ${num_msts}
set nmv(1) [get_configuration_parameter AXI_NMV_S1]
set nmv(2) [get_configuration_parameter AXI_NMV_S2]
set nmv(3) [get_configuration_parameter AXI_NMV_S3]
set nmv(4) [get_configuration_parameter AXI_NMV_S4]
set nmv(5) [get_configuration_parameter AXI_NMV_S5]
set nmv(6) [get_configuration_parameter AXI_NMV_S6]
set nmv(7) [get_configuration_parameter AXI_NMV_S7]
set nmv(8) [get_configuration_parameter AXI_NMV_S8]
set nmv(9) [get_configuration_parameter AXI_NMV_S9]
set nmv(10) [get_configuration_parameter AXI_NMV_S10]
set nmv(11) [get_configuration_parameter AXI_NMV_S11]
set nmv(12) [get_configuration_parameter AXI_NMV_S12]
set nmv(13) [get_configuration_parameter AXI_NMV_S13]
set nmv(14) [get_configuration_parameter AXI_NMV_S14]
set nmv(15) [get_configuration_parameter AXI_NMV_S15]
set nmv(16) [get_configuration_parameter AXI_NMV_S16]

set nsv(1) [get_configuration_parameter AXI_NSV_M1]
set nsv(2) [get_configuration_parameter AXI_NSV_M2]
set nsv(3) [get_configuration_parameter AXI_NSV_M3]
set nsv(4) [get_configuration_parameter AXI_NSV_M4]
set nsv(5) [get_configuration_parameter AXI_NSV_M5]
set nsv(6) [get_configuration_parameter AXI_NSV_M6]
set nsv(7) [get_configuration_parameter AXI_NSV_M7]
set nsv(8) [get_configuration_parameter AXI_NSV_M8]
set nsv(9) [get_configuration_parameter AXI_NSV_M9]
set nsv(10) [get_configuration_parameter AXI_NSV_M10]
set nsv(11) [get_configuration_parameter AXI_NSV_M11]
set nsv(12) [get_configuration_parameter AXI_NSV_M12]
set nsv(13) [get_configuration_parameter AXI_NSV_M13]
set nsv(14) [get_configuration_parameter AXI_NSV_M14]
set nsv(15) [get_configuration_parameter AXI_NSV_M15]
set nsv(16) [get_configuration_parameter AXI_NSV_M16]

# Need to know if dedicated channels exist before setting constraints on those arbiters.
set ar_on_shrd_only_s(0) [get_configuration_parameter AXI_S0_ON_AR_SHARED_ONLY_VAL]
set ar_on_shrd_only_s(1) [get_configuration_parameter AXI_S1_ON_AR_SHARED_ONLY_VAL]
set ar_on_shrd_only_s(2) [get_configuration_parameter AXI_S2_ON_AR_SHARED_ONLY_VAL]
set ar_on_shrd_only_s(3) [get_configuration_parameter AXI_S3_ON_AR_SHARED_ONLY_VAL]
set ar_on_shrd_only_s(4) [get_configuration_parameter AXI_S4_ON_AR_SHARED_ONLY_VAL]
set ar_on_shrd_only_s(5) [get_configuration_parameter AXI_S5_ON_AR_SHARED_ONLY_VAL]
set ar_on_shrd_only_s(6) [get_configuration_parameter AXI_S6_ON_AR_SHARED_ONLY_VAL]
set ar_on_shrd_only_s(7) [get_configuration_parameter AXI_S7_ON_AR_SHARED_ONLY_VAL]
set ar_on_shrd_only_s(8) [get_configuration_parameter AXI_S8_ON_AR_SHARED_ONLY_VAL]
set ar_on_shrd_only_s(9) [get_configuration_parameter AXI_S9_ON_AR_SHARED_ONLY_VAL]
set ar_on_shrd_only_s(10) [get_configuration_parameter AXI_S10_ON_AR_SHARED_ONLY_VAL]
set ar_on_shrd_only_s(11) [get_configuration_parameter AXI_S11_ON_AR_SHARED_ONLY_VAL]
set ar_on_shrd_only_s(12) [get_configuration_parameter AXI_S12_ON_AR_SHARED_ONLY_VAL]
set ar_on_shrd_only_s(13) [get_configuration_parameter AXI_S13_ON_AR_SHARED_ONLY_VAL]
set ar_on_shrd_only_s(14) [get_configuration_parameter AXI_S14_ON_AR_SHARED_ONLY_VAL]
set ar_on_shrd_only_s(15) [get_configuration_parameter AXI_S15_ON_AR_SHARED_ONLY_VAL]
set ar_on_shrd_only_s(16) [get_configuration_parameter AXI_S16_ON_AR_SHARED_ONLY_VAL]

set aw_on_shrd_only_s(0) [get_configuration_parameter AXI_S0_ON_AW_SHARED_ONLY_VAL]
set aw_on_shrd_only_s(1) [get_configuration_parameter AXI_S1_ON_AW_SHARED_ONLY_VAL]
set aw_on_shrd_only_s(2) [get_configuration_parameter AXI_S2_ON_AW_SHARED_ONLY_VAL]
set aw_on_shrd_only_s(3) [get_configuration_parameter AXI_S3_ON_AW_SHARED_ONLY_VAL]
set aw_on_shrd_only_s(4) [get_configuration_parameter AXI_S4_ON_AW_SHARED_ONLY_VAL]
set aw_on_shrd_only_s(5) [get_configuration_parameter AXI_S5_ON_AW_SHARED_ONLY_VAL]
set aw_on_shrd_only_s(6) [get_configuration_parameter AXI_S6_ON_AW_SHARED_ONLY_VAL]
set aw_on_shrd_only_s(7) [get_configuration_parameter AXI_S7_ON_AW_SHARED_ONLY_VAL]
set aw_on_shrd_only_s(8) [get_configuration_parameter AXI_S8_ON_AW_SHARED_ONLY_VAL]
set aw_on_shrd_only_s(9) [get_configuration_parameter AXI_S9_ON_AW_SHARED_ONLY_VAL]
set aw_on_shrd_only_s(10) [get_configuration_parameter AXI_S10_ON_AW_SHARED_ONLY_VAL]
set aw_on_shrd_only_s(11) [get_configuration_parameter AXI_S11_ON_AW_SHARED_ONLY_VAL]
set aw_on_shrd_only_s(12) [get_configuration_parameter AXI_S12_ON_AW_SHARED_ONLY_VAL]
set aw_on_shrd_only_s(13) [get_configuration_parameter AXI_S13_ON_AW_SHARED_ONLY_VAL]
set aw_on_shrd_only_s(14) [get_configuration_parameter AXI_S14_ON_AW_SHARED_ONLY_VAL]
set aw_on_shrd_only_s(15) [get_configuration_parameter AXI_S15_ON_AW_SHARED_ONLY_VAL]
set aw_on_shrd_only_s(16) [get_configuration_parameter AXI_S16_ON_AW_SHARED_ONLY_VAL]

set w_on_shrd_only_s(0) [get_configuration_parameter AXI_S0_ON_W_SHARED_ONLY_VAL]
set w_on_shrd_only_s(1) [get_configuration_parameter AXI_S1_ON_W_SHARED_ONLY_VAL]
set w_on_shrd_only_s(2) [get_configuration_parameter AXI_S2_ON_W_SHARED_ONLY_VAL]
set w_on_shrd_only_s(3) [get_configuration_parameter AXI_S3_ON_W_SHARED_ONLY_VAL]
set w_on_shrd_only_s(4) [get_configuration_parameter AXI_S4_ON_W_SHARED_ONLY_VAL]
set w_on_shrd_only_s(5) [get_configuration_parameter AXI_S5_ON_W_SHARED_ONLY_VAL]
set w_on_shrd_only_s(6) [get_configuration_parameter AXI_S6_ON_W_SHARED_ONLY_VAL]
set w_on_shrd_only_s(7) [get_configuration_parameter AXI_S7_ON_W_SHARED_ONLY_VAL]
set w_on_shrd_only_s(8) [get_configuration_parameter AXI_S8_ON_W_SHARED_ONLY_VAL]
set w_on_shrd_only_s(9) [get_configuration_parameter AXI_S9_ON_W_SHARED_ONLY_VAL]
set w_on_shrd_only_s(10) [get_configuration_parameter AXI_S10_ON_W_SHARED_ONLY_VAL]
set w_on_shrd_only_s(11) [get_configuration_parameter AXI_S11_ON_W_SHARED_ONLY_VAL]
set w_on_shrd_only_s(12) [get_configuration_parameter AXI_S12_ON_W_SHARED_ONLY_VAL]
set w_on_shrd_only_s(13) [get_configuration_parameter AXI_S13_ON_W_SHARED_ONLY_VAL]
set w_on_shrd_only_s(14) [get_configuration_parameter AXI_S14_ON_W_SHARED_ONLY_VAL]
set w_on_shrd_only_s(15) [get_configuration_parameter AXI_S15_ON_W_SHARED_ONLY_VAL]
set w_on_shrd_only_s(16) [get_configuration_parameter AXI_S16_ON_W_SHARED_ONLY_VAL]

set r_on_shrd_only_m(1) [get_configuration_parameter AXI_M1_ON_R_SHARED_ONLY_VAL]
set r_on_shrd_only_m(2) [get_configuration_parameter AXI_M2_ON_R_SHARED_ONLY_VAL]
set r_on_shrd_only_m(3) [get_configuration_parameter AXI_M3_ON_R_SHARED_ONLY_VAL]
set r_on_shrd_only_m(4) [get_configuration_parameter AXI_M4_ON_R_SHARED_ONLY_VAL]
set r_on_shrd_only_m(5) [get_configuration_parameter AXI_M5_ON_R_SHARED_ONLY_VAL]
set r_on_shrd_only_m(6) [get_configuration_parameter AXI_M6_ON_R_SHARED_ONLY_VAL]
set r_on_shrd_only_m(7) [get_configuration_parameter AXI_M7_ON_R_SHARED_ONLY_VAL]
set r_on_shrd_only_m(8) [get_configuration_parameter AXI_M8_ON_R_SHARED_ONLY_VAL]
set r_on_shrd_only_m(9) [get_configuration_parameter AXI_M9_ON_R_SHARED_ONLY_VAL]
set r_on_shrd_only_m(10) [get_configuration_parameter AXI_M10_ON_R_SHARED_ONLY_VAL]
set r_on_shrd_only_m(11) [get_configuration_parameter AXI_M11_ON_R_SHARED_ONLY_VAL]
set r_on_shrd_only_m(12) [get_configuration_parameter AXI_M12_ON_R_SHARED_ONLY_VAL]
set r_on_shrd_only_m(13) [get_configuration_parameter AXI_M13_ON_R_SHARED_ONLY_VAL]
set r_on_shrd_only_m(14) [get_configuration_parameter AXI_M14_ON_R_SHARED_ONLY_VAL]
set r_on_shrd_only_m(15) [get_configuration_parameter AXI_M15_ON_R_SHARED_ONLY_VAL]
set r_on_shrd_only_m(16) [get_configuration_parameter AXI_M16_ON_R_SHARED_ONLY_VAL]

set b_on_shrd_only_m(1) [get_configuration_parameter AXI_M1_ON_B_SHARED_ONLY_VAL]
set b_on_shrd_only_m(2) [get_configuration_parameter AXI_M2_ON_B_SHARED_ONLY_VAL]
set b_on_shrd_only_m(3) [get_configuration_parameter AXI_M3_ON_B_SHARED_ONLY_VAL]
set b_on_shrd_only_m(4) [get_configuration_parameter AXI_M4_ON_B_SHARED_ONLY_VAL]
set b_on_shrd_only_m(5) [get_configuration_parameter AXI_M5_ON_B_SHARED_ONLY_VAL]
set b_on_shrd_only_m(6) [get_configuration_parameter AXI_M6_ON_B_SHARED_ONLY_VAL]
set b_on_shrd_only_m(7) [get_configuration_parameter AXI_M7_ON_B_SHARED_ONLY_VAL]
set b_on_shrd_only_m(8) [get_configuration_parameter AXI_M8_ON_B_SHARED_ONLY_VAL]
set b_on_shrd_only_m(9) [get_configuration_parameter AXI_M9_ON_B_SHARED_ONLY_VAL]
set b_on_shrd_only_m(10) [get_configuration_parameter AXI_M10_ON_B_SHARED_ONLY_VAL]
set b_on_shrd_only_m(11) [get_configuration_parameter AXI_M11_ON_B_SHARED_ONLY_VAL]
set b_on_shrd_only_m(12) [get_configuration_parameter AXI_M12_ON_B_SHARED_ONLY_VAL]
set b_on_shrd_only_m(13) [get_configuration_parameter AXI_M13_ON_B_SHARED_ONLY_VAL]
set b_on_shrd_only_m(14) [get_configuration_parameter AXI_M14_ON_B_SHARED_ONLY_VAL]
set b_on_shrd_only_m(15) [get_configuration_parameter AXI_M15_ON_B_SHARED_ONLY_VAL]
set b_on_shrd_only_m(16) [get_configuration_parameter AXI_M16_ON_B_SHARED_ONLY_VAL]


for { set i 0 } { $i <= ${num_slvs} } {incr i } {
set on_shrd_only $ar_on_shrd_only_s($i)

  set setup_time [get_configuration_parameter AXI_AR_MCA_NC_S${i}]
  set arb_type [get_configuration_parameter AXI_AR_ARB_TYPE_S${i}] 
  set hold_time [expr ${setup_time} - 1 ]


  if { ($nmv($i) > 1) && ($setup_time > 1) & ($on_shrd_only == 0) } {
    if { ($arb_type == 1) } {
    set_multicycle_path -setup $setup_time     -from "U_DW_axi_sp_s${i}/gen_ar_addrch.U_AR_DW_axi_sp_addrch/U_DW_axi_sp_lockarb/U_DW_axi_arb/U_DW_axi_mca_reqhold/bus_req_r*            U_DW_axi_sp_s${i}/gen_ar_addrch.U_AR_DW_axi_sp_addrch/U_DW_axi_sp_lockarb/U_DW_axi_arb/U_DW_axi_mca_reqhold/bus_prior_r*            U_DW_axi_sp_s${i}/gen_ar_addrch.U_AR_DW_axi_sp_addrch/U_DW_axi_sp_lockarb/U_DW_axi_arb/gen_arb_type_fcfs.U_DW_axi_arbiter_fcfs/priority_ff*" 	       -to   "U_DW_axi_sp_s${i}/gen_ar_addrch.U_AR_DW_axi_sp_addrch/U_DW_axi_sp_lockarb/U_DW_axi_arb/U_DW_axi_arbpl/grant_index_r*            U_DW_axi_sp_s${i}/gen_ar_addrch.U_AR_DW_axi_sp_addrch/U_DW_axi_sp_lockarb/U_DW_axi_arb/U_DW_axi_arbpl/bus_grant_r*            U_DW_axi_sp_s${i}/gen_ar_addrch.U_AR_DW_axi_sp_addrch/U_DW_axi_sp_lockarb/U_DW_axi_arb/U_DW_axi_arbpl/grant_r*
           U_DW_axi_sp_s${i}/gen_ar_addrch.U_AR_DW_axi_sp_addrch/U_DW_axi_sp_lockarb/U_DW_axi_arb/gen_arb_type_fcfs.U_DW_axi_arbiter_fcfs/priority_ff*"


    set_multicycle_path -hold $hold_time     -from "U_DW_axi_sp_s${i}/gen_ar_addrch.U_AR_DW_axi_sp_addrch/U_DW_axi_sp_lockarb/U_DW_axi_arb/U_DW_axi_mca_reqhold/bus_req_r*            U_DW_axi_sp_s${i}/gen_ar_addrch.U_AR_DW_axi_sp_addrch/U_DW_axi_sp_lockarb/U_DW_axi_arb/U_DW_axi_mca_reqhold/bus_prior_r*            U_DW_axi_sp_s${i}/gen_ar_addrch.U_AR_DW_axi_sp_addrch/U_DW_axi_sp_lockarb/U_DW_axi_arb/gen_arb_type_fcfs.U_DW_axi_arbiter_fcfs/priority_ff*" 	       -to   "U_DW_axi_sp_s${i}/gen_ar_addrch.U_AR_DW_axi_sp_addrch/U_DW_axi_sp_lockarb/U_DW_axi_arb/U_DW_axi_arbpl/grant_index_r*            U_DW_axi_sp_s${i}/gen_ar_addrch.U_AR_DW_axi_sp_addrch/U_DW_axi_sp_lockarb/U_DW_axi_arb/U_DW_axi_arbpl/bus_grant_r*            U_DW_axi_sp_s${i}/gen_ar_addrch.U_AR_DW_axi_sp_addrch/U_DW_axi_sp_lockarb/U_DW_axi_arb/U_DW_axi_arbpl/grant_r*
           U_DW_axi_sp_s${i}/gen_ar_addrch.U_AR_DW_axi_sp_addrch/U_DW_axi_sp_lockarb/U_DW_axi_arb/gen_arb_type_fcfs.U_DW_axi_arbiter_fcfs/priority_ff*"  
    } else {
      if { ($arb_type == 2) } {
    set_multicycle_path -setup $setup_time     -from "U_DW_axi_sp_s${i}/gen_ar_addrch.U_AR_DW_axi_sp_addrch/U_DW_axi_sp_lockarb/U_DW_axi_arb/U_DW_axi_mca_reqhold/bus_req_r*            U_DW_axi_sp_s${i}/gen_ar_addrch.U_AR_DW_axi_sp_addrch/U_DW_axi_sp_lockarb/U_DW_axi_arb/U_DW_axi_mca_reqhold/bus_prior_r*            U_DW_axi_sp_s${i}/gen_ar_addrch.U_AR_DW_axi_sp_addrch/U_DW_axi_sp_lockarb/U_DW_axi_arb/gen_arb_type_2t.U_DW_axi_arbiter_fae/int_priority*" 	       -to   "U_DW_axi_sp_s${i}/gen_ar_addrch.U_AR_DW_axi_sp_addrch/U_DW_axi_sp_lockarb/U_DW_axi_arb/U_DW_axi_arbpl/grant_index_r*            U_DW_axi_sp_s${i}/gen_ar_addrch.U_AR_DW_axi_sp_addrch/U_DW_axi_sp_lockarb/U_DW_axi_arb/U_DW_axi_arbpl/bus_grant_r*            U_DW_axi_sp_s${i}/gen_ar_addrch.U_AR_DW_axi_sp_addrch/U_DW_axi_sp_lockarb/U_DW_axi_arb/U_DW_axi_arbpl/grant_r*
           U_DW_axi_sp_s${i}/gen_ar_addrch.U_AR_DW_axi_sp_addrch/U_DW_axi_sp_lockarb/U_DW_axi_arb/gen_arb_type_2t.U_DW_axi_arbiter_fae/int_priority*"


    set_multicycle_path -hold $hold_time     -from "U_DW_axi_sp_s${i}/gen_ar_addrch.U_AR_DW_axi_sp_addrch/U_DW_axi_sp_lockarb/U_DW_axi_arb/U_DW_axi_mca_reqhold/bus_req_r*            U_DW_axi_sp_s${i}/gen_ar_addrch.U_AR_DW_axi_sp_addrch/U_DW_axi_sp_lockarb/U_DW_axi_arb/U_DW_axi_mca_reqhold/bus_prior_r*            U_DW_axi_sp_s${i}/gen_ar_addrch.U_AR_DW_axi_sp_addrch/U_DW_axi_sp_lockarb/U_DW_axi_arb/gen_arb_type_2t.U_DW_axi_arbiter_fae/int_priority*" 	       -to   "U_DW_axi_sp_s${i}/gen_ar_addrch.U_AR_DW_axi_sp_addrch/U_DW_axi_sp_lockarb/U_DW_axi_arb/U_DW_axi_arbpl/grant_index_r*            U_DW_axi_sp_s${i}/gen_ar_addrch.U_AR_DW_axi_sp_addrch/U_DW_axi_sp_lockarb/U_DW_axi_arb/U_DW_axi_arbpl/bus_grant_r*            U_DW_axi_sp_s${i}/gen_ar_addrch.U_AR_DW_axi_sp_addrch/U_DW_axi_sp_lockarb/U_DW_axi_arb/U_DW_axi_arbpl/grant_r*
           U_DW_axi_sp_s${i}/gen_ar_addrch.U_AR_DW_axi_sp_addrch/U_DW_axi_sp_lockarb/U_DW_axi_arb/gen_arb_type_2t.U_DW_axi_arbiter_fae/int_priority*"  
      } else {
    set_multicycle_path -setup $setup_time     -from "U_DW_axi_sp_s${i}/gen_ar_addrch.U_AR_DW_axi_sp_addrch/U_DW_axi_sp_lockarb/U_DW_axi_arb/U_DW_axi_mca_reqhold/bus_req_r*            U_DW_axi_sp_s${i}/gen_ar_addrch.U_AR_DW_axi_sp_addrch/U_DW_axi_sp_lockarb/U_DW_axi_arb/U_DW_axi_mca_reqhold/bus_prior_r*" 	       -to   "U_DW_axi_sp_s${i}/gen_ar_addrch.U_AR_DW_axi_sp_addrch/U_DW_axi_sp_lockarb/U_DW_axi_arb/U_DW_axi_arbpl/grant_index_r*            U_DW_axi_sp_s${i}/gen_ar_addrch.U_AR_DW_axi_sp_addrch/U_DW_axi_sp_lockarb/U_DW_axi_arb/U_DW_axi_arbpl/bus_grant_r*            U_DW_axi_sp_s${i}/gen_ar_addrch.U_AR_DW_axi_sp_addrch/U_DW_axi_sp_lockarb/U_DW_axi_arb/U_DW_axi_arbpl/grant_r*"


    set_multicycle_path -hold $hold_time     -from "U_DW_axi_sp_s${i}/gen_ar_addrch.U_AR_DW_axi_sp_addrch/U_DW_axi_sp_lockarb/U_DW_axi_arb/U_DW_axi_mca_reqhold/bus_req_r*            U_DW_axi_sp_s${i}/gen_ar_addrch.U_AR_DW_axi_sp_addrch/U_DW_axi_sp_lockarb/U_DW_axi_arb/U_DW_axi_mca_reqhold/bus_prior_r*" 	       -to   "U_DW_axi_sp_s${i}/gen_ar_addrch.U_AR_DW_axi_sp_addrch/U_DW_axi_sp_lockarb/U_DW_axi_arb/U_DW_axi_arbpl/grant_index_r*            U_DW_axi_sp_s${i}/gen_ar_addrch.U_AR_DW_axi_sp_addrch/U_DW_axi_sp_lockarb/U_DW_axi_arb/U_DW_axi_arbpl/bus_grant_r*            U_DW_axi_sp_s${i}/gen_ar_addrch.U_AR_DW_axi_sp_addrch/U_DW_axi_sp_lockarb/U_DW_axi_arb/U_DW_axi_arbpl/grant_r*"  
      } 
    }
  }
    
set on_shrd_only $aw_on_shrd_only_s($i)

  set setup_time [get_configuration_parameter AXI_AW_MCA_NC_S${i}]
  set arb_type [get_configuration_parameter AXI_AW_ARB_TYPE_S${i}] 
  set hold_time [expr ${setup_time} - 1 ]


  if { ($nmv($i) > 1) && ($setup_time > 1) & ($on_shrd_only == 0) } {
    if { ($arb_type == 1) } {
    set_multicycle_path -setup $setup_time     -from "U_DW_axi_sp_s${i}/gen_aw_addrch.U_AW_DW_axi_sp_addrch/U_DW_axi_sp_lockarb/U_DW_axi_arb/U_DW_axi_mca_reqhold/bus_req_r*            U_DW_axi_sp_s${i}/gen_aw_addrch.U_AW_DW_axi_sp_addrch/U_DW_axi_sp_lockarb/U_DW_axi_arb/U_DW_axi_mca_reqhold/bus_prior_r*            U_DW_axi_sp_s${i}/gen_aw_addrch.U_AW_DW_axi_sp_addrch/U_DW_axi_sp_lockarb/U_DW_axi_arb/gen_arb_type_fcfs.U_DW_axi_arbiter_fcfs/priority_ff*" 	       -to   "U_DW_axi_sp_s${i}/gen_aw_addrch.U_AW_DW_axi_sp_addrch/U_DW_axi_sp_lockarb/U_DW_axi_arb/U_DW_axi_arbpl/grant_index_r*            U_DW_axi_sp_s${i}/gen_aw_addrch.U_AW_DW_axi_sp_addrch/U_DW_axi_sp_lockarb/U_DW_axi_arb/U_DW_axi_arbpl/bus_grant_r*            U_DW_axi_sp_s${i}/gen_aw_addrch.U_AW_DW_axi_sp_addrch/U_DW_axi_sp_lockarb/U_DW_axi_arb/U_DW_axi_arbpl/grant_r*
           U_DW_axi_sp_s${i}/gen_aw_addrch.U_AW_DW_axi_sp_addrch/U_DW_axi_sp_lockarb/U_DW_axi_arb/gen_arb_type_fcfs.U_DW_axi_arbiter_fcfs/priority_ff*"


    set_multicycle_path -hold $hold_time     -from "U_DW_axi_sp_s${i}/gen_aw_addrch.U_AW_DW_axi_sp_addrch/U_DW_axi_sp_lockarb/U_DW_axi_arb/U_DW_axi_mca_reqhold/bus_req_r*           U_DW_axi_sp_s${i}/gen_aw_addrch.U_AW_DW_axi_sp_addrch/U_DW_axi_sp_lockarb/U_DW_axi_arb/U_DW_axi_mca_reqhold/bus_prior_r*            U_DW_axi_sp_s${i}/gen_aw_addrch.U_AW_DW_axi_sp_addrch/U_DW_axi_sp_lockarb/U_DW_axi_arb/gen_arb_type_fcfs.U_DW_axi_arbiter_fcfs/priority_ff*" 	       -to   "U_DW_axi_sp_s${i}/gen_aw_addrch.U_AW_DW_axi_sp_addrch/U_DW_axi_sp_lockarb/U_DW_axi_arb/U_DW_axi_arbpl/grant_index_r*            U_DW_axi_sp_s${i}/gen_aw_addrch.U_AW_DW_axi_sp_addrch/U_DW_axi_sp_lockarb/U_DW_axi_arb/U_DW_axi_arbpl/bus_grant_r*            U_DW_axi_sp_s${i}/gen_aw_addrch.U_AW_DW_axi_sp_addrch/U_DW_axi_sp_lockarb/U_DW_axi_arb/U_DW_axi_arbpl/grant_r*
           U_DW_axi_sp_s${i}/gen_aw_addrch.U_AW_DW_axi_sp_addrch/U_DW_axi_sp_lockarb/U_DW_axi_arb/gen_arb_type_fcfs.U_DW_axi_arbiter_fcfs/priority_ff*"   
    } else {
      if { ($arb_type == 2) } { 
    set_multicycle_path -setup $setup_time     -from "U_DW_axi_sp_s${i}/gen_aw_addrch.U_AW_DW_axi_sp_addrch/U_DW_axi_sp_lockarb/U_DW_axi_arb/U_DW_axi_mca_reqhold/bus_req_r*            U_DW_axi_sp_s${i}/gen_aw_addrch.U_AW_DW_axi_sp_addrch/U_DW_axi_sp_lockarb/U_DW_axi_arb/U_DW_axi_mca_reqhold/bus_prior_r*            U_DW_axi_sp_s${i}/gen_aw_addrch.U_AW_DW_axi_sp_addrch/U_DW_axi_sp_lockarb/U_DW_axi_arb/gen_arb_type_2t.U_DW_axi_arbiter_fae/int_priority*" 	       -to   "U_DW_axi_sp_s${i}/gen_aw_addrch.U_AW_DW_axi_sp_addrch/U_DW_axi_sp_lockarb/U_DW_axi_arb/U_DW_axi_arbpl/grant_index_r*            U_DW_axi_sp_s${i}/gen_aw_addrch.U_AW_DW_axi_sp_addrch/U_DW_axi_sp_lockarb/U_DW_axi_arb/U_DW_axi_arbpl/bus_grant_r*            U_DW_axi_sp_s${i}/gen_aw_addrch.U_AW_DW_axi_sp_addrch/U_DW_axi_sp_lockarb/U_DW_axi_arb/U_DW_axi_arbpl/grant_r*
           U_DW_axi_sp_s${i}/gen_aw_addrch.U_AW_DW_axi_sp_addrch/U_DW_axi_sp_lockarb/U_DW_axi_arb/gen_arb_type_2t.U_DW_axi_arbiter_fae/int_priority*"


    set_multicycle_path -hold $hold_time     -from "U_DW_axi_sp_s${i}/gen_aw_addrch.U_AW_DW_axi_sp_addrch/U_DW_axi_sp_lockarb/U_DW_axi_arb/U_DW_axi_mca_reqhold/bus_req_r*           U_DW_axi_sp_s${i}/gen_aw_addrch.U_AW_DW_axi_sp_addrch/U_DW_axi_sp_lockarb/U_DW_axi_arb/U_DW_axi_mca_reqhold/bus_prior_r*            U_DW_axi_sp_s${i}/gen_aw_addrch.U_AW_DW_axi_sp_addrch/U_DW_axi_sp_lockarb/U_DW_axi_arb/gen_arb_type_2t.U_DW_axi_arbiter_fae/int_priority*" 	       -to   "U_DW_axi_sp_s${i}/gen_aw_addrch.U_AW_DW_axi_sp_addrch/U_DW_axi_sp_lockarb/U_DW_axi_arb/U_DW_axi_arbpl/grant_index_r*            U_DW_axi_sp_s${i}/gen_aw_addrch.U_AW_DW_axi_sp_addrch/U_DW_axi_sp_lockarb/U_DW_axi_arb/U_DW_axi_arbpl/bus_grant_r*            U_DW_axi_sp_s${i}/gen_aw_addrch.U_AW_DW_axi_sp_addrch/U_DW_axi_sp_lockarb/U_DW_axi_arb/U_DW_axi_arbpl/grant_r*
           U_DW_axi_sp_s${i}/gen_aw_addrch.U_AW_DW_axi_sp_addrch/U_DW_axi_sp_lockarb/U_DW_axi_arb/gen_arb_type_2t.U_DW_axi_arbiter_fae/int_priority*"   
      } else { 
    set_multicycle_path -setup $setup_time     -from "U_DW_axi_sp_s${i}/gen_aw_addrch.U_AW_DW_axi_sp_addrch/U_DW_axi_sp_lockarb/U_DW_axi_arb/U_DW_axi_mca_reqhold/bus_req_r*            U_DW_axi_sp_s${i}/gen_aw_addrch.U_AW_DW_axi_sp_addrch/U_DW_axi_sp_lockarb/U_DW_axi_arb/U_DW_axi_mca_reqhold/bus_prior_r*" 	       -to   "U_DW_axi_sp_s${i}/gen_aw_addrch.U_AW_DW_axi_sp_addrch/U_DW_axi_sp_lockarb/U_DW_axi_arb/U_DW_axi_arbpl/grant_index_r*            U_DW_axi_sp_s${i}/gen_aw_addrch.U_AW_DW_axi_sp_addrch/U_DW_axi_sp_lockarb/U_DW_axi_arb/U_DW_axi_arbpl/bus_grant_r*            U_DW_axi_sp_s${i}/gen_aw_addrch.U_AW_DW_axi_sp_addrch/U_DW_axi_sp_lockarb/U_DW_axi_arb/U_DW_axi_arbpl/grant_r*"


    set_multicycle_path -hold $hold_time     -from "U_DW_axi_sp_s${i}/gen_aw_addrch.U_AW_DW_axi_sp_addrch/U_DW_axi_sp_lockarb/U_DW_axi_arb/U_DW_axi_mca_reqhold/bus_req_r*           U_DW_axi_sp_s${i}/gen_aw_addrch.U_AW_DW_axi_sp_addrch/U_DW_axi_sp_lockarb/U_DW_axi_arb/U_DW_axi_mca_reqhold/bus_prior_r*" 	       -to   "U_DW_axi_sp_s${i}/gen_aw_addrch.U_AW_DW_axi_sp_addrch/U_DW_axi_sp_lockarb/U_DW_axi_arb/U_DW_axi_arbpl/grant_index_r*            U_DW_axi_sp_s${i}/gen_aw_addrch.U_AW_DW_axi_sp_addrch/U_DW_axi_sp_lockarb/U_DW_axi_arb/U_DW_axi_arbpl/bus_grant_r*            U_DW_axi_sp_s${i}/gen_aw_addrch.U_AW_DW_axi_sp_addrch/U_DW_axi_sp_lockarb/U_DW_axi_arb/U_DW_axi_arbpl/grant_r*"   
      }
    } 
  }
    

  set setup_time [get_configuration_parameter AXI_W_MCA_NC_S${i}]
  set hold_time [expr  ${setup_time} - 1 ]
  set arb_type [get_configuration_parameter AXI_W_ARB_TYPE_S${i}] 
  set on_shrd_only $w_on_shrd_only_s($i)


  if { ($nmv($i) > 1) && ($setup_time > 1) & ($on_shrd_only == 0)} {
    if { ($arb_type == 1) } {
    set_multicycle_path -setup $setup_time     -from "U_DW_axi_sp_s${i}/gen_w_datach.U_W_DW_axi_sp_wdatach/U_DW_axi_arb/U_DW_axi_mca_reqhold/bus_req_r*            U_DW_axi_sp_s${i}/gen_w_datach.U_W_DW_axi_sp_wdatach/U_DW_axi_arb/U_DW_axi_mca_reqhold/bus_prior_r*            U_DW_axi_sp_s${i}/gen_w_datach.U_W_DW_axi_sp_wdatach/U_DW_axi_arb/gen_arb_type_fcfs.U_DW_axi_arbiter_fcfs/priority_ff*" 	       -to   "U_DW_axi_sp_s${i}/gen_w_datach.U_W_DW_axi_sp_wdatach/U_DW_axi_arb/U_DW_axi_arbpl/grant_index_r*            U_DW_axi_sp_s${i}/gen_w_datach.U_W_DW_axi_sp_wdatach/U_DW_axi_arb/U_DW_axi_arbpl/bus_grant_r*            U_DW_axi_sp_s${i}/gen_w_datach.U_W_DW_axi_sp_wdatach/U_DW_axi_arb/U_DW_axi_arbpl/grant_r*
           U_DW_axi_sp_s${i}/gen_w_datach.U_W_DW_axi_sp_wdatach/U_DW_axi_arb/gen_arb_type_fcfs.U_DW_axi_arbiter_fcfs/priority_ff*"


    set_multicycle_path -hold $hold_time     -from "U_DW_axi_sp_s${i}/gen_w_datach.U_W_DW_axi_sp_wdatach/U_DW_axi_arb/U_DW_axi_mca_reqhold/bus_req_r*            U_DW_axi_sp_s${i}/gen_w_datach.U_W_DW_axi_sp_wdatach/U_DW_axi_arb/U_DW_axi_mca_reqhold/bus_prior_r*           U_DW_axi_sp_s${i}/gen_w_datach.U_W_DW_axi_sp_wdatach/U_DW_axi_arb/gen_arb_type_fcfs.U_DW_axi_arbiter_fcfs/priority_ff*" 	       -to   "U_DW_axi_sp_s${i}/gen_w_datach.U_W_DW_axi_sp_wdatach/U_DW_axi_arb/U_DW_axi_arbpl/grant_index_r*            U_DW_axi_sp_s${i}/gen_w_datach.U_W_DW_axi_sp_wdatach/U_DW_axi_arb/U_DW_axi_arbpl/bus_grant_r*            U_DW_axi_sp_s${i}/gen_w_datach.U_W_DW_axi_sp_wdatach/U_DW_axi_arb/U_DW_axi_arbpl/grant_r*
           U_DW_axi_sp_s${i}/gen_w_datach.U_W_DW_axi_sp_wdatach/U_DW_axi_arb/gen_arb_type_fcfs.U_DW_axi_arbiter_fcfs/priority_ff*"  
    } else {
      if { ($arb_type == 2) } {
    set_multicycle_path -setup $setup_time     -from "U_DW_axi_sp_s${i}/gen_w_datach.U_W_DW_axi_sp_wdatach/U_DW_axi_arb/U_DW_axi_mca_reqhold/bus_req_r*            U_DW_axi_sp_s${i}/gen_w_datach.U_W_DW_axi_sp_wdatach/U_DW_axi_arb/U_DW_axi_mca_reqhold/bus_prior_r*            U_DW_axi_sp_s${i}/gen_w_datach.U_W_DW_axi_sp_wdatach/U_DW_axi_arb/gen_arb_type_2t.U_DW_axi_arbiter_fae/int_priority*" 	       -to   "U_DW_axi_sp_s${i}/gen_w_datach.U_W_DW_axi_sp_wdatach/U_DW_axi_arb/U_DW_axi_arbpl/grant_index_r*            U_DW_axi_sp_s${i}/gen_w_datach.U_W_DW_axi_sp_wdatach/U_DW_axi_arb/U_DW_axi_arbpl/bus_grant_r*            U_DW_axi_sp_s${i}/gen_w_datach.U_W_DW_axi_sp_wdatach/U_DW_axi_arb/U_DW_axi_arbpl/grant_r*
           U_DW_axi_sp_s${i}/gen_w_datach.U_W_DW_axi_sp_wdatach/U_DW_axi_arb/gen_arb_type_2t.U_DW_axi_arbiter_fae/int_priority*"


    set_multicycle_path -hold $hold_time     -from "U_DW_axi_sp_s${i}/gen_w_datach.U_W_DW_axi_sp_wdatach/U_DW_axi_arb/U_DW_axi_mca_reqhold/bus_req_r*            U_DW_axi_sp_s${i}/gen_w_datach.U_W_DW_axi_sp_wdatach/U_DW_axi_arb/U_DW_axi_mca_reqhold/bus_prior_r*            U_DW_axi_sp_s${i}/gen_w_datach.U_W_DW_axi_sp_wdatach/U_DW_axi_arb/gen_arb_type_2t.U_DW_axi_arbiter_fae/int_priority*" 	       -to   "U_DW_axi_sp_s${i}/gen_w_datach.U_W_DW_axi_sp_wdatach/U_DW_axi_arb/U_DW_axi_arbpl/grant_index_r*            U_DW_axi_sp_s${i}/gen_w_datach.U_W_DW_axi_sp_wdatach/U_DW_axi_arb/U_DW_axi_arbpl/bus_grant_r*            U_DW_axi_sp_s${i}/gen_w_datach.U_W_DW_axi_sp_wdatach/U_DW_axi_arb/U_DW_axi_arbpl/grant_r*
           U_DW_axi_sp_s${i}/gen_w_datach.U_W_DW_axi_sp_wdatach/U_DW_axi_arb/gen_arb_type_2t.U_DW_axi_arbiter_fae/int_priority*"  
    } else {
    set_multicycle_path -setup $setup_time     -from "U_DW_axi_sp_s${i}/gen_w_datach.U_W_DW_axi_sp_wdatach/U_DW_axi_arb/U_DW_axi_mca_reqhold/bus_req_r*            U_DW_axi_sp_s${i}/gen_w_datach.U_W_DW_axi_sp_wdatach/U_DW_axi_arb/U_DW_axi_mca_reqhold/bus_prior_r*" 	       -to   "U_DW_axi_sp_s${i}/gen_w_datach.U_W_DW_axi_sp_wdatach/U_DW_axi_arb/U_DW_axi_arbpl/grant_index_r*            U_DW_axi_sp_s${i}/gen_w_datach.U_W_DW_axi_sp_wdatach/U_DW_axi_arb/U_DW_axi_arbpl/bus_grant_r*            U_DW_axi_sp_s${i}/gen_w_datach.U_W_DW_axi_sp_wdatach/U_DW_axi_arb/U_DW_axi_arbpl/grant_r*"


    set_multicycle_path -hold $hold_time     -from "U_DW_axi_sp_s${i}/gen_w_datach.U_W_DW_axi_sp_wdatach/U_DW_axi_arb/U_DW_axi_mca_reqhold/bus_req_r*            U_DW_axi_sp_s${i}/gen_w_datach.U_W_DW_axi_sp_wdatach/U_DW_axi_arb/U_DW_axi_mca_reqhold/bus_prior_r*" 	       -to   "U_DW_axi_sp_s${i}/gen_w_datach.U_W_DW_axi_sp_wdatach/U_DW_axi_arb/U_DW_axi_arbpl/grant_index_r*            U_DW_axi_sp_s${i}/gen_w_datach.U_W_DW_axi_sp_wdatach/U_DW_axi_arb/U_DW_axi_arbpl/bus_grant_r*            U_DW_axi_sp_s${i}/gen_w_datach.U_W_DW_axi_sp_wdatach/U_DW_axi_arb/U_DW_axi_arbpl/grant_r*"  
    } 
    } 
  }
}

if {$qos_en==1 || $safety_en==1} {
set_port_attribute pclk DftExistingSignalType ScanClock
set_port_attribute presetn DftExistingSignalType Reset
set_port_attribute presetn DftExistingSignalActiveState 0
}

#####DFT Commands
# The default minimum compression factor is 10. However, it may vary depending
# on the design. For this design it is set to 2. This setting is done to avoid 
# scan compression failures and increase the test coverage of the design.
set_design_attribute ScanCompressionConfiguration " -minimum_compression 2"
set_design_attribute EnableScanCompression 0
set_design_attribute NumberOfScanChains 3
