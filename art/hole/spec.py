"""Every number of the crawl hole. Change them here only.

A saw's crawl hole in a unit's side wall (GDD "The hole trap"): a low, roughly square hole in the
corrugated steel, its cut edge ragged and bright, a few tongues of steel torn and bent away from
whoever sawed it, and the cut-out panel lying flat on the far side where it fell. Where the hole
opens and how big it is are the unit's numbers (art/unit/spec.py, `crawl_*`), so the hole sits at
the same place in every unit.

Blender axes as the unit's: X across the unit (the wall's normal), Y along the wall away from the
hall (from the corridor wall's outer face), Z up. The kit is drawn in the wall's own frame: the
wall's middle plane at X = 0, its ribs standing out toward +X, as the unit's WallLeft and
WallRight are built. "Pos" pieces fall toward +X, "Neg" ones are their mirror.
"""

import importlib.util
import math
import os
import random

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", ".."))
UNIT_DIR = os.path.join(ROOT, "art", "unit")


def _unit_spec():
    s = importlib.util.spec_from_file_location("unit_spec", os.path.join(UNIT_DIR, "spec.py"))
    mod = importlib.util.module_from_spec(s)
    s.loader.exec_module(mod)
    return mod


U = _unit_spec()
C = U.COMMON

SET = "Hole"    # the texture set of the cut edges, the bent tongues and the panel's rim
TEX = 512       # thin strips: a phone sees them as a bright line, never close up
DUST = 0.0      # freshly cut
SEED = 61.0

# The hole, from the unit's spec: along the wall (Y) and up (Z).
FROM, TO = C["crawl_from"], C["crawl_to"]
BOTTOM, TOP = C["crawl_bottom"], C["crawl_top"]
H = C["wall_height"]
F = C["facade"]
SIZES = {k: v["depth"] for k, v in U.SIZES.items() if k in ("S", "M")}

# The wall's sheet, as art/unit/parts.py's `corrugated` builds it: trapezoid ribs every stud,
# standing RIB out toward +X, the sheet SHEET thick, its faces Z0 to Z1 up (the tracks hide the
# rest). Each side wall's grain starts U_OFF studs along (the right wall's is shifted so the two
# walls of a unit don't match).
RIB, SHEET = 0.10, 0.03
RIB_PROFILE = ((0.0, 0.0), (0.32, 0.0), (0.43, RIB), (0.57, RIB), (0.68, 0.0))
Z0, Z1 = 0.12, H - 0.12
U_OFF = {"Left": 0.0, "Right": 1.37}

# The cut: a rounded square (the saw turns its corners in a short curve), wandering where a hand
# guided it and chattering where the blade jumped.
CORNER = 0.24       # the corners' radius
STEP = 0.1          # studs between the outline's points
WANDER = (0.035, 1.3)   # the hand's wander: how far, over how long a stretch (studs)
CHATTER = 0.012     # the blade's jitter, point to point
KERF = 0.02         # the blade's width: the panel is this much smaller than the hole
# The bright strip round the cut on each face: shoe scratches and bare steel, this wide (studs).
BAND = (0.07, 0.13)
PANEL_BAND = (0.05, 0.09)   # the same round the fallen panel's top face

# Tongues of steel the cut left and the push bent away from the saw: where round the outline (a
# share of the way from the bottom's front end, going back along the bottom, up the back, forward
# along the top and down the front), how long a root (studs), how far they reach in, and how far
# they're bent (degrees, 90 is flat out from the wall).
TABS = [
    dict(at=0.18, root=0.28, reach=0.2, bend=58),     # the bottom's back half
    dict(at=0.36, root=0.34, reach=0.24, bend=34),    # low on the back edge
    dict(at=0.585, root=0.30, reach=0.17, bend=72),   # the top, toward the back
    dict(at=0.70, root=0.22, reach=0.14, bend=25),    # the top, toward the front
    dict(at=0.90, root=0.26, reach=0.18, bend=48),    # the front edge, low
]
TAB_ROWS = 3        # rows from root to tip: the bend curls

# The panel where it fell: hinged on its bottom edge and flat on its ribs on the far side, its
# bottom edge GAP out from the wall's middle (past the bottom track), slid SLIDE along the wall and
# turned TURN degrees as it landed. Its face that was toward the saw faces up.
GAP, SLIDE, TURN = 0.45, 0.12, 7.0


def offset(a):
    """How far the sheet's middle stands out toward +X at `a` studs along the wall."""
    k = math.floor(a)
    f = a - k
    pts = list(RIB_PROFILE) + [(1.0, 0.0)]
    for (f0, o0), (f1, o1) in zip(pts, pts[1:]):
        if f0 - 1e-9 <= f <= f1 + 1e-9:
            t = 0.0 if f1 == f0 else (f - f0) / (f1 - f0)
            return o0 + (o1 - o0) * t
    return 0.0


def folds(a0, a1):
    """Every place between a0 and a1 where the sheet folds (where `offset` changes slope)."""
    out = []
    for k in range(math.floor(a0) - 1, math.ceil(a1) + 1):
        for f, _ in RIB_PROFILE:
            a = k + f
            if a0 + 1e-6 < a < a1 - 1e-6:
                out.append(a)
    return sorted(out)


