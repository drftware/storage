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

import ease  # noqa: E402
import kit  # noqa: E402
import spec as K  # noqa: E402
from look import Coat, hexc  # noqa: E402
from shapes import Shape, arc, fillet, helix  # noqa: E402

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


# --- The walking robot (F-04c2) -----------------------------------------------------------------
# A printed tin walker of our own (README): a boxy cobalt-blue torso with a gauge panel, a square
# head with lens eyes and a coil-spring aerial, arms on shoulder pins, short ribbed legs on hip
# pins and big red pressed-tin feet, a key in its back. Wound, it clanks off in a straight line.

RB = K.ROBOT
RW = K.WALK
(BODYT, HEADT, ARMT, PANEL, STEELK, REDT, LENS, BALL, KEYT, LEGT) = range(25, 35)

FACING = {"+X": Matrix.Rotation(math.radians(90), 4, "Y"),
          "-X": Matrix.Rotation(math.radians(-90), 4, "Y"),
          "-Y": Matrix.Rotation(math.radians(90), 4, "X"),
          "+Y": Matrix.Rotation(math.radians(-90), 4, "X"),
          "+Z": Matrix()}


def rrect(hw, hd, z, r, n, cx=0.0, cy=0.0):
    """A rounded rectangle's outline at height z (mm), anticlockwise from above."""
    r = min(r, hw - 0.01, hd - 0.01)
    pts = []
    for q, (sx, sy) in enumerate(((1, 1), (-1, 1), (-1, -1), (1, -1))):
        ox, oy = cx + sx * (hw - r), cy + sy * (hd - r)
        for i in range(n + 1):
            a = math.radians(90 * q + 90 * i / n)
            pts.append((mm(ox + r * math.cos(a)), mm(oy + r * math.sin(a)), mm(z)))
    return pts


def boxloft(s, rows, kind, n, cx=0.0, cy=0.0, bottom=None, top=None):
    """A closed rounded box through rows (z, hw, hd, r), capped by poles at bottom and top."""
    rings = [rrect(hw, hd, z, r, n, cx, cy) for z, hw, hd, r in rows]
    if bottom is not None:
        rings = [[(mm(cx), mm(cy), mm(bottom))]] + rings
    if top is not None:
        rings = rings + [[(mm(cx), mm(cy), mm(top))]]
    s.loft(rings, kind)


def stud(s, at, facing, prof, kind, hi, n=12):
    """A lathed button (profile [(r, out)] mm) standing out of a face at `at` (mm)."""
    s.lathe([(mm(a), mm(b)) for a, b in prof], kind, segs(hi, n), T(V(*at)) @ FACING[facing])


def hip(sx):
    return V(sx * RB["hip"][0], RB["hip"][1], RB["hip"][2])


def ankle(sx):
    return V(sx * RB["hip"][0], 0.0, RB["ankle"])


def shoulder(sx):
    return V(sx * RB["shoulder"][0], RB["shoulder"][1], RB["shoulder"][2])


def rb_body(hi):
    s = Shape()
    n = 6 if hi else 3
    boxloft(s, RB["torso"], BODYT, n, bottom=RB["torso"][0][0] - 0.2, top=RB["torso"][-1][0] + 0.15)
    # the gauge panel pressed out of the chest, its two dial bezels and three plastic buttons
    ch = RB["chest"]
    z0, z1 = ch["z"]
    s.box(V(-ch["x"], ch["front"], z0), V(ch["x"], -19.8, z1), PANEL, mm(0.9), 2 if hi else 1)
    fy = ch["front"]
    for x, z, r in RB["dial"]:
        k = r / 6.2
        stud(s, (x, fy, z), "-Y", [(r + 1.3 * k, -0.3), (r + 1.3 * k, 0.25), (r + 0.85 * k, 0.85),
                                   (r + 0.25 * k, 0.95), (r - 0.1, 0.55), (r - 0.25, -0.1)], STEELK, hi, 18)
    for x in RB["buttons"]:
        stud(s, (x, fy, RB["button_z"]), "-Y", [(2.9, -0.3), (2.9, 0.35), (2.5, 1.0), (1.5, 1.45),
                                                 (0.0, 1.55)], LENS, hi, 12)
    # the shoulder bosses the arms swing on
    for sx in (1, -1):
        stud(s, (sx * 30.4, 0.0, RB["shoulder"][2]), "+X" if sx > 0 else "-X",
             [(7.6, -0.6), (7.6, 0.35), (6.8, 1.15), (4.2, 1.5), (0.0, 1.5)], BODYT, hi, 20)
    # the neck: a steel collar with two pressed ribs
    z0, z1, r = RB["neck"]
    prof = [(r - 1.0, z0), (r, z0 + 1.0), (r, z0 + 1.9), (r - 0.6, z0 + 2.5), (r, z0 + 3.1),
            (r, z0 + 4.2), (r - 0.9, z0 + 5.6), (r - 2.5, z1)]
    s.lathe([(mm(a), mm(b)) for a, b in prof], STEELK, segs(hi, 24))
    # the head, its lens eyes in steel bezels, the mouth grille, the ear cones
    boxloft(s, RB["head"], HEADT, n, bottom=121.0, top=RB["head_top"])
    ex, ez, er = RB["eyes"]
    hy = -RB["head"][5][2]
    for sx in (1, -1):
        stud(s, (sx * ex, hy, ez), "-Y", [(er + 2.2, -0.5), (er + 2.2, 0.3), (er + 1.6, 1.35),
                                          (er + 0.7, 1.6), (er + 0.1, 1.2), (er - 0.1, 0.5)], STEELK, hi, 20)
        stud(s, (sx * ex, hy, ez), "-Y", [(er + 0.2, 0.3), (er, 1.4), (er * 0.8, 2.6),
                                          (er * 0.48, 3.25), (0.0, 3.45)], LENS, hi, 20)
    mo = RB["mouth"]
    s.box(V(-mo["x"], hy - 1.3, mo["z"][0]), V(mo["x"], hy + 0.4, mo["z"][1]), STEELK, mm(0.55),
          2 if hi else 1)
    hw = RB["head"][5][1]
    for sx in (1, -1):
        f = "+X" if sx > 0 else "-X"
        at = (sx * (hw - 0.4), 0.0, RB["ear"]["z"])
        r = RB["ear"]["r"]
        stud(s, at, f, [(r, -0.5), (r, 0.5), (r - 0.5, 1.4), (r * 0.66, 2.5), (r * 0.42, 3.6),
                        (3.0, 4.4), (2.8, 4.6)], REDT, hi, 20)
        stud(s, at, f, [(2.3, 4.2), (2.3, 7.0), (1.9, 7.6), (1.1, 7.9), (0.0, 8.0)], STEELK, hi, 12)
    # the aerial's socket on top of the head, ringed by pressed rivets
    az = RB["head_top"]
    prof = [(4.8, az - 0.6), (4.8, az + 0.5), (4.0, az + 1.4), (2.6, az + 1.75), (0.0, az + 1.75)]
    s.lathe([(mm(a), mm(b)) for a, b in prof], STEELK, segs(hi, 16))
    return s


def rb_arm(sx):
    a = RB["arm"]
    px, py, pz = sx * RB["shoulder"][0], RB["shoulder"][1], RB["shoulder"][2]
    hd_ = RB["hand"]

    def build(hi):
        s = Shape()
        n = 4 if hi else 2
        hw, hd, r = a["hw"], a["hd"], a["r"]
        w = a["wrist"]
        rows = [(w, hw - 1.2, hd - 2.0, r - 0.8), (w + 0.6, hw - 0.3, hd - 0.6, r - 0.2),
                (w + 1.6, hw, hd, r), (pz - 14.0, hw, hd, r), (pz - 12.8, hw + 0.45, hd + 0.45, r),
                (pz - 11.0, hw + 0.45, hd + 0.45, r), (pz - 9.8, hw, hd, r), (pz + 3.0, hw, hd, r),
                (pz + 5.4, hw - 0.4, hd - 1.2, r), (pz + 6.8, hw - 1.0, hd - 3.6, r - 0.4),
                (pz + 7.5, hw - 1.8, hd - 6.0, 1.6)]
        boxloft(s, rows, ARMT, n, px, py, bottom=w - 0.1, top=pz + 7.7)
        # the pin it swings on, peened over on the outside
        stud(s, (px + sx * hw, py, pz), "+X" if sx > 0 else "-X",
             [(2.7, -0.4), (2.7, 0.1), (2.2, 0.65), (1.2, 0.95), (0.0, 1.0)], STEELK, hi, 12)
        # the wrist and the red C-claw, open to the front
        s.cylinder(V(px, py + hd_["y"] * 0.5, w + 1.5), V(px, py + hd_["y"], hd_["z"] + hd_["r"] - 0.5),
                   mm(3.4), REDT, segs(hi, 12))
        o = hd_["open"]
        pts = arc((px, py + hd_["y"], hd_["z"]), hd_["r"], -180 + o, 180 - o, 24 if hi else 12)
        pts = [Vector((mm(x), mm(y), mm(z))) for x, y, z in pts]
        s.tube(pts, mm(hd_["wire"]), REDT, segs(hi, 10))
        for p in (pts[0], pts[-1]):
            blob(s, (p.x * K.STUD_MM, p.y * K.STUD_MM, p.z * K.STUD_MM),
                 (hd_["wire"] * 1.05,) * 3, REDT, hi, lat=5, lon=10)
        return s
    return build


def rb_leg(sx):
    lg = RB["leg"]
    cx = sx * RB["hip"][0]

    def build(hi):
        s = Shape()
        n = 3 if hi else 2
        hw, hd, r = lg["hw"], lg["hd"], lg["r"]
        rows = [(lg["foot"] + 0.4, hw - 0.6, hd - 0.6, r - 0.4)]
        z = lg["foot"] + 1.0
        rows.append((z, hw, hd, r))
        for zr in (28.0, 33.5):          # two pressed ribs round the knee
            rows += [(zr - 1.0, hw, hd, r), (zr - 0.3, hw + 0.65, hd + 0.65, r + 0.3),
                     (zr + 0.9, hw + 0.65, hd + 0.65, r + 0.3), (zr + 1.6, hw, hd, r)]
        rows.append((lg["top"] - 0.6, hw, hd, r))
        boxloft(s, rows, LEGT, n, cx, 0.0, bottom=lg["foot"], top=lg["top"])
        return s
    return build


def rb_foot(sx):
    f = RB["foot"]
    cx = sx * RB["hip"][0]
    cy = (f["toe"] + f["heel"]) / 2
    hd = (f["heel"] - f["toe"]) / 2

    def build(hi):
        s = Shape()
        n = 6 if hi else 3
        hw, r, h = f["hw"], f["r"], f["h"]
        rows = [(0.0, 1.1), (0.45, 0.25), (1.4, 0.0), (h - 3.4, 0.0), (h - 1.6, 0.8), (h - 0.6, 2.4),
                (h - 0.1, 4.6)]
        boxloft(s, [(z, hw - i, hd - i, r - i * 0.6) for z, i in rows], REDT, n, cx, cy,
                bottom=0.0, top=h)
        # the cuff the leg stands in, rolled over at its top, the ankle pin through it
        cw, cd, ct = f["cuff"]
        rows = [(h - 1.0, cw, cd, 3.0), (ct - 0.9, cw, cd, 3.0), (ct - 0.3, cw - 0.35, cd - 0.35, 2.8),
                (ct, cw - 1.0, cd - 1.0, 2.4), (ct - 0.2, cw - 1.9, cd - 1.9, 2.0),
                (ct - 1.2, cw - 2.3, cd - 2.3, 1.8), (h + 0.6, cw - 2.3, cd - 2.3, 1.8)]
        boxloft(s, rows, REDT, 3 if hi else 2, cx, 0.0, top=h + 0.4)
        stud(s, (cx + sx * cw, 0.0, RB["ankle"]), "+X" if sx > 0 else "-X",
             [(2.4, -0.4), (2.4, 0.1), (2.0, 0.6), (1.1, 0.9), (0.0, 0.95)], STEELK, hi, 12)
        return s
    return build


def rb_aerial(hi):
    s = Shape()
    ad = RB["aerial"]
    ax, ay, az = ad["at"]
    cr_, wr, turns, top = ad["coil"]
    s.cylinder(V(ax, ay, az - 1.2), V(ax, ay, az + 1.0), mm(cr_ + wr * 0.6), STEELK, segs(hi, 12))
    pts = helix(V(ax, ay, az + 0.6), V(ax, ay, top), mm(cr_), turns, 18 if hi else 9)
    s.tube(pts, mm(wr), STEELK, segs(hi, 6))
    bz, br = ad["ball"]
    s.cylinder(V(ax, ay, top - 0.8), V(ax, ay, bz - br + 1.0), mm(1.4), STEELK, segs(hi, 8))
    blob(s, (ax, ay, bz), (br, br, br), BALL, hi, lat=8, lon=16)
    return s


def rb_key(hi):
    s = Shape()
    k = RB["key"]
    x, y, z = k["at"]
    r, ln = k["shaft"]
    s.cylinder(V(x, y - 1.5, z), V(x, y + ln, z), mm(r), KEYT, segs(hi, 10))
    s.cylinder(V(x, y + ln - 2.2, z), V(x, y + ln, z), mm(2.9), KEYT, segs(hi, 14))
    hw, hl, out = k["wing"]
    t = k["t"]
    m = segs(hi, 14)
    # the wings stand upright either side of the shaft, so it shows its bow side-on
    Mw = T(V(x, y, z)) @ Matrix.Rotation(math.radians(90), 4, "Y")
    yc = ln + hl - 0.6
    bv = 0.3 if hi else 0.0
    for sw in (1, -1):
        lobe = [(sw * out + hw * math.cos(2 * math.pi * j / m), yc + hl * math.sin(2 * math.pi * j / m))
                for j in range(m)]
        prism(s, lobe, -t / 2, t / 2, KEYT, Mw, bv)
    prism(s, [(3.2, ln - 0.6), (3.2, yc + 2.5), (-3.2, yc + 2.5), (-3.2, ln - 0.6)], -t / 2, t / 2,
          KEYT, Mw, bv)
    return s


def robot_look(L, f):
    nb = L.nb
    xm, ym, zm = nb.mul(L.x, K.STUD_MM), nb.mul(L.y, K.STUD_MM), nb.mul(L.z, K.STUD_MM)
    ax = nb.absf(xm)
    sgn = nb.div(xm, nb.add(ax, 0.001))

    def sq(v):
        return nb.mul(v, v)

    def disc(u, v, cu, cv, r, soft=0.2):
        d = nb.math("SQRT", nb.add(sq(nb.sub(u, cu)), sq(nb.sub(v, cv))))
        return nb.sub(1.0, nb.ss(d, r - soft, r + soft))

    def band(v, a, b, soft=0.15):
        """1 between a and b."""
        return nb.mul(nb.ss(v, a - soft, a + soft), nb.sub(1.0, nb.ss(v, b - soft, b + soft)))

    def both(*ms):
        out = ms[0]
        for m in ms[1:]:
            out = nb.mul(out, m)
        return out

    grain = L.noise(500.0, 1, detail=1)
    tone = nb.mr(grain, 0.3, 0.7, 0.95, 1.04)
    BLUE, BLUE2, CREAM, INK, RED, YEL = "#2B5BA6", "#3A6CB8", "#E9DDB8", "#1B1D22", "#C3302A", "#E6B437"
    SILVER = "#93A2B5"
    C = Coat(L, hexc(BLUE), 0.32, 0.0, 0.0)
    fr, bk = nb.ss(nb.sub(0.0, L.ny), 0.6, 0.8), nb.ss(L.ny, 0.6, 0.8)
    sd = nb.ss(nb.absf(L.nx), 0.6, 0.8)
    up, dn = nb.ss(L.nz, 0.6, 0.8), nb.ss(nb.sub(0.0, L.nz), 0.6, 0.8)
    torso, head, arm = L.k(BODYT), L.k(HEADT), L.k(ARMT)
    blue = L.k(BODYT, HEADT, ARMT)
    C.paint(blue, nb.tint(hexc(BLUE), tone), 0.32, 0.0)

    def rivets(mask, u, v, u0, step, phase=0.0, r=1.05):
        """A column of printed, pressed rivets at u = u0, every `step` mm along v."""
        dv = nb.mul(nb.sub(nb.fract(nb.add(nb.div(v, step), 0.5 + phase)), 0.5), step)
        du = nb.sub(u, u0)
        d2 = nb.add(sq(du), sq(dv))
        ring = nb.sub(1.0, nb.ss(d2, (r + 0.2) ** 2, (r + 0.45) ** 2))
        dot = nb.sub(1.0, nb.ss(d2, (r - 0.15) ** 2, (r + 0.15) ** 2))
        hl = nb.sub(1.0, nb.ss(nb.add(sq(nb.add(du, 0.35)), sq(nb.sub(dv, 0.35))), 0.08, 0.3))
        C.paint(nb.mul(mask, ring), hexc(INK), 0.32)
        C.paint(nb.mul(mask, dot), hexc(SILVER), 0.3, 0.0, 0.00012)
        C.paint(both(mask, dot, hl), hexc("#D9DEE2"), 0.3)

    # --- the torso: rivets up its corners, a hazard-striped belt, a vent, a hatch on its back
    tz = band(zm, 66.5, 113.0)
    for s_ in (1, -1):
        rivets(both(torso, nb.mx(fr, bk), tz), xm, zm, s_ * 24.6, 6.0)
        rivets(both(torso, sd, tz), ym, zm, s_ * 14.8, 6.0)
    u = nb.add(nb.mul(xm, nb.mx(fr, bk)), nb.mul(ym, sd))
    belt = both(torso, band(zm, 58.9, 66.2), nb.sub(1.0, up))
    C.paint(belt, nb.tint(hexc(YEL), tone), 0.32)
    stripes = nb.ss(nb.sin(nb.mul(nb.add(u, zm), 2 * math.pi / 7.0)), -0.12, 0.12)
    C.paint(both(belt, stripes, band(zm, 59.7, 65.4)), hexc(INK), 0.32)
    C.paint(both(torso, nb.sub(1.0, up), nb.mx(band(zm, 58.4, 59.2, 0.1), band(zm, 65.9, 66.7, 0.1))),
            hexc(INK), 0.32)
    C.paint(both(torso, nb.sub(1.0, nb.ss(zm, 58.2, 58.6))), hexc("#2A2E36"), 0.34)
    vent = both(torso, fr, band(zm, 107.6, 113.4), band(ax, -1.0, 13.0))
    C.paint(vent, hexc(INK), 0.34)
    C.paint(both(vent, band(nb.fract(nb.div(nb.sub(zm, 107.6), 1.95)), 0.42, 0.95, 0.06),
                 band(ax, -1.0, 12.2), band(zm, 108.3, 112.7)), hexc(BLUE2), 0.32)
    # the hatch on its back, the key's wind ring and our maker's mark, a diamond
    hz = nb.sub(zm, 87.0)
    rc = 3.0
    qx, qz = nb.mx(nb.sub(ax, 17.0 - rc), 0.0), nb.mx(nb.sub(nb.absf(hz), 22.5 - rc), 0.0)
    dh = nb.sub(nb.math("SQRT", nb.add(sq(qx), sq(qz))), rc)
    back = both(torso, bk)
    C.paint(both(back, nb.sub(1.0, nb.ss(dh, -0.2, 0.0))), nb.tint(hexc(BLUE2), tone), 0.32)
    C.paint(both(back, band(dh, -0.45, 0.25, 0.1)), hexc(INK), 0.32)
    for cx, cz in ((14.0, 67.5), (14.0, 106.5)):
        C.paint(both(back, disc(ax, zm, cx, cz, 1.4)), hexc(INK), 0.32)
        C.paint(both(back, disc(ax, zm, cx, cz, 1.0)), hexc(SILVER), 0.3, 0.0, 0.00012)
    kz = RB["key"]["at"][2]
    C.paint(both(back, disc(xm, zm, 0.0, kz, 6.2)), hexc(INK), 0.32)
    C.paint(both(back, disc(xm, zm, 0.0, kz, 5.4)), hexc(CREAM), 0.32)
    C.paint(both(back, disc(xm, zm, 0.0, kz, 3.6)), hexc(INK), 0.32)
    dia = nb.add(nb.div(ax, 5.6), nb.div(nb.absf(nb.sub(zm, 101.0)), 4.2))
    C.paint(both(back, nb.sub(1.0, nb.ss(dia, 0.95, 1.05))), hexc(RED), 0.3)
    C.paint(both(back, nb.sub(1.0, nb.ss(dia, 0.62, 0.72))), hexc(CREAM), 0.3)
    C.paint(both(back, disc(xm, zm, 0.0, 101.0, 1.1)), hexc(RED), 0.3)
    C.paint(both(torso, up, nb.ss(zm, 115.0, 115.5)), nb.tint(hexc(BLUE2), tone), 0.32)

    # --- the gauge panel: a dark plate in a red frame, two dials, a bar meter, label dashes
    pn = L.k(PANEL)
    pf = nb.mul(pn, fr)
    C.paint(pn, hexc("#A9ACAE"), 0.3, 1.0)
    C.paint(pf, nb.tint(hexc("#202328"), tone), 0.34, 0.0)
    rc = 2.4
    qx, qz = nb.mx(nb.sub(ax, 16.6 - rc), 0.0), nb.mx(nb.sub(nb.absf(nb.sub(zm, 89.0)), 14.6 - rc), 0.0)
    dp = nb.sub(nb.math("SQRT", nb.add(sq(qx), sq(qz))), rc)
    C.paint(both(pf, band(dp, -0.5, 0.5, 0.1)), hexc(RED), 0.3)
    for (cx, cz, r), face, ticks, needle, ncol in (
            (RB["dial"][0], CREAM, 12, 132.0, RED), (RB["dial"][1], YEL, 8, 48.0, INK)):
        px, pz = nb.sub(xm, cx), nb.sub(zm, cz)
        rr = nb.math("SQRT", nb.add(sq(px), sq(pz)))
        C.paint(both(pf, disc(xm, zm, cx, cz, r - 0.1)), nb.tint(hexc(face), tone), 0.28)
        ang = nb.math("ARCTAN2", pz, nb.add(px, 0.0001))
        fa = nb.fract(nb.mul(ang, ticks / (2 * math.pi)))
        tick = nb.sub(1.0, nb.ss(nb.mn(fa, nb.sub(1.0, fa)), 0.05, 0.09))
        C.paint(both(pf, tick, band(rr, r * 0.68, r * 0.9, 0.08)), hexc(INK), 0.28)
        if r > 5.0:
            # the red zone, a third of the way round on the right
            C.paint(both(pf, band(rr, r * 0.55, r * 0.66, 0.08), band(ang, -1.1, 0.15, 0.04)),
                    hexc(RED), 0.28)
        a = math.radians(needle)
        dx, dz = math.cos(a), math.sin(a)
        along = nb.add(nb.mul(px, dx), nb.mul(pz, dz))
        off = nb.absf(nb.sub(nb.mul(pz, dx), nb.mul(px, dz)))
        C.paint(both(pf, nb.sub(1.0, nb.ss(off, 0.25, 0.42)), band(along, -1.2, r * 0.82, 0.1)),
                hexc(ncol), 0.28)
        C.paint(both(pf, disc(xm, zm, cx, cz, 0.95)), hexc(INK), 0.28)
    meter = both(pf, band(zm, 83.4, 88.4, 0.1), band(xm, -15.4, 15.4, 0.1))
    C.paint(meter, hexc("#0E0F12"), 0.3)
    seg = band(nb.fract(nb.div(nb.add(xm, 15.0), 3.0)), 0.08, 0.86, 0.04)
    cell = both(meter, seg, band(zm, 84.0, 87.8, 0.1), band(xm, -15.0, 15.0, 0.1))
    lit = nb.sub(1.0, nb.ss(xm, 5.8, 6.2))
    for lo, hi_, c in ((-16.0, 0.0, "#3E9A4B"), (0.0, 6.0, YEL), (6.0, 16.0, RED)):
        C.paint(both(cell, band(xm, lo, hi_, 0.05)), hexc(c), 0.3)
    C.paint(both(cell, nb.sub(1.0, lit)), hexc("#5A2622"), 0.3)
    dash = both(pf, band(zm, 90.4, 91.1, 0.08), band(nb.fract(nb.div(xm, 2.2)), 0.15, 0.75, 0.05),
                nb.mx(band(xm, -13.5, -1.5, 0.1), band(xm, 3.5, 14.5, 0.1)))
    C.paint(dash, hexc(CREAM), 0.3)

    # --- the head: rivets, a strip of little lamps on its brow, rings round the eyes and ears,
    # a grille on the back of its head, rivets round the aerial
    hb = band(zm, 126.5, 158.0)
    for s_ in (1, -1):
        rivets(both(head, nb.mx(fr, bk), hb), xm, zm, s_ * 19.6, 5.5)
    brow = both(head, fr, band(zm, 153.6, 158.4), band(ax, -1.0, 15.6))
    C.paint(brow, hexc(INK), 0.32)
    lamp = both(brow, band(nb.fract(nb.div(nb.add(xm, 14.0), 4.0)), 0.18, 0.82, 0.05),
                band(zm, 154.6, 157.4, 0.1), band(ax, -1.0, 14.6))
    alt = nb.ss(nb.sin(nb.mul(nb.add(xm, 14.0), math.pi / 4.0)), -0.05, 0.05)
    C.paint(lamp, hexc(RED), 0.25)
    C.paint(nb.mul(lamp, alt), hexc(YEL), 0.25)
    ex, ez, er = RB["eyes"]
    for s_ in (1, -1):
        C.paint(both(head, fr, disc(xm, zm, s_ * ex, ez, er + 3.3)), hexc(INK), 0.32)
        C.paint(both(head, fr, disc(xm, zm, s_ * ex, ez, er + 2.6)), hexc(CREAM), 0.3)
    C.paint(both(head, fr, band(zm, 127.6, 138.0), band(ax, -1.0, 12.4)), hexc(INK), 0.32)
    ring = disc(ym, zm, 0.0, RB["ear"]["z"], RB["ear"]["r"] + 3.2)
    C.paint(both(head, sd, ring), hexc(CREAM), 0.3)
    C.paint(both(head, sd, disc(ym, zm, 0.0, RB["ear"]["z"], RB["ear"]["r"] + 2.2)), hexc(INK), 0.32)
    gr = both(head, bk, band(zm, 131.0, 151.0), band(ax, -1.0, 13.5))
    C.paint(gr, hexc(INK), 0.32)
    C.paint(both(gr, band(nb.fract(nb.div(nb.sub(zm, 131.0), 2.5)), 0.45, 0.95, 0.05),
                 band(ax, -1.0, 12.7), band(zm, 131.6, 150.4)), hexc(BLUE2), 0.32)
    C.paint(both(head, nb.sub(1.0, nb.ss(zm, 126.0, 126.4))), hexc("#2A2E36"), 0.34)
    rr = nb.math("SQRT", nb.add(sq(xm), sq(ym)))
    ang = nb.math("ARCTAN2", ym, nb.add(xm, 0.0001))
    fa = nb.sub(nb.fract(nb.mul(ang, 8 / (2 * math.pi))), 0.5)
    tdot = nb.add(sq(nb.sub(rr, 9.5)), sq(nb.mul(fa, 2 * math.pi * 9.5 / 8)))
    top = both(head, up)
    C.paint(nb.mul(top, nb.sub(1.0, nb.ss(tdot, 1.3, 1.9))), hexc(INK), 0.32)
    C.paint(nb.mul(top, nb.sub(1.0, nb.ss(tdot, 0.7, 1.1))), hexc(SILVER), 0.3, 0.0, 0.00012)

    # --- the arms: a pressed elbow band in silver, a cream stripe down the outside
    outer = nb.ss(nb.mul(L.nx, sgn), 0.6, 0.8)
    C.paint(both(arm, band(zm, 92.0, 96.0, 0.1)), hexc(SILVER), 0.3, 0.0)
    C.paint(both(arm, nb.mx(band(zm, 91.6, 92.3, 0.08), band(zm, 95.7, 96.4, 0.08))), hexc(INK), 0.32)
    C.paint(both(arm, outer, band(ym, -1.3, 1.3, 0.1), nb.mx(band(zm, 75.0, 90.5), band(zm, 97.5, 103.0))),
            hexc(CREAM), 0.3)

    # --- legs: printed gunmetal, their pressed ribs bare tin
    lg = L.k(LEGT)
    C.paint(lg, nb.tint(hexc("#6C737C"), tone), 0.36, 0.0)
    C.paint(both(lg, nb.mx(band(zm, 27.2, 30.4, 0.2), band(zm, 32.7, 35.9, 0.2))), hexc("#B9BAB5"), 0.3, 1.0)

    # --- red tin: the feet (bare tin soles, a dark sole line), the hands, the ears
    rd = L.k(REDT)
    C.paint(rd, nb.tint(hexc(RED), tone), 0.32, 0.0)
    C.paint(both(rd, band(zm, 1.6, 3.0, 0.1), nb.sub(1.0, up), nb.sub(1.0, dn)), hexc(INK), 0.34)
    C.paint(both(rd, dn, nb.sub(1.0, nb.ss(zm, 1.0, 1.5))), hexc("#8F8C84"), 0.5, 1.0)

    # --- printed tin knocked about: chips to bare tin on the edges, scuffs, a little rust low down
    printed = L.k(BODYT, HEADT, ARMT, REDT, LEGT)
    chips = both(printed, L.edge(mm(1.1), k=4.0), nb.ss(L.noise(220.0, 3, detail=4), 0.47, 0.55))
    C.paint(chips, hexc("#ABAAA2"), 0.3, 1.0, -0.00015)
    scratch = nb.ss(L.noise(300.0, 4, stretch=(1.0, 0.06, 0.06), detail=2), 0.69, 0.72)
    C.paint(both(printed, scratch, 0.5), hexc("#B6B2A6"), 0.36, 0.6)
    rust = both(nb.mx(rd, lg), nb.sub(1.0, nb.ss(zm, 6.0, 14.0)), nb.ss(L.noise(110.0, 5, detail=4), 0.64, 0.7))
    C.paint(rust, hexc("#6B3A1F"), 0.85, 0.0)

    # --- steel: the neck, bezels, pins, the mouth grille's plate, the aerial's coil and socket
    st = L.k(STEELK)
    C.paint(st, nb.tint(hexc("#A2A5A6"), nb.mr(L.noise(80.0, 6, detail=3), 0.3, 0.7, 0.86, 1.06)),
            0.3, 1.0)
    C.paint(both(st, nb.ss(L.noise(130.0, 7, detail=4), 0.68, 0.73)), hexc("#6E3B1E"), 0.8, 0.0)
    mz0, mz1 = RB["mouth"]["z"]
    slots = both(st, fr, band(zm, mz0 + 1.2, mz1 - 1.2), band(ax, -1.0, RB["mouth"]["x"] - 1.6),
                 band(nb.fract(nb.div(nb.sub(zm, mz0 + 1.2), 1.7)), 0.4, 0.95, 0.05))
    C.paint(slots, hexc("#15161A"), 0.6, 0.0)
    # the key: brass-lacquered tin
    ky = L.k(KEYT)
    C.paint(ky, nb.tint(hexc("#B8934A"), nb.mr(L.noise(90.0, 8, detail=3), 0.3, 0.7, 0.88, 1.06)), 0.3, 1.0)
    # plastic: amber lens eyes with a printed iris, red, yellow and green buttons, the red ball
    ln_ = L.k(LENS)
    eyes = nb.mul(ln_, nb.ss(zm, 138.0, 139.0))
    C.paint(ln_, hexc("#E8B22E"), 0.1, 0.0)
    ex_ = nb.sub(xm, nb.mul(sgn, ex))
    ez_ = nb.sub(zm, ez)
    C.paint(nb.mul(eyes, disc(ex_, ez_, 0.0, 0.0, 3.0)), hexc("#D45A1E"), 0.1)
    C.paint(nb.mul(eyes, disc(ex_, ez_, 0.0, 0.0, 1.8)), hexc("#121214"), 0.08)
    C.paint(nb.mul(eyes, disc(ex_, ez_, -1.5, 1.6, 0.9, 0.25)), hexc("#FFF6DC"), 0.08)
    btn = nb.mul(ln_, nb.sub(1.0, nb.ss(zm, 138.0, 139.0)))
    C.paint(nb.mul(btn, nb.sub(1.0, nb.ss(xm, -5.2, -4.8))), hexc("#D3322B"), 0.14)
    C.paint(nb.mul(btn, band(xm, -5.0, 5.0, 0.2)), hexc("#EBC13A"), 0.14)
    C.paint(nb.mul(btn, nb.ss(xm, 4.8, 5.2)), hexc("#3DA04E"), 0.14)
    C.paint(L.k(BALL), hexc("#CF2A22"), 0.16, 0.0)
    C.finish(f.dust, grime=0.5)
    return C.surface(bump_dist=0.0012, bump=0.7)


