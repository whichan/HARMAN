`timescale 1ns / 1ps

module ram(
    input clk,
    input [9:0] addr,
    input [7:0] wdata,
    input we,

    output logic [7:0] rdata
);

    // memory
    logic [7:0] ram [0:1023];
    

    // write to memory
    always_ff @(posedge clk) begin
        if(we) begin //we=1일 때
            ram[addr] <= wdata; 
        end
    end
    

    // read to memory
    
    always_ff @( posedge clk ) begin
        if(!we) begin
            rdata <= ram[addr];
        end
    end
    
    //assign rdata = ram[addr];

endmodule