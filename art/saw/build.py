"""Build the saw in Blender, headless (art/saw/README.md).

    blender -b --factory-startup -P art/saw/build.py -- --stage textures|export|renders

Stages:
    textures  the Saw texture set, baked from its recipe into out/textures
    export    out/Saw.fbx (one MeshPart) and src/shared/Tools/Specs/Saw.luau
    renders   the look sheets, art/sheets/saw-*.png

It borrows the finds' atlas, bake and export (art/finds/build.py), pointed at its own spec and out
folder, as the bolt cutters and the flashlight do.
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
SPECS = os.path.join(K.ROOT, "src", "shared", "Tools", "Specs", "Saw.luau")


def finds_kit():
    """The finds' build, as a library: it imports `spec`, which is already this folder's, so its
    atlas size, set name and dust are the saw's; its out paths are pointed here."""
    s = importlib.util.spec_from_file_location("finds_build", os.path.join(FINDS, "build.py"))
    mod = importlib.util.module_from_spec(s)
    s.loader.exec_module(mod)
    assert mod.K is K, "the finds' build must see the saw's spec"
    mod.OUT, mod.TEX, mod.UVS, mod.FBX = OUT, TEX, os.path.join(OUT, "uvs.npz"), FBX
    return mod


kit = finds_kit()

# What a face is, for the recipe (a face attribute).
BLADE, SHOE, NOSE, BOOT, BODY, GRIP, TRIGGER, BATTERY, BOLT = range(9)


# --- geometry --------------------------------------------------------------------------------

def g(y, z, x=0.0):
    """A drawing point (inches: y from the shoe's face, z from the body's middle line, x across)
    in the saw's frame (studs from the grip)."""
    by, bz = K.at(y, z)
    return Vector((x * K.IN, by, bz))


def loft(m, sections, caps=(True, True)):
    """A closed shape through cross-sections (each a closed ring of points, all the same count),
    capped at both ends. Built in a bmesh so its faces can be turned to look outwards, in a fixed
    order so every stage numbers it alike."""
    bm = bmesh.new()
    rings = [[bm.verts.new(p) for p in sec] for sec in sections]
    n = len(sections[0])
    for a, b in zip(rings, rings[1:]):
        for i in range(n):
            j = (i + 1) % n
            bm.faces.new((a[i], a[j], b[j], b[i]))
    if caps[0]:
        bm.faces.new(rings[0])
    if caps[1]:
        bm.faces.new(list(reversed(rings[-1])))
    kit.solid(m, bm)


def ring(c, t, hw, hh, e, n):
    """A rounded square of n points round c, across X and the path's normal in Y-Z (t the path's
    way there): hw across, hh along the normal, e its squareness (2 an ellipse)."""
    t = Vector((0.0, t.y, t.z)).normalized()
    up = Vector((0.0, -t.z, t.y))  # t turned a quarter in Y-Z: +Z for a path along +Y
    out = []
    for i in range(n):
        a = 2 * math.pi * i / n
        ca, sa = math.cos(a), math.sin(a)
        u = math.copysign(abs(ca) ** (2 / e), ca)
        v = math.copysign(abs(sa) ** (2 / e), sa)
        out.append(c + Vector((hw * u, 0.0, 0.0)) + up * (hh * v))
    return out


def catmull(rows, sub):
    """Each column of `rows` (tuples of numbers) smoothed through by a Catmull-Rom curve, `sub`
    steps between neighbours."""
    P = [list(r) for r in rows]
    P = [[2 * a - b for a, b in zip(P[0], P[1])]] + P + [[2 * a - b for a, b in zip(P[-1], P[-2])]]
    out = []
    for i in range(len(rows) - 1):
        p0, p1, p2, p3 = P[i], P[i + 1], P[i + 2], P[i + 3]
        for k in range(sub if i < len(rows) - 2 else sub + 1):
            u = k / sub
            out.append(tuple(0.5 * ((2 * b) + (-a + c) * u + (2 * a - 5 * b + 4 * c - d) * u * u
                                    + (-a + 3 * b - 3 * c + d) * u * u * u)
                             for a, b, c, d in zip(p0, p1, p2, p3)))
    return out


