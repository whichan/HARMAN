`timescale 1ns / 1ps

module datapath (
    input               clk,
    input               reset,
    input               run,
    input               clear,
    input        [ 1:0] mode,
    input               echo,
    input               ultra_start,
    output logic [ 6:0] o_msec,
    output logic [ 5:0] o_sec,
    output logic [ 5:0] o_min,
    output logic [ 5:0] o_hour,
    output logic [11:0] o_distance,
    output              trig
);

  logic [6:0] w_clock_msec, w_stopwatch_msec;
  logic [5:0] w_clock_sec, w_stopwatch_sec;
  logic [5:0] w_clock_min, w_stopwatch_min;
  logic [5:0] w_clock_hour, w_stopwatch_hour;
  logic [11:0] w_distance_cm;

  //   assign {o_hour, o_min, o_sec, o_msec} = mode ? {w_stopwatch_hour, w_stopwatch_min, w_stopwatch_sec, w_stopwatch_msec}
  //              : {w_clock_hour, w_clock_min, w_clock_sec, w_clock_msec};


  stopwatch_core U_Stopwatch_Core (
      .clk  (clk),
      .reset(reset),
      .run  (run),
      .clear(clear),
      .msec (w_stopwatch_msec),
      .sec  (w_stopwatch_sec),
      .min  (w_stopwatch_min),
      .hour (w_stopwatch_hour)
  );

  clock_core U_Clock_Core (
      .clk  (clk),
      .reset(reset),
      .msec (w_clock_msec),
      .sec  (w_clock_sec),
      .min  (w_clock_min),
      .hour (w_clock_hour)
  );

  ultrasonic_core U_Ultrasonic_Core (
      .clk(clk),
      .reset(reset),
      .i_ultra_start(ultra_start),
      .echo(echo),
      .trig(trig),
      .distance_cm(w_distance_cm)
  );

  always_comb begin
    o_msec = 7'b0;
    o_sec = 6'b0;
    o_min = 6'b0;
    o_hour = 6'b0;
    o_distance = 11'b0;
    case (mode)
      2'b00: begin  //clock mode
        o_msec = w_clock_msec;
        o_sec  = w_clock_sec;
        o_min  = w_clock_min;
        o_hour = w_clock_hour;
      end
      2'b01: begin  //stopwatch mode
        o_msec = w_stopwatch_msec;
        o_sec  = w_stopwatch_sec;
        o_min  = w_stopwatch_min;
        o_hour = w_stopwatch_hour;
      end
      2'b10: begin  //ultrasonic mode
        o_distance = w_distance_cm;
      end
    endcase
  end

endmodule
