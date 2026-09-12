# PALUTE Baseline — ASIC Flow Results

**Run:** `RUN_2026-09-12_10-24-58` (executed 15:55–16:01, 2026-09-12; directory created 10:24:58)
**Netlist corresponds to current `src/` (last src edit 11:07 < synthesis 15:55 — verified)**

## Flow conditions (must be identical for SILG+)

| Condition | Value |
|---|---|
| Flow | OpenLane 2.3.10 (Classic), Docker image `ghcr.io/efabless/openlane2:2.3.10` |
| PDK / cells | Sky130 / `sky130_fd_sc_hd` |
| Design | `lut_gen_unit` (P_X=4, P_W=4, LUT 112 entries × 9 bits) |
| Clock constraint | 20.0 ns (50 MHz), port `clk` |
| Synthesis strategy | `AREA 0` |
| Floorplan | Fixed die 950 × 950 µm (core 938.86 × 927.52) |
| Placement density | 0.45 |
| Power corner reported | `nom_tt_025C_1v80` (worst timing corner: `max_ss_100C_1v60`) |

## Area

| Metric | Value |
|---|---|
| Standard cells (excl. fill/tap) | 18,963 |
| — Sequential | 741 |
| — Multi-input combinational | 2,899 |
| — Buffers / inverters | 294 / 121 |
| (Fill cells added later) | 72,225 |
| (Tap cells) | 12,348 |
| **Cell instance area** | **77,610.7 µm²** |
| Die area | 902,500 µm² (fixed 950 × 950) |
| Core area | 870,811 µm² |
| Utilization | 8.91 % |
| IO count | 1,023 |

## Timing (post-route STA, all corners met)

| Metric | Value |
|---|---|
| Clock period (constraint) | 20.0 ns |
| Setup WNS (worst corner `max_ss_100C_1v60`) | **+9.954 ns slack** (0 violations) |
| Setup WS (`nom_tt_025C_1v80`) | +12.705 ns |
| Hold WNS (worst, min corner) | **+0.117 ns slack** (0 violations) |
| TNS (setup & hold) | 0 |
| **Implied critical path (worst corner)** | **≈ 10.05 ns → Fmax ≈ 99.5 MHz** |
| Clock skew (worst setup) | 0.389 ns |

## Power (post-layout, RCX-annotated, `nom_tt_025C_1v80`)

| Component | Value |
|---|---|
| Internal | 9.70 mW |
| Switching | 15.72 mW |
| Leakage | 0.133 µW |
| **Total** | **25.42 mW** |

> ⚠️ OpenSTA estimate with **default activity factors** (no SAIF/VCD back-annotation).
> Both designs must be measured the same way; label it "estimated power, default activity" in the review.

## Physical / sign-off

| Check | Result |
|---|---|
| Routed wirelength | 495,366 µm |
| Vias | 43,742 (all single-cut) |
| IR drop (worst) | 0.94 mV |
| Magic DRC | **0 errors** |
| KLayout DRC | **0 errors** |
| LVS (netgen) | **0 mismatches** |
| GDS XOR (vs layout) | **0 differences** |
| Antenna violations | 54 nets (diodes inserted; non-blocking) |
| Max slew violations (worst corner) | 156 |
| Max cap violations | 38 |
| Max fanout violations | 65 |

## ⚠️ Critical caveat — the baseline contains NO multiplier hardware

`mega_multiplier` computes `product = value * MAGNITUDE` where **`MAGNITUDE` is a Verilog
parameter (compile-time constant 1–8)**, not a runtime signal.

Yosys therefore ran each `$mul` through `alumacc` and **specialized it into constant
shift-add gate logic**. Verification evidence:

- Synthesis log: every `$mul` → `$macc` model → optimized to generic gates
- Final netlist: **0** full-adder/half-adder cells; each "multiplier" lane became ~20–30
  AOI/XOR gates (e.g. `GEN_MEGA_MULT_W1[0]` = 22 cells)
- Total design after synthesis: only 5,196 cells pre-techmap — tiny, because the constant
  multiplies were optimized away

This contradicts the agreed baseline definition (`product = input * weight` with weight
as a **runtime signal**) and weakens the headline claim "PALUTE requires multiplier
hardware": after synthesis, this PALUTE has no multiplier either.

**Decision needed before the SILG+ comparison run** (see chat): keep this baseline and
reframe the claim, or rewrite `mega_multiplier` with runtime-signal weights and re-run.