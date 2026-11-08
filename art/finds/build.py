"""Build the bedroom set's finds in Blender, headless (art/finds/README.md).

    blender -b --factory-startup -P art/finds/build.py -- --stage textures|export|renders

Stages:
    textures  the Bedroom texture set, baked from each find's recipe into out/textures
    export    out/Bedroom.fbx (every find, one MeshPart each) and src/shared/Finds/Specs.luau
    renders   the look sheets, art/sheets/finds-*.png

Every find in the set shares one 1024² atlas: their faces are smart-projected together, so each
gets the same texels a stud. The skates bake as one skate and ship as a pair wearing the same
texels, so the pair costs the atlas one skate. Each stage rebuilds the meshes from this script;
the unwrap is deterministic, and every stage prints its hash so a mismatch shows.
"""

import argparse
import hashlib
import importlib.util
import math
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
UNIT = os.path.join(HERE, "..", "unit")
BOXES = os.path.abspath(os.path.join(HERE, "..", "boxes"))
sys.path.insert(0, UNIT)
sys.path.insert(0, HERE)  # first: this folder's spec.py, not the unit's

import bmesh  # noqa: E402
import bpy  # noqa: E402
import numpy as np  # noqa: E402
from mathutils import Matrix, Vector  # noqa: E402

import bake  # noqa: E402
import geo  # noqa: E402
import render  # noqa: E402
import spec as K  # noqa: E402
from materials import Channels  # noqa: E402
from nodes import NB, hexc  # noqa: E402

OUT = os.path.join(HERE, "out")
TEX = os.path.join(OUT, "textures")
SHEETS = os.path.join(K.ROOT, "art", "sheets")
FBX = os.path.join(OUT, f"{K.SET}.fbx")
UVS = os.path.join(OUT, "uvs.npz")  # the bake's unwrap, which every later stage wears

# What a face is, for the recipes (a face attribute).
(BODY, PANEL, GRILLE, CHROME, DECK, GLASS, DIAL, KEYS, RUBBER, KNOB,
 WOOD, BEZEL, SCREEN, BACK, SWITCH,
 FUR, MUZZLE, PAD, NOSE, EYE, BUTTON, RIBBON,
 BOOT, SOLE, PLATE, WHEEL, STOP) = range(27)


def reset():
    bpy.ops.wm.read_factory_settings(use_empty=True)


# --- geometry --------------------------------------------------------------------------------

class Find:
    """One find's mesh, every face tagged with what it is."""

    def __init__(self, name):
        self.name = name
        self.m = geo.Mesh(name)
        self.kinds = []

    def add(self, kind, fn, *a, **kw):
        n = len(self.m.faces)
        fn(self.m, *a, **kw)
        self.kinds += [kind] * (len(self.m.faces) - n)

    def build(self, sharp, coll=None):
        ob = self.m.build(coll, sharp_angle=None)
        me = ob.data
        assert len(me.polygons) == len(self.kinds), f"{self.name}: a face was dropped"
        for p in me.polygons:
            p.use_smooth = True
        me.set_sharp_from_angle(angle=math.radians(sharp))
        attr = me.attributes.new("kind", "FLOAT", "FACE")
        attr.data.foreach_set("value", [float(k) for k in self.kinds])
        return ob


def ellipsoid(m, c, r, turn=(0.0, 0.0), us=12, vs=8):
    """A UV sphere built point by point, scaled to radii r, turned (about X, then Y) and moved to
    c. Not bmesh's create_uvsphere: it numbers its points differently from run to run, and the
    bake's saved UVs need every stage's meshes numbered alike."""
    M = (Matrix.Translation(Vector(c)) @ Matrix.Rotation(math.radians(turn[1]), 4, "Y")
         @ Matrix.Rotation(math.radians(turn[0]), 4, "X") @ Matrix.Diagonal((*r, 1.0)))
    top = m.vert(M @ Vector((0.0, 0.0, 1.0)))
    for j in range(1, vs):
        th = math.pi * j / vs
        for i in range(us):
            ph = 2 * math.pi * i / us
            m.vert(M @ Vector((math.sin(th) * math.cos(ph), math.sin(th) * math.sin(ph), math.cos(th))))
    bot = m.vert(M @ Vector((0.0, 0.0, -1.0)))

    def ring(j, i):
        return top + 1 + (j - 1) * us + i % us
    for i in range(us):
        m.face((top, ring(1, i), ring(1, i + 1)), None, True)
        for j in range(1, vs - 1):
            m.face((ring(j, i), ring(j + 1, i), ring(j + 1, i + 1), ring(j, i + 1)), None, True)
        m.face((bot, ring(vs - 1, i + 1), ring(vs - 1, i)), None, True)


def solid(m, bm):
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    geo.from_bmesh(m, bm, None, smooth=True)


def frustum(m, y0, y1, w0, h0, w1, h1, cz):
    """A box tapering from w0 x h0 at y0 to w1 x h1 at y1 (the tube's housing behind a TV)."""
    bm = bmesh.new()
    bmesh.ops.create_cube(bm, size=1.0)
    for v in bm.verts:
        back = v.co.y > 0
        w, h = (w1, h1) if back else (w0, h0)
        v.co = Vector((v.co.x * w, y1 if back else y0, cz + v.co.z * h))
    solid(m, bm)


def facing_front(m, c, rings):
    """A cap facing -Y from a list of rings (each a list of (x, y, z) points, the rim first) to a
    centre point `c`."""
    base = len(m.verts)
    for ring in rings:
        for p in ring:
            m.vert(p)
    centre = m.vert(c)
    n = len(rings[0])
    for k in range(len(rings) - 1):
        for i in range(n):
            a, b = base + k * n + i, base + k * n + (i + 1) % n
            m.face((a, b, b + n, a + n), None, True)
    last = base + (len(rings) - 1) * n
    for i in range(n):
        m.face((last + i, last + (i + 1) % n, centre), None, True)


def dome(m, c, r, bulge, segs=24, rings=4):
    """A speaker's grille: a disc bowing out towards -Y, its rim at c.y."""
    cx, cy, cz = c
    rs = []
    for k in range(rings):
        t = 1.0 - k / rings
        y = cy - bulge * (1.0 - t * t)
        rs.append([(cx + r * t * math.cos(2 * math.pi * i / segs), y,
                    cz + r * t * math.sin(2 * math.pi * i / segs)) for i in range(segs)])
    facing_front(m, (cx, cy - bulge, cz), rs)


def screen(m, c, w, h, bulge, n=5.0, segs=28, rings=4):
    """A tube's glass: a rounded rectangle (a superellipse) bowing out towards -Y."""
    cx, cy, cz = c
    rs = []
    for k in range(rings):
        t = 1.0 - k / rings
        y = cy - bulge * (1.0 - t * t)
        ring = []
        for i in range(segs):
            a = 2 * math.pi * i / segs
            ca, sa = math.cos(a), math.sin(a)
            ex = math.copysign(abs(ca) ** (2 / n), ca)
            ez = math.copysign(abs(sa) ** (2 / n), sa)
            ring.append((cx + w / 2 * t * ex, y, cz + h / 2 * t * ez))
        rs.append(ring)
    facing_front(m, (cx, cy - bulge, cz), rs)


def loft(m, stations, z0, n, top_e=2.6, low_e=6.0, grow=0.0, zt_of=None):
    """A boot lofted along X through (x, half-width, top) stations: each a superellipse from z0
    to its top, rounder above than below so it sits flat on its sole."""
    bm = bmesh.new()
    rings = []
    for x, hw, zt in stations:
        if zt_of:
            zt = zt_of(zt)
        hw += grow
        zc, hh = (zt + z0) / 2, (zt - z0) / 2
        ring = []
        for i in range(n):
            a = 2 * math.pi * i / n
            ca, sa = math.cos(a), math.sin(a)
            e = 2 / (top_e if sa >= 0 else low_e)
            y = hw * math.copysign(abs(ca) ** e, ca)
            z = zc + hh * math.copysign(abs(sa) ** e, sa)
            ring.append(bm.verts.new((x, y, z)))
        rings.append(ring)
    for r0, r1 in zip(rings, rings[1:]):
        for i in range(n):
            bm.faces.new((r0[i], r0[(i + 1) % n], r1[(i + 1) % n], r1[i]))
    bm.faces.new(rings[0])
    bm.faces.new(rings[-1])
    solid(m, bm)


