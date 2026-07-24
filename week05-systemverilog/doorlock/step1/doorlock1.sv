module doorlock1(
        input logic clk,
        input logic reset,
        input logic start,
        input logic [3:0]din,
        input logic stop,
        output logic unlock);

        typedef enum logic [1:0] {
                ST_IDLE, ST_DATA, ST_STOP, ST_DONE
        } state_t;

        state_t c_state, n_state;

        logic [1:0] count, match;

        always_ff@(posedge clk or negedge reset) begin //current state logic + compare logic
                if(!reset) begin
                        c_state <= ST_IDLE;
                        count   <= 2'd0;
                        match   <= 1'b1;
                end

                else begin
                        c_state <= n_state;

                        case(c_state)
                                ST_IDLE : begin
                                        count <= 2'd0;
                                        match <= 1'b1;
                                end

                                ST_DATA : begin
                                        case(count)
                                                2'd0 : if(din != 4'd0) match <= 1'b0;
                                                2'd1 : if(din != 4'd3) match <= 1'b0;
                                                2'd2 : if(din != 4'd2) match <= 1'b0;
                                                2'd3 : if(din != 4'd7) match <= 1'b0;
                                                default :              match <= 1'b0;
                                        endcase

                                        if(count != 2'd3) count <= count + 1'b1;
                                end

                                default : begin end
                        endcase
                end
        end




        always_comb begin // next state logic + output logic
                n_state = c_state;
                unlock  = 1'b0;

                if(c_state == ST_DONE) unlock = 1'b1;

                case(c_state)
                        ST_IDLE : if(start) n_state = ST_DATA;

                        ST_DATA : if(count == 2'd3) n_state = ST_STOP;

                        ST_STOP : begin
                                  if(stop) begin
                                          if(match) n_state = ST_DONE;
                                          else      n_state = ST_IDLE;
                                  end
                        end

                        ST_DONE : n_state = ST_IDLE;

                        default : n_state = ST_IDLE;
                endcase
        end

endmodule
