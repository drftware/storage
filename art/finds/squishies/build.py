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


def ts_outline(n, half=None):
    """The slice's outline (or any flat squishy's `half` outline) seen from the front, n points
    (n even) anticlockwise from the bottom's middle, as (across, up) mm: a closed Catmull-Rom
    curve through the half outline and its mirror, spaced by length plus turning, so corners get
    more points than straight runs."""
    half = half or TS["outline"]
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

# --- The jumbo slow-rise strawberry (F-05c) -------------------------------------------------------
# A jumbo slow-rise PU foam strawberry of our own (README): a fat rounded cone, rich red airbrushed
# deeper toward its tip and lighter over its shoulder, rows of yellow teardrop seeds printed in
# shallow pits, a flat green cap of six pointed leaves round a short stem, all one part. Squeeze
# it and a thumb's dent sinks deep into its front and takes ten seconds to rise back, carried by
# the butter stick's bones: one in the middle that sinks, eight round it that tip the dent's sides.

SR = K.STRAWB
SR_SKIN, SR_LEAF, SR_STEM = 7, 8, 9


def sr_curve():
    """The outline as a dense smooth curve (a Catmull-Rom through the spec's points, its ends
    held): arrays of r, z and the arc length s from the bottom's middle (mm)."""
    ctrl = SR["outline"]
    pts = [ctrl[0]] + ctrl + [ctrl[-1]]
    dense = []
    for i in range(1, len(pts) - 2):
        p0, p1, p2, p3 = (np.array(pts[i + k]) for k in (-1, 0, 1, 2))
        for t in np.linspace(0.0, 1.0, 64, endpoint=False):
            dense.append(0.5 * (2 * p1 + (p2 - p0) * t + (2 * p0 - 5 * p1 + 4 * p2 - p3) * t * t
                                + (3 * p1 - p0 - 3 * p2 + p3) * t ** 3))
    dense.append(np.array(ctrl[-1], float))
    d = np.array(dense)
    s = np.concatenate([[0.0], np.cumsum(np.hypot(*np.diff(d, axis=0).T))])
    return d[:, 0], d[:, 1], s


SR_R, SR_Z, SR_S = sr_curve()
SR_LEN = float(SR_S[-1])
SR_UP = int(np.argmax(SR_Z))            # where the outline stops climbing (the shoulder's top)
SR_ZT = 126.0                           # the seed image's height (mm)


def sr_at(s):
    """(r, z) on the outline at arc length s from the bottom (mm)."""
    return float(np.interp(s, SR_S, SR_R)), float(np.interp(s, SR_S, SR_Z))


def sr_point(s, th):
    """A point on the berry's skin (mm, the find's frame): arc length s up the outline, th radians
    round from the front, anticlockwise from above; three broad lobes, a hair oval, the top slumped
    a little aside and toward you."""
    r, z = sr_at(s)
    r *= 1.0 + SR["lobes"] * math.cos(3 * th + 0.5) * math.sin(math.pi * min(1.0, z / 118.0))
    sx, sy = SR["oval"]
    lx, ly = SR["lean"]
    return Vector((r * math.sin(th) * sx + lx * z, -r * math.cos(th) * sy + ly * z, z))


def sr_frame(s, th):
    """The skin at (s, th): its point, outward normal, the way down it (toward the tip) and the
    way round it (anticlockwise from above)."""
    ds = sr_point(s + 0.05, th) - sr_point(s - 0.05, th)
    dt = sr_point(s, th + 0.002) - sr_point(s, th - 0.002)
    return sr_point(s, th), dt.cross(ds).normalized(), -ds.normalized(), dt.normalized()


def sr_thetas(n):
    """n angles round from the front, anticlockwise, closest together at the front."""
    a = SR["crowd"]
    return [p - a * math.sin(p) for p in (2 * math.pi * j / n for j in range(n))]


def sr_ring_s(hi):
    """The rings' arc lengths up the outline: close through the dent's heights, wider elsewhere."""
    f = 2 if hi else 1
    lo, top = SR["fine"]
    out, s = [0.0], 0.0
    while True:
        z = sr_at(s)[1]
        step = (SR["ring_fine"] if lo <= z <= top else SR["ring"]) / f
        s += step
        if s >= SR_LEN - 0.5 * step:
            break
        out.append(s)
    return out + [SR_LEN]


def sr_body(hi):
    """The berry, lofted ring by ring up its outline from the flat spot's middle to the top's, and
    its cap in the same mesh (sr_cap): Roblox's importer turns an FBX with bones and two meshes
    into a Motor6D rig and drops the bones, so a boned find is one part (docs/STUDIO.md "Bones")."""
    ths = sr_thetas(SR["around"] * (2 if hi else 1))
    rings = []
    for s in sr_ring_s(hi):
        if s <= 0.0 or s >= SR_LEN:
            rings.append([tuple(mm(c) for c in sr_point(s, 0.0))])
        else:
            rings.append([tuple(mm(c) for c in sr_point(s, th)) for th in ths])
    sh = Shape()
    sh.loft(rings, SR_SKIN)
    sr_cap(sh, hi)
    return sh


SR_TOP = sr_point(SR_LEN, 0.0)          # the top's middle, where the cap grows (mm)


def sr_leaf_w(u):
    """A leaf's half width along it (0 its base, 1 its tip), over its widest: a rounded base
    swelling to its widest two fifths along, then a long pointed taper."""
    if u <= 0.4:
        return 0.34 + 0.66 * math.sin(math.pi / 2 * u / 0.4)
    return ((1.0 - u) / 0.6) ** 0.9


def sr_cap(sh, hi):
    """The cap, added to the berry's shape: six leaves, each lofted from its base under the hub to its pointed tip, lying on
    the skin (each ring's points slid round the berry from the leaf's middle line, so the leaf
    hugs it across), lifting off it toward the tip, a lens in section with a groove down its
    middle; the low hub they grow from; the short stem, leaning."""
    n_round, n_len = (24, 30) if hi else (12, 13)
    t0, t1 = SR["leaf_t"]
    rng = np.random.default_rng(int(SR["seed"]))
    for k in range(SR["leaves"]):
        L = SR["leaf_l"][k % 2] * rng.uniform(0.95, 1.05)
        phi = 2 * math.pi * k / SR["leaves"] + 0.3 + math.radians(rng.uniform(-7.0, 7.0))
        lift = SR["leaf_lift"] * rng.uniform(0.75, 1.2)
        W = SR["leaf_w"] * (1.0 if k % 2 == 0 else 0.86) * rng.uniform(0.94, 1.06)
        bend = rng.uniform(-0.1, 0.1)       # the tip swept a little round (radians)
        rings = []
        for i in range(n_len + 1):
            u = i / n_len
            s = SR_LEN - (4.0 + L * u)
            h = 0.35 + lift * u ** 2.6
            if i == n_len:
                p, nrm, _, _ = sr_frame(s, phi + bend)
                rings.append([tuple(mm(c) for c in p + nrm * h)])
                continue
            hw, th_, ring = W * sr_leaf_w(u), t0 + (t1 - t0) * u, []
            r_s = max(3.0, sr_at(s)[0])
            for j in range(n_round):
                a = 2 * math.pi * j / n_round
                v, side = math.cos(a), math.sin(a)
                p, nrm, _, _ = sr_frame(s, phi + bend * u * u + hw * v / r_s)
                if side > 0:
                    off = th_ / 2 * side - SR["groove"] * math.exp(-(v / 0.16) ** 2) * (1 - u) ** 0.5
                else:
                    off = 0.6 * th_ / 2 * side
                ring.append(tuple(mm(c) for c in p + nrm * (h - 0.25 * v * v + off)))
            rings.append(ring)
        sh.loft(rings, SR_LEAF, cap_bottom=SR_LEAF)
    R, H = SR["hub_r"], SR["hub_h"]
    hub = [(R + 0.6, -1.8), (R, 0.0), (R * 0.86, H * 0.55), (R * 0.62, H * 0.86),
           (R * 0.32, H * 0.98), (0.0, H)]
    base = SR_TOP + Vector((0.0, 0.0, 1.0))
    sh.lathe([(mm(r), mm(z)) for r, z in hub], SR_LEAF, 48 if hi else 16,
             M=Matrix.Translation(base / K.STUD_MM))
    sr, sl = SR["stem_r"], SR["stem_l"]
    stem = [(sr + 1.2, -0.6), (sr, 1.6), (sr * 0.93, sl * 0.45), (sr * 0.88, sl * 0.82),
            (sr * 0.74, sl * 0.95), (sr * 0.4, sl), (0.0, sl * 1.01)]
    M = (Matrix.Translation((base + Vector((0.0, 0.0, H - 0.8))) / K.STUD_MM)
         @ Matrix.Rotation(math.radians(SR["stem_tilt"]), 4, Vector((0.6, 0.8, 0.0))))
    sh.lathe([(mm(r), mm(z)) for r, z in stem], SR_STEM, 32 if hi else 10, M=M)


def sr_dent_frame():
    """The dent's middle on the skin, the skin's outward normal there, and two ways along the
    skin (round, up)."""
    th, z = math.radians(SR["dent"][0]), SR["dent"][1]
    s = float(np.interp(z, SR_Z[:SR_UP + 1], SR_S[:SR_UP + 1]))
    C, n, down, rnd = sr_frame(s, th)
    E2 = (-down - rnd * (-down).dot(rnd)).normalized()
    return C, n, rnd, E2