# --- how it walks -------------------------------------------------------------------------------
# One crank drives it all: psi counts footfalls, each leg swinging through a full stroke every two,
# the arms the other way. The body moves only as the planted foot's backward swing pushes it, so
# no foot ever slides, and each foot's `move` keeps its sole on the floor (or lifts it clear on
# its swing) whatever the legs, the lean and the waddle do.

def walk_rate(t):
    u = min(t / RW["length"], 1.0)
    return RW["rate"] * (1 - RW["fade"] * u) * max(0.0, 1 - u ** RW["knee"]) ** 0.5


def smooth(e0, e1, x):
    u = min(1.0, max(0.0, (x - e0) / (e1 - e0)))
    return u * u * (3 - 2 * u)


def robot_walk():
    dt = 1.0 / FPS
    r0 = RW["rate"]
    t, psi, stop = 0.0, 0.0, None
    ts, ps, rs = [], [], []
    while True:
        r = walk_rate(t) if stop is None else 0.0
        if stop is None and t > 0.5 and r < 1.0 / RW["last"]:
            stop, r = t, 0.0
        ts.append(t)
        ps.append(psi)
        rs.append(r)
        if stop is not None and t > stop + 1.8:
            break
        psi += r * dt
        t += dt
    n = len(ts)
    falls = [ts[i] for i in range(1, n) if math.floor(ps[i] - 0.5) > math.floor(ps[i - 1] - 0.5)]
    stop_i = next(i for i, t_ in enumerate(ts) if t_ >= stop)
    a_stop = min(1.0, (rs[stop_i - 1] / r0) ** 0.6)
    hipz = RB["hip"][2]
    ank = RB["ankle"]
    fx = RB["hip"][0]
    fcy = (RB["foot"]["toe"] + RB["foot"]["heel"]) / 2
    H = RB["aerial"]["at"][2]
    tr = {}

    def put(part, ch, v):
        tr.setdefault((part, ch), []).append(v)

    planted = "R"                   # it sets off on its left foot
    P = None
    bx = by = 0.0
    fi = 0
    for i, t_ in enumerate(ts):
        if t_ < stop:
            a = min(1.0, t_ / 0.15) * min(1.0, (rs[i] / r0) ** 0.6)
            aa = a
        else:
            a = a_stop * (1 - smooth(0.0, 0.4, t_ - stop))
            # the arms swing on their pins after the crank stops, and settle
            aa = a_stop * math.exp(-(t_ - stop) / 0.32) * math.cos(2 * math.pi * 1.7 * (t_ - stop))
        ph = math.pi * ps[i]
        sw = RW["swing"] * a * math.sin(ph)          # degrees the left foot is forward
        tauL, tauR = -sw, sw                          # turns about +X: + swings back
        roll = -RW["roll"] * a * math.cos(ph)         # + lowers the left (+X) side
        yaw = -RW["wiggle"] * a * math.sin(ph)
        while fi < len(falls) and falls[fi] <= t_:
            fi += 1
        tf = falls[fi - 1] if fi else -1.0
        e = min(1.0, (walk_rate(tf) / r0) ** 0.7) if fi else 0.0
        jolt = RW["jolt"] * e * (1 - math.exp(-(t_ - tf) / 0.015)) * math.exp(-(t_ - tf) / 0.06) \
            if fi and t_ < stop + 0.3 else 0.0
        lean = RW["lean"] * a
        pitch = lean + jolt
        swingL = math.cos(ph) > 0
        if t_ >= stop:
            swingL = planted == "R"
        now = "R" if swingL else "L"
        R = Matrix.Rotation(math.radians(yaw), 4, "Z") @ Matrix.Rotation(math.radians(pitch), 4, "X") \
            @ Matrix.Rotation(math.radians(roll), 4, "Y")
        soles = {}
        for side, sx, tau in (("L", 1, tauL), ("R", -1, tauR)):
            hp = Vector((mm(sx * fx), 0.0, mm(hipz)))
            Lg = T(hp) @ Matrix.Rotation(math.radians(tau), 4, "X") @ T(-hp)
            ak = Vector((mm(sx * fx), 0.0, mm(ank)))
            fp, fr = -(tau + lean), -roll
            Lf = T(ak) @ Matrix.Rotation(math.radians(fp), 4, "X") @ Matrix.Rotation(math.radians(fr), 4, "Y") @ T(-ak)
            sole = Vector((mm(sx * fx), mm(fcy), 0.0))
            z0 = (R @ Lg @ Lf @ sole).z
            swinging = (side == "L") == swingL
            lift = mm(RW["lift"]) * a * abs(math.cos(ph)) ** 1.5 if swinging and t_ < stop else 0.0
            m = lift - z0
            q = R @ Lg @ Lf @ T(Vector((0.0, 0.0, m))) @ sole
            soles[side] = q
            put("Foot" + side, "move", m)
            put("Foot" + side, "pitch", fp)
            put("Foot" + side, "roll", fr)
            put("Leg" + side, "turn", tau)
        if P is None or now != planted:
            planted = now
            P = Vector((bx, by, 0.0)) + soles[planted]
        bx, by = P.x - soles[planted].x, P.y - soles[planted].y
        put("Body", "x", bx)
        put("Body", "y", by)
        put("Body", "yaw", yaw)
        put("Body", "pitch", pitch)
        put("Body", "roll", roll)
        put("ArmL", "turn", RW["arm"] * aa * math.sin(ph))
        put("ArmR", "turn", -RW["arm"] * aa * math.sin(ph))
        put("Key", "turn", 180.0 * RW["winds"] * (1.0 - ps[i] / ps[-1]))
    # the aerial: a spring and ball on the head, flung about by the body's sway and each clank
    f_, z_, l_ = RW["aerial"]
    w = 2 * math.pi * f_

    def d2(vs, i):
        return (vs[min(i + 1, n - 1)] - 2 * vs[i] + vs[max(i - 1, 0)]) / (dt * dt)

    Bp = [math.radians(v) for v in tr[("Body", "pitch")]]
    Br = [math.radians(v) for v in tr[("Body", "roll")]]
    By = [v * K.STUD_MM for v in tr[("Body", "y")]]
    Bx = [v * K.STUD_MM for v in tr[("Body", "x")]]
    thp = thr = vp = vr = 0.0
    for i in range(n):
        ay_ = d2(By, i) - H * d2(Bp, i)
        ax_ = d2(Bx, i) + H * d2(Br, i)
        acc_p = -w * w * thp - 2 * z_ * w * vp + ay_ / l_ - d2(Bp, i)
        acc_r = -w * w * thr - 2 * z_ * w * vr - ax_ / l_ - d2(Br, i)
        vp += acc_p * dt
        vr += acc_r * dt
        thp += vp * dt
        thr += vr * dt
        put("Aerial", "pitch", max(-25.0, min(25.0, math.degrees(thp))))
        put("Aerial", "roll", max(-25.0, min(25.0, math.degrees(thr))))

    # keys only where each curve turns: half steps for the crank's sines, quarter steps for the
    # feet's lifts, a curve's own turning points (the aerial, the arms' settle), and the ends
    ends = {0, stop_i, n - 1}

    def turning(step, off=0.0):
        out_ = set(ends)
        for i in range(1, stop_i + 1):
            if math.floor(ps[i] / step + off) != math.floor(ps[i - 1] / step + off):
                out_.add(i)
        return out_

    def extremes(vs, i0=0):
        out_ = set()
        for i in range(max(1, i0), n - 1):
            if (vs[i] - vs[i - 1]) * (vs[i + 1] - vs[i]) < 0:
                out_.add(i)
        return out_

    half, quarter = turning(0.5), turning(0.25)
    tracks = []
    for (part, ch), vs in tr.items():
        if max(vs) - min(vs) < 1e-6:
            continue
        if part == "Key":
            ks = rdp(ts, vs, 3.0)
        elif (part, ch) == ("Body", "pitch"):
            ks = rdp(ts, vs, 0.04)
        else:
            if part == "Aerial":
                pick = extremes(vs) | ends
            elif ch == "move" or (part, ch) == ("Body", "x"):
                pick = quarter | extremes(vs, stop_i)
            else:
                pick = half | extremes(vs, stop_i)
            ks = [(round(ts[i], 3), round(vs[i], 5), "Sine", "InOut") for i in sorted(pick)]
            ks[0] = ks[0][:2]
        tracks.append((part, ch, ks))
    return round(ts[-1], 2), tracks, falls


def robot_wind():
    keys, t = [(0.0, 0.0), (0.15, 0.0)], 0.15
    for i in range(RW["winds"]):
        keys += [(t + 0.3, 180.0 * (i + 1), "Sine", "InOut"), (t + 0.46, 180.0 * (i + 1))]
        t += 0.46
    return round(t + 0.2, 2), [("Key", "turn", keys)]


WALK_DUR, WALK_TRACKS, FALLS = robot_walk()
RWIND_DUR, RWIND_TRACKS = robot_wind()

WALKING_ROBOT = kit.Find(
    "WalkingRobot",
    [kit.Part("Body", rb_body),
     kit.Part("LegL", rb_leg(1), tuple(hip(1)), "Body", (1, 0, 0)),
     kit.Part("LegR", rb_leg(-1), tuple(hip(-1)), "Body", (1, 0, 0)),
     kit.Part("FootL", rb_foot(1), tuple(ankle(1)), "LegL", (0, 0, 1)),
     kit.Part("FootR", rb_foot(-1), tuple(ankle(-1)), "LegR", (0, 0, 1)),
     kit.Part("ArmL", rb_arm(1), tuple(shoulder(1)), "Body", (1, 0, 0)),
     kit.Part("ArmR", rb_arm(-1), tuple(shoulder(-1)), "Body", (1, 0, 0)),
     kit.Part("Aerial", rb_aerial, tuple(V(*RB["aerial"]["at"])), "Body", (0, 0, 1)),
     kit.Part("Key", rb_key, tuple(V(*RB["key"]["at"])), "Body", (0, 1, 0))],
    robot_look,
    motions={
        # the key wound in five half turns, a regrip between each
        "Wind": dict(duration=RWIND_DUR, focus="Key", distance=0.8, view=(1.2, 2.0, 0.7),
                     drop=0.0, tracks=RWIND_TRACKS),
        # fifteen seconds of clanking off in a straight line: legs swinging from the hips, arms
        # the other way, rocking onto each planted foot, the aerial whipping about; it slows,
        # gives out, and its arms swing on a moment after it stops
        "Walk": dict(duration=WALK_DUR, focus=(0.0, 0.0, mm(95.0)), distance=1.15, follow="Body",
                     view=(-1.1, -2.0, 0.45), drop=0.0, tracks=WALK_TRACKS),
    },
    dust=RB["dust"], seed=RB["seed"], texels=900,
)


# --- The wind-up mouse (F-04d) ------------------------------------------------------------------
# A flocked clockwork mouse (README): a grey teardrop body over a tin shell on a plastic plate, two
# drive wheels under its middle and a knob under its rump, pink-lined felt ears, domed printed
# eyes, a pink bead nose, nylon whiskers, a stiff black tail on a wagging cam, a brass key in its
# left side. Wound and set down, it zips off, veers, slows, stalls dead and rocks onto its nose.

MO = K.MOUSE
ZP = K.ZIP
(FLOCK, EAR_IN, MEYE, MNOSE, WHISK, MTAIL, MKEY, PLATE, TYRE, HUB) = range(35, 45)


def mo_section(row, a):
    """A point round the body's section `row` (y, half width, underside, top; mm) at angle a,
    anticlockwise seen from behind (+Y): an ellipse above its widest line, squarer below."""
    y, hw, zb, zt = row
    zc = zb + MO["low"] * (zt - zb)
    c, s = math.cos(a), math.sin(a)
    e, h = (2.0, zt - zc) if s >= 0 else (MO["flat"], zc - zb)
    cx = math.copysign(abs(c) ** (2.0 / e), c)
    sz = math.copysign(abs(s) ** (2.0 / e), s)
    return (-hw * cx, y, zc + h * sz)


MO_FINE = smooth_rows([tuple(r) for r in MO["body"]], 8)


def mo_row(y):
    for a, b in zip(MO_FINE, MO_FINE[1:]):
        if a[0] <= y <= b[0]:
            u = (y - a[0]) / (b[0] - a[0])
            return tuple(p + (q - p) * u for p, q in zip(a, b))
    return MO_FINE[-1]


def mo_x(y, z):
    """The body's half width (mm) at y and height z."""
    _, hw, zb, zt = mo_row(y)
    zc = zb + MO["low"] * (zt - zb)
    e, h = (2.0, zt - zc) if z >= zc else (MO["flat"], zc - zb)
    s = min(1.0, abs(z - zc) / h) ** (e / 2.0)
    return hw * math.sqrt(max(0.0, 1 - s * s)) ** (2.0 / e)


def frame(face, up):
    """A turn taking +Z to `face` with +Y as near `up` as it can be (4x4)."""
    zl = Vector(face).normalized()
    yl = (Vector(up) - zl * Vector(up).dot(zl)).normalized()
    return Matrix((yl.cross(zl), yl, zl)).transposed().to_4x4()


EAR_PROF = [(0.0, 0.0), (3.0, 0.25), (5.6, 0.9), (7.6, 1.8), (8.6, 2.9), (8.7, 3.5), (8.1, 3.8),
            (6.6, 3.1), (4.2, 2.3), (2.0, 1.9), (0.0, 1.8)]
EAR_KINDS = [FLOCK] * 6 + [EAR_IN] * 4


def mo_normal(sx, y, z):
    """Which way the body's side faces at y, z on side sx."""
    h = 0.2
    return Vector((sx, -(mo_x(y + h, z) - mo_x(y - h, z)) / (2 * h),
                   -(mo_x(y, z + h) - mo_x(y, z - h)) / (2 * h))).normalized()


EYE_PROF = [(1.0, -2.2), (0.98, 0.0), (0.92, 0.9), (0.75, 1.6), (0.45, 2.1), (0.0, 2.3)]


def eye_at(sx):
    """The eye's foot and facing (mm) on side sx, and its dome's apex. The dome's skirt sits deep
    in the body all round, so no edge of it stands proud for the bake to smear onto the flock."""
    e = MO["eye"]
    face = Vector((sx * e["face"][0], e["face"][1], e["face"][2])).normalized()
    d = (mo_normal(sx, e["y"], e["z"]) * 0.75 + face * 0.25).normalized()
    at = Vector((sx * mo_x(e["y"], e["z"]), e["y"], e["z"])) - d * 0.9
    return at, d, at + d * 2.3


def key_at():
    k = MO["key"]
    return Vector((mo_x(k["y"], k["z"]) - 0.4, k["y"], k["z"]))


def mo_body(hi):
    s = Shape()
    rows = smooth_rows([tuple(r) for r in MO["body"]], 4 if hi else 2)
    n = segs(hi, 20)
    rings = []
    for i, (y, hw, zb, zt) in enumerate(rows):
        if i in (0, len(rows) - 1):
            rings.append([(mm(0.0), mm(y), mm((zb + zt) / 2))])
        else:
            rings.append([tuple(mm(v) for v in mo_section((y, max(hw, 0.05), zb, zt),
                                                          2 * math.pi * j / n)) for j in range(n)])
    s.loft(rings, FLOCK)
    # domed printed eyes, a pink bead nose
    for sx in (1, -1):
        at, d, _ = eye_at(sx)
        r = MO["eye"]["r"]
        s.lathe([(mm(r * a), mm(b)) for a, b in EYE_PROF], MEYE, segs(hi, 16),
                T(V(*at)) @ frame(d, (0.0, 0.0, 1.0)))
    nx, ny, nz, nr = MO["nose"]
    blob(s, (nx, ny, nz), (nr, nr * 0.92, nr * 0.92), MNOSE, hi, lat=6, lon=12)
    # nylon whiskers fanning from each side of the snout, drooping a little
    wk = MO["whisker"]
    wy, wz = wk["at"]
    for sx in (1, -1):
        root = Vector((sx * (mo_x(wy, wz) - 0.6), wy, wz))
        for back, up in MO["whiskers"]:
            d = Vector((sx, back, up)).normalized()
            pts = [root + d * wk["len"] * q / 3 - Vector((0.0, 0.0, 1.6 * (q / 3) ** 2)) for q in range(4)]
            s.tube([tuple(V(*p)) for p in pts], mm(wk["r"]), WHISK, segs(hi, 3),
                   radii=[mm(wk["r"] * f) for f in (1.0, 0.8, 0.6, 0.4)])
    # the grey plastic plate underneath, the tin knob it rests on behind, the key's eyelet
    pl = MO["plate"]
    y0, y1 = pl["y"]
    z0, z1 = pl["z"]
    boxloft(s, [(z0, pl["hw"], (y1 - y0) / 2, pl["r"]), (z1, pl["hw"], (y1 - y0) / 2, pl["r"])],
            PLATE, segs(hi, 4), cy=(y0 + y1) / 2, bottom=z0, top=z1)
    ky, kr = MO["knob"]
    blob(s, (0.0, ky, kr), (kr, kr, kr), HUB, hi, lat=6, lon=12)
    ka = key_at()
    stud(s, (ka.x - 0.3, ka.y, ka.z), "+X", [(3.4, -0.8), (3.3, 0.2), (2.7, 0.65), (1.7, 0.7),
                                            (1.4, 0.2)], HUB, hi, 12)
    return s


def mo_ears(hi):
    """The felt ears, cupped forward, their feet sunk in the head: their own part, so the bake
    keeps them off the flock, and they flick when it stops dead."""
    s = Shape()
    ea = MO["ear"]
    k = ea["r"] / 8.4
    prof = [(mm(r * k), mm(z * k)) for r, z in EAR_PROF]
    for sx in (1, -1):
        R = frame((sx * ea["face"][0], ea["face"][1], ea["face"][2]), (sx * ea["lean"], 0.0, 1.0))
        foot = Vector((sx * ea["at"][0], ea["at"][1], ea["at"][2]))
        mid = foot + (R.to_3x3() @ Vector((0.0, 1.0, 0.0))) * ea["r"] * 0.78
        s.lathe(prof, FLOCK, segs(hi, 22), T(V(*mid)) @ R, kinds=EAR_KINDS)
    return s


def mo_wheels(hi):
    s = Shape()
    w = MO["wheel"]
    r, hw = w["r"], w["w"] / 2
    for sx in (1, -1):
        at = (sx * w["x"], 0.0, r)
        stud(s, at, "+X", [(r - 1.3, -hw), (r - 0.25, -hw + 0.05), (r - 0.02, -hw + 0.5), (r, 0.0),
                           (r - 0.02, hw - 0.5), (r - 0.25, hw - 0.05), (r - 1.3, hw)], TYRE, hi, 16)
        stud(s, at, "+X", [(0.0, -hw + 0.25), (r - 1.2, -hw + 0.25), (r - 1.2, hw - 0.25),
                           (0.0, hw - 0.25)], HUB, hi, 16)
    s.cylinder(V(-w["x"], 0.0, r), V(w["x"], 0.0, r), mm(0.8), HUB, segs(hi, 8))
    return s


def mo_tail(hi):
    s = Shape()
    pts = smooth_rows([tuple(p) for p in MO["tail"]], 4 if hi else 2)
    r0, r1 = MO["tail_r"]
    n = len(pts)
    radii = [mm(r0 + (r1 - r0) * (i / (n - 1)) ** 0.8) for i in range(n)]
    s.tube([tuple(V(*p)) for p in pts], radii[0], MTAIL, segs(hi, 8), radii=radii)
    blob(s, pts[-1], (r1, r1, r1), MTAIL, hi, lat=4, lon=8)
    return s


def mo_key(hi):
    """The robot's wing key, smaller, out of the left side."""
    s = Shape()
    k = MO["key"]
    Mk = T(V(*key_at())) @ Matrix.Rotation(math.radians(-90), 4, "Z")
    r, ln = k["shaft"]
    s.cylinder(Mk @ V(0.0, -1.5, 0.0), Mk @ V(0.0, ln, 0.0), mm(r), MKEY, segs(hi, 10))
    s.cylinder(Mk @ V(0.0, ln - 1.8, 0.0), Mk @ V(0.0, ln, 0.0), mm(2.3), MKEY, segs(hi, 14))
    hw, hl, out = k["wing"]
    t = k["t"]
    m = segs(hi, 14)
    Mw = Mk @ Matrix.Rotation(math.radians(90), 4, "Y")
    yc = ln + hl - 0.6
    bv = 0.25 if hi else 0.0
    for sw in (1, -1):
        lobe = [(sw * out + hw * math.cos(2 * math.pi * j / m), yc + hl * math.sin(2 * math.pi * j / m))
                for j in range(m)]
        prism(s, lobe, -t / 2, t / 2, MKEY, Mw, bv)
    prism(s, [(2.6, ln - 0.6), (2.6, yc + 2.0), (-2.6, yc + 2.0), (-2.6, ln - 0.6)], -t / 2, t / 2,
          MKEY, Mw, bv)
    return s


def mouse_look(L, f):
    nb = L.nb
    xm, ym, zm = nb.mul(L.x, K.STUD_MM), nb.mul(L.y, K.STUD_MM), nb.mul(L.z, K.STUD_MM)
    ax = nb.absf(xm)

    def sq(v):
        return nb.mul(v, v)

    def dist(c):
        return nb.math("SQRT", nb.add(nb.add(sq(nb.sub(ax, c[0])), sq(nb.sub(ym, c[1]))),
                                      sq(nb.sub(zm, c[2]))))

    # flock: a short nylon pile sprayed over the tin, a fine fuzz, mottled where it lay thick or
    # thin, its nap brushed back along the body
    fib = L.noise(1800.0, 1, detail=2)
    mott = L.noise(110.0, 2, detail=3)
    nap = L.noise(420.0, 3, stretch=(1.0, 0.25, 1.0), detail=2)
    col = nb.tint(nb.tint(hexc("#80857B"), nb.mr(mott, 0.3, 0.7, 0.9, 1.08)),
                  nb.mr(fib, 0.3, 0.7, 0.9, 1.07))
    C = Coat(L, col, nb.mr(fib, 0.3, 0.7, 0.86, 0.96), 0.0,
             nb.add(nb.mul(fib, 0.0008), nb.mul(nap, 0.0004)))
    flock = L.k(FLOCK)
    # rubbed flat and darker along the back where hands pick it up
    held = nb.mul(flock, nb.mul(nb.ss(zm, 25.0, 33.0), nb.ss(L.noise(60.0, 4, detail=3), 0.42, 0.62)))
    C.paint(nb.mul(held, 0.7), hexc("#696D65"), 0.72)
    # worn through to the dark shell at the snout's tip and along the underside's edge
    tip = nb.mul(flock, nb.sub(1.0, nb.ss(ym, -43.0, -39.5)))
    low = nb.mul(flock, nb.sub(1.0, nb.ss(zm, 2.6, 4.2)))
    bare = nb.mul(nb.add(tip, low), nb.ss(L.noise(150.0, 5, detail=4), 0.36, 0.52))
    C.paint(nb.mul(bare, 0.9), hexc("#3A3935"), 0.5, 0.0, 0.0)
    scuff = nb.mul(nb.mul(flock, L.edge(mm(0.8), k=4.0)), nb.ss(L.noise(300.0, 6, detail=4), 0.55, 0.68))
    C.paint(scuff, hexc("#5A5D55"), 0.78)
    # the ears' felt lining, pink, deeper where it cups
    ein = L.k(EAR_IN)
    C.paint(ein, nb.tint(hexc("#DCA49C"), nb.mr(fib, 0.3, 0.7, 0.86, 1.06)), 0.93, 0.0,
            nb.mul(fib, 0.0007))
    # printed eyes under clear domes: cream, a warm brown iris looking ahead, a black pupil, a
    # printed shine and a dark rim
    _, _, apex = eye_at(1)
    eye = L.k(MEYE)
    C.paint(eye, hexc("#F0EBDD"), 0.05, 0.0, 0.0)
    iris = (apex.x - 0.15, apex.y - 0.75, apex.z - 0.2)
    di = dist(iris)
    C.paint(nb.mul(eye, nb.sub(1.0, nb.ss(di, 1.95, 2.2))), hexc("#8E4326"), 0.05)
    C.paint(nb.mul(eye, nb.sub(1.0, nb.ss(di, 1.05, 1.25))), hexc("#0D0C0B"), 0.05)
    C.paint(nb.mul(eye, nb.sub(1.0, nb.ss(dist((apex.x - 0.1, apex.y - 0.3, apex.z + 0.95)), 0.35, 0.5))),
            hexc("#FFFFFF"), 0.05)
    C.paint(nb.mul(eye, nb.ss(dist(apex), 3.25, 3.4)), hexc("#4A3B33"), 0.06)
    # the bead nose: glossy pink, rubbed paler on its tip
    no = L.k(MNOSE)
    C.paint(no, nb.tint(hexc("#D8738A"), nb.mr(L.noise(300.0, 7), 0.3, 0.7, 0.92, 1.05)), 0.26, 0.0, 0.0)
    C.paint(nb.mul(no, nb.sub(1.0, nb.ss(ym, -47.2, -46.4))), hexc("#E9A2B0"), 0.35)
    C.paint(L.k(WHISK), hexc("#171614"), 0.35, 0.0, 0.0)
    # the tail: black moulded plastic, satin, scuffed grey in places
    tl = L.k(MTAIL)
    C.paint(tl, nb.tint(hexc("#1C1C1B"), nb.mr(L.noise(200.0, 8), 0.3, 0.7, 0.85, 1.15)),
            nb.mr(L.noise(260.0, 9), 0.3, 0.7, 0.36, 0.55), 0.0, 0.0)
    C.paint(nb.mul(tl, nb.ss(L.noise(500.0, 10, detail=4), 0.62, 0.72)), hexc("#4A4A47"), 0.6)
    # the key: brass, rubbed bright on the wings' edges
    ky = L.k(MKEY)
    C.paint(ky, nb.tint(hexc("#B8934A"), nb.mr(L.noise(90.0, 11, detail=3), 0.3, 0.7, 0.86, 1.06)),
            0.3, 1.0, 0.0)
    C.paint(nb.mul(ky, L.edge(mm(0.35), k=4.0)), hexc("#DDBE72"), 0.22)
    # underneath: grey plastic, dark slots the wheels show through; tin wheels with rubber tyres
    pl = L.k(PLATE)
    C.paint(pl, nb.tint(hexc("#5E5F5B"), nb.mr(L.noise(240.0, 12), 0.3, 0.7, 0.92, 1.06)), 0.6, 0.0, 0.0)
    slot = nb.mul(nb.mul(nb.ss(ax, 7.4, 7.7), nb.sub(1.0, nb.ss(ax, 11.1, 11.4))),
                  nb.sub(1.0, nb.ss(nb.absf(ym), 6.2, 6.6)))
    C.paint(nb.mul(pl, slot), hexc("#121211"), 0.7)
    C.paint(L.k(TYRE), nb.tint(hexc("#1E1D1C"), nb.mr(L.noise(300.0, 13), 0.3, 0.7, 0.9, 1.12)), 0.85, 0.0, 0.0)
    C.paint(L.k(HUB), nb.tint(hexc("#C4C5BE"), nb.mr(L.noise(160.0, 14, detail=3), 0.3, 0.7, 0.85, 1.04)),
            0.32, 1.0, 0.0)
    C.finish(f.dust, grime=0.5)
    return C.surface(bump_dist=0.0008, bump=0.6)


