"""Every number of the Lights set, in studs (10 inches a stud, the boxes' scale). Change them here.

A find's frame in Blender: X across its front, Y away from you (its front faces -Y), Z up, the
origin the find's pivot (for the desk lamp, the middle of its base, on the floor).
"""

import math

# --- The desk lamp: a spring-balanced desk lamp of the 1960s-70s -------------------------------
# References (README): a 7-8 inch round cast base, two arm sections of about 12 inches each, a
# 6 inch bell shade with a push switch on top, closed-coil springs on the lower arm.
DESK_LAMP = dict(
    # the base: a two-step round cast-iron foot (profile radii and heights), with a felt underside
    base_r=0.36, base_h=0.078, step_r=0.262, step_h=0.14, boss_r=0.13, boss_top=0.19,
    turret=(0.05, 0.19, 0.235),          # the swivel under the yoke: radius, bottom, top
    shoulder=(0.0, 0.0, 0.275),          # the lower arm's hinge
    yoke=(0.068, 0.012, 0.085, 0.2, 0.31),  # cheek plates: x offset, thickness, depth, z0, z1
    # the arms at rest, as it's found: the lower leaning back, the upper reaching forward
    lower_len=1.2, lower_tilt=16.0,      # degrees back from upright
    upper_len=1.15, upper_drop=12.0,     # degrees below level, reaching forward
    bars=(0.05, 0.014, 0.034),           # the lower arm's flat bars: x offset, thickness, depth
    rods=(0.03, 0.011),                  # the upper arm's round rods: x offset, radius
    hub_r=0.03,                          # the elbow's hub
    springs=dict(x=0.025, back=0.032, r=0.021, wire=0.0045, s0=0.07, s1=0.43),
    # the shade: its own axis Z, opening down; tilted forward from straight down
    shade_tilt=25.0,
    shade=dict(rim=0.30, length=0.6, neck=0.088),
    wrist_on_shade=(0.0, 0.14, -0.05),   # where the wrist hinge sits in the shade's own frame
    bulb=dict(r=0.118, tip=-0.46, base_top=-0.13, base_r=0.053),
    switch=dict(collar=0.035, r=0.022, h=0.03),
    cord_r=0.011,
    plug=(0.42, 1.05),                   # where the plug lies on the floor
    seed=21.0,
    dust=0.55,
    # its light: a 60 W pearl bulb (2,700 K) in a bell shade
    kelvin=2700,
)


def rot_x(deg, v):
    a = math.radians(deg)
    x, y, z = v
    return (x, y * math.cos(a) - z * math.sin(a), y * math.sin(a) + z * math.cos(a))


def lamp_joints(d=DESK_LAMP):
    """The shoulder, elbow and wrist at rest, and the shade's placing (tilt, origin)."""
    S = d["shoulder"]
    t = math.radians(d["lower_tilt"])
    E = (S[0], S[1] + d["lower_len"] * math.sin(t), S[2] + d["lower_len"] * math.cos(t))
    u = math.radians(d["upper_drop"])
    W = (E[0], E[1] - d["upper_len"] * math.cos(u), E[2] - d["upper_len"] * math.sin(u))
    # the shade's own frame: turned -tilt about X (opening down and forward), its wrist point on W
    off = rot_x(-d["shade_tilt"], d["wrist_on_shade"])
    origin = (W[0] - off[0], W[1] - off[1], W[2] - off[2])
    return S, E, W, origin


def on_shade(v, d=DESK_LAMP):
    """A point in the shade's own frame, in the find's frame."""
    _, _, _, o = lamp_joints(d)
    p = rot_x(-d["shade_tilt"], v)
    return (o[0] + p[0], o[1] + p[1], o[2] + p[2])


# --- The plug-in night-light: a C7 night-light with a frosted ribbed shade -------------------
# References (README): about 4.6 inches tall, a shade about 1.75 inches across at its widest over
# a narrow white base with a slide switch on its front and two plug blades out of its back.
# Its frame: X across, the wall plate's back face at Y = 0 (the find reaches forward to -Y), Z up
# from the bottom of the base. The origin is the middle of the base's back edge on the floor.
NIGHT_LIGHT = dict(
    # the base: a white plastic block, the slide switch on its front
    base=dict(w=0.1, d=0.095, h=0.112, round=0.012),
    slot=dict(w=0.016, z0=0.03, z1=0.088),       # the switch's slot in the base's front
    tab=dict(w=0.017, h=0.017, out=0.011, z=0.034),
    travel=0.031,                                # how far the tab slides up to switch on
    # the plug: two blades out of the back, a real US plug's spacing (half an inch apart)
    blades=dict(x=0.025, z=0.056, len=0.0625, thick=0.0065, narrow=0.025, wide=0.031),
    # the shade: rings up from the base (z, width, depth from the wall), a dome on top
    shade=[(0.104, 0.124, 0.094), (0.11, 0.136, 0.104), (0.2, 0.152, 0.113), (0.3, 0.168, 0.121),
           (0.37, 0.175, 0.125), (0.4, 0.176, 0.126)],
    dome=0.06,                                   # how far the top rounds over above the last ring
    squareness=2.6,                              # the shade's section: 2 a half oval, higher boxier
    ribs=dict(z0=0.114, z1=0.396, pitch=0.0141, depth=0.0026),
    bulb=(0.0, -0.062, 0.25),                    # the C7 bulb's middle, inside the shade
    # the numbers above are a 4.6 inch night-light; it's built 1.15 times that, 5.3 inches, the
    # size of the bigger plug-in shades (5 to 5.75 inches in listings), so it reads from a doorway
    scale=1.15,
    seed=33.0,
    dust=0.5,
    # its light: a 4 W candelabra bulb, about 2,600 K, glowing through frosted plastic
    kelvin=2600,
)


