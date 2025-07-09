/******************************************************************************
Copyright (C) 2018-2022 Synopsys, Inc.
This IP and the associated documentation are confidential and
proprietary to Synopsys, Inc. Your use or disclosure of this IP is 
subject to the terms and conditions of a written license agreement 
between you, or your company, and Synopsys, Inc.
*******************************************************************************
Title  : Package for axi interface
Project: 
Description: It contains essential fields in axi protocol

*******************************************************************************
Date          Version        Author          Modification
05May2022      1.00          chitra        AXI full interface along
                                            with structure
07Jun2022      1.01          chitra        AXI tieup and assign
20Jun2022      1.02          chitra        AXI lite and AXI stream added
******************************************************************************/

package axi_pkg;

// Structure datatype for axi memory mapped
// address struct
// This structure is used for both AW and AR channel
// Source       |     Destination
// Master       |       Slave
//
typedef struct packed {
    logic [0:0] valid;
    logic [7:0] len; // hardcoded for axi4
    logic [2:0] size;
    logic [1:0] burst;
    logic [2:0] prot;
    logic [3:0] cache;
    logic [3:0] qos; // revisit whether we require it
    logic [0:0] lock;
}addr_st;

// Data structure
// This is actually used of write and read
// That means whenever variable of data_st is declared
// we can use it for R and W channel
//
typedef struct packed {
    logic [0:0] valid;
    logic [0:0] last;
    logic [1:0] resp;
} data_st;

// Write response
// This structure is useful for B channel
//
typedef struct packed{
    logic [0:0] valid;
    logic [1:0] resp;
} bresp_st;

// Stream structure
typedef struct packed{
    logic [0:0] valid;
    logic [0:0] last;
    logic [7:0] id;   // set to maximum given by spec sheet
    logic [7:0] user; //hardcoded for by author
    logic [3:0] dest; // set to maximum given by spec sheet
}stream_st;

endpackage


// AXI-4 Memory Mapped Protocol / AXI-4
// Contains 5 channels for communication both 2 device 
// AW channel -- For write address 
// W channel  -- For write data
// B channel  -- For write response
// AR channel -- For read address
// R channel  -- For read data
// Independent channel gives AXI flexibility for duplex communication
//

// Interface for axi memory mapped
// with parameter Address width (AWDT),
//                Data width (DWDT)
//                ID width (IDWDT)
//
interface axi_mm #(
    parameter AWDT = 32,
    parameter DWDT = 64,
    parameter IDWDT = 5
)
(
    input clk,
    input resetn
);
    localparam STRBWDT = DWDT/8;
    
    import axi_pkg ::*;

    // write address
    logic [0:0]         awready;
    logic [AWDT-1:0]    awaddr;
    logic [IDWDT-1:0]   awid;
    addr_st             aw;

    // read address
    logic [0:0]         arready;
    logic [AWDT-1:0]    araddr;
    logic [IDWDT-1:0]   arid;
    addr_st             ar;

    // write data
    logic [0:0]         wready;
    logic [DWDT-1:0]    wdata;
    logic [STRBWDT-1:0] wstrb;
    data_st             w;

    // read data
    logic [DWDT-1 : 0]  rdata;
    logic [0:0]         rready;
    logic [IDWDT-1:0]   rid;
    data_st             r;

    // bresp
    logic [0:0]         bready;
    logic [IDWDT-1:0]   bid;
    bresp_st            b;

    modport slave ( input clk, resetn,
                    input awaddr,aw,awid,araddr,ar,arid,wdata,wstrb,w,bready,rready,
                    output awready,arready,wready,r,rid,rdata,b,bid);
    modport master ( input clk, resetn, 
                    output awaddr,aw,awid,araddr,ar,arid,wdata,wstrb,w,bready,rready,
                    input awready,arready,wready,r,rid,rdata,b,bid);

endinterface


