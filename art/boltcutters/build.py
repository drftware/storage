"""Build the bolt cutters in Blender, headless (art/boltcutters/README.md).

    blender -b --factory-startup -P art/boltcutters/build.py -- --stage textures|export|renders

Stages:
    textures  the BoltCutters texture set, baked from its recipe into out/textures
    export    out/BoltCutters.fbx (one MeshPart) and src/shared/Tools/Specs/BoltCutters.luau
    renders   the look sheets, art/sheets/boltcutters-*.png

It borrows the finds' atlas, bake and export (art/finds/build.py), pointed at its own spec and out
folder, as the flashlight does.
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
SPECS = os.path.join(K.ROOT, "src", "shared", "Tools", "Specs", "BoltCutters.luau")


def finds_kit():
    """The finds' build, as a library: it imports `spec`, which is already this folder's, so its
    atlas size, set name and dust are the cutters'; its out paths are pointed here."""
    s = importlib.util.spec_from_file_location("finds_build", os.path.join(FINDS, "build.py"))
    mod = importlib.util.module_from_spec(s)
    s.loader.exec_module(mod)
    assert mod.K is K, "the finds' build must see the bolt cutters' spec"
    mod.OUT, mod.TEX, mod.UVS, mod.FBX = OUT, TEX, os.path.join(OUT, "uvs.npz"), FBX
    return mod


kit = finds_kit()

# What a face is, for the recipe (a face attribute).
JAW, PLATE, BOLT, HANDLE, GRIP, STOP = range(6)


# --- geometry --------------------------------------------------------------------------------

def g(x, y, z):
    """A point measured from the head's middle, moved to be measured from the grip."""
    return Vector((x, y - K.GRIP_Y, z))


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


def jaw(m, side):
    """One beak of the jaw: a double-bevelled cutting edge on the middle line, thickening out to
    a chamfered back, from its tip back under the plates."""
    secs = []
    for y, xi, xo in K.JAW:
        span = xo - xi
        w = min(K.EDGE_W, span * 0.6)
        c = min(K.CHAMFER, span * 0.2)
        t, e = K.JAW_T, K.EDGE_T
        ring = [(xi, e), (xi + w, t), (xo - c, t), (xo, t - c), (xo, -t + c), (xo - c, -t),
                (xi + w, -t), (xi, -e)]
        secs.append([g(side * x, y, z) for x, z in ring])
    loft(m, secs)


def plate(m, up):
    """One of the head's plates, its outer face chamfered round the edge."""
    z0, z1 = K.PLATE_Z
    c = K.CHAMFER
    secs = []
    for y, hw in K.PLATE:
        ring = [(-hw, z0), (hw, z0), (hw, z1 - c), (hw - c, z1), (-hw + c, z1), (-hw, z1 - c)]
        secs.append([g(x, y, up * z) for x, z in ring])
    loft(m, secs)


def bolts(m):
    _, z1 = K.PLATE_Z
    for x, y in K.BOLTS:
        geo.hexbolt(m, g(x, y, z1), "z", 1, K.BOLT_ACROSS, K.BOLT_HEIGHT)
        geo.hexbolt(m, g(x, y, -z1), "z", -1, K.BOLT_ACROSS * 0.9, K.BOLT_HEIGHT * 0.8)


def spline(pts, n):
    """A Catmull-Rom curve through (y, x) points, n points along it, as (x, y) pairs."""
    P = [Vector((x, y)) for y, x in pts]
    P = [P[0] * 2 - P[1]] + P + [P[-1] * 2 - P[-2]]
    out = []
    for k in range(n):
        t = k / (n - 1) * (len(pts) - 1)
        i = min(int(t), len(pts) - 2)
        u = t - i
        p0, p1, p2, p3 = P[i], P[i + 1], P[i + 2], P[i + 3]
        out.append(0.5 * ((2 * p1) + (-p0 + p2) * u + (2 * p0 - 5 * p1 + 4 * p2 - p3) * u * u
                          + (-p0 + 3 * p1 - 3 * p2 + p3) * u * u * u))
    return [(v.x, v.y) for v in out]


