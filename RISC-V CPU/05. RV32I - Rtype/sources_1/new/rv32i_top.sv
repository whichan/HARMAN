`timescale 1ns / 1ps

module rv32i_top(
    input clk,
    input reset
    );

    logic [31:0] instr_code, instr_raddr;

    rv32i_core u_rv32i_core(
        .clk(clk),
        .reset(reset),
        .instr_code(instr_code),
        .instr_raddr(instr_raddr)
    );

    instr_memory u_instr_mem(
        .instr_raddr(instr_raddr),
        .instr_code(instr_code)
    );
endmodule