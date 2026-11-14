"""Build the Packrat in Blender, headless (art/packrat/README.md).

    blender -b --factory-startup -P art/packrat/build.py -- --stage textures|export|renders

Stages:
    textures  the Packrat texture set, baked from its recipe into out/textures
    export    out/Packrat.fbx (fifteen MeshParts, R15's body parts) and
              src/shared/Packrat/Specs.luau
    renders   the look sheets, art/sheets/packrat-*.png, posed from out/poses.json (written by
              `lune run scripts/packrat-poses`, so the sheets wear the game's own poses)

Made the Mannequin's way (art/mannequin/build.py): parts lofted through stations, the finds'
atlas, bake and export borrowed and pointed at this spec and out folder. Its own: the blanket's
creases and the tape's pinch in the loft, and a recipe of quilted grey blanket, tan tape and
pale skin.
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
BEDROOM = os.path.join(FINDS, "out", "Bedroom.fbx")


def finds_kit():
    """The finds' build as a library, seeing this folder's spec, its out paths pointed here."""
    s = importlib.util.spec_from_file_location("finds_build", os.path.join(FINDS, "build.py"))
    mod = importlib.util.module_from_spec(s)
    s.loader.exec_module(mod)
    assert mod.K is K, "the finds' build must see the Packrat's spec"
    mod.OUT, mod.TEX, mod.UVS, mod.FBX = OUT, TEX, os.path.join(OUT, "uvs.npz"), FBX
    return mod


kit = finds_kit()

# What a face is, for the recipe (a face attribute).
BLANKET, SKIN, HAND, THUMB, FOOT = range(5)


# --- geometry --------------------------------------------------------------------------------

def sp(v, n):
    return math.copysign(abs(v) ** (2.0 / n), v)


def ring_loft(m, rings, poles):
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
    k = 4 if h >= 0.15 else 3
    out = []
    for j in range(1, k):
        t = math.pi / 2 * j / k
        c, s = math.cos(t), math.sin(t)
        out.append([tuple(centre[i] + (p[i] - centre[i]) * c + axis[i] * h * s for i in range(3))
                    for p in ring])
    return out, tuple(centre[i] + axis[i] * h for i in range(3))


def tape_at(x, y, z):
    """How much tape is round this point at rest: 0 to 1, soft at a band's edges."""
    t = 0.0
    for z0, tx, ty, w in K.TAPE:
        d = abs(z - (z0 + tx * x + ty * y)) - w / 2
        t = max(t, min(max(-d / 0.02, 0.0), 1.0))
    return t


def crease(p, c, folds, seed, hollow=False):
    """A blanket's point pushed out or in by its creases (running down and round it, as a
    blanket hangs and wraps), and pulled in where tape binds it."""
    dx, dy = p[0] - c[0], p[1] - c[1]
    r = math.hypot(dx, dy)
    if r < 1e-6:
        return p
    a, z = math.atan2(dy, dx), p[2]
    f = (0.45 * math.sin(2 * a + 1.2 * z + seed) + 0.35 * math.sin(3 * a + 2.3 * z + 2 * seed)
         + 0.20 * math.sin(7 * a - 1.9 * z + 3 * seed))
    d = folds * f - K.PINCH * r * tape_at(*p)
    if hollow:
        (hx, hy, hz), reach, deep = K.HOLLOW
        g = math.exp(-((p[0] - hx) ** 2 + (p[1] - hy) ** 2 + (z - hz) ** 2) / reach ** 2)
        d -= deep * g
    return (p[0] + dx / r * d, p[1] + dy / r * d, z)


def lathe(m, P, side, seed, hollow=False):
    """A part lofted down through its stations, domed at both ends, creased if it's blanket;
    side -1 mirrors it to the right."""
    segs, folds = P["segs"], P["folds"]
    rings, centres = [], []
    for z, rx, ry, cx, cy, n in P["stations"]:
        rings.append([(side * (cx + rx * sp(math.cos(2 * math.pi * i / segs), n)),
                       cy + ry * sp(math.sin(2 * math.pi * i / segs), n), z) for i in range(segs)])
        centres.append((side * cx, cy, z))
    top, tpole = dome(rings[0], centres[0], (0, 0, 1), P["caps"][0])
    bot, bpole = dome(rings[-1], centres[-1], (0, 0, -1), P["caps"][1])
    cs = [centres[0]] * len(top) + centres + [centres[-1]] * len(bot)
    all_rings = list(reversed(top)) + rings + bot
    if folds > 0:
        all_rings = [[crease(p, c, folds, seed, hollow) for p in ring] for ring, c in zip(all_rings, cs)]
    ring_loft(m, all_rings, (tpole, bpole))


