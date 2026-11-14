"""Build the things in a unit that are only there to look at, in Blender, headless
(art/stuff/README.md).

    blender -b --factory-startup -P art/stuff/build.py -- --stage textures|export|renders

Stages:
    textures  the Stuff texture set (the mattress and the rolled carpet), baked into out/textures
    export    out/Stuff.fbx (two MeshParts) and src/shared/Stuff/Specs.luau (the pieces and the
              box stacks)
    renders   the look sheets, art/sheets/stuff-*.png (they need the boxes built)

It borrows the finds' atlas, bake and export (art/finds/build.py), pointed at its own spec and out
folder, as the coin does.
"""

import argparse
import importlib.util
import math
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
UNIT = os.path.join(HERE, "..", "unit")
FINDS = os.path.abspath(os.path.join(HERE, "..", "finds"))
sys.path.insert(0, UNIT)
sys.path.insert(0, HERE)  # first: this folder's spec.py

import bpy  # noqa: E402
import numpy as np  # noqa: E402
from mathutils import Vector  # noqa: E402

import bake  # noqa: E402
import render  # noqa: E402
import spec as K  # noqa: E402
from nodes import hexc  # noqa: E402

OUT = os.path.join(HERE, "out")
TEX = os.path.join(OUT, "textures")
SHEETS = os.path.join(K.ROOT, "art", "sheets")
FBX = os.path.join(OUT, f"{K.SET}.fbx")
SPECS = os.path.join(K.ROOT, "src", "shared", "Stuff", "Specs.luau")


def finds_kit():
    """The finds' build, as a library: it imports `spec`, which is already this folder's, so its
    atlas size, set name and dust are these; its out paths are pointed here."""
    s = importlib.util.spec_from_file_location("finds_build", os.path.join(FINDS, "build.py"))
    mod = importlib.util.module_from_spec(s)
    s.loader.exec_module(mod)
    assert mod.K is K, "the finds' build must see this folder's spec"
    mod.OUT, mod.TEX, mod.UVS, mod.FBX = OUT, TEX, os.path.join(OUT, "uvs.npz"), FBX
    return mod


kit = finds_kit()

# What a face is, for the recipes (a face attribute).
FACE, BORDER, EDGE, PILE, STEP, END, ROPE = range(7)


# --- the mattress ------------------------------------------------------------------------------

def section(d):
    """The mattress's cross-section at inset `d` (0 along its length, more towards its rounded
    ends), anticlockwise seen from above, from the front face's left end: its points (x, y) and
    the kind of the segment each one starts. Faces crowned, corners rounded."""
    M = K.MATTRESS
    a, b, c = M["w"] / 2, M["t"] / 2, M["corner"]
    n, cs = M["across"], M["corner_segs"]
    ax, by = a - c, b - c
    r = c - d
    crown = M["crown"] * (1.0 - d / c)
    pts, kinds = [], []

    def straight(x0, x1, side):
        for i in range(n):
            x = x0 + (x1 - x0) * i / n
            pts.append((x, side * (b - d + crown * (1.0 - (x / ax) ** 2))))
            kinds.append(FACE)

    def arc(cx, cy, start):
        for k in range(cs):
            t = math.radians(start + 90.0 * k / cs)
            pts.append((cx + r * math.cos(t), cy + r * math.sin(t)))
            kinds.append(EDGE)

    straight(-ax, ax, -1.0)
    arc(ax, -by, -90.0)
    pts.append((ax + r, -by))
    kinds.append(BORDER)
    arc(ax, by, 0.0)
    straight(ax, -ax, 1.0)
    arc(-ax, by, 90.0)
    pts.append((-ax - r, by))
    kinds.append(BORDER)
    arc(-ax, -by, 180.0)
    return pts, kinds


def mattress_rings():
    """(height, inset) of each ring, foot to head: a quarter round at each end, then evenly along."""
    M = K.MATTRESS
    c, L, n = M["corner"], M["long"], M["rings"]
    q = math.radians(45.0)
    foot = [(0.0, 0.85 * c), (c * (1 - math.sin(q)), c * (1 - math.cos(q)))]
    mid = [(c + (L - 2 * c) * k / (n - 1), 0.0) for k in range(n)]
    head = [(L - z, d) for z, d in reversed(foot)]
    return foot + mid + head


def mattress_mesh(m):
    rings = mattress_rings()
    idx = []
    for z, d in rings:
        pts, _ = section(d)
        idx.append([m.vert((x, y, z)) for x, y in pts])
    return idx


def mattress_geo():
    F = kit.Find("Mattress")
    rings = mattress_rings()
    _, kinds = section(0.0)
    held = {}
    F.add(FACE, lambda m: held.setdefault("idx", mattress_mesh(m)))
    idx = held["idx"]
    n = len(kinds)
    for j in range(len(rings) - 1):
        rounding = rings[j][1] > 0 or rings[j + 1][1] > 0
        for i in range(n):
            k = kinds[i]
            if rounding and k == FACE:
                k = EDGE  # the tape edge runs round the ends too
            a, b = idx[j], idx[j + 1]
            F.add(k, lambda m, a=a, b=b, i=i: m.face((a[i], a[(i + 1) % n], b[(i + 1) % n], b[i]),
                                                     None, True))
    F.add(BORDER, lambda m: m.face(tuple(reversed(idx[0])), None, True))
    F.add(BORDER, lambda m: m.face(tuple(idx[-1]), None, True))
    return F


