//--------------------------------------------------------
// Copyright (c) 2020 by Ando Ki.
// All right reserved.
//
// http://www.future-ds.com
// adki@future-ds.com
//--------------------------------------------------------
// mem_apb.h
//--------------------------------------------------------
// VERSION = 2020.07.11.
//--------------------------------------------------------
// Macros and parameters:
//     SIZE_IN_BYTES: Size of memory in bytes
//     DELAY:         The number of clocks until PREADY
//--------------------------------------------------------
`ifdef AMBA_APB4
`ifndef AMBA_APB3
ERROR AMBA_APB3 shouldb edefined when AMBA_APB4 is defined
`endif
`endif

module mem_apb
     #(parameter SIZE_IN_BYTES=1024  // memory size in bytes
               , DELAY=0           ) // access delay if any for AMBA_APB3/AMBA_APB4
(
     input  wire        PRESETn
   , input  wire        PCLK
   , input  wire        PSEL
   , input  wire [31:0] PADDR
   , input  wire        PENABLE
   , input  wire        PWRITE
   , input  wire [31:0] PWDATA
   , output reg  [31:0] PRDATA
`ifdef AMBA3
   , output wire        PREADY
   , output wire        PSLVERR
`endif
`ifdef AMBA_APB3
   , output wire        PREADY
   , output wire        PSLVERR
`endif
`ifdef AMBA4
   , input  wire [ 2:0] PPROT
   , input  wire [ 3:0] PSTRB
`endif
`ifdef AMBA_APB4
   , input  wire [ 2:0] PPROT
   , input  wire [ 3:0] PSTRB
`endif
);
    //----------------------------------------------------
    function integer clogb2;
    input integer depth;
    integer value;
    begin
        value = depth - 1;
        for (clogb2=0; value>0; clogb2=clogb2+1) begin
            value = value >> 1;
        end
    end
    endfunction

    localparam WORD_SIZE_IN_BYTES = 4;
    localparam WORD_DEPTH         = SIZE_IN_BYTES/WORD_SIZE_IN_BYTES;
    localparam WORD_ADDR_WIDTH    = clogb2(WORD_DEPTH);

    (* ram_style = "block" *) reg [31:0] mem[0:WORD_DEPTH-1];

`ifdef AMBA4
    wire [3:0] wr_strb = PSTRB;
`elsif AMBA_APB4
    wire [3:0] wr_strb = PSTRB;
`else
    wire [3:0] wr_strb = 4'hF;
`endif

    wire [WORD_ADDR_WIDTH-1:0] word_addr = PADDR[WORD_ADDR_WIDTH+1:2];
    wire        apb_fire  = PSEL & PENABLE
`ifdef AMBA3
                          & PREADY
`endif
`ifdef AMBA_APB3
                          & PREADY
`endif
                          ;

`ifdef AMBA3
    reg [31:0] wait_count;
    assign PREADY  = (DELAY==0) ? 1'b1 : (wait_count>=DELAY);
    assign PSLVERR = 1'b0;

    always @ (posedge PCLK or negedge PRESETn) begin
        if (PRESETn==1'b0) begin
            wait_count <= 0;
        end else if (PSEL & ~PENABLE) begin
            wait_count <= 0;
        end else if (PSEL & PENABLE & ~PREADY) begin
            wait_count <= wait_count + 1;
        end
    end
`elsif AMBA_APB3
    reg [31:0] wait_count;
    assign PREADY  = (DELAY==0) ? 1'b1 : (wait_count>=DELAY);
    assign PSLVERR = 1'b0;

    always @ (posedge PCLK or negedge PRESETn) begin
        if (PRESETn==1'b0) begin
            wait_count <= 0;
        end else if (PSEL & ~PENABLE) begin
            wait_count <= 0;
        end else if (PSEL & PENABLE & ~PREADY) begin
            wait_count <= wait_count + 1;
        end
    end
`endif

    always @ (posedge PCLK) begin
        if (apb_fire) begin
            if (PWRITE) begin
                if (wr_strb[0]) mem[word_addr][ 7: 0] <= PWDATA[ 7: 0];
                if (wr_strb[1]) mem[word_addr][15: 8] <= PWDATA[15: 8];
                if (wr_strb[2]) mem[word_addr][23:16] <= PWDATA[23:16];
                if (wr_strb[3]) mem[word_addr][31:24] <= PWDATA[31:24];
            end
            PRDATA <= mem[word_addr];
        end
    end
    //----------------------------------------------------
endmodule

//--------------------------------------------------------
// Revision history
//
// 2020.07.11: Started by Ando Ki (adki@future-ds.com)
//--------------------------------------------------------
