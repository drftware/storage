"""The wind-up tin carousel (F-04j): our own musical merry-go-round, the set's Epic showpiece.

A red printed drum with a key in its side; on it a platform, a mirrored column and a crimson and
cream canopy with a scalloped valance and a pennant turn together about the centre pole, and four
pressed-tin horses ride up and down twisted brass poles, each out of step with the next. Wind:
the key turns four half turns. Play: it comes up to a turn every four seconds, the tune at that
pace, and both slow over the last six seconds as the spring runs down.

Built in mm (the find's frame: X across, Y away, Z up, the origin on the floor under the centre
pole) and handed to the kit in studs, so every piece unwraps at its true size (the fish's trap).
Its names all start cr_ / CR_.
"""

import math

import bmesh
import numpy as np
from mathutils import Matrix, Vector
from mathutils.geometry import delaunay_2d_cdt

import kit
import spec as K
from look import Coat, hexc
from shapes import Shape

mm = K.mm
CR = K.CAROUSEL
RD = K.RIDE

(CR_DRUM, CR_DECK, CR_KEY, CR_PLAT, CR_COLUMN, CR_CANOPY, CR_UNDER, CR_VAL, CR_BRASS, CR_FLAG,
 CR_POLE, CR_H1, CR_H2, CR_H3, CR_H4, CR_HBRASS) = range(131, 147)
CR_HORSES = (CR_H1, CR_H2, CR_H3, CR_H4)
S = Matrix.Scale(1.0 / K.STUD_MM, 4)
SI = Matrix.Scale(K.STUD_MM, 4)


def cr_segs(hi, n):
    return n * 2 if hi else n


def cr_lathe(s, prof, kind, segs, M=Matrix(), kinds=None, strips=False):
    """A lathe from a profile in mm, M placing it in mm; unwrapped from studs."""
    s.lathe([(r / K.STUD_MM, z / K.STUD_MM) for r, z in prof], kind, segs, S @ M @ SI,
            kinds=kinds, strips=strips)


def cr_bm(s, bm, kind, M=Matrix()):
    """Merge a bmesh built in mm, M placing it (mm); projected in its own box, in studs."""
    bmesh.ops.scale(bm, vec=Vector((1.0 / K.STUD_MM,) * 3), verts=bm.verts)
    s.merge(bm, kind, S @ M @ SI)
    bm.free()


def cr_prism(s, poly, t, kind, M, bevel=0.0):
    """A flat plate: poly [(u, v)] in the plate's XZ (mm), t thick along its Y; M places it."""
    bm = bmesh.new()
    f = [bm.verts.new((u, -t / 2, v)) for u, v in poly]
    b = [bm.verts.new((u, t / 2, v)) for u, v in poly]
    bm.faces.new(f)
    bm.faces.new(list(reversed(b)))
    n = len(poly)
    for i in range(n):
        j = (i + 1) % n
        bm.faces.new((f[i], f[j], b[j], b[i]))
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    if bevel:
        rim = [e for e in bm.edges if (e.verts[0].co.y > 0) == (e.verts[1].co.y > 0)]
        bmesh.ops.bevel(bm, geom=rim, offset=bevel, segments=2, profile=0.5, affect="EDGES",
                        clamp_overlap=True)
    cr_bm(s, bm, kind, M)


def cr_circle(cx, cz, r, n):
    return [(cx + r * math.cos(2 * math.pi * j / n), cz + r * math.sin(2 * math.pi * j / n))
            for j in range(n)]


# --- the base: a printed drum, the key's bushing, and the key -------------------------------------

def cr_base(hi):
    s = Shape()
    kinds = [CR_DECK] * 2 + [CR_DRUM] * 9 + [CR_DECK] * 4
    cr_lathe(s, CR["drum"], CR_DRUM, cr_segs(hi, 72), kinds=kinds)
    kx, _, kz = CR["key"]["at"]
    to_x = Matrix.Translation((0.0, 0.0, kz)) @ Matrix.Rotation(math.radians(90), 4, "Y")
    cr_lathe(s, [(3.4, kx - 0.6), (3.4, kx + 0.6), (2.7, kx + 1.3), (1.8, kx + 1.4)], CR_BRASS,
             cr_segs(hi, 16), to_x)
    return s


def cr_key(hi):
    """A brass butterfly key out of the drum's right side, its wings upright."""
    s = Shape()
    k = CR["key"]
    kx, _, kz = k["at"]
    r, ln = k["shaft"]
    end = kx + ln
    s.cylinder(Vector((mm(kx - 2.0), 0.0, mm(kz))), Vector((mm(end), 0.0, mm(kz))), mm(r), CR_KEY,
               cr_segs(hi, 10))
    hr, hl = k["hub"]
    s.cylinder(Vector((mm(end - hl), 0.0, mm(kz))), Vector((mm(end + 0.4), 0.0, mm(kz))), mm(hr),
               CR_KEY, cr_segs(hi, 14))
    wr, off = k["wing"]
    xc = end + wr * 0.72
    m = cr_segs(hi, 16)
    bv = 0.3 if hi else 0.0
    M = Matrix.Translation((0.0, 0.0, 0.0))
    for sz in (1, -1):
        cr_prism(s, cr_circle(xc, kz + sz * off, wr, m), k["t"], CR_KEY, M, bv)
    cr_prism(s, [(end - 1.0, kz - 3.0), (xc + 2.0, kz - 3.0), (xc + 2.0, kz + 3.0),
                 (end - 1.0, kz + 3.0)], k["t"], CR_KEY, M, bv)
    return s


# --- the top: platform, column, canopy, valance, finial, pennant, poles ---------------------------

def cr_cone():
    r0, r1, rise, p = CR["cone"]
    z0 = CR["rim"][-1][1]
    return [(r0 - (r0 - r1) * t, z0 + rise * t ** p) for t in (i / 7 for i in range(1, 8))]


