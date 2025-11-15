`timescale 1ns / 1ps

module tick_generator #(
    parameter INPUT_FREQ = 100_000_000, //100MHz
    parameter TICK_Hz = 1000 //1khz
) (
    input clk,
    input reset,
    output reg tick
);

parameter TICK_CNT = INPUT_FREQ / TICK_Hz; //100_000
reg [$clog2(TICK_CNT)-1:0] r_tick_cnt = 0;

always @(posedge clk or posedge reset) begin
    if(reset) begin
        r_tick_cnt <= 0;
        tick <= 0;
    end else begin
        if(r_tick_cnt == TICK_CNT -1) begin
            r_tick_cnt <= 0;
            tick <= 1;
        end else begin
            r_tick_cnt <= r_tick_cnt + 1;
            tick <= 0;
        end
    end
end

endmodule