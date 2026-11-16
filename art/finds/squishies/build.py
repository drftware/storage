"""The Squishies (art/finds/WAVES.md, F-05): soft finds that squash, dent and spring back. The bar
and the method are art/finds/CRAFT.md; the kit is art/finds/kit. A dent that bends in one place
rides the kit's bones (kit.Bone, F-05a), proven on the butter stick.

    scripts/art.sh set squishies [textures|export|renders|quick] [Find]
"""

import math
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "kit"))
sys.path.insert(0, HERE)

import bpy  # noqa: E402
import numpy as np  # noqa: E402
from mathutils import Matrix, Vector  # noqa: E402

import kit  # noqa: E402
import spec as K  # noqa: E402
from look import Coat, hexc  # noqa: E402
from shapes import Shape  # noqa: E402

mm = K.mm


# --- printing in code: ink drawn as strokes, sampled by the look by position ----------------------

def bu_segments(path, n=10):
    """A stroke's points: ("L", a, b) a line, ("A", centre, r, from, to) an arc (degrees)."""
    if path[0] == "L":
        return [path[1], path[2]]
    _, c, r, a0, a1 = path
    return [(c[0] + r * math.cos(math.radians(a0 + (a1 - a0) * i / n)),
             c[1] + r * math.sin(math.radians(a0 + (a1 - a0) * i / n))) for i in range(n + 1)]


# A bold, plain sans in a 9 x 13 box (mm before scaling): each letter its strokes.
BU_FONT = {
    "B": [("L", (0, 0), (0, 13)), ("L", (0, 13), (4.6, 13)), ("A", (4.6, 10.0), 3.0, 90, -90),
          ("L", (4.6, 7.0), (0, 7.0)), ("L", (0, 7.0), (5.0, 7.0)),
          ("A", (5.0, 3.5), 3.5, 90, -90), ("L", (5.0, 0), (0, 0))],
    "U": [("L", (0, 13), (0, 4.5)), ("A", (4.5, 4.5), 4.5, 180, 360), ("L", (9, 4.5), (9, 13))],
    "T": [("L", (0, 13), (9, 13)), ("L", (4.5, 13), (4.5, 0))],
    "E": [("L", (0, 0), (0, 13)), ("L", (0, 13), (8.2, 13)), ("L", (0, 6.6), (7.0, 6.6)),
          ("L", (0, 0), (8.2, 0))],
    "R": [("L", (0, 0), (0, 13)), ("L", (0, 13), (5.0, 13)), ("A", (5.0, 9.6), 3.4, 90, -90),
          ("L", (5.0, 6.2), (0, 6.2)), ("L", (3.6, 6.2), (8.8, 0))],
}


def bu_ink(w, h, extent, strokes, width):
    """An ink mask w x h texels over extent (x0, y0, x1, y1) mm: 1 within width/2 of any stroke
    (lists of points), anti-aliased over a texel."""
    x0, y0, x1, y1 = extent
    xs = np.linspace(x0, x1, w)[None, :]
    ys = np.linspace(y0, y1, h)[:, None]
    d = np.full((h, w), 1e9)
    for pts in strokes:
        for (ax, ay), (bx, by) in zip(pts, pts[1:]):
            vx, vy = bx - ax, by - ay
            t = np.clip(((xs - ax) * vx + (ys - ay) * vy) / max(vx * vx + vy * vy, 1e-9), 0, 1)
            d = np.minimum(d, np.hypot(xs - ax - t * vx, ys - ay - t * vy))
    px = (x1 - x0) / w
    return np.clip(0.5 - (d - width / 2) / px, 0.0, 1.0)


def bu_image(name, mask):
    h, w = mask.shape
    img = bpy.data.images.new(name, w, h, alpha=False)
    img.colorspace_settings.name = "Non-Color"
    px = np.ones((h, w, 4), np.float32)
    px[..., 0] = px[..., 1] = px[..., 2] = mask
    img.pixels.foreach_set(px.ravel())
    img.pack()
    return img


