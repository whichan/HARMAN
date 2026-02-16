module clock_divider#(
    parameter MAX_COUNT = 10_000_000
)(
    input clk,
    input reset,
    output reg r_tick_10khz
    //output reg r_tick_20ns
);

reg [$clog2(MAX_COUNT)-1:0] r_tick_cnt = 0;


//100_000_000 / 10_000 = 10_000

//10khz짜리 tick 생성
always @(posedge clk or posedge reset) begin
    if(reset) begin
        r_tick_cnt <= 0;
        r_tick_10khz <= 0;
    end else begin
        if(r_tick_cnt == MAX_COUNT -1) begin
            r_tick_10khz <= 1;
            r_tick_cnt <= 0;
        end else begin
            r_tick_cnt <= r_tick_cnt + 1;
            r_tick_10khz <= 0;
        end
    end
end

/*always @(posedge clk or posedge reset) begin
    if(reset) begin
        r_tick_cnt <= 0;
        r_tick_10khz <= 0;
    end else begin
        if(r_tick_cnt == TICK_CNT-1) begin
            r_tick_cnt <= 0;
            r_tick_10khz <= 1;
        end else if(r_tick_cnt==0) begin
            r_tick_cnt <= r_tick_cnt + 1;
            r_tick_10khz <= 1;
        end else begin
            r_tick_cnt <= r_tick_cnt + 1;
            r_tick_10khz <= 0;
        end
    end
end*/

endmodule