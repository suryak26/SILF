# BL-00 Verification Record

## RTL compilation and simulation

The baseline was compiled with Icarus Verilog 12.0 using:

```bash
iverilog -g2012 -s tb_lut_gen_unit -o /tmp/palute_sim/lut_gen_tb rtl/lut_gen_unit.v tb/tb_lut_gen_unit.v
vvp /tmp/palute_sim/lut_gen_tb
```

The simulation completed successfully.

Representative inputs:

- x1 = 3
- x2 = -2
- u = 1

Observed generation stages:

### Cycle 1

```
3, 6, 9, 12, 15, 18, 21, 24
```

### Cycle 2

```
-2, -4, -6, -8, -10, -12, -14
```

### Cycle 3 negative products

```
2, 4, 6, 8, 10, 12, 14
```

The final output asserted done and printed all 112 LUT entries.

Representative observed entries included:

```
LUT[0]   = 1
LUT[1]   = -1
LUT[6]   = -11
LUT[7]   = 5
LUT[13]  = 17
LUT[14]  = 4
LUT[105] = 26
LUT[111] = 38
```

The testbench is observational and representative. It is not formal verification and does not constitute an exhaustive proof over all possible signed inputs.
