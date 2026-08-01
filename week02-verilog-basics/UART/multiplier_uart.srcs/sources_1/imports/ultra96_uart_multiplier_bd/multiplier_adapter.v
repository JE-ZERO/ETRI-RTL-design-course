`timescale 1ns/1ps

module multiplier_adapter (
    input  wire        clk,
    input  wire        reset,
    input  wire        start,
    input  wire [7:0]  a,
    input  wire [7:0]  b,
    output reg  [15:0] result,
    output reg         en
);

    localparam [1:0] ST_IDLE    = 2'd0;
    localparam [1:0] ST_RELEASE = 2'd1;
    localparam [1:0] ST_RUN     = 2'd2;

    reg [1:0] state;
    reg       core_rst_n;
    reg [7:0] a_latched;
    reg [7:0] b_latched;

    wire [15:0] core_result;
    wire        core_done;

    hexa_multiplier_top u_hexa_multiplier (
        .clk   (clk),
        .rst_n (core_rst_n),
        .a     (a_latched),
        .b     (b_latched),
        .result(core_result),
        .done  (core_done)
    );

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state       <= ST_IDLE;
            core_rst_n  <= 1'b0;
            a_latched   <= 8'h00;
            b_latched   <= 8'h00;
            result      <= 16'h0000;
            en          <= 1'b0;
        end
        else begin
            en <= 1'b0;

            case (state)
                ST_IDLE: begin
                    core_rst_n <= 1'b0;

                    if (start) begin
                        a_latched <= a;
                        b_latched <= b;
                        state     <= ST_RELEASE;
                    end
                end

                ST_RELEASE: begin
                    core_rst_n <= 1'b1;
                    state      <= ST_RUN;
                end

                ST_RUN: begin
                    core_rst_n <= 1'b1;

                    if (core_done) begin
                        result     <= core_result;
                        en         <= 1'b1;
                        core_rst_n <= 1'b0;
                        state      <= ST_IDLE;
                    end
                end

                default: begin
                    core_rst_n <= 1'b0;
                    state      <= ST_IDLE;
                end
            endcase
        end
    end

endmodule