# --- how it runs ----------------------------------------------------------------------------------

def mouse_zip():
    """The run worked out from one spring: speed, the veer, the shimmy and buzz, the stall and its
    nose-down rocks, the wheels, the unwinding key, the tail on its cam whipping as plastic does."""
    dt = 1.0 / FPS

    def drive(t):
        u = min(t / ZP["length"], 1.0)
        return ZP["top"] * (1 - ZP["fade"] * u) * max(0.0, 1 - u ** ZP["knee"]) ** 0.5

    ts, vs = [], []
    t, stall, v0 = 0.0, None, 0.0
    while True:
        if stall is None and t > 0.5 and drive(t) < ZP["stall"]:
            stall, v0 = t, drive(t)
        v = drive(t) * smooth(0.0, ZP["grip"], t) if stall is None else \
            v0 * (1 - smooth(stall, stall + ZP["halt"], t))
        ts.append(t)
        vs.append(v)
        if stall is not None and t > stall + ZP["halt"] + 0.9:
            break
        t += dt
    n = len(ts)
    ds = [0.0]
    for i in range(1, n):
        ds.append(ds[-1] + (vs[i] + vs[i - 1]) / 2 * dt)
    dt_ = ds[-1]
    stop_i = next(i for i in range(n) if ts[i] >= stall + ZP["halt"])
    rock_t = stall + ZP["halt"] * 0.5
    wa, wl = ZP["wag"]
    wl = dt_ / max(1, round(dt_ / wl))           # a whole number of wags: the tail ends straight
    sa, sl = ZP["shimmy"]
    ba, bl = ZP["buzz"]
    tr = {k: [] for k in (("Body", "x"), ("Body", "y"), ("Body", "yaw"), ("Body", "pitch"),
                          ("Wheels", "turn"), ("Key", "turn"), ("Tail", "turn"), ("Tail", "pitch"),
                          ("Ears", "turn"))}
    x = y = 0.0
    cam = []
    for i in range(n):
        d, v = ds[i], vs[i]
        head = ZP["veer"] * d
        if i:
            a = math.radians(head)
            x += math.sin(a) * (ds[i] - ds[i - 1])
            y -= math.cos(a) * (ds[i] - ds[i - 1])
        tr[("Body", "x")].append(x)
        tr[("Body", "y")].append(y)
        tr[("Body", "yaw")].append(head + sa * math.sin(2 * math.pi * d / sl))
        p = ba * abs(math.sin(math.pi * d / bl)) * min(1.0, v / ZP["top"]) ** 0.5
        u = ts[i] - rock_t
        for peak, dur in ZP["rock"]:
            if 0.0 <= u < dur:
                p = 4 * peak * u * (dur - u) / (dur * dur)
                break
            u -= dur
        tr[("Body", "pitch")].append(p)
        tr[("Wheels", "turn")].append(math.degrees(d * K.STUD_MM / MO["wheel"]["r"]))
        tr[("Key", "turn")].append(180.0 * ZP["winds"] * (1.0 - d / dt_))
        cam.append(wa * math.sin(2 * math.pi * d / wl))

    def d2(vs_, i):
        return (vs_[min(i + 1, n - 1)] - 2 * vs_[i] + vs_[max(i - 1, 0)]) / (dt * dt)

    # the tail: stiff plastic on the cam, whipping behind each wag and ringing when it stops dead
    f_, z_ = ZP["tail"]
    w = 2 * math.pi * f_
    fy = fp = vy = vp = fe = ve = 0.0
    we, ze = 2 * math.pi * ZP["ears"][0], ZP["ears"][1]
    yaw = tr[("Body", "yaw")]
    pit = tr[("Body", "pitch")]
    for i in range(n):
        vy += (-w * w * fy - 2 * z_ * w * vy - d2(cam, i) - d2(yaw, i)) * dt
        vp += (-w * w * fp - 2 * z_ * w * vp - d2(pit, i)) * dt
        ve += (-we * we * fe - 2 * ze * we * ve - d2(pit, i)) * dt
        fe += ve * dt
        tr[("Ears", "turn")].append(max(-10.0, min(10.0, fe)))
        fy += vy * dt
        fp += vp * dt
        tr[("Tail", "turn")].append(cam[i] + max(-18.0, min(18.0, fy)))
        tr[("Tail", "pitch")].append(max(-15.0, min(15.0, fp)))

    ends = {0, stop_i, n - 1}

    def extremes(vs_):
        return {i for i in range(1, n - 1) if (vs_[i] - vs_[i - 1]) * (vs_[i + 1] - vs_[i]) < 0}

    quarter = {i for i in range(1, n) if math.floor(4 * ds[i] / sl) != math.floor(4 * ds[i - 1] / sl)}
    tracks = []
    for (part, ch), vs_ in tr.items():
        if (part, ch) in (("Body", "x"), ("Body", "y")):
            ks = rdp(ts, vs_, 0.0015)
        elif (part, ch) in (("Wheels", "turn"), ("Key", "turn")):
            ks = rdp(ts, vs_, 3.0)
        elif (part, ch) == ("Body", "pitch"):
            # the knob bounces: |sin| hops while it runs, parabolas as it rocks; a peak is reached
            # slowing (Out), a landing speeding up (In), which is exact for both
            ks = [(0.0, 0.0)]
            for i in sorted(extremes(vs_) | ends)[1:]:
                rising = vs_[i] > vs_[i - 1]
                style = "Quad" if ts[i] > rock_t else "Sine"
                ks.append((round(ts[i], 3), round(vs_[i], 4), style, "Out" if rising else "In"))
        else:
            pick = extremes(vs_) | ends | (quarter if (part, ch) == ("Body", "yaw") else set())
            ks = [(round(ts[i], 3), round(vs_[i], 4), "Sine", "InOut") for i in sorted(pick)]
            ks[0] = ks[0][:2]
        tracks.append((part, ch, ks))
    return round(ts[-1], 2), tracks, dt_, stall


def mouse_wind():
    keys, t = [(0.0, 0.0), (0.15, 0.0)], 0.15
    for i in range(ZP["winds"]):
        keys += [(t + 0.26, 180.0 * (i + 1), "Sine", "InOut"), (t + 0.4, 180.0 * (i + 1))]
        t += 0.4
    return round(t + 0.2, 2), [("Key", "turn", keys)]


MZIP_DUR, MZIP_TRACKS, MZIP_RUN, MZIP_STALL = mouse_zip()
MWIND_DUR, MWIND_TRACKS = mouse_wind()

WINDUP_MOUSE = kit.Find(
    "WindupMouse",
    [kit.Part("Body", mo_body),
     kit.Part("Ears", mo_ears, tuple(V(0.0, *MO["ear"]["at"][1:])), "Body", (1, 0, 0)),
     kit.Part("Wheels", mo_wheels, tuple(V(0.0, 0.0, MO["wheel"]["r"])), "Body", (1, 0, 0)),
     kit.Part("Tail", mo_tail, tuple(V(*MO["tail"][0])), "Body", (0, 0, 1)),
     kit.Part("Key", mo_key, tuple(V(*key_at())), "Body", (1, 0, 0))],
    mouse_look,
    motions={
        # the key wound in four half turns, a regrip between each
        "Wind": dict(duration=MWIND_DUR, focus="Key", distance=0.9, view=(2.0, -0.6, 0.7),
                     drop=0.0, tracks=MWIND_TRACKS),
        # set down, it zips off, curls a little to its left, slows as the spring gives out,
        # stalls dead and rocks onto its nose (where the game squeaks), its tail wagging behind
        "Zip": dict(duration=MZIP_DUR, focus=(0.0, mm(-5.0), mm(16.0)), distance=1.3, follow="Body",
                    view=(2.0, -0.9, 0.7), drop=0.0, tracks=MZIP_TRACKS),
    },
    dust=MO["dust"], seed=MO["seed"], texels=900,
)


# --- The clockwork tin bird (F-04d2) --------------------------------------------------------------
# An antique printed-tin songbird of our own (README): two pressed halves crimped along the back
# and belly, a bill of folded tin, a loose fan tail riveted under the rump, wire legs on stamped
# feet, a brass key in its left side. Wound and set down, it hops in little jumps, three at a
# time, then lifts its head, cocks its tail and whistles twice, lower and slower as it runs down.

BD = K.BIRD
HP = K.HOP
(TINB, BILL, MOUTH, TAILT, TAILB, TAILR, LEGW, FOOT, BKEY) = range(45, 54)


def bd_section(row, a):
    """A point round the body's section `row` (y, half width, belly, back, widest line) at angle
    a, anticlockwise seen from behind (+Y): two half ellipses meeting at the widest line."""
    y, hw, zb, zt, low = row
    zc = zb + low * (zt - zb)
    c, s = math.cos(a), math.sin(a)
    h = zt - zc if s >= 0 else zc - zb
    return (-hw * c, y, zc + h * s)


BD_FINE = smooth_rows([tuple(r) for r in BD["body"]], 8)


def bd_row(y):
    for a, b in zip(BD_FINE, BD_FINE[1:]):
        if a[0] <= y <= b[0]:
            u = (y - a[0]) / (b[0] - a[0])
            return tuple(p + (q - p) * u for p, q in zip(a, b))
    return BD_FINE[-1]


def bd_x(y, z):
    """The body's half width (mm) at y and height z."""
    _, hw, zb, zt, low = bd_row(y)
    zc = zb + low * (zt - zb)
    h = zt - zc if z >= zc else zc - zb
    s = min(1.0, abs(z - zc) / max(h, 1e-6))
    return hw * math.sqrt(max(0.0, 1 - s * s))


def bd_body(hi):
    s = Shape()
    rows = smooth_rows([tuple(r) for r in BD["body"]], 4 if hi else 2)
    n = segs(hi, 24)
    rings = []
    for i, row in enumerate(rows):
        y, hw, zb, zt, low = row
        if i in (0, len(rows) - 1):
            rings.append([(mm(0.0), mm(y), mm((zb + zt) / 2))])
        else:
            rings.append([tuple(mm(v) for v in bd_section((y, max(hw, 0.05), zb, zt, low),
                                                          2 * math.pi * j / n)) for j in range(n)])
    s.loft(rings, TINB)
    return s


def bill_rings(upper, hi, gap=0.0):
    """The folded tin bill, base (sunk in the face) to tip: D-shaped rings, the upper bill's
    round side up and the lower's down, their flat sides meeting at the gape."""
    b = BD["bill"]
    (y0, z0), (y1, z1) = b["base"], b["tip"]
    m, k = segs(hi, 8), segs(hi, 3)
    nr = segs(hi, 7)
    rings = []
    for i in range(nr + 1):
        u = i / nr
        y = y0 + (y1 - y0) * u
        zg = z0 + (z1 - z0) * u - b["droop"] * u * u - gap
        if i == nr:
            rings.append([(mm(0.0), mm(y), mm(zg))])
            break
        w = b["hw"] * (1 - u) ** 0.85
        h = (b["up"] if upper else b["lo"]) * (1 - u) ** 0.75
        ring = []
        if upper:      # over the top from +x to -x, then back along the flat underside
            ring += [(w * math.cos(math.pi * j / m), zg + h * math.sin(math.pi * j / m)) for j in range(m)]
            ring += [(-w + 2 * w * j / k, zg) for j in range(k)]
        else:          # under from -x to +x, then back along the flat top
            ring += [(-w * math.cos(math.pi * j / m), zg - h * math.sin(math.pi * j / m)) for j in range(m)]
            ring += [(w - 2 * w * j / k, zg) for j in range(k)]
        rings.append([(mm(x), mm(y), mm(z)) for x, z in ring])
    return rings, m


def bd_bill(hi):
    s = Shape()
    rings, m = bill_rings(True, hi)
    s.loft(rings, BILL, kinds=lambda j: BILL if j < m else MOUTH)
    return s


def bd_beak(hi):
    s = Shape()
    rings, m = bill_rings(False, hi, gap=0.06)
    s.loft(rings, BILL, kinds=lambda j: BILL if j < m else MOUTH)
    return s


def plate(s, cols, t, kinds, M=Matrix()):
    """A tin plate (mm) from a grid of its top surface `cols` [i][j] (i across, j along), `t`
    thick below it, placed by M: its top, its underside and its rim strip are each one island
    unrolled at true size. `kinds` (top, underside, rim)."""
    ni, nj = len(cols), len(cols[0])
    top = [[s._v(V(*p), M) for p in col] for col in cols]
    bot = [[s._v(V(p[0], p[1], p[2] - t), M) for p in col] for col in cols]
    ko, ku, kr = kinds
    o1, o2 = s.island(), s.island()
    for i in range(ni - 1):
        for j in range(nj - 1):
            q = [(i, j), (i + 1, j), (i + 1, j + 1), (i, j + 1)]
            s._f([top[a][b] for a, b in q], ko, [o1 + Vector((mm(cols[a][b][0]), mm(cols[a][b][1])))
                                                 for a, b in q])
            q.reverse()
            s._f([bot[a][b] for a, b in q], ku, [o2 + Vector((-mm(cols[a][b][0]), mm(cols[a][b][1])))
                                                 for a, b in q])
    # the rim, anticlockwise round the outline seen from above
    loop = ([(i, 0) for i in range(ni - 1)] + [(ni - 1, j) for j in range(nj - 1)]
            + [(i, nj - 1) for i in range(ni - 1, 0, -1)] + [(0, j) for j in range(nj - 1, 0, -1)])
    o3, run = s.island(), 0.0
    for q, (a, b) in enumerate(loop):
        c, d = loop[(q + 1) % len(loop)]
        step = (Vector(cols[c][d]) - Vector(cols[a][b])).length
        uv = [o3 + Vector((mm(u), mm(v))) for u, v in ((run, 0.0), (run + step, 0.0), (run + step, t), (run, t))]
        s._f([bot[a][b], bot[c][d], top[c][d], top[a][b]], kr, uv)
        run += step


def tail_cols(hi):
    """The fan tail's top in its own frame: across x, along +y from its root, the fold along its
    middle lifting the rib, the end cut into rounded feather tips, the outer ones shorter."""
    tl = BD["tail"]
    ln, (w0, w1), tips = tl["len"], tl["w"], tl["tips"]
    ni, nj = segs(hi, 20) + 1, segs(hi, 7) + 1
    fold = math.tan(math.radians(tl["fold"]))
    cols = []
    for i in range(ni):
        u = -1 + 2 * i / (ni - 1)
        k = min(tips - 1, int((u + 1) / 2 * tips))
        q = (u + 1) / 2 * tips - k
        end = ln - 2.6 * u * u - 3.4 * (1 - math.sqrt(max(0.0, 1 - (2 * q - 1) ** 2)))
        col = []
        for j in range(nj):
            v = j / (nj - 1)
            y = end * v
            x = u * (w0 + (w1 - w0) * (y / ln) ** 0.8) / 2
            col.append((x, y, -abs(x) * fold - 0.006 * y * y / 10))
        cols.append(col)
    return cols


def tail_frame():
    tl = BD["tail"]
    return T(V(0.0, *tl["root"])) @ Matrix.Rotation(math.radians(tl["rise"]), 4, "X")


def bd_tail(hi):
    s = Shape()
    plate(s, tail_cols(hi), BD["tail"]["t"], (TAILT, TAILB, TAILR), tail_frame())
    return s


def foot_at(sx):
    return Vector((sx * BD["leg"]["x"], BD["leg"]["foot"], 0.0))


def bd_legs(hi):
    """Two wire legs out of the crank in the belly, each on a stamped foot: three toes ahead,
    one behind, a round heel where they meet. Both swing together about the hip."""
    s = Shape()
    lg, tw = BD["leg"], BD["toe"]
    hy, hz = BD["hip"]
    for sx in (1, -1):
        heel = foot_at(sx)
        pts = [heel + Vector((0.0, 0.3, 0.9)), heel + Vector((0.0, -0.1, 6.0)),
               heel + Vector((0.0, 0.7, 13.5)), Vector((heel.x, hy, hz + 1.5))]
        s.tube([tuple(V(*p)) for p in pts], mm(lg["r"]), LEGW, segs(hi, 6),
               radii=[mm(lg["r"] * f) for f in (1.25, 1.0, 1.0, 1.0)])
        s.cylinder(V(heel.x, heel.y, 0.0), V(heel.x, heel.y, tw["t"] + 0.35), mm(2.2), FOOT,
                   segs(hi, 12))
        for ln, ang in BD["toes"]:
            a = math.radians(ang) * sx
            d = Vector((math.sin(a), -math.cos(a), 0.0))
            side = Vector((d.y, -d.x, 0.0))     # across, so across x along is up
            ni, nj = segs(hi, 4) + 1, segs(hi, 4) + 1
            cols = []
            for i in range(ni):
                u = -1 + 2 * i / (ni - 1)
                end = ln - 1.0 * (1 - math.sqrt(max(0.0, 1 - u * u)))
                col = []
                for j in range(nj):
                    v = j / (nj - 1)
                    r = 1.2 + (end - 1.2) * v
                    w = tw["w"] * (1 - 0.4 * v) / 2
                    p = heel + d * r + side * (u * w)
                    col.append((p.x, p.y, tw["t"] + 0.25 * (1 - v) ** 2))
                cols.append(col)
            plate(s, cols, tw["t"], (FOOT, FOOT, FOOT))
    return s


def bd_key_at():
    k = BD["key"]
    return Vector((bd_x(k["y"], k["z"]) - 0.4, k["y"], k["z"]))


def bd_key(hi):
    """The wing key out of its left side, the mouse's."""
    s = Shape()
    k = BD["key"]
    Mk = T(V(*bd_key_at())) @ Matrix.Rotation(math.radians(-90), 4, "Z")
    r, ln = k["shaft"]
    s.cylinder(Mk @ V(0.0, -1.5, 0.0), Mk @ V(0.0, ln, 0.0), mm(r), BKEY, segs(hi, 10))
    s.cylinder(Mk @ V(0.0, ln - 1.8, 0.0), Mk @ V(0.0, ln, 0.0), mm(2.3), BKEY, segs(hi, 14))
    hw, hl, out = k["wing"]
    t = k["t"]
    m = segs(hi, 14)
    Mw = Mk @ Matrix.Rotation(math.radians(90), 4, "Y")
    yc = ln + hl - 0.6
    bv = 0.25 if hi else 0.0
    for sw in (1, -1):
        lobe = [(sw * out + hw * math.cos(2 * math.pi * j / m), yc + hl * math.sin(2 * math.pi * j / m))
                for j in range(m)]
        prism(s, lobe, -t / 2, t / 2, BKEY, Mw, bv)
    prism(s, [(2.4, ln - 0.6), (2.4, yc + 1.8), (-2.4, yc + 1.8), (-2.4, ln - 0.6)], -t / 2, t / 2,
          BKEY, Mw, bv)
    return s


