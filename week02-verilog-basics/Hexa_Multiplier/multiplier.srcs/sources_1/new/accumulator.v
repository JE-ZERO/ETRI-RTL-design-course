module accumulator(input clk,
                   input rst_n,
                   input [15:0] in_data,
                   input acc_clear,
                   input acc_enable,
                   output reg [15:0] acc);

always @ (posedge clk or negedge rst_n) begin
    if(rst_n == 1'b0)
        acc <= 16'b0;
    else if(acc_clear == 1'b1)
        acc <= 16'b0;
    else if(acc_enable == 1'b1)
        acc <= acc + in_data;
end

endmodule