def foot(m, side):
    """The blanket bundled round the foot like a sack, lofted heel to toe, flat beneath."""
    F = K.FOOT
    segs = F["segs"]
    rings, centres = [], []
    for y, cx, hw, top in F["stations"]:
        zc, hh = top / 2, top / 2
        ring = []
        for i in range(segs):
            a = 2 * math.pi * i / segs
            ca, sa = math.cos(a), math.sin(a)
            e = 2.4 if sa >= 0 else 7.0
            ring.append((side * (cx + hw * sp(ca, e)), y, zc + hh * sp(sa, e)))
        rings.append(ring)
        centres.append((side * cx, y, zc))
    heel, hpole = dome(rings[0], centres[0], (0, 1, 0), F["caps"][0])
    toe, tpole = dome(rings[-1], centres[-1], (0, -1, 0), F["caps"][1])
    ring_loft(m, list(reversed(heel)) + rings + toe, (hpole, tpole))


def part_geo(name):
    side = K.side_of(name) or 1
    b = K.base(name)
    F = kit.Find(name)
    if b == "Foot":
        F.add(FOOT, foot, side)
        return F
    P = K.PARTS[b]
    kind = HAND if b == "Hand" else SKIN if P["stuff"] == K.SKIN else BLANKET
    F.add(kind, lathe, P, side, K.SEED + K.ORDER.index(name) * 1.7, b == "Head")
    if b == "Hand":
        path, r = K.THUMB
        F.add(THUMB, geo.sweep, [(side * x, y, z) for x, y, z in path], r, segs=10)
    return F


def build_all(baking):
    objs = {n: part_geo(n).build(70) for n in K.ORDER}
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

