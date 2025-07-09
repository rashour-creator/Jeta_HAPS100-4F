# -*- mode: tcl -*-
# ____________________________________________________________________________
# ><
# ><      Copyright (C) 2014-2022 Synopsys, Inc.
# ><
# ><  This script and the associated documentation are confidential and proprietary to Synopss, Inc.
# ><  Your use or disclosure of this script is subject to the terms and conditions of a written license agreement
# ><  between you, or your company, and Synopsys, Inc.
# ><
# ><      Project: <DUT>
# ><  Description: ProtoCompiler Scripting Configuration Script
# ><      Version: S-2021.09-B139_HEAD
# ><          $Id: //chipit/chipit/main/dev/systems/examples/xtor_riscv_soc/xtor_riscv_soc_h100/scripts/config.tcl#1 $
# ><      $Author: khertig $
# ><    $DateTime: 2022/03/11 03:29:59 $
# _____________________________

#package require pcs

# ____________________________________________________________________________
# ><
# ><      USAGE
# >< _____________________________
# ><
# ><  (a) use in combination with pcs wrapper ($HAPS_INSTALL_DIR/bin/pcs), like
# ><      pcs <path/config.tcl> [<projectname>] [<HAPS system>] [<options>] [-help]
# ><  (b) or use as -tcl script input to protocompiler (expect 'package require pcs' in config script), like:
# ><      protocompiler -batch -tcl <path/config.tcl>
# ><
# ><  It is recommended to use absolute file pointers.
# ><  Anyway, for a relative path pointer make sure you have it defined from the
# ><  directory where your ProtoCompiler project is placed [pcs get projectdir]
# _____________________________


# ____________________________________________________________________________
# ><
# ><      CONTROL PROTOCOMPILER PROJECT SETTINGS
# >< _____________________________
# ><
# ><  pcs set debug <0|1>                 - use '1' to enable pcs debug output
# ><  pcs set synth_flow_fpgas <0|1>      - use "1" to enable pcs even for synthesis flow of individual FPGAs - launch protocompiler
# ><  pcs set save_tcase <0|1>            - use '1' to save a testcase for the whole database, even in case of error
# ><  pcs set opt_db_space <0|1>          - use '1' to link files between PC states to reduce database disc space
# ><  pcs set compile_flow <0|1>          - use '1' to switch to Unified Compile 2.0 (UC2) mode; use '0' for standard compile (recommend to use env(PCS_UC2))
# ><
# ><  pcs set top_module <name>           - set design top module of the design; recommend to use PCS_TOPLEVEL environment varaible with default value 'fpga_toplevel'
# ><
# ><  pcs set projectname <name>          - force PCS project name or project path; recommend to use PCS_PROJECTNAME environment variable with default value 'pcs'
# ><  pcs set scriptsdir <path>           - set common script directory (default is directory of this config tcl script)
# ><  pcs set rtldir <path>               - set common rtl directory (default is parallel to scriptsdir)
# ><  pcs set projectdir <path>           - set PCS project path (default is parallel to scriptsdir + projectname)
# ><  pcs set technology <tech>           - force HAPS technology as HAPS-100|HAPS-80|HAPS-80D|HAPS-70|HAPS-DX7_S4|HAPS-DX7_S6; recommend to use HAPS_SYSTEM environment variable with default value 'HAPS-80'
# ><  pcs set max_license <int>           - set max license count for ProtoCompiler synthesis (each license allows up to 16 jobs)
# ><
# ><  pcs add db_options <option> <value> - add database options as <option> <value>
# _____________________________
# ><

proc check_env {envirn value} {
  if { [info exist ::env($envirn)] && $::env($envirn) == $value} {
    return 1
  }
  return 0
}

proc add_verilog_defines {envirn value} {
  if { [check_env $envirn $value] == 1} {
    pcs add verilog_defines $envirn $value
  }
}


