"""Every number of the home's kit, in studs (art/home/README.md). Change them here only.

The home front (front.py) is built in the unit kit's frame (art/unit/spec.py): the origin on the
floor at the middle of the doorway's outer face, the floor outside toward -y, the unit toward +y,
z up. Each furnishing (furnish.py) stands on its own origin, the middle of its footprint on the
floor, its front toward -y. The FBX turns Blender into Roblox's frame as the unit's and the
lobby's do (Roblox X = -x, Y = z, Z = y). Named home_spec.py, not spec.py: the unit's modules
import their own `spec` by name.
"""

import os

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", ".."))

DOOR_SIZE = "M"          # the climb's door rig the home front is built round (the lobby's gaps)
SLOT = (20.0, 30.0)      # the unit behind it (XL, art/lobby/spec.py): across, the doorway to the
                         # back wall's middle

# --- the front: a doorway in a home's wall, not the climb's steel lockup -----------------------
CASING = (0.5, 0.12)     # the oak casing round the doorway: its face's width, how proud of the wall
PLINTH = (0.7, 0.16)     # the plinth blocks at the casing's feet: tall, proud (above the baseboard)
HEAD_CAP = (0.14, 0.2, 0.12)  # the cornice on the casing's head: tall, proud, past it each side
LINER = 0.1              # the oak lining the doorway's sides and head, from the face back to the
                         # door's guides (the climb's steel jamb covers did that)
BASE = 0.55              # the baseboard's height: the lobby's (art/lobby/spec.py BASE, checked)
BASE_PROUD = 0.07        # the lobby's baseboard's depth off the wall
RAIL = (0.32, 0.12)      # the rail where the wall's two paints meet: the lobby's (checked)

# The light switch, inside by the door (D-263): twice a real plate's size, so it reads on a phone.
SWITCH = (0.45, 0.7, 0.05)   # the plate: wide, tall, thick
SWITCH_AT = (-5.4, 4.0)      # its middle on the front wall's inside face: x (the unit frame;
                             # on your left as you walk in), height (an R15 hand's reach)
TOGGLE = (0.16, 0.3, 0.07)   # the rocker on it: wide, tall, proud
TOGGLE_TILT = 12.0           # degrees it rocks each way about X: top in is on (the game poses it)

LAMP = (2.2, 0.16)       # the unit's own round ceiling lamp, the lobby's look: across, hang
LAMP_AT = 15.0           # its middle, this far in from the doorway (the unit's middle)

# --- furnishings: each its own part (D-263, D-266) ---------------------------------------------
POT = (0.78, 0.6, 1.6)   # the plant's pot: radius at the top, at the foot, tall
POT_RIM = (0.86, 0.7, 0.14)  # its rolled rim: outer radius, inner radius, tall
PLANT = (9, 2.2, 3.1, 0.44)  # a potted snake plant: leaves, shortest and longest leaf, widest

BENCH = (5.6, 1.7, 1.7, 3.4)  # the oak bench: long, deep, seat's top, back's top
PLANTER = (7.0, 1.55, 0.9, 0.15)  # the islands' planter: square across, its wall's top, the oak
                                  # seat round it (deep), the seat's thickness
PLANTER_CLUMPS = ((0.0, 0.0), (1.45, 1.2), (-1.4, 1.35), (1.3, -1.4), (-1.5, -1.25))
                                  # where its snake plants grow (x, y off its middle)
RUG = (8.0, 6.0, 0.04)   # the starter rug: across, front to back, thick
BEANBAG = (3.2, 3.0, 2.2)  # across, front to back, tall
FLOOR_LAMP = (0.55, 5.3, 0.85, 0.66, 1.1)  # base radius, the stem's top, the shade's radius at
                                           # the foot and the top, the shade's height
SHADE_GAP = 0.25         # how far the shade's foot sits below the stem's top (the bulb's in it)

# The shelf (S5-03c1a, D-284): an open oak shelf, a cream painted back, finds on show in its cubbies.
# The small unit's six: across, up, each cubby's inside width and height, its depth front to
# back, the oak boards' thickness, the legs' height under the bottom board.
SHELF = (3, 2, 2.3, 2.2, 1.6, 0.14, 0.45)
SHELF_BACK = 0.08        # the painted back's thickness, set in from the frame's back edge
SHELF_ROOM = (2.0, 2.0, 1.3)  # the box a find is fitted into on its spot: across, tall, deep
                         # (inside a cubby, clear of its sides, its board above and its back)


def shelf_spots():
    """Each spot's middle on its board, in the shelf's frame (front toward -y), left to right
    as you face it, bottom row first."""
    cols, rows, w, h, d, t, legs = SHELF
    width = cols * w + (cols + 1) * t
    out = []
    for r in range(rows):
        z = legs + t + r * (h + t)
        for c in range(cols):
            x = width / 2 - t - w / 2 - c * (w + t)  # facing it from -y, its left is +x
            out.append((x, -SHELF_BACK / 2, z))
    return out


