"""Every number of the Lights set, in studs (10 inches a stud, the boxes' scale). Change them here.

A find's frame in Blender: X across its front, Y away from you (its front faces -Y), Z up, the
origin the find's pivot (for the desk lamp, the middle of its base, on the floor).
"""

import math

# --- The desk lamp: a spring-balanced desk lamp of the 1960s-70s -------------------------------
# References (README): a 7-8 inch round cast base, two arm sections of about 12 inches each, a
# 6 inch bell shade with a push switch on top, closed-coil springs on the lower arm.
DESK_LAMP = dict(
    # the base: a two-step round cast-iron foot (profile radii and heights), with a felt underside
    base_r=0.36, base_h=0.078, step_r=0.262, step_h=0.14, boss_r=0.13, boss_top=0.19,
    turret=(0.05, 0.19, 0.235),          # the swivel under the yoke: radius, bottom, top
    shoulder=(0.0, 0.0, 0.275),          # the lower arm's hinge
    yoke=(0.068, 0.012, 0.085, 0.2, 0.31),  # cheek plates: x offset, thickness, depth, z0, z1
    # the arms at rest, as it's found: the lower leaning back, the upper reaching forward
    lower_len=1.2, lower_tilt=16.0,      # degrees back from upright
    upper_len=1.15, upper_drop=12.0,     # degrees below level, reaching forward
    bars=(0.05, 0.014, 0.034),           # the lower arm's flat bars: x offset, thickness, depth
    rods=(0.03, 0.011),                  # the upper arm's round rods: x offset, radius
    hub_r=0.03,                          # the elbow's hub
    springs=dict(x=0.025, back=0.032, r=0.021, wire=0.0045, s0=0.07, s1=0.43),
    # the shade: its own axis Z, opening down; tilted forward from straight down
    shade_tilt=25.0,
    shade=dict(rim=0.30, length=0.6, neck=0.088),
    wrist_on_shade=(0.0, 0.14, -0.05),   # where the wrist hinge sits in the shade's own frame
    bulb=dict(r=0.118, tip=-0.46, base_top=-0.13, base_r=0.053),
    switch=dict(collar=0.035, r=0.022, h=0.03),
    cord_r=0.011,
    plug=(0.42, 1.05),                   # where the plug lies on the floor
    seed=21.0,
    dust=0.55,
    # its light: a 60 W pearl bulb (2,700 K) in a bell shade
    kelvin=2700,
)


def rot_x(deg, v):
    a = math.radians(deg)
    x, y, z = v
    return (x, y * math.cos(a) - z * math.sin(a), y * math.sin(a) + z * math.cos(a))


def lamp_joints(d=DESK_LAMP):
    """The shoulder, elbow and wrist at rest, and the shade's placing (tilt, origin)."""
    S = d["shoulder"]
    t = math.radians(d["lower_tilt"])
    E = (S[0], S[1] + d["lower_len"] * math.sin(t), S[2] + d["lower_len"] * math.cos(t))
    u = math.radians(d["upper_drop"])
    W = (E[0], E[1] - d["upper_len"] * math.cos(u), E[2] - d["upper_len"] * math.sin(u))
    # the shade's own frame: turned -tilt about X (opening down and forward), its wrist point on W
    off = rot_x(-d["shade_tilt"], d["wrist_on_shade"])
    origin = (W[0] - off[0], W[1] - off[1], W[2] - off[2])
    return S, E, W, origin


def on_shade(v, d=DESK_LAMP):
    """A point in the shade's own frame, in the find's frame."""
    _, _, _, o = lamp_joints(d)
    p = rot_x(-d["shade_tilt"], v)
    return (o[0] + p[0], o[1] + p[1], o[2] + p[2])


