// `timescale 1ns / 1ps

// `include "define.vh"

// module datapath(
//     input         clk,
//     input         reset,
//     input         regfile_we,
//     input         branch,
//     input         alu_src_sel,
//     input  [ 3:0] alu_control,
//     input  [ 1:0] reg_w_src_sel, //load
//     input  [31:0] instr_code, //instruction code from rom
//     input  [31:0] drdata, //from data memory
//     output [31:0] instr_raddr, //pc to rom
//     output [ 6:0] daddr, //to data ram address
//     output [31:0] dwdata //to data ram data
//     );

//     wire [31:0] alu_result, rdata1, rdata2, reg_w_src, o_auipc;
//     wire [31:0] alu_src_2, o_imm, auipc_alu_result;
//     wire btaken; //branch 신호를 잡겠다는 뜻
    
//     assign daddr = alu_result[6:0]; //4bit만 붙이기
//     assign dwdata = rdata2;

//     mux_rf_wd_src u_reg_w_src_mux(
//         .mux_sel(reg_w_src_sel),
//         .in_0(alu_result),
//         .in_1(drdata),
//         .in_2(o_imm),
//         .in_3(auipc_alu_result),
//         .mux_out(reg_w_src)
//     );

//     // mux_2x1 u_reg_w_src_mux(
//     //     .mux_sel(reg_w_src_sel),
//     //     .in_0(alu_result), //from alu
//     //     .in_1(drdata), //from data memory
//     //     .mux_out(reg_w_src) //to register file
//     // );


//     register_file u_register_file(
//         .clk(clk),
//         .raddr1(instr_code[19:15]), //rs1
//         .raddr2(instr_code[24:20]), //rs2
//         .waddr(instr_code[11:7]), 
//         .wdata(reg_w_src), //from reg_w_src_mux 
//         .we(regfile_we),
//         .rdata1(rdata1),
//         .rdata2(rdata2) 
//     );

//     alu u_alu(
//         .alu_control(alu_control),
//         .a(rdata1), //rs1
//         .b(alu_src_2), //
//         .btaken(btaken), //branch operation
//         .alu_result(alu_result)
//     );

//     mux_2x1 u_alu_src_mux(
//         .mux_sel(alu_src_sel),
//         .in_0(rdata2),
//         .in_1(o_imm),
//         .mux_out(alu_src_2)
//     );

//     program_counter u_pc(
//         .clk(clk),
//         .reset(reset),
//         .branch(branch),
//         .btaken(btaken),
//         .imm(o_imm),
//         .o_auipc(o_auipc), //to reg_wd_src_mux
//         .current_pc(instr_raddr)
//     );

//     alu auipc_alu(
//         .alu_control(alu_control),
//         .a(o_imm),
//         .b(instr_raddr),
//         .btaken(),
//         .alu_result(auipc_alu_result)
//     );

//     extend_imm u_extend_imm(
//         .instr_code(instr_code),
//         .o_imm(o_imm)
//     );

// endmodule

// module register_file(
//     input         clk,
//     input  [ 4:0] raddr1, //instruction code rs1(register source 1)
//     input  [ 4:0] raddr2, //instruction code rs2(register source 2)
//     input  [ 4:0] waddr, //instruction code rd(register destination)
//     input  [31:0] wdata, //ALU output
//     input         we, //from control_unit
//     output [31:0] rdata1, //to ALU a
//     output [31:0] rdata2  //to ALU b
// );

//     logic [31:0] register_file [0:31]; //폭 32bit(4byte), 깊이 32개, 총 128byte
    
//     initial begin
//         for (int i=0; i<32; i++) begin
//             register_file[i] = i;
//         end
//     end
    
//     always_ff @( posedge clk ) begin
//         if(we) begin
//             register_file[waddr] <= wdata;
//         end
//     end

//     assign rdata1 = register_file[raddr1];
//     assign rdata2 = register_file[raddr2];
    
// endmodule

