`timescale 1ns / 1ps

module spi_ascii_test (
    input  logic clk,
    input  logic reset,
    input  logic sw,
    output logic sclk,
    output logic mosi,
    input  logic miso
);

  logic       tick;
  logic       start;
  logic [7:0] tx_data;
  logic       tx_ready;

  clk_div U_CLK_DIV (.*);
  ascii_send U_ASCII_SEND (.*);
  spi_master U_SPI_MASTER (
      .*,
      .rx_data(),
      .done(),
      .cpol(cpol),
      .cpha(cpha)
  );

endmodule

module clk_div (
    input        clk,
    input        reset,
    output logic tick
);

  logic [$clog2(10_000_000)-1:0] div_counter;

  always_ff @(posedge clk or posedge reset) begin
    if (reset) begin
      div_counter <= 0;
      tick        <= 1'b0;
    end else begin
      if (div_counter == 10_000_000 - 1) begin
        div_counter <= 0;
        tick        <= 1'b1;
      end else begin
        div_counter <= div_counter + 1;
        tick        <= 1'b0;
      end
    end
  end
endmodule

module ascii_send (
    input  logic       clk,
    input  logic       reset,
    input  logic       sw,
    input  logic       tick,
    output logic       start,
    output logic [7:0] tx_data,
    input  logic       tx_ready
);

  typedef enum logic [1:0] {
    IDLE,
    TX_WAIT,
    TX_ASCII
  } state_t;

  state_t state, state_next;

  logic [7:0] tx_data_reg, tx_data_next;
  logic [7:0] ascii_reg, ascii_next;

  assign tx_data = tx_data_reg;


  always_ff @(posedge clk, posedge reset) begin
    if (reset) begin
      state       <= IDLE;
      tx_data_reg <= 0;
      ascii_reg   <= 8'h30;
    end else begin
      state       <= state_next;
      tx_data_reg <= tx_data_next;
      ascii_reg   <= ascii_next;
    end
  end

  always_comb begin
    state_next   = state;
    tx_data_next = tx_data_reg;
    ascii_next   = ascii_reg;
    start        = 1'b0;
    case (state)

      IDLE: begin
        start = 1'b0;
        ascii_next = 8'h30;
        if (sw) begin
          state_next = TX_WAIT;
        end
      end

      TX_WAIT: begin
        start = 1'b0;
        if (tick & tx_ready) begin
          state_next = TX_ASCII;
        end
        if (sw == 1'b0) begin
          state_next = IDLE;
        end
      end

      TX_ASCII: begin
        start        = 1'b1;
        tx_data_next = ascii_reg;
        state_next   = TX_WAIT;
        if (ascii_reg == 8'h7a) begin
          ascii_next = 8'h30;
        end else begin
          ascii_next = ascii_reg + 2;
        end
      end
    endcase
  end
endmodule
