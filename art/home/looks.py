"""The home's procedural looks, baked to Roblox SurfaceAppearance maps the unit's way
(art/unit/materials.py explains the channels). Where the climb is years of wear, the home is the
building at its best kept (D-263): fresh paint with a roller's stipple, an oiled plank floor.
Named looks.py, not materials.py: the unit's bake imports `materials` by name.
"""

from materials import Channels, Stack, galvanized, zinc
from nodes import Coords, hexc

PAINT = hexc("#EDE4D3")  # the plaster's fallback paint; the game paints each part (Overlay)
DOOR = hexc("#B5684E")   # the home door's fallback enamel; the game paints it warm (Overlay)
CLOTH = hexc("#D8C9A8")  # the fabric's fallback colour; the game dyes each piece (Overlay)


def plaster(nb):
    """Painted plaster, 4 x 4 studs, tiles both ways. The paint is the part's Color: the map adds
    only a roller's stipple, a satin sheen that breaks up a little, and the faintest cloud."""
    P = Coords(nb, "torus", tile_u=4.0, tile_v=4.0)
    stip = nb.noise(P.v(seed=1), 38.0, detail=2, rough=0.55)
    fine = nb.noise(P.v(seed=2), 130.0, detail=1)
    cloud = nb.noise(P.v(seed=3), 0.8, detail=4, rough=0.6)
    h = nb.add(nb.mul(stip, 0.6), nb.mul(fine, 0.25))
    st = Stack(nb, PAINT, nb.mr(stip, 0.3, 0.7, 0.6, 0.76), 0.0, h)
    st.over(hexc("#FFFFFF"), nb.mr(cloud, 0.55, 0.8, 0.0, 0.05))
    st.over(hexc("#4E4032"), nb.mr(cloud, 0.42, 0.2, 0.0, 0.05))
    col, a = st.result(PAINT)
    return Channels(col, a, st.rough, st.metal, st.h, bump_dist=0.004, bump_strength=0.5)


def wood(nb):
    """An oiled oak plank floor, 8 x 8 studs, tiles both ways: twelve planks across (U), each
    column's planks 8/3 long (V) with their ends staggered, every plank its own shade."""
    P = Coords(nb, "torus", tile_u=8.0, tile_v=8.0)
    U, V = P.u, P.vv
    across = nb.mul(U, 12.0)
    fx = nb.fract(across)
    column = nb.sub(across, fx)
    off = nb.fract(nb.mul(column, 0.618034))
    along = nb.add(nb.mul(V, 3.0), off)
    fy = nb.fract(along)
    plank = nb.add(nb.sub(along, fy), nb.mul(column, 7.31))
    rnd = nb.fract(nb.mul(nb.sin(nb.mul(plank, 12.9898)), 43758.5453))
    rnd2 = nb.fract(nb.mul(nb.sin(nb.mul(plank, 78.233)), 12543.137))
    # grain: long streaks down each plank, shifted per plank so neighbours don't line up
    grain = nb.noise(P.v(sx=2.4, sz=0.1, seed=5), 7.0, detail=6,
                     rough=0.6, distortion=0.4)
    figure = nb.noise(P.v(sx=6.0, sz=0.35, seed=6), 3.0, detail=4, distortion=1.2)
    rings = nb.fract(nb.add(nb.mul(figure, 9.0), nb.mul(rnd, 3.0)))
    ring = nb.mul(nb.band(rings, 0.0, 0.18, 0.06), 0.35)
    light, mid, dark = hexc("#B38D66"), hexc("#9C7856"), hexc("#86644A")
    col = nb.mixc(nb.mr(rnd, 0.0, 1.0, 0.15, 0.85), light, dark)
    col = nb.mixc(nb.mul(nb.ss(rnd2, 0.55, 0.9), 0.5), col, mid)
    col = nb.tint(col, nb.mr(grain, 0.3, 0.7, 0.86, 1.1))
    col = nb.mixc(ring, col, hexc("#6A4428"))
    # seams: a fine bevel down each plank's edge and across its ends
    sx = nb.mn(fx, nb.sub(1.0, fx))
    sy = nb.mn(fy, nb.sub(1.0, fy))
    seam = nb.mx(nb.ss(sx, 0.03, 0.006), nb.ss(sy, 0.006, 0.0012))
    col = nb.mixc(nb.mul(seam, 0.8), col, hexc("#3A2717"))
    # gentle wear where people walk: a faint dull cloud, no scratches (it's looked after)
    walk = nb.noise(P.v(seed=8), 0.5, detail=3)
    rough = nb.mixf(nb.mr(walk, 0.4, 0.7, 0.0, 1.0), 0.5, 0.62)
    rough = nb.add(rough, nb.mul(nb.mr(grain, 0.3, 0.7, -0.04, 0.05), 1.0))
    rough = nb.mixf(seam, rough, 0.85)
    h = nb.add(nb.mul(seam, -2.0), nb.add(nb.mul(grain, 0.12), nb.mul(ring, 0.2)))
    return Channels(col, 1.0, rough, 0.0, h, bump_dist=0.005, bump_strength=0.8)


