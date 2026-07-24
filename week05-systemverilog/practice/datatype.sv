module _datatype;

logic [3:0] value;

integer a;
int b;

initial begin

        value=4'b10xz;
        a=value;
        b=value;

        $display("a = %b", a[3:0]);
        $display("b = %b", b[3:0]);


end
endmodule
