## Overview

This branch is derived from the `main` branch "https://gitsnps.internal.synopsys.com/haps/jeta.git" and introduces several enhancements to support new hardware configurations and software capabilities. The modifications are outlined in the following sections.

## Purpose

The primary goal of this branch is to extend the functionality of the original design by incorporating the following features:

- Replacing the TSS file in the JETA design with a version compatible with the **HAPS-100_4F** board.
- Updating the `partition.pcf` file to enable compilation for a **single FPGA** instead of two.
- Modifying the JETA design to create a new variant that includes an **AXI slave transactor** connected to the `SNPS_Fabric` bus.
- Integrating the **RISC-V toolchain** to compile C applications targeting the **Rocketchip processor**.

## Directory Structure

### `jeta_modified`

This directory contains a modified version of the original JETA design with the following changes:

- The `partition.pcf` file has been updated to support single FPGA compilation.
- The TSS file has been replaced with one compatible with the **HAPS-100_4F** board.
- The `UMR_CAPIM_TYPE` has been updated to match the board configuration.

✅ The design compiles successfully for a single FPGA and the HAPS-100_4F board.

- Compilation output: [Runtime directory](./jeta_modified/runtime)
- Compilation instructions: [README](./jeta_modified/README.md)
- Precompiled Linux kernel for validation: [kernel.bin](./jeta_modified/app/riscv-linux/kernel.bin)
- To run this kernel.bin, go to this readme file:[README](./run_sw/readme.md)

---

### `jeta_added_new_SNPS_Fabric`

This directory contains a variant of the JETA design with an added **AXI slave transactor** on the `SNPS_Fabric` bus.

- The `partition.pcf` file is updated for single FPGA compilation.
- The TSS file for **HAPS-100_4F** is used.

✅ The design compiles successfully for a single FPGA and the HAPS-100_4F board.

- Compilation output: [Runtime directory](./jeta_new_SNPS_Fabric/runtime_with_added_slave)
- Compilation instructions: [README](./jeta_new_SNPS_Fabric/README.md)
- Precompiled Linux kernel for validation: [kernel.bin](./jeta_new_SNPS_Fabric/app/riscv-linux/kernel.bin)
- To run this kernel.bin, go to this readme file:[README](./run_sw/readme.md)

---

### `RISCV_toolchain`

This directory contains the RISC-V toolchain used to compile C applications for the Rocketchip processor.

- Supports **Rocket**, **AndesCore**, and **SiFive** CPUs.
- Can be used from any directory without requiring a rebuild.
- Compatible only with **AlmaLinux** (not CentOS).
- This toolchain can be accesses from this "https://gitsnps.internal.synopsys.com/haps/jeta.git"   #(jeta_cairo_team branch).

