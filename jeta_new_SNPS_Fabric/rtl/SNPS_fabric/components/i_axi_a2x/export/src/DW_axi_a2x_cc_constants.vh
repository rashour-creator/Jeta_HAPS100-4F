/* --------------------------------------------------------------------
**
// ------------------------------------------------------------------------------
// 
// Copyright 2012 - 2023 Synopsys, INC.
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
// Component Name   : DW_axi_a2x
// Component Version: 2.06a
// Release Type     : GA
// Build ID         : 15.22.13.5
// ------------------------------------------------------------------------------

// 
// Release version :  2.06a
// File Version     :        $Revision: #28 $ 
// Revision: $Id: //dwh/DW_ocb/DW_axi_a2x/axi_dev_br/src/DW_axi_a2x_cc_constants.vh#28 $ 
**
** --------------------------------------------------------------------
**
** File     : DW_axi_a2x_cc_constants.v
** Created  : Thu Jan 27 11:01:41 MET 2011
** Abstract :
**
** --------------------------------------------------------------------
*/

//==============================================================================
// Start Guard: prevent re-compilation of includes
//==============================================================================
`ifndef i_axi_a2x___GUARD__DW_AXI_A2X_CC_CONSTANTS__VH__
`define i_axi_a2x___GUARD__DW_AXI_A2X_CC_CONSTANTS__VH__


// Name:         USE_FOUNDATION
// Default:      true ([<functionof>])
// Values:       false (0), true (1)
// Enabled:      [<functionof> %item]
// 
// Use DesignWare Foundation parts for optimal Synthesis QoR. This parameter can be set to true (1), only if you have 
// DWC-AMBA-Fabric-Source and DesignWare Foundation license.
`define i_axi_a2x_USE_FOUNDATION 1

`define i_axi_a2x_A2X_USE_FOUNDATION


// Name:         A2X_LOWPWR_IF
// Default:      Disable
// Values:       Disable (0), Enable (1)
// 
// When enabled, the DW_axi_a2x supports Low-Power mode.
`define i_axi_a2x_A2X_LOWPWR_IF 0


// Name:         A2X_LOWPWR_NOPX_CNT
// Default:      2
// Values:       0, ..., 15
// Enabled:      (A2X_LOWPWR_IF==1)? 1 : 0
// 
// Defines the number of clock cycles the DW_axi_a2x must be inactive before de-asserting CACTIVE.
`define i_axi_a2x_A2X_LOWPWR_NOPX_CNT 2


// Name:         A2X_PP_MODE
// Default:      AXI
// Values:       AHB (0), AXI (1)
// 
// Denotes the mode in which the DW_axi_a2x operates (either connecting to another AXI bus fabric or to an AHB bus fabric). 
// 
//   - AHB interface - Connects to AHB bus fabric  
//   - AXI interface - Connects to AXI bus fabric
`define i_axi_a2x_A2X_PP_MODE 1


// Name:         A2X_AHB_INTERFACE_TYPE
// Default:      AHB
// Values:       AHB (0), AHB5 (1)
// Enabled:      A2X_AHB_LITE_MODE==1 && <DWC-AMBA-AHB5-Fabric-Source feature 
//               authorize>==1 && <DWC-AMBA-Fabric-Source feature authorize>==1
// 
// Select AHB Interface Type as AHB or AHB5.
`define i_axi_a2x_A2X_AHB_INTERFACE_TYPE 0


// Name:         A2X_HAS_EXTD_MEMTYPE
// Default:      false
// Values:       false (0), true (1)
// Enabled:      A2X_AHB_INTERFACE_TYPE==1
// 
// Select this parameter to include Extended Memory Types property in the DW_axi_a2x. 
//  When set to 1, the width of hprot on the primary port is increased from 4 to 7 and 
//  extended memory types information is passed through the DW_axi_a2x.
`define i_axi_a2x_A2X_HAS_EXTD_MEMTYPE 0


// Name:         A2X_HAS_SECURE_XFER
// Default:      false
// Values:       false (0), true (1)
// Enabled:      A2X_AHB_INTERFACE_TYPE==1
// 
// Select this parameter to include AHB5 Secure Transfers property in the DW_axi_a2x.
`define i_axi_a2x_A2X_HAS_SECURE_XFER 0


// Name:         A2X_HAS_EXCL_XFER
// Default:      false
// Values:       false (0), true (1)
// Enabled:      A2X_AHB_INTERFACE_TYPE==1
// 
// Select this parameter to include AHB5 exclusive transfers property in the DW_axi_a2xx.
`define i_axi_a2x_A2X_HAS_EXCL_XFER 0

//AHB5 defines







`define i_axi_a2x_A2X_HPTW 4


// Name:         A2X_AXI_INTERFACE_TYPE
// Default:      AXI3
// Values:       AXI3 (0), AXI4 (1), ACELITE (2)
// 
// Select AXI Interface Type as AXI3, AXI4, or ACE-Lite. By default, DW_axi_a2x supports the AXI3 interface.   
//  - When A2X_PP_MODE = 0: AXI3 (0) and AXI4 (1) are supported. 
//  - When A2X_PP_MODE = 1: AXI3 (0), AXI4 (1) and ACELITE (2) are supported.
`define i_axi_a2x_A2X_AXI_INTERFACE_TYPE 1


`define i_axi_a2x_A2X_INT_AXI3 0


`define i_axi_a2x_A2X_INT_LTW 1


// `define i_axi_a2x_A2X_HAS_AXI3


`define i_axi_a2x_A2X_HAS_AXI4


// `define i_axi_a2x_A2X_HAS_ACELITE



// Name:         A2X_AHB_LITE_MODE
// Default:      Disable
// Values:       Disable (0), Enable (1)
// Enabled:      A2X_PP_MODE==0
// 
// Configures the DW_axi_a2x for AHB-Lite mode. In this mode: 
//  - AHB Split responses are not supported. 
//  - DW_axi_a2x supports only one AHB Manager in AHB-Lite mode.  
//  - DW_axi_a2x responds to AHB reads and non-bufferable writes by driving hready low.
`define i_axi_a2x_A2X_AHB_LITE_MODE 0


// Name:         A2X_AHB_SCALAR_HRESP
// Default:      0
// Values:       0, 1
// Enabled:      A2X_AHB_LITE_MODE==1
// 
// When set to true, hresp is a single-bit signal, else it is of 2 bits.
`define i_axi_a2x_A2X_AHB_SCALAR_HRESP 0



// Name:         A2X_AHB_SPLIT_MODE
// Default:      Enable ((A2X_AHB_LITE_MODE==0)? 1 : 0)
// Values:       Disable (0), Enable (1)
// Enabled:      ((A2X_PP_MODE==0) && (A2X_AHB_LITE_MODE==0))
// 
// Configures the DW_axi_a2x for Split mode. 
//  - 0: DW_axi_a2x responds to AHB reads and non-bufferable writes by driving hready low. 
//  - 1: DW_axi_a2x responds to AHB reads and non-bufferable writes with Split response.
`define i_axi_a2x_A2X_AHB_SPLIT_MODE 1
`define i_axi_a2x_AHB_SPLIT_MODE


