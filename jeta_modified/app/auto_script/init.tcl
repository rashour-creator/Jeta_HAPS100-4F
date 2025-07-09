## scan DBG_CCM mcapim
set mcapim_path ""
foreach mcapim [umr3_scan] { 
  if { [string first "DBG_CCM" $mcapim] != -1 } { 
    set mcapim_path [lindex $mcapim 3]
    break
  }
}

## initialisation CCM 
if { $mcapim_path == "" } {
  puts "APP_INFO    : DEBUG CCM MCAPIM not found. Skipping CCM initialisation step."
  puts "APP_INFO    : If CCM needs to be initialised then Reconfigure the H100 system and try again"

} else {

  if { [info exists ::HAPS_APP(cfg_h)] } {
    cfg_reset_set $::HAPS_APP(cfg_h) FB1.uA 0
  }

  set dbg_ccm_capim [umr3_open $mcapim_path]
  puts "APP_INFO    : CCM getting initialised"

  umr3_write $dbg_ccm_capim "0x1 0x2 0x0 0x0 0x0 0x0 0x0 0x0"
  umr3_write $dbg_ccm_capim "0x0 0x2 0x0 0x0 0x0 0x0 0x0 0x0"
  umr3_close $dbg_ccm_capim

  after 100

  if { [info exists ::HAPS_APP(cfg_h)] } {
    cfg_reset_set $::HAPS_APP(cfg_h) FB1.uA 1
  }

}

## For checking the number bit files in runtime folder
set tsd_file [file join $::env(PCS_WORK) $::env(PCS_PROJECTNAME) runtime system targetsystem.tsd]

set fp [open "$tsd_file" r]
set file_data [read $fp]

set varlist {}
set data [split $file_data "\n"]
foreach line $data {
  if { [string first "fpga_id" $line] != -1 } {
    lappend varlist [lindex [split $line " "] 2]
  }
}
close $fp
set length [llength $varlist]

if { $length == 1} {
  puts "APP_INFO    : Single FPGA bit file found. Skipping HSTDM training step..."
} else {
  puts "APP_INFO    : $length FPGA bit file found. Running the HSTDM training step..."
  # Creating the .hmf
  set hmf_file [file join $::env(PCS_WORK) $::env(PCS_PROJECTNAME) design_haps100.hmf]

  # Get the serial number
  set serial [cfg_status_get_serial_number $::HAPS_APP(cfg_h)]
  set j 0

  set fp [open $hmf_file w]
  puts $fp "\{\"tsdmaphaps\": \n\t\{ "

  foreach var $varlist {
    set fpga [lindex [split $var "."] 1]
    set line "\t\t\"$var\"\: \{\"serial\"\:\"$serial\"\, \"fpga\"\: \"$fpga\"\}"
    incr j
    if {$j < $length} {
      append line "\,"
    }
    puts $fp $line
  }
  puts $fp "\t\}"
  puts $fp "\}"
  close $fp

  # Closing the handle
  cfg_close $::HAPS_APP(cfg_h)
  # Sourcing tdm training script
  source  [file join $::env(HAPS_PRJ_DIR) app auto_script hstdm_training.tcl]
  
  after 100
  # Opening the handle
  set ::HAPS_APP(cfg_h) [cfg_open $::env(EMU)]
  # Giving a reset pulse
  cfg_reset_pulse $::HAPS_APP(cfg_h) FB1.uA 5
  puts "APP_INFO    : HSTDM training is done..."

}
