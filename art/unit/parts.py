"""The storage unit's parts, built from a Spec. Blender axes per spec.py (hallway at -Y).

Each part is one MeshPart in Roblox, one texture set:
    Floor                         Concrete
    WallLeft WallRight WallBack   Partition   (drop the ones a neighbour already has)
    FacadeBack                    Partition
    Facade                        Facade      (tinted per floor through Overlay)
    Frame                         TrimSheet   (trim, jambs, pilasters, kick plates, guides, posts)
    WireTop                       TrimSheet   (optional: the open mesh top you can run across)
    Hardware                      DoorKit     (head plates, axle, tension wheel)
    Drum                          DoorKit     (turns as the curtain winds)
    Slat_A Slat_B Slat_C          DoorKit     (templates; RollUpDoor clones the chain)
    CurtainClosed                 DoorKit     (the shut curtain, merged: one part at rest)
    BottomBar                     DoorKit     (bar, seal, handles, latch body, ears)
    LatchBolt                     DoorKit
    Padlock                       DoorKit
    NumberPlate                   DoorKit     (SurfaceGui face)
    DoorOrigin                    -           (helper: the door-local frame)
"""

import math

from mathutils import Matrix, Vector

import geo
from geo import Mesh


# DoorKit atlas layout (V ranges); U spans the whole width unless noted.
SLAT_BANDS = {  # name -> (v0, v1)
    ("A", "front"): (23 / 24, 24 / 24),
    ("B", "front"): (22 / 24, 23 / 24),
    ("C", "front"): (21 / 24, 22 / 24),
    ("A", "back"): (20 / 24, 21 / 24),
    ("B", "back"): (19 / 24, 20 / 24),
    ("C", "back"): (18 / 24, 19 / 24),
}
BAR_BODY_BAND = (0.665, 0.745)
BAR_SEAL_BAND = (0.625, 0.66)
DRUM_BAND = (0.565, 0.615)
ATLAS_RECT = (0.0, 0.0, 0.555, 0.555)   # small hardware is packed into this square
PLATE_RECT = (0.58, 0.40, 0.99, 0.55)   # the number plate's face


def rib_profile(spec):
    """Front-surface samples of one rib: [(t along curtain, n outward)], valley to valley."""
    p, d = spec.pitch, spec.rib
    ts = [-0.5, -0.38, -0.27, -0.16, -0.06, 0.06, 0.16, 0.27, 0.38, 0.5]
    out = []
    for f in ts:
        c = 0.5 + 0.5 * math.cos(math.pi * f / 0.38) if abs(f) < 0.38 else 0.0
        out.append((f * p, d * c))
    return out


def by_normal(rules, default):
    """Pick a mapper by face normal: rules = [(predicate(n), mapper)]."""
    def f(vs, n):
        for pred, m in rules:
            if pred(n):
                return m(vs, n)
        return default(vs, n)
    return f


def map_wall_along(height, along, tile=4.0, u_off=0.0):
    """Partition/Facade mapping with a known long axis (0 = x, 1 = y)."""
    def f(vs, n):
        if abs(n.z) > 0.7:
            return geo.map_wall(height, tile, u_off)(vs, n)
        return [((v[along] + u_off) / tile, v.z / height) for v in vs]
    return f


def quad(mesh, a, b, c, d, mapper):
    geo.add_faces(mesh, [a, b, c, d], [[0, 1, 2, 3]], mapper)


# --- shell ------------------------------------------------------------------------------

def floor(s):
    m = Mesh("Floor")
    W2, D = s.width / 2, s.depth
    n = 3
    verts, faces = [], []
    for j in range(n + 1):
        for i in range(n + 1):
            verts.append((-W2 + 2 * W2 * i / n, D * j / n, 0.0))
    for j in range(n):
        for i in range(n):
            a = j * (n + 1) + i
            faces.append([a, a + 1, a + n + 2, a + n + 1])
    geo.add_faces(m, verts, faces, geo.map_floor(8.0))
    return m


