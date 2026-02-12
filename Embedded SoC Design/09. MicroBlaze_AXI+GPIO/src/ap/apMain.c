#include "apMain.h"
#include "sleep.h"


led_handler_t hLeds_L[4]; //Led[0~3]
led_handler_t hLeds_H[4]; //Led[4~7]

button_handler_t hbtnL;
button_handler_t hbtnR;

typedef enum {
    MODE1,
    MODE2
} state_t;

state_t state;

void App_Init () {



//   Button_Init(&hErrorButton, GPIOC, 2);
   state = MODE1;

   	   Led_Init(&hLeds_L[0], GPIOA, 0);
   	   Led_On(&hLeds_L[0]);
   for(int i=1; i<4; i++) {
	   Led_Init(&hLeds_L[i],GPIOA, i);
	   Led_Off(&hLeds_L[i]);
   }
   for(int i=0; i<4; i++) {
   	   Led_Init(&hLeds_H[i], GPIOB, i);
   	   Led_Off(&hLeds_H[i]);
      }

   Button_Init(&hbtnL, GPIOC, 1); //초기화
}

void App_Excute()
{
	static int led_temp_L = 0;
	static int led_temp_H = 0;

   switch(state)
   {
    case MODE1 :
//    	Led_On(&hPowerLed);
//    if (Button_GetState(&hPowerButton) == ACT_RELEASED) {
//    	Led_On(hLeds);
//    state = MODE2;
    	if(Button_GetState(&hbtnL) == ACT_RELEASED) {

    	    if (led_temp_L < 3) { // 0, 1, 2일 때
    	        led_temp_L++;
    	        Led_On(&hLeds_L[led_temp_L]);
    	        Led_Off(&hLeds_L[led_temp_L-1]);
    	    }
    	    else if (led_temp_L == 3) { // 3(LED 3)에서 4(LED 4)로 넘어갈 때!
    	        Led_Off(&hLeds_L[3]);
    	        led_temp_L = 4;        // L그룹 끝났음을 표시
    	        led_temp_H = 0;        // H그룹 시작
    	        Led_On(&hLeds_H[0]);   // LED 4번이 켜짐
    	    }
    	    else if (led_temp_H < 3) { // H그룹 내부 이동 (4 -> 5 -> 6 -> 7)
    	        led_temp_H++;
    	        Led_On(&hLeds_H[led_temp_H]);
    	        Led_Off(&hLeds_H[led_temp_H-1]);
    	    }




//    		Led_On(&hLeds_L[led_temp_L]);
//    		Led_Off(&hLeds_L[led_temp_L-1]);
//
////    		Led_Off(&hLeds_L[0]);
////    		Led_Off(&hLeds_L[1]);
////    		Led_Off(&hLeds_L[2]);
////    		Led_Off(&hLeds_L[3]);
//
//    		if(led_temp_H>0){
//    			Led_On(&hLeds_H[led_temp_H]);
//    			Led_Off(&hLeds_H[led_temp_H-1]);
//    		}
//    		if(led_temp_L > 3)
//    		    		{
//    		    			led_temp_H ++;
//    		    		}


    		usleep(500000);
    break;

    case MODE2 :
//    Led_Toggle(&hErrorLed);
//    	Led_On(&hErrorLed);
//    	Led_Off(&hPowerLed);
//    if (Button_GetState(&hPowerButton) == ACT_RELEASED) {
//    state = MODE1;

    usleep(200000);
    break;
    	}
   }
}

