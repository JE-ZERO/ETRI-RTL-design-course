module counter4_rtl(

    );
    
reg [3:0] q_;

always@(posedge clk, posedge reset) begin
    if(reset) q<=0;
    
end
always@(*)
    q_=q+1;

endmodule
