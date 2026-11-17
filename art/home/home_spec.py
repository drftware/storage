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


# The counter's furniture, part one (S5-03g1c1, D-323): what turns a unit into somewhere friends
# hang out (idea 19), each something you'd sit on, set a find on or gather round. Sized to the
# game's chunky scale (a person 5.4 tall, the bench's seat at 1.7).
CRATE = (1.9, 1.9, 1.65, 0.075)  # the milk crate, upturned to sit on: across, deep, tall (its top is
                                 # the seat, a little under the bench's); its plastic, thick
CRATE_GRID = (4, 3, 4)           # its holes: across each side, up each side, each way across its top
CRATE_BANDS = (0.3, 0.13, 0.11)  # the solid bands: the rim on the floor (its hand slots in it), the
                                 # top's edge, and the ribs' width between the holes
CRATE_SLOT = (0.75, 0.12)        # the hand slot through the rim on its left and right: wide, tall
PALLET = (4.4, 3.6, 0.6)         # one pallet: long (its stringers), deep (its deck boards), tall
PALLET_BOARD = (0.46, 0.11, 7, 5)  # a deck board: wide, thick; how many on top, how many under
PALLET_STRINGER = 0.26           # the three stringers' width (their notched faces look out the front)
PALLET_NOTCH = (0.95, 0.2)       # the fork notches under each stringer: long, tall
PALLET_STACK = 2                 # pallets stacked into the coffee table (its top at 1.2: knee height)
TABLE = (4.6, 2.3, 2.8)          # the folding table: long, deep, its top's height (a seat at 1.7)
TABLE_TOP = (0.07, 0.22, 0.22)   # its moulded top: the plate's thickness, the rim's depth under it,
                                 # the corners' radius
TABLE_LEG = (0.055, 0.45, 0.8)   # the legs' steel tube radius; each leg frame in from the top's ends;
                                 # the two legs' half spread across its depth
STEEL = (3.6, 1.5, 6.0)          # the steel shelf: across, deep, tall
STEEL_TIERS = (0.35, 2.2, 4.05, 5.9)  # each tier's top: four, the room between them a find's
STEEL_ANGLE = (0.22, 0.04)       # the angle posts: each leg's width, the steel's thickness
STEEL_LIP = 0.16                 # each tier's edge folded down from its top, front and back

# The counter's furniture, part two (S5-03g1c2, D-324): soft things and warm light, what makes a
# unit somewhere you'd stay. The blanket and camp bed stand on the floor like the rest; the string
# lights hang from their clips (their origin the clips' line, the cable below it, -z), and the neon
# sign hangs on a wall like a name card (its origin its middle on the wall's face, front -y).
BLANKET = (3.2, 2.7, 0.44)       # a moving blanket folded into a floor cushion: across, deep, tall
                                 # (a seat on the floor round the pallet table, its top at 1.2)
BLANKET_LAYERS = 4               # folds you see stacked up its sides, each bulging, pinched between
BLANKET_QUILT = (0.62, 0.075)    # the quilting's diamonds: across one, how deep the stitches pull
BLANKET_BIND = 0.042             # the binding round its open edges (front and right): its radius
CAMP_BED = (6.4, 2.5, 1.45)      # the camp bed: long, across its rails, the rails' height (under
                                 # the crate's seat: you lie on it, your feet stay near the floor)
CAMP_SAG = 0.3                   # the canvas sags this far at its middle under nobody
CAMP_TUBE = (0.06, 0.55)         # the frame's tube radius; the end bars this far in from the rails'
                                 # ends (the canvas runs between them)
CAMP_PILLOW = (0.95, 1.7, 0.36)  # the pillow at its head (+x): long, across, thick
STRING = (9.6, 3, 0.7, 0.15)     # the string lights: long, swags, each swag's droop, the clips'
                                 # hooks (a small home is 10 across: it spans one)
STRING_BULBS = (12, 0.15, 0.3)   # bulbs: how many, the globe's radius, its middle below the cable
STRING_LIGHT = (16.0, 1.2, "#FFC27A")  # its one real light (near only, D-271): range (to the floor
                                 # under a home's 10-high ceiling, lamp off), brightness,
                                 # the bulbs' warm colour (the game makes them Neon in it)
NEON_SIGN = (2.9, 2.8, 0.06, 0.14)  # the neon sign's clear backing: across, tall, thick, off the wall
NEON_MOON = (1.1, 1.1, (0.38, 0.32))  # a crescent moon: the outer circle's radius, the bite's
                                 # radius and its middle from the moon's (x, up)
