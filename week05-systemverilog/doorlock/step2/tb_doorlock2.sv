module tb_doorlock2();

        logic clk;
        logic reset;
        logic start;
        logic [3:0] din;
        logic stop;
        logic init;
        logic unlock;


        //DUT instantiation
        doorlock2 u_DUT(
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



        initial begin
                reset = 0; start = 0; din = 4'hF; stop = 0; init = 0;

                @(posedge clk); reset <= 1'b1;

                @(posedge clk);

                @(posedge clk); init <= 1'b1;

                @(posedge clk); init <= 1'b0; din <= 4'h0;

                @(posedge clk); din <= 4'h3;

                @(posedge clk); din <= 4'h2;

                @(posedge clk); din <= 4'h7;

                @(posedge clk); din <= 4'hF; stop <= 1'b1;

                @(posedge clk); stop <= 1'b0;

                repeat(3) @(posedge clk);

                @(posedge clk); start <= 1'b1;

                @(posedge clk); start <= 1'b0; din <= 4'h3;

                @(posedge clk); din <= 4'h2;

                @(posedge clk); din <= 4'h7;

                @(posedge clk); din <= 4'hF; stop <= 1'b1;

                @(posedge clk); stop <= 1'b0;

                repeat(3) @(posedge clk);

                @(posedge clk); start <= 1'b1;

                @(posedge clk); start <= 1'b0; din <= 4'h0;

                @(posedge clk); din <= 4'h3;

                @(posedge clk); din <= 4'h2;

                @(posedge clk); din <= 4'h7;

                @(posedge clk); din <= 4'hF; stop <= 1'b1;

                @(posedge clk); stop <= 1'b0;

                repeat(3) @(posedge clk);

                @(posedge clk); start <= 1'b1;

                @(posedge clk); start <= 1'b0; din <= 4'h1;

                @(posedge clk); din <= 4'h2;

                @(posedge clk); din <= 4'h0;

                @(posedge clk); din <= 4'h3;

                @(posedge clk); din <= 4'h2;

                @(posedge clk); din <= 4'h7;

                @(posedge clk); din <= 4'hF; stop <= 1'b1;

                @(posedge clk); stop <= 1'b0;

                repeat(3) @(posedge clk);

                $finish;
        end

endmodule
