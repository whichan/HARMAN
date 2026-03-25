#include "main.h"
#include <stdio.h>    // ← 추가 (sprintf용)
#include <string.h>   // ← 추가 (strlen용)
SPI_HandleTypeDef hspi2;
TIM_HandleTypeDef htim1;
UART_HandleTypeDef huart2;

/* USER CODE BEGIN PV */
volatile uint16_t spi_rx_word = 0;
volatile uint16_t rx_data[2] = {0, 0};
volatile uint8_t rx_index = 0;
volatile uint8_t frame_complete = 0;

volatile uint16_t target_x = 160;
volatile uint16_t target_y = 120;
volatile uint8_t target_valid = 0;

volatile uint16_t pulse_x = 1500;
volatile uint16_t pulse_y = 1500;

// ── 이동평균 필터
#define MA_SIZE 5  // 클수록 더 부드럽지만 반응이 느려짐
typedef struct {
    float buf[MA_SIZE];
    uint8_t idx;
    float sum;
} MovAvg_t;

MovAvg_t ma_x = {0};
MovAvg_t ma_y = {0};

float MovAvg_Update(MovAvg_t *f, float new_val) {
    f->sum -= f->buf[f->idx];       // 오래된 값 뺌
    f->buf[f->idx] = new_val;
    f->sum += new_val;              // 새 값 더함
    f->idx = (f->idx + 1) % MA_SIZE;
    return f->sum / MA_SIZE; //최근 5개 평균
}

// ── 저역통과 필터 (LPF)
// alpha: 0.0(변화 없음) ~ 1.0(필터 없음)
// 0.2~0.4가 적당
#define LPF_ALPHA 0.3f

float lpf_x = 160.0f;
float lpf_y = 120.0f;

// ── PID ──────────────────────────────────────
typedef struct {
    float Kp, Ki, Kd;
    float prev_error;
    float integral;
    float integral_limit;
} PID_t;

PID_t pid_x = {
    .Kp = 1.2f, .Ki = 0.01f, .Kd = 0.3f,
    .prev_error = 0.0f, .integral = 0.0f, .integral_limit = 100.0f
};
PID_t pid_y = {
    .Kp = 0.85f, .Ki = 0.01f, .Kd = 0.3f,
    .prev_error = 0.0f, .integral = 0.0f, .integral_limit = 100.0f
};
/* USER CODE END PV */

void SystemClock_Config(void);
static void MX_GPIO_Init(void);
static void MX_USART2_UART_Init(void);
static void MX_SPI2_Init(void);
static void MX_TIM1_Init(void);

/* USER CODE BEGIN 0 */
float PID_Compute(PID_t *pid, float error) {
    float p = pid->Kp * error;
    pid->integral += error;
    if (pid->integral >  pid->integral_limit) pid->integral =  pid->integral_limit;
    if (pid->integral < -pid->integral_limit) pid->integral = -pid->integral_limit;
    float i = pid->Ki * pid->integral;
    float d = pid->Kd * (error - pid->prev_error);
    pid->prev_error = error;
    return p + i + d;
}
/* USER CODE END 0 */

int main(void)
{
  HAL_Init();
  SystemClock_Config();
  MX_GPIO_Init();
  MX_USART2_UART_Init();
  MX_SPI2_Init();
  MX_TIM1_Init();

  HAL_TIM_PWM_Start(&htim1, TIM_CHANNEL_1);
  HAL_TIM_PWM_Start(&htim1, TIM_CHANNEL_2);
  __HAL_TIM_SET_COMPARE(&htim1, TIM_CHANNEL_1, 1500);
  __HAL_TIM_SET_COMPARE(&htim1, TIM_CHANNEL_2, 1500);

  HAL_SPI_Receive_IT(&hspi2, (uint8_t*)&spi_rx_word, 1);

  while (1) {
    if (frame_complete) {
        frame_complete = 0;

        char buf[50];
            sprintf(buf, "rx[0]=%d rx[1]=%d\r\n", rx_data[0], rx_data[1]);
            HAL_UART_Transmit(&huart2, (uint8_t*)buf, strlen(buf), 10);

        target_x     = rx_data[0] & 0x01FF;
        target_valid = (rx_data[1] >> 8) & 0x01;
        target_y     = rx_data[1] & 0x00FF;

        if (target_valid) {
            // 1) 이동평균으로 튀는 값 1차 완화
            float ma_out_x = MovAvg_Update(&ma_x, (float)target_x);
            float ma_out_y = MovAvg_Update(&ma_y, (float)target_y);

            // 2)LPF로 2차 부드럽게

            lpf_x = LPF_ALPHA * ma_out_x + (1.0f - LPF_ALPHA) * lpf_x;
            lpf_y = LPF_ALPHA * ma_out_y + (1.0f - LPF_ALPHA) * lpf_y;

            // ── STEP 3: 필터된 좌표로 PID 연산 ────────
            float error_x = 160.0f - lpf_x;
            float error_y = 120.0f - lpf_y;

            float output_x = PID_Compute(&pid_x, error_x);
            float output_y = PID_Compute(&pid_y, error_y);

            // ── STEP 4: 펄스 계산 + 리미터 ────────────
            pulse_x = (uint16_t)(1500.0f + output_x * (333.0f / 160.0f));
            pulse_y = (uint16_t)(1500.0f + output_y * (333.0f / 120.0f));

            if (pulse_x > 2000) pulse_x = 2000;
            if (pulse_x < 1000) pulse_x = 1000;
            if (pulse_y > 2000) pulse_y = 2000;
            if (pulse_y < 1000) pulse_y = 1000;

            __HAL_TIM_SET_COMPARE(&htim1, TIM_CHANNEL_1, pulse_x);
            __HAL_TIM_SET_COMPARE(&htim1, TIM_CHANNEL_2, pulse_y);

        } else {
            pid_x.integral = 0.0f;
            pid_y.integral = 0.0f;
            // LPF도 서서히 중앙으로 복귀
            lpf_x = LPF_ALPHA * 160.0f + (1.0f - LPF_ALPHA) * lpf_x;
            lpf_y = LPF_ALPHA * 120.0f + (1.0f - LPF_ALPHA) * lpf_y;
        }
    }
  }
}

