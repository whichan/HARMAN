`timescale 1ns / 1ps

module ssd1306_controller(
    input clk,
    input reset,

    input [7:0] i_hour, i_min, i_sec,
    input [7:0] i_temp, i_humi,

    // I2C Master Interface
    output reg i2c_start,
    output reg [7:0] i2c_data,
    output reg i2c_is_start,
    output reg i2c_is_stop,
    input i2c_busy,
    input i2c_done
);

    // =================================================================
    // 1. 상태 머신 정의
    // =================================================================
    localparam S_IDLE        = 0;
    localparam S_INIT_WAIT   = 1;  // 전원 안정화
    localparam S_INIT_SEND   = 2;  // 초기화 명령 전송
    localparam S_READY       = 3;  // 대기
    localparam S_PAGE_SET    = 4;  // 페이지 좌표 설정 (Page, Col Low, Col High)
    localparam S_DATA_START  = 5;  // 데이터 모드 진입
    localparam S_SEND_CHAR   = 6;  // 폰트 데이터 전송
    localparam S_I2C_WAIT    = 7;  // I2C 완료 대기 (공용 상태)
    localparam S_CMD_DELAY   = 8;  // 명령 간 딜레이

    reg [3:0] state;
    reg [3:0] return_state; // I2C 완료 후 돌아갈 상태

    // =================================================================
    // 2. 초기화 명령어 ROM
    // =================================================================
    reg [7:0] w_init_cmd;
    reg [4:0] cmd_idx;

    always @(*) begin
        case(cmd_idx)
            5'd0:  w_init_cmd = 8'hAE; // Display Off
            5'd1:  w_init_cmd = 8'hD5; // Clock Div
            5'd2:  w_init_cmd = 8'h80;
            5'd3:  w_init_cmd = 8'hA8; // Multiplex
            5'd4:  w_init_cmd = 8'h3F;
            5'd5:  w_init_cmd = 8'hD3; // Offset
            5'd6:  w_init_cmd = 8'h00;
            5'd7:  w_init_cmd = 8'h40; // Start Line
            5'd8:  w_init_cmd = 8'h8D; // Charge Pump
            5'd9:  w_init_cmd = 8'h14; // Enable
            5'd10: w_init_cmd = 8'h20; // Memory Mode
            5'd11: w_init_cmd = 8'h02; // Page Addressing
            5'd12: w_init_cmd = 8'hA1; // Seg Remap
            5'd13: w_init_cmd = 8'hC8; // Com Scan Dec
            5'd14: w_init_cmd = 8'hDA; // Com Config
            5'd15: w_init_cmd = 8'h12;
            5'd16: w_init_cmd = 8'h81; // Contrast
            5'd17: w_init_cmd = 8'hCF;
            5'd18: w_init_cmd = 8'hD9; // Pre-charge
            5'd19: w_init_cmd = 8'hF1;
            5'd20: w_init_cmd = 8'hDB; // VCOMH
            5'd21: w_init_cmd = 8'h40;
            5'd22: w_init_cmd = 8'hA4; // Resume
            5'd23: w_init_cmd = 8'hA6; // Normal
            5'd24: w_init_cmd = 8'hAF; // Display On
            default: w_init_cmd = 8'hFF; // End
        endcase
    end

    // =================================================================
    // 3. 내부 변수
    // =================================================================
    reg [20:0] wait_cnt;
    reg [1:0] page_idx;     // 0, 2, 3 페이지
    reg [3:0] char_idx;     // 0~15 글자
    reg [2:0] font_col;     // 0~7 폰트 컬럼
    reg [2:0] tx_step;      // 전송 단계 (Addr -> Ctrl -> Data)
    reg [2:0] page_step;    // 페이지 설정 단계

    // [수정] 주소를 0x78 (Write)로 명시
    localparam SLAVE_ADDR_W = {7'h3C, 1'b0}; 

    reg [23:0] refresh_timer;
    wire refresh_tick = (refresh_timer == 10_000_000); // 0.1s

    wire [7:0] w_font_data;
    reg [7:0] r_char_ascii;

    // Refresh Timer
    always @(posedge clk) begin
        if (reset) refresh_timer <= 0;
        else if (refresh_tick) refresh_timer <= 0;
        else refresh_timer <= refresh_timer + 1;
    end

    // =================================================================
    // 4. Main FSM
    // =================================================================
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= S_INIT_WAIT;
            cmd_idx <= 0;
            wait_cnt <= 0;
            i2c_start <= 0;
            tx_step <= 0;
            page_idx <= 0;
            page_step <= 0;
            char_idx <= 0;
            font_col <= 0;
        end else begin
            i2c_start <= 0; // Pulse Reset

            case (state)
                // 1. 전원 대기 (충분한 시간: 10ms)
                S_INIT_WAIT: begin
                    wait_cnt <= wait_cnt + 1;
                    if (wait_cnt > 1_000_000) state <= S_INIT_SEND;
                end

                // 2. 초기화 명령 전송
                S_INIT_SEND: begin
                    if (!i2c_busy) begin // Idle 상태일 때만
                        if (w_init_cmd == 8'hFF) begin
                            state <= S_READY; // 끝
                        end else begin
                            // 3단계 전송: Addr -> Ctrl(0x80) -> Cmd
                            case (tx_step)
                                0: begin // Slave Addr
                                    i2c_data <= SLAVE_ADDR_W; // 0x78
                                    i2c_is_start <= 1; i2c_is_stop <= 0;
                                    i2c_start <= 1;
                                    state <= S_I2C_WAIT; return_state <= S_INIT_SEND;
                                    tx_step <= 1;
                                end
                                1: begin // Ctrl Byte (Single Command)
                                    i2c_data <= 8'h80; 
                                    i2c_is_start <= 0; i2c_is_stop <= 0;
                                    i2c_start <= 1;
                                    state <= S_I2C_WAIT; return_state <= S_INIT_SEND;
                                    tx_step <= 2;
                                end
                                2: begin // Command Data + Stop
                                    i2c_data <= w_init_cmd;
                                    i2c_is_start <= 0; i2c_is_stop <= 1;
                                    i2c_start <= 1;
                                    state <= S_I2C_WAIT; return_state <= S_CMD_DELAY; // 딜레이 추가
                                    
                                    cmd_idx <= cmd_idx + 1; // 다음 명령어
                                    tx_step <= 0;
                                end
                            endcase
                        end
                    end
                end
                
                // 명령 사이 딜레이 (안정성 확보)
                S_CMD_DELAY: begin
                    state <= S_INIT_SEND; // 바로 이동 (필요시 wait 추가 가능)
                end

                // 3. 화면 갱신 대기
                S_READY: begin
                    if (refresh_tick) begin
                        state <= S_PAGE_SET;
                        page_idx <= 0; // Page 0부터 그리기 시작
                        page_step <= 0;
                    end
                end

                // 4. 페이지 좌표 설정 (필수!)
                // Command: 0xB0+Page, 0x00(Low Col), 0x10(High Col)
                S_PAGE_SET: begin
                    if (!i2c_busy) begin
                        case (page_step)
                            0: begin // Addr
                                i2c_data <= SLAVE_ADDR_W;
                                i2c_is_start <= 1; i2c_is_stop <= 0;
                                i2c_start <= 1;
                                state <= S_I2C_WAIT; return_state <= S_PAGE_SET;
                                page_step <= 1;
                            end
                            1: begin // Ctrl (Stream 0x00)
                                i2c_data <= 8'h00; 
                                i2c_is_start <= 0; i2c_is_stop <= 0;
                                i2c_start <= 1;
                                state <= S_I2C_WAIT; return_state <= S_PAGE_SET;
                                page_step <= 2;
                            end
                            2: begin // Set Page Address
                                i2c_data <= 8'hB0 + page_idx;
                                i2c_start <= 1;
                                state <= S_I2C_WAIT; return_state <= S_PAGE_SET;
                                page_step <= 3;
                            end
                            3: begin // Set Lower Column
                                i2c_data <= 8'h00;
                                i2c_start <= 1;
                                state <= S_I2C_WAIT; return_state <= S_PAGE_SET;
                                page_step <= 4;
                            end
                            4: begin // Set Higher Column + Stop
                                i2c_data <= 8'h10;
                                i2c_is_stop <= 1; 
                                i2c_start <= 1;
                                state <= S_I2C_WAIT; return_state <= S_DATA_START; 
                                page_step <= 0;
                            end
                        endcase
                    end
                end

                // 5. 데이터 모드 진입 (Start + Addr + 0x40)
                S_DATA_START: begin
                    if (!i2c_busy) begin
                        case (tx_step)
                            0: begin // Addr
                                i2c_data <= SLAVE_ADDR_W;
                                i2c_is_start <= 1; i2c_is_stop <= 0;
                                i2c_start <= 1;
                                state <= S_I2C_WAIT; return_state <= S_DATA_START;
                                tx_step <= 1;
                            end
                            1: begin // Ctrl Byte (Data Stream 0x40)
                                i2c_data <= 8'h40;
                                i2c_is_start <= 0; i2c_is_stop <= 0;
                                i2c_start <= 1;
                                state <= S_I2C_WAIT; return_state <= S_SEND_CHAR;
                                
                                char_idx <= 0;
                                font_col <= 0;
                                tx_step <= 0;
                            end
                        endcase
                    end
                end

                // 6. 폰트 데이터 연속 전송
                S_SEND_CHAR: begin
                    if (!i2c_busy) begin
                        i2c_data <= w_font_data; // Font ROM에서 읽은 값
                        i2c_is_start <= 0;
                        
                        // 한 글자(8 col) 끝?
                        if (font_col == 7) begin
                            font_col <= 0;
                            // 한 줄(16글자) 끝?
                            if (char_idx == 15) begin
                                i2c_is_stop <= 1; // 줄 끝났으니 Stop
                                i2c_start <= 1;
                                state <= S_I2C_WAIT; return_state <= S_PAGE_SET; // 다음 페이지 준비
                                
                                // 다음 페이지 인덱스 계산 (0 -> 2 -> 3 -> 0)
                                if (page_idx == 0) page_idx <= 2;
                                else if (page_idx == 2) page_idx <= 3;
                                else begin
                                    page_idx <= 0;
                                    return_state <= S_READY; // 다 그렸으면 대기
                                end
                            end else begin
                                i2c_is_stop <= 0;
                                i2c_start <= 1;
                                state <= S_I2C_WAIT; return_state <= S_SEND_CHAR;
                                char_idx <= char_idx + 1;
                            end
                        end else begin
                            font_col <= font_col + 1;
                            i2c_is_stop <= 0;
                            i2c_start <= 1;
                            state <= S_I2C_WAIT; return_state <= S_SEND_CHAR;
                        end
                    end
                end

                // 7. 공용 I2C 완료 대기 상태
                S_I2C_WAIT: begin
                    // done 신호가 오면, 해당 상태로 복귀
                    if (i2c_done) begin
                        state <= return_state;
                    end
                end

            endcase
        end
    end

    // =================================================================
    // 5. 문자열 매핑 로직
    // =================================================================
    // BCD to ASCII
    function [7:0] bcd_to_ascii;
        input [3:0] bcd;
        begin
            bcd_to_ascii = {4'h3, bcd};
        end
    endfunction

    always @(*) begin
        r_char_ascii = 8'h20; // Space
        case (page_idx)
            0: begin // "Time 12:34:56"
                case (char_idx)
                    0: r_char_ascii = "T"; 1: r_char_ascii = "i"; 2: r_char_ascii = "m"; 3: r_char_ascii = "e";
                    5: r_char_ascii = bcd_to_ascii(i_hour[7:4]); 
                    6: r_char_ascii = bcd_to_ascii(i_hour[3:0]);
                    7: r_char_ascii = ":";
                    8: r_char_ascii = bcd_to_ascii(i_min[7:4]); 
                    9: r_char_ascii = bcd_to_ascii(i_min[3:0]);
                    10: r_char_ascii = ":";
                    11: r_char_ascii = bcd_to_ascii(i_sec[7:4]); 
                    12: r_char_ascii = bcd_to_ascii(i_sec[3:0]);
                endcase
            end
            2: begin // "Temp 25 C" (0으로 고정된 값)
                case (char_idx)
                    0: r_char_ascii = "T"; 1: r_char_ascii = "e"; 2: r_char_ascii = "m"; 3: r_char_ascii = "p";
                    5: r_char_ascii = bcd_to_ascii(i_temp[7:4]); 
                    6: r_char_ascii = bcd_to_ascii(i_temp[3:0]);
                    8: r_char_ascii = "C";
                endcase
            end
            3: begin // "Humi 60 %"
                case (char_idx)
                    0: r_char_ascii = "H"; 1: r_char_ascii = "u"; 2: r_char_ascii = "m"; 3: r_char_ascii = "i";
                    5: r_char_ascii = bcd_to_ascii(i_humi[7:4]); 
                    6: r_char_ascii = bcd_to_ascii(i_humi[3:0]);
                    8: r_char_ascii = "%";
                endcase
            end
        endcase
    end

    // Font ROM Instance
    font_rom u_font_rom (
        .ascii_code(r_char_ascii),
        .col_addr(font_col),
        .data(w_font_data)
    );

endmodule