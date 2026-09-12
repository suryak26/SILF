`timescale 1ns/1ps
module mega_adder #(
    parameter IN_W  = 8,
    parameter OUT_W = 9
)(
    input  wire signed [IN_W-1:0]  a,
    input  wire signed [IN_W-1:0]  b,
    output wire signed [OUT_W-1:0] sum
);
    wire signed [OUT_W-1:0] a_ext = a;
    wire signed [OUT_W-1:0] b_ext = b;
    assign sum = a_ext + b_ext;
endmodule
