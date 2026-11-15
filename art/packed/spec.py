"""The packed unit's stacks (B-05a, D-205): every number in one place (art/packed/README.md).

A packed unit is boxes to the ceiling with one path through to the back. Its walls are blocks:
each block is one MeshPart of several moving boxes (art/boxes) stacked as people stack them, a
little askew, built low (a few quads a face) so a whole unit of them stays cheap on a low-end
phone. Every block wears the boxes' own Cardboard texture set: its faces map onto the same atlas
islands the boxes do, so the game hands each block the boxes' SurfaceAppearance and nothing new is
uploaded or held in memory.

Frame (Blender, as the boxes'): X across the block's front, Y into it (its front faces -Y, the
path or the doorway), Z up. A block's pivot is the middle of its nominal footprint on the floor.
"""

import os

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", ".."))

# The unit's steel top is 10 studs up (art/unit, WallHeight). A block stops short of it so a box
# never pokes through, and close enough that from the path it reads as stacked to the ceiling.
CEILING = 10.0
TOP_MAX = 9.7
# Blocks stand side by side at this pitch; a column's boxes are 1.8 across, so each pair of
# neighbours leaves a dark crack of about 0.2 between them, as real stacks do.
PITCH = 2.0
# How far a box's front may sit off its block's front line (proud or sunk), so the wall the torch
# rakes along isn't a flat plane; and the most a box is turned off square.
PROUD = 0.1
ASKEW = 5.0
TOP_ASKEW = 20.0  # a box nothing stands on can be set down carelessly

# Boxes the blocks are made of: the boxes kit's sizes; "Photos" is a medium box wearing the open
# box's sides (PHOTOS in marker on its long side, UP on its end) and the medium's taped top, so a
# wall of mediums isn't all KITCHEN. (Sides key, top key, size from.)
SKINS = {
    "Small": ("Small", "Small", "Small"),
    "Medium": ("Medium", "Medium", "Medium"),
    "Photos": ("Open", "Medium", "Medium"),
    "Large": ("Large", "Large", "Large"),
    "Wardrobe": ("Wardrobe", "Wardrobe", "Wardrobe"),
}

# Each block: its nominal footprint (width along X, depth along Y), what it's for, and its boxes
# bottom to top as (box, x, proud, turn, on, pose):
#   x      the box's middle across the block (the build nudges it in if it would poke past)
#   proud  how far its front sits out of the block's front line (+ toward the path)
#   turn   degrees about up; 0 shows its long side (the marker word) to the front, 90 its end
#   on     the index of the box it stands on, or None for the floor
#   pose   None standing; "lying" on its side (turned about Y, so a wardrobe box lies 4 wide);
#          (rx, ry) degrees for one that fell, rested on the floor or on `on`
BLOCKS = {
    # One column to the ceiling, three ways, so a run of them never repeats in step.
    "ColumnA": dict(kind="Column", width=PITCH, depth=1.8, boxes=[
        ("Large", 0.02, 0.0, 2.0, None, None),
        ("Medium", -0.04, 0.06, 92.0, 0, None),
        ("Photos", 0.05, -0.05, -3.0, 1, None),
        ("Medium", -0.03, 0.04, 2.0, 2, None),
        ("Small", 0.08, -0.08, 86.0, 3, None),
        ("Small", -0.06, 0.05, 9.0, 4, None),
    ]),
    "ColumnB": dict(kind="Column", width=PITCH, depth=1.8, boxes=[
        ("Photos", -0.03, 0.02, 89.0, None, None),
        ("Large", 0.04, -0.06, 3.0, 0, None),
        ("Medium", 0.0, 0.08, -2.0, 1, None),
        ("Photos", -0.05, -0.02, 4.0, 2, None),
        ("Medium", 0.06, 0.05, 91.0, 3, None),
    ]),
    "ColumnC": dict(kind="Column", width=PITCH, depth=1.8, boxes=[
        ("Medium", 0.03, -0.04, 1.0, None, None),
        ("Medium", -0.05, 0.05, -91.0, 0, None),
        ("Large", 0.02, -0.07, 3.0, 1, None),
        ("Photos", 0.06, 0.03, -4.0, 2, None),
        ("Small", -0.12, 0.08, 87.0, 3, None),
        ("Small", 0.1, -0.05, -3.0, 4, None),
    ]),
    # Two columns' width on a wardrobe box laid on its side, its print turned sideways. Larges are
# kept few: every large says XMAS on both its side and its end.
    "WideA": dict(kind="Wide", width=2 * PITCH, depth=2.4, boxes=[
        ("Wardrobe", 0.0, 0.0, 0.0, None, "lying"),
        ("Large", -1.0, -0.05, 91.0, 0, None),
        ("Medium", -0.97, 0.06, -3.0, 1, None),
        ("Photos", -1.04, -0.02, 88.0, 2, None),
        ("Small", -0.9, 0.04, 5.0, 3, None),
        ("Medium", 1.02, 0.03, 2.0, 0, None),
        ("Photos", 0.98, -0.06, -89.0, 5, None),
        ("Large", 1.03, 0.05, 3.0, 6, None),
        ("Small", 0.95, -0.02, -12.0, 7, None),
    ]),
    # Two larges with a wardrobe box laid across them, two columns on that.
    "WideB": dict(kind="Wide", width=2 * PITCH, depth=2.4, boxes=[
        ("Large", -1.0, 0.04, -2.0, None, None),
        ("Large", 1.0, -0.03, 92.0, None, None),
        ("Wardrobe", 0.0, 0.0, 0.0, 0, "lying"),
        ("Medium", -0.98, 0.05, 92.0, 2, None),
        ("Photos", -1.02, -0.04, 3.0, 3, None),
        ("Small", -1.05, 0.02, 8.0, 4, None),
        ("Photos", 1.0, -0.05, -2.0, 2, None),
        ("Medium", 1.04, 0.06, 2.0, 6, None),
        ("Small", 0.92, -0.03, -84.0, 7, None),
    ]),
    # Waist to shoulder high: a step in front of a column, or the low side of the clearing at the
    # back, where the torch finds its tops.
    "Half": dict(kind="Half", width=PITCH, depth=1.8, boxes=[
        ("Large", 0.0, 0.03, 91.0, None, None),
        ("Medium", 0.05, -0.04, -4.0, 0, None),
        ("Small", -0.1, 0.06, 14.0, 1, None),
    ]),
    # Two that came down: a large on its back, its taped top to the path, and a medium that
    # slid off it and came to rest tipped on an edge of its bottom. A little wider than two columns.
    "Toppled": dict(kind="Toppled", width=4.4, depth=2.4, boxes=[
        ("Large", -1.1, 0.0, 4.0, None, (90.0, 0.0)),
        ("Medium", 1.25, -0.15, -10.0, None, (0.0, 16.0)),
    ]),
}
ORDER = ["ColumnA", "ColumnB", "ColumnC", "WideA", "WideB", "Half", "Toppled"]

