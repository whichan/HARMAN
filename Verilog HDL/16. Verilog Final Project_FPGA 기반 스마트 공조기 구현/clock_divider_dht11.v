`timescale 1ns / 1ps

module clock_divider_dht11(
    input clk,
    input reset,
    output tick_1s,      // 1초 틱 (1 클럭 펄스)
    output tick_1khz     // 1kHz 틱 (1 클럭 펄스)
);
    //===== 파라미터 설정 =====//
    parameter CNT_1S = 100_000_000;
    parameter CNT_1KHZ = 100_000;

    //===== 카운트 레지스터 선언 (비트 폭 직접 지정) =====//
    // 1억은 27비트 필요 (2^27 = 134,217,728)
    reg [26:0] cnt_1s; 
    
    // 10만은 17비트 필요 (2^17 = 131,072)
    reg [16:0] cnt_1khz;
    
    //===== 틱 레지스터 (1 클럭 펄스 생성용) =====//
    reg r_tick_1s;
    reg r_tick_1khz;

    //===== 1초 카운터 및 틱 생성 =====//
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            cnt_1s <= 0;
            r_tick_1s <= 0;
        end else begin
            if (cnt_1s == CNT_1S - 1) begin
                cnt_1s <= 0;
                r_tick_1s <= 1;  // 1 클럭 동안 High
            end else begin
                cnt_1s <= cnt_1s + 1;
                r_tick_1s <= 0;
            end
        end
    end

    //===== 1kHz 카운터 및 틱 생성 =====//
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            cnt_1khz <= 0;
            r_tick_1khz <= 0;
        end else begin
            if (cnt_1khz == CNT_1KHZ - 1) begin
                cnt_1khz <= 0;
                r_tick_1khz <= 1;  // 1 클럭 동안 High
            end else begin
                cnt_1khz <= cnt_1khz + 1;
                r_tick_1khz <= 0;
            end
        end
    end

    //===== 출력 할당 =====//
    assign tick_1s = r_tick_1s;
    assign tick_1khz = r_tick_1khz;

endmodule