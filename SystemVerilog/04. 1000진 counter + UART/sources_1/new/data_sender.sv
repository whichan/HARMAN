`timescale 1ns / 1ps

module data_sender(
    input wire clk,
    input wire reset,
    
    input wire start_trigger,      // 's' 키 입력
    input wire [13:0] current_cnt, // 0 ~ 9999
    input wire current_mode,       // 0: Down, 1: Up
    
    input wire tx_done,            // uart_tx 전송 완료 신호
    input wire tx_busy,            // uart_tx 바쁨 신호
    
    output reg tx_start,           // 전송 시작 트리거
    output reg [7:0] tx_data,      // 전송할 데이터
    output wire busy               // 모듈 Busy 신호
    );

    // =========================================================================
    // 1. 상태 머신 및 신호 정의
    // =========================================================================
    localparam S_IDLE       = 3'd0;
    localparam S_PREPARE    = 3'd1; // BCD 변환 값을 캡처하는 단계
    localparam S_LOAD_DATA  = 3'd2; 
    localparam S_SEND_START = 3'd3; 
    localparam S_WAIT_DONE  = 3'd4; 
    localparam S_CHECK_NEXT = 3'd5; 

    reg [2:0] state;
    reg [4:0] char_idx; 

    // BCD 값 저장용 레지스터
    reg [3:0] digit_th; // 천
    reg [3:0] digit_hu; // 백
    reg [3:0] digit_te; // 십
    reg [3:0] digit_on; // 일
    
    reg saved_mode; 
    assign busy = (state != S_IDLE);

    // =========================================================================
    // 2. Binary to BCD 모듈 인스턴스 (Combinational Logic)
    // =========================================================================
    wire [15:0] bcd_result; // [15:12]천, [11:8]백, [7:4]십, [3:0]일

    // 하드웨어적으로 전선만 연결해두면, current_cnt가 바뀔 때마다 
    // bcd_result는 실시간으로(약간의 딜레이 후) 변환된 값을 출력합니다.
    bin_to_bcd u_bin_to_bcd (
        .bin(current_cnt),
        .bcd(bcd_result)
    );

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
                S_IDLE: begin
                    tx_start <= 1'b0;
                    char_idx <= 5'd0;
                    
                    if (start_trigger) begin
                        state <= S_PREPARE;
                        saved_mode <= current_mode; 
                    end
                end

                // -------------------------------------------------------------
                // 데이터 캡처 (Latch)
                // -------------------------------------------------------------
                S_PREPARE: begin
                    // 나눗셈 연산 대신, 이미 변환된 wire 값을 레지스터에 저장(Latch)만 함
                    // Combinational Logic을 통과한 결과를 여기서 찰칵 찍어서 보관
                    digit_th <= bcd_result[15:12];
                    digit_hu <= bcd_result[11:8];
                    digit_te <= bcd_result[7:4];
                    digit_on <= bcd_result[3:0];
                    
                    state <= S_LOAD_DATA;
                end

                // -------------------------------------------------------------
                // 이하 로직은 기존과 동일
                // -------------------------------------------------------------
                S_LOAD_DATA: begin
                    case (char_idx)
                        0: tx_data <= "c";
                        1: tx_data <= "o";
                        2: tx_data <= "u";
                        3: tx_data <= "n";
                        4: tx_data <= "t";
                        5: tx_data <= ":";
                        // 숫자 (BCD + ASCII Offset '0'(0x30))
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
                        19: tx_data <= saved_mode ? "P" : "N";
                        // 줄바꿈
                        20: tx_data <= 8'h0D; // \r
                        21: tx_data <= 8'h0A; // \n
                        default: tx_data <= " ";
                    endcase
                    state <= S_SEND_START;
                end

                S_SEND_START: begin
                    if (!tx_busy) begin
                        tx_start <= 1'b1;
                        state <= S_WAIT_DONE;
                    end
                end

                S_WAIT_DONE: begin
                    tx_start <= 1'b0; 
                    if (tx_done) begin
                        state <= S_CHECK_NEXT;
                    end
                end

                S_CHECK_NEXT: begin
                    if (char_idx == 21) begin
                        state <= S_IDLE; 
                    end else begin
                        char_idx <= char_idx + 1; 
                        state <= S_LOAD_DATA;    
                    end
                end
            endcase
        end
    end

endmodule