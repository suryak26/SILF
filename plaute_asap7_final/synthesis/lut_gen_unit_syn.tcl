# ========== 0. Basic setup ==========
puts "\n==== [clock format [clock seconds]] : Start Genus Synthesis for Acc ====\n"

# Use legacy UI so set_attribute / read_hdl / elaborate work
set_db common_ui false

# Allow loop unrolling for initialization and parallel adder write-back loops
set_attribute hdl_max_loop_limit 200000

# RTL search path.
# Acc.v and adder_signed.v should both be located under ../rtl/
set_attribute hdl_search_path { ../rtl }

# Output directories
set report_dir  ./reports
set netlist_dir ./netlist
file mkdir $report_dir
file mkdir $netlist_dir

# ========== 1. Library setup ==========
puts "===> [clock format [clock seconds]] : Setting up ASAP7 libraries ..."

set_attribute lib_search_path {
    /home/shared/asap7/asap7sc7p5t_28/LIB/NLDM/extracted
}

set_attribute library {
    /home/shared/asap7/asap7sc7p5t_28/LIB/NLDM/extracted/asap7sc7p5t_AO_LVT_TT_nldm_211120.lib
    /home/shared/asap7/asap7sc7p5t_28/LIB/NLDM/extracted/asap7sc7p5t_AO_RVT_TT_nldm_211120.lib
    /home/shared/asap7/asap7sc7p5t_28/LIB/NLDM/extracted/asap7sc7p5t_AO_SRAM_TT_nldm_211120.lib
    /home/shared/asap7/asap7sc7p5t_28/LIB/NLDM/extracted/asap7sc7p5t_OA_LVT_TT_nldm_211120.lib
    /home/shared/asap7/asap7sc7p5t_28/LIB/NLDM/extracted/asap7sc7p5t_OA_RVT_TT_nldm_211120.lib
    /home/shared/asap7/asap7sc7p5t_28/LIB/NLDM/extracted/asap7sc7p5t_OA_SRAM_TT_nldm_211120.lib
    /home/shared/asap7/asap7sc7p5t_28/LIB/NLDM/extracted/asap7sc7p5t_SEQ_LVT_TT_nldm_220123.lib
    /home/shared/asap7/asap7sc7p5t_28/LIB/NLDM/extracted/asap7sc7p5t_SEQ_RVT_TT_nldm_220123.lib
    /home/shared/asap7/asap7sc7p5t_28/LIB/NLDM/extracted/asap7sc7p5t_SEQ_SRAM_TT_nldm_220123.lib
    /home/shared/asap7/asap7sc7p5t_28/LIB/NLDM/extracted/asap7sc7p5t_SIMPLE_LVT_TT_nldm_211120.lib
    /home/shared/asap7/asap7sc7p5t_28/LIB/NLDM/extracted/asap7sc7p5t_SIMPLE_RVT_TT_nldm_211120.lib
    /home/shared/asap7/asap7sc7p5t_28/LIB/NLDM/extracted/asap7sc7p5t_SIMPLE_SRAM_TT_nldm_211120.lib
    /home/shared/asap7/asap7sc7p5t_28/LIB/NLDM/extracted/asap7sc7p5t_INVBUF_LVT_TT_nldm_220122.lib
    /home/shared/asap7/asap7sc7p5t_28/LIB/NLDM/extracted/asap7sc7p5t_INVBUF_RVT_TT_nldm_220122.lib
    /home/shared/asap7/asap7sc7p5t_28/LIB/NLDM/extracted/asap7sc7p5t_INVBUF_SRAM_TT_nldm_220122.lib
}

# Unlock all library cells
puts "===> [clock format [clock seconds]] : Unlocking library cells ..."

set libcells [get_lib_cells */*]

if { [sizeof_collection $libcells] > 0 } {
    set_attribute preserve false $libcells
    set_attribute avoid    false $libcells
} else {
    puts "WARNING: No library cells found. Check the ASAP7 library paths."
}

# ========== 2. Read RTL ==========
puts "===> [clock format [clock seconds]] : Reading RTL source files ..."

read_hdl {lut_gen_unit.v}

# ========== 3. Elaborate ==========
puts "===> [clock format [clock seconds]] : Elaborating top module Acc ..."

elaborate lut_gen_unit
current_design lut_gen_unit

# Optional structural check
check_design -unresolved

# ========== 4. Timing constraints ==========
puts "===> [clock format [clock seconds]] : Applying timing constraints ..."

# Clock period inherited from your original script.
# Confirm the library/report time unit before interpreting frequency.
set CLK_PERIOD 2000

create_clock -name clk -period $CLK_PERIOD [get_ports clk]

# Data inputs are start and element_in_flat.
# rst_n is asynchronous reset and should not be treated as synchronous input data.
set data_inputs [remove_from_collection [all_inputs] [get_ports clk]]
set data_inputs [remove_from_collection $data_inputs [get_ports rst_n]]

set_input_delay  2 -clock clk $data_inputs
set_output_delay 2 -clock clk [all_outputs]

# Asynchronous reset timing is excluded from normal data-path timing analysis
set_false_path -from [get_ports rst_n]

# ========== 5. Synthesis flow ==========
puts "===> [clock format [clock seconds]] : Running syn_generic ..."
syn_generic

puts "===> [clock format [clock seconds]] : Running syn_map ..."
syn_map

puts "===> [clock format [clock seconds]] : Running syn_opt ..."
syn_opt

# ========== 6. Reports ==========
puts "===> [clock format [clock seconds]] : Writing synthesis reports ..."

report_timing > $report_dir/timing.rpt
report_area   > $report_dir/area.rpt
report_power  > $report_dir/power.rpt

# ========== 7. Output netlist and constraints ==========
puts "===> [clock format [clock seconds]] : Exporting synthesized netlist and SDC ..."

write_hdl > $netlist_dir/syn.v
write_sdc > $netlist_dir/syn.sdc

# ========== 8. Done ==========
puts "\n==== [clock format [clock seconds]] : Genus Synthesis for Acc COMPLETED SUCCESSFULLY ====\n"
