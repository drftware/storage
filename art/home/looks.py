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
CARPET = hexc("#CDBFA6")  # the looks' fallbacks under a clear alpha (each the first of its
TILE = hexc("#B8654A")    # palette in home_spec.py): the game paints the floor's colour
RUBBER = hexc("#3D3B39")


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


# --- the looks a player gives their home (S5-03g1a, D-321) ---------------------------------------
# Floors tile at 8 x 8 studs (the Wood set's), papers at 4 x 4 (the Plaster set's), so one floor
# panel and one wall panel wear any of them. Each takes a colour where it should: the part's Color
# shows wherever the map's alpha is 0 (Overlay), so a checker's dark squares, a carpet's pile, a
# mat's rubber and a paper's ground are whatever the player picks; what's baked (the cream
# squares, the flecks, the leaves and daisies) keeps its own colour on every choice.

def cell_rnd(nb, ident, k=12.9898, m=43758.5453):
    """A steady 0..1 for a cell's number (the wood's planks use the same hash)."""
    return nb.fract(nb.mul(nb.sin(nb.mul(ident, k)), m))


def carpet(nb):
    """A soft cut-pile carpet, 8 x 8 studs, tiles both ways: the colour is the part's; the map adds
    the shade between tufts, a heather of lighter fibres and the faint lanes a vacuum leaves."""
    P = Coords(nb, "torus", tile_u=8.0, tile_v=8.0)
    tuft = nb.noise(P.v(seed=71), 40.0, detail=2, rough=0.6)
    fibre = nb.noise(P.v(seed=72), 110.0, detail=1)
    cloud = nb.noise(P.v(seed=73), 0.7, detail=3)
    # the lanes a vacuum leaves: four across a tile, coming and going, never a regular stripe
    lanes = nb.sin(nb.mul(nb.add(P.u, nb.mul(nb.noise(P.v(seed=74), 0.4, detail=2), 0.05)),
                          6.2831853 * 4.0))
    fade = nb.mr(nb.noise(P.v(seed=75), 0.5, detail=2), 0.4, 0.65)
    h = nb.add(nb.mul(tuft, 0.7), nb.mul(fibre, 0.3))
    st = Stack(nb, CARPET, nb.mr(tuft, 0.3, 0.7, 0.97, 0.9), 0.0, h)
    st.over(hexc("#000000"), nb.mr(tuft, 0.62, 0.3, 0.0, 0.3))
    st.over(hexc("#FFFFFF"), nb.mr(fibre, 0.6, 0.78, 0.0, 0.16))
    st.over(hexc("#FFFFFF"), nb.mul(nb.mr(lanes, 0.0, 1.0, 0.0, 0.035), fade))
    st.over(hexc("#000000"), nb.mr(cloud, 0.45, 0.25, 0.0, 0.07))
    col, a = st.result(CARPET)
    return Channels(col, a, st.rough, 0.0, st.h, bump_dist=0.004, bump_strength=0.8)


def tiles(nb):
    """Checkerboard tiles, 8 x 8 studs, six squares across (1.33 studs each), tiles both ways: cream
    squares baked, the others the part's colour, every square its own faint shade under a glaze,
    a pale grout between and a softly rounded edge."""
    P = Coords(nb, "torus", tile_u=8.0, tile_v=8.0)
    gx, gy = nb.mul(P.u, 6.0), nb.mul(P.vv, 6.0)
    fx, fy = nb.fract(gx), nb.fract(gy)
    ix, iy = nb.sub(gx, fx), nb.sub(gy, fy)
    cream = nb.mul(nb.fract(nb.mul(nb.add(ix, iy), 0.5)), 2.0)  # 1 on the cream squares
    rnd = cell_rnd(nb, nb.add(ix, nb.mul(iy, 6.0)))
    g = nb.mn(nb.mn(fx, nb.sub(1.0, fx)), nb.mn(fy, nb.sub(1.0, fy)))
    grout = nb.ss(g, 0.026, 0.016)
    edge = nb.ss(g, 0.02, 0.07)  # 0 at the grout, 1 once past the rounded edge
    glaze = nb.noise(P.v(seed=91), 1.4, detail=3)
    st = Stack(nb, TILE, nb.mr(glaze, 0.3, 0.7, 0.2, 0.3), 0.0, nb.mul(edge, 0.6))
    st.over(nb.tint(hexc("#EFE6D2"), nb.mr(rnd, 0.0, 1.0, 0.95, 1.02)), cream)
    st.over(hexc("#000000"), nb.mul(nb.inv(cream), nb.mr(rnd, 0.0, 1.0, 0.0, 0.09)))
    st.over(hexc("#FFFFFF"), nb.mr(glaze, 0.55, 0.8, 0.0, 0.05))
    st.over(hexc("#CBC2B1"), grout, rough=0.85, height=-0.4)
    col, a = st.result(TILE)
    return Channels(col, a, st.rough, 0.0, st.h, bump_dist=0.004, bump_strength=0.7)