def leaf(nb):
    """The snake plant's leaves and its soil, 2 x 4 studs, not tiled. Above V 0.14 four leaf
    columns side by side (U quarters, one leaf's width each, base to tip up V): dark green
    crossed by wavy grey-green bands, a yellow margin down both edges, a waxy sheen. Below V 0.12
    the potting soil, dark and crumbly with flecks of perlite (the pot's and planter's top)."""
    P = Coords(nb, "world")
    U, V, _ = nb.sep(nb.uv())
    cu = nb.fract(nb.mul(U, 4.0))
    ci = nb.sub(nb.mul(U, 4.0), cu)
    along = nb.mr(V, 0.14, 1.0, 0.0, 1.0)
    wob = nb.noise(P.v(seed=41), 2.2, detail=3)
    zig = nb.mul(nb.absf(nb.sub(nb.fract(nb.mul(cu, 2.0)), 0.5)), 0.7)  # chevrons across the leaf
    t = nb.add(nb.add(nb.mul(along, 19.0), nb.mul(ci, 0.37)), nb.add(zig, nb.mul(wob, 1.4)))
    b = nb.fract(t)
    width = nb.noise(P.v(seed=42), 5.0, detail=2)
    light = nb.mul(nb.ss(b, 0.02, 0.09),  # a band's far edge wanders: some bands thin, some wide
                   nb.mr(b, 0.16, nb.mr(width, 0.3, 0.7, 0.22, 0.46), 1.0, 0.0, "SMOOTHSTEP"))
    speck = nb.noise(P.v(seed=43), 60.0, detail=2)
    dark, pale = hexc("#22391F"), hexc("#7D9670")
    col = nb.mixc(nb.mul(light, nb.mr(speck, 0.3, 0.7, 0.6, 1.0)), dark, pale)
    col = nb.tint(col, nb.mr(nb.noise(P.v(seed=44), 1.2, detail=3), 0.3, 0.7, 0.85, 1.12))
    rim = nb.mx(nb.ss(cu, 0.1, 0.06), nb.ss(cu, 0.9, 0.94))
    edge = nb.mx(nb.ss(cu, 0.07, 0.035), nb.ss(cu, 0.93, 0.965))
    col = nb.mixc(nb.mul(rim, 0.7), col, hexc("#7E8F3A"))
    col = nb.mixc(edge, col, hexc("#D2BE4C"))
    tip = nb.ss(along, 0.94, 1.0)  # the tip dries a little
    col = nb.mixc(nb.mul(tip, 0.5), col, hexc("#8C7A45"))
    rough = nb.mixf(light, 0.36, 0.48)
    h = nb.add(nb.mul(light, 0.12), nb.mul(edge, -0.1))
    # soil
    lump = nb.noise(P.v(seed=45), 14.0, detail=5, rough=0.65)
    perl = nb.ss(nb.noise(P.v(seed=46), 34.0, detail=1), 0.7, 0.76)
    sc = nb.mixc(nb.mr(lump, 0.3, 0.7), hexc("#241A12"), hexc("#4A3626"))
    sc = nb.mixc(perl, sc, hexc("#D8D3C6"))
    soil = nb.ss(V, 0.13, 0.12)
    col = nb.mixc(soil, col, sc)
    rough = nb.mixf(soil, rough, nb.mixf(perl, 0.95, 0.8))
    h = nb.mixf(soil, h, nb.add(nb.mul(lump, 0.6), nb.mul(perl, 0.3)))
    return Channels(col, 1.0, rough, 0.0, h, bump_dist=0.004, bump_strength=0.6)


