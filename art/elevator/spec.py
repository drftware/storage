"""Every number of the freight elevator, in studs. Change them here only.

The way up (GDD: Codes, the elevator and the roof): a freight car at the back of each floor's
lobby. Punch the floor's code into the keypad beside it and its folding gate opens; 30 seconds
later the gate folds shut on its own and the car goes up. Built from code in Blender 5.2, the
unit's way (art/elevator/README.md).

Its frame in Blender: X across (your right as you face the car from the lobby is +X), Y from the
lobby into the shaft (the car faces -Y, toward the lobby), Z up. The origin is on the lobby floor
at the middle of the threshold, in the plane of the lobby's back wall's face. The FBX turns this
into Roblox's frame (Roblox X = -x, Y = z, Z = y), so the elevator faces its LookVector, the lobby
in front of it, the car behind; src/shared/Elevator/Specs.luau, which the export stage writes,
carries every number the game needs in that frame.

Three texture sets: Car tiles across the car's walls, ceiling and floor plates (one repeat is
12.8 studs, so no wall shows a repeat, at 80 texels a stud); Elevator is the big trim (the car's
front, its bumper boards and hatch, the landing's steel frame and sill, about 44 texels a stud);
Fittings is the small things you see up close (the gate's parts, the lamp, the keypad and its
keys, the sticky note, about 135).
"""

import math
import os

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", ".."))
FONTS = "/Applications/RobloxStudio.app/Contents/Resources/content/fonts"
KEY_FONT = os.path.join(FONTS, "BuilderSans-Bold.otf")   # engraved on the keys
HAND_FONT = os.path.join(FONTS, "Kalam-Regular.ttf")     # Dale's pen on the notes (sheets only)

SET = "Elevator"   # the finds' kit reads this; the build points it at Elevator, then Keypad
SETS = ("Car", "Elevator", "Fittings")
TEX = 1024
SEED = 61
DUST = 0.3         # the car is swept by everyone who rides it; the trim's tops still gather some

# --- the landing: the lobby's side of the shaft ----------------------------------------------
WALL = 0.5               # the lobby's back wall, its face at y = 0 (FloorBuilder's LOBBY_WALL)
OPENING = (12.4, 9.2)    # the hole in that wall: width, height. FloorBuilder builds the wall round it
JAMB = 0.7               # the steel face plates either side of the opening
HEADER = 1.2             # and over it
PLATE = 0.12             # how far those plates stand off the wall
HAZARD = 1.0             # the jambs' feet are striped this high, where dollies hit them
LANDING_SILL = (-0.35, 0.5)  # its y range: a grooved sill from the lobby floor to the shaft

# --- the car -----------------------------------------------------------------------------------
# Room for six players (the GDD's party) to stand clear of a shutting gate, and for the Mannequin
# (6.3 tall) to pass under its track: inside, 12.5 across, 11 deep, 9.6 tall.
CAR_FRONT = 0.62         # y of the car's front, across a 0.12 running gap from the landing sill
CAR_W = 12.5
CAR_BACK = 12.0
CAR_H = 9.6
POST = 0.5               # the front posts' width: the gate runs between them
POST_Y = (0.62, 1.05)    # the posts', fascia's and track's depth
FASCIA = 8.75            # z of the fascia's bottom; the gate's track hangs under it
TRACK = (8.45, 8.75)
CAR_SILL = (0.62, 1.1)   # the car's striped sill, the gate's groove down its middle
GROOVE = (0.81, 0.89)
TOE = 1.5                # the steel apron under the car's sill, hanging into the gap
TILE = 12.8              # one repeat of the Car set across, and its whole height
FLOOR_BAND = 3.2         # the Car set's bottom band: one diamond plate 3.2 deep
assert abs(TILE - FLOOR_BAND - CAR_H) < 1e-6, "the Car set is a floor plate and one wall high"
WALL_U = {"back": 0.0, "left": 0.37, "right": 0.71}   # each wall starts somewhere else in the set
CEIL_STRIPS = 4          # the ceiling: panels across the car, each wearing the top of a wall
# Bumper boards: oak planks on steel brackets at a dolly's height, the dollies' marks below them.
RAILS = ((0.85, 1.35), (2.35, 2.85))
BOARD = 0.16             # their thickness; they stand 0.04 off the wall
HATCH = (0.0, 8.6, 3.0)  # the escape hatch in the ceiling: centre x, y, and its side
LAMP = (0.0, 5.2)        # the caged lamp's x, y on the ceiling: the warm light you run back to