def matting(nb):
    """Interlocking rubber mats, 8 x 8 studs, four 2-stud mats across with square teeth where they
    join, tiles both ways: the rubber is the part's colour, flecked with cream, clay, teal and
    mustard crumb (baked), matte with a fine grip."""
    P = Coords(nb, "torus", tile_u=8.0, tile_v=8.0)
    gx, gy = nb.mul(P.u, 4.0), nb.mul(P.vv, 4.0)
    tx = nb.ss(nb.sin(nb.mul(gy, 6.2831853 * 5.0)), -0.15, 0.15)  # five teeth along each join
    ty = nb.ss(nb.sin(nb.mul(gx, 6.2831853 * 5.0)), -0.15, 0.15)
    fx = nb.fract(nb.add(gx, nb.mul(nb.sub(tx, 0.5), 0.07)))
    fy = nb.fract(nb.add(gy, nb.mul(nb.sub(ty, 0.5), 0.07)))
    g = nb.mn(nb.mn(fx, nb.sub(1.0, fx)), nb.mn(fy, nb.sub(1.0, fy)))
    seam = nb.ss(g, 0.016, 0.006)  # a dark join about 0.05 studs wide, so the mats read as mats
    grip = nb.noise(P.v(seed=81), 70.0, detail=2)
    st = Stack(nb, RUBBER, nb.mr(grip, 0.3, 0.7, 0.8, 0.9), 0.0, nb.mul(grip, 0.3))
    st.over(hexc("#000000"), nb.mr(grip, 0.3, 0.7, 0.12, 0.0))
    for seed, c in ((82, "#E9E0CC"), (83, "#C0704F"), (84, "#3F8A86"), (85, "#D6A443")):
        fleck = nb.ss(nb.noise(P.v(seed=seed), 9.0, detail=1), 0.705, 0.725)
        st.over(hexc(c), fleck, height=0.25)
    st.over(hexc("#000000"), nb.mul(seam, 0.75), rough=0.95, height=-1.0)
    col, a = st.result(RUBBER)
    return Channels(col, a, st.rough, 0.0, st.h, bump_dist=0.004, bump_strength=0.7)


def paper_ground(nb, P, st):
    """Every paper's own grain over the paint: a little fibre and the faintest cloud."""
    fibre = nb.noise(P.v(sz=0.4, seed=95), 60.0, detail=2)
    cloud = nb.noise(P.v(seed=96), 0.9, detail=3)
    st.over(hexc("#000000"), nb.mr(fibre, 0.55, 0.75, 0.0, 0.05))
    st.over(hexc("#FFFFFF"), nb.mr(cloud, 0.55, 0.8, 0.0, 0.04))


def stripes(nb):
    """A regency stripe, 4 x 4 studs, tiles both ways: half-stud satin cream stripes up the wall
    (V) with a fine pinstripe down the middle of each painted one, the painted ones matte. The
    paint is the part's Color."""
    P = Coords(nb, "torus", tile_u=4.0, tile_v=4.0)
    s = nb.fract(nb.mul(P.u, 4.0))
    cream = nb.band(s, 0.0, 0.5, 0.012)
    pin = nb.band(s, 0.735, 0.765, 0.006)
    st = Stack(nb, PAINT, 0.78, 0.0, 0.0)
    st.over(hexc("#F1E9D8"), nb.mx(cream, pin), rough=0.55, height=0.05)
    paper_ground(nb, P, st)
    col, a = st.result(PAINT)
    return Channels(col, a, st.rough, 0.0, st.h, bump_dist=0.003, bump_strength=0.4)


def leaf_at(nb, x, y, ang, half, wide):
    """One leaf in a cell's frame (x, y from its middle, studs): turned by `ang`, `half` long
    from its middle to the tip, `wide` at its widest. Returns (the leaf, its midrib and stem,
    which side of the rib, 0..1 tip to tip)."""
    c, s = nb.cos(ang), nb.sin(ang)
    rx = nb.add(nb.mul(x, c), nb.mul(y, s))
    ry = nb.sub(nb.mul(y, c), nb.mul(x, s))
    t = nb.div(ry, half)
    w = nb.mul(nb.mx(nb.sub(1.0, nb.mul(t, t)), 0.0), wide)
    ax = nb.absf(rx)
    leaf = nb.mul(nb.ss(nb.sub(w, ax), 0.0, 0.01), nb.ss(nb.sub(1.0, nb.absf(t)), 0.0, 0.03))
    rib = nb.mul(nb.band(ax, -0.01, 0.007, 0.004), nb.band(t, -1.3, 0.85, 0.03))
    side = nb.ss(rx, -0.01, 0.01)
    return leaf, rib, side, nb.mr(t, -1.0, 1.0)


