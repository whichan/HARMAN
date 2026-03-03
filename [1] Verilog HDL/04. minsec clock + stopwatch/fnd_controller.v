`timescale 1ns / 1ps

module fnd_controller(
    input clk,
    input reset,   // btnU
    input [13:0] in_data,
    input dp_blink_in,  //controller부터 1초 깜박임 카운터 신호 받음
    input is_idle_anim, //IDLE animation 활성화 
    input [3:0] anim_step, //애니메이션 step
    output [3:0] an,
    output [7:0] seg
    );

    wire [1:0] w_sel;
    wire [3:0] w_d1, w_d10, w_d100, w_d1000;

    fnd_digit_select u_fnd_digit_select(
        .clk(clk),
        .reset(reset),
        .sel(w_sel)   // 00 01 10 11 : 1ms마다 바뀜
    );

    bin2bcd4digit u_bin2bcd4digit(
        .in_data(in_data),
        .d1(w_d1),
        .d10(w_d10),
        .d100(w_d100),
        .d1000(w_d1000)   
    );

    fnd_display u_fnd_display(
        .digit_sel(w_sel),
        .d1(w_d1),
        .d10(w_d10),
        .d100(w_d100),
        .d1000(w_d1000),
        .dp_blink(dp_blink_in),
        .is_idle_anim(is_idle_anim),
        .anim_step(anim_step),
        .an(an),
        .seg(seg)
    );

endmodule
//--------------------------------------------------------------
// 1ms마다 fnd를 display하기 위해서 digit 1자리씩 선택
// 4ms까지는 잔상효과가 있다. 그 이상의 시간 지연은 깜밖임 현상 발생 된다. 
//--------------------------------------------------------------
module fnd_digit_select (
    input clk,
    input reset,
    output reg [1:0] sel   // 00 01 10 11 : 1ms마다 바뀜
);

    reg [$clog2(100_000)-1:0]  r_1ms_counter=0; //17비트

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            r_1ms_counter <= 0;
            sel <= 0;
        end else begin
            if (r_1ms_counter == 100_000-1) begin    // 1ms 
                 r_1ms_counter <= 0;
                 sel <= sel + 1; 
            end else begin
                r_1ms_counter <= r_1ms_counter + 1; 
            end 
        end       
    end
endmodule

//-------------------------------------------------------
//  input [13:0]  in_data : 14bit로써 fnd에 최대 9999까지 표현 하기 위한 bin size 
//  0~9999 천/백/십/일  자리숫자 0~9 까지로 BCD로 4bit 표현 
//-------------------------------------------------------
module bin2bcd4digit (
    input [13:0]  in_data,
    output [3:0]  d1,
    output [3:0]  d10,
    output [3:0]  d100,
    output [3:0]  d1000    
);
    assign d1 = in_data % 10;
    assign d10 = (in_data / 10) % 10;
    assign d100 = (in_data / 100) % 10;
    assign d1000 = (in_data / 1000) % 10;
endmodule

//-----------------------------------------------------------
//  bcd값을 fnd에 출력 하는 module 
//-----------------------------------------------------------
module fnd_display (
    input [1:0] digit_sel,
    input [3:0]  d1,
    input [3:0]  d10,
    input [3:0]  d100,
    input [3:0]  d1000,
    input dp_blink,
    input is_idle_anim,
    input [3:0] anim_step,
    output reg [3:0]  an,
    output reg [7:0]  seg    
);
    
    reg [3:0] bcd_data;

    always @(*) begin
        
        // ===== IDLE 애니메이션 모드 =====
        if (is_idle_anim) begin
            // 모든 자리 끄기 (기본값)
            an = 4'b1111;
            seg = 8'b11111111;
            
            // 애니메이션 스텝에 따라 특정 자리의 특정 세그먼트만 켜기
            case (anim_step)
                // 1000자리 A (상단)
                4'd0: begin
                    if (digit_sel == 2'b11) begin  // 1000자리
                        an = 4'b0111;
                        seg = 8'b11111110;  // A 세그먼트만 (상단)
                    end
                end
                
                // 100자리 A (상단)
                4'd1: begin
                    if (digit_sel == 2'b10) begin  // 100자리
                        an = 4'b1011;
                        seg = 8'b11111110;  // A 세그먼트
                    end
                end
                
                // 10자리 A (상단)
                4'd2: begin
                    if (digit_sel == 2'b01) begin  // 10자리
                        an = 4'b1101;
                        seg = 8'b11111110;  // A 세그먼트
                    end
                end
                
                // 1자리 A (상단)
                4'd3: begin
                    if (digit_sel == 2'b00) begin  // 1자리
                        an = 4'b1110;
                        seg = 8'b11111110;  // A 세그먼트
                    end
                end
                
                // 1자리 B (우상단)
                4'd4: begin
                    if (digit_sel == 2'b00) begin
                        an = 4'b1110;
                        seg = 8'b11111101;  // B 세그먼트
                    end
                end
                
                // 1자리 C (우하단)
                4'd5: begin
                    if (digit_sel == 2'b00) begin
                        an = 4'b1110;
                        seg = 8'b11111011;  // C 세그먼트
                    end
                end
                
                // 1자리 D (하단)
                4'd6: begin
                    if (digit_sel == 2'b00) begin
                        an = 4'b1110;
                        seg = 8'b11110111;  // D 세그먼트
                    end
                end
                
                // 10자리 D (하단)
                4'd7: begin
                    if (digit_sel == 2'b01) begin
                        an = 4'b1101;
                        seg = 8'b11110111;  // D 세그먼트
                    end
                end
                
                // 100자리 D (하단)
                4'd8: begin
                    if (digit_sel == 2'b10) begin
                        an = 4'b1011;
                        seg = 8'b11110111;  // D 세그먼트
                    end
                end
                
                // 1000자리 D (하단)
                4'd9: begin
                    if (digit_sel == 2'b11) begin
                        an = 4'b0111;
                        seg = 8'b11110111;  // D 세그먼트
                    end
                end
                
                // 1000자리 E (좌하단)
                4'd10: begin
                    if (digit_sel == 2'b11) begin
                        an = 4'b0111;
                        seg = 8'b11101111;  // E 세그먼트
                    end
                end
                
                // 1000자리 F (좌상단)
                4'd11: begin
                    if (digit_sel == 2'b11) begin
                        an = 4'b0111;
                        seg = 8'b11011111;  // F 세그먼트
                    end
                end
                
                default: begin
                    an = 4'b1111;
                    seg = 8'b11111111;
                end
            endcase
        end 
        
        // ===== 일반 숫자 표시 모드 =====
        else begin
            // --- 1. MUX 로직 (자릿수 선택) ---
            case(digit_sel)
                2'b00: begin bcd_data = d1;    an = 4'b1110; end // 1의 자리
                2'b01: begin bcd_data = d10;   an = 4'b1101; end // 10의 자리
                2'b10: begin bcd_data = d100;  an = 4'b1011; end // 100의 자리
                2'b11: begin bcd_data = d1000; an = 4'b0111; end // 1000의 자리
                default: begin bcd_data = 4'b0000; an = 4'b1111; end
            endcase
            
            // --- 2. Decoder 로직 (BCD -> 7-Segment) ---
            case(bcd_data)
                4'd0: seg = 8'b11000000;  // 0
                4'd1: seg = 8'b11111001;  // 1
                4'd2: seg = 8'b10100100;  // 2
                4'd3: seg = 8'b10110000;  // 3
                4'd4: seg = 8'b10011001;  // 4
                4'd5: seg = 8'b10010010;  // 5
                4'd6: seg = 8'b10000010;  // 6
                4'd7: seg = 8'b11111000;  // 7
                4'd8: seg = 8'b10000000;  // 8
                4'd9: seg = 8'b10010000;  // 9
                default: seg = 8'b11111111;  // fnd all off
            endcase

            // --- 3. [DP Blink 로직] ---
            if (dp_blink == 1'b1 && digit_sel == 2'b10) begin
                seg[7] = 1'b0; // DP 켜기 (Active-Low)
            end else begin
                seg[7] = 1'b1; // DP 끄기
            end
        end
    end
endmodule