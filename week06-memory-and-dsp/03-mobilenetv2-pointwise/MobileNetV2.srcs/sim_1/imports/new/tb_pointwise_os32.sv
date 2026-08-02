`timescale 1ns/1ps

module tb_pointwise_os32;
    localparam integer TOTAL_OUTPUTS = 75264;
    localparam integer TIMEOUT_CYCLES = 160000;

    reg clk, rst_n, start;
    wire busy, done, out_valid;
    wire [16:0] out_addr;
    wire signed [47:0] out_acc;

    // 골든 결과와 주소 중복 및 누락 검사
    reg [47:0] golden [0:TOTAL_OUTPUTS-1];
    reg seen [0:TOTAL_OUTPUTS-1];
    integer output_count, error_count, cycle_count;
    integer first_output_cycle, last_output_cycle;
    integer check_index;

    // 검증 대상 모듈 연결
    pointwise_os32 dut (
        .clk(clk), .rst_n(rst_n), .start(start),
        .busy(busy), .done(done),
        .out_addr(out_addr), .out_acc(out_acc), .out_valid(out_valid)
    );

    // 100 MHz 클럭 생성
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    // 골든 결과 읽기 및 시작 신호 생성
    initial begin
        // 합성 후 기능 시뮬레이션 초기 안정화 대기
        repeat(100) @(posedge clk);

        $readmemh(
        "layer8_pointwise_acc_simple.mem",
            golden
        );
        for (check_index = 0; check_index < TOTAL_OUTPUTS;
             check_index = check_index + 1)
            seen[check_index] = 1'b0;

        rst_n = 1'b0;
        start = 1'b0;
        output_count = 0;
        error_count = 0;
        cycle_count = 0;
        first_output_cycle = -1;
        last_output_cycle = -1;

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

        // 전체 출력 개수와 누락 주소 확인
        if (output_count != TOTAL_OUTPUTS) begin
            $display("ERROR: output count=%0d, expected=%0d",
                     output_count, TOTAL_OUTPUTS);
            error_count = error_count + 1;
        end

        for (check_index = 0; check_index < TOTAL_OUTPUTS;
             check_index = check_index + 1) begin
            if (!seen[check_index]) begin
                if (error_count < 10)
                    $display("MISSING OUTPUT: address=%0d", check_index);
                error_count = error_count + 1;
            end
        end

        if (error_count == 0) begin
            $display("PASS: actual BRAM IP + 32 actual DSP Macros");
            $display("PASS: all %0d outputs match golden", TOTAL_OUTPUTS);
            $display("BUSY_CYCLES=%0d", cycle_count);
            $display("FIRST_OUTPUT_CYCLE=%0d", first_output_cycle);
            $display("LAST_OUTPUT_CYCLE=%0d", last_output_cycle);
        end
        else
            $display("FAIL: %0d errors", error_count);

        $finish;
    end

    // 유효 출력의 주소와 데이터 비교
    always @(posedge clk) begin
        if (rst_n && busy)
            cycle_count = cycle_count + 1;

        if (out_valid) begin
            if (first_output_cycle < 0)
                first_output_cycle = cycle_count;
            last_output_cycle = cycle_count;

            if (out_addr >= TOTAL_OUTPUTS) begin
                if (error_count < 10)
                    $display("RANGE ERROR: address=%0d", out_addr);
                error_count = error_count + 1;
            end
            else begin
                if (seen[out_addr]) begin
                    if (error_count < 10)
                        $display("DUPLICATE OUTPUT: address=%0d", out_addr);
                    error_count = error_count + 1;
                end
                seen[out_addr] = 1'b1;

                if (out_acc !== golden[out_addr]) begin
                    if (error_count < 10)
                        $display("DATA ERROR addr=%0d: expected=%h, got=%h",
                                 out_addr, golden[out_addr], out_acc);
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
