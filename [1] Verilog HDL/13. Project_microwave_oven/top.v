`timescale 1ns / 1ps

module top(
    input clk,
    input reset, //switch[15]
    input btnL,
    input btnR,
    input btnU,
    input btnC,
    input btnD,
    output [7:0] seg,
    output [3:0] an,
    output pwm_servo_out,
    output pwm_dcmotor_out,
    output buzzer_out,
    output [1:0] dcmotor_dir
    );
    
    wire w_tick_1s, w_tick_1khz;
    wire w_btnL_debounced, w_btnR_debounced, w_btnU_debounced, w_btnC_debounced, w_btnD_debounced;
    wire w_door_is_open;

    wire w_add_min_event, w_add_sec_event, w_countdown_event, w_clear_event, w_time_is_zero;
    wire w_buzzer_on, w_motor_on;
    wire [1:0] w_fnd_mode;
    
    wire [13:0] w_seg_data;
    

    clock_divider u_clock_divider(
        .clk(clk),
        .reset(reset),
        .tick_1s(w_tick_1s), //1초 틱(타이머, fnd animation용)
        .tick_1khz(w_tick_1khz)
    );
    
    debouncer u_btnL_debouncer(
        .clk(clk),
        .reset(reset),
        .noisy_btn(btnL),
        .clean_btn(w_btnL_debounced)
    );

    debouncer u_btnR_debouncer(
        .clk(clk),
        .reset(reset),
        .noisy_btn(btnR),
        .clean_btn(w_btnR_debounced)
    );

    debouncer u_btnU_debouncer(
        .clk(clk),
        .reset(reset),
        .noisy_btn(btnU),
        .clean_btn(w_btnU_debounced)
    );

    debouncer u_btnC_debouncer(
        .clk(clk),
        .reset(reset),
        .noisy_btn(btnC),
        .clean_btn(w_btnC_debounced)
    );

    debouncer u_btnD_debouncer(
        .clk(clk),
        .reset(reset),
        .noisy_btn(btnD),
        .clean_btn(w_btnD_debounced)
    );

    fsm_controller u_fsm_controller(
        .clk(clk),
        .reset(reset),
        .tick_1s(w_tick_1s),
        .btnU(w_btnU_debounced),
        .btnR(w_btnR_debounced),
        .btnC(w_btnC_debounced),
        .btnD(w_btnD_debounced),
        .door_is_open(w_door_is_open), //pwm_servomotor에서부터 받음
        .time_is_zero(w_time_is_zero), //시간이 00:00이 됐을 때. bcd_timer로부터 받음

        .add_min_event(w_add_min_event),
        .add_sec_event(w_add_sec_event),
        .countdown_event(w_countdown_event),
        .clear_event(w_clear_event),
        .fnd_mode(w_fnd_mode), //00:time, 01:play, 10:end
        .motor_on(w_motor_on), //pwm_dcmotor로
        .buzzer_on(w_buzzer_on)
    );

    bcd_timer u_bcd_timer(
        .clk(clk),
        .reset(reset),
        .add_min_event(w_add_min_event),
        .add_sec_event(w_add_sec_event),
        .countdown_event(w_countdown_event),
        .clear_event(w_clear_event),
        .seg_data_out(w_seg_data), //fnd_controller로
        .time_is_zero(w_time_is_zero)
    );

    pwm_dcmotor u_pwm_dcmotor(
        .clk(clk),
        .reset(reset),
        .motor_on(w_motor_on),
        .pwm_out(pwm_dcmotor_out)
    );

    pwm_servomotor u_pwm_servomotor(
        .clk(clk), 
        .reset(reset),
        .btnL(w_btnL_debounced),         
        .pwm_servo(pwm_servo_out),   //서보 모터로 가는 실제 PWM 펄스
        .door_is_open(w_door_is_open)
    );

    fnd_controller u_fnd_controller(
        .clk(clk),
        .reset(reset), 
        .tick_1khz(w_tick_1khz),    // (clock_divider) 1ms 틱 (스캔용)
        .tick_1s(w_tick_1s),      // (clock_divider) 1s 틱 (애니메이션/깜빡임용)
        // '두뇌(FSM)'로부터의 '모드' 명령
        .fnd_mode_in(w_fnd_mode),   // 00: Time, 01: Play, 10: End
        // '타이머(BCD)'로부터의 'BCD 데이터'
        .seg_data_in(w_seg_data), // {min_t, min_o, sec_t, sec_o}
        .an(an),    // 4-Digit Anode (Common Anode)
        .seg(seg)
    );

    buzzer_driver u_buzzer_driver(
        .clk(clk),          // 100MHz 클럭
        .reset(reset),        // Active-High 리셋
        .buzzer_on(w_buzzer_on),    
        .tick_1khz(w_tick_1khz),    
        .buzzer_out(buzzer_out)
    );

    assign dcmotor_dir[0] = 1'b1;
    assign dcmotor_dir[1] = 1'b0;
    
endmodule