# --- The tea light in a jar: a jam-jar lantern -------------------------------------------------
# References (README): a pint screw-top jar (about 5 inches tall, 3 across, a 70 mm regular-mouth
# thread) with a wire wrapped twice under its thread, an ear each side, and a wire bail hooked
# through the ears; a tea light (38 mm across, 16 mm deep, in a pressed aluminium cup) on its
# floor, burned about half down. Its frame: the jar's bottom middle on the floor, its front to -Y.
TEA_JAR = dict(
    # the jar's outside, bottom to top (radius, height): a raised middle under a resting ring,
    # the straight body, the shoulder, a bead the wire sits on, the threaded neck to the rim
    outside=[(0.0, 0.006), (0.118, 0.002), (0.133, 0.0), (0.143, 0.004), (0.149, 0.013),
             (0.15, 0.03), (0.151, 0.2), (0.15, 0.37), (0.147, 0.392), (0.139, 0.408),
             (0.131, 0.418), (0.1345, 0.424), (0.1345, 0.43), (0.132, 0.433), (0.132, 0.492),
             (0.13, 0.4985)],
    # and its inside, from the rim down to the floor: walls 3 mm, the base 7 mm thick
    inside=[(0.1175, 0.4985), (0.117, 0.48), (0.1175, 0.435), (0.121, 0.424), (0.127, 0.413),
            (0.135, 0.398), (0.1393, 0.372), (0.1395, 0.05), (0.137, 0.036), (0.128, 0.03),
            (0.0, 0.029)],
    thread=dict(z0=0.449, z1=0.486, turns=1.6, r=0.0026, out=0.1335),  # the screw thread
    seed=47.0,
    dust=0.42,
)
TEA_LIGHT = dict(
    at=(0.022, -0.016, 0.029),     # where it stands on the jar's floor (slid a little off middle)
    r=0.0748, h=0.063,             # the cup: 38 mm across, 16 mm deep
    wax=0.036,                     # burned about half down: the wax's top in the cup
    pool=0.042,                    # the old melt pool round the wick, set glossy
    wick=dict(r=0.0032, up=0.024, lean=12.0),  # its wick standing out of the wax, leaning
    flame=dict(h=0.088, r=0.0145, at=0.005),   # 22 mm tall, 7 mm across, its foot above the wax
    kelvin=1850,                   # a candle flame
)
TEA_WIRE = dict(
    r=0.0055,                      # heavy galvanised wire, a touch bolder than life (2.8 mm)
    z=0.4385,                      # the wrap's height: on the neck's bead, under the thread
    neck=0.132,
    eye=dict(x0=0.1465, r=0.013, turns=1.5),  # each ear: an eye coiled round the bail's hook
    bail=dict(inner=0.145, x=0.176, bend=0.008, arms=0.13),  # hook end, arms' x, the arms
    bail_rest=-150.0,              # degrees it's fallen back from upright, its top on the jar
)


# --- The bundle of glow sticks: three 6 inch lightsticks held with a rubber band ---------------
# References (README): a 6 inch lightstick is 150 to 152 mm long and 15 mm across; a plug cap
# a touch wider than the tube closes the bottom; the top is sealed into a flat tab with a hole
# and an open moulded hook beyond it; a thin glass ampoule rides loose inside. Its frame: the
# bundle's middle on the floor, the sticks along X with their hooks to +X, its front to -Y.
GLOW_STICK = dict(
    length=0.6,                    # 152 mm, cap to hook
    r=0.0295,                      # the tube: 15 mm across
    cap=dict(r=0.0315, h=0.055, round=0.004),  # the plug cap at the bottom: 16 mm across, 14 long
    shoulder=0.515,                # where the tube starts closing to its seal
    seal=0.535,                    # the seal's end on the axis
    # the flat tab the seal ends in: the hole's centre, its radius, the tab's half width, the
    # tab's start and end along the stick, its thickness
    tab=dict(hole=0.551, hole_r=0.0078, w=0.0165, z0=0.524, z1=0.567, t=0.0076),
    # the open hook past it: its centre, outer and inner radius, thickness, and where the C
    # starts and ends (degrees round its centre from the stick's side; the gap faces the tab)
    hook=dict(at=0.58, R=0.0195, r=0.0112, t=0.0066, a0=-125.0, a1=160.0),
    # the glass ampoule: where it starts and ends, its radius, and how far below the tube's
    # middle it lies (it sinks; kept inside the bake's reach of the tube wall)
    vial=dict(z0=0.09, z1=0.49, r=0.0095, drop=0.01),
    bend=0.3,                      # where it's bent to crack it: its middle
    crack=34.0,                    # degrees it bends before the ampoule snaps
)
GLOW_BUNDLE = dict(
    # the three sticks (the top one, the front one, the back one): slid along and rolled about
    # their own axes (degrees) so the hooks don't line up, as a bundle snapped together does
    sticks=[dict(slide=0.0, roll=-20.0), dict(slide=-0.022, roll=35.0),
            dict(slide=0.014, roll=-70.0)],
    band=dict(at=0.17, w=0.016, t=0.0045),  # the rubber band: along the sticks, width, thickness
    seed=53.0,
    dust=0.38,
    rgb=(120, 255, 96),            # a green lightstick's glow (about 520 nm)
)


