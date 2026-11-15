"""The Lights set (art/finds/lights/README.md), built with the finds kit.

    scripts/art.sh set lights [textures|export|renders|quick] [FindName]
"""

import math
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "kit"))
sys.path.insert(0, HERE)

import bmesh  # noqa: E402
from mathutils import Matrix, Vector  # noqa: E402

import kit  # noqa: E402
import spec as K  # noqa: E402
from look import Coat, hexc  # noqa: E402
from shapes import Shape, arc, fillet, helix  # noqa: E402

# What a face is, for the looks.
(ENAMEL, INSIDE, STEEL, SPRING, BOLT, BAKELITE, BUTTON, GLASS, BRASS, CORD, RUBBER, PRONG,
 FELT) = range(13)


def spline(pts, n):
    """A smooth path through pts (Catmull-Rom), n points a span."""
    P = [Vector(p) for p in pts]
    P = [P[0] * 2 - P[1]] + P + [P[-1] * 2 - P[-2]]
    out = []
    for i in range(1, len(P) - 2):
        p0, p1, p2, p3 = P[i - 1], P[i], P[i + 1], P[i + 2]
        for j in range(n):
            t = j / n
            out.append(0.5 * ((2 * p1) + (-p0 + p2) * t + (2 * p0 - 5 * p1 + 4 * p2 - p3) * t * t
                              + (-p0 + 3 * p1 - 3 * p2 + p3) * t * t * t))
    out.append(P[-2])
    return [tuple(v) for v in out]


# --- the desk lamp ---------------------------------------------------------------------------

D = K.DESK_LAMP
S_, E_, W_, SHADE_O = K.lamp_joints()
M_LOWER = Matrix.Translation(S_) @ Matrix.Rotation(math.radians(-D["lower_tilt"]), 4, "X")
M_UPPER = Matrix.Translation(E_) @ Matrix.Rotation(math.radians(90 + D["upper_drop"]), 4, "X")
M_SHADE = Matrix.Translation(SHADE_O) @ Matrix.Rotation(math.radians(-D["shade_tilt"]), 4, "X")


def segs(hi, lo_n):
    return lo_n * 2 if hi else lo_n


def lamp_base(hi):
    s = Shape()
    n = segs(hi, 32)
    f = 3 if hi else 2
    R, H, r2, h2 = D["base_r"], D["base_h"], D["step_r"], D["step_h"]
    prof = [(0.0, 0.004), (R - 0.05, 0.004), (R - 0.045, 0.0)]
    prof += fillet(R - 0.012, 0.012, 0.012, (-90, 0), f)
    prof += fillet(R - 0.02, H - 0.02, 0.02, (0, 90), f + 1)
    prof += fillet(r2 + 0.008, H + 0.008, 0.008, (-90, -180), f)
    prof += fillet(r2 - 0.015, h2 - 0.015, 0.015, (0, 90), f + 1)
    b = D["boss_r"]
    prof += [(b + 0.01, h2), (b, h2 + 0.006), (b * 0.8, D["boss_top"] - 0.01),
             (b * 0.5, D["boss_top"] - 0.002), (0.0, D["boss_top"])]
    kinds = [FELT, FELT] + [ENAMEL] * (len(prof) - 3)
    s.lathe(prof, ENAMEL, n, kinds=kinds)
    tr, t0, t1 = D["turret"]
    s.lathe([(0.0, t0 - 0.01), (tr, t0 - 0.01), (tr, t1 - 0.004), (tr - 0.004, t1), (0.0, t1)],
            STEEL, segs(hi, 20))
    yx, yt, yd, y0, y1 = D["yoke"]
    s.box((-yx - yt / 2 - 0.004, -yd / 2, t1 - 0.012), (yx + yt / 2 + 0.004, yd / 2, t1 + 0.01),
          ENAMEL, 0.004, 2 if hi else 1)
    for sx in (-1, 1):
        s.box((sx * yx - yt / 2, -yd / 2, y0), (sx * yx + yt / 2, yd / 2, y1), ENAMEL, 0.004,
              2 if hi else 1)
    # the shoulder's pin, a bolt head one side and a wing nut the other
    sh = Vector(D["shoulder"])
    s.cylinder(sh + Vector((-0.084, 0, 0)), sh + Vector((0.084, 0, 0)), 0.011, STEEL, segs(hi, 10))
    s.cylinder(sh + Vector((-0.092, 0, 0)), sh + Vector((-0.077, 0, 0)), 0.021, BOLT, 6)
    s.cylinder(sh + Vector((0.077, 0, 0)), sh + Vector((0.09, 0, 0)), 0.019, BOLT, segs(hi, 10))
    s.box(sh + Vector((0.08, -0.008, -0.05)), sh + Vector((0.09, 0.008, 0.05)), BOLT, 0.003,
          2 if hi else 1)
    # the cord down the back, off the base and across the floor to its plug
    cr = D["cord_r"]
    px, py = D["plug"]
    path = [(0.078, 0.02, 0.33), (0.082, 0.07, 0.24), (0.095, 0.15, 0.16), (0.105, 0.21, 0.152),
            (0.12, 0.29, 0.09), (0.13, 0.36, 0.088), (0.14, 0.42, 0.04), (0.16, 0.48, cr),
            (0.27, 0.62, cr), (0.44, 0.74, cr), (0.4, 0.9, cr), (px, py - 0.06, cr)]
    s.tube(spline(path, 6 if hi else 3), cr, CORD, segs(hi, 8))
    s.box((px - 0.04, py - 0.06, 0.0), (px + 0.04, py + 0.05, 0.048), RUBBER, 0.012,
          3 if hi else 1)
    for sx in (-1, 1):
        s.box((px + sx * 0.02 - 0.003, py + 0.05, 0.012), (px + sx * 0.02 + 0.003, py + 0.11, 0.036),
              PRONG, 0.0015 if hi else 0.0, 1)
    return s


