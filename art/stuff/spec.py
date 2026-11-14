"""Every number of the things in a unit that are only there to look at, in studs. Change them here
only.

GDD "Doors": some units with nothing to take are full of somebody's stuff, stacked boxes, a
mattress, a rolled-up carpet, so a door going up is never just a bare box. Two new pieces and four
stacks of the moving boxes (art/boxes):

- the Mattress: an old full-size mattress stood on its end, leaning back against a wall, its
  middle sagging toward the wall and its top corners flopping forward; quilted ivory ticking gone
  yellow, a big tide-marked stain, a split corner showing foam, the law tag still on it;
- the Carpet: a 5 by 8 foot patterned wool rug rolled up from a short end, tied with two lengths
  of rope and stood on its end against a wall, the fringe of its last end flopped over the roll,
  the spiral of its layers showing at its top;
- the Stacks: boxes stacked as people stack them, up to the bulb.

Sizes are the real things at 10 inches a stud, the boxes' scale. A piece's frame in Blender: X
across its front, Y away from you (its front faces -Y, its back goes to a wall), Z up, the origin
the middle of its bottom, on the floor. The FBX turns this into Roblox's frame (Y up, the front
the part's LookVector), and the game reads the sizes and the stacks from
src/shared/Stuff/Specs.luau, which the export stage writes.
"""

import importlib.util
import math
import os

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", ".."))
IN = 0.1  # studs per inch

SET = "Stuff"     # the texture set both pieces share, and the folder's name in the place
TEX = 1024
DUST = 0.55       # dust on whatever faces up: these have stood here for years

ORDER = ["Mattress", "Carpet"]

# The mattress. Built standing straight up on its foot end for the bake (so its quilting runs true
# in the recipe's studs), then posed: it leans back until its top rests on the wall, its middle
# sags toward the wall, its top corners flop forward, and its foot squashes flat on the floor.
MATTRESS = dict(
    w=54 * IN, long=75 * IN, t=9 * IN,   # a full: 54 by 75 inches, 9 thick
    corner=0.12, corner_segs=3,          # the rounded tape edge round each face
    across=6,                            # quads across a face, for its crown
    rings=7,                             # rings along its length, for the sag
    crown=0.05,                          # its faces bulge out in the middle
    lean=7.0,                            # degrees back from upright, its top on the wall
    sag=0.12,                            # its middle bows back toward the wall
    flop=0.14,                           # its top corners fold forward
    quilt=0.9,                           # the quilting's diamond, point to point
    rail=0.3,                            # the plain band inside the tape edge, round each face
    seed=71.0,
)

# The rug, rolled. Built lying along X for the bake, then stood on its end, leaning back until
# its top rests on the wall, as a rolled rug is kept: lying on the floor it was a thin line from
# the doorway. Its cross-section is one turn of a spiral, so its outer layer ends in a step the
# rug's thickness high, along its length; the fringe on that end lies flopped over the roll past
# the step, on the side facing the room.
CARPET = dict(
    long=60 * IN,        # 5 feet: rolled from a short end, the roll is the rug's width
    r=0.6,               # the roll's outer radius: 8 feet of thick wool rug, loosely rolled, a
                         # foot across (thinner, it read as a pole from the doorway)
    flat=0.9,            # it has settled under its own weight: height over width
    t=0.05,              # the rug's thickness: the outer layer's step
    core=0.07,           # the hole down its middle, where the rolling started
    segs=22,             # round the roll
    edge=50.0,           # where the outer layer ends: degrees round from the top (lying) toward
                         # the front, so the fringe past it faces the room once stood up
    lean=8.0,            # degrees back from upright, its top on the wall
    fringe=0.3,          # the fringe's length, lying over the roll past the edge
    border=0.42,         # the rug's border band, along each of its edges
    motif=0.56,          # the field's repeat, across and along the rug
    ties=(-1.85, 1.75),  # the two ropes, from the roll's middle
    tie_r=0.034, pinch=0.045,  # the rope's thickness, and how far it bites into the roll
    tie_segs=14, tie_sides=5,  # round the roll, and round the rope
    seed=83.0,
)


# --- the stacks ---------------------------------------------------------------------------------
# Each stack is boxes from art/boxes, in Roblox's frame from the stack's middle on the floor (Y
# up; its front, -Z, faces the doorway; its back goes to a wall): each box's bottom middle and its
# turn about Y in degrees (0: its labelled long side faces the front). A box stands on the floor or
# square on the top of one box below it; the checks below hold every stack to that.

def box_sizes():
    """The moving boxes' sizes in Roblox's frame (X long, Y up, Z across), from their own spec."""
    path = os.path.join(ROOT, "art", "boxes", "spec.py")
    s = importlib.util.spec_from_file_location("boxes_spec_for_stuff", path)
    mod = importlib.util.module_from_spec(s)
    s.loader.exec_module(mod)
    return {n: (b["w"], b["h"], b["d"]) for n, b in mod.BOXES.items()}