def sr_bones():
    """The dent's bones (kit.Bone), the butter stick's way on a curved side: its middle sinks the
    floor along the skin's inward normal; each of eight round it, half way out, sinks half as far
    and tips its share of the slope toward the middle; their shares make one smooth bowl (bu_bones'
    sums), measured across the skin, the berry's far side left alone."""
    C, n, E1, E2 = sr_dent_frame()
    R, nr = SR["dent_r"], SR["rims"]

    def bowl(co):
        d = Vector(co) * K.STUD_MM - C
        a, b = d.dot(E1), d.dot(E2)
        u = min(1.0, math.hypot(a, b) / R)
        s = 1.0 - u * u * (3 - 2 * u)
        near = max(0.0, min(1.0, (d.dot(n) + 14.0) / 6.0))
        return s, math.atan2(b, a), near

    def middle(co):
        s, _, near = bowl(co)
        return max(0.0, 2 * s - 1) * near

    def rim(k):
        phi = 2 * math.pi * k / nr

        def w(co):
            s, a, near = bowl(co)
            d = abs((a - phi + math.pi) % (2 * math.pi) - math.pi)
            return 2 * min(s, 1 - s) * max(0.0, 1 - d / (2 * math.pi / nr)) * near
        return w

    inward = tuple(-n)
    bones = [kit.Bone("Dent", tuple(C / K.STUD_MM), weight=middle, axis=inward)]
    for k in range(nr):
        phi = 2 * math.pi * k / nr
        radial = E1 * math.cos(phi) + E2 * math.sin(phi)
        at = C + radial * (R / 2) - n * ((R / 2) ** 2 / 120.0)
        bones.append(kit.Bone(f"Rim{k + 1}", tuple(at / K.STUD_MM), weight=rim(k), axis=inward,
                              hinge=tuple(radial.cross(n))))
    return bones


def sr_squeeze():
    """The dent's tracks from RISE: the middle sinks dent_d, the ring half that and tips."""
    def scaled(v):
        return [(k[0], k[1] * v, *k[2:]) for k in K.RISE]
    tracks = [("Dent", "move", scaled(mm(SR["dent_d"])))]
    for k in range(SR["rims"]):
        tracks.append((f"Rim{k + 1}", "move", scaled(mm(SR["dent_d"] / 2))))
        tracks.append((f"Rim{k + 1}", "turn", scaled(SR["tilt"])))
    return round(K.RISE[-1][0] + 0.5, 2), tracks


def sr_seed_ink(res=(1024, 2048)):
    """The seeds unrolled: u round the berry (the front in the middle, the back at both edges), v
    up it (0 the floor, 1 at SR_ZT mm). Staggered rows up the skin, each row as many seeds as fit
    round it, each seed drawn at its true size where it lands (squeezed in v where the skin slopes,
    in u by the ring's radius), a hair turned and sized at random. Two masks: the yellow teardrops
    (pointing up toward the cap) and the round pits they sit in, deepest in the middle."""
    H, W = res
    seed = np.zeros((H, W))
    pit = np.zeros((H, W))
    rng = np.random.default_rng(int(SR["seed"]) + 1)
    L2, w2, p2 = SR["seed_l"] / 2, SR["seed_w"] / 2, SR["pit"] / 2
    k, s = 0, SR["seed_from"]
    while s < SR_LEN - SR["seed_to"]:
        r, z = sr_at(s)
        dzds = max(0.12, (sr_at(s + 0.5)[1] - sr_at(s - 0.5)[1]) / 1.0)
        n = max(3, round(2 * math.pi * r / SR["pitch"]))
        pu, pv = W / (2 * math.pi * r), H / SR_ZT * dzds      # pixels a mm, round and up
        half = int(math.ceil(p2 * 1.3 * max(pu, pv))) + 2
        for j in range(n):
            th = 2 * math.pi * (j + 0.5 * (k % 2) + rng.uniform(-0.12, 0.12)) / n
            cu = (th / (2 * math.pi) + 0.5) * W
            cv = (z + rng.uniform(-0.6, 0.6) * dzds) / SR_ZT * H
            cols = np.arange(int(cu) - half, int(cu) + half + 1)
            rows = np.arange(max(0, int(cv) - half), min(H, int(cv) + half + 1))
            x = ((cols + 0.5 - cu) / pu)[None, :]
            y = ((rows + 0.5 - cv) / pv)[:, None]
            # the pit: a soft round bowl a little below the seed's middle
            d = np.hypot(x, y + 0.35) / p2
            bowl = np.clip(1.0 - d * d, 0.0, 1.0) ** 0.8
            # the seed: a teardrop, turned a little, its point up
            a = math.radians(rng.uniform(-16.0, 16.0))
            sz = rng.uniform(0.88, 1.1)
            xr = (x * math.cos(a) - y * math.sin(a)) / sz
            yr = (x * math.sin(a) + y * math.cos(a)) / sz
            t = yr / L2
            q = (xr / (w2 * np.clip(1.0 - 0.45 * t, 0.2, 2.0))) ** 2 + t * t
            aa = 1.6 / (min(pu, pv) * w2)
            drop = np.clip((1.0 - q) / aa, 0.0, 1.0)
            cc = cols % W
            pit[np.ix_(rows, cc)] = np.maximum(pit[np.ix_(rows, cc)], bowl)
            seed[np.ix_(rows, cc)] = np.maximum(seed[np.ix_(rows, cc)], drop)
        k += 1
        s += SR["row"]
    return seed, pit


def strawberry_look(L, f):
    nb = L.nb
    xm, ym, zm = nb.mul(L.x, K.STUD_MM), nb.mul(L.y, K.STUD_MM), nb.mul(L.z, K.STUD_MM)
    lx, ly = SR["lean"]
    sx, sy = SR["oval"]
    xs = nb.mul(nb.sub(xm, nb.mul(zm, lx)), 1 / sx)          # the berry's own across and back,
    ys = nb.mul(nb.sub(ym, nb.mul(zm, ly)), -1 / sy)         # the lean taken out
    rho = nb.math("SQRT", nb.add(nb.mul(xs, xs), nb.mul(ys, ys)))
    skin = L.k(SR_SKIN)
    green = L.k(SR_LEAF, SR_STEM)
    # the foam: rich strawberry red, matt, airbrushed deeper toward the tip and lighter, warmer
    # over the shoulder; faintly mottled where the spray went on unevenly; a fine porous skin
    C = Coat(L, hexc("#DE2634"), 0.8)
    C.paint(nb.mul(nb.inv(nb.ss(zm, 6.0, 56.0)), 0.8), hexc("#B5172A"), 0.8)
    C.paint(nb.mul(nb.ss(zm, 82.0, 117.0), 0.7), hexc("#F0504A"))
    C.paint(nb.mul(nb.ss(L.noise(7.0, 1, detail=4), 0.45, 0.8), 0.45), hexc("#D01F31"))
    C.paint(nb.mul(nb.ss(L.noise(22.0, 2, detail=3), 0.58, 0.78), 0.4), hexc("#EC4046"))
    pores = nb.ss(L.noise(1300.0, 3, detail=2), 0.58, 0.72)
    pits = nb.ss(L.noise(380.0, 4, detail=2), 0.66, 0.74)
    C.paint(nb.add(pores, nb.mul(pits, 0.8), clamp=True), height=-0.35)
    # the seeds: printed yellow teardrops sunk in shallow pits, the pits a touch darker inside
    seed, pit = sr_seed_ink()
    th = nb.math("ARCTAN2", xs, ys)
    uv = nb.comb(nb.add(nb.mul(th, 1 / (2 * math.pi)), 0.5), nb.mul(zm, 1 / SR_ZT), 0.0)
    looks = []
    for name, mask in (("StrawberrySeeds", seed), ("StrawberryPits", pit)):
        t = nb.node("ShaderNodeTexImage", image=bu_image(name, mask), interpolation="Cubic",
                    extension="EXTEND")
        nb.put(t.inputs["Vector"], uv)
        looks.append(nb.mul(skin, t.outputs["Color"]))
    seeds, hollow = looks
    C.paint(hollow, height=-2.2)
    C.paint(nb.mul(hollow, 0.4), hexc("#A8142A"))
    C.paint(seeds, hexc("#FFD23F"), 0.6, height=0.8)
    C.paint(nb.mul(seeds, nb.mul(nb.ss(L.noise(260.0, 5, detail=2), 0.5, 0.7), 0.6)),
            hexc("#F2B630"))
    # the cap: leaf green foam, darker toward the hub, lighter and yellower at the tips; the stem
    # a deeper olive, its cut end browner
    C.paint(green, hexc("#48A23A"), 0.74)
    C.paint(nb.mul(green, nb.inv(nb.ss(rho, 5.0, 16.0))), hexc("#2F7A2C"))
    C.paint(nb.mul(green, nb.mul(nb.ss(rho, 20.0, 36.0), 0.7)), hexc("#7CC455"))
    C.paint(nb.mul(green, nb.mul(nb.ss(L.noise(30.0, 6, detail=3), 0.5, 0.8), 0.35)),
            hexc("#3E9135"))
    stem = L.k(SR_STEM)
    C.paint(stem, hexc("#4F8A30"), 0.72)
    ztop = SR_TOP.z + 1.0 + SR["hub_h"] - 0.8 + SR["stem_l"]
    C.paint(nb.mul(stem, nb.ss(zm, ztop - 2.2, ztop - 0.8)), hexc("#7A7A3C"), 0.8)
    C.finish(f.dust, grime=0.25)
    return C.surface(bump_dist=mm(0.12), bump=0.5)


SR_DUR, SR_TRACKS = sr_squeeze()
SR_C, SR_N, _, _ = sr_dent_frame()

JUMBO_STRAWBERRY = kit.Find(
    "JumboStrawberry",
    [kit.Part("Berry", sr_body, bones=sr_bones())],
    strawberry_look,
    motions={
        # a thumb pressed deep into its side and let go: the dent sinks, is held, gives a little
        # back at once, then takes ten seconds to rise smooth (the game's soft squish on the press)
        "Squeeze": dict(duration=SR_DUR, tracks=SR_TRACKS,
                        focus=tuple((SR_C + SR_N * 4.0) / K.STUD_MM),
                        distance=0.8, view=(0.45, -1.0, 0.3), drop=0.0),
    },
    dust=SR["dust"], seed=SR["seed"], texels=1000,
)

