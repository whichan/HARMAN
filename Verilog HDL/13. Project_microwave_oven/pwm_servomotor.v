`timescale 1ns / 1ps

module pwm_servomotor(
    input clk, 
    input reset,
    input btnL,         
    output pwm_servo,   // 1. 서보 모터로 가는 실제 PWM 펄스
    output reg door_is_open  // FSM으로 가는 1-bit 상태
);
    
    //========== 1. 파라미터 정의 (100MHz 기준) ==========//
    // 20ms (50Hz) 주기: 100,000,000 * 0.02 = 2,000,000
    parameter PERIOD = 2_000_000;
    
    // 1ms (0도, 닫힘) 펄스 폭: 100,000,000 * 0.001 = 100,000
    parameter DUTY_CLOSE_0DEG = 100_000;
    
    // 2ms (180도, 열림) 펄스 폭: 100,000,000 * 0.002 = 200,000
    parameter DUTY_OPEN_180DEG = 200_000;
    
    
    // ========== 2. btn rising edge 감지 ========== //
    reg r_prev_btnL = 0;
    
    always @(posedge clk or posedge reset) begin
        if(reset)
            r_prev_btnL <= 0;
        else
            r_prev_btnL <= btnL; // 10ns마다 이전 상태 저장
    end
    wire w_btnL_pressed = (!r_prev_btnL && btnL);


    // ========== 3. 서보 모터 상태 FSM (토글) ========== //
    // 'output reg door_is_open'을 상태 레지스터로 직접 사용합니다.
    always @(posedge clk or posedge reset) begin
        if(reset) begin
            door_is_open <= 0; // 리셋 시 '닫힘(0도)' 상태로 시작
        end else if(w_btnL_pressed) begin
            // 1-pulse 이벤트가 발생하면 상태를 반전(Toggle)
            door_is_open <= ~door_is_open;
        end
    end

    // ========== 4. PWM 펄스 폭 선택 (Mux) ========== //
    // 2,000,000을 담으려면 21비트($clog2(PERIOD))가 필요합니다.
    wire [$clog2(PERIOD)-1:0] duty_count;
    
    // 현재 'door_is_open' 상태에 따라 펄스 폭(목표값)을 선택
    assign duty_count = (door_is_open) ? DUTY_OPEN_180DEG : DUTY_CLOSE_0DEG;
    
    
    // --- 5. PWM 생성 카운터 (20ms 주기) ---
    reg [$clog2(PERIOD)-1:0] period_counter;

    always @(posedge clk or posedge reset) begin
        if(reset) begin
            period_counter <= 0;
        end else begin
            if(period_counter == PERIOD - 1) begin
                period_counter <= 0;
            end else begin
                period_counter <= period_counter + 1;
            end
        end
    end
    
    // --- 6. PWM 출력 생성 (비교기) ---
    // '카운터'가 '목표값(duty_count)'보다 작을 때만 1(High)을 출력
    assign pwm_servo = (period_counter < duty_count);

endmodule