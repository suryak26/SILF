###############################################################################
# ASPLUT synthesis constraints - ASAP7
# PALUTE baseline methodology: 200 MHz = 5000 ps
###############################################################################

current_design asplut_gen_unit

set_units -time ps

create_clock -name clk -period 5000.000 [get_ports {clk}]

set_input_delay 0.000 -clock [get_clocks {clk}] -add_delay \
    [get_ports {rst_n}]
set_input_delay 0.000 -clock [get_clocks {clk}] -add_delay \
    [get_ports {start}]
set_input_delay 0.000 -clock [get_clocks {clk}] -add_delay \
    [get_ports {u}]
set_input_delay 0.000 -clock [get_clocks {clk}] -add_delay \
    [get_ports {x1}]
set_input_delay 0.000 -clock [get_clocks {clk}] -add_delay \
    [get_ports {x2}]

set_output_delay 0.000 -clock [get_clocks {clk}] -add_delay \
    [get_ports {done}]
set_output_delay 0.000 -clock [get_clocks {clk}] -add_delay \
    [get_ports {lut_out_flat}]

set_false_path -from [get_ports {rst_n}]

set_drive 0.0 [all_inputs]
set_load 0.01 [all_outputs]
