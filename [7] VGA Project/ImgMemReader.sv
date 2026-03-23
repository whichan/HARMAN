
`timescale 1ns / 1ps

// ImgMemReader: 4분할 화면을 위해 각 셀의 카메라 좌표로 addr 계산
// 모든 셀이 동일한 FrameBuffer(320x240)를 읽음

module ImgMemReader #(
    parameter IMG_SIZE = 320 * 240,
    parameter IMG_W    = 320,
    parameter IMG_H    = 240
) (
    input  logic                        DE,
    input  logic [                 9:0] x_pixel,     // 0~639
    input  logic [                 9:0] y_pixel,     // 0~479
    input  logic [                15:0] imgData,
    output logic [$clog2(IMG_SIZE)-1:0] addr,
    output logic [                 3:0] port_red,
    output logic [                 3:0] port_green,
    output logic [                 3:0] port_blue
);

  logic [9:0] cam_x, cam_y;
  always_comb begin
    if (x_pixel < 320) cam_x = x_pixel;
    else cam_x = x_pixel - 10'd320;

    if (y_pixel < 240) cam_y = y_pixel;
    else cam_y = y_pixel - 10'd240;
  end

  logic in_de;
  assign in_de = DE && (x_pixel < 640) && (y_pixel < 480);

  assign addr = in_de ? (IMG_W * cam_y + cam_x) : '0;

  assign port_red = in_de ? imgData[15:12] : 4'h0;
  assign port_green = in_de ? imgData[10:7] : 4'h0;
  assign port_blue = in_de ? imgData[4:1] : 4'h0;

endmodule
