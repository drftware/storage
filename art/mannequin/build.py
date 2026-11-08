"""Build the Mannequin in Blender, headless (art/mannequin/README.md).

    blender -b --factory-startup -P art/mannequin/build.py -- --stage textures|export|renders

Stages:
    textures  the Mannequin texture set, baked from its recipe into out/textures
    export    out/Mannequin.fbx (fifteen MeshParts, R15's body parts) and
              src/shared/Mannequin/Specs.luau
    renders   the look sheets, art/sheets/mannequin-*.png, posed from out/poses.json (written by
              `lune run scripts/mannequin-poses`, so the sheets wear the game's own poses)

It borrows the finds' atlas, bake and export (art/finds/build.py), pointed at its own spec and
out folder: each part smart-projected alone into its own square, the unwrap saved and worn by
every later stage, a coverage pass and padding after a margin-free bake.
"""

import argparse
import importlib.util
import json
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
POSES = os.path.join(OUT, "poses.json")


def finds_kit():
    """The finds' build, as a library: it imports `spec`, which is already this folder's, so its
    atlas size, set name and dust are the Mannequin's; its out paths are pointed here."""
    s = importlib.util.spec_from_file_location("finds_build", os.path.join(FINDS, "build.py"))
    mod = importlib.util.module_from_spec(s)
    s.loader.exec_module(mod)
    assert mod.K is K, "the finds' build must see the Mannequin's spec"
    mod.OUT, mod.TEX, mod.UVS, mod.FBX = OUT, TEX, os.path.join(OUT, "uvs.npz"), FBX
    return mod


kit = finds_kit()

# What a face is, for the recipe (a face attribute).
SKIN, HEAD, NECK, HAND, THUMB, FOOT = range(6)


# --- geometry --------------------------------------------------------------------------------

def sp(v, n):
    """A superellipse's coordinate: |v|^(2/n), keeping its sign."""
    return math.copysign(abs(v) ** (2.0 / n), v)


def ring_loft(m, rings, poles):
    """Rings of equal count joined in order, each end closed on a pole."""
    bm = bmesh.new()
    vs = [[bm.verts.new(p) for p in ring] for ring in rings]
    n = len(rings[0])
    for r0, r1 in zip(vs, vs[1:]):
        for i in range(n):
            bm.faces.new((r0[i], r0[(i + 1) % n], r1[(i + 1) % n], r1[i]))
    a, b = bm.verts.new(poles[0]), bm.verts.new(poles[1])
    for i in range(n):
        bm.faces.new((a, vs[0][(i + 1) % n], vs[0][i]))
        bm.faces.new((b, vs[-1][i], vs[-1][(i + 1) % n]))
    kit.solid(m, bm)


def dome(ring, centre, axis, h):
    """Rings closing a loft's end into a dome h tall along `axis`, and its pole: rounder for the
    shoulder's and hip's big balls, which show when the limb swings."""
    k = 4 if h >= 0.15 else 3
    out = []
    for j in range(1, k):
        t = math.pi / 2 * j / k
        c, s = math.cos(t), math.sin(t)
        out.append([tuple(centre[i] + (p[i] - centre[i]) * c + axis[i] * h * s for i in range(3))
                    for p in ring])
    pole = tuple(centre[i] + axis[i] * h for i in range(3))
    return out, pole


def lathe(m, stations, segs, caps, side=1):
    """A part lofted down through (z, half-width, half-depth, x, y, round) stations, domed at
    both ends; side -1 mirrors it to the right."""
    rings, centres = [], []
    for z, rx, ry, cx, cy, n in stations:
        ring = []
        for i in range(segs):
            a = 2 * math.pi * i / segs
            ring.append((side * (cx + rx * sp(math.cos(a), n)), cy + ry * sp(math.sin(a), n), z))
        rings.append(ring)
        centres.append((side * cx, cy, z))
    top, tpole = dome(rings[0], centres[0], (0, 0, 1), caps[0])
    bot, bpole = dome(rings[-1], centres[-1], (0, 0, -1), caps[1])
    ring_loft(m, list(reversed(top)) + rings + bot, (tpole, bpole))