NEON_STAR = (0.36, 0.15, (0.76, 0.64))  # a star in the moon's hollow: points' radius, the dips'
                                 # radius, its middle from the moon's
NEON_SIGN_TUBE = (0.05, 0.09)    # the tube's radius, off the backing's face
NEON_LIGHT = (8.0, 1.1, "#FFD27A")  # its one real light (near only): range, brightness, the glow's
                                 # colour (warm yellow to start; the game colours the tube)


PINE = (8, 4.4)  # the Pine set (looks.py): boards across it, each running its height in studs; the
                 # first six the deck boards, nailed at pallet_nails(), the last two the stringers'


def pallet_nails():
    """Where a deck board crosses the stringers, studs along it from its end: the Pine set bakes
    a pair of nail heads at each (looks.py)."""
    d, s = PALLET[1], PALLET_STRINGER
    return (s / 2, d / 2, d - s / 2)


def furniture_tops():
    """Each new piece's flat tops a find can stand on or you sit on (idea 14): the top's middle in
    the piece's frame (Blender) and its size across and deep."""
    cw, cd, ch, _ = CRATE
    pl, pd, ph = PALLET
    tl, td, th = TABLE
    sw, sd, _ = STEEL
    a, t = STEEL_ANGLE
    return {"MilkCrate": [((0.0, 0.0, ch), (cw, cd))],
            "Pallet": [((0.0, 0.0, ph * PALLET_STACK), (pl, pd))],
            "FoldingTable": [((0.0, 0.0, th), (tl, td))],
            "SteelShelf": [((0.0, 0.0, z), (sw - 2 * t, sd - 2 * t)) for z in STEEL_TIERS],
            "Blanket": [((0.0, 0.0, BLANKET[2]), (BLANKET[0] - 0.5, BLANKET[1] - 0.5))],
            "CampBed": [((-0.6, 0.0, CAMP_BED[2] - CAMP_SAG), (CAMP_BED[0] - 3.0, CAMP_BED[1] - 0.8))]}


def glows():
    """The pieces that light up (D-324): the parts the game makes Neon, the parts it makes clear
    glass, and the one real light each throws (near only, D-271), its middle in the piece's frame
    (Blender)."""
    length, swags, droop, hook = STRING
    _, globe, drop = STRING_BULBS
    srange, sbright, scol = STRING_LIGHT
    nrange, nbright, ncol = NEON_LIGHT
    return {"StringLights": (("StringBulbs",), (), (0.0, -0.6, -hook - droop - drop), srange,
                             sbright, scol),
            "NeonSign": (("NeonSignTube",), ("NeonSignBack",), (0.0, -0.9, 0.0), nrange, nbright,
                         ncol)}


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
          "Rail": ("Rail", "RailHangers", "RailSteel", "RailWheels"),
          "MilkCrate": ("MilkCrate",), "Pallet": ("Pallet",),
          "FoldingTable": ("FoldingTable", "FoldingTableLegs"),
          "SteelShelf": ("SteelShelf", "SteelShelfBolts"),
          "Blanket": ("Blanket", "BlanketBinding"),
          "CampBed": ("CampBed", "CampBedFrame", "CampBedPillow"),
          "StringLights": ("StringLights", "StringBulbs"),
          "NeonSign": ("NeonSignTube", "NeonSignBack", "NeonSignFittings")}


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


# --- the looks a player gives their home (S5-03g1a, D-321) ---------------------------------------
# Calm and warm (D-263), a couple of fun ones, nothing that looks like the climb. Each list starts
# with what a home has before anyone changes it. Ids are what a home's save keeps: never rename one.
# Each floor set tiles at FLOOR_TILE studs and each paper at PAPER_TILE (looks.py), so the game's
# one floor panel and one wall panel wear any of them; the colour a look takes is the part's Color.
FLOOR_TILE = 8.0
PAPER_TILE = 4.0
# The paint on a home's walls (plain plaster or under a paper's print).
PAINTS = (("WarmWhite", "#E8DFCF"), ("Butter", "#EAD8A4"), ("Blush", "#E3BDB1"),
          ("Sage", "#A9B899"), ("DuckEgg", "#A8C4C5"), ("Lavender", "#BEB3CF"),
          ("Terracotta", "#C98A6B"), ("Ink", "#41506A"))