def bird_look(L, f):
    nb = L.nb
    xm, ym, zm = nb.mul(L.x, K.STUD_MM), nb.mul(L.y, K.STUD_MM), nb.mul(L.z, K.STUD_MM)
    ax = nb.absf(xm)

    def sq(v):
        return nb.mul(v, v)

    def lin(c, *terms):
        """c plus each (k, v) as k times v."""
        out = c
        for k, v in terms:
            out = nb.add(out, nb.mul(v, k))
        return out

    def both(*ms):
        out = ms[0]
        for m in ms[1:]:
            out = nb.mul(out, m)
        return out

    def less(v, a, soft=0.15):
        """1 below a."""
        return nb.ss(v, a + soft, a - soft)

    def disc(u, v, cu, cv, r, soft=0.12):
        return less(nb.math("SQRT", nb.add(sq(nb.sub(u, cu)), sq(nb.sub(v, cv)))), r, soft)

    def scales(u, v, pu, pv, k=2.0):
        """Overlapping printed feathers in rows along u (each row `pu` mm), their round tips
        toward +u and every other row offset half a feather: how far toward a feather's rim a
        point lies, 0 at its base, 1 on its rim."""
        a = nb.div(u, pu)
        row = nb.math("FLOOR", a)
        c = nb.add(nb.div(v, pv), nb.mul(nb.math("FLOORED_MODULO", row, 2.0), 0.5))
        fa, fc = nb.fract(a), nb.sub(nb.fract(c), 0.5)
        return nb.math("SQRT", nb.add(sq(fa), sq(nb.mul(fc, k))))

    CREAM, GOLD, OCHRE, SCAR, CRIMSON = "#EFE2C2", "#E7AE34", "#C9822A", "#C22B26", "#86171A"
    INK, OLIVE, DBROWN, TEAL, TEAL2 = "#1A1612", "#77653A", "#3A2A1E", "#2E6E78", "#245A63"
    BARGOLD, BUFF, GREY, RUST, TINP = "#F0C24A", "#B98F55", "#8D8B78", "#B0532A", "#C3C5BE"
    grain = L.noise(700.0, 1, detail=1)
    tone = nb.mr(grain, 0.3, 0.7, 0.96, 1.03)
    gloss = nb.mr(L.noise(90.0, 2, detail=3), 0.3, 0.7, 0.26, 0.36)
    C = Coat(L, hexc(CREAM), gloss, 0.0, 0.0)
    tin = L.k(TINB)
    side = nb.ss(nb.absf(L.nx), 0.15, 0.45)
    up = nb.ss(L.nz, 0.2, 0.55)
    down = nb.ss(nb.sub(0.0, L.nz), 0.35, 0.7)

    # --- the gold throat and breast, deeper ochre round the flanks, streaked brown on the sides
    # a cream throat under the bill, so the orange bill stands out against it
    zg = lin(40.5, (-0.0088, sq(nb.add(ym, 34.0))))
    breast = both(tin, less(nb.sub(zm, zg), 0.0, 1.2))
    deep = nb.mr(nb.add(nb.mul(nb.absf(L.nx), 0.8), nb.mul(nb.ss(zm, 26.0, 40.0), 0.5)), 0.2, 1.1, 0.0, 1.0)
    C.paint(breast, nb.mixc(deep, nb.tint(hexc(GOLD), tone), hexc(OCHRE)), gloss)
    streak = nb.ss(L.noise(260.0, 3, stretch=(1.0, 1.0, 0.22), detail=2), 0.64, 0.71)
    C.paint(both(breast, streak, nb.ss(ax, 7.0, 11.0), nb.ss(ym, -20.0, -12.0)), hexc("#93552A"), gloss)
    # small printed feathers down the breast, their tips pointing down, keyed in ochre
    bf = scales(nb.sub(60.0, zm), nb.add(xm, ym), 2.7, 2.5)
    C.paint(nb.mul(both(breast, nb.band(bf, 0.82, 1.0, 0.07)), 0.75), nb.tint(hexc("#A8601F"), tone), gloss)
    C.paint(nb.mul(both(breast, nb.band(bf, 0.3, 0.55, 0.12)), 0.4), hexc("#F6CB62"), gloss)
    # the belly behind the legs: cream, shading to buff toward the rump
    C.paint(both(tin, nb.ss(ym, 4.0, 16.0), down, nb.ss(ym, 20.0, 32.0)), hexc(BUFF), gloss)

    # --- the back between the wings: olive, scalloped with small dark-edged feathers; a buff rump
    back = both(tin, up, nb.ss(ym, -11.0, -6.0))
    C.paint(back, nb.tint(hexc(OLIVE), tone), gloss)
    dm = scales(nb.add(ym, 8.0), xm, 2.6, 2.3)
    C.paint(both(back, nb.band(dm, 0.62, 0.86, 0.06)), hexc("#9C8650"), gloss)
    C.paint(both(back, nb.band(dm, 0.86, 1.0, 0.05)), hexc("#3B3020"), gloss)
    rump = both(tin, nb.ss(ym, 25.0, 30.0), nb.ss(nb.add(L.nz, L.ny), 0.3, 0.7))
    C.paint(rump, nb.tint(hexc(BUFF), tone), gloss)

    # --- the scarlet cap, printed the way the old lithographers did it (the V&A's sparrow): it
    # sweeps from the bill over the crown and down the nape, deeper crimson toward its edge with a
    # paler printed sheen on the crown, keyed with rows of small crimson-edged feathers that point
    # back; under its edge a dove-grey stripe runs from the bill over the eye and down the neck
    zc = lin(49.6, (4.6, nb.ss(ym, -34.0, -25.5)), (-7.0, nb.ss(ym, -21.0, -9.0)))
    dz = nb.sub(zm, zc)
    nape = less(ym, -7.0, 1.2)
    cap = both(tin, nb.ss(dz, 0.0, 0.3), nape)
    inner = nb.mul(nb.ss(dz, 0.3, 5.0), nb.ss(ym, -6.5, -10.5))
    C.paint(cap, nb.mixc(inner, nb.tint(hexc(CRIMSON), tone), nb.tint(hexc(SCAR), tone)), gloss)
    sheen = both(cap, nb.ss(zm, 56.5, 60.0), less(ax, 7.0, 3.0), nb.band(ym, -29.0, -15.0, 3.0))
    C.paint(nb.mul(sheen, 0.6), hexc("#E5613F"), gloss)
    cf = scales(nb.add(ym, 40.0), nb.add(xm, zm), 2.4, 2.2)
    C.paint(both(cap, nb.ss(dz, 0.8, 1.6), nb.band(cf, 0.8, 1.0, 0.07)), hexc("#6E1216"), gloss)
    C.paint(nb.mul(both(cap, nb.band(cf, 0.25, 0.5, 0.1)), 0.35), hexc("#E8573E"), gloss)
    stripe = both(tin, side, nb.band(dz, -2.6, 0.0, 0.3), nb.band(ym, -33.0, -7.5, 1.2))
    C.paint(stripe, nb.tint(hexc("#A3A59B"), tone), gloss)
    C.paint(both(stripe, less(dz, -2.0, 0.3)), nb.tint(hexc("#7F8178"), tone), gloss)
    C.paint(both(tin, side, nb.band(dz, -0.18, 0.18, 0.1), nb.band(ym, -33.0, -7.5, 1.0)), hexc("#4E0F12"), gloss)

    # --- the printed eye, pressed into a low dome: an ink rim, a cream ring, a gold iris, the
    # pupil and its shine
    ey, ez = BD["eye"]["y"], BD["eye"]["z"]
    er = BD["eye"]["r"]
    face = both(tin, nb.ss(nb.absf(L.nx), 0.3, 0.6))
    de = nb.math("SQRT", nb.add(sq(nb.sub(ym, ey)), sq(nb.sub(zm, ez))))
    C.paint(both(face, less(de, er, 0.12)), hexc(INK), 0.18, 0.0, nb.mul(nb.mr(de, 0.0, er, 1.3, 0.0), 1.0))
    C.paint(both(face, less(de, er - 0.55, 0.1)), hexc("#F5EEDA"), 0.16)
    C.paint(both(face, less(de, er - 1.15, 0.1)), hexc("#D9952B"), 0.16)
    C.paint(both(face, less(de, er - 2.05, 0.1)), hexc("#0C0B0A"), 0.14)
    C.paint(both(face, disc(ym, zm, ey - 0.55, ez + 0.6, 0.42, 0.1)), hexc("#FFFFFF"), 0.14)

    # --- the wing: pressed proud of the body and printed in three parts, front to back: teal
    # scalloped coverts, a cream and then a gold bar, long dark flight feathers edged in ochre
    # with a hairline of gold ink, converging to its point over the rump
    q = nb.div(nb.sub(ym, 14.0), 23.0)
    W = nb.mul(nb.mul(nb.math("SQRT", nb.mx(nb.sub(1.0, sq(q)), 0.0)), 17.0),
               nb.sub(1.0, nb.mul(nb.mx(q, 0.0), 0.3)))
    ztop = lin(48.3, (-0.33, ym))
    v = nb.div(nb.sub(ztop, zm), nb.mx(W, 0.05))
    xin = lin(5.5, (8.0, nb.ss(q, -0.6, -1.0)))
    wing_out = both(tin, less(v, 1.0, 0.04), nb.ss(nb.sub(ax, xin), 0.0, 0.4), less(nb.absf(q), 1.0, 0.02),
                    nb.ss(ax, 3.0, 5.0))
    wing = both(tin, less(v, 0.94, 0.03), nb.ss(nb.sub(ax, xin), 0.6, 1.0),
                less(nb.absf(q), 0.97, 0.02))
    C.paint(wing_out, hexc(INK), gloss, 0.0, 0.6)
    C.paint(wing, nb.tint(hexc(TEAL), tone), gloss, 0.0, 0.4)
    uw = nb.div(nb.add(ym, 9.0), 46.0)
    vw = nb.mn(nb.mx(v, 0.0), 1.0)
    cov = both(wing, less(uw, 0.30, 0.004))
    dc = scales(nb.add(ym, 9.0), nb.mul(vw, 17.0), 3.1, 2.9)
    C.paint(both(cov, nb.ss(L.noise(40.0, 5), 0.3, 0.7)), hexc(TEAL2))
    C.paint(both(cov, nb.band(dc, 0.66, 0.87, 0.05)), hexc("#D9CFAE"), gloss, 0.0, 0.15)
    C.paint(both(cov, nb.band(dc, 0.87, 1.0, 0.04)), hexc(INK), gloss, 0.0, 0.25)
    C.paint(both(wing, nb.band(uw, 0.30, 0.335, 0.004)), hexc(CREAM), gloss)
    C.paint(both(wing, nb.band(uw, 0.335, 0.35, 0.003)), hexc(INK), gloss)
    C.paint(both(wing, nb.band(uw, 0.35, 0.43, 0.004)), nb.tint(hexc(BARGOLD), tone), gloss)
    flight = both(wing, nb.ss(uw, 0.43, 0.434))
    fv = nb.mul(vw, 5.0)
    fr = nb.fract(fv)
    fk = nb.math("FLOORED_MODULO", nb.math("FLOOR", fv), 2.0)
    C.paint(flight, nb.mixc(fk, nb.tint(hexc(DBROWN), tone), nb.tint(hexc("#4C3726"), tone)), gloss)
    C.paint(both(flight, nb.ss(fr, 0.68, 0.74)), nb.tint(hexc("#C79A4E"), tone), gloss)
    C.paint(both(flight, nb.band(fr, 0.6, 0.64, 0.02)), hexc("#D8B266"), 0.26, 0.85)
    C.paint(both(flight, nb.mx(less(fr, 0.06, 0.02), nb.ss(fr, 0.95, 0.99))), hexc(INK), gloss, 0.0, -0.25)
    C.paint(both(wing, nb.band(uw, 0.425, 0.44, 0.003)), hexc(INK), gloss)

    # --- the crimped seam along the back and belly, its tabs, the key's bush, the legs' slots
    seam = both(tin, less(ax, 0.55, 0.3), less(nb.absf(L.nx), 0.45, 0.1))
    C.paint(seam, None, None, None, 0.9)
    C.paint(both(seam, less(ax, 0.22, 0.08)), hexc("#5A4A36"), gloss)
    for ty in (-6.0, 11.0, 25.0):
        tab = both(tin, down, less(ax, 1.5, 0.12), less(nb.absf(nb.sub(ym, ty)), 1.1, 0.12))
        C.paint(tab, hexc(TINP), 0.3, 1.0, 1.0)
    ky, kz = BD["key"]["y"], BD["key"]["z"]
    left = both(tin, nb.ss(xm, 4.0, 6.0))
    C.paint(both(left, disc(ym, zm, ky, kz, 3.0)), hexc(INK), gloss)
    C.paint(both(left, disc(ym, zm, ky, kz, 2.6)), hexc(TINP), 0.3, 1.0, 0.7)
    C.paint(both(left, disc(ym, zm, ky, kz, 1.5)), hexc("#151310"), 0.6, 0.0)
    hy = BD["hip"][0]
    slot = both(tin, down, nb.band(ax, BD["leg"]["x"] - 1.3, BD["leg"]["x"] + 1.3, 0.15),
                nb.band(ym, hy - 2.8, hy + 2.2, 0.15))
    C.paint(slot, hexc("#100E0C"), 0.7)
    # our maker's mark under the belly: a cream oval in a red ring, an ink star in it
    mu, mv = nb.sub(xm, 5.0), nb.sub(ym, 17.0)
    mo = nb.add(sq(nb.div(mu, 3.0)), sq(nb.div(mv, 4.6)))
    mark = both(tin, down)
    C.paint(both(mark, less(mo, 1.0, 0.05)), hexc("#B8312B"), gloss)
    C.paint(both(mark, less(mo, 0.62, 0.05)), hexc(CREAM), gloss)
    star = nb.add(nb.math("SQRT", nb.absf(mu)), nb.math("SQRT", nb.absf(nb.mul(mv, 0.8))))
    C.paint(both(mark, less(star, 1.45, 0.08)), hexc(INK), gloss)

    # --- antique wear: the print rubbed through to bright tinplate on the high points and the
    # seam, small chips, freckles of rust low down, fine scratches in the varnish
    hi_pts = nb.mx(nb.mx(nb.ss(zm, 59.4, 60.4), both(nb.ss(nb.sub(0.0, L.ny), 0.7, 0.9), nb.band(zm, 27.0, 40.0, 3.0))),
                   less(ax, 0.5, 0.2))
    rub = both(tin, hi_pts, nb.ss(L.noise(120.0, 6, detail=4), 0.5, 0.62))
    # chips only where hands and knocks reach: the high points, the seam and the edges
    chips = both(tin, nb.mx(hi_pts, L.edge(mm(1.2), k=3.0)), nb.ss(L.noise(55.0, 7, detail=5, rough=0.7), 0.74, 0.77))
    worn = nb.mx(rub, nb.mx(chips, both(tin, L.edge(mm(0.5), k=4.0), nb.ss(L.noise(200.0, 8, detail=4), 0.6, 0.7))))
    C.paint(worn, hexc(TINP), 0.3, 1.0, -0.15)
    rusty = nb.mul(L.k(TINB, TAILR, TAILB), nb.ss(L.noise(70.0, 9, detail=5, rough=0.7), 0.76, 0.8))
    C.paint(nb.mul(rusty, nb.mx(less(zm, 22.0, 3.0), L.k(TAILR, TAILB))), hexc("#6B381D"), 0.85, 0.0, 0.1)
    scratch = both(tin, nb.ss(L.noise(900.0, 10, stretch=(1.0, 0.04, 1.0), detail=1), 0.74, 0.77))
    C.paint(nb.mul(scratch, 0.5), hexc("#E6E0CC"), 0.4)

    # --- the bill: folded orange tin, darker at the tip, ink along the gape, a nostril each side
    bl = L.k(BILL)
    by0 = BD["bill"]["base"][0]
    C.paint(bl, nb.mixc(nb.ss(ym, by0 - 6.0, by0 - 15.5), nb.tint(hexc("#E49125"), tone), hexc("#A9561B")), 0.3)
    C.paint(both(bl, L.edge(mm(0.35), k=4.0)), hexc(INK), 0.3)
    C.paint(both(bl, disc(ax, ym, 1.6, by0 - 5.0, 0.45, 0.1), nb.ss(L.nz, 0.3, 0.6)), hexc(INK), 0.3)
    C.paint(both(bl, L.edge(mm(0.25), k=4.0), nb.ss(L.noise(150.0, 11, detail=3), 0.5, 0.6)), hexc(TINP), 0.3, 1.0)
    C.paint(L.k(MOUTH), hexc("#7A2620"), 0.5, 0.0)

    # --- the tail: a fan of rust feathers on gold lacquer tin, shafts in ochre, three dark bars
    # chevroned to the root, cream tips, its cut edge bare tinplate
    tt = L.k(TAILT)
    ry, rz = BD["tail"]["root"]
    ca, sa = math.cos(math.radians(BD["tail"]["rise"])), math.sin(math.radians(BD["tail"]["rise"]))
    st = lin(0.0, (ca, nb.sub(ym, ry)), (sa, nb.sub(zm, rz)))
    phi = nb.math("ARCTAN2", xm, nb.add(st, 9.0))
    ft = nb.add(nb.mul(phi, 17.0), 4.0)
    ff = nb.fract(ft)
    C.paint(tt, nb.mixc(nb.math("FLOORED_MODULO", nb.math("FLOOR", ft), 2.0), nb.tint(hexc(RUST), tone),
                        nb.tint(hexc("#A04726"), tone)), gloss)
    C.paint(both(tt, nb.ss(nb.absf(nb.sub(ff, 0.5)), 0.3, 0.45)), hexc("#7E3A1E"), gloss)
    chev = nb.sub(st, nb.mul(nb.absf(nb.sub(ff, 0.5)), 2.4))
    for b0, b1 in ((12.0, 15.0), (22.0, 25.5), (31.5, 35.0)):
        C.paint(both(tt, nb.band(chev, b0, b1, 0.25)), hexc(DBROWN), gloss)
    C.paint(both(tt, less(nb.absf(nb.sub(ff, 0.5)), 0.035, 0.012), nb.ss(st, 3.0, 6.0)), hexc("#D7A25A"), 0.26, 0.6)
    C.paint(both(tt, less(nb.absf(nb.sub(ff, 0.0)), 0.02, 0.01)), hexc(INK), gloss)
    C.paint(both(tt, nb.ss(nb.sub(st, lin(37.0, (-0.022, sq(xm)))), 0.0, 1.5)), hexc(CREAM), gloss)
    C.paint(both(tt, L.edge(mm(0.45), k=4.0)), hexc(INK), gloss)
    C.paint(L.k(TAILB), nb.tint(hexc("#BE9A55"), nb.mr(L.noise(60.0, 12, detail=3), 0.3, 0.7, 0.85, 1.05)), 0.34, 0.75)
    C.paint(L.k(TAILR), hexc("#B5B6AE"), 0.35, 1.0)
    C.paint(both(L.k(TAILT, TAILB), L.edge(mm(0.3), k=4.0), nb.ss(L.noise(180.0, 13, detail=4), 0.45, 0.6)),
            hexc(TINP), 0.3, 1.0)

    # --- legs and feet: dark brown enamel over steel, the toes' tips and heels knocked bright
    lg = L.k(LEGW, FOOT)
    C.paint(lg, nb.tint(hexc("#3A2A20"), nb.mr(L.noise(150.0, 14, detail=3), 0.3, 0.7, 0.85, 1.1)), 0.5, 0.0)
    C.paint(both(lg, L.edge(mm(0.35), k=4.0), nb.ss(L.noise(120.0, 15, detail=4), 0.45, 0.58)),
            hexc("#8F8C84"), 0.4, 1.0)
    C.paint(both(lg, nb.ss(L.noise(90.0, 16, detail=5), 0.72, 0.77)), hexc("#5E3218"), 0.85, 0.0)

    # --- the key: brass, rubbed bright on the wings' edges
    kk = L.k(BKEY)
    C.paint(kk, nb.tint(hexc("#B8934A"), nb.mr(L.noise(90.0, 17, detail=3), 0.3, 0.7, 0.86, 1.06)), 0.3, 1.0, 0.0)
    C.paint(nb.mul(kk, L.edge(mm(0.35), k=4.0)), hexc("#DDBE72"), 0.22)
    C.finish(f.dust, grime=0.45)
    return C.surface(bump_dist=0.0015, bump=0.7)


# --- how it hops ----------------------------------------------------------------------------------
# One crank, one turn a beat: three hops, then a whistle that takes two turns. A hop is written
# exactly: crouched on its feet it kicks (the legs swing back and the body moves forward by just
# what keeps the feet planted), then flies a parabola (Quad Out to the peak, Quad In to the floor:
# its flight time is the one gravity gives that height), swivelling a little, legs reaching
# forward to land, and rocks onto its breast. The loose tin tail and the hinged lower bill ring
# off the body's motion as damped springs: the tail floats up in the air and slaps down on each
# landing; the bill flicks open on a landing and sings on a whistle.

G_MM = 9810.0


def hop_rate(t):
    u = min(t / HP["length"], 1.0)
    return HP["rate"] * (1 - HP["fade"] * u) * max(0.0, 1 - u ** HP["knee"]) ** 0.5


def bird_hop():
    leg_len = BD["hip"][1]
    tr = {k: [(0.0, 0.0)] for k in (("Body", "x"), ("Body", "y"), ("Body", "z"), ("Body", "yaw"),
                                     ("Body", "pitch"), ("Legs", "turn"))}
    sing_tail, sing_bill = [(0.0, 0.0)], [(0.0, 0.0)]
    beats = []
    t, k, hops = 0.0, 0, 0
    x = y = head = 0.0
    while True:
        r = hop_rate(t)
        if r < HP["stall"]:
            break
        B = 1.0 / r
        p = r / HP["rate"]
        if k % (HP["pattern"] + 1) == HP["pattern"]:
            # the whistle: head up, tail cocked, two notes, over two turns of the crank
            D = 2 * B
            s = p ** 0.5
            hu, tc, bo = HP["sing"]
            tr[("Body", "pitch")] += [(t + 0.22 * D, -hu * s), (t + 0.78 * D, -hu * s * 0.85),
                                      (t + D, 0.0)]
            sing_tail += [(t + 0.18 * D, tc * s, "Sine", "Out"), (t + 0.8 * D, tc * s * 0.8),
                          (t + D, 0.0)]
            for c0, a in ((0.24, 1.0), (0.56, 0.82)):
                c = t + c0 * D
                sing_bill += [(c, 0.0), (c + 0.045, bo * a * s, "Quad", "Out"),
                              (c + 0.11, bo * a * s * 0.9), (c + 0.16, 0.0, "Quad", "In")]
            beats.append((t, D, "whistle"))
            t += D
            k += 1
            continue
        h = HP["height"] * p ** 1.5
        tf = math.sqrt(8 * h / G_MM)
        tp = HP["push"] * B
        ta, tl = t + tp, t + tp + tf
        kd, kl = HP["kick"]
        leg_kick = kl * p
        push = leg_len * math.sin(math.radians(leg_kick))
        step = HP["step"] * p
        hops += 1
        side = 1 if hops % 2 else -1
        new_head = head + side * HP["turn"][0] * p + HP["turn"][1]
        a0 = math.radians(head)
        xp, yp = x + math.sin(a0) * push, y - math.cos(a0) * push
        am = math.radians((head + new_head) / 2)
        x1, y1 = xp + math.sin(am) * step, yp - math.cos(am) * step
        c0 = t + 0.15 * tp
        tr[("Body", "x")] += [(c0, x), (ta, xp, "Sine", "In"), (tl, x1, "Linear", "In")]
        tr[("Body", "y")] += [(c0, y), (ta, yp, "Sine", "In"), (tl, y1, "Linear", "In")]
        tr[("Legs", "turn")] += [(c0, 0.0), (ta, leg_kick, "Sine", "In"),
                                 (ta + tf * 0.55, HP["tuck"] * p), (tl, 0.0, "Sine", "In")]
        tr[("Body", "z")] += [(ta, 0.0), (ta + tf / 2, h, "Quad", "Out"), (tl, 0.0, "Quad", "In")]
        tr[("Body", "yaw")] += [(ta, head), (tl, new_head)]
        settle = min(t + B, tl + 0.2)
        tr[("Body", "pitch")] += [(t + 0.6 * tp, kd * p), (ta, kd * p * 0.3, "Sine", "In"),
                                  (ta + tf / 2, -2.5 * p, "Sine", "Out"), (tl, 0.0, "Sine", "In"),
                                  (tl + (settle - tl) * 0.35, HP["land"] * p, "Sine", "Out"),
                                  (settle, 0.0)]
        x, y, head = x1, y1, new_head
        beats.append((t, B, "hop"))
        t += B
        k += 1
    end = t + 0.9
    # the key unwinds through its half turns as the crank turns
    turns = sum(2 if kind == "whistle" else 1 for _, _, kind in beats)
    key, done = [(0.0, 180.0 * HP["winds"])], 0
    for t0, D, kind in beats:
        done += 2 if kind == "whistle" else 1
        key.append((round(t0 + D, 3), round(180.0 * HP["winds"] * (1 - done / turns), 3), "Linear", "In"))

    # the springs, sampled off the written keys
    dt = 1.0 / FPS
    ts = [i * dt for i in range(int(end / dt) + 1)]
    zk, pk = ease.keys(tr[("Body", "z")]), ease.keys(tr[("Body", "pitch")])
    tk, bk = ease.keys(sing_tail), ease.keys(sing_bill)
    zs = [ease.sample(zk, u) for u in ts]
    ps = [ease.sample(pk, u) for u in ts]
    n = len(ts)

    def d2(vs, i):
        return (vs[min(i + 1, n - 1)] - 2 * vs[i] + vs[max(i - 1, 0)]) / (dt * dt)

    ft, zt_ = HP["tail"]
    wt = 2 * math.pi * ft
    fj, zj = HP["jaw"]
    wj = 2 * math.pi * fj
    a = va = b = vb = 0.0
    tails, bills = [], []
    for i in range(n):
        acc = d2(zs, i) + G_MM            # what the tail feels: gravity, less the body's fall
        # the tail sags under that load about where it rests under gravity, and the body's pitch
        # swings it the other way
        va += (-wt * wt * a - 2 * zt_ * wt * va - math.degrees((acc - G_MM) / 38.0) - d2(ps, i)) * dt
        a += va * dt
        a = max(-16.0, min(18.0, a))
        vb += (-wj * wj * b - 2 * zj * wj * vb + math.degrees(max(0.0, acc - G_MM) / 70.0)) * dt
        b += vb * dt
        if b < 0.0:                       # shut against its stop
            b, vb = 0.0, -vb * 0.2
        tails.append(a + ease.sample(tk, ts[i]))
        bills.append(min(28.0, b + ease.sample(bk, ts[i])))

    def keyed(vs):
        pick = {0, n - 1} | {i for i in range(1, n - 1) if (vs[i] - vs[i - 1]) * (vs[i + 1] - vs[i]) < 0}
        pick |= {i for i in range(1, n - 1) if (vs[i] == 0.0) != (vs[i - 1] == 0.0)}
        ks = [(round(ts[i], 3), round(vs[i], 3), "Sine", "InOut") for i in sorted(pick)]
        ks[0] = ks[0][:2]
        return ks

    # the hop's sums run in mm (gravity's 9,810 mm/s²); the kit's travel is in studs
    tracks = [(part, ch, [(round(kk[0], 4), round(mm(kk[1]) if ch in ("x", "y", "z") else kk[1], 4),
                           *kk[2:]) for kk in ks])
              for (part, ch), ks in tr.items()]
    tracks += [("Tail", "turn", keyed(tails)), ("Beak", "turn", keyed(bills)), ("Key", "turn", key)]
    return round(end, 2), tracks, beats


def bird_wind():
    keys, t = [(0.0, 0.0), (0.15, 0.0)], 0.15
    for i in range(HP["winds"]):
        keys += [(t + 0.26, 180.0 * (i + 1), "Sine", "InOut"), (t + 0.4, 180.0 * (i + 1))]
        t += 0.4
    return round(t + 0.2, 2), [("Key", "turn", keys)]


HOP_DUR, HOP_TRACKS, HOP_BEATS = bird_hop()
BWIND_DUR, BWIND_TRACKS = bird_wind()
GAPE = tuple(V(0.0, *BD["gape"]))

TIN_BIRD = kit.Find(
    "TinBird",
    [kit.Part("Body", bd_body),
     kit.Part("Bill", bd_bill, GAPE, "Body"),
     kit.Part("Beak", bd_beak, GAPE, "Body", (1, 0, 0)),
     kit.Part("Tail", bd_tail, tuple(V(0.0, *BD["tail"]["root"])), "Body", (1, 0, 0)),
     kit.Part("Legs", bd_legs, tuple(V(0.0, *BD["hip"])), "Body", (1, 0, 0)),
     kit.Part("Key", bd_key, tuple(V(*bd_key_at())), "Body", (1, 0, 0))],
    bird_look,
    motions={
        # the key wound in four half turns, a regrip between each
        "Wind": dict(duration=BWIND_DUR, focus="Key", distance=0.9, view=(2.0, -0.6, 0.7),
                     drop=0.0, tracks=BWIND_TRACKS),
        # set down, it hops off in little jumps, three at a time, then lifts its head, cocks its
        # tail and whistles twice (where the game plays its two notes), lower and slower as the
        # spring runs down, wandering a little to its left
        "Hop": dict(duration=HOP_DUR, focus=(0.0, mm(2.0), mm(30.0)), distance=1.5, follow="Body",
                    view=(2.0, -0.7, 0.45), drop=0.0, tracks=HOP_TRACKS),
    },
    dust=BD["dust"], seed=BD["seed"], texels=1500,
)


# --- The toy siren car (F-04e) ------------------------------------------------------------------
# A 1960s Japanese tin friction car of our own (README): a pressed, printed tin body in red with a
# cream roof and side flash, a numbered roundel on each door, tin bumpers and grille, rubber tyres
# with printed whitewalls on tin hubcaps, a friction motor on the rear axle, and a red fluted dome
# on the roof that the flywheel turns and a lamp lights. Its body is built the die-cast car's way
# (sections computed along the car, arches cut round the axles; D-200).

(SC_PAINT, SC_PAN, SC_BRIGHT, SC_TYRE, SC_WALL, SC_HUB, SC_LENS, SC_DOME, SC_STEEL) = range(54, 63)
SC = K.SIREN
SR = K.SIREN_RUN
SL = SC["length"] / 2
SYA = (-SC["wheelbase"] / 2, SC["wheelbase"] / 2)     # the front and rear axles
SAZ = SC["tyre"]["od"] / 2                            # the axles' height: tyres on the floor
SHM = SC["roof"] - SC["deck"]                         # the greenhouse's full height
SF = SC["fine"]                                       # the die-cast car's small offsets, scaled
NOSE = SL + 0.97 * SF                                 # the rounded ends reach this far out
BEA = SC["beacon"]


def sc_soft(u, r):
    """0 to 1 as u runs 0 to 1: straight in the middle, its ends rounded r either side."""
    def g(s):
        return 0.0 if s <= 0 else (s * s / 2 if s < 1 else s - 0.5)
    return (g(u + r) - g(u - r)) / (2 * r)


def sc_catmull(P, n):
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


def sc_hw(y):
    """The body's half width at y: its corners rounded in plan."""
    c = SC["corner"]
    e = min(c, max(0.0, abs(y) - (SL - c)))
    return SC["half_w"] - (c - math.sqrt(c * c - e * e))


def sc_deck(y):
    """The bonnet's, sills' and boot's height at y."""
    if y < SC["cowl"]:
        u = (y + SL) / (SC["cowl"] + SL)
        return SC["deck_nose"] + (SC["deck_cowl"] - SC["deck_nose"]) * (1 - (1 - u) ** 2)
    if y > SC["back_base"]:
        u = (y - SC["back_base"]) / (SL - SC["back_base"])
        return SC["deck"] + (SC["deck_tail"] - SC["deck"]) * u * u
    return SC["deck_cowl"] + (SC["deck"] - SC["deck_cowl"]) * sc_soft((y - SC["cowl"]) / (6.0 * SF), 0.3)


def sc_cabin(y):
    """How much of the greenhouse stands at y, 0 to 1: up the windscreen, down the back."""
    a = sc_soft((y - SC["cowl"]) / (SC["screen_top"] - SC["cowl"]), 0.12)
    b = sc_soft((SC["back_base"] - y) / (SC["back_base"] - SC["back_top"]), 0.12)
    return min(a, b)


def sc_bottom(y):
    """The body's lower edge at y: the rolled sill, or up round a wheel arch."""
    for ya in SYA:
        d = abs(y - ya)
        if d <= SC["arch"]:
            return SAZ + math.sqrt(SC["arch"] ** 2 - d * d)
    return SC["sill"]


def sc_half(y):
    """The body's half section at y, (x, z) mm, from the bottom's middle round to the roof's."""
    f = SF
    hw, zb, deck = sc_hw(y), sc_bottom(y), sc_deck(y)
    k = hw / SC["half_w"]
    gw, rw = SC["glass_half"] * k, SC["roof_half"] * k
    H = sc_cabin(y) * SHM
    q = min(1.0, H / (1.5 * f))
    belt = deck - 0.55 * f
    lo = zb + 0.45 * f
    up = max(lo + 0.3 * f, belt - 1.3 * f)
    crown = 0.35 * f + (SC["crown"] - 0.35 * f) * min(1.0, H / SHM)
    top = deck + H
    return [(0.0, zb), (hw - 1.3 * f, zb), (hw - 0.3 * f, lo), (hw - 0.04 * f, (lo + up) / 2),
            (hw, up), (hw - 0.12 * f, belt), (hw - 0.9 * f, deck - 0.08 * f), (gw, deck),
            ((gw + rw) / 2 + 0.15 * q * f, deck + H * 0.5), (rw + 0.55 * q * f, top - 0.55 * q * f),
            (rw - 0.35 * f, top + 0.12 * q * f + crown * 0.35), (rw * 0.5, top + crown * 0.8),
            (0.0, top + crown)]


def sc_ys(hi):
    """Where the body's sections stand along it: evenly, plus round the arches and the glass."""
    step = 1.5 if hi else 6.0
    ys = [-SL + i * step for i in range(int(2 * SL / step) + 1)] + [SL]
    na = 24 if hi else 6
    for ya in SYA:
        ys += [ya + SC["arch"] * math.cos(math.pi * i / na) for i in range(na + 1)]
        ys += [ya - SC["arch"] - 0.03, ya + SC["arch"] + 0.03]
    for e in (SC["cowl"], SC["screen_top"], SC["back_top"], SC["back_base"]):
        ys += [e - 2.0, e, e + 2.0]
    ys += [(SC["cowl"] + SC["screen_top"]) / 2, (SC["back_top"] + SC["back_base"]) / 2]
    out = []
    for y in sorted(y for y in ys if -SL <= y <= SL):
        if not out or y - out[-1] > 0.03:
            out.append(y)
    return out


def sc_ring(y, half):
    pts = [(-x, z) for x, z in half] + [(x, z) for x, z in reversed(half[1:-1])]
    return [(mm(x), mm(y), mm(z)) for x, z in pts]


def sc_shell(s, hi):
    secs = []
    for y in sc_ys(hi):
        h = sc_half(y)
        if hi:
            h = [(p.x, p.y) for p in sc_catmull(h, 3)]
        secs.append((y, h))
    # the nose and tail turn under in a round, each closing on a point
    r = SF
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
    rings = [[fp]] + [sc_ring(y, h) for y, h in reversed(front)]
    rings += [sc_ring(y, h) for y, h in secs] + [sc_ring(y, h) for y, h in back] + [[bp]]
    s.loft(rings, SC_PAINT, split=2)


def sc_roof_z(y):
    return sc_half(y)[-1][1]


def sweep(s, path, sec, kind):
    """A section [(out, up)] (mm) swept along a plan path [(x, y, z)] (mm), square to it, its
    `out` to the right of the way the path runs; capped at both ends."""
    bm = bmesh.new()
    n = len(path)
    rings = []
    for i, p in enumerate(path):
        a, b = Vector(path[max(i - 1, 0)]), Vector(path[min(i + 1, n - 1)])
        t = b - a
        t.z = 0.0
        t.normalize()
        out = Vector((t.y, -t.x, 0.0))
        rings.append([bm.verts.new(V(*p) + out * mm(u) + Vector((0.0, 0.0, mm(v)))) for u, v in sec])
    m = len(sec)
    for A, B in zip(rings, rings[1:]):
        for j in range(m):
            j1 = (j + 1) % m
            bm.faces.new((A[j], A[j1], B[j1], B[j]))
    bm.faces.new(rings[0][::-1])
    bm.faces.new(rings[-1])
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    s.merge(bm, kind)
    bm.free()


