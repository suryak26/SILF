`timescale 1ns/1ps

module tb_asplut;

    reg clk;
    reg rst_n;
    reg start;
    reg u;
    reg [3:0] x1;
    reg [3:0] x2;

    wire done;
    wire [1007:0] lut_out_flat;

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

    // 100 MHz clock
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Waveform
    initial begin
        $dumpfile("sim/waveforms/asplut_simulation.vcd");
        $dumpvars(0, tb_asplut);
    end

    integer i;
    integer errors;

    reg signed [8:0] expected_lut [0:111];
    reg signed [8:0] actual_lut [0:111];

    initial begin

        rst_n = 0;
        start = 0;
        u = 1;
        x1 = 4'sd3;
        x2 = -4'sd2;
        errors = 0;

        // Reset
        #20;
        rst_n = 1;
        #20;

        $display("========================================");
        $display("ASPLUT Functional Verification");
        $display("Test Case 1: x1=%0d, x2=%0d, u=%0d",
                 $signed(x1), $signed(x2), u);
        $display("========================================");

        // Expected LUT
        for (i = 0; i < 112; i = i + 1) begin
            integer w1;
            integer w2_idx;
            integer w2;

            w1 = (i / 14) + 1;
            w2_idx = i % 14;

            if (w2_idx < 7)
                w2 = w2_idx + 1;
            else
                w2 = -(14 - w2_idx);

            expected_lut[i] =
                (w1 * $signed(x1)) +
                (w2 * $signed(x2));
        end

        // Start LUT generation
        start = 1;
        #10;
        start = 0;

        // Wait for completion
        wait(done);
        #20;

        // Extract LUT
        for (i = 0; i < 112; i = i + 1)
            actual_lut[i] = lut_out_flat[i*9 +: 9];

        // Verify
        $display("\nVerifying LUT entries...");

        for (i = 0; i < 112; i = i + 1) begin
            if (actual_lut[i] !== expected_lut[i]) begin
                $display(
                    "ERROR: Entry[%0d] Expected=%0d, Actual=%0d",
                    i,
                    expected_lut[i],
                    actual_lut[i]
                );
                errors = errors + 1;
            end
        end

        if (errors == 0) begin
            $display("\n========================================");
            $display("[SUCCESS] All 112 LUT entries verified!");
            $display("Entry 0   : %0d", actual_lut[0]);
            $display("Entry 56  : %0d", actual_lut[56]);
            $display("Entry 111 : %0d", actual_lut[111]);
            $display("========================================");
        end
        else begin
            $display("\n========================================");
            $display("[FAILURE] %0d errors found", errors);
            $display("========================================");
        end

        // ------------------------------------------------
        // Test Case 2: u = 0
        // ------------------------------------------------
        #50;

        $display("\n========================================");
        $display("Test Case 2: u=0 (x1 only mode)");
        $display("========================================");

        u = 0;
        x1 = 4'sd5;
        x2 = 4'sd0;

        start = 1;
        #10;
        start = 0;

        wait(done);
        #20;

        $display(
            "Entry 0   : %0d (expected: 5)",
            $signed(lut_out_flat[8:0])
        );

        $display(
            "Entry 111 : %0d (expected: 40)",
            $signed(lut_out_flat[1007:999])
        );

        #50;

        $finish;
    end

    // Monitor
    initial begin
        $monitor(
            "Time=%0t | state=%b | cycle_cnt=%0d | done=%b",
            $time,
            dut.state,
            dut.cycle_cnt,
            done
        );
    end

endmodule
