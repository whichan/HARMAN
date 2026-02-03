`timescale 1ns / 1ps

module ROM (
    input  logic [31:0] addr,
    output logic [31:0] data
);
  logic [31:0] rom[0:2**10-1];

  initial begin
    // rom[0] = 32'h00a00093;
    // rom[1] = 32'h01400113;
    // rom[2] = 32'h00a00193;
    // rom[3] = 32'h00308463;
    // rom[4] = 32'h0ee00213;
    // rom[5] = 32'h00100213;
    // rom[6] = 32'h00209463;
    // rom[7] = 32'h0ee00293;
    // rom[8] = 32'h00200293;

    //LUI, JAL, JALR
    // rom[0] = 32'h000120b7;
    // rom[1] = 32'h00001117;
    // rom[2] = 32'h008001ef;
    // rom[3] = 32'h0ee00213;
    // rom[4] = 32'h00100293;
    // rom[5] = 32'h04000313;
    // rom[6] = 32'h000303e7;

    $readmemh("/home/aedu22/LWC/0129_RISCV_SingleCycle/rtl/RomFile.mem", rom);

  end

  assign data = rom[addr[31:2]];

endmodule
