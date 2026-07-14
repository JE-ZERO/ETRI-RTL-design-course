//------------------------------------------------------------------------------
//  Copyright (c) 2024 by Ando Ki.
//  All right reserved.
//
// This program is distributed in the hope that it
// will be useful to understand Ando Ki's work,
// BUT WITHOUT ANY WARRANTY.
//------------------------------------------------------------------------------
// uart_tx.v
//------------------------------------------------------------------------------
// VERSION = 2024.08.10.
//------------------------------------------------------------------------------

module uart_tx
(
      input  wire         reset_n
    , input  wire         clk
    , output reg          uart_tx // serial data
    //--------------------------------------------------------------------------
    , input  wire  [ 7:0] txd
    , input  wire         tx_vld  // txd is valie
    , output reg          tx_done // TX done (single pulse)
    //--------------------------------------------------------------------------
    , input  wire  [15:0] division // clock division
    , input  wire         width    // data width (0: 8-bit, 1: 7-bit)
    , input  wire         parity   // parity enable (0: dis, 1: enable)
    , input  wire         even     // parity mode if any (0:odd, 1:even)
    , input  wire         stop     // stop bits (0: 1-bit, 1: 2-bit)
);
    //--------------------------------------------------------------------------
    reg [15:0] cnt=16'h1;
    reg        cnt_clr=1'b0;
    //--------------------------------------------------------------------------
    reg [ 3:0] num_bit =4'h0; // num of bits has been sent
    reg        epbit   =1'b0; // even prity (make even num inclusive)
    reg [ 7:0] txd_reg =8'h0; // data holding
    reg [15:0] division_reg='h10; // clock division
    reg [ 3:0] width_reg   =4'h8;// bit-width
    reg        parity_reg  ='b0;// parity enable
    reg        even_reg    ='b0;// parity mode if any
    reg        stop_reg    ='b0;// stop bits
    //--------------------------------------------------------------------------
    always @ (posedge clk or negedge reset_n) begin
    if (reset_n==1'b0) begin
        cnt <= 16'h1;
    end else if (cnt_clr==1'b1) begin
        cnt <= 16'h2; // be careful
    end else begin
        if (cnt>=division_reg) cnt <= 8'h1;
        else                   cnt <= cnt + 1;
    end // if
    end // always
    //--------------------------------------------------------------------------
    localparam ST_READY = 'h0
             , ST_START = 'h1
             , ST_DATA  = 'h2
             , ST_PARITY= 'h3
             , ST_STOP  = 'h4
             , ST_WAIT  = 'h5;
    (* mark_debug="true" *)
    reg [2:0] state=ST_READY; // synthesis attribute keep of state is "true";
    //--------------------------------------------------------------------------
    always @ (posedge clk or negedge reset_n) begin
    if (reset_n==1'b0) begin
        tx_done      <= 1'b0;
        uart_tx      <= 1'b1;
        txd_reg      <= 8'h0;
        stop_reg     <= 1'b0;
        division_reg <= division;
        width_reg    <= 4'h8;// data width
        parity_reg   <= 'b0;// parity enable
        even_reg     <= 'b0;// parity mode if any
        stop_reg     <= 'b0;// stop bits
        cnt_clr      <= 1'b0;
        num_bit      <= 4'h0;
        epbit        <= 1'b0;
        state        <= ST_READY;
    end else begin
        case (state)
        ST_READY: begin
           if (tx_vld) begin
               txd_reg      <= txd ;
               epbit        <= 1'b0;
               division_reg <= division;
               width_reg    <= (width) ? 4'h7 : 4'h8;
               parity_reg   <= parity  ;// parity enable
               even_reg     <= even    ;// parity mode if any
               stop_reg     <= stop    ;// stop bits
               uart_tx      <= 1'b0;
               cnt_clr      <= 1'b0;
               state        <= ST_START;
           end else begin
               cnt_clr  <= 1'b1;
               uart_tx  <= 1'b1;
           end
           end // ST_READY
        ST_START: begin
           if (cnt>=division_reg) begin
               uart_tx  <= txd_reg[0];
               epbit    <= epbit^txd_reg[0];
               txd_reg  <= {1'b0,txd_reg[7:1]};
               cnt_clr  <= 1'b1;
               num_bit  <= 4'h1;
               state    <= ST_DATA;
           end else begin
               cnt_clr <= 1'b0;
           end
           end // ST_START
        ST_DATA: begin
           if (cnt>=division_reg) begin
               if (num_bit==width_reg) begin
                   if (parity_reg) begin
                      uart_tx <= (even_reg) ? epbit : ~epbit ;
                      cnt_clr <= 1'b1;
                      state   <= ST_PARITY;
                   end else begin
                      uart_tx <= 1'b1;
                      cnt_clr <= 1'b1;
                      state   <= ST_STOP;
                   end
               end else begin
                   uart_tx  <= txd_reg[0];
                   epbit    <= epbit^txd_reg[0];
                   txd_reg  <= {1'b0,txd_reg[7:1]};
                   cnt_clr  <= 1'b1;
                   num_bit  <= num_bit + 1;
               end
           end else begin
               cnt_clr <= 1'b0;
           end
           end // ST_DATA
        ST_PARITY: begin
           if (cnt>=division_reg) begin
               uart_tx <= 1'b1;
               cnt_clr <= 1'b1;
               state   <= ST_STOP;
           end else begin
               cnt_clr <= 1'b0;
           end
           end // ST_PARITY
        ST_STOP: begin
           if (cnt>=division_reg) begin
               cnt_clr <= 1'b1;
               if (stop_reg) begin
                   stop_reg <= 1'b0;
               end else begin
                   tx_done <= 1'b1;
                   state   <= ST_WAIT;
               end
           end else begin
               cnt_clr <= 1'b0;
           end
           end // ST_STOP
        ST_WAIT: begin
           cnt_clr <= 1'b0;
           if (tx_vld==1'b0) begin
               tx_done <= 1'b0;
               state   <= ST_READY;
           end
           end // ST_WAIT
        default: begin
           uart_tx <= 1'b1;
           state   <= ST_READY;
           end
        endcase
    end // if
    end // always
    //-------------------------------------------------------------------------
    // synthesis translate_off
    reg  [8*10-1:0] state_ascii = "READY";
    always @ (state) begin
    case (state)
        ST_READY : state_ascii="READY ";
        ST_START : state_ascii="START ";
        ST_DATA  : state_ascii="DATA  ";
        ST_PARITY: state_ascii="PARITY";
        ST_STOP  : state_ascii="STOP  ";
        ST_WAIT  : state_ascii="WAIT  ";
        default  : state_ascii="ERROR ";
    endcase
    end
    // synthesis translate_on
endmodule
//------------------------------------------------------------------------------
// Revision history
//
// 2024.08.10: Started by Ando Ki (andoki@gmail.com)
//------------------------------------------------------------------------------
