`timescale 1ns / 1ps

module tb_Mult_9x9();

    logic clk;
    logic rst;
    logic start;
    logic [15:0] data_out;


    Mult_9x9 DUT (.clk(clk), .rst(rst), .start(start), .data_out(data_out));

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    initial begin
        rst = 0; start = 0;
        #100; rst = 1;
        #10; rst = 0; start = 1;
        #10; start = 0;
    end

endmodule