def handle_at(y):
    """The right handle's x at y, read off its curve."""
    pts = spline(K.HANDLE, 64)
    for (xa, ya), (xb, yb) in zip(pts, pts[1:]):
        if ya <= y <= yb:
            return xa + (xb - xa) * (y - ya) / (yb - ya)
    return pts[-1][0]


def tube(m, path, radii, segs, round_end=False):
    """A round tube along a 3D path with a radius at each point; its end rounded shut on a pole
    when round_end."""
    rings = []
    for i, p in enumerate(path):
        t = (path[min(i + 1, len(path) - 1)] - path[max(i - 1, 0)]).normalized()
        a = t.cross(Vector((0, 0, 1))).normalized()
        b = t.cross(a).normalized()
        rings.append([p + radii[i] * (math.cos(2 * math.pi * k / segs) * a
                                      + math.sin(2 * math.pi * k / segs) * b) for k in range(segs)])
    bm = bmesh.new()
    vs = [[bm.verts.new(p) for p in r] for r in rings]
    for r0, r1 in zip(vs, vs[1:]):
        for k in range(segs):
            bm.faces.new((r0[k], r0[(k + 1) % segs], r1[(k + 1) % segs], r1[k]))
    bm.faces.new(vs[0])
    if round_end:
        tip = bm.verts.new(path[-1] + (path[-1] - path[-2]).normalized() * radii[-1] * 0.55)
        for k in range(segs):
            bm.faces.new((vs[-1][k], vs[-1][(k + 1) % segs], tip))
    else:
        bm.faces.new(list(reversed(vs[-1])))
    kit.solid(m, bm)


def handle(m, side):
    """The steel tube, from inside the head to just under the grip's front."""
    pts = [(x, y) for x, y in spline(K.HANDLE, 18) if y <= K.GRIP[0] + 0.06]
    path = [g(side * x, y, 0.0) for x, y in pts]
    tube(m, path, [K.HANDLE_R] * len(path), 10)


def grip(m, side):
    """The rubber sleeve over the handle's end, its front a lip and its end rounded."""
    y0, y1 = K.GRIP
    n = 14
    ys = [y0 + (y1 - y0) * k / (n - 1) for k in range(n)]
    path = [g(side * handle_at(y), y, 0.0) for y in ys]
    radii = [K.GRIP_R * (0.86 if k == 0 else 1.0) for k in range(n)]
    tube(m, path, radii, 16, round_end=True)


def stop(m, side):
    """A rubber bumper on the handle's inner side behind the head."""
    y = K.STOP["y"]
    x = handle_at(y) - K.HANDLE_R - K.STOP["r"] * 0.6
    kit.ellipsoid(m, g(side * x, y, 0.0), (K.STOP["r"] * 1.1, K.STOP["r"] * 1.3, K.STOP["r"]),
                  (0, 0), 10, 6)


def cutters_geo():
    F = kit.Find(K.SET)
    for side in (1, -1):
        F.add(JAW, jaw, side)
    for up in (1, -1):
        F.add(PLATE, plate, up)
    F.add(BOLT, bolts)
    for side in (1, -1):
        F.add(HANDLE, handle, side)
        F.add(GRIP, grip, side)
        F.add(STOP, stop, side)
    return F


