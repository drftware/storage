"""Every number of the bedroom set's finds, in studs. Change them here only.

A find's frame in Blender: X across its front (left to right as you face it), Y away from you
(its front faces -Y), Z up, the origin the middle of its bottom, on the floor. The FBX turns this
into Roblox's frame (Y up, the -Y side the part's front, so its LookVector is where it faces: a
mimic's tell is that it faces you), and the game reads the sizes from
src/shared/Finds/Specs.luau, which the export stage writes.

Sizes are the real things at 10 inches a stud, the boxes' scale (art/boxes/spec.py): a big 1980s
boombox is 24 inches long, a 13-inch portable TV about 15 wide, a sitting teddy 16 tall.
"""

import os

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", ".."))

SET = "Bedroom"     # the texture set every bedroom find shares, and the set's name in the game
TEX = 1024          # one atlas for the whole set
DUST = 0.75         # how thick the dust lies on whatever faces up; a mimic has none (GDD)

# The boombox: black plastic case, brushed-aluminium front, two big speakers, a tape in the deck.
BOOMBOX = dict(
    w=2.3, d=0.66, h=1.08, feet=0.04,  # the case, standing on four rubber feet
    bevel=0.06,
    speaker_x=0.7, speaker_z=0.5, speaker_r=0.36, speaker_depth=0.07,  # from the case's bottom
    ring=0.035,                         # the chrome ring round each speaker
    deck=(0.56, 0.4, 0.3),              # the cassette door: width, height, its bottom's height
    dial=(0.78, 0.13, 0.77),            # the tuner's window: width, height, its bottom's height
    keys=6, key=(0.075, 0.13, 0.05),    # the piano keys along the top's front edge
    handle_x=0.72, handle_rise=0.24, handle_r=0.034,
    antenna=(1.5, 0.017),               # the telescopic aerial lying along the back: length, radius
    seed=11.0,
)

# The portable TV: a woodgrain cabinet, a bulging grey-green screen, two dials, rabbit ears.
TELEVISION = dict(
    w=1.5, d=1.12, h=1.24, feet=0.04, bevel=0.05,
    back=(1.1, 0.32, 0.9),              # the tube's housing behind: width, depth, height
    screen=(-0.09, 0.71, 0.86, 0.66),   # centre across, centre up from the floor, width, height
    bulge=0.035,                        # how far the glass bows out
    knob_x=0.53, knobs=(0.97, 0.74), knob_r=0.085,  # heights from the floor
    ears=(1.35, 0.016, 28.0, 14.0),     # the rods: length, radius, splay from upright, lean back
    seed=12.0,
)

# The teddy: cream plush gone grey with handling, a mended belly, one eye replaced by a button.
# Each piece an ellipsoid: centre, radii, turn (degrees about X then Y), segments round and up.
TEDDY = dict(
    parts=[
        ("body", (0.0, 0.06, 0.43), (0.35, 0.31, 0.41), (0, 0), 14, 9),
        ("head", (0.0, -0.01, 1.1), (0.32, 0.29, 0.29), (0, 0), 16, 10),
        ("muzzle", (0.0, -0.25, 1.03), (0.14, 0.11, 0.1), (0, 0), 10, 6),
        ("nose", (0.0, -0.35, 1.07), (0.055, 0.03, 0.037), (0, 0), 8, 5),
        ("ear", (-0.23, 0.0, 1.35), (0.11, 0.05, 0.1), (0, -18), 9, 5),
        ("ear", (0.23, 0.0, 1.35), (0.11, 0.05, 0.1), (0, 18), 9, 5),
        ("arm", (-0.37, -0.08, 0.6), (0.11, 0.11, 0.25), (-28, 24), 10, 7),
        ("arm", (0.37, -0.08, 0.6), (0.11, 0.11, 0.25), (-28, -24), 10, 7),
        ("leg", (-0.19, -0.26, 0.14), (0.135, 0.27, 0.135), (-8, 0), 10, 7),
        ("leg", (0.19, -0.26, 0.14), (0.135, 0.27, 0.135), (-8, 0), 10, 7),
        ("pad", (-0.19, -0.515, 0.175), (0.1, 0.03, 0.1), (-8, 0), 8, 4),
        ("pad", (0.19, -0.515, 0.175), (0.1, 0.03, 0.1), (-8, 0), 8, 4),
        ("eye", (-0.105, -0.262, 1.19), (0.032, 0.022, 0.032), (0, 0), 8, 5),
        ("bow", (-0.08, -0.17, 0.83), (0.085, 0.035, 0.055), (0, 20), 6, 4),
        ("bow", (0.08, -0.17, 0.83), (0.085, 0.035, 0.055), (0, -20), 6, 4),
        ("knot", (0.0, -0.19, 0.83), (0.035, 0.03, 0.035), (0, 0), 8, 4),
    ],
    button=((0.105, -0.272, 1.19), 0.036, 0.016),  # the other eye: centre, radius, thickness
    patch=(0.0, 0.53, 0.2, 0.18),                  # the belly's mend: across, up, width, height
    seed=13.0,
)

