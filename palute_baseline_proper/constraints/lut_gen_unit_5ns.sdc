# PALUTE LUT Generator BL-00
# ASAP7
# 200 MHz target = 5.000 ns

set_cmd_units -time ns
set clk_name clk
set clk_port_name clk
set clk_period 5.000
set clk_port [get_ports $clk_port_name]
create_clock -name $clk_name -period $clk_period $clk_port

set non_clock_inputs [get_ports {rst_n start u x1 x2}]
set_input_delay 0.000 -clock [get_clocks $clk_name] $non_clock_inputs
set_output_delay 0.000 -clock [get_clocks $clk_name] [all_outputs]

set_false_path -from [get_ports rst_n]
