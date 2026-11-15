"""The Figures and models set (art/finds/figures/README.md), built with the finds kit.

    scripts/art.sh set figures [textures|export|renders|quick] [FindName]
"""

import math
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "kit"))
sys.path.insert(0, HERE)

import bmesh  # noqa: E402
from mathutils import Matrix, Vector  # noqa: E402

import kit  # noqa: E402
import spec as K  # noqa: E402
from look import Coat, hexc  # noqa: E402
from shapes import Shape, fillet, helix  # noqa: E402

mm = K.mm

# What a face is, for the looks.
(SHELL, WING, NYLON, PLATE, GOLD, CHROME, SPRING, TYRE, RIM, CAN, BELL, BATT, STEEL, AERIAL,
 CAP, TX, TXFACE, FOAM, ANT, LED, FLAG, WIRE, CLIP) = range(23)


def segs(hi, n):
    return n * 2 if hi else n


def V(x, y, z):
    return Vector((mm(x), mm(y), mm(z)))


def T(v):
    return Matrix.Translation(v)


def prism(s, pts, z0, z1, kind, M=Matrix(), bevel=0.0):
    """A convex outline [(x, y)] (mm, anticlockwise from above) from z0 to z1, placed by M."""
    bm = bmesh.new()
    lo = [bm.verts.new((mm(x), mm(y), mm(z0))) for x, y in pts]
    up = [bm.verts.new((mm(x), mm(y), mm(z1))) for x, y in pts]
    n = len(pts)
    bm.faces.new(list(reversed(lo)))
    bm.faces.new(up)
    for i in range(n):
        j = (i + 1) % n
        bm.faces.new((lo[i], lo[j], up[j], up[i]))
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    if bevel > 0:
        bmesh.ops.bevel(bm, geom=list(bm.edges), offset=mm(bevel), segments=2, profile=0.5,
                        affect="EDGES", clamp_overlap=True)
    bmesh.ops.transform(bm, matrix=M, verts=bm.verts)
    s.merge(bm, kind)
    bm.free()


def bar(s, a, b, w, h, kind, hi, up=(0, 0, 1)):
    """A box from a to b (mm points), w wide and h tall, its edges eased."""
    a, b = V(*a), V(*b)
    d = b - a
    L = d.length
    f = d.normalized()
    u = Vector(up)
    r = f.cross(u).normalized()
    u = r.cross(f).normalized()
    R = Matrix((r, f, u)).transposed().to_4x4()
    M = T((a + b) / 2) @ R
    c = min(mm(w), mm(h)) * 0.18
    s.box((-mm(w) / 2, -L / 2, -mm(h) / 2), (mm(w) / 2, L / 2, mm(h) / 2), kind,
          c if hi else c * 0.6, 2 if hi else 1, M)


def rod(s, a, b, r, kind, hi, sides=10):
    s.cylinder(V(*a), V(*b), mm(r), kind, segs(hi, sides))


def ball(s, c, r, kind, hi):
    n = 8 if hi else 4
    prof = [(mm(r) * math.sin(math.pi * i / n), -mm(r) * math.cos(math.pi * i / n))
            for i in range(n + 1)]
    prof[0], prof[-1] = (0.0, prof[0][1]), (0.0, prof[-1][1])
    s.lathe(prof, kind, segs(hi, 10), T(V(*c)))


# --- the car: where things are ------------------------------------------------------------------

C = K.RC
WB, TF, TR = C["wheelbase"], C["track_f"], C["track_r"]
TYF, TYR = C["tyre_f"], C["tyre_r"]
YF, YR = -WB / 2, WB / 2
ZF, ZR = TYF["od"] / 2, TYR["od"] / 2
CAST = math.radians(C["caster"])
KING_IN = 21.0                      # the kingpin, inboard of the front wheel's middle
KING_AXIS = (0.0, math.sin(CAST), math.cos(CAST))


def wheel_at(side, front):
    return V(side * (TF if front else TR) / 2, YF if front else YR, ZF if front else ZR)


def king_at(side):
    return V(side * (TF / 2 - KING_IN), YF, ZF)


AER = C["aerial"]
AER_BASE = V(*AER["at"])
AER_JOINT = AER_BASE + V(0, 0, AER["length"] * AER["joint"])
ROLL_C = V(0, 0, 55.0)              # where the chassis pitches and rolls on its springs


# --- wheels and tyres ---------------------------------------------------------------------------

def tyre_profile(t, hi, ribs=0):
    """Bead to bead over the tread, outside first (lathe about Z, the axle; z across the tread)."""
    R, w, rb = t["od"] / 2, t["w"], t["rim"] / 2 + 1.5
    sh = 6.0                         # the shoulder's round
    f = 3 if hi else 2
    p = [(rb, -w / 2 + 1.0), (rb + 3.0, -w / 2)]
    p += [(R - sh - 6.0, -w / 2 - 0.6)]
    p += fillet(R - sh, -w / 2 + sh, sh, (-90, 0), f + 1)[1:]
    if ribs:
        k = ribs * 2 + 1
        span = w - 2 * sh
        for i in range(1, k):
            z = -w / 2 + sh + span * i / k
            d = 2.4 if i % 2 else 0.0
            p += [(R - d, z - 0.8), (R - d, z + 0.8)] if d else [(R, z)]
    p += fillet(R - sh, w / 2 - sh, sh, (0, 90), f + 1)
    p += [(R - sh - 6.0, w / 2 + 0.6), (rb + 3.0, w / 2), (rb, w / 2 - 1.0)]
    return [(mm(r), mm(z)) for r, z in p]


def wheel_frame(side, front):
    """The wheel's own frame: lathe Z along the axle, pointing out of the car."""
    return T(wheel_at(side, front)) @ Matrix.Rotation(math.radians(90 * side), 4, "Y")


def rim(s, t, M, hi):
    w, rr = t["w"] - 2.0, t["rim"] / 2
    f = 2 if hi else 1
    p = [(0.0, -w / 2 + 3.0), (rr - 4.0, -w / 2 + 2.0), (rr - 2.0, -w / 2)]
    p += [(rr - 1.0, w / 2 - 2.0)]
    p += fillet(rr + 1.0, w / 2 - 1.0, 1.4, (-90, 90), 3 * f)[1:]
    p += [(rr - 3.5, w / 2 - 0.4), (rr - 7.0, w / 2 - 4.5), (13.0, w / 2 - 6.0),
          (10.0, w / 2 - 4.0), (7.0, w / 2 - 3.0), (0.0, w / 2 - 3.0)]
    s.lathe([(mm(r), mm(z)) for r, z in p], RIM, segs(hi, 28), M)
    # the hex nut and the axle's end
    s.cylinder(M @ V(0, 0, w / 2 - 3.5), M @ V(0, 0, w / 2 + 1.5), mm(4.6), STEEL, 6)
    s.cylinder(M @ V(0, 0, w / 2), M @ V(0, 0, w / 2 + 2.6), mm(2.0), STEEL, segs(hi, 6))


def sidewall_marks(s, t, M, R0, R1):
    """Moulded lettering on the outer sidewall, one arc of it: you see the wheel turn."""
    w = t["w"]
    a = -0.5
    for i, wd in enumerate((5, 3, 6, 4, 4, 7, 3, 5, 6, 4, 5)):
        span = wd / ((R0 + R1) / 2)
        Mi = M @ Matrix.Rotation(a + span / 2, 4, "Z")
        s.box((mm(R0), -mm(wd) / 2 * 0.9, mm(w / 2 - 1.2)), (mm(R1), mm(wd) / 2 * 0.9, mm(w / 2 + 0.9)),
              TYRE, mm(0.3), 1, Mi)
        a += span + 1.6 / ((R0 + R1) / 2)


def wheel(side, front):
    t = TYF if front else TYR

    def build(hi):
        s = Shape()
        M = wheel_frame(side, front)
        s.lathe(tyre_profile(t, hi, t.get("ribs", 0) if front else 0), TYRE, segs(hi, 40), M)
        rim(s, t, M, hi)
        if hi:
            sidewall_marks(s, t, M, t["rim"] / 2 + 6.0, t["rim"] / 2 + 10.5)
            if not front:
                rows, n = t["pins"]
                R, w = t["od"] / 2, t["w"]
                for j in range(n):
                    a = 2 * math.pi * (j + 0.5 * (j % 2)) / n
                    Mj = M @ Matrix.Rotation(a, 4, "Z")
                    for k in range(rows):
                        z = -w / 2 + 7.0 + (w - 14.0) * k / (rows - 1)
                        s.box((mm(R - 0.5), -mm(2.1), mm(z - 2.1)), (mm(R + 2.6), mm(2.1), mm(z + 2.1)),
                              TYRE, mm(0.5), 1, Mj)
        if not front:
            # the dogbone from the gearbox's outdrive to the wheel, and the outdrive's cup
            gx = C["gearbox"]["w"] + 6.0
            hub = wheel_at(side, False)
            od = V(side * gx, YR, ZR)
            s.cylinder(od - V(side * 4, 0, 0), od + V(side * 6, 0, 0), mm(7.0), STEEL, segs(hi, 12))
            s.cylinder(od, hub - V(side * 22, 0, 0), mm(2.6), STEEL, segs(hi, 8))
        return s
    return build


# --- the steering knuckles (they turn on the kingpins) ------------------------------------------

def knuckle(side):
    def build(hi):
        s = Shape()
        k = king_at(side)
        R = Matrix.Rotation(-CAST, 4, "X")
        # the knuckle's body round the kingpin, the stub axle out to the wheel
        s.box((-mm(6), -mm(6), -mm(9)), (mm(6), mm(6), mm(9)), NYLON, mm(1.2), 2 if hi else 1,
              T(k) @ R)
        s.cylinder(k, wheel_at(side, True) + V(side * 2, 0, 0), mm(2.5), STEEL, segs(hi, 8))
        s.cylinder(k + V(side * 6, 0, 0), k + V(side * 10, 0, 0), mm(5.5), STEEL, segs(hi, 12))
        # the steering arm back to the tie rod's ball
        arm_end = k + V(-side * 3, C["steer_arm"], 2)
        bar(s, tuple(v * K.STUD_MM for v in k + V(0, 3, 2)), tuple(v * K.STUD_MM for v in arm_end),
            5, 4, NYLON, hi)
        ball(s, tuple(v * K.STUD_MM for v in arm_end + V(0, 0, 3)), 3.0, STEEL, hi)
        return s
    return build


