`timescale 1ns / 1ps

module fsm(
    input clk,
    input reset,
    input btn,
    output led
    );


    typedef enum logic [2:0] {S_0, S_1, S_11, S_111, S_1111 } STATE_T;
    STATE_T state, next_state;
    logic c_led, n_led;
    
    always_ff @( posedge clk or posedge reset ) begin
        if(reset) begin
            state <= S_0;
            c_led <= 1'b0;
        end else begin
            state <= next_state;
            c_led <= n_led;
        end
    end

    always_comb begin
        next_state = state;

        case(state)
            S_0: begin //1 detect X
                if(btn) next_state = S_1;
                else if(btn==0) next_state = S_0;
            end

            S_1: begin //1 detect
                if(btn) next_state = S_11;
                else if(btn==0) next_state = S_0;
            end

            S_11: begin //11 detect
                if(btn) next_state = S_111;
                else if(btn==0) next_state = S_0;
            end

            S_111: begin //111 detect
                if(btn) next_state = S_1111;
                else if(btn==0) next_state = S_0;
            end

            S_1111: begin //1111 detect
                if(btn) next_state = S_1;
                else if(btn==0) next_state = S_0;
            end

            default: next_state = S_0;
            
        endcase
        
    end

    always_comb begin

        case(state)
            S_0: n_led = 1'b0;
            S_1: n_led = 1'b0;
            S_11: n_led = 1'b0;
            S_111: n_led = 1'b0;
            S_1111:n_led = 1'b1;
            default: n_led = 1'b0;
        endcase
    end

    assign led = c_led;
    
endmodule
