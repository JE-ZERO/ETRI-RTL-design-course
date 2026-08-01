`timescale 1ns/1ps

module uart_multiplier_core #(
    parameter integer CLK_FREQ  = 100_000_000,
    parameter integer BAUD_RATE = 115_200
)(
    input  wire clk,
    input  wire reset,
    input  wire rxd,
    output wire txd
);

    localparam [2:0] ST_RX         = 3'd0;
    localparam [2:0] ST_MULT_START = 3'd1;
    localparam [2:0] ST_MULT_WAIT  = 3'd2;
    localparam [2:0] ST_TX_START   = 3'd3;
    localparam [2:0] ST_TX_WAIT    = 3'd4;

    wire [7:0] rx_dout;
    wire       rx_en;

    reg  [7:0] tx_din;
    reg        tx_start;
    wire       tx_en;

    reg  [7:0] operand_a;
    reg  [7:0] operand_b;
    reg        mult_start;
    wire [15:0] mult_result;
    wire        mult_en;

    reg [15:0] result_latched;
    reg [1:0]  digit_count;
    reg [2:0]  send_index;
    reg [2:0]  state;

    uart_rx #(
        .CLK_FREQ (CLK_FREQ),
        .BAUD_RATE(BAUD_RATE)
    ) u_uart_rx (
        .clk    (clk),
        .reset  (reset),
        .rx_data(rxd),
        .dout   (rx_dout),
        .en     (rx_en)
    );

    uart_tx #(
        .CLK_FREQ (CLK_FREQ),
        .BAUD_RATE(BAUD_RATE)
    ) u_uart_tx (
        .clk    (clk),
        .din    (tx_din),
        .reset  (reset),
        .start  (tx_start),
        .tx_data(txd),
        .en     (tx_en)
    );

    multiplier_adapter u_multiplier_adapter (
        .clk   (clk),
        .reset (reset),
        .start (mult_start),
        .a     (operand_a),
        .b     (operand_b),
        .result(mult_result),
        .en    (mult_en)
    );

    function is_hex_ascii;
        input [7:0] ch;
        begin
            is_hex_ascii =
                ((ch >= 8'h30) && (ch <= 8'h39)) || ((ch >= 8'h41) && (ch <= 8'h46)) || ((ch >= 8'h61) && (ch <= 8'h66));
        end
    endfunction

    function [3:0] ascii_to_nibble;
        input [7:0] ch;
        begin
            if ((ch >= 8'h30) && (ch <= 8'h39))
                ascii_to_nibble = ch - 8'h30;
            else if ((ch >= 8'h41) && (ch <= 8'h46))
                ascii_to_nibble = ch - 8'h41 + 4'd10;
            else
                ascii_to_nibble = ch - 8'h61 + 4'd10;
        end
    endfunction

    function [7:0] nibble_to_ascii;
        input [3:0] nibble;
        begin
            if (nibble < 4'd10)
                nibble_to_ascii = 8'h30 + nibble;
            else
                nibble_to_ascii = 8'h41 + (nibble - 4'd10);
        end
    endfunction

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            tx_din         <= 8'h00;
            tx_start       <= 1'b0;
            operand_a      <= 8'h00;
            operand_b      <= 8'h00;
            mult_start     <= 1'b0;
            result_latched <= 16'h0000;
            digit_count    <= 2'd0;
            send_index     <= 3'd0;
            state          <= ST_RX;
        end
        else begin
            tx_start   <= 1'b0;
            mult_start <= 1'b0;

            case (state)
                ST_RX: begin
                    if (rx_en) begin
                        if (is_hex_ascii(rx_dout)) begin
                            case (digit_count)
                                2'd0: begin
                                    operand_a[7:4] <= ascii_to_nibble(rx_dout);
                                    digit_count    <= 2'd1;
                                end

                                2'd1: begin
                                    operand_a[3:0] <= ascii_to_nibble(rx_dout);
                                    digit_count    <= 2'd2;
                                end

                                2'd2: begin
                                    operand_b[7:4] <= ascii_to_nibble(rx_dout);
                                    digit_count    <= 2'd3;
                                end

                                2'd3: begin
                                    operand_b[3:0] <= ascii_to_nibble(rx_dout);
                                    digit_count    <= 2'd0;
                                    state          <= ST_MULT_START;
                                end
                            endcase
                        end
                        else if ((rx_dout == 8'h0D) ||
                                 (rx_dout == 8'h0A) ||
                                 (rx_dout == 8'h20)) begin
                            // Ignore CR, LF and space.
                            digit_count <= digit_count;
                        end
                        else begin
                            // Invalid character discards a partial command.
                            digit_count <= 2'd0;
                            operand_a   <= 8'h00;
                            operand_b   <= 8'h00;
                        end
                    end
                end

                ST_MULT_START: begin
                    mult_start <= 1'b1;
                    state      <= ST_MULT_WAIT;
                end

                ST_MULT_WAIT: begin
                    if (mult_en) begin
                        result_latched <= mult_result;
                        send_index     <= 3'd0;
                        state          <= ST_TX_START;
                    end
                end

                ST_TX_START: begin
                    case (send_index)
                        3'd0: tx_din <= 8'h3D;  // '='
                        3'd1: tx_din <= nibble_to_ascii(result_latched[15:12]);
                        3'd2: tx_din <= nibble_to_ascii(result_latched[11:8]);
                        3'd3: tx_din <= nibble_to_ascii(result_latched[7:4]);
                        3'd4: tx_din <= nibble_to_ascii(result_latched[3:0]);
                        3'd5: tx_din <= 8'h0D;
                        3'd6: tx_din <= 8'h0A;
                        default: tx_din <= 8'h3F;
                    endcase

                    tx_start <= 1'b1;
                    state    <= ST_TX_WAIT;
                end

                ST_TX_WAIT: begin
                    if (tx_en) begin
                        if (send_index == 3'd6) begin
                            send_index <= 3'd0;
                            state      <= ST_RX;
                        end
                        else begin
                            send_index <= send_index + 1'b1;
                            state      <= ST_TX_START;
                        end
                    end
                end

                default: state <= ST_RX;
            endcase
        end
    end

endmodule
