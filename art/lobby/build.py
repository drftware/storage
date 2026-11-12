"""Build Everkeep's front office (the lobby) in Blender, headless (art/lobby/README.md).

    blender -b --factory-startup -P art/lobby/build.py -- --stage export|renders

Stages:
    export   out/Lobby.fbx (every part, one MeshPart each) and src/shared/Lobby/Specs.luau
    renders  the look sheets, art/sheets/lobby-*.png

The lobby bakes nothing: its parts wear the unit's baked texture sets (art/unit/out/textures,
build those first), and its deck, joists and walls are the corridor kit's own pieces, so it reads
as the same building. The look sheets stand the climb's own elevator in each bay, built by the
elevator's build (art/elevator/out holds its bakes and unwraps), and hang the corridor's light.
"""

import argparse
import importlib.util
import math
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
UNIT = os.path.join(HERE, "..", "unit")
CORRIDOR = os.path.abspath(os.path.join(HERE, "..", "corridor"))
ELEVATOR = os.path.abspath(os.path.join(HERE, "..", "elevator"))
sys.path.insert(0, UNIT)
sys.path.insert(0, CORRIDOR)  # first: `spec` is the corridor's, which its pieces read

import bpy  # noqa: E402
from mathutils import Matrix, Vector  # noqa: E402

import bake  # noqa: E402
import build as corridor  # noqa: E402  the corridor's build: its fixture, for the sheets
import geo  # noqa: E402
import parts as unit_parts  # noqa: E402
import pieces  # noqa: E402
import render  # noqa: E402
import spec as C  # noqa: E402  the corridor's spec
from geo import Mesh  # noqa: E402


def load(name, path):
    s = importlib.util.spec_from_file_location(name, path)
    mod = importlib.util.module_from_spec(s)
    s.loader.exec_module(mod)
    return mod


K = load("lobby_spec", os.path.join(HERE, "spec.py"))
E = load("elevator_spec", K.ELEVATOR_SPEC)

OUT = os.path.join(HERE, "out")
TEX = os.path.join(UNIT, "out", "textures")
SHEETS = os.path.join(K.ROOT, "art", "sheets")
FBX = os.path.join(OUT, "Lobby.fbx")
TEXSET = {"Floor": "Concrete", "Ceiling": "TrimSheet", "Facade": "Facade", "Trim": "TrimSheet",
          "Panel": "Partition", "Storefront": "TrimSheet", "Counter": "TrimSheet",
          "CounterFront": "Facade", "Shelves": "TrimSheet", "CartRack": "TrimSheet",
          "Signs": "TrimSheet"}
# Untextured: imported without a SurfaceAppearance, so the game sets their Material and Color.
# These are only the colours they import with.
PLAIN = {"Glass": (0.16, 0.19, 0.2), "FloorPaint": (0.84, 0.62, 0.1)}
# Everkeep's colours in the sheets (the game's are Lobby.Paint): teal walls, cream counter.
TINT = {"Facade": "#2F6466", "CounterFront": "#CFCAC0"}

H = C.WALL_H                         # the walls' cap height, as the units' and the corridor's
CAP = H - C.CAP_DROP                 # the cap's underside: the facade stops there
TOP = C.DECK + C.RIB_DEPTH + C.DECK_COVER  # the panel runs up to the deck's top
W2, D = K.WIDTH / 2, K.DEPTH


def reset():
    bpy.ops.wm.read_factory_settings(use_empty=True)


def check():
    """The lobby must fit the climb's own elevator and the corridor's light exactly."""
    assert tuple(K.OPENING) == tuple(E.OPENING), "the bays' hole isn't the elevator's"
    assert K.WALL == E.WALL and K.JAMB == E.JAMB and K.HEADER == E.HEADER, "not the elevator's wall"
    assert abs(E.KEYPAD[0] + E.BACKPLATE[0] / 2 - K.KEYPAD_REACH) < 1e-6, "the keypad moved"
    gap = K.BAY_PITCH - K.OPENING[0] / 2 - K.JAMB
    assert K.KEYPAD_REACH < gap - 0.5, "a car's keypad runs into the next car's frame"
    assert K.DECK == C.DECK, "the lobby's deck isn't the corridor's: the hall light hangs wrong"
    for x, _ in K.fixtures():
        off = (x % K.JOIST_EVERY) - K.JOIST_EVERY / 2
        assert abs(off) < 1e-6, f"a light at {x} isn't midway between joists"
    xs = K.bay_xs()
    assert all(abs(x % K.JOIST_EVERY - K.JOIST_EVERY / 2) < 1e-6 for x in xs), "a joist over a car"


# --- the shell: floor, deck, walls ------------------------------------------------------------

