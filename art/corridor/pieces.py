"""The corridor kit's pieces, UV-mapped to the unit's texture sets (art/unit/geo.py's mappers).

Each piece is two MeshParts, one texture set each, so a hall of identical pieces draws in two
calls: the hall's Floor (Concrete) and its Ceiling (TrimSheet: the deck in the painted strip, the
joists in the raw-steel strip).
"""

import math

from mathutils import Matrix, Vector

import geo
import spec as K
from geo import Mesh


def floor(length):
    """The hall's slab between the two rows of door faces. UVs start on a texture edge at the
    piece's end, so a row of pieces meets on a saw-cut joint and never shows a seam."""
    m = Mesh("Floor")
    L2, W2 = length / 2, K.HALL / 2
    uv = lambda vs, n: [((v.x + L2) / K.TILE, (v.y + W2) / K.TILE) for v in vs]
    geo.box(m, (-L2, -W2, -K.FLOOR_SKIRT), (L2, W2, 0.0), uv)
    return m


def deck_profile():
    """The corrugation across the span, (y, z), low flutes straddling each pitch's edges so both
    ends of the span (and its middle, over the hall) sit on a low flute."""
    p, d, flat = K.RIB_PITCH, K.RIB_DEPTH, K.RIB_FLAT
    slope = (p - 2 * flat) / 2
    lo, hi = K.DECK, K.DECK + d
    pts = [(-K.SPAN / 2, lo)]
    n = int(round(K.SPAN / p))
    for k in range(n):
        y0 = -K.SPAN / 2 + k * p
        for dy, z in ((flat / 2, lo), (flat / 2 + slope, hi), (flat / 2 + slope + flat, hi),
                      (p - flat / 2, lo)):
            pts.append((y0 + dy, z))
    pts.append((K.SPAN / 2, lo))
    return pts


def deck(m, length):
    """The deck's underside, every face looking down at the hall, plus a closed top."""
    L2, S2 = length / 2, K.SPAN / 2
    strip = geo.map_strip("trim", along_axis=0)
    geo.extrude_x(m, deck_profile(), -L2, L2, closed=False, mapper=strip, caps=False)
    top = K.DECK + K.RIB_DEPTH + K.DECK_COVER
    geo.add_faces(m, [(-L2, -S2, top), (L2, -S2, top), (L2, S2, top), (-L2, S2, top)],
                  [[0, 1, 2, 3]], strip)


def _angles(m, profile, run, mapper):
    """Two steel angles back to back: `profile` is the +side one, (across, z), counter-clockwise."""
    mirrored = [(-a, z) for a, z in reversed(profile)]
    for prof in (profile, mirrored):
        geo.extrude_x(m, prof, -run / 2, run / 2, closed=True, mapper=mapper, caps=False)


def _rod(m, a, b, r, segs, mapper):
    """A round bar from a to b, open ends (they sit inside the chords)."""
    a, b = Vector(a), Vector(b)
    d = (b - a).normalized()
    ref = Vector((0, 0, 1)) if abs(d.z) < 0.9 else Vector((0, 1, 0))
    u = d.cross(ref).normalized()
    w = d.cross(u)
    ring = [(u * math.cos(2 * math.pi * k / segs) + w * math.sin(2 * math.pi * k / segs)) * r
            for k in range(segs)]
    verts = [tuple(a + o) for o in ring] + [tuple(b + o) for o in ring]
    faces = [[k, (k + 1) % segs, segs + (k + 1) % segs, segs + k] for k in range(segs)]
    geo.add_faces(m, verts, faces, mapper, smooth=True)


def joist(run):
    """One open-web steel joist along X (the piece turns it across the hall): a top chord under
    the deck, a bottom chord, and a zigzag of round bars between them."""
    j = Mesh("joist")
    raw = geo.map_strip("raw", along_axis=0)
    g, leg, t = K.CHORD_GAP / 2, K.CHORD_LEG, K.CHORD_THICK
    top, bot = K.DECK, K.JOIST_BOTTOM
    # top chord: horizontal legs up under the deck, vertical legs hanging down
    _angles(j, [(g, top - leg), (g + t, top - leg), (g + t, top - t), (g + leg, top - t),
                (g + leg, top), (g, top)], run, raw)
    # bottom chord: horizontal legs at the bottom, vertical legs standing up
    _angles(j, [(g, bot), (g + leg, bot), (g + leg, bot + t), (g + t, bot + t), (g + t, bot + leg),
                (g, bot + leg)], run, raw)
    web = geo.map_strip("raw")
    z_lo, z_hi = bot + leg * 0.5, top - leg * 0.5
    step = run / K.WEB_PANELS
    for k in range(K.WEB_PANELS):
        x0, x1 = -run / 2 + k * step, -run / 2 + (k + 1) * step
        z0, z1 = (z_lo, z_hi) if k % 2 == 0 else (z_hi, z_lo)
        _rod(j, (x0, 0.0, z0), (x1, 0.0, z1), K.WEB_RADIUS, K.WEB_SEGS, web)
    return j


