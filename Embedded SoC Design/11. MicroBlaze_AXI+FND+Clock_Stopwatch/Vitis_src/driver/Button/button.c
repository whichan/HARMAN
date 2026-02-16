#include "button.h"
#include "sleep.h"

void Button_Init(button_handler_t *hBtn, GPIO_TypeDef *GPIOx, uint32_t GPIO_Pin)
{
    hBtn->GPIOx = GPIOx;
    hBtn->GPIO_Pin = GPIO_Pin;
    hBtn->prevButtonState = RELEASED;
    GPIO_Init(hBtn->GPIOx, hBtn->GPIO_Pin, INPUT_MODE);
}

int Button_GetState(button_handler_t *hBtn)
{
    button_state_t curButtonState = GPIO_ReadPin(hBtn->GPIOx, hBtn->GPIO_Pin);


    if((curButtonState == PUSHED) && (hBtn->prevButtonState == RELEASED))
    {
        usleep(10000);
        hBtn->prevButtonState = PUSHED;
        return ACT_PUSHED;
    }
    else if((curButtonState == RELEASED) && (hBtn->prevButtonState == PUSHED))
    {
        usleep(10000);
        hBtn->prevButtonState = RELEASED;
        return ACT_RELEASED;
    }

    return NO_ACT;
}
