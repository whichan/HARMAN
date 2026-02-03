`timescale 1ns / 1ps

module tb_TimeClock ();

    logic       clk;
    logic       reset;
    logic [5:0] msec;
    logic [5:0] sec;
    logic [5:0] min;
    logic [5:0] hour;

    Core dut (.*);

    always #5 clk = ~clk;

    initial begin
        clk   = 0;
        reset = 1;
        #20 reset = 0;
    end

endmodule
