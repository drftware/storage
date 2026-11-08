"""Build the freight elevator in Blender, headless (art/elevator/README.md).

    blender -b --factory-startup -P art/elevator/build.py -- --stage labels|textures|export|renders

Stages:
    labels    out/labels.png: the digits engraved on the keypad's keys
    textures  the Car, Elevator and Keypad texture sets, baked from their recipes into out/textures
    export    out/Elevator.fbx (every part, one MeshPart each) and src/shared/Elevator/Specs.luau
    renders   the look sheets, art/sheets/elevator-*.png

The car's walls, ceiling and floor plates wear the Car set, which tiles across (the unit's
Partition does the same). Everything else borrows the finds' atlas, bake and export
(art/finds/build.py) twice, once for the Elevator set and once for the Fittings set: each part
smart-projected alone, every island of a set then packed together at one scale, the unwrap
saved and worn by every later stage.
"""

import argparse
import importlib.util
import math
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
UNIT = os.path.join(HERE, "..", "unit")
FINDS = os.path.abspath(os.path.join(HERE, "..", "finds"))
MANNEQUIN = os.path.abspath(os.path.join(HERE, "..", "mannequin"))
sys.path.insert(0, UNIT)
sys.path.insert(0, HERE)  # first: this folder's spec.py

import bmesh  # noqa: E402
import bpy  # noqa: E402
from mathutils import Matrix, Vector  # noqa: E402

import bake  # noqa: E402
import geo  # noqa: E402
import render  # noqa: E402
import spec as K  # noqa: E402
from materials import Channels  # noqa: E402
from nodes import NB, Coords, hexc  # noqa: E402

OUT = os.path.join(HERE, "out")
TEX = os.path.join(OUT, "textures")
UNIT_TEX = os.path.join(UNIT, "out", "textures")
SHEETS = os.path.join(K.ROOT, "art", "sheets")
FBX = os.path.join(OUT, "Elevator.fbx")
LABELS = os.path.join(OUT, "labels.png")


def finds_kit():
    s = importlib.util.spec_from_file_location("finds_build", os.path.join(FINDS, "build.py"))
    mod = importlib.util.module_from_spec(s)
    s.loader.exec_module(mod)
    assert mod.K is K, "the finds' build must see the elevator's spec"
    return mod


kit = finds_kit()


def use_set(name):
    """Point the finds' kit at one of this folder's unique sets: its name, unwrap and cover."""
    K.SET = name
    kit.OUT = os.path.join(OUT, name)
    kit.TEX, kit.UVS, kit.FBX = TEX, os.path.join(OUT, name, "uvs.npz"), FBX


# What a face is, for the recipes (a face attribute).
(DARK, STEEL, WOOD, HAZARD, BOLT, ALU, CREAM, GATE, CAST, WIRE, RUBBER,
 HOUSING, BACKPLATE, KEY, BEZEL, PAPER, GLUE) = range(17)

UNIQUE = {
    "Elevator": ["CarFront", "CarTrim", "Portal", "LandingSill"],
    "Fittings": ["GatePicket", "GateStrap", "GateLead", "Lamp", "Keypad"] +
                [f"Key{d}" for d in range(10)] + ["Note"],
}
ALL = UNIQUE["Elevator"] + UNIQUE["Fittings"]
PAD = {"Keypad", "Note"} | {f"Key{d}" for d in range(10)}  # painted by pad_look
PLAIN = {  # untextured: imported without a SurfaceAppearance, so the game sets Material and Color
    "LampGlass": (1.0, 0.86, 0.66),
    "KeypadReadout": (0.09, 0.02, 0.02),
    "KeypadLight": (0.6, 0.05, 0.03),
}


def reset():
    bpy.ops.wm.read_factory_settings(use_empty=True)


# --- geometry --------------------------------------------------------------------------------

def box(F, kind, lo, hi, bevel=0.0, seg=1):
    lo, hi = [min(a, b) for a, b in zip(lo, hi)], [max(a, b) for a, b in zip(lo, hi)]
    F.add(kind, geo.box, tuple(lo), tuple(hi), None, bevel, seg)


def stud(F, kind, at, axis, sign, r, h, segs=6):
    """A round head (a rivet, a carriage bolt, a screw) on a face pointing along +/- axis: a few
    flat sides, rounded by the bake's bevel."""
    c = list(at)
    c["xyz".index(axis)] += sign * h / 2
    F.add(kind, geo.cylinder, axis, tuple(c), r, h, segs, None, True, True)


def cull(F, hidden):
    """Drop the faces nobody can see (against a wall, under a sill, up in the shaft), so the
    atlas spends its texels on the ones they can. hidden(centre, normal) says which."""
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


def lathe(m, profile, cx, cy, segs):
    """A closed solid of revolution about the vertical through (cx, cy): profile (r, z) from top
    to bottom, its first and last points on the axis."""
    bm = bmesh.new()
    rings = []
    for r, z in profile[1:-1]:
        rings.append([bm.verts.new((cx + r * math.cos(2 * math.pi * i / segs),
                                    cy + r * math.sin(2 * math.pi * i / segs), z))
                      for i in range(segs)])
    top = bm.verts.new((cx, cy, profile[0][1]))
    bot = bm.verts.new((cx, cy, profile[-1][1]))
    for a, b in zip(rings, rings[1:]):
        for i in range(segs):
            j = (i + 1) % segs
            bm.faces.new((a[i], a[j], b[j], b[i]))
    for i in range(segs):
        j = (i + 1) % segs
        bm.faces.new((top, rings[0][j], rings[0][i]))
        bm.faces.new((bot, rings[-1][i], rings[-1][j]))
    kit.solid(m, bm)


def car_mesh():
    """The car's inside, UV-mapped onto the Car set: each wall a span of the wall band, the
    floor in plates the depth of the floor band, the ceiling in panels wearing a wall's top."""
    m = geo.Mesh("Car")
    T, FB, H = K.TILE, K.FLOOR_BAND, K.CAR_H
    w, y0, y1 = K.CAR_W / 2, K.POST_Y[1], K.CAR_BACK

    def quad(pts, uvs):
        base = len(m.verts)
        for p in pts:
            m.vert(p)
        m.face([base + i for i in range(4)], [tuple(u) for u in uvs])

    def wall(u0, v_of):
        return lambda us, z: (u0 + us / T, (FB + z) / T)
    back = wall(K.WALL_U["back"], None)
    quad([(-w, y1, 0), (w, y1, 0), (w, y1, H), (-w, y1, H)],
         [back(0, 0), back(2 * w, 0), back(2 * w, H), back(0, H)])
    left = wall(K.WALL_U["left"], None)
    quad([(-w, y0, 0), (-w, y1, 0), (-w, y1, H), (-w, y0, H)],
         [left(0, 0), left(y1 - y0, 0), left(y1 - y0, H), left(0, H)])
    right = wall(K.WALL_U["right"], None)
    quad([(w, y1, 0), (w, y0, 0), (w, y0, H), (w, y1, H)],
         [right(0, 0), right(y1 - y0, 0), right(y1 - y0, H), right(0, H)])
    # the floor in plates from the back, each up to a plate deep; the front one cut short
    yb, k = y1, 0
    while yb > K.CAR_SILL[1] + 1e-6:
        ya = max(yb - FB, K.CAR_SILL[1])
        u0 = 0.13 + 0.29 * k
        vb, va = FB / T, (FB - (yb - ya)) / T
        quad([(-w, ya, 0), (w, ya, 0), (w, yb, 0), (-w, yb, 0)],
             [(u0, va), (u0 + 2 * w / T, va), (u0 + 2 * w / T, vb), (u0, vb)])
        yb, k = ya, k + 1
    # the ceiling: panels across the car, each wearing the top of a wall
    d = (y1 - y0) / K.CEIL_STRIPS
    for k in range(K.CEIL_STRIPS):
        ya, yb = y0 + k * d, y0 + (k + 1) * d
        u0 = 0.53 + 0.23 * k
        va, vb = (T - d) / T, 1.0
        quad([(w, ya, H), (-w, ya, H), (-w, yb, H), (w, yb, H)],
             [(u0, va), (u0 + 2 * w / T, va), (u0 + 2 * w / T, vb), (u0, vb)])
    return m


