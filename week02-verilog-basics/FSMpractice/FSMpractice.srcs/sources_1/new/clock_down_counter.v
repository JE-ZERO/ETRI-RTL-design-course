module clock_down_counter(input clk,
                           input rst,
                           input start,
                           input [3:0] num,
                           output reg dout,
                           output reg done);

//grey coding
parameter ST_IDLE = 2'b00;
parameter ST_W1 = 2'b01;
parameter ST_W0 = 2'b11;
parameter ST_DONE = 2'b10;

reg [3:0] copy;
reg [3:0] cnt;
reg [1:0] cstate;
reg [1:0] nstate;


always @ (posedge clk or posedge rst)//current state logic
begin
    if(rst==1'b1) 
        cstate <= ST_IDLE;
    else 
        cstate <= nstate;
end

always @ (*)//next state logic
begin
    case(cstate)
        ST_IDLE : if(start==1) nstate=ST_W1;
                  else nstate=ST_IDLE;
        ST_W1 : if(copy==1) begin
                    if(cnt==num-1)
                        nstate=ST_DONE;
                    else
                        nstate=ST_W0;
                    end
                else nstate=ST_W1;
        ST_W0 : nstate=ST_W1;
        ST_DONE : nstate=ST_IDLE;
        default : nstate=ST_IDLE;
    endcase
end

always @ (posedge clk or posedge rst)//output state logic
begin
    case(cstate)
        ST_IDLE : begin
                    dout <= 0;
                    done <= 0;
                    copy <= num;
                    cnt <= 0;
                  end
        ST_W1 : begin
                    dout <= 1;
                    done <= 0;
                    copy <= copy - 1;
                end
        ST_W0 : begin
                    dout <= 0;
                    done <= 0;
                    cnt <= cnt + 1;
                    copy <= num - (cnt + 1);
                end
        ST_DONE : begin
                      dout <= 0;
                      done <= 1;
                  end
        default : begin
                       dout <= 0;
                       done <= 0;
                   end
    endcase
end

endmodule