pcs set debug              [expr {[info exists env(PCS_DEBUG)]      ? $env(PCS_DEBUG)      : 0}]
pcs set synth_flow_fpgas   [expr {[info exists env(PCS_SYNTH_FLOW)] ? $env(PCS_SYNTH_FLOW) : 0}]
pcs set save_tcase         [expr {[info exists env(PCS_TCASE)]      ? $env(PCS_TCASE)      : 0}]
pcs set opt_db_space       [expr {[info exists env(PCS_LINK_NODES)] ? $env(PCS_LINK_NODES) : 1}]
pcs set compile_flow       [expr {[info exists env(PCS_UC2)]        ? $env(PCS_UC2)        : 1}]
# ><
pcs set top_module         $env(PCS_TOPLEVEL)
# ><
pcs set projectname        $env(PCS_PROJECTNAME)
pcs set scriptsdir         [file dirname [file normalize [info script]]]
pcs set rtldir             [file join [file dirname [pcs get scriptsdir]] rtl]            
pcs set projectdir         [file join $env(PCS_WORK) [pcs get projectname]]
pcs set technology         $env(HAPS_SYSTEM)
pcs set max_licenses       1
# ><
if { "[pcs get compile_flow]" == "0" } {
pcs add db_options         vlog_std                  sysv
}
#pcs add db_options         max_parallel_par_explorer 8     ; # >< set to 8 to cover all default vivado runs in parallel
pcs add db_options          par_strategy        timing_qor  ; # >< StrategyMode can be set to "fast_turn_around" (default), "timing_qor" or "advanced"
pcs add db_options          force_async_genclk_conv     1   ; # Added to allow async clk generation
#pcs add db_options         verification_mode         1     ; # >< required to be '1' for pcs export verification
#pcs add db_options         fast_synthesis            0
#pcs add db_options         speed_grade              -1     ; # >< for partition_flow speed_grade is defined in TSS
if { [check_env "ENABLE_GSV" 1] == 1} {
  pcs add db_options      verdi_mode       1
  pcs add db_options      prepare_readback 2
}

if { [check_env "ENABLE_DEBUG" 1] == 1 || [check_env "ENABLE_GSV" 1] == 1 || [check_env "ENABLE_DF" 1] == 1 } {
  pcs add db_options      debug_dumpvars   1
}

if { [check_env "ENABLE_DF" 1] == 1 } {
  pcs add db_options      incremental_debug           1
  pcs add db_options      dynamic_force_global_driver 1
}


# _____________________________


# ____________________________________________________________________________
# ><
# ><      CONTROL PROTOCOMPILER PROJECT INPUTS
# >< _____________________________
# ><
# ><  pcs set tss <file/path>          - set HAPS target system specification script used in partition flow, support directory scan <*.tss>
# ><
# ><  pcs add vcslist <file/path>      - add vcs filelist to rtl.sfl, support directory scan <*.vc *.vhdc *.f v(hdl|log)an.filelists>
# ><  pcs add incdir <path>            - add verilog include directory to filelist includes.sfl
# ><  pcs add libdir <path>            - add verilog library directory to filelist libraries.sfl
# ><  pcs add verilog_defines <define> - add global verilog defines used for compile <mydefine=1>
# ><  pcs add verilog <file/path>      - add verilog rtl file(s) to filelist rtl.sfl, support directory scan <*.v *.sv>
# ><  pcs add vhdl <file/path> <lib>   - add vhdl rtl file(s) with their library to filelist rtl.sfl, support directory scan <*.vhd>
# ><  pcs add netlist <file>           - add netlist file(s) (support *.edif, *.edf, *.edn, *.ngc) to filelist rtl.sfl
# ><
# ><  pcs add idc <file/path>          - add instrumentation contraint file(s) to filelist idc.sfl, support directory scan <*.idc>
# ><  pcs add cdc <file/path>          - add compiler directive contraint file(s) to filelist cdc.sfl, support directory scan <*.cdc>
# ><  pcs add fdc <file/path>          - add synthesis constraint file(s) to filelist fdc.sfl, support directory scan <*.fdc>
# ><  pcs add pcf <file/path>          - add partition constraint file(s) to filelist pcf.sfl (partition mode), support directory scan <*.pcf>
# _____________________________
#set env(ADD_HAPS_XTOR_LIB) 1
#set env(ADD_HAPS_UMR3_LIB) 1
# ><
pcs set tss             [file join [pcs get scriptsdir]]
# ><
pcs add vcslist         [file join $env(PCS_WORK) rtl xgen.vc]
pcs add vcslist         [file join [pcs get rtldir] rocket-chip.vc]
pcs add vcslist 		    [file join [pcs get rtldir] noc_rtl.vc]
pcs add vcslist         [file join [pcs get rtldir] haps_lib.vc]
pcs add vcslist         [file join [pcs get rtldir] umr3_virtual_uart.vc]
#pcs add vcslist         [file join [pcs get rtldir] vlogan.filelists]
#pcs add vcslist         [file join [pcs get rtldir] vhdlan.filelists]
#pcs add incdir          <path>
#pcs add libdir          <path>
#pcs add verilog_defines mydefine=4
pcs add incdir 			    $env(DW_PRJ_DIR)/i_axi/
pcs add incdir 			    $env(DW_PRJ_DIR)/i_axi_a2x/
pcs add incdir 			    $env(DW_PRJ_DIR)/i_axi_a2x_1/

