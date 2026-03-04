#include "uart2.h"
#include <string.h>   // strcpy strncmp strcat ...

#define COMMAND_NUMBER 20
#define COMMAND_LENGTH 40

volatile uint8_t rx_buffer[COMMAND_NUMBER][COMMAND_LENGTH];
volatile int input_index=0;  // rx int에서 사용
volatile int output_index=0; // user prgm에서 사용

extern UART_HandleTypeDef huart2;
extern UART_HandleTypeDef huart1;    // BT
extern uint8_t rx_data;
extern int func_index;
volatile uint8_t bt_data;   //  BT로 부터 1byte의 INT가 들어오면 저장 하는 변수
void pc_command_processing(void);

// 1 byte가 수신 될떄 마다 이곳으로 자동 진입
void HAL_UART_RxCpltCallback(UART_HandleTypeDef *huart)
{
    static int i = 0;
    static int bt_i = 0; // 블루투스용 인덱스

    if (huart == &huart2) // PC 디버깅용
    {
        if (rx_data == '\n' || rx_data == '\r') // \r도 처리하도록 수정
        {
            if (i > 0) // 빈 문장이 아닐 때만
            {
                rx_buffer[input_index][i] = '\0';
                i = 0;
                input_index = (input_index + 1) % COMMAND_NUMBER;
            }
        }
        else if (i < COMMAND_LENGTH - 1)
        {
            rx_buffer[input_index][i++] = rx_data;
        }
        HAL_UART_Receive_IT(&huart2, &rx_data, 1);
    }

    if (huart == &huart1) // 블루투스(수동 모드 제어)
    {
        printf("BT Recv: %c\r\n", bt_data);
        // 블루투스 데이터를 처리하는 로직 추가 (예: bt_data를 이용한 즉시 처리)
        // manual_mode_run()에서 bt_data를 직접 체크한다면 여기서도 인터럽트를 다시 걸어줘야 함
        HAL_UART_Receive_IT(&huart1, (uint8_t *)&bt_data, 1);
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