def pose_mattress(ob):
    """Stand it as it is left: its middle sags back toward the wall, its top corners flop forward,
    it leans back until its top rests on the wall, and its foot squashes flat on the floor."""
    M = K.MATTRESS
    me = ob.data
    co = np.empty(len(me.vertices) * 3, dtype=np.float64)
    me.vertices.foreach_get("co", co)
    co = co.reshape(-1, 3)
    x, y, z = co[:, 0], co[:, 1].copy(), co[:, 2].copy()
    L, a = M["long"], M["w"] / 2
    y += M["sag"] * np.sin(np.pi * np.clip(z / L, 0.0, 1.0))
    y -= M["flop"] * np.clip(z / L, 0.0, 1.0) ** 3 * (x / a) ** 2
    t = math.radians(-M["lean"])
    y2 = y * math.cos(t) - z * math.sin(t)
    z2 = y * math.sin(t) + z * math.cos(t)
    co[:, 1], co[:, 2] = y2, np.maximum(z2, 0.0)
    me.vertices.foreach_set("co", co.ravel())
    me.update()


# --- the carpet --------------------------------------------------------------------------------

def roll_point(theta, r, x, pinch=0.0):
    """A point on the roll: `theta` round from the top toward the front, `r` out from its axis."""
    C = K.CARPET
    r -= pinch
    return (x, -r * math.sin(theta), C["r"] * C["flat"] + C["flat"] * r * math.cos(theta))


def roll_radius(theta):
    """The outer layer's radius at `theta`: one turn of a spiral, a rug's thickness from its free
    edge back round to just under it."""
    C = K.CARPET
    phi = (theta - math.radians(C["edge"])) % (2 * math.pi)
    return C["r"] - C["t"] + C["t"] * phi / (2 * math.pi)


def pose_carpet(ob):
    """Stand the roll on its end (its axis, X, turned up to Z; the side that faced the front still
    faces it), lean it back until its top rests on the wall, and set its foot flat on the floor."""
    C = K.CARPET
    me = ob.data
    co = np.empty(len(me.vertices) * 3, dtype=np.float64)
    me.vertices.foreach_get("co", co)
    co = co.reshape(-1, 3)
    x, y, z = co[:, 0].copy(), co[:, 1].copy(), co[:, 2] - C["r"] * C["flat"]
    up = x + C["long"] / 2
    t = math.radians(-C["lean"])
    co[:, 0] = -z
    co[:, 1] = y * math.cos(t) - up * math.sin(t)
    co[:, 2] = np.maximum(y * math.sin(t) + up * math.cos(t), 0.0)
    me.vertices.foreach_set("co", co.ravel())
    me.update()


def stations():
    """(x, pinch) of each ring along the roll: its ends, and three round each rope."""
    C = K.CARPET
    h, p = C["long"] / 2, C["pinch"]
    out = [(-h, 0.0)]
    for tx in C["ties"]:
        out += [(tx - 0.09, 0.35 * p), (tx, p), (tx + 0.09, 0.35 * p)]
    out.append((h, 0.0))
    return out


def carpet_geo():
    C = K.CARPET
    F = kit.Find("Carpet")
    segs, e = C["segs"], math.radians(C["edge"])
    st = stations()
    rings = []

    def verts(m):
        for x, p in st:
            ring = []
            for i in range(segs + 1):
                r = C["r"] - C["t"] + C["t"] * i / segs
                ring.append(m.vert(roll_point(e + 2 * math.pi * i / segs, r, x, p)))
            rings.append(ring)
        # the ends' middles, poked out a little where the rolled layers have crept
        for x, sgn in ((-C["long"] / 2, -1.0), (C["long"] / 2, 1.0)):
            rings.append([m.vert((x + sgn * 0.035, 0.0, C["r"] * C["flat"]))])

    F.add(PILE, verts)
    for j in range(len(st) - 1):
        a, b = rings[j], rings[j + 1]
        for i in range(segs):
            F.add(PILE, lambda m, a=a, b=b, i=i: m.face((a[i], a[i + 1], b[i + 1], b[i]), None, True))
        F.add(STEP, lambda m, a=a, b=b: m.face((a[segs], a[0], b[0], b[segs]), None, True))
    lo, hi = rings[0], rings[len(st) - 1]
    clo, chi = rings[-2][0], rings[-1][0]
    for i in range(segs):
        F.add(END, lambda m, i=i: m.face((clo, lo[i + 1], lo[i]), None, True))
        F.add(END, lambda m, i=i: m.face((chi, hi[i], hi[i + 1]), None, True))
    for tx in C["ties"]:
        F.add(ROPE, rope, tx)
        th = math.radians(-58.0)
        rc = roll_radius(th) - C["pinch"] + C["tie_r"] * 1.4
        F.add(ROPE, kit.ellipsoid, roll_point(th, rc, tx), (0.06, 0.05, 0.045), (0.0, 0.0), 8, 5)
    return F


