`timescale 1ns / 1ps

module fsm_controller_dht11(
    input clk,
    input reset,
    input tick_1s,
    input btnU,
    input btnR,
    input btnC,
    input btnD,
    input door_is_open, //pwm_servomotor에서부터 받음
    input time_is_zero, //시간이 00:00이 됐을 때. bcd_timer로부터 받음
    output add_min_event,
    output add_sec_event,
    output countdown_event,
    output clear_event,
    output [1:0] fnd_mode, //00:time, 01:play, 10:end
    output motor_on, //pwm_dcmotor로
    output buzzer_on //buzzer_drvier로
);

    //========== btn rising edge 감지 ========== //
    reg r_prev_btnU, r_prev_btnR, r_prev_btnC, r_prev_btnD;
    wire w_btnU_pressed, w_btnR_pressed, w_btnC_pressed, w_btnD_pressed;
    wire any_btn_pressed;
    
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            r_prev_btnU <= 0;
            r_prev_btnR <= 0;
            r_prev_btnC <= 0;
            r_prev_btnD <= 0;
        end else begin
            // 10ns마다 이전 '레벨' 상태 저장
            r_prev_btnU <= btnU; 
            r_prev_btnR <= btnR;
            r_prev_btnC <= btnC;
            r_prev_btnD <= btnD;
        end
    end

    assign w_btnU_pressed = btnU && !r_prev_btnU;
    assign w_btnR_pressed = btnR && !r_prev_btnR;
    assign w_btnC_pressed = btnC && !r_prev_btnC;
    assign w_btnD_pressed = btnD && !r_prev_btnD;
    assign any_btn_pressed = w_btnU_pressed || w_btnR_pressed || w_btnC_pressed || w_btnD_pressed;

    //========== 상태 정의 ========== //
    localparam S_IDLE = 2'b00; //00:00, 대기
    localparam S_PAUSE = 2'b01; //시간설정/일시정지
    localparam S_PLAY = 2'b10; //동작(카운트다운)
    localparam S_END = 2'b11; //종료 알림

    reg[1:0] state, next_state;

    always @(posedge clk or posedge reset) begin
        if(reset) begin
            state <= S_IDLE;
        end else begin
            state <= next_state;
        end
    end

    //==========END 상태 카운터 (3번 깜박임/울림 = 6초)==========//
    reg [2:0] end_cnt; //0~5
    wire end_done = (end_cnt == 6);

    always @(posedge clk or posedge reset) begin
        if(reset) end_cnt <= 0;
        else if(state != S_END) end_cnt <= 0; //END상태가 아니면 항상 0
        else if(tick_1s && !end_done) //END 상태일 때 1초마다 1씩 증가
            end_cnt <= end_cnt +1;
    end

    // ========== FSM 로직 ========== //
    always @(*) begin
        next_state = state;

        case(state)
            S_IDLE: begin
                if(w_btnU_pressed || w_btnR_pressed)
                next_state = S_PAUSE;
            end

            S_PAUSE: begin
                if(w_btnD_pressed) next_state = S_IDLE;
                else if(w_btnC_pressed && !door_is_open) next_state = S_PLAY;
            end

            S_PLAY: begin
                if(w_btnD_pressed) next_state = S_IDLE;
                else if(w_btnC_pressed) next_state = S_PAUSE;
                else if(door_is_open) next_state = S_PAUSE;
                else if(time_is_zero) next_state = S_END;
            end

            S_END: begin
                if(end_done) next_state = S_IDLE;
            end
        endcase
    end

    // ========== FSM output 로직 ========== //

    // ----- bcd timer로 보낼 명령 ----- //
    assign add_min_event = (state == S_PAUSE || state == S_PLAY) && w_btnU_pressed;
    assign add_sec_event = (state == S_PAUSE || state == S_PLAY) && w_btnR_pressed;
    assign countdown_event = (state == S_PLAY) && tick_1s; //PLAY일 때 1초마다
    assign clear_event = (state != S_IDLE) && w_btnD_pressed; //IDLE상태가 아닐 때 btnD를 누르면

    // ----- fnd controller로 보낼 '모드' ----- //
    assign fnd_mode = (state == S_IDLE) ? 2'b00:
                      (state == S_PAUSE) ? 2'b00:
                      (state == S_PLAY) ? 2'b01:
                      (state == S_END) ? 2'b10: 2'b00;

    assign motor_on = (state == S_PLAY);

    assign buzzer_on = (any_btn_pressed) || (state == S_END && tick_1s && (end_cnt[0] == 0));
    //아무 버튼을 누르거나 S_END상태에서 1초마다 end_cnt가 짝수일 때
    
endmodule