// AXI-4 lite
// Contains 5 channels for communication both 2 device 
// AW channel -- For write address 
// W channel  -- For write data
// B channel  -- For write response
// AR channel -- For read address
// R channel  -- For read data
// Independent channel gives AXI flexibility for duplex communication
// Difference between AXI memory mapped and AXI lite is that
// AXI lite doesn't have burst option i.e. not bulk read and write possible

// Interface for axi lite
// with parameter Address width (AWDT),
//                Data width (DWDT)
//                ID width (IDWDT)
//
interface axi_lite #(
    parameter AWDT = 32,
    parameter DWDT = 64
)
(
    input clk,
    input resetn
);
    localparam STRBWDT = DWDT/8;
    import axi_pkg::*;

    // write address
    logic [0:0]         awvalid;
    logic [0:0]         awready;
    logic [AWDT-1:0]    awaddr;
    logic [2:0]         awprot;

    // read address
    logic [0:0]         arvalid;
    logic [0:0]         arready;
    logic [AWDT-1:0]    araddr;
    logic [2:0]         arprot;

    // write response
    logic [0:0]         bvalid;
    logic [0:0]         bready;
    logic [1:0]         bresp;

    // read data
    logic [0:0]         rready;
    logic [0:0]         rvalid;
    logic [DWDT-1:0]    rdata;
    logic [1:0]         rresp;

    //write data
    logic [0:0]         wready;
    logic [0:0]         wvalid;
    logic [DWDT-1:0]    wdata;
    logic [STRBWDT-1:0] wstrb;

    modport slave  (input  clk, resetn,
                    input  awvalid, awaddr, awprot, arvalid, araddr, arprot, wvalid, wdata, wstrb, rready, bready,
                    output awready, arready, wready, bvalid, bresp, rvalid, rdata, rresp);
    modport master (input  clk, resetn,
                    output awvalid, awaddr, awprot, arvalid, araddr, arprot, wvalid, wdata, wstrb, rready, bready,
                    input  awready, arready, wready, bvalid, bresp, rvalid, rdata, rresp);

endinterface


// AXI Stream 
// Difference between other 2 protocol and this is
// This is uni directional i.e. data flows in one way
// There is no requesting of data and waiting for response
// It is a free flowing architecture only and only when ready is asserted

interface axi_stream #(
    parameter DWDT = 64
)
(
    input clk,
    input resetn
);
    localparam STRBWDT = DWDT/8;
    import axi_pkg::*;

    logic [0:0]         tready;
    logic [DWDT-1:0]    tdata;
    logic [STRBWDT-1:0] tstrb;
    logic [STRBWDT-1:0] tkeep;
    stream_st           t;

    modport slave  (input  clk, resetn,
                    input  t, tdata, tstrb, tkeep,
                    output tready);
    modport master (input  clk, resetn,
                    output t, tdata, tstrb, tkeep,
                    input  tready);

endinterface


// Used to assign the ip ports
package axi_assign;


`define AXI_MM_TIEOFF(if_port)\
    `ifdef SLAVE \
        assign ``if_port``.awready  = '1;\
        assign ``if_port``.arready  = '1;\
        assign ``if_port``.wready   = '1;\
        assign ``if_port``.bid      = '0;\
        assign ``if_port``.b        = '0;\
        assign ``if_port``.r        = '0;\
        assign ``if_port``.rid      = '0;\
        assign ``if_port``.rdata    = '0;\
    `else \
        assign ``if_port``.aw       = '0;\
        assign ``if_port``.awid     = '0;\
        assign ``if_port``.awaddr   = '0;\
        assign ``if_port``.w        = '0;\
        assign ``if_port``.wstrb    = '0;\
        assign ``if_port``.ar       = '0;\
        assign ``if_port``.arid     = '0;\
        assign ``if_port``.araddr   = '0;\
        assign ``if_port``.rready   = '1;\
        assign ``if_port``.bready   = '1;\
    `endif

