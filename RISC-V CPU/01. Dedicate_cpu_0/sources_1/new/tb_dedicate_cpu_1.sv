`timescale 1ns / 1ps

module tb_dedicate_cpu_1();

    logic clk;
    logic reset;
    logic [7:0] out;

    dedicate_cpu_1 u_dedicate_cpu_1(
        .clk(clk),
        .reset(reset),
        .out(out)
    );

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    initial begin
        #0;
        reset = 1;

        #10;
        reset = 0;

        #500;
    end
endmodule
