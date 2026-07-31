`timescale 1ns / 1ps

module tb_memory_copy();

    reg clk;
    reg rst;
    reg start;
    wire [15:0] data_out;
    wire done_w;
    wire done_r;
    wire done_c;

    memory_copy DUT(
        .clk(clk),
        .rst(rst),
        .start(start),
        .data_out(data_out),
        .done_w(done_w),
        .done_c(done_c),
        .done_r(done_r)
    );

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    initial begin
        rst = 0;
        start = 0;

        #100;
        rst = 1;
        #10;
        rst = 0;
        #10;
        start = 1;
        #10;
        start = 0;

        if(done_r) $finish;
    end

endmodule
