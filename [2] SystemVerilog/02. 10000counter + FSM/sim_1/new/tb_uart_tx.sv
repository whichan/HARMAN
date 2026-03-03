`timescale 1ns / 1ps

module tb_uart_tx();

    //test env parameter
    parameter CLK_PERIOD = 10;
    parameter UART_BIT_PERIOD = 10416*CLK_PERIOD; // 1/9600kHz = 104_166
    

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
        
        //stimulus generation
        stimulus_data = $random(256)%256;
        tx_start = 1'b1;
        
        #10

        
        
    end
endmodule