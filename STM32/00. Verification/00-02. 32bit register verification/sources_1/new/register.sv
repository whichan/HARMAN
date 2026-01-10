`timescale 1ns / 1ps

module register(
    input clk,
    input reset,
    input [31:0] d,
    output reg [31:0] q
    );

    logic [31:0] register_file [0:7];

    //상승엣지가 발생할 때마다 데이터를 저장하고 출력을 내보냄
    always_ff @(posedge clk) begin
        if(reset) begin
            q <= 32'b0;
        end else begin
            q <= d;
        end
    end

endmodule
