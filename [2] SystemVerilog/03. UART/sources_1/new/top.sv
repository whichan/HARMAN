`timescale 1ns / 1ps

module top(
    input clk,
    input reset,
    input clear,
    input run_stop,
    input mode,

    output logic [7:0] fnd_data,
    output logic [3:0] fnd_com
    );

    wire w_mode, w_run_stop, w_clear;
    wire debounced_clear, debounced_run_stop, debounced_mode;

    btn_debounce u_btn_clear(
        .clk(clk),
        .reset(reset),
        .i_btn(clear),
        .o_btn(debounced_clear)
    );

    btn_debounce u_btn_run_stop(
        .clk(clk),
        .reset(reset),
        .i_btn(run_stop),
        .o_btn(debounced_run_stop)
    );

    btn_debounce u_btn_mode(
        .clk(clk),
        .reset(reset),
        .i_btn(mode),
        .o_btn(debounced_mode)
    );



    top_10000_counter u_top_10000_counter(
        .clk(clk),
        .reset(reset),
        .clear(w_clear),
        .run_stop(w_run_stop),
        .mode(w_mode),
        .fnd_data(fnd_data),
        .fnd_com(fnd_com)
    );

    command_controller u_command_controller(
        .clk(clk),
        .reset(reset),
        .mode(debounced_mode),
        .run_stop(debounced_run_stop),
        .clear(debounced_clear),
    
        .o_mode(w_mode),
        .o_run_stop(w_run_stop),
        .o_clear(w_clear)
    );


    
endmodule