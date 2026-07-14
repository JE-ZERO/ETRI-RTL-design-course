`timescale 1ns / 1ps

module top_tb();

    reg clk;
    reg bt_start;
    reg bt_mode;
    reg bt_reset;
    reg bt_setting;

    wire [7:0] pmod_a;
    wire [7:0] pmod_b;


    //DUT instance
    top u_top (
        .clk(clk),
        .bt_start(bt_start),
        .bt_mode(bt_mode),
        .bt_reset(bt_reset),
        .bt_setting(bt_setting),
        .pmod_a(pmod_a),
        .pmod_b(pmod_b)
    );


    //==================================================
    // simulation용 parameter override
    // 실제 보드용 PERIOD는 너무 크기 때문에
    // 발표용 waveform에서는 작게 설정
    //==================================================
    defparam u_top.u0.PERIOD = 5; //timer용 signal 빠르게 생성
    defparam u_top.u1.PERIOD = 2; //display용 scan_clk 빠르게 생성


    //==================================================
    // clock generation
    // 100MHz clock 가정, 주기 10ns
    //==================================================
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end


    //==================================================
    // reset button task
    //==================================================
    task press_reset;
    begin
        @(negedge clk);
        bt_reset = 1'b1;

        repeat(5) @(negedge clk);

        bt_reset = 1'b0;

        repeat(5) @(negedge clk);
    end
    endtask


    //==================================================
    // mode button task
    //==================================================
    task press_mode;
    begin
        @(negedge clk);
        bt_mode = 1'b1;

        repeat(3) @(negedge clk);

        bt_mode = 1'b0;

        repeat(5) @(negedge clk);
    end
    endtask


    //==================================================
    // setting button task
    //==================================================
    task press_setting_once;
    begin
        @(negedge clk);
        bt_setting = 1'b1;

        repeat(1) @(negedge clk);

        bt_setting = 1'b0;

        repeat(5) @(negedge clk);
    end
    endtask


    //==================================================
    // start button task
    //==================================================
    task press_start;
    begin
        @(negedge clk);
        bt_start = 1'b1;

        repeat(1) @(negedge clk);

        bt_start = 1'b0;

        repeat(5) @(negedge clk);
    end
    endtask


    //==================================================
    // timer tick wait task
    // u_top.signal의 posedge 1번을 timer 1초 tick 1번으로 간주
    //==================================================
    task wait_timer_tick;
    begin
        @(posedge u_top.signal);
        @(posedge clk);
        #1;
    end
    endtask


    //==================================================
    // test sequence
    //==================================================
    initial begin

        bt_start   = 1'b0;
        bt_mode    = 1'b0;
        bt_reset   = 1'b0;
        bt_setting = 1'b0;


        $monitor("time=%0t | rst=%b mode_btn=%b set=%b start=%b | state=%b mode=%b num=%d set_en=%b | run=%b done=%b | timer=%d%d:%d%d | signal=%b scan=%b | digit_a=%d digit_b=%d",
                 $time,
                 bt_reset, bt_mode, bt_setting, bt_start,
                 u_top.u2.c_state, u_top.mode, u_top.num, u_top.timer_set_en,
                 u_top.u5.run, u_top.done,
                 u_top.w3, u_top.w2, u_top.w1, u_top.w0,
                 u_top.signal, u_top.scan_clk,
                 u_top.u3.digit_a, u_top.u3.digit_b);


        //==================================================
        // 1. reset
        // 기대값: 00:00
        //==================================================
        press_reset();


        //==================================================
        // 2. mode 1번
        // ST_IDLE -> ST_T1
        // 초 10의 자리 선택
        //==================================================
        press_mode();


        //==================================================
        // 3. setting 3번
        // 초 10의 자리 = 3
        // 기대값: 00:30
        //==================================================
        press_setting_once();
        press_setting_once();
        press_setting_once();

        repeat(10) @(negedge clk);


        //==================================================
        // 4. mode 1번 더
        // ST_T1 -> ST_T2
        // 분 1의 자리 선택
        // setting 모듈의 num_led는 0으로 초기화됨
        //==================================================
        press_mode();


        //==================================================
        // 5. setting 1번
        // 분 1의 자리 = 1
        // 기대값: 01:30
        //==================================================
        press_setting_once();

        repeat(10) @(negedge clk);


        //==================================================
        // 6. 01:30 설정 확인
        //==================================================
        if({u_top.w3, u_top.w2, u_top.w1, u_top.w0} == 16'h0130) begin
            $display("PASS: timer setting = 01:30");
        end
        else begin
            $display("FAIL: timer setting is not 01:30");
            $display("current timer = %0d%0d:%0d%0d",
                     u_top.w3, u_top.w2, u_top.w1, u_top.w0);
        end


        //==================================================
        // 7. start
        // countdown 시작
        //==================================================
        press_start();


        //==================================================
        // 8. countdown
        // 01:30 = 90초
        // signal tick 90번 후 00:00 확인
        //==================================================
        repeat(90) begin
            wait_timer_tick();
        end

        repeat(10) @(negedge clk);


        //==================================================
        // 9. 00:00 도달 확인
        //==================================================
        if({u_top.w3, u_top.w2, u_top.w1, u_top.w0} == 16'h0000) begin
            $display("PASS: countdown finished at 00:00");
        end
        else begin
            $display("FAIL: countdown did not finish at 00:00");
            $display("current timer = %0d%0d:%0d%0d",
                     u_top.w3, u_top.w2, u_top.w1, u_top.w0);
        end


        //==================================================
        // 10. reset 확인
        //==================================================
        press_reset();

        #100;

        $finish;

    end

endmodule