`timescale 1ns / 1ps

module tb_rv32i_top();

    logic clk;
    logic reset;

    rv32i_top u_rv32i_top(
        .clk(clk),
        .reset(reset)
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