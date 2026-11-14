"""Every number of the Packrat, in studs. Change them here only.

The second monster (GDD "The Packrat collects things, not people"): a tall, faceless bundle of
grey moving blankets bound with packing tape, and out of it two long bare arms. It carries the
floor's finds home one at a time, held to its chest, so the one thing its look must do is let a
player tell full arms from empty arms from the far end of a hall on a phone: pale arms hugged to
its chest round a find, or hanging long and wide off a dark grey bundle.

Rigid parts, as the Mannequin's (art/mannequin/spec.py): each is a Roblox R15 body part, so
Motor6Ds pose it with no skinning. Its frame in Blender: X across (its own left is +X), Y front to
back (it faces -Y), Z up, the origin on the floor between its feet; every part keeps that origin.
The FBX turns this into Roblox's frame (Roblox X = -x, Y = z, Z = y), and
src/shared/Packrat/Specs.luau, which the export stage writes, carries the joints, the capsules the
poses are checked against, the soles and the point a find is held at.

Built standing at rest: arms hanging just clear of the bundle, palms in, legs straight. A pose is
every joint's turn from there (src/shared/Packrat/Pose.luau).
"""

import os

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", ".."))

SET = "Packrat"     # its texture set, and its name in the game
TEX = 1024          # one atlas for all fifteen parts
DUST = 0.35         # it moves about, so less dust than the Mannequin's
HEIGHT = 7.3        # crown to floor at rest: a head and a half over a player (about 5.2); 8 clears a door

# What a part is made of: blanket (the bundle, legs, feet, head) or skin (the bare arms).
BLANKET, SKIN = "blanket", "skin"

# A part is lofted through stations from its top down: (z, half-width, half-depth, x, y, round),
# `round` the cross-section's superellipse power. Its ends are domes `caps` = (top, bottom) studs
# tall, each sitting inside the next part at rest. `folds` is how far the blanket's creases stand
# out (0 for skin). Built for its left side; the right is the mirror.
PARTS = {
    "Head": dict(stuff=BLANKET, segs=30, caps=(0.05, 0.03), folds=0.05, stations=[
        (7.22, 0.20, 0.25, 0.0, -0.17, 2.0),   # the blanket's gathered top, bowed forward
        (7.10, 0.33, 0.39, 0.0, -0.17, 2.2),
        (6.92, 0.41, 0.47, 0.0, -0.15, 2.3),   # a hood with nothing in its opening
        (6.70, 0.42, 0.46, 0.0, -0.11, 2.3),
        (6.50, 0.35, 0.37, 0.0, -0.07, 2.2),
        (6.36, 0.22, 0.23, 0.0, -0.03, 2.0),   # the neck, taped tight
        (6.16, 0.21, 0.22, 0.0, 0.00, 2.0),
    ]),
    "UpperTorso": dict(stuff=BLANKET, segs=40, caps=(0.05, 0.12), folds=0.085, stations=[
        (6.24, 0.26, 0.26, 0.0, 0.02, 2.0),
        (6.17, 0.46, 0.38, 0.0, 0.03, 2.2),
        (6.04, 0.66, 0.50, 0.0, 0.04, 2.4),    # the shoulders hunched up under the blanket
        (5.84, 0.76, 0.56, 0.0, 0.04, 2.5),
        (5.54, 0.75, 0.58, 0.0, 0.02, 2.5),    # the chest
        (5.14, 0.69, 0.56, 0.0, 0.00, 2.4),
        (4.74, 0.61, 0.52, 0.0, 0.00, 2.3),
        (4.42, 0.55, 0.47, 0.0, 0.00, 2.3),
        (4.25, 0.56, 0.48, 0.0, 0.00, 2.3),    # the waist
    ]),
    "LowerTorso": dict(stuff=BLANKET, segs=40, caps=(0.16, 0.08), folds=0.085, stations=[
        (4.25, 0.56, 0.48, 0.0, 0.00, 2.3),
        (4.05, 0.62, 0.50, 0.0, 0.01, 2.4),
        (3.75, 0.66, 0.53, 0.0, 0.02, 2.5),    # the hips
        (3.42, 0.66, 0.54, 0.0, 0.02, 2.5),
        (3.16, 0.70, 0.59, 0.0, 0.02, 2.6),
        (2.96, 0.73, 0.63, 0.0, 0.02, 2.7),    # the blanket's hem, hanging over its thighs
    ]),
    "UpperArm": dict(stuff=SKIN, segs=18, caps=(0.13, 0.08), folds=0.0, stations=[
        (5.96, 0.150, 0.150, 0.82, 0.00, 2.0),  # the shoulder's ball, inside the bundle
        (5.70, 0.128, 0.130, 0.85, 0.00, 2.0),
        (5.20, 0.108, 0.110, 0.88, 0.01, 2.0),
        (4.70, 0.094, 0.098, 0.90, 0.02, 2.0),
        (4.35, 0.084, 0.088, 0.92, 0.02, 2.0),  # the elbow
    ]),
    "LowerArm": dict(stuff=SKIN, segs=18, caps=(0.08, 0.04), folds=0.0, stations=[
        (4.35, 0.088, 0.092, 0.92, 0.02, 2.0),
        (4.16, 0.098, 0.090, 0.93, 0.02, 2.0),  # gaunt, but a forearm that could carry
        (3.70, 0.080, 0.078, 0.95, 0.01, 2.0),
        (3.20, 0.058, 0.064, 0.97, 0.00, 2.0),
        (2.87, 0.044, 0.060, 0.98, 0.00, 2.2),  # the wrist, flat, palm in
    ]),
    "Hand": dict(stuff=SKIN, segs=18, caps=(0.03, 0.04), folds=0.0, stations=[
        (2.86, 0.044, 0.060, 0.980, 0.000, 2.2),
        (2.76, 0.050, 0.100, 0.982, -0.010, 2.6),
        (2.62, 0.052, 0.116, 0.982, -0.010, 2.8),  # the palm
        (2.45, 0.046, 0.112, 0.978, -0.010, 2.8),  # the knuckles
        (2.25, 0.036, 0.096, 0.968, 0.000, 2.6),   # long fingers held together
        (2.07, 0.027, 0.072, 0.952, 0.012, 2.2),   # their tips hooked in
    ]),
    "UpperLeg": dict(stuff=BLANKET, segs=20, caps=(0.20, 0.12), folds=0.045, stations=[
        (3.62, 0.26, 0.27, 0.36, 0.00, 2.0),   # the hip's ball, inside the hem
        (3.30, 0.27, 0.28, 0.36, 0.00, 2.1),
        (2.80, 0.24, 0.26, 0.37, -0.01, 2.1),
        (2.30, 0.21, 0.23, 0.38, -0.01, 2.1),
        (1.95, 0.19, 0.21, 0.38, -0.02, 2.0),  # the knee
    ]),
    "LowerLeg": dict(stuff=BLANKET, segs=20, caps=(0.10, 0.08), folds=0.045, stations=[
        (1.95, 0.19, 0.21, 0.38, -0.02, 2.0),
        (1.62, 0.20, 0.23, 0.39, 0.02, 2.0),
        (1.10, 0.17, 0.19, 0.40, 0.02, 2.0),
        (0.66, 0.15, 0.16, 0.40, 0.03, 2.0),
        (0.40, 0.16, 0.17, 0.40, 0.05, 2.0),   # the ankle, inside the foot's bundle
    ]),
}

