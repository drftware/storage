"""Every number of the breaker box, in studs. Change them here only.

The box that holds a floor's power (GDD "The breaker"): when it's thrown every hall light dies with
one heavy clunk, and someone has to find it on a hall wall and hold its lever back up. As in
Phasmophobia, where the team goes to the fuse box and switches it back on. A heavy-duty safety
switch, the grey steel kind every building's back hall has: a deep enamel box on a plywood board,
its door hung on two hinges, a pilot lamp in the door's top, a yellow lightning-bolt sticker, a
conduit climbing from its top to the wall's cap, and the big lever on its right side, a steel arm
with a safety-red grip that swings up for on and down for off. Sized to be found, not to life:
about one and a half times a real one, so from across a hall on a phone the box reads and the
lever's red grip reads high or low.

Its frame in Blender: X across (+X your right as you face it), Y from its front (-Y, into the
hall) to the wall (+Y), Z up. The origin is on the floor, on the wall's face, under the middle of
the board. The FBX turns this into Roblox's frame (Roblox X = -x, Y = z, Z = y), so the box faces
its LookVector; src/shared/Breaker/Specs.luau, which the export stage writes, carries every number
the game needs in that frame.

One texture set, Breaker, at 1024: the board, the box, the conduit and the lever. The lamp's lens
comes untextured, so the game lights it.
"""

import math
import os

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", ".."))

SET = "Breaker"
TEX = 1024
DUST = 0.3          # a back-hall box nobody wipes: dust on its top and the hinges
SEED = 47.0

# --- the board it's screwed to ----------------------------------------------------------------
BOARD = (-1.5, 1.5, 2.6, 6.3)   # x from, x to, z from, z to: a plywood backboard on the wall
BOARD_T = 0.08

# --- the box ----------------------------------------------------------------------------------
W, H, D = 2.0, 2.8, 0.8     # the enclosure: across, tall, deep (from the board)
MID_Z = 4.45                # its middle: a little under your eyes (4.6), so you look at its door
BACK = -BOARD_T             # the box's back, on the board
FRONT = BACK - D            # the box's front edge, where the door closes on it
BEVEL = 0.035               # the box's formed edges

DOOR_T = 0.06               # the door's pan, standing proud of the box's front
DOOR_GAP = 0.025            # the dark line round it
DOOR_PANEL = (0.16, 0.012)  # a raised panel pressed into the door: its inset from the edge, height
HINGES = (0.55, -0.55)      # the hinges' middles off the box's middle, on its left edge
HINGE = (0.045, 0.42)       # a hinge's knuckle: radius, length
SCREWS = (0.85, -0.85)      # the door's two slotted screws, on its right edge, off the middle

LAMP = (0.0, 0.95, 0.13, 0.07)  # the pilot lamp: x, z off the middle, the lens's radius, its bulge
LAMP_BEZEL = (0.2, 0.05)        # the chrome ring round it: radius, how far it stands off the door
STICKER = (0.0, -0.25, 0.92)    # the lightning-bolt sticker: x, z off the middle, the side's length

# --- the conduit: from the box's top up to the wall's cap, where it turns into the wall --------
CONDUIT_X = -0.45
CONDUIT_Y = BACK - 0.22
CONDUIT_R = 0.11
CONDUIT_TOP = 9.15          # the elbow's foot: the wall's cap is at 9.88 (art/corridor WALL_H 10)
ELBOW = (0.34, 0.5)         # the elbow's box: across and deep, its height
STRAPS = (6.9, 8.4)         # a one-hole strap holding it to the wall at each of these heights

# --- the lever, on the box's right side --------------------------------------------------------
HUB = (D * 0.42, 0.75)      # the pivot: how far forward of the box's back, how high off its middle
HUB_BOSS = (0.27, 0.05)     # the box's round boss under the lever: radius, how far it stands out
HUB_R = 0.2                 # the lever's own hub
ARM = (0.08, 0.16, 0.86)    # the arm's flat bar: thick (along X), wide, how far its grip starts
GRIP = (0.13, 0.62)         # the grip: radius, length, carrying on from the arm's end
UP, DOWN = 42.0, -42.0      # its angles above level, pointing at the hall: on is up, off is down

