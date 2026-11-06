"""Procedural PBR recipes for the unit, baked to Roblox SurfaceAppearance maps.

Every recipe returns Channels:
    col    albedo (linear). Where a surface takes the part's Color, this is the default paint.
    ova    overlay alpha: 0 where Roblox should show MeshPart.Color (paint), 1 where the
           texture covers it (rust, chips, grime). Fixed-colour sets keep it at 1.
    rough  roughness, metal metalness
    height bump height in studs-ish units, turned into the normal map by the bump node

The look: after-hours self storage, years of use. Galvanized steel with spangle and white rust,
enamel doors chalky and chipped, rust blooming from chips and rib valleys, kick marks and dolly
scuffs at the heights people actually hit things, oily concrete with saw-cut joints.
"""

import math

from nodes import NB, Coords, hexc

PAINT_DOOR = hexc("#7E2A22")     # default door enamel (overlay fallback colour)
PAINT_FACADE = hexc("#CFCAC0")   # default corridor wall paint
TRIM = hexc("#2D2F33")


class Channels:
    def __init__(self, col, ova, rough, metal, height, bump_dist=0.01, bump_strength=1.0):
        self.col, self.ova, self.rough, self.metal, self.height = col, ova, rough, metal, height
        self.bump_dist, self.bump_strength = bump_dist, bump_strength


class Stack:
    """Premultiplied layer stack for overlay colour + alpha, with roughness/metal/height."""

    def __init__(self, nb, base_col, base_rough, base_metal, base_height, base_alpha=0.0):
        self.nb = nb
        self.base = base_col
        self.C = nb.tint(base_col, base_alpha) if base_alpha else nb.rgb((0, 0, 0))
        self.A = nb.val(base_alpha) if not hasattr(base_alpha, "links") else base_alpha
        self.rough, self.metal, self.h = base_rough, base_metal, base_height

    def over(self, col, a, rough=None, metal=None, height=None, hmode="mix"):
        nb = self.nb
        ia = nb.inv(a)
        self.C = nb.mixc(1.0, nb.tint(self.C, ia), nb.tint(col, a), blend="ADD")
        self.A = nb.add(a, nb.mul(self.A, ia), clamp=True)
        if rough is not None:
            self.rough = nb.mixf(a, self.rough, rough)
        if metal is not None:
            self.metal = nb.mixf(a, self.metal, metal)
        if height is not None:
            self.h = nb.mixf(a, self.h, height) if hmode == "mix" else nb.add(self.h, nb.mul(a, height))
        return self

    def result(self, fallback=None):
        nb = self.nb
        inva = nb.div(1.0, nb.mx(self.A, 1e-4))
        straight = nb.tint(self.C, inva)
        fb = fallback if fallback is not None else self.base
        col = nb.mixc(nb.ss(self.A, 0.0, 0.02), fb, straight)
        return col, self.A


# --- shared looks --------------------------------------------------------------------------

def galvanized(nb, P, seed=0.0, spangle=13.0, dark=0.0):
    cell = nb.gray(nb.voronoi(P.v(seed=seed), spangle, out="Color"))
    mott = nb.noise(P.v(seed=seed + 1), 0.9, detail=4, rough=0.55)
    fine = nb.noise(P.v(seed=seed + 2), 40.0, detail=2)
    col = nb.mixc(nb.mr(cell, 0.0, 1.0, 0.0, 1.0), hexc("#A2A8AB"), hexc("#B5BABD"))
    col = nb.tint(col, nb.mr(mott, 0.25, 0.75, 0.84 - dark, 1.05 - dark))
    col = nb.tint(col, nb.mr(fine, 0.3, 0.7, 0.96, 1.02))
    rough = nb.add(nb.mul(cell, 0.07), nb.mr(mott, 0.25, 0.75, 0.36, 0.56))
    edge = nb.voronoi(P.v(seed=seed), spangle, feature="DISTANCE_TO_EDGE")
    h = nb.add(nb.mul(nb.ss(edge, 0.0, 0.05), 0.05), nb.mul(fine, 0.05))
    return col, rough, h


def white_rust(nb, P, amount, seed=3.0):
    """Zinc oxide blooms: chalky, rough, dull. amount 0..1 (socket or float)."""
    n = nb.noise(P.v(seed=seed), 1.8, detail=8, rough=0.65, distortion=0.4)
    thr = nb.sub(0.72, nb.mul(amount, 0.3))
    m = nb.mr(n, thr, nb.add(thr, 0.12), 0.0, 1.0, "SMOOTHSTEP")
    speck = nb.noise(P.v(seed=seed + 1), 55.0, detail=1)
    m = nb.mul(m, nb.mr(speck, 0.35, 0.6, 0.55, 1.0))
    return m, hexc("#D3D4CE")


def rust_col(nb, P, seed=5.0):
    n = nb.noise(P.v(seed=seed), 9.0, detail=8, rough=0.7)
    return nb.ramp(n, [(0.25, hexc("#2E170D")), (0.48, hexc("#5C2A12")),
                       (0.62, hexc("#8A4318")), (0.8, hexc("#A8622C"))]), n


