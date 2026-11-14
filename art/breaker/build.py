"""Build the breaker box in Blender, headless (art/breaker/README.md).

    blender -b --factory-startup -P art/breaker/build.py -- --stage textures|export|renders

Stages:
    textures  the Breaker texture set, baked from its recipe into out/textures
    export    out/Breaker.fbx (three MeshParts) and src/shared/Breaker/Specs.luau
    renders   the look sheets, art/sheets/breaker-*.png (the hall sheets wear the unit's textures)

It borrows the finds' bake and export (art/finds/build.py), pointed at its own spec and out folder,
as the machine does.
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
from nodes import hexc  # noqa: E402

OUT = os.path.join(HERE, "out")
TEX = os.path.join(OUT, "textures")
SHEETS = os.path.join(K.ROOT, "art", "sheets")
FBX = os.path.join(OUT, f"{K.SET}.fbx")
SPECS = os.path.join(K.ROOT, "src", "shared", "Breaker", "Specs.luau")
UNIT_TEX = os.path.abspath(os.path.join(UNIT, "out", "textures"))


def finds_kit():
    s = importlib.util.spec_from_file_location("finds_build", os.path.join(FINDS, "build.py"))
    mod = importlib.util.module_from_spec(s)
    s.loader.exec_module(mod)
    assert mod.K is K, "the finds' build must see the breaker's spec"
    mod.OUT, mod.TEX, mod.UVS, mod.FBX = OUT, TEX, os.path.join(OUT, "uvs.npz"), FBX
    return mod


kit = finds_kit()

# What a face is, for the recipe (a face attribute).
(BOARD, PAINT, STEEL, CHROME, BLACK, LABEL, RED, ARM) = range(8)

TEXTURED = ["Breaker", "BreakerLever"]
PLAIN = list(K.PLAIN)


# --- geometry --------------------------------------------------------------------------------

def box(F, kind, lo, hi, bevel=0.0, seg=1):
    lo, hi = [min(a, b) for a, b in zip(lo, hi)], [max(a, b) for a, b in zip(lo, hi)]
    F.add(kind, geo.box, tuple(lo), tuple(hi), None, bevel, seg)


def triangle(m, cx, cz, side, y_face, depth):
    """A flat triangle standing point up on the X-Z plane, its face at y_face toward -Y, `depth`
    thick (its back hidden against what it's stuck on)."""
    h = side * math.sqrt(3) / 2
    pts = ((cx - side / 2, cz - h / 3), (cx + side / 2, cz - h / 3), (cx, cz + 2 * h / 3))
    front = [m.vert((x, y_face, z)) for x, z in pts]
    back = [m.vert((x, y_face + depth, z)) for x, z in pts]
    m.face((front[0], front[1], front[2]), None, False)
    for i in range(3):
        j = (i + 1) % 3
        m.face((back[i], back[j], front[j], front[i]), None, False)


def cull(F, hidden):
    """Drop the faces nobody can see, so the atlas spends its texels on the ones they can."""
    m = F.m
    keep = []
    for i, f in enumerate(m.faces):
        vs = [m.verts[j] for j in f]
        if not hidden(sum(vs, Vector()) / len(vs), geo._normal(vs)):
            keep.append(i)
    m.faces = [m.faces[i] for i in keep]
    m.uvs = [m.uvs[i] for i in keep]
    m.smooth = [m.smooth[i] for i in keep]
    F.kinds = [F.kinds[i] for i in keep]


def hidden(c, n):
    """Against the wall or the board, behind the door, inside the box, or under the conduit."""
    (x0, y0, z0), (x1, y1, z1) = K.box_lo_hi()
    if n.y > 0.9:
        return True                                   # every face toward the wall
    if n.y < -0.9 and abs(c.y - K.FRONT) < 0.005:
        return True                                   # the box's front, behind the door
    if n.x < -0.9 and abs(c.x - x1) < 0.03 and abs(c.y - (K.BACK - K.HUB[0])) < 0.3:
        return True                                   # the lever's boss, against the box's side
    if n.z < -0.9 and abs(c.z - z1) < 0.01 and abs(c.x) < x1:
        return True                                   # the conduit's foot, on the box's top
    return False


def breaker_geo():
    """The board, the box and its door, the lamp's bezel, the sticker, the boss under the lever
    and the conduit to the wall's cap: one MeshPart."""
    F = kit.Find("Breaker")
    bx0, bx1, bz0, bz1 = K.BOARD
    box(F, BOARD, (bx0, -K.BOARD_T, bz0), (bx1, 0.0, bz1), 0.012)
    # the board's four screws
    for sx in (bx0 + 0.14, bx1 - 0.14):
        for sz in (bz0 + 0.14, bz1 - 0.14):
            F.add(STEEL, geo.cylinder, "y", (sx, -K.BOARD_T - 0.008, sz), 0.045, 0.016, 12, None,
                  True, False, 0.006)

    (x0, y0, z0), (x1, y1, z1) = K.box_lo_hi()
    box(F, PAINT, (x0, y0, z0), (x1, y1, z1), K.BEVEL, 2)
    # the door: a pan over the whole front, a panel pressed up in its middle
    face = K.door_face()
    box(F, PAINT, (x0 + 0.004, face, z0 + 0.004), (x1 - 0.004, K.FRONT, z1 - 0.004), 0.022, 2)
    inset, rise = K.DOOR_PANEL
    box(F, PAINT, (x0 + inset, face - rise, z0 + inset), (x1 - inset, face + 0.01, z1 - inset),
        0.01)
    panel = face - rise
    # the hinges down its left edge, and the two slotted screws on its right
    hr, hl = K.HINGE
    for dz in K.HINGES:
        F.add(STEEL, geo.cylinder, "z", (x0 - 0.01, K.FRONT - K.DOOR_T * 0.5, K.MID_Z + dz), hr,
              hl, 12, None, True, True, 0.008)
        box(F, STEEL, (x0 - 0.03, K.FRONT - 0.012, K.MID_Z + dz - hl * 0.45),
            (x0 + 0.004, K.FRONT + 0.1, K.MID_Z + dz + hl * 0.45))
    for dz in K.SCREWS:
        F.add(STEEL, geo.cylinder, "y", (x1 - 0.1, face - 0.012, K.MID_Z + dz), 0.055, 0.024, 14,
              None, True, False, 0.008)
    # the pilot lamp's chrome bezel and the black socket the lens sits in
    lx, lz, lr, _ = K.LAMP
    br, bh = K.LAMP_BEZEL
    F.add(CHROME, geo.ring_plate, (lx, panel - bh / 2, K.MID_Z + lz), "y", br, lr + 0.004, bh, 28)
    F.add(BLACK, geo.cylinder, "y", (lx, panel - 0.01, K.MID_Z + lz), lr + 0.01, 0.02, 28, None,
          True, False)
    # the sticker: a yellow lightning-bolt triangle on the panel
    sx, sz, side = K.STICKER
    F.add(LABEL, triangle, sx, K.MID_Z + sz, side, panel - 0.004, 0.004)
    # the round boss the lever turns on, on the box's right side
    px, py, pz = K.pivot()
    bossr, bossh = K.HUB_BOSS
    F.add(PAINT, geo.cylinder, "x", (x1 + bossh / 2 - 0.01, py, pz), bossr, bossh + 0.02, 28, None,
          True, True, 0.012)
    # the conduit: its connector on the box's top, the pipe, two straps, the elbow into the wall
    cx, cy, cr = K.CONDUIT_X, K.CONDUIT_Y, K.CONDUIT_R
    F.add(STEEL, geo.cylinder, "z", (cx, cy, z1 + 0.05), cr + 0.06, 0.1, 6, None, True, False)
    F.add(STEEL, geo.cylinder, "z", (cx, cy, z1 + 0.13), cr + 0.025, 0.08, 20, None, True, False,
          0.01)
    F.add(STEEL, geo.cylinder, "z", (cx, cy, (z1 + 0.17 + K.CONDUIT_TOP) / 2), cr,
          K.CONDUIT_TOP - z1 - 0.17, 20, None, False, True)
    for sz in K.STRAPS:
        box(F, STEEL, (cx - cr - 0.035, cy - cr - 0.035, sz - 0.05), (cx + cr + 0.035, 0.0, sz + 0.05),
            0.012)
        box(F, STEEL, (cx + cr + 0.035, -0.025, sz - 0.05), (cx + cr + 0.2, 0.0, sz + 0.05), 0.008)
        F.add(STEEL, geo.cylinder, "y", (cx + cr + 0.12, -0.035, sz), 0.03, 0.02, 10, None, True,
              False)
    ew, eh = K.ELBOW
    et = K.CONDUIT_TOP
    box(F, STEEL, (cx - ew / 2, cy - ew / 2, et), (cx + ew / 2, cy + ew / 2, et + eh), 0.03)
    box(F, STEEL, (cx - ew / 2 - 0.02, cy - ew / 2 - 0.025, et + 0.04),
        (cx + ew / 2 + 0.02, cy - ew / 2 + 0.01, et + eh - 0.04), 0.01)
    F.add(STEEL, geo.cylinder, "y", (cx, (cy + ew / 2) / 2, et + eh / 2), cr, -(cy + ew / 2) + 0.01,
          20, None, False, True)
    cull(F, hidden)
    return F


def lever_geo():
    """The lever, level and pointing at the hall (-Y), its pivot the origin: a cast hub, a flat
    steel arm, a steel ferrule and the safety-red grip a hand closes round."""
    F = kit.Find("BreakerLever")
    t, w, reach = K.ARM
    gr, gl = K.GRIP
    F.add(ARM, geo.cylinder, "x", (0.0, 0.0, 0.0), K.HUB_R, 0.09, 28, None, True, True, 0.015)
    F.add(STEEL, geo.cylinder, "x", (t + 0.02, 0.0, 0.0), 0.07, 0.04, 6, None, True, False)
    box(F, ARM, (0.0, -reach - 0.04, -w / 2), (t, 0.14, w / 2), 0.02, 2)
    F.add(STEEL, geo.cylinder, "y", (t / 2, -reach - 0.03, 0.0), gr + 0.018, 0.08, 20, None, True,
          True, 0.01)
    F.add(RED, geo.cylinder, "y", (t / 2, -reach - 0.07 - (gl - 0.07) / 2, 0.0), gr, gl - 0.07, 20,
          None, True, True, 0.05)
    return F


def lamp_geo():
    """The pilot lamp's lens, untextured: a domed disc in the bezel, in the breaker's frame."""
    m = geo.Mesh("BreakerLamp")
    lx, lz, lr, bulge = K.LAMP
    face = K.door_face() - K.DOOR_PANEL[1]
    kit.dome(m, (lx, face - 0.02, K.MID_Z + lz), lr, bulge, 24, 4)
    geo.cylinder(m, "y", (lx, face - 0.01, K.MID_Z + lz), lr, 0.02, 24, None, False)
    return m


GEO = {"Breaker": breaker_geo, "BreakerLever": lever_geo}
SHARP = {"Breaker": 30, "BreakerLever": 40}


def unwrap(objs, pad=4):
    """Each part smart-projected alone, then every island packed together at one shared scale
    (the machine's way), so the lever and the box keep the same texels a stud."""
    for o in objs:
        bpy.ops.object.select_all(action="DESELECT")
        o.select_set(True)
        bpy.context.view_layer.objects.active = o
        bpy.ops.object.mode_set(mode="EDIT")
        bpy.ops.mesh.select_all(action="SELECT")
        bpy.ops.uv.smart_project(angle_limit=math.radians(66), island_margin=0.0, area_weight=0.0,
                                 correct_aspect=True, scale_to_bounds=False)
        bpy.ops.object.mode_set(mode="OBJECT")
    ts = bpy.context.scene.tool_settings
    ts.use_uv_select_sync = True
    bpy.ops.object.select_all(action="DESELECT")
    for o in objs:
        o.select_set(True)
    bpy.context.view_layer.objects.active = objs[0]
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.select_all(action="SELECT")
    bpy.ops.uv.pack_islands(rotate=True, rotate_method="CARDINAL", scale=True, margin_method="FRACTION",
                            margin=pad / K.TEX, shape_method="CONCAVE")
    bpy.ops.object.mode_set(mode="OBJECT")
    clash = kit.clashes(objs)
    assert not clash, f"faces share texels in the atlas: {clash}"


def build_all(baking, coll=None):
    objs = {n: GEO[n]().build(SHARP[n], coll) for n in TEXTURED}
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


def build_lamp(coll=None):
    ob = lamp_geo().build(coll, sharp_angle=30)
    ob.data.materials.append(render.simple("plain_BreakerLamp", K.PLAIN["BreakerLamp"], 0.3))
    return ob


def box_of(ob):
    vs = [v.co for v in ob.data.vertices]
    return (Vector([min(v[i] for v in vs) for i in range(3)]),
            Vector([max(v[i] for v in vs) for i in range(3)]))


# --- the recipe --------------------------------------------------------------------------------

def look(nb):
    """A switch box in a storage building's back hall, years past its last coat: grey enamel gone
    chalky, chipped through to red primer and to steel on every edge a dolly has hit, rust weeping
    down from its hinges and screws, the door's right edge and the lever's boss dark and shiny
    from hands; galvanized conduit and straps gone dull; a plywood board, raw and grimy; a yellow
    sticker sun-faded at its corners; the lever's arm black, worn to steel along its edges; its
    grip safety red, ribbed, rubbed dull where the palm goes."""
    L = kit.Look(nb, K.SEED)
    x, y, z = L.x, L.y, L.z
    board, paint, steel, chrome = L.k(BOARD), L.k(PAINT), L.k(STEEL), L.k(CHROME)
    black, label, red, arm = L.k(BLACK), L.k(LABEL), L.k(RED), L.k(ARM)

    # grey enamel (an old industrial grey with a little green in it), uneven and chalky
    grey = nb.tint(hexc("#7C827D"), nb.mr(L.noise(3.0, 1, detail=4), 0.3, 0.7, 0.84, 1.1))
    grey = nb.mixc(nb.mul(L.up, 0.3), grey, hexc("#959A94"))
    C = kit.Coat(L, grey, nb.mr(L.noise(6.0, 2, detail=3), 0.3, 0.7, 0.4, 0.56), 0.0)

    # the seam where the door closes on the box: a dark line round its sides
    seam = nb.mul(paint, nb.band(y, K.FRONT - 0.012, K.FRONT + 0.006, 0.004))
    C.paint(seam, hexc("#1A1B1A"), 0.7)

    # chips on every exposed edge, through to red-oxide primer, the deepest to steel and rusting
    ao = nb.ao(0.06, local=True)
    edge = nb.mul(nb.edge(0.02, k=5.0), nb.ss(ao, 0.55, 0.85))
    chip_n = L.noise(28.0, 3, detail=3, rough=0.65)
    hit = nb.add(chip_n, nb.mul(edge, 0.45))
    C.paint(nb.mul(paint, nb.ss(hit, 0.86, 0.9)), hexc("#7A3B26"), 0.75, 0.0, height=-0.2)
    deep = nb.mul(paint, nb.ss(hit, 0.95, 0.98))
    C.paint(deep, hexc("#8D9092"), 0.4, 0.9, height=-0.35)
    C.paint(nb.mul(deep, nb.ss(L.noise(9.0, 4, detail=3), 0.5, 0.6)), hexc("#5A321D"), 0.85, 0.2)

    # rust weeping down from the hinges' knuckles and the door's screws
    weep = None
    for dz in K.HINGES:
        top = K.MID_Z + dz - K.HINGE[1] / 2
        one = nb.mul(nb.ss(nb.absf(nb.sub(x, -K.W / 2 + 0.06)), 0.1, 0.02),
                     nb.mul(nb.ss(z, top + 0.05, top - 0.02), nb.ss(z, top - 0.9, top - 0.2)))
        weep = one if weep is None else nb.add(weep, one, clamp=True)
    for dz in K.SCREWS:
        top = K.MID_Z + dz - 0.05
        one = nb.mul(nb.ss(nb.absf(nb.sub(x, K.W / 2 - 0.1)), 0.06, 0.01),
                     nb.mul(nb.ss(z, top + 0.03, top - 0.02), nb.ss(z, top - 0.6, top - 0.15)))
        weep = nb.add(weep, one, clamp=True)
    streak = nb.ss(L.noise(40.0, 5, stretch=(1.0, 1.0, 0.06), detail=2), 0.35, 0.65)
    C.paint(nb.mul(paint, nb.mul(weep, nb.mul(streak, 0.75))), hexc("#6B3A1E"), 0.8)

    # hands: the door's right edge where it's pulled, and round the lever's boss, dark and shiny
    pull = nb.mul(nb.ss(x, K.W / 2 - 0.55, K.W / 2 - 0.05), nb.ss(nb.absf(nb.sub(z, K.MID_Z)), 0.9, 0.2))
    px, py, pz = K.pivot()
    boss = nb.ss(L.dist(nb.sub(y, py), nb.sub(z, pz)), 0.55, 0.2)
    boss = nb.mul(boss, nb.ss(x, K.W / 2 - 0.05, K.W / 2 + 0.01))
    hands = nb.mul(paint, nb.mul(nb.add(pull, boss, clamp=True),
                                 nb.ss(L.noise(7.0, 6, detail=3), 0.3, 0.6)))
    C.paint(nb.mul(hands, 0.6), hexc("#4C504C"), 0.3)
    # long scratches across the door and sides
    scr = nb.ss(L.noise(55.0, 7, stretch=(1.0, 1.0, 0.07), detail=1), 0.77, 0.81)
    scr2 = nb.ss(L.noise(45.0, 8, stretch=(0.06, 1.0, 1.0), detail=1), 0.78, 0.82)
    C.paint(nb.mul(paint, nb.mul(nb.add(scr, scr2, clamp=True), 0.55)), hexc("#A3A7A2"), 0.5)

    # the plywood board: pale fir veneer, its grain running up, grey with years of hall grime
    grain = nb.mr(L.noise(9.0, 9, stretch=(1.0, 1.0, 0.04), detail=4, distortion=0.5),
                  0.3, 0.7, 0.78, 1.08)
    ply = nb.tint(hexc("#9C8461"), grain)
    C.paint(board, ply, 0.82, 0.0)
    knots = nb.mul(board, nb.ss(L.noise(2.2, 10, stretch=(1.0, 1.0, 0.4), detail=2), 0.68, 0.74))
    C.paint(nb.mul(knots, 0.7), hexc("#5E4A33"), 0.8)
    grime = nb.mul(board, nb.ss(L.noise(1.5, 11, detail=4), 0.35, 0.75))
    C.paint(nb.mul(grime, 0.55), hexc("#4F4A42"), 0.85)

    # galvanized steel: the zinc's spangle gone dull and grey, a little white rust
    spangle = nb.voronoi(L.vec(s=12), 30.0, out="Color")
    zinc = nb.tint(hexc("#9DA2A2"), nb.mr(nb.gray(spangle), 0.0, 1.0, 0.84, 1.06))
    C.paint(steel, zinc, nb.mr(nb.gray(spangle), 0.0, 1.0, 0.36, 0.55), 0.85)
    wrust = nb.mul(steel, nb.ss(L.noise(12.0, 13, detail=3), 0.62, 0.7))
    C.paint(nb.mul(wrust, 0.6), hexc("#C8C6BC"), 0.8, 0.2)

    C.chrome(chrome, s=15)
    C.paint(black, hexc("#111111"), 0.5, 0.0)

    # the sticker: a black-edged yellow triangle with a black lightning bolt, faded at its tips
    sx, sz, side = K.STICKER
    cz = K.MID_Z + sz
    h = side * math.sqrt(3) / 2
    zb, zt = cz - h / 3, cz + 2 * h / 3
    u = nb.sub(x, sx)
    d_base = nb.sub(z, zb)
    d_side = nb.mul(nb.sub(nb.div(nb.sub(zt, z), math.sqrt(3)), nb.absf(u)), math.sqrt(3) / 2)
    inset = nb.mn(d_base, d_side)
    yellow = nb.tint(hexc("#E8B81C"), nb.mr(L.noise(12.0, 14, detail=3), 0.3, 0.7, 0.9, 1.04))
    C.paint(label, yellow, 0.42, 0.0)
    rim = nb.mul(label, nb.ss(inset, 0.062, 0.054))
    C.paint(rim, hexc("#151515"), 0.45)
    # the bolt: its top stroke runs down to the left, steps right, and the bottom stroke runs on
    # down to the left, narrowing to a point
    v = nb.sub(z, zb + h * 0.4)
    lean = nb.sub(u, nb.mul(v, 0.45))
    stroke = 0.046
    upper = nb.mul(nb.ss(nb.absf(nb.add(lean, 0.052)), stroke + 0.004, stroke - 0.004),
                   nb.band(v, -0.02, 0.22, 0.004))
    taper = nb.add(nb.mul(nb.mr(v, -0.25, -0.08, 0.0, 1.0), stroke), 0.002)
    lower = nb.mul(nb.ss(nb.div(nb.absf(nb.sub(lean, 0.052)), taper), 1.1, 0.9),
                   nb.band(v, -0.25, 0.02, 0.004))
    joint = nb.mul(nb.ss(nb.absf(lean), 0.1, 0.092), nb.ss(nb.absf(v), 0.038, 0.032))
    bolt = nb.mul(label, nb.add(nb.add(upper, lower, clamp=True), joint, clamp=True))
    C.paint(bolt, hexc("#151515"), 0.45)
    fade = nb.mul(label, nb.mul(nb.ss(inset, 0.14, 0.0), nb.ss(L.noise(16.0, 15, detail=3), 0.4, 0.62)))
    C.paint(nb.mul(fade, 0.5), hexc("#C9C3A8"), 0.6)

    # the lever's arm and hub: black paint on cast steel, worn bright along its edges
    C.paint(arm, hexc("#1E1F20"), 0.48, 0.2)
    wear = nb.mul(arm, nb.mul(nb.edge(0.018, k=5.0), nb.ss(L.noise(30.0, 16, detail=2), 0.35, 0.55)))
    C.paint(wear, hexc("#85898B"), 0.35, 0.9)

    # the grip: safety red rubber, ribbed round its length, rubbed dull where the palm closes
    ribs = nb.mr(nb.sin(nb.mul(y, 70.0)), -1.0, 1.0, 0.0, 1.0)
    crimson = nb.tint(hexc("#B3241B"), nb.mr(L.noise(18.0, 17, detail=3), 0.3, 0.7, 0.88, 1.06))
    C.paint(red, crimson, 0.58, 0.0)
    C.paint(nb.mul(red, nb.mul(ribs, 0.35)), hexc("#7E1712"), 0.7, height=-0.15)
    palm = nb.mul(red, nb.mul(nb.ss(nb.absf(nb.add(y, K.ARM[2] + K.GRIP[1] / 2)), 0.25, 0.05),
                              nb.ss(L.noise(8.0, 18, detail=3), 0.35, 0.6)))
    C.paint(nb.mul(palm, 0.6), hexc("#8E2F27"), 0.4)

    C.finish(ao=0.1, ao_low=0.45, dust=K.DUST)
    return C.channels(dist=0.002, strength=0.6)


def rig(name):
    r = bake.Rig(f"bk_{name}", look)
    bump = r.bsdf.inputs["Normal"].links[0].from_node
    bev = r.nb.node("ShaderNodeBevel", samples=8)
    r.nb.put(bev.inputs[0], 0.012)
    r.nb.links.new(bev.outputs[0], bump.inputs["Normal"])
    return r


def stage_textures():
    kit.reset()
    objs = build_all(baking=True)
    for i, ob in enumerate(objs.values()):
        ob.location.x = i * 8.0
    kit.bake_set([(ob, rig(n)) for n, ob in objs.items()], samples=32, pad=4)


# --- export ---------------------------------------------------------------------------------

def stage_export():
    kit.reset()
    objs = build_all(baking=False)
    mat = kit.material()
    for ob in objs.values():
        ob.data.materials.append(mat)
    objs["BreakerLamp"] = build_lamp()
    parts = {}
    for name, ob in objs.items():
        lo, hi = box_of(ob)
        s = hi - lo
        parts[name] = dict(size=(s.x, s.z, s.y), centre=tuple((lo + hi) / 2), tris=kit.tris(ob))
    os.makedirs(OUT, exist_ok=True)
    bpy.ops.object.select_all(action="DESELECT")
    for ob in objs.values():
        ob.select_set(True)
    bpy.context.view_layer.objects.active = objs["Breaker"]
    bpy.ops.export_scene.fbx(
        filepath=FBX, use_selection=True, object_types={"MESH"},
        apply_scale_options="FBX_SCALE_UNITS", axis_forward="Z", axis_up="Y",
        use_mesh_modifiers=True, mesh_smooth_type="OFF", use_tspace=False,
        add_leaf_bones=False, bake_anim=False, path_mode="COPY", embed_textures=True)
    print("FBX", FBX, {n: p["tris"] for n, p in parts.items()})
    os.makedirs(os.path.dirname(SPECS), exist_ok=True)
    K.write_luau(SPECS, parts)


# --- look sheets ----------------------------------------------------------------------------

def lever_at(lever, angle, at=(0.0, 0.0, 0.0)):
    """Stand the lever on its pivot at `angle` above level (Roblox's sense: up is positive)."""
    p = Vector(K.pivot()) + Vector(at)
    lever.matrix_world = Matrix.Translation(p) @ Matrix.Rotation(math.radians(-angle), 4, "X")


def copy(ob, at):
    o = ob.copy()
    bpy.context.scene.collection.objects.link(o)
    o.matrix_world = Matrix.Translation(Vector(at))
    return o


def lit_lamp(ob, on):
    """The lens as the game lights it: green with the power, red without."""
    ob.data = ob.data.copy()
    ob.data.materials.clear()
    col = hexc("#3CFF6A") if on else hexc("#FF2A1A")
    ob.data.materials.append(render.emissive(f"lamp_{on}", col, 9.0))
    glow = bpy.data.lights.new(f"lamp_glow_{on}", "POINT")
    glow.energy, glow.color, glow.shadow_soft_size = 2.5, col[:3], 0.05
    g = bpy.data.objects.new(f"lamp_glow_{on}", glow)
    bpy.context.scene.collection.objects.link(g)
    lo, hi = box_of(ob)
    g.location = ob.matrix_world @ ((lo + hi) / 2) + Vector((0.0, -0.25, 0.0))


def hall(coll):
    """A stretch of hall: the concrete floor, the wall the box hangs on (a unit's facade) and the
    one across, 8 studs off, both 10 high."""
    conc = bake.textured("Concrete", UNIT_TEX)
    fac = bake.textured("Facade", UNIT_TEX)
    m = geo.Mesh("hall_floor")
    geo.add_faces(m, [(-30, -8.5, 0), (30, -8.5, 0), (30, 0.5, 0), (-30, 0.5, 0)], [[0, 1, 2, 3]],
                  geo.map_floor(8.0))
    m.build(coll).data.materials.append(conc)
    for y, name, flip in ((0.0, "wall", False), (-8.0, "across", True)):
        m = geo.Mesh(name)
        pts = [(-30, y, 0), (30, y, 0), (30, y, 10), (-30, y, 10)]
        geo.add_faces(m, pts, [[0, 1, 2, 3] if not flip else [3, 2, 1, 0]], geo.map_wall(10.0))
        m.build(coll).data.materials.append(fac)
    ceil = render.simple("ceiling", hexc("#1C1D1F"), 0.9)
    render.box_obj("ceiling", (-30, -8.5, 13.0), (30, 0.5, 13.4), ceil, coll)


def stage_renders():
    kit.reset()
    render.setup(64, (1600, 900))
    objs = build_all(baking=False)
    mat = kit.material()
    for ob in objs.values():
        ob.data.materials.append(mat)
    body, lever = objs["Breaker"], objs["BreakerLever"]
    lamp = build_lamp()
    os.makedirs(SHEETS, exist_ok=True)
    coll = bpy.context.scene.collection

    # 1. in the studio, on a grey wall: on (lever up, lamp green) beside off (down, red)
    studio = render.studio_rig()
    for o in studio:
        o.hide_render = False
    wall = render.simple("studio_wall", hexc("#4A4C4E"), 0.8)
    render.box_obj("studio_wall", (-12, 0.0, 0.0), (12, 0.4, 12.0), wall, coll)
    left, right = (-2.0, 0.0, 0.0), (2.0, 0.0, 0.0)
    body.matrix_world = Matrix.Translation(Vector(left))
    body2 = copy(body, right)
    lever_at(lever, K.UP, left)
    lever2 = lever.copy()
    coll.objects.link(lever2)
    lever_at(lever2, K.DOWN, right)
    lamp.matrix_world = Matrix.Translation(Vector(left))
    lamp2 = copy(lamp, right)
    lit_lamp(lamp, True)
    lit_lamp(lamp2, False)
    cam = render.camera((3.6, -9.5, 5.4), (0.2, -0.4, 4.6), lens=40)
    render.shoot(cam, os.path.join(SHEETS, "breaker-studio.png"), exposure=-0.3)
    cam = render.camera((6.2, -2.4, 4.8), (2.6, -0.6, 4.6), lens=40)
    render.shoot(cam, os.path.join(SHEETS, "breaker-side.png"), exposure=-0.3)
    for o in studio + [body2, lever2, lamp2]:
        bpy.data.objects.remove(o)
    bpy.data.objects.remove(bpy.data.objects["studio_wall"])
    for n in ("lamp_glow_False",):
        bpy.data.objects.remove(bpy.data.objects[n])

    # 2. in a dark hall, the power cut: only your torch from across the hall, the lamp red, the
    #    lever down; a phone's view (14.6 mm is Roblox's 70 degree view on a 16:9 screen)
    body.matrix_world = Matrix.Identity(4)
    lamp.matrix_world = Matrix.Identity(4)
    lever_at(lever, K.DOWN)
    bpy.data.objects.remove(bpy.data.objects["lamp_glow_True"])
    lit_lamp(lamp, False)
    hall(coll)
    render.world((0.002, 0.0025, 0.004), 1.0)
    cam = render.camera((-5.0, -7.2, 4.6), (0.0, -0.6, 4.4), lens=14.6)
    render.flashlight(cam, True, (0.0, -0.5, 4.4))
    render.shoot(cam, os.path.join(SHEETS, "breaker-dark.png"), exposure=0.3)

    # 3. down the hall in the dark, no torch on it: what the lamp alone gives away
    render.flashlight(cam, False, (0.0, -0.5, 4.4))
    cam = render.camera((-16.0, -5.0, 4.6), (0.0, -1.0, 4.4), lens=14.6)
    render.shoot(cam, os.path.join(SHEETS, "breaker-far.png"), exposure=0.3)

    # 4. switched back on: the lever up, the lamp green, the hall's light over it
    lever_at(lever, K.UP)
    bpy.data.objects.remove(bpy.data.objects["lamp_glow_False"])
    lit_lamp(lamp, True)
    ld = bpy.data.lights.new("hall_light", "AREA")
    ld.shape, ld.size, ld.size_y = "RECTANGLE", 3.8, 0.44
    ld.energy, ld.color, ld.spread = 700.0, (0.86, 0.95, 0.93), math.radians(105)
    lo = bpy.data.objects.new("hall_light", ld)
    lo.location = (2.0, -4.0, 12.1)
    coll.objects.link(lo)
    cam = render.camera((-5.0, -7.2, 4.6), (0.0, -0.6, 4.4), lens=14.6)
    render.shoot(cam, os.path.join(SHEETS, "breaker-on.png"), exposure=0.0)


STAGES = {"textures": stage_textures, "export": stage_export, "renders": stage_renders}

if __name__ == "__main__":
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    ap = argparse.ArgumentParser()
    ap.add_argument("--stage", choices=list(STAGES), required=True)
    STAGES[ap.parse_args(argv).stage]()
    print("DONE")
