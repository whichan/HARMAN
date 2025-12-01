`timescale 1ns / 1ps

module rotary_ds1302(
    input clk,
    input reset,
    input clean_s1,
    input clean_s2,
    input clean_key,

    output reg o_valid_cw, //시계 방향 회전시 1클럭 펄스 출력
    output reg o_valid_ccw, //반시계 방향 회전시 1클럭 펄스 출력
    output reg o_sw_toggle
);

reg [1:0] r_prev_state = 2'b00;
reg [1:0] r_state = 2'b00;

// ===== 로터리 회전 감지 ===== //
always @(posedge clk or posedge reset) begin
   if(reset) begin
        r_state <= 0;
        r_prev_state <= 0;
        o_valid_ccw <= 0;
        o_valid_cw <= 0;
    end else begin
        r_prev_state <= r_state;
        r_state <= {clean_s1, clean_s2};

        o_valid_ccw <= 0;
        o_valid_cw <= 0;
        
        case({r_prev_state, r_state})
            4'b0010, 4'b1011, 4'b1101, 4'b0100: begin
                o_valid_cw <= 1'b1; //한칸 돌았음 펄스
            end

            4'b0001, 4'b0111, 4'b1110, 4'b1000: begin
                o_valid_ccw <= 1'b1; //반대쪽으로 돌았음 펄스
            end
        endcase
    end
end


// 버튼 토글 (Edge Detection)
    reg r_prev_key;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            o_sw_toggle <= 1'b0;
            r_prev_key <= 1'b0;
        end else begin
            r_prev_key <= clean_key;
            // Rising Edge Detection: 0 -> 1 로 변하는 순간
            if (!r_prev_key && clean_key) begin
                o_sw_toggle <= ~o_sw_toggle; // 모드 변경 (예: View <-> Edit)
            end
        end
    end

endmodule