"""Every number of the Wind-ups and noisemakers set. Sizes are in millimetres, as listings give
them, turned into studs by mm() (10 inches a stud, the boxes' scale: 254 mm).

A find's frame in Blender: X across its front, Y away from you (its front faces -Y), Z up, the
origin the find's pivot.
"""

STUD_MM = 254.0


def mm(v):
    return v / STUD_MM


# --- The cymbal monkey: a 1960s Japanese clockwork toy, our own monkey -------------------------
# References (README): a museum's seated cymbal monkey is 10.5 in tall, 7.5 wide and 8.5 deep
# (267 x 190 x 216 mm): a plush body sat with its legs out, a vinyl face, ears, hands and feet,
# a felt waistcoat, striped trousers, brass cymbals in its fists. Ours wears a green waistcoat,
# navy-and-cream trousers and a maroon fez with a black tassel, and winds with a key in its back.
MONKEY = dict(
    # where the pieces sit, in the toy at rest (sat on the floor, the pivot under its seat)
    neck=(0.0, 14.0, 166.0),            # the head nods about X through here
    eyes=(16.0, -31.0, 207.0),          # the left eye's middle (the right mirrors it); r below
    eye_r=11.5,
    shoulder=(51.0, 14.0, 142.0),       # the left shoulder (the right mirrors it)
    elbow=(50.0, -22.0, 104.0),
    wrist=(25.0, -58.0, 80.0),
    hand=(19.0, -66.0, 74.0),           # the fist round the cymbal's strap
    cymbal=dict(r=33.0, at=(1.0, -66.0, 74.0), dish=4.0, bell=(9.0, 10.0), t=0.8),
    open=24.0,                          # degrees the arms stand open as it's found (the clash is
    # this far back the other way: the cymbals' rims meet square at x = 0)
    key=dict(at=(0.0, 62.0, 72.0), shaft=(3.0, 14.0), wing=(25.0, 12.0), t=1.4),
    fez=dict(at=(7.0, 13.0, 239.0), tilt=13.0, r=(25.0, 20.0), h=27.0),
    dust=0.35, seed=31.0,
)

# How it plays (timed from two videos of real clockwork cymbal monkeys, README): a small one
# clashed 4.6 times a second, a 5.5-inch one 6, each slowing by about a fifth over its run before
# the spring gave out. Ours is twice their size with heavier arms, so it starts a little slower.
PLAY = dict(
    rate=4.2,          # clashes a second when fully wound: a frantic, unmissable racket
    fade=0.18,         # how much the beat slows across the run before the end
    length=20.0,       # seconds of playing (the catalog's 20)
    knee=6.0,          # how suddenly it gives out at the end: higher holds the beat longer, then
    # a quick run-down of a few slow, tired clashes
    last=0.95,         # the slowest gap between clashes (s) before it stalls short of a last one
    bob=4.5,           # degrees the head nods down on each clash, at full wind
    eyes=11.0,         # degrees the eyes roll up, wide, on each clash
    tassel=10.0,       # degrees the fez's tassel flings about after each nod
    ring=6.0,          # degrees each cymbal flaps on its strap from the hit
    winds=4,           # half turns of the key when wound (the Wind motion's clicks)
)


# --- The jack-in-the-box: a 1950s tin music box, our own jack -----------------------------------
# References (README): the Bruce County Museum's 1953 tin jack-in-the-box is 14 cm tall with its
# lid shut and 13.5 cm square, the V&A's late-1940s one (Mettoy) much the same: a printed tin
# cube with rolled corner seams, a shallow lid hinged at the back and painted yellow inside, held
# shut by a small catch at the front, a wire crank with a wooden knob on the right side, and a
# clown with a painted composition head and a felt cap on a cloth-covered spring. Ours prints a
# playing card's suit on each side (a jack in a box), wears a two-tier ruff and harlequin
# diamonds, and has a painted face that has crazed with age.
JACK = dict(
    box=(134.0, 136.0),          # the tin cube's side, and its height to the rim under the lid
    corner=3.0,                  # radius of the rolled seam at each corner
    lid=dict(over=67.8, skirt=7.0, top=2.9, hinge=(0.0, 69.6, 137.6), open=112.0),
    # the lid's outer half width, how far its skirt hangs over the box, its top above the rim,
    # its hinge pin, and how far it swings open onto its stop (past upright, as both museums'
    # stand open)
    latch=dict(pivot=(0.0, -67.2, 119.0), w=12.0, flip=24.0),
    # the front catch: a sprung tin tab riveted at its foot, hooked over the lid's front edge
    crank=dict(at=(66.5, 34.0, 90.0), arm=22.0, out=7.0, knob=(6.2, 16.0)),
    # the crank's axle on the right side (high and towards the back, as both museums' are), the
    # wire arm's reach, how far the knob stands off, and the turned knob's radius and length
    floor=5.0,                   # the spring's foot on the box's floor: the jack sways about it
    neck=209.0,                  # where the head sits in the ruff, popped up
    closed=(0.785, 0.56),        # the jack's scale and stretch pressed down in the shut box: 44
    # per cent of its height and about as wide as it stands, under the lid with room to spare
    dust=0.4, seed=37.0,
)

# How it plays (timed from a video of a 1950s tin jack-in-the-box's sound, README): the tune's
# 17 loudest notes over 7.8 s as the crank turns, 0.9 s of nothing, then the bang and four
# rattles at 0.2, 0.38, 0.52 and 0.65 s after it as the lid bounces on its stop and the jack
# sways on its spring.
TUNE = dict(
    lead=0.3,          # seconds from the start of Wind to the first note (the hand takes hold)
    length=7.8,        # seconds of tune: the crank turns all through it
    turns=6.5,         # turns of the crank in that time, about a bar of the tune a turn
    beat=0.9,          # the silence after the last note before the latch lets go
    tilt=12.0,         # degrees the jack's head is left cocked at you once it settles
)