PLAIN = {"BreakerLamp": (0.36, 0.38, 0.34)}  # as imported; the game lights it


def box_lo_hi():
    return ((-W / 2, FRONT, MID_Z - H / 2), (W / 2, BACK, MID_Z + H / 2))


def door_face():
    """The door's front face (y)."""
    return FRONT - DOOR_T


def pivot():
    """The lever's pivot, in the box's frame: on the hub's axis, just out from the boss."""
    return (W / 2 + HUB_BOSS[1] + 0.045, BACK - HUB[0], MID_Z + HUB[1])


def grip_middle(angle):
    """The grip's middle at an angle above level, in the box's frame."""
    px, py, pz = pivot()
    reach = ARM[2] + GRIP[1] / 2
    a = math.radians(angle)
    return (px + ARM[0] / 2, py - reach * math.cos(a), pz + reach * math.sin(a))


def to_roblox(v):
    """Blender's (x, y, z) to Roblox's: x = -x, y = z, z = y."""
    return (-v[0], v[2], v[1])


def lua_vec(v, nd=3):
    return "{ " + ", ".join(f"{c:.{nd}f}" for c in v) + " }"


def write_luau(path, parts):
    """parts: {name: dict(size=(x, y, z) Roblox, centre=(x, y, z) Blender, tris=n)}."""
    lx, lz, lr, _ = LAMP
    L = [
        "--!strict",
        "-- Generated by art/breaker/build.py --stage export from art/breaker/spec.py. Don't edit:",
        "-- change the spec and rebuild (scripts/art.sh breaker).",
        "-- Studs, in the breaker's own frame: the origin on the floor, on the wall's face, under",
        "-- the middle of its board; its front toward its LookVector (-Z), Y up. Its back is flat",
        "-- on the wall: place the origin on a wall's face line, facing the hall.",
        "",
        "export type Vec = { number } -- x, y, z",
        "export type Part = { Size: Vec, Centre: Vec, Triangles: number }",
        "",
        "local Specs = {",
        f"\tBoxSize = {lua_vec((W, H, D + DOOR_T))}, -- the box with its door, off the board",
        f"\tBoxCentre = {lua_vec(to_roblox((0.0, (BACK + door_face()) / 2, MID_Z)))},",
        "\t-- The lever's pivot and its turn: the lever (BreakerLever) is built level, pointing at",
        "\t-- the hall, its pivot its origin. Turn it about its own X: CFrame.Angles(math.rad(a), 0, 0)",
        "\t-- raises its grip for a above 0. Up is on, down is off.",
        f"\tPivot = {lua_vec(to_roblox(pivot()))},",
        f"\tUp = {UP},",
        f"\tDown = {DOWN},",
        "\t-- The grip's middle with the lever up and down: where a hand goes, where a prompt sits.",
        f"\tGripUp = {lua_vec(to_roblox(grip_middle(UP)))},",
        f"\tGripDown = {lua_vec(to_roblox(grip_middle(DOWN)))},",
        f"\tGripRadius = {GRIP[0]},",
        "\t-- The pilot lamp's lens (BreakerLamp): its middle on the door and its radius. The game",
        "\t-- lights it: on with the power, its colour saying which.",
        f"\tLamp = {lua_vec(to_roblox((lx, door_face() - LAMP_BEZEL[1], MID_Z + lz)))},",
        f"\tLampRadius = {lr},",
        "\t-- Each MeshPart's box as imported (its centre is its CFrame). The box and the lamp are",
        "\t-- built in the breaker's frame; the lever on its pivot.",
        "\tParts = {",
    ]
    for name, p in parts.items():
        L.append(f"\t\t{name} = {{ Size = {lua_vec(p['size'])}, "
                 f"Centre = {lua_vec(to_roblox(p['centre']))}, Triangles = {p['tris']} }},")
    L += ["\t} :: { [string]: Part },", "}", "", "return Specs", ""]
    with open(path, "w") as f:
        f.write("\n".join(L))
    print("SPEC", path)