def floor():
    """The slab from the bay wall to the apron outside the front door. UVs start on a texture
    edge at the room's corner, so the saw-cut joints run square to the walls."""
    m = Mesh("Floor")
    uv = lambda vs, n: [((v.x + W2) / C.TILE, (v.y + D) / C.TILE) for v in vs]
    geo.box(m, (-W2, -D - K.APRON, -C.FLOOR_SKIRT), (W2, 0.0, 0.0), uv)
    return m


def ceiling():
    """The corridor's steel deck over the whole room on its open-web joists, which span the
    room's depth front to back, one every 6 across: each car's middle falls between two."""
    m = Mesh("Ceiling")
    pieces.deck(m, -W2, W2, -D, 0.0)
    j = pieces.joist(D)
    turn = Matrix.Rotation(math.radians(90), 4, "Z")
    for x in K.joist_xs():
        m.extend(j, Matrix.Translation((x, -D / 2, 0.0)) @ turn)
    return m


# Each wall is built in the corridor's wall frame (its face on y = 0, the room toward -y, x along
# it) and turned into place. `along` maps a world span onto the frame's x.
WALLS = {
    "Bay": (Matrix.Identity(4), lambda a, b: (a, b)),
    "Front": (Matrix.Translation((0.0, -D, 0.0)) @ Matrix.Rotation(math.pi, 4, "Z"),
              lambda a, b: (-b, -a)),
    "Left": (Matrix.Translation((-W2, 0.0, 0.0)) @ Matrix.Rotation(math.pi / 2, 4, "Z"),
             lambda a, b: (a, b)),
    "Right": (Matrix.Translation((W2, 0.0, 0.0)) @ Matrix.Rotation(-math.pi / 2, 4, "Z"),
              lambda a, b: (-b, -a)),
}


def wall_layout():
    """For each wall, in its own frame: the facade's spans, the kick plate's and cap's spans, and
    its posts' middles. Spans are world spans along the wall, mapped into the frame."""
    ow = K.OPENING[0] / 2
    fw = ow + K.JAMB
    xs = K.bay_xs()
    s0, s1 = K.STORE
    lay = {}
    # the bay wall: facade up to each hole's edge, trim stopping at the landing frames' plates
    face = [(-W2, xs[0] - ow)] + [(a + ow, b - ow) for a, b in zip(xs, xs[1:])] + [(xs[-1] + ow, W2)]
    trim = [(-W2, xs[0] - fw)] + [(a + fw, b - fw) for a, b in zip(xs, xs[1:])] + [(xs[-1] + fw, W2)]
    lay["Bay"] = (face, trim, trim, K.posts())
    # the front: facade either side of the storefront; the cap runs over it
    front_posts = [x for x in (-48.0, -36.0, -24.0, 24.0, 36.0, 48.0)]
    lay["Front"] = ([(-W2, s0), (s1, W2)], [(-W2, s0), (s1, W2)], [(-W2, W2)], front_posts)
    side_posts = [-36.0, -24.0, -12.0]
    lay["Left"] = ([(-D, 0.0)], [(-D, 0.0)], [(-D, 0.0)], side_posts)
    lay["Right"] = ([(-D, 0.0)], [(-D, 0.0)], [(-D, 0.0)], side_posts)
    return lay


def walls():
    """Facade (the painted panels to the cap), Trim (posts, kick plate, cap, inside corners) and
    Panel (the R-panel from the cap up through the deck) round the whole room."""
    facade, trim, panel = Mesh("Facade"), Mesh("Trim"), Mesh("Panel")
    trim_z = geo.map_strip("trim", 2)
    P, F = C.POST, C.FACADE
    for name, (mat, along) in WALLS.items():
        faces, kicks, caps, posts = wall_layout()[name]
        f, t = Mesh("f"), Mesh("t")
        for a, b in faces:
            a, b = along(a, b)
            f.extend(pieces._facade(a, b))
        for a, b in kicks:
            a, b = along(a, b)
            geo.box(t, (a, -0.035, 0.0), (b, 0.0, C.KICK), geo.map_strip("diamond", 0), bevel=0.01)
        for a, b in caps:
            a, b = along(a, b)
            geo.box(t, (a, -C.CAP_PROUD, CAP), (b, F + 0.02, H + C.CAP_RISE),
                    geo.map_strip("trim", 0), bevel=0.012)
        for x in posts:
            x = along(x, x)[0]
            geo.box(t, (x - P, -C.POST_PROUD, 0.0), (x + P, F, H), trim_z, bevel=0.015,
                    segments=2, edges=lambda e, c, sz: True)
        a, b = along(*((-D, 0.0) if name in ("Left", "Right") else (-W2, W2)))
        p = pieces._panel(a, b, C.PANEL_PLANE, [])
        facade.extend(f, mat)
        trim.extend(t, mat)
        panel.extend(p, mat)
    # a steel column in each inside corner, floor to deck, over where two walls' edges meet
    s = C.INSIDE_PROUD + 0.1
    for cx, cy in ((-W2, 0.0), (W2, 0.0), (-W2, -D), (W2, -D)):
        x0, x1 = sorted((cx, cx - math.copysign(s, cx)))
        y0, y1 = sorted((cy, cy + (s if cy < -1 else -s)))
        geo.box(trim, (x0, y0, 0.0), (x1, y1, TOP), trim_z, bevel=0.015)
    return {"Facade": facade, "Trim": trim, "Panel": panel}


