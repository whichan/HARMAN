`timescale 1ns / 1ps

module oled_controller(
    input clk,
    input reset,
    input [7:0] hours,
    input [7:0] minutes,
    input [7:0] seconds,
    input i2c_done,
    output reg i2c_start,
    output reg i2c_dc,
    output reg [7:0] i2c_data,
    output reg i2c_send
);

    // 상태 머신
    localparam ST_POWER_ON   = 5'd0;
    localparam ST_INIT       = 5'd1;
    localparam ST_INIT_WAIT  = 5'd2;
    localparam ST_CLEAR      = 5'd3;
    localparam ST_CLEAR_WAIT = 5'd4;
    localparam ST_UPDATE     = 5'd5;
    localparam ST_SEND       = 5'd6;
    localparam ST_WAIT       = 5'd7;
    localparam ST_DELAY      = 5'd8;
    
    reg [4:0] state;
    reg [7:0] cmd_idx;
    reg [10:0] data_idx;
    reg [25:0] delay_cnt;
    
    // 초기화 명령어 ROM
    reg [7:0] init_cmds [0:39];
    
    initial begin
        // I2C Address는 i2c_master에서 처리
        init_cmds[0]  = 8'h80; init_cmds[1]  = 8'hAE;  // Display OFF
        init_cmds[2]  = 8'h80; init_cmds[3]  = 8'hD5;  // Clock Divide
        init_cmds[4]  = 8'h80; init_cmds[5]  = 8'h80;
        init_cmds[6]  = 8'h80; init_cmds[7]  = 8'hA8;  // Multiplex
        init_cmds[8]  = 8'h80; init_cmds[9]  = 8'h1F;  // 32 lines
        init_cmds[10] = 8'h80; init_cmds[11] = 8'hD3;  // Display Offset
        init_cmds[12] = 8'h80; init_cmds[13] = 8'h00;
        init_cmds[14] = 8'h80; init_cmds[15] = 8'h40;  // Start Line
        init_cmds[16] = 8'h80; init_cmds[17] = 8'h8D;  // Charge Pump
        init_cmds[18] = 8'h80; init_cmds[19] = 8'h14;  // Enable
        init_cmds[20] = 8'h80; init_cmds[21] = 8'h20;  // Memory Mode
        init_cmds[22] = 8'h80; init_cmds[23] = 8'h00;  // Horizontal
        init_cmds[24] = 8'h80; init_cmds[25] = 8'hA1;  // Segment Remap
        init_cmds[26] = 8'h80; init_cmds[27] = 8'hC8;  // COM Direction
        init_cmds[28] = 8'h80; init_cmds[29] = 8'hDA;  // COM Pins
        init_cmds[30] = 8'h80; init_cmds[31] = 8'h02;
        init_cmds[32] = 8'h80; init_cmds[33] = 8'h81;  // Contrast
        init_cmds[34] = 8'h80; init_cmds[35] = 8'h8F;
        init_cmds[36] = 8'h80; init_cmds[37] = 8'hAF;  // Display ON
        init_cmds[38] = 8'h80; init_cmds[39] = 8'h40;  // Data mode
    end
    
    // 1초 타이머
    reg [26:0] sec_cnt;
    reg sec_tick;
    
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            sec_cnt <= 0;
            sec_tick <= 0;
        end else begin
            if (sec_cnt == 100_000_000 - 1) begin
                sec_cnt <= 0;
                sec_tick <= 1;
            end else begin
                sec_cnt <= sec_cnt + 1;
                sec_tick <= 0;
            end
        end
    end
    
    // 문자 ROM (8x8 폰트)
    wire [7:0] char_data;
    wire [3:0] char_code;
    wire [2:0] char_col;
    
    font_rom u_font(
        .char_code(char_code),
        .col(char_col),
        .data(char_data)
    );
    
    // 시간 표시 위치 계산
    reg [3:0] display_char;
    reg [2:0] char_x;
    
    // 메인 FSM
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= ST_POWER_ON;
            cmd_idx <= 0;
            data_idx <= 0;
            delay_cnt <= 0;
            i2c_start <= 0;
            i2c_send <= 0;
            i2c_dc <= 0;
            i2c_data <= 0;
        end else begin
            case (state)
                ST_POWER_ON: begin
                    // 파워온 후 100ms 대기
                    if (delay_cnt == 10_000_000) begin
                        delay_cnt <= 0;
                        cmd_idx <= 0;
                        state <= ST_INIT;
                    end else begin
                        delay_cnt <= delay_cnt + 1;
                    end
                end
                
                ST_INIT: begin
                    if (cmd_idx < 40) begin
                        i2c_dc <= 0;  // Command
                        i2c_data <= init_cmds[cmd_idx];
                        i2c_start <= 1;
                        i2c_send <= 1;
                        state <= ST_INIT_WAIT;
                    end else begin
                        data_idx <= 0;
                        state <= ST_CLEAR;
                    end
                end
                
                ST_INIT_WAIT: begin
                    if (i2c_done) begin
                        i2c_send <= 0;
                        i2c_start <= 0;
                        cmd_idx <= cmd_idx + 1;
                        state <= ST_INIT;
                    end
                end
                
                ST_CLEAR: begin
                    // 512바이트 화면 클리어
                    if (data_idx < 512) begin
                        i2c_dc <= 1;  // Data
                        i2c_data <= 8'h00;
                        i2c_start <= 1;
                        i2c_send <= 1;
                        state <= ST_CLEAR_WAIT;
                    end else begin
                        state <= ST_UPDATE;
                    end
                end
                
                ST_CLEAR_WAIT: begin
                    if (i2c_done) begin
                        i2c_send <= 0;
                        i2c_start <= 0;
                        data_idx <= data_idx + 1;
                        state <= ST_CLEAR;
                    end
                end
                
                ST_UPDATE: begin
                    // 1초마다 업데이트
                    if (sec_tick) begin
                        data_idx <= 0;
                        state <= ST_SEND;
                    end
                end
                
                ST_SEND: begin
                    // 시간 문자 전송 (HH:MM:SS 형식)
                    // 위치: Page 2, Column 32부터 시작
                    
                    if (data_idx < 256) begin  // Page 2 영역만
                        // 문자 위치 계산
                        if (data_idx >= 32 && data_idx < 96) begin
                            // 32~39: 시 십의자리
                            // 40~47: 시 일의자리
                            // 48~55: ':'
                            // 56~63: 분 십의자리
                            // 64~71: 분 일의자리
                            // 72~79: ':'
                            // 80~87: 초 십의자리
                            // 88~95: 초 일의자리
                            
                            case (data_idx[7:3])  // 8픽셀 단위
                                5'd4:  begin display_char <= hours[7:4]; char_x <= data_idx[2:0]; end
                                5'd5:  begin display_char <= hours[3:0]; char_x <= data_idx[2:0]; end
                                5'd6:  begin display_char <= 4'd10; char_x <= data_idx[2:0]; end  // ':'
                                5'd7:  begin display_char <= minutes[7:4]; char_x <= data_idx[2:0]; end
                                5'd8:  begin display_char <= minutes[3:0]; char_x <= data_idx[2:0]; end
                                5'd9:  begin display_char <= 4'd10; char_x <= data_idx[2:0]; end  // ':'
                                5'd10: begin display_char <= seconds[7:4]; char_x <= data_idx[2:0]; end
                                5'd11: begin display_char <= seconds[3:0]; char_x <= data_idx[2:0]; end
                                default: begin display_char <= 4'd15; char_x <= 0; end  // 공백
                            endcase
                            
                            i2c_data <= char_data;
                        end else begin
                            i2c_data <= 8'h00;  // 빈 공간
                        end
                        
                        i2c_dc <= 1;
                        i2c_start <= 1;
                        i2c_send <= 1;
                        state <= ST_WAIT;
                    end else begin
                        state <= ST_DELAY;
                    end
                end
                
                ST_WAIT: begin
                    if (i2c_done) begin
                        i2c_send <= 0;
                        i2c_start <= 0;
                        data_idx <= data_idx + 1;
                        state <= ST_SEND;
                    end
                end
                
                ST_DELAY: begin
                    // 짧은 딜레이 후 다음 업데이트 대기
                    if (delay_cnt == 1000) begin
                        delay_cnt <= 0;
                        state <= ST_UPDATE;
                    end else begin
                        delay_cnt <= delay_cnt + 1;
                    end
                end
                
                default: state <= ST_POWER_ON;
            endcase
        end
    end
    
    // 폰트 ROM 연결
    assign char_code = display_char;
    assign char_col = char_x;

endmodule