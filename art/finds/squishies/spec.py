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

# --- The paper squishy with a drawn face (F-05c3) -------------------------------------------------
# References (README): kids' homemade paper squishies (One Little Project's food templates, Craftsy
# Hacks' blue cat, Red Ted Art's emoji faces): two sheets of printer paper cut to one outline,
# coloured in with marker inside a thick black line drawn round the edge, covered front and back
# in strips of clear 2 in packing tape laid across, the front's tape cut into tabs round the
# curves and folded over onto the back, stuffed with fibre fill or shredded plastic bags through
# the bottom, which a last strip seals, so it puffs like a little pillow. Templates print one to a
# letter page; Craftsy Hacks' cat is as wide as the hand holding it. Ours is a ginger cat's head of
# our own, 4.6 in wide and 4.4 in tall to its ear tips, 1.4 in thick at its puffiest.
PAPER = dict(
    # its outline seen from the front, the right half from the chin's middle round the cheek, up
    # the ear and over to the top's middle (mm across, mm up); a smooth curve runs through them
    outline=[(0.0, 0.0), (16.0, 0.7), (31.0, 3.6), (43.5, 10.0), (52.5, 20.5), (57.4, 33.0),
             (58.2, 46.0), (56.0, 58.0), (51.8, 68.5), (49.8, 79.0), (48.6, 90.0), (47.0, 99.5),
             (44.6, 105.0), (41.0, 104.6), (33.5, 97.6), (25.0, 90.6), (16.0, 88.4), (8.0, 89.2),
             (0.0, 89.5)],
    centre=46.0,       # the point its faces' rings shrink toward (mm up the middle)
    puff=16.0,         # how far each face puffs out at its middle (mm): stuffed, not overstuffed
    puff_p=2.1,        # how steeply each face rises off the seam (a pillow's, not a ball's)
    smooth=110,        # how much the stuffing rounds off the pinch lines into the ears
    seam=0.7,          # half the taped seam's thickness round the edge (mm)
    lean=12.0,         # tipped back this far (degrees), its face turned up a little to you
    # the marker line round the edge: its width and how far in from the cut edge it runs
    line=2.8, line_in=1.9,
    dust=0.08, seed=37.0,
)

# The squeeze, timed like crumpling a taped paper pouch: the fingers close and it gives in little
# crunching jumps as creases buckle, never smoothly; held flat; let go, it puffs back unevenly, a
# quick pop part way, a stall on a crease, a second pop, a slow creep and a last crackle, and
# never springs past its shape (paper has no spring) (seconds, height[, style, way]).
CRINKLE = [
    (0.0, 1.0),
    (0.05, 1.012, "Sine", "Out"),     # the fingers meet it: it bulges a hair
    (0.12, 0.9, "Quad", "Out"),       # a crease buckles: crunch
    (0.17, 0.904, "Sine", "InOut"),   # catches on the next
    (0.24, 0.81, "Quad", "Out"),      # crunch
    (0.29, 0.815, "Sine", "InOut"),
    (0.37, 0.745, "Quad", "Out"),     # flat under the thumb
    (0.68, 0.735, "Sine", "InOut"),   # held, still pressing
    (0.74, 0.74),                     # let go
    (0.83, 0.862, "Quad", "Out"),     # pops part way back
    (0.97, 0.874, "Sine", "InOut"),   # stalls on a crease
    (1.04, 0.93, "Quad", "Out"),      # a second pop
    (1.3, 0.955, "Sine", "InOut"),    # creeps
    (1.37, 0.986, "Quad", "Out"),     # a last little crackle
    (1.62, 1.0, "Sine", "InOut"),
]

