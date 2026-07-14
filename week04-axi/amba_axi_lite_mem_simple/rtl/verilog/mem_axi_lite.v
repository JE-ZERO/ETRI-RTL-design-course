//
//         +------+        +------+         +-------+
//   AW===>|write |==(A)==>|simple|<==(A)===|read   |<===(AR)
//   W ===>|handle|==(D)==>|dual  |===(D)===|handle |===>(R)
//   B <===|      |--(we)->|port  |<--(re)--|       |
//         |      |        |bram  |         |       |
//         +------+        +------+         +-------+

module mem_axi_lite
     #(parameter integer MEM_SIZE=1024
      ,parameter integer AXI_WIDTH_ADDR=32
      ,parameter integer AXI_WIDTH_DATA=32)
(
      input  wire                      aresetn
    , input  wire                      aclk

    , input  wire [AXI_WIDTH_ADDR-1:0] s_axi_awaddr
    , input  wire                      s_axi_awvalid
    , output wire                      s_axi_awready

    , input  wire [AXI_WIDTH_DATA-1:0] s_axi_wdata
    , input  wire                      s_axi_wvalid
    , output wire                      s_axi_wready

    , output wire [1:0]                s_axi_bresp
    , output wire                      s_axi_bvalid
    , input  wire                      s_axi_bready

    , input  wire [AXI_WIDTH_ADDR-1:0] s_axi_araddr
    , input  wire                      s_axi_arvalid
    , output wire                      s_axi_arready

    , output wire [AXI_WIDTH_DATA-1:0] s_axi_rdata
    , output wire [1:0]                s_axi_rresp
    , output wire                      s_axi_rvalid
    , input  wire                      s_axi_rready
);

    localparam integer BYTE_ADDR_WIDTH = $clog2(AXI_WIDTH_DATA/8);
    localparam integer MEM_DEPTH       = MEM_SIZE/(AXI_WIDTH_DATA/8);
    localparam integer MEM_ADDR_WIDTH  = $clog2(MEM_DEPTH);

    // These are nets because they connect outputs of the handler modules
    // to the BRAM implemented in this parent module.
    wire [MEM_ADDR_WIDTH-1:0]  bram_addr_wr;
    wire [MEM_ADDR_WIDTH-1:0]  bram_addr_rd;
    wire [AXI_WIDTH_DATA-1:0]  bram_data_wr;
    reg  [AXI_WIDTH_DATA-1:0]  bram_data_rd;
    wire                       bram_we;
    wire                       bram_re;

    mem_axi_lite_write_handle #(
          .AXI_WIDTH_ADDR  (AXI_WIDTH_ADDR)
        , .AXI_WIDTH_DATA  (AXI_WIDTH_DATA)
        , .MEM_ADDR_WIDTH  (MEM_ADDR_WIDTH)
        , .BYTE_ADDR_WIDTH (BYTE_ADDR_WIDTH)
    ) u_write_handle (
          .aresetn         (aresetn)
        , .aclk            (aclk)
        , .s_axi_awaddr    (s_axi_awaddr)
        , .s_axi_awvalid   (s_axi_awvalid)
        , .s_axi_awready   (s_axi_awready)
        , .s_axi_wdata     (s_axi_wdata)
        , .s_axi_wvalid    (s_axi_wvalid)
        , .s_axi_wready    (s_axi_wready)
        , .s_axi_bresp     (s_axi_bresp)
        , .s_axi_bvalid    (s_axi_bvalid)
        , .s_axi_bready    (s_axi_bready)
        , .bram_addr       (bram_addr_wr)
        , .bram_data       (bram_data_wr)
        , .bram_we         (bram_we)
    );

    mem_axi_lite_read_handle #(
          .AXI_WIDTH_ADDR  (AXI_WIDTH_ADDR)
        , .AXI_WIDTH_DATA  (AXI_WIDTH_DATA)
        , .MEM_ADDR_WIDTH  (MEM_ADDR_WIDTH)
        , .BYTE_ADDR_WIDTH (BYTE_ADDR_WIDTH)
    ) u_read_handle (
          .aresetn         (aresetn)
        , .aclk            (aclk)
        , .s_axi_araddr    (s_axi_araddr)
        , .s_axi_arvalid   (s_axi_arvalid)
        , .s_axi_arready   (s_axi_arready)
        , .s_axi_rdata     (s_axi_rdata)
        , .s_axi_rresp     (s_axi_rresp)
        , .s_axi_rvalid    (s_axi_rvalid)
        , .s_axi_rready    (s_axi_rready)
        , .bram_addr       (bram_addr_rd)
        , .bram_data       (bram_data_rd)
        , .bram_re         (bram_re)
    );

    // Simple dual-port BRAM: one write port and one synchronous read port.
    (* ram_style = "block" *)
    reg [AXI_WIDTH_DATA-1:0] Mem [0:MEM_DEPTH-1];

    always @(posedge aclk) begin
        if (bram_we)
            Mem[bram_addr_wr] <= bram_data_wr;

        if (bram_re)
            bram_data_rd <= Mem[bram_addr_rd];
    end

endmodule


module mem_axi_lite_write_handle
     #(parameter integer AXI_WIDTH_ADDR=32
      ,parameter integer AXI_WIDTH_DATA=32
      ,parameter integer MEM_ADDR_WIDTH=8
      ,parameter integer BYTE_ADDR_WIDTH=2)
