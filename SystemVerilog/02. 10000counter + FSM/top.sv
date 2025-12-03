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
        .mode(mode),
        .run_stop(run_stop),
        .clear(clear),
    
        .o_mode(w_mode),
        .o_run_stop(w_run_stop),
        .o_clear(w_clear)
    );

    
endmodule