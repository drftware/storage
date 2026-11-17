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
from types import SimpleNamespace

HERE = os.path.dirname(os.path.abspath(__file__))
UNIT = os.path.join(HERE, "..", "unit")
CORRIDOR = os.path.abspath(os.path.join(HERE, "..", "corridor"))
ELEVATOR = os.path.abspath(os.path.join(HERE, "..", "elevator"))
HOME = os.path.abspath(os.path.join(HERE, "..", "home"))
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

sys.path.append(HOME)  # last: the home's modules share no names with the unit's or corridor's
from carpentry import plaster_uv, wood_box  # noqa: E402
import front as home_front  # noqa: E402  the home's kit (art/home): its front and furnishings
import furnish as home_furnish  # noqa: E402
import looks  # noqa: E402  the home's sets


def load(name, path):
    s = importlib.util.spec_from_file_location(name, path)
    mod = importlib.util.module_from_spec(s)
    s.loader.exec_module(mod)
    return mod


K = load("lobby_spec", os.path.join(HERE, "spec.py"))
E = load("elevator_spec", K.ELEVATOR_SPEC)

OUT = os.path.join(HERE, "out")
TEX = os.path.join(UNIT, "out", "textures")
HOME_TEX = os.path.join(HOME, "out", "textures")  # the home's sets (art/home: build those first)
HOME_SETS = set(looks.LOOKS) | set(looks.SIZES)
bake.TINTED.update(looks.TINTED)  # the paint is the part's Color, as the unit's Facade
SHEETS = os.path.join(K.ROOT, "art", "sheets")
FBX = os.path.join(OUT, "Lobby.fbx")
TEXSET = {"Floor": "Concrete", "Boards": "Wood", "Deck": "TrimSheet", "Joists": "TrimSheet",
          "Ceiling": "Plaster", "Facade": "Facade", "Trim": "TrimSheet", "Panel": "Partition",
          "Walls": "Plaster", "WallsUpper": "Plaster", "Woodwork": "Wood",
          "UnitWallsLeft": "Plaster", "UnitWallsRight": "Plaster", "UnitTops": "Plaster",
          "Storefront": "TrimSheet", "Counter": "TrimSheet",
          "CounterFront": "Facade", "Shelves": "TrimSheet", "CartRack": "TrimSheet",
          "Signs": "TrimSheet"}
# Untextured: imported without a SurfaceAppearance, so the game sets their Material and Color.
# These are only the colours they import with.
PLAIN = {"Glass": (0.16, 0.19, 0.2), "FloorPaint": (0.84, 0.62, 0.1), "Lamps": (1.0, 0.9, 0.76),
         "Runner": (0.36, 0.13, 0.1)}
# The colours in the sheets (the game's are Lobby.Paint): the climb's teal on the bay wall, a
# home's sage below the rail and warm cream above it, a soft white ceiling, the units warm white.
TINT = {"Facade": "#2F6466", "CounterFront": "#CFCAC0", "Walls": "#93A68F",
        "WallsUpper": "#E6DDCC", "Ceiling": "#F5F2EB", "UnitWallsLeft": "#E8DFCF",
        "UnitWallsRight": "#E8DFCF", "UnitTops": "#F1EBDF"}

H = C.WALL_H                         # the walls' cap height, as the units' and the corridor's
CAP = H - C.CAP_DROP                 # the cap's underside: the facade stops there
TOP = C.DECK + C.RIB_DEPTH + C.DECK_COVER  # the panel runs up to the deck's top
W2, D = K.WIDTH / 2, K.DEPTH
# A unit slot as the unit kit's parts read a spec (art/unit/parts.py): every slot is built at XL
XL = SimpleNamespace(width=K.SLOT_WIDTH, depth=K.SLOT_DEPTH, wall_height=K.UNIT_WALL,
                     facade=K.UNIT_FACADE)


def reset():
    bpy.ops.wm.read_factory_settings(use_empty=True)