def boombox_geo():
    b = K.BOOMBOX
    F = Find("Boombox")
    w, d, h, f = b["w"], b["d"], b["h"], b["feet"]
    top, front = f + h, -d / 2
    F.add(BODY, geo.box, (-w / 2, -d / 2, f), (w / 2, d / 2, top), bevel=b["bevel"], segments=2)
    pf = front - 0.015  # the aluminium front's face
    F.add(PANEL, geo.box, (-w / 2 + 0.06, pf, f + 0.06), (w / 2 - 0.06, front + 0.01, top - 0.06))
    sx, sz, sr = b["speaker_x"], f + b["speaker_z"], b["speaker_r"]
    for s in (-1, 1):
        F.add(GRILLE, dome, (s * sx, pf, sz), sr, b["speaker_depth"] * 0.4, segs=20)
        F.add(CHROME, geo.ring_plate, (s * sx, pf - 0.012, sz), "y", sr + b["ring"], sr - 0.004,
              0.026, segs=20)
    dw, dh, dz = b["deck"]
    F.add(DECK, geo.box, (-dw / 2, pf - 0.018, f + dz), (dw / 2, pf + 0.005, f + dz + dh))
    F.add(GLASS, geo.box, (-dw / 2 + 0.06, pf - 0.026, f + dz + 0.08),
          (dw / 2 - 0.06, pf - 0.015, f + dz + dh - 0.08))
    tw, th, tz = b["dial"]
    F.add(DIAL, geo.box, (-tw / 2, pf - 0.014, f + tz), (tw / 2, pf + 0.005, f + tz + th))
    kw, kd, kh = b["key"]
    gap = 0.014
    x0 = -(b["keys"] * kw + (b["keys"] - 1) * gap) / 2
    for i in range(b["keys"]):
        x = x0 + i * (kw + gap)
        F.add(KEYS, geo.box, (x, front + 0.035, top - 0.03), (x + kw, front + 0.035 + kd, top + kh))
    for s in (-1, 1):
        F.add(KNOB, geo.cylinder, "z", (s * 0.5, -0.12, top + 0.02), 0.05, 0.06, segs=12)
    hx, hr, rise = b["handle_x"], b["handle_r"], b["handle_rise"]
    F.add(CHROME, geo.sweep, [(-hx, 0, top - 0.02), (-hx, 0, top + rise - 0.06),
                              (-hx + 0.06, 0, top + rise), (hx - 0.06, 0, top + rise),
                              (hx, 0, top + rise - 0.06), (hx, 0, top - 0.02)], hr, segs=10)
    for s in (-1, 1):
        F.add(BODY, geo.box, (s * hx - 0.07, -0.07, top - 0.02), (s * hx + 0.07, 0.07, top + 0.05))
    al, ar = b["antenna"]
    ay = d / 2 - 0.08
    F.add(BODY, geo.box, (-0.86, ay - 0.05, top - 0.02), (-0.72, ay + 0.05, top + 0.06))
    F.add(CHROME, geo.sweep, [(-0.75, ay, top + 0.03), (-0.75 + al, ay, top + 0.03)], ar, segs=6)
    F.add(CHROME, ellipsoid, (-0.75 + al, ay, top + 0.03), (0.026, 0.026, 0.026), us=8, vs=5)
    for sx_ in (-1, 1):
        for sy in (-1, 1):
            F.add(RUBBER, geo.cylinder, "z", (sx_ * (w / 2 - 0.2), sy * (d / 2 - 0.12), f / 2 + 0.005),
                  0.055, f + 0.01, segs=8)
    return F


def television_geo():
    b = K.TELEVISION
    F = Find("Television")
    w, h, f = b["w"], b["h"], b["feet"]
    top = f + h
    y0, y1 = -b["d"] / 2, b["d"] / 2 - b["back"][1]
    F.add(WOOD, geo.box, (-w / 2, y0, f), (w / 2, y1, top), bevel=b["bevel"], segments=2)
    bw, bd, bh = b["back"]
    F.add(BACK, frustum, y1 - 0.02, y1 + bd, bw, bh, bw * 0.68, bh * 0.66, f + h * 0.5)
    pf = y0 - 0.018
    F.add(BEZEL, geo.box, (-w / 2 + 0.04, pf, f + 0.04), (w / 2 - 0.04, y0 + 0.01, top - 0.04),
          bevel=0.01)
    cx, cz, sw, sh = b["screen"]
    F.add(SCREEN, screen, (cx, pf - 0.002, cz), sw, sh, b["bulge"])
    for kz in b["knobs"]:
        F.add(KNOB, geo.cylinder, "y", (b["knob_x"], pf - 0.03, kz), b["knob_r"], 0.06, segs=16)
    F.add(SWITCH, geo.box, (0.6, pf - 0.02, 0.57), (0.66, pf + 0.005, 0.6))
    length, r, splay, lean = b["ears"]
    bx = 0.18
    F.add(BACK, geo.cylinder, "z", (bx, 0.0, top + 0.025), 0.1, 0.06, segs=14, bevel=0.012)
    for s in (-1, 1):
        a, l_ = math.radians(splay), math.radians(lean)
        way = Vector((s * math.sin(a), math.sin(l_), math.cos(a) * math.cos(l_))).normalized()
        p = Vector((bx + s * 0.035, 0.0, top + 0.05))
        for i, (frac, rr) in enumerate(((0.4, r * 1.3), (0.34, r), (0.26, r * 0.72))):
            q = p + way * (length * frac)
            F.add(CHROME, geo.sweep, [tuple(p), tuple(q + way * 0.01)], rr, segs=6)
            p = q
        F.add(CHROME, ellipsoid, tuple(p), (0.024, 0.024, 0.024), us=8, vs=5)
    F.add(BACK, geo.sweep, [(-0.42, y0 + 0.32, top), (-0.36, y0 + 0.2, top + 0.02),
                            (0.36, y0 + 0.2, top + 0.02), (0.42, y0 + 0.32, top)], 0.022, segs=6)
    for sx in (-1, 1):
        for y in (y0 + 0.12, y1 - 0.12):
            F.add(RUBBER, geo.cylinder, "z", (sx * (w / 2 - 0.14), y, f / 2 + 0.005), 0.05, f + 0.01,
                  segs=8)
    return F


def teddy_geo():
    b = K.TEDDY
    F = Find("Teddy")
    kinds = {"body": FUR, "head": FUR, "ear": FUR, "arm": FUR, "leg": FUR, "muzzle": MUZZLE,
             "nose": NOSE, "pad": PAD, "eye": EYE, "bow": RIBBON, "knot": RIBBON}
    for part, c, r, turn, us, vs in b["parts"]:
        F.add(kinds[part], ellipsoid, c, r, turn, us, vs)
    (bx, by, bz), br, bt = b["button"]
    F.add(BUTTON, geo.cylinder, "y", (bx, by, bz), br, bt, segs=12)
    return F


def skates_geo():
    """One skate, along its own X (toe at +X); `pair` makes the pair after the unwrap."""
    b = K.SKATE
    F = Find("Skates")
    st, z0 = b["stations"], b["boot_bottom"]
    F.add(BOOT, loft, st, z0, b["round"])
    sole = [(x, hw, 0.0) for x, hw, _ in st]
    F.add(SOLE, loft, sole, z0 - b["sole"], 8, top_e=8.0, low_e=8.0, grow=0.01,
          zt_of=lambda _: z0 + 0.012)
    hx0, hx1, hh = b["heel"]
    F.add(SOLE, geo.box, (hx0, -0.11, z0 - b["sole"] - hh), (hx1, 0.11, z0 - b["sole"] + 0.01))
    F.add(PLATE, geo.box, (-0.41, -0.055, 0.17), (0.43, 0.055, z0 - b["sole"] + 0.005))
    wx, wy, wr, ww = b["wheel_x"], b["wheel_y"], b["wheel_r"], b["wheel_w"]
    for s in (-1, 1):
        F.add(PLATE, geo.box, (s * wx - 0.04, -0.075, wr - 0.01), (s * wx + 0.04, 0.075, 0.19))
        F.add(CHROME, geo.cylinder, "y", (s * wx, 0.0, wr), 0.02, 2 * wy + 0.02, segs=8)
        for t in (-1, 1):
            F.add(WHEEL, geo.cylinder, "y", (s * wx, t * wy, wr), wr, ww, segs=12, bevel=0.016)
    tx, tr, tl = b["toe_stop"]
    F.add(STOP, geo.sweep, [(tx - 0.03, 0.0, 0.2), (tx + 0.06, 0.0, 0.2 - tl)], tr, segs=10)
    return F


GEO = {"Boombox": boombox_geo, "Television": television_geo, "Teddy": teddy_geo,
       "Skates": skates_geo}
SHARP = {"Boombox": 35, "Television": 35, "Teddy": 60, "Skates": 40}


def surface(o):
    return sum(p.area for p in o.data.polygons)


def tiles(objs, pad=6):
    """A square of the atlas for each find, its side by the root of its surface, so every find
    gets the same texels a stud: shelf-packed, largest first, as big as they fit."""
    sides = {o.name: math.sqrt(surface(o)) for o in objs}
    order = sorted(sides, key=lambda n: -sides[n])
    size = K.TEX

    def place(k):
        out, x, y, row = {}, pad, pad, 0
        for n in order:
            w = math.floor(sides[n] * k)
            if x + w + pad > size:
                x, y, row = pad, y + row + pad, 0
            if y + w + pad > size or w + 2 * pad > size:
                return None
            out[n] = (x, y, w)
            x += w + pad
            row = max(row, w)
        return out

    lo, hi = 1.0, 2000.0
    for _ in range(40):
        mid = (lo + hi) / 2
        lo, hi = (mid, hi) if place(mid) else (lo, mid)
    return place(lo)


