# STATUS

## Completed

- [x] RTL implementation
- [x] RTL testbench
- [x] RTL waveform
- [x] ASAP7 Genus synthesis
- [x] ASAP7 area report
- [x] ASAP7 timing report
- [x] ASAP7 power report
- [x] synthesized gate-level netlist
- [x] Genus SDC
- [x] ORFS Docker/OpenROAD environment
- [x] Yosys synthesis in current ORFS attempt
- [x] diagnosis of OpenROAD signed-Verilog parser issue
- [x] previous complete ASAP7 ORFS baseline preserved in `~/SILF_ASAP7`

## Current blocker

The new ORFS flow stops when OpenROAD parses `1_2_yosys.v`, specifically on signed declarations such as:

```verilog
input signed [3:0] x1;
wire signed [3:0] x1;
```

A temporary unsigned copy parses successfully. The original RTL remains unchanged.

## Not yet completed for the current RTL

- [ ] current ORFS synthesis ODB
- [ ] current floorplan
- [ ] current placement
- [ ] current CTS
- [ ] current routing
- [ ] current GDS
- [ ] current post-route STA
- [ ] current post-route power
