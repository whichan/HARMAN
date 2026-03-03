`timescale 1ns / 1ps

module buzzer_driver_ds1302(
    input i_clk,
    input i_reset,
    input buzzer_on, //alarm_controller의 o_buzzer_trigger로부터 받는 신호 (1pulse trigger)
    input tick_1khz, //지속시간(100ms) 카운팅을 위한 1pulse trigger
    output reg buzzer_out
    );

    // ========== 1. 소리 지속 시간 제어 ========== //
    // buzzer_on 신호가 오면 100ms동안 beep_active를 킴
    reg [$clog2(1_000_000):0] duration_cnt;
    wire beep_active;

    always @(posedge i_clk or posedge i_reset) begin
        if(i_reset) begin
            duration_cnt <= 0;
        end else begin
            if(buzzer_on) begin
                duration_cnt <= 100; //트리거가 들어오면 100ms 준비
            end else if(tick_1khz && duration_cnt > 0) begin
                duration_cnt <= duration_cnt - 1;
            end
        end
    end

    assign beep_active = (duration_cnt > 0);

    // ========== 2. 주파수 생성 ========== //
    reg [14:0] r_tone_cnt;
    reg r_tone_toggle;

    always @(posedge i_clk or posedge i_reset) begin
        if (i_reset) begin
            r_tone_cnt <= 0;
            r_tone_toggle <= 0;
        end else if (beep_active) begin
            // 소리가 나야 하는 동안에만 카운터 동작
            if (r_tone_cnt >= 19_999) begin // 20,000 사이클 도달 시
                r_tone_cnt <= 0;
                r_tone_toggle <= ~r_tone_toggle; // 0 <-> 1 반전
            end else begin
                r_tone_cnt <= r_tone_cnt + 1;
            end
        end else begin
            // 소리가 안 날 때는 깔끔하게 0으로 초기화
            r_tone_cnt <= 0;
            r_tone_toggle <= 0;
        end
    end

    // ========== 3. 최종 출력 ========== //
    always @(posedge i_clk or posedge i_reset) begin
        if (i_reset) 
            buzzer_out <= 0;
        else 
            buzzer_out <= r_tone_toggle;
    end

endmodule