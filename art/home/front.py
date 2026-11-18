"""The home front (S5-03a2b2, D-266): the climb's M door rig set in a home's doorway.

The door still rolls on the M's own guides, drum and curtain (art/unit/parts.py, the M's numbers),
but the steel round it is gone: the room's plaster wall runs across the front with its oak
baseboard and rail, an oak casing frames the doorway on plinth blocks under a little cornice, the
reveal is lined in oak back to the guides, and inside by the door a light switch waits. The door
itself wears HomeDoor, the DoorKit's layout kept new (looks.py), painted a warm colour. Built in
the unit kit's frame (home_spec.py).

A Small home's doorway is the S door's 6 wide, in the same wall (S5-03h5b, D-355): the doorway's
two sides, built where the M's stand, slide in a stud each and a strip of the wall's plaster
comes in with them, the head drawn narrower; the M's curtain still rolls behind them. Every piece
that moves is its own part, built at the M's place, so the game slides them (and h6 grinds them
back out as the home grows). Built so nothing fights at either place: what slides in from the
wall sits a hair inside the wall's faces, and the baseboard's end a hair proud of the baseboard.

    Facade        Plaster   the wall's face across the front, round the doorway (the wall's paint)
    FacadeBack    Plaster   the same wall seen from inside the unit (the unit's paint)
    Casing        Wood      the baseboards outside and in, and the rail: what never moves
    CasingLeft    Wood      the doorway's left side: its reveal lining, casing leg, plinth, a
    CasingRight             baseboard's end, and the oak board inside that Small's doorway shows
    CasingHead    Wood      the reveal's head, the casing's head and its cornice, centred
    FillLeft      Plaster   the wall's face that fills the M doorway's side down to Small's
    FillRight
    Frame         TrimSheet the M's mechanism only: posts, guides, stop bolts, header beam
    Switch        plain     the light switch's plate (the game makes it SmoothPlastic)
    SwitchToggle  plain     its rocker, centred on its pivot
    Lamp          plain     the unit's round ceiling lamp (the game makes it Neon when on)
"""

from carpentry import plaster_uv, wood_box
import geo
from geo import Mesh
import home_spec as K
import parts as unit_parts


def facade(s):
    """The wall's face across the front, 12 wide to the cap, open round the lined doorway."""
    m = Mesh("Facade")
    W2, F, H = s.width / 2, s.facade, s.wall_height
    o, top = s.door_width / 2 + K.LINER, s.door_height + K.LINER
    pu = plaster_uv()
    for x0, x1, z0, z1 in ((-W2, -o, 0.0, H), (o, W2, 0.0, H), (-o, o, top, H)):
        geo.box(m, (x0, 0.0, z0), (x1, F, z1), pu)
    return m


def facade_back(s):
    """The front wall's inside face (the unit's own warm white), behind the door's posts."""
    m = Mesh("FacadeBack")
    W2, F, H = s.width / 2, s.facade, s.wall_height
    o, top = s.door_width / 2 + K.LINER, s.door_height + K.LINER
    pu = plaster_uv()
    for x0, x1, z0, z1 in ((-W2, -o, 0.0, H), (o, W2, 0.0, H), (-o, o, top, H)):
        geo.box(m, (x0, F, z0), (x1, F + 0.04, z1), pu)
    return m


def inset(s):
    """How far each side of the doorway stands in at Small: half the M's opening less the S's."""
    return (s.door_width - K.SMALL_DOOR) / 2


def casing(s):
    """The oak that never moves: the baseboards either side, outside and in, and the rail where
    the wall's two paints meet (the lobby's, carried across the gap)."""
    m = Mesh("Casing")
    W2, F, H = s.width / 2, s.facade, s.wall_height
    dw2, cw = s.door_width / 2, K.CASING[0]
    for sd in (-1, 1):
        x = lambda a, b: tuple(sorted((sd * a, sd * b)))
        x0, x1 = x(dw2 + cw + 0.04, W2)
        wood_box(m, (x0, -K.BASE_PROUD, 0.0), (x1, 0.0, K.BASE), 5)    # the baseboard outside
        x0, x1 = x(dw2 + s.trim + 0.3, W2)
        wood_box(m, (x0, F + 0.04, 0.0), (x1, F + 0.1, K.BASE), 5)     # and inside, past the post
    rh, rp = K.RAIL
    wood_box(m, (-W2, -rp, H - rh), (W2, F, H + 0.02), 5)              # the rail
    return m