# The roll-up door, what the hall sees while it's down: each reads against the lobby's teal.
DOORS = (("Clay", "#B5684E"), ("Mustard", "#CF9F3C"), ("Tomato", "#C24A3A"), ("Rose", "#D9919A"),
         ("Plum", "#7A4C6B"), ("Sky", "#8DB3CC"), ("Mint", "#A3CFB8"), ("Cream", "#E6D9BF"))
# The floors: id, texture set, the colours it takes (none: its colours are baked).
FLOORS = (("Boards", "Wood", ()),
          ("Carpet", "FloorCarpet", (("Oatmeal", "#CDBFA6"), ("Sage", "#9DAA8C"),
                                     ("Rose", "#C99A93"), ("Denim", "#7F95A8"),
                                     ("Cocoa", "#7A5E4C"))),
          ("Checker", "FloorTiles", (("Terracotta", "#B8654A"), ("Sage", "#7F9672"),
                                     ("Sky", "#86A9BE"), ("Cherry", "#B23A3A"),
                                     ("Charcoal", "#3C3A38"))),
          ("Matting", "FloorMatting", (("Charcoal", "#3D3B39"), ("Slate", "#4A5866"),
                                       ("Forest", "#3F5546"), ("Plum", "#5A4152"),
                                       ("Clay", "#8A5A47"))))
# The walls: id, texture set. Every paper takes the wall's paint as its ground.
PAPERS = (("Plain", "Plaster"), ("Stripes", "PaperStripes"), ("Leaves", "PaperLeaves"),
          ("Daisies", "PaperDaisies"))

# The panels the looks land on (S5-03g2a, D-325, panels.py): a floor panel and a wall panel per
# partition, the back wall and the front wall's inside, each its own part over the lobby's merged
# unit walls and floor.
PANEL_PROUD = 0.02   # each panel's thickness off the wall or floor under it: a hair, so the lobby's
                     # walls stay under it, the baseboards (0.06 proud) still stand in front and a
                     # rug (0.04) still lies on it; enough that the two never flicker at a unit's
                     # depth on a phone's depth buffer
SWATCH = (2.0, 0.1)  # each set's swatch (the part that carries its SurfaceAppearance into Studio,
                     # and the picker's chip): across and tall, thick; half a tile on its face


# The name card over a home's door (S5-03g1b, D-322): four plates, each its own part(s) on one
# origin, the card's middle on the wall's face (the lobby's R-panel), its front toward -y. The
# lobby's CARD (art/lobby/spec.py) is 6 by 1.4 studs, its middle 11.4 up, between the units' cap
# at 10 and the deck at 14: every plate stays inside 10.3 to 13.6. Lettering is a SurfaceGui on
# Face (the writing's middle, how far out from the wall) over FaceSize; Font a family under
# Studio's content/fonts/families (Font.fromName), checked there (STUDIO.md).
CARD_STEEL = (6.0, 1.4, 0.06, 0.12)   # the steel plate: across, tall, thick, its back off the wall
CARD_FOLD = 0.07                      # its edges folded back toward the wall, a sign blank's return
CARD_BEAD = 0.13                      # the pressed bead round its face, in from the edge
CARD_BOARD = (6.3, 1.56, 0.12, 0.08)  # the painted board: across, tall, thick; the cleats behind it
CARD_STRIPE = 0.11                    # the sign-writer's pinstripe, in from the board's edge
CARD_SLATE = (6.0, 1.4)               # the chalkboard's slate, inside its frame
CARD_FRAME = 0.2                      # the oak frame's face, out from the slate's edge
CARD_LEDGE = (0.14, 0.07)             # the chalk ledge under it: how far proud, thick
CARD_NEON = (6.4, 1.7, 0.08, 0.1)     # the neon's dark backing: across, tall, thick, off the wall
CARD_TUBE = (0.045, 0.16, 0.08)       # the border tube: radius, in from the backing's edge, off it
# Each reads on the hall's cream upper wall (Lobby.Paint.Cream #E6DDCC), so every plate is dark.
# id, who has it (Starter: every home; Cash; Robux), the plate's colour (None: baked), the
# lettering's family and weight, its ink, the glow (neon only: the tube and the light).
CARDS = (("Stencil", "Starter", "#34414F", ("Oswald", "Bold"), "#EFE7D6", None),
         ("Painted", "Cash", "#2F4F3F", ("LuckiestGuy", "Regular"), "#F2E6C9", None),
         ("Chalk", "Cash", None, ("PatrickHand", "Regular"), "#F1F0E8", None),
         ("Neon", "Robux", "#16171C", ("Nunito", "Regular"), "#FFF0F6", "#FF4F9E"))
