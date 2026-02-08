`timescale 1ns / 1ps

module clk_divider (

    input clk,
    input reset,
    output logic baud_tick

);

  parameter SYSTEM_CLK = 100_000_000;
  parameter BPS = 9600 * 16;  //16배속
  parameter SYSTEM_CLK_TICK_COUNT = SYSTEM_CLK / BPS; //1비트를 16등분한 0~15틱을 세는 카운트 

  logic [$clog2(SYSTEM_CLK_TICK_COUNT)-1:0] r_baud_tick_counter;


  always_ff @(posedge clk or posedge reset) begin
    if (reset) begin
      baud_tick           <= 0;
      r_baud_tick_counter <= 0;
    end else begin

      if (r_baud_tick_counter == SYSTEM_CLK_TICK_COUNT - 1) begin
        r_baud_tick_counter <= 0;
        baud_tick <= 1;
      end else begin
        r_baud_tick_counter <= r_baud_tick_counter + 1;
        baud_tick <= 0;
      end

    end

  end


endmodule
