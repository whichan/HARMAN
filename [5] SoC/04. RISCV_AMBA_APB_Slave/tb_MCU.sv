`timescale 1ns / 1ps

module tb_MCU ();

  logic clk;
  logic reset;

  MCU dut (.*);

  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end

  initial begin
    reset = 1;
    #10;
    reset = 0;
    #2000;
    $stop;
  end

endmodule