def corrugated(m, along, a0, a1, plane, sign, z0, z1, H, u_off=0.0):
    """R-panel sheet: trapezoid ribs every stud. along: 0 = runs in x, 1 = runs in y.

    The sheet's mid-plane is `plane` on the other horizontal axis; ribs stand out toward
    `sign`. Two faces 0.03 apart; the tracks hide its top and bottom edges.
    """
    d, t = 0.10, 0.03
    pts = []
    k0, k1 = math.floor(a0), math.ceil(a1)
    for k in range(k0, k1 + 1):
        for f, o in ((0.0, 0.0), (0.32, 0.0), (0.43, d), (0.57, d), (0.68, 0.0)):
            a = k + f
            if a0 - 1e-6 <= a <= a1 + 1e-6:
                pts.append((a, o))
    if pts[0][0] > a0 + 1e-6:
        pts.insert(0, (a0, 0.0))
    if pts[-1][0] < a1 - 1e-6:
        pts.append((a1, 0.0))
    mapper = map_wall_along(H, along, u_off=u_off)

    def P(a, off, z):
        q = plane + sign * off
        return (a, q, z) if along == 0 else (q, a, z)

    for side in (+1, -1):
        for (a, o), (b, ob) in zip(pts, pts[1:]):
            oa = o + side * t / 2
            obb = ob + side * t / 2
            v = [P(a, oa, z0), P(b, obb, z0), P(b, obb, z1), P(a, oa, z1)]
            # winding: outward is +side*sign on the plane axis
            nrm = geo._normal([Vector(x) for x in v])
            want = Vector((0, sign * side, 0)) if along == 0 else Vector((sign * side, 0, 0))
            if nrm.dot(want) < 0:
                v = v[::-1]
            geo.add_faces(m, v, [[0, 1, 2, 3]], mapper)
    # end strips
    for (a, o) in (pts[0], pts[-1]):
        v = [P(a, o - t / 2, z0), P(a, o + t / 2, z0), P(a, o + t / 2, z1), P(a, o - t / 2, z1)]
        geo.add_faces(m, v, [[0, 1, 2, 3]], mapper)
        geo.add_faces(m, v, [[3, 2, 1, 0]], mapper)


def tracks(m, along, a0, a1, plane, sign, H):
    """Top and bottom U-channels that cap a partition sheet."""
    mapper = map_wall_along(H, along)
    lo_off, hi_off = -0.05, 0.15
    for z0, z1 in ((0.0, 0.14), (H - 0.14, H)):
        q0 = plane + sign * (lo_off if sign > 0 else -lo_off)
        q1 = plane + sign * (hi_off if sign > 0 else -hi_off)
        ql, qh = min(q0, q1), max(q0, q1)
        if along == 0:
            geo.box(m, (a0, ql, z0), (a1, qh, z1), mapper, bevel=0.012)
        else:
            geo.box(m, (ql, a0, z0), (qh, a1, z1), mapper, bevel=0.012)


def wall_back(s):
    m = Mesh("WallBack")
    W2, D, H = s.width / 2, s.depth, s.wall_height
    corrugated(m, 0, -W2, W2, D, -1, 0.12, H - 0.12, H)
    tracks(m, 0, -W2, W2, D, -1, H)
    return m


def wall_side(s, side):
    m = Mesh("WallLeft" if side < 0 else "WallRight")
    W2, D, H, F = s.width / 2, s.depth, s.wall_height, s.facade
    corrugated(m, 1, F, D, side * W2, +1, 0.12, H - 0.12, H, u_off=1.37 if side > 0 else 0.0)
    tracks(m, 1, F, D, side * W2, +1, H)
    return m


def facade_back(s):
    m = Mesh("FacadeBack")
    W2, H, F = s.width / 2, s.wall_height, s.facade
    o = s.door_width / 2 + s.trim
    top = s.door_height + s.trim
    mp = map_wall_along(H, 0, u_off=0.6)
    y = F
    for x0, x1, z0, z1 in ((-W2, -o, 0, H), (o, W2, 0, H), (-o, o, top, H)):
        quad(m, (x0, y, z0), (x0, y, z1), (x1, y, z1), (x1, y, z0), mp)  # faces +y
    return m


