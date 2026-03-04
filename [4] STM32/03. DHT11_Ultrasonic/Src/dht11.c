// // #include "main.h"
// // #include <stdio.h>

// // // 마이크로초 단위 지연 함수 (외부 정의 필요)
// // extern void delay_us(unsigned int us);

// // // DHT11 핀을 출력 모드로 설정
// // void dht11_output(void) {
// //     GPIO_InitTypeDef GPIO_InitStruct = {0};
// //     GPIO_InitStruct.Pin = DHT11_Pin;
// //     GPIO_InitStruct.Mode = GPIO_MODE_OUTPUT_PP; // MCU가 신호를 내보냄
// //     GPIO_InitStruct.Pull = GPIO_NOPULL;
// //     GPIO_InitStruct.Speed = GPIO_SPEED_FREQ_LOW;
// //     HAL_GPIO_Init(DHT11_GPIO_Port, &GPIO_InitStruct);    
// // }

// // // DHT11 핀을 입력 모드로 설정
// // void dht11_input(void) {
// //     GPIO_InitTypeDef GPIO_InitStruct = {0};
// //     GPIO_InitStruct.Pin = DHT11_Pin;
// //     GPIO_InitStruct.Mode = GPIO_MODE_INPUT;     // 센서 신호를 읽음
// //     GPIO_InitStruct.Pull = GPIO_NOPULL;         // 외부 풀업 저항 사용 권장 [cite: 136]
// //     HAL_GPIO_Init(DHT11_GPIO_Port, &GPIO_InitStruct);    
// // }

// // void dht11_main(void) {
// //     uint8_t data[5] = {0}; // 40비트 데이터를 저장할 공간 (5바이트) [cite: 10]
// //     uint8_t check_sum = 0;

// //     while(1) {
// //         // 1. 시작 신호 보내기 (Start Signal) [cite: 356]
// //         dht11_output();
// //         HAL_GPIO_WritePin(DHT11_GPIO_Port, DHT11_Pin, 0); // LOW로 떨어뜨림
// //         HAL_Delay(18);                                    // 최소 18ms 대기 [cite: 184, 364]
// //         HAL_GPIO_WritePin(DHT11_GPIO_Port, DHT11_Pin, 1); // 다시 HIGH로 올림
// //         delay_us(30);                                     // 20~40us 대기 후 입력 전환 [cite: 358]

// //         // 2. 센서 응답 확인 (Response) [cite: 372]
// //         dht11_input();
        
// //         // 센서가 LOW 80us를 보내는지 확인 [cite: 373]
// //         while(HAL_GPIO_ReadPin(DHT11_GPIO_Port, DHT11_Pin) == 1); 
// //         delay_us(80);
        
// //         // 센서가 HIGH 80us를 보내는지 확인 [cite: 374]
// //         while(HAL_GPIO_ReadPin(DHT11_GPIO_Port, DHT11_Pin) == 0); 
// //         delay_us(80);

// //         // 3. 40비트 데이터 읽기 [cite: 377]
// //         for (int i = 0; i < 5; i++) {       // 5바이트 반복
// //             for (int j = 0; j < 8; j++) {   // 각 바이트의 8비트 반복
// //                 // 비트의 시작인 LOW(50us)가 끝날 때까지 대기 [cite: 202]
// //                 while(HAL_GPIO_ReadPin(DHT11_GPIO_Port, DHT11_Pin) == 0);
                
// //                 // HIGH 구간 진입! 40us 뒤에 상태를 확인하여 0/1 판별
// //                 // 26~28us(0)와 70us(1)의 중간인 40us를 사용 [cite: 28, 32]
// //                 delay_us(40);
                
// //                 if (HAL_GPIO_ReadPin(DHT11_GPIO_Port, DHT11_Pin) == 1) {
// //                     data[i] = (data[i] << 1) | 1; // 여전히 HIGH면 비트 '1' [cite: 32]
// //                     // 다음 비트 준비를 위해 HIGH가 끝날 때까지 대기
// //                     while(HAL_GPIO_ReadPin(DHT11_GPIO_Port, DHT11_Pin) == 1);
// //                 } else {
// //                     data[i] = (data[i] << 1);      // 이미 LOW면 비트 '0' [cite: 28]
// //                 }
// //             }
// //         }

// //         // 4. 체크섬 계산 및 출력 [cite: 18, 325]
// //         // 앞의 4바이트 합의 하위 8비트가 체크섬과 같아야 함 [cite: 147]
// //         check_sum = data[0] + data[1] + data[2] + data[3];

