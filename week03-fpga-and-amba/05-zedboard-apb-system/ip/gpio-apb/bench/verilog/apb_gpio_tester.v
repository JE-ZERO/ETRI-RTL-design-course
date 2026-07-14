/*
 * Copyright (c) 2020 by Ando Ki.
 * All right reserved.
 *
 * http://www.future-ds.com
 * adki@future-ds.com
 *
 */
`timescale 1ns/1ns

module apb_gpio_tester
     #(parameter GPIO_WIDTH = 32)
(
      input  wire                  PRESETn
    , input  wire                  PCLK
    , output reg                   PSEL
    , output reg                   PENABLE
    , output reg                   PWRITE
    , output reg  [31:0]           PADDR
    , output reg  [31:0]           PWDATA
    , input  wire [31:0]           PRDATA
    , output reg  [GPIO_WIDTH-1:0] GPIO_I
    , input  wire [GPIO_WIDTH-1:0] GPIO_O
    , input  wire [GPIO_WIDTH-1:0] GPIO_T
    , input  wire                  IRQ
);

   `include "apb_tasks.v"

   localparam LINECONTROL = 32'h0000_0000;
   localparam LINEREG     = 32'h0000_0004;
   localparam WORD_SIZE   = 3'd4;

   reg [31:0] rdata;
   reg [31:0] expected;
   reg [GPIO_WIDTH-1:0] gpio_expected;
   integer error;
   reg done;

   //--------------------------------------------------------
   // Test sequence
   //--------------------------------------------------------
   initial begin
      PSEL    = 1'b0;
      PENABLE = 1'b0;
      PWRITE  = 1'b0;
      PADDR   = 32'h0000_0000;
      PWDATA  = 32'h0000_0000;
      GPIO_I  = {GPIO_WIDTH{1'b0}};
      error   = 0;
      done    = 1'b0;

      wait (PRESETn == 1'b1);
      repeat (5) @ (posedge PCLK);

      gpio_basic_test;

      repeat (5) @ (posedge PCLK);
      done = 1'b1;

      if (error == 0) begin
         $display($time,,"%m GPIO APB test PASS");
      end
      else begin
         $display($time,,"%m GPIO APB test FAIL, error=%0d", error);
      end

      $finish;
   end

   //--------------------------------------------------------
   // Basic GPIO APB register test
   //--------------------------------------------------------
   task gpio_basic_test;
   begin
      //-----------------------------------------------------
      // 1. After reset, line control register should be zero.
      //    All pins are input mode, so GPIO_T should be all 1.
      //-----------------------------------------------------
      apb_read(LINECONTROL, WORD_SIZE, rdata);
      check_data("reset line control", rdata, 32'h0000_0000);
      check_gpio("reset gpio_t", GPIO_T, {GPIO_WIDTH{1'b1}});
      check_gpio("reset gpio_o", GPIO_O, {GPIO_WIDTH{1'b0}});
      check_bit ("irq", IRQ, 1'b0);

      //-----------------------------------------------------
      // 2. In input mode, reading Line Register returns GPIO_I.
      //-----------------------------------------------------
      GPIO_I = 32'hA5A5_F00D;
      apb_read(LINEREG, WORD_SIZE, rdata);
      expected = 32'h0000_0000;
      expected[GPIO_WIDTH-1:0] = GPIO_I;
      check_data("input mode line read", rdata, expected);

      //-----------------------------------------------------
      // 3. Writing Line Register in input mode has no effect.
      //-----------------------------------------------------
      apb_write(LINEREG, WORD_SIZE, 32'hFFFF_FFFF);
      repeat (1) @ (posedge PCLK);
      check_gpio("input mode line write ignored", GPIO_O, {GPIO_WIDTH{1'b0}});

      //-----------------------------------------------------
      // 4. Program all pins to output mode.
      //-----------------------------------------------------
      apb_write(LINECONTROL, WORD_SIZE, 32'hFFFF_FFFF);
      apb_read(LINECONTROL, WORD_SIZE, rdata);
      expected = 32'h0000_0000;
      expected[GPIO_WIDTH-1:0] = {GPIO_WIDTH{1'b1}};
      check_data("output mode line control", rdata, expected);
      check_gpio("output mode gpio_t", GPIO_T, {GPIO_WIDTH{1'b0}});

      //-----------------------------------------------------
      // 5. Write Line Register and check GPIO_O.
      //-----------------------------------------------------
      gpio_expected = 32'h5A5A_1234;
      apb_write(LINEREG, WORD_SIZE, gpio_expected);
      repeat (1) @ (posedge PCLK);
      check_gpio("output mode gpio_o", GPIO_O, gpio_expected);

      //-----------------------------------------------------
      // 6. Reading Line Register still returns current GPIO_I.
      //-----------------------------------------------------
      GPIO_I = 32'h1234_ABCD;
      apb_read(LINEREG, WORD_SIZE, rdata);
      expected = 32'h0000_0000;
      expected[GPIO_WIDTH-1:0] = GPIO_I;
      check_data("line read returns gpio_i", rdata, expected);
   end
   endtask

   //--------------------------------------------------------
   // Check helpers
   //--------------------------------------------------------
   task check_data;
      input [8*32-1:0] name;
      input [31:0] got;
      input [31:0] exp;
      begin
         if (got !== exp) begin
            error = error + 1;
            $display($time,,"%m ERROR %0s: got=0x%08x expected=0x%08x",
                     name, got, exp);
         end
      end
   endtask

   task check_gpio;
      input [8*32-1:0] name;
      input [GPIO_WIDTH-1:0] got;
      input [GPIO_WIDTH-1:0] exp;
      begin
         if (got !== exp) begin
            error = error + 1;
            $display($time,,"%m ERROR %0s: got=0x%08x expected=0x%08x",
                     name, got, exp);
         end
      end
   endtask

   task check_bit;
      input [8*32-1:0] name;
      input got;
      input exp;
      begin
         if (got !== exp) begin
            error = error + 1;
            $display($time,,"%m ERROR %0s: got=%b expected=%b",
                     name, got, exp);
         end
      end
   endtask

endmodule
