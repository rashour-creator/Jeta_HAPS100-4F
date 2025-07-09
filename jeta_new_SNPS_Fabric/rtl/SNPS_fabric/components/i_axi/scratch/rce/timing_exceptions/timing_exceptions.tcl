# -------------------------------------------------------------------------------
# 
# Copyright 2001 - 2023 Synopsys, INC.
# 
# This Synopsys IP and all associated documentation are proprietary to
# Synopsys, Inc. and may only be used pursuant to the terms and conditions of a
# written license agreement with Synopsys, Inc. All other use, reproduction,
# modification, or distribution of the Synopsys IP or the associated
# documentation is strictly prohibited.
# Inclusivity & Diversity - Visit SolvNetPlus to read the "Synopsys Statement on
#            Inclusivity and Diversity" (Refer to article 000036315 at
#                        https://solvnetplus.synopsys.com)
# 
# Component Name   : DW_axi
# Component Version: 4.06a
# Release Type     : GA
# Build ID         : 18.26.9.4
# -------------------------------------------------------------------------------


# Filename    : common.tcl
# Description : Common procs and settings used by CDC constraint files


update_timing

namespace eval BCM {

  variable ignore_clock_latency_option "-ignore_clock_latency"
  variable reset_path_option ""
  variable bcm_hier_to_skip ""
  variable bcm_mod_to_skip ""
  variable cmd_list_bcm_all {}
  variable bcm_constrain_input_ports 1

  variable name_attr "name"
  variable template_style 0
  variable cmnts_arr
  # We would like to use different comments for different constraints, but it
  # seems that tools (DC/FC) only apply the last comments on the same path. So,
  # use same comments for both max delay and min delay for now.
  #array set cmnts_arr {
  #  CDC_SYN_02_max {Define set_max_delay of 1 source clock period for Gray-coded signals}
  #  CDC_SYN_02_min {Define set_min_delay of 0 for Gray-coded signals}
  #  CDC_SYN_03_max {Define set_max_delay of (Number of Sync stages - 0.5) x destination clock period for Qualifier-based Data Bus signals}
  #  CDC_SYN_03_min {Define set_min_delay of 0 for Qualifier-based Data Bus signals}
  #  CDC_SYN_04_max {Define set_max_delay of 1 destination clock period for all CDC crossings (excluding Gray-coded and Qualifier-based Data Bus signals)}
  #  CDC_SYN_04_min {Define set_min_delay of 0 for all CDC crossings (excluding Gray-coded and Qualifier-based Data Bus signals)}
  #  CDC_SYN_05     {Define set_false_path -through for quasi-static signals at the output of the Bus Delay components}
  #  MCP_SYN        {Define set_multicycle_path for multi-cycle delay cells}
  #}
  array set cmnts_arr {
    CDC_SYN_02_max {Define set_max_delay of 1 source clock period and set_min_delay of 0 constraints for Gray-coded signals}
    CDC_SYN_02_min {Define set_max_delay of 1 source clock period and set_min_delay of 0 constraints for Gray-coded signals}
    CDC_SYN_03_max {Define set_max_delay of (Number of Sync stages - 0.5) x destination clock period and set_min_delay of 0 constraints for Qualifier-based Data Bus signals}
    CDC_SYN_03_min {Define set_max_delay of (Number of Sync stages - 0.5) x destination clock period and set_min_delay of 0 constraints for Qualifier-based Data Bus signals}
    CDC_SYN_04_max {Define set_max_delay of 1 destination clock period and set_min_delay of 0 constraints for all CDC crossings (excluding Gray-coded and Qualifier-based Data Bus signals)}
    CDC_SYN_04_min {Define set_max_delay of 1 destination clock period and set_min_delay of 0 constraints for all CDC crossings (excluding Gray-coded and Qualifier-based Data Bus signals)}
    CDC_SYN_05     {Define set_false_path -through for quasi-static signals at the output of the Bus Delay components}
    MCP_SYN        {Define set_multicycle_path for multi-cycle delay cells}
  }


