"""Every number of the Figures and models set. The car's are in millimetres, as product sheets
give them, turned into studs by mm() (10 inches a stud, the boxes' scale: 254 mm).

A find's frame in Blender: X across its front, Y away from you (its front faces -Y), Z up, the
origin the find's pivot.
"""

STUD_MM = 254.0


def mm(v):
    return v / STUD_MM


# --- The remote-control car: a 1/10 two-wheel-drive off-road buggy of the 1990s, 27 MHz --------
# References (README): a 1/10 2WD buggy is about 390 long and 240 wide on a 272 wheelbase; its
# tyres are 2.2 inch wheels, about 80 across and 28 wide in front, 84 and 42 at the back.
RC = dict(
    wheelbase=272.0,          # between the axles; the car's pivot is midway, on the floor
    track_f=196.0, track_r=200.0,   # between the wheels' middles across
    tyre_f=dict(od=80.0, w=28.0, rim=56.0, ribs=4),        # ribbed fronts
    tyre_r=dict(od=84.0, w=42.0, rim=56.0, pins=(5, 44)),   # mini-pin rears: rows, round
    ride=18.0,                # the tub's floor above the ground, sat on its springs
    tub=dict(y0=-160.0, y1=108.0, w=92.0, nose_w=56.0, h=26.0, wall=3.0),
    bumper=dict(y0=-198.0, y1=-150.0, w=104.0, z=20.0, t=5.0),
    bulk_f=dict(y=-136.0, w=50.0, z0=18.0, z1=46.0),       # the front bulkhead the arms hinge on
    tower_f=dict(y=-154.0, t=4.0, bottom=30.0, top=92.0, w0=30.0, w1=64.0),
    tower_r=dict(y=164.0, t=4.0, bottom=38.0, top=112.0, w0=42.0, w1=86.0),
    arm_f=dict(inner=(24.0, 28.0), outer=(76.0, 24.0), y0=-152.0, y1=-120.0, t=7.0),
    arm_r=dict(inner=(34.0, 30.0), outer=(80.0, 26.0), y0=112.0, y1=160.0, t=8.0),
    gearbox=dict(y=136.0, w=40.0, y0=106.0, y1=166.0, z0=22.0, z1=86.0, diff_r=27.0),
    motor=dict(y=88.0, z=50.0, r=18.0, x0=-40.0, x1=14.0, bell=9.0),   # a 540 can, across
    spur=dict(x=-46.0, y=118.0, z=60.0, r=31.0, t=10.0),
    battery=(136.0, 46.0, 24.0),     # a six-cell stick pack, in the tub
    shock_f=dict(top=(52.0, -152.0, 86.0), bottom=(60.0, -138.0, 27.0), r=6.5),
    shock_r=dict(top=(70.0, 166.0, 106.0), bottom=(70.0, 126.0, 30.0), r=7.0),
    caster=10.0,              # degrees the front kingpins lean back
    steer_arm=14.0,           # the knuckle's arm, from the kingpin to the tie rod's ball
    shell=dict(t=1.2),        # lexan, painted inside
    wing=dict(y0=112.0, y1=200.0, z=132.0, span=176.0, dam=24.0, aoa=11.0, lip=7.0),
    aerial=dict(at=(42.0, 40.0, 50.0), length=250.0, r=2.6, cap=(4.5, 13.0), joint=0.55),
    # the car as it's found: its springs settled, sat square
    seed=7.0,
    dust=0.5,
)

# Driving it (the game's wiring, later): the spec the generated Luau carries as `Drive`.
RC_DRIVE = dict(
    steer_lock=26.0,          # degrees, the outer front wheel at full lock (a 1/10 buggy's)
    travel=24.0,              # mm the springs let a wheel rise and drop, bump to full droop
    # 20 studs a second: a touch faster than a player runs (16), so friends chase it down the
    # hall of units and can't quite catch it; flat out it crosses a unit in half a second, so
    # round your unit it's driven on part throttle, and that's the skill
    top_speed=20.0,
    accel=30.0,               # studs/s each second flat out: from rest to top in two thirds of a second
    brake=40.0,               # studs/s each second: it stops in about a car length from a crawl
    roll=0.55,                # degrees of lean a stud/s^2 of cornering: it leans out, visibly
    pitch=0.22,               # degrees of squat or dive a stud/s^2: the nose lifts as it leaps off
)

