/* ---------------------------------------------------------------------
**
// ------------------------------------------------------------------------------
// 
// Copyright 2001 - 2023 Synopsys, INC.
// 
// This Synopsys IP and all associated documentation are proprietary to
// Synopsys, Inc. and may only be used pursuant to the terms and conditions of a
// written license agreement with Synopsys, Inc. All other use, reproduction,
// modification, or distribution of the Synopsys IP or the associated
// documentation is strictly prohibited.
// Inclusivity & Diversity - Visit SolvNetPlus to read the "Synopsys Statement on
//            Inclusivity and Diversity" (Refer to article 000036315 at
//                        https://solvnetplus.synopsys.com)
// 
// Component Name   : DW_axi
// Component Version: 4.06a
// Release Type     : GA
// Build ID         : 18.26.9.4
// ------------------------------------------------------------------------------

// 
// Release version :  4.06a
// File Version     :        $Revision: #5 $ 
// Revision: $Id: //dwh/DW_ocb/DW_axi/axi_dev_br/src/DW_axi_constants.vh#5 $ 
**
** ---------------------------------------------------------------------
**h
** File     : DW_axi_constants.v
//
//
** Created  : Tue May 24 17:09:09 MEST 2005
** Modified : $Date: 2022/08/11 $
** Abstract : Some static macro's for DW_axi.
**
** ---------------------------------------------------------------------
*/

//==============================================================================
// Start Guard: prevent re-compilation of includes
//==============================================================================
`ifndef i_axi___GUARD__DW_AXI_CONSTANTS__VH__
`define i_axi___GUARD__DW_AXI_CONSTANTS__VH__

// Burst Size Width
`define i_axi_AXI_BSW 3
// Burst Type Width
`define i_axi_AXI_BTW 2
// Locked Type Width
`define i_axi_AXI_LTW ((`i_axi_AXI_INTERFACE_TYPE >0)? 1 :2)
//`define i_axi_AXI_LTW 2 
// Cache Type Width
`define i_axi_AXI_CTW 4
// Protection Type Width
`define i_axi_AXI_PTW 3
// Buffered Response Width
`define i_axi_AXI_BRW 2
// Read Response Width
`define i_axi_AXI_RRW 2
// The width of the write strobe bus
`define i_axi_AXI_SW        (`i_axi_AXI_DW/8)

// Maximum number of masters or slaves.
// Including default slave.
`define i_axi_AXI_MAX_NUM_MST_SLVS 17

// Maximum number of user masters.
`define i_axi_AXI_MAX_NUM_USR_MSTS 16

// Maximum number of user slaves.
`define i_axi_AXI_MAX_NUM_USR_SLVS 16

// Locked type field macros.
`define i_axi_AXI_LT_NORM  2'b00
`define i_axi_AXI_LT_EX    2'b01
`define i_axi_AXI_LT_LOCK  2'b10

// Protection type field macros.
`define i_axi_AXI_PT_PRVLGD    3'bxx1
`define i_axi_AXI_PT_NORM      3'bxx0
`define i_axi_AXI_PT_SECURE    3'bx1x
`define i_axi_AXI_PT_NSECURE   3'bx0x
`define i_axi_AXI_PT_INSTRUCT  3'b1xx
`define i_axi_AXI_PT_DATA      3'b0xx

`define i_axi_AXI_PT_PRVLGD_BIT   0
`define i_axi_AXI_PT_INSTRUCT_BIT 2

// Encoding definition of RESP signals.
`define i_axi_AXI_RESP_OKAY     2'b00
`define i_axi_AXI_RESP_EXOKAY   2'b01
`define i_axi_AXI_RESP_SLVERR   2'b10
`define i_axi_AXI_RESP_DECERR   2'b11