def car_front():
    """The car's front: posts, fascia, the gate's track, the striped sill and its apron."""
    F = kit.Find("CarFront")
    w, H = K.CAR_W / 2, K.CAR_H
    ya, yb = K.POST_Y
    for s in (-1, 1):
        box(F, DARK, (s * w, ya, 0), (s * (w - K.POST), yb, H), 0.015)
        for z in (1.2, 4.6, 8.0):
            stud(F, BOLT, (s * (w - K.POST / 2), ya, z), "y", -1, 0.045, 0.03, 6)
    box(F, DARK, (-w + K.POST, ya, K.FASCIA), (w - K.POST, yb, H), 0.015)
    for x in (-4.5, -1.5, 1.5, 4.5):
        stud(F, BOLT, (x, ya, (K.FASCIA + H) / 2), "y", -1, 0.045, 0.03, 6)
    t0, t1 = K.TRACK
    box(F, STEEL, (-w + K.POST, 0.70, t1 - 0.13), (w - K.POST, 1.0, t1))
    box(F, STEEL, (-w + K.POST, 0.70, t0), (w - K.POST, 0.73, t1 - 0.13))
    box(F, STEEL, (-w + K.POST, 0.97, t0), (w - K.POST, 1.0, t1 - 0.13))
    g0, g1 = K.GROOVE
    box(F, HAZARD, (-w, K.CAR_SILL[0], -0.12), (w, g0, 0.02), 0.01)
    box(F, HAZARD, (-w, g1, -0.12), (w, K.CAR_SILL[1], 0.02), 0.01)
    box(F, STEEL, (-w, g0, -0.12), (w, g1, -0.04))
    box(F, DARK, (-w, K.CAR_SILL[0], -K.TOE), (w, K.CAR_SILL[0] + 0.04, -0.12))
    cull(F, lambda c, n: (n.y > 0.9 and c.z < -0.1) or (n.z < -0.9 and c.z < -0.03)
         or (abs(n.x) > 0.9 and abs(c.x) > w - 0.01) or (n.z > 0.9 and c.z > H - 0.01))
    return F


def car_trim():
    """The bumper boards round the car's three walls and the ceiling's escape hatch."""
    F = kit.Find("CarTrim")
    w, H = K.CAR_W / 2, K.CAR_H
    yb = K.POST_Y[1]
    # oak bumper boards on steel brackets, at a dolly's height, round the three walls
    b, off = K.BOARD, 0.04
    for z0, z1 in K.RAILS:
        zc = (z0 + z1) / 2
        box(F, WOOD, (-w + off + b, K.CAR_BACK - off - b, z0), (w - off - b, K.CAR_BACK - off, z1), 0.03, 2)
        for x in (-4.0, 0.0, 4.0):
            box(F, STEEL, (x - 0.06, K.CAR_BACK - off, zc - 0.3), (x + 0.06, K.CAR_BACK, zc + 0.3))
            stud(F, BOLT, (x, K.CAR_BACK - off - b, zc), "y", -1, 0.04, 0.025)
        for s in (-1, 1):
            box(F, WOOD, (s * (w - off), yb + 0.3, z0), (s * (w - off - b), K.CAR_BACK - off, z1), 0.03, 2)
            for y in (2.4, 6.5, 10.6):
                box(F, STEEL, (s * (w - off), y - 0.06, zc - 0.3), (s * w, y + 0.06, zc + 0.3))
                stud(F, BOLT, (s * (w - off - b), y, zc), "x", -s, 0.04, 0.025)
    # the escape hatch: a frame on the ceiling, two hinges and a latch
    hx, hy, hs = K.HATCH
    e, p = hs / 2, 0.1
    box(F, CREAM, (hx - e, hy - e, H - 0.04), (hx + e, hy - e + p, H))
    box(F, CREAM, (hx - e, hy + e - p, H - 0.04), (hx + e, hy + e, H))
    box(F, CREAM, (hx - e, hy - e + p, H - 0.04), (hx - e + p, hy + e - p, H))
    box(F, CREAM, (hx + e - p, hy - e + p, H - 0.04), (hx + e, hy + e - p, H))
    for x in (-0.9, 0.9):
        box(F, STEEL, (hx + x - 0.18, hy + e - 0.05, H - 0.07), (hx + x + 0.18, hy + e + 0.1, H - 0.02))
    box(F, STEEL, (hx - 0.12, hy - e - 0.08, H - 0.08), (hx + 0.12, hy - e + 0.06, H - 0.02))
    cull(F, lambda c, n: (n.y > 0.9 and c.y > K.CAR_BACK - 0.05) or (n.z > 0.9 and c.z > H - 0.01)
         or (abs(n.x) > 0.9 and abs(c.x) > w - 0.05))
    return F


def portal():
    """The landing's steel frame: face plates round the opening (their feet striped), the
    returns lining the wall's thickness, and the grooved sill from the lobby floor to the shaft."""
    F = kit.Find("Portal")
    ow, oh = K.OPENING[0] / 2, K.OPENING[1]
    top = oh + K.HEADER
    for s in (-1, 1):
        box(F, DARK, (s * ow, -K.PLATE, 0), (s * (ow + K.JAMB), 0, top), 0.02)
        box(F, DARK, (s * (ow - 0.04), 0, 0), (s * ow, K.WALL, oh))
        for z in (0.5, 3.4, 6.4, 9.8):
            stud(F, BOLT, (s * (ow + K.JAMB / 2), -K.PLATE, z), "y", -1, 0.05, 0.035, 6)
    box(F, DARK, (-ow, -K.PLATE, oh), (ow, 0, top), 0.02)
    box(F, DARK, (-ow, 0, oh - 0.04), (ow, K.WALL, oh))
    for x in (-4.6, -1.5, 1.5, 4.6):
        stud(F, BOLT, (x, -K.PLATE, oh + K.HEADER / 2), "y", -1, 0.05, 0.035, 6)
    cull(F, lambda c, n: (n.y > 0.9 and c.y < 0.01) or (n.y > 0.9 and c.y > K.WALL - 0.01)
         or (abs(n.x) > 0.9 and abs(c.x) > ow - 0.01 and c.y > -0.01)
         or (n.z > 0.9 and c.z > oh - 0.01 and c.y > -0.01 and abs(c.x) < ow))
    return F


def landing_sill():
    F = kit.Find("LandingSill")
    ow = K.OPENING[0] / 2
    box(F, ALU, (-ow, K.LANDING_SILL[0], -0.1), (ow, K.LANDING_SILL[1], 0.02), 0.012)
    cull(F, lambda c, n: n.z < -0.9)
    return F


def gate_picket():
    F = kit.Find("GatePicket")
    pw, pd = K.PICKET
    z0, z1 = K.GATE_Z
    box(F, GATE, (-pw / 2, -pd / 2, z0), (pw / 2, pd / 2, z1), 0.012)
    box(F, STEEL, (-0.02, -0.02, z1), (0.02, 0.02, z1 + 0.1))
    F.add(STEEL, geo.cylinder, "y", (0, 0, z1 + 0.1), 0.065, 0.05, 8, None, True, True)
    box(F, STEEL, (-0.05, -0.03, z0 - 0.12), (0.05, 0.03, z0))
    return F


def gate_strap():
    """One strap of the lazy tongs, lying level, its middle pin at the origin: a flat bar with
    round ends and a rivet in the middle (its end pins are painted on). 72 make a gate, so it's
    kept to 48 triangles."""
    F = kit.Find("GateStrap")
    L, w, t = K.STRAP, K.STRAP_W, K.STRAP_T

    def bar(m):
        bm = bmesh.new()
        pts = []
        for i in range(4):  # the right end, round from below to above
            a = -math.pi / 2 + math.pi * i / 3
            pts.append((L / 2 + w / 2 * math.cos(a), w / 2 * math.sin(a)))
        for i in range(4):
            a = math.pi / 2 + math.pi * i / 3
            pts.append((-L / 2 + w / 2 * math.cos(a), w / 2 * math.sin(a)))
        front = [bm.verts.new((x, -t / 2, z)) for x, z in pts]
        back = [bm.verts.new((x, t / 2, z)) for x, z in pts]
        n = len(pts)
        bm.faces.new(front)
        bm.faces.new(list(reversed(back)))
        for i in range(n):
            j = (i + 1) % n
            bm.faces.new((front[i], back[i], back[j], front[j]))
        kit.solid(m, bm)
    F.add(GATE, bar)
    stud(F, BOLT, (0.0, -t / 2, 0.0), "y", -1, 0.03, 0.016)
    return F