// Name:         A2X_NUM_AHBM
// Default:      8 ((A2X_AHB_LITE_MODE==1)? 1 : 8)
// Values:       1, ..., 15
// Enabled:      ((A2X_PP_MODE==0) && (A2X_AHB_LITE_MODE==0))
// 
// Defines the number of active AHB Managers that the DW_axi_a2x can support. The number of AHB managers specified by this 
// parameter does not include the temporary manager; the DW_axi_a2x assumes that the temporary manager is HMASTER zero.
`define i_axi_a2x_A2X_NUM_AHBM 8


// Name:         A2X_HREADY_LOW_PERIOD
// Default:      100
// Values:       10, ..., 200
// Enabled:      ((A2X_PP_MODE==0) && (A2X_AHB_SPLIT_MODE==1))
// 
// Defines the number of clock cycles for which the DW_axi_a2x drives hready low before issuing a split response to a write 
// transaction. The DW_axi_a2x drives hready low when it cannot accept a write transaction due to a Buffer Full condition.
`define i_axi_a2x_A2X_HREADY_LOW_PERIOD 100


// Name:         A2X_LOCKED
// Default:      Disabled
// Values:       Disabled (0), Enabled (1)
// Enabled:      A2X_AXI_INTERFACE_TYPE==0
// 
// Supports the following types of locked transactions: 
//  - AHB to AXI 
//  - AXI to AXI
`define i_axi_a2x_A2X_LOCKED 0


// Name:         A2X_CLK_MODE
// Default:      Synchronous
// Values:       Synchronous (0), Quassi-Synchronous (1), Asynchronous (2)
// 
// Selects the relationship between the Primary Port clock (AXI or AHB) and the Secondary Port clock (AXI).
`define i_axi_a2x_A2X_CLK_MODE 0


// Name:         A2X_PP_SYNC_DEPTH
// Default:      0 ((A2X_CLK_MODE==2) ? 2 : 0)
// Values:       0 2 3
// Enabled:      A2X_CLK_MODE==2
// 
// Defines the number of synchronization register stages in the internal channel buffers for signals passing from the 
// DW_axi_a2x Primary Port to the DW_axi_a2x Secondary Port. 
//  - 0 - No synchronization stages 
//  - 2 - Two-stage synchronization, both stages positive edge 
//  - 3 - Three-stage synchronization, all stages positive edge 
//  If one port has a synchronization depth of 0, the other port must also be 0.
`define i_axi_a2x_A2X_PP_SYNC_DEPTH 0


`define i_axi_a2x_F_SYNC_TYPE_PP 1


// Name:         A2X_SP_SYNC_DEPTH
// Default:      0 ((A2X_CLK_MODE==2) ? 2 : 0)
// Values:       0 2 3
// Enabled:      A2X_CLK_MODE==2
// 
// Defines the number of synchronization register stages in the internal channel buffers for signals passing from the 
// DW_axi_a2x Secondary Port to the DW_axi_a2x Primary Port. 
//  - 0 - No synchronization stages 
//  - 2 - Two-stage synchronization, both stages positive edge 
//  - 3 - Three-stage synchronization, all stages positive edge 
//  If one port has a synchronization depth of 0, the other port must also be 0.
`define i_axi_a2x_A2X_SP_SYNC_DEPTH 0


`define i_axi_a2x_F_SYNC_TYPE_SP 1


`define i_axi_a2x_A2X_SYNC_DEPTH_BUSY 2


// Name:         A2X_PP_IDW
// Default:      4
// Values:       1, ..., 16
// Enabled:      A2X_PP_MODE==1 || A2X_AHB_INTERFACE_TYPE==1
// 
// Specifies the ID width on the DW_axi_a2x Primary Port.
`define i_axi_a2x_A2X_PP_IDW 6


`define i_axi_a2x_A2X_IDW 6


// Name:         A2X_SP_IDW
// Default:      6 (A2X_PP_IDW)
// Values:       1, ..., 16
// 
// Specifies the ID width on the DW_axi_a2x Secondary Port.
`define i_axi_a2x_A2X_SP_IDW 8


// Name:         A2X_PP_AW
// Default:      32
// Values:       32, ..., 64
// 
// Specifies the Address Bus Width of the Primary Port.
`define i_axi_a2x_A2X_PP_AW 32


`define i_axi_a2x_A2X_AW 32


// Name:         A2X_SP_AW
// Default:      32 (A2X_PP_AW)
// Values:       32, ..., 64
// 
// Specifies the Address Bus Width of the Secondary Port.
`define i_axi_a2x_A2X_SP_AW 32

// Specifies the number of bits to the AXI boundary; 12 bits for a 4K boundary. 

`define i_axi_a2x_A2X_BOUNDARY_W 12



// Name:         A2X_PP_BLW
// Default:      4
// Values:       4 5 6 7 8
// Enabled:      (A2X_PP_MODE==0) ? 0 : 1
// 
// Specifies the width of the Primary awlen/arlen port. 
//  - Minimum supported AXI length is 16 (2^4) 
//  - Maximum supported AXI length is 256 (2^8) 
// With Locked mode on, a BLW of 4 is supported.
`define i_axi_a2x_A2X_PP_BLW 8


// Name:         A2X_SP_BLW
// Default:      4
// Values:       4 5 6 7 8
// 
// Specifies the width of the Secondary awlen/arlen port. 
//  - Minimum supported AXI length is 16 (2^4) 
//  - Maximum supported AXI length is 256 (2^8) 
// With Locked mode on, a BLW of 4 is supported.
`define i_axi_a2x_A2X_SP_BLW 8


`define i_axi_a2x_A2X_BLW 8


`define i_axi_a2x_A2X_MAX_ALEN 256


// Name:         A2X_PP_DW
// Default:      32
// Values:       8 16 32 64 128 256 512 1024
// 
// Specifies the Primary Port Data Bus Width.
`define i_axi_a2x_A2X_PP_DW 64


// Name:         A2X_SP_DW
// Default:      32
// Values:       8 16 32 64 128 256 512 1024
// 
// Specifies the Secondary Port Data Bus Width.
`define i_axi_a2x_A2X_SP_DW 32


`define i_axi_a2x_A2X_RS_RATIO 2

`define i_axi_a2x_A2X_RS_RATIO_LOG2 1


// Name:         A2X_PP_ENDIAN
// Default:      (LE) Little Endian
// Values:       (LE) Little Endian (0), (BE-32) Big Endian (1), (BE-A) Big Endian 
//               (2), (BE-8) Big Endian (3)
// 
// Specifies the endian type of the DW_axi_a2x Primary Port.
`define i_axi_a2x_A2X_PP_ENDIAN 0


// Name:         A2X_SP_ENDIAN
// Default:      (LE) Little Endian
// Values:       (LE) Little Endian (0), (BE-8) Big Endian (3)
// 
// Specifies the endian type of the DW_axi_a2x Secondary Port.
`define i_axi_a2x_A2X_SP_ENDIAN 0


