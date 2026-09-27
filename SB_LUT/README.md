# SB_LUT — Shared Broadcast LUT

## Overview

SB_LUT is a hardware implementation of a Shared Broadcast Look-Up Table (SB-LUT) architecture.

The design generates a 128-entry LUT from two 4-bit signed inputs. The computation is organized into two cycles of partial-product generation followed by a final cycle that combines the two sets of partial results into the complete LUT.

## Architecture

The RTL contains four states:

- `IDLE` — waits for `start`
- `CYC1` — computes the eight `w1 × x1` partial products for `w1 = 0 ... 7`
- `CYC2` — computes the sixteen `w2 × x2` partial products for `w2 = -8 ... 7`
- `DONE` — combines the partial products to generate all 128 LUT entries

The final LUT contains:

```text
8 × 16 = 128 entries