def gate_lead():
    """The lead picket: heavier, with a rubber edge on the side it closes toward and a pull."""
    F = kit.Find("GateLead")
    lw, ld = K.LEAD
    z0, z1 = K.GATE_Z
    box(F, GATE, (-lw / 2, -ld / 2, z0), (lw / 2, ld / 2, z1), 0.02)
    box(F, RUBBER, (lw / 2, -0.05, z0 + 0.2), (lw / 2 + K.RUBBER, 0.05, z1 - 0.2), 0.008)
    path = [(0.0, -ld / 2, 3.45), (0.0, -0.22, 3.55), (0.0, -0.27, 3.75), (0.0, -0.27, 4.75),
            (0.0, -0.22, 4.95), (0.0, -ld / 2, 5.05)]
    F.add(STEEL, geo.sweep, path, 0.042, 6)
    for x in (-0.08, 0.08):
        box(F, STEEL, (x - 0.02, -0.02, z1), (x + 0.02, 0.02, z1 + 0.1))
        F.add(STEEL, geo.cylinder, "y", (x, 0, z1 + 0.1), 0.065, 0.05, 8, None, True, True)
    box(F, STEEL, (-0.05, -0.03, z0 - 0.12), (0.05, 0.03, z0))
    return F


def lamp():
    """A jelly-jar lamp: a cast base bolted to the ceiling, a collar, a wire guard round the
    glass (the glass is LampGlass, untextured, so the game can make it glow)."""
    F = kit.Find("Lamp")
    lx, ly = K.LAMP
    H = K.CAR_H
    F.add(CAST, geo.cylinder, "z", (lx, ly, H - 0.11), 0.36, 0.22, 16, None, True, True, 0.03)
    F.add(CAST, geo.cylinder, "z", (lx, ly, H - 0.27), 0.23, 0.1, 16, None, True, True, 0.02)
    for i in range(4):
        a = math.pi / 4 + i * math.pi / 2
        c, s = math.cos(a), math.sin(a)
        path = [(lx + r * c, ly + r * s, H - z) for r, z in
                ((0.21, 0.31), (0.33, 0.38), (0.345, 0.5), (0.345, 0.7), (0.29, 0.84), (0.12, 0.9),
                 (0.03, 0.915))]
        F.add(WIRE, geo.sweep, path, 0.018, 6)
    for z in (0.47, 0.73):
        ring = [(lx + 0.347 * math.cos(2 * math.pi * i / 20), ly + 0.347 * math.sin(2 * math.pi * i / 20),
                 H - z) for i in range(20)]
        F.add(WIRE, geo.sweep, ring, 0.016, 6, None, True)
    F.add(WIRE, geo.cylinder, "z", (lx, ly, H - 0.915), 0.06, 0.04, 10, None, True, True, 0.01)
    return F


def lamp_glass():
    m = geo.Mesh("LampGlass")
    lx, ly = K.LAMP
    H = K.CAR_H
    lathe(m, [(0.0, H - 0.31), (0.2, H - 0.31), (0.27, H - 0.36), (0.275, H - 0.5), (0.27, H - 0.66),
              (0.24, H - 0.75), (0.16, H - 0.81), (0.0, H - 0.83)], lx, ly, 18)
    return m


def keypad():
    """The keypad's steel backplate and brushed housing, the readout's black bezel, the status
    light's ring and four security screws. Its keys, glass and light are parts of their own."""
    F = kit.Find("Keypad")
    kx, kz = K.KEYPAD
    bw, bh, bd = K.BACKPLATE
    hw, hh, hd = K.HOUSING
    box(F, BACKPLATE, (kx - bw / 2, -bd, kz - bh / 2), (kx + bw / 2, 0, kz + bh / 2), 0.02)
    front = -bd - hd
    box(F, HOUSING, (kx - hw / 2, front, kz - hh / 2), (kx + hw / 2, -bd, kz + hh / 2), 0.035, 2)
    rx, rz, rw, rh = K.READOUT
    cx, cz, m = kx + rx, kz + rz, 0.05
    box(F, BEZEL, (cx - rw / 2 - m, front - 0.025, cz + rh / 2), (cx + rw / 2 + m, front, cz + rh / 2 + m), 0.006)
    box(F, BEZEL, (cx - rw / 2 - m, front - 0.025, cz - rh / 2 - m), (cx + rw / 2 + m, front, cz - rh / 2), 0.006)
    box(F, BEZEL, (cx - rw / 2 - m, front - 0.025, cz - rh / 2), (cx - rw / 2, front, cz + rh / 2), 0.006)
    box(F, BEZEL, (cx + rw / 2, front - 0.025, cz - rh / 2), (cx + rw / 2 + m, front, cz + rh / 2), 0.006)
    lx, lz = K.LIGHT
    F.add(BEZEL, geo.cylinder, "y", (kx + lx, front - 0.01, kz + lz), 0.065, 0.02, 14, None, True, True, 0.006)
    for sx in (-1, 1):
        for sz in (-1, 1):
            stud(F, BOLT, (kx + sx * (bw / 2 - 0.08), -bd, kz + sz * (bh / 2 - 0.08)), "y", -1, 0.035, 0.016)
    return F


def key(d):
    F = kit.Find(f"Key{d}")
    kx, kz = K.KEYPAD
    x, z = K.key_at(d)
    front = -K.BACKPLATE[2] - K.HOUSING[2]
    s = K.KEY / 2
    box(F, KEY, (kx + x - s, front - 0.04, kz + z - s), (kx + x + s, front + 0.01, kz + z + s), 0.022, 2)
    return F


def readout():
    m = geo.Mesh("KeypadReadout")
    kx, kz = K.KEYPAD
    rx, rz, rw, rh = K.READOUT
    front = -K.BACKPLATE[2] - K.HOUSING[2]
    geo.box(m, (kx + rx - rw / 2, front - 0.008, kz + rz - rh / 2), (kx + rx + rw / 2, front, kz + rz + rh / 2))
    return m


def status_light():
    m = geo.Mesh("KeypadLight")
    kx, kz = K.KEYPAD
    lx, lz = K.LIGHT
    front = -K.BACKPLATE[2] - K.HOUSING[2]
    geo.cylinder(m, "y", (kx + lx, front - 0.03, kz + lz), 0.04, 0.03, 12, None, True, True, 0.012)
    return m


def note():
    """A big pad's sticky note in its own frame: its back's middle at the origin (stuck to
    whatever it's on at y = 0), facing -Y, its foot curling away, tighter at the right corner."""
    F = kit.Find("Note")
    s, t = K.NOTE / 2, K.NOTE_T
    zc, R0, k = K.CURL
    xs = [-s + K.NOTE * i / 6 for i in range(7)]
    zs = [s, 0.2, 0.05, zc] + [zc - (zc + s) * i / 6 for i in range(1, 7)]

    def at(x, z, depth):
        if z >= zc:
            return (x, -depth, z)
        R = R0 * (1.0 - k * (x + s) / K.NOTE)
        phi = (zc - z) / R
        r = R - depth
        return (x, -R + r * math.cos(phi), zc - r * math.sin(phi))

    def sheet(m):
        bm = bmesh.new()
        fr = [[bm.verts.new(at(x, z, t)) for x in xs] for z in zs]
        bk = [[bm.verts.new(at(x, z, 0.0)) for x in xs] for z in zs]
        nz, nx = len(zs), len(xs)
        for j in range(nz - 1):
            for i in range(nx - 1):
                bm.faces.new((fr[j][i], fr[j + 1][i], fr[j + 1][i + 1], fr[j][i + 1]))
                bm.faces.new((bk[j][i], bk[j][i + 1], bk[j + 1][i + 1], bk[j + 1][i]))
        for i in range(nx - 1):
            bm.faces.new((fr[0][i], fr[0][i + 1], bk[0][i + 1], bk[0][i]))
            bm.faces.new((fr[-1][i], bk[-1][i], bk[-1][i + 1], fr[-1][i + 1]))
        for j in range(nz - 1):
            bm.faces.new((fr[j][0], bk[j][0], bk[j + 1][0], fr[j + 1][0]))
            bm.faces.new((fr[j][-1], fr[j + 1][-1], bk[j + 1][-1], bk[j][-1]))
        bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
        verts = [v.co.copy() for v in bm.verts]
        idx = {v: i for i, v in enumerate(bm.verts)}
        base = len(m.verts)
        for v in verts:
            m.vert(v)
        for f in bm.faces:
            m.face([base + idx[v] for v in f.verts], None, True)
        kinds = [GLUE if f.normal.y > 0.5 else PAPER for f in bm.faces]
        bm.free()
        return kinds
    kinds = sheet(F.m)
    F.kinds += kinds
    return F


