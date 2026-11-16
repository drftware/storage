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

# --- The mochi bun (F-05b2) ----------------------------------------------------------------------
# References (README): powdered daifuku (Wikimedia Commons, "Assortment of mochis from the Niji
# store (in Barcelona)"), about 55 to 60 mm across, a soft dome slumped onto the plate, its side
# rolling under to a smaller footprint, dusted with white starch: thick, cracked patches on top,
# thin wisps down the sides with the colour showing through. Mochi and bun squishies sold in 2026
# run from 2 in minis to 5.5 in jumbos (a 5 x 1 in custard bun, walmart.com/ip/17278610743); ours
# is a palm-sized TPR mochi squishy in sakura pink, dusted with powder as real ones are to stop
# them sticking, a tiny two-dot face of our own printed low on its front.
MOCHI = dict(
    r=36.0,           # its widest radius, a third of the way up (mm): 72 mm, 2.8 in across
    h=42.0,           # its height (mm): 1.65 in
    belly=13.0,       # how high its widest point stands (mm); below it the side rolls under
    foot=23.0,        # the flat footprint's radius it sits on (mm)
    round_top=2.25,   # the dome's superellipse power: 2 an ellipse, more a fuller, flatter top
    oval=(1.015, 0.985),  # a hair wider than deep, slumped
    lean=(0.035, 0.025),  # its top slumped this far aside and back, per mm of height
    # the face, printed on its front (mm across and up the front, seen straight on): the eyes'
    # half spacing, height, and size (half width, half height); the smile's centre, radius, ends
    # (degrees) and stroke; the blush's offset, size (half width, half height) and softness
    eye_dx=8.2, eye_z=20.5, eye_w=1.45, eye_h=1.9,
    smile_c=(0.0, 18.4), smile_r=2.2, smile_a=(205.0, 335.0), smile_w=0.85,
    blush_dx=12.5, blush_z=17.0, blush_w=3.6, blush_h=2.1,
    dust=0.15, seed=23.0,
)

# The squeeze, timed like a TPR mochi squishy in the hand: no spring at all. The fingers close
# and it gives slowly, then all at once, sagging wide under the palm; held, it creeps a little
# flatter; let go, it heaves most of the way back in half a second and then settles into shape
# over another second and a half, never past round (seconds, height[, style, way]).
SINK = [
    (0.0, 1.0),
    (0.12, 0.97, "Sine", "In"),       # the fingers meet it: it barely gives
    (0.55, 0.6, "Quad", "InOut"),     # then sinks, heavy, spreading under the palm
    (1.0, 0.57, "Sine", "Out"),       # held: it creeps a little flatter
    (1.08, 0.57),                     # let go
    (1.62, 0.87, "Quad", "Out"),      # heaves most of the way back
    (2.5, 0.982, "Sine", "Out"),      # and settles slowly, never past round
    (3.2, 1.0, "Sine", "InOut"),
]

