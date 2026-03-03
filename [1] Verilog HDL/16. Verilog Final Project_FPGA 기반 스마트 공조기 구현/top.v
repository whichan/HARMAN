`timescale 1ns / 1ps

module top(
    input clk,
    input reset,        // SW[15] 등 보드의 리셋 스위치 연결
    input [5:0] sw, //

    input btnL, btnR, btnU, btnD, btnC, 

    // [로터리 엔코더]
    input s1, s2, key,

    // [UART]
    input RsRx,
    output RsTx,

    // [개별 하드웨어 핀 - 물리적으로 분리됨]
    inout dht11_data,       // 온습도 센서
    output motor_pwm,       // DC 모터 PWM
    output [1:0] dcmotor_dir, // DC 모터 방향
    
    inout ds1302_io,        // DS1302 데이터
    output ds1302_sclk,     // DS1302 클럭
    output ds1302_ce,       // DS1302 칩 선택

    output [7:0] seg,
    output [3:0] an,
    output [15:0] led,
    output buzzer,


    //[oled - ssd1306]
    output oled_scl,
    inout oled_sda
);

    //추가: DS1302 -> OLED
    wire [7:0] w_rtc_hour, w_rtc_min, w_rtc_sec;
    
    //추가: DHT11 -> OLED
    
    wire [7:0] w_humi_INT, w_humi_REAL;
    wire [7:0] w_temp_INT, w_temp_REAL;

    // DS1302 출력을 받을 wire
    wire [7:0] w_ds_seg;
    wire [3:0] w_ds_an;
    wire [15:0] w_ds_led;
    wire w_ds_tx;
    wire w_ds_buzzer;

    // DHT11 출력을 받을 wire
    wire [7:0] w_dht_seg;
    wire [3:0] w_dht_an;
    wire [15:0] w_dht_led;
    wire w_dht_tx;
    wire w_dht_buzzer;

    // ========== (1) 시계/알람 모듈 (top_ds1302) ==========
    // sw[5]=1
    top_ds1302 u_top_ds1302(
        .clk(clk),
        .reset(reset),
        
        .btnD(btnD),      // 알람 끄기 버튼
        .s1(s1),          // 시간 조절용 로터리
        .s2(s2),
        .key(key),
        .RsRx(RsRx),      // RX 라인 공유 (필요시)

        // 실제 DS1302 핀 연결 (여기서 제어함)
        .ds1302_io(ds1302_io),
        .ds1302_sclk(ds1302_sclk),
        .ds1302_ce(ds1302_ce),

        .RsTx(w_ds_tx),
        .seg(w_ds_seg),
        .an(w_ds_an),
        .led(w_ds_led),
        .buzzer(w_ds_buzzer),

        .o_hour(w_rtc_hour),
        .o_min(w_rtc_min),
        .o_sec(w_rtc_sec)
    );

    // ========== (2) 스마트 온습도 모듈 (top_dht11) ==========
    // sw[5]가 0일 때 화면에 표시됨
    top_dht11 u_top_dht11(
        .clk(clk),
        .reset(reset),
        .sw(sw[4:0]),     // 하위 5개 스위치는 DHT11 설정용으로 전달
        
        .btnL(btnL), .btnR(btnR), .btnU(btnU), .btnC(btnC), .btnD(btnD),
        .s1(s1), .s2(s2), .key(key),

        // 실제 온습도/모터 핀 연결
        .dht11_data(dht11_data),
        .motor_pwm(motor_pwm),
        .dcmotor_dir(dcmotor_dir),

        // [중요] top_dht11 내부의 DS1302 포트는 연결 안 함 (충돌 방지)

        .RsRx(RsRx),

        // 출력은 와이어에 저장
        .RsTx(w_dht_tx),
        .seg(w_dht_seg),
        .an(w_dht_an),
        .led(w_dht_led),
        .buzzer(w_dht_buzzer)

        /*.o_humi_INT(w_humi_INT),
        .o_humi_REAL(w_humi_REAL),
        .o_temp_INT(w_temp_INT),
        .o_temp_REAL(w_temp_REAL)*/
    );


    top_ssd1306 u_top_ssd1306(
        .clk(clk),
        .reset(reset),

        //.display_mode(sw[5]),

        // from ds1302 (BCD Format 가정)
        .hour(w_rtc_hour),
        .min(w_rtc_min),
        .sec(w_rtc_sec),

        /*.temp_int(w_temp_INT),
        .temp_real(w_temp_REAL),
        .humi_int(w_humi_INT),
        .humi_real(w_humi_REAL),*/

        // Physical I2C Pins
        .oled_scl(oled_scl),    // SCL
        .oled_sda(oled_sda)     // SDA
    );

    //================================================================
    // 3. 출력 MUX (스위치 5번에 따른 선택)
    //================================================================
    // sw[5] == 1 : DS1302 (시계) 선택
    // sw[5] == 0 : DHT11 (온습도) 선택

    // [FND 디스플레이]
    assign seg = (sw[5]) ? w_ds_seg : w_dht_seg;
    assign an  = (sw[5]) ? w_ds_an  : w_dht_an;

    // [UART 전송]
    assign RsTx = (sw[5]) ? w_ds_tx : w_dht_tx;

    // [buzzer]
    assign buzzer = (sw[5]) ? w_ds_buzzer : w_dht_buzzer;

    // [LED]
    assign led[15] = sw[5];
    
    // 나머지 LED는 선택된 모듈의 상태를 표시
    assign led[14:0] = (sw[5]) ? w_ds_led[14:0] : w_dht_led[14:0];

endmodule