# --- the unsprung frame: lower arms, hubs, links (it travels; the chassis leans on it) -----------

def arms(hi):
    s = Shape()
    af, ar = C["arm_f"], C["arm_r"]
    for side in (-1, 1):
        # front lower arm: two legs from the bulkhead's hinge pins to the C-hub, a boss each end
        ox, oz = af["outer"]
        ix, iz = af["inner"]
        outer = (side * ox, YF, oz)
        for y in (af["y0"], af["y1"]):
            bar(s, (side * ix, y, iz), outer, 8, af["t"], NYLON, hi)
            rod(s, (side * ix, y - 4, iz), (side * ix, y + 4, iz), 4.5, NYLON, hi)
        rod(s, (side * ix, af["y0"] - 6, iz), (side * ix, af["y1"] + 6, iz), 1.6, STEEL, hi, 6)
        bar(s, (side * (ix + 14), af["y0"] + 8, iz + 2), (side * (ix + 14), af["y1"] - 8, iz + 2),
            4, 4, NYLON, hi)
        # the shock's lower mount on the arm
        sb = C["shock_f"]["bottom"]
        bar(s, (side * sb[0], sb[1] - 6, sb[2] - 3), (side * sb[0], sb[1] + 6, sb[2] - 3), 6, 6, NYLON, hi)
        # the C-hub (caster block): ears above and below the knuckle, its back to the arm
        k = king_at(side) * K.STUD_MM
        R = Matrix.Rotation(-CAST, 4, "X")
        for dz in (-13.0, 13.0):
            s.box((-mm(7), -mm(7), -mm(2.5)), (mm(7), mm(7), mm(2.5)), NYLON, mm(0.8), 2 if hi else 1,
                  T(V(*k)) @ R @ T(V(0, 0, dz)))
        s.box((-mm(4), -mm(7), -mm(16)), (mm(4), mm(7), mm(16)), NYLON, mm(0.8), 2 if hi else 1,
              T(V(k[0] - side * 9, k[1], k[2])) @ R)
        rod(s, (k[0], k[1] - 2.5, k[2] - 17), (k[0], k[1] + 2.5, k[2] + 17), 1.4, STEEL, hi, 6)
        # the front camber link (a turnbuckle, ball ends) from the tower to the C-hub's top
        a, b = (side * 22, -150, 66), (side * (k[0] * side - 9), YF + 2, k[2] + 16)
        rod(s, a, b, 1.6, STEEL, hi, 6)
        for p in (a, b):
            ball(s, p, 3.4, NYLON, hi)
        # the tie rod from the servo saver to the steering arm
        arm_end = king_at(side) * K.STUD_MM + Vector((-side * 3, C["steer_arm"], 5))
        a = (side * 14, -126, 41)
        rod(s, a, tuple(arm_end), 1.5, STEEL, hi, 6)
        ball(s, a, 3.2, NYLON, hi)
        # rear lower arm: wide and flat, ribbed, hinged on the gearbox's pins
        ox, oz = ar["outer"]
        ix, iz = ar["inner"]
        bar(s, (side * ix, YR, iz), (side * ox, YR, oz), ar["y1"] - ar["y0"] - 14, ar["t"] - 3,
            NYLON, hi)
        for y in (ar["y0"], ar["y1"]):
            bar(s, (side * ix, y, iz), (side * ox, YR + (y - YR) * 0.35, oz), 7, ar["t"], NYLON, hi)
        rod(s, (side * ix, ar["y0"] - 3, iz), (side * ix, ar["y1"] + 3, iz), 4.0, NYLON, hi)
        sb = C["shock_r"]["bottom"]
        bar(s, (side * sb[0], sb[1] - 5, sb[2] - 2), (side * sb[0], sb[1] + 5, sb[2] - 2), 7, 6, NYLON, hi)
        # the rear hub carrier, its bearing round the axle, and the rear camber link
        h = wheel_at(side, False) * K.STUD_MM
        s.box((-mm(7), -mm(10), -mm(13)), (mm(7), mm(10), mm(13)), NYLON, mm(1.5), 2 if hi else 1,
              T(V(h[0] - side * 25, h[1], h[2])))
        rod(s, (h[0] - side * 32, h[1], h[2]), (h[0] - side * 18, h[1], h[2]), 6.2, STEEL, hi, 12)
        a, b = (side * 26, 166, 84), (h[0] - side * 25, h[1], h[2] + 15)
        rod(s, a, b, 1.6, STEEL, hi, 6)
        for p in (a, b):
            ball(s, p, 3.4, NYLON, hi)
    return s


# --- the sprung chassis: tub, bulkhead, bumper, towers, gearbox, motor, shocks, radio ------------

def shock(s, top, bottom, r, hi):
    a, b = V(*top), V(*bottom)
    d = (b - a).normalized()
    L = (b - a).length
    body = a + d * L * 0.62
    s.cylinder(a - d * mm(3), body, mm(r), GOLD, segs(hi, 14))
    s.cylinder(a - d * mm(6), a - d * mm(1.5), mm(r + 1.0), GOLD, segs(hi, 14))
    s.cylinder(body, b - d * mm(4), mm(1.6), CHROME, segs(hi, 8))
    s.cylinder(b - d * mm(6), b + d * mm(2), mm(3.4), NYLON, segs(hi, 8))
    s.cylinder(b - d * mm(4), b - d * mm(2.5), mm(r + 1.5), GOLD, segs(hi, 12))
    # the spring, from the collar near the top to the lower cup
    c0, c1 = a + d * mm(8), b - d * mm(5)
    if hi:
        s.tube(helix(c0, c1, mm(r + 1.6), 7.5, 20), mm(1.15), SPRING, 8, caps=False)
    else:
        s.cylinder(c0, c1, mm(r + 1.7), SPRING, 12, caps=False)
    for p in (a, b):
        s.cylinder(p + Vector((-mm(4), 0, 0)), p + Vector((mm(4), 0, 0)), mm(1.6), STEEL, 6)


def tower(s, t, hi):
    """A shock tower cut from graphite plate: two legs up from the bulkhead and a bar across the
    top that the shocks hang from, open between them."""
    M = T(V(0, t["y"], 0)) @ Matrix.Rotation(math.radians(90), 4, "X")
    b, tp, w0, w1, lg = t["bottom"], t["top"], t["w0"], t["w1"], 11.0
    bv = 0.6 if hi else 0.0
    for sd in (-1, 1):
        q = [(sd * (w0 - lg), b), (sd * w0, b), (sd * w1, tp - 14), (sd * (w1 - lg - 4), tp - 14)]
        prism(s, q if sd > 0 else list(reversed(q)), -t["t"] / 2, t["t"] / 2, PLATE, M, bevel=bv)
    prism(s, [(-w1, tp - 15), (w1, tp - 15), (w1 - 8, tp), (-w1 + 8, tp)], -t["t"] / 2, t["t"] / 2, PLATE,
          M, bevel=bv)
    prism(s, [(-w0 - 2, b - 4), (w0 + 2, b - 4), (w0 + 2, b + 8), (-w0 - 2, b + 8)], -t["t"] / 2, t["t"] / 2,
          PLATE, M, bevel=bv)


