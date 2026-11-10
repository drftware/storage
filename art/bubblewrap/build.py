"""Build the bubble wrap in Blender, headless (art/bubblewrap/README.md).

    blender -b --factory-startup -P art/bubblewrap/build.py -- --stage textures|export|renders

Stages:
    textures  the BubbleWrap texture set, baked from its recipes into out/textures
    export    out/BubbleWrap.fbx (the roll and the sheet, a MeshPart each) and
              src/shared/Tools/Specs/BubbleWrap.luau
    renders   the look sheets, art/sheets/bubblewrap-*.png

It borrows the finds' atlas, bake and export (art/finds/build.py), pointed at its own spec and out
folder, as the air horn does. The atlas is laid out here, not packed: the sheet is a long strip
across the bottom at its own texels a stud, the roll smart-projected into the square above it.
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
import numpy as np  # noqa: E402
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
SPECS = os.path.join(K.ROOT, "src", "shared", "Tools", "Specs", "BubbleWrap.luau")
PAD = 6  # texels between islands, and round the atlas's edge


def finds_kit():
    """The finds' build, as a library: it imports `spec`, which is already this folder's, so its
    atlas size, set name and dust are the bubble wrap's; its out paths are pointed here."""
    s = importlib.util.spec_from_file_location("finds_build", os.path.join(FINDS, "build.py"))
    mod = importlib.util.module_from_spec(s)
    s.loader.exec_module(mod)
    assert mod.K is K, "the finds' build must see the bubble wrap's spec"
    mod.OUT, mod.TEX, mod.UVS, mod.FBX = OUT, TEX, os.path.join(OUT, "uvs.npz"), FBX
    return mod


kit = finds_kit()

# What a face is, for the recipes (a face attribute).
WRAP, END, CORE_OUT, CORE_END, CORE_IN, FILM = range(6)


# --- geometry --------------------------------------------------------------------------------

def revolve(F, profile, segs=K.SEGS):
    """A closed tube turned round the roll's axis (X) through (x, radius, kind) points in inches,
    the last joined back to the first; each point's kind is the band from it to the next. Point 0
    of every ring faces front (-Y). Built in a bmesh, in a fixed order so every stage numbers it
    alike, each face tagged with its band's kind."""
    bm = bmesh.new()
    rings = []
    for x, r, _ in profile:
        rr = r * K.IN
        rings.append([bm.verts.new((x * K.IN, -rr * math.cos(2 * math.pi * i / segs),
                                    rr * math.sin(2 * math.pi * i / segs))) for i in range(segs)])
    kinds = []
    for k, (a, b) in enumerate(zip(rings, rings[1:] + rings[:1])):
        for i in range(segs):
            j = (i + 1) % segs
            bm.faces.new((a[i], a[j], b[j], b[i]))
            kinds.append(profile[k][2])
    n = len(F.m.faces)
    kit.solid(F.m, bm)
    assert len(F.m.faces) - n == len(kinds), "revolve: a face was dropped"
    F.kinds += kinds


def roll_profile():
    """Round the roll's section, left end to right and back through the core: the core's end ring,
    the core standing out past the wrap, the wound end, its soft edge, the outside, the same at
    the right end, then the inside of the core back to the start."""
    hw = K.ROLL_W / 2
    co, ci = K.CORE_R
    xe = hw - K.CORE_OUT   # the wound wrap's ends
    R = K.ROLL_R
    rim = K.RIM
    left = [(-hw, ci, CORE_END), (-hw, co, CORE_OUT), (-xe, co, END)]
    for k, (dx, dr) in enumerate(rim):
        left.append((-xe + dx, R - dr, END if k < 2 else WRAP))
    a, b = -xe + rim[-1][0], xe - rim[-1][0]
    left += [(a + (b - a) * k / K.ROLL_RINGS, R, WRAP) for k in range(1, K.ROLL_RINGS)]
    right = [(xe - dx, R - dr) for dx, dr in reversed(rim)]
    # the mirror of the left's bands: the outer layer's two, then the wound layers' two, then the
    # wound end's face down to the core
    right_kinds = [WRAP] * (len(rim) - 3) + [END] * 3
    out = left + [(x, r, k) for (x, r), k in zip(right, right_kinds)]
    out += [(xe, co, CORE_OUT), (hw, co, CORE_END), (hw, ci, CORE_IN)]
    return out


def roll_geo():
    F = kit.Find(K.SET)
    revolve(F, roll_profile())
    return F