def _base(n_per):
    """The rounded square's path, counter-clockwise from the bottom's front end: [(a, z, na, nz,
    s)] with the outward normal and the share of the way round."""
    r = CORNER
    a0, a1, z0, z1 = FROM, TO, BOTTOM, TOP
    pts = []
    # straight runs and corner arcs, in order: bottom, corner, back, corner, top, corner, front,
    # corner
    runs = [((a0 + r, z0), (a1 - r, z0), (0.0, -1.0)),
            ((a1 - r, z0 + r), -90.0),
            ((a1, z0 + r), (a1, z1 - r), (1.0, 0.0)),
            ((a1 - r, z1 - r), 0.0),
            ((a1 - r, z1), (a0 + r, z1), (0.0, 1.0)),
            ((a0 + r, z1 - r), 90.0),
            ((a0, z1 - r), (a0, z0 + r), (-1.0, 0.0)),
            ((a0 + r, z0 + r), 180.0)]
    for run in runs:
        if len(run) == 3:
            (pa, pz), (qa, qz), (na, nz) = run
            n = max(1, round(math.hypot(qa - pa, qz - pz) / STEP))
            for i in range(n):
                t = i / n
                pts.append((pa + (qa - pa) * t, pz + (qz - pz) * t, na, nz))
        else:
            (ca, cz), start = run
            n = max(2, round(r * math.pi / 2 / STEP) + 1)
            for i in range(n):
                ang = math.radians(start + 90.0 * i / n)
                na, nz = math.cos(ang), math.sin(ang)
                pts.append((ca + r * na, cz + r * nz, na, nz))
    # share of the way round, by length
    lens = [0.0]
    for p, q in zip(pts, pts[1:] + pts[:1]):
        lens.append(lens[-1] + math.hypot(q[0] - p[0], q[1] - p[1]))
    total = lens[-1]
    return [(a, z, na, nz, lens[i] / total) for i, (a, z, na, nz) in enumerate(pts)], total


def outline():
    """The hole's outline as drawn: [(a, z, na, nz, s, wob)], `wob` how far the cut strayed out
    (negative: in) from the rounded square, and per point the strips' widths."""
    rng = random.Random(int(SEED))
    pts, total = _base(None)
    # the hand's wander: a few slow waves round the whole path, so it closes on itself
    waves = [(rng.uniform(0, 2 * math.pi), max(1, round(total / (WANDER[1] * m))), WANDER[0] / m)
             for m in (1.0, 1.8, 3.1)]
    out = []
    for a, z, na, nz, s in pts:
        wob = sum(amp * math.sin(2 * math.pi * cyc * s + ph) for ph, cyc, amp in waves)
        wob += rng.uniform(-CHATTER, CHATTER)
        band = rng.uniform(*BAND)
        pband = rng.uniform(*PANEL_BAND)
        out.append(dict(a=a, z=z, na=na, nz=nz, s=s, wob=wob, band=band, pband=pband))
    # the blade jumped here and there: a short step out, a point or two long
    for _ in range(4):
        i = rng.randrange(len(out))
        for j in range(rng.choice((1, 2))):
            out[(i + j) % len(out)]["wob"] += rng.choice((-1, 1)) * 0.03
    return out


def ring(pts, by):
    """A ring of points `by(p)` studs out from the rounded square along each point's normal."""
    return [(p["a"] + p["na"] * by(p), p["z"] + p["nz"] * by(p)) for p in pts]


def lua_num(v):
    s = f"{v:.4f}".rstrip("0").rstrip(".")
    return s if s not in ("-0", "") else "0"


def write_luau(path, parts):
    """parts: {name: dict(size, centre, tris)} in Roblox axes (the kit's own frame)."""

    def v3(v):
        return f"Vector3.new({lua_num(v[0])}, {lua_num(v[1])}, {lua_num(v[2])})"

    lines = [
        "--!strict",
        "-- Generated by art/hole/build.py --stage export from art/hole/spec.py and the unit's",
        "-- crawl_* numbers (art/unit/spec.py). Don't edit: change the spec and rebuild",
        "-- (scripts/art.sh hole).",
        "",
        "export type Piece = {",
        "\tSize: Vector3, -- the piece's box",
        "\tCentre: Vector3, -- the box's middle, in the kit's frame (the wall's middle plane, the",
        "\t-- corridor wall's outer face, the floor)",
        "\tTriangles: number,",
        "}",
        "",
        "return {",
        "\t-- The hole, in studs: along the wall from the corridor wall's outer face, and up from the",
        "\t-- floor. Its cut wanders a few hundredths either side of these.",
        f"\tFrom = {lua_num(FROM)},",
        f"\tTo = {lua_num(TO)},",
        f"\tBottom = {lua_num(BOTTOM)},",
        f"\tTop = {lua_num(TOP)},",
        "\tParts = {",
    ]
    for name in sorted(parts):
        p = parts[name]
        lines.append(f"\t\t{name} = {{ Size = {v3(p['size'])}, Centre = {v3(p['centre'])}, "
                     f"Triangles = {p['tris']} }} :: Piece,")
    lines += ["\t},", "}", ""]
    with open(path, "w") as f:
        f.write("\n".join(lines))


def to_roblox(v):
    """Blender (x, y, z) to Roblox (X, Y, Z): x = -X, y = Z, z = Y."""
    return (-v[0], v[2], v[1])
