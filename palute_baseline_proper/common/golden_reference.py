#!/usr/bin/env python3

"""
Independent Python golden model for the PALUTE baseline LUT generator.

RTL behavior:

u = 0:
    Entry 0..7:
        |w1| * x1, where |w1| = 1..8
    Entry 8..111:
        0

u = 1:
    For each |w1| = 1..8:
        +|w2| terms for |w2| = 1..7
        -|w2| terms for |w2| = 1..7

Thus:
    LUT_DEPTH = 8 * 2 * 7 = 112
"""

P_X = 4
P_W = 4
P_Y = P_X + P_W + 1

W1_MAG_NUM = 8
W2_MAG_NUM = 7

LUT_DEPTH = W1_MAG_NUM * 2 * W2_MAG_NUM


def signed_9bit(value: int) -> int:
    """Interpret value as a signed 9-bit two's-complement value."""
    value &= (1 << P_Y) - 1

    if value & (1 << (P_Y - 1)):
        value -= 1 << P_Y

    return value


def golden_lut(x1: int, x2: int, u: int) -> list[int]:
    """
    Generate the exact 112-entry PALUTE baseline reference LUT.

    Entry ordering for u=1:

        For each w1 = 1..8:
            positive section:
                w1*x1 + 1*x2
                w1*x1 + 2*x2
                ...
                w1*x1 + 7*x2

            negative section:
                w1*x1 - 1*x2
                w1*x1 - 2*x2
                ...
                w1*x1 - 7*x2

    For u=0:

        Entry 0..7:
            w1*x1 for w1 = 1..8

        Entry 8..111:
            zero
    """

    if x1 < -(1 << (P_X - 1)) or x1 > (1 << (P_X - 1)) - 1:
        raise ValueError(f"x1 out of signed {P_X}-bit range: {x1}")

    if x2 < -(1 << (P_X - 1)) or x2 > (1 << (P_X - 1)) - 1:
        raise ValueError(f"x2 out of signed {P_X}-bit range: {x2}")

    if u not in (0, 1):
        raise ValueError(f"u must be 0 or 1: {u}")

    results = []

    # u = 0:
    # RTL writes only the first W1_MAG_NUM entries.
    if u == 0:
        for w1 in range(1, W1_MAG_NUM + 1):
            results.append(signed_9bit(w1 * x1))

        results.extend([0] * (LUT_DEPTH - W1_MAG_NUM))

    # u = 1:
    # RTL writes positive and negative sections for every w1.
    else:
        for w1 in range(1, W1_MAG_NUM + 1):

            for w2 in range(1, W2_MAG_NUM + 1):
                value = (w1 * x1) + (w2 * x2)
                results.append(signed_9bit(value))

            for w2 in range(1, W2_MAG_NUM + 1):
                value = (w1 * x1) - (w2 * x2)
                results.append(signed_9bit(value))

    assert len(results) == LUT_DEPTH

    return results


def main() -> None:
    print("PALUTE BASELINE PYTHON GOLDEN MODEL")
    print("===================================")
    print(f"Input width  : {P_X} bits signed")
    print(f"Weight width : {P_W} bits")
    print(f"Output width : {P_Y} bits signed")
    print(f"LUT depth    : {LUT_DEPTH}")
    print()

    x1 = 3
    x2 = -2

    for u in (0, 1):
        values = golden_lut(x1, x2, u)

        print(f"Example input: u={u}, x1={x1}, x2={x2}")
        print(f"Entry 0      : {values[0]}")
        print(f"Entry 1      : {values[1]}")
        print(f"Entry 6      : {values[6]}")
        print(f"Entry 7      : {values[7]}")
        print(f"Entry 8      : {values[8]}")
        print(f"Entry 14     : {values[14]}")
        print(f"Entry 111    : {values[111]}")
        print()

    print("Golden-model generation: PASS")


if __name__ == "__main__":
    main()
