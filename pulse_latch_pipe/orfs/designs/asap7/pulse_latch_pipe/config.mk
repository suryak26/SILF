export PLATFORM = asap7

export DESIGN_NAME = pulse_latch_pipe

export VERILOG_FILES = $(sort $(wildcard $(DESIGN_HOME)/src/$(DESIGN_NAME)/*.v))
export SDC_FILE = $(DESIGN_HOME)/$(PLATFORM)/$(DESIGN_NAME)/constraint.sdc

export CORE_UTILIZATION = 65
export CORE_ASPECT_RATIO = 1
export CORE_MARGIN = 0.5
export PLACE_DENSITY = 0.35

export SYNTH_USE_SYN = 1
