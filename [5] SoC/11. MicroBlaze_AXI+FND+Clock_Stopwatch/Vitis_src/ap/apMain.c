#include "apMain.h"
#include "sleep.h"
#include <stdio.h>

led_handler_t hLed_Stopwatch;
led_handler_t hLed_Clock;

button_handler_t hBtnL; //clear
button_handler_t hBtnR; //run/stop
button_handler_t hBtnD; //mode change

int mode = 0; //0: clock , 1: stopwatch

//시계용 변수
int hour=0;
int min=0;
int sec=0;
uint32_t prevTime_clock = 0;

//스톱워치용 변수
int stopwatch_tick = 0; //0.01초 단위 카운트
bool stopwatch_run = false; //true: 달리는 중, false: 멈춰있음
uint32_t prevTime_stopwatch = 0;

void App_Init ()
{

	SysTimer_Init(0); //clock 초기화
	SysTimer_Init(1); //stopwatch 초기화
	FND_Init();

	Button_Init(&hBtnL, GPIOB, BTN_L);
	Button_Init(&hBtnR, GPIOB, BTN_R);
	Button_Init(&hBtnD, GPIOB, BTN_D);
	Led_Init(&hLed_Stopwatch, GPIOA, 0);
	Led_Init(&hLed_Clock, GPIOA, 1);
	SysTimer_Start(0);
	SysTimer_Start(1);
}

void App_Clock_Run()
{
	//시간이 1000ms가 지났는지 확인
	if(SysTimer_is_elapsed(0, prevTime_clock, 1000-1)==false){
		return;
	}

	prevTime_clock = SysTimer_GetTick(0);
	sec++;
	if(sec>=60) {
		sec=0;
		min++;

		if(min>=60){
			min=0;
		}
	}
}

void App_Stopwatch_Run()
{
	//스톱워치가 멈춰있으면 return
	if(stopwatch_run == false)
	{
		return;
	}

	if(SysTimer_is_elapsed(1, prevTime_stopwatch, 10-1) == false)
	{
		return;
	}

	prevTime_stopwatch = SysTimer_GetTick(1);
	stopwatch_tick ++;

	if(stopwatch_tick > 9999)
	{
		stopwatch_tick = 0;
	}
}

void App_Button_Check()
{
	if(Button_GetState(&hBtnD)==ACT_PUSHED) {
		mode = !mode;
		if(mode==0){
			//clock mode led on
			Led_On(&hLed_Clock);
			Led_Off(&hLed_Stopwatch);
		}
		else{
			Led_Off(&hLed_Clock);
			Led_On(&hLed_Stopwatch);
		}
	}

	if(mode==1) {
		if(Button_GetState(&hBtnR) == ACT_PUSHED)
		{
			stopwatch_run = !stopwatch_run;
		}

		if(Button_GetState(&hBtnL) == ACT_PUSHED)
		{
			stopwatch_tick = 0;
		}
	}
}

void App_Display_FND()
{
	int display_number = 0;

	if(mode==0) //시계
	{
		display_number = (min*100) + sec;
	}
	else
	{
		display_number = stopwatch_tick;
	}
	FND_SetNumber(display_number);
	FND_Scan(); //잔상효과
}


void App_Excute()
{
	Led_On(&hLed_Clock);
	Led_Off(&hLed_Stopwatch);

	while(1)
	{
		App_Clock_Run();
		App_Stopwatch_Run();
		App_Button_Check();
		App_Display_FND();
	}
}