def rope(m, tx):
    """A rope round the roll at `tx`, biting into it."""
    C = K.CARPET
    n, s, tr = C["tie_segs"], C["tie_sides"], C["tie_r"]
    rows = []
    for j in range(n):
        th = 2 * math.pi * j / n + 0.11
        rc = roll_radius(th) - C["pinch"] + tr * 0.55
        cx, cy, cz = roll_point(th, rc, tx)
        ry, rz = -math.sin(th), C["flat"] * math.cos(th)
        ln = math.hypot(ry, rz)
        ry, rz = ry / ln, rz / ln
        row = []
        for k in range(s):
            ps = 2 * math.pi * k / s
            row.append(m.vert((cx + tr * math.sin(ps), cy + tr * math.cos(ps) * ry,
                               cz + tr * math.cos(ps) * rz)))
        rows.append(row)
    for j in range(n):
        a, b = rows[j], rows[(j + 1) % n]
        for k in range(s):
            m.face((a[k], b[k], b[(k + 1) % s], a[(k + 1) % s]), None, True)


GEO = {"Mattress": mattress_geo, "Carpet": carpet_geo}
SHARP = {"Mattress": 70, "Carpet": 75}


def unwrap(objs, pad=6):
    """Smart-project both pieces together and pack their islands into the one atlas, turned as
    they fit best, so a big flat mattress and a long thin roll share it with no square wasted (the
    finds' way gives each piece a square, and the mattress's faces fill little of one)."""
    bpy.ops.object.select_all(action="DESELECT")
    for o in objs:
        o.select_set(True)
    bpy.context.view_layer.objects.active = objs[0]
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.select_all(action="SELECT")
    bpy.ops.uv.smart_project(angle_limit=math.radians(55), island_margin=pad / K.TEX,
                             area_weight=0.0, correct_aspect=True, scale_to_bounds=False)
    bpy.ops.uv.select_all(action="SELECT")
    bpy.ops.uv.pack_islands(rotate=True, rotate_method="ANY", scale=True, margin_method="FRACTION",
                            margin=pad / K.TEX, shape_method="CONCAVE")
    bpy.ops.object.mode_set(mode="OBJECT")
    clash = kit.clashes(objs)
    assert not clash, f"faces share texels in the atlas: {clash}"


def build_all(baking, coll=None):
    objs = {n: GEO[n]().build(SHARP[n], coll) for n in K.ORDER}
    kit.settle(list(objs.values()))
    if baking:
        unwrap(list(objs.values()))
        kit.keep_uvs(objs)
    else:
        kit.wear_uvs(objs)
        print(f"atlas: faces on unpainted texels {kit.unpainted(objs)}")
    print(f"atlas: {kit.density(list(objs.values())):.0f} texels a stud, "
          f"uv {kit.uv_hash(list(objs.values()))}")
    sizes = {}
    if not baking:
        pose_mattress(objs["Mattress"])
        pose_carpet(objs["Carpet"])
        for n, ob in objs.items():
            sizes[n] = kit.ground(ob)
    return objs, sizes


# --- the recipes -------------------------------------------------------------------------------

