# PALUTE / SILF 7nm ASIC Work Package
## Final-Year Project Engineering Checkpoint Report

**Repository target:** `suryak26/SILF`  
**Target folder:** `palute_7nm_final/`  
**Technology focus:** ASAP7 / 7nm-class academic standard-cell flow  
**Top-level RTL:** `lut_gen_unit`

---

## 1. Executive Summary

This package records the PALUTE LUT-generator ASIC work completed during the current project phase. It is intentionally a **checkpoint report**, not a claim that every planned ASIC stage was completed for the current RTL.

The work progressed through four major layers:

1. **RTL implementation and functional verification**
2. **Cadence Genus ASAP7 synthesis and PPA estimation**
3. **OpenROAD-flow-scripts (ORFS) environment construction in WSL2/Docker**
4. **A fresh ORFS synthesis attempt, including diagnosis of the point where the flow stopped**

A separate earlier workspace, `~/SILF_ASAP7`, already contains a **successful ASAP7 ORFS baseline physical-design run through final routing** for `palute_baseline_lut_gen`. That prior run is preserved as an important reference, but it is not silently represented as a physical-design result for the newer `lut_gen_unit` RTL.

### Current headline results

| Item | Result | Status |
|---|---:|---|
| RTL top module | `lut_gen_unit` | Complete |
| LUT entries | 112 | Complete |
| LUT output width | 1008 bits | Complete |
| RTL verification | Icarus-based testbench | Complete |
| Genus mapped cell count | 4095 | Complete |
| Genus cell area | 620.204 | Complete |
| Genus critical path | 666 ps | Complete |
| Genus slack at 2 ns | 1334 ps | Complete |
| Inferred zero-slack frequency from 666 ps | ~1.50 GHz | Derived |
| Genus reported total power | 1.28015 mW | Complete |
| ORFS/Docker environment | Built successfully | Complete |
| Current ORFS Yosys synthesis | Successful | Complete |
| Current ORFS OpenROAD handoff | Stops at Verilog parser | Blocked |
| Current RTL ORFS floorplan | Not generated | Not complete |
| Current RTL ORFS placement | Not generated | Not complete |
| Current RTL ORFS CTS | Not generated | Not complete |
| Current RTL ORFS routing | Not generated | Not complete |
| Current RTL ORFS GDS | Not generated | Not complete |
| Earlier ASAP7 baseline ORFS run | Reached final routed database | Reference result |

The key engineering lesson is that the current blocker is **not an RTL/Yosys synthesis failure**. The RTL was accepted by Yosys, technology mapping completed, and a mapped Verilog netlist was produced. The failure occurred when the OpenROAD stage attempted to parse signed Verilog declarations in that generated netlist.

---

# 2. Design Under Test

## 2.1 Top-level module

```text
lut_gen_unit
```

## 2.2 Parameterization

| Parameter | Value |
|---|---:|
| `P_X` | 4 |
| `P_W` | 4 |
| `P_Y` | 9 |
| `W1_MAG_NUM` | 8 |
| `W2_MAG_NUM` | 7 |
| `LUT_DEPTH` | 112 |

The LUT depth is:

```text
8 × 7 × 2 = 112 entries
```

Each LUT entry is 9 bits:

```text
112 × 9 = 1008 bits
```

Therefore `lut_out_flat` is:

```text
[1007:0]
```

## 2.3 Interface

```text
clk
rst_n
start
u
x1[3:0]   signed
x2[3:0]   signed
done
lut_out_flat[1007:0]   signed
```

---

# 3. RTL Architecture

The controller uses four states:

```text
IDLE
GEN_W1
GEN_W2_POS
GEN_W2_NEG
```

## 3.1 IDLE

On `start`, the unit captures:

- `u`
- `x1`
- `x2`

The LUT output is cleared before generation starts.

## 3.2 GEN_W1

The unit generates the first set of products:

```text
x1 × 1
x1 × 2
...
x1 × 8
```

These are stored in `prod_w1`.

If `u = 0`, the implementation writes only the first LUT entry and returns to `IDLE`.

If `u = 1`, generation continues to the second operand stages.

## 3.3 GEN_W2_POS

The second operand products are generated:

```text
x2 × 1
x2 × 2
...
x2 × 7
```

These are stored in `prod_w2_pos`.

## 3.4 GEN_W2_NEG

The final state produces:

- 56 positive combinations
- 56 negative combinations

for a total of:

```text
56 + 56 = 112 LUT entries
```

The positive and negative index functions are:

```text
idx_positive(i,j) =
    i × (2 × W2_MAG_NUM) + j

idx_negative(i,j) =
    i × (2 × W2_MAG_NUM) + W2_MAG_NUM + j
```

The negative-side LUT values are formed by sign inversion of the positive `x2` products.

