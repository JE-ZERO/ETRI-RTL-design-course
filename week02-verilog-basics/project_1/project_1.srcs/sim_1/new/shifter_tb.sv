`timescale 1ns / 1ps


module shifter_tb();

reg [7:0] inp;
reg [1:0] shift_cntrl;
wire [15:0] shift_out;

shifter shift(.inp(inp), .shift_cntrl(shift_cntrl), .shift_out(shift_out));

initial begin

inp=8'h00; shift_cntrl=2'b00;

#10 inp=8'hca; shift_cntrl=2'b00;
#10 inp=8'hca; shift_cntrl=2'b01;
#10 inp=8'hca; shift_cntrl=2'b10;
#10 inp=8'hca; shift_cntrl=2'b11;

#100 $finish;
end
endmodule
