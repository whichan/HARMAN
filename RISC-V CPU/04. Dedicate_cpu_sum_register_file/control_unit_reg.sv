`timescale 1ns / 1ps

module control_unit_reg(
    input              clk,
    input              reset,
    input              ale10,
    output logic       rf_src_sel,
    output logic [1:0] raddr1,
    output logic [1:0] raddr2,
    output logic [1:0] waddr,
    output logic       we,
    output logic       out_load
    );

    typedef enum logic [2:0] { S0, S1, S2, S3, S4, S5, S6, S7 } state_t;
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
        rf_src_sel = 0; raddr1 = 0; raddr2 = 0; waddr = 0; we = 0; out_load = 0;

        case(state)
            S0: begin
                rf_src_sel = 0;
                waddr = 3;
                we = 1;
                out_load = 0;
                next_state = S1;
            end

            S1: begin
                rf_src_sel = 1;
                raddr1 = 0;
                raddr2 = 0;
                waddr = 1;
                we = 1;
                out_load = 0;
                next_state = S2;
            end

            S2: begin
                rf_src_sel = 1;
                raddr1 = 0;
                raddr2 = 0;
                waddr = 2;
                we = 1;
                out_load = 0;
                next_state = S3;
            end

            S3: begin
                raddr1 = 1;
                we = 0;
                out_load = 0;
                if(ale10) next_state = S4;
                else next_state = S7;
            end

            S4: begin
                rf_src_sel = 1;
                raddr1 = 1;
                raddr2 = 2;
                waddr = 2;
                we = 1;
                out_load = 0;
                next_state = S5;
            end

            S5: begin
                rf_src_sel = 1;
                raddr1 = 1;
                raddr2 = 3;
                waddr = 1;
                we = 1;
                out_load = 0;
                next_state = S6;
            end

            S6: begin
                rf_src_sel = 1;
                raddr2 = 2;
                we = 0;
                out_load = 1;
                next_state = S3;
            end

            S7: begin
                we = 0;
                out_load = 0;
                next_state = S7;
            end

            default: next_state = S0;
        endcase
    end
endmodule