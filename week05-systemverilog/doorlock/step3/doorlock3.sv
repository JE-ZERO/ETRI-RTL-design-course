module doorlock3(
        input logic clk,
        input logic reset,
        input logic start,
        input logic [3:0]din,
        input logic stop,
        input logic init,
        output logic unlock);

        typedef enum logic [1:0] {
                ST_IDLE, ST_INIT, ST_DATA, ST_DONE
        } state_t;

        state_t c_state, n_state;

        logic [47:0] password, pw_buff, shifted_buff;
        logic [3:0] length, count;
        logic match_found, valid;

        assign shifted_buff = {pw_buff[43:0], din};

        always_ff@(posedge clk or negedge reset) begin //current state logic + compare logic
                if(!reset) begin
                        c_state     <= ST_IDLE;
                        password    <= 48'b0;
                        pw_buff     <= 48'b0;
                        length      <= 4'b0;
                        count       <= 4'b0;
                        match_found <= 1'b0;
                        valid       <= 1'b0;
                end

                else begin
                        c_state <= n_state;

                        case(c_state)
                                ST_IDLE : begin
                                        if(init) begin
                                                pw_buff     <= 48'd0;
                                                count       <= 4'd0;
                                                match_found <= 1'b0;
                                                valid       <= 1'b0;
                                        end

                                        else if(start && valid) begin
                                                pw_buff     <= 48'd0;
                                                count       <= 4'd0;
                                                match_found <= 1'b0;
                                        end
                                end

                                ST_INIT : begin
                                        if(!stop) begin
                                                pw_buff <= {pw_buff[43:0], din};
                                                if(count < 4'd12) count <= count + 1'b1;
                                        end

                                        else begin
                                                if(count >= 4'd4) begin
                                                        password <= pw_buff;
                                                        length   <= count;
                                                        valid    <= 1'b1;
                                                end

                                                else begin
                                                        password <= 48'd0;
                                                        length   <= 4'd0;
                                                        valid    <= 1'b0;
                                                end
                                        end
                                end

                                ST_DATA : begin
                                        if(!stop) begin
                                                pw_buff <= shifted_buff;

                                                if(count < 4'd12) count <= count + 4'd1;

                                                if(count + 4'd1 >= length) begin
                                                        case(length)
                                                                4'd4  : if(shifted_buff[15:0] == password[15:0])
                                                                        match_found <= 1'b1;

                                                                4'd5  : if(shifted_buff[19:0] == password[19:0])
                                                                        match_found <= 1'b1;

                                                                4'd6 : if(shifted_buff[23:0] == password[23:0])
                                                                        match_found <= 1'b1;

                                                                4'd7 : if(shifted_buff[27:0] == password[27:0])
                                                                        match_found <= 1'b1;

                                                                4'd8 : if(shifted_buff[31:0] == password[31:0])
                                                                        match_found <= 1'b1;

                                                                4'd9 : if(shifted_buff[35:0] == password[35:0])
                                                                        match_found <= 1'b1;

                                                                4'd10 : if(shifted_buff[39:0] == password[39:0])
                                                                        match_found <= 1'b1;

                                                                4'd11 : if(shifted_buff[43:0] == password[43:0])
                                                                        match_found <= 1'b1;

                                                                4'd12 : if(shifted_buff[47:0] == password[47:0])
                                                                        match_found <= 1'b1;

                                                                default : begin end
                                                        endcase
                                                end

                                        end
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
                        ST_IDLE : begin
                                if(init) n_state = ST_INIT;
                                else if(start && valid) n_state = ST_DATA;
                        end

                        ST_INIT : if(stop) n_state = ST_IDLE;

                        ST_DATA : if(stop) begin
                                        if(valid && match_found) n_state = ST_DONE;
                                        else                     n_state = ST_IDLE;
                        end

                        ST_DONE : n_state = ST_IDLE;

                        default : n_state = ST_IDLE;
                endcase
        end

        endmodule
