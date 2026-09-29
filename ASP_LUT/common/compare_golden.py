#!/usr/bin/env python3

import csv
import sys
from pathlib import Path

from golden_reference import golden_lut


CSV_PATH = Path("../sim/results/asplut_rtl_output.csv")


def main() -> int:
    if not CSV_PATH.exists():
        print(f"ERROR: CSV not found: {CSV_PATH}")
        return 1

    total = 0
    mismatches = 0

    with CSV_PATH.open("r", newline="") as f:
        reader = csv.DictReader(f)

        expected_header = ["x1", "x2", "lut_index", "actual_value"]
        if reader.fieldnames != expected_header:
            print(f"ERROR: Unexpected CSV header: {reader.fieldnames}")
            return 1

        cache = {}

        for row in reader:
            x1 = int(row["x1"])
            x2 = int(row["x2"])
            lut_index = int(row["lut_index"])
            actual = row["actual_value"].strip()

            total += 1

            key = (x1, x2)

            if key not in cache:
                cache[key] = golden_lut(x1, x2)

            expected = cache[key][lut_index]

            if actual.lstrip("-").isdigit():
                actual_int = int(actual)
            else:
                actual_int = None

            if actual_int != expected:
                mismatches += 1

                if mismatches <= 20:
                    print(
                        f"MISMATCH: "
                        f"x1={x1}, x2={x2}, "
                        f"lut_index={lut_index}, "
                        f"expected={expected}, "
                        f"actual={actual}"
                    )

    print("========================================")
    print("ASP_LUT PYTHON GOLDEN-MODEL VERIFICATION")
    print("========================================")
    print(f"Total entries compared : {total}")
    print(f"Mismatches             : {mismatches}")

    if total != 256 * 112:
        print(
            f"ERROR: Expected {256 * 112} entries, "
            f"but found {total}"
        )
        return 1

    if mismatches == 0:
        print("RESULT: RTL MATCHES GOLDEN MODEL EXACTLY [PASS]")
        return 0

    print("RESULT: RTL DOES NOT MATCH GOLDEN MODEL [FAIL]")
    return 1


if __name__ == "__main__":
    sys.exit(main())
