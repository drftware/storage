"""Build the platform cart in Blender, headless (art/cart/README.md).

    blender -b --factory-startup -P art/cart/build.py -- --stage textures|export|renders

Stages:
    textures  the Cart texture set (every part), baked from its recipe into out/textures
    export    out/Cart.fbx (seven MeshParts: the body, two swivel forks, four wheels) and
              src/shared/Cart/Specs.luau
    renders   the look sheets, art/sheets/cart-*.png

It borrows the finds' atlas, bake and export (art/finds/build.py), pointed at its own spec and out
folder, as the ladder does.
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
SPECS = os.path.join(K.ROOT, "src", "shared", "Cart", "Specs.luau")


def finds_kit():
    """The finds' build, as a library: it imports `spec`, which is already this folder's, so its
    atlas size, set name and dust are the cart's; its out paths are pointed here."""
    s = importlib.util.spec_from_file_location("finds_build", os.path.join(FINDS, "build.py"))
    mod = importlib.util.module_from_spec(s)
    s.loader.exec_module(mod)
    assert mod.K is K, "the finds' build must see the cart's spec"
    mod.OUT, mod.TEX, mod.UVS, mod.FBX = OUT, TEX, os.path.join(OUT, "uvs.npz"), FBX
    return mod


kit = finds_kit()

# What a face is, for the recipe (a face attribute).
FRAME, TOP, MAT, HANDLE, GRIP, BUMPER, STEEL, TREAD, HUB, BOLT = range(10)

W, L = K.DECK_W, K.DECK_L
UNDER = K.deck_under()
RIM = K.DECK_TOP + K.LIP
CHUNK = 1.6   # studs: long pieces are cut into lengths this long so their UV islands pack tightly


# --- geometry --------------------------------------------------------------------------------

def bx(m, lo, hi, bevel=0.006):
    geo.box(m, Vector(lo), Vector(hi), bevel=bevel)


def chunks(a, b):
    n = max(1, math.ceil((b - a) / CHUNK))
    return [(a + (b - a) * k / n, a + (b - a) * (k + 1) / n) for k in range(n)]


def loft(m, sections):
    """A closed shape through rings of points, capped at both ends (as the ladder's)."""
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


def tube(m, pts, r, n=12):
    """A round tube through 3D points, in short lengths end to end for the atlas's sake."""
    full = [Vector(pts[0])]
    for p in pts[1:]:
        p = Vector(p)
        d = (p - full[-1]).length
        if d > CHUNK:
            k = math.ceil(d / CHUNK)
            a = full[-1]
            full += [a.lerp(p, i / k) for i in range(1, k)]
        full.append(p)
    run, length = [full[0]], 0.0
    for p in full[1:]:
        run.append(p)
        length += (p - run[-2]).length
        if length >= CHUNK * 0.9:
            one(m, run, r, n)
            run, length = [run[-2], p], (p - run[-2]).length
    if len(run) > 1:
        one(m, run, r, n)


def one(m, pts, r, n):
    secs = []
    for i, p in enumerate(pts):
        t = (pts[min(i + 1, len(pts) - 1)] - pts[max(i - 1, 0)]).normalized()
        a = Vector((1.0, 0.0, 0.0)) - t * t.x
        if a.length < 1e-4:
            a = Vector((0.0, 0.0, 1.0)) - t * t.z
        a.normalize()
        b = t.cross(a)
        secs.append([p + r * (math.cos(2 * math.pi * k / n) * a + math.sin(2 * math.pi * k / n) * b)
                     for k in range(n)])
    loft(m, secs)


