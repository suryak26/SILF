#!/usr/bin/env python3

"""
Independent Python golden model for ASP_LUT.

For u=1:
    w1 = 1..8
    w2 = +1..+7 and -1..-7
    total = 8 * 14 = 112 LUT entries

Each result is represented as a signed 9-bit value.
"""

P_X = 4
P_Y = 9

W1_MAG_NUM = 8
W2_MAG_NUM = 7

LUT_DEPTH = W1_MAG_NUM * 2 * W2_MAG_NUM


def signed_9bit(value: int) -> int:
    """Convert an integer to its 9-bit two's-complement interpretation."""
    value &= (1 << P_Y) - 1

    if value & (1 << (P_Y - 1)):
        value -= 1 << P_Y

    return value


def golden_lut(x1: int, x2: int) -> list[int]:
    """
    Generate the complete 112-entry ASP_LUT reference.

    Entry ordering:
        for each w1 = 1..8:
            +w2 entries for w2 = 1..7
            -w2 entries for w2 = 1..7
    """

    results = []

    for w1 in range(1, W1_MAG_NUM + 1):

        # Positive w2
        for w2 in range(1, W2_MAG_NUM + 1):
            value = (w1 * x1) + (w2 * x2)
            results.append(signed_9bit(value))

        # Negative w2
        for w2 in range(W2_MAG_NUM, 0, -1):
            value = (w1 * x1) - (w2 * x2)
            results.append(signed_9bit(value))
    assert len(results) == LUT_DEPTH

    return results


def main() -> None:
    print("ASP_LUT Python Golden Model")
    print("============================")
    print(f"Input width : {P_X} bits signed")
    print(f"Output width: {P_Y} bits signed")
    print(f"LUT entries : {LUT_DEPTH}")
    print()

    # Example reference calculation
    x1 = -8
    x2 = -8

    values = golden_lut(x1, x2)

    print(f"Example input: x1={x1}, x2={x2}")
    print(f"Entry 0      : {values[0]}")
    print(f"Entry 1      : {values[1]}")
    print(f"Entry 6      : {values[6]}")
    print(f"Entry 7      : {values[7]}")
    print(f"Entry 111    : {values[111]}")

    print()
    print("Golden-model generation: PASS")


if __name__ == "__main__":
    main()
