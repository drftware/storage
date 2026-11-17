"""The home's procedural looks, baked to Roblox SurfaceAppearance maps the unit's way
(art/unit/materials.py explains the channels). Where the climb is years of wear, the home is the
building at its best kept (D-263): fresh paint with a roller's stipple, an oiled plank floor.
Named looks.py, not materials.py: the unit's bake imports `materials` by name.
"""

from materials import Channels, Stack
from nodes import Coords, hexc

PAINT = hexc("#EDE4D3")  # the plaster's fallback paint; the game paints each part (Overlay)


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


LOOKS = {"Plaster": (plaster, (4.0, 4.0), (512, 512)), "Wood": (wood, (8.0, 8.0), (1024, 1024))}
TINTED = {"Plaster"}  # ColorMap alpha = overlay: the paint is the part's Color
