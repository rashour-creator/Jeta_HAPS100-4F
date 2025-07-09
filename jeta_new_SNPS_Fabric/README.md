v# Jeta with extra axi slave transactor

Contents :

[[_TOC_]]

## Introduction to Design

RISC design with project name - “Jeta_new_SNPS_Fabric” SOC.

This is the same jeta design in jeta_modified directory but with modifyed SNPS_Fabric bus and then modified rtl.

This is a basic prototyping flow for a small CPU on HAPS. It handles the basic interfaces such as 
clock, reset and specifically using GPIO_HT3. Also, it covers HAPS features such as transactors, 
DDR as an extended DUT which can boot a full Linux OS

![alt text][logo]

[logo]: img/block_diag.PNG "Basic Block Diagram"


## The differences between this design and jeta design

This design differs from jeta design in modifying the SNPS_Fabric bus.

  - This modification is done by using core Assembler tool (version W-2024.09-2).

  - The i_axi component is newer version than this in jeta so it is 4.06a.

  - The i_axi_a2x component is newer version than this in jeta design so it is 2.06a.

  - The added axi_slave transactor is represented by i_axi_a2x component version 2.06a.

  - The added axi_slave_transactor has base address 0x61000000 and has memory range 0x1000000.

These differences required modifying rtl directory of jeta design.


**Functional Description**
- All capabilities of the Mini SoC
- Boots Linux with using a UART console
- Xilinx AXI UART Lite connected to UART USB on front panel
- Uses DDR4 as main memory
- AXI Master Transactor for memory preload (e.g. Linux kernel image) into DDR4
- AXI Slave Transactor for connecting the design on HAPS board to TLM bus
- MDM support
- Synopsys Design Ware AXI bridge 
- Provides 4 CPU cores
- VUART:  use ./app/cpp/umr3_virtual_uart for Virtual UART over UMRBus3
- PUART:  Micro USB cable from GPIO_HT3 UART connector to host PC Host terminal (e.g., putty, 
          picocom) can be connected @ 38400 Baud, 8 Data bits, 1 Stop bit, No parity, no flow 
          control

**Linux Boot**
- Configure the HAPS system with the FB1_uA.bin file located in the confpro
- Connect a terminal application such as putty to the COM port connected to the USB serial 
  interface of front panel USB1 or using VUART


## QuickStart

```
% git clone git@gitsnps.internal.synopsys.com:haps/jeta.git my_dir
```

Click [ steps_build ](/scripts/build.md) to view steps for create database

Click [ steps_rt ](/app/run_time.md) to view steps for hardware test


## Creating branches for specific features

```
% git checkout -b featurexxxx/yyyy
% git push --set-upstream origin featurexxxx/yyyy
```

Here xxxx can be haps/rtls/krnl
While yyyy can be specific feature which is to be added

In case of updation due to software version change the name of branch should be sw_name/version


## Known Limitation

- Only FULL_SOC=multi configuration is tested on HAPS with single FPGA A
- Cascaded BUFGCE issue in Virtual UART IP

## SupportNet:

[DDR4_HT3](https://www.synopsys.com/apps/protected/hapssupportnet/download.php?file=cd/manuals/doc-00000027_ddr4_ht3.pdf)

[HAPS-100_12F](https://www.synopsys.com/apps/protected/hapssupportnet/download.php?file=cd/manuals/haps-100_12f.pdf)

[HAPS-100_4F](https://www.synopsys.com/apps/protected/hapssupportnet/download.php?file=cd/manuals/haps-100_4f.pdf)

[HAPS-100_1F](https://www.synopsys.com/apps/protected/hapssupportnet/download.php?file=cd/manuals/haps-100_1f.pdf)

**Support**

For technical assistance, go to Synopsys SolvNet® and open a support case.
