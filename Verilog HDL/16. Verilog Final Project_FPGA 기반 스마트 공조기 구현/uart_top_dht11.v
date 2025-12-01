
`timescale 1ns / 1ps

module uart_top_dht11(
    input clk,
    input reset,
    input RsRx,
    inout dht11_pin_top_level, 
    
    output [15:0] led,
    output RsTx,
    
    // DHT11 데이터 출력 포트
    output [7:0] humi_INT_out,
    output [7:0] humi_REAL_out,
    output [7:0] temp_INT_out,
    output [7:0] temp_REAL_out,
    output data_valid_out,
    output error_flag_out
    );
    
    // --- 내부 와이어 정의 ---
    wire [7:0] w_wr_data;
    wire w_rd_en, w_wr_en;
    wire [7:0] w_rd_data;
    wire w_full, w_empty;
    wire w_tx_start;
    wire [7:0] w_tx_data;
    wire w_tx_done, w_tx_busy;
    
    // 기존 명령어 관련 와이어 (이제 사용 안 함)
    wire w_send_trigger_dummy; 
    wire [2:0] w_cmd_type_dummy;

    // 카운터 및 DHT11 와이어
    wire w_tick_1hz;
    wire w_tick_2hz; 
    wire [15:0] w_cnt_val;
    wire [7:0] w_humi_int, w_humi_real, w_temp_int, w_temp_real; 
    wire w_dht_data_valid, w_dht_error;
    
    // 1. 1Hz Tick
    tick_generator_dht11 #(.INPUT_REQ(100_000_000), .TICK_Hz(1)) u_tick_1hz (
        .clk(clk), .reset(reset), .tick(w_tick_1hz)
    );
    
    // 2. DHT11 구동용 Tick (이 주기에 맞춰서 데이터가 나옵니다)
    tick_generator_dht11 #(.INPUT_REQ(100_000_000), .TICK_Hz(1)) u_dht_tick (
        .clk(clk), .reset(reset), .tick(w_tick_2hz) 
    );
    
    // 3. Up Counter
    up_counter u_up_counter(
        .clk(clk), .reset(reset), .trigger_1hz(w_tick_1hz), .count(w_cnt_val)
    );
    
    // 4. DHT11 Module
    dht11 u_dht11(
        .clk(clk),
        .reset(reset),
        .dht_pin(dht11_pin_top_level), 
        .start_read(w_tick_2hz),       

        .humi_INT_out(w_humi_int), 
        .humi_REAL_out(w_humi_real), 
        .temp_INT_out(w_temp_int),
        .temp_REAL_out(w_temp_real),
        .data_valid(w_dht_data_valid),
        .error_flag(w_dht_error)
    );

    // 5. UART RX & Queue (수신은 받기만 하고 무시함)
    uart_rx u_uart_rx(
        .clk(clk), .reset(reset), .rx(RsRx), .data_out(w_wr_data), .rx_done(w_wr_en)
    );

    circular_queue #(.DATA_WIDTH(8), .DEPTH(64)) u_circular_queue (
        .clk(clk), .reset(reset), .wr_en(w_wr_en), .wr_data(w_wr_data), 
        .rd_en(w_rd_en), .rd_data(w_rd_data), .full(w_full), .empty(w_empty)
    );

    // 6. Command Controller (연결은 해두되, 출력은 무시)
    command_controller u_command_controller(
        .clk(clk), .reset(reset),
        .queue_data_in(w_rd_data), .queue_empty(w_empty), .queue_rd_en(w_rd_en),
        .led(led), // LED 제어는 여전히 키보드로 가능 (선택사항)
        
        .i_temp_val(w_temp_int), 
        .i_humi_val(w_humi_int), 
        .i_data_valid(w_dht_data_valid),
        
        .send_trigger(w_send_trigger_dummy), // 사용 안 함
        .cmd_type(w_cmd_type_dummy),         // 사용 안 함
        .sender_busy(w_tx_busy)
    );
    

    data_sender u_data_sender(
        .clk(clk), .reset(reset),
        
        // 명령어가 아니라, "데이터가 유효해지면(Valid)" 바로 전송 시작
        .start_trigger(w_dht_data_valid), 
        
        //전송 타입은 무조건 "온습도(Type 3)"로 고정
        .cmd_type(3'd3), 
        
        .i_counter_val(w_cnt_val), 
        
        .i_temp_int(w_temp_int), 
        .i_temp_real(w_temp_real), 
        .i_humi_int(w_humi_int), 
        .i_humi_real(w_humi_real), 

        .sender_busy(w_sender_busy),
        .tx_busy(w_tx_busy), .tx_done(w_tx_done),
        .tx_start(w_tx_start), .tx_data(w_tx_data)
    );

    // 8. UART TX
    uart_tx u_uart_tx(
        .clk(clk), .reset(reset), .tx_data(w_tx_data), .tx_start(w_tx_start),
        .tx(RsTx), .tx_done(w_tx_done), .tx_busy(w_tx_busy)
    );
    
    // 외부 포트 연결
    assign humi_INT_out = w_humi_int;
    assign humi_REAL_out = w_humi_real;
    assign temp_INT_out = w_temp_int;
    assign temp_REAL_out = w_temp_real;
    assign data_valid_out = w_dht_data_valid;
    assign error_flag_out = w_dht_error;

endmodule