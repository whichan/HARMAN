`timescale 1ns / 1ps

module core (
    input               clk,
    input               reset,
    input               mode,
    input               run_stop,
    input               clear,
    input               echo,
    input               i_ultrasonic,
    output logic [ 6:0] o_msec,
    output logic [ 5:0] o_sec,
    output logic [ 5:0] o_min,
    output logic [ 5:0] o_hour,
    output logic        led1,
    output logic        led2,
    output logic        led3,
    output logic        trig,
    output logic [11:0] distance_cm,
    output logic [ 1:0] mode_2bit
);

  logic [1:0] w_mode;
  logic w_run_stop, w_clear;
  logic w_ultra_start;

  assign mode_2bit = w_mode;

  ControlUnit U_Control_Unit (
      .clk(clk),
      .reset(reset),
      .i_mode(mode),
      .i_run(run_stop),
      .i_clear(clear),
      .i_ultrasonic(i_ultrasonic),

      .o_mode(w_mode),
      .o_run(w_run_stop),
      .o_clear(w_clear),
      .o_ultra_start(w_ultra_start),
      .led1(led1),
      .led2(led2),
      .led3(led3)
  );

  datapath U_Datapath (
      .clk(clk),
      .reset(reset),
      .run(w_run_stop),
      .clear(w_clear),
      .echo(echo),
      .ultra_start(w_ultra_start),
      .mode(w_mode),
      .o_msec(o_msec),
      .o_sec(o_sec),
      .o_min(o_min),
      .o_hour(o_hour),
      .o_distance(distance_cm),
      .trig(trig)
  );



endmodule