def unwrap(objs, pad=6):
    """Smart-project each find on its own (unwrapped together, the teddy's islands folded over
    one another), into its own square of the atlas."""
    rects = tiles(objs, pad)
    for o in objs:
        x, y, w = rects[o.name]
        bpy.ops.object.select_all(action="DESELECT")
        o.select_set(True)
        bpy.context.view_layer.objects.active = o
        bpy.ops.object.mode_set(mode="EDIT")
        bpy.ops.mesh.select_all(action="SELECT")
        bpy.ops.uv.smart_project(angle_limit=math.radians(55), island_margin=pad / w,
                                 area_weight=0.0, correct_aspect=True, scale_to_bounds=False)
        bpy.ops.object.mode_set(mode="OBJECT")
        uv = np.empty(len(o.data.loops) * 2, dtype=np.float32)
        o.data.uv_layers.active.data.foreach_get("uv", uv)
        uv = uv.reshape(-1, 2) * (w / K.TEX) + np.array([x, y], dtype=np.float32) / K.TEX
        o.data.uv_layers.active.data.foreach_set("uv", uv.ravel())
        o.data.update()
    clash = clashes(objs)
    assert not clash, f"faces share texels in the atlas: {clash}"


def clashes(objs, n=512):
    """Texels (at n x n) claimed twice: by two finds, or by two faces of one find (beyond the odd
    texel on a shared edge). Returns {what: texels} for any over the slack."""
    owner = np.full((n, n), -1, dtype=np.int32)
    face = np.full((n, n), -1, dtype=np.int64)
    out = {}
    ys, xs = np.mgrid[0:n, 0:n]
    cx, cy = xs + 0.5, ys + 0.5
    for oi, o in enumerate(objs):
        me = o.data
        me.calc_loop_triangles()
        uv = np.empty(len(me.loops) * 2, dtype=np.float32)
        me.uv_layers.active.data.foreach_get("uv", uv)
        uv = uv.reshape(-1, 2) * n
        for t in me.loop_triangles:
            a, b, c = uv[list(t.loops)]
            x0, y0 = np.maximum(np.floor(np.minimum(np.minimum(a, b), c)).astype(int), 0)
            x1, y1 = np.minimum(np.ceil(np.maximum(np.maximum(a, b), c)).astype(int), n)
            if x1 <= x0 or y1 <= y0:
                continue
            px, py = cx[y0:y1, x0:x1], cy[y0:y1, x0:x1]

            def side(u, v):
                return (v[0] - u[0]) * (py - u[1]) - (v[1] - u[1]) * (px - u[0])
            s1, s2, s3 = side(a, b), side(b, c), side(c, a)
            inside = ((s1 >= 0) & (s2 >= 0) & (s3 >= 0)) | ((s1 <= 0) & (s2 <= 0) & (s3 <= 0))
            box, fbox = owner[y0:y1, x0:x1], face[y0:y1, x0:x1]
            hit = inside & (box >= 0) & (box != oi)
            for other in np.unique(box[hit]):
                k = f"{objs[other].name}/{o.name}"
                out[k] = out.get(k, 0) + int((box[hit] == other).sum())
            own = inside & (box == oi) & (fbox != t.polygon_index)
            if own.any():
                out[o.name] = out.get(o.name, 0) + int(own.sum())
            box[inside] = oi
            fbox[inside] = t.polygon_index
    slack = {o.name: len(o.data.polygons) for o in objs}  # a texel centre on a shared edge
    return {k: v for k, v in out.items() if v > slack.get(k, 0)}


def density(objs):
    area = uv = 0.0
    for o in objs:
        me = o.data
        lay = me.uv_layers.active.data
        for p in me.polygons:
            area += p.area
            pts = [lay[i].uv for i in p.loop_indices]
            uv += abs(sum(pts[i].x * pts[i - 1].y - pts[i - 1].x * pts[i].y
                          for i in range(len(pts)))) / 2
    return K.TEX * math.sqrt(uv / area)


def corners(o):
    """Each loop's (face, vertex): a face's loops can start at another corner after the unwrap's
    trip through edit mode, so UVs are kept and worn by corner, not by loop number."""
    me = o.data
    poly = np.repeat(np.arange(len(me.polygons)), [p.loop_total for p in me.polygons])
    vert = np.empty(len(me.loops), dtype=np.int64)
    me.loops.foreach_get("vertex_index", vert)
    return poly * (len(me.vertices) + 1) + vert


def keep_uvs(objs):
    """Smart project doesn't pack the same way twice, so the bake's unwrap is saved and worn."""
    arrays = {}
    for n, o in objs.items():
        a = np.empty(len(o.data.loops) * 2, dtype=np.float32)
        o.data.uv_layers.active.data.foreach_get("uv", a)
        arrays[n] = a
        arrays[n + ".corner"] = corners(o)
    os.makedirs(OUT, exist_ok=True)
    np.savez(UVS, **arrays)


def wear_uvs(objs):
    data = np.load(UVS)
    for n, o in objs.items():
        a, key = data[n].reshape(-1, 2), data[n + ".corner"]
        mine = corners(o)
        assert len(key) == len(mine), f"{n} changed since the bake: run the textures stage"
        at = {k: i for i, k in enumerate(key.tolist())}
        order = np.array([at[k] for k in mine.tolist()])
        o.data.uv_layers.active.data.foreach_set("uv", a[order].ravel())
        o.data.update()


def unpainted(objs):
    """Faces whose middle wears a texel the bake never painted (out/cover.png)."""
    img = bake.load(os.path.join(OUT, "cover.png"), True)
    w, h = img.size
    px = np.empty(w * h * 4, dtype=np.float32)
    img.pixels.foreach_get(px)
    cov = px.reshape(h, w, 4)[..., 0] > 0.5  # bottom row first, as UVs count
    out = {}
    for n, o in objs.items():
        uv = np.empty(len(o.data.loops) * 2, dtype=np.float32)
        o.data.uv_layers.active.data.foreach_get("uv", uv)
        uv = uv.reshape(-1, 2)
        out[n] = sum(not cov[min(int(c[1] * h), h - 1), min(int(c[0] * w), w - 1)]
                     for c in (uv[p.loop_start:p.loop_start + p.loop_total].mean(0)
                               for p in o.data.polygons))
    return out


def uv_hash(objs):
    h = hashlib.sha1()
    for o in objs:
        a = np.empty(len(o.data.loops) * 2, dtype=np.float32)
        o.data.uv_layers.active.data.foreach_get("uv", a)
        h.update(np.round(a, 5).tobytes())
    return h.hexdigest()[:10]


def pair(ob):
    """The skates as a pair: the one skate copied, each placed and set down on the floor."""
    me = ob.data
    bm = bmesh.new()
    bm.from_mesh(me)
    first = list(bm.verts)
    dup = bmesh.ops.duplicate(bm, geom=list(bm.verts) + list(bm.edges) + list(bm.faces))
    second = [e for e in dup["geom"] if isinstance(e, bmesh.types.BMVert)]
    for verts, (at, turn, roll) in zip((first, second), K.SKATE["pair"]):
        # roll first (about the skate's own length: -90 lays it down, wheels to -Y), then turn
        M = Matrix.Rotation(math.radians(turn), 4, "Z") @ Matrix.Rotation(math.radians(roll), 4, "X")
        bmesh.ops.transform(bm, matrix=M, verts=verts)
        lo = min(v.co.z for v in verts)
        bmesh.ops.translate(bm, vec=Vector(at) - Vector((0, 0, lo)), verts=verts)
    bm.to_mesh(me)
    bm.free()
    me.update()


def ground(ob):
    """Its pivot the middle of its bottom: centred across and front to back, standing on z=0."""
    vs = [v.co for v in ob.data.vertices]
    lo = Vector([min(v[i] for v in vs) for i in range(3)])
    hi = Vector([max(v[i] for v in vs) for i in range(3)])
    ob.data.transform(Matrix.Translation(-Vector(((lo.x + hi.x) / 2, (lo.y + hi.y) / 2, lo.z))))
    ob.data.update()
    return hi - lo


def tris(ob):
    return sum(len(p.vertices) - 2 for p in ob.data.polygons)


def settle(objs):
    """A trip through edit mode renumbers some of a fresh mesh's faces and corners (the teddy's),
    and the unwrap makes that trip, so every stage makes it first: then the bake's saved UVs fit
    the meshes every later stage builds."""
    bpy.ops.object.select_all(action="DESELECT")
    for o in objs:
        o.select_set(True)
    bpy.context.view_layer.objects.active = objs[0]
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.object.mode_set(mode="OBJECT")


