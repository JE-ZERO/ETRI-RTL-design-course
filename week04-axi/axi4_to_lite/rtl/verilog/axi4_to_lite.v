//------------------------------------------------------------------------------
//  Copyright (c) 2024 by Future Design Systems.
//  http://www.future-ds.com
//------------------------------------------------------------------------------
// axi4_to_lite.v
//------------------------------------------------------------------------------
// VERSION: 2024.06.16.
//------------------------------------------------------------------------------
// Limitation:
//   AXI and AXI-Lite address and data width should be the same.
//------------------------------------------------------------------------------
// PARAMETERS:
//   AXI_WIDTH_ID  : ID width
//   AXI_WIDTH_ADDR: Address width
//   AXI_WIDTH_DATA: Data width
//   AXI_WIDTH_STRB: Strobe width
//------------------------------------------------------------------------------
`include "axi4_to_lite_fifo_sync.v"

module axi4_to_lite
     #(parameter integer AXI_WIDTH_ID  =2
      ,parameter integer AXI_WIDTH_ADDR=32
      ,parameter integer AXI_WIDTH_DATA=32
      ,parameter integer AXI_WIDTH_STRB=(AXI_WIDTH_DATA/8))
(
    (* X_INTERFACE_PARAMETER = "POLARITY ACTIVE_LOW" *)
    (* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 axi_aresetn RST"  *) input  wire                      axi_aresetn,
    (* X_INTERFACE_PARAMETER = "ASSOCIATED_BUSIF s_axi:m_axil, ASSOCIATED_RESET axi_aresetn" *)
    (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 axi_aclk CLK"     *) input  wire                      axi_aclk,
    (* X_INTERFACE_PARAMETER = "CLK_DOMAIN axi_aclk,RUSER_WIDTH 0,WUSER_WIDTH 0,ARUSER_WIDTH 0,AWUSER_WIDTH 0,\
                                HAS_CACHE 0,HAS_LOCK 0,HAS_PROT 0,HAS_QOS 0,HAS_REGION 0" *)
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi AWID"    *) input  wire [AXI_WIDTH_ID-1:0]   s_axi_awid,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi AWADDR"  *) input  wire [AXI_WIDTH_ADDR-1:0] s_axi_awaddr,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi AWLEN"   *) input  wire [ 7:0]               s_axi_awlen,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi AWSIZE"  *) input  wire [ 2:0]               s_axi_awsize,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi AWBURST" *) input  wire [ 1:0]               s_axi_awburst,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi AWVALID" *) input  wire                      s_axi_awvalid,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi AWREADY" *) output wire                      s_axi_awready,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi WID"     *) input  wire [AXI_WIDTH_ID-1:0]   s_axi_wid,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi WDATA"   *) input  wire [AXI_WIDTH_DATA-1:0] s_axi_wdata,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi WSTRB"   *) input  wire [AXI_WIDTH_STRB-1:0] s_axi_wstrb,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi WLAST"   *) input  wire                      s_axi_wlast,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi WVALID"  *) input  wire                      s_axi_wvalid,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi WREADY"  *) output wire                      s_axi_wready,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi BID"     *) output wire [AXI_WIDTH_ID-1:0]   s_axi_bid,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi BRESP"   *) output wire [ 1:0]               s_axi_bresp,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi BVALID"  *) output wire                      s_axi_bvalid,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi BREADY"  *) input  wire                      s_axi_bready,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi ARID"    *) input  wire [AXI_WIDTH_ID-1:0]   s_axi_arid,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi ARADDR"  *) input  wire [AXI_WIDTH_ADDR-1:0] s_axi_araddr,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi ARLEN"   *) input  wire [ 7:0]               s_axi_arlen,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi ARSIZE"  *) input  wire [ 2:0]               s_axi_arsize,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi ARBURST" *) input  wire [ 1:0]               s_axi_arburst,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi ARVALID" *) input  wire                      s_axi_arvalid,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi ARREADY" *) output wire                      s_axi_arready,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi RID"     *) output wire [AXI_WIDTH_ID-1:0]   s_axi_rid,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi RDATA"   *) output wire [AXI_WIDTH_DATA-1:0] s_axi_rdata,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi RRESP"   *) output wire [ 1:0]               s_axi_rresp,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi RLAST"   *) output wire                      s_axi_rlast,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi RVALID"  *) output wire                      s_axi_rvalid,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi RREADY"  *) input  wire                      s_axi_rready,
    
    (* X_INTERFACE_PARAMETER = "CLK_DOMAIN axi_aclk,RUSER_WIDTH 0,WUSER_WIDTH 0,ARUSER_WIDTH 0,AWUSER_WIDTH 0,\
                                ADDR_WIDTH 32,ID_WIDTH 0,DATA_WIDTH 32,HAS_BURST 0,HAS_CACHE 0,HAS_LOCK 0,\
                                HAS_PROT 0,HAS_QOS 0,HAS_REGION 0,HAS_WSTRB 0,HAS_BRESP 1,HAS_RRESP 1" *)
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axil AWADDR"  *) output wire [31:0] m_axil_awaddr,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axil AWVALID" *) output wire        m_axil_awvalid,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axil AWREADY" *) input  wire        m_axil_awready,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axil WDATA"   *) output wire [31:0] m_axil_wdata,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axil WVALID"  *) output wire        m_axil_wvalid,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axil WREADY"  *) input  wire        m_axil_wready,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axil BRESP"   *) input  wire [ 1:0] m_axil_bresp,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axil BVALID"  *) input  wire        m_axil_bvalid,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axil BREADY"  *) output wire        m_axil_bready,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axil ARADDR"  *) output wire [31:0] m_axil_araddr,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axil ARVALID" *) output wire        m_axil_arvalid,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axil ARREADY" *) input  wire        m_axil_arready,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axil RDATA"   *) input  wire [31:0] m_axil_rdata,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axil RRESP"   *) input  wire [ 1:0] m_axil_rresp,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axil RVALID"  *) input  wire        m_axil_rvalid,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axil RREADY"  *) output wire        m_axil_rready
);
    //--------------------------------------------------------------------------
    axi4_to_lite_write #(.AXI_WIDTH_ID  (AXI_WIDTH_ID  )
                        ,.AXI_WIDTH_ADDR(AXI_WIDTH_ADDR)
                        ,.AXI_WIDTH_DATA(AXI_WIDTH_DATA))
    u_write (
          .axi_aresetn    ( axi_aresetn    )
        , .axi_aclk       ( axi_aclk       )
        , .s_axi_awid     ( s_axi_awid     )
        , .s_axi_awaddr   ( s_axi_awaddr   )
        , .s_axi_awlen    ( s_axi_awlen    )
        , .s_axi_awsize   ( s_axi_awsize   )
        , .s_axi_awburst  ( s_axi_awburst  )
        , .s_axi_awvalid  ( s_axi_awvalid  )
        , .s_axi_awready  ( s_axi_awready  )
        , .s_axi_wid      ( s_axi_wid      )
        , .s_axi_wdata    ( s_axi_wdata    )
        , .s_axi_wstrb    ( s_axi_wstrb    )
        , .s_axi_wlast    ( s_axi_wlast    )
        , .s_axi_wvalid   ( s_axi_wvalid   )
        , .s_axi_wready   ( s_axi_wready   )
        , .s_axi_bid      ( s_axi_bid      )
        , .s_axi_bresp    ( s_axi_bresp    )
        , .s_axi_bvalid   ( s_axi_bvalid   )
        , .s_axi_bready   ( s_axi_bready   )
        , .m_axil_awaddr  ( m_axil_awaddr  )
        , .m_axil_awvalid ( m_axil_awvalid )
        , .m_axil_awready ( m_axil_awready )
        , .m_axil_wdata   ( m_axil_wdata   )
        , .m_axil_wvalid  ( m_axil_wvalid  )
        , .m_axil_wready  ( m_axil_wready  )
        , .m_axil_bresp   ( m_axil_bresp   )
        , .m_axil_bvalid  ( m_axil_bvalid  )
        , .m_axil_bready  ( m_axil_bready  )
    );
    //--------------------------------------------------------------------------
    axi4_to_lite_read #(.AXI_WIDTH_ID  (AXI_WIDTH_ID  )
                       ,.AXI_WIDTH_ADDR(AXI_WIDTH_ADDR)
                       ,.AXI_WIDTH_DATA(AXI_WIDTH_DATA))
    u_read (
          .axi_aresetn    ( axi_aresetn    )
        , .axi_aclk       ( axi_aclk       )
        , .s_axi_arid     ( s_axi_arid     )
        , .s_axi_araddr   ( s_axi_araddr   )
        , .s_axi_arlen    ( s_axi_arlen    )
        , .s_axi_arsize   ( s_axi_arsize   )
        , .s_axi_arburst  ( s_axi_arburst  )
        , .s_axi_arvalid  ( s_axi_arvalid  )
        , .s_axi_arready  ( s_axi_arready  )
        , .s_axi_rid      ( s_axi_rid      )
        , .s_axi_rdata    ( s_axi_rdata    )
        , .s_axi_rresp    ( s_axi_rresp    )
        , .s_axi_rlast    ( s_axi_rlast    )
        , .s_axi_rvalid   ( s_axi_rvalid   )
        , .s_axi_rready   ( s_axi_rready   )
        , .m_axil_araddr  ( m_axil_araddr  )
        , .m_axil_arvalid ( m_axil_arvalid )
        , .m_axil_arready ( m_axil_arready )
        , .m_axil_rdata   ( m_axil_rdata   )
        , .m_axil_rresp   ( m_axil_rresp   )
        , .m_axil_rvalid  ( m_axil_rvalid  )
        , .m_axil_rready  ( m_axil_rready  )
    );
    //--------------------------------------------------------------------------
    // synthesis translate_off
    initial begin
        if (AXI_WIDTH_ADDR!=32) $display("%m ERROR address width not matched.");
        if (AXI_WIDTH_DATA!=32) $display("%m ERROR data width not matched.");
    end
    // synthesis translate_on
    //--------------------------------------------------------------------------
endmodule

//------------------------------------------------------------------------------
//                +----+            +----+
//                |    |            |    |
//                |    |   -+-+-+   |    |
// AXI4 write ===>|    |===>| | |==>|    |<==> AXI-Lite write
//                |    |   -+-+-+   |    |
//                |    |            |    |
//                +----+            +----+
module axi4_to_lite_write
     #(parameter integer AXI_WIDTH_ID  =2
      ,parameter integer AXI_WIDTH_ADDR=32
      ,parameter integer AXI_WIDTH_DATA=32
      ,parameter integer AXI_WIDTH_STRB=(AXI_WIDTH_DATA/8))
(
      input  wire                      axi_aresetn
    , input  wire                      axi_aclk
    , input  wire [AXI_WIDTH_ID-1:0]   s_axi_awid
    , input  wire [AXI_WIDTH_ADDR-1:0] s_axi_awaddr
    , input  wire [ 7:0]               s_axi_awlen
    , input  wire [ 2:0]               s_axi_awsize
    , input  wire [ 1:0]               s_axi_awburst
    , input  wire                      s_axi_awvalid
    , output reg                       s_axi_awready
    , input  wire [AXI_WIDTH_ID-1:0]   s_axi_wid
    , input  wire [AXI_WIDTH_DATA-1:0] s_axi_wdata
    , input  wire [AXI_WIDTH_STRB-1:0] s_axi_wstrb
    , input  wire                      s_axi_wlast
    , input  wire                      s_axi_wvalid
    , output reg                       s_axi_wready
    , output reg  [AXI_WIDTH_ID-1:0]   s_axi_bid
    , output reg  [ 1:0]               s_axi_bresp
    , output reg                       s_axi_bvalid
    , input  wire                      s_axi_bready
    
    , output reg  [31:0] m_axil_awaddr
    , output reg         m_axil_awvalid
    , input  wire        m_axil_awready
    , output reg  [31:0] m_axil_wdata
    , output reg         m_axil_wvalid
    , input  wire        m_axil_wready
    , input  wire [ 1:0] m_axil_bresp
    , input  wire        m_axil_bvalid
    , output reg         m_axil_bready
);
    //--------------------------------------------------------------------------
    reg [AXI_WIDTH_ID-1:0]   regAwid='h0;
    reg [AXI_WIDTH_ADDR-1:0] regAwaddr='h0;
    reg [ 7:0]               regAwlen='h0;
    reg [ 2:0]               regAwsize='h0;
    reg [ 1:0]               regAwburst='h0;
    //--------------------------------------------------------------------------
    reg [ 8:0]               cntWlen='h0;
    //--------------------------------------------------------------------------
    localparam integer FIFO_FDW=AXI_WIDTH_STRB+AXI_WIDTH_DATA;
    localparam integer FIFO_FAW=4;
    reg                 fifo_clr    ;
    wire                fifo_wr_rdy ;
    reg                 fifo_wr_vld ;
    reg  [FIFO_FDW-1:0] fifo_wr_din ;
    reg                 fifo_rd_rdy ;
    wire                fifo_rd_vld ;
    wire [FIFO_FDW-1:0] fifo_rd_dout;
    wire                fifo_full   ;
    wire                fifo_empty  ;
    wire [FIFO_FAW:0]   fifo_items  ;
    wire [FIFO_FAW:0]   fifo_rooms  ;
    //--------------------------------------------------------------------------
    // This FSM pushes data into the FIFO.
    localparam ST_READY    ='h0
             , ST_DATA     ='h1
             , ST_WAIT     ='h2
             , ST_RESP     ='h3;
    reg [1:0] state=ST_READY;
    //--------------------------------------------------------------------------
    // synthesis translate_off
    reg  [8*32-1:0] state_ascii = "ST_READY";
    always @ (state) begin
    case (state)
        ST_READY: state_ascii="ST_READY";
        ST_DATA : state_ascii="ST_DATA ";
        ST_WAIT : state_ascii="ST_WAIT ";
        ST_RESP : state_ascii="ST_RESP ";
        default : state_ascii="ST_UNKNOWN";
    endcase
    end
    // synthesis translate_on
    //--------------------------------------------------------------------------
    always @ ( posedge axi_aclk or negedge axi_aresetn ) begin
    if (axi_aresetn==1'b0) begin
        regAwid    <= 'h0;
        regAwaddr  <= 'h0;
        regAwlen   <= 'h0;
        regAwsize  <= 'h0;
        regAwburst <= 'h0;
        cntWlen    <= 'h0;
        state      <= ST_READY;
    end else begin
        case (state)
        ST_READY: begin
           if (s_axi_awvalid & s_axi_awready) begin
               regAwid    <= s_axi_awid   ;
               regAwaddr  <= s_axi_awaddr ;
               regAwlen   <= s_axi_awlen  ;
               regAwsize  <= s_axi_awsize ;
               regAwburst <= s_axi_awburst;
               cntWlen    <= 'h0;
               state      <= ST_DATA;
               // synthesis translate_off
               if (s_axi_awsize!=get_size(32/8)) $display("%m ERROR partial access.");
               // synthesis translate_on
           end
           end // ST_READY
        ST_DATA: begin
           if (s_axi_wvalid & s_axi_wready) begin
               cntWlen <= cntWlen + 1;
               if (regAwlen==cntWlen) begin
                   state <= ST_WAIT;
                   // synthesis translate_off
                   if (s_axi_wlast==1'b0) $display("%m ERROR WLAST expected.");
                   // synthesis translate_on
               end
               // synthesis translate_off
               else begin
                   if (s_axi_wlast==1'b1) $display("%m ERROR WLAST not expected.");
                end
               // synthesis translate_on
               // synthesis translate_off
               if (s_axi_wid!=regAwid) $display("%m ERROR WID mis-match.");
               if (s_axi_wstrb!={AXI_WIDTH_STRB{1'b1}}) $display("%m ERROR partial write not supported.");
               // synthesis translate_on
           end
           end // ST_DATA
        ST_WAIT: begin
           if (fifo_empty==1'b1) begin
               state <= ST_RESP;
           end
           end // ST_WAIT
        ST_RESP: begin
           if (s_axi_bvalid & s_axi_bready) begin
               state <= ST_READY;
           end
           end // ST_RESP
        default: begin
                 end
        endcase
    end // if
    end // always
    //--------------------------------------------------------------------------
    always @ ( * ) begin
        s_axi_awready  = 1'b0;
        s_axi_wready   = 1'b0;
        s_axi_bid      =  'b0;
        s_axi_bresp    = 2'b0;
        s_axi_bvalid   = 1'b0;
        fifo_wr_vld    = 1'b0;
        fifo_wr_din    = 1'b0;
        case (state)
        ST_READY: begin
                  s_axi_awready = 1'b1;
                  end
        ST_DATA: begin
                 s_axi_wready = fifo_wr_rdy;
                 fifo_wr_vld  = s_axi_wvalid;
                 fifo_wr_din  ={s_axi_wstrb,s_axi_wdata};
                 end
        ST_WAIT: begin
                 end
        ST_RESP: begin
                 s_axi_bid    = regAwid;
                 s_axi_bresp  = 2'b0;
                 s_axi_bvalid = 1'b1;
                 end
        default: begin
                 end
        endcase
    end // always
    //--------------------------------------------------------------------------
    axi4_to_lite_fifo_sync #(.FDW(FIFO_FDW), .FAW(FIFO_FAW))
    u_fifo (
          .rstn    ( axi_aresetn   )
        , .clr     ( fifo_clr      )
        , .clk     ( axi_aclk      )
        , .wr_rdy  ( fifo_wr_rdy   )
        , .wr_vld  ( fifo_wr_vld   )
        , .wr_din  ( fifo_wr_din   )
        , .rd_rdy  ( fifo_rd_rdy   )
        , .rd_vld  ( fifo_rd_vld   )
        , .rd_dout ( fifo_rd_dout  )
        , .full    ( fifo_full     )
        , .empty   ( fifo_empty    )
        , .items   ( fifo_items    )
        , .rooms   ( fifo_rooms    )
    );
    //--------------------------------------------------------------------------
    localparam NUM_DATA=(AXI_WIDTH_DATA/32); // to deal with wide data (not yet)
    //--------------------------------------------------------------------------
    reg [31:0] cntLawaddr='h0;
    reg [ 8:0] cntLawlen='h0;
    reg [ 3:0] cntLdata='h0; // to deal with wide data (not yet)
    //--------------------------------------------------------------------------
    localparam STL_READY    ='h0
             , STL_ADDR     ='h1
             , STL_DATA     ='h2
             , STL_RESP     ='h3
             , STL_WAIT     ='h4;
    reg [2:0] state_lite=STL_READY;
    //--------------------------------------------------------------------------
    // synthesis translate_off
    reg  [8*32-1:0] stateL_ascii = "STL_READY";
    always @ (state_lite) begin
    case (state_lite)
        STL_READY: stateL_ascii="STL_READY";
        STL_ADDR : stateL_ascii="STL_ADDR ";
        STL_DATA : stateL_ascii="STL_DATA ";
        STL_RESP : stateL_ascii="STL_RESP ";
        STL_WAIT : stateL_ascii="STL_WAIT ";
        default  : stateL_ascii="STL_UNKNOWN";
    endcase
    end
    // synthesis translate_on
    //--------------------------------------------------------------------------
    always @ ( posedge axi_aclk or negedge axi_aresetn ) begin
    if (axi_aresetn==1'b0) begin
        cntLawaddr <=  'h0;
        cntLawlen  <=  'h0;
        cntLdata   <=  'h0;
        state_lite <= STL_READY;
    end else begin
        case (state_lite)
        STL_READY: begin
            if ((state==ST_READY)&&(s_axi_awvalid&s_axi_awready)) begin
               cntLawaddr <= s_axi_awaddr[31:0];
               cntLawlen  <= 'h0;
               cntLdata   <= 'h0;
               state_lite <= STL_ADDR;
            end
            end // STL_READY
        STL_ADDR: begin
            if (m_axil_awvalid & m_axil_awready ) begin
                state_lite <= STL_DATA;
            end
            end // STL_ADDR
        STL_DATA: begin
            if (m_axil_wvalid & m_axil_wready ) begin
                cntLawaddr <= get_next_addr(cntLawaddr, regAwsize, regAwburst, regAwlen);
                cntLawlen <= cntLawlen +1;
                if (regAwlen==cntLawlen) begin
                    state_lite <= STL_RESP;
                end
            end
            end // STL_DATA
        STL_RESP: begin
            if (m_axil_bvalid & m_axil_bready ) begin
                state_lite <= STL_WAIT;
                // synthesis translate_off
                if (m_axil_bresp!=2'b00) $display("%m ERROR BRESP not-OK.");
                // synthesis translate_on
            end // STL_WAIT
            end
        STL_WAIT: begin
            if (fifo_empty==1'b1) begin
               state_lite <= STL_READY;
            end
          //// synthesis translate_off
          //if (fifo_empty==1'b0) $display("%m ERROR fifo must be empty.");
          //// synthesis translate_on
            end // STL_WAIT
        default: begin
                 end
        endcase
    end // if
    end // always
    //--------------------------------------------------------------------------
    always @ ( * ) begin
        m_axil_awaddr  =  'h0;
        m_axil_awvalid = 1'b0;
        m_axil_wdata   =  'h0;
        m_axil_wvalid  = 1'b0;
        m_axil_bready  = 1'b0;
        fifo_clr       = 1'b0;
        fifo_rd_rdy    = 1'b0;
        case (state_lite)
        STL_READY: begin
                   end
        STL_ADDR: begin
            m_axil_awaddr  = cntLawaddr;
            m_axil_awvalid = 1'b1;
                  end
        STL_DATA: begin
            fifo_rd_rdy   = m_axil_wready;
            m_axil_wdata  = fifo_rd_dout;
            m_axil_wvalid = fifo_rd_vld;
                  end
        STL_RESP: begin
            m_axil_bready  = 1'b1;
                  end
        STL_WAIT: begin
            fifo_clr = 1'b1;
                  end
        default: begin
                 end
        endcase
    end // always
    //----------------------------------------------------------------
    // input: num of bytes
    // output: AxSIZE[2:0] code
    function [2:0] get_size;
       input [7:0] size;
    begin
       case (size)
         1: get_size = 0;
         2: get_size = 1;
         4: get_size = 2;
         8: get_size = 3;
        16: get_size = 4;
        32: get_size = 5;
        64: get_size = 6;
       128: get_size = 7;
       default: get_size = 0;
       endcase
    end
    endfunction
    //-------------------------------------------------------------------------
    // input: AxSIZE[2:0] code
    // output: num of bytes
    function [7:0] get_bytes;
       input [2:0] size;
    begin
         get_bytes = 1<<size;
    end
    endfunction
    //--------------------------------------------------------------------------
    localparam ADDR_WIDTH=32  // for AXI-Lite
             , DATA_WIDTH=32  // for AXI-Lite
             , DATA_DS=DATA_WIDTH/8
             , DATA_DSB=$clog2(DATA_DS);
    function [ADDR_WIDTH-1:0] get_next_addr;
        input [ADDR_WIDTH-1:0] addr ;
        input [ 2:0]           size ;
        input [ 1:0]           burst; // burst type
        input [ 7:0]           len  ; // burst length
        reg   [ADDR_WIDTH-DATA_DSB-1:0] naddr;
        reg   [ADDR_WIDTH-1:0] mask ;
    begin
         case (burst)
         2'b00: get_next_addr = addr;
         2'b01: begin
                if ((1<<size)<DATA_DS) begin
                   get_next_addr = addr + (1<<size);
                end else begin
                    naddr = addr[ADDR_WIDTH-1:DATA_DSB];
                    naddr = naddr + 1;
                    get_next_addr = {naddr,{DATA_DSB{1'b0}}};
                end
                end
         2'b10: begin
                `ifdef BURST_TYPE_WRAPP_ENABLED
                mask          = get_wrap_mask(size,len);
                get_next_addr = (addr&~mask)
                              | (((addr&mask)+(1<<size))&mask);
                `else
                // synthesis translate_off
                $display("%m ERROR BURST WRAP not supported");
                // synthesis translate_on
                `endif
                end
         2'b11: begin
                get_next_addr = addr;
                // synthesis translate_off
                $display("%m ERROR un-defined BURST %01x", burst);
                // synthesis translate_on
                end
         endcase
    end
    endfunction
    //--------------------------------------------------------------------------
    `ifdef BURST_TYPE_WRAPP_ENABLED
    function [ADDR_WIDTH-1:0] get_wrap_mask;
    input [ 2:0]      size ;
    input [ 7:0]      len  ; // burst length
    begin
         case (size)
         3'b000: get_wrap_mask = (    len)-1;
         3'b001: get_wrap_mask = (  2*len)-1;
         3'b010: get_wrap_mask = (  4*len)-1;
         3'b011: get_wrap_mask = (  8*len)-1;
         3'b100: get_wrap_mask = ( 16*len)-1;
         3'b101: get_wrap_mask = ( 32*len)-1;
         3'b110: get_wrap_mask = ( 64*len)-1;
         3'b111: get_wrap_mask = (128*len)-1;
         endcase
    end
    endfunction
    `endif
    //--------------------------------------------------------------------------
