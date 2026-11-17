"""The home's furnishings (S5-03a2b2, D-266), each its own part on its own origin: the middle of
its footprint on the floor, its front toward -y (home_spec.py).

    Pot, Plant                  a snake plant in a cream pot (Plaster; Leaf: leaves and soil)
    Bench                       an oak bench with a back, for the walls between the doors (Wood)
    Planter, PlanterSeat,       the islands: a square planter you sit round on an oak seat, snake
    PlanterPlants               plants growing out of it (Plaster, Wood, Leaf)
    Rug                         the starter rug (Rug)
    Beanbag                     the starter beanbag, slumped, a dent where you sit (Fabric)
    FloorLamp, LampShade        the starter floor lamp: an oak stem, a fabric drum shade (Wood,
                                Fabric; the game lights it)
"""

import math
import random

from mathutils import Vector

from carpentry import plaster_uv, wood_box, wood_uv
import geo
from geo import Mesh
import home_spec as K

LEAF_V = 0.14   # the Leaf set: leaves above this V, four columns across; soil below SOIL_V
SOIL_V = 0.12


def soil_uv(cx, cy, r):
    """A disc or square of soil (half-width r round cx, cy) onto the Leaf set's soil band."""
    def f(vs, n):
        return [(0.02 + 0.96 * (v[0] - cx + r) / (2 * r),
                 0.005 + (SOIL_V - 0.01) * (v[1] - cy + r) / (2 * r)) for v in vs]
    return f


def leaf(m, base, yaw, lean, length, width, column, twist):
    """One sword leaf from `base`, leaning out toward `yaw` by `lean` (radians) toward its tip,
    cupped down its middle, twisting as it rises, both faces built (it's seen from all round)."""
    rows = (0.0, 0.12, 0.3, 0.5, 0.68, 0.84, 0.94)
    out = Vector((math.cos(yaw), math.sin(yaw), 0.0))
    up = Vector((0.0, 0.0, 1.0))
    front, back = [], []
    for t in rows + (1.0,):
        c = Vector(base) + out * (length * math.sin(lean) * t ** 1.6) + up * (length * math.cos(lean) * t)
        if t < 1.0:
            a_yaw = yaw + math.pi / 2 + twist * t
            across = Vector((math.cos(a_yaw), math.sin(a_yaw), 0.0))
            tan = (out * (1.6 * math.sin(lean) * max(t, 0.05) ** 0.6) + up * math.cos(lean)).normalized()
            nrm = across.cross(tan).normalized()
            w = width * (0.5 + 0.5 * math.sin(math.pi * t * 0.9)) * (1.0 - t ** 3)
            pts = [c - across * (w / 2), c - nrm * (0.16 * w), c + across * (w / 2)]
        else:
            pts = [c]
            nrm = Vector((0, 0, 0))
        front.append((pts, nrm, t))
    u = lambda sx: (column + 0.02 + 0.96 * sx) / 4.0
    v = lambda t: LEAF_V + (1.0 - LEAF_V) * t
    for side in (1, -1):
        idx = []
        for pts, nrm, t in front:
            idx.append([m.vert(p - nrm * (0.004 if side < 0 else 0.0)) for p in pts])
        for r in range(len(idx) - 1):
            a, b = idx[r], idx[r + 1]
            ta, tb = front[r][2], front[r + 1][2]
            if len(b) == 3:
                for k in range(2):
                    q = [a[k], a[k + 1], b[k + 1], b[k]]
                    uv = [(u(k / 2), v(ta)), (u((k + 1) / 2), v(ta)), (u((k + 1) / 2), v(tb)), (u(k / 2), v(tb))]
                    if side < 0:
                        q, uv = q[::-1], uv[::-1]
                    m.face(q, uv, True)
            else:
                for k in range(2):
                    q = [a[k], a[k + 1], b[0]]
                    uv = [(u(k / 2), v(ta)), (u((k + 1) / 2), v(ta)), (u(0.5), v(tb))]
                    if side < 0:
                        q, uv = q[::-1], uv[::-1]
                    m.face(q, uv, True)


def clump(m, cx, cy, z, n, shortest, longest, width, seed):
    """A snake plant's rosette: n leaves from a small circle, the inner ones tallest and most
    upright, each turned a golden angle from the last."""
    rng = random.Random(seed)
    for i in range(n):
        f = i / max(n - 1, 1)
        yaw = i * 2.39996 + rng.uniform(-0.3, 0.3)
        r = 0.08 + 0.26 * f
        base = (cx + r * math.cos(yaw), cy + r * math.sin(yaw), z - 0.05)
        length = longest - (longest - shortest) * f * rng.uniform(0.75, 1.0)
        lean = math.radians(4.0 + 20.0 * f + rng.uniform(-3.0, 3.0))
        leaf(m, base, yaw, lean, length, width * rng.uniform(0.85, 1.05), (i + seed) % 4,
             rng.uniform(-0.5, 0.5))


