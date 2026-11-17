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

# --- The clockwork tin bird: an antique printed-tin songbird of our own ------------------------
# References (README): the V&A's tinplate sparrow (O36973: 2.25 in tall, 1.5 in wide, two
# pressed halves crimped along the back and belly, a red cap, a cream face, a printed wing, a
# fan tail loosely joined, two stamped metal feet, the key in its side) and robin (O36970), and a
# 1960s German hopping bird listed at 85 x 56 x 40 mm. Ours is 112 mm from bill to tail tip,
# 60 mm tall and 34 mm wide: a scarlet cap, a gold breast, dark wings with a gold bar and teal
# scalloped coverts, a rust tail barred in brown. It hops on a crank and whistles on a bellows.
BIRD = dict(
    body=[(-35.0, 0.0, 47.0, 47.0, 0.5), (-34.0, 4.6, 42.4, 51.6, 0.5),
          (-32.0, 8.2, 38.4, 55.2, 0.48), (-29.0, 11.2, 34.4, 58.2, 0.46),
          (-25.0, 13.3, 30.0, 60.0, 0.45), (-20.0, 14.0, 26.2, 60.4, 0.45),
          (-15.0, 13.8, 23.2, 58.6, 0.44), (-10.0, 14.4, 20.8, 54.4, 0.42),
          (-4.0, 16.4, 18.8, 51.0, 0.42), (2.0, 17.2, 18.0, 49.0, 0.42),
          (8.0, 17.0, 18.4, 47.6, 0.42), (14.0, 15.9, 19.9, 45.6, 0.43),
          (20.0, 14.0, 22.8, 43.7, 0.44), (26.0, 11.0, 26.6, 41.8, 0.46),
          (31.0, 7.6, 30.4, 40.0, 0.48), (34.5, 4.0, 33.4, 38.4, 0.5),
          (36.2, 0.0, 35.8, 35.8, 0.5)],
    # the pressed body from the face (-y) to the rump: y, half width, belly, back, and where its
    # widest line runs from belly (0) to back (1) (mm)
    bill=dict(base=(-31.0, 47.4), tip=(-46.5, 45.4), hw=4.8, up=3.6, lo=2.5, droop=0.9),
    # the bill sunk into the face at `base` (y, z), its tip; half width and the upper and lower
    # bills' depth at the base; how far the tip bends down. The lower bill hinges at the gape.
    gape=(-33.2, 46.8),                # where the lower bill hinges (y, z)
    eye=dict(y=-24.5, z=50.0, r=3.4),  # the printed eye on each side of the head
    tail=dict(root=(27.0, 36.0), len=44.0, rise=24.0, w=(9.0, 23.0), t=0.9, fold=9.0,
              tips=5),
    # the fan tail slotted into the rump: its root (y, z), length, how far it angles up (deg),
    # width at root and tip, the tin's thickness, the fold along its middle (deg), how many
    # rounded feather tips across its end
    hip=(2.0, 21.0),                   # where the legs' crank comes out of the belly (y, z)
    leg=dict(x=6.4, r=1.5, foot=0.0), # each wire leg's x, its radius, and where its foot sits (y)
    toes=[(11.5, 17.0), (13.5, 0.0), (11.5, -17.0), (6.5, 180.0)],
    # each stamped toe: its length (mm) and heading (deg from straight ahead, + outward)
    toe=dict(w=2.1, t=1.0),           # the toes' width at the root and the plate's thickness
    key=dict(y=6.0, z=33.0, shaft=(1.3, 5.6), wing=(5.0, 4.0, 5.4), t=1.1),
    dust=0.05, seed=71.0,
)

# How it hops (README): the crank kicks it into little hops, three, then it stops and whistles
# twice, its head up and its tail cocked; as the spring gives out the hops get lower and slower.
HOP = dict(
    rate=3.3,          # crank turns a second fully wound: one hop or one whistle each
    length=12.0,       # how long the spring would run unslowed (s)
    fade=0.5,          # how much it slows across the run
    knee=4.0,          # how suddenly it gives out at the end
    stall=1.35,        # turns a second where it gives up
    pattern=3,         # hops before each whistle
    height=13.0,       # mm the first hops rise (falling as g does: the flight time follows)
    step=12.0,         # mm forward a hop, fully wound
    push=0.34,         # the share of a turn spent crouched, kicking, before it leaves the floor
    turn=(4.5, 1.4),   # degrees it swivels either way a hop, and how far it drifts left a hop
    kick=(5.0, 11.0),  # the nose dip and the legs' push back as it kicks (deg)
    tuck=-9.0,         # the legs swing forward in the air, reaching for the floor (deg)
    land=2.6,          # the nose-down rock as it lands (deg)
    sing=(7.0, 13.0, 21.0),   # whistling: head up, tail cocked, bill open (deg); a whistle
    # takes two turns of the crank, two notes
    tail=(9.0, 0.16),  # the loose tin tail's bob: how often a second, its damping
    jaw=(16.0, 0.22),  # the lower bill's flick on its hinge
    winds=4,           # half turns of the key when wound
)

# --- The toy siren car: a 1960s Japanese tin friction car of our own --------------------------
# References (README): the V&A's small English tin friction cars (11 cm: a fire chief's car, a
# highway patroller), a 1960s Japanese friction patrol car (9.25 in) whose roof lights turn as it
# rolls. Ours is a chunky two-door chief's car, 140 mm (5.5 in) long: pressed and printed tin in
# red with a cream roof and side flash, a numbered door roundel of our own (no real force's words
# or crest), tin bumpers and grille, rubber tyres with whitewalls on tin hubcaps, and a red
# fluted dome on a tin base on the roof, which the flywheel turns and a lamp inside lights.
SIREN = dict(
    length=140.0, half_w=30.0,     # nose to tail of the pressed body, half its width at the belt
    corner=7.0,                    # the plan's corners round off this much at nose and tail
    wheelbase=82.0, track=50.0,    # between the axles, and between the wheels' middles
    tyre=dict(od=26.0, w=10.0, hub=15.0, wall=(9.4, 11.0)),
    # rubber tyres: outside diameter, width, the tin hubcap's diameter, and the whitewall
    # printed between these radii on the outer sidewall
    arch=15.0,                     # the wheel arches' round about each axle
    sill=8.0,                      # the body's rolled lower edge
    deck_nose=28.0, deck_cowl=32.0, deck=33.0, deck_tail=30.0,   # bonnet and boot heights
    roof=50.0, crown=1.8,          # the roof's height and how much it domes
    cowl=-24.0, screen_top=-9.0,   # y where the windscreen starts and where it meets the roof
    back_top=22.0, back_base=37.0, # and the rear window
    glass_half=26.5, roof_half=22.0,   # the greenhouse's half width at its foot and its roof
    b_pillar=8.0,                  # y of the door window's back post
    door=(-21.0, 15.0),            # y of the door's front and back shut lines
    fine=1.8,                      # the small offsets in the section, times the die-cast car's
    base=dict(z0=7.0, z1=8.4, half=24.0),       # the tin floor pan between the sills
    motor=dict(y=(18.0, 52.0), x=13.0, z=(4.6, 9.0)),   # the friction motor's case on the rear axle
    bumper=dict(z=(10.0, 16.5), half=30.6, d=3.4),     # the tin bumpers: height, half width, depth
    grille=dict(half=22.0, z=(16.8, 24.6)),      # the tin grille across the nose
    lamp=dict(x=17.0, z=20.7, r=4.0),            # the headlamps set in the grille's ends
    beacon=dict(y=-1.0, base=(10.6, 4.2), r=8.8, h=15.0, flutes=12),
    # the roof light: y on the roof; its tin base's radius and height; the red dome's radius,
    # height and the flutes moulded round it
    number="7",                    # the door roundel's number (ours, no real force's)
    dust=0.0, seed=83.0,     # none: on the glossy lacquer any film reads as blotches (the
    # die-cast car's lesson); the creases still darken
)

