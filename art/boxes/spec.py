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

# The marked box (B-01, D-205): the one box in a unit that holds something (a find, a tool, coins
# or one of the code's notes). A Medium box anybody could have packed: the maker's print only, no
# marker word, fresh brown tape whole along the seam, nothing that tells what's in it. Unlike the
# scenery boxes it is a Model of parts that move (art/boxes/README.md "The marked box"); it shares
# the Cardboard atlas, and its inside, flap insides and cut edges wear the Open box's texels.
MARKED = dict(
    w=18 * IN, d=18 * IN, h=16 * IN, tape="brown", hole=1, bulge=0.016, sag=0.0,
    dent=None, stain=0.0, dust=0.4, seed=6.0, marked=True,
    marks=[mark("UP", "front", 0.42, 1.26, 0.62, 0.31),
           mark("CERT", "front", 1.5, 0.2, 0.46, 0.23),
           mark("UP", "end", 0.9, 1.22, 0.62, 0.31)])
TAPE_UP = 0.004      # the tape's top above the flaps it holds down
TAPE_THICK = 0.0025  # between its top and its sticky underside
UNDER = 0.004        # the end flaps fold under the long ones: their hinge this far below the board

# The cue (D-205's default, as Fortnite's chests glow): a faint warm line of light leaking out
# along both edges of the tape, as if something inside were lit. Off in the template; the game
# turns it on for a box with something in it. Neon at mid warmth: small bright Neon smears into
# blobs at low graphics (docs/STUDIO.md), so it stays well under white.
SEAM_W = 0.035       # each line's width: about a pixel and a half from a unit's doorway on a phone
SEAM_GAP = 0.002     # between the tape's edge and its line
SEAM_INSET = 0.07    # how far short of the box's ends the lines stop
CUE = dict(rgb=(196, 122, 58), transparency=0.3,
           # an optional warm point light inside the top, for a player up close (each one counts
           # toward the floor's light cap: the game decides when to spend it)
           light_kelvin=2200, light_brightness=0.6, light_range=3.0)

# Its parts, the body first. Pivots are hinges in the box's Blender frame (origin the middle of the
# bottom); a part turns about its axis by the right-hand rule, so a positive turn opens it.
# (name, hinge, axis): the hinges' heights are filled in from the box's size below.
H, HALF = MARKED["h"], MARKED["w"] / 2
MARKED_PARTS = [
    ("Body", (0.0, 0.0, 0.0), None),
    ("FlapFront", (0.0, -MARKED["d"] / 2, H), (1.0, 0.0, 0.0)),   # the long flaps, on top
    ("FlapBack", (0.0, MARKED["d"] / 2, H), (-1.0, 0.0, 0.0)),
    ("FlapLeft", (-HALF, 0.0, H - BOARD - UNDER), (0.0, -1.0, 0.0)),  # the end flaps, under them
    ("FlapRight", (HALF, 0.0, H - BOARD - UNDER), (0.0, 1.0, 0.0)),
    ("TapeLeft", (-HALF, 0.0, H + TAPE_UP), (0.0, -1.0, 0.0)),   # each half hinged where it laps
    ("TapeRight", (HALF, 0.0, H + TAPE_UP), (0.0, 1.0, 0.0)),    # down an end
    ("Seam", (0.0, 0.0, H), None),
]

# Opening it, as the finds kit writes motion (art/finds/kit/ease.py; Finds/Art.luau plays it):
# keys (seconds, degrees about the part's axis or times its size, easing style, direction).
# The moment: the box takes a breath (the tape strains at the middle, the flaps nudge up), the
# tape snaps in the middle and its halves whip back to the ends, then the long flaps burst up and
# past upright, the end flaps a beat behind, everything overshooting and settling like light board.
# The settled angles are the Open box's, which were judged already. B-02 times its reveal round it.
OPEN = dict(duration=0.95, tracks=[
    ("TapeLeft", "turn", [(0, 0), (0.1, 7, "Quad", "Out"), (0.3, 152, "Quad", "Out"),
                          (0.46, 128), (0.62, 140), (0.76, 136)]),
    ("TapeRight", "turn", [(0, 0), (0.11, 6, "Quad", "Out"), (0.32, 158, "Quad", "Out"),
                           (0.48, 132), (0.64, 143), (0.78, 139)]),
    ("Seam", "scale", [(0, 1), (0.1, 1), (0.14, 0.01, "Quad", "In")]),
    ("FlapFront", "turn", [(0, 0), (0.1, 3, "Quad", "Out"), (0.16, 1, "Quad", "In"),
                           (0.4, 130, "Quad", "Out"), (0.54, 111), (0.68, 121), (0.8, 118)]),
    ("FlapBack", "turn", [(0, 0), (0.1, 3, "Quad", "Out"), (0.17, 1, "Quad", "In"),
                          (0.42, 116, "Quad", "Out"), (0.56, 98), (0.7, 107), (0.82, 104)]),
    ("FlapLeft", "turn", [(0, 0), (0.22, 0), (0.46, 108, "Quad", "Out"), (0.6, 91), (0.74, 99),
                          (0.86, 97)]),
    ("FlapRight", "turn", [(0, 0), (0.23, 0), (0.48, 140, "Quad", "Out"), (0.62, 122),
                           (0.76, 130), (0.9, 128)]),
])