def along(m, stations, n, e=K.ROUND, sub=3):
    """A body piece lofted along the saw's length through (y, half width, half height, middle z)
    stations, in inches."""
    secs = [ring(g(y, zc), Vector((0, 1, 0)), hw * K.IN, hh * K.IN, e, n)
            for y, hw, hh, zc in catmull(stations, sub)]
    loft(m, secs)


def path_piece(m, path, half, n, e=2.6, sub=4, taper=1.0):
    """A bar along a (y, z) path in inches, `half` its half width and depth; its ends shrunk to
    `taper` of that (a trigger's rounded tips)."""
    pts = catmull(path, sub)
    secs = []
    for i, (y, z) in enumerate(pts):
        a = pts[max(i - 1, 0)]
        b = pts[min(i + 1, len(pts) - 1)]
        t = g(b[0], b[1]) - g(a[0], a[1])
        s = taper if i in (0, len(pts) - 1) else 1.0
        secs.append(ring(g(y, z), t, half[0] * K.IN * s, half[1] * K.IN * s, e, n))
    loft(m, secs)


def rounded_box(m, box, r, n=24):
    """A box (y from, y to, z from, z to, half width), its ends rounded over r inches and its
    long edges by its squareness."""
    y0, y1, z0, z1, hw = box
    hh, zc = (z1 - z0) / 2, (z1 + z0) / 2
    steps = []
    for k in range(4):
        th = math.radians(90 * k / 3)
        steps.append((r * (1 - math.sin(th)), r * (1 - math.cos(th))))
    rows = [(y0 + dy, hw - ins, hh - ins) for dy, ins in steps]
    rows += [(y1 - dy, hw - ins, hh - ins) for dy, ins in reversed(steps)]
    secs = [ring(g(y, zc), Vector((0, 1, 0)), w * K.IN, h * K.IN, K.BOX_ROUND, n)
            for y, w, h in rows]
    loft(m, secs)


def blade(m):
    """The demolition blade: its outline (y, top, bottom) from the tip back into the nose, the
    teeth along its bottom, each rising gently from its gullet to its point and dropping steeply
    behind it (they cut pulling, towards the saw)."""
    B, T = K.BLADE, K.TEETH
    bot = [(B["tip"], B["bottom"])]
    y = T["start"]
    while y + T["pitch"] <= T["end"] + 1e-6:
        bot.append((y, B["bottom"]))
        bot.append((y + T["pitch"] * 0.82, B["bottom"] - T["depth"]))
        y += T["pitch"]
    bot.append((y, B["bottom"]))
    bot.append((B["back"], B["bottom"]))

    def top(y):
        if y >= B["slope_from"]:
            return B["top"]
        f = (y - B["tip"]) / (B["slope_from"] - B["tip"])
        return B["tip_top"] + (B["top"] - B["tip_top"]) * f

    def bottom(y):
        for (ya, za), (yb, zb) in zip(bot, bot[1:]):
            if ya <= y <= yb:
                return za if yb == ya else za + (zb - za) * (y - ya) / (yb - ya)
        return B["bottom"]

    ys = sorted({y for y, _ in bot} | {B["slope_from"]})
    h = B["half"]
    secs = []
    for y in ys:
        zt, zb = top(y), bottom(y)
        secs.append([g(y, zt, h), g(y, zt, -h), g(y, zb, -h), g(y, zb, h)])
    loft(m, secs)


