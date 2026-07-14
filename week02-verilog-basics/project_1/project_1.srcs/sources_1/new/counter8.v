module counter8(input clk,
                 input reset,
                 input [1:0] func,
                 input [7:0] d,
                 output reg [7:0] q);
                 
always @ (posedge clk, posedge reset)
    if(reset)
        q<=8'h00;
    else
        case(func)
            2'b00 : q<=d;
            2'b01 : q<=q+1;
            2'b10 : q<=q-1;
            default : q<=q;
        endcase

endmodule