def build_all(baking, coll=None):
    objs = {n: GEO[n]().build(SHARP[n], coll) for n in K.ORDER}
    settle(list(objs.values()))
    if baking:
        unwrap(list(objs.values()))
        keep_uvs(objs)
    else:
        wear_uvs(objs)
        print(f"atlas: faces on unpainted texels {unpainted(objs)}")
    dens = density(list(objs.values()))
    print(f"atlas: {dens:.0f} texels a stud, uv {uv_hash(list(objs.values()))}")
    sizes = {}
    if not baking:
        pair(objs["Skates"])
        for n, ob in objs.items():
            sizes[n] = ground(ob)
    return objs, sizes


# --- the recipes -----------------------------------------------------------------------------

class Look:
    """What every recipe reads: the find's own studs (object space), its normal, its face kinds."""

    def __init__(self, nb, seed):
        self.nb, self.seed = nb, seed
        self.P = nb.node("ShaderNodeTexCoord").outputs["Object"]
        self.x, self.y, self.z = nb.sep(self.P)
        self.nx, self.ny, self.nz = nb.sep(nb.geo().outputs["Normal"])
        self.kind = nb.node("ShaderNodeAttribute", attribute_type="GEOMETRY",
                            attribute_name="kind").outputs["Fac"]
        self.front = nb.ss(nb.mul(self.ny, -1.0), 0.45, 0.75)
        self.up = nb.ss(self.nz, 0.45, 0.9)

    def k(self, *ks):
        nb, m = self.nb, None
        for k in ks:
            one = nb.band(self.kind, k - 0.3, k + 0.3, 0.1)
            m = one if m is None else nb.add(m, one, clamp=True)
        return m

    def vec(self, sx=1.0, sy=1.0, sz=1.0, s=0.0):
        nb, sd = self.nb, self.seed
        v = nb.vop("MULTIPLY", self.P, (sx, sy, sz))
        return nb.vop("ADD", v, (sd * 7.13 + s * 3.1, sd * 3.71 + s * 5.3, sd * 5.27 + s * 1.7)), None

    def noise(self, scale, s, stretch=(1.0, 1.0, 1.0), **kw):
        return self.nb.noise(self.vec(*stretch, s=s), scale, **kw)

    def dist(self, a, b):
        nb = self.nb
        return nb.pw(nb.add(nb.mul(a, a), nb.mul(b, b)), 0.5)

    def disc(self, cx, cz, r, soft=0.003):
        """1 inside a circle on the X-Z plane (what faces front)."""
        nb = self.nb
        return nb.ss(self.dist(nb.sub(self.x, cx), nb.sub(self.z, cz)), r + soft, r - soft)

    def rect(self, x0, x1, z0, z1, soft=0.002, u=None, v=None):
        nb = self.nb
        u = self.x if u is None else u
        v = self.z if v is None else v
        return nb.mul(nb.band(u, x0, x1, soft), nb.band(v, z0, z1, soft))

    def superellipse(self, cx, cz, hw, hh, n=5.0):
        """0 at the centre, 1 on a rounded rectangle hw x hh round (cx, cz)."""
        nb = self.nb
        ux = nb.absf(nb.div(nb.sub(self.x, cx), hw))
        uz = nb.absf(nb.div(nb.sub(self.z, cz), hh))
        return nb.pw(nb.add(nb.pw(ux, n), nb.pw(uz, n)), 1.0 / n)


class Coat:
    """The layers a recipe paints, mixed in where a mask says."""

    def __init__(self, L, col, rough, metal=0.0, height=0.0):
        self.L, self.nb = L, L.nb
        self.col, self.rough, self.metal, self.height = col, rough, metal, height

    def paint(self, mask, col=None, rough=None, metal=None, height=None):
        nb = self.nb
        if col is not None:
            self.col = nb.mixc(mask, self.col, col)
        if rough is not None:
            self.rough = nb.mixf(mask, self.rough, rough)
        if metal is not None:
            self.metal = nb.mixf(mask, self.metal, metal)
        if height is not None:
            self.height = nb.add(self.height, nb.mul(mask, height))

    def chrome(self, mask, s=30):
        """Old chrome: bright, tarnished in patches, pitted with a little rust."""
        L, nb = self.L, self.nb
        pit = nb.ss(L.noise(70.0, s, detail=3), 0.66, 0.74)
        tarn = L.noise(5.0, s + 1, detail=4)
        c = nb.tint(hexc("#DCDDDE"), nb.mr(tarn, 0.3, 0.7, 0.62, 1.0))
        c = nb.mixc(nb.mul(pit, 0.75), c, hexc("#5E4A3A"))
        self.paint(mask, c, nb.mixf(pit, nb.mr(tarn, 0.3, 0.7, 0.07, 0.24), 0.62),
                   nb.mixf(pit, 1.0, 0.3), nb.mul(pit, -0.3))

    def rubber(self, mask):
        self.paint(mask, hexc("#0E0E0E"), 0.9, 0.0)

    def finish(self, ao=0.25, ao_low=0.45, dust=K.DUST, s=40):
        """Grime in the creases, then the dust: on whatever faces up, thinner on the edges."""
        L, nb = self.L, self.nb
        self.col = nb.tint(self.col, nb.mr(nb.ao(ao, local=True), 0.0, 1.0, ao_low, 1.0))
        if dust <= 0:
            return
        film = nb.mr(L.noise(1.7, s, detail=6, rough=0.6, distortion=0.6), 0.2, 0.8, 0.3, 0.85)
        edge = nb.edge(0.015, k=5.0)
        d = nb.mul(nb.mul(L.up, film), nb.mul(dust, nb.inv(nb.mul(edge, 0.6))))
        speck = nb.mul(nb.mul(L.up, nb.ss(L.noise(80.0, s + 1, detail=2), 0.56, 0.7)), 0.35 * dust)
        d = nb.add(d, speck, clamp=True)
        self.paint(nb.mul(d, 0.62), hexc("#9C9488"))
        self.paint(d, rough=0.95, metal=0.0, height=0.08)

    def channels(self, dist=0.003, strength=0.7):
        return Channels(self.col, 1.0, self.rough, self.metal, self.height,
                        bump_dist=dist, bump_strength=strength)