# --- the front: the storefront and its double door ----------------------------------------------

def storefront():
    """The glass front round the double door, in dark painted steel: jamb and middle mullions,
    the sidelights' bottom rails, the transom bar at the doors' head, the head under the cap;
    each door leaf's stiles and rails with a galvanized push bar; a diamond threshold and a
    rubber mat inside. Returns (Storefront, Glass)."""
    m, g = Mesh("Storefront"), Mesh("Glass")
    trim = geo.map_strip("trim")
    flat = geo.map_floor(8.0)  # the glass is a plain part: any UVs will do
    s0, s1 = K.STORE
    mw, md = K.MULLION
    y0, y1 = -D - md, -D            # the frame's outside and room side
    gy = (y0 + y1) / 2
    top = CAP
    jambs = [s0 + mw / 2, K.SIDE_MULLIONS[0], -K.DOOR - mw / 2, K.DOOR + mw / 2,
             K.SIDE_MULLIONS[1], s1 - mw / 2]
    for x in jambs:
        geo.box(m, (x - mw / 2, y0, 0.0), (x + mw / 2, y1, top), trim, bevel=0.012)
    # the head under the cap and the transom bar over the doors and sidelights
    geo.box(m, (s0, y0, top - mw), (s1, y1, top), trim, bevel=0.012)
    geo.box(m, (s0, y0, K.DOOR_H), (s1, y1, K.DOOR_H + mw), trim, bevel=0.012)
    # the sidelights' bottom rails, between their mullions
    bays = [(jambs[0] + mw / 2, jambs[1] - mw / 2), (jambs[1] + mw / 2, jambs[2] - mw / 2),
            (jambs[3] + mw / 2, jambs[4] - mw / 2), (jambs[4] + mw / 2, jambs[5] - mw / 2)]
    for a, b in bays:
        geo.box(m, (a, y0 + 0.02, 0.0), (b, y1 - 0.02, K.SILL_RAIL), trim, bevel=0.01)
        geo.box(g, (a, gy - K.GLASS_T / 2, K.SILL_RAIL), (b, gy + K.GLASS_T / 2, K.DOOR_H), flat)
    # the transom lights over everything
    for a, b in [(jambs[i] + mw / 2, jambs[i + 1] - mw / 2) for i in range(len(jambs) - 1)]:
        geo.box(g, (a, gy - K.GLASS_T / 2, K.DOOR_H + mw), (b, gy + K.GLASS_T / 2, top - mw), flat)
    # the two leaves, shut, meeting at x = 0
    ly0, ly1 = gy - 0.1, gy + 0.1
    pipe = geo.map_strip("pipe")
    for a, b in ((-K.DOOR, 0.0), (0.0, K.DOOR)):
        st = K.STILE
        geo.box(m, (a, ly0, 0.03), (a + st, ly1, K.DOOR_H), trim, bevel=0.01)
        geo.box(m, (b - st, ly0, 0.03), (b, ly1, K.DOOR_H), trim, bevel=0.01)
        geo.box(m, (a + st, ly0, K.DOOR_H - st), (b - st, ly1, K.DOOR_H), trim, bevel=0.01)
        geo.box(m, (a + st, ly0, 0.03), (b - st, ly1, K.DOOR_RAIL), trim, bevel=0.01)
        geo.box(g, (a + st, gy - K.GLASS_T / 2, K.DOOR_RAIL), (b - st, gy + K.GLASS_T / 2, K.DOOR_H - st), flat)
        # the push bar on the room side, on two standoffs
        z, r = K.PUSH_BAR
        bx0, bx1 = a + 0.55, b - 0.55
        out = ly1 + 0.22
        geo.sweep(m, [(bx0, ly1, z), (bx0, out, z), (bx1, out, z), (bx1, ly1, z)], r, 8, pipe)
    geo.box(m, (-K.DOOR, y0 - 0.1, 0.0), (K.DOOR, y1 + 0.1, 0.03), geo.map_strip("diamond", 0))
    geo.box(m, (-K.DOOR + 0.3, y1 + 0.15, 0.0), (K.DOOR - 0.3, y1 + 3.6, 0.035),
            geo.map_strip("rubber", 0), bevel=0.012)
    return m, g