def scratches(nb, P, scale=60.0, stretch=0.04, density=0.5, seed=7.0, width=0.018):
    """Thin isoline scratches running along U / X, sparse."""
    n = nb.noise(P.v(sx=stretch, sz=1.0, seed=seed), scale, detail=3, rough=0.5, distortion=0.2)
    line = nb.ss(nb.absf(nb.sub(n, 0.5)), width, 0.0)
    gate = nb.noise(P.v(sx=0.3, sz=1.0, seed=seed + 1), 3.0, detail=2)
    thr = nb.sub(1.0, density) if not isinstance(density, float) else 1.0 - density
    hi = nb.add(thr, 0.15) if not isinstance(thr, float) else thr + 0.15
    return nb.mul(line, nb.mr(gate, thr, hi, 0.0, 1.0, "SMOOTHSTEP"))


# --- DoorKit ---------------------------------------------------------------------------------

def slat(nb):
    """Curtain rib: enamel outside (tinted), bare galvanized inside."""
    P = Coords(nb, "world")
    _, V, _ = nb.sep(nb.uv())
    U = nb.sep(nb.uv())[0]
    front = nb.ss(V, 0.872, 0.878)
    s = nb.fract(nb.mul(V, 24.0))
    off = nb.absf(nb.sub(s, 0.5))
    crest = nb.ss(off, 0.2, 0.04)
    valley = nb.ss(off, 0.3, 0.47)
    grime = nb.objattr("grime")
    zf = nb.sep(P.pos)[2]
    low = nb.mul(grime, nb.ss(zf, 1.6, 0.25))  # the bottom ribs only (C rests at z~0.5)

    # outside: enamel
    fade = nb.noise(P.v(sx=0.25, sz=1.0, seed=11), 1.1, detail=3)
    peel = nb.noise(P.v(seed=12), 160.0, detail=1)
    st = Stack(nb, PAINT_DOOR, nb.mr(peel, 0.3, 0.7, 0.36, 0.46), 0.0,
               nb.mul(peel, 0.015))
    st.over(hexc("#D9D0C4"), nb.mr(fade, 0.35, 0.75, 0.0, 0.12), rough=0.6)
    dirt_n = nb.noise(P.v(sx=0.5, seed=13), 3.0, detail=6, rough=0.6)
    dirt_a = nb.mul(nb.add(nb.add(0.06, nb.mul(valley, 0.3)), nb.mul(low, 0.45)),
                    nb.mr(dirt_n, 0.25, 0.75, 0.3, 1.0))
    st.over(hexc("#3B3128"), nb.clamp(dirt_a), rough=0.72)
    sc = scratches(nb, P, scale=38.0, stretch=0.05, density=0.3, seed=14, width=0.012)
    sc = nb.mul(sc, nb.add(0.45, nb.mul(crest, 0.55)))
    st.over(hexc("#9EA3A6"), nb.mul(sc, 0.85), rough=0.32, metal=1.0, height=-0.4)
    chip_n = nb.noise(P.v(seed=15), 26.0, detail=6, rough=0.65)
    patch = nb.noise(P.v(seed=19), 1.3, detail=3)
    wear = nb.add(nb.add(nb.mul(crest, 0.03), nb.mul(low, 0.14)),
                  nb.mr(patch, 0.45, 0.75, -0.04, 0.06))
    chip = nb.mr(chip_n, nb.sub(0.74, wear), nb.sub(0.77, wear), 0.0, 1.0, "SMOOTHSTEP")
    primer = nb.mixc(nb.ss(chip_n, 0.8, 0.86), hexc("#8D8A80"), hexc("#70757A"))
    st.over(primer, chip, rough=0.55, metal=nb.ss(chip_n, 0.8, 0.86), height=-0.6)
    rc, rn = rust_col(nb, P, seed=16)
    rust_seed = nb.noise(P.v(seed=17), 7.0, detail=6, rough=0.6)
    rust = nb.screen(nb.mul(chip, nb.ss(rust_seed, 0.45, 0.62)),
                     nb.mul(nb.add(nb.mul(valley, 0.6), nb.mul(low, 0.7)),
                            nb.mr(rust_seed, nb.sub(0.7, nb.mul(low, 0.25)), 0.82, 0.0, 1.0,
                                  "SMOOTHSTEP")))
    st.over(rc, nb.clamp(rust), rough=0.88, metal=0.0, height=nb.mul(rn, 0.8))
    kick_n = nb.noise(P.v(sx=0.6, seed=18), 5.0, detail=4)
    kick = nb.mul(nb.mul(low, nb.ss(kick_n, 0.58, 0.68)), 0.85)
    st.over(hexc("#161514"), kick, rough=0.5)
    out_col, out_a = st.result(PAINT_DOOR)

    # inside: galvanized
    gc, gr, gh = galvanized(nb, P, seed=20)
    wr, wrc = white_rust(nb, P, nb.add(0.2, nb.mul(low, 0.6)), seed=21)
    ic = nb.mixc(wr, gc, wrc)
    ir = nb.mixf(wr, gr, 0.85)
    im = nb.mixf(wr, 0.8, 0.25)
    idirt = nb.mul(nb.add(nb.mul(valley, 0.35), nb.mul(low, 0.5)), nb.mr(dirt_n, 0.3, 0.7, 0.3, 1.0))
    ic = nb.mixc(idirt, ic, hexc("#4A4036"))
    ir = nb.mixf(idirt, ir, 0.8)
    irust = nb.mul(nb.mul(valley, nb.add(0.25, low)), nb.ss(rust_seed, 0.6, 0.75))
    ic = nb.mixc(irust, ic, rc)
    ir = nb.mixf(irust, ir, 0.9)
    im = nb.mixf(irust, im, 0.0)

    col = nb.mixc(front, ic, out_col)
    ova = nb.mixf(front, 1.0, out_a)
    rough = nb.mixf(front, ir, st.rough)
    metal = nb.mixf(front, im, st.metal)
    h = nb.mixf(front, gh, st.h)
    return Channels(col, ova, rough, metal, h, bump_dist=0.004)


