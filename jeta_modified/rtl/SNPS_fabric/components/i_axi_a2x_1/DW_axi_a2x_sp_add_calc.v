/* --------------------------------------------------------------------
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
// Revision: $Id: //dwh/DW_ocb/DW_axi_a2x/amba_dev/src/DW_axi_a2x_sp_add_calc.v#1 $ 
// --------------------------------------------------------------------
*/

`include "DW_axi_a2x_all_includes.vh"
// **************************************************************************************
// Calculate SP Address
//
// The Maximum SP Burst Length is defined as 
// 2^A2X_BLW when in CT Mode and
// A2X_SNF_AWLEN/A2X_SNF_ARLEN Register when in Store-Forward Mode
//
// The address Calculator compares the Transaction Length to the maximum
// transaction length and generates the SP length based on this.
// If the Transaction Length is > Maximum Length 
//   SP Length equals Maximum Length
//   Remaining Transaction Length equals Previous Transaction Length-Maximum Length
// else 
//   SP Length equals Transaction Length 
// **************************************************************************************
module i_axi_a2x_1_DW_axi_a2x_sp_add_calc (/*AUTOARG*/
   // Outputs
   active, pyld_o, len_o, alast_o, nxt_len_o, w_snf_pop_en,
   // Inputs
   clk, resetn, buf_mode, max_len, rs_ratio, ds_fixed_decomp, asize_pp, 
   ds_fixed_len, a_ready_i, active_as, a_fifo_empty, sp_os_fifo_vld, pyld_i, 
   snf_pyld_i, ws_fixed, trans_en
   );

  // **************************************************************************************
  // Parameter Decelaration
  // **************************************************************************************
  parameter A2X_PP_MODE       = 0; 
  parameter A2X_CHANNEL       = 0; 
  parameter A2X_DOWNSIZE      = 0; 
  parameter A2X_AW            = 32;
  parameter A2X_BLW           = 4;
  parameter A2X_SP_MAX_SIZE   = 2; 
  parameter A2X_PP_MAX_SIZE   = 2; 
  parameter BLW_RS            = 4;
  parameter A2X_ASBW          = 1;
  parameter A2X_QOSW          = 1;
  parameter A2X_REGIONW       = 1;
  parameter A2X_DOMAINW       = 1;
  parameter A2X_WSNOOPW       = 1;
  parameter A2X_BARW          = 1;
  parameter A2X_PYLD_I        = 32;                          
  parameter A2X_PYLD_O        = 32;
  parameter BOUNDARY_W        = 12;  // 4K Boundary
  parameter A2X_WSNF_PYLD_W   = 1; 

  localparam STATE_W          = 1;                           
  localparam ST_WAIT          = 1'b0;
  localparam ST_CALC          = 1'b1;

  localparam MAX_PP_BYTE_BEAT = 1<<A2X_PP_MAX_SIZE;
  localparam MAX_SP_BYTE_BEAT = 1<<A2X_SP_MAX_SIZE;

  localparam LEN_W            = (MAX_PP_BYTE_BEAT>(MAX_SP_BYTE_BEAT<<A2X_BLW))? A2X_BLW+3 : A2X_BLW;

  // **************************************************************************************
  // I/O Decelaration
  // **************************************************************************************
  input                                      clk;         // clock
  input                                      resetn;      // asynchronous reset

  input                                      buf_mode;     
  input  [31:0]                              max_len; 
  input  [2:0]                               rs_ratio;
  input  [2:0]                               asize_pp;

  // Handshaking
  input                                      a_ready_i;   // Channel Control
  input                                      active_as; 
  input                                      trans_en;
  input                                      a_fifo_empty;
  input                                      sp_os_fifo_vld;
  output                                     active;

  input  [A2X_PYLD_I-1:0]                    pyld_i;      // Payload
  output [A2X_PYLD_O-1:0]                    pyld_o;

  input                                      ds_fixed_decomp;
  input  [BLW_RS-1:0]                        ds_fixed_len;

  input  [A2X_WSNF_PYLD_W-1:0]               snf_pyld_i; 
  //spyglass disable_block W240
  //SMD: An input has been declared but is not read.
  //SJ : This signal is used in specific config only 
  input                                      ws_fixed;
  //spyglass enable_block W240

  output [A2X_BLW-1:0]                       len_o; 
  output [A2X_BLW-1:0]                       nxt_len_o; 
  output                                     alast_o;
  output                                     w_snf_pop_en;

  // **************************************************************************************
  // Signal Decelaration
  // **************************************************************************************
  wire   [`A2X_IDW-1:0]                      id_i;            // Payload
  wire   [A2X_AW-1:0]                        addr_i; 
  wire   [BLW_RS-1:0]                        len_i; 
  wire   [`A2X_BSW-1:0]                      size_i;     
  wire   [`A2X_BTW-1:0]                      burst_i;   
  wire   [`A2X_LTW-1:0]                      lock_i;   
  wire   [`A2X_CTW-1:0]                      cache_i; 
  wire   [`A2X_PTW-1:0]                      prot_i; 
  wire   [A2X_ASBW-1:0]                      sideband_i;
  wire   [A2X_QOSW-1:0]                      qos_i;
  wire   [A2X_REGIONW-1:0]                   region_i;
  wire   [A2X_DOMAINW-1:0]                   domain_i;
  wire   [A2X_WSNOOPW-1:0]                   snoop_i;
  wire   [A2X_BARW-1:0]                      bar_i;
  wire   [`A2X_RSW-1:0]                      resize_i;
  wire                                       hburst_type;

  reg    [STATE_W-1:0]                       nxt_state;       // State
  reg    [STATE_W-1:0]                       state;
  wire                                       st_change;

  wire   [A2X_AW-1:0]                        align_addr;     // Aligned Address
  wire   [A2X_AW-1:0]                        nxt_align_addr; // Aligned Address
  reg    [BOUNDARY_W-1:0]                    nxt_addr_r;     
  wire   [A2X_AW-1:0]                        nxt_addr;       // Next Transaction Address
  wire   [A2X_BLW-1:0]                       nxt_len_w;      // Next Transaction Length
  wire   [A2X_BLW-1:0]                       len_w;          
  reg    [BLW_RS:0]                          remaining_len;     // Remaining Transaction Length 
  wire   [BLW_RS:0]                          remaining_len_m1;  // Remaining Transaction Length 

  wire   [A2X_AW-1:0]                        addr_o;         // Output Address
  wire   [A2X_BLW-1:0]                       len_o;          // Output Length
  wire   [`A2X_BTW-1:0]                      burst_o;   

  wire   [LEN_W:0]                           max_len_w;      // Maximum Length 
  wire   [LEN_W:0]                           max_len_m1;     // Maximum Length Minus 1

  reg                                        active_r;       // Calculator Active
  reg    [A2X_PYLD_I-1:0]                    pyld_r;
  wire   [A2X_PYLD_I-1:0]                    pyld_w;

  wire [A2X_BLW-1:0]                         fixed_len;
  wire [7:0]                                 rs_bcnt_cmp;
  reg  [7:0]                                 rs_bcnt_cmp_r;
  wire                                       mult_pp_bytes; 

  reg    [7:0]                               rs_bcnt; 
  wire                                       rs_beat_cmp;
  wire                                       addr_sub_en;

  wire                                       a_valid_init;

  wire                                       len_gte_max;     // Length Greater than or Equal to Max
  wire                                       relen_gte_max;   // Remaining length Greater than or Equal to Max. 
  wire                                       len_lt_max;      // Length Less than Max
  wire                                       relen_lte_max;   // Remaining length Less than or Equal to Max. 

  wire                                       ws_fixed_i;
  wire [6:0]                                 addr_sub_int;
  wire [6:0]                                 addr_sub;
  wire [6:0]                                 addr_msk;

  // **************************************************************************************
  // Only Sizes upto Max size Allowed
  // **************************************************************************************
  reg [3:0]  size_w;
  // spyglass disable_block W164b
  // SMD: Identifies assignments in which the LHS width is greater than the RHS width
  // SJ : This is not a functional issue, this is as per the requirement.
  // spyglass disable_block W415a
  // SMD: Signal may be multiply assigned (beside initialization) in the same scope.
  // SJ : size_i is initialized before assignment to avoid latches.
  always @(*) begin: size_w_PROC
    integer i; 
    size_w = 4'b0; 
    for (i=0; i<=A2X_SP_MAX_SIZE; i=i+1)
      // Signed and unsigned operands should not be used in same operation.
      // i can only be an integer, since it is a loop index. It is a design requirement to
      // use i in the following operation and it will not have any adverse effects on the 
      // design. So signed and unsigned operands are used to reduce the logic.
      if (i==size_i) size_w  = size_i;
  end
  // spyglass enable_block W415a
  // spyglass enable_block W164b

  // **************************************************************************************
  // Payload 
  //
  // Registered Version of Payload, This allows the Wrap SPlitter to generate
  // a new address and the FIFO to pop off the current address. The Address
  // calculator will use the information stored in the registered version for
  // decoding the SP Address. 
  // **************************************************************************************
  always @(posedge clk or negedge resetn) begin: pyld_PROC
    if (resetn==1'b0) 
      pyld_r <= {A2X_PYLD_I{1'b0}};
    else begin
      if (!active)
        pyld_r <= pyld_i;
    end
  end

  // Seclect Payload Input for First Address Otherwise selected registered
  // version
  assign pyld_w = (active)? pyld_r : pyld_i; 

  // **************************************************************************************
  // Payload Decode
  // **************************************************************************************
  assign {bar_i, snoop_i, domain_i, region_i, qos_i, hburst_type, sideband_i, id_i, addr_i, resize_i, len_i, 
  size_i, burst_i, lock_i, cache_i, prot_i} = pyld_w;

  // Fixed transaction only available for AXI Configurations
  assign ws_fixed_i = (A2X_PP_MODE==1)? ws_fixed : 1'b0; 
   
  // **************************************************************************************
  // Resize Beat Counter
  //
  // If the Reszie Ratio is greater than 2^BLW, this counter control the
  // - popping of the SNF FIFO 
  // - State Machine Transtition.
  // - AXI Fixed Bursts Calculations
  // **************************************************************************************
  generate
  if ( (A2X_DOWNSIZE==1) && (MAX_PP_BYTE_BEAT>(MAX_SP_BYTE_BEAT<<A2X_BLW)) && (((A2X_PP_MODE==0) && (A2X_CHANNEL==0)) || (A2X_PP_MODE==1)) ) begin: rs_bcnt_GEN
    // Determine number of Bytes In a PP Beat, Total number of PP Bytes in
    // Transaction & Max allowable SP Bytes in a SP Transaction. 
    // spyglass disable_block W486
    // SMD: Reports shift overflow operations
    // SJ : This is not a functional issue, this is as per the requirement.
    wire [15:0]           pp_byte_beat   = (1<<asize_pp);  
    wire [15:0]           max_sp_byte    = 1 << (A2X_BLW + size_i);
    // spyglass enable_block W486

    // If Address unaligned the beat count needs to be adjusted to factor in this unalignment.
    //  assign      addr_msk     = ~(6'b11_1111 << asize_pp) & (6'b11_1111 << (A2X_BLW + size_i));
    //  assign      addr_sub     = (addr_i[5:0]&addr_msk);
    // Address mask :
    // ~(7'b111_1111 << asize_pp) - This gives how many number of bytes are present in the single beat of the primary port.
    // (7'b111_1111 << (A2X_BLW + size_i) - This gives maximum number of bytes can be transferred on the secondary port 
    // (all beats, Considering max. possible burst size (BLW) and max. secondary port size (size_i))
    assign      addr_msk     = ~(7'b111_1111 << asize_pp) & (7'b111_1111 << (A2X_BLW + size_i));
    assign      addr_sub_int  = (addr_i[6:0]&addr_msk);
    assign      addr_sub = addr_sub_int;

    wire a_valid  = (state==ST_WAIT)? a_valid_init : (trans_en & sp_os_fifo_vld); 

    // spyglass disable_block SelfDeterminedExpr-ML
    // SMD: Self determined expression present in the design.
    // SJ : This is not a functional issue, this is as per the requirement.
    // Asserted if Multiple SP Transactions in one PP Data Beat
    assign mult_pp_bytes = (A2X_DOWNSIZE==0)? 1'b0 : ((ws_fixed_i || (len_i=={BLW_RS{1'b0}})) && ((pp_byte_beat-addr_sub)>max_sp_byte))? 1'b1 : 
                                                     (!ws_fixed_i && (len_i!={BLW_RS{1'b0}}) && (pp_byte_beat>max_sp_byte))? 1'b1 : 1'b0;

    // Number of SP Transactions in one PP Beat
    // spyglass disable_block W164a
    // SMD: Identifies assignments in which the LHS width is less than the RHS width
    // SJ : This is not a functional issue, this is as per the requirement.
    // spyglass disable_block W486
    // SMD: Reports shift overflow operations
    // SJ : This is not a functional issue, this is as per the requirement.
    assign rs_bcnt_cmp =  (A2X_DOWNSIZE==0)? 8'b0 : (state==ST_CALC)? rs_bcnt_cmp_r : (pp_byte_beat-addr_sub_int)>>(A2X_BLW + size_i);

    // Registered 
    always @(posedge clk or negedge resetn) begin: rsbcnt_cmp_r_PROC
      if (resetn==1'b0) begin
        rs_bcnt_cmp_r    <= 8'b0; 
      end else begin
        if (a_ready_i && a_valid)  begin
          if ( (state==ST_CALC) && (nxt_state==ST_WAIT) ) begin
            rs_bcnt_cmp_r       <= 8'b0; 
          end else if ((!rs_beat_cmp) && (state==ST_WAIT))
            rs_bcnt_cmp_r       <= (pp_byte_beat-addr_sub_int)>>(A2X_BLW + size_i);
          else if (ws_fixed_i && rs_beat_cmp) begin
            rs_bcnt_cmp_r       <= (pp_byte_beat-addr_sub_int)>>(A2X_BLW + size_i);
          end else if (rs_beat_cmp) begin          
            rs_bcnt_cmp_r       <= (pp_byte_beat)>>(A2X_BLW + size_i);
          end
        end
      end
    end
    // spyglass enable_block W486
    // spyglass enable_block W164a
    // spyglass enable_block SelfDeterminedExpr-ML
    
    // Resize Beat counter - Count the number of SP Data beats in a Primary Port Beat
    always @(posedge clk or negedge resetn) begin: rs_bcnt_PROC
      if (resetn==1'b0)         
        rs_bcnt <= 8'b0;
      else begin
        if (a_ready_i && a_valid && mult_pp_bytes && rs_beat_cmp)
          rs_bcnt <= 8'b0;
        else if (a_ready_i && a_valid && mult_pp_bytes)
          rs_bcnt <= rs_bcnt+1;
      end
    end

    assign addr_sub_en = state ? ((rs_bcnt == 0) ? 1'b1 : 1'b0) : 1'b0;

    // Used to generate a pop to the SNF FIFO
    assign w_snf_pop_en = (buf_mode==1'b0)? 1'b1 : (mult_pp_bytes==1'b0)? 1'b1 : (mult_pp_bytes && (rs_bcnt==(rs_bcnt_cmp-1)))? 1'b1 : 1'b0; 
    assign rs_beat_cmp  = (mult_pp_bytes==1'b0)? 1'b1 : (mult_pp_bytes && (rs_bcnt==(rs_bcnt_cmp-1)))? 1'b1 : 1'b0;

    // AXI Length for AXI Fixed Transactions
    // spyglass disable_block W164a
    // SMD: Identifies assignments in which the LHS width is less than the RHS width
    // SJ : This is not a functional issue, this is as per the requirement.
    assign fixed_len    = (ds_fixed_decomp==1'b0)? len_i : (rs_beat_cmp==1'b0)? max_len-1 : ds_fixed_len; 

    // Max Transaction Length
    // For Downsizing If Fixed Transaction size is greater than Max SP size then maximum length equals resize ratio 
    // spyglass disable_block W486
    // SMD: Reports shift overflow operations
    // SJ : This is not a functional issue, this is as per the requirement.
    assign max_len_w  = (ws_fixed_i && mult_pp_bytes)? max_len : (ws_fixed_i && (|rs_ratio))? (1<<rs_ratio) : max_len;
    assign max_len_m1 = max_len_w - 1;
    // spyglass enable_block W486
    // spyglass enable_block W164a
    
  end else begin 
    assign w_snf_pop_en   = 1'b1; 
    assign rs_beat_cmp    = 1'b1;
    // spyglass disable_block W164a
    // SMD: Identifies assignments in which the LHS width is less than the RHS width
    // SJ : This is not a functional issue, this is as per the requirement.
    assign fixed_len      = (ds_fixed_decomp==1'b0)? len_i : ds_fixed_len; 
    // spyglass enable_block W164a
    assign mult_pp_bytes  = 1'b0; 
    assign addr_sub       = 6'b0;
    assign addr_sub_en    = 6'b0;
    
    // Max Transaction Length
    // For Downsizing If Fixed Transaction size is greater than Max SP size then maximum length equals resize ratio 
    // spyglass disable_block W486
    // SMD: Reports shift overflow operations
    // SJ : This is not a functional issue, this is as per the requirement.
    // spyglass disable_block W164a
    // SMD: Identifies assignments in which the LHS width is less than the RHS width
    // SJ : This is not a functional issue, this is as per the requirement.
    assign max_len_w  = ((A2X_DOWNSIZE==1) && ws_fixed_i && (|rs_ratio))? (1<<rs_ratio) : max_len;
    // spyglass enable_block W164a
    assign max_len_m1 = max_len_w - 1;
    // spyglass enable_block W486
  end
  endgenerate
  
  // **************************************************************************************
  // Length Comparator 
  // - Decodes if Length is greater than Max Length. 
  // - Worst case Scenario is a Downsizing Ratio of 512-8 and a BLW of 8.
  //   Hence a resized length of 16384 or 4000 Hex
  // **************************************************************************************
  // spyglass disable_block W362
  // SMD: Reports an arithmetic comparison operator with unequal length
  // SJ : This is not a functional issue, this is as per the requirement.
  // spyglass disable_block W486
  // SMD: Reports shift overflow operations
  // SJ : This is not a functional issue, this is as per the requirement.
  assign len_gte_max     = (len_i>=max_len_w);          // Length Greater than or Equal Max
  assign relen_gte_max   = (remaining_len>=max_len_w);  // Remaining length Greater than or Equal Max
    
  assign len_lt_max      = (len_i<max_len_w);           // Length Less than Max
  assign relen_lte_max   = (remaining_len<=max_len_w);  // Remaining length Less than Max. 
  // spyglass enable_block W486
  // spyglass enable_block W362

  // **************************************************************************************
  // Write Address Generator State Machine
  //
  // ST_WAIT: Send 1st transfer and transition to ST_CALC if
  //          transaction broken up into multiple transactions. 
  // ST_CALC: Calculate Remain Address until Max PP length reached
  //
  // Depending on the Configurations Types PP transactions may be sent out on
  // the SP without any adjustments. These condifuration are:
  // - AXI Equaled Size Data Widths in Cut-Through Mode.
  // - AXI Upsized Configuration in Cut-Through Mode.
  // - AHB Equaled Size Data Widths in Cut-Through Mode with 
  //   - Read INCR Length less than or equal to 2^A2X_BLW
  //   - Write INCR length cannot exceed 2^A2X_BLW controlled by PP AXI Conversion (H2X). 
  //
  // For AHB Configurations in write Store-Forward Mode, if wlast is generated
  // early due to an EBT or AHB INCR less than HINCR_AWLEN, the A2X only
  // generates the required number of addresses. 
  // Example HINCR_AWLEN(128) & SNF_AWLEN(32)
  // AHB INCR of lenght 24 implies 1 AXI address in SNF Mode
  // AHB INCR of lenght 48 implies 2 AXI address in SNF Mode
  // AHB INCR of lenght 24 implies 4 AXI address in CT Mode
  // **************************************************************************************
  assign a_valid_init = trans_en & ((active_as & sp_os_fifo_vld) | ((!active_as) & (!a_fifo_empty) & sp_os_fifo_vld));

  // State Machine Combinatorial Procedure
  always @(*) begin: SM_COMB_PROC
    nxt_state = state;
    case (state)
      ST_WAIT: begin
        if ((A2X_PP_MODE==0) && (A2X_CHANNEL==0) && (buf_mode==`SNF_MODE)) begin 
          if (a_ready_i && a_valid_init && len_gte_max && ((~snf_pyld_i[0]) || (~rs_beat_cmp)))
            nxt_state = ST_CALC;
        end else begin
          if (a_ready_i && a_valid_init && len_gte_max)
            nxt_state = ST_CALC;
        end
      end
      ST_CALC: begin
        if ((A2X_PP_MODE==0) && (A2X_CHANNEL==0) && (buf_mode==`SNF_MODE)) begin 
          if (trans_en && a_ready_i && sp_os_fifo_vld && ((rs_beat_cmp && snf_pyld_i[0]) || relen_lte_max))
            nxt_state = ST_WAIT;
        end else begin
          if (trans_en && a_ready_i && sp_os_fifo_vld && relen_lte_max )
            nxt_state = ST_WAIT;
        end
      end
    endcase
  end

  //----------------------------------------------------------------------
  // State Machine Clocked Procedure
  //----------------------------------------------------------------------
  always @(posedge clk or negedge resetn) begin: SM_PROC
    if (resetn==1'b0) 
      state <= ST_WAIT;
    else 
      state <= nxt_state;
  end
  
  // state Transtition
  assign st_change = (state!=nxt_state);

  // **************************************************************************************
  // Active Status of the Address Calculator
  // - Asserted high if more than one SP address needs to be generated.
  // **************************************************************************************
  always @(posedge clk or negedge resetn) begin: active_PROC
    if (resetn==1'b0) 
      active_r <= 1'b0;
    else begin
      if (nxt_state==ST_CALC)
        active_r <= 1'b1; 
      else
        active_r <= 1'b0;
    end
  end

  assign active = active_r;
  
  // **************************************************************************************
  // Remaining Length Calculation
  //
  // Calculate the Remaining Transaction Length 
  // **************************************************************************************
  // spyglass disable_block W116
  // SMD: Identifies the unequal length operands in the bit-wise logical, arithmetic, and ternary operators
  // SJ : This is not a functional issue, this is as per the requirement.
  // spyglass disable_block W164b
  // SMD: Identifies assignments in which the LHS width is greater than the RHS width
  // SJ : This is not a functional issue, this is as per the requirement.
  // spyglass disable_block W164a
  // SMD: Identifies assignments in which the LHS width is less than the RHS width
  // SJ : This is not a functional issue, this is as per the requirement.
  // spyglass disable_block W484
  // SMD: Possible loss of carry or borrow in addition or subtraction (Verilog)
  // SJ: Accommodation of carry/borrow bit is not required 
  always @(posedge clk or negedge resetn) begin: remaining_len_PROC
    if (resetn==1'b0) begin
      remaining_len <= {BLW_RS{1'b0}};
    end else begin
      case (state)
        ST_WAIT: begin
          if (a_ready_i && a_valid_init) begin
            remaining_len <= len_i - max_len_m1;
          end
        end
        ST_CALC: begin
          if (trans_en && a_ready_i && sp_os_fifo_vld) begin
            if (ws_fixed_i && mult_pp_bytes && asize_pp==7 && size_i==1) begin 
              if (addr_sub_en==0) 
                remaining_len <= remaining_len - max_len_w;
              else 
                remaining_len <= remaining_len - max_len_w - (addr_sub>>size_i);
            end else begin
              if (ws_fixed_i && mult_pp_bytes && rs_beat_cmp)
                remaining_len <= remaining_len - max_len_w - addr_sub;
              else 
                remaining_len <= remaining_len - max_len_w;
            end
          end
        end
      endcase
    end
  end
  // spyglass enable_block W484
  // spyglass enable_block W164a
  // spyglass enable_block W164b
  // spyglass enable_block W116

  assign remaining_len_m1 = remaining_len-1;

  // **************************************************************************************
  // Align Address
  // **************************************************************************************
  // spyglass disable_block W164a
  // SMD: Identifies assignments in which the LHS width is less than the RHS width
  // SJ : This is not a functional issue, this is as per the requirement.
  assign align_addr     =   addr_i     & ({A2X_AW{1'b1}} << size_w);
  assign nxt_align_addr =   nxt_addr_r & ({A2X_AW{1'b1}} << size_w);

  // **************************************************************************************
  // Next Address Calculation
  //
  // If Transaction Type is INCR Next Address= Previous Address + (SP Length * Size)
  // **************************************************************************************
  wire        burst_incr = (burst_i==`ABURST_INCR)? 1'b1 : 1'b0; 
  // spyglass disable_block W164b
  // SMD: Identifies assignments in which the LHS width is greater than the RHS width
  // SJ : This is not a functional issue, this is as per the requirement.
  wire [31:0] num_bytes  =  max_len_w << size_w;
  // spyglass enable_block W164b

  // spyglass disable_block TA_09
  // SMD: Reports cause of uncontrollability or unobservability and estimates the number of nets whose controllability/ observability is impacted
  // SJ : Few bits of RHS may not be always required 
  always @(posedge clk or negedge resetn) begin: nxt_a_PROC
    if (resetn==1'b0) begin
      nxt_addr_r <= {BOUNDARY_W{1'b0}};
    end else begin
      case (state)
        ST_WAIT: begin
          if (a_ready_i && a_valid_init) begin 
            if (ws_fixed_i && (~mult_pp_bytes)) begin
              nxt_addr_r <= addr_i;
            end else if (ws_fixed_i && mult_pp_bytes)
              nxt_addr_r <=  align_addr + num_bytes;
            else if (burst_incr)
              nxt_addr_r <=  align_addr + num_bytes;
          end
        end
        ST_CALC: begin
          if (trans_en && a_ready_i && sp_os_fifo_vld) begin
            if (ws_fixed_i && ((~mult_pp_bytes) || rs_beat_cmp)) begin
              nxt_addr_r <= addr_i;
            end else if (ws_fixed_i && mult_pp_bytes)
              nxt_addr_r <=  nxt_align_addr + num_bytes;
            else if (burst_incr)
              nxt_addr_r <=  nxt_addr_r + num_bytes;
          end
        end
      endcase
    end
  end
  // spyglass enable_block TA_09

  assign nxt_addr = {addr_i[A2X_AW-1:BOUNDARY_W], nxt_addr_r[BOUNDARY_W-1:0]}; 

  // **************************************************************************************
  // Next Length Calculation
  // **************************************************************************************
  // Calculate the First transaction Length
  assign len_w     = (ws_fixed_i)? fixed_len : len_gte_max? max_len_m1[A2X_BLW-1:0] : len_i;

  // Calculate the Next Transaction Length
  assign nxt_len_w = (ws_fixed_i)? fixed_len : relen_gte_max ? max_len_m1[A2X_BLW-1:0] : remaining_len_m1[A2X_BLW-1:0];
  // spyglass enable_block W164a

  // **************************************************************************************
  // Assign Secondary Port AW Channel Outputs
  // **************************************************************************************
  assign burst_o    = burst_i;
  assign addr_o     = (state==ST_WAIT)? addr_i : nxt_addr;
  assign len_o      = (state==ST_WAIT)? len_w  : nxt_len_w; 
  assign nxt_len_o  = nxt_len_w;

  // ALAST COMB Block 
  reg alast_r;
  always @(*) begin: alast_PROC
    if ((A2X_PP_MODE==0) && (A2X_CHANNEL==0) && (buf_mode==`SNF_MODE)) begin 
      alast_r = ((state==ST_CALC) && (relen_lte_max || (snf_pyld_i[0] && rs_beat_cmp))) || 
                ((state==ST_WAIT) && (len_lt_max || (snf_pyld_i[0] && (~mult_pp_bytes))));
    end else begin
      alast_r = ((state==ST_CALC) && relen_lte_max) || ((state==ST_WAIT) && len_lt_max);
    end    
  end
  assign alast_o    = alast_r;

  // AW Channel Payload
  assign pyld_o     = {bar_i, snoop_i, domain_i, region_i, qos_i, hburst_type, sideband_i, id_i, addr_o, resize_i, len_o, size_i, burst_o, lock_i, cache_i, prot_i};

endmodule
