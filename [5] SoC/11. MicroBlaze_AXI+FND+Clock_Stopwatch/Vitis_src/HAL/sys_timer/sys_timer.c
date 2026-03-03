/*
 * sys_timer.c
 *
 *  Created on: 2026. 2. 13.
 *      Author: kccistc
 */

#include "sys_timer.h"
#include "sleep.h"

//id=0: 시계(TIMER0)
//id-1: 스톱워치(TIMER1)
void SysTimer_Init(int id)
{
	if(id==0) {
	SYS_TIMER0 -> PSR = 100000-1; //1ms
	SYS_TIMER0 -> CNT = 0;
	}
	else {
		SYS_TIMER1 -> PSR = 100000-1;
		SYS_TIMER1 -> CNT = 0;
	}
}

void SysTimer_Start(int id)
{
	if(id==0) {
		SYS_TIMER0->CR |= 1<<0;
	}
	else {
	SYS_TIMER1->CR |= 1<<0;
	}
}

void SysTimer_Stop(int id)
{
	if(id==0) {
	SYS_TIMER0->CR &= ~(1<<0);
	} else {
		SYS_TIMER1->CR &= ~(1<<0);
	}
}

void SysTimer_Reset(int id)
{
    if (id == 0) {
        SYS_TIMER0->CNT = 0;
    }
    else {
        SYS_TIMER1->CNT = 0;
    }
}

//현재 시간값 읽기
uint32_t SysTimer_GetTick(int id)
{
	if(id==0) {
	return SYS_TIMER0->CNT;
	}
	else {
		return SYS_TIMER1->CNT;
	}
}

//시간 경과 확인
bool SysTimer_is_elapsed(int id, uint32_t start_tick, uint32_t period_ms) //period_ms: 얼마나 기다릴 것인지 목표치
{
	uint32_t curTime = SysTimer_GetTick(id); //curTime은 CNT값
	uint32_t elapsed_ms = (curTime - start_tick); //현재시간-시작시간을 빼서 실제로 흐른시간 계산
	return (elapsed_ms >= period_ms); //계산된 시간이 목표치보다 크거나 같으면 return
}

//fnd 스캐닝 및 debounce용 delay
void SysTimer_Delay(uint32_t ms)
{
	usleep(ms*1000); //1ms = 1000us
}