(
      input  wire                      aresetn
    , input  wire                      aclk
    , input  wire [AXI_WIDTH_ADDR-1:0] s_axi_awaddr
    , input  wire                      s_axi_awvalid
    , output reg                       s_axi_awready
    , input  wire [AXI_WIDTH_DATA-1:0] s_axi_wdata
    , input  wire                      s_axi_wvalid
    , output reg                       s_axi_wready
    , output reg  [1:0]                s_axi_bresp
    , output reg                       s_axi_bvalid
    , input  wire                      s_axi_bready
    , output reg  [MEM_ADDR_WIDTH-1:0] bram_addr
    , output reg  [AXI_WIDTH_DATA-1:0] bram_data
    , output reg                       bram_we
);

    localparam [1:0] ST_ADDR = 2'd0;
    localparam [1:0] ST_DATA = 2'd1;
    localparam [1:0] ST_RESP = 2'd2;

    reg [1:0] state;

    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            s_axi_awready <= 1'b0;
            s_axi_wready  <= 1'b0;
      //      s_axi_bresp   <= 2'b00;
            s_axi_bvalid  <= 1'b0;
            bram_addr     <= {MEM_ADDR_WIDTH{1'b0}};
            bram_data     <= {AXI_WIDTH_DATA{1'b0}};
            bram_we       <= 1'b0;
            state         <= ST_ADDR;
        end else begin
            // BRAM write enable is a one-cycle pulse, not a state level.
            bram_we <= 1'b0;

            case (state)
            ST_ADDR: begin
                s_axi_awready <= 1'b1;
                if (s_axi_awvalid && s_axi_awready) begin
                    // AXI uses byte addresses; the BRAM uses word indexes.
                    bram_addr <= s_axi_awaddr[
                        BYTE_ADDR_WIDTH+MEM_ADDR_WIDTH-1:BYTE_ADDR_WIDTH];
                    s_axi_awready <= 1'b0;
                    s_axi_wready  <= 1'b1;
                    state         <= ST_DATA;
                end
            end

            ST_DATA: begin
                if (s_axi_wvalid && s_axi_wready) begin
                    bram_data    <= s_axi_wdata;
                    bram_we      <= 1'b1;
                    s_axi_wready <= 1'b0;
                    s_axi_bresp  <= 2'b00; // OKAY
                    s_axi_bvalid <= 1'b1;
                    state        <= ST_RESP;
                end
            end

            ST_RESP: begin
                // BVALID must stay high until the response handshake.
                if (s_axi_bvalid && s_axi_bready) begin
                    s_axi_bvalid <= 1'b0;
                    state        <= ST_ADDR;
                end
            end

            default: begin
                s_axi_awready <= 1'b0;
                s_axi_wready  <= 1'b0;
                s_axi_bvalid  <= 1'b0;
                state         <= ST_ADDR;
            end
            endcase
        end
    end

endmodule


module mem_axi_lite_read_handle
     #(parameter integer AXI_WIDTH_ADDR=32
      ,parameter integer AXI_WIDTH_DATA=32
      ,parameter integer MEM_ADDR_WIDTH=8
      ,parameter integer BYTE_ADDR_WIDTH=2)
(
      input  wire                      aresetn
    , input  wire                      aclk
    , input  wire [AXI_WIDTH_ADDR-1:0] s_axi_araddr
    , input  wire                      s_axi_arvalid
    , output reg                       s_axi_arready
    , output reg  [AXI_WIDTH_DATA-1:0] s_axi_rdata
    , output reg  [1:0]                s_axi_rresp
    , output reg                       s_axi_rvalid
    , input  wire                      s_axi_rready
    , output wire [MEM_ADDR_WIDTH-1:0] bram_addr
    , input  wire [AXI_WIDTH_DATA-1:0] bram_data
    , output wire                      bram_re
);

    localparam [1:0] ST_ADDR = 2'd0;
    localparam [1:0] ST_WAIT = 2'd1;
    localparam [1:0] ST_RESP = 2'd2;

    reg [1:0] state;

    // The RAM samples these signals on the same edge as the AR handshake.
    assign bram_addr = s_axi_araddr[
        BYTE_ADDR_WIDTH+MEM_ADDR_WIDTH-1:BYTE_ADDR_WIDTH];
    assign bram_re = s_axi_arvalid && s_axi_arready;

    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            s_axi_arready <= 1'b0;
            s_axi_rdata   <= {AXI_WIDTH_DATA{1'b0}};
            s_axi_rresp   <= 2'b00;
            s_axi_rvalid  <= 1'b0;
            state         <= ST_ADDR;
        end else begin
            case (state)
            ST_ADDR: begin
                s_axi_arready <= 1'b1;
                if (s_axi_arvalid && s_axi_arready) begin
                    s_axi_arready <= 1'b0;
                    state         <= ST_WAIT;
                end
            end

            ST_WAIT: begin
                // bram_data now contains the synchronous RAM read result.
                s_axi_rdata  <= bram_data;
                s_axi_rresp  <= 2'b00; // OKAY
                s_axi_rvalid <= 1'b1;
                state        <= ST_RESP;
            end

            ST_RESP: begin
                // RDATA/RRESP/RVALID remain unchanged while RREADY is low.
                if (s_axi_rvalid && s_axi_rready) begin
                    s_axi_rvalid <= 1'b0;
                    state        <= ST_ADDR;
                end
            end

            default: begin
                s_axi_arready <= 1'b0;
                s_axi_rvalid  <= 1'b0;
                state         <= ST_ADDR;
            end
            endcase
        end
    end

endmodule