CARD_LIGHT = (9.0, 1.4)               # the neon's light on the wall round it: range, brightness


def card_faces():
    """Each style's writing: (middle as (x, y, z) Blender, (across, tall))."""
    w, h, t, off = CARD_STEEL
    bw, bh, bt, cleat = CARD_BOARD
    sw, sh = CARD_SLATE
    nw, nh, nt, noff = CARD_NEON
    r, tin, toff = CARD_TUBE
    return {"Stencil": ((0.0, -off - t - 0.005, 0.0), (w - 2 * CARD_BEAD - 0.12, h - 2 * CARD_BEAD - 0.08)),
            "Painted": ((0.0, -cleat - bt - 0.005, 0.0), (bw - 2 * CARD_STRIPE - 0.3, bh - 2 * CARD_STRIPE - 0.16)),
            "Chalk": ((0.0, -card_slate_y() - 0.005, 0.0), (sw - 0.3, sh - 0.2)),
            "Neon": ((0.0, -noff - nt - toff, 0.0), (nw - 2 * tin - 0.4, nh - 2 * tin - 0.3))}


def card_slate_y():
    """How far the slate's face stands off the wall: just behind the frame's inner lip."""
    return 0.1


def luau_cards(parts_of):
    """The name cards' lines for Home.Specs; parts_of: {style: [part names]}."""
    faces = card_faces()
    L = ["\t-- The name card's styles (D-322): each a plate over the door on one origin, the card's",
         "\t-- middle on the wall's face, its front toward -Z. Face: the writing's middle in that",
         "\t-- frame; FaceSize, across and tall. Font: a family for Font.fromName and its weight",
         "\t-- (Enum.FontWeight). Ink: the lettering's colour; Paint, the plate's (nil: baked); Glow,",
         "\t-- the neon's tube and light colour. Sold: Starter (every home), Cash or Robux.",
         "\tCards = {"]
    for i, sold, paint, (fam, weight), ink, glow in CARDS:
        (c, (fw, fh)) = faces[i]
        L.append(f"\t\t{{ Id = \"{i}\", Sold = \"{sold}\", Parts = {{ "
                 + ", ".join(f"\"{n}\"" for n in parts_of[i]) + " },")
        extra = f", Paint = \"{paint}\"" if paint else ""
        extra += f", Glow = \"{glow}\"" if glow else ""
        L.append(f"\t\t\tFace = {lua_vec(b2r(c))}, FaceSize = {{ {fw:.3f}, {fh:.3f} }},")
        L.append(f"\t\t\tFont = \"{fam}\", Weight = \"{weight}\", Ink = \"{ink}\"{extra} }},")
    rng, bright = CARD_LIGHT
    L += ["\t} :: { CardStyle },",
          f"\tCardLight = {{ Range = {rng:.1f}, Brightness = {bright:.2f} }},"]
    return L


def luau_looks():
    """The looks' lines for Home.Specs."""
    def swatches(rows, ind):
        return [f"{ind}{{ Id = \"{i}\", Colour = \"{c}\" }}," for i, c in rows]
    L = ["\t-- The looks a player gives their home (D-321). Ids are what a home's save keeps; each",
         "\t-- list starts with a new home's. Colours are hex for Color3.fromHex. Floors tile at",
         "\t-- FloorTile studs and papers at PaperTile, so one floor panel and one wall panel (UVs in",
         "\t-- studs over the tile) wear any set; a look's colour is the part's Color (Overlay).",
         "\tLooks = {",
         f"\t\tFloorTile = {FLOOR_TILE:.1f},",
         f"\t\tPaperTile = {PAPER_TILE:.1f},",
         "\t\tPaints = {"]
    L += swatches(PAINTS, "\t\t\t")
    L += ["\t\t} :: { Swatch },", "\t\tDoors = {"]
    L += swatches(DOORS, "\t\t\t")
    L += ["\t\t} :: { Swatch },", "\t\tFloors = {"]
    for i, s, cols in FLOORS:
        if cols:
            L.append(f"\t\t\t{{ Id = \"{i}\", Set = \"{s}\", Colours = {{")
            L += swatches(cols, "\t\t\t\t")
            L.append("\t\t\t} },")
        else:
            L.append(f"\t\t\t{{ Id = \"{i}\", Set = \"{s}\", Colours = {{}} }},")
    L += ["\t\t} :: { Floor },", "\t\tPapers = {"]
    L += [f"\t\t\t{{ Id = \"{i}\", Set = \"{s}\" }}," for i, s in PAPERS]
    L += ["\t\t} :: { Paper },", "\t},"]
    return L


