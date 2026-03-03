`timescale 1ns / 1ps

module data_sender(
    input clk,
    input reset,
    
    // Control Interface
    input start_trigger,        // 전송 시작 신호 (Pulse or Level)
    input [1:0] cmd_type,       // 0: myname, 1: upcounter, 2: help
    input [15:0] i_counter_val, // 16비트 카운터 값
    output reg sender_busy,     // "나 전송 중이야" 플래그
    
    // UART TX Interface
    input tx_busy,              // UART TX가 바쁜지 확인
    input tx_done,              // UART TX 전송 완료 신호 (선택적 사용)
    output reg tx_start,        // UART TX 시작 신호
    output reg [7:0] tx_data    // UART TX로 보낼 데이터
    );

    // ====================================================
    // 1. 내부 파라미터 및 레지스터 정의
    // ====================================================
    parameter S_IDLE    = 3'd0;
    parameter S_PREPARE = 3'd1; // 데이터 캡처 및 길이 설정
    parameter S_SEND    = 3'd2; // UART TX에 데이터 싣기
    parameter S_WAIT    = 3'd3; // UART TX 전송 대기
    parameter S_NEXT    = 3'd4; // 인덱스 증가

    reg [2:0] state;
    reg [5:0] char_idx;         // 최대 64글자까지 커버
    reg [5:0] msg_len;          // 전송할 총 길이
    
    // 카운터 값 스냅샷용 (전송 도중 값이 바뀌는 것 방지)
    reg [15:0] latched_counter; 
    
    // 엣지 디텍터용
    reg r_trig_prev;
    wire w_trig_pulse;

    // ASCII 변환용 와이어 (Combinational Logic)
    reg [7:0] digit_10000, digit_1000, digit_100, digit_10, digit_1;

    // ====================================================
    // 2. 상승 엣지 검출 (Rising Edge Detector)
    // ====================================================
    always @(posedge clk or posedge reset) begin
        if(reset) r_trig_prev <= 0;
        else      r_trig_prev <= start_trigger;
    end
    assign w_trig_pulse = start_trigger && !r_trig_prev;

    // ====================================================
    // 3. Binary to ASCII 변환 로직 (16비트 -> 5자리)
    // ====================================================
    // 전송 속도보다 연산 속도가 빠르므로 always @(*)로 처리해도 무방
    always @(*) begin
        // 16비트 최대값 65535 (5자리)
        // FPGA 내장 DSP 블록을 사용하여 합성됨
        digit_10000 = (latched_counter / 10000) % 10 + 8'h30;
        digit_1000  = (latched_counter / 1000)  % 10 + 8'h30;
        digit_100   = (latched_counter / 100)   % 10 + 8'h30;
        digit_10    = (latched_counter / 10)    % 10 + 8'h30;
        digit_1     = (latched_counter % 10)         + 8'h30;
    end

    // ====================================================
    // 4. Main FSM
    // ====================================================
    always @(posedge clk or posedge reset) begin
        if(reset) begin
            state           <= S_IDLE;
            sender_busy     <= 0;
            tx_start        <= 0;
            tx_data         <= 0;
            char_idx        <= 0;
            msg_len         <= 0;
            latched_counter <= 0;
        end else begin
            case(state)
                
                // ------------------------------------------------
                // IDLE: 트리거 대기
                // ------------------------------------------------
                S_IDLE: begin
                    tx_start    <= 0;
                    sender_busy <= 0;
                    
                    if(w_trig_pulse) begin
                        sender_busy     <= 1;       // Busy Flag 세우기
                        latched_counter <= i_counter_val; // [중요] 값 캡처
                        char_idx        <= 0;
                        state           <= S_PREPARE;
                    end
                end

                // ------------------------------------------------
                // PREPARE: 메시지 길이 설정 (Mux)
                // ------------------------------------------------
                S_PREPARE: begin
                    case(cmd_type)
                        2'd0: msg_len <= 9;  // "Whichan" (7) + CR + LF
                        2'd1: msg_len <= 7;  // "65535" (5) + CR + LF
                        2'd2: msg_len <= 28; // "CMD: led, myname, upcounter" + CR + LF
                        default: msg_len <= 0;
                    endcase
                    state <= S_SEND;
                end

                // ------------------------------------------------
                // SEND: 글자 선택 및 전송 시작
                // ------------------------------------------------
                S_SEND: begin
                    if(!tx_busy) begin
                        tx_start <= 1; // 1-cycle Pulse
                        
                        // [핵심] cmd_type과 char_idx에 따른 데이터 MUX
                        case(cmd_type)
                            
                            // Type 0: "Whichan\r\n"
                            2'd0: begin
                                case(char_idx)
                                    0: tx_data <= "W"; 1: tx_data <= "h"; 2: tx_data <= "i";
                                    3: tx_data <= "c"; 4: tx_data <= "h"; 5: tx_data <= "a";
                                    6: tx_data <= "n"; 7: tx_data <= 8'h0D; 8: tx_data <= 8'h0A;
                                    default: tx_data <= " ";
                                endcase
                            end

                            // Type 1: "12345\r\n" (Counter)
                            2'd1: begin
                                case(char_idx)
                                    0: tx_data <= digit_10000;
                                    1: tx_data <= digit_1000;
                                    2: tx_data <= digit_100;
                                    3: tx_data <= digit_10;
                                    4: tx_data <= digit_1;
                                    5: tx_data <= 8'h0D; // CR
                                    6: tx_data <= 8'h0A; // LF
                                    default: tx_data <= " ";
                                endcase
                            end

                            // Type 2: Help Msg
                            2'd2: begin
                                // "CMD: led, myname, upcounter\r\n" (예시)
                                case(char_idx)
                                    0: tx_data <= "C"; 1: tx_data <= "M"; 2: tx_data <= "D"; 3: tx_data <= ":"; 
                                    4: tx_data <= " "; 5: tx_data <= "l"; 6: tx_data <= "e"; 7: tx_data <= "d";
                                    8: tx_data <= ","; 9: tx_data <= " "; 10:tx_data <= "m"; 11:tx_data <= "y";
                                    12:tx_data <= "n"; 13:tx_data <= "a"; 14:tx_data <= "m"; 15:tx_data <= "e";
                                    16:tx_data <= ","; 17:tx_data <= " "; 18:tx_data <= "u"; 19:tx_data <= "p";
                                    20:tx_data <= "c"; 21:tx_data <= "o"; 22:tx_data <= "u"; 23:tx_data <= "n"; 
                                    24:tx_data <= "t"; 25:tx_data <= "e"; 26:tx_data <= "r"; 27:tx_data <= " ";
                                    28:tx_data <= "e"; 29:tx_data <= "t"; 30:tx_data <= "c"; 31:tx_data <= "."; 
                                    32:tx_data <= "."; 33:tx_data <= "."; 34:tx_data <= ".";
                                    
                                    35:tx_data <= 8'h0D; 27:tx_data <= 8'h0A;
                                    default: tx_data <= ".";
                                endcase
                            end
                        endcase
                        
                        state <= S_WAIT;
                    end
                end

                // ------------------------------------------------
                // WAIT: 전송 완료 대기 (Handshake)
                // ------------------------------------------------
                S_WAIT: begin
                    tx_start <= 0; // Pulse 끄기
                    
                    // tx_busy가 1이 되었다가(시작함), 다시 0이 될 때(끝남)를 기다리거나
                    // 간단히 tx_busy가 0이 아닌 상태에서 시작했다면, 다시 0이 되길 기다림.
                    // 여기서는 가장 안전하게 "Busy가 풀릴 때까지" 대기
                    if(!tx_busy) begin 
                        state <= S_NEXT;
                    end
                    
                    // 만약 tx_done 신호를 쓴다면:
                    // if(tx_done) state <= S_NEXT;
                end

                // ------------------------------------------------
                // NEXT: 다음 글자로 이동
                // ------------------------------------------------
                S_NEXT: begin
                    if(char_idx == msg_len - 1) begin
                        state       <= S_IDLE; // 모든 글자 전송 완료
                        sender_busy <= 0;      // Busy 해제
                    end else begin
                        char_idx <= char_idx + 1;
                        state    <= S_SEND;    // 다음 글자 전송
                    end
                end

            endcase
        end
    end

endmodule