#include "button.h" //button.h에서 선언한 것들을 이 c파일에서 사용하겠다

unsigned char button_status[BUTTON_NUMBER] = {
      BUTTON_RELEASE, BUTTON_RELEASE, BUTTON_RELEASE, BUTTON_RELEASE, BUTTON_RELEASE
};

void button_check(void)
{
   //버튼을 1번 눌렀다 떼는지 체크
   if(get_button(GPIOC, GPIO_PIN_0, BUTTON0) == BUTTON_PRESS )
	   //get_button 함수에서 1을 반환하면 1==0 이기 때문에 거짓
   {
      HAL_GPIO_TogglePin(GPIOB, GPIO_PIN_0); //만약 BUTTON0이 눌렸으면 LED0 토글
   }
   else if(get_button(GPIOC, GPIO_PIN_1, BUTTON1) == BUTTON_PRESS )
   {
      HAL_GPIO_TogglePin(GPIOB, GPIO_PIN_1);
   }
   else if(get_button(GPIOC, GPIO_PIN_2, BUTTON2) == BUTTON_PRESS )
   {
      HAL_GPIO_TogglePin(GPIOB, GPIO_PIN_2);
   }
   else if(get_button(GPIOC, GPIO_PIN_3, BUTTON3) == BUTTON_PRESS )
   {
      HAL_GPIO_TogglePin(GPIOB, GPIO_PIN_3);
   }
   else if(get_button(GPIOC, GPIO_PIN_13, BUTTON4) == BUTTON_PRESS )
   {
      HAL_GPIO_TogglePin(GPIOB, GPIO_PIN_5);
   }
}
//GPIOC의 PIN 0에 연결된 BUTTON0이 '눌렀다 떼어진 상태'이면 GPIOB의 PIN0(LED0)을 토글해라
//get_button()이 '한 번 눌렀다 떼었냐'를 판단함



//int get_button(GPIO_TypeDef* GPIOx, uint16_t GPIO_Pin , int button_number)
//{
//   int state;
//   state = HAL_GPIO_ReadPin(GPIOx, GPIO_Pin);
//   //
//   // 눌렸는지 return BUTTON_PRESS
//   if(state == BUTTON_PRESS && button_status[button_number] == BUTTON_RELEASE)
//   {
//      HAL_Delay(20);
//      button_status[button_number] = BUTTON_PRESS;
//      return BUTTON_RELEASE;
//   }
//   else if (state == BUTTON_RELEASE && button_status[button_number] == BUTTON_PRESS)
//   {
//      HAL_Delay(20); //노이즈가 지나가기를 기다린다.
//      button_status[button_number] = BUTTON_RELEASE; //다음 버튼을 체크하기 위해 초기화
//      return BUTTON_PRESS; //완전히 1번 눌렀다 뗀 것으로 인정
//   }
//
//   return BUTTON_RELEASE;
//}

int get_button(GPIO_TypeDef* GPIOx, uint16_t GPIO_Pin , int button_number)
{
   int state = HAL_GPIO_ReadPin(GPIOx, GPIO_Pin);
   //GPIOx 포트의 GPIO_Pin 핀에 지금 걸려 있는 전압 상태를 읽어서 state에 저장해라
   //ex) GPIOC1(BUTTON1)은 0V이기 때문에 켜져있는 상태
   //state 0: 눌림
   //state 1: 안눌림

   if(state == BUTTON_PRESS && button_status[button_number] == BUTTON_RELEASE)
   {  //만약 지금은 눌려 있는데 이전에는 안 눌려 있었으면
      HAL_Delay(20); //노이즈 대기
      button_status[button_number] = BUTTON_PRESS; //상태 저장: 지금부터는 눌린 상태로 기억
      return BUTTON_RELEASE; //button_release 반환. 아직 눌렀다 뗀거 아님
   }

   //버튼 떼짐 감지(Release 순간)
   else if (state == BUTTON_RELEASE && button_status[button_number] == BUTTON_PRESS)
   {
	  //만약 지금은 안 눌려 있고 이전에는 눌려 있었으면 눌렀다가 방금 떼었다는 것으로 판단
      HAL_Delay(20);
      button_status[button_number] = BUTTON_RELEASE;
      return BUTTON_PRESS;
   }

   return BUTTON_RELEASE; //그 외의 경우 아무 변화 없음
}
