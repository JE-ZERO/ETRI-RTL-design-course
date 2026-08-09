`timescale 1ns / 1ps

module tb_DWC_compare;

    localparam int EXPECTED_RESULTS = 384 * 14 * 14;

    logic clk = 1'b0;
    logic rst_n = 1'b0;
    logic start = 1'b0;

    logic baseline_done;
    logic baseline_result_valid;
    logic signed [15:0] baseline_result;
    logic developed_done;
    logic developed_result_valid;
    logic signed [15:0] developed_result;

    logic baseline_valid_d1, baseline_valid_d2;
    logic baseline_done_d1, baseline_done_d2;
    logic signed [15:0] baseline_result_d1, baseline_result_d2;

    int baseline_count = 0;
    int developed_count = 0;
    int mismatch_count = 0;
    int input_bram_en_cycles = 0;
    int weight_bram_en_cycles = 0;
    int active_cycles = 0;
    time baseline_first_valid_time = 0;
    time developed_first_valid_time = 0;
    time baseline_done_time = 0;
    time developed_done_time = 0;

    always #5 clk = ~clk;

    DWC_baseline baseline (
        .clk          (clk),
        .rst_n        (rst_n),
        .start        (start),
        .done         (baseline_done),
        .result_valid (baseline_result_valid),
        .result       (baseline_result)
    );

    DWC_developed developed (
        .clk          (clk),
        .rst_n        (rst_n),
        .start        (start),
        .done         (developed_done),
        .result_valid (developed_result_valid),
        .result       (developed_result)
    );

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            baseline_valid_d1  <= 1'b0;
            baseline_valid_d2  <= 1'b0;
            baseline_done_d1   <= 1'b0;
            baseline_done_d2   <= 1'b0;
            baseline_result_d1 <= '0;
            baseline_result_d2 <= '0;
        end
        else begin
            baseline_valid_d1  <= baseline_result_valid;
            baseline_valid_d2  <= baseline_valid_d1;
            baseline_done_d1   <= baseline_done;
            baseline_done_d2   <= baseline_done_d1;
            baseline_result_d1 <= baseline_result;
            baseline_result_d2 <= baseline_result_d1;
        end
    end

    // DUT 출력과 내부 enable은 posedge NBA 갱신이 끝난 negedge에서 검사한다.
    always @(negedge clk) begin
        if (rst_n) begin
            if (baseline_result_valid) begin
                baseline_count <= baseline_count + 1;
                if (baseline_first_valid_time == 0)
                    baseline_first_valid_time <= $time;
            end

            if (developed_result_valid) begin
                developed_count <= developed_count + 1;
                if (developed_first_valid_time == 0)
                    developed_first_valid_time <= $time;

                if ($isunknown(developed_result)) begin
                    mismatch_count <= mismatch_count + 1;
                    if (mismatch_count < 10)
                        $display("MISMATCH: developed result contains X/Z at %0t", $time);
                end
                else if (developed_result !== baseline_result_d2) begin
                    mismatch_count <= mismatch_count + 1;
                    if (mismatch_count < 10)
                        $display("MISMATCH: t=%0t baseline_delayed=%0d developed=%0d",
                                 $time, baseline_result_d2, developed_result);
                end
            end

            if (developed_result_valid !== baseline_valid_d2) begin
                mismatch_count <= mismatch_count + 1;
                if (mismatch_count < 10)
                    $display("MISMATCH: valid alignment at %0t base_d2=%b developed=%b",
                             $time, baseline_valid_d2, developed_result_valid);
            end

            if (developed_done !== baseline_done_d2) begin
                mismatch_count <= mismatch_count + 1;
                if (mismatch_count < 10)
                    $display("MISMATCH: done alignment at %0t base_d2=%b developed=%b",
                             $time, baseline_done_d2, developed_done);
            end

            if (baseline_done)
                baseline_done_time <= $time;
            if (developed_done)
                developed_done_time <= $time;

            if (developed.active)
                active_cycles <= active_cycles + 1;
            if (developed.input_bram_en)
                input_bram_en_cycles <= input_bram_en_cycles + 1;
            if (developed.weight_bram_en)
                weight_bram_en_cycles <= weight_bram_en_cycles + 1;
        end
    end

    initial begin
        #100;
        rst_n = 1'b1;
        #10;
        start = 1'b1;
        #10;
        start = 1'b0;

        wait (developed_done === 1'b1);
        @(negedge clk);
        #1ps;

        $display("COMPARE_SUMMARY baseline_count=%0d developed_count=%0d mismatches=%0d",
                 baseline_count, developed_count, mismatch_count);
        $display("LATENCY_SUMMARY first_valid_base=%0t first_valid_dev=%0t done_base=%0t done_dev=%0t",
                 baseline_first_valid_time, developed_first_valid_time,
                 baseline_done_time, developed_done_time);
        $display("ENABLE_SUMMARY active=%0d input_bram_en=%0d weight_bram_en=%0d",
                 active_cycles, input_bram_en_cycles, weight_bram_en_cycles);

        if (baseline_count != EXPECTED_RESULTS)
            $fatal(1, "Baseline result count mismatch: %0d", baseline_count);
        if (developed_count != EXPECTED_RESULTS)
            $fatal(1, "Developed result count mismatch: %0d", developed_count);
        if (mismatch_count != 0)
            $fatal(1, "Baseline/developed comparison failed: %0d mismatches", mismatch_count);
        if (developed_first_valid_time - baseline_first_valid_time != 20ns)
            $fatal(1, "First-result latency delta is not two clocks");
        if (developed_done_time - baseline_done_time != 20ns)
            $fatal(1, "Done latency delta is not two clocks");
        if (developed.input_bram_en !== 1'b0)
            $fatal(1, "Input BRAM enable did not turn off after the final pipeline tail drained");
        if (developed_done !== developed_result_valid)
            $fatal(1, "Developed done is not aligned with final result_valid");

        $display("COMPARE_PASS");
        #30;
        $finish;
    end

    initial begin
        #2ms;
        $fatal(1, "Timeout waiting for developed_done");
    end

endmodule
