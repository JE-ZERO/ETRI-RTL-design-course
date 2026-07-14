`ifndef TASKS_UART_AXI_LITE_SV 
`define TASKS_UART_AXI_LITE_SV 
//------------------------------------------------------------------------------
//  Copyright (c) 2024 by Ando Ki.
//  All right reserved.
//  All rights are reserved by Ando Ki.
//  Do not use in any means or/and methods without Ando Ki's permission.
//------------------------------------------------------------------------------
// tasks_uart_axi_lite.sv
//------------------------------------------------------------------------------
// VERSION: 2024.08.10.
//------------------------------------------------------------------------------
//  [MACROS]
//------------------------------------------------------------------------------
// see uart_csr.v
localparam CSRA_BASE    = 32'h9000_0000;
localparam CSRA_VERSION = CSRA_BASE+8'h00
         , CSRA_NAME    = CSRA_BASE+8'h04
         , CSRA_CONTROL = CSRA_BASE+8'h10
         , CSRA_STATUS  = CSRA_BASE+8'h14
         , CSRA_TX      = CSRA_BASE+8'h18
         , CSRA_RX      = CSRA_BASE+8'h1C
         , CSRA_CLK_FREQ= CSRA_BASE+8'h20;
//------------------------------------------------------------------------------
task uart_csr;
    reg [31:0] dataR;
begin
    axi_lite_read(CSRA_VERSION, dataR); $display("VERSION 0x%08X", dataR);
    axi_lite_read(CSRA_NAME   , dataR); $display("NAME    0x%08X", dataR);
    axi_lite_read(CSRA_CONTROL, dataR); $display("CONTROL 0x%08X", dataR);
    axi_lite_read(CSRA_STATUS , dataR); $display("STATUS  0x%08X", dataR);
    axi_lite_read(CSRA_TX     , dataR); $display("TX      0x%08X", dataR);
    axi_lite_read(CSRA_RX     , dataR); $display("RX      0x%08X", dataR);
end
endtask
//------------------------------------------------------------------------------
task uart_init;
    input integer freq  ; // freq of 'ACLK'
    input integer baud  ; // baud rate
    input integer width ; // width bits (8 or 7)
    input integer parity; // 0:no, 1:odd, 2:even
    input integer stop  ; // 0:no, 1:1-bit, 2:2-bit

    reg [15:0] division;
    reg        stop_bit;
    reg        even_bit;
begin
    division = $rtoi($itor(freq)/$itor(baud)+0.5);
$display("%m freq=%0d baud=%0d division=%0d", freq, baud, division);
    stop_bit = (stop==1) ? 1'b0 : (stop==2) ? 1'b1 : 1'b0;
    even_bit = (parity==2) ? 1'b1 : 1'b0;
    axi_lite_write(CSRA_CONTROL, { 10'h0
                                 , 1'b0 //csr_ie_rx    // 21
                                 , 1'b0 //csr_ie_tx    // 20
                                 , stop_bit //csr_stop     // 19
                                 , even_bit //csr_even     // 18
                                 ,!(parity==0)//csr_parity   // 17
                                 ,!(width==8)//csr_width    // 16
                                 , division // 15:0
                                 });
end
endtask
//------------------------------------------------------------------------------
task uart_put_char;
    input [ 7:0]  ch;
    input integer blocking; // wait until all done when 1
    reg   [31:0]  D;
begin
     D = 1<<2; // csr_tx_vld
     while (D&32'h4) begin
            // wait until TX register empty
            axi_lite_read(CSRA_STATUS, D);
     end
     axi_lite_write(CSRA_TX, {24'h0, ch});
     if (blocking) begin
        D = 1<<2; // csr_tx_vld
        while (D&32'h4) begin
               // wait until TX register empty
               axi_lite_read(CSRA_STATUS, D);
        end
     end
end
endtask
//------------------------------------------------------------------------------
task uart_get_char;
    output [ 7:0] ch;
    reg    [31:0] D;
begin
     D = 32'h0;
     while (!(D&32'h8000_0000)) begin
            // wait until RX register filled
            axi_lite_read(CSRA_RX, D);
     end
     ch = D[7:0];
end
endtask
//------------------------------------------------------------------------------
// Revision History
//
// 2024.08.10: Started by Ando Ki (andoki@gmail.com)
//------------------------------------------------------------------------------
`endif // TASKS_UART_AXI_LITE_SV 
