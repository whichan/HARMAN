`timescale 1ns / 1ps

module APB_Master (
    // global signals
    input  logic        PCLK,
    input  logic        PRESET,
    // APB Interface Signals
    output logic [31:0] PADDR,
    output logic        PWRITE,
    output logic        PENABLE,
    output logic [31:0] PWDATA,
    output logic        PSEL0,
    output logic        PSEL1,
    output logic        PSEL2,
    output logic        PSEL3,
    input  logic [31:0] PRDATA0,
    input  logic [31:0] PRDATA1,
    input  logic [31:0] PRDATA2,
    input  logic [31:0] PRDATA3,
    input  logic        PREADY0,
    input  logic        PREADY1,
    input  logic        PREADY2,
    input  logic        PREADY3,
    // Internal Interface Signals
    input  logic        transfer,
    output logic        ready,
    input  logic        write,
    input  logic [31:0] addr,
    input  logic [31:0] wdata,
    output logic [31:0] rdata
);
  logic temp_write_reg, temp_write_next;
  logic [31:0] temp_addr_reg, temp_addr_next;
  logic [31:0] temp_wdata_reg, temp_wdata_next;
  logic decoder_en;
  logic [3:0] psel;
  logic [1:0] mux_sel;

  assign PSEL0 = psel[0];
  assign PSEL1 = psel[1];
  assign PSEL2 = psel[2];
  assign PSEL3 = psel[3];

  typedef enum {
    IDLE,
    SETUP,
    ACCESS
  } apb_state_t;

  apb_state_t apb_state, apb_state_next;

  always_ff @(posedge PCLK, posedge PRESET) begin
    if (PRESET) begin
      apb_state      <= IDLE;
      temp_write_reg <= 0;
      temp_addr_reg  <= 0;
      temp_wdata_reg <= 0;
    end else begin
      apb_state      <= apb_state_next;
      temp_write_reg <= temp_write_next;
      temp_addr_reg  <= temp_addr_next;
      temp_wdata_reg <= temp_wdata_next;
    end
  end

  always_comb begin
    apb_state_next  = apb_state;
    temp_write_next = temp_write_reg;
    temp_addr_next  = temp_addr_reg;
    temp_wdata_next = temp_wdata_reg;
    PWRITE          = temp_write_reg;
    PADDR           = temp_addr_reg;
    PWDATA          = temp_wdata_reg;
    PENABLE         = 1'b0;
    decoder_en      = 1'b0;
    case (apb_state)
      IDLE: begin
        decoder_en = 1'b0;
        PENABLE = 1'b0;
        if (transfer) begin
          apb_state_next  = SETUP;
          temp_write_next = write;  // latching data
          temp_addr_next  = addr;  // latching data
          temp_wdata_next = wdata;  // latching data
        end
      end
      SETUP: begin
        decoder_en     = 1'b1;
        apb_state_next = ACCESS;
        PENABLE        = 1'b0;
        PADDR          = temp_addr_reg;
        PWRITE         = temp_write_reg;
        PWDATA         = temp_wdata_reg;
      end
      ACCESS: begin
        decoder_en = 1'b1;
        PENABLE = 1'b1;
        if (ready & !transfer) begin
          apb_state_next = IDLE;
        end else if (ready & transfer) begin
          apb_state_next = SETUP;
        end else begin
          apb_state_next = ACCESS;
        end
      end
    endcase
  end

  APB_Decoder U_APB_DECODER (
      .en     (decoder_en),
      .sel    (temp_addr_reg),
      .y      (psel),
      .mux_sel(mux_sel)
  );

  APB_Mux U_APB_MUX (
      .sel   (mux_sel),
      .rdata0(PRDATA0),
      .rdata1(PRDATA1),
      .rdata2(PRDATA2),
      .rdata3(PRDATA3),
      .ready0(PREADY0),
      .ready1(PREADY1),
      .ready2(PREADY2),
      .ready3(PREADY3),
      .rdata (rdata),
      .ready (ready)
  );
endmodule

module APB_Decoder (
    input  logic        en,
    input  logic [31:0] sel,
    output logic [ 3:0] y,
    output logic [ 1:0] mux_sel
);
  always_comb begin
    y = 0;
    if (en) begin
      casex (sel)
        32'h1000_0xxx: y = 4'b0001;  // RAM
        32'h1000_1xxx: y = 4'b0010;  // P1
        32'h1000_2xxx: y = 4'b0100;  // P2
        32'h1000_3xxx: y = 4'b1000;  // P3
        default: y = 0;
      endcase
    end
  end

  always_comb begin
    mux_sel = 0;
    if (en) begin
      casex (sel)
        32'h1000_0xxx: mux_sel = 2'd0;  // RAM
        32'h1000_1xxx: mux_sel = 2'd1;  // P1
        32'h1000_2xxx: mux_sel = 2'd2;  // P2
        32'h1000_3xxx: mux_sel = 2'd3;  // P3
        default: mux_sel = 0;
      endcase
    end
  end
endmodule

module APB_Mux (
    input  logic [ 1:0] sel,
    input  logic [31:0] rdata0,
    input  logic [31:0] rdata1,
    input  logic [31:0] rdata2,
    input  logic [31:0] rdata3,
    input  logic        ready0,
    input  logic        ready1,
    input  logic        ready2,
    input  logic        ready3,
    output logic [31:0] rdata,
    output logic        ready
);

  always_comb begin
    rdata = 0;
    ready = 0;
    case (sel)
      2'd0: begin
        rdata = rdata0;
        ready = ready0;
      end
      2'd1: begin
        rdata = rdata1;
        ready = ready1;
      end
      2'd2: begin
        rdata = rdata2;
        ready = ready2;
      end
      2'd3: begin
        rdata = rdata3;
        ready = ready3;
      end
      default: begin
        rdata = 0;
        ready = 0;
      end
    endcase
  end
endmodule
