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
