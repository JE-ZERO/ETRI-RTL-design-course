//------------------------------------------------------------------------------
//  Copyright (c) 2024 by Ando Ki.
//  All right reserved.
//
// This program is distributed in the hope that it
// will be useful to understand Ando Ki's work,
// BUT WITHOUT ANY WARRANTY.
//------------------------------------------------------------------------------
// uart_core.v
//------------------------------------------------------------------------------
// VERSION = 2024.08.10.
//------------------------------------------------------------------------------
//   RS232-C signal at the end of UART not on the cable.
//   ___    __ __ __ __ __ __ __ ________
//      |  |  |  |  |  |  |  |  |  |  |
//      |  |D0|D1|D2|D3|D4|D5|D6|D7|P |S
//      |__|__|__|__|__|__|__|__|__|__|
//
//  starts by changing 1 to 0.
//  stops by returing to 1.
//------------------------------------------------------------------------------
`include "uart_csr.v"
`include "uart_tx.v"
`include "uart_rx.v"

module uart_core
     #(parameter BAUD_RATE=115_200 
               , CLK_FREQ=100_000_000)
(
      input  wire          reset_n
    , input  wire          clk
    , input  wire  [ 7:0]  addr
    , input  wire          wren
    , input  wire          rden
    , input  wire  [31:0]  wdata
    , output wire  [31:0]  rdata
    , output wire          uart_tx
    , input  wire          uart_rx
    , output wire          uart_irq
);
    //--------------------------------------------------------------------------
    wire [ 7:0] txd    ;
    wire        tx_vld ;// txd is valie
    wire        tx_done;// TX done (single pulse)
    wire [ 7:0] rxd    ;
    wire        rx_perr;
    wire        rx_overrun;
    wire        rx_vld ;// rxd is valid
    wire        rx_done;// RX done (single pulse)
    //--------------------------------------------------------------------------
    wire [15:0] division;// clock division
    wire        width   ;// data width (0:8-bit, 1:7-bit)
    wire        parity  ;// parity enable (0:no-parity)
    wire        even    ;// parity mode if any
    wire        stop    ;// stop bits
    wire        fifo_clr;// rx fifo clear
    //--------------------------------------------------------------------------
    uart_csr #(.BAUD_RATE(BAUD_RATE),.CLK_FREQ(CLK_FREQ))
    u_csr (
          .reset_n    (reset_n   )
        , .clk        (clk       )
        , .addr       (addr      )
        , .wren       (wren      )
        , .rden       (rden      )
        , .wdata      (wdata     )
        , .rdata      (rdata     )
        , .irq        (uart_irq  )
        , .txd        (txd       )
        , .tx_vld     (tx_vld    )
        , .tx_done    (tx_done   )
        , .rxd        (rxd       )
        , .rx_perr    (rx_perr   )
        , .rx_overrun (rx_overrun)
        , .rx_vld     (rx_vld    )
        , .rx_done    (rx_done   )
        , .division   (division  )
        , .width      (width     )
        , .parity     (parity    )
        , .even       (even      )
        , .stop       (stop      )
        , .fifo_clr   (fifo_clr  )
    );
    //--------------------------------------------------------------------------
    uart_tx
    u_tx (
          .reset_n  (reset_n )
        , .clk      (clk     )
        , .uart_tx  (uart_tx )
        , .txd      (txd     )
        , .tx_vld   (tx_vld  )
        , .tx_done  (tx_done )
        , .division (division)
        , .width    (width   )
        , .parity   (parity  )
        , .even     (even    )
        , .stop     (stop    )
    );
    //--------------------------------------------------------------------------
    uart_rx
    u_rx (
          .reset_n   (reset_n   )
        , .clk       (clk       )
        , .uart_rx   (uart_rx   )
        , .rxd       (rxd       )
        , .rx_vld    (rx_vld    )
        , .rx_perr   (rx_perr   )
        , .rx_overrun(rx_overrun)
        , .rx_done   (rx_done   )
        , .division  (division  )
        , .width     (width     )
        , .parity    (parity    )
        , .even      (even      )
        , .stop      (stop      )
        , .fifo_clr  (fifo_clr  )
    );
endmodule
//------------------------------------------------------------------------------
// Revision history
//
// 2024.08.10: Started by Ando Ki (andoki@gmail.com)
//------------------------------------------------------------------------------
