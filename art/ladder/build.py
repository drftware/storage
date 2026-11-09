"""Build the ladder in Blender, headless (art/ladder/README.md).

    blender -b --factory-startup -P art/ladder/build.py -- --stage textures|export|renders

Stages:
    textures  the Ladder texture set (both sections), baked from its recipe into out/textures
    export    out/Ladder.fbx (two MeshParts: Ladder, the base, and LadderFly) and
              src/shared/Tools/Specs/Ladder.luau
    renders   the look sheets, art/sheets/ladder-*.png

It borrows the finds' atlas, bake and export (art/finds/build.py), pointed at its own spec and out
folder, as the saw does.
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

import bmesh  # noqa: E402
import bpy  # noqa: E402
from mathutils import Matrix, Vector  # noqa: E402

import bake  # noqa: E402
import geo  # noqa: E402
import render  # noqa: E402
import spec as K  # noqa: E402
from nodes import hexc  # noqa: E402

OUT = os.path.join(HERE, "out")
TEX = os.path.join(OUT, "textures")
SHEETS = os.path.join(K.ROOT, "art", "sheets")
FBX = os.path.join(OUT, f"{K.SET}.fbx")
SPECS = os.path.join(K.ROOT, "src", "shared", "Tools", "Specs", "Ladder.luau")


def finds_kit():
    """The finds' build, as a library: it imports `spec`, which is already this folder's, so its
    atlas size, set name and dust are the ladder's; its out paths are pointed here."""
    s = importlib.util.spec_from_file_location("finds_build", os.path.join(FINDS, "build.py"))
    mod = importlib.util.module_from_spec(s)
    s.loader.exec_module(mod)
    assert mod.K is K, "the finds' build must see the ladder's spec"
    mod.OUT, mod.TEX, mod.UVS, mod.FBX = OUT, TEX, os.path.join(OUT, "uvs.npz"), FBX
    return mod


kit = finds_kit()

# What a face is, for the recipe (a face attribute).
RAIL, RUNG, FOOT, PAD, GUIDE, LOCK, CAP, ROPE, PULLEY, BOLT = range(10)

R = K.RAIL


# --- geometry --------------------------------------------------------------------------------

def g(u, x, d):
    """A drawing point (u along from the feet, x across, d through from the base's back) in the
    ladder's frame (studs from the grip)."""
    return Vector(K.at(u, x, d))


def bx(m, u, x, d, bevel=0.004):
    """A box spanning the drawing's (u0, u1), (x0, x1), (d0, d1)."""
    a, b = g(u[0], x[0], d[0]), g(u[1], x[1], d[1])
    lo = Vector([min(a[i], b[i]) for i in range(3)])
    hi = Vector([max(a[i], b[i]) for i in range(3)])
    geo.box(m, lo, hi, bevel=bevel)


def loft(m, sections):
    """A closed shape through rings of points (all the same count), capped at both ends; a bmesh
    so its faces are turned to look outwards, in a fixed order so every stage numbers it alike."""
    bm = bmesh.new()
    rings = [[bm.verts.new(p) for p in sec] for sec in sections]
    n = len(sections[0])
    for a, b in zip(rings, rings[1:]):
        for i in range(n):
            j = (i + 1) % n
            bm.faces.new((a[i], a[j], b[j], b[i]))
    bm.faces.new(rings[0])
    bm.faces.new(list(reversed(rings[-1])))
    kit.solid(m, bm)


def tube(m, pts, r, n=8):
    """A round tube through 3D points (a rope)."""
    secs = []
    up0 = Vector((1.0, 0.0, 0.0))
    for i, p in enumerate(pts):
        t = (pts[min(i + 1, len(pts) - 1)] - pts[max(i - 1, 0)]).normalized()
        a = up0 - t * up0.dot(t)
        if a.length < 1e-4:
            a = Vector((0.0, 0.0, 1.0)) - t * t.z
        a.normalize()
        b = t.cross(a)
        secs.append([p + r * (math.cos(2 * math.pi * k / n) * a + math.sin(2 * math.pi * k / n) * b)
                     for k in range(n)])
    loft(m, secs)


CHUNK = 1.6   # studs: long rails and rope are cut into pieces this long, so their UV islands
              # pack tightly into the atlas (one 6-stud island starves the whole set of texels)


