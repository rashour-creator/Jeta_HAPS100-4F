device jtagport umrbus
device prepare_incremental 1


if { [info exists env(ENABLE_DEBUG)] && $env(ENABLE_DEBUG) == 1 } {

	iice new {IICE_core_clk} -type regular
	iice clock -iice {IICE_core_clk} -edge positive {sys_clk}
	iice controller -iice {IICE_core_clk} statemachine
	iice controller -iice {IICE_core_clk} -triggerstates 4
	iice controller -iice {IICE_core_clk} -triggerconditions 4
	iice controller -iice {IICE_core_clk} -counterwidth 16
    if { [info exists env(ENABLE_GSV)] && $env(ENABLE_GSV) == 0 } {
	    iice sampler -iice {IICE_core_clk} haps100_DTD_builtin
		iice sampler -iice {IICE_core_clk} -depth 16384
    } else {
		iice sampler -iice {IICE_core_clk} -depth 1024
	}
	
	iice new {IICE_axi_DDR} -type regular
	iice clock -iice {IICE_axi_DDR} -edge positive {haps_soc.axi_DDR.clk}
	iice controller -iice {IICE_axi_DDR} statemachine
	iice controller -iice {IICE_axi_DDR} -triggerstates 4
	iice controller -iice {IICE_axi_DDR} -triggerconditions 4
	iice controller -iice {IICE_axi_DDR} -counterwidth 16
	iice sampler -iice {IICE_axi_DDR} -depth 1024

}

if { [info exists env(ENABLE_DF)] && $env(ENABLE_DF) == 1 } {
	iice new {IICE_DF} -type regular
	iice clock -iice {IICE_DF} -edge positive {sys_clk}
	iice sampler -iice {IICE_DF} -depth 1024
}
