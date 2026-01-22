`timescale 1ns / 1ps

module datapath(
    input        clk,
    input        reset,
    input        run,
    input        clear,
    input        mode,
    output [6:0] o_msec,
    output [5:0] o_sec,
    output [5:0] o_min,
    output [5:0] o_hour
    );
    
    logic [6:0] w_clock_msec, w_stopwatch_msec;
    logic [5:0] w_clock_sec, w_stopwatch_sec;
    logic [5:0] w_clock_min, w_stopwatch_min;
    logic [5:0] w_clock_hour, w_stopwatch_hour;

    stopwatch_core U_Stopwatch_Core(
        .clk(clk), 
        .reset(reset),
        .run(run),
        .clear(clear),
        .msec(w_stopwatch_msec),
        .sec(w_stopwatch_sec),
        .min(w_stopwatch_min),
        .hour(w_stopwatch_hour)
    );

    clock_core U_Clock_Core(
        .clk(clk),
        .reset(reset),
        .msec(w_clock_msec),
        .sec(w_clock_sec),
        .min(w_clock_min),
        .hour(w_clock_hour)
    );

    mux_2x1 #(
        . WIDTH (7)
    )U_msMux(
        .a(w_stopwatch_msec), 
        .b(w_clock_msec),
        .sel(mode),
        .out_mux(o_msec)
    );

    mux_2x1 #(
        .WIDTH (6)
    )U_sMux(
        .a(w_stopwatch_sec), 
        .b(w_clock_sec),
        .sel(mode),
        .out_mux(o_sec)
    );

    mux_2x1 #(
        .WIDTH (6)
    )U_minMux(
        .a(w_stopwatch_min), 
        .b(w_clock_min),
        .sel(mode),
        .out_mux(o_min)
    );

    mux_2x1 #(
        .WIDTH (6)
    )U_hourMux(
        .a(w_stopwatch_hour), 
        .b(w_clock_hour),
        .sel(mode),
        .out_mux(o_hour)
    );

endmodule

module mux_2x1 #(
    parameter WIDTH = 6
)(
    input [WIDTH-1:0]  a, 
    input [WIDTH-1:0]  b,
    input              sel,
    output [WIDTH-1:0] out_mux
);

    assign out_mux = sel ? a : b;
    
endmodule