  if {($::synopsys_program_name eq "fc_shell") || ($::synopsys_program_name eq "pt_shell")} {
    alias bcm_all_fanin {all_fanin -quiet}
    alias bcm_all_fanout {all_fanout -quiet}
  } else {
    alias bcm_all_fanin {all_fanin}
    alias bcm_all_fanout {all_fanout}
  }

  proc bcm_puts {severity str} {
    set msg_tag "(BcmCdcConstraint)"
    if {$severity eq "DBG"} {
      if {![catch {getenv DWC_BCM_TCL_SNPS_DEBUG}]} {
        puts "$severity: $str $msg_tag"
      }
    } elseif {$severity eq "WARNFST0"} {
      if {![catch {getenv DWC_BCM_WRN_SYNC_NOREG}]} {
        puts "WARN: $str $msg_tag"
      }
    } else {
      puts "$severity: $str $msg_tag"
    }
  }

  proc getBCMClocks { cell_name pin_name } {
    if {[get_pins -quiet $cell_name/$pin_name] eq ""} {
      return ""
    }
    # find all the clocks associated to the pin
    set clks [get_clocks -quiet [get_attribute -quiet [get_pins -quiet $cell_name/$pin_name] clocks]]
    if { [sizeof_collection $clks] == 0 } {
      # second try for compiled netlist where clock attribute only exists in leaf pins
      set pins [bcm_all_fanout -from $cell_name/$pin_name -endpoints_only -flat]
      append_to_collection -unique clks [get_attribute -quiet $pins clocks]
    }
    if { [sizeof_collection $clks] == 0 } {
      # third try if something before this cell stops the clock propagation
      set pins [bcm_all_fanin -to $cell_name/$pin_name -startpoints_only -flat]
      append_to_collection -unique clks [get_attribute -quiet $pins clocks]
    }
    if { [sizeof_collection $clks] == 0 } {
      bcm_puts "WARN" "Cannot get associated clocks on pin $pin_name of $cell_name. Cell will be skipped."
    }
    return $clks
  }

  proc getBCMClockPeriod { cell_name pin_name clks } {
    set allPeriods [get_attribute -quiet $clks period]
    if {$allPeriods ne ""} {
      set clkPeriod [tcl::mathfunc::min {*}$allPeriods]
      bcm_puts "DBG" "getBCMClockPeriod: cell name $cell_name - pin name $pin_name - clocks [get_object_name $clks] - period $clkPeriod"
    } else {
      set clkPeriod ""
      bcm_puts "WARN" "Period is not defined for clock [get_object_name $clks], which is associated to pin $pin_name of $cell_name. Cell will be skipped."
    }
    return $clkPeriod
  }

  proc checkTemplateNamingStyle {} {
    set value 0
    set template_naming_style ""
    set template_parameter_style ""
    set template_separator_style ""
    if {$::synopsys_program_name eq "fc_shell"} {
      set template_naming_style [get_app_option_value -name hdlin.naming.template_naming_style]
      set template_parameter_style [get_app_option_value -name hdlin.naming.template_parameter_style]
      set template_separator_style [get_app_option_value -name hdlin.naming.template_separator_style]
    } elseif {($::synopsys_program_name eq "dc_shell") || ($::synopsys_program_name eq "dcnxt_shell")} {
      set template_naming_style [get_app_var template_naming_style]
      set template_parameter_style [get_app_var template_parameter_style]
      set template_separator_style [get_app_var template_separator_style]
    } else {
      set value 2
    }
    if {
      ($template_naming_style eq {%s_%p}) &&
      (($template_parameter_style eq {%s%d}) || ($template_parameter_style eq {%d})) &&
      ($template_separator_style eq {_})
    } {
      set value 1
    }
    if {$value == 0} {
      puts "INFO: Cannot get the value of BCM parameters, because tool options template_*_style probably have non-default settings."
      puts "      Supported template_naming_style is %s_%p, supported template_parameter_style is %s%d or %d, supported template_separator_style is _"
      puts "      Normally this won't impact constraint setting, but you may see warnings like 'Unable to find synchronization flip-flop ...'."
      puts "      These warnings can be ignored if parameter F_SYNC_TYPE of some BCM modules is intentionally set to 0."
      puts "      Set 'template_*_style' to supported styles if you want to avoid such warnings."
    }
    return $value
  }
  set template_style [checkTemplateNamingStyle]

