module clkDivider(input clk,
                  input rst,
                  output clk_out);

parameter HALF_PERIOD_COUNT = 50_000_000;

reg [26:0] cnt;
reg clk_out_reg;

assign clk_out = clk_out_reg;

always @(posedge clk or posedge rst) begin
    if (rst) begin
        cnt <= 27'd0;
        clk_out_reg <= 1'b0;
    end
    else begin
        if (cnt == HALF_PERIOD_COUNT - 1) begin
            cnt <= 27'd0;
            clk_out_reg <= ~clk_out_reg;
        end
        else begin
            cnt <= cnt + 1'b1;
        end
    end
end

endmodule