def chassis(hi):
    s = Shape()
    t = C["tub"]
    z0 = C["ride"]
    # the tub: a moulded floor, narrower at the nose, its side walls
    w, nw = t["w"] / 2, t["nose_w"] / 2
    pts = [(-nw, t["y0"]), (nw, t["y0"]), (w, t["y0"] + 60), (w, t["y1"]), (-w, t["y1"]), (-w, t["y0"] + 60)]
    prism(s, pts, z0, z0 + 3, NYLON, bevel=0.8 if hi else 0.0)
    for side in (-1, 1):
        bar(s, (side * (nw - 1), t["y0"] + 2, z0 + 3 + t["h"] / 2 - 4),
            (side * (w - 1.5), t["y0"] + 60, z0 + 3 + t["h"] / 2 - 4), t["wall"], t["h"] - 8, NYLON, hi)
        bar(s, (side * (w - 1.5), t["y0"] + 60, z0 + 3 + t["h"] / 2 - 4),
            (side * (w - 1.5), t["y1"], z0 + 3 + t["h"] / 2 - 4), t["wall"], t["h"] - 8, NYLON, hi)
    # the battery: a six-cell stick in yellow shrink-wrap, its leads to the speed control
    bl, bw, bh = C["battery"]
    s.box(V(-bw / 2, -70, z0 + 3), V(bw / 2, -70 + bl, z0 + 3 + bh), BATT, mm(5), 3 if hi else 1)
    # the steering servo, its saver; the receiver and the speed control behind it
    s.box(V(-20, -132, z0 + 3), V(20, -112, z0 + 40), NYLON, mm(1.5), 2 if hi else 1)
    s.cylinder(V(0, -126, z0 + 40), V(0, -126, z0 + 46), mm(9), NYLON, segs(hi, 12))
    bar(s, (-16, -126, 41), (16, -126, 41), 6, 4, NYLON, hi)
    s.box(V(-w + 6, 72, z0 + 3), V(-8, 104, z0 + 24), NYLON, mm(1.5), 2 if hi else 1)
    s.box(V(8, 70, z0 + 3), V(w - 6, 104, z0 + 20), PLATE, mm(1.2), 2 if hi else 1)
    # the front bulkhead and the bumper, the front shock tower
    bf = C["bulk_f"]
    s.box(V(-bf["w"] / 2, -156, bf["z0"]), V(bf["w"] / 2, -116, bf["z1"]), NYLON, mm(2), 2 if hi else 1)
    b = C["bumper"]
    prism(s, [(-b["w"] / 2 + 14, b["y0"]), (b["w"] / 2 - 14, b["y0"]), (b["w"] / 2, b["y0"] + 16),
              (b["w"] / 2 - 18, b["y1"]), (-b["w"] / 2 + 18, b["y1"]), (-b["w"] / 2, b["y0"] + 16)],
          b["z"], b["z"] + b["t"], NYLON, bevel=1.2 if hi else 0.0)
    bar(s, (-b["w"] / 2 + 6, b["y0"] + 4, b["z"] + 12), (b["w"] / 2 - 6, b["y0"] + 4, b["z"] + 12),
        7, 16, NYLON, hi)
    tower(s, C["tower_f"], hi)
    # the gearbox: its case, the diff's round housing, the spur gear's cover on the right
    g = C["gearbox"]
    s.box(V(-g["w"], g["y0"], g["z0"]), V(g["w"], g["y1"], g["z1"]), NYLON, mm(5), 3 if hi else 1)
    for side in (-1, 1):
        s.cylinder(V(side * (g["w"] - 2), YR, ZR), V(side * (g["w"] + 3), YR, ZR), mm(g["diff_r"]),
                   NYLON, segs(hi, 20))
    sp = C["spur"]
    s.cylinder(V(sp["x"], sp["y"], sp["z"]), V(sp["x"] - sp["t"], sp["y"], sp["z"]), mm(sp["r"]),
               NYLON, segs(hi, 24))
    # the motor across the car, its can and end bell, brush caps and leads
    mo = C["motor"]
    Mm = T(V(0, mo["y"], mo["z"])) @ Matrix.Rotation(math.radians(90), 4, "Y")
    r = mo["r"]
    prof = [(0.0, mo["x0"]), (r - 1.0, mo["x0"]), (r, mo["x0"] + 1.5), (r, mo["x1"] - 1.5),
            (r - 1.0, mo["x1"]), (r - 3.0, mo["x1"]), (r - 3.0, mo["x1"] + mo["bell"] - 2),
            (r - 5.0, mo["x1"] + mo["bell"]), (4.0, mo["x1"] + mo["bell"]), (0.0, mo["x1"] + mo["bell"] + 1)]
    kinds = [CAN] * 5 + [BELL] * 4
    s.lathe([(mm(a), mm(b)) for a, b in prof], CAN, segs(hi, 24), Mm, kinds=kinds)
    for dz in (-1, 1):
        s.cylinder(V(mo["x1"] + 4, mo["y"], mo["z"] + dz * (r - 1)), V(mo["x1"] + 4, mo["y"], mo["z"] + dz * (r + 4)),
                   mm(4.2), NYLON, segs(hi, 10))
    # the rear shock tower behind the gearbox, the wing's stays
    tr = C["tower_r"]
    tower(s, tr, hi)
    wg = C["wing"]
    for side in (-1, 1):
        bar(s, (side * 34, tr["y"] - 4, tr["top"] - 6), (side * 34, wg["y0"] + 30, wg["z"] + 30 * math.tan(math.radians(wg["aoa"])) - 5.2), 4, 9, NYLON, hi,
            up=(0, -1, 0))
    # the shocks: gold bodies, blue springs
    for side in (-1, 1):
        for sh in (C["shock_f"], C["shock_r"]):
            tp, bt = sh["top"], sh["bottom"]
            shock(s, (side * tp[0], tp[1], tp[2]), (side * bt[0], bt[1], bt[2]), sh["r"], hi)
    # body posts with their clips, and the aerial's mount
    for p in ((0, -144, 60), (-40, 150, 84), (40, 150, 84)):
        rod(s, (p[0], p[1], 30), (p[0], p[1], p[2] + 8), 2.6, NYLON, hi, 8)
        if hi:
            s.tube([V(p[0] - 5, p[1], p[2] + 4), V(p[0], p[1], p[2] + 4), V(p[0] + 4, p[1], p[2] + 7),
                    V(p[0] + 6, p[1], p[2] + 2)], mm(0.7), CLIP, 6)
    a = AER["at"]
    s.box(V(a[0] - 5, a[1] - 5, z0 + 3), V(a[0] + 5, a[1] + 5, a[2]), NYLON, mm(1), 2 if hi else 1)
    s.cylinder(V(a[0], a[1], a[2] - 6), V(a[0], a[1], a[2]), mm(AER["r"] + 1.6), NYLON, segs(hi, 10))
    return s


# --- the lexan shell and the wing ---------------------------------------------------------------

# stations nose to tail: y, then (half width, height) from the lower edge up to the roof's middle
STATIONS = [
    (-150, [(26, 36), (27, 44), (22, 50), (12, 53), (0, 54)]),
    (-122, [(40, 31), (40, 50), (32, 58), (18, 62), (0, 63)]),
    (-82, [(58, 27), (57, 55), (44, 64), (28, 73), (0, 75)]),
    (-42, [(68, 26), (67, 58), (50, 68), (36, 100), (0, 104)]),
    (0, [(72, 26), (71, 60), (52, 70), (38, 108), (0, 112)]),
    (40, [(74, 26), (73, 60), (52, 72), (36, 104), (0, 108)]),
    (76, [(72, 28), (71, 58), (50, 70), (32, 84), (0, 87)]),
    (104, [(66, 36), (65, 56), (46, 64), (28, 70), (0, 72)]),
]


def catmull(P, n):
    P = [Vector(p) for p in P]
    P = [P[0] * 2 - P[1]] + P + [P[-1] * 2 - P[-2]]
    out = []
    for i in range(1, len(P) - 2):
        p0, p1, p2, p3 = P[i - 1], P[i], P[i + 1], P[i + 2]
        for j in range(n):
            u = j / n
            out.append(0.5 * ((2 * p1) + (-p0 + p2) * u + (2 * p0 - 5 * p1 + 4 * p2 - p3) * u * u
                              + (-p0 + 3 * p1 - 3 * p2 + p3) * u * u * u))
    out.append(P[-2])
    return out


def shell_rings(hi):
    th = C["shell"]["t"]
    per = 4 if hi else 2                 # points a span of a section's half
    along = 7 if hi else 3               # rings a span of stations
    # every station's half section, smoothed, then the stations blended along the car
    halves = [(y, catmull(pts, per)) for y, pts in STATIONS]
    ys = [y for y, _ in halves]
    n = len(halves[0][1])
    cols = [catmull([(y, h[i].x, h[i].y) for y, h in halves], along) for i in range(n)]
    rings = []
    for k in range(len(cols[0])):
        half = [(c[k].y, c[k].z) for c in cols]
        y = cols[0][k].x
        # outer: the right edge (-X) up over the roof and down the left; inner back again
        outer = [(-x, z) for x, z in half] + [(x, z) for x, z in reversed(half[:-1])]
        inner = []
        for i in range(len(outer)):
            a, b = outer[max(i - 1, 0)], outer[min(i + 1, len(outer) - 1)]
            tx, tz = b[0] - a[0], b[1] - a[1]
            ln = math.hypot(tx, tz) or 1.0
            inner.append((outer[i][0] + tz / ln * th, outer[i][1] - tx / ln * th))
        loop = outer + list(reversed(inner))
        rings.append([(mm(x), mm(y), mm(z)) for x, z in loop])
    del ys
    return rings


# an outline drawn in (y, z) and thickness along x: local X to Y, Y to Z, Z to X
YZX = Matrix(((0, 0, 1, 0), (1, 0, 0, 0), (0, 1, 0, 0), (0, 0, 0, 1)))


def shell(hi):
    s = Shape()
    s.loft(shell_rings(hi), SHELL, cap_bottom=SHELL)
    # the wing on its stays: a lexan plate, its side dams turned down, a lip at the back
    wg = C["wing"]
    a = math.radians(wg["aoa"])
    Mw = T(V(0, wg["y0"], wg["z"])) @ Matrix.Rotation(a, 4, "X")     # its trailing edge up
    ch = wg["y1"] - wg["y0"]
    s.box(V(-wg["span"] / 2, 0, -0.5), V(wg["span"] / 2, ch, 0.5), WING, mm(0.35), 1, Mw)
    for side in (-1, 1):
        x = side * wg["span"] / 2
        prism(s, [(0.0, 0.0), (ch - 2.0, -wg["dam"]), (ch, -wg["dam"] + 3.0), (ch, 0.5), (4.0, 0.5)],
              -0.5, 0.5, WING, Mw @ T(V(x, 0, 0)) @ YZX)
    s.box(V(-wg["span"] / 2, ch - 1.2, 0.0), V(wg["span"] / 2, ch, wg["lip"]), WING, mm(0.3), 1, Mw)
    return s


# --- the aerial: a tube that whips, in two lengths ------------------------------------------------

def aerial_low(hi):
    s = Shape()
    s.cylinder(AER_BASE - V(0, 0, 4), AER_JOINT, mm(AER["r"]), AERIAL, segs(hi, 8))
    return s


def aerial_tip(hi):
    s = Shape()
    top = AER_BASE + V(0, 0, AER["length"])
    s.cylinder(AER_JOINT - V(0, 0, 1), top, mm(AER["r"] * 0.92), AERIAL, segs(hi, 8))
    cr, cl = AER["cap"]
    s.lathe([(0.0, 0.0), (mm(cr), mm(1.0)), (mm(cr), mm(cl - 3)), (mm(cr - 1.5), mm(cl)), (0.0, mm(cl))],
            CAP, segs(hi, 10), T(top - V(0, 0, cl - 5)))
    return s


# --- the transmitter ----------------------------------------------------------------------------

X = K.TX
M_TX = T(V(X["at"][0], X["at"][1], 0)) @ Matrix.Rotation(math.radians(X["yaw"]), 4, "Z")
TXW = X["wheel"]
TX_WHEEL_AT = M_TX @ V(-(X["head"]["w"] / 2 + TXW["out"] + TXW["w"] / 2), TXW["y"], TXW["z"])
TX_WHEEL_AXIS = tuple((M_TX.to_3x3() @ Vector((1.0, 0.0, 0.0))).normalized())
TXT = X["trigger"]
TX_TRIG_AT = M_TX @ V(0, TXT["y"], TXT["z"])


def rounded_rings(w, d, z, r, n, M, cy=0.0):
    """A rounded rectangle w across and d deep at height z, anticlockwise from above."""
    pts = []
    q = n // 4
    for c, (sx, sy) in enumerate(((1, -1), (1, 1), (-1, 1), (-1, -1))):
        a0 = (-90 + 90 * c)
        for i in range(q):
            a = math.radians(a0 + 90 * i / q)
            pts.append((sx * (w / 2 - r) + r * math.cos(a), cy + sy * (d / 2 - r) + r * math.sin(a), z))
    return [tuple(M @ V(*p)) for p in pts]


