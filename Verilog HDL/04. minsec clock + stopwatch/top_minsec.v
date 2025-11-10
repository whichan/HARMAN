`timescale 1ns / 1ps

module top_minsec(
    input clk,
    input reset,
    input [2:0] btn,
    output [7:0] seg,
    output [3:0] an,
    output [15:0] led,
    output switch_to_stopwatch
    );

wire w_dp_blink;
wire [2:0] w_btn_debounced;
wire [13:0] w_seg_data;

btn_debouncer u_btn_debouncer(
    .clk(clk),
    .reset(reset),
    .btn(btn),
    .debounced_btn(w_btn_debounced)
);

btn_command_controller_minsec u_btn_command_controller_minsec(
    .clk(clk),
    .reset(reset), //btnU
    .btn(w_btn_debounced), //btnC: 모드 바꿈   btnR: 재생
    .led(led),  //현재 상태 표시용
    .seg_data(w_seg_data),  //FND에 표시할 9,999 값
    .switch_to_stopwatch(switch_to_stopwatch),
    .dp_blink(w_dp_blink)
);


fnd_controller u_fnd_controller(
    .clk(clk),
    .reset(reset),   // btnU
    .in_data(w_seg_data),
    .dp_blink_in(w_dp_blink),
    .an(an),
    .seg(seg)
);

endmodule