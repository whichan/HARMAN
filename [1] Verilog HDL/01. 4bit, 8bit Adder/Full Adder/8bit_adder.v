`timescale 1ns / 1ps

module full_adder_8bit(
    input [7:0] a,
    input [7:0] b,
    input cin,
    output [7:0] sum,
    output carry_out
    );
    
    wire w_carry;

        full_adder_4bit FFA0(
        .a(a[3:0]),
        .b(b[3:0]),
        .cin(1'b0),
        .sum(sum[3:0]),
        .carry_out(w_carry)
    );

         full_adder_4bit FFA1(
        .a(a[7:4]),
        .b(b[7:4]),
        .cin(w_carry),
        .sum(sum[7:4]),
        .carry_out(carry_out)
    );
    
endmodule