# --- the counter and the shop's shelves ------------------------------------------------------

def counter():
    """The shop counter, to the left as you come in, facing into the room: a steel body with
    trim posts dividing its painted front (the CounterFront part), a diamond kick plate, a steel
    top with a lip over your side, a shelf on the clerk's side, a till and a service bell."""
    m, front = Mesh("Counter"), Mesh("CounterFront")
    trim, trim_z = geo.map_strip("trim"), geo.map_strip("trim", 2)
    fx, dep = K.COUNTER_FACE, K.COUNTER_DEPTH
    y0, y1 = K.COUNTER_Y
    top, slab = K.COUNTER_TOP, K.COUNTER_SLAB
    geo.box(m, (fx - dep - 0.05, y0 - 0.05, top - slab), (fx + K.COUNTER_LIP, y1 + 0.05, top),
            trim, bevel=0.02)
    for a, b in ((y0, y0 + 0.08), (y1 - 0.08, y1)):
        geo.box(m, (fx - dep, a, 0.0), (fx, b, top - slab), trim_z, bevel=0.01)
    geo.box(m, (fx, y0 + 0.08, 0.0), (fx + 0.035, y1 - 0.08, K.COUNTER_KICK),
            geo.map_strip("diamond", 1), bevel=0.008)
    n = int(round((y1 - y0) / 3.5))
    for k in range(n + 1):
        y = y0 + 0.04 + k * (y1 - y0 - 0.08) / n
        geo.box(m, (fx, y - 0.1, K.COUNTER_KICK), (fx + 0.06, y + 0.1, top - slab), trim_z, bevel=0.01)
    # the clerk's side: a shelf and its back rail
    geo.box(m, (fx - dep + 0.1, y0 + 0.08, 1.35), (fx - 0.1, y1 - 0.08, 1.42), trim, bevel=0.01)
    geo.box(m, (fx - 0.12, y0 + 0.08, 0.0), (fx - 0.06, y1 - 0.08, top - slab), trim_z)
    # the till: a steel base, its drawer, a sloped keyboard and a pole display
    rx, ry = K.REGISTER
    geo.box(m, (rx - 0.5, ry - 0.6, top), (rx + 0.5, ry + 0.6, top + 0.38), trim, bevel=0.03)
    geo.box(m, (rx + 0.5, ry - 0.5, top + 0.05), (rx + 0.53, ry + 0.5, top + 0.3),
            geo.map_strip("scuffed"), bevel=0.008)
    kb = Mesh("kb")
    geo.box(kb, (-0.38, -0.5, -0.06), (0.38, 0.5, 0.06), geo.map_strip("raw"), bevel=0.02)
    m.extend(kb, Matrix.Translation((rx + 0.1, ry, top + 0.5)) @ Matrix.Rotation(math.radians(-18), 4, "Y"))
    geo.cylinder(m, "z", (rx - 0.3, ry + 0.35, top + 0.6), 0.04, 0.5, 8, geo.map_strip("pipe"))
    geo.box(m, (rx - 0.36, ry + 0.05, top + 0.85), (rx - 0.24, ry + 0.65, top + 1.12),
            geo.map_strip("raw"), bevel=0.015)
    # the service bell, galvanized
    bx, by = K.BELL
    geo.cylinder(m, "z", (bx, by, top + 0.03), 0.2, 0.06, 12, geo.map_strip("pipe"))
    geo.cylinder(m, "z", (bx, by, top + 0.15), 0.16, 0.18, 12, geo.map_strip("pipe"), radius2=0.05)
    geo.cylinder(m, "z", (bx, by, top + 0.27), 0.025, 0.08, 6, geo.map_strip("pipe"))
    # the painted front, between the end panels, under the top
    mp = unit_parts.map_wall_along(H, 1)
    unit_parts.quad(front, (fx, y0 + 0.08, 0.0), (fx, y1 - 0.08, 0.0), (fx, y1 - 0.08, top - slab),
                    (fx, y0 + 0.08, top - slab), mp)
    return m, front


