"""Every number of the sawn top. Change them here only.

A saw's hole down through a unit's steel top (L-13b2d, as Rainbow Six Siege's floor hatches): a
rounded square cut in the ribbed steel, big enough for a body to drop through feet first, its cut
ragged and bright, a few tongues of steel bent down into the unit, the first channel under the
sheet sawn through where it crossed, and the cut-out panel lying on the floor below where it fell,
the channel's stub still screwed under it.

Where it opens: in the middle of the unit's width, just behind the door's drum, across the first
of the three channels the top rests on. The same place in every unit by that channel, so one cut
edge and one panel serve every size and players learn where it is: on a small unit the hole's back
stops short of the sheets' lap; on an M it's a stud further back, as its channel is.

Blender axes as the unit's: X across the unit (0 its middle), Y back from the corridor wall's outer
face, Z up from the floor. The hole is drawn in its own frame: X the same, Y from the first
channel's middle (`channel(size)` in the unit's Y), Z the same. The holed tops are in each unit's
own frame; the cut edge, the panel and its rim are in the hole's frame (the game shifts them by
`channel(size)`).
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

SET = "TopHole"  # the texture set of the cut edges, the bent tongues and the panel's rim
TEX = 512        # thin strips: a phone sees them as a bright line round a dark hole
DUST = 0.0       # freshly cut
SEED = 67.0

H = C["wall_height"]
F = C["facade"]
SIZES = {k: dict(width=v["width"], depth=v["depth"]) for k, v in U.SIZES.items()
         if k in ("S", "M")}

# The top's sheet, as art/unit/parts.py's `flat_sheet` lays it: trapezoid ribs every stud across
# the unit, standing RIB up, the sheet SHEET thick, the front sheet's flats' middle at Z_SHEET.
RIB, SHEET = 0.10, 0.03
RIB_PROFILE = ((0.0, 0.0), (0.32, 0.0), (0.43, RIB), (0.57, RIB), (0.68, 0.0))
Z_SHEET = H + 0.012 + SHEET / 2
LAP = 0.3                     # the back sheet lies this far over the front one (parts.TOP_LAP)
TOP_BAND = (0.5, 0.97)        # the Partition texture's clean upper band the top wears
# The channels under the sheets (parts.top): 0.14 wide, from 0.22 under the top's rim to it.
CHANNEL_HALF = 0.07
CHANNEL_Z = (H - 0.22, H + 0.012)


def channel(size):
    """The first channel's middle, in the unit's Y: where the hole's frame starts."""
    D = SIZES[size]["depth"]
    return F + (D - F) / 4


# The hole, in its frame: across the unit (X) and back from the first channel (Y). 2.8 across and
# 2.05 front to back: a body drops through feet first, shoulders across, arms up, with a little to
# spare; a lying body (`Tops.Body`, 1.8 wide) can't pass it unnoticed. Its front stays behind the
# door's drum when the door is open (its coil reaches about 1.65 back on every size) and on a small
# unit its back stays clear of the lap (3.975); the bulb, on the middle channel, hangs behind it.
X0, X1 = -1.4, 1.4
Y0, Y1 = -0.5, 1.55

# The cut: a rounded square (the saw turns its corners in a short curve), wandering where a hand
# guided it and chattering where the blade jumped. As the wall hole's (art/hole/spec.py).
CORNER = 0.22
STEP = 0.1
WANDER = (0.035, 1.3)
CHATTER = 0.012
KERF = 0.02         # the blade's width: the panel is this much smaller than the hole
BAND = (0.07, 0.13)          # the bright strip round the cut on each face (studs)
PANEL_BAND = (0.05, 0.09)    # the same round the fallen panel's top face

# Tongues of steel the cut left, bent down into the unit by the push and the panel's weight: where
# round the outline (a share of the way from the front edge's left end, going right along the
# front, back up the right side, left along the back and forward down the left side), how long a
# root, how far they reach in, how far they're bent (degrees, 90 is straight down). None sits
# where the channel crosses a side (about 0.35 and 0.95 round): the channel was cut there.
TABS = [
    dict(at=0.10, root=0.28, reach=0.2, bend=52),     # the front edge, left of middle
    dict(at=0.44, root=0.30, reach=0.18, bend=30),    # the right side, toward the back
    dict(at=0.60, root=0.34, reach=0.24, bend=70),    # the back edge, right of middle
    dict(at=0.73, root=0.22, reach=0.14, bend=24),    # the back edge, left
    dict(at=0.86, root=0.26, reach=0.18, bend=44),    # the left side, toward the back
]
TAB_ROWS = 3

# The panel where it fell: the cut-out sheet with the channel's stub still screwed under it,
# landed face up on the floor below the hole, propped on the stub (so it lies tilted, its front
# edge up), slid aside and turned as it landed, so whoever drops after it lands mostly beside it.
FALL_SLIDE = (1.7, 0.15)   # studs it ended up across and back from where it was cut
FALL_TURN = 11.0           # degrees it turned about the vertical


def offset(a):
    """How far the sheet's middle stands up at `a` studs across the unit (the unit's rib grain:
    a rib in the middle of every stud, as `parts.rib_points`)."""
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


