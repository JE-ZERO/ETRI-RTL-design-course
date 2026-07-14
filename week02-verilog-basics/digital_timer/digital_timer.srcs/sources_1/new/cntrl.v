`timescale 1ns / 1ps

module ctrl(
    input clk,
    input bt_reset,
    input bt_mode,
    input done,
    output reg [1:0] mode_out
);

    parameter ST_IDLE = 4'b0000;
    parameter ST_T0   = 4'b0010;
    parameter ST_T1   = 4'b1010;
    parameter ST_T2   = 4'b1110;
    parameter ST_T3   = 4'b1111;
    parameter ST_DONE = 4'b0101;


    //edge detection _ mode
    reg bt_mode_d;
    wire mode;

    always @(posedge clk or posedge bt_reset) begin
        if(bt_reset) begin
            bt_mode_d <= 1'b0;
        end
        else begin
            bt_mode_d <= bt_mode;
        end
    end

    assign mode = ((bt_mode == 1'b1) && (bt_mode_d == 1'b0)) ? 1'b1 : 1'b0;


    //state
    reg [3:0] c_state, n_state;


    //current state logic
    always @(posedge clk or posedge bt_reset) begin
        if(bt_reset) begin
            c_state <= ST_IDLE;
        end
        else begin
            c_state <= n_state;
        end
    end


    //next state logic
    always @ (*) begin
        n_state = c_state;

        case(c_state)

            ST_IDLE: begin
                if(mode == 1'b1)
                    n_state = ST_T1; //수정: reset 후 mode 1번이면 초 10의 자리
            end

            ST_T0: begin
                if(done == 1'b1)
                    n_state = ST_DONE;
                else if(mode == 1'b1)
                    n_state = ST_T1;
            end

            ST_T1: begin
                if(done == 1'b1)
                    n_state = ST_DONE;
                else if(mode == 1'b1)
                    n_state = ST_T2; //mode 한 번 더 누르면 분 1의 자리
            end

            ST_T2: begin
                if(done == 1'b1)
                    n_state = ST_DONE;
                else if(mode == 1'b1)
                    n_state = ST_T3;
            end

            ST_T3: begin
                if(done == 1'b1)
                    n_state = ST_DONE;
                else if(mode == 1'b1)
                    n_state = ST_T0;
            end

            ST_DONE: begin
                n_state = ST_DONE; //DONE 상태는 reset으로만 빠져나감
            end

            default: begin
                n_state = ST_IDLE;
            end

        endcase
    end


    //output logic
    always @ (*) begin
        mode_out = 2'b00;

        case(c_state)

            ST_IDLE: begin
                mode_out = 2'b00;
            end

            ST_T0: begin
                mode_out = 2'b00; //초 1의 자리
            end

            ST_T1: begin
                mode_out = 2'b01; //초 10의 자리
            end

            ST_T2: begin
                mode_out = 2'b10; //분 1의 자리
            end

            ST_T3: begin
                mode_out = 2'b11; //분 10의 자리
            end

            ST_DONE: begin
                mode_out = 2'b00;
            end

            default: begin
                mode_out = 2'b00;
            end

        endcase
    end

endmodule`timescale 1ns / 1ps

module ctrl(
    input clk,
    input bt_reset,
    input bt_mode,
    input done,
    output reg [1:0] mode_out
);

    parameter ST_IDLE = 4'b0000;
    parameter ST_T0   = 4'b0010;
    parameter ST_T1   = 4'b1010;
    parameter ST_T2   = 4'b1110;
    parameter ST_T3   = 4'b1111;
    parameter ST_DONE = 4'b0101;


    //edge detection _ mode
    reg bt_mode_d;
    wire mode;

    always @(posedge clk or posedge bt_reset) begin
        if(bt_reset) begin
            bt_mode_d <= 1'b0;
        end
        else begin
            bt_mode_d <= bt_mode;
        end
    end

    assign mode = ((bt_mode == 1'b1) && (bt_mode_d == 1'b0)) ? 1'b1 : 1'b0;


    //state
    reg [3:0] c_state, n_state;


    //current state logic
    always @(posedge clk or posedge bt_reset) begin
        if(bt_reset) begin
            c_state <= ST_IDLE;
        end
        else begin
            c_state <= n_state;
        end
    end


    //next state logic
    always @ (*) begin
        n_state = c_state;

        case(c_state)

            ST_IDLE: begin
                if(mode == 1'b1)
                    n_state = ST_T1; //수정: reset 후 mode 1번이면 초 10의 자리
            end

            ST_T0: begin
                if(done == 1'b1)
                    n_state = ST_DONE;
                else if(mode == 1'b1)
                    n_state = ST_T1;
            end

            ST_T1: begin
                if(done == 1'b1)
                    n_state = ST_DONE;
                else if(mode == 1'b1)
                    n_state = ST_T2; //mode 한 번 더 누르면 분 1의 자리
            end

            ST_T2: begin
                if(done == 1'b1)
                    n_state = ST_DONE;
                else if(mode == 1'b1)
                    n_state = ST_T3;
            end

            ST_T3: begin
                if(done == 1'b1)
                    n_state = ST_DONE;
                else if(mode == 1'b1)
                    n_state = ST_T0;
            end

            ST_DONE: begin
                n_state = ST_DONE; //DONE 상태는 reset으로만 빠져나감
            end

            default: begin
                n_state = ST_IDLE;
            end

        endcase
    end


    //output logic
    always @ (*) begin
        mode_out = 2'b00;

        case(c_state)

            ST_IDLE: begin
                mode_out = 2'b00;
            end

            ST_T0: begin
                mode_out = 2'b00; //초 1의 자리
            end

            ST_T1: begin
                mode_out = 2'b01; //초 10의 자리
            end

            ST_T2: begin
                mode_out = 2'b10; //분 1의 자리
            end

            ST_T3: begin
                mode_out = 2'b11; //분 10의 자리
            end

            ST_DONE: begin
                mode_out = 2'b00;
            end

            default: begin
                mode_out = 2'b00;
            end

        endcase
    end

endmodule