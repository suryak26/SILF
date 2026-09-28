module asplut_gen_unit #(
    parameter P_X = 4,
    parameter P_W = 4,
    parameter P_Y = 9,
    parameter W1_MAG_NUM = 8,
    parameter W2_MAG_NUM = 7,
    parameter LUT_DEPTH = 112
)(
    input wire clk,
    input wire rst_n,
    input wire start,
    input wire u,
    input wire [P_X-1:0] x1,
    input wire [P_X-1:0] x2,
    output reg done,
    output reg [LUT_DEPTH*P_Y-1:0] lut_out_flat
);

    reg [6:0] cycle_cnt;
    reg running;
    reg [8:0] lut_mem [0:LUT_DEPTH-1];

    // Combinational logic for current cycle_cnt (0 to 111)
    wire [3:0] w1 = (cycle_cnt / 14) + 4'd1;
    wire [3:0] w2_idx = cycle_cnt % 14;
    wire [3:0] w2_mag = (w2_idx < 4'd7) ? (w2_idx + 4'd1) : (4'd14 - w2_idx);
    wire is_neg = (w2_idx >= 4'd7);

    // Explicit two's complement sign extension
    wire [8:0] x1_ext = x1[3] ? {5'b11111, x1} : {5'b00000, x1};
    wire [8:0] x2_ext = x2[3] ? {5'b11111, x2} : {5'b00000, x2};

    wire [8:0] w1_ext = {5'b00000, w1};
    wire [8:0] w2_ext_pos = {5'b00000, w2_mag};
    wire [8:0] w2_ext_neg = ~w2_ext_pos + 9'd1;
    wire [8:0] w2_ext = is_neg ? w2_ext_neg : w2_ext_pos;

    // Single-cycle compute (easily meets 500MHz in 7nm)
    wire [8:0] prod_w1 = x1_ext * w1_ext;
    wire [8:0] prod_w2 = x2_ext * w2_ext;
    wire [8:0] sum_val = u ? (prod_w1 + prod_w2) : prod_w1;

    localparam IDLE = 2'b00;
    localparam COMPUTE = 2'b01;
    localparam DONE_STATE = 2'b10;

    reg [1:0] state, next_state;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            cycle_cnt <= 7'd0;
            done <= 1'b0;
            running <= 1'b0;
        end else begin
            state <= next_state;
            case (state)
                IDLE: begin
                    done <= 1'b0;
                    if (start && !running) begin
                        running <= 1'b1;
                        cycle_cnt <= 7'd0; // Start at 0
                    end
                end
                COMPUTE: begin
                    // Write directly to memory at the current cycle_cnt
                    lut_mem[cycle_cnt] <= sum_val;

                    if (cycle_cnt == 7'd111) begin
                        running <= 1'b0;
                        state <= DONE_STATE;
                    end else begin
                        cycle_cnt <= cycle_cnt + 7'd1;
                    end
                end
                DONE_STATE: begin
                    done <= 1'b1;
                    state <= IDLE;
                end
            endcase
        end
    end

    always @(*) begin
        next_state = state;
        case (state)
            IDLE: if (start && !running) next_state = COMPUTE;
            COMPUTE: if (cycle_cnt == 7'd111) next_state = DONE_STATE;
            DONE_STATE: next_state = IDLE;
            default: next_state = IDLE;
        endcase
    end

    // Flatten 112 x 9-bit memory into 1008-bit output
    always @(*) begin
        integer i;
        for (i = 0; i < LUT_DEPTH; i = i + 1) begin
            lut_out_flat[i*P_Y +: P_Y] = lut_mem[i];
        end
    end

endmodule
