"""Every number of Everkeep's front office (the lobby), in studs. Change them here only.

The lobby (GDD "The lobby", D-112): you load in just inside the glass front door, facing six
freight cars along the back wall, and know at a glance where to go. The counter stands to the left
with the shop's shelves behind it, the cart rack to the right of the door. Built from code in
Blender 5.2 the unit's way (art/lobby/README.md), wearing the unit's own baked texture sets and
the corridor kit's deck, joists and wall pieces, so the front office reads as the same building.

Its frame in Blender is the elevator's: X across (your right as you face the cars is +X), Y from
the room toward the cars, Z up. The origin is on the floor at the middle of the bay wall's face,
so a car's threshold sits on that face at y = 0: the climb's own elevator stands in bay i with its
pivot at the lobby's pivot moved bay_xs()[i] along X. The FBX turns this into Roblox's frame
(Roblox X = -x, Y = z, Z = y): the lobby faces its LookVector, from the cars toward the front door.
src/shared/Lobby/Specs.luau, which the export stage writes, carries every number the game needs.

This file is loaded by path as `lobby_spec` (build.py): the name `spec` belongs to the corridor
kit's spec, which the corridor's pieces read.
"""

import math
import os

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", ".."))
ELEVATOR_SPEC = os.path.join(ROOT, "art", "elevator", "spec.py")

# --- the room ----------------------------------------------------------------------------------
# Wide enough for six cars side by side with a post between each, deep enough to kick a cart
# around while the count runs (L-08e4), and short enough that a new player reaches a car in a
# few seconds (the GDD's 15-second rule): the spawn is 44 studs from the cars, under 3 s at a run.
WIDTH = 120.0            # side wall's face to side wall's face (x from -60 to 60)
DEPTH = 48.0             # the bay wall's face to the front wall's face (y from -48 to 0)
WALL = 0.5               # the bay wall's depth: the elevator's Opening.Wall (checked at export)
DECK = 14.0              # the deck's underside: the corridor's, so its hall light hangs as tuned
APRON = 24.0             # concrete outside the front door: the glass shows the porch light's pool on it
OUTER = 1.0              # the colliders' depth behind each wall's face

# --- the bays: six openings in the bay wall, each the climb's own landing --------------------
BAYS = 6
BAY_PITCH = 18.0         # car middle to car middle: the frame's 13.8 and 4.2 of wall between
OPENING = (12.4, 9.2)    # the hole each car's landing frame fills: the elevator's (checked)
JAMB = 0.7               # the landing frame's plates beside and over the hole (the elevator's)
HEADER = 1.2
KEYPAD_REACH = 8.4       # the elevator's keypad reaches this far right of a car's middle
PAINT_DEPTH = 3.2        # the striped zone on the floor before each car, from the landing sill
PAINT_GAP = 0.45         # between the zone and the bay wall (the landing sill reaches 0.35)
PAINT_LINE = 0.25        # the zone's border
STRIPE = (0.5, 1.25)     # a stripe's width and pitch, at 45 degrees
PAINT_Z = 0.015          # paint's height off the floor
NUMBER = (3.6, 2.6, 11.95)  # the number plate over each car: width, height, middle's height
                            # (it reaches 13.25, between the joists either side of a car)
PLATE_T = 0.06           # a sign plate's thickness
PLATE_OFF = 0.12         # a number plate's back off the bay wall's face: clear of the R-panel's ribs (0.015)
SIGN_OFF = 0.12          # a sign plate's back off a flat painted wall


def bay_xs():
    """Each car's middle across the bay wall, bay 1 on the left as you face the cars."""
    return [BAY_PITCH * (i - (BAYS - 1) / 2) for i in range(BAYS)]


def posts():
    """The bay wall's posts: one at each end and one midway between each pair of cars."""
    xs = bay_xs()
    return [(a + b) / 2 for a, b in zip(xs, xs[1:])]


