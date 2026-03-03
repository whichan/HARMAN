`timescale 1ns / 1ps

module I2C_top (
    input  logic       clk,
    input  logic       reset,
    input  logic       i2c_en,
    input  logic       i2c_start,
    input  logic       i2c_stop,
    input  logic [7:0] tx_data,
    output logic       tx_done,
    output logic       tx_ready,
    output logic [7:0] rx_data,
    output logic       rx_done,

    // input  logic [6:0] slave_addr,
    input  logic [7:0] slave_tx_data,   //slave -> master
    output logic       slave_tx_ready,
    output logic [7:0] slave_rx_data,   //master -> slave
    output logic       slave_rx_done
);

  tri1  sda;
  logic scl;


  I2C_Master U_I2C_MASTER (
      .clk  (clk),
      .reset(reset),

      .i2c_en(i2c_en),
      .i2c_start(i2c_start),
      .i2c_stop(i2c_stop),
      .tx_data(tx_data),
      .tx_done(tx_done),
      .tx_ready(tx_ready),
      .rx_data(rx_data),
      .rx_done(rx_done),

      .scl(scl),
      .sda(sda)
  );

  I2C_Slave U_I2C_Slave (
      .clk(clk),
      .reset(reset),
      .sda(sda),
      .scl(scl),
      .tx_data(slave_tx_data),
      .tx_ready(slave_tx_ready),
      .rx_data(slave_rx_data),
      .rx_done(slave_rx_done)
  );
endmodule