`define AXI_MM(ip_port,if_port)\
    `ifdef CAP \
        .``ip_port``_AWID      (``if_port``.awid    ),\
        .``ip_port``_AWADDR    (``if_port``.awaddr  ),\
        .``ip_port``_AWLEN     (``if_port``.aw.len  ),\
        .``ip_port``_AWSIZE    (``if_port``.aw.size ),\
        .``ip_port``_AWBURST   (``if_port``.aw.burst),\
        .``ip_port``_AWLOCK    (``if_port``.aw.lock ),\
        .``ip_port``_AWCACHE   (``if_port``.aw.cache),\
        .``ip_port``_AWPROT    (``if_port``.aw.prot ),\
        `ifdef HAS_QOS .``ip_port``_AWQOS(``if_port``.aw.qos),`endif\
        .``ip_port``_AWVALID   (``if_port``.aw.valid),\
        .``ip_port``_AWREADY   (``if_port``.awready ),\
        .``ip_port``_WDATA     (``if_port``.wdata   ),\
        .``ip_port``_WSTRB     (``if_port``.wstrb   ),\
        .``ip_port``_WLAST     (``if_port``.w.last  ),\
        .``ip_port``_WVALID    (``if_port``.w.valid ),\
        .``ip_port``_WREADY    (``if_port``.wready  ),\
        .``ip_port``_BREADY    (``if_port``.bready  ),\
        .``ip_port``_BID       (``if_port``.bid     ),\
        .``ip_port``_BRESP     (``if_port``.b.resp  ),\
        .``ip_port``_BVALID    (``if_port``.b.valid ),\
        .``ip_port``_ARID      (``if_port``.arid    ),\
        .``ip_port``_ARADDR    (``if_port``.araddr  ),\
        .``ip_port``_ARLEN     (``if_port``.ar.len  ),\
        .``ip_port``_ARSIZE    (``if_port``.ar.size ),\
        .``ip_port``_ARBURST   (``if_port``.ar.burst),\
        .``ip_port``_ARLOCK    (``if_port``.ar.lock ),\
        .``ip_port``_ARCACHE   (``if_port``.ar.cache),\
        .``ip_port``_ARPROT    (``if_port``.ar.prot ),\
        `ifdef HAS_QOS .``ip_port``_ARQOS(``if_port``.ar.qos),`endif\
        .``ip_port``_ARVALID   (``if_port``.ar.valid),\
        .``ip_port``_ARREADY   (``if_port``.arready ),\
        .``ip_port``_RREADY    (``if_port``.rready  ),\
        .``ip_port``_RID       (``if_port``.rid     ),\
        .``ip_port``_RDATA     (``if_port``.rdata   ),\
        .``ip_port``_RRESP     (``if_port``.r.resp  ),\
        .``ip_port``_RLAST     (``if_port``.r.last  ),\
        .``ip_port``_RVALID    (``if_port``.r.valid )\
    `else \
        .``ip_port``_araddr    (``if_port``.araddr   ),\
        .``ip_port``_arburst   (``if_port``.ar.burst ),\
        .``ip_port``_arcache   (``if_port``.ar.cache ),\
        .``ip_port``_arid      (``if_port``.arid     ),\
        .``ip_port``_arlen     (``if_port``.ar.len   ),\
        .``ip_port``_arlock    (``if_port``.ar.lock  ),\
        .``ip_port``_arprot    (``if_port``.ar.prot  ),\
        `ifdef HAS_QOS .``ip_port``_arqos(``if_port``.ar.qos),`endif \
        .``ip_port``_arready   (``if_port``.arready  ),\
        .``ip_port``_arsize    (``if_port``.ar.size  ),\
        .``ip_port``_arvalid   (``if_port``.ar.valid ),\
        .``ip_port``_awaddr    (``if_port``.awaddr   ),\
        .``ip_port``_awburst   (``if_port``.aw.burst ),\
        .``ip_port``_awcache   (``if_port``.aw.cache ),\
        .``ip_port``_awid      (``if_port``.awid     ),\
        .``ip_port``_awlen     (``if_port``.aw.len   ),\
        .``ip_port``_awlock    (``if_port``.aw.lock  ),\
        .``ip_port``_awprot    (``if_port``.aw.prot  ),\
        `ifdef HAS_QOS .``ip_port``_awqos(``if_port``.aw.qos),`endif \
        .``ip_port``_awready   (``if_port``.awready  ),\
        .``ip_port``_awsize    (``if_port``.aw.size  ),\
        .``ip_port``_awvalid   (``if_port``.aw.valid ),\
        .``ip_port``_bid       (``if_port``.bid      ),\
        .``ip_port``_bready    (``if_port``.bready   ),\
        .``ip_port``_bresp     (``if_port``.b.resp   ),\
        .``ip_port``_bvalid    (``if_port``.b.valid  ),\
        .``ip_port``_rdata     (``if_port``.rdata    ),\
        .``ip_port``_rid       (``if_port``.rid      ),\
        .``ip_port``_rlast     (``if_port``.r.last   ),\
        .``ip_port``_rready    (``if_port``.rready   ),\
        .``ip_port``_rresp     (``if_port``.r.resp   ),\
        .``ip_port``_rvalid    (``if_port``.r.valid  ),\
        .``ip_port``_wdata     (``if_port``.wdata    ),\
        .``ip_port``_wlast     (``if_port``.w.last   ),\
        .``ip_port``_wready    (``if_port``.wready   ),\
        .``ip_port``_wstrb     (``if_port``.wstrb    ),\
        .``ip_port``_wvalid    (``if_port``.w.valid  )\
    `endif