def lamp_lower(hi):
    s = Shape()
    L = D["lower_len"]
    bx, bt, bd = D["bars"]
    M = M_LOWER
    c = 2 if hi else 1
    for sx in (-1, 1):
        s.box((sx * bx - bt / 2, -bd / 2, -0.035), (sx * bx + bt / 2, bd / 2, L + 0.035), ENAMEL,
              0.004, c, M)
    hub = D["hub_r"]
    s.cylinder((-0.072, 0, L), (0.072, 0, L), hub, STEEL, segs(hi, 14), M=M)
    for sx in (-1, 1):
        s.cylinder((sx * 0.072, 0, L), (sx * 0.084, 0, L), 0.02, BOLT, 6, M=M)
    sp = D["springs"]
    y = sp["back"] + sp["r"] + 0.004
    for z in (sp["s0"] - 0.022, sp["s1"] + 0.022):
        s.cylinder((-bx - bt / 2, y, z), (bx + bt / 2, y, z), 0.007, STEEL, segs(hi, 8), M=M)
        for sx in (-1, 1):
            s.box((sx * bx - bt / 2, 0.0, z - 0.016), (sx * bx + bt / 2, y + 0.012, z + 0.016),
                  ENAMEL, 0.003, c, M)
    for sx in (-1, 1):
        x = sx * sp["x"]
        a, b = (x, y, sp["s0"]), (x, y, sp["s1"])
        if hi:
            s.tube(helix(a, b, sp["r"] - sp["wire"], (sp["s1"] - sp["s0"]) / (2.05 * sp["wire"]), 12),
                   sp["wire"], SPRING, 8, M)
        else:
            s.cylinder(a, b, sp["r"], SPRING, 12, M=M)
        for z0, zp, a0, a1 in ((sp["s0"], sp["s0"] - 0.022, 90, -230), (sp["s1"], sp["s1"] + 0.022, -90, 230)):
            loop = [(x, y, z0)] + arc((x, y, zp), 0.011, a0, a1, 10 if hi else 6, "YZ")
            s.tube(loop, sp["wire"] * 1.2, SPRING, segs(hi, 6), M, caps=True)
    cr = D["cord_r"]
    s.tube(spline([(0.075, 0.0, 0.06), (0.078, 0.012, 0.4), (0.08, 0.02, 0.8), (0.078, 0.01, L - 0.05)],
                  8 if hi else 4), cr, CORD, segs(hi, 8), M)
    return s


