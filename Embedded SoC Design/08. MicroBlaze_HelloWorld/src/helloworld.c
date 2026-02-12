#include <stdint.h>
#include "platform.h"
#include "xparameters.h"
#include "xil_io.h"
#include "sleep.h"

#define LED_GPIO_BASE   XPAR_AXI_GPIO_0_BASEADDR   // 0x40000000
#define SW_GPIO_BASE    XPAR_AXI_GPIO_1_BASEADDR   // 0x40010000

#define GPIO_DATA       0x00
#define GPIO_TRI        0x04

int main()
{
    init_platform();

    // LED GPIO: output
    Xil_Out32(LED_GPIO_BASE + GPIO_TRI, 0x00000000);

    // Switch GPIO: input
    Xil_Out32(SW_GPIO_BASE + GPIO_TRI, 0xFFFFFFFF);

    while(1) {
        uint32_t sw = Xil_In32(SW_GPIO_BASE + GPIO_DATA);
        Xil_Out32(LED_GPIO_BASE + GPIO_DATA, sw);
        usleep(1000);
    }

    cleanup_platform();
    return 0;
}