# --- The squishy capybara (F-05c2) ----------------------------------------------------------------
# A slow-rise foam capybara of our own (README), lying like a loaf: a barrel body, a box of a head,
# small round ears, paws peeking out under it, sleepy half-shut eyes and a mandarin balanced on its
# head. One part lofted ring by ring from its tail to its nose, the ears, paws and mandarin in the
# same mesh; its squeeze is the whole capybara sinking in a contented sigh (the mochi's whole-body
# stretch, softer).

CB = K.CAPY
CB_FOAM, CB_PEEL, CB_LEAF = 10, 11, 12


def cb_spline(ys, vs):
    """A smooth function through (y, v) points: cubic Hermite with Catmull-Rom slopes, flat at
    the ends, held beyond them."""
    order = np.argsort(ys)
    Y, V = np.array(ys, float)[order], np.array(vs, float)[order]
    m = np.zeros(len(Y))
    m[1:-1] = (V[2:] - V[:-2]) / (Y[2:] - Y[:-2])

    def f(y):
        y = min(max(y, Y[0]), Y[-1])
        i = min(int(np.searchsorted(Y, y, side="right")) - 1, len(Y) - 2)
        h = Y[i + 1] - Y[i]
        t = (y - Y[i]) / h
        return float((2 * t ** 3 - 3 * t * t + 1) * V[i] + (t ** 3 - 2 * t * t + t) * h * m[i]
                     + (3 * t * t - 2 * t ** 3) * V[i + 1] + (t ** 3 - t * t) * h * m[i + 1])
    return f


CB_FIT = [cb_spline([s[0] for s in CB["stations"]], [s[k] for s in CB["stations"]])
          for k in (1, 2, 3, 4)]


def cb_section(y):
    """Its cross-section at y (mm): half width, belly line, widest line, top, and how square its
    top and bottom halves are (the body round, the head boxier)."""
    a, zb, zm, zt = (f(y) for f in CB_FIT)
    t = min(1.0, max(0.0, (CB["head_from"] + 8.0 - y) / 16.0))
    w = t * t * (3 - 2 * t)
    (pt0, pt1), (pb0, pb1) = CB["p_top"], CB["p_bot"]
    return a, zb, zm, zt, pt0 + (pt1 - pt0) * w, pb0 + (pb1 - pb0) * w


def cb_ring(sec, y, n, f=1.0):
    """A ring round the section (mm, anticlockwise seen from the nose, so faces point out), drawn
    in to f of its size about its middle for the rounded ends."""
    a, zb, zm, zt, pt, pb = sec
    cz = (zb + zt) / 2
    out = []
    for j in range(n):
        ph = 2 * math.pi * j / n
        c, s = math.cos(ph), math.sin(ph)
        p = pt if s >= 0 else pb
        x = a * math.copysign(abs(c) ** (2 / p), c)
        z = zm + (zt - zm) * abs(s) ** (2 / p) if s >= 0 else zm - (zm - zb) * abs(s) ** (2 / p)
        out.append((x * f, y, cz + (z - cz) * f))
    return out


def cb_top(x, y):
    """The skin's height over (x, y) on its top half (mm), and its outward normal there."""
    def z_at(xx, yy):
        a, zb, zm, zt, pt, pb = cb_section(yy)
        c = min(1.0, abs(xx) / a) ** (pt / 2)
        return zm + (zt - zm) * max(0.0, 1 - c * c) ** (1 / pt)
    z = z_at(x, y)
    dzdx = (z_at(x + 0.05, y) - z_at(x - 0.05, y)) / 0.1
    dzdy = (z_at(x, y + 0.05) - z_at(x, y - 0.05)) / 0.1
    return z, Vector((-dzdx, -dzdy, 1.0)).normalized()


def cb_eye_x():
    """How far out the skin is at the eye's height (mm): where the eye is printed."""
    a, zb, zm, zt, pt, pb = cb_section(CB["eye_y"])
    s = ((CB["eye_z"] - zm) / (zt - zm)) ** (pt / 2)
    return a * math.sqrt(1 - s * s) ** (2 / pt)


def cb_ellipsoid(r_along, r_up, hi, n=None):
    """A lathe profile of an ellipse, pole to pole (studs)."""
    n = n or (16 if hi else 7)
    return [(mm(r_along * math.cos(t)), mm(r_up * math.sin(t)))
            for t in (math.pi * (i / n - 0.5) for i in range(n + 1))]


def cb_turn_to(axis):
    return Vector((0.0, 0.0, 1.0)).rotation_difference(Vector(axis).normalized()).to_matrix().to_4x4()


def cb_body(hi):
    """The capybara, lofted from the tip of its rump to its nose, its ends rounded off, then its
    ears and paws in the same mesh."""
    n = 112 if hi else 48
    st = CB["stations"]
    y0, y1 = st[0][0], st[-1][0]
    ne = 18 if hi else 8
    rings = []
    ry, q = CB["tail_end"]
    sec = cb_section(y0)
    for i in range(ne, 0, -1):
        b = math.pi / 2 * i / ne
        y = y0 + ry * math.sin(b)
        if i == ne:
            rings.append([(0.0, y, (sec[1] + sec[3]) / 2)])
        else:
            rings.append(cb_ring(sec, y, n, math.cos(b) ** (2 / q)))
    count = int(math.ceil((y0 - y1) / (1.2 if hi else 2.6)))
    for i in range(count + 1):
        y = y0 - (y0 - y1) * i / count
        rings.append(cb_ring(cb_section(y), y, n))
    ry, q = CB["nose_end"]
    sec = cb_section(y1)
    for i in range(1, ne + 1):
        b = math.pi / 2 * i / ne
        y = y1 - ry * math.sin(b)
        if i == ne:
            rings.append([(0.0, y, (sec[1] + sec[3]) / 2)])
        else:
            rings.append(cb_ring(sec, y, n, math.cos(b) ** (2 / q)))
    sh = Shape()
    sh.loft([[tuple(mm(c) for c in p) for p in ring] for ring in rings], CB_FOAM)
    # the ears: little round cups facing out, forward and up, their backs sunk in the head
    ex, ey, lift = CB["ear"]
    k = CB["ear_r"] / 6.8
    cup = [(0.0, -3.4), (5.0, -3.1), (6.5, -1.0), (6.8, 0.8), (6.3, 2.3), (5.3, 3.0), (4.4, 2.6),
           (3.2, 1.6), (1.6, 1.15), (0.0, 1.05)]
    for side in (1, -1):
        z, nrm = cb_top(ex, ey)
        ax_ = Vector((CB["ear_out"][0] * side, CB["ear_out"][1], CB["ear_out"][2]))
        c = Vector((ex * side, ey, z)) + nrm * lift
        M = Matrix.Translation(c / K.STUD_MM) @ cb_turn_to(ax_)
        sh.lathe([(mm(r * k), mm(h * k)) for r, h in cup], CB_FOAM, 40 if hi else 14, M=M)
    # the paws, peeking out under its chest and beside its rump, flat on the floor
    for px, py, hx, hy, hz in CB["paws"]:
        for side in (1, -1):
            M = (Matrix.Translation(Vector((px * side, py, hz)) / K.STUD_MM)
                 @ Matrix.Diagonal((hx / hy, 1.0, 1.0, 1.0)))
            sh.lathe(cb_ellipsoid(hy, hz, hi), CB_FOAM, 32 if hi else 12,
                     M=M @ Matrix.Rotation(math.pi / 2, 4, "Z"))
    return sh


CB_TILT = (Matrix.Rotation(math.radians(CB["orange_tilt"][0]), 4, "X")
           @ Matrix.Rotation(math.radians(CB["orange_tilt"][1]), 4, "Y"))
CB_BASE = Vector((0.0, CB["orange"][0], cb_top(0.0, CB["orange"][0])[0] - CB["orange"][1]))
CB_OC = CB_BASE + CB_TILT.to_3x3() @ Vector((0.0, 0.0, CB["orange_r"] * CB["orange_squat"]))


def cb_orange(hi):
    """The mandarin balanced on its head, its own part (it rides the head's sigh but keeps its
    shape and rocks a little; baked alone, or the head's skin under it baked black from the
    inside of the peel): squat, a dimple where its stem was, tilted a little, its stem and a
    leaf."""
    R, sq = CB["orange_r"], CB["orange_squat"]
    tilt, oc = CB_TILT, CB_OC
    sh = Shape()
    nprof = 28 if hi else 14
    prof = []
    for i in range(nprof + 1):
        t = math.pi * (i / nprof - 0.5)
        r = R * math.cos(t)
        h = R * sq * math.sin(t)
        if t > 0:
            h -= 1.0 * math.exp(-(r / 2.6) ** 2)
        prof.append((mm(r), mm(h)))
    sh.lathe(prof, CB_PEEL, 64 if hi else 28, M=Matrix.Translation(oc / K.STUD_MM) @ tilt)
    top = oc + (tilt.to_3x3() @ Vector((0.0, 0.0, R * sq - 1.0)))
    up = tilt.to_3x3() @ Vector((0.0, 0.0, 1.0))
    sh.cylinder(tuple(mm(c) for c in top - up * 0.6), tuple(mm(c) for c in top + up * 1.3),
                mm(1.05), CB_LEAF, sides=10 if hi else 6)
    L_, W_, T_ = CB["leaf"]
    yaw = math.radians(35.0)
    d = Vector((math.cos(yaw), math.sin(yaw), 0.0))
    lc = top + d * (L_ * 0.45) + up * 0.5
    M = (Matrix.Translation(lc / K.STUD_MM) @ tilt @ Matrix.Rotation(yaw, 4, "Z")
         @ Matrix.Rotation(math.radians(14.0), 4, "Y") @ Matrix.Diagonal((1.0, W_ / (L_ / 2), 1.0, 1.0)))
    sh.lathe(cb_ellipsoid(L_ / 2, T_, hi, 10 if hi else 5), CB_LEAF, 24 if hi else 10, M=M)
    return sh


