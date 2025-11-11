module debouncer #(parameter DEBOUNCE_LIMIT = 20'd999_999) (
    input      clk,
    input      reset,
    input      noisy_btn,
    output reg clean_btn,
    output clean_btn_edge  //Edge 출력 추가
);
    reg [19:0] count;
    reg btn_state;
    reg clean_btn_prev;  //이전 상태 저장

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            count <= 20'd0;
            btn_state <= 1'b0;
            clean_btn <= 1'b0;
            clean_btn_prev <= 1'b0;  //
        end else begin
            clean_btn_prev <= clean_btn;  //이전 값 저장
            
            if (noisy_btn == btn_state) begin
                count <= 20'd0;
            end else begin
                if (count < DEBOUNCE_LIMIT)
                    count <= count + 1;
                else begin
                    btn_state <= noisy_btn;
                    clean_btn <= noisy_btn;
                    count <= 20'd0;
                end
            end
        end
    end

    //상승 엣지 검출
    assign clean_btn_edge = clean_btn & ~clean_btn_prev;

endmodule