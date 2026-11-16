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


# --- The stress ball with a face (F-05b) ---------------------------------------------------------
# A rubber eye-popper squeeze ball of our own (README): a glossy lime-green vinyl ball, two big
# white bubble eyes standing proud of it in soft rubber lips, black pupils crossed a little, a
# thin black grin printed under them with a dimple at each end. Squeezed, the whole ball squashes
# (`stretch`) and the air shoves the eyes out of their sockets, swelling; let go, it springs
# back and they pop home. Each eye is its own part riding the ball, its axis straight out of its
# socket; it stretches against the ball's squash so it stays round as it bulges.

SB = K.STRESS
SB_SKIN, SB_LIP, SB_EYE = 2, 3, 4
SB_R = SB["r"]
SB_SOFT = 1.6                         # how gently its flat spot rounds into the ball (mm)


def sb_flat(zr):
    """The ball's height over the floor for its sphere's height zr (mm, the floor at -sink): a
    soft maximum with 0, so it sits on a small, rounded flat spot."""
    lo = (-SB["sink"] + math.sqrt(SB["sink"] ** 2 + SB_SOFT ** 2)) / 2
    return (zr + math.sqrt(zr * zr + SB_SOFT ** 2)) / 2 - lo


SB_ZC = sb_flat(SB_R - SB["sink"])    # the ball's middle, over the pivot on the floor (mm)


def sb_dir(side):
    """An eye's axis: up eye_up and out eye_out to `side` (+1 the ball's left, at +X)."""
    u, o = math.radians(SB["eye_up"]), math.radians(SB["eye_out"])
    return Vector((side * math.sin(o) * math.cos(u), -math.cos(o) * math.cos(u), math.sin(u)))


def sb_centre(side):
    """An eye's middle (mm), eye_in inside the ball's skin."""
    return Vector((0.0, 0.0, SB_ZC)) + sb_dir(side) * (SB_R - SB["eye_in"])


def sb_frame(side):
    """The eye's own frame in studs: Z out along its axis, the origin its middle."""
    rot = Vector((0.0, 0.0, 1.0)).rotation_difference(sb_dir(side)).to_matrix().to_4x4()
    return Matrix.Translation(sb_centre(side) / K.STUD_MM) @ rot


def sb_body(hi):
    """The ball, spun from pole to pole (its front, where the face is printed, in the middle of
    a texture strip), and a soft rubber lip round each eye's socket."""
    n, seg = (112, 192) if hi else (28, 48)
    prof = [(0.0, 0.0)]
    for i in range(1, n):
        a = -math.pi / 2 + math.pi * i / n
        prof.append((mm(SB_R * math.cos(a)), mm(sb_flat(SB_ZC + SB_R * math.sin(a)))))
    prof.append((0.0, mm(sb_flat(SB_ZC + SB_R))))
    sh = Shape()
    sh.lathe(prof, SB_SKIN, seg, split=2)
    e, L, h = SB["eye_r"], SB["lip_r"], SB["lip_h"]

    def skin(rho):
        return math.sqrt(SB_R ** 2 - rho ** 2) - (SB_R - SB["eye_in"])
    lip = [(L + 0.4, -0.7), (L, 0.05), (L - 0.5, 0.45 * h), (L - 1.0, 0.8 * h),
           ((L + e) / 2, h), (e + 0.6, 0.85 * h), (e + 0.2, 0.45 * h), (e - 0.05, -0.15),
           (e - 0.3, -1.0)]
    lip = [(mm(r), mm(skin(r) + dz)) for r, dz in lip]
    for side in (1, -1):
        sh.lathe(lip, SB_LIP, 72 if hi else 28, M=sb_frame(side), strips=True)
    return sh


def sb_eye(side):
    def build(hi):
        """A white rubber bubble: most of a sphere, and the neck it's blown from, hidden in
        the ball until a squeeze shoves it out."""
        e, nr, nd = SB["eye_r"], SB["neck_r"], SB["neck_d"]
        n = 40 if hi else 14
        prof = [(nr, -nd), (nr, -11.0), (nr + 0.25, -8.6)]
        a0 = -44.0
        for i in range(n):
            a = math.radians(a0 + (90.0 - a0) * i / n)
            prof.append((e * math.cos(a), e * math.sin(a)))
        prof.append((0.0, e))
        sh = Shape()
        sh.lathe([(mm(r), mm(z)) for r, z in prof], SB_EYE, 64 if hi else 24, M=sb_frame(side))
        return sh
    return build


