//------------------------------------------------------------------------------
//  Copyright (c) 2024 by Ando Ki.
//  All right reserved.
//
// This program is distributed in the hope that it
// will be useful to understand Ando Ki's work,
// BUT WITHOUT ANY WARRANTY.
//------------------------------------------------------------------------------
// uart_rx.v
//------------------------------------------------------------------------------
// VERSION = 2024.08.10.
//------------------------------------------------------------------------------
`include "uart_fifo_sync_wt.v"

module uart_rx
(
      input  wire         reset_n
    , input  wire         clk
    , input  wire         uart_rx // serial data
    //--------------------------------------------------------------------------
    , output wire  [ 7:0] rxd
    , output wire         rx_vld  // rxd is valie
    , output wire         rx_perr // parity error when 1
    , input  wire         rx_done // RX done (single pulse)
    , output wire         rx_overrun // RX fifo full
    //--------------------------------------------------------------------------
    , input  wire  [15:0] division // clock division
    , input  wire         width    // data width
    , input  wire         parity   // parity enable
    , input  wire         even     // parity mode if any
    , input  wire         stop     // stop bits
    , input  wire         fifo_clr
);
    //--------------------------------------------------------------------------
    reg uart_rx_reg     =1'b1; // delay version of sync
    reg uart_rx_sync    =1'b1;
    reg uart_rx_sync_dly=1'b1;
    //--------------------------------------------------------------------------
    always @ (posedge clk or negedge reset_n) begin
    if (reset_n==1'b0) begin
        uart_rx_reg      <= 1'b1;
        uart_rx_sync     <= 1'b1;
        uart_rx_sync_dly <= 1'b1;
    end else begin
        uart_rx_reg      <= uart_rx;
        uart_rx_sync     <= uart_rx_reg;
        uart_rx_sync_dly <= uart_rx_sync;
    end
    end // always
    //--------------------------------------------------------------------------
    reg  [ 3:0] num_bit =4'h0; // num of bits has been received
    reg         epbit   =1'b0; // even prity (make even num inclusive)
    reg  [ 7:0] rxd_reg     = 8'h0;
    reg         rx_perr_reg = 1'b0;
    //--------------------------------------------------------------------------
    // registers to get stable while receiving input
    reg         stop_reg    =1'b0;
    reg         even_reg    =1'b0;
    reg         parity_reg  =1'b0;
    reg  [ 3:0] width_reg   =4'h8;
    reg  [15:0] division_reg='h10;
    wire [15:0] division_half={1'b0,division_reg[15:1]};
    //--------------------------------------------------------------------------
    reg [15:0] cnt=16'h1;
    wire       cnt_clr = uart_rx_sync^uart_rx_sync_dly;
    always @ (posedge clk or negedge reset_n) begin
    if (reset_n==1'b0) begin
        cnt <= 16'h1;
    end else if (cnt_clr==1'b1) begin
        cnt <= 16'h2; // be careful
    end else begin
        if (cnt>=division_reg) cnt <= 16'h1;
        else                   cnt <= cnt + 1;
    end // if
    end // always
    //--------------------------------------------------------------------------
    wire        fifo_wr_rdy;
    reg         fifo_wr_vld=1'b0;
    reg  [ 8:0] fifo_wr_dat='h0;
    wire        fifo_rd_rdy;
    wire        fifo_rd_vld;
    wire [ 8:0] fifo_rd_dat;
    wire        fifo_full  ;
    wire        fifo_empty ;
    //--------------------------------------------------------------------------
    assign rxd         = (fifo_rd_vld) ? fifo_rd_dat[7:0] : 8'h0;
    assign rx_perr     = (fifo_rd_vld) ? fifo_rd_dat[8] : 1'b0;
    assign rx_overrun  = fifo_full;
    assign rx_vld      = fifo_rd_vld;
    assign fifo_rd_rdy = rx_done|fifo_full; // in order to remove first when full.
    //--------------------------------------------------------------------------
    localparam ST_READY = 'h0
             , ST_START = 'h1
             , ST_DATA  = 'h2
             , ST_PARITY= 'h3
             , ST_STOP  = 'h4
             , ST_END   = 'h5
             , ST_WAIT  = 'h6;
    (* mark_debug="true" *)
    reg [2:0] state=ST_READY; // synthesis attribute keep of state is "true";
    //--------------------------------------------------------------------------
    always @ (posedge clk or negedge reset_n) begin
    if (reset_n==1'b0) begin
        epbit        <= 1'b0;
        num_bit      <= 4'h0; // num of bits has been received
        rxd_reg      <= 8'h0;
        rx_perr_reg  <= 1'b0;
        division_reg <= division;
        stop_reg     <= 1'b0;
        even_reg     <= 1'b0;
        parity_reg   <= 1'b0;
        width_reg    <= 4'h8;
        fifo_wr_vld  <= 1'b0;
        fifo_wr_dat  <=  'h0;
        state        <= ST_READY;
    end else begin
        case (state)
        ST_READY: begin
           if ((uart_rx_sync==1'b0)&&(cnt_clr==1'b1)) begin
               // start condition
               rxd_reg      <= 8'h0    ;
               division_reg <= division;
               width_reg    <= (width) ? 4'h7 : 4'h8;
               parity_reg   <= parity  ;
               even_reg     <= even    ;
               stop_reg     <= stop    ;
               fifo_wr_vld  <= 1'b0    ;
               fifo_wr_dat  <=  'h0    ;
               state        <= ST_START;
           end
           end // ST_READY
        ST_START: begin
           if (cnt==division_half) begin
               epbit   <= 1'b0;
               num_bit <= 4'h1; // num of bits has been received
               state   <= ST_DATA;
           end
           end // ST_START
        ST_DATA: begin
           if (cnt==division_half) begin
               // note that LSbit first-in
               rxd_reg <= {uart_rx_sync,rxd_reg[7:1]};
               epbit   <= epbit ^ uart_rx_sync;
               if (num_bit==width_reg) begin
                   if (parity_reg) begin
                       state <= ST_PARITY;
                   end else begin
                       rx_perr_reg <= 1'b0;
                       state       <= ST_STOP;
                   end
               end else begin
                   num_bit <= num_bit + 1;
               end
           end
           end // ST_START
        ST_PARITY: begin
           if (cnt==division_half) begin
               rx_perr_reg <= (even_reg) ? epbit^uart_rx_sync
                                         : epbit~^uart_rx_sync;
               state   <= ST_STOP;
           end
           end // ST_PARITY
        ST_STOP: begin
           if (cnt==division_half) begin
               if (stop_reg) begin
                   stop_reg <= 1'b0;
               end else begin
                   state    <= ST_END;
               end
           end
           end // ST_STOP
        ST_END: begin
           if (width_reg==8) fifo_wr_dat <= {rx_perr_reg,rxd_reg};
           else              fifo_wr_dat <= {rx_perr_reg,1'b0,rxd_reg[7:1]};
           fifo_wr_vld <= 1'b1;
           state       <= ST_WAIT;
           end // ST_END
        ST_WAIT: begin
           fifo_wr_vld <= 1'b0;
           state       <= ST_WAIT;
           state       <= ST_READY;
           end // ST_WAIT
        default: begin
           fifo_wr_vld <= 1'b0;
           state       <= ST_READY;
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
        ST_END   : state_ascii="END   ";
        ST_WAIT  : state_ascii="WAIT  ";
        default  : state_ascii="ERROR ";
    endcase
    end
    // synthesis translate_on
    //--------------------------------------------------------------------------
    // It will automatically pop the oldest one, when full occurs
    // by assining 'fifo_full' to 'fifo_rd_rdy'.
    // see 'fifo_rd_rdy' above.
    uart_fifo_sync_wt #(.FDW (8+1)// fifof data width (perr+data)
                       ,.FAW (3)) // num of entries in 2 to the power FAW
    u_fifo (
        .rstn    (reset_n     )
      , .clr     (fifo_clr    )
      , .clk     (clk         )
      , .wr_rdy  (fifo_wr_rdy )
      , .wr_vld  (fifo_wr_vld )
      , .wr_din  (fifo_wr_dat )
      , .rd_rdy  (fifo_rd_rdy )
      , .rd_vld  (fifo_rd_vld )
      , .rd_dout (fifo_rd_dat )
      , .full    (fifo_full   )
      , .empty   (fifo_empty  )
      , .items   ()
      , .rooms   ()
    );
endmodule
//------------------------------------------------------------------------------
// Revision history
//
// 2024.08.10: Started by Ando Ki (andoki@gmail.com)
//------------------------------------------------------------------------------