def rail(m, x_in, side, u, d0):
    """One rail: a channel open to the outside, its web on the inside at x_in (side: +1 the right
    rail, -1 the left), from u[0] to u[1], its back at d0; built in short lengths end to end."""
    def xs(a, b):
        return (side * (x_in + a), side * (x_in + b))
    n = math.ceil((u[1] - u[0]) / CHUNK)
    for k in range(n):
        uu = (u[0] + (u[1] - u[0]) * k / n, u[0] + (u[1] - u[0]) * (k + 1) / n)
        bx(m, uu, xs(0.0, R["web"]), (d0, d0 + R["depth"]), 0.0)
        bx(m, uu, xs(0.0, R["width"]), (d0, d0 + R["flange"]), 0.0)
        bx(m, uu, xs(0.0, R["width"]), (d0 + R["depth"] - R["flange"], d0 + R["depth"]), 0.0)


def rung(m, u, x_in, d):
    """A D-shaped rung across between the webs at x_in, its middle at (u, d), flat on its +u side."""
    r, n = K.RUNG_R, 18
    pts = []
    for k in range(n):
        a = 2 * math.pi * k / n
        cu, cd = r * math.cos(a), r * math.sin(a)
        pts.append((min(cu, K.RUNG_FLAT * r), cd))
    secs = [[g(u + cu, x, d + cd) for cu, cd in pts] for x in (-x_in - 0.01, x_in + 0.01)]
    loft(m, secs)


def flares(m, u, x_in, d):
    """The rung's flared ends, pressed over each web's outside."""
    for side in (1, -1):
        x = side * (x_in + R["web"] + K.FLARE["t"] / 2)
        geo.cylinder(m, "x", g(u, x, d), K.FLARE["r"], K.FLARE["t"], segs=14, bevel=0.004)


def section_rungs(m, rungs, from_u, x_in, d):
    for u in rungs:
        rung(m, from_u + u, x_in, d)


def section_flares(m, rungs, from_u, x_in, d):
    for u in rungs:
        flares(m, from_u + u, x_in, d)


def shoes(m):
    """A swivel shoe at each of the base's feet: side plates either side of the channel."""
    S = K.SHOE
    for side in (1, -1):
        x0, x1 = K.BASE_IN, K.BASE_IN + R["width"]
        bx(m, S["u"], (side * (x0 - S["plate"]), side * x0), (-0.01, R["depth"] + 0.01), 0.008)
        bx(m, S["u"], (side * x1, side * (x1 + S["plate"])), (-0.01, R["depth"] + 0.01), 0.008)


def pads(m):
    """The rubber pads under the shoes."""
    S = K.SHOE
    for side in (1, -1):
        x0, x1 = K.BASE_IN - S["plate"], K.BASE_IN + R["width"] + S["plate"]
        bx(m, S["pad"], (side * x0, side * x1), (-0.03, R["depth"] + 0.03), 0.02)


def shoe_bolts(m):
    S = K.SHOE
    for side in (1, -1):
        x = side * (K.BASE_IN + R["width"] + S["plate"])
        geo.hexbolt(m, g(S["bolt"], x, R["depth"] / 2), "x", side, 0.07, 0.03)
        x = side * (K.BASE_IN - S["plate"])
        geo.hexbolt(m, g(S["bolt"], x, R["depth"] / 2), "x", -side, 0.07, 0.03)


def base_guides(m):
    """The strap round the base's top that the fly runs in: up the outside, over the fly's rail,
    a lip down inside it."""
    u, t = K.BASE_GUIDE, K.GUIDE_T
    top = K.FLY_D + R["depth"]
    out = K.BASE_IN + R["width"]
    for side in (1, -1):
        bx(m, u, (side * out, side * (out + t)), (-0.012, top + t))
        bx(m, u, (side * (K.FLY_IN - 0.03), side * (out + t)), (top, top + t))
        bx(m, u, (side * (K.FLY_IN - 0.03), side * (K.FLY_IN - 0.03 + t)), (top - 0.09, top + t))
        bx(m, u, (side * (K.BASE_IN - 0.01), side * (out + t)), (-0.012 - t, -0.012))


def guide_rivets(m):
    u = sum(K.BASE_GUIDE) / 2
    out = K.BASE_IN + R["width"] + K.GUIDE_T
    for side in (1, -1):
        for d in (0.08, 0.22):
            geo.cylinder(m, "x", g(u, side * (out + 0.006), d), 0.022, 0.012, segs=8)


def fly_guides(m):
    """The fly's foot: a strap round the base's rail from behind, so the two sections stay
    together as the fly runs."""
    u = (K.FLY_FROM + K.FLY_GUIDE[0], K.FLY_FROM + K.FLY_GUIDE[1])
    t = K.GUIDE_T
    out = K.BASE_IN + R["width"] + 0.004
    for side in (1, -1):
        bx(m, u, (side * out, side * (out + t)), (-0.016 - t, K.FLY_D + 0.12))
        bx(m, u, (side * (K.BASE_IN - 0.012), side * (out + t)), (-0.016 - t, -0.016))
        bx(m, u, (side * (K.FLY_IN + R["width"]), side * (out + t)), (K.FLY_D + 0.09, K.FLY_D + 0.12))