GEO = {"CarFront": car_front, "CarTrim": car_trim, "Portal": portal, "LandingSill": landing_sill, "GatePicket": gate_picket, "GateStrap": gate_strap,
       "GateLead": gate_lead, "Lamp": lamp, "Keypad": keypad, "Note": note}
GEO.update({f"Key{d}": (lambda d=d: key(d)) for d in range(10)})


def unwrap(objs, pad=6):
    """Each part smart-projected alone, then every island of the set packed together at one
    shared scale, so every part keeps the same texels a stud. The kit's square a part fits long
    strips (boards, jambs, pickets) badly: this packs 42% of the atlas to its 31%."""
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
                            margin=pad / K.TEX, shape_method="AABB")
    bpy.ops.object.mode_set(mode="OBJECT")
    clash = kit.clashes(objs)
    assert not clash, f"faces share texels in the atlas: {clash}"


def build_unique(set_name, baking, coll=None):
    use_set(set_name)
    objs = {n: GEO[n]().build(30, coll) for n in UNIQUE[set_name]}
    kit.settle(list(objs.values()))
    if baking:
        unwrap(list(objs.values()))
        kit.keep_uvs(objs)
    else:
        kit.wear_uvs(objs)
        print(f"atlas {set_name}: faces on unpainted texels {kit.unpainted(objs)}")
    print(f"atlas {set_name}: {kit.density(list(objs.values())):.0f} texels a stud, "
          f"uv {kit.uv_hash(list(objs.values()))}")
    return objs


def build_all(coll=None):
    """Every part, worn with its set's material (the bakes must exist)."""
    objs = {}
    for set_name in ("Elevator", "Fittings"):
        part = build_unique(set_name, False, coll)
        mat = set_material(set_name)
        for ob in part.values():
            ob.data.materials.append(mat)
        objs.update(part)
    car = car_mesh().build(coll, sharp_angle=None)
    car.data.materials.append(set_material("Car"))
    objs["Car"] = car
    for name, fn in (("LampGlass", lamp_glass), ("KeypadReadout", readout), ("KeypadLight", status_light)):
        ob = fn().build(coll, sharp_angle=30)
        ob.data.materials.append(render.simple(f"plain_{name}", PLAIN[name], 0.4))
        objs[name] = ob
    return objs


def box_of(ob):
    vs = [v.co for v in ob.data.vertices]
    return (Vector([min(v[i] for v in vs) for i in range(3)]),
            Vector([max(v[i] for v in vs) for i in range(3)]))


# --- the key labels ---------------------------------------------------------------------------

def text(body, path, cx, cy, maxw, maxh, mat, offset=0.0):
    cu = bpy.data.curves.new("label", "FONT")
    cu.body = body
    cu.font = bpy.data.fonts.load(path, check_existing=True)
    cu.align_x, cu.align_y = "CENTER", "CENTER"
    cu.offset = offset
    ob = bpy.data.objects.new("label", cu)
    bpy.context.scene.collection.objects.link(ob)
    ob.data.materials.append(mat)
    bpy.context.view_layer.update()
    lo = Vector([min(c[i] for c in ob.bound_box) for i in range(3)])
    hi = Vector([max(c[i] for c in ob.bound_box) for i in range(3)])
    s = min(maxw / (hi.x - lo.x), maxh / (hi.y - lo.y))
    ob.scale = (s, s, 1.0)
    ob.location = (cx - s * (lo.x + hi.x) / 2, cy - s * (lo.y + hi.y) / 2, 0.0)
    return ob


def stage_labels():
    """One cell per digit, white on black: 1 x 1 Blender units a cell, 200 texels."""
    reset()
    sc = bpy.context.scene
    cols, rows = K.LABEL_SHEET
    ink = render.emissive("ink", (1.0, 1.0, 1.0), 1.0)
    for d in range(10):
        c, r = d % cols, d // cols
        text(str(d), K.KEY_FONT, c + 0.5, rows - r - 0.5, 0.62, 0.62, ink)
    cam = bpy.data.cameras.new("sheet")
    cam.type = "ORTHO"
    cam.ortho_scale = float(cols)
    ob = bpy.data.objects.new("sheet", cam)
    sc.collection.objects.link(ob)
    ob.location = (cols / 2, rows / 2, 10.0)
    sc.camera = ob
    bake.gpu_cycles(16)
    sc.render.resolution_x, sc.render.resolution_y = 200 * cols, 200 * rows
    sc.render.resolution_percentage = 100
    sc.view_settings.view_transform = "Standard"
    sc.render.image_settings.file_format = "PNG"
    sc.render.image_settings.color_mode = "BW"
    sc.world = bpy.data.worlds.new("black")
    sc.world.use_nodes = True
    sc.world.node_tree.nodes["Background"].inputs["Strength"].default_value = 0.0
    os.makedirs(OUT, exist_ok=True)
    sc.render.filepath = LABELS
    bpy.ops.render.render(write_still=True)
    print("RENDERED", LABELS)


# --- the Car set: painted steel walls and diamond plate, tiling across ------------------------

