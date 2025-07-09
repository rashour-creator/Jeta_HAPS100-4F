# ----------------------
# Configure the debugger
# ----------------------
proc check_env {envir value} {
	if {[info exist ::env($envir)] && $::env($envir) == $value} {
		return 1
	}
	return 0
}

set rt_sys_dir [file join $::env(PCS_WORK) $::env(PCS_PROJECTNAME) runtime system debug]
set IICE_ID IICE_core_clk
set trigger "haps_soc.axi_extmem.ar__#valid"



project open "[file join $rt_sys_dir debug.prj]"
com cabletype umrbus
com check


iice link -train -iice "$IICE_ID"

after 2500
iice sampler -triggertime early -iice "$IICE_ID"
watch enable -iice "$IICE_ID" -condition 0 $trigger {1'b0} {1'b1}
statemachine clear 0
statemachine addtrans -from 0 -to 0 -cond {c0} -trigger -iice "$IICE_ID"

run -iice "$IICE_ID" -wait

write fsdb "$rt_sys_dir/$IICE_ID.fsdb" -iice "$IICE_ID"


exit