# --- The string fairy lights: copper-wire micro LEDs coiled loose, on a 3 x AA box -------------
# References (README): twenty micro LEDs (resin drops on the wire) 10 cm apart on thin copper
# wire, with a lead to a translucent 3 x AA box (about 68 x 50 x 21 mm) that has a slide switch
# on top at its cable end and the batteries showing through. Found wound into a loose ring. Its
# frame: the middle of the whole thing on the floor, its front to -Y. A box's own frame: X along
# it, its cable end to -X.
FAIRY = dict(
    # the coil: its centre, radius, how squashed across, loops, the angle the far end starts at,
    # and how far the loops wander in and out
    coil=dict(at=(-0.17, 0.03), R=0.29, oval=0.88, loops=4.5, start=-160.0, wander=0.16),
    wire=dict(r=0.0022, step=0.04),   # the copper wire (1.1 mm, twice life so it reads), path step
    # the LEDs: resin drops along the wire (bolder than life: 5.5 mm by 3 mm), every 10 cm from
    # the far end
    bead=dict(len=0.022, r=0.0062, every=0.4, first=0.06),
    box=dict(at=(0.335, -0.06), yaw=-18.0, l=0.275, w=0.191, h=0.08, round=0.008),
    batt=dict(r=0.0285, l=0.199, nub=(0.0105, 0.0055), y=(-0.0575, 0.0, 0.0575), z=0.0345),
    lid=-0.075,                        # where the battery lid starts along the box
    # the slide switch on top: its middle off (x, y), its knob (length, width, height above the
    # lid), and how far it slides on, towards the cable end
    switch=dict(at=(-0.103, 0.045), knob=(0.022, 0.02, 0.009), travel=0.014),
    exit=(-0.04, 0.04),                # where the wire leaves the cable end (y, z)
    kelvin=2900,                       # warm white LEDs
    seed=59.0,
    dust=0.45,
)


# --- The camping lantern: a retro LED lantern with a dimmer knob ------------------------------
# References (README): green steel retro LED lanterns (a 3 x D cell lantern is 7 to 11 inches
# tall: Primus 8.3, Rayovac 7.25, Dorcy 7). A bell-flared steel foot, a straight band with a
# silver rotary dimmer on its front, a black seat ring, a clear straight globe round a frosted
# hourglass diffuser with horizontal ribs, guarded by six steel bars, a black top ring, a wide
# flat hood pressed with ribs, a ribbed cap, and a wire bail with a rubber grip hooked into two
# lugs on the hood. Its frame: the middle of its foot on the floor, the knob to the front (-Y).
LANTERN = dict(
    # the body's outside, bottom to top (radius, height): the foot's rolled lip and bell, the
    # band with a bead at each end, the dark neck, the black seat ring the globe stands in
    foot=[(0.0, 0.006), (0.188, 0.006), (0.199, 0.0), (0.207, 0.004), (0.208, 0.011),
          (0.2, 0.017), (0.183, 0.026), (0.168, 0.038), (0.159, 0.052), (0.155, 0.062)],
    band=dict(r=0.153, z0=0.062, z1=0.165, bead=0.0045),
    neck=dict(r=0.138, z1=0.176),
    seat=dict(r=0.162, z0=0.176, z1=0.202),
    top=dict(r=0.16, z0=0.526, z1=0.552),          # the black top ring
    globe=dict(r=0.137, wall=0.009, z0=0.194, z1=0.534),  # 2.7 in across, 3.4 in tall
    # the frosted diffuser inside: an hourglass (its end and waist radii), horizontal ribs
    diffuser=dict(z0=0.222, z1=0.5, r_end=0.074, r_waist=0.05, ribs=15, rib=0.0028,
                  collar=0.08),
    bars=dict(n=6, R=0.152, r=0.0062, start=0.0),  # the guard: six steel bars round the globe
    # the hood: a flat cone from its rolled rim up to the cap, pressed with stiffening ribs
    hood=dict(rim=0.222, bead=0.006, z_rim=0.545, r_top=0.072, z_top=0.652, under=0.15,
              ribs=12, rib=0.0055),
    cap=dict(r=0.062, z0=0.646, z1=0.702, dome=0.012, ribs=28, rib=0.0022),
    # the bail: chrome wire through a lug on each side of the hood; its arms, the arc over the
    # top and the rubber grip round the arc's middle
    bail=dict(r=0.0065, lug_x=0.163, x=0.178, z=0.598, arms=0.14, grip_r=0.0165, grip=38.0),
    bail_rest=-107.0,                  # found fallen back, its arms lying on the hood's rim
    # the dimmer: a knurled knob on a chrome bezel, its pointer at seven o'clock when off
    knob=dict(z=0.112, r=0.029, depth=0.03, bezel=0.036, off=150.0, click=24.0, full=255.0),
    port=dict(z=0.112, w=0.022, h=0.0075),  # the charging port on the band's back
    kelvin=3200,                       # warm white LEDs behind frosted plastic
    seed=67.0,
    dust=0.5,
)


