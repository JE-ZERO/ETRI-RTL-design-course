`ifndef TASKS_TTY_SV 
`define TASKS_TTY_SV 
//------------------------------------------------------------------------------
//  Copyright (c) 2024 by Ando Ki.
//  All right reserved.
//  All rights are reserved by Ando Ki.
//  Do not use in any means or/and methods without Ando Ki's permission.
//------------------------------------------------------------------------------
// tasks_tty.sv
//------------------------------------------------------------------------------
// VERSION: 2024.08.10.
//------------------------------------------------------------------------------
// Send 'msg_len' characters
task tty_send;
    input [ 7:0]  msg[];
    input integer msg_len; // num of characters
    input integer baud;
    input integer width; // 8 or 7
    input integer parity; // 0:no, 1:odd, 2:even
    input integer stop; // 0:no, 1:1-bit, 2:2-bit

    integer   interval;
    reg       pebit;
    reg [7:0] data;
begin
    if (msg_len>msg.size()) begin
        $display("%m msg length mis-match.");
        disable tty_send;
    end
    interval = (1_000_000_000/baud); // nsec
    pebit = 1'b0;
    for (int idx=0; idx<msg_len; idx=idx+1) begin
        data = msg[idx];
        uart_tx = 1'b0; // start bit
        #(interval);
        pebit = 1'b0;
        for (int idy=0; idy<width; idy=idy+1) begin
            uart_tx = data[idy];
            pebit = pebit^data[idy]; // 1 for odd
            #(interval);
        end // for (int idy
        case (parity)
            2: begin uart_tx = pebit; // make even
                     #(interval);
               end
            1: begin uart_tx = ~pebit; // make odd
                     #(interval);
               end
            0: begin end // no parity
            default: $display("%m unknown parity mode");
        endcase
        case (stop)
            2: begin uart_tx = 1'b1; // two stop bits
                     #(interval);
                     #(interval);
               end
            1: begin uart_tx = 1'b1; // one stop bit
                     #(interval);
               end
            default: $display("%m unknown stop mode");
        endcase
    end // for (int idx
end
endtask
//------------------------------------------------------------------------------
// Received 'msg_len' characters
task tty_receive;
    inout [ 7:0]  msg[];
    input  integer msg_len; // num of char to receive
    input  integer baud;
    input  integer width; // 8 or 7
    input  integer parity; // 0:no, 1:odd, 2:even
    input  integer stop; // 0:no, 1:1-bit, 2:2-bit

    integer   interval;
    reg       pebit;
    reg [7:0] data;
begin
    if (msg_len>msg.size()) begin
        $display("%m msg length mis-match.");
        disable tty_receive;
    end
    for (int idx=0; idx<msg_len; idx=idx+1) msg[idx] = 8'h0;
    interval = (1_000_000_000/baud); // nsec
    pebit = 1'b0;
    data  = 8'h0;
    for (int idx=0; idx<msg_len; idx=idx+1) begin
        @ (negedge uart_rx); // wait start
        #(interval*1.5);
        pebit = 1'b0;
        for (int idy=0; idy<width; idy=idy+1) begin
            data[idy] = uart_rx;
            pebit = pebit^uart_rx; // 1 for odd
            #(interval);
        end // for (int idy
        msg[idx] = data;
        case (parity)
            2: begin if (pebit^uart_rx) // check even
                         $display($time,,"%m even-parity error");
                     #(interval);
               end
            1: begin if (!(pebit^uart_rx)) // check odd
                         $display($time,,"%m odd-parity error");
                     #(interval);
               end
            0: begin end // no parity
            default: $display("%m unknown parity mode");
        endcase
        case (stop)
            2: begin if (uart_rx!=1'b1) // two stop bits
                         $display($time,,"%m first two-stop bit error");
                     #(interval);
                     if (uart_rx!=1'b1) // two stop bits
                         $display($time,,"%m second two-stop bit error");
                     #(interval*0.2);
               end
            1: begin if (uart_rx!=1'b1) // one stop bit
                         $display($time,,"%m one-stop bit error");
                     #(interval*0.2);
               end
            default: $display("%m unknown stop mode");
        endcase
    end // for (int idx
end
endtask
//------------------------------------------------------------------------------
// Revision History
//
// 2024.08.10: Started by Ando Ki (andoki@gmail.com)
//------------------------------------------------------------------------------
`endif // TASKS_TTY_SV 