// Name:         A2X_WBUF_MODE
// Default:      Cut-Through
// Values:       Cut-Through (0), Store-Forward (1)
// 
// Sets the DW_axi_a2x write buffer mode.
`define i_axi_a2x_A2X_WBUF_MODE 0

// This parameter was orginally intended to control the hardcoding of the DW_axi_a2x
// Write and Read Buffer modes. When this was set to 0, the DW_axi_a2x provided a
// pin/register to control the buffer modes. It was later decided to remove
// the option and always hardcode the Read and Write Buffer Modes. The DW_axi_a2x still 
// uses this parameter to remove redundant logic. Hence this parameter must be
// set to 1 that is; always hardcoded. 

`define i_axi_a2x_A2X_HCBUF_MODE 1


`define i_axi_a2x_A2X_APB_MODE 0

// Hardcodes the DW_axi_a2x Write SNF Length. This option allows the DW_axi_a2x 
// to remove additional logic based on hardcoding the DW_axi_a2x Write 
// Store-Forward Length. If the APB Interface is disabled, the DW_axi_a2x 
// Write Store-Forward Length is hardcoded.

`define i_axi_a2x_A2X_HCSNF_WLEN 1

// Sets the maximum/reset value for the Write AXI Store-Forward Length register.
//  
// This is a Log2-encoded value that determines the number of Secondary Port  
// data transfers to be internally buffered before forwarding the Secondary Port  
// address. 
//  * 4 - 16 Secondary Port data transfers
//  * 5 - 32 Secondary Port data transfers
//  * 6 - 64 Secondary Port data transfers
//  * 7 - 128 Secondary Port data transfers
//  * 8 - 256 Secondary Port data transfers
//
// This value cannot be greater than the depth of the Write Data FIFO 
// (A2X_WD_FIFO_DEPTH).

`define i_axi_a2x_A2X_SNF_AWLEN_DFLT 8

// Sets the minimum value of the Store-Forward AWLEN length.

`define i_axi_a2x_A2X_SNF_AWLEN_MIN 4


// Name:         A2X_HINCR_HCBCNT
// Default:      Yes
// Values:       No (0), Yes (1)
// Enabled:      A2X_PP_MODE==0
// 
// Enables/disables the DW_axi_a2x Read and Write Beat Counter Ports, namely hincr_rbcnt_m and hincr_wbcnt_m. 
//  - 0: Generates hincr_rbcnt and hincr_wbcnt ports  
//  - 1: Removes all hincr_rbcnt and hincr_wbcnt ports 
// The number of ports are based on the A2X_SINGLE_RBCNT and A2X_SINGLE_WBCNT parameters.
`define i_axi_a2x_A2X_HINCR_HCBCNT 1


// Name:         A2X_SINGLE_RBCNT
// Default:      Yes
// Values:       No (0), Yes (1)
// Enabled:      ((A2X_HINCR_HCBCNT==1) || (A2X_AHB_LITE_MODE==1)) ? 0 : 1
// 
// Determines the number of AHB Read INCR Ports (hincr_rbcnt_m). 
//  - 0: Generates an AHB Read INCR Port for each AHB Manager. The DW_axi_a2x uses the hincr_rbcnt corresponding to the 
//  AHB Manager for an AHB INCR transaction. 
//  - 1: Generates only one AHB Read INCR Port (hincr_rbcnt_m1). The DW_axi_a2x uses this port for all AHB INCR 
//  transactions. 
// This parameter is in use only when the DW_axi_a2x is configured for AHB Mode, and the HINCR ports are not hardcoded, 
// and the DW_axi_a2x is not an AHB Lite Mode configuration, that is: A2X_PP_MODE=0, A2X_HINCR_HCBCNT=0 and 
// A2X_AHB_LITE_MODE=0.
`define i_axi_a2x_A2X_SINGLE_RBCNT 1


// Name:         A2X_SINGLE_WBCNT
// Default:      Yes
// Values:       No (0), Yes (1)
// Enabled:      ((A2X_HINCR_HCBCNT==1) || (A2X_AHB_LITE_MODE==1) || 
//               (A2X_BRESP_MODE==1)) ? 0 : 1
// 
// Determines the number of AHB Write INCR Ports (hincr_wbcnt_m). 
//  - 0: Generates an AHB Write INCR Port for each AHB Manager. The DW_axi_a2x uses the hincr_wbcnt corresponding to the 
//  AHB Manager for an AHB INCR transaction. 
//  - 1: Generates only one AHB Write INCR Port (hincr_wbcnt_m1). The DW_axi_a2x uses this port for all AHB INCR 
//  transactions. 
// In Non-Bufferable mode, all AHB INCR transactions are treated as AHB Singles.         
// This parameter is in use only when the DW_axi_a2x is configured for AHB Mode and the HINCR ports are not hardcoded, and 
// the DW_axi_a2x is not an AHB Lite Mode or Non-Bufferable Mode configuration; that is, either: 
//  - A2X_PP_MODE=0 and A2X_HINCR_HCBCNT=0 and A2X_AHB_LITE_MODE=0 
//  - A2X_PP_MODE=0 and A2X_HINCR_HCBCNT=0 and A2X_BRESP_MODE=1
`define i_axi_a2x_A2X_SINGLE_WBCNT 1

// Sets the minimum value of the HINCR length.

`define i_axi_a2x_A2X_HINCR_WBCNT_MIN 0


// Name:         A2X_HINCR_WBCNT_MAX
// Default:      0 (A2X_HINCR_WBCNT_MIN)
// Values:       A2X_HINCR_WBCNT_MIN, ..., 10
// Enabled:      A2X_PP_MODE==0
// 
// Sets the maximum number of primary port beats for an AHB write INCR transaction. This is a Log2-encoded value that 
// determines the number of AHB INCR data beats to accept before generating a new AXI address.  
//  - 0 - 1 AHB data transfer 
//  - 1 - 2 AHB data transfers 
//  - 2 - 4 AHB data transfers 
//  - 3 - 8 AHB data transfers 
//  - 4 - 16 AHB data transfers 
//  - 5 - 32 AHB data transfers 
//  - 6 - 64 AHB data transfers 
//  - 7 - 128 AHB data transfers 
//  - 8 - 256 AHB data transfers 
//  - 9 - 512 AHB data transfers 
//  - 10 - 1024 AHB data transfers 
//  This value cannot exceed a maximum of 1K bytes, that is: 
//  
//      (AHB_data_transfers * number_of_Primary_Port_data_bytes) 
//  
// A minimum restriction on this parameter applies for upsizing configurations (A2X_PP_DW<A2X_SP_DW). The minimum allowed 
// value is determined by the resize ratio, that is: 
//   
//       A2X_PP_DW/A2X_SP_DW.
`define i_axi_a2x_A2X_HINCR_WBCNT_MAX 0


`define i_axi_a2x_A2X_HINCR_AWLEN_DFLT 0