# How it goes (the Push action): two pushes along the floor rev its flywheel, whirring, then it
# leaves the hand and rolls off down the hall on the flywheel, its roof light turning with it,
# slowing as the flywheel runs down, and coasts to a stop.
SIREN_RUN = dict(
    strokes=2,          # pushes before it's let go
    stroke=(0.07, 0.24),  # studs each push carries it, and how long a push takes (s)
    press=1.6,          # degrees its nose dips as the hand presses down on the roof
    v0=5.4,             # studs/s as it leaves the hand: about 1.4 m/s, a fast friction car
    drag=(0.55, 0.32),  # the flywheel's run-down: studs/s lost a second, plus this share of its speed
    drift=2.2,          # degrees a second its heading wanders at full speed
    rattle=0.7,         # degrees the tin body rocks on its axles at full speed
    squat=1.4,          # degrees its nose lifts as the flywheel bites
    spin=2.6,           # turns a second of the roof light at full speed (geared to the flywheel)
    glow=(0.3, 0.9),    # the lamp comes up over the pushes; it fades this long after it stops
)


# --- The squeaky rubber duck: a classic yellow vinyl bath duck of our own -------------------------
# References (README): the V&A's 1950s English moulded bath duck (O1122250, 12.7 cm long, a raised
# feathered wing, an upturned tail, a flat open bill painted red), and Wikimedia Commons photos of
# modern squeaky vinyl ducks (a round head sat on a broad body, a crest along the mould seam on
# its crown, printed eyes with a shine, a wide orange bill with a smile, a squeak hole under it).
# Ours is about 98 mm from bill to tail and 86 tall, as the common 3.5 to 4 inch squeakers are.
# The duck is one surface, drawn as rounded volumes melted together (each a centre, radii, mm).
DUCK = dict(
    body=((0.0, 6.0, 19.0), (35.0, 38.0, 25.0)),    # the broad low hull it floats on
    chest=((0.0, -12.0, 28.0), (29.0, 24.0, 24.0)),  # its round breast, rising to the head
    tail=dict(at=(0.0, 33.0, 36.0), r=(14.0, 18.0, 9.5), rise=38.0),
    # the upturned pointed tail: its middle, radii, and how steeply it points up (deg)
    head=((0.0, -11.0, 62.0), (22.5, 22.0, 22.0)),   # a big round head sat forward on the breast
    crest=dict(at=(0.0, -12.0, 82.8), r=(4.2, 7.5, 3.8), tip=-18.0),
    # the little moulded tuft along the seam on its crown, tipped forward (deg): round-topped,
    # as the references' are (a thinner one read as a sharp spike from the front)
    wing=dict(at=(29.0, 15.0, 28.0), r=(6.0, 19.0, 11.0), rise=16.0, toe=7.0, taper=0.5),
    # the left wing, raised a little off the side (the right mirrors it), its back end lifted
    # `rise` and its front turned in `toe` (deg), narrowing toward its tip to half its height
    # (`taper`), a teardrop: an even oval read as a round disc stuck on from behind
    blend=dict(head=11.0, chest=10.0, tail=12.0, wing=7.5, crest=6.0, base=5.0),
    # how wide each melts into the rest (mm): a soft neck, a wing that swells from the side (its
    # moulded edge is drawn in the look), a rounded foot
    centre=(0.0, -16.0, 20.0),       # where its surface is sampled from: low in the breast, where
    # every bit of it, the tail's top and the chin's underside both, is in sight
    bill=dict(base=(-24.0, 58.6), tip=(-47.5, 57.4), hw=(9.6, 13.2), up=(9.4, 6.0),
              lo=(6.0, 3.8), short=1.6, smile=2.6, gap=1.0),
    # the moulded bill sunk in the face at `base` (y, z) to its tip: half width at the base and
    # flared at the tip, the upper and lower bills' depth there, how far short of the upper the
    # lower stops, how much the mouth's corners turn up, the mouth line's gap (mm)
    eye=dict(az=36.0, el=17.0, w=4.6, h=5.6, pupil=(3.0, 4.0), shine=1.05),
    # each printed eye: where it sits on the head (degrees round from straight ahead and up from
    # the head's middle), its white's half width and height, the black pupil's, the shine's radius
    hole=dict(y=18.0, r=2.3, lip=1.0),   # the squeak hole under the body: y, its radius, its lip
    dust=0.3, seed=89.0,
)

# How it squeaks (the Squeeze action): squeezed, the whole duck squashes keeping its volume (the
# tea light flame's `stretch`), wheezing out its squeak, is held a beat, then let go it springs
# back past its size and wobbles still, its nose dipping as it's pressed and lifting on the bounce.
SQUEEZE = dict(
    grip=(0.07, 1.035),   # s and stretch: it rises a touch as the fingers close (the wind-up)
    squash=(0.2, 0.72),   # s and stretch at the bottom of the squeeze: the squeak
    hold=(0.34, 0.70),    # held a beat, the last of the air wheezing out
    bounce=[(0.48, 1.11), (0.6, 0.955), (0.71, 1.025), (0.82, 0.992), (0.92, 1.0)],
    # let go: the vinyl springs back past its size and wobbles still (s, stretch)
    nod=(4.0, -2.4, 0.9),  # degrees its nose dips at the squash, lifts on the bounce, then dips
)

