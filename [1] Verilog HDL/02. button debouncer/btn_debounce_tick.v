`timescale 1ns / 1ps

// Tick 기반 Button Debounce 모듈
module btn_debounce_tick(
    input i_clk,
    input i_reset,
    input i_tick,           // 1kHz tick (1ms마다)
    input i_btn,
    output reg o_btn_pulse
    );
    
    parameter DEBOUNCE_MS = 10;  // 10ms 디바운스 시간
    
    reg [$clog2(DEBOUNCE_MS)-1:0] r_ms_counter = 0;  // 4bit 정도
    reg r_btn_state = 0;        // 현재 안정된 버튼 상태
    reg r_btn_prev = 0;         // 이전 상태 (edge detection용)
    
    always @(posedge i_clk, posedge i_reset) begin
        if(i_reset) begin
            r_ms_counter <= 0;
            r_btn_state <= 0;
            r_btn_prev <= 0;
            o_btn_pulse <= 0;
        end
        else begin
            if(i_tick) begin  // 1ms마다 실행
                // 버튼 상태가 변하면 카운터 증가
                if(i_btn != r_btn_state) begin
                    r_ms_counter <= r_ms_counter + 1;
                    
                    // 10ms 동안 안정되면 상태 업데이트
                    if(r_ms_counter >= DEBOUNCE_MS - 1) begin
                        r_btn_state <= i_btn;
                        r_ms_counter <= 0;
                    end
                end
                else begin
                    r_ms_counter <= 0;  // 같으면 카운터 리셋
                end
            end
            
            // Rising edge 검출 (100MHz 클럭 도메인에서)
            r_btn_prev <= r_btn_state;
            if(r_btn_state != r_btn_prev) begin
                o_btn_pulse <= 1'b1;
            end
            else begin
                o_btn_pulse <= 1'b0;
            end
        end
    end
    
endmodule