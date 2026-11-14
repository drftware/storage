"""Every number of the machine in the car, in studs. Change them here only.

The vending machine that rides in every floor's freight car (GDD "The ride"): from the second ride
on it wakes as the gate slams and sells tools and batteries for coins. A self-storage supply
machine, the kind real storage buildings sell padlocks and tape from: an oxblood enamel cabinet
chipped to primer and steel, one tall glass pane over three rows of bays (two battery bays, then
two rows of two tool bays), a steel rail under each row carrying a lit price window and a chunky
push button per bay (old cigarette machines' one-knob-a-column look), a lit sign at the top, and
below the glass a push flap over the bin with the coin plate beside it.

Its frame in Blender: X across (+X your right as you face it), Y from its front (-Y, facing the
gate) to its back, Z up. The origin is on the floor under the middle of its footprint. The FBX
turns this into Roblox's frame (Roblox X = -x, Y = z, Z = y), so the machine faces its LookVector;
src/shared/Machine/Specs.luau, which the export stage writes, carries every number the game needs
in that frame.

One texture set, Machine, at 1024: the cabinet, a coil, a button and the flap. The glass, the
tubes, the price windows and the sign come untextured, so the game lights them.
"""

import os

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", ".."))

SET = "Machine"
TEX = 1024
DUST = 0.25        # it rides in a car people sweep with their feet: a little on its top and sills
SEED = 83.0

# --- the cabinet ------------------------------------------------------------------------------
W, D, H = 4.6, 2.4, 6.6     # eyes are at 4.6: the top row of bays is at your eyes
FRONT = -D / 2              # the door's face
SHELL = 0.14                # the side walls' and the top's thickness
PLINTH = (0.3, 0.1)         # the black plinth's height, and how far it's set back from the door
DOOR = 0.18                 # the door's depth: the frame round the glass, the flap and the sign
BEVEL = 0.03                # the cabinet's outer edges

# The window in the door, and the three rows behind it, bottom up: (bottom, height). A row's
# steel rail fills its bottom RAIL; the bays' shelves sit level with the rail's top less SINK.
WINDOW = (-2.0, 2.0)        # its x range; the door's stiles either side of it
ROWS = ((1.85, 1.0), (2.85, 1.25), (4.1, 1.25))
WINDOW_TOP = 5.4
RAIL = 0.32                 # a rail's height
RAIL_Y = (-1.32, -1.08)     # its depth: from 0.12 proud of the door back to the glass
SINK = 0.06
GLASS_Y = -1.09             # the glass's face, set into the door
LINER = (-2.12, -1.02, 1.06, 1.72, 5.46)   # the white liner inside: x half, y front, y back, z
SHELF = (-0.5, 0.05, 0.06)  # a shelf's front edge (y), thickness, the lip turned up at its front
CHUTE = SHELF[0] - GLASS_Y  # the gap between the shelves and the glass, the drop to the bin

# The bays, in each row: (middle x, width). Two to a row; a divider down the middle.
BAYS = ((-1.0, 1.9), (1.0, 1.9))
DIVIDER = 0.05
MOTOR = (0.64, 0.24, 0.5)   # the motor box at the back of each bay: width, depth, height

# --- the coils (one MeshPart, cloned per bay so each can turn) --------------------------------
COIL_R = 0.26               # its radius to the wire's middle: a battery sits in its loops
COIL_WIRE = 0.022
COIL_TURNS = 4.5
COIL_Y = (-0.47, 0.8)       # its front end to where it meets the motor's hub
COIL_TAIL = 0.14            # the helix stops this short of the hub; its tail bends in to it
COIL_STEPS = 12             # points a turn
COIL_SEGS = 6               # round the wire

# --- the rails' fittings, per bay ----------------------------------------------------------
PRICE = (-0.34, 0.5, 0.2)   # the price window: its middle x off the bay's middle, width, height
PRICE_BEZEL = 0.05          # the black bezel round it
PRICE_Y = RAIL_Y[0] - 0.025  # the window's face, set into its bezel
BUTTON = (0.36, 0.125, 0.12)   # the button: its middle x off the bay's middle, radius, length
BUTTON_TRAVEL = 0.07        # how far it sinks when pressed
BUTTON_BEZEL = (0.17, 0.03)  # the black collar it sits in: radius, depth