def shelves():
    """Two steel shelving units against the left wall behind the counter: channel uprights, a
    deck at each level with a front beam, crossed braces at the ends. The boxes on them are the
    game's (Specs.Stock, cloned from the boxes kit)."""
    m = Mesh("Shelves")
    chan_z = geo.map_strip("channel", 2)
    chan_y = geo.map_strip("channel", 1)
    trim = geo.map_strip("trim")
    raw = geo.map_strip("raw")
    p = K.SHELF_POST / 2
    back, front = -W2 + 0.08, -W2 + K.SHELF_DEPTH
    top = K.SHELF_LEVELS[-1]
    for y0, y1 in K.SHELF_RUNS:
        ys = (y0 + p, (y0 + y1) / 2, y1 - p)
        for y in ys:
            for x in (back + p, front - p):
                geo.box(m, (x - p, y - p, 0.0), (x + p, y + p, top + 0.04), chan_z)
        for z in K.SHELF_LEVELS:
            geo.box(m, (back, y0, z - K.SHELF_DECK), (front, y1, z), trim, bevel=0.01)
            geo.box(m, (front - 0.04, y0 + 0.02, z - 0.22), (front, y1 - 0.02, z - K.SHELF_DECK), chan_y)
        for y in (y0 + p, y1 - p):
            for za, zb in ((0.3, K.SHELF_LEVELS[2]), (K.SHELF_LEVELS[2], top)):
                for a, b in (((back + 2 * p, za), (front - 2 * p, zb)), ((front - 2 * p, za), (back + 2 * p, zb))):
                    geo.sweep(m, [(a[0], y, a[1]), (b[0], y, b[1])], 0.02, 4, raw)
    return m


# --- the cart rack ------------------------------------------------------------------------------

def rack_slots():
    n = int(round((K.RACK_X[1] - K.RACK_X[0]) / K.RACK_PITCH))
    y = (K.RACK_Y[0] + K.RACK_Y[1]) / 2
    return [(K.RACK_X[0] + K.RACK_PITCH * (k + 0.5), y) for k in range(n)]


def cart_rack():
    """A corral of galvanized pipe hoops against the front wall, a slot for each platform cart
    between them, a rail joining them at the back and a flange bolted under each foot."""
    m = Mesh("CartRack")
    pipe = geo.map_strip("pipe")
    r, h = K.RACK_PIPE, K.RACK_H
    y0, y1 = K.RACK_Y
    n = int(round((K.RACK_X[1] - K.RACK_X[0]) / K.RACK_PITCH))
    for k in range(n + 1):
        x = K.RACK_X[0] + k * K.RACK_PITCH
        b = 0.25
        geo.sweep(m, [(x, y0, 0.0), (x, y0, h - b), (x, y0 + b * 0.3, h - b * 0.3), (x, y0 + b, h),
                      (x, y1 - b, h), (x, y1 - b * 0.3, h - b * 0.3), (x, y1, h - b), (x, y1, 0.0)],
                  r, 8, pipe)
        for y in (y0, y1):
            geo.cylinder(m, "z", (x, y, 0.015), 0.16, 0.03, 8, pipe)
    geo.cylinder(m, "x", ((K.RACK_X[0] + K.RACK_X[1]) / 2, y0, K.RACK_RAIL_Z),
                 r, K.RACK_X[1] - K.RACK_X[0], 8, pipe)
    return m


# --- signs and paint ----------------------------------------------------------------------------

def signs():
    """The plates the game writes on (Specs.Cards): a number over each car, Everkeep's name over
    the shelves, a plate over the cart rack; each on four short standoffs."""
    m = Mesh("Signs")
    trim, raw = geo.map_strip("trim"), geo.map_strip("raw")
    nw, nh, nz = K.NUMBER
    t, off = K.PLATE_T, K.PLATE_OFF
    for x in K.bay_xs():
        geo.box(m, (x - nw / 2, -off - t, nz - nh / 2), (x + nw / 2, -off, nz + nh / 2), trim, bevel=0.02)
        for sx in (-1, 1):
            for sz in (-1, 1):
                cx, cz = x + sx * (nw / 2 - 0.3), nz + sz * (nh / 2 - 0.3)
                geo.box(m, (cx - 0.05, -off, cz - 0.05), (cx + 0.05, 0.0, cz + 0.05), raw)
    y, z, sw, sh = K.NAME_SIGN
    so = K.SIGN_OFF
    geo.box(m, (-W2 + so, y - sw / 2, z - sh / 2), (-W2 + so + t, y + sw / 2, z + sh / 2), trim, bevel=0.02)
    cz, cw, ch = K.CART_SIGN
    cx = (K.RACK_X[0] + K.RACK_X[1]) / 2
    geo.box(m, (cx - cw / 2, -D + so, cz - ch / 2), (cx + cw / 2, -D + so + t, cz + ch / 2), trim, bevel=0.02)
    for (a, b), (lo_x, hi_x) in (((y - sw / 2 + 0.5, y + sw / 2 - 0.5), (-W2, -W2 + so)),):
        for yy in (a, b):
            geo.box(m, (lo_x, yy - 0.05, z - 0.05), (hi_x, yy + 0.05, z + 0.05), raw)
    for xx in (cx - cw / 2 + 0.3, cx + cw / 2 - 0.3):
        geo.box(m, (xx - 0.05, -D, cz - 0.05), (xx + 0.05, -D + so, cz + 0.05), raw)
    return m


