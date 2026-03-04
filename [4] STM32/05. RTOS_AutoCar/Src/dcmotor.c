#include "main.h"
#include "button.h"
#include "i2c_lcd.h"
#include "cmsis_os.h"

extern TIM_HandleTypeDef htim3;
extern int distances[3];
volatile uint8_t auto_mode_state = 0;
extern volatile uint8_t bt_data;   // 2. BT로 부터 1byte의 INT가 들어오면 저장 하는 변수

void mode_check(void);
void drive_car_main(void);
void auto_drive(void);
void left_forward(void);
void right_forward(void);
void all_forward(void);
void manual_mode_run(void);
void forward(int speed);
void backward(int speed);
void turn_left(int speed);
void turn_right(int speed);
void turn_left_backward(int speed);
void turn_right_backward(int speed);
void stop(void);
void left_speed(uint16_t speed);
void right_speed(uint16_t speed);
void left_stop(void);
void right_stop(void);
void all_backward(void);
void all_stop(void);

/*
* 1. LEFT MOTOR
*    PC6 : IN1
*    PC7 : IN2
* 2. RIGHT MOTOR
*    PC8 : IN3
*    PC9 : IN4
*
*      IN1 IN3    IN2.IN4
*    =========   =========
*        0           0   : 역회전
*        1           0   : 정회전
*        1           1   : 정지
*
*/
void left_forward(void)
{
	HAL_GPIO_WritePin(IN1_GPIO_Port, IN1_Pin, 1);
	HAL_GPIO_WritePin(IN2_GPIO_Port, IN2_Pin, 0);
}

void right_forward(void)
{
	HAL_GPIO_WritePin(IN3_GPIO_Port, IN3_Pin, 1);
	HAL_GPIO_WritePin(IN4_GPIO_Port, IN4_Pin, 0);
}

// void all_forward(void)
// {
// 	left_forward();
// 	right_forward();
// }

void drive_car_main()
{
	mode_check();
	if(auto_mode_state)
	{
		auto_drive();
	}
	else
	{
		manual_mode_run();
	}
}

void mode_check()
{
   static uint8_t button_released = 1; // 버튼이 떨어졌는지 확인하는 상태 변수

   if (get_button(BUTTON0_GPIO_Port, BUTTON0_Pin, BUTTON0) == BUTTON_PRESS)
   {
       if (button_released) // 버튼이 이전에 떨어져 있었을 때만 실행
       {
           stop();
           bt_data = 'S';
           auto_mode_state = !auto_mode_state;

           // LCD 업데이트 로직
           move_cursor(0,0);
           if (auto_mode_state) lcd_string("AUTO Mode       ");
           else lcd_string("Manual Mode     ");

           move_cursor(1,0);
           lcd_string("                ");

           button_released = 0; // 버튼이 눌려있음을 기록 (중복 방지)
       }
   }
   else
   {
       button_released = 1; // 버튼에서 손을 떼면 다시 누를 수 있는 상태로 변경
   }
}

// 자율주행 프로그램을 이곳에 programming 한다.
void auto_drive(void)
{
   // 거리를 cm 단위로 변환 (기존 ultrasonic_main의 로직 참고)
   int distL = distances[0] * 0.034 / 2;
   int distC = distances[1] * 0.034 / 2;
   int distR = distances[2] * 0.034 / 2;

   // 장애물 감지 기준 거리 (cm)
   const int threshold = 10;

   // 1. Center에 장애물이 있을 때
   if (distC > 0 && distC < threshold)
   {
       stop();
       osDelay(200); // 급정지 후 대기

       backward(50); // 50 속도로 후진
       osDelay(500); // 0.5초간 후진

       stop();
       osDelay(200);

		//왼쪽 오른쪽 비교하여 넓은 쪽의 바퀴를 뒤로 후진
		int l_check = (distL <= 0) ? 999 : distL;
		int r_check = (distR <= 0) ? 999 : distR;

		if(l_check > r_check) {
			turn_left_backward(70);
		} else {
			turn_right_backward(70);
		}
       osDelay(400);
		stop();
		osDelay(200);
   }
   // 2. Right에 장애물이 있을 때
   else if (distR > 0 && distR < threshold)
   {
       stop();
       osDelay(100);

       backward(50); // 살짝 후진
       osDelay(300);

       turn_right(70); // 왼쪽으로 꺾기
       osDelay(400);
   }
   // 3. Left에 장애물이 있을 때 (추가 권장 로직)
   else if (distL > 0 && distL < threshold)
   {
       stop();
       osDelay(100);

       backward(50);
       osDelay(300);

       turn_left(70); // 오른쪽으로 꺾기
       osDelay(400);
   }
   // 4. 장애물이 없을 때 (직진)
   else
   {
       forward(50); // 평상시 주행 속도
   }
}

void manual_mode_run(void)
{
	move_cursor(1,0);
	if (bt_data == 'F') lcd_string("Forward    ");
	else if (bt_data == 'B') lcd_string("Backward    ");
	else if (bt_data == 'L') lcd_string("Turn Left    ");
	else if (bt_data == 'R') lcd_string("Turn Right   ");
	else if (bt_data == 'G') lcd_string("Left-Backward   ");
   else if (bt_data == 'H') lcd_string("Right-Backward   ");
	else if (bt_data == 'S') lcd_string("Stop            ");

	if(bt_data == 'A') lcd_string("Switch to AUTO");

	switch(bt_data)
	{
		case 'A':
			stop();
			auto_mode_state  = 1;

			move_cursor(0,0);
			lcd_string("AUTO Mode       ");
			move_cursor(1,0);
			lcd_string("                ");

			bt_data = 'S';
			break;

		case 'F':
			forward(50);
		break;

		case 'B':
			backward(50);
		break;

		case 'L':
			turn_right(60);
		break;

		case 'R':
			turn_left(60);
		break;

		case 'G' ://왼쪽으로 후진(오른쪽 바퀴 뒤로)
		turn_right_backward(60);
		break;

		case 'H' : //오른쪽으로 후진(왼쪽 바퀴 뒤로)
		turn_left_backward(60);
		break;

		case 'S':
			stop();
		break;

		default:
		break;
	}
}

