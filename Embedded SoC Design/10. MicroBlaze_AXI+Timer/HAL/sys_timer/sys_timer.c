/*
 * sys_timer.c
 *
 *  Created on: 2026. 2. 13.
 *      Author: kccistc
 */

#include "sys_timer.h"

void SysTimer_Init()
{

	SYS_TIMER->PSR = 100000 -1; // prescaler value -> 1ms counting

}


void SysTimer_Start()
{

	SYS_TIMER->CR |= 1<<0;

}


void SysTimer_Stop()
{

	SYS_TIMER->CR &= ~(1<<0);

}

uint32_t SysTimer_GetTick()
{
	return SYS_TIMER->CNT;
}

bool SysTimer_is_elapsed(uint32_t start_tick, uint32_t period_ms)
{
	uint32_t curTime = SysTimer_GetTick();
	uint32_t elapsed_ms = (curTime - start_tick);

	return (elapsed_ms >= period_ms);

}
