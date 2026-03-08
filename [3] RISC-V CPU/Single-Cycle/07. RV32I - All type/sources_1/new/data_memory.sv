`timescale 1ns / 1ps

module data_memory(
    input         clk,
    input         d_we,
    input         wr_en,
    input  [ 6:0] daddr,
    input  [31:0] dwdata,
    output [31:0] drdata
    );
    
    //word addressing
    logic [31:0] data_ram [0:127];

    //write SL
    always_ff @( posedge clk ) begin 
        if(d_we) begin
            data_ram[daddr] <= dwdata;
        end
    end
    
    //read CL
    assign drdata = data_ram[daddr];
     
endmodule