CB_EX = cb_eye_x()
CB_A = math.radians(CB["eye_turn"])


def cb_eye_ink(res=512, W=10.0):
    """One eye and its blush, seen from eye_turn degrees round from straight ahead, centred on the
    eye (u back toward its outer corner, w up, W mm each way): the sleepy eye a dark oval with its
    top hidden under a heavy, gently arched lid (a peaceful half-shut look; a flat lid read as
    grumpy), a small shine low in it, the lid's line running a hair past; the blush under it."""
    us = np.linspace(-W, W, res)[None, :]
    ws = np.linspace(-W, W, res)[:, None]
    px = 2 * W / res
    ew, eh, lid, arch = CB["eye_w"], CB["eye_h"], CB["lid"], CB["arch"]
    lid_w = lid + arch * (1.0 - np.clip(us / ew, -1.2, 1.2) ** 2)
    d_oval = (np.hypot(us / ew, ws / eh) - 1.0) * min(ew, eh)
    d = np.maximum(d_oval, ws - lid_w)
    eye = np.clip(0.5 - d / px, 0.0, 1.0)
    arc = [(u_, lid + arch * (1.0 - (u_ / ew) ** 2) + 0.1) for u_ in np.linspace(-ew * 1.06, ew * 1.1, 24)]
    line = bu_ink(res, res, (-W, -W, W, W), [arc], 0.6)
    eye = np.maximum(eye, line)
    shine = np.clip(0.5 - (np.hypot(us + 1.05, ws + 1.15) - 0.55) / px, 0.0, 1.0)
    bu_, bw, bhw, bhh = CB["blush"]
    q = np.hypot((us - bu_) / bhw, (ws - bw) / bhh)
    blush = np.clip((1.25 - q) / 0.55, 0.0, 1.0) ** 1.5
    return eye, shine, blush


CB_NZC, CB_NW = 36.0, 9.0      # the nose image's middle height and half size (mm)


def cb_nose_ink(res=512):
    """The nose and mouth seen straight on from the front (x across, z up, CB_NW mm each way from
    (0, CB_NZC)): a broad rounded nose wider at the top, two nostril commas, the line down from
    it and a little w of a mouth."""
    W, zc = CB_NW, CB_NZC
    xs = np.linspace(-W, W, res)[None, :]
    zs = np.linspace(zc - W, zc + W, res)[:, None]
    px = 2 * W / res
    nz, nw, nh = CB["nose_z"], CB["nose_w"], CB["nose_h"]
    wide = nw * (1.0 + 0.13 * (zs - nz) / nh)
    q = (np.abs(xs / wide) ** 2.6 + np.abs((zs - nz) / nh) ** 2.6) ** (1 / 2.6)
    nose = np.clip(0.5 - (q - 1.0) * nh / px, 0.0, 1.0)
    nostril = np.zeros((res, res))
    for side in (1, -1):
        u, v = xs - side * 2.7, zs - (nz + 0.5)
        a = math.radians(-28.0 * side)
        uu, vv = u * math.cos(a) + v * math.sin(a), -u * math.sin(a) + v * math.cos(a)
        dd = (np.hypot(uu / 1.25, vv / 0.55) - 1.0) * 0.55
        nostril = np.maximum(nostril, np.clip(0.5 - dd / px, 0.0, 1.0))
    mz, mr = CB["mouth_z"], CB["mouth_r"]
    top = nz - nh + 0.3
    strokes = [[(0.0, top), (0.0, mz + mr)]]
    for side in (1, -1):
        strokes.append(bu_segments(("A", (side * mr, mz + mr), mr, 180.0, 360.0), 14))
    mouth = bu_ink(res, res, (-W, zc - W, W, zc + W), strokes, CB["mouth_w"])
    return np.maximum(nose, mouth), nostril


def capybara_look(L, f):
    nb = L.nb
    xm, ym, zm = nb.mul(L.x, K.STUD_MM), nb.mul(L.y, K.STUD_MM), nb.mul(L.z, K.STUD_MM)
    ax = nb.absf(xm)
    foam = L.k(CB_FOAM)
    # the foam: warm caramel brown, satin-matt, airbrushed a deeper chestnut down its back and
    # over its crown, paler and creamier under its chin, chest and belly and on its cheeks; the
    # muzzle's front a touch deeper; mottled faintly where the spray went on uneven
    C = Coat(L, hexc("#C88D58"), 0.7)
    back = nb.mul(nb.ss(L.nz, 0.3, 0.92), nb.ss(zm, 28.0, 50.0))
    C.paint(nb.mul(back, 0.8), hexc("#9A5F35"), 0.72)
    C.paint(nb.mul(nb.inv(nb.ss(zm, 4.0, 20.0)), 0.75), hexc("#E4BE8E"))
    head = nb.inv(nb.ss(ym, -30.0, -20.0))
    cheek = nb.mul(head, nb.mul(nb.ss(zm, 12.0, 20.0), nb.inv(nb.ss(zm, 31.0, 39.0))))
    C.paint(nb.mul(cheek, 0.6), hexc("#E8C49A"))
    muzzle = nb.mul(nb.inv(nb.ss(ym, -54.0, -48.0)), nb.ss(zm, 24.0, 32.0))
    C.paint(nb.mul(muzzle, 0.55), hexc("#A86B40"))
    C.paint(nb.mul(nb.ss(L.noise(8.0, 1, detail=4), 0.45, 0.8), 0.35), hexc("#BC7E4A"))
    pores = nb.ss(L.noise(1300.0, 3, detail=2), 0.58, 0.72)
    pits = nb.ss(L.noise(380.0, 4, detail=2), 0.66, 0.74)
    C.paint(nb.mul(nb.add(pores, nb.mul(pits, 0.8), clamp=True), foam), height=-0.35)
    # the mould's seam, faint, down the middle of its back (over the head it read as a crack)
    seam = nb.mul(nb.inv(nb.ss(ax, 0.1, 0.34)), nb.mul(nb.ss(zm, 16.0, 24.0), nb.ss(ym, -14.0, -6.0)))
    C.paint(nb.mul(seam, nb.mul(foam, 0.35)), hexc("#B9804E"), 0.6, height=0.3)
    # the ears' insides, a deeper brown
    ex, ey, _ = CB["ear"]
    ez, _ = cb_top(ex, ey)
    o = Vector(CB["ear_out"]).normalized()
    dx, dy, dz = nb.sub(ax, ex), nb.sub(ym, ey), nb.sub(zm, ez + 1.0)
    along = nb.add(nb.add(nb.mul(dx, o.x), nb.mul(dy, o.y)), nb.mul(dz, o.z))
    r2 = nb.sub(nb.add(nb.add(nb.mul(dx, dx), nb.mul(dy, dy)), nb.mul(dz, dz)), nb.mul(along, along))
    dish = nb.mul(nb.inv(nb.ss(r2, 3.0 ** 2, 4.6 ** 2)), nb.ss(along, 0.6, 1.4))
    C.paint(nb.mul(dish, foam), hexc("#7B4A2C"), 0.74)
    # the paws a little deeper brown at their toes
    toes = None
    for px_, py_, hx, hy, hz in CB["paws"]:
        q = nb.add(nb.mul(nb.sub(ax, px_), 1 / hx), 0.0)
        r = nb.mul(nb.sub(ym, py_ - hy * 0.55), 1 / (hy * 0.75))
        m = nb.mul(nb.inv(nb.ss(nb.add(nb.mul(q, q), nb.mul(r, r)), 0.6, 1.1)),
                   nb.inv(nb.ss(zm, hz * 1.3, hz * 1.9)))
        toes = m if toes is None else nb.mx(toes, m)
    C.paint(nb.mul(toes, nb.mul(foam, 0.6)), hexc("#8A5432"))
    # the face, printed: sleepy eyes and blush seen from each side (one image, mirrored by |x|),
    # the nose and mouth from the front
    eye, shine, blush = cb_eye_ink()
    W = 10.0
    u = nb.add(nb.mul(nb.sub(ax, CB_EX), math.cos(CB_A)), nb.mul(nb.sub(ym, CB["eye_y"]), math.sin(CB_A)))
    w = nb.sub(zm, CB["eye_z"])
    uv = nb.comb(nb.add(nb.mul(u, 1 / (2 * W)), 0.5), nb.add(nb.mul(w, 1 / (2 * W)), 0.5), 0.0)
    facing = nb.sub(nb.mul(nb.mul(nb.math("SIGN", xm), L.nx), math.sin(CB_A)),
                    nb.mul(L.ny, math.cos(CB_A)))
    side_gate = nb.mul(nb.mul(nb.ss(facing, 0.15, 0.4), foam), nb.inv(nb.ss(ym, -28.0, -24.0)))
    looks = []
    for name, mask in (("CapyEye", eye), ("CapyShine", shine), ("CapyBlush", blush)):
        t = nb.node("ShaderNodeTexImage", image=bu_image(name, mask), interpolation="Cubic",
                    extension="CLIP")
        nb.put(t.inputs["Vector"], uv)
        looks.append(nb.mul(side_gate, t.outputs["Color"]))
    eyes, shines, cheeks = looks
    C.paint(nb.mul(cheeks, 0.7), hexc("#E88F86"), 0.66)
    C.paint(eyes, hexc("#2A1A14"), 0.32, height=0.2)
    C.paint(shines, hexc("#F4ECE2"), 0.3)
    ink, nostril = cb_nose_ink()
    uvn = nb.comb(nb.add(nb.mul(xm, 1 / (2 * CB_NW)), 0.5),
                  nb.add(nb.mul(nb.sub(zm, CB_NZC), 1 / (2 * CB_NW)), 0.5), 0.0)
    front = nb.mul(nb.mul(nb.ss(nb.mul(L.ny, -1.0), 0.35, 0.65), foam), nb.inv(nb.ss(ym, -51.0, -46.0)))
    looks = []
    for name, mask in (("CapyNose", ink), ("CapyNostril", nostril)):
        t = nb.node("ShaderNodeTexImage", image=bu_image(name, mask), interpolation="Cubic",
                    extension="CLIP")
        nb.put(t.inputs["Vector"], uvn)
        looks.append(nb.mul(front, t.outputs["Color"]))
    nose, nostrils = looks
    C.paint(nose, hexc("#4A2A1B"), 0.4, height=0.25)
    C.paint(nostrils, hexc("#1E120D"), 0.5)
    # the mandarin: bright peel, deeper where it rounds under, dimpled all over with oil pores,
    # glossier than the foam; its leaf a waxy green, its stem a dull olive
    peel = L.k(CB_PEEL)
    C.paint(peel, hexc("#F59324"), 0.46)
    oz = CB_OC.z
    C.paint(nb.mul(peel, nb.mul(nb.inv(nb.ss(zm, oz - 6.0, oz + 2.0)), 0.6)), hexc("#E06F12"))
    C.paint(nb.mul(peel, nb.mul(nb.ss(L.noise(30.0, 6, detail=3), 0.5, 0.8), 0.4)), hexc("#FBA63A"))
    C.paint(nb.mul(peel, nb.ss(L.noise(520.0, 7, detail=1), 0.55, 0.7)), height=-0.5)
    green = L.k(CB_LEAF)
    C.paint(green, hexc("#3E9638"), 0.5)
    C.paint(nb.mul(green, nb.mul(nb.ss(L.noise(40.0, 8, detail=2), 0.5, 0.8), 0.4)), hexc("#2F7A2C"))
    C.finish(f.dust, grime=0.25)
    return C.surface(bump_dist=mm(0.12), bump=0.5)


