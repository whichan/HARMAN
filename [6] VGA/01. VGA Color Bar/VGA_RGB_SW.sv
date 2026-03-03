`timescale 1ns / 1ps

module VGA_RGB_SW (
    input  logic [3:0] sw_red,
    input  logic [3:0] sw_green,
    input  logic [3:0] sw_blue,
    input  logic       DE,
    input  logic [9:0] x_pixel,
    input  logic [9:0] y_pixel,
    output logic [3:0] port_red,
    output logic [3:0] port_green,
    output logic [3:0] port_blue

);
  assign port_red   = DE ? sw_red : 4'b0;
  assign port_green = DE ? sw_green : 4'b0;
  assign port_blue  = DE ? sw_blue : 4'b0;

endmodule
