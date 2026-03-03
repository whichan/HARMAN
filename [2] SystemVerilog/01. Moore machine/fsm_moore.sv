`timescale 1ns / 1ps
`define MEALY_FSM

module fsm_moore(
    input logic clk,
    input logic reset,
    input logic in,
    output logic out
    );

    //state
    typedef enum logic [2:0] {IDLE, S_A, S_B, S_C, S_D} STATE_E;

    STATE_E c_state, n_state;
    logic c_out, n_out;

    assign out = c_out; //현재의 출력을 넘겨줌

    //state register
    always_ff @( posedge clk or posedge reset ) begin
        if(reset) begin
            c_state <= IDLE;
            c_out <= 1'b0;
        end else begin
            c_state <= n_state; //현재 상태는 다음 상태에서 받아옴
            c_out <= n_out; //현재 출력은 다음 출력에서 받아옴
        end
    end

    //next, output logic
    //moore machine은 현재 상태에 의해 출력이 결정되므로
    always_comb begin
        n_state = c_state; //이거 안하면 Latch 생김
        n_out = c_out; //이거 안하면 Latch 생김
        
        case(c_state)
        
        IDLE: begin
            //여기에 출력 적으면 moore
            n_out = 1'b0; //moore output, current state
            if(in) n_state = S_A;
            //여기에 출력 적으면 mealy
            else n_state = IDLE;
        end

        S_A: begin
            n_out = 1'b0;
            if(in) n_state = S_B;
            else n_state = IDLE;
        end

        S_B: begin
            n_out = 1'b0;
            if(in) n_state = S_C;
            else n_state = IDLE;
        end

        S_C: begin
            
            n_out = 1'b0;
            if(in) n_state = S_D;
            else n_state = IDLE;
        end
        

        S_D: begin
            n_out = 1'b1;
            if(in) n_state = S_A;
            else n_state = IDLE;
        end

        default: n_state = IDLE;
        endcase
    end

endmodule
