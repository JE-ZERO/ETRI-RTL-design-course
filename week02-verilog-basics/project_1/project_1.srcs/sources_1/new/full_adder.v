module full_adder(output cout, sum,
                  input a, b, cin);

wire B, C1, C2;

half_adder HA1(.a(a), .b(b), .sum(B), .carry(C2));

half_adder HA2(.a(cin), .b(B), .sum(sum), .carry(C1));

assign cout=C1 | C2;

endmodule