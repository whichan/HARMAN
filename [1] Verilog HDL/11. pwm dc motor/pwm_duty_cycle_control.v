`timescale 1ns / 1ps

module pwm_duty_cycle_control (
    input clk,
    input reset,              //reset 추가
    input duty_inc,
    input duty_dec,
    output [3:0] DUTY_CYCLE,
    output PWM_OUT,
    output PWM_OUT_LED
); 

    reg [3:0] r_DUTY_CYCLE;
    reg [3:0] r_counter_PWM;
    
    //Edge Detection 추가
    reg duty_inc_prev;
    reg duty_dec_prev;
    
    // 상승 엣지 감지: 이전에 0이었다가 지금 1이 된 순간
    wire duty_inc_rising = duty_inc & ~duty_inc_prev;
    wire duty_dec_rising = duty_dec & ~duty_dec_prev;

    //Duty Cycle 제어 (Edge Detection 적용)
    always @(posedge clk) begin
        if (reset) begin
            r_DUTY_CYCLE <= 4'd5;      // 초기값 50%
            duty_inc_prev <= 1'b0;
            duty_dec_prev <= 1'b0;
        end else begin
            // 이전 버튼 상태 저장
            duty_inc_prev <= duty_inc;
            duty_dec_prev <= duty_dec;
            
            // 버튼이 눌린 순간(rising edge)에만 동작
            if (duty_inc_rising && r_DUTY_CYCLE < 4'd10) begin
                r_DUTY_CYCLE <= r_DUTY_CYCLE + 1;
            end else if (duty_dec_rising && r_DUTY_CYCLE > 4'd0) begin
                r_DUTY_CYCLE <= r_DUTY_CYCLE - 1;
            end
        end
    end

    // PWM 신호 생성 (10MHz)
    always @(posedge clk) begin
        if (reset) begin
            r_counter_PWM <= 4'd0;
        end else begin
            if (r_counter_PWM >= 4'd9)
                r_counter_PWM <= 4'd0;
            else
                r_counter_PWM <= r_counter_PWM + 1;
        end
    end

    assign PWM_OUT = (r_counter_PWM < r_DUTY_CYCLE) ? 1'b1 : 1'b0;
    assign PWM_OUT_LED = PWM_OUT;
    assign DUTY_CYCLE = r_DUTY_CYCLE;
    
endmodule