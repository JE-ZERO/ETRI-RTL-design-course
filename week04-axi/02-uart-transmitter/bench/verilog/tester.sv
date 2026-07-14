`timescale 1ns/1ps

module tester
     #(parameter integer MEM_SIZE=1024
      ,parameter integer AXI_WIDTH_ADDR=32
      ,parameter integer AXI_WIDTH_DATA=32)
(
      input  wire                      aresetn
    , input  wire                      aclk

    , output reg  [AXI_WIDTH_ADDR-1:0] m_axi_lite_awaddr
    , output reg                       m_axi_lite_awvalid
    , input  wire                      m_axi_lite_awready

    , output reg  [AXI_WIDTH_DATA-1:0] m_axi_lite_wdata
    , output reg                       m_axi_lite_wvalid
    , input  wire                      m_axi_lite_wready

    , input  wire [1:0]                m_axi_lite_bresp
    , input  wire                      m_axi_lite_bvalid
    , output reg                       m_axi_lite_bready

    , output reg  [AXI_WIDTH_ADDR-1:0] m_axi_lite_araddr
    , output reg                       m_axi_lite_arvalid
    , input  wire                      m_axi_lite_arready

    , input  wire [AXI_WIDTH_DATA-1:0] m_axi_lite_rdata
    , input  wire [1:0]                m_axi_lite_rresp
    , input  wire                      m_axi_lite_rvalid
    , output reg                       m_axi_lite_rready
);
    //--------------------------------------------------------------------------
    `include "tasks_axi_lite.sv"
    //--------------------------------------------------------------------------
    reg done;
    integer addr_start, addr_end;
    integer size;
    //--------------------------------------------------------------------------
    initial begin
        done = 1'b0;
        m_axi_lite_awaddr   <= 'h0;
        m_axi_lite_awvalid  <= 'h0;
        m_axi_lite_wdata    <= 'h0;
        m_axi_lite_wvalid   <= 'h0;
        m_axi_lite_bready   <= 'h0;
        m_axi_lite_araddr   <= 'h0;
        m_axi_lite_arvalid  <= 'h0;
        m_axi_lite_rready   <= 'h0;
        wait (aresetn==1'b0);
        wait (aresetn==1'b1);
        repeat (5) @ (posedge aclk);
        addr_start = 32'h0000_1000; // inclusive
        addr_end   = 32'h0000_1100; // exclusive
        size = 4;
        mem_test(addr_start, addr_end, size);
        repeat (5) @ (posedge aclk);
        done = 1'b1;
    end
    //--------------------------------------------------------------------------
    task mem_test;
         input integer addr_start;
         input integer addr_end; // exclusive
         input integer size;

         reg [AXI_WIDTH_DATA-1:0] dataW, dataR;
         integer addr, error;
    begin
         // read-after-write
         error = 0;
         for (addr=addr_start; (addr+size)<=addr_end; addr=addr+size) begin
              dataW = addr+1;
              axi_lite_write(addr, dataW);
              axi_lite_read (addr, dataR);
              if (dataR!=dataW) begin
                  error = error + 1;
                  $display("%t %m A=0x%08X D=0x%08X, but %08X expected.",
                            $time, addr, dataR, dataW);
              end
         end // for (addr
         if (error==0) $display("%m OK for RAW for %d-bytes", addr_end-addr_start);
         else          $display("%m Mis-match for RAW %d", error);
         // read-all-after-write-all
    end
    endtask
    //--------------------------------------------------------------------------
endmodule
