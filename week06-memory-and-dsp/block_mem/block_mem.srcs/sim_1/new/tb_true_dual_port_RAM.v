`timescale 1ns / 1ps

module tb_true_dual_port_RAM();

    reg clk;
    reg rst;
    reg start_w;
    reg start_r;
    wire [15:0] data_out1;
    wire [15:0] data_out2;
    wire done_w;
    wire done_r;

    true_dual_port_RAM u3(
        .clk(clk),
        .rst(rst),
        .start_w(start_w),
        .start_r(start_r),
        .data_out1(data_out1),
        .data_out2(data_out2),
        .done_w(done_w),
        .done_r(done_r)
    );

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    initial begin
        rst = 0;
        start_w = 0;
        start_r = 0;

        #100;
        rst = 1;
        #10;
        rst = 0;
        #10;
        start_w = 1;
        #10;
        start_w = 0;

        wait(done_w);
        #5;
        start_r = 1;
        #10;
        start_r = 0;

        wait(done_r);
        #10;
        $finish;
    end

endmodule
