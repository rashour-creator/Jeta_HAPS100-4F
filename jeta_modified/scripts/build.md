# QuickStart

## Software Requirements:

**OS**:

- Linux :  64-bit

- Windows : 64-bit (only HAPS System Configuration & Run Design Verification)

This application note has been developed and verified using the listed versions of the software 
products.
 
**Synopsys Licensed Product(s)**
- HAPS ProtoCompiler(S) - R-2020.12-SP1-1
- VERDI                 - R-2020.12-SP2-6 (optional for simulation)
- VCS                   - 2020.03-SP2-10

**Xilinx Licensed Product(s)**
- Vivado Design Suite   - 2020.1

**Others**
- GCC v7.3.0         - for compile with the ProtoCompiler libraries under Linux
- GNU Binutils v2.30 - for linking with the ProtoCompiler libraries under Linux 
- GNU Make v3.81     - for reading Makefiles under Linux


**How to create database using pcs commands**

- To generate the work directory (less than one minute)

```
% pcs -xgen  // generate axi_master_xactor and axi_mmio_master_xactor
```

- To generate necessary xilinx board files or xilinx-ips

```
% pcs -x -bd ./scripts/axi_extmem.hbd  ~ 08 mins (no re-run once ready) //transactor (axi_mater_xactor) and ddr and rocket_chip connections are inside
% pcs -x -bd ./scripts/axi_mmio.hbd    ~ 11 mins (no re-run once ready) //bram_ctrl and uart blocks inside
% pcs -x -ip ./scripts/mig_ddr4.hip    ~ 20 mins (no re-run once ready) //mid_ddr4 memory inside
```

 - RTL simulation with VCS

```
% pcs -rtl_sim                         ~5min
```

 - Design implementation based on ProtoCompiler Scripting

```
% pcs -xterm                           ~1h10min 
```