def zinc(nb, P, seed=30.0, grime_ao=True):
    """Zinc-plated hardware: bright, a little blue, grimy in its corners."""
    n = nb.noise(P.v(seed=seed), 18.0, detail=5)
    col = nb.mixc(nb.mr(n, 0.3, 0.7), hexc("#9EA4A8"), hexc("#C9CED2"))
    rough = nb.mr(n, 0.3, 0.7, 0.26, 0.42)
    if grime_ao:
        ao = nb.ao(0.06, local=True)
        g = nb.ss(ao, 0.9, 0.4)
        col = nb.mixc(g, col, hexc("#3C352E"))
        rough = nb.mixf(g, rough, 0.75)
    return col, rough


def bottom_bar(nb):
    P = Coords(nb, "world")
    _, V, _ = nb.sep(nb.uv())
    seal = nb.band(V, 0.625, 0.66, 0.002)
    body = nb.band(V, 0.665, 0.745, 0.002)
    z = nb.sep(P.pos)[2]
    zr = nb.sub(z, nb.objattr("barz"))  # height above the bar's bottom edge
    # mill aluminium, brushed along X
    br = nb.noise(P.v(sx=0.02, sz=1.0, seed=31), 140.0, detail=2)
    blot = nb.noise(P.v(seed=32), 4.0, detail=5)
    al = nb.mixc(nb.mr(br, 0.3, 0.7), hexc("#8F9496"), hexc("#B3B7B9"))
    al = nb.tint(al, nb.mr(blot, 0.3, 0.7, 0.86, 1.04))
    al_r = nb.mr(br, 0.3, 0.7, 0.34, 0.5)
    ox, oxc = white_rust(nb, P, 0.35, seed=33)
    al = nb.mixc(nb.mul(ox, 0.7), al, oxc)
    al_r = nb.mixf(ox, al_r, 0.8)
    low = nb.ss(zr, 0.2, 0.08)
    dirt = nb.mul(nb.add(0.15, nb.mul(low, 0.6)), nb.mr(blot, 0.2, 0.8, 0.2, 1.0))
    al = nb.mixc(dirt, al, hexc("#2E2822"))
    al_r = nb.mixf(dirt, al_r, 0.75)
    sc = scratches(nb, P, scale=70.0, stretch=0.03, density=0.55, seed=34)
    al = nb.mixc(sc, al, hexc("#D5D8DA"))
    # rubber astragal: dusty, cracked
    cr = nb.voronoi(P.v(sx=0.25, seed=35), 30.0, feature="DISTANCE_TO_EDGE")
    crack = nb.mul(nb.ss(cr, 0.03, 0.0), nb.ss(nb.noise(P.v(seed=36), 3.0), 0.5, 0.65))
    dust = nb.mul(nb.ss(nb.noise(P.v(seed=37), 8.0, detail=5), 0.45, 0.75), 0.6)
    rb = nb.mixc(dust, hexc("#141414"), hexc("#5A5650"))
    rb = nb.mixc(crack, rb, hexc("#050505"))
    rb_r = nb.mixf(dust, 0.72, 0.92)
    # handles and latch: zinc
    zc, zr2 = zinc(nb, P, seed=38)
    grip = nb.mul(nb.ss(nb.noise(P.v(seed=39), 6.0), 0.4, 0.7), 0.5)
    zc = nb.mixc(grip, zc, hexc("#D8DCDF"))

    col = nb.mixc(seal, nb.mixc(body, zc, al), rb)
    rough = nb.mixf(seal, nb.mixf(body, zr2, al_r), rb_r)
    metal = nb.mixf(seal, 1.0, 0.0)
    h = nb.add(nb.mul(body, nb.add(nb.mul(br, 0.05), nb.mul(sc, -0.4))), nb.mul(seal, nb.mul(crack, -1.0)))
    return Channels(col, 1.0, rough, metal, h, bump_dist=0.003)


def latch_bolt(nb):
    P = Coords(nb, "world")
    zc, zr = zinc(nb, P, seed=40)
    pol = nb.ss(nb.noise(P.v(sx=0.05, seed=41), 30.0, detail=2), 0.45, 0.6)
    col = nb.mixc(nb.mul(pol, 0.6), zc, hexc("#E3E6E8"))
    return Channels(col, 1.0, nb.mixf(pol, zr, 0.18), 1.0, nb.mul(pol, 0.1), bump_dist=0.002)


