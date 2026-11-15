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
        dict(kind="Point", part="Diffuser", at=LN_GLOW_AT, kelvin=LN["kelvin"], brightness=1.2,
             range=16, shadows=False, preview_kind="POINT", preview_watts=9.0, preview_size=0.05),
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
    C.paint(ch, hexc("#5C6668"), 0.03, 0.0, alpha=0.08)
    C.paint(chi, hexc("#5C6668"), 0.03, 0.0, alpha=0.06)
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
        dict(kind="Point", part="Flame", at=OL_FLAME_MID, kelvin=OF["kelvin"], brightness=1.4,
             range=16, shadows=False, preview_kind="POINT", preview_watts=9.0, preview_size=0.02),
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

FINDS = [DESK_LAMP, NIGHT_LIGHT, TEA_LIGHT, GLOW_STICKS, FAIRY_LIGHTS, LANTERN, MOON_LAMP, BLOB_LAMP, OIL_LAMP]

if __name__ == "__main__":
    kit.main("Lights", HERE, FINDS)
