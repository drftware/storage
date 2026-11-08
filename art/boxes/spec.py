"""Every number of the moving boxes, in studs. Change them here only.

A box's frame in Blender: its long side runs along X, across it is Y, up is Z, and its origin is
the middle of its bottom, on the floor. The top flaps meet along X, so the packing tape runs along
X and laps down the two ends (the faces across X); the labelled long sides face -Y and +Y. The FBX
turns this into Roblox's frame (Y up, the -Y side the part's front), and the game reads these
numbers from src/shared/Boxes/Specs.luau, which the export stage writes.

Sizes are real moving boxes (U-Haul's), at 10 inches a stud: the unit's 10-foot width is 12 studs.
"""

import os

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", ".."))
IN = 0.1  # studs per inch

FONTS = "/Applications/RobloxStudio.app/Contents/Resources/content/fonts"
MARKER = os.path.join(FONTS, "PermanentMarker-Regular.ttf")  # what people write on boxes
PRINT = os.path.join(FONTS, "Oswald-Bold.ttf")               # what the box maker printed

BOARD = 0.03        # the board's thickness: the open box's walls and flaps
TAPE = 2 * IN       # packing tape's width
LAP = 0.3           # how far the tape laps down an end, past the top's edge
GRID = 0.4          # the longest edge of a face's quads: enough for a bulge and a crushed corner
TEX = 1024          # the Cardboard texture set, one atlas for every box
PAD = 10            # texels between two faces' islands in the atlas

# The label sheet: 4 x 8 cells of 256 x 128 texels, each one word in marker or one printed mark.
# A box's labels and prints name a cell; the bake maps it onto the face.
SHEET = (4, 8)
CELLS = [  # key, text, font
    ("KITCHEN", "KITCHEN", "marker"),
    ("BOOKS", "BOOKS", "marker"),
    ("XMAS", "XMAS", "marker"),
    ("GARAGE", "GARAGE", "marker"),
    ("PHOTOS", "PHOTOS", "marker"),
    ("TAPES", "TAPES", "marker"),
    ("KEEP", "KEEP", "marker"),
    ("MISC", "MISC.", "marker"),
    ("UP", "THIS SIDE UP", "up"),       # with two arrows over the words
    ("FRAGILE", "FRAGILE", "print"),
    ("WARDROBE", "WARDROBE", "print"),
    ("CERT", "BOX MAKER'S\nCERTIFICATE\n32 ECT", "cert"),  # the ring stamp on every box's base
]
CELL = {key: i for i, (key, _, _) in enumerate(CELLS)}

INK = "#2A211A"      # the maker's print: dark brown on kraft
RED = "#9A2B22"      # the FRAGILE stamp
MARKER_INK = "#141312"

# What's on a face: (cell, face, centre across, centre up, width, height, turn in degrees, colour).
# "front" is the long side facing -Y (the +Y side shows the same); "end" is the -X end (and +X).
# Across and up are studs from the face's bottom-left corner, seen from outside.


def mark(cell, face, cu, cv, w, h, turn=0.0, ink=INK):
    return dict(cell=cell, face=face, cu=cu, cv=cv, w=w, h=h, turn=turn, ink=ink)