def remote(hi):
    s = Shape()
    n = segs(hi, 24)
    f, gp, hd = X["foot"], X["grip"], X["head"]
    # the foot: the battery box it stands on, rounded, a rubber sole
    rings = [rounded_rings(f["w"] - 6, f["l"] - 6, 0.0, 10, n, M_TX)]
    for z, inset in ((2.0, 0.0), (f["h"] - 5.0, 0.0), (f["h"] - 1.0, 2.5), (f["h"], 6.0)):
        rings.append(rounded_rings(f["w"] - 2 * inset, f["l"] - 2 * inset, z, 12 - inset, n, M_TX))
    rings.append([tuple(M_TX @ V(0, 0, f["h"] + 0.4))])
    s.loft(rings, TX, cap_bottom=TX)
    # the grip, raked back, from the foot up under the head
    rk = math.radians(gp["rake"])
    rings = []
    m = 8 if hi else 4
    for i in range(m + 1):
        u = i / m
        z = gp["z0"] + (gp["z1"] - gp["z0"]) * u
        y = gp["y"] + (z - gp["z0"]) * math.tan(rk) * -1.0 + 6 * math.sin(math.pi * u)
        bulge = 1.0 + 0.12 * math.sin(math.pi * u)
        rings.append(rounded_rings(gp["w"] * bulge, gp["d"] * bulge, z, 12, n, M_TX, cy=y))
    s.loft(rings, TX)
    # the head: a long rounded box, its nose rounded down, its top domed
    rings = []
    m = 10 if hi else 5
    for i in range(m + 1):
        u = i / m
        z = hd["z0"] + (hd["z1"] - hd["z0"]) * u
        sh = math.sin(math.pi * min(u, 0.999)) ** 0.35
        w = hd["w"] * (0.78 + 0.22 * sh)
        L = (hd["y1"] - hd["y0"]) * (0.86 + 0.14 * sh)
        rings.append(rounded_rings(w, L, z, 14 + 6 * (1 - sh), n, M_TX, cy=(hd["y0"] + hd["y1"]) / 2))
    rings.append([tuple(M_TX @ V(0, (hd["y0"] + hd["y1"]) / 2, hd["z1"] + 1.5))])
    s.loft(rings, TX, cap_bottom=TX)
    # the face plate on the left side, trim knobs, the power switch and its red light
    s.box(V(hd["w"] / 2 - 1.0, hd["y0"] + 22, hd["z0"] + 14), V(hd["w"] / 2 + 1.2, hd["y1"] - 22, hd["z1"] - 16),
          TXFACE, mm(0.6), 2 if hi else 1, M_TX)
    for y, z in ((-40, 176), (-14, 176)):
        s.cylinder(M_TX @ V(hd["w"] / 2 + 1, y, z), M_TX @ V(hd["w"] / 2 + 6, y, z), mm(5), TXFACE, segs(hi, 12))
    s.box(V(hd["w"] / 2, 20, 160), V(hd["w"] / 2 + 3, 32, 166), STEEL, mm(0.5), 1, M_TX)
    s.cylinder(M_TX @ V(hd["w"] / 2, 40, 182), M_TX @ V(hd["w"] / 2 + 2, 40, 182), mm(2.2), LED, segs(hi, 8))
    # the crystal in the back, its pull tab, and the wheel's boss on the right
    s.box(V(-7, hd["y1"] - 2, 150), V(7, hd["y1"] + 5, 170), TXFACE, mm(1), 2 if hi else 1, M_TX)
    s.cylinder(M_TX @ V(-hd["w"] / 2 + 1, TXW["y"], TXW["z"]), M_TX @ V(-hd["w"] / 2 - TXW["out"], TXW["y"], TXW["z"]),
               mm(9), TX, segs(hi, 14))
    # the telescopic aerial: chrome sections out of a collar on top, a ball on the tip
    a = X["aerial"]
    base = M_TX @ V(0, a["y"], hd["z1"] - 6)
    up = Vector((0, 0, 1))
    s.cylinder(base, base + up * mm(14), mm(a["r0"] + 2.6), TX, segs(hi, 12))
    k = a["sections"]
    each = a["length"] / k
    for i in range(k):
        r = a["r0"] + (a["r1"] - a["r0"]) * i / (k - 1)
        z0 = 10 + each * i
        s.cylinder(base + up * mm(z0), base + up * mm(z0 + each + 1.0), mm(r), ANT, segs(hi, 10))
        if hi:
            s.cylinder(base + up * mm(z0 + each - 1.5), base + up * mm(z0 + each + 1.0), mm(r + 0.5), ANT, 10)
    top = base + up * mm(10 + a["length"] + 1.0)
    s.lathe([(0.0, 0.0), (mm(3.4), mm(2.5)), (mm(3.4), mm(4.5)), (0.0, mm(7.0))], ANT, segs(hi, 10), T(top))
    # the frequency flag: an orange ribbon clipped round the aerial's foot
    fl = base + up * mm(22)
    d = M_TX.to_3x3() @ Vector((0, 1, 0))
    s.box((0, 0, 0), (mm(1.0), mm(30), mm(14)), FLAG, mm(0.3), 1,
          T(fl) @ Matrix.Rotation(math.atan2(-d.x, d.y) + math.radians(-35), 4, "Z") @ Matrix.Rotation(math.radians(-14), 4, "X"))
    return s


def remote_wheel(hi):
    s = Shape()
    M = T(TX_WHEEL_AT) @ M_TX.to_3x3().to_4x4() @ Matrix.Rotation(math.radians(-90), 4, "Y")
    r, w = TXW["r"], TXW["w"]
    f = 2 if hi else 1
    p = [(9.0, -w / 2), (r - 5.0, -w / 2)] + fillet(r - 5.0, -w / 2 + 5.0, 5.0, (-90, 0), 3 * f)[1:]
    p += fillet(r - 5.0, w / 2 - 5.0, 5.0, (0, 90), 3 * f) + [(r - 9.0, w / 2 + 0.5)]
    p += [(r - 10.0, w / 2 - 2.0), (8.0, w / 2 - 3.0), (6.0, w / 2 - 1.0), (0.0, w / 2 - 1.0)]
    kinds = [FOAM] * (len(p) - 5) + [TXFACE] * 4
    s.lathe([(mm(a), mm(b)) for a, b in p], FOAM, segs(hi, 28), M, kinds=kinds)
    if hi:
        # the foam's knurl: fine ribs across its tread
        for j in range(48):
            Mj = M @ Matrix.Rotation(2 * math.pi * j / 48, 4, "Z")
            s.box((mm(r - 0.6), -mm(0.8), -mm(w / 2 - 5)), (mm(r + 0.7), mm(0.8), mm(w / 2 - 5)), FOAM,
                  mm(0.3), 1, Mj)
    # five spokes across the dish to the hub, like a little car wheel
    for j in range(5):
        Mj = M @ Matrix.Rotation(2 * math.pi * j / 5, 4, "Z")
        s.box((mm(6), -mm(2.4), mm(w / 2 - 4)), (mm(r - 10), mm(2.4), mm(w / 2 - 0.5)), TXFACE, mm(0.6),
              2 if hi else 1, Mj)
    return s


def trigger(hi):
    s = Shape()
    L = TXT["len"]
    pts = [M_TX @ V(0, TXT["y"] - 2.0 * math.sin(math.pi * u * 0.9) * 6 - u * 8, TXT["z"] - L * u)
           for u in [i / (8 if hi else 4) for i in range((8 if hi else 4) + 1)]]
    rad = [mm(5.5 - 1.5 * i / (len(pts) - 1)) for i in range(len(pts))]
    s.tube(pts, mm(5.5), TX, segs(hi, 10), radii=rad)
    s.cylinder(M_TX @ V(-6, TXT["y"], TXT["z"]), M_TX @ V(6, TXT["y"], TXT["z"]), mm(4.5), TX, segs(hi, 10))
    return s


# --- the look ---------------------------------------------------------------------------------