# The thumb, swept along the front of each hand (left side): its path and radius.
THUMB = ([(0.968, -0.098, 2.77), (0.958, -0.128, 2.62), (0.948, -0.132, 2.47)], 0.027)

# The foot: the blanket bundled round it like a sack, lofted heel to toe along -Y through
# (y, x, half-width, top) stations, flat beneath.
FOOT = dict(segs=18, caps=(0.06, 0.07), stations=[
    (0.30, 0.40, 0.12, 0.30),
    (0.20, 0.40, 0.16, 0.42),
    (0.05, 0.40, 0.18, 0.47),   # round the shin's dome
    (-0.15, 0.41, 0.19, 0.38),
    (-0.35, 0.42, 0.18, 0.28),
    (-0.52, 0.42, 0.15, 0.20),
    (-0.62, 0.42, 0.10, 0.14),
])

# The joints, R15's names, each at its pivot (left side; the right mirrors).
JOINTS = [
    ("Root", "HumanoidRootPart", "LowerTorso", (0.0, 0.0, 3.90)),
    ("Waist", "LowerTorso", "UpperTorso", (0.0, 0.0, 4.25)),
    ("Neck", "UpperTorso", "Head", (0.0, 0.0, 6.18)),
    ("LeftShoulder", "UpperTorso", "LeftUpperArm", (0.82, 0.0, 5.86)),
    ("LeftElbow", "LeftUpperArm", "LeftLowerArm", (0.92, 0.02, 4.35)),
    ("LeftWrist", "LeftLowerArm", "LeftHand", (0.98, 0.0, 2.86)),
    ("LeftHip", "LowerTorso", "LeftUpperLeg", (0.36, 0.0, 3.55)),
    ("LeftKnee", "LeftUpperLeg", "LeftLowerLeg", (0.38, -0.02, 1.95)),
    ("LeftAnkle", "LeftLowerLeg", "LeftFoot", (0.40, 0.05, 0.40)),
]