def frame(m):
    """The deck's edge: steel channel round all four sides, its web outside, flanges in."""
    t, fl = K.FRAME_T, 0.09
    for sx in (-1, 1):
        for y0, y1 in chunks(-L / 2, L / 2):
            x0, x1 = sorted((sx * W / 2, sx * (W / 2 - t)))
            bx(m, (x0, y0, UNDER), (x1, y1, RIM), 0.0)
            x0, x1 = sorted((sx * (W / 2 - t), sx * (W / 2 - fl)))
            bx(m, (x0, y0, UNDER), (x1, y1, UNDER + t), 0.0)
    for sy in (-1, 1):
        for x0, x1 in chunks(-W / 2 + t, W / 2 - t):
            y0, y1 = sorted((sy * L / 2, sy * (L / 2 - t)))
            bx(m, (x0, y0, UNDER), (x1, y1, RIM), 0.0)
            y0, y1 = sorted((sy * (L / 2 - t), sy * (L / 2 - fl)))
            bx(m, (x0, y0, UNDER), (x1, y1, UNDER + t), 0.0)
    # cross members under the top, between the side channels
    for y in K.CROSS:
        bx(m, (-W / 2 + t, y - 0.05, UNDER + 0.02), (W / 2 - t, y + 0.05, K.DECK_TOP - 0.03), 0.004)


def top(m):
    """The steel top inside the frame, the mat's tray."""
    t = K.FRAME_T
    for y0, y1 in chunks(-L / 2 + t, L / 2 - t):
        bx(m, (-W / 2 + t, y0, K.DECK_TOP - 0.03), (W / 2 - t, y1, K.DECK_TOP), 0.0)


def mat(m):
    """The ribbed rubber mat, inset from the edge."""
    i = K.MAT_IN
    # one piece: lengths end to end showed their seams across the ribs
    bx(m, (-W / 2 + i, -L / 2 + i, K.DECK_TOP), (W / 2 - i, L / 2 - i, K.DECK_TOP + K.MAT_T), 0.006)


def leg(sx, z):
    """A point up the handle's leg at height z (the top leans back)."""
    f = (z - K.DECK_TOP) / (K.HANDLE_TOP - K.DECK_TOP)
    return Vector((sx * K.HANDLE_W / 2, K.HANDLE_Y + f * K.HANDLE_LEAN, z))


def handle(m):
    """The U: up from the left socket, round the corner, across, round, down to the right."""
    r = K.HANDLE_BEND
    pts = [leg(-1, K.DECK_TOP + 0.05), leg(-1, K.HANDLE_TOP - r)]
    top_y = leg(1, K.HANDLE_TOP).y
    for k in range(1, 7):
        a = math.radians(90 * k / 6)
        pts.append(Vector((-K.HANDLE_W / 2 + r - r * math.cos(a), top_y,
                           K.HANDLE_TOP - r + r * math.sin(a))))
    pts.append(Vector((K.HANDLE_W / 2 - r, top_y, K.HANDLE_TOP)))
    for k in range(1, 7):
        a = math.radians(90 - 90 * k / 6)
        pts.append(Vector((K.HANDLE_W / 2 - r + r * math.cos(a), top_y,
                           K.HANDLE_TOP - r + r * math.sin(a))))
    pts.append(leg(1, K.DECK_TOP + 0.05))
    tube(m, pts, K.HANDLE_R)
    # the cross bar between the legs
    a, b = leg(-1, K.HANDLE_BAR), leg(1, K.HANDLE_BAR)
    tube(m, [a, b], K.HANDLE_R * 0.8)


def sockets(m):
    """The welded sockets on the back rail the legs drop into, and their gussets."""
    S = K.SOCKET
    for sx in (-1, 1):
        c = leg(sx, K.DECK_TOP + S["h"] / 2)
        geo.cylinder(m, "z", (c.x, K.HANDLE_Y, K.DECK_TOP + S["h"] / 2 - 0.02), S["r"], S["h"],
                     segs=14, bevel=0.008)
        x0, x1 = sorted((sx * (K.HANDLE_W / 2 - 0.012), sx * (K.HANDLE_W / 2 + 0.012)))
        loft(m, [[Vector((x, K.HANDLE_Y - S["r"] - 0.16, RIM)),
                  Vector((x, K.HANDLE_Y - S["r"] + 0.01, RIM)),
                  Vector((x, K.HANDLE_Y - S["r"] + 0.01, RIM + 0.2))] for x in (x0, x1)])


