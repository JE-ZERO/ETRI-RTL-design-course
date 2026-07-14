`timescale 1ns / 1ps

module clk_div_tb();

    reg clk;
    reg rst;
    wire clk_out;


    //DUT instance
    //시뮬레이션에서는 PERIOD를 작게 줘서 빠르게 확인
    clk_div #(
        .PERIOD(5)
    ) u_clk_div (
        .clk(clk),
        .rst(rst),
        .clk_out(clk_out)
    );


    //clock generation
    //100MHz clock 가정, 주기 10ns
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end


    //test sequence
    initial begin

        //초기값
        rst = 1'b0;


        //파형 확인용 출력
        $monitor("time=%0t | rst=%b cnt=%d clk_out=%b",
                  $time, rst, u_clk_div.cnt, clk_out);


        //==================================================
        // reset test
        // rst가 1이면 cnt=0, clk_out=0으로 초기화
        //==================================================
        #10;
        rst = 1'b1;
        #20;
        rst = 1'b0;


        //==================================================
        // divide test
        // PERIOD=5이므로 cnt가 5에 도달하면 clk_out 반전
        // clk_out이 0 -> 1 -> 0 -> 1로 바뀌는지 확인
        //==================================================
        #200;


        //==================================================
        // 동작 중 reset test
        // clk_out이 동작 중일 때 reset하면 다시 0으로 초기화되는지 확인
        //==================================================
        rst = 1'b1;
        #20;
        rst = 1'b0;


        //==================================================
        // reset 이후 다시 분주 동작 확인
        //==================================================
        #200;


        $finish;

    end

endmodule