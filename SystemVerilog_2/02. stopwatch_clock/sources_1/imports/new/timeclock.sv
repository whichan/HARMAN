`timescale 1ns / 1ps

module TimeClock (
    input  logic       clk,
    input  logic       reset,
    input  logic       mode_sw,
    output logic [3:0] fnd_com,
    output logic [7:0] fnd_font

);
    logic [5:0] sec, min, hour;
    logic [6:0] msec;

    clock_core U_TimeClockCore (.*);
    fndController U_Display (.*);

endmodule