# --- the gate: a collapsible lattice gate, folding to the left post -------------------------------
# Thirteen pickets (steel channels; the last is the lead, with the handle) linked by three rows of
# lazy tongs: in each bay two straps cross, pinned at their middles, their ends sliding in the
# pickets' channels. A strap's ends stay on the pickets for any spread: cos(angle) = pitch / STRAP.
PICKETS = 13
PICKET = (0.16, 0.12)    # a picket's width (x) and depth (y)
LEAD = (0.30, 0.16)      # the lead picket's
RUBBER = 0.03            # the lead's rubber edge, on the side it closes toward
GATE_Y = 0.85            # the pickets' middles, over the sill's groove
GATE_Z = (0.08, 8.45)    # a picket's foot (in the groove) and head (the roller's in the track)
ROWS = (1.15, 4.3, 7.45) # the three rows of tongs, by their pins' height
STRAP = 1.5              # pin to pin
STRAP_W, STRAP_T = 0.11, 0.03
STACK = -5.75 + PICKET[0] / 2     # the first picket's middle, fixed to the left post
FOLD = 0.2                        # pitch folded: pickets packed against each other
CLOSED = 5.75 - LEAD[0] / 2 - RUBBER - 0.01   # the lead's middle with the gate shut
OPEN = STACK + (PICKETS - 1) * FOLD           # and folded open
LAYERS = (GATE_Y - PICKET[1] / 2 - STRAP_T * 1.5,   # the rising straps, in front
          GATE_Y - PICKET[1] / 2 - STRAP_T * 0.5)   # the falling ones, behind them


def gate_pose(shut):
    """The gate at `shut` (0 folded open, 1 shut): each picket's x and the straps' angle from
    level (radians). src/shared/Elevator/Gate.luau does the same in Roblox's frame."""
    lead = OPEN + (CLOSED - OPEN) * min(max(shut, 0.0), 1.0)
    pitch = (lead - STACK) / (PICKETS - 1)
    xs = [STACK + i * pitch for i in range(PICKETS)]
    return xs, math.acos(min(pitch / STRAP, 1.0))


# --- the keypad, on the lobby wall right of the opening -------------------------------------
KEYPAD = (7.8, 4.0)      # its middle's x, z on the wall: at a player's chest (eyes at about 4.6)
BACKPLATE = (1.2, 1.85, 0.06)
HOUSING = (1.0, 1.62, 0.2)
READOUT = (0.0, 0.55, 0.76, 0.24)   # the readout's glass: middle x, z off the keypad's, size
KEY = 0.22               # a key's side; they stand 0.04 proud and travel KEY_TRAVEL when pressed
KEY_PITCH = 0.27
KEY_TRAVEL = 0.025
KEY_ROWS = (0.17, -0.10, -0.37, -0.64)   # z off the keypad's middle; 1 2 3 on top, 0 alone below
LIGHT = (-0.27, -0.64)   # the status light, left of 0; the speaker grille is right of it


def key_at(d):
    """Key d's middle (x, z) off the keypad's middle: 1 2 3 / 4 5 6 / 7 8 9 / 0."""
    if d == 0:
        return 0.0, KEY_ROWS[3]
    r, c = divmod(d - 1, 3)
    return (c - 1) * KEY_PITCH, KEY_ROWS[r]


LABEL_SHEET = (5, 2)     # the keys' digits, one cell each, 200 texels a cell

# --- the sticky note: a big pad's note, so it can be spotted from a unit's doorway --------------
NOTE = 0.7               # its side (a 28 cm note: Post-it's big pad)
NOTE_T = 0.008
CURL = (-0.08, 0.38, 0.3)    # where its foot starts curling (z), the curl's radius, and how much
                             # tighter it curls at the right corner
GLUE = 0.17              # the adhesive strip along the top of its back
WRITE = (0.0, 0.09, 0.62, 0.3)   # where the digits go on its face: middle x, z, size (flat there)
INK = "#1B1F2A"          # a black felt-tip gone a little blue
HAND = "Kalam"           # Roblox's font family for the digits (Bold in game)
PAPER = "#F1D957"


def b2r(v):
    """A Blender point in Roblox's frame."""
    return (-v[0], v[2], v[1])


def lua_vec(v, nd=3):
    return "{ " + ", ".join(f"{c:.{nd}f}" for c in v) + " }"


def colliders():
    """Invisible boxes the game collides with (the meshes don't): name, Blender lo, hi."""
    w, h = CAR_W / 2, CAR_H
    ow, oh = OPENING[0] / 2, OPENING[1]
    return [
        ("CarFloor", (-w, LANDING_SILL[1], -1.0), (w, CAR_BACK, 0.0)),
        ("CarBack", (-w, CAR_BACK, 0.0), (w, CAR_BACK + 0.5, h)),
        ("CarLeft", (-w - 0.5, CAR_FRONT, 0.0), (-w, CAR_BACK, h)),
        ("CarRight", (w, CAR_FRONT, 0.0), (w + 0.5, CAR_BACK, h)),
        ("CarCeiling", (-w, CAR_FRONT, h), (w, CAR_BACK, h + 0.5)),
        ("PostLeft", (-w, POST_Y[0], 0.0), (-w + POST, POST_Y[1], h)),
        ("PostRight", (w - POST, POST_Y[0], 0.0), (w, POST_Y[1], h)),
        ("Fascia", (-w, POST_Y[0], TRACK[0]), (w, POST_Y[1], h)),
        ("Header", (-ow, -PLATE, oh), (ow, WALL, oh + HEADER)),
    ]