CAPYBARA = kit.Find(
    "Capybara",
    [kit.Part("Body", cb_body),
     kit.Part("Orange", cb_orange, pivot=tuple(CB_BASE / K.STUD_MM), parent="Body",
              axis=(1.0, 0.0, 0.0), alone=True)],
    capybara_look,
    motions={
        # squeezed: a little breath in, then a long contented sigh out (the game's tiny happy
        # sigh here), sinking wide with its sleepy eyes squeezed nearly shut; let go, it breathes
        # back up and settles, never past its shape
        "Squeeze": dict(duration=round(K.SIGH[-1][0] + 0.3, 2),
                        tracks=[("Body", "stretch", K.SIGH),
                                ("Orange", "stretch", [(k[0], round(k[1] ** -0.85, 4), *k[2:])
                                                       for k in K.SIGH]),
                                ("Orange", "turn", K.ROCK)],
                        focus=(0.0, mm(-6.0), mm(30.0)), distance=0.72),
    },
    dust=CB["dust"], seed=CB["seed"], texels=1000,
)

# --- The paper squishy with a drawn face (F-05c3) -------------------------------------------------
# A kid's homemade paper squishy (README): a ginger cat's head drawn on printer paper in marker, a
# thick black line round the edge, coloured in with streaky orange, a white muzzle, pink ears and
# nose, two big shiny eyes; front and back covered in strips of clear packing tape, the front's
# tape cut into tabs folded onto the back, stuffed so it puffs like a little pillow. One part: two
# faces lofted from the taped seam in to their middles, each puffed by how far in from the edge it
# lies (smoothed, as stuffing rounds a pouch's pinch lines), tipped back a little on its seam. The
# tape is the look: glossy all over, its strips' edges catching the light, pleats gathered round
# the seam where flat paper was puffed, and crumpled creases everywhere. Its squeeze crunches
# down in little jumps and puffs back unevenly.

PP = K.PAPER
PP_PAPER = 13
PP_BOX = (-64.0, -6.0, 64.0, 116.0)    # the drawings' extent seen from the front (mm)
PP_RES = 6.0                            # the drawings' texels a mm
PP_LEAN = math.radians(PP["lean"])
# its frame: drawn standing, its face to -Y, then tipped back on its seam and lifted onto it
PP_M = Matrix.Translation((0.0, 0.0, mm(PP["seam"]))) @ Matrix.Rotation(-PP_LEAN, 4, "X")
PP_CACHE = {}


def pp_outline(n):
    return ts_outline(n, PP["outline"])


def pp_wave(t, scale, seed, k=5):
    """Smooth noise from -1 to 1 along t: a few sines of random wavelength about `scale`."""
    rng = np.random.default_rng(int(seed))
    out = np.zeros_like(np.asarray(t, float))
    for _ in range(k):
        f = 2 * math.pi / (scale * rng.uniform(0.6, 1.6))
        out = out + np.sin(np.asarray(t) * f + rng.uniform(0, 2 * math.pi))
    return out / math.sqrt(k / 2)


def pp_noise2(xs, zs, scale, seed, k=8):
    """The same over the front view: sines of random direction and wavelength about `scale`."""
    rng = np.random.default_rng(int(seed))
    out = 0.0
    for _ in range(k):
        a = rng.uniform(0, 2 * math.pi)
        f = 2 * math.pi / (scale * rng.uniform(0.6, 1.6))
        out = out + np.sin((xs * math.cos(a) + zs * math.sin(a)) * f + rng.uniform(0, 2 * math.pi))
    return out / math.sqrt(k / 2)


def pp_field(res=PP_RES):
    """Each point of the front view over PP_BOX, res a mm: how far inside the outline it lies (mm,
    below 0 outside) and how far round the outline its nearest point is (mm from the chin)."""
    key = ("field", res)
    if key in PP_CACHE:
        return PP_CACHE[key]
    x0, z0, x1, z1 = PP_BOX
    w, h = int((x1 - x0) * res), int((z1 - z0) * res)
    xs = np.linspace(x0, x1, w)[None, :]
    zs = np.linspace(z0, z1, h)[:, None]
    P = pp_outline(640)
    d = np.full((h, w), 1e9)
    s = np.zeros((h, w))
    inside = np.zeros((h, w), bool)
    acc = 0.0
    for (ax, az), (bx, bz) in zip(P, P[1:] + P[:1]):
        vx, vz = bx - ax, bz - az
        ln = math.hypot(vx, vz)
        t = np.clip(((xs - ax) * vx + (zs - az) * vz) / max(ln * ln, 1e-12), 0, 1)
        dd = np.hypot(xs - ax - t * vx, zs - az - t * vz)
        m = dd < d
        d = np.where(m, dd, d)
        s = np.where(m, acc + t * ln, s)
        if abs(vz) > 1e-12:
            inside ^= ((az > zs) != (bz > zs)) & (xs < ax + (zs - az) * vx / vz)
        acc += ln
    PP_CACHE[key] = out = (xs, zs, np.where(inside, d, -d), s, acc)
    return out


def pp_puff():
    """Each face's puff over the front view (mm out from the seam's middle, 1 mm grid): the
    distance in from the edge, smoothed so the stuffing rounds the pinch lines, eased up off the
    seam steeply and flattening over the middle."""
    if "puff" in PP_CACHE:
        return PP_CACHE["puff"]
    xs, zs, d, _, _ = pp_field(1.0)
    inside = d > 0
    u = np.maximum(d, 0.0)
    for _ in range(PP["smooth"]):
        avg = 0.25 * (np.roll(u, 1, 0) + np.roll(u, -1, 0) + np.roll(u, 1, 1) + np.roll(u, -1, 1))
        u = np.where(inside, 0.5 * u + 0.5 * avg, 0.0)
    t = u / u.max()
    PP_CACHE["puff"] = out = (xs[0], zs[:, 0], PP["puff"] * (1 - (1 - t) ** PP["puff_p"]))
    return out


def pp_sample(grid, x, z):
    gx, gz, H = grid
    i = min(max((x - gx[0]) / (gx[1] - gx[0]), 0.0), len(gx) - 1.001)
    j = min(max((z - gz[0]) / (gz[1] - gz[0]), 0.0), len(gz) - 1.001)
    i0, j0 = int(i), int(j)
    fi, fj = i - i0, j - j0
    return ((1 - fi) * (1 - fj) * H[j0, i0] + fi * (1 - fj) * H[j0, i0 + 1]
            + (1 - fi) * fj * H[j0 + 1, i0] + fi * fj * H[j0 + 1, i0 + 1])


def pp_body(hi):
    """The pouch: the taped seam's round edge, then each face from the outline in to its middle
    through rings shrunk toward the head's middle (the outline is star-shaped from there), each
    point puffed out by pp_puff. Each face unwraps as seen from its side, at true size."""
    n, N = (480, 34) if hi else (104, 10)
    O = np.array(pp_outline(n))
    C = np.array((0.0, PP["centre"]))
    puff = pp_puff()
    seam = PP["seam"]
    sh = Shape()

    def vert(x, y, z):
        return (sh._v((mm(x), mm(y), mm(z)), PP_M), x, z)

    edge = [vert(x, 0.0, z) for x, z in ts_inset(O, -seam)]
    round_ = ts_inset(O, -seam * 0.62)
    fr = [1.0 - (0.28 * s + 0.72 * s * s) for s in np.linspace(0.0, 1.0, N + 1)][:-1]
    for side in (-1, 1):                 # the front (out to -Y), then the back
        rings = [edge, [vert(x, side * seam * 0.78, z) for x, z in round_]]
        for r in fr:
            rings.append([vert(x, side * (seam + pp_sample(puff, x, z)), z)
                          for x, z in C + r * (O - C)])
        pole = vert(C[0], side * (seam + pp_sample(puff, *C)), C[1])
        o = sh.island()

        def face(vs, side=side, o=o):
            vs = vs if side < 0 else [vs[0]] + vs[:0:-1]
            sh._f([v[0] for v in vs], PP_PAPER, [o + Vector((-side * mm(v[1]), mm(v[2])))
                                                 for v in vs])

        for A, B in zip(rings, rings[1:]):
            for j in range(n):
                face([A[j], A[(j + 1) % n], B[(j + 1) % n], B[j]])
        for j in range(n):
            face([rings[-1][j], rings[-1][(j + 1) % n], pole])
    return sh


