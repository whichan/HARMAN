`timescale 1ns / 1ps

module AXI4_lite_Slave (
    // Global Signal
    input  logic        ACLK,
    input  logic        ARESETn,
    // WRITE Transaction, AW Channel
    input  logic [ 3:0] AWADDR,
    input  logic        AWVALID,
    output logic        AWREADY,
    // WRITE Transaction, W Channel
    input  logic [31:0] WDATA,
    input  logic        WVALID,
    output logic        WREADY,
    // WRITE Transaction, B Channel
    output logic [ 1:0] BRESP,
    output logic        BVALID,
    input  logic        BREADY,

    // READ Transaction, AR Channel
    input  logic [3:0] ARADDR,
    input  logic       ARVALID,
    output logic       ARREADY,

    // READ Transaction, R Channel
    output logic [31:0] RDATA,
    output logic        RVALID,
    input  logic        RREADY,
    output logic [ 1:0] RRESP
);

  logic [31:0] slv_reg0, slv_reg1, slv_reg2, slv_reg3;

  logic [3:0] aw_addr_reg, aw_addr_next;
  logic [3:0] ar_addr_reg, ar_addr_next;


  //WRITE Transaction , Write Address transfer
  typedef enum {
    AW_IDLE,
    AW_READY
  } aw_state_t;
  aw_state_t aw_state, aw_state_next;

  always_ff @(posedge ACLK) begin
    if (!ARESETn) begin
      aw_state <= AW_IDLE;
      aw_addr_reg <= 4'b0;
    end else begin
      aw_state <= aw_state_next;
      aw_addr_reg <= aw_addr_next;
    end
  end

  always_comb begin
    aw_state_next = aw_state;
    aw_addr_next = aw_addr_reg;
    AWREADY = 1'b0;
    case (aw_state)
      AW_IDLE: begin
        AWREADY = 1'b0;
        if (AWVALID) begin
          aw_state_next = AW_READY;
          aw_addr_next  = AWADDR;
        end
      end

      AW_READY: begin
        AWREADY = 1'b1;
        if (AWVALID && AWREADY) begin
          aw_state_next = AW_IDLE;
        end
      end
    endcase
  end

  //WRITE Transaction, W Channel transfer
  typedef enum {
    W_IDLE,
    W_READY
  } w_state_t;

  w_state_t w_state, w_state_next;

  always_ff @(posedge ACLK) begin
    if (!ARESETn) begin
      w_state  <= W_IDLE;
      slv_reg0 <= 32'd0;
      slv_reg1 <= 32'd0;
      slv_reg2 <= 32'd0;
      slv_reg3 <= 32'd0;

    end else begin
      w_state <= w_state_next;
      if (w_state == W_READY && WVALID && WREADY) begin
        case (aw_addr_reg[3:2])
          2'd0: slv_reg0 <= WDATA;
          2'd1: slv_reg1 <= WDATA;
          2'd2: slv_reg2 <= WDATA;
          2'd3: slv_reg3 <= WDATA;
        endcase
      end
    end
  end

  always_comb begin
    w_state_next = w_state;
    WREADY = 1'b0;
    case (w_state)
      W_IDLE: begin
        WREADY = 1'b0;
        if (AWREADY) begin
          w_state_next = W_READY;
        end
      end

      W_READY: begin
        WREADY = 1'b1;
        if (WVALID) begin
          w_state_next = W_IDLE;
        end
      end
    endcase
  end

  //WRITE Transaction, B Channel transfer
  typedef enum {
    B_IDLE,
    B_VALID
  } b_state_t;
  b_state_t b_state, b_state_next;

  always_ff @(posedge ACLK) begin
    if (!ARESETn) begin
      b_state <= B_IDLE;
    end else begin
      b_state <= b_state_next;
    end
  end

  always_comb begin
    b_state_next = b_state;
    BRESP = 2'b00;
    BVALID = 1'b0;
    case (b_state)
      B_IDLE: begin
        BVALID = 1'b0;
        if (WVALID && WREADY) b_state_next = B_VALID;
      end

      B_VALID: begin
        BRESP  = 2'b00;
        BVALID = 1'b1;
        if (BREADY) b_state_next = B_IDLE;
      end
    endcase
  end


  //READ Transaction, AR(Read Address) Channel transfer
  typedef enum {
    AR_IDLE,
    AR_READY
  } ar_state_t;
  ar_state_t ar_state, ar_state_next;

  always_ff @(posedge ACLK) begin
    if (!ARESETn) begin
      ar_state <= AR_IDLE;
      ar_addr_reg <= 4'b0;
    end else begin
      ar_state <= ar_state_next;
      ar_addr_reg <= ar_addr_next;
    end
  end

  always_comb begin
    ARREADY = 1'b0;
    ar_state_next = ar_state;
    ar_addr_next = ar_addr_reg;

    case (ar_state)
      AR_IDLE: begin
        ARREADY = 1'b0;
        if (ARVALID) begin
          ar_state_next = AR_READY;
          ar_addr_next  = ARADDR;
        end
      end

      AR_READY: begin
        ARREADY = 1'b1;
        if (ARVALID && ARREADY) begin
          ar_state_next = AR_IDLE;
        end
      end
    endcase
  end


  //READ Transaction, R(Read) Channel transfer
  typedef enum {
    R_IDLE,
    R_VALID
  } r_state_t;
  r_state_t r_state, r_state_next;

  always_ff @(posedge ACLK) begin
    if (!ARESETn) begin
      r_state <= R_IDLE;
    end else begin
      r_state <= r_state_next;
    end
  end

  always_comb begin
    RVALID = 1'b0;
    RRESP = 1'b0;
    r_state_next = r_state;

    case (r_state)
      R_IDLE: begin
        RVALID = 1'b0;
        if (ARREADY) begin
          r_state_next = R_VALID;
        end
      end

      R_VALID: begin
        RVALID = 1'b1;
        RRESP  = 1'b0;
        case (ar_addr_reg[3:2])
          2'd0: RDATA = slv_reg0;
          2'd1: RDATA = slv_reg1;
          2'd2: RDATA = slv_reg2;
          2'd3: RDATA = slv_reg3;
        endcase
        if (RREADY) begin
          r_state_next = R_IDLE;
        end
      end
    endcase
  end
endmodule
