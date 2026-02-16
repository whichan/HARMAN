/*
 * fnd.c
 *
 *  Created on: 2026. 2. 15.
 *      Author: kccistc
 */


#include "fnd.h"
#include "../sys_timer/sys_timer.h"

void FND_Init()
{
	FND -> SEG_1 = 0;
	FND -> SEG_2 = 0;
	FND -> SEG_3 = 0;
	FND -> SEG_4 = 0;
	FND -> COM = 0xf; //com을 모두 1로 -> 화면꺼짐
}

void FND_SetNumber(int number)
{
	if (number > 9999) number=9999;
	if(number<0) number=0;

	FND -> SEG_1 = number % 10;
	FND -> SEG_2 = (number/10)%10;
	FND -> SEG_3 = (number/100)%10;
	FND -> SEG_4 = (number/1000)%10;
}

void FND_Scan() //잔상효과
{
	FND -> COM = 0xE; //1110
	SysTimer_Delay(2); //2ms 대기
	FND -> COM = 0xD; //1101
	SysTimer_Delay(2); //2ms 대기
	FND -> COM = 0xB; //1011
	SysTimer_Delay(2); //2ms 대기
	FND -> COM = 0x7; //0111
	SysTimer_Delay(2); //2ms 대기
}


