`timescale 1ns / 1ps


module mux_4bit_tb();

reg [3:0]a, b, c, d;
reg [1:0] sel;
wire [3:0]q;

mux_4bit mux4bit(.a(a), .b(b), .c(c), .d(d), .sel(sel), .q(q));

initial begin
a=4'h0; b=4'h0; c=4'h0; d=4'h0; sel=2'b00;

#10 a=4'h1; b=4'h2; c=4'h4; d=4'h8; sel=2'b00;
#10 a=4'h1; b=4'h2; c=4'h4; d=4'h8; sel=2'b01;
#10 a=4'h1; b=4'h2; c=4'h4; d=4'h8; sel=2'b10;
#10 a=4'h1; b=4'h2; c=4'h4; d=4'h8; sel=2'b11;

#100 $finish;
end
endmodule
