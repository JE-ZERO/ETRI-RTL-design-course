#include <stdio.h>
#include <stdint.h>
#include "platform.h"
#include "xil_printf.h"

#define GPIO_BASE_ADDR      0x60002000U
#define GPIO_CONTROL_OFFSET 0x00U
#define GPIO_LINE_OFFSET    0x04U

#define GPIO_CONTROL_REG    (*(volatile uint32_t *)(GPIO_BASE_ADDR + GPIO_CONTROL_OFFSET))
#define GPIO_LINE_REG       (*(volatile uint32_t *)(GPIO_BASE_ADDR + GPIO_LINE_OFFSET))

#define GPIO_USED_MASK      0x0000001FU  /* BTNC/BTND/BTNL/BTNR/BTNU and LED0~LED4 */

int main()
{
    uint32_t btn;
    uint32_t prev_btn;
    uint32_t pressed;
    uint32_t led_state;

    init_platform();

    xil_printf("GPIO APB Toggle Test\r\n");
    xil_printf("GPIO base address = 0x%08X\r\n", GPIO_BASE_ADDR);

    /*
     * Line Control Register
     *   0 = input mode
     *   1 = output mode
     *
     * GPIO_LINE_REG write updates GPIO_O only for bits whose
     * control bit is 1. We use lower 5 GPIO bits for LEDs.
     */
    GPIO_CONTROL_REG = GPIO_USED_MASK;

    led_state = 0x00000000U;
    prev_btn  = GPIO_LINE_REG & GPIO_USED_MASK;
    GPIO_LINE_REG = led_state;

    xil_printf("CONTROL = 0x%08lX\r\n", GPIO_CONTROL_REG);
    xil_printf("Press a button once to toggle its LED. Press again to toggle off.\r\n");
    xil_printf("Initial BTN=0x%02lX LED=0x%02lX\r\n", prev_btn, led_state);

    while (1) {
        /* Read current button input from GPIO_I through Line Register. */
        btn = GPIO_LINE_REG & GPIO_USED_MASK;

        /* Detect only 0->1 transitions, so holding a button does not repeat. */
        pressed = btn & ~prev_btn;

        if (pressed != 0U) {
            /* Toggle the LED bits corresponding to newly pressed buttons. */
            led_state ^= pressed;
            led_state &= GPIO_USED_MASK;

            GPIO_LINE_REG = led_state;

            xil_printf("PRESSED=0x%02lX BTN=0x%02lX LED=0x%02lX\r\n",
                       pressed, btn, led_state);
        }

        prev_btn = btn;

        /* Simple debounce / polling delay. */
        for (volatile int delay = 0; delay < 100000; delay++) {
        }
    }

    cleanup_platform();
    return 0;
}