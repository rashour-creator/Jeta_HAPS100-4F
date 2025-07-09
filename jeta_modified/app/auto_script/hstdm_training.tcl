## Creator Poojitha Bommu
############# Runs HSTDM Training ############
package require proto_rt
proto_rt::run_ipinfra -hmf [file join $::env(PCS_WORK) $::env(PCS_PROJECTNAME) design_haps100.hmf] -train all
proto_rt::run_ipinfra -hmf [file join $::env(PCS_WORK) $::env(PCS_PROJECTNAME) design_haps100.hmf] -report_verbose all -file [file join  $::env(PCS_WORK) $::env(PCS_PROJECTNAME) haps_train.rpt]
