`timescale 1ns/1ps

module uart_tx #(
    parameter integer CLK_FREQ  = 100_000_000,
    parameter integer BAUD_RATE = 115_200
)(
    input  wire       clk,
    input  wire [7:0] din,
    input  wire       reset,
    input  wire       start,
    output reg        tx_data,
    output reg        en
);

    localparam [1:0] ST_IDLE  = 2'd0;
    localparam [1:0] ST_START = 2'd1;
    localparam [1:0] ST_DATA  = 2'd2;
    localparam [1:0] ST_STOP  = 2'd3;

    reg [1:0] state;
    reg [7:0] shift_reg;
    reg [2:0] bit_index;
    reg       baud_enable;
    wire      baud_tick;

    baud_rate_generator #(
        .CLK_FREQ (CLK_FREQ),
        .TICK_RATE(BAUD_RATE)
    ) u_baud_tx (
        .clk   (clk),
        .reset (reset),
        .enable(baud_enable),
        .tick  (baud_tick)
    );

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state       <= ST_IDLE;
            shift_reg   <= 8'h00;
            bit_index   <= 3'd0;
            baud_enable <= 1'b0;
            tx_data     <= 1'b1;
            en          <= 1'b0;
        end
        else begin
            en <= 1'b0;

            case (state)
                ST_IDLE: begin
                    tx_data     <= 1'b1;
                    baud_enable <= 1'b0;
                    bit_index   <= 3'd0;

                    if (start) begin
                        shift_reg   <= din;
                        tx_data     <= 1'b0;
                        baud_enable <= 1'b1;
                        state       <= ST_START;
                    end
                end

                ST_START: begin
                    if (baud_tick) begin
                        tx_data   <= shift_reg[0];
                        bit_index <= 3'd0;
                        state     <= ST_DATA;
                    end
                end

                ST_DATA: begin
                    if (baud_tick) begin
                        if (bit_index == 3'd7) begin
                            tx_data <= 1'b1;
                            state   <= ST_STOP;
                        end
                        else begin
                            bit_index <= bit_index + 1'b1;
                            tx_data   <= shift_reg[bit_index + 1'b1];
                        end
                    end
                end

                ST_STOP: begin
                    if (baud_tick) begin
                        tx_data     <= 1'b1;
                        baud_enable <= 1'b0;
                        en          <= 1'b1;
                        state       <= ST_IDLE;
                    end
                end

                default: begin
                    state       <= ST_IDLE;
                    tx_data     <= 1'b1;
                    baud_enable <= 1'b0;
                end
            endcase
        end
    end

endmodule