def boombox_look(nb):
    b = K.BOOMBOX
    L = Look(nb, b["seed"])
    x, z = L.x, L.z
    f = b["feet"]

    # the case: black plastic with a fine pebbled grain, its edges scuffed grey
    grain = L.noise(220.0, 1, detail=2)
    C = Coat(L, nb.tint(hexc("#121213"), nb.mr(L.noise(3.0, 2, detail=3), 0.3, 0.7, 0.8, 1.2)),
             nb.mr(grain, 0.3, 0.7, 0.4, 0.55), 0.0, nb.mul(grain, 0.15))
    scuff = nb.mul(nb.edge(0.03, k=5.0), nb.ss(L.noise(9.0, 3, detail=4), 0.42, 0.6))
    C.paint(nb.mul(scuff, nb.mul(L.k(BODY, KNOB), 0.65)), hexc("#58554F"), 0.7)

    # the front: brushed aluminium, scratched, with the red and orange stripes of its day
    panel = L.k(PANEL)
    brush = L.noise(90.0, 4, stretch=(0.03, 1.0, 1.0), detail=2)
    C.paint(panel, nb.tint(hexc("#B9BCBF"), nb.mr(brush, 0.3, 0.7, 0.84, 1.06)),
            nb.mr(brush, 0.3, 0.7, 0.24, 0.38), 1.0)
    tz = f + b["dial"][2] + b["dial"][1]
    face = nb.mul(panel, L.front)
    red = nb.mul(L.rect(-2, 2, tz + 0.03, tz + 0.056), face)
    orange = nb.mul(L.rect(-2, 2, tz + 0.066, tz + 0.09), face)
    C.paint(red, hexc("#B5322A"), 0.42, 0.0)
    C.paint(orange, hexc("#DB7F2A"), 0.42, 0.0)
    scr = nb.band(L.noise(5.0, 5, stretch=(1.0, 1.0, 0.18), detail=2), 0.4985, 0.5015, 0.001)
    scr = nb.mul(nb.mul(scr, nb.ss(L.noise(2.0, 6), 0.58, 0.68)), panel)
    C.paint(nb.mul(scr, 0.35), hexc("#D9DCDF"), 0.5, height=-0.2)

    # the speakers: a perforated grille over a dark cone, a chrome dust cap in the middle
    gr = L.k(GRILLE)
    sx, sz = b["speaker_x"], f + b["speaker_z"]
    rr = L.dist(nb.sub(nb.absf(x), sx), nb.sub(z, sz))
    pitch = 1.0 / 0.032
    fu = nb.sub(nb.fract(nb.mul(x, pitch)), 0.5)
    fv = nb.sub(nb.fract(nb.mul(z, pitch)), 0.5)
    cap = nb.ss(rr, 0.078, 0.07)
    hole = nb.mul(nb.ss(L.dist(fu, fv), 0.36, 0.27), nb.inv(cap))
    cone = nb.tint(hexc("#2C2C2E"), nb.mr(rr, 0.08, b["speaker_r"], 1.15, 0.3))
    gcol = nb.mixc(nb.mul(hole, 0.92), hexc("#8D9094"), cone)
    gcol = nb.mixc(cap, gcol, hexc("#D3D5D7"))
    C.paint(gr, gcol, nb.mixf(hole, nb.mixf(cap, 0.36, 0.14), 0.85),
            nb.mixf(hole, 0.95, 0.0), nb.mul(nb.mul(hole, gr), -0.7))

    C.chrome(L.k(CHROME))

    # the deck: a black door with a thin silver frame, and a tape behind its smoked window
    deck = L.k(DECK)
    dw, dh, dz = b["deck"]
    d0 = f + dz
    frame = nb.sub(L.rect(-dw / 2 + 0.02, dw / 2 - 0.02, d0 + 0.02, d0 + dh - 0.02),
                   L.rect(-dw / 2 + 0.03, dw / 2 - 0.03, d0 + 0.03, d0 + dh - 0.03))
    C.paint(deck, hexc("#18181A"), 0.34)
    C.paint(nb.mul(nb.mul(frame, deck), L.front), hexc("#A7AAAD"), 0.3, 0.9)
    glass = L.k(GLASS)
    cz = d0 + dh / 2
    tape = hexc("#2A2A2C")
    body = L.rect(-0.16, 0.16, cz - 0.1, cz + 0.1, 0.003)
    label = L.rect(-0.14, 0.14, cz + 0.03, cz + 0.085, 0.002)
    stripe = L.rect(-0.14, 0.14, cz + 0.036, cz + 0.046, 0.001)
    win = L.rect(-0.075, 0.075, cz - 0.06, cz + 0.012, 0.002)
    lpack = L.disc(-0.052, cz - 0.024, 0.042)
    rpack = L.disc(0.052, cz - 0.024, 0.027)
    hubs = nb.add(L.disc(-0.052, cz - 0.024, 0.017), L.disc(0.052, cz - 0.024, 0.017), clamp=True)
    holes = nb.add(L.disc(-0.052, cz - 0.024, 0.008), L.disc(0.052, cz - 0.024, 0.008), clamp=True)
    cass = nb.mixc(body, hexc("#060607"), tape)
    cass = nb.mixc(label, cass, hexc("#D8CDB0"))
    cass = nb.mixc(stripe, cass, hexc("#B03A2E"))
    cass = nb.mixc(win, cass, hexc("#141210"))
    cass = nb.mixc(nb.mul(nb.add(lpack, rpack, clamp=True), win), cass, hexc("#3C2416"))
    cass = nb.mixc(hubs, cass, hexc("#D2D2D0"))
    cass = nb.mixc(holes, cass, hexc("#0A0A0A"))
    C.paint(glass, nb.mixc(0.5, cass, hexc("#07070A")), 0.05, 0.0)

    # the tuner: dark glass, two rows of ticks, a red needle
    dial = L.k(DIAL)
    tw, th, t0 = b["dial"]
    t0 += f
    fine = nb.mul(nb.band(nb.fract(nb.mul(x, 30.0)), 0.0, 0.14, 0.02), L.rect(-0.3, 0.3, t0 + 0.03, t0 + 0.05))
    major = nb.mul(nb.band(nb.fract(nb.mul(x, 6.0)), 0.0, 0.05, 0.01), L.rect(-0.3, 0.3, t0 + 0.03, t0 + 0.07))
    nums = nb.mul(nb.band(nb.fract(nb.add(nb.mul(x, 6.0), 0.5)), 0.42, 0.58, 0.02),
                  L.rect(-0.3, 0.3, t0 + 0.078, t0 + 0.094))
    am = nb.mul(nb.band(nb.fract(nb.mul(x, 18.0)), 0.0, 0.12, 0.02), L.rect(-0.3, 0.3, t0 + 0.1, t0 + 0.112))
    ticks = nb.mul(nb.add(nb.add(fine, major, clamp=True), nb.add(nums, am, clamp=True), clamp=True), L.front)
    needle = nb.mul(L.rect(0.075, 0.085, t0 + 0.018, t0 + th - 0.018), L.front)
    dcol = nb.mixc(nb.mul(ticks, 0.9), hexc("#0E1012"), hexc("#E6E3DA"))
    dcol = nb.mixc(needle, dcol, hexc("#D2382B"))
    C.paint(dial, dcol, 0.06, 0.0)

    # the piano keys: aluminium, the record key red
    keys = L.k(KEYS)
    C.paint(keys, hexc("#ADB0B3"), 0.32, 0.75)
    rec = nb.mul(keys, nb.ss(x, -0.16, -0.17))
    C.paint(rec, hexc("#A3231C"), 0.36, 0.0)
    knob = L.k(KNOB)
    C.paint(nb.mul(knob, L.up), hexc("#B5B8BB"), 0.3, 0.9)
    C.rubber(L.k(RUBBER))
    C.finish(ao=0.22)
    return C.channels()


def television_look(nb):
    b = K.TELEVISION
    L = Look(nb, b["seed"])
    x, y, z = L.x, L.y, L.z

    # the cabinet: walnut woodgrain vinyl, its grain along X on top and front-to-back on the sides
    wood = L.k(WOOD)
    side = nb.ss(nb.absf(L.nx), 0.5, 0.7)
    ga = L.noise(4.0, 1, stretch=(0.05, 1.0, 1.0), detail=3, distortion=0.9)
    gb = L.noise(4.0, 1, stretch=(1.0, 0.05, 1.0), detail=3, distortion=0.9)
    g = nb.mixf(side, ga, gb)
    lines = nb.band(nb.fract(nb.mul(g, 12.0)), 0.55, 0.85, 0.08)
    base = nb.mixc(nb.mr(L.noise(1.6, 2), 0.3, 0.7), hexc("#5A381E"), hexc("#7C4F2B"))
    wcol = nb.mixc(nb.mul(lines, 0.65), base, hexc("#331D0F"))
    pores = nb.ss(L.noise(150.0, 3, stretch=(0.3, 0.3, 1.0), detail=1), 0.66, 0.72)
    wcol = nb.mixc(nb.mul(pores, 0.4), wcol, hexc("#2A170B"))
    C = Coat(L, wcol, nb.mixf(lines, 0.36, 0.46), 0.0, nb.add(nb.mul(lines, -0.12), nb.mul(pores, -0.1)))
    worn = nb.mul(nb.mul(nb.edge(0.035, k=6.0), nb.ss(L.noise(7.0, 4, detail=4), 0.48, 0.62)), wood)
    C.paint(nb.mul(worn, 0.85), hexc("#BFA47A"), 0.8, height=-0.2)
    top = nb.ss(L.nz, 0.8, 0.95)
    ring = nb.band(L.dist(nb.add(x, 0.36), nb.add(y, 0.12)), 0.104, 0.118, 0.004)
    ring = nb.mul(nb.mul(nb.mul(ring, top), wood), nb.ss(L.noise(12.0, 5), 0.3, 0.45))
    C.paint(nb.mul(ring, 0.7), hexc("#8E6E4E"), 0.72)

    # the front: silver-painted plastic, black round the glass, slots for the speaker
    bz = L.k(BEZEL)
    paint = nb.tint(hexc("#A6A9AC"), nb.mr(L.noise(30.0, 6, detail=3), 0.3, 0.7, 0.9, 1.04))
    C.paint(bz, paint, 0.42, 0.5)
    cx, cz, sw, sh = b["screen"]
    surround = nb.mul(nb.ss(L.superellipse(cx, cz, sw / 2 + 0.04, sh / 2 + 0.04), 1.01, 0.99), bz)
    C.paint(surround, hexc("#111214"), 0.55, 0.0)
    slots = nb.mul(nb.mul(L.rect(0.41, 0.65, 0.16, 0.5), nb.band(nb.fract(nb.mul(z, 22.0)), 0.0, 0.42, 0.03)), bz)
    C.paint(nb.mul(slots, L.front), hexc("#0A0A0A"), 0.8, 0.0, -0.6)
    groove = nb.mul(nb.mul(nb.band(x, 0.385, 0.392, 0.002), L.rect(-2, 2, 0.12, 1.2)), bz)
    C.paint(nb.mul(groove, L.front), hexc("#55585B"), height=-0.4)

    # the glass: grey-green, darker at the edges, a film of dust with a finger's wipe through it
    sc = L.k(SCREEN)
    se = L.superellipse(cx, cz, sw / 2, sh / 2)
    C.paint(sc, nb.tint(hexc("#1F2823"), nb.mr(se, 0.2, 1.0, 1.0, 0.5)), 0.05, 0.0)
    film = nb.mr(L.noise(3.0, 7, detail=5), 0.3, 0.7, 0.45, 0.75)
    wipe = nb.band(nb.add(nb.sub(z, 0.86), nb.mul(nb.add(x, 0.2), 0.32)), -0.035, 0.035, 0.03)
    wipe = nb.mul(wipe, nb.band(x, -0.44, 0.1, 0.12))
    film = nb.mul(film, nb.inv(nb.mul(wipe, 0.5)))  # a smear, not a clean line
    C.paint(nb.mul(nb.mul(film, sc), 0.62), hexc("#8F8B83"), rough=None)
    C.paint(nb.mul(film, sc), rough=0.85)

    # the dials: black, ridged, an aluminium insert with a white mark
    knob = L.k(KNOB)
    kx, (ka, kb), kr = b["knob_x"], b["knobs"], b["knob_r"]
    kz = nb.mixf(nb.ss(z, (ka + kb) / 2 - 0.005, (ka + kb) / 2 + 0.005), kb, ka)
    dx, dz = nb.sub(x, kx), nb.sub(z, kz)
    rk = L.dist(dx, dz)
    ang = nb.math("ARCTAN2", dz, dx)
    ridge = nb.band(nb.fract(nb.mul(ang, 24.0 / (2 * math.pi))), 0.0, 0.4, 0.08)
    C.paint(knob, hexc("#151515"), 0.4, 0.0, nb.mul(nb.mul(ridge, nb.inv(L.front)), 0.6))
    insert = nb.mul(nb.mul(nb.ss(rk, kr - 0.022, kr - 0.03), L.front), knob)
    C.paint(insert, hexc("#B2B5B8"), 0.3, 0.9)
    mark = nb.mul(nb.mul(nb.band(dx, -0.006, 0.006, 0.002), nb.ss(dz, 0.012, 0.02)), insert)
    C.paint(mark, hexc("#EDEBE4"), 0.4, 0.0)
    C.paint(L.k(SWITCH), hexc("#A1261F"), 0.35, 0.0)

    # behind: the tube's brown-black housing with vents on top
    back = L.k(BACK)
    C.paint(back, nb.tint(hexc("#27221E"), nb.mr(L.noise(6.0, 8), 0.3, 0.7, 0.85, 1.1)), 0.55, 0.0)
    vents = nb.mul(nb.mul(nb.band(nb.fract(nb.mul(x, 14.0)), 0.0, 0.42, 0.04), nb.ss(nb.absf(x), 0.36, 0.33)),
                   nb.mul(nb.mul(back, L.up), nb.ss(y, 0.3, 0.34)))
    C.paint(vents, hexc("#070707"), 0.9, height=-0.6)
    C.chrome(L.k(CHROME))
    C.rubber(L.k(RUBBER))
    C.finish(ao=0.25)
    return C.channels()


