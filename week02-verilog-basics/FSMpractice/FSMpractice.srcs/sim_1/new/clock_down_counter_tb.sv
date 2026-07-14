`timescale 1ns / 1ps

module clock_down_counter_tb();

reg clk, rst;
reg start;
reg [3:0] num;
wire dout, done;
clock_down_counter counter(.clk(clk), .rst(rst), .start(start), .num(num), .dout(dout), .done(done));

initial clk=0;
always #5 clk=~clk;


initial begin
rst=1; start=0; num=3;

#10 rst=0; start=1;
#10 start=0;

#1000 $finish;

end





endmodule