def facade(s):
    m = Mesh("Facade")
    W2, H = s.width / 2, s.wall_height
    o = s.door_width / 2 + s.trim
    top = s.door_height + s.trim
    x_in = W2 - s.pilaster
    zt = H - 0.12
    mp = map_wall_along(H, 0)
    for x0, x1, z0, z1 in ((-x_in, -o, s.kick, zt), (o, x_in, s.kick, zt), (-o, o, top, zt)):
        quad(m, (x0, 0, z0), (x1, 0, z0), (x1, 0, z1), (x0, 0, z1), mp)  # faces -y
    # behind the kick plates, so a scuffed plate never shows a hole
    for x0, x1 in ((-x_in, -o), (o, x_in)):
        quad(m, (x0, 0, 0), (x1, 0, 0), (x1, 0, s.kick), (x0, 0, s.kick), mp)
    return m


def frame(s):
    m = Mesh("Frame")
    W2, H, F, T, P = s.width / 2, s.wall_height, s.facade, s.trim, s.trim_proud
    dw2, dh = s.door_width / 2, s.door_height
    trim_z = geo.map_strip("trim", 2)
    trim_x = geo.map_strip("trim", 0)
    scuff_z = geo.map_strip("scuffed", 2)
    chan_z = geo.map_strip("channel", 2)
    chan_x = geo.map_strip("channel", 0)
    raw = geo.map_strip("raw")
    for sd in (-1, 1):
        # jamb: a steel post cover wrapping the opening's side
        lo = (min(sd * dw2, sd * (dw2 + T)), -P, 0.0)
        hi = (max(sd * dw2, sd * (dw2 + T)), 0.40, dh + T)
        jam = by_normal([(lambda n, sd=sd: n.x * sd < -0.7, scuff_z)], trim_z)
        geo.box(m, lo, hi, jam, bevel=0.018, segments=2)
        # pilaster: half a post at the unit's edge
        lo = (min(sd * (W2 - s.pilaster), sd * W2), -0.07, 0.0)
        hi = (max(sd * (W2 - s.pilaster), sd * W2), F, H)
        geo.box(m, lo, hi, trim_z, bevel=0.015, segments=2,
                edges=lambda e, c, sz: True)
        # kick plate
        x0, x1 = sorted((sd * (W2 - s.pilaster), sd * (dw2 + T)))
        geo.box(m, (x0, -0.035, 0.0), (x1, 0.0, s.kick), geo.map_strip("diamond", 0),
                bevel=0.01)
        # framing post behind the facade, the guide bolts to it
        x0, x1 = sorted((sd * (dw2 + T), sd * (dw2 + T + 0.3)))
        geo.box(m, (x0, F, 0.0), (x1, 0.42, H), chan_z, bevel=0.01)
        # guide: C-channel holding the curtain's edge
        xa, xb = sd * (dw2 - 0.03), sd * (dw2 + 0.45)
        xl, xr = min(xa, xb), max(xa, xb)
        gt = s.guide_top
        geo.box(m, (xl, 0.40, 0.0), (xr, 0.44, gt), chan_z, bevel=0.006)
        geo.box(m, (xl, 0.66, 0.0), (xr, 0.70, gt), chan_z, bevel=0.006)
        wx0, wx1 = sorted((sd * (dw2 + 0.41), sd * (dw2 + 0.45)))
        geo.box(m, (wx0, 0.44, 0.0), (wx1, 0.66, gt), chan_z)
        # bell mouth: flanges flare open at the top
        for y0, y1, lean in ((0.40, 0.44, -1), (0.66, 0.70, 1)):
            base = Matrix.Translation(Vector(((xl + xr) / 2, (y0 + y1) / 2, gt)))
            rot = Matrix.Rotation(math.radians(-28 * lean), 4, "X")
            mm = Mesh("tmp")
            geo.box(mm, (xl - (xl + xr) / 2, -0.02, 0.0), (xr - (xl + xr) / 2, 0.02, 0.2),
                    None, bevel=0.005)
            for i, v in enumerate(mm.verts):
                mm.verts[i] = base @ rot @ v
            for i, uv in enumerate(mm.uvs):
                vs = [mm.verts[k] for k in mm.faces[i]]
                mm.uvs[i] = chan_z(vs, geo._normal(vs))
            m.extend(mm)
        # stop bolt where the bottom bar tops out
        zb = s.bottom_closed + s.travel + 0.07
        geo.cylinder(m, "y", (sd * (dw2 + 0.22), 0.55, zb), 0.035, 0.34, segs=8, mapper=raw)
        geo.hexbolt(m, (sd * (dw2 + 0.22), 0.70, zb), "y", 1, mapper=raw)
        # bolts through the back flange into the post
        z = 0.7
        while z < gt - 0.3:
            geo.hexbolt(m, (sd * (dw2 + 0.33), 0.70, z), "y", 1, mapper=raw)
            z += 1.25
    # header trim and the beam behind it
    o = dw2 + T
    geo.box(m, (-o, -P, dh), (o, 0.40, dh + T),
            by_normal([(lambda n: n.z < -0.7, geo.map_strip("scuffed", 0))], trim_x),
            bevel=0.018, segments=2)
    geo.box(m, (-(o + 0.3), F, dh + T - 0.05), (o + 0.3, 0.42, dh + T + 0.45), chan_x,
            bevel=0.01)
    # top cap along the corridor wall
    geo.box(m, (-W2, -0.08, H - 0.12), (W2, F + 0.02, H + 0.012), trim_x, bevel=0.012)
    return m


