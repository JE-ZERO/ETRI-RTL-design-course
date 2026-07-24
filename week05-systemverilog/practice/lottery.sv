module lottery;

        class randclass;
                randc bit [5:0] num[6];




                constraint c1 {num[0] >= 1; num[0] <= 45;}
                constraint c2 {num[1] >= 1; num[1] <= 45;}
                constraint c3 {num[2] >= 1; num[2] <= 45;}
                constraint c4 {num[3] >= 1; num[3] <= 45;}
                constraint c5 {num[4] >= 1; num[4] <= 45;}
                constraint c6 {num[5] >= 1; num[5] <= 45;}




               function new(int seed=327);
                       srandom (seed);
               endfunction

        endclass

        randclass myrand = new();

        int test;

        initial begin

                myrand.randomize();

                $display("Lotto 6/45 number (2026/7/25)");

                for(int i=0; i<6; i++) begin
                        $display("Number %d : %d", i+1, myrand.num[i]);
                //      assert(myrand.num[i]==4);
                end
        end
endmodule
