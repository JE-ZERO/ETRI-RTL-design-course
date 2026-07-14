`timescale 1ns / 1ps

module top(
    input wire clk,
    input wire bt_start,
    input wire bt_mode,
    input wire bt_reset,
    input wire bt_setting,
    output wire [7:0] pmod_a,
    output wire [7:0] pmod_b
    );
    
    wire signal_div;
    reg signal_div_d;
    wire signal; //1초 tick pulse

    wire [3:0] num;
    wire [1:0] mode;

    wire [3:0] w3;
    wire [3:0] w2;
    wire [3:0] w1;
    wire [3:0] w0;

    wire done;
    wire scan_clk;

    reg bt_setting_d;
    reg setting_edge_d;
    wire setting_edge;
    wire timer_set_en;


    //timer용 분주기
    clk_div #(.PERIOD(20_000_000)) 
    u0(
        .clk(clk),
        .rst(bt_reset), 
        .clk_out(signal_div)
    );


    //signal_div를 1clk pulse로 변환
    always @(posedge clk or posedge bt_reset) begin
        if(bt_reset) begin
            signal_div_d <= 1'b0;
        end
        else begin
            signal_div_d <= signal_div;
        end
    end

    assign signal = ((signal_div == 1'b1) && (signal_div_d == 1'b0)) ? 1'b1 : 1'b0;


    //display용 분주기
    clk_div #(.PERIOD(20_000)) 
    u1(
        .clk(clk),
        .rst(bt_reset), 
        .clk_out(scan_clk)
    );


    //controller
    ctrl u2(
        .clk(clk),  
        .bt_reset(bt_reset), 
        .bt_mode(bt_mode), 
        .done(done), 
        .mode_out(mode)
    );


    //display output
    display_output u3(
        .scan_clk(scan_clk), 
        .w3(w3), 
        .w2(w2), 
        .w1(w1), 
        .w0(w0), 
        .pmod_a(pmod_a), 
        .pmod_b(pmod_b)
    );


    //setting
    setting u4(
        .clk(clk), 
        .rst(bt_reset), 
        .bt_set(bt_setting), 
        .mode(mode), 
        .num_led(num)
    );


    //bt_setting edge를 1clk 늦춰서 timer set_en으로 사용
    //이유: setting에서 num_led가 증가된 다음 clock에 timer가 저장해야 함
    always @(posedge clk or posedge bt_reset) begin
        if(bt_reset) begin
            bt_setting_d   <= 1'b0;
            setting_edge_d <= 1'b0;
        end
        else begin
            bt_setting_d   <= bt_setting;
            setting_edge_d <= setting_edge;
        end
    end

    assign setting_edge = ((bt_setting == 1'b1) && (bt_setting_d == 1'b0)) ? 1'b1 : 1'b0;
    assign timer_set_en = setting_edge_d;


    //timer
    timer u5(
        .clk(clk), 
        .signal(signal), 
        .rst(bt_reset), 
        .start(bt_start), 
        .num(num), 
        .mode(mode),
        .set_en(timer_set_en),
        .done(done), 
        .w3(w3), 
        .w2(w2), 
        .w1(w1), 
        .w0(w0)
    ); 
    
endmodule