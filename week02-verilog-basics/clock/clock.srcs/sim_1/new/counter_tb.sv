`timescale 1ns / 1ps

module counter_tb();

reg clk_in;
reg rst;
wire led;

// DUT instance
counter uut (
    .clk_in(clk_in),
    .rst(rst),
    .led(led)
);

// --------------------------------------------------
// Simulation용 parameter override
// 실제 clkDivider.v의 기본값은 50_000_000 그대로 유지
// TB에서만 빠르게 보기 위해 10으로 변경
// --------------------------------------------------
defparam uut.div_u0.HALF_PERIOD_COUNT = 10;

// --------------------------------------------------
// 40MHz input clock generation
// 40MHz 주기 = 25ns
// half period = 12.5ns
// --------------------------------------------------
initial begin
    clk_in = 1'b0;
    forever #12.5 clk_in = ~clk_in;
end

// --------------------------------------------------
// Reset control
// --------------------------------------------------
initial begin
    rst = 1'b1;

    // reset 유지
    #200;
    rst = 1'b0;

    // simulation 진행
    #5000;

    $finish;
end

// --------------------------------------------------
// Monitor
// --------------------------------------------------
initial begin
    $monitor("time=%0t ns, rst=%b, locked=%b, led=%b",
             $time, rst, uut.locked, led);
end

endmodule