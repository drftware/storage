"""Every number of the wrap a kept player stands in. Change them here only.

Caught, you're shrink-wrapped head to foot in clear stretch film and stored standing in a shut unit
(GDD "Getting kept"; L-07b). The friend who lifts the door finds you there in the dark: a cloudy
cocoon in overlapping bands, creased, your shape and your clothes blurred inside it.

Drawn round Roblox's default blocky R15 body standing at rest (arms down, measured in Studio on the
owner's avatar, Nov 10), in studs. The game scales it per axis to the kept character's own rest box
(KeptPlayers), so a taller or slimmer body gets a taller or slimmer wrap.

Its frame in Blender: X across (its own left is +X), Y front to back (it faces -Y), Z up, the origin
on the floor between its feet, as the Mannequin's is. The FBX turns that into Roblox's frame
(Roblox X = -x, Y = z, Z = y) and src/shared/KeptWrap/Specs.luau, which the export stage writes,
carries the body box it was drawn round and its own box, both from the character's root.
"""

import os

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", ".."))

SET = "KeptWrap"   # the texture set, and the MeshPart's name
TEX = 1024
DUST = 0.0         # fresh film: no dust
SEED = 71.0
SEGS = 40          # points round each ring: round at a doorway's distance on a phone
STEP = 0.1         # studs between rings up the body (about 56 rings)

# The body it's drawn round: Roblox's default blocky R15 at rest, each part's box from the root
# (Roblox axes, measured from the joints' rest CFrames in Studio). The root stands ROOT_Z over the
# floor. Only the look sheets draw it; the game reads the box (BODY) to scale the wrap.
ROOT_Z = 3.0
BODY_PARTS = {     # name: (x0, x1, y0, y1, z0, z1), Roblox root space
    "Head": (-0.60, 0.60, 0.98, 2.19, -0.60, 0.60),
    "UpperTorso": (-0.92, 0.92, -0.90, 1.00, -0.56, 0.52),
    "LowerTorso": (-0.84, 0.84, -0.99, -0.36, -0.50, 0.54),
    "LeftUpperArm": (-1.62, -0.68, -0.29, 0.92, -0.30, 0.45),
    "LeftLowerArm": (-1.80, -0.99, -0.80, 0.36, -0.45, 0.45),
    "LeftHand": (-1.88, -1.13, -1.35, -0.46, -0.72, 0.06),
    "LeftUpperLeg": (-0.78, 0.00, -2.31, -0.56, -0.42, 0.44),
    "LeftLowerLeg": (-0.78, -0.06, -2.87, -1.61, -0.42, 0.44),
    "LeftFoot": (-0.78, -0.06, -3.00, -2.18, -0.81, 0.44),
}
# the body's rest box, Roblox root space: lo and hi
BODY = ((-1.88, -3.00, -0.81), (1.88, 2.19, 0.60))

# The cocoon, lofted up from the floor through stations: (z over the floor, half-width, half-depth,
# its middle's y, round), `round` the section's superellipse power (2 an ellipse, more is boxier).
# The film is wound tight, so it follows the body: the legs bound together, a taut cone from the
# hands down to the thighs, the arms bound to the sides (wide and boxy there to hold the hands and
# elbows), a pinch at the neck, the head swaddled roomy enough for most hair, and the film gathered
# and twisted shut over the crown.
STATIONS = [
    (0.00, 1.00, 0.84, -0.17, 3.2),   # round the feet, the toes ahead
    (0.30, 0.98, 0.80, -0.14, 3.0),
    (0.80, 0.94, 0.72, -0.12, 2.6),   # the shins, over the toes
    (1.10, 0.96, 0.57, 0.00, 2.4),    # the knees
    (1.38, 1.38, 0.62, -0.04, 2.8),   # the film's cone up to the hands
    (1.58, 1.88, 0.72, -0.08, 3.6),
    (1.78, 2.05, 0.80, -0.09, 4.0),   # the hands, bound at the thighs
    (2.60, 2.06, 0.80, -0.07, 4.0),   # the hips and wrists
    (3.30, 2.02, 0.78, -0.04, 4.0),   # the elbows
    (3.70, 1.90, 0.74, 0.00, 3.6),    # the upper arms
    (3.95, 1.52, 0.68, 0.00, 3.0),    # over the shoulders
    (4.12, 0.88, 0.68, -0.02, 2.4),   # the neck
    (4.35, 0.86, 0.80, -0.06, 2.3),   # the jaw
    (4.75, 0.90, 0.86, -0.07, 2.3),   # the head, swaddled
    (5.10, 0.80, 0.77, -0.06, 2.2),
    (5.32, 0.52, 0.50, -0.04, 2.0),   # the crown, the film drawn in
    (5.44, 0.16, 0.16, -0.02, 2.0),   # gathered
    (5.50, 0.05, 0.05, 0.00, 2.0),    # the twist's tip
]
LUMP = 0.025       # studs: the film isn't a perfect skin; its surface wanders this much

# The film: bands of stretch wrap wound up from the feet, each laid over the top of the last.
BAND = 0.95        # a band's height on the body, studs: reads as bands from a doorway on a phone
LAP = 0.35         # how much of each band the next one covers
# how far a band climbs in one turn round the body, studs: a spiral, not rings; one band's step,
# so the spiral meets itself all the way round
PITCH = BAND * (1.0 - LAP)
# How see-through it is (alpha, 0 clear to 1 solid): one layer, where two overlap, the edge rope
# (stretched film necks into a thin bright cord along each edge), the creases, and the gathered
# twist on top. Cloudy enough that you see someone in it, not who: raised Nov 10 after Studio,
# where Roblox blends it lighter than Blender renders it and 0.28 left the face plain to read.
ALPHA = dict(one=0.46, two=0.68, edge=0.92, crease=0.18, twist=0.88)
EDGE_W = 0.05      # the edge rope's width, studs: a line a phone shows from the doorway


def to_roblox(v):
    """Blender's (x, y, z) to Roblox's: x = -x, y = z, z = y."""
    return (-v[0], v[2], v[1])


def write_luau(path, size, centre, tris):
    """size, centre: the wrap's box, Roblox axes, the centre from the character's root."""
    lo, hi = BODY

    def v3(v):
        return f"Vector3.new({v[0]:.3f}, {v[1]:.3f}, {v[2]:.3f})"

    bsize = tuple(hi[i] - lo[i] for i in range(3))
    bcentre = tuple((hi[i] + lo[i]) / 2 for i in range(3))
    lines = [
        "--!strict",
        "-- Generated by art/keptwrap/build.py --stage export from art/keptwrap/spec.py.",
        "-- Don't edit: change the spec and rebuild (scripts/art.sh keptwrap).",
        "-- Studs, Roblox axes, from the character's HumanoidRootPart (it faces -Z).",
        "",
        "return {",
        "\t-- the body it was drawn round: Roblox's default blocky R15 at rest, arms down",
        f"\tBody = {{ Size = {v3(bsize)}, Centre = {v3(bcentre)} }},",
        "\t-- the wrap's own box: scale it per axis by the kept body's box over Body's",
        f"\tWrap = {{ Size = {v3(size)}, Centre = {v3(centre)}, Triangles = {tris} }},",
        "}",
        "",
    ]
    with open(path, "w") as f:
        f.write("\n".join(lines))
    print("SPEC", path)
