`timescale 1ns / 1ps

module I2C_Slave (
    //global signals
    input  logic       clk,
    input  logic       reset,
    //i2c interface signals
    inout  logic       sda,
    input  logic       scl,
    //external interface signals
    // input  logic [6:0] slave_addr,
    input  logic [7:0] tx_data,
    output logic       tx_ready,
    output logic [7:0] rx_data,
    output logic       rx_done,
    output logic       led1
);

  parameter SLAVE_ADDRESS = 7'h50;  // 원하는 슬레이브 주소

  typedef enum logic [2:0] {
    IDLE,
    ADDR_READ,
    ADDR_ACK,
    DATA_READ,
    DATA_RACK,
    DATA_WRITE,
    DATA_WACK
  } state_t;

  state_t state, state_next;

  logic [2:0] sda_sync, scl_sync;
  logic ack_flag_reg, ack_flag_next;

  always_ff @(posedge clk or posedge reset) begin
    if (reset) begin
      sda_sync <= 3'b111;
      scl_sync <= 3'b111;
    end else begin
      sda_sync <= {sda_sync[1:0], sda};
      scl_sync <= {scl_sync[1:0], scl};
    end
  end

  logic scl_posedge, sda_posedge;
  logic scl_negedge, sda_negedge;
  logic start_detect, stop_detect;

  assign scl_posedge  = (scl_sync[2:1] == 2'b01);  //0->1: 상승엣지
  assign scl_negedge  = (scl_sync[2:1] == 2'b10);  //1->0: 하강엣지

  assign sda_posedge  = (sda_sync[2:1] == 2'b01);  //0->1: 상승엣지
  assign sda_negedge  = (sda_sync[2:1] == 2'b10);  //1->0: 하강엣지

  assign start_detect = (scl_sync[1] == 1'b1) && sda_negedge;
  assign stop_detect  = (scl_sync[1] == 1'b1) && sda_posedge;

  //내부 레지스터
  logic [7:0] shift_reg, shift_next;
  logic [3:0] bit_cnt_reg, bit_cnt_next;
  logic rw_flag_reg, rw_flag_next;  //read write 판단

  logic sda_reg, sda_next;
  logic sda_en;

  logic [7:0] rx_data_reg, rx_data_next;
  logic rx_done_reg, rx_done_next;
  logic tx_ready_reg, tx_ready_next;

  logic led1_reg;  // LED 상태를 저장할 레지스터
  assign led1     = led1_reg;

  assign sda      = (sda_en) ? sda_reg : 1'bz;
  assign rx_data  = rx_data_reg;
  assign rx_done  = rx_done_reg;
  assign tx_ready = tx_ready_reg;

  always_ff @(posedge clk or posedge reset) begin
    if (reset) begin
      led1_reg <= 1'b0;
    end else begin
      // rx_done이 1이 되었다는 것은 나(Slave)에게 데이터 전송이 성공적으로 끝났다는 뜻입니다.
      if (rx_done) begin
        // 방법 1: 마스터가 보낸 데이터의 0번 비트에 따라 LED를 On/Off (추천)
        // 마스터에서 스위치를 누르면 1, 떼면 0을 보낸다고 가정할 때
        led1_reg <= rx_data[0];

        /* // 방법 2: 데이터가 올 때마다 LED를 토글(반전)시키고 싶다면
                led1_reg <= ~led1_reg; 
                */
      end
    end
  end

  always_ff @(posedge clk or posedge reset) begin
    if (reset) begin
      state        <= IDLE;
      shift_reg    <= 0;
      bit_cnt_reg  <= 0;
      rw_flag_reg  <= 0;
      sda_reg      <= 0;
      rx_data_reg  <= 0;
      rx_done_reg  <= 0;
      tx_ready_reg <= 0;
      ack_flag_reg <= 0;
    end else begin
      state        <= state_next;
      shift_reg    <= shift_next;
      bit_cnt_reg  <= bit_cnt_next;
      rw_flag_reg  <= rw_flag_next;
      sda_reg      <= sda_next;
      rx_data_reg  <= rx_data_next;
      rx_done_reg  <= rx_done_next;
      tx_ready_reg <= tx_ready_next;
      ack_flag_reg <= ack_flag_next;
    end
  end

  always_comb begin
    state_next    = state;
    shift_next    = shift_reg;
    bit_cnt_next  = bit_cnt_reg;
    rw_flag_next  = rw_flag_reg;
    sda_next      = sda_reg;
    rx_data_next  = rx_data_reg;
    rx_done_next  = 1'b0;
    tx_ready_next = tx_ready_reg;
    sda_en        = 1'b0;  //기본 high-z
    ack_flag_next = ack_flag_reg;

    case (state)
      IDLE: begin
        sda_en        = 1'b0;
        bit_cnt_next  = 0;
        rx_done_next  = 1'b0;
        tx_ready_next = 1'b1;
        if (start_detect) begin
          state_next = ADDR_READ;
        end
      end

      ADDR_READ: begin
        sda_en = 1'b0;
        if (scl_posedge) begin
          shift_next = {shift_reg[6:0], sda_sync[1]};
        end
        if (scl_negedge) begin
          if (bit_cnt_reg == 8) begin
            state_next   = ADDR_ACK;
            bit_cnt_next = 0;
          end else begin
            bit_cnt_next = bit_cnt_reg + 1;
          end
        end

        if (stop_detect) state_next = IDLE;
      end

      ADDR_ACK: begin
        if (shift_reg[7:1] == SLAVE_ADDRESS) begin
          sda_en   = 1'b1;  //ACK 전송
          sda_next = 1'b0;
          if (scl_negedge) begin
            rw_flag_next = shift_reg[0];
            bit_cnt_next = 0;
            if (shift_reg[0] == 0) begin
              state_next = DATA_READ;
            end else begin
              state_next = DATA_WRITE;
              shift_next = tx_data;  //데이터 송신
            end
          end
        end else begin
          state_next = IDLE;
        end
      end

      DATA_READ: begin
        sda_en = 1'b0;
        if (scl_posedge) begin
          shift_next = {shift_reg[6:0], sda_sync[1]};
        end

        if (scl_negedge) begin
          if (bit_cnt_reg == 7) begin
            bit_cnt_next = 0;
            rx_data_next = shift_reg; //이미 8비트가 완성된 상태(위의 posedge 코드에 의해서)
            state_next = DATA_RACK;
          end else begin
            bit_cnt_next = bit_cnt_reg + 1;
          end
        end
      end

      DATA_RACK: begin
        sda_en   = 1'b1;  //slave -> drive
        sda_next = 1'b0;
        if (scl_negedge) begin
          state_next   = DATA_READ;
          rx_done_next = 1'b1;
        end
        if (stop_detect) state_next = IDLE;
      end

      DATA_WRITE: begin
        sda_en   = ~shift_reg[7];
        sda_next = 1'b0;
        if (scl_negedge) begin
          shift_next = {shift_reg[6:0], 1'b0};
          if (bit_cnt_reg == 7) begin
            bit_cnt_next = 0;
            state_next   = DATA_WACK;
          end else begin
            bit_cnt_next = bit_cnt_reg + 1;
          end
        end
      end

      DATA_WACK: begin
        sda_en = 1'b0;  //master -> write
        if (scl_posedge) begin
          ack_flag_next = sda_sync[1]; //rising edge에서 읽은 SDA값(ACK값)을 falling edge까지 저장하고 있어야됨
        end

        if (scl_negedge) begin
          if (ack_flag_reg == 0) begin  //ack=0이면 더 보내기
            state_next = DATA_WRITE;
            shift_next = tx_data;
          end else begin
            state_next = IDLE;
          end
        end
      end
    endcase

    // Repeated Start: 어느 상태에서든 Start 감지 시 ADDR_READ로
    if (start_detect && state != IDLE) begin
      state_next   = ADDR_READ;
      bit_cnt_next = 0;
    end

    // Stop: 어느 상태에서든 Stop 감지 시 IDLE로
    if (stop_detect) begin
      state_next = IDLE;
    end
  end
endmodule
