module sela_selb(input a, b, c, sela, selb,
                  output reg q);


always@(a, b, c, sela, selb) begin
if(sela)
    q=a;
else
    if(selb)
    q=b;
    else
    q=c;

end
endmodule
