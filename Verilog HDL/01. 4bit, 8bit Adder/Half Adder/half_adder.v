`timescale 1ns / 1ps



module adder(
 
    input wire a,b,
    output sum, carry_out //별도의 언급이 없으면 wire
);

    assign sum = a ^ b;
    assign carry_out = a & b;
    
endmodule