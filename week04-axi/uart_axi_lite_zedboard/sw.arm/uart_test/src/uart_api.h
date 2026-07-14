#ifndef _UART_API_H_
#define _UART_API_H_
//--------------------------------------------------------
//  Copyright (c) 2024 by Ando Ki.
//  All right reserved.
//
// This program is distributed in the hope that it
// will be useful to understand Ando Ki's work,
// BUT WITHOUT ANY WARRANTY.
//--------------------------------------------------------
#include <stdint.h>

#ifdef __cplusplus                                                                                     
extern "C" {
#endif

void     uart_init( uint32_t freq
                  , uint32_t baudrate
                  , uint32_t width
                  , uint32_t parity
                  , uint32_t stop);
uint32_t uart_get_char    (void);
uint32_t uart_put_char    (char d);
int      uart_put_string  (char* s);
uint32_t uart_get_clk_freq(void);
void     uart_set_addr    (uint32_t addr);
uint32_t uart_get_addr    (void);
void     uart_csr         (void);

void uart_init_ext( uint32_t freq     // clock frequency in Hz (use 0, if not sure)
                  , uint32_t baudrate // baud rate
                  , uint32_t width    // 8: 8-bit, 7: 7-bit
                  , uint32_t parity   // 0: disable, 1: odd, 2 even
                  , uint32_t stop     // 1: 1-bit, 2: 2-bit
                  , int ie_rx // enabel rx interrupt
                  , int ie_tx // enabel tx interrupt
                  );
void uart_cler_tx_irq(void);
void uart_cler_rx_irq(void);

#ifdef __cplusplus
}
#endif
//--------------------------------------------------------
// Revision history
//
// 2024.08.10: Started by Ando Ki (andoki@gmail.com)
//--------------------------------------------------------
#endif
