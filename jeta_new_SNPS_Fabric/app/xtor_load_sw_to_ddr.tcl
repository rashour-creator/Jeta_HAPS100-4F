set script_dir [file dirname [info script]]
source $script_dir/xtor_common.tcl

## Open control capim 
puts "TCL-INFO    : Open Ctrl CAPIM ($emu $bus $capim_ctrl) ..."
set h_capim [umrbus_open $emu $bus $capim_ctrl]

## Open control AXI Master
puts "TCL-INFO    : Open AXI Master ($emu $bus $xtor_axi) ..."
set h_axi  [ta_open master $emu $bus $xtor_axi axi_master 64 32]
 
puts "TCL-INFO    : Ctrl CAPIM State > [getCapim]"
puts "TCL-INFO    : Assert DUT nreset"
setCapimBitTo $BIT(dut_nreset) 0
puts "TCL-INFO    : Ctrl CAPIM State > [getCapim]"

puts "TCL-INFO    : wait for DDR init done "
while { ![expr [getCapim] & 0x1] } {
  after 1000
  puts -nonewline "."
}
puts ""

puts "TCL-INFO    : Loading '$fileName' to $loadaddr"
set count [expr $burst * $word]

set f [open $fileName r]
fconfigure $f -translation binary -encoding binary -buffering full  

while { 1 } {
  set addr [tell $f]
  set buffer [read $f $count]

  binary scan $buffer cu* data 
  ta_write $h_axi $loadaddr $data
		 
  set loadaddr [expr $loadaddr + $count]
  #puts "@D: loadaddr = $loadaddr"
  if { [eof $f] } {
     close $f
     break
  }		 
}

puts "TCL-INFO    : Ctrl CAPIM State > [getCapim]"
puts "TCL-INFO    : Deassert DUT nreset"
setCapimBitTo $BIT(dut_nreset) 1
puts "TCL-INFO    : Ctrl CAPIM State > [getCapim]"

ta_close  $h_axi
umrbus_close $h_capim