def padlock(nb, spec):
    P = Coords(nb, "object")
    z = nb.sep(P.pos)[2]
    shackle = nb.ss(z, -0.062, -0.05)
    lam = nb.fract(nb.mul(nb.add(z, 0.235), 1.0 / 0.03))
    lam_i = nb.math("FLOOR", nb.mul(nb.add(z, 0.235), 1.0 / 0.03))
    tone = nb.fract(nb.mul(nb.sin(nb.mul(lam_i, 12.9898)), 43758.5453))
    body = nb.mixc(nb.mr(tone, 0.0, 1.0, 0.0, 1.0), hexc("#3E4246"), hexc("#5A5F64"))
    n = nb.noise(P.v(seed=42), 60.0, detail=4)
    body = nb.tint(body, nb.mr(n, 0.3, 0.7, 0.85, 1.08))
    edge = nb.edge(0.006, k=8.0)
    body = nb.mixc(nb.mul(edge, 0.7), body, hexc("#A8AEB3"))
    rust_m = nb.mul(nb.ss(nb.noise(P.v(seed=43), 20.0, detail=6), 0.62, 0.72), nb.ss(lam, 0.2, 0.0))
    rc, _ = rust_col(nb, P, seed=44)
    body = nb.mixc(rust_m, body, rc)
    sh = nb.mixc(nb.mr(n, 0.3, 0.7), hexc("#B9BEC2"), hexc("#E1E4E6"))
    col = nb.mixc(shackle, body, sh)
    import parts
    L = parts.latch_layout(spec)
    cx = (L["fixed_ear"] + L["moving_locked"]) / 2
    rad = nb.vop("LENGTH", nb.vop("SUBTRACT", nb.vop("MULTIPLY", P.pos, (1, 1, 0)), (cx, L["ear_y"], 0)))
    brass = nb.mul(nb.ss(z, -0.229, -0.233), nb.ss(rad, 0.03, 0.026))
    col = nb.mixc(brass, col, hexc("#9C7A43"))
    rough = nb.mixf(shackle, nb.mixf(rust_m, nb.mr(n, 0.3, 0.7, 0.3, 0.45), 0.85), 0.2)
    metal = nb.mixf(rust_m, 1.0, 0.0)
    h = nb.add(nb.mul(nb.ss(lam, 0.0, 0.12), 0.3), nb.mul(n, 0.05))
    return Channels(col, 1.0, rough, metal, h, bump_dist=0.003)


def hardware(nb, spec):
    """Head plates (galvanized), axle (oily steel), spring tension wheel (red enamel)."""
    P = Coords(nb, "world")
    _, dy, dz = spec.drum_center
    x, y, z = nb.sep(P.pos)
    r = nb.math("SQRT", nb.add(nb.mul(nb.sub(y, dy), nb.sub(y, dy)), nb.mul(nb.sub(z, dz), nb.sub(z, dz))))
    cw2 = spec.curtain_width / 2
    wheel = nb.mul(nb.ss(x, cw2 + 0.215, cw2 + 0.225), nb.ss(r, 0.375, 0.365))
    axle = nb.mul(nb.ss(r, 0.085, 0.078), nb.ss(nb.absf(x), cw2 + 0.215, cw2 + 0.205))
    gc, gr, gh = galvanized(nb, P, seed=50, spangle=10.0, dark=0.06)
    oil = nb.mul(nb.ss(r, 0.5, 0.15), nb.ss(nb.noise(P.v(sz=0.3, seed=51), 4.0, detail=5), 0.4, 0.7))
    gc = nb.mixc(nb.mul(oil, 0.7), gc, hexc("#2B2620"))
    gr = nb.mixf(oil, gr, 0.22)
    ao = nb.ao(0.08, local=True)
    gc = nb.mixc(nb.ss(ao, 0.9, 0.45), gc, hexc("#3A332B"))
    red = hexc("#A3241B")
    chip = nb.ss(nb.noise(P.v(seed=52), 30.0, detail=6), 0.7, 0.74)
    edge = nb.edge(0.008, k=6.0)
    chip = nb.screen(chip, nb.mul(edge, nb.ss(nb.noise(P.v(seed=53), 50.0), 0.45, 0.55)))
    wc = nb.mixc(chip, red, hexc("#55585B"))
    wr = nb.mixf(chip, 0.42, 0.4)
    ac = hexc("#2F2C28")
    col = nb.mixc(wheel, nb.mixc(axle, gc, ac), wc)
    rough = nb.mixf(wheel, nb.mixf(axle, gr, 0.3), wr)
    metal = nb.mixf(wheel, 1.0, chip)
    h = nb.mixf(wheel, gh, nb.mul(chip, -0.5))
    return Channels(col, 1.0, rough, metal, h, bump_dist=0.003)


def drum(nb):
    P = Coords(nb, "world")
    gc, gr, gh = galvanized(nb, P, seed=60, spangle=11.0)
    oil = nb.ss(nb.noise(P.v(sx=0.2, seed=61), 2.0, detail=6), 0.5, 0.8)
    col = nb.mixc(nb.mul(oil, 0.6), gc, hexc("#2C2722"))
    return Channels(col, 1.0, nb.mixf(oil, gr, 0.25), 1.0, gh, bump_dist=0.003)


def plate(nb):
    """Engraved two-ply plastic: black face, white core where the edges are worn."""
    P = Coords(nb, "world")
    edge = nb.edge(0.006, k=5.0)
    n = nb.noise(P.v(seed=70), 30.0, detail=4)
    dust = nb.mul(nb.ss(nb.noise(P.v(seed=71), 6.0, detail=5), 0.45, 0.8), 0.35)
    col = nb.mixc(nb.mul(edge, 0.9), hexc("#121314"), hexc("#D9D8D2"))
    col = nb.mixc(dust, col, hexc("#6B665E"))
    return Channels(col, 1.0, nb.mr(n, 0.3, 0.7, 0.5, 0.62), 0.0, nb.mul(n, 0.1), bump_dist=0.002)


