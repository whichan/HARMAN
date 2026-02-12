`timescale 1ns / 1ps

module MCU (
    input logic clk,
    input logic reset
);

    logic [31:0] instrCode;
    logic [31:0] instrMemAddr;
    logic        busWe;
    logic [31:0] busAddr;
    logic [31:0] busWData;
    logic [31:0] busRData;

    ROM U_ROM (
        .addr(instrMemAddr),
        .data(instrCode)
    );

    CPU_RV32I U_RV32I_CORE (
        .clk         (clk),
        .reset       (reset),
        .instrCode   (instrCode),
        .instrMemAddr(instrMemAddr),
        .busWe       (busWe),
        .busAddr     (busAddr),
        .busWData    (busWData),
        .busRData    (busRData)
    );

    RAM U_RAM (
        .clk  (clk),
        .we   (busWe),
        .addr (busAddr[9:0]),
        .wdata(busWData),
        .rdata(busRData)
    );

endmodule
