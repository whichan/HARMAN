`timescale 1ns / 1ps

module top_stopwatch(
    input reset,
    input clk,
    input [2:0] btn,
    output [7:0] seg,
    output [15:0] led,
    output [3:0] an,
    output switch_to_minsec //밖으로 연결되는 출력(분초시계와 switch)
    );


wire [2:0] w_btn_debounced;
wire [13:0] w_seg_data;
wire w_is_idle_anim;
wire [3:0] w_anim_step;

btn_debouncer u_btn_debouncer(
    .clk(clk),
    .reset(reset),
    .btn(btn),   // 3개의 버튼 입력: btn[2:0] → 각각 btnL, btnC, btnR
    .debounced_btn(w_btn_debounced)
);

btn_command_controller u_btn_command_controller(
    .clk(clk),
    .reset(reset),
    .btn(w_btn_debounced),
    .led(led),
    .seg_data(w_seg_data),
    .switch_to_minsec(switch_to_minsec),
    .is_idle_anim(w_is_idle_anim), //현재 idle animation 상태인가?
    .anim_step(w_anim_step)
);

fnd_controller u_fnd_controller(
    .clk(clk),
    .reset(reset),   // btnU
    .in_data(w_seg_data),
    .is_idle_anim(w_is_idle_anim), //IDLE animation 활성화 
    .anim_step(w_anim_step), //애니메이션 step
    .an(an),
    .seg(seg)

);


    
endmodule