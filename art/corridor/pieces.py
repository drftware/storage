"""The corridor kit's pieces, UV-mapped to the unit's texture sets (art/unit/geo.py's mappers).

Each part is one MeshPart with one texture set, so a hall of identical pieces draws in a call per
part. The straight piece is the hall's Floor (Concrete) and its Ceiling (TrimSheet: the deck in
the painted strip, the joists in the raw-steel strip). The plain wall and the dead end are a
Facade (Facade), a Trim (TrimSheet) and a Panel (Partition). The fixture is at the end.
"""

import math

from mathutils import Matrix, Vector

import geo
import parts as unit_parts  # the unit's parts.py (art/unit is on the path)
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


def deck_profile(y0=-K.SPAN / 2, y1=K.SPAN / 2):
    """The corrugation across the deck from y0 to y1 (whole studs), (y, z), low flutes straddling
    each pitch's edges so both ends (and the middle of a span, over the hall) sit on a low flute."""
    p, d, flat = K.RIB_PITCH, K.RIB_DEPTH, K.RIB_FLAT
    slope = (p - 2 * flat) / 2
    lo, hi = K.DECK, K.DECK + d
    start = y0
    pts = [(start, lo)]
    n = int(round((y1 - y0) / p))
    for k in range(n):
        y0 = start + k * p
        for dy, z in ((flat / 2, lo), (flat / 2 + slope, hi), (flat / 2 + slope + flat, hi),
                      (p - flat / 2, lo)):
            pts.append((y0 + dy, z))
    pts.append((y1, lo))
    return pts