def shoe(m):
    """The stamped steel foot: its face plate, chamfered at the front, the two cheeks going back
    either side of the nose, and the bar that carries it into the gearbox."""
    S = K.SHOE
    f0, f1 = S["face"]
    hw = S["half_width"]
    za, zb = S["z"]
    hh, zc = (zb - za) / 2, (zb + za) / 2
    c = 0.05
    secs = [ring(g(f0, zc), Vector((0, 1, 0)), (hw - c) * K.IN, (hh - c) * K.IN, 4.0, 28),
            ring(g(f0 + c, zc), Vector((0, 1, 0)), hw * K.IN, hh * K.IN, 4.0, 28),
            ring(g(f1, zc), Vector((0, 1, 0)), hw * K.IN, hh * K.IN, 4.0, 28)]
    loft(m, secs)
    ca, cb = S["cheek_z"]
    for side in (1, -1):
        x0, x1 = side * (hw - S["cheek_t"]), side * hw
        geo.box(m, g(f1 - 0.01, ca, min(x0, x1)), g(S["cheek_back"], cb, max(x0, x1)),
                bevel=0.004)
    y0, y1, z0, z1, bw = S["bar"]
    geo.box(m, g(y0, z0, -bw), g(y1, z1, bw), bevel=0.004)


def shoe_bolts(m):
    y, z = K.SHOE_BOLT
    x = K.SHOE["half_width"]
    for side in (1, -1):
        geo.hexbolt(m, g(y, z, side * x), "x", side, 0.32 * K.IN, 0.14 * K.IN)


def lever(m):
    """The blade clamp's lever on the nose's side, the side your view sees (-x)."""
    L = K.LEVER
    y0, y1 = L["y"]
    z0, z1 = L["z"]
    # the nose's half width at the lever, read off its stations
    xs = [hw for y, hw, _, _ in K.NOSE if y <= (y0 + y1) / 2]
    x_in = (xs[-1] if xs else K.NOSE[0][1]) - 0.05
    geo.box(m, g(y0, z0, -x_in - L["out"] - 0.08), g(y1, z1, -x_in + 0.02), bevel=0.006)


def saw_geo():
    F = kit.Find(K.SET)
    F.add(BLADE, blade)
    F.add(SHOE, shoe)
    F.add(BOLT, shoe_bolts)
    F.add(NOSE, along, K.NOSE, 28, sub=2)
    F.add(TRIGGER, lever)
    F.add(BOOT, along, K.BOOT, 28)
    F.add(BODY, along, K.BODY, 28)
    F.add(BODY, along, K.TAIL, 24)
    F.add(GRIP, path_piece, K.GRIP_PATH, K.GRIP_HALF, 20)
    F.add(BODY, path_piece, K.NECK_PATH, K.NECK_HALF, 20, e=3.0)
    F.add(TRIGGER, path_piece, K.TRIGGER_PATH, K.TRIGGER_HALF, 12, taper=0.55)
    F.add(BODY, rounded_box, K.FOOT, 0.22)
    F.add(BATTERY, rounded_box, K.BATTERY, 0.3, 28)
    F.add(BODY, rounded_box, K.BUTTON, 0.05, 12)
    return F


def build_all(baking, coll=None):
    objs = {K.SET: saw_geo().build(40, coll)}
    kit.settle(list(objs.values()))
    if baking:
        kit.unwrap(list(objs.values()))
        kit.keep_uvs(objs)
    else:
        kit.wear_uvs(objs)
        print(f"atlas: faces on unpainted texels {kit.unpainted(objs)}")
    print(f"atlas: {kit.density(list(objs.values())):.0f} texels a stud, "
          f"uv {kit.uv_hash(list(objs.values()))}")
    return objs


def box(ob):
    vs = [v.co for v in ob.data.vertices]
    return (Vector([min(v[i] for v in vs) for i in range(3)]),
            Vector([max(v[i] for v in vs) for i in range(3)]))


# --- the recipe --------------------------------------------------------------------------------