// module alu(
//     input        [ 3:0] alu_control,
//     input        [31:0] a,
//     input        [31:0] b,
//     output logic        btaken,
//     output logic [31:0] alu_result
// );

//     enum logic [3:0] {ADD, SUB, SLL, SLT, SLTU, XOR, SRL, SRA, OR, AND} op_e;
    
//     always_comb begin
//         alu_result = 0;
//         case(alu_control)
//             `ADD: alu_result = a + b;
//             `SUB: alu_result = a - b;
//             `SLL: alu_result = a <<b[4:0]; //32bit이기 때문에 하위 5비트까지만.
//                                            //5bit를 안하면 shift 11111에서
//             //SLT: 부호 있는 Signed 비교
//             `SLT: alu_result = ($signed(a)<$signed(b)) ? 32'd1 : 32'd0;
//                                //기본적으로 unsigned이기 때문에 signed 타입으로 바꿔줘야함
//             //SLTU: 부호 없는 Unsigned 비교
//             `SLTU: alu_result = (a<b) ? 32'd1: 32'd0;
//             `XOR: alu_result = a ^ b;
//             `SRL: alu_result = a >> b[4:0]; //
//             `SRA: alu_result = $signed(a) >>> b[4:0]; //
//             `OR: alu_result = a | b;
//             `AND: alu_result = a & b;
//             default: alu_result = 32'b0;
//         endcase
//     end

//     always_comb begin
//         btaken = 1'b0;
//         case(alu_control)
//             `BEQ: btaken  = (a==b); // 
//             `BNE: btaken  = (a!=b); //
//             `BLT: btaken  = ($signed(a)<$signed(b));  // rs1 < rs2
//             `BGE: btaken  = ($signed(a)>=$signed(b)); // rs1 >= rs2
//             `BLTU: btaken = (a<b);  // rs1 
//             `BGEU: btaken = (a>=b);
//         endcase
//     end
// endmodule

// module program_counter(
//     input         clk,
//     input         reset,
//     input         branch,
//     input         btaken,
//     input  [31:0] imm,
//     output [31:0] o_auipc,
//     output [31:0] current_pc
// );

//     logic [31:0] alu_pc_next;
//     logic [31:0] branch_mux;

//     alu_pc u_auipc(
//         .a(imm),
//         .b(current_pc),
//         .o_alu(o_auipc)
//     );

//     mux_2x1 u_pc_src_mux(
//         .mux_sel(branch&btaken),
//         .in_0(32'd4),
//         .in_1(imm),
//         .mux_out(branch_mux)
//     );

//     alu_pc u_alu_pc(
//         .a(branch_mux),
//         .b(current_pc),
//         .o_alu(alu_pc_next)
//     );  

//     register u_reg_pc(
//         .clk(clk),
//         .reset(reset),
//         .data_in(alu_pc_next),
//         .data_out(current_pc)
//     );


// endmodule

// module alu_pc(
//     input [31:0] a,
//     input [31:0] b,
//     output [31:0] o_alu
// );
//     assign o_alu = a + b;
// endmodule

// module register(
//     input               clk,
//     input               reset,
//     input        [31:0] data_in,
//     output logic [31:0] data_out
// );

//     logic [31:0] register;

//     always_ff @( posedge clk or posedge reset ) begin
//         if(reset) begin
//             register <= 0;
//         end else begin
//             register <= data_in;
//         end
//     end

//     assign data_out = register;
// endmodule

// module extend_imm(
//     input        [31:0] instr_code,
//     output logic [31:0] o_imm
// );

//     //opcode에 따라 처리해야하는 imm의 비트가 달라짐
//     always_comb begin
//         o_imm = 32'd0;
//         case(instr_code[6:0])
//             `OP_S_TYPE: begin
//                         //20bit signed extends by instr_code[31:25] + imm[11:0]
//                 o_imm = {{20{instr_code[31]}},instr_code[31:25], instr_code[11:7]};
//                         //20번반복
//             end