  proc getBCMParamFromNameOrIndex { cell bcmSuffix bcmParamName bcmParamIndex } {
    variable template_style
    set cell_name [get_object_name $cell]
    set value ""
    if {$template_style == 1} {
      set ref_name [get_attribute $cell ref_name]
      if {![regsub ".*_${bcmSuffix}_" $ref_name {} paramString]} {
        # No instance name match.
        return $value
      }
      # First look by name PARAMA<valueA>_PARAMB<valueB>_...
      if {![regexp "${bcmParamName}(\[^_\]+)" $paramString match value]} {
        # Look by index <valueA>_<valueB>_...
        set parameters [split $paramString _]
        if {[llength $parameters] >= $bcmParamIndex} {
          set value [lindex $parameters $bcmParamIndex]
        }
      }
    }
    if {$value eq ""} {
      bcm_puts "DBG" "Cannot get the value of parameter $bcmParamName in $cell_name."
    }
    return $value
  }

  # Get name of reference design 'level' levels above the given cell name
  proc getBCMParent {cell_name level} {
    set names [split $cell_name /]
    set name [join [lrange $names 0 end-$level] /]
    if {$name ne ""} {
      return [get_attribute -quiet [get_cells -quiet $name] ref_name]
    }
    return ""
  }

  proc runCmd { cmd } {
    bcm_puts "DBG" $cmd
    eval $cmd
  }

  if {![catch {getenv DWC_BCM_DISABLE_IGNORE_CLOCK_LATENCY}]} {
    set ignore_clock_latency_option ""
    bcm_puts "DBG" "DWC_BCM_DISABLE_IGNORE_CLOCK_LATENCY is defined, -ignore_clock_latency won't be used."
  }

  if {![catch {getenv DWC_BCM_RESET_PATH}]} {
    set reset_path_option "-reset_path"
    bcm_puts "DBG" "DWC_BCM_RESET_PATH is defined, -reset_path will be used."
  }

  if {![catch {getenv DWC_BCM_HIER_TO_SKIP}]} {
    set bcm_hier_to_skip [getenv DWC_BCM_HIER_TO_SKIP]
    if {[llength $bcm_hier_to_skip] > 0} {
      bcm_puts "DBG" "DWC_BCM_HIER_TO_SKIP is defined, skip constraints on BCM instances under $bcm_hier_to_skip."
    }
  }

  if {![catch {getenv DWC_BCM_MOD_TO_SKIP}]} {
    set bcm_mod_to_skip [getenv DWC_BCM_MOD_TO_SKIP]
    if {[llength $bcm_mod_to_skip] > 0} {
      bcm_puts "DBG" "DWC_BCM_MOD_TO_SKIP is defined, skip constraints on BCM modules $bcm_mod_to_skip."
    }
  }

  if {![catch {getenv DWC_BCM_CONSTRAIN_INPUT_PORTS}]} {
    if {$::env(DWC_BCM_CONSTRAIN_INPUT_PORTS) == 0} {
      set bcm_constrain_input_ports 0
      bcm_puts "DBG" "DWC_BCM_CONSTRAIN_INPUT_PORTS is defined as 0, skip constraints on the paths starting from primary inputs."
    }
  }

  if {$::synopsys_program_name eq "pt_shell"} {
    set name_attr base_name
  }

}; # end of namespace BCM (common procs and vars)