def grip(m):
    g = K.GRIP
    y = leg(1, K.HANDLE_TOP).y
    geo.cylinder(m, "x", (0.0, y, K.HANDLE_TOP), g["r"], g["w"], segs=16, bevel=0.012)


def bumpers(m):
    """Grey rubber on the front corners, wrapping them, and a strip across the nose."""
    sx_, sy_, sz_ = K.BUMPER["size"]
    for sx in (-1, 1):
        x0, x1 = sorted((sx * (W / 2 - sx_ + 0.02), sx * (W / 2 + 0.025)))
        bx(m, (x0, -L / 2 - 0.06, UNDER - 0.01), (x1, -L / 2 + sy_ - 0.06, RIM + 0.01), 0.03)
    n = K.NOSE_STRIP
    bx(m, (-n["w"] / 2, -L / 2 - n["t"], UNDER + 0.03), (n["w"] / 2, -L / 2, RIM - 0.03), 0.015)


def plates(m):
    """Each caster's top plate under the frame, the fixed casters' forks, the bolts."""
    P = K.PLATE
    for name, sx, y, swivel in K.casters():
        bx(m, (sx - P["w"] / 2, y - P["l"] / 2, UNDER - P["t"]), (sx + P["w"] / 2, y + P["l"] / 2,
                                                                 UNDER), 0.006)
        if swivel:
            # the race's upper half, fixed to the plate
            geo.cylinder(m, "z", (sx, y, UNDER - P["t"] - 0.015), K.RACE["r"], 0.03, segs=18,
                         bevel=0.006)
        else:
            fork(m, sx, y, False)


def plate_bolts(m):
    P = K.PLATE
    for _, sx, y, _s in K.casters():
        for dx in (-1, 1):
            for dy in (-1, 1):
                geo.hexbolt(m, (sx + dx * (P["w"] / 2 - 0.05), y + dy * (P["l"] / 2 - 0.05),
                                UNDER - P["t"]), "z", -1, 0.055, 0.025)


def fork(m, sx, y, swivel):
    """A caster's fork: the crown under the plate (under the race if it swivels), two legs down
    either side of the wheel, rounded at the axle."""
    P = K.PLATE
    ax, ay, az = K.axle(sx, y, swivel)
    top_z = UNDER - P["t"] - (K.RACE["h"] if swivel else 0.0)
    half = K.WHEEL_W / 2 + K.FORK_GAP
    t = K.FORK_T
    # the crown: a plate across both legs
    bx(m, (sx - half - t, y - 0.15, top_z - 0.035), (sx + half + t, ay + 0.1, top_z), 0.006)
    for side in (-1, 1):
        x0, x1 = sorted((sx + side * half, sx + side * (half + t)))
        # the leg: from the crown down to the axle, its rear edge following the trail
        loft(m, [[Vector((x, y - 0.1, top_z - 0.03)), Vector((x, ay + 0.1, top_z - 0.03)),
                  Vector((x, ay + 0.09, az)), Vector((x, ay - 0.09, az))] for x in (x0, x1)])
        geo.cylinder(m, "x", ((x0 + x1) / 2, ay, az), 0.09, t, segs=16)
    if swivel:
        # the race's lower half, turning with the fork
        geo.cylinder(m, "z", (sx, y, top_z + K.RACE["h"] / 2 - 0.015), K.RACE["r"] * 0.94, 0.03,
                     segs=18, bevel=0.006)


def axles(m, swivel_only=None):
    """The axle bolt through the fork and the wheel, a nut each end."""
    half = K.WHEEL_W / 2 + K.FORK_GAP + K.FORK_T
    for name, sx, y, swivel in K.casters():
        if swivel_only is not None and name != swivel_only:
            continue
        if swivel_only is None and swivel:
            continue
        ax, ay, az = K.axle(sx, y, swivel)
        geo.cylinder(m, "x", (sx, ay, az), 0.028, 2 * half + 0.05, segs=10)
        geo.hexbolt(m, (sx + half, ay, az), "x", 1, 0.07, 0.03)
        geo.hexbolt(m, (sx - half, ay, az), "x", -1, 0.07, 0.03)


