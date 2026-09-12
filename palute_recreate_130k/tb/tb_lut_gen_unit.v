`timescale 1ns/1ps
// Self-checking testbench for lut_gen_unit (runtime-multiplier baseline).
// Verifies every LUT entry against the expected arithmetic:
//   u=1 : LUT[i][j]    = x1*(i+1) + x2*(j+1)   (positive half-row)
//         LUT[i][j+7]  = x1*(i+1) - x2*(j+1)   (negative half-row)
//   u=0 : LUT[i]       = x1*(i+1)              (w1 products only), rest 0
module tb_lut_gen_unit;

    localparam P_X = 4;
    localparam P_W = 4;
    localparam P_Y = P_X + P_W + 1;

    localparam W1_MAG_NUM = 8;
    localparam W2_MAG_NUM = 7;
    localparam LUT_DEPTH  = W1_MAG_NUM * 2 * W2_MAG_NUM; // 112

    reg clk;
    reg rst_n;
    reg start;
    reg u;

    reg signed [P_X-1:0] x1;
    reg signed [P_X-1:0] x2;

    wire done;
    wire signed [P_Y*LUT_DEPTH-1:0] lut_out_flat;

    lut_gen_unit #(
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
        .done(done),
        .lut_out_flat(lut_out_flat)
    );

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    integer errors;
    integer i, j, idx, exp_val, got_val;

    task check_entry;
        input integer idx_in;
        input integer exp_in;
        begin
            got_val = $signed(lut_out_flat[idx_in*P_Y +: P_Y]);
            if (got_val !== exp_in) begin
                errors = errors + 1;
                $display("  MISMATCH LUT[%0d]: got %0d, expected %0d",
                         idx_in, got_val, exp_in);
            end
        end
    endtask

    task run_case;
        input integer tx1;
        input integer tx2;
        input integer tu;
        integer k;
        begin
            @(negedge clk);
            x1 = tx1; x2 = tx2; u = tu; start = 1;
            @(negedge clk);
            start = 0;

            k = 0;
            while (!done && k < 200) begin @(negedge clk); k = k + 1; end
            if (!done) begin
                errors = errors + 1;
                $display("  TIMEOUT waiting for done (x1=%0d x2=%0d u=%0d)",
                         tx1, tx2, tu);
            end
            #1;
            if (tu != 0) begin
                for (i = 0; i < W1_MAG_NUM; i = i + 1) begin
                    for (j = 0; j < W2_MAG_NUM; j = j + 1) begin
                        check_entry(i*(2*W2_MAG_NUM) + j,          tx1*(i+1) + tx2*(j+1));
                        check_entry(i*(2*W2_MAG_NUM) + W2_MAG_NUM + j, tx1*(i+1) - tx2*(j+1));
                    end
                end
            end else begin
                for (i = 0; i < W1_MAG_NUM; i = i + 1)
                    check_entry(i, tx1*(i+1));
                for (idx = W1_MAG_NUM; idx < LUT_DEPTH; idx = idx + 1)
                    check_entry(idx, 0);
            end
            $display("Case x1=%0d x2=%0d u=%0d done in %0d clk cycles",
                     tx1, tx2, tu, k+1);
        end
    endtask

    initial begin
        errors = 0;
        rst_n = 0; start = 0; u = 1; x1 = 0; x2 = 0;
        repeat (2) @(negedge clk);
        rst_n = 1;
        @(negedge clk);

        // u=1: full LUT, typical and corner values of the 4-bit signed inputs
        run_case( 3, -2, 1);
        run_case(-8, -8, 1);
        run_case(-8,  7, 1);
        run_case( 7, -8, 1);
        run_case( 7,  7, 1);
        run_case( 0,  5, 1);
        run_case( 1,  0, 1);
        // u=0: w1 products only
        run_case( 3, -2, 0);
        run_case(-8,  7, 0);
        run_case( 7,  7, 0);

        if (errors == 0)
            $display("PASS: all %0d LUT entries across 10 cases match expected values",
                     7*LUT_DEPTH + 3*W1_MAG_NUM + 3*(LUT_DEPTH-W1_MAG_NUM));
        else
            $display("FAIL: %0d mismatching LUT entries", errors);
        $finish;
    end
endmodule