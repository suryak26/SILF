# PALUTE LUT Generator
# ASAP7 ASIC baseline
# Target clock period = 5 ns (200 MHz)

create_clock -name clk -period 5.000 [get_ports clk]
set_clock_uncertainty 0.000 [get_clocks clk]

set_input_delay 0.000 -clock [get_clocks clk] [get_ports {start u x1 x2}]
set_output_delay 0.000 -clock [get_clocks clk] [get_ports {done lut_out_flat}]

set_false_path -from [get_ports rst_n]
