`timescale 1ns / 1ps

module display_output_tb();

    reg scan_clk;
    reg [3:0] w3;
    reg [3:0] w2;
    reg [3:0] w1;
    reg [3:0] w0;

    wire [7:0] pmod_a;
    wire [7:0] pmod_b;


    //DUT instance
    display_output u_display_output (
        .scan_clk(scan_clk),
        .w3(w3),
        .w2(w2),
        .w1(w1),
        .w0(w0),
        .pmod_a(pmod_a),
        .pmod_b(pmod_b)
    );


    //scan_clk generation
    //실제 회로에서는 clk_div에서 생성됨
    //여기서는 testbench에서 직접 0/1 반복
    initial begin
        scan_clk = 1'b0;
        forever #10 scan_clk = ~scan_clk;
    end


    //test sequence
    initial begin

        //==================================================
        // test 1
        // 12:34 표시 확인
        //
        // pmod_b = 분 표시 = 12
        // pmod_a = 초 표시 = 34
        //==================================================
        w3 = 4'd1; //분 10의 자리
        w2 = 4'd2; //분 1의 자리
        w1 = 4'd3; //초 10의 자리
        w0 = 4'd4; //초 1의 자리

        #50;


        //==================================================
        // test 2
        // 05:09 표시 확인
        //
        // pmod_b = 분 표시 = 05
        // pmod_a = 초 표시 = 09
        //==================================================
        w3 = 4'd0; //분 10의 자리
        w2 = 4'd5; //분 1의 자리
        w1 = 4'd0; //초 10의 자리
        w0 = 4'd9; //초 1의 자리

        #50;


        //==================================================
        // test 3
        // 59:59 표시 확인
        //
        // 5와 9의 segment 패턴 확인
        //==================================================
        w3 = 4'd5; //분 10의 자리
        w2 = 4'd9; //분 1의 자리
        w1 = 4'd5; //초 10의 자리
        w0 = 4'd9; //초 1의 자리

        #50;


        //==================================================
        // test 4
        // 잘못된 값 입력 시 default '-' 표시 확인
        // 4'd10은 0~9 범위를 벗어나므로 '-' 모양 출력
        //==================================================
        w3 = 4'd10;
        w2 = 4'd10;
        w1 = 4'd10;
        w0 = 4'd10;

        #50;


        $finish;

    end


    //monitor
    initial begin
        $monitor("time=%0t | scan_clk=%b | w3w2:w1w0=%d%d:%d%d | digit_a=%d digit_b=%d | pmod_a=%b pmod_b=%b",
                 $time,
                 scan_clk,
                 w3, w2, w1, w0,
                 u_display_output.digit_a,
                 u_display_output.digit_b,
                 pmod_a,
                 pmod_b);
    end

endmodule