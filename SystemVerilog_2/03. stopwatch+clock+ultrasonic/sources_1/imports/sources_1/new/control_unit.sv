`timescale 1ns / 1ps

module ControlUnit (
    input  logic       clk,
    input  logic       reset,
    input  logic       i_mode,
    input  logic       i_run,
    input  logic       i_clear,
    input  logic       i_ultrasonic,   //ultrasonic 측정 버튼
    output logic [1:0] o_mode,
    output logic       o_run,
    output logic       o_clear,
    output logic       o_ultra_start,
    output logic       led1,           //clock
    output logic       led2,           //stopwatch
    output logic       led3            //ultrasonic
);

  typedef enum logic [1:0] {
    TIME_MODE,
    STOPWATCH_MODE,
    ULTRASONIC_MODE
  } mode_state_t;

  typedef enum logic [1:0] {
    STOP,
    RUN,
    CLEAR
  } stopwatch_state_t;

  typedef enum logic [1:0] {
    IDLE,  //버튼 대기
    TRIG   //trig 10us 출력
  } ultrasonic_state_t;

  mode_state_t mode_state, mode_state_next;
  stopwatch_state_t stopwatch_state, stopwatch_state_next;
  ultrasonic_state_t ultrasonic_state, ultrasonic_state_next;

  ////////////////////////////////////////////////////////////////////////
  //MODE STATE CIRCUIT
  ////////////////////////////////////////////////////////////////////////

  // //current mode state update sequencial circuit
  // always_ff @( posedge clk, posedge reset ) begin
  //     if(reset) begin
  //         mode_state <= TIME_MODE;        
  //     end else begin
  //         mode_state <= mode_state_next;
  //     end  
  // end

  // //next state combinational circuit
  // //다음 상태를 동작하기 위한 판단
  // always_comb begin
  //     mode_state_next = mode_state;
  //     case(mode_state)
  //         TIME_MODE: begin
  //             if(i_mode) mode_state_next = STOPWATCH_MODE;
  //             else mode_state_next = TIME_MODE;
  //         end

  //         STOPWATCH_MODE: begin
  //             if(i_mode) mode_state_next = TIME_MODE;
  //             else mode_state_next = STOPWATCH_MODE;
  //         end
  //     endcase
  // end

  // //출력
  // //현재 상태에 영향을 받지 않으니까 current와 next를 분리하지 않아도 됨
  // always_comb begin
  //     o_mode = 1'b0;
  //     led1 = 1'b0;
  //     led2 = 1'b0;

  //     case(mode_state)
  //         TIME_MODE: begin
  //             o_mode = 1'b0;
  //             led1   = 1'b1;
  //             led2   = 1'b0;
  //         end

  //         STOPWATCH_MODE: begin
  //             o_mode = 1'b1;
  //             led1   = 1'b0;
  //             led2   = 1'b1;
  //         end
  //     endcase
  // end

  always_ff @(posedge clk or posedge reset) begin
    if (reset) begin
      mode_state       <= STOPWATCH_MODE;
      stopwatch_state  <= STOP;
      ultrasonic_state <= IDLE;
    end else begin
      mode_state <= mode_state_next;
      stopwatch_state <= stopwatch_state_next;
      ultrasonic_state <= ultrasonic_state_next;
    end
  end


  //조합

  always_comb begin
    mode_state_next = mode_state;
    stopwatch_state_next = stopwatch_state;
    ultrasonic_state_next = ultrasonic_state;
    o_mode = 2'b0;
    o_run = 1'b0;
    o_clear = 1'b0;
    o_ultra_start = 1'b0;
    led1 = 1'b0;
    led2 = 1'b0;
    led3 = 1'b0;


    //===== mode제어 =====//
    case (mode_state)
      TIME_MODE: begin
        if (i_mode) mode_state_next = STOPWATCH_MODE;
        o_mode = 2'b00;
        led1   = 1'b1;
        led2   = 1'b0;
        led3   = 1'b0;
      end
      STOPWATCH_MODE: begin
        if (i_mode) mode_state_next = ULTRASONIC_MODE;
        o_mode = 2'b01;
        led1   = 1'b0;
        led2   = 1'b1;
        led3   = 1'b0;
      end

      ULTRASONIC_MODE: begin
        if (i_mode) mode_state_next = TIME_MODE;
        o_mode = 2'b10;
        led1   = 1'b0;
        led2   = 1'b0;
        led3   = 1'b1;
      end
    endcase

    //===== stopwatch mode 제어 =====//
    case (stopwatch_state)
      STOP: begin
        if (i_clear) stopwatch_state_next = CLEAR;
        else if (i_run) stopwatch_state_next = RUN;
        o_run   = 1'b0;
        o_clear = 1'b0;
      end
      RUN: begin
        if (i_clear) stopwatch_state_next = CLEAR;
        else if (i_run) stopwatch_state_next = STOP;
        o_run   = 1'b1;
        o_clear = 1'b0;
      end
      CLEAR: begin
        stopwatch_state_next = RUN;
        o_run = 1'b0;
        o_clear = 1'b1;
      end
    endcase

    //===== 초음파모드 제어 =====//
    case (ultrasonic_state)
      IDLE: begin
        if (i_ultrasonic) ultrasonic_state_next = TRIG;
        else ultrasonic_state_next = IDLE;
        o_ultra_start = 1'b0;
      end
      TRIG: begin
        ultrasonic_state_next = IDLE;
        o_ultra_start = 1'b1;
      end
    endcase
  end

  //1. 업데이트 2. 판단 3. 출력 이 가장 기본 구조

  ////////////////////////////////////////////////////////////////////////
  //STOPWATCH MODE STATE CIRCUIT
  ////////////////////////////////////////////////////////////////////////

  // //current mode state update sequencial circuit
  // always_ff @( posedge clk, posedge reset ) begin
  //     if(reset) begin
  //         stopwatch_state <= STOP;       
  //     end else begin
  //         stopwatch_state <= stopwatch_state_next;
  //     end  
  // end

  // //next state combinational circuit
  // //다음 상태를 동작하기 위한 판단
  // always_comb begin
  //     stopwatch_state_next = stopwatch_state; //현상태 계속 유지

  //     case(stopwatch_state)
  //         STOP: begin
  //             if(i_clear) stopwatch_state_next = CLEAR;
  //             else if(i_run) stopwatch_state_next = RUN;
  //             else stopwatch_state_next = STOP;
  //         end

  //         RUN: begin
  //             if(i_clear) stopwatch_state_next = CLEAR;
  //             else if(i_run) stopwatch_state_next = STOP;
  //             else stopwatch_state_next = RUN;
  //         end

  //         CLEAR: begin
  //             stopwatch_state_next = STOP;
  //         end
  //     endcase
  // end

  // //출력
  // always_comb begin
  //     o_run = 1'b0;
  //     o_clear = 1'b0;
  //     case(stopwatch_state)
  //         STOP: begin
  //             o_run = 1'b0;
  //             o_clear = 1'b0;
  //         end

  //         RUN: begin
  //             o_run = 1'b1;
  //             o_clear = 1'b0;
  //         end

  //         CLEAR: begin
  //             o_run = 1'b0;
  //             o_clear = 1'b1;
  //         end
  //     endcase
  // end
endmodule
