`timescale 1ns / 1ps

// One external radix-4 iteration is implemented as two combinational
// radix-2 Montgomery steps.  The state remains in carry-save form for all
// 1024 input bits and is collapsed only after the last iteration.
module montgomery(
  input             clk,
  input             resetn,
  input             start,
  input    [1023:0] in_a,
  input    [1023:0] in_b,
  input    [1023:0] in_m,
  output   [1023:0] result,
  output            done
);

  localparam IDLE          = 4'b0000;
  localparam PRECOMPUTE_BM = 4'b0010;
  localparam LOAD_BIT_1    = 4'b0110;
  localparam LOAD_BITS     = 4'b0111;
  localparam COLLAPSE      = 4'b1011;
  localparam STORE_SUB     = 4'b1100;
  localparam OUTPUT_RESULT = 4'b1101;

  localparam ADDER_CMD_NONE      = 2'd0;
  localparam ADDER_CMD_B_PLUS_M  = 2'd1;
  localparam ADDER_CMD_COLLAPSE  = 2'd2;
  localparam ADDER_CMD_SUBTRACT  = 2'd3;

  reg [3:0] state;
  reg [1:0] adder_cmd;
  reg       issue_adder_pending;

  reg [1023:0] result_reg;
  reg          done_reg;
  reg [8:0]    iteration_count;
  reg [1023:0] a_shift_reg;

  // The two state words need three guard bits.  Each CSA is one bit wider
  // so that its shifted result can be written back without losing a guard.
  reg  [1026:0] c_sum_reg;
  reg  [1026:0] c_carry_reg;
  reg  [1026:0] b_plus_m_reg;

  wire [1027:0] state_sum_ext;
  wire [1027:0] state_carry_ext;
  wire [1027:0] b_ext;
  wire [1027:0] m_ext;
  wire [1027:0] b_plus_m_ext;

  wire          x0;
  wire          x1;
  wire          q0;
  wire          q1;
  reg  [1027:0] d0;
  reg  [1027:0] d1;

  wire [1027:0] csa_sum_1;
  wire [1027:0] csa_carry_1;
  wire [1027:0] mid_sum;
  wire [1027:0] mid_carry;
  wire [1027:0] csa_sum_2;
  wire [1027:0] csa_carry_2;
  wire [1027:0] next_sum;
  wire [1027:0] next_carry;

  wire [1027:0] adder_result;
  wire          adder_done;
  wire          adder_start;
  reg           adder_load_subtract;
  reg  [1026:0] adder_load_a;
  reg  [1026:0] adder_load_b;

  assign state_sum_ext   = {1'b0, c_sum_reg};
  assign state_carry_ext = {1'b0, c_carry_reg};
  assign b_ext           = {4'b0, in_b};
  assign m_ext           = {4'b0, in_m};
  assign b_plus_m_ext    = {1'b0, b_plus_m_reg};

  assign x0 = a_shift_reg[0];
  assign x1 = a_shift_reg[1];

  // Montgomery reduction requires an odd modulus.  Adding q*M therefore
  // toggles the total LSB exactly when q is 1.
  assign q0 = c_sum_reg[0] ^ c_carry_reg[0] ^ (x0 & in_b[0]);

  always @* begin
    case ({x0, q0})
      2'b01:  d0 = m_ext;
      2'b10:  d0 = b_ext;
      2'b11:  d0 = b_plus_m_ext;
      default: d0 = 1028'b0;
    endcase
  end

  mpcsa #(
    .WIDTH(1028)
  ) csa_radix2_step_0 (
    .clk(clk),
    .resetn(resetn),
    .start(1'b1),
    .in_a(state_sum_ext),
    .in_b(state_carry_ext),
    .in_c(d0),
    .sum(csa_sum_1),
    .carry(csa_carry_1),
    .lower_sum(),
    .lower_carry(),
    .done()
  );

  // q0 makes csa_sum_1[0] zero; csa_carry_1[0] is zero by construction.
  // Consequently these two shifts exactly represent
  // (state_sum + state_carry + d0) / 2.
  assign mid_sum   = csa_sum_1   >> 1;
  assign mid_carry = csa_carry_1 >> 1;

  // q1 is deliberately computed from the post-step-0 carry-save state.
  assign q1 = mid_sum[0] ^ mid_carry[0] ^ (x1 & in_b[0]);

  always @* begin
    case ({x1, q1})
      2'b01:  d1 = m_ext;
      2'b10:  d1 = b_ext;
      2'b11:  d1 = b_plus_m_ext;
      default: d1 = 1028'b0;
    endcase
  end

  mpcsa #(
    .WIDTH(1028)
  ) csa_radix2_step_1 (
    .clk(clk),
    .resetn(resetn),
    .start(1'b1),
    .in_a(mid_sum),
    .in_b(mid_carry),
    .in_c(d1),
    .sum(csa_sum_2),
    .carry(csa_carry_2),
    .lower_sum(),
    .lower_carry(),
    .done()
  );

  // q1 gives the same exact-divide property at the second stage.
  assign next_sum   = csa_sum_2   >> 1;
  assign next_carry = csa_carry_2 >> 1;

  assign adder_start = issue_adder_pending;

  always @* begin
    adder_load_subtract = 1'b0;
    adder_load_a        = 1027'b0;
    adder_load_b        = 1027'b0;

    case (adder_cmd)
      ADDER_CMD_B_PLUS_M: begin
        adder_load_a = {3'b0, in_b};
        adder_load_b = {3'b0, in_m};
      end
      ADDER_CMD_COLLAPSE: begin
        adder_load_a = c_sum_reg;
        adder_load_b = c_carry_reg;
      end
      ADDER_CMD_SUBTRACT: begin
        adder_load_subtract = 1'b1;
        adder_load_a        = adder_result[1026:0];
        adder_load_b        = {3'b0, in_m};
      end
      default: begin
      end
    endcase
  end

  mpadder_cpa final_adder (
    .clk(clk),
    .resetn(resetn),
    .start(adder_start),
    .subtract(adder_load_subtract),
    .in_a(adder_load_a),
    .in_b(adder_load_b),
    .result(adder_result),
    .done(adder_done)
  );

  always @(posedge clk or negedge resetn) begin
    if (!resetn) begin
      state               <= IDLE;
      adder_cmd           <= ADDER_CMD_NONE;
      issue_adder_pending <= 1'b0;
      done_reg            <= 1'b0;
    end else begin
      issue_adder_pending <= 1'b0;

      case (state)
        IDLE: begin
          done_reg <= 1'b0;

          if (start) begin
            adder_cmd           <= ADDER_CMD_B_PLUS_M;
            issue_adder_pending <= 1'b1;
            state               <= PRECOMPUTE_BM;
          end
        end

        PRECOMPUTE_BM: begin
          if (adder_done) begin
            state <= LOAD_BIT_1;
          end
        end

        LOAD_BIT_1: begin
          if (iteration_count < 9'd511) begin
            state <= LOAD_BITS;
          end else begin
            adder_cmd           <= ADDER_CMD_COLLAPSE;
            issue_adder_pending <= 1'b1;
            state               <= COLLAPSE;
          end
        end

        LOAD_BITS: begin
          if (iteration_count >= 9'd511) begin
            adder_cmd           <= ADDER_CMD_COLLAPSE;
            issue_adder_pending <= 1'b1;
            state               <= COLLAPSE;
          end
        end

        COLLAPSE: begin
          if (adder_done) begin
            adder_cmd           <= ADDER_CMD_SUBTRACT;
            issue_adder_pending <= 1'b1;
            state               <= STORE_SUB;
          end
        end

        STORE_SUB: begin
          if (adder_done) begin
            state <= OUTPUT_RESULT;
          end
        end

        OUTPUT_RESULT: begin
          done_reg <= 1'b1;
          state    <= IDLE;
        end

        default: begin
          state <= IDLE;
        end
      endcase
    end
  end

  // Wide datapath registers intentionally have no reset.  Every one of them
  // is initialized by the operation flow before its value is consumed.
  always @(posedge clk) begin
    case (state)
      IDLE: begin
        result_reg <= 1024'b0;
      end

      PRECOMPUTE_BM: begin
        if (adder_done) begin
          b_plus_m_reg    <= adder_result[1026:0];
          c_sum_reg       <= 1027'b0;
          c_carry_reg     <= 1027'b0;
          iteration_count <= 9'b0;
          a_shift_reg     <= in_a;
        end
      end

      LOAD_BIT_1, LOAD_BITS: begin
        c_sum_reg       <= next_sum[1026:0];
        c_carry_reg     <= next_carry[1026:0];
        a_shift_reg     <= a_shift_reg >> 2;
        iteration_count <= iteration_count + 9'd1;
      end

      COLLAPSE: begin
        if (adder_done) begin
          result_reg <= adder_result[1023:0];
        end
      end

      OUTPUT_RESULT: begin
        // A zero sign bit means collapse_result - M was non-negative.
        if (!adder_result[1027]) begin
          result_reg <= adder_result[1023:0];
        end
      end

      default: begin
      end
    endcase
  end

  assign result = result_reg;
  assign done   = done_reg;

`ifndef SYNTHESIS
  // Montgomery multiplication is undefined when gcd(in_m, 2^1024) != 1.
  always @(posedge clk) begin
    if (resetn && start && (in_m[0] !== 1'b1)) begin
      $error("mont_new requires an odd Montgomery modulus");
    end
  end
`endif

endmodule
