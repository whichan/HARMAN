#include "ultrasonic.h"
#include <stdio.h>

void ultrasonic_main();

extern volatile int TIM10_1ms_ultrasonic;
int distances[3]; //0:Left, 1:Center, 2:Right
int ic_echo_flags[3]; //각 센서별 완료 플래그

// void HAL_TIM_IC_CaptureCallback(TIM_HandleTypeDef *htim)
// {
// 	static uint8_t is_first_capture[3] = {0, 0, 0};
// 	int idx = -1;
// 	uint32_t channel;

// 	if(htim->Instance == TIM1)
// 	{
// 		if(htim->Channel == HAL_TIM_ACTIVE_CHANNEL_1) {idx=0; channel = TIM_CHANNEL_1;}
// 		else if (htim->Channel == HAL_TIM_ACTIVE_CHANNEL_2) { idx = 1; channel = TIM_CHANNEL_2;}
// 		else if (htim->Channel == HAL_TIM_ACTIVE_CHANNEL_4) { idx = 2; channel = TIM_CHANNEL_4;}
// 		if(idx != -1)
// 		{
// 			if(is_first_capture[idx] == 0)
// 			{
// 				__HAL_TIM_SET_COUNTER(htim,0);
// 				is_first_capture[idx] = 1;
// 			}
// 			else
// 			{
// 				is_first_capture[idx] = 0;
// 				distances[idx] = HAL_TIM_ReadCapturedValue(htim, channel);
// 				ic_echo_flags[idx] = 1;
// 			}
// 		}
// 	}
// }

void HAL_TIM_IC_CaptureCallback(TIM_HandleTypeDef *htim)
{
    static uint8_t is_first_capture[3] = {0, 0, 0};
    int idx = -1;

    if(htim->Instance == TIM1)
    {
        // 현재 어떤 채널에서 이벤트가 발생했는지 확인
        if(htim->Channel == HAL_TIM_ACTIVE_CHANNEL_1) idx = 0;
        else if (htim->Channel == HAL_TIM_ACTIVE_CHANNEL_2) idx = 1;
        else if (htim->Channel == HAL_TIM_ACTIVE_CHANNEL_4) idx = 2;

        if(idx != -1)
        {
            if(is_first_capture[idx] == 0)
            {
                // __HAL_TIM_SET_COUNTER 대신 CNT 레지스터 직접 0으로 리셋
                TIM1->CNT = 0; 
                is_first_capture[idx] = 1;
            }
            else
            {
                is_first_capture[idx] = 0;
                // 채널별로 대응하는 CCR 레지스터 읽기
                if(idx == 0)      distances[idx] = TIM1->CCR1;
                else if(idx == 1) distances[idx] = TIM1->CCR2;
                else if(idx == 2) distances[idx] = TIM1->CCR4;
                
                ic_echo_flags[idx] = 1;
            }
        }
    }
}

// void make_trigger(void)
// {
// 	// 세 핀을 동시에 High로
// 	HAL_GPIO_WritePin(LEFT_TRIG_GPIO_Port, LEFT_TRIG_Pin, 1);
// 	HAL_GPIO_WritePin(CENTER_TRIG_GPIO_Port, CENTER_TRIG_Pin, 1);
// 	HAL_GPIO_WritePin(RIGHT_TRIG_GPIO_Port, RIGHT_TRIG_Pin, 1);

// 	delay_us(10); // 10us 유지

//    // 세 핀을 동시에 Low로
// 	HAL_GPIO_WritePin(LEFT_TRIG_GPIO_Port, LEFT_TRIG_Pin, 0);
// 	HAL_GPIO_WritePin(CENTER_TRIG_GPIO_Port, CENTER_TRIG_Pin, 0);
// 	HAL_GPIO_WritePin(RIGHT_TRIG_GPIO_Port, RIGHT_TRIG_Pin, 0);
// }

void make_trigger(void)
{
    // Trig 핀들이 모두 GPIOC에 연결되어 있다고 가정 (C0, C1, C2 등)
    // 1. 세 핀을 동시에 High로 (Set)
    GPIOC->BSRR = (LEFT_TRIG_Pin | CENTER_TRIG_Pin | RIGHT_TRIG_Pin);

    delay_us(10); // 10us 유지

    // 2. 세 핀을 동시에 Low로 (Reset)
    // BSRR의 상위 16비트는 Reset 영역입니다.
    GPIOC->BSRR = ((uint32_t)LEFT_TRIG_Pin << 16) | 
                  ((uint32_t)CENTER_TRIG_Pin << 16) | 
                  ((uint32_t)RIGHT_TRIG_Pin << 16);
}



void ultrasonic_main()
{
   if(TIM10_1ms_ultrasonic >= 500) // 0.5초마다
   {
       TIM10_1ms_ultrasonic = 0;

       // 중요: 새로운 트리거를 쏘기 전에 기존 플래그를 초기화
       ic_echo_flags[0] = ic_echo_flags[1] = ic_echo_flags[2] = 0;

       make_trigger();
   }

   // 세 센서 중 하나라도 값이 들어오면 일단 출력하게 하거나,
   // 혹은 셋 다 들어왔을 때만 출력하되 줄바꿈(\r\n)을 꼭 넣어주세요.
   if(ic_echo_flags[0] && ic_echo_flags[1] && ic_echo_flags[2])
   {
       ic_echo_flags[0] = ic_echo_flags[1] = ic_echo_flags[2] = 0;

       int distL = distances[0] * 0.034 / 2;
       int distC = distances[1] * 0.034 / 2;
       int distR = distances[2] * 0.034 / 2;

       // \r\n을 안 붙이면 버퍼에 쌓여서 출력이 늦거나 씹힐 수 있음
       printf("L:%d C:%d R:%d\r\n", distL, distC, distR);
   }
}