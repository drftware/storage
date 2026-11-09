"""Build the padlock you carry in Blender, headless (art/padlock/README.md).

    blender -b --factory-startup -P art/padlock/build.py -- --stage textures|export|renders

Stages:
    textures  the Padlock texture set, baked from its recipe into out/textures
    export    out/Padlock.fbx (one MeshPart) and src/shared/Tools/Specs/Padlock.luau
    renders   the look sheets, art/sheets/padlock-*.png

It borrows the finds' atlas, bake and export (art/finds/build.py), pointed at its own spec and out
folder, as the bolt cutters do.
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
SPECS = os.path.join(K.ROOT, "src", "shared", "Tools", "Specs", "Padlock.luau")


def finds_kit():
    """The finds' build, as a library: it imports `spec`, which is already this folder's, so its
    atlas size, set name and dust are the padlock's; its out paths are pointed here."""
    s = importlib.util.spec_from_file_location("finds_build", os.path.join(FINDS, "build.py"))
    mod = importlib.util.module_from_spec(s)
    s.loader.exec_module(mod)
    assert mod.K is K, "the finds' build must see the padlock's spec"
    mod.OUT, mod.TEX, mod.UVS, mod.FBX = OUT, TEX, os.path.join(OUT, "uvs.npz"), FBX
    return mod


kit = finds_kit()

# What a face is, for the recipe (a face attribute).
LAM, CAP, RIVET, KEY, SHACKLE = range(5)


# --- geometry --------------------------------------------------------------------------------

def body(m):
    """Six steel plates stacked, each bevelled so the seams between them read."""
    w, t = K.BODY_W / 2, K.BODY_T / 2
    for i in range(K.LAMS):
        z0 = -K.BODY_H / 2 + i * K.LAM_H
        geo.box(m, (-w, -t, z0), (w, t, z0 + K.LAM_H), None, bevel=K.LAM_BEVEL)


def cap(m):
    """The thin plate on top that the shackle goes into."""
    w, t = K.BODY_W / 2 - K.CAP_IN, K.BODY_T / 2 - K.CAP_IN
    geo.box(m, (-w, -t, K.BODY_H / 2 - 0.002), (w, t, K.CAP_TOP), None, bevel=0.003)


def rivets(m):
    """The rivets through the stack, a domed head at each end of the top and the bottom."""
    r = K.RIVET_R
    for x in (-K.RIVET_X, K.RIVET_X):
        kit.ellipsoid(m, (x, 0.0, K.CAP_TOP), (r, r, r * 0.45), (0, 0), 10, 4)
        kit.ellipsoid(m, (x, 0.0, -K.BODY_H / 2), (r, r, r * 0.45), (0, 0), 10, 4)


def keyway(m):
    """The brass plug in the bottom plate, standing a little proud."""
    h = K.KEY_PROUD + 0.004
    geo.cylinder(m, "z", (0.0, 0.0, -K.BODY_H / 2 - K.KEY_PROUD + h / 2), K.KEY_R, h, segs=20)


def shackle_path():
    """The shackle's middle line, open: the long leg (+X) up out of the body, the bend, the short
    leg down to its end, then the whole risen LIFT and swung SWING degrees round the long leg.
    Returns the points and the shackle's plane's normal."""
    R = K.SHACKLE_R
    cz = K.CAP_TOP + K.LIFT + K.SHACKLE_CLEAR
    pts = [(R, K.CAP_TOP - 0.03), (R, K.CAP_TOP + K.LIFT * 0.5), (R, cz)]
    for k in range(1, 16):
        a = math.pi * k / 16
        pts.append((R * math.cos(a), cz + R * math.sin(a)))
    pts += [(-R, cz), (-R, K.CAP_TOP - K.SHACKLE_IN + K.LIFT)]
    th = math.radians(K.SWING)
    c, s = math.cos(th), math.sin(th)
    out = [Vector((R + (x - R) * c, (x - R) * s, z)) for x, z in pts]
    return out, Vector((-s, c, 0.0))


def shackle(m):
    """A round bar along the path, its rings squared to the shackle's flat plane so it never
    twists where the legs meet the bend."""
    path, n = shackle_path()
    segs = 14
    bm = bmesh.new()
    rings = []
    for i, p in enumerate(path):
        t = (path[min(i + 1, len(path) - 1)] - path[max(i - 1, 0)]).normalized()
        b = t.cross(n).normalized()
        rings.append([bm.verts.new(p + K.SHACKLE_TUBE * (math.cos(2 * math.pi * k / segs) * n
                                                          + math.sin(2 * math.pi * k / segs) * b))
                      for k in range(segs)])
    for r0, r1 in zip(rings, rings[1:]):
        for k in range(segs):
            bm.faces.new((r0[k], r0[(k + 1) % segs], r1[(k + 1) % segs], r1[k]))
    bm.faces.new(rings[0])
    bm.faces.new(list(reversed(rings[-1])))
    kit.solid(m, bm)


