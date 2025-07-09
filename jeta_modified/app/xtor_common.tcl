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


#set fileName   [file join [file dir [file normalize [info script]]] riscv-linux kernel.bin]
#set fileName   [file join [file dir [file normalize [info script]]] riscv-linux hello.bin]
#set fileName   [file join [file dir [file normalize [info script]]] riscv-linux hello_world.bin]
#set fileName   [file join [file dir [file normalize [info script]]] riscv-linux transactor_test.bin]
set fileName   [file join [file dir [file normalize [info script]]] riscv-linux new_make_tool.bin]
set emu        300
set loadaddr   0x80000000
set burst      256
set word       8
set bus        1
set xtor_axi   1
set capim_ctrl 3

## define bits of Ctrl CAPIM
set BIT(phys_uart)  4
set BIT(dut_nreset) 5
puts "The file name is: $fileName" 