def blanket(nb, L, C, name):
    """Quilted grey moving blanket: diamond stitching puffed between, a darker binding where one
    blanket's edge crosses another, tan packing tape wound round, grime low down."""
    x, y, z = L.x, L.y, L.z
    grey = hexc(K.GREYS[K.base(name)])
    C.col = nb.tint(grey, nb.mr(L.noise(1.1, 1, detail=3), 0.3, 0.7, 0.82, 1.1))
    C.rough = nb.mr(L.noise(6.0, 2, detail=3), 0.3, 0.7, 0.86, 0.97)
    # the quilting: two sets of stitched diagonals, wobbling as a machine sews them
    u = nb.add(nb.add(x, nb.mul(y, 0.8)), nb.mul(L.noise(2.0, 3, detail=2), 0.08))
    lines, cells = [], []
    for sgn in (1.0, -1.0):
        v = nb.div(nb.add(u, nb.mul(z, sgn)), K.QUILT)
        tri = nb.absf(nb.sub(nb.fract(v), 0.5))
        lines.append(nb.ss(tri, 0.47, 0.49))
        cells.append(nb.mul(tri, 2.0))
    stitch = nb.add(lines[0], lines[1], clamp=True)
    puff = nb.mn(nb.inv(cells[0]), nb.inv(cells[1]))
    C.paint(puff, height=0.55)
    C.paint(nb.mul(stitch, 0.55), nb.tint(C.col, 0.62), height=-0.7)
    # a lighter fuzz where the weave is worn on the puffs
    C.paint(nb.mul(nb.mul(puff, nb.ss(L.noise(30.0, 4, detail=2), 0.55, 0.75)), 0.4),
            nb.tint(grey, 1.25))
    # one blanket's edge over another: its binding, a dark strip stitched down
    for p, n in K.EDGES:
        for q, m in ([(p, n), (K.mirror(p), K.mirror(n))] if p[0] != 0 else [(p, n)]):
            d = nb.add(nb.add(nb.mul(nb.sub(x, q[0]), m[0]), nb.mul(nb.sub(y, q[1]), m[1])),
                       nb.mul(nb.sub(z, q[2]), m[2]))
            bind = nb.band(d, 0.0, 0.1, 0.008)
            C.paint(bind, hexc("#3B3D40"), 0.8, height=0.6)
            C.paint(nb.mul(nb.band(d, 0.07, 0.078, 0.003), 0.7), hexc("#26282A"), height=-0.5)
            C.paint(nb.band(d, -0.01, 0.0, 0.006), height=-0.6)
    # packing tape wound round: amber, glossy, wrinkled across, edges lifting and pale
    tape = None
    for z0, tx, ty, w in K.TAPE:
        d = nb.sub(z, nb.add(nb.add(z0, nb.mul(x, tx)), nb.mul(y, ty)))
        one = nb.band(d, -w / 2, w / 2, 0.006)
        tape = one if tape is None else nb.add(tape, one, clamp=True)
        C.paint(nb.mul(nb.band(d, -w / 2 + 0.04, -w / 2 + 0.046, 0.002), 0.6), height=-0.5)
        C.paint(nb.mul(nb.band(d, w / 2 - 0.012, w / 2, 0.004), 0.45), hexc("#C2A97E"))
    amber = nb.tint(hexc("#9C8158"), nb.mr(L.noise(4.0, 5, detail=3), 0.3, 0.7, 0.8, 1.1))
    amber = nb.mixc(nb.mul(nb.ss(L.noise(1.6, 6, detail=2), 0.5, 0.75), 0.7), amber,
                    hexc("#5E4D38"))
    wrinkle = L.noise(9.0, 7, stretch=(3.0, 3.0, 0.4), detail=3)
    C.paint(tape, amber, nb.mr(wrinkle, 0.3, 0.7, 0.22, 0.42), 0.0,
            nb.add(nb.mul(nb.mr(wrinkle, 0.3, 0.7, -0.4, 0.4), 1.0), 0.35))
    # the hood's opening: nothing in it but dark
    if name == "Head":
        (hx, hy, hz), reach, _ = K.HOLLOW
        dd = nb.pw(nb.add(nb.add(nb.mul(nb.sub(x, hx), nb.sub(x, hx)), nb.mul(nb.sub(y, hy), nb.sub(y, hy))),
                          nb.mul(nb.sub(z, hz), nb.sub(z, hz))), 0.5)
        C.paint(nb.ss(dd, reach * 1.05, reach * 0.55), hexc("#0D0E0F"), 0.97)
    # grime: the floor's dirt on its legs and feet and hem, darker in the creases
    low = nb.ss(z, 1.4, 0.15)
    C.paint(nb.mul(low, nb.mr(L.noise(3.0, 8, detail=5), 0.3, 0.75, 0.25, 0.85)),
            nb.tint(C.col, 0.6), 0.95)
    C.finish(ao=0.22, ao_low=0.42, dust=K.DUST)


