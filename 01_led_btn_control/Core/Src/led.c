#include "led.h"
#include "button.h"

void led_main(void);
extern void button_check(void);
static int led_mode = 0;

void led_all_on(void)
{
	HAL_GPIO_WritePin(GPIOB, 0xff, 1);
	//0xff는 0'b11111111 이기 때문에 모두 1
//	HAL_GPIO_WritePin(GPIOB, GPIO_PIN_0| GPIO_PIN_1| GPIO_PIN_2|
//	           GPIO_PIN_3|GPIO_PIN_4| GPIO_PIN_5| GPIO_PIN_6| GPIO_PIN_7, 1);
}

void led_all_off(void)
{
	HAL_GPIO_WritePin(GPIOB, 0xff, 0);
//	HAL_GPIO_WritePin(GPIOB, GPIO_PIN_0| GPIO_PIN_1| GPIO_PIN_2|
//	           GPIO_PIN_3|GPIO_PIN_4| GPIO_PIN_5| GPIO_PIN_6| GPIO_PIN_7, 1);
}

// 7 -> 6 -> 5 -> 4 -> 3 -> 2 -> 1 -> 0
// 100ms 주기로 위의 동작을 싱행 (기존에 on된 led는 off로 처리)
void led_up_on(void)
{
	for(int i=0; i<8; i++) // or (int i=0; i<= 7; i++)
	{
		led_all_off();
		HAL_GPIO_WritePin(GPIOB, 0x01 << i, 1);
		HAL_Delay(100);
	}
	led_all_off();
	HAL_Delay(100);
}

void led_down_on(void)
{
	for(int i=0; i<8; i++) // or (int i=0; i<= 7; i++)
	{
		led_all_off();
		HAL_GPIO_WritePin(GPIOB, 0x80 >> i, 1);
		HAL_Delay(100);
	}
	led_all_off();
	HAL_Delay(100);
}

// 7 6 5 4 3 2 1 0
// 100ms 주기로 위의 동작을 실행 (기존에 on된 led는 on으로 처리)
void led_keepon_up(void)
{
	for(int i=0; i<8; i++) // or (int i=0; i<= 7; i++)
		{
			HAL_GPIO_WritePin(GPIOB, 0x01 << i, 1);
			HAL_Delay(100);
		}
		led_all_off();
		HAL_Delay(100);
}

// 7 6 5 4 3 2 1 0
// 100ms 주기로 위의 동작을 실행 (기존에 on된 led는 on으로 처리)
void led_keepon_down(void)
{
	for(int i=0; i<8; i++) // or (int i=0; i<= 7; i++)
			{
				HAL_GPIO_WritePin(GPIOB, 0x80 >> i, 1);
				HAL_Delay(100);
			}
			led_all_off();
			HAL_Delay(100);
}

void led_flower_on(void)
{
    for(int i=0; i < 4; i++)
    {

        HAL_GPIO_WritePin(GPIOB, 0x10 << i | 0x08 >> i, 1);
        HAL_Delay(100);
    }
}

void led_flower_off(void)
{
    for(int i=0; i < 4; i++)
        {

            HAL_GPIO_WritePin(GPIOB, 0x80 >> i | 0x01 << i, 0);
            HAL_Delay(100);
        }
}

void led_main(void)
{
	  if(get_button(GPIOC, GPIO_PIN_0, BUTTON0) == BUTTON_PRESS)
	  {
		  led_mode++;

		  if(led_mode >5)
			  led_mode = 0;
	  }

	  switch (led_mode)
	  {
	  case 0:
		  led_all_on();
		  break;
	  case 1:
		  led_all_off();
		  break;
	  case 2:
		  led_up_on();
		  break;
	  case 3:
		  led_down_on();
		  break;
	  case 4:
		  led_flower_on();
		  break;
	  case 5:
		  led_flower_off();
		  break;
	  }
//		button_check();
//		led_all_on();
//		HAL_Delay(1000);
//		led_all_off();
//		HAL_Delay(1000);
//		led_flower_on();
//		led_flower_off();

}
