"""A small DSL for Cycles shader node trees: sockets in, sockets out.

    nb = NB(material)
    h = nb.noise(P.v(), 4.0, detail=6)
    m = nb.ss(h, 0.45, 0.55)          # smoothstep
    nb.mixc(m, (0.2, 0.2, 0.2), rust)  # colour mix

Coordinates come from a `Coords` provider so every recipe can run on real geometry (world
position) or on a tiling bake plane (UV mapped onto a cylinder or a Clifford torus, so noise
repeats exactly at the texture's edge without seams or stretching).
"""

import math

import bpy

SOCK = bpy.types.NodeSocket


class NB:
    def __init__(self, mat):
        mat.use_nodes = True
        self.mat = mat
        self.nt = mat.node_tree
        self.nt.nodes.clear()
        self.links = self.nt.links
        self._x = 0

    # --- plumbing -------------------------------------------------------------------------
    def node(self, t, **props):
        n = self.nt.nodes.new(t)
        for k, v in props.items():
            setattr(n, k, v)
        n.location = (self._x, 0)
        self._x += 40
        return n

    def put(self, sock, val):
        if isinstance(val, SOCK):
            self.links.new(val, sock)
        elif val is None:
            return
        else:
            if sock.type == "RGBA" and isinstance(val, (int, float)):
                val = (val, val, val, 1.0)
            elif sock.type == "RGBA" and len(val) == 3:
                val = (*val, 1.0)
            elif sock.type == "VECTOR" and isinstance(val, (int, float)):
                val = (val, val, val)
            sock.default_value = val

    def val(self, v):
        n = self.node("ShaderNodeValue")
        n.outputs[0].default_value = v
        return n.outputs[0]

    def rgb(self, c):
        n = self.node("ShaderNodeRGB")
        n.outputs[0].default_value = (*c, 1.0) if len(c) == 3 else c
        return n.outputs[0]

    # --- math -----------------------------------------------------------------------------
    def math(self, op, a, b=0.0, c=0.0, clamp=False):
        n = self.node("ShaderNodeMath", operation=op, use_clamp=clamp)
        self.put(n.inputs[0], a)
        self.put(n.inputs[1], b)
        self.put(n.inputs[2], c)
        return n.outputs[0]

    def add(self, a, b, clamp=False): return self.math("ADD", a, b, clamp=clamp)
    def sub(self, a, b, clamp=False): return self.math("SUBTRACT", a, b, clamp=clamp)
    def mul(self, a, b, clamp=False): return self.math("MULTIPLY", a, b, clamp=clamp)
    def div(self, a, b): return self.math("DIVIDE", a, b)
    def mn(self, a, b): return self.math("MINIMUM", a, b)
    def mx(self, a, b): return self.math("MAXIMUM", a, b)
    def pw(self, a, b): return self.math("POWER", a, b)
    def fract(self, a): return self.math("FRACT", a)
    def absf(self, a): return self.math("ABSOLUTE", a)
    def sin(self, a): return self.math("SINE", a)
    def cos(self, a): return self.math("COSINE", a)
    def clamp(self, a): return self.math("ADD", a, 0.0, clamp=True)
    def inv(self, a): return self.math("SUBTRACT", 1.0, a, clamp=True)

    def screen(self, a, b):
        """1 - (1-a)(1-b): union of soft masks."""
        return self.inv(self.mul(self.inv(a), self.inv(b)))

    def mr(self, v, a, b, c=0.0, d=1.0, interp="LINEAR", clamp=True):
        n = self.node("ShaderNodeMapRange", interpolation_type=interp, clamp=clamp)
        self.put(n.inputs[0], v)
        self.put(n.inputs[1], a)
        self.put(n.inputs[2], b)
        self.put(n.inputs[3], c)
        self.put(n.inputs[4], d)
        return n.outputs[0]

    def ss(self, v, a, b):
        """Smoothstep from a to b (a > b gives the falling edge)."""
        if a > b:
            return self.mr(v, b, a, 1.0, 0.0, "SMOOTHSTEP")
        return self.mr(v, a, b, 0.0, 1.0, "SMOOTHSTEP")

    def band(self, v, lo, hi, soft):
        """1 inside [lo, hi], soft edges."""
        return self.mul(self.ss(v, lo - soft, lo), self.ss(v, hi + soft, hi))

    def mixf(self, f, a, b):
        n = self.node("ShaderNodeMix", data_type="FLOAT", clamp_factor=True)
        self.put(n.inputs[0], f)
        self.put(n.inputs[2], a)
        self.put(n.inputs[3], b)
        return n.outputs[0]

    def mixc(self, f, a, b, blend="MIX"):
        n = self.node("ShaderNodeMix", data_type="RGBA", blend_type=blend, clamp_factor=True)
        self.put(n.inputs[0], f)
        self.put(n.inputs[6], a)
        self.put(n.inputs[7], b)
        return n.outputs[2]

    def mixv(self, f, a, b):
        n = self.node("ShaderNodeMix", data_type="VECTOR", clamp_factor=True)
        self.put(n.inputs[0], f)
        self.put(n.inputs[4], a)
        self.put(n.inputs[5], b)
        return n.outputs[1]

    def tint(self, c, k):
        """Scale a colour's value by k (k a float or socket)."""
        n = self.node("ShaderNodeMix", data_type="RGBA", blend_type="MULTIPLY", clamp_factor=True)
        self.put(n.inputs[0], 1.0)
        self.put(n.inputs[6], c)
        kk = self.comb(k, k, k) if isinstance(k, SOCK) else (k, k, k)
        self.put(n.inputs[7], kk)
        return n.outputs[2]

    def gray(self, c):
        n = self.node("ShaderNodeRGBToBW")
        self.put(n.inputs[0], c)
        return n.outputs[0]

    # --- vectors --------------------------------------------------------------------------
    def sep(self, v):
        n = self.node("ShaderNodeSeparateXYZ")
        self.put(n.inputs[0], v)
        return n.outputs[0], n.outputs[1], n.outputs[2]

    def comb(self, x, y, z):
        n = self.node("ShaderNodeCombineXYZ")
        self.put(n.inputs[0], x)
        self.put(n.inputs[1], y)
        self.put(n.inputs[2], z)
        return n.outputs[0]

    def vop(self, op, a, b=None, scale=None):
        n = self.node("ShaderNodeVectorMath", operation=op)
        self.put(n.inputs[0], a)
        if b is not None:
            self.put(n.inputs[1], b)
        if scale is not None:
            self.put(n.inputs[3], scale)
        return n.outputs[1] if op in ("DOT_PRODUCT", "LENGTH", "DISTANCE") else n.outputs[0]

    # --- inputs ---------------------------------------------------------------------------
    def geo(self):
        return self.node("ShaderNodeNewGeometry")

    def uv(self):
        return self.node("ShaderNodeTexCoord").outputs["UV"]

    def objattr(self, name, kind="Factor"):
        n = self.node("ShaderNodeAttribute", attribute_type="OBJECT", attribute_name=name)
        return n.outputs[kind]

    def ao(self, dist, local=True, samples=16):
        n = self.node("ShaderNodeAmbientOcclusion", samples=samples, only_local=local)
        self.put(n.inputs[1], dist)
        return n.outputs["AO"]

    def edge(self, radius, k=6.0):
        """Convex-and-concave edge mask from the Bevel node."""
        b = self.node("ShaderNodeBevel", samples=8)
        self.put(b.inputs[0], radius)
        g = self.geo()
        d = self.vop("DOT_PRODUCT", b.outputs[0], g.outputs["Normal"])
        return self.mul(self.sub(1.0, d), k, clamp=True)

    # --- textures -------------------------------------------------------------------------
    def noise(self, vw, scale, detail=2.0, rough=0.5, distortion=0.0, lac=2.0, ntype="FBM",
              color=False):
        vec, w = vw
        n = self.node("ShaderNodeTexNoise", noise_dimensions="4D" if w is not None else "3D",
                      noise_type=ntype, normalize=True)
        self.put(n.inputs["Vector"], vec)
        if w is not None:
            self.put(n.inputs["W"], w)
        self.put(n.inputs["Scale"], scale)
        self.put(n.inputs["Detail"], detail)
        self.put(n.inputs["Roughness"], rough)
        self.put(n.inputs["Lacunarity"], lac)
        self.put(n.inputs["Distortion"], distortion)
        return n.outputs[1] if color else n.outputs[0]

    def voronoi(self, vw, scale, feature="F1", rand=1.0, out="Distance"):
        vec, w = vw
        n = self.node("ShaderNodeTexVoronoi", voronoi_dimensions="4D" if w is not None else "3D",
                      feature=feature)
        self.put(n.inputs["Vector"], vec)
        if w is not None:
            self.put(n.inputs["W"], w)
        self.put(n.inputs["Scale"], scale)
        self.put(n.inputs["Randomness"], rand)
        return n.outputs[out]

    def ramp(self, f, stops, interp="LINEAR"):
        n = self.node("ShaderNodeValToRGB")
        cr = n.color_ramp
        cr.interpolation = interp
        while len(cr.elements) > 1:
            cr.elements.remove(cr.elements[-1])
        cr.elements[0].position = stops[0][0]
        cr.elements[0].color = (*stops[0][1], 1.0)
        for pos, col in stops[1:]:
            e = cr.elements.new(pos)
            e.color = (*col, 1.0)
        self.put(n.inputs[0], f)
        return n.outputs[0]

    def bump(self, h, strength, dist=0.02, normal=None):
        n = self.node("ShaderNodeBump")
        self.put(n.inputs["Strength"], strength)
        self.put(n.inputs["Distance"], dist)
        self.put(n.inputs["Height"], h)
        if normal is not None:
            self.put(n.inputs["Normal"], normal)
        return n.outputs[0]