# --- the front: a glass storefront round the double door --------------------------------------
STORE = (-12.0, 12.0)    # the storefront's ends across the front wall
DOOR = 4.0               # each leaf's width: the double door is 8 wide, its meeting stiles at x 0
DOOR_H = 8.0             # the doors' and sidelights' head (the transom bar's underside)
STORE_TOP = 10.0         # the storefront's top: the wall's cap runs across over it
MULLION = (0.25, 0.4)    # an aluminium mullion's face width and depth
STILE = 0.32             # a door leaf's stiles and top rail
DOOR_RAIL = 0.9          # its bottom rail
SILL_RAIL = 0.55         # the sidelights' bottom rail
PUSH_BAR = (3.3, 0.06)   # the doors' push bars: height, radius
GLASS_T = 0.04
SIDE_MULLIONS = (-8.0, 8.0)  # the sidelights' middle mullions

# --- the counter: to the left as you come in, facing into the room --------------------------
COUNTER_FACE = -51.0     # its customer face's x
COUNTER_DEPTH = 2.4
COUNTER_Y = (-42.0, -28.0)
COUNTER_TOP = 3.4        # a shop counter's height on an R15 avatar (eyes at about 4.6)
COUNTER_SLAB = 0.15
COUNTER_LIP = 0.2        # the top's overhang on the customer side
COUNTER_KICK = 0.5
REGISTER = (-52.25, -32.0)  # the till's middle on the counter (x, y)
BELL = (-51.45, -36.2)      # the service bell's

# --- the shop's shelves on the left wall behind the counter ----------------------------------
SHELF_DEPTH = 2.0
SHELF_RUNS = ((-44.0, -35.25), (-34.75, -26.0))   # two steel shelving units, end to end
SHELF_LEVELS = (0.3, 2.25, 4.2, 6.15, 8.1)         # each deck's top; the top one is the cap
SHELF_POST = 0.12
SHELF_DECK = 0.06
NAME_SIGN = (-35.0, 9.0, 16.0, 1.3)  # the Everkeep sign over the shelves: y middle, z, w, h

# --- the cart rack: to the right of the door against the front wall ------------------------
RACK_X = (18.0, 36.0)    # its ends; a divider every RACK_PITCH between
RACK_PITCH = 3.0         # one slot per platform cart (a 2.2 x 4.3 deck, L-08e4)
RACK_Y = (-47.5, -42.8)  # how deep a slot is: the hoops' feet
RACK_H = 1.8             # the hoops' top rail
RACK_PIPE = 0.07
RACK_RAIL_Z = 1.0        # the back rail joining the hoops
CART_SIGN = (6.0, 1.6, 0.9)  # the plate over the rack: its height, width, height of the plate

# --- the lights: the corridor's hall light, hung midway between joists ----------------------
JOIST_EVERY = 6.0        # joists at every multiple of 6 across, so a car's middle is between two


def joist_xs():
    n = int(WIDTH / 2 / JOIST_EVERY)
    return [JOIST_EVERY * k for k in range(-n + 1, n)]


def fixtures():
    """Where the hall lights hang (x, y): a row over the cars' landings, a row down the room's
    middle, one over the counter and one over the cart rack."""
    xs = bay_xs()
    out = [(x, -9.0) for x in xs] + [(x, -27.0) for x in xs[1:-1]]
    out += [(-51.0, -35.0), (27.0, -40.0)]
    return out


SPAWN = (0.0, -42.0)     # where you load in: just inside the door, facing the cars

# --- the shelves' stock: moving boxes the game clones from the boxes kit -----------------------
BOX_SIZE = {"Small": (1.2, 1.6, 1.2), "Medium": (1.8, 1.8, 1.6)}  # deep, along the shelf, tall: label out


def stock():
    """Boxes on the shelves (kind, x, y, z of the bottom middle, turn in degrees about Z). Fixed
    so the look sheets and the game show the same shelves."""
    out = []
    rows = [("Medium", 1), ("Medium", 2), ("Small", 3), ("Small", 4)]
    gaps = {0: (0.6, 0.5, 1.3), 1: (0.9, 0.4, 0.8), 2: (0.5, 1.1, 0.6)}
    for r, (y0, y1) in enumerate(SHELF_RUNS):
        for level, (kind, k) in enumerate(rows):
            w = BOX_SIZE[kind][1]
            gap = gaps[(r + level) % 3]
            y = y0 + 0.35
            i = 0
            while True:
                y += gap[i % 3] * 0.6
                if y + w > y1 - 0.3:
                    break
                turn = (-4.0, 3.0, -1.5, 5.0)[(i + level + r) % 4]
                x = -60.0 + SHELF_DEPTH / 2 + (0.08 if i % 2 else -0.05)
                out.append((kind, x, y + w / 2, SHELF_LEVELS[k - 1], turn))
                y += w
                i += 1
    return out