def look(nb):
    """Green plastic, satin, scuffed pale on its corners and scratched; black rubber over the
    gearbox and on the grip, moulded in rings; a bare cast nose; a blackened steel shoe worn
    bright at its edges; a grey bimetal blade, its teeth ground bright and dusted with drywall; a
    black battery with a green latch band, ribbed sides and a charge gauge at the back."""
    L = kit.Look(nb, K.SEED)
    x, y, z = L.x, L.y, L.z
    # the drawing's inches, for placing things
    yi = nb.add(nb.div(y, K.IN), K.GRIP[0])
    zi = nb.add(nb.div(z, K.IN), K.GRIP[1])
    side = nb.ss(nb.absf(L.nx), 0.5, 0.8)        # faces looking out to either side
    view_side = nb.ss(nb.mul(L.nx, -1.0), 0.5, 0.8)   # the side your view sees (-x)
    edge = nb.edge(0.012, k=5.0)

    # the body: green plastic, a little uneven, satin
    green = nb.tint(hexc("#2C8A3C"), nb.mr(L.noise(3.0, 1, detail=4), 0.3, 0.7, 0.88, 1.08))
    C = kit.Coat(L, green, nb.mr(L.noise(6.0, 2, detail=3), 0.3, 0.7, 0.4, 0.52), 0.0,
                 nb.mul(L.noise(180.0, 3, detail=1), 0.03))
    bd = L.k(BODY)
    # scuffs: pale and rough where it's been dragged and knocked, mostly on corners
    scuff = nb.mul(edge, nb.ss(L.noise(10.0, 4, detail=5, rough=0.7), 0.45, 0.6))
    C.paint(nb.mul(nb.clamp(scuff), bd), hexc("#6E9F76"), 0.72)
    blotch = nb.mul(nb.ss(L.noise(6.0, 5, detail=5, rough=0.7), 0.64, 0.72), bd)
    C.paint(nb.mul(blotch, 0.7), hexc("#5E8E64"), 0.7, height=-0.1)
    # scratches, pale through the colour
    scr = nb.band(L.noise(5.0, 6, stretch=(1.0, 0.2, 1.0), detail=2), 0.498, 0.502, 0.001)
    C.paint(nb.mul(nb.mul(scr, nb.ss(L.noise(2.0, 7), 0.55, 0.65)), bd), hexc("#6FA478"), 0.6,
            height=-0.2)
    # the cooling slots either side of the motor, slanted
    v = K.VENTS
    spacing = (v["y"][1] - v["y"][0]) / v["slots"]
    phase = nb.fract(nb.div(nb.add(nb.sub(yi, v["y"][0]), nb.mul(zi, 0.35)), spacing))
    slot = nb.mul(nb.band(phase, 0.12, 0.58, 0.04),
                  nb.mul(nb.band(yi, v["y"][0], v["y"][1], 0.05),
                         nb.band(zi, v["z"][0], v["z"][1], 0.06)))
    slot = nb.mul(nb.mul(slot, side), bd)
    C.paint(slot, hexc("#0A0B0A"), 0.9, 0.0, -0.7)
    # a warning sticker on your view's side, worn and peeling at its corners
    lb = K.LABEL
    sticker = nb.mul(nb.mul(nb.band(yi, lb["y"][0], lb["y"][1], 0.02),
                            nb.band(zi, lb["z"][0], lb["z"][1], 0.02)), nb.mul(view_side, bd))
    peel = nb.ss(L.noise(7.0, 8, detail=4), 0.62, 0.68)
    sticker = nb.mul(sticker, nb.inv(peel))
    C.paint(sticker, nb.tint(hexc("#D9D3C2"), nb.mr(L.noise(9.0, 9, detail=3), 0.3, 0.7, 0.8, 1.0)),
            0.6, 0.0, 0.05)
    # its print: a yellow triangle at the front, lines of small type behind it
    tri_u = nb.sub(yi, lb["y"][0] + 0.38)
    tri_v = nb.sub(zi, -0.05)
    tri = nb.mul(nb.ss(nb.absf(tri_u), 0.28, 0.25),
                 nb.mul(nb.band(tri_v, -0.3, 0.3, 0.02),
                        nb.ss(nb.sub(nb.absf(tri_u), nb.mul(nb.sub(0.3, tri_v), 0.55)), 0.02, -0.02)))
    C.paint(nb.mul(tri, sticker), hexc("#D6A520"))
    lines = nb.mul(nb.band(nb.fract(nb.div(nb.sub(zi, lb["z"][0]), 0.14)), 0.35, 0.68, 0.02),
                   nb.band(yi, lb["y"][0] + 0.8, lb["y"][1] - 0.15, 0.02))
    words = nb.ss(L.noise(30.0, 10, stretch=(1.0, 1.0, 0.1), detail=1), 0.42, 0.46)
    C.paint(nb.mul(nb.mul(lines, words), nb.mul(sticker, 0.8)), hexc("#2E2E2C"))

    # the boot and the grip: black rubber moulded in rings, worn grey on what the hands rub
    bt, gr = L.k(BOOT), L.k(GRIP)
    rub = nb.add(bt, gr, clamp=True)
    C.rubber(rub)
    rings = nb.band(nb.fract(nb.div(yi, 0.34)), 0.2, 0.62, 0.12)
    C.paint(nb.mul(bt, nb.mul(rings, nb.ss(nb.absf(nb.sub(yi, 4.1)), 1.9, 1.6))),
            height=0.7)
    ribs = nb.band(nb.fract(nb.div(zi, 0.3)), 0.25, 0.7, 0.12)
    C.paint(nb.mul(gr, ribs), height=0.6)
    worn = nb.mul(rub, nb.ss(L.noise(5.0, 11, detail=4), 0.5, 0.66))
    C.paint(nb.mul(worn, 0.8), hexc("#2A2A2A"), 0.7)
    # the trigger and the clamp lever: black gloss plastic
    C.paint(L.k(TRIGGER), hexc("#141415"), nb.mr(L.noise(12.0, 12), 0.3, 0.7, 0.3, 0.4), 0.0)

    # the nose: cast aluminium, dull, mottled, grime in its pores
    no = L.k(NOSE)
    C.paint(no, nb.tint(hexc("#8D8F90"), nb.mr(L.noise(16.0, 13, detail=4), 0.3, 0.7, 0.7, 1.08)),
            nb.mr(L.noise(9.0, 14, detail=3), 0.3, 0.7, 0.45, 0.62), 0.85,
            nb.mul(nb.voronoi(L.vec(s=15), 80.0, feature="F1"), 0.2))

    # the shoe: blackened steel, rubbed back to bright steel on its edges and its face
    sh = L.k(SHOE)
    C.paint(sh, nb.tint(hexc("#242527"), nb.mr(L.noise(5.0, 16, detail=3), 0.3, 0.7, 0.85, 1.2)),
            nb.mr(L.noise(8.0, 17, detail=3), 0.3, 0.7, 0.45, 0.6), 0.8)
    rubbed = nb.mul(edge, nb.ss(L.noise(14.0, 18, detail=4), 0.45, 0.6))
    C.paint(nb.mul(rubbed, sh), hexc("#9A9C9E"), 0.35, 1.0)

    # the bolts: zinc plate, dulled
    bo = L.k(BOLT)
    C.paint(bo, nb.tint(hexc("#A7A9A4"), nb.mr(L.noise(20.0, 19, detail=3), 0.3, 0.7, 0.8, 1.05)),
            0.4, 1.0)

    # the blade: grey bimetal, a blue cast, brushed along its length, its teeth ground bright
    bl = L.k(BLADE)
    brushed = nb.mr(L.noise(200.0, 20, stretch=(1.0, 0.05, 1.0), detail=1), 0.3, 0.7, 0.88, 1.08)
    C.paint(bl, nb.tint(hexc("#6F7C88"), brushed), 0.42, 1.0)
    teeth = nb.mul(bl, nb.ss(zi, K.BLADE["bottom"] + K.TEETH_BAND + 0.02,
                             K.BLADE["bottom"] + K.TEETH_BAND - 0.02))
    C.paint(teeth, nb.tint(hexc("#C7CBCF"), brushed), 0.24, 1.0)
    weld = nb.mul(bl, nb.band(zi, K.BLADE["bottom"] + K.TEETH_BAND - 0.03,
                              K.BLADE["bottom"] + K.TEETH_BAND + 0.03, 0.01))
    C.paint(nb.mul(weld, 0.8), hexc("#3E3A36"), 0.5)
    rust = nb.mul(bl, nb.ss(L.noise(40.0, 21, detail=3), 0.66, 0.72))
    C.paint(rust, hexc("#6B4026"), 0.85, 0.2)
    # drywall dust on the blade's sides and the shoe's face: what it last cut
    chalk = nb.mul(nb.add(nb.mul(bl, nb.ss(zi, -0.2, -0.5)),
                          nb.mul(nb.mul(sh, L.front), nb.ss(zi, -0.9, -1.4)), clamp=True),
                   nb.ss(L.noise(16.0, 22, detail=5, rough=0.7), 0.56, 0.68))
    C.paint(nb.mul(chalk, 0.45), hexc("#D3CEC4"), 0.92, 0.0, 0.05)

    # the battery: black plastic, a green band where it latches, ribs on its sides, a charge
    # gauge of four dark windows on its back
    ba = L.k(BATTERY)
    C.paint(ba, nb.tint(hexc("#19191A"), nb.mr(L.noise(4.0, 23, detail=3), 0.3, 0.7, 0.85, 1.15)),
            nb.mr(L.noise(7.0, 24, detail=3), 0.3, 0.7, 0.5, 0.66), 0.0)
    band = nb.mul(ba, nb.ss(zi, -5.0, -4.9))
    C.paint(band, green, 0.48)
    b = K.BATTERY
    rib = nb.mul(nb.band(nb.fract(nb.div(yi, 0.42)), 0.3, 0.62, 0.06),
                 nb.mul(nb.band(zi, b[2] + 0.45, -5.25, 0.06), nb.band(yi, b[0] + 0.7, b[1] - 0.7, 0.05)))
    C.paint(nb.mul(nb.mul(rib, side), ba), height=-0.6)
    back = nb.ss(L.ny, 0.5, 0.8)
    gauge = None
    for k in range(4):
        dot = nb.mul(nb.ss(nb.absf(nb.sub(x, (k - 1.5) * 0.3 * K.IN)), 0.09 * K.IN, 0.06 * K.IN),
                     nb.band(zi, -5.45, -5.3, 0.02))
        gauge = dot if gauge is None else nb.add(gauge, dot, clamp=True)
    C.paint(nb.mul(nb.mul(gauge, back), ba), hexc("#1C4A26"), 0.2)
    scuffb = nb.mul(nb.mul(edge, ba), nb.ss(L.noise(10.0, 25, detail=5), 0.46, 0.6))
    C.paint(scuffb, hexc("#4A4A4A"), 0.8)

    C.finish(ao=0.25, ao_low=0.45, dust=K.DUST)
    return C.channels(dist=0.002, strength=0.6)