def teddy_look(nb):
    b = K.TEDDY
    L = Look(nb, b["seed"])
    x, z = L.x, L.z
    fur = L.k(FUR)

    # plush: cream gone grey with handling, combed down, matted into clumps
    strands = L.noise(70.0, 1, stretch=(1.0, 1.0, 0.22), detail=3)
    clump = nb.voronoi(L.vec(s=2), 22.0, out="Distance")
    tone = nb.mr(L.noise(2.2, 3, detail=4), 0.3, 0.7, 0.86, 1.06)
    base = nb.tint(hexc("#D6C4A2"), tone)
    C = Coat(L, nb.tint(base, nb.mr(strands, 0.3, 0.7, 0.86, 1.06)), 0.92, 0.0,
             nb.add(nb.mul(strands, 0.45), nb.mul(nb.mr(clump, 0.0, 0.5, 0.0, 0.35), 1.0)))
    C.col = nb.tint(C.col, nb.mr(clump, 0.0, 0.5, 0.9, 1.04))
    held = nb.mul(nb.add(nb.ss(z, 1.05, 1.32), nb.mul(nb.ss(nb.absf(x), 0.36, 0.46), nb.ss(z, 0.55, 0.4)), clamp=True),
                  nb.ss(L.noise(5.0, 4, detail=3), 0.35, 0.6))
    C.paint(nb.mul(nb.mul(held, fur), 0.7), hexc("#9F8F72"), 0.96)

    # the muzzle, the paws' pads and the ears' insides: lighter, short and felted
    mz = L.k(MUZZLE)
    C.paint(mz, nb.tint(hexc("#ECE1CA"), nb.mr(L.noise(40.0, 5, detail=3), 0.3, 0.7, 0.9, 1.04)), 0.9,
            height=nb.mul(nb.mul(strands, mz), -0.3))
    pad = L.k(PAD)
    C.paint(pad, nb.tint(hexc("#C9AE86"), nb.mr(L.noise(90.0, 6, detail=2), 0.3, 0.7, 0.88, 1.05)), 0.86)
    inner = nb.mul(nb.mul(fur, L.front), nb.ss(z, 1.29, 1.31))
    inner = nb.mul(inner, nb.ss(nb.absf(nb.sub(nb.absf(x), 0.23)), 0.075, 0.06))
    C.paint(inner, hexc("#E3D3B4"), 0.9)

    # a seam down the middle of the front, sewn in brown thread
    seam = nb.mul(nb.mul(nb.band(x, -0.004, 0.004, 0.002), L.front), nb.add(fur, mz, clamp=True))
    stitch = nb.band(nb.fract(nb.mul(z, 70.0)), 0.0, 0.5, 0.05)
    C.paint(nb.mul(seam, 0.8), hexc("#6A5641"), height=-0.6)
    cross = nb.mul(nb.mul(nb.band(x, -0.012, 0.012, 0.002), stitch),
                   nb.mul(L.front, nb.add(fur, mz, clamp=True)))
    C.paint(nb.mul(cross, 0.7), hexc("#5A4532"), height=-0.3)

    # the mend: a square of plaid sewn over a hole in its belly, a running stitch round it
    px, pz, pw, ph = b["patch"]
    on = nb.mul(nb.mul(L.rect(px - pw / 2, px + pw / 2, pz - ph / 2, pz + ph / 2, 0.003), L.front), fur)
    sx = nb.band(nb.fract(nb.mul(x, 13.0)), 0.0, 0.32, 0.02)
    sz = nb.band(nb.fract(nb.mul(z, 13.0)), 0.0, 0.32, 0.02)
    thin = nb.add(nb.band(nb.fract(nb.mul(x, 13.0)), 0.6, 0.66, 0.01),
                  nb.band(nb.fract(nb.mul(z, 13.0)), 0.6, 0.66, 0.01), clamp=True)
    plaid = nb.mixc(nb.mul(nb.add(sx, sz, clamp=True), 0.7), hexc("#9A2E27"), hexc("#2C4733"))
    plaid = nb.mixc(nb.mul(nb.mul(sx, sz), 0.6), plaid, hexc("#1B2A1F"))
    plaid = nb.mixc(nb.mul(thin, 0.7), plaid, hexc("#D9C99A"))
    C.paint(on, nb.tint(plaid, nb.mr(L.noise(60.0, 7), 0.3, 0.7, 0.88, 1.05)), 0.82, height=0.4)
    border = nb.sub(L.rect(px - pw / 2 - 0.012, px + pw / 2 + 0.012, pz - ph / 2 - 0.012, pz + ph / 2 + 0.012, 0.002),
                    L.rect(px - pw / 2 - 0.002, px + pw / 2 + 0.002, pz - ph / 2 - 0.002, pz + ph / 2 + 0.002, 0.002))
    dash = nb.band(nb.fract(nb.mul(nb.add(x, z), 45.0)), 0.0, 0.55, 0.05)
    C.paint(nb.mul(nb.mul(nb.mul(border, dash), L.front), fur), hexc("#3E2C1E"), height=0.3)

    # the nose in satin stitches, a bead for one eye and a red button sewn on for the other
    C.paint(L.k(NOSE), hexc("#3A2417"), 0.5, 0.0,
            nb.mul(nb.band(nb.fract(nb.mul(z, 150.0)), 0.0, 0.6, 0.1), L.k(NOSE)))
    C.paint(L.k(EYE), hexc("#050505"), 0.06, 0.0)
    (bx, _, bzz), br, _ = b["button"]
    btn = L.k(BUTTON)
    hole = nb.add(L.disc(bx - 0.011, bzz, 0.006), L.disc(bx + 0.011, bzz, 0.006), clamp=True)
    thread = nb.mul(L.rect(bx - 0.013, bx + 0.013, bzz - 0.003, bzz + 0.003), L.front)
    C.paint(btn, hexc("#A12B22"), 0.3, 0.0)
    C.paint(nb.mul(nb.mul(hole, btn), L.front), hexc("#2A0907"), height=-0.5)
    C.paint(nb.mul(thread, btn), hexc("#D8CBB0"), 0.8, height=0.3)
    rim = nb.mul(nb.ss(L.dist(nb.sub(x, bx), nb.sub(z, bzz)), br - 0.008, br - 0.004), nb.mul(btn, L.front))
    C.paint(rim, height=0.25)

    # the bow: red satin, faded where the light found it
    rib = L.k(RIBBON)
    sheen = nb.mr(L.noise(30.0, 8, stretch=(1.0, 1.0, 0.2), detail=2), 0.3, 0.7, 0.85, 1.1)
    C.paint(rib, nb.tint(hexc("#9B3430"), sheen), 0.34, 0.0)
    C.paint(nb.mul(nb.mul(rib, L.up), 0.6), hexc("#B9675D"))
    C.finish(ao=0.16, ao_low=0.35)
    return C.channels(dist=0.004, strength=0.6)