def b2r(v):
    """A Blender point in Roblox's frame."""
    return (-v[0], v[2], v[1])


def lua_vec(v, nd=3):
    return "{ " + ", ".join(f"{c:.{nd}f}" for c in v) + " }"


def colliders():
    """Invisible boxes the game collides with (the meshes don't): name, Blender lo, hi."""
    w, d, o = WIDTH / 2, DEPTH, OUTER
    top = DECK + 0.6
    ow, oh = OPENING[0] / 2, OPENING[1]
    out = [
        ("Floor", (-w - o, -d - APRON, -1.0), (w + o, WALL, 0.0)),
        ("Ceiling", (-w - o, -d - o, top), (w + o, WALL, top + 1.0)),
        ("WallLeft", (-w - o, -d - o, 0.0), (-w, WALL, top)),
        ("WallRight", (w, -d - o, 0.0), (w + o, WALL, top)),
        ("WallFront", (-w, -d - o, 0.0), (w, -d, top)),
        ("CounterBody", (COUNTER_FACE - COUNTER_DEPTH, COUNTER_Y[0], 0.0),
         (COUNTER_FACE + COUNTER_LIP, COUNTER_Y[1], COUNTER_TOP)),
    ]
    # the bay wall: between and beside the openings to the deck, and over each opening
    xs = bay_xs()
    edges = [-w] + [e for x in xs for e in (x - ow, x + ow)] + [w]
    for i in range(0, len(edges), 2):
        out.append((f"BayWall{i // 2}", (edges[i], 0.0, 0.0), (edges[i + 1], WALL, top)))
    for i, x in enumerate(xs):
        out.append((f"OverBay{i + 1}", (x - ow, 0.0, oh), (x + ow, WALL, top)))
    for i, (y0, y1) in enumerate(SHELF_RUNS):
        out.append((f"Shelves{i + 1}", (-w, y0, 0.0), (-w + SHELF_DEPTH, y1, SHELF_LEVELS[-1])))
    out.append(("CartRack", (RACK_X[0] - RACK_PIPE, RACK_Y[0] - RACK_PIPE, 0.0),
                (RACK_X[1] + RACK_PIPE, RACK_Y[0] + 0.4, RACK_RAIL_Z + 0.1)))
    for k in range(int(round((RACK_X[1] - RACK_X[0]) / RACK_PITCH)) + 1):
        x = RACK_X[0] + k * RACK_PITCH
        out.append((f"RackHoop{k + 1}", (x - RACK_PIPE, RACK_Y[0], 0.0),
                    (x + RACK_PIPE, RACK_Y[1] + RACK_PIPE, RACK_H + RACK_PIPE)))
    return out


def cards():
    """Flat places the game writes on (a SurfaceGui each): name, Blender middle, (w, h), the
    direction its face looks (Blender)."""
    out = []
    nw, nh, nz = NUMBER
    for i, x in enumerate(bay_xs()):
        out.append((f"Bay{i + 1}", (x, -PLATE_OFF - PLATE_T - 0.005, nz), (nw - 0.3, nh - 0.3), (0, -1, 0)))
    y, z, sw, sh = NAME_SIGN
    out.append(("Name", (-WIDTH / 2 + SIGN_OFF + PLATE_T + 0.005, y, z), (sw - 0.4, sh - 0.3), (1, 0, 0)))
    cz, cw, ch = CART_SIGN
    out.append(("Carts", ((RACK_X[0] + RACK_X[1]) / 2, -DEPTH + SIGN_OFF + PLATE_T + 0.005, cz),
                (cw - 0.3, ch - 0.25), (0, 1, 0)))
    return out