#===============================================================================
# Create Guard for file DWbb_bcm21_cdc_constraints.tcl
#===============================================================================
if {![info exists ::__snps_guard__DWbb_bcm21_cdc_constraints__tcl__] || !$::__snps_guard__DWbb_bcm21_cdc_constraints__tcl__} {
  set ::__snps_guard__DWbb_bcm21_cdc_constraints__tcl__ 1
# -------------------------------------------------------------------------------
# 
# Copyright 2001 - 2023 Synopsys, INC.
# 
# This Synopsys IP and all associated documentation are proprietary to
# Synopsys, Inc. and may only be used pursuant to the terms and conditions of a
# written license agreement with Synopsys, Inc. All other use, reproduction,
# modification, or distribution of the Synopsys IP or the associated
# documentation is strictly prohibited.
# Inclusivity & Diversity - Visit SolvNetPlus to read the "Synopsys Statement on
#            Inclusivity and Diversity" (Refer to article 000036315 at
#                        https://solvnetplus.synopsys.com)
# 
# Component Name   : DW_axi
# Component Version: 4.06a
# Release Type     : GA
# Build ID         : 18.26.9.4
# -------------------------------------------------------------------------------


# Filename    : DWbb_bcm21_cdc_constraints.tcl
# Description : Synthesis CDC Methodology constraints


# -----------------------------------------------------------------------------
# [CDC_SYN_04] Define set_max_delay of 1 destination clock period and set_min_delay of 0 constraints for all CDC crossings (excluding Gray-coded and Qualifier-based Data Bus signals)
# BCM21 set_max_delay | set_min_delay constraints
namespace eval BCM {

  proc set_cstr_bcm21 {} {
    variable ignore_clock_latency_option
    variable reset_path_option
    variable bcm_hier_to_skip
    variable cmd_list_bcm_all
    variable bcm_constrain_input_ports
    variable name_attr
    variable cmnts_arr

    set cell_collection_bcm21 [filter_collection [get_cells -hierarchical *] -regexp {(@ref_name!~.*SNPS_CLOCK_GATE.*) AND (@ref_name=~.*_bcm21.*) AND @ref_name!~.*_bcm21_a.* AND @ref_name!~.*_bcm21_cg.* AND @ref_name!~.*_bcm21_neo.* AND @ref_name!~.*_bcm21_tgl.*}]
    # Parent modules of bcm21 which have their own constraints
    set bcm21_excl_parents_expr_lvl1 "_bcm05_cf|_bcm24|_bcm40|_bcm38"
    set bcm21_excl_parents_expr_lvl2 "_bcm07(?!_rs)|_bcm87"
    set bcm21_excl_parents_expr_lvl3 "_bcm07_atv"
    foreach_in_collection cell $cell_collection_bcm21 {
      set cell_name [get_object_name $cell]
      set inst_name [get_attribute $cell $name_attr]
      set cmd_cmnt_max "-comment {Instance $inst_name: $cmnts_arr(CDC_SYN_04_max)}"
      set cmd_cmnt_min "-comment {Instance $inst_name: $cmnts_arr(CDC_SYN_04_min)}"
      if { [llength $bcm_hier_to_skip] > 0 } {
        set bcm_skip 0
        foreach bcm_skip_inst $bcm_hier_to_skip {
          if { [regexp "^$bcm_skip_inst" $cell_name] } {
            set bcm_skip 1
            break
          }
        }
        if {$bcm_skip == 1} {
          continue
        }
      }
      if { \
        [regexp $bcm21_excl_parents_expr_lvl1 [getBCMParent $cell_name 1]] || \
        [regexp $bcm21_excl_parents_expr_lvl2 [getBCMParent $cell_name 2]] || \
        [regexp $bcm21_excl_parents_expr_lvl3 [getBCMParent $cell_name 3]] \
      } {
        continue
      }

      set clk_dst [getBCMClocks $cell_name "clk_d"]
      if { [sizeof_collection $clk_dst] == 0 } {
        # Skip, the clock is probably tied off
        continue
      }
      set clkPeriod [getBCMClockPeriod $cell_name "clk_d" $clk_dst]
      if {$clkPeriod eq ""} {
        continue
      }

      set dst_pins ""
      if { [get_cells -quiet $cell_name/GEN_FST??sample_meta*] != "" } {
        # No tech cell mapping
        set dst_pins [get_pins -quiet $cell_name/GEN_FST??sample_meta*/next_state]
        if { [sizeof_collection $dst_pins] == 0 } {
          set dst_pins [get_pins $cell_name/GEN_FST??sample_meta*/D]
        }
      } elseif { [get_cells -quiet $cell_name/GEN_FST??U_SAMPLE_META_*/sample_meta*] != "" } {
        # Old way with DWC_SYNCHRONIZER_TECH_MAP
        set dst_pins [get_pins -quiet $cell_name/GEN_FST??U_SAMPLE_META_*/sample_meta*/next_state]
        if { [sizeof_collection $dst_pins] == 0 } {
          set dst_pins [get_pins $cell_name/GEN_FST??U_SAMPLE_META_*/sample_meta*/D]
        }
      } elseif { [get_cells -quiet $cell_name/GEN_FST??U_SAMPLE_META_*] != "" } {
        # New way with cT tech cell mapping
        set dst_pins [get_pins $cell_name/GEN_FST??U_SAMPLE_META_*/D]
      }
      if { [sizeof_collection $dst_pins] > 0 } {
        set dst_pins_name [get_object_name $dst_pins]
        set clk_from ""
        set data_s_regs [bcm_all_fanin -to $cell_name/data_s -startpoints_only -only_cells -flat]
        foreach_in_collection sreg $data_s_regs {
          append_to_collection -unique clk_from [get_pins -quiet [get_object_name $sreg]/* -filter "is_clock_pin == true"]
        }
        if { [sizeof_collection $clk_from] > 0 } {
          set clk_from_name [get_object_name $clk_from]
          lappend cmd_list_bcm_all "set_max_delay $clkPeriod -from \[get_pins {$clk_from_name}\] -to {$dst_pins_name} $ignore_clock_latency_option $reset_path_option $cmd_cmnt_max"
          lappend cmd_list_bcm_all "set_min_delay 0.0 -from \[get_pins {$clk_from_name}\] -to {$dst_pins_name} $ignore_clock_latency_option $reset_path_option $cmd_cmnt_min"
        }
        if {$bcm_constrain_input_ports == 1} {
          set i_ports [filter_collection [bcm_all_fanin -to $cell_name/data_s -startpoints_only -flat] "object_class == port"]
          if {[sizeof_collection $i_ports] > 0} {
            set i_ports_name [get_object_name $i_ports]
            lappend cmd_list_bcm_all "set_max_delay $clkPeriod -from \[get_ports {$i_ports_name}\] -to {$dst_pins_name} $ignore_clock_latency_option $reset_path_option $cmd_cmnt_max"
            lappend cmd_list_bcm_all "set_min_delay 0.0 -from \[get_ports {$i_ports_name}\] -to {$dst_pins_name} $ignore_clock_latency_option $reset_path_option $cmd_cmnt_min"
          }
        }
      } else {
        set f_sync_type [getBCMParamFromNameOrIndex $cell bcm21 F_SYNC_TYPE 1]
        if { [string is digit -strict $f_sync_type] && ([expr $f_sync_type % 8] == 0) } {
          # Nothing to be done when F_SYNC_TYPE is 0
          bcm_puts "WARNFST0" "Skip constraining $cell_name because F_SYNC_TYPE is set to 0."
        } else {
          bcm_puts "WARN" "Unable to find first synchronization flip-flop to destination domain in cell $cell_name. This warning can be ignored if F_SYNC_TYPE of $cell_name is intentionally set to 0."
        }
      }
    }
  }; # end of proc set_cstr_bcm21

  if { [lsearch -regexp $bcm_mod_to_skip ".*_bcm21$"] < 0 } {
    set_cstr_bcm21
  }

}; # end of namespace BCM (bcm21)
}

#===============================================================================
# Create Guard for file DWbb_bcm36_nhs_cdc_constraints.tcl
#===============================================================================
if {![info exists ::__snps_guard__DWbb_bcm36_nhs_cdc_constraints__tcl__] || !$::__snps_guard__DWbb_bcm36_nhs_cdc_constraints__tcl__} {
  set ::__snps_guard__DWbb_bcm36_nhs_cdc_constraints__tcl__ 1
# -------------------------------------------------------------------------------
# 
# Copyright 2001 - 2023 Synopsys, INC.
# 
# This Synopsys IP and all associated documentation are proprietary to
# Synopsys, Inc. and may only be used pursuant to the terms and conditions of a
# written license agreement with Synopsys, Inc. All other use, reproduction,
# modification, or distribution of the Synopsys IP or the associated
# documentation is strictly prohibited.
# Inclusivity & Diversity - Visit SolvNetPlus to read the "Synopsys Statement on
#            Inclusivity and Diversity" (Refer to article 000036315 at
#                        https://solvnetplus.synopsys.com)
# 
# Component Name   : DW_axi
# Component Version: 4.06a
# Release Type     : GA
# Build ID         : 18.26.9.4
# -------------------------------------------------------------------------------


# Filename    : DWbb_bcm36_nhs_cdc_constraints.tcl
# Description : Synthesis CDC Methodology constraints


# -----------------------------------------------------------------------------
# [CDC_SYN_05] Define "set_false_path -through" constraint for quasi-static signals at the output of the Bus Delay components
# BCM36_NHS set_false_path constraints
namespace eval BCM {

  proc set_cstr_bcm36_nhs {} {
    variable ignore_clock_latency_option
    variable reset_path_option
    variable bcm_hier_to_skip
    variable cmd_list_bcm_all
    variable name_attr
    variable cmnts_arr

    set cell_collection_bcm36_nhs [filter_collection [get_cells -hierarchical *] -regexp {(@ref_name!~.*SNPS_CLOCK_GATE.*) AND @ref_name=~.*_bcm36_nhs.*}]
    # Parent modules of bcm36_nhs which have their own constraints
    set bcm36_nhs_excl_parents_expr_lvl1 "(_bcm36_(ack|tgl)|_bcm31_p2d_fifomem)"
    foreach_in_collection cell $cell_collection_bcm36_nhs {
      set cell_name [get_object_name $cell]
      set inst_name [get_attribute $cell $name_attr]
      set cmd_cmnt "-comment {Instance $inst_name: $cmnts_arr(CDC_SYN_05)}"
      if { [llength $bcm_hier_to_skip] > 0 } {
        set bcm_skip 0
        foreach bcm_skip_inst $bcm_hier_to_skip {
          if { [regexp "^$bcm_skip_inst" $cell_name] } {
            set bcm_skip 1
            break
          }
        }
        if {$bcm_skip == 1} {
          continue
        }
      }
      if { [regexp $bcm36_nhs_excl_parents_expr_lvl1 [getBCMParent $cell_name 1]] } {
        continue
      }
      lappend cmd_list_bcm_all "set_false_path -through \[get_pins $cell_name/data_d*\] $cmd_cmnt"
    }
  }; # end of proc set_cstr_bcm36_nhs

  if { [lsearch -regexp $bcm_mod_to_skip ".*_bcm36_nhs$"] < 0 } {
    set_cstr_bcm36_nhs
  }

}; # end of namespace BCM (bcm36_nhs)
}

# -------------------------------------------------------------------------------
# 
# Copyright 2001 - 2023 Synopsys, INC.
# 
# This Synopsys IP and all associated documentation are proprietary to
# Synopsys, Inc. and may only be used pursuant to the terms and conditions of a
# written license agreement with Synopsys, Inc. All other use, reproduction,
# modification, or distribution of the Synopsys IP or the associated
# documentation is strictly prohibited.
# Inclusivity & Diversity - Visit SolvNetPlus to read the "Synopsys Statement on
#            Inclusivity and Diversity" (Refer to article 000036315 at
#                        https://solvnetplus.synopsys.com)
# 
# Component Name   : DW_axi
# Component Version: 4.06a
# Release Type     : GA
# Build ID         : 18.26.9.4
# -------------------------------------------------------------------------------


# Filename    : common_end.tcl
# Description : Common procs which will be exectued at the end


namespace eval BCM {
  variable cmd
  if { [llength $cmd_list_bcm_all] > 0 } {
    foreach cmd $cmd_list_bcm_all {
      runCmd $cmd
    }
  } else {
    bcm_puts "INFO" "No BCM CDC constraints are applied."
  }

  unalias bcm_all_fanin
  unalias bcm_all_fanout
}


