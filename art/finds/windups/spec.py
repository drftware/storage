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


# --- The chattering teeth: a walking wind-up novelty, our own -----------------------------------
# References (README): listings put walking wind-up teeth at 1.75 to 2.5 in (44 to 64 mm) long
# and about as tall; vintage ones (late 1940s on) are a moulded denture, red-pink gums and cream
# teeth, the clockwork inside between the jaws at the back, a key on the side; the walking kind
# stands on two cartoon feet whose toes poke out in front. Ours is 2.6 in wide, 2 in tall on
# orange three-toed feet, with a white wing key on the right.
TEETH = dict(
    arch=dict(half=22.0, front=-22.0, p=2.6, back=(23.5, 12.0)),
    # the arch's centreline: a superellipse quarter from the front (0, front) round to the side
    # (half, 0), then straight back to `back` on each side (it widens a little, as dentures do)
    gum=dict(t=10.5, low=14.0, top=50.0, papilla=2.6, lip=0.9),
    # the gum band's thickness at its foot, the lower jaw's foot and the upper's top, how far
    # the gum rises between two teeth, and how much it stands proud of a tooth at the gum line
    occ=34.0,                    # where the two rows of teeth meet, shut
    teeth=[(7.0, 7.4, 2.5, 7.0), (6.0, 7.0, 2.4, 5.0), (6.2, 7.6, 2.9, 3.0),
           (6.2, 6.4, 3.4, 0.0), (7.0, 5.8, 4.0, 0.0), (7.4, 5.4, 4.3, 0.0)],
    # each side's teeth from the middle out: width along the arch, how far it stands out of the
    # gum, half its depth, and how far it leans out (degrees): two incisors, a canine, molars
    gap=0.2,                     # between two teeth
    hinge=(0.0, 15.0, 34.0),     # the top jaw's hinge pin, at the back between the jaws
    drawn=9.0,                   # degrees the top jaw stands open as it's found: a grin
    foot=dict(x=12.5, splay=7.0, ankle=(-3.0, 3.0), leg=(2.6, 9.0, 16.0)),
    # the feet's middle either side, how far each turns out, the ankle the foot rocks on (y, z),
    # and the leg's radius, foot and top
    key=dict(at=(27.0, 5.0, 21.0), shaft=(2.0, 7.5), wing=(15.0, 9.5), t=1.6),
    dust=0.06, seed=41.0,
)

# How it runs (timed from a video of a walking wind-up teeth's sound, README: clicks about
# 0.085 s apart in bursts, the jaw's open and its snap, so 6 to 7 snaps a second). Every snap
# lands a footfall: the feet are on the same crank, a step for each foot every two snaps.
CHATTER = dict(
    rate=7.0,          # snaps a second, fully wound: a frantic clatter
    fade=0.3,          # how much it slows across the run
    length=10.0,       # seconds of running
    knee=5.0,          # how suddenly it gives out at the end
    last=0.32,         # the slowest gap between snaps (s) before it stalls
    open=30.0,         # degrees the top jaw gapes before each snap, fully wound
    stride=2.6,        # mm each foot swings either side of its middle (it walks 4x this a step)
    lift=1.8,          # mm a foot lifts as it swings forward
    toe=6.0,           # degrees a swinging foot's toe tips up
    roll=4.0,          # degrees it waddles onto the planted foot
    wiggle=2.5,        # degrees it swivels with each step
    drift=6.0,         # degrees a second it can veer as it goes
    winds=4,           # half turns of the key when wound
)


