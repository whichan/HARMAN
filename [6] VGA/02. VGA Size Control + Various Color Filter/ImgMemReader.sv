`timescale 1ns / 1ps

module ImgMemReader (
    input  logic                       DE,
    input  logic [                9:0] x_pixel,
    input  logic [                9:0] y_pixel,
    output logic [$clog2(320*240)-1:0] addr,
    input  logic [               15:0] imgData,
    output logic [                3:0] port_red,
    output logic [                3:0] port_green,
    output logic [                3:0] port_blue
);

  logic qvga_de;  //1/4
  assign qvga_de = (x_pixel < 320) && (y_pixel < 240);
  assign addr    = (DE&&qvga_de) ? (320 * y_pixel + x_pixel) : 0; //2차원 이미지를 1차원 주소로 변환
  assign {port_red, port_green, port_blue} = (DE&&qvga_de) ? {imgData[15:12], imgData[10:7], imgData[4:1]} : 0; //DE=0이면 검정색 출력

  //addr가 0부터 다시 시작되는 문제 발생.

endmodule


module ImgMemReader_upscaler (
    input  logic                       DE,
    input  logic [                9:0] x_pixel,
    input  logic [                9:0] y_pixel,
    output logic [$clog2(320*240)-1:0] addr,
    input  logic [               15:0] imgData,
    output logic [                3:0] port_red,
    output logic [                3:0] port_green,
    output logic [                3:0] port_blue
);

  // logic qvga_de;  //1/4
  //   assign qvga_de = (x_pixel < 320) && (y_pixel < 240);
  assign addr = (DE) ? (320 * y_pixel[9:1] + x_pixel[9:1]) : 0; //2차원 이미지를 1차원 주소로 변환

  assign {port_red, port_green, port_blue} = (DE) ? {imgData[15:12], imgData[10:7], imgData[4:1]} : 0; //DE=0이면 검정색 

endmodule
