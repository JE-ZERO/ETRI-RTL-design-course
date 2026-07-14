module multiplier_4bit(input [3:0] dataa,
                        input [3:0] datab,
                        output [7:0] product);

assign product=dataa*datab;

endmodule