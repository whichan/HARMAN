/*
 * fnd.h
 *
 *  Created on: 2026. 2. 15.
 *      Author: kccistc
 */

#ifndef SRC_HAL_FND_FND_H_
#define SRC_HAL_FND_FND_H_

#include <stdint.h>
#include "xparameters.h"

typedef struct{
	volatile uint32_t CR;
	volatile uint32_t COM;
	volatile uint32_t SEG_1;
	volatile uint32_t SEG_2;
	volatile uint32_t SEG_3;
	volatile uint32_t SEG_4;
}FND_TypeDef;

#define FND_BASEADDR XPAR_FND_0_S00_AXI_BASEADDR //0x44A0_0000
#define FND 	((FND_TypeDef *)FND_BASEADDR)

void FND_Init();
void FND_SetNumber(int number);
void FND_Scan();

#endif /* SRC_HAL_FND_FND_H_ */
