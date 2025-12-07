/*`timescale 1ns / 1ps

module data_sender(
    input clk,
    input reset,
    input start_trigger,
    input [13:0] current_cnt,  // 0~9999
    input current_mode,        // 0: down, 1: up
    input tx_done,
    
    output logic tx_start,
    output logic [7:0] tx_data,
    output logic busy
);

    localparam S_IDLE = 0, S_LATCH = 1, S_SEND = 2, S_WAIT = 3;
    reg [1:0] state;
    reg [4:0] char_idx;
    
    reg [13:0] latched_cnt;
    reg latched_mode;
    
    // BCD 변환된 각 자리수
    reg [3:0] digit_1000, digit_100, digit_10, digit_1;
    
    // 전송할 마지막 문자 인덱스 (총 문자수 - 1)
    reg [4:0] last_char_idx; 
    
    // 10진수 -> ASCII 변환 함수
    function [7:0] digit2ascii;
        input [3:0] val;
        begin
            digit2ascii = val + 8'd48;  // '0' = 48
        end
    endfunction
    
    // Combinational Logic: BCD 변환 및 길이 계산
    always @(*) begin
        // 1. 카운터 값을 각 자릿수로 분리 (0~9)
        digit_1000 = latched_cnt / 1000;
        digit_100  = (latched_cnt % 1000) / 100;
        digit_10   = (latched_cnt % 100) / 10;
        digit_1    = latched_cnt % 10;
        
        // 2. 모드에 따른 전송 길이 설정 (마지막 인덱스 번호)
        // "count: 1234, mode: up\r\n"   -> 인덱스 0~22 (총 23자)
        // "count: 1234, mode: down\r\n" -> 인덱스 0~24 (총 25자)
        last_char_idx = latched_mode ? 5'd22 : 5'd24;
    end
    
    // Sequential Logic: FSM
    always @(posedge clk) begin
        if (reset) begin
            state <= S_IDLE;
            tx_start <= 0;
            busy <= 0;
            char_idx <= 0;
            latched_cnt <= 0;
            latched_mode <= 0;
            tx_data <= 0;
        end else begin
            tx_start <= 0;  // Pulse 생성을 위한 자동 Clear
            
            case (state)
                S_IDLE: begin
                    busy <= 0;
                    char_idx <= 0;
                    if (start_trigger) begin
                        state <= S_LATCH;
                        busy <= 1;
                    end
                end
                
                S_LATCH: begin
                    latched_cnt <= current_cnt;
                    latched_mode <= current_mode;
                    char_idx <= 0;
                    state <= S_SEND;
                end
                
                S_SEND: begin
                    // 문자열 조립: "count: 1234, mode: up" or "down"
                    case (char_idx)
                        // "count: "
                        5'd0:  tx_data <= "c";
                        5'd1:  tx_data <= "o";
                        5'd2:  tx_data <= "u";
                        5'd3:  tx_data <= "n";
                        5'd4:  tx_data <= "t";
                        5'd5:  tx_data <= ":";
                        5'd6:  tx_data <= " ";
                        
                        // "1234" (가변 데이터)
                        5'd7:  tx_data <= digit2ascii(digit_1000);
                        5'd8:  tx_data <= digit2ascii(digit_100);
                        5'd9:  tx_data <= digit2ascii(digit_10);
                        5'd10: tx_data <= digit2ascii(digit_1);
                        
                        // ", mode: "
                        5'd11: tx_data <= ",";
                        5'd12: tx_data <= " ";
                        5'd13: tx_data <= "m";
                        5'd14: tx_data <= "o";
                        5'd15: tx_data <= "d";
                        5'd16: tx_data <= "e";
                        5'd17: tx_data <= ":";
                        5'd18: tx_data <= " ";
                        
                        // "up" or "down" 분기 처리
                        5'd19: tx_data <= latched_mode ? "u" : "d";
                        5'd20: tx_data <= latched_mode ? "p" : "o";
                        
                        // up인 경우 여기서 끝(\r), down인 경우 계속('w')
                        5'd21: tx_data <= latched_mode ? 8'h0D : "w"; // \r or 'w'
                        
                        // up인 경우 여기서 진짜 끝(\n), down인 경우 계속('n')
                        5'd22: tx_data <= latched_mode ? 8'h0A : "n"; // \n or 'n'
                        
                        // down인 경우 마무리 (\r\n)
                        5'd23: tx_data <= 8'h0D; // \r
                        5'd24: tx_data <= 8'h0A; // \n
                        
                        default: tx_data <= " ";
                    endcase
                    
                    tx_start <= 1;  // 전송 시작 트리거
                    state <= S_WAIT;
                end
                
                S_WAIT: begin
                    // UART TX 모듈이 전송을 마칠 때까지 대기
                    if (tx_done) begin
                        if (char_idx == last_char_idx) begin
                            // 마지막 글자까지 다 보냈으면 종료
                            state <= S_IDLE;
                            busy <= 0;
                        end else begin
                            // 다음 글자 보내러 이동
                            char_idx <= char_idx + 1;
                            state <= S_SEND;
                        end
                    end
                end
                
                default: state <= S_IDLE;
            endcase
        end
    end

endmodule*/

