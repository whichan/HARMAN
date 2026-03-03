`timescale 1ns / 1ps



module top(
    input clk,
    input reset,        //btnU
    input btnL,         // 아직 사용 X
    input s1,           // JC1
    input s2,           // JC2
    input key,
    output [15:0] led,
    output [3:0] an,
    output [7:0] seg
    );


    wire w_clean_btn;
    wire w_clean_s1, w_clean_s2, w_clean_key;       // rotary

        debouncer u_btnL_debouncer (          // debounce time : 2ms(200_000ns)
        .clk(clk),
        .reset(reset),
        .noisy_btn(btnL),  // raw noisy button input
        .clean_btn(w_clean_btn)
    );


    debouncer #(.DEBOUNCE_LIMIT(200)) u_s1_debouncer (          // debounce time : 2000ns
        .clk(clk),
        .reset(reset),
        .noisy_btn(s1),  // raw noisy button input
        .clean_btn(w_clean_s1)
    );

    debouncer #(.DEBOUNCE_LIMIT(200)) u_s2_debouncer (          // debounce time : 2000ns
        .clk(clk),
        .reset(reset),
        .noisy_btn(s2),  // raw noisy button input
        .clean_btn(w_clean_s2)
    );

    debouncer #(.DEBOUNCE_LIMIT(200_000)) u_key_debouncer (          // debounce time : 2_000_000ns(2ms)
        .clk(clk),
        .reset(reset),
        .noisy_btn(key),  // raw noisy button input
        .clean_btn(w_clean_key)
    );

    rotary u_rotary(
        .clk(clk),
        .reset(reset),
        .clean_s1(w_clean_s1),
        .clean_s2(w_clean_s2),
        .clean_key(w_clean_key),
        .led(led)
    );

    fnd_controller u_fnd_controller(
        .clk(clk),
        .reset(reset),
        .r_count(led[7:0]), //0~255. LED[0] ~ LED[7]로 카운팅
        .r_direction(led[15:14]), //시계방향: F, 반시계방향: b
        .an(an),
        .seg(seg)
    );

endmodule