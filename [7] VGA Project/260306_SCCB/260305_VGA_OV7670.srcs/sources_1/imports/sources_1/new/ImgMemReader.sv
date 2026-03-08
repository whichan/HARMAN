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
  assign addr    = (DE&&qvga_de) ? (320 * y_pixel[9:1] + x_pixel[9:1]) : 0; //2차원 이미지를 1차원 주소로 변환
  assign {port_red, port_green, port_blue} = (DE&&qvga_de) ? {imgData[15:12], imgData[10:7], imgData[4:1]} : 0; //DE=0이면 검정색 출력

  //addr가 0부터 다시 시작되는 문제 발생.

endmodule


// module ImgMemReader_upscaler (
//     input  logic                       DE,
//     input  logic [                9:0] x_pixel,
//     input  logic [                9:0] y_pixel,
//     output logic [$clog2(320*240)-1:0] addr,
//     input  logic [               15:0] imgData,
//     output logic [                3:0] port_red,
//     output logic [                3:0] port_green,
//     output logic [                3:0] port_blue
// );

//   // logic qvga_de;  //1/4
//   //   assign qvga_de = (x_pixel < 320) && (y_pixel < 240);
//   assign addr = (DE) ? (320 * y_pixel[9:1] + x_pixel[9:1]) : 0; //2차원 이미지를 1차원 주소로 변환

//   assign {port_red, port_green, port_blue} = (DE) ? {imgData[15:12], imgData[10:7], imgData[4:1]} : 0; //DE=0이면 검정색 

// endmodule

`timescale 1ns / 1ps

module ImgMemReader_upscaler (
    input  logic                       clk,         // VGA 픽셀 클럭 (25MHz)
    input  logic                       DE,
    input  logic [                9:0] x_pixel,
    input  logic [                9:0] y_pixel,
    output logic [$clog2(320*240)-1:0] addr,
    input  logic [               15:0] imgData,     // RGB565 from BRAM
    output logic [                3:0] port_red,
    output logic [                3:0] port_green,
    output logic [                3:0] port_blue
);


  wire [8:0] qvga_x = x_pixel[9:1];  // 0~319
  wire [8:0] qvga_y = y_pixel[9:1];  // 0~239

  // 홀수 x일 때 다음 픽셀 주소, 짝수일 때 현재 픽셀 주소
  wire [8:0] read_x = x_pixel[0] ? (qvga_x + 1) : qvga_x;

  // 오른쪽 끝 경계 처리 (319 넘어가면 319로 클램프)
  wire [8:0] clamped_x = (read_x > 319) ? 319 : read_x;

  assign addr = (DE) ? (320 * qvga_y + clamped_x) : 0;

  // 현재 BRAM 데이터에서 RGB 추출 (RGB565 → 각 4비트)
  wire [3:0] cur_r = imgData[15:12];
  wire [3:0] cur_g = imgData[10:7];
  wire [3:0] cur_b = imgData[4:1];

  // 이전 픽셀 저장 레지스터
  reg [3:0] prev_r, prev_g, prev_b;

  // 짝수 x에서 읽은 값 = 원본 픽셀 → 저장
  always_ff @(posedge clk) begin
    if (!DE) begin
      prev_r <= 4'd0;
      prev_g <= 4'd0;
      prev_b <= 4'd0;
    end else if (!x_pixel[0]) begin
      // 짝수 x: 현재 BRAM 데이터가 원본 픽셀
      prev_r <= cur_r;
      prev_g <= cur_g;
      prev_b <= cur_b;
    end
  end

  // 평균 계산 (보간)
  // (a + b) >> 1 = 평균 (4비트 + 4비트 → 5비트 → 시프트)
  wire [4:0] avg_r = ({1'b0, prev_r} + {1'b0, cur_r});  // 5비트 합
  wire [4:0] avg_g = ({1'b0, prev_g} + {1'b0, cur_g});
  wire [4:0] avg_b = ({1'b0, prev_b} + {1'b0, cur_b});

  // 출력 MUX
  // 짝수 x → 원본 픽셀 그대로
  // 홀수 x → 이전 픽셀과 현재(다음) 픽셀의 평균
  always_comb begin
    if (!DE) begin
      port_red   = 4'd0;
      port_green = 4'd0;
      port_blue  = 4'd0;
    end else if (!x_pixel[0]) begin
      // 짝수 x: 원본 픽셀
      port_red   = cur_r;
      port_green = cur_g;
      port_blue  = cur_b;
    end else begin
      // 홀수 x: 좌우 평균 (보간)
      port_red   = avg_r[4:1];  // 5비트 합을 1비트 우시프트 = 평균
      port_green = avg_g[4:1];
      port_blue  = avg_b[4:1];
    end
  end

endmodule
