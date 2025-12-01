`timescale 1ns / 1ps

module buzzer_driver(
    input clk,          // 100MHz 클럭
    input reset,        // Active-High 리셋
    
    // 'fsm_controller'로부터 받는 1-pulse 'ON' 명령
    input buzzer_on,    
    
    // 'clock_divider'로부터 받는 1ms 틱
    input tick_1khz,    
    
    output reg buzzer_out  // 실제 부저 핀으로 나가는 500Hz 펄스
);

    // --- 1. 100ms 지속시간 타이머 ---
    // 'buzzer_on' 펄스가 들어오면 100을 로드하고,
    // 'tick_1khz'(1ms)마다 1씩 카운트다운합니다.
    reg [6:0] duration_cnt; // 100ms = 1ms * 100 (7비트면 127까지 가능)

    always @(posedge clk or posedge reset) begin
        if (reset)
            duration_cnt <= 0;
        else if (buzzer_on)
            // [!] '두뇌'가 명령하면, 100ms 타이머 장전!
            duration_cnt <= 100; 
        else if (tick_1khz && duration_cnt > 0)
            // 1ms마다 1씩 카운트다운
            duration_cnt <= duration_cnt - 1;
    end

    // 'duration_cnt > 0'인 동안이 'beep_active' (울리는 중) 상태입니다.
    wire beep_active = (duration_cnt > 0);

    // --- 2. 500Hz 톤 생성기 (토글) ---
    // 'tick_1khz'(1ms)마다 0과 1을 뒤집습니다.
    // (1ms High, 1ms Low = 2ms 주기 = 500Hz 톤)
    reg tone_toggle;

    always @(posedge clk or posedge reset) begin
        if (reset)
            tone_toggle <= 0;
        else if (tick_1khz)
            tone_toggle <= ~tone_toggle;
    end

    // --- 3. 최종 출력 로직 ---
    // 100ms 타이머가 활성화된(beep_active) 동안에만,
    // 500Hz 톤(tone_toggle)을 출력합니다.
    always @(posedge clk or posedge reset) begin
        if (reset)
            buzzer_out <= 0;
        else if (beep_active)
            buzzer_out <= tone_toggle;
        else
            buzzer_out <= 0;
    end

endmodule
