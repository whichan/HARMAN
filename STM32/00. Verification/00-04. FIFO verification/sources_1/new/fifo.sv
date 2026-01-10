`timescale 1ns / 1ps

module fifo(
    input clk,
    input reset,
    input [7:0] wdata,
    output [7:0] rdata,
    input wr,
    input rd,
    
    output full,
    output empty
);

    wire [3:0] w_wptr, w_rptr;

    reg_file u_reg_file(
        .clk(clk),
        .wdata(wdata),
        .waddr(w_wptr),
        .raddr(w_rptr),
        .wr(wr&~full),
        .rdata(rdata)
    );

    control_unit u_control_unit(
        .clk(clk),
        .reset(reset),
        .rd(rd),
        .wr(wr),
        .wptr(w_wptr),
        .rptr(w_rptr),
        .full(full),
        .empty(empty) 
    );

endmodule

module reg_file(
    input clk,
    input [7:0] wdata,
    input [3:0] waddr,
    input [3:0] raddr,
    input wr,
    output [7:0] rdata
);

    logic [7:0] register_file [0:15]; //8비트짜리 16바이트

    always @(posedge clk) begin
        if(wr) begin
            register_file[waddr] <= wdata;
        end
    end

    assign rdata = register_file[raddr];

endmodule

module control_unit(
    input clk,
    input reset,
    input rd,
    output wr,
    
    output [3:0] wptr,
    output [3:0] rptr,

    output full,
    output empty 
);

    logic c_full, n_full, c_empty, n_empty;
    logic [3:0] c_wptr, n_wptr, c_rptr, n_rptr;

    assign full = c_full;
    assign empty = c_empty;
    assign wptr = c_wptr;
    assign rptr = c_rptr;

    always_ff @( posedge clk or posedge reset ) begin
        if(reset) begin
            c_full <= 1'b0;
            c_empty <= 1'b1; //맨처음엔 empty인 상태
            c_wptr <= 4'b0;
            c_rptr <= 4'b0;
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
        
        case({wr,rd})
            2'b00: begin
            end

            2'b01: begin //read(pop)
                n_full = 1'b0; //read했기 때문에 full아님
                if(!empty) begin
                    n_rptr = c_rptr + 1;
                    if(n_rptr == c_wptr) begin
                        //empty 판단 로직
                        n_empty = 1'b1;
                    end
                end
            end

            2'b10: begin //write(push)
                n_empty = 1'b0; //write 했기 때문에 절대 empty가 아님
                if(!full) begin
                    n_wptr = c_wptr + 1;
                    if(n_wptr == c_rptr) begin
                        //full 판단 로직
                        n_full = 1'b1;
                    end
                end
            end

            2'b11: begin
                if(c_empty == 1'b1) begin
                    //empty=1이므로 push만
                    n_empty = 1'b0;
                    n_wptr = c_wptr + 1;
                end else if(c_full == 1'b1) begin
                    //full=1이므로 pop만
                    n_full = 1'b0;
                    n_rptr = c_rptr + 1;
                end else begin
                    //push, pop
                    n_wptr = c_wptr + 1;
                    n_rptr = c_rptr + 1;
                end
            end
        endcase
    end
endmodule