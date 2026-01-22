`timescale 1ns / 1ps

module tb_uart_controller();

    reg clk;
    reg reset;
    reg [7:0] rx_data;
    reg rx_done;

    wire uart_run_stop;
    wire uart_mode;
    wire uart_clear;
    wire uart_status;

    wire [13:0] set_value;
    wire set_en;

    localparam ASCII_CR = 8'h0D; //Enter

    uart_controller u_uart_controller(
        .clk(clk),
        .reset(reset),
        .rx_data(rx_data),
        .rx_done(rx_done),
        .uart_run_stop(uart_run_stop),
        .uart_mode(uart_mode),
        .uart_clear(uart_clear),
        .uart_status(uart_status),
        
        .set_value(set_value), //0~9999
        .set_en(set_en) //set 명령어 완료 puls
    );

    task send_rx(input [7:0] data);
        begin
            @(posedge clk);
            rx_data = data;
            rx_done = 1; //1클럭동안 high
            @(posedge clk);
            rx_done = 0;
            rx_data = 0;
            #20;
        end
    endtask

    initial begin
        clk=0;
        forever #5 clk=~clk;
    end

    initial begin
        #0;
        reset = 1;
        rx_data = 8'h0;
        rx_done = 0;
        #20;
        reset = 0;
        #10;

        $display("===== Scenario 1. toggle check (r,m) =====");
        
        send_rx("r");
        #10;
        if(uart_run_stop==1) $display("[PASS] run/stop toggle");
        else $display("[FAIL] fail run/stop toggle");
        

        send_rx("R");
        #10;
        if(uart_run_stop==0) $display("[PASS] run/stop toggle");
        else $display("[FAIL] fail run/stop toggle");

        
        send_rx("m");
        #10;
        if(uart_mode==1) $display("[PASS] mode toggle 0->1");
        else $display("[FAIL]");

        send_rx("M");
        #10;
        if(uart_mode==0) $display("[PASS] mode toggle 1->0");
        else $display("[FAIL]");

        $display("\n===== Scenario 2. pulse check (c,s) =====");

        send_rx("c");
        if(uart_clear==1) $display("[PASS] clear pulse");
        else $display("[FAIL]");
        #10;

        send_rx("s");
        if(uart_clear==1) $display("[PASS] status pulse");
        else $display("[FAIL]");
        #10;

        $display("\n===== Scenario 3. /set xxxx =====");

        //set 1234
        send_rx("/"); send_rx("s"); send_rx("e"); send_rx("t"); 
        send_rx(" "); 
        send_rx("1"); send_rx("2"); send_rx("3"); send_rx("4");
        send_rx(ASCII_CR);

        // @(posedge clk);
        // wait(set_en==1);

        if(set_value == 1234) $display("[PASS] set value");
        else $display("[FAIL]");

        $display("\n===== Scenario 4. /set error =====");
        //sei 입력
        send_rx("/"); send_rx("s"); send_rx("e"); send_rx("i"); 
        send_rx(" "); 
        send_rx("1"); send_rx("2"); send_rx("3"); send_rx("4");
        send_rx(ASCII_CR);

        // @(posedge clk);
        // wait(set_en==1);

        //  /se /을 입력했을 때 CHECK_S 상태로 넘어가는지?
        send_rx("/"); send_rx("s"); send_rx("e"); send_rx("/"); 
        send_rx(" "); 
        send_rx("1"); send_rx("2"); send_rx("3"); send_rx("4");
        send_rx(ASCII_CR);
        
        // @(posedge clk);
        // wait(set_en==1);

        send_rx("/"); send_rx("s"); send_rx("e"); send_rx("c"); 
        send_rx(" "); 
        send_rx("1"); send_rx("2"); send_rx("3"); send_rx("4");
        send_rx(ASCII_CR);
        // @(posedge clk);
        // wait(set_en==1);

        send_rx("/"); send_rx("s"); send_rx("e"); send_rx("m"); 
        send_rx(" "); 
        send_rx("1"); send_rx("2"); send_rx("3"); send_rx("4");
        send_rx(ASCII_CR);
        
        #100;
        $stop;
    end
endmodule
