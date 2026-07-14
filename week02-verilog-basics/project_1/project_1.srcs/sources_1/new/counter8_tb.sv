`timescale 1ns / 1ps

module counter8_tb();

reg clk, reset;
reg [1:0] func;
reg [7:0] d;
wire [7:0] q;

counter8 counter_8bit(.clk(clk), .reset(reset), .func(func), .d(d), .q(q));

initial clk=0;
always #5 clk=~clk;


initial begin
reset=0; func=2'b00; d=8'h00;

#10 func=2'b01; d=8'hab;

#40 func=2'b10; d=8'h12;

#24 reset=1;

#6 reset=0; func=2'b00; d=8'hff;

#10 func=2'b10;



#20 $finish;

end


endmodule