def car_look(nb):
    """The bottom band a diamond plate, worn bright on its lugs and grimy between them; the rest
    a wall of cream enamel on riveted steel panels, scraped through by dollies below the boards,
    streaked from the rivets and gone brown up near the lamp."""
    C = Coords(nb, "cyl", tile_u=K.TILE, len_v=K.TILE)
    h = C.height()
    us = nb.mul(C.u, K.TILE)
    z = nb.sub(h, K.FLOOR_BAND)
    wall = nb.ss(h, K.FLOOR_BAND - 0.003, K.FLOOR_BAND + 0.003)

    def n(seed, scale, sx=1.0, sz=1.0, **kw):
        return nb.noise(C.v(sx, sz, seed), scale, **kw)

    def near(v, p):  # distance to the nearest multiple of p
        return nb.mul(nb.absf(nb.sub(nb.fract(nb.add(nb.div(v, p), 0.5)), 0.5)), p)

    # --- the floor plate ---
    P = 0.32
    fa, fb = nb.div(us, P), nb.div(h, P)
    a, b = nb.sub(nb.fract(fa), 0.5), nb.sub(nb.fract(fb), 0.5)
    cell = nb.add(nb.math("FLOOR", fa), nb.math("FLOOR", fb))
    par = nb.mul(nb.fract(nb.mul(cell, 0.5)), 2.0)
    pa, qa = nb.mul(nb.absf(nb.add(a, b)), 0.7071), nb.mul(nb.absf(nb.sub(a, b)), 0.7071)
    along, across = nb.mixf(par, pa, qa), nb.mixf(par, qa, pa)
    al = nb.mx(nb.sub(along, 0.24), 0.0)
    d = nb.pw(nb.add(nb.mul(al, al), nb.mul(across, across)), 0.5)
    lug = nb.ss(d, 0.105, 0.065)
    edge = nb.mn(h, nb.sub(K.FLOOR_BAND, h))
    seam = nb.ss(edge, 0.028, 0.012)
    sd = nb.pw(nb.add(nb.pw(near(us, 1.6), 2.0), nb.pw(nb.sub(edge, 0.13), 2.0)), 0.5)
    screw = nb.ss(sd, 0.05, 0.042)
    slot = nb.mul(screw, nb.band(nb.sub(near(us, 1.6), 0.0), -0.008, 0.008, 0.003))
    worn = nb.mr(n(1, 0.9, detail=3), 0.3, 0.7, 0.0, 1.0)
    fcol = nb.tint(hexc("#56585B"), nb.mr(n(2, 3.0, detail=4), 0.3, 0.7, 0.8, 1.1))
    fcol = nb.mixc(nb.mul(lug, nb.add(0.35, nb.mul(worn, 0.65))), fcol, hexc("#9A9C9E"))
    grime = nb.mul(nb.inv(lug), nb.mr(n(3, 2.2, detail=5), 0.25, 0.7, 0.35, 0.95))
    fcol = nb.mixc(grime, fcol, hexc("#2B2722"))
    rust = nb.mul(nb.ss(n(4, 0.7, detail=5, rough=0.65), 0.64, 0.72), nb.inv(nb.mul(lug, 0.6)))
    fcol = nb.mixc(nb.mul(rust, 0.8), fcol, hexc("#6A4027"))
    fcol = nb.mixc(seam, fcol, hexc("#151311"))
    fcol = nb.mixc(screw, fcol, hexc("#6C6E70"))
    fcol = nb.mixc(slot, fcol, hexc("#141210"))
    frough = nb.mixf(nb.mul(lug, worn), 0.55, 0.26)
    frough = nb.mixf(nb.add(grime, rust, clamp=True), frough, 0.88)
    fmetal = nb.inv(nb.mul(nb.add(nb.mul(grime, 0.7), rust, clamp=True), 0.9))
    fheight = nb.add(nb.mul(lug, 1.0), nb.add(nb.mul(seam, -1.2), nb.mul(slot, -0.8)))
    fheight = nb.add(fheight, nb.mul(n(5, 60.0, detail=2), 0.08))

    # --- the wall ---
    sx = near(us, 3.2)                       # to the nearest panel seam
    hz = nb.absf(nb.sub(z, 6.4))             # to the seam above head height
    vseam = nb.ss(sx, 0.02, 0.008)
    hseam = nb.ss(hz, 0.02, 0.008)
    lap = nb.add(nb.band(nb.sub(us, nb.mul(nb.math("FLOOR", nb.div(us, 3.2)), 3.2)), 0.0, 0.07, 0.01),
                 nb.band(hz, 0.0, 0.06, 0.01), clamp=True)

    def rivets(dx, dz):
        r = nb.pw(nb.add(nb.mul(dx, dx), nb.mul(dz, dz)), 0.5)
        return nb.ss(r, 0.042, 0.0)
    riv = rivets(nb.sub(sx, 0.1), near(z, 0.8))
    riv = nb.mx(riv, rivets(near(us, 0.8), nb.sub(hz, 0.1)))
    paint = nb.mixc(nb.mr(n(10, 0.35, detail=2), 0.3, 0.7, 0.0, 1.0), hexc("#BDB59E"), hexc("#ADA084"))
    paint = nb.tint(paint, nb.mr(n(11, 2.0, detail=5), 0.25, 0.75, 0.9, 1.05))
    col, rough, metal = paint, nb.mr(n(12, 4.0, detail=3), 0.3, 0.7, 0.38, 0.52), nb.val(0.0)
    height = nb.add(nb.mul(n(13, 180.0, detail=1), 0.05), nb.add(nb.mul(lap, 0.25), nb.mul(riv, 0.9)))
    col = nb.tint(col, nb.mr(riv, 0.0, 1.0, 1.0, 0.92))
    col = nb.mixc(nb.add(vseam, hseam, clamp=True), col, hexc("#3D382F"))
    height = nb.add(height, nb.mul(nb.add(vseam, hseam, clamp=True), -1.0))
    # rust and grime streaked down from each rivet and seam
    streak = nb.mul(nb.ss(n(14, 3.0, sx=4.0, sz=0.06, detail=4), 0.6, 0.75),
                    nb.ss(nb.add(sx, 0.0), 0.35, 0.05))
    col = nb.mixc(nb.mul(streak, 0.45), col, hexc("#7C6244"))
    # dollies: scraped through the paint below and between the boards, rubber marks, a primer rim
    low = nb.add(nb.band(z, 0.12, 0.8, 0.1), nb.band(z, 1.45, 2.25, 0.1), clamp=True)
    low = nb.add(low, nb.mul(nb.band(z, 3.0, 4.2, 0.2), 0.35), clamp=True)
    scr = nb.add(n(15, 3.5, sx=0.12, sz=2.6, detail=5, rough=0.6), nb.mul(n(16, 0.6), 0.15))
    scrape = nb.mul(nb.ss(scr, 0.66, 0.69), low)
    rim = nb.mul(nb.sub(nb.ss(scr, 0.63, 0.655), nb.ss(scr, 0.66, 0.69), clamp=True), low)
    col = nb.mixc(rim, col, hexc("#857F70"))
    steel = nb.tint(hexc("#77797B"), nb.mr(n(17, 40.0, sx=0.2, sz=4.0), 0.3, 0.7, 0.8, 1.15))
    col = nb.mixc(scrape, col, steel)
    rough = nb.mixf(scrape, rough, 0.35)
    metal = nb.mixf(scrape, metal, 1.0)
    height = nb.add(height, nb.mul(scrape, -0.35))
    rub = nb.mul(nb.ss(n(18, 5.0, sx=0.08, sz=3.0, detail=3), 0.7, 0.76), nb.mul(low, 0.8))
    col = nb.mixc(rub, col, hexc("#1F1D1B"))
    rough = nb.mixf(rub, rough, 0.7)
    metal = nb.mixf(rub, metal, 0.0)
    # dents: soft hollows where something heavy hit
    dent = nb.mul(nb.ss(n(19, 1.4, detail=2), 0.66, 0.78), nb.ss(z, 4.5, 2.0))
    height = nb.add(height, nb.mul(dent, -0.6))
    # hands: greasy smudges at a reach, grime at the foot, brown near the ceiling
    hand = nb.mul(nb.ss(n(20, 2.5, detail=5), 0.6, 0.72), nb.band(z, 3.2, 5.6, 0.5))
    col = nb.mixc(nb.mul(hand, 0.3), col, hexc("#6E6656"))
    rough = nb.mixf(nb.mul(hand, 0.6), rough, 0.3)
    foot = nb.mul(nb.ss(z, 0.5, 0.0), nb.mr(n(21, 3.0, detail=4), 0.3, 0.7, 0.5, 1.0))
    col = nb.mixc(nb.mul(foot, 0.8), col, hexc("#3B352C"))
    soot = nb.mul(nb.ss(z, 6.9, 9.6), nb.mr(n(22, 0.8, detail=4), 0.3, 0.7, 0.25, 0.55))
    col = nb.mixc(soot, col, hexc("#6A5B44"))

    col = nb.mixc(wall, fcol, col)
    rough = nb.mixf(wall, frough, rough)
    metal = nb.mixf(wall, fmetal, metal)
    height = nb.mixf(wall, fheight, height)
    return Channels(col, 1.0, rough, metal, height, bump_dist=0.012, bump_strength=0.7)


# --- the Elevator set: trim, the landing's frame, the gate's parts, the lamp -------------------