def cr_valance(s, hi):
    V = CR["valance"]
    n = V["n"] * (16 if hi else 8)
    ro, ri = V["r"]
    t = V["t"]

    def ring(r_top, r_bot, z_top, at_top):
        out = []
        for j in range(n):
            a = 2 * math.pi * j / n
            q = j * V["n"] / n
            u = q - math.floor(q) - 0.5
            z = z_top if at_top else V["tip"] + V["cusp"] * (2 * u) ** 2
            r = r_top if at_top else r_bot
            out.append((mm(r * math.cos(a)), mm(r * math.sin(a)), mm(z)))
        return out

    bo = ring(ro, ro + 1.2, V["top"], False)
    to = ring(ro, ro, V["top"], True)
    ti = ring(ro - t, ro - t, V["top"], True)
    bi = ring(ro - t, ro + 1.2 - t, V["top"], False)
    s.loft([bo, to, ti, bi, bo], CR_VAL)


def cr_flag(s, hi):
    """A pennant off the rod over the finial, waving a little."""
    F = CR["flag"]
    z0, z1 = F["at"]
    ln, wv, t = F["length"], F["wave"], F["t"]
    n = cr_segs(hi, 8)
    bm = bmesh.new()
    cols = []
    for i in range(n + 1):
        f = i / n * 0.96
        x = 0.5 + ln * f
        zc, hh = (z0 + z1) / 2, (z1 - z0) / 2 * (1.0 - f)
        y = wv * math.sin(1.7 * math.pi * f) * f
        cols.append([bm.verts.new((x, y + sy * t / 2, zc + sz * hh))
                     for sy, sz in ((-1, -1), (-1, 1), (1, 1), (1, -1))])
    for a, b in zip(cols, cols[1:]):
        for k in range(4):
            bm.faces.new((a[k], b[k], b[(k + 1) % 4], a[(k + 1) % 4]))
    bm.faces.new(cols[0])
    bm.faces.new(list(reversed(cols[-1])))
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    cr_bm(s, bm, CR_FLAG)


def cr_pole_at(i):
    a = math.radians(CR["horse_at"][i])
    r = CR["poles"]["r"]
    return r * math.cos(a), r * math.sin(a)


def cr_pole(s, hi, i):
    P = CR["poles"]
    cx, cy = cr_pole_at(i)
    z0, z1 = P["z"]
    if hi:
        n, nr = 16, int((z1 - z0) / 0.8)
        w = 2 * math.pi / P["twist"]
        rings = []
        for k in range(nr + 1):
            z = z0 + (z1 - z0) * k / nr
            ring = []
            for j in range(n):
                p = 2 * math.pi * j / n
                rr = P["rod"] * (1.0 + P["depth"] * math.cos(P["lobes"] * (p - w * z)))
                ring.append((mm(cx + rr * math.cos(p)), mm(cy + rr * math.sin(p)), mm(z)))
            rings.append(ring)
        s.loft(rings, CR_POLE)
    else:
        s.cylinder(Vector((mm(cx), mm(cy), mm(z0))), Vector((mm(cx), mm(cy), mm(z1))), mm(P["rod"]),
                   CR_POLE, 8, caps=False)
    Mc = Matrix.Translation((cx, cy, 0.0))
    cr_lathe(s, [(2.9, z0 - 0.2), (2.9, z0 + 1.1), (2.3, z0 + 2.3), (1.8, z0 + 2.8)], CR_BRASS,
             cr_segs(hi, 12), Mc)
    zt = z1 - 3.4
    cr_lathe(s, [(1.8, zt), (2.3, zt + 0.5), (2.9, zt + 1.7), (2.9, z1 + 0.3)], CR_BRASS,
             cr_segs(hi, 12), Mc)


def cr_top(hi):
    s = Shape()
    cr_lathe(s, CR["platform"], CR_PLAT, cr_segs(hi, 72))
    cr_lathe(s, CR["column"], CR_COLUMN, cr_segs(hi, 32))
    prof = CR["under"] + CR["rim"] + cr_cone() + CR["collar"]
    kinds = [CR_UNDER] * 4 + [CR_CANOPY] * (len(prof) - 5)
    cr_lathe(s, prof, CR_CANOPY, cr_segs(hi, 72), kinds=kinds)
    cr_valance(s, hi)
    cr_lathe(s, CR["finial"], CR_BRASS, cr_segs(hi, 20))
    rr, r0, r1 = CR["flag"]["rod"]
    s.cylinder(Vector((0.0, 0.0, mm(r0))), Vector((0.0, 0.0, mm(r1))), mm(rr), CR_BRASS,
               cr_segs(hi, 8))
    s.cylinder(Vector((0.0, 0.0, mm(r1 - 0.2))), Vector((0.0, 0.0, mm(r1 + 1.2))), mm(1.3),
               CR_BRASS, cr_segs(hi, 10))
    cr_flag(s, hi)
    for i in range(4):
        cr_pole(s, hi, i)
    return s


# --- a pressed-tin horse: two puffed halves crimped round a flat seam ------------------------------

def cr_smin(a, b, k):
    h = np.maximum(k - np.abs(a - b), 0.0) / k
    return np.minimum(a, b) - h * h * k * 0.25


def cr_sdf(X, Z):
    """How far outside the horse's side view a point lies (mm, negative inside)."""
    kb, kl = CR["blend"]
    d = None
    for cx, cz, a, b in CR["ellipses"]:
        e = (np.sqrt(((X - cx) / a) ** 2 + ((Z - cz) / b) ** 2) - 1.0) * min(a, b)
        d = e if d is None else cr_smin(d, e, kb)
    for cx, cz, r in CR["circles"]:
        d = cr_smin(d, np.hypot(X - cx, Z - cz) - r, kb)
    for ax, az, bx, bz, ra, rb in CR["capsules"]:
        dx, dz = bx - ax, bz - az
        h = np.clip(((X - ax) * dx + (Z - az) * dz) / (dx * dx + dz * dz), 0.0, 1.0)
        c = np.hypot(X - ax - h * dx, Z - az - h * dz) - (ra + (rb - ra) * h)
        d = cr_smin(d, c, kb if ra >= 2.6 else kl)
    return d


