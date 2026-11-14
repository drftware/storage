"""Build the battery in Blender, headless (art/battery/README.md).

    blender -b --factory-startup -P art/battery/build.py -- --stage textures|export|renders

Stages:
    textures  the Battery texture set, baked from its recipe into out/textures
    export    out/Battery.fbx (one MeshPart) and src/shared/Battery/Specs.luau
    renders   the look sheets, art/sheets/battery-*.png

It borrows the finds' atlas, bake and export (art/finds/build.py), pointed at its own spec and out
folder, as the coin and the padlock do.
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
import render  # noqa: E402
import spec as K  # noqa: E402
from nodes import hexc  # noqa: E402

OUT = os.path.join(HERE, "out")
TEX = os.path.join(OUT, "textures")
SHEETS = os.path.join(K.ROOT, "art", "sheets")
FBX = os.path.join(OUT, f"{K.SET}.fbx")
SPECS = os.path.join(K.ROOT, "src", "shared", "Battery", "Specs.luau")


def finds_kit():
    """The finds' build, as a library: it imports `spec`, which is already this folder's, so its
    atlas size, set name and dust are the battery's; its out paths are pointed here."""
    s = importlib.util.spec_from_file_location("finds_build", os.path.join(FINDS, "build.py"))
    mod = importlib.util.module_from_spec(s)
    s.loader.exec_module(mod)
    assert mod.K is K, "the finds' build must see the battery's spec"
    mod.OUT, mod.TEX, mod.UVS, mod.FBX = OUT, TEX, os.path.join(OUT, "uvs.npz"), FBX
    return mod


kit = finds_kit()

# What a face is, for the recipe (a face attribute): the button, the cap's bare steel round it,
# the wrap's rolled lips, the wrap's side, the steel bottom.
NUB, CAP, LIP, WRAP, BASE = range(5)


# --- geometry --------------------------------------------------------------------------------

def profile():
    """The battery's outline from the middle of its button round to the middle of its bottom, as
    (radius, height), with each band's kind between one point and the next."""
    zt = K.TOP + K.NUB_H
    top_lip = K.TOP + K.LIP
    bot_lip = K.BOTTOM - K.LIP
    pts = [
        (0.0, zt),
        (K.NUB_R - K.NUB_BEVEL, zt),
        (K.NUB_R, zt - K.NUB_BEVEL),
        (K.NUB_R, K.TOP + 0.006),
        (K.NUB_R + 0.008, K.TOP),
        (K.LIP_IN, K.TOP),
        (K.LIP_IN + 0.012, top_lip),
        (K.R - K.SHOULDER, top_lip),
        (K.R - 0.007, top_lip - 0.007),
        (K.R, top_lip - K.SHOULDER),
        (K.R, bot_lip + K.SHOULDER),
        (K.R - 0.007, bot_lip + 0.007),
        (K.R - K.SHOULDER, bot_lip),
        (K.LIP_IN + 0.012, bot_lip),
        (K.LIP_IN, K.BOTTOM),
        (0.06, K.BOTTOM),
        (0.045, K.BOTTOM + 0.006),
        (0.0, K.BOTTOM + 0.006),
    ]
    kinds = [NUB, NUB, NUB, CAP, CAP, LIP, LIP, LIP, LIP, WRAP, LIP, LIP, LIP, LIP, BASE, BASE,
             BASE]
    assert len(kinds) == len(pts) - 1
    return pts, kinds


class Lathe:
    """The profile turned round Z, its points shared between bands so the battery is one closed
    surface. Each band is added as its own call, so every face knows its kind."""

    def __init__(self):
        self.rings = None

    def points(self, m):
        pts, _ = profile()
        self.rings = []
        for r, z in pts:
            if r == 0.0:
                self.rings.append([m.vert((0.0, 0.0, z))] * K.SEGS)
                continue
            ring = []
            for i in range(K.SEGS):
                a = 2 * math.pi * i / K.SEGS
                ring.append(m.vert((r * math.cos(a), r * math.sin(a), z)))
            self.rings.append(ring)

    def band(self, m, j):
        """Faces between profile points j and j+1, wound so they face out of the battery."""
        a, b = self.rings[j], self.rings[j + 1]
        for i in range(K.SEGS):
            k = (i + 1) % K.SEGS
            if a[i] == a[k]:
                m.face((a[i], b[i], b[k]), None, True)
            elif b[i] == b[k]:
                m.face((a[i], b[i], a[k]), None, True)
            else:
                m.face((a[i], b[i], b[k], a[k]), None, True)


