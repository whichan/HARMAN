`timescale 1ns / 1ps

module data_sender(
    input clk,
    input reset,
    input start_trigger,   // (uart_controller의 1Hz tick이 연결됨)
    input [13:0] send_data, // (이 로직에서는 사용 안 함)
    input tx_busy,
    input tx_done,         // (이 로직에서는 사용 안 함)
    output reg tx_start,
    output reg [7:0] tx_data
    );

    // 1. 전송할 문자열 "hello! Whichan " (총 15글자)
    parameter STRING_LENGTH = 15;
    
    // 2. 문자열을 저장할 ROM 선언
    reg [7:0] string_rom [0:STRING_LENGTH-1];

    // 3. ROM 초기화 (ASCII 값)
    initial begin
        string_rom[ 0] = 8'h68; // h
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

    // 4. ROM 인덱스 카운터 (0~13까지 카운트)
    reg [3:0] r_char_index = 0; // 4비트면 0~15까지 가능

    // 5. FSM 로직
    always @(posedge clk) begin
        if (reset) begin
            tx_start <= 0;
            r_char_index <= 0;
            tx_data <= 0;
        end else begin
            
            tx_start <= 1'b0; // 1-cycle 펄스를 위해 기본값은 0

            // 1Hz 틱(start_trigger)이 들어오고, 송신기가 바쁘지 않으면(!tx_busy)
            if (start_trigger && !tx_busy) begin
                
                // 1. ROM에서 현재 인덱스의 문자를 tx_data에 싣기
                tx_data <= string_rom[r_char_index];
                
                // 2. uart_tx 모듈에 송신 시작 신호 (1-cycle)
                tx_start <= 1'b1;
                
                // 3. 다음 1Hz 틱을 위해 인덱스 증가
                if (r_char_index == STRING_LENGTH-1) begin
                    r_char_index <= 0; // 마지막 글자('n')였으면 다시 'h'로
                end else begin
                    r_char_index <= r_char_index + 1; 
                end
                
            end
            // (start_trigger가 0이거나 tx_busy가 1이면
            //  tx_start는 0, 인덱스도 변경되지 않아 다음 틱을 기다림)
        end 
    end
endmodule