def fabric(nb):
    """A soft canvas weave, 2 x 2 studs, tiles both ways: the beanbag's cover and the lamp's
    shade. The colour is the part's (Overlay); the maps add the threads and a little fuzz."""
    P = Coords(nb, "torus", tile_u=2.0, tile_v=2.0)
    n = 56.0
    wu = nb.sin(nb.mul(P.u, 6.2831853 * n))
    wv = nb.sin(nb.mul(P.vv, 6.2831853 * n))
    weave = nb.mul(wu, wv)
    fuzz = nb.noise(P.v(seed=51), 40.0, detail=3)
    slub = nb.noise(P.v(sx=3.0, seed=52), 3.0, detail=2)
    st = Stack(nb, CLOTH, nb.mr(fuzz, 0.3, 0.7, 0.8, 0.92), 0.0,
               nb.add(nb.mul(weave, 0.5), nb.mul(fuzz, 0.3)))
    st.over(hexc("#000000"), nb.mr(weave, -1.0, -0.2, 0.1, 0.0))
    st.over(hexc("#FFFFFF"), nb.mul(nb.mr(slub, 0.55, 0.8, 0.0, 1.0), 0.06))
    col, a = st.result(CLOTH)
    return Channels(col, a, st.rough, 0.0, st.h, bump_dist=0.003, bump_strength=0.6)


def rug(nb):
    """The starter rug, 8 x 6 studs, the whole rug on the map: a flat-weave in terracotta, teal,
    mustard and oatmeal, a border round a plain field and a stepped diamond in the middle. Its
    colours are baked: it's the same rug in every unit until Arrange brings others."""
    P = Coords(nb, "world")
    U, V, _ = nb.sep(nb.uv())
    x, y = nb.mul(nb.sub(U, 0.5), 8.0), nb.mul(nb.sub(V, 0.5), 6.0)
    e = nb.mn(nb.sub(4.0, nb.absf(x)), nb.sub(3.0, nb.absf(y)))  # studs in from the edge
    terra, teal = hexc("#9E4A31"), hexc("#2F5F5C")
    mustard, oat = hexc("#C8973D"), hexc("#E2D5BA")
    col = oat
    col = nb.mixc(nb.band(e, 0.86, 0.96, 0.01), col, terra)
    col = nb.mixc(nb.band(e, 0.42, 0.86, 0.01), col, teal)
    col = nb.mixc(nb.band(e, 0.30, 0.42, 0.01), col, oat)
    col = nb.mixc(nb.ss(e, 0.31, 0.29), col, terra)
    # little mustard steps along the teal band
    step = nb.fract(nb.mul(nb.add(x, y), 1.4))
    dots = nb.mul(nb.band(e, 0.56, 0.72, 0.01), nb.band(step, 0.3, 0.6, 0.02))
    col = nb.mixc(dots, col, mustard)
    # the middle: a stepped diamond, terracotta round teal round mustard
    d = nb.add(nb.absf(nb.div(x, 2.3)), nb.absf(nb.div(y, 1.55)))
    dq = nb.div(nb.sub(nb.mul(d, 9.0), nb.fract(nb.mul(d, 9.0))), 9.0)  # steps, as a weave makes them
    col = nb.mixc(nb.ss(dq, 1.0, 0.98), col, terra)
    col = nb.mixc(nb.ss(dq, 0.67, 0.65), col, oat)
    col = nb.mixc(nb.ss(dq, 0.56, 0.54), col, teal)
    col = nb.mixc(nb.ss(dq, 0.23, 0.21), col, mustard)
    # the weave: weft rows across, the yarn's own variation, a little wear down the middle
    weft = nb.sin(nb.mul(V, 6.2831853 * 150.0))
    abrash = nb.noise(P.v(seed=61), 1.6, detail=3)
    fibre = nb.noise(P.v(seed=62), 70.0, detail=2)
    col = nb.tint(col, nb.mr(abrash, 0.3, 0.7, 0.9, 1.06))
    col = nb.tint(col, nb.mr(weft, -1.0, 1.0, 0.9, 1.04))
    col = nb.tint(col, nb.mr(fibre, 0.3, 0.7, 0.94, 1.04))
    fringe = nb.ss(nb.sub(4.0, nb.absf(x)), 0.06, 0.0)
    col = nb.mixc(fringe, col, hexc("#EDE3CF"))
    h = nb.add(nb.mul(weft, 0.35), nb.mul(fibre, 0.3))
    return Channels(col, 1.0, nb.mr(fibre, 0.3, 0.7, 0.86, 0.95), 0.0, h, bump_dist=0.003,
                    bump_strength=0.6)


