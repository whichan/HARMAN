#include "button.h"

unsigned char button_status[BUTTON_NUMBER] ={
		BUTTON_RELEASE, BUTTON_RELEASE, BUTTON_RELEASE, BUTTON_RELEASE, BUTTON_RELEASE
};

void button_check(void)
{
	//버튼을 1번 눌렀다 떼는지 체크
	   if(get_button(GPIOC, GPIO_PIN_0, BUTTON0) == BUTTON_PRESS )
	   {
	      HAL_GPIO_TogglePin(GPIOB, GPIO_PIN_0);
	   }
	   else if(get_button(GPIOC, GPIO_PIN_1, BUTTON1) == BUTTON_PRESS )
	   {
	      HAL_GPIO_TogglePin(GPIOB, GPIO_PIN_1);
	   }
	   else if(get_button(GPIOC, GPIO_PIN_2, BUTTON2) == BUTTON_PRESS )
	   {
	      HAL_GPIO_TogglePin(GPIOB, GPIO_PIN_2);
	   }
	   else if(get_button(GPIOC, GPIO_PIN_3, BUTTON3) == BUTTON_PRESS )
	   {
	      HAL_GPIO_TogglePin(GPIOB, GPIO_PIN_3);
	   }
	   else if(get_button(GPIOC, GPIO_PIN_13, BUTTON4) == BUTTON_PRESS )
	   {
	      HAL_GPIO_TogglePin(GPIOB, GPIO_PIN_5);
	   }
}

int get_button(GPIO_TypeDef* GPIOx, uint16_t GPIO_Pin , int button_number)
{
   int state = HAL_GPIO_ReadPin(GPIOx, GPIO_Pin);


   if(state == BUTTON_PRESS && button_status[button_number] == BUTTON_RELEASE)
   {
      HAL_Delay(20);
      button_status[button_number] = BUTTON_PRESS;
      return BUTTON_RELEASE;
   }

   else if (state == BUTTON_RELEASE && button_status[button_number] == BUTTON_PRESS)
   {
      HAL_Delay(20);
      button_status[button_number] = BUTTON_RELEASE;
      return BUTTON_PRESS;
   }

   return BUTTON_RELEASE;
}