def build_all(baking, coll=None):
    objs = {K.SET: cutters_geo().build(40, coll)}
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
    """Red enamel on the handles, chipped and scratched to steel where they knock about; black
    rubber grips worn shiny where the palms go; black-painted plates scuffed at their edges;
    zinc bolts; a dark forged jaw with its cutting edges ground bright."""
    L = kit.Look(nb, K.SEED)
    x, y, z = L.x, L.y, L.z
    ax = nb.absf(x)

    # the handles: red enamel, a little uneven, over steel tube
    red = nb.tint(hexc("#BF2A1E"), nb.mr(L.noise(3.0, 1, detail=4), 0.3, 0.7, 0.85, 1.1))
    grain = L.noise(240.0, 2, detail=1)
    C = kit.Coat(L, red, nb.mr(L.noise(5.0, 3, detail=3), 0.3, 0.7, 0.3, 0.42), 0.0,
                 nb.mul(grain, 0.04))
    tube = L.k(HANDLE)
    steel = hexc("#8E9092")
    # chips: bare steel where the paint flaked, most along the outer side and near the head
    chip = nb.ss(L.noise(9.0, 4, detail=5, rough=0.7), 0.6, 0.64)
    outer = nb.mr(nb.mul(L.nx, nb.math("SIGN", x)), -0.2, 1.0, 0.3, 1.0)
    C.paint(nb.mul(nb.mul(chip, outer), tube), steel, 0.38, 1.0, height=-0.4)
    # scratches along the tube, pale through the enamel
    scr = nb.band(L.noise(4.0, 5, stretch=(1.0, 0.18, 1.0), detail=2), 0.497, 0.503, 0.001)
    C.paint(nb.mul(nb.mul(scr, nb.ss(L.noise(2.0, 6), 0.5, 0.62)), tube), hexc("#C6A69C"), 0.5,
            height=-0.2)

    # the grips: black rubber with moulded rings, polished a little where the palms go
    gr = L.k(GRIP)
    C.rubber(gr)
    phase = nb.fract(nb.div(y, K.GRIP_RIBS))
    rib = nb.band(phase, 0.25, 0.75, 0.15)
    C.paint(gr, height=nb.mul(rib, 0.7))
    palm = nb.mul(gr, nb.band(y, -0.25, 0.25, 0.12))
    C.paint(nb.mul(palm, nb.mr(L.noise(4.0, 7, detail=3), 0.3, 0.7, 0.3, 0.7)), hexc("#1C1C1C"),
            0.62)
    C.paint(L.k(STOP), hexc("#151515"), 0.85, 0.0)

    # the plates: black paint on steel, scuffed grey at the edges, a few deep chips
    pl = L.k(PLATE)
    C.paint(pl, nb.tint(hexc("#1B1C1D"), nb.mr(L.noise(3.5, 8, detail=3), 0.3, 0.7, 0.85, 1.2)),
            nb.mr(L.noise(8.0, 9, detail=3), 0.3, 0.7, 0.45, 0.6), 0.0)
    scuff = nb.mul(nb.edge(0.012, k=5.0), nb.ss(L.noise(12.0, 10, detail=4), 0.4, 0.58))
    C.paint(nb.mul(nb.mul(scuff, pl), 0.85), hexc("#77787A"), 0.4, 0.8)

    # the bolts: zinc plate, dulled, a touch of rust in the flats
    bo = L.k(BOLT)
    C.paint(bo, nb.tint(hexc("#A7A9A4"), nb.mr(L.noise(20.0, 11, detail=3), 0.3, 0.7, 0.8, 1.05)),
            0.4, 1.0)
    C.paint(nb.mul(bo, nb.ss(L.noise(30.0, 12, detail=3), 0.62, 0.7)), hexc("#6A4A32"), 0.8, 0.2)

    # the jaw: dark forged steel with hammer-scale mottling, the cutting edges ground bright
    jw = L.k(JAW)
    C.paint(jw, nb.tint(hexc("#55585C"), nb.mr(L.noise(14.0, 13, detail=4), 0.3, 0.7, 0.7, 1.15)),
            nb.mr(L.noise(10.0, 14, detail=3), 0.3, 0.7, 0.42, 0.6), 1.0,
            nb.mul(nb.voronoi(L.vec(s=15), 60.0, feature="F1"), 0.25))
    ground = nb.mul(jw, nb.ss(ax, K.EDGE_W + 0.012, K.EDGE_W * 0.5))
    C.paint(ground, hexc("#C9CCCE"), 0.22, 1.0)
    # the grind's lines, running along the edge
    lines = nb.mr(L.noise(300.0, 16, stretch=(0.08, 1.0, 1.0), detail=1), 0.3, 0.7, 0.85, 1.1)
    C.paint(ground, nb.tint(hexc("#C9CCCE"), lines))
    # a little rust bloom where the jaw meets the plates
    rust = nb.mul(nb.mul(jw, nb.ss(y, -K.GRIP_Y - 0.27, -K.GRIP_Y - 0.2)),
                  nb.ss(L.noise(25.0, 17, detail=4), 0.58, 0.68))
    C.paint(rust, hexc("#6E3F22"), 0.85, 0.1)

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

