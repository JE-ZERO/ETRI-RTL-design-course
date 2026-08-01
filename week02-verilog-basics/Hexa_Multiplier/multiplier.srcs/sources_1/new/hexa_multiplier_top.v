module hexa_multiplier_top(input clk,
                           input rst_n,
                           input [7:0] a,
                           input [7:0] b,
                           output [15:0] result,
                           output done);

wire sel_a;
wire sel_b;
wire [1:0] shift_cntrl;
wire acc_clear;
wire acc_enable;
wire [3:0] a_mux_out;
wire [3:0] b_mux_out;
wire [7:0] product;
wire [15:0] shift_out;

controller U0(
    .clk(clk),
    .rst_n(rst_n),
    .sel_a(sel_a),
    .sel_b(sel_b),
    .shift_cntrl(shift_cntrl),
    .acc_clear(acc_clear),
    .acc_enable(acc_enable),
    .done(done)
);

mux U1(
    .in_data(a),
    .sel(sel_a),
    .out_data(a_mux_out)
);

mux U2(
    .in_data(b),
    .sel(sel_b),
    .out_data(b_mux_out)
);

mult4x4 U3(
    .dataa(a_mux_out),
    .datab(b_mux_out),
    .product(product)
);

shifter U4(
    .inp(product),
    .shift_cntrl(shift_cntrl),
    .shift_out(shift_out)
);

accumulator U5(
    .clk(clk),
    .rst_n(rst_n),
    .in_data(shift_out),
    .acc_clear(acc_clear),
    .acc_enable(acc_enable),
    .acc(result)
);

endmodule