def rc_look(L, f):
    nb = L.nb
    st = 1.0 / K.STUD_MM                       # a millimetre, in studs
    C_ = Coat(L, hexc("#1C1C1E"), 0.55, 0.0, nb.mul(L.noise(260.0, 1, detail=1), 0.08))
    # black moulded nylon everywhere it isn't something else, a satin sheen, scuffed pale
    nyl = L.k(NYLON, TX)
    C_.paint(nyl, nb.tint(hexc("#1D1D1F"), nb.mr(L.noise(9.0, 2, detail=3), 0.3, 0.7, 0.85, 1.15)),
             nb.mr(L.noise(14.0, 3, detail=3), 0.3, 0.7, 0.42, 0.62), 0.0)
    C_.paint(nb.mul(nyl, nb.mul(L.edge(0.004), nb.ss(L.noise(30.0, 4, detail=4), 0.5, 0.62))),
             hexc("#4A4846"), 0.7)
    # the towers: graphite plate, a faint weave
    C_.paint(L.k(PLATE), nb.tint(hexc("#2B2C2F"), nb.mr(L.noise(400.0, 5, detail=1), 0.3, 0.7, 0.9, 1.1)),
             0.36, 0.2)
    # gold anodised shock bodies, chrome shafts, blue springs, steel pins and screws
    C_.paint(L.k(GOLD), nb.tint(hexc("#C79C3E"), nb.mr(L.noise(40.0, 6, detail=3), 0.3, 0.7, 0.88, 1.05)),
             0.26, 1.0)
    C_.paint(L.k(CHROME), hexc("#D6D8DA"), 0.1, 1.0)
    C_.paint(L.k(SPRING), hexc("#2D5BD6"), 0.32, 0.35)
    C_.paint(L.k(STEEL, CLIP), hexc("#A9ACAF"), 0.3, 1.0)
    # the motor: a silver can, a blue end bell; the battery in yellow wrap; red and black leads
    C_.paint(L.k(CAN), nb.tint(hexc("#B9BCBF"), nb.mr(L.noise(60.0, 7, stretch=(1.0, 0.1, 1.0), detail=3),
                                                       0.3, 0.7, 0.85, 1.05)), 0.3, 1.0)
    C_.paint(L.k(BELL), hexc("#2E58C8"), 0.3, 0.8)
    C_.paint(L.k(BATT), hexc("#E8B820"), 0.35, 0.0)
    C_.paint(L.k(WIRE), hexc("#B5221B"), 0.5, 0.0)
    # tyres: black rubber, matt, grey where they wore
    tyre = L.k(TYRE)
    C_.paint(tyre, nb.tint(hexc("#1E1D1C"), nb.mr(L.noise(50.0, 8, detail=3), 0.3, 0.7, 0.85, 1.2)),
             nb.mr(L.noise(30.0, 9, detail=3), 0.3, 0.7, 0.78, 0.9), 0.0)
    # yellow dish wheels, nylon, a little sun-faded
    rim = L.k(RIM)
    C_.paint(rim, nb.tint(hexc("#F0C21A"), nb.mr(L.noise(8.0, 10, detail=3), 0.3, 0.7, 0.88, 1.04)), 0.42, 0.0)
    # the shell: white lexan, glossy, a red nose fading through orange; dark smoke windows
    sh = L.k(SHELL)
    y = L.y
    C_.paint(sh, hexc("#F1F0EA"), 0.1, 0.0)
    fade = nb.mr(nb.add(y, nb.mul(L.noise(6.0, 11, detail=4), 0.03)), mm(-60), mm(10), 1.0, 0.0)
    C_.paint(nb.mul(sh, nb.ss(fade, 0.0, 0.5)), hexc("#EE7A1C"), 0.1)
    C_.paint(nb.mul(sh, nb.ss(fade, 0.45, 1.0)), hexc("#D3241D"), 0.1)
    # windows: the windscreen and the side windows, cut by the A pillars, under the roof
    z = L.z
    ax = nb.absf(L.x)
    cabin = nb.mul(nb.ss(z, mm(66), mm(69)), nb.mul(nb.ss(y, mm(-84), mm(-80)), nb.ss(nb.sub(0.0, y), mm(-58), mm(-54))))
    roof = nb.mul(nb.ss(ax, mm(30), mm(32)), nb.ss(y, mm(-46), mm(-42)))
    roof = nb.add(roof, nb.ss(z, mm(103), mm(105)), clamp=True)
    pillar = nb.mul(nb.ss(nb.absf(nb.sub(y, mm(-44))), mm(3.5), mm(2.5)), nb.ss(ax, mm(28), mm(34)))
    win = nb.mul(nb.mul(cabin, nb.inv(roof)), nb.inv(pillar))
    C_.paint(nb.mul(sh, win), hexc("#1A1F24"), 0.05)
    # a dark sill along its lower edge, as if the pods were sprayed smoke from inside
    C_.paint(nb.mul(sh, nb.ss(z, mm(37), mm(35))), hexc("#202326"), 0.1)
    # a blue pinstripe along the pods, the number 7 in a roundel on each flank
    stripe = nb.mul(nb.ss(nb.absf(nb.sub(z, mm(52))), mm(1.6), mm(0.9)), nb.ss(ax, mm(55), mm(60)))
    C_.paint(nb.mul(sh, nb.mul(stripe, nb.ss(y, mm(-100), mm(-90)))), hexc("#1F4FC4"), 0.1)
    side = nb.ss(nb.absf(L.nx), 0.45, 0.7)
    yc, zc = mm(38), mm(40)
    dy, dz = nb.sub(y, yc), nb.sub(z, zc)
    rr = nb.node("ShaderNodeVectorMath", operation="LENGTH")
    nb.put(rr.inputs[0], nb.comb(dy, dz, 0.0))
    rr = rr.outputs["Value"]
    disc = nb.mul(side, nb.ss(rr, mm(17), mm(16)))
    ring = nb.mul(disc, nb.ss(rr, mm(13.5), mm(14.5)))
    C_.paint(nb.mul(sh, ring), hexc("#151515"), 0.1)
    # the 7, the right way round on both flanks: its bar, then its stroke
    flip = nb.sub(nb.mul(nb.ss(L.x, -0.0005, 0.0005), -2.0), -1.0)   # +1 on the right, -1 on the left
    u = nb.mul(dy, flip)
    bar7 = nb.mul(nb.ss(nb.absf(nb.sub(dz, mm(6.5))), mm(1.7), mm(1.2)), nb.ss(nb.absf(u), mm(6.5), mm(5.8)))
    k = nb.sub(nb.add(nb.mul(u, -0.92), nb.mul(dz, 0.39)), mm(-0.6))      # distance off the stroke's line
    stroke = nb.mul(nb.mul(nb.ss(nb.absf(k), mm(1.9), mm(1.3)), nb.ss(dz, mm(-9.5), mm(-8.5))),
                    nb.ss(nb.sub(mm(6.0), dz), mm(-0.5), mm(0.5)))
    seven = nb.add(bar7, stroke, clamp=True)
    C_.paint(nb.mul(sh, nb.mul(disc, seven)), hexc("#151515"), 0.1)
    # the wing: red, an orange stripe across it
    wing = L.k(WING)
    C_.paint(wing, hexc("#D3241D"), 0.12)
    C_.paint(nb.mul(wing, nb.ss(nb.absf(nb.sub(y, mm(150))), mm(6), mm(5))), hexc("#EE7A1C"), 0.12)
    # lexan scuffed dull along its lower edges and the nose, chipped paint showing clear plastic
    low = nb.mul(nb.add(sh, wing, clamp=True), nb.ss(z, mm(40), mm(28)))
    C_.paint(nb.mul(low, nb.ss(L.noise(40.0, 12, detail=4), 0.5, 0.6)), None, 0.45)
    # the aerial: black tube, a red cap
    C_.paint(L.k(AERIAL), hexc("#141414"), 0.45, 0.0)
    C_.paint(L.k(CAP), hexc("#D01E1E"), 0.4, 0.0)
    # the transmitter: grey face plate, foam on its wheel, chrome aerial, red light, orange flag
    C_.paint(L.k(TXFACE), nb.tint(hexc("#4C4F54"), nb.mr(L.noise(20.0, 13, detail=3), 0.3, 0.7, 0.9, 1.1)), 0.45)
    C_.paint(L.k(FOAM), hexc("#141414"), 0.95)
    C_.paint(L.k(ANT), hexc("#D9DBDD"), 0.12, 1.0)
    C_.paint(L.k(LED), hexc("#8A1410"), 0.15)
    C_.paint(L.k(FLAG), hexc("#F2781B"), 0.6)
    # the grip shiny and pale where hands held it
    grip = nb.mul(L.k(TX), nb.mul(nb.ss(z, mm(40), mm(60)), nb.ss(nb.sub(0.0, z), mm(-130), mm(-115))))
    C_.paint(nb.mul(grip, nb.ss(L.noise(10.0, 14, detail=3), 0.4, 0.6)), hexc("#2C2C2E"), 0.28)
    # dried mud from the back yard: spattered low on everything of the car, thick in the tread
    car = nb.inv(L.k(TX, TXFACE, FOAM, ANT, LED, FLAG))
    splash = nb.mul(car, nb.ss(z, mm(70), mm(20)))
    spot = nb.ss(L.noise(55.0, 15, detail=5, rough=0.7), 0.62, 0.68)
    C_.paint(nb.mul(splash, spot), hexc("#7B6550"), 0.92, 0.0, 0.002)
    tread = nb.mul(tyre, nb.inv(L.ao(0.006)))
    C_.paint(nb.mul(tread, 0.85), hexc("#8A7660"), 0.95, 0.0)
    C_.paint(nb.mul(rim, nb.mul(nb.inv(L.ao(0.01)), 0.7)), hexc("#6E5A44"), 0.9, 0.0)
    del st
    C_.finish(f.dust, grime=0.5)
    return C_.surface(bump_dist=0.0012, bump=0.45)


# --- driving: the motions come from a small simulation, so the wheels turn at the rate the
# distance asks, the inner wheels slower, the chassis leans on its springs and the aerial whips --

D = K.RC_DRIVE
FPS = 240.0


def rdp(ts, vs, eps):
    """The fewest keys a straight line between them keeps within eps of the curve."""
    keep = [0, len(ts) - 1]
    stack = [(0, len(ts) - 1)]
    while stack:
        a, b = stack.pop()
        worst, at = 0.0, None
        for i in range(a + 1, b):
            u = (ts[i] - ts[a]) / (ts[b] - ts[a])
            e = abs(vs[i] - (vs[a] + (vs[b] - vs[a]) * u))
            if e > worst:
                worst, at = e, i
        if at is not None and worst > eps:
            keep.append(at)
            stack += [(a, at), (at, b)]
    keep.sort()
    out = [(round(ts[i], 3), round(vs[i], 4), "Linear", "In") for i in keep]
    out[0] = out[0][:2]
    return out


def spring(xs, target, w, z):
    """A damped spring chasing target(i): the chassis on its shocks, the aerial in its mount."""
    x, v, out = 0.0, 0.0, []
    dt = 1.0 / FPS
    for i in range(len(xs)):
        a = w * w * (target(i) - x) - 2 * z * w * v
        v += a * dt
        x += v * dt
        out.append(x)
    return out


