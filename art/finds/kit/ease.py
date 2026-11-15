"""How a find's motion keys are eased, the same sums as src/shared/Finds/Art.luau, so the game
plays exactly what the previews showed. Pure Python: no Blender."""

import math

BACK = 1.70158  # the classic overshoot (about 10 per cent past the key, then back)
STYLES = ("Linear", "Sine", "Quad", "Cubic", "Quart", "Back")
DIRECTIONS = ("In", "Out", "InOut")


def _in(style, t):
    if style == "Linear":
        return t
    if style == "Sine":
        return 1.0 - math.cos(t * math.pi / 2.0)
    if style == "Quad":
        return t * t
    if style == "Cubic":
        return t * t * t
    if style == "Quart":
        return t * t * t * t
    if style == "Back":
        return t * t * ((BACK + 1.0) * t - BACK)
    raise ValueError(f"no easing style {style}")


def ease(style, direction, t):
    t = min(max(t, 0.0), 1.0)
    if direction == "In":
        return _in(style, t)
    if direction == "Out":
        return 1.0 - _in(style, 1.0 - t)
    if direction == "InOut":
        return _in(style, 2.0 * t) / 2.0 if t < 0.5 else 1.0 - _in(style, 2.0 - 2.0 * t) / 2.0
    raise ValueError(f"no easing direction {direction}")


def keys(raw):
    """A track's keys from the spec, each (time, value) or (time, value, style, direction): the
    style and direction say how that key is reached from the one before. Default Sine InOut."""
    out = []
    for k in raw:
        t, v = float(k[0]), float(k[1])
        st = k[2] if len(k) > 2 else "Sine"
        d = k[3] if len(k) > 3 else "InOut"
        assert st in STYLES and d in DIRECTIONS, k
        assert not out or t >= out[-1][0], f"keys out of order at {k}"
        out.append((t, v, st, d))
    return out


def sample(ks, t):
    if t <= ks[0][0]:
        return ks[0][1]
    for (t0, v0, _, _), (t1, v1, st, d) in zip(ks, ks[1:]):
        if t <= t1:
            a = (t - t0) / (t1 - t0) if t1 > t0 else 1.0
            return v0 + (v1 - v0) * ease(st, d, a)
    return ks[-1][1]


def kelvin(k):
    """A light's colour from its colour temperature (Tanner Helland's fit to blackbody), 0-255."""
    t = k / 100.0
    r = 255.0 if t <= 66 else 329.698727446 * (t - 60) ** -0.1332047592
    g = (99.4708025861 * math.log(t) - 161.1195681661 if t <= 66
         else 288.1221695283 * (t - 60) ** -0.0755148492)
    b = 255.0 if t >= 66 else (0.0 if t <= 19 else 138.5177312231 * math.log(t - 10) - 305.0447927307)
    return tuple(int(round(min(max(c, 0.0), 255.0))) for c in (r, g, b))
