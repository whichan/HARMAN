/*
 * Led.c
 *
 *  Created on: 2026. 2. 12.
 *      Author: kccistc
 */


#include "Led.h"


void Led_Init(led_handler_t *hLed, GPIO_TypeDef *GPIOx, uint32_t GPIO_Pin) //초기화하는건 해당 핸들러 값을 주면된다.
{
   hLed -> GPIOx = GPIOx;
   hLed -> GPIO_Pin = GPIO_Pin;
   GPIO_Init(hLed->GPIOx, hLed->GPIO_Pin, OUTPUT_MODE);
}

void Led_On(led_handler_t *hLed)
{
   GPIO_WritePin(hLed->GPIOx, hLed->GPIO_Pin, HIGH);
}

void Led_Off(led_handler_t *hLed)
{
   GPIO_WritePin(hLed->GPIOx, hLed->GPIO_Pin, LOW);
}

void Led_Toggle(led_handler_t *hLed)
{
   GPIO_TogglePin(hLed->GPIOx, hLed->GPIO_Pin);
}

void Led_Write(led_handler_t *hLed, uint8_t data)
{
	hLed->GPIOx->ODR = data;
}



//void Led_Shift (led_handler_t *hLed)
//{
//   GPIO_WritePin(hLed->)
//}

