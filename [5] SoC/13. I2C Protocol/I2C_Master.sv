`timescale 1ns / 1ps

module I2C_Master (
    //global signals
    input  logic       clk,
    input  logic       reset,
    //external signals
    input  logic       i2c_en,
    input  logic       i2c_start,
    input  logic       i2c_stop,
    input  logic [7:0] tx_data,
    output logic       tx_done,
    output logic       tx_ready,
    output logic [7:0] rx_data,
    output logic       rx_done,
    //i2c interface signals
    output logic       scl,
    inout  wire        sda
);

  typedef enum logic [4:0] {
    IDLE,
    START1,
    START2,
    DATA1,
    DATA2,
    DATA3,
    DATA4,
    WACK1,
    WACK2,
    WACK3,
    WACK4,
    HOLD,
    READ1,
    READ2,
    READ3,
    READ4,
    RACK1,
    RACK2,
    RACK3,
    RACK4,
    STOP1,
    STOP2
  } state_t;

  state_t state, state_next;


  logic [$clog2(500)-1:0] clk_cnt_reg, clk_cnt_next;
  logic [3:0] bit_cnt_reg, bit_cnt_next;
  logic [7:0] tx_data_reg, tx_data_next;
  logic [7:0] rx_data_reg, rx_data_next;
  logic tx_done_reg, tx_done_next;
  logic tx_ready_reg, tx_ready_next;
  logic rx_done_reg, rx_done_next;
  logic ack_flag_reg, ack_flag_next;
  logic scl_reg, scl_next;
  logic sda_reg, sda_next;
  logic sda_en;

  assign scl = scl_reg;
  assign sda = (sda_en) ? sda_reg : 1'bz; //sda_en이 1일 때만 sda_reg가 나가고 0일 때는 끊어짐
  assign tx_done = tx_done_reg;
  assign tx_ready = tx_ready_reg;
  assign rx_done = rx_done_reg;

  always_ff @(posedge clk or posedge reset) begin
    if (reset) begin
      state        <= IDLE;
      clk_cnt_reg  <= 0;
      bit_cnt_reg  <= 0;
      tx_data_reg  <= 0;
      rx_data_reg  <= 0;
      tx_done_reg  <= 0;
      tx_ready_reg <= 1'b0;
      rx_done_reg  <= 1'b0;
      ack_flag_reg <= 1'b0;
      scl_reg      <= 1'b1;
      sda_reg      <= 1'b1;
    end else begin
      state        <= state_next;
      clk_cnt_reg  <= clk_cnt_next;
      bit_cnt_reg  <= bit_cnt_next;
      tx_data_reg  <= tx_data_next;
      rx_data_reg  <= rx_data_next;
      tx_done_reg  <= tx_done_next;
      tx_ready_reg <= tx_ready_next;
      rx_done_reg  <= rx_done_next;
      ack_flag_reg <= ack_flag_next;
      scl_reg      <= scl_next;
      sda_reg      <= sda_next;
    end
  end

  always_comb begin
    state_next    = state;
    clk_cnt_next  = clk_cnt_reg;
    bit_cnt_next  = bit_cnt_reg;
    tx_data_next  = tx_data_reg;
    rx_data_next  = rx_data_reg;
    tx_done_next  = tx_done_reg;
    tx_ready_next = tx_ready_reg;
    rx_done_next  = rx_done_reg;
    ack_flag_next = ack_flag_reg;
    scl_next      = scl_reg;
    sda_next      = sda_reg;
    sda_en        = 1'b1;
    case (state)
      IDLE: begin
        sda_en        = 1'b0;
        scl_next      = 1'b1;
        tx_done_next  = 1'b0;
        tx_ready_next = 1'b1;
        rx_done_next  = 1'b0;
        if (i2c_en) begin
          state_next    = START1;
          clk_cnt_next  = 0;
          tx_ready_next = 0;
          tx_data_next  = tx_data;
        end
      end

      START1: begin
        sda_en   = 1'b1;
        sda_next = 1'b0;
        scl_next = 1'b1;
        if (clk_cnt_reg == 500 - 1) begin
          clk_cnt_next = 0;
          state_next   = START2;
        end else begin
          clk_cnt_next = clk_cnt_reg + 1;
        end
      end
      START2: begin
        sda_en   = 1'b1;
        sda_next = 1'b0;
        scl_next = 1'b0;
        if (clk_cnt_reg == 500 - 1) begin
          clk_cnt_next = 0;
          state_next   = DATA1;
        end else begin
          clk_cnt_next = clk_cnt_reg + 1;
        end
      end

      DATA1: begin
        sda_en   = ~tx_data_reg[7];
        sda_next = 1'b0;
        scl_next = 1'b0;
        if (clk_cnt_reg == 250 - 1) begin
          clk_cnt_next = 0;
          state_next   = DATA2;
        end else begin
          clk_cnt_next = clk_cnt_reg + 1;
        end
      end
      DATA2: begin
        sda_en   = ~tx_data_reg[7];
        sda_next = 1'b0;
        scl_next = 1'b1;
        if (clk_cnt_reg == 250 - 1) begin
          clk_cnt_next = 0;
          state_next   = DATA3;
        end else begin
          clk_cnt_next = clk_cnt_reg + 1;
        end
      end
      DATA3: begin
        sda_en   = ~tx_data_reg[7];
        sda_next = 1'b0;
        scl_next = 1'b1;
        if (clk_cnt_reg == 250 - 1) begin
          clk_cnt_next = 0;
          state_next   = DATA4;
        end else begin
          clk_cnt_next = clk_cnt_reg + 1;
        end
      end
      DATA4: begin
        sda_en   = ~tx_data_reg[7];
        sda_next = 1'b0;
        scl_next = 1'b0;
        if (clk_cnt_reg == 250 - 1) begin
          clk_cnt_next = 0;
          if (bit_cnt_reg == 7) begin
            state_next   = WACK1;
            bit_cnt_next = 0;
          end else begin
            bit_cnt_next = bit_cnt_reg + 1;
            tx_data_next = {tx_data_reg[6:0], 1'b0};
            state_next   = DATA1;
          end
        end else begin
          clk_cnt_next = clk_cnt_reg + 1;
        end
      end


      WACK1: begin
        sda_en   = 1'b0;  //slave -> master
        scl_next = 1'b0;
        if (clk_cnt_reg == 250 - 1) begin
          clk_cnt_next = 0;
          state_next   = WACK2;
        end else begin
          clk_cnt_next = clk_cnt_reg + 1;
        end
      end

      WACK2: begin
        sda_en   = 1'b0;  //slave -> master
        scl_next = 1'b1;
        if (clk_cnt_reg == 250 - 1) begin
          clk_cnt_next = 0;
          ack_flag_next = sda;  //SCL=1 정중앙에서 sda 샘플링(sda데이터가 안정적임)
          state_next = WACK3;
        end else begin
          clk_cnt_next = clk_cnt_reg + 1;
        end
      end

      WACK3: begin
        sda_en   = 1'b0;  //slave -> master
        scl_next = 1'b1;
        if (clk_cnt_reg == 250 - 1) begin
          clk_cnt_next = 0;
          state_next   = WACK4;
        end else begin
          clk_cnt_next = clk_cnt_reg + 1;
        end
      end

      WACK4: begin
        sda_en   = 1'b0;  //slave -> master
        scl_next = 1'b0;
        if (clk_cnt_reg == 250 - 1) begin
          clk_cnt_next = 0;
          if (ack_flag_reg == 0) begin
            //ACK
            tx_done_next = 1'b1;
            state_next   = HOLD;
          end else begin
            //NACK
            state_next = STOP1;
            //NACK이면 통신 실패이기 때문에 tx_done을 1로 올리면 안됨
          end
        end else begin
          clk_cnt_next = clk_cnt_reg + 1;
        end
      end

      HOLD: begin
        tx_done_next  = 1'b0; //tx_done을 다시 0으로 내려줘야함. 그러지 않으면 두번째 데이터 바이트를 받을 때 @(posedge tx_done)을 감지하지 못함. 왜냐? 이미 계속 1이었기 땜에
        tx_ready_next = 1'b1;
        if (i2c_en) begin
          tx_data_next = tx_data;
          case ({
            i2c_start, i2c_stop
          })
            2'b00: state_next = DATA1;  //write
            2'b01: state_next = STOP1;  //stop
            2'b10: state_next = START1;  //start
            2'b11: state_next = READ1;  //read
          endcase
        end
      end

      READ1: begin
        sda_en       = 1'b0;
        scl_next     = 1'b0;
        rx_done_next = 1'b1;  //좀헷갈림
        if (clk_cnt_reg == 250 - 1) begin
          clk_cnt_next = 0;
          state_next   = READ2;
        end else begin
          clk_cnt_next = clk_cnt_reg + 1;
        end
      end

      READ2: begin
        sda_en   = 1'b0;
        scl_next = 1'b1;
        if (clk_cnt_reg == 250 - 1) begin
          clk_cnt_next = 0;
          rx_data_next = {rx_data_reg[6:0], sda};
          state_next   = READ3;
        end else begin
          clk_cnt_next = clk_cnt_reg + 1;
        end
      end

      READ3: begin
        sda_en   = 1'b0;
        scl_next = 1'b1;
        if (clk_cnt_reg == 250 - 1) begin
          clk_cnt_next = 0;
          state_next   = READ4;
        end else begin
          clk_cnt_next = clk_cnt_reg + 1;
        end
      end

      READ4: begin
        sda_en   = 1'b0;
        scl_next = 1'b0;
        if (clk_cnt_reg == 250 - 1) begin
          clk_cnt_next = 0;
          if (bit_cnt_reg == 7) begin
            state_next   = RACK1;
            bit_cnt_next = 0;
          end else begin
            bit_cnt_next = bit_cnt_reg + 1;
            state_next   = READ1;
          end
        end else begin
          clk_cnt_next = clk_cnt_reg + 1;
        end
      end

      RACK1: begin
        //i2c_stop=1이면 NACK(1)
        //i2c_stop=0이면 ACK(0)
        if (i2c_stop && !i2c_start) begin
          sda_en = 1'b0;  //pullup
        end else begin
          sda_en   = 1'b1;
          sda_next = 1'b0;
        end
        scl_next = 1'b0;
        if (clk_cnt_reg == 249) begin
          clk_cnt_next = 0;
          state_next   = RACK2;
        end else begin
          clk_cnt_next = clk_cnt_reg + 1;
        end
      end

      RACK2: begin
        //i2c_stop=1이면 NACK(1)
        //i2c_stop=0이면 ACK(0)
        if (i2c_stop && !i2c_start) begin
          sda_en = 1'b0;  //pullup
        end else begin
          sda_en   = 1'b1;
          sda_next = 1'b0;
        end
        scl_next = 1'b1;
        if (clk_cnt_reg == 249) begin
          clk_cnt_next = 0;
          state_next   = RACK3;
        end else begin
          clk_cnt_next = clk_cnt_reg + 1;
        end
      end

      RACK3: begin
        //i2c_stop=1이면 NACK(1)
        //i2c_stop=0이면 ACK(0)
        if (i2c_stop && !i2c_start) begin
          sda_en = 1'b0;  //pullup
        end else begin
          sda_en   = 1'b1;
          sda_next = 1'b0;
        end
        scl_next = 1'b1;
        if (clk_cnt_reg == 249) begin
          clk_cnt_next = 0;
          state_next   = RACK4;
        end else begin
          clk_cnt_next = clk_cnt_reg + 1;
        end
      end

      RACK4: begin
        //i2c_stop=1이면 NACK(1)
        //i2c_stop=0이면 ACK(0)
        if (i2c_stop && !i2c_start) begin
          sda_en = 1'b0;  //pullup
        end else begin
          sda_en   = 1'b1;
          sda_next = 1'b0;
        end
        scl_next = 1'b0;

        if (clk_cnt_reg == 249) begin
          clk_cnt_next = 0;
          rx_done_next = 1'b1;
          if (i2c_stop && !i2c_start) begin
            state_next = STOP1;
          end else begin
            state_next = READ1;
          end
        end else begin
          clk_cnt_next = clk_cnt_reg + 1;
        end
      end

      STOP1: begin
        sda_en       = 1'b1;
        sda_next     = 1'b0;
        scl_next     = 1'b1;
        rx_done_next = 1'b0;
        if (clk_cnt_reg == 499) begin
          clk_cnt_next = 0;
          state_next   = STOP2;
        end else begin
          clk_cnt_next = clk_cnt_reg + 1;
        end
      end

      STOP2: begin
        sda_en   = 1'b0;
        scl_next = 1'b1;
        if (clk_cnt_reg == 499) begin
          clk_cnt_next = 0;
          state_next   = IDLE;
          if (ack_flag_reg == 0) begin
            tx_done_next = 1'b1;
          end else begin
            tx_done_next = 1'b0;
          end
        end else begin
          clk_cnt_next = clk_cnt_reg + 1;
        end
      end

      default: begin
        state_next = IDLE;
      end
    endcase
  end

endmodule