def tread(m, c):
    geo.cylinder(m, "x", c, K.WHEEL_R, K.WHEEL_W, segs=28, bevel=0.035)


def hub(m, c):
    geo.cylinder(m, "x", c, K.HUB_R, K.WHEEL_W + 0.02, segs=20, bevel=0.01)
    geo.cylinder(m, "x", c, 0.055, K.WHEEL_W + 0.045, segs=12, bevel=0.006)


def body_geo():
    F = kit.Find(K.SET)
    F.add(FRAME, frame)
    F.add(TOP, top)
    F.add(MAT, mat)
    F.add(FRAME, sockets)
    F.add(HANDLE, handle)
    F.add(GRIP, grip)
    F.add(BUMPER, bumpers)
    F.add(STEEL, plates)
    F.add(BOLT, plate_bolts)
    F.add(BOLT, axles)
    return F


def fork_geo(side):
    name = "F" + side
    _, sx, y, _ = next(c for c in K.casters() if c[0] == name)
    F = kit.Find(f"CartFork{side}")
    F.add(STEEL, fork, sx, y, True)
    F.add(BOLT, axles, name)
    return F


def wheel_geo(name):
    _, sx, y, swivel = next(c for c in K.casters() if c[0] == name)
    c = K.axle(sx, y, swivel)
    F = kit.Find(f"CartWheel{name}")
    F.add(TREAD, tread, c)
    F.add(HUB, hub, c)
    return F


ORDER = [K.SET, "CartForkL", "CartForkR", "CartWheelFL", "CartWheelFR", "CartWheelBL",
         "CartWheelBR"]


def build_all(baking, coll=None):
    objs = {K.SET: body_geo().build(40, coll)}
    for side in ("L", "R"):
        objs[f"CartFork{side}"] = fork_geo(side).build(40, coll)
    for name in ("FL", "FR", "BL", "BR"):
        objs[f"CartWheel{name}"] = wheel_geo(name).build(40, coll)
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


PAD = 4   # texels round each UV island (the ladder's)


def unwrap(objs):
    """Every part smart-projected together into the whole atlas (the ladder's way)."""
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


def box(obs):
    vs = [ob.matrix_world @ v.co for ob in obs for v in ob.data.vertices]
    return (Vector([min(v[i] for v in vs) for i in range(3)]),
            Vector([max(v[i] for v in vs) for i in range(3)]))


# --- the recipe --------------------------------------------------------------------------------

