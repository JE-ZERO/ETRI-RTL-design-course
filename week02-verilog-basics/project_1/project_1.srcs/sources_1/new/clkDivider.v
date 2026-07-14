module clkDivider
#(PERIOD = 10)
(
    input clk,
    input rst,
    output clk_out
);

assign clk_out = clk / PERIOD;

endmodule
