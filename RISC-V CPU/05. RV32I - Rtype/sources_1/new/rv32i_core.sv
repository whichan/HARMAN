`timescale 1ns / 1ps

module rv32i_core(
    input clk,
    input reset,
    input [31:0] instr_code,
    output [31:0] instr_raddr
    );

    wire w_we;
    wire [3:0] w_alu_control;

    datapath u_datapath(
        .clk(clk),
        .reset(reset),
        .we(w_we),
        .alu_control(w_alu_control),
        .instr_code(instr_code),
        .instr_raddr(instr_raddr)
    );

    control_unit u_control_unit(
        .instr_code(instr_code),
        .we(w_we),
        .alu_control(w_alu_control)
    );

endmodule