# Where the game holds a tool in first person (src/shared/Tools/Catalog.luau, the row's `Hold`):
# the camera's right, down and forward in studs, then its turn in degrees (yaw left, pitch up,
# roll).
HOLD = ((0.75, -0.85, -1.05), (10.0, 14.0, -12.0))


def held(cam, offset, turn):
    """The cutters' place in the world for a camera holding them at offset, turned (Roblox's
    camera space, which Blender's camera shares: -Z ahead, +Y up)."""
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

    # lying flat on its bottom plate; tilted so the grips touch the floor too
    lo, hi = box(ob)
    middle = -(lo.y + hi.y) / 2  # laid with their middle on the spot, not their grip
    plate_z = K.PLATE_Z[1]
    tilt = math.degrees(math.atan2(plate_z - K.GRIP_R, K.GRIP_Y))

    def lay(at, yaw):
        ob.matrix_world = (Matrix.Translation(Vector(at)) @ Matrix.Rotation(math.radians(yaw), 4, "Z")
                           @ Matrix.Rotation(math.radians(-tilt), 4, "X")
                           @ Matrix.Translation(Vector((0.0, middle, plate_z))))

    # 1. in the studio: from the front three-quarter (the jaw, its bright edge, the bolts), then
    #    from behind (the grips, the handles' converging line)
    studio = render.studio_rig()
    for o in studio:
        o.hide_render = False
    lay((0.0, 0.0, 0.0), -30)
    cam = render.camera((-1.9, -2.7, 1.5), (0.0, -0.2, 0.05), lens=40)
    render.shoot(cam, os.path.join(SHEETS, "boltcutters-front.png"), exposure=-0.2)
    cam = render.camera((1.8, 2.4, 1.3), (0.0, 0.0, 0.05), lens=40)
    render.shoot(cam, os.path.join(SHEETS, "boltcutters-back.png"), exposure=-0.2)
    for o in studio:
        o.hide_render = True

    # 2. on a unit's floor among boxes, by its bulb, from the doorway at standing height: the
    #    moment you spot them
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
    lay((0.6, 5.2, 0.0), 128)
    # 14.6 mm is Roblox's 70 degree view on a 16:9 screen
    cam = render.camera((0.0, -1.5, 4.6), (0.4, 5.0, 0.4), lens=14.6)
    render.shoot(cam, os.path.join(SHEETS, "boltcutters-floor.png"), exposure=0.2)

    # 3. your view: held low on your right in the same unit, jaw forward
    cam = render.camera((0.6, -1.0, 4.6), (-0.4, 9.0, 2.6), lens=14.6)
    bpy.context.view_layer.update()
    ob.matrix_world = held(cam, *HOLD) @ FLIP
    render.shoot(cam, os.path.join(SHEETS, "boltcutters-view.png"), exposure=0.2)


STAGES = {"textures": stage_textures, "export": stage_export, "renders": stage_renders}

if __name__ == "__main__":
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    ap = argparse.ArgumentParser()
    ap.add_argument("--stage", choices=list(STAGES), required=True)
    STAGES[ap.parse_args(argv).stage]()
    print("DONE")