# name: size; how it was taped and treated; what's printed and written on it.
#   tape   "brown" or "clear" packing tape
#   hole   the ends' hand holes: 0 none, 1 cut but never pushed in, 2 pushed in
#   bulge  how far the sides bow out in the middle (full of something), sag the top's dip
#   dent   a crushed top corner: (side x, side y, reach, depth), or None
#   stain  a water mark's tide line, studs up the sides (it stood in a puddle), or 0
#   dust   0..1 on the top
#   open   the flaps' angles from shut (front, back, -X end, +X end), for the opened box
BOXES = {
    "Small": dict(
        w=16 * IN, d=12 * IN, h=12 * IN, tape="brown", hole=0, bulge=0.012, sag=0.01,
        dent=None, stain=0.0, dust=0.8, seed=1.0,
        marks=[mark("BOOKS", "front", 0.8, 0.62, 0.95, 0.36, -4, MARKER_INK),
               mark("CERT", "front", 1.33, 0.2, 0.44, 0.22),
               mark("BOOKS", "end", 0.6, 0.55, 0.8, 0.3, 3, MARKER_INK)]),
    "Medium": dict(
        w=18 * IN, d=18 * IN, h=16 * IN, tape="brown", hole=1, bulge=0.02, sag=0.025,
        dent=(1, -1, 0.8, 0.09), stain=0.0, dust=0.7, seed=2.0,
        marks=[mark("UP", "front", 0.42, 1.26, 0.62, 0.31),
               mark("KITCHEN", "front", 0.95, 0.72, 1.3, 0.44, 3, MARKER_INK),
               mark("CERT", "front", 1.5, 0.2, 0.46, 0.23),
               mark("FRAGILE", "end", 0.9, 0.62, 1.0, 0.3, -2, RED)]),
    "Large": dict(
        w=18 * IN, d=18 * IN, h=24 * IN, tape="clear", hole=2, bulge=0.03, sag=0.035,
        dent=None, stain=0.32, dust=0.65, seed=3.0,
        marks=[mark("UP", "front", 0.42, 2.06, 0.62, 0.31),
               mark("XMAS", "front", 0.9, 1.2, 1.15, 0.46, -6, MARKER_INK),
               mark("CERT", "front", 1.5, 0.2, 0.46, 0.23),
               mark("XMAS", "end", 0.9, 1.25, 0.95, 0.38, 4, MARKER_INK)]),
    "Wardrobe": dict(
        w=24 * IN, d=24 * IN, h=40 * IN, tape="brown", hole=2, bulge=0.025, sag=0.02,
        dent=(-1, 1, 0.9, 0.12), stain=0.0, dust=0.75, seed=4.0,
        marks=[mark("WARDROBE", "front", 1.2, 2.6, 1.8, 0.62),
               mark("UP", "front", 1.2, 3.45, 0.8, 0.4),
               mark("KEEP", "front", 1.2, 1.55, 1.25, 0.5, -3, MARKER_INK),
               mark("CERT", "front", 2.08, 0.22, 0.52, 0.26),
               mark("WARDROBE", "end", 1.2, 2.6, 1.8, 0.62)]),
    # A medium box someone already went through: tape slit, flaps up.
    "Open": dict(
        w=18 * IN, d=18 * IN, h=16 * IN, tape="brown", hole=1, bulge=0.012, sag=0.0,
        dent=None, stain=0.0, dust=0.45, seed=5.0, open=(118.0, 104.0, 97.0, 128.0),
        marks=[mark("PHOTOS", "front", 0.9, 0.78, 1.25, 0.44, -3, MARKER_INK),
               mark("CERT", "front", 1.5, 0.2, 0.46, 0.23),
               mark("UP", "end", 0.9, 0.72, 0.62, 0.31)]),
}
ORDER = ["Small", "Medium", "Large", "Wardrobe", "Open"]


def write_luau(path, rows):
    """rows: {name: dict(size=(x, y, z) in Roblox axes, tris=n)}."""
    lines = [
        "--!strict",
        "-- Generated by art/boxes/build.py --stage export from art/boxes/spec.py. Don't edit:",
        "-- change the spec and rebuild (scripts/art.sh boxes).",
        "-- Studs, real moving-box sizes at 10 inches a stud. A box's pivot is the middle of its",
        "-- bottom, on the floor; its labelled long side faces the part's front (LookVector), the",
        "-- tape runs front to back over the top and laps down the two ends (the part's X sides).",
        "",
        "export type Box = {",
        "\tSize: Vector3, -- X the long side, Y up, Z across",
        "\tTriangles: number,",
        "\tOpen: boolean, -- the flaps stand up past its top, so nothing stacks on it",
        "}",
        "",
        "local Boxes: { [string]: Box } = {",
    ]
    for name in ORDER:
        r = rows[name]
        x, y, z = r["size"]
        lines.append(f"\t{name} = {{ Size = Vector3.new({x:g}, {y:g}, {z:g}), "
                     f"Triangles = {r['tris']}, Open = {'true' if r['open'] else 'false'} }},")
    lines += ["}", "", "return {", f"\tBoard = {BOARD:g}, -- the board's thickness",
              "\tBoxes = Boxes,", "}", ""]
    with open(path, "w") as f:
        f.write("\n".join(lines))
    print("SPEC", path)
