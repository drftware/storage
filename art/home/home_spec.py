"""Every number of the home's kit, in studs (art/home/README.md). Change them here only.

The home front (front.py) is built in the unit kit's frame (art/unit/spec.py): the origin on the
floor at the middle of the doorway's outer face, the floor outside toward -y, the unit toward +y,
z up. Each furnishing (furnish.py) stands on its own origin, the middle of its footprint on the
floor, its front toward -y. The FBX turns Blender into Roblox's frame as the unit's and the
lobby's do (Roblox X = -x, Y = z, Z = y). Named home_spec.py, not spec.py: the unit's modules
import their own `spec` by name.
"""

import math
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
# The mirror (S5-03f1, D-314): a full-length floor mirror in a moulded oak frame, leaning on the
# unit's left wall by the rug. The glass is the picture MirrorView draws (D-280): across, tall.
MIRROR_GLASS = (2.4, 5.6)
MIRROR_BEVEL = 0.06      # the glass's bevelled edge round the picture, catching the light
MIRROR_FACE = 0.28       # the oak moulding's width from the bevel out
MIRROR_DEPTH = 0.22      # the frame front (its rounded crown) to back
MIRROR_SET = 0.08        # how far the glass sits back from the crown, so the frame casts a lip
MIRROR_FEET = 0.04       # the felt pads it stands on, and the two on its top's back
MIRROR_LEAN = 6.0        # degrees its top leans back onto the wall, as a floor mirror stands
MIRROR_IN = 12.5         # its foot's middle, this far in from the doorway; across, it stands
                         # where its top pads just touch the left wall (mirror_at)
PARTITION = 0.25         # the units' side walls, thick (art/lobby/spec.py), the wall it leans on
                         # (inside a cubby, clear of its sides, its board above and its back)
# The clothes rail (S5-03f2a, D-315): a rolling oak garment rail beside the mirror, three rows for
# what you wear: hats on its top shelf, clothes on hangers from its steel bar, shoes on its rack.
GARMENT = (4.4, 1.5, 4.95)  # the oak frame: long (post to post, outside), deep, the posts' tops
GARMENT_POST = 0.16         # the four oak posts, square
GARMENT_TOP = (0.06, 0.12, 0.14)  # the hat shelf's board: past the posts all round, thick; its
                         # gallery rail along the back, tall above the board (hats stay on)
GARMENT_BAR = (4.3, 0.055)  # the steel hanging bar: its middle's height, its radius
GARMENT_RACK = (0.44, 0.62, 0.06)  # the posts' feet (the castors' tops), the bottom frame's top,
                         # the shoe rack's slats on it, thick
GARMENT_WHEEL = (0.17, 0.1)  # each castor's rubber wheel: radius, wide
GARMENT_HANGERS = (-1.25, 0.0, 1.25)  # the oak hangers on the bar, along it from its middle
GARMENT_HANGER = (0.58, 0.2, 0.18, 0.035)  # a hanger: half its shoulders' span, how far its peak
                         # hangs under the bar, how far its shoulders drop to their tips, its
                         # dowel's radius
GARMENT_IN = 17.0           # its middle, this far in from the doorway, past the mirror on the same
GARMENT_OFF = 0.12          # wall; across, its back this far off that wall's face


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


# The job box (S5-03c2a, D-287): the steel job-site box that holds every find you own, its steel
# powder-coated a calm dusty blue (the game's paint over the Plaster set's stipple, which reads as
# powder coat), graphite handles and hasp, on two oak runners. The body is an open chest, the lid a
# tray over its top edge, hinged along the back so its front swings up.
JOBBOX = (4.4, 2.2, 2.0, 0.42, 0.28)  # the body: long, deep, tall above the runners; the lid's
                                      # height above the body's top; the oak runners' height
JOBBOX_WALL = 0.08       # the body's and the lid's steel, thick (so an open lid shows a real edge)
JOBBOX_LIP = 0.06        # how far the lid stands proud of the body all round
JOBBOX_SKIRT = 0.12      # how far the lid's skirt comes down over the body's top edge


def jobbox_hinge():
    """The lid's hinge line's middle, in the piece's frame: the back skirt's outer foot, so the
    lid swings up and back clear of the body. The game turns the lid about x through here."""
    L, D, H, lid, run = JOBBOX
    return (0.0, D / 2 + JOBBOX_LIP, run + H - JOBBOX_SKIRT)


# Where each piece of a unit's starter set stands, in the unit frame (x, y in from the doorway),
# turned about z in degrees (0: its front toward the door). From the doorway: the rug in the
# middle, the beanbag on its far left corner facing you, the lamp glowing behind it. The job box
# stands against the left wall beside the shelf, facing into the room (my default, OWNER.md), its
# back 0.8 studs off the wall so its lid opens upright clear of it.
STARTER = (("Rug", (0.0, 9.5), 0.0), ("Beanbag", (-2.3, 10.6), -22.0),
           ("FloorLamp", (-5.4, 12.8), 0.0), ("Shelf", (0.0, 15.2), 0.0),
           ("JobBox", (-7.9, 17.6), 90.0))

