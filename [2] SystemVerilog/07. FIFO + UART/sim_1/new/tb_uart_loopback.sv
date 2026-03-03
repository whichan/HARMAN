`timescale 1ns / 1ps

    module tb_uart_loopback();

    // 1. 신호 선언
    reg clk;
    reg reset;
    reg RsRx;    // PC -> FPGA
    wire RsTx;   // FPGA -> PC

    localparam BIT_TIME = 104167; 

    // 3. 모듈 연결
    uart_loopback u_uart_loopback (
        .clk(clk),
        .reset(reset),
        .RsTx(RsTx),
        .RsRx(RsRx)
    );

    task send_byte;
        input [7:0] data;
        integer i;
        begin
            // 1. Start Bit (Low)
            RsRx = 0;
            #(BIT_TIME); 

            // 2. Data Bits (8bit, LSB First)
            for (i=0; i<8; i=i+1) begin
                RsRx = data[i];
                #(BIT_TIME);
            end

            // 3. Stop Bit (High)
            RsRx = 1;
            #(BIT_TIME);
        end
    endtask

    // 4. 클럭 생성 (100MHz)
    initial begin
        clk=0;
        forever  #5 clk=~clk;
    end

    /*initial begin
        #0;
        reset = 1;
        RsRx = 1; // Idle 상태 (High)
        
        #10;       
        reset = 0;  // 리셋 해제      

        // Start Bit (0)
        RsRx = 0; #(BIT_TIME);

        // Data Bits (0x55: 1-0-1-0-1-0-1-0)
        RsRx = 1; #(BIT_TIME); 
        RsRx = 0; #(BIT_TIME); 
        RsRx = 1; #(BIT_TIME); 
        RsRx = 0; #(BIT_TIME); 
        RsRx = 1; #(BIT_TIME); 
        RsRx = 0; #(BIT_TIME); 
        RsRx = 1; #(BIT_TIME); 
        RsRx = 0; #(BIT_TIME); 

        // Stop Bit (1)
        RsRx = 1; #(BIT_TIME);
        
        // 9600bps는 느리니까 넉넉하게 기다려야 함
        #(BIT_TIME * 15); 

        $stop;
    end*/

    initial begin
        #0;
        reset = 1;
        RsRx = 1; // Idle
        
        #10;
        reset = 0;
        #100;


        // [1] 공백 (Space)
        send_byte(" "); 
        #(BIT_TIME * 2); // 글자 사이에 약간의 여유(Inter-byte delay)를 줌

        // [2] /
        send_byte("/");
        #(BIT_TIME * 2);

        // [3] s
        send_byte("s");
        #(BIT_TIME * 2);

        // [4] e
        send_byte("e");
        #(BIT_TIME * 2);

        // [5] t
        send_byte("t");
        #(BIT_TIME * 2);

        // [6] 공백
        send_byte(" ");
        #(BIT_TIME * 2);

        // [7] 1
        send_byte("1");
        #(BIT_TIME * 2);

        // [8] 2
        send_byte("2");
        #(BIT_TIME * 2);

        // [9] 3
        send_byte("3");
        #(BIT_TIME * 2);

        // [10] 4
        send_byte("4");
        #(BIT_TIME * 2);
        
        // 모든 데이터가 돌아오길 기다림 (넉넉하게)
        #(BIT_TIME * 20);
        $stop;
    end

endmodule