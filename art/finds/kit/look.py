"""What a find's surfaces are made of: the recipe helpers a find's look is written with.

A look is a function `look(L) -> Surface`: L hands out the find's coordinates (its own frame, at
rest), which kind of face it is, normals, noise and masks; a Coat stacks paint layers; the
Surface it returns is what the kit bakes (colour, roughness, metalness, a height for the fine
bump, glow: where it lights up, and alpha: how solid it is, 1 everywhere but a clear part's glass
or flame).
"""

from nodes import hexc  # noqa: F401  (re-exported for looks)


class Surface:
    def __init__(self, col, rough, metal, height=0.0, glow=0.0, bump_dist=0.002, bump=0.6,
                 alpha=1.0):
        self.col, self.rough, self.metal, self.height, self.glow = col, rough, metal, height, glow
        self.bump_dist, self.bump, self.alpha = bump_dist, bump, alpha


class Look:
    """Coordinates and masks for a recipe. Position is the find's own frame (the bake poses
    every part at rest), so a mask written in studs lands where the spec says."""

    def __init__(self, nb, seed=0.0):
        self.nb, self.seed = nb, seed
        self.P = nb.geo().outputs["Position"]
        self.x, self.y, self.z = nb.sep(self.P)
        self.N = nb.geo().outputs["Normal"]
        self.nx, self.ny, self.nz = nb.sep(self.N)
        self.kind = nb.node("ShaderNodeAttribute", attribute_type="GEOMETRY",
                            attribute_name="kind").outputs["Fac"]
        self.up = nb.ss(self.nz, 0.35, 0.9)

    def k(self, *ks):
        """1 on faces of any of these kinds."""
        nb, m = self.nb, None
        for k in ks:
            one = nb.band(self.kind, k - 0.4, k + 0.4, 0.05)
            m = one if m is None else nb.add(m, one, clamp=True)
        return m

    def vec(self, sx=1.0, sy=1.0, sz=1.0, s=0.0):
        nb, sd = self.nb, self.seed
        v = nb.vop("MULTIPLY", self.P, (sx, sy, sz))
        return nb.vop("ADD", v, (sd * 7.13 + s * 3.1, sd * 3.71 + s * 5.3, sd * 5.27 + s * 1.7)), None

    def noise(self, scale, s, stretch=(1.0, 1.0, 1.0), **kw):
        return self.nb.noise(self.vec(*stretch, s=s), scale, **kw)

    def ao(self, dist):
        return self.nb.ao(dist, local=False)

    def edge(self, radius=0.006, k=5.0):
        return self.nb.edge(radius, k=k)


class Coat:
    """Paint layers, each mixed in where a mask says."""

    def __init__(self, L, col, rough, metal=0.0, height=0.0):
        self.L, self.nb = L, L.nb
        self.col, self.rough, self.metal, self.height = col, rough, metal, height
        self.glow = 0.0
        self.alpha = 1.0

    def paint(self, mask, col=None, rough=None, metal=None, height=None, alpha=None):
        """`alpha` is how solid it is there (glass about 0.1 to 0.3, 1 solid); only a clear
        part (kit.Part(clear=True)) shows it."""
        nb = self.nb
        if alpha is not None:
            self.alpha = nb.mixf(mask, self.alpha, alpha)
        if col is not None:
            self.col = nb.mixc(mask, self.col, col)
        if rough is not None:
            self.rough = nb.mixf(mask, self.rough, rough)
        if metal is not None:
            self.metal = nb.mixf(mask, self.metal, metal)
        if height is not None:
            self.height = nb.add(self.height, nb.mul(mask, height))

    def lights(self, mask):
        """Where the find glows when it's on (the bake's emissive mask)."""
        nb = self.nb
        self.glow = mask if isinstance(self.glow, float) else nb.add(self.glow, mask, clamp=True)

    def enamel_wear(self, mask, under, s, amount=1.0):
        """Chipped enamel: knocks on the edges and a few on the faces show what's under."""
        L, nb = self.L, self.nb
        edge = L.edge(0.008, k=4.0)
        # on the edges, broken up so a rim wears in bites, never a painted band; a few on faces
        bites = nb.mul(nb.mul(edge, min(amount, 1.0)), nb.ss(L.noise(22.0, s + 1, detail=4), 0.52, 0.6))
        chips = nb.mx(nb.ss(bites, 0.35, 0.45),
                      nb.ss(L.noise(14.0, s, detail=4, rough=0.65), 0.84, 0.87))
        m = nb.mul(mask, chips)
        self.paint(m, under, 0.55, 0.85, -0.25)
        return m

    def finish(self, dust, grime=0.6, s=40, keep=None):
        """Grime in the creases, then dust on whatever faces up, thinner on the edges; none
        where `keep` (a mask) says it's sealed away (the wax inside the blob lamp's bottle)."""
        L, nb = self.L, self.nb
        self.col = nb.tint(self.col, nb.mr(L.ao(0.05), 0.0, 1.0, 1.0 - grime, 1.0))
        if dust <= 0:
            return
        film = nb.mr(L.noise(2.2, s, detail=6, rough=0.6, distortion=0.5), 0.2, 0.8, 0.25, 0.9)
        edge = L.edge(0.01, k=5.0)
        d = nb.mul(nb.mul(L.up, film), nb.mul(dust, nb.inv(nb.mul(edge, 0.7))))
        speck = nb.mul(nb.mul(L.up, nb.ss(L.noise(110.0, s + 1, detail=2), 0.6, 0.72)), 0.4 * dust)
        d = nb.add(d, speck, clamp=True)
        if keep is not None:
            d = nb.mul(d, nb.inv(keep))
        self.paint(nb.mul(d, 0.6), hexc("#A39A8C"))
        self.paint(d, rough=0.95, metal=0.0, height=0.04)
        if not isinstance(self.alpha, float):
            # dust on glass is a grey film you can't see through
            self.alpha = nb.add(self.alpha, nb.mul(d, 0.75), clamp=True)

    def surface(self, bump_dist=0.002, bump=0.6):
        return Surface(self.col, self.rough, self.metal, self.height, self.glow, bump_dist, bump,
                       self.alpha)