### Important implementation observation

The RTL contains a `prod_w2_neg` register array, but the LUT assignments directly call `sign_invert(prod_w2_pos[j])`. Consequently, the stored negative array is not required for the final LUT calculation and may be optimized away by synthesis.

---

# 4. RTL Verification

## 4.1 Testbench

The preserved testbench is:

```text
tb/tb_lut_gen_unit.v
```

The verification sequence includes:

1. reset assertion
2. reset release
3. input application
4. `start` assertion
5. observation of generation stages
6. intermediate product inspection
7. final LUT inspection
8. `done` observation
9. waveform generation

The testbench uses representative signed values including:

```text
x1 = 3
x2 = -2
```

and provides visibility into:

```text
prod_w1
prod_w2_pos
prod_w2_neg
```

rather than treating the generator as a black box.

## 4.2 Preserved simulation artifact

```text
verification/lut_gen_unit.vvp
```

This is the compiled Icarus VVP simulation artifact.

A standalone VCD file is not included in this checkpoint package. Therefore this report does not claim to preserve a VCD file that is not actually present.

---

# 5. Cadence Genus ASAP7 Synthesis

A complete Genus synthesis run was previously performed for the LUT generator.

## 5.1 Tool

```text
Cadence Genus Synthesis Solution
21.17-s066_1
```

## 5.2 Technology

The synthesis uses ASAP7 7.5-track standard-cell timing libraries, including:

```text
asap7sc7p5t_AO_*
asap7sc7p5t_OA_*
asap7sc7p5t_SEQ_*
asap7sc7p5t_SIMPLE_*
asap7sc7p5t_INVBUF_*
```

The reported operating condition is:

```text
PVT_0P7V_25C
```

## 5.3 Synthesis flow

The preserved Genus script performs:

- library setup
- RTL read
- elaboration
- design checks
- clock definition
- input/output timing constraints
- asynchronous reset false-path constraint
- generic synthesis
- technology mapping
- optimization
- timing analysis
- area analysis
- power analysis
- gate-level Verilog export
- SDC export

Script:

```text
synthesis/lut_gen_unit_syn.tcl
```

---

# 6. Genus Area Result

Source:

```text
reports/genus/area.rpt
```

Measured result:

| Metric | Value |
|---|---:|
| Module | `lut_gen_unit` |
| Cell count | 4095 |
| Cell area | 620.204 |
| Net area | 0.000 |
| Total area | 620.204 |

The value is reported in the units used by the ASAP7 timing/library environment. It should not be converted to physical µm² unless the corresponding library area-unit definition is explicitly established.

---

# 7. Genus Timing Result

Source:

```text
reports/genus/timing.rpt
```

The stored Genus synthesis constraints use:

```text
create_clock -period 2000 ps
```

which corresponds to:

```text
2 ns clock period
500 MHz target clock frequency
```

The reported critical path is:

```text
state_reg[0]/CLK
        ->
lut_out_flat_reg[966]/D
```

Reported path delay:

```text
666 ps
```

Reported slack:

```text
1334 ps
```

The timing relationship is:

```text
2000 ps - 666 ps = 1334 ps
```

## 7.1 Derived frequency

Using the measured critical-path delay as a simple zero-slack estimate:

```text
f ≈ 1 / 0.666 ns
  ≈ 1.50 GHz
```

This is a **derived theoretical frequency estimate**, not a separate signoff result.

The 500 MHz value is the applied target clock, while ~1.50 GHz is the reciprocal of the reported critical-path delay. They must not be presented as equivalent measurements.

---

# 8. Genus Power Result

Source:

```text
reports/genus/power.rpt
```

Reported total power:

```text
1.28015 mW
```

Breakdown:

| Category | Power |
|---|---:|
| Registers | 0.967507 mW |
| Logic | 0.312640 mW |
| Total | 1.28015 mW |

Approximate contribution:

```text
Registers ≈ 75.58%
Logic     ≈ 24.42%
```

This is a synthesis/power-analysis estimate dependent on the activity assumptions used by the report. It is not measured silicon power.

---

# 9. Gate-Level Netlist

The preserved Genus gate-level netlist is:

```text
netlist/genus/syn.v
```

and the associated generated constraints are:

```text
netlist/genus/syn.sdc
```

The top-level design remains:

```text
lut_gen_unit
```

The mapped netlist contains ASAP7 standard-cell instances implementing the controller, arithmetic, registers and 1008-bit output storage.

---

# 10. ORFS / OpenROAD Environment

A second, open-source ASIC flow was established using OpenROAD-flow-scripts.

## 10.1 Host environment

The new environment was moved to WSL2 because the original native Ubuntu root partition had reached capacity during tool installation/build activity.

WSL configuration used:

```text
Ubuntu 26.04.1 LTS
WSL2
8 processors allocated to WSL
10 GB WSL memory
8 GB WSL swap
~955 GB free WSL filesystem space
```

## 10.2 Docker

Docker CE and Buildx were installed and verified.

The OpenROAD-flow-scripts build was performed inside Docker rather than relying on the host Ubuntu 26.04 toolchain.

## 10.3 OpenROAD-flow-scripts

The ORFS source was cloned recursively.

The Docker builder image was successfully constructed:

```text
openroad/flow-ubuntu22.04-builder:9ed603
```

The resulting image was approximately 6.58 GB.

The completed build produced:

```text
OpenROAD 26Q3-2056-g41a28926b9
Yosys 0.68+post
KLayout 0.30.12
```

The build took approximately 4011 seconds.

The long build generated compiler warnings, including LTO/ODR warnings in ABC and parser components, but the build completed successfully.

---

# 11. Current ORFS Synthesis Attempt

A fresh ORFS design configuration was created for:

```text
DESIGN_NAME = lut_gen_unit
PLATFORM = asap7
```

The design uses:

```text
rtl/lut_gen_unit.v
constraints/lut_gen_unit_5ns.sdc
```

The ORFS target was initially configured for:

```text
5 ns clock
200 MHz
```

with the following general floorplanning settings:

```text
CORE_UTILIZATION = 50
CORE_ASPECT_RATIO = 1
CORE_MARGIN = 2.0
PLACE_DENSITY = 0.50
SYNTH_USE_SDC = 1
```

## 11.1 Yosys result

Yosys successfully:

- parsed the RTL
- executed process lowering
- handled memories
- performed FSM processing
- mapped arithmetic/control logic
- performed technology mapping
- generated a mapped Verilog netlist

The synthesis completed in approximately:

```text
8.57 seconds
```

with peak memory around:

```text
167.5 MB
```

Therefore the current failure is not a Yosys synthesis failure.

---

# 12. Current ORFS Blocker

The ORFS flow stops during the OpenROAD `synth_odb` stage while reading:

```text
1_2_yosys.v
```

The error is reported as:

```text
[ERROR STA-0171] .../1_2_yosys.v line 21, syntax error
```

The generated netlist contains declarations such as:

```verilog
input signed [3:0] x1;
wire signed [3:0] x1;

input signed [3:0] x2;
wire signed [3:0] x2;

output signed [1007:0] lut_out_flat;
wire signed [1007:0] lut_out_flat;
```

A minimal standalone test confirmed that the OpenROAD parser in this build rejects the corresponding signed declaration syntax.

An unsigned equivalent:

```verilog
input [3:0] x1;
wire [3:0] x1;

output [1007:0] lut_out_flat;
wire [1007:0] lut_out_flat;
```

was accepted by the same parser.

### Engineering conclusion

The observed failure is localized to the **OpenROAD Verilog parser handoff**, not the RTL parser or Yosys synthesis engine.

The original RTL was therefore left unchanged.

This is preferable to modifying the RTL solely to accommodate a downstream parser quirk without first establishing the exact semantic impact.

---

# 13. Earlier Successful ASAP7 ORFS Baseline

An earlier workspace exists at:

```text
~/SILF_ASAP7
```

It contains a complete ORFS run for:

```text
palute_baseline_lut_gen
```

The successful run contains intermediate and final databases including:

```text
1_synth.odb
2_floorplan.odb
3_place.odb
4_cts.odb
5_route.odb
6_final.odb
6_final.v
6_final_lec.v
```

and associated intermediate databases:

```text
2_1_floorplan.odb
2_2_floorplan_macro.odb
2_3_floorplan_tapcell.odb
2_4_floorplan_pdn.odb
3_1_place_gp_skip_io.odb
3_2_place_iop.odb
3_3_place_gp.odb
3_4_place_resized.odb
3_5_place_dp.odb
4_1_cts.odb
5_1_grt.odb
5_2_route.odb
5_3_fillcell.odb
6_1_fill.odb
```

The earlier workspace also contains:

```text
1_synth.rpt
2_floorplan_final.rpt
3_detailed_place.rpt
3_global_place.rpt
3_resizer.rpt
4_cts_final.rpt
5_global_route.rpt
5_route_drc.rpt
6_finish.rpt
```

for both the `base` and `2ns` variants.

## Important distinction

These files demonstrate that the **ASAP7 ORFS infrastructure and a prior PALUTE baseline design successfully reached physical-design stages**.

They are not automatically physical-design results for the newer `lut_gen_unit` RTL.

This distinction is preserved deliberately so that the final project report remains technically defensible.

---

# 14. Overall Completion Matrix

