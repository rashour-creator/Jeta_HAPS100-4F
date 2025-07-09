# -*-GNUmakefile-*-
#  _______________________________________________
# Makefile wrapper for VCS Elaboration and UMRBus simulation from ProtoCompiler installation
# Based on ProtoCompiler version: S-2021.09-B139_HEAD
#  _______________________________________________

DEBUG                      ?= 0
HAPS_SYSTEM                ?= HAPS-100
CWD                         = $(shell readlink -f `pwd`)
HAPS_PRJ_DIR               ?= $(shell readlink -f `pwd`/../..)
SIM_DIR                    ?= $(shell readlink -f `pwd`/../sim)

#  _____  User env settings  _____
#export DUT_NAME            ?= <path>
#INFO_VARS                  += DUT_NAME .

#  _____  User UMRBus 3.0 settings  _____
UMR3_DATA_BITWIDTH         ?= 256
UMR_DEVICE                 ?= 300
#UMR3_SIM_SERVER_PORT        = <RANDOM 49152-65536>
UMR3_SIM_TIMEOUT           ?= 300
LSUMR3                     ?= 1
UMRBUSSCAN                 ?= 1
CHKUMR3                    ?= 0
CFLAGS                      = -I$(HAPS_INSTALL_DIR)/linux_a_64/include -Wall -DUNIX

#  _____  User application shell settings (0|XTERM|TCL|VPE|VPS|<script>)  _____
APP_SHELL                  ?= 0
APP_SHELL_CWD              ?= $(CWD)

#  _____  User RTL & VCS settings  _____
GUI                        ?= 0
TOPLEVEL                   ?= $(PCS_SIM_TOPLEVEL)
#override FILELIST_DIRS     += <path>
override VERILOG_DEFINES   += SIMULATION
#override VLOGAN_FLAGS      += <global flags>
#override VERILOG_FILES     += <file>
override VERILOG_FILES     += ${PCS_VIVADO_IP_OUTDIR}/haps100_axi_extmem_${PCS_VERSION_VIVADO}/axi_extmem_sim_netlist.v 
override VERILOG_FILES     += ${PCS_VIVADO_IP_OUTDIR}/haps100_axi_mmio_${PCS_VERSION_VIVADO}/axi_mmio_sim_netlist.v
override VERILOG_FILELISTS += ${PCS_VIVADO_IP_OUTDIR}/haps100_mig_ddr4_${PCS_VERSION_VIVADO}/mig_ddr4_sim.vc
override VERILOG_FILELISTS += ${HAPS_PRJ_DIR}/rtl/sim/ddr4_sim.vc
#override VHDLAN_FLAGS      += <global flags>
#override VHDL_FILELISTS    += <file>
VCS_CPUS                   ?= 4
#DEFAULT_VCS_FLAGS           = < overwrite defaults if needed, check defaults with make info >
override VCS_FLAGS         += -debug_access+all +plusarg_save +model_data+./simv.daidir +vcs+lic+wait +incdir+${DW_PRJ_DIR}/i_axi_a2x/src +incdir+${DW_PRJ_DIR}/i_axi_a2x_1/src +incdir+${DW_PRJ_DIR}/i_axi/src 
SIMV_NOSTDOUT              ?= 1
#override SIMV_FLAGS        += +vpd_dump_all
#override SIMV_FLAGS        += +fsdb_dump_all
#VCS_FLOW                   ?= 2|3-step
SIM_LOG_SHELL              ?= 0

#  _______________________________________________
#  _____  DO NOT DELETE THIS FOOTER SECTION  _____
#  _____  Optional, define required tool variables  _____
#export VCS_HOME         =
#export VERDI_HOME       =
#export HAPS_INSTALL_DIR =
#export XILINX_VIVADO    =
#  _____  include main Makefile for VCS Elaboration and UMRBus simulation from ProtoCompiler installation  _____
ifndef HAPS_INSTALL_DIR
      $(error *** make error *** HAPS_INSTALL_DIR not valid - please load environment for ProtoCompiler)
endif
include $(HAPS_INSTALL_DIR)/lib/umrbus3/scripts/vcs/umr3_sim.mk