def bumper_path(sg, hi):
    """The bumper's line in plan round the nose (sg -1) or the tail (+1), just off the body, from
    a little way down one side round to the other, running so its outside is on its right."""
    c, hw = SC["corner"], SC["half_w"]
    g = 0.5
    rx, ry = c + g, c + (NOSE - SL) + g
    yc = sg * (SL - c)
    wrap = 5.0
    na = 10 if hi else 4
    pts = [(-(hw + g), yc - sg * wrap)]
    for i in range(na + 1):
        a = math.pi / 2 * i / na
        pts.append((-(hw - c) - rx * math.cos(a), yc + sg * ry * math.sin(a)))
    for i in range(na + 1):
        a = math.pi / 2 * i / na
        pts.append(((hw - c) + rx * math.sin(a), yc + sg * ry * math.cos(a)))
    pts.append((hw + g, yc - sg * wrap))
    if sg > 0:
        pts.reverse()
    return [(x, y, 0.0) for x, y in pts]


def sc_body(hi):
    s = Shape()
    sc_shell(s, hi)
    # the tin floor pan between the wheels, and out to the sills between and beyond the arches
    b = SC["base"]
    inner = SC["track"] / 2 - SC["tyre"]["w"] / 2 - 1.2
    s.box(V(-inner, -SL + 5.0, b["z0"]), V(inner, SL - 5.0, b["z1"]), SC_PAN, mm(0.4), 1)
    ar = SC["arch"] + 0.4
    for y0, y1 in ((-SL + 5.0, SYA[0] - ar), (SYA[0] + ar, SYA[1] - ar), (SYA[1] + ar, SL - 5.0)):
        for sd in (-1, 1):
            x0, x1 = sorted((sd * inner, sd * b["half"]))
            s.box(V(x0, y0, b["z0"] + 0.1), V(x1, y1, b["z1"]), SC_PAN, mm(0.4), 1)
    # the friction motor's steel case on the rear axle, hanging under the pan
    mo = SC["motor"]
    s.box(V(-mo["x"], mo["y"][0], mo["z"][0]), V(mo["x"], mo["y"][1], mo["z"][1]), SC_STEEL,
          mm(1.2), 2 if hi else 1)
    # the tin bumpers wrapped round the nose and tail, with a pair of over-riders on each
    bu = SC["bumper"]
    z0, z1, d = bu["z"][0], bu["z"][1], bu["d"]
    zm = (z0 + z1) / 2
    sec = [(-1.2, z0 + 0.6), (0.4, z0), (d * 0.7, z0 + 0.3), (d * 0.95, z0 + 1.3), (d, zm),
           (d * 0.95, z1 - 1.1), (d * 0.7, z1 - 0.2), (0.4, z1), (-1.2, z1 - 0.6)]
    if not hi:
        sec = [sec[0], sec[1], sec[3], sec[5], sec[7], sec[8]]
    for sg in (-1, 1):
        sweep(s, bumper_path(sg, hi), sec, SC_BRIGHT)
        yo = sg * (NOSE + 0.5)
        for sd in (-1, 1):
            y0, y1 = sorted((yo, yo + sg * (d + 1.3)))
            s.box(V(sd * 12.0 - 1.7, y0, z0 - 0.8), V(sd * 12.0 + 1.7, y1, z1 + 1.6), SC_BRIGHT,
                  mm(0.9), 2 if hi else 1)
    # the grille across the nose, its headlamps standing proud in each end
    gr = SC["grille"]
    s.box(V(-gr["half"], -NOSE - 0.9, gr["z"][0]), V(gr["half"], -NOSE + 3.0, gr["z"][1]),
          SC_BRIGHT, mm(0.7), 2 if hi else 1)
    la = SC["lamp"]
    R = la["r"]
    prof = [(R + 0.6, -0.4), (R + 0.6, 0.9), (R + 0.3, 1.35), (R - 0.3, 1.35), (R - 0.5, 1.0),
            (R * 0.62, 1.6), (R * 0.32, 1.95), (0.0, 2.05)]
    kinds = [SC_BRIGHT] * 4 + [SC_LENS] * 3
    for sd in (-1, 1):
        M = T(V(sd * la["x"], -NOSE - 0.9, la["z"])) @ Matrix.Rotation(math.radians(90), 4, "X")
        s.lathe([(mm(r), mm(z)) for r, z in prof], SC_BRIGHT, segs(hi, 16), M, kinds=kinds)
    # the roof light's pressed tin base
    zr = sc_roof_z(BEA["y"])
    bR, bH = BEA["base"]
    prof = [(0.0, -1.5), (bR, -1.5), (bR + 0.15, 0.3), (bR - 0.2, 0.9), (bR - 1.0, 1.4),
            (bR - 1.5, 2.2), (bR - 1.5, bH - 0.4), (bR - 1.9, bH), (0.0, bH)]
    s.lathe([(mm(r), mm(z)) for r, z in prof], SC_BRIGHT, segs(hi, 20), T(V(0.0, BEA["y"], zr)))
    return s


def flute(a, n, depth):
    """The dome's moulded flutes: 1 on each ridge, 1 - depth in each groove."""
    return 1.0 - depth * (0.5 - 0.5 * math.cos(n * a))


def sc_beacon(hi):
    """The red dome on its turntable: a flange, a fluted wall, a fluted cap and its sprue nub,
    drawn about its pivot on the base's top."""
    s = Shape()
    R, H, n = BEA["r"], BEA["h"], BEA["flutes"]
    m = n * (8 if hi else 4)
    c = Vector((0.0, BEA["y"], 0.0))
    z0 = sc_roof_z(BEA["y"]) + BEA["base"][1] - 0.2

    def ring(r, z, depth):
        return [(mm(c.x + r * flute(2 * math.pi * j / m, n, depth) * math.cos(2 * math.pi * j / m)),
                 mm(c.y + r * flute(2 * math.pi * j / m, n, depth) * math.sin(2 * math.pi * j / m)),
                 mm(z0 + z)) for j in range(m)]
    wall = H - 6.0
    rings = [[(mm(c.x), mm(c.y), mm(z0))], ring(R + 0.6, 0.0, 0.0), ring(R + 0.6, 1.0, 0.0),
             ring(R + 0.05, 1.15, 0.04), ring(R, 1.5, 0.05)]
    for z in ((2.5, 4.0, 5.5) if hi else (4.0,)):
        rings.append(ring(R, z, 0.05))
    na = 8 if hi else 4
    for i in range(na + 1):
        a = math.pi / 2 * 0.86 * i / na
        rings.append(ring(R * math.cos(a), wall + 5.4 * math.sin(a), 0.05 * math.cos(a) ** 2))
    rings += [ring(1.3, H - 0.25, 0.0), ring(1.0, H, 0.0), [(mm(c.x), mm(c.y), mm(z0 + H + 0.1))]]
    s.loft(rings, SC_DOME, split=2)
    return s


def sc_wheels(front):
    """A pair of rubber tyres on tin hubcaps, fixed to one steel axle."""
    def build(hi):
        s = Shape()
        ya = SYA[0] if front else SYA[1]
        t = SC["tyre"]
        R, w, hb = t["od"] / 2, t["w"], t["hub"] / 2
        w0, w1 = t["wall"]
        f = 3 if hi else 1
        p = [(0.0, -w / 2 + 0.8), (hb - 1.0, -w / 2 + 0.8), (R - 3.0, -w / 2)]
        p += fillet(R - 1.6, -w / 2 + 1.6, 1.6, (-90, 0), f + 1)[1:]
        if hi:
            # the moulded tread: three grooves round
            for zc in (-2.2, 0.0, 2.2):
                p += [(R, zc - 0.5), (R - 0.55, zc - 0.32), (R - 0.55, zc + 0.32), (R, zc + 0.5)]
        p += fillet(R - 1.6, w / 2 - 1.6, 1.6, (0, 90), f + 1)
        e = len(p) - 1
        # the outer sidewall, the whitewall printed on it, the bead round the hubcap
        p += [(w1, w / 2 + 0.1), (w0, w / 2 + 0.12), (hb + 0.5, w / 2 - 0.1)]
        # the tin hubcap pressed into it: a rim, a dished ring, a domed middle and its boss
        p += [(hb, w / 2 - 0.2), (hb - 0.3, w / 2 + 0.5), (hb - 1.2, w / 2 + 0.75),
              (hb * 0.55, w / 2 + 0.55), (2.2, w / 2 + 1.4), (1.0, w / 2 + 1.8), (0.0, w / 2 + 1.85)]
        kinds = [SC_TYRE] * (e + 1) + [SC_WALL] + [SC_TYRE] * 2 + [SC_HUB] * (len(p) - e - 5)
        prof = [(mm(r), mm(z)) for r, z in p]
        for side in (-1, 1):
            M = T(V(side * SC["track"] / 2, ya, SAZ)) @ Matrix.Rotation(math.radians(90 * side), 4, "Y")
            s.lathe(prof, SC_TYRE, segs(hi, 22), M, kinds=kinds)
        xe = SC["track"] / 2 - w / 2 + 0.6
        s.cylinder(V(-xe, ya, SAZ), V(xe, ya, SAZ), mm(1.1), SC_STEEL, segs(hi, 8))
        return s
    return build


def sc_look(L, f):
    nb = L.nb
    x, y, z = L.x, L.y, L.z
    ax = nb.absf(x)

    def inb(v, lo, hi, soft=0.12):
        return nb.mul(nb.ss(v, mm(lo - soft), mm(lo + soft)), nb.ss(nb.sub(0.0, v), mm(-hi - soft), mm(-hi + soft)))

    def line(v, c, w=0.18):
        return nb.ss(nb.sub(0.0, nb.absf(nb.sub(v, mm(c)))), -mm(2 * w), -mm(w))

    RED, CREAM = hexc("#B8231B"), hexc("#EDE2C4")
    INK, SILVER = hexc("#1E1A19"), hexc("#C9CBC8")
    C_ = Coat(L, RED, 0.3, 0.0)
    paint = L.k(SC_PAINT)
    side = nb.ss(nb.absf(L.nx), 0.5, 0.7)
    top = nb.ss(L.nz, 0.45, 0.65)
    rear = nb.ss(L.ny, 0.6, 0.8)
    front = nb.ss(nb.sub(0.0, L.ny), 0.6, 0.8)
    # litho red under its lacquer, the print a little uneven, the lacquer a little orange-peeled
    # (a fine roughness noise broke the top light's sheen into a pale speckled film on the
    # bonnet and boot; the lacquer is smooth, so only a broad, gentle wander)
    C_.paint(paint, nb.tint(RED, nb.mr(L.noise(45.0, 1, detail=2), 0.3, 0.7, 0.955, 1.03)),
             nb.mr(L.noise(25.0, 2, detail=1), 0.3, 0.7, 0.19, 0.24), 0.0)
    # the cream roof and pillars, and the cream flash down each side with a silver line either edge
    cabin = nb.ss(z, mm(SC["deck"] + 0.5), mm(SC["deck"] + 1.1))
    C_.paint(nb.mul(paint, cabin), CREAM, 0.32)
    flash = nb.mul(nb.mul(side, inb(z, 21.4, 25.4, 0.1)),
                   nb.mul(nb.ss(y, mm(-60.0), mm(-58.5)), nb.ss(nb.sub(0.0, y), mm(-66.5), mm(-65.0))))
    C_.paint(nb.mul(paint, flash), CREAM, 0.32)
    trims = nb.mul(nb.mul(side, nb.add(line(z, 21.1, 0.22), line(z, 25.7, 0.22), clamp=True)),
                   nb.mul(nb.ss(y, mm(-61.0), mm(-60.0)), nb.ss(nb.sub(0.0, y), mm(-67.0), mm(-66.0))))
    C_.paint(nb.mul(paint, trims), SILVER, 0.22, 0.8)
    # the shut lines printed dark over the pressing: doors, bonnet and boot lid
    doors = nb.mul(nb.mul(side, nb.add(line(y, SC["door"][0]), line(y, SC["door"][1]), clamp=True)),
                   inb(z, 9.6, SC["deck"] - 0.6))
    lid_x = nb.ss(nb.sub(0.0, ax), -mm(25.4), -mm(25.0))
    bon = nb.add(nb.mul(line(y, SC["cowl"] - 2.0), lid_x),
                 nb.mul(line(ax, 25.2), nb.ss(nb.sub(0.0, y), mm(-SC["cowl"] + 1.6), mm(-SC["cowl"] + 2.0))),
                 clamp=True)
    boot = nb.add(nb.mul(line(y, SC["back_base"] + 2.0), lid_x),
                  nb.mul(line(ax, 25.2), nb.ss(y, mm(SC["back_base"] + 1.6), mm(SC["back_base"] + 2.0))),
                  clamp=True)
    lids = nb.mul(nb.mul(top, nb.ss(z, mm(24.0), mm(24.6))), nb.add(bon, boot, clamp=True))
    C_.paint(nb.mul(paint, nb.add(doors, lids, clamp=True)), INK, 0.4)
    # the door roundel: a gold ring, a white disc and our number, on both sides read the right way
    yc, zc = (SC["door"][0] + SC["door"][1]) / 2, 23.4
    dy, dz = nb.sub(y, mm(yc)), nb.sub(z, mm(zc))
    d = nb.math("SQRT", nb.add(nb.mul(dy, dy), nb.mul(dz, dz)))
    disc = nb.mul(nb.mul(side, paint), nb.ss(nb.sub(0.0, d), -mm(7.0), -mm(6.8)))
    C_.paint(disc, hexc("#D3A43C"), 0.3, 0.6)
    C_.paint(nb.mul(disc, nb.ss(nb.sub(0.0, d), -mm(5.9), -mm(5.7))), hexc("#F3EFE4"), 0.3, 0.0)
    sg = nb.sub(nb.mul(nb.ss(x, -mm(0.1), mm(0.1)), 2.0), 1.0)
    u = nb.mul(nb.sub(y, mm(yc)), sg)
    v = dz
    bar = nb.mul(inb(u, -2.7, 2.7, 0.08), inb(v, 2.4, 3.7, 0.08))
    dist = nb.absf(nb.add(nb.mul(nb.sub(u, mm(2.5)), 0.8998), nb.mul(nb.sub(v, mm(2.6)), -0.4363)))
    stem = nb.mul(nb.ss(nb.sub(0.0, dist), -mm(0.72), -mm(0.6)), inb(v, -3.9, 2.9, 0.08))
    C_.paint(nb.mul(disc, nb.add(bar, stem, clamp=True)), hexc("#A81E18"), 0.3, 0.0)
    # door handles and the printed chrome round the windows
    C_.paint(nb.mul(nb.mul(paint, side), nb.mul(inb(y, 8.8, 12.6, 0.1), inb(z, 29.2, 30.2, 0.1))),
             SILVER, 0.2, 0.9, 0.4)
    a = (SC["screen_top"] - SC["cowl"]) / SHM
    yA = nb.add(mm(SC["cowl"] - a * SC["deck"]), nb.mul(z, a))
    c = (SC["back_base"] - SC["back_top"]) / SHM
    yC = nb.sub(mm(SC["back_base"] + c * SC["deck"]), nb.mul(z, c))

    def side_glass(m):
        g = nb.mul(nb.mul(side, inb(z, SC["deck"] + 2.2 - m, SC["roof"] - 2.0 + m)),
                   nb.mul(nb.ss(nb.sub(y, yA), mm(2.8 - m), mm(3.1 - m)), nb.ss(nb.sub(yC, y), mm(4.4 - m), mm(4.7 - m))))
        return nb.mul(g, nb.ss(nb.absf(nb.sub(y, mm(SC["b_pillar"]))), mm(1.5 - m), mm(1.8 - m)))
    kx = (SC["glass_half"] - SC["roof_half"]) / SHM

    def screens(m):
        xm = nb.sub(mm(SC["glass_half"] - 3.0 + m + kx * SC["deck"]), nb.mul(z, kx))
        span = nb.mul(nb.ss(nb.sub(xm, ax), 0.0, mm(0.3)), inb(z, SC["deck"] + 2.0 - m, SC["roof"] - 1.8 + m))
        return nb.mul(span, nb.add(nb.ss(nb.sub(0.0, L.ny), 0.3, 0.45), nb.ss(L.ny, 0.3, 0.45), clamp=True))
    frame = nb.mul(paint, nb.add(side_glass(0.9), screens(0.9), clamp=True))
    C_.paint(frame, SILVER, 0.22, 0.85)
    glass = nb.mul(paint, nb.add(side_glass(0.0), screens(0.0), clamp=True))
    # printed glass: deep blue-grey, paler low down, two white glints slanting across each pane
    C_.paint(glass, nb.mixc(nb.mr(z, mm(36.0), mm(48.0)), hexc("#7896AA"), hexc("#2E4252")), 0.12, 0.2)
    q = nb.fract(nb.mul(nb.add(nb.add(y, nb.mul(x, 0.9)), nb.mul(z, 0.8)), 1.0 / mm(34.0)))
    # a broad soft sheen and a fainter narrow one (thin hard lines read as cracks)
    glint = nb.add(nb.mul(nb.mul(nb.ss(q, 0.26, 0.31), nb.ss(nb.sub(0.0, q), -0.40, -0.35)), 0.42),
                   nb.mul(nb.mul(nb.ss(q, 0.44, 0.455), nb.ss(nb.sub(0.0, q), -0.485, -0.47)), 0.25),
                   clamp=True)
    C_.paint(nb.mul(glass, glint), hexc("#D5E1E6"), 0.12)
    # the crew printed on the side glass, as every tin car of the kind has them: a driver in a
    # peaked cap in the front window and a passenger behind, in profile looking ahead, a navy
    # tunic, a pink face with one dark eye, the hair at the back, a gold badge on the cap
    pane = nb.mul(paint, side_glass(0.0))

    def ell(yc_, zc_, ry, rz, soft=0.1):
        a = nb.mul(nb.sub(y, mm(yc_)), 1.0 / mm(ry))
        b = nb.mul(nb.sub(z, mm(zc_)), 1.0 / mm(rz))
        return nb.ss(nb.sub(0.0, nb.add(nb.mul(a, a), nb.mul(b, b))), -1.0 - soft, -1.0 + soft)
    NAVY = hexc("#1C2740")
    for yh, cap in ((-3.0, True), (16.6, False)):
        zh = 43.2
        torso = nb.add(ell(yh + 1.0, zh - 7.6, 4.4, 5.2),
                       nb.mul(inb(y, yh - 3.0, yh + 4.8, 0.1), inb(z, SC["deck"], zh - 7.0, 0.1)), clamp=True)
        C_.paint(nb.mul(pane, torso), NAVY, 0.15)
        head = ell(yh, zh, 2.5, 2.9)
        C_.paint(nb.mul(pane, head), hexc("#E3A47F"), 0.15)
        hair = nb.mul(head, nb.add(nb.ss(y, mm(yh + 0.6), mm(yh + 0.9)),
                                   nb.ss(z, mm(zh + 1.3), mm(zh + 1.6)), clamp=True))
        C_.paint(nb.mul(pane, hair), hexc("#3A2418"), 0.15)
        if cap:
            crown = nb.add(nb.mul(inb(y, yh - 2.6, yh + 2.7, 0.08), inb(z, zh + 1.2, zh + 3.2, 0.08)),
                           ell(yh + 0.3, zh + 3.1, 2.9, 0.9), clamp=True)
            peak = nb.mul(inb(y, yh - 4.3, yh - 1.8, 0.08), inb(z, zh + 0.9, zh + 1.6, 0.08))
            C_.paint(nb.mul(pane, nb.add(crown, peak, clamp=True)), NAVY, 0.15)
            C_.paint(nb.mul(pane, ell(yh - 1.9, zh + 2.4, 0.6, 0.6)), hexc("#D9AE45"), 0.2, 0.6)
        C_.paint(nb.mul(pane, ell(yh - 1.5, zh + 0.4, 0.45, 0.5)), INK, 0.2)
    # the tail: lamps either side and a number plate between, printed; the base under it bare
    lamps = nb.mul(nb.mul(paint, rear), nb.mul(inb(ax, 17.0, 26.0), inb(z, 19.0, 25.0)))
    C_.paint(lamps, SILVER, 0.2, 0.9)
    lens = nb.mul(nb.mul(paint, rear), nb.mul(inb(ax, 18.0, 25.0), inb(z, 20.0, 24.0)))
    C_.paint(lens, nb.mixc(nb.mr(z, mm(20.5), mm(23.5)), hexc("#E0381F"), hexc("#FF8A4A")), 0.08, 0.0)
    C_.paint(nb.mul(lens, inb(ax, 18.0, 20.6)), hexc("#F2A23A"), 0.1, 0.0)
    plate = nb.mul(nb.mul(paint, rear), nb.mul(inb(ax, 0.0, 9.0), inb(z, 18.0, 24.6)))
    C_.paint(plate, hexc("#E9DFC0"), 0.35)
    cx = nb.absf(nb.sub(nb.fract(nb.mul(nb.add(x, mm(1.25)), 1.0 / mm(2.5))), 0.5))
    cz = nb.absf(nb.sub(z, mm(21.3)))
    cell = nb.mul(nb.ss(nb.sub(0.0, cx), -0.36, -0.33), nb.ss(nb.sub(0.0, cz), -mm(1.75), -mm(1.6)))
    hole = nb.mul(nb.ss(nb.sub(0.0, cx), -0.14, -0.11), nb.ss(nb.sub(0.0, cz), -mm(1.05), -mm(0.9)))
    bar = nb.mul(nb.ss(nb.sub(0.0, cz), -mm(0.3), -mm(0.18)), nb.ss(nb.sin(nb.mul(x, 1.0 / mm(1.6))), -0.2, 0.2))
    marks = nb.mul(nb.mul(inb(ax, 0.0, 6.4), cell), nb.add(nb.inv(hole), bar, clamp=True))
    C_.paint(nb.mul(plate, marks), INK, 0.4)
    C_.paint(nb.mul(paint, nb.ss(nb.sub(0.0, L.nz), 0.5, 0.7)), hexc("#4A4C4E"), 0.6)
    # tinplate: the bright bumpers, grille and base, the bare floor pan, the steel motor case
    tin = nb.tint(hexc("#D5D7D3"), nb.mr(L.noise(260.0, 3, detail=3), 0.3, 0.7, 0.88, 1.06))
    C_.paint(L.k(SC_BRIGHT), tin, nb.mr(L.noise(420.0, 4, detail=2), 0.3, 0.7, 0.24, 0.34), 1.0)
    slots = nb.ss(nb.sub(0.0, nb.absf(nb.sub(nb.fract(nb.mul(z, 1.0 / mm(1.3))), 0.5))), -0.24, -0.16)
    grille = nb.mul(nb.mul(L.k(SC_BRIGHT), front),
                    nb.mul(inb(ax, 0.0, 11.8), inb(z, SC["grille"]["z"][0] + 1.2, SC["grille"]["z"][1] - 1.2)))
    C_.paint(nb.mul(grille, slots), hexc("#2A2C2E"), 0.5, 0.5)
    C_.paint(L.k(SC_PAN), nb.tint(hexc("#B9BCB8"), nb.mr(L.noise(300.0, 5, detail=3), 0.3, 0.7, 0.85, 1.05)),
             0.42, 1.0)
    C_.paint(L.k(SC_STEEL), hexc("#55595C"), 0.45, 0.9)
    C_.paint(L.k(SC_LENS), hexc("#EDEEE6"), 0.06, 0.3)
    # rubber tyres, a printed whitewall, pressed tin hubcaps
    C_.paint(L.k(SC_TYRE), nb.tint(hexc("#1A1A1A"), nb.mr(L.noise(400.0, 6, detail=3), 0.3, 0.7, 0.85, 1.25)),
             nb.mr(L.noise(300.0, 7, detail=2), 0.3, 0.7, 0.62, 0.78), 0.0)
    C_.paint(L.k(SC_WALL), nb.tint(hexc("#E6E1D3"), nb.mr(L.noise(200.0, 8, detail=3), 0.3, 0.7, 0.82, 1.0)), 0.6, 0.0)
    # (fully metal and glossy they mirrored the dark room and read black from the front)
    C_.paint(L.k(SC_HUB), hexc("#E6E8E3"), 0.38, 0.75)
    # the dome: red moulded plastic, deeper at its foot where it's thick, a pale lamp-glow core
    dome = L.k(SC_DOME)
    C_.paint(dome, nb.mixc(nb.mr(z, mm(56.0), mm(66.0)), hexc("#8E0E0B"), hexc("#D0261B")), 0.12, 0.0)
    # played with: the print chipped to the tin on the edges and a few knocks on the faces, fine
    # scuffs along the sides, a little rust in the deepest chips
    edge = L.edge(mm(1.4), k=4.0)
    bites = nb.mul(edge, nb.ss(L.noise(300.0, 9, detail=4), 0.5, 0.56))
    chips = nb.mx(nb.ss(bites, 0.35, 0.45), nb.ss(L.noise(180.0, 10, detail=4, rough=0.65), 0.84, 0.87))
    chips = nb.mul(nb.mul(paint, nb.inv(glass)), chips)
    C_.paint(chips, hexc("#BDBFBA"), 0.4, 0.9, -0.4)
    rust = nb.mul(chips, nb.ss(L.noise(90.0, 11, detail=3), 0.62, 0.7))
    C_.paint(rust, hexc("#6E4228"), 0.8, 0.1)
    scuff = nb.mul(nb.mul(paint, side), nb.ss(L.noise(260.0, 12, stretch=(1.0, 0.06, 1.0), detail=2), 0.71, 0.73))
    C_.paint(nb.mul(scuff, 0.6), hexc("#D9B9A8"), 0.5)
    # lit, the side the lamp's reflector faces burns, the rest of the dome a dim red round it
    C_.lights(nb.mul(dome, nb.add(0.16, nb.mul(nb.pw(nb.ss(nb.sub(0.0, L.ny), -0.1, 0.95), 2.0), 0.84))))
    C_.finish(f.dust, grime=0.35)
    return C_.surface(bump_dist=0.0008, bump=0.6)


# --- pushing it: two pushes rev the flywheel, then it goes -----------------------------------------

def sc_spring(n, target, w, zeta):
    x, v, out = 0.0, 0.0, []
    dt = 1.0 / FPS
    for i in range(n):
        v += (w * w * (target(i) - x) - 2 * zeta * w * v) * dt
        x += v * dt
        out.append(x)
    return out


