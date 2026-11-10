"""Build the air horn in Blender, headless (art/airhorn/README.md).

    blender -b --factory-startup -P art/airhorn/build.py -- --stage textures|export|renders

Stages:
    textures  the AirHorn texture set, baked from its recipe into out/textures
    export    out/AirHorn.fbx (one MeshPart) and src/shared/Tools/Specs/AirHorn.luau
    renders   the look sheets, art/sheets/airhorn-*.png

It borrows the finds' atlas, bake and export (art/finds/build.py), pointed at its own spec and out
folder, as the saw and the bolt cutters do.
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
import render  # noqa: E402
import spec as K  # noqa: E402
from nodes import hexc  # noqa: E402

OUT = os.path.join(HERE, "out")
TEX = os.path.join(OUT, "textures")
SHEETS = os.path.join(K.ROOT, "art", "sheets")
FBX = os.path.join(OUT, f"{K.SET}.fbx")
SPECS = os.path.join(K.ROOT, "src", "shared", "Tools", "Specs", "AirHorn.luau")


def finds_kit():
    """The finds' build, as a library: it imports `spec`, which is already this folder's, so its
    atlas size, set name and dust are the horn's; its out paths are pointed here."""
    s = importlib.util.spec_from_file_location("finds_build", os.path.join(FINDS, "build.py"))
    mod = importlib.util.module_from_spec(s)
    s.loader.exec_module(mod)
    assert mod.K is K, "the finds' build must see the horn's spec"
    mod.OUT, mod.TEX, mod.UVS, mod.FBX = OUT, TEX, os.path.join(OUT, "uvs.npz"), FBX
    return mod


kit = finds_kit()

# What a face is, for the recipe (a face attribute).
CAN, COLLAR, TRUMPET = range(3)


# --- geometry --------------------------------------------------------------------------------

def lathe(m, profile, segs=K.SEGS):
    """A closed shape turned round the can's axis through (z, radius) points in inches, a radius
    of 0 closing it on the axis. Point 0 of every ring faces front (-Y). Built in a bmesh so its
    faces can be turned to look outwards, in a fixed order so every stage numbers it alike."""
    bm = bmesh.new()
    rings = []
    for z, r in profile:
        zz = K.at(z)
        if r <= 1e-6:
            rings.append([bm.verts.new((0.0, 0.0, zz))])
            continue
        rr = r * K.IN
        rings.append([bm.verts.new((rr * math.sin(2 * math.pi * i / segs),
                                    -rr * math.cos(2 * math.pi * i / segs), zz))
                      for i in range(segs)])
    for a, b in zip(rings, rings[1:]):
        for i in range(segs):
            j = (i + 1) % segs
            if len(a) == 1:
                bm.faces.new((a[0], b[i], b[j]))
            elif len(b) == 1:
                bm.faces.new((a[i], a[j], b[0]))
            else:
                bm.faces.new((a[i], a[j], b[j], b[i]))
    kit.solid(m, bm)


def can_profile():
    z0, z1, n = K.CAN_WALL
    wall = [(z0 + (z1 - z0) * k / n, K.CAN_R) for k in range(1, n)]
    return K.CAN_FOOT + wall + K.CAN_TOP


def trumpet_profile():
    """Up the outside (flange, neck, the bead, the flare), over the lip, and down the inside to
    the throat."""
    (z0, z1), n = K.FLARE["z"], K.FLARE["rings"]
    b = K.BEAD
    zs = [z0 + (z1 - z0) * k / n for k in range(1, n + 1)]
    out = [(z, K.flare_r(z)) for z in zs if abs(z - b["z"]) > b["w"] * 0.7]
    # the bead gets its own rings, to stand up off the neck
    for f, h in ((-0.5, 0.0), (-0.25, 0.8), (0.0, 1.0), (0.25, 0.8), (0.5, 0.0)):
        z = b["z"] + f * b["w"]
        out.append((z, K.flare_r(z) + b["out"] * h))
    out.sort()
    inside = []
    zt, zc = K.THROAT
    top = K.LIP[-1][0] - 0.06
    for k in range(9):
        z = top + (zt - top) * k / 8
        inside.append((z, K.flare_r(z) - K.WALL_T))
    return K.TRUMPET_BASE + out + K.LIP + inside + [(zc, 0.0)]


