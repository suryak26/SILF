export PLATFORM = asap7

export DESIGN_NAME = palute_baseline_lut_gen

export VERILOG_FILES = $(sort $(wildcard $(DESIGN_HOME)/src/palute_baseline/*.v))
export SDC_FILE = $(DESIGN_HOME)/$(PLATFORM)/palute_baseline/constraint.sdc

export CORE_UTILIZATION = 65
export CORE_ASPECT_RATIO = 1
export CORE_MARGIN = 0.5
export PLACE_DENSITY = 0.35

export SYNTH_USE_SYN = 1