# --- the bin and the coin plate, under the glass -------------------------------------------
FLAP = (-1.95, 0.6, 0.62, 1.4)   # the push flap's opening: x from, x to, z from, z to
FLAP_T = 0.04
BIN_BACK = -0.3             # the bin's back wall, behind the flap
PLATE = (0.9, 1.98, 0.48, 1.72)  # the coin plate: x, z
PLATE_T = 0.04
SLOT = (1.44, 1.42, 0.17)   # the coin slot's boss: x, z, radius (the slot is cut in it)
CUP = (1.44, 0.78, 0.46, 0.3)    # the return cup: middle x, z, width, height

# --- the sign and the tubes (untextured) -----------------------------------------------------
SIGN = (-1.98, 1.98, 5.56, 6.34)   # x, z: the lit panel under the cabinet's cap
SIGN_Y = (-1.12, -1.06)
TUBE_R = 0.045
TUBE_X = 1.9                # its half-length
TUBE_Y = -0.955             # just behind the glass at the top of each row, under the next rail
TUBE_DROP = 0.08            # its axis under the row's top

# --- where it stands in the car -------------------------------------------------------------
# In art/elevator/spec.py's frame: the car's back-right corner as you face it from the lobby,
# its back to the back wall's bumper boards (CAR_BACK 12 less 0.2), its right side 0.05 off the
# right wall's boards (CAR_W / 2 less 0.2).
IN_CAR = (6.05 - 0.05 - W / 2, 11.8 - 0.02 - D / 2, 0.0)

# Untextured parts' colours as imported (the game sets their materials and colours).
PLAIN = {
    "MachineGlass": (0.55, 0.62, 0.66),
    "MachineTubes": (0.82, 0.86, 0.88),
    "MachinePrices": (0.12, 0.02, 0.02),
    "MachineSign": (0.42, 0.4, 0.36),
}


def rows():
    """Each row: its bottom, top, the rail's top, the shelf's top."""
    out = []
    for z0, h in ROWS:
        out.append(dict(bottom=z0, top=z0 + h, rail=z0 + RAIL, shelf=z0 + RAIL - SINK))
    return out


def bays():
    """Every bay, bottom row first and left to right as you face it: row, middle x, width, the
    shelf's top, the row's top, the coil's axis height."""
    out = []
    for r, row in enumerate(rows()):
        for x, w in BAYS:
            out.append(dict(row=r, x=x, w=w, shelf=row["shelf"], top=row["top"],
                            rail=(row["bottom"] + row["rail"]) / 2,
                            coil=row["shelf"] + COIL_R + COIL_WIRE))
    return out


def to_roblox(v):
    """Blender's (x, y, z) to Roblox's: x = -x, y = z, z = y."""
    return (-v[0], v[2], v[1])


def lua_vec(v, nd=3):
    return "{ " + ", ".join(f"{c:.{nd}f}" for c in v) + " }"


