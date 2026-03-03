`timescale 1ns / 1ps

module spi_slave (
    //global signals
    input  logic       clk,
    input  logic       reset,
    //spi interface signals
    input  logic       sclk,
    input  logic       mosi,
    output logic       miso,
    input  logic       cs,
    //external interface signals
    input  logic [7:0] tx_data,  //peripheral -> slave -> master
    output logic [7:0] rx_data,  //master -> slave -> peripheral
    output logic       rx_done,
    input  logic       cpol,
    input  logic       cpha
);

  logic sclk_d1, sclk_d2, sclk_d3;
  logic sclk_rising, sclk_falling;
  logic sample_edge, shift_edge;

  always_ff @(posedge clk) begin
    if (reset) begin
      sclk_d1 <= 0;
      sclk_d2 <= 0;
      sclk_d3 <= 0;
    end else begin
      sclk_d1 <= sclk;
      sclk_d2 <= sclk_d1;
      sclk_d3 <= sclk_d2;
    end
  end

  assign sclk_rising = (sclk_d2 == 1'b1) && (sclk_d3 == 1'b0);  //0에서 1이 된 순간
  assign sclk_falling = (sclk_d2 == 1'b0) && (sclk_d3 == 1'b1);  //1에서 0이 된 순간

  //mode에 따른 sampling/shift edge 결정

  //cpha=0: 첫번째 엣지에서 샘플링, cpha=1: 두번째 엣지에서 샘플링
  assign sample_edge = cpha ? (cpol ? sclk_rising:sclk_falling)
                        : (cpol? sclk_falling: sclk_rising);
  assign shift_edge  = cpha ? (cpol ? sclk_falling : sclk_rising) 
                            : (cpol ? sclk_rising  : sclk_falling);


  logic [7:0] rx_reg, tx_reg;
  logic [2:0] bit_cnt;

  assign rx_data = rx_reg;


  assign miso = (!cs) ? tx_reg[7] : 1'bz;

  always_ff @(posedge clk or posedge reset) begin
    if (reset) begin
      rx_reg  <= 0;
      tx_reg  <= 0;
      bit_cnt <= 3'b0;
      rx_done <= 1'b0;
    end else begin
      if (cs) begin
        bit_cnt <= 3'b0;
        rx_done <= 1'b0;
        tx_reg  <= tx_data;
      end else begin
        //데이터 수신
        if (sample_edge) begin
          rx_reg <= {rx_reg[6:0], mosi};
          if (bit_cnt == 7) begin
            bit_cnt <= 0;
            rx_done <= 1'b1;
          end else begin
            bit_cnt <= bit_cnt + 1;
            rx_done <= 1'b0;
          end
        end

        //데이터 송신
        if (shift_edge) begin
          tx_reg <= {tx_reg[6:0], 1'b0};
        end
      end
    end
  end
endmodule
