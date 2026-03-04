#include "led.h"
#include <stdio.h>
#include <string.h> // strcmp를 사용하기 위해 필요

extern volatile int TIM10_1ms_counter;
extern volatile int TIM10_1ms_ledcnt;
int func_index = -1;

// --- 레지스터 주소 정의 ---
#define GPIOB_ODR     (*(volatile unsigned int *)0x40020414)
#define GPIOC_IDR     (*(volatile unsigned int *)0x40020810)

// USART2 레지스터 정의
#define USART2_SR     (*(volatile unsigned int *)0x40004400)
#define USART2_DR     (*(volatile unsigned int *)0x40004404)

// --- LED 패턴 함수들 (기존과 동일) ---
void led_all_on(void)   { GPIOB_ODR = 0x00FF; }
void led_all_off(void)  { GPIOB_ODR = 0x0000; }
void led_up_on(void)    {
    static int i = 0;
    if (TIM10_1ms_ledcnt >= 100) {
        TIM10_1ms_ledcnt = 0;
        led_all_off();
        GPIOB_ODR = (0x01 << i);
        i = (i + 1) % 8;
    }
}
void led_down_on(void)  {
    static int i = 0;
    if (TIM10_1ms_ledcnt >= 100) {
        TIM10_1ms_ledcnt = 0;
        led_all_off();
        GPIOB_ODR = (0x80 >> i);
        i = (i + 1) % 8;
    }
}
void led_flower_on(void) {
    static int i = 0;
    if (TIM10_1ms_counter >= 100) {
        TIM10_1ms_counter = 0;
        GPIOB_ODR = (0x10 << i | 0x08 >> i);
        i = (i + 1) % 4;
    }
}
void led_flower_off(void) {
    static int i = 0;
    if (TIM10_1ms_counter >= 100) {
        TIM10_1ms_counter = 0;
        GPIOB_ODR = 0x00FF & ~(0x10 << (3-i) | 0x08 >> (3-i));
        i = (i + 1) % 4;
    }
}

void (*funcp[]) () = { led_all_on, led_all_off, led_up_on, led_down_on, led_flower_on, led_flower_off };

// --- UART 명령어 수신 및 처리 함수 ---
void uart_command_check(void)
{
    static char rx_buffer[50]; // 데이터를 쌓아둘 바구니
    static int rx_index = 0;

    // 1. USART2_SR의 5번 비트(RXNE)가 1인지 확인 (데이터 왔니?)
    if (USART2_SR & (0x1 << 5))
    {
        char received_char = (char)(USART2_DR & 0xFF); // 데이터 1바이트 읽기

        // 엔터(\n) 문자가 들어오면 명령어 비교 시작
        if (received_char == '\n' || received_char == '\r')
        {
            rx_buffer[rx_index] = '\0'; // 문자열의 끝 표시

            // 2. 명령어 비교 및 func_index 설정
            if (strcmp(rx_buffer, "led_all_on") == 0)      func_index = 0;
            else if (strcmp(rx_buffer, "led_all_off") == 0) func_index = 1;
            else if (strcmp(rx_buffer, "led_up_on") == 0)   func_index = 2;
            else if (strcmp(rx_buffer, "led_down_on") == 0) func_index = 3;

            rx_index = 0; // 다음 문장을 위해 인덱스 초기화
        }
        else
        {
            // 아직 문장이 안 끝났으면 버퍼에 저장
            if (rx_index < 49)
            {
                rx_buffer[rx_index++] = received_char;
            }
        }
    }
}

// --- 버튼 체크 함수 (기존 유지) ---
void button_check(void)
{
    if (!(GPIOC_IDR & (0x1 << 13)))
    {
        HAL_Delay(20);
        if (!(GPIOC_IDR & (0x1 << 13)))
        {
            func_index++;
            if (func_index > 5) func_index = 0;
            while (!(GPIOC_IDR & (0x1 << 13)));
        }
    }
}

// --- 최종 메인 실행부 ---
void led_main(void)
{
    // 버튼과 UART 명령어를 둘 다 감시합니다.
    button_check();
    uart_command_check();

    if (func_index != -1)
    {
        funcp[func_index]();
    }
}