# Quads a box face is cut into: 2 x 2 lets a side bow out (the middle vertex) for the soft, full
# look the boxes kit has, at 8 triangles a face. Tops that sit under another box stay one quad.
SPLIT = 2

# The look sheets' packed M unit (Blender frame: x across, y in from the doorway at 0, the back
# wall at 12): (block, x, y, facing), (x, y) the middle of the block's front edge. Facing is where
# its front looks: "door" (-Y), "back" (+Y), "left" (-X) or "right" (+X). The path comes in 3 wide
# up the middle (under the bulb), then turns left along the back wall into a clearing in the
# back-left corner that the doorway can't see. The B-05b deal lays real units by its own rules.
SAMPLE = [
    # facing the door, their front line 2.5 in (DealSpot.Door)
    ("ColumnA", -2.5, 2.5, "door"),
    ("ColumnC", -4.5, 2.5, "door"),
    ("WideB", 3.5, 2.5, "door"),
    # the left side of the way in, facing right across it
    ("ColumnB", -1.5, 5.35, "right"),
    ("ColumnA", -1.5, 7.45, "right"),
    # the right side, facing left, to the back
    ("ColumnC", 1.5, 5.9, "left"),
    ("WideA", 1.5, 8.9, "left"),
    # the clearing: its near side faces the back wall; a low stack in its far corner
    ("ColumnB", -4.5, 8.6, "back"),
    ("Half", -4.9, 9.8, "door"),
]
SAMPLE_BOX = (-2.6, 10.6, -12.0)  # where the marked box waits in the clearing: x, y, turn


def check():
    """What the blocks must hold to; the build runs these before anything else."""
    for name in ORDER:
        b = BLOCKS[name]
        under = {on for *_, on, _ in b["boxes"] if on is not None}
        for i, (box, x, proud, turn, on, pose) in enumerate(b["boxes"]):
            assert box in SKINS, f"{name}[{i}]: no box {box}"
            assert on is None or on < i, f"{name}[{i}] stands on a box laid after it"
            fell = isinstance(pose, tuple)
            assert fell or abs(proud) <= PROUD + 1e-9, f"{name}[{i}] sits {proud} off the front line"
            if pose is None:
                off = min(abs(turn - k * 90.0) for k in range(-1, 3))
                most = ASKEW if i in under else TOP_ASKEW
                assert off <= most + 1e-9, f"{name}[{i}] turned {off} off square"
