`timescale 1ns/1ps

module tb_uart_multiplier_core;

    localparam int  CLK_FREQ  = 100_000_000;
    localparam int  BAUD_RATE = 115_200;
    localparam time CLK_HALF   = 5ns;
    localparam time BIT_TIME   = 8680ns;

    logic clk;
    logic reset;
    logic rxd;
    wire  txd;

    int pass_count;
    int fail_count;

    uart_multiplier_core #(
        .CLK_FREQ (CLK_FREQ),
        .BAUD_RATE(BAUD_RATE)
    ) dut (
        .clk  (clk),
        .reset(reset),
        .rxd  (rxd),
        .txd  (txd)
    );

    initial begin
        clk = 1'b0;
        forever #CLK_HALF clk = ~clk;
    end

    task automatic uart_send_byte(input logic [7:0] data);
        int i;
        begin
            rxd = 1'b0;
            #BIT_TIME;

            for (i = 0; i < 8; i++) begin
                rxd = data[i];
                #BIT_TIME;
            end

            rxd = 1'b1;
            #BIT_TIME;
        end
    endtask

    task automatic uart_receive_byte(output logic [7:0] data);
        int i;
        begin
            @(negedge txd);
            #(BIT_TIME + BIT_TIME/2);

            for (i = 0; i < 8; i++) begin
                data[i] = txd;
                #BIT_TIME;
            end

            if (txd !== 1'b1) begin
                $error("Stop-bit error");
                fail_count++;
            end
        end
    endtask

    function automatic logic [7:0] hex_ascii(input logic [3:0] n);
        if (n < 10)
            hex_ascii = 8'h30 + n;
        else
            hex_ascii = 8'h41 + (n - 10);
    endfunction

    task automatic send_command(input logic [31:0] text);
        begin
            uart_send_byte(text[31:24]);
            uart_send_byte(text[23:16]);
            uart_send_byte(text[15:8]);
            uart_send_byte(text[7:0]);
        end
    endtask

    task automatic check_response(input logic [15:0] expected);
        logic [7:0] got [0:6];
        logic [7:0] exp;
        int i;
        begin
            for (i = 0; i < 7; i++)
                uart_receive_byte(got[i]);

            for (i = 0; i < 7; i++) begin
                case (i)
                    0: exp = 8'h3D;
                    1: exp = hex_ascii(expected[15:12]);
                    2: exp = hex_ascii(expected[11:8]);
                    3: exp = hex_ascii(expected[7:4]);
                    4: exp = hex_ascii(expected[3:0]);
                    5: exp = 8'h0D;
                    6: exp = 8'h0A;
                    default: exp = 8'h3F;
                endcase

                if (got[i] !== exp) begin
                    $error("Byte %0d: expected %02h, got %02h", i, exp, got[i]);
                    fail_count++;
                end
                else begin
                    pass_count++;
                end
            end

            $display("Checked response for expected product 0x%04h", expected);
        end
    endtask

    initial begin
        rxd        = 1'b1;
        reset      = 1'b1;
        pass_count = 0;
        fail_count = 0;

        repeat (10) @(posedge clk);
        reset = 1'b0;
        repeat (10) @(posedge clk);

        fork
            send_command("1234");
            check_response(16'h03A8);
        join

        repeat (100) @(posedge clk);

        fork
            send_command("FFFF");
            check_response(16'hFE01);
        join

        repeat (100) @(posedge clk);

        fork
            send_command("ab02");
            check_response(16'h0156);
        join

        $display("----------------------------------------");
        $display("PASS bytes = %0d", pass_count);
        $display("FAIL bytes = %0d", fail_count);
        $display("----------------------------------------");

        if (fail_count == 0)
            $display("ALL TESTS PASSED");
        else
            $fatal(1, "TEST FAILED");

        #10us;
        $finish;
    end

    initial begin
        #10ms;
        $fatal(1, "Simulation timeout");
    end

endmodule
