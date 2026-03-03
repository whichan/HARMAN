`timescale 1ns / 1ps


module spi_top (
    //global signals
    input  logic       clk,
    input  logic       reset,
    //external interface signals
    input  logic       start,
    input  logic [7:0] tx_data,   //cpu -> spi master -> spi slave
    output logic       tx_ready,  //spi master -> cpu
    output logic [7:0] rx_data,   //spi slave -> spi master -> cpu
    output logic       done,      //spi master -> cpu
    input  logic       cpha,
    input  logic       cpol,

    //external
    input  logic [7:0] slave_tx_data,
    output logic [7:0] slave_rx_data,
    output logic       slave_rx_done
);




  logic sclk, mosi, miso, cs;

  spi_master U_SPI_MASTER (
      .*,
      .start(start),
      .tx_data(tx_data),
      .tx_ready(tx_ready),
      .rx_data(rx_data),
      .done(done)
  );

  spi_slave U_SPI_SLAVE (
      .*,
      .tx_data(slave_tx_data),
      .rx_data(slave_rx_data),
      .rx_done(slave_rx_done)
  );

endmodule