def clip(poly, x0, x1, y0, y1):
    """A 2D polygon clipped to the box x0..x1, y0..y1 (Sutherland-Hodgman)."""
    def cut(pts, inside, meet):
        out = []
        for i, p in enumerate(pts):
            q = pts[i - 1]
            if inside(p):
                if not inside(q):
                    out.append(meet(q, p))
                out.append(p)
            elif inside(q):
                out.append(meet(q, p))
        return out

    def at_x(x):
        return lambda a, b: (x, a[1] + (b[1] - a[1]) * (x - a[0]) / (b[0] - a[0]))

    def at_y(y):
        return lambda a, b: (a[0] + (b[0] - a[0]) * (y - a[1]) / (b[1] - a[1]), y)

    for inside, meet in ((lambda p: p[0] >= x0, at_x(x0)), (lambda p: p[0] <= x1, at_x(x1)),
                         (lambda p: p[1] >= y0, at_y(y0)), (lambda p: p[1] <= y1, at_y(y1))):
        poly = cut(poly, inside, meet)
        if not poly:
            return []
    return poly


def floor_paint():
    """The striped zone on the floor before each car: a yellow border and 45-degree stripes, the
    floor showing between them, as the landing sill and the car's sill are striped."""
    m = Mesh("FloorPaint")
    z, L = K.PAINT_Z, K.PAINT_LINE
    ow = K.OPENING[0] / 2
    y1 = -K.PAINT_GAP
    y0 = y1 - K.PAINT_DEPTH

    def flat(poly):
        geo.add_faces(m, [(x, y, z) for x, y in poly], [list(range(len(poly)))], geo.map_floor(8.0))

    for bx in K.bay_xs():
        x0, x1 = bx - ow, bx + ow
        for a in ((x0, y0, x1, y0 + L), (x0, y1 - L, x1, y1), (x0, y0 + L, x0 + L, y1 - L),
                  (x1 - L, y0 + L, x1, y1 - L)):
            flat([(a[0], a[1]), (a[2], a[1]), (a[2], a[3]), (a[0], a[3])])
        w, pitch = K.STRIPE
        span = (x1 - x0) + (y1 - y0)
        k = 0
        while k * pitch < span:
            u = x0 - (y1 - y0) + k * pitch
            poly = [(u, y0), (u + w * math.sqrt(2), y0), (u + w * math.sqrt(2) + (y1 - y0), y1),
                    (u + (y1 - y0), y1)]
            poly = clip(poly, x0 + L, x1 - L, y0 + L, y1 - L)
            if len(poly) >= 3:
                flat(poly)
            k += 1
    return m


def meshes():
    out = {"Floor": floor(), "Ceiling": ceiling()}
    out.update(walls())
    out["Storefront"], out["Glass"] = storefront()
    out["Counter"], out["CounterFront"] = counter()
    out["Shelves"] = shelves()
    out["CartRack"] = cart_rack()
    out["Signs"] = signs()
    out["FloorPaint"] = floor_paint()
    return out


def build(coll=None, for_export=True):
    """Every part as an object, with its material. Returns {part: object}."""
    objs = {}
    for name, mesh in meshes().items():
        ob = mesh.build(coll)
        if name in PLAIN:
            ob.data.materials.append(render.simple(f"plain_{name}", PLAIN[name], 0.4))
        else:
            ob.data.materials.append(bake.textured(TEXSET[name], TEX, for_export=for_export))
            if not for_export and name in TINT:
                ob["tint"] = (*render.hexc(TINT[name]), 1.0)
        objs[name] = ob
    return objs


def box_of(ob):
    vs = [v.co for v in ob.data.vertices]
    return (Vector([min(v[i] for v in vs) for i in range(3)]),
            Vector([max(v[i] for v in vs) for i in range(3)]))


def tris(ob):
    return sum(len(p.vertices) - 2 for p in ob.data.polygons)


