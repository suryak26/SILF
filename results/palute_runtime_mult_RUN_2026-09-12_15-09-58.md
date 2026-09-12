# PALUTE Baseline (Runtime-Multiplier) — ASIC Flow Results

**Run:** `RUN_2026-09-12_15-09-58` — v2 RTL, commit "runtime-signal multipliers"
**Flow conditions:** identical to v1 run (OpenLane 2.3.10 Classic, Sky130 `sky130_fd_sc_hd`,
20 ns clock, AREA 0 strategy, fixed 950 × 950 µm die, density 0.45)
**Sign-off:** Magic DRC 0 · KLayout DRC 0 · LVS 0 · GDS XOR 0 · setup/hold met

## Comparison with v1 (constant-magnitude) baseline

| Metric | v1 const-mult | v2 runtime-mult | Δ (v2 vs v1) |
|---|---:|---:|---:|
| Std cells (stage count, incl. taps) | 18,963 | 23,827 | +25.6 % |
| Sequential cells (flip-flops) | 741 | 1,156 | +56 % |
| Multi-input combinational cells | 2,899 | 6,167 | **+113 %** |
| **Instance area (µm²)** | **77,610.7** | **120,752** | **+55.6 %** |
| Utilization | 8.91 % | 13.87 % | +4.96 pt |
| Routed wirelength (µm) | 495,366 | 824,769 | +66.5 % |
| Setup slack @ 20 ns (worst corner, ns) | +9.954 | +9.527 | −0.427 ns |
| **Implied critical path (ns)** | **10.05** | **10.47** | +4.3 % |
| **Fmax (MHz)** | **≈ 99.5** | **≈ 95.5** | −4 % |
| Hold slack, worst (ns) | +0.117 | +0.112 | met |
| **Total power (mW, est.)** | **25.42** | **39.14** | **+54 %** |
| — internal (mW) | 9.70 | 15.13 | |
| — switching (mW) | 15.72 | 24.01 | |
| — leakage (µW) | 0.133 | 1.84 | |
| DRC / LVS / XOR | 0 / 0 / 0 | 0 / 0 / 0 | clean |

## Verification that the multiplier is genuine runtime hardware

- Weight is a **runtime signal**: `mag_cnt` counter register present in final
  netlist; per-lane magnitude registers (`mag_w1[0..7]`, `mag_w2[0..6]`) drive
  the multiplier operand ports.
- Lane sizes grew from 22–29 gates (constant-specialized) to **33–57 gates**
  (genuine 4-bit × 4-bit multiplier datapaths with partial products).
- Combinational cell growth (+3,268) = ~15 real multipliers (~220 cells)
  **plus** 112 adders that can no longer share constant-mult partial
  products across lanes (~29 cells/adder).
- `xor2` count grew ~3× (partial-product sum logic), `nand2` 356 → 887,
  `or2` 288 → 743, `a22o` 163 → 534.

## Interpretation for the review

1. **PALUTE as a multiplier architecture costs 55.6 % more area and 54 % more
   power** than the same structure when synthesis is allowed to optimize the
   weights as compile-time constants. This quantifies exactly what
   "PALUTE requires multiplier hardware" means at Sky130.
2. The v1 run (kept as a separate data point) shows the floor Yosys can reach
   when weights are constant — useful context, but **not** the paper's
   architecture claim.
3. The critical path is nearly unchanged (10.05 → 10.47 ns): the LUT register
   load dominates, not the multiplier — timing-neutral claim for SILG+.
4. Storage cost (LUT DFF array) is common to both designs; the differentiator
   is the combinational multiplier/adder logic, which SILG+ replaces with
   incremental-add/wavefront/gated logic.

## Still identical for both (comparison hygiene)

PDK, cell library, tool versions, clock (20 ns), strategy, die, density,
operating corners, power methodology (OpenSTA estimate, default activity).
Sim verification of v2: `sim_out/tb_lut_gen_unit.log` — all 1,120 LUT entries
correct over 10 cases; latency 12 cycles (u=1) / 10 (u=0).