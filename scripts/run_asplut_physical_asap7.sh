#!/usr/bin/env bash
set -euo pipefail

# Run from OpenROAD-flow-scripts/flow.
# This script is intentionally a real physical-design run, not an area estimator.

export DESIGN_CONFIG="./designs/asap7/asplut_gen_unit/config.mk"

echo "=== ASPLUT ASAP7 physical-design run ==="
echo "Design config: ${DESIGN_CONFIG}"

make DESIGN_CONFIG="${DESIGN_CONFIG}" clean_all
make DESIGN_CONFIG="${DESIGN_CONFIG}"

echo
echo "=== Expected final artifacts ==="
echo "results/asap7/asplut_gen_unit/base/6_final.odb"
echo "results/asap7/asplut_gen_unit/base/6_final.def"
echo "results/asap7/asplut_gen_unit/base/6_final.gds"
echo "results/asap7/asplut_gen_unit/base/6_final.spef"
echo "results/asap7/asplut_gen_unit/base/6_final.v"
echo "reports/asap7/asplut_gen_unit/base/6_report.json"
echo "reports/asap7/asplut_gen_unit/base/6_finish.rpt"

echo
echo "=== Extract requested final physical metrics ==="
python3 - <<'PY'
import json, pathlib
p = pathlib.Path("reports/asap7/asplut_gen_unit/base/6_report.json")
if not p.exists():
    print("6_report.json not found. The physical flow did not finish.")
    raise SystemExit(1)
d = json.loads(p.read_text())
keys = [
    "finish__design__io",
    "finish__design__nets",
    "finish__design__instance__count",
    "finish__design__instance__area",
    "finish__design__core__area",
    "finish__design__die__area",
    "finish__design__instance__utilization",
    "finish__power__total",
    "finish__timing__fmax",
    "finish__timing__drv__setup_violation_count",
    "finish__timing__drv__hold_violation_count",
]
for k in keys:
    print(f"{k}: {d.get(k, 'MISSING')}")
PY
