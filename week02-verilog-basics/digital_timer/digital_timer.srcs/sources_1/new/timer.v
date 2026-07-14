`timescale 1ns / 1ps

module timer(
    input clk,
    input signal,          //1초 tick pulse
    input rst,
    input start,
    input [3:0] num,
    input [1:0] mode,
    input set_en,
    output reg done,
    output wire [3:0] w3,
    output wire [3:0] w2,
    output wire [3:0] w1,
    output wire [3:0] w0
    );
    
    reg [3:0] cnt_t_0; //초 1의 자리
    reg [3:0] cnt_t_1; //초 10의 자리
    reg [3:0] cnt_t_2; //분 1의 자리
    reg [3:0] cnt_t_3; //분 10의 자리

    reg run;

    reg start_d;
    wire start_pulse;

    wire is_zero;
    wire is_one;


    assign is_zero = (cnt_t_3 == 4'd0 && cnt_t_2 == 4'd0 &&
                      cnt_t_1 == 4'd0 && cnt_t_0 == 4'd0);

    assign is_one = (cnt_t_3 == 4'd0 && cnt_t_2 == 4'd0 &&
                     cnt_t_1 == 4'd0 && cnt_t_0 == 4'd1);


    //edge detection _ start
    always @(posedge clk or posedge rst) begin
        if(rst) begin
            start_d <= 1'b0;
        end
        else begin
            start_d <= start;
        end
    end

    assign start_pulse = ((start == 1'b1) && (start_d == 1'b0)) ? 1'b1 : 1'b0;


    //timer logic
    always @(posedge clk or posedge rst) begin
        if(rst) begin
            cnt_t_0 <= 4'd0;
            cnt_t_1 <= 4'd0;
            cnt_t_2 <= 4'd0;
            cnt_t_3 <= 4'd0;

            run  <= 1'b0;
            done <= 1'b0;
        end

        //setting 상태
        //run이 0일 때만 숫자 설정 가능
        else if(run == 1'b0 && set_en == 1'b1) begin
            done <= 1'b0;

            case(mode)
                2'b00: cnt_t_0 <= num; //초 1의 자리
                2'b01: cnt_t_1 <= num; //초 10의 자리
                2'b10: cnt_t_2 <= num; //분 1의 자리
                2'b11: cnt_t_3 <= num; //분 10의 자리
                default: begin
                    cnt_t_0 <= cnt_t_0;
                    cnt_t_1 <= cnt_t_1;
                    cnt_t_2 <= cnt_t_2;
                    cnt_t_3 <= cnt_t_3;
                end
            endcase
        end

        //start
        else if(start_pulse == 1'b1 && is_zero == 1'b0) begin
            run  <= 1'b1;
            done <= 1'b0;
        end

        //countdown
        else if(run == 1'b1 && signal == 1'b1) begin

            if(is_zero == 1'b1) begin
                run  <= 1'b0;
                done <= 1'b1;
            end

            else if(is_one == 1'b1) begin
                cnt_t_0 <= 4'd0;
                cnt_t_1 <= 4'd0;
                cnt_t_2 <= 4'd0;
                cnt_t_3 <= 4'd0;

                run  <= 1'b0;
                done <= 1'b1;
            end

            else if(cnt_t_0 != 4'd0) begin
                cnt_t_0 <= cnt_t_0 - 4'd1;
                done <= 1'b0;
            end

            else begin
                cnt_t_0 <= 4'd9;

                if(cnt_t_1 != 4'd0) begin
                    cnt_t_1 <= cnt_t_1 - 4'd1;
                end
                else begin
                    cnt_t_1 <= 4'd5;

                    if(cnt_t_2 != 4'd0) begin
                        cnt_t_2 <= cnt_t_2 - 4'd1;
                    end
                    else begin
                        cnt_t_2 <= 4'd9;

                        if(cnt_t_3 != 4'd0) begin
                            cnt_t_3 <= cnt_t_3 - 4'd1;
                        end
                    end
                end

                done <= 1'b0;
            end
        end
    end


    assign w0 = cnt_t_0;
    assign w1 = cnt_t_1;
    assign w2 = cnt_t_2;
    assign w3 = cnt_t_3;

endmodule