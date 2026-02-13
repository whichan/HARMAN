/*
 * sys_timer.h
 *
 *  Created on: 2026. 2. 13.
 *      Author: kccistc
 */

#ifndef SRC_HAL_SYS_TIMER_SYS_TIMER_H_
#define SRC_HAL_SYS_TIMER_SYS_TIMER_H_


#include <stdint.h>
#include <stdbool.h>
#include "xparameters.h"

typedef struct{
	volatile uint32_t CR;
	volatile uint32_t PSR;
	volatile uint32_t CNT;
}SysTimer_TypeDef;

#define SYS_TIMER_BASEADDR XPAR_TIMER_0_S00_AXI_BASEADDR //0x44A20000
#define SYS_TIMER 		   ((SysTimer_TypeDef *)SYS_TIMER_BASEADDR) // ((sys_timer_TypeDef *)0x44A20000)
void SysTimer_Init();
void SysTimer_Start();
void SysTimer_Stop();
uint32_t SysTimer_GetTick();
bool SysTimer_is_elapsed(uint32_t start_tick, uint32_t period_ms);

#endif /* SRC_HAL_SYS_TIMER_SYS_TIMER_H_ */
