`timescale 1ns / 1ps

module tb_MCU ();

  logic       clk;
  logic       reset;
  logic [3:0] gpoa;
  logic [3:0] gpob;
  logic [3:0] gpic;
  logic [3:0] gpiod;

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
