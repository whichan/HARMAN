`timescale 1ns / 1ps

module top_ds1302(
    input clk,
    input reset,
    /*input btnU,
    input btnR,
    input btnL,
    input btnC,*/
    input btnD, //알람 해제
    input s1,    // Rotary A
    input s2,    // Rotary B
    input key,   // Rotary Switch
    input RsRx,

    inout ds1302_io, 

    output ds1302_sclk, 
    output ds1302_ce, 
    output RsTx,
    
    output [7:0] seg,
    output [3:0] an,
    output [15:0] led,

    output buzzer,

    //추가: ssd1306으로 들어가는 시간값
    output [7:0] o_hour,
    output [7:0] o_min,
    output [7:0] o_sec
);


wire w_tick_1mhz, w_tick_1hz, w_tick_1khz;
wire [7:0] w_hour, w_min, w_sec;
wire w_rtc_read_done;
wire w_tx_start, w_busy;
wire [7:0] w_tx_byte;
wire w_tx_done;
wire [15:0] w_fnd_bcd_data;
wire w_rotary_cw, w_rotary_ccw, w_sw_toggle;
wire w_is_rotating;
wire [7:0] w_new_min, w_new_sec;
wire [7:0] w_final_min, w_final_sec;
wire w_mode_is_sec;

wire w_alarm_active, w_buzzer_trigger;


//추가: ssd1306으로 들어가는 시간값
assign o_hour = w_hour;
assign o_min = w_min;
assign o_sec = w_sec;

//===================================================
// [수정 1] 토글 신호의 변화 감지 (Edge Detection)
//===================================================
reg r_old_toggle;
wire w_toggle_changed;

// 이전 상태 저장
always @(posedge clk) begin
    r_old_toggle <= w_sw_toggle;
end

// 현재 상태와 이전 상태가 다르면 1 (변화 감지)
assign w_toggle_changed = (w_sw_toggle != r_old_toggle);

// 모드 설정
assign w_mode_is_sec = w_sw_toggle; 
assign w_is_rotating = w_rotary_cw | w_rotary_ccw;


//===================================================
// [수정 2] 타이머 로직 수정 (레벨 -> 펄스 트리거)
//===================================================
reg [26:0] r_edit_timer; 
reg r_is_editing; 

always @(posedge clk or posedge reset) begin
    if (reset) begin
        r_edit_timer <= 0;
        r_is_editing <= 0;
    end else begin
        // [중요] w_sw_toggle(상태) 대신 w_toggle_changed(변화)를 사용해야 함!
        if (w_is_rotating || w_toggle_changed) begin 
            r_edit_timer <= 27'd50_000_000; // 0.5초 타이머 시작
            r_is_editing <= 1;
        end 
        else if (r_edit_timer > 0) begin
            r_edit_timer <= r_edit_timer - 1;
            r_is_editing <= 1;
        end 
        else begin
            r_is_editing <= 0;
        end
    end
end



reg r_ds1302_we;
always @(posedge clk or posedge reset) begin
    if (reset) r_ds1302_we <= 0;
    else begin
        if (w_is_rotating) r_ds1302_we <= 1;
        else r_ds1302_we <= 0;
    end
end

assign w_final_min = w_new_min;
assign w_final_sec = (!w_mode_is_sec) ? 8'h00 : w_new_sec;


tick_generator_ds1302 u_tick_generator(
    .i_clk(clk),
    .i_reset(reset),
    .o_tick_1mhz(w_tick_1mhz),
    .o_tick_1hz(w_tick_1hz),
    .o_tick_1khz(w_tick_1khz)
);

ds1302_driver u_ds1302_driver(
    .i_clk(clk),
    .i_reset(reset),
    .i_tick_1mhz(w_tick_1mhz),
    .i_tick_1hz(w_tick_1hz),
    .i_we(r_ds1302_we),
    .i_set_hour(w_hour),
    .i_set_min(w_final_min),
    .i_set_sec(w_final_sec),
    .o_ce(ds1302_ce),
    .o_sclk(ds1302_sclk),
    .io_data(ds1302_io),
    .o_hour(w_hour), 
    .o_min(w_min), 
    .o_sec(w_sec),
    .o_done_tick(w_rtc_read_done)
);

bcd_up_down_counter_ds1302 u_cnt_min(
    .clk(clk),
    .reset(reset),
    .i_load(!r_is_editing), 
    .i_load_val(w_min),
    .i_inc(w_rotary_cw && !w_mode_is_sec), 
    .i_dec(w_rotary_ccw && !w_mode_is_sec), 
    .i_max_val(8'h59),
    .o_bcd(w_new_min) 
);

bcd_up_down_counter_ds1302 u_cnt_sec(
    .clk(clk),
    .reset(reset),
    .i_load(!r_is_editing),
    .i_load_val(w_sec),
    .i_inc(w_rotary_cw && w_mode_is_sec), 
    .i_dec(w_rotary_ccw && w_mode_is_sec), 
    .i_max_val(8'h59),
    .o_bcd(w_new_sec)
);

// MUX for FND Data
assign w_fnd_bcd_data = (r_is_editing) ? {w_new_min, w_new_sec} : {w_min, w_sec};

time_to_uart_ds1302 u_time_to_uart(
    .i_clk(clk),
    .i_reset(reset),
    .i_hour(w_hour), 
    .i_min(w_min), 
    .i_sec(w_sec),
    .i_start_trigger(w_rtc_read_done),
    .i_tx_done(w_tx_done),
    .o_tx_start(w_tx_start),
    .o_tx_byte(w_tx_byte),
    .o_busy(w_busy)
);

uart_tx #(
    .CLK_FREQ(100_000_000),
    .BPS(9600)
) u_uart_tx(
    .clk(clk),
    .reset(reset),
    .tx_data(w_tx_byte),
    .tx_start(w_tx_start),
    .tx(RsTx),
    .tx_busy(),
    .tx_done(w_tx_done)
);

fnd_controller_ds1302 u_fnd_controller(
    .clk(clk),
    .reset(reset),
    .bcd_data(w_fnd_bcd_data),
    .an(an),
    .seg(seg)
);

rotary_ds1302 u_rotary(
    .clk(clk),
    .reset(reset),
    .clean_s1(s1),
    .clean_s2(s2),
    .clean_key(key),
    .o_valid_cw(w_rotary_cw), 
    .o_valid_ccw(w_rotary_ccw), 
    .o_sw_toggle(w_sw_toggle)
);

alarm_controller_ds1302 u_alarm_controller_ds1302(
    .i_clk(clk),
    .i_reset(reset),
    .i_tick_1khz(w_tick_1khz), //타이밍용 1ms 펄스
    .i_hour(w_hour),
    .i_min(w_min),
    .i_sec(w_sec),
    .i_stop_btn(btnD), //알람 끄는 버튼 (btnD)

    .o_buzzer_trigger(w_buzzer_trigger), //buzzer_driver에 보낼 시작 펄스
    .o_alarm_active(w_alarm_active)
);

buzzer_driver_ds1302 u_buzzer_driver_ds1302(
    .i_clk(clk),
    .i_reset(reset),
    .buzzer_on(w_buzzer_trigger), //alarm_controller의 o_buzzer_trigger로부터 받는 신호 (1pulse trigger)
    .tick_1khz(w_tick_1khz), //지속시간(100ms) 카운팅을 위한 1pulse trigger
    .buzzer_out(buzzer)
);

// Debug LEDs
assign led[0] = w_mode_is_sec; //led[0] ON: sec를 수정 중 / led[0] OFF: min을 수정 중
assign led[1] = r_is_editing; //rotary를 돌려서 수정 중
assign led[14:2] = 0; //led[2]~led[14]는 OFF

endmodule