def horn_geo():
    F = kit.Find(K.SET)
    F.add(CAN, lathe, can_profile())
    F.add(COLLAR, lathe, K.COLLAR)
    F.add(TRUMPET, lathe, trumpet_profile())
    return F


def build_all(baking, coll=None):
    objs = {K.SET: horn_geo().build(40, coll)}
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
    """White enamel on a steel can, a black printed band with orange stripes and an orange
    sound-wave mark on its front, warnings in small black type on its back, chipped to grey steel
    and freckled with rust round its foot; bare tinplate at the chime and the seam; a black
    ribbed collar; a safety-orange trumpet, satin, a mould seam up each side, scuffed pale at its
    lip and dark down its throat."""
    L = kit.Look(nb, K.SEED)
    x, y, z = L.x, L.y, L.z
    # the drawing's inches, for placing things
    xi = nb.div(x, K.IN)
    yi = nb.div(y, K.IN)
    zi = nb.add(nb.div(z, K.IN), K.GRIP_Z)
    front = nb.ss(nb.mul(yi, -1.0), 0.1, 0.5)     # the can's front half (-y)
    back = nb.ss(yi, 0.1, 0.5)
    edge = nb.edge(0.01, k=5.0)
    angle = nb.math("ARCTAN2", x, nb.mul(y, -1.0))   # round the axis, 0 at the front

    # the can: white enamel, a little uneven, gloss gone satin with handling
    white = nb.tint(hexc("#E6E2D6"), nb.mr(L.noise(3.0, 1, detail=4), 0.3, 0.7, 0.9, 1.04))
    C = kit.Coat(L, white, nb.mr(L.noise(6.0, 2, detail=3), 0.3, 0.7, 0.3, 0.42), 0.0,
                 nb.mul(L.noise(160.0, 3, detail=1), 0.02))
    cn = L.k(CAN)
    t0, t1 = K.TIN
    tin = nb.mul(cn, nb.add(nb.band(zi, t0[0], t0[1], 0.03), nb.band(zi, t1[0], t1[1], 0.02),
                            clamp=True))
    label = nb.mul(cn, nb.inv(tin))

    # the black band and its orange stripes, all the way round
    b0, b1 = K.BAND
    band = nb.mul(label, nb.band(zi, b0, b1, 0.01))
    C.paint(band, hexc("#151516"), 0.36)
    orange = nb.tint(hexc("#E8601C"), nb.mr(L.noise(5.0, 4, detail=3), 0.3, 0.7, 0.9, 1.06))
    stripes = nb.add(nb.band(zi, b0 - K.STRIPE - 0.04, b0 - 0.04, 0.01),
                     nb.band(zi, b1 + 0.04, b1 + K.STRIPE + 0.04, 0.01), clamp=True)
    C.paint(nb.mul(stripes, label), orange, 0.38)
    # the sound-wave mark on the front: a dot, then three arcs going out to the right
    W = K.WAVES
    cx, cz = W["c"]
    dx, dz = nb.sub(xi, cx), nb.sub(zi, cz)
    d = L.dist(dx, dz)
    wedge = nb.ss(nb.sub(dx, nb.mul(nb.absf(dz), W["spread"])), 0.0, 0.06)
    arcs = None
    for r in W["r"]:
        a = nb.band(d, r - W["t"] / 2, r + W["t"] / 2, 0.015)
        arcs = a if arcs is None else nb.add(arcs, a, clamp=True)
    mark = nb.add(nb.mul(arcs, wedge), nb.ss(d, W["dot"] + 0.015, W["dot"] - 0.015), clamp=True)
    C.paint(nb.mul(nb.mul(mark, front), band), orange, 0.38)
    # a line of white type under it, and the warnings on the back in black
    words = nb.ss(L.noise(26.0, 5, stretch=(1.0, 1.0, 0.12), detail=1), 0.42, 0.46)
    tf = nb.mul(nb.band(zi, *K.TYPE_FRONT, 0.01), nb.band(xi, -1.15, 1.15, 0.02))
    C.paint(nb.mul(nb.mul(tf, words), nb.mul(front, band)), hexc("#D8D4C8"))
    lines = nb.band(nb.fract(nb.div(zi, 0.15)), 0.3, 0.68, 0.02)
    tb = None
    for lo, hi in K.TYPE_BACK:
        t = nb.band(zi, lo, hi, 0.01)
        tb = t if tb is None else nb.add(tb, t, clamp=True)
    C.paint(nb.mul(nb.mul(nb.mul(tb, lines), words), nb.mul(back, label)), hexc("#2A2A2A"))
    # a red warning diamond at the head of the warnings
    dia = nb.ss(nb.add(nb.absf(xi), nb.absf(nb.sub(zi, 4.86))), 0.2, 0.17)
    C.paint(nb.mul(dia, nb.mul(back, label)), hexc("#B8281E"))
    # chips: the enamel knocked off to grey steel, mostly near the foot and on the band's edges
    chip = nb.mul(nb.ss(L.noise(14.0, 6, detail=5, rough=0.7), 0.64, 0.68),
                  nb.add(nb.ss(zi, 1.6, 0.4), 0.35))
    C.paint(nb.mul(nb.clamp(chip), label), hexc("#7D8084"), 0.5, 0.8, -0.3)
    # scratches, pale through the colour
    scr = nb.band(L.noise(4.0, 7, stretch=(1.0, 1.0, 0.25), detail=2), 0.498, 0.502, 0.001)
    C.paint(nb.mul(nb.mul(scr, nb.ss(L.noise(2.0, 8), 0.55, 0.65)), label), hexc("#B4B2AC"),
            0.5, height=-0.2)

    # the tinplate: bright steel dulled with handling, rust freckles and grime round the foot
    C.paint(tin, nb.tint(hexc("#B6B9BB"), nb.mr(L.noise(18.0, 9, detail=3), 0.3, 0.7, 0.75, 1.05)),
            nb.mr(L.noise(9.0, 10, detail=3), 0.3, 0.7, 0.3, 0.48), 1.0)
    rust = nb.mul(nb.mul(cn, nb.ss(zi, 1.1, 0.1)), nb.ss(L.noise(30.0, 11, detail=4), 0.6, 0.68))
    C.paint(rust, hexc("#6E3F22"), 0.85, 0.15, 0.1)
    grime = nb.mul(nb.mul(cn, nb.ss(zi, 0.9, 0.0)), nb.mr(L.noise(8.0, 12, detail=4), 0.3, 0.7, 0.2, 0.6))
    C.paint(grime, hexc("#4A4238"), 0.8)

    # the collar: black plastic, satin, ribbed round its skirt, scuffed grey on its edges
    co = L.k(COLLAR)
    C.paint(co, nb.tint(hexc("#161617"), nb.mr(L.noise(5.0, 13, detail=3), 0.3, 0.7, 0.85, 1.15)),
            nb.mr(L.noise(7.0, 14, detail=3), 0.3, 0.7, 0.45, 0.58), 0.0)
    kn = K.KNURL
    rib = nb.band(nb.fract(nb.div(nb.mul(angle, kn["ribs"]), 2 * math.pi)), 0.0, kn["groove"], 0.08)
    C.paint(nb.mul(nb.mul(rib, nb.band(zi, *kn["z"], 0.03)), co), height=-0.7)
    C.paint(nb.mul(nb.mul(edge, co), nb.ss(L.noise(10.0, 15, detail=5), 0.46, 0.6)),
            hexc("#4A4A4A"), 0.75)

    # the trumpet: safety-orange plastic, satin, a mould seam up each side (where x is 0 is the
    # front and back; the mould parts left and right, at y = 0)
    tr = L.k(TRUMPET)
    C.paint(tr, orange, nb.mr(L.noise(6.0, 16, detail=3), 0.3, 0.7, 0.4, 0.5), 0.0)
    radial = nb.add(nb.mul(L.nx, x), nb.mul(L.ny, y))   # below 0 where a face looks in at the axis
    inside = nb.mul(tr, nb.ss(radial, 0.0005, -0.0005))
    outside = nb.mul(tr, nb.inv(inside))
    seam = nb.mul(nb.band(yi, -0.012, 0.012, 0.008), outside)
    C.paint(seam, hexc("#F08A4E"), height=0.5)
    lip = nb.mul(nb.mul(tr, nb.ss(zi, 12.0, 12.35)),
                 nb.ss(L.noise(12.0, 17, detail=4), 0.4, 0.58))
    C.paint(lip, hexc("#F2A77A"), 0.62)
    scuff = nb.mul(nb.mul(edge, outside), nb.ss(L.noise(10.0, 18, detail=5, rough=0.7), 0.45, 0.6))
    C.paint(scuff, hexc("#EE9A6A"), 0.65)
    # down the throat it goes dark, as you'd see into a horn
    deep = nb.mr(zi, 12.3, K.THROAT[0] + 0.4, 0.15, 0.97)
    C.paint(nb.mul(inside, deep), hexc("#2A1206"), 0.7)

    C.finish(ao=0.2, ao_low=0.45, dust=K.DUST)
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