def battery_geo():
    F = kit.Find(K.SET)
    lathe = Lathe()
    F.add(NUB, lathe.points)
    _, kinds = profile()
    for j, kind in enumerate(kinds):
        F.add(kind, lathe.band, j)
    return F


def build_all(baking, coll=None):
    objs = {K.SET: battery_geo().build(35, coll)}
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
    """A D-cell that's been rolling about a concrete floor: a glossy black wrap with a bold amber
    band round its top half, a big black plus on the amber (twice round, so one faces you however
    it lies) and a lightning bolt between them, a thin bright stripe where the amber meets the
    black, a minus and rows of small grey print on the black; nickel steel at the ends, the button
    rubbed bright; the wrap scuffed pale and nicked through to steel at its lips."""
    L = kit.Look(nb, K.SEED)
    x, y, z = L.x, L.y, L.z
    r = L.dist(x, y)
    ang = nb.math("ARCTAN2", y, x)
    half_turn = math.pi * K.R  # studs round the wrap in half a turn

    nub, cap, lip, wrap, base = L.k(NUB), L.k(CAP), L.k(LIP), L.k(WRAP), L.k(BASE)
    film = nb.add(lip, wrap, clamp=True)
    steel = nb.add(nb.add(nub, cap, clamp=True), base, clamp=True)

    # the wrap: glossy black film, a touch uneven where it was shrunk on
    black = nb.tint(hexc("#141414"), nb.mr(L.noise(14.0, 1, detail=3), 0.3, 0.7, 0.85, 1.2))
    C = kit.Coat(L, black, nb.mr(L.noise(9.0, 2, detail=3), 0.3, 0.7, 0.24, 0.36), 0.0)

    # the amber band round its top half, and the bright stripe under it
    amber = nb.tint(hexc("#F2A71E"), nb.mr(L.noise(18.0, 3, detail=3), 0.3, 0.7, 0.92, 1.06))
    band = nb.mul(film, nb.ss(z, K.BAND_FROM - 0.002, K.BAND_FROM + 0.002))
    C.paint(band, amber, 0.3)
    stripe = nb.mul(film, nb.band(z, K.BAND_FROM - K.STRIPE, K.BAND_FROM, 0.0015))
    C.paint(stripe, hexc("#E4E2DA"), 0.22, 0.85)

    # Two frames round the wrap: `su` studs round from the nearest of the +X and -X sides (where
    # the pluses are), `sv` from the nearest of the sides between them (the bolts and the print).
    su = nb.mul(nb.sub(nb.fract(nb.add(nb.div(ang, math.pi), 0.5)), 0.5), half_turn)
    sv = nb.mul(nb.sub(nb.fract(nb.div(ang, math.pi)), 0.5), half_turn)
    au, av = nb.absf(su), nb.absf(sv)

    # the plus, black on the amber
    pz, arm, w = K.PLUS
    dz = nb.absf(nb.sub(z, pz))
    bar_a = nb.mul(nb.ss(au, arm + 0.003, arm - 0.003), nb.ss(dz, w + 0.003, w - 0.003))
    bar_b = nb.mul(nb.ss(au, w + 0.003, w - 0.003), nb.ss(dz, arm + 0.003, arm - 0.003))
    plus = nb.mul(wrap, nb.add(bar_a, bar_b, clamp=True))
    C.paint(plus, hexc("#121212"), 0.34, height=0.12)

    # the lightning bolt, black on the amber between the pluses: two slanted strokes offset
    # across each other and a short bar joining them, a zig-zag
    bz = pz - 0.03
    dv = nb.sub(z, bz)
    lean = nb.sub(sv, nb.mul(dv, 0.5))
    stroke = 0.016
    upper = nb.mul(nb.ss(nb.absf(nb.sub(lean, 0.026)), stroke + 0.003, stroke - 0.003),
                   nb.band(dv, -0.006, 0.105, 0.003))
    lower = nb.mul(nb.ss(nb.absf(nb.add(lean, 0.026)), stroke + 0.003, stroke - 0.003),
                   nb.band(dv, -0.105, 0.006, 0.003))
    joint = nb.mul(nb.ss(nb.absf(lean), 0.044, 0.04), nb.ss(nb.absf(dv), 0.016, 0.012))
    bolt = nb.mul(wrap, nb.add(nb.add(upper, lower, clamp=True), joint, clamp=True))
    C.paint(bolt, hexc("#121212"), 0.34, height=0.12)

    # the minus on the black, under each plus, in a pale grey
    mz, marm, mw = K.MINUS
    minus = nb.mul(wrap, nb.mul(nb.ss(au, marm + 0.003, marm - 0.003),
                                nb.ss(nb.absf(nb.sub(z, mz)), mw + 0.003, mw - 0.003)))
    C.paint(minus, hexc("#B9B7B0"), 0.3)

    # rows of small print on the black under each bolt: short dashes, no real words
    print_ = None
    for row in K.TEXT_ROWS:
        line = nb.mul(nb.band(z, row - 0.011, row + 0.011, 0.002), nb.ss(av, 0.12, 0.115))
        dashes = nb.ss(L.noise(55.0, 7 + int(row * 100), stretch=(1.0, 1.0, 0.05), detail=1),
                       0.42, 0.47)
        one = nb.mul(line, dashes)
        print_ = one if print_ is None else nb.add(print_, one, clamp=True)
    C.paint(nb.mul(wrap, nb.mul(print_, 0.85)), hexc("#8E8C86"), 0.32)

    # scuffs: short pale scratches all over the film from rolling about the floor
    s1 = nb.ss(L.noise(90.0, 11, stretch=(1.0, 1.0, 0.16), detail=1), 0.74, 0.78)
    s2 = nb.ss(L.noise(70.0, 12, stretch=(0.2, 0.2, 1.0), detail=1), 0.75, 0.79)
    scuff = nb.mul(film, nb.add(s1, s2, clamp=True))
    C.paint(nb.mul(scuff, 0.3), hexc("#5A5853"), 0.5)
    rub = nb.mul(film, nb.ss(L.noise(4.0, 13, detail=4), 0.62, 0.78))
    C.paint(nb.mul(rub, 0.25), rough=0.5)

    # the steel: nickel, tarnished in soft patches; the button's top rubbed bright; fine rings
    # pressed into the bottom
    nickel = nb.tint(hexc("#C9CAC6"), nb.mr(L.noise(10.0, 14, detail=4), 0.3, 0.7, 0.78, 1.04))
    C.paint(steel, nickel, nb.mr(L.noise(25.0, 15, detail=3), 0.3, 0.7, 0.18, 0.32), 1.0)
    shine = nb.mul(nub, nb.ss(z, K.TOP + K.NUB_H - 0.004, K.TOP + K.NUB_H - 0.001))
    C.paint(shine, hexc("#EDEDE8"), 0.12)
    rings = nb.mr(nb.sin(nb.mul(r, 260.0)), -1.0, 1.0, 0.0, 1.0)
    C.paint(nb.mul(base, nb.mul(rings, 0.5)), hexc("#9E9F9B"), 0.3, height=-0.2)
    C.paint(nb.mul(cap, nb.band(r, K.NUB_R + 0.02, K.NUB_R + 0.03, 0.003)), hexc("#9A9B97"),
            0.3, height=-0.3)

    # nicks: where the rolled lips caught the concrete the film is chipped through to steel
    nick = nb.mul(lip, nb.ss(L.noise(40.0, 16, detail=2), 0.68, 0.72))
    C.paint(nick, hexc("#A9AAA6"), 0.35, 0.9, height=-0.25)

    C.finish(ao=0.05, ao_low=0.6, dust=K.DUST)
    return C.channels(dist=0.001, strength=0.55)