# --- tiling sets ---------------------------------------------------------------------------

def facade(nb):
    """Corridor wall panels, 4 studs wide (tiles in U) x 10 tall. Paint is the part's Color."""
    P = Coords(nb, "cyl", tile_u=4.0, len_v=10.0)
    U, V = P.u, P.vv
    zh = P.height()
    us = nb.mul(U, 4.0)
    # panel seams every 2 studs, mini ribs every quarter stud
    seam_d = nb.absf(nb.sub(nb.fract(nb.mul(U, 2.0)), 0.5))  # 0.5 at a seam
    seam = nb.ss(seam_d, 0.494, 0.4995)
    rib = nb.mul(nb.sub(1.0, nb.absf(nb.sin(nb.mul(us, math.pi * 4)))), 1.0)
    # screws down each seam, 0.08 studs either side of it, every 1.3 studs
    dv = nb.mul(nb.sub(nb.fract(nb.div(nb.sub(zh, 0.45), 1.3)), 0.5), 1.3)
    du = nb.mul(nb.sub(seam_d, 0.46), 2.0)
    sd = nb.math("SQRT", nb.add(nb.mul(dv, dv), nb.mul(du, du)))
    screw = nb.mul(nb.ss(sd, 0.03, 0.021), nb.ss(zh, 9.7, 9.6))
    peel = nb.noise(P.v(seed=1), 120.0, detail=1)
    st = Stack(nb, PAINT_FACADE, nb.mr(peel, 0.3, 0.7, 0.38, 0.5), 0.0,
               nb.add(nb.add(nb.mul(rib, 0.25), nb.mul(seam, -2.5)), nb.mul(peel, 0.05)))
    mott = nb.noise(P.v(seed=2), 0.8, detail=4)
    st.over(hexc("#FFFFFF"), nb.mr(mott, 0.55, 0.8, 0.0, 0.07))
    st.over(hexc("#6A6052"), nb.mr(mott, 0.45, 0.2, 0.0, 0.08), rough=0.6)
    # drips from the top cap
    drip_n = nb.noise(P.v(sx=1.0, sz=0.06, seed=3), 6.0, detail=5)
    drip = nb.mul(nb.ss(drip_n, 0.6, 0.72), nb.mul(nb.ss(zh, 3.0, 9.0), 0.35))
    st.over(hexc("#7A6448"), drip, rough=0.62)
    # grime: low on the wall and in the seams
    g_n = nb.noise(P.v(seed=4), 2.5, detail=6, rough=0.6)
    grime = nb.add(nb.mul(nb.ss(zh, 1.4, 0.0), 0.4), nb.mul(seam, 0.45))
    st.over(hexc("#433A30"), nb.clamp(nb.mul(grime, nb.mr(g_n, 0.2, 0.8, 0.35, 1.0))), rough=0.75)
    # dolly and cart scuffs, 0.7 to 3.2 studs up
    band = nb.band(zh, 0.8, 3.0, 0.5)
    sc_n = nb.noise(P.v(sx=0.08, sz=1.0, seed=5), 7.0, detail=4, distortion=0.3)
    sc_gate = nb.noise(P.v(sx=0.4, seed=6), 1.4, detail=3)
    scuff = nb.mul(nb.mul(nb.ss(sc_n, 0.6, 0.68), nb.ss(sc_gate, 0.5, 0.62)), band)
    st.over(hexc("#1B1A19"), nb.mul(scuff, 0.8), rough=0.55)
    lines = nb.mul(scratches(nb, P, scale=40.0, stretch=0.05, density=0.5, seed=8), band)
    st.over(hexc("#9C9A93"), nb.mul(lines, 0.8), rough=0.5, height=-0.8)
    # chips to primer where things hit
    chip_n = nb.noise(P.v(seed=9), 18.0, detail=6, rough=0.65)
    chip = nb.mul(nb.ss(chip_n, 0.78, 0.8), nb.add(nb.mul(band, 1.0), 0.15))
    st.over(hexc("#7F7E78"), chip, rough=0.6, height=-1.0)
    rc, _ = rust_col(nb, P, seed=10)
    st.over(rc, nb.mul(chip, nb.ss(chip_n, 0.83, 0.88)), rough=0.85)
    st.over(hexc("#A6ABAE"), screw, rough=0.35, metal=1.0, height=1.5)
    # dents
    dent_n = nb.voronoi(P.v(seed=11), 1.6, feature="F1")
    dent = nb.mul(nb.ss(dent_n, 0.12, 0.0), nb.mul(band, 0.6))
    st.h = nb.sub(st.h, nb.mul(dent, 2.0))
    col, a = st.result(PAINT_FACADE)
    return Channels(col, a, st.rough, st.metal, st.h, bump_dist=0.006)