def look(nb):
    """Safety-orange powder coat on welded steel, chipped to grey steel on every edge that knocks
    a door frame and rusting a little in the chips; scuffed black where boxes slide off; the
    handle's top worn by hands either side of a black foam grip; a ribbed black rubber mat worn
    grey down the middle where feet go; grey rubber bumpers; zinc caster forks and plates gone
    dull; dark grey tread on pale grey hubs; grime underneath."""
    L_ = kit.Look(nb, K.SEED)
    x, y, z = L_.x, L_.y, L_.z
    edge = nb.edge(0.012, k=5.0)
    paint = L_.k(FRAME, TOP, HANDLE)

    # the powder coat: orange, a little mottled, satin
    mottle = nb.mr(L_.noise(2.2, 1, detail=4), 0.3, 0.7, 0.86, 1.04)
    orange = nb.tint(hexc(K.ORANGE), mottle)
    C = kit.Coat(L_, orange, nb.mr(L_.noise(6.0, 2, detail=3), 0.3, 0.7, 0.42, 0.56), 0.0,
                 nb.mul(L_.noise(90.0, 3, detail=1), 0.03))
    # faded on what faces up (years of the office's lights and sun through the door)
    C.paint(nb.mul(nb.mul(L_.up, paint), 0.35), hexc("#D9895A"))
    # chips to bare steel on the edges that knock things, the most at the nose and the corners
    nose = nb.ss(nb.mul(y, -1.0), 1.4, 2.2)
    chip_n = L_.noise(14.0, 4, detail=5, rough=0.7)
    chips = nb.mul(nb.mul(edge, paint), nb.ss(nb.add(chip_n, nb.mul(nose, 0.1)), 0.58, 0.66))
    C.paint(chips, nb.tint(hexc("#8D9193"), nb.mr(L_.noise(30.0, 5), 0.3, 0.7, 0.7, 1.0)), 0.38,
            0.85, -0.2)
    rust = nb.mul(chips, nb.ss(L_.noise(40.0, 6, detail=3), 0.55, 0.65))
    C.paint(rust, hexc("#6B3A22"), 0.85, 0.15)
    # scuffs: black rubs where boxes slide and shoes kick, on the frame's sides
    scuff = nb.mul(nb.ss(L_.noise(5.0, 7, stretch=(1.0, 0.25, 1.0), detail=4), 0.58, 0.72),
                   L_.k(FRAME))
    C.paint(nb.mul(scuff, 0.7), hexc("#2B2622"), 0.6)
    # long scratches along the deck's sides
    scr = nb.band(L_.noise(5.0, 8, stretch=(1.0, 0.07, 1.0), detail=2), 0.496, 0.504, 0.001)
    C.paint(nb.mul(nb.mul(scr, nb.ss(L_.noise(1.5, 9), 0.48, 0.6)), paint), hexc("#9A8F88"), 0.4,
            0.6, -0.2)

    # the handle: hands wear its top to bare steel either side of the grip, grubby on the legs
    hd = L_.k(HANDLE)
    high = nb.ss(z, K.HANDLE_TOP - 0.35, K.HANDLE_TOP - 0.1)
    hands = nb.mul(nb.mul(hd, high), nb.ss(L_.noise(6.0, 10, detail=4), 0.42, 0.6))
    C.paint(hands, hexc("#7E7F7E"), 0.3, 0.8)
    C.paint(nb.mul(nb.mul(hd, nb.ss(L_.noise(3.0, 11, detail=4), 0.6, 0.75)), 0.25),
            hexc("#5A3A26"), 0.6)

    # the mat: black rubber, ribbed across the deck, worn grey down the middle where feet go,
    # dusty footprints of grey
    mt = L_.k(MAT)
    C.paint(mt, hexc("#1C1C1D"), 0.86, 0.0)
    ribs = nb.band(nb.fract(nb.div(y, K.MAT_RIB)), 0.25, 0.6, 0.08)
    on_top = L_.up
    C.paint(nb.mul(nb.mul(mt, on_top), ribs), hexc("#2A2A2B"), 0.75, height=0.7)
    path = nb.mul(nb.ss(nb.absf(x), 0.75, 0.15), nb.ss(L_.noise(3.0, 12, detail=5), 0.38, 0.62))
    C.paint(nb.mul(nb.mul(nb.mul(mt, on_top), path), 0.6), hexc("#4A4846"), 0.92)
    prints = nb.ss(L_.noise(2.0, 13, detail=6, rough=0.7, distortion=0.8), 0.6, 0.7)
    C.paint(nb.mul(nb.mul(nb.mul(mt, on_top), prints), 0.5), hexc("#6B6760"), 0.95)

    # the top under the mat's edge: the same orange, darker, grimy in the tray
    C.paint(nb.mul(L_.k(TOP), 0.55), hexc("#3A2A20"), 0.7)

    # the foam grip: black, fine-pored, worn shiny where palms go
    gp = L_.k(GRIP)
    C.paint(gp, nb.tint(hexc("#161616"), nb.mr(L_.noise(120.0, 14), 0.3, 0.7, 0.8, 1.2)), 0.92,
            0.0)
    C.paint(nb.mul(gp, nb.ss(L_.noise(5.0, 15, detail=3), 0.5, 0.7)), hexc("#262626"), 0.6)
    C.paint(gp, height=nb.mul(L_.noise(140.0, 16), 0.3))

    # the bumpers: grey rubber, scuffed black on their faces, chalky on top
    bp = L_.k(BUMPER)
    C.paint(bp, nb.tint(hexc("#56595B"), nb.mr(L_.noise(12.0, 17, detail=3), 0.3, 0.7, 0.8, 1.05)),
            0.88, 0.0)
    C.paint(nb.mul(nb.mul(bp, L_.front), nb.ss(L_.noise(8.0, 18, detail=4), 0.45, 0.65)),
            hexc("#232425"), 0.8)

    # zinc-plated steel: the caster plates and forks, gone dull, rust in the corners
    st = L_.k(STEEL)
    # mostly diffuse, as the ladder's aluminium: fully metal it took on the dark and read black
    C.paint(st, nb.tint(hexc("#B9BCB8"), nb.mr(L_.noise(16.0, 19, detail=3), 0.3, 0.7, 0.72,
                                               1.02)), 0.5, 0.55)
    C.paint(nb.mul(st, nb.ss(L_.noise(28.0, 20, detail=3), 0.63, 0.7)), hexc("#6E4129"), 0.85, 0.2)
    bo = L_.k(BOLT)
    C.paint(bo, hexc("#A8ABA7"), 0.45, 0.6)

    # the wheels: dark grey rubber tread, worn smooth and pale on the rolling face; pale grey hubs
    tr = L_.k(TREAD)
    C.paint(tr, hexc("#2C2D2F"), 0.82, 0.0)
    rolling = nb.ss(nb.absf(L_.nx), 0.4, 0.15)     # the tread's face, not its sides
    C.paint(nb.mul(nb.mul(tr, rolling), 0.6), hexc("#4B4C4D"), 0.7)
    hb = L_.k(HUB)
    C.paint(hb, nb.tint(hexc("#A7AAAB"), nb.mr(L_.noise(10.0, 21, detail=3), 0.3, 0.7, 0.8, 1.0)),
            0.55, 0.0)

    # grime from the floors on everything low, and under the deck
    low = nb.ss(z, 0.55, 0.0)
    grime = nb.mul(low, nb.ss(L_.noise(7.0, 22, detail=5), 0.4, 0.62))
    C.paint(nb.mul(grime, 0.7), hexc("#2E2A25"), 0.85)
    under = nb.ss(L_.nz, -0.4, -0.8)
    C.paint(nb.mul(nb.mul(under, paint), 0.55), hexc("#3E2C22"), 0.75)

    C.finish(ao=0.3, ao_low=0.4, dust=K.DUST)
    return C.channels(dist=0.002, strength=0.6)


