`timescale 1ns / 1ps
//================================================================
// Module: data_sender
// Description: 16비트 이진수 값을 4자리 ASCII 문자로 순차 전송
//================================================================
module data_sender (
    input clk,
    input reset,
    input start_trigger,       // 1Hz 틱 (전송 시작 신호)
    input [15:0] i_counter_value, // 16비트 이진수 카운터 값
    input tx_busy,             // uart_tx가 바쁜지 (Handshake)
    output reg tx_start,       // uart_tx에 보낼 1-cycle 시작 신호
    output reg [7:0] tx_data   // uart_tx에 보낼 ASCII 문자 값
);

    // ========== 1. 이진수 -> 4-Digit ASCII 변환기 (조합 논리) ========== //
    // 16비트 이진수(i_counter_value)를 4개의 ASCII 문자로 실시간 변환
    reg [7:0] ascii_thousands, ascii_hundreds, ascii_tens, ascii_ones;

    // 이 always 블록은 clk이 없으므로 "조합 논리 회로"로 합성됩니다.
    // 즉, i_counter_value가 바뀌면 4개의 ASCII 값이 "즉시" 바뀝니다.
    always @(*) begin
        // Verilog의 나눗셈(/)과 나머지(%) 연산으로 각 10진수 자리 추출
        // (주의: 이 연산은 많은 로직을 사용하므로, 타이밍이 빡빡하면 비효율적일 수 있음)
        ascii_thousands = (i_counter_value / 1000) % 10 + 8'h30;
        ascii_hundreds  = (i_counter_value / 100)  % 10 + 8'h30;
        ascii_tens      = (i_counter_value / 10)   % 10 + 8'h30;
        ascii_ones      = (i_counter_value / 1)    % 10 + 8'h30;
    end

    // ========== 2. 4바이트 순차 전송 FSM (동기 논리) ========== //
    parameter S_IDLE = 2'b00; // 1Hz 틱 대기 상태
    parameter S_SEND = 2'b01; // 1바이트(문자 1개)를 전송 지시하는 상태
    parameter S_WAIT = 2'b10; // uart_tx가 전송 완료하기를 기다리는 상태

    reg [1:0] r_state;
    reg [1:0] r_char_index; // 보낼 문자의 인덱스 (0:천, 1:백, 2:십, 3:일)

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            r_state <= S_IDLE;
            tx_start <= 0;
            tx_data <= 0;
            r_char_index <= 0;
        end else begin
            
            tx_start <= 1'b0; // 1-cycle 펄스를 위해 기본값은 0

            case (r_state)
                // 1Hz 틱을 기다리는 대기 상태
                S_IDLE: begin
                    // 1Hz 틱이 왔고, uart_tx가 쉬고 있으면(ready)
                    if (start_trigger && !tx_busy) begin
                        r_state <= S_SEND;
                        r_char_index <= 0; // 0번 인덱스(천의 자리)부터 전송 시작
                    end
                end

                // 1바이트(문자 1개)를 전송 지시하는 상태
                S_SEND: begin
                    // r_char_index에 따라 보낼 문자(tx_data) 선택
                    case (r_char_index)
                        0: tx_data <= ascii_thousands; // 천의 자리 문자
                        1: tx_data <= ascii_hundreds;  // 백의 자리 문자
                        2: tx_data <= ascii_tens;      // 십의 자리 문자
                        3: tx_data <= ascii_ones;      // 일의 자리 문자
                    endcase
                    
                    tx_start <= 1'b1; // uart_tx 모듈에 "송신 시작!" 신호
                    r_state <= S_WAIT; // "송신 완료 대기" 상태로 이동
                end

                // uart_tx가 송신을 완료하기를 기다리는 상태
                S_WAIT: begin
                    // tx_start가 0이 되고, tx_busy가 0이 되면 (전송 완료)
                    if (!tx_start && !tx_busy) begin
                        if (r_char_index == 2'd3) begin
                            // 마지막 문자(일의 자리)까지 다 보냈으면 IDLE로
                            r_state <= S_IDLE;
                        end else begin
                            // 아직 보낼 문자가 남았으면
                            r_state <= S_SEND; // 다시 "전송" 상태로
                            r_char_index <= r_char_index + 1; // 다음 문자 인덱스
                        end
                    end
                end
                
                default: r_state <= S_IDLE;
            endcase
        end
    end
endmodule