def deck(m, x0, x1, y0=-K.SPAN / 2, y1=K.SPAN / 2):
    """The deck's underside from x0 to x1, flutes along x, every face looking down at the hall,
    plus a closed top."""
    strip = geo.map_strip("trim", along_axis=0)
    geo.extrude_x(m, deck_profile(y0, y1), x0, x1, closed=False, mapper=strip, caps=False)
    top = K.DECK + K.RIB_DEPTH + K.DECK_COVER
    geo.add_faces(m, [(x0, y0, top), (x1, y0, top), (x1, y1, top), (x0, y1, top)],
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
    the deck, a bottom chord, and a zigzag of round bars between them, close to 45 degrees."""
    panels = K.WEB_PANELS if run == K.SPAN else 2 * max(1, round(run * K.WEB_PANELS / K.SPAN / 2))
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
    step = run / panels
    for k in range(panels):
        x0, x1 = -run / 2 + k * step, -run / 2 + (k + 1) * step
        z0, z1 = (z_lo, z_hi) if k % 2 == 0 else (z_hi, z_lo)
        _rod(j, (x0, 0.0, z0), (x1, 0.0, z1), K.WEB_RADIUS, K.WEB_SEGS, web)
    return j


def ceiling(length):
    m = Mesh("Ceiling")
    deck(m, -length / 2, length / 2)
    j = joist(K.SPAN)
    turn = Matrix.Rotation(math.radians(90), 4, "Z")
    for x in K.joist_xs(length):
        m.extend(j, Matrix.Translation((x, 0.0, 0.0)) @ turn)
    return m


def straight():
    """The straight piece: STRAIGHT long, the hall's floor and the ceiling over it and its units."""
    return {"Floor": floor(K.STRAIGHT), "Ceiling": ceiling(K.STRAIGHT)}


# --- the junctions: the corner, the T and the cross (spec.py, "the junctions") -------------------
# Three MeshParts: the Floor (Concrete), the whole square; the Ceiling (TrimSheet): the deck along x,
# the joists along y, a joist girder across each y arm's mouth; and the Trim (TrimSheet): a steel
# column at each corner where the junction's walls meet. The walls themselves are the kit's plain
# walls, which the game stands where the spec says (CorridorKit.junction).

def girder(run):
    """A joist girder along X, centred: heavier chords than a joist's, a vertical every panel and a
    diagonal across each, and the closure plate on its top chord that shuts the turned deck's
    flutes."""
    g = Mesh("girder")
    raw = geo.map_strip("raw", along_axis=0)
    a, leg, t = K.GIRDER_GAP / 2, K.GIRDER_LEG, K.GIRDER_THICK
    top, bot = K.DECK, K.JOIST_BOTTOM
    _angles(g, [(a, top - leg), (a + t, top - leg), (a + t, top - t), (a + leg, top - t),
                (a + leg, top), (a, top)], run, raw)
    _angles(g, [(a, bot), (a + leg, bot), (a + leg, bot + t), (a + t, bot + t), (a + t, bot + leg),
                (a, bot + leg)], run, raw)
    web = geo.map_strip("raw")
    z_lo, z_hi = bot + t, top - t
    n = max(2, round(run / K.GIRDER_PANEL))
    step = run / n
    for k in range(n + 1):
        x = -run / 2 + k * step
        _rod(g, (x, 0.0, z_lo), (x, 0.0, z_hi), K.GIRDER_WEB, K.WEB_SEGS, web)
        if k < n:
            z0, z1 = (z_lo, z_hi) if k % 2 == 0 else (z_hi, z_lo)
            _rod(g, (x, 0.0, z0), (x + step, 0.0, z1), K.GIRDER_WEB, K.WEB_SEGS, web)
    deck_top = K.DECK + K.RIB_DEPTH + K.DECK_COVER
    geo.box(g, (-run / 2, -K.CLOSURE / 2, top), (run / 2, K.CLOSURE / 2, deck_top),
            geo.map_strip("trim", along_axis=0))
    return g


def junction_floor():
    """The whole square, mapped like a straight's floor so every arm meets it on a joint."""
    m = Mesh("Floor")
    h = K.JUNCTION / 2
    uv = lambda vs, n: [((v.x + h) / K.TILE, (v.y + h) / K.TILE) for v in vs]
    geo.box(m, (-h, -h, -K.FLOOR_SKIRT), (h, h, 0.0), uv)
    return m


def junction_ceiling(name):
    """The deck along x over the junction's extent, the joists along y on the straights' beat, and a
    girder across each y arm's mouth, where the arm's deck turns."""
    m = Mesh("Ceiling")
    x0, x1, y0, y1 = K.junction_extent(name)
    h = K.JUNCTION / 2
    deck(m, x0, x1, y0, y1)
    j = joist(y1 - y0)
    turn = Matrix.Rotation(math.radians(90), 4, "Z")
    beat = [-h + K.JOIST_SPACING * (k + 0.5) for k in range(-1, int(K.JUNCTION / K.JOIST_SPACING) + 1)]
    for x in beat:
        if x0 < x < x1:
            m.extend(j, Matrix.Translation((x, (y0 + y1) / 2, 0.0)) @ turn)
    g = girder(x1 - x0)
    for arm, y in (("+y", h), ("-y", -h)):
        if arm in K.JUNCTIONS[name]:
            m.extend(g, Matrix.Translation(((x0 + x1) / 2, y, 0.0)))
    return m


def junction_trim(name):
    """A steel column from the floor to the deck at each corner where the junction's walls meet."""
    m = Mesh("Trim")
    post = geo.map_strip("trim", 2)
    top = K.DECK + K.RIB_DEPTH + K.DECK_COVER
    for kind, (cx, cy), (sx, sy) in K.junction_walls(name)[1]:
        out, back = ((K.CORNER_PROUD, K.CORNER_BACK) if kind == "outside"
                     else (K.INSIDE_PROUD, K.INSIDE_BACK))
        xs = sorted((cx - sx * out, cx + sx * back))
        ys = sorted((cy - sy * out, cy + sy * back))
        geo.box(m, (xs[0], ys[0], 0.0), (xs[1], ys[1], top), post, bevel=0.015, segments=2,
                edges=lambda e, c, sz: True)
    return m


def junction(name):
    return {"Floor": junction_floor(), "Ceiling": junction_ceiling(name), "Trim": junction_trim(name)}


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


# --- the unit's bulb ------------------------------------------------------------------------------
# Two MeshParts: the Cage (TrimSheet: a galvanized cord grip, the black cord and bakelite socket,
# and a galvanized wire guard round the bulb) and the Glass, a plain part the game colours
# (UnitLight). The frame is the hang point under the steel top's channel; everything hangs down -z
# and is round about z, so it looks the same at any turn.

def _glass_profile():
    """The glass's outline from the neck down, (radius, z): a pear-shaped A bulb, widest a little
    past the middle and rounded to its tip."""
    out = []
    for t in (0.0, 0.18, 0.38, 0.6, 0.78, 0.92):
        if t <= 0.6:
            r = K.GLASS_NECK_R + (K.GLASS_R - K.GLASS_NECK_R) * math.sin(math.pi / 2 * t / 0.6) ** 1.4
        else:
            r = K.GLASS_R * math.sqrt(1 - ((t - 0.6) / 0.4) ** 2)
        out.append((r, K.BULB_NECK - K.GLASS_LEN * t))
    return out


def _glass_radius_at(z):
    """The glass's radius at height z (0 above the neck or below the tip)."""
    prof = _glass_profile() + [(0.0, K.BULB_TIP)]
    for (r0, z0), (r1, z1) in zip(prof, prof[1:]):
        if z1 <= z <= z0:
            return r0 + (r1 - r0) * (z0 - z) / (z0 - z1)
    return 0.0


def _glass():
    """The bulb's glass: the profile turned about z, closed at its tip; open at the neck, which
    sits inside the socket."""
    m = Mesh("Glass")
    segs = K.GLASS_SEGS
    rings = [[m.vert((r * math.cos(2 * math.pi * s / segs), r * math.sin(2 * math.pi * s / segs), z))
              for s in range(segs)] for r, z in _glass_profile()]
    for r0, r1 in zip(rings, rings[1:]):
        for s in range(segs):
            m.face([r0[s], r1[s], r1[(s + 1) % segs], r0[(s + 1) % segs]], smooth=True)
    tip = m.vert((0.0, 0.0, K.BULB_TIP))
    last = rings[-1]
    for s in range(segs):
        m.face([last[s], tip, last[(s + 1) % segs]], smooth=True)
    uv = geo.map_floor(1.0)
    m.uvs = [uv([m.verts[i] for i in f], None) for f in m.faces]
    return m


def _guard_wire(angle):
    """One of the guard's bowed wires, (x, y, z) from the collar out round the glass to the bottom
    ring, at `angle` about z."""
    top = (K.COLLAR_R - 0.01, K.BULB_NECK)
    bottom = (K.CAGE_BOTTOM_R, K.BULB_BOTTOM + K.CAGE_WIRE)
    # a cubic in (radius, z) from the collar to the bottom ring, bowed out past the glass
    p1 = (K.CAGE_R + 0.035, K.BULB_NECK - 0.05)
    p2 = (K.CAGE_R + 0.03, bottom[1] + 0.05)
    pts = []
    for k in range(K.CAGE_SEGS + 1):
        t = k / K.CAGE_SEGS
        a, b, c, d = (1 - t) ** 3, 3 * t * (1 - t) ** 2, 3 * t * t * (1 - t), t ** 3
        r = a * top[0] + b * p1[0] + c * p2[0] + d * bottom[0]
        z = a * top[1] + b * p1[1] + c * p2[1] + d * bottom[1]
        assert r - K.CAGE_WIRE > _glass_radius_at(z) + 0.012, \
            f"the guard's wire touches the glass at z = {z:.3f}"
        pts.append((r * math.cos(angle), r * math.sin(angle), z))
    return pts


def bulb():
    """The unit's bulb: {"Cage", "Glass"}."""
    galv = geo.map_strip("pipe")
    wire = geo.map_strip("wire")
    rubber = geo.map_strip("rubber")
    m = Mesh("Cage")
    # the cord grip on the channel, the cord, and the socket it holds
    geo.cylinder(m, "z", (0.0, 0.0, -K.CANOPY_H / 2), K.CANOPY_R, K.CANOPY_H, segs=6, mapper=galv,
                 smooth=False)
    _tube(m, [(0.0, 0.0, -K.CANOPY_H + 0.01), (0.0, 0.0, K.BULB_SOCKET_TOP - 0.01)], K.CORD_R, 4,
          rubber)
    geo.cylinder(m, "z", (0.0, 0.0, K.BULB_SOCKET_TOP - K.SOCKET_H / 2), K.SOCKET_R, K.SOCKET_H,
                 segs=8, mapper=rubber, radius2=K.SOCKET_TOP_R)
    geo.cylinder(m, "z", (0.0, 0.0, K.BULB_NECK + K.COLLAR_H / 2), K.COLLAR_R, K.COLLAR_H, segs=8,
                 mapper=galv, smooth=False)
    # the guard: bowed wires from the collar, a ring round them at the glass's widest, and the
    # small ring they meet in under the tip
    widest_z, widest_r = None, 0.0
    for w in range(K.CAGE_WIRES):
        pts = _guard_wire(2 * math.pi * w / K.CAGE_WIRES)
        _tube(m, pts, K.CAGE_WIRE, 3, wire)
        for p in pts:
            r = math.hypot(p[0], p[1])
            if r > widest_r:
                widest_r, widest_z = r, p[2]
    ring = [(widest_r * math.cos(2 * math.pi * k / K.RING_SEGS),
             widest_r * math.sin(2 * math.pi * k / K.RING_SEGS), widest_z) for k in range(K.RING_SEGS)]
    _loop(m, ring, (0.0, 0.0, 1.0), K.CAGE_WIRE, 3, wire)
    low = K.BULB_BOTTOM + K.CAGE_WIRE
    foot = [(K.CAGE_BOTTOM_R * math.cos(2 * math.pi * k / 6),
             K.CAGE_BOTTOM_R * math.sin(2 * math.pi * k / 6), low) for k in range(6)]
    _loop(m, foot, (0.0, 0.0, 1.0), K.CAGE_WIRE, 3, wire)
    return {"Cage": m, "Glass": _glass()}


# --- the hall's walls ---------------------------------------------------------------------------
# The plain wall (Wall) and the dead end (DeadEnd), spec.py's "the hall's walls": a unit's front
# without the door. Three MeshParts each: the Facade (the unit's Facade set, painted per floor like
# a unit's), the Trim (TrimSheet: posts, diamond kick plate, cap) and the Panel (Partition: the
# R-panel above the cap, and the bare sheet behind the wall). The Facade is flat on the face's
# plane and the Panel's middle lies behind it, which is how CorridorKit.frame tells the hall's side.

def _facade(x0, x1):
    """The painted panels between the posts, from the floor (behind the kick plate) to the cap.
    Panel seams fall every 2 studs from x = 0, so a wall centred on a whole stud ends on one."""
    m = Mesh("Facade")
    mp = unit_parts.map_wall_along(K.WALL_H, 0)
    zt = K.WALL_H - K.CAP_DROP
    unit_parts.quad(m, (x0, 0.0, 0.0), (x1, 0.0, 0.0), (x1, 0.0, zt), (x0, 0.0, zt), mp)  # faces -y
    return m


def _trim(x0, x1, cap_proud):
    """Half a post at each end (a neighbour's half makes it whole), the kick plate between them, and
    the cap along the top: the unit's own trim (art/unit/parts.py, `frame`)."""
    m = Mesh("Trim")
    H, P, F = K.WALL_H, K.POST, K.FACADE
    trim_z = geo.map_strip("trim", 2)
    for a, b in ((x0, x0 + P), (x1 - P, x1)):
        geo.box(m, (a, -K.POST_PROUD, 0.0), (b, F, H), trim_z, bevel=0.015, segments=2,
                edges=lambda e, c, sz: True)
    geo.box(m, (x0 + P, -0.035, 0.0), (x1 - P, 0.0, K.KICK), geo.map_strip("diamond", 0),
            bevel=0.01)
    geo.box(m, (x0, -cap_proud, H - K.CAP_DROP), (x1, F + 0.02, H + K.CAP_RISE),
            geo.map_strip("trim", 0), bevel=0.012)
    return m


def _panel(x0, x1, plane, backs):
    """The R-panel from inside the cap up through the deck, its ribs towards the hall; and the bare
    sheets behind, `backs` = [(x0, x1, facing)], facing +1 away from the hall, -1 towards it."""
    m = Mesh("Panel")
    H = K.WALL_H
    z0, z1 = H - K.CAP_DROP, K.DECK + K.RIB_DEPTH + K.DECK_COVER
    # Built as the top of a 10-stud wall and lifted into place, so it wears the clean upper part of
    # the units' wall texture rather than the grime they carry at the floor.
    rise = z1 - H
    sheet = Mesh("sheet")
    unit_parts.corrugated(sheet, 0, x0, x1, plane, -1, z0 - rise, H, H)
    m.extend(sheet, Matrix.Translation((0.0, 0.0, rise)))
    mp = unit_parts.map_wall_along(H, 0)
    y, zt = K.BACKING, z0
    for a, b, facing in backs:
        if facing > 0:
            unit_parts.quad(m, (b, y, 0.0), (a, y, 0.0), (a, y, zt), (b, y, zt), mp)
        else:
            unit_parts.quad(m, (a, y, 0.0), (b, y, 0.0), (b, y, zt), (a, y, zt), mp)
    return m


def plain_wall(width=K.PLAIN):
    """The plain wall: a hall side where no unit stands, one unit wide (an M's, or an S's for the
    short wall), closed to the deck."""
    w2 = width / 2
    return {
        "Facade": _facade(-w2 + K.POST, w2 - K.POST),
        "Trim": _trim(-w2, w2, K.CAP_PROUD),
        "Panel": _panel(-w2, w2, K.PANEL_PLANE, [(-w2, w2, +1)]),
    }


def dead_end():
    """The dead end: the corridor wall across the hall's end, and the R-panel above it across the
    whole span, closing off the deck's flutes. Beside the hall, behind the unit rows' end walls, a
    bare sheet closes whatever slot ends there."""
    h2, s2 = K.HALL / 2, K.SPAN / 2
    return {
        "Facade": _facade(-h2 + K.POST, h2 - K.POST),
        "Trim": _trim(-h2, h2, K.END_CAP_PROUD),
        "Panel": _panel(-s2, s2, K.END_PANEL_PLANE, [(-s2, -h2, -1), (h2, s2, -1)]),
    }
