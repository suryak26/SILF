`timescale 1ns / 1ps

//////////////////////////////////////////////////////////////////////////////////
// Testbench for SB-LUT Generator
//
// Tests:
//   1. x1 = 3,  x2 = -2
//   2. x1 = -4, x2 = 5
//   3. x1 = 7,  x2 = -8
//
// Also generates:
//      sim/waveform.vcd
//////////////////////////////////////////////////////////////////////////////////

module tb_sb_lut_gen;

    reg clk;
    reg rst_n;
    reg start;

    reg signed [3:0] x1;
    reg signed [3:0] x2;

    wire done;
    wire lut_valid;
    wire [511:0] lut_out;


    // -------------------------------------------------------------------------
    // DUT
    // -------------------------------------------------------------------------

    sb_lut_gen dut (
        .clk       (clk),
        .rst_n     (rst_n),
        .start     (start),
        .x1        (x1),
        .x2        (x2),
        .done      (done),
        .lut_valid (lut_valid),
        .lut_out   (lut_out)
    );


    // -------------------------------------------------------------------------
    // 200 MHz clock
    // Period = 5 ns
    // -------------------------------------------------------------------------

    initial begin
        clk = 1'b0;
        forever #2.5 clk = ~clk;
    end


    // -------------------------------------------------------------------------
    // Waveform dump
    // -------------------------------------------------------------------------

    initial begin
        $dumpfile("sim/waveform.vcd");
        $dumpvars(0, tb_sb_lut_gen);
    end


    // -------------------------------------------------------------------------
    // Test procedure
    // -------------------------------------------------------------------------

    task run_test;

        input signed [3:0] test_x1;
        input signed [3:0] test_x2;

        integer i;
        integer j;
        integer entry;

        integer expected;
        integer actual;

        reg test_passed;

        begin

            x1 = test_x1;
            x2 = test_x2;

            test_passed = 1'b1;

            $display("");
            $display("========================================");
            $display("TEST: x1 = %0d, x2 = %0d", x1, x2);
            $display("========================================");

            // Start pulse
            @(negedge clk);
            start = 1'b1;

            @(negedge clk);
            start = 1'b0;

            // Wait for completion
            wait (done === 1'b1);

            // Check all 128 entries
            for (i = 0; i < 8; i = i + 1) begin

                for (j = 0; j < 16; j = j + 1) begin

                    entry = i * 16 + j;

                    expected =
                        (i * test_x1) +
                        ((j - 8) * test_x2);

                    // Convert expected result to signed 4-bit
                    expected = expected & 16'hF;

                    // Convert LUT entry to unsigned integer first
                    actual = lut_out[(entry * 4) +: 4];

                    // Compare lower four bits
                    if (actual !== expected) begin

                        $display(
                            "FAIL: Entry[%0d] w1=%0d w2=%0d Expected=%0d Got=%0d",
                            entry,
                            i,
                            j - 8,
                            expected,
                            actual
                        );

                        test_passed = 1'b0;

                    end

                end

            end


            if (lut_valid && test_passed) begin

                $display("PASS: All 128 LUT entries verified.");
                $display("x1 = %0d, x2 = %0d", x1, x2);

            end else begin

                $display("FAIL: LUT validation failed.");

            end

            // Allow return to IDLE
            @(posedge clk);

        end

    endtask


    // -------------------------------------------------------------------------
    // Main simulation
    // -------------------------------------------------------------------------

    initial begin

        rst_n = 1'b0;
        start = 1'b0;

        x1 = 4'sd0;
        x2 = 4'sd0;


        // Reset
        #10;
        rst_n = 1'b1;

        // Allow one clock
        #10;


        // Test 1
        run_test(4'sd3, -4'sd2);

        #20;


        // Test 2
        run_test(-4'sd4, 4'sd5);

        #20;


        // Test 3
        run_test(4'sd7, -4'sd8);

        #20;


        $display("");
        $display("========================================");
        $display("ALL SB-LUT TESTS COMPLETED");
        $display("Waveform: sim/waveform.vcd");
        $display("========================================");


        #20;
        $finish;

    end

endmodule
