`timescale 1ns / 1ps

module clk_div
#(PERIOD = 20_000_000)
(
    input wire clk, rst,
    output reg clk_out
    );
    reg [24:0] cnt;
    
    always@(posedge clk or posedge rst) begin
        if(rst) begin
            cnt <= 25'd0;
            clk_out <= 1'b0;
        end
        else if(cnt == PERIOD)begin
            clk_out <= ~clk_out;
            cnt <= 25'd1;
        end
        else begin
            cnt <= cnt + 25'd1;
        end
    end

endmodule
