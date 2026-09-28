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

## Post-route parasitic extraction

OpenROAD RCX was run during the final reporting stage using the ASAP7 extraction model. The recorded extraction log reports:

- 64,280 final RC segments
- 66,390 routed wires extracted
- 8,429 nets extracted
- 72,708 resistance segments
- 72,708 capacitance entries
- 93,380 coupling-capacitance entries
- 8,429 nets finished

The final SPEF is:

`flow/results/asap7/palute_lut_gen/base/6_final.spef`

It is an IEEE 1481-1999 SPEF with:

- Time unit: ns
- Capacitance unit: pF
- Resistance unit: ohm
- `*D_NET`, `*CONN`, `*CAP`, and `*RES` sections

The SPEF is a post-route extraction output. It was not a synthesis input. The available run logs prove RC extraction and SPEF generation; they do not establish a separate later `read_spef` invocation.

## Power-integrity verification

A final IR-drop visualization was generated at:

`flow/reports/asap7/palute_lut_gen/base/final_ir_drop.webp`

The recorded power-grid analysis reported:

- Supply: 0.70 V
- Worst VDD voltage: 0.699 V
- Average VDD voltage: 0.700 V
- Average VDD IR drop: 0.235 mV
- Worst VDD IR drop: 0.784 mV
- Worst VDD relative drop: approximately 0.11%
- VSS average IR drop: approximately 0.234 mV
- VSS relative drop: approximately 0.09%

These IR results are power-grid analysis results and should not be confused with the cell-level total-power breakdown above.

Electromigration analysis is **not claimed as completed** because no EM/current-density result was identified in the available run artifacts.

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
- final_ir_drop.webp

These large generated artifacts are documented here. The lightweight GitHub baseline snapshot records source, reports, constraints, and verification metadata rather than duplicating the complete generated database set.

## Scope

BL-00 is a LUT-generator block implementation. It is not a reproduction of the PALUTE paper's complete system/chip PPA. Paper-level system metrics and BL-00 block metrics must remain separate in later comparisons.

ASAP7 is a 7 nm-class academic technology proxy. The implementation uses an open-source Yosys/OpenROAD flow rather than claiming an identical Cadence Genus/PDK environment.
