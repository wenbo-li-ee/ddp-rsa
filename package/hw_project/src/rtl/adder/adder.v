`timescale 1ns / 1ps

module mpcsa #(
  parameter WIDTH = 1027
)(
  input  wire          clk,
  input  wire          resetn,
  input  wire          start,
  input  wire [WIDTH-1:0] in_a,
  input  wire [WIDTH-1:0] in_b,
  input  wire [WIDTH-1:0] in_c,
  output wire [WIDTH-1:0] sum,
  output wire [WIDTH-1:0] carry,
  output wire [1:0]    lower_sum,
  output wire          lower_carry,
  output wire          done
  );

wire [WIDTH-1:0] carry_raw;
wire [2:0]       lower_total;

assign carry_raw  = (in_a & in_b) | (in_a & in_c) | (in_b & in_c);
assign sum        = in_a ^ in_b ^ in_c;
assign carry      = carry_raw << 1;
assign lower_total = {1'b0, in_a[1:0]} + {1'b0, in_b[1:0]} + {1'b0, in_c[1:0]};
assign lower_sum   = lower_total[1:0];
assign lower_carry = lower_total[2];
assign done        = start;

endmodule


`timescale 1ns / 1ps

module mpadder_cpa(
  input  wire          clk,
  input  wire          resetn,
  input  wire          start,
  input  wire          subtract,
  input  wire [1026:0] in_a,
  input  wire [1026:0] in_b,
  output wire [1027:0] result,
  output wire          done
  );

reg  [1027:0] reg_a_shift;
reg  [1027:0] reg_b_shift;
reg  [1027:0] reg_result_shift;
reg           reg_carry;
reg  [1:0]    reg_phase;
reg           reg_busy;
reg           done_reg;

wire [256:0] chunk_a;
wire [256:0] chunk_b;
wire [257:0] chunk_sum;

assign chunk_a = reg_a_shift[256:0];
assign chunk_b = reg_b_shift[256:0];

adder_257 u_adder_257 (
  .cin(reg_carry),
  .in_a(chunk_a),
  .in_b(chunk_b),
  .sum(chunk_sum)
);

always @(posedge clk) begin
  if (!resetn) begin
    reg_a_shift    <= 1028'b0;
    reg_b_shift    <= 1028'b0;
    reg_result_shift <= 1028'b0;
    reg_carry    <= 1'b0;
    reg_phase    <= 2'b00;
    reg_busy     <= 1'b0;
    done_reg     <= 1'b0;
  end else begin
    done_reg <= 1'b0;

    if (!reg_busy) begin
      if (start) begin
        reg_a_shift      <= {1'b0, in_a};
        reg_b_shift      <= subtract ? ~{1'b0, in_b} : {1'b0, in_b};
        reg_result_shift <= 1028'b0;
        reg_carry        <= subtract;
        reg_phase        <= 2'b00;
        reg_busy         <= 1'b1;
      end
    end else begin
      reg_a_shift      <= {257'b0, reg_a_shift[1027:257]};
      reg_b_shift      <= {257'b0, reg_b_shift[1027:257]};
      reg_result_shift <= {chunk_sum[256:0], reg_result_shift[1027:257]};
      reg_carry        <= chunk_sum[257];

      if (reg_phase == 2'b11) begin
        reg_busy <= 1'b0;
        done_reg <= 1'b1;
      end else begin
        reg_phase <= reg_phase + 2'b01;
      end
    end
  end
end

assign result = reg_result_shift;
assign done   = done_reg;

endmodule

module adder_257(
  input  wire         cin,
  input  wire [256:0] in_a,
  input  wire [256:0] in_b,
  output wire [257:0] sum
);

  assign sum = {1'b0, in_a} + {1'b0, in_b} + cin;

endmodule
