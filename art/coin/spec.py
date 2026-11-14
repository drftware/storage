"""Every number of the coin, in studs. Change them here only.

The coin a door pays out (GDD "Doors": about seven units in ten have one to three coins lying on
the floor; a tap picks them up and your count goes up). A chunky old gold coin, worn: a raised rim
with a ring of beads inside it, a keyhole stamped through the middle of both faces (the building's
own mint, for the machine on the ride), a reeded edge, tarnish in the low places and the high
places rubbed bright.

Sized to be seen rather than to life, as the tools are: 0.8 studs across and 0.12 thick, about
three times a real coin, so a pile reads on a unit's floor from the doorway on a phone and catches
the bulb and your torch.

The coin's frame in Blender: Z through it (its faces at +Z and -Z), the origin its middle. The
FBX turns this into Roblox's frame (Y through it), and the game reads the numbers, and the piles'
layouts, from src/shared/Coins/Specs.luau, which the export stage writes.
"""

import math
import os

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", ".."))

SET = "Coin"      # the texture set, and the MeshPart's name
TEX = 512         # one small coin: 512 gives it about 400 texels a stud
DUST = 0.0        # a coin is turned over in hands; no dust on it
SEED = 61.0

R = 0.4           # the coin's radius
T = 0.12          # its thickness, rim to rim
SEGS = 32         # round its edge: smooth at phone size, 512 triangles a coin

RIM_W = 0.07      # the raised rim's width, in from the edge
FIELD_DROP = 0.016  # how far the field (the flat inside the rim) sits below the rim's top
RIM_SLOPE = 0.012   # the rim's inner wall, from the field up to its top
EDGE_BEVEL = 0.014  # the rim's outer corner, rounded off where it wears

BEADS = 28        # the ring of little raised beads just inside the rim
BEAD_RING = R - RIM_W - 0.04
BEAD_R = 0.012

# The keyhole stamped in the middle: a round head and a flared foot, sunk into the field, with a
# raised ring round it.
KEY_HEAD = (0.0, 0.045, 0.055)    # x, y of the head's middle, its radius
KEY_FOOT = (-0.085, 0.03, 0.06)   # the foot from its bottom (y) up: bottom, half width at the top,
                                  # half width at the bottom
KEY_RING = (0.15, 0.17)           # the raised ring round it: inner and outer radius

# --- the piles --------------------------------------------------------------------------------
# A pile of one, two or three coins as it lies on a unit's floor, in Roblox's frame from the
# pile's middle on the floor (Y up): each coin's middle and its turn (degrees about X, then Y,
# then Z, as CFrame.fromOrientation takes them in Roblox's YXZ order). Worked out from the coin's
# own size so the coins touch and never sink into each other or the floor.


def _lean(under_x, under_z, toward_deg, over):
    """A coin leaning on a flat coin lying at (under_x, under_z): its low edge on the floor `over`
    studs past the flat coin's rim, its face resting on that rim, leaning `toward_deg` degrees
    round from +X (Roblox's frame) back over it. Returns its middle and its tilt."""
    tilt = math.atan2(T, over)
    # in the lean's own plane: s along the floor away from the flat coin, h up
    s_low = R + over                      # the low edge's foot, from the flat coin's middle
    s_mid = s_low - R * math.cos(tilt) + (T / 2) * math.sin(tilt)
    h_mid = R * math.sin(tilt) + (T / 2) * math.cos(tilt)
    a = math.radians(toward_deg)
    x = under_x + s_mid * math.cos(a)
    z = under_z - s_mid * math.sin(a)
    return (x, h_mid, z), math.degrees(tilt)


def piles():
    """Each pile's coins as (middle, (rx, ry, rz)) in Roblox's frame, before centring."""
    flat = T / 2
    one = [((0.0, flat, 0.0), (0.0, 37.0, 0.0))]
    # A leaning coin is turned to its direction (about Y), then tipped back over the flat coin
    # about its own Z: a negative turn tips its face away from the flat coin, as it lies.
    lean2, tilt2 = _lean(0.0, 0.0, 20.0, 0.32)
    two = [
        ((0.0, flat, 0.0), (0.0, 12.0, 0.0)),
        (lean2, (0.0, 20.0, -tilt2)),
    ]
    # Three: a second coin lying on the first, slid off its middle away from the third, which
    # leans on the first from the other side; slid this far (0.32) the lean clears it.
    lean3, tilt3 = _lean(0.0, 0.0, 200.0, 0.28)
    off = math.radians(20.0)
    three = [
        ((0.0, flat, 0.0), (0.0, 64.0, 0.0)),
        ((0.32 * math.cos(off), flat + T, -0.32 * math.sin(off)), (0.0, 151.0, 0.0)),
        (lean3, (0.0, 200.0, -tilt3)),
    ]
    return {1: one, 2: two, 3: three}


def centred():
    """The piles moved so each one's footprint (every coin as a disc of radius R) is centred on
    its middle; with each pile's footprint size (across X, along Z) and height."""
    out = {}
    for n, coins in piles().items():
        xs = [c[0][0] for c in coins]
        zs = [c[0][2] for c in coins]
        cx = (min(xs) + max(xs)) / 2
        cz = (min(zs) + max(zs)) / 2
        moved = [((p[0] - cx, p[1], p[2] - cz), turn) for p, turn in coins]
        across = max(xs) - min(xs) + 2 * R
        along = max(zs) - min(zs) + 2 * R
        # each coin's highest point: its middle, plus half its tipped face and half its thickness
        tall = max(p[1] + R * math.sin(math.radians(abs(t[2]))) + (T / 2) * math.cos(math.radians(t[2]))
                   for p, t in moved)
        out[n] = (moved, (across, tall, along))
    return out


def to_roblox(v):
    """Blender's (x, y, z) to Roblox's: x = -x, y = z, z = y."""
    return (-v[0], v[2], v[1])


def write_luau(path, coin):
    """coin: dict(size, tris) in Roblox axes."""

    def v3(v):
        return f"Vector3.new({v[0]:.3f}, {v[1]:.3f}, {v[2]:.3f})"

    lines = [
        "--!strict",
        "-- Generated by art/coin/build.py --stage export from art/coin/spec.py.",
        "-- Don't edit: change the spec and rebuild (scripts/art.sh coin).",
        "-- Studs. The coin in its own frame: its faces up and down (Y), its middle the origin.",
        "-- A pile's coins from the pile's middle on the floor, each a middle and a turn in degrees",
        "-- (CFrame.fromOrientation's x, y, z).",
        "",
        "export type Coin = { Position: Vector3, Turn: Vector3 }",
        "export type Pile = { Coins: { Coin }, Size: Vector3 } -- Size: across, tall, along",
        "",
        "return {",
        f"\tCoin = {{ Size = {v3(coin['size'])}, Triangles = {coin['tris']} }},",
        "\tPiles = {",
    ]
    for n, (coins, size) in sorted(centred().items()):
        lines.append(f"\t\t[{n}] = {{")
        lines.append(f"\t\t\tSize = {v3(size)},")
        lines.append("\t\t\tCoins = {")
        for p, turn in coins:
            lines.append(f"\t\t\t\t{{ Position = {v3(p)}, Turn = {v3(turn)} }},")
        lines.append("\t\t\t},")
        lines.append("\t\t} :: Pile,")
    lines += ["\t},", "}", ""]
    with open(path, "w") as f:
        f.write("\n".join(lines))
    print("SPEC", path)
