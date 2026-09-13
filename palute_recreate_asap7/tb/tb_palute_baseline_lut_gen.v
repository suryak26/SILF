`timescale 1ns/1ps

// ============================================================================
// tb_palute_baseline_lut_gen
//
// Testbench for the PALUTE-style LUT generator baseline.
//
// INT4 configuration:
//
//     P_X = 4
//     P_W = 4
//     P_Y = 9
//
//     |w1| = 1..8
//     |w2| = 1..7
//
// The magnitude buses are UNSIGNED because +8 must be representable in
// four bits.
//
// Test inputs:
//
//     x1 = 3
//     x2 = -2
//
// Expected examples:
//
//     8*x1 + 1*x2 = 22
//     8*x1 + 7*x2 = 10
//     8*x1 - 1*x2 = 26
//     8*x1 - 7*x2 = 38
// ============================================================================

module tb_palute_baseline_lut_gen;

    localparam P_X = 4;
    localparam P_W = 4;
    localparam P_Y = P_X + P_W + 1;

    localparam W1_MAG_NUM = 8;
    localparam W2_MAG_NUM = 7;
    localparam LUT_DEPTH  = 112;

    reg clk;
    reg rst_n;
    reg start;
    reg u;

    reg signed [P_X-1:0] x1;
    reg signed [P_X-1:0] x2;

    // ------------------------------------------------------------------------
    // UNSIGNED magnitude buses
    //
    // P_W = 4 therefore:
    //
    //     0001 = 1
    //     ...
    //     0111 = 7
    //     1000 = 8
    //
    // This is why these MUST NOT be declared signed.
    // ------------------------------------------------------------------------
    reg [P_W*W1_MAG_NUM-1:0] w1_mag_flat;
    reg [P_W*W2_MAG_NUM-1:0] w2_mag_flat;

    wire done;

    wire signed [P_Y*LUT_DEPTH-1:0] lut_out_flat;

    integer i;
    integer j;
    integer index;

    // =========================================================================
    // DUT
    // =========================================================================
    palute_baseline_lut_gen #(
        .P_X(P_X),
        .P_W(P_W),
        .P_Y(P_Y),
        .W1_MAG_NUM(W1_MAG_NUM),
        .W2_MAG_NUM(W2_MAG_NUM),
        .LUT_DEPTH(LUT_DEPTH)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .u(u),
        .x1(x1),
        .x2(x2),
        .w1_mag_flat(w1_mag_flat),
        .w2_mag_flat(w2_mag_flat),
        .done(done),
        .lut_out_flat(lut_out_flat)
    );


    // =========================================================================
    // Clock
    // =========================================================================
    initial begin

        clk = 1'b0;

        forever #5 clk = ~clk;

    end


    // =========================================================================
    // Test sequence
    // =========================================================================
    initial begin

        // ---------------------------------------------------------------
        // Initial values
        // ---------------------------------------------------------------
        rst_n = 1'b0;
        start = 1'b0;
        u     = 1'b1;

        x1 = 0;
        x2 = 0;


        // ---------------------------------------------------------------
        // Load runtime W1 magnitude values
        //
        // slot 0 = 1
        // slot 1 = 2
        // ...
        // slot 7 = 8
        // ---------------------------------------------------------------
        w1_mag_flat = 0;

        for (i = 0; i < W1_MAG_NUM; i = i + 1) begin

            w1_mag_flat[i*P_W +: P_W] = i + 1;

        end


        // ---------------------------------------------------------------
        // Load runtime W2 magnitude values
        //
        // slot 0 = 1
        // slot 1 = 2
        // ...
        // slot 6 = 7
        // ---------------------------------------------------------------
        w2_mag_flat = 0;

        for (i = 0; i < W2_MAG_NUM; i = i + 1) begin

            w2_mag_flat[i*P_W +: P_W] = i + 1;

        end


        // ---------------------------------------------------------------
        // Reset
        // ---------------------------------------------------------------
        repeat (2) @(posedge clk);

        @(negedge clk);

        rst_n = 1'b1;


        // ---------------------------------------------------------------
        // Apply test inputs
        // ---------------------------------------------------------------
        @(negedge clk);

        x1    = 3;
        x2    = -2;
        start = 1'b1;


        // ---------------------------------------------------------------
        // Start pulse
        // ---------------------------------------------------------------
        @(posedge clk);

        #1;

        $display(
            "Input: x1 = %0d, x2 = %0d",
            $signed(x1),
            $signed(x2)
        );


        @(negedge clk);

        start = 1'b0;


        // =========================================================================
        // CYCLE 1
        // =========================================================================
        @(posedge clk);

        #1;

        $display(
            "\nCycle 1: generate |w1| * x1 (runtime multiplier)"
        );

        for (i = 0; i < W1_MAG_NUM; i = i + 1) begin

            $display(
                "|w1| = %0d, product = %0d",
                i + 1,
                $signed(dut.prod_w1[i])
            );

        end


        // =========================================================================
        // CYCLE 2
        // =========================================================================
        @(posedge clk);

        #1;

        $display(
            "\nCycle 2: generate +|w2| * x2 (runtime multiplier)"
        );

        for (i = 0; i < W2_MAG_NUM; i = i + 1) begin

            $display(
                "|w2| = %0d, product = %0d",
                i + 1,
                $signed(dut.prod_w2_pos[i])
            );

        end


        // =========================================================================
        // CYCLE 3
        // =========================================================================
        @(posedge clk);

        #1;

        $display(
            "\nCycle 3: generate -|w2| * x2 and LUT"
        );

        for (i = 0; i < W2_MAG_NUM; i = i + 1) begin

            $display(
                "-|w2| * x2, |w2| = %0d, product = %0d",
                i + 1,
                $signed(dut.prod_w2_neg[i])
            );

        end


        // =========================================================================
        // DONE
        // =========================================================================
        $display(
            "\ndone = %0d",
            done
        );


        // =========================================================================
        // FINAL LUT
        // =========================================================================
        $display("\nFinal LUT:");

        for (i = 0; i < W1_MAG_NUM; i = i + 1) begin

            // ---------------------------------------------------------------
            // Positive branch
            // ---------------------------------------------------------------
            for (j = 0; j < W2_MAG_NUM; j = j + 1) begin

                index =
                    i * 2 * W2_MAG_NUM
                    + j;

                $display(
                    "LUT[%0d]: %0d*x1 + %0d*x2 = %0d",
                    index,
                    i + 1,
                    j + 1,
                    $signed(
                        lut_out_flat[
                            index*P_Y +: P_Y
                        ]
                    )
                );

            end


            // ---------------------------------------------------------------
            // Negative branch
            // ---------------------------------------------------------------
            for (j = 0; j < W2_MAG_NUM; j = j + 1) begin

                index =
                    i * 2 * W2_MAG_NUM
                    + W2_MAG_NUM
                    + j;

                $display(
                    "LUT[%0d]: %0d*x1 - %0d*x2 = %0d",
                    index,
                    i + 1,
                    j + 1,
                    $signed(
                        lut_out_flat[
                            index*P_Y +: P_Y
                        ]
                    )
                );

            end

        end


        // Give simulation time to finish cleanly.
        #10;

        $finish;

    end

endmodule
