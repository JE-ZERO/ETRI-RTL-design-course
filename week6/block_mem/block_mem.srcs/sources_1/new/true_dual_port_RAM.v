`timescale 1ns / 1ps

module true_dual_port_RAM(
    input clk,
    input rst,
    input start_w,
    input start_r,
    output [15:0] data_out1,
    output [15:0] data_out2,
    output done_w,
    output done_r
    );

    reg ena, enb;
    reg wea, web;
    reg [1:0] buff_a, buff_b;
    reg done_wa, done_wb;
    reg done_ra, done_rb;
    reg [9:0] addra, addrb;
    reg [15:0] cnt1, cnt2;
    wire [15:0] dina, dinb;
    wire [15:0] douta, doutb;

    blk_mem_gen_3 u3(
        .clka(clk),
        .ena(ena),
        .wea(wea),
        .addra(addra),
        .dina(dina),
        .douta(douta),
        .clkb(clk),
        .enb(enb),
        .web(web),
        .addrb(addrb),
        .dinb(dinb),
        .doutb(doutb)
    );

    assign data_out1 = douta;
    assign data_out2 = doutb;
    assign dina = cnt1;
    assign dinb = cnt2;
    assign done_w = done_wa && done_wb;
    assign done_r = done_ra && done_rb;



    always @(posedge clk) begin
        if (rst) begin
            ena <= 0;
            wea <= 0;
            addra <= 0;
            cnt1 <= 0;
            buff_a <= 0;
            done_wa <= 0;
            done_ra <= 0;
        end

        else begin
            done_wa <= 0;
            done_ra <= 0;

            if (start_w) begin
                ena <= 1;
                wea <= 1;
                addra <= 0;
                cnt1 <= 1;
                buff_a <= 0;
            end

            else if (start_r) begin
                ena <= 1;
                wea <= 0;
                addra <= 50;
                buff_a <= 0;
            end

            else if (ena && wea) begin
                if (addra == 49) begin
                    ena <= 0;
                    wea <= 0;
                    done_wa <= 1;
                end

                else begin
                    addra <= addra + 1;
                    cnt1 <= cnt1 + 1;
                end
            end

            else if (ena) begin
                if (addra < 99) begin
                    addra <= addra + 1;
                end

                else if (buff_a < 2) begin
                    buff_a <= buff_a + 1;
                end

                else begin
                    ena <= 0;
                    buff_a <= 0;
                    done_ra <= 1;
                end
            end
        end
    end




    always @(posedge clk) begin
        if (rst) begin
            enb <= 0;
            web <= 0;
            addrb <= 0;
            cnt2 <= 0;
            buff_b <= 0;
            done_wb <= 0;
            done_rb <= 0;
        end

        else begin
            done_wb <= 0;
            done_rb <= 0;

            if (start_w) begin
                enb <= 1;
                web <= 1;
                addrb <= 50;
                cnt2 <= 51;
                buff_b <= 0;
            end

            else if (start_r) begin
                enb <= 1;
                web <= 0;
                addrb <= 0;
                buff_b <= 0;
            end

            else if (enb && web) begin
                if (addrb == 99) begin
                    enb <= 0;
                    web <= 0;
                    done_wb <= 1;
                end

                else begin
                    addrb <= addrb + 1;
                    cnt2 <= cnt2 + 1;
                end
            end

            else if (enb) begin
                if (addrb < 49) begin
                    addrb <= addrb + 1;
                end

                else if (buff_b < 2) begin
                    buff_b <= buff_b + 1;
                end

                else begin
                    enb <= 0;
                    buff_b <= 0;
                    done_rb <= 1;
                end
            end
        end
    end

endmodule
