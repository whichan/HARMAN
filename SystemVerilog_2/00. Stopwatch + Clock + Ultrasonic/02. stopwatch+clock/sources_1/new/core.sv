`timescale 1ns / 1ps

module core(
    input              clk,
    input              reset,
    input              mode,
    input              run_stop,
    input              clear,
    output logic [6:0] o_msec,
    output logic [5:0] o_sec,
    output logic [5:0] o_min,
    output logic [5:0] o_hour,
    output logic       led1, 
    output logic       led2
    );

    logic w_mode, w_run_stop, w_clear;

    ControlUnit U_Control_Unit(
        .clk(clk),
        .reset(reset),
        .i_mode(mode),
        .i_run(run_stop),
        .i_clear(clear),
        .o_mode(w_mode),
        .o_run(w_run_stop),
        .o_clear(w_clear),
        .led1(led1),
        .led2(led2)
    );

    datapath U_Datapath(
        .clk(clk),
        .reset(reset),
        .run(w_run_stop),
        .clear(w_clear),
        .mode(w_mode),
        .o_msec(o_msec),
        .o_sec(o_sec),
        .o_min(o_min),
        .o_hour(o_hour)
    );

endmodule