# (box, x, z, turn, on): `on` is the index of the box it stands on, or None for the floor.
STACKS = {
    # To the bulb: a wardrobe box, a large on it, a small on top, each set down a little askew.
    "Tower": [
        ("Wardrobe", 0.0, 0.0, 3.0, None),
        ("Large", 0.08, -0.06, -7.0, 0),
        ("Small", -0.06, 0.1, 16.0, 1),
    ],
    # A wall of boxes along the back: two larges, two mediums on them, a medium and a small on top.
    "Wall": [
        ("Large", -0.96, 0.02, 2.0, None),
        ("Large", 0.96, -0.04, -3.0, None),
        ("Medium", -0.99, 0.04, -5.0, 0),
        ("Medium", 1.04, -0.02, 4.0, 1),
        ("Medium", -0.95, 0.08, 9.0, 2),
        ("Small", 1.1, 0.12, -11.0, 3),
    ],
    # Someone went through these: a large with a medium on it, the open box beside, a small left
    # on the floor in front.
    "Heap": [
        ("Large", -0.8, 0.3, -6.0, None),
        ("Medium", -0.77, 0.29, 7.0, 0),
        ("Open", 1.45, 0.15, 21.0, None),
        ("Small", 0.15, -1.8, -28.0, None),
    ],
    # A short column: two mediums and a small.
    "Column": [
        ("Medium", 0.0, 0.0, -4.0, None),
        ("Medium", 0.05, 0.04, 6.0, 0),
        ("Small", -0.04, 0.06, -15.0, 1),
    ],
}
STACK_ORDER = ["Tower", "Wall", "Heap", "Column"]


def box_reach():
    """How far each box reaches from its pivot (the middle of its bottom) in Roblox's frame, as
    (left, right, front, back) past the middle: half its size and its sides' bulge each way (the
    templates measure so in Studio, a large box 1.857 across), but the open box's flaps lean out
    past its walls, each by its length (half the box's depth) times the sine of how far
    past upright it stands. Seen in Studio (S1-04b2): the open box's template reaches 1.454 to -X,
    1.010 to +X, 1.322 to the front (-Z) and 1.118 to the back, its flaps' angles taken as (front,
    back, -X end, +X end) in the boxes' Blender frame land at Roblox's (front, back, +X, -X)."""
    path = os.path.join(ROOT, "art", "boxes", "spec.py")
    s = importlib.util.spec_from_file_location("boxes_spec_for_reach", path)
    mod = importlib.util.module_from_spec(s)
    s.loader.exec_module(mod)
    out = {}
    for n, b in mod.BOXES.items():
        hx, hz = b["w"] / 2 + b["bulge"], b["d"] / 2 + b["bulge"]
        left = right = hx
        front = back = hz
        angles = b.get("open")
        if angles:
            length = b["d"] / 2  # a regular slotted box: every flap is half its depth
            past = [length * max(0.0, math.sin(math.radians(a - 90.0))) for a in angles]
            hx, hz = b["w"] / 2, b["d"] / 2  # its walls' bulge is under its flaps' lean
            front, back = hz + past[0], hz + past[1]
            right, left = hx + past[2], hx + past[3]
        out[n] = (left, right, front, back)
    return out


def _reach_corners(x, z, reach, turn):
    """The corners of the floor a box covers, flaps and all, standing at (x, z) turned `turn`."""
    left, right, front, back = reach
    a = math.radians(turn)
    c, s = math.cos(a), math.sin(a)
    out = []
    for px, pz in ((-left, -front), (right, -front), (right, back), (-left, back)):
        out.append((x + px * c + pz * s, z - px * s + pz * c))
    return out


def _corners(x, z, sx, sz, turn):
    a = math.radians(turn)
    c, s = math.cos(a), math.sin(a)
    out = []
    for u, v in ((-1, -1), (1, -1), (1, 1), (-1, 1)):
        px, pz = u * sx / 2, v * sz / 2
        # Roblox's turn about Y: x' = x cos + z sin, z' = -x sin + z cos
        out.append((x + px * c + pz * s, z - px * s + pz * c))
    return out


def _overlap(a, b):
    """Two convex footprints overlap (the separating axis test), beyond a hair's touch."""
    for poly in (a, b):
        for i in range(4):
            x0, z0 = poly[i]
            x1, z1 = poly[(i + 1) % 4]
            nx, nz = z1 - z0, x0 - x1
            pa = [nx * x + nz * z for x, z in a]
            pb = [nx * x + nz * z for x, z in b]
            if max(pa) <= min(pb) + 1e-3 or max(pb) <= min(pa) + 1e-3:
                return False
    return True


def _inside(p, poly):
    sign = None
    for i in range(4):
        x0, z0 = poly[i]
        x1, z1 = poly[(i + 1) % 4]
        cross = (x1 - x0) * (p[1] - z0) - (z1 - z0) * (p[0] - x0)
        if sign is None:
            sign = cross > 0
        elif (cross > 0) != sign:
            return False
    return True