endmodule
//------------------------------------------------------------------------------
//                +----+            +----+
//                |    |            |    |
//                |    |   +-+-+-   |    |
// AXI4 read <===>|    |<==| | |===>|    |<==> AXI-Lite read
//                |    |   +-+-+-   |    |
//                |    |            |    |
//                +----+            +----+
module axi4_to_lite_read
     #(parameter integer AXI_WIDTH_ID  =2
      ,parameter integer AXI_WIDTH_ADDR=32
      ,parameter integer AXI_WIDTH_DATA=32
      ,parameter integer AXI_WIDTH_STRB=(AXI_WIDTH_DATA/8))
(
      input  wire                      axi_aresetn
    , input  wire                      axi_aclk
    , input  wire [AXI_WIDTH_ID-1:0]   s_axi_arid
    , input  wire [AXI_WIDTH_ADDR-1:0] s_axi_araddr
    , input  wire [ 7:0]               s_axi_arlen
    , input  wire [ 2:0]               s_axi_arsize
    , input  wire [ 1:0]               s_axi_arburst
    , input  wire                      s_axi_arvalid
    , output reg                       s_axi_arready
    , output reg  [AXI_WIDTH_ID-1:0]   s_axi_rid
    , output reg  [AXI_WIDTH_DATA-1:0] s_axi_rdata
    , output reg  [ 1:0]               s_axi_rresp
    , output reg                       s_axi_rlast
    , output reg                       s_axi_rvalid
    , input  wire                      s_axi_rready
    
    , output reg  [31:0] m_axil_araddr
    , output reg         m_axil_arvalid
    , input  wire        m_axil_arready
    , input  wire [31:0] m_axil_rdata
    , input  wire [ 1:0] m_axil_rresp
    , input  wire        m_axil_rvalid
    , output reg         m_axil_rready
);
    //--------------------------------------------------------------------------
    reg [AXI_WIDTH_ID-1:0]   regArid='h0;
    reg [AXI_WIDTH_ADDR-1:0] regAraddr='h0;
    reg [ 7:0]               regArlen='h0;
    reg [ 2:0]               regArsize='h0;
    reg [ 1:0]               regArburst='h0;
    //--------------------------------------------------------------------------
    reg [ 8:0]               cntRlen='h0;
    //--------------------------------------------------------------------------
    localparam integer FIFO_FDW=2+32; // rresp, rdata
    localparam integer FIFO_FAW=4;
    reg                 fifo_clr    ;
    wire                fifo_wr_rdy ;
    reg                 fifo_wr_vld ;
    reg  [FIFO_FDW-1:0] fifo_wr_din ;
    reg                 fifo_rd_rdy ;
    wire                fifo_rd_vld ;
    wire [FIFO_FDW-1:0] fifo_rd_dout;
    wire                fifo_full   ;
    wire                fifo_empty  ;
    wire [FIFO_FAW:0]   fifo_items  ;
    wire [FIFO_FAW:0]   fifo_rooms  ;
    //--------------------------------------------------------------------------
    // This FSM pops data from the FIFO.
    localparam ST_READY    ='h0
             , ST_DATA     ='h1
             , ST_WAIT     ='h2;
    reg [1:0] state=ST_READY;
    //--------------------------------------------------------------------------
    // synthesis translate_off
    reg  [8*32-1:0] state_ascii = "ST_READY";
    always @ (state) begin
    case (state)
        ST_READY: state_ascii="ST_READY";
        ST_DATA : state_ascii="ST_DATA ";
        ST_WAIT : state_ascii="ST_WAIT ";
        default : state_ascii="ST_UNKNOWN";
    endcase
    end
    // synthesis translate_on
    //--------------------------------------------------------------------------
    always @ ( posedge axi_aclk or negedge axi_aresetn ) begin
    if (axi_aresetn==1'b0) begin
        regArid    <= 'h0;
        regAraddr  <= 'h0;
        regArlen   <= 'h0;
        regArsize  <= 'h0;
        regArburst <= 'h0;
        cntRlen    <= 'h0;
        state      <= ST_READY;
    end else begin
        case (state)
        ST_READY: begin
           if (s_axi_arvalid & s_axi_arready) begin
               regArid    <= s_axi_arid   ;
               regAraddr  <= s_axi_araddr ;
               regArlen   <= s_axi_arlen  ;
               regArsize  <= s_axi_arsize ;
               regArburst <= s_axi_arburst;
               cntRlen    <= 'h0;
               state      <= ST_DATA;
               // synthesis translate_off
               if (s_axi_arsize!=get_size(32/8)) $display("%m ERROR partial access.");
               // synthesis translate_on
           end
           end // ST_READY
        ST_DATA: begin
           if (s_axi_rvalid & s_axi_rready) begin
               cntRlen <= cntRlen + 1;
               if (regArlen==cntRlen) begin
                   state <= ST_WAIT;
                   // synthesis translate_off
                   if (s_axi_rlast==1'b0) $display("%m ERROR RLAST expected.");
                   // synthesis translate_on
               end
               // synthesis translate_off
               else begin
                   if (s_axi_rlast==1'b1) $display("%m ERROR RLAST not expected.");
                end
               // synthesis translate_on
               // synthesis translate_off
               if (s_axi_rid!=regArid) $display("%m ERROR RID mis-match.");
               if (s_axi_rresp!=2'b00) $display("%m ERROR RRESP not-OK.");
               // synthesis translate_on
           end
           end // ST_DATA
        ST_WAIT: begin
           if (fifo_empty==1'b1) begin
               state <= ST_READY;
           end
           end // ST_WAIT
        default: begin
                 end
        endcase
    end // if
    end // always
    //--------------------------------------------------------------------------
    always @ ( * ) begin
        s_axi_arready = 1'b0;
        s_axi_rid     =  'b0;
        s_axi_rvalid  = 1'b0;
        s_axi_rdata   =  'h0;
        s_axi_rlast   = 1'b0;
        s_axi_rresp   = 2'b0;
        s_axi_rresp   = 2'b0;
        fifo_clr      = 1'b0;
        fifo_rd_rdy   = 1'b0;
        case (state)
        ST_READY: begin
           s_axi_arready = 1'b1;
                  end
        ST_DATA: begin
           s_axi_rid    = regArid     ;
           s_axi_rvalid = fifo_rd_vld ;
          {s_axi_rresp
          ,s_axi_rdata} = fifo_rd_dout;
           s_axi_rlast  = (regArlen==cntRlen);
           fifo_rd_rdy  = s_axi_rready;
                 end
        ST_WAIT: begin
           fifo_clr = 1'b1;
                 end
        default: begin
                 end
        endcase
    end // always
    //--------------------------------------------------------------------------
    axi4_to_lite_fifo_sync #(.FDW(FIFO_FDW), .FAW(FIFO_FAW))
    u_fifo (
          .rstn    ( axi_aresetn   )
        , .clr     ( fifo_clr      )
        , .clk     ( axi_aclk      )
        , .wr_rdy  ( fifo_wr_rdy   )
        , .wr_vld  ( fifo_wr_vld   )
        , .wr_din  ( fifo_wr_din   )
        , .rd_rdy  ( fifo_rd_rdy   )
        , .rd_vld  ( fifo_rd_vld   )
        , .rd_dout ( fifo_rd_dout  )
        , .full    ( fifo_full     )
        , .empty   ( fifo_empty    )
        , .items   ( fifo_items    )
        , .rooms   ( fifo_rooms    )
    );
    //--------------------------------------------------------------------------
    localparam NUM_DATA=(AXI_WIDTH_DATA/32); // to deal with wide data (not yet)
    //--------------------------------------------------------------------------
    reg [31:0] cntLaraddr='h0;
    reg [ 8:0] cntLarlen='h0;
    reg [ 3:0] cntLdata='h0; // to deal with wide data (not yet)
    //--------------------------------------------------------------------------
    localparam STL_READY    ='h0
             , STL_ADDR     ='h1
             , STL_DATA     ='h2
             , STL_WAIT     ='h3;
    reg [1:0] state_lite=STL_READY;
    //--------------------------------------------------------------------------
    // synthesis translate_off
    reg  [8*32-1:0] stateL_ascii = "STL_READY";
    always @ (state_lite) begin
    case (state_lite)
        STL_READY: stateL_ascii="STL_READY";
        STL_ADDR : stateL_ascii="STL_ADDR ";
        STL_DATA : stateL_ascii="STL_DATA ";
        STL_WAIT : stateL_ascii="STL_WAIT ";
        default  : stateL_ascii="STL_UNKNOWN";
    endcase
    end
    // synthesis translate_on
    //--------------------------------------------------------------------------
    always @ ( posedge axi_aclk or negedge axi_aresetn ) begin
    if (axi_aresetn==1'b0) begin
        cntLaraddr <=  'h0;
        cntLarlen  <=  'h0;
        cntLdata   <=  'h0;
        state_lite <= STL_READY;
    end else begin
        case (state_lite)
        STL_READY: begin
            if ((state==ST_READY)&&(s_axi_arvalid&s_axi_arready)) begin
               cntLaraddr <= s_axi_araddr[31:0];
               cntLarlen  <= 'h0;
               cntLdata   <= 'h0;
               state_lite <= STL_ADDR;
            end
            end // STL_READY
        STL_ADDR: begin
            if (m_axil_arvalid & m_axil_arready ) begin
                state_lite <= STL_DATA;
            end
            end // STL_ADDR
        STL_DATA: begin
            if (m_axil_rvalid & m_axil_rready ) begin
                cntLaraddr <= get_next_addr(cntLaraddr, regArsize, regArburst, regArlen);
                cntLarlen <= cntLarlen +1;
                if (regArlen==cntLarlen) begin
                    state_lite <= STL_WAIT;
                end
                // synthesis translate_off
                if (m_axil_rresp!=2'b00) $display("%m ERROR RRESP not-OK.");
                // synthesis translate_on
            end
            end // STL_DATA
        STL_WAIT: begin
            if (fifo_empty==1'b1) begin
               state_lite <= STL_READY;
            end
          //// synthesis translate_off
          //if (fifo_empty==1'b0) $display("%m ERROR fifo must be empty.");
          //// synthesis translate_on
            end // STL_WAIT
        default: begin
                 end
        endcase
    end // if
    end // always
    //--------------------------------------------------------------------------
    always @ ( * ) begin
        m_axil_araddr  =  'h0;
        m_axil_arvalid = 1'b0;
        m_axil_rready  = 1'h0;
        fifo_wr_vld    = 1'b0;
        fifo_wr_din    =  'b0;
        case (state_lite)
        STL_READY: begin
                   end
        STL_ADDR: begin
            m_axil_araddr  = cntLaraddr;
            m_axil_arvalid = 1'b1;
                  end
        STL_DATA: begin
            fifo_wr_vld   = m_axil_rvalid;
            fifo_wr_din   ={m_axil_rresp,m_axil_rdata};
            m_axil_rready = fifo_wr_rdy;
                  end
        STL_WAIT: begin
                  end
        default: begin
                 end
        endcase
    end // always
    //----------------------------------------------------------------
    // input: num of bytes
    // output: AxSIZE[2:0] code
    function [2:0] get_size;
       input [7:0] size;
    begin
       case (size)
         1: get_size = 0;
         2: get_size = 1;
         4: get_size = 2;
         8: get_size = 3;
        16: get_size = 4;
        32: get_size = 5;
        64: get_size = 6;
       128: get_size = 7;
       default: get_size = 0;
       endcase
    end
    endfunction
    //-------------------------------------------------------------------------
    // input: AxSIZE[2:0] code
    // output: num of bytes
    function [7:0] get_bytes;
       input [2:0] size;
    begin
         get_bytes = 1<<size;
    end
    endfunction
    //--------------------------------------------------------------------------
    localparam ADDR_WIDTH=32  // for AXI-Lite
             , DATA_WIDTH=32  // for AXI-Lite
             , DATA_DS=DATA_WIDTH/8
             , DATA_DSB=$clog2(DATA_DS);
    function [ADDR_WIDTH-1:0] get_next_addr;
        input [ADDR_WIDTH-1:0] addr ;
        input [ 2:0]           size ;
        input [ 1:0]           burst; // burst type
        input [ 7:0]           len  ; // burst length
        reg   [ADDR_WIDTH-DATA_DSB-1:0] naddr;
        reg   [ADDR_WIDTH-1:0] mask ;
    begin
         case (burst)
         2'b00: get_next_addr = addr;
         2'b01: begin
                if ((1<<size)<DATA_DS) begin
                   get_next_addr = addr + (1<<size);
                end else begin
                    naddr = addr[ADDR_WIDTH-1:DATA_DSB];
                    naddr = naddr + 1;
                    get_next_addr = {naddr,{DATA_DSB{1'b0}}};
                end
                end
         2'b10: begin
                `ifdef BURST_TYPE_WRAPP_ENABLED
                mask          = get_wrap_mask(size,len);
                get_next_addr = (addr&~mask)
                              | (((addr&mask)+(1<<size))&mask);
                `else
                // synthesis translate_off
                $display("%m ERROR BURST WRAP not supported");
                // synthesis translate_on
                `endif
                end
         2'b11: begin
                get_next_addr = addr;
                // synthesis translate_off
                $display("%m ERROR un-defined BURST %01x", burst);
                // synthesis translate_on
                end
         endcase
    end
    endfunction
    //--------------------------------------------------------------------------
    `ifdef BURST_TYPE_WRAPP_ENABLED
    function [ADDR_WIDTH-1:0] get_wrap_mask;
    input [ 2:0]      size ;
    input [ 7:0]      len  ; // burst length
    begin
         case (size)
         3'b000: get_wrap_mask = (    len)-1;
         3'b001: get_wrap_mask = (  2*len)-1;
         3'b010: get_wrap_mask = (  4*len)-1;
         3'b011: get_wrap_mask = (  8*len)-1;
         3'b100: get_wrap_mask = ( 16*len)-1;
         3'b101: get_wrap_mask = ( 32*len)-1;
         3'b110: get_wrap_mask = ( 64*len)-1;
         3'b111: get_wrap_mask = (128*len)-1;
         endcase
    end
    endfunction
    `endif
endmodule
//------------------------------------------------------------------------------
// Revision History
//
// 2024.06.16: Started by Ando Ki (adki@future-ds.com)
//------------------------------------------------------------------------------
