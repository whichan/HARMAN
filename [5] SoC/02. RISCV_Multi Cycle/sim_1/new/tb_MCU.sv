`timescale 1ns / 1ps

module tb_rsicv ();

  logic clk;
  logic reset;

  MCU dut (.*);
  always #5 clk = ~clk;

  //   initial begin
  //     $fsdbDumpfile("build/wave_mcu.fsdb");
  //     $fsdbDumpvars(0);
  //   end

  initial begin
    clk   = 0;
    reset = 1;
    #10;
    reset = 0;
    #5000;
    $stop;
  end
endmodule