# --- its transmitter: a pistol-grip radio, wheel and trigger, a chrome telescopic aerial --------
# References (README): about 200 tall to the top of its head, the head 155 long and 58 thick,
# a 60 wheel on its right side, a battery foot 150 by 70, the aerial 190 collapsed.
TX = dict(
    at=(-185.0, 52.0), yaw=-18.0,       # where it stands beside the car (mm, degrees)
    foot=dict(l=150.0, w=70.0, h=28.0),
    grip=dict(w=32.0, d=44.0, rake=14.0, y=22.0, z0=24.0, z1=126.0),
    head=dict(y0=-92.0, y1=66.0, w=58.0, z0=122.0, z1=196.0),
    wheel=dict(y=-46.0, z=150.0, r=31.0, w=17.0, out=6.0, turn=38.0),   # turn: at full lock
    trigger=dict(y=-6.0, z=120.0, len=44.0, pull=13.0, push=-9.0),
    aerial=dict(y=-60.0, length=190.0, r0=4.6, r1=1.6, sections=7),
)

# --- The die-cast car: a pocket-size metal toy car of the late 1960s, our own two-door saloon ---
# References (README): toy cars of the kind ran 66 to 76 long on wheels 9 to 10 across; a zinc
# body in metallic paint, a bright zinc base making the bumpers and grille, riveted under it,
# and plastic wheels on crimped steel axles. No real maker's or carmaker's design. All in mm,
# its frame like the RC car's: front to -Y, the pivot on the floor midway between the axles.
DC = dict(
    length=76.0,              # nose to tail of the casting (3 inches: a touch bolder than most)
    half_w=15.0,              # the body's half width at the belt; its corners round off in plan
    corner=3.0,               # the plan's corner round at nose and tail
    wheelbase=44.0, track=25.2,
    tyre=dict(od=9.6, w=4.0, hub=5.6),   # black plastic tyres on silver hubs
    arch=5.6,                 # the wheel arches' round about each axle
    sill=3.5,                 # the casting's lower edge, over the base
    deck_nose=11.0, deck_cowl=13.0, deck=13.2, deck_tail=12.4,   # the bonnet's and boot's height
    roof=20.1, crown=0.5,     # the roof and how much it domes
    cowl=-14.0, screen_top=-5.0,          # y where the windscreen starts and meets the roof
    back_top=13.0, back_base=22.0,        # and the rear window
    glass_half=13.2, roof_half=10.4,      # the greenhouse's half width at its foot and its roof
    b_pillar=4.6,             # y of the door's back window post
    door=(-12.6, 7.6),        # y of the door's front and back shut lines
    base=dict(z0=1.9, z1=3.4, half=9.8, side=13.8, end=1.5),
    bumper=dict(z0=3.0, z1=5.6, half=13.6),
    seed=11.0,
    dust=0.0,                # none: on glossy metallic paint any film reads as blotches
)

# Pushing it (the Push action's motion): a shove from the hand, then it rolls off down the hall
# of units, slowing on the concrete, its loose axles letting it wander and rattle.
DC_PUSH = dict(
    v0=4.0,                   # studs/s as it leaves the hand: a quarter of a player's run
    shove=0.12,               # s the hand takes to send it off
    decel=1.1,                # studs/s each second of rolling drag: about 7 studs before it stops
    drift=3.0,                # degrees a second its heading wanders at full speed
    rattle=0.55,              # degrees the body rocks on its axles at full speed
    nose=0.036,               # degrees of nose-up a stud/s^2 as the hand shoves it
)
