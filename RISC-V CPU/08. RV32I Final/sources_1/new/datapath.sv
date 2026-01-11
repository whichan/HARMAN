`timescale 1ns / 1ps
`include "define.vh"
//  `define SIMULATION
module datapath(
    input         clk,
    input         reset,
    input         regfile_we,
    input         branch,
    input         alu_src_sel, //ALU에 들어가는 source를 정하는 MUX에 들어가는 sel신호
    input  [ 3:0] alu_control,
    input  [ 2:0] reg_w_src_sel,
    input  [31:0] instr_code,
    input  [31:0] drdata,
    input         jal,
    input         jalr,
    output [31:0] instr_raddr,
    output [ 6:0] daddr,
    output [31:0] dwdata
);

    wire [31:0] wdata, rdata1, rdata2, o_imm, alu_src_mux_out, alu_result;
    wire btaken;
    wire [31:0] auipc_alu_result;
    wire [31:0] mux_4_in;
    assign daddr = alu_result[6:0]; //Data Memory의 daddr에는 32bit alu_result 중 하위 7비트만 보내기
    assign dwdata = rdata2;

    register_file u_register_file(
        .clk(clk),
        .reset(reset),
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
        .btaken(btaken),
        .alu_result(alu_result)
    );

    extend_imm u_extend_imm(
        .instr_code(instr_code),
        .o_imm(o_imm)
    );

    mux_rf_wd_src u_mux_rf_wd_src(
        .mux_sel(reg_w_src_sel),
        .in_0(alu_result), //alu 출력
        .in_1(drdata), //data memory load할때
        .in_2(o_imm),
        .in_3(auipc_alu_result),
        .in_4(mux_4_in),
        .mux_out(wdata)
    );

    alu u_auipc_alu(
        .alu_control(alu_control),
        .a(o_imm),
        .b(instr_raddr),
        .btaken(),
        .alu_result(auipc_alu_result)
    );

    program_counter u_program_counter(
        .clk(clk),
        .reset(reset),
        .branch(branch),
        .btaken(btaken),  
        .imm(o_imm),
        .jal(jal),
        .jalr(jalr),
        .rs1(rdata1),
        .current_pc(instr_raddr),
        .mux_4_in(mux_4_in)
    );

endmodule

module register_file(
    input         clk,
    input         reset,
    input  [ 4:0] raddr1,
    input  [ 4:0] raddr2,
    input  [ 4:0] waddr,
    input  [31:0] wdata,
    input         we,
    output [31:0] rdata1,
    output [31:0] rdata2
);

    logic [31:0] register_file [0:31]; //폭 32bit(4byte), 깊이 32: 4x32=128byte
    
    `ifdef SIMULATION
        initial begin
            for(int i=0; i<32; i++) begin
                register_file[i] = i;
            end
        end
    `endif

    always_ff @( posedge clk ) begin
        if(reset) begin
            register_file[0]<=0;
        end else if(we && waddr!=5'd0) begin
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
    output logic        btaken,
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

    always_comb begin
        btaken = 1'b0;
        case(alu_control)
            `BEQ:  btaken = (a==b);
            `BNE:  btaken = (a!=b);
            `BLT:  btaken = ($signed(a)<$signed(b));
            `BGE:  btaken = ($signed(a)>=$signed(b));
            `BLTU: btaken = (a<b);
            `BGEU: btaken = (a>=b);
        endcase
    end
endmodule


module program_counter(
    input         clk,
    input         reset,
    input         branch,
    input         btaken,
    input  [31:0] imm,
    input         jal,
    input         jalr,
    input  [31:0] rs1,
    output [31:0] current_pc,
    output [31:0] mux_4_in
);
    //clk의 상승엣지마다 다음 명령어를 읽음
    
    logic [31:0] alu_pc_next, branch_mux_out, jalr_mux_out;
    logic [31:0] alu_pc1_result, alu_pc2_result;
    assign mux_4_in = alu_pc2_result;

    mux_2x1 u_jalr_mux(
        .mux_sel(jalr),
        .in_0(current_pc),
        .in_1(rs1),
        .mux_out(jalr_mux_out)
    );

    alu_pc u_alu_pc1(
        .a(imm),
        .b(jalr_mux_out),
        .alu_pc_result(alu_pc1_result)
    );

    alu_pc u_alu_pc2(
        .a(32'd4),
        .b(current_pc),
        .alu_pc_result(alu_pc2_result)
    );

    mux_2x1 u_pc_src_mux(
        .mux_sel((btaken&branch)|jal|jalr),
        .in_0(alu_pc2_result),
        .in_1(alu_pc1_result),
        .mux_out(alu_pc_next)
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
    assign alu_pc_result = $signed(a) + $signed(b);
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

            `OP_IL_TYPE: begin
                o_imm = {{20{instr_code[31]}},instr_code[31:20]};
            end

            `OP_B_TYPE: begin
                o_imm = {
                    {19{instr_code[31]}},
                    instr_code[31], //imm[12]
                    instr_code[7], //imm[11]
                    instr_code[30:25], //imm[10:5]
                    instr_code[11:8],
                    1'b0
                };
            end
             
            `OP_U_TYPE_LUI, `OP_U_TYPE_AUIPC: begin
                o_imm = {{instr_code[31:12],12'h000}};
            end

            `OP_J_TYPE_JAL: begin
                o_imm = {
                    {12{instr_code[31]}},
                    instr_code[19:12],
                    instr_code[20],
                    instr_code[30:21],
                    1'b0
                };
            end

            `OP_J_TYPE_JALR: begin
                o_imm = {{20{instr_code[31]}},instr_code[31:20]};
            end
        endcase
    end
endmodule

module mux_rf_wd_src(
    input        [ 2:0] mux_sel,
    input        [31:0] in_0,
    input        [31:0] in_1,
    input        [31:0] in_2,
    input        [31:0] in_3,
    input        [31:0] in_4,
    output logic [31:0] mux_out
);

    always_comb begin
        mux_out = 32'b0;
        case(mux_sel)
            3'b000: mux_out = in_0;
            3'b001: mux_out = in_1;
            3'b010: mux_out = in_2;
            3'b011: mux_out = in_3;
            3'b100: mux_out = in_4;
        endcase
    end
endmodule