// ... 이하 SystemClock_Config, MX_*_Init, 콜백 함수들은 동일
void SystemClock_Config(void)
{
  RCC_OscInitTypeDef RCC_OscInitStruct = {0};
  RCC_ClkInitTypeDef RCC_ClkInitStruct = {0};
  __HAL_RCC_PWR_CLK_ENABLE();
  __HAL_PWR_VOLTAGESCALING_CONFIG(PWR_REGULATOR_VOLTAGE_SCALE1);
  RCC_OscInitStruct.OscillatorType = RCC_OSCILLATORTYPE_HSI;
  RCC_OscInitStruct.HSIState = RCC_HSI_ON;
  RCC_OscInitStruct.HSICalibrationValue = RCC_HSICALIBRATION_DEFAULT;
  RCC_OscInitStruct.PLL.PLLState = RCC_PLL_ON;
  RCC_OscInitStruct.PLL.PLLSource = RCC_PLLSOURCE_HSI;
  RCC_OscInitStruct.PLL.PLLM = 8;
  RCC_OscInitStruct.PLL.PLLN = 100;
  RCC_OscInitStruct.PLL.PLLP = RCC_PLLP_DIV2;
  RCC_OscInitStruct.PLL.PLLQ = 4;
  if (HAL_RCC_OscConfig(&RCC_OscInitStruct) != HAL_OK) Error_Handler();
  RCC_ClkInitStruct.ClockType = RCC_CLOCKTYPE_HCLK|RCC_CLOCKTYPE_SYSCLK|RCC_CLOCKTYPE_PCLK1|RCC_CLOCKTYPE_PCLK2;
  RCC_ClkInitStruct.SYSCLKSource = RCC_SYSCLKSOURCE_PLLCLK;
  RCC_ClkInitStruct.AHBCLKDivider = RCC_SYSCLK_DIV1;
  RCC_ClkInitStruct.APB1CLKDivider = RCC_HCLK_DIV2;
  RCC_ClkInitStruct.APB2CLKDivider = RCC_HCLK_DIV2;
  if (HAL_RCC_ClockConfig(&RCC_ClkInitStruct, FLASH_LATENCY_3) != HAL_OK) Error_Handler();
}

static void MX_SPI2_Init(void)
{
  hspi2.Instance = SPI2;
  hspi2.Init.Mode = SPI_MODE_SLAVE;
  hspi2.Init.Direction = SPI_DIRECTION_2LINES;
  hspi2.Init.DataSize = SPI_DATASIZE_16BIT;
  hspi2.Init.CLKPolarity = SPI_POLARITY_LOW;
  hspi2.Init.CLKPhase = SPI_PHASE_1EDGE;
  hspi2.Init.NSS = SPI_NSS_HARD_INPUT;
  hspi2.Init.FirstBit = SPI_FIRSTBIT_MSB;
  hspi2.Init.TIMode = SPI_TIMODE_DISABLE;
  hspi2.Init.CRCCalculation = SPI_CRCCALCULATION_DISABLE;
  hspi2.Init.CRCPolynomial = 10;
  if (HAL_SPI_Init(&hspi2) != HAL_OK) Error_Handler();
}

