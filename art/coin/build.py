"""Build the coin in Blender, headless (art/coin/README.md).

    blender -b --factory-startup -P art/coin/build.py -- --stage textures|export|renders

Stages:
    textures  the Coin texture set, baked from its recipe into out/textures
    export    out/Coin.fbx (one MeshPart) and src/shared/Coins/Specs.luau (the coin and its piles)
    renders   the look sheets, art/sheets/coin-*.png

It borrows the finds' atlas, bake and export (art/finds/build.py), pointed at its own spec and out
folder, as the padlock does.
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
SPECS = os.path.join(K.ROOT, "src", "shared", "Coins", "Specs.luau")


def finds_kit():
    """The finds' build, as a library: it imports `spec`, which is already this folder's, so its
    atlas size, set name and dust are the coin's; its out paths are pointed here."""
    s = importlib.util.spec_from_file_location("finds_build", os.path.join(FINDS, "build.py"))
    mod = importlib.util.module_from_spec(s)
    s.loader.exec_module(mod)
    assert mod.K is K, "the finds' build must see the coin's spec"
    mod.OUT, mod.TEX, mod.UVS, mod.FBX = OUT, TEX, os.path.join(OUT, "uvs.npz"), FBX
    return mod


kit = finds_kit()

# What a face is, for the recipe (a face attribute).
FIELD, RIM, EDGE = range(3)


# --- geometry --------------------------------------------------------------------------------

def profile():
    """The coin's outline from its top middle round to its bottom middle, as (radius, height):
    the field, the rim's inner wall, its top, its worn outer corner, the edge, and the same
    mirrored underneath. Each band between two points is a ring of faces of one kind."""
    rin = K.R - K.RIM_W
    zf = K.T / 2 - K.FIELD_DROP
    top = [(rin, zf), (rin + K.RIM_SLOPE, K.T / 2), (K.R - K.EDGE_BEVEL, K.T / 2),
           (K.R, K.T / 2 - K.EDGE_BEVEL)]
    pts = [(0.0, zf)] + top + [(r, -z) for r, z in reversed(top)] + [(0.0, -zf)]
    kinds = [FIELD, RIM, RIM, RIM, EDGE, RIM, RIM, RIM, FIELD]
    return pts, kinds