def sc_push():
    dt = 1.0 / FPS
    d0, t0 = SR["stroke"]
    segs_ = []
    t = 0.12
    for k in range(SR["strokes"]):
        segs_.append((t, t + t0, d0))
        segs_.append((t + t0 + 0.03, t + 1.6 * t0 + 0.03, -0.75 * d0))
        t += 1.6 * t0 + 0.08
    t_rel, shove = t, 0.16
    a_, b_ = SR["drag"]
    ts, ss_, vs = [], [], []
    s_, v, tt, t_stop = 0.0, 0.0, 0.0, None
    while True:
        if tt < t_rel:
            s_ = 0.0
            for ta, tb, dd in segs_:
                if tt >= tb:
                    s_ += dd
                elif tt > ta:
                    s_ += dd * smooth(0.0, 1.0, (tt - ta) / (tb - ta))
            v = (s_ - ss_[-1]) / dt if ss_ else 0.0
        else:
            u = tt - t_rel
            if u < shove:
                v = SR["v0"] * smooth(0.0, 1.0, u / shove)
            else:
                v = max(0.0, v - (a_ + b_ * v) * dt)
            s_ += v * dt
            if t_stop is None and u > shove and v <= 0.0:
                t_stop = tt
        ts.append(tt)
        ss_.append(s_)
        vs.append(v)
        if t_stop is not None and tt > t_stop + 0.3 + SR["glow"][1] + 0.25:
            break
        tt += dt
    n = len(ts)
    x = yy = yaw = 0.0
    tr = {k: [] for k in (("Body", "x"), ("Body", "y"), ("Body", "yaw"), ("FrontWheels", "turn"),
                          ("RearWheels", "turn"), ("Beacon", "turn"))}
    fly, ang = 0.0, 0.0
    for i in range(n):
        tr[("Body", "x")].append(x)
        tr[("Body", "y")].append(yy)
        tr[("Body", "yaw")].append(math.degrees(yaw))
        turn = math.degrees(ss_[i] / mm(SAZ))
        tr[("FrontWheels", "turn")].append(turn)
        tr[("RearWheels", "turn")].append(turn)
        # the flywheel: wound up by each push forward (its clutch slips going back), then it
        # drives the car; the roof light turns geared to it
        if ts[i] < t_rel:
            wound = sum(min(1.0, max(0.0, (ts[i] - ta) / (tb - ta))) for ta, tb, dd in segs_ if dd > 0)
            fly = max(fly - 0.3 * dt, 0.35 * wound)
        else:
            fly = max(fly - 0.3 * dt, vs[i] / SR["v0"])
        ang += 360.0 * SR["spin"] * min(fly, 1.0) * dt
        tr[("Beacon", "turn")].append(ang)
        ds = (ss_[i] - ss_[i - 1]) if i else 0.0
        yaw += math.radians(SR["drift"] * math.sin(2 * math.pi * 0.27 * ts[i] + 0.4) * vs[i] / SR["v0"]) * dt
        x += math.sin(yaw) * ds
        yy -= math.cos(yaw) * ds
    af = [(vs[min(i + 1, n - 1)] - vs[max(i - 1, 0)]) / (2 * dt) for i in range(n)]
    kq = SR["squat"] / (SR["v0"] / shove)
    pitch = sc_spring(n, lambda i: -kq * max(-12.0, min(af[i], SR["v0"] / shove)), 2 * math.pi * 6.0, 0.3)
    tr[("Body", "pitch")] = pitch
    tr[("Body", "roll")] = [SR["rattle"] * min(1.0, abs(vs[i]) / SR["v0"]) ** 0.7
                            * (0.65 * math.sin(2 * math.pi * 5.3 * t) + 0.35 * math.sin(2 * math.pi * 8.1 * t + 1.3))
                            for i, t in enumerate(ts)]
    eps = {"x": 0.0015, "y": 0.0015, "yaw": 0.1, "turn": 2.5, "pitch": 0.04, "roll": 0.06}
    out = []
    for (part, ch), vs_ in tr.items():
        if max(vs_) - min(vs_) < 1e-4:
            continue
        out.append((part, ch, rdp(ts, vs_, eps[ch])))
    # the lamp catches with a flicker on the first push, burns the whole run and dies after it stops
    g0 = segs_[0][0]
    up, fade = SR["glow"]
    out.append(("Beacon", "glow", [(0.0, 0.0), (g0, 0.0), (g0 + 0.04, 0.75, "Quad", "Out"),
                                   (g0 + 0.09, 0.4), (g0 + up, 1.0, "Quad", "Out"),
                                   (round(t_stop + 0.3, 3), 1.0),
                                   (round(t_stop + 0.3 + fade, 3), 0.0, "Sine", "InOut")]))
    return round(ts[-1], 2), out, t_rel, t_stop, ss_[-1]


SC_DUR, SC_TRACKS, SC_REL, SC_STOP, SC_RUN = sc_push()
SC_TOP = sc_roof_z(BEA["y"])
BEACON_AT = V(0.0, BEA["y"], SC_TOP + BEA["base"][1] - 0.2)
BEAM_AT = V(0.0, BEA["y"] - BEA["r"] - 0.9, SC_TOP + BEA["base"][1] + 5.0)
SC_RED = (255, 48, 36)

SIREN_CAR = kit.Find(
    "SirenCar",
    [kit.Part("Body", sc_body),
     kit.Part("FrontWheels", sc_wheels(True), tuple(V(0.0, SYA[0], SAZ)), "Body", (1, 0, 0)),
     kit.Part("RearWheels", sc_wheels(False), tuple(V(0.0, SYA[1], SAZ)), "Body", (1, 0, 0)),
     kit.Part("Beacon", sc_beacon, tuple(BEACON_AT), "Body", (0, 0, 1))],
    sc_look,
    lights=[
        # the beam: a red cone out of the dome's lit side, turning with it, sweeping the walls
        dict(kind="Spot", part="Beacon", at=tuple(BEAM_AT), face=(0.0, -0.99, -0.14), rgb=SC_RED,
             brightness=1.4, range=14, angle=50, shadows=True, preview_watts=70.0,
             preview_blend=0.35),
        # the dome's own glow on the roof and the floor round it, which also lights at low
        # graphics, where a close spotlight lights nothing (docs/STUDIO.md)
        dict(kind="Point", part="Beacon", at=tuple(BEACON_AT + V(0.0, 0.0, 6.0)), rgb=SC_RED,
             brightness=0.4, range=5, shadows=False, preview_kind="POINT", preview_watts=0.5,
             preview_size=0.02),
    ],
    glow=dict(part="Beacon", strength=2.5, tint=SC_RED, preview=4.0),
    motions={
        # two pushes along the floor rev the flywheel (the lamp catches with a flicker, the roof
        # light starts to turn); let go, it shoots off down the hall, its beam sweeping round,
        # wandering a little and rattling on its axles, slows as the flywheel runs down and stops;
        # the light turns slower and slower, then the lamp dies (the game wails the siren)
        "Push": dict(duration=SC_DUR, focus=(0.0, 0.0, mm(26.0)), distance=1.0, follow="Body",
                     view=(-1.1, -2.0, 1.0), drop=0.0, tracks=SC_TRACKS),
    },
    dust=SC["dust"], seed=SC["seed"], texels=1400,
)


# --- The squeaky rubber duck (F-04e2) -------------------------------------------------------------
# A classic yellow vinyl bath duck of our own (README): one soft hollow moulding, a big round head
# sat forward on a broad body, an upturned tail, a moulded wing on each side and a little crest
# along the seam on its crown, an orange bill with a smile, printed eyes, a squeak hole
# underneath. Squeezed, the whole of it squashes, squeaks and springs back.

import numpy as np  # noqa: E402

DK = K.DUCK
SQ = K.SQUEEZE
(DK_VINYL, DK_BILL, DK_MOUTH) = range(63, 66)


def _rot(rise, toe=0.0):
    """An ellipsoid's own X, Y, Z (columns) in the duck's frame: its Y tipped up `rise` degrees
    about X, then turned `toe` degrees about Z."""
    a, b = math.radians(rise), math.radians(toe)
    Rx = np.array([[1.0, 0.0, 0.0], [0.0, math.cos(a), -math.sin(a)], [0.0, math.sin(a), math.cos(a)]])
    Rz = np.array([[math.cos(b), -math.sin(b), 0.0], [math.sin(b), math.cos(b), 0.0], [0.0, 0.0, 1.0]])
    return Rz @ Rx


def _ell(P, c, r, R=None):
    q = P - np.array(c)
    if R is not None:
        q = q @ R
    r = np.array(r)
    return (np.linalg.norm(q / r, axis=-1) - 1.0) * r.min()


def _smin(a, b, k):
    """The two volumes melted together, over about k (mm)."""
    h = np.clip(0.5 + 0.5 * (b - a) / k, 0.0, 1.0)
    return b * (1 - h) + a * h - k * h * (1 - h)


TAIL_R = _rot(DK["tail"]["rise"])
WING_R = _rot(DK["wing"]["rise"], -DK["wing"]["toe"])
CREST_R = _rot(DK["crest"]["tip"])


def _wing(P):
    """The left wing (P mirrored onto the left): an oval narrowing toward its tip, a teardrop."""
    w = DK["wing"]
    q = (P - np.array(w["at"])) @ WING_R
    r = np.array(w["r"])
    t = np.clip((q[..., 1] / r[1] + 0.5) / 1.5, 0.0, 1.0)    # eases in from behind its middle,
    q[..., 2] /= 1.0 - w["taper"] * t * t * (3.0 - 2.0 * t)   # so its outline has no corner
    return (np.linalg.norm(q / r, axis=-1) - 1.0) * r.min()


def dk_sdf(P):
    """How far outside the duck each point of P (..., 3; mm) is, about: negative inside."""
    bl = DK["blend"]
    d = _smin(_ell(P, *DK["body"]), _ell(P, *DK["chest"]), bl["chest"])
    t = DK["tail"]
    d = _smin(d, _ell(P, t["at"], t["r"], TAIL_R), bl["tail"])
    d = _smin(d, _ell(P, *DK["head"]), bl["head"])
    Pm = P.copy()
    Pm[..., 0] = np.abs(Pm[..., 0])
    d = _smin(d, _wing(Pm), bl["wing"])
    c = DK["crest"]
    d = _smin(d, _ell(P, c["at"], c["r"], CREST_R), bl["crest"])
    return -_smin(-d, P[..., 2], bl["base"])      # flat underneath, so it stands (and floats)


def dk_march(D, origin, reach=90.0, step=0.4):
    """Where each ray D (n, 3) from `origin` first leaves the duck (mm), and how many rays go
    back in further out (0 when every bit of the duck is seen from `origin`)."""
    C = np.array(origin)
    ts = np.arange(0.0, reach, step)
    out = dk_sdf(C + D[:, None, :] * ts[:, None]) > 0
    first = np.argmax(out, axis=-1)
    lo, hi = ts[np.maximum(first - 1, 0)], ts[first]
    for _ in range(18):
        mid = (lo + hi) / 2
        o = dk_sdf(C + D * mid[:, None]) > 0
        hi, lo = np.where(o, mid, hi), np.where(o, lo, mid)
    again = (~out) & (np.arange(len(ts)) > first[:, None])
    return C + D * hi[:, None], int(again.any(axis=-1).sum())


def dk_grad(P, h=0.03):
    return np.stack([dk_sdf(P + e) - dk_sdf(P - e) for e in np.eye(3) * h], axis=-1) / (2 * h)


def dk_normal(p):
    g = dk_grad(np.array([p]))[0]
    return g / np.linalg.norm(g)


def dk_settle(R, poles, iters, pull=6.0):
    """Even the sampled grid (rings, columns, 3) out over the surface: rays from one point
    graze the wing's top, the tail and the chin and leave long faces there, so each point slides
    along the surface toward its neighbours' middle, then is put back on it. It is pulled harder
    (`pull` more for each mm) toward a neighbour whose edge's middle sinks inside the surface, so
    points gather where it bends: the game mesh's flat faces then cut the tail's tip and the
    wing's edge by under 0.7 mm, inside what the bake can reach (they cut 5 mm evened out
    plainly, and the bake left black holes there)."""
    for _ in range(iters):
        up = np.concatenate([R[1:], np.broadcast_to(poles[1], (1,) + R.shape[1:])], axis=0)
        dn = np.concatenate([np.broadcast_to(poles[0], (1,) + R.shape[1:]), R[:-1]], axis=0)
        nb = [up, dn, np.roll(R, 1, axis=1), np.roll(R, -1, axis=1)]
        ws = [1.0 + pull * np.maximum(0.0, -dk_sdf((R + q) / 2)) for q in nb]
        avg = sum(w[..., None] * q for w, q in zip(ws, nb)) / sum(ws)[..., None]
        g = dk_grad(R)
        n = g / np.linalg.norm(g, axis=-1, keepdims=True)
        m = avg - R
        m -= n * (m * n).sum(-1, keepdims=True)
        R = R + 0.5 * m
        for _ in range(2):
            g = dk_grad(R)
            R = R - g * (dk_sdf(R) / (g * g).sum(-1))[..., None]
    return R


def dk_eye():
    """The left eye's middle on the head (mm), the way across it toward the back, and up it."""
    e = DK["eye"]
    az, el = math.radians(e["az"]), math.radians(e["el"])
    d = np.array([[math.sin(az) * math.cos(el), -math.cos(az) * math.cos(el), math.sin(el)]])
    p = dk_march(d, DK["head"][0])[0][0]
    n = dk_normal(p)
    t1 = np.cross([0.0, 0.0, 1.0], n)
    t1 /= np.linalg.norm(t1)
    t2 = np.cross(n, t1)
    return p, t1, t2 if t2[2] > 0 else -t2, n


def dk_bill_rings(upper, hi):
    """The moulded bill, base (sunk in the face) to tip: the upper bill's round side up and the
    lower's down, their flat sides meeting at the mouth, which turns up at its corners (the
    smile). Rings bunch toward the tip, which rounds off in plan and side."""
    b = DK["bill"]
    (y0, z0), (y1, z1) = b["base"], b["tip"]
    if not upper:
        y1 += b["short"]
    m, k = segs(hi, 10), segs(hi, 5)
    nr = segs(hi, 10)
    hs = b["up"] if upper else b["lo"]
    rings = []
    for i in range(nr + 1):
        u = math.sin(0.5 * math.pi * i / nr)
        y = y0 + (y1 - y0) * u
        zc = z0 + (z1 - z0) * u - (0.0 if upper else b["gap"])
        if i == nr:
            rings.append([(mm(0.0), mm(y), mm(zc - (0.0 if upper else 0.6)))])
            break
        rnd = 1.0 if u < 0.6 else math.sqrt(max(0.0, 1 - ((u - 0.6) / 0.4) ** 2))
        w = (b["hw"][0] + (b["hw"][1] - b["hw"][0]) * u ** 0.7) * max(rnd, 0.0) ** 0.8
        h = (hs[0] + (hs[1] - hs[0]) * u) * (0.35 + 0.65 * rnd)

        def zg(x):
            return zc + b["smile"] * (x / b["hw"][1]) ** 2

        ring = []
        if upper:      # over the top from +x to -x, then back along the flat underside
            for j in range(m):
                a = math.pi * j / m
                x = w * math.cos(a)
                ring.append((x, zg(x) + h * math.sin(a) ** 0.75))
            ring += [(-w + 2 * w * j / k, zg(-w + 2 * w * j / k)) for j in range(k)]
        else:          # under from -x to +x, then back along the flat top
            for j in range(m):
                a = math.pi * j / m
                x = -w * math.cos(a)
                ring.append((x, zg(x) - h * math.sin(a) ** 0.75))
            ring += [(w - 2 * w * j / k, zg(w - 2 * w * j / k)) for j in range(k)]
        rings.append([(mm(x), mm(y), mm(z)) for x, z in ring])
    return rings, m


def dk_body(hi):
    """The duck, sampled along rays from inside its neck: rings from its foot to its crown, each
    starting straight ahead, so the loft's two halves part along the mould seam front and back."""
    s = Shape()
    nr, n = (140, 200) if hi else (44, 72)
    C = DK["centre"]
    a = -math.pi / 2 + 2 * math.pi * np.arange(n) / n
    R, again = [], 0
    for i in range(1, nr):
        ph = math.pi * i / nr
        D = np.stack([math.sin(ph) * np.cos(a), math.sin(ph) * np.sin(a),
                      -math.cos(ph) * np.ones(n)], axis=-1)
        pts, g = dk_march(D, C)
        again += g
        R.append(pts)
    if again:
        print(f"  RubberDuck: {again} rays see the duck twice (a fold in its surface)")
    poles = [dk_march(np.array([[0.0, 0.0, z]]), C)[0][0] for z in (-1.0, 1.0)]
    R = dk_settle(np.array(R), poles, 60)
    rings = ([[tuple(mm(v) for v in poles[0])]] + [[tuple(mm(v) for v in p) for p in r] for r in R]
             + [[tuple(mm(v) for v in poles[1])]])
    s.loft(rings, DK_VINYL)
    for upper in (True, False):
        br, m = dk_bill_rings(upper, hi)
        s.loft(br, DK_BILL, kinds=lambda j, m=m: DK_BILL if j < m else DK_MOUTH)
    return s


def duck_look(L, f):
    nb = L.nb
    xm, ym, zm = nb.mul(L.x, K.STUD_MM), nb.mul(L.y, K.STUD_MM), nb.mul(L.z, K.STUD_MM)
    ax = nb.absf(xm)

    def sq(v):
        return nb.mul(v, v)

    def dot(o, t):
        """(P - o) . t in mm, P mirrored onto the left side."""
        return nb.add(nb.add(nb.mul(nb.sub(ax, o[0]), t[0]), nb.mul(nb.sub(ym, o[1]), t[1])),
                      nb.mul(nb.sub(zm, o[2]), t[2]))

    vin = L.k(DK_VINYL)
    # the vinyl: a warm egg-yolk yellow with a satin sheen and the mould's faint orange peel,
    # deeper and warmer low down where it's thickest, a touch paler up on the crown
    mott = L.noise(80.0, 1, detail=3)
    peel = L.noise(2400.0, 2, detail=2)
    col = nb.tint(hexc("#FFCB1C"), nb.mr(mott, 0.3, 0.7, 0.965, 1.03))
    C = Coat(L, col, nb.mr(L.noise(150.0, 3, detail=2), 0.3, 0.7, 0.33, 0.43), 0.0,
             nb.mul(peel, 0.00011))
    C.paint(nb.mul(vin, nb.mul(nb.sub(1.0, nb.ss(zm, 2.0, 16.0)), 0.4)), hexc("#EFA912"))
    C.paint(nb.mul(vin, nb.mul(nb.ss(zm, 70.0, 86.0), 0.45)), hexc("#FFDA4A"))
    # the mould's seam: a faint raised line down the middle, over the crown, the back and under,
    # caught only by a grazing light (twice as tall, it read as a fold down the tail)
    seam = nb.mul(vin, nb.sub(1.0, nb.ss(ax, 0.15, 0.7)))
    C.paint(seam, None, 0.34, None, mm(0.035))
    # each wing's moulded edge and three feather grooves toward its tip
    w = DK["wing"]
    R = WING_R
    lx, ly, lz = (dot(w["at"], tuple(R[:, i])) for i in range(3))
    lz = nb.math("DIVIDE", lz, nb.sub(1.0, nb.mul(nb.ss(ly, -0.5 * w["r"][1], w["r"][1]), w["taper"])))
    e = nb.add(sq(nb.mul(ly, 1.0 / w["r"][1])), sq(nb.mul(lz, 1.0 / w["r"][2])))
    out = nb.ss(lx, -4.5, 0.5)
    rim = nb.mul(nb.mul(vin, out), nb.mul(nb.ss(e, 0.8, 0.88), nb.sub(1.0, nb.ss(e, 0.93, 1.02))))
    grooves = None
    for g in (6.5, 10.5, 14.5):
        yy = nb.add(nb.sub(ly, g), nb.mul(sq(lz), -0.02))
        band = nb.sub(1.0, nb.ss(nb.absf(yy), 0.25, 0.75))
        grooves = band if grooves is None else nb.add(grooves, band, clamp=True)
    feath = nb.mul(nb.mul(vin, out), nb.mul(grooves, nb.sub(1.0, nb.ss(e, 0.7, 0.86))))
    C.paint(nb.add(rim, feath, clamp=True), hexc("#E2A914"), 0.45, None, -mm(0.22))
    # printed eyes: a white almond, a big black pupil looking ahead, a shine, a fine dark rim;
    # the print rubbed thin in specks
    E, t1, t2, n = dk_eye()
    ey = DK["eye"]
    u, v, h = dot(E, t1), dot(E, t2), nb.absf(dot(E, n))
    near = nb.sub(1.0, nb.ss(h, 2.5, 4.0))
    k_w = nb.add(sq(nb.mul(u, 1.0 / ey["w"])), sq(nb.mul(v, 1.0 / ey["h"])))
    pw, ph = ey["pupil"]
    k_p = nb.add(sq(nb.mul(nb.add(u, 1.0), 1.0 / pw)), sq(nb.mul(nb.add(v, 0.35), 1.0 / ph)))
    k_s = nb.add(sq(nb.add(u, 1.9)), sq(nb.sub(v, 1.25)))
    rub = nb.ss(L.noise(900.0, 4, detail=3), 0.75, 0.79)
    eye = nb.mul(nb.mul(vin, near), nb.sub(1.0, rub))
    C.paint(nb.mul(eye, nb.sub(1.0, nb.ss(k_w, 1.12, 1.2))), hexc("#1B1512"), 0.3)
    C.paint(nb.mul(eye, nb.sub(1.0, nb.ss(k_w, 0.92, 1.0))), hexc("#F4F0E6"), 0.3)
    C.paint(nb.mul(eye, nb.sub(1.0, nb.ss(k_p, 0.92, 1.0))), hexc("#100D0C"), 0.22)
    C.paint(nb.mul(eye, nb.sub(1.0, nb.ss(k_s, ey["shine"] ** 2 * 0.8, ey["shine"] ** 2))),
            hexc("#FBFAF5"), 0.22)
    # the squeak hole: dark inside, a little rolled lip round it
    ho = DK["hole"]
    rr = nb.math("SQRT", nb.add(sq(xm), sq(nb.sub(ym, ho["y"]))))
    low = nb.sub(1.0, nb.ss(zm, 0.6, 1.4))
    C.paint(nb.mul(nb.mul(vin, low), nb.sub(1.0, nb.ss(rr, ho["r"] - 0.3, ho["r"]))),
            hexc("#2B1F08"), 0.8, None, -mm(0.4))
    lip = nb.mul(nb.ss(rr, ho["r"] - 0.1, ho["r"] + 0.25),
                 nb.sub(1.0, nb.ss(rr, ho["r"] + ho["lip"] - 0.3, ho["r"] + ho["lip"])))
    C.paint(nb.mul(nb.mul(vin, low), lip), None, 0.3, None, mm(0.25))
    # the bill: orange paint, glossier than the vinyl, a darker mouth line, worn back to the
    # yellow along its tip's rim
    bi = L.k(DK_BILL)
    C.paint(bi, nb.tint(hexc("#EE6418"), nb.mr(L.noise(200.0, 5, detail=3), 0.3, 0.7, 0.975, 1.025)), 0.22)
    C.paint(L.k(DK_MOUTH), hexc("#A8320E"), 0.4)
    tip = nb.mul(nb.mul(bi, L.edge(mm(0.9), k=4.0)),
                 nb.mul(nb.sub(1.0, nb.ss(ym, -46.8, -45.6)), nb.ss(L.noise(200.0, 6, detail=3), 0.5, 0.62)))
    C.paint(tip, hexc("#F2B62C"), 0.36)
    # scuffed matt and a touch paler on what it was knocked about on: the breast and tail tip
    hit = nb.add(nb.sub(1.0, nb.ss(ym, -36.0, -31.0)), nb.ss(ym, 44.0, 49.0), clamp=True)
    sc = nb.mul(nb.mul(vin, hit), nb.ss(L.noise(70.0, 7, detail=3), 0.5, 0.7))
    C.paint(nb.mul(sc, 0.5), None, 0.6)
    C.finish(f.dust, grime=0.3)
    return C.surface(bump_dist=0.0008, bump=0.6)


# --- how it squeaks -------------------------------------------------------------------------------

def duck_squeeze():
    """The whole duck squashed and let go: a rise as the fingers close, a quick squash (the
    squeak), held a beat, then a spring back past its size and a wobble still; its nose dips as
    it's pressed and lifts on the bounce."""
    g, sq, ho, bo = SQ["grip"], SQ["squash"], SQ["hold"], SQ["bounce"]
    st = [(0.0, 1.0), (g[0], g[1], "Sine", "Out"), (sq[0], sq[1], "Quad", "Out"),
          (ho[0], ho[1], "Sine", "InOut")]
    st += [(t, v, "Quad", "Out") if i == 0 else (t, v) for i, (t, v) in enumerate(bo)]
    a, b, c = SQ["nod"]
    pitch = [(0.0, 0.0), (g[0], -0.1 * a, "Sine", "Out"), (sq[0], a, "Quad", "Out"), (ho[0], a),
             (bo[0][0], b, "Quad", "Out"), (bo[1][0], c), (bo[3][0], 0.0)]
    return round(bo[-1][0] + 0.25, 2), [("Body", "stretch", st), ("Body", "pitch", pitch)]


DQ_DUR, DQ_TRACKS = duck_squeeze()

RUBBER_DUCK = kit.Find(
    "RubberDuck",
    [kit.Part("Body", dk_body)],
    duck_look,
    motions={
        # squeezed in the hand: it squashes, squeaks (the game's squeak here, loud enough to
        # carry down the hall), is held a beat, and springs back with a wobble
        "Squeeze": dict(duration=DQ_DUR, focus=(0.0, mm(-4.0), mm(42.0)), distance=1.15,
                        tracks=DQ_TRACKS),
    },
    dust=DK["dust"], seed=DK["seed"], texels=900,
)


# --- The kazoo (F-04f) ---------------------------------------------------------------------------
# A classic pressed-tin kazoo of our own (README): a tin top with a crease down its middle, three
# rings and our star mark pressed into it, a red-printed bottom half crimped over its edges, both
# ends turned under, a threaded collar on top and a dished screw cap with a punched hole, through
# which the cream wax-paper skin shows. Hum into the wide end and the skin buzzes.

KZ = K.KAZOO
BW = K.BLOW
(KZ_SHELL, KZ_IN, KZ_CAP, KZ_COLLAR, KZ_SKIN) = range(66, 71)
KZ_L = KZ["length"]
KY0 = -KZ_L / 2            # the mouth end's lip (mm)


def kz_soft(d):
    """max(d, 0), its corner rounded over KZ.knee's softness."""
    k = KZ["knee"][1]
    return k * math.log1p(math.exp(d / k)) if d < 8 * k else d


def kz_dims(t):
    """Half width, ridge height and seam height (mm) a fraction t back from the mouth end."""
    kn = KZ["knee"][0]

    def run(v):
        a = (v[0] - v[1]) / kn
        b = (v[1] - v[2]) / (1.0 - kn) - a
        return v[0] - a * t - b * kz_soft(t - kn)
    H = run(KZ["h"])
    return run(KZ["w"]), H, KZ["seam"] * H


def kz_xz(t, phi, bead=1.0):
    """A point round the section at t (x across, z up, mm): phi 0 at the right-hand seam, up
    over the ridge to the left seam at pi, then round under the bottom."""
    w, H, ys = kz_dims(t)
    c, s = math.cos(phi), math.sin(phi)
    if s >= 0.0:
        u, v = abs(c) ** (2.0 / KZ["top_sq"]), s ** (2.0 / KZ["top_sq"])
        rn = 1.0 - KZ["ridge"] * math.sqrt(0.003)
        z = ys + (H - ys) * v * (1.0 - KZ["ridge"] * math.sqrt(u * u + 0.003)) / rn
    else:
        u, v = abs(c) ** (2.0 / KZ["bot_sq"]), (-s) ** (2.0 / KZ["bot_sq"])
        z = ys * (1.0 - v)
    x = math.copysign(w * u, c)
    if bead:
        b, hh = KZ["bead"]
        x += math.copysign(b * bead * math.exp(-((z - (ys - 0.2)) / hh) ** 2), c)
    return x, z


def kz_section(t, n, bead=1.0, inset=0.0):
    pts = [kz_xz(t, 2 * math.pi * j / n, bead) for j in range(n)]
    if not inset:
        return pts
    out = []
    for j, (x, z) in enumerate(pts):
        (xa, za), (xb, zb) = pts[j - 1], pts[(j + 1) % n]
        tx, tz = xb - xa, zb - za
        ln = math.hypot(tx, tz) or 1.0
        out.append((x - inset * tz / ln, z + inset * tx / ln))
    return out


def kz_ring(sec, Y):
    return [(mm(x), mm(Y), mm(z)) for x, z in sec]


def kz_lip(rings, t, Y_end, r, n, steps, toward):
    """The rolled lip at an end: from the outside round to the inside (toward = -1, the mouth),
    or from the inside round to the outside (toward = +1, the tail)."""
    out = kz_section(t, n, 0.0)
    mid = kz_section(t, n, 0.0, r)
    for i in range(steps + 1):
        a = math.pi * i / steps if toward < 0 else math.pi * (1.0 - i / steps)
        ca, sa = math.cos(a), math.sin(a)
        sec = [(mx + ca * (ox - mx), mz + ca * (oz - mz)) for (ox, oz), (mx, mz) in zip(out, mid)]
        rings.append(kz_ring(sec, Y_end - toward * r * (1.0 - sa)))


def kz_depth(s, end, n, steps):
    """The inside of an end, seen past its lip: the wall a few mm in, then a dark wall across."""
    r = KZ["lip"][0 if end < 0 else 1]
    d = KZ["deep"][0 if end < 0 else 1]
    Y_lip = (KY0 + r) if end < 0 else (-KY0 - r)
    Y_deep = (KY0 + d) if end < 0 else (-KY0 - d)
    rings = []
    for i in range(steps + 1):
        Y = Y_lip + (Y_deep - Y_lip) * i / steps if end < 0 else Y_deep + (Y_lip - Y_deep) * i / steps
        rings.append(kz_ring(kz_section((Y - KY0) / KZ_L, n, 0.0, 2 * r), Y))
    zc = sum(p[2] for p in rings[0 if end > 0 else -1]) / n
    pole = [(0.0, mm(Y_deep), zc)]
    rings = [pole] + rings if end > 0 else rings + [pole]
    s.loft(rings, KZ_IN)


