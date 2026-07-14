module mem_apb4
     #(parameter SIZE_IN_BYTES=1024 // memory size in bytes
               , DELAY=0 ) // access delay if required
(
    (* X_INTERFACE_PARAMETER = "POLARITY ACTIVE_LOW" *)
    (* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 PRESETn RST"    *) input  wire         PRESETn,
    (* X_INTERFACE_PARAMETER = "ASSOCIATED_BUSIF S_APB,ASSOCIATED_RESET PRESETn" *)
    (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 PCLK CLK"       *) input  wire         PCLK,
    (* X_INTERFACE_PARAMETER = "ASSOCIATED_BUSIF S_APB,ASSOCIATED_RESET PRESETn,CLK_DOMAIN PCLK" *)
    (* X_INTERFACE_INFO = "xilinx.com:interface:apb:1.0 S_APB PSEL"    *) input  wire         S_APB_PSEL,
    (* X_INTERFACE_INFO = "xilinx.com:interface:apb:1.0 S_APB PENABLE" *) input  wire         S_APB_PENABLE,
    (* X_INTERFACE_INFO = "xilinx.com:interface:apb:1.0 S_APB PADDR"   *) input  wire [31:0]  S_APB_PADDR,
    (* X_INTERFACE_INFO = "xilinx.com:interface:apb:1.0 S_APB PWRITE"  *) input  wire         S_APB_PWRITE,
    (* X_INTERFACE_INFO = "xilinx.com:interface:apb:1.0 S_APB PWDATA"  *) input  wire [31:0]  S_APB_PWDATA,
    (* X_INTERFACE_INFO = "xilinx.com:interface:apb:1.0 S_APB PRDATA"  *) output reg  [31:0]  S_APB_PRDATA,
    (* X_INTERFACE_INFO = "xilinx.com:interface:apb:1.0 S_APB PREADY"  *) output reg          S_APB_PREADY,
    (* X_INTERFACE_INFO = "xilinx.com:interface:apb:1.0 S_APB PSLVERR" *) output reg          S_APB_PSLVERR,
    (* X_INTERFACE_INFO = "xilinx.com:interface:apb:1.0 S_APB PPROT"   *) input  wire [ 2:0]  S_APB_PPROT,
    (* X_INTERFACE_INFO = "xilinx.com:interface:apb:1.0 S_APB PSTRB"   *) input  wire [ 3:0]  S_APB_PSTRB
);
    localparam ADD_WIDTH  = $clog2(SIZE_IN_BYTES);
    localparam ADD_OFFSET = $clog2(32/8);
    localparam ADD_NEW    = ADD_WIDTH-ADD_OFFSET;
    localparam DEPTH      = 1 << ADD_NEW;

    localparam ST_IDLE  = 2'h0;
    localparam ST_WAIT  = 2'h1;
    localparam ST_DONE  = 2'h2;

    reg [31:0] mem[0:DEPTH-1];
    reg [1:0]  state  = ST_IDLE;
    reg [31:0] cntDly = 32'h0;

    wire [ADD_NEW-1:0] local_add = S_APB_PADDR[ADD_WIDTH-1:ADD_OFFSET];
    wire               setup_phase = S_APB_PSEL && !S_APB_PENABLE;

    always @ (posedge PCLK or negedge PRESETn) begin
        if (PRESETn==1'b0) begin
            S_APB_PRDATA  <= 32'h0;
            S_APB_PREADY  <= 1'b0;
            S_APB_PSLVERR <= 1'b0;
            cntDly        <= 32'h0;
            state         <= ST_IDLE;
        end else begin
            S_APB_PREADY  <= 1'b0;
            S_APB_PSLVERR <= 1'b0;

            case (state)
            ST_IDLE: begin
                cntDly <= 32'h0;
                if (setup_phase==1'b1) begin
                    if (DELAY==0) begin
                        if (S_APB_PWRITE==1'b1) begin
                            if (S_APB_PSTRB[0]) mem[local_add][ 7: 0] <= S_APB_PWDATA[ 7: 0];
                            if (S_APB_PSTRB[1]) mem[local_add][15: 8] <= S_APB_PWDATA[15: 8];
                            if (S_APB_PSTRB[2]) mem[local_add][23:16] <= S_APB_PWDATA[23:16];
                            if (S_APB_PSTRB[3]) mem[local_add][31:24] <= S_APB_PWDATA[31:24];
                        end else begin
                            S_APB_PRDATA <= mem[local_add];
                        end
                        S_APB_PREADY <= 1'b1;
                        state        <= ST_DONE;
                    end else begin
                        state <= ST_WAIT;
                    end
                end
            end
            ST_WAIT: begin
                cntDly <= cntDly + 1;
                if ((cntDly+1)==DELAY) begin
                    if (S_APB_PWRITE==1'b1) begin
                        if (S_APB_PSTRB[0]) mem[local_add][ 7: 0] <= S_APB_PWDATA[ 7: 0];
                        if (S_APB_PSTRB[1]) mem[local_add][15: 8] <= S_APB_PWDATA[15: 8];
                        if (S_APB_PSTRB[2]) mem[local_add][23:16] <= S_APB_PWDATA[23:16];
                        if (S_APB_PSTRB[3]) mem[local_add][31:24] <= S_APB_PWDATA[31:24];
                    end else begin
                        S_APB_PRDATA <= mem[local_add];
                    end
                    S_APB_PREADY <= 1'b1;
                    state        <= ST_DONE;
                end
            end
            ST_DONE: begin
                state <= ST_IDLE;
            end
            default: begin
                cntDly <= 32'h0;
                state  <= ST_IDLE;
            end
            endcase
        end
    end
endmodule
