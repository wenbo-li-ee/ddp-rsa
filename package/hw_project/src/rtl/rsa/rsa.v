module rsa (
    input  wire          clk,
    input  wire          resetn,
    output wire   [ 3:0] leds,


    input  wire   [31:0] rin0,             output wire   [31:0] rout0,
    input  wire   [31:0] rin1,             output wire   [31:0] rout1,
    input  wire   [31:0] rin2,             output wire   [31:0] rout2,
    input  wire   [31:0] rin3,             output wire   [31:0] rout3,
    input  wire   [31:0] rin4,             output wire   [31:0] rout4,
    input  wire   [31:0] rin5,             output wire   [31:0] rout5,
    input  wire   [31:0] rin6,             output wire   [31:0] rout6,
    input  wire   [31:0] rin7,             output wire   [31:0] rout7,


    input  wire [1023:0] dma_rx_data,      output wire [1023:0] dma_tx_data,
    output reg  [ 31:0]  dma_rx_address,   output reg  [ 31:0] dma_tx_address,
    output reg           dma_rx_start,     output reg           dma_tx_start,
    input  wire          dma_done,
    input  wire          dma_idle,
    input  wire          dma_error
  );


  wire [31:0] command;
  assign command        = rin0;
  //assign dma_tx_address = rin2;

  wire [31:0] e_len;
  assign e_len = rin1;


  wire [31:0] addr_e, addr_x, addr_m, addr_rn, addr_r2n;
  assign addr_e   = rin3;
  assign addr_x   = rin4;
  assign addr_m   = rin5;
  assign addr_rn  = rin6;
  assign addr_r2n = rin7;


  wire [31:0] status;
  assign rout0 = status;
  assign rout1 = 32'b0;
  assign rout2 = 32'b0;
  assign rout3 = 32'b0;
  assign rout4 = 32'b0;
  assign rout5 = 32'b0;
  assign rout6 = 32'b0;
  assign rout7 = 32'b0;


  wire isCmdComp = (command == 32'd1);
  wire isCmdIdle = (command == 32'd0);


  localparam
    STATE_IDLE          = 4'd0,
    STATE_RX_E          = 4'd1,
    STATE_RX_E_WAIT     = 4'd2,
    STATE_RX_X          = 4'd3,
    STATE_RX_X_WAIT     = 4'd4,
    STATE_RX_M          = 4'd5,
    STATE_RX_M_WAIT     = 4'd6,
    STATE_RX_RN         = 4'd7,
    STATE_RX_RN_WAIT    = 4'd8,
    STATE_RX_R2N        = 4'd9,
    STATE_RX_R2N_WAIT   = 4'd10,
    STATE_COMPUTE       = 4'd11,
    STATE_COMPUTE_WAIT  = 4'd12,
    STATE_TX            = 4'd13,
    STATE_TX_WAIT       = 4'd14,
    STATE_DONE          = 4'd15;


  reg [3:0] state = STATE_IDLE;
  reg [3:0] next_state;


  reg [1023:0] e_reg      = 1024'h0;
  reg [1023:0] x_reg      = 1024'h0;
  reg [1023:0] m_reg      = 1024'h0;
  reg [1023:0] rn_reg     = 1024'h0;
  reg [1023:0] r2n_reg    = 1024'h0;

  reg [31:0] e_len_reg = 32'd0;

  reg exponent_start;
  wire exponent_done;
  wire [1023:0] result_reg;


  exponent exponent_inst (
      .clk(clk),
      .resetn(resetn),
      .start(exponent_start),
      .base(x_reg),
      .exponent(e_reg),
      .modulus(m_reg),
      .r(rn_reg),
      .r2(r2n_reg),
      .e_len(e_len_reg),
      .result_out(result_reg),
      .done_out(exponent_done)
  );


  always@(*) begin
    next_state <= state;

    case (state)
      STATE_IDLE: begin
        next_state <= (isCmdComp) ? STATE_RX_E : state;
      end


      STATE_RX_E: begin
        next_state <= (~dma_idle) ? STATE_RX_E_WAIT : state;
      end
      STATE_RX_E_WAIT: begin
        next_state <= (dma_done) ? STATE_RX_X : state;
      end


      STATE_RX_X: begin
        next_state <= (~dma_idle) ? STATE_RX_X_WAIT : state;
      end
      STATE_RX_X_WAIT: begin
        next_state <= (dma_done) ? STATE_RX_M : state;
      end


      STATE_RX_M: begin
        next_state <= (~dma_idle) ? STATE_RX_M_WAIT : state;
      end
      STATE_RX_M_WAIT: begin
        next_state <= (dma_done) ? STATE_RX_RN : state;
      end


      STATE_RX_RN: begin
        next_state <= (~dma_idle) ? STATE_RX_RN_WAIT : state;
      end
      STATE_RX_RN_WAIT: begin
        next_state <= (dma_done) ? STATE_RX_R2N : state;
      end


      STATE_RX_R2N: begin
        next_state <= (~dma_idle) ? STATE_RX_R2N_WAIT : state;
      end
      STATE_RX_R2N_WAIT: begin
        next_state <= (dma_done) ? STATE_COMPUTE : state;
      end


      STATE_COMPUTE: begin
        next_state <= STATE_COMPUTE_WAIT;
      end


      STATE_COMPUTE_WAIT: begin
        next_state <= (exponent_done) ? STATE_TX : state;
      end


      STATE_TX: begin
        next_state <= (~dma_idle) ? STATE_TX_WAIT : state;
      end
      STATE_TX_WAIT: begin
        next_state <= (dma_done) ? STATE_DONE : state;
      end


      STATE_DONE: begin
        next_state <= (isCmdIdle) ? STATE_IDLE : state;
      end

      default: next_state <= STATE_IDLE;
    endcase
  end

  always @(posedge clk) begin
    if (~resetn) begin
      state <= STATE_IDLE;
      dma_rx_start <= 1'b0;
      dma_tx_start <= 1'b0;
      exponent_start <= 1'b0;
      dma_rx_address <= 32'b0;
      dma_tx_address <= 32'b0;
      e_len_reg <= 32'd0;
    end else begin
      state <= next_state;
      dma_rx_start <= 1'b0;
      dma_tx_start <= 1'b0;
      exponent_start <= 1'b0;

      case (state)
        STATE_RX_E: begin
          e_len_reg <= e_len;
          dma_rx_address <= addr_e;
          dma_rx_start <= 1'b1;
        end
        STATE_RX_E_WAIT: begin
          if (dma_done) begin
            e_reg <= dma_rx_data;
          end
        end


        STATE_RX_X: begin
          dma_rx_address <= addr_x;
          dma_rx_start <= 1'b1;
        end
        STATE_RX_X_WAIT: begin
          if (dma_done) begin
            x_reg <= dma_rx_data;
          end
        end


        STATE_RX_M: begin
          dma_rx_address <= addr_m;
          dma_rx_start <= 1'b1;
        end
        STATE_RX_M_WAIT: begin
          if (dma_done) begin
            m_reg <= dma_rx_data;
          end
        end


        STATE_RX_RN: begin
          dma_rx_address <= addr_rn;
          dma_rx_start <= 1'b1;
        end
        STATE_RX_RN_WAIT: begin
          if (dma_done) begin
            rn_reg <= dma_rx_data;
          end
        end

        STATE_RX_R2N: begin
          dma_rx_address <= addr_r2n;
          dma_rx_start <= 1'b1;
        end
        STATE_RX_R2N_WAIT: begin
          if (dma_done) begin
            r2n_reg <= dma_rx_data;
          end
        end

        STATE_COMPUTE: begin
          exponent_start <= 1'b1;
        end

        STATE_TX: begin
          dma_tx_address <= rin2;
          dma_tx_start <= 1'b1;
        end

      endcase
    end
  end

  assign dma_tx_data = result_reg;

  wire isStateIdle = (state == STATE_IDLE);
  wire isStateDone = (state == STATE_DONE);
  assign status = {29'b0, dma_error, isStateIdle, isStateDone};

endmodule


module exponent(
    input wire          clk,
    input wire          resetn,
    input wire          start,
    input wire [31:0]   e_len,
    input wire [1023:0] base,
    input wire [1023:0] exponent,
    input wire [1023:0] modulus,
    input wire [1023:0] r,
    input wire [1023:0] r2,
    output  [1023:0] result_out,

    output           done_out
);
    reg [1023:0]    result;
    reg     done;
    assign done_out = done;
    assign result_out = result;
    reg  [1023:0] mont_in_a_1, mont_in_b_1;
    reg  [1023:0] mont_in_a_2, mont_in_b_2;
    wire [1023:0] mont_result_1, mont_result_2;
    reg  [1023:0] A;
    reg           mont_start_1, mont_start_2;
    wire          mont_done_1, mont_done_2;
    reg  [1023:0] x_tilde = 0;
    reg  [11:0]   i;
    reg  [11:0]   counter = 0;
    reg  [3:0]   state;
    reg          e_silce;

    montgomery multiplier_1 (
        .clk(clk),
        .resetn(resetn),
        .start(mont_start_1),
        .in_a(mont_in_a_1),
        .in_b(mont_in_b_1),
        .in_m(modulus),
        .result(mont_result_1),
        .done(mont_done_1)
    );


    montgomery multiplier_2 (
        .clk(clk),
        .resetn(resetn),
        .start(mont_start_2),
        .in_a(mont_in_a_2),
        .in_b(mont_in_b_2),
        .in_m(modulus),
        .result(mont_result_2),
        .done(mont_done_2)
    );
  parameter IDLE          = 4'b0000;
  parameter INIT          = 4'b0001;
  parameter STORE_X_MONT       = 4'b0010;
  parameter LOOP      = 4'b0011;
  parameter WAIT_LOOP_UPDATE       = 4'b0100;
  parameter FINALIZE      = 4'b1000;


    always @(posedge clk or negedge resetn) begin
        if (!resetn) begin
            state <= IDLE;
            done <= 0;
            mont_start_1 <= 0;
            mont_start_2 <= 0;
        end else begin
            case (state)
                IDLE: begin
                    done <= 0;
                    if (start) begin
                        state <= INIT;
                        i <= e_len - 1;
                        counter <= 0;
                    end
                end

                INIT: begin
                    mont_start_2 <= 1;
                    mont_in_a_2  <= base;
                    mont_in_b_2 <= r2;
                    state <= STORE_X_MONT;

                end

                STORE_X_MONT: begin
                    mont_start_2 <= 0;
                    e_silce <= exponent[i];
                    A <= r;
                    if (mont_done_2) begin
                        x_tilde <= mont_result_2;
                        state <= LOOP;
                    end
                end

                LOOP: begin
                    if (counter < e_len) begin
                        i <= i - 1;
                        counter <= counter + 1;
                        if (e_silce) begin
                            mont_start_1 <= 1;
                            mont_in_a_1 <= A;
                            mont_in_b_1 <= x_tilde;

                            mont_start_2 <= 1;
                            mont_in_a_2 <= x_tilde;
                            mont_in_b_2 <= x_tilde;

                            state <= WAIT_LOOP_UPDATE;
                        end else begin
                            mont_start_1 <= 1;
                            mont_in_a_1 <= A;
                            mont_in_b_1 <= A;

                            mont_start_2 <= 1;
                            mont_in_a_2 <= A;
                            mont_in_b_2 <= x_tilde;

                            state <= WAIT_LOOP_UPDATE;
                        end
                    end else begin
                        mont_start_1 <= 1;
                        mont_in_a_1 <= A;
                        mont_in_b_1 <= 1;
                        state <= FINALIZE;
                    end
                end
                WAIT_LOOP_UPDATE: begin
                    mont_start_1 <= 0;
                    mont_start_2 <= 0;
                    e_silce <= exponent[i];
                    if(mont_done_1) begin
                        A <= mont_result_1;
                    end
                    if(mont_done_2) begin
                        x_tilde <= mont_result_2;
                    end
                    if(mont_done_1 && mont_done_2) begin

                        state <= LOOP;
                    end
                end
                FINALIZE: begin
                    mont_start_1 <= 0;
                    if (mont_done_1) begin
                        result <= mont_result_1;
                        done <= 1;
                        state <= IDLE;
                    end
                end

            endcase
        end
    end
endmodule
