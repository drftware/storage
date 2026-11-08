"""Every number of the Mannequin, in studs. Change them here only.

A shop mannequin left too long in storage (GDD Keepers: the Mannequin, a Kept Thing): faceless
fibreglass, ivory paint gone yellow and chipped, cut at every joint. Rigid parts, so each one is a
Roblox R15 body part and Motor6Ds move it with no skinning (art/mannequin/README.md).

Its frame in Blender: X across (its own left is +X), Y front to back (it faces -Y), Z up, the
origin on the floor between its feet. Every part keeps that origin, so each part's object space is
the whole figure's and the recipes paint in one frame. The FBX turns this into Roblox's frame
(Roblox X = -x, Y = z, Z = y: it faces its LookVector), and src/shared/Mannequin/Specs.luau, which
the export stage writes, carries the joints and the shapes the poses are checked against.

It is built standing in its rest pose: arms hanging just clear of its sides, palms in, legs
straight, feet a little apart and pointing ahead (Roblox's I-pose). A pose is every joint's turn
from there (src/shared/Mannequin/Pose.luau).
"""

import os

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", ".."))

SET = "Mannequin"   # its texture set, and its name in the game
TEX = 1024          # one atlas for all fifteen parts
DUST = 0.6          # dust on whatever faces up: it has stood in a unit a long time
HEIGHT = 6.3        # crown to floor: a head taller than a player (about 5.2), so it looms in a doorway

# A part is lofted through stations from its top down: (z, half-width, half-depth, x, y, round),
# `round` the cross-section's superellipse power (2 a plain ellipse, more is boxier). Its ends are
# domes `caps` = (top, bottom) studs tall, so where two parts meet each one's dome sits inside the
# other at rest and shows as a ball when the joint bends, like a jointed shop or artist's
# mannequin. Built for its left side; the right is the mirror (x negated).
PARTS = {
    "UpperTorso": dict(segs=30, caps=(0.03, 0.10), stations=[
        (5.35, 0.190, 0.165, 0.0, 0.020, 2.0),   # the neck's socket
        (5.31, 0.360, 0.195, 0.0, 0.020, 2.4),
        (5.22, 0.560, 0.240, 0.0, 0.010, 2.5),   # the shoulders' slope
        (5.10, 0.630, 0.285, 0.0, -0.010, 2.6),
        (4.92, 0.620, 0.320, 0.0, -0.030, 2.5),  # under the arms
        (4.70, 0.585, 0.335, 0.0, -0.040, 2.6),  # the chest
        (4.45, 0.530, 0.315, 0.0, -0.030, 2.5),
        (4.20, 0.450, 0.285, 0.0, -0.010, 2.4),
        (3.98, 0.400, 0.265, 0.0, 0.000, 2.4),   # the waist's seam
    ]),
    "LowerTorso": dict(segs=30, caps=(0.12, 0.08), stations=[
        (3.98, 0.400, 0.265, 0.0, 0.000, 2.4),
        (3.78, 0.455, 0.285, 0.0, 0.010, 2.4),
        (3.55, 0.515, 0.305, 0.0, 0.020, 2.5),   # the hips
        (3.35, 0.530, 0.305, 0.0, 0.030, 2.6),
        (3.18, 0.470, 0.280, 0.0, 0.030, 2.4),
        (3.05, 0.330, 0.220, 0.0, 0.020, 2.2),
    ]),
    "UpperArm": dict(segs=20, caps=(0.17, 0.10), stations=[
        (5.12, 0.165, 0.170, 0.780, 0.020, 2.0),  # the shoulder's ball above
        (4.90, 0.155, 0.160, 0.785, 0.020, 2.0),
        (4.60, 0.135, 0.140, 0.790, 0.020, 2.0),
        (4.30, 0.115, 0.120, 0.795, 0.020, 2.0),
        (3.98, 0.100, 0.105, 0.800, 0.030, 2.0),  # the elbow's seam
    ]),
    "LowerArm": dict(segs=20, caps=(0.10, 0.05), stations=[
        (3.98, 0.100, 0.105, 0.800, 0.030, 2.0),
        (3.80, 0.108, 0.100, 0.810, 0.020, 2.0),
        (3.55, 0.092, 0.090, 0.820, 0.010, 2.0),
        (3.30, 0.068, 0.078, 0.830, 0.005, 2.0),
        (3.08, 0.045, 0.062, 0.840, 0.000, 2.2),  # the wrist: flat, palm in
    ]),
    "Hand": dict(segs=20, caps=(0.04, 0.04), stations=[
        (3.06, 0.045, 0.062, 0.840, 0.000, 2.2),
        (2.98, 0.052, 0.100, 0.842, -0.005, 2.6),
        (2.88, 0.055, 0.112, 0.843, -0.005, 2.8),
        (2.78, 0.050, 0.110, 0.840, -0.005, 2.8),  # the knuckles
        (2.66, 0.042, 0.100, 0.830, -0.004, 2.6),
        (2.54, 0.036, 0.088, 0.818, -0.002, 2.4),
        (2.44, 0.030, 0.070, 0.806, 0.000, 2.2),   # the fingers curl in towards the thigh
    ]),
    "UpperLeg": dict(segs=20, caps=(0.22, 0.13), stations=[
        (3.22, 0.245, 0.255, 0.300, 0.020, 2.0),  # the hip's ball above, inside the pelvis
        (3.00, 0.240, 0.250, 0.300, 0.010, 2.0),
        (2.70, 0.215, 0.225, 0.300, 0.000, 2.0),
        (2.35, 0.180, 0.190, 0.300, -0.010, 2.0),
        (2.00, 0.150, 0.160, 0.300, -0.010, 2.0),
        (1.76, 0.140, 0.150, 0.300, -0.010, 2.0),  # the knee's seam
    ]),
    "LowerLeg": dict(segs=20, caps=(0.12, 0.07), stations=[
        (1.76, 0.140, 0.150, 0.300, -0.010, 2.0),
        (1.55, 0.140, 0.165, 0.300, 0.020, 2.0),   # the calf
        (1.30, 0.130, 0.160, 0.305, 0.030, 2.0),
        (1.00, 0.105, 0.120, 0.310, 0.020, 2.0),
        (0.70, 0.082, 0.090, 0.315, 0.030, 2.0),
        (0.42, 0.075, 0.082, 0.320, 0.050, 2.0),
        (0.30, 0.078, 0.085, 0.320, 0.060, 2.0),   # the ankle, inside the foot
    ]),
}

