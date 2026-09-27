`timescale 1ns/1ps

module tb_debug;

    reg clk_1, clk_2, clk_3;
    reg rst_n, start, u;
    reg signed [3:0] x1, x2;

    wire done;
    wire signed [1007:0] lut_out_flat;

    pulse_latch_pipe dut (
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

    initial begin
        clk_1 = 0;
        clk_2 = 0;
        clk_3 = 0;

        forever begin
            clk_1 = 1; #10;
            clk_1 = 0;
            #2;

            clk_2 = 1; #10;
            clk_2 = 0;
            #2;

            clk_3 = 1; #10;
            clk_3 = 0;
            #6;
        end
    end

    initial begin
        rst_n = 0;
        start = 0;
        u = 1;
        x1 = 0;
        x2 = 0;

        #20 rst_n = 1;

        @(posedge clk_1);
        #1;

        x1 = 4'sd3;
        x2 = -4'sd2;
        start = 1;

        @(posedge clk_1);
        #1;

        start = 0;

        wait(done == 1);
        #5;

        $display("==========================================");
        $display("INTERNAL PIPELINE DEBUG");
        $display("==========================================");

        $display("Input x1              = %0d", $signed(x1));
        $display("Input x2              = %0d", $signed(x2));
        $display("Input u               = %0d", u);

        $display("------------------------------------------");

        $display("u_s1                  = %0d", dut.u_s1);
        $display("x1_s1                 = %0d", $signed(dut.x1_s1));
        $display("x2_s1                 = %0d", $signed(dut.x2_s1));

        $display("------------------------------------------");

        $display("prod_w1_s1[0]         = %0d",
                 $signed(dut.prod_w1_s1[0]));

        $display("prod_w1_s1[1]         = %0d",
                 $signed(dut.prod_w1_s1[1]));

        $display("prod_w2_pos_s2[0]     = %0d",
                 $signed(dut.prod_w2_pos_s2[0]));

        $display("prod_w2_neg_s2[0]     = %0d",
                 $signed(dut.prod_w2_neg_s2[0]));

        $display("------------------------------------------");

        $display("Expected prod_w1[0]   = 3");
        $display("Expected prod_w2_pos[0] = -2");
        $display("Expected LUT[0]       = 1");

        $display("------------------------------------------");

        $display("LUT[0]                = %0d",
                 $signed(lut_out_flat[8:0]));

        $display("LUT[111]              = %0d",
                 $signed(lut_out_flat[1007:999]));

        $display("done                  = %0d", done);

        $display("==========================================");

        $finish;
    end

endmodule