def mattress_look(nb):
    """Old quilted ticking: ivory cotton printed with a faint grey damask, quilted in diamonds
    with a tuft at every crossing, a plain rail inside the navy tape edge; a faded blue-grey border
    quilted in channels, with webbing handles and the law tag at the foot. Yellowed in the middle
    where it was slept on, a big tide-marked stain and a coffee spill on the side that faces the
    room, a split near the top corner showing old foam, grime where it stands on the concrete."""
    M = K.MATTRESS
    L = kit.Look(nb, M["seed"])
    x, y, z = L.x, L.y, L.z
    a, b, Lz, q, rail = M["w"] / 2, M["t"] / 2, M["long"], M["quilt"], M["rail"]
    face, border, edge = L.k(FACE), L.k(BORDER), L.k(EDGE)
    front = nb.ss(nb.mul(y, -1.0), 0.15, 0.35)
    s2 = math.sqrt(2.0)

    ivory = nb.tint(hexc("#DDD2BA"), nb.mr(L.noise(1.6, 1, detail=4), 0.3, 0.7, 0.8, 1.03))
    C = kit.Coat(L, ivory, 0.84)
    C.paint(nb.mul(face, nb.ss(L.noise(45.0, 2, detail=2), 0.4, 0.7)), rough=0.9, height=0.02)

    # the quilting: two families of stitch lines at 45 degrees, pillowed between, tufted where
    # they cross, inside a plain rail round the face
    pa = nb.sub(nb.fract(nb.div(nb.add(x, z), q)), 0.5)
    pb = nb.sub(nb.fract(nb.div(nb.sub(x, z), q)), 0.5)
    da = nb.mul(nb.sub(0.5, nb.absf(pa)), q / s2)
    db = nb.mul(nb.sub(0.5, nb.absf(pb)), q / s2)
    dl = nb.mn(da, db)
    inner = nb.mul(nb.band(x, -a + rail, a - rail, 0.012), nb.band(z, rail, Lz - rail, 0.012))
    quilted = nb.mul(face, inner)
    # a smooth dome in each diamond (the nearer line's distance alone creased it along the
    # diagonals, and every diamond read as a pyramid in Studio)
    dome = nb.mul(nb.sub(1.0, nb.mul(nb.mul(pa, pa), 4.0)), nb.sub(1.0, nb.mul(nb.mul(pb, pb), 4.0)))
    pillow = nb.pw(nb.clamp(dome), 0.5)
    stitch = nb.ss(dl, 0.016, 0.005)
    tuft = nb.ss(L.dist(da, db), 0.06, 0.018)
    C.paint(quilted, height=nb.sub(nb.mul(pillow, 0.75), nb.add(nb.mul(stitch, 0.35),
                                                                nb.mul(tuft, 0.7))))
    C.paint(nb.mul(quilted, nb.mul(nb.inv(pillow), 0.3)), hexc("#A39780"))  # shade in the folds
    C.paint(nb.mul(quilted, nb.mul(stitch, 0.4)), hexc("#ABA08A"))
    C.paint(nb.mul(quilted, nb.mul(tuft, 0.6)), hexc("#A39A8A"), 0.7)
    # the damask: a faint four-petalled flower in every diamond
    rho = L.dist(pa, pb)
    petals = nb.mul(nb.band(rho, 0.15, 0.3, 0.02),
                    nb.ss(nb.cos(nb.mul(nb.math("ARCTAN2", pb, pa), 4.0)), 0.1, 0.5))
    dot = nb.ss(rho, 0.07, 0.05)
    C.paint(nb.mul(quilted, nb.mul(nb.add(petals, dot, clamp=True), 0.3)), hexc("#9EA8AE"))
    # the rail: plain, a little proud, with one straight stitch line round it
    rail_m = nb.mul(face, nb.inv(inner))
    C.paint(rail_m, height=0.45)
    line = nb.mul(face, nb.band(inner, 0.35, 0.65, 0.12))
    C.paint(line, hexc("#B5AA94"), height=-0.3)

    # yellowed where it was slept on
    sleep = nb.mul(nb.ss(L.noise(0.55, 5, detail=3), 0.42, 0.62),
                   nb.ss(nb.absf(nb.sub(z, Lz * 0.5)), Lz * 0.45, Lz * 0.12))
    C.paint(nb.mul(nb.add(face, edge, clamp=True), nb.mul(sleep, 0.65)), hexc("#CDB47C"))

    # the big stain, with its tide mark, and a coffee spill, on the side facing the room
    f1 = nb.add(L.dist(nb.div(nb.sub(x, 0.75), 1.0), nb.div(nb.sub(z, 3.3), 1.3)),
                nb.mul(nb.sub(L.noise(1.3, 9, detail=4), 0.5), 0.9))
    on = nb.mul(front, nb.add(face, edge, clamp=True))
    blotch = nb.mr(L.noise(3.0, 10, detail=4), 0.3, 0.7, 0.15, 0.6)
    C.paint(nb.mul(on, nb.mul(nb.ss(f1, 1.0, 0.8), blotch)), hexc("#C2A062"))
    C.paint(nb.mul(on, nb.mul(nb.band(f1, 0.62, 0.68, 0.04), 0.22)), hexc("#A88449"))
    rim = nb.mr(L.noise(4.0, 12, detail=3), 0.3, 0.7, 0.2, 0.75)
    C.paint(nb.mul(on, nb.mul(nb.band(f1, 0.94, 1.0, 0.03), rim)), hexc("#8A6634"))
    f2 = nb.add(L.dist(nb.div(nb.add(x, 1.55), 0.42), nb.div(nb.sub(z, 5.75), 0.6)),
                nb.mul(nb.sub(L.noise(3.0, 11, detail=3), 0.5), 0.7))
    C.paint(nb.mul(on, nb.mul(nb.ss(f2, 1.0, 0.7), 0.3)), hexc("#8A5F35"))
    C.paint(nb.mul(on, nb.mul(nb.band(f2, 0.9, 1.0, 0.04), 0.25)), hexc("#6A4626"))
    spots = nb.mul(on, nb.ss(L.noise(8.0, 13, detail=2), 0.72, 0.78))
    C.paint(nb.mul(spots, 0.45), hexc("#9A7C52"))

    # the border: faded blue-grey, quilted in channels along its length
    ch = nb.absf(nb.sin(nb.mul(y, math.pi / 0.21)))
    blue = nb.tint(hexc("#7F8C99"), nb.mr(L.noise(3.0, 14, detail=3), 0.3, 0.7, 0.88, 1.05))
    C.paint(border, blue, 0.88, height=nb.mul(ch, 0.5))
    C.paint(nb.mul(border, nb.ss(ch, 0.14, 0.0)), hexc("#56606B"))
    # handles: grey webbing straps on each side
    side = nb.mul(border, nb.ss(nb.absf(x), a - 0.06, a - 0.02))
    straps = nb.add(nb.band(z, Lz * 0.33 - 0.3, Lz * 0.33 + 0.3, 0.01),
                    nb.band(z, Lz * 0.67 - 0.3, Lz * 0.67 + 0.3, 0.01), clamp=True)
    strap = nb.mul(nb.mul(side, straps), nb.ss(nb.absf(y), 0.095, 0.085))
    C.paint(strap, hexc("#4D5560"), 0.8, height=0.7)
    ends = nb.add(nb.band(nb.absf(nb.sub(z, Lz * 0.33)), 0.25, 0.28, 0.006),
                  nb.band(nb.absf(nb.sub(z, Lz * 0.67)), 0.25, 0.28, 0.006), clamp=True)
    C.paint(nb.mul(strap, ends), hexc("#2E333A"), height=-0.4)
    # the law tag, sewn into the seam at the foot of the right-hand side
    tag = nb.mul(nb.mul(border, nb.ss(x, a - 0.06, a - 0.02)),
                 nb.mul(nb.band(z, 0.32, 0.86, 0.006), nb.band(y, -0.24, 0.12, 0.006)))
    C.paint(tag, hexc("#E8E3D6"), 0.7, height=0.3)
    rows = nb.mul(nb.band(nb.fract(nb.div(z, 0.07)), 0.32, 0.62, 0.05),
                  nb.mul(nb.ss(L.noise(26.0, 17, detail=1), 0.36, 0.5), nb.band(y, -0.19, 0.08, 0.01)))
    C.paint(nb.mul(tag, nb.mul(rows, nb.band(z, 0.38, 0.78, 0.01))), hexc("#7E7A72"))

    # the tape edge: navy woven tape, worn pale on the corners
    tape = nb.tint(hexc("#7D838C"), nb.mr(L.noise(60.0, 18, stretch=(1.0, 1.0, 0.2), detail=1),
                                          0.3, 0.7, 0.85, 1.12))
    C.paint(edge, tape, 0.74)
    C.paint(nb.mul(edge, nb.mul(nb.ss(L.noise(4.0, 19, detail=3), 0.6, 0.76), 0.6)),
            hexc("#A7AAAD"))

    # the split near the top corner, old yellow foam showing, its torn lip frayed and pale
    ang = math.radians(32.0)
    ux = nb.add(nb.mul(nb.sub(x, 1.82), math.cos(ang)), nb.mul(nb.sub(z, 6.55), math.sin(ang)))
    uz = nb.sub(nb.mul(nb.sub(z, 6.55), math.cos(ang)), nb.mul(nb.sub(x, 1.82), math.sin(ang)))
    tear = nb.add(nb.add(nb.pw(nb.div(nb.absf(ux), 0.26), 2.0), nb.pw(nb.div(nb.absf(uz), 0.06), 2.0)),
                  nb.mul(nb.sub(L.noise(14.0, 20, detail=2), 0.5), 0.6))
    tf = nb.mul(front, face)
    hole = nb.mul(tf, nb.ss(tear, 1.0, 0.86))
    pores = nb.ss(nb.voronoi(L.vec(), 70.0), 0.0, 0.35)
    C.paint(hole, nb.tint(hexc("#B99D5E"), nb.mr(pores, 0.0, 1.0, 0.6, 1.0)), 0.95,
            height=nb.sub(nb.mul(pores, 0.15), 1.1))
    C.paint(nb.mul(tf, nb.band(tear, 0.72, 1.0, 0.06)), hexc("#3E3220"))  # the cut's shadow
    lip = nb.mul(tf, nb.band(tear, 1.0, 1.6, 0.12))
    C.paint(nb.mul(lip, 0.7), hexc("#EFE7D2"), height=0.35)

    # grime where it stands on the floor, climbing a little way
    dirt = nb.mul(nb.ss(z, 0.95, 0.0), nb.mr(L.noise(3.5, 15, detail=4), 0.3, 0.7, 0.45, 1.0))
    C.paint(nb.mul(dirt, 0.8), hexc("#5E5345"), 0.95)

    C.finish(ao=0.14, ao_low=0.62, dust=K.DUST)
    return C.channels(dist=0.04, strength=0.8)


