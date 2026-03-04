`timescale 1ns / 1ps

module imgROM (
    input  logic [$clog2(320*240)-1:0] addr,
    output logic [               15:0] data
);

  logic [15:0] mem[0:320*240-1];
  initial begin
    $readmemh("Lena_320x240.mem", mem);
  end

  assign data = mem[addr];

endmodule