CAP_T = KZ["cap_at"] / KZ_L
_, CAP_H, _ = kz_dims(CAP_T)
# the collar stands square to the top, which falls a little toward the tail
_slope = (kz_dims(CAP_T + 0.01)[1] - kz_dims(CAP_T - 0.01)[1]) / (0.02 * KZ_L)
CAP_R = Matrix.Rotation(math.atan(_slope), 4, "X")
CAP_AT = V(0.0, KY0 + KZ["cap_at"], CAP_H)
CAP_M = T(CAP_AT) @ CAP_R
SK = KZ["skin"]
SKIN_AT = CAP_AT + (CAP_R.to_3x3() @ V(0.0, 0.0, KZ["collar"]["up"] + SK["on"]))
SKIN_AXIS = tuple(CAP_R.to_3x3() @ Vector((0.0, 0.0, 1.0)))


def kz_turret(s, hi):
    """The threaded collar and the dished screw cap over it (mm about the collar's foot)."""
    co, cp = KZ["collar"], KZ["cap"]
    r, ri, up = co["r"], co["ri"], co["up"]
    prof = [(r - 0.3, -co["low"]), (r, -co["low"]), (r, 0.3)]
    if hi:
        for zc in (0.95, 2.3):          # the rolled thread, where it shows under the cap's rim
            prof += [(r, zc - 0.4), (r + 0.16, zc - 0.22), (r + 0.24, zc), (r + 0.16, zc + 0.22), (r, zc + 0.4)]
    prof += [(r, up - 0.35), (r - 0.12, up - 0.08), (r - 0.4, up), (ri + 0.3, up - 0.05),
             (ri + 0.05, up - 0.3), (ri, up - 0.6), (ri, 0.0), (0.0, 0.0)]
    s.lathe([(mm(a), mm(b)) for a, b in prof], KZ_COLLAR, segs(hi, 28), CAP_M)
    # the cap: up the outside from its rolled rim, over the dished top and the hole's turned-down
    # edge, then back out under the top and down inside the skirt
    ro, rs, g, top, hole, dish, bd = (cp[k] for k in ("r", "skirt", "gap", "top", "hole", "dish", "bead"))
    rin = rs - 0.3
    rc = r + 0.3                        # the foot's inner edge, just clear of the collar's thread
    bc = (ro - bd, g + bd)              # the rolled rim's middle
    if hi:
        foot = [(rc + 0.15, g + 0.42), (rc, g + 0.3), (rc + 0.05, g + 0.08), (rc + 0.25, g)]
        angs = [270, 290, 315, 340, 360, 380, 405, 425, 445]
        rim = [(bc[0] + bd * math.cos(math.radians(a)), bc[1] + bd * math.sin(math.radians(a))) for a in angs]
        skirt = [(rs, g + 2 * bd + 0.15)]
        for zc in (g + 2.15, g + 2.85):             # the thread rolled into the skirt
            skirt += [(rs, zc - 0.28), (rs - 0.1, zc - 0.12), (rs - 0.14, zc), (rs - 0.1, zc + 0.12), (rs, zc + 0.28)]
        n_d = 9
        dishp = [(rs - 0.05, top - 0.6), (rs - 0.2, top - 0.25), (rs - 0.45, top - 0.06), (rs - 0.8, top)]
        for i in range(1, n_d + 1):
            f = i / n_d
            rr = (rs - 0.8) + ((hole + 0.75) - (rs - 0.8)) * f
            dishp.append((rr, top - dish * (1.0 - (1.0 - f) ** 2)))
        edge = [(hole + 0.4, top - dish - 0.08), (hole + 0.12, top - dish - 0.22), (hole, top - dish - 0.45),
                (hole + 0.08, top - dish - 0.62), (hole + 0.3, top - dish - 0.7)]
        under = [(hole + 0.9, top - dish - 0.38), (rs - 1.0, top - 0.33), (rin, top - 0.5), (rin, g + 2 * bd),
                 (rin - 0.3, g + 0.45), (rc + 0.6, g + 0.42)]
        prof = foot + rim + skirt + dishp + edge + under
    else:
        prof = [(rc + 0.1, g + 0.4), (rc, g + 0.1), (rc + 0.3, g), (ro - bd, g), (ro, g + bd), (rs, g + 2 * bd),
                (rs, top - 0.45), (rs - 0.6, top), (hole + 0.75, top - dish), (hole, top - dish - 0.45),
                (hole + 0.6, top - dish - 0.55), (rin, top - 0.5), (rin, g + 0.45), (rc + 0.4, g + 0.42)]
    s.lathe([(mm(a), mm(b)) for a, b in prof], KZ_CAP, segs(hi, 28), CAP_M)


def kz_body(hi):
    s = Shape()
    n = 192 if hi else 40
    nl = 118 if hi else 20
    steps = 8 if hi else 3
    rm, rt = KZ["lip"]
    tm, tt = rm / KZ_L, 1.0 - rt / KZ_L
    rings = []
    # from inside the tail, round its lip, along the outside to the mouth end, round its lip
    kz_lip(rings, tt, -KY0, rt, n, steps, +1)
    for i in range(1, nl):
        t = tt + (tm - tt) * i / nl
        Y = KY0 + t * KZ_L
        fade = min(ss_(t * KZ_L - rm, 0.6, 3.0), ss_((1.0 - t) * KZ_L - rt, 0.6, 3.0))
        rings.append(kz_ring(kz_section(t, n, fade if hi else 0.0), Y))
    kz_lip(rings, tm, KY0, rm, n, steps, -1)
    s.loft(rings, KZ_SHELL)
    kz_depth(s, +1, n, 4 if hi else 1)
    kz_depth(s, -1, n, 4 if hi else 1)
    kz_turret(s, hi)
    return s


def ss_(v, a, b):
    f = min(max((v - a) / (b - a), 0.0), 1.0)
    return f * f * (3 - 2 * f)


def kz_skin(hi):
    s = Shape()
    r, d, t = SK["r"], SK["dome"], SK["t"]
    fr = [0.0, 0.3, 0.55, 0.75, 0.9, 1.0] if hi else [0.0, 0.6, 1.0]
    lo = [(r * f, d * (1.0 - f * f)) for f in fr]
    prof = lo + [(r, t)] + [(r * f, t + d * (1.0 - f * f)) for f in reversed(fr[:-1])]
    s.lathe([(mm(a), mm(b)) for a, b in prof], KZ_SKIN, segs(hi, 20),
            T(SKIN_AT) @ CAP_R)
    return s


KZ_BD = mm(0.15)            # the look's bump distance: a height of 1 stands 0.15 mm proud


def kz_h(v):
    """A height in mm, in the bump's units (the Bump node multiplies height by its distance)."""
    return v / 0.15


def kazoo_look(L, f):
    nb = L.nb
    xm, ym, zm = nb.mul(L.x, K.STUD_MM), nb.mul(L.y, K.STUD_MM), nb.mul(L.z, K.STUD_MM)

    def sq(v):
        return nb.mul(v, v)

    def bell(d, at, w):
        """1 at `at`, falling smoothly to 0 `w` either side: a pressed bead's crest."""
        return nb.mul(nb.ss(d, at - w, at), nb.sub(1.0, nb.ss(d, at, at + w)))

    def total(ms):
        out = ms[0]
        for m in ms[1:]:
            out = nb.add(out, m, clamp=True)
        return out

    shell, inside = L.k(KZ_SHELL), L.k(KZ_IN)
    cap, collar, skin = L.k(KZ_CAP), L.k(KZ_COLLAR), L.k(KZ_SKIN)
    # where the halves meet: the seam's height along the kazoo (KZ.seam of the ridge's height)
    kn = KZ["knee"][0]
    h0, h1, h2 = KZ["h"]
    a = (h0 - h1) / kn
    b = (h1 - h2) / (1.0 - kn) - a
    t = nb.mul(nb.sub(ym, KY0), 1.0 / KZ_L)
    H = nb.sub(nb.sub(h0, nb.mul(t, a)), nb.mul(nb.math("MAXIMUM", nb.sub(t, kn), 0.0), b))
    up_seam = nb.sub(zm, nb.mul(H, KZ["seam"]))
    # the red half's edge is rolled up over the seam's bead onto the top's side, as a crimped
    # kazoo's is: that fold is the red a player sees from above (the half below tucks under)
    fold = KZ["fold"]
    red = nb.mul(shell, nb.sub(1.0, nb.ss(up_seam, fold - 0.06, fold + 0.06)))
    tin = nb.mul(shell, nb.ss(up_seam, fold - 0.06, fold + 0.06))
    top = nb.mul(tin, nb.ss(L.nz, 0.35, 0.6))      # the top, where the pressings are
    lows, highs = [], []                            # creases that tarnish, crests that polish

    # tinplate: bright, faintly warm, lacquered, brushed in fine streaks down its length
    streak = L.noise(700.0, 1, stretch=(1.0, 0.025, 1.0), detail=3)
    TIN = nb.tint(hexc("#DEDACE"), nb.mr(streak, 0.3, 0.7, 0.86, 1.07))
    C = Coat(L, TIN, nb.mr(L.noise(500.0, 2, stretch=(1.0, 0.03, 1.0), detail=2), 0.3, 0.7, 0.17, 0.3), 0.9)
    # the bottom half printed red, a glossy lacquered print
    RED = nb.tint(hexc("#B8261C"), nb.mr(L.noise(60.0, 3, detail=2), 0.3, 0.7, 0.94, 1.05))
    C.paint(red, RED, nb.mr(L.noise(40.0, 4, detail=1), 0.3, 0.7, 0.22, 0.3), 0.0)
    # the crimp: the red edge rolled over the tin's, a dark line where it grips, its crest
    # rubbed through to the tin in places from years in a pocket
    crimp = nb.mul(shell, bell(up_seam, fold + 0.1, 0.18))
    C.paint(nb.mul(crimp, 0.85), hexc("#2E2520"), 0.5, 0.2, kz_h(-0.08))
    # the fold is two thicknesses of tin: it stands a step proud of the top's side
    C.paint(nb.mul(shell, nb.sub(1.0, nb.ss(up_seam, fold - 0.1, fold + 0.02))), height=kz_h(0.1))
    crest = nb.mul(red, bell(up_seam, -0.25, 0.55))
    rub = nb.ss(L.noise(30.0, 14, stretch=(1.0, 0.08, 1.0), detail=4), 0.5, 0.62)
    C.paint(nb.mul(crest, rub), hexc("#BDB7A8"), 0.3, 0.85)
    # the inside: bare tin, dull, darkening into the tube
    C.paint(inside, hexc("#6A665C"), 0.5, 0.6)

    # the three rings pressed up out of the top: a round bead, its middle sunk a touch
    w = KZ["ring_w"]
    for at, R, up in KZ["rings"]:
        d = nb.math("SQRT", nb.add(sq(xm), sq(nb.sub(ym, KY0 + at))))
        bead = bell(d, R, w)
        mid = nb.sub(1.0, nb.ss(d, R - 1.4, R - 0.7))
        C.paint(nb.mul(top, bead), height=kz_h(up))
        C.paint(nb.mul(top, mid), height=kz_h(-0.1))
        lows.append(nb.mul(top, nb.add(bell(d, R + w, 0.4), nb.mul(bell(d, R - w, 0.35), 0.6), clamp=True)))
        highs.append(nb.mul(top, nb.ss(bead, 0.72, 0.95)))

    # our maker's mark: an oval rim, a fine line inside it, a raised star in a stippled field
    mk = KZ["mark"]
    my = nb.sub(ym, KY0 + mk["at"])
    rx, ry = mk["r"][1], mk["r"][0]
    e = nb.math("SQRT", nb.add(sq(nb.mul(xm, 1.0 / rx)), sq(nb.mul(my, 1.0 / ry))))
    mtop = nb.mul(tin, nb.ss(L.nz, 0.3, 0.5))
    rim = bell(e, 0.88, 0.11)
    line = bell(e, 0.7, 0.045)
    field = nb.sub(1.0, nb.ss(e, 0.64, 0.68))
    rs = nb.math("SQRT", nb.add(sq(xm), sq(my)))
    th = nb.math("ARCTAN2", xm, nb.sub(0.0, my))
    lobe = nb.pw(nb.add(0.5, nb.mul(nb.math("COSINE", nb.mul(th, 5.0)), 0.5)), 2.4)
    edge_r = nb.mul(nb.add(0.38, nb.mul(lobe, 0.62)), mk["star"])
    star = nb.sub(1.0, nb.ss(nb.sub(rs, edge_r), -0.12, 0.12))
    # the star's arms bevelled: highest down their middles
    bev = nb.sub(1.0, nb.mul(nb.math("MINIMUM", nb.math("DIVIDE", rs, edge_r), 1.0), 0.45))
    stip = nb.ss(L.noise(900.0, 15, detail=1), 0.55, 0.62)
    C.paint(nb.mul(mtop, rim), height=kz_h(mk["up"]))
    C.paint(nb.mul(mtop, line), height=kz_h(0.14))
    C.paint(nb.mul(mtop, nb.mul(star, bev)), height=kz_h(mk["up"] * 0.95))
    C.paint(nb.mul(nb.mul(mtop, field), nb.mul(nb.sub(1.0, star), stip)), height=kz_h(-0.06))
    lows.append(nb.mul(mtop, nb.add(bell(e, 0.88 + 0.13, 0.06), nb.mul(field, nb.sub(1.0, star)), clamp=True)))
    lows.append(nb.mul(nb.mul(mtop, field), nb.mul(bell(nb.sub(rs, edge_r), 0.15, 0.12), 1.0)))
    highs.append(nb.mul(mtop, nb.add(nb.ss(rim, 0.7, 0.95), nb.mul(star, 0.9), clamp=True)))
    mfield = nb.mul(nb.mul(mtop, field), nb.sub(1.0, star))     # darkest: the star stands on it

    # the cap and collar: the same tin, the cap a little greyer and handled more
    CAPT = nb.tint(hexc("#D6D2C6"), nb.mr(L.noise(300.0, 5, detail=3), 0.3, 0.7, 0.9, 1.05))
    C.paint(nb.add(cap, collar, clamp=True), CAPT, nb.mr(L.noise(350.0, 6, detail=2), 0.3, 0.7, 0.2, 0.3), 0.9)
    # in the cap's frame: across its middle, round it, and up from the collar's foot (the cap
    # leans back a touch with the top, so its up runs a touch toward the mouth)
    dy = nb.sub(ym, KY0 + KZ["cap_at"])
    dcap = nb.math("SQRT", nb.add(sq(xm), sq(dy)))
    zc = nb.sub(nb.sub(zm, CAP_H), nb.mul(dy, _slope))
    # the grip band above the thread: fine ribs pressed round it, tarnish between them
    kn_ = KZ["knurl"]
    rib = nb.add(0.5, nb.mul(nb.math("COSINE", nb.mul(nb.math("ARCTAN2", xm, dy), float(kn_["n"]))), 0.5))
    band = nb.mul(nb.mul(cap, nb.sub(1.0, nb.ss(nb.math("ABSOLUTE", L.nz), 0.35, 0.6))),
                  nb.mul(nb.ss(zc, kn_["band"][0], kn_["band"][0] + 0.25),
                         nb.sub(1.0, nb.ss(zc, kn_["band"][1] - 0.25, kn_["band"][1]))))
    C.paint(nb.mul(band, nb.ss(rib, 0.25, 0.75)), height=kz_h(kn_["up"]))
    lows.append(nb.mul(band, nb.mul(nb.sub(1.0, nb.ss(rib, 0.05, 0.35)), 0.8)))
    highs.append(nb.mul(band, nb.mul(nb.ss(rib, 0.8, 1.0), 0.8)))
    # the bead pressed round the cap's top, between the rim and the hole
    cr = KZ["cap_ring"]
    ctop = nb.mul(cap, nb.ss(L.nz, 0.6, 0.85))
    cbead = bell(dcap, KZ["cap"]["hole"] + cr[0], cr[1])
    C.paint(nb.mul(ctop, cbead), height=kz_h(cr[2]))
    lows.append(nb.mul(ctop, nb.mul(bell(dcap, KZ["cap"]["hole"] + cr[0] + cr[1], 0.3), 0.7)))
    highs.append(nb.mul(ctop, nb.ss(cbead, 0.7, 0.95)))
    # the cap's rolled rim, polished by thumbs
    rimb = nb.mul(cap, L.edge(mm(0.5), k=4.0))
    highs.append(nb.mul(rimb, 0.6))
    # where the collar's foot meets the top and under the cap's rim: tarnish creeps in
    lows.append(nb.mul(shell, nb.mul(bell(dcap, KZ["collar"]["r"] + 0.6, 1.4), 0.9)))
    lows.append(nb.mul(collar, 0.5))

    # the wax-paper skin: cream, faintly crinkled, a little yellowed toward its edge
    PAPER = nb.tint(hexc("#F1E9D2"), nb.mr(L.noise(160.0, 7, detail=3), 0.3, 0.7, 0.93, 1.03))
    C.paint(skin, nb.mixc(nb.ss(dcap, 3.0, 8.0), PAPER, hexc("#E2D2A8")), 0.42, 0.0,
            nb.mul(L.noise(900.0, 8, detail=3), kz_h(0.03)))

    # aged tinplate: dull yellow-grey blotches, thicker toward the tail and low down the sides
    blot = nb.ss(L.noise(16.0, 16, detail=4, rough=0.6), 0.5, 0.72)
    aged = nb.mul(tin, nb.mul(blot, nb.add(0.35, nb.mul(nb.ss(ym, -10.0, 50.0), 0.4))))
    C.paint(nb.mul(aged, 0.55), hexc("#B9AE92"), 0.38)
    # handled: tarnish where fingers hold it near the mouth end, polish on every crest and down
    # the ridge where a pocket rubs it, fine scratches down its length
    hold = nb.mul(tin, nb.mul(nb.sub(1.0, nb.ss(ym, -25.0, 5.0)), nb.ss(L.noise(45.0, 9, detail=4), 0.5, 0.68)))
    C.paint(nb.mul(hold, 0.4), hexc("#A39A84"), 0.4)
    # the creases: tarnish dark and dull in every pressed groove, the seam and round the collar
    low = total(lows)
    C.paint(nb.mul(nb.mul(low, nb.add(tin, nb.add(cap, collar, clamp=True), clamp=True)), 0.85),
            hexc("#544D40"), 0.55, 0.5)
    C.paint(nb.mul(mfield, 0.9), hexc("#4A4438"), 0.62, 0.35)
    C.paint(nb.mul(nb.mul(low, red), 0.6), hexc("#5A1A14"), 0.45)
    ridge = nb.mul(tin, nb.mul(nb.ss(nb.sub(zm, H), -0.9, -0.15),
                               nb.mr(L.noise(25.0, 17, stretch=(1.0, 0.15, 1.0), detail=3), 0.35, 0.7, 0.3, 1.0)))
    high = nb.add(total(highs), ridge, clamp=True)
    C.paint(nb.mul(high, 0.75), hexc("#F4F2EC"), 0.1, 0.95)
    scr = nb.ss(L.noise(1100.0, 10, stretch=(1.0, 0.018, 1.0), detail=2), 0.73, 0.76)
    C.paint(nb.mul(nb.mul(nb.add(tin, cap, clamp=True), scr), 0.5), hexc("#F0EDE5"), 0.16)
    C.paint(nb.mul(nb.mul(red, scr), 0.5), hexc("#C9C4B6"), 0.3, 0.8)
    # the red rubbed thin on the bottom where it's been slid about, worn through at the corners
    under = nb.mul(red, nb.ss(nb.sub(0.0, L.nz), 0.6, 0.85))
    C.paint(nb.mul(under, nb.ss(L.noise(80.0, 11, stretch=(1.0, 0.2, 1.0), detail=3), 0.45, 0.7)),
            hexc("#A23A2E"), 0.55)
    corner = nb.mul(nb.mul(red, L.edge(mm(1.2), k=4.0)), nb.ss(nb.sub(0.0, L.nz), 0.2, 0.5))
    C.paint(nb.mul(corner, nb.ss(L.noise(40.0, 18, stretch=(1.0, 0.1, 1.0), detail=4), 0.48, 0.6)),
            hexc("#BDB7A8"), 0.32, 0.85)
    ends = nb.add(nb.sub(1.0, nb.ss(ym, KY0 + 1.0, KY0 + 3.0)), nb.ss(ym, -KY0 - 3.0, -KY0 - 1.0), clamp=True)
    chips = C.enamel_wear(nb.mul(red, nb.add(nb.mul(ends, 0.9), nb.mul(crimp, 0.5), clamp=True)),
                          hexc("#C4BFB1"), 12, 1.0)
    rust = nb.mul(chips, nb.ss(L.noise(120.0, 13, detail=3), 0.55, 0.66))
    C.paint(rust, hexc("#7A4A2A"), 0.75, 0.1)
    C.finish(f.dust, grime=0.4)
    return C.surface(bump_dist=KZ_BD, bump=1.0)


# --- how it plays ---------------------------------------------------------------------------------

def kazoo_blow():
    """Lifted to the lips, the mouth end tipping up; the note starts and the skin under the cap
    shivers, swelling a little; the note stops, the skin stills, and it's lowered back."""
    lt, rise, tip = BW["lift"]
    h0, h1 = BW["hum"]
    l0, l1 = BW["lower"]
    sw = BW["swell"]
    z = [(0.0, 0.0), (lt * 0.8, mm(rise * 1.08), "Sine", "InOut"), (lt + 0.06, mm(rise)),
         (l0, mm(rise)), (l1 - 0.14, mm(-0.3), "Sine", "InOut"), (l1, 0.0)]
    pitch = [(0.0, 0.0), (lt * 0.85, tip * 1.1, "Sine", "InOut"), (lt + 0.08, tip),
             (h0 + 0.45, tip - sw), (h1 - 0.15, tip - 0.35 * sw), (l0, tip),
             (l1 - 0.12, 0.6, "Sine", "InOut"), (l1, 0.0)]
    mv, st = BW["skin"]
    step = 1.0 / BW["buzz"]
    move, stretch = [(0.0, 0.0), (h0, 0.0)], [(0.0, 1.0), (h0, 1.0)]
    i, t = 1, h0 + step
    while t < h1 + 0.1:
        att = min((t - h0) / 0.07, 1.0)
        rel = 1.0 - min(max((t - h1) / 0.1, 0.0), 1.0)
        amp = att * rel * (0.82 + 0.18 * math.sin(math.pi * min((t - h0) / (h1 - h0), 1.0)))
        sg = 1.0 if i % 2 else -1.0
        move.append((round(t, 4), mm(mv) * amp * sg, "Linear", "InOut"))
        stretch.append((round(t, 4), 1.0 + st * amp * sg, "Linear", "InOut"))
        i, t = i + 1, t + step
    move.append((round(h1 + 0.14, 4), 0.0))
    stretch.append((round(h1 + 0.14, 4), 1.0))
    return l1, [("Body", "z", z), ("Body", "pitch", pitch), ("Skin", "move", move), ("Skin", "stretch", stretch)]


KB_DUR, KB_TRACKS = kazoo_blow()

KAZOO = kit.Find(
    "Kazoo",
    [kit.Part("Body", kz_body),
     kit.Part("Skin", kz_skin, tuple(SKIN_AT), "Body", SKIN_AXIS)],
    kazoo_look,
    motions={
        # put to the lips and hummed into: the skin under the cap buzzes (the game plays the
        # note here), swelling as the note leans in, then stills, and it's lowered
        "Blow": dict(duration=KB_DUR, focus=tuple(CAP_AT + V(0.0, 0.0, 4.0)), distance=0.38,
                     view=(-1.1, -2.0, 1.5), drop=0.0, tracks=KB_TRACKS),
    },
    dust=KZ["dust"], seed=KZ["seed"], texels=1100,
)


# --- The toy drum (F-04f2) -----------------------------------------------------------------------
# A child's tin drum of our own (README): a printed tin shell (a deep blue field, cream stars and
# red roundels), red rolled-tin hoops, a white cotton cord laced in ten V's between them through
# punched holes, a calfskin head under the top hoop's rolled lip, and two turned beech sticks
# lying across the top. Bang: a stick lifts, snaps down onto the head and bounces off; the head
# dips and shivers; then the other stick, and at the end both together.

DR = K.DRUM
BG = K.BANG
(DR_SHELL, DR_FLOOR, DR_HOOP, DR_CORD, DR_HEAD, DR_STICK, DR_GROM) = range(71, 78)
DR_R, DR_H = DR["r"], DR["h"]
HP = DR["hoop"]
DR_B = DR_R + HP["out"]                 # the hoops' band (mm)
DR_RT = HP["roll"] * 1.25               # the top roll is fatter: it rolls over and in, over the head
HEAD_Z = DR_H - DR["head"]["sink"]
CD = DR["cord"]
DR_N = CD["n"]
TOP0 = -90.0 + 180.0 / DR_N             # the first top hole (degrees round from +X): a bottom
BOT0 = -90.0                            # hole straight at the front, a star above it
ST = DR["stick"]
ST_AX = ST["length"] - ST["bead"]       # butt end to the bead's middle (mm)


def cyl(r, th, z):
    a = math.radians(th)
    return Vector((r * math.cos(a), r * math.sin(a), z))


def dr_roll(c, rad, a0, a1, n):
    """Points round a rolled bead's section: centre c (r, z), from angle a0 to a1 (degrees)."""
    return [(c[0] + rad * math.cos(math.radians(a0 + (a1 - a0) * i / n)),
             c[1] + rad * math.sin(math.radians(a0 + (a1 - a0) * i / n))) for i in range(n + 1)]


def hoop_rz(hi):
    """The top hoop's section (r, z mm): up the outside from its rolled foot, round the fat roll
    at the rim, in over the head and down inside the lip, back out under it to the shell."""
    R, b, rr, rt = DR_R, DR_B, HP["roll"], DR_RT
    z0, z1, lip, deep = DR_H - HP["h"], DR_H, HP["lip"], HP["deep"]
    q = 3 if hi else 1
    pts = [(R + 0.15, z0 + 0.9), (R + 0.9, z0 + 0.05)]
    pts += dr_roll((b - 0.2 * rr, z0 + rr), rr, -90, 90, 2 * q)
    pts += [(b, z0 + 2 * rr + 0.5), (b, z1 - 2 * rt - 0.3)]
    pts += dr_roll((b - 0.25 * rt, z1 - rt), rt, -90, 90, 2 * q)
    pts += [(lip + 1.6, z1 - 0.1), (lip + 0.35, z1 - 0.55), (lip, z1 - 1.5),
            (lip, z1 - deep + 0.8), (lip + 0.7, z1 - deep), (R + 0.15, z1 - deep)]
    return pts


def cord_runs():
    """Each run of cord, top hole to bottom hole, as six points (mm): in the hole, just out of
    it, over the roll at the hoop's foot, the same at the other hoop, out of the hole, in it."""
    b, rr, cr = DR_B, HP["roll"], CD["r"]
    zt, zb = DR_H - CD["hole"], CD["hole"]
    z_ct, z_cb = DR_H - HP["h"] + rr, HP["h"] - rr        # the rolls' crests
    r_c = b + 0.8 * rr + cr
    runs = []
    for k in range(DR_N):
        ta = TOP0 + 360.0 * k / DR_N
        for tb in (ta - 180.0 / DR_N, ta + 180.0 / DR_N):
            def at(z, r):
                return cyl(r, ta + (tb - ta) * (zt - z) / (zt - zb), z)
            runs.append([cyl(b - 1.0, ta, zt), at(zt - 1.6, b + 0.9 * cr), at(z_ct, r_c),
                         at(z_cb, r_c), at(zb + 1.6, b + 0.9 * cr), cyl(b - 1.0, tb, zb)])
    return runs


def chaikin(P, n):
    for _ in range(n):
        Q = [P[0]]
        for a, c in zip(P, P[1:]):
            Q += [a.lerp(c, 0.25), a.lerp(c, 0.75)]
        P = Q + [P[-1]]
    return P


def resample(P, step):
    """Points every `step` mm along the polyline P."""
    acc = [0.0]
    for a, c in zip(P, P[1:]):
        acc.append(acc[-1] + (c - a).length)
    n = max(int(acc[-1] / step), 1)
    out, j = [], 0
    for i in range(n + 1):
        d = acc[-1] * i / n
        while j < len(P) - 2 and acc[j + 1] < d:
            j += 1
        f = (d - acc[j]) / max(acc[j + 1] - acc[j], 1e-9)
        out.append(P[j].lerp(P[j + 1], min(max(f, 0.0), 1.0)))
    return out


def strands(s, P, r, kind):
    """The cord's three twisted strands along the path P (mm), for the detailed mesh."""
    T = [(P[min(i + 1, len(P) - 1)] - P[max(i - 1, 0)]).normalized() for i in range(len(P))]
    U = [T[0].cross(Vector((0, 0, 1))).normalized()]
    for t in T[1:]:
        u = U[-1] - t * U[-1].dot(t)
        U.append(u.normalized())
    along = [0.0]
    for a, c in zip(P, P[1:]):
        along.append(along[-1] + (c - a).length)
    for k in range(3):
        pts = []
        for p, t, u, l in zip(P, T, U, along):
            ph = 2 * math.pi * (l / CD["twist"] + k / 3.0)
            w = t.cross(u)
            pts.append(p + (u * math.cos(ph) + w * math.sin(ph)) * (0.42 * r))
        s.tube([tuple(mm(c) for c in q) for q in pts], mm(0.62 * r), kind, sides=6)