static void MX_TIM1_Init(void)
{
  TIM_MasterConfigTypeDef sMasterConfig = {0};
  TIM_OC_InitTypeDef sConfigOC = {0};
  TIM_BreakDeadTimeConfigTypeDef sBreakDeadTimeConfig = {0};
  htim1.Instance = TIM1;
  htim1.Init.Prescaler = 100-1;
  htim1.Init.CounterMode = TIM_COUNTERMODE_UP;
  htim1.Init.Period = 20000-1;
  htim1.Init.ClockDivision = TIM_CLOCKDIVISION_DIV1;
  htim1.Init.RepetitionCounter = 0;
  htim1.Init.AutoReloadPreload = TIM_AUTORELOAD_PRELOAD_DISABLE;
  if (HAL_TIM_PWM_Init(&htim1) != HAL_OK) Error_Handler();
  sMasterConfig.MasterOutputTrigger = TIM_TRGO_RESET;
  sMasterConfig.MasterSlaveMode = TIM_MASTERSLAVEMODE_DISABLE;
  if (HAL_TIMEx_MasterConfigSynchronization(&htim1, &sMasterConfig) != HAL_OK) Error_Handler();
  sConfigOC.OCMode = TIM_OCMODE_PWM1;
  sConfigOC.Pulse = 1500;
  sConfigOC.OCPolarity = TIM_OCPOLARITY_HIGH;
  sConfigOC.OCNPolarity = TIM_OCNPOLARITY_HIGH;
  sConfigOC.OCFastMode = TIM_OCFAST_DISABLE;
  sConfigOC.OCIdleState = TIM_OCIDLESTATE_RESET;
  sConfigOC.OCNIdleState = TIM_OCNIDLESTATE_RESET;
  if (HAL_TIM_PWM_ConfigChannel(&htim1, &sConfigOC, TIM_CHANNEL_1) != HAL_OK) Error_Handler();
  if (HAL_TIM_PWM_ConfigChannel(&htim1, &sConfigOC, TIM_CHANNEL_2) != HAL_OK) Error_Handler();
  sBreakDeadTimeConfig.OffStateRunMode = TIM_OSSR_DISABLE;
  sBreakDeadTimeConfig.OffStateIDLEMode = TIM_OSSI_DISABLE;
  sBreakDeadTimeConfig.LockLevel = TIM_LOCKLEVEL_OFF;
  sBreakDeadTimeConfig.DeadTime = 0;
  sBreakDeadTimeConfig.BreakState = TIM_BREAK_DISABLE;
  sBreakDeadTimeConfig.BreakPolarity = TIM_BREAKPOLARITY_HIGH;
  sBreakDeadTimeConfig.AutomaticOutput = TIM_AUTOMATICOUTPUT_DISABLE;
  if (HAL_TIMEx_ConfigBreakDeadTime(&htim1, &sBreakDeadTimeConfig) != HAL_OK) Error_Handler();
  HAL_TIM_MspPostInit(&htim1);
}

static void MX_USART2_UART_Init(void)
{
  huart2.Instance = USART2;
  huart2.Init.BaudRate = 115200;
  huart2.Init.WordLength = UART_WORDLENGTH_8B;
  huart2.Init.StopBits = UART_STOPBITS_1;
  huart2.Init.Parity = UART_PARITY_NONE;
  huart2.Init.Mode = UART_MODE_TX_RX;
  huart2.Init.HwFlowCtl = UART_HWCONTROL_NONE;
  huart2.Init.OverSampling = UART_OVERSAMPLING_16;
  if (HAL_UART_Init(&huart2) != HAL_OK) Error_Handler();
}

static void MX_GPIO_Init(void)
{
  GPIO_InitTypeDef GPIO_InitStruct = {0};
  __HAL_RCC_GPIOC_CLK_ENABLE();
  __HAL_RCC_GPIOH_CLK_ENABLE();
  __HAL_RCC_GPIOA_CLK_ENABLE();
  __HAL_RCC_GPIOB_CLK_ENABLE();
  HAL_GPIO_WritePin(LD2_GPIO_Port, LD2_Pin, GPIO_PIN_RESET);
  GPIO_InitStruct.Pin = B1_Pin;
  GPIO_InitStruct.Mode = GPIO_MODE_IT_FALLING;
  GPIO_InitStruct.Pull = GPIO_NOPULL;
  HAL_GPIO_Init(B1_GPIO_Port, &GPIO_InitStruct);
  GPIO_InitStruct.Pin = LD2_Pin;
  GPIO_InitStruct.Mode = GPIO_MODE_OUTPUT_PP;
  GPIO_InitStruct.Pull = GPIO_NOPULL;
  GPIO_InitStruct.Speed = GPIO_SPEED_FREQ_LOW;
  HAL_GPIO_Init(LD2_GPIO_Port, &GPIO_InitStruct);
}

/* USER CODE BEGIN 4 */
void HAL_SPI_RxCpltCallback(SPI_HandleTypeDef *hspi) {
    if (hspi->Instance == SPI2) {
        rx_data[rx_index++] = spi_rx_word;
        if (rx_index >= 2) {
            rx_index = 0;
            frame_complete = 1;
        }
        HAL_SPI_Receive_IT(&hspi2, (uint8_t*)&spi_rx_word, 1);
    }
}

void HAL_SPI_ErrorCallback(SPI_HandleTypeDef *hspi) {
    if (hspi->Instance == SPI2) {
        rx_index = 0;
        HAL_SPI_Receive_IT(&hspi2, (uint8_t*)&spi_rx_word, 1);
    }
}
/* USER CODE END 4 */

void Error_Handler(void)
{
  __disable_irq();
  while (1) {}
}

#ifdef USE_FULL_ASSERT
void assert_failed(uint8_t *file, uint32_t line) {}
#endif
