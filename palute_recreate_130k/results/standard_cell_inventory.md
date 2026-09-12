# Standard-Cell Components — PALUTE Baseline Netlist

**Source:** `runs/RUN_2026-09-12_10-24-58/final/nl/lut_gen_unit.nl.v`
**Library:** SkyWater Sky130 `sky130_fd_sc_hd` (high-density)
**Netlist stage:** final signed-off (post-route, post-fill)

The design uses **~160 cell variants**. Every cell belongs to one of the groups
below. Counts are exact instance counts from the final netlist.

## Group summary

| Group | Count | Role |
|---|---:|---|
| Sequential (flip-flops) | **741** | all storage: FSM, input regs, product regs, 1,008-bit LUT |
| Combinational logic | **≈2,903** | the multiplier & adder equations, control decode |
| Buffers / inverters / delay | **≈1,933** | fanout repair, hold fixing (462 delay gates) |
| Clock tree | **767** | CTS buffers + clock inverters |
| Antenna diodes | **264** | process-antenna protection |
| Constant tie cells | **28** | logic-1/0 tie (conb) |
| **Functional logic subtotal** | **≈6,640** | what the RTL actually required |
| Physical-only (tap/fill/decap) | **≈39,800** | inserted by P&R, no logic |

> Note on the "18,963 cells" metric: that stage count = functional cells +
> well taps. Fill/decap cells were added after that metric was recorded.
> For PALUTE-vs-SILG+ slides, quote **functional cell count (≈6,640)** and
> **instance area (77,610.7 µm²)** — physical cells are identical overhead
> for both designs (same fixed die).

## 1. Sequential — 741 total

| Cell | Count | Function |
|---|---:|---|
| `dfrtp_1` | 461 | D flip-flop, rising edge, async active-high reset, drive 1 |
| `dfrtp_4` | 160 | same, drive 4 |
| `dfrtp_2` | 77 | same, drive 2 |
| `dfxtp_1` | 25 | D flip-flop, rising edge, **no reset**, drive 1 |
| `dfxtp_4` | 15 | same, drive 4 |
| `dfxtp_2` | 3 | same, drive 2 |

The 1008-bit `lut_out_flat` output register array dominates this group.
Sky130 has no memory macro in this flow — the LUT is pure DFFs.

## 2. Combinational logic — ≈2,903 total

### AND-OR composite gates — 1,177
The workhorses of the adder bank. Naming: `a` = AND stage, `o` = OR stage,
trailing `i` = inverted output, digits = inputs per gate, `b` = inverted input.

| Cell | Equation | Count |
|---|---|---:|
| `a21o_1/2/4` | Y = (A1·A2) + B1 | 362 |
| `a32o_2` | Y = (A1·A2·A3) + (B1·B2) | 302 |
| `a22o_2/4` | Y = (A1·A2) + (B1·B2) | 168 |
| `a211o_1` | Y = (A1·A2) + B1 + C1 | 67 |
| `a31o_2/4` | Y = (A1·A2·A3) + B1 | 70 |
| `a2bb2o_1` | Y = (A1·Ā2) + (B1·B̄2) | 47 |
| `a21bo_2/4` | Y = (A1·A2) + B̄1 | 40 |
| `a21oi_1/2/4` | Y = ¬((A1·A2) + B1) | 79 |
| others (`a2111o`, `a22oi`, `a31oi`, `a221o/oi`, `a21boi`, `a311o`, `a32oi`, `a211oi`) | | 42 |

### OR-AND composite gates — 274

| Cell | Equation | Count |
|---|---|---:|
| `o21a_1/2/4` | Y = (A1+A2) · B1 | 77 |
| `o21ai_1/2/4` | Y = ¬((A1+A2) · B1) | 62 |
| `o211ai_1/2/4` | Y = ¬((A1+A2) · B1 · C1) | 23 |
| `o211a_1` | Y = (A1+A2) · B1 · C1 | 40 |
| `o22a_1` | Y = (A1+A2) · (B1+B2) | 28 |
| others (`o21ba/bai`, `o31a/ai`, `o311a`, `o2bb2a/ai`, `o221a/ai`, `o2111a/ai`) | | 44 |

### Basic gates — 1,389

| Family | Cells | Count |
|---|---|---:|
| NAND/NOR | `nand2` (405), `nand3` (77), `nand2b` (29), `nor2` (153), `nor3` (2), `nand3b/nand4/nand4b` (8) | 674 |
| AND/OR | `or2` (298), `and3` (91), `and2` (96), `or3` (52), `and2b` (16), `and3b` (13), `or4/or3b/or4b/or4bb` (13) | 578 |
| XOR/XNOR | `xnor2` (99), `xor2` (38) | 137 |

### Other — 63
`mux2_1` (35), `conb_1` constant tie (28).

## 3. Buffers, inverters, delay — ≈1,933

| Cell | Count | Function |
|---|---:|---|
| `buf_1/2/4/6/8/12` | 1,302 | data-path buffers (fanout/wire-delay repair) |
| `inv_2/4/6/8/12/16` | 153 | inverters |
| `dlygate4sd3_1` | 462 | dedicated delay cell — **hold-violation repair** |
| `dlymetal6s2s_1` | 11 | metal delay cell |
| `bufinv_16` | 16 | combined buffer-inverter |

## 4. Clock tree — 767

| Cell | Count | Function |
|---|---:|---|
| `clkbuf_1` | 264 | clock buffers (CTS) |
| `clkbuf_2/4/8/16` | 60/153/201/39 | clock buffers, higher drives |
| `clkinv_4/clkinv_2` | 34 | clock inverters |
| `clkinvlp_4` | 16 | low-power clock inverter |

## 5. Physical & reliability cells — ≈40,060

| Cell | Count | Function |
|---|---:|---|
| `tapvpwrvgnd_1` | 12,348 | well tap (latch-up rule, one per row segment) |
| `fill_1` / `fill_2` | 11,953 / 961 | fill (density) |
| `decap_3/4/6/8` | 1,727/812/10,818/1,177 | decoupling capacitance |
| `diode_2` | 264 | antenna-check protection diodes |

## Key facts for the review

1. **No arithmetic cells exist in the library.** `sky130_fd_sc_hd` has no
   multiplier cell, no full-adder cell, no memory macro. All arithmetic is
   composed from composite AND-OR/OR-AND and XOR gates by Yosys/ABC.
2. **The v1 netlist contains no multiplier hardware.** Because the RTL weight
   was a parameter constant, Yosys turned each of the 15 multiplier lanes into
   ~22–29 gates of constant shift-add logic (verified: 0 full-adder cells;
   `GEN_MEGA_MULT_W1[0]` = 22 gates, `GEN_MEGA_MULT_W2[0]` = 29 gates).
3. **Storage dominates the design** (741 FFs; the LUT array is 1,008 bits of
   DFFs) — both designs pay this cost, so the comparison will hinge on the
   combinational multiplier/adder logic.
4. The runtime-multiplier baseline (v2, committed, sim-verified) is now flowing
   through the identical process; its cell counts will differ mainly in the
   combinational group.