def ceiling(length):
    m = Mesh("Ceiling")
    deck(m, length)
    j = joist(K.SPAN)
    turn = Matrix.Rotation(math.radians(90), 4, "Z")
    for x in K.joist_xs(length):
        m.extend(j, Matrix.Translation((x, 0.0, 0.0)) @ turn)
    return m


def straight():
    """The straight piece: STRAIGHT long, the hall's floor and the ceiling over it and its units."""
    return {"Floor": floor(K.STRAIGHT), "Ceiling": ceiling(K.STRAIGHT)}


# --- the hall light fixture ---------------------------------------------------------------------
# Three MeshParts: the Housing (TrimSheet: painted steel, galvanized chain and box, a rubber cord),
# and two plain parts the game colours: the Diffuser (the lens HallLight.light lights) and the Eye
# (the sensor's dome HallLight.eye lights). The frame is on the floor under the lens's middle.

def _lens():
    """The frosted lens: flat on top where it clips in, bowed down across its width."""
    m = Mesh("Diffuser")
    hw, top = K.LENS_W / 2, K.LENS_TOP
    edge, bottom = top - K.LENS_EDGE, top - K.LENS_THICK
    arc = []
    n = 8
    for k in range(n + 1):
        y = -hw + 2 * hw * k / n
        arc.append((y, bottom + (edge - bottom) * (y / hw) ** 2))
    # counter-clockwise in (y, z): down the left edge, along the bow, up the right edge, back on top
    prof = [(-hw, top)] + arc + [(hw, top)]
    smooth = [False] + [True] * n + [False, False]
    geo.extrude_x(m, prof, -K.LENS_LEN / 2, K.LENS_LEN / 2, closed=True, mapper=geo.map_floor(1.0),
                  smooth=smooth)
    return m


def _housing_channel(m, mapper):
    """The steel channel the lens clips into: sloped sides, lips under the lens's edges."""
    hw, tw = K.HOUSING_W / 2, K.HOUSING_TOP_W / 2
    lt, lb, top = K.LENS_TOP, K.LENS_TOP - K.LIP, K.FIXTURE_TOP
    inner = K.LENS_W / 2 + 0.005
    shoulder = lb + 0.06
    prof = [(-hw, lb), (-inner, lb), (-inner, lt), (inner, lt), (inner, lb), (hw, lb),
            (hw, shoulder), (tw, top), (-tw, top), (-hw, shoulder)]
    geo.extrude_x(m, prof, -K.HOUSING_LEN / 2, K.HOUSING_LEN / 2, closed=True, mapper=mapper)


def _sensor(m, mapper):
    """The occupancy sensor's box on the housing's +X end and the bezel round its dome. Returns the
    dome's centre (where it meets the box)."""
    x0 = K.HOUSING_LEN / 2
    x1 = x0 + K.SENSOR_LEN
    z0 = K.LENS_TOP - K.LIP - 0.02
    geo.box(m, (x0 - 0.02, -K.SENSOR_W / 2, z0), (x1, K.SENSOR_W / 2, z0 + K.SENSOR_H), mapper,
            bevel=0.025, segments=1)
    c = ((x0 + x1) / 2, 0.0, z0)
    geo.ring_plate(m, (c[0], c[1], z0 - 0.012), "z", K.EYE_R + 0.035, K.EYE_R - 0.01, 0.024,
                   segs=K.EYE_SEGS, mapper=mapper)
    return c


