`timescale 1ns / 1ps

module tb_top();

    logic clk;
    logic reset;
    logic clear;
    logic run_stop;
    logic mode;

    logic RsRx;
    logic RsTx;

    logic [7:0] fnd_data;
    logic [3:0] fnd_com;

    //=====시간 상수=====//
    //UART 9600bps 1비트 시간: 1s/9600 = 104,166ns
    localparam UART_BIT_PERIOD = 104_166;

    //카운터 한번 올라가는 시간: 0.1초
    //3번 카운트
    localparam WAIT_COUNT = 350_000_000; //3.5초

    top u_top(
        .clk(clk),
        .reset(reset),
        
        .clear(clear),
        .run_stop(run_stop),
        .mode(mode),

        .RsRx(RsRx), // 테스트벤치가 이 선을 흔들어 줍니다.
        .RsTx(RsTx),

        .fnd_data(fnd_data),
        .fnd_com(fnd_com)
    );

    initial begin
        clk=0;
        forever #5 clk=~clk;
    end

    initial begin
        reset=1;
        clear=0;
        run_stop=0;
        mode=0;
        RsRx=1; //IDLE 상태일 때 1

        #100
        reset=0;

        // ===== 1. 'r'전송: down count start ===== //
        send_uart_byte("r");
        #(WAIT_COUNT+WAIT_COUNT/3);

        // ===== 2. 'm'전송: up count start ===== //
        send_uart_byte("m");
        #(WAIT_COUNT+WAIT_COUNT/4);

        // ===== 3. 'r' 전송: stop ===== //
        send_uart_byte("r");
        #(WAIT_COUNT+WAIT_COUNT/2);

        // ===== 4. 'r' 전송: 다시 up count start ===== //
        send_uart_byte("r");
        #(WAIT_COUNT+WAIT_COUNT/5);

        // ===== 5. 'c' 전송 ===== //
        send_uart_byte("c");
        #(WAIT_COUNT);

        // ===== 6. 's' 전송 ===== //
        send_uart_byte("s");
        #(WAIT_COUNT);
        #50_000_000

        $finish;
    end


    task send_uart_byte (input [7:0] data);
        integer i;
        begin
            //start bit
            RsRx=0;
            #(UART_BIT_PERIOD);

            //data bits
            for(i=0; i<8; i++) begin
                RsRx = data[i]; //LSB First
                #(UART_BIT_PERIOD);
            end

            //stop bit
            RsRx=1;
            #(UART_BIT_PERIOD);

            #1_000_000;
        end
    endtask //send_uart_byte

endmodule