create_clock -name clk -period 5.0 [get_ports clk]

set_input_delay 0.5 -clock clk [get_ports {rst_n start x1 x2}]
set_output_delay 0.5 -clock clk [get_ports {done lut_valid lut_out}]

set_false_path -from [get_ports rst_n]
