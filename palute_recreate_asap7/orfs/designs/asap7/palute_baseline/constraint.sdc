create_clock -name clk -period 10.0 [get_ports clk]

set_input_delay 0.0 -clock clk [get_ports {rst_n x1 x2 w1_mag_flat w2_mag_flat}]
set_output_delay 0.0 -clock clk [get_ports {done lut_out_flat}]

set_false_path -from [get_ports rst_n]
