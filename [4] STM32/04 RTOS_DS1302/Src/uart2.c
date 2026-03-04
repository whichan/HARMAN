#include "uart2.h"
#include <string.h>   // strcpy strncmp strcat ...

#define COMMAND_NUMBER 20
#define COMMAND_LENGTH 40

volatile uint8_t rx_buffer[COMMAND_NUMBER][COMMAND_LENGTH];
volatile int input_index=0;  // rx int에서 사용
volatile int output_index=0; // user prgm에서 사용

extern UART_HandleTypeDef huart2;
extern uint8_t rx_data;
extern int func_index;
void pc_command_processing(void);

// 1 byte가 수신 될떄 마다 이곳으로 자동 진입
void HAL_UART_RxCpltCallback(UART_HandleTypeDef *huart)
{
    volatile static int i=0;

	if (huart == &huart2)
	{
		uint8_t data;

		data = rx_data;
		if (data == '\n')
		{
			rx_buffer[input_index][i] = '\0';   // 몬장의 끝을 알리는 null
			i=0;
			input_index++;
			input_index %= COMMAND_NUMBER;
			// 주의: queue overflow 체크 하는 logic을 넣어야 한다.
		}
		else
		{
			rx_buffer[input_index][i++] = data;
		}
		HAL_UART_Receive_IT(&huart2, &rx_data, 1);   // 주의: 반드시 집어 넣어 줘야 다음 INT가 들어 온다.

	}
}


void pc_command_processing(void)
{
	if (input_index != output_index)
	{
		printf("%s\n", rx_buffer[output_index]); // &rx_buffer[output_index][0] 와 동일

		if (strncmp(rx_buffer[output_index], "led_all_on", strlen("led_all_on")) == 0)
		{
			func_index=1;
		}
		else if (strncmp(rx_buffer[output_index], "led_all_off", strlen("led_all_off")) == 0)
		{
			func_index=2;
		}
		output_index++;
		output_index %= COMMAND_NUMBER;
		// 주의: queue full check logic missing
	}
}
