
/*
 * helloworld.c: simple test application
 *
 * This application configures UART 16550 to baud rate 9600.
 * PS7 UART (Zynq) is not initialized by this application, since
 * bootrom/bsp configures it to baud rate 115200
 *
 * ------------------------------------------------
 * | UART TYPE   BAUD RATE                        |
 * ------------------------------------------------
 *   uartns550   9600
 *   uartlite    Configurable only in HW design
 *   ps7_uart    115200 (configured by bootrom/bsp)
 */

#include <stdio.h>
#include "platform.h"
#include "xil_printf.h"
#include "uart_api.h"

int main()
{
    init_platform();

    print("UART Test\n\r");

    uint32_t dataW, dataR;
    uint32_t *addr=(uint32_t*)0x60000000;
    dataW = 0x12345678;
    *addr = dataW;
    dataR = *addr;
    printf("A=0x%08X DW=0x%08lX DR=0x%08lX\n\r", (unsigned)addr, dataW, dataR);

    uart_set_addr(0x60000000);
    uart_csr();

    uart_init( 100000000 //unsigned int freq     // clock frequency in Hz
             , 115200    //unsigned int baudrate // baud rate
             , 8         //unsigned int width    // 8: 8-bit, 7: 7-bit
             , 0         //unsigned int parity   // 0: disable, 1: enable
             , 1         //unsigned int stop     // 1: 1-bit, 2: 2-bit
             );
    uart_csr();

    uart_put_char('A');
    uart_put_char('B');

    char *message="It's me...\n\r";
    do { uart_put_string( message );
    } while (1);

    cleanup_platform();
    return 0;
}