def carpet_look(nb):
    """An old wool rug, hand-knotted: a madder-red field of navy and ivory diamonds outlined in
    gold, small green crosses between, borders of red and navy triangles between guard stripes;
    the red dyed in faint bands, threadbare in patches, dusty along the top. Rolled pattern out,
    so its last end lies on the outside, the fringe flopped over the roll; the ends show the
    layers wound round a dark hole; two lengths of sisal rope tie it."""
    C_ = K.CARPET
    L = kit.Look(nb, C_["seed"])
    x, y, z = L.x, L.y, L.z
    R, t, flat, m = C_["r"], C_["t"], C_["flat"], C_["motif"]
    half, bd = C_["long"] / 2, C_["border"]
    zc = R * flat
    pile, step, end, rope = L.k(PILE), L.k(STEP), L.k(END), L.k(ROPE)
    zz = nb.div(nb.sub(z, zc), flat)
    th = nb.math("ARCTAN2", nb.mul(y, -1.0), zz)
    rho = L.dist(y, zz)
    phi = nb.fract(nb.div(nb.sub(th, math.radians(C_["edge"])), 2 * math.pi))
    s = nb.mul(nb.sub(1.0, phi), 2 * math.pi * R)   # along the rug, back from its free end
    fs = nb.mul(phi, 2 * math.pi * R)               # past the end, where the fringe lies
    v = x

    red = nb.tint(hexc("#7C2922"), nb.mr(L.noise(2.2, 1, stretch=(0.15, 1.0, 1.0), detail=3),
                                         0.3, 0.7, 0.86, 1.1))   # abrash: the dye lots in bands
    navy, ivory, gold = hexc("#1E2A44"), hexc("#D6C6A0"), hexc("#B5853A")
    C = kit.Coat(L, red, 0.92)

    # the field: diamonds on a lattice
    du = nb.absf(nb.sub(nb.fract(nb.div(s, m)), 0.5))
    dv = nb.absf(nb.sub(nb.fract(nb.add(nb.div(v, m), 0.5)), 0.5))
    dm = nb.mul(nb.add(du, dv), 2.0)        # 0 at a diamond's middle, 1 at its points
    C.paint(nb.ss(dm, 0.7, 0.66), navy)
    C.paint(nb.band(dm, 0.7, 0.78, 0.02), gold)
    C.paint(nb.ss(dm, 0.46, 0.42), ivory)
    C.paint(nb.ss(dm, 0.3, 0.26), red)
    C.paint(nb.ss(dm, 0.13, 0.1), navy)
    cross = nb.mul(nb.ss(dm, 1.62, 1.66),
                   nb.ss(nb.mn(nb.absf(nb.sub(du, 0.5)), nb.absf(nb.sub(dv, 0.5))), 0.035, 0.02))
    C.paint(cross, hexc("#3F5B45"))

    # the borders: along both long edges (the roll's ends) and across its last end
    w_side = nb.div(nb.sub(nb.absf(v), half - bd), bd)     # 0 at the band's inner edge, 1 outer
    w_end = nb.sub(1.0, nb.div(s, bd))
    in_end = nb.ss(s, bd + 0.01, bd - 0.01)
    in_side = nb.mul(nb.ss(w_side, -0.02, 0.02), nb.inv(in_end))

    def band(wv, along, mask):
        C.paint(mask, ivory)
        guard = nb.add(nb.band(wv, 0.0, 0.08, 0.01), nb.band(wv, 0.92, 1.0, 0.01), clamp=True)
        main = nb.band(wv, 0.17, 0.83, 0.01)
        zig = nb.mr(nb.absf(nb.sub(nb.fract(nb.div(along, 0.34)), 0.5)), 0.0, 0.5, 0.17, 0.83)
        upper = nb.ss(nb.sub(wv, zig), -0.015, 0.015)
        C.paint(nb.mul(mask, guard), navy)
        C.paint(nb.mul(mask, nb.mul(main, upper)), navy)
        C.paint(nb.mul(mask, nb.mul(main, nb.inv(upper))), red)
        C.paint(nb.mul(mask, nb.mul(main, nb.band(nb.sub(wv, zig), -0.03, 0.03, 0.01))), ivory)
    band(w_side, s, in_side)
    band(w_end, v, in_end)

    # worn: the knots rubbed down to the pale warp and weft in patches, and the pile's fine grain
    bare = nb.mul(pile, nb.ss(L.noise(1.6, 21, detail=5), 0.6, 0.71))
    C.paint(nb.mul(bare, 0.7), hexc("#B5A27F"), 0.95, height=-0.3)
    C.paint(pile, nb.tint(C.col, nb.mr(L.noise(42.0, 25, detail=2), 0.3, 0.7, 0.88, 1.08)),
            height=nb.mul(L.noise(70.0, 23, detail=1), 0.25))
    # the selvedges and the cut end, bound in dark wool
    C.paint(nb.mul(pile, nb.ss(nb.absf(v), half - 0.045, half - 0.03)), hexc("#3A1E1A"))
    C.paint(nb.mul(pile, nb.ss(s, 0.035, 0.02)), hexc("#3A1E1A"))

    # the fringe, lying over the roll past the end: bundles of cotton warp, ragged at the tips
    tip = nb.mul(C_["fringe"], nb.mr(L.noise(9.0, 27, stretch=(1.0, 0.0, 0.0), detail=2),
                                     0.3, 0.7, 0.72, 1.05))
    jitter = nb.mul(nb.sub(L.noise(14.0, 35, stretch=(1.0, 0.3, 0.3), detail=2), 0.5), 0.05)
    strands = nb.absf(nb.sin(nb.mul(nb.add(nb.add(v, jitter), nb.mul(nb.sin(nb.mul(fs, 18.0)), 0.012)),
                                    math.pi / 0.085)))
    lying = nb.mul(nb.mul(pile, nb.mr(fs, nb.sub(tip, 0.03), tip, 1.0, 0.0, "SMOOTHSTEP")),
                   nb.band(v, -half + 0.05, half - 0.05, 0.01))
    lying = nb.mul(lying, nb.ss(fs, 0.0, 0.004))
    fringe = nb.mul(lying, nb.ss(strands, 0.25, 0.55))
    C.paint(nb.mul(lying, 0.35), hexc("#2A1512"))            # shadow between the bundles
    cotton = nb.mixc(nb.mr(fs, 0.05, tip, 0.0, 1.0, "SMOOTHSTEP"), hexc("#D3C9B0"), hexc("#958A72"))
    cotton = nb.tint(cotton, nb.mr(L.noise(30.0, 37, stretch=(1.0, 0.0, 0.0), detail=1),
                                   0.3, 0.7, 0.72, 1.05))   # each bundle a little different
    C.paint(fringe, cotton, 0.9, height=nb.mul(strands, 0.6))
    knots = nb.mul(lying, nb.ss(fs, 0.06, 0.03))
    C.paint(nb.mul(knots, 0.8), hexc("#C9BC9B"), height=0.5)
    # the cut end's face: the binding, the warp running out of it into the fringe
    C.paint(step, hexc("#3A1E1A"), 0.9)
    C.paint(nb.mul(step, nb.ss(strands, 0.3, 0.6)), hexc("#CFC4A9"))

    # the ends: the layers wound round, pile and backing, a dark hole down the middle
    lay = nb.div(nb.sub(nb.add(R - t, nb.mul(phi, t)), rho), t)
    lf = nb.fract(lay)
    knot_col = nb.mixc(nb.ss(L.noise(6.0, 29, detail=2), 0.42, 0.58), hexc("#74251F"), navy)
    knot_col = nb.mixc(nb.ss(L.noise(11.0, 31, detail=2), 0.66, 0.72), knot_col, ivory)
    C.paint(end, knot_col, 0.95, height=0.3)
    backing = nb.mul(end, nb.ss(lf, 0.62, 0.7))
    C.paint(backing, hexc("#B9A57F"), height=-0.2)
    C.paint(nb.mul(end, nb.ss(lf, 0.9, 0.98)), hexc("#241512"), height=-0.6)
    core = nb.mul(end, nb.ss(rho, C_["core"] + 0.01, C_["core"] - 0.01))
    C.paint(core, hexc("#0D0907"), 1.0, height=-1.0)

    # the rope: three-strand sisal, hairy, its grooves dark
    xt = nb.mixf(nb.ss(x, -0.1, 0.1), C_["ties"][0], C_["ties"][1])
    psi = nb.math("ARCTAN2", nb.sub(x, xt), nb.sub(rho, R - C_["pinch"]))
    tw = nb.fract(nb.add(nb.mul(th, R / 0.13), nb.mul(psi, 3.0 / (2 * math.pi))))
    groove = nb.ss(nb.absf(nb.sub(tw, 0.5)), 0.36, 0.5)
    sisal = nb.tint(hexc("#A3814F"), nb.mr(L.noise(30.0, 33, detail=3), 0.3, 0.7, 0.8, 1.1))
    C.paint(rope, sisal, 0.95, height=nb.mul(nb.inv(groove), 0.5))
    C.paint(nb.mul(rope, nb.mul(groove, 0.7)), hexc("#4F3C22"))

    C.finish(ao=0.12, ao_low=0.55, dust=K.DUST)
    return C.channels(dist=0.008, strength=0.7)


