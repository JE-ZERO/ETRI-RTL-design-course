module FF(input clk,
           input reset,
           output reg q);

always@(posedge reset or posedge clk)
    if(reset) q<=1'b0;
    else q<=~q;
    
endmodule