def bu_word(word, height, at):
    """The word's strokes in mm, centred on `at` (x, z), letters `height` tall."""
    s = height / 13.0
    adv = 9.0 + 4.4
    width = adv * len(word) - 4.4
    out = []
    for i, ch in enumerate(word):
        ox = at[0] - width * s / 2 + i * adv * s
        for path in BU_FONT[ch]:
            out.append([(ox + x * s, at[1] - height / 2 + y * s) for x, y in bu_segments(path)])
    return out


# --- The squishy butter stick (F-05a) ------------------------------------------------------------
# A slow-rise foam stick of butter (README): a sunny yellow block, every edge well rounded, the
# wrapper printed on in navy (BUTTER on its front, a real wrapper's tablespoon marks over its
# top). Squeeze it and a thumb's dent sinks into its top and slowly fills back in, carried by
# bones: one in the dent's middle that sinks, six round it that sink half as far and tip the
# dent's sides toward the middle so they catch the light.

BU = K.BUTTER
BU_FOAM = 1
BU_L, BU_S, BU_E = BU["length"], BU["side"], BU["edge"]
BU_TOP = BU_S                         # the top, this high over the pivot (mm)


def bu_ring(h, rc, z, nt, ns, nc):
    """A rounded square of half side h and corner radius rc at height z of the loft (its own
    frame: x the stick's top, y its back, z along it), anticlockwise from above, starting on the
    top's front end: nt points along the top, ns along each other side, nc round each corner."""
    s = h - rc
    pts = []
    sides = [((h, -s), (0, 1)), ((s, h), (-1, 0)), ((-h, s), (0, -1)), ((-s, -h), (1, 0))]
    for i, ((px, py), (dx, dy)) in enumerate(sides):
        n = nt if i == 0 else ns
        for k in range(n):
            f = 2 * s * k / n
            pts.append((px + dx * f, py + dy * f, z))
        cx, cy = (s if i in (0, 3) else -s), (s if i in (0, 1) else -s)
        for k in range(nc):
            a = math.radians(90 * i + 90 * k / nc)
            pts.append((cx + rc * math.cos(a), cy + rc * math.sin(a), z))
    return pts


def bu_body(hi):
    """The stick, lofted in two halves from each end to the middle: each end's flat face, its
    rounded rim, then rings down the length (close together on the game mesh, so the dent has
    points to bend)."""
    f = 2 if hi else 1
    nt = round(2 * (BU_S / 2 - BU_E) / BU["top_step"]) * f
    ns = max(2, round(2 * (BU_S / 2 - BU_E) / BU["side_step"])) * f
    nc, ne = BU["corner_n"] * f, BU["edge_n"] * f
    h0 = BU_S / 2 - BU_E
    rings = []
    for k in range(ne + 1):
        a = math.radians(90 * k / ne)
        rings.append(bu_ring(h0 + BU_E * math.sin(a), max(1.2, BU_E * math.sin(a)),
                             BU_E * (1 - math.cos(a)), nt, ns, nc))
    n = round((BU_L / 2 - BU_E) / BU["ring"]) * f
    for k in range(1, n + 1):
        rings.append(bu_ring(BU_S / 2, BU_E, BU_E + (BU_L / 2 - BU_E) * k / n, nt, ns, nc))
    rings = [[(mm(x), mm(y), mm(z)) for x, y, z in r] for r in rings]
    # the loft's x is the stick's up, its y the stick's back, its z runs from the +X end in
    B = Matrix(((0, 0, -1, 0), (0, 1, 0, 0), (1, 0, 0, 0), (0, 0, 0, 1)))
    M = Matrix.Translation((mm(BU_L / 2), 0, mm(BU_S / 2))) @ B
    sh = Shape()
    for half in (Matrix(), Matrix.Rotation(math.pi, 4, "Z")):
        sh.loft(rings, BU_FOAM, M=half @ M, cap_bottom=BU_FOAM)
    return sh


