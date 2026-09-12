`timescale 1ns/1ps

module lut_gen_unit #(
    parameter P_X = 4,
    parameter P_W = 4,
    parameter P_Y = P_X + P_W + 1,
    parameter W1_MAG_NUM = (1 << (P_W - 1)),
    parameter W2_MAG_NUM = (1 << (P_W - 1)) - 1,
    parameter LUT_DEPTH = W1_MAG_NUM * 2 * W2_MAG_NUM
)(
    input  wire                         clk,
    input  wire                         rst_n,
    input  wire                         start,
    input  wire                         u,
    input  wire signed [P_X-1:0]        x1,
    input  wire signed [P_X-1:0]        x2,
    output reg                          done,
    output reg signed [P_Y*LUT_DEPTH-1:0] lut_out_flat
);

    localparam integer PROD_W = P_X + P_W;
    localparam [2:0] IDLE       = 3'd0;
    localparam [2:0] LOAD_MAGS  = 3'd1;
    localparam [2:0] GEN_W1     = 3'd2;
    localparam [2:0] GEN_W2_POS = 3'd3;
    localparam [2:0] GEN_W2_NEG = 3'd4;

    reg [2:0] state;
    reg                   u_reg;
    reg signed [P_X-1:0] x1_reg;
    reg signed [P_X-1:0] x2_reg;

    // ---- Magnitude generator ----
    // Enumerates |w| = 1..8 with a free-running counter and latches each
    // lane's weight into a register, so every multiplier operand below is a
    // genuine runtime signal that synthesis cannot constant-specialize.
    reg [3:0] mag_cnt;
    reg [3:0] mag_w1 [0:W1_MAG_NUM-1];
    reg [3:0] mag_w2 [0:W2_MAG_NUM-1];

    reg signed [PROD_W-1:0] prod_w1     [0:W1_MAG_NUM-1];
    reg signed [PROD_W-1:0] prod_w2_pos [0:W2_MAG_NUM-1];
    reg signed [PROD_W-1:0] prod_w2_neg [0:W2_MAG_NUM-1];

    integer i, j;

    // ---- MegaMultiplier block: 8 + 7 runtime-magnitude lanes ----
    wire signed [PROD_W-1:0] mult_w1 [0:W1_MAG_NUM-1];
    wire signed [PROD_W-1:0] mult_w2 [0:W2_MAG_NUM-1];

    genvar gi;
    generate
        for (gi = 0; gi < W1_MAG_NUM; gi = gi + 1) begin : GEN_MEGA_MULT_W1
            mega_multiplier #(.P_X(P_X), .PROD_W(PROD_W))
                u_mega_mult_w1 (.value(x1_reg), .magnitude(mag_w1[gi]), .product(mult_w1[gi]));
        end
        for (gi = 0; gi < W2_MAG_NUM; gi = gi + 1) begin : GEN_MEGA_MULT_W2
            mega_multiplier #(.P_X(P_X), .PROD_W(PROD_W))
                u_mega_mult_w2 (.value(x2_reg), .magnitude(mag_w2[gi]), .product(mult_w2[gi]));
        end
    endgenerate

    // ---- negation (trivial, not part of the reported blocks) ----
    wire signed [PROD_W-1:0] neg_w2 [0:W2_MAG_NUM-1];
    generate
        for (gi = 0; gi < W2_MAG_NUM; gi = gi + 1) begin : GEN_NEG
            assign neg_w2[gi] = -prod_w2_pos[gi];
        end
    endgenerate

    // ---- MegaAdder block: one adder per LUT entry ----
    wire signed [P_Y-1:0] add_pos [0:W1_MAG_NUM-1][0:W2_MAG_NUM-1];
    wire signed [P_Y-1:0] add_neg [0:W1_MAG_NUM-1][0:W2_MAG_NUM-1];

    genvar gi2, gj2;
    generate
        for (gi2 = 0; gi2 < W1_MAG_NUM; gi2 = gi2 + 1) begin : GEN_ROW
            for (gj2 = 0; gj2 < W2_MAG_NUM; gj2 = gj2 + 1) begin : GEN_COL
                mega_adder #(.IN_W(PROD_W), .OUT_W(P_Y)) u_mega_add_pos
                    (.a(prod_w1[gi2]), .b(prod_w2_pos[gj2]), .sum(add_pos[gi2][gj2]));
                mega_adder #(.IN_W(PROD_W), .OUT_W(P_Y)) u_mega_add_neg
                    (.a(prod_w1[gi2]), .b(neg_w2[gj2]),     .sum(add_neg[gi2][gj2]));
            end
        end
    endgenerate

    function integer idx_positive; input integer w1i, w2i;
        idx_positive = w1i*(2*W2_MAG_NUM) + w2i; endfunction
    function integer idx_negative; input integer w1i, w2i;
        idx_negative = w1i*(2*W2_MAG_NUM) + W2_MAG_NUM + w2i; endfunction

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE; done <= 1'b0; u_reg <= 1'b0;
            x1_reg <= {P_X{1'b0}}; x2_reg <= {P_X{1'b0}};
            mag_cnt <= 4'd0;
            lut_out_flat <= {P_Y*LUT_DEPTH{1'b0}};
            for (i = 0; i < W2_MAG_NUM; i = i + 1) prod_w2_neg[i] <= {PROD_W{1'b0}};
        end else begin
            case (state)
                IDLE: begin
                    done <= 1'b0;
                    if (start) begin
                        u_reg <= u; x1_reg <= x1; x2_reg <= x2;
                        lut_out_flat <= {P_Y*LUT_DEPTH{1'b0}};
                        mag_cnt <= 4'd1;
                        state <= LOAD_MAGS;
                    end
                end
                // Enumerate weight magnitudes 1..8 across the lanes.
                LOAD_MAGS: begin
                    mag_w1[mag_cnt-1] <= mag_cnt;
                    if (mag_cnt <= W2_MAG_NUM) mag_w2[mag_cnt-1] <= mag_cnt;
                    if (mag_cnt == W1_MAG_NUM) state <= GEN_W1;
                    mag_cnt <= mag_cnt + 4'd1;
                end
                GEN_W1: begin
                    for (i = 0; i < W1_MAG_NUM; i = i + 1) begin
                        prod_w1[i] <= mult_w1[i];
                        if (!u_reg) lut_out_flat[i*P_Y +: P_Y] <= mult_w1[i];
                    end
                    if (!u_reg) begin done <= 1'b1; state <= IDLE; end
                    else state <= GEN_W2_POS;
                end
                GEN_W2_POS: begin
                    for (i = 0; i < W2_MAG_NUM; i = i + 1) prod_w2_pos[i] <= mult_w2[i];
                    state <= GEN_W2_NEG;
                end
                GEN_W2_NEG: begin
                    for (j = 0; j < W2_MAG_NUM; j = j + 1) prod_w2_neg[j] <= -prod_w2_pos[j];
                    for (i = 0; i < W1_MAG_NUM; i = i + 1)
                        for (j = 0; j < W2_MAG_NUM; j = j + 1) begin
                            lut_out_flat[idx_positive(i,j)*P_Y +: P_Y] <= add_pos[i][j];
                            lut_out_flat[idx_negative(i,j)*P_Y +: P_Y] <= add_neg[i][j];
                        end
                    done <= 1'b1; state <= IDLE;
                end
                default: begin state <= IDLE; done <= 1'b0; end
            endcase
        end
    end
endmodule
