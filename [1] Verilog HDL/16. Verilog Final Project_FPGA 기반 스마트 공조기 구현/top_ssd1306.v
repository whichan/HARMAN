`timescale 1ns / 1ps

module top_ssd1306 (
    input  wire clk,
    input  wire reset,
    input  wire [7:0] hour, // BCD 형식
    input  wire [7:0] min, // BCD 형식
    input  wire [7:0] sec, // BCD 형식
    inout  wire oled_sda,
    output wire oled_scl
);


    // =========================================================
    // 1. 파라미터 정의
    // =========================================================
    localparam S_IDLE   = 4'd0;
    localparam S_START1 = 4'd1;
    localparam S_START2 = 4'd2;
    localparam S_START3 = 4'd11; 
    localparam S_BIT0   = 4'd3; //1비트를 보내기 위해 SCL을 Low로 내림
    localparam S_BIT1   = 4'd4; //데이터를 싣고 SCL을 High로 올림
    localparam S_ACK0   = 4'd5; //응답 확인
    localparam S_ACK1   = 4'd6;
    localparam S_STOP1  = 4'd7;
    localparam S_STOP2  = 4'd8;
    localparam S_STOP3  = 4'd9;
    localparam S_WAIT   = 4'd10;

    reg [3:0] state;

    // =========================================================
    // 2. 통신 속도 설정
    // =========================================================
    
    localparam TICKS_PER_STATE = 500; // 200kHz

    reg [15:0] tick_cnt;
    reg        tick;

    always @(posedge clk) begin
        if (reset) begin
            tick_cnt <= 16'd0;
            tick     <= 1'b0;
        end else begin
            if (tick_cnt == TICKS_PER_STATE-1) begin
                tick_cnt <= 16'd0;
                tick     <= 1'b1;
            end else begin
                tick_cnt <= tick_cnt + 16'd1;
                tick     <= 1'b0;
            end
        end
    end

    // =========================================================
    // 3. I2C 신호 제어
    // =========================================================
    reg scl_reg;
    reg sda_out; //보내고 싶은 값
    reg sda_oe; //1: 출력 모드 0: 입력/대기 모드

    assign oled_scl = scl_reg;
    assign oled_sda = sda_oe ? sda_out : 1'bz; //sda_oe = 1 이면 sda_out을 내보냄
                                               //sda_oe = 0 이면 High-Z

    // =========================================================
    // 4. 초기화 데이터 배열 (128x32 설정)
    // =========================================================
    localparam integer N_BYTES = 40; 

    reg [7:0] tx_data [0:N_BYTES-1];

    initial begin
        tx_data[0] = 8'h78;       // I2C Address(Slave Address)
        
        //tx_data[홀수] = 8'h30
        //명령어를 보낼 때마다 앞에 0x80을 붙여서 바로 다음에 오는 바이트는
        //명령어니까 실행하라는 뜻
        tx_data[1] = 8'h80; tx_data[2] = 8'hAE;  // Display OFF
        tx_data[3] = 8'h80; tx_data[4] = 8'hD5;  // Clock Divide
        tx_data[5] = 8'h80; tx_data[6] = 8'h80;
        
        tx_data[7] = 8'h80; tx_data[8] = 8'hA8;  // Multiplex Ratio
        tx_data[9] = 8'h80; tx_data[10]= 8'h1F;  // 32 lines (128x32)
        
        tx_data[11]= 8'h80; tx_data[12]= 8'hD3;  // Display Offset
        tx_data[13]= 8'h80; tx_data[14]= 8'h00;
        
        tx_data[15]= 8'h80; tx_data[16]= 8'h40;  // Start Line 0
        
        tx_data[17]= 8'h80; tx_data[18]= 8'h8D;  // Charge Pump
        tx_data[19]= 8'h80; tx_data[20]= 8'h14;  // Enable
        
        tx_data[21]= 8'h80; tx_data[22]= 8'h20;  // Memory Mode
        tx_data[23]= 8'h80; tx_data[24]= 8'h00;  // Horizontal
        
        tx_data[25]= 8'h80; tx_data[26]= 8'hA1;  // Segment Remap
        tx_data[27]= 8'h80; tx_data[28]= 8'hC8;  // COM Direction
        
        tx_data[29]= 8'h80; tx_data[30]= 8'hDA;  // COM Pins
        tx_data[31]= 8'h80; tx_data[32]= 8'h02;  // Sequential (128x32)
        
        tx_data[33]= 8'h80; tx_data[34]= 8'h81;  // Contrast
        tx_data[35]= 8'h80; tx_data[36]= 8'h8F;
        
        tx_data[37]= 8'h80; tx_data[38]= 8'hAF;  // Display ON
        tx_data[39]= 8'h40;  // Data mode
    end

    reg [7:0] cur_byte;
    reg [5:0] byte_idx;   
    reg [2:0] bit_idx;
    reg [9:0] clear_cnt;  // 128x32 = 512 bytes (0~511)

    // =========================================================
    // 5. 시간 동기화
    // =========================================================
    // 3단 동기화기를 통해 안정된 초 신호를 받음
    reg [7:0] sec_reg1, sec_reg2, sec_reg3;
    
    always @(posedge clk) begin
        if (reset) begin
            sec_reg1 <= 8'hFF;
            sec_reg2 <= 8'hFF;
            sec_reg3 <= 8'hFF;
        end else begin
            sec_reg1 <= sec;
            sec_reg2 <= sec_reg1;
            sec_reg3 <= sec_reg2;
        end
    end
    
    wire [7:0] sec_stable = sec_reg3;
    
    reg [7:0] sec_prev;
    wire sec_changed = (sec_stable != sec_prev);
    
    // =========================================================
    // 6. 시간 값 관리
    // =========================================================
    // 시간이 1초 지났다는 sec_changed 신호를 받고 FSM 시작

    reg [7:0] display_hour, display_min, display_sec;
    reg init_done;
    reg update_request;

    always @(posedge clk) begin
        if (reset) begin
            sec_prev <= 8'hFF;
            update_request <= 0;
        end else begin
            if (state == S_WAIT) begin
                if (sec_changed && init_done) begin
                    sec_prev <= sec_stable;
                    update_request <= 1;
                end
            end
            
            if (update_request && state != S_WAIT) begin
                update_request <= 0;
            end
        end
    end

    // =========================================================
    // 7. 폰트 ROM (8x8)
    // =========================================================
    // 숫자를 점 데이터로 변환

    function [7:0] get_font;
        input [3:0] digit;
        input [2:0] row;
        begin
            case (digit)
                4'd0: case (row)
                    3'd0: get_font = 8'b00000000;
                    3'd1: get_font = 8'b00111100;
                    3'd2: get_font = 8'b01100010;
                    3'd3: get_font = 8'b01010010;
                    3'd4: get_font = 8'b01001010;
                    3'd5: get_font = 8'b01000110;
                    3'd6: get_font = 8'b00111100;
                    3'd7: get_font = 8'b00000000;
                endcase
                4'd1: case (row)
                    3'd0: get_font = 8'b00000000;
                    3'd1: get_font = 8'b00000000;
                    3'd2: get_font = 8'b01000010;
                    3'd3: get_font = 8'b01111110;
                    3'd4: get_font = 8'b01000000;
                    3'd5: get_font = 8'b00000000;
                    3'd6: get_font = 8'b00000000;
                    3'd7: get_font = 8'b00000000;
                endcase
                4'd2: case (row)
                    3'd0: get_font = 8'b00000000;
                    3'd1: get_font = 8'b01000010;
                    3'd2: get_font = 8'b01100010;
                    3'd3: get_font = 8'b01010010;
                    3'd4: get_font = 8'b01010010;
                    3'd5: get_font = 8'b01001010;
                    3'd6: get_font = 8'b01000110;
                    3'd7: get_font = 8'b00000000;
                endcase
                4'd3: case (row)
                    3'd0: get_font = 8'b00000000;
                    3'd1: get_font = 8'b00100010;
                    3'd2: get_font = 8'b01000010;
                    3'd3: get_font = 8'b01001010;
                    3'd4: get_font = 8'b01001010;
                    3'd5: get_font = 8'b01001010;
                    3'd6: get_font = 8'b00110100;
                    3'd7: get_font = 8'b00000000;
                endcase
                4'd4: case (row)
                    3'd0: get_font = 8'b00000000;
                    3'd1: get_font = 8'b00011000;
                    3'd2: get_font = 8'b00010100;
                    3'd3: get_font = 8'b00010010;
                    3'd4: get_font = 8'b01111110;
                    3'd5: get_font = 8'b00010000;
                    3'd6: get_font = 8'b00010000;
                    3'd7: get_font = 8'b00000000;
                endcase
                4'd5: case (row)
                    3'd0: get_font = 8'b00000000;
                    3'd1: get_font = 8'b00100110;
                    3'd2: get_font = 8'b01000110;
                    3'd3: get_font = 8'b01000110;
                    3'd4: get_font = 8'b01000110;
                    3'd5: get_font = 8'b01000110;
                    3'd6: get_font = 8'b00111010;
                    3'd7: get_font = 8'b00000000;
                endcase
                4'd6: case (row)
                    3'd0: get_font = 8'b00000000;
                    3'd1: get_font = 8'b00111100;
                    3'd2: get_font = 8'b01001010;
                    3'd3: get_font = 8'b01001010;
                    3'd4: get_font = 8'b01001010;
                    3'd5: get_font = 8'b01001010;
                    3'd6: get_font = 8'b00110000;
                    3'd7: get_font = 8'b00000000;
                endcase
                4'd7: case (row)
                    3'd0: get_font = 8'b00000000;
                    3'd1: get_font = 8'b00000010;
                    3'd2: get_font = 8'b00000010;
                    3'd3: get_font = 8'b01100010;
                    3'd4: get_font = 8'b00010010;
                    3'd5: get_font = 8'b00001010;
                    3'd6: get_font = 8'b00000110;
                    3'd7: get_font = 8'b00000000;
                endcase
                4'd8: case (row)
                    3'd0: get_font = 8'b00000000;
                    3'd1: get_font = 8'b00110100;
                    3'd2: get_font = 8'b01001010;
                    3'd3: get_font = 8'b01001010;
                    3'd4: get_font = 8'b01001010;
                    3'd5: get_font = 8'b01001010;
                    3'd6: get_font = 8'b00110100;
                    3'd7: get_font = 8'b00000000;
                endcase
                4'd9: case (row)
                    3'd0: get_font = 8'b00000000;
                    3'd1: get_font = 8'b00000110;
                    3'd2: get_font = 8'b01001010;
                    3'd3: get_font = 8'b01001010;
                    3'd4: get_font = 8'b01001010;
                    3'd5: get_font = 8'b01001010;
                    3'd6: get_font = 8'b00111100;
                    3'd7: get_font = 8'b00000000;
                endcase
                4'd10: case (row)
                    3'd0: get_font = 8'b00000000;
                    3'd1: get_font = 8'b00000000;
                    3'd2: get_font = 8'b00000000;
                    3'd3: get_font = 8'b00100100;
                    3'd4: get_font = 8'b00000000;
                    3'd5: get_font = 8'b00000000;
                    3'd6: get_font = 8'b00000000;
                    3'd7: get_font = 8'b00000000;
                endcase
                default: get_font = 8'b00000000;
            endcase
        end
    endfunction

    // =========================================================
    // 8. 시간 표시 계산 (128x32 레이아웃)
    // =========================================================
    // 어느 위치에 어느 숫자를 그릴 건지 좌표를 찍음

    reg [7:0] display_byte;
    wire [3:0] h_tens  = display_hour[7:4];
    wire [3:0] h_ones  = display_hour[3:0];
    wire [3:0] m_tens  = display_min[7:4];
    wire [3:0] m_ones  = display_min[3:0];
    wire [3:0] s_tens  = display_sec[7:4];
    wire [3:0] s_ones  = display_sec[3:0];

    // 128x32 = 4 pages × 128 columns
    // Page 구조: 0, 1, 2, 3
    wire [1:0] page_num = clear_cnt[8:7];     // 0~3
    wire [6:0] col_in_page = clear_cnt[6:0];  // 0~127

    always @(*) begin
        // Page 1, 2에 시간 표시 (중앙 배치)
        // 각 숫자 8픽셀, 총 64픽셀
        // 시작 위치: (128-64)/2 = 32
        if (page_num >= 1 && page_num <= 2) begin
            case (col_in_page)
                // 시 십의자리 (32~39)
                7'd32, 7'd33, 7'd34, 7'd35, 7'd36, 7'd37, 7'd38, 7'd39:
                    display_byte = get_font(h_tens, col_in_page[2:0]);
                
                // 시 일의자리 (40~47)
                7'd40, 7'd41, 7'd42, 7'd43, 7'd44, 7'd45, 7'd46, 7'd47:
                    display_byte = get_font(h_ones, col_in_page[2:0]);
                
                // ':' (48~55)
                7'd48, 7'd49, 7'd50, 7'd51, 7'd52, 7'd53, 7'd54, 7'd55:
                    display_byte = get_font(4'd10, col_in_page[2:0]);
                
                // 분 십의자리 (56~63)
                7'd56, 7'd57, 7'd58, 7'd59, 7'd60, 7'd61, 7'd62, 7'd63:
                    display_byte = get_font(m_tens, col_in_page[2:0]);
                
                // 분 일의자리 (64~71)
                7'd64, 7'd65, 7'd66, 7'd67, 7'd68, 7'd69, 7'd70, 7'd71:
                    display_byte = get_font(m_ones, col_in_page[2:0]);
                
                // ':' (72~79)
                7'd72, 7'd73, 7'd74, 7'd75, 7'd76, 7'd77, 7'd78, 7'd79:
                    display_byte = get_font(4'd10, col_in_page[2:0]);
                
                // 초 십의자리 (80~87)
                7'd80, 7'd81, 7'd82, 7'd83, 7'd84, 7'd85, 7'd86, 7'd87:
                    display_byte = get_font(s_tens, col_in_page[2:0]);
                
                // 초 일의자리 (88~95)
                7'd88, 7'd89, 7'd90, 7'd91, 7'd92, 7'd93, 7'd94, 7'd95:
                    display_byte = get_font(s_ones, col_in_page[2:0]);
                
                default:
                    display_byte = 8'h00;
            endcase
        end else begin
            display_byte = 8'h00;
        end
    end


    // =========================================================
    // 9. 메인 FSM
    // =========================================================
    reg [15:0] power_cnt;

    always @(posedge clk) begin
        if (reset) begin
            state    <= S_IDLE;
            scl_reg  <= 1'b1;
            sda_out  <= 1'b1;
            sda_oe   <= 1'b1;
            byte_idx <= 6'd0;
            cur_byte <= 8'h00;
            bit_idx  <= 3'd7;
            power_cnt <= 16'd0;
            clear_cnt <= 10'd0;
            display_hour <= 8'h00;
            display_min  <= 8'h00;
            display_sec  <= 8'h00;
            init_done <= 0;
        end else begin
            if (tick) begin
                case (state)
                    S_IDLE: begin
                        scl_reg  <= 1'b1;
                        sda_out  <= 1'b1;
                        sda_oe   <= 1'b1;
                        byte_idx <= 6'd0;
                        clear_cnt <= 10'd0;
                        cur_byte <= tx_data[0];
                        bit_idx  <= 3'd7;
                        
                        if (power_cnt == 16'hFFFF) 
                             state <= S_START1;
                        else 
                             power_cnt <= power_cnt + 16'd1;
                    end

                    S_START1: begin 
                        scl_reg <= 1'b1; 
                        sda_out <= 1'b1; 
                        sda_oe <= 1'b1;
                        display_hour <= hour;
                        display_min  <= min;
                        display_sec  <= sec_stable;
                        state <= S_START2;
                    end
                    
                    S_START2: begin //start 신호
                        scl_reg <= 1'b1; 
                        sda_out <= 1'b0; 
                        sda_oe <= 1'b1;
                        state <= S_START3; 
                    end
                    
                    S_START3: begin
                        scl_reg <= 1'b0; 
                        sda_out <= 1'b0; 
                        sda_oe  <= 1'b1;
                        state   <= S_BIT0;
                    end

                    S_BIT0: begin 
                        scl_reg <= 1'b0; 
                        sda_out <= cur_byte[bit_idx]; 
                        sda_oe  <= 1'b1;
                        state   <= S_BIT1;
                    end
                    
                    S_BIT1: begin 
                        scl_reg <= 1'b1;
                        if (bit_idx == 0) 
                            state <= S_ACK0;
                        else begin
                            bit_idx <= bit_idx - 1;
                            state   <= S_BIT0;
                        end
                    end

                    S_ACK0: begin 
                        scl_reg <= 1'b0;
                        sda_oe  <= 1'b0; 
                        state   <= S_ACK1;
                    end
                    
                    S_ACK1: begin 
                        scl_reg <= 1'b1;
                        
                        if (byte_idx < N_BYTES-1) begin
                            byte_idx <= byte_idx + 6'd1;
                            cur_byte <= tx_data[byte_idx + 1];
                            bit_idx  <= 3'd7;
                            state    <= S_BIT0;
                        end
                        else if (clear_cnt < 512) begin  // 128x32 = 512 bytes
                            cur_byte <= display_byte;
                            clear_cnt <= clear_cnt + 10'd1;
                            bit_idx   <= 3'd7;
                            state     <= S_BIT0;
                        end
                        else begin
                            state <= S_STOP1;
                        end
                    end

                    S_STOP1: begin 
                        scl_reg <= 1'b0; 
                        sda_out <= 1'b0; 
                        sda_oe <= 1'b1;
                        state <= S_STOP2;
                    end
                    
                    S_STOP2: begin 
                        scl_reg <= 1'b1; 
                        sda_out <= 1'b0; 
                        sda_oe <= 1'b1;
                        state <= S_STOP3;
                    end
                    
                    S_STOP3: begin 
                        scl_reg <= 1'b1; 
                        sda_out <= 1'b1; 
                        sda_oe <= 1'b1;
                        init_done <= 1;
                        state <= S_WAIT; 
                    end

                    S_WAIT: begin
                        if (update_request) begin
                            byte_idx <= 6'd0;
                            clear_cnt <= 10'd0;
                            cur_byte <= tx_data[0];
                            bit_idx  <= 3'd7;
                            state    <= S_START1;
                        end
                    end

                    default: state <= S_IDLE;
                endcase
            end
        end
    end

endmodule

// ===========================================================================================================================================================================