def sheet_z(x, y):
    """The sheet's film height (inches) at x across the hall, y along it: its ends curled up as
    the roll left them, a little ripple everywhere."""
    hl, c = K.SHEET_L / 2, K.CURL
    t = min(max((abs(x) - (hl - c["len"])) / c["len"], 0.0), 1.0)
    curl = c["lift"] * (1.0 - math.cos(t * math.pi / 2))
    rp = K.RIPPLE
    ripple = rp["amp"] * (0.6 * math.sin(2 * math.pi * x / rp["across"] + 0.7)
                          + 0.4 * math.sin(2 * math.pi * (0.4 * x + y) / rp["along"] + 2.1))
    return K.SHEET_Z + curl + ripple


def sheet_geo():
    """One surface, its top only (it lies on a floor and its ends curl up towards the hall, so
    nothing ever sees its underside), wound to face up."""
    F = kit.Find(K.SHEET)
    nx, ny = K.SHEET_NX, K.SHEET_NY
    bm = bmesh.new()
    grid = []
    for j in range(ny + 1):
        y = -K.SHEET_W / 2 + K.SHEET_W * j / ny
        row = []
        for i in range(nx + 1):
            x = -K.SHEET_L / 2 + K.SHEET_L * i / nx
            row.append(bm.verts.new((x * K.IN, y * K.IN, sheet_z(x, y) * K.IN)))
        grid.append(row)
    for j in range(ny):
        for i in range(nx):
            bm.faces.new((grid[j][i], grid[j][i + 1], grid[j + 1][i + 1], grid[j + 1][i]))
    n = len(F.m.faces)
    geo.from_bmesh(F.m, bm, None, smooth=True)
    F.kinds += [FILM] * (len(F.m.faces) - n)
    return F


def uv_layer(o):
    if not o.data.uv_layers:
        o.data.uv_layers.new(name="UVMap")
    return o.data.uv_layers.active.data


def unwrap(objs):
    """The sheet as a strip along the atlas's bottom (square texels), the roll smart-projected by
    the finds' unwrap, then moved into the square above the strip."""
    roll, sheet = objs[K.SET], objs[K.SHEET]
    span = K.TEX - 2 * PAD
    strip = math.floor(span * K.SHEET_W / K.SHEET_L)
    lay = uv_layer(sheet)
    vs = sheet.data.vertices
    for p in sheet.data.polygons:
        for li in p.loop_indices:
            co = vs[sheet.data.loops[li].vertex_index].co
            u = PAD + (co.x / K.IN + K.SHEET_L / 2) / K.SHEET_L * span
            v = PAD + (co.y / K.IN + K.SHEET_W / 2) / K.SHEET_W * strip
            lay[li].uv = (u / K.TEX, v / K.TEX)
    sheet.data.update()

    kit.unwrap([roll])
    uv = np.empty(len(roll.data.loops) * 2, dtype=np.float32)
    roll.data.uv_layers.active.data.foreach_get("uv", uv)
    uv = uv.reshape(-1, 2)
    lo, hi = uv.min(0), uv.max(0)
    v0 = PAD + strip + 2 * PAD
    side = K.TEX - PAD - v0
    s = side / K.TEX / float((hi - lo).max())
    uv = (uv - lo) * s + np.array([PAD, v0], dtype=np.float32) / K.TEX
    roll.data.uv_layers.active.data.foreach_set("uv", uv.ravel())
    roll.data.update()
    clash = kit.clashes([roll, sheet])
    assert not clash, f"faces share texels in the atlas: {clash}"


def build_all(baking, coll=None):
    objs = {K.SET: roll_geo().build(40, coll), K.SHEET: sheet_geo().build(40, coll)}
    for o in objs.values():
        uv_layer(o)
    kit.settle(list(objs.values()))
    if baking:
        unwrap(objs)
        kit.keep_uvs(objs)
    else:
        kit.wear_uvs(objs)
        print(f"atlas: faces on unpainted texels {kit.unpainted(objs)}")
    for name, o in objs.items():
        print(f"atlas: {name} {kit.density([o]):.0f} texels a stud")
    print(f"atlas: uv {kit.uv_hash(list(objs.values()))}")
    return objs


def box(ob):
    vs = [v.co for v in ob.data.vertices]
    return (Vector([min(v[i] for v in vs) for i in range(3)]),
            Vector([max(v[i] for v in vs) for i in range(3)]))


# --- the recipes -------------------------------------------------------------------------------

