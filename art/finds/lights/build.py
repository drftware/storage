"""The Lights set (art/finds/lights/README.md), built with the finds kit.

    scripts/art.sh set lights [textures|export|renders|quick] [FindName]
"""

import math
import os
import random
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "kit"))
sys.path.insert(0, HERE)

import bmesh  # noqa: E402
import numpy as np  # noqa: E402
from mathutils import Matrix, Vector  # noqa: E402

import ease  # noqa: E402
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


# --- the tea light in a jar ---------------------------------------------------------------------

(JAR, JAR_IN, CUP, WAX, WICK, FLAME, WIRE) = range(18, 25)
TJ, TL, TW = K.TEA_JAR, K.TEA_LIGHT, K.TEA_WIRE
TL_AT = Vector(TL["at"])
FLAME_FOOT = TL_AT + Vector((0.0, 0.0, TL["wax"] + TL["flame"]["at"]))
BAIL_PIVOT = Vector((0.0, 0.0, TW["z"]))


def tj_jar(hi):
    """The jar: one glass shell, out round the base, up the body, over the rim and back down the
    inside to its floor; the detailed one has its screw thread."""
    s = Shape()
    out, ins = TJ["outside"], TJ["inside"]
    (r0, z0), (r1, _) = out[-1], ins[0]
    nl = 6 if hi else 3
    lip = fillet((r0 + r1) / 2, z0, (r0 - r1) / 2, (0, 180), nl)
    prof = out[:-1] + lip + ins[1:]
    n_out = len(out) - 1 + nl  # the spans up the outside and over the rim
    kinds = [JAR] * n_out + [JAR_IN] * (len(prof) - 1 - n_out)
    s.lathe(prof, JAR, segs(hi, 32), kinds=kinds)
    if hi:
        t = TJ["thread"]
        n = int(t["turns"] * 48)
        pts, radii = [], []
        for i in range(n + 1):
            u = i / n
            a = 2 * math.pi * t["turns"] * u + 0.6
            pts.append((t["out"] * math.cos(a), t["out"] * math.sin(a), t["z0"] + (t["z1"] - t["z0"]) * u))
            # the thread runs out to nothing at both ends, as a moulded thread does
            radii.append(t["r"] * max(0.25, min(1.0, u / 0.1, (1.0 - u) / 0.1)))
        s.tube(pts, t["r"], JAR, 10, radii=radii)
    return s


def tj_candle(hi):
    """The tea light: a pressed aluminium cup with a rolled lip, its wax half burned down, the
    wick standing out of it, leaning and charred."""
    s = Shape()
    r, h, wx = TL["r"], TL["h"], TL["wax"]
    n = 3 if hi else 1
    cup = ([(0.0, 0.0), (r - 0.003, 0.0)] + fillet(r - 0.003, 0.003, 0.003, (-90, 0), n)[1:]
           + [(r + 0.0006, h - 0.004)] + fillet(r - 0.0004, h - 0.0012, 0.0012, (0, 180), 2 * n)[1:]
           + [(r - 0.0022, h - 0.004), (r - 0.0022, wx + 0.0025)])
    # the wax: it creeps up the wall a little, then lies flat, with a dip round the wick
    wax = [(r - 0.0035, wx + 0.0006), (r - 0.007, wx), (0.012, wx), (0.007, wx - 0.0012),
           (0.0, wx - 0.0016)]
    prof = cup + wax
    kinds = [CUP] * (len(cup) - 1) + [WAX] * len(wax)
    s.lathe(prof, CUP, segs(hi, 24), Matrix.Translation(TL_AT), kinds=kinds[:len(prof) - 1])
    w = TL["wick"]
    lean = math.radians(w["lean"])
    pts = []
    m = 8 if hi else 4
    for i in range(m + 1):
        u = i / m
        # it leans more towards its tip, where it has burned and curled
        a = lean * u ** 1.6
        pts.append(TL_AT + Vector((math.sin(a) * w["up"] * u * 0.7, 0.0, wx - 0.004 + (w["up"] + 0.004) * u)))
    s.tube(pts, w["r"], WICK, 8 if hi else 5)
    return s


def tj_flame(hi):
    """The flame: a teardrop round at its foot and drawn to a point, widest a third of the way up."""
    s = Shape()
    f = TL["flame"]
    n = 24 if hi else 10
    shape = lambda u: u ** 0.42 * (1.0 - u) ** 1.15  # noqa: E731
    peak = max(shape(i / 200) for i in range(201))
    prof = [(0.0, 0.0)] + [(f["r"] * shape(i / n) / peak, f["h"] * i / n) for i in range(1, n)]
    prof.append((0.0, f["h"]))
    s.lathe(prof, FLAME, segs(hi, 14), Matrix.Translation(FLAME_FOOT))
    return s


def tj_eye(sign, n):
    """One ear: the wire coiled one and a half times round the bail's hook (the X axis), as it's
    made, wound round a nail. sign 1 the right ear (arriving from the front), -1 the left."""
    e, z = TW["eye"], TW["z"]
    pts = []
    for i in range(n + 1):
        a = math.radians(180 + 540 * i / n)
        p = (e["x0"] + 2 * TW["r"] * e["turns"] * i / n, e["r"] * math.cos(a), z + e["r"] * math.sin(a))
        pts.append((p[0] * sign, p[1] * sign, p[2]))
    return pts


def tj_neck(a0, a1, n):
    R, z = TW["neck"] + TW["r"], TW["z"]
    return [(R * math.cos(math.radians(a0 + (a1 - a0) * i / n)),
             R * math.sin(math.radians(a0 + (a1 - a0) * i / n)), z) for i in range(n + 1)]


def tj_wire(hi):
    """The wire round the neck: one turn, an ear coiled out each side, its two ends twisted
    together at the back into a short tail."""
    s = Shape()
    R, z, r = TW["neck"] + TW["r"], TW["z"], TW["r"]
    # the tail: two strands twisted round each other, out from the back and a little down
    p0, p1 = Vector((0.0, R + 0.006, z)), Vector((0.0, R + 0.04, z - 0.007))
    ax = (p1 - p0).normalized()
    e1 = Vector((1.0, 0.0, 0.0))
    e2 = ax.cross(e1)
    strand = []
    m = 24 if hi else 12
    for k in range(2):
        pts = []
        for i in range(m + 1):
            u = i / m
            a = 2 * math.pi * 2.25 * u + k * math.pi
            pts.append(tuple(p0.lerp(p1, u) + (e1 * math.cos(a) + e2 * math.sin(a)) * r * 0.95))
        strand.append(pts)
    k = 3 if hi else 1
    e = 30 if hi else 16
    path = (list(reversed(strand[1])) + tj_neck(100, 158, 6 * k) + tj_eye(-1, e)
            + tj_neck(202, 338, 14 * k) + tj_eye(1, e) + tj_neck(382, 440, 6 * k) + strand[0])
    s.tube(path, r, WIRE, 10 if hi else 6)
    return s


def tj_bail(hi):
    """The bail: hooked through both ears, straight up the arms and round over the top; built
    upright and laid back to where it fell against the jar."""
    s = Shape()
    b, z = TW["bail"], TW["z"]
    x, bend, arms = b["x"], b["bend"], b["arms"]
    side = [(b["inner"], 0.0, z), (x - bend, 0.0, z)]
    side += [(x - bend + bend * math.sin(math.radians(a)), 0.0, z + bend - bend * math.cos(math.radians(a)))
             for a in range(15, 91, 15)]
    side += [(x, 0.0, z + arms)]
    top = [(x * math.cos(math.radians(a)), 0.0, z + arms + x * math.sin(math.radians(a)))
           for a in range(0, 181, 5 if hi else 9)][1:-1]
    left = [(-p[0], p[1], p[2]) for p in reversed(side)]
    M = (Matrix.Translation(BAIL_PIVOT) @ Matrix.Rotation(math.radians(TW["bail_rest"]), 4, "X")
         @ Matrix.Translation(-BAIL_PIVOT))
    s.tube(side + top + left, TW["r"], WIRE, 10 if hi else 6, M)
    return s


def tj_look(L, f):
    nb = L.nb
    glass = L.k(JAR, JAR_IN)
    # soda-lime glass: a faint sea green, glossy, seen through
    # (glass reflects, it hardly scatters: a dark colour keeps it from glowing like plastic when
    # the candle lights it from inside, and lets its highlights carry it)
    C = Coat(L, hexc("#9FB5AA"), 0.04, 0.0)
    C.paint(glass, alpha=0.12)
    # thicker glass reads greener and less clear: the base, the bead and thread, the rim
    base = nb.ss(L.z, 0.034, 0.012)
    neck = nb.ss(L.z, 0.405, 0.43)
    rim = nb.ss(L.z, 0.493, 0.4985)
    thick = nb.mx(nb.mx(base, nb.mul(neck, 0.55)), rim)
    C.paint(nb.mul(glass, thick), hexc("#86A796"), alpha=0.4)
    # handled: smudges and fingermarks on the outside, dull and a little grey
    smudge = nb.mul(L.k(JAR), nb.ss(L.noise(7.0, 11, detail=4, rough=0.6), 0.55, 0.7))
    C.paint(nb.mul(smudge, 0.8), hexc("#CFD3CF"), 0.32, alpha=0.24)
    # soot: the candle has burned in it before; a brown-black film inside the shoulder and neck,
    # heaviest above the flame, in drifts
    soot_h = nb.mul(nb.ss(L.z, 0.24, 0.4), nb.inv(nb.mul(nb.ss(L.z, 0.44, 0.49), 0.6)))
    drift = nb.mr(L.noise(4.0, 12, detail=5, rough=0.65, distortion=0.4), 0.3, 0.7, 0.15, 1.0)
    soot = nb.mul(nb.mul(L.k(JAR_IN), soot_h), drift)
    C.paint(soot, hexc("#241F1B"), 0.6, alpha=0.62)
    # the cup: pressed aluminium, brushed by the press, gone straw-coloured where it got hot and
    # sooty on the wall the wax has burned down from
    cup = L.k(CUP)
    alu = nb.tint(hexc("#C9CCCE"), nb.mr(L.noise(60.0, 13, stretch=(1.0, 1.0, 0.08), detail=3), 0.3, 0.7, 0.88, 1.03))
    C.paint(cup, alu, nb.mr(L.noise(80.0, 14, stretch=(1.0, 1.0, 0.1), detail=3), 0.3, 0.7, 0.22, 0.36), 1.0)
    cz = TL_AT.z
    burnt = nb.mul(cup, nb.mul(nb.ss(L.z, cz + TL["wax"] + 0.012, cz + TL["wax"] + 0.002),
                               nb.ss(L.z, cz + TL["wax"], cz + TL["wax"] + 0.002)))
    C.paint(nb.mul(burnt, 0.85), hexc("#4A4038"), 0.55, 0.4)
    C.paint(nb.mul(cup, nb.mul(nb.ss(L.z, cz + 0.045, cz + 0.062), 0.35)), hexc("#C9B48A"))
    # the wax: white paraffin, waxy, the melt pool set glossy round the wick, specks of soot
    wax = L.k(WAX)
    dx, dy = nb.sub(L.x, TL_AT.x), nb.sub(L.y, TL_AT.y)
    rad = nb.pw(nb.add(nb.mul(dx, dx), nb.mul(dy, dy)), 0.5)
    C.paint(wax, nb.tint(hexc("#EEEAE1"), nb.mr(L.noise(9.0, 15, detail=3), 0.3, 0.7, 0.95, 1.02)), 0.55, 0.0)
    C.paint(nb.mul(wax, nb.ss(rad, TL["pool"], TL["pool"] * 0.6)), hexc("#E9E2D2"), 0.2)
    specks = nb.mul(nb.mul(wax, nb.ss(rad, 0.03, 0.006)), nb.ss(L.noise(90.0, 16, detail=2), 0.62, 0.7))
    C.paint(specks, hexc("#3A322C"), 0.6)
    # the wick: wax-stiffened cotton low down, charred black above, a grey ash bead at its tip
    wick = L.k(WICK)
    wz = cz + TL["wax"]
    C.paint(wick, hexc("#D8CFBE"), 0.7, 0.0)
    C.paint(nb.mul(wick, nb.ss(L.z, wz + 0.004, wz + 0.009)), hexc("#16130F"), 0.85)
    C.paint(nb.mul(wick, nb.ss(L.z, wz + TL["wick"]["up"] - 0.004, wz + TL["wick"]["up"])), hexc("#6E6A66"), 0.95)
    # the flame: blue and faint at its foot, a hot white-yellow body, orange drawn up to the tip
    fl = L.k(FLAME)
    u = nb.mul(nb.sub(L.z, FLAME_FOOT.z), 1.0 / TL["flame"]["h"])
    fcol = nb.mixc(nb.ss(u, 0.14, 0.24), hexc("#5470F0"), hexc("#FFF2CF"))
    fcol = nb.mixc(nb.ss(u, 0.45, 0.85), fcol, hexc("#FFA94A"))
    C.paint(fl, fcol, 0.5, 0.0)
    C.paint(fl, alpha=nb.mr(u, 0.0, 0.2, 0.3, 0.92))
    C.paint(nb.mul(fl, nb.ss(u, 0.75, 1.0)), alpha=0.5)
    C.lights(nb.mul(fl, nb.mr(u, 0.08, 0.22, 0.35, 1.0)))
    # the wire: galvanised steel, its zinc dulled, rusting where it was bent and in spots
    wire = L.k(WIRE)
    zinc = nb.tint(hexc("#A2A7A9"), nb.mr(L.noise(40.0, 17, detail=4), 0.3, 0.7, 0.8, 1.05))
    C.paint(wire, zinc, nb.mr(L.noise(25.0, 18, detail=3), 0.3, 0.7, 0.35, 0.55), 1.0)
    rust = nb.mul(wire, nb.ss(L.noise(18.0, 19, detail=5, rough=0.7), 0.6, 0.7))
    C.paint(rust, hexc("#7B4B2C"), 0.85, 0.0, 0.2)
    C.finish(f.dust, grime=0.35)
    return C.surface(bump_dist=0.0006, bump=0.4)


FLAME_MID = tuple(FLAME_FOOT + Vector((0.0, 0.0, TL["flame"]["h"] * 0.35)))
TEA_LIGHT = kit.Find(
    "TeaLight",
    [kit.Part("Jar", tj_jar, clear=True),
     kit.Part("Candle", tj_candle, tuple(TL_AT), "Jar"),
     kit.Part("Wire", tj_wire, tuple(BAIL_PIVOT), "Jar"),
     kit.Part("Bail", tj_bail, tuple(BAIL_PIVOT), "Jar", (1, 0, 0)),
     kit.Part("Flame", tj_flame, tuple(FLAME_FOOT), "Candle", (0, 1, 0), clear=True)],
    tj_look,
    lights=[
        # a candle's light: warm, low, all round; no shadows, so it shines out through the glass
        dict(kind="Point", part="Flame", at=FLAME_MID, kelvin=TL["kelvin"], brightness=0.9,
             range=9, shadows=False, preview_kind="POINT", preview_watts=2.6, preview_size=0.012),
    ],
    glow=dict(part="Flame", strength=3.0, tint=(255, 178, 98), preview=14.0),
    # found cold: the flame is scaled to nothing until it's lit
    lit={("Flame", "scale"): 1.0},
    motions={
        # struck: the wick catches small, sinks as it melts its wax, then the flame climbs too
        # tall, wavers and settles
        "Light": dict(duration=1.3, focus=FLAME_MID, distance=0.5, tracks=[
            ("Flame", "scale", [(0.0, 0.0), (0.06, 0.32, "Quad", "Out"), (0.18, 0.24),
                                (0.5, 1.0, "Quad", "Out")]),
            ("Flame", "stretch", [(0.0, 1.0), (0.18, 0.8), (0.52, 1.32, "Quad", "Out"),
                                  (0.76, 0.9), (0.98, 1.07), (1.2, 1.0)]),
            ("Flame", "turn", [(0.0, 0.0), (0.4, 0.0), (0.6, 3.5), (0.84, -2.4), (1.06, 1.1),
                               (1.3, 0.0)]),
            ("Flame", "glow", [(0.0, 0.0), (0.06, 0.45, "Quad", "Out"), (0.18, 0.32),
                               (0.5, 1.0, "Quad", "Out"), (1.3, 1.0)])]),
        # burning: played on a loop, the flame stretches and leans, and its light breathes
        "Flicker": dict(duration=2.0, focus=FLAME_MID, distance=0.5, tracks=[
            ("Flame", "scale", [(0.0, 1.0), (2.0, 1.0)]),
            ("Flame", "stretch", [(0.0, 1.0), (0.18, 1.07), (0.33, 0.95), (0.6, 1.04), (0.82, 0.97),
                                  (1.1, 1.09), (1.3, 0.94), (1.6, 1.03), (2.0, 1.0)]),
            ("Flame", "turn", [(0.0, 0.0), (0.25, 2.2), (0.55, -1.4), (0.9, 1.6), (1.25, -2.4),
                               (1.6, 0.8), (2.0, 0.0)]),
            ("Flame", "glow", [(0.0, 1.0), (0.2, 0.93), (0.35, 1.0), (0.62, 0.9), (0.85, 1.0),
                               (1.12, 0.88), (1.32, 0.97), (1.6, 0.92), (2.0, 1.0)])]),
        # run down: it gutters twice, shrinks and goes out
        "GoOut": dict(duration=1.6, focus=FLAME_MID, distance=0.5, tracks=[
            ("Flame", "scale", [(0.0, 1.0), (0.9, 0.85), (1.35, 0.0, "Quad", "In")]),
            ("Flame", "stretch", [(0.0, 1.0), (0.3, 0.68), (0.5, 1.04), (0.75, 0.55), (0.9, 0.82),
                                  (1.35, 0.5)]),
            ("Flame", "turn", [(0.0, 0.0), (0.3, -3.0), (0.55, 2.0), (0.8, -4.0), (1.1, 1.0),
                               (1.35, 0.0)]),
            ("Flame", "glow", [(0.0, 1.0), (0.3, 0.68), (0.5, 0.95), (0.75, 0.52), (0.9, 0.72),
                               (1.35, 0.0, "Quad", "In"), (1.6, 0.0)])]),
        # picked up by its handle: the bail swings up from where it lay, past upright a touch,
        # and settles
        "Lift": dict(duration=0.9, focus=(0.0, 0.0, 0.52), distance=1.0, tracks=[
            ("Bail", "turn", [(0.0, 0.0), (0.32, -TW["bail_rest"] + 6.0, "Quad", "InOut"),
                              (0.46, -TW["bail_rest"] - 3.0), (0.62, -TW["bail_rest"] + 1.2),
                              (0.78, -TW["bail_rest"])])]),
    },
    dust=TJ["dust"], seed=TJ["seed"],
)

# --- the bundle of glow sticks ------------------------------------------------------------------

(GS_TUBE, GS_CAP, GS_HOOK, GS_VIAL, GS_BAND) = range(25, 30)
GS, GB = K.GLOW_STICK, K.GLOW_BUNDLE
GS_R = GS["r"]
GS_Z = GS_R + GB["band"]["t"]      # the band under the bottom two lifts them off the floor
# each stick's axis (y, z): the top one, the front one, the back one, stacked as they lie
GS_AT = [(0.0, GS_Z + GS_R * math.sqrt(3.0)), (-GS_R, GS_Z), (GS_R, GS_Z)]
GS_X0 = -GS["length"] / 2


def gs_start(i):
    return Vector((GS_X0 + GB["sticks"][i]["slide"], GS_AT[i][0], GS_AT[i][1]))


def gs_frame(i, roll=True):
    """Stick i's own frame: Z along it from its cap end towards its hook (+X), rolled about
    itself so the hooks don't line up."""
    M = Matrix.Translation(gs_start(i)) @ Matrix.Rotation(math.radians(90.0), 4, "Y")
    return M @ Matrix.Rotation(math.radians(GB["sticks"][i]["roll"]), 4, "Z") if roll else M


def gs_split(prof, part, at, cut):
    """The piece of a profile below ("low") or above ("tip") `at`, with the cut point `cut`."""
    if part == "low":
        return [p for p in prof if p[1] < at] + [cut]
    if part == "tip":
        return [cut] + [p for p in prof if p[1] > at]
    return prof


def gs_tube_profile(hi):
    """The tube, cap end to seal: the plug cap (a touch wider, its end set in a hair), the step
    onto the tube, the tube, and the domed end the seal pinches out of."""
    r, c = GS_R, GS["cap"]
    n, rd = (3 if hi else 2), c["round"]
    prof = ([(0.0, 0.0012), (0.012, 0.0008), (c["r"] - rd, 0.0)]
            + fillet(c["r"] - rd, rd, rd, (-90, 0), n)[1:]
            + fillet(c["r"] - 0.0012, c["h"] - 0.0016, 0.0012, (0, 90), n)
            + [(r + 0.0002, c["h"] - 0.0004), (r, c["h"] + 0.0012)])
    sh, se = GS["shoulder"], GS["seal"]
    m = 8 if hi else 5
    prof += [(r * math.cos(math.radians(90 * k / m)), sh + (se - sh) * math.sin(math.radians(90 * k / m)))
             for k in range(m)] + [(0.0, se)]
    return prof


def gs_vial_profile(hi):
    """The ampoule: a round bottom, a straight run, and a shoulder drawn off to the little nub
    where the glass was sealed."""
    V = GS["vial"]
    rv, vb, vt = V["r"], V["z0"], V["z1"]
    m = 5 if hi else 3
    return ([(0.0, vb)] + [(rv * math.sin(math.radians(90 * k / m)), vb + rv - rv * math.cos(math.radians(90 * k / m)))
                           for k in range(1, m + 1)]
            + [(rv, vt - 0.014), (rv * 0.9, vt - 0.0075), (rv * 0.55, vt - 0.003), (0.0026, vt - 0.0008),
               (0.002, vt + 0.0025), (0.0015, vt + 0.0046), (0.0, vt + 0.0052)])


def gs_plate(outer, inner, t, closed, hi):
    """A flat plate t thick (local Y) between two loops of (x, z) points the same length: a ring
    when closed, an open C with its ends capped when not. The detailed one has its edges eased."""
    bm = bmesh.new()
    n = len(outer)

    def loop(pts, y):
        return [bm.verts.new((p[0], y, p[1])) for p in pts]

    ot, ob, it, ib = loop(outer, t / 2), loop(outer, -t / 2), loop(inner, t / 2), loop(inner, -t / 2)
    for i in range(n if closed else n - 1):
        j = (i + 1) % n
        bm.faces.new((ot[i], ot[j], it[j], it[i]))
        bm.faces.new((ob[i], ib[i], ib[j], ob[j]))
        bm.faces.new((ob[i], ob[j], ot[j], ot[i]))
        bm.faces.new((ib[i], it[i], it[j], ib[j]))
    if not closed:
        bm.faces.new((ot[0], it[0], ib[0], ob[0]))
        bm.faces.new((ot[-1], ob[-1], ib[-1], it[-1]))
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    if hi:
        sharp = [e for e in bm.edges if e.is_manifold and e.calc_face_angle(0.0) > math.radians(40)]
        bmesh.ops.bevel(bm, geom=sharp, offset=min(t * 0.22, 0.0016), segments=2, profile=0.5,
                        affect="EDGES", clamp_overlap=True)
    return bm


def gs_tab(n):
    """The flat tab the seal ends in: a rounded oblong round its hole."""
    T = GS["tab"]
    outer, inner = [], []
    for k in range(n):
        a = 2 * math.pi * k / n
        ca, sa = math.cos(a), math.sin(a)
        B = (T["z1"] - T["hole"]) if sa > 0 else (T["hole"] - T["z0"])
        q = (abs(ca / T["w"]) ** 4 + abs(sa / B) ** 4) ** -0.25
        outer.append((q * ca, T["hole"] + q * sa))
        inner.append((T["hole_r"] * ca, T["hole"] + T["hole_r"] * sa))
    return outer, inner


def gs_hook(n):
    """The open hook: a C round its centre, its gap facing back towards the tab."""
    H = GS["hook"]
    outer, inner = [], []
    for k in range(n + 1):
        a = math.radians(H["a0"] + (H["a1"] - H["a0"]) * k / n)
        outer.append((H["R"] * math.cos(a), H["at"] + H["R"] * math.sin(a)))
        inner.append((H["r"] * math.cos(a), H["at"] + H["r"] * math.sin(a)))
    return outer, inner


def gs_stick(i, part):
    """Stick i: its cap end ("low"), its hook end ("tip", from where it bends) or all of it
    ("whole"), each with its piece of the ampoule inside."""
    b = GS["bend"]

    def build(hi):
        s = Shape()
        # the ampoule first, so a renderer drawing in order lays the tube over it
        V = GS["vial"]
        vprof = gs_split(gs_vial_profile(hi), part, b, (V["r"], b))
        s.lathe(vprof, GS_VIAL, segs(hi, 10), gs_frame(i, False) @ Matrix.Translation((V["drop"], 0.0, 0.0)))
        prof = gs_split(gs_tube_profile(hi), part, b, (GS_R, b))
        h = GS["cap"]["h"]
        kinds = [GS_CAP if max(p[1], q[1]) <= h else GS_TUBE for p, q in zip(prof, prof[1:])]
        s.lathe(prof, GS_TUBE, segs(hi, 16), gs_frame(i), kinds=kinds)
        if part != "low":
            n = 48 if hi else 20
            for (o, inn), closed, t in ((gs_tab(n), True, GS["tab"]["t"]),
                                        (gs_hook(n // 2), False, GS["hook"]["t"])):
                bm = gs_plate(o, inn, t, closed, hi)
                s.merge(bm, GS_HOOK, gs_frame(i))
                bm.free()
        return s

    return build


def gs_band(hi):
    """The rubber band: a flat ribbon stretched round the three, tight to each stick and
    straight between them, its edges rounded."""
    s = Shape()
    B = GB["band"]
    t, w = B["t"], B["w"]
    x0 = GS_X0 + B["at"] - w / 2
    x1 = x0 + w
    n = 12 if hi else 6
    # round the back stick, the top one and the front one: anticlockwise seen from +X
    arcs = [(GS_AT[2], -30.0), (GS_AT[0], 90.0), (GS_AT[1], 210.0)]
    prof = [(0.0006, x0), (0.55 * t, x0 + 0.0004), (0.9 * t, x0 + 0.0022), (t, x0 + 0.005),
            (t, x1 - 0.005), (0.9 * t, x1 - 0.0022), (0.55 * t, x1 - 0.0004), (0.0006, x1)]
    rings = []
    for d, x in prof:
        ring = []
        for (y, z), a in arcs:
            for k in range(n + 1):
                ang = math.radians(a - 60 + 120 * k / n)
                ring.append((y + (GS_R + d) * math.cos(ang), z + (GS_R + d) * math.sin(ang), x))
        rings.append(ring)
    # loft's own frame: its X our Y, its Y our Z, its Z (up the rings) along the sticks
    M = Matrix(((0, 0, 1, 0), (1, 0, 0, 0), (0, 1, 0, 0), (0, 0, 0, 1)))
    s.loft(rings, GS_BAND, M)
    return s


def gs_look(L, f):
    nb = L.nb
    tube, cap, hook, vial, band = (L.k(GS_TUBE), L.k(GS_CAP), L.k(GS_HOOK), L.k(GS_VIAL),
                                   L.k(GS_BAND))
    # frosted polyethylene: the plug caps and the hook, milky, hardly see-through
    C = Coat(L, hexc("#D3D8CF"), 0.46, 0.0)
    C.paint(nb.add(cap, hook, clamp=True), alpha=0.78)
    # the tube: clear polyethylene, the liquid in it a pale lime before it's cracked
    C.paint(tube, hexc("#B5D23E"), 0.1, alpha=0.42)
    # the air bubble lying along the top of the liquid: paler and clearer
    along = nb.mul(nb.ss(L.x, 0.02, 0.035), nb.inv(nb.ss(L.x, 0.08, 0.1)))
    C.paint(nb.mul(nb.mul(tube, nb.ss(L.nz, 0.82, 0.96)), along), hexc("#E6EFC0"), alpha=0.36)
    # handled and kept in a drawer: fine scuffs along the tube, duller and a little milky
    scuff = nb.mul(tube, nb.ss(L.noise(26.0, 61, stretch=(0.06, 1.0, 1.0), detail=4, rough=0.6), 0.56, 0.68))
    C.paint(nb.mul(scuff, 0.8), hexc("#D7E1A2"), 0.36, alpha=0.6)
    # the ampoule: thin glass in the liquid, seen mostly by its glints
    C.paint(vial, hexc("#DCE6CF"), 0.05, alpha=0.55)
    # the band: natural rubber gone tan and perished, a powdery bloom where it faced up, and
    # fine cracks across it where it's stretched
    rub = nb.tint(hexc("#94683F"), nb.mr(L.noise(25.0, 62, detail=4), 0.3, 0.7, 0.85, 1.08))
    C.paint(band, rub, 0.8, 0.0)
    C.paint(nb.mul(band, nb.mul(L.up, nb.ss(L.noise(14.0, 63, detail=3), 0.45, 0.65))), hexc("#B59C80"), 0.92)
    cracks = nb.mul(band, nb.ss(L.noise(60.0, 64, stretch=(0.15, 1.0, 1.0), detail=2), 0.64, 0.69))
    C.paint(nb.mul(cracks, 0.85), hexc("#3E2C1E"), 0.9)
    # cracked: the liquid glows, the ampoule in it; the caps and the hook pass a little of it
    C.lights(nb.add(nb.add(tube, vial, clamp=True), nb.add(nb.mul(cap, 0.35), nb.mul(hook, 0.12)), clamp=True))
    C.finish(f.dust, grime=0.3)
    return C.surface(bump_dist=0.0004, bump=0.3)


GS_TOP = GS_AT[0][1]
GS_BEND = tuple(gs_start(0) + Vector((GS["bend"], 0.0, -GS_R)))   # its underside, where it kinks
GS_MID = tuple(gs_start(0) + Vector((GS["bend"], 0.0, 0.0)))
GLOW_STICKS = kit.Find(
    "GlowSticks",
    [kit.Part("Band", gs_band),
     kit.Part("Stick1", gs_stick(0, "low"), tuple(gs_start(0)), "Band", clear=True),
     kit.Part("Stick1Tip", gs_stick(0, "tip"), GS_BEND, "Stick1", (0, -1, 0), clear=True),
     kit.Part("Stick2", gs_stick(1, "whole"), tuple(gs_start(1)), "Band", clear=True),
     kit.Part("Stick3", gs_stick(2, "whole"), tuple(gs_start(2)), "Band", clear=True)],
    gs_look,
    lights=[
        # a lightstick's light: a soft green all round, weak; it shines out through its tube
        dict(kind="Point", part="Stick1", at=GS_MID, rgb=GB["rgb"], brightness=0.7, range=7,
             shadows=False, preview_kind="POINT", preview_watts=1.4, preview_size=0.03),
    ],
    glow=dict(part="Stick1", strength=2.0, tint=GB["rgb"], preview=4.5),
    # cracked, both halves of the top stick glow
    lit={("Stick1Tip", "glow"): 1.0},
    motions={
        # cracked: a grip, then the top stick bent against its stiff plastic until the ampoule
        # snaps and it gives all at once; let go, it drops back onto the others and bounces, and
        # the light comes up from the crack as the liquids mix
        "Crack": dict(duration=1.8, focus=(0.06, 0.0, 0.07), distance=0.62, tracks=[
            ("Stick1Tip", "turn", [(0.0, 0.0), (0.12, 3.0, "Quad", "Out"), (0.22, 2.0),
                                   (0.5, GS["crack"] - 7.0, "Quad", "In"), (0.55, GS["crack"], "Quad", "Out"),
                                   (0.7, 0.0, "Quad", "In"), (0.79, 4.5, "Quad", "Out"),
                                   (0.88, 0.0, "Quad", "In"), (0.94, 1.2, "Quad", "Out"),
                                   (1.0, 0.0, "Quad", "In")]),
            ("Stick1Tip", "glow", [(0.0, 0.0), (0.55, 0.0), (0.6, 0.45, "Quad", "Out"), (0.76, 0.3),
                                   (1.5, 1.0), (1.8, 1.0)]),
            ("Stick1", "glow", [(0.0, 0.0), (0.55, 0.0), (0.62, 0.4, "Quad", "Out"), (0.8, 0.28),
                                (1.56, 1.0), (1.8, 1.0)])]),
    },
    # thin tubes cut into many small islands: asked for more so the packed set lands near 300
    dust=GB["dust"], seed=GB["seed"], texels=500,
)

# --- the string fairy lights --------------------------------------------------------------------

(FL_BOX, FL_METAL, FL_WRAP1, FL_WRAP2, FL_BAND1, FL_BAND2, FL_KNOB, FL_GROMMET, FL_WIRE,
 FL_BEAD) = range(30, 40)
FL, FB = K.FAIRY, K.FAIRY["box"]
FL_YAW = math.radians(FB["yaw"])
# the box's own frame: X along it (its cable end to -X), on the floor
FL_BOXM = Matrix.Translation((FB["at"][0], FB["at"][1], 0.0)) @ Matrix.Rotation(FL_YAW, 4, "Z")
FL_EXIT = FL_BOXM @ Vector((-FB["l"] / 2 - 0.012, FL["exit"][0], FL["exit"][1]))


def fl_coil(step):
    """The wire's path from its far end round the loose coil (each loop lying a little in or
    out of the last, wobbling as wire does, riding over the others), then across to the box."""
    c, rw = FL["coil"], FL["wire"]["r"]
    cx, cy = c["at"]
    a0, total = math.radians(c["start"]), 2 * math.pi * c["loops"]
    n = int(total * c["R"] / step)
    pts = []
    for i in range(n + 1):
        a = a0 + total * i / n
        R = c["R"] * (1.0 + c["wander"] * (0.7 * math.sin(a * 0.37 + 1.3) + 0.3 * math.sin(a * 1.13 + 0.4))
                      + 0.04 * math.sin(2 * a + 2.0))
        z = rw + 0.0035 * (1 + math.sin(a * 0.61 + 0.9)) + 0.0022 * (1 + math.sin(a * 1.7))
        pts.append(Vector((cx + R * math.cos(a), cy + R * c["oval"] * math.sin(a), z)))
    coil = len(pts)
    # the lead: off the coil along its last heading, down onto the floor, and up into the box
    t = (pts[-1] - pts[-2]).normalized()
    back = (FL_BOXM.to_3x3() @ Vector((-1.0, 0.0, 0.0)))
    lead = [pts[-1], pts[-1] + t * 0.07 + Vector((0, 0, -0.003)),
            (pts[-1] + FL_EXIT) / 2 + Vector((0.0, -0.03, 0.0)),
            FL_EXIT + back * 0.07 + Vector((0.0, 0.0, -FL_EXIT.z + rw + 0.002)),
            FL_EXIT + back * 0.02 + Vector((0.0, 0.0, -0.012)), FL_EXIT]
    lead = [Vector((p.x, p.y, max(p.z, rw))) for p in lead]
    sm = [Vector(p) for p in spline(lead, max(3, int(0.12 / step)))]
    return pts + sm[1:], coil


def fl_beads(pts, coil):
    """Where each LED sits on the coil, measured along the wire from its far end."""
    B = FL["bead"]
    out, run, nxt = [], 0.0, B["first"]
    for i in range(1, coil):
        d = (pts[i] - pts[i - 1]).length
        while run + d >= nxt:
            u = (nxt - run) / d
            out.append((pts[i - 1].lerp(pts[i], u), (pts[i] - pts[i - 1]).normalized()))
            nxt += B["every"]
        run += d
    return out


def fl_string(hi):
    """The string: the copper wire and its LEDs, each a drop of clear resin on the wire."""
    s = Shape()
    W, B = FL["wire"], FL["bead"]
    pts, coil = fl_coil(W["step"] / (2 if hi else 1))
    # in pieces: one strip ten studs long won't pack into a square
    k = 32 if hi else 16
    for i in range(0, len(pts) - 1, k):
        s.tube(pts[i:i + k + 1], W["r"], FL_WIRE, 6 if hi else 4, caps=False)
    h, r = B["len"] / 2, B["r"]
    n = 3 if hi else 1
    prof = ([(0.0, -h), (r * 0.45, -h + 0.0012)] + [(r * math.sin(math.radians(a)), -h * 0.62 * math.cos(math.radians(a)))
                                                    for a in range(30, 151, 120 // (2 * n + 1))][:]
            + [(r * 0.45, h - 0.0012), (0.0, h)])
    # placed along the game mesh's path, so both versions put each LED in the same spot
    for p, t in fl_beads(*fl_coil(W["step"])):
        p = Vector((p.x, p.y, max(p.z, r)))
        M = Matrix.Translation(p) @ Vector((0, 0, 1)).rotation_difference(t).to_matrix().to_4x4()
        s.lathe(prof, FL_BEAD, segs(hi, 6), M)
    return s


def fl_battery(hi, k):
    """One AA cell: a flat negative end, the printed wrap rolled over both shoulders, a band of
    colour near the top, the positive nub."""
    T = FL["batt"]
    r, L, (nr, nh) = T["r"], T["l"], T["nub"]
    wrap, band = (FL_WRAP2, FL_BAND2) if k == 1 else (FL_WRAP1, FL_BAND1)
    n = 3 if hi else 1
    pts = [((0.0, 0.0), None), ((r - 0.004, 0.0), FL_METAL)]
    pts += [(p, wrap) for p in fillet(r - 0.003, 0.003, 0.003, (-90, 0), n)[1:]]
    pts += [((r, L * 0.66), wrap), ((r, L - 0.004), band)]
    pts += [(p, wrap) for p in fillet(r - 0.004, L - 0.004, 0.004, (0, 90), n)[1:]]
    pts += [((nr + 0.0018, L), FL_METAL), ((nr, L + 0.0012), FL_METAL), ((nr, L + nh), FL_METAL),
            ((0.0, L + nh), FL_METAL)]
    return [p for p, _ in pts], [kk for _, kk in pts[1:]]


def fl_box(hi):
    """The 3 x AA box: three cells inside (one not matching), their contacts, and the frosted
    box over them, with the grommet the wire leaves by. The detailed one has the lid's grip."""
    s = Shape()
    T = FL["batt"]
    l, w, h = FB["l"], FB["w"], FB["h"]
    span = T["l"] + T["nub"][1]
    # the cells first, so a renderer drawing in order lays the frosted box over them
    for k, y in enumerate(T["y"]):
        prof, kinds = fl_battery(hi, k)
        flip = -1.0 if k % 2 else 1.0
        M = (FL_BOXM @ Matrix.Translation((-span / 2 * flip, y, T["z"]))
             @ Matrix.Rotation(math.radians(90.0 * flip), 4, "Y"))
        s.lathe(prof, FL_METAL, segs(hi, 14), M, kinds=kinds)
        for sx in (-1.0, 1.0):
            x = sx * (span / 2 + 0.003)
            s.box((x - 0.0015, y - 0.018, T["z"] - 0.018), (x + 0.0015, y + 0.018, T["z"] + 0.018),
                  FL_METAL, M=FL_BOXM)
    s.box((-l / 2, -w / 2, 0.0), (l / 2, w / 2, h), FL_BOX, chamfer=FB["round"], segs=4 if hi else 2,
          M=FL_BOXM)
    if hi:
        # the lid's grip: ribs across its far end
        for i in range(6):
            x = l / 2 - 0.022 - i * 0.0068
            s.box((x - 0.0016, -w * 0.3, h - 0.0004), (x + 0.0016, w * 0.3, h + 0.0013), FL_BOX,
                  chamfer=0.0005, segs=1, M=FL_BOXM)
    ey, ez = FL["exit"]
    s.cylinder((-l / 2 + 0.002, ey, ez), (-l / 2 - 0.012, ey, ez), 0.0072, FL_GROMMET,
               segs(hi, 10), M=FL_BOXM)
    return s


def fl_switch(hi):
    """The slide switch's knob, standing out of its slot in the top, ridged for a thumb."""
    s = Shape()
    S, h = FL["switch"], FB["h"]
    (x, y), (kx, ky, kz) = S["at"], S["knob"]
    s.box((x - kx / 2, y - ky / 2, h - 0.004), (x + kx / 2, y + ky / 2, h + kz), FL_KNOB,
          chamfer=0.0022, segs=3 if hi else 1, M=FL_BOXM)
    if hi:
        for i in range(-2, 3):
            xx = x + i * 0.0041
            s.box((xx - 0.001, y - ky / 2 + 0.0025, h + kz - 0.0004), (xx + 0.001, y + ky / 2 - 0.0025, h + kz + 0.0013),
                  FL_KNOB, chamfer=0.0004, segs=1, M=FL_BOXM)
    return s


def fl_look(L, f):
    nb = L.nb
    S, l, w = FL["switch"], FB["l"], FB["w"]
    # the box's own coordinates (bx along it, by across)
    c, sn = math.cos(FL_YAW), math.sin(FL_YAW)
    dx, dy = nb.sub(L.x, FB["at"][0]), nb.sub(L.y, FB["at"][1])
    bx = nb.add(nb.mul(dx, c), nb.mul(dy, sn))
    by = nb.sub(nb.mul(dy, c), nb.mul(dx, sn))
    box = L.k(FL_BOX)
    top = nb.mul(box, L.up)
    # frosted polypropylene: milky, the cells showing through soft, whiter where it's thick
    C = Coat(L, hexc("#C9D0D2"), 0.4, 0.0)
    C.paint(box, alpha=0.3)
    C.paint(nb.mul(box, L.edge(0.006)), hexc("#DDE2E3"), alpha=0.62)
    # the lid's seams: across where it starts, and down both long sides
    across = nb.band(bx, FL["lid"] - 0.0011, FL["lid"] + 0.0011, 0.0004)
    sides = nb.mul(nb.band(nb.absf(by), w / 2 - 0.0102, w / 2 - 0.0082, 0.0004), nb.ss(bx, FL["lid"], FL["lid"] + 0.002))
    C.paint(nb.mul(top, nb.add(across, sides, clamp=True)), hexc("#5C6466"), 0.6, alpha=0.9)
    # the switch's slot, dark, the length the knob slides
    x0, y0 = S["at"]
    kx, ky = S["knob"][0], S["knob"][1]
    slot = nb.mul(nb.band(bx, x0 - kx / 2 - S["travel"] - 0.0025, x0 + kx / 2 + 0.0025, 0.0006),
                  nb.band(by, y0 - ky / 2 - 0.0025, y0 + ky / 2 + 0.0025, 0.0006))
    C.paint(nb.mul(top, slot), hexc("#1E2022"), 0.7, alpha=0.97)
    # the cells: two of one make, deep green with a gold band, one odd one, black and orange;
    # nickel-plated ends and contacts
    C.paint(L.k(FL_WRAP1), hexc("#1E4636"), 0.32, 0.0, alpha=1.0)
    C.paint(L.k(FL_BAND1), hexc("#C2953A"), 0.3, 0.6, alpha=1.0)
    C.paint(L.k(FL_WRAP2), hexc("#1B1B1D"), 0.34, 0.0, alpha=1.0)
    C.paint(L.k(FL_BAND2), hexc("#D0601E"), 0.36, 0.0, alpha=1.0)
    C.paint(L.k(FL_METAL), hexc("#C4C6C6"), 0.26, 1.0, alpha=1.0)
    # the knob: black ABS, its ridges worn paler by thumbs; the grommet: black rubber
    knob = L.k(FL_KNOB)
    C.paint(knob, hexc("#1C1C1E"), 0.55, 0.0, alpha=1.0)
    C.paint(nb.mul(knob, nb.mul(L.edge(0.002), 0.6)), hexc("#4A4A4C"), 0.45)
    C.paint(L.k(FL_GROMMET), hexc("#202020"), 0.78, 0.0, alpha=1.0)
    # the wire: enamelled copper, bright where it's bent and rubbed, tarnished brown in places
    wire = L.k(FL_WIRE)
    C.paint(wire, hexc("#B8683C"), 0.3, 1.0, alpha=1.0)
    tarnish = nb.mul(wire, nb.ss(L.noise(9.0, 71, detail=4, rough=0.6), 0.5, 0.66))
    C.paint(nb.mul(tarnish, 0.75), hexc("#6A3F27"), 0.5, 0.8)
    # the LEDs: clear resin drops, the yellow phosphor of the chip showing on top
    bead = L.k(FL_BEAD)
    C.paint(bead, hexc("#EEE9D8"), 0.12, 0.0, alpha=1.0)
    chip = nb.mul(bead, nb.ss(L.nz, 0.78, 0.97))
    C.paint(chip, hexc("#EFC24A"), 0.15)
    C.lights(nb.mx(nb.mul(bead, 0.75), chip))
    C.finish(f.dust, grime=0.3)
    return C.surface(bump_dist=0.0004, bump=0.3)


FL_T = FL["switch"]["travel"]
FL_SW = tuple(FL_BOXM @ Vector((FL["switch"]["at"][0], FL["switch"]["at"][1], FB["h"])))
FL_GLOW = (FL["coil"]["at"][0], FL["coil"]["at"][1], 0.07)
FAIRY_LIGHTS = kit.Find(
    "FairyLights",
    [kit.Part("Box", fl_box, clear=True),
     kit.Part("Switch", fl_switch, FL_SW, "Box", tuple(FL_BOXM.to_3x3() @ Vector((-1.0, 0.0, 0.0)))),
     kit.Part("String", fl_string, FL_GLOW, "Box")],
    fl_look,
    lights=[
        # twenty warm LEDs: a faint warm wash round the coil, no shadows (they're everywhere)
        dict(kind="Point", part="String", at=FL_GLOW, kelvin=FL["kelvin"], brightness=0.6, range=9,
             shadows=False, preview_kind="POINT", preview_watts=1.2, preview_size=0.25),
    ],
    glow=dict(part="String", strength=2.5, tint=(255, 184, 116), preview=6.0),
    lit={("Switch", "move"): FL_T},
    motions={
        # switched on: the thumb pushes against the detent, it clicks over, and the LEDs come on
        # at once, stutter once on a tired battery's contact, and hold
        "SwitchOn": dict(duration=0.7, focus=FL_SW, distance=0.42, tracks=[
            ("Switch", "move", [(0.0, 0.0), (0.09, FL_T * 0.2, "Quad", "In"),
                                (0.13, FL_T * 1.06, "Quad", "Out"), (0.19, FL_T)]),
            ("String", "glow", [(0.0, 0.0), (0.13, 0.0), (0.14, 1.0, "Linear"), (0.19, 0.3, "Linear"),
                                (0.22, 1.0, "Linear"), (0.3, 0.86), (0.42, 1.0), (0.7, 1.0)])]),
        # switched off: clicked back, and they're out
        "SwitchOff": dict(duration=0.5, focus=(0.0, 0.0, 0.03), distance=0.9, tracks=[
            ("Switch", "move", [(0.0, FL_T), (0.08, FL_T * 0.8, "Quad", "In"),
                                (0.12, -0.0008, "Quad", "Out"), (0.18, 0.0)]),
            ("String", "glow", [(0.0, 1.0), (0.12, 1.0), (0.15, 0.0, "Quad", "Out"), (0.5, 0.0)])]),
    },
    # many thin wire strips: asked for more so the packed set lands near 300
    dust=FL["dust"], seed=FL["seed"], texels=500,
)

# --- the camping lantern ------------------------------------------------------------------------

(LN_ENAMEL, LN_BLACK, LN_BARS, LN_GLASS, LN_GLASS_IN, LN_DIFF, LN_CHROME, LN_GRIP, LN_ALU,
 LN_POINTER, LN_BOTTOM) = range(40, 51)
LN = K.LANTERN
LB, LK, LH = LN["bail"], LN["knob"], LN["hood"]
LN_BAIL_PIVOT = Vector((0.0, 0.0, LB["z"]))
LN_KNOB_AT = Vector((0.0, -LN["band"]["r"], LK["z"]))
# the knob's own frame: its face out to -Y, its local +Y up
LN_KNOB_M = Matrix.Translation(LN_KNOB_AT) @ Matrix.Rotation(math.radians(90), 4, "X")
LN_GLOW_AT = (0.0, 0.0, (LN["diffuser"]["z0"] + LN["diffuser"]["z1"]) / 2)


def ln_runs(*runs):
    """A lathe profile from runs of (points, kind): a run's spans take its kind, and so does the
    span joining it to the run before."""
    prof, kinds = [], []
    for pts, k in runs:
        for p in pts:
            if prof:
                kinds.append(k)
            prof.append(p)
    return prof, kinds


def ln_ring(r_of, z, n):
    """One loft ring, anticlockwise from above; r_of(a) gives its radius at angle a."""
    return [(r_of(2 * math.pi * j / n) * math.cos(2 * math.pi * j / n),
             r_of(2 * math.pi * j / n) * math.sin(2 * math.pi * j / n), z) for j in range(n)]


def ln_flutes(count, depth, power=1.5):
    """Rounded flutes round a knurled edge: how far out a point at angle a stands."""
    return lambda a: depth * (0.5 + 0.5 * math.cos(count * a)) ** power


def ln_hood_profile(hi):
    """The hood: its underside out from the top ring, round the rolled rim, up its top to the cap."""
    t, h = LN["top"], LH
    f = 3 if hi else 1
    c = (h["rim"] - h["bead"], h["z_rim"])
    under = [(t["r"] - 0.006, t["z1"]), (c[0] - 0.004, c[1] - 0.0048)]
    rim = fillet(c[0], c[1], h["bead"], (-115, 110), 6 * f)
    end = rim[-1]
    m = 10 if hi else 3
    top = [(end[0] + (h["r_top"] - end[0]) * i / m, end[1] + (h["z_top"] - end[1]) * i / m)
           for i in range(1, m + 1)]
    return under + rim + top + [(h["r_top"] - 0.007, h["z_top"] + 0.004)]


def ln_hood_z(r):
    """Height of the hood's top surface at radius r."""
    prof = ln_hood_profile(False)
    top = prof[-5:-1]
    (r0, z0), (r1, z1) = top[0], top[-1]
    return z0 + (z1 - z0) * (r - r0) / (r1 - r0)


def ln_body(hi):
    s = Shape()
    n = segs(hi, 40)
    f = 3 if hi else 1
    b, nk, se, t, g = LN["band"], LN["neck"], LN["seat"], LN["top"], LN["globe"]
    bd = b["bead"]
    foot = LN["foot"]
    prof, kinds = ln_runs(
        (foot[:2], LN_BOTTOM),
        (foot[2:-1], LN_ENAMEL),
        (fillet(b["r"], b["z0"] + bd, bd, (-90, 90), 3 * f)
         + fillet(b["r"], b["z1"] - bd, bd, (-90, 90), 3 * f)
         + [(nk["r"] + 0.004, b["z1"])], LN_ENAMEL),
        ([(nk["r"], b["z1"] + 0.003), (nk["r"], nk["z1"])], LN_BLACK),
        ([(se["r"] - 0.004, se["z0"])] + fillet(se["r"] - 0.004, se["z0"] + 0.004, 0.004, (-90, 0), 2 * f)
         + fillet(se["r"] - 0.004, se["z1"] - 0.004, 0.004, (0, 90), 2 * f)
         + [(g["r"] + 0.004, se["z1"]), (g["r"] + 0.002, se["z1"] - 0.006),
            (g["r"] - g["wall"] - 0.003, se["z1"] - 0.006), (0.0, se["z1"] - 0.004)], LN_BLACK),
    )
    s.lathe(prof, LN_ENAMEL, n, kinds=kinds)
    # the top ring, its underside the ceiling seen up through the globe
    ring = ([(0.0, t["z0"] + 0.004), (g["r"] - g["wall"] - 0.003, t["z0"] + 0.004),
             (g["r"] - g["wall"] - 0.001, t["z0"])]
            + fillet(t["r"] - 0.004, t["z0"] + 0.004, 0.004, (-90, 0), 2 * f)
            + fillet(t["r"] - 0.004, t["z1"] - 0.004, 0.004, (0, 90), 2 * f)
            + [(t["r"] - 0.012, t["z1"])])
    s.lathe(ring, LN_BLACK, n)
    # the diffuser's collars: the socket it stands in and the driver's cup it hangs from
    d = LN["diffuser"]
    for z0, z1 in ((se["z1"] - 0.006, d["z0"] + 0.004), (d["z1"] - 0.004, t["z0"] + 0.004)):
        s.lathe([(0.0, z0), (0.058, z0), (0.06, z0 + 0.003), (0.06, z1 - 0.003), (0.058, z1), (0.0, z1)],
                LN_BLACK, segs(hi, 24))
    # the guard: six bars bowed a little outward, each sunk into both rings
    bs = LN["bars"]
    m = 12 if hi else 5
    for i in range(bs["n"]):
        a = math.radians(bs["start"] + 360.0 * i / bs["n"])
        za, zb = se["z1"] - 0.004, t["z0"] + 0.004
        pts = []
        for k in range(m + 1):
            u = k / m
            R = bs["R"] + 0.006 * math.sin(math.pi * u)
            pts.append((R * math.cos(a), R * math.sin(a), za + (zb - za) * u))
        s.tube(pts, bs["r"], LN_BARS, 16 if hi else 6)
    # the hood: pressed ribs on its top in the detailed one
    hp = ln_hood_profile(hi)
    if hi:
        N = 288
        rib = LH["ribs"]
        n_rim = len(hp) - 11

        def ring_at(i, r, z):
            pts = []
            for j in range(N):
                a = 2 * math.pi * j / N
                zz = z
                if i >= n_rim:
                    # each rib a rounded ridge 8 mm wide, fading out at both ends
                    off = (a - math.pi / rib) % (2 * math.pi / rib)
                    dd = min(off, 2 * math.pi / rib - off) * r
                    fade = (min(1.0, max(0.0, (r - 0.088) / 0.02))
                            * min(1.0, max(0.0, (0.2 - r) / 0.012)))
                    zz += LH["rib"] * fade * math.exp(-(dd / 0.0085) ** 2)
                pts.append((r * math.cos(a), r * math.sin(a), zz))
            return pts

        s.loft([ring_at(i, r, z) for i, (r, z) in enumerate(hp)], LN_ENAMEL)
    else:
        s.lathe(hp, LN_ENAMEL, n)
    # the lugs the bail hooks through: tabs pressed up out of the hood
    for sx in (-1, 1):
        x = sx * LB["lug_x"]
        zb = ln_hood_z(LB["lug_x"] + 0.004) - 0.004
        s.box((x - 0.0035, -0.014, zb), (x + 0.0035, 0.014, LB["z"] + 0.012), LN_ENAMEL, 0.002,
              2 if hi else 1)
    # the cap: knurled steel, domed on top
    c = LN["cap"]
    cap = ([(c["r"] + 0.003, c["z0"]), (c["r"], c["z0"] + 0.004), (c["r"], c["z0"] + 0.008),
            (c["r"], c["z1"] - 0.008)]
           + fillet(c["r"] - 0.006, c["z1"] - 0.006, 0.006, (0, 90), 2 * f)[1:]
           + [(c["r"] * 0.6, c["z1"] + c["dome"] * 0.7), (c["r"] * 0.3, c["z1"] + c["dome"] * 0.95),
              (0.0, c["z1"] + c["dome"])])
    if hi:
        N = c["ribs"] * 8
        fl = ln_flutes(c["ribs"], c["rib"])
        rings = []
        for i, (r, z) in enumerate(cap):
            if r <= 1e-6:
                rings.append([(0.0, 0.0, z)])
            elif 2 <= i <= 3:
                rings.append(ln_ring(lambda a, r=r: r + fl(a), z, N))
            else:
                rings.append(ln_ring(lambda a, r=r: r, z, N))
        s.loft(rings, LN_ALU)
    else:
        s.lathe(cap, LN_ALU, segs(hi, 28))
    # the dimmer's chrome bezel, sunk into the band's curve
    s.lathe([(LK["r"] + 0.002, -0.008), (LK["bezel"], -0.008), (LK["bezel"], 0.002)]
            + fillet(LK["bezel"] - 0.004, 0.002, 0.004, (0, 90), 2 * f)
            + [(LK["r"] + 0.002, 0.006), (LK["r"] + 0.002, -0.008)],
            LN_CHROME, segs(hi, 28), LN_KNOB_M)
    return s


def ln_globe(hi):
    """The globe: one clear glass tube, its ends hidden in the rings."""
    s = Shape()
    g = LN["globe"]
    r, w = g["r"], g["wall"]
    prof = ([(r, g["z0"]), (r, g["z1"] - 0.006)] + fillet(r - w / 2, g["z1"] - 0.006, w / 2, (0, 180), 4)[1:]
            + [(r - w, g["z0"])])
    kinds = [LN_GLASS] * 5 + [LN_GLASS_IN]
    s.lathe(prof, LN_GLASS, segs(hi, 40), kinds=kinds)
    return s


def ln_diffuser(hi):
    """The frosted diffuser: an hourglass ringed with ribs, the LEDs hidden in it."""
    s = Shape()
    d = LN["diffuser"]
    z0, z1 = d["z0"], d["z1"]
    m = d["ribs"] * 8 if hi else 14
    prof = [(0.0, z0), (0.05, z0), (d["r_end"] - 0.006, z0 + 0.002)]
    for i in range(m + 1):
        u = i / m
        r = d["r_waist"] + (d["r_end"] - d["r_waist"]) * (2 * u - 1) ** 2
        if hi:
            r += d["rib"] * (0.5 - 0.5 * math.cos(2 * math.pi * d["ribs"] * u))
        prof.append((r, z0 + 0.006 + (z1 - z0 - 0.012) * u))
    prof += [(d["r_end"] - 0.006, z1 - 0.002), (0.05, z1), (0.0, z1)]
    s.lathe(prof, LN_DIFF, segs(hi, 24) if not hi else 64)
    return s


def ln_knob(hi):
    """The dimmer knob: knurled round its edge, a raised pointer across its face."""
    s = Shape()
    r, dp = LK["r"], LK["depth"]
    f = 3 if hi else 1
    prof = ([(0.0, 0.004), (r - 0.002, 0.004), (r, 0.007), (r, dp - 0.006)]
            + fillet(r - 0.005, dp - 0.005, 0.005, (0, 90), 2 * f)[1:]
            + [(r * 0.5, dp + 0.0015), (0.0, dp + 0.002)])
    if hi:
        N = 24 * 8
        fl = ln_flutes(24, 0.0018)
        rings = []
        for i, (rr, z) in enumerate(prof):
            if rr <= 1e-6:
                rings.append([(0.0, 0.0, z)])
            elif 2 <= i <= 3:
                rings.append(ln_ring(lambda a, rr=rr: rr + fl(a), z, N))
            else:
                rings.append(ln_ring(lambda a, rr=rr: rr, z, N))
        s.loft(rings, LN_ALU, LN_KNOB_M)
    else:
        s.lathe(prof, LN_ALU, segs(hi, 24), LN_KNOB_M)
    # the pointer: a ridge from the middle out to the edge, at seven o'clock when off
    a = math.radians(-LK["off"])
    P = LN_KNOB_M @ Matrix.Rotation(-a, 4, "Z")
    s.box((-0.0028, -0.002, dp - 0.002), (0.0028, r - 0.004, dp + 0.004), LN_POINTER, 0.0012,
          2 if hi else 1, P)
    return s


def ln_bail(hi):
    """The bail: hooked through the lugs, up the arms, round over the top; the rubber grip on the
    arc. Built upright and laid back to where it fell on the hood's rim."""
    s = Shape()
    z, x, bend, arms = LB["z"], LB["x"], 0.014, LB["arms"]
    side = [(LB["lug_x"] - 0.012, 0.0, z), (x - bend, 0.0, z)]
    side += [(x - bend + bend * math.sin(math.radians(a)), 0.0, z + bend - bend * math.cos(math.radians(a)))
             for a in range(15, 91, 15)]
    side += [(x, 0.0, z + arms)]
    top = [(x * math.cos(math.radians(a)), 0.0, z + arms + x * math.sin(math.radians(a)))
           for a in range(0, 181, 4 if hi else 9)][1:-1]
    left = [(-p[0], p[1], p[2]) for p in reversed(side)]
    M = (Matrix.Translation(LN_BAIL_PIVOT) @ Matrix.Rotation(math.radians(LN["bail_rest"]), 4, "X")
         @ Matrix.Translation(-LN_BAIL_PIVOT))
    s.tube(side + top + left, LB["r"], LN_CHROME, 24 if hi else 8, M)
    # the grip: a rubber sleeve round the top of the arc, its ends rounded off
    g = LB["grip"]
    m = 30 if hi else 12
    pts, radii = [], []
    for i in range(m + 1):
        a = math.radians(90 - g + 2 * g * i / m)
        pts.append((x * math.cos(a), 0.0, z + arms + x * math.sin(a)))
        e = min(i, m - i) / m * 2 * g          # degrees from the nearer end
        radii.append(LB["grip_r"] * (0.55 + 0.45 * min(1.0, e / 4.0) ** 0.5))
    s.tube(pts, LB["grip_r"], LN_GRIP, 24 if hi else 10, M, radii=radii)
    return s


def ln_look(L, f):
    nb = L.nb
    # olive green powder coat over pressed steel
    paint = nb.tint(hexc("#56623E"), nb.mr(L.noise(3.0, 1, detail=3), 0.3, 0.7, 0.88, 1.08))
    C = Coat(L, paint, nb.mr(L.noise(8.0, 2, detail=4), 0.2, 0.8, 0.34, 0.48), 0.0,
             nb.mul(L.noise(280.0, 3, detail=1), 0.1))
    enamel = L.k(LN_ENAMEL)
    # sun-faded on top
    C.paint(nb.mul(nb.mul(enamel, L.up), nb.mr(L.noise(1.6, 4, detail=3), 0.3, 0.7, 0.12, 0.35)),
            hexc("#77805C"))
    C.enamel_wear(enamel, hexc("#5C5D5A"), s=5, amount=1.4)
    # rust where it was chipped and stood in the damp: freckles round the foot's lip
    damp = nb.mul(enamel, nb.ss(L.z, 0.05, 0.0))
    C.paint(nb.mul(damp, nb.ss(L.noise(30.0, 6, detail=5, rough=0.7), 0.6, 0.68)), hexc("#6A3B22"), 0.85, 0.0, 0.1)
    # the charging port on the band's back, under a rubber flap long lost
    p = LN["port"]
    port = nb.mul(nb.mul(nb.ss(L.y, 0.12, 0.14), nb.ss(nb.absf(L.x), p["w"] / 2, p["w"] / 2 - 0.002)),
                  nb.ss(nb.absf(nb.sub(L.z, p["z"])), p["h"] / 2, p["h"] / 2 - 0.0015))
    C.paint(nb.mul(port, enamel), hexc("#111111"), 0.6, 0.0, -0.4)
    # black plastic rings and collars
    C.paint(L.k(LN_BLACK), nb.tint(hexc("#1D1D1B"), nb.mr(L.noise(20.0, 7, detail=3), 0.3, 0.7, 0.85, 1.15)),
            nb.mr(L.noise(12.0, 8, detail=3), 0.3, 0.7, 0.42, 0.58), 0.0)
    # the guard's bars: black-green paint worn to steel where hands grab them
    bars = L.k(LN_BARS)
    C.paint(bars, hexc("#2C3125"), 0.42, 0.0)
    C.paint(nb.mul(bars, nb.ss(L.noise(16.0, 9, stretch=(1.0, 1.0, 0.25), detail=4), 0.6, 0.66)),
            hexc("#6D6E6B"), 0.4, 0.8)
    # chrome: the bail and the bezel, bright, pitted with rust specks
    chrome = L.k(LN_CHROME)
    C.paint(chrome, hexc("#CDD0D2"), nb.mr(L.noise(35.0, 10, detail=3), 0.3, 0.7, 0.14, 0.26), 1.0)
    C.paint(nb.mul(chrome, nb.ss(L.noise(60.0, 11, detail=5, rough=0.7), 0.66, 0.72)), hexc("#7A4A2E"), 0.8, 0.1)
    C.paint(L.k(LN_GRIP), nb.tint(hexc("#1A1918"), nb.mr(L.noise(25.0, 12, detail=3), 0.3, 0.7, 0.9, 1.25)),
            0.78, 0.0)
    # brushed aluminium: the knob and the cap, the white line on the knob's pointer
    alu = L.k(LN_ALU)
    C.paint(alu, nb.tint(hexc("#BFC2C4"), nb.mr(L.noise(50.0, 13, detail=3), 0.3, 0.7, 0.85, 1.03)),
            nb.mr(L.noise(70.0, 14, stretch=(1.0, 1.0, 0.1), detail=3), 0.3, 0.7, 0.24, 0.36), 1.0)
    C.paint(L.k(LN_POINTER), hexc("#ECEAE3"), 0.45, 0.0)
    C.paint(L.k(LN_BOTTOM), hexc("#62645F"), 0.6, 0.6)
    # the globe: clear, faintly green glass, smudged by fingers
    glass = L.k(LN_GLASS, LN_GLASS_IN)
    C.paint(glass, hexc("#9FB2AA"), 0.04, 0.0, alpha=0.1)
    smudge = nb.mul(L.k(LN_GLASS), nb.ss(L.noise(6.0, 15, detail=4, rough=0.6), 0.56, 0.7))
    C.paint(nb.mul(smudge, 0.8), hexc("#CDD2CF"), 0.3, alpha=0.22)
    # the diffuser: frosted white plastic, its grooves a touch darker
    diff = L.k(LN_DIFF)
    d = LN["diffuser"]
    u = nb.mul(nb.sub(L.z, d["z0"] + 0.006), 1.0 / (d["z1"] - d["z0"] - 0.012))
    groove = nb.mr(nb.sin(nb.mul(u, 2 * math.pi * d["ribs"] - 0.0)), -1.0, 1.0, 0.0, 1.0)
    C.paint(diff, nb.mixc(nb.mul(groove, 0.35), hexc("#EDE9DF"), hexc("#CFCBC1")), 0.62, 0.0)
    C.lights(nb.mul(diff, nb.mr(groove, 0.0, 1.0, 1.0, 0.72)))
    C.finish(f.dust, grime=0.5)
    return C.surface(bump_dist=0.0012, bump=0.45)


LN_TURN_ON = [(0.0, 0.0), (0.1, LK["click"] + 4.0, "Quad", "Out"), (0.16, LK["click"]),
              (0.34, LK["click"]), (1.15, LK["full"], "Quad", "InOut")]
LANTERN = kit.Find(
    "CampLantern",
    [kit.Part("Body", ln_body),
     kit.Part("Globe", ln_globe, LN_GLOW_AT, "Body", clear=True),
     kit.Part("Diffuser", ln_diffuser, LN_GLOW_AT, "Body"),
     kit.Part("Knob", ln_knob, tuple(LN_KNOB_AT), "Body", (0, 1, 0)),
     kit.Part("Bail", ln_bail, tuple(LN_BAIL_PIVOT), "Body", (1, 0, 0))],
    ln_look,
    lights=[
        # LEDs behind frosted plastic: warm, wide, all round; no shadows, so it shines out
        # through the globe and the guard
        dict(kind="Point", part="Diffuser", at=LN_GLOW_AT, kelvin=LN["kelvin"], brightness=0.8,
             range=12, shadows=False, preview_kind="POINT", preview_watts=9.0, preview_size=0.05),
    ],
    glow=dict(part="Diffuser", strength=3.0, tint=(255, 200, 150), preview=9.0),
    motions={
        # the knob clicks on to a faint glow, then turns up and the light rises with it
        "SwitchOn": dict(duration=1.5, focus=(0.0, -0.08, 0.3), distance=0.65, tracks=[
            ("Knob", "turn", LN_TURN_ON),
            ("Diffuser", "glow", [(0.0, 0.0), (0.1, 0.0), (0.12, 0.16, "Quad", "Out"),
                                  (0.34, 0.13), (1.15, 1.0, "Quad", "InOut"), (1.5, 1.0)])]),
        # turned down, the light falls with it, and it clicks off
        "SwitchOff": dict(duration=0.9, focus=(0.0, -0.08, 0.3), distance=0.65, tracks=[
            ("Knob", "turn", [(0.0, LK["full"]), (0.45, LK["click"] + 2.0, "Quad", "InOut"),
                              (0.53, -2.5, "Quad", "In"), (0.62, 0.0, "Quad", "Out")]),
            ("Diffuser", "glow", [(0.0, 1.0), (0.45, 0.14, "Quad", "InOut"), (0.51, 0.12),
                                  (0.53, 0.0, "Quad", "Out"), (0.9, 0.0)])]),
        # its 90 seconds up: the batteries give out, it stutters, sags and dies
        "RunDown": dict(duration=2.4, focus=(0.0, 0.0, 0.36), distance=0.8, tracks=[
            ("Diffuser", "glow", [(0.0, 1.0), (0.3, 0.82), (0.36, 0.3, "Quad", "Out"), (0.44, 0.78),
                                  (0.8, 0.58), (0.85, 0.16, "Quad", "Out"), (0.92, 0.52),
                                  (1.3, 0.38), (1.35, 0.06, "Quad", "Out"), (1.43, 0.3),
                                  (1.8, 0.12), (2.1, 0.0, "Quad", "In"), (2.4, 0.0)])]),
        # picked up by its handle: the bail swings up off the hood, a touch past upright, and
        # settles
        "Lift": dict(duration=1.0, focus=(0.0, 0.0, 0.62), distance=1.0, tracks=[
            ("Bail", "turn", [(0.0, 0.0), (0.3, -LN["bail_rest"] + 6.0, "Quad", "InOut"),
                              (0.45, -LN["bail_rest"] - 3.0), (0.6, -LN["bail_rest"] + 1.2),
                              (0.78, -LN["bail_rest"])])]),
    },
    dust=LN["dust"], seed=LN["seed"],
)

# --- the moon lamp ------------------------------------------------------------------------------

(MN_MOON, MN_PLUG, MN_SHADE, MN_WOOD_A, MN_WOOD_B) = range(51, 56)
MN, CR = K.MOON, K.CRADLE
MN_ALPHA = math.radians(CR["slope"])
# the moon rests on the V's four slopes: its middle where each slope's top is a radius away
MN_C = Vector((0.0, 0.0, CR["valley"] + MN["R"] / math.cos(MN_ALPHA)))


def mn_outline():
    """One cradle piece's outline in its own plane (x across, z up): the V the moon sits in,
    its two peaks, the legs down to the feet; anticlockwise seen from -Y."""
    ta = math.tan(MN_ALPHA)
    zv, p, a, fw = CR["valley"], CR["peak"], CR["foot"], CR["foot_w"]
    zp = zv + p * ta
    zb = zv - CR["w"] / math.cos(MN_ALPHA)          # the V's underside at the middle
    # the leg's inner edge runs parallel to its outer one from the inner corner of the foot;
    # where it meets the V's underside is the crotch under the peak
    dx, dz = p - a, zp
    t = (zb + (a - fw) * ta) / (dz - dx * ta)
    xi, zi = a - fw + dx * t, dz * t
    right = [(a - fw, 0.0), (a, 0.0), (p, zp)]
    out = [(0.0, zb), (xi, zi)] + right + [(0.0, zv)]
    out += [(-p, zp), (-a, 0.0), (-(a - fw), 0.0), (-xi, zi)]
    return list(reversed(out))


def mn_piece(s, yaw, kind, hi):
    """A cradle piece: its outline pushed out to the wood's thickness, its edges eased."""
    tmp = bmesh.new()
    t = CR["t"]
    ol = mn_outline()
    n = len(ol)
    front = [tmp.verts.new((x, -t / 2, z)) for x, z in ol]
    back = [tmp.verts.new((x, t / 2, z)) for x, z in ol]
    tmp.faces.new(front)
    tmp.faces.new(list(reversed(back)))
    for i in range(n):
        j = (i + 1) % n
        tmp.faces.new((front[i], front[j], back[j], back[i]))
    bmesh.ops.recalc_face_normals(tmp, faces=list(tmp.faces))
    bmesh.ops.bevel(tmp, geom=list(tmp.edges), offset=0.0035 if hi else 0.0025,
                    segments=3 if hi else 1, profile=0.5, affect="EDGES", clamp_overlap=True)
    bmesh.ops.triangulate(tmp, faces=[f for f in tmp.faces if len(f.verts) > 4])
    # turned before it's merged: merge's own matrix projects in the wrong frame
    bmesh.ops.transform(tmp, matrix=Matrix.Rotation(math.radians(yaw), 4, "Z"), verts=tmp.verts)
    s.merge(tmp, kind)
    tmp.free()


def mn_cradle(hi):
    s = Shape()
    mn_piece(s, 0.0, MN_WOOD_A, hi)
    mn_piece(s, 90.0, MN_WOOD_B, hi)
    return s


def mn_dir(lat, lon):
    """A point on the moon's face (unit, from its middle): the near side looks out to -Y,
    longitude east to the right as seen from the front, as the Moon is drawn (IAU)."""
    la, lo = math.radians(lat), math.radians(lon)
    return np.array((math.cos(la) * math.sin(lo), -math.cos(la) * math.cos(lo), math.sin(la)))


def mn_mare(u, warp):
    """How much of a mare each direction in u is (0 to 1): soft caps with ragged shores."""
    out = np.zeros(len(u))
    for lat, lon, rad in MN["maria"]:
        ang = np.degrees(np.arccos(np.clip(u @ mn_dir(lat, lon), -1.0, 1.0)))
        t = np.clip((rad * (1.0 + 0.4 * warp) - ang) / 5.0 + 0.5, 0.0, 1.0)  # a 5 degree shore
        out = np.maximum(out, t * t * (3 - 2 * t))
    return out


def mn_warp(u):
    from mathutils import noise
    return np.array([noise.fractal(Vector(p) * 3.5 + Vector((7.1, 3.3, 1.9)), 0.6, 2.0, 4)
                     for p in u])


def mn_crater(h, u, d, r, w=1.0):
    """One crater of radius r (studs) at direction d: a bowl, a raised rim, ejecta thinning out;
    inside it the older relief is mostly gone."""
    R = MN["R"]
    cr = r / R
    near = np.nonzero(u @ d > math.cos(cr * 2.6))[0]
    if len(near) == 0:
        return
    t = np.arccos(np.clip(u[near] @ d, -1.0, 1.0)) / cr
    depth = MN["depth"] * r
    rim = MN["rim"] * depth
    k = (1 / 2.6) ** 3
    hc = np.where(t < 1.0, -depth + (depth + rim) * t * t,
                  rim * ((1.0 / np.maximum(t, 1.0)) ** 3 - k) / (1 - k))
    keep = np.clip((t - 0.8) / 0.25, 0.0, 1.0)
    h[near] = h[near] * (0.2 + 0.8 * keep * keep) + hc * w


def mn_relief(s):
    """The print's relief on the detailed moon: the maria a touch low and smooth, the highlands
    rough and crowded with craters (bowls with raised rims, many small, few large, the young
    ones over the old), Tycho and Copernicus with their rays. Each point also carries `maria`
    and `ray` (0 to 1) for the look, so the colour and the glow follow the same face."""
    import random
    from mathutils import noise
    R, c = MN["R"], MN["cut"]
    # (new layers first: adding one frees the verts Python holds)
    ml = s.bm.verts.layers.float.new("maria")
    rl = s.bm.verts.layers.float.new("ray")
    vs = list(s.bm.verts)
    C = np.array(MN_C)
    co = np.array([v.co[:] for v in vs]) - C
    r = np.linalg.norm(co, axis=1)
    u = co / r[:, None]
    # the plug's flat stays flat; the relief comes in over the first 3 cm up from the cut
    f = np.clip((co[:, 2] - (-R + c) - 0.004) / 0.03, 0.0, 1.0)
    fade = np.where(r > R - c * 1.5, f * f * (3 - 2 * f), 0.0)
    mar = mn_mare(u, mn_warp(u))
    h = -MN["mare_drop"] * mar
    hills = np.array([noise.fractal(Vector(p) * 20.0, 0.55, 2.0, 4) for p in u])
    h += MN["hills"] * hills * (1.0 - 0.85 * mar)
    rng = random.Random(MN["seed"])
    lo, hi = MN["crater"]
    n = 0
    while n < MN["craters"]:
        z = rng.uniform(-1.0, 1.0)
        a = rng.uniform(0.0, 2 * math.pi)
        q = math.sqrt(1 - z * z)
        d = np.array((q * math.cos(a), q * math.sin(a), z))
        rad = lo * (hi / lo) ** (rng.random() ** 2.4)
        # the maria are younger: few craters, and small
        m = mn_mare(d[None, :], mn_warp(d[None, :]))[0]
        if m > 0.5 and (rng.random() > 0.2 or rad > lo * 1.8):
            continue
        mn_crater(h, u, d, rad)
        n += 1
    ray = np.zeros(len(vs))
    for lat, lon, rad, count in MN["rayed"]:
        d = mn_dir(lat, lon)
        mn_crater(h, u, d, rad, 1.15)
        # rays: thin bright streaks out along great circles, fading with distance
        e1 = np.cross(d, (0.0, 0.0, 1.0))
        e1 /= np.linalg.norm(e1)
        e2 = np.cross(d, e1)
        dist = np.arccos(np.clip(u @ d, -1.0, 1.0))
        bear = np.arctan2(u @ e2, u @ e1)
        cr = rad / R
        halo = np.exp(-((dist / (cr * 3.2)) ** 2))
        for _ in range(count):
            b = rng.uniform(-math.pi, math.pi)
            length = rng.uniform(0.35, 0.9)
            width = rng.uniform(0.008, 0.02)
            db = np.angle(np.exp(1j * (bear - b)))
            across = np.abs(db) * np.sin(np.minimum(dist, math.pi / 2))
            along = np.clip(1.0 - dist / length, 0.0, 1.0) * np.clip((dist - cr) / cr, 0.0, 1.0)
            ray = np.maximum(ray, np.exp(-((across / width) ** 2)) * along)
        ray = np.maximum(ray, halo * 0.8)
    for i, v in enumerate(vs):
        v.co = Vector(C + u[i] * (R + h[i] * fade[i]))
        v[ml] = float(mar[i])
        v[rl] = float(ray[i] * (1.0 - mar[i] * 0.5))


def mn_moon(hi):
    """The moon: a sphere cut flat at the bottom where the plug sits."""
    s = Shape()
    R, c = MN["R"], MN["cut"]
    rc = math.sqrt(R * R - (R - c) ** 2)
    a0 = math.degrees(math.acos((R - c) / R))
    m = MN["rings"][1 if hi else 0]
    plug = [(0.0, -R + c - 0.002), (rc - 0.012, -R + c - 0.002), (rc - 0.006, -R + c + 0.0005)]
    sphere = [(R * math.sin(math.radians(a)), -R * math.cos(math.radians(a)))
              for a in [a0 + (180 - a0) * i / m for i in range(m + 1)]]
    sphere[-1] = (0.0, R)
    prof = plug + sphere
    kinds = [MN_PLUG] * 3 + [MN_MOON] * (len(prof) - 4)
    s.lathe(prof, MN_MOON, MN["segs"][1 if hi else 0], Matrix.Translation(MN_C), kinds=kinds)
    if hi:
        mn_relief(s)
    return s


def mn_shade(hi):
    """The phase shade: a dark cap just outside the moon, facing the back so the moon shows
    full from the front; it turns about the moon's axis to wax and wane."""
    s = Shape()
    Rs = MN["R"] + MN["shade_gap"]
    m = 28 if hi else 14
    prof = [(Rs * math.sin(math.radians(a)), Rs * math.cos(math.radians(a)))
            for a in [112.0 - 112.0 * i / m for i in range(m + 1)]]
    prof[-1] = (0.0, Rs)
    M = Matrix.Translation(MN_C) @ Matrix.Rotation(math.radians(-90), 4, "X")
    s.lathe(prof, MN_SHADE, 80 if hi else 36, M)
    return s


def mn_attr(L, name):
    return L.nb.node("ShaderNodeAttribute", attribute_type="GEOMETRY",
                     attribute_name=name).outputs["Fac"]


def mn_pits(L, scale, s, share):
    """Fine craters below the mesh's: a Voronoi cell's point is a pit's middle, and only
    `share` of the cells hold one, each its own size: a bowl with a lip."""
    nb = L.nb
    v = L.vec(s=s)
    d = nb.voronoi(v, scale)
    rnd = nb.voronoi(v, scale, out="Color")
    rr = nb.add(nb.mul(rnd, 0.6), 0.14)
    t = nb.div(d, rr)
    bowl = nb.mr(t, 0.0, 1.0, -1.0, 0.0, "SMOOTHSTEP")
    lip = nb.mul(nb.band(t, 1.0, 1.1, 0.18), 0.4)
    return nb.mul(nb.add(bowl, lip), nb.ss(rnd, share + 0.02, share))


def mn_look(L, f):
    nb = L.nb
    R = MN["R"]
    moon = L.k(MN_MOON)
    # the Moon's own face, carried on the detailed mesh (mn_relief): the maria, the rays
    maria = mn_attr(L, "maria")
    ray = mn_attr(L, "ray")
    # printed PLA: ivory, satin; the maria a shade greyer, as the print's thicker there
    mott = L.noise(9.0, 12, detail=3, rough=0.6)
    ivory = nb.mixc(nb.add(nb.mul(maria, 0.5), nb.mul(mott, 0.12)), hexc("#F1ECE1"), hexc("#C9C3B5"))
    # the fine pitting the mesh is too coarse for, crowded on the highlands, rare on the maria
    pits = nb.add(mn_pits(L, 70.0, 13, 0.32), nb.mul(mn_pits(L, 150.0, 14, 0.22), 0.6))
    pits = nb.mul(pits, nb.sub(1.0, nb.mul(maria, 0.8)))
    grain = nb.mul(L.noise(260.0, 10, detail=2), 0.12)
    C = Coat(L, ivory, 0.55, 0.0, nb.mul(moon, nb.add(nb.mul(pits, 0.55), grain)))
    # lit through: the highlands bright, the thick maria grey, Tycho's rays brighter still
    glow = nb.add(nb.sub(1.0, nb.mul(maria, 0.7)), nb.mr(mott, 0.3, 0.7, -0.08, 0.08))
    glow = nb.mul(nb.add(glow, nb.mul(ray, 0.25)), nb.add(1.0, nb.mul(pits, 0.25)))
    C.lights(nb.mul(moon, glow))
    # the plug: white ABS, a dark port and the touch dot
    plug = L.k(MN_PLUG)
    C.paint(plug, hexc("#E6E4DF"), 0.4, 0.0, 0.0)
    rx, ry = nb.sub(L.x, 0.035), L.y
    port = nb.mul(nb.ss(nb.absf(rx), 0.006, 0.004), nb.ss(nb.absf(ry), 0.02, 0.017))
    C.paint(nb.mul(plug, port), hexc("#141414"), 0.6, 0.0, -0.4)
    dot = nb.ss(nb.pw(nb.add(nb.mul(nb.add(L.x, 0.03), nb.add(L.x, 0.03)), nb.mul(L.y, L.y)), 0.5), 0.011, 0.008)
    C.paint(nb.mul(plug, dot), hexc("#B9B6B0"), 0.3, 0.0, 0.3)
    # the shade: a dark film, solid over its middle, fading out a little past the terminator
    shade = L.k(MN_SHADE)
    cosb = nb.mul(nb.sub(L.y, MN_C.y), 1.0 / (R + MN["shade_gap"]))
    C.paint(shade, hexc("#0C0E14"), 0.6, 0.0, 0.0, alpha=nb.mul(nb.ss(cosb, -0.2, 0.22), 0.9))
    # the cradle: pale beech, oiled. Its grain runs along each piece as it was cut from the board:
    # soft, uneven lines, and beech's little dark flecks across them
    for kind, st in ((MN_WOOD_A, (0.06, 1.0, 1.0)), (MN_WOOD_B, (1.0, 0.06, 1.0))):
        wood = L.k(kind)
        sd = 7 if kind == MN_WOOD_A else 8
        wob = L.noise(5.0, sd, stretch=st, detail=5, rough=0.6)
        grain = nb.sin(nb.mul(nb.add(L.z, nb.mul(wob, 0.05)), 190.0))
        g = nb.mul(nb.pw(nb.mr(grain, 0.3, 1.0, 0.0, 1.0), 2.0), nb.mr(L.noise(3.0, sd + 20), 0.3, 0.7, 0.2, 1.0))
        fleck = nb.mul(nb.ss(L.noise(90.0, sd + 30, stretch=(2.0, 2.0, 0.5), detail=1), 0.68, 0.74), 0.5)
        col = nb.mixc(nb.add(nb.mul(g, 0.32), fleck), hexc("#DCC199"), hexc("#A88259"))
        C.paint(wood, nb.tint(col, nb.mr(L.noise(1.6, sd + 2, detail=3), 0.3, 0.7, 0.92, 1.05)), 0.5, 0.0,
                nb.mul(g, 0.08))
    # handled: the cradle's edges darkened by hands, a dent or two
    edge = L.edge(0.006, k=4.0)
    C.paint(nb.mul(nb.mul(L.k(MN_WOOD_A, MN_WOOD_B), edge), 0.35), hexc("#8B6A45"), 0.6)
    C.finish(f.dust, grime=0.35)
    return C.surface(bump_dist=MN["relief"], bump=0.7)


MN_SHADE_ON = [(0.0, 0.0), (0.02, 1.0, "Linear")]
MOON_LAMP = kit.Find(
    "MoonLamp",
    [kit.Part("Cradle", mn_cradle),
     kit.Part("Moon", mn_moon, tuple(MN_C), "Cradle", (0, 0, 1)),
     kit.Part("Shade", mn_shade, tuple(MN_C), "Moon", (0, 0, 1), clear=True)],
    mn_look,
    lights=[
        # warm white LEDs inside the shell: a soft glow all round; no shadows, so it shines out
        # through the print
        dict(kind="Point", part="Moon", at=tuple(MN_C), kelvin=MN["kelvin"], brightness=0.8,
             range=10, shadows=False, preview_kind="POINT", preview_watts=7.0, preview_size=0.08),
    ],
    glow=dict(part="Moon", strength=1.6, tint=(255, 214, 170), preview=1.4),
    # found off, its shade hidden; on, the shade stands round it, at full moon to start
    lit={("Shade", "scale"): 1.0},
    motions={
        # tapped on: the light swells up through the print, a touch too bright, then settles
        "SwitchOn": dict(duration=1.0, focus=tuple(MN_C), distance=0.75, tracks=[
            ("Shade", "scale", MN_SHADE_ON),
            ("Moon", "glow", [(0.0, 0.0), (0.45, 1.08, "Quad", "Out"), (0.75, 1.0), (1.0, 1.0)])]),
        "SwitchOff": dict(duration=0.7, focus=tuple(MN_C), distance=0.75, tracks=[
            ("Shade", "scale", [(0.0, 1.0), (0.5, 1.0), (0.52, 0.0, "Linear")]),
            ("Moon", "glow", [(0.0, 1.0), (0.5, 0.0, "Quad", "In"), (0.7, 0.0)])]),
        # tapped: the next phase. The shade turns an eighth of the way round, overshooting a
        # little, and the light blinks as it does (the game adds the phase it was on)
        "Phase": dict(duration=0.9, focus=tuple(MN_C), distance=0.75, tracks=[
            ("Shade", "scale", [(0.0, 1.0), (0.9, 1.0)]),
            ("Shade", "turn", [(0.0, 0.0), (0.55, 48.0, "Quad", "InOut"), (0.75, 44.0), (0.9, 45.0)]),
            ("Moon", "glow", [(0.0, 1.0), (0.08, 0.86, "Quad", "Out"), (0.4, 1.0)])]),
    },
    dust=MN["dust"], seed=MN["seed"],
)

# --- the blob lamp ------------------------------------------------------------------------------

(BL_ALU, BL_ALU_IN, BL_FOOT, BL_GLASS, BL_GLASS_IN, BL_LIQ, BL_LIQTOP, BL_POOL, BL_MOUND, BL_NECK,
 BL_BLOB, BL_CORD, BL_SLEEVE, BL_SWITCH, BL_ROCKER, BL_PLUG, BL_PRONG) = range(56, 73)
BB, BT, BC, BW = K.BLOB_BASE, K.BLOB_BOTTLE, K.BLOB_CAP, K.BLOB_WAX
BL_P = BW["pool_top"]
BL_PIVOT = (0.0, 0.0, BL_P)
BL_SW = BB["switch"]
BL_SW_M = (Matrix.Translation((BL_SW["at"][0], BL_SW["at"][1], 0.0))
           @ Matrix.Rotation(math.radians(BL_SW["yaw"]), 4, "Z"))
BL_ROCK_AT = tuple(BL_SW_M @ Vector((0.0, 0.0, BL_SW["h"] - 0.003)))
BL_ROCK_AX = tuple(BL_SW_M.to_3x3() @ Vector((0.0, 1.0, 0.0)))


def bl_offset(prof, d):
    """A profile (r, z), listed up the outside, moved d inward along its normals: the glass's
    inside."""
    out, n = [], len(prof)
    for i, (r, z) in enumerate(prof):
        t = (Vector(prof[min(i + 1, n - 1)]) - Vector(prof[max(i - 1, 0)])).normalized()
        p = Vector((r, z)) - Vector((t.y, -t.x)) * d
        out.append((max(p.x, 0.0), p.y))
    return out


BL_IN = bl_offset(BT["outside"], BT["wall"])


def bl_rin(z):
    """The bottle's inside radius at height z, up its side."""
    for (r0, z0), (r1, z1) in zip(BL_IN, BL_IN[1:]):
        if z0 <= z <= z1 and z1 > z0:
            return r0 + (r1 - r0) * (z - z0) / (z1 - z0)
    return BL_IN[-1][0]


def bl_base(hi):
    """The spun aluminium base: a rolled foot, a cone in to the waist, a flare out to the collar
    and its rolled rim; inside the collar, the shelf the bottle stands on. The cord leaves the
    back through a rubber sleeve and runs over the floor through an inline rocker switch to a
    two-pin plug."""
    s = Shape()
    out, ins = BB["outside"], BB["inside"]
    (r0, z0), (r1, _) = out[-1], ins[0]
    nl = 6 if hi else 3
    lip = fillet((r0 + r1) / 2, z0, (r0 - r1) / 2, (0, 180), nl)
    prof = out[:-1] + lip + ins[1:]
    n_out = len(out) - 1 + nl
    kinds = [BL_FOOT] + [BL_ALU] * (n_out - 1) + [BL_ALU_IN] * (len(prof) - 1 - n_out)
    s.lathe(prof, BL_ALU, segs(hi, 48), kinds=kinds)
    # the sleeve, square to the cone at the back of the foot
    g = BB["grommet"]
    (ra, za), (rb, zb) = out[5], out[6]
    rz = ra + (rb - ra) * (g["z"] - za) / (zb - za)
    lean = math.atan2(ra - rb, zb - za)
    nrm = Vector((0.0, math.cos(lean), math.sin(lean)))
    foot = Vector((0.0, rz, g["z"]))
    a, b = foot - nrm * 0.008, foot + nrm * g["len"]
    s.tube([tuple(a), tuple(a.lerp(b, 0.55)), tuple(b)], g["r"], BL_SLEEVE, segs(hi, 12),
           radii=[g["r"], g["r"] * 0.86, g["r"] * 0.66])
    # the switch: a two-part moulded case, a nub at each end where the cord goes in, a raised
    # frame round the rocker
    sw, M = BL_SW, BL_SW_M
    l, w, h = sw["l"], sw["w"], sw["h"]
    zc = h * 0.42
    s.box((-l / 2, -w / 2, 0.0), (l / 2, w / 2, h), BL_SWITCH, 0.014 if hi else 0.01, 3 if hi else 1, M)
    for sx in (-1, 1):
        s.tube([(sx * (l / 2 - 0.004), 0.0, zc), (sx * (l / 2 + 0.022), 0.0, zc)], 0.019, BL_SWITCH,
               segs(hi, 12), M, radii=[0.02, 0.0125])
    rl, rw, _ = sw["rocker"]
    t = 0.0055
    for (x0, y0, x1, y1) in [(-rl / 2 - t, -rw / 2 - t, rl / 2 + t, -rw / 2), (-rl / 2 - t, rw / 2, rl / 2 + t, rw / 2 + t),
                             (-rl / 2 - t, -rw / 2, -rl / 2, rw / 2), (rl / 2, -rw / 2, rl / 2 + t, rw / 2)]:
        s.box((x0, y0, h - 0.003), (x1, y1, h + 0.0045), BL_SWITCH, 0.0016 if hi else 0.0, 1, M)
    # the cord: out of the sleeve, down to the floor, into the switch, out and round to the plug
    cr = BB["cord_r"]
    u = M.to_3x3() @ Vector((1.0, 0.0, 0.0))
    A = M @ Vector((-l / 2 - 0.018, 0.0, zc))
    B = M @ Vector((l / 2 + 0.018, 0.0, zc))
    pg = BB["plug"]
    Mp = Matrix.Translation((pg["at"][0], pg["at"][1], 0.0)) @ Matrix.Rotation(math.radians(pg["yaw"]), 4, "Z")
    E = Mp @ Vector((-0.106, 0.0, 0.0215))
    lo_ = Vector((0.0, 0.0, cr))
    one = [tuple(foot + nrm * 0.004), tuple(b + nrm * 0.008), (0.0, 0.262, 0.024), (0.004, 0.3, cr + 0.001),
           (0.022, 0.338, cr), tuple(A - u * 0.045 + lo_), tuple(A)]
    two = [tuple(B), tuple(B + u * 0.035 + lo_), (0.372, 0.508, cr), (0.374, 0.552, cr), (0.347, 0.598, cr),
           (0.29, 0.632, cr), (0.215, 0.648, cr), (0.168, 0.648, cr + 0.003), tuple(E)]
    k = 6 if hi else 3
    s.tube(spline(one, k), cr, BL_CORD, segs(hi, 8))
    s.tube(spline(two, k), cr, BL_CORD, segs(hi, 8))
    # the plug: a moulded body, a tapered tail where the cord goes in, two flat brass pins
    s.box((-0.07, -0.038, 0.0), (0.0, 0.038, 0.044), BL_PLUG, 0.012 if hi else 0.008, 3 if hi else 1, Mp)
    s.tube([(-0.066, 0.0, 0.022), (-0.108, 0.0, 0.0215)], 0.019, BL_PLUG, segs(hi, 12), Mp,
           radii=[0.019, 0.0125])
    for sy in (-1, 1):
        s.box((-0.004, sy * 0.0254 - 0.003, 0.0095), (0.062, sy * 0.0254 + 0.003, 0.0345), BL_PRONG,
              0.0012 if hi else 0.0, 1, Mp)
    return s


def bl_rocker(hi):
    """The switch's rocker, built tipped to off: two faces meeting in a shallow V over its axle,
    sunk into the frame; it rocks about the axle across the switch."""
    s = Shape()
    rl, rw, _ = BL_SW["rocker"]
    M = (Matrix.Translation(BL_ROCK_AT) @ (BL_SW_M.to_3x3().to_4x4())
         @ Matrix.Rotation(math.radians(BL_SW["off"]), 4, "Y"))
    for sx in (-1, 1):
        Mh = M @ Matrix.Rotation(math.radians(-7.0 * sx), 4, "Y")
        x0, x1 = (-0.002, rl / 2) if sx > 0 else (-rl / 2, 0.002)
        s.box((x0, -rw / 2, -0.016), (x1, rw / 2, 0.0115), BL_ROCKER, 0.003 if hi else 0.0015,
              2 if hi else 1, Mh)
    return s


def bl_bottle(hi):
    """The glass bottle, one shell: up the outside, over the lip, down the inside. The inside
    under the liquid's surface carries the liquid's colour; the surface is a disc that climbs
    the glass in a meniscus."""
    s = Shape()
    out, w, liq = BT["outside"], BT["wall"], BT["liquid"]
    (r0, z0) = out[-1]
    nl = 6 if hi else 3
    lip = fillet(r0 - w / 2, z0, w / 2, (0, 180), nl)
    side = list(reversed(BL_IN))[1:]
    k = next(i for i in range(len(side) - 1) if side[i][1] >= liq > side[i + 1][1])
    (ra, za), (rb, zb) = side[k], side[k + 1]
    rl = ra + (rb - ra) * (za - liq) / (za - zb)
    side.insert(k + 1, (rl, liq))
    prof = out[:-1] + lip + side
    n_out = len(out) - 1 + nl
    kinds = [BL_GLASS if i < n_out else
             (BL_GLASS_IN if (prof[i][1] + prof[i + 1][1]) / 2 > liq else BL_LIQ)
             for i in range(len(prof) - 1)]
    s.lathe(prof, BL_GLASS, segs(hi, 48), kinds=kinds)
    men = [(rl - 0.0004, liq + 0.0045), (rl - 0.0025, liq + 0.0015), (rl - 0.007, liq + 0.0003),
           (rl - 0.016, liq), (0.0, liq)]
    s.lathe(men, BL_LIQTOP, segs(hi, 48))
    return s


def bl_cap(hi):
    """The cap: spun like the base, a rolled lip over the bottle's neck, a cone, a rounded top."""
    s = Shape()
    s.lathe(BC["outside"], BL_ALU, segs(hi, 40))
    s.lathe(BC["inside"] + [(0.1035, 1.2538)], BL_ALU_IN, segs(hi, 40))
    return s


def bl_waves(seed, n=5):
    rng = np.random.default_rng(int(seed * 7 + 3))
    return [(Vector(rng.normal(size=3)).normalized(), rng.uniform(1.0, 2.4), rng.uniform(0.0, 6.28))
            for _ in range(n)]


def bl_lumps(s, c, amt, seed):
    """Push a round shape in and out a little, smoothly, so no blob is a ball."""
    waves = bl_waves(seed)
    for v in s.bm.verts:
        d = v.co - c
        if d.length < 1e-9:
            continue
        u = d.normalized()
        k = sum(math.sin(f * math.pi * u.dot(wv) + ph) for wv, f, ph in waves) / len(waves)
        v.co = c + d * (1.0 + amt * 1.6 * k)


def bl_pool(hi):
    """The wax on the bottle's floor: it fills the round bottom and lies gently uneven on top."""
    s = Shape()
    P = BL_P
    rw = bl_rin(P) - 0.0008
    floor = [(r, z + 0.0008) for (r, z) in BL_IN if z < P - 0.012]
    m = 12 if hi else 6
    top = [(rw, P - 0.004), (rw - 0.0035, P + 0.0012)] + [
        ((rw - 0.009) * (1 - i / m), P + 0.002 + 0.0016 * math.cos(3.0 * i / m)) for i in range(m + 1)]
    top[-1] = (0.0, top[-1][1])
    s.lathe(floor + top, BL_POOL, segs(hi, 40))
    waves = bl_waves(9.0, 4)
    for v in s.bm.verts:
        r = math.hypot(v.co.x, v.co.y)
        if v.co.z > P - 0.001 and r < rw - 0.006:
            k = sum(math.sin(f * 18.0 * (v.co.x * wv.x + v.co.y * wv.y) + ph) for wv, f, ph in waves)
            v.co.z += 0.0014 * k * min(1.0, (rw - 0.006 - r) / 0.03)
    return s


def bl_mound(hi):
    """The hump in the middle of the pool, where blobs gather to leave and sink back in."""
    s = Shape()
    m = BW["mound"]
    n = 14 if hi else 7
    prof = [(m["r"] * (1 - i / n), BL_P - 0.004 + (m["h"] + 0.004) * math.exp(-((1 - i / n) / 0.5) ** 2))
            for i in range(n + 1)]
    prof[-1] = (0.0, prof[-1][1])
    s.lathe(prof, BL_MOUND, segs(hi, 28))
    bl_lumps(s, Vector((0.0, 0.0, BL_P - 0.03)), 0.012, 11.0)
    return s


def bl_neck(hi):
    """The strand a rising blob draws up out of the mound: wide at its foot, pinched at its
    waist, opening into the blob. Stretched, it thins (it keeps its volume) until it snaps."""
    s = Shape()
    nk = BW["neck"]
    h0, fo, wa, to = nk["h"], nk["foot"], nk["waist"], nk["top"]
    cp = [(0.0, fo), (0.12, fo * 0.66), (0.5, wa), (0.88, to * 0.9), (1.0, to)]
    n = 18 if hi else 9
    prof = [(0.0, -0.016), (fo * 1.05, -0.012)]
    for i in range(n + 1):
        u = i / n
        j = max(k for k in range(len(cp) - 1) if cp[k][0] <= u) if u < 1 else len(cp) - 2
        (u0, r0), (u1, r1) = cp[j], cp[j + 1]
        e = 0.5 - 0.5 * math.cos(math.pi * (u - u0) / (u1 - u0))
        prof.append((r0 + (r1 - r0) * e, h0 * u))
    prof += [(to * 0.72, h0 + to * 0.55), (to * 0.36, h0 + to * 0.88), (0.0, h0 + to)]
    s.lathe(prof, BL_NECK, segs(hi, 16), Matrix.Translation(BL_PIVOT))
    return s


def bl_blob(name):
    R, lump, seed = BW["blobs"][name]

    def build(hi):
        s = Shape()
        m = 20 if hi else 10
        prof = [(R * math.sin(math.pi * i / m), -R * math.cos(math.pi * i / m)) for i in range(m + 1)]
        prof[0], prof[-1] = (0.0, -R), (0.0, R)
        s.lathe(prof, BL_BLOB, segs(hi, 20), Matrix.Translation(BL_PIVOT))
        bl_lumps(s, Vector(BL_PIVOT), lump, seed)
        return s
    return build


def bl_look(L, f):
    nb = L.nb
    # spun aluminium, satin: fine rings from the spinning, a little brighter and duller by turns
    C = Coat(L, hexc("#B7BBBF"), 0.3, 1.0)
    alu = L.k(BL_ALU)
    rings = L.noise(320.0, 3, stretch=(0.03, 0.03, 1.0), detail=2)
    bands = L.noise(24.0, 4, stretch=(0.05, 0.05, 1.0), detail=2)
    C.paint(alu, nb.tint(hexc("#BCC0C4"), nb.mr(nb.add(nb.mul(rings, 0.5), nb.mul(bands, 0.5)), 0.3, 0.7, 0.86, 1.07)),
            nb.mr(rings, 0.3, 0.7, 0.2, 0.36), 1.0, nb.mul(rings, 0.04))
    # handled and knocked about: patches of fine scratches gone dull, a few dings, a grey film
    # in the waist where hands never reach
    scuff = nb.mul(alu, nb.ss(L.noise(5.0, 5, detail=4, rough=0.6), 0.58, 0.72))
    C.paint(nb.mul(scuff, nb.ss(L.noise(140.0, 6, stretch=(1.0, 1.0, 0.15), detail=2), 0.45, 0.6)),
            hexc("#A9ADB0"), 0.46)
    dings = nb.mul(alu, nb.ss(L.noise(30.0, 7, detail=2), 0.8, 0.86))
    C.paint(dings, height=-0.35)
    waist = nb.mul(alu, nb.mul(nb.ss(L.z, 0.3, 0.38), nb.ss(L.z, 0.5, 0.42)))
    C.paint(nb.mul(waist, 0.35), hexc("#8E9094"), 0.45)
    C.paint(L.k(BL_ALU_IN), hexc("#2F3032"), 0.7, 0.5)
    C.paint(L.k(BL_FOOT), hexc("#1C1B1A"), 0.95, 0.0)
    # the bottle: clear glass, dark and glossy so it reads by its highlights; fingermarks
    glass = L.k(BL_GLASS)
    C.paint(glass, hexc("#9AA5AE"), 0.035, 0.0, alpha=0.085)
    smudge = nb.mul(glass, nb.ss(L.noise(6.0, 8, detail=4, rough=0.6), 0.56, 0.72))
    C.paint(nb.mul(smudge, 0.8), hexc("#C6CACC"), 0.3, alpha=0.2)
    liq = BT["liquid"]
    C.paint(L.k(BL_GLASS_IN), hexc("#9AA5AE"), 0.04, 0.0, alpha=0.07)
    # a faint tide mark just over the liquid, where it has stood for years
    tide = nb.mul(L.k(BL_GLASS_IN), nb.mul(nb.ss(L.z, liq + 0.016, liq + 0.004), nb.ss(L.z, liq, liq + 0.002)))
    C.paint(tide, hexc("#8C7FA8"), 0.3, alpha=0.3)
    # the liquid: violet, pinker low down where the hot wax lights it, bluer up top
    lq = L.k(BL_LIQ, BL_LIQTOP)
    lcol = nb.mixc(nb.ss(L.z, 0.68, 1.15), hexc("#7A2CC4"), hexc("#3F2AA6"))
    C.paint(lq, lcol, 0.05, 0.0, alpha=0.3)
    C.paint(L.k(BL_LIQTOP), alpha=0.45)
    # the liquid only carries the bulb's light, so it glows far less than the wax it holds
    C.lights(nb.mul(lq, nb.mr(L.z, 0.6, 1.22, 0.35, 0.15)))
    # the wax: red-orange, hottest and yellowest in the pool, glossy where it's molten
    P = BL_P
    pool = L.k(BL_POOL, BL_MOUND)
    marble = nb.mr(L.noise(40.0, 9, detail=3), 0.3, 0.7, 0.93, 1.05)
    hot = nb.ss(L.z, P - 0.03, P + 0.02)
    C.paint(pool, nb.tint(nb.mixc(hot, hexc("#F05A1C"), hexc("#FF9A2C")), marble), 0.26, 0.0)
    C.lights(nb.mul(pool, nb.mr(L.z, P - 0.06, P + 0.02, 0.32, 0.48)))
    neck = L.k(BL_NECK)
    nu = nb.mul(nb.sub(L.z, P), 1.0 / BW["neck"]["h"])
    C.paint(neck, nb.tint(nb.mixc(nb.ss(nu, 0.0, 1.0), hexc("#FF8A28"), hexc("#F05220")), marble), 0.28, 0.0)
    C.lights(nb.mul(neck, nb.mr(nu, 0.0, 1.0, 0.46, 0.34)))
    # a blob is lit from under: a bright orange belly, a deeper red crown (its glow kept low,
    # or it washes out to peach: lit wax stays saturated)
    blob = L.k(BL_BLOB)
    bu = nb.mul(nb.sub(L.z, P), 1.0 / 0.06)
    C.paint(blob, nb.tint(nb.mixc(nb.ss(bu, -0.9, 0.9), hexc("#FF6E22"), hexc("#D3301A")), marble), 0.3, 0.0)
    C.lights(nb.mul(blob, nb.mr(bu, -1.0, 1.0, 0.46, 0.16)))
    # the cord: black PVC, its gloss worn dull in places
    C.paint(L.k(BL_CORD), hexc("#161616"), nb.mr(L.noise(30.0, 10, detail=2), 0.3, 0.7, 0.42, 0.6), 0.0)
    C.paint(L.k(BL_SLEEVE), hexc("#141414"), 0.75, 0.0)
    # the switch: black moulded plastic, a seam round its middle, a white bar on the rocker's on side
    sw = L.k(BL_SWITCH)
    C.paint(sw, hexc("#1A1A1A"), 0.48, 0.0)
    C.paint(nb.mul(sw, nb.mul(nb.ss(L.z, BL_SW["h"] * 0.5 - 0.0025, BL_SW["h"] * 0.5 - 0.0008),
                              nb.ss(L.z, BL_SW["h"] * 0.5 + 0.0025, BL_SW["h"] * 0.5 + 0.0008))), hexc("#050505"), 0.8)
    rk = L.k(BL_ROCKER)
    C.paint(rk, hexc("#202020"), 0.38, 0.0)
    rx = nb.add(nb.mul(nb.sub(L.x, BL_ROCK_AT[0]), math.cos(math.radians(BL_SW["yaw"]))),
                nb.mul(nb.sub(L.y, BL_ROCK_AT[1]), math.sin(math.radians(BL_SW["yaw"]))))
    ry = nb.add(nb.mul(nb.sub(L.x, BL_ROCK_AT[0]), -math.sin(math.radians(BL_SW["yaw"]))),
                nb.mul(nb.sub(L.y, BL_ROCK_AT[1]), math.cos(math.radians(BL_SW["yaw"]))))
    bar = nb.mul(nb.mul(nb.ss(rx, -0.024, -0.021), nb.ss(rx, -0.012, -0.015)),
                 nb.mul(nb.ss(ry, -0.012, -0.010), nb.ss(ry, 0.012, 0.010)))
    C.paint(nb.mul(rk, nb.mul(bar, L.up)), hexc("#D8D8D2"), 0.5)
    C.paint(L.k(BL_PLUG), hexc("#191919"), 0.62, 0.0)
    C.paint(L.k(BL_PRONG), nb.tint(hexc("#C9B98E"), nb.mr(L.noise(60.0, 12, detail=2), 0.3, 0.7, 0.85, 1.05)),
            0.32, 1.0)
    sealed = L.k(BL_LIQ, BL_LIQTOP, BL_GLASS_IN, BL_POOL, BL_MOUND, BL_NECK, BL_BLOB, BL_ALU_IN)
    C.finish(f.dust, grime=0.4, keep=sealed)
    return C.surface(bump_dist=0.0008, bump=0.4)


# The flow: each blob's path written as a few keys, joined by a smooth curve that never
# overshoots (no stop at every key), sampled and thinned to straight runs for the game.
BL_FPS = 10.0


def bl_pchip(keys):
    """A monotone cubic through keys [(t, v)]: smooth, and it never overshoots a key."""
    ts = [k[0] for k in keys]
    vs = [k[1] for k in keys]
    n = len(ts)
    d = [(vs[i + 1] - vs[i]) / (ts[i + 1] - ts[i]) for i in range(n - 1)]
    m = [0.0] * n
    for i in range(1, n - 1):
        if d[i - 1] * d[i] > 0:
            w1 = 2 * (ts[i + 1] - ts[i]) + (ts[i] - ts[i - 1])
            w2 = (ts[i + 1] - ts[i]) + 2 * (ts[i] - ts[i - 1])
            m[i] = (w1 + w2) / (w1 / d[i - 1] + w2 / d[i])

    def at(t):
        if t <= ts[0]:
            return vs[0]
        if t >= ts[-1]:
            return vs[-1]
        i = max(j for j in range(n - 1) if ts[j] <= t)
        h = ts[i + 1] - ts[i]
        u = (t - ts[i]) / h
        h00, h10 = 2 * u ** 3 - 3 * u ** 2 + 1, u ** 3 - 2 * u ** 2 + u
        h01, h11 = -2 * u ** 3 + 3 * u ** 2, u ** 3 - u ** 2
        return h00 * vs[i] + h10 * h * m[i] + h01 * vs[i + 1] + h11 * h * m[i + 1]
    return at


def bl_rdp(ts, vs, eps):
    """The fewest keys a straight line between them keeps within eps of the curve."""
    keep, stack = [0, len(ts) - 1], [(0, len(ts) - 1)]
    while stack:
        a, b = stack.pop()
        worst, at = 0.0, None
        for i in range(a + 1, b):
            e = abs(vs[i] - (vs[a] + (vs[b] - vs[a]) * (ts[i] - ts[a]) / (ts[b] - ts[a])))
            if e > worst:
                worst, at = e, i
        if at is not None and worst > eps:
            keep.append(at)
            stack += [(a, at), (at, b)]
    keep.sort()
    out = [(round(ts[i], 2), round(vs[i], 4), "Linear", "In") for i in keep]
    out[0] = out[0][:2]
    return out


# Measured off a video of a real lamp (README): a tower climbs about a sixteenth of the bottle a
# second, slowing near the top; its neck snaps about 16 s in; the blob hangs at the top for about
# 6 s, then sinks faster, gathering speed, and a sinking blob may tear, its top half floating
# back up. rise is the blob's middle above the pool; x and y its drift; sc its size (it grows
# as it draws wax up out of the pool); st its stretch; turn its slow spin.
BL_PLAN = {
    "Blob1": dict(
        sc=[(0, 0), (2.6, 0), (4.2, 0.5), (8, 0.85), (12, 1.0), (16.4, 1.0), (16.7, 1.03), (17.6, 1.0),
            (28.45, 1.0), (28.85, 0.82), (33.2, 0.82), (34.6, 0.0), (52, 0)],
        st=[(0, 2.4), (2.6, 2.4), (6, 2.0), (11, 1.6), (16.35, 1.42), (16.75, 1.08), (17.4, 1.24), (18.2, 1.12),
            (19, 1.16), (23.5, 0.88), (25, 0.85), (26.8, 0.95), (28.4, 1.45), (29.0, 1.05), (29.6, 1.18),
            (32.8, 1.25), (33.4, 0.62), (34.6, 0.55), (52, 2.4)],
        rise=[(0, 0.02), (2.6, 0.02), (4.2, 0.065), (8, 0.19), (12, 0.36), (14.5, 0.445), (16.4, 0.49),
              (18, 0.505), (22, 0.515), (24, 0.515), (26.5, 0.475), (28.5, 0.4), (29.0, 0.38), (31.2, 0.21),
              (33.2, 0.06), (34.6, 0.025), (52, 0.02)],
        x=[(0, 0.0), (4, 0.0), (10, 0.012), (16, 0.02), (20, 0.024), (24, 0.026), (27, 0.04), (30, 0.066),
           (33.2, 0.075), (34.6, 0.075), (52, 0.0)],
        y=[(0, 0.0), (12, 0.008), (24, -0.006), (33, 0.004), (52, 0.0)],
        turn=[(0, 0.0), (4, 0.0), (34.6, 55.0), (52, 0.0)]),
    "Blob2": dict(
        sc=[(0, 0), (21.9, 0), (23.5, 0.5), (27.5, 0.85), (31.5, 1.0), (36.9, 1.0), (37.2, 1.03), (38.1, 1.0),
            (48.5, 1.0), (49.9, 0.0), (52, 0)],
        st=[(0, 2.4), (21.9, 2.4), (25, 2.0), (30, 1.6), (36.85, 1.42), (37.25, 1.08), (37.9, 1.24),
            (38.7, 1.12), (39.5, 1.16), (40.5, 0.9), (42.5, 0.96), (45, 1.2), (48.2, 1.22), (48.7, 0.62),
            (49.9, 0.55), (52, 2.4)],
        rise=[(0, 0.02), (21.9, 0.02), (23.5, 0.065), (27.3, 0.19), (31.3, 0.34), (33.8, 0.42),
              (36.9, 0.465), (38.5, 0.49), (40.5, 0.497), (42.5, 0.46), (44.5, 0.34), (46.5, 0.2),
              (48.5, 0.055), (49.9, 0.025), (52, 0.02)],
        x=[(0, 0.0), (21.9, 0.0), (25, -0.012), (28, -0.03), (32, -0.036), (36, -0.038), (40, -0.036),
           (44, -0.045), (48.5, -0.06), (49.9, -0.06), (52, 0.0)],
        y=[(0, 0.0), (30, -0.006), (44, 0.008), (52, 0.0)],
        turn=[(0, 0.0), (21.9, 0.0), (49.9, -48.0), (52, 0.0)]),
    "Blob3": dict(
        sc=[(0, 0), (28.45, 0), (28.8, 1.0), (41.9, 1.0), (43.1, 0.0), (52, 0)],
        st=[(0, 1.0), (28.45, 1.7), (29.0, 1.05), (29.6, 1.2), (30.4, 1.05), (32, 1.1), (35, 0.9),
            (36.5, 0.95), (39, 1.18), (41.6, 1.2), (42.1, 0.6), (43.1, 0.55), (52, 1.0)],
        rise=[(0, 0.02), (28.45, 0.45), (29.0, 0.465), (30.5, 0.45), (33, 0.425), (35.5, 0.415),
              (38, 0.35), (40, 0.2), (41.9, 0.055), (43.1, 0.02), (52, 0.02)],
        x=[(0, 0.0), (28.45, 0.055), (30, 0.06), (33, 0.066), (36, 0.066), (40, 0.05), (41.9, 0.035),
           (43.1, 0.035), (52, 0.0)],
        y=[(0, 0.0), (52, 0.0)],
        turn=[(0, 0.0), (28.45, 0.0), (43.1, -40.0), (52, 0.0)]),
    # the drop left behind when a neck snaps, as a stretched strand of any liquid leaves one
    "Blob4": dict(
        sc=[(0, 0), (16.35, 0), (16.6, 1.0), (20.4, 1.0), (21.3, 0.0), (36.95, 0), (37.2, 1.0), (40.8, 1.0),
            (41.7, 0.0), (52, 0)],
        st=[(0, 1.0), (16.35, 1.6), (16.85, 0.88), (17.4, 1.08), (18, 1.0), (20.3, 1.05), (20.8, 0.6),
            (21.3, 0.55), (36.95, 1.6), (37.45, 0.88), (38, 1.08), (38.6, 1.0), (40.7, 1.05), (41.2, 0.6),
            (41.7, 0.55), (52, 1.0)],
        rise=[(0, 0.02), (16.35, 0.23), (17.2, 0.235), (20.4, 0.03), (21.3, 0.0), (36.95, 0.22),
              (37.8, 0.225), (40.8, 0.03), (41.7, 0.0), (52, 0.02)],
        x=[(0, 0.0), (16.35, 0.009), (20.4, 0.004), (21.3, 0.0), (36.95, -0.016), (40.8, -0.006),
           (41.7, 0.0), (52, 0.0)],
        y=[(0, 0.0), (52, 0.0)],
        turn=[(0, 0.0), (52, 0.0)]),
}
# the hump in the pool: it swells before a blob leaves, sags as the neck drains it, jumps back
# when the neck snaps, and swells as a blob sinks back in
BL_MOUND_PLAN = dict(
    st=[(0, 1.0), (3.0, 1.7), (6, 1.35), (10, 1.0), (15.5, 0.86), (16.9, 1.06), (18.5, 1.0), (19.5, 1.0),
        (22.5, 1.65), (25.5, 1.3), (29, 1.0), (35.5, 0.86), (37.4, 1.06), (39, 1.0), (52, 1.0)],
    sc=[(0, 1.0), (3.0, 1.12), (6, 1.06), (10, 1.0), (20.4, 1.0), (21.2, 1.05), (22.5, 1.1), (25.5, 1.04),
        (29, 1.0), (41.0, 1.0), (42.3, 1.14), (44.5, 1.0), (52, 1.0)])
# the neck: which blob it feeds and when it's there; it snaps as that blob's stretch springs back
BL_NECK_PLAN = dict(
    feeds=[(2.4, 17.1, "Blob1"), (21.7, 37.6, "Blob2")],
    sc=[(0, 0), (2.7, 0), (4.2, 1.0), (16.4, 1.0), (16.95, 0.0), (21.8, 0), (23.4, 1.0), (36.9, 1.0),
        (37.45, 0.0), (52, 0)])


def bl_flow():
    """Flow's tracks, and the blobs' places at each tenth of a second (for the check)."""
    L = BW["loop"]
    ts = [i / BL_FPS for i in range(int(L * BL_FPS) + 1)]
    tracks, state = [], {}
    eps = dict(move=0.0015, x=0.0015, y=0.0015, scale=0.012, stretch=0.015, turn=0.8)
    for name, plan in BL_PLAN.items():
        c = {k: bl_pchip(v) for k, v in plan.items()}
        sc = [max(0.0, c["sc"](t)) for t in ts]
        st = [c["st"](t) for t in ts]
        rise = [c["rise"](t) for t in ts]
        mv, last = [], 0.0
        for a, b, r in zip(sc, st, rise):
            # the blob's middle rises by move times its scale and stretch (it scales about where
            # it was built), so divide them out; hold still while it's hidden
            last = r / (a * b) if a > 0.02 else last
            mv.append(last)
        x = [c["x"](t) for t in ts]
        y = [c["y"](t) for t in ts]
        tn = [c["turn"](t) for t in ts]
        state[name] = (sc, st, rise, x, y)
        for ch, vs in (("move", mv), ("x", x), ("y", y), ("scale", sc), ("stretch", st), ("turn", tn)):
            tracks.append((name, ch, bl_rdp(ts, vs, eps[ch])))
    cm = {k: bl_pchip(v) for k, v in BL_MOUND_PLAN.items()}
    tracks.append(("Mound", "stretch", bl_rdp(ts, [cm["st"](t) for t in ts], eps["stretch"])))
    tracks.append(("Mound", "scale", bl_rdp(ts, [cm["sc"](t) for t in ts], eps["scale"])))
    # the neck reaches from the mound into the bottom of the blob it feeds, leaning to it
    nsc_c = bl_pchip(BL_NECK_PLAN["sc"])
    h0 = BW["neck"]["h"]
    nsc, nst, nturn = [], [], []
    held = (1.0, 0.0)
    for i, t in enumerate(ts):
        a = max(0.0, nsc_c(t))
        nsc.append(a)
        feed = next((f for f in BL_NECK_PLAN["feeds"] if f[0] <= t < f[1]), None)
        if feed and a > 0.02 and t < feed[1] - 0.6:
            sc, st, rise, x, _ = state[feed[2]]
            R = BW["blobs"][feed[2]][0]
            H = max(0.012, rise[i] - 0.35 * R * sc[i] * st[i])
            held = (min(7.0, max(0.5, H / (h0 * max(a, 0.3)))), math.degrees(math.atan2(x[i], max(rise[i], 0.02))))
        nst.append(held[0])
        nturn.append(held[1])
    tracks += [("Neck", "scale", bl_rdp(ts, nsc, eps["scale"])),
               ("Neck", "stretch", bl_rdp(ts, nst, 0.03)),
               ("Neck", "turn", bl_rdp(ts, nturn, eps["turn"]))]
    tracks += [(p, "glow", [(0.0, 1.0), (L, 1.0)])
               for p in ("Bottle", "Pool", "Mound", "Neck", "Blob1", "Blob2", "Blob3", "Blob4")]
    return tracks, ts, state


def bl_check(ts, state):
    """Print where blobs crowd each other or the glass (lumps allowed for)."""
    names = list(state)
    worst = {}
    for i, t in enumerate(ts):
        e = {}
        for n in names:
            sc, st, rise, x, y = state[n]
            if sc[i] < 0.3:
                continue
            R, lump, _ = BW["blobs"][n]
            a, b = R * sc[i] / math.sqrt(st[i]) * (1 + lump), R * sc[i] * st[i] * (1 + lump)
            e[n] = (x[i], y[i], BL_P + rise[i], a, b)
            zc = BL_P + rise[i]
            # the glass: the widest the blob is at each height against the bottle there
            for k in range(-4, 5):
                z = zc + b * k / 5
                half = a * math.sqrt(max(0.0, 1 - (k / 5) ** 2))
                gap = bl_rin(z) - math.hypot(x[i], y[i]) - half
                if gap < worst.get((n, "glass"), (1, 0))[0]:
                    worst[(n, "glass")] = (gap, t)
            top = BT["liquid"] - (zc + b)
            if top < worst.get((n, "top"), (1, 0))[0]:
                worst[(n, "top")] = (top, t)
        for j, p in enumerate(names):
            for q in names[j + 1:]:
                if p not in e or q not in e:
                    continue
                if (p, q) == ("Blob1", "Blob3") and 28.3 < t < 30.0:
                    continue  # a blob tearing in two touches the half it tears from
                (x1, y1, z1, a1, b1), (x2, y2, z2, a2, b2) = e[p], e[q]
                d = math.hypot(math.hypot(x1 - x2, y1 - y2) / (a1 + a2), (z1 - z2) / (b1 + b2))
                if d < worst.get((p, q), (9, 0))[0]:
                    worst[(p, q)] = (d, t)
    for k, (v, t) in sorted(worst.items(), key=lambda kv: kv[1][0]):
        bad = v < (1.0 if k[1] not in ("glass", "top") else 0.004)
        if bad:
            print(f"  blob lamp: {k[0]} and {k[1]} {'touch' if k[1] not in ('glass', 'top') else 'gap'} "
                  f"{v:.3f} at {t:.1f} s")


BL_TRACKS, BL_TS, BL_STATE = bl_flow()
bl_check(BL_TS, BL_STATE)
BL_LIT_AT = 29.8   # the still for the lit previews: one blob sinking, its torn top floating, a tower


def bl_rock(a, b):
    return [(0.0, a), (0.05, b + (2.0 if b > a else -2.0), "Quad", "Out"), (0.1, b)]


BL_ON = BL_SW["on"] - BL_SW["off"]
BLOB_LAMP = kit.Find(
    "BlobLamp",
    [kit.Part("Base", bl_base),
     kit.Part("Rocker", bl_rocker, BL_ROCK_AT, "Base", BL_ROCK_AX),
     kit.Part("Bottle", bl_bottle, (0.0, 0.0, BT["outside"][0][1]), "Base", clear=True),
     kit.Part("Cap", bl_cap, (0.0, 0.0, BC["outside"][0][1]), "Bottle"),
     kit.Part("Pool", bl_pool, BL_PIVOT, "Bottle"),
     kit.Part("Mound", bl_mound, (0.0, 0.0, BL_P - 0.004), "Pool", (0, 0, 1), alone=True),
     kit.Part("Neck", bl_neck, BL_PIVOT, "Pool", (0, 1, 0), alone=True)]
    + [kit.Part(n, bl_blob(n), BL_PIVOT, "Pool", (0, 0, 1), alone=True) for n in BW["blobs"]],
    bl_look,
    lights=[
        # the bulb in the base, seen through violet liquid and orange wax: a pink-violet glow all
        # round; no shadows, so it shines out through the base and the bottle
        # (it sits where the bulb is, under the wax: any higher and it burns the pool white)
        dict(kind="Point", part="Bottle", at=(0.0, 0.0, 0.57), rgb=K.BLOB_LAMP["rgb"], brightness=0.8,
             range=10, shadows=False, preview_kind="POINT", preview_watts=5.0, preview_size=0.06),
    ],
    glow=dict(part="Bottle", strength=2.0, tint=(255, 214, 196), preview=10.0),
    lit={**{(p, ch): ease.sample(ease.keys(ks), BL_LIT_AT) for p, ch, ks in BL_TRACKS},
         ("Rocker", "turn"): BL_ON},
    motions={
        # clicked on at the switch on the cord: the bulb lights the liquid at once, the wax
        # warms into colour a beat behind, and the pool stirs
        "SwitchOn": dict(duration=2.2, focus=(0.0, 0.0, 0.62), distance=0.75, tracks=[
            ("Rocker", "turn", bl_rock(0.0, BL_ON)),
            ("Bottle", "glow", [(0.0, 0.0), (0.1, 0.0), (0.22, 0.8, "Quad", "Out"), (0.9, 1.0)]),
            ("Pool", "glow", [(0.0, 0.0), (0.12, 0.0), (0.5, 0.65, "Quad", "Out"), (1.6, 1.0)]),
            ("Mound", "glow", [(0.0, 0.0), (0.12, 0.0), (0.5, 0.65, "Quad", "Out"), (1.6, 1.0)]),
            ("Mound", "stretch", [(0.0, 1.0), (1.2, 1.06), (2.2, 1.0)])]),
        # warm: played on a loop (its end is its start). Two towers climb and snap, one blob
        # tears on the way down, and the drops left by the snaps fall back in
        "Flow": dict(duration=BW["loop"], fps=8, focus=(0.0, 0.0, 0.9), distance=0.5, tracks=BL_TRACKS),
        # clicked off: the light goes, the wax's glow a breath after; the blobs stay where they
        # were (the game stops Flow there)
        "SwitchOff": dict(duration=1.4, focus=(0.0, 0.0, 0.62), distance=0.75, tracks=[
            ("Rocker", "turn", bl_rock(BL_ON, 0.0)),
            ("Bottle", "glow", [(0.0, 1.0), (0.1, 1.0), (0.3, 0.12, "Quad", "Out"), (0.8, 0.0)]),
            ("Pool", "glow", [(0.0, 1.0), (0.12, 1.0), (0.5, 0.3, "Quad", "Out"), (1.4, 0.0)]),
            ("Mound", "glow", [(0.0, 1.0), (0.12, 1.0), (0.5, 0.3, "Quad", "Out"), (1.4, 0.0)])]),
    },
    dust=K.BLOB_LAMP["dust"], seed=K.BLOB_LAMP["seed"],
)

# --- the oil lamp -------------------------------------------------------------------------------

(OL_SOLID, OL_GLASS, OL_GLASS_IN, OL_OIL, OL_OILTOP, OL_WICK, OL_BRASS, OL_BRASS_IN, OL_DOME,
 OL_STEEL, OL_WHEEL, OL_CHIM, OL_CHIM_IN, OL_FLAME) = range(73, 87)
OG, OB, OC, OF, OLK = K.OIL_GLASS, K.OIL_BURNER, K.OIL_CHIMNEY, K.OIL_FLAME, K.OIL_LAMP
OL_CHIM_Z = 0.987                      # the chimney's foot, standing in the gallery's dish
OL_CHIM_TOP = OL_CHIM_Z + OC["outside"][-1][1]
OL_FLAME_FOOT = (0.0, 0.0, OB["flame_at"])
OL_FLAME_MID = (0.0, 0.0, OB["flame_at"] + OF["h"] * 0.4)
OL_WHEEL_AT = (OB["wheel"]["x"], 0.0, OB["spindle"]["z"])


def ol_dense(prof, step):
    """A profile with points added so no run is longer than step (a chip needs rings to bend)."""
    out = [prof[0]]
    for a, b in zip(prof, prof[1:]):
        n = max(1, math.ceil((Vector(b) - Vector(a)).length / step))
        out += [(a[0] + (b[0] - a[0]) * i / n, a[1] + (b[1] - a[1]) * i / n) for i in range(1, n + 1)]
    return out


def ol_chip(s, deg, depth, width, z0, z1, down, inward, rmin=0.0, zmax=99.0):
    """Knock a chip out of a glass edge: the vertices near the angle `deg` (round from +X) and
    between heights z0 and z1 drop and pull in, most in the middle and at z1, unevenly, like a
    flake that came away."""
    a0 = math.radians(deg)
    rng = np.random.default_rng(int(abs(deg) * 13 + depth * 1000))
    jag = [rng.uniform(0.75, 1.15) for _ in range(9)]
    for v in s.bm.verts:
        r = math.hypot(v.co.x, v.co.y)
        if r < max(rmin, 1e-6) or not (z0 <= v.co.z <= zmax):
            continue
        d = (math.atan2(v.co.y, v.co.x) - a0 + math.pi) % (2.0 * math.pi) - math.pi
        e = abs(d * r) / (width / 2.0)
        if e >= 1.0:
            continue
        j = jag[min(int((d * r / width + 0.5) * 8.0), 8)]
        f = (1.0 - e * e) ** 0.6 * j
        w = min(1.0, (v.co.z - z0) / (z1 - z0))
        w = w * w * (3.0 - 2.0 * w) * depth * f
        v.co.z -= w * down
        v.co.x -= v.co.x / r * w * inward
        v.co.y -= v.co.y / r * w * inward


def ol_fount(hi):
    """The glass, one shell: up the outside from the hollow under the foot, over the neck's lip,
    down the fount's inside to its floor. Under the paraffin's surface the inside carries the
    oil's colour; the surface is a disc meeting the glass in a meniscus. The flat wick hangs
    from the burner into the oil, twisting a little, its end lying on the floor."""
    s = Shape()
    out, w, oil, fl = OG["outside"], OG["wall"], OG["oil"], OG["floor"]
    fi = OG["fount"]
    (r0, z0) = out[-1]
    nl = 4 if hi else 2
    lip = fillet(r0 - w / 2, z0, w / 2, (0, 180), nl)
    inner = bl_offset(out[fi:], w)
    side = [p for p in reversed(inner) if p[1] > fl + 0.012][1:]
    side += [(side[-1][0] * 0.6, fl + 0.002), (0.0, fl)]
    k = next(i for i in range(len(side) - 1) if side[i][1] >= oil > side[i + 1][1])
    (ra, za), (rb, zb) = side[k], side[k + 1]
    rl = ra + (rb - ra) * (za - oil) / (za - zb)
    side.insert(k + 1, (rl, oil))
    prof = out[:-1] + lip + side
    n_out = len(out) - 1
    kinds = [(OL_SOLID if i < fi else OL_GLASS) if i < n_out + nl else
             (OL_GLASS_IN if (prof[i][1] + prof[i + 1][1]) / 2 > oil else OL_OIL)
             for i in range(len(prof) - 1)]
    s.lathe(prof, OL_GLASS, segs(hi, 48), kinds=kinds)
    c = OG["chips"]["foot"]
    ol_chip(s, c[0], c[1], 0.06, 0.008, 0.036, 0.35, 1.0, rmin=0.25, zmax=0.05)
    men = [(rl - 0.0004, oil + 0.003), (rl - 0.002, oil + 0.001), (rl - 0.006, oil + 0.0002),
           (rl - 0.014, oil), (0.0, oil)]
    s.lathe(men, OL_OILTOP, segs(hi, 48))
    # the wick: a flat cotton ribbon an inch wide; rings bottom to top, anticlockwise from above
    hw, ht = 0.047, 0.0032
    zs = [fl + 0.004, fl + 0.016, 0.4, 0.45, 0.52, 0.6, 0.68, 0.76, 0.83, 0.874]
    rings = []
    for z in zs:
        u = (z - zs[0]) / (zs[-1] - zs[0])
        cx = 0.045 * (1.0 - u) ** 2.2
        tw = math.radians(28.0 * (1.0 - u) ** 1.5)
        ct, st = math.cos(tw), math.sin(tw)
        ring = []
        for (a, b) in ((hw, -ht), (hw, ht), (-hw, ht), (-hw, -ht)):
            ring.append((cx + a * ct - b * st, a * st + b * ct, z))
        rings.append(ring)
    s.loft(rings, OL_WICK, cap_bottom=OL_WICK)
    return s


def ol_burner(hi):
    """The brass burner and collar: one spun shell from the underside, up the threaded collar,
    the band of air holes and the gallery to the slotted dome; four prongs that hold the
    chimney; the steel spindle out the side through its boss."""
    s = Shape()
    prof = OB["outside"]
    kinds = [OL_BRASS_IN if i < 2 or i in (22, 23) else (OL_DOME if i >= 24 else OL_BRASS)
             for i in range(len(prof) - 1)]
    s.lathe(prof, OL_BRASS, segs(hi, 40), kinds=kinds)
    P = OB["prongs"]
    zb = prof[20][1]
    for i in range(P["n"]):
        a = math.radians(P["at"] + 360.0 * i / P["n"])
        R = Matrix.Rotation(a - math.pi / 2.0, 4, "Z")
        M1 = R @ Matrix.Translation((0.0, P["r"], 0.0))
        s.box((-P["w"] / 2, 0.0, zb), (P["w"] / 2, P["t"], zb + P["up"]), OL_BRASS,
              chamfer=0.0008, segs=2 if hi else 1, M=M1)
        M2 = R @ Matrix.Translation((0.0, P["r"], zb + P["up"] - 0.002)) @ Matrix.Rotation(
            math.radians(-P["lean"]), 4, "X")
        s.box((-P["w"] / 2, 0.0, 0.0), (P["w"] / 2, P["t"], P["flare"]), OL_BRASS,
              chamfer=0.0008, segs=2 if hi else 1, M=M2)
    S = OB["spindle"]
    s.cylinder(Vector((0.116, 0.0, S["z"])), Vector((0.134, 0.0, S["z"])), S["boss"], OL_BRASS, segs(hi, 12))
    s.cylinder(Vector((S["x0"], 0.0, S["z"])), Vector((S["x1"], 0.0, S["z"])), S["r"], OL_STEEL, segs(hi, 8))
    return s


def ol_wheel(hi):
    """The thumbwheel: a brass disc with a knurled rim and a hub nut on the spindle's end."""
    s = Shape()
    W = OB["wheel"]
    r, t, hb = W["r"], W["t"], W["hub"]
    M = Matrix.Translation(OL_WHEEL_AT) @ Matrix.Rotation(math.pi / 2.0, 4, "Y")
    prof = [(0.0, -t / 2), (r - 0.003, -t / 2), (r, -t / 2 + 0.0025), (r, t / 2 - 0.0025),
            (r - 0.003, t / 2), (hb, t / 2), (hb, t / 2 + 0.0045), (hb - 0.002, t / 2 + 0.0058),
            (0.0, t / 2 + 0.0058)]
    s.lathe(prof, OL_WHEEL, segs(hi, 36), M)
    return s


def ol_chimney(hi):
    """The chimney, one shell of thin blown glass: the fitter, the bulge, the long top with its
    fire-polished bead, over the rim and down the inside. A chip is out of its rim."""
    s = Shape()
    w = OC["wall"]
    out = [(r, z + OL_CHIM_Z) for r, z in ol_dense(OC["outside"], 0.03 if hi else 0.12)]
    (r0, z0) = out[-1]
    nl = 4 if hi else 2
    lip = fillet(r0 - w / 2, z0, w / 2, (0, 180), nl)
    inner = bl_offset(out[1:], w)
    start = (out[0][0] - w * 0.55, OL_CHIM_Z)
    prof = [start] + out[:-1] + lip + list(reversed(inner))[1:] + [start]
    n_out = len(out) + nl
    kinds = [OL_CHIM if i < n_out else OL_CHIM_IN for i in range(len(prof) - 1)]
    s.lathe(prof, OL_CHIM, segs(hi, 48), kinds=kinds)
    deg, depth, width = OC["chip"]
    ol_chip(s, deg, depth, width, z0 - depth * 2.6, z0 + w / 2, 1.0, 0.25)
    return s


def ol_flame(hi):
    """The flame off a flat wick: a fan, broad face on and thin edge on, as wide as the wick at
    its foot, rounded over to a soft point."""
    s = Shape()
    foot = Vector(OL_FLAME_FOOT)
    nr, na = (16, 28) if hi else (8, 14)
    rings = [[tuple(foot + Vector((0.0, 0.0, -0.004)))]]
    for i in range(1, nr):
        u = i / nr
        w = OF["w"] * (1.0 - u ** 3.2) ** 0.55 * (0.9 + 0.14 * math.sin(math.pi * min(u * 1.4, 1.0)))
        t = OF["t"] * math.sin(math.pi * u ** 0.75) ** 0.8
        ring = []
        for j in range(na):
            a = 2.0 * math.pi * j / na
            c, sn = math.cos(a), math.sin(a)
            ring.append((w * math.copysign(abs(c) ** 0.8, c), t * math.copysign(abs(sn) ** 0.8, sn),
                         foot.z + OF["h"] * u))
        rings.append(ring)
    rings.append([tuple(foot + Vector((0.0, 0.0, OF["h"])))])
    s.loft(rings, OL_FLAME)
    return s


def ol_look(L, f):
    nb = L.nb
    ang = nb.math("ARCTAN2", L.y, L.x)
    rad = nb.pw(nb.add(nb.mul(L.x, L.x), nb.mul(L.y, L.y)), 0.5)
    # pressed soda-lime glass: a faint sea green, glossy, dark so it reads by its highlights
    C = Coat(L, hexc("#86A196"), 0.04, 0.0)
    glass, solid = L.k(OL_GLASS), L.k(OL_SOLID)
    C.paint(glass, alpha=0.12)
    C.paint(solid, hexc("#7C9C8F"), alpha=0.22)
    C.paint(L.k(OL_GLASS_IN), alpha=0.07)
    # pressed panels round the fount's lower half, and the mould's two seams
    tri = nb.absf(nb.sub(nb.fract(nb.mul(ang, OG["flutes"] / (2.0 * math.pi))), 0.5))
    flute = nb.mul(nb.mul(glass, nb.mul(nb.ss(L.z, 0.345, 0.37), nb.ss(L.z, 0.53, 0.49))), nb.ss(tri, 0.5, 0.15))
    C.paint(flute, height=nb.mul(flute, 0.8))
    seam = nb.mul(nb.add(glass, solid, clamp=True),
                  nb.ss(nb.absf(L.x), 0.0016, 0.0006))
    C.paint(seam, hexc("#B9C9C2"), 0.1, height=nb.mul(seam, 0.5), alpha=0.3)
    smudge = nb.mul(nb.add(glass, solid, clamp=True), nb.ss(L.noise(7.0, 21, detail=4, rough=0.6), 0.55, 0.7))
    C.paint(nb.mul(smudge, 0.8), hexc("#CFD3CF"), 0.32, alpha=0.24)
    # the foot's chip: fresh glass, whiter and frosted where it broke
    fc = OG["chips"]["foot"]
    fdist = nb.mul(nb.absf(nb.sub(ang, math.radians(fc[0]))), rad)
    fchip = nb.mul(nb.mul(solid, nb.ss(fdist, 0.03, 0.018)), nb.mul(nb.ss(rad, 0.272, 0.285), nb.ss(L.z, 0.012, 0.024)))
    C.paint(fchip, hexc("#E4ECE8"), 0.3, alpha=0.5)
    # the paraffin: old oil gone amber, a faint tide mark where it stood higher once
    oil = OG["oil"]
    C.paint(L.k(OL_OIL), hexc("#74400E"), 0.02, 0.0, alpha=0.5)
    C.paint(L.k(OL_OILTOP), hexc("#7E4812"), 0.02, 0.0, alpha=0.55)
    tide = nb.mul(L.k(OL_GLASS_IN), nb.mul(nb.ss(L.z, oil + 0.05, oil + 0.035), nb.ss(L.z, oil + 0.03, oil + 0.036)))
    C.paint(tide, hexc("#8C6A3A"), 0.3, alpha=0.24)
    # the wick: cream cotton, soaked amber up from the oil, scorched black at the top
    wick = L.k(OL_WICK)
    C.paint(wick, nb.tint(hexc("#D6CBB1"), nb.mr(L.noise(80.0, 22, stretch=(1.0, 1.0, 0.2), detail=2), 0.3, 0.7, 0.9, 1.04)), 0.9, 0.0, alpha=1.0)
    C.paint(nb.mul(wick, nb.ss(L.z, oil + 0.1, oil - 0.02)), hexc("#9C6C30"), 0.6)
    # the brass: polished once, tarnished brown in patches and creases, worn bright on edges
    brass = L.k(OL_BRASS, OL_WHEEL)
    bcol = nb.tint(hexc("#C9A24F"), nb.mr(L.noise(50.0, 23, detail=3), 0.3, 0.7, 0.9, 1.06))
    C.paint(brass, bcol, nb.mr(L.noise(40.0, 24, detail=3), 0.3, 0.7, 0.22, 0.34), 1.0)
    tarn = nb.mul(brass, nb.ss(L.noise(6.0, 25, detail=5, rough=0.65), 0.5, 0.66))
    C.paint(tarn, hexc("#7E6431"), 0.5)
    C.paint(nb.mul(tarn, nb.ss(L.noise(14.0, 26, detail=4), 0.6, 0.72)), hexc("#4F4A2E"), 0.6)
    # the air holes, round the band, clear of the spindle
    H = OB["holes"]
    hu = nb.mul(nb.sub(nb.fract(nb.add(nb.mul(ang, H["n"] / (2.0 * math.pi)), 0.5)), 0.5), 2.0 * math.pi * 0.12 / H["n"])
    hz = nb.sub(L.z, H["z"])
    hd = nb.pw(nb.add(nb.mul(hu, hu), nb.mul(hz, hz)), 0.5)
    hole = nb.mul(nb.mul(L.k(OL_BRASS), nb.ss(hd, H["r"], H["r"] * 0.75)),
                  nb.mul(nb.ss(rad, 0.116, 0.119), nb.ss(nb.absf(ang), 0.2, 0.3)))
    C.paint(hole, hexc("#0E0B08"), 0.9, 0.2, nb.mul(hole, -1.0))
    # inside the gallery and under the burner: soot-dark brass
    C.paint(L.k(OL_BRASS_IN), hexc("#2B2219"), 0.7, 0.3)
    # the dome: heat-darkened brass, sooty round its slot; the slot itself black
    dome = L.k(OL_DOME)
    C.paint(dome, hexc("#8A6A34"), 0.42, 0.9)
    C.paint(nb.mul(dome, nb.ss(rad, 0.05, 0.02)), hexc("#3A2C1E"), 0.6, 0.5)
    sx, sw = OB["slot"]
    slot = nb.mul(dome, nb.mul(nb.ss(nb.absf(L.x), sx, sx - 0.003), nb.ss(nb.absf(L.y), sw, sw - 0.0015)))
    C.paint(slot, hexc("#060504"), 0.95, 0.0, nb.mul(slot, -1.0))
    # the spindle: steel, a little rusty
    st = L.k(OL_STEEL)
    C.paint(st, hexc("#8F8A83"), 0.38, 1.0)
    C.paint(nb.mul(st, nb.ss(L.noise(30.0, 27, detail=4), 0.58, 0.68)), hexc("#6E4A2E"), 0.8, 0.1)
    # the wheel's knurled rim
    wh = L.k(OL_WHEEL)
    wy, wz = L.y, nb.sub(L.z, OB["spindle"]["z"])
    wa = nb.math("ARCTAN2", wz, wy)
    wr = nb.pw(nb.add(nb.mul(wy, wy), nb.mul(wz, wz)), 0.5)
    knurl = nb.absf(nb.sub(nb.fract(nb.mul(wa, OB["wheel"]["knurl"] / (2.0 * math.pi))), 0.5))
    rim = nb.mul(wh, nb.ss(wr, OB["wheel"]["r"] - 0.0035, OB["wheel"]["r"] - 0.001))
    C.paint(rim, height=nb.mul(rim, nb.mul(nb.ss(knurl, 0.1, 0.4), 1.2)))
    C.paint(nb.mul(rim, nb.ss(knurl, 0.25, 0.45)), hexc("#E0BE6E"), 0.2)
    # the chimney: thin clear glass; fingermarks on the bulge, soot inside above the flame
    ch, chi = L.k(OL_CHIM), L.k(OL_CHIM_IN)
    # (dark, so the flame inside lights it as glass, not as yellow plastic)
    # (alpha 0.08 vanished in Roblox, which blends alpha lighter than Cycles and has no
    # Fresnel to draw glass's edges: F-S1 raised it until the chimney read from a doorway)
    C.paint(ch, hexc("#5C6668"), 0.03, 0.0, alpha=0.18)
    C.paint(chi, hexc("#5C6668"), 0.03, 0.0, alpha=0.12)
    zc = OL_CHIM_Z
    prints = nb.mul(nb.mul(ch, nb.mul(nb.ss(L.z, zc + 0.12, zc + 0.18), nb.ss(L.z, zc + 0.36, zc + 0.3))),
                    nb.ss(L.noise(9.0, 28, detail=4, rough=0.6), 0.55, 0.68))
    C.paint(prints, hexc("#D2D6D3"), 0.35, alpha=0.22)
    soot_h = nb.mul(nb.ss(L.z, zc + 0.22, zc + 0.42), nb.ss(L.z, zc + 0.75, zc + 0.55))
    drift = nb.mr(L.noise(4.0, 29, detail=5, rough=0.65, distortion=0.4), 0.35, 0.7, 0.0, 1.0)
    C.paint(nb.mul(nb.mul(chi, soot_h), drift), hexc("#221D19"), 0.6, alpha=0.3)
    cdeg, cdepth, cwidth = OC["chip"]
    cdist = nb.mul(nb.absf(nb.sub(ang, math.radians(cdeg))), rad)
    cchip = nb.mul(nb.add(ch, chi, clamp=True), nb.mul(nb.ss(cdist, cwidth * 0.5, cwidth * 0.32),
                                                       nb.ss(L.z, OL_CHIM_TOP - cdepth * 1.8, OL_CHIM_TOP - cdepth * 0.9)))
    C.paint(cchip, hexc("#D6E0DC"), 0.25, alpha=0.4)
    # the flame: blue and faint where it leaves the slot, a white-yellow heart, orange edges
    # and tip
    fl = L.k(OL_FLAME)
    u = nb.mul(nb.sub(L.z, OL_FLAME_FOOT[2]), 1.0 / OF["h"])
    edge = nb.ss(nb.absf(L.x), OF["w"] * 0.72, OF["w"] * 1.0)
    fcol = nb.mixc(nb.ss(u, 0.06, 0.18), hexc("#4A66E8"), hexc("#FFE6A6"))
    fcol = nb.mixc(nb.add(nb.ss(u, 0.5, 0.95), nb.mul(edge, 0.7), clamp=True), fcol, hexc("#FF9C3C"))
    C.paint(fl, fcol, 0.5, 0.0)
    C.paint(fl, alpha=nb.mr(u, 0.0, 0.16, 0.25, 0.92))
    C.paint(nb.mul(fl, nb.ss(u, 0.8, 1.0)), alpha=0.5)
    C.lights(nb.mul(fl, nb.mr(u, 0.04, 0.18, 0.3, 1.0)))
    sealed = L.k(OL_OIL, OL_OILTOP, OL_WICK, OL_GLASS_IN, OL_CHIM_IN, OL_FLAME, OL_BRASS_IN)
    # dust only on the chimney's rim: on its sides the flame lights dust up like frosted plastic
    sides = nb.mul(ch, nb.ss(L.z, OL_CHIM_TOP - 0.03, OL_CHIM_TOP - 0.12))
    C.finish(f.dust, grime=0.35, keep=nb.add(sealed, sides, clamp=True))
    return C.surface(bump_dist=0.0006, bump=0.4)


OL_UP, OL_LIFT = OLK["wick_up"], OLK["lift"]
# the close filmstrips aim this high so the flame, not the burner, fills them
OL_FLAME_LOOK = (0.0, 0.0, OB["flame_at"] + 0.13)
OIL_LAMP = kit.Find(
    "OilLamp",
    [kit.Part("Fount", ol_fount, clear=True),
     kit.Part("Burner", ol_burner, (0.0, 0.0, OB["collar"]), "Fount"),
     kit.Part("Wheel", ol_wheel, OL_WHEEL_AT, "Burner", (1, 0, 0)),
     kit.Part("Chimney", ol_chimney, (0.0, 0.0, OL_CHIM_Z), "Burner", (0, 0, 1), clear=True),
     kit.Part("Flame", ol_flame, OL_FLAME_FOOT, "Burner", (0, 1, 0), clear=True)],
    ol_look,
    lights=[
        # a paraffin flame: deep warm, all round; no shadows, so it shines out through the glass
        dict(kind="Point", part="Flame", at=OL_FLAME_MID, kelvin=OF["kelvin"], brightness=0.7,
             range=10, shadows=False, preview_kind="POINT", preview_watts=9.0, preview_size=0.02),
    ],
    glow=dict(part="Flame", strength=3.0, tint=(255, 176, 92), preview=14.0),
    # found cold: the flame is scaled to nothing, the wick wound down
    lit={("Flame", "scale"): 1.0, ("Wheel", "turn"): OL_UP},
    motions={
        # lit the way a real one is: the chimney lifted off its prongs, a flame caught low and
        # lazy, the chimney set back (a ring of glass on brass), its draught drawing the flame
        # up tall, then the wheel winds the wick up to a good flame
        "Light": dict(duration=2.6, focus=(0.0, 0.0, 1.3), distance=1.0, tracks=[
            ("Chimney", "move", [(0.0, 0.0), (0.08, -0.002), (0.4, OL_LIFT + 0.01, "Quad", "Out"),
                                 (0.52, OL_LIFT), (1.1, OL_LIFT), (1.42, 0.004, "Quad", "In"),
                                 (1.46, 0.0, "Linear"), (1.5, 0.005, "Quad", "Out"),
                                 (1.55, 0.0, "Quad", "In"), (1.6, 0.0015, "Quad", "Out"),
                                 (1.64, 0.0, "Quad", "In")]),
            ("Flame", "scale", [(0.0, 0.0), (0.55, 0.0), (0.6, 0.3, "Quad", "Out"), (0.75, 0.22),
                                (1.0, 0.42), (1.3, 0.36), (1.46, 0.4), (1.7, 0.6, "Quad", "Out"),
                                (2.3, 1.0, "Quad", "Out")]),
            ("Flame", "stretch", [(0.0, 1.0), (0.6, 0.8), (0.8, 1.15), (1.0, 0.85), (1.2, 1.1),
                                  (1.4, 0.9), (1.62, 1.35, "Quad", "Out"), (1.85, 0.95),
                                  (2.05, 1.08), (2.3, 0.97), (2.6, 1.0)]),
            ("Flame", "turn", [(0.0, 0.0), (0.6, 0.0), (0.8, 6.0), (1.0, -5.0), (1.2, 4.0),
                               (1.4, -3.0), (1.6, 0.5), (1.9, -0.6), (2.2, 0.0)]),
            ("Flame", "glow", [(0.0, 0.0), (0.55, 0.0), (0.6, 0.5, "Quad", "Out"), (0.75, 0.38),
                               (1.0, 0.55), (1.3, 0.48), (1.46, 0.52), (1.7, 0.7, "Quad", "Out"),
                               (2.3, 1.0, "Quad", "Out"), (2.6, 1.0)]),
            ("Wheel", "turn", [(0.0, 0.0), (1.7, 0.0), (2.3, OL_UP)])]),
        # burning: played on a loop; under a chimney the flame is steady, it only breathes
        "Burn": dict(duration=2.4, focus=OL_FLAME_LOOK, distance=0.2, tracks=[
            ("Flame", "scale", [(0.0, 1.0), (2.4, 1.0)]),
            ("Flame", "stretch", [(0.0, 1.0), (0.3, 1.035), (0.62, 0.975), (0.95, 1.02),
                                  (1.3, 0.985), (1.65, 1.03), (2.0, 0.98), (2.4, 1.0)]),
            ("Flame", "turn", [(0.0, 0.0), (0.4, 0.8), (0.9, -0.6), (1.4, 0.7), (1.9, -0.5),
                               (2.4, 0.0)]),
            ("Flame", "glow", [(0.0, 1.0), (0.3, 0.97), (0.62, 1.0), (0.95, 0.95), (1.3, 0.99),
                               (1.65, 0.96), (2.0, 1.0), (2.4, 1.0)])]),
        # the oil gone: the wick dries, the flame sinks, gutters twice and goes out
        "RunDown": dict(duration=4.0, focus=OL_FLAME_LOOK, distance=0.2, tracks=[
            ("Flame", "scale", [(0.0, 1.0), (1.4, 0.72), (2.2, 0.5), (2.6, 0.55), (3.0, 0.32),
                                (3.3, 0.38), (3.65, 0.0, "Quad", "In"), (4.0, 0.0)]),
            ("Flame", "stretch", [(0.0, 1.0), (1.4, 0.9), (2.2, 0.75), (2.4, 1.05), (2.6, 0.7),
                                  (3.0, 0.8), (3.2, 0.55), (3.65, 0.5)]),
            ("Flame", "turn", [(0.0, 0.0), (1.0, 1.2), (2.0, -1.5), (2.4, 2.5), (2.7, -2.0),
                               (3.1, 2.6), (3.4, -1.5), (3.65, 0.0)]),
            ("Flame", "glow", [(0.0, 1.0), (1.4, 0.74), (2.2, 0.5), (2.35, 0.62), (2.6, 0.46),
                               (3.0, 0.3), (3.3, 0.36), (3.65, 0.0, "Quad", "In"), (4.0, 0.0)])]),
    },
    dust=OLK["dust"], seed=OLK["seed"],
)

# --- the disco ball ----------------------------------------------------------------------------

(DB_PLASTIC, DB_UNDER, DB_FOOT, DB_SLIDER, DB_STEEL, DB_CUP, DB_GROUT, DB_BARE, DB_TILE,
 DB_TILE_B, DB_OLD, DB_GLINT, DB_EDGE, DB_PLATE) = range(87, 101)

DBB, DBL, DBK = K.DISCO_BASE, K.DISCO_BALL, K.DISCO
# the ball's middle, seated on the cup's rim
DB_Z = DBL["cup"]["z"] + math.sqrt(DBL["r"] ** 2 - DBL["cup"]["r"] ** 2)
DB_C = Vector((0.0, 0.0, DB_Z))
DB_PIVOT = (0.0, 0.0, DBB["collar"][1])       # the motor's shaft, where it leaves the base
DB_SW = DBB["switch"]
DB_SW_AT = (-DB_SW["travel"] / 2, -DBB["r"] - DB_SW["d"] / 2 + 0.006, DB_SW["z"])
I4 = Matrix()


def db_base_profile(hi):
    r = DBB["r"]
    b0, b1 = DBB["band"]
    dz, dr = DBB["dome"]
    kr, kz = DBB["collar"]
    prof = [(0.0, 0.004), (r - 0.02, 0.004), (r - 0.005, 0.006), (r, b0), (r, b1),
            (r - 0.004, b1 + 0.006)] + DBB["skirt"]
    # the dome, from just over its middle to the collar
    angs = range(10, 81, 4) if hi else (10, 24, 38, 51, 63, 74, 80)
    prof += [(dr * math.cos(math.radians(a)), dz + dr * math.sin(math.radians(a))) for a in angs]
    prof += [(kr + 0.0015, kz - 0.009), (kr, kz - 0.006), (kr, kz), (0.0, kz)]
    kinds = [DB_UNDER] + [DB_PLASTIC] * (len(prof) - 2)
    return prof, kinds


def db_base(hi):
    s = Shape()
    prof, kinds = db_base_profile(hi)
    s.lathe(prof, DB_PLASTIC, segs(hi, 40), kinds=kinds)
    ft = DBB["feet"]
    for i in range(ft["n"]):
        a = math.radians(90 + 360 * i / ft["n"])
        x, y = ft["at"] * math.cos(a), ft["at"] * math.sin(a)
        s.cylinder((x, y, 0.0), (x, y, 0.0045), ft["r"], DB_FOOT, segs(hi, 12))
    return s


def db_switch(hi):
    s = Shape()
    w, d, h = DB_SW["w"], DB_SW["d"], DB_SW["h"]
    x, y, z = DB_SW_AT
    s.box((x - w / 2, y - d / 2, z - h / 2), (x + w / 2, y + d / 2, z + h / 2), DB_SLIDER,
          chamfer=0.002, segs=2 if hi else 1)
    if hi:
        # the thumb grip: five ribs across its face
        for i in range(-2, 3):
            s.box((x + i * 0.0038 - 0.0007, y - d / 2 - 0.0014, z - h / 2 + 0.0025),
                  (x + i * 0.0038 + 0.0007, y - d / 2 + 0.001, z + h / 2 - 0.0025), DB_SLIDER)
    return s


def db_sphere(r, n):
    return [(r * math.sin(math.pi * i / n), DB_Z - r * math.cos(math.pi * i / n)) for i in range(n + 1)]


def db_dir(phi, lam):
    return Vector((math.cos(phi) * math.cos(lam), math.cos(phi) * math.sin(lam), math.sin(phi)))


def db_tile_list():
    """Every tile: (latitude, longitude, width, kind or None where it fell off, tilt, tilt)."""
    rng = random.Random(DBK["seed"])
    R, side, gap, rows = DBL["r"], DBL["tile"], DBL["gap"], DBL["rows"]
    pitch, dphi = side + gap, math.pi / rows
    cut = {-1: DBL["cup"]["r"] + 0.012, 1: DBL["plate"]["r"] + 0.006}
    out = []
    for i in range(rows):
        phi = -math.pi / 2 + (i + 0.5) * dphi
        rc = R * math.cos(phi)
        if rc - side / 2 < cut[1 if phi > 0 else -1]:
            continue
        n = int(2 * math.pi * rc / pitch)
        # sized to the row's edge nearer the pole, so neighbours never overlap there
        w = min(side, 2 * math.pi * R * math.cos(abs(phi) + dphi / 2) / n - gap * 0.6)
        off = rng.random() * 2 * math.pi
        for j in range(n):
            lam = off + 2 * math.pi * j / n
            u = rng.random()
            m, o, g = DBL["missing"], DBL["old"], DBL["glint"]
            if u < m:
                kind = None
            elif u < m + o:
                kind = DB_OLD
            elif u < m + o + g:
                kind = DB_GLINT
            else:
                kind = DB_TILE if rng.random() < 0.5 else DB_TILE_B
            out.append([phi, lam, w, kind, rng.gauss(0.0, DBL["tilt"]), rng.gauss(0.0, DBL["tilt"])])
    # a knock took out a little patch low on the front left, and one more on the right
    for c, reach in ((db_dir(-0.3, math.radians(-118)), 0.075), (db_dir(0.42, math.radians(-62)), 0.03)):
        for t in out:
            if db_dir(t[0], t[1]).dot(c) > math.cos(reach):
                t[3] = None
    return out


DB_TILES = db_tile_list()


def db_tiles(s):
    R, t, h = DBL["r"], DBL["t"], DBL["tile"]
    corners = ((-1, -1), (1, -1), (1, 1), (-1, 1))
    for phi, lam, w, kind, ta, tb in DB_TILES:
        n = db_dir(phi, lam)
        e_lon = Vector((-math.sin(lam), math.cos(lam), 0.0))
        e_lat = n.cross(e_lon)
        if kind is None:
            # the bare foam where it fell, the glue still on it
            c = DB_C + n * (DBL["core"] + 0.0006)
            s._f([s._v(c + e_lon * (a * w / 2) + e_lat * (b * h / 2), I4) for a, b in corners], DB_BARE)
            continue
        m = (n + e_lat * math.radians(ta) + e_lon * math.radians(tb)).normalized()
        el = (e_lon - m * e_lon.dot(m)).normalized()
        et = m.cross(el)
        c = DB_C + n * R
        top = [c + el * (a * w / 2) + et * (b * h / 2) for a, b in corners]
        vt = [s._v(p, I4) for p in top]
        vb = [s._v(p - m * t, I4) for p in top]
        s._f(vt, kind)
        for a in range(4):
            b = (a + 1) % 4
            s._f([vt[a], vb[a], vb[b], vt[b]], DB_EDGE)


def db_ball(hi):
    s = Shape()
    c, pl, rg = DBL["cup"], DBL["plate"], DBL["ring"]
    # the motor's shaft and the cup the ball sits in
    s.cylinder((0.0, 0.0, DBB["collar"][1] - 0.003), (0.0, 0.0, c["z"] - 0.01), c["shaft"], DB_STEEL,
               segs(hi, 10), caps=False)
    cup = [(0.0, c["z"] - 0.012), (c["shaft"] + 0.004, c["z"] - 0.012), (c["r"] - 0.008, c["z"] - 0.008),
           (c["r"], c["z"] - 0.003), (c["r"] + 0.0015, c["z"]), (c["r"] - 0.003, c["z"] + 0.0015)]
    s.lathe(cup, DB_CUP, segs(hi, 24))
    if hi:
        s.lathe(db_sphere(DBL["core"], 48), DB_GROUT, 96)
        db_tiles(s)
    else:
        s.lathe(db_sphere(DBL["r"], 24), DB_TILE, 48)
    # the hanging plate at the top pole, its eye and ring
    z0 = DB_Z + DBL["core"] - 0.002
    pt = z0 + pl["t"]
    s.lathe([(0.0, z0), (pl["r"], z0), (pl["r"], pt - 0.002), (pl["r"] - 0.003, pt), (0.0, pt)],
            DB_PLATE, segs(hi, 20))
    s.cylinder((0.0, 0.0, pt - 0.001), (0.0, 0.0, pt + 0.005), 0.007, DB_PLATE, segs(hi, 10))
    rr, wr = rg["r"], rg["wire"]
    m = segs(hi, 16)
    loop = [(rr * math.sin(2 * math.pi * i / m), 0.0, pt + 0.004 + rr - rr * math.cos(2 * math.pi * i / m))
            for i in range(m + 1)]
    s.tube(loop, wr, DB_PLATE, sides=segs(hi, 6), caps=False)
    return s


def db_look(L, f):
    nb = L.nb
    # the base: black ABS, a fine moulded grain, rubbed glossy round the band where hands lift it
    C = Coat(L, hexc("#141416"), nb.mr(L.noise(9.0, 1, detail=3), 0.3, 0.7, 0.36, 0.48), 0.0,
             nb.mul(L.noise(420.0, 2, detail=1), 0.08))
    plastic = L.k(DB_PLASTIC)
    band = nb.mul(plastic, nb.ss(L.z, 0.042, 0.032))
    rub = nb.mul(band, nb.ss(L.noise(14.0, 3, stretch=(1.0, 1.0, 5.0), detail=3), 0.55, 0.7))
    C.paint(rub, hexc("#262628"), 0.2)
    scratch = nb.mul(plastic, nb.ss(L.noise(60.0, 4, stretch=(1.0, 1.0, 9.0), detail=2, rough=0.8),
                                    0.72, 0.76))
    C.paint(scratch, hexc("#3A3A3C"), 0.3, height=nb.mul(scratch, -0.3))
    # the switch's slot in the front of the band; the DC jack in the back
    sw = DB_SW
    slot = nb.mul(nb.mul(band, nb.ss(L.y, -0.2, -0.25)),
                  nb.mul(nb.ss(nb.absf(L.x), sw["slot"], sw["slot"] - 0.002),
                         nb.ss(nb.absf(nb.sub(L.z, sw["z"])), sw["h"] / 2 + 0.002, sw["h"] / 2)))
    C.paint(slot, hexc("#050505"), 0.9, height=nb.mul(slot, -1.0))
    jk = DBB["jack"]
    jr = nb.pw(nb.add(nb.mul(L.x, L.x), nb.mul(nb.sub(L.z, jk["z"]), nb.sub(L.z, jk["z"]))), 0.5)
    back = nb.mul(band, nb.ss(L.y, 0.2, 0.25))
    hole = nb.mul(back, nb.ss(jr, jk["r"], jk["r"] - 0.0015))
    C.paint(hole, hexc("#070707"), 0.8, height=nb.mul(hole, -1.0))
    C.paint(nb.mul(back, nb.ss(jr, 0.0022, 0.0012)), hexc("#9C9A94"), 0.3, 1.0)
    # underneath: the battery door's seam and its screw, the rubber feet
    un = L.k(DB_UNDER)
    door = nb.mul(nb.ss(nb.absf(L.x), 0.125, 0.12), nb.ss(nb.absf(L.y), 0.075, 0.07))
    seam = nb.mul(un, nb.sub(door, nb.mul(nb.ss(nb.absf(L.x), 0.12, 0.115),
                                          nb.ss(nb.absf(L.y), 0.07, 0.065)), clamp=True))
    C.paint(seam, hexc("#050505"), 0.9, height=nb.mul(seam, -0.8))
    sr = nb.pw(nb.add(nb.mul(L.x, L.x), nb.mul(nb.sub(L.y, 0.05), nb.sub(L.y, 0.05))), 0.5)
    C.paint(nb.mul(un, nb.ss(sr, 0.008, 0.006)), hexc("#77746E"), 0.35, 1.0)
    C.paint(L.k(DB_FOOT), hexc("#1E1D1C"), 0.75, 0.0)
    C.paint(L.k(DB_SLIDER), hexc("#202022"), 0.42, 0.0)
    C.paint(L.k(DB_CUP), hexc("#18181A"), 0.4, 0.0)
    st = L.k(DB_STEEL, DB_PLATE)
    C.paint(st, hexc("#A8ABAE"), nb.mr(L.noise(30.0, 5, detail=3), 0.3, 0.7, 0.22, 0.38), 1.0)
    C.paint(nb.mul(st, nb.ss(L.noise(45.0, 6, detail=4, rough=0.7), 0.62, 0.7)), hexc("#6B4A30"), 0.8, 0.1)
    # the ball: grey grout in the gaps, bare foam and old glue where tiles fell
    C.paint(L.k(DB_GROUT), hexc("#4A4945"), 0.85, 0.0)
    bare = L.k(DB_BARE)
    glue = nb.ss(L.noise(70.0, 7, detail=4, rough=0.6), 0.45, 0.62)
    C.paint(bare, nb.mixc(glue, hexc("#8C8981"), hexc("#6A5D45")), 0.88, 0.0,
            nb.mul(bare, nb.mul(glue, 0.8)))
    # the mirror tiles: silvered glass, two batches a shade apart, the odd one dark at the back
    C.paint(L.k(DB_TILE, DB_GLINT), hexc("#DCDEE0"), 0.045, 1.0)
    C.paint(L.k(DB_TILE_B), hexc("#CDD0D3"), 0.08, 1.0)
    old = L.k(DB_OLD)
    C.paint(old, hexc("#BFC0BE"), 0.12, 1.0)
    rot = nb.mul(old, nb.ss(L.noise(55.0, 8, detail=5, rough=0.65), 0.42, 0.56))
    C.paint(rot, hexc("#34322D"), 0.45, 0.4)
    C.paint(L.k(DB_EDGE), hexc("#33413C"), 0.2, 0.0)
    # handled: smeared fingermarks round its middle, where hands turn it
    tiles = L.k(DB_TILE, DB_TILE_B, DB_GLINT, DB_OLD)
    belt = nb.mul(nb.ss(nb.absf(nb.sub(L.z, DB_Z)), 0.22, 0.08), nb.ss(L.noise(8.0, 9, detail=4), 0.58, 0.7))
    C.paint(nb.mul(tiles, belt), rough=0.22)
    # spinning in a light: a scatter of tiles flash, the rest a faint sheen
    C.lights(L.k(DB_GLINT))
    # dust: the ball's top greyed; the base wiped more often than the ball (half as much)
    C.finish(f.dust, grime=0.4, keep=nb.mul(L.k(DB_PLASTIC, DB_UNDER, DB_FOOT), 0.55))
    return C.surface(bump_dist=0.0008, bump=0.4)


DB_DEG_S = DBK["rpm"] * 6.0          # degrees a second at speed
DB_T = DB_SW["travel"]
DB_CLICK = 0.12                       # the slide clicks over and the motor starts
DB_UP = 1.0                           # seconds the ball takes to come up to speed
DB_A0 = DB_DEG_S * DB_UP / 2          # degrees it turns getting there
DB_LEN = 2.4
DB_END = DB_A0 + DB_DEG_S * (DB_LEN - DB_CLICK - DB_UP)
DB_ON = [(0.0, 0.0), (0.07, DB_T * 0.3, "Quad", "In"), (0.1, DB_T + 0.0015, "Quad", "Out"),
         (0.16, DB_T)]
DB_OFF = [(0.0, DB_T), (0.07, DB_T * 0.7, "Quad", "In"), (0.1, -0.0015, "Quad", "Out"), (0.16, 0.0)]
# the spots: (degrees round from +X, degrees up), six evenly round, each at its own height, so a
# ball on the floor sweeps the walls in bands
DB_SPOTS = [(0.0, 13.0), (60.0, 30.0), (120.0, 6.0), (180.0, 22.0), (240.0, 38.0), (300.0, 9.0)]


def db_spot(az, el):
    d = db_dir(math.radians(el), math.radians(az))
    return dict(kind="Spot", part="Ball", at=tuple(DB_C + d * (DBL["r"] + 0.012)), face=tuple(d),
                kelvin=DBK["kelvin"], brightness=1.2, range=14, angle=4, shadows=False,
                preview_watts=400.0, preview_blend=0.08)


DB_LOOK = (0.0, 0.0, 0.62)
DISCO_BALL = kit.Find(
    "DiscoBall",
    [kit.Part("Base", db_base),
     kit.Part("Ball", db_ball, DB_PIVOT, "Base", (0, 0, 1)),
     kit.Part("Switch", db_switch, DB_SW_AT, "Base", (1, 0, 0))],
    db_look,
    lights=[db_spot(az, el) for az, el in DB_SPOTS] + [
        # the ball's own sheen: weak, so the dots are what you see
        dict(kind="Point", part="Ball", at=tuple(DB_C), kelvin=DBK["kelvin"], brightness=0.25,
             range=6, shadows=False, preview_kind="POINT", preview_watts=1.5, preview_size=0.1)],
    glow=dict(part="Ball", strength=2.0, tint=(225, 232, 255), preview=6.0),
    lit={("Switch", "move"): DB_T},
    texels=520,
    motions={
        # the slide clicks over, the spots come on, the ball takes a second to come up to five
        # turns a minute (a geared motor and the ball's weight)
        "Spin": dict(duration=DB_LEN, focus=DB_LOOK, distance=1.0, tracks=[
            ("Switch", "move", DB_ON),
            ("Ball", "turn", [(0.0, 0.0), (DB_CLICK, 0.0, "Linear"), (DB_CLICK + DB_UP, DB_A0, "Quad", "In"),
                              (DB_LEN, DB_END, "Linear")]),
            ("Ball", "glow", [(0.0, 0.0), (DB_CLICK, 0.0, "Linear"), (DB_CLICK + 0.08, 1.0, "Quad", "Out")])]),
        # spinning: a loop from where Spin ends; one turn in 12 s comes back to the same place
        "Spinning": dict(duration=12.0, fps=4, focus=DB_LOOK, distance=1.0, tracks=[
            ("Switch", "move", [(0.0, DB_T), (12.0, DB_T)]),
            ("Ball", "turn", [(0.0, DB_END), (12.0, DB_END + 360.0, "Linear")]),
            ("Ball", "glow", [(0.0, 1.0), (12.0, 1.0)])]),
        # slid off: the motor stops, the ball's weight carries it a few degrees on in its cup and
        # it rocks back a touch (the game adds where the ball stood)
        "SpinDown": dict(duration=1.2, focus=DB_LOOK, distance=1.0, tracks=[
            ("Switch", "move", DB_OFF),
            ("Ball", "turn", [(0.0, DB_END), (0.1, DB_END + DB_DEG_S * 0.1, "Linear"),
                              (0.36, DB_END + 5.0, "Quad", "Out"), (0.64, DB_END + 4.2),
                              (0.92, DB_END + 4.55), (1.2, DB_END + 4.45)]),
            ("Ball", "glow", [(0.0, 1.0), (0.1, 1.0, "Linear"), (0.2, 0.0, "Quad", "Out")])]),
    },
    dust=DBK["dust"], seed=DBK["seed"],
)

# --- the neon OPEN sign ------------------------------------------------------------------------

(NE_ACRYLIC, NE_PINK, NE_AQUA, NE_BLOCK, NE_BOOT, NE_POST, NE_BOX, NE_TOGGLE, NE_CORD, NE_PLUG,
 NE_PRONG, NE_EYE) = range(101, 113)

NE = K.NEON
NE_TY, NE_R = NE["ty"], NE["r"]
NE_BX = NE["box"]
NE_TOG_AT = (NE["toggle"]["x"], sum(NE_BX["y"]) / 2, NE_BX["z"] + 0.012)


def ne_round(pts, rad, n=5, closed=False):
    """A polyline in (x, z) with its corners rounded (a curve through each corner's two
    tangent points), as 3D points in the tubes' plane."""
    P = [Vector(p) for p in pts]
    m = len(P)
    out = []
    for i in range(m):
        if not closed and i in (0, m - 1):
            out.append(P[i])
            continue
        a, b, c = P[i - 1], P[i], P[(i + 1) % m]
        u, v = a - b, c - b
        t = min(rad, u.length * 0.45, v.length * 0.45)
        p0, p1 = b + u.normalized() * t, b + v.normalized() * t
        for k in range(n + 1):
            s = k / n
            out.append(p0 * (1 - s) ** 2 + b * (2 * s * (1 - s)) + p1 * s * s)
    if closed:
        out.append(out[0])
    return [Vector((q.x, NE_TY, q.y)) for q in out]


def ne_paths():
    """Each tube: (its points, its kind, whether its ends bend back through the backing)."""
    L = NE["letters"]
    z0, z1 = L["z0"], L["z1"]
    zm = (z0 + z1) / 2
    w = L["widths"]
    xs = [-(sum(w) + 3 * L["gap"]) / 2]
    for k in range(3):
        xs.append(xs[-1] + w[k] + L["gap"])
    out = []
    # O: a squared-off oval, its two ends side by side at the bottom
    a, b, cx = w[0] / 2, (z1 - z0) / 2, xs[0] + w[0] / 2
    o = []
    for k in range(49):
        t = math.radians(-90 + 7 + (360 - 14) * k / 48)
        ct, st = math.cos(t), math.sin(t)
        o.append(Vector((cx + a * math.copysign(abs(ct) ** 0.75, ct), NE_TY,
                         zm + b * math.copysign(abs(st) ** 0.75, st))))
    out.append((o, NE_PINK))
    # P: up the stem, round the bowl, back to the stem
    x0, x1 = xs[1], xs[1] + w[1]
    out.append((ne_round([(x0, z0), (x0, z1), (x1 - 0.07, z1), (x1, z1 - 0.07), (x1, zm + 0.08),
                          (x1 - 0.07, zm), (x0 + 0.035, zm)], 0.06), NE_PINK))
    # E: top, stem and foot in one bend; the middle bar its own short tube
    x0, x1 = xs[2], xs[2] + w[2]
    out.append((ne_round([(x1, z1), (x0, z1), (x0, z0), (x1, z0)], 0.05), NE_PINK))
    out.append((ne_round([(x0 + 0.04, zm), (x1 - 0.04, zm)], 0.0), NE_PINK))
    # N: up, the diagonal down, up
    x0, x1 = xs[3], xs[3] + w[3]
    out.append((ne_round([(x0, z0), (x0, z1), (x1, z0), (x1, z1)], 0.04), NE_PINK))
    # the border: a rounded rectangle, its ends meeting at the bottom middle
    B = NE["border"]
    g0, g1 = B["gap"]
    hw = B["hw"]
    pts = [(g1, B["z0"]), (hw, B["z0"]), (hw, B["z1"]), (-hw, B["z1"]), (-hw, B["z0"]), (g0, B["z0"])]
    out.append((ne_round(pts, B["rad"], n=6), NE_AQUA))
    return out, xs


NE_PATHS, NE_XS = ne_paths()


def ne_leg(s, p, d, hi):
    """A tube's end bent back through the backing, blacked out, into its rubber boot."""
    rb = 0.035
    pts = [p + d * (rb * math.sin(math.pi / 2 * k / 6)) + Vector((0.0, rb * (1 - math.cos(math.pi / 2 * k / 6)), 0.0))
           for k in range(7)]
    pts.append(Vector((pts[-1].x, 0.004, pts[-1].z)))
    s.tube([tuple(q) for q in pts], NE_R, NE_BLOCK, sides=segs(hi, 8), caps=False)
    q = pts[-1]
    s.lathe([(0.0, -0.052), (0.024, -0.052), (0.03, -0.042), (0.031, -0.004), (0.036, 0.0)],
            NE_BOOT, segs(hi, 12), Matrix.Translation((q.x, 0.0, q.z)) @ Matrix.Rotation(math.radians(-90), 4, "X"))


def ne_chunks(pts, most=1.0):
    """A long tube cut into runs of at most `most` studs, sharing their end points, so no strip
    is too long to pack (the border's 6 studs shrank the whole texture to 195 texels a stud).
    The tubes lie flat in one plane, so each run's rings line up with the last's."""
    out, run, d = [], [pts[0]], 0.0
    for a, b in zip(pts, pts[1:]):
        run.append(b)
        d += (b - a).length
        if d > most:
            out.append(run)
            run, d = [b], 0.0
    if len(run) > 1:
        out.append(run)
    return out


def ne_tubes(hi):
    s = Shape()
    for pts, kind in NE_PATHS:
        for run in ne_chunks(pts):
            s.tube([tuple(q) for q in run], NE_R, kind, sides=segs(hi, 8), caps=False)
        for end, nxt in ((pts[0], pts[1]), (pts[-1], pts[-2])):
            if (end - nxt).length > 1e-6 and (pts[0] - pts[-1]).length > 1e-4:
                ne_leg(s, end, (end - nxt).normalized(), hi)
    return s


def ne_backing(hi):
    s = Shape()
    w, h, t = NE["w"], NE["h"], NE["t"]
    s.box((-w / 2, 0.0, 0.0), (w / 2, t, h), NE_ACRYLIC, chamfer=0.006, segs=2 if hi else 1)
    # the clear posts the tubes stand on
    L = NE["letters"]
    zm = (L["z0"] + L["z1"]) / 2
    xs, wd = NE_XS, L["widths"]
    B = NE["border"]
    posts = [(xs[0], zm), (xs[0] + wd[0], zm), (xs[1], L["z0"] + 0.13), (xs[1] + wd[1], zm + 0.14),
             (xs[2], zm - 0.15), (xs[2], zm + 0.15), (xs[3], zm), (xs[3] + wd[3], zm)]
    posts += [(sx * B["hw"], zm) for sx in (-1, 1)] + [(sx * 0.6, z) for sx in (-1, 1) for z in (B["z0"], B["z1"])]
    for x, z in posts:
        s.lathe([(0.0, NE_TY + NE_R * 0.6), (0.0085, NE_TY + NE_R * 0.6), (0.0085, -0.006),
                 (0.016, -0.004), (0.017, 0.0)], NE_POST, segs(hi, 10),
                Matrix.Translation((x, 0.0, z)) @ Matrix.Rotation(math.radians(-90), 4, "X"))
    # the transformer box behind, its switch's bushing and nut
    bx = NE_BX
    s.box((-bx["x"], bx["y"][0], 0.0), (bx["x"], bx["y"][1], bx["z"]), NE_BOX, chamfer=0.005,
          segs=2 if hi else 1)
    tx, ty, tz = NE_TOG_AT
    s.cylinder((tx, ty, bx["z"] - 0.002), (tx, ty, bx["z"] + 0.006), 0.017, NE_EYE, 6)
    s.cylinder((tx, ty, bx["z"] + 0.006), (tx, ty, tz), 0.01, NE_EYE, segs(hi, 12))
    # the cord out of the box's left end, lying on the floor to its plug
    cord = [(-bx["x"] + 0.004, 0.1, 0.06), (-bx["x"] - 0.05, 0.1, 0.045), (-bx["x"] - 0.11, 0.115, 0.014),
            (-0.5, 0.2, 0.012), (-0.68, 0.19, 0.012), (-0.8, 0.1, 0.012)]
    s.tube(spline(cord, 4 if hi else 2), 0.012, NE_CORD, sides=segs(hi, 8))
    a, b = Vector(cord[-2]), Vector(cord[-1])
    yaw = math.atan2(b.y - a.y, b.x - a.x)
    M = Matrix.Translation((b.x, b.y, 0.0)) @ Matrix.Rotation(yaw, 4, "Z")
    s.box((0.0, -0.022, 0.0), (0.06, 0.022, 0.026), NE_PLUG, chamfer=0.006, segs=2 if hi else 1, M=M)
    for py in (-0.0125, 0.0125):
        s.box((0.06, py - 0.001, 0.008), (0.1, py + 0.001, 0.02), NE_PRONG, M=M)
    # the hanging eyes on the top edge
    for sx in (-1, 1):
        x = sx * NE["eyes"]
        s.cylinder((x, t / 2, h - 0.002), (x, t / 2, h + 0.012), 0.004, NE_EYE, segs(hi, 8))
        m = segs(hi, 12)
        loop = [(x + 0.018 * math.sin(2 * math.pi * k / m), t / 2, h + 0.012 + 0.018 - 0.018 * math.cos(2 * math.pi * k / m))
                for k in range(m + 1)]
        s.tube(loop, 0.0035, NE_EYE, sides=segs(hi, 6), caps=False)
    return s


def ne_toggle(hi):
    s = Shape()
    tx, ty, tz = NE_TOG_AT
    tg = NE["toggle"]
    M = Matrix.Translation(NE_TOG_AT) @ Matrix.Rotation(math.radians(-tg["lean"]), 4, "X")
    n = segs(hi, 10)
    ln = tg["len"]
    s.lathe([(0.0, -0.004), (0.0055, -0.004), (0.0065, 0.01), (0.0048, ln - 0.008), (0.0058, ln - 0.004),
             (0.0045, ln), (0.0, ln + 0.0015)], NE_TOGGLE, n, M)
    return s


def ne_look(L, f):
    nb = L.nb
    # the backing: black acrylic, glossy, hairline scratches, a bloom of scuffs low down
    C = Coat(L, hexc("#0A0A0B"), nb.mr(L.noise(6.0, 1, detail=3), 0.3, 0.7, 0.08, 0.16), 0.0)
    ac = L.k(NE_ACRYLIC)
    hair = nb.mul(ac, nb.ss(L.noise(90.0, 2, stretch=(1.0, 1.0, 14.0), detail=2, rough=0.8), 0.74, 0.77))
    C.paint(hair, hexc("#2C2C2E"), 0.3, height=nb.mul(hair, -0.2))
    scuff = nb.mul(nb.mul(ac, nb.ss(L.z, 0.25, 0.05)), nb.ss(L.noise(12.0, 3, detail=4), 0.55, 0.68))
    C.paint(scuff, hexc("#1C1C1E"), 0.45)
    # the tubes: coloured glass, the pink a little faded on the tops where light hit them
    # (saturated: the glow is this colour times its strength, and a pale one burns white)
    C.paint(L.k(NE_PINK), hexc("#DE4C98"), 0.12, 0.0)
    C.paint(nb.mul(L.k(NE_PINK), nb.mul(L.up, 0.35)), hexc("#E57AB2"))
    C.paint(L.k(NE_AQUA), hexc("#3FC4D2"), 0.12, 0.0)
    # blockout paint on the bends back, flaking at the bend where the glass shows
    bl = L.k(NE_BLOCK)
    C.paint(bl, hexc("#121212"), 0.55, 0.0)
    C.paint(nb.mul(bl, nb.ss(L.noise(80.0, 4, detail=3), 0.66, 0.72)), hexc("#B7A6AE"), 0.15, 0.0)
    C.paint(L.k(NE_BOOT), hexc("#141414"), 0.72, 0.0)
    C.paint(L.k(NE_POST), hexc("#3E4447"), 0.18, 0.0)
    # the transformer box: black crinkle paint, rust coming through at its edges
    bx = L.k(NE_BOX)
    C.paint(bx, hexc("#1B1C1D"), 0.62, 0.3, nb.mul(bx, nb.mul(L.noise(260.0, 5, detail=2), 0.25)))
    C.enamel_wear(bx, hexc("#5A3B26"), s=6, amount=1.2)
    C.paint(L.k(NE_TOGGLE), hexc("#C3C5C7"), 0.18, 1.0)
    eye = L.k(NE_EYE)
    C.paint(eye, hexc("#9EA1A3"), 0.35, 1.0)
    C.paint(nb.mul(eye, nb.ss(L.noise(40.0, 6, detail=4), 0.6, 0.68)), hexc("#6A4630"), 0.8, 0.1)
    C.paint(L.k(NE_CORD), hexc("#111111"), 0.5, 0.0)
    C.paint(L.k(NE_PLUG), hexc("#151515"), 0.45, 0.0)
    C.paint(L.k(NE_PRONG), hexc("#B9B4A6"), 0.3, 1.0)
    C.lights(L.k(NE_PINK, NE_AQUA))
    C.finish(f.dust, grime=0.5)
    return C.surface(bump_dist=0.0008, bump=0.4)


NE_LEAN = 2.0 * NE["toggle"]["lean"]
NE_FLIP = [(0.0, 0.0), (0.05, NE_LEAN * 0.35, "Quad", "In"), (0.08, NE_LEAN + 3.0, "Quad", "Out"),
           (0.14, NE_LEAN)]
NE_FLOP = [(0.0, NE_LEAN), (0.05, NE_LEAN * 0.65, "Quad", "In"), (0.08, -3.0, "Quad", "Out"), (0.14, 0.0)]
NE_LOOK = (0.0, -0.1, 0.5)
NEON_SIGN = kit.Find(
    "NeonSign",
    [kit.Part("Backing", ne_backing),
     kit.Part("Tubes", ne_tubes, (0.0, NE_TY, 0.5), "Backing"),
     kit.Part("Toggle", ne_toggle, NE_TOG_AT, "Backing", (1, 0, 0))],
    ne_look,
    lights=[
        # the pink spill on whatever is in front of it; no shadows, so it lights the room round
        dict(kind="Point", part="Tubes", at=(0.0, -0.45, 0.5), rgb=(255, 92, 182), brightness=0.6,
             range=10, shadows=False, preview_kind="POINT", preview_watts=10.0, preview_size=0.4)],
    glow=dict(part="Tubes", strength=2.5, tint=(255, 255, 255), preview=4.5),
    lit={("Toggle", "turn"): NE_LEAN},
    motions={
        # the toggle snaps over and the tubes strike: a stutter of half-lit flashes as the gas
        # catches, then the full glow, a last dip, steady
        "SwitchOn": dict(duration=1.4, focus=NE_LOOK, distance=0.9, tracks=[
            ("Toggle", "turn", NE_FLIP),
            ("Tubes", "glow", [(0.0, 0.0), (0.08, 0.0, "Linear"), (0.1, 0.7, "Linear"), (0.14, 0.05, "Linear"),
                               (0.26, 0.05, "Linear"), (0.28, 0.9, "Linear"), (0.32, 0.3, "Linear"),
                               (0.36, 0.85, "Linear"), (0.5, 0.75), (0.53, 1.0, "Linear"), (0.7, 0.9),
                               (0.82, 1.0), (1.4, 1.0)])]),
        # on: played on a loop with the buzz; the glow only shivers
        "Buzz": dict(duration=2.0, focus=NE_LOOK, distance=0.9, tracks=[
            ("Tubes", "glow", [(0.0, 1.0), (0.4, 0.97), (0.55, 1.0), (1.1, 0.98), (1.3, 0.94, "Linear"),
                               (1.34, 1.0, "Linear"), (2.0, 1.0)])]),
        # snapped off: the glow drops at once, the pink's coating a breath behind
        "SwitchOff": dict(duration=0.7, focus=NE_LOOK, distance=0.9, tracks=[
            ("Toggle", "turn", NE_FLOP),
            ("Tubes", "glow", [(0.0, 1.0), (0.07, 1.0, "Linear"), (0.09, 0.18, "Linear"),
                               (0.45, 0.0, "Quad", "Out")])]),
    },
    dust=NE["dust"], seed=NE["seed"],
)

# --- the miner's hard hat ------------------------------------------------------------------------

(HH_SHELL, HH_INSIDE, HH_BAND, HH_LEATHER, HH_STEEL, HH_RIVET, HH_LAMP, HH_CHROME, HH_REFL,
 HH_BULB, HH_LENS, HH_LENS_IN, HH_KNOB, HH_CORD, HH_CASE, HH_LID, HH_PLATE, HH_SPRING, HH_BRASS,
 HH_UNDER) = range(113, 133)
HH, HB, HL, HC, HP = K.HARD_HAT, K.HAT_BRACKET, K.CAP_LAMP, K.HAT_CORD, K.HAT_BATTERY
HH_V = HH["visor"]
HH_TAN = math.tan(math.radians(HH_V["slope"]))


def hh_ss(a, b, x):
    """0 below a, 1 past b, smooth between (a > b runs it the other way)."""
    u = min(1.0, max(0.0, (x - a) / (b - a)))
    return u * u * (3 - 2 * u)


def hh_R(a):
    """The dome's foot: its distance from the middle at azimuth a (radians from +X, anticlockwise
    from above; the front is -90 degrees)."""
    c, s = abs(math.cos(a)), abs(math.sin(a))
    m = HH["mh"]
    return ((c / HH["A"]) ** m + (s / HH["B"]) ** m) ** (-1.0 / m)


def hh_peak(a):
    """How far the peak reaches out past the flare at azimuth a: most at the front, rounding off
    to nothing at the span's ends."""
    d = abs((a + math.pi / 2 + math.pi) % (2 * math.pi) - math.pi)
    span = math.radians(HH_V["span"])
    if d >= span:
        return 0.0
    return HH_V["len"] * math.cos(0.5 * math.pi * d / span) ** 1.5


def hh_lipz(a):
    """The lip's underside over the floor: on the floor front and back, up over the ears."""
    return HH["side_lift"] * (1.0 + math.cos(2 * a)) / 2


def hh_zb(a):
    """The dome's foot over the floor: the flare and the peak droop from it to the lip."""
    return hh_lipz(a) + HH["zb"] + hh_peak(a) * HH_TAN


def hh_rs(a, z, inner=False):
    """The dome's distance from the middle at azimuth a and height z (no crest)."""
    t = HH["wall"] if inner else 0.0
    z0 = hh_zb(a) + (0.004 if inner else HH["lip"])
    u = min(1.0, max(0.0, (z - z0) / (HH["crown"] - t - z0)))
    mv = HH["mv"]
    sphi = u ** (mv / 2)
    cphi = math.sqrt(max(0.0, 1.0 - sphi * sphi))
    return (hh_R(a) - t) * cphi ** (2 / mv)


def hh_F(p):
    """Positive outside the dome, negative inside."""
    a = math.atan2(p[1], p[0])
    return math.hypot(p[0], p[1]) - hh_rs(a, p[2])


def hh_n(p):
    e = 1e-4
    g = Vector(((hh_F((p[0] + e, p[1], p[2])) - hh_F((p[0] - e, p[1], p[2]))),
                (hh_F((p[0], p[1] + e, p[2])) - hh_F((p[0], p[1] - e, p[2]))),
                (hh_F((p[0], p[1], p[2] + e)) - hh_F((p[0], p[1], p[2] - e)))))
    return g.normalized()


def hh_on(x, z, side=-1):
    """The dome's surface at (x, z), on its front (side -1) or back (+1)."""
    lo, hi = 0.0, side * 1.0
    for _ in range(40):
        m = (lo + hi) / 2
        if hh_F((x, m, z)) > 0:
            hi = m
        else:
            lo = m
    return Vector((x, (lo + hi) / 2, z))


def hh_top(x, y):
    """The dome's surface over the plan point (x, y)."""
    lo, hi = 0.0, HH["crown"] + 0.01
    for _ in range(40):
        m = (lo + hi) / 2
        if hh_F((x, y, m)) > 0:
            hi = m
        else:
            lo = m
    return Vector((x, y, (lo + hi) / 2))


def hh_crest(p):
    """The crest's rise at an outer dome point: a ridge along the middle, fading out above the
    bracket on the front and above the cord clip on the back."""
    c = HH["crest"]
    fade = hh_ss(0.455, 0.52, p[2]) if p[1] < 0 else hh_ss(0.36, 0.46, p[2])
    return c["h"] * math.exp(-(p[0] / c["w"]) ** 2) * fade


def hh_shell(hi):
    s = Shape()
    n = 256 if hi else 72
    nd = 44 if hi else 14
    f = 3 if hi else 1
    mv, t, er = HH["mv"], HH["wall"], HH["edge"]
    inner, outer = [], []
    for j in range(n):
        a = 2 * math.pi * j / n
        R, zb, zl = hh_R(a), hh_zb(a), hh_lipz(a)
        e = HH["flare"] + hh_peak(a)
        ca, sa = math.cos(a), math.sin(a)
        # the inside, from the top of the hollow down to its foot
        col = []
        for i in range(nd, -1, -1):
            sp = math.sin(0.5 * math.pi * i / nd)
            cp = math.cos(0.5 * math.pi * i / nd)
            r = (R - t) * cp ** (2 / mv)
            z = zb + 0.004 + (HH["crown"] - t - zb - 0.004) * sp ** (2 / mv)
            col.append((r, z))
        inner.append([(r * ca, r * sa, z) for r, z in col])
        # under the lip, round its rolled edge, back over its top and up the dome
        prof = [(R - t, zb + 0.004), (R - t + 0.35 * e, zb - 0.45 * (zb - zl) - 0.002),
                (R + e - er - 0.25 * e, zl + 0.002 + 0.12 * (zb - zl)), (R + e - er, zl)]
        prof += fillet(R + e - er, zl + er, er, (-90, 90), 3 * f)[1:]
        prof += [(R + 0.55 * e, zl + 2 * er + 0.5 * (zb - zl) + 0.001),
                 (R + 0.012, zb + HH["lip"] - 0.001)]
        for i in range(nd + 1):
            sp = math.sin(0.5 * math.pi * i / nd)
            cp = math.cos(0.5 * math.pi * i / nd)
            prof.append((R * cp ** (2 / mv), zb + HH["lip"] + (HH["crown"] - zb - HH["lip"]) * sp ** (2 / mv)))
        ring = []
        for k, (r, z) in enumerate(prof):
            p = Vector((r * ca, r * sa, z))
            if k >= len(prof) - nd - 1 and r > 1e-6:
                p = p + hh_n(p) * hh_crest(p)
            ring.append(p)
        outer.append(ring)
    # columns to rings; the poles collapse to one point
    rings_in = [[tuple(c[i]) for c in inner] for i in range(len(inner[0]))]
    rings_in[0] = [(0.0, 0.0, inner[0][0][2])]
    rings_out = [[tuple(c[i]) for c in outer] for i in range(len(outer[0]))]
    rings_out[-1] = [(0.0, 0.0, outer[0][-1][2] + HH["crest"]["h"])]
    s.loft(rings_in, HH_INSIDE)
    s.loft(rings_out, HH_SHELL)
    # the suspension's headband, a strap just inside the rim
    b = HH["band"]
    rings = []
    for z, d in ((b["z"], 0.0), (b["z"], b["t"]), (b["z"] + b["h"], b["t"]), (b["z"] + b["h"], 0.0)):
        rings.append([((hh_R(2 * math.pi * j / n) - t - 0.004 - d) * math.cos(2 * math.pi * j / n),
                       (hh_R(2 * math.pi * j / n) - t - 0.004 - d) * math.sin(2 * math.pi * j / n),
                       z + hh_zb(2 * math.pi * j / n) - HH["zb"]) for j in range(0, n, 2)])
    s.loft(rings, HH_BAND)
    # the suspension's lugs, moulded buttons either side
    lg = HH["lugs"]
    for sx in (-1, 1):
        lo, hi_ = 0.0, sx * 1.0
        for _ in range(40):
            m = (lo + hi_) / 2
            if hh_F((m, lg["y"], lg["z"])) > 0:
                hi_ = m
            else:
                lo = m
        p = Vector(((lo + hi_) / 2, lg["y"], lg["z"]))
        hh_rivet(s, p, hh_n(p), lg["r"], 0.012, HH_RIVET, hi, sink=0.006)
    return s


def hh_frame(p, n):
    """A matrix at p with its Z along n."""
    return Matrix.Translation(p) @ Vector((0, 0, 1)).rotation_difference(n).to_matrix().to_4x4()


def hh_rivet(s, p, n, r, h, kind, hi, sink=0.003):
    """A domed rivet head on a surface at p, normal n."""
    f = 3 if hi else 1
    prof = [(0.0, -sink), (r, -sink), (r, 0.0)] + [
        (r * math.cos(math.radians(a)), h * math.sin(math.radians(a))) for a in
        [90.0 * i / (4 * f) for i in range(1, 4 * f + 1)]]
    prof[-1] = (0.0, h)
    s.lathe(prof, kind, segs(hi, 12), hh_frame(p, n))


def hh_strap(s, pts, ups, w, t, kind, hi, n=4.0):
    """A flat strap swept along pts (its face toward ups), its section a rounded rectangle, its
    ends closed flat."""
    m = 20 if hi else 8
    rings = []
    P = [Vector(p) for p in pts]
    for i, p in enumerate(P):
        T = (P[min(i + 1, len(P) - 1)] - P[max(i - 1, 0)]).normalized()
        u = Vector(ups[i])
        u = (u - T * u.dot(T)).normalized()
        sd = u.cross(T)
        ring = []
        for j in range(m):
            th = 2 * math.pi * j / m
            c, si = math.cos(th), math.sin(th)
            ring.append(tuple(p + sd * (w / 2 * math.copysign(abs(c) ** (2 / n), c))
                              + u * (t / 2 * math.copysign(abs(si) ** (2 / n), si))))
        rings.append(ring)
    end = P[-1]
    rings.append([tuple(end + (Vector(q) - end) * 0.5) for q in rings[-1]])
    rings.append([tuple(end)])
    s.loft(rings, kind, cap_bottom=kind)


def hh_outline(hi):
    """The leather bracket's outline, anticlockwise seen from the front (x right, z up)."""
    half = HB["outline"]
    pts = [(-x, z) for x, z in reversed(half[:-1])] + [(x, z) for x, z in half]
    # start at the point, go up the right side, across the top, down the left
    pts = pts[len(half) - 1:] + pts[:len(half) - 1]
    pts = [(x, 0.0, z) for x, z in pts] + [(pts[0][0], 0.0, pts[0][1])]
    sm = spline(pts, 12)
    # resample evenly
    L = [0.0]
    for a, b in zip(sm, sm[1:]):
        L.append(L[-1] + (Vector(b) - Vector(a)).length)
    m = 120 if hi else 40
    out = []
    k = 0
    for i in range(m):
        d = L[-1] * i / m
        while L[k + 1] < d:
            k += 1
        u = (d - L[k]) / max(1e-9, L[k + 1] - L[k])
        q = Vector(sm[k]).lerp(Vector(sm[k + 1]), u)
        out.append((q.x, q.z))
    return out


def hh_leather_at(x, z, d):
    """A point on the leather: the shell's front at (x, z), d out along its normal."""
    p = hh_on(x, z)
    return p + hh_n(p) * d


def hh_bracket(s, hi):
    ol = hh_outline(hi)
    c = (0.0, 0.31)
    t = HB["t"]

    def ring(scale, d, inset=0.0):
        out = []
        for x, z in ol:
            dx, dz = x - c[0], z - c[1]
            L = math.hypot(dx, dz)
            k = scale * (1.0 - inset / L)
            out.append(tuple(hh_leather_at(c[0] + dx * k, c[1] + dz * k, d)))
        return out

    rings = [ring(1.0, -0.006), ring(1.0, t * 0.55), ring(1.0, t * 0.85, 0.002),
             ring(1.0, t, 0.0055)]
    steps = 8 if hi else 3
    for i in range(1, steps + 1):
        rings.append(ring(1.0 - i / (steps + 1), t, 0.0055))
    rings.append([tuple(hh_leather_at(c[0], c[1], t))])
    s.loft(rings, HH_LEATHER)
    # the steel strap across it, standing off where the lamp's hook drops behind it
    st = HB["strap"]
    zm = (st["z"][0] + st["z"][1]) / 2
    m = 24 if hi else 10
    pts, ups = [], []
    for i in range(m + 1):
        x = -st["x"] + 2 * st["x"] * i / m
        off = HB["slot"][1] * hh_ss(st["x"] - 0.004, st["x"] - 0.03, abs(x))
        p = hh_on(x, zm)
        nn = hh_n(p)
        pts.append(p + nn * (t + st["t"] / 2 + off))
        ups.append(nn)
    hh_strap(s, pts, ups, st["z"][1] - st["z"][0], st["t"], HH_STEEL, hi)
    # its rivets, and the leather's
    for sx in (-1, 1):
        p = hh_on(sx * (st["x"] - 0.016), zm)
        nn = hh_n(p)
        hh_rivet(s, p + nn * (t + st["t"]), nn, 0.011, 0.006, HH_RIVET, hi)
    for x, z in HB["rivets"]:
        p = hh_on(x, z)
        nn = hh_n(p)
        hh_rivet(s, p + nn * t, nn, 0.012, 0.0065, HH_RIVET, hi)


# the lamp's frame: Z forward along its beam, Y up, the origin at the middle of its back
HH_STRAP_Z = (HB["strap"]["z"][0] + HB["strap"]["z"][1]) / 2
HH_LAMP_Y = (hh_on(0.0, HH_STRAP_Z).y - HB["t"] - HB["strap"]["t"] - HB["slot"][1] - HL["gap"])
HH_LAMP_AT = Vector((0.0, HH_LAMP_Y, HL["z"]))
HH_LAMP_M = Matrix.Translation(HH_LAMP_AT) @ Matrix.Rotation(math.radians(90 + HL["tilt"]), 4, "X")
HH_FRONT = HL["back"] + HL["body"]["d"] + HL["bezel"]["d"]   # the bezel's front, along the beam
HH_SEAT = HH_FRONT - 0.012                                    # where the lens sits
HH_KNOB_Z = HL["back"] + HL["body"]["d"] * 0.5
# the cord's boot: out of the back's upper right, up and back toward the crown
HH_BOOT = (HH_LAMP_M @ Vector((0.05, 0.062, 0.02)), HH_LAMP_M @ Vector((0.068, 0.112, -0.004)))


def hh_body_r(z):
    """The housing's radius at z along the beam (from its back)."""
    b = HL["body"]
    u = min(1.0, max(0.0, (z - HL["back"]) / b["d"]))
    return b["r1"] + (b["r0"] - b["r1"]) * u


def hh_lamp(hi):
    s = Shape()
    f = 3 if hi else 1
    b, bz, bk = HL["body"], HL["bezel"], HL["back"]
    # the domed back, the housing widening toward the front, the bezel's rolled ring, its lip
    # turned in over the lens, and back in to the reflector's rim
    back = [(b["r1"] * math.sin(math.radians(a)), bk * (1.0 - math.cos(math.radians(a))))
            for a in [90.0 * i / (6 * f) for i in range(6 * f + 1)]]
    front = HH_FRONT
    prof = back + [(b["r1"], bk + 0.01), (b["r0"], bk + b["d"] - 0.004),
                   (b["r0"] + 0.004, bk + b["d"])]
    prof += fillet(bz["r"] - 0.008, bk + b["d"] + 0.008, 0.008, (-90, 0), 2 * f)[1:]
    prof += fillet(bz["r"] - 0.01, front - 0.01, 0.01, (0, 90), 3 * f)[1:]
    prof += [(bz["r"] - bz["lip"], front - 0.002), (bz["r"] - bz["lip"] - 0.002, front - 0.006),
             (bz["r"] - bz["lip"] - 0.002, HH_SEAT - 0.004), (HL["reflector"]["r"] + 0.001, HH_SEAT - 0.004)]
    kinds = [HH_LAMP] * (len(back) + 2) + [HH_CHROME] * (len(prof) - len(back) - 2 - 1)
    s.lathe(prof, HH_LAMP, segs(hi, 40), HH_LAMP_M, kinds=kinds)
    # the hook: a flat steel tongue from the top of its back, down behind the strap
    hk = HL["hook"]
    yb = b["r1"] * 0.35
    s.box((-hk["w"] / 2, yb, -HL["gap"] - HB["slot"][1] - 0.002),
          (hk["w"] / 2, yb + hk["h"], 0.006), HH_STEEL, 0.002, 2 if hi else 1, HH_LAMP_M)
    s.box((-hk["w"] / 2, yb + hk["h"] - 0.012, -HL["gap"] - HB["slot"][1] - 0.002),
          (hk["w"] / 2, yb + hk["h"], 0.01), HH_STEEL, 0.002, 2 if hi else 1, HH_LAMP_M)
    # the knob's boss on top
    kz = HH_KNOB_Z
    top = hh_body_r(kz)
    s.lathe([(0.0, -0.012), (HL["knob"]["r"] + 0.007, -0.012), (HL["knob"]["r"] + 0.007, 0.008),
             (HL["knob"]["r"] + 0.003, 0.012), (0.0, 0.012)], HH_LAMP, segs(hi, 20),
            HH_LAMP_M @ Matrix.Translation((0.0, top, kz)) @ Matrix.Rotation(math.radians(-90), 4, "X"))
    # the cord's rubber boot, out of the back's upper right
    pts = [HH_BOOT[0].lerp(HH_BOOT[1], i / 6) for i in range(7)]
    s.tube([tuple(q) for q in pts], 0.028, HH_CORD, 20 if hi else 8,
           radii=[0.029 - 0.007 * (i / 6) ** 0.7 for i in range(7)])
    return s


def hh_knob(hi):
    s = Shape()
    k = HL["knob"]
    top = hh_body_r(HH_KNOB_Z)
    M = (HH_LAMP_M @ Matrix.Translation((0.0, top + 0.012, HH_KNOB_Z))
         @ Matrix.Rotation(math.radians(-90), 4, "X"))
    f = 3 if hi else 1
    s.lathe([(0.0, 0.0), (k["r"], 0.0), (k["r"], k["h"] * 0.35)]
            + fillet(k["r"] - 0.004, k["h"] * 0.35, 0.004, (0, 90), 2 * f)[1:]
            + [(0.0, k["h"] * 0.35 + 0.004)], HH_KNOB, segs(hi, 24), M)
    # the fin you turn it by, across it
    s.box((-k["r"] * 0.95, -0.007, k["h"] * 0.3), (k["r"] * 0.95, 0.007, k["h"]), HH_KNOB, 0.003,
          2 if hi else 1, M)
    return s


def hh_bulb(hi):
    """The reflector's bright bowl and the bulb at its heart."""
    s = Shape()
    rf, bl = HL["reflector"], HL["bulb"]
    z0 = HH_SEAT - 0.003
    m = 16 if hi else 6
    prof = [(0.016, z0 - rf["d"])]
    for i in range(1, m + 1):
        u = i / m
        prof.append((0.016 + (rf["r"] - 0.016) * u ** 0.5, z0 - rf["d"] * (1.0 - u)))
    # listed from the middle out and up the bowl's inside, which faces forward
    s.lathe(list(reversed(prof)), HH_REFL, segs(hi, 32), HH_LAMP_M)
    # the bulb: a small round envelope on its socket
    f = 3 if hi else 1
    zb_ = z0 - rf["d"] + 0.004
    bulb = [(0.0, zb_ - 0.004), (0.012, zb_ - 0.004), (0.012, zb_ + 0.012)]
    bulb += fillet(0.0, zb_ + 0.012 + bl["r"], bl["r"], (-60, 90), 6 * f)[1:]
    kinds = [HH_STEEL, HH_STEEL] + [HH_BULB] * (len(bulb) - 3)
    s.lathe(bulb, HH_BULB, segs(hi, 20), HH_LAMP_M, kinds=kinds)
    return s


def hh_lens(hi):
    s = Shape()
    r = HL["bezel"]["r"] - HL["bezel"]["lip"] - 0.002
    z = HH_SEAT - 0.002
    prof = [(0.0, z), (r, z), (r, z + 0.007), (r * 0.6, z + 0.0095), (0.0, z + 0.011)]
    s.lathe(prof, HH_LENS, segs(hi, 40), HH_LAMP_M, kinds=[HH_LENS_IN, HH_LENS, HH_LENS, HH_LENS])
    return s


def hh_lay(p, d):
    """A point d out from the dome's surface point p."""
    return p + hh_n(p) * d


HH_CR = HC["r"]
HH_CLIP = hh_on(0.0, HC["clip_z"], 1)
HH_BAT_M = (Matrix.Translation((HP["at"][0], HP["at"][1], 0.0))
            @ Matrix.Rotation(math.radians(HP["yaw"]), 4, "Z"))
HH_BAT_TOP = HP["h"] + HP["lid"]["h"]
HH_GLAND = HH_BAT_M @ Vector((0.085, 0.0, HH_BAT_TOP))


def hh_cord_over():
    """The cord from the boot up over the crown to the clip on the back."""
    d = HH_CR + 0.003
    t = HB["t"]
    pts = [HH_BOOT[1], HH_BOOT[1] + (HH_BOOT[1] - HH_BOOT[0]).normalized() * 0.02,
           hh_lay(hh_on(0.074, 0.43), d + t), hh_lay(hh_on(0.08, 0.475), d)]
    pts += [hh_lay(hh_top(0.084, y), d) for y in (-0.24, -0.14, -0.04, 0.06, 0.16, 0.25)]
    pts += [hh_lay(hh_on(0.064, 0.47, 1), d), hh_lay(hh_on(0.036, 0.41, 1), d),
            hh_lay(hh_on(0.008, 0.365, 1), d), hh_lay(HH_CLIP, d)]
    return [Vector(q) for q in spline(pts, 6)]


def hh_cord_down():
    """From the clip down the back, over the lip, round the floor and up into the battery."""
    d = HH_CR + 0.003
    r = HH_CR
    g = HH_GLAND
    up = HH_BAT_M.to_3x3() @ Vector((0.0, 0.0, 1.0))
    pts = [hh_lay(HH_CLIP, d), hh_lay(hh_on(0.004, 0.27, 1), d), hh_lay(hh_on(0.01, 0.18, 1), d),
           hh_lay(hh_on(0.018, 0.1, 1), d), Vector((0.026, 0.508, 0.062)),
           Vector((0.034, 0.56, 0.036)), Vector((0.05, 0.63, r)), Vector((0.13, 0.76, r)),
           Vector((0.3, 0.83, r)), Vector((0.52, 0.84, r)), Vector((0.74, 0.8, r)),
           Vector((g.x + 0.16, g.y + 0.36, r + 0.002)), Vector((g.x + 0.2, g.y + 0.3, 0.12)),
           Vector((g.x + 0.19, g.y + 0.24, 0.42)), Vector((g.x + 0.14, g.y + 0.16, 0.66)),
           Vector((g.x + 0.07, g.y + 0.07, g.z + HP["spring"]["h"] + 0.07)),
           g + up * (HP["spring"]["h"] + 0.012), g + up * 0.02]
    return [Vector(q) for q in spline(pts, 7)]


def hh_cord(s, pts, hi):
    for run in ne_chunks(pts, 0.9):
        s.tube([tuple(q) for q in run], HH_CR, HH_CORD, segs(hi, 8) + (4 if hi else 0), caps=False)


def hh_clip(s, hi):
    """The steel clip on the back the cord runs under: a strap bent up over it, riveted down
    either side."""
    m = 16 if hi else 8
    pts, ups = [], []
    w = HH_CR + 0.006
    for i in range(m + 1):
        x = -0.05 + 0.1 * i / m
        p = hh_on(x, HC["clip_z"], 1)
        nn = hh_n(p)
        lift = 0.004 + (2 * HH_CR + 0.004) * hh_ss(w + 0.012, w - 0.004, abs(x))
        pts.append(p + nn * lift)
        ups.append(nn)
    hh_strap(s, pts, ups, 0.036, 0.006, HH_STEEL, hi)
    for sx in (-1, 1):
        p = hh_on(sx * 0.04, HC["clip_z"], 1)
        nn = hh_n(p)
        hh_rivet(s, p + nn * 0.007, nn, 0.008, 0.005, HH_RIVET, hi)


def hh_shell_all(hi):
    s = hh_shell(hi)
    hh_bracket(s, hi)
    hh_clip(s, hi)
    hh_cord(s, hh_cord_over(), hi)
    return s


def hh_pack(hi):
    """The cord from the clip down to the floor and round to the battery, and the battery."""
    s = Shape()
    hh_cord(s, hh_cord_down(), hi)
    M = HH_BAT_M
    w, d, h = HP["w"], HP["d"], HP["h"]
    ld, o = HP["lid"], HP["lid"]["over"]
    s.box((-w / 2, -d / 2, 0.0), (w / 2, d / 2, h), HH_CASE, 0.018, 3 if hi else 1, M)
    s.box((-w / 2 - o, -d / 2 - o, h - 0.014), (w / 2 + o, d / 2 + o, h + ld["h"]), HH_LID, 0.01,
          3 if hi else 1, M)
    # the lid's latches: steel straps down each narrow side, riveted to the case
    for sx in (-1, 1):
        x0 = sx * (w / 2 + o)
        s.box((min(x0, x0 + sx * 0.007), -0.03, h - 0.085), (max(x0, x0 + sx * 0.007), 0.03, h + ld["h"] - 0.012),
              HH_STEEL, 0.002, 2 if hi else 1, M)
        p = M @ Vector((x0 + sx * 0.007, 0.0, h - 0.06))
        hh_rivet(s, p, M.to_3x3() @ Vector((sx, 0.0, 0.0)), 0.009, 0.005, HH_RIVET, hi)
    # the cord's gland nut and the strain-relief spring round the cord
    top = HH_BAT_TOP
    sp = HP["spring"]
    s.cylinder((0.085, 0.0, top - 0.004), (0.085, 0.0, top + 0.022), 0.033, HH_STEEL, 6, M=M)
    s.cylinder((0.085, 0.0, top + 0.02), (0.085, 0.0, top + 0.03), 0.026, HH_STEEL, segs(hi, 16), M=M)
    coil = helix((0.085, 0.0, top + 0.026), (0.085, 0.0, top + 0.026 + sp["h"]), sp["r"], sp["turns"],
                 24 if hi else 8)
    s.tube([tuple(M @ q) for q in coil], 0.0048, HH_SPRING, segs(hi, 6))
    # the charging contacts on the lid
    for sy in (-1, 1):
        s.lathe([(0.0, top - 0.002), (0.013, top - 0.002), (0.013, top + 0.006), (0.009, top + 0.012),
                 (0.0, top + 0.013)], HH_BRASS, segs(hi, 16),
                M @ Matrix.Translation((-0.085, sy * 0.04, 0.0)))
    # the nameplate on the front, its four rivets
    pl = HP["plate"]
    s.box((-pl["w"] / 2, -d / 2 - 0.003, pl["z"] - pl["h"] / 2),
          (pl["w"] / 2, -d / 2 + 0.002, pl["z"] + pl["h"] / 2), HH_PLATE, 0.0015, 1, M)
    fwd = M.to_3x3() @ Vector((0.0, -1.0, 0.0))
    for sx in (-1, 1):
        for sz in (-1, 1):
            p = M @ Vector((sx * (pl["w"] / 2 - 0.012), -d / 2 - 0.003, pl["z"] + sz * (pl["h"] / 2 - 0.011)))
            hh_rivet(s, p, fwd, 0.0055, 0.003, HH_RIVET, hi)
    # the belt loop on its back: a steel strap standing off the case
    m = 16 if hi else 8
    pts, ups = [], []
    back = M.to_3x3() @ Vector((0.0, 1.0, 0.0))
    for i in range(m + 1):
        x = -0.135 + 0.27 * i / m
        off = 0.003 + 0.024 * hh_ss(0.135, 0.105, abs(x))
        pts.append(M @ Vector((x, d / 2 + off, 0.39)))
        ups.append(back)
    hh_strap(s, pts, ups, 0.06, 0.006, HH_STEEL, hi)
    return s


def hh_look(L, f):
    nb = L.nb
    # safety yellow gel coat over fibreglass, faded on the crown, scuffed black on the sides
    yellow = nb.tint(hexc("#D29C1C"), nb.mr(L.noise(2.5, 1, detail=3), 0.3, 0.7, 0.86, 1.08))
    C = Coat(L, yellow, nb.mr(L.noise(6.0, 2, detail=4), 0.25, 0.75, 0.34, 0.52), 0.0,
             nb.mul(L.noise(300.0, 3, detail=1), 0.06))
    shell = L.k(HH_SHELL)
    C.paint(nb.mul(nb.mul(shell, L.up), nb.mr(L.noise(1.4, 4, detail=3), 0.3, 0.7, 0.12, 0.42)),
            hexc("#E2C163"))
    scuff = nb.ss(L.noise(6.0, 5, stretch=(4.0, 1.0, 4.0), detail=5, rough=0.65), 0.64, 0.73)
    C.paint(nb.mul(nb.mul(shell, scuff), 0.8), hexc("#2A2621"), 0.62)
    hair = nb.mul(nb.band(L.noise(16.0, 6, stretch=(1.0, 3.0, 1.0), detail=2), 0.496, 0.504, 0.004),
                  nb.ss(L.noise(2.5, 7, detail=2), 0.6, 0.72))
    C.paint(nb.mul(nb.mul(shell, hair), 0.7), hexc("#DCC68C"), 0.68, None, -0.1)
    C.enamel_wear(shell, hexc("#9A8F68"), s=8, amount=1.3)
    # coal dust ground in low down and under the peak; a black thumbprint smudge on the peak
    low = nb.mul(shell, nb.ss(L.z, 0.17, 0.02))
    C.paint(nb.mul(low, nb.mr(L.noise(5.0, 9, detail=4), 0.3, 0.7, 0.15, 0.65)), hexc("#3A332A"), 0.72)
    thumb = nb.mul(nb.mul(nb.ss(nb.absf(nb.sub(L.x, 0.06)), 0.07, 0.02),
                          nb.ss(nb.absf(nb.add(L.y, 0.6)), 0.06, 0.015)),
                   nb.ss(L.noise(12.0, 10, detail=4, rough=0.6), 0.4, 0.6))
    C.paint(nb.mul(nb.mul(shell, thumb), 0.85), hexc("#221E19"), 0.66)
    C.paint(L.k(HH_INSIDE), nb.tint(hexc("#3D382F"), nb.mr(L.noise(20.0, 11, detail=3), 0.3, 0.7, 0.8, 1.15)),
            0.86, 0.0)
    C.paint(L.k(HH_BAND), hexc("#1C1B19"), 0.55, 0.0)
    # the leather: oiled brown, rubbed pale at its edges, darker where hands and oil met it
    leather = L.k(HH_LEATHER)
    C.paint(leather, nb.tint(hexc("#6E4628"), nb.mr(L.noise(9.0, 12, detail=5), 0.3, 0.7, 0.72, 1.2)),
            nb.mr(L.noise(14.0, 13, detail=4), 0.3, 0.7, 0.5, 0.72), 0.0,
            nb.mul(L.noise(120.0, 14, detail=3), 0.12))
    C.paint(nb.mul(nb.mul(leather, L.edge(0.006, k=5.0)), 0.85), hexc("#9C7352"), 0.75)
    C.paint(nb.mul(leather, nb.ss(L.noise(4.0, 15, detail=4), 0.58, 0.7)), hexc("#2D1B10"), 0.45)
    # dark steel: the strap, the hook, the clip, the latches; rusted where it's wet
    steel = L.k(HH_STEEL)
    C.paint(steel, nb.tint(hexc("#4D4C49"), nb.mr(L.noise(18.0, 16, detail=3), 0.3, 0.7, 0.85, 1.15)),
            0.5, 0.75)
    C.paint(nb.mul(steel, nb.ss(L.noise(22.0, 17, detail=5, rough=0.7), 0.56, 0.66)), hexc("#6B3A20"), 0.85, 0.1)
    C.paint(L.k(HH_RIVET), nb.tint(hexc("#77573A"), nb.mr(L.noise(40.0, 18, detail=3), 0.3, 0.7, 0.8, 1.2)),
            0.42, 0.85)
    # the lamp: black moulded housing worn grey at its edges, a chrome bezel, a bright bowl
    lamp = L.k(HH_LAMP)
    C.paint(lamp, nb.tint(hexc("#1F1E1C"), nb.mr(L.noise(15.0, 19, detail=3), 0.3, 0.7, 0.85, 1.2)), 0.36, 0.0)
    C.paint(nb.mul(nb.mul(lamp, L.edge(0.006, k=5.0)), 0.6), hexc("#4A4741"), 0.5)
    chrome = L.k(HH_CHROME)
    C.paint(chrome, hexc("#CBCDCF"), nb.mr(L.noise(30.0, 20, detail=3), 0.3, 0.7, 0.12, 0.3), 1.0)
    C.paint(nb.mul(chrome, nb.ss(L.noise(55.0, 21, detail=5, rough=0.7), 0.64, 0.7)), hexc("#5F5A52"), 0.7, 0.4)
    refl = L.k(HH_REFL)
    C.paint(refl, hexc("#E9EAEA"), 0.07, 1.0)
    C.paint(L.k(HH_BULB), hexc("#F4EBD3"), 0.12, 0.0)
    # lit, the bowl is brightest round the bulb and falls off toward its rim
    dz = nb.sub(L.z, HL["z"])
    ring = nb.mr(nb.add(nb.mul(L.x, L.x), nb.mul(dz, dz)), 0.0, 0.015, 0.55, 0.22)
    C.lights(nb.add(L.k(HH_BULB), nb.mul(refl, ring), clamp=True))
    C.paint(L.k(HH_LENS), hexc("#9DAEA8"), 0.03, 0.0, alpha=0.18)
    C.paint(L.k(HH_LENS_IN), hexc("#9DAEA8"), 0.03, 0.0, alpha=0.12)
    C.paint(L.k(HH_KNOB), hexc("#262422"), 0.44, 0.0)
    # the rubber cord, dulled grey where it rubbed
    cord = L.k(HH_CORD)
    C.paint(cord, nb.tint(hexc("#1C1C1B"), nb.mr(L.noise(10.0, 22, detail=3), 0.3, 0.7, 0.9, 1.35)), 0.7, 0.0)
    # the battery: red enamelled steel, chipped to steel, rust round its foot; an aluminium lid
    case = L.k(HH_CASE)
    C.paint(case, nb.tint(hexc("#7A281D"), nb.mr(L.noise(4.0, 23, detail=4), 0.3, 0.7, 0.78, 1.1)),
            nb.mr(L.noise(9.0, 24, detail=3), 0.3, 0.7, 0.4, 0.58), 0.0, nb.mul(L.noise(90.0, 25, detail=3), 0.08))
    C.enamel_wear(case, hexc("#5E5F5C"), s=26, amount=1.6)
    # grimy hand marks and drips down its face
    drip = nb.ss(L.noise(5.0, 32, stretch=(5.0, 5.0, 0.6), detail=4, rough=0.6), 0.58, 0.7)
    C.paint(nb.mul(nb.mul(case, drip), 0.75), hexc("#3A1C16"), 0.62)
    C.paint(nb.mul(nb.mul(case, nb.ss(L.z, 0.09, 0.0)), nb.ss(L.noise(26.0, 27, detail=5, rough=0.7), 0.52, 0.62)),
            hexc("#5E3220"), 0.85, 0.0)
    lid = L.k(HH_LID)
    C.paint(lid, nb.tint(hexc("#A3A5A3"), nb.mr(L.noise(12.0, 28, detail=4), 0.3, 0.7, 0.8, 1.1)),
            nb.mr(L.noise(20.0, 29, detail=3), 0.3, 0.7, 0.4, 0.58), 0.9)
    plate = L.k(HH_PLATE)
    C.paint(plate, hexc("#C6C6BE"), 0.36, 0.85)
    pz = HP["plate"]["z"]
    rows = nb.add(nb.add(nb.band(L.z, pz + 0.012, pz + 0.02, 0.0012), nb.band(L.z, pz - 0.004, pz + 0.004, 0.0012)),
                  nb.band(L.z, pz - 0.02, pz - 0.012, 0.0012), clamp=True)
    words = nb.ss(L.noise(70.0, 30, stretch=(1.0, 1.0, 0.15), detail=2), 0.44, 0.48)
    C.paint(nb.mul(nb.mul(plate, rows), words), hexc("#2A2A28"), 0.6, 0.2, -0.15)
    C.paint(L.k(HH_SPRING), hexc("#8B8D8F"), 0.35, 1.0)
    C.paint(nb.mul(L.k(HH_SPRING), nb.ss(L.noise(60.0, 31, detail=4), 0.55, 0.65)), hexc("#6E3D22"), 0.8, 0.1)
    C.paint(L.k(HH_BRASS), hexc("#B0884A"), 0.34, 1.0)
    C.finish(f.dust, grime=0.55, keep=L.k(HH_LENS, HH_LENS_IN, HH_REFL, HH_BULB))
    return C.surface(bump_dist=0.0012, bump=0.45)


HH_HOOK = HH_LAMP_M @ Vector((0.0, HL["body"]["r1"] * 0.35 + HL["hook"]["h"] - 0.006,
                              -HL["gap"] - HB["slot"][1] / 2))
HH_UP = HH_LAMP_M.to_3x3() @ Vector((0.0, 1.0, 0.0))
HH_AIM = (HH_LAMP_M.to_3x3() @ Vector((0.0, 0.0, 1.0))).normalized()
HH_KNOB_AT = HH_LAMP_M @ Vector((0.0, hh_body_r(HH_KNOB_Z) + 0.012, HH_KNOB_Z))
HH_LENS_C = HH_LAMP_M @ Vector((0.0, 0.0, HH_SEAT))
# the filmstrip's camera aims 0.14 of the find's size under its focus: lift it to the knob
HH_LOOK = tuple(HH_LAMP_M @ Vector((0.0, 0.07, 0.12)) + Vector((0.0, 0.0, 0.2)))
HH_KNOB_ON = HL["knob"]["on"]
HH_TURN_ON = [(0.0, 0.0), (0.06, -6.0, "Quad", "Out"), (0.16, HH_KNOB_ON + 6.0, "Quad", "In"),
              (0.21, HH_KNOB_ON - 2.0, "Quad", "Out"), (0.29, HH_KNOB_ON + 1.0), (0.36, HH_KNOB_ON)]
HH_TURN_OFF = [(0.0, HH_KNOB_ON), (0.06, HH_KNOB_ON + 5.0, "Quad", "Out"), (0.15, -4.0, "Quad", "In"),
               (0.21, 1.5, "Quad", "Out"), (0.28, 0.0)]
# the thumb's push nods the lamp in its bracket, and it rocks back
HH_NOD = [(0.0, 0.0), (0.06, 0.6, "Quad", "Out"), (0.16, 2.4, "Quad", "In"), (0.26, -1.0),
          (0.38, 0.4), (0.52, 0.0)]
HARD_HAT = kit.Find(
    "HardHat",
    [kit.Part("Shell", hh_shell_all),
     kit.Part("Lamp", hh_lamp, tuple(HH_HOOK), "Shell", (1, 0, 0)),
     kit.Part("Switch", hh_knob, tuple(HH_KNOB_AT), "Lamp", tuple(-HH_UP)),
     kit.Part("Bulb", hh_bulb, tuple(HH_LENS_C), "Lamp"),
     kit.Part("Lens", hh_lens, tuple(HH_LENS_C), "Lamp", clear=True),
     kit.Part("Pack", hh_pack, tuple(HH_CLIP), "Shell")],
    hh_look,
    lights=[
        # the beam: a warm, narrow cone out of the lens, lighting whatever the wearer looks at
        dict(kind="Spot", part="Lamp", at=tuple(HH_LAMP_M @ Vector((0.0, 0.0, HH_FRONT + 0.004))),
             face=tuple(HH_AIM), kelvin=HL["kelvin"], brightness=1.5, range=20, angle=40,
             shadows=True, preview_watts=30.0, preview_blend=0.35),
        # its spill round the lamp, which also lights at low graphics (docs/STUDIO.md)
        dict(kind="Point", part="Lamp", at=tuple(HH_LAMP_M @ Vector((0.0, 0.0, HH_FRONT + 0.06))),
             kelvin=HL["kelvin"], brightness=0.3, range=5, shadows=False, preview_kind="POINT",
             preview_watts=1.0, preview_size=0.05),
    ],
    glow=dict(part="Bulb", strength=3.0, tint=(255, 205, 150), preview=14.0),
    lit={("Switch", "turn"): HH_KNOB_ON},
    motions={
        # a thumb turns the knob: a nudge back, it snaps round into its click, the lamp nods in
        # its bracket under the push; the filament comes up warm a breath after the click
        "SwitchOn": dict(duration=0.7, focus=HH_LOOK, distance=0.33, tracks=[
            ("Switch", "turn", HH_TURN_ON), ("Lamp", "turn", HH_NOD),
            ("Bulb", "glow", [(0.0, 0.0), (0.155, 0.0, "Linear"), (0.19, 0.45, "Quad", "Out"),
                              (0.32, 1.0, "Quad", "Out"), (0.7, 1.0)])]),
        # turned back: the light drops at the click and the filament fades orange to nothing
        "SwitchOff": dict(duration=0.7, focus=HH_LOOK, distance=0.33, tracks=[
            ("Switch", "turn", HH_TURN_OFF), ("Lamp", "turn", HH_NOD),
            ("Bulb", "glow", [(0.0, 1.0), (0.14, 1.0, "Linear"), (0.17, 0.25, "Quad", "Out"),
                              (0.55, 0.0, "Sine", "Out")])]),
        # its minute up: the battery sags, the beam browns and stutters and dies
        "RunDown": dict(duration=3.0, focus=HH_LOOK, distance=0.33, tracks=[
            ("Bulb", "glow", [(0.0, 1.0), (0.4, 0.86), (0.46, 0.4, "Quad", "Out"), (0.55, 0.8),
                              (1.0, 0.6), (1.06, 0.18, "Quad", "Out"), (1.14, 0.5), (1.6, 0.32),
                              (1.66, 0.05, "Quad", "Out"), (1.74, 0.22), (2.2, 0.08),
                              (2.6, 0.0, "Quad", "In"), (3.0, 0.0)])]),
    },
    dust=HH["dust"], seed=HH["seed"],
)

# --- the jar of fireflies -----------------------------------------------------------------------

(FJ_GLASS, FJ_GLASS_IN, FJ_BAND, FJ_DISC, FJ_UNDER, FJ_GRASS, FJ_STRAW, FJ_TWIG, FF_BODY, FF_WING,
 FF_EDGE, FF_HOOD, FF_SPOT, FF_LANTERN, FF_LEG) = range(133, 148)
FJ, FF = K.FIREFLY_JAR, K.FIREFLY
FJB, FJD = FJ["band"], FJ["disc"]
FJ_LID = Vector((0.0, 0.0, (FJB["z0"] + FJB["z1"]) / 2))   # the lid's pivot: the band's middle
FJ_DZ = FJB["z1"] - 0.007                                 # the disc's top, under the band's lip


def fj_ss(a, b, x):
    u = min(1.0, max(0.0, (x - a) / (b - a)))
    return u * u * (3 - 2 * u)


def fj_jar(hi):
    """The jar: one glass shell, out round its base, up the body and shoulder, over the rim and
    back down the inside to its floor."""
    s = Shape()
    out, ins = FJ["outside"], FJ["inside"]
    (r0, z0), (r1, _) = out[-1], ins[0]
    nl = 6 if hi else 3
    lip = fillet((r0 + r1) / 2, z0, (r0 - r1) / 2, (0, 180), nl)
    prof = out[:-1] + lip + ins[1:]
    n_out = len(out) - 1 + nl
    kinds = [FJ_GLASS] * n_out + [FJ_GLASS_IN] * (len(prof) - 1 - n_out)
    s.lathe(prof, FJ_GLASS, segs(hi, 40), kinds=kinds)
    return s


def fj_holes():
    """The nail holes: a sunflower scatter over the panel, nudged off true as a hand punches."""
    rng = random.Random(FJD["seed"])
    n, out = FJD["holes"], []
    for i in range(n):
        r = 0.094 * math.sqrt((i + 0.5) / n)
        a = i * 2.39996 + rng.uniform(-0.25, 0.25)
        r += rng.uniform(-0.004, 0.004)
        out.append((r * math.cos(a), r * math.sin(a)))
    return out


FJ_HOLES = fj_holes()


def fj_disc_z(x, y, hi):
    """The disc's top: flat, a recessed ring round its panel, each hole a punched crater."""
    r = math.hypot(x, y)
    z = FJ_DZ
    z -= 0.0028 * math.exp(-((r - FJD["panel"]) / 0.0035) ** 2)
    if hi:
        for hx, hy in FJ_HOLES:
            d = math.hypot(x - hx, y - hy)
            if d < 0.011:
                z -= 0.0042 * (0.5 + 0.5 * math.cos(math.pi * d / 0.011))
    return z


def fj_lid(hi):
    s = Shape()
    f = 3 if hi else 1
    r, z0, z1, t, lip = FJB["r"], FJB["z0"], FJB["z1"], FJB["t"], FJB["lip"]
    # the band: round its rolled foot, up the outside (two rings pressed by the thread), over the
    # top and its lip, back under the lip and down the inside
    g = 0.0025
    prof = fillet(r - t / 2, z0 + t / 2, t / 2, (-180, 0), 3 * f)
    for zc in (z0 + 0.024, z0 + 0.044):
        prof += [(r, zc - 0.008), (r - g, zc - 0.002), (r - g, zc + 0.002), (r, zc + 0.008)]
    prof += fillet(r - 0.005, z1 - 0.005, 0.005, (0, 90), 2 * f)[1:]
    prof += fillet(lip + 0.003, z1 - 0.003, 0.003, (90, 270), 3 * f)[1:]
    prof += [(r - t, z1 - t - 0.002), (r - t, z0 + 0.003)]
    prof.append(prof[0])
    s.lathe(prof, FJ_BAND, segs(hi, 48))
    # the disc: its underside (the sealing ring's face) and edge, then its punched top
    dr = FJD["r"]
    s.lathe([(0.0, FJ_DZ - 0.003), (dr, FJ_DZ - 0.003), (dr, FJ_DZ)], FJ_UNDER, segs(hi, 40))
    n = 200 if hi else 40
    m = 46 if hi else 8
    rings = []
    for i in range(m):
        rr = dr * (1.0 - i / m)
        rings.append([(rr * math.cos(2 * math.pi * j / n), rr * math.sin(2 * math.pi * j / n),
                       fj_disc_z(rr * math.cos(2 * math.pi * j / n), rr * math.sin(2 * math.pi * j / n), hi))
                      for j in range(n)])
    rings.append([(0.0, 0.0, fj_disc_z(0.0, 0.0, hi))])
    s.loft(rings, FJ_DISC)
    return s


def fj_blade(s, base, lean, height, bend, w, kind, hi):
    """A blade of grass from base, up and leaning toward `lean` (a direction), its tip bent
    over by `bend`; a flattened V in section, tapering to a point."""
    lean = Vector(lean).normalized()
    b0 = Vector(base)
    # it leans out until its tip rests on the glass, never through it
    room = 0.172 - Vector((b0.x, b0.y, 0.0)).dot(lean)
    reach = min(height * (0.3 + 0.5 * bend), room)
    b1 = b0 + Vector((0.0, 0.0, height * 0.6)) + lean * reach * 0.35
    b2 = b0 + Vector((0.0, 0.0, height * (1.0 - 0.45 * bend))) + lean * reach
    m = 14 if hi else 6
    rings = []
    for i in range(m + 1):
        u = i / m
        p = b0 * (1 - u) ** 2 + b1 * 2 * u * (1 - u) + b2 * u * u
        T = ((b1 - b0) * 2 * (1 - u) + (b2 - b1) * 2 * u).normalized()
        side = T.cross(lean).normalized()
        nrm = side.cross(T).normalized()
        if i == m:
            rings.append([tuple(p)])
            break
        ww = w * (1.0 - u) ** 0.55
        th = 0.0016
        # anticlockwise seen from the tip: a, then nrm-ward, then -a, then back
        ring = [p + side * ww, p + nrm * (th + ww * 0.12), p - side * ww, p - nrm * th]
        rings.append([tuple(q) for q in ring])
    s.loft(rings, kind, cap_bottom=kind)


def fj_grass(hi):
    s = Shape()
    rng = random.Random(FJ["seed"] + 1)
    for k in range(7):
        a = 2 * math.pi * k / 7 + rng.uniform(-0.3, 0.3)
        r0 = rng.uniform(0.02, 0.1)
        base = (r0 * math.cos(a), r0 * math.sin(a), 0.026)
        lean = (math.cos(a), math.sin(a), 0.0)
        h = rng.uniform(0.3, 0.46)
        fj_blade(s, base, lean, h, rng.uniform(0.1, 0.5), rng.uniform(0.009, 0.013),
                 FJ_STRAW if k in (2, 5) else FJ_GRASS, hi)
    # a twig across the bottom, leaning on the glass, a short fork off it
    pts = [(-0.15, 0.07, 0.035), (-0.04, 0.03, 0.07), (0.06, -0.01, 0.11), (0.15, -0.05, 0.16)]
    sm = spline(pts, 4 if hi else 2)
    s.tube(sm, 0.0065, FJ_TWIG, segs(hi, 6), radii=[0.0075 - 0.003 * i / (len(sm) - 1) for i in range(len(sm))])
    fk = [(-0.04, 0.03, 0.07), (-0.02, 0.07, 0.1), (0.0, 0.1, 0.12)]
    s.tube(fk, 0.004, FJ_TWIG, segs(hi, 5), radii=[0.0045, 0.0035, 0.0025])
    return s


# --- the fireflies: one beetle, built in its own frame (head +Y, back +Z) at each one's rest ---

def ff_bug(s, M, hi):
    L = FF["length"] / 0.066
    n = 12 if hi else 8

    def ring(y, w, h, z=0.0, cnt=n):
        # anticlockwise seen from the head: from the back (+Z) round toward +X
        return [tuple(M @ (Vector((w * math.sin(2 * math.pi * j / cnt), y, z + h * math.cos(2 * math.pi * j / cnt))) * L))
                for j in range(cnt)]

    def belly(j, cnt=n):
        return FF_LANTERN if math.cos(2 * math.pi * (j + 0.5) / cnt) < -0.2 else FF_BODY

    # the abdomen: its tail the lantern underneath and round the tip
    tail = [[tuple(M @ (Vector((0.0, -0.034, -0.0015)) * L))], ring(-0.031, 0.0055, 0.0032, -0.001),
            ring(-0.025, 0.0088, 0.0044), ring(-0.017, 0.0105, 0.0048)]
    s.loft(tail, FF_BODY, kinds=belly)
    front = [ring(-0.017, 0.0105, 0.0048), ring(-0.006, 0.0112, 0.005), ring(0.006, 0.0105, 0.0048),
             ring(0.013, 0.0078, 0.0042), [tuple(M @ (Vector((0.0, 0.016, 0.0)) * L))]]
    s.loft(front, FF_BODY)
    # the wing covers: a thin shell over its back, their pale margins down each side
    m = 10 if hi else 6

    def shell(y, w, h, z):
        out, inn = [], []
        for j in range(m + 1):
            a = -math.pi * 0.62 + 1.24 * math.pi * j / m
            out.append(Vector((w * math.sin(a), y, z + h * math.cos(a))))
            inn.append(Vector(((w - 0.0012) * math.sin(a), y, z + (h - 0.0012) * math.cos(a))))
        return [tuple(M @ (q * L)) for q in out + list(reversed(inn))]

    cnt = 2 * (m + 1)

    def edge(j):
        return FF_EDGE if j in (0, m - 1, m, m + 1, cnt - 2, cnt - 1) or j == m // 2 else FF_WING

    wings = [[tuple(M @ (Vector((0.0, -0.035, 0.002)) * L))], shell(-0.032, 0.006, 0.0042, 0.0004),
             shell(-0.024, 0.0112, 0.0058, 0.0004), shell(-0.01, 0.0128, 0.0062, 0.0004),
             shell(0.004, 0.0126, 0.006, 0.0004), shell(0.012, 0.0112, 0.0054, 0.0004)]
    s.loft(wings, FF_WING, kinds=edge)
    # the hood over its head: a rounded shield, rose with a black spot in its middle
    k = 14 if hi else 8
    hood = []
    for i, sc in enumerate((1.0, 0.96, 0.8, 0.55, 0.28)):
        rr = []
        for j in range(k):
            a = 2 * math.pi * j / k
            x = 0.0115 * math.cos(a)
            y = 0.0225 + (0.011 if math.sin(a) > 0 else 0.0095) * math.sin(a)
            rr.append(tuple(M @ (Vector((x * sc, 0.0225 + (y - 0.0225) * sc,
                                          0.0028 + 0.004 * (1.0 - sc ** 2) ** 0.6)) * L)))
        hood.append(rr)
    hood.append([tuple(M @ (Vector((0.0, 0.0225, 0.0068)) * L))])
    s.loft(hood, FF_HOOD, cap_bottom=FF_HOOD)
    s.lathe([(0.0, -0.001), (0.003, -0.001), (0.0026, 0.0008), (0.0, 0.0012)], FF_SPOT, 8 if hi else 5,
            M @ Matrix.Translation(Vector((0.0, 0.0215, 0.0062)) * L) @ Matrix.Diagonal((1.0, 1.3, 1.0, 1.0)))
    # the head, tucked under the hood's front
    s.lathe([(0.0, -0.004), (0.0035, -0.0035), (0.0045, 0.0), (0.0035, 0.0035), (0.0, 0.004)],
            FF_BODY, 8 if hi else 5, M @ Matrix.Translation(Vector((0.0, 0.03, -0.0005)) * L)
            @ Matrix.Rotation(math.radians(-90), 4, "X"))
    # feelers and six legs, thin dark wire
    for sx in (-1, 1):
        s.tube([tuple(M @ (Vector(p) * L)) for p in ((sx * 0.0025, 0.0335, 0.0005), (sx * 0.008, 0.042, 0.003),
                                                     (sx * 0.013, 0.05, 0.002))], 0.0007 * L, FF_LEG, 3)
        for y, out, back in ((0.012, 0.016, 0.006), (0.004, 0.018, -0.002), (-0.006, 0.017, -0.012)):
            s.tube([tuple(M @ (Vector(p) * L)) for p in ((sx * 0.005, y, -0.003), (sx * out, y + back * 0.4, -0.004),
                                                         (sx * (out + 0.003), y + back, -0.0095))],
                   0.0008 * L, FF_LEG, 3)


FF_L = FF["length"] / 0.066     # the beetle is drawn 66 thousandths long, then scaled


def ff_frames():
    """Each firefly's rest, as found: most on the glass (back to the middle, head up or askew),
    a few on the jar's floor."""
    rng = random.Random(FJ["seed"] + 2)
    out = []
    wall = [(0.12, 0.0), (0.33, 0.8), (0.2, 1.6), (0.41, 2.4), (0.15, 3.1), (0.3, 3.9), (0.24, 4.7),
            (0.38, 5.5), (0.1, 2.0)]
    for z, a in wall:
        a += rng.uniform(-0.2, 0.2)
        rad = Vector((math.cos(a), math.sin(a), 0.0))
        tan = Vector((-math.sin(a), math.cos(a), 0.0))
        b = math.radians(rng.uniform(-55, 55))
        Y = Vector((0, 0, 1)) * math.cos(b) + tan * math.sin(b)
        Z = -rad
        X = Y.cross(Z)
        p = rad * (0.187 - 0.0095 * FF_L) + Vector((0, 0, z))
        out.append((p, X, Y, Z))
    for r, a, h in ((0.07, 0.6, 2.2), (0.09, 3.6, 0.4), (0.05, 5.0, 4.0)):
        p = Vector((r * math.cos(a), r * math.sin(a), 0.028 + 0.0095 * FF_L))
        Y = Vector((math.cos(h), math.sin(h), 0.0))
        Z = Vector((0, 0, 1))
        out.append((p, Y.cross(Z), Y, Z))
    return out


FF_REST = ff_frames()


def ff_M(i):
    p, X, Y, Z = FF_REST[i]
    R = Matrix((X, Y, Z)).transposed()
    return Matrix.Translation(p) @ R.to_4x4()


def ff_part(i):
    def build(hi):
        s = Shape()
        ff_bug(s, ff_M(i), hi)
        return s
    return build


# --- how they fly (README): every number in FF; a loop the game plays for the minute ------

FF_T = FF["drift"]


def ff_quarter_keys(c, a, k, q):
    """c + a sin(2 pi k t / T + q pi / 2) over the loop, keyed at its quarter points, where a
    Sine Out (from a crossing to a peak) or Sine In (a peak to a crossing) between them is the
    curve exactly."""
    step = FF_T / (4 * k)
    keys = []
    for m in range(4 * k + 1):
        ph = (q + m) % 4
        v = round(c + a * (0, 1, 0, -1)[ph], 4)
        if m == 0:
            keys.append((0.0, v))
        else:
            style = ("Sine", "Out") if (q + m - 1) % 4 in (0, 2) else ("Sine", "In")
            keys.append((round(m * step, 4), v) + style)
    return keys


def ff_flash(t0, peak):
    """One flash from t0: up fast, held a breath, dying away (keys after an unlit stretch)."""
    f = FF["flash"]
    return [(round(t0, 3), 0.0, "Linear", "In"), (round(t0 + f["rise"], 3), peak, "Sine", "Out"),
            (round(t0 + f["rise"] + f["hold"], 3), round(peak * 0.92, 3), "Linear", "In"),
            (round(t0 + f["rise"] + f["hold"] + f["fall"], 3), 0.0, "Sine", "In")]


def ff_glow(flashes, peaks, end):
    keys = [(0.0, 0.0)]
    for t0, pk in sorted(zip(flashes, peaks)):
        keys += ff_flash(t0, pk)
    keys.append((end, 0.0, "Linear", "In"))
    return keys


def ff_J(tau):
    """The J: a dip just before the flash, a climb while it's lit, settling back after."""
    dip = -FF["dip"] * math.sin(math.pi * (tau + 0.5) / 0.7) if -0.5 <= tau <= 0.2 else 0.0
    return dip + FF["climb"] * fj_ss(0.0, 0.75, tau) * (1.0 - fj_ss(1.1, 3.4, tau))


def ff_plan(i):
    """Firefly i's loop: a Lissajous figure round its own middle, bobbing, with its flashes."""
    rng = random.Random(FJ["seed"] + 10 + i)
    a = rng.uniform(0, 2 * math.pi)
    rr = FF["middle"] * math.sqrt(rng.random())
    kx, ky = rng.choice((1, 2)), rng.choice((1, 2))
    qx = rng.randrange(4)
    qy = (qx + 1) % 4 if kx == ky else rng.randrange(4)
    if qx % 2 and qy % 2:
        qy = (qy + 1) % 4          # never both at a peak at once: it would hang still
    f1 = rng.uniform(0.3, 3.4)
    fl = [f1]
    while True:
        nxt = fl[-1] + rng.uniform(*FF["every"])
        if nxt + 1.0 > FF_T or nxt > f1 + FF_T - FF["every"][0]:
            break
        fl.append(nxt)
    return dict(cx=rr * math.cos(a), cy=rr * math.sin(a), ax=rng.uniform(*FF["reach"]),
                ay=rng.uniform(*FF["reach"]), kx=kx, ky=ky, qx=qx, qy=qy,
                cz=rng.uniform(*FF["height"]), az=rng.uniform(0.15, 0.4), kz=rng.choice((2, 3)),
                qz=rng.randrange(4), flashes=fl, rng=rng)


FF_PLANS = [ff_plan(i) for i in range(FF["n"])]


def ff_drift_at(pl, t):
    w = 2 * math.pi / FF_T
    x = pl["cx"] + pl["ax"] * math.sin(w * pl["kx"] * t + pl["qx"] * math.pi / 2)
    y = pl["cy"] + pl["ay"] * math.sin(w * pl["ky"] * t + pl["qy"] * math.pi / 2)
    z = pl["cz"] + pl["az"] * math.sin(w * pl["kz"] * t + pl["qz"] * math.pi / 2)
    for f in pl["flashes"]:
        tau = (t - f + FF_T / 2) % FF_T - FF_T / 2
        z += ff_J(tau)
    return Vector((x, y, z))


def ff_drift_vel(pl, t):
    e = 1e-3
    return (ff_drift_at(pl, t + e) - ff_drift_at(pl, t - e)) / (2 * e)


def ff_hermite(pts, ts, v0, v1):
    P = [Vector(p) for p in pts]
    V = [Vector(v0)] + [(P[k + 1] - P[k - 1]) / (ts[k + 1] - ts[k - 1]) for k in range(1, len(P) - 1)] + [Vector(v1)]

    def at(t):
        if t <= ts[0]:
            return P[0].copy()
        if t >= ts[-1]:
            return P[-1] + V[-1] * (t - ts[-1])
        k = max(i for i in range(len(ts) - 1) if ts[i] <= t)
        h = ts[k + 1] - ts[k]
        u = (t - ts[k]) / h
        return (P[k] * (2 * u ** 3 - 3 * u ** 2 + 1) + V[k] * h * (u ** 3 - 2 * u ** 2 + u)
                + P[k + 1] * (-2 * u ** 3 + 3 * u ** 2) + V[k + 1] * h * (u ** 3 - u ** 2))
    return at


def ff_sampled(f, dur, eps, rate=24.0):
    """Channel keys for f(t) -> (x, y, z), sampled and thinned to straight runs."""
    n = int(round(dur * rate))
    ts = [dur * i / n for i in range(n + 1)]
    ps = [f(t) for t in ts]
    return [bl_rdp(ts, [p[c] for p in ps], eps) for c in range(3)]


def ff_tracks_drift():
    tr = []
    for i, pl in enumerate(FF_PLANS):
        p = FF_REST[i][0]
        name = f"Firefly{i}"
        tr.append((name, "x", ff_quarter_keys(pl["cx"] - p.x, pl["ax"], pl["kx"], pl["qx"])))
        tr.append((name, "y", ff_quarter_keys(pl["cy"] - p.y, pl["ay"], pl["ky"], pl["qy"])))
        n = int(FF_T * 24)
        ts = [FF_T * j / n for j in range(n + 1)]
        tr.append((name, "move", bl_rdp(ts, [ff_drift_at(pl, t).z - p.z for t in ts], 0.012)))
        tr.append((name, "glow", ff_glow(pl["flashes"], [1.0] * len(pl["flashes"]), FF_T)))
    return tr


def ff_tracks_open():
    tr = []
    order = sorted(range(FF["n"]), key=lambda i: -FF_REST[i][0].z)
    T = FF["open"]
    for rank, i in enumerate(order):
        pl = FF_PLANS[i]
        rng = random.Random(FJ["seed"] + 40 + i)
        p = FF_REST[i][0]
        t0 = 1.8 + 0.34 * rank + rng.uniform(0.0, 0.1)
        d0 = ff_drift_at(pl, 0.0)
        out = Vector((d0.x, d0.y, 0.0))
        out = out.normalized() if out.length > 1e-3 else Vector((1.0, 0.0, 0.0))
        a1 = Vector((p.x * 0.35, p.y * 0.35, min(0.55, max(0.2, p.z + 0.18))))
        a2 = Vector((rng.uniform(-0.03, 0.03), rng.uniform(-0.03, 0.03), 0.76))
        a3 = a2 + out * rng.uniform(0.35, 0.6) + Vector((0.0, 0.0, rng.uniform(0.5, 0.8)))
        path = ff_hermite([p, a1, a2, a3, d0], [t0, t0 + 0.45, t0 + 0.8, t0 + 1.6, T],
                          (0.0, 0.0, 0.0), ff_drift_vel(pl, 0.0))
        name = f"Firefly{i}"
        kx, ky, kz = ff_sampled(lambda t: path(t) - p, T, 0.01)
        tr += [(name, "x", kx), (name, "y", ky), (name, "move", kz)]
        # startled as the lid comes off: a flash as it lifts, another on its way out
        fl = [t0 - 0.2, t0 + 1.4 + rng.uniform(0.3, 1.3)]
        if fl[1] + 0.8 > T:
            fl = fl[:1]
        tr.append((name, "glow", ff_glow(fl, [0.85, 1.0][:len(fl)], T)))
    return tr


def ff_tracks_gone():
    tr = []
    T = FF["gone"]
    for i, pl in enumerate(FF_PLANS):
        rng = random.Random(FJ["seed"] + 70 + i)
        p = FF_REST[i][0]
        d0, v0 = ff_drift_at(pl, 0.0), ff_drift_vel(pl, 0.0)
        t1, t2 = rng.uniform(0.9, 1.6), rng.uniform(3.0, 4.0)
        g1 = d0 + v0 * t1 * 0.6 + Vector((0.0, 0.0, 0.7))
        out = Vector((g1.x, g1.y, 0.0))
        out = out.normalized() if out.length > 1e-3 else Vector((1.0, 0.0, 0.0))
        g2 = g1 + out * rng.uniform(0.8, 1.6) + Vector((0.0, 0.0, rng.uniform(1.6, 2.4)))
        path = ff_hermite([d0, g1, g2], [0.0, t1, t2], v0, out * 0.3 + Vector((0.0, 0.0, 0.6)))
        name = f"Firefly{i}"
        kx, ky, kz = ff_sampled(lambda t: path(t) - p, T, 0.01)
        tr += [(name, "x", kx), (name, "y", ky), (name, "move", kz)]
        tr.append((name, "glow", ff_glow([t1 - 0.2, max(t2 - 1.1, t1 + 0.7)], [0.8, 0.45], T)))
        tr.append((name, "scale", [(0.0, 1.0), (t2 - 0.45, 1.0, "Linear", "In"), (t2, 0.02, "Quad", "In"),
                                   (T, 0.02, "Linear", "In")]))
    return tr


def ff_tracks_idle(T=12.0):
    tr = []
    for i in range(FF["n"]):
        rng = random.Random(FJ["seed"] + 100 + i)
        fl = [rng.uniform(0.2, 5.0)]
        if rng.random() < 0.7:
            fl.append(fl[0] + rng.uniform(4.5, 6.2))
        fl = [f for f in fl if f + 0.8 < T]
        tr.append((f"Firefly{i}", "glow", ff_glow(fl, [rng.uniform(0.55, 0.8) for _ in fl], T)))
    return tr


# the lid: unscrewed in three twists, the thread lifting it; popped free, lifted clear, set down
# on the floor beside the jar on one edge, slapped flat with a last little rock
FJ_TWIST = [(0.0, 0.0), (0.32, 175.0, "Quad", "InOut"), (0.44, 175.0, "Linear", "In"),
            (0.76, 355.0, "Quad", "InOut"), (0.88, 355.0, "Linear", "In"), (1.2, 540.0, "Quad", "InOut")]
FJ_SET = Vector((-0.44, -0.2, 0.0))         # where it's set down, from the jar's middle
FJ_HALF = (FJB["z1"] - FJB["z0"]) / 2


def fj_lid_state(t):
    """The lid's middle and its pitch (degrees) at t."""
    ks = ease.keys(FJ_TWIST)
    thread = FJ["pitch"] * ease.sample(ks, min(t, 1.2)) / 360.0
    base = FJ_LID.copy()

    def touch(p):
        return FJ_HALF * math.cos(math.radians(p)) + FJB["r"] * math.sin(math.radians(abs(p)))

    if t <= 1.2:
        return base + Vector((0, 0, thread)), 0.0
    up = FJ["turns"] * FJ["pitch"]
    if t <= 1.32:
        u = ease.ease("Quad", "Out", (t - 1.2) / 0.12)
        return base + Vector((0, 0, up + 0.01 * u)), 0.0
    if t <= 1.62:
        u = ease.ease("Sine", "InOut", (t - 1.32) / 0.3)
        return base + Vector((0, 0, up + 0.01 + 0.14 * u)), 0.0
    hi_ = base + Vector((0, 0, up + 0.15))
    land = Vector((FJ_SET.x, FJ_SET.y, touch(7.0)))
    if t <= 2.12:
        u = (t - 1.62) / 0.5
        uh = ease.ease("Sine", "InOut", u)
        zz = hi_.z + (land.z - hi_.z) * ease.ease("Quad", "InOut", u) + 0.08 * math.sin(math.pi * u)
        return Vector((land.x * uh, land.y * uh, zz)), 7.0 * ease.ease("Sine", "InOut", u)
    for t0, t1, p0, p1, st in ((2.12, 2.2, 7.0, 0.0, ("Quad", "In")), (2.2, 2.27, 0.0, -1.6, ("Quad", "Out")),
                               (2.27, 2.34, -1.6, 0.0, ("Quad", "In"))):
        if t <= t1:
            pp = p0 + (p1 - p0) * ease.ease(st[0], st[1], (t - t0) / (t1 - t0))
            return Vector((land.x, land.y, touch(pp))), pp
    return Vector((land.x, land.y, FJ_HALF)), 0.0


def fj_lid_tracks(T):
    """The lid's channels: its middle and pitch solved for the travel channels (which tilt
    about its pivot after the move along its axis), sampled and thinned."""
    n = int(round(T * 48))
    ts = [T * i / n for i in range(n + 1)]
    xs, ys, ms, ps = [], [], [], []
    for t in ts:
        c, pdeg = fj_lid_state(t)
        pr = math.radians(pdeg)
        mv = (c.z - FJ_LID.z) / math.cos(pr)
        xs.append(c.x - FJ_LID.x)
        ys.append(c.y - FJ_LID.y + mv * math.sin(pr))
        ms.append(mv)
        ps.append(pdeg)
    return [("Lid", "turn", FJ_TWIST + [(T, 540.0, "Linear", "In")]),
            ("Lid", "move", bl_rdp(ts, ms, 0.0015)), ("Lid", "x", bl_rdp(ts, xs, 0.0015)),
            ("Lid", "y", bl_rdp(ts, ys, 0.0015)), ("Lid", "pitch", bl_rdp(ts, ps, 0.15))]


def fj_lid_still(T):
    """The lid lying where it was set down, for the motions after Open."""
    c, _ = fj_lid_state(99.0)
    return [("Lid", "turn", [(0.0, 540.0), (T, 540.0, "Linear", "In")]),
            ("Lid", "move", [(0.0, round(c.z - FJ_LID.z, 4)), (T, round(c.z - FJ_LID.z, 4), "Linear", "In")]),
            ("Lid", "x", [(0.0, round(c.x, 4)), (T, round(c.x, 4), "Linear", "In")]),
            ("Lid", "y", [(0.0, round(c.y, 4)), (T, round(c.y, 4), "Linear", "In")])]


def fj_look(L, f):
    nb = L.nb
    # old aqua glass: dark and glossy so it reads as glass, rippled as old glass is
    glass = L.k(FJ_GLASS, FJ_GLASS_IN)
    C = Coat(L, hexc("#77A09A"), 0.04, 0.0, nb.mul(L.noise(14.0, 1, stretch=(1.0, 1.0, 0.35), detail=3), 0.12))
    C.paint(L.k(FJ_GLASS), alpha=0.18)
    C.paint(L.k(FJ_GLASS_IN), alpha=0.12)
    smudge = nb.mul(L.k(FJ_GLASS), nb.ss(L.noise(5.0, 2, detail=4, rough=0.6), 0.58, 0.72))
    C.paint(nb.mul(smudge, 0.7), hexc("#C2CFCB"), 0.3, alpha=0.24)
    # the band: brass-coloured lacquer on steel, worn through on its top edge, rust at its foot
    band = L.k(FJ_BAND)
    C.paint(band, nb.tint(hexc("#B48E45"), nb.mr(L.noise(10.0, 3, detail=3), 0.3, 0.7, 0.82, 1.1)),
            nb.mr(L.noise(16.0, 4, detail=3), 0.3, 0.7, 0.28, 0.42), 1.0)
    C.paint(nb.mul(nb.mul(band, L.edge(0.004, k=5.0)), nb.ss(L.noise(30.0, 5, detail=4), 0.45, 0.6)),
            hexc("#8C8F90"), 0.4, 1.0)
    C.paint(nb.mul(nb.mul(band, nb.ss(L.z, FJB["z0"] + 0.012, FJB["z0"])), nb.ss(L.noise(40.0, 6, detail=5), 0.5, 0.6)),
            hexc("#6B3A1F"), 0.85, 0.1)
    # the disc: tinplate, every punched hole black with a ring of rust round it
    disc = L.k(FJ_DISC)
    C.paint(disc, nb.tint(hexc("#C4C7C6"), nb.mr(L.noise(12.0, 7, detail=3), 0.3, 0.7, 0.85, 1.05)),
            nb.mr(L.noise(20.0, 8, detail=3), 0.3, 0.7, 0.22, 0.38), 1.0)
    holes, rust = None, None
    for hx, hy in FJ_HOLES:
        d2 = nb.add(nb.mul(nb.sub(L.x, hx), nb.sub(L.x, hx)), nb.mul(nb.sub(L.y, hy), nb.sub(L.y, hy)))
        h = nb.ss(d2, (FJD["hole"] + 0.0006) ** 2, (FJD["hole"] - 0.0006) ** 2)
        ru = nb.ss(d2, 0.0115 ** 2, 0.006 ** 2)
        holes = h if holes is None else nb.add(holes, h, clamp=True)
        rust = ru if rust is None else nb.add(rust, ru, clamp=True)
    C.paint(nb.mul(nb.mul(disc, rust), nb.mr(L.noise(50.0, 9, detail=4), 0.3, 0.7, 0.35, 1.0)),
            hexc("#7A4424"), 0.75, 0.15)
    C.paint(nb.mul(disc, holes), hexc("#090807"), 0.9, 0.0)
    C.paint(L.k(FJ_UNDER), hexc("#9A3D24"), 0.6, 0.0)     # the sealing compound's red
    # grass, green going to straw at its tips; a dry twig
    gr = L.k(FJ_GRASS)
    C.paint(gr, nb.mixc(nb.ss(L.z, 0.2, 0.42), hexc("#4F6E27"), hexc("#9C9A4A")), 0.55, 0.0)
    C.paint(L.k(FJ_STRAW), nb.tint(hexc("#B39A5C"), nb.mr(L.noise(30.0, 10, detail=3), 0.3, 0.7, 0.85, 1.1)),
            0.62, 0.0)
    C.paint(L.k(FJ_TWIG), nb.tint(hexc("#5B4734"), nb.mr(L.noise(60.0, 11, detail=4), 0.3, 0.7, 0.7, 1.2)),
            0.82, 0.0)
    # the fireflies: dark wing covers with pale margins, a rose hood with a black spot, and the
    # pale yellow lantern under the tail that glows
    C.paint(L.k(FF_BODY), hexc("#2A211B"), 0.45, 0.0)
    C.paint(L.k(FF_WING), hexc("#35291F"), 0.38, 0.0)
    C.paint(L.k(FF_EDGE), hexc("#C2A95E"), 0.45, 0.0)
    C.paint(L.k(FF_HOOD), hexc("#C7716A"), 0.4, 0.0)
    C.paint(L.k(FF_SPOT), hexc("#16110E"), 0.4, 0.0)
    C.paint(L.k(FF_LANTERN), hexc("#E9E59C"), 0.35, 0.0)
    C.paint(L.k(FF_LEG), hexc("#211913"), 0.5, 0.0)
    C.lights(L.k(FF_LANTERN))
    alive = L.k(FF_BODY, FF_WING, FF_EDGE, FF_HOOD, FF_SPOT, FF_LANTERN, FF_LEG, FJ_GRASS, FJ_STRAW,
                FJ_TWIG, FJ_GLASS_IN)
    C.finish(f.dust, grime=0.45, keep=alive)
    return C.surface(bump_dist=0.001, bump=0.4)


FJ_OPEN_T, FJ_GONE_T = FF["open"], FF["gone"]
FJ_LIGHTS = [dict(kind="Point", part=f"Firefly{i}", at=tuple(FF_REST[i][0]), rgb=FF["rgb"],
                  brightness=0.4, range=7, shadows=False, preview_kind="POINT", preview_watts=0.5,
                  preview_size=0.02, glow_part=f"Firefly{i}") for i in FF["lights"]]
FIREFLY_JAR = kit.Find(
    "FireflyJar",
    [kit.Part("Jar", fj_jar, clear=True),
     kit.Part("Lid", fj_lid, tuple(FJ_LID), "Jar", (0, 0, 1)),
     kit.Part("Grass", fj_grass, (0.0, 0.0, 0.03), "Jar")]
    + [kit.Part(f"Firefly{i}", ff_part(i), tuple(FF_REST[i][0]), "Jar", (0, 0, 1)) for i in range(FF["n"])],
    fj_look,
    # three of the twelve carry a light: each blinks with its own firefly
    lights=FJ_LIGHTS,
    glow=dict(part="Firefly0", strength=4.0, tint=(205, 255, 120), preview=40.0),
    lit={(f"Firefly{i}", "glow"): 0.8 for i in range(FF["n"])},
    motions={
        # as found: they crawl the glass and blink now and then; the game loops it
        "Idle": dict(duration=12.0, focus=(0.0, 0.0, 0.36), distance=0.8, fps=8,
                     tracks=ff_tracks_idle(12.0)),
        # the lid unscrews and is set down; one by one they flash, climb out of the mouth and
        # drift off to their places round the unit
        "Open": dict(duration=FJ_OPEN_T, focus=(0.0, 0.0, 1.5), distance=3.6, fps=12,
                     tracks=fj_lid_tracks(FJ_OPEN_T) + ff_tracks_open()),
        # the minute they light the unit: each on its own loop, flashing and climbing in the J;
        # the game loops it
        "Drift": dict(duration=FF_T, focus=(0.0, 0.0, 1.9), distance=3.8, fps=8,
                      tracks=fj_lid_still(FF_T) + ff_tracks_drift()),
        # the minute's up: they rise, flash a last time and wink out
        "Gone": dict(duration=FJ_GONE_T, focus=(0.0, 0.0, 2.6), distance=4.0, fps=12,
                     tracks=fj_lid_still(FJ_GONE_T) + ff_tracks_gone()),
    },
    dust=FJ["dust"], seed=FJ["seed"], texels=450,
)

# --- the theatre spotlight ----------------------------------------------------------------------

(SP_ENAMEL, SP_INSIDE, SP_ZINC, SP_BLACK, SP_CHROME, SP_CAST, SP_BAKELITE, SP_RUBBER, SP_GLASS,
 SP_BRASS, SP_DIAL) = range(148, 159)
SL = K.SPOTLIGHT
SC, SDR, SY, SS = SL["can"], SL["doors"], SL["yoke"], SL["stand"]
SP_TZ = SL["tilt_z"]
# the can's own frame: z along the beam (out the front, the find's -Y), y up, x across, from the
# tilt axis
SP_CAN = Matrix.Translation((0.0, 0.0, SP_TZ)) @ Matrix.Rotation(math.radians(90), 4, "X")
SP_DOOR_Z = SDR["z"] + SDR["t"]                    # the frame's front, where the leaves hinge
SP_KNOB_AT = (-(SY["x"] + 0.035), 0.0, SP_TZ)      # the tilt lock, outside the yoke's left arm
SP_SW_AT = (SC["box"]["x"] + 0.025, -0.62, 0.12)   # the toggle on the focus box's side (can frame)
SP_SW_AXIS = tuple(SP_CAN.to_3x3() @ Vector((0.0, 0.0, 1.0)))


def sp_c(p):
    """A point in the can's frame, in the find's."""
    return tuple(SP_CAN @ Vector(p))


def sp_stand(hi):
    s = Shape()
    n = segs(hi, 16)
    f = 3 if hi else 2
    top, cr, rr, lz = SS["top"], SS["column_r"], SS["riser_r"], SS["lock_z"]
    ft, hz, bz = SS["foot"], SS["hub_z"], SS["brace_z"]
    # the column, the riser out of its lock collar, the cast top cap and the spigot pin
    s.cylinder((0, 0, ft), (0, 0, lz + 0.05), cr, SP_CHROME, n)
    s.lathe([(0.0, ft - 0.03), (cr + 0.01, ft - 0.03), (cr + 0.01, ft + 0.03), (0.0, ft + 0.03)],
            SP_CAST, n)
    s.cylinder((0, 0, lz), (0, 0, top - 0.06), rr, SP_CHROME, n)
    s.lathe([(0.0, lz - 0.01), (cr + 0.016, lz - 0.01), (cr + 0.022, lz + 0.004),
             (cr + 0.022, lz + 0.07), (cr + 0.01, lz + 0.088), (0.0, lz + 0.088)], SP_CAST, n)
    y = cr + 0.02
    s.cylinder((0, y - 0.01, lz + 0.04), (0, y + 0.09, lz + 0.04), 0.011, SP_ZINC, segs(hi, 8))
    s.cylinder((-0.06, y + 0.09, lz + 0.04), (0.06, y + 0.09, lz + 0.04), 0.012, SP_ZINC,
               segs(hi, 8))
    s.lathe([(0.0, top - 0.1), (rr + 0.01, top - 0.1), (rr + 0.028, top - 0.065), (0.074, top - 0.03),
             (0.074, top - 0.006), (0.068, top), (0.0, top)], SP_CAST, n)
    pr, pin = SS["pin_r"], SS["pin"]
    s.lathe([(0.0, top - 0.004), (pr, top - 0.004), (pr, top + 0.08), (pr - 0.006, top + 0.09),
             (pr - 0.006, top + 0.11), (pr, top + 0.12), (pr, top + pin - 0.012),
             (pr - 0.012, top + pin), (0.0, top + pin)], SP_ZINC, segs(hi, 12))
    # the cast spider the legs hang from, and the collar their braces pull on
    s.lathe([(0.0, hz - 0.09), (0.07, hz - 0.09), (0.1, hz - 0.06), (0.112, hz - 0.02),
             (0.112, hz + 0.04), (0.09, hz + 0.07), (cr + 0.008, hz + 0.09), (0.0, hz + 0.09)],
            SP_CAST, n)
    s.lathe([(0.0, bz - 0.04), (0.084, bz - 0.04), (0.088, bz - 0.03), (0.088, bz + 0.03),
             (0.084, bz + 0.04), (0.0, bz + 0.04)], SP_CAST, n)
    wr, ww, cz, tr = SS["wheel_r"], SS["wheel_w"], SS["caster_z"], SS["trail"]
    for i in range(3):
        a = math.radians(90 + 120 * i)            # one leg straight back, two splayed forward
        d = Vector((math.cos(a), math.sin(a), 0.0))
        t = Vector((-math.sin(a), math.cos(a), 0.0))
        a0 = d * 0.09 + Vector((0, 0, hz - 0.02))
        e = d * SS["reach"] + Vector((0, 0, cz + 0.05))
        s.cylinder(a0, e, SS["leg_r"], SP_CHROME, segs(hi, 10))
        s.cylinder(a0 + (e - a0) * 0.55, d * 0.08 + Vector((0, 0, bz)), 0.016, SP_CHROME,
                   segs(hi, 6))
        c = Vector((e.x, e.y, 0.0))
        s.cylinder(c + Vector((0, 0, cz - 0.03)), c + Vector((0, 0, cz + 0.11)), 0.05, SP_CAST,
                   segs(hi, 12))
        # the caster: a swivel plate, a fork trailing outward and the wheel on its axle
        s.cylinder(c + Vector((0, 0, cz - 0.05)), c + Vector((0, 0, cz - 0.03)), 0.056, SP_ZINC,
                   segs(hi, 12))
        Mf = Matrix.Translation(c) @ Matrix.Rotation(a, 4, "Z")
        for sy in (-1, 1):
            y0, y1 = sorted((sy * (ww / 2 + 0.006), sy * (ww / 2 + 0.018)))
            s.box((-0.04, y0, wr - 0.035), (tr + 0.035, y1, cz - 0.045), SP_ZINC, 0.005,
                  2 if hi else 1, Mf)
        s.box((-0.045, -(ww / 2 + 0.018), cz - 0.058), (0.045, ww / 2 + 0.018, cz - 0.045),
              SP_ZINC, 0.004, 1, Mf)
        w = c + d * tr + Vector((0, 0, wr))
        Mw = (Matrix.Translation(w) @ Matrix.Rotation(a + math.pi / 2, 4, "Z")
              @ Matrix.Rotation(math.pi / 2, 4, "Y"))
        rd = 0.024
        tyre = ([(0.032, -ww / 2)] + fillet(wr - rd, -ww / 2 + rd, rd, (-90, 0), f)
                + fillet(wr - rd, ww / 2 - rd, rd, (0, 90), f) + [(0.032, ww / 2)])
        s.lathe(tyre, SP_RUBBER, segs(hi, 20), Mw)
        s.lathe([(0.0, -ww / 2 - 0.01), (0.034, -ww / 2 - 0.01), (0.036, -ww / 2 + 0.004),
                 (0.036, ww / 2 - 0.004), (0.034, ww / 2 + 0.01), (0.0, ww / 2 + 0.01)], SP_ZINC,
                segs(hi, 12), Mw)
        s.cylinder(w - t * (ww / 2 + 0.03), w + t * (ww / 2 + 0.03), 0.011, SP_ZINC, 6)
    return s


def sp_yoke(hi):
    s = Shape()
    X, r, bz, bd = SY["x"], SY["r"], SY["bar_z"], SY["bend"]
    k = 6 if hi else 3
    path = [(-X, 0.0, SP_TZ - 0.04), (-X, 0.0, bz + bd)]
    path += arc((-X + bd, 0.0, bz + bd), bd, 180, 270, k, "XZ")[1:]
    path += arc((X - bd, 0.0, bz + bd), bd, 270, 360, k, "XZ")
    path += [(X, 0.0, SP_TZ - 0.04)]
    s.tube(path, r, SP_ENAMEL, segs(hi, 10))
    for sx in (-1, 1):
        s.cylinder((sx * (X - 0.035), 0, SP_TZ), (sx * (X + 0.035), 0, SP_TZ), 0.085, SP_ENAMEL,
                   segs(hi, 16))
    # the right arm's pivot bolt: a washer and a hex nut
    s.cylinder((X + 0.035, 0, SP_TZ), (X + 0.048, 0, SP_TZ), 0.06, SP_ZINC, segs(hi, 14))
    s.cylinder((X + 0.048, 0, SP_TZ), (X + 0.084, 0, SP_TZ), 0.042, SP_ZINC, 6)
    # the spigot socket that drops over the stand's pin, and its locking T-screw
    top = SS["top"]
    s.lathe([(0.0, top + 0.004), (0.07, top + 0.004), (0.072, top + 0.012), (0.072, top + 0.05),
             (0.058, top + 0.07), (0.058, bz), (0.0, bz)], SP_ENAMEL, segs(hi, 16))
    zt = top + 0.2
    s.cylinder((0, 0.05, zt), (0, 0.13, zt), 0.011, SP_ZINC, segs(hi, 8))
    s.cylinder((-0.055, 0.13, zt), (0.055, 0.13, zt), 0.012, SP_ZINC, segs(hi, 8))
    return s


def sp_knob(hi):
    """The tilt lock: a four-lobed bakelite knob on a steel stem, out from the yoke's left arm."""
    s = Shape()
    M = Matrix.Translation(SP_KNOB_AT) @ Matrix.Rotation(math.radians(-90), 4, "Y")
    f = 3 if hi else 1
    prof = [(0.0, 0.0), (0.05, 0.0), (0.05, 0.012), (0.024, 0.014), (0.024, 0.05),
            (0.062, 0.054), (0.066, 0.06), (0.066, 0.1)]
    prof += fillet(0.05, 0.1, 0.016, (0, 90), f) + [(0.0, 0.118)]
    kinds = [SP_ZINC] * 4 + [SP_BAKELITE] * (len(prof) - 5)
    s.lathe(prof, SP_BAKELITE, segs(hi, 20), M, kinds=kinds)
    for i in range(4):
        a = math.radians(45 + 90 * i)
        c = (0.068 * math.cos(a), 0.068 * math.sin(a))
        s.cylinder((c[0], c[1], 0.056), (c[0], c[1], 0.108), 0.03, SP_BAKELITE, segs(hi, 12), M=M)
    return s


def sp_can(hi):
    s = Shape()
    n = segs(hi, 40)
    f = 3 if hi else 2
    c = 2 if hi else 1
    co, B = SC["core"], SC["bezel"]
    ri, ro, bf = B["r_in"], B["r_out"], B["front"]
    back, front, seat = SC["back"], SC["front"], SC["lens"]["seat"]
    # the shell in one turn: the domed back, the rear band, the sooty drum the louvres stand
    # round, the front band, the bezel's rolled lip and the lens's well
    p = [(0.0, back - 0.185), (0.28, back - 0.18), (0.45, back - 0.162)]
    p += fillet(0.52, back - 0.12, 0.045, (-90, 0), f)
    p += [(0.565, back - 0.01), (0.54, back), (co, back)]
    kinds = [SP_ENAMEL] * (len(p) - 1)
    p += [(co, front)]
    kinds += [SP_INSIDE]
    q = [(0.55, front + 0.002), (0.578, front + 0.012), (0.578, 0.52), (ro, 0.535)]
    q += fillet(ro - 0.04, 0.615, 0.04, (0, 90), f)
    q += fillet(ri + 0.03, bf - 0.03, 0.03, (90, 180), f)
    kinds += [SP_ENAMEL] * len(q)
    p += q
    p += [(ri, seat), (ri - 0.03, seat)]
    kinds += [SP_INSIDE, SP_INSIDE]
    s.lathe(p, SP_ENAMEL, n, SP_CAN, kinds=kinds)
    # the back: a pressed bead round the dome, the rear focus knob, a maker's plate
    bz_ = back - 0.172
    ring = [(0.33 * math.cos(2 * math.pi * i / 48), 0.33 * math.sin(2 * math.pi * i / 48), bz_)
            for i in range(49)]
    s.tube(ring, 0.011, SP_ENAMEL, segs(hi, 6), SP_CAN, caps=False)
    Mb = SP_CAN @ Matrix.Translation((0.0, 0.0, back - 0.182)) @ Matrix.Rotation(math.pi, 4, "X")
    s.lathe([(0.0, 0.0), (0.05, 0.0), (0.05, 0.012), (0.018, 0.014), (0.018, 0.03), (0.05, 0.032),
             (0.054, 0.04), (0.054, 0.066), (0.046, 0.076), (0.0, 0.078)], SP_BAKELITE,
            segs(hi, 16), Mb, kinds=[SP_ZINC] * 4 + [SP_BAKELITE] * 5)
    s.box((-0.1, 0.15, back - 0.19), (0.1, 0.25, back - 0.172), SP_DIAL, 0.004, 1, SP_CAN)
    for x in (-0.085, 0.085):
        s.cylinder((x, 0.2, back - 0.19), (x, 0.2, back - 0.196), 0.007, SP_ZINC, 6, M=SP_CAN)
    # the louvres, turned like shutters so the drum shows dark between them
    sr, sw, st = SC["slat_r"], SC["slat_w"], SC["slat_t"]
    for i in range(SC["slats"]):
        a = math.radians(360.0 * (i + 0.5) / SC["slats"])
        M = (SP_CAN @ Matrix.Rotation(a, 4, "Z") @ Matrix.Translation((0, sr, 0))
             @ Matrix.Rotation(math.radians(SC["twist"]), 4, "Z"))
        s.box((-sw / 2, -st / 2, back + 0.004), (sw / 2, st / 2, front - 0.004), SP_ENAMEL,
              0.006 if hi else 0.0, c, M)
    # the trunnions the yoke holds, on plates riveted over the louvres
    for sx in (-1, 1):
        x0, x1 = sorted((sx * 0.52, sx * 0.585))
        s.box((x0, -0.15, -0.17), (x1, 0.15, 0.17), SP_ENAMEL, 0.014, c, SP_CAN)
        s.cylinder((sx * 0.58, 0, 0), (sx * (SY["x"] - 0.035), 0, 0), 0.07, SP_ENAMEL,
                   segs(hi, 16), M=SP_CAN)
        for ry in (-0.11, 0.11):
            for rz in (-0.13, 0.13):
                s.cylinder((sx * 0.582, ry, rz), (sx * 0.594, ry, rz), 0.012, SP_ZINC,
                           segs(hi, 8), M=SP_CAN)
    # the carrying handle over the top
    hz, k = -0.04, (6 if hi else 3)
    hp = [(-0.22, 0.54, hz), (-0.22, 0.66, hz)]
    hp += arc((-0.14, 0.66, hz), 0.08, 180, 90, k, "XY")[1:]
    hp += arc((0.14, 0.66, hz), 0.08, 90, 0, k, "XY") + [(0.22, 0.54, hz)]
    s.tube(hp, 0.021, SP_ENAMEL, segs(hi, 8), SP_CAN)
    for sx in (-1, 1):
        s.box((sx * 0.22 - 0.045, 0.52, hz - 0.06), (sx * 0.22 + 0.045, 0.566, hz + 0.06),
              SP_ENAMEL, 0.008, c, SP_CAN)
    # the focus box underneath: its knob out front on a brass scale plate, the toggle's bushing
    bx = SC["box"]
    s.box((-bx["x"], bx["y0"], bx["z0"]), (bx["x"], bx["y1"], bx["z1"]), SP_ENAMEL, 0.018, c,
          SP_CAN)
    s.box((-0.12, -0.7, bx["z1"] - 0.004), (0.12, -0.54, bx["z1"] + 0.004), SP_DIAL, 0.003, 1,
          SP_CAN)
    Mk = SP_CAN @ Matrix.Translation((0.0, -0.615, bx["z1"] + 0.004))
    kp = [(0.0, 0.0), (0.016, 0.0), (0.016, 0.02), (0.052, 0.022), (0.056, 0.03), (0.056, 0.058),
          (0.048, 0.068), (0.0, 0.07)]
    s.lathe(kp, SP_BAKELITE, segs(hi, 16), Mk, kinds=[SP_ZINC, SP_ZINC] + [SP_BAKELITE] * 5)
    s.cylinder(SP_SW_AT, (SP_SW_AT[0] - 0.03, SP_SW_AT[1], SP_SW_AT[2]), 0.019, SP_ZINC, 6,
               M=SP_CAN)
    # the gel clips at the corners, holding the barn doors' frame by its edges
    for sx in (-1, 1):
        for sy in (-1, 1):
            y0, y1 = sy * SDR["clip_y"] - 0.045, sy * SDR["clip_y"] + 0.045
            xs = lambda a, b: sorted((sx * a, sx * b))   # noqa: E731
            x0, x1 = xs(0.28, 0.665)
            s.box((x0, y0, 0.53), (x1, y1, 0.56), SP_ZINC, 0.004, 1, SP_CAN)
            x0, x1 = xs(0.648, 0.665)
            s.box((x0, y0, 0.53), (x1, y1, 0.708), SP_ZINC, 0.004, 1, SP_CAN)
            x0, x1 = xs(0.61, 0.665)
            s.box((x0, y0, 0.692), (x1, y1, 0.708), SP_ZINC, 0.004, 1, SP_CAN)
    # the barn doors' frame, slid into the clips
    F, H, z0, z1 = SDR["frame"], SDR["hole"], SDR["z"], SP_DOOR_Z
    for lo, hi_ in (((-F, H), (F, F)), ((-F, -F), (F, -H)), ((-F, -H), (-H, H)), ((H, -H), (F, H))):
        s.box((lo[0], lo[1], z0), (hi_[0], hi_[1], z1), SP_BLACK, 0.004, 1, SP_CAN)
    # the wire guard over the lens
    for v in (-0.3, -0.1, 0.1, 0.3):
        h = math.sqrt(ri * ri - v * v) - 0.004
        s.cylinder((-h, v, 0.642), (h, v, 0.642), 0.006, SP_ZINC, segs(hi, 5), M=SP_CAN)
        s.cylinder((v, -h, 0.632), (v, h, 0.632), 0.006, SP_ZINC, segs(hi, 5), M=SP_CAN)
    # the cord out of the focus box, hanging to its stage plug
    cp = [(0.08, -0.62, -0.31), (0.08, -0.65, -0.42), (0.1, -0.8, -0.49), (0.12, -0.96, -0.5),
          (0.12, -1.0, -0.5)]
    s.tube(spline(cp, 6 if hi else 3), 0.021, SP_RUBBER, segs(hi, 8), SP_CAN)
    s.cylinder((0.08, -0.62, -0.3), (0.08, -0.62, -0.345), 0.032, SP_RUBBER, segs(hi, 10),
               M=SP_CAN)
    s.box((0.075, -1.17, -0.54), (0.165, -0.99, -0.46), SP_RUBBER, 0.012, c, SP_CAN)
    for x in (0.095, 0.12, 0.145):
        s.cylinder((x, -1.165, -0.5), (x, -1.21, -0.5), 0.0065, SP_BRASS, segs(hi, 6), M=SP_CAN)
    return s


def sp_lens(hi):
    """The stepped Fresnel lens: rings that rise toward their inner edge and drop back."""
    s = Shape()
    Ls = SC["lens"]
    R, seat, face, nst = Ls["r"], Ls["seat"], Ls["face"], Ls["steps"]
    p = [(0.0, seat), (R, seat), (R, face)]
    if hi:
        for k in range(nst, 0, -1):
            r1 = R * (k - 1) / nst
            h = 0.003 + 0.001 * k
            p += [(r1 + 0.0015, face + h), (r1, face)] if k > 1 else [(R / nst * 0.5, face + h * 0.8),
                                                                       (0.0, face + h)]
    else:
        p += [(R * 0.97, face + 0.005), (0.0, face + 0.006)]
    s.lathe(p, SP_GLASS, segs(hi, 40), SP_CAN)
    return s


def sp_switch(hi):
    """The toggle's lever, found down (off)."""
    s = Shape()
    M = SP_CAN @ Matrix.Translation(SP_SW_AT) @ Matrix.Rotation(math.radians(-25), 4, "Z")
    s.cylinder((0.0, 0, 0), (0.055, 0, 0), 0.0075, SP_ZINC, segs(hi, 8), M=M)
    s.cylinder((0.05, 0, 0), (0.064, 0, 0), 0.0105, SP_ZINC, segs(hi, 8), M=M)
    return s


def sp_door_m(side):
    """A leaf's hinge frame in the can's: the hinge along x, the leaf out along z, its outside y."""
    F, z = SDR["frame"], SP_DOOR_Z
    bo, so = math.radians(SDR["big"]["open"]), math.radians(SDR["side"]["open"])
    R = Matrix.Rotation
    if side == "Top":
        return Matrix.Translation((0, F, z)) @ R(-bo, 4, "X")
    if side == "Bottom":
        return Matrix.Translation((0, -F, z)) @ R(bo, 4, "X") @ R(math.pi, 4, "Z")
    if side == "Right":
        return Matrix.Translation((F, 0, z)) @ R(so, 4, "Y") @ R(-math.pi / 2, 4, "Z")
    return Matrix.Translation((-F, 0, z)) @ R(-so, 4, "Y") @ R(math.pi / 2, 4, "Z")


def sp_leaf(side, hi):
    """One barn-door leaf: a tapered black steel sheet, its hinge knuckle, a rolled front edge
    and the little tab you push it by."""
    s = Shape()
    d = SDR["big"] if side in ("Top", "Bottom") else SDR["side"]
    w0, w1, L, t = d["w0"], d["w1"], d["d"], 0.016
    M = SP_CAN @ sp_door_m(side)
    tmp = bmesh.new()
    bmesh.ops.create_cube(tmp, size=1.0)
    for v in tmp.verts:
        u = v.co.z + 0.5
        v.co = Vector((v.co.x * (w0 + (w1 - w0) * u), v.co.y * t, 0.014 + u * (L - 0.014)))
    if hi:
        bmesh.ops.bevel(tmp, geom=list(tmp.edges), offset=0.004, segments=2, profile=0.5,
                        affect="EDGES", clamp_overlap=True)
    bmesh.ops.transform(tmp, matrix=M, verts=tmp.verts)
    s.merge(tmp, SP_BLACK)
    tmp.free()
    s.cylinder((-w0 / 2 + 0.03, 0, 0), (w0 / 2 - 0.03, 0, 0), 0.016, SP_ZINC, segs(hi, 10), M=M)
    s.cylinder((-w1 / 2, 0, L), (w1 / 2, 0, L), 0.011, SP_BLACK, segs(hi, 8), M=M)
    s.box((-0.05, t / 2 - 0.004, L - 0.1), (0.05, t / 2 + 0.03, L - 0.03), SP_BLACK, 0.006,
          2 if hi else 1, M)
    return s


def sp_look(L, f):
    nb = L.nb
    # oxblood hammertone enamel: the dimpled finish old studio lights wore
    paint = nb.tint(hexc("#6E211C"), nb.mr(L.noise(2.2, 2, detail=3), 0.3, 0.7, 0.85, 1.1))
    C = Coat(L, paint, nb.mr(L.noise(6.0, 3, detail=3), 0.2, 0.8, 0.26, 0.42), 0.0,
             nb.mul(L.noise(140.0, 1, detail=2), 0.3))
    C.paint(nb.mul(L.up, nb.mr(L.noise(1.4, 4, detail=3), 0.3, 0.7, 0.1, 0.35)), hexc("#8A3A2E"))
    # the lamp's heat browned the louvres over it
    heat = nb.mul(L.k(SP_ENAMEL), nb.ss(L.z, SP_TZ + 0.3, SP_TZ + 0.62))
    C.paint(nb.mul(heat, nb.mr(L.noise(4.0, 5, detail=3), 0.3, 0.7, 0.35, 0.85)), hexc("#3A1C16"),
            0.55)
    # the barn doors and their frame: black crinkle paint
    C.paint(L.k(SP_BLACK), nb.tint(hexc("#1F1E1D"), nb.mr(L.noise(9.0, 9, detail=3), 0.3, 0.7,
                                                           0.85, 1.15)), 0.62, 0.0)
    C.enamel_wear(L.k(SP_ENAMEL, SP_BLACK), hexc("#4B4743"), s=5, amount=1.5)
    C.paint(L.k(SP_INSIDE), hexc("#141211"), 0.75, 0.0)
    # bright work: zinc-plated fittings, the stand's chrome tubes scratched along their length
    zinc = nb.tint(hexc("#B6B9BB"), nb.mr(L.noise(18.0, 6, detail=4), 0.3, 0.7, 0.72, 1.0))
    C.paint(L.k(SP_ZINC), zinc, nb.mr(L.noise(30.0, 7, detail=3), 0.3, 0.7, 0.24, 0.42), 1.0)
    chrome = nb.tint(hexc("#CFD2D4"), nb.mr(L.noise(30.0, 10, stretch=(1.0, 1.0, 0.06), detail=4),
                                            0.3, 0.7, 0.8, 1.0))
    C.paint(L.k(SP_CHROME), chrome, nb.mr(L.noise(40.0, 11, stretch=(1.0, 1.0, 0.06), detail=3),
                                          0.3, 0.7, 0.1, 0.26), 1.0)
    rust = nb.mul(L.k(SP_ZINC, SP_CHROME), nb.ss(L.noise(40.0, 8, detail=4, rough=0.7), 0.64, 0.72))
    C.paint(rust, hexc("#6B3B22"), 0.85, 0.15, 0.05)
    C.paint(L.k(SP_CAST), hexc("#2A2826"), 0.5, 0.35)
    C.paint(L.k(SP_BAKELITE), hexc("#1B1512"), 0.3, 0.0)
    C.paint(L.k(SP_RUBBER), hexc("#232120"), 0.72, 0.0)
    C.paint(L.k(SP_BRASS), hexc("#A88445"), 0.35, 1.0)
    C.paint(L.k(SP_DIAL), hexc("#B49F6C"), 0.38, 0.8)
    # the lens: pressed glass, pale and cold through its rings, greener toward the edge
    dz = nb.sub(L.z, SP_TZ)
    rad = nb.pw(nb.add(nb.mul(L.x, L.x), nb.mul(dz, dz)), 0.5)
    C.paint(L.k(SP_GLASS), nb.mixc(nb.mr(rad, 0.0, 0.44, 0.0, 1.0), hexc("#C7D0CA"), hexc("#8D9B94")),
            0.14, 0.0)
    C.lights(nb.mul(L.k(SP_GLASS), nb.mr(rad, 0.0, 0.44, 1.0, 0.62)))
    C.finish(f.dust, grime=0.5)
    return C.surface(bump_dist=0.0015, bump=0.45)


SP_ON = SL["switch_on"]
SP_FLIP_ON = [(0.0, 0.0), (0.05, -4.0, "Quad", "Out"), (0.11, SP_ON + 5.0, "Quad", "In"),
              (0.2, SP_ON, "Back", "Out")]
SP_FLIP_OFF = [(0.0, SP_ON), (0.05, SP_ON + 4.0, "Quad", "Out"), (0.11, -5.0, "Quad", "In"),
               (0.2, 0.0, "Back", "Out")]
# aimed by hand: the lock knob backed off, a nudge the wrong way as the weight is taken, a slow
# heavy swing that runs past and settles back, the knob snugged; the loose leaves lag and swing
SP_PAN = [(0.0, 0.0), (0.42, 0.0, "Linear"), (0.6, 2.5, "Quad", "Out"), (1.6, -39.0, "Cubic", "InOut"),
          (1.9, -35.4), (2.15, -36.0)]
SP_TILT = [(0.0, 0.0), (0.5, 0.0, "Linear"), (0.68, -2.0, "Quad", "Out"),
           (1.7, 15.6, "Cubic", "InOut"), (2.0, 13.6), (2.25, 14.0)]
SP_LOCK = [(0.0, 0.0), (0.38, -160.0, "Quad", "InOut"), (2.4, -160.0, "Linear"),
           (2.85, 0.0, "Quad", "InOut")]
SP_SWING_SIDE = [(0.0, 0.0), (0.6, 0.0, "Linear"), (0.95, 2.5), (1.35, -2.0), (1.65, -3.0),
                 (1.85, 1.8), (2.05, -0.9), (2.3, 0.4), (2.5, 0.0)]
SP_SWING_BIG = [(0.0, 0.0), (0.68, 0.0, "Linear"), (1.05, -2.0), (1.45, 1.6), (1.75, 2.6),
                (1.95, -1.4), (2.15, 0.7), (2.4, 0.0)]
SP_LOOK = (0.0, -0.5, SP_TZ - 0.35)
F_ = SDR["frame"]

SPOTLIGHT = kit.Find(
    "Spotlight",
    [kit.Part("Stand", sp_stand),
     kit.Part("Yoke", sp_yoke, (0.0, 0.0, SS["top"]), "Stand", (0, 0, 1)),
     kit.Part("Knob", sp_knob, SP_KNOB_AT, "Yoke", (1, 0, 0)),
     kit.Part("Can", sp_can, (0.0, 0.0, SP_TZ), "Yoke", (1, 0, 0)),
     kit.Part("Lens", sp_lens, sp_c((0.0, 0.0, SC["lens"]["seat"])), "Can"),
     kit.Part("Switch", sp_switch, sp_c(SP_SW_AT), "Can", SP_SW_AXIS),
     kit.Part("DoorTop", lambda hi: sp_leaf("Top", hi), sp_c((0.0, F_, SP_DOOR_Z)), "Can", (1, 0, 0)),
     kit.Part("DoorBottom", lambda hi: sp_leaf("Bottom", hi), sp_c((0.0, -F_, SP_DOOR_Z)), "Can",
              (1, 0, 0)),
     kit.Part("DoorLeft", lambda hi: sp_leaf("Left", hi), sp_c((-F_, 0.0, SP_DOOR_Z)), "Can",
              (0, 0, 1)),
     kit.Part("DoorRight", lambda hi: sp_leaf("Right", hi), sp_c((F_, 0.0, SP_DOOR_Z)), "Can",
              (0, 0, 1))],
    sp_look,
    lights=[
        # the beam: a narrow warm cone out past the barn doors, onto the find it's aimed at
        dict(kind="Spot", part="Lens", at=sp_c((0.0, 0.0, 0.72)), face=(0.0, -1.0, 0.0),
             kelvin=SL["kelvin"], brightness=2.0, range=18, angle=SL["beam"], shadows=True,
             preview_watts=160.0, preview_blend=0.3),
        # the spill round the lens, which also lights at low graphics (docs/STUDIO.md)
        dict(kind="Point", part="Lens", at=sp_c((0.0, 0.0, 0.8)), kelvin=SL["kelvin"],
             brightness=0.35, range=6, shadows=False, preview_kind="POINT", preview_watts=2.0,
             preview_size=0.1),
    ],
    glow=dict(part="Lens", strength=3.0, tint=(255, 200, 140), preview=12.0),
    lit={("Switch", "turn"): SP_ON},
    motions={
        # the toggle snaps up; a breath later the filament strikes and the lens warms through
        # orange to full as a big tungsten lamp does
        "SwitchOn": dict(duration=1.2, focus=SP_LOOK, distance=0.42, tracks=[
            ("Switch", "turn", SP_FLIP_ON),
            ("Lens", "glow", [(0.0, 0.0), (0.11, 0.0, "Linear"), (0.16, 0.12, "Quad", "Out"),
                              (0.8, 1.0, "Quad", "Out"), (1.2, 1.0)])]),
        # flicked down: the light drops at the click and the filament dies away orange
        "SwitchOff": dict(duration=1.2, focus=SP_LOOK, distance=0.42, tracks=[
            ("Switch", "turn", SP_FLIP_OFF),
            ("Lens", "glow", [(0.0, 1.0), (0.11, 1.0, "Linear"), (0.15, 0.35, "Quad", "Out"),
                              (1.0, 0.0, "Sine", "Out"), (1.2, 0.0)])]),
        # pointed at a find: pan and tilt on the real pivots (the game aims it at any angle,
        # tilt within 70 degrees either way; README)
        "Aim": dict(duration=3.0, focus=SP_LOOK, distance=0.5, tracks=[
            ("Knob", "turn", SP_LOCK), ("Yoke", "turn", SP_PAN), ("Can", "turn", SP_TILT),
            ("DoorLeft", "turn", SP_SWING_SIDE), ("DoorRight", "turn", SP_SWING_SIDE),
            ("DoorTop", "turn", SP_SWING_BIG), ("DoorBottom", "turn", SP_SWING_BIG)]),
    },
    big=True, dust=SL["dust"], seed=SL["seed"],
)

# --- the stained-glass lamp --------------------------------------------------------------------

(SG_AMBER1, SG_AMBER2, SG_AMBER3, SG_RUBY1, SG_RUBY2, SG_GREEN1, SG_GREEN2, SG_GREEN3,
 SG_COBALT1, SG_COBALT2, SG_GOLD, SG_JEWEL, SG_CRACK, SG_LEAD, SG_RIM, SG_BRONZE, SG_BRONZE_IN,
 SG_CAP, SG_BRASS, SG_BULB, SG_CHAIN) = range(159, 180)
SG_GLASS = (SG_AMBER1, SG_AMBER2, SG_AMBER3, SG_RUBY1, SG_RUBY2, SG_GREEN1, SG_GREEN2, SG_GREEN3,
            SG_COBALT1, SG_COBALT2, SG_GOLD, SG_JEWEL)
SGK = K.STAINED_GLASS
SGS = SGK["shade"]
TAU = 2.0 * math.pi
SG_CH = SGK["chain"]
SG_CHAIN_A = (SG_CH["x"], 0.0, SG_CH["z"])
SG_CHAIN_B = (-SG_CH["x"], 0.0, SG_CH["z"])


def sg_rz(z, cone=None):
    """The shade's outside radius at height z and its slope dr/dz, on the apron or the cone
    (at the crease between them, `cone` says which)."""
    S = SGS
    if cone is None:
        cone = z > S["z1"]
    if not cone:
        k = (S["r1"] - S["r0"]) / (S["z1"] - S["z0"])
        return S["r0"] + k * (z - S["z0"]), k
    h = S["top"] - S["z1"]
    t = (z - S["z1"]) / h
    r = S["r1"] + (S["r_top"] - S["r1"]) * t + S["belly"] * math.sin(math.pi * t)
    return r, ((S["r_top"] - S["r1"]) + S["belly"] * math.pi * math.cos(math.pi * t)) / h


def sg_P(th, z, off=0.0, cone=None):
    """A point on the shade at angle th (round from +X) and height z, moved off along its normal
    (out positive, in negative)."""
    r, dr = sg_rz(z, cone)
    n = math.hypot(1.0, dr)
    rr = r + off / n
    return Vector((rr * math.cos(th), rr * math.sin(th), z - off * dr / n))


def sg_N(th, z, cone=None):
    return (sg_P(th, z, 1.0, cone) - sg_P(th, z, 0.0, cone)).normalized()


def sg_pieces():
    """Every glass piece as (kind, [(th, z), ...] anticlockwise seen from outside, cone?).
    Our own pattern in the leaded tradition: a border of gold diamonds on cobalt round the
    apron; a band of twelve ruby four-petal blossoms with gold hearts and leaves on green;
    four rows of honey bricks, each row half a brick round from the last, to the top."""
    S, B, R, A = SGS, SGK["band"], SGK["bricks"], SGK["apron"]
    rng = random.Random(83)
    h = S["top"] - S["z1"]
    out = []
    n = A["n"]

    def ap(u, v):
        return (u * TAU / n, S["z0"] + (S["z1"] - S["z0"]) * v)
    for c in range(n):
        out.append((SG_GOLD, [ap(c + 0.5, 0.0), ap(c + 1.0, 0.5), ap(c + 0.5, 1.0), ap(c, 0.5)], False))
        out.append((SG_COBALT1 if c % 2 else SG_COBALT2, [ap(c + 1.0, 0.5), ap(c + 1.5, 1.0), ap(c + 0.5, 1.0)], False))
        out.append((SG_COBALT2 if c % 2 else SG_COBALT1, [ap(c + 0.5, 0.0), ap(c + 1.5, 0.0), ap(c + 1.0, 0.5)], False))
    nb_ = B["n"]
    T, Bm, Lf, Rt, Cc = (0.5, 0.92), (0.5, 0.16), (0.2, 0.55), (0.8, 0.55), (0.5, 0.55)
    hu, hv = 0.075, 0.095
    Cr, Cl, Ct, Cb = (Cc[0] + hu, Cc[1]), (Cc[0] - hu, Cc[1]), (Cc[0], Cc[1] + hv), (Cc[0], Cc[1] - hv)
    left = [
        (SG_GREEN2, [(0.5, 0.0), Bm, (0.3, 0.3)]),                         # a leaf
        (SG_GREEN1, [(0.0, 0.0), (0.5, 0.0), (0.3, 0.3), (0.0, 0.55)]),
        (SG_GREEN3, [(0.3, 0.3), Bm, Lf, (0.0, 0.55)]),
        (SG_GREEN1, [(0.0, 0.55), Lf, T, (0.5, 1.0), (0.0, 1.0)]),
        (SG_RUBY1, [Lf, Bm, Cb, Cl]),                                       # petals
        (SG_RUBY2, [T, Lf, Cl, Ct]),
    ]
    cell = []
    for k, poly in left:
        cell.append((k, poly))
        mk = {SG_RUBY1: SG_RUBY2, SG_RUBY2: SG_RUBY1, SG_GREEN1: SG_GREEN3, SG_GREEN3: SG_GREEN1}.get(k, k)
        cell.append((mk, [(1.0 - u, v) for (u, v) in reversed(poly)]))
    cell.append((SG_GOLD, [Cb, Cr, Ct, Cl]))                                # the heart
    t1 = B["t1"]
    for c in range(nb_):
        for k, poly in cell:
            out.append((k, [((c + u) * TAU / nb_, S["z1"] + h * t1 * v) for (u, v) in poly], True))
    ts, ns = R["t"], R["n"]
    for row, m in enumerate(ns):
        za, zb = S["z1"] + h * ts[row], S["z1"] + h * ts[row + 1]
        sh = 0.5 * (row % 2)
        for i in range(m):
            a0, a1 = (i + sh) * TAU / m, (i + 1 + sh) * TAU / m
            k = rng.choices((SG_AMBER1, SG_AMBER2, SG_AMBER3), (0.45, 0.35, 0.2))[0]
            out.append((k, [(a0, za), (a1, za), (a1, zb), (a0, zb)], True))
    return out


SG_ZJ = SGS["z1"] + (SGS["top"] - SGS["z1"]) * SGK["band"]["t1"] * 0.55   # where the jewels sit


def sg_tri(s, A, B_, C_, kind, off, m, flip, cone):
    """A triangle of the shade in (angle, height), cut m times along each side so it follows
    the curve, laid on the surface off along its normal."""
    vs = {}

    def V(i, j):
        if (i, j) not in vs:
            th = A[0] + (B_[0] - A[0]) * i / m + (C_[0] - A[0]) * j / m
            z = A[1] + (B_[1] - A[1]) * i / m + (C_[1] - A[1]) * j / m
            vs[(i, j)] = s.bm.verts.new(sg_P(th, z, off, cone))
        return vs[(i, j)]
    for i in range(m):
        for j in range(m - i):
            tris = [(V(i, j), V(i + 1, j), V(i, j + 1))]
            if i + j < m - 1:
                tris.append((V(i + 1, j), V(i + 1, j + 1), V(i, j + 1)))
            for t in tris:
                s._f(list(reversed(t)) if flip else list(t), kind)


def sg_len(a, b, cone):
    return (sg_P(b[0], b[1], 0.0, cone) - sg_P(a[0], a[1], 0.0, cone)).length


def sg_piece(s, kind, poly, cone, off, flip):
    """One piece of glass: a fan from its middle, its sides cut into short runs."""
    c = (sum(p[0] for p in poly) / len(poly), sum(p[1] for p in poly) / len(poly))
    rim = []
    for a, b in zip(poly, poly[1:] + poly[:1]):
        n = max(1, math.ceil(sg_len(a, b, cone) / 0.03))
        rim += [(a[0] + (b[0] - a[0]) * i / n, a[1] + (b[1] - a[1]) * i / n) for i in range(n)]
    for a, b in zip(rim, rim[1:] + rim[:1]):
        m = max(1, min(4, math.ceil(max(sg_len(c, a, cone), sg_len(c, b, cone)) / 0.03)))
        sg_tri(s, c, a, b, kind, off, m, flip, cone)


def sg_leads(pieces):
    """Every lead line once: each piece's sides, shared sides counted once, without the rims
    (the heavier came) and the crease between apron and cone (its own ring)."""
    S = SGS
    seen, out = set(), []
    for k, poly, cone in pieces:
        for a, b in zip(poly, poly[1:] + poly[:1]):
            if any(abs(a[1] - z) < 1e-6 and abs(b[1] - z) < 1e-6 for z in (S["z0"], S["z1"], S["top"])):
                continue
            key = tuple(sorted((round(p[0] % TAU, 5) % round(TAU, 5), round(p[1], 5)) for p in (a, b)))
            if key in seen:
                continue
            seen.add(key)
            out.append((a, b, cone))
    return out


def sg_ring(s, z, off, r, cone, hi, kind=SG_RIM):
    n = segs(hi, 64)
    pts = [sg_P(TAU * i / n, z, off, cone) for i in range(n + 1)]
    s.tube(pts, r, kind, sides=6 if hi else 4, caps=False)


def sg_frame(p, nrm):
    return Matrix.Translation(p) @ nrm.to_track_quat("Z", "Y").to_matrix().to_4x4()


SG_CRACK_PATH = [[(14.82, 0.0), (14.88, 0.08), (14.86, 0.14), (14.95, 0.22), (14.99, 0.3),
                  (15.04, 0.37)],
                 [(14.95, 0.22), (15.08, 0.25), (15.19, 0.21)]]


def sg_profile():
    """The shade's game shell: up the outside, over the top, down the inside."""
    S, w = SGS, SGS["wall"]
    zs = [S["z0"], (S["z0"] + S["z1"]) / 2, S["z1"]]
    zc = [S["z1"] + (S["top"] - S["z1"]) * i / 14 for i in range(1, 15)]

    def rz(z, off, cone):
        p = sg_P(0.0, z, off, cone)
        return (p.x, p.z)
    out = [rz(z, 0.0, False) for z in zs] + [rz(z, 0.0, True) for z in zc]
    inn = [rz(z, -w, False) for z in zs] + [rz(S["z1"], -w, True)] + [rz(z, -w, True) for z in zc]
    prof = out + list(reversed(inn)) + [out[0]]
    no = len(out) - 1
    kinds = [SG_AMBER1 if i < no else (SG_RIM if i == no or i == len(prof) - 2 else SG_GREEN1)
             for i in range(len(prof) - 1)]
    return prof, kinds


def sg_shade(hi):
    """The leaded shade, its vented cap and finial, the spider under it and the two bulbs.
    The game mesh is a plain shell; the detailed one is the glass, piece by piece, both faces,
    with half-round lead lines over every join, inside and out, so the bake draws the pattern
    and the leading's relief exactly; amber cabochons where the blossoms' leaves meet; one
    cobalt piece in the apron has a hairline crack, as old shades do (it's Fragile)."""
    s = Shape()
    S, w = SGS, SGS["wall"]
    if hi:
        pieces = sg_pieces()
        for k, poly, cone in pieces:
            sg_piece(s, k, poly, cone, 0.0, False)
            sg_piece(s, k, poly, cone, -w, True)
        for a, b, cone in sg_leads(pieces):
            n = max(2, math.ceil(sg_len(a, b, cone) / 0.02))
            for off in (0.0, -w):
                pts = [sg_P(a[0] + (b[0] - a[0]) * i / n, a[1] + (b[1] - a[1]) * i / n, off, cone)
                       for i in range(n + 1)]
                s.tube(pts, S["lead"], SG_LEAD, sides=6)
        for z, cone, r in ((S["z0"], False, S["rim"]), (S["top"], True, S["rim"] * 0.9),
                           (S["z1"], False, S["lead"] * 1.15)):
            for off in (0.0, -w):
                sg_ring(s, z, off, r, cone, hi)
        prof, kinds = sg_profile()
        no = len([k for k in kinds if k == SG_AMBER1])
        s.lathe(prof[no:no + 2], SG_RIM, 128)
        s.lathe(prof[-2:], SG_RIM, 128)
        J = SGK["jewel"]
        nb_ = SGK["band"]["n"]
        for c in range(nb_):
            th = c * TAU / nb_
            M = sg_frame(sg_P(th, SG_ZJ, 0.0, True), sg_N(th, SG_ZJ, True))
            r, up = J["r"], J["rise"]
            s.lathe([(r, -0.002), (r * 0.95, up * 0.22), (r * 0.75, up * 0.62), (r * 0.45, up * 0.9),
                     (0.0, up)], SG_JEWEL, 24, M)
            ring = [M @ Vector((math.cos(a) * (r + 0.002), math.sin(a) * (r + 0.002), 0.0))
                    for a in [TAU * i / 24 for i in range(25)]]
            s.tube(ring, S["lead"], SG_LEAD, sides=6, caps=False)
        na = SGK["apron"]["n"]
        for path in SG_CRACK_PATH:
            for off in (0.0007, -w - 0.0007):
                pts = []
                for (u0, v0), (u1, v1) in zip(path, path[1:]):
                    for i in range(4):
                        u, v = u0 + (u1 - u0) * i / 4, v0 + (v1 - v0) * i / 4
                        pts.append(sg_P(u * TAU / na, S["z0"] + (S["z1"] - S["z0"]) * v, off, False))
                u, v = path[-1]
                pts.append(sg_P(u * TAU / na, S["z0"] + (S["z1"] - S["z0"]) * v, off, False))
                s.tube(pts, 0.0017, SG_CRACK, sides=4)
    else:
        prof, kinds = sg_profile()
        s.lathe(prof, SG_AMBER1, 48, kinds=kinds)
    # the vented cap over the top row, and the finial that holds it all on the pipe
    cap = [(0.016, 2.06), (0.195, 2.019), (0.228, 2.014), (0.238, 2.018), (0.24, 2.028),
           (0.232, 2.036), (0.19, 2.054), (0.15, 2.072), (0.11, 2.088), (0.075, 2.098),
           (0.058, 2.102), (0.05, 2.108), (0.034, 2.114), (0.03, 2.124), (0.036, 2.132),
           (0.045, 2.146), (0.046, 2.158), (0.04, 2.172), (0.03, 2.184), (0.018, 2.194),
           (0.006, 2.2), (0.0, 2.201)]
    ck = [SG_BRONZE_IN, SG_BRONZE_IN] + [SG_CAP] * 9 + [SG_BRONZE] * (len(cap) - 12)
    s.lathe(cap, SG_CAP, segs(hi, 32), kinds=ck)
    # the spider: a ring inside the top row and three arms to the pipe
    zsp, rsp = 2.008, 0.192
    s.tube([(rsp * math.cos(a), rsp * math.sin(a), zsp) for a in [TAU * i / 32 for i in range(33)]],
           0.0055, SG_BRONZE, sides=6, caps=False)
    for i in range(3):
        a = TAU * i / 3 + 0.5
        s.cylinder(Vector((0.014 * math.cos(a), 0.014 * math.sin(a), zsp)),
                   Vector((rsp * math.cos(a), rsp * math.sin(a), zsp)), 0.005, SG_BRONZE, 6)
    # two frosted bulbs in the sockets
    bulb = [(0.0, 1.60), (0.02, 1.60), (0.023, 1.635), (0.03, 1.66), (0.058, 1.70), (0.082, 1.74),
            (0.092, 1.78), (0.088, 1.815), (0.07, 1.846), (0.04, 1.864), (0.0, 1.87)]
    for x in (SGK["sockets"]["x"], -SGK["sockets"]["x"]):
        s.lathe(bulb, SG_BULB, segs(hi, 24), Matrix.Translation((x, 0.0, 0.0)))
    return s


SG_STEM = [(0.0, 0.012), (0.29, 0.012), (0.31, 0.0), (0.335, 0.0), (0.342, 0.01), (0.342, 0.028),
           (0.334, 0.038), (0.305, 0.045), (0.27, 0.058), (0.22, 0.082), (0.17, 0.106),
           (0.138, 0.126), (0.122, 0.146), (0.127, 0.16), (0.119, 0.176), (0.088, 0.188),
           (0.072, 0.208), (0.061, 0.26), (0.057, 0.31), (0.063, 0.355), (0.084, 0.395),
           (0.092, 0.425), (0.082, 0.455), (0.052, 0.478), (0.043, 0.53), (0.04, 0.72),
           (0.043, 0.89), (0.058, 0.92), (0.066, 0.945), (0.059, 0.968), (0.042, 0.988),
           (0.038, 1.15), (0.036, 1.3), (0.041, 1.355), (0.055, 1.375), (0.058, 1.398),
           (0.05, 1.418), (0.03, 1.43), (0.034, 1.442), (0.054, 1.452), (0.06, 1.47),
           (0.06, 1.515), (0.047, 1.532), (0.013, 1.54), (0.013, 2.13), (0.0, 2.13)]


def sg_base(hi):
    """The cast bronze base: a weighted round foot stepped up to a dome, a turned stem with a
    vase knop and two rings, the cluster at its top with two arms out to brass pull-chain
    sockets, and the pipe running up the middle to the finial."""
    s = Shape()
    kinds = [SG_BRONZE_IN] + [SG_BRONZE] * (len(SG_STEM) - 2)
    s.lathe(SG_STEM, SG_BRONZE, segs(hi, 32), kinds=kinds)
    So = SGK["sockets"]
    sock = [(0.0, So["z0"]), (0.028, So["z0"]), (0.034, So["z0"] + 0.01), (0.034, 1.5),
            (0.0365, 1.505), (0.0365, 1.515), (0.034, 1.52), (So["r"], 1.585), (0.031, 1.595),
            (0.022, So["z1"]), (0.0, So["z1"])]
    for sx in (1.0, -1.0):
        x = So["x"] * sx
        s.lathe(sock, SG_BRASS, segs(hi, 24), Matrix.Translation((x, 0.0, 0.0)))
        s.cylinder(Vector((0.04 * sx, 0.0, 1.49)), Vector((x - 0.028 * sx, 0.0, 1.49)), 0.011,
                   SG_BRONZE, segs(hi, 10))
        s.cylinder(Vector((x + 0.031 * sx, 0.0, SG_CH["z"])), Vector((SG_CH["x"] * sx, 0.0, SG_CH["z"])),
                   0.0075, SG_BRASS, segs(hi, 8))
    return s


def sg_chain(sx):
    def build(hi):
        """A brass ball chain hanging from the socket's side, and its little bronze pull."""
        s = Shape()
        x, z0, z1, rb = SG_CH["x"] * sx, SG_CH["z"] - 0.006, SG_CH["end"], SG_CH["bead"]
        if hi:
            n = int((z0 - z1) / SG_CH["step"])
            for i in range(n + 1):
                z = z0 - i * (z0 - z1) / n
                s.lathe([(0.0, -rb), (rb * 0.7, -rb * 0.7), (rb, 0.0), (rb * 0.7, rb * 0.7), (0.0, rb)],
                        SG_CHAIN, 10, Matrix.Translation((x, 0.0, z)))
            s.cylinder(Vector((x, 0.0, z0)), Vector((x, 0.0, z1)), 0.0016, SG_CHAIN, 6)
        else:
            s.cylinder(Vector((x, 0.0, z0 + 0.005)), Vector((x, 0.0, z1)), rb * 0.8, SG_CHAIN, 6)
        pull = [(0.0, z1 + 0.002), (0.006, z1 + 0.002), (0.012, z1 - 0.007), (0.016, z1 - 0.026),
                (0.017, z1 - 0.042), (0.014, z1 - 0.049), (0.0, z1 - 0.051)]
        s.lathe(pull, SG_BRONZE, segs(hi, 16), Matrix.Translation((x, 0.0, 0.0)))
        return s
    return build


SG_GLASS_COL = {SG_AMBER1: "#B0611A", SG_AMBER2: "#CC8C34", SG_AMBER3: "#8E4416",
                SG_RUBY1: "#86121A", SG_RUBY2: "#A8242E", SG_GREEN1: "#284F22",
                SG_GREEN2: "#788526", SG_GREEN3: "#35632C", SG_COBALT1: "#1D2F86",
                SG_COBALT2: "#2A4A9C", SG_GOLD: "#D9A43A", SG_JEWEL: "#E08A18"}


def sg_look(L, f):
    nb = L.nb
    ang = nb.math("ARCTAN2", L.y, L.x)
    rad = nb.pw(nb.add(nb.mul(L.x, L.x), nb.mul(L.y, L.y)), 0.5)
    # cast bronze, patinated near black-brown, a dull green bloom in patches, rubbed back to
    # warm metal on the edges hands and dusters reach
    C = Coat(L, hexc("#3E2F22"), 0.45, 1.0)
    bz = L.k(SG_BRONZE, SG_CAP)
    C.paint(bz, nb.tint(hexc("#3B2C1F"), nb.mr(L.noise(30.0, 31, detail=4), 0.3, 0.7, 0.8, 1.18)),
            nb.mr(L.noise(25.0, 32, detail=3), 0.3, 0.7, 0.36, 0.55), 1.0)
    C.paint(nb.mul(bz, nb.ss(L.noise(5.0, 33, detail=5, rough=0.65), 0.57, 0.7)), hexc("#3D4433"), 0.6, 0.5)
    rub = nb.mul(bz, nb.mul(L.edge(0.006, k=4.0), nb.ss(L.noise(18.0, 34, detail=3), 0.38, 0.52)))
    C.paint(rub, hexc("#93703F"), 0.28, 1.0)
    C.paint(L.k(SG_BRONZE_IN), hexc("#1D1712"), 0.75, 0.3)
    # the cap's vents: rings of holes the bulbs' light shows through
    holes = 0.0
    for rho, n in SGK["cap"]["holes"]:
        du = nb.mul(nb.sub(nb.fract(nb.add(nb.mul(ang, n / TAU), 0.5)), 0.5), TAU * rho / n)
        dr = nb.sub(rad, rho)
        d = nb.pw(nb.add(nb.mul(du, du), nb.mul(dr, dr)), 0.5)
        hr = SGK["cap"]["hole_r"]
        h1 = nb.ss(d, hr, hr * 0.7)
        holes = h1 if isinstance(holes, float) else nb.add(holes, h1, clamp=True)
    holes = nb.mul(L.k(SG_CAP), nb.mul(holes, nb.ss(L.z, 2.04, 2.05)))
    C.paint(holes, hexc("#4A3216"), 0.9, 0.0, nb.mul(holes, -1.0))
    # brass sockets and chain, tarnished
    br = L.k(SG_BRASS, SG_CHAIN)
    C.paint(br, nb.tint(hexc("#B08E4C"), nb.mr(L.noise(40.0, 35, detail=3), 0.3, 0.7, 0.85, 1.08)), 0.32, 1.0)
    C.paint(nb.mul(br, nb.ss(L.noise(8.0, 36, detail=4), 0.5, 0.64)), hexc("#6E5A32"), 0.5)
    # the lead: dull grey, darkened with patina, a coppery cast here and there
    ld = L.k(SG_LEAD, SG_RIM)
    C.paint(ld, nb.tint(hexc("#3A3631"), nb.mr(L.noise(40.0, 37, detail=3), 0.3, 0.7, 0.75, 1.2)), 0.5, 0.7)
    C.paint(nb.mul(ld, nb.ss(L.noise(9.0, 38, detail=4), 0.56, 0.68)), hexc("#4B3424"), 0.5, 0.6)
    # the glass: each piece its colour, streaked along the cone as rolled glass is, with milky
    # opal wisps, a little rippled; glossy, and every piece glows when lit
    streak = nb.mr(L.noise(14.0, 39, stretch=(1.0, 1.0, 0.3), detail=4, rough=0.6), 0.28, 0.72, 0.62, 1.38)
    glass = L.k(*SG_GLASS)
    for k, col in SG_GLASS_COL.items():
        C.paint(L.k(k), nb.tint(hexc(col), streak), 0.1, 0.0)
    wisp = nb.mul(glass, nb.ss(L.noise(6.0, 40, stretch=(1.0, 1.0, 0.4), detail=5, rough=0.62, distortion=0.6), 0.6, 0.78))
    C.paint(nb.mul(wisp, 0.42), hexc("#F2DDB4"), 0.14)
    C.paint(glass, height=nb.mul(glass, nb.mul(L.noise(60.0, 41, detail=2), 0.35)))
    C.paint(L.k(SG_JEWEL), rough=0.04)
    # the crack: a pale hairline that catches light off and burns bright lit
    cr = L.k(SG_CRACK)
    C.paint(cr, hexc("#E6E1D2"), 0.3, 0.0)
    bulb = L.k(SG_BULB)
    C.paint(bulb, hexc("#ECE7DA"), 0.45, 0.0)
    C.lights(nb.add(nb.add(glass, cr, clamp=True), nb.add(bulb, nb.mul(holes, 0.9), clamp=True), clamp=True))
    C.finish(f.dust, grime=0.4, keep=bulb)
    return C.surface(bump_dist=0.0006, bump=0.4)


SG_FOCUS = (0.06, 0.0, 1.22)   # between the chains, under the shade's rim
SG_PULL = [(0.0, 1.0), (0.12, 1.09, "Quad", "Out"), (0.17, 1.1), (0.23, 0.985, "Quad", "In"),
           (0.31, 1.012), (0.4, 1.0)]
SG_SWING = [(0.0, 0.0), (0.12, -5.0, "Quad", "Out"), (0.17, -5.0), (0.32, 9.0, "Sine", "Out"),
            (0.56, -6.5), (0.8, 4.4), (1.04, -2.7), (1.28, 1.5), (1.52, -0.6), (1.75, 0.0)]
SG_SYMPATHY = [(0.0, 0.0), (0.26, 0.0), (0.46, 2.4), (0.7, -1.9), (0.95, 1.3), (1.2, -0.7),
               (1.45, 0.3), (1.75, 0.0)]
SG_COLOURS = ((-90.0, (255, 74, 58)), (30.0, (120, 220, 90)), (150.0, (80, 120, 255)))
STAINED_GLASS_LAMP = kit.Find(
    "StainedGlassLamp",
    [kit.Part("Base", sg_base),
     kit.Part("Shade", sg_shade, (0.0, 0.0, SGS["z0"]), "Base", (0, 0, 1)),
     kit.Part("ChainA", sg_chain(1.0), SG_CHAIN_A, "Base", (0, 1, 0)),
     kit.Part("ChainB", sg_chain(-1.0), SG_CHAIN_B, "Base", (0, 1, 0))],
    sg_look,
    lights=[
        # the bulbs' warm pool on the table and floor, out of the shade's open foot
        dict(kind="Spot", part="Shade", at=(0.0, 0.0, 1.62), face=(0.0, 0.0, -1.0),
             kelvin=SGK["kelvin"], brightness=0.6, range=10, angle=110, shadows=True,
             preview_watts=30.0, preview_blend=0.3),
        # the glow all round, dim (the glass holds most of it back)
        dict(kind="Point", part="Shade", at=(0.0, 0.0, 1.75), kelvin=SGK["kelvin"], brightness=0.3,
             range=8, shadows=False, preview_kind="POINT", preview_watts=4.0, preview_size=0.05),
    ] + [
        # the coloured patterns on your walls: ruby out the front, green and cobalt behind
        dict(kind="Spot", part="Shade", at=(0.25 * math.cos(math.radians(a)), 0.25 * math.sin(math.radians(a)), 1.6),
             face=tuple(Vector((math.cos(math.radians(a)), math.sin(math.radians(a)), -0.3)).normalized()),
             rgb=rgb, brightness=0.5, range=9, angle=70, shadows=False, preview_watts=40.0,
             preview_blend=0.4)
        for a, rgb in SG_COLOURS],
    glow=dict(part="Shade", strength=1.8, tint=(255, 222, 180), preview=2.2),
    motions={
        # a tug on the chain: it gives, clicks, springs back and swings; the bulbs come up
        # through the glass in a breath, as a filament does; the other chain sways in sympathy
        "SwitchOn": dict(duration=1.75, focus=SG_FOCUS, distance=0.28, tracks=[
            ("ChainA", "stretch", SG_PULL), ("ChainA", "turn", SG_SWING),
            ("ChainB", "turn", SG_SYMPATHY),
            ("Shade", "glow", [(0.0, 0.0), (0.16, 0.0), (0.22, 0.62, "Quad", "Out"),
                               (0.42, 1.0, "Sine", "Out"), (1.75, 1.0)])]),
        # the same tug; the filaments fade out through orange
        "SwitchOff": dict(duration=1.75, focus=SG_FOCUS, distance=0.28, tracks=[
            ("ChainA", "stretch", SG_PULL), ("ChainA", "turn", SG_SWING),
            ("ChainB", "turn", SG_SYMPATHY),
            ("Shade", "glow", [(0.0, 1.0), (0.16, 1.0), (0.21, 0.42, "Quad", "Out"),
                               (0.36, 0.07), (0.55, 0.0), (1.75, 0.0)])]),
    },
    big=True, dust=SGK["dust"], seed=SGK["seed"],
)

# --- the lamp that's on when you find it (Secret) ----------------------------------------------

(UL_BRASS, UL_BRASS_IN, UL_FELT, UL_SOCKET, UL_KNURL, UL_KEY, UL_HARP, UL_PARCH, UL_PARCH_IN,
 UL_BEAD, UL_LACE, UL_SEAM, UL_BULB, UL_CORD, UL_PLUG, UL_PRONG, UL_FIBRE) = range(180, 197)
UL = K.UNPLUGGED
ULS = UL["shade"]
ULK = UL["key"]
ULSO = UL["socket"]
UL_KDIR = Vector((math.sin(math.radians(ULK["yaw"])), -math.cos(math.radians(ULK["yaw"])), 0.0))
UL_KEY_AT = Vector((0.0, 0.0, ULK["z"])) + UL_KDIR * ULSO["r"]
UL_BULB_C = Vector((0.0, 0.0, 1.87))   # the middle of the bulb's glass, where the light comes from

# the base's turned profile, foot to the top of the column, around the reeded shaft
UL_FOOT = [(0.0, 0.004), (0.29, 0.004), (0.296, 0.0), (0.316, 0.0), (0.322, 0.003), (0.325, 0.009),
           (0.325, 0.026), (0.322, 0.033), (0.313, 0.037), (0.3, 0.038), (0.295, 0.041),
           (0.293, 0.05), (0.288, 0.055), (0.274, 0.058), (0.262, 0.062), (0.245, 0.072),
           (0.222, 0.086), (0.195, 0.1), (0.165, 0.112), (0.136, 0.122), (0.112, 0.132),
           (0.095, 0.143), (0.084, 0.156), (0.079, 0.168), (0.084, 0.172), (0.089, 0.179),
           (0.087, 0.186), (0.079, 0.191), (0.066, 0.194), (0.064, 0.2), (0.072, 0.214),
           (0.083, 0.233), (0.091, 0.255), (0.094, 0.278), (0.091, 0.3), (0.082, 0.322),
           (0.068, 0.343), (0.055, 0.362), (0.048, 0.378), (0.046, 0.39), (0.052, 0.394),
           (0.06, 0.4), (0.062, 0.409), (0.06, 0.418), (0.052, 0.424), (0.046, 0.428),
           (0.044, 0.436)]
UL_TOP = [(0.036, 1.096), (0.044, 1.1), (0.05, 1.106), (0.051, 1.115), (0.046, 1.122),
          (0.04, 1.126), (0.04, 1.14), (0.046, 1.165), (0.054, 1.2), (0.059, 1.235), (0.06, 1.262),
          (0.057, 1.282), (0.049, 1.296), (0.05, 1.3), (0.05, 1.31), (0.04, 1.314), (0.012, 1.314),
          (0.012, 1.334), (0.0, 1.334)]


def ul_harp_path():
    """The harp's wire, left sleeve up round the bulb to the top and down to the right."""
    top = UL["harp"]["top"] - 0.005
    right = [(0.066, 1.362), (0.068, 1.40), (0.084, 1.46), (0.112, 1.53), (0.138, 1.62),
             (0.154, 1.72), (0.161, 1.82), (0.16, 1.92), (0.153, 2.02), (0.138, 2.12),
             (0.117, 2.21), (0.09, 2.29), (0.06, 2.345), (0.03, top - 0.008), (0.0, top)]
    left = [(-x, z) for x, z in right[:-1]]
    path = left + [right[-1]] + list(reversed(right[:-1]))
    return [(x, 0.0, z) for x, z in spline(path, 2)]


def ul_base(hi):
    """The spun brass foot stepped up to an ogee dome, a bead, an urn, a collar, the reeded
    column, a cup at its top; the harp's saddle and sleeves; the socket's knurled cap and
    shell; the harp; the cord out of the foot at the back, across the floor to its plug."""
    s = Shape()
    n = segs(hi, 40)
    fk = [UL_FELT, UL_BRASS_IN] + [UL_BRASS] * (len(UL_FOOT) - 3)
    z0, z1, r0, r1, reeds, depth = UL["shaft"]
    if hi:
        s.lathe(UL_FOOT, UL_BRASS, n, kinds=fk)
        # the reeds: rounded ridges up the column, dying into the rings at each end
        m = reeds * 8
        rings = []
        nz = 40
        for i in range(nz + 1):
            z = z0 + (z1 - z0) * i / nz
            r = r0 + (r1 - r0) * i / nz
            end = min(z - z0, z1 - z) / 0.018
            dz = depth * (min(1.0, end) ** 0.5 if end > 0 else 0.0)
            ring = []
            for j in range(m):
                a = TAU * j / m
                u = (reeds * a / TAU) % 1.0
                rr = r - dz + dz * math.sqrt(max(0.0, 1.0 - (2 * u - 1) ** 2))
                ring.append((rr * math.cos(a), rr * math.sin(a), z))
            rings.append(ring)
        s.loft(rings, UL_BRASS)
        s.lathe(UL_TOP, UL_BRASS, n)
    else:
        s.lathe(UL_FOOT + UL_TOP, UL_BRASS, n, kinds=fk + [UL_BRASS] * len(UL_TOP))
    # the harp's saddle under the socket, its two sleeves
    sd = UL["saddle"]
    s.box((-sd["x"] - 0.012, -sd["w"] / 2, sd["z"]), (sd["x"] + 0.012, sd["w"] / 2, sd["z"] + sd["t"]),
          UL_HARP, 0.002 if hi else 0.0, 2 if hi else 1)
    for sx in (-1, 1):
        s.cylinder(Vector((sx * sd["x"], 0.0, sd["sleeve"][0])), Vector((sx * sd["x"], 0.0, sd["sleeve"][1])),
                   sd["sleeve_r"], UL_HARP, segs(hi, 12))
    # the socket: a knurled cap, the brass shell, its mouth rolled over the fibre liner
    S = ULSO
    a, b = S["z0"], S["cap_top"]
    cap = [(0.0, a), (0.07, a), (0.077, a + 0.004), (0.081, a + 0.011)]
    knurl = [(S["r_cap"], a + 0.016), (S["r_cap"], b - 0.016)]
    shell = [(0.079, b - 0.01), (0.076, b - 0.004), (0.073, b), (S["r"], b + 0.004),
             (S["r"], S["shell_top"] - 0.032), (0.072, S["shell_top"] - 0.016),
             (0.066, S["shell_top"] - 0.005), (0.059, S["shell_top"]), (S["mouth"] + 0.002, S["shell_top"] + 0.001),
             (S["mouth"], S["shell_top"] - 0.004), (S["mouth"], S["shell_top"] - 0.03), (0.0, S["shell_top"] - 0.03)]
    prof = cap + knurl + shell
    kinds = [UL_SOCKET] * 4 + [UL_KNURL] + [UL_SOCKET] * 9 + [UL_FIBRE] * 3
    if hi:
        s.lathe(cap + knurl[:1], UL_SOCKET, 64)
        rings = []
        for i in range(9):
            z = knurl[0][1] + (knurl[1][1] - knurl[0][1]) * i / 8
            ring = []
            for j in range(240):
                aj = TAU * j / 240
                rr = S["r_cap"] - 0.0016 * (0.5 + 0.5 * math.cos(aj * 60))
                ring.append((rr * math.cos(aj), rr * math.sin(aj), z))
            rings.append(ring)
        s.loft(rings, UL_KNURL)
        s.lathe(knurl[1:] + shell, UL_SOCKET, 64,
                kinds=[UL_SOCKET] * 9 + [UL_FIBRE] * 3)
    else:
        s.lathe(prof, UL_SOCKET, 24, kinds=kinds)
    # the key's stem goes in through a little boss on the shell
    s.cylinder(UL_KEY_AT - UL_KDIR * 0.006, UL_KEY_AT + UL_KDIR * 0.008, 0.012, UL_SOCKET, segs(hi, 12))
    # the harp: plated wire from sleeve to sleeve over the bulb, a domed cap where it joins
    s.tube(ul_harp_path(), UL["harp"]["wire"], UL_HARP, 12 if hi else 6)
    ht = UL["harp"]["top"]
    s.lathe([(0.0, ht - 0.011), (0.014, ht - 0.011), (0.018, ht - 0.006), (0.016, ht + 0.0),
             (0.0, ht + 0.003)], UL_HARP, segs(hi, 16))
    s.cylinder(Vector((0.0, 0.0, ht)), Vector((0.0, 0.0, ht + 0.06)), 0.0052, UL_HARP, segs(hi, 8))
    # the cord: out through a grommet in the foot's rim at the back, a lazy loop round the
    # right, and off the floor into the plug where it lies in front
    C = UL["cord"]
    rs = C["strand"]
    h = 2 * rs
    path = [(0.0, 0.29, 0.0128), (0.0, 0.33, 0.0124), (0.006, 0.40, h), (0.035, 0.48, h),
            (0.13, 0.58, h), (0.32, 0.66, h), (0.56, 0.63, h), (0.78, 0.48, h), (0.93, 0.24, h),
            (0.98, -0.06, h), (0.95, -0.36, h), (0.88, -0.6, h), (0.8, -0.72, h + 0.002)]
    P = UL["plug"]
    M = ul_plug_m()
    back = M @ Vector((0.0, 0.0, -P["l"] / 2 - 0.012))
    near = M @ Vector((0.0, 0.0, -P["l"] / 2 - 0.05))
    path += [((path[-1][0] + near.x) / 2, (path[-1][1] + near.y) / 2, 0.022), tuple(near), tuple(back)]
    pts = spline(path, 10 if hi else 3)
    s.cylinder(Vector((0.0, 0.312, 0.0128)), Vector((0.0, 0.333, 0.0128)), 0.015, UL_PLUG, segs(hi, 12))
    if hi:
        ul_twist(s, pts, rs, C["pitch"])
    else:
        s.tube(pts, h, UL_CORD, 6)
    ul_plug(s, hi, M)
    return s


def ul_resample(pts, step):
    P = [Vector(p) for p in pts]
    out, acc = [P[0]], 0.0
    for a, b in zip(P, P[1:]):
        L = (b - a).length
        t = step - acc
        while t <= L:
            out.append(a + (b - a) * (t / L))
            t += step
        acc = L - (t - step)
    out.append(P[-1])
    return out


def ul_twist(s, pts, rs, pitch):
    """A twisted pair: two cloth-covered strands round each other along the path."""
    P = ul_resample(pts, 0.004)
    T = [(P[min(i + 1, len(P) - 1)] - P[max(i - 1, 0)]).normalized() for i in range(len(P))]
    N = [T[0].cross(Vector((0.0, 0.0, 1.0))).normalized()]
    for i in range(1, len(P)):
        n = N[-1] - T[i] * N[-1].dot(T[i])
        N.append(n.normalized())
    run = 0.0
    strands = ([], [])
    for i, p in enumerate(P):
        if i:
            run += (P[i] - P[i - 1]).length
        ph = TAU * run / pitch
        B = T[i].cross(N[i])
        off = N[i] * math.cos(ph) + B * math.sin(ph)
        strands[0].append(p + off * rs)
        strands[1].append(p - off * rs)
    for st in strands:
        s.tube(st, rs * 0.97, UL_CORD, 8)


def ul_plug_m():
    """The plug's frame: its axis (local Z, out to the prongs) lying level, turned to `yaw`,
    rolled about itself by `roll`, resting on the floor."""
    P = UL["plug"]
    return (Matrix.Translation((P["at"][0], P["at"][1], P["r"]))
            @ Matrix.Rotation(math.radians(P["yaw"]), 4, "Z")
            @ Matrix.Rotation(math.radians(90.0), 4, "Y")
            @ Matrix.Rotation(math.radians(P["roll"]), 4, "Z"))


def ul_plug(s, hi, M):
    """A round brown plug, fluted for the fingers, two flat brass prongs with holes."""
    P = UL["plug"]
    r, l = P["r"], P["l"]
    back = [(0.0, -l / 2 - 0.016), (0.017, -l / 2 - 0.016), (0.02, -l / 2 - 0.012),
            (0.021, -l / 2 - 0.003), (0.046, -l / 2), (0.054, -l / 2 + 0.004), (r, -l / 2 + 0.013)]
    front = [(r, l / 2 - 0.011), (r - 0.004, l / 2 - 0.003), (r - 0.011, l / 2), (0.0, l / 2)]
    if hi:
        s.lathe(back, UL_PLUG, 48, M)
        rings = []
        for i in range(13):
            z = back[-1][1] + (front[0][1] - back[-1][1]) * i / 12
            end = min(i, 12 - i) / 2.0
            ring = []
            for j in range(192):
                a = TAU * j / 192
                u = (P["ribs"] * a / TAU) % 1.0
                flute = max(0.0, math.cos((u - 0.5) * math.pi * 1.6)) if 0.19 < u < 0.81 else 0.0
                rr = r - 0.0032 * flute * min(1.0, end)
                ring.append((rr * math.cos(a), rr * math.sin(a), z))
            rings.append(ring)
        s.loft(rings, UL_PLUG, M)
        s.lathe(front, UL_PLUG, 48, M)
    else:
        s.lathe(back + front, UL_PLUG, 20, M)
    pl, pw, pt = P["prong"]
    for sx in (-1, 1):
        x = sx * P["gap"] / 2
        s.box((x - pt / 2, -pw / 2, l / 2 - 0.006), (x + pt / 2, pw / 2, l / 2 + pl), UL_PRONG,
              0.0011 if hi else 0.0, 1, M)


def ul_prong_holes():
    """Where the holes near the prongs' tips are, in the find's frame."""
    P = UL["plug"]
    M = ul_plug_m()
    return [M @ Vector((sx * P["gap"] / 2, 0.0, P["l"] / 2 + P["prong"][0] - 0.016)) for sx in (-1, 1)]


def ul_curve(t):
    """The shade's wall at t (0 its foot, 1 its top): the point on the wall's middle (r, z) and
    its outward normal and upward tangent, in the profile's plane."""
    S = ULS
    H = S["z1"] - S["z0"]
    r = S["r1"] + (S["r0"] - S["r1"]) * (1 - t) ** S["flare"]
    dr = -(S["r0"] - S["r1"]) * S["flare"] * (1 - t) ** (S["flare"] - 1)
    T = Vector((dr, H)).normalized()
    return Vector((r, S["z0"] + H * t)), Vector((T.y, -T.x)), T


def ul_shade_profile(nt):
    """The shade's game shell: round the foot's rolled rim, up the outside, over the top's
    rim and down the inside."""
    S = ULS
    w2, b = S["wall"] / 2, S["bead"]
    tb = 1.6 * b / 1.0
    C0, n0, T0 = ul_curve(0.0)
    C1, n1, T1 = ul_curve(1.0)
    ts = [tb + (1 - 2 * tb) * i / nt for i in range(nt + 1)]
    na = 4
    bot = [C0 + b * (math.cos(f) * n0 + math.sin(f) * T0)
           for f in [math.pi + math.pi * i / na for i in range(na + 1)]]
    out = [ul_curve(t)[0] + ul_curve(t)[1] * w2 for t in ts]
    top = [C1 + b * (math.cos(f) * n1 + math.sin(f) * T1) for f in [math.pi * i / na for i in range(na + 1)]]
    inn = [ul_curve(t)[0] - ul_curve(t)[1] * w2 for t in reversed(ts)]
    pts = bot + out + top + inn + [bot[0]]
    kinds = ([UL_BEAD] * na + [UL_PARCH] * (len(out) + 1) + [UL_BEAD] * na + [UL_PARCH_IN] * (len(inn) + 1))
    return [(p.x, p.y) for p in pts], kinds[:len(pts) - 1]


def ul_lacing(s, top):
    """Whip-stitching over a rim: the cord goes in through a hole near the edge, over the
    rolled rim and back out through the next hole, all the way round."""
    S = ULS
    C, n_, T = ul_curve(1.0 if top else 0.0)
    into = -T if top else T                  # from the edge into the wall
    w2 = S["wall"] / 2 + S["cord"]
    b = S["bead"] + S["cord"]
    sa = b * math.sin(math.radians(60))
    loop = [(w2, S["hole"]), (w2, sa * 1.1)]
    loop += [(b * math.cos(math.radians(a)), b * math.sin(math.radians(a)))
             for a in [60 - 300 * i / 10 for i in range(11)]]
    loop += [(-w2, sa * 1.1), (-w2, S["hole"])]
    seg = [0.0]
    for p, q in zip(loop + [loop[0]], (loop + [loop[0]])[1:]):
        seg.append(seg[-1] + math.dist(p, q))
    total = seg[-1]
    nst = S["stitches"][0 if not top else 1]
    pts = []
    for k in range(nst):
        for (nv, sv), u in zip(loop, seg):
            th = TAU * (k + u / total) / nst
            c, sn = math.cos(th), math.sin(th)
            rr = C.x + nv * n_.x + sv * into.x
            zz = C.y + nv * n_.y + sv * into.y
            pts.append((rr * c, rr * sn, zz))
    pts.append(pts[0])
    s.tube(pts, S["cord"], UL_LACE, sides=6, caps=False)


def ul_shade(hi):
    """The parchment bell with its laced rims and the seam's overlap at the back, the spider
    and finial that hold it on the harp, and the frosted bulb in the socket."""
    s = Shape()
    S = ULS
    prof, kinds = ul_shade_profile(40 if hi else 10)
    s.lathe(prof, UL_PARCH, 192 if hi else 64, kinds=kinds)
    if hi:
        ul_lacing(s, False)
        ul_lacing(s, True)
        # the seam: where the parchment's end overlaps its start, a cut edge on the outside
        th = math.radians(S["seam"]) + 0.0
        pts = []
        for i in range(41):
            t = 0.03 + 0.94 * i / 40
            c, n_, _ = ul_curve(t)
            p = c + n_ * (S["wall"] / 2 + S["wall"] * 0.5)
            a = th + S["overlap"] / p.x
            pts.append((p.x * math.cos(a), p.x * math.sin(a), p.y))
        s.tube(pts, S["wall"] * 0.5, UL_SEAM, sides=6)
    # the spider: a washer on the harp's top, three spokes out to the top rim's ring
    ht = UL["harp"]["top"]
    s.lathe([(0.0, ht + 0.003), (0.026, ht + 0.003), (0.028, ht + 0.0065), (0.026, ht + 0.01),
             (0.0, ht + 0.01)], UL_HARP, segs(hi, 20))
    for i in range(3):
        a = TAU * i / 3 + math.radians(30)
        s.cylinder(Vector((0.02 * math.cos(a), 0.02 * math.sin(a), ht + 0.0065)),
                   Vector(((S["r1"] - 0.004) * math.cos(a), (S["r1"] - 0.004) * math.sin(a), S["z1"])),
                   0.0034, UL_HARP, segs(hi, 6))
    # the finial: a turned brass urn with a point, screwed down on the harp's stud
    f = UL["finial"]
    fin = [(0.0, f), (0.019, f), (0.023, f + 0.003), (0.025, f + 0.009), (0.023, f + 0.015),
           (0.015, f + 0.021), (0.013, f + 0.029), (0.016, f + 0.039), (0.024, f + 0.055),
           (0.029, f + 0.073), (0.029, f + 0.089), (0.025, f + 0.103), (0.017, f + 0.115),
           (0.009, f + 0.126), (0.005, f + 0.135), (0.003, f + 0.141), (0.0, f + 0.143)]
    s.lathe(fin, UL_BRASS, segs(hi, 24))
    # an A19 bulb, frosted inside
    bb = UL["bulb"]
    bulb = [(0.0, bb["base"]), (0.051, bb["base"]), (0.051, bb["neck"]), (0.05, bb["neck"] + 0.004),
            (0.054, 1.676), (0.062, 1.70), (0.078, 1.74), (0.097, 1.79), (0.112, 1.84),
            (bb["r"], 1.885), (0.118, 1.925), (0.111, 1.962), (0.096, 1.99), (0.072, 2.008),
            (0.04, 2.018), (0.0, 2.021)]
    s.lathe(bulb, UL_BULB, 48 if hi else 20, kinds=[UL_FIBRE, UL_FIBRE] + [UL_BULB] * (len(bulb) - 3))
    return s


def ul_key(hi):
    """The turn key: a stem out of the shell and a flat paddle on it, knurled round its rim,
    found standing upright (its flat faces to the sides)."""
    s = Shape()
    k = ULK
    a = UL_KDIR
    p = Vector((0.0, 0.0, 1.0))
    q = a.cross(p)
    M = Matrix.Translation(UL_KEY_AT) @ Matrix((
        (a.x, p.x, q.x, 0.0), (a.y, p.y, q.y, 0.0), (a.z, p.z, q.z, 0.0), (0.0, 0.0, 0.0, 1.0)))
    s.cylinder(Vector((-0.012, 0.0, 0.0)), Vector((k["out"] + 0.006, 0.0, 0.0)), k["stem_r"], UL_KEY,
               segs(hi, 10), M=M)
    s.cylinder(Vector((0.004, 0.0, 0.0)), Vector((0.009, 0.0, 0.0)), 0.011, UL_KEY, segs(hi, 12), M=M)
    # the paddle, stacked through its thickness (local Z): a pole, a chamfer, the knurled rim,
    # a chamfer, a pole
    cx, hx, hy, t = k["out"] + k["len"] / 2, k["len"] / 2, k["w"] / 2, k["t"]
    m = 96 if hi else 28

    def outline(scale, knurl):
        ring = []
        for j in range(m):
            th = TAU * j / m
            c, sn = math.cos(th), math.sin(th)
            e = 2.0 / 2.6
            x = hx * math.copysign(abs(c) ** e, c)
            y = hy * math.copysign(abs(sn) ** e, sn) * (0.86 + 0.14 * c)
            kn = 1.0 - (0.035 * (0.5 + 0.5 * math.cos(th * 44)) if knurl and c > -0.55 else 0.0)
            ring.append((cx + x * scale * kn, y * scale * kn))
        return ring
    rings = [[(cx, 0.0, -t / 2)]]
    for z, sc, kn in ((-t / 2, 0.9, False), (-t / 2 + 0.0022, 1.0, hi), (t / 2 - 0.0022, 1.0, hi),
                      (t / 2, 0.9, False)):
        rings.append([(x, y, z) for x, y in outline(sc, kn)])
    rings.append([(cx, 0.0, t / 2)])
    s.loft(rings, UL_KEY, M)
    return s


def ul_look(L, f):
    nb = L.nb
    # spun brass under lacquer gone patchy: warm brass, a brown tarnish pooled in the turnings
    # and reeds, darker spots where the lacquer failed, rubbed bright on the rings
    C = Coat(L, hexc("#A8864C"), 0.32, 1.0)
    br = L.k(UL_BRASS, UL_SOCKET, UL_KNURL, UL_KEY, UL_HARP)
    C.paint(br, nb.tint(hexc("#B28F52"), nb.mr(L.noise(24.0, 61, detail=4), 0.3, 0.7, 0.8, 1.12)),
            nb.mr(L.noise(18.0, 62, detail=3), 0.3, 0.7, 0.24, 0.4), 1.0)
    C.paint(nb.mul(br, nb.ss(L.noise(4.0, 63, detail=5, rough=0.62), 0.46, 0.64)), hexc("#5E4A2C"), 0.5, 0.9)
    C.paint(nb.mul(br, nb.ss(L.noise(30.0, 64, detail=3, rough=0.7), 0.67, 0.73)), hexc("#4B3D27"), 0.6, 0.7)
    C.paint(nb.mul(br, nb.mul(L.edge(0.005, k=4.0), nb.ss(L.noise(16.0, 65, detail=3), 0.36, 0.5))),
            hexc("#D6B26A"), 0.2, 1.0)
    # the socket's shell, the key and the harp: thinner stamped brass, browner, duller
    C.paint(L.k(UL_SOCKET, UL_KNURL), nb.tint(hexc("#9C7A44"), nb.mr(L.noise(20.0, 66, detail=4), 0.3, 0.7, 0.78, 1.05)),
            0.4, 1.0)
    C.paint(L.k(UL_HARP), nb.tint(hexc("#B8975A"), nb.mr(L.noise(30.0, 67, detail=3), 0.3, 0.7, 0.85, 1.05)), 0.3, 1.0)
    C.paint(L.k(UL_BRASS_IN), hexc("#3A2E20"), 0.7, 0.4)
    C.paint(L.k(UL_FELT), hexc("#2E3A2A"), 0.97, 0.0)
    C.paint(L.k(UL_FIBRE), hexc("#2A1E15"), 0.8, 0.0)
    # the parchment: aged ivory going to honey, fibrous, foxed with brown spots, browner up
    # where the bulb's heat rose for years; paler inside
    fib = nb.mr(L.noise(36.0, 68, stretch=(1.0, 1.0, 0.3), detail=5, rough=0.6), 0.3, 0.7, 0.86, 1.1)
    mot = nb.mr(L.noise(4.5, 69, detail=4, rough=0.55), 0.3, 0.7, 0.88, 1.08)
    heat = nb.ss(L.z, 1.95, 2.42)
    paper = L.k(UL_PARCH, UL_SEAM, UL_BEAD)
    C.paint(paper, nb.tint(nb.tint(nb.mixc(nb.mul(heat, 0.7), hexc("#CDA96C"), hexc("#A2733A")), fib), mot),
            0.74, 0.0)
    inside = L.k(UL_PARCH_IN)
    C.paint(inside, nb.tint(nb.mixc(nb.mul(heat, 0.6), hexc("#DFC48E"), hexc("#B98D50")), fib), 0.8, 0.0)
    allp = L.k(UL_PARCH, UL_PARCH_IN, UL_SEAM, UL_BEAD)
    fox = nb.mul(allp, nb.ss(L.noise(24.0, 70, detail=4, rough=0.62), 0.68, 0.745))
    C.paint(nb.mul(fox, 0.75), hexc("#93653A"))
    C.paint(L.k(UL_BEAD), nb.tint(hexc("#A57E48"), fib), 0.7, 0.0)
    C.paint(L.k(UL_LACE), nb.tint(hexc("#4A2F1D"), nb.mr(L.noise(80.0, 71, detail=2), 0.3, 0.7, 0.8, 1.15)), 0.6, 0.0)
    # the bulb: frosted glass
    bulb = L.k(UL_BULB)
    C.paint(bulb, hexc("#EEE9DE"), 0.35, 0.0)
    # the cord: gold rayon braided over each strand, the 1940s kind; pale on a dark floor so
    # its line reads from the doorway, running off to nothing
    weave = nb.sin(nb.mul(nb.add(nb.mul(L.x, 1.3), nb.add(nb.mul(L.y, 0.7), L.z)), 900.0))
    C.paint(L.k(UL_CORD), nb.mixc(nb.mr(weave, -1, 1, 0, 1), hexc("#7A5A30"), hexc("#C9A466")), 0.62, 0.0,
            nb.mul(weave, 0.2))
    # the plug: ivory urea, yellowed and grubby where it's handled; brass prongs with holes
    C.paint(L.k(UL_PLUG), nb.tint(hexc("#D8C9A6"), nb.mr(L.noise(14.0, 72, detail=4), 0.3, 0.7, 0.86, 1.06)), 0.3, 0.0)
    C.paint(nb.mul(L.k(UL_PLUG), nb.ss(L.noise(9.0, 73, detail=4), 0.55, 0.7)), hexc("#9C8762"), 0.45)
    C.paint(L.k(UL_PRONG), hexc("#B8975A"), 0.3, 1.0)
    holes = 0.0
    for c in ul_prong_holes():
        d = nb.vop("DISTANCE", L.P, tuple(c))
        h1 = nb.ss(d, 0.0046, 0.0036)
        holes = h1 if isinstance(holes, float) else nb.add(holes, h1, clamp=True)
    holes = nb.mul(L.k(UL_PRONG), holes)
    C.paint(holes, hexc("#14100C"), 0.9, 0.0, nb.mul(holes, -1.0))
    # where it glows: the paper, brightest level with the bulb, dimmer down the flare and up to
    # the top (the light falls off with distance); the fibres and foxing show through, the
    # overlap at the seam darker (two layers), the rims dimmer, the lacing dark; the inside
    # brighter; the bulb full
    d = nb.vop("DISTANCE", L.P, tuple(UL_BULB_C))
    fall = nb.mr(d, 0.46, 0.84, 1.0, 0.45)
    th = nb.math("ARCTAN2", L.y, L.x)
    rad = nb.pw(nb.add(nb.mul(L.x, L.x), nb.mul(L.y, L.y)), 0.5)
    arc = nb.mul(nb.sub(th, math.radians(ULS["seam"])), rad)
    lap = nb.mul(nb.ss(arc, -0.003, 0.002), nb.ss(arc, ULS["overlap"] + 0.004, ULS["overlap"] - 0.002))
    pulp = nb.mr(L.noise(9.0, 74, detail=5, rough=0.62), 0.25, 0.75, 0.62, 1.12)
    shine = nb.mul(nb.mul(fall, nb.mul(pulp, nb.mul(fib, mot))), nb.inv(nb.mul(fox, 0.6)))
    shine = nb.mul(shine, nb.inv(nb.mul(lap, 0.45)))
    outer = nb.mul(L.k(UL_PARCH, UL_SEAM), shine)
    inner = nb.mul(inside, nb.mr(d, 0.4, 0.8, 1.0, 0.7))
    rims = nb.mul(L.k(UL_BEAD), nb.mul(shine, 0.4))
    C.lights(nb.add(nb.add(outer, inner, clamp=True), nb.add(rims, bulb, clamp=True), clamp=True))
    C.finish(f.dust, grime=0.5, keep=nb.add(bulb, inside, clamp=True))
    return C.surface(bump_dist=0.0008, bump=0.45)


# the key: fingers take up the slack, it resists the detent, snaps through a quarter turn with
# a click and settles; a beat with nothing; again, harder; nothing. The light never wavers.
UL_PADDLE = tuple(UL_KEY_AT + UL_KDIR * (ULK["out"] + ULK["len"] / 2) - Vector((0.0, 0.0, 0.01)))
UL_TURN = [(0.0, 0.0), (0.12, 7.0, "Quad", "Out"), (0.24, 15.0, "Sine", "InOut"),
           (0.285, 94.0, "Quad", "In"), (0.33, 88.5, "Quad", "Out"), (0.39, 90.0),
           (0.92, 90.0), (1.02, 98.0, "Quad", "Out"), (1.14, 106.0, "Sine", "InOut"),
           (1.185, 184.0, "Quad", "In"), (1.23, 178.5, "Quad", "Out"), (1.29, 180.0), (1.9, 180.0)]
UNPLUGGED_LAMP = kit.Find(
    "UnpluggedLamp",
    [kit.Part("Base", ul_base),
     kit.Part("Shade", ul_shade, (0.0, 0.0, UL["harp"]["top"]), "Base"),
     kit.Part("Key", ul_key, tuple(UL_KEY_AT), "Base", tuple(UL_KDIR))],
    ul_look,
    lights=[
        # the pool on the floor out of the shade's foot, wide as the bell
        dict(kind="Spot", part="Shade", at=(0.0, 0.0, 1.78), face=(0.0, 0.0, -1.0), kelvin=UL["kelvin"],
             brightness=0.6, range=11, angle=120, shadows=True, preview_watts=30.0, preview_blend=0.3),
        # the glow through the paper all round
        dict(kind="Point", part="Shade", at=tuple(UL_BULB_C), kelvin=UL["kelvin"], brightness=0.35,
             range=10, shadows=False, preview_kind="POINT", preview_watts=5.0, preview_size=0.06),
        # the ring of light on the ceiling out of the open top
        dict(kind="Spot", part="Shade", at=(0.0, 0.0, 2.0), face=(0.0, 0.0, 1.0), kelvin=UL["kelvin"],
             brightness=0.35, range=8, angle=64, shadows=False, preview_watts=14.0, preview_blend=0.3),
    ],
    glow=dict(part="Shade", strength=1.4, tint=(255, 170, 96), preview=1.2),
    motions={
        # it's found on and it stays on: the glow holds at 1 through everything (so its rest,
        # the first key, is lit); the key clicks round twice and nothing answers
        "Switch": dict(duration=1.9, focus=UL_PADDLE, distance=0.1, view=(-1.4, -1.4, -0.3), drop=0.0,
                       tracks=[("Key", "turn", UL_TURN),
                               ("Shade", "glow", [(0.0, 1.0), (1.9, 1.0, "Linear", "In")])]),
    },
    big=True, dust=UL["dust"], seed=UL["seed"],
)

FINDS = [DESK_LAMP, NIGHT_LIGHT, TEA_LIGHT, GLOW_STICKS, FAIRY_LIGHTS, LANTERN, MOON_LAMP, BLOB_LAMP, OIL_LAMP, DISCO_BALL, NEON_SIGN,
         HARD_HAT, FIREFLY_JAR, SPOTLIGHT, STAINED_GLASS_LAMP, UNPLUGGED_LAMP]

if __name__ == "__main__":
    kit.main("Lights", HERE, FINDS)