# --- The kazoo: a classic pressed-tin kazoo of our own --------------------------------------------
# References (README): the Kazoo Museum's board of the 18 pressings that make a tin kazoo
# (Wikimedia Commons, "Kazoo manufacturing steps.JPG": a tin top embossed with a name and three
# raised rings, a red-printed bottom half crimped over its edges, both ends turned under, a
# threaded collar pressed onto the top, a cap with a punched hole screwed over a card ring that
# holds the skin), "2023 Kazoo (1).jpg" (the submarine taper, the ridge down the top, the cap's
# rolled lip and threads, brushed metal), and the Grover Center's 1970s toy kazoo (1985.006.140:
# painted, two halves crimped together, three indentations on top). Listings give 4.75 in
# (121 mm) long. Ours: a tin top, a red bottom, a tin cap, a cream wax-paper skin. Lengths run
# along Y from the mouth end (-Y, the wide flattened end you hum into) to the narrow tail (+Y);
# the bottom lies on the floor at z = 0.
KAZOO = dict(
    length=121.0,                 # mouth lip to tail lip (mm)
    # The museum board's finished kazoo (measured off the photo): nearly full width from the
    # mouth end back to the cap, then a long straight taper to the narrow tail, a submarine.
    w=(11.5, 11.1, 4.9),          # half width at the mouth end, at the knee, at the tail
    h=(12.6, 12.2, 9.0),          # height of the ridge down the top, the same three places
    knee=(0.30, 0.05),            # where the taper starts (a fraction of the length back from
    # the mouth) and how softly it bends there
    seam=0.5,                     # where the halves meet up the sides, a fraction of the height:
    # the red bottom half, its edge crimped over the top's (0.40 as the references showed the
    # red as a thin line from any angle above; at half height it reads as a band down the side)
    top_sq=2.5, bot_sq=4.2,       # how square the top and bottom halves' sections are
    # (2 an oval; the bottom is flatter, so it lies still on the floor, its sides more upright)
    fold=1.5,                     # how far the red half's crimped edge folds up over the seam
    # onto the top's side (mm): the red stripe seen from above, the half below tucking under
    ridge=0.11,                   # the crease down the middle of the top: how much it peaks
    bead=(0.62, 0.7),             # the crimped seam's rolled bead along each side: how far it
    # stands out and its half height (mm), just under where the halves meet
    lip=(0.55, 0.45),             # the rolled lips' radius at the mouth end and the tail (mm)
    deep=(13.0, 9.0),             # how far into each end you can see before it's dark (mm)
    cap_at=39.0,                  # the cap's middle, back from the mouth end (mm)
    collar=dict(r=9.4, ri=8.6, up=4.0, low=4.4),
    # the threaded collar pressed onto the top: outer and inner radius, how far it stands up off
    # the ridge and reaches down into the tube (mm); as wide as the body (10.4) it stood out of
    # the body's rounded sides under the cap
    skin=dict(r=8.9, dome=0.25, t=0.12, on=0.05),
    # the wax-paper skin on its card, resting on the collar's rim: radius, how far it bulges up,
    # its thickness, how far above the rim it sits (mm)
    cap=dict(r=12.6, skirt=11.95, gap=0.7, top=6.0, hole=4.6, dish=0.55, bead=0.7),
    # the screw cap, wider than the body: its rolled rim's outer radius, the skirt's radius, how
    # far above the ridge its rim stops, its top's height, the punched hole's radius, how far its
    # top dishes down to the hole, the rim's roll (mm); its foot turns in under to the collar's
    # thread, as a screw cap's does
    rings=[(60.0, 4.2, 0.45), (74.0, 3.7, 0.42), (87.0, 3.2, 0.38)],
    # the three rings pressed up out of the top down the taper, as bold as the museum board's,
    # about half the top's width: back from the mouth end, radius, how far the bead stands (mm)
    ring_w=0.75,                  # each ring's bead: how far it runs either side of its crest (mm)
    mark=dict(at=15.0, r=(6.0, 4.4), star=2.6, up=0.38),
    # our maker's mark pressed up out of the top between the mouth end and the cap: an oval rim
    # with a fine line inside it and a five-point star in a stippled field (back from the mouth
    # end, half length and half width, the star's radius, how far the rim stands, mm)
    knurl=dict(n=60, band=(3.2, 5.45), up=0.16),
    # the cap's grip band above its thread: ribs round it, the band's foot and top above the
    # collar's foot, how far a rib stands (mm)
    cap_ring=(2.7, 0.55, 0.22),   # a bead pressed round the cap's top: radius out from the hole's
    # edge, its half width, how far it stands (mm)
    dust=0.35, seed=97.0,
)

# How it plays (the Blow action): lifted to the lips, the mouth end tipping up; the hum starts
# and the paper skin under the cap shivers, a buzz too fast to see but for its flicker, swelling
# a little through the note; the note stops, the skin stills, and it's lowered back.
BLOW = dict(
    lift=(0.32, 3.5, -6.0),       # s to bring it up, mm it rises, degrees its mouth end tips up
    hum=(0.36, 1.58),             # the note starts and stops (s)
    buzz=24.0,                    # the skin's flicks a second (every frame of a 24 fps preview:
    # the real buzz is a few hundred, too fast to see, so it shows as a shimmer)
    skin=(0.2, 0.5),              # how far it flicks (mm) and how much its bulge pumps (stretch)
    swell=1.6,                    # the note leans in: degrees more tip at its loudest
    lower=(1.62, 2.1),            # lowered back from, and at rest by (s)
)

# --- The toy drum (F-04f2) ------------------------------------------------------------------------
# A child's tin drum of our own: a printed tin shell (a deep blue field, cream stars and red
# roundels), red-painted rolled-tin hoops top and bottom, a white cotton cord laced in ten V's
# between them through punched holes in the hoops, a calfskin head under the top hoop's rolled lip
# and two turned beech sticks lying across the top, as found. Listings and museum records give 6
# to 7 in across and 3 to 5 in tall (README); ours is 6.5 in across the shell, 4.5 in tall. The
# drum stands on the floor at z = 0, centred on the origin; the sticks' butts stick out the front.
DRUM = dict(
    r=82.5,                       # the shell's radius (165 mm across, 6.5 in)
    h=115.0,                      # bottom hoop's foot to top hoop's rim (4.5 in)
    hoop=dict(h=15.0, out=3.5, roll=1.6, lip=80.0, deep=9.0),
    # each rolled-tin hoop: how tall it is, how far its band stands out from the shell, the
    # radius of the bead rolled at each edge, the radius its top roll turns in to over the head,
    # and how far down inside that lip reaches (mm): below the head even when a hit dips it
    head=dict(sink=4.2, flat=0.9),
    # the calfskin head: how far below the top hoop's rim it lies, and the fraction of the
    # shell's radius it stays flat before it curves down over the shell's edge under the lip
    floor=4.0,                    # the tin bottom, this far up inside the bottom hoop (mm)
    cord=dict(n=10, r=1.2, hole=7.5, grommet=(1.7, 2.7, 0.35), twist=7.0),
    # the cord: n holes in each hoop, so n V's round the drum; its radius; how far each hole is
    # in from the drum's end (the middle of the hoop's band); a tin grommet round each hole (the
    # hole's radius, the ring's radius, how far it stands); the twist of its three strands (mm a turn)
    stripe=(4.5, 0.8),            # a printed cream line round the shell this far from each hoop, this wide
    star=13.0,                    # the cream star printed in each V that opens upward (radius, mm)
    roundel=(8.0, 5.4, 3.6),      # the red roundel printed between them: outer, ring's outer and inner radius
    register=(0.35, -0.25),       # the red print's misregistration (mm round, mm up): a real litho's tell
    mark=dict(r=(14.0, 10.0), star=5.5),
    # our maker's mark printed in the V at the back instead of a star: an oval plate (half wide,
    # half tall) rimmed in gold, with the kazoo's star in it; as big as a star, so it reads
    stick=dict(length=190.0, r=(4.5, 3.0), neck=2.6, bead=5.5, grip=40.0, tip=(14.0, 30.0),
               splay=20.0, gap=0.5),
    # each turned beech stick: its length, radius at the butt and where the taper ends, the neck
    # under the bead, the bead's radius; the hand's grip this far from the butt (its pivot); as
    # found its bead rests on the head this far either side of the middle and back from it, the
    # stick splayed this many degrees off straight ahead, resting this far above the rim (mm)
    dust=0.4, seed=113.0,
)

# How it plays (the Bang action): a kid banging it, left, right, left, right, then both sticks
# together, the loud one. Each stick lifts, snaps down onto the head and bounces off; the head
# dips under the hit and shivers back; the whole drum gives a little under each blow.
BANG = dict(
    first=0.22,                   # the first hit lands (s): the game plays a bang at each hit
    beat=0.27,                    # s between hits, about four a second like a kid banging
    hits=4,                       # single hits, left stick first, then the two together
    lift=(30.0, 0.15),            # degrees the tip lifts before a hit, and how long that takes (s)
    snap=0.06,                    # s from the top of the lift down onto the head: it accelerates
    bounce=(9.0, 0.07, 0.08),     # degrees it bounces up off the head, s going up, s coming back
    double=dict(gap=0.58, lift=(44.0, 0.3), bounce=15.0),
    # the double hit: s after the last single hit, a bigger, slower lift, a bigger bounce
    head=(1.5, 2.6),              # mm the head dips under a hit, and under the double
    shiver=(0.45, 0.25, 0.12),    # the head's swings back after the dip, each a fraction of it
    jolt=(0.5, 1.5),              # mm the whole drum gives under a hit, and under the double
    end=2.3,                      # all still by (s)
)

