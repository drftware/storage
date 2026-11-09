"""Every number of the ladder. Change them here only.

An aluminium extension ladder that has done a lot of jobs: two sections, the fly riding on the
base, rung locks at the fly's foot, a yellow rope over a pulley at the base's top, swivel feet with
rubber pads, black caps on the fly's top, orange and yellow warning labels on the rails, paint
splashes and scuffs. It gets you onto the open unit tops (GDD, the tools table): leaned on a
unit's front with the fly run out it reaches past the wire top (10 studs up); collapsed you carry
it, 6.8 studs long, short enough to lie in a small unit and turn a hall's corner.

Drawn in studs, at the building's scale (a stud is about a foot: the doors are 8 tall), not
enlarged to a hand as the small tools are, because it must fit the building it climbs.

The ladder's frame in Blender: its length along Y with its top at -Y (its front: the part's
LookVector once in Roblox), X across, Z through its face (+Z the fly's side), the origin the grip
(where a hand closes round the base's rail to carry it). The drawing's own numbers run along the
ladder from the feet (u = 0 where the base's rails end, + towards the top), across from its middle
(x) and through it from the base's back face (d = 0, + towards the fly); GRIP moves them. Two
parts, the base and the fly, each a MeshPart in one texture set; the FBX turns this into Roblox's
frame and the game reads the numbers from src/shared/Tools/Specs/Ladder.luau.
"""

import os

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", ".."))

SET = "Ladder"        # the texture set, and the base's MeshPart name
FLY = "LadderFly"     # the fly section's MeshPart
TEX = 1024            # a big thing seen from a few studs: the finds' atlas size
DUST = 0.06           # it's been leaning in a unit: a little dust on what faces up
SEED = 53.0

# The sections (studs along u). The fly sits FLY_FROM up the base when collapsed and slides out
# TRAVEL to full length: whole rungs, so its locks land on a base rung. Full length from the pads
# to the fly's caps is about 11.8: leaned at the 4-to-1 rule (75 degrees) it reaches 11.4 up, a
# stud and a half past a unit's wire top.
BASE_LEN = 6.4
FLY_LEN = 6.4
FLY_FROM = 0.2
TRAVEL = 5.0
PITCH = 1.0                                   # a foot between rungs, as a real ladder's
BASE_RUNGS = [0.5 + k * PITCH for k in range(6)]   # 0.5 to 5.5 up the base
FLY_RUNGS = [0.5 + k * PITCH for k in range(6)]    # up the fly, from its own foot

# The rails: aluminium channel, open to the outside (x), the web inside where the rungs go
# through. Each is the web (WEB thick) and two flanges, the channel DEPTH deep through the ladder.
RAIL = dict(depth=0.3, width=0.13, web=0.028, flange=0.026)
BASE_IN = 0.69        # the base rails' inner faces, either side of the middle
FLY_IN = 0.61         # the fly's: narrower, so its rails ride inside the base's guides
FLY_D = 0.33          # the fly's back face, just clear of the base's front (0.3)

# The rungs: D-shaped tubes, flat on the side you step on (+u), ribbed there in the paint, their
# ends flared over the web outside.
RUNG_R = 0.075
RUNG_FLAT = 0.62      # the flat's distance from the middle, as a share of the radius
FLARE = dict(r=0.1, t=0.014)

# The feet: a swivel shoe on each base rail, side plates either side of the channel and a ribbed
# rubber pad under them, on a bolt through the rail.
SHOE = dict(u=(-0.02, 0.26), plate=0.022, pad=(-0.16, -0.02), bolt=0.13)

# The guides: a strap round both rails at the base's top (the fly runs in it), and another at the
# fly's foot round the base's rails.
BASE_GUIDE = (5.92, 6.18)          # u, on the base
FLY_GUIDE = (0.08, 0.26)           # u from the fly's foot
GUIDE_T = 0.022

# The rung locks at the fly's foot: a cast housing inside each rail and a hook that drops over the
# base rung below (its lowest rung when collapsed, FLY_FROM + LOCK_U up the base).
LOCK_U = 0.3          # from the fly's foot: where the hook catches a base rung
LOCK_X = (0.43, 0.6)  # its housing across, inside the fly's rails