// Encoding definition of timing option parameters.
`define i_axi_AXI_TMO_COMB  2'b00
`define i_axi_AXI_TMO_FRWD  2'b01
`define i_axi_AXI_TMO_FULL  2'b10

// Macros used as parameter inputs to blocks,
`define i_axi_AXI_NOREQ_LOCKING  0 // No locking functionality required.
`define i_axi_AXI_REQ_LOCKING    1 // Locking functionality required.

// Macros to define the encoding of the the AXI arbitration type
// paramters e.g. AXI_AR_ARBITER_S0.
`define i_axi_AXI_ARB_TYPE_DP   0
`define i_axi_AXI_ARB_TYPE_FCFS 1
`define i_axi_AXI_ARB_TYPE_2T   2
`define i_axi_AXI_ARB_TYPE_USER 3
`define i_axi_AXI_ARB_TYPE_QOS  4

// Some blocks need to implement different logic depending
// on what type of channel they are implementing, these macros
// are used for that purpose.
`define i_axi_AXI_W_CH 1      // This channel is a write data channel.
`define i_axi_AXI_NOT_W_CH  0 // This channel is not a write data channel.

`define i_axi_AXI_AW_CH 1      // This channel is a write address channel.
`define i_axi_AXI_NOT_AW_CH  0 // This channel is not a write address channel.

`define i_axi_AXI_R_CH 1      // This channel is a read data channel.
`define i_axi_AXI_NOT_R_CH  0 // This channel is not a read data channel.

`define i_axi_AXI_ADDR_CH 1     // This channel is an address channel.
`define i_axi_AXI_NOT_ADDR_CH 0 // This channel is not an address channel.

// Macros to pass to the USE_INT_GRANT_INDEX parameter of the
// DW_axi_arb block.
`define i_axi_USE_INT_GI  1 // Use internal grant index.
`define i_axi_USE_EXT_GI  0 // Use external grant index.

// Macros, encoding of shared parameters.
`define i_axi_AXI_SHARED 1
`define i_axi_AXI_NOT_SHARED 0

// Width of buses containing hold valid status bits for all 
// sources at all other destinations, from master annd slave 
// perspective.
`define i_axi_AXI_HOLD_VLD_OTHER_S_W (`i_axi_AXI_NUM_MASTERS*(`i_axi_AXI_NSP1-1))
`define i_axi_AXI_HOLD_VLD_OTHER_M_W ((`i_axi_AXI_NUM_MASTERS > 1) ? (`i_axi_AXI_NSP1*(`i_axi_AXI_NUM_MASTERS-1)) : 1)


// Macros for bit field position of components of
// read address channel payload vector.
`define i_axi_AXI_ARPYLD_PROT_RHS 0
`define i_axi_AXI_ARPYLD_PROT_LHS ((`i_axi_AXI_PTW-1) + `i_axi_AXI_ARPYLD_PROT_RHS)
`define i_axi_AXI_ARPYLD_PROT    1 
 
`define i_axi_AXI_ARPYLD_CACHE_RHS (`i_axi_AXI_ARPYLD_PROT_LHS + 1)
`define i_axi_AXI_ARPYLD_CACHE_LHS ((`i_axi_AXI_CTW-1) + `i_axi_AXI_ARPYLD_CACHE_RHS)
`define i_axi_AXI_ARPYLD_CACHE     `i_axi_AXI_ARPYLD_CACHE_LHS:`i_axi_AXI_ARPYLD_CACHE_RHS
 
`define i_axi_AXI_ARPYLD_LOCK_RHS (`i_axi_AXI_ARPYLD_CACHE_LHS + 1)
`define i_axi_AXI_ARPYLD_LOCK_LHS ((`i_axi_AXI_LTW-1) + `i_axi_AXI_ARPYLD_LOCK_RHS)
`define i_axi_AXI_ARPYLD_LOCK     `i_axi_AXI_ARPYLD_LOCK_LHS:`i_axi_AXI_ARPYLD_LOCK_RHS
 
`define i_axi_AXI_ARPYLD_BURST_RHS (`i_axi_AXI_ARPYLD_LOCK_LHS + 1)
`define i_axi_AXI_ARPYLD_BURST_LHS ((`i_axi_AXI_BTW-1) + `i_axi_AXI_ARPYLD_BURST_RHS)
`define i_axi_AXI_ARPYLD_BURST     `i_axi_AXI_ARPYLD_BURST_LHS:`i_axi_AXI_ARPYLD_BURST_RHS
 
