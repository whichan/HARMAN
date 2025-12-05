`timescale 1ns / 1ps

module tb_uart_rx();

    parameter CLK_PERIOD = 10; //100MHz
    parameter UART_BIT_PERIOD = 10416 * CLK_PERIOD;

    //입력신호(tb -> DUT)
    bit clk;
    bit reset;
    bit rx;

    //출력 신호(DUT -> tb)
    logic [7:0] data_out;
    logic rx_done;

    //검증용 데이터
    bit [7:0] stimulus_data; //내가 보낼 데이터

    integer pass_cnt;
    integer fail_cnt;

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
        //1.초기화
        pass_cnt=0;
        fail_cnt=0;
        reset=1;
        rx=1; //UART IDLE 상태에서 1
        
        #10
        reset=0;

        //step1. 고정 데이터 테스트
        #100
        stimulus_data = 8'h30;
        
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

        $display("PASS Count: %0d", pass_cnt);
        $display("FAIL Count: %0d", fail_cnt);

        $stop;

    end

    //task1. 랜덤 데이터 생성
    task stimulus_generate();
        stimulus_data = $random()%256;
    endtask

    //task2. 송신기
    //8비트 데이터를 받아서 rx선을 0,1로 흔들어줌
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

    // task3. 결과 계산 태스크
    task compare_t();
        // DUT의 출력(data_out)과 내가 보낸 값(stimulus_data) 비교
        if (data_out == stimulus_data) begin
            pass_cnt++;
            //$display("%t: PASS! Sent=0x%x, Received=0x%x", $time, stimulus_data, data_out);
        end else begin
            fail_cnt++;
            $display("%t: FAIL! Sent=0x%x, Received=0x%x", $time, stimulus_data, data_out);
        end
    endtask

endmodule