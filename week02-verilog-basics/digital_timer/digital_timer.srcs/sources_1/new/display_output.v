`timescale 1ns / 1ps

module display_output(
    input  wire scan_clk, //멀티플렉싱용 신호(cat)
    input  wire [3:0] w3, //분 10의자리
    input  wire [3:0] w2, //분 1의자리
    input  wire [3:0] w1, //초 10의자리
    input  wire [3:0] w0, //초 1의자리
    output wire [7:0] pmod_a, //top모듈에
    output wire [7:0] pmod_b
);

    //top모듈에서 div_clk을 통해 멀티플렉싱용 신호를 따로 만들어서 이용

    // 순서 pmod_x = {CAT, g, f, e, d, c, b, a}
    wire [3:0] digit_a;
    wire [3:0] digit_b;
    reg [6:0] seg_a; //7세그먼트 변환값
    reg [6:0] seg_b;

    //위에서 언급한 scan_clk이용하여 왼쪽/오른쪽 7세그먼트 동시 제어
    assign digit_a = (scan_clk == 1'b0) ? w0 : w1;
    assign digit_b = (scan_clk == 1'b0) ? w2 : w3;

    always @ (*) begin
        case(digit_a) //
            4'd0: seg_a = 7'b0111111;   // a,b,c,d,e,f
            4'd1: seg_a = 7'b0000110;   // b,c
            4'd2: seg_a = 7'b1011011;   // a,b,d,e,g
            4'd3: seg_a = 7'b1001111;   // a,b,c,d,g
            4'd4: seg_a = 7'b1100110;   // b,c,f,g
            4'd5: seg_a = 7'b1101101;   // a,c,d,f,g
            4'd6: seg_a = 7'b1111101;   // a,c,d,e,f,g
            4'd7: seg_a = 7'b0000111;   // a,b,c
            4'd8: seg_a = 7'b1111111;   // 전부
            4'd9: seg_a = 7'b1101111;   // a,b,c,d,f,g
            default: seg_a = 7'b1000000; // - 모양
        endcase
    end

    always @ (*) begin
        case(digit_b)
            4'd0: seg_b = 7'b0111111;
            4'd1: seg_b = 7'b0000110;
            4'd2: seg_b = 7'b1011011;
            4'd3: seg_b = 7'b1001111;
            4'd4: seg_b = 7'b1100110;
            4'd5: seg_b = 7'b1101101;
            4'd6: seg_b = 7'b1111101;
            4'd7: seg_b = 7'b0000111;
            4'd8: seg_b = 7'b1111111;
            4'd9: seg_b = 7'b1101111;
            default: seg_b = 7'b1000000;
        endcase
    end


    assign pmod_a = {scan_clk, seg_a}; //scan_clk이 CAT신호로 사용
    assign pmod_b = {scan_clk, seg_b};

endmodule