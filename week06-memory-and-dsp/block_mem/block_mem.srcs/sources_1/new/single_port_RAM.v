`timescale 1ns / 1ps

module single_port_RAM(
    input clk,
    input rst,
    input start,
    output [15:0] data_out,
    output reg done_w,
    output reg done_r
    );

    reg ena;
    reg wea;
    reg [9:0] addra;
    reg [9:0] read_addra_d;
    reg [9:0] read_addra_d2;
    reg [15:0] dina;
    wire [15:0] douta;

    blk_mem_gen_1 u1(.clka(clk), .ena(ena), .wea(wea), .addra(addra), .dina(dina), .douta(douta));

    assign data_out = douta;

    always @(posedge clk) begin
        if (rst) begin
            ena <= 0;
            wea <= 0;
            addra <= 0;
            read_addra_d <= 0;
            read_addra_d2 <= 0;
            dina <= 0;
            done_w <= 0;
            done_r <= 0;
        end

        else begin
            done_w <= 0;
            done_r <= 0;

            if (start) begin
                ena <= 1;
                wea <= 1;
                addra <= 0;
                read_addra_d <= 0;
                read_addra_d2 <= 0;
                dina <= 1;
            end

            else if (ena && wea) begin
                if (addra == 99) begin
                    wea <= 0;
                    addra <= 0;
                    done_w <= 1;
                end

                else begin
                    addra <= addra + 1;
                    dina <= dina + 1;
                end
            end

            else if (ena) begin
                read_addra_d <= addra;
                read_addra_d2 <= read_addra_d;

                if (addra < 99) begin
                    addra <= addra + 1;
                end

                else if (read_addra_d2 == 99) begin
                    ena <= 0;
                    done_r <= 1;
                end
            end
        end
    end

endmodule