# --- The moon lamp: a 3D-printed moon on a wooden cradle --------------------------------------
# References (README): moon lamps are printed PLA spheres (8 to 20 cm; 15 cm the usual) whose
# relief is a lithophane of the Moon, so lit the thick maria read grey and the thin highlands
# bright; a white plug in a flat cut at the bottom holds the touch switch and the USB port; they
# sit in a cradle of two M-shaped pieces of pale wood halved into each other. Its frame: the
# middle of the cradle on the floor, front to -Y.
MOON = dict(
    R=0.295,                           # 15 cm across
    cut=0.011,                         # the flat cut at the bottom the plug fills (4 cm across)
    segs=(48, 720), rings=(24, 320),   # game mesh, detailed mesh: the craters need the density
    # the print's relief, in studs out from the sphere (0.001 is a quarter of a millimetre)
    craters=1300, crater=(0.0065, 0.034),  # how many, smallest and largest radius (power law)
    depth=0.17, rim=0.3,               # a bowl's depth times its radius; its rim times its depth
    hills=0.0005,                      # the highlands' low roughness between the craters
    mare_drop=0.0009,                  # the maria sit a touch lower, smooth and nearly bare
    # the near side's maria, as the Moon has them: (latitude, longitude, radius) in degrees,
    # longitude east to the right as seen from the front (IAU)
    maria=[(33, -16, 19), (28, 17, 12), (8.5, 31, 14), (17, 59, 9), (-8, 51, 14),
           (-15, 35, 6), (-21, -17, 12), (-24, -39, 7), (13, 4, 5), (-10, -23, 7),
           (7, -31, 9), (18, -57, 22), (-2, -48, 13), (40, -50, 12), (56, -25, 8),
           (57, 5, 9), (55, 30, 6), (18, 35, 5)],
    # the bright young craters whose rays read lit: Tycho and Copernicus (lat, lon, radius)
    rayed=[(-43, -11, 0.013, 12), (9.6, -20, 0.011, 8)],
    relief=0.0015,                     # the look's fine pitting, below the mesh's craters
    shade_gap=0.006,                   # the phase shade just outside the surface
    kelvin=3000,
    seed=71.0,
    dust=0.3,
)
CRADLE = dict(
    t=0.05,                            # the wood's thickness (13 mm)
    w=0.05,                            # how wide each stick is, across it
    slope=25.0,                        # the V the moon sits in, degrees from level
    valley=0.115,                      # the top of the V's bottom, above the floor
    peak=0.19,                         # how far out each peak is
    foot=0.24, foot_w=0.06,            # each foot's outer edge and how long it stands on the floor
    seed=73.0,
)


# --- The blob lamp: the classic wax-in-a-bottle motion lamp -------------------------------------
# References (README): a 14.5 inch lamp, a spun aluminium base (a cone narrowing to a waist,
# then flaring to the collar the bottle stands in), a tapering glass bottle, a spun cap; violet
# liquid and red-orange wax lit by a bulb in the base. Its frame: the middle of the base on the
# floor, front to -Y. Measured off a side-on photo scaled to 14.5 in.
BLOB_BASE = dict(
    # the base's outside, bottom to top (radius, height): the rolled foot, the cone up to the
    # waist, the flare up to the collar and its rolled rim; then down inside the collar to the
    # shelf the bottle stands on
    outside=[(0.0, 0.003), (0.196, 0.003), (0.207, 0.0), (0.2135, 0.004), (0.2155, 0.009),
             (0.2135, 0.015), (0.0905, 0.384), (0.0858, 0.396), (0.0858, 0.404), (0.0905, 0.416),
             (0.1555, 0.536), (0.1605, 0.546), (0.1612, 0.555)],
    inside=[(0.1555, 0.555), (0.1545, 0.512), (0.13, 0.505), (0.0, 0.505)],
    # the cord leaves the back of the foot through a rubber sleeve, runs over the floor through
    # an inline rocker switch to a two-pin plug
    grommet=dict(z=0.036, r=0.019, len=0.03),
    cord_r=0.0105,
    switch=dict(at=(0.205, 0.43), yaw=20.0, l=0.21, w=0.086, h=0.062, rocker=(0.066, 0.05, 0.02),
                off=-11.0, on=11.0),
    plug=dict(at=(0.03, 0.645), yaw=180.0),
)
BLOB_BOTTLE = dict(
    # the glass, outside, bottom to top: its round bottom sits down in the collar; widest 1.45 in
    # above the collar, then a straight taper to the neck the cap sits over
    outside=[(0.0, 0.507), (0.08, 0.509), (0.124, 0.516), (0.145, 0.53), (0.155, 0.547),
             (0.1612, 0.565), (0.172, 0.604), (0.1805, 0.65), (0.1848, 0.705), (0.1002, 1.262),
             (0.0985, 1.27), (0.0985, 1.302)],
    wall=0.0105,                       # about 3 mm of glass
    liquid=1.215,                      # the liquid's surface: a clear band of air shows under the cap
)
BLOB_CAP = dict(
    # spun like the base: a rolled lip over the bottle's neck, a cone, a rounded flat top
    outside=[(0.1035, 1.254), (0.1075, 1.258), (0.1085, 1.266), (0.1072, 1.276), (0.0482, 1.443),
             (0.044, 1.4495), (0.036, 1.452), (0.0, 1.452)],
    inside=[(0.0, 1.444), (0.04, 1.442), (0.1005, 1.272), (0.1005, 1.256)],
)
BLOB_WAX = dict(
    pool_top=0.622,                    # the wax lying on the bottle's floor, cold or melted
    mound=dict(r=0.085, h=0.03),       # the hump in the middle where blobs leave and land
    neck=dict(h=0.1, foot=0.048, waist=0.017, top=0.034),  # the strand a rising blob draws up
    # each blob: its size (radius of the ball it would be), how lumpy, and its seed
    blobs=dict(Blob1=(0.062, 0.07, 1.0), Blob2=(0.055, 0.08, 2.0), Blob3=(0.045, 0.09, 3.0),
               Blob4=(0.024, 0.06, 4.0)),
    loop=48.0,                         # seconds before Flow comes round to where it started
)
BLOB_LAMP = dict(
    rgb=(255, 120, 178),               # its light: the bulb through violet liquid and orange wax
    seed=71.0,
    dust=0.55,
)


