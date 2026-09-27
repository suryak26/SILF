current_design pulse_latch_pipe

create_clock -name clk_3 -period 10.0 [get_ports clk_3]

set_input_delay 0.0 -clock clk_3 [get_ports {clk_1 clk_2 start u x1 x2 rst_n}]
set_output_delay 0.0 -clock clk_3 [get_ports {done lut_out_flat}]

set_false_path -from [get_ports rst_n]
