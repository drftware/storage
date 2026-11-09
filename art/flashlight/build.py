"""Build the flashlight in Blender, headless (art/flashlight/README.md).

    blender -b --factory-startup -P art/flashlight/build.py -- --stage textures|export|renders

Stages:
    textures  the Flashlight texture set, baked from its recipe into out/textures
    export    out/Flashlight.fbx (two MeshParts: the torch and its lens) and
              src/shared/Flashlight/Specs.luau
    renders   the look sheets, art/sheets/flashlight-*.png

It borrows the finds' atlas, bake and export (art/finds/build.py), pointed at its own spec and out
folder, as the Mannequin does. The lens is left out of the bake: the game lights it by changing
its material, so it ships plain.
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
from mathutils import Matrix, Vector  # noqa: E402

import bake  # noqa: E402
import geo  # noqa: E402
import render  # noqa: E402
import spec as K  # noqa: E402
from nodes import NB, hexc  # noqa: E402

OUT = os.path.join(HERE, "out")
TEX = os.path.join(OUT, "textures")
SHEETS = os.path.join(K.ROOT, "art", "sheets")
FBX = os.path.join(OUT, f"{K.SET}.fbx")


def finds_kit():
    """The finds' build, as a library: it imports `spec`, which is already this folder's, so its
    atlas size, set name and dust are the flashlight's; its out paths are pointed here."""
    s = importlib.util.spec_from_file_location("finds_build", os.path.join(FINDS, "build.py"))
    mod = importlib.util.module_from_spec(s)
    s.loader.exec_module(mod)
    assert mod.K is K, "the finds' build must see the flashlight's spec"
    mod.OUT, mod.TEX, mod.UVS, mod.FBX = OUT, TEX, os.path.join(OUT, "uvs.npz"), FBX
    return mod


kit = finds_kit()

# What a face is, for the recipe (a face attribute).
REFLECTOR, BEZEL, HEAD, COLLAR, BODY, TAIL, HOUSING, BUTTON, BAIL, BULB = range(10)


# --- geometry --------------------------------------------------------------------------------

def revolve(m, profile, segs=K.SEGS):
    """A surface of revolution round the torch's axis (Y) through (y, radius) points, measured
    from the grip. Angle 0 is the top (+Z). A point on the axis closes the surface on a pole.
    Faces look to the left of the profile's direction of travel, which is outwards for a profile
    traced from the reflector round the lens and back over the outside."""
    rings = []
    for y, r in profile:
        y -= K.GRIP_Y
        if r <= 1e-6:
            rings.append([m.vert((0.0, y, 0.0))])
            continue
        rings.append([m.vert((r * math.sin(2 * math.pi * i / segs), y,
                              r * math.cos(2 * math.pi * i / segs))) for i in range(segs)])
    for a, b in zip(rings, rings[1:]):
        for i in range(segs):
            j = (i + 1) % segs
            if len(a) == 1:
                m.face((a[0], b[j], b[i]), None, True)
            elif len(b) == 1:
                m.face((a[i], a[j], b[0]), None, True)
            else:
                m.face((a[i], a[j], b[j], b[i]), None, True)


def body_profile():
    """The plain tube, with rings along it so the bake and the shading stay even."""
    y0, y1 = K.BODY[0][0], K.BODY[-1][0]
    r = K.BODY[0][1]
    n = K.BODY_RINGS
    return [(y0 + (y1 - y0) * k / n, r) for k in range(n + 1)]


def grip(c):
    return (c[0], c[1] - K.GRIP_Y, c[2])


def bail(m):
    """A wire loop standing out of the tail's end, flat, for a lanyard."""
    b = K.BAIL
    y0 = b["y"] - K.GRIP_Y
    pts = []
    for k in range(13):
        t = math.pi * k / 12
        pts.append((b["half_gap"] * math.cos(t), y0 + b["r"] * math.sin(t), 0.0))
    pts = [(pts[0][0], y0 - 0.03, 0.0)] + pts + [(pts[-1][0], y0 - 0.03, 0.0)]
    geo.sweep(m, pts, b["wire"], segs=8)


