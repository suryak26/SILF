`timescale 1ns/1ps

module tb_pulse_latch;

    localparam P_X = 4;
    localparam P_W = 4;
    localparam P_Y = P_X + P_W + 1;
    localparam W1_MAG_NUM = 8;
    localparam W2_MAG_NUM = 7;
    localparam LUT_DEPTH = 112;

    reg rst_n;
    reg start;
    reg u;

    reg signed [P_X-1:0] x1;
    reg signed [P_X-1:0] x2;

    wire done;
    wire signed [P_Y*LUT_DEPTH-1:0] lut_out_flat;

    reg clk_1;
    reg clk_2;
    reg clk_3;

    // ------------------------------------------------------------
    // DUT
    // ------------------------------------------------------------

    pulse_latch_pipe #(
        P_X,
        P_W,
        P_Y,
        W1_MAG_NUM,
        W2_MAG_NUM,
        LUT_DEPTH
    ) dut (
        .clk_1(clk_1),
        .clk_2(clk_2),
        .clk_3(clk_3),
        .rst_n(rst_n),
        .start(start),
        .u(u),
        .x1(x1),
        .x2(x2),
        .done(done),
        .lut_out_flat(lut_out_flat)
    );

    // ------------------------------------------------------------
    // Phase-shifted clocks
    // ------------------------------------------------------------

    initial begin
        clk_1 = 0;
        clk_2 = 0;
        clk_3 = 0;

        forever begin
            clk_1 = 1;
            #10;
            clk_1 = 0;

            #2;

            clk_2 = 1;
            #10;
            clk_2 = 0;

            #2;

            clk_3 = 1;
            #10;
            clk_3 = 0;

            #6;
        end
    end

    // ------------------------------------------------------------
    // Stimulus
    // ------------------------------------------------------------

    initial begin
        rst_n = 0;
        start = 0;
        u = 1;

        x1 = 0;
        x2 = 0;

        // Release reset
        #20;
        rst_n = 1;

        // --------------------------------------------------------
        // Apply input.
        // --------------------------------------------------------

        @(posedge clk_1);
        #1;

        x1 = 4'sd3;
        x2 = -4'sd2;
        start = 1;

        // --------------------------------------------------------
        // IMPORTANT:
        // Keep start HIGH through Stage 1, Stage 2 and Stage 3.
        //
        // Stage 3 occurs after Stage 2, so we must not deassert
        // start immediately after the next clk_1 edge.
        // --------------------------------------------------------

        @(posedge clk_3);
        #1;

        // At this point Stage 3 has captured the LUT.
        // It is now safe to release the input isolation.
        start = 0;

        #1;

        // --------------------------------------------------------
        // Expected:
        //
        // x1 =  3
        // x2 = -2
        //
        // LUT[0]   = 1*3 + 1*(-2)
        //          = 1
        //
        // LUT[111] = 8*3 - 7*(-2)
        //           = 38
        // --------------------------------------------------------

        $display("--------------------------------------------------");
        $display("Pulsed Latch LUT Simulation Complete.");

        $display("LUT[0]   = %0d (Expected: 1)",
                 $signed(lut_out_flat[8:0]));

        $display("LUT[111] = %0d (Expected: 38)",
                 $signed(lut_out_flat[1007:999]));

        if (($signed(lut_out_flat[8:0]) == 1) &&
            ($signed(lut_out_flat[1007:999]) == 38)) begin

            $display("TEST PASSED: LUT values are correct.");

        end else begin

            $display("TEST FAILED: LUT values mismatch.");

        end

        $display("--------------------------------------------------");

        #50;
        $finish;
    end

    // ------------------------------------------------------------
    // VCD
    // ------------------------------------------------------------

    initial begin
        $dumpfile("pulse_latch_pipe.vcd");
        $dumpvars(0, tb_pulse_latch);
    end

endmodule