def wire_top(s):
    m = Mesh("WireTop")
    W2, D, H, F = s.width / 2, s.depth, s.wall_height, s.facade
    wx = geo.map_strip("wire", 0)
    wy = geo.map_strip("wire", 1)
    r = 0.016
    x = -W2 + 0.25
    while x < W2 - 0.1:
        geo.box(m, (x - r, F + 0.02, H + 0.012), (x + r, D, H + 0.012 + 2 * r), wy)
        x += 0.5
    y = F + 0.25
    while y < D - 0.1:
        geo.box(m, (-W2, y - r, H + 0.012 + 2 * r), (W2, y + r, H + 0.012 + 4 * r), wx)
        y += 0.5
    for k in (1, 2, 3):
        yk = F + (D - F) * k / 4
        geo.box(m, (-W2, yk - 0.07, H - 0.22), (W2, yk + 0.07, H + 0.012),
                geo.map_strip("channel", 0), bevel=0.01)
    return m


# --- door hardware ------------------------------------------------------------------------

def rounded_rect(y0, z0, y1, z1, r, segs=4):
    pts = []
    corners = ((y1 - r, z0 + r, -90), (y1 - r, z1 - r, 0), (y0 + r, z1 - r, 90),
               (y0 + r, z0 + r, 180))
    for cy, cz, a0 in corners:
        for k in range(segs + 1):
            a = math.radians(a0 + 90 * k / segs)
            pts.append((cy + r * math.cos(a), cz + r * math.sin(a)))
    return pts  # counter-clockwise in (y, z)


def hardware(s):
    m = Mesh("Hardware")
    _, dy, dz = s.drum_center
    cw2 = s.curtain_width / 2
    plate = rounded_rect(0.42, dz - 0.75, dy + 0.70, dz + 0.77, 0.32)
    for sd in (-1, 1):
        x0, x1 = sorted((sd * (cw2 + 0.15), sd * (cw2 + 0.21)))
        geo.extrude_x(m, plate, x0, x1)
        xo = x1 if sd > 0 else x0
        for (yy, zz) in ((0.55, dz - 0.55), (0.55, dz + 0.55), (dy + 0.48, dz + 0.58),
                         (dy + 0.48, dz - 0.56)):
            geo.hexbolt(m, (xo, yy, zz), "x", sd, across=0.08)
        # axle stub and nut (the shaft is fixed; the drum turns on it)
        geo.cylinder(m, "x", (sd * (cw2 + 0.12), dy, dz), 0.07, 0.3, segs=12)
        geo.cylinder(m, "x", (sd * (cw2 + 0.25), dy, dz), 0.075, 0.04, segs=6, smooth=False)
    # spring tension wheel on the right
    xc = cw2 + 0.25
    geo.ring_plate(m, (xc, dy, dz), "x", 0.36, 0.30, 0.05, segs=20)
    geo.cylinder(m, "x", (xc, dy, dz), 0.11, 0.07, segs=12)
    for k in range(6):
        a = 2 * math.pi * k / 6 + 0.26
        mm = Mesh("spoke")
        geo.box(mm, (-0.018, 0.09, -0.03), (0.018, 0.31, 0.03), None)
        rot = Matrix.Rotation(a, 4, "X")
        tr = Matrix.Translation(Vector((xc, dy, dz)))
        m.extend(mm, tr @ rot)
    return m