def torch_geo():
    F = kit.Find(K.SET)
    F.add(REFLECTOR, revolve, K.REFLECTOR)
    F.add(BEZEL, revolve, K.BEZEL)
    F.add(HEAD, revolve, K.HEAD)
    F.add(COLLAR, revolve, K.COLLAR)
    F.add(BODY, revolve, body_profile())
    F.add(TAIL, revolve, K.TAIL)
    F.add(HOUSING, kit.ellipsoid, grip(K.HOUSING["c"]), K.HOUSING["r"], (0, 0), 16, 8)
    F.add(BUTTON, kit.ellipsoid, grip(K.BUTTON["c"]), K.BUTTON["r"], (0, 0), 14, 7)
    F.add(BULB, kit.ellipsoid, grip(K.BULB["c"]), (K.BULB["r"],) * 3, (0, 0), 10, 6)
    F.add(BAIL, bail)
    return F


def lens_geo(coll=None):
    m = geo.Mesh("FlashlightLens")
    kit.dome(m, (0.0, K.LENS["y"] - K.GRIP_Y, 0.0), K.LENS["r"], K.LENS["bulge"], segs=K.SEGS,
             rings=4)
    ob = m.build(coll, sharp_angle=None)
    for p in ob.data.polygons:
        p.use_smooth = True
    return ob