def stage_textures():
    kit.reset()
    objs = build_all(baking=True)
    kit.bake_set([(ob, bake.Rig(f"bk_{name}", look)) for name, ob in objs.items()], samples=32)


# --- export ---------------------------------------------------------------------------------

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
    lo, hi = box(ob)
    s = hi - lo
    battery = dict(size=(s.x, s.z, s.y), tris=kit.tris(ob))
    print("FBX", FBX, {K.SET: battery["tris"]})
    os.makedirs(os.path.dirname(SPECS), exist_ok=True)
    K.write_luau(SPECS, battery)


# --- look sheets ----------------------------------------------------------------------------

def lying(ob, at, yaw, roll=0.0):
    """Laid on its side on Blender's floor as the game lays it: its middle `at` (x, y) a radius
    up, its button toward +X turned `yaw` degrees, rolled `roll` degrees about its own length."""
    ob.matrix_world = (Matrix.Translation(Vector((at[0], at[1], K.R)))
                       @ Matrix.Rotation(math.radians(yaw), 4, "Z")
                       @ Matrix.Rotation(math.radians(90), 4, "Y")
                       @ Matrix.Rotation(math.radians(roll), 4, "Z"))


def copy(ob):
    o = ob.copy()
    bpy.context.scene.collection.objects.link(o)
    return o


