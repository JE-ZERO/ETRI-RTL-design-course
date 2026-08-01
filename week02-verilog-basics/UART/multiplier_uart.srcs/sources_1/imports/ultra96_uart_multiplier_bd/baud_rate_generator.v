`timescale 1ns/1ps

module baud_rate_generator #(
    parameter integer CLK_FREQ  = 100_000_000,
    parameter integer TICK_RATE = 115_200
)(
    input  wire clk,
    input  wire reset,
    input  wire enable,
    output reg  tick
);

    localparam integer DIVISOR =
        (CLK_FREQ + (TICK_RATE / 2)) / TICK_RATE;

    reg [31:0] count;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            count <= 32'd0;
            tick  <= 1'b0;
        end
        else if (!enable) begin
            count <= 32'd0;
            tick  <= 1'b0;
        end
        else if (count == DIVISOR - 1) begin
            count <= 32'd0;
            tick  <= 1'b1;
        end
        else begin
            count <= count + 1'b1;
            tick  <= 1'b0;
        end
    end

endmodule