`timescale 1ns / 1ps

module data_sender(
    input clk,
    input reset,
    input start_trigger,
    input [13:0] current_cnt,  // 0~9999
    input current_mode,        // 0: down, 1: up
    input tx_done,
    
    output logic tx_start,
    output logic [7:0] tx_data,
    output logic busy
);

    localparam S_IDLE = 0, S_LATCH = 1, S_SEND = 2, S_WAIT = 3;
    reg [1:0] state;
    reg [4:0] char_idx;
    
    // 내부 저장소 (Latch)
    reg [13:0] latched_cnt;
    reg latched_mode;
    
    // BCD 변환 결과를 받을 wire
    wire [15:0] w_bcd_result;
    
    // 각 자리수 분리용
    reg [3:0] digit_1000, digit_100, digit_10, digit_1;
    
    // 전송할 마지막 문자 인덱스
    reg [4:0] last_char_idx; 


    bin_to_bcd u_bin_to_bcd (
        .bin(latched_cnt),  // Latch된 카운터 값을 입력으로 줌
        .bcd(w_bcd_result)  // 변환된 10진수 결과를 받음
    );

    // 10진수 -> ASCII 변환 함수
    function [7:0] digit2ascii;
        input [3:0] val;
        begin
            digit2ascii = val + 8'd48;  // '0' = 48
        end
    endfunction
    
    // Combinational Logic
    always @(*) begin
        // 1. 모듈에서 변환된 BCD 값을 자릿수별로 쪼개기
        digit_1000 = w_bcd_result[15:12]; // 천
        digit_100  = w_bcd_result[11:8];  // 백
        digit_10   = w_bcd_result[7:4];   // 십
        digit_1    = w_bcd_result[3:0];   // 일
        
        // 2. 모드에 따른 전송 길이 설정
        // Up: 23글자 (idx 22), Down: 25글자 (idx 24)
        last_char_idx = latched_mode ? 5'd22 : 5'd24;
    end
    
    // FSM Logic
    always @(posedge clk) begin
        if (reset) begin
            state <= S_IDLE;
            tx_start <= 0;
            busy <= 0;
            char_idx <= 0;
            latched_cnt <= 0;
            latched_mode <= 0;
            tx_data <= 0;
        end else begin
            tx_start <= 0;  // Pulse 자동 Clear
            
            case (state)
                S_IDLE: begin
                    busy <= 0;
                    char_idx <= 0;
                    if (start_trigger) begin
                        state <= S_LATCH;
                        busy <= 1;
                    end
                end
                
                S_LATCH: begin
                    // 값 캡쳐 (Snapshot)
                    latched_cnt <= current_cnt;
                    latched_mode <= current_mode;
                    char_idx <= 0;
                    state <= S_SEND;
                end
                
                S_SEND: begin
                    // 문자열 조립
                    case (char_idx)
                        // "count: "
                        5'd0:  tx_data <= "c";
                        5'd1:  tx_data <= "o";
                        5'd2:  tx_data <= "u";
                        5'd3:  tx_data <= "n";
                        5'd4:  tx_data <= "t";
                        5'd5:  tx_data <= ":";
                        5'd6:  tx_data <= " ";
                        
                        // "1234" (변환된 숫자)
                        5'd7:  tx_data <= digit2ascii(digit_1000);
                        5'd8:  tx_data <= digit2ascii(digit_100);
                        5'd9:  tx_data <= digit2ascii(digit_10);
                        5'd10: tx_data <= digit2ascii(digit_1);
                        
                        // ", mode: "
                        5'd11: tx_data <= ",";
                        5'd12: tx_data <= " ";
                        5'd13: tx_data <= "m";
                        5'd14: tx_data <= "o";
                        5'd15: tx_data <= "d";
                        5'd16: tx_data <= "e";
                        5'd17: tx_data <= ":";
                        5'd18: tx_data <= " ";
                        
                        // "up" or "down"
                        5'd19: tx_data <= latched_mode ? "u" : "d";
                        5'd20: tx_data <= latched_mode ? "p" : "o";
                        
                        // 가변 길이 처리 부분
                        5'd21: tx_data <= latched_mode ? 8'h0D : "w"; // \r or 'w'
                        5'd22: tx_data <= latched_mode ? 8'h0A : "n"; // \n or 'n'
                        5'd23: tx_data <= 8'h0D; // \r (down only)
                        5'd24: tx_data <= 8'h0A; // \n (down only)
                        
                        default: tx_data <= " ";
                    endcase
                    
                    tx_start <= 1;  // 전송 시작
                    state <= S_WAIT;
                end
                
                S_WAIT: begin
                    if (tx_done) begin
                        if (char_idx == last_char_idx) begin
                            state <= S_IDLE; // 끝
                            busy <= 0;
                        end else begin
                            char_idx <= char_idx + 1; // 다음 글자
                            state <= S_SEND;
                        end
                    end
                end
                
                default: state <= S_IDLE;
            endcase
        end
    end

endmodule