def leaves(nb):
    """A botanical paper, 4 x 4 studs, tiles both ways: a leaf tossed in every stud-square cell (half
    dropped down every other column) and a smaller one beside it, sage, deep green and olive, a
    pale midrib and one side of each in shade. The ground is the paint (the part's Color)."""
    P = Coords(nb, "torus", tile_u=4.0, tile_v=4.0)
    gx = nb.mul(P.u, 4.0)
    col_i = nb.sub(gx, nb.fract(gx))
    drop = nb.mul(nb.fract(nb.mul(col_i, 0.5)), 1.0)  # 0.5 on odd columns: a half drop
    gy = nb.add(nb.mul(P.vv, 4.0), drop)
    row_i = nb.mul(nb.fract(nb.mul(nb.sub(gy, nb.fract(gy)), 0.25)), 4.0)  # 0..3, so it tiles
    x, y = nb.sub(nb.fract(gx), 0.5), nb.sub(nb.fract(gy), 0.5)
    ident = nb.add(col_i, nb.mul(row_i, 4.0))
    r1, r2, r3 = cell_rnd(nb, ident), cell_rnd(nb, ident, 78.233, 12543.137), \
        cell_rnd(nb, ident, 39.425, 24634.634)
    st = Stack(nb, PAINT, 0.74, 0.0, 0.0)
    paper_ground(nb, P, st)
    greens = nb.mixc(nb.ss(r2, 0.35, 0.65), hexc("#8FA27F"), hexc("#4D6A4B"))
    greens = nb.mixc(nb.ss(r3, 0.8, 0.85), greens, hexc("#7F7C46"))
    for ox, oy, ang, half, wide in ((0.0, 0.0, nb.mul(r1, 6.2831853), 0.4, 0.15),
                                    (0.25, -0.24, nb.add(nb.mul(r1, 6.2831853), 2.2), 0.19, 0.07)):
        leaf, rib, side, _ = leaf_at(nb, nb.sub(x, ox), nb.sub(y, oy), ang, half, wide)
        shade = nb.tint(greens, nb.mixf(side, 1.0, 0.82))
        st.over(shade, leaf, rough=0.6, height=0.08)
        st.over(hexc("#C9CFAE"), nb.mul(rib, 0.85))
    col, a = st.result(PAINT)
    return Channels(col, a, st.rough, 0.0, st.h, bump_dist=0.003, bump_strength=0.4)


def daisies(nb):
    """A daisy paper, 4 x 4 studs, tiles both ways: a five-petal daisy in every stud-square cell
    (half dropped down every other column), each turned its own way, cream petals round a mustard
    middle. The ground is the paint (the part's Color)."""
    P = Coords(nb, "torus", tile_u=4.0, tile_v=4.0)
    gx = nb.mul(P.u, 4.0)
    col_i = nb.sub(gx, nb.fract(gx))
    gy = nb.add(nb.mul(P.vv, 4.0), nb.fract(nb.mul(col_i, 0.5)))
    row_i = nb.mul(nb.fract(nb.mul(nb.sub(gy, nb.fract(gy)), 0.25)), 4.0)
    x, y = nb.sub(nb.fract(gx), 0.5), nb.sub(nb.fract(gy), 0.5)
    rnd = cell_rnd(nb, nb.add(col_i, nb.mul(row_i, 4.0)))
    r = nb.pw(nb.add(nb.mul(x, x), nb.mul(y, y)), 0.5)
    th = nb.add(nb.math("ARCTAN2", y, x), nb.mul(rnd, 6.2831853))
    petal = nb.absf(nb.cos(nb.mul(th, 2.5)))  # five lobes round the middle
    reach = nb.mul(nb.add(0.5, nb.mul(petal, 0.5)), 0.24)
    flower = nb.ss(nb.sub(reach, r), 0.0, 0.012)
    crease = nb.mul(flower, nb.mr(petal, 0.2, 0.0, 0.0, 0.35))  # a soft line between petals
    middle = nb.ss(nb.sub(0.06, r), 0.0, 0.008)
    st = Stack(nb, PAINT, 0.74, 0.0, 0.0)
    paper_ground(nb, P, st)
    st.over(hexc("#F4EEDF"), flower, rough=0.6, height=0.08)
    st.over(hexc("#B9AE98"), crease)
    st.over(hexc("#D9A63A"), middle, height=0.12)
    col, a = st.result(PAINT)
    return Channels(col, a, st.rough, 0.0, st.h, bump_dist=0.003, bump_strength=0.4)


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
         "Rug": (rug, (8.0, 6.0), (512, 512)),
         "FloorCarpet": (carpet, (8.0, 8.0), (512, 512)),
         "FloorTiles": (tiles, (8.0, 8.0), (1024, 1024)),
         "FloorMatting": (matting, (8.0, 8.0), (1024, 1024)),
         "PaperStripes": (stripes, (4.0, 4.0), (512, 512)),
         "PaperLeaves": (leaves, (4.0, 4.0), (1024, 1024)),
         "PaperDaisies": (daisies, (4.0, 4.0), (512, 512))}
SIZES = {"HomeDoor": (1024, 1024)}
TINTED = {"Plaster", "Fabric", "HomeDoor", "FloorCarpet", "FloorTiles", "FloorMatting",
          "PaperStripes", "PaperLeaves", "PaperDaisies"}  # ColorMap alpha = overlay: the part's colour