# The thumb, swept along the front of each hand (left side): its path and radius.
THUMB = ([(0.828, -0.082, 2.99), (0.818, -0.112, 2.88), (0.806, -0.124, 2.79)], 0.030)

# The foot is lofted heel to toe along -Y through (y, x, half-width, top) stations, flat beneath.
FOOT = dict(segs=18, caps=(0.04, 0.05), stations=[
    (0.26, 0.320, 0.065, 0.16),
    (0.20, 0.320, 0.085, 0.26),
    (0.10, 0.320, 0.095, 0.36),   # the ankle, round the shin's dome
    (0.00, 0.322, 0.100, 0.34),
    (-0.12, 0.325, 0.108, 0.27),  # the instep
    (-0.28, 0.330, 0.118, 0.19),
    (-0.42, 0.335, 0.122, 0.13),  # the ball of the foot
    (-0.54, 0.335, 0.110, 0.10),  # the toes, one block with grooves
    (-0.62, 0.335, 0.075, 0.075),
])

# The head: a faceless egg on a neck, with only a brow and a nose (a face you can't read).
HEAD = dict(
    centre=(0.0, 0.0, 5.93), radii=(0.265, 0.32, 0.375),
    us=36, vs=22,                 # points round and up; twice as many round the face
    back=1.06, front=0.94,        # the skull deeper behind, the face flatter
    jaw=(5.88, 5.56, 0.70),       # the jaw narrows from this height down to this one, to this much
    nose=(5.89, 0.05, 0.11, 0.036),     # height, its width and length (spreads), how far it stands
    brow=(6.00, 0.16, 0.04, 0.024),     # height, half its width, its spread, how far
    sockets=(5.955, 0.1, 0.056, 0.032),  # height, either side, spread, how deep
    chin=(5.63, 0.06, 0.05, 0.022),     # height, its width and height (spreads), how far
    neck=dict(segs=16, caps=(0.05, 0.03), stations=[
        (5.70, 0.135, 0.145, 0.0, 0.050, 2.0),
        (5.58, 0.138, 0.150, 0.0, 0.040, 2.0),
        (5.40, 0.142, 0.150, 0.0, 0.030, 2.0),
        (5.26, 0.150, 0.155, 0.0, 0.020, 2.0),
    ]),
)

