`timescale 1ns / 1ps

module tb_uart_tx();

    //test env parameter
    parameter CLK_PERIOD = 10; //100MHz
    parameter UART_BIT_PERIOD = 10416*CLK_PERIOD; // 1/9600kHz = 104_166
    //9600bps에서 1비트 폭은 104.16us임

    

    // stimulus variable
    bit clk, reset, tx_start;
    bit [7:0] tx_data, stimulus_data, compare_data;
    

    //output variable
    logic tx, tx_busy, tx_done;

    uart_tx tb_u_uart_tx(
        .clk(clk),
        .reset(reset),
        .tx_data(tx_data),
        .tx_start(tx_start),
        .tx(tx),
        .tx_busy(tx_busy),
        .tx_done(tx_done)
    );
    

    initial begin
        clk=0;
        forever #5 clk=~clk;
    end

    initial begin
        reset = 1;
        tx_start = 0;
        
        #10
        reset=0;
        //step1. 고정데이터 0x30 테스트   
        #10
        stimulus_data = 8'h30; //test로 stimulus data를 고정값으로 넣음
        tx_data = stimulus_data;
        tx_start = 1'b1;
        #10
        tx_start = 1'b0; //1. 전송 명령
        #10; //1tick
        
        //wait for transmitt, receive
        uart_receive_t(); //2. 수신 태스트 호출 (데이터가 날아오는 동안 여기서 대기)
        
        compare_t(); //3. 데이터 검증
        //stimulus generation
        //stimulus_data = $random(256)%256;
        
        //랜덤 테스트로 넘어가기 전에 내가 아는 확실한 값으로 회로가 살아있는지 확인

        for (int i=0; i<256; i++) begin

            wait(!tx_busy); //wait tx_busy low(이전 전송이 끝날 때까지 대기)
            //tx_busy low 될 때까지 기다림.
            //tx_start 받을 수 있을 때까지 대기 (uart_tx)
            #10 //약간 대기

            stimulus_generate(); //랜덤 데이터 생성
            tx_data = stimulus_data;
            tx_start = 1'b1;
            #10
            tx_start = 0;

            uart_receive_t(); //수신
            compare_t(); //비교
        end

        #1000;
        $stop;
    end

    task stimulus_generate();
        stimulus_data = $random()%256;
    endtask

    task uart_receive_t ();
        wait(!tx); //wait tx start bit low
        #(UART_BIT_PERIOD/2);
        if (tx) begin
            $display("%t: TX start bit Fail", $time);
            return;
        end

        for(int i=0; i<8; i++) begin
            #(UART_BIT_PERIOD);
            compare_data[i] = tx;
        end //bit 0~7까지 gathering
        
        //stop bit
        #(UART_BIT_PERIOD);
        if (!tx) begin
            $display("%t: TX Stop bit Fail", $time);
        end

        #(UART_BIT_PERIOD/2);
    endtask //uart_receive

    task compare_t ();
        if(compare_data == stimulus_data) begin //성공 메시지
            $display("%t: PASS tx data = 0x%x",$time, compare_data);
        end else begin //실패 메시지
            $display("%t: Fail tx data = 0x%x, compare_data=0x%x",$time, stimulus_data, compare_data);
        end
    endtask //
endmodule