# --- The farm-animal spinner: a talking farm toy of our own, a red barn with a dial ------------
# References (README): the classic talking farm spinner is about 10.5 x 10 x 3 in (267 x 254 x
# 76 mm): a moulded plastic case, a paper litho face of animals in a ring, an arrow over it on
# the dial's axle, pulled by a handle or string, a metal mechanism inside. Ours is a squat red
# barn with a slate-blue gambrel roof, a white bezel round its own printed face
# (spinner_face.py), a yellow lever down its right side and a black weathervane arrow.
SPINNER = dict(
    w=250.0,                      # across the walls (9.8 in)
    d=72.0,                       # front to back, walls (2.8 in)
    eave=206.0,                   # the walls' height, where the roof starts
    knee=(88.0, 252.0),           # the gambrel roof's knees (x either side, z): the barn's tell
    ridge=274.0,                  # the roof line's top (10.8 in), before the roof's own thickness
    rounds=dict(foot=10.0, eave=8.0, knee=6.0, ridge=6.0),
    # the outline's corners rounded this much (mm), as a moulded case's are
    edge=5.0,                     # the front and back edges rounded this much (mm)
    dial=124.0,                   # the dial's middle, this high (mm)
    bezel=[(106.0, 0.0), (106.0, 1.6), (105.2, 3.1), (103.0, 4.0), (99.0, 4.0), (97.5, 2.5), (97.0, -1.5)],
    # the white bezel round the face (r, out from the front mm): it stands 4 proud, square off
    # the front (a smooth foot bends the front's shading into streaks), and the
    # printed face lies 1.5 in, under its lip from r 97 (the print is drawn to r 100)
    collar=[(16.5, -1.5), (16.5, 0.6), (15.6, 1.6), (13.5, 1.9)],
    # the white collar the arrow turns on (r, out from the front mm)
    trim=(6.0, 3.0),              # a white band printed round the front, this far in, this wide
    boards=(14.0, 1.2, 0.35),     # the barn's boards pressed in the case: wide, groove wide, deep (mm)
    roof=dict(t=7.0, over=5.0, eave=10.0, row=11.5, tab=13.0),
    # the roof: its thickness, how far it overhangs front and back, how far it runs past the
    # eaves down its slope, and its pressed shingles' rows up the slope and tabs along it (mm)
    lever=dict(pivot=(105.0, 0.0, 150.0), reach=75.0, w=12.0, t=8.0, knob=15.0, rest=30.0,
               slot=(126.0, 168.0, 8.0)),
    # the yellow lever: its pivot inside the right wall, the knob's middle this far out, the
    # arm this wide (front to back) and thick, the ball knob's radius, raised this many degrees
    # as found; it comes out through a slot in the right wall (z from, z to, half wide)
    arrow=dict(tip=56.0, head=(38.0, 9.0), shaft=2.2, tail=(-26.0, -54.0, 12.0), lift=(4.0, 7.0),
               hub=[(13.0, 0.8), (13.0, 2.0), (12.0, 4.2), (9.5, 6.4), (5.5, 7.8), (0.0, 8.3)]),
    # the black weathervane arrow: its tip this far out, its head's back (r, half wide), the
    # shaft's half width, the swallow-tail fletch (from, to, half wide), how high over the face
    # it lies (mm out from the face), and its brass dome hub (r, out from the front mm)
    screws=[(-95.0, 30.0), (95.0, 30.0), (-72.0, 214.0), (72.0, 214.0)],
    grille=(34.0, 6),             # the round speaker grille on the back: radius (mm), rings of slots
    mark=dict(z=251.0, r=(15.0, 9.5), star=6.0),
    # our maker's mark on the front gable: an oval cream plate rimmed in gold with a red star
    dust=0.45, seed=127.0,
)

# How it plays (the Pull action): a kid pulls the lever down to its stop and lets go; it snaps
# back up, past where it rests, and settles; the snap flicks the arrow, which spins fast,
# slows, then ticks over the last three animals, each a quick hop into the next notch, to stop
# on one. The toy tips a hair toward the lever as it's pulled and hops as the lever slams back.
PULL = dict(
    lift=(-4.0, 0.08),            # the lever first lifts this far (degrees), this long (s)
    down=(70.0, 0.24),            # then comes down this far past rest, in this long (s)
    hold=0.06,                    # held at the bottom (s)
    snap=(-8.0, 0.09),            # let go: back up this far past rest, this fast (s)
    settle=[(3.0, 0.06), (-1.2, 0.05), (0.0, 0.05)],    # two bounces at its stop (degrees, s)
    tilt=0.8,                     # degrees the far side lifts as the lever is pressed down
    hop=0.7,                      # mm the toy hops as the lever slams back to its stop
    spin=dict(after=0.02, free=1170.0, time=1.8),
    # the arrow starts this long after the lever leaves the bottom, and spins this far (three
    # and a quarter turns), slowing all the way, this long (s)
    ticks=[(0.10, 0.12), (0.12, 0.2), (0.15, 0.0)],
    # then three 45-degree hops into the next notch: each this long, then a pause (s)
    wobble=(4.0, -1.5),           # each hop overshoots the notch this far, then back this far
    end=3.45,                     # all still by (s); it stops at 1305 degrees: three turns and
    # five animals on. The game picks the animal by adding a multiple of 45 to every spin key.
)


# --- The pull-string cowboy doll: a 1960s talking doll in its own cowboy clothes ---------------
# References (README): Mattel's 1961 Matty and Sister Belle are 16 in (406 mm) tall, a stuffed
# cloth body sewn to a vinyl face with painted features, yarn hair, a pull-string talker with a
# plastic ring on a cord; the 1964 Drowsy is 14 in with vinyl hands; a 1949 cowboy doll has a
# vinyl face, a felt hat, a fringed vest over a check shirt. Ours sits with its legs out, as
# those photos show them: a ginger kid in a cream felt hat, a green spotted bandana, a blue
# check shirt, a tan suede vest fringed at the hem, jeans turned up over black boots, and a
# white ring on a cord out of the middle of its back. Its own clothes and face: no cow print,
# no star, no brown hat.
DOLL = dict(
    # the stuffed body, seat to neck: (z, half wide, half deep, middle in y) in mm
    torso=[(1.0, 0.0, 0.0, 6.0), (4.0, 44.0, 35.0, 6.0), (14.0, 58.0, 43.0, 5.0),
           (30.0, 63.0, 46.0, 4.0), (52.0, 61.0, 45.0, 4.0), (76.0, 57.0, 43.0, 4.5),
           (100.0, 58.0, 42.0, 5.0), (122.0, 59.0, 40.0, 6.0), (138.0, 56.0, 37.0, 7.0),
           (150.0, 48.0, 33.0, 8.0), (158.0, 35.0, 27.0, 8.0), (164.0, 21.0, 19.0, 8.0),
           (168.0, 0.0, 0.0, 8.0)],
    seam=(0.035, 0.16),           # the sewn side seams pinch the stuffing in this much, this wide
    # (a fraction of the radius, radians): the pillowy look of a stuffed cloth body
    belt=(38.0, 47.0),            # the jeans' belt, z from and to (mm); jeans below it
    hem=55.0,                     # the vest's hem; its fringe hangs from here
    fringe=(27.0, 1.0, 3.2, 26.0),  # the fringe: how long, how far off the body inside and out,
    # and the gap left at the front between the vest's two panels (mm across)
    neck=(0.0, 4.0, 158.0),       # the head nods about X through here
    head=(0.0, -2.0, 224.0),      # the vinyl head's middle and radii: a big round kid's head
    head_r=(54.0, 50.0, 60.0),
    eyes=(19.0, -45.5, 224.0),    # the left eye's middle on the face (the right mirrors it)
    mouth=196.0,                  # the grin's middle, this high
    # the hat: where its brim's middle sits on the head, tipped back this far (degrees), the
    # brim's half sizes, its curl up at the sides, and the crown's base, height and crease
    hat=dict(at=(0.0, 6.0, 262.0), tilt=-11.0, brim=(97.0, 90.0), curl=19.0, dip=4.0,
             crown=(53.0, 49.0), h=58.0, crease=11.0, pinch=0.17, t=3.2),
    shoulder=(57.0, 7.0, 140.0),  # the left shoulder, where the arm is sewn on (the right mirrors)
    elbow=(68.0, -3.0, 90.0),
    wrist=(74.0, -16.0, 46.0),
    arm_r=(21.0, 17.5, 15.0),     # the sleeve's radius at shoulder, elbow and wrist
    hand=(75.0, -21.0, 22.0),     # the vinyl hand's middle, resting on the floor beside the hip
    hip=(31.0, -6.0, 31.0),       # the left leg, hip to ankle (the right mirrors it)
    knee=(37.0, -78.0, 34.0),
    ankle=(40.0, -132.0, 27.0),
    leg_r=(30.0, 26.0, 23.0),
    cuff=(10.0, 2.2),             # the jeans turned up at the ankle: this wide, this proud (mm)
    boot=dict(at=(40.0, -150.0, 46.0), r=(19.0, 15.0, 37.0), lean=-12.0, shaft=22.0),
    # the black boot: its foot's middle and radii (the sole faces you, toes up, as it sits), how
    # far it leans back (degrees), and the shaft's radius where it goes into the jeans
    grommet=(0.0, 47.0, 92.0),    # where the cord comes out of the middle of its back
    pull=-20.0,                   # the cord pulls out this far below level, back and down (degrees)
    cord=(1.1, 66.0, 68.0),       # the white cord's radius and its two runs' lengths (mm): the outer
    # run comes out with the ring; the inner one follows at half the speed, so the cord shows
    # whole from the back to the ring when it's out, and it all hides in the body at rest
    ring=dict(r=15.0, t=2.8, tab=6.0, off=3.5),
    # the white plastic ring: its radius and thickness, the tab it hangs from, how far off the
    # back it hangs
    tag=(-61.0, 62.0),            # the maker's cloth tag sewn into the right side seam (x, z)
    dust=0.5, seed=131.0,
)