def lamp_upper(hi):
    s = Shape()
    L = D["upper_len"]
    rx, rr = D["rods"]
    M = M_UPPER
    c = 2 if hi else 1
    for sx in (-1, 1):
        s.cylinder((sx * rx, 0, 0.02), (sx * rx, 0, L - 0.02), rr, STEEL, segs(hi, 10), M=M)
    s.box((-0.036, -0.022, -0.03), (0.036, 0.022, 0.05), ENAMEL, 0.006, c, M)
    s.box((-0.045, -0.022, L - 0.05), (0.045, 0.022, L + 0.03), ENAMEL, 0.006, c, M)
    s.box((-0.026, -0.012, L * 0.5 - 0.02), (0.026, 0.012, L * 0.5 + 0.02), ENAMEL, 0.004, c, M)
    cr = D["cord_r"]
    s.tube(spline([(0.05, -0.03, 0.05), (0.052, -0.05, L * 0.35), (0.052, -0.055, L * 0.65),
                   (0.05, -0.035, L - 0.06)], 8 if hi else 4), cr, CORD, segs(hi, 8), M)
    return s


def lamp_head(hi):
    s = Shape()
    n = segs(hi, 32)
    sd = D["shade"]
    R, Ln, nk = sd["rim"], sd["length"], sd["neck"]
    # a bell: a round shoulder off the neck, then a long cone flaring a little at the rim
    inner = [(0.0, -0.032), (0.07, -0.032), (nk - 0.008, -0.05), (nk - 0.008, -0.1),
             (0.104, -0.128), (0.142, -0.168), (0.186, -0.25), (0.226, -0.36), (0.262, -0.47),
             (R - 0.014, -0.56), (R - 0.006, -Ln)]
    lip = fillet(R + 0.002, -Ln + 0.004, 0.006, (-160, 40), 4 if hi else 2)
    outer = [(R - 0.003, -0.584), (R - 0.022, -0.53), (0.27, -0.46), (0.234, -0.36),
             (0.194, -0.25), (0.152, -0.168), (0.118, -0.128), (nk + 0.005, -0.106), (nk, -0.09),
             (nk, -0.025)]
    outer += fillet(nk - 0.014, -0.014, 0.014, (0, 90), 3 if hi else 1)
    sw = D["switch"]
    top = [(sw["collar"] + 0.006, 0.0), (sw["collar"], 0.004), (sw["collar"], 0.014),
           (sw["collar"] - 0.004, 0.018), (0.0, 0.018)]
    prof = inner + lip + outer + top
    kinds = ([INSIDE] * (len(inner) - 1) + [ENAMEL] * (len(lip) + len(outer) + len(top)))
    kinds[0] = kinds[1] = BAKELITE
    kinds[-4:] = [BAKELITE] * 4
    s.lathe(prof, ENAMEL, n, M_SHADE, kinds=kinds[:len(prof) - 1])
    # the lamp holder inside the neck
    s.lathe([(0.0, -0.14), (0.044, -0.14), (0.05, -0.133), (0.05, -0.04), (0.0, -0.04)],
            BAKELITE, segs(hi, 16), M_SHADE)
    # the wrist: a strap from the neck to the hub the arm's hinge turns on
    w = Vector(D["wrist_on_shade"])
    c = 2 if hi else 1
    s.box((-0.024, nk - 0.01, w.z - 0.03), (0.024, w.y, w.z + 0.03), ENAMEL, 0.005, c, M_SHADE)
    s.cylinder(w + Vector((-0.062, 0, 0)), w + Vector((0.062, 0, 0)), 0.02, STEEL, segs(hi, 12),
               M=M_SHADE)
    for sx in (-1, 1):
        s.cylinder(w + Vector((sx * 0.062, 0, 0)), w + Vector((sx * 0.072, 0, 0)), 0.018, BOLT, 6,
                   M=M_SHADE)
    # the cord leaves the top beside the switch and runs back to the arm
    cr = D["cord_r"]
    s.tube(spline([(0.0, 0.052, 0.004), (0.0, 0.075, 0.03), (0.02, 0.12, 0.045), (0.04, 0.17, 0.02)],
                  6 if hi else 3), cr, CORD, segs(hi, 8), M_SHADE)
    s.cylinder((0.0, 0.04, -0.004), (0.0, 0.058, 0.012), 0.016, RUBBER, segs(hi, 10), M=M_SHADE)
    return s


def lamp_switch(hi):
    s = Shape()
    sw = D["switch"]
    r, h = sw["r"], sw["h"]
    f = fillet(r - 0.005, 0.014 + h - 0.005, 0.005, (0, 90), 3 if hi else 1)
    s.lathe([(0.0, 0.012), (r, 0.012)] + f + [(0.0, 0.014 + h + 0.002)], BUTTON, segs(hi, 16),
            M_SHADE)
    return s