def cr_contour(level, step, n):
    """The horse's outline where the distance is `level`, as n points evenly round, anticlockwise
    in its side view (marching squares on a grid `step` mm apart)."""
    xs = np.arange(-34.0, 36.0, step)
    zs = np.arange(-38.0, 28.0, step)
    X, Z = np.meshgrid(xs, zs)
    F = cr_sdf(X, Z) - level
    ins = F < 0

    def pt(e):
        i, j, d = e
        i1, j1 = (i + 1, j) if d == 0 else (i, j + 1)
        f0, f1 = F[j, i], F[j1, i1]
        t = f0 / (f0 - f1)
        return (xs[i] + (xs[i1] - xs[i]) * t, zs[j] + (zs[j1] - zs[j]) * t)

    nbr = {}

    def link(a, b):
        nbr.setdefault(a, []).append(b)
        nbr.setdefault(b, []).append(a)

    c = (ins[:-1, :-1].astype(int) + ins[:-1, 1:] * 2 + ins[1:, 1:] * 4 + ins[1:, :-1] * 8)
    for j, i in zip(*np.nonzero((c > 0) & (c < 15))):
        b = (ins[j, i], ins[j, i + 1], ins[j + 1, i + 1], ins[j + 1, i])
        e = [(i, j, 0), (i + 1, j, 1), (i, j + 1, 0), (i, j, 1)]
        cr = [e[k] for k in range(4) if b[k] != b[(k + 1) % 4]]
        if len(cr) == 2:
            link(*cr)
        else:
            mid = (F[j, i] + F[j, i + 1] + F[j + 1, i + 1] + F[j + 1, i]) < 0
            if mid == b[0]:
                link(e[0], e[1])
                link(e[2], e[3])
            else:
                link(e[0], e[3])
                link(e[1], e[2])
    best, seen = [], set()
    for start in nbr:
        if start in seen:
            continue
        loop, prev, cur = [], None, start
        while True:
            seen.add(cur)
            loop.append(pt(cur))
            nx = [q for q in nbr[cur] if q != prev]
            nxt = nx[0] if nx else nbr[cur][0]
            prev, cur = cur, nxt
            if cur == start or cur in seen:
                break
        if len(loop) > len(best):
            best = loop
    P = np.array(best)
    area = np.sum(P[:, 0] * np.roll(P[:, 1], -1) - np.roll(P[:, 0], -1) * P[:, 1])
    if area < 0:
        P = P[::-1]
    seg = np.hypot(*(np.roll(P, -1, 0) - P).T)
    cum = np.concatenate([[0.0], np.cumsum(seg)])
    want = np.linspace(0.0, cum[-1], n, endpoint=False)
    Pc = np.vstack([P, P[:1]])
    return np.stack([np.interp(want, cum, Pc[:, 0]), np.interp(want, cum, Pc[:, 1])], 1)


def cr_inside(poly, pts):
    """Which points lie inside a closed polygon (even-odd)."""
    x, z = pts[:, 0][:, None], pts[:, 1][:, None]
    ax, az = poly[:, 0][None, :], poly[:, 1][None, :]
    bx, bz = np.roll(poly[:, 0], -1)[None, :], np.roll(poly[:, 1], -1)[None, :]
    cross = ((az > z) != (bz > z)) & (x < ax + (z - az) * (bx - ax) / (bz - az + 1e-12))
    return np.count_nonzero(cross, 1) % 2 == 1


def cr_horse_mesh(hi):
    """The horse's two halves and the flat seam round them, in its own mm (x forward, y across,
    z up, from its pole at the saddle)."""
    fl, fh = CR["flange"]
    outer = cr_contour(fl, 0.25 if hi else 0.35, 380 if hi else 140)
    loops = [outer]
    if hi:
        loops.append(cr_contour(0.0, 0.25, 360))
    g = 0.7 if hi else 2.3
    gx, gz = np.meshgrid(np.arange(-34.0, 36.0, g), np.arange(-38.0, 28.0, g))
    G = np.stack([gx.ravel(), gz.ravel()], 1)
    G = G[cr_sdf(G[:, 0], G[:, 1]) < (-0.45 * g if hi else -1.1)]
    pts = np.vstack(loops + [G])
    edges, base = [], 0
    for lp in loops:
        n = len(lp)
        edges += [(base + i, base + (i + 1) % n) for i in range(n)]
        base += n
    vs, _, fs, *_ = delaunay_2d_cdt([Vector(p) for p in pts], edges, [], 0, 1e-5)
    V2 = np.array([(v.x, v.y) for v in vs])
    tris = [f for f in fs if len(f) == 3]
    cen = np.array([V2[list(f)].mean(0) for f in tris])
    tris = [f for f, ok in zip(tris, cr_inside(outer, cen)) if ok]
    d = -cr_sdf(V2[:, 0], V2[:, 1])
    hgt = fh + CR["puff"] * (1.0 - np.exp(-np.maximum(d, 0.0) / CR["soft"]))
    bm = bmesh.new()
    used = sorted({i for f in tris for i in f})
    fr = {i: bm.verts.new((V2[i, 0], -hgt[i], V2[i, 1])) for i in used}
    bk = {i: bm.verts.new((V2[i, 0], hgt[i], V2[i, 1])) for i in used}
    count = {}
    for f in tris:
        a, b, c = f
        bm.faces.new((fr[a], fr[b], fr[c]))
        bm.faces.new((bk[c], bk[b], bk[a]))
        for e in ((a, b), (b, c), (c, a)):
            k = tuple(sorted(e))
            count[k] = count.get(k, 0) + 1
    for (a, b), c in count.items():
        if c == 1:
            bm.faces.new((fr[a], fr[b], bk[b], bk[a]))
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    return bm


def cr_horse_at(i):
    """Horse i's pivot (mm): on its pole at the saddle, at its height as it's found."""
    x, y = cr_pole_at(i)
    return x, y, CR["saddle_z"] + RD["lift"] * math.cos(2 * math.pi * RD["phase"][i])