LOOK = {"Mattress": mattress_look, "Carpet": carpet_look}


def stage_textures():
    kit.reset()
    objs, _ = build_all(baking=True)
    for i, ob in enumerate(objs.values()):
        ob.location.x = i * 10.0  # apart, so neither shades the other in the bake
    kit.bake_set([(ob, bake.Rig(f"bk_{name}", LOOK[name])) for name, ob in objs.items()], samples=32)


# --- export ---------------------------------------------------------------------------------

def stage_export():
    kit.reset()
    objs, sizes = build_all(baking=False)
    mat = kit.material()
    rows = {}
    for i, (name, ob) in enumerate(objs.items()):
        ob.data.materials.append(mat)
        ob.location.x = i * 8.0
        s = sizes[name]
        rows[name] = dict(size=(s.x, s.z, s.y), tris=kit.tris(ob))
    os.makedirs(OUT, exist_ok=True)
    bpy.ops.object.select_all(action="DESELECT")
    for ob in objs.values():
        ob.select_set(True)
    bpy.context.view_layer.objects.active = objs[K.ORDER[0]]
    bpy.ops.export_scene.fbx(
        filepath=FBX, use_selection=True, object_types={"MESH"},
        apply_scale_options="FBX_SCALE_UNITS", axis_forward="Z", axis_up="Y",
        use_mesh_modifiers=True, mesh_smooth_type="OFF", use_tspace=False,
        add_leaf_bones=False, bake_anim=False, path_mode="COPY", embed_textures=True)
    print("FBX", FBX, {n: (r["tris"], tuple(round(v, 2) for v in r["size"])) for n, r in rows.items()})
    os.makedirs(os.path.dirname(SPECS), exist_ok=True)
    K.write_luau(SPECS, rows)


