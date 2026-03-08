`timescale 1ns / 1ps

module control_unit(
    input        [31:0] instr_code,
    output logic        we,
    output logic [3:0] alu_control
    );

    logic [6:0] funct7;
    logic [2:0] funct3;
    logic [6:0] opcode;

    assign funct7 = instr_code[31:25];
    assign funct3 = instr_code[14:12];
    assign opcode = instr_code[6:0];

    always_comb begin //opcode가 0110011일때만 write
        we = 1'b0;
        case(opcode)
            7'b0110011: we = 1'b1;
            default: we = 1'b0;
        endcase
    end

    always_comb begin
        alu_control = 4'b000;
        case({funct7[5], funct3})
            4'b0_000: alu_control = 4'd0; //ADD
            4'b1_000: alu_control = 4'd1; //SUB
            4'b0_001: alu_control = 4'd2; //SLL
            4'b0_010: alu_control = 4'd3; //SLT
            4'b0_011: alu_control = 4'd4; //SLTU
            4'b0_100: alu_control = 4'd5; //XOR
            4'b0_101: alu_control = 4'd6; //SRL
            4'b1_101: alu_control = 4'd7; //SRA
            4'b0_110: alu_control = 4'd8; //OR
            4'b0_111: alu_control = 4'd9; //AND
            default: alu_control = 4'd0;
        endcase
    end

endmodule