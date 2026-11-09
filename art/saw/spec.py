"""Every number of the saw. Change them here only.

A cordless reciprocating saw that has cut its way through a lot of drywall: a green plastic body
scuffed pale, a black rubber boot over the gearbox where the other hand goes, a bare cast nose, a
blackened steel shoe, a demolition blade with its teeth worn bright, and a black battery pack
under the rear handle. It cuts a crawl hole into the next unit, keepers can't fit through, and
it's loud (GDD, the tools table; "The hole trap").

Drawn in a real saw's inches, then scaled by IN to studs: sized to a Roblox hand rather than to
life, as the cutters and the torch are (IN is about 1.3 times life), 2.9 studs from the blade's
tip to the tail, 1.1 tall standing on its battery. Green, because the torch is yellow and the
cutters red: three tools nobody mixes up at a glance, and green stays green in a unit's warm bulb.

The saw's frame in Blender: its length along Y with the blade's tip at -Y (its front), X across,
Z up (the body on top, the battery below), the origin the grip (the middle of the rear handle,
where the hand closes). The drawing's own numbers run from the shoe's face (y = 0, rearwards
positive) and the body's middle line (z = 0); GRIP moves them. The FBX turns this into Roblox's
frame (Y up, the blade towards the part's LookVector), and the game reads the numbers from
src/shared/Tools/Specs/Saw.luau, which the export stage writes.
"""

import os

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", ".."))

SET = "Saw"     # the texture set, and the MeshPart's name
TEX = 1024      # seen a couple of studs from your eye in first person: the finds' atlas size
DUST = 0.12     # a tool left on a unit's floor a while: dust on its top
SEED = 47.0

IN = 0.12       # studs to the drawing's inch
GRIP = (16.05, -2.05)   # (y, z): the middle of the rear handle, where the hand closes

# The blade: a 9-inch demolition blade, 6.6 inches of it out past the shoe. Its outline (y, z):
# the top edge straight back from the tip's slope, the teeth along the bottom.
BLADE = dict(tip=-6.6, back=1.2, top=0.3, bottom=-0.54, slope_from=-5.4, tip_top=-0.12,
             half=0.045)   # half its thickness, a little thicker than life so its edge reads
TEETH = dict(start=-6.45, end=-0.25, pitch=1 / 6, depth=0.1)   # 6 to the inch; they cut pulling

# Each body piece is lofted through cross-sections: (y, half width, half height, middle z),
# rounded squares (a superellipse's power: 2 is an ellipse, higher is squarer).
NOSE = [(0.15, 0.6, 0.6, -0.08), (0.32, 0.82, 0.84, -0.06), (1.15, 0.96, 1.0, -0.03),
        (1.95, 1.06, 1.1, 0.0)]                       # the gearbox's bare cast front
BOOT = [(1.85, 1.1, 1.16, 0.0), (2.15, 1.24, 1.3, 0.02), (3.9, 1.31, 1.43, 0.05),
        (5.6, 1.33, 1.49, 0.08), (6.25, 1.3, 1.5, 0.1)]   # rubber over the gearbox: the front grip
BODY = [(6.2, 1.38, 1.54, 0.1), (6.55, 1.46, 1.63, 0.12), (8.8, 1.49, 1.71, 0.16),
        (11.4, 1.46, 1.66, 0.14), (12.6, 1.34, 1.5, 0.16)]   # the motor's housing
TAIL = [(12.3, 1.22, 1.28, 0.24), (13.4, 0.98, 0.98, 0.42), (15.3, 0.82, 0.84, 0.54),
        (16.75, 0.79, 0.8, 0.5), (17.35, 0.66, 0.66, 0.42), (17.62, 0.36, 0.38, 0.36),
        (17.7, 0.12, 0.14, 0.35)]                     # the handle's top bar, its end rounded
ROUND = 3.2     # the body pieces' squareness
# The rear handle's grip and the D's front (the neck), each a path (y, z) from top to bottom
# with its half width (x) and half depth (across the path).
GRIP_PATH = [(16.62, 0.1), (16.36, -1.0), (16.05, -2.05), (15.75, -3.1), (15.55, -4.0)]
GRIP_HALF = (0.62, 0.76)
NECK_PATH = [(11.0, -0.9), (11.25, -2.4), (11.55, -4.0)]
NECK_HALF = (1.0, 0.72)
# The trigger, on the grip's front near its top: a path (y, z) and its half width and depth.
TRIGGER_PATH = [(15.42, -0.42), (15.05, -0.75), (14.96, -1.3), (15.1, -1.86)]
TRIGGER_HALF = (0.27, 0.24)
# The battery's mount under the handle (the foot) and the battery pack: rounded boxes
# (y from, y to, z from, z to, half width).
FOOT = (10.75, 17.05, -4.6, -3.7, 1.5)
BATTERY = (10.55, 16.9, -7.3, -4.55, 1.58)
BOX_ROUND = 5.0      # their squareness across
BUTTON = (10.38, 10.6, -5.08, -4.72, 0.55)   # the battery's release on its front (y, y, z, z, hw)
# The shoe: a stamped steel foot in front of the nose, the blade through its slot.
SHOE = dict(face=(-0.12, 0.0), half_width=1.0, z=(-1.5, 0.78), cheek_back=1.15,
            cheek_z=(-1.05, 0.35), cheek_t=0.1, bar=(0.0, 1.5, -1.12, -0.88, 0.34))
SHOE_BOLT = (0.62, -0.38)     # the shoe's pivot bolt through each cheek (y, z)
# The blade clamp's lever, on the side you see in your view (Blender's -x).
LEVER = dict(y=(0.55, 1.45), z=(-0.32, 0.12), out=0.1)

# Where the paint goes, in the drawing's inches.
VENTS = dict(y=(9.6, 12.0), z=(-0.75, 0.75), slots=6)   # the motor's cooling slots, both sides
LABEL = dict(y=(6.9, 8.9), z=(-0.55, 0.45))             # a worn warning sticker, your-view side
TEETH_BAND = 0.16       # how far up from the teeth the blade's ground steel shows


def to_roblox(v):
    """Blender's (x, y, z) to Roblox's: x = -x, y = z, z = y."""
    return (-v[0], v[2], v[1])


def at(y, z):
    """A drawing point (inches) in the saw's frame (studs from the grip), Blender's axes."""
    return ((y - GRIP[0]) * IN, (z - GRIP[1]) * IN)


def write_luau(path, body):
    """body: dict(size, centre, tris) in Roblox axes, from the grip."""

    def v3(v):
        return f"Vector3.new({v[0]:.3f}, {v[1]:.3f}, {v[2]:.3f})"

    def point(y, z):
        by, bz = at(y, z)
        return to_roblox((0.0, by, bz))

    tip = point(BLADE["tip"], (BLADE["top"] + BLADE["bottom"]) / 2)
    shoe = point(SHOE["face"][0], -0.3)
    lines = [
        "--!strict",
        "-- Generated by art/saw/build.py --stage export from art/saw/spec.py.",
        "-- Don't edit: change the spec and rebuild (scripts/art.sh saw).",
        "-- Studs, in the saw's own frame: the blade towards the LookVector (-Z), the body up (+Y),",
        "-- every point measured from the grip, where the hand closes round the rear handle.",
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
        "\t-- the blade's tip, where it bites first",
        f"\tBladeTip = {v3(tip)},",
        "\t-- the middle of the shoe's face, what rests against a wall as it cuts",
        f"\tShoe = {v3(shoe)},",
        "}",
        "",
    ]
    with open(path, "w") as f:
        f.write("\n".join(lines))
    print("SPEC", path)