# --- The gel bead ball (F-05d) -------------------------------------------------------------------
# A clear TPR stress ball packed with water beads of our own (README): sold 2.5 to 3 in across;
# the beads inside, grown about 10 mm, press flat against the skin so the ball reads as a sphere
# of pastel dots with a thin milky web between them (the DIY balloon ball's look), the skin itself
# a hair milky and glossy, with a moulded seam round its middle and a fill plug underneath.
GELBEAD = dict(
    r=33.0,            # the ball's outside radius: 66 mm across (2.6 in)
    sink=1.0,          # how far it settles onto the floor: a small soft flat spot
    skin=1.5,          # the TPR skin's thickness (mm): the beads press against its inside
    # the beads touching the skin: how many, their radius (mm, each a little off it, as grown
    # beads are), how far each presses into the skin's inside (mm: the round patch it makes
    # there) and how softly that patch rolls round into the bead (mm)
    n=90, bead_r=5.6, bead_jit=0.5, press=0.8, roll=1.4,
    core=23.8,         # the deeper beads, seen between them as a pale cloud: this radius (mm)
    # the bands that swirl apart when it's squeezed, by a bead's height over the middle (mm)
    band=9.0,
    dust=0.14, seed=41.0,
)

# The squeeze, timed like a water-filled stress ball: slower and heavier than the hollow stress
# ball (the water has to move), then let go it heaves back past round and wobbles longer and
# lower, the water still slopping (seconds, height[, style, way]).
SLOSH = [
    (0.0, 1.0),
    (0.08, 1.03, "Sine", "Out"),      # the fingers close round it: it bulges up a hair first
    (0.32, 0.7, "Quad", "Out"),       # squashed, the beads shoved round inside
    (0.72, 0.685, "Sine", "InOut"),   # held, still pressing
    (0.86, 1.07, "Quad", "Out"),      # let go: heaves back past round
    (1.0, 0.962),
    (1.14, 1.025),
    (1.28, 0.986),
    (1.43, 1.006),
    (1.58, 1.0),
]
# The beads' swirl (degrees about the ball's upright, anticlockwise from above): the squeeze
# shoves the top band round one way, the middle the other and the bottom a little, each a beat
# behind the last; let go, they slop back past where they were and settle slowly, as beads in
# water do (seconds, degrees[, style, way]).
SWIRL_TOP = [
    (0.0, 0.0), (0.1, 0.0),
    (0.44, 40.0, "Quad", "Out"),
    (0.74, 48.0, "Sine", "InOut"),
    (1.02, -11.0, "Quad", "Out"),
    (1.45, 3.5, "Sine", "InOut"),
    (1.95, 0.0, "Sine", "InOut"),
]
SWIRL_MID = [
    (0.0, 0.0), (0.13, 0.0),
    (0.47, -23.0, "Quad", "Out"),
    (0.76, -28.0, "Sine", "InOut"),
    (1.06, 7.0, "Quad", "Out"),
    (1.5, -2.0, "Sine", "InOut"),
    (2.0, 0.0, "Sine", "InOut"),
]
SWIRL_LOW = [
    (0.0, 0.0), (0.16, 0.0),
    (0.5, 14.0, "Quad", "Out"),
    (0.78, 18.0, "Sine", "InOut"),
    (1.1, -5.0, "Quad", "Out"),
    (1.55, 1.2, "Sine", "InOut"),
    (2.05, 0.0, "Sine", "InOut"),
]

# --- The glitter goo ball (F-05d2) ---------------------------------------------------------------
# A clear TPR squeeze ball full of tinted glitter gel, of our own (README): sold 2.5 in across;
# a clear, glossy skin with a moulded seam and a fill plug like the gel bead ball's, the gel a
# clear aqua, chunky glitter hung all through it (hex flakes 1.6 to 2.9 mm, silver most, then
# gold, rose and lilac holographic) with a dozen gold star sequins, and fine glitter and a few
# tiny bubbles deep in it, seen on the far side's inside.
GLITTER = dict(
    r=32.0,            # the ball's outside radius: 64 mm across (2.5 in)
    sink=1.0,          # how far it settles onto the floor: a small soft flat spot
    skin=1.4,          # the TPR skin's thickness (mm): the gel fills it to its inside
    # the hex flakes hung in the gel: how many, their size (the hexagon's corner radius, mm),
    # how far apart two must stay (mm, so none cross), and how near the gel's wall they may come
    flakes=230, flake_r=(0.8, 1.45), gap=2.8, wall=2.9,
    # how the flakes are dealt: silver, gold, rose, lilac (shares of the whole)
    mix=(0.46, 0.24, 0.18, 0.12),
    # the star sequins: how many, their points' radius and their waist's (mm)
    stars=12, star_r=2.6, star_in=1.12,
    band=8.0,          # the swirling bands, by a flake's height over the middle (mm): equal thirds
    dust=0.12, seed=53.0,
)

