`ifndef APB_TASKS_V
`define APB_TASKS_V
/*
 * Copyright (c) 2020 by Ando Ki.
 * All right reserved.
 *
 * http://www.future-ds.com
 * adki@future-ds.com
 *
 */

   //--------------------------------------------------------
   // generate a read transaction on AMBA APB
   // apb_read(address, size, data)
   //--------------------------------------------------------
   task apb_read;
        input  [31:0] address;
        input  [2:0]  size;
        output [31:0] data;
        begin
            @ (posedge PCLK); #1;
            PADDR   = address;
            PWRITE  = 1'b0;
            PSEL    = 1'b1;
            PENABLE = 1'b0;

            @ (posedge PCLK); #1;
            PENABLE = 1'b1;
            data    = PRDATA;

            @ (posedge PCLK); #1;
            PSEL    = 1'b0;
            PENABLE = 1'b0;
        end
   endtask

   //--------------------------------------------------------
   // generate a write transaction on AMBA APB
   // apb_write(address, size, data)
   //--------------------------------------------------------
   task apb_write;
        input [31:0] address;
        input [2:0]  size;
        input [31:0] data;
        begin
            @ (posedge PCLK); #1;
            PADDR   = address;
            PWDATA  = data;
            PWRITE  = 1'b1;
            PSEL    = 1'b1;
            PENABLE = 1'b0;

            @ (posedge PCLK); #1;
            PENABLE = 1'b1; 

            @ (posedge PCLK); #1;
            PSEL    = 1'b0;
            PENABLE = 1'b0;
        end
   endtask

`endif