def lamp_bulb(hi):
    s = Shape()
    b = D["bulb"]
    r, tip, top, br = b["r"], b["tip"], b["base_top"], b["base_r"]
    glass = [(0.0, tip), (0.045, tip + 0.004), (0.082, tip + 0.022), (0.106, tip + 0.05),
             (r, tip + 0.1), (r - 0.004, tip + 0.135), (0.104, tip + 0.18), (0.08, tip + 0.225),
             (0.062, tip + 0.258), (0.056, tip + 0.28)]
    if hi:
        thread = []
        z = tip + 0.285
        while z < top - 0.006:
            thread += [(br - 0.004, z), (br + 0.003, z + 0.0045)]
            z += 0.009
        thread += [(br - 0.004, top - 0.004)]
    else:
        thread = [(br, tip + 0.285), (br, top - 0.004)]
    prof = glass + thread + [(0.0, top)]
    kinds = [GLASS] * (len(glass) - 1) + [BRASS] * (len(thread) + 1)
    s.lathe(prof, GLASS, segs(hi, 20), M_SHADE, kinds=kinds[:len(prof) - 1])
    return s


def lamp_look(L, f):
    nb = L.nb
    paint = nb.tint(hexc("#7E231C"), nb.mr(L.noise(2.5, 1, detail=3), 0.3, 0.7, 0.86, 1.08))
    C = Coat(L, paint, nb.mr(L.noise(7.0, 2, detail=4), 0.2, 0.8, 0.2, 0.36), 0.0,
             nb.mul(L.noise(320.0, 3, detail=1), 0.12))
    # the sun and years faded the enamel on whatever faced up
    C.paint(nb.mul(L.up, nb.mr(L.noise(1.5, 4, detail=3), 0.3, 0.7, 0.15, 0.4)), hexc("#9A4436"))
    enamel = L.k(ENAMEL)
    C.enamel_wear(enamel, hexc("#4A4642"), s=5, amount=1.6)
    # inside the shade: white enamel, yellowed and browned by the bulb's heat near the neck
    near = nb.ss(nb.pw(nb.add(nb.mul(nb.sub(L.x, 0.0), nb.sub(L.x, 0.0)),
                              nb.add(nb.mul(nb.sub(L.y, BULB_C[1]), nb.sub(L.y, BULB_C[1])),
                                     nb.mul(nb.sub(L.z, BULB_C[2]), nb.sub(L.z, BULB_C[2])))), 0.5),
                 0.26, 0.08)
    inside = L.k(INSIDE)
    C.paint(inside, nb.mixc(nb.mul(near, 0.75), hexc("#E7E1D2"), hexc("#B88A4E")), 0.38, 0.0, 0.0)
    # bright work: zinc-plated steel, dulled, scratched along its length, freckled with rust
    zinc = nb.tint(hexc("#B9BCBE"), nb.mr(L.noise(18.0, 6, detail=4), 0.3, 0.7, 0.72, 1.0))
    C.paint(L.k(STEEL), zinc, nb.mr(L.noise(30.0, 7, detail=3), 0.3, 0.7, 0.22, 0.4), 1.0)
    C.paint(L.k(SPRING), nb.tint(hexc("#A9ACAD"), 0.9), 0.32, 1.0)
    rust = nb.mul(L.k(STEEL, SPRING, BOLT), nb.ss(L.noise(40.0, 8, detail=4, rough=0.7), 0.64, 0.72))
    C.paint(rust, hexc("#6B3B22"), 0.85, 0.15, 0.05)
    C.paint(L.k(BOLT), hexc("#5C5E60"), 0.42, 1.0)
    C.paint(L.k(BAKELITE), hexc("#2B1B13"), 0.3, 0.0)
    C.paint(L.k(BUTTON), hexc("#1B1714"), 0.34, 0.0)
    # the bulb: pearl glass, a brass screw base
    C.paint(L.k(GLASS), hexc("#EFEBE3"), 0.18, 0.0)
    C.paint(L.k(BRASS), hexc("#A88445"), 0.38, 1.0)
    C.lights(nb.mul(L.k(GLASS), nb.mr(L.z, BULB_C[2] - 0.25, BULB_C[2] + 0.05, 1.0, 0.7)))
    # the cord: braided cloth, a brown and gold twist
    twist = nb.sin(nb.mul(nb.add(nb.mul(L.x, 1.0), nb.add(L.y, L.z)), 520.0))
    C.paint(L.k(CORD), nb.mixc(nb.mr(twist, -1, 1, 0, 1), hexc("#3A2A1D"), hexc("#7A6040")), 0.85,
            0.0, nb.mul(twist, 0.25))
    C.paint(L.k(RUBBER), hexc("#1E1D1C"), 0.62, 0.0)
    C.paint(L.k(PRONG), hexc("#B59456"), 0.3, 1.0)
    C.paint(L.k(FELT), hexc("#2F332B"), 0.97, 0.0)
    C.finish(f.dust, grime=0.55)
    return C.surface(bump_dist=0.0015, bump=0.5)


