`timescale 1ns/1ps

// ============================================================================
// palute_baseline_lut_gen
//
// PALUTE-style LUT generator with a GENUINE RUNTIME multiplier.
//
// Baseline-integrity note:
//
// The magnitude values are PRIMARY INPUT PORTS, so synthesis cannot know
// their values ahead of time. Therefore:
//
//     x1_reg * w1_mag_flat[...]
//     x2_reg * w2_mag_flat[...]
//
// are genuine runtime multiplications.
//
// IMPORTANT:
// The magnitude buses are UNSIGNED because |w| is a non-negative magnitude.
// With P_W = 4, an unsigned 4-bit value can represent 0..15, allowing the
// required magnitude |w1| = 8. Declaring the bus signed would interpret
// 4'b1000 as -8.
//
// Interface and FSM structure otherwise mirror the original LUT generator.
// ============================================================================

module palute_baseline_lut_gen #(
    parameter P_X = 4,
    parameter P_W = 4,
    parameter P_Y = P_X + P_W + 1,

    // For INT4:
    // W1_MAG_NUM = 8: |w1| = 1,2,...,8
    // W2_MAG_NUM = 7: |w2| = 1,2,...,7
    parameter W1_MAG_NUM = (1 << (P_W - 1)),
    parameter W2_MAG_NUM = (1 << (P_W - 1)) - 1,
    parameter LUT_DEPTH = W1_MAG_NUM * 2 * W2_MAG_NUM
)(
    input  wire                         clk,
    input  wire                         rst_n,
    input  wire                         start,

    // u = 0: segment length 1 -> y = |w1| * x1
    // u = 1: segment length 2 -> y = |w1| * x1 +/- |w2| * x2
    input  wire                         u,

    input  wire signed [P_X-1:0]        x1,
    input  wire signed [P_X-1:0]        x2,

    // Runtime weight-magnitude buses.
    //
    // These are UNSIGNED because they represent positive magnitudes.
    // Slot i contains magnitude (i+1).
    input  wire [P_W*W1_MAG_NUM-1:0]    w1_mag_flat,
    input  wire [P_W*W2_MAG_NUM-1:0]    w2_mag_flat,

    output reg                          done,
    output reg signed [P_Y*LUT_DEPTH-1:0] lut_out_flat
);

    // ------------------------------------------------------------------------
    // Width of x * magnitude product
    // ------------------------------------------------------------------------
    localparam integer PROD_W = P_X + P_W;

    // ------------------------------------------------------------------------
    // FSM states
    // ------------------------------------------------------------------------
    localparam [2:0] IDLE        = 3'd0;
    localparam [2:0] GEN_W1      = 3'd1;
    localparam [2:0] GEN_W2_POS  = 3'd2;
    localparam [2:0] GEN_W2_NEG  = 3'd3;

    reg [2:0] state;

    // ------------------------------------------------------------------------
    // Registered inputs
    // ------------------------------------------------------------------------
    reg                         u_reg;
    reg signed [P_X-1:0]       x1_reg;
    reg signed [P_X-1:0]       x2_reg;

    // ------------------------------------------------------------------------
    // Buffered products
    // ------------------------------------------------------------------------

    // |w1| * x1
    reg signed [PROD_W-1:0] prod_w1 [0:W1_MAG_NUM-1];

    // +|w2| * x2
    reg signed [PROD_W-1:0] prod_w2_pos [0:W2_MAG_NUM-1];

    // -|w2| * x2
    reg signed [PROD_W-1:0] prod_w2_neg [0:W2_MAG_NUM-1];

    integer i;
    integer j;

    // =========================================================================
    // Genuine runtime multiplier
    //
    // value = signed x input
    // mag   = unsigned magnitude
    //
    // Both operands are runtime signals.
    // =========================================================================
    function signed [PROD_W-1:0] rt_multiply;
        input signed [P_X-1:0] value;
        input        [P_W-1:0] mag;

        reg signed [PROD_W-1:0] value_ext;
        reg signed [PROD_W-1:0] mag_ext;

        begin
            // Sign-extend x to product width.
            value_ext = value;

            // Zero-extend the unsigned magnitude.
            mag_ext = {{(PROD_W-P_W){1'b0}}, mag};

            // Genuine runtime multiplication.
            rt_multiply = value_ext * mag_ext;
        end
    endfunction

    // =========================================================================
    // Sign inversion
    // =========================================================================
    function signed [PROD_W-1:0] sign_invert;
        input signed [PROD_W-1:0] value;

        begin
            sign_invert = -value;
        end
    endfunction

    // =========================================================================
    // Add two products and extend to LUT output width
    // =========================================================================
    function signed [P_Y-1:0] add_products;
        input signed [PROD_W-1:0] value1;
        input signed [PROD_W-1:0] value2;

        reg signed [P_Y-1:0] value1_ext;
        reg signed [P_Y-1:0] value2_ext;

        begin
            value1_ext = value1;
            value2_ext = value2;

            add_products = value1_ext + value2_ext;
        end
    endfunction

    // =========================================================================
    // LUT indexing
    //
    // Positive:
    //   |w1|*x1 + |w2|*x2
    //
    // Negative:
    //   |w1|*x1 - |w2|*x2
    // =========================================================================
    function integer idx_positive;
        input integer w1_index;
        input integer w2_index;

        begin
            idx_positive =
                w1_index * (2 * W2_MAG_NUM)
                + w2_index;
        end
    endfunction

    function integer idx_negative;
        input integer w1_index;
        input integer w2_index;

        begin
            idx_negative =
                w1_index * (2 * W2_MAG_NUM)
                + W2_MAG_NUM
                + w2_index;
        end
    endfunction

    // =========================================================================
    // Main FSM
    // =========================================================================
    always @(posedge clk or negedge rst_n) begin

        if (!rst_n) begin

            state        <= IDLE;
            done         <= 1'b0;
            u_reg        <= 1'b0;
            x1_reg       <= {P_X{1'b0}};
            x2_reg       <= {P_X{1'b0}};

            lut_out_flat <= {P_Y*LUT_DEPTH{1'b0}};

            // Clear |w1|*x1 products
            for (i = 0; i < W1_MAG_NUM; i = i + 1) begin
                prod_w1[i] <= {PROD_W{1'b0}};
            end

            // Clear +|w2|*x2 and -|w2|*x2 products
            for (i = 0; i < W2_MAG_NUM; i = i + 1) begin
                prod_w2_pos[i] <= {PROD_W{1'b0}};
                prod_w2_neg[i] <= {PROD_W{1'b0}};
            end

        end else begin

            case (state)

                // =================================================================
                // IDLE
                // =================================================================
                IDLE: begin

                    done <= 1'b0;

                    if (start) begin

                        // Capture inputs
                        u_reg  <= u;
                        x1_reg <= x1;
                        x2_reg <= x2;

                        // Clear previous LUT
                        lut_out_flat <=
                            {P_Y*LUT_DEPTH{1'b0}};

                        state <= GEN_W1;

                    end

                end


                // =================================================================
                // CYCLE 1
                //
                // Generate:
                //
                //     |w1| * x1
                //
                // for all eight magnitude values.
                // =================================================================
                GEN_W1: begin

                    for (i = 0; i < W1_MAG_NUM; i = i + 1) begin

                        // Buffer runtime multiplication result
                        prod_w1[i] <=
                            rt_multiply(
                                x1_reg,
                                $unsigned(
                                    w1_mag_flat[i*P_W +: P_W]
                                )
                            );

                        // For u = 0, the LUT only requires |w1|*x1.
                        if (!u_reg) begin

                            lut_out_flat[i*P_Y +: P_Y] <=
                                rt_multiply(
                                    x1_reg,
                                    $unsigned(
                                        w1_mag_flat[i*P_W +: P_W]
                                    )
                                );

                        end

                    end

                    if (!u_reg) begin

                        done  <= 1'b1;
                        state <= IDLE;

                    end else begin

                        state <= GEN_W2_POS;

                    end

                end


                // =================================================================
                // CYCLE 2
                //
                // Generate:
                //
                //     +|w2| * x2
                //
                // for all seven magnitude values.
                // =================================================================
                GEN_W2_POS: begin

                    for (i = 0; i < W2_MAG_NUM; i = i + 1) begin

                        prod_w2_pos[i] <=
                            rt_multiply(
                                x2_reg,
                                $unsigned(
                                    w2_mag_flat[i*P_W +: P_W]
                                )
                            );

                    end

                    state <= GEN_W2_NEG;

                end


                // =================================================================
                // CYCLE 3
                //
                // Generate:
                //
                //     -|w2| * x2
                //
                // and construct the complete LUT.
                // =================================================================
                GEN_W2_NEG: begin

                    // Generate negative products
                    for (j = 0; j < W2_MAG_NUM; j = j + 1) begin

                        prod_w2_neg[j] <=
                            sign_invert(prod_w2_pos[j]);

                    end

                    // Generate complete LUT
                    for (i = 0; i < W1_MAG_NUM; i = i + 1) begin

                        for (j = 0; j < W2_MAG_NUM; j = j + 1) begin

                            // -----------------------------------------------------
                            // |w1|*x1 + |w2|*x2
                            // -----------------------------------------------------
                            lut_out_flat[
                                idx_positive(i,j)*P_Y +: P_Y
                            ] <=
                                add_products(
                                    prod_w1[i],
                                    prod_w2_pos[j]
                                );

                            // -----------------------------------------------------
                            // |w1|*x1 - |w2|*x2
                            // -----------------------------------------------------
                            lut_out_flat[
                                idx_negative(i,j)*P_Y +: P_Y
                            ] <=
                                add_products(
                                    prod_w1[i],
                                    sign_invert(prod_w2_pos[j])
                                );

                        end

                    end

                    done  <= 1'b1;
                    state <= IDLE;

                end


                // =================================================================
                // DEFAULT
                // =================================================================
                default: begin

                    state <= IDLE;
                    done  <= 1'b0;

                end

            endcase

        end

    end

endmodule