def check():
    """The lobby must fit the climb's own elevator and the corridor's light exactly."""
    assert tuple(K.OPENING) == tuple(E.OPENING), "the bays' hole isn't the elevator's"
    assert K.WALL == E.WALL and K.JAMB == E.JAMB and K.HEADER == E.HEADER, "not the elevator's wall"
    assert K.BASE == K.HOME.BASE and tuple(K.RAIL) == tuple(K.HOME.RAIL), "the home front's trim isn't the room's"
    assert K.DOOR_SIZE == K.HOME.DOOR_SIZE, "the home front isn't the gap's door"
    assert abs(E.KEYPAD[0] + E.BACKPLATE[0] / 2 - K.KEYPAD_REACH) < 1e-6, "the keypad moved"
    gap = K.BAY_PITCH - K.OPENING[0] / 2 - K.JAMB
    assert K.KEYPAD_REACH < gap - 0.5, "a car's keypad runs into the next car's frame"
    assert K.DECK == C.DECK, "the lobby's deck isn't the corridor's: the hall light hangs wrong"
    for x, _ in K.fixtures():
        off = (x % K.JOIST_EVERY) - K.JOIST_EVERY / 2
        assert abs(off) < 1e-6, f"a light at {x} isn't midway between joists"
    xs = K.bay_xs()
    assert all(abs(x % K.JOIST_EVERY - K.JOIST_EVERY / 2) < 1e-6 for x in xs), "a joist over a car"
    # the units' slots wear the climb's unit and corridor numbers, so the M's front fits each gap
    assert K.UNIT_WALL == C.WALL_H and K.UNIT_FACADE == C.FACADE, "the slots aren't the units' walls"
    assert abs(K.HANG - (C.WALL_H - C.CHANNEL_DROP)) < 1e-9, "the bulb doesn't hang from the channel"
    assert K.DOOR_GAP == C.UNIT.width, "the gap isn't the M unit's front"
    lines = K.slot_lines()
    for y in K.slot_ys():
        near = min(abs(y - ln) for ln in lines)
        assert near - K.DOOR_GAP / 2 > 2 * C.POST, "a gap's half post runs into a partition's post"


# --- the shell: floor, deck, walls ------------------------------------------------------------

def floor():
    """The climb's concrete where the cars are (the landing strip) and outside the front door;
    the home's oak planks over the rest of the room and in the units, running toward the cars.
    UVs start on a texture edge at the room's corner, so joints and planks run square to the walls."""
    m, boards = Mesh("Floor"), Mesh("Boards")
    uv = lambda vs, n: [((v.x + W2) / C.TILE, (v.y + D) / C.TILE) for v in vs]
    geo.box(m, (-W2, K.LANDING, -C.FLOOR_SKIRT), (W2, 0.0, 0.0), uv)
    geo.box(m, (-W2, -D - K.APRON, -C.FLOOR_SKIRT), (W2, -D, 0.0), uv)
    geo.box(boards, (-W2, -D, -C.FLOOR_SKIRT), (W2, K.LANDING, 0.0), uv)
    # under the units, out to their back walls (as the Floor collider)
    lines, back = K.slot_lines(), W2 + K.SLOT_DEPTH + K.OUTER
    for side in (-1, 1):
        x0, x1 = sorted((side * W2, side * back))
        geo.box(boards, (x0, lines[0], -C.FLOOR_SKIRT), (x1, lines[-1], 0.0), uv)
    return {"Floor": m, "Boards": boards}


def ceiling(wood):
    """Over the cars' landing strip the climb's steel deck on its open-web joists (one every 6
    across, each car's middle between two). Over the home a finished plaster ceiling (Ceiling),
    dropping to a bulkhead where it meets the deck, on wood beams: two front to back and one across
    on every unit's partition line, so each beam bay holds a pair of units and its round lamps."""
    deck, joists, ceil = Mesh("Deck"), Mesh("Joists"), Mesh("Ceiling")
    pieces.deck(deck, -W2, W2, K.LANDING, 0.0)
    j = pieces.joist(-K.LANDING)
    turn = Matrix.Rotation(math.radians(90), 4, "Z")
    for x in K.joist_xs():
        joists.extend(j, Matrix.Translation((x, K.LANDING / 2, 0.0)) @ turn)
    bd, drop = K.BULKHEAD
    edge = K.LANDING - bd
    pu = plaster_uv()
    geo.box(ceil, (-W2, -D, K.CEIL), (W2, edge, K.CEIL + 0.1), pu)
    geo.box(ceil, (-W2, edge, K.CEIL - drop), (W2, K.LANDING, TOP), pu)
    bw, bdep = K.BEAM
    for y in K.slot_lines():
        if y < K.LANDING - 1.0:
            wood_box(wood, (-W2, y - bw / 2, K.CEIL - bdep), (W2, y + bw / 2, K.CEIL), 3)
    for x in K.BEAM_XS:  # a touch shallower, so they butt into the cross beams as joinery does
        wood_box(wood, (x - bw / 2, -D, K.CEIL - bdep + 0.06), (x + bw / 2, edge, K.CEIL), 3)
    return {"Deck": deck, "Joists": joists, "Ceiling": ceil}