# Where each piece of a unit's starter set stands, in the unit frame (x, y in from the doorway),
# turned about z in degrees (0: its front toward the door). From the doorway: the rug in the
# middle, the beanbag on its far left corner facing you, the lamp glowing behind it.
STARTER = (("Rug", (0.0, 9.5), 0.0), ("Beanbag", (-2.3, 10.6), -22.0),
           ("FloorLamp", (-5.4, 12.8), 0.0), ("Shelf", (0.0, 15.2), 0.0))

# Each furnishing's parts: a game piece is these MeshParts standing on one origin.
PIECES = {"Plant": ("Pot", "Plant"), "Bench": ("Bench",), "Planter": ("Planter", "PlanterSeat",
          "PlanterPlants"), "Rug": ("Rug",), "Beanbag": ("Beanbag",),
          "FloorLamp": ("FloorLamp", "LampShade"), "Shelf": ("Shelf", "ShelfBack")}


def b2r(v):
    """A Blender point in Roblox's frame."""
    return (-v[0], v[2], v[1])


def lua_vec(v, nd=3):
    return "{ " + ", ".join(f"{c:.{nd}f}" for c in v) + " }"


def write_luau(path, parts, switch, toggle, lamp):
    """parts: {name: dict(size=(x, y, z) Roblox, centre=Blender, tris=n)}; switch, toggle, lamp:
    their middles in the unit frame (Blender)."""
    L = [
        "--!strict",
        "-- Generated by art/home/build.py --stage export from art/home/home_spec.py. Don't edit:",
        "-- change the spec and rebuild (scripts/art.sh home).",
        "-- The home's kit (D-263, D-266): the home front, the climb's M door rig in a home's doorway,",
        "-- and the furnishings. Studs. The front's parts sit in the unit's frame (StorageUnit.Specs:",
        "-- the origin on the floor at the middle of the doorway's outer face, the floor outside -Z,",
        "-- the unit +Z, Y up); each furnishing on its own origin, the middle of its footprint on the",
        "-- floor, its front toward -Z.",
        "",
        "export type Vec = { number } -- x, y, z",
        "export type Part = { Size: Vec, Centre: Vec, Triangles: number }",
        "export type Placed = { Kind: string, At: Vec, Turn: number }",
        "",
        "local Specs = {",
        f"\tDoorSize = \"{DOOR_SIZE}\", -- the climb's door rig it's built round",
        "\t-- The light switch inside by the door: the plate's middle, the rocker's middle (it rocks",
        "\t-- about X by Tilt degrees each way, top in when on).",
        f"\tSwitch = {{ Plate = {lua_vec(b2r(switch))}, Toggle = {lua_vec(b2r(toggle))}, "
        f"Tilt = {TOGGLE_TILT} }},",
        "\t-- The unit's round ceiling lamp's middle (a plain part the game makes Neon when on).",
        f"\tLamp = {lua_vec(b2r(lamp))},",
        "\t-- Each furnishing a game piece is: its MeshParts, standing on one origin.",
        "\tPieces = {",
    ]
    for kind, names in PIECES.items():
        L.append(f"\t\t{kind} = {{ " + ", ".join(f"\"{n}\"" for n in names) + " },")
    L += ["\t} :: { [string]: { string } },",
          "\t-- A unit's starter set (D-263): each piece's origin in the unit's frame, turned about Y",
          "\t-- (degrees, 0 with its front toward the door).",
          "\tStarter = {"]
    for kind, (x, y), turn in STARTER:
        L.append(f"\t\t{{ Kind = \"{kind}\", At = {lua_vec(b2r((x, y, 0.0)))}, Turn = {turn:.1f} }},")
    L += ["\t} :: { Placed },",
          "\t-- The shelf (D-284): each spot's middle on its board in the Shelf piece's frame, left to",
          "\t-- right facing it, bottom row first; Room, the box a find is fitted into there (across,",
          "\t-- tall, deep), a find's bottom on the spot.",
          "\tShelf = {",
          "\t\tSpots = {"]
    for p in shelf_spots():
        L.append(f"\t\t\t{lua_vec(b2r(p))},")
    rx, ry, rz = SHELF_ROOM
    L += ["\t\t} :: { Vec },",
          f"\t\tRoom = {{ {rx:.3f}, {ry:.3f}, {rz:.3f} }} :: Vec,",
          "\t},",
          "\t-- Each MeshPart's box as imported (its centre is its CFrame in its frame).",
          "\tParts = {"]
    for name in sorted(parts):
        r = parts[name]
        px, py, pz = r["size"]
        L.append(f"\t\t{name} = {{ Size = {{ {px:.3f}, {py:.3f}, {pz:.3f} }}, "
                 f"Centre = {lua_vec(b2r(r['centre']))}, Triangles = {r['tris']} }},")
    L += ["\t} :: { [string]: Part },", "}", "", "return Specs", ""]
    with open(path, "w") as f:
        f.write("\n".join(L))
    print("SPEC", path)
