module controller(input clk,
                  input rst_n,
                  output reg sel_a,
                  output reg sel_b,
                  output reg [1:0] shift_cntrl,
                  output reg acc_clear,
                  output reg acc_enable,
                  output reg done);

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
        DONE : nstate = IDLE;
        default : nstate = IDLE;
    endcase
end


//output logic
always @ (*)
begin
    done = 1'b0;
    sel_a = 1'b0;
    sel_b = 1'b0;
    shift_cntrl = 2'b00;
    acc_clear = 1'b0;
    acc_enable = 1'b0;

    case(cstate)
        IDLE :
            begin
            done = 1'b0;
            sel_a = 1'b0;
            sel_b = 1'b0;
            shift_cntrl = 2'b00;
            acc_clear = 1'b1;
            acc_enable = 1'b0;
            end
        STATE1 :
            begin
            sel_a = 1'b1;
            sel_b = 1'b1;
            shift_cntrl = 2'b10;
            acc_clear = 1'b0;
            acc_enable = 1'b1;
            end
        STATE2 :
            begin
            sel_a = 1'b1;
            sel_b = 1'b0;
            shift_cntrl = 2'b01;
            acc_clear = 1'b0;
            acc_enable = 1'b1;
            end
        STATE3 :
            begin
            sel_a = 1'b0;
            sel_b = 1'b1;
            shift_cntrl = 2'b01;
            acc_clear = 1'b0;
            acc_enable = 1'b1;
            end
        STATE4 :
            begin
            sel_a = 1'b0;
            sel_b = 1'b0;
            shift_cntrl = 2'b00;
            acc_clear = 1'b0;
            acc_enable = 1'b1;
            end
        DONE :
            begin
            done = 1'b1;
            acc_clear = 1'b0;
            acc_enable = 1'b0;
            end
        default :
            begin
            done = 1'b0;
            acc_clear = 1'b0;
            acc_enable = 1'b0;
            end
        endcase
end
endmodule
