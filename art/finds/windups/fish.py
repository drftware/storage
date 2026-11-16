"""The singing fish plaque (F-04i): our own channel catfish on a varnished oak board.

A slate-blue latex catfish, speckled, with long whiskers, curved off an arched, routed oak board
that leans back on a fold-out leg; a red button lower right, a brass plate with an engraved fish
(no words) under it, a speaker grille lower left. Press: the tail flaps twice, the head swings out
to face you, the mouth sings two bars, the head snaps back and the tail gives a last flap.

Built in the plaque's own frame (mm: X across, the board's face at Y = 0 with the viewer at -Y,
Z up the board from its foot), then leaned back and set on the floor by TO. The fish is lofted
along X from its tail's tip; `w` is mm from there. Its names all start fs_ / FS_ (build.py's
note: a new find's names must not replace an older find's).
"""

import math

import bmesh
from mathutils import Matrix, Vector

import kit
import spec as K
from look import Coat, hexc
from shapes import Shape

mm = K.mm
FI = K.FISH
SG = K.SING

(FS_WOOD, FS_FACE, FS_BACK, FS_BOX, FS_DOOR, FS_BRASS, FS_BEZEL, FS_BUTTON, FS_SKIN, FS_JAW,
 FS_KNUCK, FS_FIN, FS_LIP, FS_MOUTH, FS_TONGUE, FS_EYE, FS_WHISK, FS_CHIN) = range(113, 131)

FS_LEAN = math.radians(FI["lean"])
BW, BH, BT = FI["board"]
FS_Z0 = FI["ogee"][1][1] * math.sin(FS_LEAN)          # the back of the foot's edge on the floor
LEAN_M = Matrix.Translation((0.0, 0.0, FS_Z0)) @ Matrix.Rotation(-FS_LEAN, 4, "X")
TO = Matrix.Scale(1.0 / K.STUD_MM, 4) @ LEAN_M       # plaque mm -> the find's frame in studs
FB = Matrix(((1, 0, 0, 0), (0, 0, -1, 0), (0, 1, 0, 0), (0, 0, 0, 1)))   # a lathe's Z out of the face
# the same lean for a mesh already in studs: the kit unwraps a merged mesh and a lathe from their
# own coordinates, so everything is handed over in studs (in mm its islands were 254 times too big
# and the packer squeezed the fish's skin to nothing)
TOS = Matrix.Translation((0.0, 0.0, FS_Z0 / K.STUD_MM)) @ Matrix.Rotation(-FS_LEAN, 4, "X")


def fs_merge(s, bm, kind):
    """Merge a plaque-mm bmesh, scaled to studs first so it unwraps at the true size."""
    bmesh.ops.scale(bm, vec=Vector((1.0 / K.STUD_MM,) * 3), verts=bm.verts)
    s.merge(bm, kind, TOS)


def fs_lathe(s, prof, kind, segs, M):
    """A lathe from a profile in mm, M taking mm to the find's frame; unwrapped in studs."""
    s.lathe([(r / K.STUD_MM, z / K.STUD_MM) for r, z in prof], kind, segs,
            M @ Matrix.Scale(K.STUD_MM, 4))


def fs_segs(hi, n):
    return n * 2 if hi else n


def Ls(p):
    """A plaque point (mm) in the find's frame (studs), as a tuple."""
    return tuple(TO @ Vector(p))


def Ld(v):
    """A plaque direction in the find's frame."""
    return tuple((LEAN_M.to_3x3() @ Vector(v)).normalized())


def ss01(t):
    t = min(max(t, 0.0), 1.0)
    return t * t * (3 - 2 * t)


# --- the board -----------------------------------------------------------------------------------

def fs_outline(n):
    """The board's outline in (x, z), n points evenly round, anticlockwise from the right, with
    each point's outward normal: a superellipse, square below and arched above."""
    nb_, nt, rise, foot = FI["arch"]
    a = BW / 2
    dense = []
    for i in range(2400):
        t = 2 * math.pi * i / 2400
        c, s = math.cos(t), math.sin(t)
        e = 2.0 / (nb_ if s < 0 else nt)
        dense.append(Vector((math.copysign(abs(c) ** e, c) * a,
                             foot + math.copysign(abs(s) ** e, s) * (rise if s > 0 else foot))))
    acc = [0.0]
    for i in range(len(dense)):
        acc.append(acc[-1] + (dense[(i + 1) % len(dense)] - dense[i]).length)
    out, k = [], 0
    for j in range(n):
        target = acc[-1] * j / n
        while acc[k + 1] < target:
            k += 1
        f = (target - acc[k]) / max(acc[k + 1] - acc[k], 1e-9)
        out.append(dense[k].lerp(dense[(k + 1) % len(dense)], f))
    res = []
    for j in range(n):
        tng = out[(j + 1) % n] - out[j - 1]
        res.append((out[j], Vector((tng.y, -tng.x)).normalized()))
    return res


def fs_panel(s, rings, centre, kind, toward_front):
    """A flat face filled from its outer ring (anticlockwise seen from the front) in to a point."""
    bm = bmesh.new()
    R = [[bm.verts.new(p) for p in ring] for ring in rings]
    c = bm.verts.new(centre)
    for a, b in zip(R, R[1:]):
        n = len(a)
        for j in range(n):
            f = (a[j], a[(j + 1) % n], b[(j + 1) % n], b[j])
            bm.faces.new(f if toward_front else tuple(reversed(f)))
    last = R[-1]
    for j in range(len(last)):
        f = (last[j], last[(j + 1) % len(last)], c)
        bm.faces.new(f if toward_front else tuple(reversed(f)))
    fs_merge(s, bm, kind)
    bm.free()


def fs_board(s, hi):
    n = fs_segs(hi, 72)
    ol = fs_outline(n)
    rings = [[Ls((p.x - d * q.x, yb, p.y - d * q.y)) for p, q in ol] for d, yb in FI["ogee"]]
    s.loft(rings, FS_WOOD, split=4)
    cx, cz = 0.0, FI["arch"][3] + 10.0

    def inset(d, y):
        return [Vector((p.x - d * q.x, y, p.y - d * q.y)) for p, q in ol]

    def shrink(ring, k, y):
        return [Vector((cx + (p.x - cx) * k, y, cz + (p.z - cz) * k)) for p in ring]

    d0 = FI["ogee"][-1][0]
    face = [inset(d0, 0.0), inset(d0 + 6.0, 0.0), inset(d0 + 14.0, 0.0)]
    face += [shrink(face[-1], k, 0.0) for k in (0.8, 0.55, 0.3)]
    fs_panel(s, face, (cx, 0.0, cz), FS_FACE, True)
    d1, y1 = FI["ogee"][0]
    back = [inset(d1, y1), inset(d1 + 8.0, y1)]
    back += [shrink(back[-1], k, y1) for k in (0.75, 0.45)]
    fs_panel(s, back, (cx, y1, cz), FS_BACK, False)