def bubble_dist(L, a, b):
    """Inches to the nearest bubble's middle, its rows running along a, each row half a bubble on
    from the last: the nearer of two square lattices, one shifted half a pitch and a row."""
    nb = L.nb
    p, h = K.PITCH, K.ROW

    def cell(a, b):
        du = nb.mul(nb.sub(nb.fract(nb.add(nb.div(a, p), 0.5)), 0.5), p)
        dv = nb.mul(nb.sub(nb.fract(nb.add(nb.div(b, 2 * h), 0.5)), 0.5), 2 * h)
        return L.dist(du, dv)

    return nb.mn(cell(a, b), cell(nb.add(a, p / 2), nb.add(b, h)))


def bubbles(C, L, d, keep, bubble, rim):
    """Each bubble a clear dome standing off the film: a little lighter and glossier than the
    film in its middle, where you see through it, and white round its edge, where the plastic
    turns away from you."""
    nb = L.nb
    r = K.BUBBLE_D / 2
    q = nb.div(d, r)
    inside = nb.mul(nb.ss(d, r + 0.03, r - 0.03), keep)
    dome = nb.mul(nb.pw(nb.clamp(nb.sub(1.0, nb.mul(q, q))), 0.5), keep)
    C.paint(inside, bubble, 0.06)
    C.paint(nb.mul(nb.band(d, r * 0.68, r * 0.97, 0.08), keep), rim)
    C.paint(dome, height=1.0)


def roll_look(nb):
    """Clear wrap wound thick enough to go milky, its bubbles out; the wound layers showing at
    each end round a brown cardboard core; the loose end high on the front, its cut edge catching
    the light, held down by a strip of brown packing tape."""
    L = kit.Look(nb, K.SEED)
    x, y, z = L.x, L.y, L.z
    xi, yi, zi = nb.div(x, K.IN), nb.div(y, K.IN), nb.div(z, K.IN)
    ri = L.dist(yi, zi)
    # round the axis from the seam: +-pi at the seam, so the bubbles' rows break there, as the
    # outer layer's do where it ends
    f = math.radians(K.SEAM_AT)
    fwd = nb.mul(yi, -1.0)
    along = nb.add(nb.mul(fwd, math.cos(f)), nb.mul(zi, math.sin(f)))
    across = nb.add(nb.mul(yi, math.sin(f)), nb.mul(zi, math.cos(f)))
    ang = nb.math("ARCTAN2", across, nb.mul(along, -1.0))
    arc = nb.mul(ang, K.ROLL_R)
    to_seam = nb.sub(math.pi, nb.absf(ang))   # radians from the seam

    milky = nb.tint(hexc("#9DB0BA"), nb.mr(L.noise(4.0, 1, detail=4), 0.3, 0.7, 0.9, 1.06))
    C = kit.Coat(L, milky, nb.mr(L.noise(6.0, 2, detail=3), 0.3, 0.7, 0.18, 0.3), 0.0)

    # the outside: bubbles to within the sealed strip of each end
    wrap = L.k(WRAP)
    xe = K.ROLL_W / 2 - K.CORE_OUT
    keep = nb.mul(wrap, nb.band(xi, -xe + K.EDGE, xe - K.EDGE, 0.05))
    bubbles(C, L, bubble_dist(L, xi, arc), keep, hexc("#B0C2CB"), hexc("#E9F2F6"))
    # the sealed strips at the ends, a doubled film
    C.paint(nb.mul(wrap, nb.inv(nb.band(xi, -xe + K.EDGE, xe - K.EDGE, 0.05))), hexc("#B2C3CB"))
    # the seam: the outer layer's cut edge, bright, and the step down to the layer under it
    C.paint(nb.mul(wrap, nb.band(ang, math.pi - 0.05, math.pi - 0.012, 0.008)), hexc("#EEF5F8"),
            height=0.5)
    C.paint(nb.mul(wrap, nb.band(ang, -math.pi, -math.pi + 0.07, 0.015)), hexc("#71858F"),
            height=-0.3)
    # the tape across the seam: brown packing tape, glossy, pressed into the bubbles, its edges
    # lifting pale, a few wrinkles
    t = K.TAPE
    tape = nb.mul(nb.mul(wrap, nb.band(xi, t["x"] - t["w"] / 2, t["x"] + t["w"] / 2, 0.03)),
                  nb.ss(to_seam, t["len"] / 2 / K.ROLL_R + 0.02, t["len"] / 2 / K.ROLL_R - 0.02))
    amber = nb.tint(hexc("#A8702F"), nb.mr(L.noise(9.0, 3, detail=3), 0.3, 0.7, 0.85, 1.12))
    C.paint(tape, amber, 0.16)
    lift = nb.mul(tape, nb.inv(nb.band(xi, t["x"] - t["w"] / 2 + 0.12, t["x"] + t["w"] / 2 - 0.12,
                                       0.04)))
    C.paint(lift, hexc("#C9995E"), 0.22)
    crease = nb.mul(tape, nb.band(L.noise(3.0, 4, stretch=(0.2, 1.0, 1.0), detail=2),
                                  0.49, 0.51, 0.006))
    C.paint(crease, hexc("#D2A673"), height=0.4)

    # the ends: the wound layers seen edge on, a bright film line at each turn, the bubbles
    # squashed between them as pale lenses
    end = L.k(END)
    ph = nb.add(nb.div(nb.sub(ri, K.CORE_R[0]), K.LAYER), nb.mul(L.noise(2.0, 5, detail=2), 0.25))
    C.paint(end, hexc("#7A8E98"), 0.3)
    round_arc = nb.mul(nb.math("ARCTAN2", zi, fwd), ri)
    lens = nb.mul(nb.band(nb.fract(ph), 0.22, 0.86, 0.08),
                  nb.band(nb.fract(nb.div(round_arc, K.PITCH)), 0.18, 0.82, 0.1))
    C.paint(nb.mul(end, lens), hexc("#A7BBC4"), 0.2, height=0.4)
    C.paint(nb.mul(end, nb.band(nb.fract(ph), 0.0, 0.1, 0.03)), hexc("#D4E1E6"), 0.15)

    # the core: kraft board, its end ring frayed pale, darker inside with its wound seam
    core = L.k(CORE_OUT, CORE_END)
    kraft = nb.tint(hexc("#9A7650"), nb.mr(L.noise(12.0, 6, detail=4), 0.3, 0.7, 0.85, 1.1))
    C.paint(core, kraft, 0.86)
    fray = nb.mul(L.k(CORE_END), nb.ss(L.noise(30.0, 7, detail=4), 0.45, 0.62))
    C.paint(fray, hexc("#BC9D73"), 0.9)
    inner = L.k(CORE_IN)
    C.paint(inner, nb.tint(hexc("#6A5036"), nb.mr(L.noise(10.0, 8, detail=3), 0.3, 0.7, 0.8, 1.1)),
            0.9)
    helix = nb.fract(nb.add(nb.div(nb.math("ARCTAN2", zi, fwd), 2 * math.pi), nb.div(xi, 5.0)))
    C.paint(nb.mul(inner, nb.band(helix, 0.0, 0.025, 0.006)), hexc("#3E2D1E"), height=-0.4)

    C.finish(ao=0.2, ao_low=0.5, dust=K.DUST)
    return C.channels(dist=K.BUBBLE_H * K.IN, strength=1.0)