`define i_axi_AXI_ARPYLD_SIZE_RHS (`i_axi_AXI_ARPYLD_BURST_LHS + 1)
`define i_axi_AXI_ARPYLD_SIZE_LHS ((`i_axi_AXI_BSW-1) + `i_axi_AXI_ARPYLD_SIZE_RHS)
`define i_axi_AXI_ARPYLD_SIZE     `i_axi_AXI_ARPYLD_SIZE_LHS:`i_axi_AXI_ARPYLD_SIZE_RHS
 
`define i_axi_AXI_ARPYLD_LEN_RHS (`i_axi_AXI_ARPYLD_SIZE_LHS + 1)
`define i_axi_AXI_ARPYLD_LEN_LHS ((`i_axi_AXI_BLW-1) + `i_axi_AXI_ARPYLD_LEN_RHS)
`define i_axi_AXI_ARPYLD_LEN     `i_axi_AXI_ARPYLD_LEN_LHS:`i_axi_AXI_ARPYLD_LEN_RHS
 
`define i_axi_AXI_ARPYLD_ADDR_RHS (`i_axi_AXI_ARPYLD_LEN_LHS + 1)
`define i_axi_AXI_ARPYLD_ADDR_LHS ((`i_axi_AXI_AW-1) + `i_axi_AXI_ARPYLD_ADDR_RHS)
`define i_axi_AXI_ARPYLD_ADDR     `i_axi_AXI_ARPYLD_ADDR_LHS:`i_axi_AXI_ARPYLD_ADDR_RHS
 
// Note : Different ID widths in master and slave ports.
`define i_axi_AXI_ARPYLD_ID_RHS_M (`i_axi_AXI_ARPYLD_ADDR_LHS + 1)
`define i_axi_AXI_ARPYLD_ID_LHS_M ((`i_axi_AXI_MIDW-1) + `i_axi_AXI_ARPYLD_ID_RHS_M)
`define i_axi_AXI_ARPYLD_ID_M     `i_axi_AXI_ARPYLD_ID_LHS_M:`i_axi_AXI_ARPYLD_ID_RHS_M
 
