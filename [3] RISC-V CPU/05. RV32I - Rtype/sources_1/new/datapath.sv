`timescale 1ns / 1ps

module datapath(
    input clk,
    input reset,
    input we,
    input [3:0] alu_control,
    input [31:0] instr_code,
    output [31:0] instr_raddr
    );

    wire [31:0] wdata, rdata1, rdata2;

    register_file u_register_file(
        .clk(clk),
        .raddr1(instr_code[19:15]), //rs1
        .raddr2(instr_code[24:20]), //rs2
        .waddr(instr_code[11:7]), 
        .wdata(wdata), 
        .we(we),
        .rdata1(rdata1),
        .rdata2(rdata2) 
    );

    alu u_alu(
        .control(alu_control),
        .a(rdata1),
        .b(rdata2),
        .alu_result(wdata)
    );

    program_counter u_pc(
        .clk(clk),
        .reset(reset),
        .current_pc(instr_raddr)
    );

endmodule

module register_file(
    input         clk,
    input  [ 4:0] raddr1, //instruction code rs1(register source 1)
    input  [ 4:0] raddr2, //instruction code rs2(register source 2)
    input  [ 4:0] waddr, //instruction code rd(register destination)
    input  [31:0] wdata, //ALU output
    input         we, //from control_unit
    output [31:0] rdata1, //to ALU a
    output [31:0] rdata2  //to ALU b
);

    logic [31:0] register_file [0:31]; //폭 32bit(4byte), 깊이 32개, 총 128byte
    
    initial begin
        for (int i=0; i<32; i++) begin
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
    input [3:0] control,
    input [31:0] a,
    input [31:0] b,
    output logic [31:0] alu_result
);

    enum logic [3:0] {ADD, SUB, SLL, SLT, SLTU, XOR, SRL, SRA, OR, AND} op_e;
    
    always_comb begin
        alu_result = 0;
        case(control)
            ADD: alu_result = a + b;
            SUB: alu_result = a - b;
            SLL: alu_result = a <<b[4:0];
            //SLT: 부호 있는 Signed 비교
            SLT: alu_result = ($signed(a)<$signed(b)) ? 32'd1 : 32'd0;
            //SLTU: 부호 없는 Unsigned 비교
            SLTU: alu_result = (a<b) ? 32'd1: 32'd0;
            XOR: alu_result = a ^ b;
            SRL: alu_result = a >> b[4:0];
            SRA: alu_result = $signed(a) >>> b[4:0]; //
            OR: alu_result = a | b;
            AND: alu_result = a & b;
            default: alu_result = 32'b0;
        endcase
    end
endmodule

module program_counter(
    input clk,
    input reset,
    output [31:0] current_pc
);

    logic [31:0] alu_pc_next;

    alu_pc u_alu_pc(
        .a(32'd4),
        .b(current_pc),
        .o_alu(alu_pc_next)
    );  

    register u_reg_pc(
        .clk(clk),
        .reset(reset),
        .data_in(alu_pc_next),
        .data_out(current_pc)
    );
endmodule

module alu_pc(
    input [31:0] a,
    input [31:0] b,
    output [31:0] o_alu
);
    assign o_alu = a + b;
endmodule

module register(
    input               clk,
    input               reset,
    input        [31:0] data_in,
    output logic [31:0] data_out
);

    logic [31:0] register;

    always_ff @( posedge clk or posedge reset ) begin
        if(reset) begin
            register <= 0;
        end else begin
            register <= data_in;
        end
    end

    assign data_out = register;
endmodule