def fs_back(s, hi):
    """The black battery and speaker box, its door, and the fold-out leg on its hinge."""
    w, h, d, zc = FI["box"]
    y0 = BT - 1.0
    s.box((-w / 2, y0, zc - h / 2), (w / 2, y0 + d, zc + h / 2), FS_BOX, chamfer=5.0, segs=2, M=TO)
    s.box((-42.0, y0 + d - 0.6, zc - 40.0), (42.0, y0 + d + 1.0, zc + 6.0), FS_DOOR, chamfer=1.0,
          segs=1, M=TO)
    lw, lt, lz = FI["leg"]
    s.box((-13.0, y0 + d - 1.0, lz - 6.0), (13.0, y0 + d + 5.0, lz + 6.0), FS_BOX, chamfer=1.5,
          segs=1, M=TO)
    hf = LEAN_M @ Vector((0.0, y0 + d + 3.0, lz))
    foot = Vector((0.0, hf.y + 0.42 * hf.z, 0.0))
    zv = (foot - hf).normalized()
    xv = Vector((1.0, 0.0, 0.0))
    yv = zv.cross(xv)
    R = Matrix((xv, yv, zv)).transposed().to_4x4()
    M = Matrix.Scale(1.0 / K.STUD_MM, 4) @ Matrix.Translation(hf) @ R
    L = (foot - hf).length
    s.box((-lw / 2, -lt / 2, -3.0), (lw / 2, lt / 2, L - 1.2), FS_BOX, chamfer=1.2, segs=1, M=M)
    # its rubber foot, flat on the floor
    s.box((-lw / 2 - 1.0, -4.0, L - 5.0), (lw / 2 + 1.0, 4.0, L - 0.4), FS_BEZEL, chamfer=1.0,
          segs=1, M=M)


def fs_front(s, hi):
    """The brass plate and its screws, the button's bezel."""
    pl = FI["plate"]
    px, pz = pl["at"]
    a, b = pl["half"]
    t = pl["t"]
    n = fs_segs(hi, 48)

    def ell(k, y, ina=0.0):
        return [(px + (a - ina) * k * math.cos(2 * math.pi * j / n), y,
                 pz + (b - ina) * k * math.sin(2 * math.pi * j / n)) for j in range(n)]

    s.loft([[Ls(p) for p in ell(1.0, y, i)] for y, i in ((0.4, 0.0), (-t + 0.4, 0.0), (-t, 0.6))],
           FS_BRASS)
    top = [[Vector(p) for p in ell(k, -t, 0.6)] for k in (1.0, 0.93, 0.75, 0.5, 0.25)]
    fs_panel(s, top, (px, -t, pz), FS_BRASS, True)
    for sx in (-1, 1):
        s.lathe([(mm(1.9), mm(-0.3)), (mm(1.9), mm(0.25)), (mm(1.5), mm(0.75)), (mm(0.8), mm(1.0)),
                 (0.0, mm(1.05))], FS_BRASS, fs_segs(hi, 10),
                TO @ Matrix.Translation((px + sx * (a - 6.5), -t, pz)) @ FB @ Matrix.Scale(K.STUD_MM, 4))
    bt = FI["button"]
    bx, bz = bt["at"]
    ro, hb = bt["bezel"]
    r = bt["r"]
    prof = [(ro, -0.4), (ro, hb * 0.5), (ro - 0.9, hb * 0.92), (ro - 2.3, hb), (r + 1.0, hb * 0.85),
            (r + 0.6, hb * 0.4), (r + 0.6, -3.0)]
    fs_lathe(s, prof, FS_BEZEL, fs_segs(hi, 24), TO @ Matrix.Translation((bx, 0.0, bz)) @ FB)


def fs_plaque(hi):
    s = Shape()
    fs_board(s, hi)
    fs_back(s, hi)
    fs_front(s, hi)
    return s


def fs_button(hi):
    bt = FI["button"]
    bx, bz = bt["at"]
    r, dome = bt["r"], bt["dome"]
    hb = bt["bezel"][1]
    prof = [(r, -3.0), (r, hb - 1.2), (r * 0.97, hb + dome * 0.32), (r * 0.86, hb + dome * 0.62),
            (r * 0.66, hb + dome * 0.84), (r * 0.36, hb + dome * 0.97), (0.0, hb + dome)]
    s = Shape()
    fs_lathe(s, prof, FS_BUTTON, fs_segs(hi, 24), TO @ Matrix.Translation((bx, 0.0, bz)) @ FB)
    return s


# --- the fish ------------------------------------------------------------------------------------

ROWS = FI["body"]
X0, FZ = FI["x0"], FI["z"]
P_B, P_F, Q = 0.5, 0.82, 0.88       # the board side squarer (flat against it), the front fuller
WK, KH, KR = FI["knuckle"]
WH, MZ, WJ = FI["mouth"]


def fs_arch(w):
    a0, a1 = FI["arch_up"]
    return a0 * ((150.0 - w) / 150.0) ** 2 if w < 150.0 else a1 * ((w - 150.0) / 141.5) ** 2


def fs_row(w):
    """(bottom, top, half thick to you, to the board, off the board) at w, Catmull-Rom."""
    ws = [r[0] for r in ROWS]
    w = min(max(w, ws[0]), ws[-1])
    i = max(j for j in range(len(ws) - 1) if ws[j] <= w) if w < ws[-1] else len(ws) - 2
    t = (w - ws[i]) / (ws[i + 1] - ws[i])
    p0, p1, p2, p3 = (ROWS[max(i - 1, 0)], ROWS[i], ROWS[i + 1], ROWS[min(i + 2, len(ROWS) - 1)])
    return tuple(0.5 * (2 * b + (c - a) * t + (2 * a - 5 * b + 4 * c - d) * t * t
                        + (3 * b - a - 3 * c + d) * t ** 3)
                 for a, b, c, d in zip(p0[1:], p1[1:], p2[1:], p3[1:]))


def fs_sec(w):
    zb, zt, tf, tb, lift = fs_row(w)
    return FZ + fs_arch(w) + (zt + zb) / 2, (zt - zb) / 2, -(lift + tb), tf, tb


def spw(c, p):
    return math.copysign(abs(c) ** p, c)


def fs_pt(w, phi, S=None):
    zc, h, yc, tf, tb = S or fs_sec(w)
    c, s = math.cos(phi), math.sin(phi)
    return Vector((X0 + w, yc + (tb * spw(c, P_B) if c > 0 else tf * spw(c, P_F)), zc + h * spw(s, Q)))


def fs_zm(w):
    return FZ + fs_arch(w) + MZ


def fs_beta(w, S):
    k = min(max((S[0] - fs_zm(w)) / S[1], 0.02), 0.97)
    return math.asin(k ** (1.0 / Q))


def fs_ymid(w):
    zc, h, yc, tf, tb = fs_sec(w)
    return yc - (tf - tb) / 2