def drum(s):
    m = Mesh("Drum")
    _, dy, dz = s.drum_center
    half = s.curtain_width / 2 + 0.04
    v0, v1 = DRUM_BAND
    u0, u1 = s.u_across(0.04)

    def pipe_map(vs, n):
        c = sum((v for v in vs), Vector()) / len(vs)
        ac = math.atan2(c.z - dz, c.y - dy)
        out = []
        for v in vs:
            a = math.atan2(v.z - dz, v.y - dy)
            while a - ac > math.pi:
                a -= 2 * math.pi
            while a - ac < -math.pi:
                a += 2 * math.pi
            out.append((u0 + (u1 - u0) * (v.x + half) / (2 * half),
                        v0 + (a + math.pi) / (2 * math.pi) * (v1 - v0) * 0.98))
        return out
    geo.cylinder(m, "x", (0, dy, dz), s.drum_r, 2 * half, segs=24, mapper=pipe_map, caps=False)
    for sd in (-1, 1):
        geo.cylinder(m, "x", (sd * (half + 0.01), dy, dz), s.drum_r + 0.03, 0.025, segs=24)
        for k in range(3):
            a = 2 * math.pi * k / 3 + 0.4
            geo.hexbolt(m, (sd * (half + 0.023), dy + 0.17 * math.cos(a), dz + 0.17 * math.sin(a)),
                        "x", sd, across=0.07, height=0.03)
    return m


def slat(s, variant):
    """One rib of curtain, hinge chord centred on the origin, hanging (identity) pose."""
    m = Mesh(f"Slat_{variant}")
    prof = rib_profile(s)
    cw2 = s.curtain_width / 2
    th = s.sheet
    fv0, fv1 = SLAT_BANDS[(variant, "front")]
    bv0, bv1 = SLAT_BANDS[(variant, "back")]
    lens = [0.0]
    for (ta, na), (tb, nb) in zip(prof, prof[1:]):
        lens.append(lens[-1] + math.hypot(tb - ta, nb - na))
    L = lens[-1]
    inset = 0.004  # half-texel guard inside each band
    u0, u1 = s.u_across()

    def band(v0, v1, s_):
        return v0 + inset + (v1 - v0 - 2 * inset) * s_

    for i in range(len(prof) - 1):
        (ta, na), (tb, nb) = prof[i], prof[i + 1]
        sa, sb = lens[i] / L, lens[i + 1] / L
        # front (faces -Y): x from -cw2 to cw2
        f = [(-cw2, -na, ta), (cw2, -na, ta), (cw2, -nb, tb), (-cw2, -nb, tb)]
        uv = [(u0, band(fv0, fv1, sa)), (u1, band(fv0, fv1, sa)),
              (u1, band(fv0, fv1, sb)), (u0, band(fv0, fv1, sb))]
        base = len(m.verts)
        for v in f:
            m.vert(v)
        m.face([base, base + 1, base + 2, base + 3], uv, True)
        # back (faces +Y), offset by the sheet
        b = [(-cw2, -na + th, ta), (-cw2, -nb + th, tb), (cw2, -nb + th, tb), (cw2, -na + th, ta)]
        uvb = [(u0, band(bv0, bv1, sa)), (u0, band(bv0, bv1, sb)),
               (u1, band(bv0, bv1, sb)), (u1, band(bv0, bv1, sa))]
        base = len(m.verts)
        for v in b:
            m.vert(v)
        m.face([base, base + 1, base + 2, base + 3], uvb, True)
    # hinge edges (thin strips at the valleys)
    for (t, n), sgn in ((prof[0], -1), (prof[-1], 1)):
        e = [(-cw2, -n, t), (-cw2, -n + th, t), (cw2, -n + th, t), (cw2, -n, t)]
        if sgn > 0:
            e = e[::-1]
        base = len(m.verts)
        for v in e:
            m.vert(v)
        vv = band(bv0, bv1, 0.0 if sgn < 0 else 1.0)
        m.face([base, base + 1, base + 2, base + 3], [(u0, vv), (u0, vv), (u1, vv),
                                                       (u1, vv)], False)
    return m