# The joints, R15's names (Motor6D `Name` between `Part0` and `Part1`), each at its pivot (left
# side; the right mirrors). `seam` is where the two parts' paint meets: a plane through the pivot,
# its normal pointing into Part1, and how far round the pivot it runs.
JOINTS = [
    ("Root", "HumanoidRootPart", "LowerTorso", (0.0, 0.0, 3.60), None),
    ("Waist", "LowerTorso", "UpperTorso", (0.0, 0.0, 3.98), ((0.0, 0.0, 1.0), 0.7)),
    ("Neck", "UpperTorso", "Head", (0.0, 0.02, 5.33), ((0.0, 0.0, 1.0), 0.3)),
    ("LeftShoulder", "UpperTorso", "LeftUpperArm", (0.78, 0.02, 5.12), ((0.62, 0.0, -0.78), 0.3)),
    ("LeftElbow", "LeftUpperArm", "LeftLowerArm", (0.80, 0.03, 3.98), ((0.0, 0.0, -1.0), 0.2)),
    ("LeftWrist", "LeftLowerArm", "LeftHand", (0.84, 0.0, 3.06), ((0.0, 0.0, -1.0), 0.12)),
    ("LeftHip", "LowerTorso", "LeftUpperLeg", (0.30, 0.02, 3.22), ((0.5, 0.0, -0.87), 0.36)),
    ("LeftKnee", "LeftUpperLeg", "LeftLowerLeg", (0.30, -0.01, 1.76), ((0.0, 0.0, -1.0), 0.22)),
    ("LeftAnkle", "LeftLowerLeg", "LeftFoot", (0.32, 0.06, 0.30), ((0.0, 0.0, -1.0), 0.14)),
]
# The shoulder's and hip's seams sit where the arm and leg leave the body, not at the pivot.
SEAM_AT = {"Neck": (0.0, 0.02, 5.365), "LeftShoulder": (0.70, 0.02, 5.10),
           "LeftHip": (0.36, 0.02, 3.06)}

# HumanoidRootPart, R15's invisible root: its centre and size (x, y, z Blender).
ROOT_PART = ((0.0, 0.0, 3.60), (2.0, 1.0, 2.0))

# The shapes the poses are checked against (tests/mannequin.spec.luau): capsules a little inside
# each part's skin, (a, b, radius), left side.
CAPSULES = {
    "Head": [((0.0, 0.0, 5.85), (0.0, 0.0, 6.05), 0.25), ((0.0, 0.03, 5.38), (0.0, 0.04, 5.6), 0.12)],
    "UpperTorso": [((-0.28, -0.02, 4.55), (0.28, -0.02, 4.55), 0.28),
                   ((-0.30, 0.0, 5.0), (0.30, 0.0, 5.0), 0.22),
                   ((0.0, 0.0, 4.1), (0.0, 0.0, 4.4), 0.30)],
    "LowerTorso": [((-0.22, 0.02, 3.45), (0.22, 0.02, 3.45), 0.27), ((0.0, 0.0, 3.8), (0.0, 0.0, 3.85), 0.30)],
    "UpperArm": [((0.78, 0.02, 5.0), (0.80, 0.03, 4.05), 0.11)],
    "LowerArm": [((0.80, 0.03, 3.95), (0.84, 0.0, 3.12), 0.07)],
    "Hand": [((0.84, 0.0, 3.0), (0.81, 0.0, 2.48), 0.04)],
    "UpperLeg": [((0.30, 0.02, 3.15), (0.30, -0.01, 1.85), 0.15)],
    "LowerLeg": [((0.30, -0.01, 1.7), (0.32, 0.06, 0.38), 0.09)],
    "Foot": [((0.32, 0.18, 0.09), (0.335, -0.5, 0.07), 0.07)],
}
# Points on each sole (left), for setting a pose's lowest foot on the floor.
SOLE = [(0.32, 0.24, 0.0), (0.335, -0.60, 0.0), (0.235, -0.42, 0.0), (0.435, -0.42, 0.0)]

# Where it's been knocked about in a unit and a van: the paint chips most here (left side, and
# mirrored), (point, reach).
KNOCKS = [((0.0, -0.36, 5.90), 0.035), ((0.0, -0.30, 5.62), 0.06), ((0.0, 0.05, 6.28), 0.12),
          ((0.80, -0.05, 5.20), 0.14), ((0.80, 0.12, 3.98), 0.10), ((0.30, -0.14, 1.76), 0.12),
          ((0.335, -0.62, 0.05), 0.08), ((0.32, 0.27, 0.06), 0.06), ((0.81, -0.08, 2.47), 0.06),
          ((0.84, -0.11, 2.78), 0.06), ((0.62, -0.2, 4.95), 0.08)]