def drive(dur, speed, steer, start=(0.0, 0.0, 0.0), slip=None, trigger=None):
    """speed(t) studs/s, steer(t) degrees (the bicycle's front wheel, + left); start (x, y, yaw)."""
    n = int(dur * FPS) + 1
    ts = [i / FPS for i in range(n)]
    L = mm(WB)
    x, y, yaw = start
    # the rear axle's middle drives; the pivot is midway between the axles
    P, H, Vv, Dl = [], [], [], []
    for t in ts:
        v, d = speed(t), math.radians(steer(t))
        f = Vector((math.sin(yaw), -math.cos(yaw), 0.0))
        P.append(Vector((x, y, 0.0)))
        H.append(yaw)
        Vv.append(v)
        Dl.append(d)
        rear = Vector((x, y, 0.0)) - f * L / 2
        w = v * math.tan(d) / L
        rear += f * v / FPS
        yaw += w / FPS
        f = Vector((math.sin(yaw), -math.cos(yaw), 0.0))
        x, y = (rear + f * L / 2).x, (rear + f * L / 2).y
    tr = {}
    tr[("Arms", "x")] = [p.x for p in P]
    tr[("Arms", "y")] = [p.y for p in P]
    tr[("Arms", "yaw")] = [math.degrees(h) for h in H]
    # accelerations in the car's frame: forward and to its left
    af = [(Vv[min(i + 1, n - 1)] - Vv[max(i - 1, 0)]) * FPS / 2 for i in range(n)]
    al = [Vv[i] * Vv[i] * math.tan(Dl[i]) / L for i in range(n)]
    # Ackermann: the inner wheel turns more; each knuckle's angle about its kingpin
    for side, part in ((1, "SteerL"), (-1, "SteerR")):
        vals = []
        for d in Dl:
            if abs(d) < 1e-5:
                vals.append(0.0)
                continue
            R = L / math.tan(d)                  # + left: the turn's middle is to the left
            vals.append(math.degrees(math.atan(L / (R - side * mm(TF) / 2))))
        tr[(part, "turn")] = vals
    # every wheel turns by the distance its own contact patch rolls, over its radius
    for part, side, front in (("WheelFL", 1, True), ("WheelFR", -1, True), ("WheelRL", 1, False),
                              ("WheelRR", -1, False)):
        off = Vector((mm(side * (TF if front else TR) / 2), mm(YF if front else YR), 0.0))
        r = mm((TYF if front else TYR)["od"] / 2)
        ang, out, last = 0.0, [], None
        steer_k = tr[("SteerL" if side > 0 else "SteerR", "turn")] if front else None
        for i in range(n):
            c = P[i] + Matrix.Rotation(H[i], 3, "Z") @ off
            if last is not None:
                h = H[i] + (math.radians(steer_k[i]) if front else 0.0)
                ang += (c - last).dot(Vector((math.sin(h), -math.cos(h), 0.0))) / r
            last = c
            extra = slip(ts[i]) / r if (slip and not front) else 0.0
            out.append(math.degrees(ang + extra))
        tr[(part, "turn")] = out
    # the chassis squats as it speeds up, dives as it brakes, leans out of a turn
    tr[("Chassis", "pitch")] = spring(ts, lambda i: -D["pitch"] * af[i], 2 * math.pi * 2.6, 0.42)
    tr[("Chassis", "roll")] = spring(ts, lambda i: -D["roll"] * al[i], 2 * math.pi * 2.4, 0.45)
    # the aerial: its lower length swings on its mount, the tip lags that and whips
    for ch, push, sign in (("pitch", af, -1.0), ("roll", al, -1.0)):
        base = spring(ts, lambda i: 1.5 * push[i], 2 * math.pi * 3.0, 0.11)
        acc = [(base[min(i + 1, n - 1)] - 2 * base[i] + base[max(i - 1, 0)]) * FPS * FPS for i in range(n)]
        tip = spring(ts, lambda i: -0.012 * acc[i], 2 * math.pi * 5.5, 0.12)
        tr[("Aerial", ch)] = [sign * v if ch == "pitch" else -v for v in base]
        tr[("AerialTip", ch)] = [sign * v if ch == "pitch" else -v for v in tip]
    tr[("RemoteWheel", "turn")] = [math.degrees(d) / D["steer_lock"] * X["wheel"]["turn"] for d in Dl]
    if trigger:
        tr[("Trigger", "turn")] = [trigger(t) for t in ts]
    eps = {"x": 0.002, "y": 0.002, "yaw": 0.15, "turn": 0.6, "pitch": 0.06, "roll": 0.06}
    out = []
    for (part, ch), vs in tr.items():
        if max(vs) - min(vs) < 1e-4:
            continue
        e = eps[ch] * (0.25 if part in ("SteerL", "SteerR", "RemoteWheel", "Trigger") else 1.0)
        out.append((part, ch, rdp(ts, vs, e)))
    return out


def ease_s(t, t0, t1):
    u = min(max((t - t0) / (t1 - t0), 0.0), 1.0)
    return u * u * (3 - 2 * u)


TT = X["trigger"]
LAUNCH = drive(1.4, lambda t: 5.5 * ease_s(t, 0.1, 1.05) ** 0.8, lambda t: 0.0,
               slip=lambda t: 0.3 * ease_s(t, 0.1, 0.45),
               trigger=lambda t: TT["pull"] * ease_s(t, 0.0, 0.1))
CRUISE = 3.6
DRIVE = drive(2.6, lambda t: CRUISE,
              lambda t: -19.0 * (ease_s(t, 0.25, 0.65) - ease_s(t, 1.65, 2.1)),
              trigger=lambda t: TT["pull"] * 0.6)


def stop_speed(t):
    return 5.0 * (1.0 - ease_s(t, 0.12, 0.62) ** 0.7)


_dist = sum(stop_speed(i / FPS) / FPS for i in range(int(1.4 * FPS) + 1))
STOP = drive(1.4, stop_speed, lambda t: 0.0, start=(0.0, _dist, 0.0),
             trigger=lambda t: TT["pull"] * 0.8 * (1 - ease_s(t, 0.08, 0.14))
             + TT["push"] * (ease_s(t, 0.1, 0.16) - ease_s(t, 0.7, 0.8)))

CAR_FOCUS = (0.0, 0.0, 0.42)          # the filmstrips' camera aims a little under this
RC_CAR = kit.Find(
    "RCCar",
    [kit.Part("Remote", remote),
     kit.Part("RemoteWheel", remote_wheel, tuple(TX_WHEEL_AT), "Remote", TX_WHEEL_AXIS),
     kit.Part("Trigger", trigger, tuple(TX_TRIG_AT), "Remote",
              tuple(M_TX.to_3x3() @ Vector((1.0, 0.0, 0.0)))),
     kit.Part("Arms", arms, (0.0, 0.0, 0.0), "Remote"),
     kit.Part("Chassis", chassis, tuple(ROLL_C), "Arms"),
     kit.Part("Shell", shell, tuple(ROLL_C), "Chassis"),
     kit.Part("Aerial", aerial_low, tuple(AER_BASE), "Chassis"),
     kit.Part("AerialTip", aerial_tip, tuple(AER_JOINT), "Aerial"),
     kit.Part("SteerL", knuckle(1), tuple(king_at(1)), "Arms", KING_AXIS),
     kit.Part("SteerR", knuckle(-1), tuple(king_at(-1)), "Arms", KING_AXIS),
     kit.Part("WheelFL", wheel(1, True), tuple(wheel_at(1, True)), "SteerL", (1, 0, 0)),
     kit.Part("WheelFR", wheel(-1, True), tuple(wheel_at(-1, True)), "SteerR", (1, 0, 0)),
     kit.Part("WheelRL", wheel(1, False), tuple(wheel_at(1, False)), "Arms", (1, 0, 0)),
     kit.Part("WheelRR", wheel(-1, False), tuple(wheel_at(-1, False)), "Arms", (1, 0, 0))],
    rc_look,
    motions={
        # flat out from rest: the trigger squeezed, the rear tyres spin up and bite, the nose
        # lifts as it leaps off and the aerial is flung back, then shivers
        "Launch": dict(duration=1.4, focus=CAR_FOCUS, distance=0.62, follow="Arms", tracks=LAUNCH),
        # cruising round a corner on part throttle: the wheel turned, the front wheels steer
        # (the inner one more), the body leans out of the turn and the aerial swings wide
        "Drive": dict(duration=2.6, focus=CAR_FOCUS, distance=0.62, follow="Arms", tracks=DRIVE),
        # off the throttle and onto the brake: the nose dives, bobs back up and the aerial
        # whips forward and settles
        "Stop": dict(duration=1.4, focus=CAR_FOCUS, distance=0.62, follow="Arms", tracks=STOP),
    },
    drive=dict(
        body="Arms", sprung="Chassis",
        wheels=[("WheelFL", mm(TYF["od"] / 2), "SteerL"), ("WheelFR", mm(TYF["od"] / 2), "SteerR"),
                ("WheelRL", mm(TYR["od"] / 2), None), ("WheelRR", mm(TYR["od"] / 2), None)],
        Wheelbase=round(mm(WB), 4), Track=round(mm((TF + TR) / 2), 4), SteerLock=D["steer_lock"],
        Travel=round(mm(D["travel"]), 4), TopSpeed=D["top_speed"], Accel=D["accel"],
        Brake=D["brake"], Roll=D["roll"], Pitch=D["pitch"]),
    dust=C["dust"], seed=C["seed"],
)

# --- The die-cast car (F-03b) -------------------------------------------------------------------
# A pocket-size metal toy car of the late 1960s (README): a zinc body in metallic paint with its
# windows on the casting, a bright zinc base riveted under it that makes the bumpers and grille,
# and four black plastic wheels with silver hubs on crimped steel axles. Our own two-door saloon.

(DC_PAINT, DC_ZINC, DC_BRIGHT, DC_TYRE, DC_HUB, DC_STEEL, DC_LAMP) = range(23, 30)
G = K.DC
GL = G["length"] / 2
GYA = (-G["wheelbase"] / 2, G["wheelbase"] / 2)       # the front and rear axles
GAZ = G["tyre"]["od"] / 2                              # the axles' height: tyres on the floor
GHM = G["roof"] - G["deck"]                            # the greenhouse's full height


def soft01(u, r):
    """0 to 1 as u runs 0 to 1: straight in the middle, its ends rounded r either side."""
    def g(s):
        return 0.0 if s <= 0 else (s * s / 2 if s < 1 else s - 0.5)
    return (g(u + r) - g(u - r)) / (2 * r)


def dc_hw(y):
    """The body's half width at y: its corners rounded in plan."""
    c = G["corner"]
    e = min(c, max(0.0, abs(y) - (GL - c)))
    return G["half_w"] - (c - math.sqrt(c * c - e * e))


def dc_deck(y):
    """The bonnet's, sills' and boot's height at y."""
    if y < G["cowl"]:
        u = (y + GL) / (G["cowl"] + GL)
        return G["deck_nose"] + (G["deck_cowl"] - G["deck_nose"]) * (1 - (1 - u) ** 2)
    if y > G["back_base"]:
        u = (y - G["back_base"]) / (GL - G["back_base"])
        return G["deck"] + (G["deck_tail"] - G["deck"]) * u * u
    return G["deck_cowl"] + (G["deck"] - G["deck_cowl"]) * soft01((y - G["cowl"]) / 6.0, 0.3)


def dc_cabin(y):
    """How much of the greenhouse stands at y, 0 to 1: up the windscreen, down the back."""
    a = soft01((y - G["cowl"]) / (G["screen_top"] - G["cowl"]), 0.12)
    b = soft01((G["back_base"] - y) / (G["back_base"] - G["back_top"]), 0.12)
    return min(a, b)


def dc_bottom(y):
    """The casting's lower edge at y: the sill, or up round a wheel arch."""
    for ya in GYA:
        d = abs(y - ya)
        if d <= G["arch"]:
            return GAZ + math.sqrt(G["arch"] ** 2 - d * d)
    return G["sill"]