`define i_axi_a2x_A2X_HINCR_AWLEN_MIN 0


// Name:         A2X_BRESP_MODE
// Default:      Non-Bufferable Only
// Values:       Bufferable Only (0), Non-Bufferable Only (1), Dynamic (2)
// Enabled:      (A2X_PP_MODE==0)? 1 : (A2X_LOCKED==0)? 1 : 0
// 
// Selects the Write Response mode.  
//  - Bufferable Mode (available in AXI3 and AHB Mode) 
//  -- Returns OKAY responses after last write data beat is received from primary port write data channel.  
//  - Non-Bufferable - Returns response received on Secondary Port 
//  - Dynamic Mode (available only in AHB mode): 
//  -- Returns response for non-bufferable transaction 
//  -- Responses for bufferable transactions ignored and not returned  
//    Note: To support AXI exclusive access, it is recommended to set the write response mode to non-bufferable.  
//  In AXI4 configurations, only Non-Bufferable mode is supported. 
//  - When A2X_PP_MODE = 0: Bufferable, Non-Bufferable and Dynamic modes are supported.  
//  - When A2X_PP_MODE = 1:  
//  -- If A2X_AXI_INTERFACE_TYPE = AXI3:  
//         If A2X_LOCKED = 1, only Non-Bufferable mode is supported.  
//         If A2X_LOCKED = 0, Non-Bufferable and Bufferable mode are supported. 
//  -- If A2X_AXI_INTERFACE_TYPE = AXI4/ACELITE: Only Non-Bufferable mode is supported.
`define i_axi_a2x_A2X_BRESP_MODE 1


// Name:         A2X_BRESP_ORDER
// Default:      In-Order
// Values:       In-Order (0), Out-of-Order (1)
// Enabled:      (A2X_BRESP_MODE==0)? 0 : 1
// 
// Selects the order in which write responses are returned to the DW_axi_a2x Secondary Port.  
//  - In-Order - Write responses returned in the same order as sent on Secondary Port Write Address channel.  
//  - Out-Of-Order - Write response may return from Secondary Port in different order than sent on Secondary Port Write 
//  Address channel. 
// This parameter is in use only for Non-Bufferable or Dynamic Response mode (A2X_BRESP_MODE=1/2).
`define i_axi_a2x_A2X_BRESP_ORDER 0

// Enables the A2X_NUM_UWID parameter (number of unique Write IDs). Since Store-Forward is hardcoded, equal-sized non-bufferable configurations have no limit on the number of UWID.<br> 
// There is no restriction on the number of outstanding Write IDs:
// - In Bufferable mode
// - In an equal-sized configuration with Non-Bufferable mode

`define i_axi_a2x_A2X_OSW_EN 1


// Name:         A2X_NUM_UWID
// Default:      1
// Values:       1, ..., (A2X_PP_MODE==0)? A2X_NUM_AHBM : 64
// Enabled:      ((A2X_PP_MODE==0) && (A2X_AHB_LITE_MODE==1))? 0 : ((A2X_OSW_EN==1) 
//               && (A2X_BRESP_ORDER==1)) ? 1 : 0
// 
// Selects the number of unique Write IDs for which the DW_axi_a2x may have outstanding on the AXI secondary port. When 
// responses are returned in order, there is no restriction on the number of unique write IDs. In this case, this parameter is 
// not used, and the only restriction placed on the number of outstanding write transactions is the A2X_OSAW_LIMIT parameter.  
// 
// This parameter is enabled for Out-of-Order Write Responses for: 
//  - AHB and AXI upsized and downsized configurations 
//  - AHB equal-sized Dynamic mode  
//  This parameter is disabled for: 
//  - AHB and AXI Bufferable Response mode 
//  - AXI equal-sized configurations 
// For more information on usage for this parameter, refer to "Outstanding Transaction Limits" in the DesignWare 
// DW_axi_a2x Databook.
`define i_axi_a2x_A2X_NUM_UWID 1


// Name:         A2X_SP_OSAW_LIMIT_P1
// Default:      3
// Values:       3, ..., 64
// Enabled:      (A2X_PP_MODE==0)? 1 : (A2X_OSW_EN==1)? 1 : 0
// 
// Defines the maximum number of Secondary Port write addresses that the DW_axi_a2x can send before sending data. This 
// parameter is enabled for all configurations except AXI equal-sized  configurations. 
// For more information on usage for this parameter, refer to "Outstanding Transaction Limits" in the DesignWare 
// DW_axi_a2x Databook.
`define i_axi_a2x_A2X_SP_OSAW_LIMIT_P1 3


`define i_axi_a2x_A2X_SP_OSAW_LIMIT 2

`define i_axi_a2x_A2X_OSAW_LIMIT 2


// Name:         A2X_PP_OSAW_LIMIT_P1
// Default:      16 ((A2X_OSW_EN==1)? 16 : 3)
// Values:       3, ..., 64
// Enabled:      (A2X_PP_ENDIAN!=0)? 1 : (A2X_PP_DW<A2X_SP_DW)? 1 : 
//               ((A2X_PP_DW>A2X_SP_DW) && (A2X_WBUF_MODE==1))? 1 : 0
// 
// Defines the maximum number of outstanding Primary Port write addresses that the DW_axi_a2x can accept before receiving 
// write data. 
// For more information on usage for this parameter, refer to "Outstanding Transaction Limits" in the DesignWare 
// DW_axi_a2x Databook.
`define i_axi_a2x_A2X_PP_OSAW_LIMIT_P1 16


`define i_axi_a2x_A2X_PP_OSAW_LIMIT 15


// Name:         A2X_B_OSW_LIMIT_P1
// Default:      16 ((A2X_OSW_EN==1)? 16 : 3)
// Values:       3, ..., 64
// Enabled:      (A2X_OSW_EN==1)? 1 : 0
// 
// Defines the maximum number of outstanding Secondary Port write transactions per ID when responses are returned 
// out-of-order. 
// For more information on usage for this parameter, refer to "Outstanding Transaction Limits" in the DesignWare 
// DW_axi_a2x Databook.
`define i_axi_a2x_A2X_B_OSW_LIMIT_P1 16


`define i_axi_a2x_A2X_B_OSW_LIMIT 15

`define i_axi_a2x_A2X_OSW_LIMIT 15


// Name:         A2X_RBUF_MODE
// Default:      Cut-Through
// Values:       Cut-Through (0), Store-Forward (1)
// Enabled:      ((A2X_PP_MODE==1) || ((A2X_PP_MODE==0) && (A2X_LOCKED==0)))? 1 : 0
// 
// Sets the DW_axi_a2x read buffer mode. 
// In AHB mode with Locked support enabled, the Read Buffer Mode (A2X_RBUF_MODE) is hard-coded to Cut-Through. In this 
// mode, the read data buffer is large enough to accept any outstanding read data transactions. Thus, Store-Forward is not 
// required in this configuration. For all other modes, the A2X_RBUF_MODE parameter is user-configurable.
`define i_axi_a2x_A2X_RBUF_MODE 0

// Hardcodes the DW_axi_a2x Write SNF Length. This option allows the DW_axi_a2x 
// to remove additional logic based on hardcoding the DW_axi_a2x Write 
// Store-Forward length. If the APB interface is disabled, the DW_axi_a2x Read 
// Store-Forward length is hardcoded.