def casing_side(s, sd, name):
    """One side of the doorway (`sd` -1 the left as you walk in, 1 the right), where the M's
    stands: the reveal's lining back to the guides, the casing's leg on its plinth, the
    baseboard's end that follows the plinth in (a hair proud of the baseboard it slides over),
    and the oak board on the inside face that Small's doorway shows (inside the M's wall)."""
    m = Mesh(name)
    F = s.facade
    dw2, dh = s.door_width / 2, s.door_height
    cw, cp = K.CASING
    ph, pp = K.PLINTH
    L, back, n = K.LINER, 0.40, inset(s)  # the guides' front flange: the lining stops there
    x = lambda a, b: tuple(sorted((sd * a, sd * b)))
    x0, x1 = x(dw2, dw2 + L)
    wood_box(m, (x0, -0.02, 0.0), (x1, back, dh), 2)                    # the reveal's lining
    x0, x1 = x(dw2, dw2 + cw)
    wood_box(m, (x0, -cp, ph), (x1, 0.0, dh), 2, bevel=0.02)           # the casing's leg
    x0, x1 = x(dw2 - 0.02, dw2 + cw + 0.04)
    wood_box(m, (x0, -pp, 0.0), (x1, 0.0, ph), 1, bevel=0.02)          # its plinth block
    x0, x1 = x(dw2 + cw + 0.04, dw2 + cw + 0.04 + n)
    wood_box(m, (x0, -K.BASE_PROUD - 0.005, 0.0), (x1, 0.0, K.BASE + 0.005), 5)  # the baseboard's end
    x0, x1 = x(dw2 + L, dw2 + L + n)
    wood_box(m, (x0, F - 0.01, 0.0), (x1, F + 0.035, dh + L), 2)       # the board inside
    return m


def casing_left(s):
    return casing_side(s, -1, "CasingLeft")


def casing_right(s):
    return casing_side(s, 1, "CasingRight")


def head(s):
    """The doorway's head, centred so the game can draw it narrower for Small: the reveal's head,
    the casing's head over the legs, and the little cornice on it."""
    m = Mesh("CasingHead")
    dw2, dh = s.door_width / 2, s.door_height
    cw, cp = K.CASING
    kh, kp, kx = K.HEAD_CAP
    L, back = K.LINER, 0.40
    wood_box(m, (-(dw2 + L), -0.02, dh), (dw2 + L, back, dh + L), 2)    # the reveal's head
    wood_box(m, (-(dw2 + cw), -cp, dh), (dw2 + cw, 0.0, dh + cw), 2, bevel=0.02)  # the head
    wood_box(m, (-(dw2 + cw + kx), -kp, dh + cw), (dw2 + cw + kx, 0.0, dh + cw + kh), 3,
             bevel=0.03)                                                # the cornice
    return m


def fill_side(s, sd, name):
    """The wall's plaster that fills one side of the M's doorway at Small, built where it hides
    at the M (inside the wall beside the opening, a hair in from its faces): the stud between the
    S's lining and the M's opening."""
    m = Mesh(name)
    F, dw2, dh, L, n = s.facade, s.door_width / 2, s.door_height, K.LINER, inset(s)
    x0, x1 = sorted((sd * (dw2 + L), sd * (dw2 + L + n)))
    geo.box(m, (x0, 0.005, 0.0), (x1, F - 0.01, dh + L), plaster_uv())
    return m


def fill_left(s):
    return fill_side(s, -1, "FillLeft")


def fill_right(s):
    return fill_side(s, 1, "FillRight")


