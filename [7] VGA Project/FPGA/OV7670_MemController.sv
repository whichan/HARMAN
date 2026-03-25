`timescale 1ns / 1ps


module OV7670_MemController (
    input  logic                       pclk,
    input  logic                       reset,
    //OV7670 side
    input  logic                       href,
    input  logic                       vsync,
    input  logic [                7:0] data,
    //mem side
    output logic                       we,
    output logic [$clog2(320*240)-1:0] wAddr,
    output logic [               15:0] wData
);
    logic pixelToggle;
    logic [15:0] pixelData;
    assign wData = pixelData;

    always_ff @(posedge pclk or posedge reset) begin
        if (reset) begin
            pixelData   <= 0;
            pixelToggle <= 0;
            we          <= 0;
            wAddr       <= 0;
        end else begin
            if (href) begin
                if (pixelToggle == 1'b0) begin  // even number
                    we              <= 1'b0;
                    pixelData[15:8] <= data;
                    pixelToggle     <= ~pixelToggle;
                end else begin
                    we             <= 1'b1;
                    pixelData[7:0] <= data;
                    pixelToggle    <= ~pixelToggle;
                    wAddr          <= wAddr + 1;
                end
            end else if (vsync) begin
                pixelToggle <= 0;
                we          <= 0;
                wAddr       <= 0;
            end
        end
    end

endmodule