def build_all(baking, coll=None):
    objs = {K.SET: torch_geo().build(40, coll)}
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
    """Sun-faded yellow plastic gone glossy where a hand holds it, black ends scuffed grey at
    their edges, an orange-peel chrome reflector, a rubber button, a steel wire bail."""
    L = kit.Look(nb, K.SEED)
    x, y, z = L.x, L.y, L.z
    ang = nb.math("ARCTAN2", x, z)  # round the tube: 0 on top

    # the tube: yellow plastic, faded paler on top where the light caught it on a shelf
    fade = nb.mul(nb.ss(L.nz, -0.2, 0.9), nb.mr(L.noise(1.2, 1, detail=3), 0.3, 0.7, 0.55, 1.0))
    yellow = nb.mixc(fade, hexc("#D49A16"), hexc("#D9B865"))
    yellow = nb.tint(yellow, nb.mr(L.noise(4.0, 2, detail=4), 0.3, 0.7, 0.9, 1.05))
    grain = L.noise(260.0, 3, detail=1)
    C = kit.Coat(L, yellow, nb.mr(L.noise(6.0, 4, detail=3), 0.3, 0.7, 0.38, 0.5), 0.0,
                 nb.mul(grain, 0.06))
    tube = L.k(BODY, HOUSING)

    # the grip rings: shallow ridges moulded round the tube, grime packed in their grooves
    r0, r1, pitch = K.RIBS
    ribs = nb.mul(nb.band(y, r0 - K.GRIP_Y, r1 - K.GRIP_Y, 0.004), L.k(BODY))
    phase = nb.fract(nb.div(nb.sub(y, r0 - K.GRIP_Y), pitch))
    ridge = nb.band(phase, 0.2, 0.8, 0.12)
    groove = nb.mul(nb.inv(ridge), ribs)
    C.paint(ribs, height=nb.mul(ridge, 0.9))
    C.paint(nb.mul(groove, 0.55), hexc("#6B5520"), 0.75)

    # held: the plastic polished glossy and a touch darker where the fingers close
    held = nb.mul(nb.mul(tube, nb.band(y, -0.12, 0.3, 0.12)),
                  nb.mr(L.noise(3.0, 5, detail=4), 0.3, 0.7, 0.4, 0.9))
    C.paint(nb.mul(held, 0.7), nb.tint(C.col, 0.9), 0.22)

    # print: a red band near the tail, and a worn white label down the left side
    s0, s1 = K.STRIPE
    C.paint(nb.mul(nb.band(y, s0 - K.GRIP_Y, s1 - K.GRIP_Y, 0.002), L.k(BODY)), hexc("#A8281F"),
            0.4)
    l0, l1, lh = K.LABEL
    side = nb.band(z, -lh, lh, 0.004)
    left = nb.ss(L.nx, 0.6, 0.8)  # Roblox's left is Blender's +X: the side your eye sees
    letters = nb.mul(nb.band(nb.fract(nb.mul(y, 26.0)), 0.15, 0.7, 0.03),
                     nb.ss(L.noise(30.0, 6, stretch=(1.0, 0.3, 1.0), detail=2), 0.4, 0.5))
    worn = nb.ss(L.noise(7.0, 7, detail=4), 0.35, 0.5)
    label = nb.mul(nb.mul(nb.mul(nb.band(y, l0 - K.GRIP_Y, l1 - K.GRIP_Y, 0.003), side), left),
                   nb.mul(letters, worn))
    C.paint(nb.mul(nb.mul(label, L.k(BODY)), 0.85), hexc("#E9E4D6"), 0.45)

    # scuffs and scratches on the yellow: pale where the plastic was gouged
    scr = nb.band(L.noise(5.0, 8, stretch=(1.0, 0.25, 1.0), detail=2), 0.498, 0.502, 0.001)
    scr = nb.mul(nb.mul(scr, nb.ss(L.noise(2.0, 9), 0.55, 0.65)), tube)
    C.paint(nb.mul(scr, 0.6), hexc("#EDE0B5"), 0.6, height=-0.3)

    # the black ends: satin ABS, grey where knocks scuffed their edges
    black = L.k(BEZEL, HEAD, COLLAR, TAIL)
    C.paint(black, nb.tint(hexc("#19191A"), nb.mr(L.noise(3.0, 10, detail=3), 0.3, 0.7, 0.85, 1.15)),
            nb.mr(L.noise(9.0, 11, detail=3), 0.3, 0.7, 0.42, 0.56), 0.0)
    scuff = nb.mul(nb.edge(0.02, k=5.0), nb.ss(L.noise(11.0, 12, detail=4), 0.42, 0.6))
    C.paint(nb.mul(nb.mul(scuff, black), 0.7), hexc("#5D5B57"), 0.7)
    # the collar's knurl: ridges along the torch, all the way round
    knurl = nb.band(nb.fract(nb.mul(ang, K.KNURL / (2 * math.pi))), 0.25, 0.75, 0.15)
    C.paint(L.k(COLLAR), height=nb.mul(knurl, 1.0))
    # the tail's end: rings pressed into it
    rr = L.dist(x, z)
    endf = nb.mul(L.k(TAIL), nb.ss(y, 0.69 - K.GRIP_Y, 0.71 - K.GRIP_Y))
    C.paint(endf, height=nb.mul(nb.band(nb.fract(nb.mul(rr, 40.0)), 0.3, 0.7, 0.1), 0.6))

    # the reflector: orange-peel chrome, a little hazy
    refl = L.k(REFLECTOR)
    C.chrome(refl, s=30)
    dimple = nb.voronoi(L.vec(s=13), 90.0, feature="F1")
    C.paint(refl, height=nb.mul(dimple, 0.3))
    C.paint(L.k(BULB), hexc("#EFEBDF"), 0.08, 0.0)

    # the button: black rubber with a fine grip texture
    C.rubber(L.k(BUTTON))
    C.paint(L.k(BUTTON), height=nb.mul(L.noise(180.0, 14, detail=1), 0.4))
    # the bail: steel wire, dull
    C.paint(L.k(BAIL), hexc("#8D8F91"), 0.42, 1.0)

    C.finish(ao=0.25, ao_low=0.5, dust=K.DUST)
    return C.channels(dist=0.002, strength=0.6)


def stage_textures():
    kit.reset()
    objs = build_all(baking=True)
    kit.bake_set([(ob, bake.Rig(f"bk_{name}", look)) for name, ob in objs.items()], samples=32)


# --- export ---------------------------------------------------------------------------------

def lens_material():
    if "FlashlightLens" in bpy.data.materials:
        return bpy.data.materials["FlashlightLens"]
    return render.simple("FlashlightLens", hexc("#C9D3D6"), 0.05)