def partition(nb):
    """R-panel partitions, 4 studs (tiles in U) x 10 tall; the tracks live in the top/bottom bands."""
    P = Coords(nb, "cyl", tile_u=4.0, len_v=10.0)
    U, V = P.u, P.vv
    zh = P.height()
    f = nb.fract(nb.mul(U, 4.0))  # position within each stud: major rib at 0.32..0.68
    gc, gr, gh = galvanized(nb, P, seed=80)
    minor = nb.add(nb.band(f, 0.115, 0.135, 0.02), nb.band(f, 0.865, 0.885, 0.02))
    flank = nb.add(nb.band(f, 0.3, 0.34, 0.03), nb.band(f, 0.66, 0.7, 0.03))
    track = nb.add(nb.ss(V, 0.016, 0.012), nb.ss(V, 0.984, 0.988))
    # screws through each track at every flat (f = 0), 0.07 studs in from each end
    dx = nb.sub(nb.fract(nb.add(f, 0.5)), 0.5)  # studs from the flat's middle
    dz = nb.mn(nb.absf(nb.sub(zh, 0.07)), nb.absf(nb.sub(zh, 9.93)))
    sd = nb.math("SQRT", nb.add(nb.mul(dx, dx), nb.mul(dz, dz)))
    screw = nb.ss(sd, 0.034, 0.024)
    col = nb.tint(gc, nb.mixf(track, 1.0, 0.92))
    rough = gr
    # white rust low down where the floor gets mopped
    wr, wrc = white_rust(nb, P, nb.add(0.1, nb.mul(nb.ss(zh, 2.0, 0.0), 0.7)), seed=81)
    col = nb.mixc(wr, col, wrc)
    rough = nb.mixf(wr, rough, 0.85)
    metal = nb.mixf(wr, 0.7, 0.25)
    # streaks and dust
    stk = nb.noise(P.v(sx=1.0, sz=0.05, seed=82), 5.0, detail=6)
    stk_m = nb.mul(nb.ss(stk, 0.58, 0.75), 0.35)
    col = nb.mixc(stk_m, col, hexc("#5B5246"))
    rough = nb.mixf(stk_m, rough, 0.6)
    dust_n = nb.noise(P.v(seed=83), 3.0, detail=6)
    low = nb.ss(zh, 1.0, 0.0)
    dirt = nb.clamp(nb.mul(nb.add(nb.add(nb.mul(low, 0.55), nb.mul(flank, 0.18)), 0.04),
                           nb.mr(dust_n, 0.2, 0.8, 0.4, 1.0)))
    col = nb.mixc(dirt, col, hexc("#3E362D"))
    rough = nb.mixf(dirt, rough, 0.78)
    metal = nb.mixf(dirt, metal, 0.4)
    # scrapes from things stored against it
    band = nb.band(zh, 0.4, 4.5, 0.6)
    lines = nb.mul(scratches(nb, P, scale=45.0, stretch=0.05, density=0.45, seed=84), band)
    col = nb.mixc(nb.mul(lines, 0.8), col, hexc("#D6DADC"))
    rough = nb.mixf(lines, rough, 0.2)
    rc, rn = rust_col(nb, P, seed=85)
    rmask = nb.mul(nb.ss(nb.noise(P.v(seed=86), 6.0, detail=7), 0.7, 0.8), nb.add(nb.mul(low, 0.8), nb.mul(screw, 0.0)))
    rust_screw = nb.mul(screw, nb.ss(nb.noise(P.v(seed=87), 10.0), 0.45, 0.6))
    rmask = nb.screen(rmask, nb.mul(rust_screw, 0.8))
    col = nb.mixc(rmask, col, rc)
    rough = nb.mixf(rmask, rough, 0.9)
    metal = nb.mixf(rmask, metal, 0.0)
    col = nb.mixc(screw, col, hexc("#AEB3B6"))
    h = nb.add(nb.add(gh, nb.mul(minor, 1.2)), nb.add(nb.mul(screw, 1.6), nb.mul(lines, -0.5)))
    col = nb.tint(col, nb.mixf(flank, 1.0, 0.85))
    return Channels(col, 1.0, rough, metal, h, bump_dist=0.006)


