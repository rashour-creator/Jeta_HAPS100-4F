#!/bin/sh
##############################################################################
#  Copyright (C) 2020-2022 Synopsys, Inc.
#  This script and the associated documentation are confidential and
#  proprietary to Synopsys, Inc. Your use or disclosure of this script
#  is subject to the terms and conditions of a written license agreement
#  between you, or your company, and Synopsys, Inc.
##############################################################################
#  Description: HAPS Project environment setup BASH script (auto-sourced by pcs)
#               This settings script is intend to be AUTOMATICAL sourced by pcs wrapper
#               Source ONLY to permanent set the environment for the active prompt by using force switch
#  Version    : S-2021.09-B139_HEAD
##############################################################################
#          $Id: //chipit/chipit/main/dev/systems/examples/xtor_riscv_soc/xtor_riscv_soc_h100/haps_prj_env.sh#3 $
##############################################################################

## add pre-check to interrupt if not auto sourced by PCS
if [[ -z $PCS_CRC && `echo $1 | tr a-z A-Z` != "FORCE" ]]; then
  echo "PCS-ERROR: It is not recommended to manual source this script (adding 'force' switch will source anyway)"
  return 1
fi

## Control Tool setup based on their main Env variables (adapt to match Customer specific environment)
## On Synopsys machines:
## - the 'default' tool version from modules env will be used if their main Env variable is defined with empty content
## - mandatory tools as VCS_HOME and XILINX_VIVADO will be used even with their main Env variable unset or commented
## Customer environment:
## - add valid installation pointer for respective main tool variable
export XILINX_VIVADO=
export VCS_HOME=
#export VERDI_HOME=
#export SNPS_VP_HOME=
#export SYNOPSYS=
#export GATEWAY_HOME=
## Optional, use PROTOCOMPILER_HOME to force a specific ProtoCompiler release but use PCS from HAPS_INSTALL_DIR 
#export PROTOCOMPILER_HOME=

## Control lisence settings
#preenv SNPSLMD_LICENSE_FILE 
#preenv XILINXD_LICENSE_FILE 

## HAPS project variables
export HAPS_UFPGAS=${HAPS_UFPGAS:=one}     			; # use "one" or "two"
export FULL_SOC=${FULL_SOC:=multi}         			; # use "multi" or "single" (CAUTION: single failed runtime test)
export ENABLE_GSV=${ENABLE_GSV:=0}         			; # use "0" or "1"
export ENABLE_DEBUG=1   	; # use "0" or "1"
#export ENABLE_DEBUG=${ENABLE_DEBUG:=${ENABLE_GSV}} 	; # use "0" or "1"
export ENABLE_TDM=${ENABLE_TDM:=0}         			; # use "0", "hstdm" or "mgtdm"
export ENABLE_DF=${ENABLE_DF:=0}           			; # use "0" or "1"
export HAPS_DDR4_HT3=${HAPS_DDR4_HT3:=a24}
export HAPS_GPIO_HT3=${HAPS_GPIO_HT3:=a11}


export PCS_FORCE_VIVADO=1
export PCS_FORCE_VCS=1
export PCS_FORCE_VERDI=1
## Selection of Common HAPS/PCS environment variables (force or use defaults)
export HAPS_PRJ_DIR=`pwd`
##### added by ritesh and commented later export HAPS_PRJ_DIR=/SCRATCH/gst/jeta
export PCS_WORK=${PCS_WORK:=${HAPS_PRJ_DIR}/work}
#### commented by Riteshand commented later  export PCS_WORK=/SCRATCH/gst/jeta/work

export HAPS_SYSTEM="HAPS-100_4F"
#export PCS_INTERACTIVE=0                                                ; # <0|1>       Default 1
export PCS_TOPLEVEL=haps_soc
export PCS_SIM_TOPLEVEL=haps_soc
export PCS_PROJECTNAME=pcs_${HAPS_UFPGAS}_${FULL_SOC}
export PCS_XGEN_SCRIPT=./scripts/xgen.tcl
#export PCS_SCRIPT=./scripts/config.tcl
export PCS_SCRIPT=${HAPS_PRJ_DIR}/scripts/config.tcl
#export PCS_SIM_MAKE=./scripts/Makefile
export SIM_DIR=${PCS_WORK}/sim
export APP_SHELL=./scripts/sim_app_script.sh
#export APP_SHELL=XTERM
export APP_SHELL_CWD=${HAPS_PRJ_DIR}/app
export PCS_VIVADO_IP_OUTDIR=${PCS_WORK}/vivadoips
#export VCS_IGNORE_ENV=""
export VERILOG_DEFINES="NO_VERDI_DUMP NO_VCS_DUMP ${HAPS_SYSTEM/-/} RDIMM"
export VERILOG_FILELISTS="${HAPS_PRJ_DIR}/rtl/rocket-chip.vc ${HAPS_PRJ_DIR}/rtl/noc_rtl.vc "
export VERILOG_FILELISTS+="${HAPS_PRJ_DIR}/rtl/umr3_virtual_uart.vc ${HAPS_PRJ_DIR}/rtl/haps_lib.vc ${PCS_WORK}/rtl/xgen.vc "
export DW_PRJ_DIR="${HAPS_PRJ_DIR}/rtl/SNPS_fabric/components"
export VCS_FLAGS="+incdir+${DW_PRJ_DIR}/i_axi_a2x/ +incdir+${DW_PRJ_DIR}/i_axi_a2x_1/ +incdir+${DW_PRJ_DIR}/i_axi/ "
echo $PCS_PROJECTNAME
echo $HAPS_UFPGAS
echo $FULL_SOC
echo $ENABLE_DEBUG

## ProtoCompiler specific env
#export ${PC_SELECT^^}_LICENSE_FEATURE=<value>
#export ${PC_SELECT^^}_LICENSE_WAIT=<waitTime>

## General env
#preenv PATH /depot/gcc-7.3.0/bin
#preenv PATH /depot/binutils-2.30/bin
#preenv PATH /depot/make-3.81/bin
