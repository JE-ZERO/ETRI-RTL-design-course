//------------------------------------------------------------------------------
// Copyright (c) 2024 by Ando Ki.
//------------------------------------------------------------------------------
// tester.v
//------------------------------------------------------------------------------
`timescale 1ns/1ps

module tester
     #(parameter ACLK_FREQ=50_000_000)
(
      input  wire        aresetn
    , input  wire        aclk
    , output reg  [31:0] m_axi_lite_awaddr
    , output reg         m_axi_lite_awvalid
    , input  wire        m_axi_lite_awready
    , output reg  [31:0] m_axi_lite_wdata
    , output reg         m_axi_lite_wvalid
    , input  wire        m_axi_lite_wready
    , input  wire [ 1:0] m_axi_lite_bresp
    , input  wire        m_axi_lite_bvalid
    , output reg         m_axi_lite_bready
    , output reg  [31:0] m_axi_lite_araddr
    , output reg         m_axi_lite_arvalid
    , input  wire        m_axi_lite_arready
    , input  wire [31:0] m_axi_lite_rdata
    , input  wire [ 1:0] m_axi_lite_rresp
    , input  wire        m_axi_lite_rvalid
    , output reg         m_axi_lite_rready
    , input  wire        uart_rx
    , output reg         uart_tx
    , input  wire        interrupt
);
    //--------------------------------------------------------------------------
    `include "tasks_axi_lite.sv"
    `include "tasks_uart_axi_lite.sv"
    `include "tasks_tty.sv"
    //--------------------------------------------------------------------------
    initial begin
        m_axi_lite_awaddr  <=  'h0;
        m_axi_lite_awvalid <= 1'b0;
        m_axi_lite_wdata   <=  'h0;
        m_axi_lite_wvalid  <= 1'b0;
        m_axi_lite_bready  <= 1'b0;
        m_axi_lite_araddr  <=  'h0;
        m_axi_lite_arvalid <= 1'b0;
        m_axi_lite_rready  <= 1'b0;
        uart_tx            <= 1'b0;
        wait (aresetn==1'b0);
        wait (aresetn==1'b1);
        repeat (10) @ (posedge aclk);
        uart_csr();
        repeat (10) @ (posedge aclk);
        test_hello_world( 115200// baud rate
                        , 0     // parity, 0:no, 1:odd, 2:even
                        , 1     // stop, 0:no, 1:1-bit, 2:2-bit
                        );
        test_hello_world( 19200 // baud rate
                        , 2     // parity, 0:no, 1:odd, 2:even
                        , 2     // stop, 0:no, 1:1-bit, 2:2-bit
                        );
        test_hello_world( 9600  // baud rate
                        , 1     // parity, 0:no, 1:odd, 2:even
                        , 1     // stop, 0:no, 1:1-bit, 2:2-bit
                        );
        repeat (20) @ (posedge aclk);
        $finish(2);
    end
    //--------------------------------------------------------------------------
    task test_hello_world;
        input integer baud  ; // baud rate
        input integer parity; // 0:no, 1:odd, 2:even
        input integer stop  ; // 0:no, 1:1-bit, 2:2-bit

        string msg;
        integer msg_len;
        reg [7:0] buff[];
    begin
        uart_init( ACLK_FREQ //freq  ; // freq of 'PCLK'
                 , baud      // baud rate
                 , 8         // width
                 , parity
                 , stop);
        msg = "Hello world!";
        msg_len = msg.len();
        buff = new[msg_len];
        fork for (int idx=0; idx<msg_len; idx=idx+1) begin
                 uart_put_char(msg[idx], 1);
             end
             tty_receive( buff
                        , msg_len
                        , baud
                        , 8      // width // 8 or 7
                        , parity // 0:no, 1:odd, 2:even
                        , stop   // 0:no, 1:1-bit, 2:2-bit
                        );
        join
        for (int idx=0; idx<msg_len; idx=idx+1) begin
            $write("%c", buff[idx]);
        end
        $write("\n");
        buff.delete();
    end
    endtask
    //--------------------------------------------------------------------------
endmodule
//------------------------------------------------------------------------------
// Revision History
//
// 2024.08.10: Started by Ando Ki (andoki@gmail.com)
//------------------------------------------------------------------------------
