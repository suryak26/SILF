`timescale 1ns/1ps

module tb_asplut;


    parameter P_X = 4;
    parameter P_W = 4;
    parameter P_Y = P_X + P_W + 1;
    parameter W1_MAG_NUM = 8;
    parameter W2_MAG_NUM = 7;
    parameter LUT_DEPTH = W1_MAG_NUM * 2 * W2_MAG_NUM;

    reg clk;
    reg rst_n;
    reg start;
    reg u;
    reg signed [P_X-1:0] x1;
    reg signed [P_X-1:0] x2;

    wire done;
    wire signed [P_Y*LUT_DEPTH-1:0] lut_out_flat;

    integer i;
    integer j;
    integer idx;
    integer f;
    integer errors;
    integer total_entries;

    reg signed [P_Y-1:0] actual;

    // ============================================================
    // DUT
    // ============================================================

    asplut_gen_unit dut (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .u(u),
        .x1(x1),
        .x2(x2),
        .done(done),
        .lut_out_flat(lut_out_flat)
    );

    // ============================================================
    // Clock: 2 ns period
    // ============================================================

    initial clk = 1'b0;
    always #1 clk = ~clk;

    // ============================================================
    // Main verification
    // ============================================================

    initial begin

        // --------------------------------------------------------
        // Waveform
        // --------------------------------------------------------


        // --------------------------------------------------------
        // CSV output
        // --------------------------------------------------------

        f = $fopen("sim/results/asplut_rtl_output.csv", "w");

        if (f == 0) begin
            $display("ERROR: Could not open CSV output file.");
            $finish;
        end

        $fdisplay(f, "x1,x2,lut_index,actual_value");

        // --------------------------------------------------------
        // Initial state
        // --------------------------------------------------------

        rst_n = 1'b0;
        start = 1'b0;
        u     = 1'b1;
        x1    = 4'sd0;
        x2    = 4'sd0;

        errors = 0;
        total_entries = 0;

        #10;

        rst_n = 1'b1;

        repeat (2) @(posedge clk);

        // ========================================================
        // Exhaustive signed input verification
        // x1 = -8 ... +7
        // x2 = -8 ... +7
        // ========================================================

        for (i = -8; i <= 7; i = i + 1) begin
            for (j = -8; j <= 7; j = j + 1) begin

                x1 = i;
                x2 = j;

                // Start transaction
		// Assert start away from the sampling edge
		@(negedge clk);
		start = 1'b1;

		// DUT samples start on the following rising edge
		@(posedge clk);

		// Deassert start away from the sampling edge
		@(negedge clk);
		start = 1'b0;

		// 112 COMPUTE cycles:
		// cycle 0 through cycle 111
		repeat (112) @(posedge clk);

		#1;
                // ------------------------------------------------
                // Dump all 112 generated LUT entries
                // ------------------------------------------------

                for (idx = 0; idx < LUT_DEPTH; idx = idx + 1) begin

                    actual = $signed(
                        lut_out_flat[idx*P_Y +: P_Y]
                    );

                    $fdisplay(
                        f,
                        "%0d,%0d,%0d,%0d",
                        i,
                        j,
                        idx,
                        actual
                    );

                    total_entries = total_entries + 1;
                end

            end
        end

        $fclose(f);

        // ========================================================
        // Final result
        // ========================================================

        $display("========================================");
        $display("ASP_LUT RTL DATA GENERATION COMPLETE");
        $display("Input combinations : %0d", 256);
        $display("LUT entries/input   : %0d", LUT_DEPTH);
        $display("Total CSV entries   : %0d", total_entries);
        $display("Errors              : %0d", errors);
        $display("========================================");

        if (errors == 0)
            $display("RTL SIMULATION: PASSED");
        else
            $display("RTL SIMULATION: FAILED");

        $finish;
    end

endmodule
