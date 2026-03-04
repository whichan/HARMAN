#include "main.h"
#include <stdio.h>
#include <string.h>

/* 외부 정의 확인 */
extern void delay_us(unsigned int us);
extern volatile uint8_t rx_buffer[20][40];
extern volatile int input_index;
extern volatile int output_index;

#define DS1302_SEC   0x80
#define DS1302_MIN   0x82
#define DS1302_HOUR  0x84
#define DS1302_DATE  0x86
#define DS1302_MONTH 0x88
#define DS1302_DAY   0x8A
#define DS1302_YEAR  0x8C
#define DS1302_WP    0x8E

static uint8_t dec2bcd(uint8_t val) { return ((val / 10) << 4) | (val % 10); }
static uint8_t bcd2dec(uint8_t val) { return ((val >> 4) * 10) + (val & 0x0F); }

static void ds1302_output(void) {
    GPIO_InitTypeDef g = {0};
    g.Pin = IO_DS1302_Pin;
    g.Mode = GPIO_MODE_OUTPUT_PP;
    g.Pull = GPIO_NOPULL;
    g.Speed = GPIO_SPEED_FREQ_LOW;
    HAL_GPIO_Init(IO_DS1302_GPIO_Port, &g);
}

static void ds1302_input(void) {
    GPIO_InitTypeDef g = {0};
    g.Pin = IO_DS1302_Pin;
    g.Mode = GPIO_MODE_INPUT;
    g.Pull = GPIO_PULLUP;
    HAL_GPIO_Init(IO_DS1302_GPIO_Port, &g);
}

/* 데이터 전송 후 반드시 CLK을 LOW로 유지해야 다음 읽기/쓰기가 정확합니다 */
static void ds1302_write_byte(uint8_t data) {
    ds1302_output();
    for (int i = 0; i < 8; i++) {
        HAL_GPIO_WritePin(IO_DS1302_GPIO_Port, IO_DS1302_Pin, (data & 0x01) ? GPIO_PIN_SET : GPIO_PIN_RESET);
        delay_us(5); // 안정성을 위해 5us로 증가
        HAL_GPIO_WritePin(CLK_DS1302_GPIO_Port, CLK_DS1302_Pin, GPIO_PIN_SET);
        delay_us(5);
        HAL_GPIO_WritePin(CLK_DS1302_GPIO_Port, CLK_DS1302_Pin, GPIO_PIN_RESET); // CLK 하강 시점에서 데이터 샘플링
        delay_us(5);
        data >>= 1;
    }
}

static uint8_t ds1302_read_byte(void) {
    uint8_t v = 0;
    ds1302_input();
    for (int i = 0; i < 8; i++) {
        v >>= 1;
        if (HAL_GPIO_ReadPin(IO_DS1302_GPIO_Port, IO_DS1302_Pin)) v |= 0x80;
        HAL_GPIO_WritePin(CLK_DS1302_GPIO_Port, CLK_DS1302_Pin, GPIO_PIN_SET);
        delay_us(5);
        HAL_GPIO_WritePin(CLK_DS1302_GPIO_Port, CLK_DS1302_Pin, GPIO_PIN_RESET);
        delay_us(5);
    }
    return v;
}

static void ds1302_write_reg(uint8_t reg, uint8_t val) {
    HAL_GPIO_WritePin(CE_DS1302_GPIO_Port, CE_DS1302_Pin, GPIO_PIN_SET);
    delay_us(5);
    ds1302_write_byte(reg & 0xFE);
    ds1302_write_byte(val);
    HAL_GPIO_WritePin(CE_DS1302_GPIO_Port, CE_DS1302_Pin, GPIO_PIN_RESET);
    delay_us(5);
}

static uint8_t ds1302_read_reg(uint8_t reg) {
    uint8_t val;
    HAL_GPIO_WritePin(CE_DS1302_GPIO_Port, CE_DS1302_Pin, GPIO_PIN_SET);
    delay_us(5);
    ds1302_write_byte(reg | 0x01);
    val = ds1302_read_byte();
    HAL_GPIO_WritePin(CE_DS1302_GPIO_Port, CE_DS1302_Pin, GPIO_PIN_RESET);
    delay_us(5);
    return val;
}

void ds1302_set_time(uint8_t sec, uint8_t min, uint8_t hour, uint8_t date, uint8_t month, uint8_t day, uint8_t year) {
    ds1302_write_reg(DS1302_WP, 0x00); // 쓰기 방지 해제
    ds1302_write_reg(DS1302_SEC, dec2bcd(sec) & 0x7F);
    ds1302_write_reg(DS1302_MIN, dec2bcd(min));
    ds1302_write_reg(DS1302_HOUR, dec2bcd(hour));
    ds1302_write_reg(DS1302_DATE, dec2bcd(date));
    ds1302_write_reg(DS1302_MONTH, dec2bcd(month));
    ds1302_write_reg(DS1302_DAY, day);
    ds1302_write_reg(DS1302_YEAR, dec2bcd(year));
    ds1302_write_reg(DS1302_WP, 0x80); // 다시 쓰기 방지 설정
}

void ds1302_get_time(uint8_t *t) {
    t[0] = bcd2dec(ds1302_read_reg(DS1302_SEC) & 0x7F);
    t[1] = bcd2dec(ds1302_read_reg(DS1302_MIN));
    t[2] = bcd2dec(ds1302_read_reg(DS1302_HOUR) & 0x3F);
    t[3] = bcd2dec(ds1302_read_reg(DS1302_DATE));
    t[4] = bcd2dec(ds1302_read_reg(DS1302_MONTH));
    t[5] = ds1302_read_reg(DS1302_DAY);
    t[6] = bcd2dec(ds1302_read_reg(DS1302_YEAR));
}

static void ds1302_process_uart(void) {
    while (output_index != input_index) {
        char *cmd = (char*)rx_buffer[output_index];
        if (!strncmp(cmd, "setrtc", 6) && strlen(cmd) >= 18) {
            uint8_t sec, min, hour, date, month, year;
            year  = (cmd[6]-'0')*10 + (cmd[7]-'0');
            month = (cmd[8]-'0')*10 + (cmd[9]-'0');
            date  = (cmd[10]-'0')*10 + (cmd[11]-'0');
            hour  = (cmd[12]-'0')*10 + (cmd[13]-'0');
            min   = (cmd[14]-'0')*10 + (cmd[15]-'0');
            sec   = (cmd[16]-'0')*10 + (cmd[17]-'0');
            ds1302_set_time(sec, min, hour, date, month, 1, year);
            printf("\n[OK] RTC SET: 20%02d-%02d-%02d %02d:%02d:%02d\n", year, month, date, hour, min, sec);
        }
        output_index = (output_index + 1) % 20;
    }
}

void ds1302_main(void) {
    uint8_t t[7];

    // 최초 실행 시 핀 상태 초기화 (중요)
    HAL_GPIO_WritePin(CE_DS1302_GPIO_Port, CE_DS1302_Pin, GPIO_PIN_RESET);
    HAL_GPIO_WritePin(CLK_DS1302_GPIO_Port, CLK_DS1302_Pin, GPIO_PIN_RESET);

    while (1) {
        ds1302_get_time(t);
        // \r 대신 \n을 사용하여 실시간 출력 보장
        printf("Time: 20%02d-%02d-%02d %02d:%02d:%02d\n", t[6], t[4], t[3], t[2], t[1], t[0]);

        ds1302_process_uart();
        HAL_Delay(1000);
    }
}
