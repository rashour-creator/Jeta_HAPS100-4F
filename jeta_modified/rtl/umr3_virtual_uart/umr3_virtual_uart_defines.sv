/******************************************************************************
   Copyright (C) 2020-2021 Synopsys, Inc.
   This IP and the associated documentation are confidential and
   proprietary to Synopsys, Inc. Your use or disclosure of this IP is 
   subject to the terms and conditions of a written license agreement 
   between you, or your company, and Synopsys, Inc.
*******************************************************************************
   Title      : UMR3 VIRTUAL UART defines
   Project    : Anaconda
   Description: This module defines the macros/switches by VUART.
                Thus enabling few of the feature of umr vuart
*******************************************************************************
 Date          Version        Author          Modification
 17Jun2021      1.00         khertig        Initial(in verilog file)
 05May2022      1.01         chitra         Porting into sv file, usage of
                                            interface and including the package
                                            files and Documentation
******************************************************************************/

// Line Control register bits
`define UMR3_VIRTUAL_UART_LCR_WLS   1:0 // word length select
`define UMR3_VIRTUAL_UART_LCR_STB     2 // stop bits
`define UMR3_VIRTUAL_UART_LCR_PEN     3 // parity enable
`define UMR3_VIRTUAL_UART_LCR_EPS     4 // even parity select
`define UMR3_VIRTUAL_UART_LCR_SP      5 // stick parity
`define UMR3_VIRTUAL_UART_LCR_BC      6 // Break control
`define UMR3_VIRTUAL_UART_LCR_DLAB    7 // Divisor Latch access bit

// Line Status Register bits
`define UMR3_VIRTUAL_UART_LSR_DR      0 // Data ready Indicator
`define UMR3_VIRTUAL_UART_LSR_OE      1 // Overrun Error Indicator
`define UMR3_VIRTUAL_UART_LSR_PE      2 // Parity Error Indicator
`define UMR3_VIRTUAL_UART_LSR_FE      3 // Frame Error Indicator
`define UMR3_VIRTUAL_UART_LSR_BI      4 // Break Error Indicator
`define UMR3_VIRTUAL_UART_LSR_THRE    5 // Transmit holding register is empty
`define UMR3_VIRTUAL_UART_LSR_TEMT    6 // Transmitter Empty indicator
`define UMR3_VIRTUAL_UART_LSR_RXFIFOE 7 // Received FIFO Error
