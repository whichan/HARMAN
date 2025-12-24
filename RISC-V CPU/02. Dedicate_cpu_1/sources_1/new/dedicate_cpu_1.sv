`timescale 1ns / 1ps

module dedicate_cpu_1(
    input clk,
    input reset,
    output [7:0] out
    );

    logic src_sel, a_load, out_sel, alt_10;

    datapath u_datapath(
        .*,
        .out(out)
    );

    control_unit u_control_unit(
        .*
    );

endmodule

module control_unit(
    input clk,
    input reset,
    input alt_10,
    output logic src_sel,
    output logic a_load,
    output logic out_sel
);

    typedef enum logic [2:0] { S0, S1, S2, S3, S4 } state_t;

    state_t  current_state, next_state;

    assign src_sel = (current_state == S3) ? 1'b1 : 1'b0;
    assign a_load = (current_state == S0 | current_state == S3) ? 1'b1 : 1'b0;
    assign out_sel = (current_state == S2) ? 1'b1 : 1'b0;

    logic next_src_sel, next_a_load, next_out_sel;

    always_ff @( posedge clk or posedge reset ) begin : blockName
        if(reset) begin
            current_state <= S0;
            // src_sel <= 0;
            // a_load <= 1; //처음에 바로 a=0으로 되도록 (reset되면 바로 다음 cycle에 출력이 나가도록)
            // out_sel <= 0;
        end else begin
            current_state <= next_state;
            // src_sel <= next_src_sel;
            // a_load <= next_a_load;
            // out_sel <= next_out_sel;
        end
    end

    always_comb begin
        next_state = current_state;
        src_sel = 0;
        a_load = 0;
        out_sel = 0;
        // next_src_sel = src_sel;
        // next_a_load = a_load;
        // next_out_sel = out_sel;
        
        case(current_state)
            S0: begin
                //a = 0;
                // next_state & output
                src_sel = 0;
                a_load = 1;
                out_sel = 0;
                next_state = S1;
            end

            S1: begin
                //a < 10 (branch)
                //a가 10보다 작냐?
                out_sel = 0;

                if(alt_10) begin
                    next_state = S2; //S2로 갈 때 
                end else begin
                    next_state = S4; //halt로 보냄
                    
                end
            end

            S2: begin
                // a = a + 1
                // 연산된 결과를 더해줌
                //S3에서 나갈 결과를 처리
                next_state = S3;
                // next_src_sel = 1;
                // next_a_load = 1;
                // next_out_sel = 0;
                out_sel = 1;
            end

            S3: begin
                // a = a + 1;
                // next_src_sel = 1'b1;
                // next_a_load  = 1'b1;
                // next_out_sel = 1'b0;
                src_sel = 1; //from alu output
                a_load = 1; //store to reg A
                out_sel = 0; //출력 막기
                next_state = S1;
            end

            S4: begin
                // halt
                
                next_state = current_state;
            end

            default: next_state = S0;
        endcase
    end
endmodule

module datapath(
    input       clk,
    input       reset,
    input       src_sel,
    input       a_load,
    input       out_sel,
    output      alt_10, // a_less_than_10
                   // 참,거짓 판별이므로 1비트만 필요
    output [7:0] out
);

    wire [7:0] w_alu_out;
    wire [7:0] w_mux_out;
    wire [7:0] w_a_reg_out;

    assign out = (out_sel) ? w_a_reg_out : 8'hzz;

    mux_2x1 u_mux_2x1 (
        .a(8'h0),
        .b(w_alu_out),
        .src_sel(src_sel),
        .mux_out(w_mux_out)
    );

    a_reg u_a_reg (
        .clk(clk),
        .reset(reset),
        .a_load(a_load),
        .data_in(w_mux_out),
        .data_out(w_a_reg_out)
    );

    alu u_alu(
        .a(w_a_reg_out),
        .b(8'h01),
        .alu_out(w_alu_out)
    );

    comparator_alt_10 u_comparator_alt_10(
        .a_reg_out(w_a_reg_out),
        .alt_10(alt_10)
    );

endmodule

module mux_2x1(
    input [7:0] a,
    input [7:0] b,
    input src_sel,
    output [7:0] mux_out
);

    assign mux_out = src_sel ? b : a;
    
endmodule

module a_reg(
    input        clk,
    input        reset,
    input        a_load,
    input  [7:0] data_in,
    output [7:0] data_out
);

    logic [7:0] a_reg;

    always_ff @( posedge clk or posedge reset ) begin
        if(reset) begin
            a_reg <= 0;
        end else begin
            if(a_load) begin
            a_reg <= data_in;
            end
        end 
    end

    assign data_out = a_reg;
endmodule


module alu(
    input [7:0] a,
    input [7:0] b,
    output [7:0] alu_out
);
    assign alu_out = a + b;
endmodule

module comparator_alt_10(
    input [7:0] a_reg_out,
    output      alt_10
);

    assign alt_10 = (a_reg_out < 10) ? 1 : 0;
    //1이면 참이라는 뜻(10보다 작음)
endmodule




// `timescale 1ns / 1ps


