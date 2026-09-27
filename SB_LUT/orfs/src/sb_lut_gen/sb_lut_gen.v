`timescale 1ns / 1ps

//////////////////////////////////////////////////////////////////////////////////
// SB-LUT Generator
// Shared Broadcast LUT Generator for PALUTE Architecture
//
// W4A4 quantization
// Segment length b = 2
//
// w1 = 0 .. 7       -> 8 values
// w2 = -8 .. 7      -> 16 values
//
// Total LUT entries = 8 * 16 = 128
// Each entry = 4 bits
// Total LUT size = 512 bits
//
// Latency:
//   CYC1 -> compute w1*x1
//   CYC2 -> compute w2*x2
//   DONE -> generate 128 LUT entries
//////////////////////////////////////////////////////////////////////////////////

module sb_lut_gen (
    input  wire              clk,
    input  wire              rst_n,
    input  wire              start,

    input  wire signed [3:0] x1,
    input  wire signed [3:0] x2,

    output reg               done,
    output reg               lut_valid,
    output reg        [511:0] lut_out
);

    // State machine
    localparam IDLE = 2'd0;
    localparam CYC1 = 2'd1;
    localparam CYC2 = 2'd2;
    localparam DONE = 2'd3;

    reg [1:0] state;

    // Wider storage for multiplication results.
    // Maximum magnitude is safely represented here.
    reg signed [7:0] w1_x1 [0:7];
    reg signed [7:0] w2_x2 [0:15];

    integer i;
    integer j;
    integer idx;

    always @(posedge clk or negedge rst_n) begin

        if (!rst_n) begin

            state     <= IDLE;
            done      <= 1'b0;
            lut_valid <= 1'b0;
            lut_out   <= 512'd0;

            for (i = 0; i < 8; i = i + 1)
                w1_x1[i] <= 8'sd0;

            for (i = 0; i < 16; i = i + 1)
                w2_x2[i] <= 8'sd0;

        end else begin

            case (state)

                // -------------------------------------------------------------
                // IDLE
                // -------------------------------------------------------------
                IDLE: begin

                    done      <= 1'b0;
                    lut_valid <= 1'b0;

                    if (start)
                        state <= CYC1;

                end


                // -------------------------------------------------------------
                // CYCLE 1
                // Compute:
                //      w1 * x1
                //
                // where:
                //      w1 = 0 ... 7
                // -------------------------------------------------------------
                CYC1: begin

                    for (i = 0; i < 8; i = i + 1)
                        w1_x1[i] <= i * x1;

                    state <= CYC2;

                end


                // -------------------------------------------------------------
                // CYCLE 2
                // Compute:
                //      w2 * x2
                //
                // where:
                //      w2 = -8 ... 7
                // -------------------------------------------------------------
                CYC2: begin

                    for (i = 0; i < 16; i = i + 1)
                        w2_x2[i] <= (i - 8) * x2;

                    state <= DONE;

                end


                // -------------------------------------------------------------
                // CYCLE 3
                // Generate all 128 LUT entries.
                //
                // LUT entry:
                //
                //      LUT[i*16+j] = w1*x1 + w2*x2
                //
                // Only the lower 4 bits are stored.
                // -------------------------------------------------------------
                DONE: begin

                    idx = 0;

                    for (i = 0; i < 8; i = i + 1) begin

                        for (j = 0; j < 16; j = j + 1) begin

                            lut_out[(idx * 4) +: 4] <=
                                w1_x1[i] + w2_x2[j];

                            idx = idx + 1;

                        end

                    end

                    lut_valid <= 1'b1;
                    done      <= 1'b1;

                    state <= IDLE;

                end


                default: begin
                    state <= IDLE;
                end

            endcase

        end

    end

endmodule
