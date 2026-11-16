"""Every number of the Squishies set. Sizes are in millimetres, as listings give them, turned into
studs by mm() (10 inches a stud, the boxes' scale: 254 mm).

A find's frame in Blender: X across its front, Y away from you (its front faces -Y), Z up, the
origin the find's pivot.
"""

STUD_MM = 254.0


def mm(v):
    return v / STUD_MM


# --- The squishy butter stick (F-05a) ------------------------------------------------------------
# References (README): slow-rise PU foam butter sticks sold in 2026 are 5.1 to 5.5 in long and
# about 1.5 to 1.6 in square (one listing 5.51 x 1.57 x 1.57 in), a sunny yellow block with
# well-rounded edges and the wrapper printed straight onto the foam in navy: the word BUTTER on
# its side. Ours prints BUTTER on its front and a real wrapper's tablespoon marks over its top.
BUTTER = dict(
    length=140.0,          # 5.5 in
    side=40.0,             # 1.57 in square
    edge=7.0,              # the radius every edge is rounded to
    # the game mesh: points this far apart over its top, where the thumb goes, coarser round
    # its other sides; a ring of them every `ring` mm down its length (the detailed mesh halves
    # them all)
    top_step=2.6, side_step=8.0, corner_n=4, edge_n=4, ring=3.0,
    # the thumb's dent: its middle on the top (x, y), its radius and how deep it goes, how far
    # its sides tip toward the middle at its deepest (degrees), and the bones round it
    dent=(28.0, -2.0), dent_r=15.0, dent_d=8.5, tilt=36.0, rims=6,
    # the print: the word's letters (mm tall, stroke), the tablespoon marks' pitch (a stick of
    # butter is eight tablespoons)
    letter_h=14.0, stroke=3.1, tbsp=17.5,
    dust=0.35, seed=5.0,
)

# The squeeze: a thumb pressed in fast and held, let go, and the slow-rise foam creeping back
# over about seven seconds, quickest at first (a slow-rise squishy's rise, timed from listings'
# "rises in 5 to 10 seconds"). (seconds, how far in: 0 none, 1 the full dent[, style, way])
PRESS = [
    (0.0, 0.0),
    (0.32, 1.0, "Quad", "Out"),     # the thumb goes in, slowing as the foam fights it
    (1.0, 1.0),                     # held
    (1.3, 0.9, "Sine", "Out"),      # let go: the first little give back
    (3.8, 0.42, "Quad", "Out"),     # the slow rise, quickest first
    (8.6, 0.0, "Sine", "Out"),      # creeping the last of the way flat
]


# --- The stress ball with a face (F-05b) ---------------------------------------------------------
# References (README): rubber "eye poppin'" squeeze balls, 1.75 to 2.76 in across (a promo
# smiley ball 1.75 in; a sensory popping-eye ball 2.76 in): a glossy, soft vinyl ball in one
# bright colour, two big white bubble eyes with black pupils standing proud of the face, a thin
# black grin printed under them. Squeezed, the air inside pushes the eyes out of their sockets on
# white necks; let go, they pop back in. Ours is lime green, its pupils crossed a little.
STRESS = dict(
    r=35.0,                # the ball's radius: 70 mm across (2.76 in)
    sink=1.2,              # how far it settles onto the floor: a soft ball's flat spot
    # the eyes: their radius, how far their middles sit inside the ball's skin, their angle up
    # from the ball's middle and out to each side of the front (degrees), the white neck under
    # each (its radius and how deep it reaches, from the eye's middle)
    eye_r=9.5, eye_in=2.5, eye_up=17.0, eye_out=19.5, neck_r=6.0, neck_d=17.0,
    # the rubber lip round each socket: from the eye's edge out to this radius, this high
    lip_r=11.6, lip_h=0.8,
    # the pupils: their radius on the eye (degrees of the eye's sphere), and where they look
    # (degrees in toward the nose, up)
    pupil=24.0, look_in=17.0, look_up=9.0,
    # the grin, printed on (mm over the ball's skin from the front's middle, across and up from
    # the ball's middle): its arc's centre, radius and ends (degrees), the stroke, the dimples
    grin_c=(0.0, 6.0), grin_r=19.0, grin_a=(212.0, 328.0), grin_w=2.4, dimple=3.6,
    dust=0.3, seed=11.0,
)

# The squeeze, timed like a rubber squeeze toy in the hand: a quick squash as the fingers close,
# the eyes shoved out a beat behind it (the air takes a moment to push them), held, then let go:
# the ball springs back past round and wobbles still, the eyes snap back in and bounce once.
# (seconds, value[, style, way])
SQUISH = [
    (0.0, 1.0),
    (0.07, 1.035, "Sine", "Out"),     # the fingers close round it: it bulges up a hair first
    (0.26, 0.68, "Quad", "Out"),      # squashed: the eyes go
    (0.66, 0.66, "Sine", "InOut"),    # held, still pressing
    (0.78, 1.1, "Quad", "Out"),       # let go: it springs back past round
    (0.9, 0.955),
    (1.01, 1.03),
    (1.12, 0.99),
    (1.22, 1.0),
]
POP = [                               # each eye out along its own axis, mm
    (0.0, 0.0),
    (0.09, 0.0),
    (0.34, 7.6, "Quad", "Out"),       # shoved out, a little past where the air holds it
    (0.45, 6.6),
    (0.68, 7.0),
    (0.8, -0.9, "Quad", "Out"),       # let go: back in, a hair past home
    (0.92, 0.5),
    (1.03, -0.15),
    (1.14, 0.0),
]
SWELL = [                             # each eye's size: the bubble swells as it comes out
    (0.0, 1.0),
    (0.09, 1.0),
    (0.34, 1.3, "Quad", "Out"),
    (0.45, 1.22),
    (0.68, 1.26),
    (0.8, 0.95, "Quad", "Out"),
    (0.92, 1.03),
    (1.04, 1.0),
]
