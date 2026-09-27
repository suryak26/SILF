# PALUTE BL-00 Baseline Record

## Purpose

BL-00 is the frozen reference point for future PALUTE LUT-generator optimization and comparison work.

## Architecture

- Top module: `lut_gen_unit`
- Technology class: 7 nm, implemented with ASAP7
- Precision: INT4 / W4A4 context
- Segment length: b=2, represented as u=1
- P_X=4
- P_W=4
- P_Y=9
- W1_MAG_NUM=8
- W2_MAG_NUM=7
- LUT_DEPTH=112
- LUT output width=1008 bits
- LUT generation path: three generation cycles
- FSM: IDLE, GEN_W1, GEN_W2_POS, GEN_W2_NEG

## Physical implementation settings

- Platform: asap7
- VT: RVT
- Library model: NLDM
- Corner: TC
- Voltage: 0.70 V
- Temperature: 0 C
- Clock period: 5.000 ns
- Target frequency: 200 MHz
- Core utilization: 50%
- Core aspect ratio: 1
- Placement density: 0.60

## Final post-route results

| Metric | BL-00 |
|---|---:|
| Final design area | 1147 um^2 |
| Final utilization | 53% |
| WNS | 0.00 ns |
| TNS | 0.00 ns |
| Worst slack | 4.22 ns |
| Minimum clock period | 0.78 ns |
| Reported Fmax | 1283.71 MHz |
| Setup violations | 0 |
| Hold violations | 0 |
| Max slew violations | 0 |
| Max fanout violations | 0 |
| Max capacitance violations | 0 |
| Total power | 2.50 mW |
| Internal power | 1.39 mW |
| Switching power | 1.12 mW |
| Leakage power | 0.000809 mW |

## Power breakdown

| Group | Internal | Switching | Leakage | Total |
|---|---:|---:|---:|---:|
| Sequential | 0.463 mW | 0.145 mW | 0.000215 mW | 0.608 mW |
| Combinational | 0.769 mW | 0.871 mW | 0.000536 mW | 1.640 mW |
| Clock | 0.155 mW | 0.0996 mW | 0.000058 mW | 0.255 mW |
| Macro | 0 | 0 | 0 | 0 |
| Pad | 0 | 0 | 0 | 0 |
| **Total** | **1.390 mW** | **1.120 mW** | **0.000809 mW** | **2.50 mW** |

## Final artifacts

The completed WSL flow generated:

- 6_final.odb
- 6_final.sdc
- 6_final.def
- 6_final.gds
- 6_final.spef
- 6_final.v
- 6_final_lec.v
- 6_1_merged.gds
- 6_1_fill.odb

These large generated artifacts are documented here but are not duplicated in this lightweight source repository snapshot.

## Scope

BL-00 is a LUT-generator block implementation. It is not a reproduction of the PALUTE paper's complete system/chip PPA. Paper-level system metrics and BL-00 block metrics must remain separate in later comparisons.

ASAP7 is a 7 nm-class academic technology proxy. The implementation uses an open-source Yosys/OpenROAD flow rather than claiming an identical Cadence Genus/PDK environment.
