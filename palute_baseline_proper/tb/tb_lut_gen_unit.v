`timescale 1ns/1ps

module tb_lut_gen_unit;

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

    wire done;
    wire signed [P_Y*LUT_DEPTH-1:0] lut_out_flat;

    integer i;
    integer j;
    integer index;

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

    initial begin
        rst_n = 0;
        start = 0;
        u     = 1;
        x1    = 0;
        x2    = 0;

        repeat (2) @(posedge clk);
        @(negedge clk);
        rst_n = 1;

        @(negedge clk);
        x1    = 3;
        x2    = -2;
        start = 1;

        @(posedge clk);
        #1;
        $display("Input: x1 = %0d, x2 = %0d",
                 $signed(x1), $signed(x2));

        @(negedge clk);
        start = 0;

        @(posedge clk);
        #1;
        $display("\nCycle 1: generate |w1| * x1");

        for (i = 0; i < W1_MAG_NUM; i = i + 1) begin
            $display("|w1| = %0d, product = %0d",
                     i + 1,
                     $signed(dut.prod_w1[i]));
        end

        @(posedge clk);
        #1;
        $display("\nCycle 2: generate +|w2| * x2");

        for (i = 0; i < W2_MAG_NUM; i = i + 1) begin
            $display("|w2| = %0d, product = %0d",
                     i + 1,
                     $signed(dut.prod_w2_pos[i]));
        end

        @(posedge clk);
        #1;
        $display("\nCycle 3: generate -|w2| * x2 and LUT");

        for (i = 0; i < W2_MAG_NUM; i = i + 1) begin
            $display("-|w2| * x2, |w2| = %0d, product = %0d",
                     i + 1,
                     $signed(dut.prod_w2_neg[i]));
        end

        $display("\ndone = %0d", done);
        $display("\nFinal LUT:");

        for (i = 0; i < W1_MAG_NUM; i = i + 1) begin
            for (j = 0; j < W2_MAG_NUM; j = j + 1) begin
                index = i * 2 * W2_MAG_NUM + j;

                $display(
                    "LUT[%0d]: %0d*x1 + %0d*x2 = %0d",
                    index,
                    i + 1,
                    j + 1,
                    $signed(lut_out_flat[index*P_Y +: P_Y])
                );
            end

            for (j = 0; j < W2_MAG_NUM; j = j + 1) begin
                index = i * 2 * W2_MAG_NUM
                        + W2_MAG_NUM + j;

                $display(
                    "LUT[%0d]: %0d*x1 - %0d*x2 = %0d",
                    index,
                    i + 1,
                    j + 1,
                    $signed(lut_out_flat[index*P_Y +: P_Y])
                );
            end
        end

        #10;
        $finish;
    end

endmodule