def sheet_look(nb):
    """Fresh wrap laid flat: clear film with the concrete's grey under it, bubbles up, glossy,
    whiter round their edges; a sealed strip along each long edge; a few long creases."""
    L = kit.Look(nb, K.SEED + 1)
    xi, yi = nb.div(L.x, K.IN), nb.div(L.y, K.IN)
    film = nb.tint(hexc("#5E6A70"), nb.mr(L.noise(3.0, 1, detail=4), 0.3, 0.7, 0.9, 1.08))
    C = kit.Coat(L, film, nb.mr(L.noise(5.0, 2, detail=3), 0.3, 0.7, 0.16, 0.26), 0.0)
    hw = K.SHEET_W / 2
    keep = nb.band(yi, -hw + K.EDGE, hw - K.EDGE, 0.05)
    C.paint(nb.inv(keep), hexc("#76848B"))
    bubbles(C, L, bubble_dist(L, xi, yi), keep, hexc("#7E9099"), hexc("#D6E3E9"))
    crease = nb.band(L.noise(1.5, 3, stretch=(0.25, 1.0, 1.0), detail=2), 0.496, 0.504, 0.008)
    C.paint(nb.mul(crease, nb.mul(nb.ss(L.noise(1.0, 4), 0.45, 0.6), 0.45)), hexc("#8E9BA2"),
            height=0.15)
    C.finish(ao=0.05, ao_low=0.8, dust=0.0)
    return C.channels(dist=K.BUBBLE_H * K.IN, strength=1.0)


def stage_textures():
    kit.reset()
    objs = build_all(baking=True)
    kit.bake_set([(objs[K.SET], bake.Rig("bk_roll", roll_look)),
                  (objs[K.SHEET], bake.Rig("bk_sheet", sheet_look))], samples=32)


# --- export ---------------------------------------------------------------------------------

def piece(ob):
    lo, hi = box(ob)
    s, c = hi - lo, (lo + hi) / 2
    return dict(size=(s.x, s.z, s.y), centre=K.to_roblox(c), tris=kit.tris(ob))


