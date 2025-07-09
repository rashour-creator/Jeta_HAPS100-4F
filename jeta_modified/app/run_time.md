# QuickStart

## Software Requirements:

**OS**:

- Linux :  64-bit

- Windows : 64-bit (only HAPS System Configuration & Run Design Verification)

This application note has been developed and verified using the listed versions of the software 
products.
 
**Synopsys Licensed Product(s)**
-  HAPS ProtoCompiler(S) - R-2020.12-SP1-1
-  VERDI                 - R-2020.12-SP2-6 (for observing waveform)

## Hardware Requirements:
 - HAPS-100
 - optional HAPS GPIO_HT3 + USB serial UART cable (recommend to use Virtual UART over UMRBus3)
 - HAPS DDR4_HT3 or DDR4_U16GB_HT3 Daughter Board - (onboard Clock Generator 200 MHz, 
       differential)
    + MTA18ASF1G72PDZ-2G(1A|3B)1 --- Micron  8GB RDIMM (1 Gig x 72) dual rank x8, ECC
    + MTA16ATF2G64AZ-2G(6E)1     --- Micron 16GB UDIMM (2 Gig x 64) dual rank x8, PC4-2666
 - HAPS UMRBus® Interface Kit (CDE) or USB Cable

**How to run hardware test using pcs commands**
 - HAPS system configuration plus verification (less than one minute)

```
% pcs -hw
```
