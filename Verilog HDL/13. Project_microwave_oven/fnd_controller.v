`timescale 1ns / 1ps

// 9-모듈 아키텍처의 8번: FND 컨트롤러 ('근육')
// [!] Circle Animation 로직 수정
module fnd_controller (
    input wire clk,
    input wire reset,
    input wire tick_1khz,     // (clock_divider) 1ms 틱 (스캔용)
    input wire tick_1s,       // (clock_divider) 1s 틱 (애니메이션/깜빡임용)
    input wire [1:0] fnd_mode_in,   // 00: Time, 01: Play, 10: End
    input wire [13:0] seg_data_in, // {min_t, min_o, sec_t, sec_o}
    
    output reg [3:0] an, 
    // [!] 7비트 세그먼트 (Common Anode, Active-Low, A=seg[0]...G=seg[6])
    output reg [6:0] seg 
);

    // --- 1. BCD 데이터 분해 ---
    wire [2:0] min_t = seg_data_in[13:11];
    wire [3:0] min_o = seg_data_in[10:7];
    wire [2:0] sec_t = seg_data_in[6:4];
    wire [3:0] sec_o = seg_data_in[3:0];
    
    // ========== [!] 1. 애니메이션용 10Hz (100ms) 틱 추가 ==========
    parameter CNT_10HZ = 10_000_000; // 100MHz / 10M = 10Hz (100ms)
    reg [$clog2(CNT_10HZ)-1:0] cnt_10hz;
    wire tick_10hz;
    
    always @(posedge clk or posedge reset) begin
        if (reset) cnt_10hz <= 0;
        else if (cnt_10hz == CNT_10HZ - 1) cnt_10hz <= 0;
        else cnt_10hz <= cnt_10hz + 1;
    end
    assign tick_10hz = (cnt_10hz == CNT_10HZ - 1);
    // ==========================================================

    // --- 2. 1초 틱 기반 '모드' 플래그 ---
    reg display_is_time; // 'PLAY' 모드 (1s 교차)
    reg end_blink_on;    // 'END' 모드 (1s 깜빡임)
    // [!] 2. 12단계 애니메이션 스텝 레지스터 추가
    reg [3:0] anim_step;     // 0 ~ 11

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            display_is_time <= 1'b1;
            end_blink_on    <= 1'b1;
            anim_step <= 0;
        end else begin
            // --- 1초 틱 (1Hz) 기반 로직 ---
            if (tick_1s) begin
                if (fnd_mode_in == 2'b01) // PLAY 모드 (시간/Circle 교차)
                    display_is_time <= ~display_is_time;
                else
                    display_is_time <= 1'b1;
                
                if (fnd_mode_in == 2'b10) // END 모드 (ON/OFF 깜빡임)
                    end_blink_on <= ~end_blink_on;
                else
                    end_blink_on <= 1'b1;
            end
            
            // --- 100ms 틱 (10Hz) 기반 로직 ---
            // [!] 3. 100ms마다 애니메이션 스텝 갱신
            if (tick_10hz) begin
                // 'PLAY' 모드이고, '애니메이션' 차례일 때만 스텝 증가
                if (fnd_mode_in == 2'b01 && !display_is_time) begin
                    if (anim_step == 11) anim_step <= 0;
                    else anim_step <= anim_step + 1;
                end else begin
                    anim_step <= 0; // 다른 모드일 땐 항상 0으로 리셋
                end
            end
        end
    end
    
    // --- 3. FND MUX 스캐너 (1kHz 틱) ---
    reg [1:0] fnd_mux_cnt; 
    always @(posedge clk or posedge reset) begin
        if (reset) fnd_mux_cnt <= 0;
        else if (tick_1khz) fnd_mux_cnt <= fnd_mux_cnt + 1;
    end
    
    // --- 4. BCD to 7-Segment 디코더 (조합) ---
    function [6:0] bcd_to_7seg (input [3:0] bcd);
        case (bcd) // Common Anode, Active-Low (A=0,B=1...G=6)
            0: bcd_to_7seg = 7'b1000000; // G off
            1: bcd_to_7seg = 7'b1111001; // B, C on
            2: bcd_to_7seg = 7'b0100100; // A, B, G, E, D on
            3: bcd_to_7seg = 7'b0110000; // A, B, G, C, D on
            4: bcd_to_7seg = 7'b0011001; // F, G, B, C on
            5: bcd_to_7seg = 7'b0010010; // A, F, G, C, D on
            6: bcd_to_7seg = 7'b0000010; // A, F, G, E, C, D on
            7: bcd_to_7seg = 7'b1111000; // A, B, C on
            8: bcd_to_7seg = 7'b0000000; // All on
            9: bcd_to_7seg = 7'b0010000; // A, F, G, B, C, D on
            default: bcd_to_7seg = 7'b1111111; // OFF
        endcase
    endfunction
    
    // --- 5. 최종 FND 출력 MUX (조합) ---
    reg [3:0] fnd_data_out;
    reg [6:0] fnd_seg_out; // 7-Segment 데이터 임시 저장

    always @(*) begin
        // 기본값: OFF (래치 방지)
        an = 4'b1111;
        fnd_seg_out = 7'b1111111;
        fnd_data_out = 4'd15; // (OFF BCD)

        // '두뇌'의 '모드' 명령에 따라 분기
        case(fnd_mode_in)
            // 00: IDLE/PAUSE (항상 시간 표시)
            2'b00: begin 
                case(fnd_mux_cnt)
                    2'b00: begin an = 4'b1110; fnd_data_out = sec_o; end
                    2'b01: begin an = 4'b1101; fnd_data_out = sec_t; end
                    2'b10: begin an = 4'b1011; fnd_data_out = min_o; end
                    2'b11: begin an = 4'b0111; fnd_data_out = min_t; end
                endcase
                fnd_seg_out = bcd_to_7seg(fnd_data_out);
            end
            
            // 01: PLAY (시간 / Circle 교차)
            2'b01: begin 
                if (display_is_time) begin // A. 시간 표시
                    case(fnd_mux_cnt)
                        2'b00: begin an = 4'b1110; fnd_data_out = sec_o; end
                        2'b01: begin an = 4'b1101; fnd_data_out = sec_t; end
                        2'b10: begin an = 4'b1011; fnd_data_out = min_o; end
                        2'b11: begin an = 4'b0111; fnd_data_out = min_t; end
                    endcase
                    fnd_seg_out = bcd_to_7seg(fnd_data_out);
                
                // [!] 4. 12-Step Circle Animation 삽입
                end else begin // B. Circle 애니메이션 표시
                    case (anim_step)
                        // (seg[0]=A, 1=B, 2=C, 3=D, 4=E, 5=F, 6=G)
                        // A=1111110, B=1111101, C=1111011, D=1110111, E=1101111, F=1011111
                        4'd0: begin // 1000자리 A (상단)
                            if (fnd_mux_cnt == 2'b11) begin an = 4'b0111; fnd_seg_out = 7'b1111110; end
                        end
                        4'd1: begin // 100자리 A (상단)
                            if (fnd_mux_cnt == 2'b10) begin an = 4'b1011; fnd_seg_out = 7'b1111110; end
                        end
                        4'd2: begin // 10자리 A (상단)
                            if (fnd_mux_cnt == 2'b01) begin an = 4'b1101; fnd_seg_out = 7'b1111110; end
                        end
                        4'd3: begin // 1자리 A (상단)
                            if (fnd_mux_cnt == 2'b00) begin an = 4'b1110; fnd_seg_out = 7'b1111110; end
                        end
                        4'd4: begin // 1자리 B (우상단)
                            if (fnd_mux_cnt == 2'b00) begin an = 4'b1110; fnd_seg_out = 7'b1111101; end
                        end
                        4'd5: begin // 1자리 C (우하단)
                            if (fnd_mux_cnt == 2'b00) begin an = 4'b1110; fnd_seg_out = 7'b1111011; end
                        end
                        4'd6: begin // 1자리 D (하단)
                            if (fnd_mux_cnt == 2'b00) begin an = 4'b1110; fnd_seg_out = 7'b1110111; end
                        end
                        4'd7: begin // 10자리 D (하단)
                            if (fnd_mux_cnt == 2'b01) begin an = 4'b1101; fnd_seg_out = 7'b1110111; end
                        end
                        4'd8: begin // 100자리 D (하단)
                            if (fnd_mux_cnt == 2'b10) begin an = 4'b1011; fnd_seg_out = 7'b1110111; end
                        end
                        4'd9: begin // 1000자리 D (하단)
                            if (fnd_mux_cnt == 2'b11) begin an = 4'b0111; fnd_seg_out = 7'b1110111; end
                        end
                        4'd10: begin // 1000자리 E (좌하단)
                            if (fnd_mux_cnt == 2'b11) begin an = 4'b0111; fnd_seg_out = 7'b1101111; end
                        end
                        4'd11: begin // 1000자리 F (좌상단)
                            if (fnd_mux_cnt == 2'b11) begin an = 4'b0111; fnd_seg_out = 7'b1011111; end
                        end
                        default: begin
                            an = 4'b1111; fnd_seg_out = 7'b1111111;
                        end
                    endcase
                end
            end
            
            // 10: END (깜빡임)
            2'b10: begin 
                if (end_blink_on) begin // 00:00 표시
                    case(fnd_mux_cnt)
                        2'b00: begin an = 4'b1110; fnd_data_out = 0; end
                        2'b01: begin an = 4'b1101; fnd_data_out = 0; end
                        2'b10: begin an = 4'b1011; fnd_data_out = 0; end
                        2'b11: begin an = 4'b0111; fnd_data_out = 0; end
                    endcase
                    fnd_seg_out = bcd_to_7seg(fnd_data_out);
                end // else: OFF (기본값)
            end
        endcase
        
        // 최종 세그먼트 출력
        // (애니메이션은 bcd_to_7seg를 거치지 않음)
        seg = fnd_seg_out; 
    end

endmodule