`timescale 1 ns / 1 ps

module my_I2C_v1_0 #(
    // Users to add parameters here

    // User parameters ends
    // Do not modify the parameters beyond this line


    // Parameters of Axi Slave Bus Interface S00_AXI
    parameter integer C_S00_AXI_DATA_WIDTH = 32,
    parameter integer C_S00_AXI_ADDR_WIDTH = 4
) (
    // Users to add ports here

    output wire SCL,
    inout  wire SDA,
    // User ports ends
    // Do not modify the ports beyond this line


    // Ports of Axi Slave Bus Interface S00_AXI
    input wire s00_axi_aclk,
    input wire s00_axi_aresetn,
    input wire [C_S00_AXI_ADDR_WIDTH-1 : 0] s00_axi_awaddr,
    input wire [2 : 0] s00_axi_awprot,
    input wire s00_axi_awvalid,
    output wire s00_axi_awready,
    input wire [C_S00_AXI_DATA_WIDTH-1 : 0] s00_axi_wdata,
    input wire [(C_S00_AXI_DATA_WIDTH/8)-1 : 0] s00_axi_wstrb,
    input wire s00_axi_wvalid,
    output wire s00_axi_wready,
    output wire [1 : 0] s00_axi_bresp,
    output wire s00_axi_bvalid,
    input wire s00_axi_bready,
    input wire [C_S00_AXI_ADDR_WIDTH-1 : 0] s00_axi_araddr,
    input wire [2 : 0] s00_axi_arprot,
    input wire s00_axi_arvalid,
    output wire s00_axi_arready,
    output wire [C_S00_AXI_DATA_WIDTH-1 : 0] s00_axi_rdata,
    output wire [1 : 0] s00_axi_rresp,
    output wire s00_axi_rvalid,
    input wire s00_axi_rready
);

    wire       I2C_En;
    wire       I2C_start;
    wire       I2C_stop;
    wire [7:0] tx_data;
    wire       tx_done;
    wire       tx_ready;
    wire [7:0] rx_data;
    wire       rx_done;
    // Instantiation of Axi Bus Interface S00_AXI
    my_I2C_v1_0_S00_AXI #(
        .C_S_AXI_DATA_WIDTH(C_S00_AXI_DATA_WIDTH),
        .C_S_AXI_ADDR_WIDTH(C_S00_AXI_ADDR_WIDTH)
    ) my_I2C_v1_0_S00_AXI_inst (
        .I2C_En       (I2C_En),
        .I2C_start    (I2C_start),
        .I2C_stop     (I2C_stop),
        .tx_data      (tx_data),
        .tx_done      (tx_done),
        .tx_ready     (tx_ready),
        .rx_data      (rx_data),
        .rx_done      (rx_done),
        .S_AXI_ACLK   (s00_axi_aclk),
        .S_AXI_ARESETN(s00_axi_aresetn),
        .S_AXI_AWADDR (s00_axi_awaddr),
        .S_AXI_AWPROT (s00_axi_awprot),
        .S_AXI_AWVALID(s00_axi_awvalid),
        .S_AXI_AWREADY(s00_axi_awready),
        .S_AXI_WDATA  (s00_axi_wdata),
        .S_AXI_WSTRB  (s00_axi_wstrb),
        .S_AXI_WVALID (s00_axi_wvalid),
        .S_AXI_WREADY (s00_axi_wready),
        .S_AXI_BRESP  (s00_axi_bresp),
        .S_AXI_BVALID (s00_axi_bvalid),
        .S_AXI_BREADY (s00_axi_bready),
        .S_AXI_ARADDR (s00_axi_araddr),
        .S_AXI_ARPROT (s00_axi_arprot),
        .S_AXI_ARVALID(s00_axi_arvalid),
        .S_AXI_ARREADY(s00_axi_arready),
        .S_AXI_RDATA  (s00_axi_rdata),
        .S_AXI_RRESP  (s00_axi_rresp),
        .S_AXI_RVALID (s00_axi_rvalid),
        .S_AXI_RREADY (s00_axi_rready)
    );

    // Add user logic here
    I2C_MASTER u_i2c_master (
        .clk      (s00_axi_aclk),
        .reset    (~s00_axi_aresetn),
        .I2C_En   (I2C_En),
        .I2C_start(I2C_start),
        .I2C_stop (I2C_stop),
        .tx_data  (tx_data),
        .tx_done  (tx_done),
        .tx_ready (tx_ready),
        .rx_data  (rx_data),
        .rx_done  (rx_done),
        .SCL      (SCL),
        .SDA      (SDA)
    );
    // User logic ends

endmodule

module I2C_MASTER (
    input  wire       clk,
    input  wire       reset,
    input  wire       I2C_En,
    input  wire       I2C_start,
    input  wire       I2C_stop,
    input  wire [7:0] tx_data,
    output wire       tx_done,
    output wire       tx_ready,
    output wire [7:0] rx_data,
    output wire       rx_done,
    output wire       SCL,
    inout  wire       SDA
);

    // =====================================
    // SystemVerilog enum -> Verilog localparam
    // =====================================
    localparam [4:0] 
        IDLE   = 5'd0,
        START1 = 5'd1,
        START2 = 5'd2,
        DATA1  = 5'd3,
        DATA2  = 5'd4,
        DATA3  = 5'd5,
        DATA4  = 5'd6,
        READ1  = 5'd7,
        READ2  = 5'd8,
        READ3  = 5'd9,
        READ4  = 5'd10,
        WACK1  = 5'd11,
        WACK2  = 5'd12,
        WACK3  = 5'd13,
        WACK4  = 5'd14,
        RACK1  = 5'd15,
        RACK2  = 5'd16,
        RACK3  = 5'd17,
        RACK4  = 5'd18,
        HOLD   = 5'd19,
        STOP1  = 5'd20,
        STOP2  = 5'd21;

    reg [4:0] state, state_n;

    // =====================================
    // logic -> reg 변환
    // =====================================
    reg r_sda_out, r_sda_out_n;
    reg r_sda_oe, r_sda_oe_n;

    // Verilog에서는 'hz 대신 'bz를 사용합니다
    assign SDA = (r_sda_oe) ? r_sda_out : 1'bz;

    reg r_SCL, r_SCL_n;
    reg [8:0] clk_cnt, clk_cnt_n;
    reg [2:0] bit_cnt, bit_cnt_n;
    reg [7:0] r_tx_data, r_tx_data_n;
    reg [7:0] r_rx_data, r_rx_data_n;
    reg r_tx_done, r_tx_done_n;
    reg r_tx_ready, r_tx_ready_n;
    reg r_rx_done, r_rx_done_n;
    reg r_reading, r_reading_n;

    assign rx_data  = r_rx_data;
    assign tx_done  = r_tx_done;
    assign tx_ready = r_tx_ready;
    assign rx_done  = r_rx_done;
    assign SCL      = r_SCL;

    // =====================================
    // always_ff -> always @(posedge clk)
    // =====================================
    always @(posedge clk) begin
        if (reset) begin
            state      <= IDLE;
            r_sda_out  <= 1'b0;
            r_sda_oe   <= 1'b0;
            r_SCL      <= 1'b1;
            clk_cnt    <= 9'd0;
            bit_cnt    <= 3'd0;
            r_tx_data  <= 8'd0;
            r_tx_done  <= 1'b0;
            r_tx_ready <= 1'b0;
            r_rx_data  <= 8'd0;
            r_rx_done  <= 1'b0;
            r_reading  <= 1'b0;
        end else begin
            state      <= state_n;
            r_sda_out  <= r_sda_out_n;
            r_sda_oe   <= r_sda_oe_n;
            r_SCL      <= r_SCL_n;
            clk_cnt    <= clk_cnt_n;
            bit_cnt    <= bit_cnt_n;
            r_tx_data  <= r_tx_data_n;
            r_tx_done  <= r_tx_done_n;
            r_tx_ready <= r_tx_ready_n;
            r_rx_data  <= r_rx_data_n;
            r_rx_done  <= r_rx_done_n;
            r_reading  <= r_reading_n;
        end
    end

    // =====================================
    // always_comb -> always @*
    // =====================================
    always @* begin
        state_n      = state;
        r_sda_out_n  = r_sda_out;
        r_sda_oe_n   = r_sda_oe;
        r_SCL_n      = r_SCL;
        clk_cnt_n    = clk_cnt;
        bit_cnt_n    = bit_cnt;
        r_tx_data_n  = r_tx_data;
        r_tx_done_n  = r_tx_done;
        r_tx_ready_n = r_tx_ready;
        r_rx_data_n  = r_rx_data;
        r_rx_done_n  = r_rx_done;
        r_reading_n  = r_reading;

        case (state)
            IDLE: begin
                r_sda_oe_n   = 1'b0;
                r_sda_out_n  = 1'b0;
                r_SCL_n      = 1'b1;
                r_tx_done_n  = 1'b0;
                r_tx_ready_n = 1'b1;
                r_rx_done_n  = 1'b0;
                r_reading_n  = 1'b0;

                if (I2C_En) begin
                    clk_cnt_n    = 9'd0;
                    r_tx_ready_n = 1'b0;
                    state_n      = START1;
                end
            end

            START1: begin
                r_sda_oe_n  = 1'b1;
                r_sda_out_n = 1'b0;
                r_SCL_n     = 1'b1;

                if (clk_cnt == 9'd499) begin
                    clk_cnt_n = 9'd0;
                    state_n   = START2;
                end else begin
                    clk_cnt_n = clk_cnt + 1'b1;
                end
            end

            START2: begin
                r_sda_oe_n  = 1'b1;
                r_sda_out_n = 1'b0;
                r_SCL_n     = 1'b0;

                if (clk_cnt == 9'd499) begin
                    clk_cnt_n   = 9'd0;
                    r_tx_data_n = tx_data;
                    state_n     = DATA1;
                end else begin
                    clk_cnt_n = clk_cnt + 1'b1;
                end
            end

            DATA1: begin
                r_sda_oe_n  = ~r_tx_data[7];
                r_sda_out_n = 1'b0;
                r_SCL_n     = 1'b0;

                if (clk_cnt == 9'd249) begin
                    clk_cnt_n = 9'd0;
                    state_n   = DATA2;
                end else begin
                    clk_cnt_n = clk_cnt + 1'b1;
                end
            end

            DATA2: begin
                r_sda_oe_n  = ~r_tx_data[7];
                r_sda_out_n = 1'b0;
                r_SCL_n     = 1'b1;

                if (clk_cnt == 9'd249) begin
                    clk_cnt_n = 9'd0;
                    state_n   = DATA3;
                end else begin
                    clk_cnt_n = clk_cnt + 1'b1;
                end
            end

            DATA3: begin
                r_sda_oe_n  = ~r_tx_data[7];
                r_sda_out_n = 1'b0;
                r_SCL_n     = 1'b1;

                if (clk_cnt == 9'd249) begin
                    clk_cnt_n = 9'd0;

                    if (bit_cnt == 3'd7) begin
                        bit_cnt_n = 3'd0;
                        state_n   = WACK1;
                    end else begin
                        bit_cnt_n   = bit_cnt + 1'b1;
                        r_tx_data_n = {r_tx_data[6:0], 1'b0};
                        state_n     = DATA4;
                    end
                end else begin
                    clk_cnt_n = clk_cnt + 1'b1;
                end
            end

            DATA4: begin
                r_sda_oe_n  = ~r_tx_data[7];
                r_sda_out_n = 1'b0;
                r_SCL_n     = 1'b0;

                if (clk_cnt == 9'd249) begin
                    clk_cnt_n = 9'd0;
                    state_n   = DATA1;
                end else begin
                    clk_cnt_n = clk_cnt + 1'b1;
                end
            end

            WACK1: begin
                r_sda_oe_n = 1'b0;
                r_SCL_n    = 1'b0;

                if (clk_cnt == 9'd249) begin
                    clk_cnt_n = 9'd0;
                    state_n   = WACK2;
                end else begin
                    clk_cnt_n = clk_cnt + 1'b1;
                end
            end

            WACK2: begin
                r_sda_oe_n = 1'b0;
                r_SCL_n    = 1'b1;

                if (clk_cnt == 9'd249) begin
                    clk_cnt_n = 9'd0;
                    state_n   = WACK3;
                end else begin
                    clk_cnt_n = clk_cnt + 1'b1;
                end
            end

            WACK3: begin
                r_sda_oe_n = 1'b0;
                r_SCL_n    = 1'b1;

                if (clk_cnt == 9'd249) begin
                    clk_cnt_n = 9'd0;
                    state_n   = WACK4;
                end else begin
                    clk_cnt_n = clk_cnt + 1'b1;
                end
            end

            WACK4: begin
                r_sda_oe_n = 1'b0;
                r_SCL_n    = 1'b0;

                if (clk_cnt == 9'd249) begin
                    clk_cnt_n = 9'd0;
                    state_n   = HOLD;
                end else begin
                    clk_cnt_n = clk_cnt + 1'b1;
                end
            end

            HOLD: begin
                if ((I2C_start == 1'b0) && (I2C_stop == 1'b0)) begin
                    r_tx_data_n = tx_data;
                    bit_cnt_n   = 3'd0;
                    state_n     = DATA1;
                end else if ((I2C_start == 1'b0) && (I2C_stop == 1'b1)) begin
                    state_n = STOP1;
                end
            end

            STOP1: begin
                r_sda_oe_n  = 1'b1;
                r_sda_out_n = 1'b0;
                r_SCL_n     = 1'b1;

                if (clk_cnt == 9'd499) begin
                    clk_cnt_n = 9'd0;
                    state_n   = STOP2;
                end else begin
                    clk_cnt_n = clk_cnt + 1'b1;
                end
            end

            STOP2: begin
                r_sda_oe_n = 1'b0;
                r_SCL_n    = 1'b1;

                if (clk_cnt == 9'd499) begin
                    clk_cnt_n   = 9'd0;
                    r_tx_done_n = 1'b1;
                    state_n     = IDLE;
                end else begin
                    clk_cnt_n = clk_cnt + 1'b1;
                end
            end

            default: state_n = IDLE;

        endcase
    end

endmodule