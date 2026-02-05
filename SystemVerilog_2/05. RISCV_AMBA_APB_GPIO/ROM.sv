`timescale 1ns / 1ps


module ROM (
    input  logic [31:0] addr,
    output logic [31:0] data
);
  logic [31:0] rom[0:2**10-1];

  initial begin
    $readmemh("code.mem", rom);
    // R-Type Test
    // rom[0] = 32'hff000093;  // addi x1, x0, -16
    // rom[1] = 32'h00300113;  // addi x2, x0, 3       
    // rom[2] = 32'h0020f633;  // and  x12, x1, x2 : AND
    // rom[2] = 32'h0020e5b3;  // or   x11, x1, x2 : OR
    // rom[2] = 32'h0020c433;  // xor  x8, x1, x2  : XOR
    // rom[2] = 32'h002081b3;  // add  x3, x1, x2  : ADD  -16+3=-13
    // rom[2] = 32'h0020b3b3;  // sltu x7, x1, x2  : SLTU
    // rom[2] = 32'h40208233;  // sub  x4, x1, x2  : SUB  -16-3=-19
    // rom[2] = 32'h002092b3;  // sll  x5, x1, x2  : SLL  
    // rom[2] = 32'h0020a333;  // slt  x6, x1, x2  : SLT
    // rom[2] = 32'h4020d533;  // sra  x10, x1, x2 : SRA
    // rom[2] = 32'h0020d4b3;  // srl  x9, x1, x2  : SRL

    //L-Type Test
    // rom[0] = 32'h06400293;
    // rom[1] = 32'h12300313;
    // rom[2] = 32'h00628023;
    // rom[3] = 32'h0002a383;

    //B-Type Test
    //BEQ
    // rom[0] = 32'h00700093;  // 1. addi x1, x0, 7      (x1 = 7)
    // rom[1] = 32'h00700113;  // 2. addi x2, x0, 7      (x2 = 7)
    // rom[2] = 32'h00208663;    // 3. beq  x1, x2, 12     (x1==x2이므로 12바이트(3줄) 뒤인 6번으로 점프)
    // rom[3] = 32'h00100193;  // 4. addi x3, x0, 1      (FAIL - 실행되면 안 됨)
    // rom[4] = 32'h00200193;  // 5. addi x3, x0, 2      (FAIL - 실행되면 안 됨)
    // rom[5] = 32'h00300213;  // 6. addi x4, x0, 3      (SUCCESS - 점프 성공 시 실행됨)

    //BNE
    // rom[0] = 32'h00a00093;  // addi x1, x0, 10  (x1 = 10)
    // rom[1] = 32'h01400113;  // addi x2, x0, 20  (x2 = 20)
    // rom[2] = 32'h00209463; // bne  x1, x2, 8   (x1 != x2이므로 8바이트 뒤인 4번으로 점프)
    // rom[3] = 32'h00100193;  // addi x3, x0, 1   (FAIL - 실행되면 안 됨)
    // rom[4] = 32'h00200213;  // addi x4, x0, 2   (SUCCESS - 점프 성공 시 실행됨)

    //BLT
    //-1<1이 참 (Signed)
    // rom[0] = 32'hfff00093;  // PC 0: addi x1, x0, -1
    // rom[1] = 32'h00100113;  // PC 4: addi x2, x0, 1
    // rom[2] = 32'h0020c463;  // PC 8: blt  x1, x2, 8 (수정됨: 오프셋 8)
    // rom[3] = 32'h00300193;  // PC 12: addi x3, x0, 3 (점프 시 건너뜀)
    // rom[4] = 32'h00400213;  // PC 16: addi x4, x0, 4 (점프 도착지)


    //LUI
    // rom[0] = 32'h123450b7;  // lui x1, 0x12345 (x1 = 0x12345000)

    // //AUIPC
    // rom[0] = 32'h12345097;  // 0x00: AUIPC x1, 0x12345 (x1 = 0x12345000 + PC)
    // rom[1] = 32'h00001117;  // 0x04: AUIPC x2, 0x00001 (x2 = 0x00001000 + PC)

    // //JAL, JALR
    // rom[0] = 32'h008000ef; // 0x00: jal  x1, 8      (8바이트 뒤인 0x08로 점프, x1 = 0x04 저장)
    // rom[1] = 32'h00100113;  // 0x04: addi x2, x0, 1   (FAIL - 점프 성공 시 실행 안 됨)
    // rom[2] = 32'h01400213;  // 0x08: addi x4, x0, 20  (x4 = 20, 즉 0x14 주소 준비)
    // rom[3] = 32'h000202e7;  // 0x0c: jalr x5, 0(x4)   (x4인 0x14로 점프, x5 = 0x10 저장)
    // rom[4] = 32'h00100313;  // 0x10: addi x6, x0, 1   (FAIL - 점프 성공 시 실행 안 됨)
    // rom[5] = 32'h00100393;  // 0x14: addi x7, x0, 1   (SUCCESS - 최종 도착지)





  end

  assign data = rom[addr[31:2]];

endmodule