def foot(m, side=1):
    """The foot lofted heel to toe through (y, x, half-width, top) stations, flat beneath."""
    F = K.FOOT
    segs = F["segs"]
    rings, centres = [], []
    for y, cx, hw, top in F["stations"]:
        zc, hh = top / 2, top / 2
        ring = []
        for i in range(segs):
            a = 2 * math.pi * i / segs
            ca, sa = math.cos(a), math.sin(a)
            e = 2.6 if sa >= 0 else 7.0  # round over the top, flat on the sole
            ring.append((side * (cx + hw * sp(ca, e)), y, zc + hh * sp(sa, e)))
        rings.append(ring)
        centres.append((side * cx, y, zc))
    heel, hpole = dome(rings[0], centres[0], (0, 1, 0), F["caps"][0])
    toe, tpole = dome(rings[-1], centres[-1], (0, -1, 0), F["caps"][1])
    ring_loft(m, list(reversed(heel)) + rings + toe, (hpole, tpole))


def head(m):
    """The faceless egg, point by point (so every stage numbers it alike): denser round the face,
    the skull deeper behind, the jaw narrowing to the chin, a brow and a nose and nothing else."""
    H = K.HEAD
    cx, cy, cz = H["centre"]
    rx, ry, rz = H["radii"]
    us, vs = H["us"], H["vs"]
    jt, jb, jk = H["jaw"]
    nz, nsx, nsz, nh = H["nose"]
    bz, bw, bs, bh = H["brow"]
    sz_, sx_, ss_, sd = H["sockets"]
    chz, chx, chs, chh = H["chin"]
    g = lambda v: math.exp(-v * v)  # noqa: E731

    def point(th, ph):
        ux, uy, uz = math.sin(th) * math.cos(ph), math.sin(th) * math.sin(ph), math.cos(th)
        x, y, z = rx * ux, ry * uy * (H["back"] if uy > 0 else H["front"]), cz + rz * uz
        t = min(max((jt - z) / (jt - jb), 0.0), 1.0) ** 1.4
        x *= 1.0 - (1.0 - jk) * t
        if y < 0:
            y *= 1.0 - 0.12 * t
        face = max(0.0, -uy) ** 2  # only the front
        push = nh * g(x / nsx) * g((z - nz) / (nsz if z > nz else nsz * 0.4))
        push += bh * g(max(abs(x) - bw, 0.0) / bs) * g((z - bz) / bs)
        push += chh * g(x / chx) * g((z - chz) / chs)
        push -= sd * (g((x - sx_) / ss_) + g((x + sx_) / ss_)) * g((z - sz_) / ss_)
        return (cx + x, cy + y - push * face, z)

    def warp(u):  # longitude, twice as dense round the face (which faces -Y) as behind
        return u - 0.5 * math.sin(u + math.pi / 2)

    top = m.vert(point(0.0, 0.0))
    for j in range(1, vs):
        for i in range(us):
            m.vert(point(math.pi * j / vs, warp(2 * math.pi * i / us)))
    bot = m.vert(point(math.pi, 0.0))

    def ring(j, i):
        return top + 1 + (j - 1) * us + i % us
    for i in range(us):
        m.face((top, ring(1, i), ring(1, i + 1)), None, True)
        for j in range(1, vs - 1):
            m.face((ring(j, i), ring(j + 1, i), ring(j + 1, i + 1), ring(j, i + 1)), None, True)
        m.face((bot, ring(vs - 1, i + 1), ring(vs - 1, i)), None, True)