# Where the game holds the horn in first person (src/shared/Tools/Catalog.luau, the row's `hold`
# and `holdTurn`): the camera's right, up and back in studs, then its turn in degrees (yaw left,
# pitch up, roll).
HOLD = ((-1.2, -1.15, -2.2), (205.0, 4.0, 10.0))


def held(cam, offset, turn):
    """The horn's place in the world for a camera holding it at offset, turned (Roblox's camera
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

    # standing on its foot, as the game lays it: its lowest point on the floor
    lo, _ = box(ob)

    def lay(at, yaw):
        ob.matrix_world = (Matrix.Translation(Vector(at)) @ Matrix.Rotation(math.radians(yaw), 4, "Z")
                           @ Matrix.Translation(Vector((0.0, 0.0, -lo.z))))

    # 1. in the studio: from the front three-quarter (the band and its sound-wave mark), then
    #    from behind on the other side (the warnings, the trumpet's mould seam)
    studio = render.studio_rig()
    for o in studio:
        o.hide_render = False
    lay((0.0, 0.0, 0.0), 0)
    cam = render.camera((-1.9, -3.4, 1.7), (0.0, 0.0, 0.88), lens=35)
    render.shoot(cam, os.path.join(SHEETS, "airhorn-front.png"), exposure=-0.2)
    cam = render.camera((2.1, 3.3, 1.7), (0.0, 0.0, 0.88), lens=35)
    render.shoot(cam, os.path.join(SHEETS, "airhorn-back.png"), exposure=-0.2)
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
    lay((0.5, 5.4, 0.0), -20)
    # 14.6 mm is Roblox's 70 degree view on a 16:9 screen
    cam = render.camera((0.0, -1.5, 4.6), (0.4, 5.0, 0.4), lens=14.6)
    render.shoot(cam, os.path.join(SHEETS, "airhorn-floor.png"), exposure=0.2)

    # 3. your view: held low on your left in the same unit, the trumpet up
    cam = render.camera((0.6, -1.0, 4.6), (-0.4, 9.0, 2.6), lens=14.6)
    bpy.context.view_layer.update()
    ob.matrix_world = held(cam, *HOLD) @ FLIP
    render.shoot(cam, os.path.join(SHEETS, "airhorn-view.png"), exposure=0.2)


STAGES = {"textures": stage_textures, "export": stage_export, "renders": stage_renders}

if __name__ == "__main__":
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    ap = argparse.ArgumentParser()
    ap.add_argument("--stage", choices=list(STAGES), required=True)
    STAGES[ap.parse_args(argv).stage]()
    print("DONE")