def fs_side(w, z, front=True):
    """The fish's surface at w, height z, on the side toward you (or the board)."""
    S = fs_sec(w)
    k = min(max((z - S[0]) / S[1], -0.98), 0.98)
    a = math.asin(spw(k, 1.0 / Q))
    return fs_pt(w, math.pi - a if front else a, S)


def fs_body_ring(w, na, nb_):
    S = fs_sec(w)
    b = fs_beta(w, S)
    ring = [fs_pt(w, -b + (math.pi + 2 * b) * j / na, S) for j in range(na)]
    fe, be = fs_pt(w, math.pi + b, S), fs_pt(w, -b, S)
    km = ss01((w - WJ) / (WH - WJ))
    for k in range(nb_):
        e = fs_pt(w, math.pi + b + (math.pi - 2 * b) * k / nb_, S)
        ring.append(e.lerp(fe.lerp(be, k / nb_), km))
    return ring


def fs_ws(a, b, step, extra=()):
    n = max(1, int(math.ceil((b - a) / step)))
    return sorted(set([round(a + (b - a) * i / n, 3) for i in range(n + 1)] + list(extra)))


def fs_ell(s, c, r, kind, hi, lat=8, lon=16):
    """An ellipsoid round a plaque point c with radii r (mm), its poles up the board."""
    nl, nn = fs_segs(hi, lat), fs_segs(hi, lon)
    rings = [[Ls((c[0], c[1], c[2] - r[2]))]]
    for i in range(1, nl):
        a = math.pi * i / nl
        k = math.sin(a)
        rings.append([Ls((c[0] + r[0] * k * math.cos(2 * math.pi * j / nn),
                          c[1] + r[1] * k * math.sin(2 * math.pi * j / nn),
                          c[2] - r[2] * math.cos(a))) for j in range(nn)])
    rings.append([Ls((c[0], c[1], c[2] + r[2]))])
    s.loft(rings, kind)


def fs_fan(s, c, ring, n, tc, te, kind):
    """A thin fin: a plate fanned from c (inside the body) out to its outline, tc thick in the
    middle, te at the edge, offset both ways along n. Plaque mm."""
    bm = bmesh.new()
    n = Vector(n).normalized()
    c = Vector(c)
    ring = [Vector(p) for p in ring]
    m = len(ring)
    mid = [c.lerp(p, 0.55) for p in ring]
    tm = tc * 0.45 + te * 0.55
    sides = []
    for sg in (1, -1):
        ct = bm.verts.new(c + n * sg * tc / 2)
        md = [bm.verts.new(p + n * sg * tm / 2) for p in mid]
        ot = [bm.verts.new(p + n * sg * te / 2) for p in ring]
        sides.append((ct, md, ot))
    for ct, md, ot in sides:
        for j in range(m):
            k = (j + 1) % m
            bm.faces.new((ct, md[j], md[k]))
            bm.faces.new((md[j], ot[j], ot[k], md[k]))
    a, b = sides[0][2], sides[1][2]
    for j in range(m):
        k = (j + 1) % m
        bm.faces.new((a[j], b[j], b[k], a[k]))
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    fs_merge(s, bm, kind)
    bm.free()


def fs_whisker(s, root, offs, r0, r1, kind, hi, ymax=-1.5):
    pts = [Vector(root) + Vector(o) for o in offs]
    for p in pts:
        p.y = min(p.y, ymax)
    n = len(pts)
    s.tube([Ls(p) for p in pts], mm(r0), kind, fs_segs(hi, 6),
           radii=[mm(r0 + (r1 - r0) * i / (n - 1)) for i in range(n)])


def fs_top(w):
    zc, h = fs_sec(w)[:2]
    return zc + h


def fs_bot(w):
    zc, h = fs_sec(w)[:2]
    return zc - h


def fs_fins_body(s):
    # the dorsal fin, its stiff spine leading, swept back
    c = (X0 + 194.0, fs_sec(194.0)[2], fs_top(194.0) - 8.0)
    ring = [(X0 + w, fs_sec(w)[2], fs_top(w) + du) for w, du in
            ((211.0, -6.0), (210.0, 4.0), (206.0, 11.0), (201.0, 19.0), (196.0, 25.0), (192.5, 28.0),
             (189.5, 27.5), (186.5, 23.0), (183.0, 12.0), (179.0, 0.0), (178.0, -6.0))]
    fs_fan(s, c, ring, (0, 1, 0), 4.5, 1.0, FS_FIN)
    # the little fleshy adipose fin on the back, near the tail
    c = (X0 + 114.0, fs_sec(114.0)[2], fs_top(114.0) - 5.0)
    ring = [(X0 + w, fs_sec(w)[2], fs_top(w) + du) for w, du in
            ((124.0, -4.0), (123.0, 3.0), (118.0, 7.5), (111.0, 7.0), (106.0, 3.0), (104.0, -4.0))]
    fs_fan(s, c, ring, (0, 1, 0), 3.4, 1.6, FS_FIN)
    # the long anal fin under the belly, its edge rounded
    c = (X0 + 122.0, fs_sec(122.0)[2], fs_bot(122.0) + 6.0)
    ring = [(X0 + w, fs_sec(w)[2], fs_bot(w) + du) for w, du in
            ((93.0, 4.0), (94.0, -4.0), (100.0, -12.0), (112.0, -16.0), (128.0, -18.0),
             (142.0, -14.0), (149.0, -6.0), (151.0, 4.0))]
    fs_fan(s, c, ring, (0, 1, 0), 4.0, 1.0, FS_FIN)
    # a pelvic fin under the belly, angled out toward you
    yc = fs_sec(160.0)[2] - fs_sec(160.0)[3] * 0.45
    c = (X0 + 160.0, yc + 2.0, fs_bot(160.0) + 5.0)
    ring = [(X0 + w, yc - out, fs_bot(w) + du) for w, du, out in
            ((170.0, 3.0, 0.0), (167.0, -8.0, 3.0), (160.0, -14.0, 6.0), (153.0, -12.0, 6.0),
             (151.0, -4.0, 3.0), (153.0, 3.0, 0.0))]
    fs_fan(s, c, ring, (0, 0.9, 0.4), 3.6, 0.9, FS_FIN)
    # the pectoral fin behind the gill cover, lying back along the flank
    mid = FZ + fs_arch(215.0)
    ring = []
    for w, dz, out in ((229.0, -6.0, 0.0), (231.0, -14.0, 0.0), (222.0, -21.0, 3.0),
                       (206.0, -28.0, 6.0), (195.0, -29.0, 7.0), (192.0, -25.0, 7.0),
                       (200.0, -18.0, 5.0), (214.0, -11.0, 2.0), (225.0, -5.0, 0.0)):
        p = fs_side(w, mid + dz)
        ring.append((X0 + w, p.y - 1.4 - out, mid + dz))
    p = fs_side(226.0, mid - 10.0)
    fs_fan(s, (X0 + 226.0, p.y + 1.5, mid - 10.0), ring, (0, -1, 0.15), 4.0, 0.9, FS_FIN)