# How it plays (the Pull action): a kid hooks the ring, pulls the cord out to its end and lets
# go; the cord creeps back in as the doll talks (a governor in the voice box holds it to the
# speed the line plays at), the arms jiggle and the head bobs with the words, and the ring clacks
# home and flops down against its back. The game starts one of the six lines at `let_go`.
TALK = dict(
    hook=(70.0, 0.12),            # the ring swings up in line with the cord this far, this long
    out=(120.0, 0.40),            # the cord pulled out this far (mm), in this long (s)
    give=1.5,                     # it stretches this much more as it hits its end (mm)
    hold=0.14,                    # held out (s)
    zip=(6.0, 0.04),              # let go: the first bit snaps in this far, this fast
    creep=2.3,                    # then it creeps back the rest of the way in this long (s), the
    # line playing
    flutter=0.07,                 # the governor's speed wobbles this much as it creeps
    clack=(4.0, 0.05),            # the last this-far snaps home this fast (mm, s)
    tip=(-2.4, 1.3),              # the doll tips back this far as you pull (degrees), and rocks
    # forward this far when you let go
    jiggle=(4.5, 5.5),            # the arms flap this far (degrees) this often (a second) as it talks
    nod=(3.5, 2.6),               # the head bobs this far (degrees), on the words
    sway=2.2,                     # and leans side to side this far over the line
    end=3.8,                      # all still by (s)
    seed=7,
)


# --- The singing fish plaque: our own channel catfish on a honey-oak board -----------------------
# References (README): singing fish plaques are 13 x 8 in (a trout on a rock) to about 14 x 10 in
# (the famous bass); a latex rubber fish over a plastic skeleton with three motors (the tail out,
# the body out from the board, the lower jaw down), each sprung back when its motor stops
# (HowStuffWorks' teardown); some stand on a fold-out leg. Ours: a slate-blue speckled channel
# catfish with long whiskers on an arched, routed, varnished oak board, a red button lower right,
# a brass plate with an engraved fish (no words), a speaker grille lower left.
FISH = dict(
    board=(360.0, 245.0, 22.0),     # the board: wide, tall, thick (mm), an arched top, flat foot
    arch=(5.0, 3.0, 150.0, 95.0),   # the outline's squareness below and above, and how far the
    # arch rises above, and the foot sits below, its widest line (mm)
    # the routed edge, back to front: (in from the outline, mm toward the back from the face)
    ogee=[(1.5, 22.0), (0.0, 20.5), (0.0, 13.0), (0.4, 10.5), (1.6, 8.6), (3.6, 7.6), (5.6, 6.6),
          (7.4, 4.8), (8.6, 2.6), (9.2, 0.8), (10.2, 0.0)],
    lean=15.0,                      # degrees it leans back on its fold-out leg
    box=(250.0, 150.0, 26.0, 110.0),  # the black battery and speaker box behind: wide, tall, deep,
    # its middle's height on the board (mm)
    leg=(18.0, 4.0, 150.0),         # the fold-out leg: wide, thick, and its hinge's height (mm)
    # the fish (mm): its tail's tip at x0 on the board, its middle line this high
    x0=-150.0, z=140.0,
    # (w from the tail's tip, bottom and top of the side view about the middle line, half thick
    # toward you and toward the board, how far its back stands off the board)
    body=[(46.0, -13.0, 13.0, 8.0, 5.5, 3.6), (58.0, -14.5, 14.5, 9.0, 6.0, 3.3),
          (70.0, -16.0, 16.0, 11.0, 7.0, 3.0), (82.0, -16.5, 16.5, 11.5, 7.5, 2.5),
          (100.0, -20.0, 21.0, 14.0, 9.0, 2.0), (130.0, -27.0, 27.5, 18.0, 11.0, 1.5),
          (160.0, -33.0, 33.0, 21.0, 12.5, 1.5), (190.0, -37.0, 37.5, 23.5, 13.5, 2.0),
          (215.0, -37.5, 38.0, 25.5, 14.5, 3.0), (240.0, -33.0, 33.0, 27.0, 15.0, 4.5),
          (258.0, -27.0, 27.0, 26.5, 15.0, 6.0), (272.0, -21.0, 20.5, 24.5, 14.0, 7.0),
          (283.0, -14.5, 13.5, 20.0, 11.5, 8.0), (289.0, -8.0, 7.0, 13.0, 7.5, 8.5)],
    snout=291.5, chin=288.0,        # where the upper head's and the chin's rounded ends reach
    arch_up=(4.0, 7.0),             # its back arches: the tail and the head lifted this much (mm)
    knuckle=(82.0, 15.0, 10.0),     # the hinge the body and tail both turn on: w, and the rubber
    # ball's half height and radius there (a ball turning on its own axis never gapes)
    mouth=(238.0, -7.0, 226.0),     # the jaw's hinge (w, height) and where its back end tucks in
    lip=(1.9, 2.2),                 # the upper and lower lips' thickness (mm radius): thin, or
    # they stick out of the snout like a clothes-peg
    eye=(263.0, 11.0, 6.2),         # w, height, radius: a touch bigger than life, to read
    gill=232.0,                     # the gill cover's back edge, at its middle (w)
    tail=dict(curl=16.0, at=60.0, lobe=(64.0, 34.0, 28.0)),  # the tail turns out this many
    # degrees from w=at; its lobes reach back to the tip, this far up and down, the fork this deep
    whisker=dict(long=(70.0, 2.0), nose=(10.0, 0.9), chin=(17.0, 0.95)),  # length, root radius
    button=dict(at=(128.0, 44.0), r=9.0, dome=5.0, bezel=(13.5, 3.0), travel=2.6),
    plate=dict(at=(0.0, 46.0), half=(54.0, 16.0), t=1.4),
    grille=dict(at=(-128.0, 44.0), r=12.5, hole=1.5),
    dust=0.45, seed=31.0,
)

