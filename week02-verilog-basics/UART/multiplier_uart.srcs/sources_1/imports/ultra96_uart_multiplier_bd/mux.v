module mux(input [7:0] in_data,
           input sel,
           output [3:0] out_data);

assign out_data = (sel) ? in_data[7:4] : in_data[3:0];

endmodule