# --- The squishy toast slice (F-05b3) -----------------------------------------------------------
# References (README): toast-slice squishies sold in 2026 are PU foam slices 4.3 to 5.4 in tall
# and wide and 1.1 to 1.9 in thick (one 4.3 in, one 5.4 x 5.4 x 1.9 in), the slice's outline a
# square base under a wider rounded crown that overhangs it a little at the shoulders, the crust
# airbrushed golden brown round the edge and darker over the crown, the crumb face pale cream,
# often with a cute face printed low on it. Ours: 4.4 in tall, 4.1 in across the crown, 1.1 in
# thick, standing on its bottom crust; a face of our own.
TOAST = dict(
    # its outline seen from the front, the right half from the bottom's middle up and over to the
    # top's middle (mm across, mm up); a smooth curve runs through these points
    outline=[(0.0, 0.0), (18.0, 0.0), (34.0, 0.15), (41.5, 1.4), (45.0, 6.0), (46.0, 14.0),
             (46.2, 32.0), (45.9, 50.0), (45.4, 58.0), (46.4, 64.5), (49.6, 69.0), (52.0, 75.0),
             (52.2, 83.0), (49.8, 92.0), (44.0, 100.0), (35.0, 106.0), (24.0, 109.6),
             (12.0, 110.4), (0.0, 109.2)],
    thick=28.0,       # front face to back face (mm): 1.1 in
    edge=5.5,         # how round the faces' edges are (mm)
    # the crust: its band on the face (mm in from the outline), deeper over the crown (from the
    # shoulders up), then a toasted glow fading into the crumb over this much more
    crust=5.0, crust_top=8.5, toasted=11.0,
    # the face, printed low on the front (mm across and up, seen straight on): the eyes' half
    # spacing, height and size (half width, half height); the mouth's centre, half width, depth
    # and stroke; the blush's offset, size and height
    eye_dx=13.5, eye_z=52.0, eye_w=2.55, eye_h=3.3,
    mouth_c=(0.0, 46.0), mouth_w=3.9, mouth_d=3.1, mouth_line=0.8,
    blush_dx=20.5, blush_z=46.0, blush_w=4.6, blush_h=2.7,
    dust=0.15, seed=31.0,
)

# The squeeze, timed like a bread squishy in the hand: the fingers close and it gives fast, the
# crumb crushing down under the thumb; held a moment; let go, it springs back up like real bread,
# a little past its shape, dips under and settles inside two thirds of a second, softer than the
# rubber ball's ring (seconds, height[, style, way]).
SPRING = [
    (0.0, 1.0),
    (0.06, 1.015, "Sine", "Out"),     # the fingers meet it: it bulges a hair
    (0.24, 0.75, "Quad", "Out"),      # crushed under the thumb
    (0.62, 0.735, "Sine", "InOut"),   # held, still pressing
    (0.68, 0.74),                     # let go
    (0.82, 1.05, "Quad", "Out"),      # springs back up past its shape
    (0.96, 0.972, "Sine", "InOut"),
    (1.1, 1.008, "Sine", "InOut"),
    (1.26, 1.0, "Sine", "InOut"),
]

# --- The jumbo slow-rise strawberry (F-05c) -----------------------------------------------------
# References (README): jumbo strawberry squishies sold in 2026 run 4.5 to 6.3 in (Sunny Days'
# Squeezy Strawberry 5 x 5 x 5 in; a Walmart "extra large" 5 in; a half jumbo 13 cm tall): a fat
# rounded cone, widest a little over half way up, a broad rounded tip it stands on, rich red PU
# foam airbrushed lighter over the shoulder, rows of little yellow teardrop seeds printed in
# shallow pits, a flat green cap of pointed leaves lying over the top round a short stem. Ours is
# 4.9 in tall and 4.4 in across, six leaves of our own, long and short in turn.
STRAWB = dict(
    # its outline, the floor to the top's middle (mm out from its middle, mm up); a smooth curve
    # runs through these points: a little flat spot it settles on, the rounded tip, widest 62 per
    # cent up, the shoulder rolling over into a shallow dip where the cap sits
    outline=[(0.0, 0.0), (8.0, 0.0), (16.0, 1.5), (25.0, 6.6), (33.5, 16.0), (42.5, 30.0),
             (49.5, 46.0), (54.2, 62.0), (56.2, 76.0), (55.2, 89.0), (51.0, 101.0),
             (43.0, 111.0), (31.0, 118.0), (17.0, 121.4), (7.0, 121.0), (0.0, 120.2)],
    lobes=0.022,      # three broad lobes round it (share of the radius), as a real berry has
    oval=(1.015, 0.985),
    lean=(0.028, -0.012),  # its top slumped this far aside and toward you, per mm of height
    # the game mesh: points round each ring (closest together at the front, where the dent goes:
    # `crowd` 0 even, 0.5 the front's half as far apart as the average), rings this far apart
    # through the dent's heights and further elsewhere (the detailed mesh halves them all)
    around=80, crowd=0.5, ring_fine=2.2, ring=5.0, fine=(46.0, 102.0),
    # the seeds: printed yellow teardrops (long, wide, mm) in shallow round pits, in staggered
    # rows this far apart up the berry and round it, none on the flat spot or under the cap
    seed_l=3.4, seed_w=2.0, pit=5.0, row=10.5, pitch=12.5, seed_from=7.0, seed_to=26.0,
    # the cap: six leaves round the stem (long and short in turn, mm along the berry's skin from
    # the top's middle), their widest (half width, mm), how high their tips curl off the skin,
    # how thick they are at the base and tip, the midrib's groove; the hub they grow from (its
    # radius, how high) and the stem (its radius, length, tilt in degrees)
    leaves=6, leaf_l=(47.0, 38.0), leaf_w=12.5, leaf_lift=3.4, leaf_t=(3.6, 1.5), groove=0.8,
    hub_r=11.0, hub_h=4.6, stem_r=3.9, stem_l=12.0, stem_tilt=13.0,
    # the thumb's dent, on its front a little right of the middle: its middle (degrees round from
    # the front, mm up), its radius and how deep it goes, how far its sides tip toward the middle
    # at its deepest (degrees), and the bones round it
    dent=(8.0, 74.0), dent_r=23.0, dent_d=12.0, tilt=32.0, rims=8,
    dust=0.2, seed=37.0,
)