def stage_textures():
    kit.reset()
    objs = build_all(baking=True)
    kit.bake_set([(ob, bake.Rig(f"bk_{name}", look)) for name, ob in objs.items()], samples=32)


# --- export ---------------------------------------------------------------------------------

def piece(ob):
    lo, hi = box(ob)
    s, c = hi - lo, (lo + hi) / 2
    return dict(size=(s.x, s.z, s.y), centre=K.to_roblox(c), tris=kit.tris(ob))


def stage_export():
    kit.reset()
    objs = build_all(baking=False)
    ob = objs[K.SET]
    ob.data.materials.append(kit.material())
    os.makedirs(OUT, exist_ok=True)
    bpy.ops.object.select_all(action="DESELECT")
    ob.select_set(True)
    bpy.context.view_layer.objects.active = ob
    bpy.ops.export_scene.fbx(
        filepath=FBX, use_selection=True, object_types={"MESH"},
        apply_scale_options="FBX_SCALE_UNITS", axis_forward="Z", axis_up="Y",
        use_mesh_modifiers=True, mesh_smooth_type="OFF", use_tspace=False,
        add_leaf_bones=False, bake_anim=False, path_mode="COPY", embed_textures=True)
    body = piece(ob)
    print("FBX", FBX, {K.SET: body["tris"]})
    os.makedirs(os.path.dirname(SPECS), exist_ok=True)
    K.write_luau(SPECS, body)