// module cpu_0 (
//     input clk,
//     input reset,
//     output [7:0] out
// );

//   logic src_sel, a_load, out_sel, alt_10;

//   datapath u_datapath (
//       .*,
//       .out(out)
//   );

//   control_unit u_control_unit (.*);



// endmodule

// module control_unit (
//     input clk,
//     input reset,
//     input alt_10,
//     output logic src_sel,
//     output logic out_sel,
//     output logic a_load
// );

//   typedef enum logic [2:0]{
//     S0,
//     S1,
//     S2,
//     S3,
//     S4
//   } state_t;
//   state_t c_state, n_state;

//   logic n_a_load, n_src_sel, n_out_sel;
//   //C_없애고 output logic처리해서 그냥 연결함

//   always_ff @(posedge clk, posedge reset) begin
//     if (reset) begin
//       c_state <= S0;
//       src_sel <= 0;
//       a_load  <= 0;
//       out_sel <= 0;
//     end else begin
//       c_state <= n_state;
//       src_sel <= n_src_sel;
//       a_load  <= n_a_load;
//       out_sel <= n_out_sel;
//     end
//   end

//   always_comb begin

//     n_state   = c_state;
//     n_src_sel = src_sel;
//     n_a_load  = a_load;
//     n_out_sel = out_sel;

//     case (c_state)
//       S0: begin
//         n_src_sel = 0;
//         n_a_load  = 1;
//         n_out_sel = 1;
//         n_state   = S1;
//       end
//       S1: begin
//         // a<10;
//         n_src_sel = 1;
//         n_a_load  = 1;
//         n_out_sel = 0;
//         if (alt_10) n_state = S2;
//         else n_state = S4;
//       end
//       S2: begin
//         //out a
//         n_src_sel = 0;
//         n_a_load  = 0;
//         n_out_sel = 1;
//         n_state = S3;
//       end

//       S3: begin
//         //a = a + 1;
//         n_src_sel = 1;
//         n_a_load  = 1;
//         n_out_sel = 0;
//         n_state = S1;
//       end

//       S4: begin  
//         //halt
//         n_src_sel = 0;
//         n_a_load  = 0;
//         n_out_sel = 1;
//       end
//     endcase
//   end
// endmodule

// module datapath (
//     input        a_load,
//     input        src_sel,
//     input        clk,
//     input        reset,
//     input        out_sel,
//     output       alt_10,   //10미만 검사
//     output [7:0] out
// );

//   logic [7:0] w_alu_out;
//   logic [7:0] w_mux_out;
//   logic [7:0] w_a_reg_out;
//   assign out = (out_sel) ? w_a_reg_out : 8'hzz;


//   mux_2x1 u_mux (
//       .a(8'h00),
//       .b(w_alu_out),
//       .src_sel(src_sel),
//       .mux_out(w_mux_out)
//   );

//   a_reg u_a_reg (
//       .clk(clk),
//       .reset(reset),
//       .a_load(a_load),
//       .in_data(w_mux_out),
//       .out_data(w_a_reg_out)
//   );

//   alu U_ALU (
//       .a(w_a_reg_out),
//       .b(8'h01),
//       .alu_out(w_alu_out)
//   );

//   comparator_alt_10 U_compare_alt_10 (
//       .a_reg_out(w_a_reg_out),
//       .alt_10(alt_10)
//   );

// endmodule

// module mux_2x1 (
//     input        [7:0] a,
//     input        [7:0] b,
//     input              src_sel,
//     output logic [7:0] mux_out
// );
//   always_comb begin
//     if (src_sel) begin
//       mux_out <= b;
//     end else begin
//       mux_out <= a;
//     end
//   end
// endmodule

// module a_reg (
//     input clk,
//     input reset,
//     input a_load,
//     input [7:0] in_data,
//     output logic [7:0] out_data
// );

//   logic [7:0] a_reg;

//   always_ff @(posedge clk, posedge reset) begin
//     if (reset) begin
//       out_data <= 0;
//     end else begin
//       if (a_load) begin
//         a_reg <= in_data;
//       end
//     end
//   end

//   assign out_data = a_reg;
// endmodule

// module alu (
//     input  [7:0] a,
//     input  [7:0] b,
//     output [7:0] alu_out
// );
//   assign alu_out = a + b;

// endmodule

// module comparator_alt_10 (
//     input  [7:0] a_reg_out,
//     output       alt_10
// );
//   assign alt_10 = (a_reg_out < 10) ? 1 : 0;

// endmodule