`timescale 1ns / 1ps

module pwm_dcmotor_dht11(
    input clk,
    input reset,
    input motor_on,
    input [7:0]temp_INT_out,
    input [7:0]temp_REAL_out,
    output reg pwm_out
);
    
    //모터 속도
    reg [7:0] DUTY_CYCLE=0;
    
    parameter DUTY_CYCLE_FAST = 180 ;   
    parameter DUTY_CYCLE_NORMAL = 128;  
    parameter DUTY_CYCLE_SLOW = 90;        

    // 기준 25도 3섹션으로 나눌예정, 상(30이상) 중(20~30) 하(20이하)
    localparam  STD_TOP = 30,   //30도
                STD_BTM = 20;   //20도

    // wire [31:0]temp_total = {temp_INT_out,temp_REAL_out}; //온도 다 합 했음  32비트

    reg [7:0] clk_div; //클럭이 너무 빨라서 모터드라이버가 인식 못할수도있기때문에 추가함

    //=====PWM 주기 생성=====//
    reg [7:0] pwm_cnt;
    
    always @(posedge clk or posedge reset) begin
        if(reset) begin
            pwm_cnt <= 0;
            clk_div <= 0;
        end else begin
            if (clk_div >= 199) begin
                clk_div <= 0;
                pwm_cnt <= pwm_cnt + 1;
            end else begin
                clk_div <= clk_div + 1;
            end
        end
    end

    //=====PWM 출력 로직=====//
    always @(posedge clk or posedge reset) begin
        if(reset)  begin
            pwm_out <= 0;
        end else if(motor_on) begin

            if(temp_INT_out <= STD_BTM) begin//상(30이상)
                DUTY_CYCLE <= DUTY_CYCLE_SLOW;

            end else if (temp_INT_out > STD_BTM && temp_INT_out < STD_TOP) begin
                DUTY_CYCLE <= DUTY_CYCLE_NORMAL;

            end else if(temp_INT_out >= STD_TOP) begin
                DUTY_CYCLE <= DUTY_CYCLE_FAST;
            end 

            pwm_out <= (pwm_cnt < DUTY_CYCLE); //카운터가 DUTY_CYCLE보다 작을 때만 High 출력
        end  else
            pwm_out <= 0;
    end
    
endmodule