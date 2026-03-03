`timescale 1ns / 1ps

module bin_to_bcd(
    input [13:0] bin,   // 0~9999 (14bit)
    output reg [15:0] bcd // 4자리 BCD (각 4비트씩) -> 천,백,십,일
    );
    
    integer i;
    reg [13:0] temp_bin; // 복사본
    
    always @(*) begin
        bcd = 0;
        temp_bin = bin; // 입력값 복사
        
        for (i = 0; i < 14; i = i + 1) begin
            // 각 자리가 5 이상이면 3을 더함
            if (bcd[3:0] >= 5)   bcd[3:0] = bcd[3:0] + 3;
            if (bcd[7:4] >= 5)   bcd[7:4] = bcd[7:4] + 3;
            if (bcd[11:8] >= 5)  bcd[11:8] = bcd[11:8] + 3;
            if (bcd[15:12] >= 5) bcd[15:12] = bcd[15:12] + 3;
            
            // 왼쪽으로 1비트 Shift
            bcd = {bcd[14:0], temp_bin[13]};
            temp_bin = temp_bin << 1;
        end
    end
endmodule