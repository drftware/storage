"""The Big finds set (art/finds/big/README.md), built with the finds kit.

    scripts/art.sh set big [textures|export|renders|quick] [FindName]
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
from shapes import Shape  # noqa: E402

# What a face is, for the looks.
(WOOD, PLINTH, CHROME, CLOTH, PLASTIC, GLASS, VINYL, LABEL, IVORY, INSIDE, RUBBER, PANEL) = range(12)


def segs(hi, lo_n):
    return lo_n * 2 if hi else lo_n


# --- solids the kit's shapes don't draw: a flat outline pushed out, and a band along a path -----

def prism(pts, vec, kind, s, bevel=0.0, steps=1):
    """The flat outline pts (3D, convex) pushed along vec into a solid, its sharp edges rounded by
    `bevel`, into shape s (box-projected, as the kit's boxes are)."""
    bm = bmesh.new()
    face = bm.faces.new([bm.verts.new(p) for p in pts])
    out = bmesh.ops.extrude_face_region(bm, geom=[face])
    moved = [g for g in out["geom"] if isinstance(g, bmesh.types.BMVert)]
    bmesh.ops.translate(bm, vec=Vector(vec), verts=moved)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    if bevel > 0:
        sharp = [e for e in bm.edges if len(e.link_faces) == 2 and e.calc_face_angle(0.0) > 0.6]
        bmesh.ops.bevel(bm, geom=sharp, offset=bevel, segments=steps, profile=0.5,
                        affect="EDGES", clamp_overlap=True)
    s.merge(bm, kind)
    bm.free()


def band(outer, inner, y0, y1, kind, s):
    """A solid band between two paths in XZ (the same count), from y0 to y1."""
    bm = bmesh.new()

    def ring(path, y):
        return [bm.verts.new((x, y, z)) for x, z in path]

    of, inf, ob, ib = ring(outer, y0), ring(inner, y0), ring(outer, y1), ring(inner, y1)
    for i in range(len(outer) - 1):
        j = i + 1
        bm.faces.new((of[i], of[j], inf[j], inf[i]))
        bm.faces.new((ob[i], ib[i], ib[j], ob[j]))
        bm.faces.new((of[i], ob[i], ob[j], of[j]))
        bm.faces.new((inf[i], inf[j], ib[j], ib[i]))
    for i in (0, len(outer) - 1):
        bm.faces.new((of[i], inf[i], ib[i], ob[i]))
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    s.merge(bm, kind)
    bm.free()


def arc_pts(r, zc, n, z0=None):
    """Round the arch at radius r over zc, right to left; with z0, down both sides to it too."""
    pts = [(r * math.cos(math.pi * i / n), zc + r * math.sin(math.pi * i / n)) for i in range(n + 1)]
    return [(r, z0)] + pts + [(-r, z0)] if z0 is not None else pts


# --- the jukebox -------------------------------------------------------------------------------

J = K.JUKEBOX
W, D, H, FRONT = J["w"], J["d"], J["h"], J["front"]
R = W / 2                 # the arch's radius: the cabinet's whole width
ZC = H - R                # the arch's middle, where its sides turn into the curve
BACK = FRONT + 2.0        # the cabinet runs 20 in back; the bay and the arch stand proud of it
JB, JBAY, JP, JK, JG, JF = J["band"], J["bay"], J["platter"], J["keys"], J["grille"], J["fan"]
BAY_Y0 = FRONT - JBAY["out"]            # the bay's foot, furthest out
BAY_Y1 = BAY_Y0 + JBAY["lean"]          # its top edge, leaning back
REC_Z = JP["z"]


def jb_cabinet(hi):
    s = Shape()
    n = segs(hi, 24)
    bev, st = (0.035, 3) if hi else (0.035, 1)
    zb = J["plinth"]["h"]
    # the wooden body: an arch-topped slab, its face set back behind the plastics
    outline = [(-R, FRONT, zb), (R, FRONT, zb)] + [(x, FRONT, z) for x, z in arc_pts(R, ZC, n)]
    prism(outline, (0.0, BACK - FRONT, 0.0), WOOD, s, bev, st)
    # the dark kick base it stands on
    i = J["plinth"]["inset"]
    s.box((-R + i, FRONT + i, 0.0), (R - i, BACK - i, zb + 0.02), PLINTH, 0.02, 2 if hi else 1)
    # chrome trim along both edges of the plastic horseshoe, and a cast foot under each end
    yb = FRONT - JB["proud"]
    for r in (JB["c"] + JB["w"] / 2, JB["c"] - JB["w"] / 2):
        path = [(x, yb, z) for x, z in arc_pts(r, ZC, n, JB["z0"])]
        s.tube(path, JB["chrome"], CHROME, segs(hi, 8))
    for sx in (-1, 1):
        x0, x1 = sorted((sx * (JB["c"] - JB["w"] / 2 - 0.02), sx * (JB["c"] + JB["w"] / 2 + 0.02)))
        s.box((x0, yb - 0.03, zb), (x1, FRONT + 0.01, JB["z0"]), CHROME, 0.02, 2 if hi else 1)
    # the bay over the record: wooden cheeks, a lid, a dark floor and back, chrome round the glass
    bx, z0, z1 = JBAY["x"], JBAY["z0"], JBAY["z1"]
    for sx in (-1, 1):
        xo = sx * bx
        cheek = [(xo, FRONT, z0 - 0.06), (xo, BAY_Y0, z0 - 0.06), (xo, BAY_Y1, z1 + 0.06),
                 (xo, FRONT, z1 + 0.06)]
        prism(cheek, (-sx * 0.07, 0.0, 0.0), WOOD, s, 0.012 if hi else 0.0, 2 if hi else 1)
    s.box((-bx, BAY_Y1 - 0.02, z1), (bx, FRONT + 0.01, z1 + 0.07), WOOD, 0.015, 2 if hi else 1)
    s.box((-bx, BAY_Y0 - 0.02, z0 - 0.07), (bx, FRONT + 0.01, z0), INSIDE, 0.015, 2 if hi else 1)
    # a pale gold panel behind the record, so through the glass it reads as a record, not a screen
    s.box((-bx, FRONT - 0.02, z0), (bx, FRONT + 0.005, z1), PANEL)
    fr = JBAY["frame"]
    rim = [(-bx, BAY_Y0, z0), (bx, BAY_Y0, z0), (bx, BAY_Y1, z1), (-bx, BAY_Y1, z1), (-bx, BAY_Y0, z0)]
    s.tube(rim, fr, CHROME, segs(hi, 8))
    # the turntable: its rubber mat, the spindle, the tone arm on its post
    s.cylinder((0.0, JP["y"], z0), (0.0, JP["y"], REC_Z - 0.012), JP["r"] + 0.02, RUBBER, segs(hi, 32))
    s.cylinder((0.0, JP["y"], REC_Z), (0.0, JP["y"], REC_Z + 0.05), 0.012, CHROME, segs(hi, 8))
    post = (0.68, FRONT - 0.18)
    s.cylinder((post[0], post[1], z0), (post[0], post[1], REC_Z + 0.08), 0.045, CHROME, segs(hi, 12))
    s.tube([(post[0], post[1], REC_Z + 0.07), (0.45, JP["y"] - 0.05, REC_Z + 0.07),
            (0.22, JP["y"] - 0.12, REC_Z + 0.035)], 0.016, CHROME, segs(hi, 8))
    s.box((0.17, JP["y"] - 0.16, REC_Z + 0.01), (0.26, JP["y"] - 0.08, REC_Z + 0.05), CHROME, 0.008)
    # the changer's records standing in their rack behind the turntable
    st_ = J["stack"]
    for k in range(st_["n"]):
        x = (k - (st_["n"] - 1) / 2) * st_["gap"]
        s.cylinder((x - st_["t"] / 2, st_["y"], st_["z"]), (x + st_["t"] / 2, st_["y"], st_["z"]),
                   st_["r"], VINYL, segs(hi, 24))
    s.box((-0.4, st_["y"] - 0.12, z0), (0.4, FRONT + 0.01, st_["z"] - st_["r"] + 0.06), INSIDE,
          0.01)
    # the selector: a chrome strip of ivory keys under the window, the coin slot's plate at its end
    kx, kz0, kz1 = JK["x"], JK["z0"], JK["z1"]
    s.box((-kx, FRONT - 0.3, kz0), (kx, FRONT + 0.01, kz1), CHROME, 0.025, 3 if hi else 1)
    kn = JK["n"]
    kw = 1.6 / kn
    for k in range(kn):
        x = -0.98 + (k + 0.5) * kw
        s.box((x - kw * 0.36, FRONT - 0.34, kz0 + 0.05), (x + kw * 0.36, FRONT - 0.28, kz1 - 0.05),
              IVORY, 0.012, 2 if hi else 1)
    s.box((0.72, FRONT - 0.33, kz0 + 0.04), (1.04, FRONT - 0.29, kz1 - 0.04), CHROME, 0.01)
    s.box((0.86, FRONT - 0.345, kz0 + 0.07), (0.9, FRONT - 0.32, kz1 - 0.07), INSIDE)
    # the speaker: dark cloth behind chrome bars and a chrome frame
    gx, g0, g1 = JG["x"], JG["z0"], JG["z1"]
    s.box((-gx, FRONT - 0.03, g0), (gx, FRONT + 0.01, g1), CLOTH)
    yb2 = FRONT - 0.06
    s.tube([(-gx, yb2, g0), (gx, yb2, g0), (gx, yb2, g1), (-gx, yb2, g1), (-gx, yb2, g0)], 0.04,
           CHROME, segs(hi, 8))
    for k in range(JG["bars"]):
        z = g0 + (k + 1) * (g1 - g0) / (JG["bars"] + 1)
        s.cylinder((-gx, yb2 + 0.01, z), (gx, yb2 + 0.01, z), JG["bar_r"], CHROME, segs(hi, 8))
    s.cylinder((0.0, yb2 - 0.01, g0), (0.0, yb2 - 0.01, g1), JG["bar_r"] * 1.4, CHROME, segs(hi, 8))
    # inside the arch: dark cloth, a fan of chrome rods from a chrome hub
    cr = JF["cloth_r"]
    cloth = [(-cr, FRONT - 0.03, z1 + 0.1), (cr, FRONT - 0.03, z1 + 0.1)] \
        + [(x, FRONT - 0.03, z) for x, z in arc_pts(cr, ZC, n)]
    prism(cloth, (0.0, 0.04, 0.0), CLOTH, s)
    for k in range(JF["rods"]):
        a = math.pi * (k + 1) / (JF["rods"] + 1)
        p0 = (JF["r0"] * math.cos(a), FRONT - 0.07, ZC + JF["r0"] * math.sin(a))
        p1 = (JF["r1"] * math.cos(a), FRONT - 0.05, ZC + JF["r1"] * math.sin(a))
        s.cylinder(p0, p1, JF["rod_r"], CHROME, segs(hi, 8))
    s.cylinder((0.0, FRONT - 0.12, ZC), (0.0, FRONT, ZC), JF["r0"], CHROME, segs(hi, 32))
    s.lathe([(0.0, 0.0), (0.2, 0.0), (0.12, 0.05), (0.0, 0.06)], CHROME, segs(hi, 24),
            M=Matrix.Translation((0.0, FRONT - 0.12, ZC)) @ Matrix.Rotation(math.radians(90), 4, "X"))
    return s


def jb_glow(hi):
    """The horseshoe of coloured plastic, up both sides and round the arch: it glows when played."""
    s = Shape()
    n = segs(hi, 24)
    ro, ri = JB["c"] + JB["w"] / 2, JB["c"] - JB["w"] / 2
    band(arc_pts(ro, ZC, n, JB["z0"]), arc_pts(ri, ZC, n, JB["z0"]), FRONT - JB["proud"],
         FRONT + 0.01, PLASTIC, s)
    return s


def jb_window(hi):
    """The bay's glass, leaning back over the record."""
    s = Shape()
    bx, z0, z1 = JBAY["x"] - 0.02, JBAY["z0"], JBAY["z1"]
    a, b = Vector((-bx, BAY_Y0, z0)), Vector((bx, BAY_Y0, z0))
    c, d = Vector((bx, BAY_Y1, z1)), Vector((-bx, BAY_Y1, z1))
    inward = (b - a).cross(d - a).normalized() * 0.014
    prism([a, b, c, d], tuple(inward), GLASS, s)
    return s


def jb_record(hi):
    """The single on the turntable, a red label in its middle; it spins when played."""
    s = Shape()
    r = JP["r"]
    prof = [(0.0, 0.0), (r - 0.01, 0.0), (r, 0.004), (r, 0.01), (r - 0.012, 0.014), (0.13, 0.014),
            (0.125, 0.016), (0.0, 0.016)]
    kinds = [VINYL, VINYL, VINYL, VINYL, VINYL, LABEL, LABEL]
    s.lathe(prof, VINYL, segs(hi, 40), M=Matrix.Translation((0.0, JP["y"], REC_Z)), kinds=kinds)
    return s


def jb_look(L, f):
    nb = L.nb
    # walnut veneer, lacquered: the grain runs up the cabinet; a touch redder than life so it
    # holds its colour under the unit's red bulb (CRAFT.md, "Value")
    grain = L.noise(5.0, 3, stretch=(1.0, 1.0, 0.08), detail=5)
    wood = nb.tint(hexc("#7A4527"), nb.mr(grain, 0.3, 0.7, 0.72, 1.18))
    C = Coat(L, wood, nb.mr(L.noise(8.0, 2, detail=3), 0.2, 0.8, 0.3, 0.48), 0.0,
             nb.mul(nb.sin(nb.mul(grain, 40.0)), 0.06))
    C.paint(nb.mul(L.up, nb.mr(L.noise(1.6, 4, detail=3), 0.3, 0.7, 0.1, 0.35)), hexc("#93603D"))
    C.paint(L.k(PLINTH), hexc("#1E1B19"), 0.55, 0.0)
    C.enamel_wear(L.k(WOOD, PLINTH), hexc("#A07E58"), s=5, amount=1.3)
    # chrome: bright, scratched along its length, freckled with rust where it was handled
    chrome = nb.tint(hexc("#D3D6D8"), nb.mr(L.noise(30.0, 10, detail=4), 0.3, 0.7, 0.8, 1.0))
    C.paint(L.k(CHROME), chrome, nb.mr(L.noise(40.0, 11, detail=3), 0.3, 0.7, 0.08, 0.24), 1.0)
    rust = nb.mul(L.k(CHROME), nb.ss(L.noise(40.0, 8, detail=4, rough=0.7), 0.66, 0.74))
    C.paint(rust, hexc("#6B3B22"), 0.85, 0.15, 0.04)
    # the speaker cloth: a dark gold weave
    weave = nb.mul(nb.sin(nb.mul(L.x, 260.0)), nb.sin(nb.mul(L.z, 260.0)))
    C.paint(L.k(CLOTH), nb.tint(hexc("#3A2E22"), nb.mr(weave, -1, 1, 0.8, 1.15)), 0.9, 0.0,
            nb.mul(weave, 0.2))
    # the plastics: three bands round the horseshoe, amber inside, orange, deep red outside,
    # a groove between each, and fine flutes across them the way moulded jukebox plastics were
    ax = nb.pw(nb.mul(L.x, L.x), 0.5)
    dz = nb.sub(L.z, ZC)
    rad = nb.pw(nb.add(nb.mul(L.x, L.x), nb.mul(dz, dz)), 0.5)
    rr = nb.add(ax, nb.mul(nb.ss(L.z, ZC - 0.01, ZC + 0.01), nb.sub(rad, ax)))
    t = nb.mr(rr, JB["c"] - JB["w"] / 2, JB["c"] + JB["w"] / 2, 0.0, 1.0)
    plastic = L.k(PLASTIC)
    C.paint(plastic, hexc("#F0B248"), 0.22, 0.0)
    C.paint(nb.mul(plastic, nb.ss(t, 0.31, 0.35)), hexc("#E2632A"), 0.22, 0.0)
    C.paint(nb.mul(plastic, nb.ss(t, 0.65, 0.69)), hexc("#B42A1C"), 0.22, 0.0)
    for g in (0.33, 0.67):
        d = nb.pw(nb.mul(nb.sub(t, g), nb.sub(t, g)), 0.5)
        C.paint(nb.mul(plastic, nb.mr(d, 0.0, 0.025, 1.0, 0.0)), hexc("#5A1A10"), 0.4, 0.0, -0.5)
    C.lights(nb.mul(plastic, nb.mr(t, 0.0, 1.0, 1.0, 0.75)))
    # the record: black vinyl, its grooves catching the light in rings; a red paper label
    rp = nb.pw(nb.add(nb.mul(L.x, L.x), nb.mul(nb.sub(L.y, JP["y"]), nb.sub(L.y, JP["y"]))), 0.5)
    C.paint(L.k(VINYL), hexc("#141414"), nb.mr(nb.sin(nb.mul(rp, 700.0)), -1, 1, 0.22, 0.4), 0.0,
            nb.mul(nb.sin(nb.mul(rp, 700.0)), 0.1))
    C.paint(L.k(LABEL), hexc("#B8332A"), 0.7, 0.0)
    C.paint(L.k(IVORY), hexc("#E6DCC4"), 0.32, 0.0)
    C.paint(L.k(INSIDE), hexc("#1A1714"), 0.8, 0.0)
    C.paint(L.k(PANEL), nb.tint(hexc("#C8A964"), nb.mr(L.noise(12.0, 12, detail=3), 0.3, 0.7, 0.85, 1.05)),
            0.3, 0.6)
    C.paint(L.k(RUBBER), hexc("#222120"), 0.75, 0.0)
    C.finish(f.dust, grime=0.5)
    # glass: dark and glossy, so the light behind it doesn't turn it to plastic (CRAFT.md), and
    # painted after the dust: leaning back, it frosted over and read as a blank screen
    C.paint(L.k(GLASS), hexc("#7E948A"), 0.05, 0.0, alpha=0.18)
    return C.surface(bump_dist=0.003, bump=0.45)


GLOW_RGB = J["glow_rgb"]
PLAY_FOCUS = (0.0, BAY_Y0, 3.4)
SPIN = 1.6 * 270.0  # a 45 turns 270 degrees a second: the last 1.6 s of the play at full speed

JUKEBOX = kit.Find(
    "Jukebox",
    [kit.Part("Cabinet", jb_cabinet),
     kit.Part("Glow", jb_glow, (0.0, FRONT, ZC), "Cabinet"),
     kit.Part("Window", jb_window, (0.0, (BAY_Y0 + BAY_Y1) / 2, (JBAY["z0"] + JBAY["z1"]) / 2),
              "Cabinet", clear=True),
     kit.Part("Record", jb_record, (0.0, JP["y"], REC_Z), "Cabinet", (0, 0, 1))],
    jb_look,
    lights=[
        # the plastics' glow on the floor and the walls round it: warm, no brighter than a unit's
        # bulb (CRAFT.md, "Judged in Roblox")
        dict(kind="Point", part="Glow", at=(0.0, FRONT - 0.6, 3.4), rgb=GLOW_RGB, brightness=0.6,
             range=10, shadows=False, preview_kind="POINT", preview_watts=6.0, preview_size=0.3),
    ],
    glow=dict(part="Glow", strength=1.6, tint=(255, 190, 120), preview=4.0),
    motions={
        # played: the tubes warm up with a stutter as old valves do, then the record comes up to
        # speed, heavy at first (clockwise from above)
        "Play": dict(duration=3.0, focus=PLAY_FOCUS, distance=0.6, tracks=[
            ("Glow", "glow", [(0.0, 0.0), (0.15, 0.0, "Linear"), (0.22, 0.45, "Quad", "Out"),
                              (0.32, 0.12), (0.45, 0.6, "Quad", "Out"), (1.3, 1.0, "Quad", "Out"),
                              (3.0, 1.0)]),
            ("Record", "turn", [(0.0, 0.0), (0.5, 0.0, "Linear"), (1.4, -150.0, "Quad", "In"),
                                (3.0, -150.0 - SPIN, "Linear")])]),
    },
    big=True, dust=J["dust"], seed=J["seed"],
)

FINDS = [JUKEBOX]

if __name__ == "__main__":
    kit.main("Big", HERE, FINDS)