def lamps():
    """The round lamps, flush drums under the ceiling: a plain part the game lights warm."""
    m = Mesh("Lamps")
    d, hang = K.LAMP
    for x, y in K.lamps():
        geo.cylinder(m, "z", (x, y, K.CEIL - hang / 2), d / 2, hang, segs=20, smooth=False)
    return m


def runner():
    """The runner rug from the door mat to the landing strip: a plain part the game makes Fabric."""
    m = Mesh("Runner")
    w, y0, y1 = K.RUNNER
    geo.box(m, (-w / 2, y0, 0.0), (w / 2, y1, 0.03), geo.map_floor(8.0))
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
    # the side walls: facade, kick plate and cap between the units' gaps (the M unit standing in a
    # gap brings its own, its cap level with the wall's); a full post on each partition's line and
    # a half post on the lobby side of each gap's edge, which the M's half pilaster makes whole
    g = K.DOOR_GAP / 2
    edges = [-D] + [e for y in K.slot_ys() for e in (y - g, y + g)] + [0.0]
    spans = [(edges[i], edges[i + 1]) for i in range(0, len(edges), 2)]
    halves = [h for y in K.slot_ys() for h in ((y - g - C.POST, y - g), (y + g, y + g + C.POST))]
    for name in ("Left", "Right"):
        lay[name] = (spans, spans, spans, K.slot_lines(), halves)
    return lay


def walls(wood):
    """The bay wall keeps the climb's: Facade (the painted panels to the cap), Trim (posts, kick
    plate, cap) and Panel (the R-panel from the cap up through the deck). The home's three walls
    are plaster in two paints, Walls below the rail and WallsUpper above it to the ceiling, with a
    wood baseboard and a wood rail where the units' caps run (Woodwork)."""
    facade, trim, panel = Mesh("Facade"), Mesh("Trim"), Mesh("Panel")
    lower, upper = Mesh("Walls"), Mesh("WallsUpper")
    pu = plaster_uv()
    rh, rp = K.RAIL
    trim_z = geo.map_strip("trim", 2)
    P, F = C.POST, C.FACADE
    for name, (mat, along) in WALLS.items():
        faces, kicks, caps, posts, *halves = wall_layout()[name]
        if name != "Bay":
            lo_m, up_m, w_m = Mesh("lo"), Mesh("up"), Mesh("w")
            for a, b in faces:
                a, b = along(a, b)
                geo.box(lo_m, (a, 0.0, 0.0), (b, F, H), pu)
            for a, b in kicks:
                a, b = along(a, b)
                wood_box(w_m, (a, -0.07, 0.0), (b, 0.0, K.BASE), 5)
            for a, b in caps:
                a, b = along(a, b)
                wood_box(w_m, (a, -rp, H - rh), (b, F, H + 0.02), 5)
            a, b = along(*((-D, 0.0) if name in ("Left", "Right") else (-W2, W2)))
            geo.box(up_m, (a, 0.0, H), (b, F, K.CEIL + 0.1), pu)
            lower.extend(lo_m, mat)
            upper.extend(up_m, mat)
            wood.extend(w_m, mat)
            continue
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
        for a, b in (halves[0] if halves else []):
            a, b = along(a, b)
            geo.box(t, (a, -C.POST_PROUD, 0.0), (b, F, H), trim_z, bevel=0.015,
                    segments=2, edges=lambda e, c, sz: True)
        a, b = along(*((-D, 0.0) if name in ("Left", "Right") else (-W2, W2)))
        p = pieces._panel(a, b, C.PANEL_PLANE, [])
        facade.extend(f, mat)
        trim.extend(t, mat)
        panel.extend(p, mat)
    # a steel column in each inside corner, floor to deck, over where two walls' edges meet
    s = C.INSIDE_PROUD + 0.1
    for cx, cy in ((-W2, 0.0), (W2, 0.0)):  # the bay wall's corners: the home's need none
        x0, x1 = sorted((cx, cx - math.copysign(s, cx)))
        y0, y1 = sorted((cy, cy + (s if cy < -1 else -s)))
        geo.box(trim, (x0, y0, 0.0), (x1, y1, TOP), trim_z, bevel=0.015)
    return {"Facade": facade, "Trim": trim, "Panel": panel, "Walls": lower, "WallsUpper": upper}


