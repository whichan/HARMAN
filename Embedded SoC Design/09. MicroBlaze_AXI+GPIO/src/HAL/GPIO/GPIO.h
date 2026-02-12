/*
 * GPIO.H
 *
 *  Created on: 2026. 2. 12.
 *      Author: kccistc
 */

#ifndef SRC_HAL_GPIO_GPIO_H_
#define SRC_HAL_GPIO_GPIO_H_

#include <stdint.h>
#include "xparameters.h"

typedef struct {
volatile uint32_t MODER;
volatile uint32_t IDR;
volatile uint32_t ODR;
}GPIO_TypeDef;

#define GPIOA_BASEADDR  XPAR_GPIO_0_S00_AXI_BASEADDR
#define GPIOB_BASEADDR  XPAR_GPIO_1_S00_AXI_BASEADDR
#define GPIOC_BASEADDR  XPAR_GPIO_2_S00_AXI_BASEADDR

#define GPIOA  ((GPIO_TypeDef *)GPIOA_BASEADDR)
#define GPIOB  ((GPIO_TypeDef *)GPIOB_BASEADDR)
#define GPIOC  ((GPIO_TypeDef *)GPIOC_BASEADDR)

typedef enum {
	INPUT_MODE = 0,
   OUTPUT_MODE}
 gpio_dir_t;

 typedef enum {
	 LOW = 0,
    HIGH}
  gpio_level_t;

  void GPIO_Init(GPIO_TypeDef *GPIOx, uint32_t GPIO_Pin, uint32_t direction);
  void GPIO_WritePin(GPIO_TypeDef *GPIOx, uint32_t GPIO_Pin, gpio_level_t level);
  gpio_level_t GPIO_ReadPin(GPIO_TypeDef *GPIOx, uint32_t GPIO_Pin);
  void GPIO_TogglePin(GPIO_TypeDef *GPIOx, uint32_t GPIO_Pin);

#endif /* SRC_HAL_GPIO_GPIO_H_ */
