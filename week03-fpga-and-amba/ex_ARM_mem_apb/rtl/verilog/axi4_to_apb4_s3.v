//------------------------------------------------------------------------------
module axi4_to_apb4_s3
     #(parameter integer AXI_WIDTH_ID  = 4 // ID width in bits
      ,parameter integer AXI_WIDTH_ADDR=32 // address width
      ,parameter integer AXI_WIDTH_DATA=32 // data width
      ,parameter integer AXI_WIDTH_STRB=(AXI_WIDTH_DATA/8) // data strobe width
      ,parameter integer NUM_PSLAVE    =3
      ,parameter integer WIDTH_PAD     =32 // address width
      ,parameter integer WIDTH_PDA     =32 // data width
      ,parameter integer WIDTH_PDS     =(WIDTH_PDA/8) // data strobe width
      ,parameter integer ADDR_PBASE0   =32'hC0000000, PSIZE0='h1000
      ,parameter integer ADDR_PBASE1   =32'hC0001000, PSIZE1='h1000
      ,parameter integer ADDR_PBASE2   =32'hC0002000, PSIZE2='h1000
      ,parameter         CLOCK_SYNC    ="SYNC")
(
    (* X_INTERFACE_PARAMETER = "POLARITY ACTIVE_LOW" *)
    (* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 axi_aresetn RST"  *) input  wire                      axi_aresetn,
    (* X_INTERFACE_PARAMETER = "ASSOCIATED_BUSIF s_axi:m_axil, ASSOCIATED_RESET axi_aresetn" *)
    (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 axi_aclk CLK"     *) input  wire                      axi_aclk,
    (* X_INTERFACE_PARAMETER = "ASSOCIATED_BUSIF s_axi,ASSOCIATED_RESET axi_aresetn,CLK_DOMAIN axi_aclk,\
                                RUSER_WIDTH 0,WUSER_WIDTH 0,ARUSER_WIDTH 0,AWUSER_WIDTH 0,\
                                HAS_CACHE 0,HAS_LOCK 0,HAS_PROT 0,HAS_QOS 0,HAS_REGION 0" *)
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi AWID"    *) input  wire [AXI_WIDTH_ID-1:0]   s_axi_awid,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi AWADDR"  *) input  wire [AXI_WIDTH_ADDR-1:0] s_axi_awaddr,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi AWLEN"   *) input  wire [ 7:0]               s_axi_awlen,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi AWSIZE"  *) input  wire [ 2:0]               s_axi_awsize,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi AWBURST" *) input  wire [ 1:0]               s_axi_awburst,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi AWVALID" *) input  wire                      s_axi_awvalid,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi AWREADY" *) output wire                      s_axi_awready,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi WID"     *) input  wire [AXI_WIDTH_ID-1:0]   s_axi_wid,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi WDATA"   *) input  wire [AXI_WIDTH_DATA-1:0] s_axi_wdata,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi WSTRB"   *) input  wire [AXI_WIDTH_STRB-1:0] s_axi_wstrb,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi WLAST"   *) input  wire                      s_axi_wlast,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi WVALID"  *) input  wire                      s_axi_wvalid,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi WREADY"  *) output wire                      s_axi_wready,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi BID"     *) output wire [AXI_WIDTH_ID-1:0]   s_axi_bid,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi BRESP"   *) output wire [ 1:0]               s_axi_bresp,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi BVALID"  *) output wire                      s_axi_bvalid,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi BREADY"  *) input  wire                      s_axi_bready,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi ARID"    *) input  wire [AXI_WIDTH_ID-1:0]   s_axi_arid,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi ARADDR"  *) input  wire [AXI_WIDTH_ADDR-1:0] s_axi_araddr,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi ARLEN"   *) input  wire [ 7:0]               s_axi_arlen,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi ARSIZE"  *) input  wire [ 2:0]               s_axi_arsize,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi ARBURST" *) input  wire [ 1:0]               s_axi_arburst,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi ARVALID" *) input  wire                      s_axi_arvalid,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi ARREADY" *) output wire                      s_axi_arready,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi RID"     *) output wire [AXI_WIDTH_ID-1:0]   s_axi_rid,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi RDATA"   *) output wire [AXI_WIDTH_DATA-1:0] s_axi_rdata,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi RRESP"   *) output wire [ 1:0]               s_axi_rresp,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi RLAST"   *) output wire                      s_axi_rlast,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi RVALID"  *) output wire                      s_axi_rvalid,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi RREADY"  *) input  wire                      s_axi_rready,
    //--------------------------------------------------------------------------
    (* X_INTERFACE_PARAMETER = "POLARITY ACTIVE_LOW" *)
    (* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 PRESETn RST"     *) input  wire                     PRESETn,
    (* X_INTERFACE_PARAMETER = "ASSOCIATED_BUSIF M0_APB:M1_APB:M2_APB,ASSOCIATED_RESET PRESETn" *)
    (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 PCLK CLK"        *) input  wire                     PCLK,
    (* X_INTERFACE_PARAMETER = "ASSOCIATED_BUSIF M0_APB,ASSOCIATED_RESET PRESETn,CLK_DOMAIN PCLK" *)
    (* X_INTERFACE_INFO = "xilinx.com:interface:apb:1.0 M0_APB PADDR"   *) output wire [WIDTH_PAD-1:0]     M0_APB_PADDR,
    (* X_INTERFACE_INFO = "xilinx.com:interface:apb:1.0 M0_APB PENABLE" *) output wire                     M0_APB_PENABLE,
    (* X_INTERFACE_INFO = "xilinx.com:interface:apb:1.0 M0_APB PWRITE"  *) output wire                     M0_APB_PWRITE,
    (* X_INTERFACE_INFO = "xilinx.com:interface:apb:1.0 M0_APB PWDATA"  *) output wire [WIDTH_PDA-1:0]     M0_APB_PWDATA,
    (* X_INTERFACE_INFO = "xilinx.com:interface:apb:1.0 M0_APB PSEL"    *) output wire                     M0_APB_PSEL,
    (* X_INTERFACE_INFO = "xilinx.com:interface:apb:1.0 M0_APB PRDATA"  *) input  wire [WIDTH_PDA-1:0]     M0_APB_PRDATA,
    (* X_INTERFACE_INFO = "xilinx.com:interface:apb:1.0 M0_APB PREADY"  *) input  wire                     M0_APB_PREADY,
    (* X_INTERFACE_INFO = "xilinx.com:interface:apb:1.0 M0_APB PSLVERR" *) input  wire                     M0_APB_PSLVERR,
    (* X_INTERFACE_INFO = "xilinx.com:interface:apb:1.0 M0_APB PSTRB"   *) output wire [WIDTH_PDS-1:0]     M0_APB_PSTRB,
    (* X_INTERFACE_PARAMETER = "ASSOCIATED_BUSIF M1_APB,ASSOCIATED_RESET PRESETn,CLK_DOMAIN PCLK" *)
    (* X_INTERFACE_INFO = "xilinx.com:interface:apb:1.0 M1_APB PADDR"   *) output wire [WIDTH_PAD-1:0]     M1_APB_PADDR,
    (* X_INTERFACE_INFO = "xilinx.com:interface:apb:1.0 M1_APB PENABLE" *) output wire                     M1_APB_PENABLE,
    (* X_INTERFACE_INFO = "xilinx.com:interface:apb:1.0 M1_APB PWRITE"  *) output wire                     M1_APB_PWRITE,
    (* X_INTERFACE_INFO = "xilinx.com:interface:apb:1.0 M1_APB PWDATA"  *) output wire [WIDTH_PDA-1:0]     M1_APB_PWDATA,
    (* X_INTERFACE_INFO = "xilinx.com:interface:apb:1.0 M1_APB PSEL"    *) output wire                     M1_APB_PSEL,
    (* X_INTERFACE_INFO = "xilinx.com:interface:apb:1.0 M1_APB PRDATA"  *) input  wire [WIDTH_PDA-1:0]     M1_APB_PRDATA,
    (* X_INTERFACE_INFO = "xilinx.com:interface:apb:1.0 M1_APB PREADY"  *) input  wire                     M1_APB_PREADY,
    (* X_INTERFACE_INFO = "xilinx.com:interface:apb:1.0 M1_APB PSLVERR" *) input  wire                     M1_APB_PSLVERR,
    (* X_INTERFACE_INFO = "xilinx.com:interface:apb:1.0 M1_APB PSTRB"   *) output wire [WIDTH_PDS-1:0]     M1_APB_PSTRB,
    (* X_INTERFACE_PARAMETER = "ASSOCIATED_BUSIF M2_APB,ASSOCIATED_RESET PRESETn,CLK_DOMAIN PCLK" *)
    (* X_INTERFACE_INFO = "xilinx.com:interface:apb:1.0 M2_APB PADDR"   *) output wire [WIDTH_PAD-1:0]     M2_APB_PADDR,
    (* X_INTERFACE_INFO = "xilinx.com:interface:apb:1.0 M2_APB PENABLE" *) output wire                     M2_APB_PENABLE,
    (* X_INTERFACE_INFO = "xilinx.com:interface:apb:1.0 M2_APB PWRITE"  *) output wire                     M2_APB_PWRITE,
    (* X_INTERFACE_INFO = "xilinx.com:interface:apb:1.0 M2_APB PWDATA"  *) output wire [WIDTH_PDA-1:0]     M2_APB_PWDATA,
    (* X_INTERFACE_INFO = "xilinx.com:interface:apb:1.0 M2_APB PSEL"    *) output wire                     M2_APB_PSEL,
    (* X_INTERFACE_INFO = "xilinx.com:interface:apb:1.0 M2_APB PRDATA"  *) input  wire [WIDTH_PDA-1:0]     M2_APB_PRDATA,
    (* X_INTERFACE_INFO = "xilinx.com:interface:apb:1.0 M2_APB PREADY"  *) input  wire                     M2_APB_PREADY,
    (* X_INTERFACE_INFO = "xilinx.com:interface:apb:1.0 M2_APB PSLVERR" *) input  wire                     M2_APB_PSLVERR,
    (* X_INTERFACE_INFO = "xilinx.com:interface:apb:1.0 M2_APB PSTRB"   *) output wire [WIDTH_PDS-1:0]     M2_APB_PSTRB
);
     //-----------------------------------------------------------
     wire        X_PSEL   ;
     wire        X_PENABLE;
     wire [31:0] X_PADDR  ;
     wire        X_PWRITE ;
     wire [31:0] X_PRDATA ;
     wire [31:0] X_PWDATA ;
     wire        X_PREADY ;
     wire        X_PSLVERR;
     wire [ 2:0] X_PPROT  ;
     wire [ 3:0] X_PSTRB  ;
     //-----------------------------------------------------------
     axi_to_apb_bridge #(.AXI_WIDTH_ID  (AXI_WIDTH_ID  )// Channel ID width in bits
                        ,.AXI_WIDTH_ADDR(AXI_WIDTH_ADDR)// address width
                        ,.AXI_WIDTH_DATA(AXI_WIDTH_DATA)// data width
                        ,.APB_WIDTH_PAD (WIDTH_PAD     )// APB address width
                        ,.CLOCK_SYNC    (CLOCK_SYNC    ))
     u_bridge (
            .ARESETn            ( axi_aresetn      )
          , .ACLK               ( axi_aclk         )
          , .AWID               ( s_axi_awid       )
          , .AWADDR             ( s_axi_awaddr     )
          , .AWLEN              ( s_axi_awlen      )
          , .AWSIZE             ( s_axi_awsize     )
          , .AWBURST            ( s_axi_awburst    )
          , .AWVALID            ( s_axi_awvalid    )
          , .AWREADY            ( s_axi_awready    )
          , .WID                ( s_axi_wid        )
          , .WDATA              ( s_axi_wdata      )
          , .WSTRB              ( s_axi_wstrb      )
          , .WLAST              ( s_axi_wlast      )
          , .WVALID             ( s_axi_wvalid     )
          , .WREADY             ( s_axi_wready     )
          , .BID                ( s_axi_bid        )
          , .BRESP              ( s_axi_bresp      )
          , .BVALID             ( s_axi_bvalid     )
          , .BREADY             ( s_axi_bready     )
          , .ARID               ( s_axi_arid       )
          , .ARADDR             ( s_axi_araddr     )
          , .ARLEN              ( s_axi_arlen      )
          , .ARSIZE             ( s_axi_arsize     )
          , .ARBURST            ( s_axi_arburst    )
          , .ARVALID            ( s_axi_arvalid    )
          , .ARREADY            ( s_axi_arready    )
          , .RID                ( s_axi_rid        )
          , .RDATA              ( s_axi_rdata      )
          , .RRESP              ( s_axi_rresp      )
          , .RLAST              ( s_axi_rlast      )
          , .RVALID             ( s_axi_rvalid     )
          , .RREADY             ( s_axi_rready     )

          , .PCLK               (PCLK       )
          , .PRESETn            (PRESETn    )
          , .M_PSEL             (X_PSEL     )
          , .M_PENABLE          (X_PENABLE  )
          , .M_PADDR            (X_PADDR    )
          , .M_PWRITE           (X_PWRITE   )
          , .M_PRDATA           (X_PRDATA   )
          , .M_PWDATA           (X_PWDATA   )
          , .M_PREADY           (X_PREADY   )
          , .M_PSLVERR          (X_PSLVERR  )
          , .M_PPROT            (X_PPROT    )
          , .M_PSTRB            (X_PSTRB    )

     );
     //-------------------------------------------------------------------------
     wire [WIDTH_PAD-1:0]  M_PADDR  ;
     wire                  M_PENABLE;
     wire                  M_PWRITE ;
     wire [WIDTH_PDA-1:0]  M_PWDATA ;
     wire [WIDTH_PDS-1:0]  M_PSTRB  ;
     wire [ 2:0]           M_PPROT  ;
     //-------------------------------------------------------------------------
     amba_apb_s3 #(.P_NUM(3)// num of slaves
                  ,.P_PSEL0_START(ADDR_PBASE0),.P_PSEL0_SIZE(PSIZE0)
                  ,.P_PSEL1_START(ADDR_PBASE1),.P_PSEL1_SIZE(PSIZE1)
                  ,.P_PSEL2_START(ADDR_PBASE2),.P_PSEL2_SIZE(PSIZE2)
                  )
     u_amba_apb_s3 (
         .PRESETn      ( PRESETn    )
       , .PCLK         ( PCLK       )
       , .M_PSEL       ( X_PSEL     )
       , .M_PENABLE    ( X_PENABLE  )
       , .M_PADDR      ( X_PADDR    )
       , .M_PWRITE     ( X_PWRITE   )
       , .M_PWDATA     ( X_PWDATA   )
       , .M_PRDATA     ( X_PRDATA   )
       , .M_PREADY     ( X_PREADY   )
       , .M_PSLVERR    ( X_PSLVERR  )
       , .M_PPROT      ( X_PPROT    )
       , .M_PSTRB      ( X_PSTRB    )
       , .S_PADDR      ( M_PADDR        )
       , .S_PENABLE    ( M_PENABLE      )
       , .S_PWRITE     ( M_PWRITE       )
       , .S_PWDATA     ( M_PWDATA       )
       , .S_PPROT      ( M_PPROT        )
       , .S_PSTRB      ( M_PSTRB        )
       , .S_PSEL0      ( M0_APB_PSEL    )
       , .S_PRDATA0    ( M0_APB_PRDATA  )
       , .S_PREADY0    ( M0_APB_PREADY  )
       , .S_PSLVERR0   ( M0_APB_PSLVERR )
       , .S_PSEL1      ( M1_APB_PSEL    )
       , .S_PRDATA1    ( M1_APB_PRDATA  )
       , .S_PREADY1    ( M1_APB_PREADY  )
       , .S_PSLVERR1   ( M1_APB_PSLVERR )
       , .S_PSEL2      ( M2_APB_PSEL    )
       , .S_PRDATA2    ( M2_APB_PRDATA  )
       , .S_PREADY2    ( M2_APB_PREADY  )
       , .S_PSLVERR2   ( M2_APB_PSLVERR )
     );
     //-------------------------------------------------------------------------
     assign M0_APB_PADDR  =M_PADDR  ;
     assign M0_APB_PENABLE=M_PENABLE;
     assign M0_APB_PWRITE =M_PWRITE ;
     assign M0_APB_PWDATA =M_PWDATA ;
     assign M0_APB_PSTRB  =M_PSTRB  ;
     assign M1_APB_PADDR  =M_PADDR  ;
     assign M1_APB_PENABLE=M_PENABLE;
     assign M1_APB_PWRITE =M_PWRITE ;
     assign M1_APB_PWDATA =M_PWDATA ;
     assign M1_APB_PSTRB  =M_PSTRB  ;
     assign M2_APB_PADDR  =M_PADDR  ;
     assign M2_APB_PENABLE=M_PENABLE;
     assign M2_APB_PWRITE =M_PWRITE ;
     assign M2_APB_PWDATA =M_PWDATA ;
     assign M2_APB_PSTRB  =M_PSTRB  ;
     //-------------------------------------------------------------------------