def slot_frame(side, y):
    """A unit slot's frame (the unit kit's: origin on the floor at the doorway's outer face, the
    floor toward -y, the unit toward +y) for the slot at `y` on side -1 (left) or +1 (right)."""
    mat, along = WALLS["Left" if side < 0 else "Right"]
    return mat @ Matrix.Translation((along(y, y)[0], 0.0, 0.0))


def unit_shells(wood):
    """The units' shells round each front, a home's: smooth painted plaster partitions on every
    slot line (shared by the units either side), each slot's back wall and the inside of the side
    wall either side of its gap, a flat plaster ceiling at the walls' top (UnitTops), and a wood
    baseboard round the inside. Built in each slot's frame (`slot_frame`)."""
    out = {"UnitWallsLeft": Mesh("UnitWallsLeft"), "UnitWallsRight": Mesh("UnitWallsRight"),
           "UnitTops": Mesh("UnitTops")}
    w2, g, H, F = XL.width / 2, K.DOOR_GAP / 2, XL.wall_height, XL.facade
    d, t, b, pu = XL.depth, 0.125, K.BASE, plaster_uv()

    def part(x):
        m = Mesh("partition")
        geo.box(m, (x - t, F, 0.0), (x + t, d, H), pu)
        return m

    shell, top, trim = Mesh("shell"), Mesh("top"), Mesh("trim")
    geo.box(shell, (-w2, d - t, 0.0), (w2, d + t, H), pu)  # the back wall
    for x0, x1 in ((-w2, -g), (g, w2)):
        geo.box(shell, (x0, F, 0.0), (x1, F + 0.04, H), pu)  # the side wall's inside
        wood_box(trim, (x0 + (t if x0 < 0 else 0.0), F + 0.04, 0.0),
                 (x1 - (t if x1 > 0 else 0.0), F + 0.1, b), 5)
    geo.box(top, (-w2, F, H), (w2, d, H + 0.15), pu)
    wood_box(trim, (-w2 + t, d - t - 0.06, 0.0), (w2 - t, d - t, b), 5)
    wood_box(trim, (-w2 + t, F + 0.1, 0.0), (-w2 + t + 0.06, d - t - 0.06, b), 5)
    wood_box(trim, (w2 - t - 0.06, F + 0.1, 0.0), (w2 - t, d - t - 0.06, b), 5)
    near, far = part(-w2), part(w2)
    for side, name in ((-1, "UnitWallsLeft"), (1, "UnitWallsRight")):
        ys = K.slot_ys()
        for k, y in enumerate(ys):
            at = slot_frame(side, y)
            out[name].extend(shell, at)
            out[name].extend(near, at)
            # the line the -x partitions leave: the cars' end on the left, the front on the right
            if k == (len(ys) - 1 if side < 0 else 0):
                out[name].extend(far, at)
            out["UnitTops"].extend(top, at)
            wood.extend(trim, at)
    return out


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
    # a name card over each unit's door, off the R-panel on standoffs as the bays' numbers are
    kw, kh, kz = K.CARD
    for _, side, y in K.slots():
        x0, x1 = sorted((side * (W2 - off), side * (W2 - off - t)))
        geo.box(m, (x0, y - kw / 2, kz - kh / 2), (x1, y + kw / 2, kz + kh / 2), trim, bevel=0.02)
        s0, s1 = sorted((side * W2, side * (W2 - off)))
        for sy in (-1, 1):
            for sz in (-1, 1):
                cy, cz2 = y + sy * (kw / 2 - 0.3), kz + sz * (kh / 2 - 0.3)
                geo.box(m, (s0, cy - 0.05, cz2 - 0.05), (s1, cy + 0.05, cz2 + 0.05), raw)
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
    wood = Mesh("Woodwork")
    out = floor()
    out.update(ceiling(wood))
    out.update(walls(wood))
    out.update(unit_shells(wood))
    out["Woodwork"] = wood
    out["Lamps"] = lamps()
    out["Runner"] = runner()
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
        if name == "Lamps" and not for_export:
            ob.data.materials.append(render.emissive("lamp_lit", PLAIN[name], 5.0))
        elif name in PLAIN:
            ob.data.materials.append(render.simple(f"plain_{name}", PLAIN[name], 0.9 if name == "Runner" else 0.4))
        else:
            tex = HOME_TEX if TEXSET[name] in HOME_SETS else TEX
            ob.data.materials.append(bake.textured(TEXSET[name], tex, for_export=for_export))
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


