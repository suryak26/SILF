`timescale 1ns/1ps
// Generic runtime multiplier: the weight (magnitude) is a RUNTIME SIGNAL,
// so synthesis must implement genuine multiplier hardware instead of
// specializing a compile-time constant into shift-add logic.
//
// The magnitude values 1..8 are enumerated on-chip by the magnitude
// generator in lut_gen_unit and latched into per-lane registers before
// the multipliers are used, so no compile-time constant reaches this
// module.
module mega_multiplier #(
    parameter P_X       = 4,
    parameter PROD_W    = 8
)(
    input  wire signed [P_X-1:0]     value,
    input  wire        [3:0]         magnitude,    // runtime weight (used 1..8)
    output wire signed [PROD_W-1:0]  product
);
    // Explicit signed extension: value is signed (range -8..7 for P_X=4),
    // magnitude is unsigned (0..15) so the value 8 is representable.
    // Worst-case |product| = 8*15 = 120 fits in PROD_W = 8 signed bits.
    wire signed [PROD_W-1:0] v_sext = value;
    wire signed [PROD_W-1:0] m_sext = $signed({1'b0, magnitude});
    assign product = v_sext * m_sext;
endmodule