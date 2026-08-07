module DWC_baseline (
    input  logic               clk,
    input  logic               rst_n,
    input  logic               start,
    output logic               done,
    output logic               result_valid,
    output logic signed [15:0] result
);

    // 최소 debug probe: behavioral에서 파이프 정렬을 확인하고,
    // post-synthesis에서도 핵심 제어/좌표 이름이 유지되도록 한다.
    (* keep = "true" *) logic active, data_valid_d1, data_valid;

    (* keep = "true" *) logic [8:0] channel, channel_d1, channel_d;

    (* keep = "true" *) logic [3:0] row, col, row_d1, col_d1, row_d, col_d;
    (* keep = "true" *) logic [3:0] weight_index, weight_index_d1, weight_index_d;
    (* keep = "true" *) logic weight_valid_d1, weight_valid_d;

    (* keep = "true" *) logic [16:0] input_addr;
    (* keep = "true" *) logic [11:0] weight_addr;
    (* keep = "true" *) logic signed [15:0] input_bram_data, weight_bram_data;

    // line[1], line[0], 현재 입력을 합치면 세로로 3개 행이 만들어짐
    (* keep = "true" *) logic signed [15:0] line [0:1][0:13];

    // shift에는 왼쪽 두 열을 저장하고, current에는 현재 열이 들어감
    (* keep = "true" *) logic signed [15:0] shift       [0:2][0:1];
    (* keep = "true" *) logic signed [15:0] current     [0:2];
    (* keep = "true" *) logic signed [15:0] window_data [0:8];
    (* keep = "true" *) logic signed [15:0] weight_data [0:8];

    // DSP의 PCOUT을 다음 DSP의 PCIN으로 넘기기 위한 선
    (* keep = "true" *) logic signed [47:0] cascade [0:7];
    (* keep = "true" *) logic signed [47:0] dsp_sum_comb, dsp_sum;

    // DSP AREG 2단 + MREG 1단 + cascade 출력 레지스터 1단
    localparam int RESULT_LATENCY = 4;

    (* keep = "true" *) logic window_valid, window_last;
    (* keep = "true" *) logic [RESULT_LATENCY-1:0] result_valid_pipe, done_pipe;



    // ------------------------------------------------------------------------
    // 1. 동작 제어와 15x15 스캔 좌표 생성
    // ------------------------------------------------------------------------

    // start는 한 클럭만 들어오므로 active에 전체 연산 상태를 기억함
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            active <= 1'b0;
        else if (start && !active)
            active <= 1'b1;
        else if (active && channel == 383 && row == 14 && col == 14)
            active <= 1'b0;
    end




    // 입력 BRAM의 채널, 행, 열 주소를 순서대로 올려줌
    // 14번 행과 열은 실제 입력이 아니라 아래쪽, 오른쪽 padding을 만들기 위한 좌표임
    always_ff @(posedge clk) begin
        if (start && !active) begin
            channel <= 0;
            row     <= 0;
            col     <= 0;
        end
        else if (active) begin
            if (col == 14) begin
                col <= 0;

                if (row == 14) begin
                    row <= 0;
                    if (channel != 383)
                        channel <= channel + 1'b1;
                end

                else begin
                    row <= row + 1'b1;
                end
            end

            else begin
                col <= col + 1'b1;
            end
        end
    end



    // ------------------------------------------------------------------------
    // 2. 입력/weight 주소 생성과 BRAM 읽기
    // ------------------------------------------------------------------------

    // 입력은 CHW 순서: 채널마다 14x14 = 196개
    // 가상 padding 좌표에서는 BRAM 범위를 벗어나지 않도록 채널의 첫 주소로 고정함
    assign input_addr = channel * 196
                      + ((row < 14 && col < 14) ? row * 14 + col : 0);

    // weight는 채널마다 3x3 = 9개
    // 9개를 모두 읽은 뒤에는 index 9 대신 현재 채널의 weight 0 주소를 유지함
    assign weight_addr = channel * 9
                       + ((weight_index < 9) ? weight_index : 0);

    // pointwise 결과가 들어있는 입력 BRAM
    blk_mem_gen_2 input_buffer (
        .clka(clk), .ena(1'b0), .wea(1'b0), .addra('0), .dina('0),
        .clkb(clk), .enb(1'b1), .addrb(input_addr), .doutb(input_bram_data)
    );

    // 채널마다 3x3 weight 9개가 들어있는 ROM
    blk_mem_gen_3 weight_buffer (
        .clka(clk), .ena(1'b1), .addra(weight_addr), .douta(weight_bram_data)
    );


    // ------------------------------------------------------------------------
    // 3. 입력 BRAM 데이터와 좌표 정렬
    // ------------------------------------------------------------------------

    // 지금 BRAM은 출력 레지스터가 켜져있어서 데이터가 두 클럭 뒤에 나옴
    // 그래서 좌표도 d1, d 순서로 두 클럭 미뤄서 데이터랑 맞춰줌
    // valid는 쓰기를 제어하는 신호이므로 reset하고, 좌표 지연값은 reset하지 않음
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            {data_valid, data_valid_d1} <= '0;
        else
            {data_valid, data_valid_d1} <= {data_valid_d1, active};
    end

    always_ff @(posedge clk) begin
        if (active) begin
            channel_d1 <= channel;
            row_d1     <= row;
            col_d1     <= col;
        end

        if (data_valid_d1) begin
            channel_d <= channel_d1;
            row_d     <= row_d1;
            col_d     <= col_d1;
        end
    end




    // ------------------------------------------------------------------------
    // 4. 현재 채널의 weight 9개 미리 읽기
    // ------------------------------------------------------------------------

    // 현재 채널의 weight 9개 주소를 0부터 8까지 넣어줌
    // weight도 두 클럭 뒤에 나오므로 index와 valid를 같이 미뤄줌
    // 지연 index 자체는 초기화하지 않고 valid가 0일 때 사용하지 않음
    always_ff @(posedge clk) begin
        if ((start && !active) || (active && row == 14 && col == 14)) begin
            weight_index    <= 0;
            weight_valid_d1 <= 1'b0;
            weight_valid_d <= 1'b0;
        end
        else if (active) begin
            weight_index_d <= weight_index_d1;
            weight_valid_d <= weight_valid_d1;

            if (weight_index < 9) begin
                weight_index_d1 <= weight_index;
                weight_index    <= weight_index + 1'b1;
                weight_valid_d1 <= 1'b1;
            end
            else begin
                weight_valid_d1 <= 1'b0;
            end
        end
    end





    // BRAM에서 하나씩 나온 weight를 9개 배열에 모아둠
    // 그래야 DSP 9개에 weight 9개를 동시에 넣을 수 있음
    always_ff @(posedge clk) begin
        if (active && weight_valid_d)
            weight_data[weight_index_d] <= weight_bram_data;
    end



    // ------------------------------------------------------------------------
    // 5. Line buffer와 shift register로 3x3 window 생성
    // ------------------------------------------------------------------------

    // 현재 열의 세로 3개를 고르고, 경계 밖이면 여기서 0을 넣어줌
    // shift의 이전 두 열과 current의 현재 열을 합쳐 window_data[0:8]을 만듦
    always_comb begin
        current[0] = (row_d < 2 || col_d == 14) ? 0 : line[1][col_d];
        current[1] = (row_d < 1 || col_d == 14) ? 0 : line[0][col_d];
        current[2] = (row_d == 14 || col_d == 14) ? 0 : input_bram_data;

        for (int i = 0; i < 3; i++) begin
            window_data[i*3]   = shift[i][1];
            window_data[i*3+1] = shift[i][0];
            window_data[i*3+2] = current[i];
        end
    end

    // row/col 0은 line/shift를 채우는 준비 구간이고, 1~14만 실제 14x14 출력임
    assign window_valid = data_valid && (row_d != 0) && (col_d != 0);
    assign window_last  = window_valid
                        && (channel_d == 383)
                        && (row_d == 14)
                        && (col_d == 14);




    // 실제 입력만 line buffer에 저장하고 padding 0은 저장하지 않음
    always_ff @(posedge clk) begin
        if (data_valid && row_d != 14 && col_d != 14) begin
            line[1][col_d] <= line[0][col_d];
            line[0][col_d] <= input_bram_data;
        end
    end



    // 세 행에서 각각 왼쪽 두 픽셀만 기억해둠
    // 한 행이 끝나면 다음 행의 왼쪽 padding을 위해 0으로 비워줌
    always_ff @(posedge clk) begin
        if ((start && !active) || (data_valid && col_d == 14)) begin
            for (int i = 0; i < 3; i++) begin
                shift[i][0] <= 0;
                shift[i][1] <= 0;
            end
        end
        else if (data_valid) begin
            for (int i = 0; i < 3; i++) begin
                shift[i][1] <= shift[i][0];
                shift[i][0] <= current[i];
            end
        end
    end


    // ------------------------------------------------------------------------
    // 6. DSP 9개로 3x3 곱셈 누적
    // ------------------------------------------------------------------------

    // 첫 번째 DSP는 PCIN 없이 A*B만 계산하고 PCOUT을 다음 DSP에 전달함
    // dsp_macro_1의 A/B는 window/weight와 동일한 signed 16비트
    dsp_macro_1 dsp_0 (
        .CLK   (clk),
        .A     (window_data[0]),
        .B     (weight_data[0]),
        .PCOUT (cascade[0]),
        .P     ()
    );

    // 두 번째 DSP부터 앞 DSP의 PCOUT을 받아 A*B 결과에 계속 더함
    dsp_macro_0 dsp_1 (.CLK(clk), .PCIN(cascade[0]), .A(window_data[1]), .B(weight_data[1]), .PCOUT(cascade[1]), .P());
    dsp_macro_0 dsp_2 (.CLK(clk), .PCIN(cascade[1]), .A(window_data[2]), .B(weight_data[2]), .PCOUT(cascade[2]), .P());
    dsp_macro_0 dsp_3 (.CLK(clk), .PCIN(cascade[2]), .A(window_data[3]), .B(weight_data[3]), .PCOUT(cascade[3]), .P());
    dsp_macro_0 dsp_4 (.CLK(clk), .PCIN(cascade[3]), .A(window_data[4]), .B(weight_data[4]), .PCOUT(cascade[4]), .P());
    dsp_macro_0 dsp_5 (.CLK(clk), .PCIN(cascade[4]), .A(window_data[5]), .B(weight_data[5]), .PCOUT(cascade[5]), .P());
    dsp_macro_0 dsp_6 (.CLK(clk), .PCIN(cascade[5]), .A(window_data[6]), .B(weight_data[6]), .PCOUT(cascade[6]), .P());
    dsp_macro_0 dsp_7 (.CLK(clk), .PCIN(cascade[6]), .A(window_data[7]), .B(weight_data[7]), .PCOUT(cascade[7]), .P());
    dsp_macro_0 dsp_8 (.CLK(clk), .PCIN(cascade[7]), .A(window_data[8]), .B(weight_data[8]), .PCOUT(),           .P(dsp_sum_comb));

    // 9개 DSP cascade가 모두 안정된 뒤 한 번만 등록한다.
    // 데이터 레지스터이므로 reset하지 않고 result_valid로 유효 구간을 구분한다.
    always_ff @(posedge clk) begin
        dsp_sum <= dsp_sum_comb;
    end

    // AREG 2단 + MREG 1단 + 출력 레지스터 1단에 맞춰 valid와 last도 4클럭 지연
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            result_valid_pipe <= '0;
            done_pipe         <= '0;
        end
        else begin
            result_valid_pipe <= {result_valid_pipe[RESULT_LATENCY-2:0], window_valid};
            done_pipe         <= {done_pipe[RESULT_LATENCY-2:0], window_last};
        end
    end


    // ------------------------------------------------------------------------
    // 7. 결과와 완료 신호
    // ------------------------------------------------------------------------

    // 구현했을 때 DSP가 없어지지 않도록 최종 결과의 상위 16비트만 밖으로 뺌
    assign result = dsp_sum[47:32];

    assign result_valid = result_valid_pipe[RESULT_LATENCY-1];
    assign done         = done_pipe[RESULT_LATENCY-1];

endmodule
