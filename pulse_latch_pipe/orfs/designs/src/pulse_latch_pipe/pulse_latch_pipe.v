`timescale 1ns/1ps

module pulse_latch_pipe #(
    parameter P_X = 4,
    parameter P_W = 4,
    parameter P_Y = P_X + P_W + 1,          // 9
    parameter W1_MAG_NUM = (1 << (P_W - 1)),       // 8
    parameter W2_MAG_NUM = (1 << (P_W - 1)) - 1,   // 7
    parameter LUT_DEPTH = W1_MAG_NUM * 2 * W2_MAG_NUM // 112
)(
    input  wire                         clk_1,
    input  wire                         clk_2,
    input  wire                         clk_3,
    input  wire                         rst_n,
    input  wire                         start,
    input  wire                         u,
    input  wire signed [P_X-1:0]        x1,
    input  wire signed [P_X-1:0]        x2,
    output reg                          done,
    output reg signed [P_Y*LUT_DEPTH-1:0] lut_out_flat
);

    localparam integer PROD_W = P_X + P_W; // 8

    // =========================================================================
    // 1. OPERAND ISOLATION
    // =========================================================================

    wire signed [P_X-1:0] x1_iso = start ? x1 : {P_X{1'b0}};
    wire signed [P_X-1:0] x2_iso = start ? x2 : {P_X{1'b0}};
    wire                  u_iso  = start ? u  : 1'b0;

    // =========================================================================
    // 2. STAGE 1 LATCHES
    // Transparent when clk_1 is high
    // =========================================================================

    (* dont_touch = "true" *) reg                          u_s1;
    (* dont_touch = "true" *) reg signed [P_X-1:0]        x1_s1;
    (* dont_touch = "true" *) reg signed [P_X-1:0]        x2_s1;
    (* dont_touch = "true" *) reg signed [PROD_W-1:0]     prod_w1_s1 [0:W1_MAG_NUM-1];

    // Changed from explicit sensitivity list to always @(*)
    always @(*) begin
        if (clk_1) begin
            u_s1   <= u_iso;
            x1_s1  <= x1_iso;
            x2_s1  <= x2_iso;

            for (integer i = 0; i < W1_MAG_NUM; i = i + 1) begin
                prod_w1_s1[i] <= x1_iso * (i + 1);
            end
        end
    end

    // =========================================================================
    // 3. STAGE 2 LATCHES
    // Transparent when clk_2 is high
    // =========================================================================

    (* dont_touch = "true" *) reg signed [PROD_W-1:0] prod_w2_pos_s2 [0:W2_MAG_NUM-1];
    (* dont_touch = "true" *) reg signed [PROD_W-1:0] prod_w2_neg_s2 [0:W2_MAG_NUM-1];

    // Changed from explicit sensitivity list to always @(*)
    always @(*) begin
        if (clk_2) begin
            if (u_s1) begin
                for (integer i = 0; i < W2_MAG_NUM; i = i + 1) begin
                    prod_w2_pos_s2[i] <= x2_s1 * (i + 1);
                    prod_w2_neg_s2[i] <= -(x2_s1 * (i + 1));
                end
            end
        end
    end

    // =========================================================================
    // 4. STAGE 3 FLIP-FLOPS
    // Edge-triggered capture
    // =========================================================================

    always @(posedge clk_3 or negedge rst_n) begin
        if (!rst_n) begin
            done <= 1'b0;
            lut_out_flat <= {P_Y*LUT_DEPTH{1'b0}};
        end else begin
            if (!u_s1) begin
                for (integer i = 0; i < W1_MAG_NUM; i = i + 1) begin
                    lut_out_flat[i*P_Y +: P_Y] <= prod_w1_s1[i];
                end

                done <= 1'b1;

            end else begin

                for (integer i = 0; i < W1_MAG_NUM; i = i + 1) begin
                    for (integer j = 0; j < W2_MAG_NUM; j = j + 1) begin

                        lut_out_flat[
                            (i * 2 * W2_MAG_NUM + j) * P_Y +: P_Y
                        ] <= prod_w1_s1[i] + prod_w2_pos_s2[j];

                        lut_out_flat[
                            (i * 2 * W2_MAG_NUM + W2_MAG_NUM + j) * P_Y +: P_Y
                        ] <= prod_w1_s1[i] + prod_w2_neg_s2[j];

                    end
                end

                done <= 1'b1;
            end
        end
    end

endmodule