def locks(m):
    """The rung locks: a cast housing inside each of the fly's rails at its foot."""
    lu = K.FLY_FROM + K.LOCK_U
    for side in (1, -1):
        bx(m, (lu + 0.06, lu + 0.36), (side * K.LOCK_X[0], side * K.LOCK_X[1]),
           (K.FLY_D + 0.02, K.FLY_D + 0.2), 0.012)


def hooks(m):
    """Each lock's hook, dropping from its housing over the base rung below."""
    lu = K.FLY_FROM + K.LOCK_U   # the base rung it catches
    rd = R["depth"] / 2
    x = (K.LOCK_X[0] + K.LOCK_X[1]) / 2
    path = [(lu + 0.16, K.FLY_D + 0.06), (lu + 0.12, rd + 0.12), (lu + 0.09, rd + 0.05),
            (lu + 0.085, rd - 0.03), (lu + 0.05, rd - 0.09)]
    for side in (1, -1):
        tube(m, [g(u, side * x, d) for u, d in path], 0.026, 8)


def caps(m):
    """Black caps over the fly's rails' top ends."""
    u1 = K.FLY_FROM + K.FLY_LEN
    for side in (1, -1):
        bx(m, (u1 - K.CAP, u1 + 0.03),
           (side * (K.FLY_IN - 0.012), side * (K.FLY_IN + R["width"] + 0.014)),
           (K.FLY_D - 0.014, K.FLY_D + R["depth"] + 0.014), 0.025)


# The rope's runs (u, d) at ROPE_X: the front run from a knot on the base's bottom rung, between
# the base's rungs and the fly's; the back run behind the base's rungs; the wheel between them.
FRONT_D = (R["depth"] + K.FLY_D) / 2 + 0.0
BACK_D = 0.02


def rope_path():
    P = K.PULLEY
    cu, cd = P["u"], (FRONT_D + BACK_D) / 2
    rr = (FRONT_D - BACK_D) / 2
    rd = R["depth"] / 2
    first = K.BASE_RUNGS[0]
    pts = [(first + 0.07, rd + 0.09), (first + 0.2, FRONT_D - 0.01), (first + 0.45, FRONT_D)]
    pts += [(first + 0.45 + k * (cu - first - 0.6) / 6, FRONT_D) for k in range(1, 7)]
    for k in range(13):
        th = math.radians(90 - 180 * k / 12)
        pts.append((cu + rr * math.cos(th), cd + rr * math.sin(th)))
    second = K.BASE_RUNGS[1]
    pts += [(cu - 0.15 - k * (cu - 0.15 - second - 0.14) / 6, BACK_D) for k in range(1, 7)]
    pts += [(second + 0.08, rd - 0.1), (second - 0.08, BACK_D - 0.005), (second - 0.35, BACK_D),
            (second - 0.62, BACK_D + 0.01)]
    return pts


def rope(m):
    """The rope as short tubes end to end (each ends inside the next), for the atlas's sake."""
    pts = []
    for u, d in rope_path():
        p = g(u, K.ROPE_X, d)
        # the long runs: a point every chunk's length, so no tube is longer than that
        if pts and (p - pts[-1]).length > CHUNK:
            n = math.ceil((p - pts[-1]).length / CHUNK)
            a = pts[-1]
            pts += [a.lerp(p, k / n) for k in range(1, n)]
        pts.append(p)
    run, length = [pts[0]], 0.0
    for p in pts[1:]:
        run.append(p)
        length += (p - run[-2]).length
        if length >= CHUNK * 0.9:
            tube(m, run, K.ROPE_R, 8)
            run, length = [run[-2], p], (p - run[-2]).length
    if len(run) > 1:
        tube(m, run, K.ROPE_R, 8)


def knots(m):
    rd = R["depth"] / 2
    for u in (K.BASE_RUNGS[0], K.BASE_RUNGS[1]):
        kit.ellipsoid(m, g(u + 0.03, K.ROPE_X, rd), (0.06, 0.085, 0.1), us=10, vs=6)


def pulley(m):
    """The wheel the rope runs over, on a bracket from the base's top rung."""
    P = K.PULLEY
    cd = (FRONT_D + BACK_D) / 2
    geo.cylinder(m, "x", g(P["u"], K.ROPE_X, cd), P["r"], P["t"], segs=18, bevel=0.006)