# The roller skates: a pair of white high-tops with pink wheels, one standing, one on its side.
# One skate is built along its own X, toe at +X; the boot is lofted through these stations:
# (x, half-width, top of the boot) from heel to toe.
SKATE = dict(
    stations=[(-0.5, 0.125, 0.92), (-0.47, 0.14, 0.95), (-0.38, 0.15, 0.95), (-0.24, 0.15, 0.93),
              (-0.1, 0.152, 0.86), (0.02, 0.158, 0.7), (0.14, 0.165, 0.58), (0.26, 0.165, 0.5),
              (0.38, 0.155, 0.44), (0.46, 0.13, 0.4), (0.51, 0.09, 0.36), (0.535, 0.04, 0.33)],
    boot_bottom=0.26, round=10,         # the boot sits on its sole; points round each station
    sole=0.05, heel=(-0.49, -0.26, 0.09),
    wheel_x=0.3, wheel_y=0.16, wheel_r=0.1, wheel_w=0.085,
    toe_stop=(0.5, 0.06, 0.13),         # where it sits along X, its radius, its length
    # the pair: (at, turn, roll about its own length). One stands behind in profile; the other
    # lies in front with its row of wheels to the door, the skates' tell from a doorway.
    pair=[((-0.2, 0.72, 0.0), 172.0, 0.0), ((0.3, -0.45, 0.0), 8.0, -90.0)],
    seed=14.0,
)

ORDER = ["Boombox", "Television", "Teddy", "Skates"]
COLLISION = {"Boombox": "Box", "Television": "Box", "Teddy": "Hull", "Skates": "Hull"}


def write_luau(path, rows):
    """rows: {name: dict(size=(x, y, z) in Roblox axes, tris=n)}."""
    lines = [
        "--!strict",
        "-- Generated by art/finds/build.py --stage export from art/finds/spec.py. Don't edit:",
        "-- change the spec and rebuild (scripts/art.sh finds).",
        "-- Studs, the real things at 10 inches a stud (the boxes' scale). A find's pivot is the",
        "-- middle of its bottom, on the floor, and its front faces the part's LookVector.",
        "",
        "export type Find = {",
        "\tSize: Vector3, -- X across its front, Y up, Z front to back",
        "\tTriangles: number,",
        "\tSet: string, -- the set it belongs to, and the texture set it wears",
        "\tHull: boolean, -- collides as its hull rather than its box",
        "}",
        "",
        "local Finds: { [string]: Find } = {",
    ]
    for name in ORDER:
        r = rows[name]
        x, y, z = r["size"]
        lines.append(f"\t{name} = {{ Size = Vector3.new({x:.2f}, {y:.2f}, {z:.2f}), "
                     f"Triangles = {r['tris']}, Set = \"{SET}\", "
                     f"Hull = {'true' if COLLISION[name] == 'Hull' else 'false'} }},")
    lines += ["}", "", "return {", "\tFinds = Finds,", "}", ""]
    with open(path, "w") as f:
        f.write("\n".join(lines))
    print("SPEC", path)