def hexc(h):
    """'#RRGGBB' -> linear RGB."""
    h = h.lstrip("#")
    c = [int(h[i:i + 2], 16) / 255.0 for i in (0, 2, 4)]
    return tuple(x / 12.92 if x <= 0.04045 else ((x + 0.055) / 1.055) ** 2.4 for x in c)


class Coords:
    """Where noise is sampled. `v(sx, sz, seed)` -> (vector socket, w socket or None)."""

    def __init__(self, nb, kind, tile_u=4.0, len_v=10.0, tile_v=None):
        self.nb, self.kind = nb, kind
        self.tile_u, self.len_v, self.tile_v = tile_u, len_v, tile_v
        if kind == "world":
            self.pos = nb.geo().outputs["Position"]
        elif kind == "object":
            self.pos = nb.node("ShaderNodeTexCoord").outputs["Object"]
        else:
            u, v, _ = nb.sep(nb.uv())
            self.u, self.vv = u, v
            self.th = nb.mul(u, 2 * math.pi)
            self.cu, self.su = nb.cos(self.th), nb.sin(self.th)
            if kind == "torus":
                self.ph = nb.mul(v, 2 * math.pi)
                self.cv, self.sv = nb.cos(self.ph), nb.sin(self.ph)

    def v(self, sx=1.0, sz=1.0, seed=0.0):
        nb = self.nb
        if self.kind in ("world", "object"):
            vec = nb.vop("MULTIPLY", self.pos, (sx, sx, sz))
            return nb.vop("ADD", vec, (seed * 7.13, seed * 3.71, seed * 5.27)), nb.val(seed)
        r = self.tile_u / (2 * math.pi) * sx
        x = nb.mul(self.cu, r)
        y = nb.mul(self.su, r)
        if self.kind == "cyl":
            z = nb.mul(self.vv, self.len_v * sz)
            return nb.comb(nb.add(x, seed * 7.13), nb.add(y, seed * 3.71), z), nb.val(seed * 1.93)
        rv = self.tile_v / (2 * math.pi) * sz
        z = nb.mul(self.cv, rv)
        w = nb.mul(self.sv, rv)
        return nb.comb(nb.add(x, seed * 7.13), nb.add(y, seed * 3.71), z), nb.add(w, seed * 1.93)

    def height(self):
        """Studs above the floor (bake planes) or world Z."""
        if self.kind in ("world", "object"):
            return self.nb.sep(self.pos)[2]
        return self.nb.mul(self.vv, self.len_v)
