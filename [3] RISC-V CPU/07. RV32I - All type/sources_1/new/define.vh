//OP_CODE
`define OP_R_TYPE       7'b0110011
`define OP_S_TYPE       7'b0100011
`define OP_IL_TYPE      7'b0000011
`define OP_I_TYPE       7'b0010011
`define OP_B_TYPE       7'b1100011
`define OP_U_TYPE_LUI   7'b0110111
`define OP_U_TYPE_AUIPC 7'b0010111
`define OP_J_TYPE_JAL   7'b1101111
`define OP_J_TYPE_JALR  7'b1100111

//R-type, funct7[5], funct3
`define ADD  4'b0_000
`define SUB  4'b1_000
`define SLL  4'b0_001
`define SLT  4'b0_010
`define SLTU 4'b0_011
`define XOR  4'b0_100
`define SRL  4'b0_101
`define SRA  4'b1_101
`define OR   4'b0_110
`define AND  4'b0_111

//S-type
`define SW 3'b010

//I-type
`define ADDI  4'b0000
`define SLLI  4'b0001
`define SLTI  4'b0010
`define SLTUI 4'b0011
`define XORI  4'b0100
`define SRLI  4'b0101
`define SRAI  4'b1101
`define ORI   4'b0110
`define ANDI  4'b0111

//IL-type
//funct3
`define LB  3'b000
`define LH  3'b001
`define LW  3'b010
`define LBU 3'b100
`define LHU 3'b101

//B-type
`define BEQ  4'b0_000
`define BNE  4'b0_001
`define BLT  4'b0_100
`define BGE  4'b0_101
`define BLTU 4'b0_110
`define BGEU 4'b0_111
