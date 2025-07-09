# ----------------------
# Configure the debugger
# ----------------------
package require DF

set serial [cfg_status_get_serial_number $::HAPS_APP(cfg_h)]
#puts "TCL-INFO    : Serial number is $serial"
DF::df_open [file join $::env(PCS_WORK) $::env(PCS_PROJECTNAME) runtime] $serial

puts "TCL-INFO    : Current value for Software reset signal => [value haps_soc.sw_rst_sync]"

after 200
force haps_soc.sw_rst_sync 0
puts "TCL-INFO    : Software reset signal "
