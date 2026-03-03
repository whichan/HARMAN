`timescale 1ns / 1ps

module pwm_dcmotor(
    input clk,
    input reset,
    input motor_on,
    output reg pwm_out
);
    
    //모터 속도
    parameter DUTY_CYCLE = 128;
    
    //=====PWM 주기 생성=====//
    reg [7:0] pwm_cnt;
    
    always @(posedge clk or posedge reset) begin
        if(reset) begin
            pwm_cnt <= 0;
        end else begin
            pwm_cnt <= pwm_cnt + 1;
        end
    end
    
    //=====PWM 출력 로직=====//
    always @(posedge clk or posedge reset) begin
        if(reset)
        pwm_out <= 0;
        else if(motor_on)
        pwm_out <= (pwm_cnt < DUTY_CYCLE); //카운터가 128보다 작을 때만 High 출력
        else
        pwm_out <= 0;
    end
    
endmodule