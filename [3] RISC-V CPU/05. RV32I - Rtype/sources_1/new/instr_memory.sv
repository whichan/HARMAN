`timescale 1ns / 1ps

module instr_memory(
    input  [31:0] instr_raddr,
    output [31:0] instr_code
    );
    
    logic [31:0] rom_file [0:15]; //폭 32bit(4byte)
                                  //명령어 10개를 처리할 것이기 때문에 대충 16개 정도 있으면 됨
    
    initial begin
        for (int i=0; i<16; i++) begin
            rom_file[i] = 32'd0;
        end
                      //  funct7   rs2   rs1  f3   rd   opcode
        rom_file[0] = 32'b0000000_00001_00000_000_00011_0110011; //ADD x3 x0 x1: x3에 0+1 = 1을 저장
        rom_file[1] = 32'b0100000_00001_00000_000_00100_0110011; //SUB x4 x0 x1: x4에 0-1 = -1을 저장
        rom_file[2] = 32'b0000000_00010_00100_001_00101_0110011; //SLL x5 x4 x2: x5에 x3 << x2 연산결과를 저장
        rom_file[3] = 32'b0000000_00010_00100_010_00110_0110011; //SLT x6 x4 x2: x6에 x3, x2 대소관계 결과를 저장
        rom_file[4] = 32'b0000000_00010_00100_011_00111_0110011; //SLTU x7 x3 x2: x7에 x3, x2 대소관계 결과를 저장(unsigned)
        rom_file[5] = 32'b0000000_00001_00011_100_01000_0110011;//XOR x8 x3 x1: x8에 00010=2 저장
        rom_file[6] = 32'b0000000_00010_00100_101_01001_0110011; //SRL x9에 저장
        rom_file[7] = 32'b0100000_00010_00100_101_01010_0110011;//SRA x10에 저장
        rom_file[8] = 32'b0000000_00010_00001_110_01011_0110011;//OR x11 x1 x2: x11에 3저장
        rom_file[9] = 32'b0000000_00010_00001_111_01100_0110011; //AND x12 x1 x2: x12에 0저장

        // rom_file[0] = 32'h0041_82b3;
        // rom_file[1] = 
        // rom_file[2] = 
        // rom_file[3] = 
        // rom_file[4] = 
        // rom_file[5] = 
        // rom_file[6] = 
        // rom_file[7] = 
        // rom_file[8] = 
        // rom_file[9] = 
    end

    assign instr_code = rom_file[instr_raddr[5:2]]; //pc count가 4씩 증가할 때 주소는 1씩 증가하도록

endmodule