def part_geo(name):
    side = K.side_of(name) or 1
    b = K.base(name)
    F = kit.Find(name)
    if b == "Head":
        F.add(HEAD, head)
        N = K.HEAD["neck"]
        F.add(NECK, lathe, N["stations"], N["segs"], N["caps"])
    elif b == "Foot":
        F.add(FOOT, foot, side)
    else:
        P = K.PARTS[b]
        F.add(HAND if b == "Hand" else SKIN, lathe, P["stations"], P["segs"], P["caps"], side)
        if b == "Hand":
            path, r = K.THUMB
            F.add(THUMB, geo.sweep, [(side * x, y, z) for x, y, z in path], r, segs=10)
    return F


def build_all(baking, coll=None):
    objs = {n: part_geo(n).build(80, coll) for n in K.ORDER}
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

def look(nb, name, lo, hi):
    """Ivory paint gone yellow over grey filler over glass fibre: satin where it's sound, chipped
    where it was knocked, a dark groove at every joint, dust on top."""
    L = kit.Look(nb, K.SEED + K.ORDER.index(name))
    x, y, z = L.x, L.y, L.z

    def dist(p):
        return nb.pw(nb.add(nb.add(nb.mul(nb.sub(x, p[0]), nb.sub(x, p[0])),
                                   nb.mul(nb.sub(y, p[1]), nb.sub(y, p[1]))),
                            nb.mul(nb.sub(z, p[2]), nb.sub(z, p[2]))), 0.5)

    def near(p, r):  # is p within r of this part's box
        return all(lo[i] - r <= p[i] <= hi[i] + r for i in range(3))

    # the paint: ivory, yellowed in drifts, a satin sheen with a faint orange peel
    yellow = nb.mr(L.noise(0.7, 1, detail=2), 0.35, 0.68, 0.0, 1.0)
    paint = nb.mixc(nb.mul(yellow, 0.6), hexc("#E4DCCB"), hexc("#D6C49E"))
    paint = nb.tint(paint, nb.mr(L.noise(2.4, 2, detail=4), 0.3, 0.7, 0.9, 1.04))
    C = kit.Coat(L, paint, nb.mr(L.noise(5.0, 3, detail=3), 0.3, 0.7, 0.28, 0.44), 0.0,
                 nb.mul(L.noise(240.0, 4, detail=1), 0.05))
    # handled: gone matte and grey where hands carried it (the waist, the upper arms, the shins)
    held = nb.mul(nb.ss(L.noise(3.0, 5, detail=4), 0.45, 0.72),
                  nb.add(nb.band(z, 3.7, 4.3, 0.2), nb.band(z, 4.4, 5.0, 0.2), clamp=True))
    C.paint(nb.mul(held, 0.5), hexc("#C4BBA9"), 0.62)
    # scuffs: short grey rubbery marks, more of them low down
    scuff = nb.ss(L.noise(8.0, 6, stretch=(0.3, 0.3, 1.6), detail=4), 0.64, 0.7)
    low = nb.add(nb.ss(z, 2.4, 0.9), 0.3, clamp=True)
    C.paint(nb.mul(nb.mul(scuff, low), 0.45), hexc("#827B70"), 0.66)

    # dirt: a grey-brown film low down, where the floor's grime splashed and hands didn't wipe
    dirt = nb.mul(nb.ss(z, 1.6, 0.2), nb.mr(L.noise(3.5, 13, detail=5), 0.3, 0.75, 0.15, 0.75))
    C.paint(dirt, nb.tint(C.col, 0.72), 0.7)

    # chips: knocked off at its edges and where it was bumped, down through the primer to the
    # grey filler, and in the deepest to the glass fibre's weave
    risk = nb.mul(nb.edge(0.03, k=3.0), 0.35)
    for p, r in K.KNOCKS:
        for q in ([p, K.mirror(p)] if p[0] != 0 else [p]):
            if near(q, r):
                risk = nb.add(risk, nb.ss(dist(q), r, r * 0.2))
    field = nb.add(L.noise(9.0, 7, detail=5, rough=0.62), nb.mul(nb.clamp(risk), 0.25))
    chip = nb.ss(field, 0.715, 0.73)
    rim = nb.sub(nb.ss(field, 0.69, 0.71), chip, clamp=True)
    deep = nb.mul(chip, nb.ss(nb.add(L.noise(22.0, 8, detail=3), nb.mul(field, 0.4)), 0.9, 0.93))
    C.paint(rim, hexc("#F3EFE6"), 0.5, height=0.15)
    filler = nb.tint(hexc("#ABA59A"), nb.mr(L.noise(40.0, 9, detail=3), 0.3, 0.7, 0.85, 1.08))
    C.paint(chip, filler, 0.86, height=-0.9)
    weave = nb.mul(nb.band(nb.fract(nb.mul(nb.add(x, z), 55.0)), 0.0, 0.45, 0.08),
                   nb.band(nb.fract(nb.mul(nb.sub(x, z), 55.0)), 0.0, 0.45, 0.08))
    fibre = nb.mixc(nb.mul(weave, 0.6), hexc("#7C735F"), hexc("#5C5445"))
    C.paint(deep, fibre, 0.9, height=nb.mul(weave, 0.4))
    C.paint(deep, height=-0.8)

    # the seams: a dark groove where two parts meet, grime gathered either side of it
    for jn, p0, p1, at, sm, sat in K.joints():
        if not sm or name not in (p0, p1):
            continue
        n, reach = sm
        d = nb.add(nb.add(nb.mul(nb.sub(x, sat[0]), n[0]), nb.mul(nb.sub(y, sat[1]), n[1])),
                   nb.mul(nb.sub(z, sat[2]), n[2]))
        by = nb.ss(dist(sat), reach + 0.06, reach)
        C.paint(nb.mul(nb.band(d, -0.05, 0.05, 0.04), nb.mul(by, 0.35)), hexc("#8E8270"))
        C.paint(nb.mul(nb.band(d, -0.006, 0.006, 0.003), by), hexc("#372F25"), 0.85, height=-1.4)

    # a hairline crack over the left of its skull, and one across its back
    for c, r in (((0.17, -0.06, 6.12), 0.2), ((-0.16, 0.3, 4.62), 0.24)):
        if near(c, r):
            edge = nb.voronoi(L.vec(s=11), 2.6, feature="DISTANCE_TO_EDGE")
            C.paint(nb.mul(nb.ss(edge, 0.016, 0.004), nb.ss(dist(c), r, r * 0.3)),
                    hexc("#2C251C"), 0.8, height=-1.0)

    # fingers pressed together, and toes, told by the grooves between them
    if K.base(name) == "Hand":
        side = nb.ss(nb.absf(L.nx), 0.3, 0.6)
        fing = nb.mul(nb.mul(L.k(HAND), nb.ss(z, 2.75, 2.70)), side)
        g = None
        for o in (-0.052, -0.004, 0.044):
            b = nb.band(y, o - 0.004, o + 0.004, 0.003)
            g = b if g is None else nb.add(g, b, clamp=True)
        C.paint(nb.mul(nb.mul(g, fing), 0.8), hexc("#6E655A"), height=-1.2)
    if K.base(name) == "Foot":
        top = nb.mul(nb.mul(L.k(FOOT), nb.ss(L.nz, 0.15, 0.45)), nb.ss(y, -0.44, -0.49))
        u = nb.sub(nb.absf(x), 0.335)
        g = None
        for o in (-0.05, -0.005, 0.04):
            b = nb.band(u, o - 0.004, o + 0.004, 0.003)
            g = b if g is None else nb.add(g, b, clamp=True)
        C.paint(nb.mul(nb.mul(g, top), 0.8), hexc("#6E655A"), height=-1.2)

    # where it stood in a shop window: the display stand's socket in the back of its right calf
    if name == "RightLowerLeg":
        c, r, w = K.STAND
        d = dist(c)
        back = nb.ss(L.ny, 0.2, 0.5)
        C.paint(nb.mul(nb.band(d, r, r + w, 0.003), back),
                nb.tint(hexc("#8A8B8C"), nb.mr(L.noise(60.0, 12, detail=3), 0.3, 0.7, 0.6, 1.1)),
                0.38, 1.0, 0.4)
        C.paint(nb.mul(nb.ss(d, r + 0.002, r - 0.004), back), hexc("#0A0806"), 0.95, 0.0, -2.0)

    C.finish(ao=0.18, ao_low=0.55, dust=K.DUST)
    return C.channels(dist=0.003, strength=0.55)