# --- The oil lamp: a clear glass pedestal paraffin lamp with a #2 flat-wick burner -------------
# References (README): a pressed glass foot, stem and onion fount about 9.5 in to the collar; a
# brass collar and #2 burner (an air-hole band, four prongs holding the chimney, a slotted
# dome over a 1 in flat wick, a thumbwheel on a spindle out the side); a 10 in chimney with a
# 3 in fitter. About 20 in in all. Its frame: the middle of the foot on the floor, front to -Y;
# the wick runs across X, so the flame shows its broad face to the front.
OIL_GLASS = dict(
    # the glass, outside, bottom to top: the hollow under the foot, the foot's rim, the domed
    # foot, the stem with its knop, the onion fount, the neck the collar screws onto
    outside=[(0.0, 0.05), (0.08, 0.046), (0.2, 0.024), (0.265, 0.006), (0.285, 0.0),
             (0.296, 0.004), (0.3, 0.014), (0.298, 0.026), (0.29, 0.034), (0.26, 0.044),
             (0.2, 0.068), (0.14, 0.1), (0.095, 0.135), (0.072, 0.17), (0.062, 0.2),
             (0.07, 0.228), (0.078, 0.25), (0.07, 0.272), (0.058, 0.29), (0.056, 0.305),
             (0.075, 0.322), (0.12, 0.342), (0.18, 0.37), (0.225, 0.405), (0.252, 0.45),
             (0.262, 0.5), (0.258, 0.545), (0.24, 0.6), (0.205, 0.66), (0.16, 0.72),
             (0.12, 0.77), (0.095, 0.805), (0.087, 0.82), (0.086, 0.866)],
    fount=21,                          # the outside from here up is the fount's thin wall
    wall=0.012,                        # about 3 mm of pressed glass
    floor=0.352,                       # the fount's floor inside
    oil=0.55,                          # the paraffin's surface: a little over half full
    flutes=16,                         # pressed panels round the fount's lower half
    chips=dict(foot=(-112.0, 0.014)),   # (angle round from +X, depth): a flake off the foot's top edge
)
OIL_BURNER = dict(
    collar=0.836,                      # where the collar's rolled foot meets the glass
    # the brass, bottom to top: the collar (rolled foot, thread, top), the burner's flared base,
    # the band of air holes, the shoulder, the gallery the chimney stands in, the slotted dome
    outside=[(0.0, 0.872), (0.08, 0.872), (0.0875, 0.836), (0.093, 0.838), (0.0955, 0.843),
             (0.0955, 0.85), (0.0975, 0.855), (0.0955, 0.86), (0.0975, 0.865), (0.0955, 0.87),
             (0.0975, 0.875), (0.0955, 0.88), (0.0975, 0.888), (0.09, 0.892), (0.1, 0.9),
             (0.115, 0.912), (0.12, 0.922), (0.12, 0.965), (0.124, 0.97), (0.15, 0.978),
             (0.158, 0.982), (0.1585, 0.99), (0.152, 0.992), (0.135, 0.986), (0.062, 0.986),
             (0.059, 0.999), (0.051, 1.017), (0.036, 1.029), (0.016, 1.035), (0.0, 1.036)],
    holes=dict(n=20, z=0.944, r=0.0075),   # the round air holes round the band
    slot=(0.05, 0.006),              # the dome's slot the flame comes out of (half length, half width)
    prongs=dict(n=4, at=45.0, r=0.1555, w=0.022, t=0.003, up=0.055, flare=0.026, lean=32.0),
    spindle=dict(z=0.944, x0=0.112, x1=0.2, r=0.0058, boss=0.0115),
    wheel=dict(x=0.205, r=0.042, t=0.011, hub=0.013, knurl=44),
    flame_at=1.031,                    # the flame's foot, just inside the slot
)
OIL_CHIMNEY = dict(
    # a #2 chimney, outside, from its foot (0) up: the 3 in fitter, a waist, the 4 in bulge,
    # the long 2 in top, a fire-polished bead at the rim
    outside=[(0.147, 0.0), (0.15, 0.004), (0.15, 0.03), (0.145, 0.045), (0.158, 0.08),
             (0.18, 0.13), (0.196, 0.19), (0.2, 0.25), (0.195, 0.31), (0.175, 0.38),
             (0.145, 0.44), (0.118, 0.5), (0.104, 0.56), (0.1, 0.62), (0.1, 0.975),
             (0.1025, 0.99)],
    wall=0.0065,                       # about 2 mm of blown glass
    chip=(-36.0, 0.013, 0.05),          # (angle round from +X, depth, width): a chip out of the rim
)
OIL_FLAME = dict(
    h=0.125, w=0.048, t=0.011,          # a 1 in wick turned to a good flame: 1.2 in tall, a fan face on
    kelvin=1900.0,                     # a paraffin flame: deep warm yellow
)
OIL_LAMP = dict(
    wick_up=110.0,                     # degrees the thumbwheel turns to bring the wick up to burn
    lift=0.3,                          # how high the chimney is lifted to light it
    seed=79.0,
    dust=0.5,
)