| Stage | Current `lut_gen_unit` | Earlier `palute_baseline_lut_gen` |
|---|---|---|
| RTL | Complete | Complete |
| RTL simulation | Complete | Complete |
| Genus synthesis | Complete | Complete/reference |
| Genus area | Complete | Reference |
| Genus timing | Complete | Reference |
| Genus power | Complete | Reference |
| Yosys synthesis | Complete | Complete/reference |
| OpenROAD synth ODB | Blocked | Complete |
| Floorplan | Not completed | Complete |
| Placement | Not completed | Complete |
| CTS | Not completed | Complete |
| Global routing | Not completed | Complete |
| Detailed routing | Not completed | Complete |
| Final ODB | Not completed | Complete |
| Final routed Verilog | Not completed | Complete |
| Current RTL GDS | Not completed | Existing baseline workspace may contain related physical artifacts |

---

# 15. Files in This Package

```text
palute_7nm_final/
├── README.md
├── STATUS.md
├── FINAL_PROJECT_REPORT.md
├── GIT_PUSH_INSTRUCTIONS.md
│
├── rtl/
│   └── lut_gen_unit.v
│
├── tb/
│   └── tb_lut_gen_unit.v
│
├── constraints/
│   └── lut_gen_unit_5ns.sdc
│
├── synthesis/
│   └── lut_gen_unit_syn.tcl
│
├── netlist/
│   └── genus/
│       ├── syn.v
│       └── syn.sdc
│
├── reports/
│   └── genus/
│       ├── area.rpt
│       ├── timing.rpt
│       └── power.rpt
│
├── verification/
│   └── lut_gen_unit.vvp
│
├── docs/
│   ├── SILGplus_Architecture_Proposal.docx
│   └── EXTERNAL_REFERENCE_NOTE.md
│
└── scripts/
    └── collect_existing_orfs_results.sh
```

Large generated ORFS databases are intentionally not embedded in the lightweight source package. The helper script can import the previously completed ORFS result tree from `~/SILF_ASAP7` when the repository is being prepared locally.

---

# 16. Reproducibility

The main RTL and synthesis inputs are preserved.

For Genus:

```text
rtl/lut_gen_unit.v
synthesis/lut_gen_unit_syn.tcl
```

For the open-source ORFS experiment:

```text
rtl/lut_gen_unit.v
constraints/lut_gen_unit_5ns.sdc
```

The ORFS environment itself was containerized using the successfully built:

```text
openroad/flow-ubuntu22.04-builder:9ed603
```

The local Docker image should not be committed to Git.

---

# 17. Recommended Repository Structure

The project repository should contain this work under:

```text
SILF/
└── palute_7nm_final/
```

This makes the folder a self-contained project checkpoint and prevents the new 7nm work from being mixed with unrelated SILF material.

Recommended Git commit:

```text
Add PALUTE 7nm ASIC work package
```

---

# 18. Final Technical Assessment

The work completed so far establishes a credible ASIC-design pipeline up to the following level:

```text
RTL
  ↓
RTL simulation
  ↓
Cadence Genus synthesis
  ↓
Area / timing / power estimation
  ↓
Gate-level netlist
  ↓
OpenROAD/Yosys environment
  ↓
Current ORFS Yosys synthesis
  ↓
OpenROAD parser handoff blocker
```

The Genus run provides the strongest current PPA evidence for the exact LUT-generator RTL:

```text
4095 cells
620.204 reported cell area
666 ps critical path
1334 ps slack at 2 ns
1.28015 mW reported total power
```

The prior `SILF_ASAP7` workspace provides evidence that the ASAP7 ORFS physical-design infrastructure has previously been driven through:

```text
synthesis
→ floorplanning
→ placement
→ CTS
→ routing
→ final database
```

but that result must remain identified as the earlier `palute_baseline_lut_gen` run.

The current `lut_gen_unit` ORFS run should be considered **functionally synthesized but physically incomplete** until the signed-Verilog handoff issue is resolved or a parser-compatible netlist path is deliberately established.

That is the honest stopping point for this phase. The silicon gods have not granted us routing yet, but at least the evidence trail is intact.

---

# 19. Next Phase

When continuing the project, the next engineering tasks should be:

1. Resolve the signed-Verilog/OpenROAD parser handoff without changing the intended RTL behavior.
2. Regenerate the current `1_synth.odb`.
3. Complete current-design floorplanning.
4. Complete placement.
5. Complete CTS.
6. Complete global and detailed routing.
7. Generate final routed database/netlist.
8. Run post-route STA.
9. Generate post-route power estimates.
10. Generate GDS and inspect it in KLayout.
11. Compare current `lut_gen_unit` results against the earlier baseline.
12. Integrate the final measured comparison into the main SILF project report.

Until those steps are completed, this folder should remain the authoritative checkpoint for the work completed in this phase.
