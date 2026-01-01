`timescale 1ns / 1ps
`include "define.vh"

module control_unit(
    input        [31:0] instr_code, //from ROM instruction code
    output logic        regfile_we, //Register File Write Enable 신호
    output logic        alu_src_sel, //타입별 MUX 제어신호
    output logic [ 3:0] alu_control, //ALU 제어신호
    output logic        reg_w_src_sel, //Load?
    output logic        d_we //RAM Data Memory Write Enable 신호
);

    logic [6:0] funct7; //funct7은 7bit
    logic [2:0] funct3; //funct3은 3bit
    logic [6:0] opcode; //opcode는 7bit

    assign funct7 = instr_code[31:25];
    assign funct3 = instr_code[14:12];
    assign opcode = instr_code[6:0];

    always_comb begin
        regfile_we    = 1'b0;
        alu_src_sel   = 1'b0;
        alu_control   = 4'b0;
        reg_w_src_sel = 1'b0;
        d_we          = 1'b0;

        case(opcode)
            `OP_R_TYPE: begin
                regfile_we    = 1'b1; //연산 결과를 Register File에 저장
                alu_src_sel   = 1'b0; //R type이기 때문에 rs2를 그대로 ALU 입력에 넣음
                alu_control   = {funct7[5], funct3}; //funct7[5], funct3에 따라 어떤 연산을 할지 달라짐(ADD, SUB, XOR 등등..)
                reg_w_src_sel = 1'b0; //Data Memory는 필요 없기 때문에 0
                d_we          = 1'b0; //Data Memory에 값을 넣지 않기 때문에 0
            end

            `OP_I_TYPE: begin
                regfile_we    = 1'b1; //연산 결과를 Register File에 저장
                alu_src_sel   = 1'b1; //상수(o_imm)를 ALU의 입력에 넣음

                if(funct3==`SRLI || funct3 == `SRAI) begin
                    alu_control = {funct7[5], funct3}; //0_101:SRLI, 1_101:SRAI
                end else begin
                    alu_control = {1'b0, funct3};
                end
                //SRLI와 SRAI의 funct3은 101로 같기 때문에 funct7[5]가 0인지 1인지를 통해 alu_control을 구분해야됨
                //나머지 연산자는 funct7[5]가 다 0이기 때문에 0으로 고정시켜놓음

                reg_w_src_sel = 1'b0; //Data Memory는 필요 없기 때문에 0
                d_we          = 1'b0; //Data Memory에 값을 넣지 않기 때문에 0
            end

            `OP_S_TYPE: begin
                regfile_we    = 1'b0; //그냥 Data Memory에 Store하는 것이기 때문에 Register File에는 write하지 않음
                alu_src_sel   = 1'b1; //I type이기 때문에 상수(o_imm)를 ALU의 입력에 넣음
                alu_control   = `ADD; //rs1(Base)+imm(Offset)를 통해 Data Memory의 주소에 접근하기 위해 ALU에서 add연산을 수행해야 함
                reg_w_src_sel = 1'b0; //Data Memory에 store만 하고 아직 읽지는 않기 때문에 0
                d_we          = 1'b1; //Data Memory에 store하는 것이기 때문에 d_we=1                
            end
        endcase
    end
endmodule