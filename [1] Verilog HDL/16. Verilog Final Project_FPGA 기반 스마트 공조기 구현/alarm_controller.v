`timescale 1ns / 1ps

module alarm_controller_ds1302(
    input i_clk,
    input i_reset,
    input i_tick_1khz,       // 타이밍용 1ms 펄스
    input [7:0] i_hour,
    input [7:0] i_min,
    input [7:0] i_sec,
    input i_stop_btn,        // 알람 끄는 버튼 (btnD)

    output reg o_buzzer_trigger, // buzzer_driver에 보낼 시작 펄스
    output reg o_alarm_active    // 알람이 동작 중임을 알리는 신호
);

    // ========== 1. 파라미터 정의 ========== //
    localparam TARGET_HOUR = 8'h12;
    localparam TARGET_MIN  = 8'h50;
    localparam TARGET_SEC  = 8'h00;
    
    // ========== 2. 내부 레지스터 ========== //
    // 1ms 단위로 500까지 세려면 9비트면 충분합니다 (2^9 = 512)
    reg [8:0] r_beep_interval_cnt; 
    reg r_stopped_by_user; 

    always @(posedge i_clk or posedge i_reset) begin
        if(i_reset) begin
            o_alarm_active <= 0;
            o_buzzer_trigger <= 0;
            r_beep_interval_cnt <= 0;
            r_stopped_by_user <= 0;
        end else begin
            // 트리거는 1클럭 펄스이므로 기본적으로 0
            o_buzzer_trigger <= 0; 
            
            // =================================================
            // [1] 알람 끄기 (최우선 순위)
            // =================================================
            if(i_stop_btn) begin 
                o_alarm_active <= 0; // 즉시 알람 끔
                
                // 만약 현재 시간이 12:50:00 라면, "내가 껐다"는 흔적을 남김
                if((i_hour == TARGET_HOUR) && (i_min == TARGET_MIN) && (i_sec == TARGET_SEC)) begin
                    r_stopped_by_user <= 1; 
                end
            end
            // =================================================
            // [2] 알람 로직 (버튼을 안 눌렀을 때)
            // =================================================
            else begin
                // 2-1. 시간 체크 및 알람 시작 조건
                if((i_hour == TARGET_HOUR) && (i_min == TARGET_MIN) && (i_sec == TARGET_SEC)) begin
                    // 시간이 맞고, 강제로 끈 적이 없고, 아직 안 켜졌다면 -> 시작!
                    if(!r_stopped_by_user && !o_alarm_active) begin
                        o_alarm_active <= 1;
                        r_beep_interval_cnt <= 0;
                        o_buzzer_trigger <= 1; // 첫 '삑'
                    end
                end 
                else begin
                    // [중요 수정] 시간이 지났을 때 (12:50:01 ~)
                    // 알람을 끄지 않습니다! (o_alarm_active 건드리지 않음)
                    // 대신 내일을 위해 '강제종료 플래그'만 초기화합니다.
                    r_stopped_by_user <= 0; 
                end

                // 2-2. 알람 울리기
                // 시간이 지나도 o_alarm_active가 1이면 계속 들어와서 울립니다.
                if(o_alarm_active) begin
                    if(i_tick_1khz) begin
                        if(r_beep_interval_cnt >= 499) begin // 500ms 도달
                            r_beep_interval_cnt <= 0;
                            o_buzzer_trigger <= 1; // '삑' 트리거 발생
                        end else begin
                            r_beep_interval_cnt <= r_beep_interval_cnt + 1;
                        end
                    end
                end
            end
        end
    end
endmodule