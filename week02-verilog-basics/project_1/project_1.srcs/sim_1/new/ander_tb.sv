`timescale 1ns / 1ps

module ander_tb();
reg a, b;
wire result;

ander ander(.a(a), .b(b), .result(result));



initial begin
a=0; b=0;
#10 a=1; b=0;
#10 a=0; b=1;
#10 a=1; b=1;
#10 $finish;
end

endmodule
