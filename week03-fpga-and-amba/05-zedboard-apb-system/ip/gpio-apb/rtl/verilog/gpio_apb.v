//--------------------------------------------------------
// gpio_apb.v
//--------------------------------------------------------
// [REGISTERS]
// 0x00: Line Control Register
//       '0' = input mode (default)
//       '1' = output mode
// 0x04: Line Register
//       Current GPIO pin level
// 0x08: Interrupt Mask Register
//       '0' = enabled
//       '1' = masked (disabled) (default)
// 0x0C: Interrupt Flag
// 0x10: Interrupt Edge/Level Sensitivity Mode Register
//       '0' = Level sensitivity mode (default)
//       '1' = Edge sensitivity mode
// 0x14: Interrupt Pol Sensitivity Mode Register
//       '0' = active-low for level mode, falling for edge mode (default)
//       '1' = active-high for level mode, rising for edge mode
//
// [HOWTO]
// * Use a pin as an input:
//   Program the corresponding bit in the Control Register
//   to 'input mode' ('0').
//   Then, the pin's state (input level) can be checked
//   by reading the Line Register.
//   Note that writing to the GPIO pin's Line Register bit
//   while in input mode has no effect.
//
// * Use a pin as an output:
//   Program the corresponding bit in the Control Register
//   to 'output mode' ('1').
//   Then, program the GPIO pin's output level by writing
//   to the corresponding bit in the Line Register.
//   Note reading the GPIO pin's Line Register bit while
//   in output mode returns the current input pin level
//   so that it may not reflect the value written.
//
// * Use a pin as an interrupt source:
//   Program the corresponding bit in the Edge Register
//   to the desired sensitivity mode (level or edge).
//   Program the corresponding bit in the Pol Register
//   to the desired sensitivity mode (low/falling or high/rising).
//   Program the corresponding bit in the Mask Register
//   to 'un-masked mode' ('0').
//--------------------------------------------------------
module gpio_apb #(parameter GPIO_WIDTH = 32)
(
    input PRESETn,
    input PCLK,
    input PSEL,
    input PENABLE,
    input PWRITE,
    input [31:0] PADDR,
    input [31:0] PWDATA,
    input [GPIO_WIDTH-1:0] GPIO_I,
    output [GPIO_WIDTH-1:0] GPIO_O,
    output [GPIO_WIDTH-1:0] GPIO_T,
    output IRQ,
    output reg [31:0] PRDATA
);

    localparam LINECONTROL = 8'h00;
    localparam LINEREG     = 8'h04;

    wire [7:0] reg_addr = PADDR[7:0];
    wire apb_write = PSEL &&  PENABLE &&  PWRITE;
    wire apb_read  = PSEL && !PENABLE && !PWRITE;

    reg [GPIO_WIDTH-1:0] line_control_reg;
    reg [GPIO_WIDTH-1:0] line_output_reg;

    //----------------------------------------------------
    // GPIO side
    //----------------------------------------------------
    // line_control_reg: 0=input mode, 1=output mode
    // GPIO_T:           1=input/high-Z, 0=output enable
    // gpio_apb_xilinx.v connects GPIO_T to gpio_dir.
    // gpio_dir comment says: 0=output, 1=input.
    assign GPIO_O = line_output_reg;
    assign GPIO_T = ~line_control_reg;

    //----------------------------------------------------
    // Interrupt is not implemented
    //----------------------------------------------------
    assign IRQ = 1'b0;

    //----------------------------------------------------
    // APB write block
    //----------------------------------------------------
    always @(posedge PCLK or negedge PRESETn) begin
        if (!PRESETn) begin
            line_control_reg <= {GPIO_WIDTH{1'b0}};
            line_output_reg  <= {GPIO_WIDTH{1'b0}};
        end
        else if (apb_write) begin
            case (reg_addr)
                LINECONTROL: begin
                    line_control_reg <= PWDATA[GPIO_WIDTH-1:0];
                end

                LINEREG: begin
                    line_output_reg <= (line_output_reg & ~line_control_reg) |
                                       (PWDATA[GPIO_WIDTH-1:0] & line_control_reg);
                end

                default: begin
                end
            endcase
        end
    end

    //----------------------------------------------------
    // APB read block
    //----------------------------------------------------
    always @(posedge PCLK or negedge PRESETn) begin
        if (!PRESETn) begin
            PRDATA <= 32'h0000_0000;
        end
        else if (apb_read) begin
            PRDATA <= 32'h0000_0000;

            case (reg_addr)
                LINECONTROL: begin
                    PRDATA[GPIO_WIDTH-1:0] <= line_control_reg;
                end

                LINEREG: begin
                    PRDATA[GPIO_WIDTH-1:0] <= GPIO_I;
                end

                default: begin
                    PRDATA <= 32'h0000_0000;
                end
            endcase
        end
    end

endmodule