def unit_kit():
    """The unit's own build module (its Unit and Spec), for standing the M's front in each gap."""
    mine = sys.modules.pop("spec")
    here = os.path.abspath(UNIT)
    try:
        s = importlib.util.spec_from_file_location("unit_build", os.path.join(here, "build.py"))
        mod = importlib.util.module_from_spec(s)
        s.loader.exec_module(mod)
    finally:
        sys.modules["unit_spec_live"] = sys.modules.pop("spec", None)
        sys.modules["spec"] = mine
        if sys.path and sys.path[0] == here:
            sys.path.pop(0)  # it put its folder first; the corridor's `spec` must stay ahead
    return mod


SHUT = (3, 10)  # in the sheets these units are shut and locked; the rest stand open
NAMES = ("Maya", "Jax", "Rowan", "Kit", "Theo", "Ivy", "Sam", "Nova", "Eli", "Pip", "Ash", "Zoe")
FINDS = (((-5.5, 24.0, 0.0), "Medium", 12.0), ((-3.2, 25.2, 0.0), "Small", -8.0),
         ((-5.0, 24.6, 1.8), "Small", 20.0), ((6.8, 20.0, 0.0), "Medium", -4.0),
         ((2.0, 27.0, 0.0), "Medium", 3.0))  # stand-in boxes in each open unit (unit frame)


# The sheets' paints for the home's kit (the game's are b3's): the front's wall the room's sage,
# its inside the units' warm white, a clay door, cream pots, a stone planter, a mustard beanbag.
HOME_TINT = {"Facade": TINT["Walls"], "FacadeBack": TINT["UnitWallsLeft"], "HomeDoor": "#B5684E",
             "Pot": "#E9E2D3", "Planter": "#D8CCB6", "Beanbag": "#B98A3C", "LampShade": "#F1E8D6",
             "JobBox": "#6A8A93", "JobBoxLid": "#6A8A93"}


def home_texsets():
    """Every home part's texture set (None: plain), as art/home/build.py exports them."""
    out = {n: home_front.TEXSET.get(n) for n in home_front.BUILDERS}
    out.update(home_furnish.TEXSET)
    out.update({n: "HomeDoor" for n in home_front.DOOR_PARTS})
    return out


def home_material(name, set_name):
    if set_name is None:
        if name == "Lamp":
            return render.emissive("unit_lamp_lit", (1.0, 0.9, 0.76), 5.0)
        return render.simple(f"plain_{name}", home_front.PLAIN[name], 0.4)
    tex = HOME_TEX if set_name in HOME_SETS else TEX
    return bake.textured(set_name, tex, for_export=False)


