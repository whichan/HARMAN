`timescale 1ns / 1ps

module datapath(
    input   clk,
    input   reset,
    input   src_sel,
    input   a_load,
    input   out_sel,
    output  [7:0] out
);

    wire [7:0] w_alu_out;
    wire [7:0] w_mux_out;
    wire [7:0] w_a_reg_out;

    assign out = out_sel ? w_a_reg_out : 8'hzz;

    mux_2x1 u_mux_2x1(
        .a(8'h00),
        .b(w_alu_out),
        .src_sel(src_sel),
        .mux_out(w_mux_out)
    );

    a_reg u_a_reg(
        .clk(clk),
        .reset(reset),
        .a_load(a_load),
        .in_data(w_mux_out),
        .out_data(w_a_reg_out)
    );

    alu u_alu(
        .a(w_a_reg_out),
        .b(8'h01),
        .alu_out(w_alu_out)
    );

endmodule


module mux_2x1(
    input [7:0] a,
    input [7:0] b,
    input       src_sel,
    output logic [7:0] mux_out
);

    always_comb begin
        if(src_sel) mux_out = b;
        else mux_out = a;
    end

endmodule


module a_reg(
    input        clk,
    input        reset,
    input        a_load,
    input  [7:0] in_data,
    output [7:0] out_data
);

    reg [7:0] a_reg;

    always_ff @( posedge clk or posedge reset ) begin
        if(reset) begin
            a_reg <= 8'b0;
        end else begin
            if(a_load) begin
                a_reg <= in_data; //a_reg에 in_data를 저장
            end
        end 
    end

    

    assign out_data = a_reg;

endmodule


module alu(
    input [7:0] a,
    input [7:0] b,
    output [7:0] alu_out
);

    assign alu_out = a + b;

endmodule