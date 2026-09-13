# PALUTE Baseline Reimplementation - ASAP7

This directory contains the PALUTE-style LUT-generator baseline
reimplementation and its ASIC synthesis/physical-design results using
the ASAP7 standard-cell library and OpenROAD-flow-scripts.

## Design

The baseline implements LUT generation for:

- P_X = 4-bit signed input data
- P_W = 4-bit unsigned weight magnitudes
- P_Y = 9-bit signed LUT output
- LUT depth = 112 entries
- 8 runtime |w1| × x1 products
- 7 runtime |w2| × x2 products
- Positive and negative w2 LUT generation
- Three-cycle control sequence

The weight magnitudes are runtime input signals rather than
compile-time constants. This prevents the synthesis flow from
trivially replacing the multiplication operations with constant
shift/add logic and provides a more meaningful baseline for comparison
with the proposed SILG+ architecture.

## Verification

RTL simulation was performed using the supplied testbench.

The testbench verifies the LUT-generation sequence and the generated
LUT values for the configured input/weight combinations.

## ASIC Flow

Technology:
ASAP7

Flow:
OpenROAD-flow-scripts

Clock constraint:
10.0 ns

Target clock:
clk

Core utilization:
65%

Placement density:
35%

The implementation flow includes:

1. RTL synthesis
2. Floorplanning
3. Placement
4. Clock-tree synthesis
5. Global/detailed routing
6. Filler insertion
7. Final timing, power and physical checks

## Final ASIC Results

The following values are taken from the final OpenROAD finish report.

| Metric | Result |
|---|---:|
| Standard-cell area | 1604.49 um^2 |
| Core area | 2011.25 um^2 |
| Die area | 2109.56 um^2 |
| Utilization | 79.7754% |
| Total power | 1.20489 W |
| Internal power | 0.767766 W |
| Switching power | 0.437122 W |
| Leakage power | 1.00578 uW |
| Derived Fmax | 2.82657 GHz |
| Critical path delay | 416.044 ps |
| Setup WNS | -343.785 ps |
| Setup TNS | -434758 ps |
| Hold WNS | -65.5362 ps |
| Hold TNS | -1611.06 ps |
| Setup violations | 2149 |
| Hold violations | 79 |
| Max slew violations | 0 |
| Max capacitance violations | 0 |
| Max fanout violations | 0 |
| DRC violations | 0 |
| Antenna violations | 0 |
| LEC | PASS |
| Macros | 0 |

## Cell Information

The final physical implementation contains 22,559 total physical
instances. This count includes filler, tap, tie, clock, timing-repair,
sequential and combinational cells and therefore should not be treated
as a pure logic-gate count.

Final standard-cell instance count reported by OpenROAD:

13,045

Functional cell categories include:

- Sequential cells: 1,140
- Multi-input combinational cells: 5,946
- Inverters: 425
- Clock buffers: 80
- Clock inverters: 25
- Timing-repair buffers: 3,871
- Timing-repair inverters: 2
- Tie cells: 1,140
- Tap cells: 416
- Fill cells: 9,514

## Important Timing Note

The derived Fmax is reported by the OpenROAD flow from the minimum
clock period. The final design still has significant setup and hold
timing violations. Therefore, Fmax must not be presented alone as
evidence of timing closure.

For comparison with SILG+, the same timing, technology, synthesis,
placement, routing and reporting methodology should be applied to both
designs.

## Stored Results

### Synthesis

`results/synthesis/`

Contains:

- synthesized gate-level Verilog
- synthesis SDC
- synthesis report
- synthesis JSON metrics

### Final Physical Implementation

`results/final/`

Contains:

- final routed Verilog netlist
- final DEF
- final SDC
- final timing/power report
- final JSON metrics
- final flow report
- routing DRC report

Large intermediate OpenROAD databases and generated GDS files are not
stored in this Git checkpoint.