BULB_C = K.on_shade((0.0, 0.0, -0.36))
TIP = K.on_shade((0.0, 0.0, D["bulb"]["tip"] - 0.02))
AIM = Vector(K.on_shade((0.0, 0.0, -1.0))) - Vector(K.on_shade((0.0, 0.0, 0.0)))
SWITCH_AXIS = tuple(Vector(K.on_shade((0.0, 0.0, 1.0))) - Vector(K.on_shade((0.0, 0.0, 0.0))))

PRESS = [(0.0, 0.0), (0.06, -0.014, "Quad", "In"), (0.085, -0.018, "Quad", "Out"),
         (0.21, 0.0, "Back", "Out")]
NOD = [(0.0, 0.0), (0.085, 4.0, "Quad", "Out"), (0.24, -1.8), (0.38, 0.7), (0.54, 0.0)]
SWAY = [(0.0, 0.0), (0.12, 0.8, "Quad", "Out"), (0.32, -0.35), (0.5, 0.0)]

DESK_LAMP = kit.Find(
    "DeskLamp",
    [kit.Part("Base", lamp_base),
     kit.Part("LowerArm", lamp_lower, S_, "Base", (1, 0, 0)),
     kit.Part("UpperArm", lamp_upper, E_, "LowerArm", (1, 0, 0)),
     kit.Part("Head", lamp_head, W_, "UpperArm", (1, 0, 0)),
     kit.Part("Switch", lamp_switch, K.on_shade((0.0, 0.0, 0.012)), "Head", SWITCH_AXIS),
     kit.Part("Bulb", lamp_bulb, K.on_shade((0.0, 0.0, D["bulb"]["base_top"])), "Head")],
    lamp_look,
    lights=[
        # the pool: a warm cone out of the shade, onto the desk (or the unit's floor)
        dict(kind="Spot", part="Head", at=TIP, face=tuple(AIM.normalized()), kelvin=D["kelvin"],
             brightness=2.2, range=10, angle=80, shadows=True, preview_watts=55.0,
             preview_blend=0.55),
        # the spill: the bulb's glow round the shade, which also lights at low graphics, where a
        # close spotlight lights nothing (docs/STUDIO.md)
        dict(kind="Point", part="Head", at=K.on_shade((0.0, 0.0, -0.52)), kelvin=D["kelvin"],
             brightness=0.5, range=5, shadows=False, preview_kind="POINT", preview_watts=1.5,
             preview_size=0.1),
    ],
    glow=dict(part="Bulb", strength=3.0, tint=(255, 196, 128), preview=16.0),
    motions={
        # a thumb on the top of the shade: the button goes in, clicks, the shade nods under the
        # push and settles, the arm sways a touch after it; the filament flares up warm
        "SwitchOn": dict(duration=0.6, focus="Head", tracks=[
            ("Switch", "move", PRESS), ("Head", "turn", NOD), ("UpperArm", "turn", SWAY),
            ("Bulb", "glow", [(0.0, 0.0), (0.085, 0.0, "Linear", "In"), (0.11, 0.6, "Quad", "Out"),
                              (0.2, 1.0, "Quad", "Out")])]),
        # the same press; the light drops at the click and the filament fades orange to nothing
        "SwitchOff": dict(duration=0.6, focus="Head", tracks=[
            ("Switch", "move", PRESS), ("Head", "turn", NOD), ("UpperArm", "turn", SWAY),
            ("Bulb", "glow", [(0.0, 1.0), (0.085, 1.0, "Linear", "In"), (0.12, 0.22, "Quad", "Out"),
                              (0.5, 0.0, "Sine", "Out")])]),
    },
    dust=D["dust"], seed=D["seed"],
)

