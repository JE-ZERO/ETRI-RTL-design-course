module tb_doorlock3();

        logic clk;
        logic reset;
        logic start;
        logic [3:0] din;
        logic stop;
        logic init;
        logic unlock;

        string command;
        string digits;
        integer i;

        //DUT instantiation
        doorlock3 u_DUT(
                .clk(clk),
                .reset(reset),
                .start(start),
                .din(din),
                .stop(stop),
                .init(init),
                .unlock(unlock)
        );


        //for convenient waveform debugging
        initial begin
                $shm_open("waves.shm");
                $shm_probe("ACFM");
        end




        //CLK generation
        initial begin
                clk = 0;
                forever #5 clk = ~clk;
        end



        //Reset
        task reset_dut;
                begin
                        reset <= 1'b0;
                        start <= 1'b0;
                        init  <= 1'b0;
                        stop  <= 1'b0;
                        din   <= 4'hF;

                        repeat(2) @(posedge clk);

                        reset <= 1'b1;

                        @(posedge clk);

                        $display("Reset complete");
                end
        endtask




        //set password
        task set_password(input string pw);
                begin
                        $display("Set password %s", pw);

                        @(posedge clk); init <= 1'b1;
                        @(posedge clk); init <= 1'b0;

                        for(i=0; i<pw.len(); i++) begin
                                din <= pw.getc(i) - 8'd48;
                                @(posedge clk);
                        end

                        din <= 4'hF;
                        stop <= 1'b1;

                        @(posedge clk); stop <= 1'b0;

                        #1;

                        if(u_DUT.valid) $display("Password set success : length = %0d, password = %h", u_DUT.length, u_DUT.password);
                        else            $display("Password set failed : must be at least 4 digits");

                        repeat(3) @(posedge clk);
                end
        endtask




        //try password
        task try_password(input string pw);
                begin
                        $display("Try password %s", pw);

                        @(posedge clk); start <= 1'b1;
                        @(posedge clk); start <= 1'b0;

                        for(i=0; i<pw.len(); i++) begin
                                din <= pw.getc(i) - 8'd48;
                                @(posedge clk);
                        end

                        din <= 4'hF;
                        stop <= 1'b1;

                        @(posedge clk) stop <= 1'b0;

                        #1;

                        if(unlock) $display("Unlock success");
                        else       $display("Unlock failed");

                        repeat(3) @(posedge clk);
                end
        endtask






        initial begin
                reset = 0; start = 0; din = 4'hF; stop = 0; init = 0;
                command = ""; digits = "";

                reset_dut();

                forever begin

                        $display("====================================");
                        $display("set   : set password");
                        $display("try   : try password");
                        $display("reset : reset DUT");
                        $display("quit  : quit simulation");
                        $display("====================================");

                        $write("input command : ");
                        $fflush();
                        $fscanf(32'h8000_0000, "%s", command);

                        case(command)
                                "set"   : begin
                                        $write("input password : ");
                                        $fflush();
                                        $fscanf(32'h8000_0000, "%s", digits);

                                        set_password(digits);
                                end

                                "try"   : begin
                                        $write("input digits : ");
                                        $fflush();
                                        $fscanf(32'h8000_0000, "%s", digits);

                                        try_password(digits);
                                end

                                "reset" : reset_dut();

                                "quit"  : begin
                                        $display("Simulation finished");
                                        $finish;
                                end

                                default : $display("ERROR : Unknown command");

                        endcase
                end
        end

endmodule