# How it sings when pressed (seconds, degrees). Timed from how the real toys are built: each
# motor drives its piece out quickly and a spring snaps it back, so every move out is a push and
# every move back a snap; the jaw opens on each sung syllable, about four a second.
SING = dict(
    press=(0.0, 0.06, 0.18, 0.27),  # the button: pushed, bottomed, let go, home
    flaps=[0.28, 0.6],              # the tail's two flaps before it sings
    flap=(30.0, 0.12, 0.09, 3.0),   # out this far in this long, snapped back, overshooting this
    out=(0.95, 0.4, 78.0, 6.0),     # the head swings out: starts, takes, how far, overshoot
    beat=0.5,                       # the song's beat: 120 a minute
    sing=1.55,                      # the first sung syllable
    # (beat, length in beats, how wide the mouth opens): two bars, the last note held long
    notes=[(0.0, 0.5, 26.0), (0.5, 0.25, 15.0), (0.75, 0.25, 18.0), (1.0, 0.5, 28.0),
           (1.5, 0.5, 16.0), (2.0, 1.0, 30.0), (3.0, 0.25, 14.0), (3.25, 0.25, 18.0),
           (3.5, 0.5, 22.0), (4.0, 0.5, 28.0), (4.5, 0.25, 16.0), (4.75, 0.25, 20.0),
           (5.0, 0.5, 26.0), (5.5, 0.5, 18.0), (6.0, 1.5, 32.0)],
    beat_flaps=[2.0, 6.0, 6.5],     # the tail flicks on these beats while it sings
    back=(5.6, 0.26, 7.0),          # the head snaps back: starts, takes, how far it bounces off
    last_flap=6.15,                 # one last flap as it settles
    end=6.9,
)


# --- The wind-up tin carousel (F-04j): our own musical merry-go-round, Epic ---------------------
# References (README): a hand-made German tin horse carousel, 8 in tall and 6 in across (Alexander
# Taron's, Christmas Central's listing): an eight-panel printed canopy with a scalloped valance and
# a brass ball on top, a striped centre column, riders on rods; Northlight's carousel music boxes
# (7.25 in by 3.25, 6.5 in by 4.75); the Museo del Juguete's tin carousel (Commons). Ours: a red
# printed drum with a key in its side, a turning platform, a mirrored column, four pressed-tin
# horses on twisted brass poles under a crimson-and-cream canopy with a pennant, 214 mm tall.
CAROUSEL = dict(
    # each lathe's profile, (radius, height) in mm from the floor under the centre pole
    drum=[(0.0, 1.0), (58.0, 1.0), (63.2, 0.2), (65.4, 0.9), (66.6, 2.6), (66.0, 4.4), (65.5, 5.4),
          (65.5, 30.6), (66.0, 31.6), (66.6, 33.4), (65.4, 35.1), (63.0, 35.9), (56.0, 36.3),
          (16.0, 37.3), (13.0, 37.9), (0.0, 37.9)],
    platform=[(0.0, 38.3), (57.0, 38.3), (61.2, 38.6), (62.3, 39.6), (62.3, 41.0), (61.6, 41.6),
              (58.0, 41.9), (0.0, 41.9)],
    column=[(14.5, 41.9), (13.8, 43.4), (11.2, 45.0), (10.2, 47.5), (10.0, 50.0), (10.0, 140.0),
            (10.6, 142.0), (11.6, 143.8), (11.2, 145.6), (9.6, 146.6)],
    # the canopy: underside out from the column, the rolled rim, then a tent-like cone that rises
    # steeper toward the top (rise mm over the cone, its power), to a collar under the finial
    under=[(0.0, 146.4), (9.6, 146.4), (40.0, 148.6), (74.0, 150.8)],
    rim=[(76.2, 151.2), (77.3, 152.4), (77.0, 153.8), (75.6, 154.6)],
    cone=(75.6, 13.0, 28.0, 1.3),
    collar=[(11.0, 183.4), (10.4, 185.6), (0.0, 186.0)],
    finial=[(0.0, 185.8), (6.0, 186.3), (6.5, 187.8), (4.0, 189.4), (3.2, 190.2), (4.6, 191.6),
            (5.0, 194.0), (4.6, 196.4), (3.0, 198.6), (1.0, 204.5), (0.0, 206.0)],
    flag=dict(rod=(0.65, 198.0, 215.0), at=(209.0, 214.0), length=15.0, wave=1.6, t=0.6),
    # the valance under the rim: scallops (count, the tips' height, how high the cusps rise)
    valance=dict(n=16, top=152.6, tip=139.0, cusp=4.5, r=(77.4, 78.6), t=0.5),
    # four horses on twisted brass poles (radius from the centre, radius of the pole, its twist:
    # one lobe round in this many mm), each at an angle round; the saddle's height at mid stroke
    poles=dict(r=50.0, rod=1.6, twist=14.0, lobes=4, depth=0.17, z=(41.9, 149.6)),
    horse_at=[45.0, 135.0, 225.0, 315.0],
    saddle_z=95.0,
    # a pressed-tin horse: two halves crimped round a flat seam (flange mm out, its half
    # thickness), puffed out up to `puff` mm, rising over `soft` mm in from the seam; drawn as
    # round pieces in its side view (mm: x forward, z up, from the pole at the saddle's top)
    flange=(0.55, 0.3), puff=4.0, soft=2.4,
    ellipses=[(-2.0, -8.0, 16.0, 8.5)],
    circles=[(10.0, -7.0, 8.0), (-12.0, -6.5, 8.5), (19.5, 12.0, 4.4)],
    # tapered pieces (from x, z, to x, z, radius at each end): neck, head, ear, legs, tail
    capsules=[(9.0, -3.0, 17.0, 13.0, 7.0, 4.5), (18.0, 15.0, 26.5, 7.2, 4.2, 3.0),
              (16.4, 18.0, 15.8, 22.6, 1.6, 0.55),
              (11.0, -12.0, 19.5, -17.0, 3.2, 2.2), (19.5, -17.0, 16.5, -24.0, 2.0, 1.7),
              (16.5, -24.0, 17.6, -25.6, 2.0, 2.0),
              (7.5, -13.0, 12.5, -21.0, 3.2, 2.1), (12.5, -21.0, 10.5, -28.0, 2.0, 1.7),
              (10.5, -28.0, 11.6, -29.6, 2.0, 2.0),
              (-13.0, -11.0, -20.0, -22.0, 5.0, 2.3), (-20.0, -22.0, -18.5, -30.0, 2.1, 1.7),
              (-18.5, -30.0, -18.2, -32.0, 2.0, 2.0),
              (-8.5, -12.5, -13.0, -23.0, 4.0, 2.2), (-13.0, -23.0, -10.0, -30.5, 2.1, 1.7),
              (-10.0, -30.5, -9.4, -32.4, 2.0, 2.0),
              (-17.0, -2.0, -23.0, -5.0, 2.6, 2.8), (-23.0, -5.0, -26.0, -11.0, 2.8, 2.4),
              (-26.0, -11.0, -25.0, -18.0, 2.4, 1.3),
              # the saddle's cantle and pommel, stamped up proud of the back
              (-7.6, 0.2, -7.9, 2.9, 1.5, 1.1), (2.7, 0.4, 3.2, 2.6, 1.3, 0.95)],
    blend=(2.2, 0.9),               # how softly the body's pieces join, and the legs' and hooves'
    key=dict(at=(65.5, 0.0, 18.0), shaft=(1.5, 9.5), hub=(2.6, 3.0), wing=(6.4, 7.4), t=1.3),
    dust=0.4, seed=37.0,
)

