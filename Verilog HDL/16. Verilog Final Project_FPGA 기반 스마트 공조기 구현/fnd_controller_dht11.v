`timescale 1ns / 1ps

module fnd_controller_dht11 (
    input wire clk,
    input wire reset,
    input wire tick_1khz,     // 스캔용 1ms 틱
    input wire tick_1s,       // 애니메이션용 1s 틱
    input wire [1:0] fnd_mode_in,   // 00: Time, 01: Play, 10: End , 11:온습도
    
    input wire [13:0] seg_data_in, // 시간 데이터 {min_t, min_o, sec_t, sec_o}
    
    // ] DHT11 온습도 데이터 입력
    input wire [7:0] humi_INT_out,
    input wire [7:0] humi_REAL_out, // (현재는 정수만 표시하므로 연결만 해둠)
    input wire [7:0] temp_INT_out,
    input wire [7:0] temp_REAL_out, // (연결만 해둠)
    input wire data_valid,          // 데이터 유효성 체크
    
    output reg [3:0] an, 
    output reg [7:0] seg // [수정] 8비트 (DP 포함)
);

    // --- 1. 데이터 분해 (시간) ---
    wire [3:0] min_t = seg_data_in[13:11]; // 3bit
    wire [3:0] min_o = seg_data_in[10:7];  // 4bit 
    wire [3:0] sec_t = seg_data_in[6:4];   // 3bit
    wire [3:0] sec_o = seg_data_in[3:0];   // 4bit

    // 정수부 2자리씩 분리 (예: 25도 -> 2, 5)
    wire [3:0] humi_1000 = (humi_INT_out  / 10) %10;
    wire [3:0] humi_100  = (humi_INT_out % 10);
    wire [3:0] humi_10 = (humi_REAL_out / 10) % 10;
    wire [3:0] humi_1  = (humi_REAL_out % 10);

    wire [3:0] temp_1000 = (temp_INT_out / 10) % 10;
    wire [3:0] temp_100  = (temp_INT_out % 10);
    wire [3:0] temp_10 = (temp_REAL_out / 10) % 10;
    wire [3:0] temp_1  = (temp_REAL_out % 10);

    // --- 2. 애니메이션 카운터 ---
    reg [3:0] anim_step; // 0~11
    reg display_is_time; // PLAY 모드에서 교차 디스플레이용
    reg end_blink_on;    // END 모드 깜빡임용

    reg [1:0] swap_temp_humi; //
    reg [28:0] swap_temp_humi_cnt;

    localparam CHAR_C = 7'b1000110; //온도 표시 C
    localparam CHAR_H = 7'b0001001;// 습도 표시 H

    // 10Hz (100ms) 틱 생성
    reg [$clog2(10_000_000)-1:0] cnt_10hz;
    wire tick_10hz = (cnt_10hz == 10_000_000 - 1);

always @(posedge clk, posedge reset) begin///온도와 습도 번갈아 표시하기 위한 카운터
        if(reset) begin
            swap_temp_humi_cnt <= 0;
        end else begin
            if (tick_1s) begin 
                swap_temp_humi <= ~swap_temp_humi;  
            end 
        end
    end 


    always @(posedge clk or posedge reset) begin
        if (reset) cnt_10hz <= 0;
        else if (tick_10hz) cnt_10hz <= 0;
        else cnt_10hz <= cnt_10hz + 1;
    end

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            anim_step <= 0;
            display_is_time <= 1;
            end_blink_on <= 1;
        end else begin
            if (tick_1s) begin
                if (fnd_mode_in == 2'b01) display_is_time <= ~display_is_time;
                else display_is_time <= 1; // 다른 모드에선 항상 데이터 표시
                
                if (fnd_mode_in == 2'b10) end_blink_on <= ~end_blink_on;
                else end_blink_on <= 1;
            end
            
            if (tick_10hz) begin
                if (fnd_mode_in == 2'b01 && !display_is_time) begin
                    if (anim_step == 11) anim_step <= 0;
                    else anim_step <= anim_step + 1;
                end else begin
                    anim_step <= 0;
                end
            end
        end
    end

    // --- 3. FND MUX 스캐너 ---
    reg [1:0] fnd_mux_cnt;
    always @(posedge clk or posedge reset) begin
        if (reset) fnd_mux_cnt <= 0;
        else if (tick_1khz) fnd_mux_cnt <= fnd_mux_cnt + 1;
    end

    // --- 4. BCD to 7-Segment 디코더 ---
    function [6:0] bcd_to_7seg(input [3:0] val);
        case (val)
            4'h0: bcd_to_7seg = 7'b1000000;
            4'h1: bcd_to_7seg = 7'b1111001;
            4'h2: bcd_to_7seg = 7'b0100100;
            4'h3: bcd_to_7seg = 7'b0110000;
            4'h4: bcd_to_7seg = 7'b0011001;
            4'h5: bcd_to_7seg = 7'b0010010;
            4'h6: bcd_to_7seg = 7'b0000010;
            4'h7: bcd_to_7seg = 7'b1111000;
            4'h8: bcd_to_7seg = 7'b0000000;
            4'h9: bcd_to_7seg = 7'b0010000;
            default: bcd_to_7seg = 7'b1111111; // Off
        endcase
    endfunction

    // --- 5. 최종 출력 로직 ---
    reg [3:0] current_digit_val;
    reg [6:0] seg_temp;
    reg dp_val; //점 켜고 끄기 위한 
    always @(*) begin
        // 초기화
        an = 4'b1111;
        current_digit_val = 0;
        seg_temp = 7'b1111111;
        dp_val = 1; // 기본적으로 소수점 끔 (OFF)

        case (fnd_mode_in)
            // 00: IDLE (기본: 시간 표시) 
            // 현재는 시간만 표시하도록 유지
            2'b00: begin 
                case(fnd_mux_cnt)
                    2'b00: begin an = 4'b1110; current_digit_val = sec_o; end
                    2'b01: begin an = 4'b1101; current_digit_val = sec_t; end
                    2'b10: begin an = 4'b1011; current_digit_val = min_o; end
                    2'b11: begin an = 4'b0111; current_digit_val = min_t; end
                endcase
                seg_temp = bcd_to_7seg(current_digit_val);
            end

            // 01: PLAY (시간 <-> 애니메이션)
            2'b01: begin
                if (display_is_time) begin
                     case(fnd_mux_cnt)
                        2'b00: begin an = 4'b1110; current_digit_val = sec_o; end
                        2'b01: begin an = 4'b1101; current_digit_val = sec_t; end
                        2'b10: begin an = 4'b1011; current_digit_val = min_o; end
                        2'b11: begin an = 4'b0111; current_digit_val = min_t; end
                    endcase
                    seg_temp = bcd_to_7seg(current_digit_val);
                end else begin
                    // 써클 애니메이션 로직 (기존 코드 유지)
                    case (anim_step)
                        0: if(fnd_mux_cnt==3) begin an=4'b0111; seg_temp=7'b1111110; end // A
                        1: if(fnd_mux_cnt==2) begin an=4'b1011; seg_temp=7'b1111110; end // A
                        2: if(fnd_mux_cnt==1) begin an=4'b1101; seg_temp=7'b1111110; end // A
                        3: if(fnd_mux_cnt==0) begin an=4'b1110; seg_temp=7'b1111110; end // A
                        4: if(fnd_mux_cnt==0) begin an=4'b1110; seg_temp=7'b1111101; end // B
                        5: if(fnd_mux_cnt==0) begin an=4'b1110; seg_temp=7'b1111011; end // C
                        6: if(fnd_mux_cnt==0) begin an=4'b1110; seg_temp=7'b1110111; end // D
                        7: if(fnd_mux_cnt==1) begin an=4'b1101; seg_temp=7'b1110111; end // D
                        8: if(fnd_mux_cnt==2) begin an=4'b1011; seg_temp=7'b1110111; end // D
                        9: if(fnd_mux_cnt==3) begin an=4'b0111; seg_temp=7'b1110111; end // D
                        10: if(fnd_mux_cnt==3) begin an=4'b0111; seg_temp=7'b1101111; end // E
                        11: if(fnd_mux_cnt==3) begin an=4'b0111; seg_temp=7'b1011111; end // F
                        default: begin an=4'b1111; seg_temp=7'b1111111; end
                    endcase
                end
            end

            // 10: END (00:00 깜빡임)
            2'b10: begin
                if (end_blink_on) begin
                     case(fnd_mux_cnt)
                        2'b00: begin an = 4'b1110; current_digit_val = 0; end
                        2'b01: begin an = 4'b1101; current_digit_val = 0; end
                        2'b10: begin an = 4'b1011; current_digit_val = 0; end
                        2'b11: begin an = 4'b0111; current_digit_val = 0; end
                    endcase
                    seg_temp = bcd_to_7seg(current_digit_val);
                end
            end
            
            // 표시 형식: 습도(2자리) 온도(2자리) 예: "50 24"
            2'b11: begin
                if(swap_temp_humi)begin  //1초마다 스왑되게
                     case(fnd_mux_cnt)       //예시  49.3H
                        2'b00: begin an = 4'b1110; seg_temp = CHAR_H; end  // 습도 H표시 ==> 직접넣음
                        2'b01: begin an = 4'b1101; current_digit_val = humi_10; seg_temp = bcd_to_7seg(current_digit_val); end // 습도 실수 10의자리
                        2'b10: begin an = 4'b1011; current_digit_val = humi_100; seg_temp = bcd_to_7seg(current_digit_val); dp_val = 0; end // 습도 정수 1의자리, 점도 킴
                        2'b11: begin an = 4'b0111; current_digit_val = humi_1000; seg_temp = bcd_to_7seg(current_digit_val); end // 습도 정수 10의자리
                    endcase
                end else begin
                    case(fnd_mux_cnt)       //예시  25.3C
                        2'b00: begin an = 4'b1110; seg_temp = CHAR_C; end  // 온도 C표시
                        2'b01: begin an = 4'b1101; current_digit_val = temp_10; seg_temp = bcd_to_7seg(current_digit_val); end // 온도 실수 10의자리
                        2'b10: begin an = 4'b1011; current_digit_val = temp_100; seg_temp = bcd_to_7seg(current_digit_val); dp_val = 0; end  // 온도 정수 1의자리, 점도 킴
                        2'b11: begin an = 4'b0111; current_digit_val = temp_1000; seg_temp = bcd_to_7seg(current_digit_val); end // 온도 정수 10의자리
                    endcase  
                end
            end
        endcase
        
        // 최종 출력 (DP 비트 추가하여 8비트 맞춤)
        seg = {dp_val, seg_temp}; 
    end
endmodule