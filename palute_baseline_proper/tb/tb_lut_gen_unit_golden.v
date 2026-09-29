`timescale 1ns/1ps

module tb_lut_gen_unit_golden;

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

    integer x1_i;
    integer x2_i;
    integer u_i;
    integer lut_i;
    integer total_entries;
    integer errors;
    integer fd;

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
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    initial begin
        fd = $fopen("palute_baseline_proper/sim/results/palute_rtl_output.csv", "w");

        if (fd == 0) begin
            $display("ERROR: Could not open CSV output file.");
            $finish;
        end

        $fwrite(fd, "u,x1,x2,lut_index,actual_value\n");

        rst_n = 1'b0;
        start = 1'b0;
        u     = 1'b0;
        x1    = '0;
        x2    = '0;

        repeat (2) @(posedge clk);
        @(negedge clk);
        rst_n = 1'b1;

        total_entries = 0;
        errors        = 0;

        for (u_i = 0; u_i <= 1; u_i = u_i + 1) begin
            for (x1_i = -8; x1_i <= 7; x1_i = x1_i + 1) begin
                for (x2_i = -8; x2_i <= 7; x2_i = x2_i + 1) begin

                    @(negedge clk);
                    u     = u_i;
                    x1    = x1_i;
                    x2    = x2_i;
                    start = 1'b1;

                    @(posedge clk);
                    @(negedge clk);
                    start = 1'b0;

                    if (u_i == 0)
                        repeat (1) @(posedge clk);
                    else
                        repeat (3) @(posedge clk);

                    #1;

                    if (!done) begin
                        $display(
                            "ERROR: done not asserted for u=%0d, x1=%0d, x2=%0d",
                            u_i, x1_i, x2_i
                        );
                        errors = errors + 1;
                    end

                    for (lut_i = 0; lut_i < LUT_DEPTH; lut_i = lut_i + 1) begin
                        $fwrite(
                            fd,
                            "%0d,%0d,%0d,%0d,%0d\n",
                            u_i,
                            x1_i,
                            x2_i,
                            lut_i,
                            $signed(lut_out_flat[lut_i*P_Y +: P_Y])
                        );

                        total_entries = total_entries + 1;
                    end

                    @(negedge clk);
                end
            end
        end

        $fclose(fd);

        $display("========================================");
        $display("PALUTE RTL DATA GENERATION COMPLETE");
        $display("Input combinations : 256");
        $display("u modes             : 2");
        $display("LUT entries/input   : 112");
        $display("Total CSV entries   : %0d", total_entries);
        $display("Errors              : %0d", errors);
        $display("========================================");

        if ((total_entries == 2 * 256 * 112) && (errors == 0))
            $display("RTL SIMULATION: PASSED");
        else
            $display("RTL SIMULATION: FAILED");

        $finish;
    end

endmodule
