#!/bin/sh

if [[ $CI_JOB_STAGE == "build" ]]; then
	if  [[ $CI_RUNNER_TAGS == "sglabn9lnx" ]]; then 
		setenv XILINXD_LICENSE_FILE 21050@us01-lic89:21050@us01vglmd3p1:$XILINXD_LICENSE_FILE
	fi
	setenv RUN_DIR $1
elif [[ $CI_JOB_STAGE == "deploy" ]]; then
	if  [[ $CI_RUNNER_TAGS == "sglabn9lnx" ]]; then 
		setenv LM_LICENSE_FILE 26585@us01genlic:26585@us01snpslmd1:$LM_LICENSE_FILE
		setenv SNPSLMD_LICENSE_FILE 26585@us01genlic:26585@us01snpslmd1:$SNPSLMD_LICENSE_FILE
	fi
fi
if [[ $CI_JOB_NAME == "golden" ]]; then
	module load protocompiler/2020.12-SP1-1
	module load verdi/2020.12-SP2-6
	module load vivado/2020.1
	module load vcs/2020.03-SP2-10
elif [[ $CI_JOB_NAME == "weekly" ]]; then
	module load protocompiler/2020.12-SP1-1
elif [[ $CI_JOB_STAGE == "deploy" ]]; then
	module load protocompiler/2020.12-SP1-1
	module load verdi/2020.12-SP2-6
fi