def to_radial(p):
    """A matrix standing a lathe's Z out square from the drum's side at p (mm)."""
    rd = Vector((p.x, p.y, 0.0)).normalized()
    return T(Vector(tuple(mm(c) for c in p))) @ Vector((0, 0, 1)).rotation_difference(rd).to_matrix().to_4x4()


def drum_body(hi):
    s = Shape()
    n = segs(hi, 48)
    R, fl = DR_R, DR["floor"]
    # the tin shell and its bottom, one piece
    s.lathe([(mm(a), mm(c)) for a, c in [(0.0, fl), (R - 1.2, fl), (R, fl + 1.2), (R, HEAD_Z - 1.4),
                                          (R - 0.9, HEAD_Z - 0.5)]],
            DR_SHELL, n, kinds=[DR_FLOOR, DR_FLOOR, DR_SHELL, DR_SHELL])
    # the two rolled-tin hoops: the bottom one the top one upside down
    top = hoop_rz(hi)
    for prof in (top, [(r, DR_H - z) for r, z in reversed(top)]):
        s.lathe([(mm(a), mm(c)) for a, c in prof], DR_HOOP, n, strips=True)
    # the cord, laced in V's between the hoops; detailed, three twisted strands
    for run in cord_runs():
        if hi:
            strands(s, resample(chaikin(run, 3), 0.5), CD["r"], DR_CORD)
        else:
            s.tube([tuple(mm(c) for c in p) for p in run], mm(CD["r"]), DR_CORD, sides=6, caps=False)
    if hi:
        # a tin grommet round every hole the cord goes through
        gi, go, gh = CD["grommet"]
        for k in range(DR_N):
            for th, z in ((TOP0 + 360.0 * k / DR_N, DR_H - CD["hole"]), (BOT0 + 360.0 * k / DR_N, CD["hole"])):
                p = cyl(DR_B - 0.15, th, z)
                prof = [(go + 0.05, -0.3), (go, 0.05), (go - 0.35, gh), (gi + 0.3, gh), (gi + 0.05, 0.2), (gi, -0.3)]
                s.lathe([(mm(a), mm(c)) for a, c in prof], DR_GROM, 20, to_radial(p))
    return s


def drum_head(hi):
    s = Shape()
    R, f = DR_R, DR["head"]["flat"]
    rim = [(R + 0.4, -5.0), (R + 0.4, -2.6), (R - 0.4, -1.0), (0.96 * R, -0.3), (f * R, 0.0)]
    inner = [(f * R * (1.0 - i / 6.0), 0.0) for i in range(1, 7)] if hi else [(0.0, 0.0)]
    s.lathe([(mm(a), mm(HEAD_Z + c)) for a, c in rim + inner], DR_HEAD, segs(hi, 48))
    return s


def stick_rz(hi):
    """A stick's turned section (r, along mm), from the butt (0) to the bead's tip."""
    L, (r0, r1), rn, rb = ST["length"], ST["r"], ST["neck"], ST["bead"]
    cz = L - rb
    butt = [(r0 * math.sin(math.radians(a)), 0.6 * r0 * (1 - math.cos(math.radians(a))))
            for a in ((0, 30, 55, 75, 90) if hi else (0, 45, 90))]
    shaft = [(r0, 45.0), (0.5 * (r0 + r1), 100.0), (r1, 150.0), (rn + 0.25, cz - rb - 1.2)]
    if hi:
        shaft = [(r0, 20.0)] + shaft[:1] + [(0.75 * r0 + 0.25 * r1, 75.0)] + shaft[1:2] + \
                [(0.25 * r0 + 0.75 * r1, 125.0)] + shaft[2:]
    a0 = math.degrees(math.asin(rn / rb))
    nb_ = 8 if hi else 5
    bead = [(rb * math.sin(math.radians(a)), cz - rb * math.cos(math.radians(a)))
            for a in [a0 + (180.0 - a0) * i / nb_ for i in range(nb_ + 1)]]
    bead[-1] = (0.0, L)
    return butt + shaft + bead


def stick_place(side):
    """Where a stick lies as found (mm): its butt, its bead's middle, its direction butt to tip,
    its grip (the pivot) and its axis (a turn lifts the tip). side -1 the left, 1 the right."""
    rb = ST["bead"]
    tx, ty = ST["tip"]
    Cb = Vector((side * tx, ty, HEAD_Z + rb))
    sp = math.radians(ST["splay"])
    d = Vector((-side * math.sin(sp), math.cos(sp), 0.0))
    # where it crosses the top roll's crest, and how high it rests there
    rc = DR_B - 0.25 * DR_RT
    cd = Cb.x * d.x + Cb.y * d.y
    s = cd + math.sqrt(cd * cd - (Cb.x ** 2 + Cb.y ** 2) + rc * rc)
    x = ST_AX - s                                   # from the butt
    r0, r1 = ST["r"]
    rx = r0 if x < 45.0 else r0 + (r1 - r0) * min((x - 45.0) / 105.0, 1.0)
    rise = DR_H + ST["gap"] + rx - Cb.z
    d = Vector((d.x, d.y, -rise / s)).normalized()
    B = Cb - d * ST_AX
    G = B + d * ST["grip"]
    a = Vector((d.y, -d.x, 0.0)).normalized()
    return B, Cb, d, G, a


STICKS = {"StickL": stick_place(-1), "StickR": stick_place(1)}


def drum_stick(name):
    B, _, d, _, _ = STICKS[name]

    def build(hi):
        s = Shape()
        M = T(Vector(tuple(mm(c) for c in B))) @ Vector((0, 0, 1)).rotation_difference(d).to_matrix().to_4x4()
        s.lathe([(mm(a), mm(c)) for a, c in stick_rz(hi)], DR_STICK, segs(hi, 12), M)
        return s
    return build


DR_BD = mm(0.15)            # the look's bump distance: a height of 1 stands 0.15 mm proud


def dr_h(v):
    """A height in mm, in the bump's units."""
    return v / 0.15


def drum_look(L, f):
    nb = L.nb
    xm, ym, zm = nb.mul(L.x, K.STUD_MM), nb.mul(L.y, K.STUD_MM), nb.mul(L.z, K.STUD_MM)

    def sq(v):
        return nb.mul(v, v)

    def bell(d, at, w):
        return nb.mul(nb.ss(d, at - w, at), nb.sub(1.0, nb.ss(d, at, at + w)))

    def within(d, r, soft=0.16):
        return nb.sub(1.0, nb.ss(d, r - soft, r + soft))

    def hyp(a, b):
        return nb.math("SQRT", nb.add(sq(a), sq(b)))

    def dist3(p):
        return nb.math("SQRT", nb.add(nb.add(sq(nb.sub(xm, p.x)), sq(nb.sub(ym, p.y))), sq(nb.sub(zm, p.z))))

    shell, floor, hoop = L.k(DR_SHELL), L.k(DR_FLOOR), L.k(DR_HOOP)
    cord, head, stick, grom = L.k(DR_CORD), L.k(DR_HEAD), L.k(DR_STICK), L.k(DR_GROM)
    th = nb.math("ARCTAN2", ym, xm)
    step = math.pi / DR_N

    def local(phase):
        """Radians from the nearest of the n repeats that start at `phase` (degrees)."""
        return nb.math("WRAP", nb.sub(th, math.radians(phase)), step, -step)

    lo_z, hi_z = HP["h"], DR_H - HP["h"]

    # the shell: deep blue litho ink on tinplate under a glossy lacquer
    BLUE = nb.tint(hexc("#1D3784"), nb.mr(L.noise(18.0, 21, detail=3), 0.3, 0.7, 0.9, 1.07))
    C = Coat(L, BLUE, nb.mr(L.noise(60.0, 22, detail=2), 0.3, 0.7, 0.24, 0.34), 0.0)
    ru, rv = DR["register"]
    # in each V opening upward a cream star ringed by a fine gold line; at the back our maker's
    # mark instead: a cream oval plate, a red line round it, a red star
    us = nb.mul(local(BOT0), DR_R)
    zs = hi_z - 19.0
    dv = nb.sub(zm, zs)
    ds = hyp(us, dv)
    ph = nb.math("ARCTAN2", us, dv)
    lobe = nb.pw(nb.add(0.5, nb.mul(nb.math("COSINE", nb.mul(ph, 5.0)), 0.5)), 2.4)
    star_r = nb.mul(nb.add(0.38, nb.mul(lobe, 0.62)), DR["star"])
    back = nb.mul(nb.sub(1.0, nb.ss(nb.absf(xm), 22.0, 26.0)), nb.ss(ym, 30.0, 40.0))
    front = nb.mul(shell, nb.sub(1.0, back))
    star = nb.mul(front, within(nb.sub(ds, star_r), 0.0, 0.14))
    gold = nb.mul(front, bell(nb.sub(ds, star_r), 1.25, 0.3))
    # the cream ink gone faintly yellow with age, more in some places than others
    CREAM = nb.tint(nb.mixc(nb.ss(L.noise(5.0, 20, detail=3), 0.35, 0.75), hexc("#EFE3C2"), hexc("#E4CF9C")),
                    nb.mr(L.noise(90.0, 23, detail=2), 0.3, 0.7, 0.95, 1.03))
    RED = hexc("#C02A20")
    GOLD = hexc("#C7A042")
    C.paint(gold, GOLD, 0.3, 0.55)
    C.paint(star, CREAM, 0.3, 0.0)
    mk = DR["mark"]
    e = hyp(nb.mul(us, 1.0 / mk["r"][0]), nb.mul(dv, 1.0 / mk["r"][1]))
    plate = nb.mul(nb.mul(shell, back), within(e, 1.0, 0.02))
    C.paint(plate, CREAM, 0.3, 0.0)
    C.paint(nb.mul(nb.mul(shell, back), bell(e, 0.985, 0.075)), GOLD, 0.3, 0.55)
    eu = hyp(nb.mul(nb.sub(us, ru), 1.0 / mk["r"][0]), nb.mul(nb.sub(dv, rv), 1.0 / mk["r"][1]))
    C.paint(nb.mul(nb.mul(shell, back), bell(eu, 0.8, 0.045)), RED, 0.3, 0.0)
    ds_r = hyp(nb.sub(us, ru), nb.sub(dv, rv))
    ph_r = nb.math("ARCTAN2", nb.sub(us, ru), nb.sub(dv, rv))
    lobe_r = nb.pw(nb.add(0.5, nb.mul(nb.math("COSINE", nb.mul(ph_r, 5.0)), 0.5)), 2.4)
    mstar = within(nb.sub(ds_r, nb.mul(nb.add(0.38, nb.mul(lobe_r, 0.62)), mk["star"])), 0.0, 0.1)
    C.paint(nb.mul(nb.mul(shell, back), mstar), RED, 0.3, 0.0)
    # in each V opening downward a red roundel: red, a cream ring, a red middle; the red printed
    # a hair off the cream, as a real litho's colours are
    ur = nb.mul(local(TOP0), DR_R)
    zr = lo_z + 19.0
    o, ring_o, ring_i = DR["roundel"]
    dr_ = hyp(nb.sub(ur, ru), nb.sub(zm, zr + rv))
    dc = hyp(ur, nb.sub(zm, zr))
    C.paint(nb.mul(shell, within(dr_, o)), RED, 0.3, 0.0)
    C.paint(nb.mul(shell, nb.mul(within(dc, ring_o), nb.sub(1.0, within(dc, ring_i)))), CREAM, 0.3, 0.0)
    # a cream line round the shell near each hoop
    sw = DR["stripe"]
    for zz in (lo_z + sw[0], hi_z - sw[0]):
        C.paint(nb.mul(shell, nb.band(zm, zz - sw[1] / 2, zz + sw[1] / 2, 0.12)), CREAM, 0.3, 0.0)
    # knocked about: a shallow dent low on the front right, its ink crazed at the rim
    dent = dist3(cyl(DR_R, -58.0, 40.0))
    C.paint(nb.mul(shell, nb.sub(1.0, nb.ss(dent, 2.0, 11.0))), height=dr_h(-0.7))
    craze = nb.mul(shell, bell(dent, 8.5, 2.5))
    C.paint(nb.mul(craze, nb.ss(L.noise(260.0, 24, detail=3), 0.6, 0.66)), hexc("#C6C0B0"), 0.3, 0.8)
    # rubbed where it's been dragged and carried: the ink thinned, here and there worn to tin
    # most low down, where it's been pushed along the floor, and at the front, where a kid's
    # knees and belt rubbed it while they marched
    low = nb.sub(1.0, nb.ss(zm, 18.0, 62.0))
    fore = nb.ss(nb.sub(0.0, ym), 0.0, 70.0)
    where = nb.add(nb.add(0.2, nb.mul(low, 0.6)), nb.mul(fore, 0.45), clamp=True)
    rub = nb.mul(shell, nb.mul(nb.ss(L.noise(9.0, 25, detail=4, rough=0.6), 0.46, 0.68), where))
    C.paint(nb.mul(rub, 0.62), hexc("#56688F"), 0.38)
    C.paint(nb.mul(rub, nb.ss(L.noise(70.0, 26, detail=3), 0.58, 0.66)), hexc("#C2BDAE"), 0.3, 0.85)
    # scratches round the drum from being dragged, a few bright to the tin at their cores
    sn = L.noise(900.0, 27, stretch=(0.04, 0.04, 1.0), detail=2)
    scr = nb.mul(nb.mul(shell, nb.ss(sn, 0.71, 0.75)), nb.add(0.35, nb.mul(where, 0.65), clamp=True))
    C.paint(nb.mul(scr, 0.75), hexc("#8D93A6"), 0.32, 0.4)
    C.paint(nb.mul(nb.mul(shell, nb.ss(sn, 0.765, 0.79)), where), hexc("#BDB9AC"), 0.3, 0.85)
    # the tin bottom: dull tinplate, freckled with rust
    C.paint(floor, nb.tint(hexc("#B8B3A4"), nb.mr(L.noise(30.0, 28, detail=3), 0.3, 0.7, 0.85, 1.05)), 0.38, 0.85)
    C.paint(nb.mul(floor, nb.ss(L.noise(40.0, 29, detail=4), 0.62, 0.7)), hexc("#7A4A2A"), 0.8, 0.1)

    # the hoops: red enamel on rolled tin, glossy, chipped on the rolls' crests, the top rim
    # nicked at the front where the sticks catch it, the foot rusting where it's chipped
    HRED = nb.tint(hexc("#B4231B"), nb.mr(L.noise(40.0, 31, detail=2), 0.3, 0.7, 0.92, 1.06))
    C.paint(hoop, HRED, 0.3, 0.0)
    ub = DR_B
    zt, zb = DR_H - CD["hole"], CD["hole"]
    dt = hyp(nb.mul(local(TOP0), ub), nb.sub(zm, zt))
    db = hyp(nb.mul(local(BOT0), ub), nb.sub(zm, zb))
    dh = nb.mn(dt, db)
    gi, go, gh = CD["grommet"]
    C.paint(nb.mul(hoop, bell(dh, go + 0.2, 0.45)), hexc("#5A1611"), 0.5)     # grime round the grommet
    C.paint(nb.mul(hoop, within(dh, gi, 0.1)), hexc("#120F0C"), 0.85, 0.0)   # the hole, dark
    C.paint(grom, nb.tint(hexc("#CFC8B4"), nb.mr(L.noise(200.0, 32, detail=2), 0.3, 0.7, 0.8, 1.05)), 0.26, 0.9)
    C.paint(nb.mul(grom, nb.ss(L.noise(150.0, 33, detail=3), 0.58, 0.66)), hexc("#6E5338"), 0.6, 0.3)
    # two fine grooves pressed round each hoop's band, just in from its rolls, broken round
    # every grommet; grime settles in them
    rr = hyp(xm, ym)
    band_lo, band_hi = DR_H - HP["h"] + 2.0 * HP["roll"] + 0.5, DR_H - 2.0 * DR_RT - 0.3
    grv = None
    for zz in (band_lo + 0.8, band_hi - 0.7, DR_H - band_lo - 0.8, DR_H - band_hi + 0.7):
        g = bell(zm, zz, 0.5)
        grv = g if grv is None else nb.add(grv, g, clamp=True)
    grv = nb.mul(nb.mul(nb.mul(hoop, grv), nb.ss(rr, DR_B - 0.7, DR_B - 0.25)), nb.ss(dh, go + 0.35, go + 0.8))
    C.paint(nb.mul(grv, 0.8), hexc("#661310"), 0.45, None, dr_h(-0.24))
    # the top rim nicked at the front where the sticks catch it: a few bites in clusters, big
    # and small, rusting at their cores; the enamel otherwise chipped in patches, not evenly
    top_roll = nb.mul(hoop, nb.ss(zm, DR_H - 2.6, DR_H - 1.4))
    foot = nb.sub(1.0, nb.ss(zm, 3.0, 8.0))
    nn = L.noise(45.0, 34, detail=4)
    cluster = nb.ss(L.noise(7.0, 37, detail=2), 0.48, 0.6)
    nick = nb.mul(nb.mul(top_roll, nb.ss(nb.sub(0.0, ym), 10.0, 60.0)),
                  nb.mx(nb.mul(nb.ss(nn, 0.6, 0.65), cluster), nb.ss(L.noise(16.0, 38, detail=3), 0.72, 0.75)))
    patchy = nb.add(nb.ss(L.noise(6.0, 39, detail=2), 0.44, 0.52), foot, clamp=True)
    chips = C.enamel_wear(nb.mul(hoop, patchy), hexc("#C2BDAE"), 35, 1.0)
    C.paint(nick, hexc("#BDB8A9"), 0.4, 0.85, dr_h(-0.08))
    C.paint(nb.mul(nick, nb.ss(L.noise(110.0, 35, detail=2), 0.5, 0.62)), hexc("#8A4A26"), 0.8, 0.1)
    C.paint(nb.mul(chips, nb.add(nb.mul(foot, 0.9), 0.25, clamp=True)), hexc("#7B4528"), 0.8, 0.1)
    C.paint(nb.mul(nb.mul(hoop, foot), nb.ss(L.noise(25.0, 36, detail=4), 0.5, 0.64)), hexc("#5E2A1A"), 0.6)

    # the cord: white cotton gone ivory, dirtier toward the holes where hands pull it
    CORD = nb.tint(hexc("#ECE6D5"), nb.mr(L.noise(300.0, 41, detail=3), 0.3, 0.7, 0.88, 1.04))
    C.paint(cord, CORD, 0.93, 0.0, nb.mul(L.noise(1400.0, 42, detail=2), dr_h(0.05)))
    near = nb.mul(cord, nb.sub(1.0, nb.ss(dh, 3.0, 14.0)))
    C.paint(nb.mul(near, 0.55), hexc("#A79C84"), 0.95)
    C.paint(nb.mul(nb.mul(cord, nb.ss(L.noise(50.0, 43, detail=3), 0.55, 0.7)), 0.4), hexc("#B9AE94"), 0.95)

    # the calfskin head: cream hide, mottled and veined, darker where it rolls over the edge;
    # scuffed grey where the beads have struck it for years, with little dents
    rh = rr
    mott = L.noise(14.0, 51, detail=4, rough=0.6)
    SKIN = nb.tint(nb.mixc(nb.ss(mott, 0.36, 0.68), hexc("#EEDDB6"), hexc("#D1B381")),
                   nb.mr(L.noise(120.0, 52, detail=3), 0.3, 0.7, 0.94, 1.04))
    C.paint(head, SKIN, 0.6, 0.0, nb.mul(L.noise(700.0, 53, detail=3), dr_h(0.03)))
    # broad clouds where the hide is thicker: darker, warmer
    C.paint(nb.mul(nb.mul(head, nb.ss(L.noise(4.0, 57, detail=3, rough=0.55), 0.52, 0.72)), 0.5),
            hexc("#C6A46F"), 0.58)
    vein = bell(L.noise(5.0, 54, detail=3, distortion=0.4), 0.5, 0.009)
    C.paint(nb.mul(nb.mul(head, vein), 0.3), hexc("#C2A271"), 0.6)
    # the calf's spine: a faint darker streak right across the hide, a little wavy, in front of
    # where the sticks land
    sa = math.radians(14.0)
    across = nb.add(nb.add(nb.mul(xm, -math.sin(sa)), nb.mul(ym, math.cos(sa))), 16.0)
    wob = nb.mul(nb.sub(L.noise(3.0, 58, detail=2), 0.5), 9.0)
    spine = nb.sub(1.0, nb.ss(nb.absf(nb.add(across, wob)), 0.8, 4.5))
    C.paint(nb.mul(nb.mul(head, spine), 0.38), hexc("#BC9A66"), 0.56)
    C.paint(nb.mul(head, nb.ss(rh, DR_R * 0.84, DR_R * 0.97)), hexc("#C9AF80"), 0.62)
    # where the beads land: years of hits have worn a grey-brown patch, polished a little,
    # pocked with small round dents; a fainter played-on zone between the two
    strike, core = None, None
    for name in ("StickL", "StickR"):
        _, Cb, _, _, _ = STICKS[name]
        dd = hyp(nb.sub(xm, Cb.x), nb.sub(ym, Cb.y - 4.0))
        # hits wander toward the middle: the worn patch spreads out in front of the bead
        w = Vector((Cb.x, Cb.y, 0.0)) * (1.0 - 10.0 / math.hypot(Cb.x, Cb.y))
        dw = hyp(nb.sub(xm, w.x), nb.sub(ym, w.y))
        m, c = nb.sub(1.0, nb.ss(dw, 6.0, 21.0)), nb.sub(1.0, nb.ss(dd, 2.0, 11.0))
        strike = m if strike is None else nb.add(strike, m, clamp=True)
        core = c if core is None else nb.add(core, c, clamp=True)
    played = nb.sub(1.0, nb.ss(hyp(xm, nb.sub(ym, 18.0)), 12.0, 42.0))
    C.paint(nb.mul(nb.mul(head, played), 0.3), hexc("#B39A74"), 0.55)
    sm = nb.mul(head, strike)
    C.paint(nb.mul(sm, nb.mr(L.noise(35.0, 55, detail=4), 0.3, 0.7, 0.7, 1.0)), hexc("#857258"), 0.48)
    C.paint(nb.mul(nb.mul(head, core), 0.45), hexc("#6F5F4A"), 0.46)
    pock = nb.sub(1.0, nb.ss(nb.voronoi(L.vec(s=59.0), 85.0), 0.1, 0.32))
    dents = nb.mul(nb.mul(nb.mul(head, core), pock), nb.ss(L.noise(60.0, 56, detail=2), 0.42, 0.55))
    C.paint(dents, hexc("#76654E"), 0.52, 0.0, dr_h(-0.3))

    # the sticks: turned beech, lacquered; grey and dented at the beads, darker where held
    grain = L.noise(55.0, 61, stretch=(1.0, 0.035, 1.0), detail=4)
    WOOD = nb.tint(nb.mixc(nb.ss(grain, 0.34, 0.72), hexc("#E6BF86"), hexc("#B9844C")),
                   nb.mr(L.noise(300.0, 62, stretch=(1.0, 0.05, 1.0), detail=2), 0.3, 0.7, 0.92, 1.05))
    C.paint(stick, WOOD, 0.42, 0.0, nb.mul(grain, dr_h(0.04)))
    # fine dark grain lines running down the turned beech
    fine = bell(L.noise(150.0, 64, stretch=(1.0, 0.02, 1.0), detail=3), 0.5, 0.03)
    C.paint(nb.mul(nb.mul(stick, fine), 0.5), hexc("#9A673A"), 0.44)
    for name in ("StickL", "StickR"):
        B, Cb, _, _, _ = STICKS[name]
        tip = nb.mul(stick, nb.sub(1.0, nb.ss(dist3(Cb), ST["bead"] + 0.8, ST["bead"] + 4.0)))
        C.paint(nb.mul(tip, 0.82), hexc("#9C8C74"), 0.6)
        C.paint(nb.mul(tip, nb.ss(L.noise(260.0, 63, detail=2), 0.64, 0.7)), hexc("#7A6A55"), 0.62, 0.0, dr_h(-0.12))
        held = nb.mul(stick, nb.sub(1.0, nb.ss(dist3(B), 30.0, 70.0)))
        C.paint(nb.mul(held, 0.55), hexc("#A47F50"), 0.3)
    C.finish(f.dust, grime=0.5)
    return C.surface(bump_dist=DR_BD, bump=1.0)


# --- how it plays ---------------------------------------------------------------------------------

def drum_bang():
    """Left, right, left, right, then both: each stick lifts, snaps down onto the head (the game
    plays a bang here), bounces off it twice and settles; the head dips and shivers back; the
    drum gives a little under each blow. Returns the duration, the tracks and the hit times."""
    first, beat, n = BG["first"], BG["beat"], BG["hits"]
    lift, lift_t = BG["lift"]
    snap = BG["snap"]
    bup, t_up, t_dn = BG["bounce"]
    dbl = BG["double"]
    reach = ST_AX - ST["grip"]                       # grip to bead (mm)
    sticks = {"StickL": [(0.0, 0.0)], "StickR": [(0.0, 0.0)]}
    hits = []
    for i in range(n):
        hits.append((first + i * beat, ("StickL", "StickR")[i % 2:i % 2 + 1], False))
    hits.append((hits[-1][0] + dbl["gap"], ("StickL", "StickR"), True))
    head = [(0.0, 0.0)]
    body = [(0.0, 0.0)]
    for t, who, big in hits:
        up, ut, bo = (dbl["lift"][0], dbl["lift"][1], dbl["bounce"]) if big else (lift, lift_t, bup)
        dip = BG["head"][1 if big else 0]
        dip_deg = math.degrees(math.atan(dip / reach))
        for name in who:
            k = sticks[name]
            start = max(t - snap - ut, k[-1][0] + 0.01)
            k += [(round(start, 4), 0.0),
                  (round(t - snap, 4), up, "Sine", "Out"),            # up, slowing into the top
                  (round(t, 4), -dip_deg, "Quad", "In"),              # down, quicker and quicker
                  (round(t + t_up, 4), bo, "Quad", "Out"),            # off the head
                  (round(t + t_up + t_dn, 4), 0.0, "Quad", "In"),     # back onto it
                  (round(t + t_up + t_dn + 0.035, 4), bo * 0.2, "Quad", "Out"),
                  (round(t + t_up + t_dn + 0.07, 4), 0.0, "Quad", "In")]
        sv = BG["shiver"]
        head += [(round(t - 0.012, 4), 0.0), (round(t + 0.012, 4), mm(-dip), "Quad", "Out"),
                 (round(t + 0.045, 4), mm(dip * sv[0])), (round(t + 0.075, 4), mm(-dip * sv[1])),
                 (round(t + 0.105, 4), mm(dip * sv[2])), (round(t + 0.14, 4), 0.0)]
        j = BG["jolt"][1 if big else 0]
        body += [(round(t - 0.01, 4), 0.0), (round(t + 0.03, 4), mm(-j), "Quad", "Out"),
                 (round(t + 0.16, 4), 0.0, "Sine", "InOut")]
    tracks = [(name, "turn", k) for name, k in sticks.items()]
    tracks += [("Head", "move", head), ("Body", "z", body)]
    return BG["end"], tracks, [round(t, 3) for t, _, _ in hits]


DB_DUR, DB_TRACKS, DB_HITS = drum_bang()


def stud(v):
    return tuple(mm(c) for c in v)


TOY_DRUM = kit.Find(
    "ToyDrum",
    [kit.Part("Body", drum_body),
     kit.Part("Head", drum_head, (0.0, 0.0, mm(HEAD_Z)), "Body", (0.0, 0.0, 1.0)),
     kit.Part("StickL", drum_stick("StickL"), stud(STICKS["StickL"][3]), "Body", tuple(STICKS["StickL"][4])),
     kit.Part("StickR", drum_stick("StickR"), stud(STICKS["StickR"][3]), "Body", tuple(STICKS["StickR"][4]))],
    drum_look,
    motions={
        # banged by a kid: left, right, left, right, then both together, the loud one (the game
        # plays a bang at each of DB_HITS)
        "Bang": dict(duration=DB_DUR, focus=(0.0, mm(-10.0), mm(HEAD_Z + 25.0)), distance=0.75,
                     view=(-1.1, -2.0, 1.3), drop=0.0, tracks=DB_TRACKS),
    },
    dust=DR["dust"], seed=DR["seed"], texels=600,
)


FINDS = [CYMBAL_MONKEY, JACK_IN_THE_BOX, CHATTERING_TEETH, WALKING_ROBOT, WINDUP_MOUSE, TIN_BIRD,
         SIREN_CAR, RUBBER_DUCK, KAZOO, TOY_DRUM]

if __name__ == "__main__":
    kit.main("Windups", HERE, FINDS)