# The squeeze, timed like a thick gel ball: the fingers close and it bulges a hair, squashes slow
# and heavy, and let go it heaves back past round only a little and settles quickly, the gel too
# thick to slosh (seconds, height[, style, way]).
GOO = [
    (0.0, 1.0),
    (0.1, 1.022, "Sine", "Out"),      # the fingers close round it: it bulges up a hair first
    (0.4, 0.72, "Quad", "Out"),       # squashed slow, the gel shoved round inside
    (0.82, 0.706, "Sine", "InOut"),   # held, still pressing
    (1.0, 1.045, "Quad", "Out"),      # let go: heaves back past round
    (1.18, 0.981),
    (1.38, 1.007),
    (1.62, 1.0),
]


def glitter_swirl(start, spin, coast, s=1.0):
    """One band's swirl (degrees about the upright, anticlockwise from above): still until the
    squeeze reaches it at `start`, then whipped round faster and faster for `spin` seconds, then
    coasting a long way on, slowing all the while, to stop a whole turn on at `coast` seconds
    later, where it started (a seamless loop: the glitter looks the same at rest). The handover
    angle is where the two speeds match: a Quad In's last speed 2a/spin equals a Quart Out's
    first, 4(360 - a)/coast."""
    a = 720.0 * spin / (coast + 2.0 * spin)
    return [(0.0, 0.0), (start, 0.0), (start + spin, s * a, "Quad", "In"),
            (start + spin + coast, s * 360.0, "Quart", "Out")]


def glitter_rise(start, peak, end, h):
    """One band lifted a hair by its swirl (studs up the ball) and settling slowly back down."""
    return [(0.0, 0.0), (start, 0.0), (peak, h, "Sine", "InOut"), (end, 0.0, "Sine", "InOut")]


# The glitter's swirl: the squeeze whips the top band round first and fastest, the middle a beat
# behind and the bottom later still, so the glitter twists round inside like a stirred drink; each
# lifts a hair as it goes and drifts back down, the top stopping first and the fine glitter deep
# in the gel last, by 5.4 s.
GLITTER_TOP = glitter_swirl(0.1, 0.6, 2.6)
GLITTER_MID = glitter_swirl(0.2, 0.9, 3.3)
GLITTER_LOW = glitter_swirl(0.3, 1.1, 3.6)
GLITTER_DEEP = glitter_swirl(0.35, 1.2, 3.85)
GLITTER_RISE_TOP = glitter_rise(0.1, 1.1, 3.3, 0.0045)
GLITTER_RISE_MID = glitter_rise(0.2, 1.4, 4.4, 0.0035)
GLITTER_RISE_LOW = glitter_rise(0.3, 1.7, 5.0, 0.003)

