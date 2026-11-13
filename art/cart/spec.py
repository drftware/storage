"""Every number of the platform cart. Change them here only.

The front office's platform cart (GDD "The lobby", the cart ride; L-08e4): the kind every
self-storage office leaves by the door for moving day. A welded steel deck in worn safety-orange
powder coat with a ribbed black rubber mat, a U-shaped push handle at the back with a cross bar,
grey rubber corner bumpers at the front, and four 6-inch casters: the front pair swivel, the back
pair are fixed. Scuffed to bare steel where it knocks door frames, grimy underneath.

Drawn in studs at the building's scale (a stud is about a foot): a 2.2 by 4.3 deck, as the rack's
slots in the front office were sized for (art/lobby/spec.py, RACK_*: 3 studs apart, 4.7 deep), so
the whole cart, bumpers and all, is under 2.6 wide and parks nose-in between two hoops.

The cart's frame in Blender: its length along Y with its nose (the end away from the handle) at
-Y, the part's LookVector once in Roblox; X across; Z up. The origin is on the floor under the
deck's middle, so a cart parks by putting its pivot on a slot. Seven MeshParts in one texture set:
the body (deck, mat, handle, bumpers, the fixed casters' forks), the two front swivel forks
(CartForkL, CartForkR), each turning about its kingpin, and the four wheels (CartWheel*), each
spinning about its axle. The FBX turns this into Roblox's frame and the game reads the numbers from
src/shared/Cart/Specs.luau.
"""

import os

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", ".."))

SET = "Cart"          # the texture set, and the body's MeshPart name
TEX = 1024            # seen from a few studs and ridden on: the finds' atlas size
DUST = 0.03           # it's used every day: barely dusty
SEED = 71.0

# The deck: a welded frame of steel channel round a flat steel top, the mat inset on it.
DECK_W = 2.2          # across (X)
DECK_L = 4.3          # nose to back (Y)
DECK_TOP = 0.78       # the steel top's upper face above the floor: a step up, as a real cart's 9"
FRAME_H = 0.16        # the channel's height (the deck's edge you see)
FRAME_T = 0.035       # its steel's thickness
LIP = 0.02            # how far the frame's rim stands above the top, so the mat sits in a tray
MAT_IN = 0.09         # the mat's edge, in from the frame's outside
MAT_T = 0.025         # the mat's thickness, above the top
MAT_RIB = 0.07        # the mat's ribs, across the deck (in the paint)
CROSS = [-1.2, 0.0, 1.2]   # the cross members under the top (y), between the side channels

# The handle: a U of round tube up from two sockets at the back corners, a cross bar between its
# legs, its top bend at a grown-up's hip.
HANDLE_R = 0.055      # the tube's radius (2.5" tube reads at phone size; a real one is 1")
HANDLE_W = 1.9        # between the legs' middles
HANDLE_TOP = 3.15     # the top bar's middle above the floor
HANDLE_BEND = 0.22    # the corners' bend radius
HANDLE_Y = DECK_L / 2 - 0.12   # the legs' middles, in from the back edge
HANDLE_BAR = 1.95     # the cross bar's height above the floor
HANDLE_LEAN = 0.08    # how far the top leans back past the sockets (y)
SOCKET = dict(r=0.085, h=0.32)  # the welded sockets the legs drop into
GRIP = dict(w=1.1, r=0.072)     # the black foam grip over the top bar's middle

# The bumpers: grey rubber blocks on the front corners, and a strip across the nose.
BUMPER = dict(size=(0.16, 0.26, 0.14), z=0.6)
NOSE_STRIP = dict(w=1.5, h=0.09, t=0.05, z=0.66)

# The casters: a top plate bolted under the deck, a fork, an axle, a wheel. The front pair swivel
# about a kingpin through the plate's middle, the wheel trailing behind it; the back pair are
# fixed, their wheels rolling straight.
WHEEL_R = 0.25        # a 6" wheel
WHEEL_W = 0.15        # its tread's width
HUB_R = 0.13          # the grey hub the tread is moulded round
CASTER_X = 0.82       # the casters' middles, either side of the middle line
CASTER_Y = 1.75       # the casters' plates' middles, either side of the deck's middle (y)
PLATE = dict(w=0.42, l=0.42, t=0.025)   # the top plate, under the deck's frame
RACE = dict(r=0.15, h=0.06)             # the swivel's bearing race, under the plate
TRAIL = 0.11          # how far a swivel wheel's axle trails behind its kingpin
FORK_T = 0.025        # the fork's legs' thickness
FORK_GAP = 0.02       # between the wheel and the fork's legs

