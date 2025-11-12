`timescale 1ns / 1ps

module bcd_timer(
    input clk,
    input reset,
    input add_min_event,
    input add_sec_event,
    input countdown_event,
    input clear_event,
    output [13:0] seg_data_out, //fnd_controller로
    output time_is_zero //fsm_controller로
);
    
    //========== BCD(10진수) 저장 레지스터 ==========//
    reg [2:0] min_t; //분 십의자리 (0~5)
    reg [3:0] min_o; //분 일의자리(0~9)
    reg [2:0] sec_t; //초 십의자리 (0~5)
    reg [3:0] sec_o; //초 일의자리(0~9)

    //========== BCD 연산 로직 (우선순위 수정) ==========//
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            // 시스템 리셋
            min_t <= 0;
            min_o <= 0;
            sec_t <= 0;
            sec_o <= 0;
        
        // "CLEAR" 이벤트 (D 버튼) - reset 다음으로 우선순위
        end else if (clear_event) begin
            min_t <= 0;
            min_o <= 0;
            sec_t <= 0;
            sec_o <= 0;
        
        // "+1분" 이벤트 (U 버튼)
        end else if (add_min_event) begin
            if (min_o == 9) begin
                min_o <= 0;
                if (min_t == 5) begin // 59분 -> 00분
                    min_t <= 0;
                end else begin
                    min_t <= min_t + 1;
                end
            end else begin
                min_o <= min_o + 1;
            end
        
        // "+10초" 이벤트 (R 버튼)
        end else if (add_sec_event) begin
            if (sec_t == 5) begin // 50초 -> 00초
                sec_t <= 0;
            end else begin
                sec_t <= sec_t + 1;
            end
        
        // "1초 카운트다운" 이벤트 (PLAY 상태에서 tick_1s마다)
        end else if (countdown_event && !time_is_zero) begin
            if (sec_o > 0) begin
                // 일의 자리만 감소 (예: 01:23 -> 01:22)
                sec_o <= sec_o - 1;
            end else begin 
                // sec_o가 0일 때 (예: 01:20 -> 01:19)
                sec_o <= 9;
                if (sec_t > 0) begin
                    sec_t <= sec_t - 1;
                end else begin 
                    // sec_t도 0일 때 (예: 01:00 -> 00:59)
                    sec_t <= 5;
                    if (min_o > 0) begin
                        min_o <= min_o - 1;
                    end else begin 
                        // min_o가 0일 때 (예: 10:00 -> 09:59)
                        min_o <= 9;
                        if (min_t > 0) begin
                            min_t <= min_t - 1;
                        end else begin
                            // 00:00 도달 - 더 이상 감소 안 함
                            min_t <= 0;
                        end
                    end
                end
            end
        end
    end // always

    assign time_is_zero = (min_t==0 && min_o==0 && sec_t==0 && sec_o==0);
    assign seg_data_out = {min_t[2:0], min_o[3:0], sec_t[2:0], sec_o[3:0]}; //14비트 bcd 데이터

endmodule