def _eye(centre):
    """The sensor's dome, faceted like a Fresnel lens, hanging below the sensor box."""
    m = Mesh("Eye")
    cx, cy, cz = centre
    rings = K.EYE_RINGS
    segs = K.EYE_SEGS
    top = [m.vert((cx + K.EYE_R * math.cos(2 * math.pi * s / segs),
                   cy + K.EYE_R * math.sin(2 * math.pi * s / segs), cz)) for s in range(segs)]
    prev = top
    for r in range(1, rings + 1):
        a = (math.pi / 2) * r / (rings + 1)
        rad, dz = K.EYE_R * math.cos(a), K.EYE_DROP * math.sin(a)
        off = math.pi / segs * r  # stagger the facets, as a Fresnel dome's are
        ring = [m.vert((cx + rad * math.cos(2 * math.pi * s / segs + off),
                        cy + rad * math.sin(2 * math.pi * s / segs + off), cz - dz))
                for s in range(segs)]
        for s in range(segs):
            m.face([prev[s], ring[s], ring[(s + 1) % segs], prev[(s + 1) % segs]])
        prev = ring
    pole = m.vert((cx, cy, cz - K.EYE_DROP))
    for s in range(segs):
        m.face([prev[s], pole, prev[(s + 1) % segs]])
    m.face(top)  # the flat top, facing up into the box
    uv = geo.map_floor(1.0)
    m.uvs = [uv([m.verts[i] for i in f], None) for f in m.faces]
    return m


def _rings(m, pts, frames, r, sides):
    """Rings of `sides` vertices round each point; frames[i] = (a, b) with a x b along the path."""
    return [[m.vert(Vector(p) + r * (math.cos(2 * math.pi * k / sides) * a
                                     + math.sin(2 * math.pi * k / sides) * b))
             for k in range(sides)] for p, (a, b) in zip(pts, frames)]


def _skin(m, rings, closed, mapper):
    count = len(rings) if closed else len(rings) - 1
    sides = len(rings[0])
    for i in range(count):
        r0, r1 = rings[i], rings[(i + 1) % len(rings)]
        for k in range(sides):
            q = [r0[k], r0[(k + 1) % sides], r1[(k + 1) % sides], r1[k]]
            vs = [m.verts[j] for j in q]
            m.face(q, mapper(vs, geo._normal(vs)), True)


def _loop(m, pts, normal, r, sides, mapper):
    """A round wire round a closed loop lying in the plane with this normal (a chain link, an eye).
    The ring frame keeps to the plane, so the wire never twists."""
    nrm = Vector(normal)
    frames = []
    for i in range(len(pts)):
        t = (Vector(pts[(i + 1) % len(pts)]) - Vector(pts[i - 1])).normalized()
        frames.append((nrm.cross(t).normalized(), nrm))
    _skin(m, _rings(m, pts, frames, r, sides), True, mapper)


def _tube(m, pts, r, sides, mapper):
    """A round cord along an open path; its ring frame is carried along without twisting."""
    vs = [Vector(p) for p in pts]
    tans = [(vs[min(i + 1, len(vs) - 1)] - vs[max(i - 1, 0)]).normalized() for i in range(len(vs))]
    ref = Vector((1.0, 0.0, 0.0)) if abs(tans[0].x) < 0.9 else Vector((0.0, 1.0, 0.0))
    b = (ref - tans[0] * ref.dot(tans[0])).normalized()
    frames = []
    for t in tans:
        b = (b - t * b.dot(t)).normalized()
        frames.append((b.cross(t).normalized(), b))
    _skin(m, _rings(m, pts, frames, r, sides), False, mapper)


def _link(m, centre, across_x, mapper):
    """One jack chain link standing up at `centre`, its loop in the X-Z plane (or Y-Z)."""
    r = K.LINK_WIRE
    rad = K.LINK_W / 2 - r                 # the loop's end radius, on the wire's centre
    straight = (K.LINK_LEN - 2 * r) - 2 * rad
    half = K.LINK_POINTS // 2
    pts = []
    for end, zc in ((0, straight / 2), (1, -straight / 2)):
        for k in range(half):
            a = math.pi * k / (half - 1) + math.pi * end
            u, w = rad * math.cos(a), zc + rad * math.sin(a)
            pts.append((centre[0] + (u if across_x else 0.0), centre[1] + (0.0 if across_x else u),
                        centre[2] + w))
    _loop(m, pts, (0.0, 1.0, 0.0) if across_x else (1.0, 0.0, 0.0), r, K.LINK_SIDES, mapper)


