`timescale 1ns / 1ps

module fndController (
    input  logic        clk,
    input  logic        reset,
    input  logic [ 1:0] mode,         //0:clock, 1:stopwatch, 2:ultrasonic
    input  logic        mode_sw,
    input  logic [ 6:0] msec,
    input  logic [ 5:0] sec,
    input  logic [ 5:0] min,
    input  logic [ 5:0] hour,
    input  logic [11:0] distance_cm,
    output logic [ 3:0] fnd_com,
    output logic [ 7:0] fnd_font
);

  logic [3:0] sec_digit_1, sec_digit_10, min_digit_1, min_digit_10;
  logic [3:0] msec_digit_1, msec_digit_10, hour_digit_1, hour_digit_10;
  logic [3:0] msec_sec_digit, min_hour_digit;
  logic [3:0] time_digit;
  logic tick_1khz, w_dp;
  logic [1:0] digit_sel;


  logic [3:0] dist_digit_1, dist_digit_10, dist_digit_100, dist_digit_1000;
  logic [3:0] ultrasonic_digit;

  assign dist_digit_1 = distance_cm % 10;
  assign dist_digit_10 = (distance_cm / 10) % 10;
  assign dist_digit_100 = (distance_cm / 100) % 10;
  assign dist_digit_1000 = 4'h0;



  clk_div_1khz U_Clk_Div_1Khz (
      .clk      (clk),
      .reset    (reset),
      .tick_1khz(tick_1khz)
  );

  counter_2bit U_Counter_2bit (
      .clk   (clk),
      .reset (reset),
      .i_tick(tick_1khz),
      .count (digit_sel)
  );

  decoder_2x4 U_Digit_Sel (
      .x(digit_sel),
      .y(fnd_com)
  );

  digit_splitter #(
      .WIDTH(7)
  ) U_MSecSplitter (
      .digit   (msec),
      .digit_1 (msec_digit_1),
      .digit_10(msec_digit_10)
  );

  digit_splitter U_SecSplitter (
      .digit   (sec),
      .digit_1 (sec_digit_1),
      .digit_10(sec_digit_10)
  );

  digit_splitter U_MinSplitter (
      .digit   (min),
      .digit_1 (min_digit_1),
      .digit_10(min_digit_10)
  );

  digit_splitter U_HourSplitter (
      .digit   (hour),
      .digit_1 (hour_digit_1),
      .digit_10(hour_digit_10)
  );


  mux_4X1 U_MSecSecMux (
      .sel(digit_sel),
      .x0 (msec_digit_1),
      .x1 (msec_digit_10),
      .x2 (sec_digit_1),
      .x3 (sec_digit_10),
      .y  (msec_sec_digit)
  );


  mux_4X1 U_MinHourMux (
      .sel(digit_sel),
      .x0 (min_digit_1),
      .x1 (min_digit_10),
      .x2 (hour_digit_1),
      .x3 (hour_digit_10),
      .y  (min_hour_digit)
  );

  //초음파 mux
  mux_4X1 U_UltrasonicMux (
      .sel(digit_sel),
      .x0 (dist_digit_1),
      .x1 (dist_digit_10),
      .x2 (dist_digit_100),
      .x3 (dist_digit_1000),
      .y  (ultrasonic_digit)
  );

  always_comb begin
    case (mode)
      2'b10: time_digit = ultrasonic_digit;  //초음파 모드
      default: time_digit = mode_sw ? min_hour_digit : msec_sec_digit;  //시계/스톱워치 모드
    endcase
  end

  //   mux_2X1 U_ModeMux (
  //       .sel(mode_sw),
  //       .x0 (msec_sec_digit),
  //       .x1 (min_hour_digit),
  //       .y  (time_digit)
  //   );



  comp U_CompSec (
      .en(fnd_com[2]),
      .x (msec),
      .y (w_dp)

  );

  BCDtoSEG_decoder U_BCDtoSEG (
      .bcd(time_digit),
      .dp (w_dp),
      .seg(fnd_font)
  );
endmodule

module digit_splitter #(
    parameter WIDTH = 6
) (
    input logic [WIDTH -1:0] digit,
    output logic [3:0] digit_1,
    output logic [3:0] digit_10
);
  assign digit_1  = digit % 10;
  assign digit_10 = digit / 10;
endmodule

module mux_4X1 (
    input  logic [1:0] sel,
    input  logic [3:0] x0,
    input  logic [3:0] x1,
    input  logic [3:0] x2,
    input  logic [3:0] x3,
    output logic [3:0] y
);
  always_comb begin
    y = 4'b0000;
    case (sel)
      2'b00:   y = x0;
      2'b01:   y = x1;
      2'b10:   y = x2;
      2'b11:   y = x3;
      default: y = 4'b0000;
    endcase
  end
endmodule


module mux_2X1 (
    input logic sel,
    input logic [3:0] x0,
    input logic [3:0] x1,
    output logic [3:0] y
);
  always_comb begin
    y = 4'b0000;
    case (sel)
      1'b0: y = x0;
      1'b1: y = x1;
    endcase
  end
endmodule

module clk_div_1khz (
    input  logic clk,
    input  logic reset,
    output logic tick_1khz
);
  logic [$clog2(100_000)-1 : 0] div_counter;

  assign tick_1khz = (div_counter == 100_000 - 1);

  always_ff @(posedge clk, posedge reset) begin
    if (reset) begin
      div_counter <= 0;
    end else begin
      if (div_counter == 100_000 - 1) begin
        div_counter <= 0;
      end else begin
        div_counter <= div_counter + 1;
      end
    end
  end
endmodule

module counter_2bit (
    input logic clk,
    input logic reset,
    input logic i_tick,
    output logic [1:0] count
);
  always_ff @(posedge clk, posedge reset) begin
    if (reset) begin
      count <= 0;
    end else begin
      if (i_tick) begin
        count <= count + 1;
      end
    end
  end
endmodule

module decoder_2x4 (
    input  logic [1:0] x,
    output logic [3:0] y
);
  always_comb begin
    y = 4'b1111;
    case (x)
      2'b00: y = 4'b1110;
      2'b01: y = 4'b1101;
      2'b10: y = 4'b1011;
      2'b11: y = 4'b0111;
    endcase
  end
endmodule

module comp (
    input logic en,
    input logic [6:0] x,
    output logic y

);
  assign y = (x < 50) & ~en;

endmodule

module BCDtoSEG_decoder (
    input  logic [3:0] bcd,
    input  logic       dp,
    output logic [7:0] seg
);
  logic [7:0] seg_digit;


  assign seg = {~dp, seg_digit[6:0]};

  always @(bcd) begin
    seg_digit = 8'hff;
    case (bcd)
      4'h0: seg_digit = 8'hc0;
      4'h1: seg_digit = 8'hf9;
      4'h2: seg_digit = 8'ha4;
      4'h3: seg_digit = 8'hb0;
      4'h4: seg_digit = 8'h99;
      4'h5: seg_digit = 8'h92;
      4'h6: seg_digit = 8'h82;
      4'h7: seg_digit = 8'hf8;
      4'h8: seg_digit = 8'h80;  // 8'b1000_000 
      4'h9: seg_digit = 8'h90;
      4'ha: seg_digit = 8'h88;
      4'hb: seg_digit = 8'h83;
      4'hc: seg_digit = 8'hc6;
      4'hd: seg_digit = 8'ha1;
      4'he: seg_digit = 8'h86;
      4'hf: seg_digit = 8'h8e;
      default: seg_digit = 8'hff;
    endcase
  end
endmodule