`define i_axi_a2x_A2X_HCSNF_RLEN 1

// Sets the maximum/reset value for the Read AXI Store-Forward Length register.
//  
// This is a Log2-encoded value that determines the number of free spaces that 
// must be in the Read Data FIFO before the AR is forwarded to the Secondary 
// Port address. The number of free spaces is determined from the number of 
// empty locations in the FIFO and the number of outstanding transactions.
//  * 4 - 16 Secondary Port data transfers
//  * 5 - 32 Secondary Port data transfers
//  * 6 - 64 Secondary Port data transfers
//  * 7 - 128 Secondary Port data transfers
//  * 8 - 256 Secondary Port data transfers
//
// This value cannot be greater than the depth of the Read Data FIFO  
// (A2X_RD_FIFO_DEPTH), nor can it be greater than the length of the Secondary 
// Port AXI length (arlen_sp); that is, 2^A2X_BLW.

`define i_axi_a2x_A2X_SNF_ARLEN_DFLT 8

// Sets the minimum value of the Read Store-Forward ARLEN Length.

`define i_axi_a2x_A2X_SNF_ARLEN_MIN 4

// Sets the maximum/reset value for the AHB Read Recall. 
// 
// This is a Log2-encoded value that determines the number of data entries 
// that must be in the Read Data FIFO before the AHB Manager is recalled from 
// Split. 
//  * 2 - 4 data transfers
//  * 3 - 8 data transfers
//  * 4 - 16 data transfers
//  * 5 - 32 data transfers
//
// This value cannot be greater than the depth of the Read Data FIFO  
// (A2X_RD_FIFO_DEPTH).

`define i_axi_a2x_A2X_AHB_RRECALL_DEPTH 2

// Defines how the DW_axi_a2x responds to an Early Burst Terminated (EBT)   
// condition during a write transaction.
//  * AHB EBT Mode(0) - Only generates strobed data for a write transaction 
//    Early Burst Terminated by another write to the DW_axi_a2x, or if a write  
//    transaction commences before the AHB Manager returns to complete its  
//    transfer. 
//  * AHB EBT Mode(1) - Generates strobed data beats when an AHB Write 
//    transaction is Early Burst Terminated by another Manager. When the  
//    AHB Manager returns to complete its transfer, it is considered a new write  
//    transaction.

`define i_axi_a2x_A2X_AHB_EBT_MODE 1

// Sets the minimum value of the HINCR length.

`define i_axi_a2x_A2X_HINCR_RBCNT_MIN 0


// Name:         A2X_HINCR_RBCNT_MAX
// Default:      0 (A2X_HINCR_RBCNT_MIN)
// Values:       A2X_HINCR_RBCNT_MIN, ..., (A2X_LOCKED==0)? 10 : 7
// Enabled:      A2X_PP_MODE==0
// 
// Sets the maximum number of primary port beats for an AHB read INCR transaction. This is a Log2-encoded value that 
// determines the number of AHB Read INCR data beats to prefetch.  
//  - 0  - Prefetch 1 AHB data transfer 
//  - 1  - Prefetch 2 AHB data transfers 
//  - 2  - Prefetch 4 AHB data transfers 
//  - 3  - Prefetch 8 AHB data transfers 
//  - 4  - Prefetch 16 AHB data transfers 
//  - 5  - Prefetch 32 AHB data transfers 
//  - 6  - Prefetch 64 AHB data transfers 
//  - 7  - Prefetch 128 AHB data transfers 
//  - 8  - Prefetch 256 AHB data transfers 
//  - 9  - Prefetch 512 AHB data transfers 
//  - 10 - Prefetch 1024 AHB data transfers 
// This value cannot exceed a maximum of 1K bytes. To calculate the maximum number of bytes: 
//  
//     (AHB_data_transfers * number_of_primary_port_data_bytes) 
//  
//  
// In AHB Locked mode, this value cannot exceed the DW_axi_a2x maximum prefetch of 128. In this mode, the Read Data buffer 
// depth is set to: 
//   
//     (number_of_managers * maximum_Prefetch) 
//   
// For upsizing configurations (A2X_PP_DW<A2X_SP_DW), a minimum restriction on this parameter applies. The minimum allowed 
// value is determined by the resize ratio, that is: A2X_PP_DW/A2X_SP_DW.
`define i_axi_a2x_A2X_HINCR_RBCNT_MAX 0


`define i_axi_a2x_A2X_LKMODE_MAX_PREFETCH 16


`define i_axi_a2x_A2X_HINCR_ARLEN_DFLT 0

`define i_axi_a2x_A2X_HINCR_ARLEN_MIN 0


// Name:         A2X_READ_INTLEV
// Default:      Disabled
// Values:       Disabled (0), Enabled (1)
// 
// Enables support for Read Data interleaving.
`define i_axi_a2x_A2X_READ_INTLEV 0


// Name:         A2X_READ_ORDER
// Default:      In-Order ((A2X_READ_INTLEV==1)? 1 : 0)
// Values:       In-Order (0), Out-of-Order (1)
// Enabled:      A2X_READ_INTLEV==0
// 
// Selects the Secondary Port Read Data order. 
//  - In-Order - Read data is returned in same order as sent on Secondary Port channel.  
//  - Out-Of-Order - Read data may return from Secondary Port in different order than sent on Secondary Port write address 
//  channel.
`define i_axi_a2x_A2X_READ_ORDER 0

// Simulation Read and Write Data reordering. Determines if the testbench 
// returns read data or write responses in the same order as the AR and AW 
// addresses.

`define i_axi_a2x_SIM_REORDER 0

// -Enabled the Number of Unique Read ID parameters. 
// -Enabled for Resized Configurations

`define i_axi_a2x_A2X_OSR_EN 1


// Name:         A2X_NUM_URID
// Default:      1
// Values:       1, ..., (A2X_PP_MODE==0)? A2X_NUM_AHBM : 128
// Enabled:      ((A2X_OSR_EN==1) && ((A2X_READ_ORDER==1) || (A2X_READ_INTLEV==1)))? 
//               1 : 0
// 
// Selects the number of unique Read IDs for which the DW_axi_a2x may have outstanding transactions. When read data are 
// returned in order, there is no restriction on the number of unique Read IDs. 
// Enabled under the following conditions: 
//  - In Out-Of-Order or Interleaved configurations with: 
//  -- AHB/AXI upsizing or downsizing configurations 
//  -- AHB configurations with A2X_HINCR_RBCNT > 2^A2X_SP_BLW 
//  - In In-Order configurations, this parameter is hardcoded to 1 for: 
//  -- AHB/AXI upsizing or downsizing configurations 
//  -- AHB Configurations with A2X_HINCR_RBCNT > 2^A2X_SP_BLW  
//  For more information on usage for this parameter, refer to "Outstanding Transaction Limits" in the DesignWare 
//  DW_axi_a2x Databook.
`define i_axi_a2x_A2X_NUM_URID 1


// Name:         A2X_OSR_LIMIT_P1
// Default:      16 ((A2X_OSR_EN==1)? 16 : 3)
// Values:       3, ..., 128
// Enabled:      ((A2X_LOCKED==1) || (A2X_OSR_EN==1))? 1 : 0
// 
// Selects the maximum number of outstanding Secondary Port read transactions when read data are returned in order. Also 
// selects the maximum number of outstanding Secondary Port read transactions per ID when read data are returned out-of-order. 
//   
// For more information on usage for this parameter, refer to "Outstanding Transaction Limits" in the DesignWare 
// DW_axi_a2x Databook.
`define i_axi_a2x_A2X_OSR_LIMIT_P1 16