# The squeeze, timed like a jumbo slow-rise squishy in the hand: a thumb pressed deep into its
# side, slowing as the foam fights it, held, let go: a little give back at once, then the dent
# rises slowly, quickest first, and creeps the last of the way smooth ten seconds after the thumb
# let go (listings: "slow rising"; the catalog's "ten seconds to rise back"). (seconds, how far
# in: 0 none, 1 the full dent[, style, way])
RISE = [
    (0.0, 0.0),
    (0.38, 1.0, "Quad", "Out"),     # the thumb goes in deep
    (1.1, 1.0),                     # held
    (1.4, 0.92, "Sine", "Out"),     # let go: the first little give back
    (4.4, 0.48, "Quad", "Out"),     # the slow rise, quickest first
    (11.1, 0.0, "Sine", "Out"),     # creeping the last of the way smooth
]

# --- The squishy capybara (F-05c2) ---------------------------------------------------------------
# References (README): capybara slow-rise squishies sold in 2026 run from 2 in minis to jumbos;
# a standard one is 3.5 in long and 3 in tall, moulded PU foam in two halves (a faint seam down
# the middle), satin brown with a dot eye and a little nose; a jumbo sits up with a darker muzzle.
# Real capybaras (Commons) have a long box of a head, its top straight from the small round ears
# high at the back to a deep, blunt muzzle with the nostrils high on its front, eyes high on the
# sides, and a barrel body that lies flat on its belly with the legs tucked under. Ours lies like
# that, as a loaf: 4.3 in long, 2.6 in wide, 2.1 in tall (2.7 with its mandarin), head two fifths
# sleepy half-shut eyes and a little mandarin balanced on its head, as capybaras in hot springs
# wear one. Lengths in mm; y from its tail (+) to its nose (-), z up from the floor.
CAPY = dict(
    # its sides, tail to nose: (y, half width, belly line, widest line, top) at each station
    stations=[
        (30.0, 28.5, 1.0, 22.5, 49.0),     # the rump, where it starts to round off
        (22.0, 31.5, 0.0, 23.0, 53.0),     # the haunches, highest
        (6.0, 33.0, 0.0, 23.5, 52.5),      # the belly, widest
        (-8.0, 31.0, 0.0, 25.0, 50.5),     # the shoulders
        (-15.0, 28.0, 1.0, 28.0, 50.0),    # the neck, a soft dip in the top line
        (-22.0, 27.5, 3.0, 30.0, 54.0),    # the crown behind the eyes, where the ears sit
        (-33.0, 25.5, 5.5, 30.0, 52.0),    # the cheeks
        (-43.0, 21.5, 7.5, 28.5, 48.0),    # the muzzle
        (-47.0, 20.5, 8.0, 28.0, 47.0),    # where the nose starts to round
    ],
    p_top=(2.3, 2.9),   # how square its top half is: the body round (2), the head boxier
    p_bot=(3.4, 2.8),   # and its underside, flat where it lies
    head_from=-14.0,    # where the head's squarer shape takes over (y)
    # its ends, each rounded off over this length; the second number how blunt (2 a round dome,
    # more a flatter face with rounded edges): the rump round, the muzzle's front blunt
    tail_end=(21.0, 2.3), nose_end=(10.0, 3.4),
    # the ears, small and round, high at the back of the head: centre (x, y, how far over the
    # skin), radius, and the way they face (out, forward, up)
    ear=(18.0, -17.0, 0.4), ear_r=5.6, ear_out=(0.66, -0.12, 0.74),
    # the paws peeking out under it: (x, y, half sizes across, along, up)
    paws=[(14.5, -16.5, 6.2, 8.4, 4.6), (25.0, 31.0, 7.0, 10.5, 5.2)],
    # the mandarin on its head: where it sits (y, how far its bottom sinks in), radius, how
    # squat, its tilt (degrees about x and y)
    orange=(-25.0, 0.6), orange_r=9.0, orange_squat=0.84, orange_tilt=(8.0, -6.0),
    leaf=(8.5, 3.6, 0.9),   # its leaf: length, half width, half thickness (mm)
    # the face: the eyes seen from 62 degrees round from straight ahead, centred this far back,
    # up and out; their size; the lid's height over the centre at its ends (what's left showing
    # below it is the sleepy half-shut eye) and how much it arches up in the middle
    eye_turn=62.0, eye_y=-37.0, eye_z=41.0, eye_w=3.6, eye_h=3.2, lid=-0.35, arch=0.75,
    blush=(-1.0, -6.8, 4.4, 2.5),   # the blush below each eye: offset, half width, half height
    nose_z=40.0, nose_w=6.4, nose_h=3.5,   # the nose, high on the muzzle's front
    mouth_z=33.2, mouth_r=1.7, mouth_w=0.62,
    dust=0.15, seed=31.0,
)

