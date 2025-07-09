// Library ARCv2MSS_v2.1.66.iplib          -- ARCv2MSS-2.1.66
module axi_dummy_slave
                      #(
                         parameter         aw = 12,
                         parameter         dw = 32,
                         parameter         idw = 16
                       )
                       ( input             arvalid,
                         output            arready,
                         input  [aw-1:0]   araddr,
                         input  [1:0]      arburst,
                         input  [2:0]      arsize,
                         input  [idw-1:0]  arid,
                         input  [3:0]      arlen,
                         output            rvalid,
                         input             rready,
                         output [idw-1:0]  rid,
                         output [dw-1:0]   rdata,
                         output [1:0]      rresp,
                         output            rlast,
                         input             awvalid,
                         output            awready,
                         input  [aw-1:0]   awaddr,
                         input  [1:0]      awburst,
                         input  [2:0]      awsize,
                         input  [3:0]      awlen,
                         input  [idw-1:0]  awid,
                         input             wvalid,
                         output            wready,
                         input [dw-1:0]    wdata,
                         input [dw/8-1:0]  wstrb,
                         input             wlast,
                         output            bvalid,
                         input             bready,
                         output [idw-1:0]  bid,
                         output [1:0]      bresp,
                         input             aclk,
                         input             areset_n
                       );

