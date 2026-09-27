# BL-00 Artifact Register

## Final physical-design artifacts generated in WSL

```
6_final.odb
6_final.sdc
6_final.def
6_final.gds
6_final.spef
6_final.v
6_final_lec.v
6_1_merged.gds
6_1_fill.odb
```

## ORFS report set

```
1_synth.rpt
2_floorplan_final.rpt
3_global_place.rpt
3_detailed_place.rpt
3_resizer.rpt
4_cts_final.rpt
5_global_route.rpt
5_route_drc.rpt
6_finish.rpt
```

## Final physical checks

- Detailed routing completed with zero final DRC violations.
- Antenna violations: 0.
- Setup violations: 0.
- Hold violations: 0.
- Slew violations: 0.
- Fanout violations: 0.
- Capacitance violations: 0.
- Final GDS was generated.
- KLayout reported matching LEF/GDS cells and no orphan cells.
- A DEF database-unit mismatch warning was emitted during streamout. The GDS was nevertheless generated successfully. This warning is recorded rather than silently ignored.

## IR/power-grid report

The final finish stage also reported approximately 2.50e-03 W in the power-grid/IR analysis at 0.70 V. This value is not used as a substitute for the detailed `report_power` result. The detailed post-route power report independently reports 2.50e-03 W total design power.
