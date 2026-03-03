`timescale 1ns / 1ps

module command_controller(
    input clk,
    input reset,
    input mode,
    input run_stop,
    input clear,
    
    output logic o_mode,
    output logic o_run_stop,
    output logic o_clear
    );

    typedef enum logic [1:0] {S_IDLE, S_UP, S_STOP, S_DOWN} STATE_T;
    
    STATE_T state, next_state;
    
    logic c_mode, n_mode;
    logic c_run_stop, n_run_stop;
    logic c_clear, n_clear;
    
    assign o_mode = c_mode;
    assign o_run_stop = c_run_stop;
    assign o_clear = c_clear;

    always_ff @( posedge clk or posedge reset ) begin
        if(reset) begin
            state <= S_IDLE;
            c_mode <= 0;
            c_run_stop <= 0;
            c_clear <= 1;
        end else begin
            state <= next_state;
            c_mode <= n_mode;
            c_run_stop <= n_run_stop;
            c_clear <= n_clear;
        end
    end

    always_comb begin
        next_state  = state;
        n_mode = c_mode;
        n_run_stop = c_run_stop;
        n_clear = c_clear;
        
        case(state)
            S_IDLE: begin
                n_mode = 0;
                n_run_stop = 0;
                n_clear = 1;
                if(clear) next_state = S_IDLE;
                else if(run_stop && !mode) next_state = S_UP;
                else if(run_stop && mode) next_state = S_DOWN;
                else next_state = S_IDLE;
            end

            S_UP: begin
                n_mode = 0;
                n_run_stop = 1;
                n_clear = 0;
                if(clear) next_state = S_IDLE;
                else if(run_stop && mode) next_state = S_DOWN;
                else if(!run_stop) next_state = S_STOP;
                else next_state = S_UP;
            end

            S_DOWN: begin
                n_mode = 1;
                n_run_stop = 1;
                n_clear = 0;
                if(clear) next_state = S_IDLE;
                else if(!mode && run_stop) next_state = S_UP;
                else if(!run_stop) next_state = S_STOP;
                else next_state = S_DOWN;
            end

            S_STOP: begin
                n_mode = c_mode; //기존 모드 유지: up하다 멈췄는지 down하다 멈췄는지?
                n_run_stop = 0;
                n_clear = 0;
                if(clear) next_state = S_IDLE;
                else if(run_stop && !mode) next_state = S_UP;
                else if(run_stop && mode) next_state = S_DOWN;
                else next_state = S_STOP;
            end

            default: next_state = S_IDLE;
        endcase
        
    end

endmodule