def trim_look(nb, name):
    L = kit.Look(nb, K.SEED + ALL.index(name))
    x, y, z = L.x, L.y, L.z
    C = kit.Coat(L, hexc("#34383A"), nb.mr(L.noise(4.0, 1, detail=3), 0.3, 0.7, 0.42, 0.58), 0.0,
                 nb.mul(L.noise(220.0, 2, detail=1), 0.04))
    steel = nb.tint(hexc("#717375"), nb.mr(L.noise(30.0, 3, detail=3), 0.3, 0.7, 0.8, 1.15))
    rust = hexc("#5E3B22")

    C.paint(L.k(STEEL), steel, nb.mr(L.noise(6.0, 4, detail=3), 0.3, 0.7, 0.3, 0.5), 1.0)
    C.paint(L.k(BOLT), hexc("#4E5052"), 0.5, 0.9)
    C.paint(L.k(CREAM), hexc("#B3AA92"), 0.5, 0.0)
    C.paint(L.k(GATE), hexc("#1D1F20"), 0.55, 0.0)
    C.paint(L.k(CAST), hexc("#6B6E70"), 0.62, 0.0)
    C.paint(L.k(WIRE), hexc("#808386"), 0.45, 0.8)
    C.rubber(L.k(RUBBER))

    # the landing's sill: aluminium, grooved along its length, grime in the grooves
    alu = L.k(ALU)
    groove = nb.mul(nb.band(nb.fract(nb.div(y, 0.07)), 0.0, 0.42, 0.04), nb.mul(L.up, alu))
    C.paint(alu, nb.tint(hexc("#9C9FA2"), nb.mr(L.noise(8.0, 5, detail=4), 0.3, 0.7, 0.85, 1.1)), 0.42, 1.0)
    C.paint(groove, hexc("#36332E"), 0.85, 0.2, -1.0)

    # oak bumper boards, grain along each board, gouged by dollies, the edges worn pale
    wood = L.k(WOOD)
    side = nb.ss(nb.absf(x), 5.85, 5.95)
    grain = nb.mixf(side, L.noise(5.0, 6, stretch=(0.04, 1.0, 1.0), detail=5),
                    L.noise(5.0, 6, stretch=(1.0, 0.04, 1.0), detail=5))
    ring = nb.ss(nb.fract(nb.mul(grain, 9.0)), 0.15, 0.85)
    oak = nb.mixc(ring, hexc("#7A5634"), hexc("#5A3B21"))
    oak = nb.tint(oak, nb.mr(L.noise(1.5, 7, detail=3), 0.3, 0.7, 0.8, 1.1))
    C.paint(wood, oak, 0.72, 0.0, nb.mul(ring, 0.25))
    gouge = nb.mul(nb.ss(L.noise(7.0, 8, stretch=(0.3, 0.3, 1.0), detail=4), 0.69, 0.73), wood)
    C.paint(gouge, hexc("#2F2216"), 0.85, None, -0.9)
    pale = nb.mul(nb.mul(nb.edge(0.02, k=4.0), wood), nb.mr(L.noise(9.0, 9), 0.3, 0.7, 0.2, 0.9))
    C.paint(pale, hexc("#A07B54"), 0.6)

    # stripes where you cross: the car's sill, the landing's jambs to a dolly's height
    haz = L.k(HAZARD)
    if name == "Portal":
        haz = nb.mul(nb.mul(L.k(DARK), nb.ss(z, K.HAZARD + 0.01, K.HAZARD - 0.01)),
                     nb.ss(nb.absf(x), K.OPENING[0] / 2 + 0.02, K.OPENING[0] / 2 + 0.05))
    stripe = nb.band(nb.fract(nb.div(nb.add(nb.add(x, y), z), 0.5)), 0.0, 0.5, 0.01)
    C.paint(haz, nb.mixc(stripe, hexc("#1B1B1A"), hexc("#D19A1C")), 0.5, 0.0)
    if name == "CarFront":  # trodden: the paint gone in the middle where everyone steps over
        tread = nb.mul(nb.mul(haz, L.up), nb.mul(nb.ss(nb.absf(x), 4.6, 1.0),
                                               nb.ss(L.noise(6.0, 10, detail=5), 0.45, 0.6)))
        C.paint(tread, steel, 0.35, 1.0, -0.3)

    # the pickets' channel: a slot down the front the straps' pins ride in
    if name in ("GatePicket", "GateLead"):
        slot = nb.mul(nb.mul(nb.band(x, -0.022, 0.022, 0.004), L.front), L.k(GATE))
        C.paint(slot, hexc("#0A0A0A"), 0.8, 0.0, -1.0)
    if name == "GateStrap":  # its end pins, painted on: a dome where it rides in each picket
        for px in (-K.STRAP / 2, K.STRAP / 2):
            pin = nb.mul(nb.ss(L.dist(nb.sub(x, px), z), 0.03, 0.0), L.front)
            C.paint(nb.ss(pin, 0.0, 0.2), hexc("#4E5052"), 0.5, 0.9, nb.mul(pin, 1.2))
    if name == "GateLead":  # the pull, polished by every hand that hauled it
        C.paint(L.k(STEEL), nb.tint(steel, 1.25), 0.24, 1.0)

    # chips and scrapes through the paint to steel, rust in the oldest
    painted = nb.add(nb.add(L.k(DARK), L.k(GATE), clamp=True),
                     nb.add(nb.add(L.k(CREAM), L.k(CAST), clamp=True), haz, clamp=True), clamp=True)
    field = nb.add(L.noise(8.0, 11, detail=5, rough=0.62), nb.mul(nb.clamp(nb.edge(0.025, k=3.0)), 0.3))
    chip = nb.mul(nb.ss(field, 0.7, 0.715), painted)
    C.paint(chip, steel, 0.38, 1.0, -0.3)
    old = nb.mul(chip, nb.ss(L.noise(14.0, 12, detail=3), 0.55, 0.7))
    C.paint(old, rust, 0.88, 0.0)
    scratch = nb.mul(nb.ss(L.noise(30.0, 13, stretch=(1.0, 1.0, 0.08), detail=3), 0.7, 0.73), painted)
    C.paint(nb.mul(scratch, 0.6), steel, 0.4, 0.8)
    if name not in ("GateStrap",):  # grime up from the floor (the strap is posed in the game)
        foot = nb.mul(nb.ss(z, 1.0, -0.1), nb.mr(L.noise(3.0, 14, detail=4), 0.3, 0.7, 0.2, 0.8))
        C.paint(foot, nb.tint(C.col, 0.55), 0.8)
    C.paint(nb.mul(nb.ss(L.noise(2.0, 15, detail=5), 0.62, 0.75), 0.5), nb.tint(C.col, 0.75))
    C.finish(ao=0.15, ao_low=0.5, dust=K.DUST)
    return C.channels(dist=0.003, strength=0.6)


# --- the Fittings set's keypad: brushed steel, engraved keys; and the sticky note ----------------------------

def pad_look(nb, name, sheet):
    L = kit.Look(nb, K.SEED + 40 + ALL.index(name))
    x, y, z = L.x, L.y, L.z
    kx, kz = K.KEYPAD
    if name == "Note":
        return note_look(nb, L)
    brush = L.noise(260.0, 1, stretch=(0.025, 1.0, 1.0), detail=2)
    C = kit.Coat(L, nb.tint(hexc("#A5A8AB"), nb.mr(brush, 0.3, 0.7, 0.9, 1.07)),
                 nb.mr(brush, 0.3, 0.7, 0.24, 0.4), 1.0, nb.mul(brush, 0.05))
    C.paint(L.k(BACKPLATE), nb.tint(hexc("#5A5E60"), nb.mr(L.noise(3.0, 2, detail=4), 0.3, 0.7, 0.85, 1.1)),
            0.55, 0.0, 0.0)
    C.paint(L.k(BEZEL), hexc("#111213"), 0.5, 0.0)
    C.paint(L.k(BOLT), hexc("#8B8D90"), 0.35, 1.0)
    front = L.front
    if name == "Keypad":
        # the speaker: a disc of small holes right of 0
        gx, gz = kx - K.LIGHT[0], kz + K.LIGHT[1]
        p = 0.034

        def near(v, c):
            return nb.mul(nb.absf(nb.sub(nb.fract(nb.add(nb.div(nb.sub(v, c), p), 0.5)), 0.5)), p)
        hd = nb.pw(nb.add(nb.pw(near(x, gx), 2.0), nb.pw(near(z, gz), 2.0)), 0.5)
        disc = nb.ss(L.dist(nb.sub(x, gx), nb.sub(z, gz)), 0.095, 0.085)
        hole = nb.mul(nb.mul(nb.ss(hd, 0.012, 0.009), disc), nb.mul(front, L.k(HOUSING)))
        C.paint(hole, hexc("#050505"), 0.9, 0.0, -1.0)
        # fingers: a grey film round the keys and on the plate's edge where it's pushed
        keys = nb.mul(L.rect(kx - 0.45, kx + 0.45, kz - 0.8, kz + 0.33, soft=0.08), front)
        C.paint(nb.mul(keys, nb.mr(L.noise(9.0, 3, detail=4), 0.35, 0.75, 0.15, 0.55)),
                hexc("#6F6C66"), 0.45, 0.6)
    if name.startswith("Key") and name[3:].isdigit():
        d = int(name[3:])
        cx, cz = K.key_at(d)
        cx, cz = kx + cx, kz + cz
        S = 0.177
        uu = nb.add(nb.div(nb.sub(x, cx), S), 0.5)
        vv = nb.add(nb.div(nb.sub(z, cz), S), 0.5)
        within = nb.mul(nb.band(uu, 0.0, 1.0, 0.001), nb.band(vv, 0.0, 1.0, 0.001))
        cols, rows = K.LABEL_SHEET
        c, r = d % cols, d // cols
        img = nb.node("ShaderNodeTexImage", image=sheet, extension="CLIP", interpolation="Linear")
        nb.put(img.inputs["Vector"], nb.comb(nb.div(nb.add(nb.clamp(uu), c), cols),
                                             nb.div(nb.add(nb.clamp(vv), rows - 1 - r), rows), 0.0))
        legend = nb.mul(nb.mul(nb.ss(nb.gray(img.outputs["Color"]), 0.3, 0.62), within), front)
        # pressed a thousand times: polished in the middle, the fill worn thin in places
        mid = nb.ss(L.dist(nb.sub(x, cx), nb.sub(z, cz)), 0.1, 0.02)
        C.paint(nb.mul(mid, front), nb.tint(hexc("#B8BBBE"), 1.06), 0.16, 1.0)
        fill = nb.mul(legend, nb.mr(L.noise(40.0, 4, detail=3), 0.3, 0.7, 0.75, 1.0))
        C.paint(fill, hexc("#141414"), 0.6, 0.0, -0.8)
    C.finish(ao=0.12, ao_low=0.55, dust=0.15)
    return C.channels(dist=0.002, strength=0.5)