def _base():
    """The rounded square's path, counter-clockwise seen from above, from the front edge's left
    end: [(x, y, nx, ny)] with the outward normal, and its length. (The wall hole's names: `a` is
    across, `z` is back.)"""
    r = CORNER
    a0, a1, z0, z1 = X0, X1, Y0, Y1
    pts = []
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
    lens = [0.0]
    for p, q in zip(pts, pts[1:] + pts[:1]):
        lens.append(lens[-1] + math.hypot(q[0] - p[0], q[1] - p[1]))
    total = lens[-1]
    return [(a, z, na, nz, lens[i] / total) for i, (a, z, na, nz) in enumerate(pts)], total


def outline():
    """The hole's outline as drawn: [dict(a, z, na, nz, s, wob, band, pband)] in the hole's frame
    (`a` across, `z` back), `wob` how far the cut strayed out (negative: in) from the rounded
    square, and per point the strips' widths."""
    rng = random.Random(int(SEED))
    pts, total = _base()
    waves = [(rng.uniform(0, 2 * math.pi), max(1, round(total / (WANDER[1] * m))), WANDER[0] / m)
             for m in (1.0, 1.8, 3.1)]
    out = []
    for a, z, na, nz, s in pts:
        wob = sum(amp * math.sin(2 * math.pi * cyc * s + ph) for ph, cyc, amp in waves)
        wob += rng.uniform(-CHATTER, CHATTER)
        out.append(dict(a=a, z=z, na=na, nz=nz, s=s, wob=wob, band=rng.uniform(*BAND),
                        pband=rng.uniform(*PANEL_BAND)))
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


def to_roblox(v):
    """Blender (x, y, z) to Roblox (X, Y, Z): x = -X, y = Z, z = Y."""
    return (-v[0], v[2], v[1])


def fall_cframe(m):
    """A 4x4 transform in the hole's frame (Blender axes, rows of numbers) as a Roblox CFrame's
    constructor: the same move in Roblox axes. Blender to Roblox is C = (x -> -X, y -> Z, z -> Y),
    its own inverse, so the turn is C M C and the shift is C t."""
    c = ((-1, 0, 0), (0, 0, 1), (0, 1, 0))
    r = [[sum(c[i][a] * m[a][b] * c[b][j] for a in range(3) for b in range(3))
          for j in range(3)] for i in range(3)]
    t = to_roblox((m[0][3], m[1][3], m[2][3]))
    nums = [lua_num(v) for v in t] + [f"{r[i][j]:.6f}" for i in range(3) for j in range(3)]
    return "CFrame.new(" + ", ".join(n if n != "-0.000000" else "0.000000" for n in nums) + ")"


def write_luau(path, parts, fall):
    """parts: {name: dict(size, centre, tris)} in Roblox axes, each in its own frame (a holed
    top in its unit's, the rest in the hole's). fall: the panel's fall (build.py's `lay`), a 4x4
    in Blender axes."""

    def v3(v):
        return f"Vector3.new({lua_num(v[0])}, {lua_num(v[1])}, {lua_num(v[2])})"

    lines = [
        "--!strict",
        "-- Generated by art/tophole/build.py --stage export from art/tophole/spec.py and the",
        "-- unit's numbers (art/unit/spec.py). Don't edit: change the spec and rebuild",
        "-- (scripts/art.sh tophole).",
        "",
        "export type Piece = {",
        "\tSize: Vector3, -- the piece's box",
        "\tCentre: Vector3, -- the box's middle: a holed top's in its unit's frame (the unit's",
        "\t-- middle across, the corridor wall's outer face, the floor), the rest in the hole's",
        "\t-- (the same, but from the first channel's middle: add `Channel[size]` along Z)",
        "\tTriangles: number,",
        "}",
        "",
        "return {",
        "\t-- Where the hole's frame starts in each unit: the first channel's middle, studs back",
        "\t-- from the corridor wall's outer face (Roblox +Z).",
        "\tChannel = {",
    ]
    for size in sorted(SIZES):
        lines.append(f"\t\t{size} = {lua_num(channel(size))},")
    lines += [
        "\t},",
        "\t-- The hole in its frame, in studs: across from the unit's middle (Roblox X) and back",
        "\t-- from the first channel (Roblox Z). Its cut wanders a few hundredths either side.",
        f"\tLeft = {lua_num(-X1)},",
        f"\tRight = {lua_num(-X0)},",
        f"\tFront = {lua_num(Y0)},",
        f"\tBack = {lua_num(Y1)},",
        f"\tTop = {lua_num(Z_SHEET + RIB + SHEET / 2)}, -- the ribs' top face, up from the floor",
        "\t-- The cut-out panel's fall, in the hole's frame: from where it was cut, in the top, to",
        "\t-- where it lies on the floor (propped on the channel's stub, slid aside and turned).",
        "\t-- Panel and PanelEdge are drawn where it fell; `Fall:Inverse()` puts them in the hole.",
        f"\tFall = {fall_cframe(fall)},",
        "\tParts = {",
    ]
    for name in sorted(parts):
        p = parts[name]
        lines.append(f"\t\t{name} = {{ Size = {v3(p['size'])}, Centre = {v3(p['centre'])}, "
                     f"Triangles = {p['tris']} }} :: Piece,")
    lines += ["\t},", "}", ""]
    with open(path, "w") as f:
        f.write("\n".join(lines))