`define i_axi_a2x_A2X_OSR_LIMIT 15


// Name:         A2X_A_UBW
// Default:      0
// Values:       0, ..., 256
// Enabled:      A2X_PP_MODE==0 && <DWC-AMBA-AHB5-Fabric-Source feature 
//               authorize>==1 && <DWC-AMBA-Fabric-Source feature authorize>==1
// 
// This parameter specifies the AHB address channel user bus width. When set to 0, the address channel user ports do not 
// exist on the DW_axi_a2x.
`define i_axi_a2x_A2X_A_UBW 0


// Name:         A2X_USER_SIGNAL_XFER_MODE
// Default:      Pass Through
// Values:       Pass Through (0), Aligned to Data (1)
// Enabled:      A2X_PP_MODE==0
// 
// This parameter selects whether the data channel user signals are to be transported across DW_axi_a2x as pass through or 
// aligned to data.
`define i_axi_a2x_A2X_USER_SIGNAL_XFER_MODE 0


// Name:         A2X_WUSER_BITS_PER_BYTE
// Default:      0
// Values:       0, ..., 8
// Enabled:      (A2X_USER_SIGNAL_XFER_MODE==1) && (<DWC-AMBA-AHB5-Fabric-Source 
//               feature authorize> == 1) && <DWC-AMBA-Fabric-Source feature 
//               authorize>==1
// 
// This parameter specifies the number of user signal bits corresponding to each byte of write data bus.
`define i_axi_a2x_A2X_WUSER_BITS_PER_BYTE 0


// Name:         A2X_RUSER_BITS_PER_BYTE
// Default:      0
// Values:       0, ..., 8
// Enabled:      (A2X_USER_SIGNAL_XFER_MODE==1) && (<DWC-AMBA-AHB5-Fabric-Source 
//               feature authorize> == 1) && <DWC-AMBA-Fabric-Source feature 
//               authorize>==1
// 
// This parameter specifies the number of user signal bits corresponding to each byte of read data bus.
`define i_axi_a2x_A2X_RUSER_BITS_PER_BYTE 0


// Name:         A2X_W_UBW
// Default:      0 ((A2X_USER_SIGNAL_XFER_MODE==1) ? 
//               ((A2X_PP_DW/8)*A2X_WUSER_BITS_PER_BYTE) : 0)
// Values:       0, ..., (A2X_USER_SIGNAL_XFER_MODE==1) ? 
//               ((A2X_PP_DW/8)*A2X_WUSER_BITS_PER_BYTE) : 256
// Enabled:      (A2X_PP_MODE==0) && (A2X_USER_SIGNAL_XFER_MODE==0) && 
//               <DWC-AMBA-AHB5-Fabric-Source feature authorize>==1 && <DWC-AMBA-Fabric-Source 
//               feature authorize>==1
// 
// This parameter specifies the width of AHB write data channel user bus. When set to 0, the write data channel user ports 
// do not exist on the DW_axi_a2x.
`define i_axi_a2x_A2X_W_UBW 0


// Name:         A2X_R_UBW
// Default:      0 ((A2X_USER_SIGNAL_XFER_MODE==1) ? 
//               ((A2X_PP_DW/8)*A2X_RUSER_BITS_PER_BYTE) : 0)
// Values:       0, ..., (A2X_USER_SIGNAL_XFER_MODE==1) ? 
//               ((A2X_PP_DW/8)*A2X_RUSER_BITS_PER_BYTE) : 256
// Enabled:      (A2X_PP_MODE==0) && (A2X_USER_SIGNAL_XFER_MODE==0) && 
//               <DWC-AMBA-AHB5-Fabric-Source feature authorize>==1 && <DWC-AMBA-Fabric-Source 
//               feature authorize>==1
// 
// This parameter specifies the width of AHB read data channel user bus. When set to 0, the read data channel user ports do 
// not exist on the DW_axi_a2x.
`define i_axi_a2x_A2X_R_UBW 0


// Name:         A2X_AWSBW
// Default:      0 ((A2X_PP_MODE==0) ? A2X_A_UBW : 0)
// Values:       0, ..., 256
// Enabled:      A2X_PP_MODE==1
// 
// Specifies the DW_axi_a2x Write Address Sideband (AXI3)/User Signal (AXI4/ACE-Lite) Bus Width. When set to 0, the write 
// address sideband (AXI3)/user (AXI4/ACE-Lite) ports are removed.
`define i_axi_a2x_A2X_AWSBW 0


// Name:         A2X_ARSBW
// Default:      0 ((A2X_PP_MODE==0) ? A2X_A_UBW : 0)
// Values:       0, ..., 256
// Enabled:      A2X_PP_MODE==1
// 
// Specifies the DW_axi_a2x Read Address Sideband (AXI3)/User Signal (AXI4/ACE-Lite) Bus Width. When set to 0, the Read 
// address sideband (AXI3)/user (AXI4/ACE-Lite) ports are removed.
`define i_axi_a2x_A2X_ARSBW 0


// Name:         A2X_WSBW
// Default:      0 ((A2X_PP_MODE==0) ? ((A2X_USER_SIGNAL_XFER_MODE==1) ? 
//               ((A2X_SP_DW/8)*A2X_WUSER_BITS_PER_BYTE) : A2X_W_UBW) : 0)
// Values:       0, ..., (A2X_PP_MODE==0) ? ((A2X_USER_SIGNAL_XFER_MODE==1) ? 
//               ((A2X_SP_DW/8)*A2X_WUSER_BITS_PER_BYTE) : 256) : 256
// Enabled:      A2X_PP_MODE==1
// 
// Specifies the DW_axi_a2x Write Data Sideband (AXI3)/User Signal (AXI4/ACE-Lite) Bus Width. When set to 0, the Write Data 
// sideband (AXI3)/user (AXI4/ACE-Lite) ports are removed.
`define i_axi_a2x_A2X_WSBW 0


// Name:         A2X_RSBW
// Default:      0 ((A2X_PP_MODE==0) ? ((A2X_USER_SIGNAL_XFER_MODE==1) ? 
//               ((A2X_SP_DW/8)*A2X_RUSER_BITS_PER_BYTE) : A2X_R_UBW) : 0)
// Values:       0, ..., (A2X_PP_MODE==0) ? ((A2X_USER_SIGNAL_XFER_MODE==1) ? 
//               ((A2X_SP_DW/8)*A2X_RUSER_BITS_PER_BYTE) : 256) : 256
// Enabled:      A2X_PP_MODE==1
// 
// Specifies the DW_axi_a2x Read Data Sideband (AXI3)/User Signal (AXI4/ACE-Lite) Bus Width. When set to 0, the Read Data 
// sideband (AXI3)/user (AXI4/ACE-Lite) ports are removed.
`define i_axi_a2x_A2X_RSBW 0


// Name:         A2X_BSBW
// Default:      0
// Values:       0, ..., 256
// Enabled:      (A2X_PP_MODE==1) && (A2X_BRESP_MODE!=0)
// 
// Specifies the DW_axi_a2x Write Response Sideband (AXI3)/User Signal (AXI4/ACE-Lite) Bus Width. When set to 0, the Write 
// Response sideband (AXI3)/user (AXI4/ACE-Lite) ports are removed.
`define i_axi_a2x_A2X_BSBW 0