# How it plays (seconds, degrees, mm). A spring under the drum turns the platform, canopy and
# column together about the centre pole; a crank under the canopy, geared to the turning, lifts
# each horse up and down its pole twice a revolution, each out of step with the next. Paced like
# a carousel music box: a turn in four seconds, the tune at that speed, both slowing over the
# last six seconds as the spring runs down (the game plays the tune at the top's speed).
RIDE = dict(
    speed=90.0,                     # degrees a second, full wound
    spin_up=0.9,                    # seconds to come up to speed
    steady=9.5,                     # when the spring starts to run down
    stop=15.5,                      # when it has stopped
    fade=1.4,                       # the run-down's curve: the speed falls as (1 - s) ** fade
    rock=(1.6, 0.6),                # the gears' slack: it rocks back this far, then settles
    bobs=2.0,                       # each horse's rises a revolution
    lift=9.0,                       # each horse's rise and fall either side of mid stroke (mm)
    phase=[0.25, 0.75, 0.0, 0.5],   # each horse's place in its stroke as it's found
    winds=4,                        # half turns of the key to wind it
    end=16.4,
)


# --- The game rows (F-G1f, D-265; art/finds/PIPELINE.md) ----------------------------------------
# What the game deals and plays for each find, in the order the deal lists them. art/finds/rows.py
# (plain Python: `scripts/art.sh rows`, and every export) writes them into
# src/shared/Finds/Rows.luau; never edit that file. `catalog` is the find's line in the item
# catalog as art/finds/WAVES.md's table names it: a find is dealt once that line is ticked built.
# Grade and worth are the catalog's; `from_` the lowest floor it's dealt on (none: floor 1); its
# grip in studs from the middle of its bottom (across, up, front to back); heft how heavy it feels
# (0 to 1); size where it sits in your view; `press` its one press (Finds/Use's row).
from game import (  # noqa: E402
    ACROSS_THE_FLOOR,
    AS_FAR_AS_THE_HORN,
    CAROUSEL_TUNE,
    CLACK,
    CLANG,
    CLANK,
    CLASH,
    CLICK_ON,
    CLINK,
    COW,
    CRUNCH,
    DOG,
    DOWN_THE_HALL,
    EEK,
    DRUM_HIT,
    DUCK,
    HOLLOW,
    HORSE,
    HUM,
    LEVER,
    MEOW,
    MOTOR,
    MUSIC_BOX,
    PIG,
    PLASTIC,
    POP,
    ROOSTER,
    SHEEP,
    SLAP,
    SNAP,
    SOFT,
    SQUEAK,
    TICK,
    TIN,
    WHIRR,
    WHISTLE,
    WIND,
    pitched,
    squeeze,
)