def pulley_bracket(m):
    P = K.PULLEY
    cd = (FRONT_D + BACK_D) / 2
    top = K.BASE_RUNGS[-1]
    for side in (1, -1):
        x0 = K.ROPE_X + side * (P["t"] / 2 + 0.006)
        x1 = x0 + side * 0.016
        bx(m, (top - 0.06, P["u"] + 0.06), (min(x0, x1), max(x0, x1)), (cd - 0.07, cd + 0.07),
           0.006)
    geo.cylinder(m, "x", g(P["u"], K.ROPE_X, cd), 0.025, P["t"] + 0.07, segs=8)


def base_geo():
    F = kit.Find(K.SET)
    for side in (1, -1):
        F.add(RAIL, rail, K.BASE_IN, side, (0.0, K.BASE_LEN), 0.0)
    F.add(RUNG, section_rungs, K.BASE_RUNGS, 0.0, K.BASE_IN, R["depth"] / 2)
    F.add(RUNG, section_flares, K.BASE_RUNGS, 0.0, K.BASE_IN, R["depth"] / 2)
    F.add(FOOT, shoes)
    F.add(PAD, pads)
    F.add(BOLT, shoe_bolts)
    F.add(GUIDE, base_guides)
    F.add(BOLT, guide_rivets)
    F.add(PULLEY, pulley)
    F.add(GUIDE, pulley_bracket)
    F.add(ROPE, rope)
    F.add(ROPE, knots)
    return F


def fly_geo():
    F = kit.Find(K.FLY)
    d = K.FLY_D + R["depth"] / 2
    for side in (1, -1):
        F.add(RAIL, rail, K.FLY_IN, side, (K.FLY_FROM, K.FLY_FROM + K.FLY_LEN), K.FLY_D)
    F.add(RUNG, section_rungs, K.FLY_RUNGS, K.FLY_FROM, K.FLY_IN, d)
    F.add(RUNG, section_flares, K.FLY_RUNGS, K.FLY_FROM, K.FLY_IN, d)
    F.add(GUIDE, fly_guides)
    F.add(LOCK, locks)
    F.add(GUIDE, hooks)
    F.add(CAP, caps)
    return F


PAD = 4   # texels round each UV island (the kit's 6 starves a set of thin parts)


def unwrap(objs):
    """Both sections smart-projected together into the whole atlas: the kit gives each object its
    own square, which leaves half of it empty for two long parts side by side."""
    bpy.ops.object.select_all(action="DESELECT")
    for o in objs:
        o.select_set(True)
    bpy.context.view_layer.objects.active = objs[0]
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.select_all(action="SELECT")
    bpy.ops.uv.smart_project(angle_limit=math.radians(55), island_margin=PAD / K.TEX,
                             area_weight=0.0, correct_aspect=True, scale_to_bounds=False)
    bpy.ops.uv.select_all(action="SELECT")
    bpy.ops.uv.pack_islands(rotate=True, margin=PAD / K.TEX)
    bpy.ops.object.mode_set(mode="OBJECT")
    clash = kit.clashes(objs)
    assert not clash, f"faces share texels in the atlas: {clash}"


def build_all(baking, coll=None):
    objs = {K.SET: base_geo().build(40, coll), K.FLY: fly_geo().build(40, coll)}
    kit.settle(list(objs.values()))
    if baking:
        unwrap(list(objs.values()))
        kit.keep_uvs(objs)
    else:
        kit.wear_uvs(objs)
        print(f"atlas: faces on unpainted texels {kit.unpainted(objs)}")
    print(f"atlas: {kit.density(list(objs.values())):.0f} texels a stud, "
          f"uv {kit.uv_hash(list(objs.values()))}")
    return objs


def box(obs):
    vs = [v.co for ob in obs for v in ob.data.vertices]
    return (Vector([min(v[i] for v in vs) for i in range(3)]),
            Vector([max(v[i] for v in vs) for i in range(3)]))


# --- the recipe --------------------------------------------------------------------------------

