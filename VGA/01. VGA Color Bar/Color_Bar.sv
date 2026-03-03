`timescale 1ns / 1ps

module Color_Bar (
    input  logic [9:0] x_pixel,
    input  logic [9:0] y_pixel,
    input  logic       DE,
    output logic [3:0] port_red,
    output logic [3:0] port_green,
    output logic [3:0] port_blue
);

  always_comb begin
    // 기본값 설정 (Latch 방지 및 DE가 0일 때)
    port_red   = 4'h0;
    port_green = 4'h0;
    port_blue  = 4'h0;

    if (DE) begin
      // 상단 영역 (y: 0~299)
      if (y_pixel < 300) begin
        if (x_pixel < 90) begin
          port_red   = 4'hc;
          port_green = 4'hc;
          port_blue  = 4'hc;
        end // 회색
        else if (x_pixel < 180) begin
          port_red   = 4'hc;
          port_green = 4'hc;
          port_blue  = 4'h0;
        end // 노란색
        else if (x_pixel < 270) begin
          port_red   = 4'h0;
          port_green = 4'hc;
          port_blue  = 4'hc;
        end // 하늘색
        else if (x_pixel < 360) begin
          port_red   = 4'h0;
          port_green = 4'hc;
          port_blue  = 4'h0;
        end // 초록색
        else if (x_pixel < 450) begin
          port_red   = 4'hc;
          port_green = 4'h0;
          port_blue  = 4'hc;
        end // 핑크색
        else if (x_pixel < 540) begin
          port_red   = 4'hc;
          port_green = 4'h0;
          port_blue  = 4'h0;
        end // 빨간색
        else                    begin
          port_red   = 4'h0;
          port_green = 4'h0;
          port_blue  = 4'hc;
        end  // 파란색
      end  // 중간 영역 (y: 300~329)
      else if (y_pixel < 330) begin
        if (x_pixel < 90) begin
          port_red   = 4'h0;
          port_green = 4'h0;
          port_blue  = 4'h8;
        end // 남색
        else if (x_pixel < 180) begin
          port_red   = 4'h5;
          port_green = 4'h2;
          port_blue  = 4'h1;
        end // 갈색
        else if (x_pixel < 270) begin
          port_red   = 4'hF;
          port_green = 4'h8;
          port_blue  = 4'hA;
        end // 핑크색
        else if (x_pixel < 360) begin
          port_red   = 4'h0;
          port_green = 4'h0;
          port_blue  = 4'h0;
        end // 검정색
        else if (x_pixel < 450) begin
          port_red   = 4'h0;
          port_green = 4'hc;
          port_blue  = 4'hc;
        end // 하늘색
        else if (x_pixel < 540) begin
          port_red   = 4'h1;
          port_green = 4'h1;
          port_blue  = 4'h1;
        end // 어두운 회색
        else                    begin
          port_red   = 4'hc;
          port_green = 4'hc;
          port_blue  = 4'hc;
        end  // 회색
      end  // 하단 영역 (y: 330~479)
      else begin
        if (x_pixel < 100) begin
          port_red   = 4'h4;
          port_green = 4'h5;
          port_blue  = 4'h2;
        end // 국방색
        else if (x_pixel < 200) begin
          port_red   = 4'hF;
          port_green = 4'hF;
          port_blue  = 4'hF;
        end // 흰색
        else if (x_pixel < 300) begin
          port_red   = 4'h8;
          port_green = 4'h0;
          port_blue  = 4'h8;
        end // 보라색
        else if (x_pixel < 400) begin
          port_red   = 4'h1;
          port_green = 4'h1;
          port_blue  = 4'h1;
        end // 어두운 회색
        else if (x_pixel < 433) begin
          port_red   = 4'h0;
          port_green = 4'h0;
          port_blue  = 4'h0;
        end // 검정 1
        else if (x_pixel < 466) begin
          port_red   = 4'h1;
          port_green = 4'h1;
          port_blue  = 4'h1;
        end // 검정 2
        else if (x_pixel < 499) begin
          port_red   = 4'h2;
          port_green = 4'h2;
          port_blue  = 4'h2;
        end // 검정 3
        else                    begin
          port_red   = 4'h0;
          port_green = 4'h0;
          port_blue  = 4'h0;
        end  // 검정 4
      end
    end
  end

endmodule
