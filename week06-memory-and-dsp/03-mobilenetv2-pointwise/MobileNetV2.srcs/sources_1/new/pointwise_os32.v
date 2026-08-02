`timescale 1ns/1ps

module pointwise_os32 (
    input wire clk, input wire rst_n, input wire start,
    output reg busy, output reg done,
    output reg [16:0] out_addr,
    output reg signed [47:0] out_acc,
    output reg out_valid
    );

    localparam integer PARALLEL_OUT = 32;
    localparam [3:0] LAST_OUT_GROUP = 4'd11;
    localparam [7:0] LAST_PIXEL = 8'd195;
    localparam [5:0] LAST_IN_CHANNEL = 6'd63;
    localparam [16:0] LAST_RESULT = 17'd75263;
    localparam integer DSP_RESULT_DELAY = 4;

    reg [3:0] out_group_count;
    reg [7:0] pixel_count;
    reg [5:0] in_channel_count;
    reg [13:0] input_addr;
    reg input_rd_en;
    wire signed [15:0] input_data;
    reg [9:0] weight_addr;
    reg [9:0] weight_base_addr;
    reg weight_rd_en;
    wire [511:0] weight_data;

    reg read_issue_active;
    reg first_channel_d1, first_channel_d2;
    reg last_channel_d1, last_channel_d2;
    reg [DSP_RESULT_DELAY-1:0] last_channel_pipe;

    wire [0:0] dsp_sel;
    wire signed [15:0] weight_lane [0:PARALLEL_OUT-1];
    wire signed [47:0] dsp_result [0:PARALLEL_OUT-1];
    reg signed [47:0] result_buffer [0:PARALLEL_OUT-1];

    reg [4:0] serialize_lane;
    reg serialize_active;
    reg [3:0] buffer_out_group;
    reg [7:0] buffer_pixel;
    reg [3:0] capture_out_group;
    reg [7:0] capture_pixel;
    reg [16:0] result_count;

    wire [8:0] serialize_out_channel;
    wire [16:0] serialize_out_channel_ext;
    wire [16:0] serialize_channel_offset;
    integer i;
    genvar lane;

    blk_mem_gen_0 u_input_sdp_ram (
        .clka(clk), .ena(1'b0), .wea(1'b0),
        .addra(14'd0), .dina(16'd0),
        .clkb(clk), .enb(input_rd_en),
        .addrb(input_addr), .doutb(input_data)
    );

    blk_mem_gen_2 u_weight_rom_os32 (
        .clka(clk), .ena(weight_rd_en),
        .addra(weight_addr), .douta(weight_data)
    );

    assign dsp_sel[0] = first_channel_d2 ? 1'b0 : 1'b1;

    generate
        for (lane = 0; lane < PARALLEL_OUT; lane = lane + 1) begin : g_mac
            assign weight_lane[lane] = weight_data[(16*lane) +: 16];
            dsp_macro_0 u_mac (
                .CLK(clk), .CE(busy), .SCLR(~rst_n), .SEL(dsp_sel),
                .A(input_data), .B(weight_lane[lane]), .P(dsp_result[lane])
            );
        end
    endgenerate

    // CHW 출력 주소 계산: 출력 채널×196 + 픽셀
    // 196배 연산을 128+64+4의 시프트와 덧셈으로 처리
    assign serialize_out_channel = {buffer_out_group, 5'b0} + serialize_lane;
    assign serialize_out_channel_ext = {{8{1'b0}}, serialize_out_channel};
    assign serialize_channel_offset =
        (serialize_out_channel_ext << 7) +
        (serialize_out_channel_ext << 6) +
        (serialize_out_channel_ext << 2);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            busy <= 1'b0;
            done <= 1'b0;
            out_addr <= 17'd0;
            out_acc <= 48'sd0;
            out_valid <= 1'b0;

            out_group_count <= 4'd0;
            pixel_count <= 8'd0;
            in_channel_count <= 6'd0;
            input_addr <= 14'd0;
            input_rd_en <= 1'b0;
            weight_addr <= 10'd0;
            weight_base_addr <= 10'd0;
            weight_rd_en <= 1'b0;
            read_issue_active <= 1'b0;

            first_channel_d1 <= 1'b0;
            first_channel_d2 <= 1'b0;
            last_channel_d1 <= 1'b0;
            last_channel_d2 <= 1'b0;
            last_channel_pipe <= {DSP_RESULT_DELAY{1'b0}};

            serialize_lane <= 5'd0;
            serialize_active <= 1'b0;
            buffer_out_group <= 4'd0;
            buffer_pixel <= 8'd0;
            capture_out_group <= 4'd0;
            capture_pixel <= 8'd0;
            result_count <= 17'd0;
        end
        else begin
            done <= 1'b0;
            out_valid <= 1'b0;

            // BRAM 읽기 지연에 맞춰 채널 정보 2클럭 지연
            first_channel_d1 <= read_issue_active &&
                                (in_channel_count == 6'd0);
            first_channel_d2 <= first_channel_d1;
            last_channel_d1 <= read_issue_active &&
                               (in_channel_count == LAST_IN_CHANNEL);
            last_channel_d2 <= last_channel_d1;
            last_channel_pipe <= {last_channel_pipe[DSP_RESULT_DELAY-2:0],
                                  last_channel_d2};

            if (!busy && start) begin
                busy <= 1'b1;
                out_group_count <= 4'd0;
                pixel_count <= 8'd0;
                in_channel_count <= 6'd0;
                input_addr <= 14'd0;
                input_rd_en <= 1'b1;
                weight_addr <= 10'd0;
                weight_base_addr <= 10'd0;
                weight_rd_en <= 1'b1;
                read_issue_active <= 1'b1;

                first_channel_d1 <= 1'b0;
                first_channel_d2 <= 1'b0;
                last_channel_d1 <= 1'b0;
                last_channel_d2 <= 1'b0;
                last_channel_pipe <= {DSP_RESULT_DELAY{1'b0}};
                serialize_lane <= 5'd0;
                serialize_active <= 1'b0;
                capture_out_group <= 4'd0;
                capture_pixel <= 8'd0;
                result_count <= 17'd0;
                out_addr <= 17'd0;
                out_acc <= 48'sd0;
            end

            if (busy) begin
                // 마지막 주소 요청 후 BRAM 활성 신호 1클럭 추가 유지
                if (!read_issue_active &&
                    (input_rd_en || weight_rd_en)) begin
                    input_rd_en <= 1'b0;
                    weight_rd_en <= 1'b0;
                end

                // 매 클럭 입력 주소와 묶음 가중치 주소 요청
                if (read_issue_active) begin
                    if (in_channel_count == LAST_IN_CHANNEL) begin
                        in_channel_count <= 6'd0;

                        if ((pixel_count == LAST_PIXEL) &&
                            (out_group_count == LAST_OUT_GROUP)) begin
                            read_issue_active <= 1'b0;
                        end
                        else if (pixel_count == LAST_PIXEL) begin
                            pixel_count <= 8'd0;
                            out_group_count <= out_group_count + 1'b1;
                            input_addr <= 14'd0;
                            weight_base_addr <= weight_base_addr + 10'd64;
                            weight_addr <= weight_base_addr + 10'd64;
                        end
                        else begin
                            pixel_count <= pixel_count + 1'b1;
                            input_addr <= pixel_count + 1'b1;
                            weight_addr <= weight_base_addr;
                        end
                    end
                    else begin
                        in_channel_count <= in_channel_count + 1'b1;
                        input_addr <= input_addr + 14'd196;
                        weight_addr <= weight_addr + 1'b1;
                    end
                end

                // 64클럭마다 출력 32개 계산 완료
                if (last_channel_pipe[DSP_RESULT_DELAY-1]) begin
                    for (i = 0; i < PARALLEL_OUT; i = i + 1)
                        result_buffer[i] <= dsp_result[i];

                    buffer_out_group <= capture_out_group;
                    buffer_pixel <= capture_pixel;
                    serialize_lane <= 5'd0;
                    serialize_active <= 1'b1;

                    if (capture_pixel == LAST_PIXEL) begin
                        capture_pixel <= 8'd0;
                        capture_out_group <= capture_out_group + 1'b1;
                    end
                    else begin
                        capture_pixel <= capture_pixel + 1'b1;
                    end
                end

                // 저장된 출력 32개를 32클럭 동안 직렬 출력
                // 다음 연산에 64클럭이 필요하므로 출력 병목 없음
                if (serialize_active) begin
                    out_acc <= result_buffer[serialize_lane];
                    out_addr <= serialize_channel_offset + buffer_pixel;
                    out_valid <= 1'b1;

                    if (serialize_lane == 5'd31) begin
                        serialize_lane <= 5'd0;
                        serialize_active <= 1'b0;
                    end
                    else begin
                        serialize_lane <= serialize_lane + 1'b1;
                    end

                    if (result_count == LAST_RESULT) begin
                        busy <= 1'b0;
                        done <= 1'b1;
                        input_rd_en <= 1'b0;
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