def padlock_geo():
    F = kit.Find(K.SET)
    F.add(LAM, body)
    F.add(CAP, cap)
    F.add(RIVET, rivets)
    F.add(KEY, keyway)
    F.add(SHACKLE, shackle)
    return F


def build_all(baking, coll=None):
    objs = {K.SET: padlock_geo().build(40, coll)}
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
    """The doors' padlock, handled: steel plates each a slightly different grey, their edges worn
    bright and grime in the seams with a little rust; a hardened steel shackle, the stretch that
    sat inside the body clean and oily; a brass keyway with its key's slot; dull rivet heads."""
    L = kit.Look(nb, K.SEED)
    x, y, z = L.x, L.y, L.z

    # the plates: each its own grey, as a stack of stamped steel is
    rel = nb.div(nb.add(z, K.BODY_H / 2), K.LAM_H)
    idx = nb.math("FLOOR", rel)
    tone = nb.fract(nb.mul(nb.sin(nb.mul(idx, 12.9898)), 43758.5453))
    grey = nb.mixc(nb.mr(tone, 0.0, 1.0, 0.0, 1.0), hexc("#7C838A"), hexc("#A0A7AD"))
    grey = nb.tint(grey, nb.mr(L.noise(40.0, 1, detail=4), 0.3, 0.7, 0.88, 1.08))
    C = kit.Coat(L, grey, nb.mr(L.noise(9.0, 2, detail=3), 0.3, 0.7, 0.5, 0.66), 1.0,
                 nb.mul(L.noise(200.0, 3, detail=1), 0.03))
    lam = L.k(LAM, CAP)
    # the stamping's fine lines, along each plate
    lines = nb.mr(L.noise(260.0, 4, stretch=(0.06, 1.0, 1.0), detail=1), 0.3, 0.7, 0.9, 1.08)
    C.paint(lam, nb.tint(grey, lines))
    # grime in the seams between plates, and rust blooming out of a few
    phase = nb.fract(rel)
    seam = nb.mul(nb.add(nb.ss(phase, 0.16, 0.0), nb.ss(phase, 0.84, 1.0), clamp=True),
                  L.k(LAM))
    C.paint(nb.mul(seam, 0.85), hexc("#2E3236"), 0.75, 0.4, height=-0.3)
    rust = nb.mul(nb.mul(seam, nb.ss(L.noise(18.0, 5, detail=6), 0.6, 0.7)), 0.9)
    C.paint(rust, hexc("#6E3F22"), 0.85, 0.1)
    # the edges, worn back to bright steel where the lock knocks about
    worn = nb.mul(nb.mul(nb.edge(0.006, k=8.0), lam), nb.ss(L.noise(14.0, 6, detail=4), 0.35, 0.55))
    C.paint(nb.mul(worn, 0.85), hexc("#D3D8DC"), 0.3, 1.0)
    # the cap a touch brighter, and the short leg's hole in it, dark
    C.paint(L.k(CAP), hexc("#A9B0B5"), 0.42, 1.0)
    hole = nb.ss(L.dist(nb.add(x, K.SHACKLE_R), y), K.SHACKLE_TUBE * 1.2, K.SHACKLE_TUBE * 0.95)
    hole = nb.mul(nb.mul(hole, L.k(CAP)), nb.ss(z, K.CAP_TOP - 0.003, K.CAP_TOP - 0.001))
    C.paint(hole, hexc("#08090A"), 0.9, 0.0, height=-0.6)

    # the rivets: dull steel domes
    C.paint(L.k(RIVET), nb.tint(hexc("#8D9297"), nb.mr(L.noise(50.0, 7, detail=3), 0.3, 0.7,
                                                         0.8, 1.1)), 0.42, 1.0)

    # the keyway: brass, tarnished in patches, a ring round its plug and the key's slot
    kw = L.k(KEY)
    tarn = L.noise(30.0, 8, detail=4)
    C.paint(kw, nb.mixc(nb.ss(tarn, 0.5, 0.7), hexc("#B28A45"), hexc("#6B5428")),
            nb.mr(tarn, 0.3, 0.7, 0.28, 0.5), 1.0)
    face = nb.mul(kw, nb.ss(z, -K.BODY_H / 2 - K.KEY_PROUD + 0.003, -K.BODY_H / 2 - K.KEY_PROUD
                            + 0.001))
    ring = nb.band(L.dist(x, y), K.KEY_R * 0.62, K.KEY_R * 0.7, 0.002)
    C.paint(nb.mul(face, ring), hexc("#2A2114"), 0.7, height=-0.3)
    sl, sw = K.KEY_SLOT
    slot = nb.mul(nb.band(x, -sl / 2, sl / 2, 0.002), nb.band(y, -sw / 2, sw / 2, 0.001))
    C.paint(nb.mul(face, slot), hexc("#050505"), 0.9, 0.0, height=-0.8)

    # the shackle: hardened steel, bright, scuffed; the stretch that sat in the body clean and oily
    sh = L.k(SHACKLE)
    C.paint(sh, nb.tint(hexc("#C9CED2"), nb.mr(L.noise(25.0, 9, detail=4), 0.3, 0.7, 0.82, 1.06)),
            nb.mr(L.noise(12.0, 10, detail=3), 0.3, 0.7, 0.22, 0.36), 1.0)
    scuff = nb.mul(sh, nb.ss(L.noise(60.0, 11, stretch=(1.0, 1.0, 0.15), detail=2), 0.62, 0.7))
    C.paint(scuff, hexc("#8E9499"), 0.45)
    clean = nb.mul(nb.mul(sh, nb.band(x, K.SHACKLE_R - 0.04, K.SHACKLE_R + 0.04, 0.005)),
                   nb.band(z, K.CAP_TOP, K.CAP_TOP + K.LIFT, 0.004))
    C.paint(clean, hexc("#EDEFF0"), 0.14, 1.0)

    C.finish(ao=0.25, ao_low=0.5, dust=K.DUST)
    return C.channels(dist=0.0015, strength=0.6)


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