def home_parts(coll, meshes, sets):
    """Render objects for the home's meshes, hidden: the originals the sheets copy into place."""
    out = {}
    for name, mesh in meshes.items():
        ob = mesh.build(coll)
        ob.data.materials.append(home_material(name, sets[name]))
        tint = HOME_TINT.get(name)
        if tint:
            ob["tint"] = (*render.hexc(tint), 1.0)
        ob.hide_render = True
        out[name] = ob
    return out


def place(coll, objs, at):
    for o in objs:
        c = o.copy()
        c.hide_render = False
        coll.objects.link(c)
        c.matrix_world = at @ o.matrix_world


def furnishings(coll):
    """The home's furnishings, built once and hidden: {piece kind: [its objects]}."""
    sets = home_texsets()
    objs = home_parts(coll, home_furnish.meshes(), sets)
    objs["LampShade"].data.materials.clear()  # lit from inside: the cloth glows warm
    objs["LampShade"].data.materials.append(render.emissive("shade_lit", render.hexc(HOME_TINT["LampShade"]), 1.2))
    out = {kind: [objs[n] for n in names] for kind, names in K.HOME.PIECES.items()}
    # the mirror's glass, a real mirror here (in the game it's MirrorView's picture, D-280)
    gw, gh = K.HOME.MIRROR_GLASS
    _, _, mid, _, _ = K.HOME.mirror_box()
    y = K.HOME.mirror_glass_y()
    gm = Mesh("MirrorGlass")
    geo.box(gm, (-gw / 2, y, mid - gh / 2), (gw / 2, y + 0.04, mid + gh / 2))
    glass = gm.build(coll)
    glass.data.materials.append(render.simple("mirror_glass", (0.9, 0.92, 0.93), 0.02, 1.0))
    glass.hide_render = True
    out["Mirror"].append(glass)
    return out


def mirror_frame(at):
    """Where a unit's mirror stands (Specs.Mirror): its foot, turned to look across the unit,
    leaning back onto the left wall."""
    x, y = K.HOME.mirror_at()
    return (at @ Matrix.Translation((x, y, 0.0)) @ Matrix.Rotation(math.radians(-90), 4, "Z")
            @ Matrix.Rotation(math.radians(-K.HOME.MIRROR_LEAN), 4, "X"))


def rail_frame(at):
    """Where a unit's clothes rail stands (Specs.Rail): along the mirror's wall, past it, turned as
    the mirror is so its front looks across the unit."""
    x, y = K.HOME.rail_at()
    return at @ Matrix.Translation((x, y, 0.0)) @ Matrix.Rotation(math.radians(-90), 4, "Z")


def turned(x, y, turn, at=None):
    m = Matrix.Translation((x, y, 0.0)) @ Matrix.Rotation(math.radians(turn), 4, "Z")
    return at @ m if at is not None else m


