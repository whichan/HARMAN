`timescale 1ns / 1ps

module UART_TX (
    input        clk,
    input        reset,
    input  [7:0] tx_data,
    input        baud_tick,
    input        start_trigger,
    output       tx,
    output       tx_busy
);

  typedef enum logic [1:0] {
    S_IDLE,
    S_START,
    S_DATA,
    S_STOP
  } STATE;

  STATE cur_state, next_state;

  logic [7:0] cur_data, next_data;
  logic [3:0] cur_tick_cnt, next_tick_cnt;
  logic [2:0] cur_bit_cnt, next_bit_cnt;

  logic cur_tx, next_tx;
  logic cur_busy, next_busy;

  assign tx      = cur_tx;
  assign tx_busy = cur_busy;

  always_ff @(posedge clk or posedge reset) begin
    if (reset) begin
      cur_state    <= S_IDLE;
      cur_data     <= 0;
      cur_tick_cnt <= 0;
      cur_bit_cnt  <= 0;
      cur_tx       <= 1;
      cur_busy     <= 0;
    end else begin
      cur_state    <= next_state;
      cur_data     <= next_data;
      cur_tick_cnt <= next_tick_cnt;`
      cur_bit_cnt  <= next_bit_cnt;
      cur_tx       <= next_tx;
      cur_busy     <= next_busy;
    end
  end

  always_comb begin
    next_state    = cur_state;
    next_data     = cur_data;
    next_tick_cnt = cur_tick_cnt;
    next_bit_cnt  = cur_bit_cnt;
    next_tx       = cur_tx;
    next_busy     = cur_busy;

    case (cur_state)

      S_IDLE: begin
        next_tx       = 1;
        next_busy     = 0;
        next_tick_cnt = 0;
        next_bit_cnt  = 0;

        if (start_trigger) begin
          next_data     = tx_data;
          next_busy     = 1;
          next_state    = S_START;
          next_tick_cnt = 0;
        end
      end


      S_START: begin
        next_tx   = 0;
        next_busy = 1;

        if (baud_tick) begin
          if (cur_tick_cnt == 15) begin
            next_tick_cnt = 0;
            next_bit_cnt  = 0;
            next_state    = S_DATA;
          end else next_tick_cnt = cur_tick_cnt + 1;

        end
      end

      S_DATA: begin
        next_tx   = cur_data[cur_bit_cnt];
        next_busy = 1;

        if (baud_tick) begin

          if (cur_tick_cnt == 15) next_tick_cnt = 0;
          else next_tick_cnt = cur_tick_cnt + 1;

          if (cur_tick_cnt == 15 && cur_bit_cnt == 7) next_state = S_STOP;

          else if (cur_tick_cnt == 15) next_bit_cnt = cur_bit_cnt + 1;

        end
      end

      S_STOP: begin
        next_tx   = 1;
        next_busy = 1;

        if (baud_tick) begin
          if (cur_tick_cnt == 15) begin
            next_tick_cnt = 0;
            next_busy     = 0;
            next_state    = S_IDLE;

          end else next_tick_cnt = cur_tick_cnt + 1;

        end
      end

    endcase
  end

endmodule
