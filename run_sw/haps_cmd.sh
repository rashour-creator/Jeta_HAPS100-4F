#!/bin/bash
export PROJECT_PATH=$(dirname "$(readlink -f "$0")")

if [ "$1" = "help" ] ;then
	echo " ***................***
Command options:
	- setup: loading the required tools to specify the environmnt required to run this directory.
	- load_design: program the HAPS-100-4F board by the tsd file of this jeta design.
	- assert_processor_reset: assert the reset of the processor to run the trigger signals defined in protocompiler100_runtime
	- load_sw: load the sw (.bin file) to DDR and deassert the reset of the processor to execute the instructions. 
	"
else

	if [ "$1" = "setup" ] ;then
		source $PROJECT_PATH/setup.sh

	elif [ "$1" = "load_design" ] ;then
		source $PROJECT_PATH/run/run.sh $1
	
	elif [ "$1" = "assert_processor_reset" ] ;then
		source $PROJECT_PATH/run/run.sh $1

	elif [ "$1" = "load_sw" ] ;then
		source $PROJECT_PATH/run/run.sh $1

	fi
fi