# --- The galaxy goo ball (F-05d3) ----------------------------------------------------------------
# A clear TPR squeeze ball full of deep blue-violet galaxy gel, of our own (README): galaxy gel balls
# sell at 2 to 4 in, most 2.5 in; the handmade galaxy vortex ball held in a palm reads about
# 2.75 in, and the Legendary takes that. A glossy, faintly violet skin with the glitter ball's seam
# and plug; inside, a nebula swirls through the gel (magenta clouds on one side, teal on the
# other, dark lanes through both) over a dense field of tiny stars; silver and gold star sequins
# and fine silver glitter hang through it, a few pale sparkle stars and a pearl moon glow
# faintly, and a tiny ringed planet floats near the top.
GALAXY = dict(
    r=35.0,            # the ball's outside radius: 70 mm across (2.75 in)
    sink=1.1,          # how far it settles onto the floor: a small soft flat spot
    skin=1.5,          # the TPR skin's thickness (mm): the gel fills it to its inside
    # the star sequins: silver five-pointed, gold five-pointed, and pale four-pointed sparkles
    # that glow; how many of each, their points' radius (mm) and their waist's share of it
    silver=11, gold=7, sparkle=10, star_r=(1.9, 2.8), star_in=0.43, sparkle_in=0.24,
    # the fine glitter: hex specks, how many and how big (corner radius, mm)
    specks=80, speck_r=(0.45, 0.8),
    gap=2.4, wall=3.2,  # how far apart two pieces stay and how near the gel's wall they come (mm)
    band=9.0,          # the swirling bands, by a piece's height over the middle (mm)
    # the pearl moon (radius mm, its middle from the ball's) and the ringed planet (its ball's
    # radius, its ring's inner and outer, its tilt in degrees, its middle)
    moon_r=3.3, moon=(-7.0, -13.5, 1.5),
    planet_r=1.7, ring=(2.4, 4.1), ring_tilt=(24.0, -18.0), planet=(9.5, -9.0, 13.0),
    # the nebula: a band of cloud round the ball, its plane's facing (square to the front
    # camera's view, so it crosses the ball's far side corner to corner from the front and the
    # back alike), the way along it that runs from teal to magenta, and how wide it spreads (mm)
    neb_n=(0.62, -0.34, -0.71), neb_t=(0.62, -0.34, 0.71), neb_w=17.0,
    dust=0.08, seed=61.0,
)

# The galaxy's swirl, slower and dreamier than the glitter ball's: the squeeze stirs the top
# stars round first, the middle a beat behind, the bottom later, each about one turn over six to
# seven seconds, lifting a hair and drifting back down; the nebula's gel turns last and slowest
# behind them, so its clouds drift round the ball, and all stop where they began (a seamless
# loop). Stirred, the stars and clouds brighten a little and fade back as they settle.
GALAXY_TOP = glitter_swirl(0.1, 1.0, 4.6)
GALAXY_MID = glitter_swirl(0.2, 1.3, 5.2)
GALAXY_LOW = glitter_swirl(0.3, 1.5, 5.6)
GALAXY_NEB = glitter_swirl(0.4, 1.8, 6.2)
GALAXY_RISE_TOP = glitter_rise(0.1, 1.4, 4.6, 0.005)
GALAXY_RISE_MID = glitter_rise(0.2, 1.8, 5.6, 0.004)
GALAXY_RISE_LOW = glitter_rise(0.3, 2.1, 6.2, 0.0035)
GALAXY_GLOW = [(0.0, 0.8), (0.3, 0.8), (1.2, 1.0, "Sine", "Out"), (4.4, 1.0),
               (8.0, 0.8, "Sine", "InOut")]


# --- The game rows (F-G1f, D-265; art/finds/PIPELINE.md) ----------------------------------------
# What the game deals and plays for each find, in the order the deal lists them. art/finds/rows.py
# (plain Python: `scripts/art.sh rows`, and every export) writes them into
# src/shared/Finds/Rows.luau; never edit that file. `catalog` is the find's line in the item
# catalog as art/finds/WAVES.md's table names it: a find is dealt once that line is ticked built.
# Grade and worth are the catalog's; `from_` the lowest floor it's dealt on (none: floor 1); its
# grip in studs from the middle of its bottom (across, up, front to back); heft how heavy it feels
# (0 to 1); size where it sits in your view; `press` its one press (Finds/Use's row).
from game import (  # noqa: E402
    CRINKLE,
    RUBBER,
    RUSTLE,
    SIGH,
    SLOSH,
    SOFT,
    SQUELCH,
    SQUISH,
    pitched,
    squeeze,
)

