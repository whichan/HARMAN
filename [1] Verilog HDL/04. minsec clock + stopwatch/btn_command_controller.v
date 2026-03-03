`timescale 1ns / 1ps

module btn_command_controller(
    input clk,
    input reset, //btnU
    input [2:0] btn, //btnL:pause/재생      btnU: reset         btnC:분초시계로 모드 바꿈 
    output reg [15:0] led,  //현재 상태 표시용
    output [13:0] seg_data,  //FND에 표시할 9,999 값
    output reg switch_to_minsec,
    output reg is_idle_anim, //현재 idle animation 상태인가?
    output reg [3:0] anim_step //총 12가지 상태가 있으므로 4비트 선언
    );

    parameter ANIM_DELAY = 25'd10_000_000; //100ms마다 이동

    //----------FSM 상태 정의----------//
    parameter S_IDLE = 2'b00;
    parameter S_RUNNING = 2'b01;
    parameter S_PAUSED = 2'b10;

    //----------내부 레지스터----------//
    reg [1:0] r_state = S_IDLE;
    reg [19:0] r_tick_counter = 0;
    reg [13:0] r_ms10_counter = 0;
    
    //animation(애니메이션용 레지스터)
    reg [24:0] r_anim_tick_counter = 0;
    
    //5초 타이머
    reg [$clog2(500_000_000)-1:0] r_auto_resume_counter = 0;

    //----------버튼 Rising Edge 감지----------//
    reg r_prev_btnL = 0;
    reg r_prev_btnC = 0;
    reg r_prev_btnR = 0;

    wire w_btnL_pressed = (btn[0] && !r_prev_btnL);
    wire w_btnC_pressed = (btn[1] && !r_prev_btnC);
    wire w_btnR_pressed = (btn[2] && !r_prev_btnR);

    wire w_any_btn_pressed = w_btnL_pressed || w_btnC_pressed || w_btnR_pressed;
    
    //----------메인FSM----------//
    always @(posedge clk or posedge reset) begin
        if(reset) begin
            r_state <= S_IDLE;
            r_ms10_counter <= 0;
            r_tick_counter <= 0;
            r_prev_btnL <= 0;
            r_prev_btnC <= 0;
            r_prev_btnR <= 0;
            switch_to_minsec <= 0;
            r_auto_resume_counter <= 0;
            is_idle_anim <= 1'b1;
            anim_step <= 0;
            r_anim_tick_counter <= 0;
        end else begin
            //FSM
            r_prev_btnL <= btn[0];
            r_prev_btnC <= btn[1];
            r_prev_btnR <= btn[2];
            switch_to_minsec <= 0;

            //------[btnC]모드전환-----//
            if(w_btnC_pressed) begin
                switch_to_minsec <= 1'b1;
                if(r_state == S_RUNNING) begin
                    r_state <= S_PAUSED;
                    is_idle_anim <= 1'b0;
                end
            end
            
            //-----[btnL]재생,정지-----//
            else if(w_btnL_pressed) begin
                case(r_state)
                    S_RUNNING: begin 
                        r_state <= S_PAUSED; 
                        is_idle_anim <= 1'b0; 
                    end
                    S_PAUSED: begin 
                        r_state <= S_RUNNING; 
                        is_idle_anim <= 1'b0; 
                    end
                    default: begin
                        // S_IDLE 상태에서는 아무 동작 안 함
                    end
                endcase
            end
            
            //-----[btnR]시작-----//
            else if(w_btnR_pressed) begin
                if(r_state == S_IDLE) begin
                    r_state <= S_RUNNING;
                    is_idle_anim <= 1'b0;
                    r_ms10_counter <= 0;  // 카운터 초기화
                end
            end

            //-----5초 자동 IDLE 복귀-----//
            if(r_state == S_PAUSED) begin
                if(w_any_btn_pressed) begin
                    r_auto_resume_counter <= 0;
                end else if(r_auto_resume_counter == 29'd499_999_999) begin
                    r_state <= S_IDLE;
                    r_auto_resume_counter <= 0;
                    is_idle_anim <= 1'b1;
                    anim_step <= 0;
                    r_anim_tick_counter <= 0;
                    r_ms10_counter <= 0;
                end else begin
                    r_auto_resume_counter <= r_auto_resume_counter + 1;
                end
            end else begin
                r_auto_resume_counter <= 0;
            end

            //-----IDLE 애니메이션 로직-----//
            if(r_state == S_IDLE) begin
                is_idle_anim <= 1'b1;
                
                if(r_anim_tick_counter == ANIM_DELAY - 1) begin
                    r_anim_tick_counter <= 0;
                    
                    if(anim_step == 4'd11)
                        anim_step <= 0;
                    else
                        anim_step <= anim_step + 1;
                end else begin
                    r_anim_tick_counter <= r_anim_tick_counter + 1;
                end
            end else begin
                is_idle_anim <= 1'b0;
                r_anim_tick_counter <= 0;
            end

            //-----카운터 동작-----//   
            if(r_state == S_RUNNING) begin
                if(r_tick_counter == 20'd999_999) begin
                    r_tick_counter <= 0;
                    if(r_ms10_counter < 14'd9999) begin
                        r_ms10_counter <= r_ms10_counter + 1;
                    end
                end else begin
                    r_tick_counter <= r_tick_counter + 1;
                end
            end else begin
                r_tick_counter <= 0;
            end
        end  
    end  

    //----------출력 로직(조합논리)----------//
    assign seg_data = r_ms10_counter;

    //led출력
    always @(*) begin
        led = 16'b0;
        case(r_state)
            S_IDLE: led[13] = 1'b1;
            S_RUNNING: led[15] = 1'b1;
            S_PAUSED: led[14] = 1'b1;
            default: led = 16'b0;
        endcase        
    end

endmodule