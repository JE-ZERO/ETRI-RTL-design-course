module mux_4bit(input [3:0]a, [3:0]b, [3:0]c, [3:0]d, [1:0]sel,
                 output reg [3:0] q);
                 
always@(sel,a,b,c,d)
begin
    case(sel)
        2'b00 : q=a;
        2'b01 : q=b;
        2'b10 : q=c;
        2'b11 : q=d;
        default : q=4'b0000;
    endcase
end
endmodule