// assign default values to the output signals
   // I_axi_s (axi_slave) signal_prefix='S1_'
   wire  S1_ACLK;
   wire  S1_ARESETn;
   wire [9:0]                                         S1_AWID;
   wire [31:0]                                        S1_AWADDR;
   wire [3:0]                                         S1_AWLEN;
   wire [2:0]                                         S1_AWSIZE;
   wire [1:0]                                         S1_AWBURST;
   wire [1:0]                                         S1_AWLOCK;
   wire [3:0]                                         S1_AWCACHE;
   wire [2:0]                                         S1_AWPROT;
   wire  S1_AWVALID;
   wire  S1_AWREADY;
   wire [9:0]                                         S1_WID;
   wire [63:0]                                        S1_WDATA;
   wire [7:0]                                         S1_WSTRB;
   wire  S1_WLAST;
   wire  S1_WVALID;
   wire  S1_WREADY;
   wire  S1_BREADY;
   wire [9:0]                                         S1_BID;
   wire [1:0]                                         S1_BRESP;
   wire  S1_BVALID;
   wire [9:0]                                         S1_ARID;
   wire [31:0]                                        S1_ARADDR;
   wire [3:0]                                         S1_ARLEN;
   wire [2:0]                                         S1_ARSIZE;
   wire [1:0]                                         S1_ARBURST;
   wire [1:0]                                         S1_ARLOCK;
   wire [3:0]                                         S1_ARCACHE;
   wire [2:0]                                         S1_ARPROT;
   wire  S1_ARVALID;
   wire  S1_ARREADY;
   wire  S1_RREADY;
   wire [9:0]                                         S1_RID;
   wire [63:0]                                        S1_RDATA;
   wire [1:0]                                         S1_RRESP;
   wire  S1_RLAST;
   wire  S1_RVALID;
   wire  S1_CSYSREQ;
   wire  S1_CSYSACK;
   wire  S1_CACTIVE;

   assign       S1_ACLK    = aclk;
   assign       S1_ARESETn = areset_n;
   assign       S1_AWID    = awid;
   assign       S1_AWADDR  = awaddr;
   assign       S1_AWLEN   = awlen;
   assign       S1_AWSIZE  = awsize;
   assign       S1_AWBURST = awburst;
   assign       S1_AWLOCK  = 2'b00;
   assign       S1_AWCACHE = 4'b0000;
   assign       S1_AWPROT  = 3'b000;
   assign       S1_AWVALID = awvalid;
   assign       awready    = S1_AWREADY;
   assign       S1_WID     = awid;
   assign       S1_WDATA   = wdata;
   assign       S1_WSTRB   = wstrb;
   assign       S1_WLAST   = wlast;
   assign       S1_WVALID  = wvalid;
   assign       wready     = S1_WREADY;
   assign       S1_BREADY  = bready;
   assign       bid        = S1_BID;
   assign       bresp      = S1_BRESP;
   assign       bvalid     = S1_BVALID;
   assign       S1_ARID    = arid;
   assign       S1_ARADDR  = {{(32-aw){1'b0}},araddr};
   assign       S1_ARLEN   = arlen;
   assign       S1_ARSIZE  = arsize;
   assign       S1_ARBURST = arburst;
   assign       S1_ARLOCK  = 2'b00;
   assign       S1_ARCACHE = 4'b0000;
   assign       S1_ARPROT  = 3'b000;
   assign       S1_ARVALID = arvalid;
   assign       arready    = S1_ARREADY;
   assign       S1_RREADY  = rready;
   assign       rid        = S1_RID;
   assign       rdata      = S1_RDATA;
   assign       rresp      = S1_RRESP;
   assign       rlast      = S1_RLAST;
   assign       rvalid     = S1_RVALID;
   assign       S1_CSYSREQ = 1'b0;

   axi_slave_xtor #(
    .S1_DATA_WIDTH(dw),
    .S1_ADDR_WIDTH(aw),
    .S1_ID_WIDTH(idw)
   ) I_axi_slave_xtor
     (
      // I_axi_s (axi_slave) signal_prefix='S1_'
      .S1_ACLK                                      (S1_ACLK                                     ),
      .S1_ARESETn                                   (S1_ARESETn                                  ),
      .S1_AWID                                      (S1_AWID                                     ),
      .S1_AWADDR                                    (S1_AWADDR                                   ),
      .S1_AWLEN                                     (S1_AWLEN                                    ),
      .S1_AWSIZE                                    (S1_AWSIZE                                   ),
      .S1_AWBURST                                   (S1_AWBURST                                  ),
      .S1_AWLOCK                                    (S1_AWLOCK                                   ),
      .S1_AWCACHE                                   (S1_AWCACHE                                  ),
      .S1_AWPROT                                    (S1_AWPROT                                   ),
      .S1_AWVALID                                   (S1_AWVALID                                  ),
      .S1_AWREADY                                   (S1_AWREADY                                  ),
      .S1_WID                                       (S1_WID                                      ),
      .S1_WDATA                                     (S1_WDATA                                    ),
      .S1_WSTRB                                     (S1_WSTRB                                    ),
      .S1_WLAST                                     (S1_WLAST                                    ),
      .S1_WVALID                                    (S1_WVALID                                   ),
      .S1_WREADY                                    (S1_WREADY                                   ),
      .S1_BREADY                                    (S1_BREADY                                   ),
      .S1_BID                                       (S1_BID                                      ),
      .S1_BRESP                                     (S1_BRESP                                    ),
      .S1_BVALID                                    (S1_BVALID                                   ),
      .S1_ARID                                      (S1_ARID                                     ),
      .S1_ARADDR                                    (S1_ARADDR                                   ),
      .S1_ARLEN                                     (S1_ARLEN                                    ),
      .S1_ARSIZE                                    (S1_ARSIZE                                   ),
      .S1_ARBURST                                   (S1_ARBURST                                  ),
      .S1_ARLOCK                                    (S1_ARLOCK                                   ),
      .S1_ARCACHE                                   (S1_ARCACHE                                  ),
      .S1_ARPROT                                    (S1_ARPROT                                   ),
      .S1_ARVALID                                   (S1_ARVALID                                  ),
      .S1_ARREADY                                   (S1_ARREADY                                  ),
      .S1_RREADY                                    (S1_RREADY                                   ),
      .S1_RID                                       (S1_RID                                      ),
      .S1_RDATA                                     (S1_RDATA                                    ),
      .S1_RRESP                                     (S1_RRESP                                    ),
      .S1_RLAST                                     (S1_RLAST                                    ),
      .S1_RVALID                                    (S1_RVALID                                   ),
      .S1_CSYSREQ                                   (S1_CSYSREQ                                  ),
      .S1_CSYSACK                                   (S1_CSYSACK                                  ),
      .S1_CACTIVE                                   (S1_CACTIVE                                  )
      );

 endmodule