def pp_drawings():
    """What's drawn and taped on each face, seen from the front over PP_BOX, as three images a
    face, three masks each: (marker black, pink, white paper left uncoloured), (tape edges, tape
    lifted off the paper, the seam's pleats' height), (tabby stripes, blush or the heart, -)."""
    if "draw" in PP_CACHE:
        return PP_CACHE["draw"]
    xs, zs, d, s, per = pp_field()
    x0, z0 = PP_BOX[0], PP_BOX[1]
    H, W = d.shape
    px = 1.0 / PP_RES
    wob = pp_noise2(xs, zs, 4.5, 5)

    def soft(v):
        return np.clip(0.5 + v / px, 0.0, 1.0)

    def hand(pts, seed, amp=0.3):
        """A stroke as a hand draws it: resampled every 0.8 mm and wandering off its line."""
        P = np.array(pts, float)
        acc = np.concatenate([[0.0], np.cumsum(np.hypot(*np.diff(P, axis=0).T))])
        t = np.linspace(0.0, acc[-1], max(int(acc[-1] / 0.8), 2))
        Q = np.stack([np.interp(t, acc, P[:, 0]), np.interp(t, acc, P[:, 1])], 1)
        tg = np.gradient(Q, axis=0)
        tg /= np.linalg.norm(tg, axis=1)[:, None] + 1e-9
        return Q + np.stack([-tg[:, 1], tg[:, 0]], 1) * (amp * pp_wave(t, 7.0, seed))[:, None]

    def dist(strokes, margin=4.0):
        out = np.full((H, W), 1e9)
        for P in strokes:
            c0 = max(int((P[:, 0].min() - margin - x0) * PP_RES), 0)
            c1 = min(int((P[:, 0].max() + margin - x0) * PP_RES) + 1, W)
            r0 = max(int((P[:, 1].min() - margin - z0) * PP_RES), 0)
            r1 = min(int((P[:, 1].max() + margin - z0) * PP_RES) + 1, H)
            X, Z = xs[:, c0:c1], zs[r0:r1, :]
            sub = out[r0:r1, c0:c1]
            for (ax, az), (bx, bz) in zip(P, P[1:]):
                vx, vz = bx - ax, bz - az
                t = np.clip(((X - ax) * vx + (Z - az) * vz) / max(vx * vx + vz * vz, 1e-12), 0, 1)
                sub = np.minimum(sub, np.hypot(X - ax - t * vx, Z - az - t * vz))
            out[r0:r1, c0:c1] = sub
        return out

    def ink(strokes, width, seed):
        return soft(width / 2 * (1 + 0.16 * wob) - dist([hand(p, seed + i)
                                                          for i, p in enumerate(strokes)]))

    def oval(cx, cz, rx, rz, taper=None):
        if taper:   # narrower toward its bottom end, as a stroke lifted off
            rx = rx * np.clip((zs - (cz - rz)) / (2 * rz), taper, 1.0)
        q = np.hypot((xs - cx) / rx, (zs - cz) / rz)
        return soft((1.0 - q) * np.minimum(rx, rz) + 0.22 * wob)

    def inside(pts):
        P = np.array(pts, float)
        m = np.zeros((H, W), bool)
        for (ax, az), (bx, bz) in zip(P, np.roll(P, -1, 0)):
            if abs(bz - az) > 1e-12:
                m ^= ((az > zs) != (bz > zs)) & (xs < ax + (zs - az) * (bx - ax) / (bz - az))
        return m.astype(float)

    def arc(c, r, a0, a1, n=14):
        return [(c[0] + r * math.cos(math.radians(a0 + (a1 - a0) * i / n)),
                 c[1] + r * math.sin(math.radians(a0 + (a1 - a0) * i / n))) for i in range(n + 1)]

    def outline(seed):
        c = PP["line_in"] + 0.45 * pp_wave(s, 14.0, seed)
        return soft(PP["line"] / 2 * (1 + 0.16 * wob) - np.abs(d - c)) * (d > -0.3)

    def gaps(seed):
        """Paper left white: the cut edge, and where the colouring stopped short of the line."""
        band = (d > PP["line_in"]) * (d < PP["line_in"] + PP["line"] / 2 + 1.6)
        short = band * np.clip((pp_noise2(xs, zs, 7.0, seed) - 0.75) * 2.0, 0.0, 1.0)
        return np.maximum(short, soft(0.15 - d))

    def tape(edges, tabs, seed):
        """The tape's edges (a strip's straight-ish edges across, and on the back the front's tabs
        folded over: cuts out from the edge and their ends), the silvery film where it lifted along
        them, and the seam's gathered pleats."""
        rng = np.random.default_rng(seed)
        line = np.zeros((H, W))
        lift = np.zeros((H, W))
        for k, (z, slope, curve) in enumerate(edges):
            e = z + slope * xs + curve * xs * xs + 0.5 * pp_wave(xs, 30.0, seed + k)
            line = np.maximum(line, soft(0.2 - np.abs(zs - e)))
            side = np.clip((zs - e) / 2.4, 0.0, 1.0) * (zs > e) * (zs - e < 2.4)
            lift = np.maximum(lift, side * np.clip(pp_wave(xs, 11.0, seed + 9 + k) - 0.1, 0, 1))
        if tabs:
            bounds = np.concatenate([[0.0], np.cumsum(rng.uniform(11.0, 18.0, 40))])
            bounds = bounds[bounds < per - 8.0].tolist() + [per]
            k = np.clip(np.searchsorted(bounds, s), 1, len(bounds) - 1)
            lens = rng.uniform(8.0, 13.0, len(bounds) + 1)
            ln = lens[k]
            cut = np.minimum(s - np.take(bounds, k - 1), np.take(bounds, k) - s)
            line = np.maximum(line, soft(0.2 - cut) * (d < ln) * (d > 0.2))
            line = np.maximum(line, soft(0.2 - np.abs(d - ln)))
            lift = np.maximum(lift, np.clip((d - ln + 2.2) / 2.2, 0, 1) * (d < ln)
                              * np.clip(pp_wave(s, 9.0, seed + 3), 0, 1))
        phase = s / 6.2 + 0.9 * pp_wave(s, 40.0, seed + 4) + 0.03 * d * pp_wave(s, 25.0, seed + 5)
        idx = np.floor(phase)
        length = 4.0 + 11.0 * np.modf(np.abs(np.sin(idx * 12.9898 + seed) * 43758.5453))[0]
        tri = 2.0 * np.abs(phase - idx - 0.5) * 2.0 - 1.0
        pleat = tri * np.clip(1.0 - d / length, 0.0, 1.0) ** 0.7 * (d > 0)
        return line, lift, 0.5 + 0.5 * np.clip(pleat, -1.0, 1.0)

    # the front: the cat's face
    blk = outline(11)
    for sx, cx, cz, rx, rz in ((-1, -18.6, 51.0, 5.0, 6.0), (1, 18.9, 50.4, 5.35, 6.25)):
        blk = np.maximum(blk, oval(cx, cz, rx, rz))
    shine = np.maximum.reduce([oval(cx + 1.75, cz + 2.3, 1.8, 1.8) for cx, cz in
                               ((-18.6, 51.0), (18.9, 50.4))]
                              + [oval(cx - 1.6, cz - 2.7, 0.8, 0.8) for cx, cz in
                                 ((-18.6, 51.0), (18.9, 50.4))])
    nose = [(-4.0, 41.6), (4.1, 41.4), (0.1, 37.4)]
    ears = [[(33.0, 91.0), (42.6, 101.4), (46.4, 84.0)], [(-32.4, 90.4), (-42.0, 100.6),
                                                         (-46.0, 84.6)]]
    face = [nose + [nose[0]], [(0.1, 37.4), (0.0, 35.3)],
            arc((-3.05, 35.3), 3.05, 0, -180), arc((3.05, 35.3), 3.05, 180, 360),
            [(35.0, 42.0), (52.5, 46.0)], [(35.5, 38.0), (54.0, 37.2)], [(35.0, 34.0), (51.5, 28.8)],
            [(-35.0, 41.6), (-52.0, 45.2)], [(-35.5, 37.6), (-53.6, 37.6)],
            [(-35.0, 33.6), (-51.0, 29.4)]]
    blk = np.maximum(blk, ink(face, 1.45, 21))
    blk = np.maximum(blk, ink([e + [e[0]] for e in ears], 1.35, 41))
    pink = np.maximum.reduce([inside(nose)] + [inside(e) for e in ears])
    muzzle = np.maximum(oval(-6.3, 34.6, 8.8, 7.6), oval(6.3, 34.4, 8.9, 7.7))
    white = np.maximum.reduce([gaps(31), shine, muzzle * (1 - pink)])
    stripes = np.maximum.reduce([oval(-8.8, 81.6, 1.8, 6.2, 0.3), oval(0.3, 80.8, 1.9, 7.4, 0.3),
                                 oval(9.0, 81.8, 1.8, 6.0, 0.3)])
    hatch = 0.55 + 0.45 * np.clip(np.sin((xs * 0.5 + zs * 0.866) * 2 * math.pi / 1.15) * 3, -1, 1)
    blush = np.maximum(oval(-28.5, 42.6, 5.2, 3.2), oval(28.8, 42.2, 5.0, 3.3)) * hatch
    F1 = (blk * (1 - shine), pink, white)
    F2 = tape([(8.0, 0.01, 0.0011), (35.5, -0.025, 0.0), (79.5, 0.035, 0.0)], False, 51)
    F3 = (stripes, blush, np.zeros_like(blk))
    # the back: the outline again, a little heart, the back of the head's stripes, the tabs
    t = np.linspace(0.0, 2 * math.pi, 73)
    heart = [(-13.0 + 0.5 * 16 * math.sin(a) ** 3,
              57.0 + 0.5 * (13 * math.cos(a) - 5 * math.cos(2 * a) - 2 * math.cos(3 * a)
                            - math.cos(4 * a))) for a in t]
    hb = ink([heart], 1.3, 71)
    B1 = (np.maximum(outline(12), hb), inside(heart[:-1]) * (1 - hb), gaps(32))
    B2 = tape([(30.0, 0.02, 0.0), (71.0, -0.03, 0.0)], True, 61)
    B3 = (np.maximum.reduce([oval(-9.0, 80.0, 1.6, 6.4, 0.3), oval(0.0, 79.0, 1.7, 7.4, 0.3),
                             oval(9.4, 80.4, 1.6, 6.2, 0.3)]), np.zeros_like(blk),
          np.zeros_like(blk))
    PP_CACHE["draw"] = out = (F1, F2, F3, B1, B2, B3)
    return out


