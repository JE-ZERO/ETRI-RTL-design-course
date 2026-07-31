module Mult_9x9(
    input clk,
    input rst,
    input start,
    output [15:0] data_out,
    output [3:0] step,
    output reg done_w,
    output reg done_r
    );


    reg d1, d2, d3, d4;
    reg [7:0] A, B;
    reg [6:0] addra;
    reg [6:0] read_addra_d;
    reg [6:0] read_addra_d2;
    wire [15:0] mult_out;
    reg wea, ena;

    
    mult_gen_0 u1(.CLK(clk), .A(A), .B(B), .P(mult_out));
    blk_mem_gen_0 u2(.clka(clk), .wea(wea), .ena(ena), .addra(addra), .dina(mult_out), .douta(data_out));


    assign step = A;


    always@(posedge clk) begin
        d1 <= start;
        d2 <= d1;
        d3 <= d2;
        //d4 <= d3;
    end


    always@(posedge clk) begin
        if(rst) begin
            A <= 0;
            B <= 0;
        end

        else begin

            if(start) begin
                A <= 2;
                B <= 1;
            end

            else if(A < 10) begin
                if(B < 9) B <= B + 1;

                else begin
                    A <= A + 1;
                    B <= 1;
                end
            end
        end
    end




    always @(posedge clk) begin//write and read
        if (rst) begin
            ena <= 0;
            wea <= 0;
            addra <= 0;
            read_addra_d <= 0;
            read_addra_d2 <= 0;
            done_w <= 0;
            done_r <= 0;
        end

        else begin
            done_w <= 0;
            done_r <= 0;

            if (d3) begin
                ena <= 1;
                wea <= 1;
                addra <= 0;
                read_addra_d <= 0;
                read_addra_d2 <= 0;
            end

            else if (ena && wea) begin
                if (addra == 71) begin
                    wea <= 0;
                    addra <= 0;
                    done_w <= 1;
                end

                else begin
                    addra <= addra + 1;
                end
            end

            else if (ena) begin
                read_addra_d <= addra;
                read_addra_d2 <= read_addra_d;

                if (addra < 71) begin
                    addra <= addra + 1;
                end

                else if (read_addra_d2 == 71) begin
                    ena <= 0;
                    done_r <= 1;
                end
            end
        end
    end


endmodule