def dc_half(y):
    """The body's half section at y, (x, z) mm, from the bottom's middle round to the roof's."""
    hw, zb, deck = dc_hw(y), dc_bottom(y), dc_deck(y)
    k = hw / G["half_w"]
    gw, rw = G["glass_half"] * k, G["roof_half"] * k
    H = dc_cabin(y) * GHM
    q = min(1.0, H / 1.5)
    belt = deck - 0.55
    lo = zb + 0.45
    up = max(lo + 0.3, belt - 1.3)
    crown = 0.35 + (G["crown"] - 0.35) * min(1.0, H / GHM)
    top = deck + H
    return [(0.0, zb), (hw - 1.3, zb), (hw - 0.3, lo), (hw - 0.04, (lo + up) / 2), (hw, up),
            (hw - 0.12, belt), (hw - 0.9, deck - 0.08), (gw, deck),
            ((gw + rw) / 2 + 0.15 * q, deck + H * 0.5), (rw + 0.55 * q, top - 0.55 * q),
            (rw - 0.35, top + 0.12 * q + crown * 0.35), (rw * 0.5, top + crown * 0.8),
            (0.0, top + crown)]


def dc_ys(hi):
    """Where the body's sections stand along it: evenly, plus round the arches and the glass."""
    step = 1.0 if hi else 4.0
    ys = [-GL + i * step for i in range(int(2 * GL / step) + 1)] + [GL]
    na = 24 if hi else 6
    for ya in GYA:
        ys += [ya + G["arch"] * math.cos(math.pi * i / na) for i in range(na + 1)]
        ys += [ya - G["arch"] - 0.02, ya + G["arch"] + 0.02]
    for e in (G["cowl"], G["screen_top"], G["back_top"], G["back_base"]):
        ys += [e - 1.1, e, e + 1.1]
    ys += [(G["cowl"] + G["screen_top"]) / 2, (G["back_top"] + G["back_base"]) / 2]
    out = []
    for y in sorted(y for y in ys if -GL <= y <= GL):
        if not out or y - out[-1] > 0.015:
            out.append(y)
    return out


def dc_ring(y, half):
    pts = [(-x, z) for x, z in half] + [(x, z) for x, z in reversed(half[1:-1])]
    return [(mm(x), mm(y), mm(z)) for x, z in pts]


def dc_body_shell(s, hi):
    secs = []
    for y in dc_ys(hi):
        h = dc_half(y)
        if hi:
            h = [(p.x, p.y) for p in catmull(h, 3)]
        secs.append((y, h))
    # the nose and tail turn under in a 1 mm round, each closing on a point
    r = 1.0
    angs = (25, 50, 70) if hi else (40, 70)

    def cap(y, h, sgn):
        zc = (h[0][1] + h[-1][1]) / 2
        hw = max(x for x, _ in h)
        hz = (h[-1][1] - h[0][1]) / 2
        out = []
        for a in angs:
            d, dy = r * (1 - math.cos(math.radians(a))), r * math.sin(math.radians(a))
            fx, fz = (hw - d) / hw, (hz - d) / hz
            out.append((y + sgn * dy, [(x * fx, zc + (z - zc) * fz) for x, z in h]))
        return out, (mm(0.0), mm(y + sgn * r * 0.97), mm(zc))
    front, fp = cap(*secs[0], -1)
    back, bp = cap(*secs[-1], 1)
    rings = [[fp]] + [dc_ring(y, h) for y, h in reversed(front)]
    rings += [dc_ring(y, h) for y, h in secs] + [dc_ring(y, h) for y, h in back] + [[bp]]
    s.loft(rings, DC_PAINT, split=2)


def dc_body(hi):
    s = Shape()
    dc_body_shell(s, hi)
    b, bu = G["base"], G["bumper"]
    # the base: a zinc plate between the wheels, out to the sills between and beyond the arches
    s.box(V(-b["half"], -GL + b["end"], b["z0"]), V(b["half"], GL - b["end"], b["z1"]), DC_ZINC,
          mm(0.3), 1)
    ar = G["arch"] + 0.3
    for y0, y1 in ((-GL + b["end"], GYA[0] - ar), (GYA[0] + ar, GYA[1] - ar), (GYA[1] + ar, GL - b["end"])):
        for sd in (-1, 1):
            x0, x1 = sorted((sd * b["half"], sd * b["side"]))
            s.box(V(x0, y0, b["z0"] + 0.05), V(x1, y1, b["z1"]), DC_ZINC, mm(0.3), 1)
    # the base's ends turned up into bumpers, a grille panel and round headlamps in the nose
    for sg in (-1, 1):
        y0, y1 = sorted((sg * (GL - 1.6), sg * (GL + 1.5)))
        s.box(V(-bu["half"], y0, bu["z0"]), V(bu["half"], y1, bu["z1"]), DC_BRIGHT, mm(0.7),
              3 if hi else 1)
    s.box(V(-7.6, -GL - 1.0, 6.2), V(7.6, -GL + 1.0, 9.8), DC_BRIGHT, mm(0.35), 2 if hi else 1)
    for sd in (-1, 1):
        s.cylinder(V(sd * 10.0, -GL + 1.0, 8.0), V(sd * 10.0, -GL - 0.95, 8.0), mm(1.45), DC_BRIGHT,
                   segs(hi, 14), cap_kind=DC_LAMP)
    # the axles in their lugs, crimped over in a dome outside each hub
    xe = G["track"] / 2 + G["tyre"]["w"] / 2 + 0.05
    for ya in GYA:
        s.cylinder(V(-xe, ya, GAZ), V(xe, ya, GAZ), mm(0.42), DC_STEEL, segs(hi, 8))
        for sd in (-1, 1):
            ball(s, (sd * (xe - 0.1), ya, GAZ), 0.72, DC_STEEL, hi)
            x0, x1 = sorted((sd * 7.6, sd * 9.4))
            s.box(V(x0, ya - 0.8, b["z1"] - 0.1), V(x1, ya + 0.8, GAZ + 1.0), DC_ZINC, mm(0.25), 1)
    # the rivets that hold the base on, peened over under it
    for yr in (-27.0, 27.0):
        ball(s, (0.0, yr, b["z0"]), 1.15, DC_ZINC, hi)
    if hi:
        # the maker's lines cast into the base, our own: two rows of raised lettering
        for row, xr in enumerate((-2.6, 2.6)):
            yy = -16.0
            for i, wd in enumerate((4, 6, 3, 7, 5) if row == 0 else (5, 3, 8, 4, 6)):
                for c in range(wd):
                    s.box(V(xr - 0.7, yy + c * 0.95, b["z0"] - 0.12), V(xr + 0.7, yy + c * 0.95 + 0.7,
                          b["z0"] + 0.05), DC_ZINC, mm(0.1), 1)
                yy += wd * 0.95 + 1.6
    return s


def dc_wheel_at(side, front):
    return V(side * G["track"] / 2, GYA[0] if front else GYA[1], GAZ)


def dc_wheel(side, front):
    def build(hi):
        s = Shape()
        M = T(dc_wheel_at(side, front)) @ Matrix.Rotation(math.radians(90 * side), 4, "Y")
        t = G["tyre"]
        R, w, hb = t["od"] / 2, t["w"], t["hub"] / 2
        f = 3 if hi else 1
        p = [(0.0, -w / 2 + 0.3), (hb - 0.6, -w / 2 + 0.3), (R - 1.3, -w / 2)]
        p += fillet(R - 0.6, -w / 2 + 0.6, 0.6, (-90, 0), f + 1)[1:]
        if hi:
            # the moulded tread: three fine grooves round
            for zc in (-0.75, 0.0, 0.75):
                p += [(R, zc - 0.17), (R - 0.22, zc - 0.11), (R - 0.22, zc + 0.11), (R, zc + 0.17)]
        p += fillet(R - 0.6, w / 2 - 0.6, 0.6, (0, 90), f + 1)
        p += [(R - 1.2, w / 2 + 0.04), (hb + 0.3, w / 2 - 0.05)]
        nt = len(p) - 1
        # the silver hub, set in: a raised rim, a dished face, the boss the axle's dome sits on
        p += [(hb, w / 2 - 0.3), (hb - 0.25, w / 2 - 0.1), (hb * 0.6, w / 2 - 0.32), (1.05, w / 2 - 0.12),
              (0.0, w / 2 - 0.05)]
        kinds = [DC_TYRE] * nt + [DC_TYRE] + [DC_HUB] * (len(p) - 2 - nt)
        s.lathe([(mm(r), mm(z)) for r, z in p], DC_TYRE, segs(hi, 20), M, kinds=kinds)
        return s
    return build


