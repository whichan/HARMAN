`timescale 1ns / 1ps

module mealy(
    input clk,
    input rstn,
    input done, //1bit input
    output reg ack //1bit output
    );

    //1. 상태 정의
    parameter READY = 2'b00;
    parameter TRANS = 2'b01;
    parameter WRITE = 2'b10;
    parameter READ = 2'b11;
    
    //2. 상태 레지스터
    reg [1:0] state, state_next; //상태가 4개이므로 2비트로 선언

    //-----[always block 1]-----//
    always @(posedge clk or negedge rstn) begin
        if(!rstn) begin //rstn=0일 때
            state <= READY;
        end else begin
            state <= state_next;
        end
    end //rstn이 0이 되면 READY로 초기화, 그게 아니라면 다음상태를 받음

    //-----[Always block 2](현재 상태와 입력에 따라 다음 상태 결정)-----//
    always @(*) begin
        state_next = READY;

        case (state)

            READY: begin //done=1이면
                if(done)
                    state_next = TRANS;
                else
                    state_next = READY;
            end

            TRANS: begin
                if(done)
                    state_next = TRANS;
                else
                    state_next = WRITE;
            end

            WRITE: begin
                if(done)
                    state_next = READ;
                else
                    state_next = WRITE;
            end

            READ: begin
                if(done)
                    state_next = READY;
                else
                    state_next = READ;
            end
            
            default: 
                state_next = READY;
        endcase
    end
    

    //-----[Always block 2](현재 상태와 현재 입력에 따라 출력(ack) 결정)-----//
    always @(*) begin
        ack = 1'b0; //기본 출력은 0으로 
    
        case(state)
            READY: begin
                if(done) //READY 상태에서 done=1이면 ack=1
                ack=1'b1;
                else //READY 상태에서 done=1이면 ack=0
                ack=1'b0;
            end

            TRANS: begin
                if(done)
                ack=1'b0;
                else
                ack=1'b0;           
            end

            WRITE: begin
                if(done)
                ack=1'b1;
                else
                ack=1'b0;
            end

            READ: begin
                if(done)
                ack=1'b0;
                else
                ack=1'b0;
            end

            default: ack=1'b0;
        endcase
    end
endmodule