# --- the disco ball (F-02h) --------------------------------------------------------------------
# An 8 inch mirror ball on a tabletop battery motor: the motor's base is a black dome on a wide
# cone, 7 in across and 3.8 in tall, one D cell inside, turning the ball at 5 turns a minute.
DISCO_BASE = dict(
    r=0.35,                            # 7 in across the foot
    band=(0.012, 0.03),                # the upright band round the foot, where the switch is
    # the skirt: a hat brim, flat at the band and steepening into the dome (r, z)
    skirt=[(0.335, 0.04), (0.3, 0.0512), (0.265, 0.0718), (0.23, 0.0984), (0.2, 0.1253),
           (0.18, 0.145), (0.166, 0.152)],
    dome=(0.155, 0.162),               # the dome's middle height and radius
    collar=(0.02, 0.327),              # the boss the shaft comes out of (r, top)
    feet=dict(n=3, at=0.26, r=0.028, h=0.004),   # rubber feet under it
    switch=dict(w=0.022, d=0.012, h=0.013, z=0.021, travel=0.014, slot=0.026),
    jack=dict(z=0.021, r=0.006),      # the DC jack at the back (the motor also runs off a plug)
)
DISCO_BALL = dict(
    r=0.4,                             # 8 in across the tiles' faces
    core=0.392,                        # the foam sphere under the tiles
    tile=0.0394,                       # 10 mm square glass mirror tiles
    gap=0.0039,                        # 1 mm of grout between them
    t=0.0075,                          # tiles about 2 mm thick
    rows=29,                           # rows pole to pole (half the circumference over the pitch)
    tilt=1.1,                          # degrees each tile sits off true (hand-laid; the sparkle)
    cup=dict(r=0.058, z=0.362, shaft=0.011),   # the motor's cup the ball sits in, its rim
    plate=dict(r=0.034, t=0.012),      # the hanging plate at the top pole
    ring=dict(r=0.02, wire=0.0035),    # the hanging ring (it hangs as well as sits)
    missing=0.008,                     # share of tiles fallen off in storage
    old=0.05,                          # share gone dark at the back (desilvered)
    glint=0.05,                        # share that flash when it spins in a light
)
DISCO = dict(
    rpm=5.0,                           # the motor's speed: one turn in 12 s, spots sweep a wall
                                       # 5 studs away at about 2.6 studs a second
    kelvin=6500.0,                     # the spots: a cool white LED
    seed=91.0,
    dust=0.45,
)

# --- the neon OPEN sign (F-02i) ----------------------------------------------------------------
# A real-glass shop sign, 24 x 10 x 3 in: pink letters and an aqua border bent from 10 mm tube,
# standing an inch off a black acrylic backing on clear posts; each tube's ends bend back
# through the backing in black rubber boots to the transformer box behind.
NEON = dict(
    w=2.4, h=1.0, t=0.025,             # the backing: 24 x 10 in of 1/4 in black acrylic
    ty=-0.1,                           # the tubes' middles, 1 in in front of it
    r=0.0197,                          # 10 mm tube
    letters=dict(z0=0.22, z1=0.78,     # the letters' tube middles, bottom and top (6.4 in tall)
                 widths=(0.38, 0.32, 0.30, 0.36), gap=0.16),
    border=dict(hw=1.1, z0=0.09, z1=0.91, rad=0.07, gap=(0.15, 0.25)),
    box=dict(x=0.2, y=(0.025, 0.17), z=0.25),   # the transformer box behind, its half width
    toggle=dict(x=0.12, lean=20.0, len=0.07),   # its switch on top: degrees off upright each way
    eyes=0.9,                          # the hanging eyes on the top edge, either side
    seed=97.0,
    dust=0.5,
)