# --- The walking robot: a 1950s-style printed tin walker of our own -----------------------------
# References (README): the small keyed walkers sold as reproductions of post-war Japanese toys
# (11.5 cm tall, 6 cm wide) and 1950s-60s originals of 6.5 to 8.5 in: a boxy printed torso, a
# square head with an aerial, arms on shoulder pins swinging opposite the legs, short legs on hip
# pins and big flat pressed-tin feet, a key in its back. Ours is 6.4 in to the top of its head
# (7.2 with its aerial's ball), printed cobalt blue with a dark gauge panel, red feet, hands and
# ears, a coil-spring aerial with a red ball.
ROBOT = dict(
    torso=[(54.0, 26.5, 17.0, 4.5), (54.6, 28.4, 19.0, 5.4), (55.8, 29.4, 19.9, 5.9),
           (57.4, 29.3, 19.8, 5.9), (58.6, 29.0, 19.6, 5.8), (100.0, 30.6, 20.5, 6.0),
           (110.0, 31.0, 20.6, 6.0), (113.6, 30.5, 20.1, 5.8), (115.8, 28.6, 18.4, 5.0),
           (116.7, 25.8, 15.8, 3.8), (117.0, 21.0, 12.0, 2.6)],
    # the torso's sections from its foot up: height, half width, half depth, corner radius (mm)
    chest=dict(x=19.0, z=(72.0, 106.0), front=-21.9),   # the raised gauge panel on its chest
    dial=[(-7.0, 96.5, 6.2), (9.0, 97.5, 4.0)],        # its two dials: x, z, the face's radius
    buttons=[-10.0, 0.0, 10.0], button_z=77.5,          # three plastic buttons along its foot
    head=[(121.2, 20.0, 15.0, 4.0), (121.8, 23.2, 18.2, 6.0), (122.9, 24.4, 19.4, 6.8),
          (124.4, 24.8, 19.8, 7.0), (125.9, 24.4, 19.4, 7.0), (151.0, 24.4, 19.4, 7.0),
          (155.5, 24.0, 19.0, 7.0), (158.6, 22.6, 17.6, 6.6), (160.6, 19.6, 14.8, 5.6),
          (161.7, 14.5, 10.0, 4.0)],
    head_top=162.0,
    eyes=(9.6, 146.5, 5.1),            # the left eye's x and z, and the lens's radius
    mouth=dict(x=10.5, z=(129.0, 136.5)),
    ear=dict(z=143.0, r=8.6),          # the red ear cones on each side of the head
    neck=(115.5, 122.0, 11.6),         # the steel collar between torso and head: foot, top, radius
    aerial=dict(at=(0.0, 0.0, 163.6), coil=(2.8, 0.85, 6.0, 177.4), ball=(182.0, 4.7)),
    # the coil's radius, wire radius, turns and top; the ball's middle and radius
    shoulder=(38.0, 0.0, 106.0),       # the left arm's pin (the right mirrors it): left is +X
    arm=dict(hw=5.6, hd=8.8, r=3.4, wrist=72.0),
    hand=dict(y=-1.0, z=62.5, r=7.4, wire=2.9, open=40.0),   # the C-claw: middle, radius,
    # thickness, and degrees open either side of straight ahead
    hip=(14.5, 0.0, 58.0),             # the left leg's pin
    leg=dict(hw=7.0, hd=8.0, r=2.4, top=63.0, foot=9.0),     # its foot end sits deep in the cuff
    ankle=13.0,                        # the ankle pin's height above the sole
    foot=dict(hw=12.5, toe=-31.0, heel=15.0, r=8.0, h=9.7, cuff=(10.4, 11.4, 15.6)),
    # half width, toe and heel (y), the corner radius, the top; the cuff round the leg's foot:
    # its half width, half depth and top
    key=dict(at=(0.0, 20.3, 86.0), shaft=(1.6, 7.6), wing=(7.6, 5.8, 8.0), t=1.3),
    # the key on its back: the shaft's radius and length; each wing's half width, half length
    # and how far out from the middle
    dust=0.05, seed=53.0,
)

# How it walks (timed from a video of a small tin walker's clanks, README: a footfall about every
# 0.28 s, fully wound). Both legs, both arms and the waddle run off one crank: a step for each
# leg every two footfalls, the arms swinging opposite the legs.
WALK = dict(
    rate=3.6,          # footfalls a second, fully wound: a brisk clank-clank-clank
    fade=0.35,         # how much it slows across the run
    length=17.0,       # how long the spring would last unslowed: it gives out near 15 s (the catalog)
    knee=6.0,          # how suddenly it gives out at the end
    last=0.55,         # the slowest gap between footfalls (s) before it stalls
    swing=15.0,        # degrees each leg swings either side of straight: 23 mm a step
    arm=24.0,          # degrees each arm swings either side of hanging
    lift=2.2,          # mm a swinging foot clears the floor at mid-swing
    roll=3.0,          # degrees it rocks onto the planted foot
    wiggle=2.5,        # degrees it twists with each step
    lean=3.0,          # degrees it leans into the walk
    jolt=0.7,          # degrees it nods as each foot clanks down
    winds=5,           # half turns of the key when wound
    aerial=(5.0, 0.12, 18.0),   # the aerial's sway: how often a second, its damping, the ball's
    # height over its pin (mm)
)