def write_luau(path, parts):
    """parts: {name: dict(size=(x, y, z) Roblox, centre=(x, y, z) Blender, tris=n)}."""
    coil_mid = (COIL_Y[0] + COIL_Y[1]) / 2
    L = [
        "--!strict",
        "-- Generated by art/machine/build.py --stage export from art/machine/spec.py. Don't edit:",
        "-- change the spec and rebuild (scripts/art.sh machine).",
        "-- Studs, in the machine's own frame: the origin on the floor under the middle of its",
        "-- footprint, its front toward its LookVector (-Z), Y up.",
        "",
        "export type Vec = { number } -- x, y, z",
        "export type Bay = { Row: number, Middle: Vec, Width: number, Coil: Vec, Button: Vec,",
        "\tPrice: Vec }",
        "export type Part = { Size: Vec, Centre: Vec, Triangles: number }",
        "",
        "local Specs = {",
        f"\tSize = {lua_vec((W, H, D))},",
        "\t-- Where it stands in a floor's car, in the elevator's frame (Elevator.Specs).",
        f"\tInCar = {lua_vec(to_roblox(IN_CAR))},",
        "\t-- Each bay, bottom row first, left to right as you face the machine: its middle (on the",
        "\t-- shelf, halfway back), its width, its coil's middle (the coil turns about its own Z),",
        "\t-- its button's back (the button sinks +Z by `ButtonTravel`), its price window's face.",
        "\tBays = {",
    ]
    for b in bays():
        mid = to_roblox((b["x"], (SHELF[0] + LINER[2]) / 2, b["shelf"]))
        coil = to_roblox((b["x"], coil_mid, b["coil"]))
        button = to_roblox((b["x"] + BUTTON[0], RAIL_Y[0] - BUTTON_BEZEL[1], b["rail"]))
        price = to_roblox((b["x"] + PRICE[0], PRICE_Y, b["rail"]))
        L.append(f"\t\t{{ Row = {b['row'] + 1}, Middle = {lua_vec(mid)}, Width = {b['w']}, "
                 f"Coil = {lua_vec(coil)},")
        L.append(f"\t\t\tButton = {lua_vec(button)}, Price = {lua_vec(price)} }},")
    fx0, fx1, fz0, fz1 = FLAP
    sx0, sx1, sz0, sz1 = SIGN
    L += [
        "\t} :: { Bay },",
        "\t-- The coil's helix: where its wire starts, at the bottom of the loop, from the coil's",
        "\t-- middle along Z (toward the glass), and how far it runs a turn. The wire is at the bottom",
        "\t-- of its loop every `CoilPitch` back from there: what stands in the coil rests on it.",
        f"\tCoilFront = {COIL_Y[0] - coil_mid:.3f},",
        f"\tCoilPitch = {(COIL_Y[1] - COIL_TAIL - COIL_Y[0]) / COIL_TURNS:.4f},",
        f"\tButtonTravel = {BUTTON_TRAVEL},",
        f"\tPriceSize = {{ {PRICE[1]}, {PRICE[2]} }}, -- a price window's width and height",
        "\t-- The flap's hinge (its top edge's middle): it swings in, about its X.",
        f"\tFlapHinge = {lua_vec(to_roblox(((fx0 + fx1) / 2, GLASS_Y - 0.01, fz1)))},",
        f"\tFlapSize = {{ {fx1 - fx0:.3f}, {fz1 - fz0:.3f} }},",
        "\t-- The coin slot's boss, on the plate, and the return cup's middle.",
        f"\tSlot = {lua_vec(to_roblox((SLOT[0], FRONT - PLATE_T - 0.05, SLOT[1])))},",
        f"\tCup = {lua_vec(to_roblox((CUP[0], FRONT - PLATE_T, CUP[1])))},",
        "\t-- The sign's lit face (its middle) and its size: the emblem's SurfaceGui goes on it.",
        f"\tSign = {{ Centre = {lua_vec(to_roblox(((sx0 + sx1) / 2, SIGN_Y[0], (sz0 + sz1) / 2)))}, "
        f"Size = {{ {sx1 - sx0:.3f}, {sz1 - sz0:.3f} }} }},",
        "\t-- The glass's face, its middle and size: the light that spills into the car leaves it.",
        f"\tGlass = {{ Centre = {lua_vec(to_roblox((0.0, GLASS_Y, (ROWS[0][0] + WINDOW_TOP) / 2)))}, "
        f"Size = {{ {WINDOW[1] - WINDOW[0]:.3f}, {WINDOW_TOP - ROWS[0][0]:.3f} }} }},",
        "\t-- Each row's tube, bottom row first (its axis's middle; it runs along X), its radius and",
        "\t-- length: the game draws each as its own cylinder, so the rows catch one at a time.",
        "\tTubes = { " + ", ".join(lua_vec(to_roblox((0.0, TUBE_Y, r["top"] - TUBE_DROP))) for r in rows()) + " },",
        f"\tTubeRadius = {TUBE_R},",
        f"\tTubeLength = {2 * TUBE_X},",
        "\t-- Each MeshPart's box as imported (its centre is its CFrame). The cabinet, glass, tubes,",
        "\t-- prices and sign are built in the machine's frame; the coil, the button and the flap",
        "\t-- each on its own origin (the coil's axis at its middle, the button's back, the hinge).",
        "\tParts = {",
    ]
    for name, p in parts.items():
        L.append(f"\t\t{name} = {{ Size = {lua_vec(p['size'])}, "
                 f"Centre = {lua_vec(to_roblox(p['centre']))}, Triangles = {p['tris']} }},")
    L += ["\t} :: { [string]: Part },", "}", "", "return Specs", ""]
    with open(path, "w") as f:
        f.write("\n".join(L))
    print("SPEC", path)