if { [check_env "ENABLE_GSV" 1] == 1} {
  pcs add verilog_defines ENABLE_GSV    1
}

if {[check_env "ENABLE_DEBUG" 1] == 1 || [check_env "ENABLE_GSV" 1] == 1} {
  pcs add verilog_defines ENABLE_DEBUG  1
}

if { [check_env "ENABLE_DF" 1] == 1 } {
  pcs add verilog_defines ENABLE_DF     1
}

pcs add verilog_defines UMR_USE_LOCATION_ID; # enable MDM mode (even HAPS-100 in UMRBus 2.0 compatibility mode, especial for xactors)
pcs add verilog_defines UMR_CHAIN_LIMIT4;    # used to increase max number of User CAPIMs for MDM from 3 to 7  
#pcs add verilog         [file join [pcs get rtldir]]
#pcs add vhdl            <file> <lib>
#pcs add netlist         <file>
# ><

#pcs add cdc             [file join [pcs get scriptsdir]]
pcs add fdc             [file join $LIB xactors xactors_gen templates syn_useioff.fdc]
pcs add fdc             [file join [pcs get scriptsdir]]
pcs add pcf             [file join [pcs get scriptsdir]]
if { [check_env "ENABLE_DEBUG" 1] == 1 || [check_env "ENABLE_GSV" 1] == 1 || [check_env "ENABLE_DF" 1] == 1 } {
  pcs add idc             $::env(HAPS_PRJ_DIR)/scripts/basic_debug.idc
}

# _____________________________


