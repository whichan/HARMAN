`timescale 1ns / 1ps

module data_sender(
    input wire clk,
    input wire reset,
    
    input wire start_trigger,      // 's' 키가 눌렸을 때 들어오는 1-cycle 펄스
    input wire [13:0] current_cnt, // 0 ~ 9999 (14비트 이진수)
    input wire current_mode,       // 0: Down, 1: Up
    
    input wire tx_done,            // uart_tx가 한 바이트 전송을 마쳤다는 신호
    input wire tx_busy,            // uart_tx가 전송 중인지 여부
    
    output reg tx_start,           // uart_tx에게 전송 시작 명령
    output reg [7:0] tx_data,      // uart_tx에게 보낼 1바이트 데이터
    output wire busy               // 현재 문자열 패킷을 보내는 중 (외부 알림용)
    );

    // =========================================================================
    // 1. 상태 머신 정의
    // =========================================================================
    localparam S_IDLE       = 3'd0;
    localparam S_PREPARE    = 3'd1; // 이진수를 십진수 자리수로 변환하는 단계
    localparam S_LOAD_DATA  = 3'd2; // 보낼 문자를 결정하는 단계
    localparam S_SEND_START = 3'd3; // tx_start 신호를 켜는 단계
    localparam S_WAIT_DONE  = 3'd4; // 전송 완료(tx_done)를 기다리는 단계
    localparam S_CHECK_NEXT = 3'd5; // 다음 문자가 있는지 확인하는 단계

    reg [2:0] state;
    reg [4:0] char_idx; // 보낼 문자열 인덱스 (최대 32글자까지 커버)

    // =========================================================================
    // 2. Binary to BCD 변환용 레지스터
    // =========================================================================
    // current_cnt(이진수)를 천, 백, 십, 일의 자리 숫자로 쪼개서 저장
    reg [3:0] digit_th; // 천의 자리
    reg [3:0] digit_hu; // 백의 자리
    reg [3:0] digit_te; // 십의 자리
    reg [3:0] digit_on; // 일의 자리
    
    // 모드 저장용 (전송 도중에 모드가 바뀌면 안 되므로 캡처)
    reg saved_mode; 

    // busy 신호: IDLE 상태가 아니면 busy임
    assign busy = (state != S_IDLE);

    // =========================================================================
    // 3. 메인 동작 로직
    // =========================================================================
    always @(posedge clk) begin
        if (reset) begin
            state <= S_IDLE;
            tx_start <= 1'b0;
            tx_data <= 8'b0;
            char_idx <= 5'd0;
            digit_th <= 0; digit_hu <= 0; digit_te <= 0; digit_on <= 0;
            saved_mode <= 0;
        end else begin
            case (state)
                // -------------------------------------------------------------
                // 대기 상태
                // -------------------------------------------------------------
                S_IDLE: begin
                    tx_start <= 1'b0;
                    char_idx <= 5'd0;
                    
                    if (start_trigger) begin
                        state <= S_PREPARE;
                        saved_mode <= current_mode; // 현재 모드 캡처
                    end
                end

                // -------------------------------------------------------------
                // 데이터 준비 (Binary -> BCD 변환)
                // -------------------------------------------------------------
                S_PREPARE: begin
                    // 간단한 수식 사용 (합성 툴이 알아서 최적화해줍니다)
                    // 14비트 숫자는 작아서 나눗셈 연산 비용이 크지 않습니다.
                    digit_th <= (current_cnt / 1000) % 10;
                    digit_hu <= (current_cnt / 100) % 10;
                    digit_te <= (current_cnt / 10) % 10;
                    digit_on <= current_cnt % 10;
                    
                    state <= S_LOAD_DATA;
                end

                // -------------------------------------------------------------
                // 전송할 문자 로드 (Lookup Table)
                // "count:1234, mode: UP\r\n" 형식
                // -------------------------------------------------------------
                S_LOAD_DATA: begin
                    case (char_idx)
                        // "count:"
                        0: tx_data <= "c";
                        1: tx_data <= "o";
                        2: tx_data <= "u";
                        3: tx_data <= "n";
                        4: tx_data <= "t";
                        5: tx_data <= ":";
                        // 숫자 (BCD + '0' -> ASCII)
                        6: tx_data <= {4'b0011, digit_th}; 
                        7: tx_data <= {4'b0011, digit_hu};
                        8: tx_data <= {4'b0011, digit_te};
                        9: tx_data <= {4'b0011, digit_on};
                        // ", mode: "
                        10: tx_data <= ",";
                        11: tx_data <= " ";
                        12: tx_data <= "m";
                        13: tx_data <= "o";
                        14: tx_data <= "d";
                        15: tx_data <= "e";
                        16: tx_data <= ":";
                        17: tx_data <= " ";
                        // UP / DN
                        18: tx_data <= saved_mode ? "U" : "D";
                        19: tx_data <= saved_mode ? "P" : "N"; // UP or DN
                        // 줄바꿈 (Carriage Return + Line Feed)
                        20: tx_data <= 8'h0D; // \r
                        21: tx_data <= 8'h0A; // \n
                        default: tx_data <= " ";
                    endcase
                    state <= S_SEND_START;
                end

                // -------------------------------------------------------------
                // 전송 시작 신호 (1 클럭 펄스)
                // -------------------------------------------------------------
                S_SEND_START: begin
                    // 혹시 uart_tx가 이전 전송 때문에 아직 바쁘다면 대기
                    if (!tx_busy) begin
                        tx_start <= 1'b1;
                        state <= S_WAIT_DONE;
                    end
                end

                // -------------------------------------------------------------
                // 전송 완료 대기
                // -------------------------------------------------------------
                S_WAIT_DONE: begin
                    tx_start <= 1'b0; // 펄스는 바로 내려줍니다.
                    
                    // tx_done이 뜰 때까지 기다림
                    if (tx_done) begin
                        state <= S_CHECK_NEXT;
                    end
                end

                // -------------------------------------------------------------
                // 다음 문자 확인
                // -------------------------------------------------------------
                S_CHECK_NEXT: begin
                    // 총 22글자 (인덱스 0~21)
                    if (char_idx == 21) begin
                        state <= S_IDLE; // 끝났으면 초기 상태로
                    end else begin
                        char_idx <= char_idx + 1; // 인덱스 증가
                        state <= S_LOAD_DATA;     // 다음 글자 가지러 감
                    end
                end
            endcase
        end
    end

endmodule