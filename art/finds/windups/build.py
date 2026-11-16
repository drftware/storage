"""The Wind-ups and noisemakers set (art/finds/windups/README.md), built with the finds kit.

    scripts/art.sh set windups [textures|export|renders|quick] [FindName]
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
from shapes import Shape, fillet  # noqa: E402

mm = K.mm

# What a face is, for the looks.
(TORSO, FUR, TROUSER, VINYL, EAR, EYE, FEZ, TASSEL, BRASS, TIN) = range(10)


def segs(hi, n):
    return n * 2 if hi else n


def V(x, y, z):
    return Vector((mm(x), mm(y), mm(z)))


def T(v):
    return Matrix.Translation(v)


def about(c, R):
    """R (a 4x4 rotation) turned about the point c (studs)."""
    return T(c) @ R @ T(-c)


def blob(s, c, r, kind, hi, M=Matrix(), lat=10, lon=20):
    """An ellipsoid round c (mm) with radii r (mm), as a loft from pole to pole."""
    cx, cy, cz = c
    rx, ry, rz = r
    nl, nn = segs(hi, lat), segs(hi, lon)
    rings = [[(mm(cx), mm(cy), mm(cz - rz))]]
    for i in range(1, nl):
        a = math.pi * i / nl
        k = math.sin(a)
        z = cz - rz * math.cos(a)
        rings.append([(mm(cx + rx * k * math.cos(2 * math.pi * j / nn)),
                       mm(cy + ry * k * math.sin(2 * math.pi * j / nn)), mm(z)) for j in range(nn)])
    rings.append([(mm(cx), mm(cy), mm(cz + rz))])
    s.loft(rings, kind, M)


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


def cr(p0, p1, p2, p3, t):
    return 0.5 * (2 * p1 + (p2 - p0) * t + (2 * p0 - 5 * p1 + 4 * p2 - p3) * t * t
                  + (3 * p1 - p0 - 3 * p2 + p3) * t * t * t)


def smooth_rows(rows, sub):
    """Catmull-Rom through a table's rows (each a tuple of numbers), `sub` steps a span."""
    out = []
    n = len(rows)
    for i in range(n - 1):
        p0, p1, p2, p3 = rows[max(i - 1, 0)], rows[i], rows[i + 1], rows[min(i + 2, n - 1)]
        for k in range(sub):
            t = k / sub
            out.append(tuple(cr(a, b, c, d, t) for a, b, c, d in zip(p0, p1, p2, p3)))
    out.append(rows[-1])
    return out


# --- The cymbal monkey (F-04a) ------------------------------------------------------------------
# A clockwork toy of the 1960s (README): a plush monkey sat with its legs out, a vinyl face, ears,
# hands and feet, in a felt waistcoat, striped trousers and a fez, a brass cymbal in each fist
# and a tin key in its back. Wound, it clashes its cymbals, nods and rolls its eyes until the
# spring runs down.

M_ = K.MONKEY
OPEN = M_["open"]

# The torso: (z, half width, half depth, middle in y), seat to neck, in mm
TORSO_ROWS = [(1.0, 0.0, 0.0, 16.0), (5.0, 40.0, 36.0, 15.0), (14.0, 55.0, 48.0, 13.0),
              (30.0, 63.0, 55.0, 11.0), (50.0, 64.0, 56.0, 10.0), (75.0, 60.0, 51.0, 11.0),
              (100.0, 58.0, 48.0, 13.0), (122.0, 57.0, 44.0, 14.0), (140.0, 54.0, 40.0, 15.0),
              (152.0, 48.0, 36.0, 16.0), (162.0, 38.0, 31.0, 16.0), (171.0, 24.0, 22.0, 16.0),
              (178.0, 0.0, 0.0, 16.0)]
HEM = 60.0                      # the waistcoat's hem; striped trousers below it
LEG = [(26.0, 2.0, 27.0), (31.0, -24.0, 25.5), (35.5, -50.0, 25.0), (39.0, -72.0, 25.5),
       (41.0, -86.0, 27.0)]     # the left leg's middle, hip to ankle (the right mirrors it)
LEG_R = [21.0, 20.0, 18.5, 16.5, 15.5]
HEAD = (0.0, 14.0, 205.0)
HEAD_R = (50.0, 46.0, 44.0)


def m_torso(hi):
    s = Shape()
    rows = smooth_rows(TORSO_ROWS[1:-1], 3 if hi else 1)
    nn = segs(hi, 22)
    rings = [[(0.0, mm(TORSO_ROWS[0][3]), mm(TORSO_ROWS[0][0]))]]
    for z, rx, ry, cy in rows:
        rings.append([(mm(rx * math.cos(2 * math.pi * j / nn)),
                       mm(cy + ry * math.sin(2 * math.pi * j / nn)), mm(z)) for j in range(nn)])
    rings.append([(0.0, mm(TORSO_ROWS[-1][3]), mm(TORSO_ROWS[-1][0]))])
    s.loft(rings, TORSO)
    return s


def m_body(hi):
    s = m_torso(hi)
    for sx in (1, -1):
        pts = [V(sx * x, y, z) for x, y, z in LEG]
        s.tube(pts, mm(LEG_R[0]), TROUSER, segs(hi, 16), radii=[mm(r) for r in LEG_R])
        # the foot: a vinyl foot sole-forward, toes up, as the toy sits
        c = V(sx * 42.0, -97.0, 33.0)
        R = Matrix.Rotation(math.radians(-18), 4, "X") @ Matrix.Rotation(math.radians(sx * 10), 4, "Z")
        blob(s, (sx * 42.0, -97.0, 33.0), (15.0, 12.5, 22.0), VINYL, hi, about(c, R), 8, 16)
        # the big toe, set apart as an ape's is
        blob(s, (sx * 33.0, -103.0, 30.0), (5.5, 6.0, 8.0), VINYL, hi, about(c, R), 6, 10)
    # the key's tin collar where it comes out through the fur
    k = M_["key"]
    Mk = T(V(*k["at"])) @ Matrix.Rotation(math.radians(-90), 4, "X")
    prof = [(0.0, -3.0), (7.5, -3.0), (8.4, -0.6), (8.0, 0.8), (6.0, 1.6), (3.6, 1.8), (0.0, 1.8)]
    s.lathe([(mm(a), mm(b)) for a, b in prof], TIN, segs(hi, 20), Mk)
    return s


def fez_m():
    f = M_["fez"]
    return T(V(*f["at"])) @ Matrix.Rotation(math.radians(f["tilt"]), 4, "Y")


def fez_edge():
    """Where the tassel's cord drapes over the fez's top edge (studs)."""
    return fez_m() @ V(20.5, 0.0, M_["fez"]["h"])


def m_head(hi):
    s = Shape()
    blob(s, HEAD, HEAD_R, FUR, hi, lat=12, lon=24)
    # the vinyl face: a broad plate, a brow over the eyes, a muzzle that juts with the grin
    blob(s, (0.0, -12.0, 201.0), (38.0, 28.0, 37.0), VINYL, hi, lat=10, lon=22)
    blob(s, (0.0, -27.0, 222.0), (33.0, 8.0, 9.5), VINYL, hi, lat=8, lon=16)
    blob(s, (0.0, -33.0, 183.0), (27.0, 18.0, 18.0), VINYL, hi, lat=10, lon=20)
    # ears: cupped vinyl, set on the sides and turned a little forward
    prof = [(0.0, 0.0), (12.0, 0.4), (18.0, 1.4), (20.0, 3.0), (19.0, 4.2), (16.0, 3.6),
            (10.0, 2.2), (0.0, 1.9)]
    for sx in (1, -1):
        blob(s, (sx * 49.0, 13.0, 206.0), (4.0, 6.0, 8.0), EAR, hi, lat=6, lon=10)
        Me = (T(V(sx * 51.5, 12.0, 206.0)) @ Matrix.Rotation(math.radians(-20 * sx), 4, "Z")
              @ Matrix.Rotation(math.radians(90 * sx), 4, "Y"))
        s.lathe([(mm(a), mm(b)) for a, b in prof], EAR, segs(hi, 20), Me)
    # the fez: felt over a card shape, sat at a slant; the tassel's button and cord on top
    f = M_["fez"]
    r0, r1, h = f["r"][0], f["r"][1], f["h"]
    p = [(r0 - 1.5, -5.0), (r0, -0.5), (r0 - 0.4, 1.0), (r1 + 1.4, h - 2.5)]
    p += fillet(r1 - 1.0, h - 2.5, 2.4, (0, 90), 4 if hi else 2)[1:] + [(0.0, h - 0.1)]
    s.lathe([(mm(a), mm(b)) for a, b in p], FEZ, segs(hi, 26), fez_m())
    Mf = fez_m()
    blob(s, (0.0, 0.0, h + 1.0), (3.4, 3.4, 2.2), TASSEL, hi, Mf, 6, 12)
    cord = [Mf @ V(0.0, 0.0, h + 0.9), Mf @ V(8.0, 0.0, h + 0.9), Mf @ V(15.0, 0.0, h + 0.7),
            Mf @ V(19.5, 0.0, h + 0.2), fez_edge()]
    s.tube(cord, mm(1.1), TASSEL, segs(hi, 6))
    return s


def m_eyes(hi):
    s = Shape()
    ex, ey, ez = M_["eyes"]
    for sx in (1, -1):
        blob(s, (sx * ex, ey, ez), (M_["eye_r"],) * 3, EYE, hi, lat=10, lon=20)
    return s


def m_tassel(hi):
    """The cord's drop over the fez's edge and the tassel on it, hanging plumb."""
    s = Shape()
    e = fez_edge()
    s.tube([e, e + V(0.6, 0.0, -1.5), e + V(0.9, 0.0, -3.0)], mm(1.1), TASSEL, segs(hi, 6))
    prof = [(0.0, -11.0), (3.6, -10.6), (4.3, -9.4), (3.9, -6.0), (2.7, -2.6), (1.7, -1.0),
            (1.2, 0.0), (0.0, 0.4)]
    s.lathe([(mm(a), mm(b)) for a, b in prof], TASSEL, segs(hi, 14), T(e + V(0.9, 0.0, -3.0)))
    if hi:
        # the threads' ends, a ragged fringe under the tassel
        for j in range(14):
            a = 2 * math.pi * j / 14
            b = e + V(0.9 + 3.0 * math.cos(a), 3.0 * math.sin(a), -13.0)
            s.cylinder(b + V(0, 0, 2.5), b - V(0, 0, 0.6 + 0.6 * (j % 3)), mm(0.55), TASSEL, 5)
    return s


# The arms are drawn as they are at the clash (the cymbals' rims meeting square at x = 0), then
# swung open about each shoulder's axis by OPEN degrees: as the toy is found, and as it's baked,
# so the cymbals' faces never shade each other.

def arm_axis(sx):
    S, H = V(sx * M_["shoulder"][0], *M_["shoulder"][1:]), V(sx * M_["hand"][0], *M_["hand"][1:])
    a = (H - S).normalized().cross(Vector((1.0, 0.0, 0.0))).normalized()
    c = V(sx * M_["cymbal"]["at"][0], *M_["cymbal"]["at"][1:])
    moved = Matrix.Rotation(math.radians(OPEN), 3, a) @ (c - S) + S
    if (moved.x - c.x) * sx < 0:      # opening must swing the cymbal outward
        a = -a
    return S, a


def arm_open(sx):
    S, a = arm_axis(sx)
    return about(S, Matrix.Rotation(math.radians(OPEN), 4, a))


def cym_m(sx):
    """The cymbal's own frame at the clash: its Z out of the dish, towards the fist."""
    return T(V(sx * M_["cymbal"]["at"][0], *M_["cymbal"]["at"][1:])) @ Matrix.Rotation(
        math.radians(90 * sx), 4, "Y")


def strap_at(sx):
    return arm_open(sx) @ cym_m(sx) @ V(0.0, 0.0, M_["cymbal"]["bell"][1])


def m_arm(sx):
    def build(hi):
        s = Shape()
        Mo = arm_open(sx)
        S = V(sx * M_["shoulder"][0], *M_["shoulder"][1:])
        E = V(sx * M_["elbow"][0], *M_["elbow"][1:])
        W = V(sx * M_["wrist"][0], *M_["wrist"][1:])
        # a gentle bend through the elbow: a quadratic through the three
        pts, radii = [], []
        n = 8 if hi else 5
        for i in range(n + 1):
            t = i / n
            p = (1 - t) ** 2 * S + 2 * (1 - t) * t * (2 * E - (S + W) / 2) + t * t * W
            pts.append(Mo @ p)
            radii.append(mm(18.5 - 6.0 * t))
        s.tube(pts, radii[0], FUR, segs(hi, 14), radii=radii)
        hx, hy, hz = M_["hand"]
        blob(s, (sx * hx, hy, hz), (9.5, 12.5, 15.5), VINYL, hi, Mo, 8, 16)
        # the thumb, wrapped round the strap's front
        blob(s, (sx * (hx - 5.0), hy - 9.0, hz + 6.0), (4.6, 5.5, 7.0), VINYL, hi,
             Mo @ about(V(sx * (hx - 5.0), hy - 9.0, hz + 6.0),
                        Matrix.Rotation(math.radians(25 * sx), 4, "Y")), 6, 10)
        return s
    return build