# --- the miner's hard hat (F-02j) ---------------------------------------------------------------
# A mid-century fibreglass miner's cap (the cap style: a short peak, a low crest over the crown,
# a flared lip round the sides and back), safety yellow worn to the glass; a riveted leather
# lamp bracket on its front with a steel slot strap; a round cap lamp hooked in it; its rubber
# cord over the crown, through a clip on the back and down to a red steel battery case standing
# beside it. Sizes: the hat 8.4 x 11.6 x 5.8 in; the lamp head 3 in across, 2.6 deep; the
# battery 3.8 x 1.9 x 6.6 in (README).
HARD_HAT = dict(
    A=0.415, B=0.475,                  # the dome's half width and half length at its base
    crown=0.6,                         # the crown's top over the floor (under the crest)
    mh=2.3,                            # the plan's squareness (2 an ellipse)
    mv=2.75,                           # the dome's fullness (2 a half ellipsoid; more, a fuller top)
    wall=0.016,                        # the fibreglass shell (about 4 mm with its gel coat)
    zb=0.024,                          # the dome's foot over the floor at the back
    side_lift=0.03,                    # the lip rises this much over the ears
    flare=0.032,                       # how far the lip flares out round the sides and back
    lip=0.018, edge=0.008,             # the lip's thickness and its rolled edge's radius
    visor=dict(len=0.2, span=74.0, slope=12.0),  # the peak: how far it reaches, degrees either
                                       # side of the front it spans, and its droop
    crest=dict(h=0.02, w=0.042),       # the raised ridge front to back over the crown
    band=dict(z=0.05, h=0.075, t=0.01),  # the suspension's headband, just inside the rim
    lugs=dict(y=0.02, z=0.14, r=0.034),  # the suspension's round lugs, one each side
    seed=103.0,
    dust=0.5,
)

# the leather bracket on the front: its outline (x half width at z), the steel strap across it
# that the lamp's hook drops into, and the rivets
HAT_BRACKET = dict(
    outline=[(0.088, 0.452), (0.105, 0.43), (0.105, 0.33), (0.06, 0.17), (0.022, 0.135),
             (0.0, 0.132)],            # from the top corner down to the point, the right half
    t=0.016,                           # 4 mm leather
    strap=dict(z=(0.295, 0.335), x=0.118, t=0.009),
    rivets=[(0.055, 0.425), (-0.055, 0.425), (0.0, 0.163)],
    slot=(0.03, 0.006),                # the slot the hook drops into: half width, depth
)

CAP_LAMP = dict(
    z=0.29, gap=0.012,                 # the head's axis height at its back, and its gap off the strap
    tilt=6.0,                          # degrees nodded down from level, to light where you look
    bezel=dict(r=0.15, d=0.042, lip=0.012),  # the chrome ring holding the lens
    body=dict(r0=0.128, r1=0.112, d=0.17),   # the housing: front and back radii, its depth
    back=0.035,                        # the domed back's rise
    reflector=dict(r=0.122, d=0.07),   # the bright bowl behind the lens
    bulb=dict(r=0.018, l=0.04),
    hook=dict(w=0.05, h=0.07, t=0.008),  # the flat steel tongue on its back
    knob=dict(r=0.03, h=0.036, fin=0.026, on=70.0),  # the switch on top; turned 70 degrees on
    kelvin=2900.0,                     # an incandescent miner's bulb, warm white
)

HAT_CORD = dict(
    r=0.02,                            # 1/2 in rubber cord
    clip_z=0.33,                       # the height of the clip on the back it runs through
)

HAT_BATTERY = dict(
    at=(0.66, 0.36), yaw=-28.0,        # where it stands beside the hat, turned toward the front
    w=0.38, d=0.19, h=0.6,             # the case below its lid
    lid=dict(h=0.058, over=0.008),     # the lid's height and how far it hangs over the case
    spring=dict(h=0.1, r=0.026, turns=11),  # the strain-relief spring round the cord on top
    plate=dict(w=0.16, h=0.07, z=0.43),     # the nameplate on its front
)

# --- the jar of fireflies (F-02k) -------------------------------------------------------------
# A quart canning jar of old aqua glass, 6.7 in tall and 3.9 across, its two-piece lid (a
# tinplate disc punched with nail holes, a brass-coloured screw band), a few blades of grass and
# a twig inside, and twelve fireflies (the common eastern firefly, about 14 mm long, a touch
# bigger here at 16 mm). README for the references and the flight timings.
FIREFLY_JAR = dict(
    outside=[(0.0, 0.014), (0.14, 0.008), (0.172, 0.0), (0.186, 0.006), (0.193, 0.022),
             (0.195, 0.045), (0.195, 0.44), (0.19, 0.48), (0.176, 0.52), (0.158, 0.55),
             (0.146, 0.572), (0.141, 0.59), (0.139, 0.65)],   # the glass, bottom to the rim
    inside=[(0.124, 0.652), (0.127, 0.6), (0.135, 0.575), (0.15, 0.552), (0.168, 0.522),
            (0.182, 0.485), (0.187, 0.44), (0.187, 0.05), (0.18, 0.03), (0.15, 0.024),
            (0.0, 0.028)],                                    # back down the inside to its floor
    band=dict(r=0.152, z0=0.594, z1=0.668, lip=0.126, t=0.004),  # the screw band
    disc=dict(r=0.137, z=0.654, panel=0.112, holes=23, hole=0.0055, seed=7),  # the punched lid
    turns=1.5, pitch=0.0167,           # the thread: turns to come off, studs it rises a turn
    seed=113.0,
    dust=0.5,
)