//             `OP_I_TYPE: begin
//                 o_imm = {{20{instr_code[31]}},instr_code[31:20]};
//             end

//             `OP_IL_TYPE: begin
//                 o_imm = {{20{instr_code[31]}},instr_code[31:20]};
//             end

//             `OP_B_TYPE: begin
//                 o_imm = {
//                     {19{instr_code[31]}},
//                     instr_code[31], 
//                     instr_code[7],
//                     instr_code[30:25],
//                     instr_code[11:8], 
//                     1'b0
//                     };
//             end

//             `OP_U_TYPE_LUI, `OP_U_TYPE_AUIPC: begin
//                 //instr_code[31:12] + 12'h000
//                 o_imm = {instr_code[31:12], 12'h000};
//             end
//         endcase
//     end
// endmodule


// module mux_2x1(
//     input         mux_sel,
//     input  [31:0] in_0,
//     input  [31:0] in_1,
//     output [31:0] mux_out
// );

//     assign mux_out = mux_sel ? in_1 : in_0;

// endmodule

// module mux_rf_wd_src( //Register File의 Write Data에 넣어줄 Source를 결정하는 MUX
//     input        [ 2:0] mux_sel,
//     input        [31:0] in_0, //alu result
//     input        [31:0] in_1, //data memory
//     input        [31:0] in_2, //LUI
//     input        [31:0] in_3, //AUIPC
//     input        [31:0] in_4, //JAL
//     output logic [31:0] mux_out
// );

//     always_comb begin
//         mux_out = in_0;
//         case(mux_sel)
//             3'b000: mux_out = in_0;
//             3'b001: mux_out = in_1;
//             3'b010: mux_out = in_2;
//             3'b011: mux_out = in_3;
//             3'b100: mux_out = in_4;
//             default: mux_out = 32'b0;
//         endcase
//     end
// endmodule

`timescale 1ns / 1ps
`include "define.vh"

module datapath(
    input         clk,
    input         reset,
    input         regfile_we,
    input         alu_src_sel, //ALU에 들어가는 source를 정하는 MUX에 들어가는 sel신호
    input  [ 3:0] alu_control,
    input         reg_w_src_sel,
    input  [31:0] instr_code,
    input  [31:0] drdata,
    output [31:0] instr_raddr,
    output [ 6:0] daddr,
    output [31:0] dwdata
);

    wire [31:0] wdata, rdata1, rdata2, o_imm, alu_src_mux_out, alu_result;

    assign daddr = alu_result[6:0]; //Data Memory의 daddr에는 32bit alu_result 중 하위 7비트만 보내기
    assign dwdata = rdata2;

    register_file u_register_file(
        .clk(clk),
        .raddr1(instr_code[19:15]),
        .raddr2(instr_code[24:20]),
        .waddr(instr_code[11:7]),
        .wdata(wdata),
        .we(regfile_we),
        .rdata1(rdata1),
        .rdata2(rdata2)
    );

    mux_2x1 u_alu_src_mux(
        .mux_sel(alu_src_sel),
        .in_0(rdata2),
        .in_1(o_imm),
        .mux_out(alu_src_mux_out)
    );

    alu u_alu(
        .alu_control(alu_control),
        .a(rdata1),
        .b(alu_src_mux_out),
        .alu_result(alu_result)
    );

    extend_imm u_extend_imm(
        .instr_code(instr_code),
        .o_imm(o_imm)
    );

    mux_rf_wd_src u_mux_rf_wd_src(
        .mux_sel(reg_w_src_sel),
        .in_0(alu_result),
        .in_1(drdata),
        .mux_out(wdata)
    );

    program_counter u_program_counter(
        .clk(clk),
        .reset(reset),
        .current_pc(instr_raddr)
    );

endmodule

