`timescale 1ns / 1ps
module tb_top();
    
    logic clk;
    logic reset;
    logic clear;
    logic run_stop;
    logic mode;
    logic [7:0] fnd_data;
    logic [3:0] fnd_com;


    top u_top(
        .clk(clk),
        .reset(reset),
        .clear(clear),
        .run_stop(run_stop),
        .mode(mode),
        .fnd_data(fnd_data),
        .fnd_com(fnd_com)
    );

    localparam ONE_TICK_TIME = 100000000;

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    initial begin
        
        // 초기화
        reset = 1;
        clear = 1;
        run_stop = 0;
        mode = 0;
        
        #200;
        reset = 0;
        clear = 0;

  
        // Case 1: Up Count 시작 (약 0.3초간 동작)
        mode = 0;     // Up
        run_stop = 1; // Run
        
        // 3번 카운팅할 때까지 대기 (0 -> 1 -> 2 -> 3)
        // 0.1초 * 3.5회 = 0.35초 대기
        #(ONE_TICK_TIME * 3.5); 
        
    


        // Case 2: Down Count 전환 (약 0.3초간 동작)
        mode = 1; // Down (3 -> 2 -> 1 -> 0)
        
        // 3번 카운팅할 때까지 대기
        #(ONE_TICK_TIME * 3.5);



        // Case 3: Stop 확인
        run_stop = 0;
        #(ONE_TICK_TIME * 1); // 1 tick 시간 동안 멈춰있는지 확인

        run_stop = 1;
        #(ONE_TICK_TIME * 2);
        

        clear = 1;
        #10
        
        run_stop = 1;
        #(ONE_TICK_TIME *3);

        $finish;
    end

endmodule