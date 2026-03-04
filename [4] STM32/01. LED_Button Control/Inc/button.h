#define INC_BTNH

#include "main.h" //STM32 HAL라이브러리와 GPIO_TypeDef, GPIO_PIN_x 같은 타입을 쓰기 위해 필요

#define BUTTON_RELEASE 1 //버튼 안누름: High
#define BUTTON_PRESS 0   //버튼 누름: Low
#define BUTTON_NUMBER 5 //버튼 갯수 정의

#define BUTTON0 0    //portC 0
#define BUTTON1 1    //portC 1
#define BUTTON2 2    //portC 2
#define BUTTON3 3    //portC 3
#define BUTTON4 4    //portC 13 demo B'd


int get_button(GPIO_TypeDef* GPIOx, uint16_t GPIO_Pin, int button_number); //이 함수 때문에 main.h는 반드시 필요
//특정 GPIO 핀에 연결된 버튼의 상태를 판단
//GPIOx: GPIO 포트 구별(GPIOA, GPIOB, GPIOC...)
//GPIO_Pin: 핀 번호(GPIO_Pin_0..)
//button_number: 버튼 인덱스
//uint16_t: 부호 없는 16비트 정수형
//GPIO_TypeDef* GPIOx: 어떤 GPIO 포트를 가리키는 포인터 (하드웨어 레지스터는 반드시 포인터로 접근해야함)
//GPIOx 포트의 GPIO_Pin 핀에 연결된 button_number 번 버튼의 상태를 읽어서 눌렸는지 안눌렸는지 int값으로 반환해라


void button_check(void);