def fs_eye_at(front):
    w, dz, r = FI["eye"]
    p = fs_side(w, FZ + fs_arch(w) + dz, front)
    nrm = Vector((0.12, -1.0 if front else 1.0, 0.5)).normalized()
    return p - nrm * 0.9, nrm, r


def fs_lip_path(front_w, z_off, ws):
    """Along the mouth's edge: the board side's corner to the nose, round the front, and back
    along the side toward you to its corner."""
    board = [fs_pt(w, -fs_beta(w, fs_sec(w))) for w in ws]
    front = [fs_pt(w, math.pi + fs_beta(w, fs_sec(w))) for w in ws]
    be, fe = board[-1], front[-1]
    nose = []
    for k in range(1, 6):
        p = be.lerp(fe, k / 6)
        p.x = front_w + 1.6 * math.sin(math.pi * k / 6)
        nose.append(p)
    pts = board + nose + list(reversed(front))
    for p in pts:
        p.z += z_off
    return pts


def fs_body(hi):
    s = Shape()
    na, nb_ = fs_segs(hi, 22), fs_segs(hi, 10)
    snout = FI["snout"]
    end = ROWS[-1][0]
    ws = fs_ws(WK, end, 4.0 if hi else 8.0, (WJ, WH, WJ + 4.0, WH - 4.0))
    rings = [[Ls((X0 + WK - 4.0, fs_ymid(WK), fs_sec(WK)[0]))]]
    rings += [[Ls(p) for p in fs_body_ring(w, na, nb_)] for w in ws]
    zc = fs_sec(end)[0]
    rings.append([Ls((X0 + snout, fs_ymid(end), (zc + fs_zm(end)) / 2 + 3.0))])
    s.loft(rings, FS_SKIN, split=4)
    # the rubber ball the body and tail both turn on
    kc = FS_KNUCKLE
    fs_ell(s, kc, (KR, KR, KH), FS_KNUCK, hi)
    fs_fins_body(s)
    # the eyes: glossy domes, a touch bigger than life
    n = fs_segs(hi, 14)
    for front in (True, False):
        at, nrm, r = fs_eye_at(front)
        zl = nrm
        yl = (Vector((0, 0, 1)) - zl * zl.z).normalized()
        R = Matrix((yl.cross(zl), yl, zl)).transposed().to_4x4()
        prof = [(1.0, -2.0), (0.98, 0.0), (0.9, 0.3), (0.72, 0.52), (0.42, 0.68), (0.0, 0.73)]
        fs_lathe(s, [(r * a, r * b) for a, b in prof], FS_EYE, n, TO @ Matrix.Translation(at) @ R)
    # the upper lip, round the snout from corner to corner
    ul, ll = FI["lip"]
    pts = fs_lip_path(X0 + end - 0.6, ul * 0.35, fs_ws(WH, end, 4.0 if hi else 6.0))
    m = len(pts)
    s.tube([Ls(p) for p in pts], mm(ul), FS_LIP, fs_segs(hi, 8),
           radii=[mm(ul * (0.55 + 0.45 * math.sin(math.pi * i / (m - 1)) ** 0.5)) for i in range(m)])
    # whiskers: the two long ones from the snout's sides, sweeping back and down; two short
    # ones on top by the nostrils
    wl, wr = FI["whisker"]["long"]
    k = wl / 62.0
    for front in (True, False):
        sy = -1.0 if front else 1.0
        root = fs_side(270.0, fs_zm(270.0) + 3.5, front)
        root.y -= sy * 0.8
        drop = [(0, 0.0, 0), (-8, 5.0, -0.5), (-20, 10.0, -2.5), (-33, 13.0, -7), (-45, 14.0, -14),
                (-55, 13.0, -23), (-62, 12.0, -33)]
        offs = [(x * k, (y * sy * k) if front else min(y, 4.0), z * k) for x, y, z in drop]
        fs_whisker(s, root, offs, wr, 0.35, FS_WHISK, hi)
        nl, nr = FI["whisker"]["nose"]
        S = fs_sec(279.0)
        root = Vector((X0 + 279.0, S[2] + (-0.5 * S[3] if front else 0.4 * S[4]), fs_top(279.0) - 3.0))
        fs_whisker(s, root, [(0, 0, 0), (-2, sy * 1.0, 4), (-5, sy * 2.0, 8), (-9, sy * 2.0, nl - 0.5)],
                   nr, 0.4, FS_WHISK, hi)
    return s


def fs_jaw_ring(w, nl, nc):
    S = fs_sec(w)
    b = fs_beta(w, S)
    low = [fs_pt(w, math.pi + b + (math.pi - 2 * b) * j / nl, S) for j in range(nl + 1)]
    fe, be = low[0], low[-1]
    ring = low + [be.lerp(fe, k / nc) for k in range(1, nc)]
    if w < WH:
        cy, cz = fs_ymid(w), (S[0] - S[1] + fs_zm(w)) / 2
        ring = [Vector((p.x, cy + (p.y - cy) * 0.994, cz + (p.z - cz) * 0.994)) for p in ring]
    return ring


def fs_jaw(hi):
    s = Shape()
    nl, nc = fs_segs(hi, 10), fs_segs(hi, 6)
    chin = FI["chin"]
    last = chin - 2.5
    ws = fs_ws(WJ, last, 3.0 if hi else 6.0, (WH,))
    rings = [[Ls((X0 + WJ - 4.0, fs_ymid(WJ), (fs_bot(WJ) + fs_zm(WJ)) / 2))]]
    rings += [[Ls(p) for p in fs_jaw_ring(w, nl, nc)] for w in ws]
    rings.append([Ls((X0 + chin, fs_ymid(last), fs_zm(last) - 3.0))])
    s.loft(rings, FS_JAW, kinds=lambda j: FS_JAW if j < nl else FS_TONGUE, split=2)
    # the tongue, a soft pink pad on the mouth's floor
    w = 262.0
    fs_ell(s, (X0 + w, fs_ymid(w), fs_zm(w) + 0.2), (13.0, 8.0, 2.4), FS_TONGUE, hi, 6, 14)
    # the thick lower lip
    ul, ll = FI["lip"]
    pts = fs_lip_path(X0 + last - 0.6, -ll * 0.7, fs_ws(WH, last, 4.0 if hi else 6.0))
    m = len(pts)
    s.tube([Ls(p) for p in pts], mm(ll), FS_LIP, fs_segs(hi, 8),
           radii=[mm(ll * (0.5 + 0.5 * math.sin(math.pi * i / (m - 1)) ** 0.5)) for i in range(m)])
    # four pale chin whiskers hanging down and back
    cl, cr = FI["whisker"]["chin"]
    for w, f in ((278.0, -0.8), (283.5, -0.35), (283.5, 0.35), (278.0, 0.8)):
        S = fs_sec(w)
        half = S[3] if f < 0 else S[4]
        root = Vector((X0 + w, fs_ymid(w) + f * half, S[0] - S[1] * 0.9 + 1.0))
        k = cl / 19.0
        fs_whisker(s, root, [(0, 0, 0), (-3 * k, f * 2, -6 * k), (-8 * k, f * 4, -12 * k),
                             (-14 * k, f * 5, -16.5 * k), (-19 * k, f * 5, -19 * k)], cr, 0.3, FS_CHIN, hi)
    return s