def cr_horse_frame(i):
    """Horse i's own frame (mm): facing the way the top turns (anticlockwise from above)."""
    a = math.radians(CR["horse_at"][i])
    f = Vector((-math.sin(a), math.cos(a), 0.0))
    o = Vector((math.cos(a), math.sin(a), 0.0))
    R = Matrix((f, -o, (0.0, 0.0, 1.0))).transposed().to_4x4()
    return Matrix.Translation(cr_horse_at(i)) @ R


def cr_horse(hi, i):
    s = Shape()
    M = cr_horse_frame(i)
    cr_bm(s, cr_horse_mesh(hi), CR_HORSES[i], M)
    z = 0.0
    for prof in ([(2.6, z - 0.5), (2.6, z + 1.1), (2.1, z + 1.9), (1.8, z + 2.1)],
                 [(1.8, z - 18.6), (2.1, z - 18.4), (2.6, z - 17.6), (2.6, z - 15.8)]):
        cr_lathe(s, prof, CR_HBRASS, cr_segs(hi, 12), M)
    return s


# --- the look ---------------------------------------------------------------------------------------

def carousel_look(L, f):
    nb = L.nb
    xm, ym, zm = nb.mul(L.x, K.STUD_MM), nb.mul(L.y, K.STUD_MM), nb.mul(L.z, K.STUD_MM)

    def sq(v):
        return nb.mul(v, v)

    def both(*ms):
        out = ms[0]
        for m in ms[1:]:
            out = nb.mul(out, m)
        return out

    def less(v, a, soft=0.15):
        return nb.ss(v, a + soft, a - soft)

    def hyp(a, b):
        return nb.math("SQRT", nb.add(sq(a), sq(b)))

    rr = hyp(xm, ym)
    ang = nb.math("ARCTAN2", ym, xm)

    def cell(n):
        """Where a point sits in one of n equal slices round the pole (-0.5 to 0.5 across it),
        and whether its slice is odd (1) or even (0)."""
        q = nb.mul(ang, n / (2 * math.pi))
        return nb.sub(nb.fract(q), 0.5), nb.math("FLOORED_MODULO", nb.math("FLOOR", q), 2.0)

    def seg(px, pz, ax, az, bx, bz):
        """Distance (mm) from (px, pz) to the segment a-b."""
        dx, dz = bx - ax, bz - az
        h = nb.clamp(nb.div(nb.add(nb.mul(nb.sub(px, ax), dx), nb.mul(nb.sub(pz, az), dz)),
                            dx * dx + dz * dz))
        return hyp(nb.sub(nb.sub(px, ax), nb.mul(h, dx)), nb.sub(nb.sub(pz, az), nb.mul(h, dz)))

    RED, CRIMSON, CREAM, NAVY, ROYAL = "#B3261E", "#A01C21", "#F1E4C4", "#1D3566", "#24489A"
    GOLD, TIN, INK = "#D7A83E", "#BFC1BA", "#231A15"
    tone = nb.mr(L.noise(700.0, 1, detail=1), 0.3, 0.7, 0.95, 1.04)
    gloss = nb.mr(L.noise(90.0, 2, detail=3), 0.3, 0.7, 0.24, 0.36)
    gold_c = nb.tint(hexc(GOLD), nb.mr(L.noise(160.0, 3, detail=3), 0.3, 0.7, 0.88, 1.08))
    C = Coat(L, hexc(RED), gloss, 0.0, 0.0)

    def gold(m):
        C.paint(m, gold_c, 0.3, 0.85)

    # --- the drum: arched navy panels between red pilasters, a star or a sunburst in each, rows of
    # printed bulbs above and below, gold beads top and bottom
    drum = L.k(CR_DRUM)
    C.paint(drum, nb.tint(hexc(RED), tone), gloss)
    fu8, par8 = cell(8)
    fu = nb.mul(fu8, 51.4)
    ap = nb.absf(fu)
    arch = nb.math("SQRT", nb.mx(nb.sub(1.0, sq(nb.div(fu, 20.5))), 0.0))
    zt = nb.add(20.6, nb.mul(arch, 3.8))
    panel = both(drum, less(ap, 20.5), nb.ss(zm, 11.4, 11.7), less(nb.sub(zm, zt), 0.0))
    inner = both(drum, less(ap, 19.6), nb.ss(zm, 12.3, 12.6), less(nb.sub(zm, zt), -0.9))
    gold(panel)
    C.paint(inner, nb.mixc(nb.ss(zm, 12.0, 24.0), nb.tint(hexc(NAVY), 0.75), hexc(ROYAL)), gloss)
    even, odd = nb.inv(par8), par8
    dz = nb.sub(zm, 17.6)
    rho = hyp(fu, dz)
    beta = nb.math("ARCTAN2", dz, fu)
    star_r = nb.add(2.3, nb.mul(nb.pw(nb.absf(nb.cos(nb.mul(beta, 4.0))), 3.0), 3.5))
    gold(both(inner, even, less(nb.sub(rho, star_r), 0.0, 0.2)))
    C.paint(both(inner, even, less(rho, 1.3, 0.12)), hexc(RED), gloss)
    for sx in (-14.0, 14.0):
        C.paint(both(inner, even, less(hyp(nb.sub(fu, sx), nb.sub(zm, 14.4)), 0.9, 0.1)), hexc(CREAM))
    dz2 = nb.sub(zm, 12.6)
    rho2 = hyp(fu, dz2)
    g = nb.math("ARCTAN2", dz2, fu)
    ray = less(nb.absf(nb.sub(nb.fract(nb.mul(g, 7.0 / math.pi)), 0.5)), 0.25, 0.03)
    fan = both(inner, odd, less(rho2, 8.6, 0.15))
    C.paint(fan, hexc(CREAM), gloss)
    C.paint(both(fan, ray), hexc(RED), gloss)
    gold(both(inner, odd, nb.band(rho2, 8.7, 9.7, 0.12)))
    gold(both(inner, odd, less(rho2, 1.7, 0.1)))
    wall = nb.band(zm, 11.4, 24.6, 0.15)
    gold(both(drum, wall, less(nb.sub(25.7, ap), 0.45, 0.12)))
    dd = nb.add(nb.div(nb.sub(25.7, ap), 2.2), nb.div(nb.absf(nb.sub(zm, 18.0)), 3.6))
    C.paint(both(drum, less(dd, 1.0, 0.06)), hexc(CREAM), gloss)
    C.paint(both(drum, less(dd, 0.35, 0.05)), hexc(RED), gloss)
    bu, _ = cell(68)
    for z0, z1 in ((6.3, 10.5), (25.5, 29.7)):
        bnd = both(drum, nb.band(zm, z0, z1, 0.12))
        C.paint(bnd, nb.tint(hexc(CREAM), tone), gloss)
        db = hyp(nb.mul(bu, 6.05), nb.sub(zm, (z0 + z1) / 2))
        C.paint(both(bnd, less(db, 1.45, 0.12)),
                nb.mixc(nb.ss(db, 0.2, 1.4), hexc("#FFF0B4"), hexc("#E2862A")), 0.2)
        gold(both(drum, nb.mx(nb.band(zm, z0 - 0.75, z0 - 0.15, 0.08), nb.band(zm, z1 + 0.15, z1 + 0.75, 0.08))))
    gold(both(drum, nb.mx(less(zm, 5.5, 0.2), nb.ss(zm, 30.5, 30.9))))

    deck = L.k(CR_DECK)
    C.paint(deck, nb.tint(hexc(TIN), tone), 0.45, 1.0)
    gold(both(deck, nb.ss(zm, 10.0, 20.0)))

    # --- the platform: radial boards, a red band of gold studs round its edge
    plat = L.k(CR_PLAT)
    top = nb.ss(L.nz, 0.5, 0.8)
    fb, pb = cell(48)
    C.paint(plat, nb.tint(hexc(RED), tone), gloss)
    pt = both(plat, top)
    C.paint(pt, nb.tint(nb.mixc(pb, hexc("#B57E45"), hexc("#C9995C")),
                        nb.mr(L.noise(180.0, 4, stretch=(1.0, 1.0, 1.0), detail=3), 0.3, 0.7, 0.9, 1.05)), gloss)
    C.paint(both(pt, nb.ss(nb.absf(fb), 0.44, 0.49)), hexc("#5A3A22"), gloss)
    C.paint(both(pt, nb.ss(rr, 52.0, 52.3)), nb.tint(hexc(RED), tone), gloss)
    gold(both(pt, nb.mx(nb.band(rr, 52.3, 53.0, 0.1), nb.band(rr, 59.8, 60.6, 0.1))))
    fd, _ = cell(44)
    gold(both(pt, less(hyp(nb.mul(fd, 8.04), nb.sub(rr, 56.3)), 1.2, 0.12)))
    gold(both(pt, less(rr, 14.6, 0.2)))
    gold(both(plat, nb.inv(top), nb.band(zm, 39.4, 40.8, 0.1), nb.ss(rr, 61.0, 61.5)))
    C.paint(both(plat, nb.ss(L.nz, -0.5, -0.8)), hexc(TIN), 0.45, 1.0)

    # --- the column: eight mirror panels in gold frames, red between with gold studs
    col = L.k(CR_COLUMN)
    fc, _ = cell(8)
    u = nb.mul(fc, 7.85)
    au = nb.absf(u)
    mid = nb.band(zm, 52.0, 136.0, 0.2)
    streak = nb.ss(L.noise(30.0, 5, stretch=(1.0, 1.0, 0.15), detail=2), 0.45, 0.65)
    C.paint(both(col, mid, less(au, 2.6, 0.1)),
            nb.mixc(streak, hexc("#B9CBD8"), hexc("#6F8798")), 0.08, 0.95)
    gold(both(col, mid, nb.band(au, 2.6, 3.3, 0.08)))
    fz = nb.mul(nb.sub(nb.fract(nb.div(zm, 6.0)), 0.5), 6.0)
    gold(both(col, mid, less(hyp(nb.sub(3.925, au), fz), 0.55, 0.08)))
    gold(both(col, nb.inv(mid)))

    # --- the canopy: sixteen crimson and cream gores with gold seams, a rose medallion on each
    # crimson one and a red diamond on each cream, a royal-blue band of gold studs at the rim
    can = L.k(CR_CANOPY)
    fg, pg = cell(16)
    C.paint(can, nb.mixc(pg, nb.tint(hexc(CRIMSON), tone), nb.tint(hexc(CREAM), tone)), gloss)
    gold(both(can, less(nb.mul(nb.sub(0.5, nb.absf(fg)), nb.mul(rr, 2 * math.pi / 16)), 0.45, 0.1)))
    ug = nb.mul(fg, 2 * math.pi * 47.0 / 16)
    dv = nb.sub(rr, 47.0)
    e = hyp(nb.div(ug, 4.4), nb.div(dv, 5.8))
    crim, crm = nb.inv(pg), pg
    C.paint(both(can, crim, less(e, 1.0, 0.04)), hexc(CREAM), gloss)
    gold(both(can, crim, nb.band(e, 1.0, 1.28, 0.03)))
    # a five-petal flower, a petal pointing up the canopy, two leaves under it
    leaf = hyp(nb.div(nb.sub(nb.absf(ug), 1.9), 1.5), nb.div(nb.sub(dv, 2.3), 0.75))
    C.paint(both(can, crim, less(leaf, 1.0, 0.08)), hexc("#2F7A45"), gloss)
    rose = hyp(ug, nb.add(dv, 0.6))
    psi = nb.math("ARCTAN2", nb.add(dv, 0.6), ug)
    petal = nb.add(1.3, nb.mul(nb.pw(nb.absf(nb.cos(nb.mul(nb.add(psi, math.pi / 2), 2.5))), 0.6), 1.5))
    C.paint(both(can, crim, less(nb.sub(rose, petal), 0.0, 0.1)), hexc("#C8232C"), gloss)
    C.paint(both(can, crim, less(nb.sub(rose, nb.mul(petal, 0.5)), 0.0, 0.08)), hexc("#86161E"), gloss)
    gold(both(can, crim, less(rose, 0.75, 0.08)))
    uw = nb.mul(fg, nb.mul(rr, 2 * math.pi / 16))
    C.paint(both(can, crm, less(nb.absf(uw), 0.45, 0.08), nb.band(rr, 18.0, 61.0, 0.2)), hexc(RED), gloss)
    dmd = nb.add(nb.div(nb.absf(ug), 2.6), nb.div(nb.absf(dv), 4.6))
    C.paint(both(can, crm, less(dmd, 1.0, 0.05)), hexc(RED), gloss)
    gold(both(can, crm, less(hyp(ug, dv), 0.9, 0.1)))
    C.paint(both(can, nb.ss(rr, 63.6, 64.0)), nb.tint(hexc(ROYAL), tone), gloss)
    gold(both(can, nb.band(rr, 62.9, 63.7, 0.1)))
    fdots, _ = cell(64)
    gold(both(can, less(hyp(nb.mul(fdots, 6.81), nb.sub(rr, 69.4)), 1.3, 0.12)))
    gold(both(can, nb.mx(nb.ss(rr, 74.9, 75.3), less(rr, 13.6, 0.2))))

    und = L.k(CR_UNDER)
    _, pr = cell(16)
    C.paint(und, nb.mixc(pr, hexc("#E6D29A"), hexc("#C4523F")), 0.4)
    gold(both(und, nb.mx(nb.band(rr, 11.0, 13.5, 0.2), nb.band(rr, 64.8, 66.0, 0.15))))
    C.paint(both(und, nb.ss(rr, 66.0, 66.3)), hexc(ROYAL), 0.4)

    # --- the valance: navy scallops edged in gold, a mirror jewel in each, red or green
    val = L.k(CR_VAL)
    nr = nb.div(nb.add(nb.mul(L.nx, xm), nb.mul(L.ny, ym)), rr)
    out = both(val, nb.ss(nr, 0.1, 0.4))
    C.paint(val, hexc("#962620"), 0.45)
    fs, ps = cell(16)
    ze = nb.add(139.0, nb.mul(sq(fs), 18.0))
    dzs = nb.sub(zm, ze)
    C.paint(out, nb.tint(hexc(NAVY), tone), gloss)
    C.paint(both(out, nb.ss(zm, 148.7, 149.1)), nb.tint(hexc(RED), tone), gloss)
    gold(both(out, nb.band(zm, 147.8, 148.6, 0.1)))
    gold(both(out, nb.band(dzs, 0.5, 1.5, 0.12)))
    C.paint(both(out, nb.band(dzs, 1.5, 2.1, 0.1)), hexc(CREAM), gloss)
    je = hyp(nb.div(nb.mul(fs, 30.6), 2.0), nb.div(nb.sub(zm, 144.6), 2.6))
    C.paint(both(out, less(je, 1.0, 0.06)), nb.mixc(ps, hexc("#C23A3A"), hexc("#2E8A5A")), 0.1, 0.75)
    gold(both(out, nb.band(je, 1.0, 1.4, 0.05)))
    C.paint(both(out, less(hyp(nb.add(nb.mul(fs, 30.6), 0.6), nb.sub(zm, 145.5)), 0.42, 0.1)),
            hexc("#FFF6E0"), 0.1, 0.0)
    gold(both(val, less(dzs, 0.45, 0.15)))

    # --- brass: the finial, collars, key and bushing; the twisted poles
    br = L.k(CR_BRASS, CR_HBRASS, CR_KEY, CR_POLE)
    C.paint(br, nb.tint(hexc("#C39A48"), nb.mr(L.noise(90.0, 6, detail=3), 0.3, 0.7, 0.84, 1.06)), 0.26, 1.0)
    C.paint(both(br, L.edge(mm(0.35), k=4.0)), hexc("#E4C67C"), 0.2)
    C.paint(both(br, nb.ss(L.noise(70.0, 7, detail=4), 0.66, 0.74)), hexc("#5E4A26"), 0.6, 0.6)

    fl = L.k(CR_FLAG)
    F = CR["flag"]
    fx = nb.div(nb.sub(xm, 0.5), F["length"])
    zc, hh = sum(F["at"]) / 2, (F["at"][1] - F["at"][0]) / 2
    edge_d = nb.sub(nb.mul(nb.sub(1.0, fx), hh), nb.absf(nb.sub(zm, zc)))
    C.paint(fl, nb.tint(hexc("#C8282B"), tone), gloss)
    gold(both(fl, less(edge_d, 0.6, 0.1)))

    # --- the horses: each its own coat, saddle and blanket, a gold bridle, breast collar and
    # reins, a painted eye, a flowing mane and tail; airbrushed darker toward the belly
    hm = [L.k(k) for k in CR_HORSES]
    hor = L.k(*CR_HORSES)
    lx, lz = 0.0, 0.0
    for i, m in enumerate(hm):
        a = math.radians(CR["horse_at"][i])
        px, py, pz = cr_horse_at(i)
        lxi = nb.add(nb.mul(nb.sub(xm, px), -math.sin(a)), nb.mul(nb.sub(ym, py), math.cos(a)))
        lx = nb.add(lx, nb.mul(m, lxi))
        lz = nb.add(lz, nb.mul(m, nb.sub(zm, pz)))

    def pal(cols):
        c = hexc(cols[0])
        for m, col in zip(hm[1:], cols[1:]):
            c = nb.mixc(m, c, hexc(col))
        return c

    shade = nb.mr(lz, -17.0, 0.0, 0.8, 1.04)
    C.paint(hor, nb.tint(pal(["#2B2623", "#B5B3AB", "#F3EFE6", "#DDA650"]), nb.mul(shade, tone)), gloss)
    dap = both(nb.add(hm[1], nb.mul(hm[2], 0.45)), nb.ss(L.noise(110.0, 8, detail=1), 0.62, 0.7))
    C.paint(nb.mul(dap, 0.55), pal(["#000000", "#7E7C76", "#CFCBC2", "#000000"]), gloss)
    # the mane down the crest of the neck, in flowing locks; the forelock
    s_m = nb.add(nb.mul(nb.sub(lx, 2.74), -0.824), nb.mul(nb.sub(lz, 0.13), 0.567))
    t_m = nb.add(nb.mul(nb.sub(lx, 2.74), 0.567), nb.mul(nb.sub(lz, 0.13), 0.824))
    mane = both(hor, nb.ss(s_m, -3.6, -3.0), nb.band(t_m, -1.0, 19.5, 0.8))
    mane_c = pal(["#D8A33A", "#F2EBDD", "#D8A33A", "#F7EDD2"])
    C.paint(mane, mane_c, 0.28, 0.0, 0.5)
    locks = nb.fract(nb.div(nb.add(s_m, nb.mul(nb.sin(nb.mul(t_m, 0.55)), 0.9)), 1.15))
    C.paint(both(mane, nb.band(locks, 0.0, 0.22, 0.06)),
            nb.tint(mane_c, 0.62), 0.32, None, -0.5)
    tail = hor
    td = nb.mn(nb.mn(seg(lx, lz, -18.5, -2.2, -23.0, -5.0), seg(lx, lz, -23.0, -5.0, -26.0, -11.0)),
               seg(lx, lz, -26.0, -11.0, -25.0, -18.0))
    tl = both(tail, less(td, 2.9, 0.4), nb.ss(nb.mul(lx, -1.0), 17.0, 18.5))
    C.paint(tl, mane_c, 0.28, 0.0, 0.5)
    C.paint(both(tl, nb.band(nb.fract(nb.div(nb.add(lz, nb.mul(lx, 0.6)), 1.3)), 0.0, 0.25, 0.06)),
            nb.tint(mane_c, 0.62), None, None, -0.5)
    # hooves
    hd = None
    for c in CR["capsules"]:
        if c[4] == 2.0 and c[5] == 2.0:
            d1 = seg(lx, lz, *c[:4])
            hd = d1 if hd is None else nb.mn(hd, d1)
    C.paint(both(hor, less(hd, 2.3, 0.15)), hexc("#2E2622"), 0.4)
    # the saddle cloth: its lower edge scalloped, a gold border, a gold tassel under each scallop;
    # over it the saddle, its seat across the back between the stamped cantle and pommel and its
    # skirt hanging in a rounded flap edged in gold, a stirrup on its strap; the girth
    cu = nb.add(lx, 1.5)
    q = nb.sub(nb.fract(nb.div(nb.add(cu, 19.5), 3.0)), 0.5)
    zb = nb.add(-9.2, nb.mul(sq(nb.mul(q, 2.0)), 1.2))
    dzb = nb.sub(lz, zb)
    cloth = both(hor, less(nb.absf(cu), 9.8, 0.12), nb.ss(dzb, -0.1, 0.1), less(lz, 0.6, 0.15))
    C.paint(cloth, nb.tint(pal(["#C0352C", "#2A8C8C", "#2F5DB3", "#7A3E9A"]), tone), gloss, None, 0.5)
    gold(both(cloth, nb.mx(nb.mx(less(dzb, 0.75, 0.1), nb.ss(nb.absf(cu), 9.0, 9.2)), nb.ss(lz, -0.2, 0.0))))
    gold(both(hor, less(hyp(nb.mul(q, 3.0), nb.add(lz, 9.9)), 0.6, 0.1), less(nb.absf(cu), 9.0, 0.1)))
    sad_c = pal(["#2F7D4C", "#6A3A8E", "#B7262A", "#2C4FA3"])
    seat = both(hor, nb.band(lx, -9.0, 4.2, 0.15), nb.ss(lz, -2.6, -2.3))
    sk = hyp(nb.div(nb.add(lx, 1.6), 4.8), nb.div(nb.add(lz, 1.6), 6.4))
    skirt = both(hor, less(sk, 1.0, 0.03))
    C.paint(nb.mx(seat, skirt), nb.tint(sad_c, tone), 0.25, None, 0.8)
    gold(nb.mx(both(skirt, nb.ss(sk, 0.85, 0.89)),
               both(seat, nb.inv(skirt), nb.band(lz, -2.4, -1.7, 0.08))))
    C.paint(both(hor, less(nb.absf(nb.add(lx, 3.0)), 0.38, 0.08), nb.band(lz, -10.0, -2.0, 0.1)),
            nb.tint(sad_c, 0.55), 0.3)
    gold(both(hor, less(nb.absf(nb.sub(hyp(nb.add(lx, 3.0), nb.mul(nb.add(lz, 10.8), 1.2)), 0.85)), 0.28, 0.08)))
    C.paint(both(hor, nb.band(lx, 4.4, 5.8, 0.15), nb.band(lz, -17.5, -6.0, 0.2)), nb.tint(sad_c, 0.7), 0.3)
    # breast collar with red jewels, bridle, reins
    bc = nb.sub(hyp(nb.sub(lx, 1.5), nb.add(lz, 5.0)), 13.5)
    collar = both(hor, less(nb.absf(bc), 0.8, 0.1), nb.ss(lx, 8.5, 9.5), nb.band(lz, -13.0, 2.0, 0.5))
    gold(collar)
    C.paint(nb.mul(collar, less(nb.absf(nb.sub(nb.fract(nb.div(lz, 4.0)), 0.5)), 0.12, 0.04)), hexc("#B01E2A"), 0.15)
    hu = nb.add(nb.mul(nb.sub(lx, 18.0), 0.737), nb.mul(nb.sub(lz, 15.0), -0.676))
    hv = nb.add(nb.mul(nb.sub(lx, 18.0), 0.676), nb.mul(nb.sub(lz, 15.0), 0.737))
    head = both(hor, nb.ss(lx, 13.5, 14.5), nb.ss(lz, 3.5, 4.5))
    strap = nb.mx(nb.mx(nb.band(hu, 7.5, 8.5, 0.1), nb.band(hu, -0.6, 0.4, 0.1)),
                  both(nb.band(hv, -1.8, -0.9, 0.1), nb.band(hu, 0.0, 8.0, 0.2)))
    gold(both(head, strap))
    gold(both(hor, less(seg(lx, lz, 25.2, 6.6, 6.0, 0.8), 0.45, 0.1)))
    de = hyp(nb.sub(lx, 20.4), nb.div(nb.sub(lz, 13.4), 1.25))
    C.paint(both(hor, less(de, 1.6, 0.1)), hexc("#F6F1E6"), 0.2)
    C.paint(both(hor, less(de, 1.2, 0.1)), hexc(INK), 0.15)
    C.paint(both(hor, less(hyp(nb.sub(lx, 20.9), nb.sub(lz, 14.0)), 0.38, 0.08)), hexc("#FFFFFF"), 0.1)
    C.paint(both(hor, less(hyp(nb.sub(lx, 27.4), nb.sub(lz, 8.6)), 0.55, 0.1)), hexc(INK), 0.3)
    C.paint(both(hor, less(seg(lx, lz, 28.3, 6.2, 25.8, 6.7), 0.28, 0.08)), hexc(INK), 0.3)
    C.paint(both(hor, less(seg(lx, lz, 16.3, 18.6, 16.0, 21.4), 0.5, 0.1)), hexc("#7A4A44"), 0.3)
    # the printed outline at the seam, as the lithographers keyed every piece
    C.paint(both(hor, L.edge(mm(0.45), k=4.0)), hexc("#3A2A20"), 0.3)

    # --- wear: tin through the printing on edges and knocks, grime, dust
    printed = L.k(CR_DRUM, CR_PLAT, CR_COLUMN, CR_CANOPY, CR_VAL, CR_FLAG, *CR_HORSES)
    C.enamel_wear(printed, hexc(TIN), 50, amount=0.55)
    C.finish(f.dust, grime=0.5)
    return C.surface(bump_dist=0.0015, bump=0.7)