module register_file(
    input         clk,
    input  [ 4:0] raddr1,
    input  [ 4:0] raddr2,
    input  [ 4:0] waddr,
    input  [31:0] wdata,
    input         we,
    output [31:0] rdata1,
    output [31:0] rdata2
);

    logic [31:0] register_file [0:31]; //폭 32bit(4byte), 깊이 32: 4x32=128byte

    initial begin
        for(int i=0; i<32; i++) begin
            register_file[i] = i;
        end
    end

    always_ff @( posedge clk ) begin
        if(we) begin
            register_file[waddr] <= wdata;
        end
    end

    assign rdata1 = register_file[raddr1];
    assign rdata2 = register_file[raddr2];

endmodule

module alu(
    input        [ 3:0] alu_control,
    input        [31:0] a,
    input        [31:0] b,
    output logic [31:0] alu_result
);

    //enum logic {ADD, SUB, SLL, SLT, SLTU, XOR, SRL, SRA, OR, AND} op_e;

    always_comb begin
        alu_result = 0;
        case(alu_control)
            `ADD: alu_result = a + b;
            `SUB: alu_result = a - b;
            `SLL: alu_result = a << b[4:0]; //risc-v는 32bit이기 때문에 하위 5비트만 다룸
            //SLA가 없는 이유는 SLL과 동작이 똑같음
            `SLT: alu_result = ($signed(a)<$signed(b)) ? 32'd1 : 32'd0;
            `SLTU: alu_result = (a<b) ? 32'd1 : 32'd0;
            `XOR: alu_result = a ^ b;
            `SRL: alu_result = a >> b[4:0]; //오른쪽으로 밀면서 무조건 0으로 채움
            `SRA: alu_result = $signed(a) >>> b[4:0]; //>>>: 오른쪽으로 밀면서 빈 공간을 원래 있던 부호 비트(MSB)로 채움
            `OR: alu_result = a | b;
            `AND: alu_result = a & b;
        endcase
    end
endmodule

module program_counter(
    input         clk,
    input         reset,
    output [31:0] current_pc
);
    //clk의 상승엣지마다 다음 명령어를 읽음
    
    logic [31:0] alu_pc_next;

    alu_pc u_alu_pc(
        .a(32'h4),
        .b(current_pc),
        .alu_pc_result(alu_pc_next)
    );

    register u_register(
        .clk(clk),
        .reset(reset),
        .data_in(alu_pc_next),
        .data_out(current_pc)
    );

endmodule

module alu_pc(
    input [31:0] a,
    input [31:0] b,
    output [31:0] alu_pc_result
);
    assign alu_pc_result = a + b;
endmodule

module mux_2x1(
    input         mux_sel,
    input  [31:0] in_0,
    input  [31:0] in_1,
    output [31:0] mux_out
);

    assign mux_out = mux_sel ? in_1 : in_0;

endmodule

module register(
    input         clk,
    input         reset,
    input  [31:0] data_in,
    output [31:0] data_out
);
    
    logic [31:0] register;

    always_ff @( posedge clk ) begin
        if(reset) begin
            register <= 0;
        end else begin
            register <= data_in;
        end
    end

    assign data_out = register;
endmodule

module extend_imm(
    input        [31:0] instr_code,
    output logic [31:0] o_imm
);

    //instruction set 참조
    //opcode에 따라 처리해야 하는 imm의 비트가 달라짐
    always_comb begin
        o_imm = 0;
        case(instr_code[6:0])
        
            `OP_I_TYPE: begin
                o_imm = {{20{instr_code[31]}},instr_code[31:20]};
            end
    
            `OP_S_TYPE: begin
                o_imm = {{20{instr_code[31]}},instr_code[31:25],instr_code[11:7]};
            end
        endcase
    end
endmodule

module mux_rf_wd_src(
    input               mux_sel,
    input        [31:0] in_0,
    input        [31:0] in_1,
    output logic [31:0] mux_out
);

    always_comb begin
        case(mux_sel)
            1'b0: mux_out = in_0;
            1'b1: mux_out = in_1;
        endcase
    end

endmodule