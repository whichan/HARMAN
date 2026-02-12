`timescale 1ns / 1ps

module TimeClock (
    input  logic       clk,
    input  logic       reset,
    output logic [3:0] fnd_com,
    output logic [7:0] fnd_font

);
    logic [5:0] msec, sec, min, hour;

    Core U_TimeClockCore (.*);
    fndController U_Display (.*);

endmodule