def stage_textures():
    kit.reset()
    objs = build_all(baking=True)
    rigs = []
    for name, ob in objs.items():
        lo, hi = box(ob)
        rigs.append((ob, bake.Rig(f"bk_{name}", lambda nb, n=name, a=lo, b=hi: look(nb, n, a, b))))
    kit.bake_set(rigs, samples=32)


# --- export ---------------------------------------------------------------------------------

def stage_export():
    kit.reset()
    objs = build_all(baking=False)
    mat = kit.material()
    rows = {}
    for name, ob in objs.items():
        ob.data.materials.append(mat)
        lo, hi = box(ob)
        s = hi - lo
        rows[name] = dict(size=(s.x, s.z, s.y), centre=tuple((lo + hi) / 2), tris=kit.tris(ob))
    os.makedirs(OUT, exist_ok=True)
    bpy.ops.object.select_all(action="DESELECT")
    for ob in objs.values():
        ob.select_set(True)
    bpy.context.view_layer.objects.active = objs["LowerTorso"]
    bpy.ops.export_scene.fbx(
        filepath=FBX, use_selection=True, object_types={"MESH"},
        apply_scale_options="FBX_SCALE_UNITS", axis_forward="Z", axis_up="Y",
        use_mesh_modifiers=True, mesh_smooth_type="OFF", use_tspace=False,
        add_leaf_bones=False, bake_anim=False, path_mode="COPY", embed_textures=True)
    print("FBX", FBX, sum(r["tris"] for r in rows.values()), "triangles",
          {n: r["tris"] for n, r in rows.items()})
    os.makedirs(os.path.join(K.ROOT, "src", "shared", "Mannequin"), exist_ok=True)
    K.write_luau(os.path.join(K.ROOT, "src", "shared", "Mannequin", "Specs.luau"), rows)