# The fly's top: black caps over its rails' ends.
CAP = 0.2

# The rope: tied to the fly's bottom rung, up the ladder's middle between the sections, over the
# pulley on the base's top, back down behind the base to a knot on its second rung.
ROPE_R = 0.032
ROPE_X = 0.12
PULLEY = dict(u=6.0, r=0.1, t=0.055)   # the wheel's middle, just over the base's top rung

# Where the paint goes (u, along each section from its foot).
LABELS = dict(danger=(4.3, 5.1), duty=(1.6, 2.1))   # on the rails' outer webs

# Where a hand closes to carry it: round the base's rail, a little behind the middle so more of
# the ladder leads.
GRIP = dict(u=2.9, x=BASE_IN + RAIL["width"] / 2, d=RAIL["depth"] / 2)


def to_roblox(v):
    """Blender's (x, y, z) to Roblox's: x = -x, y = z, z = y."""
    return (-v[0], v[2], v[1])


def at(u, x, d):
    """A drawing point (u along, x across, d through) in the ladder's frame (studs from the grip),
    Blender's axes: the top towards -Y."""
    return (x - GRIP["x"], -(u - GRIP["u"]), d - GRIP["d"])


def write_luau(path, base, fly):
    """base, fly: dict(size, centre, tris) in Roblox axes, from the grip."""

    def v3(v):
        return f"Vector3.new({v[0]:.3f}, {v[1]:.3f}, {v[2]:.3f})"

    def point(u, x, d):
        return to_roblox(at(u, x, d))

    feet = point(SHOE["pad"][0], 0.0, RAIL["depth"] / 2)
    top = point(FLY_FROM + FLY_LEN, 0.0, FLY_D + RAIL["depth"] / 2)
    lines = [
        "--!strict",
        "-- Generated by art/ladder/build.py --stage export from art/ladder/spec.py.",
        "-- Don't edit: change the spec and rebuild (scripts/art.sh ladder).",
        "-- Studs, in the ladder's own frame: its top towards the LookVector (-Z), its face up (+Y,",
        "-- the fly's side), every point measured from the grip, where a hand closes round the base's",
        "-- rail to carry it. Collapsed: the fly as it rides on the base.",
        "",
        "export type Piece = {",
        "\tSize: Vector3, -- the piece's box",
        "\tCentre: Vector3, -- the box's middle, from the grip",
        "\tTriangles: number,",
        "}",
        "",
        "return {",
        "\t-- the base section, the tool's body: its feet, rails, rungs, the pulley and the rope",
        f"\tBody = {{ Size = {v3(base['size'])}, Centre = {v3(base['centre'])}, "
        f"Triangles = {base['tris']} }} :: Piece,",
        "\t-- the fly section (LadderFly), collapsed on the base: its rails, rungs, locks and caps",
        f"\tFly = {{ Size = {v3(fly['size'])}, Centre = {v3(fly['centre'])}, "
        f"Triangles = {fly['tris']} }} :: Piece,",
        "\t-- both together, collapsed: what lies on a floor",
        f"\tBounds = {{ Size = {v3(base['bsize'])}, Centre = {v3(base['bcentre'])}, "
        f"Triangles = {base['tris'] + fly['tris']} }} :: Piece,",
        "\t-- the middle of the feet's pads, what stands on the floor when it's leaned",
        f"\tFeet = {v3(feet)},",
        "\t-- the middle of the fly's caps, collapsed: what rests on a wall when it's leaned",
        f"\tTop = {v3(top)},",
        "\t-- how far the fly slides out along the LookVector to full length (whole rungs)",
        f"\tTravel = {TRAVEL:.3f},",
        "\t-- studs between rungs, and the base's rungs from its feet (u, along the ladder)",
        f"\tPitch = {PITCH:.3f},",
        "\tRungs = { " + ", ".join(f"{u - SHOE['pad'][0]:.3f}" for u in BASE_RUNGS) + " },",
        "}",
        "",
    ]
    with open(path, "w") as f:
        f.write("\n".join(lines))
    print("SPEC", path)