def _v3(v):
    return f"Vector3.new({v[0] + 0.0:.4g}, {v[1] + 0.0:.4g}, {v[2] + 0.0:.4g})"


def _marked_luau(m):
    """The marked box's rows: m = dict(size, tris, parts=[dict(name, pivot, axis, size, tris)],
    tracks=[(part, channel, keys)], cue_rgb, light_rgb), all already in Roblox axes."""
    c, lc = m["cue_rgb"], m["light_rgb"]
    L = ["", "-- The marked box (B-01): a Model of these parts, the body first. Parts ride on the body;",
         "-- each flap and tape half turns about its Axis through its Pivot (both from the box's pivot,",
         "-- the middle of its bottom). Motions play with Finds/Art.luau's sums (Art.sample).",
         "local Marked: Marked = {",
         f"\tSize = {_v3(m['size'])},", f"\tTriangles = {m['tris']},", "\tParts = {"]
    for p in m["parts"]:
        par = "" if p["name"] == "Marked_Body" else 'Parent = "Marked_Body", '
        ax = f"Axis = {_v3(p['axis'])}, " if p["axis"] else ""
        L.append(f"\t\t{{ Name = \"{p['name']}\", {par}Pivot = {_v3(p['pivot'])}, {ax}"
                 f"Size = {_v3(p['size'])}, Triangles = {p['tris']} }},")
    L += ["\t},", "\tMotions = {", f"\t\tOpen = {{ Duration = {OPEN['duration']:g}, Tracks = {{"]
    for part, ch, ks in m["tracks"]:
        keys = ", ".join(f"{{ {t:g}, {v:g}, \"{st}\", \"{d}\" }}" for t, v, st, d in ks)
        L.append(f"\t\t\t{{ Part = \"Marked_{part}\", Channel = \"{ch}\", Keys = {{ {keys} }} }},")
    L += ["\t\t} },", "\t},",
          f"\tCue = {{ Part = \"Marked_Seam\", Color = Color3.fromRGB({c[0]}, {c[1]}, {c[2]}), "
          f"Transparency = {CUE['transparency']:g}, Light = {{ Color = Color3.fromRGB({lc[0]}, "
          f"{lc[1]}, {lc[2]}), Brightness = {CUE['light_brightness']:g}, "
          f"Range = {CUE['light_range']:g} }} }},",
          "}"]
    return L


def write_luau(path, rows, marked):
    """rows: {name: dict(size=(x, y, z) in Roblox axes, tris=n)}; marked: _marked_luau's."""
    lines = [
        "--!strict",
        "-- Generated by art/boxes/build.py --stage export from art/boxes/spec.py. Don't edit:",
        "-- change the spec and rebuild (scripts/art.sh boxes).",
        "-- Studs, real moving-box sizes at 10 inches a stud. A box's pivot is the middle of its",
        "-- bottom, on the floor; its labelled long side faces the part's front (LookVector), the",
        "-- tape runs front to back over the top and laps down the two ends (the part's X sides).",
        "",
        "-- The marked box's parts and motion, shaped as Finds/Art.luau's Part and Track (no require:",
        "-- the tests load this file bare), so Art.sample plays its keys.",
        "export type Part = {",
        "\tName: string,",
        "\tParent: string?,",
        "\tPivot: Vector3,",
        "\tAxis: Vector3?,",
        "\tSize: Vector3,",
        "\tTriangles: number,",
        "}",
        "export type Track = { Part: string, Channel: \"turn\" | \"scale\", Keys: { { any } } }",
        "",
        "export type Box = {",
        "\tSize: Vector3, -- X the long side, Y up, Z across",
        "\tTriangles: number,",
        "\tOpen: boolean, -- the flaps stand up past its top, so nothing stacks on it",
        "}",
        "",
        "export type Marked = {",
        "\tSize: Vector3, -- shut",
        "\tTriangles: number,",
        "\tParts: { Part },",
        "\tMotions: { [string]: { Duration: number, Tracks: { Track } } }, -- Open: tape tears, flaps spring",
        "\t-- Something's inside: the seam's Neon lines (Transparency 1 in the template) and an",
        "\t-- optional warm light for a player up close, which counts toward the light cap",
        "\tCue: { Part: string, Color: Color3, Transparency: number, Light: { Color: Color3, "
        "Brightness: number, Range: number } },",
        "}",
        "",
        "local Boxes: { [string]: Box } = {",
    ]
    for name in ORDER:
        r = rows[name]
        x, y, z = r["size"]
        lines.append(f"\t{name} = {{ Size = Vector3.new({x:g}, {y:g}, {z:g}), "
                     f"Triangles = {r['tris']}, Open = {'true' if r['open'] else 'false'} }},")
    lines += ["}"] + _marked_luau(marked)
    lines += ["", "return {", f"\tBoard = {BOARD:g}, -- the board's thickness",
              "\tBoxes = Boxes,", "\tMarked = Marked,", "}", ""]
    with open(path, "w") as f:
        f.write("\n".join(lines))
    print("SPEC", path)