def write_luau(path, parts):
    """parts: {name: dict(size=(x, y, z) Roblox, centre=(x, y, z) Blender, tris=n)}."""
    kx, kz = KEYPAD
    L = [
        "--!strict",
        "-- Generated by art/elevator/build.py --stage export from art/elevator/spec.py. Don't",
        "-- edit: change the spec and rebuild (scripts/art.sh elevator).",
        "-- Studs, in the elevator's own frame: the origin on the lobby floor at the middle of the",
        "-- threshold, the lobby in front (-Z, its LookVector), the car behind (+Z), Y up.",
        "",
        "export type Vec = { number } -- x, y, z",
        "export type Part = { Size: Vec, Centre: Vec, Triangles: number }",
        "export type Box = { Name: string, Centre: Vec, Size: Vec }",
        "",
        "local Specs = {",
        f"\tSets = {{ \"{SETS[0]}\", \"{SETS[1]}\", \"{SETS[2]}\" }},",
        "\t-- The hole in the lobby's back wall the landing's frame fills, and the wall's depth.",
        f"\tOpening = {{ Width = {OPENING[0]}, Height = {OPENING[1]}, Wall = {WALL} }},",
        "\t-- The car inside: wall to wall, its front and back (Z), floor to ceiling.",
        f"\tCar = {{ Width = {CAR_W}, Front = {CAR_FRONT}, Back = {CAR_BACK}, Height = {CAR_H} }},",
        "\t-- The lamp's glass, where its light goes.",
        f"\tLamp = {lua_vec(b2r((LAMP[0], LAMP[1], CAR_H - 0.56)))},",
        "\t-- The gate (Gate.luau poses it): the first picket's middle (X), the lead's with the gate",
        "\t-- shut and folded open, the pickets' plane (Z), feet and heads (Y), the rows of tongs",
        "\t-- (Y), a strap pin to pin, and the depth (Z) of the rising and falling straps.",
        "\tGate = {",
        f"\t\tPickets = {PICKETS},",
        f"\t\tStack = {-STACK:.4f},",
        f"\t\tClosed = {-CLOSED:.4f},",
        f"\t\tOpen = {-OPEN:.4f},",
        f"\t\tPlane = {GATE_Y},",
        f"\t\tFoot = {GATE_Z[0]},",
        f"\t\tHead = {GATE_Z[1]},",
        f"\t\tRows = {{ {', '.join(str(r) for r in ROWS)} }},",
        f"\t\tStrap = {STRAP},",
        f"\t\tLayers = {{ {LAYERS[0]:.4f}, {LAYERS[1]:.4f} }},",
        f"\t\tPicketWidth = {PICKET[0]},",
        f"\t\tLeadWidth = {LEAD[0] + RUBBER},",
        "\t},",
        "\t-- The keypad: each key's middle (indexed by digit + 1: Keys[1] is 0), how far a key",
        "\t-- travels when pressed (+Z, into the keypad), and the readout's glass.",
        "\tKeypad = {",
        f"\t\tCentre = {lua_vec(b2r((kx, -BACKPLATE[2] - HOUSING[2] / 2, kz)))},",
        "\t\tKeys = {",
    ]
    for d in range(10):
        x, z = key_at(d)
        L.append(f"\t\t\t{lua_vec(b2r((kx + x, -BACKPLATE[2] - HOUSING[2] - 0.02, kz + z)))}, -- {d}")
    rx, rz, rw, rh = READOUT
    L += [
        "\t\t},",
        f"\t\tTravel = {KEY_TRAVEL},",
        f"\t\tReadout = {{ Centre = {lua_vec(b2r((kx + rx, -BACKPLATE[2] - HOUSING[2] - 0.005, kz + rz)))}, "
        f"Size = {{ {rw}, {rh} }} }},",
        "\t},",
        "\t-- The sticky note, in its own frame: its back's middle is its pivot, stuck to whatever it's",
        "\t-- on, its face toward its LookVector. The digits are written in the flat area `Write`.",
        "\tNote = {",
        f"\t\tSide = {NOTE},",
        f"\t\tWrite = {{ Centre = {lua_vec(b2r((WRITE[0], -NOTE_T, WRITE[1])))}, Size = {{ {WRITE[2]}, {WRITE[3]} }} }},",
        f"\t\tFont = \"rbxasset://fonts/families/{HAND}.json\",",
        f"\t\tInk = {{ {', '.join(str(int(INK[i:i + 2], 16)) for i in (1, 3, 5))} }},",
        "\t},",
        "\t-- Each MeshPart's box as imported (its centre is its CFrame in the elevator's frame;",
        "\t-- the gate's parts and the note are centred on their own origins).",
        "\tParts = {",
    ]
    for name in sorted(parts):
        r = parts[name]
        sx, sy, sz = r["size"]
        L.append(f"\t\t{name} = {{ Size = {{ {sx:.3f}, {sy:.3f}, {sz:.3f} }}, "
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