def _ring(m, centre, radius, wire, plane_x, mapper, segs=8):
    """A small wire eye standing up, its loop in the X-Z plane (plane_x) or the Y-Z plane."""
    pts = []
    for k in range(segs):
        a = 2 * math.pi * k / segs
        u, w = radius * math.cos(a), radius * math.sin(a)
        pts.append((centre[0] + (u if plane_x else 0.0), centre[1] + (0.0 if plane_x else u),
                    centre[2] + w))
    _loop(m, pts, (0.0, 1.0, 0.0) if plane_x else (1.0, 0.0, 0.0), wire, 4, mapper)


def _chain(m, x, paint, galv):
    """An eye bolt on the housing's top, a hanging run of links, and a clip on the deck. Each link
    hangs on the one above it, a quarter turn round, the housing's weight pulling them straight."""
    top, r = K.FIXTURE_TOP, K.LINK_WIRE
    geo.hexbolt(m, (x, 0.0, top), "z", 1, across=0.1, height=0.04, mapper=paint)
    eye_r, eye_wire = 0.045, 0.016
    eye_c = top + 0.04 + eye_r
    _ring(m, (x, 0.0, eye_c), eye_r, eye_wire, True, galv)
    plate = 0.03
    geo.box(m, (x - 0.11, -0.11, K.DECK - plate), (x + 0.11, 0.11, K.DECK + 0.01), galv)
    clip_c = K.DECK - plate - eye_r + 0.01
    # A link's centre line reaches `half` above and below its middle; where two wires hook, their
    # centres sit a wire's thickness apart (both radii).
    half = (K.LINK_LEN - 2 * r) / 2
    first = (eye_c + eye_r) - (eye_wire + r) + half   # the bottom link, hooked on the eye bolt
    last = (clip_c - eye_r) + (eye_wire + r) - half   # the top link, hooked on the clip's eye
    pitch = K.LINK_LEN - 4 * r
    n = max(2, round((last - first) / pitch) + 1)
    step = (last - first) / (n - 1)
    for k in range(n):
        _link(m, (x, 0.0, first + step * k), k % 2 == 1, galv)
    # the clip's eye turns a quarter from the top link, so the two hook
    _ring(m, (x, 0.0, clip_c), eye_r, eye_wire, (n - 1) % 2 == 0, galv)


def _bezier(p0, p1, p2, p3, n):
    out = []
    for i in range(n + 1):
        t = i / n
        a, b, c, d = (1 - t) ** 3, 3 * t * (1 - t) ** 2, 3 * t * t * (1 - t), t ** 3
        out.append(tuple(a * p0[j] + b * p1[j] + c * p2[j] + d * p3[j] for j in range(3)))
    return out


def _power(m, sensor_top, paint, galv, rubber):
    """A black cord from the sensor box, hanging in a slack curve up to a junction box on the deck."""
    bx, by = K.BOX_X, 0.0
    box_bottom = K.DECK - K.BOX_H
    geo.cylinder(m, "z", (bx, by, K.DECK - K.BOX_H / 2), K.BOX_R, K.BOX_H, segs=8, mapper=galv,
                 smooth=False)
    geo.cylinder(m, "z", (bx, by, box_bottom - 0.03), 0.045, 0.06, segs=6, mapper=paint,
                 smooth=False)  # the cord grip
    sx = K.HOUSING_LEN / 2 + K.SENSOR_LEN * 0.6
    geo.cylinder(m, "z", (sx, 0.0, sensor_top + 0.025), 0.04, 0.05, segs=6, mapper=paint,
                 smooth=False)  # the strain relief on the sensor box
    path = _bezier((sx, 0.0, sensor_top + 0.04), (sx + 0.05, 0.32, 12.9), (bx - 0.1, 0.3, 13.4),
                   (bx, by, box_bottom - 0.05), 12)
    _tube(m, path, K.CORD_R, 6, rubber)


def fixture():
    """The hall light: {"Housing", "Diffuser", "Eye"}."""
    paint = geo.map_strip("trim", along_axis=0)
    galv = geo.map_strip("pipe")
    rubber = geo.map_strip("rubber")
    h = Mesh("Housing")
    _housing_channel(h, paint)
    centre = _sensor(h, paint)
    for x in (-K.CHAIN_X, K.CHAIN_X):
        _chain(h, x, paint, galv)
    _power(h, centre[2] + K.SENSOR_H, paint, galv, rubber)
    return {"Housing": h, "Diffuser": _lens(), "Eye": _eye(centre)}
