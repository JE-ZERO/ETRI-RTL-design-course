`timescale 1ns / 1ps

module hexa_multiplier_tb();
reg clk;
reg rst_n;
reg [7:0] a;
reg [7:0] b;
wire [15:0] result;
wire done;
hexa_multiplier_top DUT(
    .clk(clk),
    .rst_n(rst_n),
    .a(a),
    .b(b),
    .result(result),
    .done(done)
);

always #5 clk = ~clk;

initial begin
    clk = 1'b0;
    rst_n = 1'b0;
    a = 8'h12;
    b = 8'h34;

    #20 rst_n = 1'b1;
    #60 rst_n = 1'b0;
    #20 $finish;
end
endmodule