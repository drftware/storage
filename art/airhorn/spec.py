"""Every number of the air horn. Change them here only.

A marine air horn, the kind boats and stadiums use: a steel can of compressed gas in white enamel
printed with a black band, and a safety-orange plastic trumpet standing up out of a black collar
clamped over the can's top. You press the trumpet down and it blasts. It lures keepers to a spot
and wakes dormant things nearby (GDD, the tools table), as Lethal Company's air horn draws the
monsters that hunt by sound.

Drawn in a real horn's inches, then scaled by IN to studs: about 1.6 times life, as the small
tools are sized up to read in a Roblox hand (the padlock is twice), 1.9 studs from the can's foot
to the bell's lip. White and orange, because the torch is yellow, the cutters red and the saw
green: the can is the one white tool, and the flared trumpet is its outline from a doorway.

The horn's frame in Blender: Z up the can's axis (the trumpet on top), the can's printed front
(the sound-wave mark) towards -Y, the origin the grip (the can's axis at the middle of its
label, where the hand closes). The drawing's own numbers run up from the can's foot (z = 0);
GRIP_Z moves them. The FBX turns this into Roblox's frame (Y up, the printed front towards the
part's LookVector), and the game reads the numbers from src/shared/Tools/Specs/AirHorn.luau,
which the export stage writes.
"""

import math
import os

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", ".."))

SET = "AirHorn"   # the texture set, and the MeshPart's name
TEX = 1024        # seen a couple of studs from your eye in first person: the finds' atlas size
DUST = 0.1        # a tool left on a unit's floor a while: dust on the collar and the can's top
SEED = 53.0
SEGS = 40         # points round the can and the trumpet: round at arm's length on a phone

IN = 0.15         # studs to the drawing's inch
GRIP_Z = 3.0      # the drawing's z of the grip: the middle of the can's label

# Each piece is turned round the can's axis through (z, radius) points in inches, z up from the
# can's foot. A radius of 0 closes the piece on its axis.
CAN_R = 1.49
# the foot: the domed bottom (pushed up inside, as a pressure can's is), the rolled chime round it
CAN_FOOT = [(0.42, 0.0), (0.37, 0.62), (0.22, 1.1), (0.07, 1.33), (0.0, 1.41), (0.03, 1.49),
            (0.12, 1.53), (0.24, 1.52), (0.32, 1.48), (0.38, CAN_R)]
CAN_WALL = (0.38, 5.2, 10)        # the straight wall: from, to, and the rings along it
# the top: the seam bead, then the shoulder up under the collar
CAN_TOP = [(5.2, CAN_R), (5.28, 1.51), (5.38, 1.54), (5.48, 1.51), (5.55, 1.42), (5.75, 1.2),
           (5.92, 0.9), (6.02, 0.55), (6.05, 0.0)]
TIN = ((-0.1, 0.4), (5.22, 5.56))  # where the can is bare tinplate (z from, z to): the foot and
#                                   its chime, and the seam bead

# The collar: black plastic snapped over the seam bead, ribbed round its skirt for a grip.
COLLAR = [(5.6, 0.0), (5.58, 1.34), (5.5, 1.5), (5.52, 1.57), (5.62, 1.6), (6.25, 1.58),
          (6.4, 1.53), (6.55, 1.36), (6.66, 1.08), (6.72, 0.8), (6.74, 0.0)]
KNURL = dict(z=(5.72, 6.22), ribs=40, groove=0.4)   # the ribs: where, how many, the groove's share

# The trumpet: its flange sunk in the collar, a neck, then an exponential flare to the bell (the
# radius grows as e^(k t) along it), rolled over at the mouth, its wall WALL_T thick, and the
# inside running down to the throat where it closes.
TRUMPET_BASE = [(6.66, 0.0), (6.66, 0.74), (6.74, 0.79), (6.86, 0.78), (6.95, 0.6), (7.05, 0.5)]
FLARE = dict(z=(7.05, 12.22), r=(0.5, 1.52), k=3.0, rings=18)
BEAD = dict(z=7.75, out=0.06, w=0.2)   # a moulded ring round the neck
LIP = [(12.3, 1.58), (12.38, 1.6), (12.43, 1.55), (12.4, 1.47)]
WALL_T = 0.08
THROAT = (8.6, 8.2)       # how far down the inside runs at the flare's own shape, where it closes

# Where the paint goes, in the drawing's inches (x across the front, z up).
BAND = (1.85, 4.35)       # the label's black band
STRIPE = 0.14             # the orange stripes along its edges
# the sound-wave mark on the front: a dot and three arcs going out to the right
WAVES = dict(c=(-0.6, 3.1), dot=0.24, r=(0.5, 0.82, 1.14), t=0.13, spread=0.9)
TYPE_FRONT = (2.02, 2.2)  # a line of white type under the mark
TYPE_BACK = ((4.62, 5.08), (0.62, 1.66))   # the warnings on the back, above and below the band


def flare_r(z):
    """The trumpet's outside radius at z, along its flare."""
    (z0, z1), (r0, r1), k = FLARE["z"], FLARE["r"], FLARE["k"]
    t = min(max((z - z0) / (z1 - z0), 0.0), 1.0)
    return r0 + (r1 - r0) * (math.exp(k * t) - 1.0) / (math.exp(k) - 1.0)


def to_roblox(v):
    """Blender's (x, y, z) to Roblox's: x = -x, y = z, z = y."""
    return (-v[0], v[2], v[1])


def at(z):
    """A drawing height (inches) in the horn's frame (studs above the grip)."""
    return (z - GRIP_Z) * IN


def write_luau(path, body):
    """body: dict(size, centre, tris) in Roblox axes, from the grip."""

    def v3(v):
        return f"Vector3.new({v[0]:.3f}, {v[1]:.3f}, {v[2]:.3f})"

    mouth = to_roblox((0.0, 0.0, at(LIP[1][0])))
    foot = to_roblox((0.0, 0.0, at(0.0)))
    lines = [
        "--!strict",
        "-- Generated by art/airhorn/build.py --stage export from art/airhorn/spec.py.",
        "-- Don't edit: change the spec and rebuild (scripts/art.sh airhorn).",
        "-- Studs, in the horn's own frame: the trumpet up (+Y), the can's printed front towards the",
        "-- LookVector (-Z), every point measured from the grip, where the hand closes round the can.",
        "",
        "export type Piece = {",
        "\tSize: Vector3, -- the piece's box",
        "\tCentre: Vector3, -- the box's middle, from the grip",
        "\tTriangles: number,",
        "}",
        "",
        "return {",
        f"\tBody = {{ Size = {v3(body['size'])}, Centre = {v3(body['centre'])}, "
        f"Triangles = {body['tris']} }} :: Piece,",
        "\t-- the middle of the bell's mouth, where the blast comes out",
        f"\tMouth = {v3(mouth)},",
        "\t-- the bell's radius at its lip",
        f"\tMouthRadius = {LIP[1][1] * IN:.3f},",
        "\t-- the middle of the can's foot, what it stands on",
        f"\tFoot = {v3(foot)},",
        "}",
        "",
    ]
    with open(path, "w") as f:
        f.write("\n".join(lines))
    print("SPEC", path)