// Name:         A2X_INC_QOS
// Default:      No
// Values:       No (0), Yes (1)
// Enabled:      (((A2X_AXI_INTERFACE_TYPE==1) || (A2X_AXI_INTERFACE_TYPE==2)) && 
//               (A2X_PP_MODE==1))
// 
// If true, the primary port manager and secondary port subordinate write and read address channels have QoS signals 
// (awqos_*/arqos_*) in the I/O.
`define i_axi_a2x_A2X_INC_QOS 0


// `define i_axi_a2x_A2X_HAS_QOS



// Name:         A2X_INC_REGION
// Default:      No
// Values:       No (0), Yes (1)
// Enabled:      (((A2X_AXI_INTERFACE_TYPE==1) || (A2X_AXI_INTERFACE_TYPE==2)) && 
//               (A2X_PP_MODE==1))
// 
// If true, the primary port manager and secondary port subordinate write and read address channels have Region signals 
// (awregion_*/arregion_*) in the I/O.
`define i_axi_a2x_A2X_INC_REGION 0


// `define i_axi_a2x_A2X_HAS_REGION


// Name:         A2X_AW_FIFO_DEPTH
// Default:      4 (((A2X_PP_MODE==0) && (A2X_BRESP_MODE==1) && 
//               (A2X_AHB_SPLIT_MODE==0))? 2 :4)
// Values:       2, ..., 32
// Enabled:      ((A2X_PP_MODE==0) && (A2X_BRESP_MODE==1) && 
//               (A2X_AHB_SPLIT_MODE==0))? 0 : 1
// 
// Sets the depth of the Write Address Channel buffer.
`define i_axi_a2x_A2X_AW_FIFO_DEPTH 4


// Name:         A2X_WD_FIFO_DEPTH
// Default:      16 ([<functionof> A2X_WBUF_MODE A2X_SNF_AWLEN_DFLT])
// Values:       2, ..., 512
// 
// Sets the depth of the Write Data Channel buffer.
`define i_axi_a2x_A2X_WD_FIFO_DEPTH 16


// Name:         A2X_BRESP_FIFO_DEPTH
// Default:      2
// Values:       2, ..., 32
// Enabled:      (A2X_PP_MODE==0) ? 0 : 1
// 
// Sets the depth of the Write Response Channel buffer. In the AHB mode, this parameter is hardcoded to 2.
`define i_axi_a2x_A2X_BRESP_FIFO_DEPTH 2


// Name:         A2X_AR_FIFO_DEPTH
// Default:      4 ((A2X_PP_MODE==0)? 2 : 4)
// Values:       2, ..., 32
// Enabled:      ((A2X_PP_MODE==0) && (A2X_AHB_SPLIT_MODE==0))? 0 : 1
// 
// Sets the depth of the Read Address Channel buffer.
`define i_axi_a2x_A2X_AR_FIFO_DEPTH 4


// Name:         A2X_RD_FIFO_DEPTH
// Default:      16 ([<functionof> A2X_PP_MODE A2X_LOCKED A2X_NUM_AHBM 
//               A2X_LKMODE_MAX_PREFETCH A2X_RBUF_MODE A2X_SNF_ARLEN_DFLT])
// Values:       2, ..., 2048
// Enabled:      ((A2X_LOCKED==1) && (A2X_PP_MODE==0)) ? 0 : 1
// 
// Sets the depth of the Read Data Channel buffer. In the AHB mode with Locked support, the buffer depth is set to: 
//   
//      (number_of_AHB_Managers * maximum_burst_length)  
//  
//  This ensures that the DW_axi_a2x can store all outstanding Read transactions before issuing an AHB Locked transaction 
//  on the Secondary Port AXI channel.
`define i_axi_a2x_A2X_RD_FIFO_DEPTH 16


// Name:         A2X_LK_RD_FIFO_DEPTH
// Default:      4
// Values:       2, ..., A2X_LKMODE_MAX_PREFETCH
// Enabled:      0
// 
// Sets the depth of the Locked Read Data Channel buffer in AHB mode. The buffer does not exist in AXI mode, or in AHB mode 
// without Locked support.
`define i_axi_a2x_A2X_LK_RD_FIFO_DEPTH 4


// Name:         A2X_AUTO_LINK_SPLIT_MODE
// Default:      1
// Values:       0, 1
// Enabled:      [<functionof> equal $::shell_activity_mode "assembler"]
// 
// Controls the connection of the A2X_AHB_SPLIT_MODE parameter to the Configure Interface Parameter SplitCapable value is 
// set to 1. 
// 
`define i_axi_a2x_A2X_AUTO_LINK_SPLIT_MODE 1

/////////////////////////////////////////////////////
// Timing mode parameters
/////////////////////////////////////////////////////


// Name:         A2X_AR_SP_PIPELINE
// Default:      Disable
// Values:       Disable (0), Enable (1)
// 
// Optional. Secondary Port Read Address Channel timing pipeline.
`define i_axi_a2x_A2X_AR_SP_PIPELINE 0


// Name:         A2X_AW_SP_PIPELINE
// Default:      Disable
// Values:       Disable (0), Enable (1)
// 
// Optional. Secondary Port Write Address Channel timing pipeline.
`define i_axi_a2x_A2X_AW_SP_PIPELINE 0


`define i_axi_a2x_A2X_RS_AR_TMO 0


`define i_axi_a2x_A2X_RS_AW_TMO 0


`define i_axi_a2x_A2X_RS_R_TMO 0


`define i_axi_a2x_A2X_RS_W_TMO 0


`define i_axi_a2x_A2X_RS_B_TMO 0

//**************************************************************************************************
// Defined Constants (Resized configurations)
//**************************************************************************************************

`define i_axi_a2x_A2X_AHB_LOCKED 0


// `define i_axi_a2x_A2X_HAS_LOCKED


`define i_axi_a2x_A2X_INT_NUM_AHBM 9


`define i_axi_a2x_A2X_UPSIZE 0


`define i_axi_a2x_A2X_DOWNSIZE 1


// `define i_axi_a2x_A2X_IS_UPSIZED

`define i_axi_a2x_A2X_IS_DOWNSIZED


// `define i_axi_a2x_A2X_HAS_RBUF


// `define i_axi_a2x_A2X_IS_EQSIZED

//**************************************************************************************************
// Defined Constants (INCR Enables)
//**************************************************************************************************

`define i_axi_a2x_A2X_HAS_NBUF_MODE


`define i_axi_a2x_A2X_HAS_HINCR_HCBCNT


`define i_axi_a2x_A2X_HAS_SINGLE_RBCNT


`define i_axi_a2x_A2X_HAS_SINGLE_WBCNT


