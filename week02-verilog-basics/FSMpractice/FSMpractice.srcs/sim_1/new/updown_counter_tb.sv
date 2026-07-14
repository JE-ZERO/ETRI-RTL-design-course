`timescale 1ns / 1ps

module updown_counter_tb();

reg clk, rst_n;
reg mode;
wire [2:0] cnt;

updown_counter counter(.clk(clk), .rst_n(rst_n), .mode(mode), .cnt(cnt));

initial clk=0;
always #5 clk=~clk;


initial begin
rst_n=1; mode=0;

#5 rst_n=0;
#15 rst_n=1;
#70 mode=1;
#10 mode=0;

#50 $finish;

end





endmodule