def pot():
    """A cream pot, tapering to its foot, with a rolled rim."""
    m = Mesh("Pot")
    rt, rf, h = K.POT
    ro, ri, rh = K.POT_RIM
    pu = plaster_uv(2.0)
    body = h - rh
    geo.cylinder(m, "z", (0.0, 0.0, body / 2), rf, body, segs=20, mapper=pu, radius2=rt)
    geo.ring_plate(m, (0.0, 0.0, h - rh / 2), "z", ro, ri, rh, segs=20, mapper=pu)
    return m


def plant():
    """The pot's snake plant: its soil a little under the rim, nine leaves rising out of it."""
    m = Mesh("Plant")
    _, _, h = K.POT
    ro, ri, rh = K.POT_RIM
    z = h - rh - 0.0
    n, shortest, longest, width = K.PLANT
    geo.cylinder(m, "z", (0.0, 0.0, z + 0.02), ri + 0.01, 0.04, segs=16, mapper=soil_uv(0, 0, ri),
                 smooth=False)
    clump(m, 0.0, 0.0, z + 0.04, n, shortest, longest, width, seed=7)
    return m


def bench():
    """An oak bench with a back: three seat slats on two leg frames, the back legs rising into
    posts that carry two back rails. Against a wall, its back to it."""
    m = Mesh("Bench")
    L, D, seat, top = K.BENCH
    lx, fy, by = L / 2 - 0.35, -D / 2 + 0.1, D / 2 - 0.2  # leg middles: across, front, back
    st = 0.14
    for k in range(3):  # seat slats, front to back
        y0 = -D / 2 + k * 0.5
        wood_box(m, (-L / 2, y0, seat - st), (L / 2, y0 + 0.44, seat), 2 + k, bevel=0.025)
    for sx in (-1, 1):
        x0, x1 = sx * lx - 0.11, sx * lx + 0.11
        wood_box(m, (x0, fy - 0.11, 0.0), (x1, fy + 0.11, seat - st), 6)          # front leg
        wood_box(m, (x0, by - 0.11, 0.0), (x1, by + 0.11, top), 6, bevel=0.02)    # back leg and post
        wood_box(m, (x0 + 0.02, fy, seat - st - 0.26), (x1 - 0.02, by, seat - st), 7)  # side rail
        wood_box(m, (x0 + 0.03, fy, 0.35), (x1 - 0.03, by, 0.52), 7)               # stretcher
    wood_box(m, (-lx, fy - 0.1, seat - st - 0.24), (lx, fy + 0.02, seat - st), 8)  # front apron
    wood_box(m, (-lx, by - 0.02, seat - st - 0.24), (lx, by + 0.1, seat - st), 8)  # back apron
    for z0, z1 in ((top - 1.05, top - 0.65), (top - 0.45, top - 0.02)):  # back rails
        wood_box(m, (-(lx + 0.2), by - 0.17, z0), (lx + 0.2, by - 0.05, z1), 9, bevel=0.02)
    return m


def planter():
    """The islands' square planter: plaster walls, a shallow plinth recess at the foot."""
    m = Mesh("Planter")
    S, h, _, _ = K.PLANTER
    pu = plaster_uv()
    a = S / 2 - 0.05
    geo.box(m, (-a + 0.08, -a + 0.08, 0.0), (a - 0.08, a - 0.08, 0.18), pu)  # the recess
    geo.box(m, (-a, -a, 0.18), (a, a, h), pu)
    return m


def planter_seat():
    """The oak seat round the planter's top, overhanging a little: four boards, mitred square."""
    m = Mesh("PlanterSeat")
    S, h, d, t = K.PLANTER
    o = S / 2 + 0.12
    i = o - d
    for sy in (-1, 1):  # front and back boards run the full width
        y0, y1 = sorted((sy * o, sy * i))
        wood_box(m, (-o, y0, h), (o, y1, h + t), 2 + (sy > 0), bevel=0.03)
    for sx in (-1, 1):
        x0, x1 = sorted((sx * o, sx * i))
        wood_box(m, (x0, -i, h), (x1, i, h + t), 4 + (sx > 0), bevel=0.03)
    return m