`define i_axi_AXI_ARPYLD_ID_RHS_S (`i_axi_AXI_ARPYLD_ADDR_LHS + 1)
`define i_axi_AXI_ARPYLD_ID_LHS_S ((`i_axi_AXI_SIDW-1) + `i_axi_AXI_ARPYLD_ID_RHS_S)
`define i_axi_AXI_ARPYLD_ID_S     `i_axi_AXI_ARPYLD_ID_LHS_S:`i_axi_AXI_ARPYLD_ID_RHS_S
 
 
// Macros for bit field position of components of
// read data channel payload vector.
`define i_axi_AXI_RPYLD_LAST_LHS 0
`define i_axi_AXI_RPYLD_LAST     `i_axi_AXI_RPYLD_LAST_LHS
 
`define i_axi_AXI_RPYLD_RESP_RHS (`i_axi_AXI_RPYLD_LAST_LHS + 1)
`define i_axi_AXI_RPYLD_RESP_LHS ((`i_axi_AXI_RRW-1) + `i_axi_AXI_RPYLD_RESP_RHS)
`define i_axi_AXI_RPYLD_RESP     `i_axi_AXI_RPYLD_RESP_LHS:`i_axi_AXI_RPYLD_RESP_RHS
 
`define i_axi_AXI_RPYLD_DATA_RHS (`i_axi_AXI_RPYLD_RESP_LHS + 1)
`define i_axi_AXI_RPYLD_DATA_LHS ((`i_axi_AXI_DW-1) + `i_axi_AXI_RPYLD_DATA_RHS)
`define i_axi_AXI_RPYLD_DATA     `i_axi_AXI_RPYLD_DATA_LHS:`i_axi_AXI_RPYLD_DATA_RHS
 
// Note : Different ID widths in master and slave ports.
`define i_axi_AXI_RPYLD_ID_RHS_M (`i_axi_AXI_RPYLD_DATA_LHS + 1)
`define i_axi_AXI_RPYLD_ID_LHS_M ((`i_axi_AXI_MIDW-1) + `i_axi_AXI_RPYLD_ID_RHS_M)
`define i_axi_AXI_RPYLD_ID_M     `i_axi_AXI_RPYLD_ID_LHS_M:`i_axi_AXI_RPYLD_ID_RHS_M
 
`define i_axi_AXI_RPYLD_ID_RHS_S (`i_axi_AXI_RPYLD_DATA_LHS + 1)
`define i_axi_AXI_RPYLD_ID_LHS_S ((`i_axi_AXI_SIDW-1) + `i_axi_AXI_RPYLD_ID_RHS_S)
`define i_axi_AXI_RPYLD_ID_S     `i_axi_AXI_RPYLD_ID_LHS_S:`i_axi_AXI_RPYLD_ID_RHS_S
 
 
// Macros for bit field position of components of
// write address channel payload vector.
`define i_axi_AXI_AWPYLD_PROT_RHS 0
`define i_axi_AXI_AWPYLD_PROT_LHS ((`i_axi_AXI_PTW-1) + `i_axi_AXI_AWPYLD_PROT_RHS)
`define i_axi_AXI_AWPYLD_PROT     `i_axi_AXI_AWPYLD_PROT_LHS:`i_axi_AXI_AWPYLD_PROT_RHS
 
`define i_axi_AXI_AWPYLD_CACHE_RHS (`i_axi_AXI_AWPYLD_PROT_LHS + 1)
`define i_axi_AXI_AWPYLD_CACHE_LHS ((`i_axi_AXI_CTW-1) + `i_axi_AXI_AWPYLD_CACHE_RHS)
`define i_axi_AXI_AWPYLD_CACHE     `i_axi_AXI_AWPYLD_CACHE_LHS:`i_axi_AXI_AWPYLD_CACHE_RHS
 
`define i_axi_AXI_AWPYLD_LOCK_RHS (`i_axi_AXI_AWPYLD_CACHE_LHS + 1)
`define i_axi_AXI_AWPYLD_LOCK_LHS ((`i_axi_AXI_LTW-1) + `i_axi_AXI_AWPYLD_LOCK_RHS)
`define i_axi_AXI_AWPYLD_LOCK     `i_axi_AXI_AWPYLD_LOCK_LHS:`i_axi_AXI_AWPYLD_LOCK_RHS
 
`define i_axi_AXI_AWPYLD_BURST_RHS (`i_axi_AXI_AWPYLD_LOCK_LHS + 1)
`define i_axi_AXI_AWPYLD_BURST_LHS ((`i_axi_AXI_BTW-1) + `i_axi_AXI_AWPYLD_BURST_RHS)
`define i_axi_AXI_AWPYLD_BURST     `i_axi_AXI_AWPYLD_BURST_LHS:`i_axi_AXI_AWPYLD_BURST_RHS
 
`define i_axi_AXI_AWPYLD_SIZE_RHS (`i_axi_AXI_AWPYLD_BURST_LHS + 1)
`define i_axi_AXI_AWPYLD_SIZE_LHS ((`i_axi_AXI_BSW-1) + `i_axi_AXI_AWPYLD_SIZE_RHS)
`define i_axi_AXI_AWPYLD_SIZE     `i_axi_AXI_AWPYLD_SIZE_LHS:`i_axi_AXI_AWPYLD_SIZE_RHS
 
`define i_axi_AXI_AWPYLD_LEN_RHS (`i_axi_AXI_AWPYLD_SIZE_LHS + 1)
`define i_axi_AXI_AWPYLD_LEN_LHS ((`i_axi_AXI_BLW-1) + `i_axi_AXI_AWPYLD_LEN_RHS)
`define i_axi_AXI_AWPYLD_LEN     `i_axi_AXI_AWPYLD_LEN_LHS:`i_axi_AXI_AWPYLD_LEN_RHS
 
