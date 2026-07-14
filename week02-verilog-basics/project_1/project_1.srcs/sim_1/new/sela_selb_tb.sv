`timescale 1ns / 1ps

module sela_selb_tb();

reg a, b, c, sela, selb;
wire q;

sela_selb mux(.a(a), .b(b), .c(c), .sela(sela), .selb(selb), .q(q));

initial begin
a=0; b=0; c=0; sela=0; selb=0;
#10 a=0; b=0; c=1; sela=0; selb=0;
#10 a=0; b=1; c=0; sela=0; selb=0;
#10 a=0; b=1; c=1; sela=0; selb=0;
#10 a=1; b=0; c=0; sela=0; selb=0;
#10 a=1; b=0; c=1; sela=0; selb=0;
#10 a=1; b=1; c=0; sela=0; selb=0;
#10 a=1; b=1; c=1; sela=0; selb=0;


#10 a=0; b=0; c=0; sela=0; selb=1;
#10 a=0; b=0; c=1; sela=0; selb=1;
#10 a=0; b=1; c=0; sela=0; selb=1;
#10 a=0; b=1; c=1; sela=0; selb=1;
#10 a=1; b=0; c=0; sela=0; selb=1;
#10 a=1; b=0; c=1; sela=0; selb=1;
#10 a=1; b=1; c=0; sela=0; selb=1;
#10 a=1; b=1; c=1; sela=0; selb=1;

#10 a=0; b=0; c=0; sela=1; selb=0;
#10 a=0; b=0; c=1; sela=1; selb=0;
#10 a=0; b=1; c=0; sela=1; selb=0;
#10 a=0; b=1; c=1; sela=1; selb=0;
#10 a=1; b=0; c=0; sela=1; selb=0;
#10 a=1; b=0; c=1; sela=1; selb=0;
#10 a=1; b=1; c=0; sela=1; selb=0;
#10 a=1; b=1; c=1; sela=1; selb=0;

#10 a=0; b=0; c=0; sela=1; selb=1;
#10 a=0; b=0; c=1; sela=1; selb=1;
#10 a=0; b=1; c=0; sela=1; selb=1;
#10 a=0; b=1; c=1; sela=1; selb=1;
#10 a=1; b=0; c=0; sela=1; selb=1;
#10 a=1; b=0; c=1; sela=1; selb=1;
#10 a=1; b=1; c=0; sela=1; selb=1;
#10 a=1; b=1; c=1; sela=1; selb=1;
#400 $finish;

end
endmodule
