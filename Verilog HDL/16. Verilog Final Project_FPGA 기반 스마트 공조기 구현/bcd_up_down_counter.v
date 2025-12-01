`timescale 1ns / 1ps

module bcd_up_down_counter_ds1302(
    input clk,
    input reset,
    // [추가됨] 현재 값을 불러오기 위한 포트
    input i_load,          // 1이면 i_load_val 값을 강제로 입력 (Sync)
    input [7:0] i_load_val,// 현재 RTC 시간값
    
    input i_inc,          // 증가 펄스
    input i_dec,          // 감소 펄스
    input [7:0] i_max_val,// 최댓값 (예: 59)
    output reg [7:0] o_bcd // 결과값
    );

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            o_bcd <= 8'h00;
        end else begin
            // 1. Load가 1이면 무조건 현재 값으로 동기화 (우선순위 높음)
            // 단, Inc/Dec 신호가 들어오는 순간에는 Load를 무시해야 연산이 가능함
            // Top 모듈에서 타이밍을 조절해서 넣어줄 예정
            if (i_load) begin
                o_bcd <= i_load_val;
            end
            // 2. 증가 연산
            else if (i_inc) begin
                if (o_bcd == i_max_val) begin
                    o_bcd <= 8'h00; 
                end else if (o_bcd[3:0] == 4'd9) begin
                    o_bcd[3:0] <= 4'd0;
                    o_bcd[7:4] <= o_bcd[7:4] + 1;
                end else begin
                    o_bcd[3:0] <= o_bcd[3:0] + 1;
                end
            end 
            // 3. 감소 연산
            else if (i_dec) begin
                if (o_bcd == 8'h00) begin
                    o_bcd <= i_max_val; 
                end else if (o_bcd[3:0] == 4'd0) begin
                    o_bcd[3:0] <= 4'd9;
                    o_bcd[7:4] <= o_bcd[7:4] - 1;
                end else begin
                    o_bcd[3:0] <= o_bcd[3:0] - 1;
                end
            end
        end
    end
endmodule