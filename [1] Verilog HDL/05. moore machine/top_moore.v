`timescale 1ns / 1ps

module moore(
    input clk,
    input rst_n,
    input go,
    input ws,
    output reg rd,
    output reg ds
    );

    reg [1:0] state, state_next;

    parameter IDLE = 2'b00;
    parameter READ = 2'b01;
    parameter DLY = 2'b10;
    parameter DONE = 2'b11;



    always @(posedge clk or negedge rst_n) begin
        if(!rst_n)
        state <= IDLE;
        else
        state <= state_next;
    end
    

    //-----[always block 2]. 현재 상태와 현재 입력에 대해 다음 상태 결정-----//
    always @(*) begin
        state_next=IDLE;

        case(state)
            IDLE: begin
                if(go)
                    state_next = READ;
                else
                    state_next = IDLE;
                end
            READ: begin
                if(go)
                    state_next = DLY;
                else
                    state_next = IDLE;
                end

            DLY: begin
                if(ws)
                    state_next = READ;
                else
                    state_next = DONE;
            end
            DONE: begin
                if(go)
                    state_next = IDLE;
                else
                    state_next = DONE;
            end

            default:
                state_next = IDLE;
        endcase
    end
    
    //-----[always block 3]. 현재 상태에 따라 출력 결정-----//
    always @(*) begin
        rd=1'b0;
        ds=1'b0;

        case(state)
            READ: begin
                rd=1'b1;
            end

            DONE: begin
                ds=1'b1;
            end
        endcase
    end
endmodule
