# PALUTE Baseline vs ASPLUT Proposed Netlist / Physical-Design Report

**Project:** PALUTE-inspired LUT Generator ASIC study  
**Technology:** ASAP7, 7 nm predictive standard-cell library  
**Comparison:** PALUTE baseline vs ASPLUT proposed shared-MAC serial/parallel LUT generator  
**Report date:** 30 September 2026

## 1. Scope and important result boundary

The current project material identifies the measured proposed architecture as **ASPLUT**, a shared-MAC serial/parallel LUT generator. The Phase-I material reports matched synthesis-stage comparisons and explicitly states that matched post-route ASPLUT PPA was **not yet claimed**. Therefore this report does **not** invent a proposed die area or post-route result.

The attached local Genus reports are also not mixed into the matched table below because they use a different synthesis run/constraint setup. They are retained as provenance only.

## 2. Architecture being compared

### PALUTE baseline
- 112 LUT entries
- 9-bit LUT entry width
- 1008-bit flattened output
- Three-cycle generation concept
- Replicated arithmetic resources are used to achieve short LUT-generation latency

### ASPLUT proposed
- Same 112-entry LUT function
- Same 9-bit entry width
- Same 1008-bit external LUT output
- Shared-MAC serial/parallel enumeration
- 113 clock periods including DONE in the reported implementation
- Current RTL still contains arithmetic multiply operators, so the synthesized result must be described as **ASPLUT shared-MAC**, not as the later SILG+ multiplier-free architecture.

## 3. Matched synthesis-stage netlist metrics

| Metric | PALUTE baseline | ASPLUT proposed | Change |
|---|---:|---:|---:|
| I/O count | 1081 | 1021 | -5.55% |
| Nets | 8151 | 4456 | -45.33% |
| Instances | 8079 | 4436 | -45.09% |
| Standard-cell area (µm²) | 1312.170 | 677.081 | -48.40% |
| Total synthesis power (W) | 1.113360 | 0.0010496 | -99.91% |
| Minimum period (ns) | 0.38060 | 0.39375 | 3.46% |
| Fmax (GHz) | 2.62746 | 2.53966 | -3.34% |

**Source of the matched proposed synthesis data:** committed `ASP_LUT/results/synthesis/1_synth.json`.  
**Source of the matched baseline synthesis data:** committed `palute_recreate_asap7/results/synthesis/1_synth.json`.

### Interpretation
The synthesis data shows the structural cost of moving from a heavily replicated three-cycle generator to a shared-MAC enumeration architecture. Area, instance count and net count are directly measurable synthesis outputs. Generation latency is the architectural trade-off and must be reported alongside those PPA figures rather than hidden.

## 4. Actual completed physical-design result currently available

The repository contains a completed ASAP7 OpenROAD physical-design run for the **PALUTE baseline**. These values are from the final physical report, not an AI estimate:

| Physical metric | PALUTE baseline final |
|---|---:|
| Standard-cell area | 1604.49 µm² |
| Core area | 2011.25 µm² |
| **Die area** | **2109.56 µm²** |
| Utilization | 79.7754% |
| Final nets | 12657 |
| Final I/O | 1083 |
| Final instances | 22559 |
| Total post-route power | 1.20489 W |
| Fmax reported by final JSON | 2.82657 GHz |
| Setup violations | 2149 |
| Hold violations | 79 |
| Slew violations | 0 |
| Fanout violations | 0 |
| Capacitance violations | 0 |

**Critical qualification:** the final JSON currently committed for this baseline contains setup/hold violations. Therefore the physical result is an actual routed result, but it should not be presented as sign-off-clean timing.

The repository artifact register separately records the generated final ODB/DEF/GDS/SPEF/netlist artifacts and reports zero final DRC, antenna, slew, fanout and capacitance violations in that run.

## 5. Proposed physical-design status

**ASPLUT proposed die area: NOT YET MEASURED.**

The current committed ASPLUT results contain synthesis JSON/report data, but no completed post-route `6_report.json` equivalent for ASPLUT. Consequently:

- Proposed die area: **pending physical implementation**
- Proposed core area: **pending physical implementation**
- Proposed post-route nets: **pending**
- Proposed final instance count: **pending**
- Proposed post-route power: **pending**
- Proposed post-route timing: **pending**
- Proposed DRC/antenna/IR results: **pending**

This is intentional. A synthesis area number such as 677.081 µm² is **not** a die area and must not be relabeled as one.

## 6. Dot Viewer / critical-path reports

The two supplied PNGs in this report were generated from the actual timing-path data using Graphviz, in the same general visual style as the requested Yosys Dot Viewer image.

### PALUTE baseline
The graph follows the reported path from `state_reg[0]/QN` through the mapped ASAP7 cells to `lut_out_flat_reg[966]/D`.

### ASPLUT proposed
The graph follows the reported maximum-delay path from `x2[1]` through the mapped logic to register `u287`.

Files:
- `palute_baseline_critical_path.dot`
- `palute_baseline_critical_path.png`
- `asplut_proposed_critical_path.dot`
- `asplut_proposed_critical_path.png`

## 7. Exact physical-design flow needed for ASPLUT

The existing ASPLUT ORFS configuration already defines:
- ASAP7 platform
- `asplut_gen_unit` top
- 65% core utilization
- 1:1 aspect ratio
- 0.5 core margin
- 0.35 placement density
- 5 ns reference clock constraint

The next physical-design run should execute the same complete flow used for the baseline:

1. synthesis
2. floorplan
3. placement
4. placement optimization/resizing
5. CTS
6. global routing
7. detailed routing / DRC
8. final extraction/reporting
9. final `6_report.json`
10. final DEF/GDS/ODB/SPEF

The proposed result must then be compared against the **same physical-design methodology**, not against the baseline's synthesis-only area.

## 8. Required final comparison table after ASPLUT physical implementation

| Metric | PALUTE baseline synthesis | ASPLUT synthesis | PALUTE final physical | ASPLUT final physical |
|---|---:|---:|---:|---:|
| I/O | 1081 | 1021 | 1083 | PENDING |
| Nets | 8151 | 4456 | 12657 | PENDING |
| Instances | 8079 | 4436 | 22559 | PENDING |
| Std-cell area (µm²) | 1312.170 | 677.081 | 1604.490 | PENDING |
| Core area (µm²) | — | — | 2011.250 | PENDING |
| **Die area (µm²)** | — | — | **2109.560** | **PENDING** |
| Utilization | — | — | 79.7754% | PENDING |
| Power (W) | 1.113360 | 0.0010496 | 1.204890 | PENDING |
| Fmax (GHz) | 2.62746 | 2.53966 | 2.82657 | PENDING |

## 9. Provenance

All numerical values in this report are tied to project artifacts:
- PALUTE paper: architectural baseline and the 112-entry/9-bit LUT-generator context.
- ASPLUT Phase-I presentation: matched baseline/proposed synthesis comparison and Phase-I/Phase-II boundary.
- `ASP_LUT/results/synthesis/1_synth.json`: ASPLUT synthesis metrics.
- `palute_recreate_asap7/results/synthesis/1_synth.json`: PALUTE synthesis metrics.
- `palute_recreate_asap7/results/final/6_report.json`: PALUTE final physical-design metrics.
- `palute_baseline_proper/docs/ARTIFACTS.md`: baseline physical-design artifact and verification register.

## 10. Bottom line

The report is ready for the **measured Phase-I synthesis comparison** and contains an actual final physical-design record for the PALUTE baseline.

The only missing quantity for the requested full physical comparison is the **ASPLUT post-route result**. It must be generated by actually running the physical-design flow. No proposed die area is fabricated in this report.
