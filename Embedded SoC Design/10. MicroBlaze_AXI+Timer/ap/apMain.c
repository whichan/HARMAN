#include "apMain.h"
#include "sleep.h"
#include <stdio.h>

led_handler_t hLed1 ,hLed2;

void Service1();
void Service2();
void Service3();

void App_Init ()
{

	SysTimer_Init();
	SysTimer_Start();
	Led_Init(&hLed1, GPIOA, 0);
	Led_Init(&hLed2, GPIOA, 3);
}

void App_Excute()
{
	Service1();
	Service2();
	Service3();
}

void Service1()
{

	static uint32_t startTimer = 0;

	if	(!SysTimer_is_elapsed(startTimer, 500)) return;

		startTimer = SysTimer_GetTick();
		printf("timer: %d\n", startTimer);

}

void Service2()
{

	static uint32_t ledTimer1  = 0;

	if	(!SysTimer_is_elapsed(ledTimer1, 500)) return;

		ledTimer1 = SysTimer_GetTick();
		Led_Toggle(&hLed1);

}

void Service3()
{

	static uint32_t ledTimer2  = 0;

	if	(!SysTimer_is_elapsed(ledTimer2, 1000)) return;

		ledTimer2 = SysTimer_GetTick();
		Led_Toggle(&hLed2);

}
