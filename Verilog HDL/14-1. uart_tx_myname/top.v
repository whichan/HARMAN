`timescale 1ns / 1ps


module top(
    input clk,
    input reset,
    input RsRx,
    input sw,
    input btn,
    output [15:0] led,
    output RsTx,
    output [3:0] an,
    output [7:0] seg
    );

    wire [7:0] w_rx_data;
    wire w_rx_done;

    uart_controller u_uart_controller(
        .clk(clk),
        .reset(reset),
        .send_data(),
        .rx(RsRx),
        .rx_data(w_rx_data),
        .rx_done(w_rx_done),
        .tx(RsTx)
    );

    /*debouncer u_debouncer(

    );

    command_controller u_command_controller(

    );

    fnd_controller u_fnd_controller(
        
    );*/
    
endmodule
