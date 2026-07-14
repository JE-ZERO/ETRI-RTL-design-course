module counter(input clk_in,
                input rst,
                output led);
          
wire clk, locked;

wire rst_div;

clk_wiz_0 clk_u0 (
.clk_out1(clk),
.locked(locked),
.clk_in1(clk_in)
);


// Clock Wizard가 lock되기 전에는 divider를 reset 상태로 유지
assign rst_div = rst | ~locked;

clkDivider div_u0 (
    .clk(clk),
    .rst(rst_div),
    .clk_out(led)
);
 
endmodule
