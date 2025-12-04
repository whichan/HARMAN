`timescale 1ns / 1ps

module tb_uart_rx();

    parameter CLK_PERIOD = 10; //100MHz
    parameter UART_BIT_PERIOD = 10416 * CLK_PERIOD;

    //2. stimulus variables
    bit clk;
    bit reset;
    bit rx;

    //검증용 변수
    logic [7:0] data_out;
    logic rx_done;

    bit [7:0] stimulus_data;

    uart_rx u_tb_uart_rx(
        .clk(clk),
        .reset(reset),
        .rx(rx),
        .data_out(data_out),
        .rx_done(rx_done)
    );

    initial begin
        clk=0;
        forever #5 clk=~clk;
    end

    initial begin
        reset=1;
        rx=1; //UART IDLE 상태 1
        
        #10
        reset=0;

        //step1. 고정 데이터//
        #100
        stimulus_data = 8'h37;
        
        //데이터 전송
        uart_send_t(stimulus_data);
        
        #10
        compare_t();

        for (int i=0; i<256; i++) begin
            #200;
            stimulus_generate();
            uart_send_t(stimulus_data);

            #10
            compare_t();
        end

        #1000

        $stop;

    end

    task stimulus_generate();
        stimulus_data = $random()%256;
    endtask

    task uart_send_t(input [7:0] data);
        // 1. Start Bit (High -> Low)
        rx = 1'b0;
        #(UART_BIT_PERIOD);
        
        // 2. Data Bits (8 bits, LSB First)
        for (int i=0; i<8; i++) begin
            rx = data[i];
            #(UART_BIT_PERIOD);
        end

        // 3. Stop Bit (Low -> High)
        rx = 1'b1;
        #(UART_BIT_PERIOD/2);
        
    endtask

    // 결과 비교 태스크
    task compare_t();
        // DUT의 출력(data_out)과 내가 보낸 값(stimulus_data) 비교
        if (data_out == stimulus_data) begin
            //$display("%t: PASS! Sent=0x%x, Received=0x%x", $time, stimulus_data, data_out);
        end else begin
            $display("%t: FAIL! Sent=0x%x, Received=0x%x", $time, stimulus_data, data_out);
        end
    endtask

endmodule