def bu_bones():
    """The dent's bones (kit.Bone): its middle sinks the floor; each of six round it, half way
    out, sinks half as far and tips its share of the slope toward the middle. Their shares make
    one smooth bowl: s(u) = 1 - smoothstep(u), u the distance from the middle over the radius,
    the middle bone max(0, 2s - 1), the ring 2 min(s, 1 - s), split round between the two
    nearest; the top's points only (the sides stay put)."""
    cx, cy = BU["dent"]
    R = BU["dent_r"]
    n = BU["rims"]

    def bowl(co):
        x, y, z = co.x * K.STUD_MM - cx, co.y * K.STUD_MM - cy, co.z * K.STUD_MM
        u = min(1.0, math.hypot(x, y) / R)
        s = 1.0 - u * u * (3 - 2 * u)
        top = max(0.0, min(1.0, (z - (BU_TOP - 6.0)) / 5.0))
        return s, math.atan2(y, x), top

    def middle(co):
        s, _, top = bowl(co)
        return max(0.0, 2 * s - 1) * top

    def rim(k):
        phi = 2 * math.pi * k / n

        def w(co):
            s, a, top = bowl(co)
            d = abs((a - phi + math.pi) % (2 * math.pi) - math.pi)
            return 2 * min(s, 1 - s) * max(0.0, 1 - d / (2 * math.pi / n)) * top
        return w

    bones = [kit.Bone("Dent", (mm(cx), mm(cy), mm(BU_TOP)), weight=middle)]
    for k in range(n):
        phi = 2 * math.pi * k / n
        at = (mm(cx + R / 2 * math.cos(phi)), mm(cy + R / 2 * math.sin(phi)), mm(BU_TOP))
        # about the circle's tangent the other way round: a positive turn tips the top toward
        # the middle, the way a bowl's side faces
        bones.append(kit.Bone(f"Rim{k + 1}", at, weight=rim(k),
                              hinge=(math.sin(phi), -math.cos(phi), 0.0)))
    return bones


def bu_squeeze():
    """The dent's tracks from PRESS: the middle sinks dent_d, the ring half that and tips."""
    def scaled(v):
        return [(k[0], k[1] * v, *k[2:]) for k in K.PRESS]
    tracks = [("Dent", "move", scaled(mm(BU["dent_d"])))]
    for k in range(BU["rims"]):
        tracks.append((f"Rim{k + 1}", "move", scaled(mm(BU["dent_d"] / 2))))
        tracks.append((f"Rim{k + 1}", "turn", scaled(BU["tilt"])))
    return round(K.PRESS[-1][0] + 0.4, 2), tracks