# --- how it plays -------------------------------------------------------------------------------

def cr_theta():
    """The top's angle through Play: times, degrees (sampled finely), and where it stops."""
    w, t0, t1, t2, p = RD["speed"], RD["spin_up"], RD["steady"], RD["stop"], RD["fade"]

    def om(t):
        if t < t0:
            return w * (1.0 - (1.0 - t / t0) ** 2)
        if t < t1:
            return w
        if t < t2:
            return w * (1.0 - (t - t1) / (t2 - t1)) ** p
        return 0.0

    ts = np.arange(0.0, t2 + 1e-9, 1.0 / 480)
    th = np.concatenate([[0.0], np.cumsum([om(t + 1.0 / 960) / 480 for t in ts[:-1]])])
    return ts, th


def carousel_play():
    ts, th = cr_theta()
    t0, t1, t2 = RD["spin_up"], RD["steady"], RD["stop"]
    end = float(th[-1])
    marks = sorted(set([round(t0 * k / 6, 3) for k in range(7)] + [t1]
                       + [round(t1 + (t2 - t1) * k / 20, 3) for k in range(1, 21)]))
    at = lambda t: float(np.interp(t, ts, th))  # noqa: E731
    top = [(t, round(at(t), 2), "Linear", "InOut") for t in marks]
    back, settle = RD["rock"]
    top += [(round(t2 + 0.22, 3), round(end - back, 2), "Sine", "Out"),
            (round(t2 + 0.6, 3), round(end - settle, 2), "Sine", "InOut")]
    wound = 180.0 * RD["winds"]
    key = [(t, round(wound * (1.0 - at(t) / end), 2), "Linear", "InOut") for t in marks]
    tracks = [("Top", "turn", top), ("Key", "turn", key)]
    k, A = RD["bobs"], mm(RD["lift"])
    for i, ph in enumerate(RD["phase"]):
        z0 = A * math.cos(2 * math.pi * ph)

        def z(theta):
            return round(A * math.cos(2 * math.pi * (k * theta / 360.0 + ph)) - z0, 5)

        keys = [(0.0, 0.0)]
        m = math.floor(2 * ph) + 1
        while True:
            theta = (m / 2.0 - ph) * 360.0 / k
            if theta >= end - 1.0:
                break
            keys.append((round(float(np.interp(theta, th, ts)), 3), z(theta)))
            m += 1
        keys.append((t2, z(end)))
        tracks.append((f"Horse{i + 1}", "move", keys))
    return tracks