def pp_image(name, chans):
    h, w = chans[0].shape
    img = bpy.data.images.new(name, w, h, alpha=False)
    img.colorspace_settings.name = "Non-Color"
    px = np.ones((h, w, 4), np.float32)
    for i, c in enumerate(chans):
        px[..., i] = c
    img.pixels.foreach_set(px.ravel())
    img.pack()
    return img


def paper_look(L, f):
    nb = L.nb
    ca, sa = math.cos(PP_LEAN), math.sin(PP_LEAN)
    up = nb.sub(L.z, mm(PP["seam"]))
    # back in the pouch's own frame, as drawn standing (mm)
    xm = nb.mul(L.x, K.STUD_MM)
    zm = nb.mul(nb.add(nb.mul(L.y, sa), nb.mul(up, ca)), K.STUD_MM)
    ym = nb.mul(nb.sub(nb.mul(L.y, ca), nb.mul(up, sa)), K.STUD_MM)
    front = nb.ss(ym, 0.2, -0.2)
    back = nb.inv(front)
    x0, z0, x1, z1 = PP_BOX
    uv = nb.comb(nb.mul(nb.sub(xm, x0), 1 / (x1 - x0)), nb.mul(nb.sub(zm, z0), 1 / (z1 - z0)),
                 0.0)
    draw = pp_drawings()

    def img(name, chans):
        t = nb.node("ShaderNodeTexImage", image=pp_image(name, chans), interpolation="Cubic",
                    extension="EXTEND")
        nb.put(t.inputs["Vector"], uv)
        return nb.sep(t.outputs["Color"])

    F = [img(f"Paper{k}F", c) for k, c in enumerate(draw[:3])]
    B = [img(f"Paper{k}B", c) for k, c in enumerate(draw[3:])]

    def both(i, c):
        return nb.add(nb.mul(front, F[i][c]), nb.mul(back, B[i][c]))

    blk, white, pink = both(0, 0), both(0, 2), nb.mul(front, F[0][1])
    edge, lift, pleat = both(1, 0), both(1, 1), both(1, 2)
    stripes, blush = both(2, 0), both(2, 1)
    heart = nb.mul(back, B[0][1])
    # printer paper under the tape, a cool white with a faint fibre
    C = Coat(L, hexc("#F3F1EA"), 0.12)
    C.paint(nb.ss(L.noise(900.0, 1, detail=2), 0.3, 0.8), height=0.12)
    # coloured in with an orange marker in diagonal back-and-forth strokes: darker where strokes
    # overlapped, lighter where the nib ran dry, the paper left white where the kid stopped short
    q = nb.add(nb.mul(xm, 0.819), nb.mul(zm, 0.574))
    r = nb.sub(nb.mul(zm, 0.819), nb.mul(xm, 0.574))
    streak = nb.noise((nb.comb(nb.mul(q, 0.55), nb.mul(r, 0.035), 0.0), None), 1.0, detail=2)
    blot = L.noise(30.0, 3, detail=2)
    colour = nb.inv(white)
    C.paint(colour, hexc("#F58A2E"))
    C.paint(nb.mul(colour, nb.ss(streak, 0.52, 0.66)), hexc("#EC731F"))
    C.paint(nb.mul(colour, nb.mul(nb.ss(streak, 0.4, 0.28), 0.55)), hexc("#F8A452"))
    C.paint(nb.mul(colour, nb.mul(nb.ss(blot, 0.55, 0.75), 0.4)), hexc("#E46A1C"))
    C.paint(nb.mul(colour, stripes), hexc("#B5461A"))
    C.paint(pink, hexc("#F27A9B"))
    C.paint(nb.mul(nb.mul(front, blush), 0.8), hexc("#F2708A"))
    C.paint(heart, hexc("#E2303F"))
    C.paint(blk, hexc("#1E1A1C"), height=0.1)
    # the tape over everything: a glossy film, a touch grey, smudged with fingerprints; silvery
    # where it lifted off the paper, its cut edges catching the light
    C.paint(nb.mul(nb.ss(L.noise(55.0, 6, detail=3), 0.56, 0.72), 0.8), rough=0.3)
    C.paint(nb.mul(lift, 0.2), hexc("#F2F6F6"), 0.2, height=0.3)
    C.paint(nb.mul(edge, 0.12), hexc("#FFFFFF"))
    C.paint(edge, rough=0.3, height=0.8)
    # crumpled: the paper's facets, each tipped its own way, at two sizes, and the pleats gathered
    # round the seam where flat sheets were puffed out
    for sc, amp, sd in ((12.0, 5.0, 6), (26.0, 6.0, 7), (64.0, 3.0, 8)):
        vw = L.vec(s=sd)
        cell = nb.voronoi(vw, sc, out="Position")
        rnd = nb.vop("SUBTRACT", nb.voronoi(vw, sc, out="Color"), (0.5, 0.5, 0.5))
        tilt = nb.vop("DOT_PRODUCT", nb.vop("SUBTRACT", vw[0], cell), rnd)
        C.paint(1.0, height=nb.mul(tilt, sc * amp))
    C.paint(1.0, height=nb.mul(nb.sub(pleat, 0.5), 4.6))
    C.finish(f.dust, grime=0.2)
    return C.surface(bump_dist=mm(0.12), bump=0.6)


PAPER_SQUISHY = kit.Find(
    "PaperSquishy",
    [kit.Part("Body", pp_body)],
    paper_look,
    motions={
        # squeezed: it crunches flat in little jumps as its creases buckle, held, then let go it
        # puffs back unevenly, a pop, a stall, a pop and a creep, never past its shape
        "Squeeze": dict(duration=round(K.CRINKLE[-1][0] + 0.3, 2),
                        tracks=[("Body", "stretch", K.CRINKLE)],
                        focus=(0.0, 0.0, mm(52.0)), distance=1.0),
    },
    dust=PP["dust"], seed=PP["seed"], texels=1000,
)

# --- The gel bead ball (F-05d) -------------------------------------------------------------------
# A clear TPR stress ball packed with water beads, of our own (README): a hair milky, glossy skin
# with a moulded seam over it and a fill plug underneath, and inside it about 120 pastel beads,
# each pressed flat where it meets the skin, so the ball reads as a sphere of coloured dots with a
# thin milky web between them; the deeper beads show through the gaps as a pale cloud. Squeezed,
# it squashes heavy and slops back (`stretch`), and the beads swirl round inside it in three
# bands, top, middle and bottom, each turning its own way a beat behind the last, then slopping
# back past where they were and settling.

GB = K.GELBEAD
GB_SKIN, GB_CORE = 14, 15
GB_BEADS = (16, 17, 18, 19, 20, 21)    # lavender, mint, lemon, sky, pink, peach
GB_R = GB["r"]
GB_RIN = GB_R - GB["skin"]             # the skin's inside, where the beads press flat (mm)
GB_SOFT = 1.6                          # how gently its flat spot rounds into the ball (mm)


def gb_flat(zr):
    """The ball's height over the floor for its sphere's height zr (mm, the floor at -sink): a
    soft maximum with 0, so it sits on a small, rounded flat spot (the stress ball's way)."""
    lo = (-GB["sink"] + math.sqrt(GB["sink"] ** 2 + GB_SOFT ** 2)) / 2
    return (zr + math.sqrt(zr * zr + GB_SOFT ** 2)) / 2 - lo


GB_ZC = gb_flat(GB_R - GB["sink"])     # the ball's middle over the pivot on the floor (mm)


def gb_beads():
    """The beads against the skin: [(direction from the ball's middle, radius mm, colour kind)],
    spread evenly over the sphere (a Fibonacci spiral, nudged off its pattern and relaxed apart so
    no two crowd), each a little off the grown size, the colours dealt at random but never the
    same as both of its nearest neighbours."""
    rng = np.random.default_rng(int(GB["seed"]))
    n = GB["n"]
    i = np.arange(n) + 0.5
    z = 1 - 2 * i / n
    th = math.pi * (1 + 5 ** 0.5) * i
    p = np.stack([np.sqrt(1 - z * z) * np.cos(th), np.sqrt(1 - z * z) * np.sin(th), z], 1)
    p += rng.normal(0, 0.06, p.shape)
    p /= np.linalg.norm(p, axis=1)[:, None]
    want = 1.02 * math.sqrt(4 * math.pi / n * 2 / math.sqrt(3))    # the hex packing's spacing
    for _ in range(60):
        d = p[:, None, :] - p[None, :, :]
        r = np.linalg.norm(d, axis=2) + np.eye(n)
        push = np.clip(want - r, 0, None) / r
        p += 0.25 * (d * push[..., None]).sum(1)
        p /= np.linalg.norm(p, axis=1)[:, None]
    rad = GB["bead_r"] + rng.uniform(-GB["bead_jit"], GB["bead_jit"], n)
    near = np.argsort(np.linalg.norm(p[:, None] - p[None], axis=2), axis=1)[:, 1:3]
    kinds = []
    for j in range(n):
        while True:
            k = int(rng.integers(len(GB_BEADS)))
            seen = [kinds[m] for m in near[j] if m < j]
            if len(seen) < 2 or not all(s == GB_BEADS[k] for s in seen):
                break
        kinds.append(GB_BEADS[k])
    return [(Vector(tuple(p[j])), float(rad[j]), kinds[j]) for j in range(n)]


