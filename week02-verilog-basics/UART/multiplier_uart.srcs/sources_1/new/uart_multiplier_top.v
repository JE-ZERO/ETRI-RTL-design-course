`timescale 1ns/1ps

module uart_multiplier_top (
    input  wire clk_40m,
    input  wire rxd,
    output wire txd
);

    wire clk_100m;
    wire clk_locked;

    reg  [1:0] reset_sync = 2'b11;
    wire       reset;


    clk_wiz_0 u_clk_wiz (
        .clk_in1  (clk_40m),
        .clk_out1 (clk_100m),
        .locked   (clk_locked)
    );


    always @(posedge clk_100m or negedge clk_locked) begin
        if (!clk_locked)
            reset_sync <= 2'b11;
        else
            reset_sync <= {reset_sync[0], 1'b0};
    end

    assign reset = reset_sync[1];


    uart_multiplier_core u_core (
        .clk   (clk_100m),
        .reset (reset),
        .rxd   (rxd),
        .txd   (txd)
    );

endmodule