TL = FI["tail"]


def fs_curl(p):
    """Bend a tail point out toward you, more the further behind `at` it is."""
    at = TL["at"]
    w = p.x - X0
    a = math.radians(TL["curl"]) * ss01((at - w) / 12.0)
    if a <= 0:
        return Vector(p)
    c = Vector((X0 + at, fs_ymid(at), p.z))
    d = Vector(p) - c
    return c + Vector((d.x * math.cos(a) - d.y * math.sin(a), d.x * math.sin(a) + d.y * math.cos(a), d.z))


def fs_tail(hi):
    s = Shape()
    n = fs_segs(hi, 22)
    w0 = ROWS[0][0]
    ws = fs_ws(w0, WK, 3.0 if hi else 6.0)
    rings = [[Ls(fs_curl(Vector((X0 + w0 - 3.0, fs_ymid(w0), fs_sec(w0)[0]))))]]
    for w in ws:
        S = fs_sec(w)
        rings.append([Ls(fs_curl(fs_pt(w, 2 * math.pi * j / n, S))) for j in range(n)])
    rings.append([Ls((X0 + WK + 4.0, fs_ymid(WK), fs_sec(WK)[0]))])
    s.loft(rings, FS_SKIN, split=2)
    # the deeply forked tail fin
    tip, fork = TL["lobe"][1], TL["lobe"][2]
    out = [(64.0, 9.0), (54.0, 13.0), (36.0, 21.0), (16.0, 30.0), (2.0, tip), (0.0, tip - 3.0),
           (8.0, tip - 12.0), (20.0, 9.0), (64.0 - fork - 9.0, 0.0)]
    out += [(w, -u) for w, u in reversed(out[:-1])]
    mid = lambda w: FZ + fs_arch(w)  # noqa: E731
    yc = fs_ymid(TL["at"])
    ring = [fs_curl(Vector((X0 + w, yc, mid(w) + u))) for w, u in out]
    a = math.radians(TL["curl"])
    fs_fan(s, fs_curl(Vector((X0 + 58.0, yc, mid(58.0)))), ring, (-math.sin(a), math.cos(a), 0.0),
           5.0, 1.0, FS_FIN)
    return s


FS_KNUCKLE = (X0 + WK, fs_ymid(WK), fs_sec(WK)[0])
FS_HINGE = (X0 + WH, fs_ymid(WH), fs_zm(WH))
FS_BUTTON_AT = (FI["button"]["at"][0], 0.0, FI["button"]["at"][1])


# --- the look ------------------------------------------------------------------------------------

FS_BD = mm(0.15)            # the look's bump distance: a height of 1 stands 0.15 mm proud


def fs_h(v):
    return v / 0.15