// //         if (data[4] == check_sum) {
// //             // ComportMaster 출력 형식 준수
// //             printf("[TEMP]: %d.%dC\n", data[2], data[3]);
// //             printf("[HUMI]: %d.%d%%\n", data[0], data[1]);
// //         } else {
// //             printf("Checksum Error! (Calc:%d, Recv:%d)\n", check_sum, data[4]);
// //         }

// //         // 5. 샘플링 간격 유지 (최소 1초 이상 권장) 
// //         HAL_Delay(2000); 
// //     }
// // }

// #include "main.h"
// #include <stdio.h>

// extern void delay_us(uint16_t us);

// #define DHT_TIMEOUT 100  // us 단위 타임아웃

// void dht11_output(void)
// {
//     GPIO_InitTypeDef GPIO_InitStruct = {0};
//     GPIO_InitStruct.Pin = DHT11_Pin;
//     GPIO_InitStruct.Mode = GPIO_MODE_OUTPUT_PP;
//     GPIO_InitStruct.Pull = GPIO_PULLUP;   // 중요!
//     GPIO_InitStruct.Speed = GPIO_SPEED_FREQ_LOW;
//     HAL_GPIO_Init(DHT11_GPIO_Port, &GPIO_InitStruct);
// }

// void dht11_input(void)
// {
//     GPIO_InitTypeDef GPIO_InitStruct = {0};
//     GPIO_InitStruct.Pin = DHT11_Pin;
//     GPIO_InitStruct.Mode = GPIO_MODE_INPUT;
//     GPIO_InitStruct.Pull = GPIO_PULLUP;   // 중요!
//     HAL_GPIO_Init(DHT11_GPIO_Port, &GPIO_InitStruct);
// }

// uint8_t wait_for_pin(GPIO_PinState state, uint16_t timeout_us)
// {
//     while (HAL_GPIO_ReadPin(DHT11_GPIO_Port, DHT11_Pin) != state) {
//         delay_us(1);
//         if (--timeout_us == 0) return 0;
//     }
//     return 1;
// }

// void dht11_main(void)
// {
//     uint8_t data[5];

//     while (1)
//     {
//         for (int i = 0; i < 5; i++) data[i] = 0;

//         /* Start Signal */
//         dht11_output();
//         HAL_GPIO_WritePin(DHT11_GPIO_Port, DHT11_Pin, GPIO_PIN_RESET);
//         HAL_Delay(18);
//         HAL_GPIO_WritePin(DHT11_GPIO_Port, DHT11_Pin, GPIO_PIN_SET);
//         delay_us(30);

//         dht11_input();

//         /* Response */
//         if (!wait_for_pin(GPIO_PIN_RESET, DHT_TIMEOUT) ||
//             !wait_for_pin(GPIO_PIN_SET,   DHT_TIMEOUT)) {
//             printf("DHT11 No Response\r\n");
//             goto retry;
//         }

//         /* Read 40 bits */
//         for (int i = 0; i < 5; i++) {
//             for (int j = 0; j < 8; j++) {

//                 if (!wait_for_pin(GPIO_PIN_SET, DHT_TIMEOUT)) {
//                     printf("Bit timeout\r\n");
//                     goto retry;
//                 }

//                 delay_us(40);

//                 data[i] <<= 1;
//                 if (HAL_GPIO_ReadPin(DHT11_GPIO_Port, DHT11_Pin) == GPIO_PIN_SET) {
//                     data[i] |= 1;
//                 }

//                 if (!wait_for_pin(GPIO_PIN_RESET, DHT_TIMEOUT)) {
//                     printf("Bit end timeout\r\n");
//                     goto retry;
//                 }
//             }
//         }

//         /* Checksum */
//         uint8_t checksum = (data[0] + data[1] + data[2] + data[3]) & 0xFF;

//         if (checksum == data[4]) {
//             printf("[TEMP] %d.%d C\r\n", data[2], data[3]);
//             printf("[HUMI] %d.%d %%\r\n", data[0], data[1]);
//         } else {
//             printf("Checksum Error (%d / %d)\r\n", checksum, data[4]);
//         }

//     retry:
//         HAL_Delay(2000);
//     }
// }

#include "main.h"
#include <stdio.h> //printf. gets, fgets
#include <stdlib.h>
#include <string.h>

extern void delay_us(unsigned int us);

void dht11_output(void)
{
  GPIO_InitTypeDef GPIO_InitStruct = {0};

  GPIO_InitStruct.Pin = DHT11_Pin;
  GPIO_InitStruct.Mode = GPIO_MODE_OUTPUT_PP;
  GPIO_InitStruct.Pull = GPIO_NOPULL;
  GPIO_InitStruct.Speed = GPIO_SPEED_FREQ_LOW;
  HAL_GPIO_Init(DHT11_GPIO_Port, &GPIO_InitStruct);
}