def stage_export():
    check()
    reset()
    objs = build()
    rows = {}
    for name, ob in objs.items():
        lo, hi = box_of(ob)
        s = hi - lo
        rows[name] = dict(size=(s.x, s.z, s.y), centre=tuple((lo + hi) / 2), tris=tris(ob))
        assert rows[name]["tris"] < 20000, f"{name} has {rows[name]['tris']} triangles (Roblox's cap)"
    # the R-panel's ribs must stay behind the number plates' standoffs
    ribs = min(v.co.y for v in objs["Panel"].data.vertices
               if v.co.y > -1.0 and v.co.z > H and abs(v.co.x) < W2 - 1.0)
    assert -ribs < K.PLATE_OFF, f"the panel's ribs reach {ribs:.3f}, past the plates"
    os.makedirs(OUT, exist_ok=True)
    bpy.ops.object.select_all(action="DESELECT")
    for ob in objs.values():
        ob.select_set(True)
    bpy.context.view_layer.objects.active = objs["Floor"]
    bpy.ops.export_scene.fbx(
        filepath=FBX, use_selection=True, object_types={"MESH"},
        apply_scale_options="FBX_SCALE_UNITS", axis_forward="Z", axis_up="Y",
        use_mesh_modifiers=True, mesh_smooth_type="OFF", use_tspace=False,
        add_leaf_bones=False, bake_anim=False, path_mode="COPY", embed_textures=True)
    total = sum(r["tris"] for r in rows.values())
    print("FBX", FBX, os.path.getsize(FBX), f"{total} triangles", {n: r["tris"] for n, r in rows.items()},
          f"ribs at {ribs:.3f}")
    lua = os.path.join(K.ROOT, "src", "shared", "Lobby", "Specs.luau")
    os.makedirs(os.path.dirname(lua), exist_ok=True)
    K.write_luau(lua, rows, rack_slots())


# --- look sheets: the room lit, the climb's car standing in each bay ---------------------------

def elevator_kit():
    """The elevator's own build module (its spec, its finds kit), for standing its car in a bay."""
    mine = sys.modules.pop("spec")
    sys.path.insert(0, ELEVATOR)
    try:
        s = importlib.util.spec_from_file_location("elevator_build", os.path.join(ELEVATOR, "build.py"))
        mod = importlib.util.module_from_spec(s)
        s.loader.exec_module(mod)
    finally:
        sys.modules["elevator_spec_live"] = sys.modules.pop("spec", None)
        sys.modules["spec"] = mine
        sys.path.remove(ELEVATOR)
    return mod


def cars(coll):
    """The climb's car, gate folded open and lamp lit, in every bay (render copies of one build)."""
    ek = elevator_kit()
    objs = ek.build_all(coll)
    ek.glow(objs)
    for n in ("GatePicket", "GateLead", "GateStrap", "Note"):
        objs[n].hide_render = True
    gate = ek.gate(objs, 0.0)
    keep = [o for n, o in objs.items() if n not in ("GatePicket", "GateLead", "GateStrap", "Note")]
    keep += gate
    for x in K.bay_xs():
        at = Matrix.Translation((x, 0.0, 0.0))
        for o in keep:
            c = o.copy()
            coll.objects.link(c)
            c.matrix_world = at @ o.matrix_world
        ld = bpy.data.lights.new("car_lamp", "POINT")
        ld.energy = 260.0
        ld.color = (1.0, 0.8, 0.58)
        ld.shadow_soft_size = 0.25
        lo = bpy.data.objects.new("car_lamp", ld)
        coll.objects.link(lo)
        lo.location = (x + E.LAMP[0], E.LAMP[1], E.CAR_H - 0.56)
    for o in keep:
        o.hide_render = True


def fixtures(coll):
    """The corridor's hall light at each of Specs.Lights, lit, its eye dark (the lobby is safe)."""
    lens = render.emissive("lens_lit", (0.9, 0.95, 0.93), 6.0)
    eye = render.simple("eye_dark", (0.12, 0.12, 0.12), 0.4)
    for x, y in K.fixtures():
        for ob in corridor.build_fixture(0.0, coll, for_export=False, lens=lens, eye=eye).values():
            ob.matrix_world = Matrix.Translation((x, y, 0.0)) @ ob.matrix_world
        ld = bpy.data.lights.new("hall", "AREA")
        ld.shape = "RECTANGLE"
        ld.size, ld.size_y = 3.8, 0.44
        ld.energy = 520.0
        ld.spread = math.radians(110)
        ld.color = (0.86, 0.95, 0.93)
        lo = bpy.data.objects.new("hall", ld)
        lo.location = (x, y, C.LENS_Z - C.LENS_THICK / 2 - 0.01)
        coll.objects.link(lo)