def look(nb):
    """Aluminium gone dull and grey, brushed along the rails, scuffed bright on the edges that
    knock things and smudged dark where hands go; paint splashes from old jobs; orange and yellow
    warning labels on the rails' outer webs; rungs ribbed on their tread; cast feet, black rubber
    pads; zinc-plated steel guides; black plastic caps; a yellow rope, twisted, gone grubby."""
    L = kit.Look(nb, K.SEED)
    x, y, z = L.x, L.y, L.z
    # the drawing's studs: u along from the feet, d through from the base's back
    u = nb.add(nb.mul(y, -1.0), K.GRIP["u"])
    d = nb.add(z, K.GRIP["d"])
    ax = nb.absf(nb.add(x, K.GRIP["x"]))     # distance from the middle line, either side
    # faces looking out to the sides, away from the middle (not a web's inner face)
    outward = nb.ss(nb.div(nb.mul(L.nx, nb.add(x, K.GRIP["x"])), nb.add(ax, 0.001)), 0.6, 0.85)
    edge = nb.edge(0.01, k=5.0)

    # aluminium: grey, dull, brushed along its length
    brushed = nb.mr(L.noise(160.0, 1, stretch=(1.0, 0.04, 1.0), detail=1), 0.3, 0.7, 0.9, 1.06)
    mottle = nb.mr(L.noise(2.5, 2, detail=4), 0.3, 0.7, 0.86, 1.05)
    # mill-finish aluminium reads pale and mostly diffuse: as a mirror-bright metal it took on the
    # dark room's colour and lay on a unit's floor as a black shape (the first floor sheet)
    alu = nb.tint(nb.tint(hexc("#C4C7C8"), brushed), mottle)
    C = kit.Coat(L, alu, nb.mr(L.noise(7.0, 3, detail=3), 0.3, 0.7, 0.42, 0.55), 0.38,
                 nb.mul(L.noise(120.0, 4, stretch=(1.0, 0.05, 1.0), detail=1), 0.04))
    metal = L.k(RAIL, RUNG, FOOT, LOCK)
    # oxide: chalky grey blooms where it's been out in the weather
    ox = nb.mul(nb.ss(L.noise(4.0, 5, detail=5, rough=0.7), 0.52, 0.66), metal)
    C.paint(nb.mul(ox, 0.75), hexc("#A3A6A5"), 0.72, 0.15)
    # bright where its edges knock door frames and floors
    knock = nb.mul(nb.mul(edge, nb.ss(L.noise(11.0, 6, detail=5, rough=0.7), 0.44, 0.58)), metal)
    C.paint(knock, hexc("#E4E6E7"), 0.3, 0.75)
    # long scratches along the rails
    scr = nb.band(L.noise(4.0, 7, stretch=(1.0, 0.06, 1.0), detail=2), 0.497, 0.503, 0.001)
    C.paint(nb.mul(nb.mul(scr, nb.ss(L.noise(1.5, 8), 0.5, 0.62)), metal), hexc("#DADDDE"), 0.35,
            height=-0.25)
    # grey-black smudges where hands carry and climb it: the rails' middles, the rungs' treads
    hands = nb.mul(nb.ss(L.noise(3.0, 9, detail=4), 0.5, 0.7), nb.band(u, 1.8, 4.4, 0.6))
    C.paint(nb.mul(nb.mul(hands, L.k(RAIL)), 0.5), hexc("#74777A"), 0.6)

    # the rungs: ribbed across their tread, worn bright on the ribs, grimy between
    rg = L.k(RUNG)
    tread = nb.ss(nb.mul(L.ny, -1.0), 0.55, 0.8)     # the flat, facing +u (Blender -y)
    ribs = nb.band(nb.fract(nb.div(z, 0.03)), 0.35, 0.65, 0.08)
    C.paint(nb.mul(nb.mul(rg, tread), ribs), hexc("#D8DBDC"), 0.32, height=0.6)
    C.paint(nb.mul(nb.mul(rg, tread), nb.inv(ribs)), hexc("#7B7E80"), 0.7)

    # the labels on the rails' outer webs, each section's own: an orange danger label high up,
    # a yellow duty label low down; worn at their corners
    on_web = nb.mul(L.k(RAIL), outward)
    base_side = nb.ss(d, K.FLY_D - 0.01, K.FLY_D - 0.03)          # 1 on the base's rails
    fu = nb.sub(u, K.FLY_FROM)
    su = nb.mixf(base_side, fu, u)                                # u along its own section
    mid_d = nb.mixf(base_side, K.FLY_D + R["depth"] / 2, R["depth"] / 2)
    across = nb.absf(nb.sub(d, mid_d))
    lab_h = R["depth"] / 2 - R["flange"] - 0.01
    peel = nb.ss(L.noise(9.0, 10, detail=4), 0.64, 0.7)
    lo, hi = K.LABELS["danger"]
    danger = nb.mul(nb.mul(on_web, nb.band(su, lo, hi, 0.01)), nb.ss(across, lab_h, lab_h - 0.01))
    danger = nb.mul(danger, nb.inv(peel))
    C.paint(danger, nb.tint(hexc("#E8E2D2"), nb.mr(L.noise(8.0, 11), 0.3, 0.7, 0.82, 1.0)), 0.6,
            0.0, 0.05)
    band = nb.mul(danger, nb.ss(su, hi - 0.2, hi - 0.17))
    C.paint(band, hexc("#E0601C"))
    # its print: rows of small type running along the rail, broken into words
    rows = nb.band(nb.fract(nb.div(nb.sub(d, mid_d), 0.034)), 0.3, 0.7, 0.04)
    words = nb.mul(rows, nb.ss(L.noise(40.0, 12, stretch=(1.0, 0.15, 1.0), detail=1), 0.4, 0.44))
    words = nb.mul(nb.mul(words, nb.band(su, lo + 0.06, hi - 0.26, 0.01)),
                   nb.ss(across, lab_h - 0.025, lab_h - 0.035))
    C.paint(nb.mul(nb.mul(words, danger), 0.85), hexc("#2A2A28"))
    lo, hi = K.LABELS["duty"]
    duty = nb.mul(nb.mul(on_web, nb.band(su, lo, hi, 0.01)), nb.ss(across, lab_h, lab_h - 0.01))
    duty = nb.mul(duty, nb.inv(peel))
    C.paint(duty, hexc("#E2B323"), 0.55, 0.0, 0.05)
    big = nb.mul(nb.band(su, lo + 0.08, lo + 0.3, 0.01), nb.ss(across, lab_h - 0.03, lab_h - 0.045))
    C.paint(nb.mul(big, duty), hexc("#232220"))

    # paint splashes from old jobs: off-white drips and spots, a few grey, mostly on the rails and
    # the rungs' ends
    blobs = nb.ss(L.noise(9.0, 13, detail=3, rough=0.6), 0.71, 0.73)
    specks = nb.ss(L.noise(45.0, 14, detail=2), 0.74, 0.76)
    splash = nb.mul(nb.add(blobs, specks, clamp=True), metal)
    C.paint(splash, nb.tint(hexc("#DCD6C8"), nb.mr(L.noise(3.0, 15), 0.3, 0.7, 0.85, 1.02)), 0.55,
            0.0, 0.12)
    grey = nb.mul(nb.ss(L.noise(7.0, 16, detail=3, rough=0.6), 0.735, 0.75), metal)
    C.paint(grey, hexc("#7F8A8E"), 0.5, 0.0, 0.1)

    # the feet's casting: darker, rough, grimy from floors
    ft = L.k(FOOT)
    C.paint(ft, nb.tint(hexc("#A2A5A5"), nb.mr(L.noise(18.0, 17, detail=4), 0.3, 0.7, 0.7, 1.0)),
            0.68, 0.45)
    low = nb.ss(u, 0.9, 0.0)
    grime = nb.mul(nb.mul(low, nb.ss(L.noise(6.0, 18, detail=5), 0.42, 0.6)), nb.add(ft, metal,
                                                                                    clamp=True))
    C.paint(nb.mul(grime, 0.7), hexc("#3B3A36"), 0.85, 0.2)
    # the pads: black rubber, ribbed across their soles, worn grey
    pd = L.k(PAD)
    C.rubber(pd)
    sole = nb.band(nb.fract(nb.div(z, 0.05)), 0.3, 0.65, 0.1)
    C.paint(nb.mul(pd, sole), height=0.6)
    C.paint(nb.mul(nb.mul(pd, nb.ss(L.noise(8.0, 19, detail=4), 0.48, 0.62)), 0.8), hexc("#353533"),
            0.85)

    # the guides and the pulley's bracket: zinc-plated steel, dulled, a little rust in the corners
    gd = L.k(GUIDE)
    C.paint(gd, nb.tint(hexc("#B3B6B1"), nb.mr(L.noise(14.0, 20, detail=3), 0.3, 0.7, 0.75, 1.02)),
            0.45, 1.0)
    rust = nb.mul(gd, nb.ss(L.noise(30.0, 21, detail=3), 0.64, 0.7))
    C.paint(rust, hexc("#6E4129"), 0.85, 0.2)
    # the locks' housings: cast, painted black, chipped to the metal
    lk = L.k(LOCK)
    C.paint(lk, hexc("#1A1B1C"), 0.55, 0.0)
    chip = nb.mul(nb.mul(edge, lk), nb.ss(L.noise(16.0, 22, detail=4), 0.46, 0.6))
    C.paint(chip, hexc("#9A9D9E"), 0.4, 0.9)
    # the caps: black plastic, scuffed
    cp = L.k(CAP)
    C.paint(cp, hexc("#111112"), nb.mr(L.noise(10.0, 23), 0.3, 0.7, 0.45, 0.6), 0.0)
    C.paint(nb.mul(nb.mul(edge, cp), nb.ss(L.noise(12.0, 24, detail=4), 0.45, 0.6)),
            hexc("#3A3A3A"), 0.7)
    # the pulley: a nylon wheel, grey-white
    pl = L.k(PULLEY)
    C.paint(pl, hexc("#C8C6BE"), 0.5, 0.0)
    # bolts and rivets: zinc
    bo = L.k(BOLT)
    C.paint(bo, hexc("#A4A6A2"), 0.4, 1.0)

    # the rope: yellow polypropylene, three strands twisted, grubby
    rp = L.k(ROPE)
    twist = nb.band(nb.fract(nb.add(nb.div(y, 0.06), nb.mul(nb.add(x, z), 9.0))), 0.0, 0.33, 0.06)
    yellow = nb.tint(hexc("#D3A82A"), nb.mr(L.noise(5.0, 25, detail=3), 0.3, 0.7, 0.75, 1.0))
    C.paint(rp, yellow, 0.8, 0.0)
    C.paint(nb.mul(rp, twist), hexc("#8E6E1C"), height=-0.5)
    C.paint(nb.mul(nb.mul(rp, nb.ss(L.noise(4.0, 26, detail=4), 0.45, 0.65)), 0.6), hexc("#6F6448"),
            0.9)

    C.finish(ao=0.3, ao_low=0.42, dust=K.DUST)
    return C.channels(dist=0.002, strength=0.6)


