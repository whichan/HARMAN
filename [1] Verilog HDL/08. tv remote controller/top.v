`timescale 1ns / 1ps


module top(
    input [2:0] btn,
    input clk,
    input reset,
    output reg [3:0] ch
    );

btn_debouncer u_btn_debouncer (

    );

remote_controller u_remote_controller (

    );


    
endmodule