`define AXI_LITE(ip_port,if_port)\
    `ifdef CAP \
        .``ip_port``_AWADDR       (``if_port``.awaddr ),\
        .``ip_port``_AWPROT       (``if_port``.awprot ),\
        .``ip_port``_AWVALID      (``if_port``.awvalid),\
        .``ip_port``_AWREADY      (``if_port``.awready),\
        .``ip_port``_WDATA        (``if_port``.wdata  ),\
        .``ip_port``_WSTRB        (``if_port``.wstrb  ),\
        .``ip_port``_WVALID       (``if_port``.wvalid ),\
        .``ip_port``_WREADY       (``if_port``.wready ),\
        .``ip_port``_BREADY       (``if_port``.bready ),\
        .``ip_port``_BRESP        (``if_port``.bresp  ),\
        .``ip_port``_BVALID       (``if_port``.bvalid ),\
        .``ip_port``_ARADDR       (``if_port``.araddr ),\
        .``ip_port``_ARPROT       (``if_port``.arprot ),\
        .``ip_port``_ARVALID      (``if_port``.arvalid),\
        .``ip_port``_ARREADY      (``if_port``.arready),\
        .``ip_port``_RREADY       (``if_port``.rready ),\
        .``ip_port``_RDATA        (``if_port``.rdata  ),\
        .``ip_port``_RRESP        (``if_port``.rresp  ),\
        .``ip_port``_RVALID       (``if_port``.rvalid )\
    `else \
        .``ip_port``_araddr       (``if_port``.araddr ),\
        .``ip_port``_arprot       (``if_port``.arprot ),\
        .``ip_port``_arready      (``if_port``.arready),\
        .``ip_port``_arvalid      (``if_port``.arvalid),\
        .``ip_port``_awaddr       (``if_port``.awaddr ),\
        .``ip_port``_awprot       (``if_port``.awprot ),\
        .``ip_port``_awready      (``if_port``.awready),\
        .``ip_port``_awvalid      (``if_port``.awvalid),\
        .``ip_port``_bready       (``if_port``.bready ),\
        .``ip_port``_bresp        (``if_port``.bresp  ),\
        .``ip_port``_bvalid       (``if_port``.bvalid ),\
        .``ip_port``_rdata        (``if_port``.rdata  ),\
        .``ip_port``_rready       (``if_port``.rready ),\
        .``ip_port``_rresp        (``if_port``.rresp  ),\
        .``ip_port``_rvalid       (``if_port``.rvalid ),\
        .``ip_port``_wdata        (``if_port``.wdata  ),\
        .``ip_port``_wready       (``if_port``.wready ),\
        .``ip_port``_wstrb        (``if_port``.wstrb  ),\
        .``ip_port``_wvalid       (``if_port``.wvalid )\
    `endif

