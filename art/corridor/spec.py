"""Every number of the corridor kit, in studs (about 0.28 m each). Change them here only.

The kit's frame in Blender: the hall runs along X, across it is Y, up is Z. A piece's origin is
the middle of its hall floor, on the floor. The FBX turns this into Roblox's frame (Y up) and the
game reads these numbers from src/shared/CorridorKit/Specs.luau, which the export stage writes.
"""

import os
import re

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", ".."))

# --- the hall -----------------------------------------------------------------------------------
HALL = 8.0          # the hall's width, door face to door face (the units' facades)
UNIT_DEPTH = 12.0   # an M unit, door face to back wall: the ceiling reaches over a row each side
SPAN = HALL + 2 * UNIT_DEPTH  # the ceiling across: the hall and a row of units either side
TILE = 8.0          # the unit's Concrete texture repeats every 8 studs, a saw-cut joint on its edge

# Two M units a side (three S), and one hall light's stretch (HallLight: a fixture every 24).
# A multiple of TILE, so floors meet on a joint, and of JOIST_SPACING, so joists keep their beat.
STRAIGHT = 24.0

FLOOR_SKIRT = 0.2   # the slab's hidden edges, below the floor

# --- the ceiling: a corrugated steel deck on open-web steel joists ------------------------------
DECK = 14.0         # underside of the deck's low flutes, where it sits on the joists
RIB_PITCH = 1.0     # one low and one high flute
RIB_DEPTH = 0.25    # low flute to high flute
RIB_FLAT = 0.35     # width of each flute's flat; the slopes take the rest of the pitch
DECK_COVER = 0.1    # a closed top above the high flutes, so nothing shows through from above

JOIST_SPACING = 6.0
# The joists' lowest steel. The hall's haze tops out at 12.6 (HallLight.HazeHeight 9.6 plus a
# puff's 3-stud reach), and low graphics draws a hard line where a puff cuts into anything, so
# the joists stay clear of it (tests/corridor.spec.luau checks this against HallLight).
JOIST_BOTTOM = 12.8
CHORD_LEG = 0.16    # each chord is two steel angles back to back
CHORD_THICK = 0.03
CHORD_GAP = 0.06    # between the two angles, where the web's bars are welded
WEB_RADIUS = 0.05   # round bar
WEB_SEGS = 6
WEB_PANELS = 26     # diagonals across the span, close to 45 degrees

assert STRAIGHT % TILE == 0 and STRAIGHT % JOIST_SPACING == 0
assert SPAN % RIB_PITCH == 0


# --- the hall's walls: the plain wall where no unit stands, and the dead end ----------------------
# Both are the corridor wall a unit's front is (art/unit/parts.py, `facade` and `frame`), without a
# door, so the hall reads as one building: painted steel panels (the unit's Facade set, painted per
# floor) on a diamond kick plate between posts, capped at the units' wall height. Above the cap an
# R-panel (the units' Partition set) closes the wall to the deck, where a unit is open over its wire
# top. Built in the unit's frame: the wall's hall face is the plane y = 0 with the hall at -y, and
# the origin is the face's middle, on the floor. So a plain wall goes wherever a unit would.
def _unit():
    """The M unit's spec (art/unit/spec.py), loaded under its own name: this folder has a spec.py."""
    import importlib.util
    path = os.path.join(ROOT, "art", "unit", "spec.py")
    s = importlib.util.spec_from_file_location("unit_spec", path)
    m = importlib.util.module_from_spec(s)
    s.loader.exec_module(m)
    return m.Spec("M")


UNIT = _unit()
WALL_H = UNIT.wall_height    # the units' walls, 10: the cap sits on top
PLAIN = UNIT.width           # the plain wall is one M unit wide, so a hall side is a row of slots
FACADE = UNIT.facade         # the corridor wall's thickness
POST = UNIT.pilaster         # half a post at each end of a unit; two neighbours make it whole
POST_PROUD = 0.07            # as the unit's: the posts stand this far into the hall
KICK = UNIT.kick             # the diamond kick plate's height
CAP_DROP = 0.12              # the cap's underside below WALL_H, as the unit's
CAP_RISE = 0.012             # its top above WALL_H
CAP_PROUD = 0.08             # how far the cap stands into the hall: the units' caps line up with it
# The R-panel above the cap: its ribs are 0.1 deep (the unit's `corrugated`). On the plain wall the
# ribs' crests sit just behind the cap's face, under the deck's low flute that runs over the wall.
# On the dead end, which crosses the deck's flutes at the deck's end, the panel's valleys are flush
# with that end, so no gap opens between them, and its cap stands out further to cover the crests.
PANEL_PLANE = 0.1            # the plain wall's sheet, behind its face
END_PANEL_PLANE = 0.015      # the dead end's sheet: its valleys' hall side on the face's plane
END_CAP_PROUD = 0.12
BACKING = FACADE             # the bare sheet behind a wall, seen only from the slot behind it

