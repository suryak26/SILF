# BL-00 Provenance

## Exact baseline RTL

Source used for BL-00:

`~/palute_7nm_final/rtl/lut_gen_unit.v`

Local SHA256 recorded during the baseline inspection:

`911921624402b2cadb50350de2f3885be3c6b62fdbfeb80b7831a0812b746592`

The RTL is the 242-line parameterized LUT-generator implementation with 112-entry INT4 half-table behavior.

## Testbench

`~/palute_7nm_final/tb/tb_lut_gen_unit.v`

The testbench uses a 10 ns simulation clock and representative signed inputs x1=3, x2=-2, u=1. It observes the three generation stages and the final 112-entry LUT.

## Timing constraint

`~/palute_7nm_final/constraints/lut_gen_unit_5ns.sdc`

The synthesis/physical-design target is 5 ns / 200 MHz.

## ORFS configuration

`~/OpenROAD-flow-scripts/flow/designs/asap7/palute_lut_gen/config.mk`

The controlled configuration uses ASAP7, RVT, NLDM, TC, 50% core utilization, 1:1 core aspect ratio, and 0.60 placement density.

## ORFS loader change

The upstream ORFS `flow/scripts/load.tcl` was restored before the final run. The only local modification retained for the final baseline was:

```tcl
# PALUTE timing-unit fix:
# PALUTE SDC constraints are specified in ns.
set_cmd_units -time ns
```

This was inserted after the Liberty loader and before design/SDC loading.

## Final flow status

The design completed:

Yosys synthesis -> ASAP7 mapping -> floorplan -> placement -> CTS -> routing -> filler -> RC extraction -> post-route STA -> post-route power -> GDS/ODB generation.

## Repository scope

Large ODB/GDS/SPEF and generated intermediate databases are intentionally not embedded in this Git snapshot. The exact WSL paths and artifact names are recorded in the baseline record.
