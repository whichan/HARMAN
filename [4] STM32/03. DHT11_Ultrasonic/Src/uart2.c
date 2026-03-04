#include "uart2.h"
#include <string.h>

#define COMMAND_NUMBER 20   // 최대 저장 가능한 명령어 개수
#define COMMAND_LENGTH 40   // 한 명령어의 최대 길이

extern int func_index;
extern UART_HandleTypeDef huart2;
extern uint8_t rx_data; // main.c에서 선언된 수신용 1바이트 변수

volatile char rx_buffer[COMMAND_NUMBER][COMMAND_LENGTH];
volatile int input_index = 0;   // 인터럽트가 데이터를 넣는 위치
volatile int output_index = 0;  // main 함수가 데이터를 꺼내는 위치

// UART 한 글자 수신 완료 시 자동으로 실행되는 함수 (인터럽트)
void HAL_UART_RxCpltCallback(UART_HandleTypeDef *huart)
{
    static int i = 0;

    if (huart == &huart2)
    {
        // 1. 문장의 끝(\n 또는 \r) 확인
        if (rx_data == '\n' || rx_data == '\r')
        {
            if (i > 0) // 빈 문장이 아닐 때만 저장
            {
                rx_buffer[input_index][i] = '\0'; // 문자열 끝 표시
                i = 0; // 다음 문장을 위해 초기화
                input_index = (input_index + 1) % COMMAND_NUMBER; // 다음 칸으로 이동
            }
        }
        else // 2. 일반 글자라면 버퍼에 저장
        {
            if (i < COMMAND_LENGTH - 1)
            {
                rx_buffer[input_index][i++] = rx_data;
            }
        }
        // 3. 다시 다음 1바이트를 받기 위해 인터럽트 재가동
        HAL_UART_Receive_IT(&huart2, &rx_data, 1);
    }
}

// 쌓여있는 명령어를 꺼내서 분석하는 함수
void pc_command_processing(void)
{
    // input과 output이 다르다면, 처리 안 된 명령어가 쌓여있다는 뜻!
    if (input_index != output_index)
    {
        char *cmd = (char*)rx_buffer[output_index];

        if (strcmp(cmd, "led_all_on") == 0)      func_index = 0;
        else if (strcmp(cmd, "led_all_off") == 0) func_index = 1;
        else if (strcmp(cmd, "led_up_on") == 0)   func_index = 2;
        else if (strcmp(cmd, "led_down_on") == 0) func_index = 3;
        else if (strcmp(cmd, "flower_on") == 0)   func_index = 4;
        else if (strcmp(cmd, "flower_off") == 0)  func_index = 5;

        // 처리가 끝났으니 다음 명령어로 넘겨줌
        output_index = (output_index + 1) % COMMAND_NUMBER;
    }
}