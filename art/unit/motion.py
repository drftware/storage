"""Python twin of src/shared/StorageUnit/Motion.luau, for the animation sheets."""

import math

FULL = {"Peek": 1.0, "Open": 2.0, "Close": 1.6, "LiftInside": 6.0}
SLAM_G = 200.0
BOUNCE_T = 0.26
MIN_T = 0.12


def _out_quart(t):
    return 1 - (1 - t) ** 4


def _in_out_cubic(t):
    return 4 * t ** 3 if t < 0.5 else 1 - (-2 * t + 2) ** 3 / 2


def _lift(t):
    return 0.8 * _in_out_cubic(t) + 0.2 * _out_quart(t)


def duration(kind, a, b, full):
    h = abs(b - a)
    if h < 1e-4:
        return 0.0
    if kind == "Slam":
        return math.sqrt(2 * h / SLAM_G) + BOUNCE_T
    frac = 1.0 if kind == "Peek" else min(1.0, h / max(full, 1e-3))
    return max(MIN_T, FULL.get(kind, 2.0) * frac)


def sample(kind, a, b, t, full):
    d = duration(kind, a, b, full)
    if d <= 0 or t >= d:
        return b
    if t <= 0:
        return a
    h = b - a
    if kind == "Slam":
        fall = math.sqrt(2 * abs(h) / SLAM_G)
        if t < fall:
            return a + h * (t / fall) ** 2
        u = (t - fall) / BOUNCE_T
        return b + min(0.32, 0.045 * abs(h)) * math.sin(math.pi * u) * (1 - u) ** 1.5
    x = min(max(t / d, 0.0), 1.0)
    if kind == "Peek":
        return a + h * _out_quart(x)
    if kind == "Close":
        return a + h * _in_out_cubic(x)
    if kind == "LiftInside":
        return a + h * min(max(x + math.sin(x * math.pi * 6) * 0.025 * (1 - x), 0.0), 1.0)
    return a + h * _lift(x)


def timeline(steps, full, fps=24):
    """steps: [("Hold", seconds) | (kind, target)] -> list of rises, one per frame."""
    out, rise = [], 0.0
    for kind, arg in steps:
        if kind == "Hold":
            n = int(round(arg * fps))
            out += [rise] * n
            continue
        d = duration(kind, rise, arg, full)
        n = max(1, int(math.ceil(d * fps)))
        out += [sample(kind, rise, arg, i / fps, full) for i in range(1, n + 1)]
        rise = arg
    return out