# --- look sheets ----------------------------------------------------------------------------

# Roblox's frame to Blender's and back (the same matrix both ways): x = -X, y = Z, z = Y.
FLIP = Matrix(((-1, 0, 0, 0), (0, 0, 1, 0), (0, 1, 0, 0), (0, 0, 0, 1)))


def poses():
    if not os.path.exists(POSES):
        print("ERROR no poses: run `lune run scripts/mannequin-poses` first (scripts/art.sh does)")
        return {}
    with open(POSES) as f:
        return json.load(f)


def figure(objs, pose, at, turn, copy=True):
    """One whole Mannequin posed (each part's Roblox transform turned into Blender's), stood at
    `at` turned `turn` degrees about Z."""
    place = Matrix.Translation(Vector(at)) @ Matrix.Rotation(math.radians(turn), 4, "Z")
    for name, ob in objs.items():
        o = ob.copy() if copy else ob
        if copy:
            bpy.context.scene.collection.objects.link(o)
        t = pose.get(name) if pose else None
        m = Matrix([t[0:4], t[4:8], t[8:12], t[12:16]]) if t else Matrix.Identity(4)
        o.matrix_world = place @ FLIP @ m @ FLIP


def stage_renders():
    kit.reset()
    render.setup(96, (1600, 900))
    objs = build_all(baking=False)
    mat = kit.material()
    for ob in objs.values():
        ob.data.materials.append(mat)
        ob.hide_render = True
    P = poses()
    os.makedirs(SHEETS, exist_ok=True)

    # 1. the line-up in the studio: standing as it's found, from behind, mid-step, mid-stride
    studio = render.studio_rig()
    for o in studio:
        o.hide_render = False
    shown = []
    for pose, x, turn in (("Still", -4.4, 0), ("Still", -1.5, 180), ("StepRight", 1.5, -35),
                          ("PassRight", 4.4, -90)):
        before = set(bpy.context.scene.objects)
        figure(objs, P.get(pose), (x, 0.0, 0.0), turn)
        shown += [o for o in bpy.context.scene.objects if o not in before]
    for o in shown:
        o.hide_render = False
    cam = render.camera((0.0, -16.0, 3.6), (0.0, 0.0, 3.1), lens=40)
    render.shoot(cam, os.path.join(SHEETS, "mannequin-lineup.png"), exposure=-0.2)
    cam = render.camera((-5.6, -2.3, 6.0), (-4.4, 0.0, 5.55), lens=50)
    render.shoot(cam, os.path.join(SHEETS, "mannequin-close.png"), exposure=-0.2)
    cam = render.camera((2.2, -2.4, 4.3), (1.5, 0.0, 3.6), lens=40)
    render.shoot(cam, os.path.join(SHEETS, "mannequin-close-b.png"), exposure=-0.2)
    for o in studio + shown:
        o.hide_render = True

    # 2. in a unit among its boxes, by the unit's dim bulb, seen from the doorway
    bk = kit.boxes_kit()
    bmat = bk.material(False)
    boxes, _, _ = bk.build_all(baking=False)
    for ob in boxes.values():
        ob.data.materials.append(bmat)
    render.world((0.003, 0.004, 0.006), 1.0)
    bk.unit_room(bpy.context.scene.collection)
    bk.place(boxes, "Wardrobe", -4.4, 10.6, 0.0, 6)
    bk.place(boxes, "Large", 2.4, 10.8, 0.0, 4)
    bk.place(boxes, "Medium", 2.35, 10.75, 2.4, -7)
    bk.place(boxes, "Open", 4.0, 7.6, 0.0, 28)
    bk.place(boxes, "Small", -3.9, 8.0, 0.0, 64)
    before = set(bpy.context.scene.objects)
    figure(objs, P.get("Still"), (-0.9, 8.2, 0.0), -12)
    fig = [o for o in bpy.context.scene.objects if o not in before]
    for o in fig:
        o.hide_render = False
    bulb = bpy.data.lights.new("bulb", "POINT")
    bulb.energy = 220.0
    bulb.color = (1.0, 0.674, 0.408)
    bulb.shadow_soft_size = 0.08
    bo = bpy.data.objects.new("bulb", bulb)
    bpy.context.scene.collection.objects.link(bo)
    bo.location = (0.0, 6.0, 8.7)
    hall = bk.light("hall", "AREA", (0.0, -3.0, 9.0), (0.0, 3.0, 0.0), 90.0, (0.85, 0.92, 1.0), size=6.0)
    cam = render.camera((1.1, -2.2, 4.5), (-0.6, 8.0, 3.2), lens=26)
    render.shoot(cam, os.path.join(SHEETS, "mannequin-unit.png"), exposure=0.2)

    # 3. the next time your light finds it: the bulb out, a step nearer, reaching
    for o in fig:
        o.hide_render = True
    bo.hide_render = hall.hide_render = True
    before = set(bpy.context.scene.objects)
    figure(objs, P.get("StepRight"), (0.4, 5.2, 0.0), 8)
    for o in bpy.context.scene.objects:
        if o not in before:
            o.hide_render = False
    cam = render.camera((-2.3, -0.9, 4.7), (0.4, 6.0, 3.9), lens=26)
    render.flashlight(cam, True, (0.4, 5.2, 3.8))
    render.shoot(cam, os.path.join(SHEETS, "mannequin-torch.png"), exposure=0.1)


STAGES = {"textures": stage_textures, "export": stage_export, "renders": stage_renders}

if __name__ == "__main__":
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    ap = argparse.ArgumentParser()
    ap.add_argument("--stage", choices=list(STAGES), required=True)
    STAGES[ap.parse_args(argv).stage]()
    print("DONE")
