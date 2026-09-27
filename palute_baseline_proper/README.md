# PALUTE LUT Generator Baseline BL-00

This folder records the frozen PALUTE LUT-generator OpenROAD/ASAP7 physical-design baseline used for future optimization and comparison.

## Final BL-00 PPA and timing

| Metric | Result |
|---|---:|
| Clock target | 200 MHz |
| Clock period | 5.000 ns |
| Post-route worst slack | 4.22 ns |
| WNS | 0.00 ns |
| TNS | 0.00 ns |
| Minimum clock period | 0.78 ns |
| Reported Fmax | 1283.71 MHz |
| Setup violations | 0 |
| Hold violations | 0 |
| Max slew violations | 0 |
| Max fanout violations | 0 |
| Max capacitance violations | 0 |
| Final design area | 1147 um^2 |
| Final utilization | 53% |
| Total reported power | 2.50 mW |
| Internal power | 1.39 mW |
| Switching power | 1.12 mW |
| Leakage power | 0.000809 mW |

## Architecture

- 4-bit INT4 / W4A4 context.
- Segment length b = 2, represented by u = 1 in this RTL.
- |w1| magnitudes 1 through 8.
- |w2| magnitudes 1 through 7.
- LUT depth 112 entries.
- LUT entry width 9 bits.
- Flat LUT output 1008 bits.
- Three-cycle LUT generation for the u = 1 path.
- FSM states: IDLE, GEN_W1, GEN_W2_POS, GEN_W2_NEG.

## Flow

RTL -> Yosys synthesis -> ASAP7 mapping -> floorplan -> placement -> CTS -> routing -> filler -> RC extraction -> post-route STA -> post-route power -> final GDS/ODB.

## Controlled implementation settings

- ASAP7 platform.
- RVT standard-cell variant.
- NLDM library model.
- TC corner.
- 0.70 V.
- 0 C.
- 50% core utilization.
- 0.60 placement density.
- 5.000 ns clock.

## Verification

The baseline RTL was simulated with Icarus Verilog using the preserved testbench. The representative vector x1=3, x2=-2, u=1 completed the three generation stages and produced all 112 LUT entries. This is simulation-based verification, not formal or exhaustive verification.

## Scope note

This folder records the LUT-generator block implementation. The PALUTE paper reports broader system/chip-level metrics, so those paper figures must not be treated as directly equivalent to BL-00 area or power. ASAP7 is used as a 7 nm-class academic technology proxy, not as a claim of identical reproduction of the paper's PDK and Cadence flow.

## Repository layout

- rtl/ : exact baseline RTL
- tb/ : preserved RTL testbench
- constraints/ : 5 ns SDC
- orfs/ : exact ORFS design configuration and controlled loader timing-unit change
- reports/ : captured synthesis and physical-design reports
- netlist/ : selected final netlist and constraints
- verification/ : simulation result and notes
- docs/ : baseline methodology, provenance, and recorded parameters

BL-00 is a frozen reference. Future optimization work should use a separate experiment folder or revision rather than editing this baseline.