def note_look(nb, L):
    """Canary paper, a little tired: fibres, the edges handled grey, the glue strip on its back,
    a thumb's smudge low on the right where it was pressed on."""
    x, z = L.x, L.z
    fib = L.noise(160.0, 1, detail=4)
    col = nb.mixc(nb.mr(L.noise(1.6, 2, detail=3), 0.3, 0.7, 0.0, 1.0), hexc(K.PAPER), hexc("#E9CC4E"))
    col = nb.tint(col, nb.mr(fib, 0.3, 0.7, 0.95, 1.04))
    C = kit.Coat(L, col, 0.85, 0.0, nb.mul(fib, 0.12))
    edge = nb.mul(nb.clamp(nb.edge(0.01, k=4.0)), nb.mr(L.noise(20.0, 3, detail=3), 0.3, 0.7, 0.2, 0.8))
    C.paint(nb.mul(edge, 0.5), hexc("#B9A24A"))
    s = K.NOTE / 2
    glue = nb.mul(L.k(GLUE), nb.ss(z, s - K.GLUE - 0.01, s - K.GLUE + 0.01))
    C.paint(glue, nb.tint(C.col, 0.93), 0.62)
    thumb = nb.mul(nb.ss(L.dist(nb.sub(x, 0.2), nb.sub(z, -0.18)), 0.09, 0.03),
                   nb.mr(L.noise(70.0, 4, detail=3), 0.3, 0.7, 0.2, 0.55))
    C.paint(nb.mul(thumb, L.k(PAPER)), hexc("#8E8466"))
    C.finish(ao=0.05, ao_low=0.85, dust=0.0)
    return C.channels(dist=0.002, strength=0.4)


def bevelled(r, radius):
    """Round a rig's edges in its normals (the Bevel node), so hard edges catch the light."""
    bump = r.bsdf.inputs["Normal"].links[0].from_node
    bev = r.nb.node("ShaderNodeBevel", samples=8)
    r.nb.put(bev.inputs[0], radius)
    r.nb.links.new(bev.outputs[0], bump.inputs["Normal"])
    return r


def stage_textures():
    reset()
    bake.SIZES["Car"] = (K.TEX, K.TEX)
    p = bake.plane("bake_Car", K.TILE, K.TILE)
    bake.bake_set("Car", [(p, bake.Rig("bk_car", car_look))], TEX, samples=16)
    bpy.data.objects.remove(p)

    objs = build_unique("Elevator", True)
    for i, ob in enumerate(objs.values()):
        ob.location.x = i * 16.0
    kit.bake_set([(ob, bevelled(bake.Rig(f"bk_{n}", lambda nb, n=n: trim_look(nb, n)), 0.012))
                  for n, ob in objs.items()], samples=32)

    sheet = bake.load(LABELS, True)
    objs = build_unique("Fittings", True)
    for i, ob in enumerate(objs.values()):
        ob.location.x = 200.0 + i * 4.0

    def rig(n):
        if n in PAD:
            return bevelled(bake.Rig(f"bk_{n}", lambda nb: pad_look(nb, n, sheet)),
                            0.004 if n == "Note" else 0.01)
        return bevelled(bake.Rig(f"bk_{n}", lambda nb: trim_look(nb, n)), 0.01)
    kit.bake_set([(ob, rig(n)) for n, ob in objs.items()], samples=32)


# --- export ---------------------------------------------------------------------------------

def set_material(name):
    if name in bpy.data.materials:
        return bpy.data.materials[name]
    mat = bpy.data.materials.new(name)
    nb = NB(mat)
    p = lambda k: os.path.join(TEX, f"{name}_{k}.png")  # noqa: E731
    col = nb.node("ShaderNodeTexImage", image=bake.load(p("Color"), False))
    rough = nb.node("ShaderNodeTexImage", image=bake.load(p("Roughness"), True))
    metal = nb.node("ShaderNodeTexImage", image=bake.load(p("Metalness"), True))
    nrm = nb.node("ShaderNodeTexImage", image=bake.load(p("Normal"), True))
    nm = nb.node("ShaderNodeNormalMap")
    nb.put(nm.inputs["Color"], nrm.outputs["Color"])
    bsdf = nb.node("ShaderNodeBsdfPrincipled")
    out = nb.node("ShaderNodeOutputMaterial")
    nb.put(bsdf.inputs["Base Color"], col.outputs["Color"])
    nb.put(bsdf.inputs["Roughness"], rough.outputs["Color"])
    nb.put(bsdf.inputs["Metallic"], metal.outputs["Color"])
    nb.put(bsdf.inputs["Normal"], nm.outputs["Normal"])
    nb.links.new(bsdf.outputs[0], out.inputs["Surface"])
    return mat


def stage_export():
    reset()
    objs = build_all()
    rows = {}
    for name, ob in objs.items():
        lo, hi = box_of(ob)
        s = hi - lo
        rows[name] = dict(size=(s.x, s.z, s.y), centre=tuple((lo + hi) / 2), tris=kit.tris(ob))
    os.makedirs(OUT, exist_ok=True)
    bpy.ops.object.select_all(action="DESELECT")
    for ob in objs.values():
        ob.select_set(True)
    bpy.context.view_layer.objects.active = objs["Car"]
    bpy.ops.export_scene.fbx(
        filepath=FBX, use_selection=True, object_types={"MESH"},
        apply_scale_options="FBX_SCALE_UNITS", axis_forward="Z", axis_up="Y",
        use_mesh_modifiers=True, mesh_smooth_type="OFF", use_tspace=False,
        add_leaf_bones=False, bake_anim=False, path_mode="COPY", embed_textures=True)
    gate = rows["GatePicket"]["tris"] * (K.PICKETS - 1) + rows["GateLead"]["tris"] + \
        rows["GateStrap"]["tris"] * (K.PICKETS - 1) * len(K.ROWS) * 2
    fixed = sum(r["tris"] for n, r in rows.items() if not n.startswith("Gate") and n != "Note")
    print("FBX", FBX, f"{fixed + gate} triangles in place (the gate {gate}), the note "
          f"{rows['Note']['tris']}", {n: r["tris"] for n, r in rows.items()})
    os.makedirs(os.path.join(K.ROOT, "src", "shared", "Elevator"), exist_ok=True)
    K.write_luau(os.path.join(K.ROOT, "src", "shared", "Elevator", "Specs.luau"), rows)


# --- look sheets ----------------------------------------------------------------------------

def mannequin_kit():
    """The Mannequin's own build module (its spec, its finds kit), for standing it in a shot."""
    mine = sys.modules.pop("spec")
    sys.path.insert(0, MANNEQUIN)
    try:
        s = importlib.util.spec_from_file_location("mannequin_build", os.path.join(MANNEQUIN, "build.py"))
        mod = importlib.util.module_from_spec(s)
        s.loader.exec_module(mod)
    finally:
        sys.modules["mannequin_spec"] = sys.modules.pop("spec", None)
        sys.modules["spec"] = mine
    return mod


def copy(ob, matrix):
    o = ob.copy()
    bpy.context.scene.collection.objects.link(o)
    o.matrix_world = matrix
    o.hide_render = False
    return o


