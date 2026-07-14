
//      +-----------+       +-----------+
//      |           |       |           |
//      |tester     |<=====>|mem        |
//      |           |       |           |
//      |           |       |           |
//      +-----------+       +-----------+

`timescale 1ns/1ps

module top;
    localparam integer MEM_SIZE=1024;
    localparam integer AXI_WIDTH_ADDR=32;
    localparam integer AXI_WIDTH_DATA=32;

    //--------------------------------------------------------------------------
    reg  aclk=1'b0; always #10 aclk <= ~aclk;
    reg  aresetn=1'b0; initial begin #111; aresetn = 1'b1; end
    //--------------------------------------------------------------------------
    wire [AXI_WIDTH_ADDR-1:0] axi_awaddr ;
    wire                      axi_awvalid;
    wire                      axi_awready;
    wire [AXI_WIDTH_DATA-1:0] axi_wdata  ;
    wire                      axi_wvalid ;
    wire                      axi_wready ;
    wire [1:0]                axi_bresp  ;
    wire                      axi_bvalid ;
    wire                      axi_bready ;
    wire [AXI_WIDTH_ADDR-1:0] axi_araddr ;
    wire                      axi_arvalid;
    wire                      axi_arready;
    wire [AXI_WIDTH_DATA-1:0] axi_rdata  ;
    wire [1:0]                axi_rresp  ;
    wire                      axi_rvalid ;
    wire                      axi_rready ;
    //--------------------------------------------------------------------------
    mem_axi_lite #(.MEM_SIZE      (MEM_SIZE      )
                  ,.AXI_WIDTH_ADDR(AXI_WIDTH_ADDR)
                  ,.AXI_WIDTH_DATA(AXI_WIDTH_DATA))
    u_mem_axi_lite (
          .aresetn       ( aresetn     )
        , .aclk          ( aclk        )
        , .s_axi_awaddr  ( axi_awaddr  )
        , .s_axi_awvalid ( axi_awvalid )
        , .s_axi_awready ( axi_awready )
        , .s_axi_wdata   ( axi_wdata   )
        , .s_axi_wvalid  ( axi_wvalid  )
        , .s_axi_wready  ( axi_wready  )
        , .s_axi_bresp   ( axi_bresp   )
        , .s_axi_bvalid  ( axi_bvalid  )
        , .s_axi_bready  ( axi_bready  )
        , .s_axi_araddr  ( axi_araddr  )
        , .s_axi_arvalid ( axi_arvalid )
        , .s_axi_arready ( axi_arready )
        , .s_axi_rdata   ( axi_rdata   )
        , .s_axi_rresp   ( axi_rresp   )
        , .s_axi_rvalid  ( axi_rvalid  )
        , .s_axi_rready  ( axi_rready  )
    );
    //--------------------------------------------------------------------------
    tester #(.MEM_SIZE      (MEM_SIZE      )
            ,.AXI_WIDTH_ADDR(AXI_WIDTH_ADDR)
            ,.AXI_WIDTH_DATA(AXI_WIDTH_DATA))
    u_tester (
          .aresetn            ( aresetn     )
        , .aclk               ( aclk        )
        , .m_axi_lite_awaddr  ( axi_awaddr  )
        , .m_axi_lite_awvalid ( axi_awvalid )
        , .m_axi_lite_awready ( axi_awready )
        , .m_axi_lite_wdata   ( axi_wdata   )
        , .m_axi_lite_wvalid  ( axi_wvalid  )
        , .m_axi_lite_wready  ( axi_wready  )
        , .m_axi_lite_bresp   ( axi_bresp   )
        , .m_axi_lite_bvalid  ( axi_bvalid  )
        , .m_axi_lite_bready  ( axi_bready  )
        , .m_axi_lite_araddr  ( axi_araddr  )
        , .m_axi_lite_arvalid ( axi_arvalid )
        , .m_axi_lite_arready ( axi_arready )
        , .m_axi_lite_rdata   ( axi_rdata   )
        , .m_axi_lite_rresp   ( axi_rresp   )
        , .m_axi_lite_rvalid  ( axi_rvalid  )
        , .m_axi_lite_rready  ( axi_rready  )
    );
    //--------------------------------------------------------------------------
    initial begin
       $dumpfile("wave.vcd");
       $dumpvars(0);
       wait(aresetn==1'b0);
       wait(aresetn==1'b1);
       repeat (5) @ (posedge aclk);
       wait (u_tester.done==1'b1);
       repeat (5) @ (posedge aclk);
       $finish(2);
    end

endmodule