# Each furnishing's parts: a game piece is these MeshParts standing on one origin.
PIECES = {"Plant": ("Pot", "Plant"), "Bench": ("Bench",), "Planter": ("Planter", "PlanterSeat",
          "PlanterPlants"), "Rug": ("Rug",), "Beanbag": ("Beanbag",),
          "FloorLamp": ("FloorLamp", "LampShade"), "Shelf": ("Shelf", "ShelfBack"),
          "JobBox": ("JobBox", "JobBoxLid", "JobBoxFittings", "JobBoxRunners"),
          "Mirror": ("MirrorFrame", "MirrorBevel", "MirrorPads"),
          "Rail": ("Rail", "RailHangers", "RailSteel", "RailWheels")}


def mirror_box():
    """The mirror's sizes: the opening's half width and half height (the glass and its bevel),
    the opening's middle's height, and the whole frame across and tall."""
    w, h = MIRROR_GLASS
    a, b = w / 2 + MIRROR_BEVEL, h / 2 + MIRROR_BEVEL
    return a, b, MIRROR_FEET + MIRROR_FACE + b, 2 * (a + MIRROR_FACE), MIRROR_FEET + 2 * (b + MIRROR_FACE)


def mirror_glass_y():
    """The glass's front, front to back in the piece's frame (front toward -y)."""
    return -MIRROR_DEPTH / 2 + MIRROR_SET


def mirror_at():
    """Where the mirror's foot stands in the unit frame (x across, y in), so that leaning back
    MIRROR_LEAN degrees its top pads just touch the left wall's face."""
    _, _, _, _, tall = mirror_box()
    lean = math.radians(MIRROR_LEAN)
    pad_back, pad_top = MIRROR_DEPTH / 2 + MIRROR_FEET, tall - 0.1
    reach = pad_top * math.sin(lean) + pad_back * math.cos(lean)
    return (SLOT[0] / 2 - PARTITION / 2 - reach, MIRROR_IN)


def rail_at():
    """Where the rail's middle stands in the unit frame (x across, y in): along the mirror's wall,
    its back GARMENT_OFF off the wall's face. Turned as the mirror is, its front looks across the unit."""
    return (SLOT[0] / 2 - PARTITION / 2 - GARMENT_OFF - GARMENT[1] / 2 - GARMENT_TOP[0], GARMENT_IN)


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
          "\t-- The job box (D-287): its lid's hinge line's middle in the JobBox piece's frame; the lid",
          "\t-- (JobBoxLid) turns about X through it, a positive turn lifting its front.",
          f"\tJobBox = {{ Hinge = {lua_vec(b2r(jobbox_hinge()))} :: Vec }},",
          "\t-- The mirror (D-314): its foot's middle in the unit's frame, its glass looking across the",
          "\t-- unit (turned -90 about Y), leaning back Lean degrees about its own X onto the left wall.",
          "\t-- In the Mirror piece's frame: Glass, the middle of the glass's front face; GlassSize, the",
          "\t-- picture across and tall; Size, the whole frame across and tall.",
          "\tMirror = {"]
    gw, gh = MIRROR_GLASS
    _, _, mid, wide, tall = mirror_box()
    ax, ay = mirror_at()
    L += [f"\t\tAt = {lua_vec(b2r((ax, ay, 0.0)))} :: Vec,",
          "\t\tTurn = -90,",
          f"\t\tLean = {MIRROR_LEAN:.1f},",
          f"\t\tGlass = {lua_vec(b2r((0.0, mirror_glass_y(), mid)))} :: Vec,",
          f"\t\tGlassSize = {{ {gw:.3f}, {gh:.3f} }} :: Vec,",
          f"\t\tSize = {{ {wide:.3f}, {tall:.3f} }} :: Vec,",
          "\t},",
          "\t-- The clothes rail (D-315): its middle on the floor in the unit's frame, turned as the",
          "\t-- mirror is. In the Rail piece's frame: Size, the whole rail across, tall and deep; Shelf,",
          "\t-- the hat shelf's top; Bar, the hanging bar's middle; Rack, the shoe rack's top; Hangers,",
          "\t-- each hanger's middle along the bar (its hook over it).",
          "\tRail = {"]
    rx, ry = rail_at()
    long_, deep, posts = GARMENT
    over, board, gallery = GARMENT_TOP
    bar, _ = GARMENT_BAR
    _, rack, slat = GARMENT_RACK
    L += [f"\t\tAt = {lua_vec(b2r((rx, ry, 0.0)))} :: Vec,",
          "\t\tTurn = -90,",
          f"\t\tSize = {{ {long_ + 2 * over:.3f}, {posts + board + gallery:.3f}, {deep + 2 * over:.3f} }} :: Vec,",
          f"\t\tShelf = {posts + board:.3f},",
          f"\t\tBar = {bar:.3f},",
          f"\t\tRack = {rack + slat:.3f},",
          "\t\tHangers = { " + ", ".join(f"{-x:.3f}" for x in GARMENT_HANGERS) + " } :: { number },",
          "\t},"]
    L += [
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
