`timescale 1ns / 1ps

module VGA_ImgROM (
    input  logic       clk,
    input  logic       reset,
    input  logic       sw_scale,     //sw15
    input  logic       sw_gray,      //sw14
    input  logic       sw_red,       //sw13
    input  logic       sw_green,     //sw12
    input  logic       sw_blue,      //sw11
    input  logic       sw_negative,  //sw10
    output logic       h_sync,
    output logic       v_sync,
    output logic [3:0] port_red,
    output logic [3:0] port_green,
    output logic [3:0] port_blue
);

  logic [                9:0] x_pixel;
  logic [                9:0] y_pixel;
  logic                       DE;
  logic [$clog2(320*240)-1:0] addr;
  logic [$clog2(320*240)-1:0] addr_origin;
  logic [$clog2(320*240)-1:0] addr_upscale;

  logic [               15:0] data;
  logic [               15:0] data_origin;
  logic [               15:0] data_upscale;
  logic [                3:0] port_red_origin;
  logic [                3:0] port_green_origin;
  logic [                3:0] port_blue_origin;
  logic [                3:0] port_red_upscale;
  logic [                3:0] port_green_upscale;
  logic [                3:0] port_blue_upscale;
  logic [               11:0] rgb;
  logic [               11:0] rgb_gray;
  logic [               11:0] rgb_red;
  logic [               11:0] rgb_green;
  logic [               11:0] rgb_blue;
  logic [               11:0] rgb_negative;



  mux #(
      .WIDTH(12)
  ) U_MUX_RGB_PORT (
      .sel(sw_scale),
      .x1 ({port_red_origin, port_green_origin, port_blue_origin}),
      .x2 ({port_red_upscale, port_green_upscale, port_blue_upscale}),
      .y  (rgb)
  );

  mux_color #(
      .WIDTH(12)
  ) U_MUX_RGB_FILTER_PORT (
      .sel({sw_red, sw_green, sw_blue}),
      .x0 (rgb),
      .x1 (rgb_gray),
      .x2 (rgb_red),
      .x3 (rgb_green),
      .x4 (rgb_blue),
      .x5 (rgb_negative),
      .y  ({port_red, port_green, port_blue})
  );

  gray_scale_filter U_GRAY_FILTER (
      .i_rgb(rgb),
      .o_rgb(rgb_gray)
  );

  //   mux #(
  //       .WIDTH(12)
  //   ) U_MUX_RGB_GRAY (
  //       .sel(sw_gray),
  //       .x1 (rgb),
  //       .x2 (rgb_gray),
  //       .y  ({port_red, port_green, port_blue})
  //   );

  VGA_Decoder_Top U_VGA_DECODER (.*);

  ImgMemReader U_ImgReader_Origin (
      .DE        (DE),
      .x_pixel   (x_pixel),
      .y_pixel   (y_pixel),
      .addr      (addr_origin),
      .imgData   (data_origin),
      .port_red  (port_red_origin),
      .port_green(port_green_origin),
      .port_blue (port_blue_origin)
  );

  ImgMemReader_upscaler U_ImgMemReader_UpScaler (
      .DE        (DE),
      .x_pixel   (x_pixel),
      .y_pixel   (y_pixel),
      .addr      (addr_upscale),
      .imgData   (data_upscale),
      .port_red  (port_red_upscale),
      .port_green(port_green_upscale),
      .port_blue (port_blue_upscale)
  );

  imgROM U_ImgROM (
      .addr(addr),
      .data(data)
  );

  mux #(
      .WIDTH($clog2(320 * 240))
  ) U_AddrMux (
      .sel(sw_scale),
      .x1 (addr_origin),
      .x2 (addr_upscale),
      .y  (addr)
  );

  demux #(
      .WIDTH(16)
  ) U_DataDemux (
      .sel(sw_scale),
      .y  (data),
      .x0 (data_origin),
      .x1 (data_upscale)
  );

  red_filter U_RED_FILTER (
      .i_rgb(rgb),
      .o_rgb(rgb_red)
  );

  green_filter U_GREEN_FILTER (
      .i_rgb(rgb),
      .o_rgb(rgb_green)
  );

  blue_filter U_BLUE_FILTER (
      .i_rgb(rgb),
      .o_rgb(rgb_blue)
  );
  negative_filter U_NEGATIVE_FILTER (
      .i_rgb(rgb),
      .o_rgb(rgb_negative)
  );

endmodule

module mux #(
    parameter WIDTH = 16
) (
    input  logic             sel,
    input  logic [WIDTH-1:0] x1,
    input  logic [WIDTH-1:0] x2,
    output logic [WIDTH-1:0] y
);

  assign y = sel ? x2 : x1;

endmodule

module demux #(
    parameter WIDTH = 12
) (
    input  logic             sel,
    input  logic [WIDTH-1:0] y,
    output logic [WIDTH-1:0] x0,
    output logic [WIDTH-1:0] x1
);

  always_comb begin
    x0 = 0;
    x1 = 0;
    case (sel)
      1'b0: x0 = y;
      1'b1: x1 = y;
      default: begin
        x0 = 0;
        x1 = 0;
      end
    endcase
  end
endmodule

module mux_color #(
    parameter WIDTH = 16
) (
    input  logic [      2:0] sel,
    input  logic [WIDTH-1:0] x0,
    input  logic [WIDTH-1:0] x1,
    input  logic [WIDTH-1:0] x2,
    input  logic [WIDTH-1:0] x3,
    input  logic [WIDTH-1:0] x4,
    input  logic [WIDTH-1:0] x5,
    output logic [WIDTH-1:0] y
);

  always_comb begin
    y = x0;
    case (sel)
      3'b000: begin
        y = x0;
      end
      3'b001: begin
        y = x1;
      end
      3'b010: begin
        y = x2;
      end
      3'b011: begin
        y = x3;
      end
      3'b100: begin
        y = x4;
      end
      3'b101: begin
        y = x5;
      end
    endcase

  end

endmodule

