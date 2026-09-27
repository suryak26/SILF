`timescale 1ns/1ps

module lut_gen_unit #(
    parameter P_X = 4,
    parameter P_W = 4,
    parameter P_Y = P_X + P_W + 1,

    // For INT4:
    // W1_MAG_NUM = 8:  |w1| = 1, 2, ..., 8
    // W2_MAG_NUM = 7:  |w2| = 1, 2, ..., 7
    parameter W1_MAG_NUM = (1 << (P_W - 1)),
    parameter W2_MAG_NUM = (1 << (P_W - 1)) - 1,
    parameter LUT_DEPTH = W1_MAG_NUM * 2 * W2_MAG_NUM
)(
    input  wire                         clk,
    input  wire                         rst_n,
    input  wire                         start,

    // u = 0: segment length 1
    //        y = |w1| * x1
    // u = 1: segment length 2
    //        y = |w1| * x1 +/- |w2| * x2
    input  wire                         u,

    input  wire signed [P_X-1:0]        x1,
    input  wire signed [P_X-1:0]        x2,

    output reg                          done,
    output reg signed [P_Y*LUT_DEPTH-1:0] lut_out_flat
);

    localparam integer PROD_W = P_X + P_W;

    localparam [2:0] IDLE        = 3'd0;
    localparam [2:0] GEN_W1      = 3'd1;
    localparam [2:0] GEN_W2_POS  = 3'd2;
    localparam [2:0] GEN_W2_NEG  = 3'd3;

    reg [2:0] state;

    reg                          u_reg;
    reg signed [P_X-1:0]        x1_reg;
    reg signed [P_X-1:0]        x2_reg;

    // Buffered |w1| * x1 products
    reg signed [PROD_W-1:0] prod_w1 [0:W1_MAG_NUM-1];

    // Buffered +|w2| * x2 products
    reg signed [PROD_W-1:0] prod_w2_pos [0:W2_MAG_NUM-1];

    // Buffered -|w2| * x2 products
    reg signed [PROD_W-1:0] prod_w2_neg [0:W2_MAG_NUM-1];

    integer i;
    integer j;

    function signed [PROD_W-1:0] multiply_magnitude;
        input signed [P_X-1:0] value;
        input integer magnitude;
        begin
            multiply_magnitude = value * magnitude;
        end
    endfunction

    function signed [PROD_W-1:0] sign_invert;
        input signed [PROD_W-1:0] value;
        begin
            sign_invert = -value;
        end
    endfunction

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

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state        <= IDLE;
            done         <= 1'b0;
            u_reg        <= 1'b0;
            x1_reg       <= {P_X{1'b0}};
            x2_reg       <= {P_X{1'b0}};
            lut_out_flat <= {P_Y*LUT_DEPTH{1'b0}};

            for (i = 0; i < W1_MAG_NUM; i = i + 1) begin
                prod_w1[i] <= {PROD_W{1'b0}};
            end

            for (i = 0; i < W2_MAG_NUM; i = i + 1) begin
                prod_w2_pos[i] <= {PROD_W{1'b0}};
                prod_w2_neg[i] <= {PROD_W{1'b0}};
            end
        end else begin
            case (state)

                IDLE: begin
                    done <= 1'b0;

                    if (start) begin
                        u_reg  <= u;
                        x1_reg <= x1;
                        x2_reg <= x2;

                        // Clear previous LUT contents.
                        lut_out_flat <=
                            {P_Y*LUT_DEPTH{1'b0}};

                        state <= GEN_W1;
                    end
                end

                /*
                 * Generation cycle 1:
                 *
                 * Generate and buffer:
                 *
                 *     |w1| * x1
                 *
                 * where |w1| = 1, 2, ..., 8.
                 */
                GEN_W1: begin
                    for (i = 0; i < W1_MAG_NUM; i = i + 1) begin
                        prod_w1[i] <=
                            multiply_magnitude(x1_reg, i + 1);

                        if (!u_reg) begin
                            lut_out_flat[i*P_Y +: P_Y] <=
                                multiply_magnitude(
                                    x1_reg,
                                    i + 1
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

                /*
                 * Generation cycle 2:
                 *
                 * Generate and buffer:
                 *
                 *     +|w2| * x2
                 *
                 * where |w2| = 1, 2, ..., 7.
                 */
                GEN_W2_POS: begin
                    for (i = 0; i < W2_MAG_NUM; i = i + 1) begin
                        prod_w2_pos[i] <=
                            multiply_magnitude(x2_reg, i + 1);
                    end

                    state <= GEN_W2_NEG;
                end

                /*
                 * Generation cycle 3:
                 *
                 * The sign inverter generates:
                 *
                 *     -|w2| * x2
                 */
                GEN_W2_NEG: begin
                    for (j = 0; j < W2_MAG_NUM; j = j + 1) begin
                        prod_w2_neg[j] <=
                            sign_invert(prod_w2_pos[j]);
                    end

                    for (i = 0; i < W1_MAG_NUM; i = i + 1) begin
                        for (j = 0; j < W2_MAG_NUM; j = j + 1) begin

                            // |w1|*x1 + |w2|*x2
                            lut_out_flat[
                                idx_positive(i,j)*P_Y +: P_Y
                            ] <= add_products(
                                prod_w1[i],
                                prod_w2_pos[j]
                            );

                            // |w1|*x1 - |w2|*x2
                            lut_out_flat[
                                idx_negative(i,j)*P_Y +: P_Y
                            ] <= add_products(
                                prod_w1[i],
                                sign_invert(prod_w2_pos[j])
                            );
                        end
                    end

                    done  <= 1'b1;
                    state <= IDLE;
                end

                default: begin
                    state <= IDLE;
                    done  <= 1'b0;
                end

            endcase
        end
    end

endmodule
