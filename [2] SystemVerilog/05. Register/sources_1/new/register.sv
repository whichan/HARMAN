`timescale 1ns / 1ps

module register(
    input logic clk,
    input logic reset,
    input logic [31:0] in,
    output logic [31:0] out
    );

    logic [31:0] register_32;
    //reg [31:0] register_32;

    always @(posedge clk)  begin
        if(reset) begin
            out <= 32'h0000_0000; //reset이면 출력을 항상 0으로
        end else begin

            out <= in;
        end
    end

endmodule