# The squeeze, timed as a contented sigh: as the fingers close it draws a little breath, then
# lets it all out, sinking slow and settling wide, its sleepy eyes squeezed nearly shut; held,
# content; let go, it breathes back up over a second with a soft settle, never past its shape
# (seconds, height[, style, way]).
SIGH = [
    (0.0, 1.0),
    (0.22, 1.03, "Sine", "InOut"),    # a little breath in
    (0.84, 0.8, "Quad", "InOut"),     # and the long sigh out, sinking wide
    (1.25, 0.785, "Sine", "Out"),     # held, content, settling a touch more
    (1.35, 0.785),                    # let go
    (2.15, 0.972, "Quad", "Out"),     # it breathes back up
    (2.6, 1.0, "Sine", "InOut"),      # and settles into shape
]

# The mandarin rides the sigh a beat behind, as a loose thing balanced on a moving head does: it
# barely tips back as the breath comes in, rocks forward as the head sinks, and when the head
# breathes back up it rocks back and forth once and settles (seconds, degrees forward).
ROCK = [
    (0.0, 0.0),
    (0.3, -1.0),
    (0.95, 2.6, "Sine", "InOut"),
    (1.4, 0.7, "Sine", "InOut"),
    (1.75, -3.0, "Sine", "InOut"),
    (2.15, 1.8, "Sine", "InOut"),
    (2.5, -0.7, "Sine", "InOut"),
    (2.85, 0.0, "Sine", "InOut"),
]