# Where the game holds it in first person (src/shared/Tools/Catalog.luau, the row's `hold` and
# `holdTurn`): the camera's right, up and back in studs, then its turn in degrees (yaw left,
# pitch up, roll).
HOLD = ((-0.62, -0.6, -1.7), (200.0, 10.0, 8.0))


def held(cam, offset, turn):
    """The padlock's place in the world for a camera holding it at offset, turned (Roblox's
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

    # standing on its bottom plate, as the game lays it (Slots: its lowest point on the floor)
    lo, _ = box(ob)

    def lay(at, yaw):
        ob.matrix_world = (Matrix.Translation(Vector(at)) @ Matrix.Rotation(math.radians(yaw), 4, "Z")
                           @ Matrix.Translation(Vector((0.0, 0.0, -lo.z))))

    # 1. in the studio: its face three-quarter (the plates, the open shackle, the keyway's edge),
    #    then from behind and above (the cap, the hole the shackle snaps into)
    studio = render.studio_rig()
    for o in studio:
        o.hide_render = False
    lay((0.0, 0.0, 0.0), -25)
    cam = render.camera((-1.0, -2.0, 0.83), (0.1, 0.0, 0.27), lens=50)
    render.shoot(cam, os.path.join(SHEETS, "padlock-front.png"), exposure=-0.2)
    cam = render.camera((1.07, 1.6, 1.4), (0.1, 0.0, 0.27), lens=50)
    render.shoot(cam, os.path.join(SHEETS, "padlock-back.png"), exposure=-0.2)
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
    lay((0.6, 5.2, 0.0), 160)
    # 14.6 mm is Roblox's 70 degree view on a 16:9 screen
    cam = render.camera((0.0, -1.5, 4.6), (0.4, 5.0, 0.4), lens=14.6)
    render.shoot(cam, os.path.join(SHEETS, "padlock-floor.png"), exposure=0.2)

    # 3. your view: held low on your left in the same unit, its face to you
    cam = render.camera((0.6, -1.0, 4.6), (-0.4, 9.0, 2.6), lens=14.6)
    bpy.context.view_layer.update()
    ob.matrix_world = held(cam, *HOLD) @ FLIP
    render.shoot(cam, os.path.join(SHEETS, "padlock-view.png"), exposure=0.2)


STAGES = {"textures": stage_textures, "export": stage_export, "renders": stage_renders}

if __name__ == "__main__":
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    ap = argparse.ArgumentParser()
    ap.add_argument("--stage", choices=list(STAGES), required=True)
    STAGES[ap.parse_args(argv).stage]()
    print("DONE")
