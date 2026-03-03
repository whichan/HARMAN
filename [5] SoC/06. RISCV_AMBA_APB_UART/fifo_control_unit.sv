module fifo_control_unit (
    input        clk,
    input        reset,
    input        wr,
    input        rd,
    output [1:0] w_ptr,  //1:0
    output [1:0] r_ptr,  //1:0
    output       full,
    output       empty
);

  logic cur_full, next_full, cur_empty, next_empty;
  logic [1:0] cur_wptr, next_wptr, cur_rptr, next_rptr;  //1:0

  assign full  = cur_full;
  assign empty = cur_empty;
  assign w_ptr = cur_wptr;
  assign r_ptr = cur_rptr;

  // state register logic
  always_ff @(posedge clk, posedge reset) begin
    if (reset) begin
      cur_full  <= 0;
      cur_empty <= 0;  //0
      cur_wptr  <= 0;
      cur_rptr  <= 0;
    end else begin
      cur_full  <= next_full;
      cur_empty <= next_empty;
      cur_wptr  <= next_wptr;
      cur_rptr  <= next_rptr;
    end
  end

  // next state logic

  always_comb begin
    next_full  = cur_full;
    next_empty = cur_empty;
    next_wptr  = cur_wptr;
    next_rptr  = cur_rptr;
    case ({
      wr, rd
    })  // state wr, rd or psuh, pop
      2'b00: begin  //없어도됨
        //idle

      end
      2'b01: begin
        //pop
        next_full = 1'b0;
        if (!cur_empty) begin
          next_rptr = cur_rptr + 1;
          if (cur_wptr == next_rptr) begin
            next_empty = 1'b1;
          end
        end
      end

      2'b10: begin
        //push
        next_empty = 1'b0;
        if (!cur_full) begin
          next_wptr = cur_wptr + 1;
          if (cur_rptr == next_wptr) begin
            next_full = 1'b1;
          end
        end
      end

      2'b11: begin
        //push, pop
        if (cur_empty == 1) begin
          // only push
          next_empty = 0;
          next_wptr  = cur_wptr + 1;
        end else if (cur_full == 1) begin
          // only pop
          next_full = 0;
          next_rptr = cur_rptr + 1;
        end else begin
          // write, read ptr inc
          next_wptr = cur_wptr + 1;
          next_rptr = cur_rptr + 1;
        end
      end

    endcase
  end

endmodule