def gate(objs, shut):
    """The gate posed at `shut` from the picket, lead and strap templates: what Gate.luau does."""
    xs, th = K.gate_pose(shut)
    out = []
    for i, x in enumerate(xs):
        src = objs["GateLead"] if i == K.PICKETS - 1 else objs["GatePicket"]
        out.append(copy(src, Matrix.Translation((x, K.GATE_Y, 0.0))))
    for i in range(K.PICKETS - 1):
        cx = (xs[i] + xs[i + 1]) / 2
        for z in K.ROWS:
            for layer, sign in ((0, -1.0), (1, 1.0)):
                out.append(copy(objs["GateStrap"], Matrix.Translation((cx, K.LAYERS[layer], z))
                                @ Matrix.Rotation(sign * th, 4, "Y")))
    return out


def lobby(coll):
    """The lobby in front of the landing, as FloorBuilder lays it: 24 square, 14 high, its back
    wall round the opening, the hall's mouth 8 wide at the far end."""
    conc = bake.textured("Concrete", UNIT_TEX)
    wallm = render.simple("lobby_wall", hexc("#8F8E89"), 0.85)
    ceil = render.simple("lobby_ceiling", hexc("#26262A"), 0.7, 0.4)
    ow, oh = K.OPENING[0] / 2, K.OPENING[1]
    render.box_obj("lobby_floor", (-12, -24, -1), (12, 0.5, 0), conc, coll)
    render.box_obj("lobby_ceiling", (-12, -24, 14), (12, 0.5, 15), ceil, coll)
    for lo, hi in (((-12.5, -24, 0), (-12, 0.5, 14)), ((12, -24, 0), (12.5, 0.5, 14)),
                   ((-12, 0, 0), (-ow, K.WALL, 14)), ((ow, 0, 0), (12, K.WALL, 14)),
                   ((-ow, 0, oh), (ow, K.WALL, 14)),
                   ((-12, -24.5, 0), (-4, -24, 14)), ((4, -24.5, 0), (12, -24, 14))):
        render.box_obj("lobby_wall", lo, hi, wallm, coll)


def lights():
    lx, ly = K.LAMP
    ld = bpy.data.lights.new("car_lamp", "POINT")
    ld.energy = 260.0
    ld.color = (1.0, 0.8, 0.58)
    ld.shadow_soft_size = 0.25
    ob = bpy.data.objects.new("car_lamp", ld)
    bpy.context.scene.collection.objects.link(ob)
    ob.location = (lx, ly, K.CAR_H - 0.56)
    return ob


def glow(objs):
    """The lamp's glass, the readout and the status light lit as the game lights them."""
    for name, col, k in (("LampGlass", (1.0, 0.78, 0.52), 9.0), ("KeypadReadout", (0.8, 0.06, 0.03), 0.06),
                         ("KeypadLight", (1.0, 0.06, 0.02), 6.0)):
        ob = objs[name]
        ob.data.materials.clear()
        ob.data.materials.append(render.emissive(f"glow_{name}", col, k))
        ob.visible_shadow = False
    objs["Lamp"].visible_shadow = False  # the guard's wires cast no shadows in the game either


def stage_renders():
    reset()
    render.setup(96, (1560, 720))
    coll = bpy.context.scene.collection
    objs = build_all(coll)
    glow(objs)
    for n in ("GatePicket", "GateLead", "GateStrap", "Note"):
        objs[n].hide_render = True
    lobby(coll)
    lights()
    render.world((0.004, 0.0045, 0.006), 1.0)
    os.makedirs(SHEETS, exist_ok=True)

    mk = mannequin_kit()
    figs = mk.build_all(baking=False)
    mmat = mk.kit.material()
    for ob in figs.values():
        ob.data.materials.append(mmat)
        ob.hide_render = True
    P = mk.poses()

    # 1. from the hall's mouth, across the dark lobby: the lit car, its gate folded open
    g = gate(objs, 0.0)
    cam = render.camera((2.6, -23.0, 4.7), (0.0, 3.0, 4.2), lens=15)
    render.shoot(cam, os.path.join(SHEETS, "elevator-lobby.png"), exposure=0.7)

    # 2. the last one in: the gate halfway shut, from a stride away
    for o in g:
        bpy.data.objects.remove(o)
    g = gate(objs, 0.55)
    cam = render.camera((3.6, -6.0, 4.4), (-0.8, 2.5, 3.9), lens=20)
    render.flashlight(cam, True, (3.5, 0.0, 2.2))
    render.shoot(cam, os.path.join(SHEETS, "elevator-shut.png"), exposure=0.2)
    render.flashlight(cam, False, (0.0, 0.0, 0.0))

    # 3. aboard, the gate nearly shut, the Mannequin come to the gate: it can't ride
    for o in g:
        bpy.data.objects.remove(o)
    g = gate(objs, 0.82)
    before = set(bpy.context.scene.objects)
    mk.figure(figs, P.get("StepRight"), (-1.6, -3.6, 0.0), 172)
    for o in bpy.context.scene.objects:
        if o not in before:
            o.hide_render = False
    cam = render.camera((2.2, 10.2, 4.7), (-0.6, -6.0, 3.7), lens=17)
    render.shoot(cam, os.path.join(SHEETS, "elevator-aboard.png"), exposure=0.35)
    for o in bpy.context.scene.objects:
        if o not in before and o.type == "MESH":
            o.hide_render = True

    # 4. the keypad up close, in a torch, beside the shut gate
    for o in g:
        bpy.data.objects.remove(o)
    g = gate(objs, 1.0)
    kx, kz = K.KEYPAD
    cam = render.camera((kx - 1.7, -3.3, kz + 0.45), (kx - 0.15, 0.0, kz - 0.05), lens=32)
    render.flashlight(cam, True, (kx, 0.0, kz))
    render.shoot(cam, os.path.join(SHEETS, "elevator-keypad.png"), exposure=0.0)

    # 5. a note on a box in a unit, found by torchlight
    for ob in list(bpy.context.scene.objects):
        if ob.type in ("MESH", "LIGHT", "FONT", "CURVE"):
            ob.hide_render = True
    bk = kit.boxes_kit()
    bmat = bk.material(False)
    boxes, _, _ = bk.build_all(baking=False)
    for ob in boxes.values():
        ob.data.materials.append(bmat)
    room = bpy.data.collections.new("room")
    coll.children.link(room)
    bk.unit_room(room)
    bk.place(boxes, "Large", 0.6, 9.0, 0.0, 0)
    bk.place(boxes, "Medium", 0.55, 8.95, bk.K.BOXES["Large"]["h"], -6)
    bk.place(boxes, "Wardrobe", -3.8, 10.2, 0.0, 8)
    for name in ("Small", "Open"):
        boxes[name].hide_render = True
    big = boxes["Large"]
    bpy.context.view_layer.update()
    corners = [big.matrix_world @ Vector(c) for c in big.bound_box]
    ny, top = min(c.y for c in corners) - 0.002, max(c.z for c in corners)
    nz = top * 0.6
    at = Matrix.Translation((0.35, ny, nz)) @ Matrix.Rotation(math.radians(-4), 4, "Y")
    copy(objs["Note"], at)
    ink = render.simple("ink", hexc(K.INK), 0.55)
    wx, wz, ww, wh = K.WRITE
    t = text("_ 7 _ _", K.HAND_FONT, 0.0, 0.0, ww * 0.92, wh * 0.72, ink, offset=0.012)
    t.matrix_world = at @ Matrix.Translation((wx, -K.NOTE_T - 0.0015, wz)) @ \
        Matrix.Rotation(math.radians(90), 4, "X") @ Matrix.LocRotScale(t.location, None, t.scale)
    cam = render.camera((-0.5, ny - 2.4, nz + 0.9), (0.3, ny, nz - 0.05), lens=32)
    render.flashlight(cam, True, (0.35, ny, nz))
    bulb = bk.light("bulb", "POINT", (0.0, 6.0, 8.7), (0.0, 6.0, 0.0), 30.0, (1.0, 0.674, 0.408), 0.08)
    bulb.hide_render = False
    render.shoot(cam, os.path.join(SHEETS, "elevator-note.png"), exposure=0.1)


STAGES = {"labels": stage_labels, "textures": stage_textures, "export": stage_export,
          "renders": stage_renders}

if __name__ == "__main__":
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    ap = argparse.ArgumentParser()
    ap.add_argument("--stage", choices=list(STAGES), required=True)
    STAGES[ap.parse_args(argv).stage]()
    print("DONE")
