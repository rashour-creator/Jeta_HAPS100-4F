/* --------------------------------------------------------------------
**
// ------------------------------------------------------------------------------
// 
// Copyright 2012 - 2020 Synopsys, INC.
// 
// This Synopsys IP and all associated documentation are proprietary to
// Synopsys, Inc. and may only be used pursuant to the terms and conditions of a
// written license agreement with Synopsys, Inc. All other use, reproduction,
// modification, or distribution of the Synopsys IP or the associated
// documentation is strictly prohibited.
// 
// Component Name   : DW_axi_a2x
// Component Version: 2.04a
// Release Type     : GA
// ------------------------------------------------------------------------------

// 
// Release version :  2.04a
// File Version     :        $Revision: #1 $ 
// Revision: $Id: //dwh/DW_ocb/DW_axi_a2x/amba_dev/src/DW_axi_a2x_define_constants.vh#1 $ 
**
** --------------------------------------------------------------------
**
** File     : DW_axi_a2x_define_constants.v
** Created  : Thu Jan 27 11:01:40 MET 2011
** Abstract :
**
** --------------------------------------------------------------------
*/

//==============================================================================
// Start Guard: prevent re-compilation of includes
//==============================================================================
`define __GUARD__DW_AXI_A2X_DEFINE_CONSTANTS__VH__

//*****************************************************************************
// Software Interface
//*****************************************************************************

//*****************************************************************************
// A2X Address Channel
//*****************************************************************************

`define A2X_BSW            3    // Burst Size Width
`define A2X_BTW            2    // Burst Type Width
`define A2X_LTW            2    // Locked Type Width
`define A2X_CTW            4    // Cache Type Width
`define A2X_PTW            3    // Protection Type Width
`define A2X_RSW            1    // A2X Resize bit

`define A2X_BRESPW         2    // AXI Buffered Response Width
`define A2X_RRESPW         2    // AXI Buffered Response Width

`define A2X_HIDW            4
`define A2X_HBLW            3    // AHB Burst Width
`define A2X_HPTW            4    // AHB Protection Type Width
`define A2X_HRESPW          2    // AHB Response Width
`define A2X_HBTYPE_W        1    // AHB Burst Type Width

`define A2X_MAX_BSBW        32

//*****************************************************************************
// H2X Defines
//*****************************************************************************
`define CT_MODE             1'b0          
`define SNF_MODE            1'b1

//*****************************************************************************
// AXI Defines
//*****************************************************************************
`define ABURST_FIXED        2'b00
`define ABURST_INCR         2'b01
`define ABURST_WRAP         2'b10

//*****************************************************************************
// AHB Defines
//*****************************************************************************
`define HTRANS_IDLE         2'b00
`define HTRANS_BUSY         2'b01
`define HTRANS_NSEQ         2'b10
`define HTRANS_SEQ          2'b11
`define HBURST_SINGLE       3'b000
`define HBURST_INCR         3'b001
`define HBURST_WRAP4        3'b010
`define HBURST_INCR4        3'b011
`define HBURST_WRAP8        3'b100
`define HBURST_INCR8        3'b101
`define HBURST_WRAP16       3'b110
`define HBURST_INCR16       3'b111
`define HSIZE_8             3'b000
`define HSIZE_16            3'b001
`define HSIZE_32            3'b010
`define HSIZE_64            3'b011
`define HSIZE_128           3'b100
`define HSIZE_256           3'b101
`define HSIZE_512           3'b110
`define HSIZE_1024          3'b111
`define HSIZE_8BIT          3'b000
`define HSIZE_16BIT         3'b001
`define HSIZE_32BIT         3'b010
`define HSIZE_64BIT         3'b011
`define HSIZE_128BIT        3'b100
`define HSIZE_256BIT        3'b101
`define HSIZE_512BIT        3'b110
`define HSIZE_1024BIT       3'b111
`define HSIZE_BYTE          3'b000
`define HSIZE_WORD16        3'b001
`define HSIZE_WORD32        3'b010
`define HSIZE_WORD64        3'b011
`define HSIZE_WORD128       3'b100
`define HSIZE_WORD256       3'b101
`define HSIZE_WORD512       3'b110
`define HSIZE_WORD1024      3'b111
`define HPROT_DATA          0
`define HPROT_PRIV          1
`define HPROT_BUFF          2
`define HPROT_CACHE         3


`define HRESP_OKAY          2'b00
`define HRESP_ERROR         2'b01
`define HRESP_RETRY         2'b10
`define HRESP_SPLIT         2'b11

//*****************************************************************************
//  AXI Defines
//*****************************************************************************
`define AFIXED 2'b00
`define AINCR  2'b01
`define AWRAP  2'b10

`define AOKAY   2'b00
`define AEXOKAY 2'b10
`define ASLVERR 2'b10
`define ADECERR 2'b11

//==============================================================================
// End Guard
//==============================================================================  