def stage_renders():
    kit.reset()
    render.setup(96, (1600, 900))
    objs = build_all(baking=False)
    ob = objs[K.SET]
    ob.data.materials.append(kit.material())
    os.makedirs(SHEETS, exist_ok=True)

    # 1. in the studio: one standing on its bottom, one lying showing its plus, one its bolt
    studio = render.studio_rig()
    for o in studio:
        o.hide_render = False
    ob.matrix_world = Matrix.Translation(Vector((-0.75, 0.3, 0.45)))
    lying(copy(ob), (0.3, -0.2), 0, roll=-90)
    lying(copy(ob), (0.55, 0.75), 25, roll=0)
    cam = render.camera((0.0, -3.4, 2.0), (0.0, 0.25, 0.3), lens=45)
    render.shoot(cam, os.path.join(SHEETS, "battery-studio.png"), exposure=-0.2)
    for o in studio:
        o.hide_render = True
    for o in list(bpy.context.scene.objects):
        if o.type == "MESH" and o.data == ob.data and o is not ob:
            bpy.data.objects.remove(o)

    # 2. on a unit's floor among boxes, in the bulb's pool, from the doorway at standing height:
    #    the moment the door goes up and there it is
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
    lying(ob, (0.7, 4.6), 70, roll=-60)
    # 14.6 mm is Roblox's 70 degree view on a 16:9 screen
    cam = render.camera((0.0, -1.5, 4.6), (0.4, 5.0, 0.4), lens=14.6)
    render.shoot(cam, os.path.join(SHEETS, "battery-floor.png"), exposure=0.2)

    # 3. the bulb out, only your torch's beam on it: what a dying torch finds
    bulb.energy = 0.0
    cam = render.camera((0.0, -0.5, 4.6), (0.6, 4.6, 0.2), lens=14.6)
    render.flashlight(cam, True, (0.7, 4.6, 0.2))
    render.shoot(cam, os.path.join(SHEETS, "battery-beam.png"), exposure=0.2)

    # 4. stooping over it, about where your tap takes it
    bulb.energy = 220.0
    render.flashlight(cam, False, (0.7, 4.6, 0.2))
    cam = render.camera((0.1, 2.7, 2.3), (0.7, 4.6, 0.15), lens=35)
    render.shoot(cam, os.path.join(SHEETS, "battery-near.png"), exposure=0.2)


STAGES = {"textures": stage_textures, "export": stage_export, "renders": stage_renders}

if __name__ == "__main__":
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    ap = argparse.ArgumentParser()
    ap.add_argument("--stage", choices=list(STAGES), required=True)
    STAGES[ap.parse_args(argv).stage]()
    print("DONE")
