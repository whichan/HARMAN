`timescale 1ns / 1ps

module VGA_top (
    input  logic       clk,
    input  logic       reset,
    input  logic [3:0] sw_red,
    input  logic [3:0] sw_green,
    input  logic [3:0] sw_blue,
    output logic       h_sync,
    output logic       v_sync,
    output logic [3:0] port_red,
    output logic [3:0] port_green,
    output logic [3:0] port_blue
);

  logic [9:0] x_pixel;
  logic [9:0] y_pixel;
  logic DE;


  VGA_Decoder U_VGA_DECODER (
      .clk    (clk),
      .reset  (reset),
      .h_sync (h_sync),
      .v_sync (v_sync),
      .x_pixel(x_pixel),
      .y_pixel(y_pixel),
      .DE     (DE)
  );


  //   VGA_RGB_SW U_VGA_RGB_SW (
  //       .sw_red    (sw_red),
  //       .sw_green  (sw_green),
  //       .sw_blue   (sw_blue),
  //       .DE        (DE),
  //       .port_red  (port_red),
  //       .port_green(port_green),
  //       .port_blue (port_blue)
  //   );

  Color_Bar U_COLOR_BAR (
      .x_pixel   (x_pixel),
      .y_pixel   (y_pixel),
      .DE        (DE),
      .port_red  (port_red),
      .port_green(port_green),
      .port_blue (port_blue)
  );
endmodule