def butter_look(L, f):
    nb = L.nb
    xm, ym, zm = nb.mul(L.x, K.STUD_MM), nb.mul(L.y, K.STUD_MM), nb.mul(L.z, K.STUD_MM)
    # the foam: a sunny butter yellow, matt, mottled faintly where the pour cured unevenly
    C = Coat(L, hexc("#F4CF3E"), 0.82)
    C.paint(nb.ss(L.noise(9.0, 1, detail=4), 0.45, 0.8), hexc("#EFC232"), 0.84)
    C.paint(nb.mul(nb.ss(L.noise(26.0, 2, detail=3), 0.55, 0.75), 0.6), hexc("#F7D95A"))
    # its skin: fine pores, a few bigger pits, the mould's soft sheen on the flat faces
    pores = nb.ss(L.noise(1400.0, 3, detail=2), 0.58, 0.72)
    pits = nb.ss(L.noise(420.0, 4, detail=2), 0.66, 0.74)
    C.paint(nb.add(pores, nb.mul(pits, 0.8), clamp=True), height=-0.35)
    C.paint(nb.mul(pits, 0.5), hexc("#E2B52C"))
    flat = nb.mul(nb.inv(L.edge(mm(3.0), k=3.0)), 0.3)
    C.paint(flat, rough=0.62)

    # the print: navy ink, laid flat on the foam, a touch glossier, rubbed thin at the edges
    INK = hexc("#22357A")
    front = nb.ss(nb.mul(L.ny, -1.0), 0.6, 0.85)
    top = nb.ss(L.nz, 0.6, 0.85)
    word = bu_word("BUTTER", BU["letter_h"], (6.0, BU_S / 2 - 1.0))
    # thin rules along the front's top and bottom, where a wrapper's border runs
    rules = [[(-58.0, 6.0), (58.0, 6.0)], [(-58.0, BU_S - 6.0), (58.0, BU_S - 6.0)]]
    ink_f = bu_ink(1024, 320, (-70.0, 0.0, 70.0, BU_S), word, BU["stroke"])
    ink_f = np.maximum(ink_f, bu_ink(1024, 320, (-70.0, 0.0, 70.0, BU_S), rules, 0.9))
    img_f = bu_image("ButterFront", ink_f)
    tf = nb.node("ShaderNodeTexImage", image=img_f, interpolation="Cubic", extension="CLIP")
    nb.put(tf.inputs["Vector"], nb.comb(nb.add(nb.mul(xm, 1 / 140.0), 0.5),
                                        nb.mul(zm, 1 / BU_S), 0.0))
    # the top: a wrapper's tablespoon marks, ticks across from the front edge at every eighth,
    # a rule along their ends and a short label beside each
    ticks, P = [], BU["tbsp"]
    for k in range(1, 8):
        x = -BU_L / 2 + P * k
        ticks.append([(x, -BU_S / 2 - 2.0), (x, -6.0)])
    for k in range(8):
        # each eighth's label, the size of "1 TBSP" printed small: four short dashes
        cx = -BU_L / 2 + P * (k + 0.5)
        ticks += [[(cx + j - 0.55, -2.6), (cx + j + 0.55, -2.6)] for j in (-4.2, -1.6, 1.0, 3.6)]
    ticks.append([(-BU_L / 2 + P, -6.0), (BU_L / 2 - P, -6.0)])
    ink_t = bu_ink(1024, 320, (-70.0, -BU_S / 2 - 2.0, 70.0, BU_S / 2 + 2.0), ticks, 0.9)
    img_t = bu_image("ButterTop", ink_t)
    tt = nb.node("ShaderNodeTexImage", image=img_t, interpolation="Cubic", extension="CLIP")
    nb.put(tt.inputs["Vector"], nb.comb(nb.add(nb.mul(xm, 1 / 140.0), 0.5),
                                        nb.add(nb.mul(ym, 1 / (BU_S + 4.0)), 0.5), 0.0))
    ink = nb.add(nb.mul(front, tf.outputs["Color"]), nb.mul(top, tt.outputs["Color"]), clamp=True)
    worn = nb.mul(L.edge(mm(2.5), k=3.0), nb.ss(L.noise(60.0, 6, detail=3), 0.45, 0.7))
    ink = nb.mul(ink, nb.inv(nb.mul(worn, 0.8)))
    C.paint(ink, INK, 0.6)
    C.paint(nb.mul(ink, nb.ss(L.noise(300.0, 7, detail=2), 0.62, 0.7)), hexc("#3A4C8C"))
    C.finish(f.dust, grime=0.35)
    return C.surface(bump_dist=mm(0.12), bump=0.5)


BU_DUR, BU_TRACKS = bu_squeeze()

BUTTER_STICK = kit.Find(
    "ButterStick",
    [kit.Part("Stick", bu_body, bones=bu_bones())],
    butter_look,
    motions={
        # a thumb pressed into its top and let go: the dent sinks, is held, and slowly fills
        # back in (the game's soft squish sound on the press)
        "Squeeze": dict(duration=BU_DUR, tracks=BU_TRACKS,
                        focus=(mm(BU["dent"][0] - 10.0), mm(BU["dent"][1]), mm(BU_TOP - 6.0)),
                        distance=0.55, view=(-0.35, -1.0, 1.25), drop=0.0),
    },
    dust=BU["dust"], seed=BU["seed"], texels=1100,
)

FINDS = [BUTTER_STICK]

if __name__ == "__main__":
    kit.main("Squishies", HERE, FINDS)
