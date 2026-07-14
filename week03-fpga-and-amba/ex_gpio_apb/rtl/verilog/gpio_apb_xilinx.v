//------------------------------------------------------------------------------
// Copyright (c) 2026 by Future Design Systems.
// http://www.future-ds.com
//------------------------------------------------------------------------------
// gpio_apb_xilinx.v
//------------------------------------------------------------------------------
module gpio_apb_xilinx
     #(parameter P_WIDTH=5) // bit-width for gpio
(
    (* X_INTERFACE_PARAMETER = "POLARITY ACTIVE_LOW" *)
    (* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 PRESETn RST"    *) input  wire         PRESETn,
    (* X_INTERFACE_PARAMETER = "ASSOCIATED_BUSIF S_APB:M1_APB:M2_APB,ASSOCIATED_RESET PRESETn" *)
    (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 PCLK CLK"       *) input  wire         PCLK,
    (* X_INTERFACE_PARAMETER = "ASSOCIATED_BUSIF S_APB,ASSOCIATED_RESET PRESETn,CLK_DOMAIN PCLK" *)
    (* X_INTERFACE_INFO = "xilinx.com:interface:apb:1.0 S_APB PADDR"   *) input  wire [31:0]  S_APB_PADDR,
    (* X_INTERFACE_INFO = "xilinx.com:interface:apb:1.0 S_APB PENABLE" *) input  wire         S_APB_PENABLE,
    (* X_INTERFACE_INFO = "xilinx.com:interface:apb:1.0 S_APB PWRITE"  *) input  wire         S_APB_PWRITE,
    (* X_INTERFACE_INFO = "xilinx.com:interface:apb:1.0 S_APB PWDATA"  *) input  wire [31:0]  S_APB_PWDATA,
    (* X_INTERFACE_INFO = "xilinx.com:interface:apb:1.0 S_APB PSEL"    *) input  wire         S_APB_PSEL,
    (* X_INTERFACE_INFO = "xilinx.com:interface:apb:1.0 S_APB PRDATA"  *) output wire [31:0]  S_APB_PRDATA,
    (* X_INTERFACE_INFO = "xilinx.com:interface:apb:1.0 S_APB PREADY"  *) output wire         S_APB_PREADY,
    (* X_INTERFACE_INFO = "xilinx.com:interface:apb:1.0 S_APB PSLVERR" *) output wire         S_APB_PSLVERR,
    (* X_INTERFACE_INFO = "xilinx.com:interface:apb:1.0 S_APB PSTRB"   *) input  wire [ 3:0]  S_APB_PSTRB

    , input  wire [P_WIDTH-1:0] gpio_in
    , output wire [P_WIDTH-1:0] gpio_out
    , output wire [P_WIDTH-1:0] gpio_dir // 0 for output, 1 for input
    , output wire               interrupt
);
    //--------------------------------------------------------------------------
    assign S_APB_PREADY=1'b1;
    assign S_APB_PSLVERR=1'b0;
    //--------------------------------------------------------------------------
    gpio_apb #(.GPIO_WIDTH(P_WIDTH))
    u_gpio_apb (
          .PRESETn ( PRESETn )
        , .PCLK    ( PCLK    )
        , .PADDR   ( S_APB_PADDR   )
        , .PENABLE ( S_APB_PENABLE )
        , .PWRITE  ( S_APB_PWRITE  )
        , .PWDATA  ( S_APB_PWDATA  )
        , .PSEL    ( S_APB_PSEL    )
        , .PRDATA  ( S_APB_PRDATA  )
        , .GPIO_I  ( gpio_in       )
        , .GPIO_O  ( gpio_out      )
        , .GPIO_T  ( gpio_dir      )
        , .IRQ     ( interrupt     )
    );
    //--------------------------------------------------------------------------
endmodule
//------------------------------------------------------------------------------
// Revision History
//
// 2026.07.09: Started by Ando Ki (adki@future-ds.com)
//------------------------------------------------------------------------------