def skates_look(nb):
    b = K.SKATE
    L = Look(nb, b["seed"])
    x, y, z = L.x, L.y, L.z
    boot = L.k(BOOT)
    side = nb.ss(nb.absf(L.ny), 0.4, 0.65)

    # the boot: ivory leather, creased where the ankle bends, scuffed at the toe and heel
    grain = L.noise(160.0, 1, detail=2)
    crease = nb.band(nb.fract(nb.mul(nb.add(nb.add(nb.mul(x, 0.9), nb.mul(z, 0.5)),
                                           nb.mul(L.noise(3.0, 2), 0.06)), 20.0)), 0.0, 0.12, 0.05)
    crease = nb.mul(crease, nb.band(x, -0.2, 0.12, 0.08))
    C = Coat(L, nb.tint(hexc("#E8E2D5"), nb.mr(L.noise(2.5, 3, detail=4), 0.3, 0.7, 0.9, 1.03)),
             nb.mr(grain, 0.3, 0.7, 0.45, 0.6), 0.0, nb.add(nb.mul(grain, 0.12), nb.mul(crease, -0.5)))
    C.col = nb.tint(C.col, nb.mixf(crease, 1.0, 0.86))
    worn = nb.add(nb.ss(x, 0.36, 0.48), nb.ss(x, -0.42, -0.5), clamp=True)
    worn = nb.mul(nb.mul(worn, nb.ss(L.noise(8.0, 4, detail=5), 0.4, 0.62)), boot)
    C.paint(nb.mul(worn, 0.8), hexc("#8F887C"), 0.7)

    # the stripes down its side, pink over teal, stopping short of the toe
    ends = nb.ss(nb.add(x, nb.mul(nb.sub(z, 0.3), 0.6)), 0.31, 0.29)
    pink = nb.mul(nb.mul(nb.mul(nb.band(z, 0.325, 0.352, 0.002), side), boot), ends)
    teal = nb.mul(nb.mul(nb.mul(nb.band(z, 0.362, 0.389, 0.002), side), boot), ends)
    C.paint(pink, hexc("#E04A80"), 0.5)
    C.paint(teal, hexc("#2A9E9C"), 0.5)
    stitch = nb.mul(nb.mul(nb.band(z, 0.296, 0.3, 0.001), nb.band(nb.fract(nb.mul(x, 60.0)), 0.0, 0.55, 0.05)), boot)
    C.paint(nb.mul(stitch, 0.8), hexc("#7A7266"), height=-0.3)
    toecap = nb.mul(nb.mul(nb.band(x, 0.335, 0.341, 0.001), boot), nb.band(nb.fract(nb.mul(z, 60.0)), 0.0, 0.55, 0.05))
    C.paint(nb.mul(toecap, 0.8), hexc("#857D70"), height=-0.3)

    # the laces criss-crossing up the instep, through chrome eyelets
    instep = nb.mul(nb.mul(nb.ss(L.nz, 0.3, 0.5), L.rect(-0.14, 0.33, -2, 2, 0.01)), boot)
    tongue = nb.mul(nb.ss(nb.absf(y), 0.07, 0.06), instep)
    C.paint(tongue, hexc("#D6CFC0"), 0.6)
    d1 = nb.fract(nb.mul(nb.add(x, nb.mul(y, 0.9)), 13.0))
    d2 = nb.fract(nb.mul(nb.sub(x, nb.mul(y, 0.9)), 13.0))
    lace = nb.add(nb.band(d1, 0.0, 0.26, 0.04), nb.band(d2, 0.0, 0.26, 0.04), clamp=True)
    lace = nb.mul(nb.mul(lace, nb.ss(nb.absf(y), 0.085, 0.075)), instep)
    C.paint(lace, hexc("#F3F0E9"), 0.75, height=0.6)
    eyelet = nb.mul(nb.mul(nb.band(nb.absf(y), 0.078, 0.094, 0.003),
                           nb.band(nb.fract(nb.mul(x, 13.0)), 0.0, 0.16, 0.03)), instep)
    C.paint(eyelet, hexc("#C9CBCD"), 0.25, 1.0, 0.3)

    # the ankle's opening: padded lining, dark inside
    ex = nb.div(nb.add(x, 0.31), 0.155)
    ey = nb.div(y, 0.098)
    oval = L.dist(ex, ey)
    collar = nb.mul(nb.mul(nb.ss(L.nz, 0.7, 0.85), nb.ss(x, -0.1, -0.13)), boot)
    C.paint(nb.mul(nb.ss(oval, 1.25, 1.05), collar), hexc("#CFC6B4"), 0.75, height=0.3)
    C.paint(nb.mul(nb.ss(oval, 1.0, 0.92), collar), hexc("#19140F"), 0.9, height=-1.0)

    # the sole, the plate and the trucks
    C.paint(L.k(SOLE), nb.tint(hexc("#3A2A1F"), nb.mr(L.noise(20.0, 5), 0.3, 0.7, 0.8, 1.1)), 0.58)
    plate = L.k(PLATE)
    C.paint(plate, nb.tint(hexc("#55585C"), nb.mr(L.noise(12.0, 6, detail=4), 0.3, 0.7, 0.75, 1.1)), 0.42, 0.85)
    C.chrome(L.k(CHROME))

    # the wheels: pink urethane, worn round their tread, a white hub and its bearing
    wheel = L.k(WHEEL)
    rw = L.dist(nb.sub(nb.absf(x), b["wheel_x"]), nb.sub(z, b["wheel_r"]))
    hubface = nb.mul(wheel, side)
    C.paint(wheel, nb.tint(hexc("#E3477F"), nb.mr(L.noise(25.0, 7), 0.3, 0.7, 0.9, 1.05)), 0.42, 0.0)
    tread = nb.mul(wheel, nb.inv(side))
    C.paint(nb.mul(tread, 0.5), hexc("#B23A64"), 0.6)
    C.paint(nb.mul(nb.ss(rw, 0.052, 0.046), hubface), hexc("#DADAD8"), 0.35, 0.0, 0.2)
    C.paint(nb.mul(nb.ss(rw, 0.022, 0.018), hubface), hexc("#3A3B3D"), 0.3, 0.8, -0.4)

    # the toe stop: red rubber, its tip ground flat and dark
    stop = L.k(STOP)
    C.paint(stop, hexc("#A22E26"), 0.85, 0.0)
    C.paint(nb.mul(nb.mul(stop, nb.ss(z, 0.11, 0.08)), 0.7), hexc("#4A1A15"), 0.95)
    C.finish(ao=0.18)
    return C.channels(dist=0.003, strength=0.6)


LOOK = {"Boombox": boombox_look, "Television": television_look, "Teddy": teddy_look,
        "Skates": skates_look}
BEVEL = {"Boombox": 0.012, "Television": 0.014, "Teddy": 0.0, "Skates": 0.008}


def rig(name):
    """A bake rig; hard-surface finds also round their edges in the normals (the Bevel node)."""
    r = bake.Rig(f"bk_{name}", LOOK[name])
    if BEVEL[name] > 0:
        bump = r.bsdf.inputs["Normal"].links[0].from_node
        bev = r.nb.node("ShaderNodeBevel", samples=8)
        r.nb.put(bev.inputs[0], BEVEL[name])
        r.nb.links.new(bev.outputs[0], bump.inputs["Normal"])
    return r


def dilate(a, covered, steps):
    """Grow every island's edge texels outward into the empty gutter, never over another island,
    so mipmaps and filtering at an island's edge read its own colour."""
    a, cov = a.copy(), covered.copy()
    for _ in range(steps):
        acc, cnt = np.zeros_like(a), np.zeros(cov.shape, dtype=np.float32)
        for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1), (1, 1), (1, -1), (-1, 1), (-1, -1)):
            c = np.roll(np.roll(cov, dy, 0), dx, 1)
            acc += np.roll(np.roll(a, dy, 0), dx, 1) * c[..., None]
            cnt += c
        grow = (~cov) & (cnt > 0)
        a[grow] = acc[grow] / cnt[grow][:, None]
        cov |= grow
    return a


