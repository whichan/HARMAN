`timescale 1ns / 1ps

module datapath(
    input        clk,
    input        reset,
    input        a_src_sel,
    input        sum_src_sel,
    input        a_load,
    input        sum_load,
    input        alu_src_sel,
    input        out_load,
         
    output       ale10,
    output [7:0] out
    );

    wire [7:0] w_mux_a_out, w_mux_sum_out, w_sum_reg_out, w_mux_alu_out;
    wire [7:0] w_a_reg_out, w_alu_out;

    mux_2x1 u_mux_a(
        .a(8'h00),
        .b(w_alu_out),
        .sel(a_src_sel),
        .mux_out(w_mux_a_out)
    );

    register u_a_reg(
        .clk(clk),
        .reset(reset),
        .load(a_load),
        .data_in(w_mux_a_out),
        .data_out(w_a_reg_out)
    );

    mux_2x1 u_mux_sum(
        .a(8'h00),
        .b(w_alu_out),
        .sel(sum_src_sel),
        .mux_out(w_mux_sum_out)
    );

    register u_sum_reg(
        .clk(clk),
        .reset(reset),
        .load(sum_load),
        .data_in(w_mux_sum_out),
        .data_out(w_sum_reg_out)
    );

    mux_2x1 u_mux_alu(
        .a(8'h01),
        .b(w_sum_reg_out),
        .sel(alu_src_sel),
        .mux_out(w_mux_alu_out)
    );

    alu u_alu(
        .a(w_a_reg_out),
        .b(w_mux_alu_out),
        .alu_out(w_alu_out)
    );

    comparator u_comparator(
        .a(w_a_reg_out),
        .b(8'd10),
        .ale10(ale10)
    );

    register u_out_reg(
        .clk(clk),
        .reset(reset),
        .load(out_load),
        .data_in(w_sum_reg_out),
        .data_out(out)
    );

endmodule

module register (
    input        clk,
    input        reset,
    input        load,
    input  [7:0] data_in,
    output [7:0] data_out
);

    logic [7:0] register;
    
    always_ff @( posedge clk or posedge reset ) begin
        if(reset) begin
            register <= 8'h0;
        end else begin
            if(load) register <= data_in;
        end
    end

    assign data_out = register;
endmodule

module mux_2x1(
    input  [7:0] a,
    input  [7:0] b,
    input        sel,
    output [7:0] mux_out
);

    assign mux_out = sel ? b : a;

endmodule

module alu(
    input  [7:0] a,
    input  [7:0] b,
    output [7:0] alu_out
    
);
    assign alu_out = a + b;
    
endmodule

module comparator(
    input [7:0] a,
    input [7:0] b,
    output      ale10
);

    assign ale10 = a<= b;
    //작으면 1, 크면 0

endmodule