def stage_textures():
    kit.reset()
    objs = build_all(baking=True)
    kit.bake_set([(ob, bake.Rig(f"bk_{name}", look)) for name, ob in objs.items()], samples=32,
                 pad=PAD)


# --- export ---------------------------------------------------------------------------------

def piece(ob, all_obs):
    lo, hi = box([ob])
    s, c = hi - lo, (lo + hi) / 2
    blo, bhi = box(all_obs)
    bs, bc = bhi - blo, (blo + bhi) / 2
    return dict(size=(s.x, s.z, s.y), centre=K.to_roblox(c), tris=kit.tris(ob),
                bsize=(bs.x, bs.z, bs.y), bcentre=K.to_roblox(bc))


def stage_export():
    kit.reset()
    objs = build_all(baking=False)
    mat = kit.material()
    for ob in objs.values():
        ob.data.materials.append(mat)
    os.makedirs(OUT, exist_ok=True)
    bpy.ops.object.select_all(action="DESELECT")
    for ob in objs.values():
        ob.select_set(True)
    bpy.context.view_layer.objects.active = objs[K.SET]
    bpy.ops.export_scene.fbx(
        filepath=FBX, use_selection=True, object_types={"MESH"},
        apply_scale_options="FBX_SCALE_UNITS", axis_forward="Z", axis_up="Y",
        use_mesh_modifiers=True, mesh_smooth_type="OFF", use_tspace=False,
        add_leaf_bones=False, bake_anim=False, path_mode="COPY", embed_textures=True)
    obs = list(objs.values())
    base, fly = piece(objs[K.SET], obs), piece(objs[K.FLY], obs)
    print("FBX", FBX, {K.SET: base["tris"], K.FLY: fly["tris"]})
    os.makedirs(os.path.dirname(SPECS), exist_ok=True)
    K.write_luau(SPECS, base, fly)


