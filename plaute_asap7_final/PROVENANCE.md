# Provenance and Scope

This package consolidates artifacts produced or supplied during the PALUTE/SILF ASIC work.

## Exact-design artifacts
- `rtl/lut_gen_unit.v`
- `tb/tb_lut_gen_unit.v`
- `constraints/lut_gen_unit_5ns.sdc`
- `synthesis/lut_gen_unit_syn.tcl`
- `netlist/genus/syn.v`
- `netlist/genus/syn.sdc`
- `reports/genus/*`

## Reference material
- `docs/SILGplus_Architecture_Proposal.docx`
- `docs/EXTERNAL_REFERENCE_NOTE.md`

## Earlier successful ORFS reference
The full earlier physical-design result exists in the WSL workspace:
`~/SILF_ASAP7/orfs/runs/results/asap7/palute_baseline_lut_gen/`

It is not copied into this lightweight package by default because ODB/GDS-style generated artifacts can become very large and are better managed separately or through Git LFS.

## Current ORFS blocker
The newer `lut_gen_unit` flow successfully reaches Yosys technology mapping but OpenROAD fails while parsing signed Verilog declarations in the generated `1_2_yosys.v`.

No RTL change was made to hide that tool-flow issue.