void forward(int speed)
{
	all_forward();

	HAL_TIM_PWM_Start(&htim3, TIM_CHANNEL_1);
	__HAL_TIM_SET_COMPARE(&htim3, TIM_CHANNEL_1, speed);   // left speed

	HAL_TIM_PWM_Start(&htim3, TIM_CHANNEL_2);
	__HAL_TIM_SET_COMPARE(&htim3, TIM_CHANNEL_2, speed);   //  right speed
}

void backward(int speed)
{
	all_backward();

	HAL_TIM_PWM_Start(&htim3, TIM_CHANNEL_1);
	__HAL_TIM_SET_COMPARE(&htim3, TIM_CHANNEL_1, speed);   // left speed

	HAL_TIM_PWM_Start(&htim3, TIM_CHANNEL_2);
	__HAL_TIM_SET_COMPARE(&htim3, TIM_CHANNEL_2, speed);   //  right speed
}

void turn_left(int speed)
{
	all_forward();

	left_speed(speed);
	right_speed(0);   //  PWM 출력 right
}

void turn_right(int speed)
{
	all_forward();

	left_speed(0); //  PWM 출력	  left
	right_speed(speed);    //  PWM 출력 right
}

void stop()
{
	all_stop();

	HAL_GPIO_WritePin(IN1_GPIO_Port, IN1_Pin, GPIO_PIN_SET);
	HAL_GPIO_WritePin(IN2_GPIO_Port, IN2_Pin, GPIO_PIN_SET);

	HAL_GPIO_WritePin(IN3_GPIO_Port, IN3_Pin, GPIO_PIN_SET);
	HAL_GPIO_WritePin(IN4_GPIO_Port, IN4_Pin, GPIO_PIN_SET);
}

void turn_left_backward(int speed)
{
	left_backward();
	right_stop();
	left_speed(speed);
}

void turn_right_backward(int speed)
{
	right_backward();
	left_stop();
	right_speed(speed);
}


void left_speed(uint16_t speed)
{
	if (speed >= 100) speed = 100;
	else if (speed < 0) speed = 0;

	if (speed == 0)
	{
		HAL_TIM_PWM_Stop(&htim3, TIM_CHANNEL_1);
	}
	else
	{
		HAL_TIM_PWM_Start(&htim3, TIM_CHANNEL_1);
		__HAL_TIM_SET_COMPARE(&htim3, TIM_CHANNEL_1, speed);
	}

}

void right_speed(uint16_t speed)
{
	if (speed >= 100) speed = 100;
	else if (speed < 0) speed = 0;

	if (speed == 0)
	{
		HAL_TIM_PWM_Stop(&htim3, TIM_CHANNEL_2);
	}
	else
	{
		HAL_TIM_PWM_Start(&htim3, TIM_CHANNEL_2);
		__HAL_TIM_SET_COMPARE(&htim3, TIM_CHANNEL_2, speed);
	}
}

void all_forward()
{
	 left_forward();
	 right_forward();
}

void left_backward()
{
	HAL_GPIO_WritePin(IN1_GPIO_Port, IN1_Pin, GPIO_PIN_RESET);
	HAL_GPIO_WritePin(IN2_GPIO_Port, IN2_Pin, GPIO_PIN_SET);

}

void right_backward()
{
	HAL_GPIO_WritePin(IN3_GPIO_Port, IN3_Pin, GPIO_PIN_RESET);
	HAL_GPIO_WritePin(IN4_GPIO_Port, IN4_Pin, GPIO_PIN_SET);
}

void all_backward()
{
	left_backward();
	right_backward();
}

void left_stop()
{
	left_speed(0);
}

void right_stop()
{
	right_speed(0);
}

void all_stop()
{
	 left_stop();
	 right_stop();
}


void dcmotor_main(void)
{
	static int PWM_val=0;
	static uint8_t direction=0;   // defult 0 : forward

	all_forward();

	while(1)
	{
		if (get_button(GPIOC, GPIO_PIN_1 , BUTTON1 )  == BUTTON_PRESS)
		{
			if (!direction)
			{
				HAL_GPIO_WritePin(GPIOB, GPIO_PIN_0, 1);
				PWM_val = __HAL_TIM_GET_COMPARE(&htim3, TIM_CHANNEL_1);
				PWM_val += 10;
				if (PWM_val > 100) {
					direction = !direction;
					PWM_val = 100;
				}
				__HAL_TIM_SET_COMPARE(&htim3, TIM_CHANNEL_1, PWM_val);
				__HAL_TIM_SET_COMPARE(&htim3, TIM_CHANNEL_2, PWM_val);

			} else {
				HAL_GPIO_WritePin(GPIOB, GPIO_PIN_0, 0);
				PWM_val = __HAL_TIM_GET_COMPARE(&htim3, TIM_CHANNEL_1);
				PWM_val -= 10;
				if (PWM_val < 0) {
					direction = !direction;
					PWM_val = 0;
				}
				__HAL_TIM_SET_COMPARE(&htim3, TIM_CHANNEL_1, PWM_val);
				__HAL_TIM_SET_COMPARE(&htim3, TIM_CHANNEL_2, PWM_val);
			}
		}
	}
}