def curtain_closed(s):
    """The whole shut curtain as one mesh: what a door at rest shows, instead of 38 parts."""
    m = Mesh("CurtainClosed")
    meshes = {v: slat(s, v) for v in "ABC"}
    frames, _ = s.curtain.slats(0.0)
    for i, (mz, my, dz, dy) in enumerate(frames):
        Y, Z = s.to_blender(mz, my)
        mat = Matrix.Translation(Vector((0.0, Y, Z))) @ Matrix.Rotation(math.atan2(dz, dy), 4, "X")
        m.extend(meshes[s.slat_variant(i, 7)], mat)
    return m


def bar_profiles():
    """Bottom bar body and seal, in (y, z) about the curtain's bottom edge. Counter-clockwise."""
    body = [(-0.075, 0.03), (-0.075, -0.07), (-0.088, -0.083), (-0.088, -0.172), (-0.075, -0.188),
            (-0.062, -0.20), (0.062, -0.20), (0.075, -0.188), (0.075, 0.03), (0.03, 0.03),
            (0.03, 0.0), (-0.055, 0.0), (-0.055, 0.03)]
    body = body[::-1]  # listed clockwise above; flip
    seal = [(-0.04, -0.20), (-0.05, -0.215), (-0.058, -0.245), (-0.05, -0.275), (-0.03, -0.293),
            (0.0, -0.30), (0.03, -0.293), (0.05, -0.275), (0.058, -0.245), (0.05, -0.215),
            (0.04, -0.20)]
    return body, seal


def _signed_area(poly):
    return 0.5 * sum(a[0] * b[1] - b[0] * a[1] for a, b in zip(poly, poly[1:] + poly[:1]))


def latch_layout(s):
    """X positions for the latch (door-local), shared by the bar, the bolt and the padlock."""
    dw2 = s.door_width / 2
    fixed_ear = dw2 - 0.20
    moving_locked = fixed_ear - 0.05
    throw = 0.39
    return dict(fixed_ear=fixed_ear, moving_locked=moving_locked, throw=throw,
                body=(dw2 - 0.78, dw2 - 0.04), ear_z=0.055, ear_y=-0.20)


def bottom_bar(s):
    """Relative to the curtain's bottom edge at (0, curtain_y, bottom_closed)."""
    m = Mesh("BottomBar")
    cw2 = s.curtain_width / 2
    body, seal = bar_profiles()
    if _signed_area(body) < 0:
        body = body[::-1]
    if _signed_area(seal) < 0:
        seal = seal[::-1]
    geo.extrude_x(m, body, -cw2, cw2, uv_band=s.u_across() + BAR_BODY_BAND)
    geo.extrude_x(m, seal, -cw2 + 0.02, cw2 - 0.02, uv_band=s.u_across() + BAR_SEAL_BAND,
                  smooth=True)
    # lift handles, outside and in
    for sgn, y_face in ((-1, -0.088), (1, 0.075)):
        for x in (-0.26, 0.26):
            geo.box(m, (x - 0.05, min(y_face, y_face + sgn * 0.02), -0.165),
                    (x + 0.05, max(y_face, y_face + sgn * 0.02), -0.085), None, bevel=0.006)
        path = [(-0.26, y_face + sgn * 0.01, -0.125), (-0.26, y_face + sgn * 0.11, -0.125),
                (-0.225, y_face + sgn * 0.145, -0.125), (0.225, y_face + sgn * 0.145, -0.125),
                (0.26, y_face + sgn * 0.11, -0.125), (0.26, y_face + sgn * 0.01, -0.125)]
        geo.sweep(m, path, 0.022, segs=8)
    # slide latch body: back plate reaching up over the bottom ribs, two bolt keepers
    L = latch_layout(s)
    x0, x1 = L["body"]
    geo.box(m, (x0, -0.118, -0.12), (x1, -0.088, 0.20), None, bevel=0.008)
    for xk in (x0 + 0.08, x0 + 0.36):
        geo.box(m, (xk, -0.17, 0.0), (xk + 0.06, -0.118, 0.11), None, bevel=0.006)
    # fixed padlock ear
    ex = L["fixed_ear"]
    geo.box(m, (ex - 0.01, -0.17, L["ear_z"] - 0.03), (ex + 0.01, -0.118, L["ear_z"] + 0.03),
            None)
    geo.ring_plate(m, (ex, L["ear_y"], L["ear_z"]), "x", 0.05, 0.024, 0.02, segs=12)
    for (yy, zz) in ((-0.118, 0.17), (-0.118, -0.09)):
        for xx in (x0 + 0.04, x1 - 0.04):
            geo.hexbolt(m, (xx, yy, zz), "y", -1, across=0.045, height=0.015)
    return m


