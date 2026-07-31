`timescale 1ns / 1ps

module simple_dual_port_RAM(
    input clk,
    input rst,
    input start_w,
    input start_r,
    output [15:0] data_out,
    output reg done_w,
    output reg done_r
    );

    reg ena, enb;
    reg wea;
    reg buff1, buff2;
    reg [9:0] addra;
    reg [9:0] addrb;
    reg [15:0] cnt;
    wire [15:0] dina;
    wire [15:0] doutb;

    blk_mem_gen_2 u2(.clka(clk), .ena(ena), .wea(wea), .addra(addra), .dina(dina), .clkb(clk), .enb(enb), .addrb(addrb), .doutb(doutb));

    assign data_out = doutb;
    assign dina = cnt;

    always @(posedge clk) begin
        if (rst) begin
            ena <= 0;
            wea <= 0;
            addra <= 0;
            cnt <= 0;
            done_w <= 0;
        end

        else begin
            done_w <= 0;


            if (start_w) begin
                ena <= 1;
                wea <= 1;
                addra <= 0;
                cnt <= 1;
            end

            else if (ena && wea) begin
                if (addra == 99) begin
                    wea <= 0;
                    addra <= 0;
                    done_w <= 1;
                end

                else begin
                    addra <= addra + 1;
                    cnt <= cnt + 1;
                end
            end

            else if (ena) ena <= 0;

        end
    end


    always@(posedge clk) begin
        if(rst) begin
            enb <= 0;
            addrb <= 0;
            done_r <= 0;
            buff1 <= 0;
            buff2 <= 0;
        end

        else begin
            done_r <= 0;

            if(start_r) begin
                enb <= 1;
                addrb <= 0;
            end

            else if(enb) begin
                if(addrb < 99) begin
                    addrb <= addrb + 1;
                end

                else if(addrb == 99) begin
                    buff1 <= 1;

                    if(buff1) begin
                        buff2 <= 1;
                        buff1 <= 0;
                    end

                    else if(buff2) begin
                        enb <= 0;
                        done_r <= 1;
                        buff2 <= 0;
                    end
                end
            end
        end
    end


endmodule
