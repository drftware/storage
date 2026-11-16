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
