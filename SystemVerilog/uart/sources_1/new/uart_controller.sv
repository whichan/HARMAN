`timescale 1ns / 1ps

module uart_controller(
    input clk,
    input reset,
    input [7:0] rx_data,
    input rx_done,
    
    output logic uart_run_stop,
    output logic uart_clear,
    output logic uart_mode
    );
    
    parameter ASCII_r = 8'h72;
    parameter ASCII_R = 8'h52;
    parameter ASCII_m = 8'h6D;
    parameter ASCII_M = 8'h4D;
    parameter ASCII_c = 8'h63;
    parameter ASCII_C = 8'h43;

    always_ff @( posedge clk or posedge reset ) begin
        if(reset) begin
            uart_run_stop <= 0;
        end else begin
            if(rx_done) begin
                if(rx_data == ASCII_R || rx_data == ASCII_r) begin
                    uart_run_stop <= ~uart_run_stop;
                end
            end
        end
    end

    always_ff @( posedge clk or posedge reset ) begin
        if(reset) begin
            uart_clear <= 0;
        end else begin
            if(rx_done) begin
                if(rx_data == ASCII_C || rx_data == ASCII_c) begin
                    uart_clear <= ~uart_clear;
                end
            end
        end
    end

    always_ff @( posedge clk or posedge reset ) begin
        if(reset) begin
            uart_mode <= 0;
        end else begin
            if(rx_done) begin
                if(rx_data == ASCII_M || rx_data == ASCII_m) begin
                    uart_mode <= ~uart_mode;
                end
            end
        end
    end

endmodule
