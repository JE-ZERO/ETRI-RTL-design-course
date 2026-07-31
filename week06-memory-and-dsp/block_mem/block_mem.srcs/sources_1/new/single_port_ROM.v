`timescale 1ns / 1ps

module single_port_ROM(
    input clk,
    input rst,
    input start_r,
    output [15:0] data_out,
    output done
    );
    
    reg ena;
    reg [6:0] addra;
    wire [15:0] douta;
    
    blk_mem_gen_0 u0(.clka(clk), .ena(ena), .addra(addra), .douta(douta));
    

    assign data_out = douta;
    assign done = (douta == 16'd100) ? 1'b1 : 1'b0;


    always@(posedge clk) begin
        if(rst) ena <= 0;
        else if(start_r) ena <= 1;
        else if(done) ena <= 0;
    end


    always@(posedge clk) begin
        if(rst) addra <= 0;
        else if(ena && addra < 100) begin
            addra <= addra + 1;
        end
    end

    
endmodule