def fish_look(L, f):
    nb = L.nb
    xm, ym, zm = nb.mul(L.x, K.STUD_MM), nb.mul(L.y, K.STUD_MM), nb.mul(L.z, K.STUD_MM)
    sl, cl = math.sin(FS_LEAN), math.cos(FS_LEAN)
    zr = nb.sub(zm, FS_Z0)
    xl = xm
    yl = nb.sub(nb.mul(ym, cl), nb.mul(zr, sl))
    zl = nb.add(nb.mul(ym, sl), nb.mul(zr, cl))
    nzl = nb.add(nb.mul(L.ny, sl), nb.mul(L.nz, cl))
    nyl = nb.sub(nb.mul(L.ny, cl), nb.mul(L.nz, sl))

    def sq(v):
        return nb.mul(v, v)

    def hyp(a, b):
        return nb.math("SQRT", nb.add(sq(a), sq(b)))

    def within(d, r, soft=0.2):
        return nb.sub(1.0, nb.ss(d, r - soft, r + soft))

    def bell(d, at, w):
        return nb.mul(nb.ss(d, at - w, at), nb.sub(1.0, nb.ss(d, at, at + w)))

    def band(v, a, b, soft=0.3):
        return nb.mul(nb.ss(v, a - soft, a + soft), nb.sub(1.0, nb.ss(v, b - soft, b + soft)))

    def dist3(p):
        p = Vector(p) * K.STUD_MM
        return nb.math("SQRT", nb.add(nb.add(sq(nb.sub(xm, p.x)), sq(nb.sub(ym, p.y))), sq(nb.sub(zm, p.z))))

    # --- the board: pale honey oak under a clear varnish; the raw back paler and dry. Pale so
    #     the slate fish stands out on it in a dim unit (F-04k: at #CC975A it went dark in Roblox)
    face, edge, back = L.k(FS_FACE), L.k(FS_WOOD), L.k(FS_BACK)
    wood = nb.mx(nb.mx(face, edge), back)
    rings_ = L.noise(46.0, 3, stretch=(0.045, 1.0, 1.0), detail=3, distortion=0.4)
    flow = L.noise(9.0, 4, stretch=(0.2, 1.0, 1.0), detail=2)
    late = nb.ss(nb.fract(nb.add(nb.mul(rings_, 7.0), nb.mul(flow, 3.0))), 0.62, 0.9)
    pores = nb.mul(bell(L.noise(240.0, 5, stretch=(0.012, 1.0, 1.0), detail=2), 0.5, 0.025),
                   nb.ss(L.noise(80.0, 6, stretch=(0.2, 1.0, 1.0)), 0.45, 0.6))
    flecks = nb.mul(nb.ss(L.noise(120.0, 7, stretch=(0.35, 1.0, 1.0), detail=2), 0.66, 0.72),
                    nb.ss(L.noise(30.0, 8), 0.4, 0.6))
    tone = nb.mr(L.noise(6.0, 9, detail=2), 0.3, 0.7, 0.9, 1.08)
    OAK = nb.tint(nb.mixc(late, hexc("#E6BC80"), hexc("#B98149")), tone)
    C = Coat(L, OAK, 0.24, 0.0, 0.0)
    C.paint(nb.mul(wood, nb.mul(pores, nb.add(0.2, nb.mul(late, 0.4)))), hexc("#6E4320"), 0.3, None, fs_h(-0.05))
    C.paint(nb.mul(wood, nb.mul(flecks, 0.5)), hexc("#F0D3A0"))
    C.paint(wood, None, None, None, nb.mul(late, fs_h(0.03)))
    # varnish rubbed thin on the routed edge's bead and the corners, a few dings in the face
    rub = nb.mul(nb.mul(edge, L.edge(0.006, k=4.0)), nb.ss(L.noise(16.0, 10, detail=3), 0.45, 0.62))
    C.paint(nb.mul(rub, 0.7), hexc("#EDCC98"), 0.5)
    ding = nb.mul(face, nb.ss(L.noise(55.0, 11, detail=3), 0.74, 0.78))
    C.paint(nb.mul(ding, 0.6), hexc("#946537"), 0.42, None, fs_h(-0.25))
    C.paint(back, nb.tint(hexc("#C9A272"), nb.mr(late, 0.0, 1.0, 1.05, 0.86)), 0.78)
    # the speaker grille lower left: holes drilled through the face in a ring
    gx, gz = FI["grille"]["at"]
    gr, ho = FI["grille"]["r"], FI["grille"]["hole"]
    gu, gv = nb.sub(xl, gx), nb.sub(zl, gz)
    per = 4.4
    du = nb.mul(nb.sub(nb.fract(nb.add(nb.div(gu, per), 0.5)), 0.5), per)
    dv = nb.mul(nb.sub(nb.fract(nb.add(nb.div(gv, per), 0.5)), 0.5), per)
    holes = nb.mul(nb.mul(face, within(hyp(du, dv), ho, 0.25)), within(hyp(gu, gv), gr - 1.0, 0.3))
    C.paint(holes, hexc("#120D09"), 0.9, 0.0, fs_h(-1.2))
    groove = nb.mul(face, bell(hyp(gu, gv), gr + 1.2, 0.45))
    C.paint(nb.mul(groove, 0.8), hexc("#7A4D25"), 0.35, None, fs_h(-0.4))

    # --- the black box behind, its door, the leg, the rubber foot and the button's bezel
    box, door, bez = L.k(FS_BOX), L.k(FS_DOOR), L.k(FS_BEZEL)
    plastic = nb.mx(nb.mx(box, door), bez)
    grain = L.noise(500.0, 12, detail=1)
    C.paint(plastic, nb.tint(hexc("#252423"), nb.mr(grain, 0.3, 0.7, 0.9, 1.1)), 0.55, 0.0,
            nb.mul(grain, fs_h(0.03)))
    C.paint(bez, hexc("#141414"), 0.3)
    ribs = nb.mul(door, nb.mul(band(zl, FI["box"][3] + 10.0, FI["box"][3] + 30.0, 0.2),
                              nb.ss(nb.math("SINE", nb.mul(xl, 1.6)), 0.3, 0.6)))
    C.paint(ribs, hexc("#2A2928"), 0.5, None, fs_h(0.4))
    # our maker's mark: a small red star on the box
    sx_, sz_ = 80.0, FI["box"][3] + 45.0
    su, sv = nb.sub(xl, sx_), nb.sub(zl, sz_)
    ph = nb.math("ARCTAN2", su, sv)
    lobe = nb.pw(nb.add(0.5, nb.mul(nb.math("COSINE", nb.mul(ph, 5.0)), 0.5)), 2.4)
    star = nb.mul(box, within(nb.sub(hyp(su, sv), nb.mul(nb.add(0.38, nb.mul(lobe, 0.62)), 7.0)), 0.0, 0.15))
    C.paint(nb.mul(star, nb.ss(nyl, 0.5, 0.8)), hexc("#B5231C"), 0.4)
    bw, bh = FI["box"][0] / 2 - 9.0, FI["box"][1] / 2 - 9.0
    for sx in (-1, 1):
        for sz in (-1, 1):
            d = hyp(nb.sub(xl, sx * bw), nb.sub(zl, FI["box"][3] + sz * bh))
            C.paint(nb.mul(box, within(d, 3.2, 0.3)), hexc("#0E0E0E"), 0.4, None, fs_h(-0.6))
            head = nb.mul(box, within(d, 2.6, 0.2))
            C.paint(head, hexc("#55575A"), 0.35, 0.8, fs_h(0.3))
            C.paint(nb.mul(head, bell(nb.sub(xl, sx * bw), 0.0, 0.45)), hexc("#151515"), 0.5, 0.3, fs_h(-0.4))
    kz = FI["box"][3] + FI["box"][1] / 2 + 34.0
    key = nb.mx(within(hyp(xl, nb.sub(zl, kz)), 5.0, 0.3),
                nb.mul(within(nb.absf(xl), 2.6, 0.25), band(zl, kz, kz + 14.0, 0.3)))
    C.paint(nb.mul(back, key), hexc("#2A1C10"), 0.9, None, fs_h(-1.5))

    # --- the brass plate: an engraved border, a leaping fish over two waves, no words
    brass = L.k(FS_BRASS)
    px, pz = FI["plate"]["at"]
    pa, pb = FI["plate"]["half"]
    pu, pv = nb.sub(xl, px), nb.sub(zl, pz)
    BR = nb.tint(hexc("#C8A14A"), nb.mr(L.noise(40.0, 13, detail=3), 0.3, 0.7, 0.85, 1.08))
    C.paint(brass, BR, 0.24, 1.0)
    border = bell(nb.math("SQRT", nb.add(sq(nb.div(pu, pa - 3.0)), sq(nb.div(pv, pb - 3.0)))), 1.0, 0.03)
    q = nb.add(sq(nb.div(nb.sub(pu, 3.0), 13.0)), sq(nb.div(nb.add(pv, nb.mul(nb.sub(pu, 3.0), -0.12)), 4.6)))
    fbody = within(q, 1.0, 0.08)
    tail = nb.mul(band(pu, -17.5, -9.5, 0.2), nb.sub(1.0, nb.ss(nb.sub(nb.absf(pv), nb.mul(nb.sub(-8.0, pu), 0.7)), -0.2, 0.2)))
    eye = within(hyp(nb.sub(pu, 12.0), nb.sub(pv, 1.4)), 1.0, 0.2)
    emblem = nb.mul(nb.mx(fbody, tail), nb.sub(1.0, eye))
    waves = nb.mx(bell(nb.sub(pv, nb.add(-8.5, nb.mul(nb.math("SINE", nb.mul(pu, 0.42)), 1.3))), 0.0, 0.35),
                  bell(nb.sub(pv, nb.add(-11.0, nb.mul(nb.math("SINE", nb.add(nb.mul(pu, 0.42), 1.2)), 1.1))), 0.0, 0.3))
    waves = nb.mul(waves, nb.sub(1.0, nb.ss(nb.absf(pu), 30.0, 34.0)))
    cut = nb.mul(nb.mul(brass, nb.ss(nb.sub(0.0, nyl), 0.7, 0.9)), nb.mx(nb.mx(border, emblem), waves))
    C.paint(cut, hexc("#4A3414"), 0.55, 0.6, fs_h(-0.5))
    tarn = nb.mul(brass, nb.mx(L.edge(0.006, k=4.0), nb.ss(L.noise(25.0, 14, detail=3), 0.58, 0.7)))
    C.paint(nb.mul(tarn, 0.6), hexc("#7D6430"), 0.45, 0.85)

    # --- the button: glossy red plastic, rubbed shiny on its top
    btn = L.k(FS_BUTTON)
    C.paint(btn, nb.tint(hexc("#C9241B"), nb.mr(L.noise(30.0, 15, detail=2), 0.3, 0.7, 0.9, 1.06)), 0.2)
    C.paint(nb.mul(btn, nb.ss(nb.sub(0.0, nyl), 0.9, 0.99)), hexc("#D93A2A"), 0.12)

    # --- the fish: slate-blue latex over a cream belly, black speckles, airbrushed and glossy
    skin = nb.mx(L.k(FS_SKIN, FS_JAW), L.k(FS_KNUCK))
    fin = L.k(FS_FIN)
    fishy = nb.mx(skin, fin)
    w = nb.sub(xl, X0)
    zf = nb.add(FZ, nb.mul(sq(nb.sub(w, 150.0)), 5.5 / 145.0 ** 2))
    zrel = nb.sub(zl, zf)
    mott = L.noise(14.0, 16, detail=3)
    BACK = nb.tint(hexc("#36434F"), nb.mr(mott, 0.3, 0.7, 0.86, 1.12))
    FLANK = nb.tint(hexc("#7D8C95"), nb.mr(mott, 0.3, 0.7, 0.9, 1.08))
    BELLY = hexc("#E4DDCB")
    up = nb.add(nb.mul(nb.ss(nzl, -0.2, 0.7), 0.6), nb.mul(nb.ss(zrel, -4.0, 16.0), 0.6))
    C.paint(fishy, FLANK, 0.3, 0.0)
    C.paint(nb.mul(fishy, nb.clamp(up)), BACK, 0.3)
    belly = nb.mul(skin, nb.clamp(nb.add(nb.ss(nb.sub(0.0, nzl), 0.3, 0.8), nb.ss(nb.sub(0.0, zrel), 16.0, 26.0))))
    C.paint(belly, BELLY, 0.36)
    # the back toward the board: the airbrush only oversprays it, the grey latex shows through
    C.paint(nb.mul(nb.mul(skin, nb.ss(nyl, 0.8, 0.97)), 0.55), hexc("#4D555B"), 0.42)
    # speckles over the back and flanks, none on the belly
    spots = nb.mul(nb.sub(1.0, nb.ss(nb.voronoi(L.vec(s=17.0), 38.0), 0.1, 0.19)),
                   nb.ss(L.noise(60.0, 18), 0.42, 0.52))
    C.paint(nb.mul(nb.mul(skin, spots), nb.sub(1.0, nb.clamp(nb.mul(belly, 1.6)))), hexc("#1A1F24"), 0.3)
    # the lateral line, a fine pale thread of pores along the flank
    lat = nb.mul(nb.mul(skin, bell(nb.sub(zrel, 2.0), 0.0, 0.45)), band(w, 92.0, 228.0, 4.0))
    C.paint(nb.mul(nb.mul(lat, 0.4), nb.add(0.4, nb.mul(nb.ss(nb.math("SINE", nb.mul(xl, 1.9)), -0.2, 0.6), 0.6))),
            hexc("#AEB9BD"), 0.35, None, fs_h(-0.1))
    # the gill cover's edge: a dark crease curving down behind the head, the cover a shade paler
    xg = nb.sub(X0 + FI["gill"], nb.mul(nb.sub(1.0, sq(nb.div(zrel, 30.0))), 9.0))
    dg = nb.sub(xl, xg)
    gills = nb.mul(skin, nb.sub(1.0, nb.ss(nb.absf(zrel), 24.0, 30.0)))
    C.paint(nb.mul(nb.mul(gills, bell(dg, 0.0, 1.8)), 0.6), hexc("#26303A"), 0.35, None, fs_h(-0.5))
    cover = nb.mul(nb.mul(gills, nb.ss(dg, 0.5, -2.0)), nb.ss(w, 236.0, 244.0))
    C.paint(nb.mul(nb.mul(cover, nb.sub(1.0, belly)), 0.25), hexc("#9AA8AF"))
    # the latex skin: a fine pebble and a wet gloss, a little duller where dust sits
    C.paint(fishy, None, nb.mr(L.noise(80.0, 19, detail=2), 0.3, 0.7, 0.22, 0.36), None,
            nb.mul(L.noise(650.0, 20, detail=2), fs_h(0.06)))
    # the rubber ball at the hinge: a fold of darker latex
    kn = L.k(FS_KNUCK)
    C.paint(nb.mul(kn, 0.3), hexc("#2E363D"), 0.36, None, nb.mul(nb.math("SINE", nb.mul(zl, 2.2)), fs_h(0.15)))
    # the fins: slate with darker rays fanning from their roots, darkest at the edges
    rays = None
    for cx, cz, nrays, R in ((X0 + 58.0, FZ + fs_arch(58.0), 80.0, 62.0),
                             (X0 + 194.0, fs_top(194.0) - 8.0, 60.0, 37.0),
                             (X0 + 114.0, fs_top(114.0) - 5.0, 0.0, 12.0),
                             (X0 + 122.0, fs_bot(122.0) + 22.0, 90.0, 42.0),
                             (X0 + 160.0, fs_bot(160.0) + 5.0, 70.0, 18.0),
                             (X0 + 226.0, FZ + fs_arch(215.0) - 10.0, 70.0, 36.0)):
        du_, dv_ = nb.sub(xl, cx), nb.sub(zl, cz)
        dd = hyp(du_, dv_)
        near = nb.sub(1.0, nb.ss(dd, R * 1.02, R * 1.12))
        if nrays > 0:
            ang = nb.math("ARCTAN2", dv_, du_)
            r = nb.mul(bell(nb.fract(nb.mul(ang, nrays / (2 * math.pi))), 0.5, 0.18), near)
        else:
            r = nb.mul(near, 0.0)
        tipd = nb.mul(near, nb.ss(dd, R * 0.55, R))
        rays = r if rays is None else nb.mx(rays, r)
        C.paint(nb.mul(nb.mul(fin, tipd), 0.7), hexc("#1F262C"), 0.32)
    C.paint(nb.mul(nb.mul(fin, rays), 0.65), hexc("#252D33"), 0.3, None, fs_h(0.25))
    # the mouth: dark red inside, a pink tongue, rough pads of tiny teeth behind the lips
    roof = nb.mul(L.k(FS_SKIN), nb.mul(nb.ss(w, WJ - 1.0, WJ + 1.0),
                                       nb.sub(1.0, nb.ss(nb.sub(zl, nb.add(zf, MZ)), 0.2, 0.9))))
    C.paint(roof, hexc("#5C1F23"), 0.5)
    pads = nb.mul(roof, nb.ss(w, 270.0, 278.0))
    C.paint(nb.mul(pads, 0.8), hexc("#B9A79C"), 0.8, None, nb.mul(L.noise(900.0, 21), fs_h(0.15)))
    tng = L.k(FS_TONGUE)
    C.paint(tng, hexc("#8E3439"), 0.42)
    C.paint(nb.mul(tng, nb.ss(nzl, 0.85, 0.97)), hexc("#B5585C"), 0.36)
    # thick pale lips, a dark line where they meet
    lip = L.k(FS_LIP)
    # lips the head's own grey, a shade warmer: pale lips round an open mouth read as teeth
    C.paint(lip, nb.tint(hexc("#77818A"), nb.mr(mott, 0.3, 0.7, 0.92, 1.05)), 0.3)
    # the eyes: a black pupil in a gold ring, glassy
    eyes = L.k(FS_EYE)
    C.paint(eyes, hexc("#14110C"), 0.05)
    for front in (True, False):
        at, nrm, r = fs_eye_at(front)
        apex = Ls(at + nrm * r * 0.73)
        d = dist3(apex)
        iris = nb.mul(nb.ss(d, r * 0.3, r * 0.36), nb.sub(1.0, nb.ss(d, r * 0.6, r * 0.68)))
        C.paint(nb.mul(eyes, iris), hexc("#B8811F"), 0.06)
        C.paint(nb.mul(eyes, bell(d, r * 0.6, r * 0.08)), hexc("#5E3B10"), 0.06)
        # each pass stays on its own eye, or the second eye's rim paints over the first's iris
        C.paint(nb.mul(eyes, nb.mul(nb.ss(d, r * 0.78, r * 0.92), nb.sub(1.0, nb.ss(d, r * 1.6, r * 1.8)))),
                hexc("#2B2F2E"), 0.2)
    # the whiskers dark, the chin's pale
    C.paint(L.k(FS_WHISK), hexc("#2B3238"), 0.33)
    C.paint(L.k(FS_CHIN), hexc("#C2B8AB"), 0.4)
    C.finish(f.dust, grime=0.55)
    return C.surface(bump_dist=FS_BD, bump=1.0)