def sb_pupil(side):
    """Where an eye's pupil looks: in toward the nose and up from its axis."""
    d = sb_dir(side)
    across = Vector((0.0, 0.0, 1.0)).cross(d).normalized()     # toward +X, the ball's left
    upv = d.cross(across).normalized()
    a, b = math.radians(SB["look_in"]), math.radians(SB["look_up"])
    inward = -across * side         # the left eye (at +X) looks toward -X, the right toward +X
    return (d * math.cos(a) * math.cos(b) + inward * math.sin(a) + upv * math.sin(b)).normalized()


def sb_face_ink(res=1024, W=30.0):
    """The grin, w x h texels over the ball's front seen straight on (x across, z up, W mm each
    way from the ball's middle): each texel's spot on the skin measured out from the front's
    middle (an equidistant map), so the stroke is the same width all round the curve."""
    xs = np.linspace(-W, W, res)[None, :]
    zs = np.linspace(-W, W, res)[:, None]
    q = np.clip(SB_R ** 2 - xs ** 2 - zs ** 2, 1e-6, None)
    th = np.arccos(np.clip(np.sqrt(q) / SB_R, -1, 1))
    rr = np.hypot(xs, zs) + 1e-9
    u, v = SB_R * th * xs / rr, SB_R * th * zs / rr
    (cx, cy), r = SB["grin_c"], SB["grin_r"]
    a0, a1 = SB["grin_a"]
    strokes = [bu_segments(("A", (cx, cy), r, a0, a1), 40)]
    for a in (a0, a1):
        nx, ny = math.cos(math.radians(a)), math.sin(math.radians(a))
        ex, ey = cx + r * nx, cy + r * ny
        d = SB["dimple"] / 2
        strokes.append([(ex - nx * d, ey - ny * d), (ex + nx * d, ey + ny * d)])
    dist = np.full(u.shape, 1e9)
    for pts in strokes:
        for (ax, ay), (bx, by) in zip(pts, pts[1:]):
            vx, vy = bx - ax, by - ay
            t = np.clip(((u - ax) * vx + (v - ay) * vy) / max(vx * vx + vy * vy, 1e-9), 0, 1)
            dist = np.minimum(dist, np.hypot(u - ax - t * vx, v - ay - t * vy))
    px = 2 * W / res
    return np.clip(0.5 - (dist - SB["grin_w"] / 2) / px, 0.0, 1.0)


