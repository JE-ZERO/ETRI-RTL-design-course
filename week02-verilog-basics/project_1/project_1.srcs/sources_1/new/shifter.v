module shifter(input [7:0]inp, 
                input[1:0]shift_cntrl,
                output reg [15:0] shift_out);
                
always@(*) begin
    case (shift_cntrl)
        2'b00 : shift_out={8'b0, inp};
        2'b01 : shift_out={8'b0,inp}<<4;
        2'b10 : shift_out={8'b0,inp}<<8;
        default : shift_out=16'b0;
    endcase
end


endmodule
