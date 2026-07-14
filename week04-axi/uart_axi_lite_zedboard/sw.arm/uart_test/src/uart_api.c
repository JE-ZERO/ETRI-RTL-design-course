//------------------------------------------------------------------------------
//  Copyright (c) 2024 by Ando Ki.
//  All right reserved.
//
// This program is distributed in the hope that it
// will be useful to understand Ando Ki's work,
// BUT WITHOUT ANY WARRANTY.
//------------------------------------------------------------------------------
#include <stdint.h>
#include <stdio.h>
#include "uart_api.h"

//------------------------------------------------------------------------------
static volatile uint32_t  UART_ADDR_BASE=0x92000000;
static volatile uint32_t  UART_VERSION  =0x92000000;
static volatile uint32_t  UART_NAME     =0x92000004;
static volatile uint32_t  UART_CONTROL  =0x92000010;
static volatile uint32_t  UART_STATUS   =0x92000014;
static volatile uint32_t  UART_TX       =0x92000018;
static volatile uint32_t  UART_RX       =0x9200001C;
static volatile uint32_t  UART_CLK_FREQ =0x92000020;

//------------------------------------------------------------------------------
#if defined(TRX_BFM)
#include "cosim_bfm_axi.h"
        extern int cid;
#       define CSR_WRITE(A,B)   cosim_bfm_axi_lite_write((uint32_t)(A), (uint32_t)(B), cid)
#       define CSR_READ(A,B)    cosim_bfm_axi_lite_read((uint32_t)(A), (uint32_t*)&(B), cid)
#else
#define reinterpret_cast(TO, VAR)\
       ({ union { __typeof__((VAR)) source; TO dest; } u = { .source = (VAR) }; (TO)u.dest; })
#       define CSR_WRITE(A,B)   *(reinterpret_cast(uint32_t *, (A))) = B;
#       define CSR_READ(A,B)    B = *(reinterpret_cast(uint32_t *, A));
#endif

//------------------------------------------------------------------------------
// Default should be 8-bit, no-parity, 1-stop
void uart_init( uint32_t freq     // clock frequency in Hz (use CSR when 0)
              , uint32_t baudrate // baud rate
              , uint32_t width    // 8: 8-bit, 7: 7-bit
              , uint32_t parity   // 0: disable, 1: odd, 2 even
              , uint32_t stop     // 1: 1-bit, 2: 2-bit
              )
{
     volatile uint32_t val;
     if (freq==0) freq = uart_get_clk_freq();
     val  = (int)(freq/baudrate+0.5)&0xFFFF;
     val |= (width==8 ) ? 0 : 1<<16;
     val |= (parity==0) ? 0 : 1<<17;
     val |= (parity==1) ? 0 : 1<<18;
     val |= (stop==1  ) ? 0 : 1<<19;
     CSR_WRITE( UART_CONTROL, val );
}

//------------------------------------------------------------------------------
// Default should be 8-bit, no-parity, 1-stop
void uart_init_ext( uint32_t freq     // clock frequency in Hz (use CSR when 0)
                  , uint32_t baudrate // baud rate
                  , uint32_t width    // 8: 8-bit, 7: 7-bit
                  , uint32_t parity   // 0: disable, 1: odd, 2 even
                  , uint32_t stop     // 1: 1-bit, 2: 2-bit
                  , int ie_rx // enabel rx interrupt
                  , int ie_tx // enabel tx interrupt
                  )
{
     volatile uint32_t val;
     if (freq==0) freq = uart_get_clk_freq();
     val  = (int)(freq/baudrate+0.5)&0xFFFF;
     val |= (width==8 ) ? 0 : 1<<16;
     val |= (parity==0) ? 0 : 1<<17;
     val |= (parity==1) ? 0 : 1<<18;
     val |= (stop==1  ) ? 0 : 1<<19;
     val |= (ie_rx==0 ) ? 0 : 1<<21;
     val |= (ie_tx==0 ) ? 0 : 1<<20;
     CSR_WRITE( UART_CONTROL, val );
}

//------------------------------------------------------------------------------
uint32_t uart_get_char(void) {
    volatile uint32_t val;
    do { CSR_READ(UART_RX, val);
    } while (!(val&0x80000000));
    return val&0xFF;
}

//------------------------------------------------------------------------------
uint32_t uart_put_char(char d) {
    volatile uint32_t val;
    do { CSR_READ(UART_TX, val);
    } while (val&0x80000000);
    val = d;
    CSR_WRITE(UART_TX, val);
    return (uint32_t)d;
}

//------------------------------------------------------------------------------
int uart_put_string(char* s) {
   char c;
   int i=0;
   while ((c=*s++)) {
       uart_put_char(c);
       i++;
   }
   return i;
}

//------------------------------------------------------------------------------
void uart_cler_tx_irq(void)
{
    volatile uint32_t val;
    CSR_READ(UART_STATUS, val);
    val &= ~0x1; // bit-0
    CSR_WRITE(UART_STATUS, val);
}

//------------------------------------------------------------------------------
void uart_cler_rx_irq(void)
{
    volatile uint32_t val;
    CSR_READ(UART_STATUS, val);
    val &= ~0x2; // bit-1
    CSR_WRITE(UART_STATUS, val);
}

//------------------------------------------------------------------------------
uint32_t uart_get_clk_freq(void) {
    volatile uint32_t val;
    CSR_READ(UART_CLK_FREQ, val);
    return val;
}

void uart_csr(void)
{
    volatile uint32_t val;
    CSR_READ(UART_VERSION , val); printf("VERSION : 0x%08lX\n\r", val);
    CSR_READ(UART_NAME    , val); printf("NAME    : 0x%08lX\n\r", val);
    CSR_READ(UART_CONTROL , val); printf("CONTROL : 0x%08lX\n\r", val);
    CSR_READ(UART_STATUS  , val); printf("STATUS  : 0x%08lX\n\r", val);
    CSR_READ(UART_TX      , val); printf("TX      : 0x%08lX\n\r", val);
    CSR_READ(UART_RX      , val); printf("RX      : 0x%08lX\n\r", val);
    CSR_READ(UART_CLK_FREQ, val); printf("CLK_FREQ: 0x%08lX\n\r", val);
}

//------------------------------------------------------------------------------
void uart_set_addr( uint32_t addr ) {
    UART_ADDR_BASE = addr;
    UART_VERSION   = addr+0x00;
    UART_NAME      = addr+0x04;
    UART_CONTROL   = addr+0x10;
    UART_STATUS    = addr+0x14;
    UART_TX        = addr+0x18;
    UART_RX        = addr+0x1C;
    UART_CLK_FREQ  = addr+0x20;
}

//------------------------------------------------------------------------------
uint32_t uart_get_addr( void ) {
    return UART_ADDR_BASE;
}

//------------------------------------------------------------------------------
// Revision history
//
// 2024.08.10: Started by Ando Ki (andoki@gmail.com)
//------------------------------------------------------------------------------
