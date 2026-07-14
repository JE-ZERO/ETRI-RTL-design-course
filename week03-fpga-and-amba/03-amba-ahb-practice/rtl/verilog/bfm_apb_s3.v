module bfm_apb_s3 

#(parameter P_DWIDTH = 32,
            P_STRB = P_DWIDTH/8,
            P_NUM = 3,
            P_ADDR_START0 = 16'h0000, P_ADDR_SIZE0 = 16'h0010,
            P_ADDR_START1 = 16'h1000, P_ADDR_SIZE1 = 16'h0010,
            P_ADDR_START2 = 16'h2000, P_ADDR_SIZE2 = 16'h0010) 
                  
(
   input PRESETn,
   input PCLK,
   input [P_DWIDTH-1:0] PRDATA0,
   input [P_DWIDTH-1:0] PRDATA1,
   input [P_DWIDTH-1:0] PRDATA2,
   output reg [P_NUM-1:0] PSEL,
   output reg [31:0] PADDR,
   output reg PENABLE,
   output reg PWRITE,
   output reg [P_DWIDTH-1:0] PWDATA

   `ifdef AMBA3,
   input [P_NUM-1:0] PREADY,
   input [P_NUM-1:0] PSLAVERR
   `endif

   `ifdef AMBA4,
   output reg [2:0] PPROT,
   output reg [P_STRB-1:0] PSTRB
   `endif
);
   
endmodule