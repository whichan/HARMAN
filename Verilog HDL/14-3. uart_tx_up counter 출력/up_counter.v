`timescale 1ns / 1ps

module up_counter(
    input clk,
    input reset,
    input trigger_1hz,
    output reg [15:0] count
    );

    always @(posedge clk or posedge reset) begin
        if(reset) begin
            count <= 0;
        end else if (trigger_1hz) begin
            count <= count + 1;
        end
    end
endmodule
