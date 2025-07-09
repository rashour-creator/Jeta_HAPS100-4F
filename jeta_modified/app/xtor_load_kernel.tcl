# -*-tcl-*-
##############################################################################
#  Copyright (C) 2017-2022 Synopsys, Inc.
##############################################################################
#  Description : Pre-load Kernel bin over HAPS transactor
##############################################################################
#          $Id: //chipit/chipit/main/dev/systems/examples/xtor_riscv_soc/app/xtor_load_kernel.tcl#7 $
#      $Author: khertig $
#    $DateTime: 2022/03/29 01:43:26 $ 
##############################################################################

package require xactors

proc setCapimBitTo {bit value} {
  global h_capim

  set capim_read  [umrbus_read  $h_capim 1]
  set capim_write [expr {$value ? $capim_read | (1 << $bit) : $capim_read & ~(1 << $bit)}]
  #puts "umrbus_write @D: bit=$bit capim_write=[format %08X $capim_write]"
  puts "TCL-INFO    : UMRBus Write Ctrl CAPIM($bit)=$value"
  umrbus_write $h_capim capim_write 
}

proc getCapim {} {
  global h_capim

  return [format 0x%08X [umrbus_read $h_capim 1]]
}

# #############################################################################
# check scan for simulation
# #############################################################################
catch {umrbus_scan} UMRBusScanResult
set CONFIG(SIM) 0

foreach n $UMRBusScanResult {
  set s [lindex $n 4]
  if { [string range $s 1 8] == "umr3_sim" } {
    set CONFIG(SIM) 1
    puts "TCL-INFO   : UMRBus 3.0 Simulation found"
    break
  } elseif { $s == "PLI" } {
    set CONFIG(SIM) 1
    puts "TCL-INFO   : UMRBus 2.0 PLI Simulation found"
    break
  }
}

set fileName   [file join [file dir [file normalize [info script]]] riscv-linux kernel.bin]
set emu        $env(UMR_DEVICE)
set loadaddr   0x80000000
set burst      256
set word       8
set bus        1
set xtor_axi   1
set capim_ctrl 3

## define bits of Ctrl CAPIM
set BIT(phys_uart)  4
set BIT(dut_nreset) 5

## Open control capim 
puts "TCL-INFO    : Open Ctrl CAPIM ($emu $bus $capim_ctrl) ..."
set h_capim [umrbus_open $emu $bus $capim_ctrl]

puts "TCL-INFO    : Open AXI Master ($emu $bus $xtor_axi) ..."
set h_axi  [ta_open master $emu $bus $xtor_axi axi_master 64 32]
 
puts "TCL-INFO    : Ctrl CAPIM State > [getCapim]"
puts "TCL-INFO    : Assert DUT nreset"
setCapimBitTo $BIT(dut_nreset) 0
puts "TCL-INFO    : Ctrl CAPIM State > [getCapim]"

## enable physical uart (for HAPS-100 only, puart is default for HAPS-80)
if { [regexp "HAPS-100" $env(HAPS_SYSTEM)] } {
  set vuart 1
  puts "TCL-INFO    : control physical(1) or virtual-uart(0) via env EN_PUART ..."
  setCapimBitTo $BIT(phys_uart) [expr {[info exists env(EN_PUART)] ? $env(EN_PUART) : 0}]
  puts "TCL-INFO    : Ctrl CAPIM State > [getCapim]"
}

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

if { [regexp "HAPS-100" $env(HAPS_SYSTEM)] && [info exists vuart] } {
  puts "TCL-INFO    : Close Virtual UART terminal to exit ..."
}	
