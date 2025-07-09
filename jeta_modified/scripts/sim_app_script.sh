#!/bin/sh
##############################################################################
#  Copyright (C) 2013-2021 Synopsys, Inc.
#  This script and the associated documentation are confidential and
#  proprietary to Synopsys, Inc. Your use or disclosure of this script
#  is subject to the terms and conditions of a written license agreement
#  between you, or your company, and Synopsys, Inc.
##############################################################################
#  Description: used for HAPS UMRBus Simulation to run/control application
#               It is executed as APP_SHELL=<script> in simulation makefile   
#  Version    : R-2020.12-SP1
##############################################################################
#          $Id: //chipit/chipit/main/dev/systems/examples/xtor_riscv_soc/xtor_riscv_soc_h100/scripts/sim_app_script.sh#1 $
#      $Author: khertig $
#    $DateTime: 2022/04/01 06:40:36 $ 
##############################################################################

## compile application, if required

## define test application command
run="confprosh xtor_load_kernel.tcl"

## run either interactive GUI or BATCH mode
if [[ $GUI != 0 ]]; then

  echo "------------------------------------------------------------------------------------"
  echo "APP_SHELL_INFO: Simulation is running in Interactive GUI mode."
  echo "APP_SHELL_INFO: - use upcoming ${GUI} gui to dump signals of interest and to control start/stop the simulation run"
  echo "APP_SHELL_INFO: - use upcoming XTERM titled 'APP_SHELL HAPS UMRBus simulation with VCS ...' to invoke test application, use command line as:"
  echo "APP_SHELL_CMD $   $run"
  echo "APP_SHELL_INFO: - UMRBus simulation needs to be stopped by the user (closing ${GUI} gui will stop simulation)"

  title="APP_SHELL HAPS UMRBus simulation with VCS - `basename $HAPS_PRJ_DIR` $HAPS_SYSTEM"
  (xterm -T "${title}"; echo -e "\nINFO: Stop UMRBus Simulation ..."; make -C $SIM_DIR -f $PCS_SIM_MAKE stop > /dev/null) &
  APP_PID=$!
  echo ""
  echo "APP_SHELL_INFO: Start app terminal with title '$title' (PID=$APP_PID)" 

else

  echo ""
  echo "----------------------------------------------------"
  echo "APP_SHELL_INFO: Running test application ..."
  echo "APP_SHELL_INFO: Start UMR3 virtual uart app in xterm ..."
  #xterm -ls -hold -T \"UMR3 VUART Terminal\" -e /bin/bash -c ./cpp/umr3_virtual_uart &
  xterm -ls -hold -T \"UMR3 VUART Terminal\" -e /bin/bash -c ${HAPS_PRJ_DIR}/cpp/umr3_virtual_uart &
  echo "APP_SHELL_CMD $ $run"
  eval $run || exit 1
  make -C $SIM_DIR -f $PCS_SIM_MAKE stop

fi

echo ""
