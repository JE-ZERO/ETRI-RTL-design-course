module tb_doorlock1();

        logic clk;
        logic reset;
        logic start;
        logic [3:0] din;
        logic stop;
        logic unlock;

        doorlock1 u_DUT(
                .clk(clk),
                .reset(reset),
                .start(start),
                .din(din),
                .stop(stop),
                .unlock(unlock)
        );

        initial begin
                $shm_open("wave.shm");
                $shm_probe("ACFM");
        end

        initial begin
                clk = 0;
                forever #5 clk = ~clk;
        end


        initial begin
                reset = 0; start = 0; din = 4'hF; stop = 0;

                @(posedge clk);

                @(posedge clk); reset <= 1;

                @(posedge clk);

                @(posedge clk); start <= 1;

                @(posedge clk); start <= 0; din <= 4'd0;

                @(posedge clk); din <= 4'd3;

                @(posedge clk); din <= 4'd2;

                @(posedge clk); din <= 4'd7;

                @(posedge clk); din <= 4'hF; stop <= 1;

                @(posedge clk); stop <= 0;

                repeat(20) @(posedge clk);

                $finish;
        end

endmodule
