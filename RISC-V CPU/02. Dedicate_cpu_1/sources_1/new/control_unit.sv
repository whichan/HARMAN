`timescale 1ns / 1ps

module control_unit(
    input clk,
    input reset,
    output src_sel,
    output a_load,
    output out_sel
    );

    typedef enum { S0, S1, S2 } state_t;
    state_t state, next_state;

    logic current_src_sel, next_src_sel;
    logic current_a_load, next_a_load;
    logic current_out_sel, next_out_sel;

    assign src_sel = current_src_sel;
    assign a_load = current_a_load;
    assign out_sel = current_out_sel;

    // register SL
    always_ff @( posedge clk or posedge reset ) begin
        if(reset) begin
            state           <= S0;
            current_src_sel <= 0;
            current_a_load <= 0;
            current_out_sel <= 0;
        end else begin
            state <= next_state;
            current_src_sel <= next_src_sel;
            current_a_load <= next_a_load;
            current_out_sel <= next_out_sel;
        end
    end

    // next CL
    always_comb begin
        next_state = state;
        next_src_sel = current_src_sel;
        next_a_load = current_a_load;
        next_out_sel = current_out_sel;
        
        case(state)
            S0: begin
                next_src_sel = 0;
                next_a_load = 1;
                next_out_sel = 0;
                next_state = S1;
            end

            S1: begin
                next_src_sel = 1;
                next_a_load = 1;
                next_out_sel = 0;
                next_state = S2;
            end

            S2: begin
                // nothing
                next_src_sel = 0;
                next_a_load = 0;
                next_out_sel = 1;
            end

            default: next_state = S0;
        endcase
    end

endmodule