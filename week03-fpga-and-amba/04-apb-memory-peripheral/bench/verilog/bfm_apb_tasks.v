`ifndef BFM_APB_TASKS_V
`define BFM_APB_TASKS_V
//--------------------------------------------------------
// Copyright (c) 2020 by Ando Ki.
// All right reserved.
//
// http://www.future-ds.com
// adki@future-ds.com
//--------------------------------------------------------
// bfm_apb_tasks.h
//--------------------------------------------------------
// VERSION = 2020.07.10.
//--------------------------------------------------------
task apb_write;
input [31:0] addr;
input [31:0] data;
input [ 2:0] size;
begin

    @ (posedge PCLK); #1;
    PADDR   = addr;
    PWDATA  = data;
    PWRITE  = 1'b1;
    PSEL    = decoder(addr);
    PENABLE = 1'b0;
    PPROT   = 3'b000;
    PSTRB   = get_pstrob(addr, size);

    @ (posedge PCLK); #1;
    PENABLE = 1'b1;
    while (get_pready(addr)==1'b0) begin
        @ (posedge PCLK); #1;
    end
    @ (posedge PCLK); #1;
    if (get_pslverr(addr)==1'b1) begin
        $display($time,,"%m APB write slave error at A:0x%08x D:0x%08x", addr, data);
    end

    PSEL    = {P_NUM{1'b0}};
    PENABLE = 1'b0;
    PWRITE  = 1'b0;
    PSTRB   = {P_STRB{1'b0}};

end
endtask
//--------------------------------------------------------
task apb_read;
input  [31:0] addr;
output [31:0] data;
input  [ 2:0] size;
begin

    @ (posedge PCLK); #1;
    PADDR   = addr;
    PWRITE  = 1'b0;
    PSEL    = decoder(addr);
    PENABLE = 1'b0;
    PPROT   = 3'b000;
    PSTRB   = {P_STRB{1'b0}};

    @ (posedge PCLK); #1;
    PENABLE = 1'b1;
    while (get_pready(addr)==1'b0) begin
        @ (posedge PCLK); #1;
    end
    @ (posedge PCLK); #1;
    data = get_prdata(addr);
    if (get_pslverr(addr)==1'b1) begin
        $display($time,,"%m APB read slave error at A:0x%08x", addr);
    end

    PSEL    = {P_NUM{1'b0}};
    PENABLE = 1'b0;

end
endtask
//--------------------------------------------------------
// It makes PSEL[P_NUM-1] signals according to PADDR[31:0].
function [P_NUM-1:0] decoder;
input [31:0] addr;
begin
    decoder = {P_NUM{1'b0}};
    if (P_NUM>=1) begin
         if ((addr>=P_ADDR_START0)&&
             (addr<=P_ADDR_START0+P_SIZE0-1)) decoder = 1<<0;
    end
    if (P_NUM>=2) begin
         if ((addr>=P_ADDR_START1)&&
             (addr<=P_ADDR_START1+P_SIZE1-1)) decoder = 1<<1;
    end
    if (P_NUM>=3) begin
         if ((addr>=P_ADDR_START2)&&
             (addr<=P_ADDR_START2+P_SIZE2-1)) decoder = 1<<2;
    end
    if (P_NUM>=4) begin
         if ((addr>=P_ADDR_START3)&&
             (addr<=P_ADDR_START3+P_SIZE3-1)) decoder = 1<<3;
    end
    if (decoder==0) begin
         $display($time,,"%m ERROR address range.");
    end
end
endfunction
//--------------------------------------------------------
function [P_STRB-1:0] get_pstrob;
input [31:0] addr;
input [ 2:0] size;
begin
    case (size)
    3'd1: get_pstrob = 4'b0001 << addr[1:0];
    3'd2: get_pstrob = addr[1] ? 4'b1100 : 4'b0011;
    3'd4: get_pstrob = 4'b1111;
    default: begin
        get_pstrob = 4'b0000;
        $display($time,,"%m ERROR unsupported APB access size: %0d", size);
    end
    endcase
end
endfunction
//--------------------------------------------------------
// It selects one of PREADY[P_NUM-1] signals according to PADDR[31:0].
function get_pready;
input [31:0] addr;
begin
    get_pready = 1'b1;
    if (P_NUM>=1) begin
         if ((addr>=P_ADDR_START0)&&
             (addr<=P_ADDR_START0+P_SIZE0-1)) get_pready = PREADY[0];
    end
    if (P_NUM>=2) begin
         if ((addr>=P_ADDR_START1)&&
             (addr<=P_ADDR_START1+P_SIZE1-1)) get_pready = PREADY[1];
    end
    if (P_NUM>=3) begin
         if ((addr>=P_ADDR_START2)&&
             (addr<=P_ADDR_START2+P_SIZE2-1)) get_pready = PREADY[2];
    end
    if (P_NUM>=4) begin
         if ((addr>=P_ADDR_START3)&&
             (addr<=P_ADDR_START3+P_SIZE3-1)) get_pready = PREADY[3];
    end
end
endfunction
//--------------------------------------------------------
// It selects one of PSLVERR[P_NUM-1] signals according to PADDR[31:0].
function get_pslverr;
input [31:0] addr;
begin
    get_pslverr = 1'b0;
    if (P_NUM>=1) begin
         if ((addr>=P_ADDR_START0)&&
             (addr<=P_ADDR_START0+P_SIZE0-1)) get_pslverr = PSLVERR[0];
    end
    if (P_NUM>=2) begin
         if ((addr>=P_ADDR_START1)&&
             (addr<=P_ADDR_START1+P_SIZE1-1)) get_pslverr = PSLVERR[1];
    end
    if (P_NUM>=3) begin
         if ((addr>=P_ADDR_START2)&&
             (addr<=P_ADDR_START2+P_SIZE2-1)) get_pslverr = PSLVERR[2];
    end
    if (P_NUM>=4) begin
         if ((addr>=P_ADDR_START3)&&
             (addr<=P_ADDR_START3+P_SIZE3-1)) get_pslverr = PSLVERR[3];
    end
end
endfunction
//--------------------------------------------------------
// It selects one of PRDATA[P_NUM-1] signals according to PADDR[31:0].
function [31:0] get_prdata;
input  [31:0] addr;
begin
    get_prdata = 32'h0;
    if (P_NUM>=1) begin
         if ((addr>=P_ADDR_START0)&&
             (addr<=P_ADDR_START0+P_SIZE0-1)) get_prdata = PRDATA[0*P_DWIDTH+:P_DWIDTH];
    end
    if (P_NUM>=2) begin
         if ((addr>=P_ADDR_START1)&&
             (addr<=P_ADDR_START1+P_SIZE1-1)) get_prdata = PRDATA[1*P_DWIDTH+:P_DWIDTH];
    end
    if (P_NUM>=3) begin
         if ((addr>=P_ADDR_START2)&&
             (addr<=P_ADDR_START2+P_SIZE2-1)) get_prdata = PRDATA[2*P_DWIDTH+:P_DWIDTH];
    end
    if (P_NUM>=4) begin
         if ((addr>=P_ADDR_START3)&&
             (addr<=P_ADDR_START3+P_SIZE3-1)) get_prdata = PRDATA[3*P_DWIDTH+:P_DWIDTH];
    end
end
endfunction
//--------------------------------------------------------
// Revision history
//
// 2020.07.10: Started by Ando Ki (adki@future-ds.com)
//--------------------------------------------------------
`endif