`define i_axi_AXI_AWPYLD_ADDR_RHS (`i_axi_AXI_AWPYLD_LEN_LHS + 1)
`define i_axi_AXI_AWPYLD_ADDR_LHS ((`i_axi_AXI_AW-1) + `i_axi_AXI_AWPYLD_ADDR_RHS)
`define i_axi_AXI_AWPYLD_ADDR     `i_axi_AXI_AWPYLD_ADDR_LHS:`i_axi_AXI_AWPYLD_ADDR_RHS
 
// Note : Different ID widths in master and slave ports.
`define i_axi_AXI_AWPYLD_ID_RHS_M (`i_axi_AXI_AWPYLD_ADDR_LHS + 1)
`define i_axi_AXI_AWPYLD_ID_LHS_M ((`i_axi_AXI_MIDW-1) + `i_axi_AXI_AWPYLD_ID_RHS_M)
`define i_axi_AXI_AWPYLD_ID_M     `i_axi_AXI_AWPYLD_ID_LHS_M:`i_axi_AXI_AWPYLD_ID_RHS_M
 
`define i_axi_AXI_AWPYLD_ID_RHS_S (`i_axi_AXI_AWPYLD_ADDR_LHS + 1)
`define i_axi_AXI_AWPYLD_ID_LHS_S ((`i_axi_AXI_SIDW-1) + `i_axi_AXI_AWPYLD_ID_RHS_S)
`define i_axi_AXI_AWPYLD_ID_S     `i_axi_AXI_AWPYLD_ID_LHS_S:`i_axi_AXI_AWPYLD_ID_RHS_S
 
 
// Macros for bit field position of components of
// write data channel payload vector.
`define i_axi_AXI_WPYLD_LAST_LHS 0
`define i_axi_AXI_WPYLD_LAST     `i_axi_AXI_WPYLD_LAST_LHS
 
`define i_axi_AXI_WPYLD_STRB_RHS (`i_axi_AXI_WPYLD_LAST_LHS + 1)
`define i_axi_AXI_WPYLD_STRB_LHS ((`i_axi_AXI_SW-1) + `i_axi_AXI_WPYLD_STRB_RHS)
`define i_axi_AXI_WPYLD_STRB     `i_axi_AXI_WPYLD_STRB_LHS:`i_axi_AXI_WPYLD_STRB_RHS
 
`define i_axi_AXI_WPYLD_DATA_RHS (`i_axi_AXI_WPYLD_STRB_LHS + 1)
`define i_axi_AXI_WPYLD_DATA_LHS ((`i_axi_AXI_DW-1) + `i_axi_AXI_WPYLD_DATA_RHS)
`define i_axi_AXI_WPYLD_DATA     `i_axi_AXI_WPYLD_DATA_LHS:`i_axi_AXI_WPYLD_DATA_RHS
 
// Note : Different ID widths in master and slave ports.
`define i_axi_AXI_WPYLD_ID_RHS_M (`i_axi_AXI_WPYLD_DATA_LHS + 1)
`define i_axi_AXI_WPYLD_ID_LHS_M ((`i_axi_AXI_MIDW-1) + `i_axi_AXI_WPYLD_ID_RHS_M)
`define i_axi_AXI_WPYLD_ID_M     `i_axi_AXI_WPYLD_ID_LHS_M:`i_axi_AXI_WPYLD_ID_RHS_M
 
`define i_axi_AXI_WPYLD_ID_RHS_S (`i_axi_AXI_WPYLD_DATA_LHS + 1)
`define i_axi_AXI_WPYLD_ID_LHS_S ((`i_axi_AXI_SIDW-1) + `i_axi_AXI_WPYLD_ID_RHS_S)
`define i_axi_AXI_WPYLD_ID_S     `i_axi_AXI_WPYLD_ID_LHS_S:`i_axi_AXI_WPYLD_ID_RHS_S
 
 
// Macros for bit field position of components of
// burst response channel payload vector.
`define i_axi_AXI_BPYLD_RESP_RHS 0
`define i_axi_AXI_BPYLD_RESP_LHS ((`i_axi_AXI_BRW-1) + `i_axi_AXI_BPYLD_RESP_RHS)
`define i_axi_AXI_BPYLD_RESP     `i_axi_AXI_BPYLD_RESP_LHS:`i_axi_AXI_BPYLD_RESP_RHS
 
// Note : Different ID widths in master and slave ports.
`define i_axi_AXI_BPYLD_ID_RHS_M (`i_axi_AXI_BPYLD_RESP_LHS + 1)
`define i_axi_AXI_BPYLD_ID_LHS_M ((`i_axi_AXI_MIDW-1) + `i_axi_AXI_BPYLD_ID_RHS_M)
`define i_axi_AXI_BPYLD_ID_M     `i_axi_AXI_BPYLD_ID_LHS_M:`i_axi_AXI_BPYLD_ID_RHS_M
 
`define i_axi_AXI_BPYLD_ID_RHS_S (`i_axi_AXI_BPYLD_RESP_LHS + 1)
`define i_axi_AXI_BPYLD_ID_LHS_S ((`i_axi_AXI_SIDW-1) + `i_axi_AXI_BPYLD_ID_RHS_S)
`define i_axi_AXI_BPYLD_ID_S     `i_axi_AXI_BPYLD_ID_LHS_S:`i_axi_AXI_BPYLD_ID_RHS_S
 
// QOS Signal width
`define i_axi_AXI_QOSW  4
 // APB constant
`define i_axi_IC_ADDR_SLICE_LHS  5
`define i_axi_MAX_APB_DATA_WIDTH 32
`define i_axi_REG_XCT_RATE_W      12
`define i_axi_REG_BURSTINESS_W    8
`define i_axi_REG_PEAK_RATE_W     12
`define i_axi_APB_ADDR_WIDTH      32

//AXI 4 specific constant
`define i_axi_AXI_ALSW 4 
`define i_axi_AXI_ALDW 2
`define i_axi_AXI_ALBW 2
`define i_axi_AXI_REGIONW 4


`define i_axi_PL_BUF_AW 0


`define i_axi_PL_BUF_AR 0


// Active IDs buffer pointer width

`define i_axi_ACT_ID_BUF_POINTER_W_AW_M1 70


`define i_axi_LOG2_ACT_ID_BUF_POINTER_W_AW_M1 4


`define i_axi_ACT_ID_BUF_POINTER_W_AR_M1 40


`define i_axi_LOG2_ACT_ID_BUF_POINTER_W_AR_M1 3


`define i_axi_ACT_ID_BUF_POINTER_W_AW_M2 70


`define i_axi_LOG2_ACT_ID_BUF_POINTER_W_AW_M2 4


`define i_axi_ACT_ID_BUF_POINTER_W_AR_M2 40


`define i_axi_LOG2_ACT_ID_BUF_POINTER_W_AR_M2 3


`define i_axi_ACT_ID_BUF_POINTER_W_AW_M3 10


`define i_axi_LOG2_ACT_ID_BUF_POINTER_W_AW_M3 1


`define i_axi_ACT_ID_BUF_POINTER_W_AR_M3 40


`define i_axi_LOG2_ACT_ID_BUF_POINTER_W_AR_M3 3


`define i_axi_ACT_ID_BUF_POINTER_W_AW_M4 10


`define i_axi_LOG2_ACT_ID_BUF_POINTER_W_AW_M4 1


`define i_axi_ACT_ID_BUF_POINTER_W_AR_M4 40


`define i_axi_LOG2_ACT_ID_BUF_POINTER_W_AR_M4 3


`define i_axi_ACT_ID_BUF_POINTER_W_AW_M5 10


`define i_axi_LOG2_ACT_ID_BUF_POINTER_W_AW_M5 1


`define i_axi_ACT_ID_BUF_POINTER_W_AR_M5 40


`define i_axi_LOG2_ACT_ID_BUF_POINTER_W_AR_M5 3


`define i_axi_ACT_ID_BUF_POINTER_W_AW_M6 10


`define i_axi_LOG2_ACT_ID_BUF_POINTER_W_AW_M6 1


`define i_axi_ACT_ID_BUF_POINTER_W_AR_M6 40


`define i_axi_LOG2_ACT_ID_BUF_POINTER_W_AR_M6 3


`define i_axi_ACT_ID_BUF_POINTER_W_AW_M7 10


`define i_axi_LOG2_ACT_ID_BUF_POINTER_W_AW_M7 1


`define i_axi_ACT_ID_BUF_POINTER_W_AR_M7 40


`define i_axi_LOG2_ACT_ID_BUF_POINTER_W_AR_M7 3


`define i_axi_ACT_ID_BUF_POINTER_W_AW_M8 10


`define i_axi_LOG2_ACT_ID_BUF_POINTER_W_AW_M8 1


`define i_axi_ACT_ID_BUF_POINTER_W_AR_M8 40


`define i_axi_LOG2_ACT_ID_BUF_POINTER_W_AR_M8 3


`define i_axi_ACT_ID_BUF_POINTER_W_AW_M9 10


`define i_axi_LOG2_ACT_ID_BUF_POINTER_W_AW_M9 1


`define i_axi_ACT_ID_BUF_POINTER_W_AR_M9 40


`define i_axi_LOG2_ACT_ID_BUF_POINTER_W_AR_M9 3


`define i_axi_ACT_ID_BUF_POINTER_W_AW_M10 10


`define i_axi_LOG2_ACT_ID_BUF_POINTER_W_AW_M10 1


`define i_axi_ACT_ID_BUF_POINTER_W_AR_M10 40


`define i_axi_LOG2_ACT_ID_BUF_POINTER_W_AR_M10 3


`define i_axi_ACT_ID_BUF_POINTER_W_AW_M11 10


`define i_axi_LOG2_ACT_ID_BUF_POINTER_W_AW_M11 1


`define i_axi_ACT_ID_BUF_POINTER_W_AR_M11 40


`define i_axi_LOG2_ACT_ID_BUF_POINTER_W_AR_M11 3


`define i_axi_ACT_ID_BUF_POINTER_W_AW_M12 10


`define i_axi_LOG2_ACT_ID_BUF_POINTER_W_AW_M12 1


`define i_axi_ACT_ID_BUF_POINTER_W_AR_M12 40


`define i_axi_LOG2_ACT_ID_BUF_POINTER_W_AR_M12 3


`define i_axi_ACT_ID_BUF_POINTER_W_AW_M13 10


`define i_axi_LOG2_ACT_ID_BUF_POINTER_W_AW_M13 1


`define i_axi_ACT_ID_BUF_POINTER_W_AR_M13 40


`define i_axi_LOG2_ACT_ID_BUF_POINTER_W_AR_M13 3


`define i_axi_ACT_ID_BUF_POINTER_W_AW_M14 10


`define i_axi_LOG2_ACT_ID_BUF_POINTER_W_AW_M14 1


`define i_axi_ACT_ID_BUF_POINTER_W_AR_M14 40


`define i_axi_LOG2_ACT_ID_BUF_POINTER_W_AR_M14 3


`define i_axi_ACT_ID_BUF_POINTER_W_AW_M15 10


`define i_axi_LOG2_ACT_ID_BUF_POINTER_W_AW_M15 1


`define i_axi_ACT_ID_BUF_POINTER_W_AR_M15 40


`define i_axi_LOG2_ACT_ID_BUF_POINTER_W_AR_M15 3


`define i_axi_ACT_ID_BUF_POINTER_W_AW_M16 10


`define i_axi_LOG2_ACT_ID_BUF_POINTER_W_AW_M16 1


`define i_axi_ACT_ID_BUF_POINTER_W_AR_M16 40


`define i_axi_LOG2_ACT_ID_BUF_POINTER_W_AR_M16 3





`define i_axi_AXI_HAS_WID (`i_axi_AXI_INTERFACE_TYPE==0)
//==============================================================================
// End Guard
//==============================================================================  
`endif