def piece(ob):
    lo, hi = box(ob)
    s, c = hi - lo, (lo + hi) / 2
    return dict(size=(s.x, s.z, s.y), centre=K.to_roblox(c), tris=kit.tris(ob))


def stage_export():
    kit.reset()
    objs = build_all(baking=False)
    ob = objs[K.SET]
    ob.data.materials.append(kit.material())
    lens = lens_geo()
    lens.data.materials.append(lens_material())
    os.makedirs(OUT, exist_ok=True)
    bpy.ops.object.select_all(action="DESELECT")
    ob.select_set(True)
    lens.select_set(True)
    bpy.context.view_layer.objects.active = ob
    bpy.ops.export_scene.fbx(
        filepath=FBX, use_selection=True, object_types={"MESH"},
        apply_scale_options="FBX_SCALE_UNITS", axis_forward="Z", axis_up="Y",
        use_mesh_modifiers=True, mesh_smooth_type="OFF", use_tspace=False,
        add_leaf_bones=False, bake_anim=False, path_mode="COPY", embed_textures=True)
    body, glass = piece(ob), piece(lens)
    print("FBX", FBX, {"Flashlight": body["tris"], "FlashlightLens": glass["tris"]})
    os.makedirs(os.path.join(K.ROOT, "src", "shared", "Flashlight"), exist_ok=True)
    K.write_luau(os.path.join(K.ROOT, "src", "shared", "Flashlight", "Specs.luau"), body, glass)


# --- look sheets ----------------------------------------------------------------------------

# Roblox's frame to Blender's and back (the same matrix both ways): x = -X, y = Z, z = Y.
FLIP = Matrix(((-1, 0, 0, 0), (0, 0, 1, 0), (0, 1, 0, 0), (0, 0, 0, 1)))

# Where the game holds it in first person (src/shared/Flashlight/Torch.luau, `Hold`): the camera's
# right, down and forward in studs, then its turn in degrees (yaw left, pitch up, roll).
HOLD = ((0.62, -0.58, -1.25), (8.0, 4.0, -6.0))


def held(cam, offset, turn):
    """The torch's place in the world for a camera holding it at offset, turned (Roblox's camera
    space, which Blender's camera shares: -Z ahead, +Y up)."""
    yaw, pitch, roll = (math.radians(a) for a in turn)
    R = (Matrix.Rotation(yaw, 4, "Y") @ Matrix.Rotation(pitch, 4, "X")
         @ Matrix.Rotation(roll, 4, "Z"))
    return cam.matrix_world @ Matrix.Translation(Vector(offset)) @ R


def beam(name, energy=180.0, angle=52.0):
    ld = bpy.data.lights.new(name, "SPOT")
    ld.energy = energy
    ld.spot_size = math.radians(angle)
    ld.spot_blend = 0.6
    ld.color = (1.0, 0.86, 0.66)
    ld.shadow_soft_size = 0.02
    ob = bpy.data.objects.new(name, ld)
    bpy.context.scene.collection.objects.link(ob)
    return ob


def glowing(lens, on):
    lens.data.materials.clear()
    if on:
        lens.data.materials.append(render.emissive("lens_on", (1.0, 0.85, 0.62, 1.0), 14.0))
    else:
        lens.data.materials.append(lens_material())