def stage_export():
    kit.reset()
    objs = build_all(baking=False)
    mat = kit.material()
    os.makedirs(OUT, exist_ok=True)
    bpy.ops.object.select_all(action="DESELECT")
    for ob in objs.values():
        ob.data.materials.append(mat)
        ob.select_set(True)
    bpy.context.view_layer.objects.active = objs[K.SET]
    bpy.ops.export_scene.fbx(
        filepath=FBX, use_selection=True, object_types={"MESH"},
        apply_scale_options="FBX_SCALE_UNITS", axis_forward="Z", axis_up="Y",
        use_mesh_modifiers=True, mesh_smooth_type="OFF", use_tspace=False,
        add_leaf_bones=False, bake_anim=False, path_mode="COPY", embed_textures=True)
    roll, sheet = piece(objs[K.SET]), piece(objs[K.SHEET])
    print("FBX", FBX, {K.SET: roll["tris"], K.SHEET: sheet["tris"]})
    os.makedirs(os.path.dirname(SPECS), exist_ok=True)
    K.write_luau(SPECS, roll, sheet)


# --- look sheets ----------------------------------------------------------------------------

# Roblox's frame to Blender's and back (the same matrix both ways): x = -X, y = Z, z = Y.
FLIP = Matrix(((-1, 0, 0, 0), (0, 0, 1, 0), (0, 1, 0, 0), (0, 0, 0, 1)))

# Where the game holds the roll in first person (src/shared/Tools/Catalog.luau, the row's `hold`
# and `holdTurn`): the camera's right, up and back in studs, then its turn in degrees (yaw left,
# pitch up, roll).
HOLD = ((-1.3, -1.2, -2.6), (240.0, -8.0, 0.0))


def held(cam, offset, turn):
    """The roll's place in the world for a camera holding it at offset, turned (Roblox's camera
    space, which Blender's camera shares: -Z ahead, +Y up)."""
    yaw, pitch, roll = (math.radians(a) for a in turn)
    R = (Matrix.Rotation(yaw, 4, "Y") @ Matrix.Rotation(pitch, 4, "X")
         @ Matrix.Rotation(roll, 4, "Z"))
    return cam.matrix_world @ Matrix.Translation(Vector(offset)) @ R


def stage_renders():
    kit.reset()
    render.setup(96, (1600, 900))
    objs = build_all(baking=False)
    mat = kit.material()
    for ob in objs.values():
        ob.data.materials.append(mat)
    ob, sheet = objs[K.SET], objs[K.SHEET]
    os.makedirs(SHEETS, exist_ok=True)

    # on its side, as the game lays it: its lowest point on the floor
    lo, _ = box(ob)

    def lay(at, yaw):
        ob.matrix_world = (Matrix.Translation(Vector(at)) @ Matrix.Rotation(math.radians(yaw), 4, "Z")
                           @ Matrix.Translation(Vector((0.0, 0.0, -lo.z))))

    # 1. in the studio: the roll from its front three-quarter (an end's wound layers and core, the
    #    taped seam), then the sheet laid flat from standing height, the roll beside it for size
    studio = render.studio_rig()
    for o in studio:
        o.hide_render = False
    sheet.hide_render = True
    lay((0.0, 0.0, 0.0), 0)
    cam = render.camera((-2.0, -3.0, 1.5), (0.0, 0.0, 0.32), lens=35)
    render.shoot(cam, os.path.join(SHEETS, "bubblewrap-roll.png"), exposure=-0.2)
    sheet.hide_render = False
    lay((1.6, -2.2, 0.0), 25)
    cam = render.camera((-2.6, -6.4, 4.6), (0.2, 0.0, 0.0), lens=28)
    render.shoot(cam, os.path.join(SHEETS, "bubblewrap-sheet.png"), exposure=-0.2)
    sheet.hide_render = True
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
    render.shoot(cam, os.path.join(SHEETS, "bubblewrap-floor.png"), exposure=0.2)

    # 3. your view: held low on your left in the same unit
    cam = render.camera((0.6, -1.0, 4.6), (-0.4, 9.0, 2.6), lens=14.6)
    bpy.context.view_layer.update()
    ob.matrix_world = held(cam, *HOLD) @ FLIP
    render.shoot(cam, os.path.join(SHEETS, "bubblewrap-view.png"), exposure=0.2)


STAGES = {"textures": stage_textures, "export": stage_export, "renders": stage_renders}

if __name__ == "__main__":
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    ap = argparse.ArgumentParser()
    ap.add_argument("--stage", choices=list(STAGES), required=True)
    STAGES[ap.parse_args(argv).stage]()
    print("DONE")