# --- The wind-up mouse: a flocked clockwork mouse, our own -----------------------------------
# References (README): the V&A's 1970s Hong Kong mouse (B.114-1996: grey nylon flock over a tin
# shell, cloth ears, printed eyes, a black plastic tail, the key bar out of its left side, two
# wheels under its middle, a balancing knob at the back; 1.5 in tall and wide) and Brent Museum's
# 1925 clockwork mouse (T944: 85 mm long, 38 wide, 40 high). Ours: grey flock, pink-lined felt
# ears, domed printed eyes, a pink bead nose and nylon whiskers, a brass wing key.
MOUSE = dict(
    body=[(-45.6, 0.0, 9.0, 9.0), (-44.6, 2.6, 6.6, 11.6), (-42.5, 5.0, 5.2, 13.8),
          (-39.0, 7.6, 4.2, 16.6), (-33.0, 10.8, 3.3, 20.6), (-25.0, 14.4, 2.7, 25.6),
          (-15.0, 17.6, 2.4, 30.4), (-4.0, 19.6, 2.3, 34.0), (7.0, 20.2, 2.4, 35.6),
          (17.0, 19.2, 2.7, 34.6), (25.0, 16.8, 3.4, 30.8), (31.0, 13.4, 4.6, 25.4),
          (35.0, 9.0, 6.6, 19.6), (37.3, 4.6, 9.0, 15.2), (38.2, 0.0, 12.0, 12.0)],
    # the body from the nose's tip (-y) to the rump: y, half width, its underside, its top (mm)
    low=0.42,          # where the widest line runs, from underside (0) to top (1): fuller low
    flat=3.2,          # the underside's squareness (2 an ellipse): it sits flat on its plate
    ear=dict(at=(10.2, -14.0, 28.0), r=8.4, face=(0.42, -0.84, 0.30), lean=0.30),
    # the left ear's foot on the head, the felt disc's radius, which way its cup opens, and how
    # far it leans out from upright
    eye=dict(y=-29.0, z=19.2, r=3.6, face=(0.80, -0.48, 0.36)),   # domed printed eyes, a quarter
    # of the way from the body's own facing toward `face`
    nose=(0.0, -45.4, 9.0, 2.5),
    whiskers=[(0.30, 0.22), (0.38, 0.0), (0.30, -0.24)],   # each one's back and up lean
    whisker=dict(at=(-41.4, 9.8), len=19.0, r=0.42),
    wheel=dict(x=9.4, r=5.2, w=2.6),   # the two drive wheels on one axle under its middle
    plate=dict(hw=12.0, y=(-21.0, 23.0), z=(1.4, 2.8), r=6.0),     # the grey plastic base
    knob=(26.0, 2.6),                  # the balancing knob under its rump: y and radius
    tail=[(0.0, 36.0, 11.6), (0.0, 45.0, 15.6), (0.4, 54.0, 20.6), (1.4, 63.0, 24.8),
          (3.0, 72.0, 27.4), (5.0, 81.0, 28.2), (6.8, 89.0, 27.2)],
    tail_r=(2.0, 0.9),                 # the plastic tail's thickness at its root and its tip
    key=dict(y=8.0, z=15.0, shaft=(1.3, 5.6), wing=(5.4, 4.4, 5.8), t=1.1),
    # the key out of its left side: the shaft's radius and length; each wing's half width, half
    # length and how far out from the middle; its thickness
    dust=0.05, seed=67.0,
)

# How it runs (README): it zips off at a toy's top speed, veers a little to its left, slows as
# the spring gives out, stalls dead, rocks onto its nose and squeaks there.
ZIP = dict(
    top=3.0,           # studs a second fully wound (0.76 m/s, a quick toy)
    grip=0.06,         # seconds its wheels take to bite and launch it
    length=5.4,        # how long the spring would run unslowed (s)
    fade=0.45,         # how much it slows across the run
    knee=5.0,          # how suddenly it gives out at the end
    stall=0.95,        # studs a second where the spring gives up and it stops dead
    halt=0.06,         # seconds it takes to stop dead
    veer=3.2,          # degrees a stud it curls to its left (one wheel drags)
    shimmy=(1.4, 0.5), # degrees it shimmies either side, and studs a shimmy
    buzz=(0.55, 0.22), # degrees its nose hops as the gears buzz, and studs a hop
    wag=(20.0, 0.48),  # degrees the tail wags either side, and studs a wag (its cam)
    tail=(14.0, 0.12), # the plastic tail's own whip: how often a second, its damping
    ears=(11.0, 0.18), # the felt ears' flick on their feet: how often a second, its damping
    rock=[(5.4, 0.20), (1.5, 0.11), (0.35, 0.055)],   # the nose-down rocks when it stops:
    # degrees and seconds each
    winds=4,           # half turns of the key when wound
)