def stage_renders():
    kit.reset()
    render.setup(96, (1600, 900))
    objs = build_all(baking=False)
    ob = objs[K.SET]
    ob.data.materials.append(kit.material())
    lens = lens_geo(bpy.context.scene.collection)
    os.makedirs(SHEETS, exist_ok=True)
    pieces = (ob, lens)

    def place(at, yaw, roll=0.0, pitch=0.0):
        M = (Matrix.Translation(Vector(at)) @ Matrix.Rotation(math.radians(yaw), 4, "Z")
             @ Matrix.Rotation(math.radians(pitch), 4, "X") @ Matrix.Rotation(math.radians(roll), 4, "Y"))
        for p in pieces:
            p.matrix_world = M

    # 1. in the studio: lying on the floor on its head's rim and its tail, from the front
    #    three-quarter (lens off), then the back three-quarter (button, grip rings, tail, bail)
    studio = render.studio_rig()
    for o in studio:
        o.hide_render = False
    glowing(lens, False)
    rest = (0.177, -2.77)  # the axis's height and its tilt, so head and tail both touch
    place((0.0, 0.0, rest[0]), -32, pitch=rest[1])
    cam = render.camera((-1.75, -2.15, 1.3), (0.0, 0.0, 0.12), lens=50)
    render.shoot(cam, os.path.join(SHEETS, "flashlight-front.png"), exposure=-0.2)
    cam = render.camera((1.35, 1.25, 0.9), (0.0, 0.08, 0.12), lens=50)
    render.shoot(cam, os.path.join(SHEETS, "flashlight-back.png"), exposure=-0.2)
    # lit, its beam pooling on the floor in front of it; only the studio's soft fill left on
    for o in studio[1:]:
        o.hide_render = o.name != "studio_fill"
    glowing(lens, True)
    place((0.0, 0.0, rest[0]), 200, pitch=rest[1])
    light = beam("floor_beam")
    lens_at = Vector((0.0, K.LENS["y"] - K.LENS["bulge"] - K.GRIP_Y - 0.03, 0.0))
    light.matrix_world = ob.matrix_world @ Matrix.Translation(lens_at) @ Matrix.Rotation(
        math.radians(-90), 4, "X")
    render.world((0.004, 0.005, 0.008), 1.0)
    cam = render.camera((2.2, -1.2, 1.4), (-0.5, 1.6, 0.0), lens=28)
    render.shoot(cam, os.path.join(SHEETS, "flashlight-lit.png"), exposure=0.3)
    light.hide_render = True
    for o in studio:
        o.hide_render = True

    # 2. your view: in a dark unit among boxes, the hall dead, the torch low on your right and
    #    its beam the only light
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
    # 14.6 mm is Roblox's 70 degree view on a 16:9 screen
    cam = render.camera((0.6, -1.0, 4.6), (-0.4, 9.0, 2.6), lens=14.6)
    bpy.context.view_layer.update()
    M = held(cam, *HOLD) @ FLIP
    for p in pieces:
        p.matrix_world = M
    light = beam("torch")
    front = Vector(K.to_roblox((0.0, K.LENS["y"] - K.LENS["bulge"] - K.GRIP_Y - 0.03, 0.0)))
    light.matrix_world = held(cam, *HOLD) @ Matrix.Translation(front)
    # the light spilling back round the bezel onto the torch (the game's `Spill` light), so it
    # shows in your hand in a dark hall
    sd = bpy.data.lights.new("spill", "POINT")
    sd.energy, sd.color, sd.shadow_soft_size = 0.4, (1.0, 0.86, 0.66), 0.05
    spill = bpy.data.objects.new("spill", sd)
    bpy.context.scene.collection.objects.link(spill)
    spill.matrix_world = held(cam, *HOLD) @ Matrix.Translation(Vector((0.0, 0.25, -0.55)))
    glowing(lens, True)
    render.shoot(cam, os.path.join(SHEETS, "flashlight-view.png"), exposure=0.4)
    # off, in the same unit with its bulb on: the torch in your hand by the bulb's light
    light.hide_render = spill.hide_render = True
    glowing(lens, False)
    bulb = bpy.data.lights.new("bulb", "POINT")
    bulb.energy, bulb.color, bulb.shadow_soft_size = 220.0, (1.0, 0.674, 0.408), 0.08
    bo = bpy.data.objects.new("bulb", bulb)
    bpy.context.scene.collection.objects.link(bo)
    bo.location = (0.0, 6.0, 8.7)
    render.shoot(cam, os.path.join(SHEETS, "flashlight-view-off.png"), exposure=0.2)

STAGES = {"textures": stage_textures, "export": stage_export, "renders": stage_renders}

if __name__ == "__main__":
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    ap = argparse.ArgumentParser()
    ap.add_argument("--stage", choices=list(STAGES), required=True)
    STAGES[ap.parse_args(argv).stage]()
    print("DONE")