`define AXI_STREAM(ip_port,if_port)\
    `ifdef CAP \
        .``ip_port``_TVALID     (``if_port``.t.valid)\
        .``ip_port``_TLAST      (``if_port``.t.last),\
        .``ip_port``_TID        (``if_port``.t.id),\
        .``ip_port``_TUSER      (``if_port``.t.user),\
        .``ip_port``_TDEST      (``if_port``.t.dest),\
        .``ip_port``_TREADY     (``if_port``.tready),\
        .``ip_port``_TDATA      (``if_port``.tdata),\
        .``ip_port``_TSTRB      (``if_port``.tstrb),\
        .``ip_port``_TKEEP      (``if_port``.tkeep)\
    `else \
        .``ip_port``_tvalid     (``if_port``.t.valid)\
        .``ip_port``_tlast      (``if_port``.t.last),\
        .``ip_port``_tid        (``if_port``.t.id),\
        .``ip_port``_tuser      (``if_port``.t.user),\
        .``ip_port``_tdest      (``if_port``.t.dest),\
        .``ip_port``_tready     (``if_port``.tready),\
        .``ip_port``_tdata      (``if_port``.tdata),\
        .``ip_port``_tstrb      (``if_port``.tstrb),\
        .``ip_port``_tkeep      (``if_port``.tkeep)\
    `endif

`define RESP_PORT(ip_port,if_port)\
    .``ip_port``_aw_ready      ( ``if_port``.awready ),\
    .``ip_port``_w_ready       ( ``if_port``.wready  ),\
    .``ip_port``_b_valid       ( ``if_port``.b.valid ),\
    .``ip_port``_b_bits_id     ( ``if_port``.bid     ),\
    .``ip_port``_b_bits_resp   ( ``if_port``.b.resp  ),\
    .``ip_port``_ar_ready      ( ``if_port``.arready ),\
    .``ip_port``_r_valid       ( ``if_port``.r.valid ),\
    .``ip_port``_r_bits_id     ( ``if_port``.rid     ),\
    .``ip_port``_r_bits_data   ( ``if_port``.rdata   ),\
    .``ip_port``_r_bits_resp   ( ``if_port``.r.resp  ),\
    .``ip_port``_r_bits_last   ( ``if_port``.r.last  )

`define REQ_PORT(ip_port,if_port)\
    .``ip_port``_aw_valid      ( ``if_port``.aw.valid ),\
    .``ip_port``_aw_bits_id    ( ``if_port``.awid     ),\
    .``ip_port``_aw_bits_addr  ( ``if_port``.awaddr   ),\
    .``ip_port``_aw_bits_len   ( ``if_port``.aw.len   ),\
    .``ip_port``_aw_bits_size  ( ``if_port``.aw.size  ),\
    .``ip_port``_aw_bits_burst ( ``if_port``.aw.burst ),\
    .``ip_port``_w_valid       ( ``if_port``.w.valid  ),\
    .``ip_port``_w_bits_data   ( ``if_port``.wdata    ),\
    .``ip_port``_w_bits_strb   ( ``if_port``.wstrb    ),\
    .``ip_port``_w_bits_last   ( ``if_port``.w.last   ),\
    .``ip_port``_b_ready       ( ``if_port``.bready   ),\
    .``ip_port``_ar_valid      ( ``if_port``.ar.valid ),\
    .``ip_port``_ar_bits_id    ( ``if_port``.arid     ),\
    .``ip_port``_ar_bits_addr  ( ``if_port``.araddr   ),\
    .``ip_port``_ar_bits_len   ( ``if_port``.ar.len   ),\
    .``ip_port``_ar_bits_size  ( ``if_port``.ar.size  ),\
    .``ip_port``_ar_bits_burst ( ``if_port``.ar.burst ),\
    .``ip_port``_r_ready       ( ``if_port``.rready   )

endpackage