assert UNIT.width == STRAIGHT / 2, "a straight piece holds two plain walls a side"
assert (SPAN / 2 - HALL / 2) % RIB_PITCH == 0, "the hall's sides sit under a low flute"


# --- the hall light fixture: a steel strip light on two chains, with a motion sensor's eye ----------
# The lens is the part the game lights (HallLight.light), so its place and size are read from the
# game's own HallLight.Height and TubeSize: the light was tuned there and the art follows it.
def hall_light():
    """(height of the lens's middle, (length along the hall, thickness, width across))."""
    with open(os.path.join(ROOT, "src", "shared", "HallLight.luau")) as f:
        src = f.read()
    height = float(re.search(r"HallLight\.Height = ([\d.]+)", src).group(1))
    size = re.search(r"HallLight\.TubeSize = Vector3\.new\(([\d.]+), ([\d.]+), ([\d.]+)\)", src)
    return height, tuple(float(g) for g in size.groups())


LENS_Z, (LENS_LEN, LENS_THICK, LENS_W) = hall_light()
LENS_TOP = LENS_Z + LENS_THICK / 2   # where the lens clips into the housing
LENS_EDGE = 0.02    # the lens's edge below the housing's lips; it bows down to LENS_THICK mid-width

HOUSING_LEN = LENS_LEN + 0.2   # the steel channel, a little past the lens at each end
HOUSING_W = 0.58    # across the hall at its lips: a little wider than the lens
HOUSING_TOP_W = 0.42  # its sloped sides narrow to this on top
HOUSING_H = 0.23    # lens top to housing top
LIP = 0.04          # the lips hold the lens's edges this far below its top

# The occupancy sensor: a box on one end of the housing with a frosted dome under it, the building's
# eye. The game lights the dome (HallLight.eye). A full half-sphere, as a ceiling sensor that sees
# all round has, so it shows from anywhere in the hall; about twice a real one's size, because at a
# 0.26-stud dome only the nearest eye in a dark hall read on a phone (Studio, Galaxy A16).
SENSOR_LEN = 0.44
SENSOR_W = 0.46
SENSOR_H = 0.22
EYE_R = 0.18        # the dome's radius
EYE_DROP = 0.18     # how far it hangs below the sensor box: a half-sphere
EYE_SEGS = 12       # facets around: a Fresnel lens is faceted
EYE_RINGS = 4

# Jack chain, galvanized, from an eye bolt on the housing's top to a clip on the deck's low flute
# over the hall's middle. Links are drawn bigger than real ones (about 6 cm) so they read on a phone.
CHAIN_X = 1.5       # either side of the middle: well inside the joists at +/- 3
LINK_LEN = 0.2      # a link's outside length
LINK_W = 0.1        # its outside width
LINK_WIRE = 0.017   # the wire's radius
LINK_POINTS = 8     # around a link's loop
LINK_SIDES = 3      # around its wire

# The fixture's power: a black cord from the sensor end up to a junction box on the deck.
CORD_R = 0.022
BOX_R = 0.2         # the octagonal junction box
BOX_H = 0.14
BOX_X = HOUSING_LEN / 2 + 0.25  # over the sensor end

FIXTURE_TOP = LENS_TOP + HOUSING_H
# how far the fixture reaches from its middle along the hall: the sensor box or the junction box
REACH = max(HOUSING_LEN / 2 + SENSOR_LEN, BOX_X + BOX_R)
assert JOIST_SPACING / 2 - (CHORD_GAP / 2 + CHORD_LEG) > REACH, "the fixture hits a joist"
assert LENS_Z + LENS_THICK / 2 < JOIST_BOTTOM


def joist_xs(length):
    """Joists sit half a spacing in from each end, so pieces in a row keep a 6-stud beat."""
    n = int(round(length / JOIST_SPACING))
    return [-length / 2 + JOIST_SPACING * (k + 0.5) for k in range(n)]


def haze_top():
    """Where HallLight's haze reaches, read from the game's own numbers."""
    with open(os.path.join(ROOT, "src", "shared", "HallLight.luau")) as f:
        src = f.read()
    height = float(re.search(r"HallLight\.HazeHeight = ([\d.]+)", src).group(1))
    size = float(re.search(r"HallLight\.HazeSizeEnd = ([\d.]+)", src).group(1))
    return height + size / 2


