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
