`timescale 1ns / 1ps

module fifo(
    input clk,
    input reset,
    input wr, //push
    input rd, //pop
    input [7:0] wdata, //들어올 데이터
    output [7:0] rdata, //나갈 데이터
    output full,
    output empty
    );

    wire [1:0] w_wptr, w_rptr;

    register_file u_register_file(
        .clk(clk),
        .waddr(w_wptr),
        .wdata(wdata),
        .raddr(w_rptr),
        .wr(~full&wr), //full이 아니면서 wr=1일 때만 write
        .rdata(rdata)
    );

    fifo_control_unit u_fifo_control_unit(
        .clk(clk),
        .reset(reset),
        .wr(wr),
        .rd(rd),
        .w_ptr(w_wptr),
        .r_ptr(w_rptr),
        .full(full),
        .empty(empty)
    );

endmodule

module register_file(
    input clk,
    input [1:0] waddr, //4byte buffer이므로 2개의 주소 필요
    input [7:0] wdata, //data는 8bit
    input [1:0] raddr,
    input wr,
    output [7:0] rdata
);

    logic [7:0] register_file [0:3]; //data 8bit, size 4byte

    always @(posedge clk) begin
        //write, push
        if(wr) begin
            //clk이 posedge 일 때 wr신호가 1이면 데이터를 레지스터에 저장
            register_file[waddr] <= wdata; 
        end
    end

    //읽기동작(조합논리)
    //clk을 기다리지 않고 주소(raddr)가 바뀌면 즉시 데이터가 나가도록 설계
    //read는 조금 더 반응을 빨리 하기 위해 순차로 안하고 조합논리로 짬
    assign rdata = register_file[raddr];

endmodule

module fifo_control_unit(
    input clk,
    input reset,
    input wr,
    input rd,
    output [1:0] w_ptr,
    output [1:0] r_ptr,
    output full,
    output empty
);

    logic c_full, n_full, c_empty, n_empty;
    logic [1:0] c_wptr, n_wptr, c_rptr, n_rptr;

    assign full = c_full; //항상 출력은 current로
    assign empty = c_empty;
    assign w_ptr = c_wptr;
    assign r_ptr = c_rptr;

    //output state
    always_ff @(posedge clk or posedge reset) begin
        if(reset) begin
            c_full <= 1'b0;
            c_empty <= 1'b1;
            c_wptr <= 2'b00;
            c_rptr <= 2'b00;
        end else begin
            c_full <= n_full;
            c_empty <= n_empty;
            c_wptr <= n_wptr;
            c_rptr <= n_rptr;
        end
    end

    always_comb begin

        n_full = c_full;
        n_empty = c_empty;
        n_wptr = c_wptr;
        n_rptr = c_rptr;

        case({wr,rd}) //state wr,rd or push,pop
            2'b00: begin

            end
            
            2'b01: begin
                //POP: 읽기 요청
                n_full = 1'b0; //하나 읽었으니 절대 Full일 수가 없음
                if(!empty) begin //empty가 아닐 때만 읽어야 함
                    n_rptr = c_rptr + 1; //읽기포인터 한칸 전진

                    //Empty 판단 로직
                    //지금 쓰기 포인터 위치(c_wptr)와 방금 이동한 읽기 포인터(n_rptr) 가 같으면
                    //다 읽어서 비었다는 뜻
                    if(c_wptr == n_rptr) begin
                        n_empty = 1'b1; //다 읽었으므로 empty=1
                    end
                end
            end


            2'b10: begin
                    n_empty = 1'b0; //하나 썼으니 절대 Empty 일 수가 없음
                //PUSH: 쓰기 요청
                if(!c_full) begin //꽉 차지 않았을 때만 써야 함(onverflow 방지)
                        n_wptr = c_wptr + 1; //쓰기 포인터 한칸 전진

                    // Full 판단로직
                    // 지금 읽기 포인터(c_rptr)가 방금 이동한 쓰기 포인터(n_wptr)가 같아졌다면
                    // 쓰는 포인터가 한 바퀴 돌아 읽기 포인터 뒤를 잡았다는 뜻 -> 꽉 참
                    if(c_rptr == n_wptr) begin
                        n_full = 1'b1;
                    end
                end
            end

            2'b11: begin
                //PUSH, POP
                if (c_empty == 1) begin
                    //only push
                    n_empty = 1'b0;
                    n_wptr = c_wptr + 1;
                end else if (c_full == 1) begin
                    //only pop
                    n_full = 1'b0;
                    n_rptr = c_rptr + 1;
                end else begin
                    //일반적인 상황: 하나 넣고 하나 뺌
                    //포인터 둘 다 이동
                    //write, read ptr inc..
                    n_wptr = c_wptr + 1;
                    n_rptr = c_rptr + 1;
                end
            end
        endcase
    end
endmodule