# Paint: worn safety orange on the steel.
ORANGE = "#D2601E"


def to_roblox(v):
    """Blender's (x, y, z) to Roblox's: x = -x, y = z, z = y."""
    return (-v[0], v[2], v[1])


def deck_under():
    """The underside of the deck's frame above the floor."""
    return DECK_TOP + LIP - FRAME_H


def casters():
    """Each caster: its name's ending, the plate's middle (x, y), whether it swivels."""
    out = []
    for name, y, swivel in (("F", -CASTER_Y, True), ("B", CASTER_Y, False)):
        # left and right as you push it from the handle, facing the nose (-Y): your left is +X
        for side, sx in (("L", CASTER_X), ("R", -CASTER_X)):
            out.append((name + side, sx, y, swivel))
    return out


def axle(sx, y, swivel):
    """A caster's axle middle (x, y, z): a swivel wheel trails behind its kingpin, towards the
    handle, as it does when the cart is pushed nose first."""
    return (sx, y + (TRAIL if swivel else 0.0), WHEEL_R)


def write_luau(path, rows):
    """rows: name -> dict(size, centre, tris) in Roblox axes, from the pivot (the floor under the
    deck's middle)."""

    def v3(v):
        return f"Vector3.new({v[0]:.3f}, {v[1]:.3f}, {v[2]:.3f})"

    lines = [
        "--!strict",
        "-- Generated by art/cart/build.py --stage export from art/cart/spec.py.",
        "-- Don't edit: change the spec and rebuild (scripts/art.sh cart).",
        "-- Studs, in the cart's own frame: its nose towards the LookVector (-Z), the handle at the",
        "-- back (+Z), up +Y, every point measured from the pivot, on the floor under the deck's",
        "-- middle. One body and six moving parts: the front pair of forks turn about their",
        "-- kingpins (Y), every wheel spins about its axle (X).",
        "",
        "export type Piece = {",
        "\tSize: Vector3, -- the piece's box",
        "\tCentre: Vector3, -- the box's middle, from the pivot",
        "\tTriangles: number,",
        "}",
        "",
        "export type Caster = {",
        "\tWheel: string, -- the wheel's MeshPart",
        "\tFork: string?, -- the swivel fork's MeshPart, for the front pair",
        "\tKingpin: Vector3, -- where a swivel fork turns, under its plate (the fixed: the same)",
        "\tAxle: Vector3, -- the wheel's middle, where it spins",
        "}",
        "",
        "return {",
        "\t-- every MeshPart's box",
        "\tParts = {",
    ]
    for name, r in rows.items():
        lines.append(f"\t\t{name} = {{ Size = {v3(r['size'])}, Centre = {v3(r['centre'])}, "
                     f"Triangles = {r['tris']} }} :: Piece,")
    lines += [
        "\t},",
        "\t-- the casters, front left, front right, back left, back right (as you push it)",
        "\tCasters = {",
    ]
    for name, sx, y, swivel in casters():
        king = to_roblox((sx, y, deck_under() - PLATE["t"]))
        ax = to_roblox(axle(sx, y, swivel))
        fork = f"\"CartFork{name[1]}\"" if swivel else "nil"
        lines.append(f"\t\t{{ Wheel = \"CartWheel{name}\", Fork = {fork}, Kingpin = {v3(king)}, "
                     f"Axle = {v3(ax)} }} :: Caster,")
    lines += [
        "\t},",
        "\t-- the deck's size (across, nose to back) and its mat's top above the floor: where a",
        "\t-- rider stands",
        f"\tDeck = Vector3.new({DECK_W:.3f}, {DECK_TOP + MAT_T:.3f}, {DECK_L:.3f}),",
        "\t-- the handle's top bar: its middle, from the pivot",
        f"\tHandle = {v3(to_roblox((0.0, HANDLE_Y + HANDLE_LEAN, HANDLE_TOP)))},",
        f"\tWheelRadius = {WHEEL_R:.3f},",
        "}",
        "",
    ]
    with open(path, "w") as f:
        f.write("\n".join(lines))
    print("SPEC", path)