# --- look sheets ----------------------------------------------------------------------------

def put(ob, x, y, z=0.0, turn=0.0):
    ob.location = (x, y, z)
    ob.rotation_euler = (0.0, 0.0, math.radians(turn))
    return ob


def lay_stack(bk, boxes, name, at, turn=0.0):
    """A stack as the game lays it: Roblox's (x, y, z) from the stack's middle is Blender's
    (-x, z, y), and a turn about Roblox's Y is the same turn about Blender's Z."""
    made, _ = K.stacks()[name]
    a = math.radians(turn)
    for box, (px, py, pz), bt in made:
        bx, by = -px, pz
        wx = at[0] + bx * math.cos(a) - by * math.sin(a)
        wy = at[1] + bx * math.sin(a) + by * math.cos(a)
        bk.place(boxes, box, wx, wy, py, bt + turn, copy=True)


def unit_scene(bk):
    """An M unit's inside from the boxes' sheets, lit by its bulb and a little of the hall."""
    render.world((0.002, 0.0025, 0.004), 1.0)
    bk.unit_room(bpy.context.scene.collection)
    bulb = bpy.data.lights.new("bulb", "POINT")
    bulb.energy, bulb.color, bulb.shadow_soft_size = 220.0, (1.0, 0.674, 0.408), 0.08
    bo = bpy.data.objects.new("bulb", bulb)
    bpy.context.scene.collection.objects.link(bo)
    bo.location = (0.0, 6.0, 8.7)
    bk.light("hall", "AREA", (0.0, -3.0, 9.0), (0.0, 3.0, 0.0), 60.0, (0.85, 0.92, 1.0), size=6.0)


