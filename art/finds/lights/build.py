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

FINDS = [DESK_LAMP, NIGHT_LIGHT, TEA_LIGHT]

if __name__ == "__main__":
    kit.main("Lights", HERE, FINDS)