def stress_look(L, f):
    nb = L.nb
    xm, zm = nb.mul(L.x, K.STUD_MM), nb.mul(L.z, K.STUD_MM)
    eye = L.k(SB_EYE)
    # the ball: glossy lime vinyl, its colour a touch deeper where the rotocast wall is thicker,
    # a fine orange-peel skin, the mould's faint seam round its sides and over its top
    C = Coat(L, hexc("#8FD13C"), 0.34)
    C.paint(nb.mul(nb.ss(L.noise(7.0, 1, detail=3), 0.45, 0.75), 0.7), hexc("#7CC232"), 0.36)
    C.paint(nb.mul(nb.ss(L.noise(20.0, 2, detail=2), 0.55, 0.72), 0.5), hexc("#A2DC52"))
    peel = nb.ss(L.noise(1500.0, 3, detail=2), 0.45, 0.75)
    C.paint(peel, height=0.25)
    C.paint(nb.mul(nb.ss(L.noise(380.0, 4, detail=2), 0.66, 0.74), 0.6), rough=0.48)
    seam = nb.mul(nb.band(L.y, -mm(0.12), mm(0.12), mm(0.1)), nb.inv(eye))
    C.paint(seam, hexc("#86C835"), 0.42, height=0.9)
    # the fill plug under it, where the ball was sealed: a little ring on its flat spot
    plug = nb.band(nb.math("SQRT", nb.add(nb.mul(L.x, L.x), nb.mul(L.y, L.y))),
                   mm(2.6), mm(3.2), mm(0.25))
    C.paint(nb.mul(plug, nb.ss(nb.mul(L.nz, -1.0), 0.8, 0.95)), hexc("#7BB830"), 0.5, height=0.8)
    # the eyes: white rubber bubbles, glossy, a touch greyer low down where the vinyl stretches
    # thin over the neck; each pupil a glossy black dot printed on, raised a hair
    C.paint(eye, hexc("#F2EFE6"), 0.2)
    pupils = None
    for side in (1, -1):
        c = sb_centre(side) / K.STUD_MM
        v = nb.vop("NORMALIZE", nb.vop("SUBTRACT", L.P, tuple(c)))
        out = nb.vop("DOT_PRODUCT", v, tuple(sb_dir(side)))
        thin = nb.mul(nb.inv(nb.ss(out, -0.2, 0.35)), eye)
        C.paint(nb.mul(thin, 0.8), hexc("#D7D6CE"), 0.26)
        d = nb.vop("DOT_PRODUCT", v, tuple(sb_pupil(side)))
        cos = [math.cos(math.radians(SB["pupil"] + e)) for e in (0.8, -0.8)]
        p = nb.ss(d, *cos)
        pupils = p if pupils is None else nb.add(pupils, p, clamp=True)
    pupils = nb.mul(pupils, eye)
    C.paint(pupils, hexc("#121214"), 0.16, height=0.6)
    # the grin, printed in black, glossier than the vinyl, its edge a little soft where the
    # spray mask lifted, rubbed thin where a thumb meets it most
    img = bu_image("StressGrin", sb_face_ink())
    t = nb.node("ShaderNodeTexImage", image=img, interpolation="Cubic", extension="CLIP")
    nb.put(t.inputs["Vector"], nb.comb(nb.add(nb.mul(xm, 1 / 60.0), 0.5),
                                       nb.add(nb.mul(nb.sub(zm, SB_ZC), 1 / 60.0), 0.5), 0.0))
    front = nb.mul(nb.ss(nb.mul(L.ny, -1.0), 0.3, 0.6), nb.inv(eye))
    ink = nb.mul(front, t.outputs["Color"])
    rub = nb.mul(nb.ss(L.noise(70.0, 6, detail=3), 0.55, 0.75), 0.35)
    ink = nb.mul(ink, nb.inv(rub))
    C.paint(ink, hexc("#161618"), 0.26)
    C.finish(f.dust, grime=0.3)
    return C.surface(bump_dist=mm(0.1), bump=0.5)


def sb_squeeze():
    """The ball squashes and springs back (SQUISH); each eye goes out along its axis and swells
    (POP, SWELL), the right one a hair behind the left, and stretches against the ball's squash
    so it stays round."""
    def later(keys, dt):
        return [keys[0]] + [(round(k[0] + dt, 3), *k[1:]) for k in keys[1:]]
    tracks = [("Body", "stretch", K.SQUISH)]
    keep = [(k[0], round(k[1] ** -0.9, 4), *k[2:]) for k in K.SQUISH]
    for name, dt in (("EyeL", 0.0), ("EyeR", 0.025)):
        tracks.append((name, "move", later([(k[0], mm(k[1]), *k[2:]) for k in K.POP], dt)))
        tracks.append((name, "scale", later(K.SWELL, dt)))
        tracks.append((name, "stretch", keep))
    return round(K.SQUISH[-1][0] + 0.3, 2), tracks


SB_DUR, SB_TRACKS = sb_squeeze()

STRESS_BALL = kit.Find(
    "StressBall",
    [kit.Part("Body", sb_body),
     kit.Part("EyeL", sb_eye(1), pivot=tuple(sb_centre(1) / K.STUD_MM), parent="Body",
              axis=tuple(sb_dir(1)), alone=True),
     kit.Part("EyeR", sb_eye(-1), pivot=tuple(sb_centre(-1) / K.STUD_MM), parent="Body",
              axis=tuple(sb_dir(-1)), alone=True)],
    stress_look,
    motions={
        # squeezed in the hand: it squashes and the eyes bulge out of their sockets (the game's
        # rubbery squeak and a little rush of air here), held, then let go: it springs back
        # and the eyes pop home
        "Squeeze": dict(duration=SB_DUR, tracks=SB_TRACKS, focus=(0.0, 0.0, mm(SB_ZC)),
                        distance=0.95),
    },
    dust=SB["dust"], seed=SB["seed"], texels=1000,
)

