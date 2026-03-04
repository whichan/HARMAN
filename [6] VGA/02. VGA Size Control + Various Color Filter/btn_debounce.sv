`timescale 1ns / 1ps

module btn_debounce (
    input  clk,
    input  reset,
    input  i_btn,
    output o_btn
);

  //clk_divider
  //100MHz -> 100kHz
  parameter FCOUNT = 100_000_000 / 100_000;
  logic [$clog2(FCOUNT)-1:0] counter_100khz;
  logic r_clock_100khz;

  always_ff @(posedge clk or posedge reset) begin
    if (reset) begin
      counter_100khz <= 0;
      r_clock_100khz <= 1'b0;
    end else begin
      if (counter_100khz == FCOUNT - 1) begin
        counter_100khz <= 0;
        r_clock_100khz <= 1'b1;
      end else begin
        counter_100khz <= counter_100khz + 1;
        r_clock_100khz <= 1'b0;
      end
    end
  end




  // debounce 8FF - 8input And Gate
  logic [7:0] shift_reg;  //verilog에서는 reg
                          //systemverilog에서는 reg을 logic이라 함

  logic debounce;

  //8 SIPO(serial input parallel output) shift register
  always_ff @(posedge r_clock_100khz or posedge reset) begin
    if (reset) begin
      shift_reg <= 8'h00;
    end else begin
      shift_reg <= {i_btn, shift_reg[7:1]};
    end
  end

  // 8input AND Gate
  assign debounce = &(shift_reg);


  logic edge_detect;

  // Rising Edge Detector
  always_ff @(posedge clk or posedge reset) begin
    if (reset) begin
      edge_detect <= 1'b0;
    end else begin
      edge_detect <= debounce;
    end
  end

  assign o_btn = debounce & (~edge_detect);



  //reset은 민감하기 때문에 
endmodule
