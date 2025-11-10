`timescale 1ns / 1ps

module top_btn_tick(
    input clk,
    input reset,
    input btnC,
    output led
    );

    wire w_tick;
    wire w_btn_pulse;

    tick_generator u_tick_generator(
        .clk(clk),
        .reset(reset),
        .tick(w_tick)
    );

    btn_debounce_tick u_btn_debounce_tick(
        .i_clk(clk),
        .i_reset(reset),
        .i_tick(w_tick),           // 1kHz tick (1ms마다)
        .i_btn(btnC),
        .o_btn_pulse(w_btn_pulse)
    );

    led_toggle_tick u_led_toggle_tick(
        .i_clk(clk),
        .i_reset(reset),
        .i_btn_pulse(w_btn_pulse),
        .o_led(led)
    );

endmodule