def skin(nb, L, C, name):
    """Pale, bloodless skin: mottled, waxy, darker at the knuckles and elbows, the fingertips
    grimed and their nails yellow-grey, dark where the arm goes into the blanket."""
    x, y, z = L.x, L.y, L.z
    C.col = nb.tint(hexc("#C4BDB0"), nb.mr(L.noise(2.5, 11, detail=4), 0.3, 0.7, 0.8, 1.04))
    C.rough = nb.mr(L.noise(12.0, 12, detail=3), 0.3, 0.7, 0.42, 0.62)
    C.paint(nb.mul(nb.ss(L.noise(1.2, 13, detail=3), 0.45, 0.72), 0.55), hexc("#9EA2A3"))
    C.paint(nb.mul(nb.ss(L.noise(3.4, 16, detail=4), 0.55, 0.8), 0.5), hexc("#8A8276"), 0.7)
    vein = nb.voronoi(L.vec(1.0, 1.0, 0.35, s=14), 6.0, feature="DISTANCE_TO_EDGE")
    C.paint(nb.mul(nb.ss(vein, 0.03, 0.006), 0.35), hexc("#8E97A0"), height=0.25)
    C.paint(nb.mul(nb.ss(L.noise(40.0, 15, detail=3), 0.6, 0.75), 0.4), height=-0.3)
    b = K.base(name)
    s = K.side_of(name)
    for jn, p0, p1, at in K.joints():
        if name in (p0, p1) and ("Elbow" in jn or "Wrist" in jn):
            dd = nb.pw(nb.add(nb.add(nb.mul(nb.sub(x, at[0]), nb.sub(x, at[0])),
                                     nb.mul(nb.sub(y, at[1]), nb.sub(y, at[1]))),
                              nb.mul(nb.sub(z, at[2]), nb.sub(z, at[2]))), 0.5)
            C.paint(nb.mul(nb.ss(dd, 0.16, 0.04), 0.6), hexc("#9C9284"), 0.7, height=-0.2)
    if b == "UpperArm":
        C.paint(nb.ss(z, 5.62, 5.82), hexc("#2A2724"), 0.9)
    if b == "Hand":
        fing = nb.mul(L.k(HAND), nb.ss(z, 2.42, 2.36))
        g = None
        for o in (-0.048, -0.004, 0.04):
            band = nb.band(y, o - 0.005, o + 0.005, 0.003)
            g = band if g is None else nb.add(g, band, clamp=True)
        C.paint(nb.mul(nb.mul(g, fing), 0.85), hexc("#6E655A"), height=-1.2)
        knuck = nb.mul(nb.band(z, 2.40, 2.50, 0.03), nb.ss(nb.mul(L.nx, float(-s)), 0.2, 0.6))
        C.paint(nb.mul(knuck, 0.6), hexc("#9A8F80"), height=0.3)
        tips = nb.ss(z, 2.2, 2.1)
        C.paint(nb.mul(tips, 0.7), hexc("#6F6556"), 0.7)
        nail = nb.mul(nb.mul(tips, nb.ss(z, 2.16, 2.12)), nb.ss(nb.mul(L.nx, float(s)), 0.3, 0.7))
        C.paint(nail, hexc("#9B9175"), 0.3, height=0.4)
    C.finish(ao=0.2, ao_low=0.5, dust=0.0)


def look(nb, name):
    L = kit.Look(nb, K.SEED + K.ORDER.index(name))
    C = kit.Coat(L, hexc("#808080"), 0.9)
    (blanket if K.stuff(name) == K.BLANKET else skin)(nb, L, C, name)
    return C.channels(dist=0.003, strength=0.6)


def stage_textures():
    kit.reset()
    objs = build_all(baking=True)
    rigs = [(ob, bake.Rig(f"bk_{n}", lambda nb, n=n: look(nb, n))) for n, ob in objs.items()]
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
    print("FBX", FBX, sum(r["tris"] for r in rows.values()), "triangles")
    os.makedirs(os.path.join(K.ROOT, "src", "shared", "Packrat"), exist_ok=True)
    K.write_luau(os.path.join(K.ROOT, "src", "shared", "Packrat", "Specs.luau"), rows)


# --- look sheets ----------------------------------------------------------------------------

# Roblox's frame to Blender's and back (the same matrix both ways): x = -X, y = Z, z = Y.
FLIP = Matrix(((-1, 0, 0, 0), (0, 0, 1, 0), (0, 1, 0, 0), (0, 0, 0, 1)))


def mat4(t):
    return Matrix([t[0:4], t[4:8], t[8:12], t[12:16]])


def figure(objs, pose, at, turn, carry=None):
    """One whole Packrat posed, stood at `at` turned `turn` degrees about Z; with `carry`, that
    find (a Blender object, its middle at its origin) held at the pose's Carry point."""
    place = Matrix.Translation(Vector(at)) @ Matrix.Rotation(math.radians(turn), 4, "Z")
    made = []
    for name, ob in objs.items():
        o = ob.copy()
        bpy.context.scene.collection.objects.link(o)
        o.matrix_world = place @ FLIP @ mat4(pose[name]) @ FLIP
        o.hide_render = False
        made.append(o)
    if carry is not None:
        o = carry.copy()
        bpy.context.scene.collection.objects.link(o)
        o.matrix_world = place @ FLIP @ mat4(pose["Carry"]) @ FLIP
        o.hide_render = False
        made.append(o)
    return made


def the_find(name):
    """A bedroom find from its FBX, its middle moved to its origin, hidden; the others dropped."""
    before = set(bpy.data.objects)
    bpy.ops.import_scene.fbx(filepath=BEDROOM, axis_forward="Z", axis_up="Y")
    keep = None
    for o in set(bpy.data.objects) - before:
        if o.name.startswith(name) and o.type == "MESH":
            keep = o
        else:
            bpy.data.objects.remove(o)
    bpy.context.view_layer.update()
    lo, hi = box(keep)
    mid = (lo + hi) / 2
    keep.data.transform(Matrix.Translation(-mid))
    keep.matrix_world = Matrix.Identity(4)
    keep.hide_render = True
    print("FIND", name, tuple(round(v, 2) for v in (hi - lo)))
    return keep