# --- The mochi bun (F-05b2) ----------------------------------------------------------------------
# A TPR mochi squishy of our own (README): a soft sakura-pink dome slumped onto its footprint, its
# side rolling under, dusted with white starch as real ones are (thick, cracked patches over its
# top, thin wisps down its sides with the pink showing through), a tiny two-dot face and blush
# printed low on its front. Squeezed, it sinks slow and heavy and spreads (`stretch`), then heaves
# back and settles into shape without ever springing past it.

MB = K.MOCHI
MB_SKIN = 5


def mb_profile(hi):
    """Its outline, floor to top (mm): the flat foot, the side rolling under to the belly (a
    quarter circle), then a full superellipse dome to the top."""
    r, h, b, f, p = MB["r"], MB["h"], MB["belly"], MB["foot"], MB["round_top"]
    n_roll, n_dome = (24, 64) if hi else (8, 18)
    prof = [(0.0, 0.0), (f * 0.55, 0.0)]
    for i in range(n_roll + 1):
        a = -math.pi / 2 + math.pi / 2 * i / n_roll
        prof.append((f + (r - f) * math.cos(a), b + b * math.sin(a)))
    for i in range(1, n_dome):
        t = math.pi / 2 * i / n_dome
        prof.append((r * math.cos(t) ** (2 / p), b + (h - b) * math.sin(t) ** (2 / p)))
    prof.append((0.0, h))
    return prof


def mb_body(hi):
    """The bun, spun about its middle (its face in the middle of a texture strip), a hair oval,
    its top slumped a little to one side and back, as a soft thing sits."""
    sx, sy = MB["oval"]
    lx, ly = MB["lean"]
    M = Matrix(((sx, 0.0, lx, 0.0), (0.0, sy, ly, 0.0), (0.0, 0.0, 1.0, 0.0), (0.0, 0.0, 0.0, 1.0)))
    sh = Shape()
    sh.lathe([(mm(r), mm(z)) for r, z in mb_profile(hi)], MB_SKIN, 160 if hi else 40, M=M)
    return sh


def mb_face_ink(res=512, W=20.0, zc=18.0):
    """The face seen straight on from the front (x across, z up, W mm each way from (0, zc)):
    the eyes (two dark ovals) and a tiny smile in one mask, the blush (two soft ovals) in another."""
    xs = np.linspace(-W, W, res)[None, :]
    zs = np.linspace(zc - W, zc + W, res)[:, None]
    px = 2 * W / res
    eyes = np.zeros((res, res))
    blush = np.zeros((res, res))
    for side in (1, -1):
        ex, ez, ew, eh = side * MB["eye_dx"], MB["eye_z"], MB["eye_w"], MB["eye_h"]
        d = (np.hypot((xs - ex) / ew, (zs - ez) / eh) - 1.0) * min(ew, eh)
        eyes = np.maximum(eyes, np.clip(0.5 - d / px, 0.0, 1.0))
        bx, bz = side * MB["blush_dx"], MB["blush_z"]
        q = np.hypot((xs - bx) / MB["blush_w"], (zs - bz) / MB["blush_h"])
        blush = np.maximum(blush, np.clip((1.25 - q) / 0.55, 0.0, 1.0) ** 1.5)
    (cx, cz), r = MB["smile_c"], MB["smile_r"]
    smile = bu_ink(res, res, (-W, zc - W, W, zc + W),
                   [bu_segments(("A", (cx, cz), r, *MB["smile_a"]), 16)], MB["smile_w"])
    return np.maximum(eyes, smile), blush


