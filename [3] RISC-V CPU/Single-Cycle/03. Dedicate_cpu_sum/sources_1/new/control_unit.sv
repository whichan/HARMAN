`timescale 1ns / 1ps

module control_unit(
    input        clk,
    input        reset,
    input        ale10,

    output logic a_src_sel,
    output logic sum_src_sel,
    output logic a_load,
    output logic sum_load,
    output logic alu_src_sel,
    output logic out_load
    );

    typedef enum logic [2:0] { S0, S1, S2, S3, S4, S5 } state_t;
    state_t state, next_state;
    

    always_ff @( posedge clk or posedge reset ) begin
        if(reset) begin
            state <= S0;
        end else begin
            state <= next_state;
        end
    end

    always_comb begin
        next_state = state;
        a_src_sel = 0;
        sum_src_sel = 0;
        a_load = 0;
        sum_load = 0;
        alu_src_sel = 0;
        out_load = 0;

        case(state)
            S0: begin
                a_src_sel = 0;
                sum_src_sel = 0;
                a_load = 1;
                sum_load = 1;
                out_load = 0;
                next_state = S1;
            end

            S1: begin
                //a<10
                a_load = 0;
                sum_load = 0;
                out_load = 0;
                if(ale10) next_state = S2;
                else next_state = S5;
            end

            S2: begin    
                sum_src_sel = 1;
                a_load = 0;
                sum_load = 1;
                alu_src_sel = 1;
                out_load = 0;
                next_state = S3;
            end
            S3: begin
                a_src_sel = 1;
                a_load = 1;
                sum_load = 0;
                alu_src_sel = 0;
                out_load = 0;
                next_state = S4;
            end
            S4: begin
                a_load = 0;
                sum_load = 0;
                out_load = 1;
                next_state = S1;
            end
            S5: begin
                a_load = 0;
                sum_load = 0;
                out_load = 1;
                next_state = S5;
            end
        endcase 
    end 
endmodule