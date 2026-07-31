`timescale 1ns / 1ps

module memory_copy(
    input clk,
    input rst,
    input start,
    output [15:0] data_out,
    output reg done_w,
    output reg done_c,
    output reg done_r
    );


    reg delay1, delay2;
    reg mem1_last_addr_d1, mem1_last_addr_d2;
    reg mem2_last_addr_d1, mem2_last_addr_d2;
    reg mem1_ena, mem2_ena;
    reg mem1_wea, mem2_wea;
    reg mem2_enb;
    reg [9:0] mem1_addr, mem2_addra, mem2_addrb, addr;
    reg [15:0] mem1_din, mem2_din;
    wire [15:0] mem1_dout;
    wire [15:0] dout;

    assign data_out = dout;




    blk_mem_gen_1 mem1(.clka(clk), .ena(mem1_ena), .wea(mem1_wea), .addra(mem1_addr), .dina(mem1_din), .douta(mem1_dout));

    blk_mem_gen_2 mem2(.clka(clk), .ena(mem2_ena), .wea(mem2_wea), .addra(mem2_addra), .dina(mem2_din), .clkb(clk), .enb(mem2_enb), .addrb(mem2_addrb), .doutb(data_out));



    always@(posedge clk) begin
        delay1 <= done_w;
        delay2 <= delay1;
    end

    always @(posedge clk) begin//memory1 write control
        if (rst) begin
            mem1_ena <= 0;
            mem1_wea <= 0;
            mem1_addr <= 0;
            mem1_last_addr_d1 <= 0;
            mem1_last_addr_d2 <= 0;
            done_w <= 0;
        end

        else begin
            done_w <= 0;
            mem1_last_addr_d1 <= mem1_ena && !mem1_wea && (mem1_addr == 99);
            mem1_last_addr_d2 <= mem1_last_addr_d1;


            if(start) begin
                mem1_ena <= 1;
                mem1_wea <= 1;
                mem1_addr <= 0;
                mem1_din <= 1;
            end


            else if (mem1_ena && mem1_wea) begin
                if (mem1_addr == 99) begin
                    mem1_wea <= 0;
                    mem1_addr <= 0;
                    done_w <= 1;
                end

                else begin
                    mem1_addr <= mem1_addr + 1;
                    mem1_din <= mem1_din + 1;
                end
            end


            else if (mem1_ena) begin
                if(mem1_addr < 99) begin
                    mem1_addr <= mem1_addr + 1;
                end

                else if (mem1_last_addr_d2) begin
                    mem1_ena <= 0;
                end
            end
        end
    end





    always@(posedge clk) begin//memory2 copy control
        if (rst) begin
            mem2_ena <= 0;
            mem2_wea <= 0;
            mem2_addra <= 0;
            done_c <= 0;
        end

        else begin
            done_c <= 0;

            if(delay2) begin
                mem2_ena <= 1;
                mem2_wea <= 1;
                mem2_addra <= 0;//write address
                mem2_din <= 1;
            end

            else if (mem2_ena && mem2_wea) begin
                if (mem2_addra == 99) begin
                    mem2_ena <= 0;
                    mem2_wea <= 0;
                    mem2_addra <= 0;
                    done_c <= 1;
                end

                else begin
                    mem2_din <= mem1_dout;
                    mem2_addra <= addr;//이부분
                end
            end
        end
    end



    always@(posedge clk) begin//memory2 read control
        if(rst) begin
            mem2_enb <= 0;
            mem2_addrb <= 0;
            mem2_last_addr_d1 <= 0;
            mem2_last_addr_d2 <= 0;
        end

        else begin
            done_r <= 0;
            mem2_last_addr_d1 <= mem2_enb && (mem2_addrb == 99);
            mem2_last_addr_d2 <= mem2_last_addr_d1;

            if(done_c) begin
                mem2_enb <= 1;
                mem2_addrb <= 0;
            end

            else if(mem2_enb) begin
                if(mem2_addrb < 99) begin
                    mem2_addrb <= mem2_addrb + 1;
                end

                else if(mem2_last_addr_d2) begin
                    done_r <= 1;
                    mem2_enb <= 0;
                end
            end
        end
    end
















    //address control
    always@(posedge clk) begin
        if(rst) begin
            addr <= 0;
        end

        else if(delay2) begin
            addr <= 10;
        end

        else if(mem2_ena && mem2_wea) begin
            if(addr >= 90) begin
                addr <= addr - 89;
            end

            else begin
                addr <= addr + 10;
            end
        end
    end

endmodule