# The display stand's socket, a steel-rimmed hole in the back of its right calf (x is the left
# side's, so this one isn't mirrored): where it stood in a shop window once.
STAND = ((-0.30, 0.175, 1.45), 0.042, 0.016)   # centre, hole radius, steel ring's width

SEED = 21.0

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


def joints():
    """Every joint, both sides: (name, part0, part1, pivot, seam) in Blender's frame."""
    out = []
    for name, p0, p1, at, seam in JOINTS:
        if not name.startswith("Left"):
            out.append((name, p0, p1, at, seam, SEAM_AT.get(name, at)))
            continue
        out.append((name, p0, p1, at, seam, SEAM_AT.get(name, at)))
        r = lambda s: s.replace("Left", "Right")  # noqa: E731
        sm = (mirror(seam[0]), seam[1]) if seam else None
        out.append((r(name), r(p0), r(p1), mirror(at), sm, mirror(SEAM_AT.get(name, at))))
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
        "-- Generated by art/mannequin/build.py --stage export from art/mannequin/spec.py. Don't",
        "-- edit: change the spec and rebuild (scripts/art.sh mannequin).",
        "-- Studs, in the figure's own frame at rest: Roblox's axes (X its right, Y up, Z behind it),",
        "-- the origin on the floor between its feet. Plain number lists, so Lune can check poses.",
        "",
        "export type Vec = { number } -- x, y, z",
        "export type Joint = { Name: string, Part0: string, Part1: string, At: Vec }",
        "export type Capsule = { A: Vec, B: Vec, Radius: number }",
        "export type Part = { Size: Vec, Centre: Vec, Triangles: number }",
        "",
        f"local Height = {HEIGHT}",
        "",
        "-- R15's joints from the root out: a Motor6D `Name` turns `Part1` about `At` on `Part0`.",
        "local Joints: { Joint } = {",
    ]
    for name, p0, p1, at, _, _ in joints():
        L.append(f'\t{{ Name = "{name}", Part0 = "{p0}", Part1 = "{p1}", At = {lua_vec(at)} }},')
    L += ["}", "", "-- Each MeshPart's box at rest, as imported (its centre is its CFrame).",
          "local Parts: { [string]: Part } = {"]
    for name in ORDER:
        r = parts[name]
        sx, sy, sz = r["size"]
        L.append(f"\t{name} = {{ Size = {{ {sx:.3f}, {sy:.3f}, {sz:.3f} }}, "
                 f"Centre = {lua_vec(r['centre'])}, Triangles = {r['tris']} }},")
    L += ["}", "", "-- Capsules a little inside each part's skin, for checking a pose never puts one",
          "-- part through another.", "local Capsules: { [string]: { Capsule } } = {"]
    for name in ORDER:
        s = side_of(name)
        caps = CAPSULES[base(name)]
        rows = []
        for a, b, r in caps:
            if s < 0:
                a, b = mirror(a), mirror(b)
            rows.append(f"{{ A = {lua_vec(a)}, B = {lua_vec(b)}, Radius = {r} }}")
        L.append(f"\t{name} = {{ " + ", ".join(rows) + " },")
    L += ["}", "", "-- Points on each sole, to stand a pose's lowest foot on the floor.",
          "local Soles: { [string]: { Vec } } = {"]
    for s in SIDES:
        pts = SOLE if s == "Left" else [mirror(p) for p in SOLE]
        L.append(f"\t{s}Foot = {{ " + ", ".join(lua_vec(p) for p in pts) + " },")
    (c, size) = ROOT_PART
    L += ["}", "", "-- HumanoidRootPart: R15's invisible root, the part a mover drives.",
          f"local RootPart = {{ Centre = {lua_vec(c)}, Size = {{ {size[0]}, {size[2]}, {size[1]} }} }}",
          "", "return {", "\tHeight = Height,", "\tJoints = Joints,", "\tParts = Parts,",
          "\tCapsules = Capsules,", "\tSoles = Soles,", "\tRootPart = RootPart,", "}", ""]
    with open(path, "w") as f:
        f.write("\n".join(L))
    print("SPEC", path)