def planter_plants():
    """The planter's soil, just under the seat, and five snake plants in it, taller than a pot's."""
    m = Mesh("PlanterPlants")
    S, h, d, t = K.PLANTER
    r = S / 2 + 0.12 - d + 0.02
    geo.box(m, (-r, -r, h - 0.1), (r, r, h + 0.02), soil_uv(0, 0, r))
    for k, (x, y) in enumerate(K.PLANTER_CLUMPS):
        tall = 1.0 if k == 0 else 0.82
        clump(m, x, y, h + 0.02, 10 if k == 0 else 8, 2.6 * tall, 4.4 * tall, 0.5, seed=11 + k)
    return m


def rug():
    """The starter rug: the whole rug on the Rug map, its edges the border's colour."""
    m = Mesh("Rug")
    w, d, t = K.RUG
    def uv(vs, n):
        if abs(n.z) > 0.7:
            return [((v.x + w / 2) / w, (v.y + d / 2) / d) for v in vs]
        return [(0.5, 0.004) for _ in vs]  # the sides: the border's terracotta at the rug's edge
    geo.box(m, (-w / 2, -d / 2, 0.005), (w / 2, d / 2, 0.005 + t), uv)
    return m


def fabric_uv(tile=2.0):
    """Fabric round a soft body: the angle round z unrolled (no seam jump), height up it."""
    def f(vs, n):
        angs = [math.atan2(v.y, v.x) for v in vs]
        if max(angs) - min(angs) > math.pi:
            angs = [a + 2 * math.pi if a < 0 else a for a in angs]
        r = max(math.hypot(v.x, v.y) for v in vs)
        return [(a * 1.5 / tile, v.z / tile + 0.1 * r) for a, v in zip(angs, vs)]
    return f


def beanbag():
    """The starter beanbag: a sphere slumped onto the floor, its back standing higher, a dent
    where you sit, its sides bulging at the foot."""
    m = Mesh("Beanbag")
    W, D, H = K.BEANBAG
    segs, rings = 18, 11
    pts = []
    for j in range(rings + 1):
        ph = math.pi * j / rings  # 0 at the top
        for i in range(segs):
            th = 2 * math.pi * i / segs
            x, y, z = math.sin(ph) * math.cos(th), math.sin(ph) * math.sin(th), math.cos(ph)
            if z < -0.4:
                z = -0.4 + (z + 0.4) * 0.12  # flattened on the floor
            bulge = 1.0 + 0.16 * math.exp(-((z + 0.3) / 0.35) ** 2)
            x, y = x * bulge, y * bulge
            if z > 0:
                z *= 0.78 + 0.3 * max(y, 0.0)  # the back stands higher than the front
                z -= 0.42 * z * math.exp(-((x / 0.55) ** 2 + ((y + 0.12) / 0.5) ** 2))  # the seat
            pts.append(Vector((x, y, z)))
    lo = Vector([min(p[k] for p in pts) for k in range(3)])
    hi = Vector([max(p[k] for p in pts) for k in range(3)])
    size = hi - lo
    pts = [Vector(((p.x - (lo.x + hi.x) / 2) * W / size.x, (p.y - (lo.y + hi.y) / 2) * D / size.y,
                   (p.z - lo.z) * H / size.z)) for p in pts]
    base = len(m.verts)
    for p in pts:
        m.vert(p)
    idx = lambda j, i: base + j * segs + (i % segs)
    mp = fabric_uv()
    for j in range(rings):
        for i in range(segs):
            q = [idx(j, i), idx(j + 1, i), idx(j + 1, i + 1), idx(j, i + 1)]
            if j == 0:
                q = [idx(0, i), idx(1, i), idx(1, i + 1)]
            elif j == rings - 1:
                q = [idx(j, i), idx(j + 1, i), idx(j, i + 1)]
            vs = [m.verts[k] for k in q]
            m.face(q, mp(vs, geo._normal(vs)), True)
    return m


def floor_lamp():
    """The floor lamp's oak: a turned base, a slim stem, the collar the shade sits on."""
    m = Mesh("FloorLamp")
    rb, stem, _, _, _ = K.FLOOR_LAMP
    geo.cylinder(m, "z", (0.0, 0.0, 0.07), rb, 0.14, segs=20, bevel=0.03,
                 mapper=wood_uv(0, (-rb, -rb, 0), (rb, rb, 0.14), 6))
    geo.cylinder(m, "z", (0.0, 0.0, 0.18), rb * 0.45, 0.1, segs=14,
                 mapper=wood_uv(0, (-rb, -rb, 0), (rb, rb, 0.2), 6))
    geo.cylinder(m, "z", (0.0, 0.0, stem / 2), 0.07, stem, segs=10,
                 mapper=wood_uv(2, (-0.07, -0.07, 0), (0.07, 0.07, stem), 7))
    geo.cylinder(m, "z", (0.0, 0.0, stem - 0.1), 0.13, 0.2, segs=12,
                 mapper=wood_uv(2, (-0.13, -0.13, stem - 0.2), (0.13, 0.13, stem), 7))
    return m