def dc_look(L, f):
    nb = L.nb
    x, y, z = L.x, L.y, L.z
    ax = nb.absf(x)

    def inb(v, lo, hi, soft=0.1):
        return nb.mul(nb.ss(v, mm(lo - soft), mm(lo + soft)), nb.ss(nb.sub(0.0, v), mm(-hi - soft), mm(-hi + soft)))

    def groove(v, c, w=0.12):
        return nb.ss(nb.sub(0.0, nb.absf(nb.sub(v, mm(c)))), -mm(2 * w), -mm(w))

    C_ = Coat(L, hexc("#2A64B8"), 0.2, 0.8)
    paint = L.k(DC_PAINT)
    # metallic blue enamel, a little uneven where it flowed thin over the casting
    C_.paint(paint, nb.tint(hexc("#2A64B8"), nb.mr(L.noise(90.0, 1, detail=3), 0.3, 0.7, 0.95, 1.04)),
             nb.mr(L.noise(160.0, 2, detail=2), 0.3, 0.7, 0.18, 0.22), 0.8)
    side = nb.ss(nb.absf(L.nx), 0.5, 0.7)
    top = nb.ss(L.nz, 0.45, 0.65)
    # the shut lines cast in: the doors, the bonnet and the boot lid
    lines = nb.mul(nb.mul(side, nb.add(groove(y, G["door"][0]), groove(y, G["door"][1]), clamp=True)),
                   inb(z, 4.2, 12.3))
    lid_x = nb.ss(nb.sub(0.0, ax), -mm(13.0), -mm(12.8))
    bon = nb.add(nb.mul(groove(y, G["cowl"] - 1.0), lid_x),
                 nb.mul(groove(ax, 12.9), nb.ss(nb.sub(0.0, y), mm(-G["cowl"] + 0.9), mm(-G["cowl"] + 1.1))),
                 clamp=True)
    boot = nb.add(nb.mul(groove(y, G["back_base"] + 1.0), lid_x),
                  nb.mul(groove(ax, 12.9), nb.ss(y, mm(G["back_base"] + 0.9), mm(G["back_base"] + 1.1))),
                  clamp=True)
    lines = nb.add(lines, nb.mul(nb.mul(top, nb.ss(z, mm(10.0), mm(10.4))), nb.add(bon, boot, clamp=True)),
                   clamp=True)
    C_.paint(nb.mul(paint, lines), hexc("#132845"), 0.5, 0.4, -1.0)
    # the windows, cast in and painted: tinted glass, the pale seats seen through the sides
    a = (G["screen_top"] - G["cowl"]) / GHM
    yA = nb.add(mm(G["cowl"] - a * G["deck"]), nb.mul(z, a))
    c = (G["back_base"] - G["back_top"]) / GHM
    yC = nb.sub(mm(G["back_base"] + c * G["deck"]), nb.mul(z, c))
    sideg = nb.mul(nb.mul(side, inb(z, 13.85, G["roof"] - 0.8)),
                   nb.mul(nb.ss(nb.sub(y, yA), mm(1.25), mm(1.45)), nb.ss(nb.sub(yC, y), mm(2.0), mm(2.2))))
    sideg = nb.mul(sideg, nb.ss(nb.absf(nb.sub(y, mm(G["b_pillar"]))), mm(0.6), mm(0.8)))
    kx = (G["glass_half"] - G["roof_half"]) / GHM
    xm = nb.sub(mm(G["glass_half"] - 1.3 + kx * G["deck"]), nb.mul(z, kx))
    span = nb.mul(nb.ss(nb.sub(xm, ax), 0.0, mm(0.2)), inb(z, 14.0, G["roof"] - 0.75))
    screens = nb.mul(span, nb.add(nb.ss(nb.sub(0.0, L.ny), 0.3, 0.45), nb.ss(L.ny, 0.3, 0.45), clamp=True))
    glass = nb.mul(paint, nb.add(sideg, screens, clamp=True))
    C_.paint(glass, hexc("#18232D"), 0.05, 0.0, -0.8)
    # the seats behind the side glass: the front seat's back under the door window, the bench's
    # behind the back one, cream plastic seen through the tint
    seats = nb.add(nb.mul(inb(y, -3.0, 2.2, 0.35), nb.ss(nb.sub(0.0, z), -mm(16.9), -mm(16.4))),
                   nb.mul(inb(y, 9.5, 15.0, 0.4), nb.ss(nb.sub(0.0, z), -mm(16.4), -mm(15.9))), clamp=True)
    seats = nb.mul(seats, nb.mr(z, mm(13.9), mm(16.6), 0.15, 0.5))
    C_.paint(nb.mul(nb.mul(paint, sideg), seats), hexc("#B3A98F"), 0.3)
    # door handles, tail lamps and the front indicators
    C_.paint(nb.mul(nb.mul(paint, side), nb.mul(inb(y, 4.9, 6.5, 0.08), inb(z, 11.2, 11.6, 0.08))),
             hexc("#D3D5D6"), 0.2, 1.0, 0.6)
    rear = nb.ss(L.ny, 0.6, 0.8)
    front = nb.ss(nb.sub(0.0, L.ny), 0.6, 0.8)
    C_.paint(nb.mul(nb.mul(paint, rear), nb.mul(inb(ax, 9.0, 12.4), inb(z, 9.2, 11.0))),
             hexc("#B5161B"), 0.15, 0.1, 0.3)
    C_.paint(nb.mul(nb.mul(paint, front), nb.mul(inb(ax, 9.4, 11.4), inb(z, 5.9, 6.6))),
             hexc("#E2891B"), 0.2, 0.1)
    # under the casting it's bare and dark
    C_.paint(nb.mul(paint, nb.ss(nb.sub(0.0, L.nz), 0.5, 0.7)), hexc("#3A3C3F"), 0.6, 0.5)
    # the base and its bumpers: bright zinc; the grille's slots; the lamps' lenses
    C_.paint(L.k(DC_ZINC), nb.tint(hexc("#ADB0AE"), nb.mr(L.noise(300.0, 3, detail=3), 0.3, 0.7, 0.86, 1.08)),
             nb.mr(L.noise(500.0, 4, detail=2), 0.3, 0.7, 0.34, 0.48), 1.0)
    bright = L.k(DC_BRIGHT)
    C_.paint(bright, hexc("#D6D8D8"), 0.13, 1.0)
    slots = nb.ss(nb.sub(0.0, nb.absf(nb.sub(nb.fract(nb.mul(z, 1.0 / mm(0.8))), 0.5))), -0.2, -0.13)
    grille = nb.mul(nb.mul(bright, front), nb.mul(inb(ax, 0.0, 7.0), inb(z, 6.6, 9.4)))
    C_.paint(nb.mul(grille, slots), hexc("#2B2D2F"), 0.5, 0.6, -1.0)
    C_.paint(L.k(DC_LAMP), hexc("#ECEDE8"), 0.06, 0.4)
    C_.paint(L.k(DC_STEEL), hexc("#9DA1A4"), 0.32, 1.0)
    # the wheels: black plastic, scuffed grey on the tread; silver hubs
    tyre = L.k(DC_TYRE)
    C_.paint(tyre, nb.tint(hexc("#151515"), nb.mr(L.noise(400.0, 5, detail=3), 0.3, 0.7, 0.85, 1.25)),
             nb.mr(L.noise(300.0, 6, detail=2), 0.3, 0.7, 0.42, 0.58), 0.0)
    C_.paint(L.k(DC_HUB), hexc("#CDD0D2"), 0.2, 1.0)
    # played with: the paint chipped to the zinc where it was knocked, on the edges and a few faces
    edge = L.edge(mm(0.8), k=4.0)
    bites = nb.mul(edge, nb.ss(L.noise(420.0, 7, detail=4), 0.5, 0.56))
    chips = nb.mx(nb.ss(bites, 0.35, 0.45), nb.ss(L.noise(240.0, 8, detail=4, rough=0.65), 0.83, 0.86))
    chips = nb.mul(nb.mul(paint, nb.inv(glass)), chips)
    C_.paint(chips, hexc("#A6A8A5"), 0.42, 0.9, -0.5)
    C_.finish(f.dust, grime=0.35)
    return C_.surface(bump_dist=0.0008, bump=0.6)


# --- pushing it: the same small simulation as the RC car's, reduced to keys ----------------------

PU = K.DC_PUSH


def dc_push():
    t_stop = PU["shove"] + PU["v0"] / PU["decel"]
    dur = round(t_stop + 0.4, 2)
    n = int(dur * FPS) + 1
    ts = [i / FPS for i in range(n)]

    def speed(t):
        if t < PU["shove"]:
            return PU["v0"] * ease_s(t, 0.0, PU["shove"])
        return max(0.0, PU["v0"] - PU["decel"] * (t - PU["shove"]))
    x = y = yaw = 0.0
    P, H, Vv = [], [], []
    for t in ts:
        v = speed(t)
        P.append(Vector((x, y, 0.0)))
        H.append(yaw)
        Vv.append(v)
        # the loose axles let it wander: a slow meander, more the faster it goes
        yaw += math.radians(PU["drift"] * math.sin(2 * math.pi * 0.32 * t + 0.5) * v / PU["v0"]) / FPS
        f = Vector((math.sin(yaw), -math.cos(yaw), 0.0))
        x, y = x + f.x * v / FPS, y + f.y * v / FPS
    tr = {("Body", "x"): [p.x for p in P], ("Body", "y"): [p.y for p in P],
          ("Body", "yaw"): [math.degrees(h) for h in H]}
    r = mm(G["tyre"]["od"] / 2)
    for part, side, front in (("WheelFL", 1, True), ("WheelFR", -1, True), ("WheelRL", 1, False),
                              ("WheelRR", -1, False)):
        off = Vector((mm(side * G["track"] / 2), mm(GYA[0] if front else GYA[1]), 0.0))
        ang, out, last = 0.0, [], None
        for i in range(n):
            cpt = P[i] + Matrix.Rotation(H[i], 3, "Z") @ off
            if last is not None:
                ang += (cpt - last).dot(Vector((math.sin(H[i]), -math.cos(H[i]), 0.0))) / r
            last = cpt
            out.append(math.degrees(ang))
        tr[(part, "turn")] = out
    af = [(Vv[min(i + 1, n - 1)] - Vv[max(i - 1, 0)]) * FPS / 2 for i in range(n)]
    # the shove tips its nose up on its axles, and it drops back with a bounce
    tr[("Body", "pitch")] = spring(ts, lambda i: -PU["nose"] * af[i], 2 * math.pi * 7.0, 0.3)
    # rolling, it rattles side to side on them, dying away as it slows
    tr[("Body", "roll")] = [PU["rattle"] * (Vv[i] / PU["v0"]) * (0.65 * math.sin(2 * math.pi * 5.3 * t)
                            + 0.35 * math.sin(2 * math.pi * 8.1 * t + 1.3)) for i, t in enumerate(ts)]
    eps = {"x": 0.002, "y": 0.002, "yaw": 0.1, "turn": 2.0, "pitch": 0.05, "roll": 0.08}
    out = []
    for (part, ch), vs in tr.items():
        if max(vs) - min(vs) < 1e-4:
            continue
        out.append((part, ch, rdp(ts, vs, eps[ch])))
    return dur, out


DC_DUR, DC_TRACKS = dc_push()
DIECAST = kit.Find(
    "DiecastCar",
    [kit.Part("Body", dc_body),
     kit.Part("WheelFL", dc_wheel(1, True), tuple(dc_wheel_at(1, True)), "Body", (1, 0, 0)),
     kit.Part("WheelFR", dc_wheel(-1, True), tuple(dc_wheel_at(-1, True)), "Body", (1, 0, 0)),
     kit.Part("WheelRL", dc_wheel(1, False), tuple(dc_wheel_at(1, False)), "Body", (1, 0, 0)),
     kit.Part("WheelRR", dc_wheel(-1, False), tuple(dc_wheel_at(-1, False)), "Body", (1, 0, 0))],
    dc_look,
    motions={
        # a shove from the hand: it leaves at a quarter of a run, nose up a hair, and rolls off
        # down the hall slowing, wandering and rattling on its loose axles, and stops
        "Push": dict(duration=DC_DUR, focus=(0.0, 0.0, mm(9.0)), distance=0.8, follow="Body",
                     view=(-1.1, -2.0, 1.1), drop=0.0, tracks=DC_TRACKS),
    },
    dust=G["dust"], seed=G["seed"], texels=1800,
)

FINDS = [RC_CAR, DIECAST]

if __name__ == "__main__":
    kit.main("Figures", HERE, FINDS)
