`timescale 1ns / 1ps

// 9-모듈 아키텍처의 7번: 부저 드라이버 ('근육')
// '두뇌'로부터 1-pulse 'buzzer_on' 명령을 받아,
// 100ms 동안 500Hz 톤을 생성합니다.
module buzzer_driver_dht11(
    input clk,          // 100MHz 클럭
    input reset,        // Active-High 리셋 (top.v에서 사용)
    
    // 'fsm_controller'로부터 받는 1-pulse 'ON' 명령
    input buzzer_on,    
    
    // 'clock_divider'로부터 받는 1ms 틱
    input tick_1khz,    
    
    output reg buzzer_out  // 실제 부저 핀으로 나가는 500Hz 펄스
);

    // --- 1. 100ms 지속시간 타이머 ---
    reg [6:0] duration_cnt; // 100ms = 1ms * 100 (7비트)

    always @(posedge clk or posedge reset) begin
        if (reset) // Active-High 비동기 리셋
            duration_cnt <= 0;
        else if (buzzer_on)
            duration_cnt <= 100; 
        else if (tick_1khz && duration_cnt > 0)
            duration_cnt <= duration_cnt - 1;
    end

    wire beep_active = (duration_cnt > 0);

    // --- 2. 500Hz 톤 생성기 (토글) ---
    reg tone_toggle;

    always @(posedge clk or posedge reset) begin
        if (reset) // Active-High 비동기 리셋
            tone_toggle <= 0;
        else if (tick_1khz)
            tone_toggle <= ~tone_toggle;
    end

    // --- 3. 최종 출력 로직 ---
    always @(posedge clk or posedge reset) begin
        if (reset) // Active-High 비동기 리셋
            buzzer_out <= 0;
        else if (beep_active)
            buzzer_out <= tone_toggle;
        else
            buzzer_out <= 0;
    end

endmodule