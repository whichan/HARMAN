`timescale 1ns / 1ps

module rv32i_top(
    input clk,
    input reset
    );

    logic [31:0] instr_code, instr_raddr, dwdata, drdata;
    logic wr_en, d_we;
    logic [1:0] reg_w_src_sel;
    logic [6:0] daddr;
    

    rv32i_core u_rv32i_core(
        // .clk(clk),
        // .reset(reset),
        // .instr_code(instr_code),
        // .instr_raddr(instr_raddr)
        .*
    );

    instr_memory u_instr_mem(
        // .instr_raddr(instr_raddr),
        // .instr_code(instr_code)
        .*
    );

    data_memory u_data_mem(
        .clk(clk),
        .d_we(d_we),
        .wr_en(wr_en),
        .daddr(daddr),
        .dwdata(dwdata),
        .drdata(drdata)
    );

endmodule