# --- look sheets ----------------------------------------------------------------------------

# Roblox's frame to Blender's and back (the same matrix both ways): x = -X, y = Z, z = Y.
FLIP = Matrix(((-1, 0, 0, 0), (0, 0, 1, 0), (0, 1, 0, 0), (0, 0, 0, 1)))

# Where the game holds the ladder in first person (src/shared/Tools/Catalog.luau, the row's `hold`
# and `holdTurn`): the camera's right, up and back in studs, then its turn in degrees (yaw left,
# pitch up, roll).
HOLD = ((-1.2, -1.25, -0.7), (-14.0, 8.0, -58.0))


def held(cam, offset, turn):
    """The ladder's place in the world for a camera holding it at offset, turned (Roblox's camera
    space, which Blender's camera shares: -Z ahead, +Y up)."""
    yaw, pitch, roll = (math.radians(a) for a in turn)
    R_ = (Matrix.Rotation(yaw, 4, "Y") @ Matrix.Rotation(pitch, 4, "X")
          @ Matrix.Rotation(roll, 4, "Z"))
    return cam.matrix_world @ Matrix.Translation(Vector(offset)) @ R_


def stage_renders():
    kit.reset()
    render.setup(96, (1600, 900))
    objs = build_all(baking=False)
    mat = kit.material()
    obs = list(objs.values())
    for ob in obs:
        ob.data.materials.append(mat)
    os.makedirs(SHEETS, exist_ok=True)
    lo, hi = box(obs)
    middle = -(lo.y + hi.y) / 2

    def place(M):
        for ob in obs:
            ob.matrix_world = M

    def lay(at, yaw):
        """Lying on its back, as the game lays it: its lowest point on the floor."""
        place(Matrix.Translation(Vector(at)) @ Matrix.Rotation(math.radians(yaw), 4, "Z")
              @ Matrix.Translation(Vector((-(lo.x + hi.x) / 2, middle, -lo.z))))

    def lean(at, yaw, tilt, travel):
        """Standing on its feet against a wall behind it (+Y), its fly run out `travel`: for the
        studio sheet, the moment L-13b2 builds."""
        feet = g(K.SHOE["pad"][0], 0.0, R["depth"] / 2)
        M = (Matrix.Translation(Vector(at)) @ Matrix.Rotation(math.radians(yaw), 4, "Z")
             @ Matrix.Rotation(math.radians(tilt - 180), 4, "X")
             @ Matrix.Rotation(math.radians(180), 4, "Y") @ Matrix.Translation(-feet))
        objs[K.SET].matrix_world = M
        objs[K.FLY].matrix_world = M @ Matrix.Translation(Vector((0.0, -travel, 0.0)))

    # 1. in the studio: collapsed from the fly's side, three-quarter (the labels, the rope, the
    #    locks), then leaned and run out to full length against nothing, from the climbing side
    studio = render.studio_rig()
    for o in studio:
        o.hide_render = False
    lay((0.0, 0.0, 0.0), 0)
    cam = render.camera((-5.2, -3.4, 3.6), (0.0, 0.0, 0.2), lens=30)
    render.shoot(cam, os.path.join(SHEETS, "ladder-front.png"), exposure=-0.2)
    lean((0.0, 0.0, 0.0), 0, 75.5, K.TRAVEL)
    cam = render.camera((9.0, -13.0, 6.0), (0.0, 1.2, 5.7), lens=24)
    render.shoot(cam, os.path.join(SHEETS, "ladder-up.png"), exposure=-0.2)
    for o in studio:
        o.hide_render = True

    # 2. on a unit's floor among boxes, by its bulb, from the doorway at standing height: the
    #    moment you spot it
    bk = kit.boxes_kit()
    bmat = bk.material(False)
    boxes, _, _ = bk.build_all(baking=False)
    for b in boxes.values():
        b.data.materials.append(bmat)
    render.world((0.002, 0.0025, 0.004), 1.0)
    bk.unit_room(bpy.context.scene.collection)
    bk.place(boxes, "Wardrobe", -4.4, 10.6, 0.0, 6)
    bk.place(boxes, "Large", -1.9, 10.9, 0.0, -3)
    bk.place(boxes, "Medium", -1.85, 10.85, 2.4, 9)
    bk.place(boxes, "Large", 2.4, 10.8, 0.0, 4, copy=True)
    bk.place(boxes, "Open", 4.0, 7.9, 0.0, 28)
    bulb = bpy.data.lights.new("bulb", "POINT")
    bulb.energy, bulb.color, bulb.shadow_soft_size = 220.0, (1.0, 0.674, 0.408), 0.08
    bo = bpy.data.objects.new("bulb", bulb)
    bpy.context.scene.collection.objects.link(bo)
    bo.location = (0.0, 6.0, 8.7)
    lay((0.0, 5.0, 0.0), 80)
    # 14.6 mm is Roblox's 70 degree view on a 16:9 screen
    cam = render.camera((0.0, -1.5, 4.6), (0.2, 5.0, 0.4), lens=14.6)
    render.shoot(cam, os.path.join(SHEETS, "ladder-floor.png"), exposure=0.2)

    # 3. your view: carried at your left side on its edge, its top leading
    cam = render.camera((0.6, -1.0, 4.6), (-0.4, 9.0, 3.6), lens=14.6)
    bpy.context.view_layer.update()
    place(held(cam, *HOLD) @ FLIP)
    render.shoot(cam, os.path.join(SHEETS, "ladder-view.png"), exposure=0.2)


STAGES = {"textures": stage_textures, "export": stage_export, "renders": stage_renders}

if __name__ == "__main__":
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    ap = argparse.ArgumentParser()
    ap.add_argument("--stage", choices=list(STAGES), required=True)
    STAGES[ap.parse_args(argv).stage]()
    print("DONE")
