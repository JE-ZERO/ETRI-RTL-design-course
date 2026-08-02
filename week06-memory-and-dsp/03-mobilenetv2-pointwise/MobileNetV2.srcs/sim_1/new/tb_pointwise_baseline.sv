`timescale 1ns/1ps

module tb_pointwise_baseline;

    localparam integer TOTAL_OUTPUTS  = 75264;
    localparam integer TIMEOUT_CYCLES = 4820000;

    reg clk;
    reg rst_n;
    reg start;

    wire busy;
    wire done;
    wire [16:0] out_addr;
    wire signed [47:0] out_acc;
    wire out_valid;

    // 골든 결과 및 검사 카운터
    reg [47:0] golden [0:TOTAL_OUTPUTS-1];
    integer output_count;
    integer error_count;
    integer cycle_count;

    // 검증 대상 모듈 연결
    pointwise_baseline dut (
        .clk       (clk),
        .rst_n     (rst_n),
        .start     (start),
        .busy      (busy),
        .done      (done),
        .out_addr  (out_addr),
        .out_acc   (out_acc),
        .out_valid (out_valid)
    );

    // 100 MHz 클럭 생성
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    // 골든 결과 읽기 및 시작 신호 생성
    initial begin
        $readmemh(
        "layer8_pointwise_acc_simple.mem",
            golden
        );

        rst_n        = 1'b0;
        start        = 1'b0;
        output_count = 0;
        error_count  = 0;
        cycle_count  = 0;

        // 리셋 해제 후 start 1클럭 입력
        repeat (4) @(posedge clk);
        @(negedge clk);
        rst_n = 1'b1;
        start = 1'b1;
        @(negedge clk);
        start = 1'b0;

        wait (done);
        @(posedge clk);
        #1;

        // 전체 출력 개수 확인
        if (output_count != TOTAL_OUTPUTS) begin
            $display(
                "ERROR: output count = %0d, expected = %0d",
                output_count, TOTAL_OUTPUTS
            );
            error_count = error_count + 1;
        end

        if (error_count == 0)
            $display(
                "PASS: actual BRAM IP + actual DSP Macro, all %0d outputs match golden",
                TOTAL_OUTPUTS
            );
        else
            $display("FAIL: %0d errors", error_count);

        $finish;
    end

    // 유효 출력의 주소와 데이터 비교
    always @(posedge clk) begin
        if (rst_n && busy)
            cycle_count = cycle_count + 1;

        if (out_valid) begin
            if (output_count >= TOTAL_OUTPUTS) begin
                if (error_count < 10)
                    $display("EXTRA OUTPUT: address = %0d", out_addr);
                error_count = error_count + 1;
            end
            else begin
                if (out_addr !== output_count[16:0]) begin
                    if (error_count < 10)
                        $display(
                            "ADDR ERROR: expected %0d, got %0d",
                            output_count, out_addr
                        );
                    error_count = error_count + 1;
                end

                if (out_acc !== golden[output_count]) begin
                    if (error_count < 10)
                        $display(
                            "DATA ERROR %0d: expected %h, got %h",
                            output_count, golden[output_count], out_acc
                        );
                    error_count = error_count + 1;
                end
            end

            output_count = output_count + 1;
        end

        // 제한 클럭 초과 시 종료
        if (cycle_count > TIMEOUT_CYCLES) begin
            $display("TIMEOUT after %0d busy cycles", cycle_count);
            $finish;
        end
    end

endmodule
