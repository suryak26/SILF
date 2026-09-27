# PALUTE Paper Alignment

## Parameters aligned with the reference architecture

| Parameter | Reference | BL-00 |
|---|---:|---:|
| Logic technology class | 7 nm | ASAP7 7 nm-class |
| Precision | W4A4 / INT4 | 4-bit |
| Segment length | b=2 | u=1 represents segment length 2 |
| LUT depth | 112 | 112 |
| LUT generation | 3 cycles | 3-cycle u=1 path |
| Target clock | 200 MHz | 200 MHz |
| Clock period | 5 ns | 5 ns |

## Parameters that are not directly equivalent

The paper's published area and power figures describe the broader PALUTE system/chip context. BL-00 measures the physical implementation of the LUT-generator block. Therefore the paper's system-level area/power values are not used as direct block-level comparison numbers.

The paper's Cadence-based methodology and its exact 7 nm PDK/PVT details are not identical to this open-source ASAP7/OpenROAD implementation.

## Use in future experiments

BL-00 should remain fixed. Optimization experiments should use the same RTL function, clock target, PVT/library selection, floorplan assumptions, and reporting methodology unless the experiment explicitly studies one of those variables.