def mochi_look(L, f):
    nb = L.nb
    xm, zm = nb.mul(L.x, K.STUD_MM), nb.mul(L.z, K.STUD_MM)
    # the TPR: sakura pink, satin, deeper and a touch richer low down where it rolls under and
    # the starch never reaches, faintly mottled where the cast is thicker; a soft pebbly skin
    C = Coat(L, hexc("#F3B5C5"), 0.46)
    C.paint(nb.mul(nb.inv(nb.ss(zm, 3.0, 24.0)), 0.8), hexc("#E890AA"), 0.42)
    C.paint(nb.mul(nb.ss(L.noise(9.0, 1, detail=3), 0.45, 0.75), 0.45), hexc("#EEA4B9"))
    C.paint(nb.ss(L.noise(900.0, 2, detail=2), 0.4, 0.8), height=0.15)
    # the face, printed in cocoa brown, the blush in a deeper rose sprayed soft
    ink, blush = mb_face_ink()
    front = nb.ss(nb.mul(L.ny, -1.0), 0.3, 0.6)
    W, zc = 20.0, 18.0
    uv = nb.comb(nb.add(nb.mul(xm, 1 / (2 * W)), 0.5),
                 nb.add(nb.mul(nb.sub(zm, zc), 1 / (2 * W)), 0.5), 0.0)
    looks = []
    for name, mask in (("MochiFace", ink), ("MochiBlush", blush)):
        t = nb.node("ShaderNodeTexImage", image=bu_image(name, mask), interpolation="Cubic",
                    extension="CLIP")
        nb.put(t.inputs["Vector"], uv)
        looks.append(nb.mul(front, t.outputs["Color"]))
    face, cheeks = looks
    C.paint(nb.mul(cheeks, 0.75), hexc("#E57F9C"), 0.44)
    C.paint(face, hexc("#3B2426"), 0.3, height=0.2)
    # the starch: thick where it faces up, in blotches with ragged, crisp edges; thin wisps down
    # the sides; loose grains at the edges of both; none in the crease it sits on. The thick
    # patches craze into little plates as they dry, the pink showing in the cracks. Over the
    # face it lies thinner, rubbed by thumbs.
    up = nb.ss(L.nz, -0.15, 0.9)
    blot = nb.add(L.noise(17.0, 4, detail=5, rough=0.66, distortion=0.5),
                  nb.mul(L.noise(70.0, 5, detail=3), 0.2))
    streak = nb.mul(L.noise(9.0, 9, stretch=(1.0, 1.0, 0.25), detail=3), 0.35)
    T = nb.add(nb.mul(up, 0.72), nb.mul(nb.sub(nb.add(blot, streak), 0.72), 2.1))
    rubbed = nb.mul(front, nb.mul(nb.inv(nb.ss(nb.absf(nb.sub(zm, 19.0)), 6.0, 12.0)),
                                  nb.inv(nb.ss(nb.absf(xm), 14.0, 20.0))))
    T = nb.sub(T, nb.mul(rubbed, 0.35))
    T = nb.mul(T, nb.ss(L.nz, -0.55, -0.25))
    thin = nb.ss(T, 0.18, 0.58)
    C.paint(nb.mul(thin, 0.6), hexc("#FBEFF1"), 0.82, height=0.3)
    thick = nb.ss(T, 0.6, 0.66)
    C.paint(thick, hexc("#FBF8F5"), 0.95, height=0.7)
    grains = nb.mul(nb.ss(L.noise(700.0, 6, detail=1), 0.6, 0.64), nb.ss(T, 0.08, 0.45))
    C.paint(grains, hexc("#FFFDFB"), 0.95, height=0.8)
    crack = None
    for sc, s in ((60.0, 7), (125.0, 8)):
        iso = nb.absf(nb.sub(L.noise(sc, s, detail=2, distortion=0.6), 0.5))
        c = nb.inv(nb.ss(iso, 0.0, 0.014))
        crack = c if crack is None else nb.mx(crack, nb.mul(c, 0.7))
    crack = nb.mul(crack, nb.mul(thick, nb.ss(L.noise(25.0, 10, detail=2), 0.35, 0.6)))
    C.paint(nb.mul(crack, 0.7), hexc("#F1C4CF"), 0.7, height=0.3)
    C.finish(f.dust, grime=0.2)
    return C.surface(bump_dist=mm(0.1), bump=0.5)


MOCHI_BUN = kit.Find(
    "MochiBun",
    [kit.Part("Body", mb_body)],
    mochi_look,
    motions={
        # squeezed in the hand: it gives slowly, sinks heavy and wide (the game's soft puff of
        # air here), held, then let go: it heaves back and settles into shape, never past it
        "Squeeze": dict(duration=round(K.SINK[-1][0] + 0.3, 2),
                        tracks=[("Body", "stretch", K.SINK)],
                        focus=(0.0, 0.0, mm(MB["h"] * 0.45)), distance=0.95),
    },
    dust=MB["dust"], seed=MB["seed"], texels=1000,
)