# --- the plug-in night-light -------------------------------------------------------------------

(HOUSING, FROST, SLOT, TAB, BLADE) = range(13, 18)
N = K.NIGHT_LIGHT
NB_, NS_ = N["base"], N["shade"]


def nl_section(w, d, s=1.0, hi=False):
    """One ring of the shade: a rounded D, its flat back on the wall (Y = 0), anticlockwise from
    above; scaled by s about the middle of its back. Returns the ring and its count in front."""
    nf, nbk = (32, 4) if hi else (18, 2)
    e = 2.0 / N["squareness"]
    sp = lambda c: math.copysign(abs(c) ** e, c)  # noqa: E731
    ring = []
    for i in range(nf + 1):
        a = -math.pi / 2 + math.pi * i / nf
        ring.append((w / 2 * sp(math.sin(a)) * s, -d * abs(math.cos(a)) ** e * s))
    for i in range(1, nbk):
        ring.append((w / 2 * s - w * s * i / nbk, 0.0))
    return ring, nf


def nl_profile():
    """The shade's (z, width, depth) every few thousandths of a stud, smooth through the spec."""
    return [Vector(p) for p in spline(NS_, 24)]


def nl_at(z, prof):
    for a, b in zip(prof, prof[1:]):
        if a.x <= z <= b.x:
            t = (z - a.x) / max(b.x - a.x, 1e-9)
            v = a.lerp(b, t)
            return v.y, v.z
    return prof[-1].y, prof[-1].z


def nl_scaled(build):
    """A night-light part built to the spec's numbers, then scaled up about the origin."""
    def go(hi):
        s = build(hi)
        k = N["scale"]
        bmesh.ops.scale(s.bm, vec=(k, k, k), verts=s.bm.verts)
        return s
    return go


def nl_k(v):
    return tuple(c * N["scale"] for c in v)


def nl_shade(hi):
    s = Shape()
    prof = nl_profile()
    rb = N["ribs"]
    z0s, z1s = NS_[0][0], NS_[-1][0]
    if hi:
        zs = [z0s, NS_[1][0]]
        z = rb["z0"]
        while z < rb["z1"]:
            zs.append(z)
            z += rb["pitch"] / 6
        zs.append(z1s)
    else:
        zs = [z0s, NS_[1][0], 0.15, 0.2, 0.25, 0.3, 0.35, z1s]
    rings, nf = [], 0
    for z in zs:
        w, d = nl_at(z, prof)
        sc = 1.0
        if hi and rb["z0"] <= z <= rb["z1"]:
            # a rounded rib every pitch, the grooves sharper than the crests, centred on the
            # game mesh's surface so the bake reaches both
            c = (0.5 + 0.5 * math.cos(2 * math.pi * (z - rb["z0"]) / rb["pitch"])) ** 1.5
            sc = 1.0 + rb["depth"] * (c - 0.45) / d
        ring, nf = nl_section(w, d, sc, hi)
        rings.append([(x, y, z) for x, y in ring])
    # the dome: the top rounds over towards the wall
    w, d = nl_at(z1s, prof)
    m = 12 if hi else 7
    for k in range(1, m):
        a = math.pi / 2 * k / m
        ring, _ = nl_section(w, d, math.cos(a), hi)
        rings.append([(x, y, z1s + N["dome"] * math.sin(a)) for x, y in ring])
    rings.append([(0.0, 0.0, z1s + N["dome"])])
    s.loft(rings, FROST, kinds=lambda j: FROST if j < nf else HOUSING, split=2,
           cap_bottom=HOUSING)
    return s