def write_luau(path, parts, slots):
    """parts: {name: dict(size=(x, y, z) Roblox, centre=(x, y, z) Blender, tris=n)}; slots: the
    cart rack's slot middles (Blender)."""
    sx, sy = SPAWN
    L = [
        "--!strict",
        "-- Generated by art/lobby/build.py --stage export from art/lobby/spec.py. Don't edit:",
        "-- change the spec and rebuild (scripts/art.sh lobby).",
        "-- Studs, in the lobby's own frame: the origin on the floor at the middle of the bay wall's",
        "-- face, the room in front (-Z, its LookVector), the cars' shafts behind (+Z), Y up.",
        "",
        "export type Vec = { number } -- x, y, z",
        "export type Part = { Size: Vec, Centre: Vec, Triangles: number }",
        "export type Box = { Name: string, Centre: Vec, Size: Vec }",
        "export type Card = { Name: string, Centre: Vec, Size: { number }, Facing: Vec }",
        "export type Stock = { Kind: string, At: Vec, Turn: number }",
        "",
        "local Specs = {",
        "\t-- The room inside: wall to wall across (X), the bay wall's face to the front wall's (Z), and",
        "\t-- the deck's underside (Y).",
        f"\tRoom = {{ Width = {WIDTH}, Depth = {DEPTH}, Deck = {DECK} }},",
        "\t-- Each car's middle across the bay wall (X), bay 1 on the left as you face the cars: the",
        "\t-- climb's elevator stands there with its threshold on the wall's face (Z 0).",
        "\tBays = { " + ", ".join(f"{b2r((x, 0, 0))[0]:.1f}" for x in bay_xs()) + " },",
        "\t-- The hole each landing frame fills (the elevator's Opening).",
        f"\tOpening = {{ Width = {OPENING[0]}, Height = {OPENING[1]} }},",
        "\t-- Where you load in, on the floor, facing the cars (+Z).",
        f"\tSpawn = {lua_vec(b2r((sx, sy, 0.0)))},",
        "\t-- Where the hall lights hang (on the floor under each lens's middle; each lens along X).",
        "\tLights = {",
    ]
    for x, y in fixtures():
        L.append(f"\t\t{lua_vec(b2r((x, y, 0.0)))},")
    L += ["\t},", "\t-- The cart rack's slots: each slot's middle on the floor; a cart parks nose to the wall (-Z).",
          "\tCartSlots = {"]
    for x, y in slots:
        L.append(f"\t\t{lua_vec(b2r((x, y, 0.0)))},")
    L += ["\t},", "\t-- Boxes on the shop's shelves: the kind (Boxes.Specs), the bottom middle, the turn about Y",
          "\t-- in degrees.", "\tStock = {"]
    for kind, x, y, z, turn in stock():
        L.append(f"\t\t{{ Kind = \"{kind}\", At = {lua_vec(b2r((x, y, z)))}, Turn = {turn:.1f} }},")
    L += ["\t} :: { Stock },", "\t-- Flat places the game writes on: the bay numbers, Everkeep's name, the cart rack's sign.",
          "\tCards = {"]
    for name, c, (w, h), n in cards():
        L.append(f"\t\t{{ Name = \"{name}\", Centre = {lua_vec(b2r(c))}, Size = {{ {w:.2f}, {h:.2f} }}, "
                 f"Facing = {lua_vec(b2r(n), 0)} }},")
    L += ["\t} :: { Card },", "\t-- Each MeshPart's box as imported (its centre is its CFrame in the lobby's frame).",
          "\tParts = {"]
    for name in sorted(parts):
        r = parts[name]
        px, py, pz = r["size"]
        L.append(f"\t\t{name} = {{ Size = {{ {px:.3f}, {py:.3f}, {pz:.3f} }}, "
                 f"Centre = {lua_vec(b2r(r['centre']))}, Triangles = {r['tris']} }},")
    L += ["\t} :: { [string]: Part },", "\t-- Invisible boxes the game collides with; the meshes don't.",
          "\tColliders = {"]
    for name, lo, hi in colliders():
        c = [(lo[i] + hi[i]) / 2 for i in range(3)]
        s = [hi[i] - lo[i] for i in range(3)]
        L.append(f"\t\t{{ Name = \"{name}\", Centre = {lua_vec(b2r(c))}, "
                 f"Size = {lua_vec((s[0], s[2], s[1]))} }},")
    L += ["\t} :: { Box },", "}", "", "return Specs", ""]
    with open(path, "w") as f:
        f.write("\n".join(L))
    print("SPEC", path)
