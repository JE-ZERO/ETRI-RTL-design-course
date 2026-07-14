`timescale 1ns / 1ps

module setting_tb();

    reg clk;
    reg rst;
    reg bt_set;
    reg [1:0] mode;

    wire [3:0] num_led;


    //DUT instance
    setting u_setting (
        .clk(clk),
        .rst(rst),
        .bt_set(bt_set),
        .mode(mode),
        .num_led(num_led)
    );


    //clock generation
    //100MHz clock 가정, 주기 10ns
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end


    //setting button press task
    //bt_set을 1clk 동안만 high로 만들어서 숫자 1번 증가 확인
    //setting 내부에서는 clk_out이 1일 때만 증가하므로 clk_out이 1이 될 때까지 기다림
    task press_set;
    begin
        wait(u_setting.clk_out == 1'b1);

        @(negedge clk);
        bt_set = 1'b1;

        @(negedge clk);
        bt_set = 1'b0;

        #20;
    end
    endtask


    //reset task
    task press_reset;
    begin
        @(negedge clk);
        rst = 1'b1;

        @(negedge clk);
        rst = 1'b0;

        #20;
    end
    endtask


    //test sequence
    initial begin

        //초기값
        rst    = 1'b0;
        bt_set = 1'b0;
        mode   = 2'b00;


        //파형 확인용 출력
        $monitor("time=%0t | rst=%b bt_set=%b mode=%b | clk_out=%b cnt=%d | num_led=%d",
                  $time, rst, bt_set, mode, u_setting.clk_out, u_setting.cnt, num_led);


        //==================================================
        // reset test
        // rst가 1이면 num_led가 0으로 초기화되는지 확인
        //==================================================
        press_reset();


        //==================================================
        // mode = 00 test
        // 초 1의 자리
        // 0~9까지 증가 후 다시 0으로 돌아가는지 확인
        //==================================================
        mode = 2'b00;

        press_set(); //0 -> 1
        press_set(); //1 -> 2
        press_set(); //2 -> 3
        press_set(); //3 -> 4
        press_set(); //4 -> 5
        press_set(); //5 -> 6
        press_set(); //6 -> 7
        press_set(); //7 -> 8
        press_set(); //8 -> 9
        press_set(); //9 -> 0

        #50;


        //==================================================
        // mode = 01 test
        // 초 10의 자리
        // 0~5까지 증가 후 다시 0으로 돌아가는지 확인
        //==================================================
        press_reset();

        mode = 2'b01;

        press_set(); //0 -> 1
        press_set(); //1 -> 2
        press_set(); //2 -> 3
        press_set(); //3 -> 4
        press_set(); //4 -> 5
        press_set(); //5 -> 0

        #50;


        //==================================================
        // mode = 10 test
        // 분 1의 자리
        // 0~9까지 증가 후 다시 0으로 돌아가는지 확인
        //==================================================
        press_reset();

        mode = 2'b10;

        press_set(); //0 -> 1
        press_set(); //1 -> 2
        press_set(); //2 -> 3
        press_set(); //3 -> 4
        press_set(); //4 -> 5
        press_set(); //5 -> 6
        press_set(); //6 -> 7
        press_set(); //7 -> 8
        press_set(); //8 -> 9
        press_set(); //9 -> 0

        #50;


        //==================================================
        // mode = 11 test
        // 분 10의 자리
        // 0~5까지 증가 후 다시 0으로 돌아가는지 확인
        //==================================================
        press_reset();

        mode = 2'b11;

        press_set(); //0 -> 1
        press_set(); //1 -> 2
        press_set(); //2 -> 3
        press_set(); //3 -> 4
        press_set(); //4 -> 5
        press_set(); //5 -> 0

        #50;


        //==================================================
        // bt_set이 0이면 num_led가 유지되는지 확인
        //==================================================
        mode = 2'b00;
        bt_set = 1'b0;

        #200;


        $finish;

    end

endmodule