# HumanoidRootPart, R15's invisible root: its centre and size (x, y, z Blender).
ROOT_PART = ((0.0, 0.0, 3.90), (2.0, 1.0, 2.0))

# Where a carried find's middle sits, on the UpperTorso at rest: between its chest and its hugging
# forearms (S2-06b welds the find here; the sheets stand one there).
CARRY = (0.0, -1.22, 4.95)

# The shapes the poses are checked against (tests/packrat.spec.luau): capsules a little inside
# each part's skin, (a, b, radius), left side.
CAPSULES = {
    "Head": [((0.0, -0.13, 6.62), (0.0, -0.15, 6.98), 0.32)],
    "UpperTorso": [((-0.32, 0.0, 5.55), (0.32, 0.0, 5.55), 0.42), ((0.0, 0.0, 4.5), (0.0, 0.0, 5.1), 0.42)],
    "LowerTorso": [((-0.22, 0.02, 3.75), (0.22, 0.02, 3.75), 0.42)],
    "UpperArm": [((0.85, 0.0, 5.7), (0.92, 0.02, 4.42), 0.08)],
    "LowerArm": [((0.92, 0.02, 4.28), (0.98, 0.0, 2.95), 0.05)],
    "Hand": [((0.98, 0.0, 2.8), (0.96, 0.0, 2.15), 0.03)],
    "UpperLeg": [((0.36, 0.0, 3.4), (0.38, -0.02, 2.05), 0.18)],
    "LowerLeg": [((0.38, -0.02, 1.85), (0.40, 0.05, 0.5), 0.13)],
    "Foot": [((0.40, 0.18, 0.15), (0.42, -0.5, 0.11), 0.09)],
}
# Points on each sole (left), for setting a pose's lowest foot on the floor.
SOLE = [(0.40, 0.32, 0.0), (0.42, -0.66, 0.0), (0.26, -0.30, 0.0), (0.56, -0.30, 0.0)]

# Packing tape wound round it, in the figure's frame at rest: each band is (height, slope across,
# slope front to back, width). A band is a plane's worth of tape: wherever the blanket crosses it,
# it's pulled in a little and painted tan. Tilted, as a hand winds it.
TAPE = [
    (7.00, 0.08, -0.12, 0.16),   # round the hood
    (6.30, 0.00, 0.10, 0.14),    # the neck
    (5.55, 0.42, -0.05, 0.19),   # across the chest one way,
    (5.22, -0.40, 0.05, 0.17),   # and the other: an X binding the bundle shut
    (4.40, 0.05, 0.00, 0.17),    # the waist
    (2.66, 0.10, 0.08, 0.15),    # the thighs, under the hem
    (1.95, -0.06, 0.00, 0.14),   # the knees
    (0.55, 0.00, 0.06, 0.13),    # the ankles
]
PINCH = 0.06   # how much a band pulls the blanket in, as a share of its radius

# The quilting stitched through each blanket: diamonds this far apart (studs, 4 inches is 0.36).
QUILT = 0.42
# Where one blanket's edge crosses another, its binding a darker strip: (a point on the edge,
# the edge plane's normal), left side or middle.
EDGES = [((0.0, -0.30, 5.10), (0.55, 0.15, 0.82)),
         ((0.0, 0.40, 4.70), (-0.45, 0.10, 0.89)),
         ((0.0, -0.20, 6.75), (0.20, -0.45, 0.87)),
         ((0.30, 0.0, 2.45), (0.25, 0.35, 0.90))]
# Each blanket's grey, by part (it's three or four blankets, not one).
GREYS = {"Head": "#4F5255", "UpperTorso": "#5E6164", "LowerTorso": "#585B5D",
         "UpperLeg": "#605F59", "LowerLeg": "#5A5954", "Foot": "#4C4B48"}
# The hood's opening, where a face would be: nothing in it but dark (centre, how far round, depth).
HOLLOW = ((0.0, -0.44, 6.80), 0.24, 0.13)

SEED = 37.0

SIDES = ("Left", "Right")
LIMBS = ("UpperArm", "LowerArm", "Hand", "UpperLeg", "LowerLeg", "Foot")
ORDER = (["Head", "UpperTorso", "LowerTorso"]
         + [f"{s}{p}" for s in SIDES for p in LIMBS])


def mirror(p):
    return (-p[0], p[1], p[2])


def side_of(name):
    """+1 for the left parts (built as specified), -1 for the right (mirrored), 0 for the middle."""
    return 1 if name.startswith("Left") else -1 if name.startswith("Right") else 0