class Lathe:
    """The profile turned round Z, its points shared between bands so the coin is one closed
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
        """Faces between profile points j and j+1, wound so they face out of the coin."""
        a, b = self.rings[j], self.rings[j + 1]
        for i in range(K.SEGS):
            k = (i + 1) % K.SEGS
            if a[i] == a[k]:
                m.face((a[i], b[i], b[k]), None, True)
            elif b[i] == b[k]:
                m.face((a[i], b[i], a[k]), None, True)
            else:
                m.face((a[i], b[i], b[k], a[k]), None, True)


def coin_geo():
    F = kit.Find(K.SET)
    lathe = Lathe()
    F.add(FIELD, lathe.points)
    _, kinds = profile()
    for j, kind in enumerate(kinds):
        F.add(kind, lathe.band, j)
    return F


def build_all(baking, coll=None):
    objs = {K.SET: coin_geo().build(30, coll)}
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
    """Old gold, handled: warm and bright where fingers and floors rub it (the rim's top, the
    beads, the ring round the keyhole), tarnished brown in the low places (the field's edge under
    the rim, the reeding's grooves), the keyhole sunk dark through the middle of each face, and
    the faint scratches of a coin that has been in a lot of pockets."""
    L = kit.Look(nb, K.SEED)
    x, y, z = L.x, L.y, L.z
    r = L.dist(x, y)
    az = nb.absf(z)
    ang = nb.math("ARCTAN2", y, x)

    gold = nb.tint(hexc("#D3A43C"), nb.mr(L.noise(30.0, 1, detail=4), 0.3, 0.7, 0.86, 1.06))
    C = kit.Coat(L, gold, nb.mr(L.noise(8.0, 2, detail=3), 0.3, 0.7, 0.26, 0.38), 1.0)

    field = L.k(FIELD)
    rim = L.k(RIM)
    edge = L.k(EDGE)

    # the field: a touch duller, tarnished in soft patches and in a ring where it meets the rim
    C.paint(field, nb.tint(gold, 0.86), 0.4)
    patches = nb.mul(field, nb.ss(L.noise(6.0, 3, detail=5), 0.5, 0.68))
    C.paint(nb.mul(patches, 0.55), hexc("#8A6322"), 0.55)
    rin = K.R - K.RIM_W
    foot = nb.mul(field, nb.ss(r, rin - 0.035, rin))
    C.paint(nb.mul(foot, 0.7), hexc("#6E4C18"), 0.6, height=-0.15)

    # pocket wear: faint short scratches across both faces, under the stamp's marks
    scratch = nb.ss(L.noise(110.0, 4, stretch=(1.0, 0.18, 1.0), detail=1), 0.68, 0.73)
    scratch2 = nb.ss(L.noise(110.0, 5, stretch=(0.18, 1.0, 1.0), detail=1), 0.69, 0.74)
    worn = nb.mul(nb.add(scratch, scratch2, clamp=True), nb.add(field, rim, clamp=True))
    C.paint(nb.mul(worn, 0.35), hexc("#F7DE96"), 0.22)

    # the beads: a ring of small domes just inside the rim, their tops rubbed bright
    n = float(K.BEADS)
    turn = nb.fract(nb.add(nb.div(nb.mul(ang, n), 2 * math.pi), 0.5))
    arc = nb.mul(nb.absf(nb.sub(turn, 0.5)), 2 * math.pi * K.BEAD_RING / n)
    bead = L.dist(arc, nb.sub(r, K.BEAD_RING))
    beads = nb.mul(field, nb.ss(bead, K.BEAD_R, K.BEAD_R * 0.45))
    C.paint(beads, hexc("#F0CF72"), 0.22, height=0.5)

    # the ring round the keyhole, raised and bright
    ring = nb.mul(field, nb.band(r, K.KEY_RING[0], K.KEY_RING[1], 0.004))
    C.paint(ring, hexc("#EDCB6C"), 0.24, height=0.45)

    # the keyhole, stamped deep: a round head and a flared foot, dark with old grime
    hx, hy, hr = K.KEY_HEAD
    head = nb.ss(L.dist(nb.sub(x, hx), nb.sub(y, hy)), hr + 0.003, hr - 0.003)
    bot, wtop, wbot = K.KEY_FOOT
    along = nb.mr(y, bot, hy, 0.0, 1.0)
    half = nb.add(wbot, nb.mul(along, wtop - wbot))
    foot_k = nb.mul(nb.ss(nb.sub(nb.absf(x), half), 0.003, -0.003), nb.band(y, bot, hy, 0.003))
    hole = nb.mul(field, nb.add(head, foot_k, clamp=True))
    C.paint(hole, hexc("#2B1D0A"), 0.75, 0.6, height=-0.9)
    # its edge catches the light where the stamp pushed the metal up
    lip = nb.mul(field, nb.mul(nb.ss(L.dist(nb.sub(x, hx), nb.sub(y, hy)), hr + 0.016, hr + 0.004),
                               nb.inv(hole)))
    C.paint(nb.mul(lip, 0.6), hexc("#F2D47A"), 0.22)

    # the rim: its top worn back to bright gold, its inner wall a little tarnished
    top = nb.mul(rim, nb.ss(az, K.T / 2 - 0.006, K.T / 2 - 0.002))
    C.paint(top, hexc("#F6D982"), 0.18)
    wall = nb.mul(rim, nb.ss(r, rin + K.RIM_SLOPE, rin))
    C.paint(nb.mul(wall, 0.6), hexc("#9A7128"), 0.45)

    # the edge: fine reeding, the grooves dark, the ridges bright
    reeds = nb.mr(nb.sin(nb.mul(ang, 72.0)), -1.0, 1.0, 0.0, 1.0)
    C.paint(nb.mul(edge, nb.inv(reeds)), hexc("#80591C"), 0.5, height=-0.35)
    C.paint(nb.mul(edge, nb.ss(reeds, 0.7, 0.95)), hexc("#EFCB6A"), 0.22)

    C.finish(ao=0.05, ao_low=0.55, dust=K.DUST)
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
    coin = dict(size=(s.x, s.z, s.y), tris=kit.tris(ob))
    print("FBX", FBX, {K.SET: coin["tris"]})
    os.makedirs(os.path.dirname(SPECS), exist_ok=True)
    K.write_luau(SPECS, coin)


# --- look sheets ----------------------------------------------------------------------------

# Roblox's frame to Blender's and back (the same matrix both ways): x = -X, y = Z, z = Y.
FLIP = Matrix(((-1, 0, 0, 0), (0, 0, 1, 0), (0, 1, 0, 0), (0, 0, 0, 1)))


def orientation(rx, ry, rz):
    """Roblox's CFrame.fromOrientation (Y, then X, then Z, in degrees) in Roblox's axes."""
    return (Matrix.Rotation(math.radians(ry), 4, "Y") @ Matrix.Rotation(math.radians(rx), 4, "X")
            @ Matrix.Rotation(math.radians(rz), 4, "Z"))


def pile(ob, n, at, yaw):
    """Pile `n` laid as the game lays it: its middle at `at` on Blender's floor, turned `yaw`
    degrees. The first coin is `ob` itself; the rest are copies sharing its mesh."""
    coins, _ = K.centred()[n]
    made = []
    for i, (p, turn) in enumerate(coins):
        o = ob if i == 0 else ob.copy()
        if o is not ob:
            bpy.context.scene.collection.objects.link(o)
        # the coin's own Z (through it) is Roblox's Y: flip it into Roblox's frame, place and turn
        # it there, and flip back
        local = Matrix.Translation(Vector(p)) @ orientation(*turn)
        o.matrix_world = (Matrix.Translation(Vector(at)) @ Matrix.Rotation(math.radians(yaw), 4, "Z")
                          @ FLIP @ local @ FLIP)
        made.append(o)
    return made


def stage_renders():
    kit.reset()
    render.setup(96, (1600, 900))
    objs = build_all(baking=False)
    ob = objs[K.SET]
    ob.data.materials.append(kit.material())
    os.makedirs(SHEETS, exist_ok=True)

    # 1. in the studio: the three piles side by side, and a coin standing on its edge behind them
    studio = render.studio_rig()
    for o in studio:
        o.hide_render = False
    pile(ob, 1, (-1.1, 0.0, 0.0), 0)
    two = ob.copy()
    bpy.context.scene.collection.objects.link(two)
    pile(two, 2, (0.0, 0.0, 0.0), 0)
    three = ob.copy()
    bpy.context.scene.collection.objects.link(three)
    pile(three, 3, (1.25, 0.0, 0.0), 0)
    stand = ob.copy()
    bpy.context.scene.collection.objects.link(stand)
    stand.matrix_world = (Matrix.Translation(Vector((0.2, 1.0, K.R)))
                          @ Matrix.Rotation(math.radians(80), 4, "X")
                          @ Matrix.Rotation(math.radians(-15), 4, "Y"))
    cam = render.camera((0.1, -3.6, 2.2), (0.15, 0.2, 0.15), lens=45)
    render.shoot(cam, os.path.join(SHEETS, "coin-studio.png"), exposure=-0.2)
    for o in studio:
        o.hide_render = True
    for o in list(bpy.context.scene.objects):
        if o.type == "MESH" and o.data == ob.data and o is not ob:
            bpy.data.objects.remove(o)

    # 2. on a unit's floor among boxes, in the bulb's pool, from the doorway at standing height:
    #    the moment the door goes up and they catch the light
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
    pile(ob, 3, (0.7, 4.6, 0.0), 35)
    # 14.6 mm is Roblox's 70 degree view on a 16:9 screen
    cam = render.camera((0.0, -1.5, 4.6), (0.4, 5.0, 0.4), lens=14.6)
    render.shoot(cam, os.path.join(SHEETS, "coin-floor.png"), exposure=0.2)

    # 3. stooping over it, about where your tap takes it
    cam = render.camera((0.2, 2.6, 2.4), (0.7, 4.6, 0.1), lens=35)
    render.shoot(cam, os.path.join(SHEETS, "coin-near.png"), exposure=0.2)


STAGES = {"textures": stage_textures, "export": stage_export, "renders": stage_renders}

if __name__ == "__main__":
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    ap = argparse.ArgumentParser()
    ap.add_argument("--stage", choices=list(STAGES), required=True)
    STAGES[ap.parse_args(argv).stage]()
    print("DONE")