def home_fronts(coll, pieces):
    """The home front in every gap (art/home/front.py) on the M's door rig, its door wearing
    HomeDoor in clay, open or shut by SHUT; in each unit its round lamp lit and, in the open ones,
    the starter set (the rug, the beanbag, the floor lamp glowing) and stand-in finds."""
    uk = unit_kit()
    sub = uk.collection("UnitFront", coll)
    unit = uk.Unit(uk.Spec(K.DOOR_SIZE), sub)
    dk = [unit.objs[n] for n in ("BottomBar", "LatchBolt", "Padlock", "Hardware", "Drum", "NumberPlate")]
    bake.copy_atlas(dk, os.path.join(UNIT, "out", K.DOOR_SIZE, "unit.blend"))
    door = home_material("CurtainClosed", "HomeDoor")
    for name in home_front.DOOR_PARTS:
        ob = unit.objs[name]
        ob.data.materials.clear()
        ob.data.materials.append(door)
        ob["tint"] = (*render.hexc(HOME_TINT["HomeDoor"]), 1.0)
    chain = list(unit.make_chain().objects)
    for o in chain:
        o["tint"] = unit.objs["Slat_A"]["tint"]
    sets = home_texsets()
    fixed = list(home_parts(sub, home_front.meshes(unit.spec), sets).values())
    fixed += [unit.objs[n] for n in ("BottomBar", "LatchBolt", "Hardware", "Drum")]
    for shut in (False, True):
        unit.pose(0.0 if shut else unit.spec.travel, locked=shut)
        bpy.context.view_layer.update()
        show = fixed + ([unit.objs["CurtainClosed"]] if shut else chain)
        for n, side, y in K.slots():
            if (n in SHUT) == shut:
                place(coll, show, slot_frame(side, y))
    for o in list(unit.objs.values()) + chain:
        o.hide_render = True
    d, hang = K.HOME.LAMP
    lamp = home_front.lamp_at(unit.spec)
    for n, side, door_at, _, _, _ in K.slot_rows():
        at = slot_frame(side, door_at[1])
        ld = bpy.data.lights.new("unit_lamp", "AREA")
        ld.shape, ld.size = "DISK", d * 0.9
        ld.energy, ld.color = 1100.0, (1.0, 0.86, 0.7)
        lo = bpy.data.objects.new("unit_lamp", ld)
        coll.objects.link(lo)
        lo.location = at @ Vector((lamp[0], lamp[1], lamp[2] - hang / 2 - 0.02))
        if n in SHUT:
            continue
        place(coll, pieces["Mirror"], mirror_frame(at))
        place(coll, pieces["Rail"], rail_frame(at))
        for kind, (x, y), turn in K.HOME.STARTER:
            place(coll, pieces[kind], turned(x, y, turn, at))
            if kind == "FloorLamp":
                pd = bpy.data.lights.new("floor_lamp", "POINT")
                pd.energy, pd.color, pd.shadow_soft_size = 140.0, (1.0, 0.78, 0.5), 0.3
                po = bpy.data.objects.new("floor_lamp", pd)
                coll.objects.link(po)
                stem = K.HOME.FLOOR_LAMP[1]
                po.location = at @ Vector((x, y, stem + 0.2))
        yaw = math.atan2(at[1][0], at[0][0])
        for (lx, ly, lz), kind, turn in FINDS:
            sx, sy, sz = K.BOX_SIZE[kind]
            render.box_prop(coll, tuple(at @ Vector((lx, ly, lz))), (sy, sx, sz), yaw + math.radians(turn))


def dress_floor(coll, pieces):
    """The plants, benches and planters round the floor (K.dressing)."""
    for kind, x, y, turn in K.dressing():
        place(coll, pieces[kind], turned(x, y, turn))


def fixtures(coll):
    """The corridor's hall light at each of Specs.Lights, lit, its eye dark (the lobby is safe)."""
    lens = render.emissive("lens_lit", (0.9, 0.95, 0.93), 6.0)
    eye = render.simple("eye_dark", (0.12, 0.12, 0.12), 0.4)
    for x, y in K.fixtures():
        if y < K.LANDING:
            continue  # the home has its round lamps (below); the hall lights keep to the cars
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
    d, hang = K.LAMP
    for x, y in K.lamps():
        ld = bpy.data.lights.new("lamp", "AREA")
        ld.shape, ld.size = "DISK", d * 0.9
        ld.energy, ld.color = 800.0, (1.0, 0.88, 0.74)
        lo = bpy.data.objects.new("lamp", ld)
        lo.location = (x, y, K.CEIL - hang - 0.02)
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
        label = (name[3:] if name.startswith("Bay") else NAMES[int(name[4:]) - 1] if name.startswith("Unit")
                 else {"Name": "EVERKEEP SELF STORAGE", "Carts": "CARTS"}[name])
        text(label, Vector(c) + Vector(n) * 0.01, n, h * (0.95 if name.startswith(("Bay", "Unit")) else 0.62),
             (0.92, 0.9, 0.84), coll, w)
    for kind, x, y, z, turn in K.stock():
        sx, sy, sz = K.BOX_SIZE[kind]
        render.box_prop(coll, (x, y, z), (sy, sx, sz), math.radians(90 + turn))


