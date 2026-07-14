module controller(input clk,
                  input rst_n,
                  output reg sel_a,
                  output reg sel_b,
                  output reg [2:0] shift_cntrl,
                  output reg done,
                  output reg reset);

reg [3:0] cstate, nstate;

parameter IDLE = 3'd0;
parameter STATE1 = 3'd1;//2^8 calculation (MS 4bits * MS 4bits)
parameter STATE2 = 3'd3;//2^4 calculation (MS 4bits * LS 4bits)
parameter STATE3 = 3'd2;//2^4 calculation (LS 4bits * MS 4bits)
parameter STATE4 = 3'd5;//2^0 calculation (LS 4bits * LS 4bits)
parameter DONE = 3'd4;

//current state logic
always @ (posedge clk or negedge rst_n)
begin
    if(rst_n == 1'b0)
        cstate <= IDLE;
    else
        cstate <= nstate;
end


//next state logic
always @ (*)
begin
    case(cstate)
        IDLE : nstate = STATE1;
        STATE1 : nstate = STATE2;
        STATE2 : nstate = STATE3;
        STATE3 : nstate = STATE4;
        STATE4 : nstate = DONE;
        default : nstate = IDLE;
    endcase
end


//output logic
always @ (*)
begin
    case(cstate)
        IDLE :
            begin
            reset = 0;
            done = 0;
            end
        STATE1 : 
            begin
            sel_a = 1;
            sel_b = 1;
            shift_cntrl = 2;
            end
        STATE2 : 
            begin
            sel_a = 1;
            sel_b = 0;
            shift_cntrl = 1;
            end
        STATE3 : 
            begin
            sel_a = 0;
            sel_b = 1;
            shift_cntrl = 1;
            end
        STATE4 : 
            begin
            sel_a = 1;
            sel_b = 1;
            shift_cntrl = 0;
            end            
end
endmodule
