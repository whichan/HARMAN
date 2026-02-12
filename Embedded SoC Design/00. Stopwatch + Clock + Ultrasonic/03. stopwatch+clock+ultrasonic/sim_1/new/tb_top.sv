`timescale 1ns / 1ps

module tb_top ();

  logic clk;
  logic reset;
  logic mode;
  logic run_stop;
  logic clear;
  logic mode_sw;
  logic ultrasonic;
  logic echo;
  logic trig;
  logic [3:0] fnd_com;
  logic [7:0] fnd_font;
  logic led1;
  logic led2;
  logic led3;

  top DUT (
      .clk(clk),
      .reset(reset),
      .mode(mode),
      .run_stop(run_stop),
      .clear(clear),
      .mode_sw(mode_sw),
      .ultrasonic(ultrasonic),
      .echo(echo),
      .trig(trig),
      .fnd_com(fnd_com),
      .fnd_font(fnd_font),
      .led1(led1),
      .led2(led2),
      .led3(led3)
  );

  initial begin
    #0;
    clk = 0;
    forever #5 clk = ~clk;
  end

  initial begin
    // 1. 초기화
    reset = 1;
    mode = 0;
    run_stop = 0;
    clear = 0;
    ultrasonic = 0;
    mode_sw = 0;
    echo = 0;

    repeat (5) @(posedge clk);  // 5클락 대기
    reset = 0;
    repeat (10) @(posedge clk);

    // 2. 모드 전환 (STOPWATCH -> ULTRASONIC)
    mode = 1;
    #100_000  // 20클락 동안 유지 (충분한 시간)
    mode = 0;
    #100_000

    // 3. 초음파 측정 시작
    ultrasonic = 1;
    #100_000;
    ultrasonic = 0;

    // 4. Echo 신호 시뮬레이션 (시간 단위 주의!)

    #10000;  // 센서 내부 처리 시간 대기 (10us)
    echo = 1;
    #5800000;  // 100cm 거리 시뮬레이션
    echo = 0;

    #10000;

    // 3. 초음파 측정 시작
    ultrasonic = 1;
    #100_000;
    ultrasonic = 0;

    // 4. Echo 신호 시뮬레이션 (시간 단위 주의!)

    #10000;  // 센서 내부 처리 시간 대기 (10us)
    echo = 1;
    #5000000;  // 100cm 거리 시뮬레이션
    echo = 0;

    #100000 $stop;
  end
endmodule
