`timescale 1ns / 1ps

//control_unit + datapath
module rv32i_core(
    input         clk,
    input         reset,
    input  [31:0] instr_code,
    input  [31:0] drdata,
    output [31:0] instr_raddr,
    output        d_we,
    output [31:0] dwdata,
    output [ 6:0] daddr
    );

    logic regfile_we, branch, alu_src_sel;
    logic [3:0] alu_control;
    logic [1:0] reg_w_src_sel;

    datapath u_datapath(
        // .clk(clk),
        // //.reset(reset),
        // .we(we),
        // .alu_control(alu_control),
        // .instr_code(instr_code), 
        // .instr_raddr(instr_raddr) 
        .*
    );

    control_unit u_control_unit(
        .*
    );

endmodule