def text(body, at, normal, height, colour, coll, width=None):
    """Words on a plate: Builder Sans Bold, as the game writes them, facing `normal`."""
    cu = bpy.data.curves.new("words", "FONT")
    cu.body = body
    cu.font = bpy.data.fonts.load(E.KEY_FONT, check_existing=True)
    cu.align_x, cu.align_y = "CENTER", "CENTER"
    cu.size = height
    ob = bpy.data.objects.new("words", cu)
    coll.objects.link(ob)
    yaw = math.atan2(normal[1], normal[0]) + math.pi / 2
    ob.matrix_world = Matrix.Translation(at) @ Matrix.Rotation(yaw, 4, "Z") @ Matrix.Rotation(math.pi / 2, 4, "X")
    if width:
        bpy.context.view_layer.update()
        w = ob.dimensions.x
        if w > width:
            ob.scale = (width / w,) * 3
    ob.data.materials.append(render.emissive("words", colour, 1.6))
    return ob


def dressing(coll):
    """The game's writing on the cards and the boxes on the shelves (render stand-ins)."""
    for name, c, (w, h), n in K.cards():
        label = name[3:] if name.startswith("Bay") else {"Name": "EVERKEEP SELF STORAGE", "Carts": "CARTS"}[name]
        text(label, Vector(c) + Vector(n) * 0.01, n, h * (0.95 if name.startswith("Bay") else 0.62),
             (0.92, 0.9, 0.84), coll, w)
    for kind, x, y, z, turn in K.stock():
        sx, sy, sz = K.BOX_SIZE[kind]
        render.box_prop(coll, (x, y, z), (sy, sx, sz), math.radians(90 + turn))


def stage_renders():
    reset()
    render.setup(96, (1560, 720))
    coll = bpy.context.scene.collection
    objs = build(coll, for_export=False)
    glass = objs["Glass"]
    glass.data.materials.clear()
    gm = render.simple("glass", (0.05, 0.06, 0.065), 0.05, 0.0)
    gm.node_tree.nodes["Principled BSDF"].inputs["Transmission Weight"].default_value = 0.85
    glass.data.materials.append(gm)
    cars(coll)
    fixtures(coll)
    dressing(coll)
    # the porch light outside over the door (Lobby.Porch): a sodium pool on the concrete
    pd = bpy.data.lights.new("porch", "SPOT")
    pd.energy, pd.color = 900.0, (1.0, 0.67, 0.38)
    pd.spot_size = math.radians(100)
    po = bpy.data.objects.new("porch", pd)
    coll.objects.link(po)
    po.location = (0.0, -K.DEPTH - 1.5, 10.5)
    po.rotation_euler = (math.radians(-31), 0.0, 0.0)  # down, and out across the apron
    render.world((0.004, 0.0045, 0.006), 1.0)
    os.makedirs(SHEETS, exist_ok=True)
    shots = [
        # where you load in: just inside the door, at a player's eyes, facing the six cars
        ("spawn", (0.0, -42.0, 4.6), (0.0, 0.0, 4.4), 14.0, 0.5),
        # one car up close: its number, the striped zone, the post between
        ("bay", (3.0, -15.0, 4.8), (9.0, 0.0, 5.6), 20.0, 0.4),
        # from the cars back to the way in: the storefront, the counter, the rack
        ("door", (4.0, -6.0, 5.2), (0.0, -48.0, 4.2), 14.0, 0.5),
        # the counter and the shelves behind it
        ("counter", (-38.0, -20.0, 5.2), (-56.0, -36.0, 3.6), 20.0, 0.4),
        # the cart rack, empty
        ("rack", (20.0, -34.0, 5.0), (28.0, -46.0, 1.2), 22.0, 0.4),
    ]
    for name, loc, target, lens, ex in shots:
        cam = render.camera(loc, target, lens=lens)
        render.shoot(cam, os.path.join(SHEETS, f"lobby-{name}.png"), exposure=ex)
    # the plan, from above with the deck lifted off
    objs["Ceiling"].hide_render = True
    objs["Panel"].hide_render = True
    for o in bpy.data.objects:
        if o.name.startswith(("Housing", "Diffuser", "Eye", "hall")) or o.type == "LIGHT" and o.name.startswith("hall"):
            o.hide_render = True
    sun = bpy.data.lights.new("plan_sun", "SUN")
    sun.energy = 2.0
    so = bpy.data.objects.new("plan_sun", sun)
    coll.objects.link(so)
    so.rotation_euler = (math.radians(20), math.radians(10), 0.0)
    cam = render.camera((0.0, -30.0, 120.0), (0.0, -26.0, 0.0), lens=30.0)
    render.shoot(cam, os.path.join(SHEETS, "lobby-plan.png"), exposure=0.0)


STAGES = {"export": stage_export, "renders": stage_renders}

if __name__ == "__main__":
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    ap = argparse.ArgumentParser()
    ap.add_argument("--stage", choices=list(STAGES), required=True)
    STAGES[ap.parse_args(argv).stage]()
    print("DONE")