endmodule
//---------------------------------------------------------------------------
`ifndef AXI_TO_APB_BRIDGE_V
`define AXI_TO_APB_BRIDGE_V
module axi_to_apb_bridge
     #(parameter integer AXI_WIDTH_ID   = 4 // Channel ID width in bits
      ,parameter integer AXI_WIDTH_ADDR =32 // address width
      ,parameter integer AXI_WIDTH_DATA =32 // data width
      ,parameter integer AXI_WIDTH_STRB =(AXI_WIDTH_DATA/8)  // data strobe width
      ,parameter integer AXI_WIDTH_DSB  =clogb2(AXI_WIDTH_STRB) // data strobe width
      ,parameter integer APB_WIDTH_PAD  =32 // APB address width
      ,parameter integer APB_WIDTH_PDA  =32 // APB data width
      ,parameter         CLOCK_SYNC     ="SYNC") // SYNC, ASYNC
(
       input  wire                      ARESETn
     , input  wire                      ACLK
     , input  wire [AXI_WIDTH_ID-1:0]   AWID
     , input  wire [AXI_WIDTH_ADDR-1:0] AWADDR
     , input  wire [ 7:0]               AWLEN
     , input  wire [ 2:0]               AWSIZE
     , input  wire [ 1:0]               AWBURST
     , input  wire                      AWVALID
     , output reg                       AWREADY
     , input  wire [AXI_WIDTH_ID-1:0]   WID
     , input  wire [AXI_WIDTH_DATA-1:0] WDATA
     , input  wire [AXI_WIDTH_STRB-1:0] WSTRB
     , input  wire                      WLAST
     , input  wire                      WVALID
     , output reg                       WREADY
     , output reg  [AXI_WIDTH_ID-1:0]   BID
     , output reg  [ 1:0]               BRESP
     , output reg                       BVALID
     , input  wire                      BREADY
     , input  wire [AXI_WIDTH_ID-1:0]   ARID
     , input  wire [AXI_WIDTH_ADDR-1:0] ARADDR
     , input  wire [ 7:0]               ARLEN
     , input  wire [ 2:0]               ARSIZE
     , input  wire [ 1:0]               ARBURST
     , input  wire                      ARVALID
     , output reg                       ARREADY
     , output reg  [AXI_WIDTH_ID-1:0]   RID
     , output reg  [AXI_WIDTH_DATA-1:0] RDATA
     , output reg  [ 1:0]               RRESP
     , output reg                       RLAST
     , output reg                       RVALID
     , input  wire                      RREADY
     //-----------------------------------------------------------
     , input  wire                     PCLK
     , input  wire                     PRESETn
     , output reg                      M_PSEL
     , output reg                      M_PENABLE
     , output reg  [APB_WIDTH_PAD-1:0] M_PADDR
     , output reg                      M_PWRITE
     , input  wire [APB_WIDTH_PDA-1:0] M_PRDATA
     , output reg  [APB_WIDTH_PDA-1:0] M_PWDATA
     , input  wire                     M_PREADY
     , input  wire                     M_PSLVERR
     , output wire [ 2:0]              M_PPROT
     , output reg  [ 3:0]              M_PSTRB
     //-----------------------------------------------------------
);
     //-----------------------------------------------------------
     assign  M_PPROT=3'b0;
     //-----------------------------------------------------------
     reg                      REQ=1'b0;
     reg                      ACK=1'b0;
     reg  [APB_WIDTH_PAD-1:0] ADDR='h0;
     reg                      WR=1'b0;
     reg  [31:0]              DATAW=32'h0;
     reg  [31:0]              DATAR=32'h0;
     reg  [ 3:0]              BE=4'h0;
     reg  [ 2:0]              PROT=3'h0;
     reg                      ERROR=1'b0;
     //-----------------------------------------------------------
     reg  [APB_WIDTH_PAD-1:0] Twaddr ;
     reg  [31:0]              Twdata ;
     reg  [ 3:0]              Twstrb ;
     reg                      Twen   ;
     reg  [APB_WIDTH_PAD-1:0] Traddr ;
     wire [31:0]              Trdata  = DATAR;
     reg  [ 3:0]              Trstrb ;
     reg                      Tren   ;
     reg                      Tack   ; // ACK_sync;
     //-----------------------------------------------------------
     reg grant_write=1'b0;
     reg grant_read =1'b0;
     //-----------------------------------------------------------
     always @ ( * ) begin
         case ({grant_write,grant_read})
         2'b10: begin // write-case
                REQ   = Twen  ;
                ADDR  = Twaddr;
                WR    = 1'b1  ;
                DATAW = Twdata; // be careful WDATA (AXI)
                BE    = Twstrb;
                end
         2'b01: begin // read-case
                REQ   = Tren  ;
                ADDR  = Traddr;
                WR    = 1'b0  ;
                DATAW =  'h0  ;
                BE    = Trstrb;
                end
         2'b00, 
         2'b11: begin
                REQ   = 1'b0;
                ADDR  =  'h0;
                WR    = 1'b0;
                DATAW =  'h0; // be careful WDATA (AXI)
                BE    = 4'h0;
                PROT  =  'h0;
                end
         endcase
     end
     //-----------------------------------------------------------
     // synthesis translate_off
     always @ (posedge ACLK or negedge ARESETn) begin
     if (ARESETn==1'b0) begin
     end else begin
            if (grant_write&grant_read)
            $display("%04d %m ERROR both granted", $time);
     end
     end
     // synthesis translate_on
     //-----------------------------------------------------------
     reg ACK_sync, ACK_sync0;
     always @ (posedge ACLK or negedge ARESETn) begin
         if (ARESETn==1'b0) begin
             ACK_sync  <= 1'b0;
             ACK_sync0 <= 1'b0;
         end else begin
             ACK_sync  <= ACK_sync0;
             ACK_sync0 <= ACK;
         end
     end
     always @ ( * ) begin
         if (CLOCK_SYNC=="SYNC") Tack = ACK;
         else Tack = ACK_sync;
     end
     //-----------------------------------------------------------
     // write case
     //-----------------------------------------------------------
     reg  [AXI_WIDTH_ID-1:0]    AWID_reg   ;
     reg  [AXI_WIDTH_ADDR-1:0]  AWADDR_reg ;
     reg  [ 7:0]                AWLEN_reg  ;
     reg  [ 2:0]                AWSIZE_reg ;
     reg  [ 1:0]                AWBURST_reg;
     reg  [AXI_WIDTH_DATA-1:0]  WDATA_reg  ;
     reg  [AXI_WIDTH_STRB-1:0]  WSTRB_reg  ;
     //-----------------------------------------------------------
     reg  [APB_WIDTH_PAD-1:0] addrW; // address of each transfer within a burst
     reg  [APB_WIDTH_PAD-1:0] addrWT;// address of each transfer within a beat
     reg  [ 7:0]              beatW; // keeps num of transfers within a burst
     //-----------------------------------------------------------
     reg  [ 3:0]         tickW;
     wire [ 3:0]         AWTICK = (AXI_WIDTH_DATA/32); // num of words in a data-bus
     //-----------------------------------------------------------
     localparam STW_IDLE        = 'h0,
                STW_RUN         = 'h1,
                STW_WRITE0      = 'h2,
                STW_WRITE1      = 'h3,
                STW_WRITE1_VOID = 'h4,
                STW_WRITE2      = 'h5,
                STW_WRITE       = 'h6,
                STW_RSP         = 'h7;
     reg [2:0] stateW=STW_IDLE;
     always @ (posedge ACLK or negedge ARESETn) begin
         if (ARESETn==1'b0) begin
             AWID_reg    <=  'h0;
             AWADDR_reg  <=  'h0;
             AWLEN_reg   <=  'h0;
             AWSIZE_reg  <=  'b0;
             AWBURST_reg <=  'b0;
             AWREADY     <= 1'b0;
             WREADY      <= 1'b0;
             WDATA_reg   <=  'h0;
             WSTRB_reg   <=  'h0;
             BID         <=  'h0;
             BRESP       <= 2'b10; // SLAVE ERROR
             BVALID      <= 1'b0;
             addrW       <=  'h0;
             addrWT      <=  'h0;
             beatW       <=  'h0;
             Twaddr      <=  'h0;
             Twdata      <=  'h0;
             Twstrb      <=  'h0;
             Twen        <= 1'b0;
             tickW       <=  'h0;
             grant_write <= 1'b0;
             stateW      <= STW_IDLE;
         end else begin
             case (stateW)
             STW_IDLE: begin
                 if ((AWVALID==1'b1)&&(grant_read==1'b0)) begin
                      AWREADY     <= 1'b1;
                      grant_write <= 1'b1;
                      AWID_reg    <= AWID   ;
                      AWADDR_reg  <= AWADDR ;
                      AWLEN_reg   <= AWLEN  ;
                      AWSIZE_reg  <= AWSIZE ;
                      AWBURST_reg <= AWBURST;
                      stateW      <= STW_RUN;
                 end
                 end // STW_IDLE
             STW_RUN: begin
                 AWREADY     <= 1'b0;
                 WREADY      <= 1'b1;
                 BRESP       <= 2'b00; // OKAY
                 addrW       <= AWADDR_reg[APB_WIDTH_PAD-1:0];
                 addrWT      <= AWADDR_reg[APB_WIDTH_PAD-1:0];
                 beatW       <=  'h0;
                 tickW       <= get_tick_wr(AWADDR_reg[7:0]); //get_tick_wr(AWADDR_reg[AXI_WIDTH_DSB-1:0]);
                 stateW      <= STW_WRITE0;
                 `ifdef RIGOR
                 // synopsys translate_off
                 if (AWVALID!=1'b1) begin
                   $display("%04d %m ERROR AWVALID should be 1 at this point", $time);
                 end
                 // synopsys translate_on
                 `endif
                 end // STW_RUN
             STW_WRITE0: begin
                 if (WVALID==1'b1) begin
                     WDATA_reg <= WDATA;
                     WSTRB_reg <= WSTRB;
                     Twaddr    <= addrWT;
                     Twdata    <= get_data_wr(addrWT,WDATA);
                     Twstrb    <= get_strb_wr(addrWT,WSTRB);
                     Twen      <= 1'b1;
                     tickW     <= tickW + 1;
                     if (beatW>=AWLEN_reg) begin
                         if (WLAST==1'b0) BRESP <= 2'b10; // SLVERR - missing last
                     end
                     if (WID!=AWID_reg) BRESP <= 2'b10; // SLVERR - ID mis-match occured
                     WREADY <= 1'b0;
                     stateW <= STW_WRITE1;
                 end else begin
                     Twen   <= 1'b0;
                 end
                 end // STW_WRITE0
             STW_WRITE1: begin
                 if (Tack==1'b1) begin
                     Twen <= 1'b0;
                     if (tickW>=AWTICK) begin
                        beatW  <= beatW + 1;
                        addrW  <= get_next_addr_wr(addrW,AWSIZE_reg,AWBURST_reg,AWLEN_reg);
                        addrWT <= get_next_addr_wr(addrW,AWSIZE_reg,AWBURST_reg,AWLEN_reg);
                        if (beatW>=AWLEN_reg) begin
                            BID    <= AWID_reg;
                            tickW  <=  'h0;
                            stateW <= STW_RSP;
                        end else begin
                            tickW  <=  'h0; // it should be 0
                            stateW <= STW_WRITE;
                        end
                     end else begin
                         addrWT <= addrWT+4; // because TCM is 32-bit wide
                         stateW <= STW_WRITE2;
                     end
                 end
                 end // STW_WRITE1
             STW_WRITE1_VOID: begin
                 if (tickW>=AWTICK) begin
                    beatW  <= beatW + 1;
                    addrW  <= get_next_addr_wr(addrW,AWSIZE_reg,AWBURST_reg,AWLEN_reg);
                    addrWT <= get_next_addr_wr(addrW,AWSIZE_reg,AWBURST_reg,AWLEN_reg);
                    if (beatW>=AWLEN_reg) begin
                        BID    <= AWID_reg;
                        tickW  <=  'h0;
                        stateW <= STW_RSP;
                    end else begin
                        tickW  <=  'h0; // it should be 0
                        stateW <= STW_WRITE;
                    end
                 end else begin
                     addrWT <= addrWT+4; // because TCM is 32-bit wide
                     stateW <= STW_WRITE2;
                 end
                 end // STW_WRITE1
             STW_WRITE2: begin
                 if (Tack==1'b0) begin
                     tickW  <= tickW + 1;
                     if (|get_strb_wr(addrWT,WSTRB_reg)) begin
                         Twaddr <= addrWT;
                         Twdata <= get_data_wr(addrWT,WDATA_reg);
                         Twstrb <= get_strb_wr(addrWT,WSTRB_reg);
                         Twen   <= 1'b1;
                         stateW <= STW_WRITE1;
                     end else begin
                         Twdata <= 'h0;
                         Twstrb <= 'h0;
                         stateW <= STW_WRITE1_VOID;
                     end
                 end
                 end // STW_WRITE2
             STW_WRITE: begin
                 if (Tack==1'b0) begin
                     WREADY <= 1'b1;
                     stateW <= STW_WRITE0;
                 end
                 end // STW_WRITE
             STW_RSP: begin
                 if (Tack==1'b0) begin
                     grant_write <= 1'b0;
                     if ((BREADY==1'b1)&&(BVALID==1'b1)) begin
                         BVALID  <= 1'b0;
                         stateW  <= STW_IDLE;
                     end else begin
                         BVALID <= 1'b1;
                     end
                 end
                 end // STW_RSP
             endcase
         end
     end
     //-----------------------------------------------------------
     // read case
     //-----------------------------------------------------------
     reg  [AXI_WIDTH_ADDR-1:0] ARADDR_reg ;
     reg  [ 7:0]               ARLEN_reg  ;
     reg  [ 2:0]               ARSIZE_reg ;
     reg  [ 1:0]               ARBURST_reg;
     reg  [AXI_WIDTH_STRB-1:0] ARSTRB_reg ;
     //-----------------------------------------------------------
     reg  [APB_WIDTH_PAD-1:0] addrR ;// address of each transfer within a burst
     reg  [APB_WIDTH_PAD-1:0] addrRT;// address of each transfer within a beat
     reg  [ 7:0]              beatR; // keeps num of transfers within a burst
     //-----------------------------------------------------------
     reg  [ 3:0] tickR;
     wire [ 3:0] ARTICK = (AXI_WIDTH_DATA/32); // num of words in a data-bus
     //-----------------------------------------------------------
     localparam STR_IDLE      = 'h0,
                STR_RUN       = 'h1,
                STR_WAIT      = 'h2,
                STR_WAIT_VOID = 'h3,
                STR_TICK      = 'h4,
                STR_READ0     = 'h5,
                STR_READ1     = 'h6,
                STR_END       = 'h7;
     reg [2:0] stateR=STR_IDLE;
     always @ (posedge ACLK or negedge ARESETn) begin
         if (ARESETn==1'b0) begin
             ARADDR_reg  <=  'h0;
             ARLEN_reg   <=  'h0;
             ARSIZE_reg  <=  'b0;
             ARBURST_reg <=  'b0;
             ARSTRB_reg  <=  'h0;
             ARREADY     <= 1'b0;
             RID         <=  'h0;
             RLAST       <= 1'b0;
             RRESP       <= 2'b10; // SLAERROR
             RDATA       <=  'h0;
             RVALID      <= 1'b0;
             addrR       <=  'h0;
             addrRT      <=  'h0;
             beatR       <=  'h0;
             Traddr      <=  'h0;
             Trstrb      <=  'h0;
             Tren        <= 1'b0;
             tickR       <=  'h0;
             grant_read  <= 1'b0;
             stateR      <= STR_IDLE;
         end else begin
             case (stateR)
             STR_IDLE: begin
                 if ((ARVALID==1'b1)&&(AWVALID==1'b0)&&(grant_write==1'b0)) begin
                      grant_read  <= 1'b1;
                      ARREADY     <= 1'b1;
                      ARADDR_reg  <= ARADDR ;
                      ARLEN_reg   <= ARLEN  ;
                      ARSIZE_reg  <= ARSIZE ;
                      ARBURST_reg <= ARBURST;
                      ARSTRB_reg  <= make_strb_rd(ARADDR[AXI_WIDTH_DSB-1:0],ARSIZE);
                      addrR       <= ARADDR[APB_WIDTH_PAD-1:0];
                      addrRT      <= ARADDR[APB_WIDTH_PAD-1:0];
                      stateR      <= STR_RUN;
                 end
                 end // STR_IDLE
             STR_RUN: begin
                 ARREADY     <= 1'b0;
                 RID         <= ARID;
                 RDATA       <=  'h0; // it should be here
                 beatR       <=  'h0;
                 tickR       <= get_tick_rd(addrRT[7:0]);
                 Traddr      <= addrRT;
                 Trstrb      <= get_strb_rd(addrRT,ARSTRB_reg);
                 Tren        <= 1'b1;
                 stateR      <= STR_WAIT;
                 end // STR_RUN
             STR_WAIT: begin
                 if (Tack) begin
                    Tren   <= 1'b0;
                    RDATA  <= get_data_rd(RDATA,addrRT,Trdata,ARSIZE_reg);
                    if (tickR>=ARTICK) begin
                        addrR  <= get_next_addr_rd(addrR,ARSIZE_reg,ARBURST_reg,ARLEN_reg);
                        addrRT <= get_next_addr_rd(addrR,ARSIZE_reg,ARBURST_reg,ARLEN_reg);
                        tickR  <= 'h0; // since new beat
                        stateR <= STR_READ0;
                    end else begin
                        addrRT <= addrRT + 4; // since TCM is 32-bit width
                        stateR <= STR_TICK;
                    end
                 end
                 end // STR_WAIT
             STR_WAIT_VOID: begin
                 if (tickR>=ARTICK) begin
                     addrR  <= get_next_addr_rd(addrR,ARSIZE_reg,ARBURST_reg,ARLEN_reg);
                     addrRT <= get_next_addr_rd(addrR,ARSIZE_reg,ARBURST_reg,ARLEN_reg);
                     tickR  <= 'h0; // since new beat
                     stateR <= STR_READ0;
                 end else begin
                     addrRT <= addrRT + 4; // since TCM is 32-bit width
                     stateR <= STR_TICK;
                 end
                 end // STR_WAIT
             STR_TICK: begin
                 if (Tack==1'b0) begin
                     tickR  <= tickR + 1;
                     if (|get_strb_rd(addrRT,ARSTRB_reg)) begin
                          Tren   <= 1'b1;
                          Traddr <= addrRT;
                          Trstrb <= get_strb_rd(addrRT,ARSTRB_reg);
                          stateR <= STR_WAIT;
                     end else begin
                          stateR <= STR_WAIT_VOID; // nothing to read
                     end
                 end
                 end // STR_TICK
             STR_READ0: begin
                 if (Tack==1'b0) begin
                     if (beatR>=ARLEN_reg) begin
                         RLAST      <= 1'b1;
                         RRESP      <= 2'b00;
                         RVALID     <= 1'b1;
                         grant_read <= 1'b0;
                         stateR     <= STR_END;
                     end else begin
                         RLAST      <= 1'b0;
                         RRESP      <= 2'b00;
                         RVALID     <= 1'b1;
                         ARSTRB_reg <= make_strb_rd(addrR[AXI_WIDTH_DSB-1:0],ARSIZE_reg);
                         stateR     <= STR_READ1;
                     end
                 end
                 end // STR_READ0
             STR_READ1: begin
                 if (RREADY) begin
                     RVALID <= 1'b0;
                     RDATA  <= 'h0;
                     Tren   <= 1'b1;
                     Traddr <= addrRT;
                     Trstrb <= get_strb_rd(addrRT,ARSTRB_reg);
                     tickR  <= 'h1;
                     beatR  <= beatR + 1;
                     stateR <= STR_WAIT;
                 end
                 end // STR_READ1
             STR_END: begin // data only
                 if (RREADY==1'b1) begin
                     RLAST   <= 1'b0;
                     RVALID  <= 1'b0;
                     stateR <= STR_IDLE;
                 end
                 end // STR_END
             endcase
         end
     end
     //-----------------------------------------------------------
     function [3:0] get_strb_wr;
          input [APB_WIDTH_PAD-1:0]  addr;
          input [AXI_WIDTH_STRB-1:0] strb;  // num. of byte to move: 0=1-byte, 1=2-byte
     begin
          case (AXI_WIDTH_STRB)
           4: get_strb_wr = strb;
           8: case (addr[2])
              0: get_strb_wr = strb;
              1: get_strb_wr = strb>>4;
              endcase
          16: case (addr[3:2])
              2'b00: get_strb_wr = strb;
              2'b01: get_strb_wr = strb>>4;
              2'b10: get_strb_wr = strb>>8;
              2'b11: get_strb_wr = strb>>12;
              endcase
          default: begin
                   get_strb_wr = strb;
                   // synopsys translate_off
                   $display("%04d %m ERROR un-supported WSTRB width %2d", $time, AXI_WIDTH_STRB);
                   // synopsys translate_on
                   end
          endcase
     end
     endfunction
     //-----------------------------------------------------------
     function [3:0] get_strb_rd;
          input [APB_WIDTH_PAD-1:0]  addr;
          input [AXI_WIDTH_STRB-1:0] strb;  // num. of byte to move: 0=1-byte, 1=2-byte
     begin
          case (AXI_WIDTH_STRB)
           4: get_strb_rd = strb;
           8: case (addr[2])
              0: get_strb_rd = strb;
              1: get_strb_rd = strb>>4;
              endcase
          16: case (addr[3:2])
              2'b00: get_strb_rd = strb;
              2'b01: get_strb_rd = strb>>4;
              2'b10: get_strb_rd = strb>>8;
              2'b11: get_strb_rd = strb>>12;
              endcase
          default: begin
                   get_strb_rd = strb;
                   // synopsys translate_off
                   $display("%04d %m ERROR un-supported WSTRB width %2d", $time, AXI_WIDTH_STRB);
                   // synopsys translate_on
                   end
          endcase
     end
     endfunction
     //-----------------------------------------------------------
     function [AXI_WIDTH_STRB-1:0] make_strb_rd;
          input [AXI_WIDTH_DSB-1:0] addr;
          input [ 2:0]              size; // 0=1-byte, 1=2-byte
          reg   [127:0]             strb;
     begin
          case (size)
          3'b000: strb = {   1{1'b1}}<<addr; // one-byte
          3'b001: strb = {   2{1'b1}}<<addr; // two-byte
          3'b010: strb = {   4{1'b1}}<<addr; // four-byte
          3'b011: strb = {   8{1'b1}}<<addr;
          3'b100: strb = {  16{1'b1}}<<addr;
          3'b101: strb = {  32{1'b1}}<<addr;
          3'b110: strb = { 64{1'b1}}<<addr;
          3'b111: strb = {128{1'b1}}<<addr;
          endcase
          make_strb_rd = strb[AXI_WIDTH_STRB-1:0];
     end
     endfunction
     //-----------------------------------------------------------
     function [APB_WIDTH_PAD-1:0] get_next_addr_wr;
          input [APB_WIDTH_PAD-1:0] addr ;
          input [ 2:0]            size ;
          input [ 1:0]            burst; // burst type
          input [ 7:0]            len  ; // burst length
          reg   [APB_WIDTH_PAD-3:0] naddr;
          reg   [APB_WIDTH_PAD-1:0] mask ;
     begin
          case (burst)
          2'b00: get_next_addr_wr = addr;
          2'b01: begin
                 if ((1<<size)<AXI_WIDTH_STRB) begin
                    get_next_addr_wr = addr + (1<<size);
                 end else begin
                     naddr = addr[APB_WIDTH_PAD-1:AXI_WIDTH_DSB];
                     naddr = naddr + 1;
                     get_next_addr_wr = {naddr,{AXI_WIDTH_DSB{1'b0}}};
                 end
                 end
          2'b10: begin
                 mask          = get_wrap_mask(size,len);
                 get_next_addr_wr = (addr&~mask)
                               | (((addr&mask)+(1<<size))&mask);
                 end
          2'b11: begin
                 get_next_addr_wr = addr;
                 // synopsys translate_off
                 $display("%04d %m ERROR un-defined BURST %01x", $time, burst);
                 // synopsys translate_on
                 end
          endcase
     end
     endfunction
     //-----------------------------------------------------------
     function [APB_WIDTH_PAD-1:0] get_next_addr_rd;
          input [APB_WIDTH_PAD-1:0] addr ;
          input [ 2:0]            size ;
          input [ 1:0]            burst; // burst type
          input [ 7:0]            len  ; // burst length
          reg   [APB_WIDTH_PAD-3:0] naddr;
          reg   [APB_WIDTH_PAD-1:0] mask ;
     begin
          case (burst)
          2'b00: get_next_addr_rd = addr;
          2'b01: begin
                 if ((1<<size)<AXI_WIDTH_STRB) begin
                    get_next_addr_rd = addr + (1<<size);
                 end else begin
                     naddr = addr[APB_WIDTH_PAD-1:AXI_WIDTH_DSB];
                     naddr = naddr + 1;
                     get_next_addr_rd = {naddr,{AXI_WIDTH_DSB{1'b0}}};
                 end
                 end
          2'b10: begin
                 mask          = get_wrap_mask(size,len);
                 get_next_addr_rd = (addr&~mask)
                               | (((addr&mask)+(1<<size))&mask);
                 end
          2'b11: begin
                 get_next_addr_rd = addr;
                 // synopsys translate_off
                 $display("%04d %m ERROR un-defined BURST %01x", $time, burst);
                 // synopsys translate_on
                 end
          endcase
     end
     endfunction
     //-----------------------------------------------------------
     function [APB_WIDTH_PAD-1:0] get_wrap_mask;
          input [ 2:0]      size ;
          input [ 7:0]      len  ; // burst length
     begin
          case (size)
          3'b000: get_wrap_mask = (    (len+1))-1;
          3'b001: get_wrap_mask = (  2*(len+1))-1;
          3'b010: get_wrap_mask = (  4*(len+1))-1;
          3'b011: get_wrap_mask = (  8*(len+1))-1;
          3'b100: get_wrap_mask = ( 16*(len+1))-1;
          3'b101: get_wrap_mask = ( 32*(len+1))-1;
          3'b110: get_wrap_mask = ( 64*(len+1))-1;
          3'b111: get_wrap_mask = (128*(len+1))-1;
          endcase
     end
     endfunction
     //-----------------------------------------------------------
     function [31:0] get_data_wr;
          input [APB_WIDTH_PAD-1:0] addr;
          input [AXI_WIDTH_DATA-1:0]    data;
     begin
          case (AXI_WIDTH_DATA)
          32: get_data_wr = data;
          64: case (addr[2])
              0: get_data_wr = data;
              1: get_data_wr = data>>32;
              endcase
          128: case (addr[3:2])
              2'b00: get_data_wr = data;
              2'b01: get_data_wr = data>>32;
              2'b10: get_data_wr = data>>64;
              2'b11: get_data_wr = data>>96;
              endcase
          default: begin
                   get_data_wr = data;
                   // synopsys translate_off
                   $display("%04d %m ERROR %d-bit AXI data bus not supported", $time, AXI_WIDTH_DATA);
                   // synopsys translate_on
                   end
          endcase
     end
     endfunction
     //-----------------------------------------------------------
     // It determines the first tick value
     function [3:0] get_tick_wr;
          //input [AXI_WIDTH_DSB-1:0] addr;
          input [7:0] addr;
     begin
          case (AXI_WIDTH_DATA)
           32: get_tick_wr = 4'h0;
           64: case (addr[2])
               0: get_tick_wr = 4'h0;
               1: get_tick_wr = 4'h1;
               endcase
          128: case (addr[3:2])
               2'b00: get_tick_wr = 4'h0;
               2'b01: get_tick_wr = 4'h1;
               2'b10: get_tick_wr = 4'h2;
               2'b11: get_tick_wr = 4'h3;
               endcase
          default: begin
                   get_tick_wr = 'h0;
                   // synopsys translate_off
                   $display("%m ERROR %d-bit AXI data bus not supported", $time, AXI_WIDTH_DATA);
                   // synopsys translate_on
                   end
          endcase
     end
     endfunction
     //-----------------------------------------------------------
     // It determines the first tick value
     function [3:0] get_tick_rd;
          //input [AXI_WIDTH_DSB-1:0] addr;
          input [7:0] addr;
     begin
          case (AXI_WIDTH_DATA)
           32: get_tick_rd = 4'h1;
           64: case (addr[2])
               0: get_tick_rd = 4'h1;
               1: get_tick_rd = 4'h2;
               endcase
          128: case (addr[3:2])
               2'b00: get_tick_rd = 4'h1;
               2'b01: get_tick_rd = 4'h2;
               2'b10: get_tick_rd = 4'h3;
               2'b11: get_tick_rd = 4'h4;
               endcase
          default: begin
                   get_tick_rd = 'h1;
                   // synopsys translate_off
                   $display("%04d %m ERROR %d-bit AXI data bus not supported", $time, AXI_WIDTH_DATA);
                   // synopsys translate_on
                   end
          endcase
     end
     endfunction
     //-----------------------------------------------------------
     // It merges 'dataT' to 'dataR'.
     function [AXI_WIDTH_DATA-1:0] get_data_rd;
          input [AXI_WIDTH_DATA-1:0] dataR;
          input [APB_WIDTH_PAD-1:0]  addr;
          input [31:0]             dataT;
          input [ 2:0]             sizeR; // 0=1-byte
     begin
          case (AXI_WIDTH_DATA)
          32: get_data_rd = dataT;
          64: case (addr[2])
              0: get_data_rd = dataT;
              1: get_data_rd = (dataT<<32)|dataR;
              endcase
          128: case (addr[3:2])
              2'b00: get_data_rd = dataT;
              2'b01: get_data_rd = (dataT<<32)|dataR;
              2'b10: get_data_rd = (dataT<<64)|dataR;
              2'b11: get_data_rd = (dataT<<96)|dataR;
              endcase
          default: begin
                   get_data_rd = dataT;
                   // synopsys translate_off
                   $display("%04d %m ERROR %d-bit AXI data bus not supported", $time, AXI_WIDTH_DATA);
                   // synopsys translate_on
                   end
          endcase
     end
     endfunction
     //-----------------------------------------------------------
     function integer clogb2;
     input [31:0] value;
     reg   [31:0] tmp;
     begin
        tmp = value - 1;
        for (clogb2 = 0; tmp > 0; clogb2 = clogb2 + 1) tmp = tmp >> 1;
     end
     endfunction
     //-----------------------------------------------------------
     reg Treq;
     reg req_sync=1'b0;
     reg req_sync0=1'b0;
     always @ (posedge PCLK or negedge PRESETn) begin
            if (PRESETn==1'b0) begin
                req_sync  <= 1'b0;
                req_sync0 <= 1'b0;
            end else begin
                req_sync  <= req_sync0;
                req_sync0 <= REQ;
            end
     end
     always @ ( * ) begin
         if (CLOCK_SYNC=="SYNC") Treq = REQ;
         else Treq = req_sync;
     end
     //-----------------------------------------------------------
     localparam ST_IDLE  = 'h0,
                ST_ADDR  = 'h1,
                ST_WAIT  = 'h2,
                ST_END   = 'h3;
     reg [1:0] state=ST_IDLE;
     //-----------------------------------------------------------
     always @ (posedge PCLK or negedge PRESETn) begin
            if (PRESETn==1'b0) begin
                M_PSEL    <=  'h0;
                M_PENABLE <=  'h0;
                M_PWRITE  <=  'h0;
                M_PADDR   <=  'h0;
                M_PWDATA  <=  'h0;
                M_PSTRB   <=  'h0;
                ACK       <=  'b0;
                ERROR     <=  'b0;
                DATAR     <=  'h0;
                state     <= ST_IDLE;
            end else begin
                case (state)
                ST_IDLE: begin
                   if (Treq) begin
                       M_PSEL   <= 1'b1;
                       M_PWRITE <= WR  ;
                       M_PADDR  <= ADDR;
                       M_PWDATA <= DATAW;
                       M_PSTRB  <= (WR) ? BE : 4'hF;
                       state    <= ST_ADDR;
                   end
                   end // STW_IDLE
                ST_ADDR: begin
                   M_PENABLE <= 1'b1;
                   state     <= ST_WAIT;
                   end // ST_ADDR
                ST_WAIT: begin
                   if (M_PREADY) begin
                       ERROR     <= M_PSLVERR;
                       M_PSEL    <= 1'b0;
                       M_PENABLE <= 1'b0;
                       DATAR     <= M_PRDATA;
                       ACK       <= 1'b1;
                       state     <= ST_END;
                   end
                   end // ST_WAIT
                ST_END: begin
                   if (Treq==1'b0) begin
                       ACK      <= 1'b0;
                       state    <= ST_IDLE;
                   end
                   end // ST_END
                endcase
            end
     end
     //-----------------------------------------------------------
endmodule
`endif
//---------------------------------------------------------------------------
//---------------------------------------------------------------------------
module amba_apb_s3
     #(parameter P_NUM=3 // num of slaves
               , P_PSEL0_START=32'hC0000000, P_PSEL0_SIZE=32'h00001000
               , P_PSEL1_START=32'hC0001000, P_PSEL1_SIZE=32'h00001000
               , P_PSEL2_START=32'hC0002000, P_PSEL2_SIZE=32'h00001000
               )
(
       input   wire          PRESETn
     , input   wire          PCLK
     , input   wire          M_PSEL
     , input   wire          M_PENABLE
     , input   wire  [31:0]  M_PADDR
     , input   wire          M_PWRITE
     , input   wire  [31:0]  M_PWDATA
     , output  wire  [31:0]  M_PRDATA
     , output  wire          M_PREADY
     , output  wire          M_PSLVERR
     , input   wire  [ 2:0]  M_PPROT
     , input   wire  [ 3:0]  M_PSTRB
     , output  wire  [31:0]  S_PADDR
     , output  wire          S_PENABLE
     , output  wire          S_PWRITE
     , output  wire  [31:0]  S_PWDATA
     , output  wire  [ 2:0]  S_PPROT
     , output  wire  [ 3:0]  S_PSTRB
     , output  wire          S_PSEL0
     , input   wire  [31:0]  S_PRDATA0
     , input   wire          S_PREADY0
     , input   wire          S_PSLVERR0
     , output  wire          S_PSEL1
     , input   wire  [31:0]  S_PRDATA1
     , input   wire          S_PREADY1
     , input   wire          S_PSLVERR1
     , output  wire          S_PSEL2
     , input   wire  [31:0]  S_PRDATA2
     , input   wire          S_PREADY2
     , input   wire          S_PSLVERR2
);
     wire P_SELD;
     assign S_PADDR   = M_PADDR;
     assign S_PENABLE = M_PENABLE;
     assign S_PWRITE  = M_PWRITE;
     assign S_PWDATA  = M_PWDATA;
     assign S_PPROT   = M_PPROT;
     assign S_PSTRB   = M_PSTRB;
     apb_decoder_s3 #(.P_NUM(3)
                  ,.P_PSEL0_START(P_PSEL0_START),.P_PSEL0_SIZE(P_PSEL0_SIZE)
                  ,.P_PSEL1_START(P_PSEL1_START),.P_PSEL1_SIZE(P_PSEL1_SIZE)
                  ,.P_PSEL2_START(P_PSEL2_START),.P_PSEL2_SIZE(P_PSEL2_SIZE)
                  )
     u_apb_decoder (
           .PSEL  ( M_PSEL  )
         , .PADDR ( M_PADDR )
         , .PSEL0 ( S_PSEL0 )
         , .PSEL1 ( S_PSEL1 )
         , .PSEL2 ( S_PSEL2 )
         , .PSELD ( S_PSELD )
     );
     apb_mux_s3 #(.P_NUM(3))
     u_apb_mux (
           .PSEL     ({S_PSELD,S_PSEL2,S_PSEL1,S_PSEL0})
         , .PRDATA   (M_PRDATA )
         , .PRDATA0  (S_PRDATA0)
         , .PRDATA1  (S_PRDATA1)
         , .PRDATA2  (S_PRDATA2)
         , .PREADY   (M_PREADY  )
         , .PSLVERR  (M_PSLVERR )
         , .PREADY0  (S_PREADY0)
         , .PSLVERR0 (S_PSLVERR0)
         , .PREADY1  (S_PREADY1)
         , .PSLVERR1 (S_PSLVERR1)
         , .PREADY2  (S_PREADY2)
         , .PSLVERR2 (S_PSLVERR2)
     );
endmodule
//---------------------------------------------------------------------------
//---------------------------------------------------------------------------
module apb_decoder_s3
     #(parameter P_NUM=3 // num of slaves
               , P_PSEL0_START=32'hC0000000, P_PSEL0_SIZE=32'h00001000
               , P_PSEL0_END  =P_PSEL0_START+P_PSEL0_SIZE
               , P_PSEL1_START=32'hC0001000, P_PSEL1_SIZE=32'h00001000
               , P_PSEL1_END  =P_PSEL1_START+P_PSEL1_SIZE
               , P_PSEL2_START=32'hC0002000, P_PSEL2_SIZE=32'h00001000
               , P_PSEL2_END  =P_PSEL2_START+P_PSEL2_SIZE
               )
(
       input   wire        PSEL
     , input   wire [31:0] PADDR
     , output  wire        PSEL0
     , output  wire        PSEL1
     , output  wire        PSEL2
     , output  wire        PSELD // decoding error
);
   assign PSEL0 = ((PSEL==1'b1)&&(P_NUM>0)&&(PADDR>=P_PSEL0_START)&&(PADDR<P_PSEL0_END)) ? 1'b1 : 1'b0;
   assign PSEL1 = ((PSEL==1'b1)&&(P_NUM>1)&&(PADDR>=P_PSEL1_START)&&(PADDR<P_PSEL1_END)) ? 1'b1 : 1'b0;
   assign PSEL2 = ((PSEL==1'b1)&&(P_NUM>2)&&(PADDR>=P_PSEL2_START)&&(PADDR<P_PSEL2_END)) ? 1'b1 : 1'b0;
   assign PSELD =  (PSEL==1'b1)&~PSEL0&~PSEL1&~PSEL2;
   `ifdef RIGOR
   // synthesis translate_off
   initial begin
       if (P_PSEL0_SIZE==0) $display("%m ERROR P_PSEL0_SIZE should be positive 32-bit");
       if (P_PSEL1_SIZE==0) $display("%m ERROR P_PSEL1_SIZE should be positive 32-bit");
       if (P_PSEL2_SIZE==0) $display("%m ERROR P_PSEL2_SIZE should be positive 32-bit");
       if ((P_PSEL0_END>P_PSEL1_START)&&
           (P_PSEL0_END<=P_PSEL1_END)) $display("%m ERROR address range overlapped 0:1");
       if ((P_PSEL0_END>P_PSEL2_START)&&
           (P_PSEL0_END<=P_PSEL2_END)) $display("%m ERROR address range overlapped 0:2");
       if ((P_PSEL1_END>P_PSEL0_START)&&
           (P_PSEL1_END<=P_PSEL0_END)) $display("%m ERROR address range overlapped 1:0");
       if ((P_PSEL1_END>P_PSEL2_START)&&
           (P_PSEL1_END<=P_PSEL2_END)) $display("%m ERROR address range overlapped 1:2");
       if ((P_PSEL2_END>P_PSEL0_START)&&
           (P_PSEL2_END<=P_PSEL0_END)) $display("%m ERROR address range overlapped 2:0");
       if ((P_PSEL2_END>P_PSEL1_START)&&
           (P_PSEL2_END<=P_PSEL1_END)) $display("%m ERROR address range overlapped 2:1");
   end
   // synthesis translate_on
   `endif
endmodule
//---------------------------------------------------------------------------
//---------------------------------------------------------------------------
module apb_mux_s3
     #(parameter P_NUM=3) // num of slaves
(
       input   wire  [P_NUM:0]    PSEL
     , output  reg   [31:0]       PRDATA
     , input   wire  [31:0]       PRDATA0
     , input   wire  [31:0]       PRDATA1
     , input   wire  [31:0]       PRDATA2
     , output  reg                PREADY
     , output  reg                PSLVERR
     , input   wire               PREADY0
     , input   wire               PSLVERR0
     , input   wire               PREADY1
     , input   wire               PSLVERR1
     , input   wire               PREADY2
     , input   wire               PSLVERR2
);
     always @ ( PSEL or PRDATA0 or PRDATA1 or PRDATA2) begin
     case (PSEL)
     4'h1: PRDATA = PRDATA0;
     4'h2: PRDATA = PRDATA1;
     4'h4: PRDATA = PRDATA2;
     default: PRDATA = 32'h0;
     endcase
     end // always
     always @ ( PSEL or PREADY0 or PREADY1 or PREADY2) begin
     case (PSEL)
     4'h1: PREADY = PREADY0;
     4'h2: PREADY = PREADY1;
     4'h4: PREADY = PREADY2;
     default: PREADY = 1'b1; // make ready by default
     endcase
     end // always
     always @ ( PSEL or PSLVERR0 or PSLVERR1 or PSLVERR2) begin
     case (PSEL)
     4'h1: PSLVERR = PSLVERR0;
     4'h2: PSLVERR = PSLVERR1;
     4'h4: PSLVERR = PSLVERR2;
     4'h8: PSLVERR = 1'b1; // decoding error
     default: PSLVERR = 1'b1; // make error by default
     endcase
     end // always
endmodule