# --- The plug-in night-light: a C7 night-light with a frosted ribbed shade -------------------
# References (README): about 4.6 inches tall, a shade about 1.75 inches across at its widest over
# a narrow white base with a slide switch on its front and two plug blades out of its back.
# Its frame: X across, the wall plate's back face at Y = 0 (the find reaches forward to -Y), Z up
# from the bottom of the base. The origin is the middle of the base's back edge on the floor.
NIGHT_LIGHT = dict(
    # the base: a white plastic block, the slide switch on its front
    base=dict(w=0.1, d=0.095, h=0.112, round=0.012),
    slot=dict(w=0.016, z0=0.03, z1=0.088),       # the switch's slot in the base's front
    tab=dict(w=0.017, h=0.017, out=0.011, z=0.034),
    travel=0.031,                                # how far the tab slides up to switch on
    # the plug: two blades out of the back, a real US plug's spacing (half an inch apart)
    blades=dict(x=0.025, z=0.056, len=0.0625, thick=0.0065, narrow=0.025, wide=0.031),
    # the shade: rings up from the base (z, width, depth from the wall), a dome on top
    shade=[(0.104, 0.124, 0.094), (0.11, 0.136, 0.104), (0.2, 0.152, 0.113), (0.3, 0.168, 0.121),
           (0.37, 0.175, 0.125), (0.4, 0.176, 0.126)],
    dome=0.06,                                   # how far the top rounds over above the last ring
    squareness=2.6,                              # the shade's section: 2 a half oval, higher boxier
    ribs=dict(z0=0.114, z1=0.396, pitch=0.0141, depth=0.0026),
    bulb=(0.0, -0.062, 0.25),                    # the C7 bulb's middle, inside the shade
    # the numbers above are a 4.6 inch night-light; it's built 1.15 times that, 5.3 inches, the
    # size of the bigger plug-in shades (5 to 5.75 inches in listings), so it reads from a doorway
    scale=1.15,
    seed=33.0,
    dust=0.5,
    # its light: a 4 W candelabra bulb, about 2,600 K, glowing through frosted plastic
    kelvin=2600,
)


# --- The tea light in a jar: a jam-jar lantern -------------------------------------------------
# References (README): a pint screw-top jar (about 5 inches tall, 3 across, a 70 mm regular-mouth
# thread) with a wire wrapped twice under its thread, an ear each side, and a wire bail hooked
# through the ears; a tea light (38 mm across, 16 mm deep, in a pressed aluminium cup) on its
# floor, burned about half down. Its frame: the jar's bottom middle on the floor, its front to -Y.
TEA_JAR = dict(
    # the jar's outside, bottom to top (radius, height): a raised middle under a resting ring,
    # the straight body, the shoulder, a bead the wire sits on, the threaded neck to the rim
    outside=[(0.0, 0.006), (0.118, 0.002), (0.133, 0.0), (0.143, 0.004), (0.149, 0.013),
             (0.15, 0.03), (0.151, 0.2), (0.15, 0.37), (0.147, 0.392), (0.139, 0.408),
             (0.131, 0.418), (0.1345, 0.424), (0.1345, 0.43), (0.132, 0.433), (0.132, 0.492),
             (0.13, 0.4985)],
    # and its inside, from the rim down to the floor: walls 3 mm, the base 7 mm thick
    inside=[(0.1175, 0.4985), (0.117, 0.48), (0.1175, 0.435), (0.121, 0.424), (0.127, 0.413),
            (0.135, 0.398), (0.1393, 0.372), (0.1395, 0.05), (0.137, 0.036), (0.128, 0.03),
            (0.0, 0.029)],
    thread=dict(z0=0.449, z1=0.486, turns=1.6, r=0.0026, out=0.1335),  # the screw thread
    seed=47.0,
    dust=0.42,
)
TEA_LIGHT = dict(
    at=(0.022, -0.016, 0.029),     # where it stands on the jar's floor (slid a little off middle)
    r=0.0748, h=0.063,             # the cup: 38 mm across, 16 mm deep
    wax=0.036,                     # burned about half down: the wax's top in the cup
    pool=0.042,                    # the old melt pool round the wick, set glossy
    wick=dict(r=0.0032, up=0.024, lean=12.0),  # its wick standing out of the wax, leaning
    flame=dict(h=0.088, r=0.0145, at=0.005),   # 22 mm tall, 7 mm across, its foot above the wax
    kelvin=1850,                   # a candle flame
)
TEA_WIRE = dict(
    r=0.0055,                      # heavy galvanised wire, a touch bolder than life (2.8 mm)
    z=0.4385,                      # the wrap's height: on the neck's bead, under the thread
    neck=0.132,
    eye=dict(x0=0.1465, r=0.013, turns=1.5),  # each ear: an eye coiled round the bail's hook
    bail=dict(inner=0.145, x=0.176, bend=0.008, arms=0.13),  # hook end, arms' x, the arms
    bail_rest=-150.0,              # degrees it's fallen back from upright, its top on the jar
)


