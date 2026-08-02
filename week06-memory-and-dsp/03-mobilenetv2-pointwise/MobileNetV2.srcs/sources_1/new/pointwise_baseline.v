`timescale 1ns/1ps

module pointwise_baseline (
    // 제어 신호
    input  wire                     clk,
    input  wire                     rst_n,
    input  wire                     start,
    output reg                      busy,
    output reg                      done,

    // 포인트와이즈 누산 결과: 부호 있는 48비트, 소수부 24비트
    output reg  [16:0]              out_addr,
    output reg  signed [47:0]       out_acc,
    output reg                      out_valid
    );

    localparam [8:0] LAST_OUT_CHANNEL = 9'd383;
    localparam [7:0] LAST_PIXEL       = 8'd195;
    localparam [5:0] LAST_IN_CHANNEL  = 6'd63;
    localparam [16:0] LAST_OUT_ADDR   = 17'd75263;

    // DSP 입력 후 P 출력까지 3클럭 지연
    // P 출력 레지스터 저장용 1클럭 포함
    localparam integer DSP_RESULT_DELAY = 4;

    // 연산 순서 카운터
    reg [8:0] out_channel_count;
    reg [7:0] pixel_count;
    reg [5:0] in_channel_count;

    // Layer7 입력 RAM 읽기 신호: 부호 있는 16비트, 소수부 11비트
    reg  [13:0] input_addr;
    reg         input_rd_en;
    wire signed [15:0] input_data;

    // Layer8 가중치 ROM 읽기 신호: 부호 있는 16비트, 소수부 13비트
    reg  [14:0] weight_addr;
    reg  [14:0] weight_base_addr;
    reg         weight_rd_en;
    wire signed [15:0] weight_data;

    // 마지막 주소 요청 후 남은 데이터 출력을 위해
    // BRAM 활성 신호 1클럭 추가 유지
    reg read_issue_active;

    // 계산 완료된 출력 개수
    reg [16:0] result_count;

    // BRAM과 ROM의 읽기 지연에 맞춘 채널 시작/끝 신호
    reg        first_channel_d1;
    reg        first_channel_d2;
    reg        last_channel_d1;
    reg        last_channel_d2;

    // DSP 결과 시점에 맞춘 마지막 채널 신호 지연
    reg [DSP_RESULT_DELAY-1:0] last_channel_pipe;

    // 첫 채널 곱셈, 이후 채널 누산
    wire [0:0] dsp_sel;
    wire signed [47:0] dsp_result;

    // 입력 RAM COE 초기화, 쓰기 포트 미사용
    blk_mem_gen_0 u_input_sdp_ram (
        .clka  (clk),
        .ena   (1'b0),
        .wea   (1'b0),
        .addra (14'd0),
        .dina  (16'd0),
        .clkb  (clk),
        .enb   (input_rd_en),
        .addrb (input_addr),
        .doutb (input_data)
    );

    blk_mem_gen_1 u_weight_rom (
        .clka  (clk),
        .ena   (weight_rd_en),
        .addra (weight_addr),
        .douta (weight_data)
    );

    assign dsp_sel[0] = first_channel_d2 ? 1'b0 : 1'b1;

    dsp_macro_0 u_pointwise_mac (
        .CLK  (clk),
        .CE   (busy),
        .SCLR (~rst_n),
        .SEL  (dsp_sel),
        .A    (input_data),
        .B    (weight_data),
        .P    (dsp_result)
    );

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            busy                <= 1'b0;
            done                <= 1'b0;
            out_addr            <= 17'd0;
            out_acc             <= 48'sd0;
            out_valid           <= 1'b0;

            out_channel_count   <= 9'd0;
            pixel_count         <= 8'd0;
            in_channel_count    <= 6'd0;

            input_addr          <= 14'd0;
            input_rd_en         <= 1'b0;
            weight_addr         <= 15'd0;
            weight_base_addr    <= 15'd0;
            weight_rd_en        <= 1'b0;
            read_issue_active   <= 1'b0;
            result_count        <= 17'd0;

            first_channel_d1    <= 1'b0;
            first_channel_d2    <= 1'b0;
            last_channel_d1     <= 1'b0;
            last_channel_d2     <= 1'b0;
            last_channel_pipe   <= {DSP_RESULT_DELAY{1'b0}};
        end

        else begin
            // done과 out_valid 1클럭 펄스 생성
            done      <= 1'b0;
            out_valid <= 1'b0;

            // 입력과 가중치 출력에 맞춰 채널 정보 2클럭 지연
            first_channel_d1 <= read_issue_active &&
                                (in_channel_count == 6'd0);
            first_channel_d2 <= first_channel_d1;
            last_channel_d1 <= read_issue_active &&
                               (in_channel_count == LAST_IN_CHANNEL);
            last_channel_d2 <= last_channel_d1;
            last_channel_pipe <= {last_channel_pipe[DSP_RESULT_DELAY-2:0],
                                  last_channel_d2};

            // 대기 상태에서만 start 수신
            if (!busy && start) begin
                busy                <= 1'b1;

                out_channel_count   <= 9'd0;
                pixel_count         <= 8'd0;
                in_channel_count    <= 6'd0;

                input_addr          <= 14'd0;
                input_rd_en         <= 1'b1;
                weight_addr         <= 15'd0;
                weight_base_addr    <= 15'd0;
                weight_rd_en        <= 1'b1;
                read_issue_active   <= 1'b1;
                result_count        <= 17'd0;

                first_channel_d1    <= 1'b0;
                first_channel_d2    <= 1'b0;
                last_channel_d1     <= 1'b0;
                last_channel_d2     <= 1'b0;
                last_channel_pipe   <= {DSP_RESULT_DELAY{1'b0}};
                out_addr            <= 17'd0;
                out_acc             <= 48'sd0;
            end

            if (busy) begin
                // 마지막 주소 요청 후 활성 신호 1클럭 추가 유지
                if (!read_issue_active &&
                    (input_rd_en || weight_rd_en)) begin
                    input_rd_en  <= 1'b0;
                    weight_rd_en <= 1'b0;
                end

                // 다음 입력 채널 주소 생성
                if (read_issue_active) begin
                    if (in_channel_count == LAST_IN_CHANNEL) begin
                        in_channel_count <= 6'd0;

                        if ((pixel_count == LAST_PIXEL) &&
                            (out_channel_count == LAST_OUT_CHANNEL)) begin
                            // 마지막 주소 요청 후 파이프라인 결과 대기
                            read_issue_active <= 1'b0;
                        end
                        else begin
                            if (pixel_count == LAST_PIXEL) begin
                                pixel_count       <= 8'd0;
                                out_channel_count <= out_channel_count + 1'b1;
                                input_addr        <= 14'd0;
                                weight_base_addr  <= weight_base_addr + 15'd64;
                                weight_addr       <= weight_base_addr + 15'd64;
                            end
                            else begin
                                pixel_count <= pixel_count + 1'b1;
                                input_addr  <= pixel_count + 1'b1;
                                weight_addr <= weight_base_addr;
                            end
                        end
                    end
                    else begin
                        in_channel_count <= in_channel_count + 1'b1;
                        input_addr       <= input_addr + 14'd196;
                        weight_addr      <= weight_addr + 1'b1;
                    end
                end

                // 입력 채널 64개 누산 완료 후 DSP 결과 출력
                if (last_channel_pipe[DSP_RESULT_DELAY-1]) begin
                    out_acc   <= dsp_result;
                    out_addr  <= result_count;
                    out_valid <= 1'b1;

                    if (result_count == LAST_OUT_ADDR) begin
                        busy         <= 1'b0;
                        done         <= 1'b1;
                        input_rd_en  <= 1'b0;
                        weight_rd_en <= 1'b0;
                        read_issue_active <= 1'b0;
                    end
                    else begin
                        result_count <= result_count + 1'b1;
                    end
                end
            end
        end
    end

endmodule
