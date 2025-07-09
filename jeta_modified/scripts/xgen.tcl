# -*-tcl-*-
##############################################################################
#  Description : create HAPS XGEN project
##############################################################################
package require xactors_gen

## create project
xgen_project new $env(PCS_WORK)

## set project options
xgen_project set output_structure 1 ; # comment that line for protocompiler 2020.03--
xgen_project set platform $env(HAPS_SYSTEM)
xgen_project set toplevel $env(PCS_TOPLEVEL)
#xgen_project set sim_path_toplevel sim_tb.i_$env(PCS_TOPLEVEL)
xgen_project set sim_path_toplevel $env(PCS_TOPLEVEL)
xgen_project set templates no
xgen_project set scriptsdir off
 
# AXI MASTER TRANSACTOR
# add module 'axi_master_xactor'
xgen_add module axi_master_xactor i_axi_master_xactor

xgen_add xactor axi_master_xactor axi4_master i_axi_master

xgen_set axi_master_xactor i_axi_master FLOW_DEPTH 0
xgen_set axi_master_xactor i_axi_master DATA_WIDTH 64
xgen_set axi_master_xactor i_axi_master XACTOR_ID 1
xgen_set axi_master_xactor i_axi_master ADDR_WIDTH 32
xgen_set axi_master_xactor i_axi_master BURST_LIMIT 0
xgen_set axi_master_xactor i_axi_master UMR_INPORT_FIFO_DEPTH 2048
xgen_set axi_master_xactor i_axi_master MAX_FLIGHT 5
xgen_set axi_master_xactor i_axi_master XACTOR_COMMENT "i_axi_master_xactor"
xgen_set axi_master_xactor i_axi_master UMR_OUTPORT_FIFO_DEPTH 4095

# add module 'axi_master_xactor'
xgen_add module axi_mmio_master_xactor i_axi_mmio_master_xactor

xgen_add xactor axi_mmio_master_xactor axi4_master i_axi_master

xgen_set axi_mmio_master_xactor i_axi_master FLOW_DEPTH 0
xgen_set axi_mmio_master_xactor i_axi_master DATA_WIDTH 64
xgen_set axi_mmio_master_xactor i_axi_master XACTOR_ID 2
xgen_set axi_mmio_master_xactor i_axi_master ADDR_WIDTH 32
xgen_set axi_mmio_master_xactor i_axi_master BURST_LIMIT 0
xgen_set axi_mmio_master_xactor i_axi_master UMR_INPORT_FIFO_DEPTH 2048
xgen_set axi_mmio_master_xactor i_axi_master MAX_FLIGHT 5
xgen_set axi_mmio_master_xactor i_axi_master XACTOR_COMMENT "i_axi_mmio_master_xactor"
xgen_set axi_mmio_master_xactor i_axi_master UMR_OUTPORT_FIFO_DEPTH 4095

# create output
xgen_create