def luau_panels(panels, swatches):
    """The panels' and swatches' lines for Home.Specs. panels: (part, middle, turn) in the unit
    frame (Blender); swatches: set to part."""
    L = ["\t-- The panels a home's looks land on (D-325): each its own part on its own origin (its",
         "\t-- middle, its face toward -Z), At its middle in the unit's frame, turned Turn degrees",
         "\t-- about Y. The floor wears a floor's set, the walls a paper's, cloned from Swatches (a",
         "\t-- game script can't write a SurfaceAppearance's maps); the lobby's walls stay under them.",
         "\tPanels = {"]
    row = lambda n, at, turn: f"{{ Part = \"{n}\", At = {lua_vec(b2r(at))}, Turn = {turn:.1f} }}"
    floor = [p for p in panels if p[0] == "PanelFloor"][0]
    L += [f"\t\tFloor = {row(*floor)},", "\t\tWalls = {"]
    L += [f"\t\t\t{row(*p)}," for p in panels if p[0] != "PanelFloor"]
    L += ["\t\t},", "\t} :: { Floor: Panel, Walls: { Panel } },",
          "\t-- Each floor's and paper's set: the part that carries its SurfaceAppearance.",
          "\tSwatches = {"]
    L += [f"\t\t{k} = \"{v}\"," for k, v in swatches.items()]
    L += ["\t} :: { [string]: string },"]
    return L


def b2r(v):
    """A Blender point in Roblox's frame."""
    return (-v[0], v[2], v[1])


def lua_vec(v, nd=3):
    return "{ " + ", ".join(f"{c:.{nd}f}" for c in v) + " }"


def write_luau(path, parts, switch, toggle, lamp, cards_of, panels, swatches):
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
        "export type Top = { At: Vec, Size: { number } }",
        "export type Glow = { Neon: { string }, Clear: { string }, Light: Vec, Range: number,",
        "\tBrightness: number, Colour: string }",
        "export type Swatch = { Id: string, Colour: string }",
        "export type Floor = { Id: string, Set: string, Colours: { Swatch } }",
        "export type Paper = { Id: string, Set: string }",
        "export type Panel = { Part: string, At: Vec, Turn: number }",
        "export type CardStyle = { Id: string, Sold: string, Parts: { string }, Face: Vec, FaceSize: Vec,",
        "\tFont: string, Weight: string, Ink: string, Paint: string?, Glow: string? }",
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
    L += ["\t-- The counter's furniture (D-323): each piece's flat tops, a find standing on one or you",
          "\t-- sitting on it: the top's middle in the piece's frame, and its size across and deep.",
          "\tTops = {"]
    for kind, tops in furniture_tops().items():
        L.append(f"\t\t{kind} = {{")
        for c, (w, d) in tops:
            L.append(f"\t\t\t{{ At = {lua_vec(b2r(c))}, Size = {{ {w:.3f}, {d:.3f} }} }},")
        L.append("\t\t},")
    L += ["\t} :: { [string]: { Top } },"]
    L += ["\t-- The pieces that light up (D-324): the parts the game makes Neon in Colour, the parts it",
          "\t-- makes clear glass, and the one real light each throws, near you only (D-271), its middle",
          "\t-- in the piece's frame.",
          "\tGlows = {"]
    for kind, (neon, clear, at, rng, bright, col) in glows().items():
        names = lambda ns: "{ " + ", ".join(f'"{n}"' for n in ns) + " }" if ns else "{}"
        L += [f"\t\t{kind} = {{ Neon = {names(neon)}, Clear = {names(clear)}, Light = {lua_vec(b2r(at))},",
              f"\t\t\tRange = {rng}, Brightness = {bright}, Colour = \"{col}\" }},"]
    L += ["\t} :: { [string]: Glow },"]
    L += luau_looks()
    L += luau_panels(panels, swatches)
    L += luau_cards(cards_of)
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
