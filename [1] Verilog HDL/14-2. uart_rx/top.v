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
    
    reg [15:0] r_led;

    always @(posedge clk or posedge reset) begin
        if(reset) begin
            r_led <= 16'h0000;
        end else begin
            if(w_rx_done) begin
                case(w_rx_data)
                    8'h30: r_led[0] <= ~r_led[0]; //ASCII code '0'
                    8'h31: r_led[1] <= ~r_led[1]; //ASCII code '1'
                    default: begin end //0,1 외 다른 값이 오면 아무것도 안함
                endcase
            end
        end
    end

    assign led = r_led;

endmodule
