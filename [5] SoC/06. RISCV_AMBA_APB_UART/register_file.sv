module register_file (
    input            clk,
    input      [1:0] waddr,  //1:0
    input      [7:0] wdata,
    input      [1:0] raddr,  //1:0
    input            wr,
    input            rd,
    output reg [7:0] rdata

);
  //data 8bit, size 4byte
  logic [7:0] register_file[0:15];  //15

  always_ff @(posedge clk) begin
    // write, push
    if (wr) register_file[waddr] <= wdata;
  end

  // read, pop combinational logic
  assign rdata = register_file[raddr];

endmodule
