`timescale 1ns / 1ps

module timer_tb();

    reg clk;
    reg signal;
    reg rst;
    reg start;
    reg [3:0] num;
    reg [1:0] mode;
    reg set_en;

    wire [3:0] w3;
    wire [3:0] w2;
    wire [3:0] w1;
    wire [3:0] w0;


    //DUT instance
    timer u_timer (
        .clk(clk),
        .signal(signal),
        .rst(rst),
        .start(start),
        .num(num),
        .mode(mode),
        .set_en(set_en),
        .w3(w3),
        .w2(w2),
        .w1(w1),
        .w0(w0)
    );


    //clock generation
    //100MHz clock 가정, 주기 10ns
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end


    //set digit task
    //mode에 따라 원하는 자리에 num값 저장
    task set_digit;
        input [1:0] mode_in;
        input [3:0] num_in;
        begin
            @(negedge clk);
            mode   = mode_in;
            num    = num_in;
            set_en = 1'b1;

            @(negedge clk);
            set_en = 1'b0;
        end
    endtask


    //start button task
    //start는 1clk 정도만 high
    task press_start;
        begin
            @(negedge clk);
            start = 1'b1;

            @(negedge clk);
            start = 1'b0;
        end
    endtask


    //1초 signal task
    //실제 1초를 기다리지 않고, 1초 tick이라고 가정한 pulse를 직접 넣음
    task tick_signal;
        begin
            @(negedge clk);
            signal = 1'b1;

            @(negedge clk);
            signal = 1'b0;
        end
    endtask


    //test sequence
    initial begin

        //초기값
        signal = 1'b0;
        rst    = 1'b0;
        start  = 1'b0;
        num    = 4'd0;
        mode   = 2'b00;
        set_en = 1'b0;


        //파형 확인용 출력
        $monitor("time=%0t | rst=%b start=%b signal=%b set_en=%b mode=%b num=%d | run=%b | w3w2:w1w0 = %d%d:%d%d",
                  $time, rst, start, signal, set_en, mode, num,
                  u_timer.run, w3, w2, w1, w0);


        //==================================================
        // reset test
        // rst가 1이면 모든 자리 0000 초기화
        //==================================================
        #10;
        rst = 1'b1;
        #20;
        rst = 1'b0;
        #20;


        //==================================================
        // setting test
        // 00:10 설정
        //
        // mode = 00 -> w0, 초 1의 자리
        // mode = 01 -> w1, 초 10의 자리
        // mode = 10 -> w2, 분 1의 자리
        // mode = 11 -> w3, 분 10의 자리
        //==================================================

        set_digit(2'b00, 4'd0); //w0 = 0, 초 1의 자리
        set_digit(2'b01, 4'd1); //w1 = 1, 초 10의 자리
        set_digit(2'b10, 4'd0); //w2 = 0, 분 1의 자리
        set_digit(2'b11, 4'd0); //w3 = 0, 분 10의 자리

        #30;


        //==================================================
        // start test
        // start가 들어가면 timer 내부 run이 1이 됨
        //==================================================

        press_start();

        #30;


        //==================================================
        // countdown test
        // signal pulse가 들어올 때마다 1씩 감소
        // 00:10 -> 00:09 -> 00:08 ...
        //==================================================

        tick_signal(); //00:10 -> 00:09
        #20;

        tick_signal(); //00:09 -> 00:08
        #20;

        tick_signal(); //00:08 -> 00:07
        #20;

        tick_signal(); //00:07 -> 00:06
        #20;

        tick_signal(); //00:06 -> 00:05
        #20;


        //==================================================
        // borrow test
        // 다시 01:00으로 설정 후, signal 1번으로 00:59 확인
        //==================================================

        rst = 1'b1;
        #20;
        rst = 1'b0;
        #20;

        set_digit(2'b00, 4'd0); //초 1의 자리 = 0
        set_digit(2'b01, 4'd0); //초 10의 자리 = 0
        set_digit(2'b10, 4'd1); //분 1의 자리 = 1
        set_digit(2'b11, 4'd0); //분 10의 자리 = 0

        #30;

        press_start();

        #30;

        tick_signal(); //01:00 -> 00:59

        #50;


        //==================================================
        // countdown to zero test
        // 00:03으로 설정 후 0까지 감소
        //==================================================

        rst = 1'b1;
        #20;
        rst = 1'b0;
        #20;

        set_digit(2'b00, 4'd3); //00:03
        set_digit(2'b01, 4'd0);
        set_digit(2'b10, 4'd0);
        set_digit(2'b11, 4'd0);

        #30;

        press_start();

        #30;

        tick_signal(); //00:03 -> 00:02
        #20;

        tick_signal(); //00:02 -> 00:01
        #20;

        tick_signal(); //00:01 -> 00:00
        #20;

        tick_signal(); //00:00 유지
        #50;


        $finish;

    end

endmodule