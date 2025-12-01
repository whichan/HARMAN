`timescale 1ns / 1ps

module font_rom(
    input [3:0] char_code,   // 0~9: 숫자, 10: ':', 15: 공백
    input [2:0] col,         // 0~7: 8픽셀 폭
    output reg [7:0] data
);

    // 8x8 폰트 데이터 (세로로 읽음)
    always @(*) begin
        case (char_code)
            // '0'
            4'd0: case (col)
                3'd0: data = 8'b00111100;
                3'd1: data = 8'b01000010;
                3'd2: data = 8'b01000010;
                3'd3: data = 8'b01000010;
                3'd4: data = 8'b01000010;
                3'd5: data = 8'b01000010;
                3'd6: data = 8'b00111100;
                3'd7: data = 8'b00000000;
            endcase
            
            // '1'
            4'd1: case (col)
                3'd0: data = 8'b00001000;
                3'd1: data = 8'b00011000;
                3'd2: data = 8'b00001000;
                3'd3: data = 8'b00001000;
                3'd4: data = 8'b00001000;
                3'd5: data = 8'b00001000;
                3'd6: data = 8'b00111110;
                3'd7: data = 8'b00000000;
            endcase
            
            // '2'
            4'd2: case (col)
                3'd0: data = 8'b00111100;
                3'd1: data = 8'b01000010;
                3'd2: data = 8'b00000010;
                3'd3: data = 8'b00001100;
                3'd4: data = 8'b00110000;
                3'd5: data = 8'b01000000;
                3'd6: data = 8'b01111110;
                3'd7: data = 8'b00000000;
            endcase
            
            // '3'
            4'd3: case (col)
                3'd0: data = 8'b00111100;
                3'd1: data = 8'b01000010;
                3'd2: data = 8'b00000010;
                3'd3: data = 8'b00011100;
                3'd4: data = 8'b00000010;
                3'd5: data = 8'b01000010;
                3'd6: data = 8'b00111100;
                3'd7: data = 8'b00000000;
            endcase
            
            // '4'
            4'd4: case (col)
                3'd0: data = 8'b00000100;
                3'd1: data = 8'b00001100;
                3'd2: data = 8'b00010100;
                3'd3: data = 8'b00100100;
                3'd4: data = 8'b01111110;
                3'd5: data = 8'b00000100;
                3'd6: data = 8'b00000100;
                3'd7: data = 8'b00000000;
            endcase
            
            // '5'
            4'd5: case (col)
                3'd0: data = 8'b01111110;
                3'd1: data = 8'b01000000;
                3'd2: data = 8'b01111100;
                3'd3: data = 8'b00000010;
                3'd4: data = 8'b00000010;
                3'd5: data = 8'b01000010;
                3'd6: data = 8'b00111100;
                3'd7: data = 8'b00000000;
            endcase
            
            // '6'
            4'd6: case (col)
                3'd0: data = 8'b00111100;
                3'd1: data = 8'b01000000;
                3'd2: data = 8'b01000000;
                3'd3: data = 8'b01111100;
                3'd4: data = 8'b01000010;
                3'd5: data = 8'b01000010;
                3'd6: data = 8'b00111100;
                3'd7: data = 8'b00000000;
            endcase
            
            // '7'
            4'd7: case (col)
                3'd0: data = 8'b01111110;
                3'd1: data = 8'b00000010;
                3'd2: data = 8'b00000100;
                3'd3: data = 8'b00001000;
                3'd4: data = 8'b00010000;
                3'd5: data = 8'b00010000;
                3'd6: data = 8'b00010000;
                3'd7: data = 8'b00000000;
            endcase
            
            // '8'
            4'd8: case (col)
                3'd0: data = 8'b00111100;
                3'd1: data = 8'b01000010;
                3'd2: data = 8'b01000010;
                3'd3: data = 8'b00111100;
                3'd4: data = 8'b01000010;
                3'd5: data = 8'b01000010;
                3'd6: data = 8'b00111100;
                3'd7: data = 8'b00000000;
            endcase
            
            // '9'
            4'd9: case (col)
                3'd0: data = 8'b00111100;
                3'd1: data = 8'b01000010;
                3'd2: data = 8'b01000010;
                3'd3: data = 8'b00111110;
                3'd4: data = 8'b00000010;
                3'd5: data = 8'b00000010;
                3'd6: data = 8'b00111100;
                3'd7: data = 8'b00000000;
            endcase
            
            // ':' (콜론)
            4'd10: case (col)
                3'd0: data = 8'b00000000;
                3'd1: data = 8'b00000000;
                3'd2: data = 8'b00011000;
                3'd3: data = 8'b00000000;
                3'd4: data = 8'b00011000;
                3'd5: data = 8'b00000000;
                3'd6: data = 8'b00000000;
                3'd7: data = 8'b00000000;
            endcase
            
            // 공백
            default: data = 8'b00000000;
        endcase
    end

endmodule