# --- how it sings --------------------------------------------------------------------------------

def fish_press():
    """The button pushed and let go; the tail flaps twice; the head swings out to face you,
    hits its stop and wobbles; two bars sung, the jaw driven open on each syllable and sprung
    shut, the body jolting on the loud ones, the tail flicking on the beat; the head snaps back
    and clacks against the board; one last flap."""
    p0, p1, p2, p3 = SG["press"]
    tr = FI["button"]["travel"]
    button = [(p0, 0.0), (p1, mm(tr), "Quad", "Out"), (p2, mm(tr)), (p3 - 0.04, mm(-0.25), "Quad", "In"),
              (p3, 0.0)]
    deg, t_out, t_back, over = SG["flap"]
    tail = [(0.0, 0.0)]

    def flap(t, d, bounce=True):
        tail.extend([(round(t, 4), 0.0), (round(t + t_out, 4), d, "Quad", "Out"),
                     (round(t + t_out + t_back, 4), -over if bounce else 0.0, "Quad", "In")])
        if bounce:
            tail.append((round(t + t_out + t_back + 0.06, 4), 0.0, "Sine", "Out"))

    for t in SG["flaps"]:
        flap(t, deg)
    o0, od, odeg, oover = SG["out"]
    # the body's swing drags the tail out a little behind it
    tail += [(o0, 0.0), (o0 + 0.17, 9.0, "Sine", "Out"), (o0 + 0.37, -2.0), (o0 + 0.5, 0.0)]
    beat, t_sing = SG["beat"], SG["sing"]
    for b in SG["beat_flaps"]:
        flap(t_sing + b * beat + 0.02, deg * 0.7)
    b0, bd, bounce = SG["back"]
    home = b0 + bd
    tail += [(round(home, 4), 0.0), (round(home + 0.05, 4), 6.0, "Quad", "Out"),
             (round(home + 0.15, 4), 0.0)]
    flap(SG["last_flap"], deg)
    tail.append((SG["end"], 0.0))
    body = [(0.0, 0.0), (o0, 0.0), (o0 + od, odeg + oover, "Quad", "InOut"),
            (o0 + od + 0.11, odeg - oover * 0.25), (o0 + od + 0.21, odeg + oover * 0.12),
            (o0 + od + 0.3, odeg)]
    jaw = [(0.0, 0.0)]
    for nb_, ln, d in SG["notes"]:
        t = t_sing + nb_ * beat
        ls = ln * beat
        to = min(0.08, 0.4 * ls)
        tc = max(t + to + 0.005, t + ls - 0.07)
        jaw += [(round(t, 4), 0.0), (round(t + to, 4), d, "Quad", "Out")]
        if ls >= 0.5:               # a held note: the motor hums and the jaw quivers
            k, tq = 0, t + to + 0.07
            while tq < tc - 0.03:
                jaw.append((round(tq, 4), d - 2.5 if k % 2 == 0 else d))
                k, tq = k + 1, tq + 0.07
        jaw += [(round(tc, 4), d * 0.94), (round(tc + 0.06, 4), 0.0, "Quad", "In")]
        if d >= 24.0:               # a loud one jolts the head on its motor
            body += [(round(t, 4), odeg), (round(t + 0.05, 4), odeg + 2.5, "Quad", "Out"),
                     (round(t + 0.18, 4), odeg)]
    body += [(b0, odeg), (home, 0.0, "Quad", "In"), (home + 0.08, bounce, "Quad", "Out"),
             (home + 0.18, 0.0, "Quad", "In"), (home + 0.24, bounce * 0.22, "Quad", "Out"),
             (home + 0.3, 0.0, "Quad", "In"), (SG["end"], 0.0)]
    jaw.append((SG["end"], 0.0))
    button.append((SG["end"], 0.0))

    def clean(keys):
        out = []
        for k in sorted(keys, key=lambda k: k[0]):
            if out and k[0] <= out[-1][0] + 1e-4:
                continue
            out.append(k)
        return out

    return [("Button", "move", clean(button)), ("Tail", "turn", clean(tail)),
            ("Body", "turn", clean(body)), ("Jaw", "turn", clean(jaw))]


FS_TRACKS = fish_press()

SINGING_FISH = kit.Find(
    "SingingFish",
    [kit.Part("Plaque", fs_plaque),
     kit.Part("Button", fs_button, Ls(FS_BUTTON_AT), "Plaque", Ld((0.0, 1.0, 0.0))),
     kit.Part("Body", fs_body, Ls(FS_KNUCKLE), "Plaque", Ld((0.0, 0.0, -1.0))),
     kit.Part("Tail", fs_tail, Ls(FS_KNUCKLE), "Plaque", Ld((0.0, 0.0, 1.0))),
     kit.Part("Jaw", fs_jaw, Ls(FS_HINGE), "Body", Ld((0.0, 1.0, 0.0)))],
    fish_look,
    motions={
        # pressed by a kid: the game starts the song at SING["sing"] (its first syllable)
        # filmed from the front left: the swung-out head turns its painted side and face that way
        "Press": dict(duration=SG["end"], focus=Ls((-30.0, -80.0, 140.0)), distance=0.8,
                      view=(-0.8, -2.0, 0.3), drop=0.05, tracks=FS_TRACKS),
    },
    dust=FI["dust"], seed=FI["seed"], big=True, texels=600,
)
