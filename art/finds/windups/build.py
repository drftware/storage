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

FINDS = [CYMBAL_MONKEY]

if __name__ == "__main__":
    kit.main("Windups", HERE, FINDS)