def nl_base(hi):
    s = Shape()
    w, d, h, r = NB_["w"], NB_["d"], NB_["h"], NB_["round"]
    s.box((-w / 2, -d, 0.0), (w / 2, 0.0, h), HOUSING, r, 3 if hi else 2)
    # the switch's slot: a dark floor behind a raised frame
    sl = N["slot"]
    sw, z0, z1 = sl["w"], sl["z0"], sl["z1"]
    fy = -d - 0.004
    s.box((-sw / 2, -d - 0.0012, z0), (sw / 2, -d + 0.002, z1), SLOT)
    fr = 0.0045
    c = 0.0012 if hi else 0.0
    for lo_, hi_ in (((-sw / 2 - fr, fy, z0 - fr), (-sw / 2, -d + 0.002, z1 + fr)),
                     ((sw / 2, fy, z0 - fr), (sw / 2 + fr, -d + 0.002, z1 + fr)),
                     ((-sw / 2, fy, z0 - fr), (sw / 2, -d + 0.002, z0)),
                     ((-sw / 2, fy, z1), (sw / 2, -d + 0.002, z1 + fr))):
        s.box(lo_, hi_, HOUSING, c, 1)
    # the plug: two flat blades out of the back, one wider (a polarised plug)
    bl = N["blades"]
    for x, wd in ((-bl["x"], bl["wide"]), (bl["x"], bl["narrow"])):
        s.box((x - bl["thick"] / 2, -0.004, bl["z"] - wd / 2),
              (x + bl["thick"] / 2, bl["len"], bl["z"] + wd / 2), BLADE,
              0.0012 if hi else 0.0, 2 if hi else 1)
        # the raised collar the blade comes out of
        s.box((x - bl["thick"] / 2 - 0.004, -0.002, bl["z"] - wd / 2 - 0.004),
              (x + bl["thick"] / 2 + 0.004, 0.004, bl["z"] + wd / 2 + 0.004), HOUSING,
              0.0015 if hi else 0.0, 1)
    return s


def nl_tab(hi):
    s = Shape()
    t, d = N["tab"], NB_["d"]
    y0, y1 = -d - 0.001, -d - 0.001 - t["out"]
    s.box((-t["w"] / 2, y1, t["z"]), (t["w"] / 2, y0, t["z"] + t["h"]), TAB,
          0.0022 if hi else 0.0012, 2 if hi else 1)
    if hi:
        # three ridges for a thumb
        for i in range(3):
            z = t["z"] + t["h"] * (0.28 + 0.22 * i)
            s.box((-t["w"] / 2 + 0.002, y1 - 0.0016, z - 0.0011),
                  (t["w"] / 2 - 0.002, y1 + 0.0005, z + 0.0011), TAB, 0.0005, 1)
    return s


def nl_look(L, f):
    nb = L.nb
    # ivory plastic: a fine moulded stipple, yellowed on top by years of a warm bulb
    ivory = nb.tint(hexc("#E2D9C2"), nb.mr(L.noise(3.0, 1, detail=3), 0.3, 0.7, 0.95, 1.03))
    C = Coat(L, ivory, nb.mr(L.noise(9.0, 2, detail=3), 0.3, 0.7, 0.38, 0.5), 0.0,
             nb.mul(L.noise(520.0, 3, detail=1), 0.05))
    C.paint(nb.mul(L.up, 0.35), hexc("#D9CDAA"))
    scuff = nb.mul(L.edge(0.006, k=4.0), nb.ss(L.noise(30.0, 4, detail=4, rough=0.7), 0.6, 0.68))
    C.paint(nb.mul(scuff, L.k(HOUSING, TAB)), hexc("#9D978A"), 0.62)
    # the shade: frosted, milky plastic, glossier on the ribs, browned over the bulb by its heat
    bx, by, bz = nl_k(N["bulb"])
    dz = nb.mul(nb.sub(L.z, bz), 0.55)
    dist = nb.pw(nb.add(nb.mul(nb.sub(L.x, bx), nb.sub(L.x, bx)),
                        nb.add(nb.mul(nb.sub(L.y, by), nb.sub(L.y, by)), nb.mul(dz, dz))), 0.5)
    hot = nb.ss(dist, 0.15 * N["scale"], 0.064 * N["scale"])
    frost = L.k(FROST)
    C.paint(frost, nb.tint(hexc("#F3F1EC"), nb.mr(L.noise(5.0, 5, detail=3), 0.3, 0.7, 0.96, 1.02)),
            nb.mr(L.nz, -1.0, 1.0, 0.3, 0.22), 0.0, 0.0)
    heat = nb.mul(frost, nb.add(nb.mul(nb.ss(L.z, 0.34 * N["scale"], 0.46 * N["scale"]), 0.3), nb.mul(hot, 0.22), clamp=True))
    C.paint(heat, hexc("#E2CB98"))
    # lit, it's brightest round the bulb, and the ribs' slopes show as darker lines
    ribs = nb.inv(nb.mul(nb.pw(nb.mul(L.nz, L.nz), 0.5), 0.45))
    C.lights(nb.mul(nb.mul(frost, ribs), nb.add(0.06, nb.mul(nb.pw(hot, 1.6), 0.94))))
    C.paint(L.k(SLOT), hexc("#221E1A"), 0.75, 0.0)
    C.paint(L.k(TAB), hexc("#DFD8C4"), 0.48, 0.0)
    # the blades: nickel-plated brass, worn to the brass where a socket gripped them
    blade = L.k(BLADE)
    C.paint(blade, nb.tint(hexc("#C9C5BB"), nb.mr(L.noise(40.0, 6, detail=3), 0.3, 0.7, 0.85, 1.0)),
            nb.mr(L.noise(60.0, 7, stretch=(1.0, 0.1, 1.0), detail=3), 0.3, 0.7, 0.2, 0.34), 1.0)
    worn = nb.mul(blade, nb.mul(nb.ss(L.y, 0.014, 0.035),
                                nb.ss(L.noise(24.0, 8, detail=4), 0.45, 0.6)))
    C.paint(worn, hexc("#B38D55"), 0.36, 1.0)
    tarnish = nb.mul(blade, nb.ss(L.noise(16.0, 9, detail=4, rough=0.7), 0.62, 0.7))
    C.paint(tarnish, hexc("#7A705E"), 0.55, 0.8)
    C.finish(f.dust, grime=0.5)
    return C.surface(bump_dist=0.0008, bump=0.5)


