# BL-00 Flow Record

## Host/tool environment

- WSL2
- Docker
- OpenROAD-flow-scripts
- Builder image: openroad/flow-ubuntu22.04-builder:9ed603
- OpenROAD: 26Q3-2056-g41a28926b9
- Yosys: 0.68+post
- ASAP7 platform

## Controlled source

RTL:
~/palute_7nm_final/rtl/lut_gen_unit.v

ORFS design:
~/OpenROAD-flow-scripts/flow/designs/asap7/palute_lut_gen/config.mk

SDC:
~/OpenROAD-flow-scripts/flow/designs/asap7/palute_lut_gen/constraint.sdc

## Flow

The completed BL-00 flow was run through synthesis, floorplan, placement, CTS, global routing, detailed routing, filler insertion, RC extraction, post-route STA, power analysis, and GDS generation.

## Important reproducibility rule

Do not change the baseline RTL, PVT, library model, clock, core utilization, placement density, or reporting method when producing an optimization comparison. Make a new experiment record instead.
