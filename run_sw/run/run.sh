#!/bin/bash

if [ "$1" = "load_design" ] ;then
	confprosh $PROJECT_PATH/jeta_new_SNPS_Fabric/app/configure_board_and_design.tcl $PROJECT_PATH/jeta_new_SNPS_Fabric/runtime_with_added_slave/runtime/system/targetsystem.tsd
	## (umrbusscan -l command to define the device number)
	export emu_Device=300
	## These steps are required only for protocompiler runtime and verdi tools to check the waveform
	
    ## protocompiler100_runtime &
	##trigger the signal you need from protocompiler_runtime GUI but without running it
	
elif [ "$1" = "assert_processor_reset" ] ;then
	confprosh $PROJECT_PATH/jeta_new_SNPS_Fabric/app/xtor_reset_processor.tcl
	##These steps are required only for protocompiler runtime and verdi tools to check the waveform
	##run this triggered signal in the previous step by protocompiler_runtime GUI (Run button)

elif [ "$1" = "load_sw" ] ;then
	confprosh $PROJECT_PATH/jeta_new_SNPS_Fabric/app/xtor_load_sw_to_ddr.tcl   #define the bin file that you want to run in this tcl file"
	##These steps are required only for protocompiler runtime and verdi tools to check the waveform
	##The waveform viewer icon in protocompiler_runtme GUI will be activated automatically to see the waveform

fi