def concrete(nb):
    """Sealed slab, 8 x 8 studs, tiles both ways; a saw-cut control joint on the tile edge."""
    P = Coords(nb, "torus", tile_u=8.0, tile_v=8.0)
    U, V = P.u, P.vv
    big = nb.noise(P.v(seed=1), 0.35, detail=5, rough=0.55)
    mid = nb.noise(P.v(seed=2), 1.6, detail=6, rough=0.6, distortion=0.6)
    burn = nb.noise(P.v(seed=3), 0.9, detail=8, rough=0.7, distortion=1.4)
    col = nb.mixc(nb.mr(big, 0.25, 0.75), hexc("#6F6C66"), hexc("#9A968E"))
    col = nb.tint(col, nb.mr(mid, 0.3, 0.7, 0.9, 1.06))
    burn_m = nb.ss(burn, 0.56, 0.7)
    col = nb.mixc(nb.mul(burn_m, 0.55), col, hexc("#55524D"))
    rough = nb.mixf(burn_m, nb.mr(mid, 0.3, 0.7, 0.62, 0.8), 0.42)
    agg = nb.voronoi(P.v(seed=4), 38.0, out="Color")
    aggv = nb.gray(agg)
    agg_d = nb.voronoi(P.v(seed=4), 38.0)
    speck = nb.mul(nb.ss(agg_d, 0.22, 0.12), nb.ss(aggv, 0.75, 0.85))
    col = nb.mixc(nb.mul(speck, 0.5), col, nb.mixc(nb.ss(aggv, 0.85, 0.95), hexc("#ABA79F"), hexc("#3E3B37")))
    pores = nb.mul(nb.ss(nb.noise(P.v(seed=5), 90.0, detail=1), 0.72, 0.8), 0.6)
    col = nb.mixc(pores, col, hexc("#3A3834"))
    # hairline cracks
    cr = nb.voronoi(P.v(sx=1.0, seed=6), 0.55, feature="DISTANCE_TO_EDGE")
    crn = nb.noise(P.v(seed=7), 1.2, detail=3)
    crack = nb.mul(nb.ss(cr, 0.006, 0.001), nb.ss(crn, 0.6, 0.66))
    col = nb.mixc(nb.mul(crack, 0.7), col, hexc("#2C2A26"))
    damp = nb.ss(nb.noise(P.v(seed=12), 0.25, detail=4, distortion=0.8), 0.55, 0.75)
    col = nb.mixc(nb.mul(damp, 0.35), col, hexc("#5E5A53"))
    cloud = nb.noise(P.v(seed=13), 2.6, detail=8, rough=0.68, distortion=0.9)
    col = nb.tint(col, nb.mr(cloud, 0.3, 0.7, 0.88, 1.08))
    # oil and water stains
    oil_n = nb.noise(P.v(seed=8), 0.6, detail=6, rough=0.65, distortion=0.5)
    oil = nb.ss(oil_n, 0.68, 0.74)
    col = nb.mixc(nb.mul(oil, 0.75), col, hexc("#2E2A25"))
    rough = nb.mixf(oil, rough, 0.28)
    ring = nb.mul(nb.band(oil_n, 0.62, 0.64, 0.01), 0.35)
    col = nb.mixc(ring, col, hexc("#B2AEA5"))
    # wheel marks: long dark smudges
    tm = nb.noise(P.v(sx=1.0, sz=0.08, seed=9), 3.0, detail=4)
    tire = nb.mul(nb.ss(tm, 0.62, 0.7), 0.35)
    col = nb.mixc(tire, col, hexc("#2A2724"))
    rough = nb.mixf(tire, rough, 0.55)
    # control joint along the tile's edges
    du = nb.absf(nb.sub(nb.fract(nb.add(U, 0.5)), 0.5))
    dv = nb.absf(nb.sub(nb.fract(nb.add(V, 0.5)), 0.5))
    joint = nb.mx(nb.ss(du, 0.004, 0.0015), nb.ss(dv, 0.004, 0.0015))
    jdirt = nb.mx(nb.ss(du, 0.012, 0.003), nb.ss(dv, 0.012, 0.003))
    col = nb.mixc(nb.mul(jdirt, 0.45), col, hexc("#3B3731"))
    col = nb.mixc(joint, col, hexc("#1E1C1A"))
    rough = nb.mixf(jdirt, rough, 0.85)
    h = nb.add(nb.add(nb.mul(mid, 0.15), nb.mul(pores, -0.6)),
               nb.add(nb.mul(crack, -1.2), nb.mul(joint, -2.0)))
    h = nb.add(h, nb.mul(nb.voronoi(P.v(seed=4), 38.0), 0.12))
    return Channels(col, 1.0, rough, 0.0, h, bump_dist=0.006)


# --- trim sheet strips ---------------------------------------------------------------------