FIREFLY = dict(
    n=12,
    length=0.074,                      # 19 mm head to tail: a touch bigger than life, to read
    kelvin=None, rgb=(198, 255, 92),   # the cold yellow-green of a firefly's lantern (560 nm)
    # flight, from field records of the common eastern firefly (README): the male flies about
    # 1 to 1.5 m a second when searching, slower when he hovers; he flashes for about 3/4 of a
    # second every 5 to 6 seconds, dipping and lighting on the upswing (the J)
    flash=dict(rise=0.24, hold=0.14, fall=0.38),   # one flash: up, held, dying away (0.76 s)
    every=(4.6, 6.2),                  # seconds between a flier's flashes
    dip=0.12, climb=0.38,              # the J: how far it drops before a flash, climbs during it
    drift=16.0,                        # the swarm's loop, seconds
    reach=(0.9, 2.1),                  # each flier's loop, studs either side of its middle
    middle=1.0,                        # how far a loop's middle wanders from the jar
    height=(1.3, 3.3),                 # its loop's middle over the floor
    open=8.5,                          # the lid comes off and the last flier is out and away
    gone=4.5,                          # the minute's up: they rise and wink out
    lights=(0, 4, 8),                  # the fliers that carry a light
)


# --- the theatre spotlight (F-02l) ----------------------------------------------------------------
# A 1960s studio Fresnel with an 8 in lens, on a rolling stand at its lowest (README: the
# references). The head after the 2K "Junior" class (about 12 in across the can, 13 in long); the
# stand after a three-legged rolling stand collapsed to about 4 ft. Can-local numbers: z along the
# beam from the tilt axis (front +), y up, x across.
SPOTLIGHT = dict(
    tilt_z=4.95,            # the tilt axis over the floor: the lens's middle, a head above a kid
    can=dict(
        core=0.5,           # the sooty drum inside the louvres
        slat_r=0.548,       # the louvres' ring: 11 in across, so the can reads fat from a doorway
        slats=16, slat_w=0.2, slat_t=0.022,
        twist=30.0,         # each louvre turned like a shutter, so the dark drum shows between
        back=-0.49, front=0.45,
        bezel=dict(r_in=0.44, r_out=0.61, front=0.66),
        lens=dict(r=0.437, seat=0.56, face=0.585, steps=7),
        hub=0.56,           # where the side trunnions leave the can
        box=dict(x=0.2, y0=-0.72, y1=-0.5, z0=-0.32, z1=0.3),   # the focus box underneath
    ),
    doors=dict(
        frame=0.64, hole=0.46, z=0.665, t=0.025,   # the square frame slid into the clips
        big=dict(w0=1.2, w1=1.38, d=0.84, open=24.0),     # top and bottom leaves, splayed
        side=dict(w0=0.84, w1=0.9, d=0.55, open=26.0),    # the narrow side leaves
        clip_y=0.53,
    ),
    yoke=dict(x=0.8, r=0.045, bar_z=4.0, bend=0.17),
    stand=dict(
        top=3.62,           # the cast top cap the yoke's spigot sits on
        pin=0.3, pin_r=0.032,
        column_r=0.066, riser_r=0.05, lock_z=2.42, foot=0.4,
        hub_z=1.02,         # the cast spider the three legs hang from
        brace_z=0.46,
        reach=1.22,         # legs out to the casters: 2.4 studs across, it stands steady
        leg_r=0.04, caster_z=0.3, wheel_r=0.12, wheel_w=0.07, trail=0.06,
    ),
    kelvin=3200,            # a tungsten studio lamp
    beam=26.0,              # the cone, spot-focused: a pool a find wide at a few studs
    switch_on=50.0,         # the toggle's throw, degrees
    dust=0.55, seed=7.7,
)

# The stained-glass lamp (F-02m): a leaded-glass table lamp of the 1910s to 1930s kind, a cone
# shade of small glass pieces in lead lines on a cast bronze base with two pull-chain sockets.
# Sizes from a 15.5 in shade, 24 in tall listing (Chairish 23548881) and a 10.75 in, 17.75 in
# one: this one has a 14 in shade and stands 22 in, so it reads as a lamp, not a lampshade,
# from a doorway. The pattern is our own in that tradition (README).
STAINED_GLASS = dict(
    shade=dict(
        z0=1.30, z1=1.44,       # the apron: a 1.4 in band round the shade's foot
        top=2.02,               # the cone's top, under the vented cap
        r0=0.712, r1=0.700,     # the apron flares a little to its foot
        r_top=0.215,
        belly=0.025,            # the cone bows out this much midway: a soft bell, not a funnel
        wall=0.012,             # glass and came, an eighth of an inch
        lead=0.0068,            # a lead line's half width: an eighth of an inch across
        rim=0.0095,             # the heavier came round the foot and the top
    ),
    # the pattern, all ours: ruby four-petal blossoms on green, amber cabochons between them,
    # honey bricks to the top, a border of gold diamonds on cobalt round the apron
    band=dict(n=12, t1=0.40),   # 12 blossoms in the cone's lower 40 per cent
    bricks=dict(t=(0.40, 0.555, 0.70, 0.85, 1.0), n=(36, 30, 24, 18)),
    apron=dict(n=24),
    jewel=dict(r=0.024, rise=0.0062),
    crack=dict(cell=17),        # the apron piece with a hairline crack (front left as found)
    cap=dict(holes=((0.092, 14), (0.135, 22), (0.18, 30)), hole_r=0.0085),
    sockets=dict(x=0.10, z0=1.45, z1=1.60, r=0.034),
    chain=dict(x=0.142, z=1.555, end=1.10, bead=0.0055, step=0.0165),   # the pull 2 in under the rim, in reach
    kelvin=2700,
    dust=0.5, seed=8.3,
)