# --- The bundle of glow sticks: three 6 inch lightsticks held with a rubber band ---------------
# References (README): a 6 inch lightstick is 150 to 152 mm long and 15 mm across; a plug cap
# a touch wider than the tube closes the bottom; the top is sealed into a flat tab with a hole
# and an open moulded hook beyond it; a thin glass ampoule rides loose inside. Its frame: the
# bundle's middle on the floor, the sticks along X with their hooks to +X, its front to -Y.
GLOW_STICK = dict(
    length=0.6,                    # 152 mm, cap to hook
    r=0.0295,                      # the tube: 15 mm across
    cap=dict(r=0.0315, h=0.055, round=0.004),  # the plug cap at the bottom: 16 mm across, 14 long
    shoulder=0.515,                # where the tube starts closing to its seal
    seal=0.535,                    # the seal's end on the axis
    # the flat tab the seal ends in: the hole's centre, its radius, the tab's half width, the
    # tab's start and end along the stick, its thickness
    tab=dict(hole=0.551, hole_r=0.0078, w=0.0165, z0=0.524, z1=0.567, t=0.0076),
    # the open hook past it: its centre, outer and inner radius, thickness, and where the C
    # starts and ends (degrees round its centre from the stick's side; the gap faces the tab)
    hook=dict(at=0.58, R=0.0195, r=0.0112, t=0.0066, a0=-125.0, a1=160.0),
    # the glass ampoule: where it starts and ends, its radius, and how far below the tube's
    # middle it lies (it sinks; kept inside the bake's reach of the tube wall)
    vial=dict(z0=0.09, z1=0.49, r=0.0095, drop=0.01),
    bend=0.3,                      # where it's bent to crack it: its middle
    crack=34.0,                    # degrees it bends before the ampoule snaps
)
GLOW_BUNDLE = dict(
    # the three sticks (the top one, the front one, the back one): slid along and rolled about
    # their own axes (degrees) so the hooks don't line up, as a bundle snapped together does
    sticks=[dict(slide=0.0, roll=-20.0), dict(slide=-0.022, roll=35.0),
            dict(slide=0.014, roll=-70.0)],
    band=dict(at=0.17, w=0.016, t=0.0045),  # the rubber band: along the sticks, width, thickness
    seed=53.0,
    dust=0.38,
    rgb=(120, 255, 96),            # a green lightstick's glow (about 520 nm)
)


# --- The string fairy lights: copper-wire micro LEDs coiled loose, on a 3 x AA box -------------
# References (README): twenty micro LEDs (resin drops on the wire) 10 cm apart on thin copper
# wire, with a lead to a translucent 3 x AA box (about 68 x 50 x 21 mm) that has a slide switch
# on top at its cable end and the batteries showing through. Found wound into a loose ring. Its
# frame: the middle of the whole thing on the floor, its front to -Y. A box's own frame: X along
# it, its cable end to -X.
FAIRY = dict(
    # the coil: its centre, radius, how squashed across, loops, the angle the far end starts at,
    # and how far the loops wander in and out
    coil=dict(at=(-0.17, 0.03), R=0.29, oval=0.88, loops=4.5, start=-160.0, wander=0.16),
    wire=dict(r=0.0022, step=0.04),   # the copper wire (1.1 mm, twice life so it reads), path step
    # the LEDs: resin drops along the wire (bolder than life: 5.5 mm by 3 mm), every 10 cm from
    # the far end
    bead=dict(len=0.022, r=0.0062, every=0.4, first=0.06),
    box=dict(at=(0.335, -0.06), yaw=-18.0, l=0.275, w=0.191, h=0.08, round=0.008),
    batt=dict(r=0.0285, l=0.199, nub=(0.0105, 0.0055), y=(-0.0575, 0.0, 0.0575), z=0.0345),
    lid=-0.075,                        # where the battery lid starts along the box
    # the slide switch on top: its middle off (x, y), its knob (length, width, height above the
    # lid), and how far it slides on, towards the cable end
    switch=dict(at=(-0.103, 0.045), knob=(0.022, 0.02, 0.009), travel=0.014),
    exit=(-0.04, 0.04),                # where the wire leaves the cable end (y, z)
    kelvin=2900,                       # warm white LEDs
    seed=59.0,
    dust=0.45,
)
