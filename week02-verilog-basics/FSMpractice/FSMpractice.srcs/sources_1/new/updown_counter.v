module updown_counter(input clk,
                  input rst_n,
                  input mode,
                  output reg [2:0] cnt);

parameter s0=1'b0;//upcount
parameter s1=1'b1;//downcount

reg cstate, nstate;

always @ (posedge clk or negedge rst_n)//current state logic
begin
    if(rst_n==1'b0)
        cstate <= s0;
    else 
        cstate <= nstate;
end

always @ (mode, cstate)//next state logic
begin
    case(cstate)
        s0 : if(mode==1) nstate=s1;
             else nstate=s0;
        s1 : if(mode==1) nstate=s0;
             else nstate=s1;
        default : nstate=s0;
    endcase
end

always @ (posedge clk or negedge rst_n)//output state logic
begin
    if(rst_n==1'b0) cnt <= 3'b000;
    else begin
        case(cstate)
            s0 : cnt<=cnt+1;
            s1 : cnt<=cnt-1;
            default : cnt<=3'd0;
        endcase
    end
end

endmodule