GAME = [
    dict(
        key="CymbalMonkey",
        catalog="Cymbal monkey",
        name="Cymbal monkey",
        grade="Rare",
        worth=40,
        grip=(0, 0.55, 0),  # round its middle
        heft=0.3,
        size="Medium",
        pickUp=pitched(CLANG, 1.5),
        drop=pitched(TIN, 1.15),
        # "Wind: it bashes its cymbals for 20 seconds, loud", "the strongest lure in the set":
        # every monster on the floor keeps coming to it, every 2 seconds, until it stalls
        press=dict(
            verb="Wind",
            on=[
                dict(motion="Wind", sound=WIND),
                dict(motion="Play", hit=dict(part="CymbalMonkey_ArmL", sound=CLASH)),
            ],
            noise="Play",
            lure=2,
            toy=True,
        ),
    ),
    dict(
        key="JackInTheBox",
        catalog="Jack-in-the-box",
        name="Jack-in-the-box",
        grade="Uncommon",
        worth=18,
        grip=(0, 0.45, 0),  # the tin box, shut
        heft=0.3,
        size="Medium",
        pickUp=pitched(SLAP, 1.1),
        drop=TIN,
        # "Wind: a tune, then a bang as it pops. The bang comes a few seconds after you let go":
        # wind it, set it down, walk away, and see what comes to look
        press=dict(
            verb="Wind",
            on=[dict(motion="Wind", sound=MUSIC_BOX), dict(motion="Pop", sound=POP)],
            reset=dict(motion="Shut"),
            noise="Pop",
        ),
    ),
    dict(
        key="Kazoo",
        catalog="Kazoo",
        name="Kazoo",
        grade="Common",
        worth=2,
        grip=(0, 0.05, 0.05),  # its tube, behind the bump
        heft=0.02,
        size="Small",
        pickUp=pitched(CLACK, 1.9, 0.6),
        drop=pitched(PLASTIC, 2.1, 0.4),
        # "Blow: a buzzy note": lifted to your lips, it hums one note as its paper skin buzzes,
        # and monsters down the hall turn to it (Lethal Company's airhorn, a toy's worth)
        press=dict(
            verb="Blow",
            on=[dict(motion="Blow", cues=[dict(at=0.36, sound=HUM)])],
            noise="Blow",
            heard=DOWN_THE_HALL,
            toy=True,
        ),
    ),
    dict(
        key="RubberDuck",
        catalog="Squeaky rubber duck",
        name="Rubber duck",
        grade="Common",
        worth=3,
        grip=(0, 0.15, 0),  # round its body
        heft=0.04,
        size="Small",
        pickUp=pitched(HOLLOW, 1.7, 0.6),
        drop=pitched(HOLLOW, 1.4, 0.55),
        # "Squeeze: a squeak you can hear down the hall": it squashes and squeaks, and every
        # monster within a hall's length turns to look
        press=squeeze(SQUEAK, noisy=True),
    ),
    dict(
        key="SirenCar",
        catalog="Toy siren car",
        name="Siren car",
        grade="Common",
        worth=5,
        grip=(0, 0.14, 0),  # round its middle, under the light bar
        heft=0.06,
        size="Small",
        pickUp=pitched(CLACK, 1.6),
        drop=pitched(PLASTIC, 1.8, 0.5),
    ),
    dict(
        key="ChatteringTeeth",
        catalog="Wind-up chattering teeth",
        name="Chattering teeth",
        grade="Common",
        worth=6,
        grip=(0, 0.12, 0),  # round the jaws, shut
        heft=0.05,
        size="Small",
        pickUp=pitched(CLACK, 1.75),
        drop=pitched(PLASTIC, 1.9, 0.5),
        # "They chatter off across the floor; monsters come to look": wound and set down, they
        # chatter away, a clack each snap, and every monster across the floor keeps turning to
        # where they are now, every 2 seconds, until they run down; a wall stops them going,
        # not chattering (R.E.P.O.'s music box; the monkey's lure)
        press=dict(
            verb="Wind",
            on=[
                dict(motion="Wind", sound=WIND),
                dict(motion="Chatter",
                     hit=dict(part="ChatteringTeeth_Base", channel="pitch", sound=SNAP)),
            ],
            noise="Chatter",
            heard=ACROSS_THE_FLOOR,
            lure=2,
            toy=True,
            down=True,
            walks=True,
        ),
    ),
    dict(
        key="ToyDrum",
        catalog="Toy drum",
        name="Toy drum",
        grade="Uncommon",
        worth=10,
        grip=(0, 0.3, 0),  # its tin shell
        heft=0.3,
        size="Medium",
        pickUp=pitched(SLAP, 1.15),
        drop=pitched(TIN, 0.95),
        # "Bang: loud": left, right, left, right, then both sticks together, a bang at each hit
        # as the drum gives under it, and every monster as far as an air horn carries comes to
        # look (Lethal Company's airhorn)
        press=dict(
            verb="Bang",
            on=[dict(motion="Bang", hit=dict(part="ToyDrum_Body", channel="y", sound=DRUM_HIT))],
            noise="Bang",
            heard=AS_FAR_AS_THE_HORN,
            toy=True,
        ),
    ),
    dict(
        key="WindupMouse",
        catalog="Wind-up mouse",
        name="Wind-up mouse",
        grade="Uncommon",
        worth=12,
        grip=(0, 0.09, 0),  # round its tin body
        heft=0.04,
        size="Small",
        pickUp=pitched(SLAP, 1.6, 0.55),
        drop=pitched(TIN, 1.75, 0.55),
        # "It zips off and squeaks wherever it stops": wound and set down, it zips away on its
        # wheels, slows as the spring gives out, stalls, rocks onto its nose and squeaks there;
        # monsters down the hall keep turning to where it is now; at a wall its wheels buzz on
        press=dict(
            verb="Wind",
            on=[
                dict(motion="Wind", sound=WIND),
                dict(motion="Zip", hit=dict(part="WindupMouse_Body", channel="pitch", sound=EEK)),
            ],
            noise="Zip",
            heard=DOWN_THE_HALL,
            lure=2,
            toy=True,
            down=True,
            walks=True,
        ),
    ),
    dict(
        key="WalkingRobot",
        catalog="Wind-up walking robot",
        name="Wind-up robot",
        grade="Uncommon",
        worth=15,
        grip=(0, 0.45, 0),  # round its chest
        heft=0.15,
        size="Small",
        pickUp=pitched(SLAP, 1.35),
        drop=pitched(TIN, 1.35),
        # "It clanks off in a straight line for 15 seconds": wound and set down, it walks off a
        # clank each footfall, and every monster across the floor keeps turning to where it is
        # now; a wall stops it going, not stamping (R.E.P.O.'s music box; the monkey's lure)
        press=dict(
            verb="Wind",
            on=[
                dict(motion="Wind", sound=WIND),
                dict(motion="Walk",
                     hit=dict(part="WalkingRobot_Body", channel="pitch", sound=CLANK)),
            ],
            noise="Walk",
            heard=ACROSS_THE_FLOOR,
            lure=2,
            toy=True,
            down=True,
            walks=True,
        ),
    ),
    dict(
        key="FarmSpinner",
        catalog="Farm-animal spinner",
        name="Farm spinner",
        grade="Uncommon",
        worth=16,
        grip=(0, 1.0, 0),  # the handle on its top
        heft=0.35,
        size="Large",
        pickUp=pitched(HOLLOW, 1.0),
        drop=pitched(PLASTIC, 1.0),
        # "Pull: the arrow spins and an animal noise plays": the lever slams back up, the arrow
        # spins, slows and ticks into its last three notches, and the animal it stops on calls
        # through the speaker; monsters down the hall turn to it. The server picks the animal
        # each pull, never the one it's on, and every screen bends the spin to end there
        # (F-G1e3d): the face's eight clockwise from the cow the arrow is made pointing at, an
        # eighth (45 degrees) apart; the art's own spin is 29 eighths, to the cat
        press=dict(
            verb="Pull",
            on=[dict(motion="Pull", hit=dict(part="FarmSpinner_Arrow", sound=TICK),
                     cues=[dict(at=0.47, sound=LEVER)],
                     lands=dict(part="FarmSpinner_Arrow", every=45, at=3.2,
                                calls=[COW, PIG, SHEEP, HORSE, DUCK, MEOW, ROOSTER, DOG]))],
            noise="Pull",
            heard=DOWN_THE_HALL,
            toy=True,
        ),
    ),
    dict(
        key="CowboyDoll",
        catalog="Pull-string cowboy doll",
        name="Cowboy doll",
        grade="Rare",
        worth=45,
        grip=(0, 0.75, 0),  # round its chest, under the hat
        heft=0.25,
        size="Medium",
        pickUp=SOFT,
        drop=pitched(SOFT, 0.75, 0.6),
        # "Pull: it says one of six lines": the ring pulled out and let go, the cord creeps home
        # as it talks and clacks in; monsters down the hall turn to it. Until its lines are
        # recorded (OWNER.md) you hear the cord's whirr under its governor
        press=dict(
            verb="Pull",
            on=[dict(motion="Pull",
                     cues=[dict(at=0.62, sound=WHIRR), dict(at=3.01, sound=pitched(CLACK, 1.6, 0.5))])],
            noise="Pull",
            heard=DOWN_THE_HALL,
            toy=True,
        ),
    ),
    dict(
        key="SingingFish",
        catalog="Singing fish plaque",
        name="Singing fish",
        grade="Rare",
        worth=50,
        grip=(0, 0.8, 0),  # the plaque's top edge
        heft=0.4,
        size="Large",
        pickUp=pitched(HOLLOW, 0.95),
        drop=pitched(CRUNCH, 0.9),
        # "Press: its head turns and it sings": the button clicks in, the tail flaps, the head
        # swings out and sings two bars, then snaps back and knocks the board twice; monsters
        # down the hall turn to it. Until its song is recorded (OWNER.md) its motors hum
        press=dict(
            verb="Press",
            on=[dict(motion="Press", sound=CLICK_ON,
                     cues=[dict(at=0.28, sound=MOTOR), dict(at=5.86, sound=pitched(HOLLOW, 1.15, 0.5)),
                           dict(at=6.04, sound=pitched(HOLLOW, 1.25, 0.3))])],
            noise="Press",
            heard=DOWN_THE_HALL,
            toy=True,
        ),
    ),
    dict(
        key="TinBird",
        catalog="Clockwork tin bird",
        name="Tin bird",
        grade="Epic",
        worth=140,
        grip=(0, 0.12, 0),  # round its tin body
        heft=0.06,
        size="Small",
        pickUp=pitched(CLINK, 1.6),
        drop=pitched(TIN, 1.85, 0.55),
        # "It hops and whistles": wound and set down, it hops off in threes and whistles two
        # notes at each stop, lower and slower as it runs down; monsters across the floor keep
        # turning to where it is now
        press=dict(
            verb="Wind",
            on=[
                dict(motion="Wind", sound=WIND),
                dict(motion="Hop", hit=dict(part="TinBird_Beak", sound=WHISTLE)),
            ],
            noise="Hop",
            heard=ACROSS_THE_FLOOR,
            lure=2,
            toy=True,
            down=True,
            walks=True,
        ),
    ),
    dict(
        key="TinCarousel",
        catalog="Wind-up tin carousel",
        name="Tin carousel",
        grade="Epic",
        worth=200,
        grip=(0, 0.75, 0),  # the pole under its canopy
        heft=0.4,
        size="Medium",
        pickUp=pitched(CLANG, 1.3),
        drop=pitched(TIN, 1.0),
        # "It turns and plays a tune": wound where it stands, it turns and plays its music box
        # tune until the spring runs down, and monsters down the hall keep coming to it (the
        # cymbal monkey's lure, quieter)
        press=dict(
            verb="Wind",
            on=[dict(motion="Wind", sound=WIND), dict(motion="Play", sound=CAROUSEL_TUNE)],
            noise="Play",
            heard=DOWN_THE_HALL,
            lure=2,
            toy=True,
        ),
    ),
]