# --- The squishy toast slice (F-05b3) -------------------------------------------------------------
# A slow-rise foam slice of white toast of our own (README): a square base under a wider rounded
# crown, the crust airbrushed golden brown round its edge and darker over the crown, the crumb a
# pale cream full of little pores, a cute face printed low on its front. One part, lofted from
# each face through its rounded edge to the middle, standing on its bottom crust; its squeeze is
# the whole slice crushing down and springing back, past its shape and settling, like bread.

TS = K.TOAST
TS_FOAM = 6
TS_T, TS_E = TS["thick"], TS["edge"]


def ts_outline(n):
    """The slice's outline seen from the front, n points (n even) anticlockwise from the bottom's
    middle, as (across, up) mm: a closed Catmull-Rom curve through the spec's half outline and its
    mirror, spaced by length plus turning, so corners get more points than straight runs."""
    half = TS["outline"]
    ctrl = half + [(-x, z) for x, z in reversed(half[1:-1])]
    m = len(ctrl)
    dense = []
    for i in range(m):
        p0, p1, p2, p3 = (np.array(ctrl[(i + k) % m]) for k in (-1, 0, 1, 2))
        for t in np.linspace(0.0, 1.0, 48, endpoint=False):
            dense.append(0.5 * (2 * p1 + (p2 - p0) * t + (2 * p0 - 5 * p1 + 4 * p2 - p3) * t * t
                                + (3 * p1 - p0 - 3 * p2 + p3) * t ** 3))
    dense = np.array(dense)
    top = (len(half) - 1) * 48
    right = dense[:top + 1]
    seg = np.diff(right, axis=0)
    ang = np.arctan2(seg[:, 1], seg[:, 0])
    turn = np.abs((np.diff(ang) + np.pi) % (2 * np.pi) - np.pi)
    cost = np.hypot(seg[:, 0], seg[:, 1]) + 9.0 * np.concatenate([[0.0], turn])
    acc = np.concatenate([[0.0], np.cumsum(cost)])
    want = np.linspace(0.0, acc[-1], n // 2 + 1)
    xs = np.interp(want, acc, right[:, 0])
    zs = np.interp(want, acc, right[:, 1])
    xs[0] = xs[-1] = 0.0
    pts = list(zip(xs, zs))
    return pts + [(-x, z) for x, z in reversed(pts[1:-1])]


def ts_inset(pts, d):
    """The outline moved d mm inward along its normals (it runs anticlockwise)."""
    P = np.array(pts)
    t = np.roll(P, -1, axis=0) - np.roll(P, 1, axis=0)
    t /= np.linalg.norm(t, axis=1)[:, None]
    return P + d * np.stack([-t[:, 1], t[:, 0]], axis=1)


def ts_body(hi):
    """The slice: its front half lofted from the front face (capped) round the rounded edge and
    back to the middle, then the same turned half a turn about Z for the back."""
    n = 360 if hi else 96
    ne, nb = (14, 4) if hi else (4, 1)
    out = ts_outline(n)
    rings = []
    for k in range(ne + 1):
        a = math.radians(90 * k / ne)
        ring = ts_inset(out, TS_E * (1 - math.sin(a)))
        rings.append([(mm(u), mm(v), mm(TS_E * (1 - math.cos(a)))) for u, v in ring])
    for k in range(1, nb + 1):
        w = TS_E + (TS_T / 2 - TS_E) * k / nb
        rings.append([(mm(u), mm(v), mm(w)) for u, v in out])
    # the loft's (across, up, in): across to -X (a proper turn, so its faces point out; the
    # outline is the same both ways), up to Z, in to +Y from the front face at -thick/2
    R = Matrix(((-1, 0, 0, 0), (0, 0, 1, 0), (0, 1, 0, 0), (0, 0, 0, 1)))
    M = Matrix.Translation((0.0, -mm(TS_T / 2), 0.0)) @ R
    sh = Shape()
    for half in (Matrix(), Matrix.Rotation(math.pi, 4, "Z")):
        sh.loft(rings, TS_FOAM, M=half @ M, cap_bottom=TS_FOAM)
    return sh


TS_BOX = (-58.0, -4.0, 58.0, 116.0)     # the face images' extent seen from the front (mm)


def ts_crust_dist(res=(928, 960)):
    """How far each point of the front view lies inside the outline (mm, over 24), for the crust
    band, its toasted glow and the ragged edge between them, which the look draws."""
    w, h = res
    x0, z0, x1, z1 = TS_BOX
    xs = np.linspace(x0, x1, w)[None, :]
    zs = np.linspace(z0, z1, h)[:, None]
    P = ts_outline(480)
    d = np.full((h, w), 1e9)
    for (ax, az), (bx, bz) in zip(P, P[1:] + P[:1]):
        vx, vz = bx - ax, bz - az
        t = np.clip(((xs - ax) * vx + (zs - az) * vz) / max(vx * vx + vz * vz, 1e-9), 0, 1)
        d = np.minimum(d, np.hypot(xs - ax - t * vx, zs - az - t * vz))
    return np.clip(d / 24.0, 0.0, 1.0)


def ts_face_ink(res=640, W=26.0, zc=48.0):
    """The face seen straight on (W mm each way from (0, zc)): the eyes and the open mouth (one
    ink mask), each eye's shine, the tongue, and the blush."""
    xs = np.linspace(-W, W, res)[None, :]
    zs = np.linspace(zc - W, zc + W, res)[:, None]
    px = 2 * W / res

    def oval(cx, cz, rw, rh):
        dd = (np.hypot((xs - cx) / rw, (zs - cz) / rh) - 1.0) * min(rw, rh)
        return np.clip(0.5 - dd / px, 0.0, 1.0)

    ink = np.zeros((res, res))
    shine = np.zeros((res, res))
    blush = np.zeros((res, res))
    for side in (1, -1):
        ex, ez, ew, eh = side * TS["eye_dx"], TS["eye_z"], TS["eye_w"], TS["eye_h"]
        ink = np.maximum(ink, oval(ex, ez, ew, eh))
        shine = np.maximum(shine, oval(ex + 0.7, ez + 1.15, 0.72, 0.8))
        bx, bz = side * TS["blush_dx"], TS["blush_z"]
        q = np.hypot((xs - bx) / TS["blush_w"], (zs - bz) / TS["blush_h"])
        blush = np.maximum(blush, np.clip((1.25 - q) / 0.55, 0.0, 1.0) ** 1.5)
    # the mouth: a little open smile, flat along its top with round corners, a tongue low in it
    (cx, cz), mw, md = TS["mouth_c"], TS["mouth_w"], TS["mouth_d"]
    lip = TS["mouth_line"] * 0.5
    mouth = oval(cx, cz + lip, mw, md + lip) * np.clip(0.5 - (zs - cz - lip) / px, 0.0, 1.0)
    ink = np.maximum(ink, mouth)
    tongue = oval(cx, cz - md * 0.98, mw * 0.62, md * 0.62) * oval(cx, cz + lip, mw - 0.55,
                                                                       md + lip - 0.55)
    return ink, shine, tongue, blush


def toast_look(L, f):
    nb = L.nb
    xm, zm = nb.mul(L.x, K.STUD_MM), nb.mul(L.z, K.STUD_MM)
    front = nb.ss(nb.mul(L.ny, -1.0), 0.3, 0.6)

    def projected(name, mask, box):
        x0, z0, x1, z1 = box
        uv = nb.comb(nb.mul(nb.sub(xm, x0), 1 / (x1 - x0)), nb.mul(nb.sub(zm, z0), 1 / (z1 - z0)),
                     0.0)
        t = nb.node("ShaderNodeTexImage", image=bu_image(name, mask), interpolation="Cubic",
                    extension="EXTEND")
        nb.put(t.inputs["Vector"], uv)
        return t.outputs["Color"]

    # how far in from the edge (mm), roughened so the crust's inner edge wanders as baked bread's
    dm = nb.mul(projected("ToastDist", ts_crust_dist(), TS_BOX), 24.0)
    dm = nb.add(dm, nb.mul(nb.sub(L.noise(36.0, 1, detail=3), 0.5), 3.4))
    dm = nb.add(dm, nb.mul(nb.sub(L.noise(150.0, 2, detail=2), 0.5), 1.1))
    crown = nb.ss(zm, 62.0, 92.0)
    band = nb.add(TS["crust"], nb.mul(crown, TS["crust_top"] - TS["crust"]))
    crust = nb.inv(nb.ss(nb.sub(dm, band), -0.5, 0.5))
    glow = nb.inv(nb.ss(nb.sub(dm, band), 0.0, TS["toasted"]))
    crumb = nb.inv(crust)
    # the crumb: pale cream foam, matte, a touch warmer toward the middle; toasted golden near the
    # crust; full of little pores, longer up and down as bread rises, darker in their hollows
    C = Coat(L, hexc("#F8E6B9"), 0.86)
    C.paint(nb.mul(nb.ss(L.noise(7.0, 3, detail=2), 0.45, 0.7), 0.4), hexc("#F4DCA6"))
    C.paint(nb.mul(glow, 0.95), hexc("#EDBA6A"), 0.84)
    C.paint(nb.mul(nb.ss(glow, 0.55, 1.0), 0.6), hexc("#E2A253"), 0.82)
    pores = None
    for sc, s, lo in ((120.0, 4, 0.64), (260.0, 5, 0.62), (520.0, 6, 0.6)):
        p = nb.ss(L.noise(sc, s, stretch=(1.0, 1.0, 0.62), detail=2, distortion=0.4), lo,
                  lo + 0.05)
        pores = p if pores is None else nb.mx(pores, nb.mul(p, 0.8))
    pores = nb.mul(pores, crumb)
    C.paint(nb.mul(pores, 0.8), hexc("#D9B677"), 0.92, height=-1.1)
    # each pore's lower lip catches the light a touch, as a cut crumb's walls do
    lip = nb.mul(nb.ss(L.noise(260.0, 5, stretch=(1.0, 1.0, 0.62), detail=2, distortion=0.4,
                               ), 0.55, 0.6), nb.mul(crumb, nb.inv(pores)))
    C.paint(nb.mul(lip, 0.45), hexc("#FFF4D6"))
    C.paint(nb.ss(L.noise(1100.0, 7, detail=1), 0.35, 0.75), height=0.12)
    # the crust: golden brown, airbrushed in patches, deepest at the very edge and over the crown,
    # a faint sheen where it baked hardest
    C.paint(crust, hexc("#C98A45"), 0.72)
    C.paint(nb.mul(crust, nb.mul(nb.ss(L.noise(26.0, 8, detail=3), 0.4, 0.7), 0.6)),
            hexc("#B5702F"))
    C.paint(nb.mul(crust, nb.inv(nb.ss(dm, 0.0, 3.2))), hexc("#A8642A"), 0.66)
    C.paint(nb.mul(crust, nb.mul(crown, 0.85)), hexc("#94531F"), 0.6)
    C.paint(nb.mul(crust, nb.ss(L.noise(300.0, 9, detail=2), 0.55, 0.62)), height=-0.4)
    C.paint(nb.mul(crust, nb.ss(L.noise(700.0, 11, detail=2), 0.3, 0.8)), height=0.3)
    # the face, printed in dark cocoa with a white shine in each eye, a pink tongue, a soft blush
    ink, shine, tongue, blush = ts_face_ink()
    box = (-26.0, 22.0, 26.0, 74.0)
    cheeks = nb.mul(front, projected("ToastBlush", blush, box))
    C.paint(nb.mul(cheeks, 0.7), hexc("#F09A86"), 0.84)
    C.paint(nb.mul(front, projected("ToastFace", ink, box)), hexc("#3A2216"), 0.42, height=0.25)
    C.paint(nb.mul(front, projected("ToastTongue", tongue, box)), hexc("#E06C7A"), 0.42)
    C.paint(nb.mul(front, projected("ToastShine", shine, box)), hexc("#FFF9F0"), 0.4)
    C.finish(f.dust, grime=0.25)
    return C.surface(bump_dist=mm(0.12), bump=0.55)


TOAST_SLICE = kit.Find(
    "ToastSlice",
    [kit.Part("Body", ts_body)],
    toast_look,
    motions={
        # squeezed in the hand: the crumb crushes down fast under the thumb, held, then let go it
        # springs back up like bread, a little past its shape, and settles
        "Squeeze": dict(duration=round(K.SPRING[-1][0] + 0.3, 2),
                        tracks=[("Body", "stretch", K.SPRING)],
                        focus=(0.0, 0.0, mm(60.0)), distance=1.02),
    },
    dust=TS["dust"], seed=TS["seed"], texels=1000,
)

FINDS = [BUTTER_STICK, STRESS_BALL, MOCHI_BUN, TOAST_SLICE]

if __name__ == "__main__":
    kit.main("Squishies", HERE, FINDS)
