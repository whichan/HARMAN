`timescale 1ns / 1ps

module UART_TOP (
    input clk,
    input reset,

    //uart
    output RsTx,
    input  RsRx,

    //fifo tx
    input  [7:0] wdata,
    input        wr,
    output       full,

    //fifo rx
    output [7:0] rdata,
    input        rd,
    output       empty
);
  logic [7:0] w_rxdata;
  logic [7:0] w_txdata;
  logic w_wr;
  logic w_fifotx_empty;
  logic w_tx_busy;
  logic w_baud_tick;

  UART_RX U_UART_RX (

      .clk(clk),
      .reset(reset),
      .baud_tick(w_baud_tick),
      .rx(RsRx),
      .rx_data(w_rxdata),
      .rx_done(w_wr)
  );

  UART_TX U_UART_TX (
      .clk(clk),
      .reset(reset),
      .tx_data(w_txdata),
      .baud_tick(w_baud_tick),
      .start_trigger(~w_fifotx_empty),
      .tx(RsTx),
      .tx_busy(w_tx_busy)
  );

  FIFO_TX U_FIFO_TX (

      .clk(clk),
      .reset(reset),
      .wr(w_wr),
      .rd(rd),
      .wdata(w_rxdata),
      .rdata(rdata),
      .full(),
      .empty(empty)
  );

  FIFO_RX U_FIFO_RX (

      .clk(clk),
      .reset(reset),
      .wr(wr),
      .rd((~w_tx_busy) & (~w_fifotx_empty)),
      .wdata(wdata),
      .rdata(w_txdata),
      .full(full),
      .empty(w_fifotx_empty)
  );

  clk_divider U_clk_divider (

      .clk(clk),
      .reset(reset),
      .baud_tick(w_baud_tick)

  );

endmodule