def strip(nb, name):
    """One strip of the trim sheet. Tiles along U every 4 studs; 0.5 studs across."""
    P = Coords(nb, "cyl", tile_u=4.0, len_v=4.0)
    U, V = P.u, P.vv
    a = nb.fract(nb.mul(V, 8.0))  # 0..1 across this strip
    edge = nb.add(nb.ss(a, 0.075, 0.03), nb.ss(a, 0.925, 0.97))
    us = nb.mul(U, 4.0)
    if name in ("trim", "scuffed"):
        heavy = 1.0 if name == "scuffed" else 0.0
        peel = nb.noise(P.v(seed=1), 130.0, detail=1)
        col = nb.tint(TRIM, nb.mr(nb.noise(P.v(seed=2), 1.0, detail=4), 0.3, 0.7, 0.85, 1.12))
        rough = nb.mr(peel, 0.3, 0.7, 0.34, 0.44)
        metal = 0.0
        chip_n = nb.noise(P.v(seed=3), 24.0, detail=6, rough=0.65)
        thr = 0.72 - 0.12 * heavy
        chip = nb.mr(chip_n, nb.sub(thr, nb.mul(edge, 0.12)), nb.sub(thr + 0.02, nb.mul(edge, 0.12)),
                     0.0, 1.0, "SMOOTHSTEP")
        col = nb.mixc(chip, col, hexc("#787D82"))
        rough = nb.mixf(chip, rough, 0.32)
        metal = nb.mixf(chip, 0.0, 1.0)
        rc, _ = rust_col(nb, P, seed=4)
        rust = nb.mul(chip, nb.ss(chip_n, thr + 0.07, thr + 0.12))
        col = nb.mixc(rust, col, rc)
        rough = nb.mixf(rust, rough, 0.85)
        metal = nb.mixf(rust, metal, 0.0)
        lt = scratches(nb, P, scale=36.0 if heavy else 50.0, stretch=0.05, density=0.3 + 0.25 * heavy,
                       seed=5, width=0.012)
        col = nb.mixc(nb.mul(lt, 0.8), col, hexc("#8A8F93"))
        sc_n = nb.noise(P.v(sx=0.3, seed=6), 6.0, detail=4)
        scuff = nb.mul(nb.ss(sc_n, 0.62 - 0.08 * heavy, 0.7 - 0.08 * heavy), 0.5 + 0.3 * heavy)
        col = nb.mixc(scuff, col, nb.mixc(nb.ss(sc_n, 0.7, 0.8), hexc("#6E6B66"), hexc("#141312")))
        dust = nb.mul(nb.ss(nb.noise(P.v(seed=7), 4.0, detail=6), 0.5, 0.8), 0.25)
        col = nb.mixc(dust, col, hexc("#5C564D"))
        rough = nb.mixf(dust, rough, 0.7)
        h = nb.add(nb.mul(peel, 0.03), nb.add(nb.mul(chip, -0.8), nb.mul(lt, -0.5)))
        return Channels(col, 1.0, rough, metal, h, bump_dist=0.004)
    if name == "diamond":
        p = 4.0 / 28.0
        uu = nb.div(us, p)
        vv = nb.div(nb.mul(a, 0.5), p)
        lx = nb.sub(nb.fract(uu), 0.5)
        ly = nb.sub(nb.fract(vv), 0.5)
        chk = nb.math("MODULO", nb.add(nb.math("FLOOR", uu), nb.math("FLOOR", vv)), 2.0)
        sg = nb.sub(nb.mul(chk, 2.0), 1.0)
        rx = nb.mul(nb.add(lx, nb.mul(sg, ly)), 0.7071)
        ry = nb.mul(nb.sub(ly, nb.mul(sg, lx)), 0.7071)
        e = nb.add(nb.pw(nb.div(rx, 0.43), 2.0), nb.pw(nb.div(ry, 0.135), 2.0))
        lug = nb.ss(e, 1.0, 0.35)
        base = nb.mixc(nb.mr(nb.noise(P.v(seed=10), 3.0, detail=4), 0.3, 0.7), hexc("#8C9193"), hexc("#B2B6B8"))
        top = nb.mul(lug, nb.ss(nb.noise(P.v(seed=11), 40.0), 0.3, 0.6))
        col = nb.mixc(nb.mul(top, 0.7), base, hexc("#DADDDF"))
        grime = nb.mul(nb.inv(lug), nb.mr(nb.noise(P.v(seed=12), 5.0, detail=5), 0.2, 0.8, 0.25, 0.85))
        grime = nb.add(grime, nb.mul(nb.ss(a, 0.4, 0.0), 0.3))
        col = nb.mixc(nb.clamp(grime), col, hexc("#3A332B"))
        sc = nb.mul(nb.ss(nb.noise(P.v(sx=0.08, seed=13), 7.0, detail=4), 0.62, 0.7), 0.7)
        col = nb.mixc(sc, col, hexc("#1B1A19"))
        rough = nb.mixf(top, nb.mixf(nb.clamp(grime), 0.42, 0.75), 0.22)
        return Channels(col, 1.0, rough, nb.mixf(nb.clamp(grime), 1.0, 0.5), nb.mul(lug, 1.0),
                        bump_dist=0.012)
    if name in ("channel", "pipe", "wire"):
        sp = {"channel": 12.0, "pipe": 16.0, "wire": 20.0}[name]
        gc, gr, gh = galvanized(nb, P, seed=20 + len(name), spangle=sp, dark=0.04 if name == "wire" else 0.0)
        dust = nb.mul(nb.ss(nb.noise(P.v(seed=24), 5.0, detail=6), 0.4, 0.75),
                      0.55 if name == "wire" else 0.3)
        col = nb.mixc(dust, gc, hexc("#6A645A"))
        rough = nb.mixf(dust, nb.add(gr, 0.08 if name == "wire" else 0.0), 0.75)
        wr, wrc = white_rust(nb, P, 0.25, seed=25)
        col = nb.mixc(wr, col, wrc)
        rough = nb.mixf(wr, rough, 0.85)
        rc, _ = rust_col(nb, P, seed=26)
        rs = nb.mul(nb.ss(nb.noise(P.v(seed=27), 8.0, detail=7), 0.74, 0.82), 0.9)
        col = nb.mixc(rs, col, rc)
        rough = nb.mixf(rs, rough, 0.9)
        metal = nb.mixf(nb.screen(rs, nb.mul(dust, 0.5)), 0.78, 0.2)
        return Channels(col, 1.0, rough, metal, nb.add(gh, nb.mul(edge, 0.3)), bump_dist=0.004)
    if name == "raw":
        n = nb.noise(P.v(seed=30), 12.0, detail=6)
        col = nb.mixc(nb.mr(n, 0.3, 0.7), hexc("#2E2C2A"), hexc("#4A4743"))
        rc, _ = rust_col(nb, P, seed=31)
        rs = nb.ss(nb.noise(P.v(seed=32), 6.0, detail=6), 0.58, 0.7)
        col = nb.mixc(rs, col, rc)
        oil = nb.ss(nb.noise(P.v(seed=33), 3.0, detail=4), 0.5, 0.7)
        rough = nb.mixf(rs, nb.mixf(oil, 0.55, 0.22), 0.88)
        return Channels(col, 1.0, rough, nb.mixf(rs, 0.85, 0.0), nb.mul(n, 0.2), bump_dist=0.003)
    if name == "rubber":
        n = nb.noise(P.v(seed=40), 30.0, detail=4)
        dust = nb.mul(nb.ss(nb.noise(P.v(seed=41), 5.0, detail=5), 0.5, 0.8), 0.5)
        col = nb.mixc(dust, hexc("#151515"), hexc("#55524C"))
        return Channels(col, 1.0, nb.mixf(dust, 0.75, 0.9), 0.0, nb.mul(n, 0.1), bump_dist=0.003)
    raise KeyError(name)