def stacks():
    """Each stack's boxes as (name, (x, y, z), turn), centred on its footprint, with its size
    (across, tall, deep). Checks that every box stands on the floor or on a closed box below it,
    its middle over that box's top and its own footprint mostly on it, and that no two boxes
    at the same height overlap."""
    sizes = box_sizes()
    reach = box_reach()
    out = {}
    for name in STACK_ORDER:
        rows = STACKS[name]
        placed = []
        for i, (box, x, z, turn, on) in enumerate(rows):
            sx, sy, sz = sizes[box]
            y = 0.0
            if on is not None:
                under = placed[on]
                assert under["box"] != "Open", f"{name}: nothing stands on the open box"
                y = under["y"] + sizes[under["box"]][1]
                assert _inside((x, z), under["foot"]), f"{name}: box {i} hangs off box {on}"
                # most of its footprint on the box below: each corner within a hand of its top
                bx, bz = under["x"], under["z"]
                usx, _, usz = sizes[under["box"]]
                grown = _corners(bx, bz, usx + 0.5, usz + 0.5, under["turn"])
                for c in _corners(x, z, sx, sz, turn):
                    assert _inside(c, grown), f"{name}: box {i} reaches too far off box {on}"
            foot = _corners(x, z, sx, sz, turn)
            for j, other in enumerate(placed):
                if abs(other["y"] - y) < 1e-6:
                    assert not _overlap(foot, other["foot"]), f"{name}: boxes {j} and {i} overlap"
            placed.append(dict(box=box, x=x, y=y, z=z, turn=turn, foot=foot))
        # the stack's size is the floor it really covers: the open box's flaps and all
        reached = [_reach_corners(p["x"], p["z"], reach[p["box"]], p["turn"]) for p in placed]
        xs = [c[0] for r in reached for c in r]
        zs = [c[1] for r in reached for c in r]
        cx, cz = (min(xs) + max(xs)) / 2, (min(zs) + max(zs)) / 2
        tall = max(p["y"] + sizes[p["box"]][1] for p in placed)
        boxes = [(p["box"], (p["x"] - cx, p["y"], p["z"] - cz), p["turn"]) for p in placed]
        out[name] = (boxes, (max(xs) - min(xs), tall, max(zs) - min(zs)))
    return out


def write_luau(path, rows):
    """rows: {name: dict(size=(x, y, z) in Roblox axes, tris=n)}."""

    def v3(v):
        return f"Vector3.new({v[0]:.3f}, {v[1]:.3f}, {v[2]:.3f})"

    lines = [
        "--!strict",
        "-- Generated by art/stuff/build.py --stage export from art/stuff/spec.py.",
        "-- Don't edit: change the spec and rebuild (scripts/art.sh stuff).",
        "-- Studs. A piece's pivot is the middle of its bottom, on the floor; its front faces the",
        "-- part's LookVector and its back goes to a wall. A stack's boxes stand from the stack's",
        "-- middle on the floor (its front -Z): each box's bottom middle and its turn about Y in",
        "-- degrees, boxes from ReplicatedStorage.Props.Boxes.",
        "",
        "export type Piece = { Size: Vector3, Triangles: number } -- Size: across, tall, deep",
        "export type StackBox = { Box: string, Position: Vector3, Turn: number }",
        "export type Stack = { Size: Vector3, Boxes: { StackBox } }",
        "",
        "local Pieces: { [string]: Piece } = {",
    ]
    for n in ORDER:
        r = rows[n]
        lines.append(f"\t{n} = {{ Size = {v3(r['size'])}, Triangles = {r['tris']} }},")
    lines += ["}", "", "local Stacks: { [string]: Stack } = {"]
    made = stacks()
    for n in STACK_ORDER:
        boxes, size = made[n]
        lines.append(f"\t{n} = {{")
        lines.append(f"\t\tSize = {v3(size)},")
        lines.append("\t\tBoxes = {")
        for box, p, turn in boxes:
            lines.append(f'\t\t\t{{ Box = "{box}", Position = {v3(p)}, Turn = {turn:.1f} }},')
        lines += ["\t\t},", "\t},"]
    lines += [
        "}",
        "",
        "return {",
        "\tPieces = Pieces,",
        f"\tPieceOrder = {{ {', '.join(chr(34) + n + chr(34) for n in ORDER)} }},",
        "\tStacks = Stacks,",
        f"\tStackOrder = {{ {', '.join(chr(34) + n + chr(34) for n in STACK_ORDER)} }},",
        "}",
        "",
    ]
    with open(path, "w") as f:
        f.write("\n".join(lines))
    print("SPEC", path)


if __name__ == "__main__":
    for n, (boxes, size) in stacks().items():
        print(n, [round(v, 2) for v in size], [(b, [round(v, 2) for v in p], t) for b, p, t in boxes])