def stage_renders(only=None):
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
    pieces = furnishings(coll)
    home_fronts(coll, pieces)
    dress_floor(coll, pieces)
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
        # where you load in: just inside the door, at a player's eyes, the units down both walls
        # and the six cars at the far end
        ("spawn", (0.0, K.FRONT + 6.0, 4.6), (0.0, 0.0, 4.4), 14.0, 0.5),
        # one car up close: its number, the striped zone, the post between
        ("bay", (3.0, -15.0, 4.8), (9.0, 0.0, 5.6), 20.0, 0.4),
        # from near the front back to the way in: the storefront, the counter, the rack
        ("door", (4.0, K.FRONT + 42.0, 5.2), (0.0, K.FRONT, 4.2), 14.0, 0.5),
        # the counter and the shelves behind it
        ("counter", (-38.0, K.FRONT + 28.0, 5.2), (-56.0, K.FRONT + 12.0, 3.6), 20.0, 0.4),
        # the cart rack, empty
        ("rack", (20.0, K.FRONT + 14.0, 5.0), (28.0, K.FRONT + 2.0, 1.2), 22.0, 0.4),
        # one unit from the floor: its door up, its bulb on, its owner's name over it (unit 9)
        ("unit", (37.0, -94.0, 5.2), (60.0, -82.0, 6.6), 18.0, 0.4),
        # from a unit's back corner out its door to the floor (unit 4)
        ("inside", (-88.4, -70.4, 6.2), (-40.0, -60.0, 3.6), 18.0, 0.4),
        # walking up to your own unit (9): the plants either side, its starter set waiting inside
        ("home", (47.0, -87.5, 4.7), (66.0, -81.0, 2.6), 17.0, 0.4),
        # a bench between two doors and the planter in the middle, from across the floor
        ("nook", (-6.0, -96.0, 5.0), (-40.0, -70.0, 2.4), 16.0, 0.4),
    ]
    for n, side, door_at, _, _, _ in K.slot_rows():
        if n == 9:  # your own unit's mirror (S5-03f1), from the rug and close up
            at = slot_frame(side, door_at[1])
            shots.append(("mirror", tuple(at @ Vector((2.0, 6.5, 4.6))),
                          tuple(at @ Vector((9.0, 12.5, 3.0))), 18.0, 0.4))
            shots.append(("mirror-close", tuple(at @ Vector((6.2, 10.0, 4.4))),
                          tuple(at @ Vector((9.4, 12.5, 4.6))), 24.0, 0.4))
            # the clothes rail past it (S5-03f2a), from the rug and close up
            shots.append(("rail", tuple(at @ Vector((1.0, 8.0, 4.8))),
                          tuple(at @ Vector((8.9, 15.5, 2.8))), 18.0, 0.4))
            shots.append(("rail-close", tuple(at @ Vector((4.6, 14.0, 4.4))),
                          tuple(at @ Vector((8.9, 17.0, 2.9))), 20.0, 0.4))
    for name, loc, target, lens, ex in shots:
        if only and name not in only:
            continue
        cam = render.camera(loc, target, lens=lens)
        render.shoot(cam, os.path.join(SHEETS, f"lobby-{name}.png"), exposure=ex)
    if only and "plan" not in only:
        return
    # the plan, from above with the deck lifted off
    for n in ("Ceiling", "Deck", "Joists", "Panel", "UnitTops", "WallsUpper", "Lamps"):
        objs[n].hide_render = True
    for o in bpy.data.objects:
        if o.name.startswith(("Housing", "Diffuser", "Eye", "hall", "lamp")):
            o.hide_render = True
    sun = bpy.data.lights.new("plan_sun", "SUN")
    sun.energy = 2.0
    so = bpy.data.objects.new("plan_sun", sun)
    coll.objects.link(so)
    so.rotation_euler = (math.radians(20), math.radians(10), 0.0)
    cam = render.camera((0.0, -86.0, 330.0), (0.0, -84.0, 0.0), lens=30.0)
    render.shoot(cam, os.path.join(SHEETS, "lobby-plan.png"), exposure=0.0)


STAGES = {"export": stage_export, "renders": stage_renders}

if __name__ == "__main__":
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    ap = argparse.ArgumentParser()
    ap.add_argument("--stage", choices=list(STAGES), required=True)
    ap.add_argument("--only", nargs="*", help="renders: just these sheets (spawn, unit, home, ...)")
    a = ap.parse_args(argv)
    STAGES[a.stage](a.only) if a.stage == "renders" else STAGES[a.stage]()
    print("DONE")
