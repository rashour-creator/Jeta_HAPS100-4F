# ----------------------
# Configure the debugger
# ----------------------
set rt_sys_dir [file join $::env(PCS_WORK) $::env(PCS_PROJECTNAME) runtime system readback]
set IICE_ID Readback

proc readback_set {fb} {
  global rt_sys_dir
  global IICE_ID

  set fpga      [lindex [split $fb "_"] 1]
  set board     [lindex [split $fb "_"] 0]
  set filename  [file join $rt_sys_dir "$fb.ll"]

  if { [file exists $filename] == 1} {
	  readback set -llfile $filename -fpga "$board.$fpga" -iice $IICE_ID
  }

}

project open "[file join $rt_sys_dir debug.prj]"
com cabletype umrbus

iice current $IICE_ID
readback set -clear
readback_set "FB1_uA"
readback_set "FB1_uB"
readback_set "FB1_uC"
readback_set "FB1_uD"
readback set -apply

run -wait -wait_for_trigger extn -release_clock yes -readback 1000 -stepping 2 -iice $IICE_ID

write fsdb "$rt_sys_dir/$IICE_ID.fsdb" -iice $IICE_ID

exit