def lamp_shade():
    """A drum shade, open top and bottom, its cloth seen inside and out."""
    m = Mesh("LampShade")
    _, stem, r0, r1, h = K.FLOOR_LAMP
    z0, z1 = stem - K.SHADE_GAP, stem - K.SHADE_GAP + h
    segs, t = 24, 0.03
    mp = fabric_uv(1.0)
    rings = []
    for r, z in ((r0, z0), (r1, z1), (r1 - t, z1), (r0 - t, z0)):  # out-foot, out-top, in-top, in-foot
        rings.append([m.vert((r * math.cos(2 * math.pi * i / segs), r * math.sin(2 * math.pi * i / segs), z))
                      for i in range(segs)])
    for a, b in ((0, 1), (1, 2), (2, 3), (3, 0)):  # outside, top rim, inside, foot rim
        for i in range(segs):
            j = (i + 1) % segs
            q = [rings[a][i], rings[a][j], rings[b][j], rings[b][i]]
            vs = [m.verts[k] for k in q]
            m.face(q, mp(vs, geo._normal(vs)), a in (0, 2))
    return m


BUILDERS = {"Pot": pot, "Plant": plant, "Bench": bench, "Planter": planter,
            "PlanterSeat": planter_seat, "PlanterPlants": planter_plants, "Rug": rug,
            "Beanbag": beanbag, "FloorLamp": floor_lamp, "LampShade": lamp_shade}


def shelf():
    """The shelf's oak (D-284): two ends on short legs, a board under each row and one on top,
    the uprights between the cubbies, a rail along the top's back. Its front toward -y."""
    m = Mesh("Shelf")
    cols, rows, w, h, d, t, legs = K.SHELF
    width = cols * w + (cols + 1) * t
    top = legs + rows * (h + t) + t
    x0, x1, y0, y1 = -width / 2, width / 2, -d / 2, d / 2
    for sx in (-1, 1):  # the two ends, floor to top, and their feet set back from the front
        a, b = (x0, x0 + t) if sx < 0 else (x1 - t, x1)
        wood_box(m, (a, y0, legs), (b, y1, top), 3, bevel=0.02)
        wood_box(m, (a, y0 + 0.08, 0.0), (b, y0 + 0.3, legs), 5)
        wood_box(m, (a, y1 - 0.3, 0.0), (b, y1 - 0.08, legs), 5)
    wood_box(m, (x0 + t, y0 + 0.12, legs - 0.2), (x1 - t, y0 + 0.24, legs), 8)  # the kick rail
    for r in range(rows + 1):  # boards: under each row, and the top
        z = legs + r * (h + t)
        wood_box(m, (x0 + t, y0, z), (x1 - t, y1 - K.SHELF_BACK, z + t), 2 + r, bevel=0.015)
    for c in range(1, cols):  # the uprights between cubbies
        x = x0 + t + c * w + (c - 1) * t
        for r in range(rows):
            z = legs + t + r * (h + t)
            wood_box(m, (x, y0 + 0.04, z), (x + t, y1 - K.SHELF_BACK, z + h), 6 + c)
    wood_box(m, (x0 + 0.04, y1 - 0.2, top), (x1 - 0.04, y1, top + 0.22), 9, bevel=0.02)  # top rail
    return m


def shelf_back():
    """The shelf's back, painted the units' cream, between its ends from the bottom board up."""
    m = Mesh("ShelfBack")
    cols, rows, w, h, d, t, legs = K.SHELF
    width = cols * w + (cols + 1) * t
    top = legs + rows * (h + t) + t
    geo.box(m, (-width / 2 + t, d / 2 - K.SHELF_BACK, legs), (width / 2 - t, d / 2, top),
            plaster_uv())
    return m


BUILDERS.update({"Shelf": shelf, "ShelfBack": shelf_back})

TEXSET = {"Pot": "Plaster", "Plant": "Leaf", "Bench": "Wood", "Planter": "Plaster",
          "PlanterSeat": "Wood", "PlanterPlants": "Leaf", "Rug": "Rug", "Beanbag": "Fabric",
          "FloorLamp": "Wood", "LampShade": "Fabric", "Shelf": "Wood", "ShelfBack": "Plaster"}


def meshes():
    return {name: fn() for name, fn in BUILDERS.items()}
