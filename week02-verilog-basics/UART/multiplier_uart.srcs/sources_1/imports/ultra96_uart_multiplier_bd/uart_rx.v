`timescale 1ns/1ps

module uart_rx #(
    parameter integer CLK_FREQ  = 100_000_000,
    parameter integer BAUD_RATE = 115_200,
    parameter integer OVERSAMPLE = 16
)(
    input  wire       clk,
    input  wire       reset,
    input  wire       rx_data,
    output reg  [7:0] dout,
    output reg        en
);

    localparam [1:0] ST_IDLE  = 2'd0;
    localparam [1:0] ST_START = 2'd1;
    localparam [1:0] ST_DATA  = 2'd2;
    localparam [1:0] ST_STOP  = 2'd3;

    localparam integer HALF_SAMPLE = OVERSAMPLE / 2;

    (* ASYNC_REG = "TRUE" *) reg rx_meta;
    (* ASYNC_REG = "TRUE" *) reg rx_sync;

    reg [1:0] state;
    reg [4:0] sample_count;
    reg [2:0] bit_index;
    reg       sample_enable;
    wire      sample_tick;

    baud_rate_generator #(
        .CLK_FREQ (CLK_FREQ),
        .TICK_RATE(BAUD_RATE * OVERSAMPLE)
    ) u_baud_rx (
        .clk   (clk),
        .reset (reset),
        .enable(sample_enable),
        .tick  (sample_tick)
    );

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            rx_meta <= 1'b1;
            rx_sync <= 1'b1;
        end
        else begin
            rx_meta <= rx_data;
            rx_sync <= rx_meta;
        end
    end

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state         <= ST_IDLE;
            sample_count  <= 5'd0;
            bit_index     <= 3'd0;
            sample_enable <= 1'b0;
            dout          <= 8'h00;
            en            <= 1'b0;
        end
        else begin
            en <= 1'b0;

            case (state)
                ST_IDLE: begin
                    sample_count  <= 5'd0;
                    bit_index     <= 3'd0;
                    sample_enable <= 1'b0;

                    if (rx_sync == 1'b0) begin
                        sample_enable <= 1'b1;
                        state         <= ST_START;
                    end
                end

                ST_START: begin
                    if (sample_tick) begin
                        if (sample_count == HALF_SAMPLE - 1) begin
                            sample_count <= 5'd0;

                            if (rx_sync == 1'b0) begin
                                bit_index <= 3'd0;
                                state     <= ST_DATA;
                            end
                            else begin
                                sample_enable <= 1'b0;
                                state         <= ST_IDLE;
                            end
                        end
                        else begin
                            sample_count <= sample_count + 1'b1;
                        end
                    end
                end

                ST_DATA: begin
                    if (sample_tick) begin
                        if (sample_count == OVERSAMPLE - 1) begin
                            sample_count    <= 5'd0;
                            dout[bit_index] <= rx_sync;

                            if (bit_index == 3'd7)
                                state <= ST_STOP;
                            else
                                bit_index <= bit_index + 1'b1;
                        end
                        else begin
                            sample_count <= sample_count + 1'b1;
                        end
                    end
                end

                ST_STOP: begin
                    if (sample_tick) begin
                        if (sample_count == OVERSAMPLE - 1) begin
                            sample_count  <= 5'd0;
                            sample_enable <= 1'b0;

                            if (rx_sync == 1'b1)
                                en <= 1'b1;

                            state <= ST_IDLE;
                        end
                        else begin
                            sample_count <= sample_count + 1'b1;
                        end
                    end
                end

                default: begin
                    state         <= ST_IDLE;
                    sample_enable <= 1'b0;
                end
            endcase
        end
    end

endmodule
