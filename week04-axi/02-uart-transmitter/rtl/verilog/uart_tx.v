module uart_tx (
    input  wire        clk,
    input  wire        rst_n,

    // CSR CONTROL register 설정값
    input  wire [15:0] cfg_div,
    input  wire        cfg_width,
    input  wire        cfg_parity_en,
    input  wire        cfg_even_parity,
    input  wire        cfg_stop_2bit,

    // CSR TXBUFF에서 오는 송신 요청
    input  wire [7:0]  tx_data,
    input  wire        tx_valid,

    // CSR 또는 상위 모듈로 전달할 상태
    output wire        tx_ready,
    output reg         tx_done,

    // 실제 UART 출력 핀
    output reg         uart_txd
);

    reg       baud_tick;
    reg [15:0] baud_count;
    reg [2:0] c_state;
    reg [2:0] n_state;

    localparam ST_IDLE   = 'h0;
    localparam ST_START  = 'h1;
    localparam ST_DATA   = 'h2;
    localparam ST_PARITY = 'h3;
    localparam ST_STOP   = 'h4;


    always @ (posedge clk or negedge rst_n) begin//current state logic
        if(rst_n == 1'b0) begin
            baud_tick  <= 1'b0;
            baud_count <= 1'b0;
            c_state    <= ST_IDLE;
            n_state    <= ST_IDLE;
        end

        else c_state <= n_state;
    end

    always @ (*) begin//next state logic
        case(c_state)

        ST_IDLE   : begin
            if(tx_ready & tx_valid) n_state = ST_START;
            else begin
            end
        end

        ST_START  : begin
            
        end
        default   : n_state = ST_IDLE;
        endcase
    end
    always @ (posedge clk or negedge rst_n) begin
        case(c_state)

        ST_IDLE   : begin
            baud_count <= 1'b0;
            baud_tick  <= 1'b0;
        end

        ST_START  : begin
            
        end
        ST_DATA   :
        ST_PARITY :
        ST_STOP   :
        endcase
    end