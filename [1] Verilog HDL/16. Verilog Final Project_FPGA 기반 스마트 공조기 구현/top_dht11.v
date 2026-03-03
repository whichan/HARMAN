`timescale 1ns / 1ps

module top_dht11(
    input clk,
    input reset, // switch[15]
    input [4:0] sw, // Switch 0: FND 모드 전환용 (0: 시계, 1: 온습도)

    // 버튼
    input btnL,
    input btnR,
    input btnU,
    input btnC,
    input btnD,
    
    // rotary input
    input s1, // A상
    input s2, // B상
    input key, // key

    // inout
    inout dht11_data,

    // UART
    input RsRx,
    output RsTx,

    // Output devices
    output [7:0] seg,
    output [3:0] an,
    output [15:0] led,
    output motor_pwm,
    output buzzer,
    output [1:0] dcmotor_dir

    /*output [7:0] o_humi_INT,
    output [7:0] o_humi_REAL,
    output [7:0] o_temp_INT,
    output [7:0] o_temp_REAL*/


    );
    
    wire w_tick_1s, w_tick_1khz;
    wire w_btnL_debounced, w_btnR_debounced, w_btnU_debounced, w_btnC_debounced, w_btnD_debounced;
    wire w_door_is_open;

    wire w_add_min_event, w_add_sec_event, w_countdown_event, w_clear_event, w_time_is_zero;
    wire w_buzzer_on, w_motor_on;
    
    wire [1:0] w_fnd_mode_from_fsm; // FSM에서 오는 모드
    wire [1:0] w_final_fnd_mode;    // FND로 들어가는 최종 모드
    wire [13:0] w_seg_data;
    
    wire [7:0] w_final_temp_INT_out;    // pwm_motor로 들어가는 최종 모드
    wire [2:0] w_final_motor_on;
    // DHT11 관련 와이어 (uart_top과 fnd_controller를 이어주는 다리 역할)
    wire [7:0] w_humi_INT_out;   
    wire [7:0] w_humi_REAL_out;   
    wire [7:0] w_temp_INT_out;  
    wire [7:0] w_temp_REAL_out;
    wire w_dht_data_valid; 
    wire w_dht_error_flag; 

    clock_divider_dht11 u_clock_divider_dht11(
        .clk(clk),
        .reset(reset),
        .tick_1s(w_tick_1s), 
        .tick_1khz(w_tick_1khz)
    );
    
    debouncer_dht11 u_btnL_debouncer_dht11(.clk(clk), .reset(reset), .noisy_btn(btnL), .clean_btn(w_btnL_debounced));
    debouncer_dht11 u_btnR_debouncer_dht11(.clk(clk), .reset(reset), .noisy_btn(btnR), .clean_btn(w_btnR_debounced));
    debouncer_dht11 u_btnU_debouncer_dht11(.clk(clk), .reset(reset), .noisy_btn(btnU), .clean_btn(w_btnU_debounced));
    debouncer_dht11 u_btnC_debouncer_dht11(.clk(clk), .reset(reset), .noisy_btn(btnC), .clean_btn(w_btnC_debounced));
    debouncer_dht11 u_btnD_debouncer_dht11(.clk(clk), .reset(reset), .noisy_btn(btnD), .clean_btn(w_btnD_debounced));

    fsm_controller_dht11 u_fsm_controller_dht11(
        .clk(clk),
        .reset(reset),
        .tick_1s(w_tick_1s),
        .btnU(w_btnU_debounced),
        .btnR(w_btnR_debounced),
        .btnC(w_btnC_debounced),
        .btnD(w_btnD_debounced),
        .door_is_open(w_door_is_open), 
        .time_is_zero(w_time_is_zero), 
        .add_min_event(w_add_min_event),
        .add_sec_event(w_add_sec_event),
        .countdown_event(w_countdown_event),
        .clear_event(w_clear_event),
        .fnd_mode(w_fnd_mode_from_fsm), 
        .motor_on(w_motor_on), 
        .buzzer_on(w_buzzer_on)
    );

    bcd_timer_dht11 u_bcd_timer_dht11(
        .clk(clk),
        .reset(reset),
        .add_min_event(w_add_min_event),
        .add_sec_event(w_add_sec_event),
        .countdown_event(w_countdown_event),
        .clear_event(w_clear_event),
        .seg_data_out(w_seg_data), 
        .time_is_zero(w_time_is_zero)
    );
    
    localparam TEMP_40C =8'd40;  //40
    localparam TEMP_25C =8'd25;  //25
    localparam TEMP_10C =8'd10;  //10
    assign w_final_temp_INT_out =   (sw[3]) ? TEMP_40C :                //sw[2:1]이 1 _ _ 이면 40
                                    (sw[2]) ? TEMP_25C :                //sw[2:1]이 0 1 _ 이면 25
                                    (sw[1]) ? TEMP_10C : w_temp_INT_out;//sw[2:1]이 0 0 1 이면 10, 0 0 0이면 w_temp_INT_out
                                                                                            
                                                                                            

    assign w_final_motor_on = (sw[4])? 1 : w_motor_on;
 
    pwm_dcmotor_dht11 u_pwm_dcmotor_dht11(
        .clk(clk),
        .reset(reset),
        .motor_on(w_final_motor_on),
        .temp_INT_out(w_final_temp_INT_out),
        .temp_REAL_out(w_temp_REAL_out),
        .pwm_out(motor_pwm)

    );

    /*pwm_servomotor u_pwm_servomotor(
        .clk(clk), 
        .reset(reset),
        .btnL(w_btnL_debounced),         
        .pwm_servo(servo_pwm),   
        .door_is_open(w_door_is_open)
    );*/
    
    // FND 모드 결정 (스위치 0번이 1이면 온습도 모드, 0이면 FSM 모드)
    assign w_final_fnd_mode = (sw[0]) ? 2'b11 : w_fnd_mode_from_fsm;
    
    fnd_controller_dht11 u_fnd_controller_dht11(
        .clk(clk),
        .reset(reset), 
        .tick_1khz(w_tick_1khz),    
        .tick_1s(w_tick_1s),      
        .fnd_mode_in(w_final_fnd_mode),  
        .seg_data_in(w_seg_data), 
        
        // DHT11 데이터 연결 (uart_top에서 받아온 값 사용)
        .humi_INT_out(w_humi_INT_out),   
        .humi_REAL_out(w_humi_REAL_out),   
        .temp_INT_out(w_final_temp_INT_out),  
        .temp_REAL_out(w_temp_REAL_out),
        .data_valid(w_dht_data_valid), 

        .an(an),    
        .seg(seg)
    );

    buzzer_driver_dht11 u_buzzer_driver_dht11(
        .clk(clk),          
        .reset(reset),        
        .buzzer_on(w_buzzer_on),    
        .tick_1khz(w_tick_1khz),    
        .buzzer_out(buzzer)
    );

    ////////////////////////////////////////////////
    uart_top_dht11 u_uart_top_dht11(
        .clk(clk),
        .reset(reset),
        .RsRx(RsRx),
        .dht11_pin_top_level(dht11_data), // 물리적 핀 연결
        .led(led),                        // LED 제어권도 넘김
        .RsTx(RsTx),
        
        // 여기서 나온 데이터를 Top의 와이어로 연결 (Source)
        .humi_INT_out(w_humi_INT_out),
        .humi_REAL_out(w_humi_REAL_out),
        .temp_INT_out(w_temp_INT_out),
        .temp_REAL_out(w_temp_REAL_out),

        .data_valid_out(w_dht_data_valid),
        .error_flag_out(w_dht_error_flag)
    );
    assign dcmotor_dir[0] =1'b0;
    assign dcmotor_dir[1] =1'b1;


    assign o_humi_INT = w_humi_INT_out;
    assign o_humi_REAL = w_humi_REAL_out;
    assign o_temp_INT = w_temp_INT_out;
    assign o_temp_REAL = w_temp_REAL_out;

endmodule