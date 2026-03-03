`timescale 1ns / 1ps
//==============================================================================
// Module: data_sender (수정: 상승 엣지 검출 추가)
// Description: 문자열을 한 글자씩 순차 전송
//==============================================================================

module data_sender(
    input clk,
    input reset,
    input start_trigger,
    input [13:0] send_data,
    input tx_busy,
    input tx_done,
    output reg tx_start,
    output reg [7:0] tx_data
);

    // ========== ROM 선언 ========== //
    parameter STRING_LENGTH = 15;  // 줄바꿈 포함 17글자
    reg [7:0] string_rom [0:STRING_LENGTH-1];

    // ========== ROM 초기화 ========== //
    initial begin
        string_rom[ 0] = 8'h48; // H
        string_rom[ 1] = 8'h65; // e
        string_rom[ 2] = 8'h6C; // l
        string_rom[ 3] = 8'h6C; // l
        string_rom[ 4] = 8'h6F; // o
        string_rom[ 5] = 8'h21; // !
        string_rom[ 6] = 8'h20; // (space)
        string_rom[ 7] = 8'h57; // W
        string_rom[ 8] = 8'h68; // h
        string_rom[ 9] = 8'h69; // i
        string_rom[10] = 8'h63; // c
        string_rom[11] = 8'h68; // h
        string_rom[12] = 8'h61; // a
        string_rom[13] = 8'h6E; // n
        string_rom[14] = 8'h20; // (space)
    end

    // ========== 상태 정의 ========== //
    parameter S_IDLE      = 3'd0;
    parameter S_LOAD_DATA = 3'd1;
    parameter S_START_BIT = 3'd2;
    parameter S_WAIT_DONE = 3'd3;
    parameter S_DELAY     = 3'd4;  // 딜레이 상태 추가

    // ========== 내부 신호 ========== //
    reg [2:0] r_state;
    reg [4:0] r_char_index;  // 5비트로 변경 (0~31까지 가능)
    reg r_start_trigger_prev;
    wire w_start_pulse;

    // ========== 상승 엣지 검출 (중요!) ========== //
    always @(posedge clk) begin
        if (reset)
            r_start_trigger_prev <= 1'b0;
        else
            r_start_trigger_prev <= start_trigger;
    end
    
    assign w_start_pulse = start_trigger && !r_start_trigger_prev;

    // ========== FSM ========== //
    always @(posedge clk) begin
        if (reset) begin
            r_state <= S_IDLE;
            r_char_index <= 4'd0;
            tx_data <= 8'd0;
            tx_start <= 1'b0;
        end else begin
            case (r_state)
                // ========== IDLE: 1초 tick 대기 ========== //
                S_IDLE: begin
                    tx_start <= 1'b0;
                    
                    // 1초 tick의 상승 엣지에서만 시작
                    if (w_start_pulse) begin
                        r_char_index <= 5'd0;  // 5비트
                        r_state <= S_LOAD_DATA;
                    end
                end

                // ========== LOAD_DATA: ROM에서 데이터 로드 ========== //
                S_LOAD_DATA: begin
                    tx_data <= string_rom[r_char_index];
                    tx_start <= 1'b0;
                    r_state <= S_START_BIT;
                end

                // ========== START_BIT: 전송 시작 ========== //
                S_START_BIT: begin
                    if (!tx_busy) begin
                        tx_start <= 1'b1;
                        r_state <= S_WAIT_DONE;
                    end
                end

                // ========== WAIT_DONE: 전송 완료 대기 ========== //
                S_WAIT_DONE: begin
                    tx_start <= 1'b0;
                    
                    if (tx_done) begin
                        if (r_char_index == STRING_LENGTH - 1) begin
                            r_state <= S_IDLE;  // 모든 문자 전송 완료
                        end else begin
                            r_char_index <= r_char_index + 1'b1;
                            r_state <= S_LOAD_DATA;  // 다음 문자
                        end
                    end
                end

                default: r_state <= S_IDLE;
            endcase
        end
    end

endmodule