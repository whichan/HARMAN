`timescale 1ns / 1ps

module tb_btn_debounce ();

  logic clk, reset, i_btn, o_btn;

  btn_debounce u_btn_debounce (
      .clk  (clk),
      .reset(reset),
      .i_btn(i_btn),
      .o_btn(o_btn)
  );

  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end

  initial begin
    clk   = 0;
    reset = 1;
    i_btn = 0;

    #10 reset = 0;

    #1000 i_btn = 1;
    #1000 i_btn = 0;
    #5000 i_btn = 1;
    #6000 i_btn = 0;
    #9000 i_btn = 1;
    #7000 i_btn = 0;
    #1300 i_btn = 1;
    #500000 i_btn = 0;
    #1000000 $finish;
  end

endmodule
