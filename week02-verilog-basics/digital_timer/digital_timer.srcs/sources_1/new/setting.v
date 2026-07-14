`timescale 1ns / 1ps

module setting(
    input wire clk,
    input wire rst,
    input wire bt_set,
    input wire [1:0] mode,
    output reg [3:0] num_led
    );

    reg bt_set_d;
    wire set;

    reg [1:0] mode_d;


    //edge detection _ setting
    always @(posedge clk or posedge rst) begin
        if(rst) begin
            bt_set_d <= 1'b0;
        end
        else begin
            bt_set_d <= bt_set;
        end
    end

    assign set = ((bt_set == 1'b1) && (bt_set_d == 1'b0)) ? 1'b1 : 1'b0;


    //setting logic
    always @(posedge clk or posedge rst) begin
        if(rst) begin
            mode_d  <= 2'b00;
            num_led <= 4'd0;
        end
        else begin
            mode_d <= mode;

            if(mode != mode_d) begin
                num_led <= 4'd0; //수정: 자리가 바뀌면 입력 숫자 초기화
            end
            else if(set) begin
                case(mode)

                    2'b00: begin //초 1의 자리, 0~9
                        if(num_led == 4'd9)
                            num_led <= 4'd0;
                        else
                            num_led <= num_led + 4'd1;
                    end

                    2'b01: begin //초 10의 자리, 0~5
                        if(num_led == 4'd5)
                            num_led <= 4'd0;
                        else
                            num_led <= num_led + 4'd1;
                    end

                    2'b10: begin //분 1의 자리, 0~9
                        if(num_led == 4'd9)
                            num_led <= 4'd0;
                        else
                            num_led <= num_led + 4'd1;
                    end

                    2'b11: begin //분 10의 자리, 0~5
                        if(num_led == 4'd5)
                            num_led <= 4'd0;
                        else
                            num_led <= num_led + 4'd1;
                    end

                    default: begin
                        num_led <= num_led;
                    end

                endcase
            end
        end
    end

endmodule