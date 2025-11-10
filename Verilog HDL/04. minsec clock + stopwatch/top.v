`timescale 1ns / 1ps

module top(
    input clk,
    input reset,
    input [2:0] btn,
    output [7:0] seg,
    output [15:0] led,
    output [3:0] an
    );

    parameter S_MINSEC = 1'b0;
    parameter S_STOPWATCH = 1'b1;

    reg r_main_state = S_MINSEC;

    wire [7:0] w_minsec_seg;
    wire [3:0] w_minsec_an;
    wire [15:0] w_minsec_led;
    wire w_switch_to_stopwatch;

    wire [7:0] w_stopwatch_seg;
    wire [3:0] w_stopwatch_an;
    wire [15:0] w_stopwatch_led;
    wire w_switch_to_minsec;


    top_minsec u_top_minsec(
        .clk(clk),
        .reset(reset),  // 리셋은 항상 전달
        .btn(btn),
        .seg(w_minsec_seg),
        .an(w_minsec_an),
        .led(w_minsec_led),
        .switch_to_stopwatch(w_switch_to_stopwatch)
    );

    top_stopwatch u_top_stopwatch(
        .reset(reset),  // 리셋은 항상 전달
        .clk(clk),
        .btn(btn),
        .seg(w_stopwatch_seg),
        .led(w_stopwatch_led),
        .an(w_stopwatch_an),
        .switch_to_minsec(w_switch_to_minsec)
    );


    //----------FSM----------//
    // 모드 전환만 담당 (리셋은 각 하위 모듈에서 처리)
    always @(posedge clk or posedge reset) begin  //'or' 사용
        if(reset) begin
            // 현재 모드 유지 (또는 초기 모드로)
            // 옵션 1: 현재 모드 유지
            r_main_state <= r_main_state;
            
            // 옵션 2: 항상 분초시계로 (권장)
            // r_main_state <= S_MINSEC;
        end else begin
            case (r_main_state)
                S_MINSEC: begin
                    if(w_switch_to_stopwatch) begin
                        r_main_state <= S_STOPWATCH;
                    end
                end

                S_STOPWATCH: begin
                    if(w_switch_to_minsec) begin
                        r_main_state <= S_MINSEC;
                    end
                end
            endcase
        end
    end
    

    //----------출력 MUX----------//
    //FSM 상태에 따라 최종 핀으로 나갈 출력 선택
    assign seg = (r_main_state == S_MINSEC) ? w_minsec_seg: w_stopwatch_seg;
    //r_main_state가 S_MINSEC이면 w_minsec_seg 출력
    assign an = (r_main_state == S_MINSEC) ? w_minsec_an : w_stopwatch_an;
    assign led = (r_main_state == S_MINSEC) ? w_minsec_led : w_stopwatch_led;
endmodule