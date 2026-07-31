`timescale 1ns / 1ps


module tb_single_port_ROM();

        logic clk;
        logic rst;
        logic start_r;
        logic [15:0] data_out;
        logic done;

        single_port_ROM u0(
                .clk(clk),
                .rst(rst),
                .start_r(start_r),
                .data_out(data_out),
                .done(done)
        );


        initial begin
                clk = 0;
                forever #5 clk = ~clk;
        end


        initial begin
                rst = 0; start_r = 0; 
                #95;
                rst = 1;
                #10;
                rst = 0;
                #10;

                start_r = 1;
                #10;
                start_r = 0;
                #10;

                if(done) $finish;

        end
        
endmodule