GB_LIST = gb_beads()


def gb_band(d):
    """Which swirling band a bead rides, by its middle's height over the ball's (mm)."""
    h = d.z * (GB_RIN - GB["bead_r"] + GB["press"])
    return "Top" if h > GB["band"] else ("Low" if h < -GB["band"] else "Mid")


def gb_skin(hi):
    """The skin: the ball spun from pole to pole, its outside only (it's clear)."""
    n, seg = (112, 192) if hi else (20, 36)
    prof = [(0.0, 0.0)]
    for i in range(1, n):
        a = -math.pi / 2 + math.pi * i / n
        prof.append((mm(GB_R * math.cos(a)), mm(gb_flat(GB_ZC + GB_R * math.sin(a)))))
    prof.append((0.0, mm(gb_flat(GB_ZC + GB_R))))
    sh = Shape()
    sh.lathe(prof, GB_SKIN, seg, split=2)
    return sh


def gb_bead(sh, d, r, kind, hi):
    """One bead spun about its own axis out from the ball's middle: a sphere whose outer side is
    pressed into a round patch against the skin's inside, rolling softly into the bead (a smooth
    minimum of the bead and the skin), its bottom held off the floor inside the flat spot. Its
    inner side faces the cloud of deeper beads and is never seen, so it's left open."""
    c = GB_RIN - r + GB["press"]
    if hi:
        angs = [-40.0 + 5.0 * i for i in range(26)] + [90.0]
    else:
        angs = [-40.0, -2.0, 32.0, 60.0, 90.0]
    k = GB["roll"]
    prof = []
    for a in angs:
        a = math.radians(a)
        rho, zb = r * math.cos(a), r * math.sin(a)
        zs = math.sqrt(max(GB_RIN ** 2 - rho * rho, 0.0)) - c
        zz = (zb + zs - math.sqrt((zb - zs) ** 2 + k * k)) / 2
        prof.append((0.0 if abs(rho) < 1e-6 else mm(rho), mm(zz)))
    rot = Vector((0.0, 0.0, 1.0)).rotation_difference(d).to_matrix().to_4x4()
    M = Matrix.Translation(Vector((0.0, 0.0, GB_ZC)) / K.STUD_MM + d * (c / K.STUD_MM)) @ rot
    n0 = len(sh.bm.verts)
    sh.lathe(prof, kind, 28 if hi else 14, M=M, split=2)
    sh.bm.verts.ensure_lookup_table()
    floor = mm(GB["skin"] + 0.35)
    for v in sh.bm.verts[n0:]:
        if v.co.z < floor + mm(1.0):
            q = v.co.z - floor
            v.co.z = floor + (q + math.sqrt(q * q + mm(0.6) ** 2)) / 2


def gb_beads_part(band):
    def build(hi):
        """The beads of one band; the middle band also carries the pale cloud of deeper beads."""
        sh = Shape()
        for d, r, kind in GB_LIST:
            if gb_band(d) == band:
                gb_bead(sh, d, r, kind, hi)
        if band == "Mid":
            n, seg = (48, 64) if hi else (10, 16)
            prof = [(0.0, mm(GB_ZC - GB["core"]))]
            for i in range(1, n):
                a = -math.pi / 2 + math.pi * i / n
                prof.append((mm(GB["core"] * math.cos(a)), mm(GB_ZC + GB["core"] * math.sin(a))))
            prof.append((0.0, mm(GB_ZC + GB["core"])))
            sh.lathe(prof, GB_CORE, seg, split=2)
        return sh
    return build


GB_COLS = {16: "#A98BE6", 17: "#72D6A2", 18: "#F0D84E", 19: "#69B4EE", 20: "#F287B8",
           21: "#F7A266"}


def gelbead_look(L, f):
    nb = L.nb
    beads = L.k(*GB_BEADS)
    # the skin: clear TPR a hair milky, glossy, a faint orange-peel from the mould, the parting
    # line over its sides and top, a fill plug under it, rubbed and smudged where thumbs go
    C = Coat(L, hexc("#AABFC4"), 0.07, 0.0, nb.mul(L.noise(1400.0, 1, detail=2), 0.12))
    skin = L.k(GB_SKIN)
    C.paint(skin, alpha=0.18)
    haze = nb.mul(nb.mul(skin, nb.ss(L.noise(9.0, 2, detail=3), 0.5, 0.78)), 0.75)
    C.paint(haze, hexc("#D3DDDF"), 0.12, alpha=0.27)
    smudge = nb.mul(skin, nb.ss(L.noise(26.0, 3, detail=4, rough=0.6), 0.6, 0.74))
    C.paint(nb.mul(smudge, 0.8), hexc("#C8D2D4"), 0.3, alpha=0.24)
    seam = nb.mul(nb.band(L.y, -mm(0.14), mm(0.14), mm(0.12)), skin)
    C.paint(seam, hexc("#D5DFE1"), 0.16, height=0.9, alpha=0.46)
    rr = nb.math("SQRT", nb.add(nb.mul(L.x, L.x), nb.mul(L.y, L.y)))
    plug = nb.mul(nb.band(rr, -mm(1.0), mm(3.4), mm(0.3)), nb.ss(nb.mul(L.nz, -1.0), 0.8, 0.95))
    C.paint(nb.mul(plug, skin), hexc("#C4CED0"), 0.4, height=0.6, alpha=0.6)
    # the beads: glossy gel, each its colour, lighter and clearer in the middle of its flat patch
    # against the skin (light goes through more of it there), deeper round the patch's edge and
    # down its sides, and each bead a little off the next in shade
    for k, col in GB_COLS.items():
        C.paint(L.k(k), hexc(col), 0.07, 0.0, alpha=1.0)
    c = (0.0, 0.0, mm(GB_ZC))
    out = nb.vop("DOT_PRODUCT", L.N, nb.vop("NORMALIZE", nb.vop("SUBTRACT", L.P, c)))
    shade = nb.mr(out, 0.2, 0.99, 0.55, 1.12)
    shade = nb.mul(shade, nb.mr(L.noise(45.0, 4, detail=2), 0.3, 0.7, 0.9, 1.08))
    C.col = nb.mixc(beads, C.col, nb.tint(C.col, shade))
    clear = nb.mul(beads, nb.mul(nb.ss(out, 0.93, 0.998), 0.12))
    C.paint(clear, hexc("#F4F6F2"))
    # far down its sides, deep in the gaps, it's seen through the water: a hair milky
    web = nb.mul(beads, nb.mul(nb.inv(nb.ss(out, 0.05, 0.4)), 0.4))
    C.paint(web, hexc("#DCE3E4"), 0.1)
    # the deeper beads, a pale milky cloud of all their colours through the water
    core = L.k(GB_CORE)
    cloud = nb.mixc(nb.ss(L.noise(30.0, 5, detail=2), 0.4, 0.6), hexc("#C9C0E4"), hexc("#BFE2CF"))
    cloud = nb.mixc(nb.ss(L.noise(30.0, 6, detail=2), 0.45, 0.62), cloud, hexc("#E9DDB0"))
    cloud = nb.mixc(nb.ss(L.noise(30.0, 7, detail=2), 0.5, 0.66), cloud, hexc("#E7C3D4"))
    C.paint(core, cloud, 0.2, 0.0, alpha=1.0)
    C.finish(f.dust, grime=0.1, keep=nb.add(beads, core, clamp=True))
    return C.surface(bump_dist=mm(0.1), bump=0.4)


GB_FOCUS = (0.0, 0.0, mm(GB_ZC))

GEL_BEAD_BALL = kit.Find(
    "GelBeadBall",
    [kit.Part("Body", gb_skin, clear=True),
     kit.Part("BeadsLow", gb_beads_part("Low"), (0.0, 0.0, 0.0), "Body", (0, 0, 1)),
     kit.Part("BeadsMid", gb_beads_part("Mid"), (0.0, 0.0, 0.0), "Body", (0, 0, 1)),
     kit.Part("BeadsTop", gb_beads_part("Top"), (0.0, 0.0, 0.0), "Body", (0, 0, 1))],
    gelbead_look,
    motions={
        # squeezed: it squashes heavy as the water moves and the beads swirl round inside, the
        # top band one way, the middle the other, the bottom a little; let go, it heaves back and
        # wobbles, and the beads slop back past where they were and settle
        "Squeeze": dict(duration=2.3, focus=GB_FOCUS, distance=0.95,
                        tracks=[("Body", "stretch", K.SLOSH),
                                ("BeadsTop", "turn", K.SWIRL_TOP),
                                ("BeadsMid", "turn", K.SWIRL_MID),
                                ("BeadsLow", "turn", K.SWIRL_LOW)]),
    },
    dust=GB["dust"], seed=GB["seed"], texels=1000, cage=0.0016,
)

FINDS = [BUTTER_STICK, STRESS_BALL, MOCHI_BUN, TOAST_SLICE, JUMBO_STRAWBERRY, CAPYBARA,
         PAPER_SQUISHY, GEL_BEAD_BALL]

if __name__ == "__main__":
    kit.main("Squishies", HERE, FINDS)
