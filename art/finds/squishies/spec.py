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