def stage_textures():
    kit.reset()
    objs = build_all(baking=True)
    kit.bake_set([(ob, bake.Rig(f"bk_{name}", look)) for name, ob in objs.items()], samples=32,
                 pad=PAD)


# --- export ---------------------------------------------------------------------------------

def stage_export():
    kit.reset()
    objs = build_all(baking=False)
    mat_ = kit.material()
    for ob in objs.values():
        ob.data.materials.append(mat_)
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
    rows = {}
    for name in ORDER:
        lo, hi = box([objs[name]])
        s, c = hi - lo, (lo + hi) / 2
        rows[name] = dict(size=(s.x, s.z, s.y), centre=K.to_roblox(c), tris=kit.tris(objs[name]))
    lo, hi = box(list(objs.values()))
    s, c = hi - lo, (lo + hi) / 2
    rows["Bounds"] = dict(size=(s.x, s.z, s.y), centre=K.to_roblox(c),
                          tris=sum(r["tris"] for r in rows.values()))
    print("FBX", FBX, {n: r["tris"] for n, r in rows.items()})
    os.makedirs(os.path.dirname(SPECS), exist_ok=True)
    K.write_luau(SPECS, rows)


# --- look sheets ----------------------------------------------------------------------------

def stage_renders():
    kit.reset()
    render.setup(96, (1600, 900))
    objs = build_all(baking=False)
    mat_ = kit.material()
    obs = list(objs.values())
    for ob in obs:
        ob.data.materials.append(mat_)
    os.makedirs(SHEETS, exist_ok=True)

    def place(M):
        for ob in obs:
            ob.matrix_world = M

    # 1. in the studio: three-quarter from the nose (the bumpers, the mat, the casters), then from
    #    behind at a hand's height (the handle, the grip, the fixed casters)
    studio = render.studio_rig()
    for o in studio:
        o.hide_render = False
    place(Matrix.Identity(4))
    cam = render.camera((-4.6, -5.6, 3.4), (0.0, -0.2, 0.9), lens=32)
    render.shoot(cam, os.path.join(SHEETS, "cart-hero.png"), exposure=-0.2)
    cam = render.camera((4.4, 7.0, 3.4), (0.0, 0.2, 1.3), lens=30)
    render.shoot(cam, os.path.join(SHEETS, "cart-back.png"), exposure=-0.2)
    cam = render.camera((-1.6, -2.4, 0.5), (0.8, -1.4, 0.3), lens=26)
    render.shoot(cam, os.path.join(SHEETS, "cart-caster.png"), exposure=-0.2)
    for o in studio:
        o.hide_render = True

    # 2. in the rack, as the front office lays it (art/lobby/spec.py RACK_*): three carts nose-in
    #    between the hoops, the wall behind, from where you load in at standing height, at a
    #    phone's size (a 70 degree view on a 844 x 390 screen)
    coll = bpy.context.scene.collection
    render.world((0.03, 0.035, 0.04), 1.0)
    floor = render.simple("floor", hexc("#5B5850"), 0.7)
    wall = render.simple("wall", hexc("#2F6466"), 0.8)
    pipe = render.simple("pipe", hexc("#8C8F90"), 0.4, 1.0)
    render.box_obj("floor", (-20.0, -3.0, -0.1), (20.0, 20.0, 0.0), floor, coll)
    render.box_obj("wall", (-20.0, -3.0, 0.0), (20.0, -2.8, 10.0), wall, coll)
    depth = 4.7
    y0 = -2.8 + 0.05
    m = geo.Mesh("hoops")
    for k in range(4):
        hx = -4.5 + 3.0 * k
        geo.sweep(m, [(hx, y0, 0.0), (hx, y0, 1.8), (hx, y0 + depth, 1.8), (hx, y0 + depth, 0.0)],
                  0.07, 10)
    geo.sweep(m, [(-4.5, y0 + 0.1, 1.0), (4.5, y0 + 0.1, 1.0)], 0.07, 10)
    hoops = m.build(coll)
    hoops.data.materials.append(pipe)
    middle = y0 + depth / 2
    for k, turn in enumerate((-1.0, 0.5, 1.5)):
        M = (Matrix.Translation(Vector((-3.0 + 3.0 * k, middle, 0.0)))
             @ Matrix.Rotation(math.radians(turn), 4, "Z"))
        if k == 0:
            place(M)
        else:
            for ob in obs:
                c = ob.copy()
                coll.objects.link(c)
                c.matrix_world = M
    lamp = bpy.data.lights.new("lamp", "AREA")
    lamp.energy, lamp.size, lamp.color = 900.0, 6.0, (1.0, 0.86, 0.7)
    lo_ = bpy.data.objects.new("lamp", lamp)
    coll.objects.link(lo_)
    lo_.location = (0.0, 4.0, 9.0)
    bpy.context.scene.render.resolution_x, bpy.context.scene.render.resolution_y = 844, 390
    cam = render.camera((-7.0, 11.0, 4.6), (0.0, 0.0, 0.6), lens=14.6)
    render.shoot(cam, os.path.join(SHEETS, "cart-rack-phone.png"), exposure=0.0)
    cam = render.camera((-2.4, 6.6, 3.6), (0.0, 0.0, 0.6), lens=22)
    bpy.context.scene.render.resolution_x, bpy.context.scene.render.resolution_y = 1600, 900
    render.shoot(cam, os.path.join(SHEETS, "cart-rack.png"), exposure=0.0)


STAGES = {"textures": stage_textures, "export": stage_export, "renders": stage_renders}

if __name__ == "__main__":
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    ap = argparse.ArgumentParser()
    ap.add_argument("--stage", choices=list(STAGES), required=True)
    STAGES[ap.parse_args(argv).stage]()
    print("DONE")
