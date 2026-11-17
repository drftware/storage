"""How the home's parts wear its two sets (looks.py): painted plaster mapped flat whichever way a
face looks, and oak trim cut from one plank of the floor's bake so no plank joints show. Shared
by the ground floor (art/lobby/build.py), the home front and the furnishings."""

import geo


def plaster_uv(tile=4.0):
    """Painted plaster: world-planar, 4 studs to a tile, whichever way a face looks."""
    def f(vs, n):
        ax = max(range(3), key=lambda i: abs(n[i]))
        a, b = {0: (1, 2), 1: (0, 2), 2: (0, 1)}[ax]
        return [(v[a] / tile, v[b] / tile) for v in vs]
    return f


def wood_uv(axis, lo, hi, column=4):
    """Wood trim (beams, rails, baseboards, benches) out of one plank of the floor's bake: the
    piece's length runs down the plank, so no plank joints show, the grain drawn out along it."""
    off = (column * 0.618034) % 1.0
    v0, v1 = (1.0 - off) / 3.0 + 0.01, (2.0 - off) / 3.0 - 0.01  # one plank's run in V
    u0, u1 = (column + 0.12) / 12.0, (column + 0.88) / 12.0
    span = [max(hi[i] - lo[i], 1e-6) for i in range(3)]
    def f(vs, n):
        ax = max(range(3), key=lambda i: abs(n[i]))
        other = [i for i in range(3) if i not in (ax, axis)]
        k = other[0] if other else [i for i in range(3) if i != ax][0]
        t = lambda v: (v[axis] - lo[axis]) / span[axis] if ax != axis else 0.5
        return [(u0 + (u1 - u0) * (v[k] - lo[k]) / span[k], v0 + (v1 - v0) * t(v)) for v in vs]
    return f


def wood_box(m, lo, hi, column=4, bevel=0.0):
    """A box of wood trim, its grain along its longest side."""
    axis = max(range(3), key=lambda i: abs(hi[i] - lo[i]))
    geo.box(m, lo, hi, wood_uv(axis, lo, hi, column), bevel=bevel)
