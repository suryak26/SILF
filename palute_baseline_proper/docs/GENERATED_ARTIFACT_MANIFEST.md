# BL-00 Generated Physical-Analysis Artifact Manifest

Generated in the WSL ORFS run:

- `flow/results/asap7/palute_lut_gen/base/6_final.spef`
  - IEEE 1481-1999 SPEF
  - Post-route RC extraction output
  - Contains net connectivity, resistance, capacitance, and coupling capacitance
- `flow/reports/asap7/palute_lut_gen/base/final_ir_drop.webp`
  - Final IR-drop visualization
- `flow/results/asap7/palute_lut_gen/base/6_final.odb`
  - Final OpenROAD database
- `flow/results/asap7/palute_lut_gen/base/6_final.def`
  - Final DEF
- `flow/results/asap7/palute_lut_gen/base/6_final.gds`
  - Final streamed GDS
- `flow/results/asap7/palute_lut_gen/base/6_final.v`
  - Final routed netlist

## Decision

The GitHub BL-00 snapshot intentionally keeps these generated binary/database artifacts out of the lightweight source archive while preserving their names, paths, and verified contents in the documentation. This avoids treating generated databases as source-of-truth RTL while keeping the WSL run reproducible and auditable.