# --- the home door: the climb's roll-up door kept new (HomeDoor, D-266) -------------------------

def door_slat(nb):
    """A curtain rib kept new: satin enamel outside, the part's colour (Overlay), with only an
    orange peel and the faintest fade; bright galvanized inside. The slat's bands as the DoorKit's
    (art/unit/parts.py SLAT_BANDS), so the climb's meshes wear it unchanged."""
    P = Coords(nb, "world")
    _, V, _ = nb.sep(nb.uv())
    front = nb.ss(V, 0.872, 0.878)
    off = nb.absf(nb.sub(nb.fract(nb.mul(V, 24.0)), 0.5))
    valley = nb.ss(off, 0.3, 0.47)
    peel = nb.noise(P.v(seed=12), 160.0, detail=1)
    fade = nb.noise(P.v(sx=0.25, sz=1.0, seed=11), 1.1, detail=3)
    st = Stack(nb, DOOR, nb.mr(peel, 0.3, 0.7, 0.3, 0.38), 0.0, nb.mul(peel, 0.012))
    st.over(hexc("#FFFFFF"), nb.mr(fade, 0.35, 0.75, 0.0, 0.04), rough=0.4)
    st.over(hexc("#3B3128"), nb.mul(valley, 0.08), rough=0.45)
    out_col, out_a = st.result(DOOR)
    gc, gr, gh = galvanized(nb, P, seed=20)
    return Channels(nb.mixc(front, gc, out_col), nb.mixf(front, 1.0, out_a),
                    nb.mixf(front, gr, st.rough), nb.mixf(front, 0.8, st.metal),
                    nb.mixf(front, gh, st.h), bump_dist=0.004)


def door_bar(nb):
    """The bottom bar kept new: brushed aluminium, a clean black seal, bright zinc handles. The
    DoorKit's bands (BAR_BODY_BAND, BAR_SEAL_BAND)."""
    P = Coords(nb, "world")
    _, V, _ = nb.sep(nb.uv())
    seal = nb.band(V, 0.625, 0.66, 0.002)
    body = nb.band(V, 0.665, 0.745, 0.002)
    br = nb.noise(P.v(sx=0.02, sz=1.0, seed=31), 140.0, detail=2)
    al = nb.mixc(nb.mr(br, 0.3, 0.7), hexc("#9BA0A2"), hexc("#BCC0C2"))
    al_r = nb.mr(br, 0.3, 0.7, 0.3, 0.42)
    zc, zr = zinc(nb, P, seed=38, grime_ao=False)
    col = nb.mixc(seal, nb.mixc(body, zc, al), hexc("#1B1B1B"))
    rough = nb.mixf(seal, nb.mixf(body, zr, al_r), 0.7)
    metal = nb.mixf(seal, 1.0, 0.0)
    return Channels(col, 1.0, rough, metal, nb.mul(body, nb.mul(br, 0.05)), bump_dist=0.003)


# set -> (recipe, bake plane in studs, map size); HomeDoor bakes on the door's own parts (build.py)
LOOKS = {"Plaster": (plaster, (4.0, 4.0), (512, 512)), "Wood": (wood, (8.0, 8.0), (1024, 1024)),
         "Leaf": (leaf, (2.0, 4.0), (512, 1024)), "Fabric": (fabric, (2.0, 2.0), (512, 512)),
         "Rug": (rug, (8.0, 6.0), (512, 512))}
SIZES = {"HomeDoor": (1024, 1024)}
TINTED = {"Plaster", "Fabric", "HomeDoor"}  # ColorMap alpha = overlay: the colour is the part's
