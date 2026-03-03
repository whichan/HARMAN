`timescale 1ns / 1ps

module FIFO_TX (

    input        clk,
    input        reset,
    input        wr,
    input        rd,
    input  [7:0] wdata,
    output [7:0] rdata,
    output       full,
    output       empty
);

  logic [1:0] w_wptr, w_rptr;  //1:0

  register_file u_register_file (
      .clk  (clk),
      .waddr(w_wptr),
      .wdata(wdata),
      .raddr(w_rptr),
      .wr   (wr & ~full),
      .rd   (rd & ~empty),
      .rdata(rdata)
  );

  fifo_control_unit u_fifo_control_unit (
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

/* 
module register_file (
    input        clk,
    input  [1:0] waddr, //1:0
    input  [7:0] wdata,
    input  [1:0] raddr, //1:0
    input        wr,
    input        rd,
    output reg [7:0] rdata

);
    //data 8bit, size 4byte
    logic [7:0] register_file[0:15]; //15

    always_ff @(posedge clk) begin
        // write, push
        if (wr) register_file[waddr] <= wdata;
    end

    // read, pop combinational logic
     assign rdata = register_file[raddr];

endmodule
*/