def carousel_wind():
    keys, t = [(0.0, 0.0), (0.15, 0.0)], 0.15
    for i in range(RD["winds"]):
        keys += [(round(t + 0.26, 2), 180.0 * (i + 1), "Sine", "InOut"), (round(t + 0.4, 2), 180.0 * (i + 1))]
        t += 0.4
    return round(t + 0.2, 2), [("Key", "turn", keys)]


CR_WIND_DUR, CR_WIND = carousel_wind()
CR_PLAY = carousel_play()

TIN_CAROUSEL = kit.Find(
    "TinCarousel",
    [kit.Part("Base", cr_base),
     kit.Part("Key", cr_key, tuple(mm(v) for v in CR["key"]["at"]), "Base", (1, 0, 0)),
     kit.Part("Top", cr_top, (0.0, 0.0, 0.0), "Base", (0, 0, 1))]
    + [kit.Part(f"Horse{i + 1}", (lambda i: lambda hi: cr_horse(hi, i))(i),
                tuple(mm(v) for v in cr_horse_at(i)), "Top", (0, 0, 1)) for i in range(4)],
    carousel_look,
    motions={
        # the key wound in four half turns, a regrip between each
        "Wind": dict(duration=CR_WIND_DUR, focus="Key", distance=0.3, view=(1.2, -1.7, 0.45),
                     drop=0.0, tracks=CR_WIND),
        # let go, the top comes up to speed, the horses rising and falling out of step; the key
        # turns back as the spring unwinds; it all slows over the last six seconds (the game
        # slows the tune with it) and rocks back on the gears' slack as it stops
        "Play": dict(duration=RD["end"], focus=(0.0, 0.0, mm(108.0)), distance=0.85, drop=0.1,
                     view=(-1.1, -2.0, 0.55),
                     tracks=CR_PLAY),
    },
    dust=CR["dust"], seed=CR["seed"], big=True, texels=900,
)