TRAVEL = N["travel"] * N["scale"]
NIGHT_LIGHT = kit.Find(
    "NightLight",
    [kit.Part("Base", nl_scaled(nl_base)),
     kit.Part("Shade", nl_scaled(nl_shade), nl_k((0.0, 0.0, NS_[0][0])), "Base"),
     kit.Part("Switch", nl_scaled(nl_tab),
              nl_k((0.0, -NB_["d"] - 0.001 - N["tab"]["out"] / 2, N["tab"]["z"] + N["tab"]["h"] / 2)),
              "Base", (0, 0, 1))],
    nl_look,
    lights=[
        # the soft glow by the floor: a 4 W bulb through frosted plastic lights round it, not
        # in a beam; no shadows, so it shines out through the shade as the glow does
        dict(kind="Point", part="Shade", at=nl_k(N["bulb"]), kelvin=N["kelvin"], brightness=0.7,
             range=8, shadows=False, preview_kind="POINT", preview_watts=2.0, preview_size=0.04),
    ],
    glow=dict(part="Shade", strength=2.0, tint=(255, 190, 122), preview=3.0),
    motions={
        # a thumb pushes the tab up: it sticks, snaps over its catch to the top, knocks back off
        # the end a hair and settles; the bulb takes a moment to warm, then the shade glows
        "SwitchOn": dict(duration=0.5, focus=nl_k((0.0, -0.06, 0.26)), distance=0.85, tracks=[
            ("Switch", "move", [(0.0, 0.0), (0.07, 0.004, "Quad", "In"),
                                (0.12, TRAVEL, "Quad", "Out"), (0.16, TRAVEL - 0.0025, "Sine", "Out"),
                                (0.22, TRAVEL)]),
            ("Shade", "glow", [(0.0, 0.0), (0.12, 0.0, "Linear", "In"), (0.15, 0.5, "Quad", "Out"),
                               (0.28, 1.0, "Quad", "Out")])]),
        # pulled back down: the light drops at the click and the filament's orange fades out
        "SwitchOff": dict(duration=0.55, focus=nl_k((0.0, -0.06, 0.26)), distance=0.85, tracks=[
            ("Switch", "move", [(0.0, TRAVEL), (0.07, TRAVEL - 0.004, "Quad", "In"),
                                (0.12, 0.0, "Quad", "Out"), (0.16, 0.0025, "Sine", "Out"),
                                (0.22, 0.0)]),
            ("Shade", "glow", [(0.0, 1.0), (0.12, 1.0, "Linear", "In"), (0.15, 0.28, "Quad", "Out"),
                               (0.5, 0.0, "Sine", "Out")])]),
    },
    dust=N["dust"], seed=N["seed"],
    # its ribs are 0.014 studs apart: at 300 texels a stud they'd smear into four texels
    texels=500,
)

FINDS = [DESK_LAMP, NIGHT_LIGHT]

if __name__ == "__main__":
    kit.main("Lights", HERE, FINDS)
