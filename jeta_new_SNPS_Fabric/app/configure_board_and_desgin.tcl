# Set the device
#join [cfg_scan]\n gives the available devices either for HAPS80 (mainly device number 8 and 9) and for HAPS100 (mainly device number 200 and 300 which are pci and usb for same serial number and same device mainly).
set device "/umr3pci0/pci-0280-p1/mod-E030706"

# Check if an argument for the .tsd file was provided
if {[llength $argv] < 2} {
    puts "ERROR: Missing .tsd file argument."
    exit 1
}

set tsd_file [lindex $argv 1]

puts "INFO: Device serial is $device"
puts "INFO: TSD file is $tsd_file"

# Check if the file exists and is in the correct directory
if {![file exists $tsd_file]} {
    puts "ERROR: TSD file '$tsd_file' not found."
    exit 1
}

if {![file readable $tsd_file]} {
    puts "ERROR: TSD file '$tsd_file' is not readable."
    exit 1
}

# Open the HAPS HW device
set cfg_var [cfg_open $device]

# Add the bit files to HW device (TSD file) (program the HAPS board device)
cfg_project_configure $cfg_var $tsd_file 

# Check the reset status
set reset_value [cfg_reset_get $cfg_var FB1.uA] 

# Release the reset if necessary
if {$reset_value == 0} {
    puts "INFO: Deasserting reset"
    cfg_reset_set $cfg_var FB1.uA 1 
} else {
    puts "Warning: Reset value is not 0"
}



