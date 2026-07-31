`timescale 1ns / 1ps

module tb_simple_dual_port_RAM();

    reg clk;
    reg rst;
    reg start_w;
    reg start_r;
    wire [15:0] data_out;
    wire done_w;
    wire done_r;

    simple_dual_port_RAM u2(
        .clk(clk),
        .rst(rst),
        .start_w(start_w),
        .start_r(start_r),
        .data_out(data_out),
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
        #500;

        start_r = 1;
        #10;
        start_r = 0;

        if(done_r) begin
            #10;
            $finish;
        end
    end

endmodule