# ____________________________________________________________________________
# ><
# ><      OPTIONAL - CONTROL PAR BACK-END FOR INDIVIDUAL FPGAs
# ><      define for either a specific partitioned FPGA only (e.g. FB1_uA) or use 'all' to target all FPGAs
# >< _____________________________
# ><
# ><  pcs set vivado_ip_outdir <path>         - set base folder for pre-synthesized Vivado IP outputs used by 'pcs add_vivado_ip'
# ><                                            optional (recommended) 'set env(PCS_VIVADO_IP_OUTDIR) <path>' e.g. define a common folder for multiple designs
# ><  pcs add white_box <file|haps_ip> [flag] - add white_box IP - use for Interface IPs (IP is used for analysis in PC syhtnesis and gets resolved in vivado back-end)
# ><  pcs add absorb    <file|haps_ip> [flag] - add absorb IP    - use for Data-Path IPs (IP is resolved in PC synthesis, use xdc file from IP in vivado back-end)
# ><                                            support *.hip, *.xci, *.dcp, as <file> input
# ><                                            avoid dcp as xci is the Xilinx recommended IP format
# ><                                            support for pre-defined HAPS IPs like ddr3, ddr4, xdma ... or *.hip (HAPS IP) files
# ><                                            optional flag: force|skip    - control IP regeneration
# ><                                                           synth_ip      - default since 2020.12-SP1, force read_ip+synth_ip for xci input (no dcp required)
# ><                                                           add_ip        - force use of ProtoCompiler add_vivado_ip function (not recommended)
# ><                                                           ignore_fdc    - skip IP fdc constraints (use only original xdc in vivado back-end)
# ><                                                           force_verilog - use IP verilog file for compile (default, only combined with read_ip/synth_ip)
# ><                                                           force_edif    - use IP edf+verilog_wrapper files for compile (only combined with read_ip/synth_ip)
# ><  pcs add black_box <file|haps_ip> [fpga] - add black_box IP (IP is resolved in vivado back-end)
# ><                                            support *.xci, *.dcp, *.edif, *.edn, *.edf, *.ngc, *.hip
# ><                                            optional flag: add_ip        - skip synth_ip (hip or xci) and no adding of stub/wrapper file (user has to define)
# ><                                                           fpga          - force to specified FPGA, e.g. FB1_uB (auto assign on default)
# ><  pcs add vivado_files <file> <fpga>      - add other vivado input files (support *.xdc, *.bmm, *.elf, *.vm, *.tcl) for the given FPGA
# ><  pcs set vivado_run_path <path> <fpga>   - force place-and-route back-end path for the given FPGA (recommended to use absolute path per FPGA)
# ><  pcs set vivado_run_script <file> <fpga> - force place-and-route runscript for the given FPGA (used instead of the ProtoCompiler default generated one)
# _____________________________
# ><
pcs set vivado_ip_outdir  [file join $env(PCS_WORK) vivadoips]
pcs add white_box         [file join [pcs get scriptsdir] mig_ddr4.hip]
pcs add white_box         [file join [pcs get vivado_ip_outdir] haps100_axi_extmem_$PCS(VIVADO_VERSION) axi_extmem.dcp]
pcs add white_box         [file join [pcs get vivado_ip_outdir] haps100_axi_mmio_$PCS(VIVADO_VERSION) axi_mmio.dcp]
#pcs add absorb            <file>
#pcs add black_box         <file>
pcs add vivado_files      [file join [pcs get scriptsdir] custom.xdc] all
#pcs set vivado_run_path   <path> FB1_uA
#pcs set vivado_run_script [file join [pcs get pcs_dir] run_vivado_haps.tcl] all
# _____________________________


# ____________________________________________________________________________
# ><
# ><      PARTITION FLOW ONLY - CONTROL SYNTHESIS FLOW FOR INDIVIDUAL FPGAs
# ><      define for either a specific partitioned FPGA only (e.g. FB1_uA) or use 'all' to target all FPGAs
# >< _____________________________
# ><
# ><  pcs set rtl_input_format <srs|rtl> <fpga> - switch from default netlist-based (srs) to hdl-based scripts to run synthesis for the given FPGA
# ><  pcs set enable_par <0|1> <fpga>           - control place and route for the given FPGA
# ><  pcs set enable_par_explorer <0|1> <fpga>  - control exploratory place and route for the given FPGA
# ><  pcs set enable_backannotate <0|1> <fpga>  - control backannotation, values 0|1 for the given FPGA
# ><  pcs set user_rtl_idc <file> <fpga>        - set idc file for single-FPGA debug (RTL) for the given FPGA
# ><  pcs set user_netlist_icd <file> <fpga>    - set idc file for single-FPGA debug (SRS) for the given FPGA
# ><  pcs set par_explorer_script <file> <fpga> - set additional TCL script for the given FPGA(s) to source when running exploratory place and route
# _____________________________
# ><
#pcs set rtl_input_format    srs all
#pcs set enable_par          1 FB1_uA
#pcs set enable_par_explorer 1 FB1_uA
#pcs set enable_backannotate 1 FB1_uA
#pcs set user_rtl_idc        <file> FB1_uA
#pcs set user_netlist_idc    <file> FB1_uA
#pcs set par_explorer_script <file> FB1_uA
# _____________________________


