//------------------------------------------------------------------------------
//  Copyright (c) 2024 by Ando Ki.
//  All right reserved.
//
// This program is distributed in the hope that it
// will be useful to understand Ando Ki's work,
// BUT WITHOUT ANY WARRANTY.
//------------------------------------------------------------------------------
// uart_csr.v
//------------------------------------------------------------------------------
// VERSION = 2024.08.10.
//------------------------------------------------------------------------------
// CSR access signals
//              __    __    __    __    __
// clk       __|  |__|  |__|  |__|  |__|  |
//              _____             _____
// addr[..]  XXX_____XXXXXXXXXXXXX_____XXX
//              _____
// rden      __|     |____________________
//                    _____
// rdata[..] XXXXXXXXX_____XXXXXXXXXXXXXXX
//                                _____
// wren      ____________________|     |__
//                                _____
// wdata[..] XXXXXXXXXXXXXXXXXXXXX_____XXX
//------------------------------------------------------------------------------

module uart_csr
     #(parameter BAUD_RATE=115_200 
               , CLK_FREQ =100_000_000
               , VERSION  =32'h2024_0810
               , NAME     ="UART")
(
      input  wire         reset_n
    , input  wire         clk
    , input  wire  [ 7:0] addr
    , input  wire         wren
    , input  wire         rden
    , input  wire  [31:0] wdata
    , output reg   [31:0] rdata
    , output wire         irq
    //--------------------------------------------------------------------------
    , output wire  [ 7:0] txd
    , output wire         tx_vld  // txd is valid
    , input  wire         tx_done // TX done (single pulse)
    , input  wire  [ 7:0] rxd
    , input  wire         rx_perr // parity error
    , input  wire         rx_overrun // RX fifo full
    , input  wire         rx_vld  // rxd is valid
    , output reg          rx_done // RX done (single pulse)
    //--------------------------------------------------------------------------
    , output wire  [15:0] division // clock division
    , output wire         width    // data width
    , output wire         parity   // parity enable
    , output wire         even     // parity mode if any
    , output wire         stop     // stop bits
    , output wire         fifo_clr // rx fifo clear
);
    //--------------------------------------------------------------------------
    // csr address
    localparam CSRA_VERSION = 8'h00
             , CSRA_NAME    = 8'h04
             , CSRA_CONTROL = 8'h10
             , CSRA_STATUS  = 8'h14
             , CSRA_TX      = 8'h18
             , CSRA_RX      = 8'h1C
             , CSRA_CLK_FREQ= 8'h20;
    //---------------------------------------------------
    localparam DIVISION=$rtoi((CLK_FREQ/BAUD_RATE)+0.5);
    reg  [15:0] csr_division=DIVISION;
    reg         csr_width   =1'b0;// 0:8-bit, 1:7-bit
    reg         csr_parity  =1'b0;// 0:no-parity, 1:parity
    reg         csr_even    =1'b0;// 0:odd-parity, 1:even-parity
    reg         csr_stop    =1'b0;// 0:1-bit, 1:2-bit
    reg         csr_ie_tx   =1'b0;
    reg         csr_ie_rx   =1'b0;
    reg         csr_ip_tx   =1'b0; // set when csr_tx got empty
    reg         csr_ip_rx   =1'b0; // set when csr_rx got filled
    reg         csr_fifo_clr=1'b0; // RX fifo clear (auto return to 0)
    //---------------------------------------------------
    reg  [ 7:0] csr_tx      =8'h0;// TX holding register
    reg         csr_tx_vld  =1'b0;
    wire [ 7:0] csr_rx           ;// TX holding register
    wire        csr_rx_perr      ;
    wire        csr_rx_vld       ;
    //---------------------------------------------------
    // csr read
    always @ (posedge clk or negedge reset_n) begin
    if (reset_n==1'b0) begin
        rdata   <= 32'h0;
        rx_done <= 1'b0;
    end else begin
        if (rden==1'b1) begin
            case (addr)
            CSRA_VERSION: rdata <= VERSION;
            CSRA_NAME   : rdata <= NAME;
            CSRA_CONTROL: rdata <= { 9'h0
                                   , csr_fifo_clr // 22
                                   , csr_ie_rx    // 21
                                   , csr_ie_tx    // 20
                                   , csr_stop     // 19
                                   , csr_even     // 18
                                   , csr_parity   // 17
                                   , csr_width    // 16
                                   , csr_division // 15:0
                                   };
            CSRA_STATUS : rdata <= { 27'h0
                                   , csr_rx_perr // 4
                                   , csr_rx_vld  // 3
                                   , csr_tx_vld  // 2
                                   , csr_ip_rx   // 1
                                   , csr_ip_tx   // 0
                                   };
            CSRA_TX     : rdata <= {csr_tx_vld,23'h0,csr_tx};
            CSRA_RX     : begin
                          rdata   <= {csr_rx_vld,csr_rx_perr,22'h0,csr_rx};
                          rx_done <= csr_rx_vld;
                          end
            CSRA_CLK_FREQ: rdata <= CLK_FREQ;
            default      : rdata <= 32'h0;
            endcase
        end
        if (rx_done==1'b1) rx_done <= 1'b0; // in order to make one-cycle pulse
    end // if
    end // always
    //---------------------------------------------------
    // csr write
    always @ (posedge clk or negedge reset_n) begin
    if (reset_n==1'b0) begin
        csr_division <= DIVISION;
        csr_width    <= 1'b0; // 8-bit
        csr_parity   <= 1'b0; // no-parity
        csr_even     <= 1'b0;
        csr_stop     <= 1'b0; // 1-stop
        csr_fifo_clr <= 1'b0; // RX fifo clear
    end else begin
        if (wren==1'b1) begin
            case (addr)
            CSRA_CONTROL: { csr_fifo_clr // 22
                          , csr_ie_rx    // 21
                          , csr_ie_tx    // 20
                          , csr_stop     // 19
                          , csr_even     // 18
                          , csr_parity   // 17
                          , csr_width    // 16
                          , csr_division // 15:0
                          } <= wdata[22:0];
            endcase
        end else begin
            csr_fifo_clr <= 1'b0;
        end
    end // if
    end // always
    //---------------------------------------------------
    // TX
    always @ (posedge clk or negedge reset_n) begin
    if (reset_n==1'b0) begin
        csr_ip_tx   <= 1'b0;
        csr_tx      <= 8'h0; // TX holding register
        csr_tx_vld  <= 1'b0;
    end else begin
        if ((wren==1'b1)&&(addr==CSRA_TX)) begin
            csr_tx     <= wdata[7:0];
            csr_tx_vld <= 1'b1;
        end else if ((wren==1'b1)&&(addr==CSRA_STATUS)) begin
            csr_ip_tx  <= wdata[0];
        end else begin
            if (tx_done) begin
                csr_tx_vld <= 1'b0;
                csr_ip_tx  <= csr_ie_tx;
            end
        end
    end // if
    end // always
    //---------------------------------------------------
    // RX
    always @ (posedge clk or negedge reset_n) begin
    if (reset_n==1'b0) begin
        csr_ip_rx <= 1'b0;
    end else begin
        if ((wren==1'b1)&&(addr==CSRA_STATUS)) begin
            csr_ip_rx  <= wdata[1];
        end else begin
            csr_ip_rx  <= csr_ip_rx | (csr_ie_rx&rx_vld);
        end
    end // if
    end // always
    //---------------------------------------------------
    assign division = csr_division;
    assign width    = csr_width   ;
    assign parity   = csr_parity  ;
    assign even     = csr_even    ;
    assign stop     = csr_stop    ;
    assign fifo_clr = csr_fifo_clr;
    //---------------------------------------------------
    assign irq = (csr_ie_tx&csr_ip_tx)
               | (csr_ie_rx&csr_ip_rx);
    //---------------------------------------------------
    assign txd         = csr_tx    ;
    assign tx_vld      = csr_tx_vld;
    assign csr_rx      = rxd       ;
    assign csr_rx_perr = rx_perr   ;
    assign csr_rx_vld  = rx_vld    ;
    //---------------------------------------------------
endmodule
//------------------------------------------------------------------------------
// Revision history
//
// 2024.08.10: Started by Ando Ki (andoki@gmail.com)
//------------------------------------------------------------------------------
