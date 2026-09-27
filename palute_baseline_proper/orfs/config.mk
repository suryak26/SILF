export PLATFORM        = asap7
export DESIGN_NAME     = lut_gen_unit
export DESIGN_NICKNAME  = palute_lut_gen

export VERILOG_FILES   = /home/surya_k/palute_7nm_final/rtl/lut_gen_unit.v
export SDC_FILE        = $(DESIGN_HOME)/$(PLATFORM)/$(DESIGN_NICKNAME)/constraint.sdc

export ASAP7_USE_VT = RVT
export LIB_MODEL    = NLDM
export CORNER       = TC

export CORE_UTILIZATION = 50
export CORE_ASPECT_RATIO = 1
export PLACE_DENSITY     = 0.60
export SYNTH_USE_SYN = 1