# --- look sheets ----------------------------------------------------------------------------

# Roblox's frame to Blender's and back (the same matrix both ways): x = -X, y = Z, z = Y.
FLIP = Matrix(((-1, 0, 0, 0), (0, 0, 1, 0), (0, 1, 0, 0), (0, 0, 0, 1)))

# Where the game holds the saw in first person (src/shared/Tools/Catalog.luau, the row's `hold`
# and `holdTurn`): the camera's right, up and back in studs, then its turn in degrees (yaw left,
# pitch up, roll).
HOLD = ((-1.25, -1.1, -2.0), (-26.0, 10.0, 16.0))


def held(cam, offset, turn):
    """The saw's place in the world for a camera holding it at offset, turned (Roblox's camera
    space, which Blender's camera shares: -Z ahead, +Y up)."""
    yaw, pitch, roll = (math.radians(a) for a in turn)
    R = (Matrix.Rotation(yaw, 4, "Y") @ Matrix.Rotation(pitch, 4, "X")
         @ Matrix.Rotation(roll, 4, "Z"))
    return cam.matrix_world @ Matrix.Translation(Vector(offset)) @ R


def stage_renders():
    kit.reset()
    render.setup(96, (1600, 900))
    objs = build_all(baking=False)
    ob = objs[K.SET]
    ob.data.materials.append(kit.material())
    os.makedirs(SHEETS, exist_ok=True)

    # standing on its battery, as the game lays it: its lowest point on the floor
    lo, hi = box(ob)
    middle = -(lo.y + hi.y) / 2  # laid with its middle on the spot, not its grip

    def lay(at, yaw):
        ob.matrix_world = (Matrix.Translation(Vector(at)) @ Matrix.Rotation(math.radians(yaw), 4, "Z")
                           @ Matrix.Translation(Vector((0.0, middle, -lo.z))))

    # 1. in the studio: from the front three-quarter on your view's side (the blade, the shoe,
    #    the sticker), then from behind on the other (the grip, the trigger, the battery's gauge)
    studio = render.studio_rig()
    for o in studio:
        o.hide_render = False
    lay((0.0, 0.0, 0.0), 0)
    cam = render.camera((-3.3, -1.9, 1.5), (0.0, -0.1, 0.45), lens=35)
    render.shoot(cam, os.path.join(SHEETS, "saw-front.png"), exposure=-0.2)
    cam = render.camera((3.2, 2.1, 1.5), (0.0, 0.1, 0.45), lens=35)
    render.shoot(cam, os.path.join(SHEETS, "saw-back.png"), exposure=-0.2)
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
    bk.place(boxes, "Small", -3.9, 8.0, 0.0, 64)
    bulb = bpy.data.lights.new("bulb", "POINT")
    bulb.energy, bulb.color, bulb.shadow_soft_size = 220.0, (1.0, 0.674, 0.408), 0.08
    bo = bpy.data.objects.new("bulb", bulb)
    bpy.context.scene.collection.objects.link(bo)
    bo.location = (0.0, 6.0, 8.7)
    lay((0.5, 5.4, 0.0), 70)
    # 14.6 mm is Roblox's 70 degree view on a 16:9 screen
    cam = render.camera((0.0, -1.5, 4.6), (0.4, 5.0, 0.4), lens=14.6)
    render.shoot(cam, os.path.join(SHEETS, "saw-floor.png"), exposure=0.2)

    # 3. your view: held low on your left in the same unit, blade forward
    cam = render.camera((0.6, -1.0, 4.6), (-0.4, 9.0, 2.6), lens=14.6)
    bpy.context.view_layer.update()
    ob.matrix_world = held(cam, *HOLD) @ FLIP
    render.shoot(cam, os.path.join(SHEETS, "saw-view.png"), exposure=0.2)


STAGES = {"textures": stage_textures, "export": stage_export, "renders": stage_renders}

if __name__ == "__main__":
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    ap = argparse.ArgumentParser()
    ap.add_argument("--stage", choices=list(STAGES), required=True)
    STAGES[ap.parse_args(argv).stage]()
    print("DONE")