def base(name):
    for s in SIDES:
        if name.startswith(s):
            return name[len(s):]
    return name


def stuff(name):
    b = base(name)
    return BLANKET if b == "Foot" else PARTS[b]["stuff"]


def joints():
    """Every joint, both sides: (name, part0, part1, pivot) in Blender's frame."""
    out = []
    for name, p0, p1, at in JOINTS:
        out.append((name, p0, p1, at))
        if name.startswith("Left"):
            r = lambda s: s.replace("Left", "Right")  # noqa: E731
            out.append((r(name), r(p0), r(p1), mirror(at)))
    order = ["Root", "Waist", "Neck"] + [f"{s}{j}" for s in SIDES
                                        for j in ("Shoulder", "Elbow", "Wrist", "Hip", "Knee", "Ankle")]
    return sorted(out, key=lambda j: order.index(j[0]))


def roblox(p):
    """Blender's frame to Roblox's: X = -x, Y = z, Z = y."""
    return (-p[0], p[2], p[1])


def lua_vec(p):
    x, y, z = roblox(p)
    return f"{{ {x + 0.0:.4f}, {y + 0.0:.4f}, {z + 0.0:.4f} }}".replace("-0.0000", "0.0000")


def write_luau(path, parts):
    """parts: {name: dict(size=(x, y, z) Roblox, centre=(x, y, z) Blender, tris=n)}."""
    L = [
        "--!strict",
        "-- Generated by art/packrat/build.py --stage export from art/packrat/spec.py. Don't edit:",
        "-- change the spec and rebuild (scripts/art.sh packrat).",
        "-- Studs, in the figure's own frame at rest: Roblox's axes (X its right, Y up, Z behind it),",
        "-- the origin on the floor between its feet. Plain number lists, so Lune can check poses.",
        "",
        'local Rig = require("../Rig")',
        "",
        f"local Height = {HEIGHT}",
        "",
        "-- R15's joints from the root out: a Motor6D `Name` turns `Part1` about `At` on `Part0`.",
        "local Joints: { Rig.Joint } = {",
    ]
    for name, p0, p1, at in joints():
        L.append(f'\t{{ Name = "{name}", Part0 = "{p0}", Part1 = "{p1}", At = {lua_vec(at)} }},')
    L += ["}", "", "-- Each MeshPart's box at rest, as imported (its centre is its CFrame), and what it's",
          "-- made of (its colour if the maps fail to load).",
          "local Parts: { [string]: Rig.Part } = {"]
    for name in ORDER:
        r = parts[name]
        sx, sy, sz = r["size"]
        L.append(f"\t{name} = {{ Size = {{ {sx:.3f}, {sy:.3f}, {sz:.3f} }}, "
                 f"Centre = {lua_vec(r['centre'])}, Triangles = {r['tris']}, "
                 f'Stuff = "{stuff(name)}" }},')
    L += ["}", "", "-- Capsules a little inside each part's skin, for checking a pose never puts one",
          "-- part through another.", "local Capsules: { [string]: { Rig.Capsule } } = {"]
    for name in ORDER:
        s = side_of(name)
        rows = []
        for a, b, r in CAPSULES[base(name)]:
            if s < 0:
                a, b = mirror(a), mirror(b)
            rows.append(f"{{ A = {lua_vec(a)}, B = {lua_vec(b)}, Radius = {r} }}")
        L.append(f"\t{name} = {{ " + ", ".join(rows) + " },")
    L += ["}", "", "-- Points on each sole, to stand a pose's lowest foot on the floor.",
          "local Soles: { [string]: { Rig.Vec } } = {"]
    for s in SIDES:
        pts = SOLE if s == "Left" else [mirror(p) for p in SOLE]
        L.append(f"\t{s}Foot = {{ " + ", ".join(lua_vec(p) for p in pts) + " },")
    (c, size) = ROOT_PART
    L += ["}", "", "-- HumanoidRootPart: R15's invisible root, the part a mover drives.",
          f"local RootPart = {{ Centre = {lua_vec(c)}, Size = {{ {size[0]}, {size[2]}, {size[1]} }} }}",
          "", "-- Where a carried find's middle sits, in the figure's frame at rest (it rides the",
          "-- UpperTorso).", f"local Carry = {lua_vec(CARRY)}",
          "", "return {", "\tHeight = Height,", "\tJoints = Joints,", "\tParts = Parts,",
          "\tCapsules = Capsules,", "\tSoles = Soles,", "\tRootPart = RootPart,", "\tCarry = Carry,",
          "}", ""]
    with open(path, "w") as f:
        f.write("\n".join(L))
    print("SPEC", path)
