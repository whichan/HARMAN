`timescale 1ns / 1ps

module UART_RX (

    input        clk,
    input        reset,
    input        baud_tick,
    input        rx,
    output [7:0] rx_data,
    output       rx_done

);

  typedef enum logic [1:0] {
    S_IDLE,
    S_START,
    S_DATA,
    S_STOP
  } STATE;

  STATE cur_state;
  STATE next_state;

  logic [7:0] cur_rx_data;
  logic [7:0] next_rx_data;

  logic [3:0] cur_tick_cnt, next_tick_cnt;
  logic [2:0] cur_bit_cnt, next_bit_cnt;

  logic cur_rx_done;
  logic next_rx_done;

  assign rx_data = cur_rx_data;
  assign rx_done = cur_rx_done;

  always_ff @(posedge clk or posedge reset) begin
    if (reset) begin
      cur_state <= S_IDLE;
      cur_rx_data <= 0;
      cur_rx_done <= 0;
      cur_tick_cnt <= 0;
      cur_bit_cnt <= 0;
    end else begin
      cur_state <= next_state;
      cur_rx_data <= next_rx_data;
      cur_rx_done <= next_rx_done;
      cur_tick_cnt <= next_tick_cnt;
      cur_bit_cnt <= next_bit_cnt;
    end
  end

  always_comb begin
    next_state = cur_state;
    next_rx_data = cur_rx_data;
    next_rx_done = 0;
    next_tick_cnt = cur_tick_cnt;
    next_bit_cnt = cur_bit_cnt;
    case (cur_state)
      S_IDLE: begin
        next_rx_done = 0;
        if (rx == 0) begin
          next_state = S_START;
        end
      end
      S_START: begin
        if (baud_tick) begin
          if (cur_tick_cnt == 7) begin
            next_state = S_DATA;
            next_tick_cnt = 0;
            next_bit_cnt = 0;
          end else next_tick_cnt = cur_tick_cnt + 1;
        end
      end

      S_DATA: begin
        if (baud_tick) begin
          if (cur_tick_cnt == 15) next_tick_cnt = 0;
          else next_tick_cnt = cur_tick_cnt + 1;

          if (cur_tick_cnt == 15) begin
            next_rx_data = cur_rx_data;
            next_rx_data[cur_bit_cnt] = rx;

            if (cur_bit_cnt == 7) next_state = S_STOP;
            else next_bit_cnt = cur_bit_cnt + 1;
          end

        end
      end

      S_STOP: begin
        if (baud_tick) begin

          if (cur_tick_cnt == 15) begin
            next_tick_cnt = 0;
            next_state    = S_IDLE;

          end else begin
            next_tick_cnt = cur_tick_cnt + 1;

            if (cur_tick_cnt == 7) next_rx_done = 1;
          end
        end
      end


    endcase
  end

endmodule

/*     
            S_DATA: begin
                if (baud_tick) begin
                    next_tick_cnt = cur_tick_cnt + 1;
                    if (cur_tick_cnt == 15) begin
                        next_bit_cnt = cur_bit_cnt + 1;
                        next_rx_data = {rx, cur_rx_data[7:1]};
                        if (cur_bit_cnt == 7) begin
                            next_state = S_STOP;
                            next_tick_cnt = 0;
                        end
                        next_tick_cnt = 0;
                    end
                end
            end
*/