def mechanism(s):
    """The M's own door mechanism, the steel the home keeps: posts, guides, stop bolts, the
    header's beam (parts.frame without its jambs, pilasters, kick plates and cap)."""
    m = unit_parts.frame(s, dress=False)
    m.name = "Frame"
    return m


def switch_at(s):
    """The plate's middle and the rocker's middle (the unit frame)."""
    x, z = K.SWITCH_AT
    y = s.facade + 0.04
    plate = (x, y + K.SWITCH[2] / 2, z)
    toggle = (x, y + K.SWITCH[2] + K.TOGGLE[2] / 2, z)
    return plate, toggle


def switch(s):
    """The plate on the front wall's inside face, its edges eased."""
    m = Mesh("Switch")
    (x, y, z), _ = switch_at(s)
    w, h, t = K.SWITCH
    geo.box(m, (x - w / 2, y - t / 2, z - h / 2), (x + w / 2, y + t / 2, z + h / 2),
            geo.map_floor(1.0), bevel=0.015)
    return m


def toggle(s):
    """The rocker, centred on its pivot so the game can rock it."""
    m = Mesh("SwitchToggle")
    _, (x, y, z) = switch_at(s)
    w, h, t = K.TOGGLE
    geo.box(m, (x - w / 2, y - t / 2, z - h / 2), (x + w / 2, y + t / 2, z + h / 2),
            geo.map_floor(1.0), bevel=0.012)
    return m


def lamp_at(s):
    return (0.0, K.LAMP_AT, s.wall_height - K.LAMP[1] / 2)


def lamp(s):
    """The unit's round lamp, a flush drum under its plaster ceiling (the lobby's look)."""
    m = Mesh("Lamp")
    d, hang = K.LAMP
    geo.cylinder(m, "z", lamp_at(s), d / 2, hang, segs=20, smooth=False)
    return m


BUILDERS = {"Facade": facade, "FacadeBack": facade_back, "Casing": casing,
            "CasingLeft": casing_left, "CasingRight": casing_right, "CasingHead": head,
            "FillLeft": fill_left, "FillRight": fill_right, "Frame": mechanism,
            "Switch": switch, "SwitchToggle": toggle, "Lamp": lamp}
TEXSET = {"Facade": "Plaster", "FacadeBack": "Plaster", "Casing": "Wood", "CasingLeft": "Wood",
          "CasingRight": "Wood", "CasingHead": "Wood", "FillLeft": "Plaster", "FillRight": "Plaster",
          "Frame": "TrimSheet"}
PLAIN = {"Switch": (0.93, 0.91, 0.86), "SwitchToggle": (0.96, 0.95, 0.92),
         "Lamp": (1.0, 0.9, 0.76), "JobBoxFittings": (0.29, 0.31, 0.32),
         "MirrorBevel": (0.84, 0.88, 0.89), "MirrorPads": (0.29, 0.25, 0.22),
         "RailSteel": (0.29, 0.31, 0.32), "RailWheels": (0.16, 0.15, 0.14),
         "MilkCrate": (0.62, 0.36, 0.25), "FoldingTableLegs": (0.29, 0.31, 0.32),
         "SteelShelfBolts": (0.55, 0.56, 0.55), "CampBedFrame": (0.72, 0.73, 0.74),
         "StringLights": (0.08, 0.08, 0.08), "StringBulbs": (1.0, 0.76, 0.48),
         "NeonSignTube": (1.0, 0.82, 0.48), "NeonSignBack": (0.85, 0.9, 0.92),
         "NeonSignFittings": (0.75, 0.76, 0.77)}
# The door's parts the home front takes from the M as they are, in HomeDoor (the padlock and the
# number plate stay on the climb: a home's door latches, and its owner's name is over it).
DOOR_PARTS = ("CurtainClosed", "Slat_A", "Slat_B", "Slat_C", "BottomBar", "LatchBolt",
              "Hardware", "Drum")


def meshes(s):
    return {name: fn(s) for name, fn in BUILDERS.items()}