def m_cymbal(sx):
    def build(hi):
        s = Shape()
        c = M_["cymbal"]
        t = c["t"]
        top = [(0.0, 10.0), (4.0, 9.6), (7.0, 8.4), (8.6, 6.4), (9.6, 4.6), (12.0, 4.0),
               (21.0, 2.6), (29.0, 1.2), (33.0, 0.6)]
        under = [(x, z - t) for x, z in top]
        prof = under + [(33.25, 0.2)] + list(reversed(top))
        s.lathe([(mm(a), mm(b)) for a, b in prof], BRASS, segs(hi, 32), arm_open(sx) @ cym_m(sx))
        # the leather strap's knot on the bell, inside the fist
        blob(s, (0.0, 0.0, 10.8), (3.0, 3.0, 2.0), BRASS, hi, arm_open(sx) @ cym_m(sx), 4, 8)
        return s
    return build


def m_key(hi):
    s = Shape()
    k = M_["key"]
    at = V(*k["at"])
    r, L = k["shaft"]
    s.cylinder(at + V(0, -2.0, 0), at + V(0, L, 0), mm(r), TIN, segs(hi, 10))
    # the wings: two rounded lobes of folded tin on a hub, a bow-tie seen from behind
    Mw = T(at + V(0, L, 0)) @ Matrix.Rotation(math.radians(-90), 4, "X")
    wx, wz = k["wing"]
    n = segs(hi, 16)
    for sx in (1, -1):
        lobe = [(sx * (wx * 0.56) + wx * 0.44 * math.cos(2 * math.pi * j / n),
                 wz * 0.5 * math.sin(2 * math.pi * j / n)) for j in range(n)]
        if sx < 0:
            lobe = lobe[n // 2:] + lobe[:n // 2]
        prism(s, lobe, -k["t"] / 2, k["t"] / 2, TIN, Mw, 0.35 if hi else 0.0)
    s.cylinder(at + V(0, L - 2.2, 0), at + V(0, L + 2.2, 0), mm(6.0), TIN, segs(hi, 14))
    return s


def monkey_look(L, f):
    nb = L.nb
    x, y, z = L.x, L.y, L.z
    ax = nb.absf(x)

    def band(v, lo, hi, soft):
        return nb.mul(nb.ss(v, lo - soft, lo + soft), nb.sub(1.0, nb.ss(v, hi - soft, hi + soft)))

    # fur: dark warm brown plush, strands running down, clumped, paler at the tips
    strands = L.noise(240.0, 1, stretch=(1.0, 1.0, 0.07), detail=2, rough=0.6)
    locks = L.noise(90.0, 11, stretch=(1.0, 1.0, 0.15), detail=2)
    clumps = L.noise(40.0, 2, detail=3)
    tips = nb.ss(nb.add(nb.mul(strands, 0.6), nb.mul(locks, 0.4)), 0.5, 0.74)
    fur_col = nb.tint(nb.mixc(nb.mul(tips, 0.85), hexc("#34200F"), hexc("#94704C")),
                      nb.mr(clumps, 0.3, 0.7, 0.78, 1.2))
    C = Coat(L, fur_col, nb.mr(strands, 0.3, 0.7, 0.84, 0.97), 0.0,
             nb.add(nb.add(nb.mul(strands, 0.0024), nb.mul(locks, 0.0014)), nb.mul(clumps, 0.002)))
    # the chest in the waistcoat's V is lighter, as a monkey's is
    torso = L.k(TORSO)
    front = nb.ss(nb.sub(0.0, L.ny), 0.15, 0.45)
    w = nb.add(mm(5.0), nb.mul(nb.sub(z, mm(HEM)), 0.3))
    in_v = nb.mul(front, nb.sub(1.0, nb.ss(nb.sub(ax, w), -mm(0.4), mm(0.4))))
    C.paint(nb.mul(nb.mul(torso, in_v), band(z, mm(HEM + 4), mm(156), mm(3))),
            nb.tint(nb.mixc(nb.mul(tips, 0.8), hexc("#6A4A2E"), hexc("#B08C64")),
                    nb.mr(clumps, 0.3, 0.7, 0.85, 1.12)))
    # trousers: navy and cream stripes in cotton twill, round each leg and down the lap
    trou_leg = L.k(TROUSER)
    xc = nb.add(mm(26.0), nb.mul(nb.sub(mm(2.0), y), 15.0 / 88.0))
    a_leg = nb.math("ARCTAN2", nb.sub(z, mm(26.0)), nb.sub(ax, xc))
    a_lap = nb.math("ARCTAN2", nb.sub(y, mm(12.0)), x)
    lap = nb.mul(torso, nb.sub(1.0, nb.ss(z, mm(HEM - 0.6), mm(HEM + 0.6))))
    stripe_leg = nb.ss(nb.sin(nb.mul(a_leg, 7.0)), -0.12, 0.12)
    stripe_lap = nb.ss(nb.sin(nb.mul(a_lap, 22.0)), -0.12, 0.12)
    weave = L.noise(900.0, 3, detail=1)
    twill = nb.mr(weave, 0.3, 0.7, 0.9, 1.08)
    for m, st in ((trou_leg, stripe_leg), (lap, stripe_lap)):
        C.paint(m, nb.tint(hexc("#E4D9BE"), twill), 0.82, 0.0, nb.mul(weave, 0.0003))
        C.paint(nb.mul(m, st), nb.tint(hexc("#22305A"), twill), 0.8, 0.0)
    # the waistcoat: green felt from the hem to the shoulders, open in a V, edged in gold braid
    vest = nb.mul(torso, nb.mul(band(z, mm(HEM), mm(152), mm(0.5)), nb.sub(1.0, in_v)))
    felt = L.noise(700.0, 4, detail=2)
    C.paint(vest, nb.tint(hexc("#2D5A43"), nb.mr(felt, 0.3, 0.7, 0.88, 1.1)), 0.95, 0.0,
            nb.add(0.0012, nb.mul(felt, 0.0002)))
    edge_v = nb.mul(front, nb.sub(1.0, nb.ss(nb.sub(ax, w), mm(2.6), mm(3.2))))
    edge_h = nb.sub(1.0, nb.ss(z, mm(HEM + 2.6), mm(HEM + 3.2)))
    trim = nb.mul(vest, nb.add(edge_v, edge_h, clamp=True))
    braid = nb.ss(nb.sin(nb.mul(nb.add(nb.mul(x, 1.0), z), 2 * math.pi / mm(2.2))), -0.4, 0.4)
    C.paint(trim, nb.tint(hexc("#C9A13A"), nb.mr(braid, 0, 1, 0.75, 1.1)), 0.6, 0.35,
            nb.add(0.0016, nb.mul(braid, 0.0003)))
    # vinyl: the face, hands and feet in a pale peach, satin; the ears a warmer orange
    vin = L.k(VINYL)
    mott = L.noise(30.0, 5, detail=3)
    C.paint(vin, nb.tint(hexc("#E6B496"), nb.mr(mott, 0.3, 0.7, 0.94, 1.04)), 0.42, 0.0, 0.0)
    ear = L.k(EAR)
    C.paint(ear, nb.tint(hexc("#DE955F"), nb.mr(mott, 0.3, 0.7, 0.94, 1.04)), 0.44, 0.0, 0.0)
    inner = nb.ss(nb.mul(L.nx, x), 0.0, 0.004)
    C.paint(nb.mul(ear, inner), hexc("#D3824F"), 0.46)
    # rosy cheeks either side of the grin, and the darker skin round the eyes
    face = nb.mul(vin, nb.ss(z, mm(150), mm(160)))

    def spot(cx, cz, r, soft):
        dx, dz = nb.sub(ax, mm(cx)), nb.sub(z, mm(cz))
        d2 = nb.add(nb.mul(dx, dx), nb.mul(dz, dz))
        return nb.sub(1.0, nb.ss(d2, mm(r - soft) ** 2, mm(r + soft) ** 2))

    C.paint(nb.mul(nb.mul(face, front), nb.mul(spot(20.0, 188.0, 9.0, 6.0), 0.55)), hexc("#D9767A"))
    C.paint(nb.mul(nb.mul(face, front), nb.mul(spot(16.0, 207.0, 15.5, 3.0), 0.5)), hexc("#B88068"))
    # the grin: red lips round a row of white teeth, curving up at the corners
    muz = nb.mul(nb.mul(vin, nb.ss(nb.sub(0.0, L.ny), 0.45, 0.7)), band(z, mm(164), mm(193), mm(0.5)))
    xr = nb.div(ax, mm(21.0))
    curve = nb.sub(z, nb.add(mm(176.0), nb.mul(mm(4.2), nb.mul(xr, xr))))
    hgt = nb.mul(mm(7.0), nb.sub(1.0, nb.mul(xr, xr), clamp=True))
    ac = nb.absf(curve)
    lips = nb.mul(muz, nb.ss(nb.sub(hgt, ac), 0.0, mm(0.5)))
    teeth = nb.mul(muz, nb.ss(nb.sub(nb.mul(hgt, 0.62), ac), 0.0, mm(0.35)))
    gaps = nb.ss(nb.absf(nb.sub(nb.fract(nb.add(nb.div(x, mm(4.7)), 0.5)), 0.5)), 0.4, 0.5)
    seam = nb.sub(1.0, nb.ss(ac, mm(0.25), mm(0.6)))
    C.paint(lips, hexc("#A8262A"), 0.3, 0.0, 0.0004)
    C.paint(teeth, hexc("#ECE4CF"), 0.22, 0.0, 0.0006)
    C.paint(nb.mul(teeth, nb.add(nb.mul(gaps, 0.85), seam, clamp=True)), hexc("#3A1C14"), 0.5, 0.0,
            0.0002)
    # nostrils on the muzzle's top
    C.paint(nb.mul(vin, spot(4.2, 191.0, 1.7, 0.6)), hexc("#3A2117"), 0.5)
    # the eyes: glossy, a cream white, an amber iris ringed dark, a black pupil, set wide
    eye = L.k(EYE)
    look_out = nb.ss(nb.sub(0.0, L.ny), 0.2, 0.5)
    ex, _, ez = M_["eyes"]
    C.paint(eye, hexc("#EEE7D4"), 0.07, 0.0, 0.0)
    C.paint(nb.mul(nb.mul(eye, look_out), spot(ex, ez, 7.0, 0.3)), hexc("#5C2C0E"), 0.06)
    C.paint(nb.mul(nb.mul(eye, look_out), spot(ex, ez, 6.2, 0.4)), hexc("#B2611C"), 0.06)
    C.paint(nb.mul(nb.mul(eye, look_out), spot(ex, ez, 3.4, 0.25)), hexc("#0B0806"), 0.05)
    # fez: maroon felt, its crown faded pale by years of light
    fez = L.k(FEZ)
    C.paint(fez, nb.tint(hexc("#6C1A1E"), nb.mr(felt, 0.3, 0.7, 0.85, 1.12)), 0.93, 0.0,
            nb.mul(felt, 0.0002))
    C.paint(nb.mul(fez, nb.mul(L.up, 0.45)), hexc("#8A3A35"), 0.93)
    # the tassel: black silk thread, strands hanging
    tas = L.k(TASSEL)
    thread = L.noise(520.0, 6, stretch=(1.0, 1.0, 0.06), detail=1)
    C.paint(tas, nb.tint(hexc("#16120F"), nb.mr(thread, 0.3, 0.7, 0.6, 1.6)), 0.6, 0.0,
            nb.mul(thread, 0.0005))
    # the cymbals: spun brass, tarnished in blooms, rubbed bright where they hit
    br = L.k(BRASS)
    tarn = nb.ss(L.noise(16.0, 7, detail=4), 0.5, 0.66)
    C.paint(br, nb.tint(hexc("#C79C48"), nb.mr(L.noise(80.0, 8, detail=3), 0.3, 0.7, 0.9, 1.06)),
            0.24, 1.0, 0.0)
    C.paint(nb.mul(br, tarn), hexc("#7B6232"), 0.48, 0.85)
    C.paint(nb.mul(br, nb.mul(L.edge(0.004), 0.8)), hexc("#E2BF6E"), 0.18, 1.0)
    # the key and its collar: tinplate lacquered gold, worn to steel, a few specks of rust
    tin = L.k(TIN)
    C.paint(tin, hexc("#B48D3E"), 0.3, 1.0, 0.0)
    C.paint(nb.mul(tin, nb.mul(L.edge(0.003), nb.ss(L.noise(60.0, 9, detail=3), 0.4, 0.55))),
            hexc("#A7AAAD"), 0.36, 1.0)
    C.paint(nb.mul(tin, nb.ss(L.noise(140.0, 10, detail=3), 0.7, 0.76)), hexc("#6A3A1E"), 0.85, 0.0)
    C.finish(f.dust, grime=0.6)
    return C.surface(bump_dist=0.0015, bump=0.7)


# --- how it plays -------------------------------------------------------------------------------

P_ = K.PLAY


def clashes():
    """Times of every clash: the beat r(t) slows a little across the run, then gives out."""
    r0, T_ = P_["rate"], P_["length"]
    t, ph, dt = 0.0, 1.0 - 0.17 * r0, 0.0005
    out = []
    while True:
        u = min(t / T_, 1.0)
        r = r0 * (1 - P_["fade"] * u) * max(0.0, 1 - u ** P_["knee"]) ** 0.5
        if r < 1.0 / P_["last"]:
            return out
        ph += r * dt
        t += dt
        if ph >= 1.0:
            out.append(round(t, 3))
            ph -= 1.0


def play_tracks():
    ts = clashes()
    n = len(ts)
    gaps = [b - a for a, b in zip(ts, ts[1:])]
    gaps.append(gaps[-1] * 1.15)
    p0 = 1.0 / P_["rate"]
    arm, head, eyes, tas, cym, key = [(0.0, 0.0)], [(0.0, 0.0)], [(0.0, 0.0)], [(0.0, 0.0)], [(0.0, 0.0)], []
    wound = 180.0 * P_["winds"]
    key.append((0.0, wound))
    for i, (tc, P) in enumerate(zip(ts, gaps)):
        e = max(0.25, min(1.0, (p0 / P) ** 1.3))
        arm += [(tc, -OPEN, "Quad", "In"), (tc + 0.06 * P, -OPEN + 1.8 * e, "Quad", "Out"),
                (tc + 0.55 * P, 0.0, "Sine", "InOut")]
        head += [(tc + 0.02, P_["bob"] * e, "Quad", "In"), (tc + 0.5 * P, -0.3 * P_["bob"] * e)]
        eyes += [(tc + 0.03, -P_["eyes"] * e, "Quart", "In"), (tc + 0.6 * P, 0.0)]
        ts_ = P_["tassel"] * e
        tas += [(tc + 0.02, -0.4 * ts_), (tc + 0.3 * P, ts_, "Sine", "Out"), (tc + 0.75 * P, -0.5 * ts_)]
        cym += [(tc, 0.0, "Linear", "In"), (tc + 0.03, P_["ring"] * e, "Quad", "Out"),
                (tc + 0.09, -0.45 * P_["ring"] * e), (tc + 0.16, 0.0)]
        key.append((tc, wound * (1.0 - (i + 1) / (n + 1)), "Linear", "In"))
    # the last of the spring: the arms swing in for one more and stall short, then sag apart
    tl, P = ts[-1], gaps[-1]
    stall = tl + 0.55 * P + 0.75 * P
    arm += [(stall, -0.55 * OPEN, "Sine", "Out"), (stall + 0.35, -0.55 * OPEN),
            (stall + 1.2, 0.0, "Sine", "InOut")]
    head += [(stall, 1.2), (stall + 1.2, 0.0)]
    eyes += [(stall, -3.0), (stall + 1.2, 0.0)]
    tas += [(tl + 0.75 * P + 0.4, 0.5 * P_["tassel"]), (tl + 0.75 * P + 0.8, -0.25 * P_["tassel"]),
            (tl + 0.75 * P + 1.2, 0.1 * P_["tassel"]), (stall + 1.2, 0.0)]
    key.append((stall, 0.0, "Linear", "In"))
    dur = round(stall + 1.4, 2)
    tracks = [("ArmL", "turn", arm), ("ArmR", "turn", arm), ("Head", "turn", head),
              ("Eyes", "turn", eyes), ("Tassel", "turn", tas), ("CymbalL", "turn", cym),
              ("CymbalR", "turn", cym), ("Key", "turn", key)]
    return dur, tracks, ts


def wind_tracks():
    keys, t = [(0.0, 0.0), (0.15, 0.0)], 0.15
    for i in range(P_["winds"]):
        keys += [(t + 0.34, 180.0 * (i + 1), "Sine", "InOut"), (t + 0.52, 180.0 * (i + 1))]
        t += 0.52
    return round(t + 0.2, 2), [("Key", "turn", keys)]


PLAY_DUR, PLAY_TRACKS, CLASHES = play_tracks()
WIND_DUR, WIND_TRACKS = wind_tracks()
NECK = V(*M_["neck"])
EYES_AT = V(0.0, *M_["eyes"][1:])
SL, AL = arm_axis(1)
SR, AR = arm_axis(-1)


def cym_axis(sx):
    return tuple((arm_open(sx).to_3x3() @ cym_m(sx).to_3x3() @ Vector((1.0, 0.0, 0.0))))


CYMBAL_MONKEY = kit.Find(
    "CymbalMonkey",
    [kit.Part("Body", m_body),
     kit.Part("Head", m_head, tuple(NECK), "Body", (1, 0, 0)),
     kit.Part("Eyes", m_eyes, tuple(EYES_AT), "Head", (1, 0, 0)),
     kit.Part("Tassel", m_tassel, tuple(fez_edge()), "Head", (1, 0, 0)),
     kit.Part("ArmL", m_arm(1), tuple(SL), "Body", tuple(AL)),
     kit.Part("ArmR", m_arm(-1), tuple(SR), "Body", tuple(AR)),
     kit.Part("CymbalL", m_cymbal(1), tuple(strap_at(1)), "ArmL", cym_axis(1)),
     kit.Part("CymbalR", m_cymbal(-1), tuple(strap_at(-1)), "ArmR", cym_axis(-1)),
     kit.Part("Key", m_key, tuple(V(*M_["key"]["at"])), "Body", (0, -1, 0))],
    monkey_look,
    motions={
        # the key wound clockwise in four half turns, a regrip between each
        "Wind": dict(duration=WIND_DUR, focus="Key", distance=0.55, view=(1.2, 2.0, 0.6),
                     drop=0.0, tracks=WIND_TRACKS),
        # twenty seconds of clashing: arms slam in square and bounce off, the head nods and the
        # eyes roll up wide on every hit, the tassel flings about, the cymbals ring on their
        # straps and the key creeps back; the beat slows, tires, and the last one stalls short
        "Play": dict(duration=PLAY_DUR, focus=(0.0, mm(-20.0), mm(150.0)), distance=0.95,
                     tracks=PLAY_TRACKS),
    },
    dust=M_["dust"], seed=M_["seed"], texels=450,
)

# --- The jack-in-the-box (F-04b) ----------------------------------------------------------------
# A tin music box of the 1950s (README): a printed tin cube with rolled corner seams, a shallow
# lid on a wire hinge at the back, painted yellow inside and held shut by a sprung catch at the
# front, a wire crank with a turned knob on the right side, and a clown on a cloth-covered spring
# inside. Crank it and the tune plays; a beat after the last note the catch lets go, the lid bangs
# open on its stop and the jack springs out, bobs, sways and settles with its head cocked at you.
# The lid and the jack are drawn open and popped up (as baked, so the jack is lit, not shaded by
# the box shut over it); as found, the lid is turned shut and the jack squeezed down inside.

J_ = K.JACK
TU = K.TUNE
(LITHO, INSIDE, LIDTOP, LIDIN, STEEL, NICKEL, KNOB, SACK, RUFF, RUFF2, FACE, NOSE, HAIR, HAT,
 POM) = range(10, 25)

BW, BH = J_["box"]
LO = J_["lid"]
OPEN_LID = LO["open"]
HINGE = V(*LO["hinge"])
LID_TOP = BH + LO["top"]                 # the lid's top, shut (mm)
LID_FOOT = LID_TOP - LO["skirt"]         # the bottom of its skirt
CR = J_["crank"]
CRANK_AT = V(*CR["at"])
LATCH_AT = V(*J_["latch"]["pivot"])
FLOOR, NECK = J_["floor"], J_["neck"]
SC0, ST0 = J_["closed"]
HAT_AT, HAT_TILT = (5.0, 1.0, 253.0), 20.0


def rsq(hw, z, r, n):
    """A rounded square's outline at height z (mm), anticlockwise from above, n steps a corner."""
    r = min(r, hw - 0.01)
    pts = []
    for q, (sx, sy) in enumerate(((1, 1), (-1, 1), (-1, -1), (1, -1))):
        cx, cy = sx * (hw - r), sy * (hw - r)
        for i in range(n + 1):
            a = math.radians(90 * q + 90 * i / n)
            pts.append((mm(cx + r * math.cos(a)), mm(cy + r * math.sin(a)), mm(z)))
    return pts


def rounded(pts, r, n):
    """A polyline (Vectors) with each inside corner rounded by a curve r long each way."""
    out = [pts[0]]
    for a, b, c in zip(pts, pts[1:], pts[2:]):
        u, w = (a - b), (c - b)
        ru, rw = min(r, u.length * 0.45), min(r, w.length * 0.45)
        p, q = b + u.normalized() * ru, b + w.normalized() * rw
        for i in range(n + 1):
            t = i / n
            out.append((1 - t) ** 2 * p + 2 * (1 - t) * t * b + t * t * q)
    out.append(pts[-1])
    return out


def strip(s, path, x0, x1, t, kind, M=Matrix()):
    """A bent tin strip: its middle line [(y, z)] in mm, t thick, from x0 to x1, placed by M."""
    bm = bmesh.new()
    P = [Vector(p) for p in path]
    n = len(P)
    rows = []
    for i, p in enumerate(P):
        d = (P[min(i + 1, n - 1)] - P[max(i - 1, 0)]).normalized()
        o = Vector((-d.y, d.x)) * (t / 2)
        rows.append([bm.verts.new((mm(x), mm(c.x), mm(c.y))) for x in (x0, x1) for c in (p + o, p - o)])
    for A, B in zip(rows, rows[1:]):
        for i, j in ((0, 2), (2, 3), (3, 1), (1, 0)):
            bm.faces.new((A[i], A[j], B[j], B[i]))
    for R in (rows[0], rows[-1]):
        bm.faces.new((R[0], R[2], R[3], R[1]))
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bmesh.ops.transform(bm, matrix=M, verts=bm.verts)
    s.merge(bm, kind)
    bm.free()


def rivet(s, at, facing, r, kind, hi):
    """A domed rivet head at `at` (mm) on a face whose outward normal is `facing` ('-Y', '+Y')."""
    R = {"-Y": Matrix.Rotation(math.radians(90), 4, "X"),
         "+Y": Matrix.Rotation(math.radians(-90), 4, "X")}[facing]
    prof = [(r, -0.4), (r, 0.1), (r * 0.8, 0.55), (r * 0.42, 0.85), (0.0, 0.92)]
    s.lathe([(mm(a), mm(b)) for a, b in prof], kind, segs(hi, 10), T(V(*at)) @ R)


def jb_box(hi):
    s = Shape()
    n = 4 if hi else 2
    c, H = J_["corner"], BH
    # outside: the floor, the rolled bead at the foot, the printed walls, the neck the lid sits
    # on, and the rolled rim; then down inside to the floor
    rows = [(0.0, 64.6, 1.5), (0.5, 66.7, 2.6), (1.6, 67.3, 3.0), (3.6, 67.35, 3.0),
            (5.0, 66.8, 3.0), (5.8, 66.5, c), (H - 7.4, 66.5, c), (H - 6.4, 66.05, c - 0.4),
            (H - 1.4, 66.05, c - 0.4), (H - 0.3, 66.3, c - 0.3), (H + 0.35, 65.9, c - 0.6),
            (H + 0.2, 65.2, c - 1.0)]
    s.loft([[(0.0, 0.0, 0.0)]] + [rsq(hw, z, r, n) for z, hw, r in rows], LITHO)
    rows = [(H + 0.2, 65.2, c - 1.0), (H - 1.6, 65.0, c - 1.0), (6.5, 65.0, c - 1.0),
            (FLOOR, 64.0, c - 1.2)]
    s.loft([rsq(hw, z, r, n) for z, hw, r in rows] + [[(0.0, 0.0, mm(FLOOR))]], INSIDE)
    # the crank's pressed bushing on the right side
    prof = [(8.6, -0.8), (8.5, 0.25), (7.4, 0.7), (4.3, 1.05), (3.3, 1.5), (2.4, 1.75), (0.0, 1.75)]
    s.lathe([(mm(a), mm(b)) for a, b in prof], STEEL, segs(hi, 20),
            T(CRANK_AT) @ Matrix.Rotation(math.radians(90), 4, "Y"))
    # the hinge: two tin straps riveted to the back, joggled out behind the lid's skirt and
    # rolled round the pin; the pin through every knuckle, peened at its ends
    hy, hz = LO["hinge"][1:]
    for sx in (1, -1):
        x0, x1 = sorted((sx * 40.0, sx * 52.0))
        path = [(66.85, 118.0), (66.85, 129.3), (hy - 0.7, 131.0), (hy - 0.7, hz)]
        strip(s, rounded([Vector(p) for p in path], 1.2, 3 if hi else 1), x0, x1, 0.6, STEEL)
        s.cylinder(V(x0, hy, hz), V(x1, hy, hz), mm(1.55), STEEL, segs(hi, 10))
        rivet(s, (sx * 46.0, 67.15, 122.0), "+Y", 1.9, STEEL, hi)
    s.cylinder(V(-58.8, hy, hz), V(58.8, hy, hz), mm(0.75), STEEL, segs(hi, 6))
    for sx in (1, -1):
        s.cylinder(V(sx * 58.6, hy, hz), V(sx * 59.4, hy, hz), mm(1.05), STEEL, segs(hi, 8))
    # the catch's rivet, on the front below the lid
    rivet(s, (0.0, -67.45, J_["latch"]["pivot"][2]), "-Y", 2.2, STEEL, hi)
    return s


def lid_open():
    return about(HINGE, Matrix.Rotation(math.radians(OPEN_LID), 4, Vector((-1.0, 0.0, 0.0))))


def jb_lid(hi):
    s = Shape()
    n = 4 if hi else 2
    o, tp, zb = LO["over"], LID_TOP, LID_FOOT
    Mo = lid_open()
    rows = [(zb, o - 0.6, 3.0), (zb + 0.2, o + 0.15, 3.5), (zb + 1.1, o + 0.25, 3.5),
            (zb + 1.9, o, 3.4), (tp - 0.8, o, 3.4), (tp - 0.2, o - 0.6, 3.0), (tp, o - 2.2, 2.4),
            (tp + 0.15, o - 9.0, 1.8)]
    s.loft([rsq(hw, z, r, n) for z, hw, r in rows] + [[(0.0, 0.0, mm(tp + 0.35))]], LIDTOP, Mo)
    rows = [(tp - 0.55, o - 9.0, 1.8), (tp - 0.6, o - 0.9, 2.6), (zb + 0.6, o - 0.9, 2.6),
            (zb, o - 0.6, 3.0)]
    s.loft([[(0.0, 0.0, mm(tp - 0.5))]] + [rsq(hw, z, r, n) for z, hw, r in rows], LIDIN, Mo)
    # its knuckles: tabs off the back edge rolled round the pin, between the box's straps
    hy, hz = LO["hinge"][1:]
    for x0, x1 in ((-38.5, 38.5), (53.0, 58.0), (-58.0, -53.0)):
        strip(s, [(63.5, tp + 0.2), (67.4, tp + 0.2), (hy - 0.6, hz + 1.3)], x0, x1, 0.6, LIDTOP, Mo)
        s.cylinder(V(x0, hy, hz), V(x1, hy, hz), mm(1.55), LIDTOP, segs(hi, 10), M=Mo)
    return s


def jb_latch(hi):
    s = Shape()
    w = J_["latch"]["w"] / 2
    py, pz = J_["latch"]["pivot"][1:]
    # a thumb tab flared out at the foot, flat on the box, joggled out over the lid's skirt and
    # hooked over its front edge
    path = [(py - 1.9, pz - 3.4), (py + 0.35, pz - 1.0), (py + 0.35, 129.3), (-68.6, 130.9),
            (-68.6, LID_TOP + 0.5), (-64.6, LID_TOP + 0.5)]
    strip(s, rounded([Vector(p) for p in path], 1.0, 3 if hi else 1), -w, w, 0.6, NICKEL)
    return s


def crank_path():
    a = math.radians(20.0)
    d = Vector((0.0, math.sin(a), -math.cos(a)))   # the arm's way as found: down, a little back
    ax, ay, az = CR["at"]
    p1 = V(ax + 5.3, ay, az)
    p2 = p1 + d * mm(CR["arm"])
    return [V(ax + 2.0, ay, az), p1, p2, p2 + V(CR["out"] + 2.5, 0.0, 0.0)], p2


def jb_crank(hi):
    s = Shape()
    ax, ay, az = CR["at"]
    s.cylinder(V(ax - 0.6, ay, az), V(ax + 4.0, ay, az), mm(2.0), STEEL, segs(hi, 10))
    s.cylinder(V(ax + 1.1, ay, az), V(ax + 3.6, ay, az), mm(3.3), STEEL, segs(hi, 12))
    pts, p2 = crank_path()
    s.tube(rounded(pts, mm(3.0), 4 if hi else 2), mm(1.5), STEEL, segs(hi, 8))
    r, ln = CR["knob"]
    prof = [(0.0, 0.0), (2.8, 0.0), (3.6, 0.4), (4.6, 1.6), (5.6, 3.6), (r, 6.8), (r - 0.2, 10.0),
            (r - 0.8, 12.8), (r - 1.9, 14.8), (r - 3.4, ln - 0.2), (0.0, ln)]
    s.lathe([(mm(a), mm(b)) for a, b in prof], KNOB, segs(hi, 18),
            T(p2 + V(1.4, 0.0, 0.0)) @ Matrix.Rotation(math.radians(90), 4, "Y"))
    return s


SACK_ROWS = [(5.2, 23.0), (8.0, 27.0), (16.0, 28.5), (60.0, 29.0), (110.0, 29.6), (140.0, 30.4),
             (162.0, 31.0), (180.0, 30.2), (193.0, 28.0), (201.0, 21.5), (206.0, 14.5),
             (209.5, 9.5)]


def ruff(s, z0, r0, r1, drop, pleats, amp, kind, hi, phase=0.0):
    """A pleated collar round the neck: out along its underside, round its edge, back along its
    top; its pleats rise and fall more towards the edge."""
    mid = (r0 + r1) / 2
    prof = [(r0, z0 - 3.0), (mid, z0 - 3.0 - drop * 0.45), (r1 - 1.0, z0 - 2.2 - drop),
            (r1, z0 - 1.3 - drop), (r1 - 1.0, z0 - 0.5 - drop), (mid, z0 - drop * 0.45 + 0.3),
            (r0, z0 + 0.4)]
    n = pleats * (12 if hi else 6)
    rings = []
    for r, z in prof:
        a = amp * ((r - r0) / (r1 - r0)) ** 1.2
        ring = []
        for j in range(n):
            th = 2 * math.pi * j / n
            w = math.sin(pleats * th + phase)
            rr = r + 0.35 * a * math.cos(pleats * th + phase)
            ring.append((mm(rr * math.cos(th)), mm(rr * math.sin(th)), mm(z + a * w)))
        rings.append(ring)
    s.loft(rings, kind)


def jb_jack(hi):
    s = Shape()
    rows = smooth_rows(SACK_ROWS, 8 if hi else 5)
    n = segs(hi, 28)
    rings = [[(0.0, 0.0, mm(FLOOR))]]
    for z, r in rows:
        ring = []
        gather = min(1.0, max(0.0, (z - 194.0) / 10.0))
        coil = 0.0
        if 12.0 < z < 192.0:
            coil = 1.7 * max(0.0, math.cos(2 * math.pi * (z - 12.0) / 18.5)) ** 3 * min(1.0, (192.0 - z) / 10.0)
        for j in range(n):
            th = 2 * math.pi * j / n
            fold = (0.065 * (1 - gather) * math.sin(7 * th + 0.9 * math.sin(z / 26.0))
                    + 0.08 * gather * math.sin(14 * th + 0.4))
            if hi:
                fold += 0.018 * (1 - gather) * math.sin(12 * th + 2.1 + z / 15.0)
            rr = r * (1 + fold) + coil
            ring.append((mm(rr * math.cos(th)), mm(rr * math.sin(th)), mm(z)))
        rings.append(ring)
    rings.append([(0.0, 0.0, mm(211.0))])
    s.loft(rings, SACK)
    ruff(s, 207.0, 10.0, 40.0, 7.0, 13, 3.6, RUFF, hi)
    ruff(s, 212.5, 8.6, 29.5, 5.0, 10, 3.0, RUFF2, hi, phase=1.3)
    return s


HEAD_ROWS = [(212.5, 8.0, 7.0, -3.5), (215.0, 14.5, 12.5, -3.5), (219.0, 19.5, 17.5, -3.0),
             (224.0, 23.0, 21.0, -2.2), (230.0, 24.8, 22.6, -1.5), (236.0, 25.2, 23.0, -1.0),
             (242.0, 24.6, 22.8, -0.5), (248.0, 22.4, 21.2, 0.0), (253.0, 18.5, 18.0, 0.3),
             (257.0, 12.5, 12.5, 0.5)]


def hat_m():
    return T(V(*HAT_AT)) @ Matrix.Rotation(math.radians(HAT_TILT), 4, "Y")


def jb_head(hi):
    s = Shape()
    s.cylinder(V(0.0, -0.5, 203.0), V(0.0, -0.5, 214.0), mm(8.4), FACE, segs(hi, 14))
    rows = smooth_rows(HEAD_ROWS, 3 if hi else 1)
    nn = segs(hi, 24)
    rings = [[(0.0, mm(-3.0), mm(211.5))]]
    for z, rx, ry, cy in rows:
        rings.append([(mm(rx * math.cos(2 * math.pi * j / nn)),
                       mm(cy + ry * math.sin(2 * math.pi * j / nn)), mm(z)) for j in range(nn)])
    rings.append([(0.0, mm(0.5), mm(259.4))])
    s.loft(rings, FACE)
    blob(s, (0.0, -27.0, 232.5), (6.3, 6.3, 6.3), NOSE, hi, lat=10, lon=20)
    for sx in (1, -1):
        blob(s, (sx * 24.4, 0.5, 228.0), (3.0, 5.6, 7.0), FACE, hi, lat=6, lon=12)
        # tufts of yarn hair over the ears
        blob(s, (sx * 21.5, 7.0, 245.0), (9.5, 10.5, 8.0), HAIR, hi, lat=8, lon=16)
        blob(s, (sx * 24.0, 3.0, 240.0), (6.5, 8.5, 6.5), HAIR, hi, lat=8, lon=14)
        blob(s, (sx * 19.5, 11.5, 238.5), (8.0, 8.0, 7.5), HAIR, hi, lat=8, lon=14)
        if hi:
            blob(s, (sx * 25.5, 7.0, 245.5), (5.0, 6.0, 5.0), HAIR, hi, lat=6, lon=10)
            blob(s, (sx * 17.0, 13.0, 247.5), (6.0, 6.0, 5.0), HAIR, hi, lat=6, lon=10)
    # the cap: a felt cone with a rolled band, leaning, its tip bent further, a wool pompom
    rows = [(-3.0, 13.0), (0.0, 13.6), (1.0, 13.8), (2.2, 13.3), (12.0, 10.0), (24.0, 5.8),
            (33.0, 2.4), (35.5, 0.9)]
    nh = segs(hi, 20)
    rings = []
    for z, r in rows:
        cx = 5.0 * (max(z, 0.0) / 36.0) ** 2
        rings.append([(mm(cx + r * math.cos(2 * math.pi * j / nh)),
                       mm(r * math.sin(2 * math.pi * j / nh)), mm(z)) for j in range(nh)])
    rings.append([(mm(5.0), 0.0, mm(36.0))])
    s.loft(rings, HAT, hat_m(), cap_bottom=HAT)
    blob(s, (5.2, 0.0, 38.0), (6.2, 6.2, 5.8), POM, hi, hat_m(), 8, 16)
    return s


def jack_look(L, f):
    nb = L.nb
    xm, ym, zm = nb.mul(L.x, K.STUD_MM), nb.mul(L.y, K.STUD_MM), nb.mul(L.z, K.STUD_MM)
    ax, ay = nb.absf(xm), nb.absf(ym)

    def sq(v):
        return nb.mul(v, v)

    def disc(u, v, cu, cv, r, soft=0.25):
        """1 inside the circle (mm) at (cu, cv) of the coordinates u, v."""
        d = nb.math("SQRT", nb.add(sq(nb.sub(u, cu)), sq(nb.sub(v, cv))))
        return nb.sub(1.0, nb.ss(d, r - soft, r + soft))

    grain = L.noise(500.0, 1, detail=1)
    C = Coat(L, hexc("#EDE0BF"), 0.3, 0.0, 0.0)

    # --- the box's printed sides: each a coloured border of cream marquee dots round a cream
    # panel with a playing card's suit, the four suits round the box; tin shows at the knocks
    litho = L.k(LITHO)
    fr, bk = nb.ss(nb.sub(0.0, L.ny), 0.6, 0.8), nb.ss(L.ny, 0.6, 0.8)
    rt, lf = nb.ss(L.nx, 0.6, 0.8), nb.ss(nb.sub(0.0, L.nx), 0.6, 0.8)
    side = nb.mul(litho, nb.mx(nb.mx(fr, bk), nb.mx(rt, lf)))
    u = nb.add(nb.mul(ax, nb.mx(fr, bk)), nb.mul(ay, nb.mx(rt, lf)))
    zc = (6.5 + BH - 7.8) / 2
    v = nb.sub(zm, zc)
    rc = 6.0
    qx = nb.mx(nb.sub(u, 56.5 - rc), 0.0)
    qz = nb.mx(nb.sub(nb.absf(v), 50.85 - rc), 0.0)
    d = nb.sub(nb.math("SQRT", nb.add(sq(qx), sq(qz))), rc)   # mm outside the panel's edge
    border = nb.ss(d, 1.6, 1.9)
    key = nb.mul(nb.ss(d, -0.75, -0.55), nb.sub(1.0, nb.ss(d, -0.05, 0.15)))
    cols = ((fr, "#B4342B"), (rt, "#2F7448"), (bk, "#2C568F"), (lf, "#D49A2B"))
    tone = nb.mr(grain, 0.3, 0.7, 0.95, 1.04)
    C.paint(litho, nb.tint(hexc("#EDE0BF"), tone), 0.3, 0.0, 0.0)
    for m, c in cols:
        C.paint(nb.mul(nb.mul(side, m), border), nb.tint(hexc(c), tone), 0.3)
    # the marquee's dots along the middle of the border
    hz = nb.add(sq(nb.mul(nb.sub(nb.fract(nb.add(nb.div(u, 8.0), 0.5)), 0.5), 8.0)),
                sq(nb.sub(nb.absf(v), 56.75)))
    vz = nb.add(sq(nb.mul(nb.sub(nb.fract(nb.add(nb.div(v, 8.0), 0.5)), 0.5), 8.0)),
                sq(nb.sub(u, 62.4)))
    dots = nb.sub(1.0, nb.ss(nb.mn(hz, vz), 1.7 ** 2, 2.1 ** 2))
    C.paint(nb.mul(nb.mul(side, border), dots), hexc("#F2E5C0"), 0.3)
    C.paint(nb.mul(side, key), hexc("#1E1A19"), 0.3)
    # the panel: faint rays behind the suit
    R = 24.0
    X, Y = nb.div(u, R), nb.div(nb.sub(v, 2.0), R)
    ang = nb.math("ARCTAN2", Y, nb.add(X, 0.0001))
    rays = nb.ss(nb.sin(nb.mul(ang, 16.0)), -0.2, 0.2)
    panel = nb.mul(side, nb.sub(1.0, nb.ss(d, -0.8, -0.6)))
    C.paint(nb.mul(panel, nb.mul(rays, 0.5)), hexc("#E3D2A6"), 0.3)

    def stem(top):
        w = nb.add(0.09, nb.mul(nb.mx(nb.sub(top, Y), 0.0), 0.62))
        inside = nb.sub(1.0, nb.ss(nb.sub(X, w), -0.02, 0.02))
        return nb.mul(inside, nb.mul(nb.ss(Y, -1.47, -1.43), nb.sub(1.0, nb.ss(Y, top - 0.05, top))))

    def lobes(Yl, cy):
        """Two round lobes on a triangle coming to a point 1.35 below them (Yl up)."""
        c = disc(X, Yl, 0.47, cy, 0.5, 0.012)
        tri = nb.sub(1.0, nb.ss(nb.sub(nb.mul(X, 1.42), nb.add(Yl, 1.35 - cy)), -0.015, 0.015))
        under = nb.sub(1.0, nb.ss(Yl, cy - 0.02, cy + 0.02))
        return nb.mx(c, nb.mul(tri, under))

    hrt = lobes(Y, 0.3)
    spade = nb.mx(lobes(nb.sub(0.0, Y), 0.25), stem(-0.45))
    diam = nb.sub(1.0, nb.ss(nb.add(nb.div(X, 0.78), nb.div(nb.absf(Y), 1.12)), 0.985, 1.015))
    club = nb.mx(nb.mx(disc(X, Y, 0.0, 0.52, 0.47, 0.012), disc(X, Y, 0.5, -0.18, 0.47, 0.012)),
                 nb.mx(disc(X, Y, 0.0, 0.05, 0.3, 0.012), stem(-0.3)))
    for m, pip, c in ((fr, spade, "#1D1B1C"), (rt, hrt, "#B92B26"), (bk, diam, "#B92B26"),
                      (lf, club, "#1D1B1C")):
        C.paint(nb.mul(nb.mul(panel, m), pip), nb.tint(hexc(c), tone), 0.28)
    # the bottom and the rim: bare tin, gold-lacquered
    bare = nb.mul(litho, nb.mx(nb.ss(nb.sub(0.0, L.nz), 0.6, 0.8),
                               nb.mul(nb.ss(L.nz, 0.5, 0.8), nb.ss(zm, BH - 2.0, BH - 1.0))))
    C.paint(bare, hexc("#A08A5A"), 0.38, 1.0)
    # inside: gold-lacquered tinplate, never printed
    C.paint(L.k(INSIDE), nb.tint(hexc("#9C8650"), nb.mr(grain, 0.3, 0.7, 0.9, 1.05)), 0.42, 1.0)

    # --- the lid: worked out where it lies shut (it's drawn open)
    lid = nb.mx(L.k(LIDTOP), L.k(LIDIN))
    cb, sb = math.cos(math.radians(OPEN_LID)), math.sin(math.radians(OPEN_LID))
    hy, hz = LO["hinge"][1:]
    qy = nb.add(hy, nb.sub(nb.mul(nb.sub(ym, hy), cb), nb.mul(nb.sub(zm, hz), sb)))
    qn = nb.add(nb.mul(L.ny, sb), nb.mul(L.nz, cb))          # its up, shut
    top = nb.mul(L.k(LIDTOP), nb.ss(qn, 0.6, 0.8))
    rr = nb.math("SQRT", nb.add(sq(xm), sq(qy)))
    la = nb.math("ARCTAN2", qy, xm)
    burst = nb.ss(nb.sin(nb.mul(la, 12.0)), -0.08, 0.08)
    C.paint(L.k(LIDTOP), nb.tint(hexc("#B4342B"), tone), 0.3)
    C.paint(nb.mul(top, burst), nb.tint(hexc("#E7B83A"), tone), 0.3)
    C.paint(nb.mul(top, nb.sub(1.0, burst)), nb.tint(hexc("#C23A2C"), tone), 0.3)
    edge_band = nb.ss(nb.mx(ax, nb.absf(qy)), 60.5, 61.0)
    C.paint(nb.mul(top, edge_band), nb.tint(hexc("#B4342B"), tone), 0.3)
    C.paint(nb.mul(top, nb.mul(edge_band, nb.sub(1.0, nb.ss(nb.mx(ax, nb.absf(qy)), 61.8, 62.2)))),
            hexc("#F2E5C0"), 0.3)
    C.paint(nb.mul(top, nb.sub(1.0, nb.ss(rr, 18.0, 18.3))), hexc("#1E1A19"), 0.3)
    C.paint(nb.mul(top, nb.sub(1.0, nb.ss(rr, 16.8, 17.1))), nb.tint(hexc("#EDE0BF"), tone), 0.3)
    tri = nb.mul(nb.absf(nb.sub(nb.fract(nb.sub(nb.mul(la, 5.0 / (2 * math.pi)), 0.25)), 0.5)), 2.0)
    star = nb.sub(1.0, nb.ss(nb.sub(rr, nb.add(4.2, nb.mul(nb.pw(tri, 1.6), 5.6))), -0.15, 0.15))
    C.paint(nb.mul(top, star), hexc("#1E1A19"), 0.3)
    C.paint(L.k(LIDIN), nb.tint(hexc("#E2BE3E"), nb.mr(grain, 0.3, 0.7, 0.92, 1.04)), 0.45)

    # --- knocks: the print chipped to tin on the edges, rust where it sat on damp floors
    printed = nb.mx(litho, L.k(LIDTOP))
    chips = nb.mul(nb.mul(printed, L.edge(mm(1.3), k=4.0)),
                   nb.ss(L.noise(150.0, 3, detail=4), 0.5, 0.58))
    C.paint(chips, hexc("#A9A8A0"), 0.3, 1.0, -0.0002)
    scratch = nb.ss(L.noise(260.0, 4, stretch=(1.0, 0.06, 0.06), detail=2), 0.71, 0.74)
    C.paint(nb.mul(nb.mul(printed, scratch), 0.55), hexc("#B9B3A2"), 0.36, 0.6)
    rust = nb.mul(nb.mx(nb.mul(litho, nb.sub(1.0, nb.ss(zm, 6.0, 9.0))), nb.mul(L.k(LIDIN), 0.4)),
                  nb.ss(L.noise(90.0, 5, detail=4), 0.62, 0.7))
    C.paint(rust, hexc("#6B3A1F"), 0.85, 0.0)

    # --- steel and nickel: the hinge, the crank's wire and bushing, the catch
    st = L.k(STEEL)
    C.paint(st, nb.tint(hexc("#8E9092"), nb.mr(L.noise(80.0, 6, detail=3), 0.3, 0.7, 0.85, 1.08)),
            0.36, 1.0)
    C.paint(nb.mul(st, nb.ss(L.noise(120.0, 7, detail=4), 0.66, 0.72)), hexc("#6E3B1E"), 0.8, 0.0)
    ni = L.k(NICKEL)
    C.paint(ni, hexc("#C2C1BA"), 0.22, 1.0)
    C.paint(nb.mul(ni, nb.ss(L.noise(140.0, 8, detail=4), 0.6, 0.66)), hexc("#8C8576"), 0.5, 1.0)
    # the knob: turned wood painted red, rubbed to the wood at its end
    kn = L.k(KNOB)
    C.paint(kn, nb.tint(hexc("#B0281F"), tone), 0.38)
    worn = nb.mul(kn, nb.mul(nb.ss(xm, CR["at"][0] + 26.0, CR["at"][0] + 29.0),
                             nb.ss(L.noise(60.0, 9, detail=3), 0.4, 0.55)))
    C.paint(worn, hexc("#C4975E"), 0.6)

    # --- the jack: harlequin cloth over the spring, a two-tier ruff, a crazed painted face
    sk = L.k(SACK)
    ang2 = nb.math("ARCTAN2", ym, xm)
    harl = nb.sub(nb.cos(nb.mul(nb.sub(zm, 150.0), 2 * math.pi / 40.0)), nb.cos(nb.mul(ang2, 8.0)))
    weave = L.noise(900.0, 10, detail=1)
    cloth = nb.mr(weave, 0.3, 0.7, 0.88, 1.08)
    C.paint(sk, nb.tint(hexc("#E9DEC2"), cloth), 0.9, 0.0, nb.mul(weave, 0.00025))
    C.paint(nb.mul(sk, nb.ss(harl, -0.06, 0.06)), nb.tint(hexc("#A52A27"), cloth), 0.9)
    C.paint(nb.mul(sk, nb.sub(1.0, nb.ss(nb.absf(harl), 0.05, 0.11))), hexc("#2A1D1A"), 0.9)
    r_ax = nb.math("SQRT", nb.add(sq(xm), sq(ym)))
    r1 = L.k(RUFF)
    C.paint(r1, nb.tint(hexc("#EBE2CC"), cloth), 0.85, 0.0, nb.mul(weave, 0.0002))
    C.paint(nb.mul(r1, nb.ss(r_ax, 36.8, 37.4)), nb.tint(hexc("#B8322B"), cloth), 0.85)
    r2 = L.k(RUFF2)
    C.paint(r2, nb.tint(hexc("#B8322B"), cloth), 0.85, 0.0, nb.mul(weave, 0.0002))
    C.paint(nb.mul(r2, nb.ss(r_ax, 26.0, 26.6)), nb.tint(hexc("#EBE2CC"), cloth), 0.85)

    fc = L.k(FACE)
    crack = nb.sub(1.0, nb.ss(nb.voronoi(L.vec(s=11.0), 70.0, feature="DISTANCE_TO_EDGE"), 0.02, 0.07))
    crack2 = nb.sub(1.0, nb.ss(nb.voronoi(L.vec(s=12.0), 150.0, feature="DISTANCE_TO_EDGE"), 0.02, 0.06))
    C.paint(fc, nb.tint(hexc("#EEE7D7"), nb.mr(L.noise(40.0, 13, detail=3), 0.3, 0.7, 0.93, 1.03)),
            0.34, 0.0, 0.0)
    C.paint(nb.mul(fc, nb.mul(nb.mx(crack, nb.mul(crack2, 0.6)), 0.7)), hexc("#8E7C62"), 0.6, 0.0,
            -0.00015)
    front = nb.mul(fc, nb.ss(nb.sub(0.0, L.ny), 0.2, 0.45))
    for sx in (1, -1):
        ex = nb.sub(xm, sx * 9.0)
        dz = nb.sub(zm, 239.5)
        # a blue harlequin diamond through each eye, the eye an upright black almond with a glint
        dia = nb.sub(1.0, nb.ss(nb.add(nb.div(nb.absf(ex), 6.0), nb.div(nb.absf(dz), 12.0)), 0.97, 1.03))
        C.paint(nb.mul(front, dia), hexc("#2E5E9C"), 0.3)
        eye = nb.sub(1.0, nb.ss(nb.add(sq(nb.div(ex, 3.9)), sq(nb.div(dz, 5.4))), 0.92, 1.08))
        C.paint(nb.mul(front, eye), hexc("#141213"), 0.14)
        C.paint(nb.mul(front, disc(xm, zm, sx * 9.0 - 1.2, 241.4, 1.0, 0.2)), hexc("#F4F0E6"), 0.12)
        brow = nb.mul(nb.sub(1.0, nb.ss(nb.absf(nb.sub(nb.math("SQRT", nb.add(sq(ex), sq(nb.sub(zm, 240.0)))), 10.5)), 0.4, 0.6)),
                      nb.ss(zm, 247.0, 248.0))
        C.paint(nb.mul(front, brow), hexc("#141213"), 0.2)
        C.paint(nb.mul(front, nb.mul(disc(xm, zm, sx * 14.5, 227.0, 5.2, 2.5), 0.6)), hexc("#DE7A73"), 0.34)
    # the grin: red, its corners drawn up into the cheeks, outlined, the lips' seam through it
    mz = nb.add(222.0, nb.mul(sq(xm), 0.036))
    th = nb.add(nb.mul(nb.sub(1.0, sq(nb.div(xm, 17.0)), clamp=True), 3.8), 0.5)
    off = nb.absf(nb.sub(zm, mz))
    lips = nb.mul(front, nb.sub(1.0, nb.ss(nb.sub(off, nb.mul(th, 0.5)), -0.1, 0.1)))
    line = nb.mul(front, nb.sub(1.0, nb.ss(nb.sub(off, nb.add(nb.mul(th, 0.5), 0.55)), -0.1, 0.1)))
    span = nb.sub(1.0, nb.ss(ax, 17.5, 18.5))
    C.paint(nb.mul(line, span), hexc("#1E1414"), 0.25)
    C.paint(nb.mul(lips, span), hexc("#B11E22"), 0.22)
    C.paint(nb.mul(nb.mul(front, span), nb.sub(1.0, nb.ss(off, 0.25, 0.45))), hexc("#4A1210"), 0.3)
    nose = L.k(NOSE)
    C.paint(nose, hexc("#C01D1D"), 0.2)
    C.paint(nb.mul(nose, nb.ss(L.noise(80.0, 14, detail=3), 0.68, 0.72)), hexc("#E6DCC4"), 0.5)
    hair = L.k(HAIR)
    yarn = L.noise(320.0, 15, detail=3, rough=0.7)
    C.paint(hair, nb.tint(hexc("#C9561F"), nb.mr(yarn, 0.3, 0.7, 0.7, 1.2)), 0.92, 0.0,
            nb.mul(yarn, 0.0012))
    hat = L.k(HAT)
    felt = L.noise(700.0, 16, detail=2)
    C.paint(hat, nb.tint(hexc("#2E6A5E"), nb.mr(felt, 0.3, 0.7, 0.86, 1.1)), 0.95, 0.0,
            nb.mul(felt, 0.0002))
    pom = L.k(POM)
    wool = L.noise(380.0, 17, detail=3, rough=0.7)
    C.paint(pom, nb.tint(hexc("#E7DCC2"), nb.mr(wool, 0.3, 0.7, 0.8, 1.08)), 1.0, 0.0,
            nb.mul(wool, 0.0012))
    C.finish(f.dust, grime=0.5)
    return C.surface(bump_dist=0.0012, bump=0.7)


# --- how it plays -------------------------------------------------------------------------------

def jack_wind():
    """The crank turns all through the tune, a quicker push and a slower pull each turn as a
    hand cranks, slows on its last half turn as the last note sounds, and stops; then a beat of
    nothing in which the lid lifts against its catch, once."""
    lead, length, beat = TU["lead"], TU["length"], TU["beat"]
    t_end = lead + length
    total = 360.0 * TU["turns"]
    crank = [(0.0, 0.0), (0.16, -8.0), (lead + 0.12, 50.0, "Quad", "In")]
    a, t = 50.0, lead + 0.12
    last = 0.95
    n = int((total - a - 100.0) // 180.0)
    span = (t_end - last - t) / n
    for i in range(n):
        a += 180.0
        t += span * (0.9 if i % 2 == 0 else 1.1)
        crank.append((round(t, 3), a, "Linear", "In"))
    crank.append((round(t_end, 3), total, "Quad", "Out"))
    tw = t_end + 0.42
    lid = [(0.0, -OPEN_LID), (tw, -OPEN_LID), (tw + 0.08, -OPEN_LID + 1.1, "Quad", "Out"),
           (tw + 0.18, -OPEN_LID, "Quad", "In")]
    latch = [(0.0, 0.0), (tw, 0.0), (tw + 0.08, 1.6, "Quad", "Out"), (tw + 0.18, 0.0, "Quad", "In")]
    return round(t_end + beat, 2), [("Crank", "turn", crank), ("Lid", "turn", lid),
                                    ("Latch", "turn", latch)]


def jack_pop():
    """The catch flicks off, the lid bangs onto its stop and bounces three times, the jack
    springs up past its height and bobs, sways side to side on its spring with its head swinging
    after it, settles, and then slowly cocks its head at you."""
    fl = J_["latch"]["flip"]
    latch = [(0.0, 0.0), (0.025, fl, "Quad", "Out"), (0.1, 0.0, "Quad", "In"),
             (0.14, 2.5, "Quad", "Out"), (0.19, 0.0, "Quad", "In")]
    lid = [(0.0, -OPEN_LID), (0.02, -OPEN_LID), (0.095, 0.0, "Linear", "In"),
           (0.18, -14.0, "Quad", "Out"), (0.295, 0.0, "Quad", "In"), (0.37, -6.0, "Quad", "Out"),
           (0.475, 0.0, "Quad", "In"), (0.53, -2.2, "Quad", "Out"), (0.615, 0.0, "Quad", "In")]
    scale = [(0.0, SC0), (0.03, SC0), (0.11, 1.0, "Quad", "Out")]
    stretch = [(0.0, ST0), (0.03, ST0), (0.14, 1.11, "Quad", "Out"), (0.27, 0.93), (0.39, 1.05),
               (0.5, 0.975), (0.62, 1.012), (0.75, 1.0)]
    sway = [(0.0, 0.0), (0.12, 0.0), (0.22, 8.0), (0.42, -6.5), (0.62, 4.6), (0.82, -3.0),
            (1.02, 1.8), (1.23, -0.9), (1.46, 0.35), (1.75, 0.0)]
    head = [(0.0, 0.0), (0.15, 0.0), (0.25, -9.0), (0.46, 7.5), (0.66, -5.2), (0.86, 3.4),
            (1.07, -1.9), (1.3, 0.8), (1.6, 0.0), (2.05, 0.0), (2.85, TU["tilt"])]
    return 2.95, [("Latch", "turn", latch), ("Lid", "turn", lid), ("Jack", "scale", scale),
                  ("Jack", "stretch", stretch), ("Jack", "turn", sway), ("Head", "turn", head)]


def jack_shut():
    """Pushed back down: the head straightens, the jack is pressed into the box as the lid comes
    over and claps shut, its edge pushes the catch out and the catch clicks over it."""
    head = [(0.0, TU["tilt"]), (0.3, 0.0)]
    scale = [(0.0, 1.0), (0.1, 1.0), (0.45, SC0)]
    stretch = [(0.0, 1.0), (0.1, 1.0), (0.45, ST0)]
    lid = [(0.0, 0.0), (0.12, 0.0), (0.55, -OPEN_LID, "Quad", "In"),
           (0.62, -OPEN_LID + 1.6, "Quad", "Out"), (0.7, -OPEN_LID, "Quad", "In")]
    latch = [(0.0, 0.0), (0.5, 0.0), (0.545, 16.0, "Quad", "Out"), (0.585, 0.0, "Quad", "In"),
             (0.62, 1.5, "Quad", "Out"), (0.66, 0.0, "Quad", "In")]
    return 0.9, [("Head", "turn", head), ("Jack", "scale", scale), ("Jack", "stretch", stretch),
                 ("Lid", "turn", lid), ("Latch", "turn", latch)]


JW_DUR, JW_TRACKS = jack_wind()
JP_DUR, JP_TRACKS = jack_pop()
JS_DUR, JS_TRACKS = jack_shut()
WHOLE = (0.0, mm(-10.0), mm(165.0))

JACK_IN_THE_BOX = kit.Find(
    "JackInTheBox",
    [kit.Part("Box", jb_box),
     kit.Part("Crank", jb_crank, tuple(CRANK_AT), "Box", (-1, 0, 0)),
     kit.Part("Latch", jb_latch, tuple(LATCH_AT), "Box", (1, 0, 0)),
     kit.Part("Lid", jb_lid, tuple(HINGE), "Box", (-1, 0, 0)),
     kit.Part("Jack", jb_jack, tuple(V(0.0, 0.0, FLOOR)), "Box", (0, 1, 0)),
     kit.Part("Head", jb_head, tuple(V(0.0, 0.0, NECK)), "Jack", (0, 1, 0))],
    jack_look,
    motions={
        # the crank turns by itself through the tune (6.5 turns in 7.8 s), stops, and in the
        # beat of nothing after it the lid lifts once against its catch
        "Wind": dict(duration=JW_DUR, focus="Crank", distance=0.6, view=(2.0, -0.7, 0.7),
                     drop=0.0, tracks=JW_TRACKS),
        # the bang: catch off, lid onto its stop, the jack up, bobbing, swaying, then the head
        # cocked
        "Pop": dict(duration=JP_DUR, focus=WHOLE, distance=1.75, tracks=JP_TRACKS),
        # pushed back in and shut, ready to wind again
        "Shut": dict(duration=JS_DUR, focus=WHOLE, distance=1.75, tracks=JS_TRACKS),
    },
    dust=J_["dust"], seed=J_["seed"], texels=500,
)


# --- The chattering teeth (F-04c) ---------------------------------------------------------------
# A moulded denture on two orange feet: the lower jaw, the clockwork between the jaws at the back
# and the feet's legs make the Base; the top jaw swings on a pin behind the teeth. Wind the key
# and the top jaw clatters open and snaps shut seven times a second while the feet, on the same
# crank, shuffle it off across the floor, a footfall every snap. As found the jaw stands a little
# open in a grin (drawn that way, so the bake lights the teeth), the feet planted.

(GUM, GUM_IN, TOOTH, FOOT, KEYP, MECH, GEAR) = range(10, 17)

TT = K.TEETH
CH = K.CHATTER
TA = TT["arch"]
TG = TT["gum"]
OCC = TT["occ"]
DRAWN = TT["drawn"]
JAW_AT = V(*TT["hinge"])
# the top jaw is drawn this far open about its pin (+ opens about -X)
M_OPEN = about(JAW_AT, Matrix.Rotation(math.radians(DRAWN), 4, Vector((-1.0, 0.0, 0.0))))


def _arch():
    """The arch's centreline (mm), left back end round the front to the right back end, as
    points every 0.25 mm, with the running length to each."""
    a, f, p = TA["half"], TA["front"], TA["p"]
    bx, by = TA["back"]
    q = [Vector((-bx + (bx - a) * i / 40, by * (1 - i / 40), 0.0)) for i in range(40)]
    for i in range(801):
        th = -math.pi / 2 + math.pi * i / 800
        s, c = math.sin(th), math.cos(th)
        q.append(Vector((a * math.copysign(abs(s) ** (2 / p), s), f * abs(c) ** (2 / p), 0.0)))
    q += [Vector((a + (bx - a) * i / 40, by * i / 40, 0.0)) for i in range(1, 41)]
    acc = [0.0]
    for u, v in zip(q, q[1:]):
        acc.append(acc[-1] + (v - u).length)
    return q, acc


ARCH, ARCH_S = _arch()
ARCH_L = ARCH_S[-1]
MID = ARCH_L / 2


def arch_at(s):
    """The centreline's point, tangent and outward normal (horizontal) at running length s."""
    s = min(max(s, 0.0), ARCH_L)
    lo, hi = 0, len(ARCH_S) - 1
    while hi - lo > 1:
        m = (lo + hi) // 2
        if ARCH_S[m] <= s:
            lo = m
        else:
            hi = m
    u = (s - ARCH_S[lo]) / max(ARCH_S[hi] - ARCH_S[lo], 1e-9)
    p = ARCH[lo].lerp(ARCH[hi], u)
    t = (ARCH[min(hi + 2, len(ARCH) - 1)] - ARCH[max(lo - 2, 0)]).normalized()
    return p, t, Vector((t.y, -t.x, 0.0))


def _teeth():
    """Every tooth: its running length, width, how far it stands, half depth, lean."""
    out = []
    for sx in (1, -1):
        s = TT["gap"] / 2
        for w, vis, hd, lean in TT["teeth"]:
            out.append((MID + sx * (s + w / 2), w, vis, hd, lean))
            s += w + TT["gap"]
    return sorted(out)


TEETH_AT = _teeth()
EDGE_S = TT["gap"] / 2 + sum(w + TT["gap"] for w, *_ in TT["teeth"])   # the last tooth's end


def _between(s, field):
    """A tooth's number at s (1 how far it stands out, 2 half its depth), eased between the
    middles of neighbouring teeth."""
    d = abs(s - MID)
    cs = [(abs(c - MID), row[field]) for c, *row in TEETH_AT if c >= MID]
    cs = [(0.0, cs[0][1])] + cs + [(EDGE_S + 4.0, cs[-1][1])]
    for (d0, v0), (d1, v1) in zip(cs, cs[1:]):
        if d <= d1:
            u = (d - d0) / max(d1 - d0, 1e-9)
            return v0 + (v1 - v0) * (3 * u * u - 2 * u * u * u)
    return cs[-1][1]


def scallop(s):
    """How far the gum climbs a tooth at s (mm): none at a tooth's middle, rising to a point
    between two (the papilla), and level past the last tooth."""
    d = abs(s - MID)
    pap = TG["papilla"]
    for c, w, *_ in TEETH_AT:
        if c >= MID and abs(d - abs(c - MID)) <= w / 2 + TT["gap"] / 2:
            return pap * (abs(d - abs(c - MID)) / (w / 2 + TT["gap"] / 2)) ** 2.2
    return pap


def chaikin(pts, n):
    for _ in range(n):
        q = []
        for i in range(len(pts)):
            a, b = pts[i], pts[(i + 1) % len(pts)]
            q += [(0.75 * a[0] + 0.25 * b[0], 0.75 * a[1] + 0.25 * b[1]),
                  (0.25 * a[0] + 0.75 * b[0], 0.25 * a[1] + 0.75 * b[1])]
        pts = q
    return pts


def gum_section(s, upper):
    """The gum band's cross-section at s as (u out, w up) mm, anticlockwise: wide and rounded at
    its foot, closing in on the teeth at the gum line, a little proud of them."""
    t2 = TG["t"] / 2
    tw = _between(s, 2) + TG["lip"]
    # the gum line: the occlusal plane less the tooth that stands out of it, plus the scallop
    line = OCC - _between(s, 1) + scallop(s)
    if upper:
        g0, g1 = 2 * OCC - line, TG["top"]
        # its top climbs inward to meet the palate's dome
        ctrl = [(0.0, g1 + 0.8), (-t2 * 0.8, g1 + 1.6), (-t2 - 0.3, g1 - 3.0), (-t2 - 0.4, (g0 + g1) / 2),
                (-tw - 0.7, g0 + 1.4), (-tw * 0.5, g0), (tw * 0.5, g0), (tw + 0.7, g0 + 1.4),
                (t2 + 0.4, (g0 + g1) / 2), (t2 + 0.3, g1 - 4.0), (t2 * 0.8, g1)]
    else:
        g0, g1 = TG["low"], line
        ctrl = [(0.0, g0), (t2 * 0.8, g0), (t2 + 0.3, g0 + 4.0), (t2 + 0.4, (g0 + g1) / 2),
                (tw + 0.7, g1 - 1.4), (tw * 0.5, g1), (-tw * 0.5, g1), (-tw - 0.7, g1 - 1.4),
                (-t2 - 0.4, (g0 + g1) / 2), (-t2 - 0.3, g0 + 4.0), (-t2 * 0.8, g0)]
    return ctrl


def gum_band(s_, upper, hi, M=Matrix()):
    """The gum swept round the arch, its back ends rounded off."""
    sub = 3 if hi else 1
    n = int(ARCH_L / (0.4 if hi else 1.6))
    rings = []

    def ring(s, k=1.0, back=0.0):
        p, t, nn = arch_at(s)
        sec = chaikin(gum_section(s, upper), sub)
        wm = sum(w for _, w in sec) / len(sec)
        pts = [p + nn * (u * k) + Vector((0, 0, wm + (w - wm) * k)) + t * back for u, w in sec]
        return [tuple(mm(c) for c in q) for q in pts]

    p0, t0, n0 = arch_at(0.0)
    flip = n0.cross(Vector((0, 0, 1))).dot(t0) < 0
    cap = 2.6
    caps = [math.radians(a) for a in (30, 55, 75)]

    def pole(s, back):
        r = ring(s, 1e-3, back)
        c = Vector((sum(q[0] for q in r), sum(q[1] for q in r), sum(q[2] for q in r))) / len(r)
        return [tuple(c)]
    rings.append(pole(0.0, -cap))
    for a in caps:
        rings.append(ring(0.0, math.sin(a), -cap * math.cos(a)))
    for i in range(n + 1):
        rings.append(ring(ARCH_L * i / n))
    for a in reversed(caps):
        rings.append(ring(ARCH_L, math.sin(a), cap * math.cos(a)))
    rings.append(pole(ARCH_L, cap))
    if flip:
        rings = [list(reversed(r)) for r in rings]
    s_.loft(rings, GUM, M, split=4)


def tooth(s_, c, w, vis, hd, lean, upper, hi, M=Matrix()):
    """One tooth: a rounded, slightly boxy column from its root in the gum to a domed tip."""
    p, t, nn = arch_at(c)
    up = Vector((0, 0, -1 if upper else 1))
    ax = (up * math.cos(math.radians(lean)) + nn * math.sin(math.radians(lean))).normalized()
    a, b = t, nn
    if a.cross(b).dot(ax) < 0:
        a = -a
    hw = w / 2 - 0.06
    tip = OCC + (0.15 if upper else -0.15)
    root = OCC + (vis + 3.0 if upper else -vis - 3.0)
    L_ = abs(tip - root)
    base = p + Vector((0, 0, root))
    rc = min(hd, 1.7 if hw > 2.9 else 2.6)          # the tip's rounding: canines come to a point
    nr = 24 if hi else 10
    zs = [0.0, 0.3, 0.6, 1.0] if hi else [0.0, 1.0]
    zs = [z * (L_ - rc) for z in zs]
    caps = [math.radians(a_) for a_ in ((25, 45, 62, 76, 86) if hi else (45, 78))]
    rings = []
    e = 3.2
    for z in zs:
        k = 0.93 + 0.07 * min(1.0, z / max(L_ - rc, 1e-6) * 1.6)
        rings.append((z, k, k))
    for ang in caps:
        rings.append((L_ - rc + rc * math.sin(ang), math.cos(ang), math.cos(ang) ** 0.8))
    out = []
    for z, kd, kw in rings:
        ring_ = []
        for j in range(nr):
            th = 2 * math.pi * j / nr
            cx, sy = math.cos(th), math.sin(th)
            u = hw * kw * math.copysign(abs(cx) ** (2 / e), cx)
            v = hd * kd * math.copysign(abs(sy) ** (2 / e), sy)
            q = base + ax * z + a * u + b * v
            ring_.append(tuple(mm(k_) for k_ in q))
        out.append(ring_)
    out.append([tuple(mm(k_) for k_ in base + ax * L_)])
    s_.loft(out, TOOTH, M)


def floor_ring(offset, z, k=1.0):
    """The inside of the U (the arch's centreline pulled in by `offset`), closed across the back,
    scaled about its middle by k, at height z: anticlockwise from above."""
    pts = []
    n = 48
    for i in range(n + 1):
        p, t, nn = arch_at(ARCH_L * i / n)
        pts.append(p - nn * offset)
    c = sum(pts, Vector()) / len(pts)
    return [(mm(c.x + (q.x - c.x) * k), mm(c.y + (q.y - c.y) * k), mm(z)) for q in pts]


def floor_middle():
    r = floor_ring(3.0, 0.0)
    return sum(q[0] for q in r) / len(r) * K.STUD_MM, sum(q[1] for q in r) / len(r) * K.STUD_MM


def tt_base(hi):
    s = Shape()
    gum_band(s, False, hi)
    for c, w, vis, hd, lean in TEETH_AT:
        tooth(s, c, w, vis, hd, lean, False, hi)
    # the mouth's floor: a slab inside the U, its top a little below the gum line
    rings = [floor_ring(3.0, TG["low"] + 0.6), floor_ring(3.0, 21.0), floor_ring(3.0, 22.4, 0.9)]
    fx, fy = floor_middle()
    rings.append([(mm(fx), mm(fy), mm(23.0))])
    s.loft(rings, GUM_IN, cap_bottom=GUM_IN)
    # the clockwork between the jaws at the back: a tin box, two brass gears on top, the pin
    prism(s, [(-8.0, 3.0), (8.0, 3.0), (8.0, 16.0), (-8.0, 16.0)], 21.0, 31.0, MECH,
          bevel=0.5 if hi else 0.0)
    for (gx, gy, gr, gn) in ((2.6, 8.4, 5.2, 16), (-4.2, 6.2, 2.8, 10)):
        nd = 40 if hi else gn
        rr = gr - 0.7 if hi else gr - 0.3
        disc = [(gx + rr * math.cos(2 * math.pi * j / nd), gy + rr * math.sin(2 * math.pi * j / nd))
                for j in range(nd)]
        prism(s, disc, 31.0, 32.0, GEAR, bevel=0.15 if hi else 0.0)
        if hi:
            # its teeth: little tabs round the rim (a toothed rim isn't convex)
            for j in range(gn):
                th = 2 * math.pi * j / gn
                ca, sa = math.cos(th), math.sin(th)
                tab = [(gx + (gr - 0.9) * ca + 0.45 * sa, gy + (gr - 0.9) * sa - 0.45 * ca),
                       (gx + gr * ca + 0.35 * sa, gy + gr * sa - 0.35 * ca),
                       (gx + gr * ca - 0.35 * sa, gy + gr * sa + 0.35 * ca),
                       (gx + (gr - 0.9) * ca - 0.45 * sa, gy + (gr - 0.9) * sa + 0.45 * ca)]
                prism(s, tab, 31.0, 32.0, GEAR)
        s.cylinder(V(gx, gy, 30.5), V(gx, gy, 32.6), mm(0.9), MECH, segs(hi, 8))
    s.cylinder(V(-10.5, 15.0, 34.0), V(10.5, 15.0, 34.0), mm(1.1), MECH, segs(hi, 10))
    for sx in (1, -1):
        prism(s, [(sx * 8.0 - 0.8, 12.5), (sx * 8.0 + 0.8, 12.5), (sx * 8.0 + 0.8, 16.5),
                  (sx * 8.0 - 0.8, 16.5)], 21.0, 34.8, MECH)
    return s


def tt_jaw(hi):
    s = Shape()
    gum_band(s, True, hi, M_OPEN)
    for c, w, vis, hd, lean in TEETH_AT:
        tooth(s, c, w, vis, hd, lean, True, hi, M_OPEN)
    # the palate: the roof of the mouth, seen from under when it gapes, domed on top
    top = TG["top"]
    rings = [floor_ring(3.0, top - 6.0), floor_ring(3.0, top - 1.2), floor_ring(3.0, top + 1.2, 0.9),
             floor_ring(3.0, top + 2.6, 0.72), floor_ring(3.0, top + 3.5, 0.48),
             floor_ring(3.0, top + 3.95, 0.24)]
    fx, fy = floor_middle()
    rings.append([(mm(fx), mm(fy), mm(top + 4.05))])
    s.loft(rings, GUM, M_OPEN, cap_bottom=GUM_IN)
    # two tin lugs hang down from the roof onto the pin
    for sx in (1, -1):
        prism(s, [(sx * 10.0 - 0.7, 12.0), (sx * 10.0 + 0.7, 12.0), (sx * 10.0 + 0.7, 16.8),
                  (sx * 10.0 - 0.7, 16.8)], 32.6, top - 4.0, MECH, M_OPEN)
    return s


TF = TT["foot"]
# the foot from heel to toe: (y, half width, height), mm, before it's turned out
FOOT_ROWS = [(5.0, 5.4, 8.4), (3.5, 6.6, 10.6), (0.5, 7.2, 11.7), (-4.0, 7.6, 12.0), (-9.5, 7.9, 11.3),
             (-15.0, 8.4, 10.0), (-20.0, 8.8, 8.7), (-24.0, 8.6, 7.6), (-27.0, 7.4, 6.4),
             (-28.6, 5.4, 5.0)]


def ankle(sx):
    return V(sx * TF["x"], *TF["ankle"])


def tt_foot(sx):
    def build(hi):
        s = Shape()
        cx = sx * TF["x"]
        M = about(ankle(sx), Matrix.Rotation(math.radians(-sx * TF["splay"]), 4, "Z"))
        rows = smooth_rows(FOOT_ROWS, 3 if hi else 1)
        nr = segs(hi, 14)
        rings = [[(mm(cx), mm(6.4), mm(5.0))]]
        for y, hw, h in rows:
            ring = []
            for j in range(nr):
                th = 2 * math.pi * j / nr
                c, sn = math.cos(th), math.sin(th)
                e = 2.0 if sn > 0 else 4.0
                ring.append((mm(cx + hw * math.copysign(abs(c) ** (2 / e), c)), mm(y),
                             mm(h / 2 + h / 2 * math.copysign(abs(sn) ** (2 / e), sn))))
            rings.append(ring)
        rings.append([(mm(cx), mm(-29.6), mm(3.2))])
        # swept heel to toe (toward -Y): anticlockwise seen from the toe is (x, z) anticlockwise
        s.loft(rings, FOOT, M)
        # three round toes across the front
        for dx, dy, r in ((-5.0, -28.6, (3.0, 3.6, 3.2)), (0.0, -29.9, (3.3, 3.9, 3.6)),
                          (5.0, -28.6, (3.0, 3.6, 3.2))):
            blob(s, (cx + dx, dy, r[2] - 0.15), r, FOOT, hi, M, lat=8, lon=14)
        r_, z0, z1 = TF["leg"]
        s.cylinder(V(cx, -3.0, z0), V(cx, -3.0, z1), mm(r_), FOOT, segs(hi, 12))
        return s
    return build


TK = TT["key"]


def tt_key(hi):
    s = Shape()
    at = V(*TK["at"])
    r, L_ = TK["shaft"]
    s.cylinder(at + V(-2.0, 0, 0), at + V(L_, 0, 0), mm(r), KEYP, segs(hi, 10))
    s.cylinder(at + V(L_ - 2.0, 0, 0), at + V(L_ + 1.6, 0, 0), mm(3.4), KEYP, segs(hi, 14))
    # the wings: two rounded lobes of white plastic standing up and down from the hub
    Mw = T(at + V(L_, 0, 0)) @ Matrix.Rotation(math.radians(90), 4, "Y")
    wz, wy = TK["wing"]
    n = segs(hi, 16)
    for sz in (1, -1):
        lobe = [(sz * (wz * 0.28) + wz * 0.26 * math.cos(2 * math.pi * j / n),
                 wy * 0.5 * math.sin(2 * math.pi * j / n)) for j in range(n)]
        prism(s, lobe, -TK["t"] / 2, TK["t"] / 2, KEYP, Mw, 0.3 if hi else 0.0)
    return s


def teeth_look(L, f):
    nb = L.nb
    x, y, z = L.x, L.y, L.z

    def groove(v, c, w):
        return nb.ss(nb.sub(0.0, nb.absf(nb.sub(v, mm(c)))), -mm(2 * w), -mm(w))

    gum = L.k(GUM, GUM_IN)
    C_ = Coat(L, hexc("#D8445B"), 0.3, 0.0)
    # glossy pink-red plastic, its tone a little uneven as moulded plastic is, a fine stipple
    C_.paint(gum, nb.tint(hexc("#D8445B"), nb.mr(L.noise(170.0, 1, detail=3), 0.3, 0.7, 0.92, 1.06)),
             nb.mr(L.noise(300.0, 2, detail=2), 0.3, 0.7, 0.26, 0.36), 0.0,
             nb.mul(nb.mr(L.noise(1400.0, 9, detail=2), 0.35, 0.65, -0.5, 0.5), 0.12))
    # deeper red inside the mouth, where the light never reached the plastic
    C_.paint(L.k(GUM_IN), hexc("#9E2C40"), 0.45)
    # rubbed paler on the high edges where it's been handled and dropped
    edge = L.edge(mm(0.7), k=4.0)
    C_.paint(nb.mul(nb.mul(gum, edge), nb.ss(L.noise(380.0, 3, detail=4), 0.45, 0.6)),
             hexc("#E57E8D"), 0.5)
    # the teeth: cream enamel-look plastic, yellowed toward the gum, glossy; the top row's
    # coordinates are worked back to where it lies shut (it's drawn open)
    cb, sb = math.cos(math.radians(DRAWN)), math.sin(math.radians(DRAWN))
    hy, hz = mm(TT["hinge"][1]), mm(TT["hinge"][2])
    zs = nb.add(hz, nb.add(nb.mul(nb.sub(y, hy), sb), nb.mul(nb.sub(z, hz), cb)))
    upper = nb.ss(z, mm(OCC + 1.0), mm(OCC + 1.2))
    zt = nb.mixf(upper, z, zs)
    from_tip = nb.absf(nb.sub(zt, mm(OCC)))
    tooth = L.k(TOOTH)
    C_.paint(tooth, nb.tint(hexc("#F2EAD3"), nb.mr(L.noise(420.0, 4, detail=3), 0.3, 0.7, 0.95, 1.03)),
             0.16, 0.0)
    C_.paint(nb.mul(tooth, nb.mr(from_tip, mm(2.5), mm(7.0), 0.0, 0.7)), hexc("#D9C38E"), 0.22)
    # a hairline of grime where each tooth goes into the gum
    C_.paint(nb.mul(tooth, nb.mul(nb.ss(from_tip, mm(5.6), mm(7.8)), 0.4)), hexc("#8C6A4A"), 0.4)
    # the moulding's parting line round each tooth's tip, a hair paler, and a few scuffs
    C_.paint(nb.mul(tooth, nb.mul(nb.ss(nb.sub(0.0, from_tip), -mm(0.5), -mm(0.25)),
                                  nb.ss(L.noise(260.0, 5), 0.4, 0.6))), hexc("#FFFBEE"), 0.3)
    # the feet: glossy orange, scuffed dull and darker on the soles, a mould seam round the side
    foot = L.k(FOOT)
    C_.paint(foot, nb.tint(hexc("#F0701A"), nb.mr(L.noise(200.0, 6, detail=3), 0.3, 0.7, 0.93, 1.05)),
             nb.mr(L.noise(340.0, 7, detail=2), 0.3, 0.7, 0.3, 0.42), 0.0)
    sole = nb.mul(foot, nb.ss(nb.sub(0.0, L.nz), 0.4, 0.7))
    C_.paint(sole, nb.tint(hexc("#9A4B1E"), nb.mr(L.noise(500.0, 8, detail=4), 0.3, 0.7, 0.8, 1.1)), 0.75)
    side = nb.inv(nb.ss(nb.absf(L.nz), 0.6, 0.8))
    C_.paint(nb.mul(nb.mul(foot, groove(z, 4.6, 0.12)), side), hexc("#FF9B55"), 0.45, None, 0.3)
    C_.paint(nb.mul(nb.mul(foot, edge), nb.ss(L.noise(420.0, 10, detail=4), 0.5, 0.62)),
             hexc("#F7A066"), 0.55)
    # the key: white plastic gone ivory, glossy where fingers wore it
    key = L.k(KEYP)
    C_.paint(key, nb.tint(hexc("#ECE6D6"), nb.mr(L.noise(300.0, 11, detail=3), 0.3, 0.7, 0.94, 1.03)),
             0.3, 0.0)
    # the clockwork: tin gone dull and a little oily; brass gears
    mech = L.k(MECH)
    C_.paint(mech, nb.tint(hexc("#D2D2C8"), nb.mr(L.noise(260.0, 12, detail=4), 0.3, 0.7, 0.85, 1.05)),
             nb.mr(L.noise(400.0, 13, detail=2), 0.3, 0.7, 0.42, 0.58), 0.35)
    C_.paint(L.k(GEAR), nb.tint(hexc("#C9A04A"), nb.mr(L.noise(300.0, 14, detail=3), 0.3, 0.7, 0.8, 1.05)),
             0.3, 1.0)
    C_.finish(f.dust, grime=0.3)
    return C_.surface(bump_dist=0.0006, bump=0.5)


# --- how it runs ----------------------------------------------------------------------------------

FPS = 240.0


def rdp(ts, vs, eps):
    """The fewest keys a straight line between them keeps within eps of the curve (the die-cast
    car's)."""
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
    out = [(round(ts[i], 3), round(vs[i], 5), "Linear", "In") for i in keep]
    out[0] = out[0][:2]
    return out


def chatter_rate(t):
    u = min(t / CH["length"], 1.0)
    return CH["rate"] * (1 - CH["fade"] * u) * max(0.0, 1 - u ** CH["knee"]) ** 0.5


def teeth_chatter():
    """The run: a crank turning at the snap rate, slowing and giving out. The top jaw is levered
    open by its cam and snaps shut on each half turn; each snap lands a footfall."""
    dt = 1.0 / FPS
    r0, A, B = CH["rate"], mm(CH["stride"]), mm(CH["lift"])
    # the crank, sampled: psi counts snaps
    t, psi, ts, ps, rs = 0.0, 0.4, [], [], []
    stop = None
    while True:
        r = chatter_rate(t) if stop is None else 0.0
        if stop is None and t > 0.5 and r < 1.0 / CH["last"]:
            stop, r = t, 0.0
        ts.append(t)
        ps.append(psi)
        rs.append(r)
        if stop is not None and t > stop + 1.3:
            break
        psi += r * dt
        t += dt
    n = len(ts)
    dur = round(ts[-1], 2)
    # snaps where psi crosses a whole number
    snaps = [ts[i] for i in range(1, n) if math.floor(ps[i]) > math.floor(ps[i - 1])]
    # the jaw: levered open by the cam over most of each beat, slammed shut, a tiny rebound
    jaw = [(0.0, 0.0)]
    first = snaps[0]
    jaw.append((first * 0.7, CH["open"] * 0.6 - DRAWN, "Sine", "Out"))
    for k, tc in enumerate(snaps):
        P = (snaps[k + 1] - tc) if k + 1 < len(snaps) else (tc - snaps[k - 1]) * 1.3
        e = max(0.35, min(1.0, (chatter_rate(tc) / r0) ** 1.2))
        jaw += [(tc, -DRAWN, "Quad", "In"), (tc + 0.022, -DRAWN + 2.4 * e, "Quad", "Out"),
                (tc + 0.045, -DRAWN, "Quad", "In")]
        if k + 1 < len(snaps):
            jaw.append((tc + 0.82 * P, -DRAWN + CH["open"] * e, "Sine", "InOut"))
    # spent: the cam leaves it half open, and the spring lets it sag back to its grin
    tl = snaps[-1]
    jaw += [(tl + 0.3, -DRAWN + 0.35 * CH["open"], "Sine", "Out"), (tl + 1.1, 0.0, "Sine", "InOut")]
    # the feet on the crank, a step for each foot every two snaps; the body rides the planted one
    tr = {k: [] for k in (("FootL", "y"), ("FootL", "move"), ("FootL", "pitch"), ("FootR", "y"),
                          ("FootR", "move"), ("FootR", "pitch"), ("Base", "x"), ("Base", "y"),
                          ("Base", "yaw"), ("Base", "roll"), ("Base", "pitch"), ("Key", "turn"))}
    bx = by = yaw = 0.0
    wound = 180.0 * CH["winds"]
    psi_end = ps[-1]
    last_snap = -1.0
    si = 0
    for i, tt_ in enumerate(ts):
        # how hard it's going: ramps in as the spring takes, fades as it runs down, settles
        if tt_ < stop:
            a = min(1.0, tt_ / 0.12) * min(1.0, (rs[i] / r0) ** 0.7)
        else:
            a = (chatter_rate(stop - dt) / r0) ** 0.7 * max(0.0, 1 - (tt_ - stop) / 0.25)
        roll = CH["roll"] * a * math.sin(math.pi * ps[i] + 1.5 * math.pi)
        th = math.pi * ps[i] + 1.5 * math.pi
        for part, ph, fx in (("FootL", th, -TF["x"]), ("FootR", th + math.pi, TF["x"])):
            sw = max(0.0, math.sin(ph))
            tr[(part, "y")].append(A * a * math.cos(ph))
            # lifted, plus what keeps the planted sole on the floor as the body rolls onto it
            tr[(part, "move")].append(B * a * sw ** 1.5
                                      + max(0.0, mm(fx) * math.sin(math.radians(roll))))
            tr[(part, "pitch")].append(-CH["toe"] * a * sw ** 1.2)
        v = A * a * math.pi * rs[i] * abs(math.sin(th))
        yaw += math.radians(CH["drift"] * math.sin(2 * math.pi * 0.21 * tt_ + 0.8) * a) * dt
        f = Vector((math.sin(yaw), -math.cos(yaw), 0.0))
        tr[("Base", "x")].append(bx)
        tr[("Base", "y")].append(by)
        bx, by = bx + f.x * v * dt, by + f.y * v * dt
        tr[("Base", "yaw")].append(math.degrees(yaw) + CH["wiggle"] * a * math.cos(th))
        tr[("Base", "roll")].append(roll)
        while si < len(snaps) and snaps[si] <= tt_:
            last_snap = snaps[si]
            si += 1
        jolt = math.exp(-(tt_ - last_snap) / 0.03) if last_snap >= 0 else 0.0
        frac = ps[i] - math.floor(ps[i])
        tr[("Base", "pitch")].append(a * (-1.4 * frac + 1.6 * jolt))
        tr[("Key", "turn")].append(wound * (1.0 - (ps[i] - ps[0]) / (psi_end - ps[0])))
    # keys where each curve turns (a sine is exact between its turning points eased Sine InOut),
    # so a stride costs a few keys, not a sampled curve: the crank's phase in quarter turns
    stop_i = next(i for i, t_ in enumerate(ts) if t_ >= stop)
    ends = {0, stop_i, min(n - 1, stop_i + int(0.25 * FPS)), n - 1}

    def turning(phase, step, off=0.0):
        """Sample indices where phase / step + off crosses a whole number."""
        out_ = set(ends)
        for i in range(1, n):
            if math.floor(phase[i] / step + off) != math.floor(phase[i - 1] / step + off):
                out_.add(i)
        return sorted(out_)

    thL = [math.pi * p_ + 1.5 * math.pi for p_ in ps]
    thR = [t_ + math.pi for t_ in thL]
    pick = {("FootL", "y"): turning(thL, math.pi), ("FootR", "y"): turning(thR, math.pi),
            ("FootL", "move"): turning(thL, math.pi / 2), ("FootR", "move"): turning(thR, math.pi / 2),
            ("FootL", "pitch"): turning(thL, math.pi / 2), ("FootR", "pitch"): turning(thR, math.pi / 2),
            ("Base", "x"): turning(thL, math.pi), ("Base", "y"): turning(thL, math.pi),
            ("Base", "yaw"): turning(thL, math.pi), ("Base", "roll"): turning(thL, math.pi, 0.5)}
    tracks = [("Jaw", "turn", jaw)]
    for (part, ch), vs in tr.items():
        if max(vs) - min(vs) < 1e-6:
            continue
        if (part, ch) in pick:
            ks = [(round(ts[i], 3), round(vs[i], 5), "Sine", "InOut") for i in pick[(part, ch)]]
            ks[0] = ks[0][:2]
        elif ch == "pitch":
            # the body: rocks back as the jaw is levered open, jolts forward on the snap
            ks = [(0.0, 0.0)]
            for k_, tc in enumerate(snaps):
                e = min(1.0, (chatter_rate(tc) / r0) ** 0.7)
                ks += [(round(tc, 3), round(-1.4 * e, 3), "Sine", "In"),
                       (round(tc + 0.014, 3), round(1.6 * e, 3), "Quad", "Out"),
                       (round(tc + 0.07, 3), round(0.15 * e, 3), "Sine", "Out")]
            ks.append((round(snaps[-1] + 0.6, 3), 0.0))
        else:
            ks = rdp(ts, vs, 3.0)
        tracks.append((part, ch, ks))
    return dur, tracks, snaps


def teeth_wind():
    keys, t = [(0.0, 0.0), (0.15, 0.0)], 0.15
    for i in range(CH["winds"]):
        keys += [(t + 0.3, 180.0 * (i + 1), "Sine", "InOut"), (t + 0.46, 180.0 * (i + 1))]
        t += 0.46
    return round(t + 0.2, 2), [("Key", "turn", keys)]


TEETH_DUR, TEETH_TRACKS, SNAPS = teeth_chatter()
TWIND_DUR, TWIND_TRACKS = teeth_wind()

CHATTERING_TEETH = kit.Find(
    "ChatteringTeeth",
    [kit.Part("Base", tt_base),
     kit.Part("Jaw", tt_jaw, tuple(JAW_AT), "Base", (-1, 0, 0)),
     kit.Part("FootL", tt_foot(-1), tuple(ankle(-1)), "Base", (0, 0, 1)),
     kit.Part("FootR", tt_foot(1), tuple(ankle(1)), "Base", (0, 0, 1)),
     kit.Part("Key", tt_key, tuple(V(*TK["at"])), "Base", (1, 0, 0))],
    teeth_look,
    motions={
        # the key wound in four half turns, a regrip between each
        "Wind": dict(duration=TWIND_DUR, focus="Key", distance=0.75, view=(2.0, -0.9, 0.7),
                     drop=0.0, tracks=TWIND_TRACKS),
        # ten seconds of chattering: the top jaw levered open and slammed shut seven times a
        # second, a footfall each snap, waddling onto the planted foot and veering as it goes,
        # the key spinning back; it slows, gives out, and the jaw sags back to its grin
        "Chatter": dict(duration=TEETH_DUR, focus=(0.0, mm(-4.0), mm(24.0)), distance=1.0,
                        follow="Base", view=(-1.1, -2.0, 0.6), drop=0.0, tracks=TEETH_TRACKS),
    },
    dust=TT["dust"], seed=TT["seed"], texels=1600,
)


FINDS = [CYMBAL_MONKEY, JACK_IN_THE_BOX, CHATTERING_TEETH]

if __name__ == "__main__":
    kit.main("Windups", HERE, FINDS)