def hall(coll):
    """A plain storage hall for the far shot: floor, two walls, a ceiling, strip lights."""
    dark = render.simple("hall_wall", hexc("#4A4D50"), 0.8)
    floor = render.simple("hall_floor", hexc("#3C3B39"), 0.6)
    render.box_obj("hall_floor", (-4.5, -6.0, -0.2), (4.5, 60.0, 0.0), floor, coll)
    render.box_obj("hall_l", (-4.7, -6.0, 0.0), (-4.5, 60.0, 10.0), dark, coll)
    render.box_obj("hall_r", (4.5, -6.0, 0.0), (4.7, 60.0, 10.0), dark, coll)
    render.box_obj("hall_top", (-4.7, -6.0, 10.0), (4.7, 60.0, 10.2), dark, coll)
    for i, y in enumerate((4.0, 16.0, 28.0, 40.0)):
        ld = bpy.data.lights.new(f"strip{i}", "AREA")
        ld.shape, ld.size, ld.size_y = "RECTANGLE", 0.4, 3.5
        ld.energy, ld.color = 500.0, (0.86, 0.93, 1.0)
        lo = bpy.data.objects.new(f"strip{i}", ld)
        lo.location = (0.0, y, 9.6)
        coll.objects.link(lo)


def stage_renders():
    kit.reset()
    render.setup(96, (1600, 900))
    objs = build_all(baking=False)
    mat = kit.material()
    for ob in objs.values():
        ob.data.materials.append(mat)
        ob.hide_render = True
    if not os.path.exists(POSES):
        print("ERROR no poses: run `lune run scripts/packrat-poses` first (scripts/art.sh does)")
        return
    with open(POSES) as f:
        P = json.load(f)
    teddy = the_find("Teddy")
    os.makedirs(SHEETS, exist_ok=True)

    # 1. the line-up in the studio: as it's found, arms empty, arms full, and full from the side
    studio = render.studio_rig()
    for o in studio:
        o.hide_render = False
    shown = []
    for pose, x, turn, find in (("Still", -6.0, 0, None), ("EmptyStepRight", -2.0, -15, None),
                                ("FullStepRight", 2.0, 15, teddy), ("FullPassRight", 6.0, -90, teddy)):
        shown += figure(objs, P[pose], (x, 0.0, 0.0), turn, find)
    cam = render.camera((0.0, -19.0, 4.0), (0.0, 0.0, 3.6), lens=38)
    render.shoot(cam, os.path.join(SHEETS, "packrat-lineup.png"), exposure=-0.2)
    cam = render.camera((0.6, -6.2, 5.6), (2.0, 0.0, 5.0), lens=40)
    render.shoot(cam, os.path.join(SHEETS, "packrat-close.png"), exposure=-0.2)
    for o in studio + shown:
        o.hide_render = True

    # 2. from a hall's end at a phone's size: arms empty on the left, full on the right, 30 studs
    # off under the hall's strip lights (Roblox's camera: 70 degrees tall)
    sc = bpy.context.scene
    sc.render.resolution_x, sc.render.resolution_y = 844, 390
    render.world((0.004, 0.005, 0.007), 1.0)
    hall(sc.collection)
    figure(objs, P["EmptyStepRight"], (-1.6, 30.0, 0.0), 180 + 180, None)
    figure(objs, P["FullStepRight"], (1.6, 30.0, 0.0), 180 + 180, teddy)
    cam = render.camera((0.0, 0.0, 4.6), (0.0, 30.0, 3.6), lens=24)
    cam.data.sensor_fit = "VERTICAL"
    cam.data.angle_y = math.radians(70)
    render.shoot(cam, os.path.join(SHEETS, "packrat-hall.png"), exposure=0.0)


STAGES = {"textures": stage_textures, "export": stage_export, "renders": stage_renders}

if __name__ == "__main__":
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    ap = argparse.ArgumentParser()
    ap.add_argument("--stage", choices=list(STAGES), required=True)
    STAGES[ap.parse_args(argv).stage]()
    print("DONE")
