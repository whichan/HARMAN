/*
 * button.h
 *
 *  Created on: Jan 9, 2026
 *      Author: user
 */
#include "main.h"    // for GPIO HAL

#define BUTTON_RELEASE 1
#define BUTTON_PRESS   0

#define BUTTON_NUMBER  5

#define BUTTON0   0   // PC0
#define BUTTON1   1   // PC1
#define BUTTON2   2   // PC2
#define BUTTON3   3   // PC3
#define BUTTON4   4   // PC13   demo B'd

int get_button(GPIO_TypeDef* GPIOx, uint16_t GPIO_Pin, int button_number);
void button_check(void);
