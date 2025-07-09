# -*-tcl-*-
#############################################################################
#  Description: run/control HAPS HW <-> UMRBus Application
#############################################################################
#          $Id: //chipit/chipit/main/dev/systems/examples/xtor_riscv_soc/xtor_riscv_soc_h100/scripts/haps_app_script.tcl#6 $
#############################################################################

## ------------------------------------
## defaults, change if needed:
## ------------------------------------
#set env(PCS_PROJECTNAME)            "pcs"
set env(HAPS_SYSTEM)                "HAPS-100_4F"
set env(HAPS_PRJ_DIR)               [pwd]
#confprotools::set_default ::env(HAPS_VARIANT) "$env(HAPS_SYSTEM)"
set mode "GUI"
#set HAPS_APP (cfg_scan_patt)        ""
#set HAPS_APP(cfg_scan)              1
#set HAPS_APP(confFile)              ""
#set HAPS_APP(cfg_project_configure) 1
#set HAPS_APP(setup_pcie)            0
#set HAPS_APP(lsumr3)                1
#set HAPS_APP(umrbusscan)             1
#set HAPS_APP(cfg_project_clear)     0
set HAPS_APP(ignore_argv)           "quick full"

## ------------------------------------
## helper procs (confprotools) to be used:
## ------------------------------------
## proc EvalCheckExit {args}   = evaluate tcl command with print & exit in error
## proc ExecCheckExit {args}   = execute other external tool with print & exit in error
## ------------------------------------

proc pause {{message "APP_INFO    : Do you want to continue \[y\/n\]? "}} {
  ## This procedure is used to wait for user to continue loading kernel
  puts -nonewline $message
  flush stdout
  gets stdin answer
  if { $answer == "y" || $answer == "Y" } {
    return 1
  } else {
    if { $answer != "n" && $answer != "N" } {
      puts "APP_INFO    : Since the input given is not y\/n we are assuming it to be yes "
      return 1
    }
    return 0
  } 
}

proc check_env {envirn value} {
  if { [info exist ::env($envirn)] && $::env($envirn) == $value} {
    return 1
  }
  return 0
}

proc haps_app {args} {
  global HAPS_APP env

  ## compile application if required
  #ExecCheckExit make -C [file join $env(HAPS_PRJ_DIR) app] -f Makefile.linux cleanall all

  set fp [open "[file join $env(APP_SHELL_CWD) cpp umr3_virtual_uart.config]" r]
  set file_data [read $fp]

  set i 0
  set data [split $file_data "\n"]
  foreach line $data {

    set x [lindex $data $i]
    set y [lindex $x 0]
    #puts $y

    if { $i == 0 } {
      set mode $y
      puts "APP_INFO    : APP is open in $mode mode"
    } 

    incr i
  }

  close $fp
  
  set script_dir [file join $env(APP_SHELL_CWD) auto_script]

  ## running the Initialisation required
  puts "APP_INFO    : Running initialisation steps..."
  EvalCheckExit source [file join $script_dir init.tcl]
  #set ::env(EN_PUART) 1

  ## execute application
  puts "APP_INFO    : Running test application ..."
  if { [check_env "EN_PUART" 1] == 1 } {
    puts "APP_WARNING : Start picocom for physical serial uart link in xterm ..."
    ExecCheckExit xterm -ls -hold -T \"PUART Terminal\" -e /bin/bash -c \"picocom -b38400 /dev/ttyUSB0\" &
  } else {
    puts "APP_INFO    : Start UMR3 virtual uart app in xterm ..." 
    if {$mode=="GUI"} {
      ExecCheckExit xterm -ls -hold -T \"UMR3 VUART Terminal\" -e /bin/bash -c [file join $env(APP_SHELL_CWD) cpp umr3_virtual_uart] &
    } else {
      ExecCheckExit xterm -ls -T \"UMR3 VUART Terminal\" -e /bin/bash -c [file join $env(APP_SHELL_CWD) cpp umr3_virtual_uart] &
    } 
  }
      
  if { [info exist ::env(EN_AUTO)] } {
      # This is for auto testing
      if { [check_env "ENABLE_GSV" 1] == 1 } {
        ExecCheckExit protocompiler100_runtime debug -shell -tcl [file join $script_dir rdbck.tcl] -log [file join $env(PCS_WORK) $env(PCS_PROJECTNAME) auto_rdbk.log] &
        after 40000
        ExecCheckExit protocompiler100_runtime debug -shell -tcl [file join $script_dir debug.tcl] -log [file join $env(PCS_WORK) $env(PCS_PROJECTNAME) auto_dbgr.log] &
      } elseif { [check_env "ENABLE_DEBUG" 0] == 0 } {
        ExecCheckExit protocompiler100_runtime debug -shell -tcl [file join $script_dir debug.tcl] -log [file join $env(PCS_WORK) $env(PCS_PROJECTNAME) auto_dbgr.log] &
      }
      after 40000
      EvalCheckExit cfg_reset_pulse $::HAPS_APP(cfg_h) FB1.uA 5
    set answer 1
  } else {
     # This is for manual feature testing
      if { [check_env "ENABLE_GSV" 1] == 1 } {
        ExecCheckExit protocompiler100_runtime -log [file join $env(PCS_WORK) $env(PCS_PROJECTNAME) pcrt_gsv1.log] &
        ExecCheckExit protocompiler100_runtime -log [file join $env(PCS_WORK) $env(PCS_PROJECTNAME) pcrt_gsv2.log] &
      } elseif { [check_env "ENABLE_DEBUG" 0] == 0 } {
        ExecCheckExit protocompiler100_runtime -log [file join $env(PCS_WORK) $env(PCS_PROJECTNAME) pcrt_debug.log] &
      } elseif { [check_env "ENABLE_DF" 1] == 1 } {
        ExecCheckExit protocompiler100_runtime -log [file join $env(PCS_WORK) $env(PCS_PROJECTNAME) pcrt_df.log] &
      }
      set answer [pause "APP_INFO    : Do you want load kernel \[y\/n\]? "] ; # Waiting for the user to give the response after setting the trigger or readback prj
      EvalCheckExit cfg_reset_pulse $::HAPS_APP(cfg_h) FB1.uA 5
  }

  if { $answer == 1 } {
    ExecCheckExit confprosh [file join $env(APP_SHELL_CWD) xtor_load_kernel.tcl]
    if {[info exist ::env(EN_AUTO)] && [check_env "ENABLE_DF" 1] == 1 } {
      EvalCheckExit source [file join $script_dir df.tcl]
    }
    if { [info exist ::env(EN_AUTO)] && [check_env "ENABLE_DEBUG" 1] == 1 && [check_env "EN_VERDI" 1] == 1 } {
      after 200
      ExecCheckExit verdi [file join $env(PCS_WORK) $env(PCS_PROJECTNAME) runtime system debug IICE_axi_extmem.fsdb] &
    }
    if { [info exist ::env(EN_AUTO)] && [check_env "ENABLE_GSV" 1] == 1 && [check_env "EN_VERDI" 1] == 1 } {
      after 200
      ExecCheckExit verdi [file join $env(PCS_WORK) $env(PCS_PROJECTNAME) runtime system readback Readback.fsdb] &
    }		
  }
}

## run haps_app_main
confprotools::haps_app_main
