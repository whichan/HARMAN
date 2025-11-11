`timescale 1ns / 1ps

module top_buzzer(
    input clk,
    input reset, // switch[15]
    input btnL,
    input btnR,
    output buzzer
    );
    
    wire w_debounced_btnL, w_debounced_btnR;

    debouncer u_btnL_debouncer(
        .clk(clk),
        .reset(reset),
        .noisy_btn(btnL),
        .clean_btn(w_debounced_btnL)
    );

    debouncer u_btnR_debouncer(
        .clk(clk),
        .reset(reset),
        .noisy_btn(btnR),
        .clean_btn(w_debounced_btnR)
    );

    play_buzzer u_play_buzzer(
        .clk(clk),
        .reset(reset),
        .btnL(w_debounced_btnL),
        .btnR(w_debounced_btnR),
        .buzzer(buzzer)
    );
    
    

endmodule
