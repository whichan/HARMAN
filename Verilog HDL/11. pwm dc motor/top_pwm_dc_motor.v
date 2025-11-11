`timescale 1ns / 1ps

module top_pwm_dcmotor (
    input clk,   // 100MHz clock input 
    input reset,
    input increase_duty_btn,   // input to increase 10% duty cycle 
    input decrease_duty_btn,   // input to decrease 10% duty cycle 
    input [1:0] motor_direction,  // sw0 sw1 : motor direction
    output PWM_OUT,       // 10MHz PWM output signal 
    output PWM_OUT_LED,
    output [1:0] in1_in2,  // motor direction switch sw[0] sw[1]
    output [3:0] an,    // anode signals of the 7-segment LED display
    output [6:0] seg,    // cathode patterns of the 7-segment LED display
    output dp
    /*
      in1   in2
        0    1   :  역방향 회전
        1    0   :  정방향 회전
        1    1   :  브레이크
    */
    );

    wire w_debounced_inc_btn;
    wire w_debounced_dec_btn;
    wire [3:0] w_DUTY_CYCLE;

    debouncer u_increase_duty_btn(
      .clk(clk),
      .reset(reset),
      .noisy_btn(increase_duty_btn),
      .clean_btn(),
      .clean_btn_edge(w_debounced_inc_btn)
    );

    debouncer u_decrease_duty_btn(
      .clk(clk),
      .reset(reset),
      .noisy_btn(decrease_duty_btn),
      .clean_btn(),
      .clean_btn_edge(w_debounced_dec_btn)
    );
	
    pwm_duty_cycle_control u_pwm_duty_cycle_control (
        .clk(clk),
        .reset(reset),
        .duty_inc(w_debounced_inc_btn),
        .duty_dec(w_debounced_dec_btn),
        .DUTY_CYCLE(w_DUTY_CYCLE),
        .PWM_OUT(PWM_OUT),       // 10MHz PWM output signal 
        .PWM_OUT_LED(PWM_OUT_LED)
    );

    fnd_display u_fnd_display (
        .clock_100Mhz(clk),
        .reset(reset),     
        .in1_in2(in1_in2),  
        .display_number(w_DUTY_CYCLE),    
        .an(an),     
        .seg(seg),
        .dp(dp)     
    );

    assign in1_in2 = motor_direction;

endmodule