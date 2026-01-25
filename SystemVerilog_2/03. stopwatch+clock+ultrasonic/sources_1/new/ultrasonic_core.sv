`timescale 1ns / 1ps

module ultrasonic_core (
    input               clk,
    input               reset,
    input               i_ultra_start,
    input               echo,           //센서의 echo핀
    output logic        trig,           //초음파센서로 나가는 trig 핀
    output logic [11:0] distance_cm
);

  typedef enum logic [2:0] {
    IDLE,
    TRIG,  //TRIG핀 10us유지
    WAIT_ECHO_POS,  //ECHO핀이 High가 될 때까지 대기
    WAIT_ECHO_NEG,  //ECHO핀이 LOW가 되기 전까지 몇us인지 count
    CALCULATE  //시간을 cm로 변환
  } state_t;
  state_t ultrasonic_state, ultrasonic_state_next;

  logic [$clog2(1_500)-1:0] cnt_10us;
  logic [$clog2(100)-1:0] cnt_1us;
  logic [14:0] echo_time_us;  //데이터시트상 400cm가 최대이기 때문

  assign trig = (ultrasonic_state == TRIG);  //TRIG상태일 때만 trig핀으로 출력



  // --- 1. 순차 로직 (상태 업데이트 및 카운터 제어) ---
  always_ff @(posedge clk or posedge reset) begin
    if (reset) begin
      ultrasonic_state <= IDLE;
      cnt_10us         <= 0;
      cnt_1us          <= 0;
      echo_time_us     <= 0;
      distance_cm      <= 100;
    end else begin
      ultrasonic_state <= ultrasonic_state_next;

      case (ultrasonic_state)
        IDLE: begin
          // 대기 상태에서는 모든 카운터 초기화
          cnt_10us     <= 0;
          cnt_1us      <= 0;
          echo_time_us <= 0;
        end

        TRIG: begin
          cnt_10us <= cnt_10us + 1;
        end

        WAIT_ECHO_NEG: begin
          if (cnt_1us == 100 - 1) begin
            cnt_1us      <= 0;
            echo_time_us <= echo_time_us + 1;
          end else begin
            cnt_1us <= cnt_1us + 1;
          end
        end

        CALCULATE: begin
          // 거리를 계산하여 레지스터에 저장 (IDLE로 가도 유지됨)
          distance_cm <= (echo_time_us * 34) / 2000;
          // distance_cm <= 200;
        end
      endcase
    end
  end

  // --- 2. 조합 로직 (다음 상태 결정) ---
  always_comb begin
    ultrasonic_state_next = ultrasonic_state;
    case (ultrasonic_state)
      IDLE: if (i_ultra_start) ultrasonic_state_next = TRIG;
      TRIG: if (cnt_10us == 1500 - 1) ultrasonic_state_next = WAIT_ECHO_POS;
      WAIT_ECHO_POS: if (echo) ultrasonic_state_next = WAIT_ECHO_NEG;
      WAIT_ECHO_NEG: if (echo == 0) ultrasonic_state_next = CALCULATE;
      CALCULATE: ultrasonic_state_next = IDLE;
      default: ultrasonic_state_next = IDLE;
    endcase
  end
endmodule