def bake_set(items, samples=32, pad=6):
    """bake.bake_set's way, but with no margin while baking: Blender bakes the finds one after
    another and each one's margin painted over its neighbours' island edges (the teddy's small
    islands came out chrome). A coverage pass says which texels are islands; the gutter is padded
    afterwards from each island's own edge."""
    bake.gpu_cycles(samples)
    bpy.context.scene.render.bake.margin = 0
    for ob, r in items:
        ob.data.materials.clear()
        ob.data.materials.append(r.mat)
    bpy.ops.object.select_all(action="DESELECT")
    for ob, _ in items:
        ob.hide_render = False
        ob.select_set(True)
    bpy.context.view_layer.objects.active = items[0][0]
    rigs = [r for _, r in items]
    res = {}
    for k in ("cover", "col", "rough", "metal", "normal"):
        img = bpy.data.images.new(f"{K.SET}_{k}", K.TEX, K.TEX, alpha=True, float_buffer=True)
        img.colorspace_settings.name = "Non-Color"
        img.generated_color = (0.5, 0.5, 1.0, 1.0) if k == "normal" else (0, 0, 0, 1)
        for r in rigs:
            if k == "cover":
                r.nb.links.new(r.nb.val(1.0), r.emit.inputs["Color"])
                r.nb.links.new(r.emit.outputs[0], r.out.inputs["Surface"])
            else:
                r.channel(k)
            r.target(img)
        kind = "NORMAL" if k == "normal" else "EMIT"
        bpy.ops.object.bake(type=kind, normal_space="TANGENT", margin=0, use_clear=False)
        res[k] = bake.pixels(img)
    covered = res.pop("cover")[..., 0] > 0.5
    bake.write_png(os.path.join(OUT, "cover.png"), bake.q8(covered.astype(np.float32)))
    print(f"atlas: faces on unpainted texels {unpainted({ob.name: ob for ob, _ in items})}")
    for k in res:
        res[k] = dilate(res[k], covered, pad)
    os.makedirs(TEX, exist_ok=True)
    out = lambda k: os.path.join(TEX, f"{K.SET}_{k}.png")  # noqa: E731
    bake.write_png(out("Color"), bake.q8(bake.to_srgb(res["col"][..., :3])))
    bake.write_png(out("Normal"), bake.q8(res["normal"][..., :3]))
    bake.write_png(out("Roughness"), bake.q8(res["rough"][..., 0]))
    bake.write_png(out("Metalness"), bake.q8(res["metal"][..., 0]))
    print("BAKED", K.SET, f"{covered.mean():.0%} of the atlas is islands")


def stage_textures():
    reset()
    objs, _ = build_all(baking=True)
    for i, ob in enumerate(objs.values()):
        ob.location.x = i * 4.0
    bake_set([(ob, rig(name)) for name, ob in objs.items()])


# --- export ---------------------------------------------------------------------------------

def material():
    if K.SET in bpy.data.materials:
        return bpy.data.materials[K.SET]
    mat = bpy.data.materials.new(K.SET)
    nb = NB(mat)
    p = lambda k: os.path.join(TEX, f"{K.SET}_{k}.png")  # noqa: E731
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
    objs, sizes = build_all(baking=False)
    mat = material()
    rows = {}
    for i, (name, ob) in enumerate(objs.items()):
        ob.data.materials.append(mat)
        ob.location.x = i * 4.0
        s = sizes[name]
        rows[name] = dict(size=(s.x, s.z, s.y), tris=tris(ob))
    os.makedirs(OUT, exist_ok=True)
    bpy.ops.object.select_all(action="DESELECT")
    for ob in objs.values():
        ob.select_set(True)
    bpy.context.view_layer.objects.active = objs["Boombox"]
    bpy.ops.export_scene.fbx(
        filepath=FBX, use_selection=True, object_types={"MESH"},
        apply_scale_options="FBX_SCALE_UNITS", axis_forward="Z", axis_up="Y",
        use_mesh_modifiers=True, mesh_smooth_type="OFF", use_tspace=False,
        add_leaf_bones=False, bake_anim=False, path_mode="COPY", embed_textures=True)
    print("FBX", FBX, {n: r["tris"] for n, r in rows.items()})
    K.write_luau(os.path.join(K.ROOT, "src", "shared", "Finds", "Specs.luau"), rows)


# --- look sheets ----------------------------------------------------------------------------

def boxes_kit():
    """The boxes' own build module, for the look sheets' unit and its boxes."""
    mine = sys.modules.pop("spec")
    sys.path.insert(0, BOXES)
    try:
        s = importlib.util.spec_from_file_location("boxes_build", os.path.join(BOXES, "build.py"))
        mod = importlib.util.module_from_spec(s)
        s.loader.exec_module(mod)
    finally:
        sys.modules["boxes_spec"] = sys.modules.pop("spec", None)
        sys.modules["spec"] = mine
    return mod


def put(ob, x, y, z=0.0, turn=0.0):
    ob.location = (x, y, z)
    ob.rotation_euler = (0.0, 0.0, math.radians(turn))
    return ob


def stage_renders():
    reset()
    render.setup(96, (1600, 900))
    objs, _ = build_all(baking=False)
    mat = material()
    for ob in objs.values():
        ob.data.materials.append(mat)
    os.makedirs(SHEETS, exist_ok=True)

    # 1. the line-up and two close looks, in the studio
    studio = render.studio_rig()
    for o in studio:
        o.hide_render = False
    put(objs["Boombox"], -2.7, 0.2, 0.0, 14)
    put(objs["Television"], -0.35, 0.3, 0.0, -8)
    put(objs["Teddy"], 1.45, 0.0, 0.0, -16)
    put(objs["Skates"], 3.1, 0.0, 0.0, -22)
    cam = render.camera((0.1, -8.6, 3.0), (0.1, 0.0, 0.62), lens=40)
    render.shoot(cam, os.path.join(SHEETS, "finds-lineup.png"), exposure=-0.1)
    cam = render.camera((-2.0, -2.9, 1.7), (-1.55, 0.2, 0.7), lens=40)
    render.shoot(cam, os.path.join(SHEETS, "finds-close-a.png"), exposure=-0.1)
    cam = render.camera((2.6, -2.6, 1.5), (2.25, 0.0, 0.55), lens=40)
    render.shoot(cam, os.path.join(SHEETS, "finds-close-b.png"), exposure=-0.1)
    for o in studio:
        o.hide_render = True

    # 2. among the boxes at the back of an open unit, under its bulb, seen from the doorway
    kit = boxes_kit()
    bmat = kit.material(False)
    boxes, _, _ = kit.build_all(baking=False)
    for ob in boxes.values():
        ob.data.materials.append(bmat)
    render.world((0.003, 0.004, 0.006), 1.0)
    kit.unit_room(bpy.context.scene.collection)
    kit.place(boxes, "Wardrobe", -4.4, 10.6, 0.0, 6)
    kit.place(boxes, "Large", -1.9, 10.9, 0.0, -3)
    kit.place(boxes, "Medium", -1.85, 10.85, 2.4, 9)
    kit.place(boxes, "Large", 2.4, 10.8, 0.0, 4, copy=True)
    kit.place(boxes, "Medium", 0.3, 10.9, 0.0, -2, copy=True)
    kit.place(boxes, "Open", 4.0, 7.9, 0.0, 28)
    kit.place(boxes, "Small", -3.9, 8.0, 0.0, 64)
    put(objs["Television"], 0.35, 10.75, 1.6, -8)
    put(objs["Boombox"], 2.3, 10.7, 2.4, 6)
    put(objs["Teddy"], -1.9, 10.6, 4.0, 16)
    put(objs["Skates"], -0.9, 7.2, 0.0, 34)
    bulb = bpy.data.lights.new("bulb", "POINT")
    bulb.energy = 220.0
    bulb.color = (1.0, 0.674, 0.408)
    bulb.shadow_soft_size = 0.08
    bo = bpy.data.objects.new("bulb", bulb)
    bpy.context.scene.collection.objects.link(bo)
    bo.location = (0.0, 6.0, 8.7)
    hall = kit.light("hall", "AREA", (0.0, -3.0, 9.0), (0.0, 3.0, 0.0), 90.0, (0.85, 0.92, 1.0), size=6.0)
    cam = render.camera((1.1, -2.2, 4.5), (-0.3, 9.0, 1.4), lens=26)
    render.shoot(cam, os.path.join(SHEETS, "finds-unit.png"), exposure=0.2)
    hall.hide_render = True


STAGES = {"textures": stage_textures, "export": stage_export, "renders": stage_renders}

if __name__ == "__main__":
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    ap = argparse.ArgumentParser()
    ap.add_argument("--stage", choices=list(STAGES), required=True)
    STAGES[ap.parse_args(argv).stage]()
    print("DONE")
