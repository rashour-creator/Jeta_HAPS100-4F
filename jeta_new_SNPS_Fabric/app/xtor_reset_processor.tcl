set script_dir [file dirname [info script]]
source $script_dir/xtor_common.tcl

## Open control capim 
puts "TCL-INFO    : Open Ctrl CAPIM ($emu $bus $capim_ctrl) ..."
set h_capim [umrbus_open $emu $bus $capim_ctrl]

puts "TCL-INFO    : Ctrl CAPIM State > [getCapim]"
puts "TCL-INFO    : Assert DUT nreset"
setCapimBitTo $BIT(dut_nreset) 0
puts "TCL-INFO    : Ctrl CAPIM State > [getCapim]"
umrbus_close $h_capim