def stage_renders():
    kit.reset()
    render.setup(96, (1600, 900))
    objs, sizes = build_all(baking=False)
    mat = kit.material()
    for ob in objs.values():
        ob.data.materials.append(mat)
    os.makedirs(SHEETS, exist_ok=True)
    bk = kit.boxes_kit()
    bmat = bk.material(False)
    boxes, _, _ = bk.build_all(baking=False)
    for b in boxes.values():
        b.data.materials.append(bmat)
        b.location.z = -50.0  # the originals stay out of shot; the stacks are copies
    unit_scene(bk)
    mat_d = sizes["Mattress"].y
    car_d = sizes["Carpet"].y
    # 14.6 mm is Roblox's 70 degree view on a 16:9 screen; the eye at standing height
    door = render.camera((0.6, -1.5, 4.6), (0.0, 9.0, 2.2), lens=14.6)

    # 1. the mattress against the left wall, the door going up on it; then close on its face
    put(objs["Mattress"], -6.0 + mat_d / 2, 7.4, 0.0, 90.0)
    put(objs["Carpet"], 0.0, -40.0)
    render.shoot(door, os.path.join(SHEETS, "stuff-mattress.png"), exposure=0.2)
    near = render.camera((-1.2, 3.6, 4.6), (-5.2, 7.6, 3.8), lens=30)
    render.shoot(near, os.path.join(SHEETS, "stuff-mattress-near.png"), exposure=0.2)

    # 2. the carpet stood in the back corner, from the doorway, then close on its top and fringe
    put(objs["Mattress"], 0.0, -40.0)
    put(objs["Carpet"], 3.6, 12.0 - car_d / 2, 0.0, 0.0)
    render.shoot(door, os.path.join(SHEETS, "stuff-carpet.png"), exposure=0.2)
    near = render.camera((1.0, 7.2, 6.4), (3.5, 11.2, 4.6), lens=30)
    render.shoot(near, os.path.join(SHEETS, "stuff-carpet-near.png"), exposure=0.2)

    # 3. the stacks, two to a unit
    put(objs["Carpet"], 0.0, -40.0)
    lay_stack(bk, boxes, "Tower", (-3.6, 12.0 - K.stacks()["Tower"][1][2] / 2))
    lay_stack(bk, boxes, "Wall", (1.9, 12.0 - K.stacks()["Wall"][1][2] / 2))
    render.shoot(door, os.path.join(SHEETS, "stuff-stacks-a.png"), exposure=0.2)
    for o in list(bpy.context.scene.objects):
        if o.type == "MESH" and "." in o.name and o.name.split(".")[0] in boxes:
            bpy.data.objects.remove(o)
    lay_stack(bk, boxes, "Heap", (-2.9, 12.0 - K.stacks()["Heap"][1][2] / 2))
    lay_stack(bk, boxes, "Column", (3.2, 12.0 - K.stacks()["Column"][1][2] / 2))
    render.shoot(door, os.path.join(SHEETS, "stuff-stacks-b.png"), exposure=0.2)


STAGES = {"textures": stage_textures, "export": stage_export, "renders": stage_renders}

if __name__ == "__main__":
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    ap = argparse.ArgumentParser()
    ap.add_argument("--stage", choices=list(STAGES), required=True)
    STAGES[ap.parse_args(argv).stage]()
    print("DONE")