GAME = [
    dict(
        key="StressBall",
        catalog="Stress ball with a face",
        name="Stress ball",
        grade="Common",
        worth=2,
        grip=(0, 0.14, 0),  # round the ball
        heft=0.04,
        size="Small",
        pickUp=pitched(SOFT, 1.5),
        drop=pitched(SOFT, 1.2, 0.5),
        press=squeeze(RUBBER),  # "its eyes bulge out": the rubber skin squeezed
    ),
    dict(
        key="ButterStick",
        catalog="Squishy butter stick",
        name="Butter stick",
        grade="Common",
        worth=4,
        grip=(0, 0.08, 0),  # round the stick
        heft=0.04,
        size="Small",
        pickUp=pitched(SOFT, 1.45),
        drop=pitched(SOFT, 1.15, 0.5),
        press=squeeze(pitched(SQUISH, 1.1)),  # "a dent that slowly fills back in"
    ),
    dict(
        key="MochiBun",
        catalog="Mochi bun",
        name="Mochi bun",
        grade="Common",
        worth=4,
        grip=(0, 0.09, 0),  # round the bun
        heft=0.02,
        size="Small",
        pickUp=pitched(SOFT, 1.6),
        drop=pitched(SOFT, 1.3, 0.45),
        press=squeeze(pitched(SQUISH, 1.4, 0.6)),  # "a soft puff of a sound"
    ),
    dict(
        key="PaperSquishy",
        catalog="Paper squishy with a drawn face",
        name="Paper squishy",
        grade="Uncommon",
        worth=10,
        grip=(0, 0.2, 0),  # round its middle
        heft=0.01,
        size="Small",
        pickUp=RUSTLE,
        drop=pitched(RUSTLE, 0.8, 0.5),
        press=squeeze(CRINKLE),  # "it crinkles"
    ),
    dict(
        key="ToastSlice",
        catalog="Squishy toast slice",
        name="Toast slice",
        grade="Uncommon",
        worth=11,
        grip=(0, 0.22, 0),  # pinched by its crust
        heft=0.02,
        size="Small",
        pickUp=pitched(SOFT, 1.4),
        drop=pitched(SOFT, 1.1, 0.5),
        press=squeeze(pitched(SQUISH, 0.95)),  # "springs back like real bread"
    ),
    dict(
        key="GelBeadBall",
        catalog="Gel bead ball",
        name="Gel bead ball",
        grade="Uncommon",
        worth=12,
        grip=(0, 0.13, 0),  # round the ball
        heft=0.05,
        size="Small",
        pickUp=pitched(SOFT, 1.35),
        drop=pitched(SOFT, 1.05, 0.55),
        press=squeeze(SLOSH),  # "the beads swirl inside"
    ),
    dict(
        key="GlitterGooBall",
        catalog="Glitter goo ball",
        name="Glitter goo ball",
        grade="Uncommon",
        worth=15,
        grip=(0, 0.12, 0),  # round the ball
        heft=0.05,
        size="Small",
        pickUp=pitched(SOFT, 1.35),
        drop=pitched(SOFT, 1.05, 0.55),
        press=squeeze(pitched(SQUELCH, 1.15)),  # "glitter swirls, then settles"
    ),
    dict(
        key="JumboStrawberry",
        catalog="Jumbo slow-rise strawberry",
        name="Jumbo strawberry",
        grade="Uncommon",
        worth=18,
        grip=(0, 0.25, 0),  # round its middle
        heft=0.08,
        size="Medium",
        pickUp=pitched(SOFT, 1.15),
        drop=pitched(SOFT, 0.9, 0.55),
        press=squeeze(pitched(SQUISH, 0.8, 1.0)),  # "ten seconds to rise back": deep
    ),
    dict(
        key="Capybara",
        catalog="Squishy capybara",
        name="Squishy capybara",
        grade="Rare",
        worth=55,
        grip=(0, 0.14, 0),  # round its back
        heft=0.04,
        size="Small",
        pickUp=pitched(SOFT, 1.3),
        drop=pitched(SOFT, 1.0, 0.55),
        press=squeeze(SIGH),  # "a tiny, happy sigh"
    ),
    dict(
        key="GalaxyGooBall",
        catalog="Galaxy goo ball",
        name="Galaxy goo ball",
        grade="Legendary",
        worth=350,
        grip=(0, 0.14, 0),  # round the ball
        heft=0.05,
        size="Small",
        pickUp=pitched(SOFT, 1.25),
        drop=pitched(SOFT, 0.95, 0.55),
        press=squeeze(pitched(SQUELCH, 0.9, 0.7)),  # "stars drift and swirl inside"
    ),
]