void dht11_input(void)
{
  GPIO_InitTypeDef GPIO_InitStruct = {0};

  GPIO_InitStruct.Pin = DHT11_Pin;
  GPIO_InitStruct.Mode = GPIO_MODE_INPUT;
  GPIO_InitStruct.Pull = GPIO_PULLUP;
  GPIO_InitStruct.Speed = GPIO_SPEED_FREQ_LOW;
  HAL_GPIO_Init(DHT11_GPIO_Port, &GPIO_InitStruct);
}

void dht11_main(void)
{
	enum state_t {OK, TIME_OUT, VALUE_ERROR, TRANS_ERROR};
	enum state_t state = OK;
	uint32_t us_counter = 0;

	int data[6] = {0};

	while(1)
	{
		for(int i=0; i<6; i++)
			data[i] = 0;
		state = OK;
		//======request signal======
		dht11_output();
		HAL_GPIO_WritePin(DHT11_GPIO_Port, DHT11_Pin, 0);
		HAL_Delay(20);

		HAL_GPIO_WritePin(DHT11_GPIO_Port, DHT11_Pin, 1);
		delay_us(30);
		dht11_input();

		us_counter = 0;
		while (HAL_GPIO_ReadPin(DHT11_GPIO_Port,DHT11_Pin)==1)
		{
			delay_us(2);
			us_counter += 2;
			if(us_counter > 50)
			{
				state = TIME_OUT;
				break;
			}
		}
		//---------- response start signal from DHT11-----
		if(state == OK)
		{
			us_counter = 0;
			while (HAL_GPIO_ReadPin(DHT11_GPIO_Port,DHT11_Pin)==0)
				{
					delay_us(2);
					us_counter += 2;
					if(us_counter > 100)
					{
						state = TIME_OUT;
						break;
					}
				}
		}

		if(state == OK)
		{
			us_counter = 0;
			while (HAL_GPIO_ReadPin(DHT11_GPIO_Port,DHT11_Pin)==1)
				{
					delay_us(2);
					us_counter += 2;
					if(us_counter > 100)
					{
						state = TIME_OUT;
						break;
					}
				}
		}

		//----data read port -----
		//---- data read port (총 40비트 = 5바이트 읽기) -----
		        if(state == OK)
		        {
		            // 5바이트를 순서대로 읽습니다. (습도상위, 습도하위, 온도상위, 온도하위, 체크섬)
		            for(int i = 0; i < 5; i++)
		            {
		                for(int j = 0; j < 8; j++) // 8비트 반복 (한 바이트 만들기)
		                {
		                    // [1단계] 50us 동안의 Low 신호 지나가기 (비트 시작 알림)
		                    // Low인 동안은 그냥 기다립니다.
		                    us_counter = 0;
		                    while (HAL_GPIO_ReadPin(DHT11_GPIO_Port, DHT11_Pin) == 0)
		                    {
		                        delay_us(1);
		                        us_counter++;
		                        if(us_counter > 100) { state = TIME_OUT; break; }
		                    }

		                    // [2단계] High 신호가 얼마나 유지되는지 시간 재기
		                    // 이게 짧으면(26~28us) '0', 길면(70us) '1' 입니다.
		                    us_counter = 0;
		                    while (HAL_GPIO_ReadPin(DHT11_GPIO_Port, DHT11_Pin) == 1)
		                    {
		                        delay_us(1);
		                        us_counter++;
		                        if(us_counter > 100) { state = TIME_OUT; break; }
		                    }

		                    // [3단계] 0인지 1인지 판별해서 저장하기
		                    // (1) 일단 기존 데이터를 왼쪽으로 한 칸 밉니다. (빈칸 만들기)
		                    data[i] = data[i] << 1;

		                    // (2) 만약 High 시간이 45us보다 길었다면 '1'이므로 1을 더해줍니다.
		                    if(us_counter > 30)
		                    {
		                        data[i] = data[i] | 1;
		                    }
		                    // 짧았다면 '0'인데, 위에서 밀기만 했으므로 자동으로 끝자리는 0이 됩니다.
		                }
		            }
		        }

		        // 결과 출력하기 (체크섬 확인)
		        if(state == OK)
		        {
		            // 5번째 바이트(체크섬)가 앞의 4개 합과 같은지 확인
		            uint8_t check_sum = data[0] + data[1] + data[2] + data[3];

		            if(data[4] == check_sum)
		            {
		                printf("Humidity: %d.%d %% | Temp: %d.%d C\r\n", data[0], data[1], data[2], data[3]);
		            }
		            else
		            {
		                printf("Error: Checksum mismatch!\r\n");
		            }
		        }
		        else
		        {
		            printf("Error: Sensor Time out\r\n");
		        }

		HAL_Delay(2000); // 안정화 시간
}
}
