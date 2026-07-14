`timescale 1ns / 1ps

module cntrl_tb();

    reg clk;
    reg bt_reset;
    reg bt_mode;
    reg done;

    wire [1:0] mode_out;


    //DUT instance
    cntrl u_cntrl (
        .clk(clk),
        .bt_reset(bt_reset),
        .bt_mode(bt_mode),
        .done(done),
        .mode_out(mode_out)
    );


    //clock generation
    //100MHz clock 가정, 주기 10ns
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end


    //mode button press task
    //bt_mode는 실제 버튼처럼 잠깐 1로 유지
    //컨트롤러 내부에서 edge detection 하므로 한 번만 상태 이동해야 함
    task press_mode;
    begin
        bt_mode = 1'b1;
        #30;
        bt_mode = 1'b0;
        #30;
    end
    endtask


    //reset button press task
    //bt_reset은 active-high reset
    task press_reset;
    begin
        bt_reset = 1'b1;
        #30;
        bt_reset = 1'b0;
        #30;
    end
    endtask


    //test sequence
    initial begin

        //초기값
        bt_reset = 1'b0;
        bt_mode  = 1'b0;
        done     = 1'b0;

        //파형 보기용
        $monitor("time=%0t | reset=%b mode_btn=%b done=%b | c_state=%b mode_out=%b",
                  $time, bt_reset, bt_mode, done, u_cntrl.c_state, mode_out);


        //초기 reset
        #10;
        bt_reset = 1'b1;
        #30;
        bt_reset = 1'b0;
        #30;


        //==================================================
        // mode 버튼 테스트
        // ST_IDLE -> ST_T0 -> ST_T1 -> ST_T2 -> ST_T3 -> ST_T0
        //==================================================

        press_mode(); //ST_IDLE -> ST_T0, mode_out = 00
        press_mode(); //ST_T0   -> ST_T1, mode_out = 01
        press_mode(); //ST_T1   -> ST_T2, mode_out = 10
        press_mode(); //ST_T2   -> ST_T3, mode_out = 11
        press_mode(); //ST_T3   -> ST_T0, mode_out = 00


        //==================================================
        // mode 버튼을 길게 눌렀을 때 테스트
        // edge detection이 제대로 되면 상태가 한 번만 이동해야 함
        //==================================================

        bt_mode = 1'b1;
        #100;
        bt_mode = 1'b0;
        #50;


        //==================================================
        // done 테스트
        // 현재 상태에서 done이 1이면 ST_DONE으로 이동
        //==================================================

        press_mode(); //자리 상태 하나 이동

        done = 1'b1;
        #20;
        done = 1'b0;
        #50;


        //==================================================
        // ST_DONE에서 mode 버튼 테스트
        // 네 코드 기준: ST_DONE에서 mode를 누르면 ST_T0로 이동
        // 단, done이 계속 1이면 다시 ST_DONE으로 갈 수 있음
        //==================================================

        press_mode();


        //==================================================
        // reset 테스트
        // 어떤 상태에서든 bt_reset이 들어오면 ST_IDLE로 이동
        //==================================================

        press_mode();
        press_mode();

        press_reset();


        #100;
        $finish;

    end

endmodule