# PALUTE 7nm Final ASIC Work Package

This folder contains the consolidated PALUTE/SILF ASIC work completed so far.

## Contents

- `FINAL_PROJECT_REPORT.md` — detailed technical report
- `rtl/` — LUT-generator RTL
- `tb/` — RTL testbench
- `constraints/` — ORFS 5 ns SDC
- `synthesis/` — Cadence Genus synthesis script
- `netlist/genus/` — synthesized gate-level Verilog and SDC
- `reports/genus/` — area, timing and power reports
- `verification/` — RTL simulation artifact
- `docs/` — architecture proposal
- `scripts/` — helper scripts for importing the earlier ORFS run

## Key measured synthesis results

- ASAP7 Genus cell count: **4095**
- Cell area: **620.204**
- Critical path delay: **666 ps**
- Reported slack at 2 ns clock: **1334 ps**
- Reported total power: **1.28015 mW**

## ORFS status

The OpenROAD/ORFS Docker environment was successfully built and Yosys synthesis of the current RTL completed successfully.

The current ORFS run is blocked during OpenROAD parsing of the Yosys-generated netlist because the parser rejects signed Verilog port/wire declarations. A previous ASAP7 baseline workspace already contains a complete ORFS physical-design run through final routing.

See `FINAL_PROJECT_REPORT.md` for the full distinction between the current run and the earlier successful baseline.
