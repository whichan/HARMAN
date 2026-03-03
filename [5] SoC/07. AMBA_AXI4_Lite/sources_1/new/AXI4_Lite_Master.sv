`timescale 1ns / 1ps
//
module AXI4_lite_Master (
    // Global Signal
    input  logic        ACLK,
    input  logic        ARESETn,
    // WRITE Transaction, AW Channel
    output logic [ 3:0] AWADDR,
    output logic        AWVALID,
    input  logic        AWREADY,
    // WRITE Transaction, W Channel
    output logic [31:0] WDATA,
    output logic        WVALID,
    input  logic        WREADY,
    // WRITE Transaction, B Channel
    input  logic [ 1:0] BRESP,
    input  logic        BVALID,
    output logic        BREADY,

    // READ Transaction, AR Channel
    output logic [3:0] ARADDR,
    output logic       ARVALID,
    input  logic       ARREADY,

    // READ Transaction, R Channel
    input  logic [31:0] RDATA,
    input  logic        RVALID,
    output logic        RREADY,
    input  logic [ 1:0] RRESP,

    // internal Signals
    input  logic        transfer,
    output logic        ready,
    input  logic [ 3:0] addr,
    input  logic [31:0] wdata,
    input  logic        write,
    output logic [31:0] rdata
);

  logic w_ready, r_ready;  //write에 대한 ready, read에 대한 ready
  //   assign ready = (write) ? w_ready : r_ready;
  assign ready = w_ready | r_ready;

  //WRITE Transaction, AW Channel transfer
  typedef enum {
    AW_IDLE,
    AW_VALID
  } aw_state_t;
  aw_state_t aw_state, aw_state_next;


  always_ff @(posedge ACLK) begin
    if (!ARESETn) begin
      aw_state <= AW_IDLE;
    end else begin
      aw_state <= aw_state_next;
    end
  end

  always_comb begin
    aw_state_next = aw_state;
    AWVALID = 1'b0;
    AWADDR = addr[3:0];
    case (aw_state)
      AW_IDLE: begin
        AWVALID = 1'b0;
        if (transfer & write) begin
          aw_state_next = AW_VALID;
        end
      end

      AW_VALID: begin
        AWVALID = 1'b1;
        AWADDR  = addr[3:0];
        if (AWREADY) begin
          aw_state_next = AW_IDLE;
        end
      end
    endcase
  end

  //WRITE Transaction, W Channel transfer
  typedef enum {
    W_IDLE,
    W_VALID
  } w_state_t;
  w_state_t w_state, w_state_next;

  always_ff @(posedge ACLK) begin
    if (!ARESETn) begin
      w_state <= W_IDLE;
    end else begin
      w_state <= w_state_next;
    end
  end

  always_comb begin
    w_state_next = w_state;
    WVALID = 1'b0;
    WDATA = wdata;
    case (w_state)
      W_IDLE: begin
        WVALID = 1'b0;
        if (transfer && write) begin
          w_state_next = W_VALID;
        end
      end
      W_VALID: begin
        WDATA  = wdata;
        WVALID = 1'b1;
        if (WREADY) begin
          w_state_next = W_IDLE;
        end
      end
    endcase
  end


  //WRITE Transaction, B Channel transfer
  typedef enum {
    B_IDLE,
    B_READY
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
    BREADY = 1'b0;
    w_ready = 1'b0;
    case (b_state)
      B_IDLE: begin
        BREADY  = 1'b0;
        w_ready = 1'b0;
        if (WVALID) begin
          b_state_next = B_READY;
        end
      end
      B_READY: begin
        BREADY = 1'b1;
        if (BVALID) begin  //slave에서 보내는 BVALID를 받아야 함
          w_ready = 1'b1;
          b_state_next = B_IDLE;
        end
      end
    endcase
  end


  //READ Transaction, AR Channel transfer
  typedef enum {
    AR_IDLE,
    AR_VALID
  } ar_state_t;
  ar_state_t ar_state, ar_state_next;

  always_ff @(posedge ACLK) begin
    if (!ARESETn) begin
      ar_state <= AR_IDLE;
    end else begin
      ar_state <= ar_state_next;
    end
  end

  always_comb begin
    ar_state_next = ar_state;
    ARADDR = addr[3:0];
    ARVALID = 1'b0;
    case (ar_state)
      AR_IDLE: begin
        ARVALID = 1'b0;
        if (transfer == 1'b1 && write == 1'b0) begin
          ar_state_next = AR_VALID;
        end
      end
      AR_VALID: begin
        ARADDR  = addr[3:0];
        ARVALID = 1'b1;
        if (ARVALID && ARREADY) begin
          ar_state_next = AR_IDLE;
        end
      end
    endcase
  end


  //READ Transaction, R Channel transfer
  typedef enum {
    R_IDLE,
    R_READY
  } r_state_e;
  r_state_e r_state, r_state_next;

  always_ff @(posedge ACLK) begin
    if (!ARESETn) begin
      r_state <= R_IDLE;
    end else begin
      r_state <= r_state_next;
    end
  end

  always_comb begin
    r_state_next = r_state;
    RREADY = 1'b0;
    rdata = RDATA;
    r_ready = 1'b0;
    case (r_state)
      R_IDLE: begin
        RREADY = 1'b0;
        if (ARVALID) begin
          r_state_next = R_READY;
        end
      end
      R_READY: begin
        RREADY = 1'b1;
        if (RVALID) begin
          rdata = RDATA;
          r_ready = 1'b1;
          r_state_next = R_IDLE;
        end
      end
    endcase
  end
endmodule