def latch_bolt(s):
    """The sliding bolt, in its shot (locked) position, relative to the bar frame."""
    m = Mesh("LatchBolt")
    L = latch_layout(s)
    mx = L["moving_locked"]
    geo.cylinder(m, "x", (mx + 0.30, -0.145, 0.055), 0.026, 0.62, segs=10)
    geo.box(m, (mx - 0.01, -0.172, L["ear_z"] - 0.03), (mx + 0.01, -0.12, L["ear_z"] + 0.03),
            None)
    geo.ring_plate(m, (mx, L["ear_y"], L["ear_z"]), "x", 0.05, 0.024, 0.02, segs=12)
    # thumb knob
    geo.cylinder(m, "y", (mx + 0.08, -0.19, 0.055), 0.032, 0.09, segs=10)
    return m


def padlock(s):
    """Laminated padlock through both ears, relative to the bar frame."""
    m = Mesh("Padlock")
    L = latch_layout(s)
    cx = (L["fixed_ear"] + L["moving_locked"]) / 2
    y = L["ear_y"]
    ez = L["ear_z"]
    r = 0.07
    cz = ez - math.sqrt(max(r * r - 0.025 ** 2, 0.0))
    # shackle: legs into the body, arc through the ears
    path = [(cx - r, y, -0.06)]
    for k in range(13):
        a = math.pi - math.pi * k / 12
        path.append((cx + r * math.cos(a), y, cz + r * math.sin(a)))
    path.append((cx + r, y, -0.06))
    geo.sweep(m, path, 0.017, segs=8)
    # body: stacked laminations
    for i in range(6):
        z0 = -0.235 + i * 0.03
        geo.box(m, (cx - 0.11, y - 0.045, z0), (cx + 0.11, y + 0.045, z0 + 0.03), None,
                bevel=0.006)
    geo.box(m, (cx - 0.1, y - 0.04, -0.06), (cx + 0.1, y + 0.04, -0.054), None, bevel=0.002)
    geo.cylinder(m, "z", (cx, y, -0.236), 0.028, 0.008, segs=12)
    return m


def number_plate(s):
    """Its face (-Y) maps to PLATE_RECT so a decal or the SurfaceGui lines up; the rest packs."""
    m = Mesh("NumberPlate")
    u0, v0, u1, v1 = PLATE_RECT

    def mp(vs, n):
        if n.y < -0.9:
            return [(u0 + (v.x + 0.9) / 1.8 * (u1 - u0), v0 + (v.z - 8.85) / 0.7 * (v1 - v0))
                    for v in vs]
        return None
    geo.box(m, (-0.9, -0.03, 8.85), (0.9, 0.0, 9.55), mp, bevel=0.008)
    return m


def door_origin(s):
    m = Mesh("DoorOrigin")
    geo.box(m, (-0.05, s.curtain_y - 0.05, -0.05), (0.05, s.curtain_y + 0.05, 0.05), None)
    return m
