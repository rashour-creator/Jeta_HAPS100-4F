/******************************************************************************
   Copyright (C) 2020-2021 Synopsys, Inc.
   This IP and the associated documentation are confidential and
   proprietary to Synopsys, Inc. Your use or disclosure of this IP is 
   subject to the terms and conditions of a written license agreement 
   between you, or your company, and Synopsys, Inc.
*******************************************************************************
   Title      : UMR3 VIRTUAL UART undef
   Project    : Anaconda
   Description: This module undefines the macros/switches by VUART.
                Thus disenabling few of the feature of umr vuart
 *******************************************************************************
 Date          Version        Author          Modification
    $           1.00            $           Initial(in verilog file)
 17Jun2021      1.01         khertig        Updates
 05May2022      1.02         chitra         Porting into sv file, usage of
                                            interface and including the package
                                            files and Documentation
 ******************************************************************************/
// Line Control register bits
`undef UMR3_VIRTUAL_UART_LCR_WLS
`undef UMR3_VIRTUAL_UART_LCR_STB
`undef UMR3_VIRTUAL_UART_LCR_PEN
`undef UMR3_VIRTUAL_UART_LCR_EPS
`undef UMR3_VIRTUAL_UART_LCR_SP
`undef UMR3_VIRTUAL_UART_LCR_BC
`undef UMR3_VIRTUAL_UART_LCR_DLAB

// Line Status Register bits
`undef UMR3_VIRTUAL_UART_LSR_DR
`undef UMR3_VIRTUAL_UART_LSR_OE
`undef UMR3_VIRTUAL_UART_LSR_PE
`undef UMR3_VIRTUAL_UART_LSR_FE
`undef UMR3_VIRTUAL_UART_LSR_BI
`undef UMR3_VIRTUAL_UART_LSR_THRE
`undef UMR3_VIRTUAL_UART_LSR_TEMT
`undef UMR3_VIRTUAL_UART_LSR_RXFIFOE
