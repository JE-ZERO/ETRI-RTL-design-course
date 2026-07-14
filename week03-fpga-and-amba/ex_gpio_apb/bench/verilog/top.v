//--------------------------------------------------------
// Copyright (c) 2020 by Ando Ki.
// All right reserved.
//
// http://www.future-ds.com
// adki@future-ds.com
//--------------------------------------------------------
`timescale 1ns/1ns

module top ;

   //--------------------------------------------------------
   // Parameters
   //--------------------------------------------------------
   localparam GPIO_WIDTH = 32;
   localparam CLK_PERIOD = 10;

   //--------------------------------------------------------
   // Clock and reset
   //--------------------------------------------------------
   reg PRESETn;
   reg PCLK;

   initial begin
      PCLK = 1'b0;
      forever #(CLK_PERIOD/2) PCLK = ~PCLK;
   end

   initial begin
      PRESETn = 1'b0;
      repeat (5) @ (posedge PCLK);
      PRESETn = 1'b1;
   end

   //--------------------------------------------------------
   // APB signals
   //--------------------------------------------------------
   wire        PSEL;
   wire        PENABLE;
   wire        PWRITE;
   wire [31:0] PADDR;
   wire [31:0] PWDATA;
   wire [31:0] PRDATA;

   //--------------------------------------------------------
   // GPIO signals
   //--------------------------------------------------------
   wire [GPIO_WIDTH-1:0] GPIO_I;
   wire [GPIO_WIDTH-1:0] GPIO_O;
   wire [GPIO_WIDTH-1:0] GPIO_T;
   wire                  IRQ;

   //--------------------------------------------------------
   // Testbench APB master
   //--------------------------------------------------------
   apb_gpio_tester #(.GPIO_WIDTH(GPIO_WIDTH))
   u_tester (
        .PRESETn ( PRESETn )
      , .PCLK    ( PCLK    )
      , .PSEL    ( PSEL    )
      , .PENABLE ( PENABLE )
      , .PWRITE  ( PWRITE  )
      , .PADDR   ( PADDR   )
      , .PWDATA  ( PWDATA  )
      , .PRDATA  ( PRDATA  )
      , .GPIO_I  ( GPIO_I  )
      , .GPIO_O  ( GPIO_O  )
      , .GPIO_T  ( GPIO_T  )
      , .IRQ     ( IRQ     )
   );

   //--------------------------------------------------------
   // DUT: APB GPIO
   //--------------------------------------------------------
   gpio_apb #(.GPIO_WIDTH(GPIO_WIDTH))
   u_gpio (
        .PRESETn ( PRESETn )
      , .PCLK    ( PCLK    )
      , .PSEL    ( PSEL    )
      , .PENABLE ( PENABLE )
      , .PWRITE  ( PWRITE  )
      , .PADDR   ( PADDR   )
      , .PWDATA  ( PWDATA  )
      , .GPIO_I  ( GPIO_I  )
      , .GPIO_O  ( GPIO_O  )
      , .GPIO_T  ( GPIO_T  )
      , .IRQ     ( IRQ     )
      , .PRDATA  ( PRDATA  )
   );

endmodule
