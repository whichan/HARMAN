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

#define SYS_TIMER0_BASEADDR XPAR_TIMER_0_S00_AXI_BASEADDR //0x44A30000
#define SYS_TIMER1_BASEADDR XPAR_TIMER_1_S00_AXI_BASEADDR //0x44A40000

#define SYS_TIMER0 		   ((SysTimer_TypeDef *)SYS_TIMER0_BASEADDR) // ((SysTimer_TypeDef *)0x44A30000)
#define SYS_TIMER1 		   ((SysTimer_TypeDef *)SYS_TIMER1_BASEADDR) // ((SysTimer_TypeDef *)0x44A40000)


void SysTimer_Init(int id);
void SysTimer_Start(int id);
void SysTimer_Stop(int id);
void SysTimer_Reset(int id);
uint32_t SysTimer_GetTick(int id);
bool SysTimer_is_elapsed(int id, uint32_t start_tick, uint32_t period_ms);
void SysTimer_Delay(uint32_t ms);


#endif /* SRC_HAL_SYS_TIMER_SYS_TIMER_H_ */