def lua_num(x):
    s = f"{x:.4f}".rstrip("0").rstrip(".")
    return "0" if s in ("-0", "") else s


def write_luau(path, pieces, walls, fixture_tris):
    """pieces: {name: dict(length=, colliders={name: (pos, size)}, tris={part: n})}, Roblox axes;
    walls: {name: dict(width=, colliders=, tris=)}, in the wall's frame; fixture_tris: {part: n}
    for the hall light fixture."""
    v3 = lambda t: f"Vector3.new({', '.join(lua_num(v) for v in t)})"
    lines = [
        "--!strict",
        "-- Generated by art/corridor/build.py --stage export from art/corridor/spec.py. Don't edit:",
        "-- change the spec and rebuild (scripts/art.sh corridor).",
        "-- Studs. A piece's origin is the middle of its hall floor, on the floor; the hall runs",
        "-- along X, +Y is up.",
        "",
        "return {",
        f"\tHallWidth = {lua_num(HALL)}, -- door face to door face",
        f"\tSpan = {lua_num(SPAN)}, -- the ceiling across: the hall and a row of M units each side",
        f"\tDeckHeight = {lua_num(DECK)}, -- underside of the deck's low flutes",
        f"\tDeckTop = {lua_num(DECK + RIB_DEPTH + DECK_COVER)}, -- the deck's closed top",
        f"\tJoistBottom = {lua_num(JOIST_BOTTOM)}, -- the lowest steel overhead",
        f"\tJoistSpacing = {lua_num(JOIST_SPACING)},",
        f"\tFloorTile = {lua_num(TILE)}, -- pieces are a multiple of this long, so floors meet on a joint",
        "",
        "\tPieces = {",
    ]
    for name, p in pieces.items():
        lines += [f"\t\t{name} = {{", f"\t\t\tLength = {lua_num(p['length'])},", "\t\t\tColliders = {"]
        for cname, (pos, size) in p["colliders"].items():
            lines.append(f"\t\t\t\t{cname} = {{ Position = {v3(pos)}, Size = {v3(size)} }},")
        lines += ["\t\t\t},", "\t\t\tTriangles = {"]
        for part, n in sorted(p["tris"].items()):
            lines.append(f"\t\t\t\t{part} = {n},")
        lines += ["\t\t\t},", "\t\t},"]
    lines += [
        "\t},",
        "",
        "\t-- The hall's walls: the plain wall where no unit stands, and the dead end across the hall's",
        "\t-- end. A wall's frame is the middle of its hall face, on the floor, looking into the hall (a",
        "\t-- unit's door face): X along the wall, +Y up, +Z behind it.",
        f"\tWallHeight = {lua_num(WALL_H)}, -- the cap's height, the units' walls",
        "\tWalls = {",
    ]
    for name, w in walls.items():
        lines += [f"\t\t{name} = {{", f"\t\t\tWidth = {lua_num(w['width'])},", "\t\t\tColliders = {"]
        for cname, (pos, size) in w["colliders"].items():
            lines.append(f"\t\t\t\t{cname} = {{ Position = {v3(pos)}, Size = {v3(size)} }},")
        lines += ["\t\t\t},", "\t\t\tTriangles = {"]
        for part, n in sorted(w["tris"].items()):
            lines.append(f"\t\t\t\t{part} = {n},")
        lines += ["\t\t\t},", "\t\t},"]
    lines += [
        "\t},",
        "",
        "\t-- The hall light fixture: its frame is on the floor under the lens's middle, the hall along",
        "\t-- X, the sensor's eye on +X.",
        "\tFixture = {",
        f"\t\tLensHeight = {lua_num(LENS_Z)}, -- the lens's middle (HallLight.Height)",
        f"\t\tLensSize = Vector3.new({lua_num(LENS_LEN)}, {lua_num(LENS_THICK)}, {lua_num(LENS_W)}),"
        " -- HallLight.TubeSize",
        f"\t\tTop = {lua_num(FIXTURE_TOP)}, -- the housing's top; chains run from here to the deck",
        f"\t\tReach = {lua_num(REACH)}, -- from its middle along the hall to its far end (the sensor's)",
        "\t\tTriangles = {",
    ]
    for part, n in sorted(fixture_tris.items()):
        lines.append(f"\t\t\t{part} = {n},")
    lines += ["\t\t},", "\t},", "}", ""]
    with open(path, "w") as f:
        f.write("\n".join(lines))
