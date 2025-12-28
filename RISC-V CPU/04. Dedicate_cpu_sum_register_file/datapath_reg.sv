`timescale 1ns / 1ps

module datapath_reg(
    input        clk,
    input        reset,
    input        rf_src_sel,
    input  [1:0] raddr1,
    input  [1:0] raddr2,
    input  [1:0] waddr,
    input        we,
    input        out_load,
    output       ale10,
    output [7:0] out
    );

    wire [7:0] w_alu_out, w_rd1, w_rd2, w_mux_out;

    mux_2x1 u_mux(
        .a(8'h01),
        .b(w_alu_out),
        .sel(rf_src_sel),
        .mux_out(w_mux_out)
    );

    register_file u_register_file(
        .clk(clk),
        .data_in(w_mux_out),
        .raddr1(raddr1),
        .raddr2(raddr2),
        .waddr(waddr),
        .we(we),
        .rd1(w_rd1),
        .rd2(w_rd2)
    );

    alu u_alu(
        .a(w_rd1),
        .b(w_rd2),
        .alu_out(w_alu_out)
    );

    register u_register_out(
        .clk(clk),
        .reset(reset),
        .load(out_load),
        .data_in(w_rd2),
        .data_out(out)
    );

    comparator u_comp10(
        .a(w_rd1),
        .b(8'd10),
        .ale10(ale10)
    );

endmodule

module mux_2x1(
    input  [7:0] a,
    input  [7:0] b,
    input        sel,
    output [7:0] mux_out
);

    assign mux_out = sel ? b: a;
    
endmodule

module register_file(
    input        clk,
    input  [7:0] data_in,
    input  [1:0] raddr1,
    input  [1:0] raddr2,
    input  [1:0] waddr,
    input        we,
    output [7:0] rd1,
    output [7:0] rd2
);

    logic [7:0] reg_file [0:3]; //data 8bit, 4byte
    //assign register_file[0] = 8'h00;
    
    always @(posedge clk) begin
        if(we) begin
            if(waddr != 0) begin
                reg_file[waddr] <= data_in;
            end 
        end
    end

    assign rd1 = (raddr1 == 2'd0) ? 8'h00 : reg_file[raddr1];
    assign rd2 = (raddr2 == 2'd0) ? 8'h00 : reg_file[raddr2];

    
endmodule

module alu(
    input  [7:0] a,
    input  [7:0] b,
    output [7:0] alu_out
);
    assign alu_out = a + b;
endmodule

module register(
    input        clk,
    input        reset,
    input        load,
    input  [7:0] data_in,
    output [7:0] data_out
);

    reg [7:0] register;
    
    always_ff @( posedge clk or posedge reset ) begin
        if(reset) begin
            register <= 8'h00;
        end else begin
            if(load) register <= data_in;
        end
    end

    assign data_out = register;

endmodule

module comparator(
    input [7:0] a,
    input [7:0] b,
    output      ale10
);

    assign ale10 = (a<=b);

endmodule