// `define i_axi_a2x_A2X_HAS_CNT_M1


// `define i_axi_a2x_A2X_HAS_CNT_M2


// `define i_axi_a2x_A2X_HAS_CNT_M3


// `define i_axi_a2x_A2X_HAS_CNT_M4


// `define i_axi_a2x_A2X_HAS_CNT_M5


// `define i_axi_a2x_A2X_HAS_CNT_M6


// `define i_axi_a2x_A2X_HAS_CNT_M7


`define i_axi_a2x_A2X_HAS_CNT_M8


// `define i_axi_a2x_A2X_HAS_CNT_M9


// `define i_axi_a2x_A2X_HAS_CNT_M10


// `define i_axi_a2x_A2X_HAS_CNT_M11


// `define i_axi_a2x_A2X_HAS_CNT_M12


// `define i_axi_a2x_A2X_HAS_CNT_M13


// `define i_axi_a2x_A2X_HAS_CNT_M14


// `define i_axi_a2x_A2X_HAS_CNT_M15


//**************************************************************************************************
// Defined Constants (Sideband Buses)
//**************************************************************************************************

// `define i_axi_a2x_A2X_HAS_LOWPWR_IF


// `define i_axi_a2x_A2X_HAS_USER_SIGNAL_XFER_MODE

`define i_axi_a2x_A2X_INT_HASBW 1

// `define i_axi_a2x_A2X_HAS_HASB

`define i_axi_a2x_A2X_INT_HWSBW 1

// `define i_axi_a2x_A2X_HAS_HWSB

`define i_axi_a2x_A2X_INT_HRSBW 1

// `define i_axi_a2x_A2X_HAS_HRSB


// `define i_axi_a2x_A2X_HAS_AWSB

`define i_axi_a2x_A2X_INT_AWSBW 1

// `define i_axi_a2x_A2X_HAS_WSB

`define i_axi_a2x_A2X_INT_WSBW 1

// `define i_axi_a2x_A2X_HAS_ARSB

`define i_axi_a2x_A2X_INT_ARSBW 1

// `define i_axi_a2x_A2X_HAS_RSB

`define i_axi_a2x_A2X_INT_RSBW 1

// `define i_axi_a2x_A2X_HAS_BSB

`define i_axi_a2x_A2X_INT_BSBW 1

// `define i_axi_a2x_A2X_PP_IS_AHB

`define i_axi_a2x_A2X_PP_IS_AXI

`define i_axi_a2x_A2X_CLK_IS_SYNC

//**************************************************************************************************
// Defined Constants (FIFO Parameter)
//**************************************************************************************************

`define i_axi_a2x_A2X_AW_FIFO_DEPTH_LOG2 2

`define i_axi_a2x_A2X_AR_FIFO_DEPTH_LOG2 2

`define i_axi_a2x_A2X_BRESP_FIFO_DEPTH_LOG2 1

`define i_axi_a2x_A2X_WD_FIFO_DEPTH_LOG2 4

`define i_axi_a2x_A2X_RD_FIFO_DEPTH_LOG2 4

`define i_axi_a2x_A2X_B_OSW_LIMIT_LOG2 4

`define i_axi_a2x_A2X_PP_OSAW_LIMIT_LOG2 4

`define i_axi_a2x_A2X_SP_OSAW_LIMIT_LOG2 1

`define i_axi_a2x_A2X_OSR_LIMIT_LOG2 4

`define i_axi_a2x_A2X_LK_RD_FIFO_DEPTH_LOG2 2
//**************************************************************************************************
// Defined Constants (DW_axi_a2x Parameter)
//**************************************************************************************************

`define i_axi_a2x_A2X_PP_DW_LOG2 6

`define i_axi_a2x_A2X_SP_DW_LOG2 5

`define i_axi_a2x_A2X_PP_NUM_BYTES 8

`define i_axi_a2x_A2X_PP_WSTRB_DW 8

`define i_axi_a2x_A2X_SP_NUM_BYTES 4

`define i_axi_a2x_A2X_SP_WSTRB_DW 4

`define i_axi_a2x_A2X_PP_MAX_SIZE 3

`define i_axi_a2x_A2X_SP_MAX_SIZE 2

`define i_axi_a2x_A2X_MAX_PP_TOTAL_BYTES 2056

`define i_axi_a2x_A2X_MAX_SP_TOTAL_BYTES 1028

`define i_axi_a2x_A2X_MAX_TOTAL_BYTES 2056


`define i_axi_a2x_A2X_MAX_TOTAL_BYTES_LOG2 12

`define i_axi_a2x_A2X_PP_NUM_BYTES_LOG2 3

`define i_axi_a2x_A2X_SP_NUM_BYTES_LOG2 2


`define i_axi_a2x_A2X_PP_DW_16


`define i_axi_a2x_A2X_PP_DW_32


`define i_axi_a2x_A2X_PP_DW_64


// `define i_axi_a2x_A2X_PP_DW_128


// `define i_axi_a2x_A2X_PP_DW_256


// `define i_axi_a2x_A2X_PP_DW_512


// `define i_axi_a2x_A2X_PP_DW_1024


`define i_axi_a2x_A2X_SP_DW_32


// `define i_axi_a2x_A2X_SP_DW_64


// `define i_axi_a2x_A2X_SP_DW_128


// `define i_axi_a2x_A2X_SP_DW_256


// `define i_axi_a2x_A2X_SP_DW_512


// `define i_axi_a2x_A2X_SP_DW_1024


`define i_axi_a2x_A2X_DS_RATIO_2


// `define i_axi_a2x_A2X_DS_RATIO_4


// `define i_axi_a2x_A2X_DS_RATIO_8

//**************************************************************************************************
// Parameters to remove init and test ports in bcm
//**************************************************************************************************


`define i_axi_a2x_DWC_NO_TST_MODE

`define i_axi_a2x_DWC_NO_CDC_INIT

//**************************************************************************************************
// Simulation parameters
//**************************************************************************************************


`define i_axi_a2x_A2X_SIM_SEED 200


`define i_axi_a2x_A2X_SIM_APB_CLK_PERIOD 20


`define i_axi_a2x_A2X_SIM_PP_CLK_PERIOD 10


`define i_axi_a2x_A2X_SIM_SP_CLK_PERIOD 10


`define i_axi_a2x_A2X_SP_CLK_SKEW 0


`define i_axi_a2x_A2X_INACTIVE_VAL 0


// `define i_axi_a2x_A2X_ASYNC_CLKS


// `define i_axi_a2x_A2X_DUAL_CLK

//The following is a way to duplicate the testcases

`define i_axi_a2x_A2X_N_TESTCASE_DUPLICATION 0

//Include SVA assertions

//Used to insert VMM testbench

//Used to insert internal tests


`define i_axi_a2x_A2X_PRIMEPOWER_SIM 0


// `define i_axi_a2x_A2X_SIM_IS_PRIMEPOWER


`define i_axi_a2x_A2X_VERIF_EN 1


`define i_axi_a2x_A2X_HRESPW 2

`define i_axi_a2x_A2X_HRESP_WIDTH_2




//==============================================================================
// End Guard
//==============================================================================  
`endif