# ____________________________________________________________________________
# ><
# ><      PROTOCOMPILER SCRIPTING FLOW STEPS
# >< _____________________________
# ><
# ><  pcs add_vivado_ip                  - run ProtoCompiler add_vivado_ip pre-step if IPs defined
# ><  pcs database load [db_name] [flag] - create new ProtoCompiler database (prepare project)
# ><                                       [db_name] database name (default: partition_db or synthesis_db)
# ><                                       [flag]    force - delete existing database
# ><  pcs launch uc <options>            - Unified Compile entry, use '-utf pcs_uc.utf' to enable pcs controlled run
# ><  pcs run <state> <options> [flag]   - ProtoCompiler run state (create state if not exist | up-to-date check if exist)
# ><                                       <state>   pre_instrument, compile, pre_map, map, pre_partition, partition, system_route, system_generate
# ><                                       <options> define options for the protocompiler state
# ><                                       [flag]    force - delete existing state
# ><                                                 tcase - create testcase for that state
# ><  pcs export verification <path>      - export of system-level post-partition simulation (after system generate) to the specified path
# ><  pcs launch <state> [flag] [fpga]    - ProtoCompiler launch state
# ><                                        <state>  protocompiler, vivado
# ><                                        [flag]   auto  - pcs controlled with incremental dependency check
# ><                                                 force - force re-run
# ><                                                 skip  - skip re-run
# ><                                        [fpga]   for the given FPGA - target all FPGAs on default
# ><  pcs export vivado                   - export files for vivado back-end
# ><  pcs import vivado [flag]            - import vivado results as auto|force|skip
# ><  pcs export runtime [flag]           - export runtime as auto|force|skip
# ><  pcs exit                            - pcs controlled close, save tcase if enabled
# _____________________________
# ><  Common
pcs add_vivado_ip
pcs database load
if { "[pcs get compile_flow]" == "1" } {
#set env(LOCAL_SYNOPSYS_SIM_SETUP) <file>
pcs launch uc             -utf [expr {[info exists env(PCS_UTF)] ? $env(PCS_UTF) : "pcs_uc.utf"}] -ucdb [file join [pcs get projectdir] uc_db] -v 2.0
pcs run compile           -out c0 -ucdb [file join [pcs get projectdir] uc_db] -srclist edf.sfl -idclist idc.sfl
} else {
pcs run pre_instrument    -out r0 -srclist rtl.sfl -top_module [pcs get top_module] -ilist includes.sfl -llist libraries.sfl -cdclist cdc.sfl
pcs run compile           -out c0 -idclist idc.sfl
#export uc -path [file join [pcs get projectdir] uc_export]; pcs exit
}
pcs run pre_partition     -out pp0 -fdclist fdc.sfl -tss [pcs get tss] -area_est [expr {[info exists env(PCS_AREA_EST)] ? $env(PCS_AREA_EST) : 1}] -idclist idc.sfl
pcs report target_system  -out tss0
pcs run partition         -out pa0 -pcflist pcf.sfl -builtin_est [expr {[info exists env(PCS_BUILTIN_EST)] ? $env(PCS_BUILTIN_EST) : 1}] -optimization_priority tdm_ratio -clock_gate_replication 1
pcs run system_route      -out sr0 -fdclist fdc.sfl -pcflist pcf.sfl -optimization_priority tdm_ratio -estimate_timing 1
pcs run system_generate   -out sg0 -fdclist fdc.sfl -path synthesis_files
# ><
pcs export verification   [file join [pcs get projectdir] sim_postpart]
pcs launch protocompiler  auto [expr {[info exists env(PCS_UFPGA)] ? $env(PCS_UFPGA) : "all"}]
pcs launch vivado         auto [expr {[info exists env(PCS_UFPGA)] ? $env(PCS_UFPGA) : "all"}]
pcs import vivado         auto [expr {[info exists env(PCS_UFPGA)] ? $env(PCS_UFPGA) : "all"}]
pcs export runtime        auto [expr {[info exists env(PCS_UFPGA)] ? $env(PCS_UFPGA) : "all"}]
# _____________________________
pcs exit
