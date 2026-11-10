"""The dent: a keeper shut in a unit beats its door out toward the hall (L-06b3d2, D-079).

The moment: the door you slammed on it starts to bow out toward you, a little more with each
blow, so you can see from the hall how close it is to coming through (Amnesia's battered doors).

The curtain is rigid ribs hinged at their valleys, so the dent lives in the ribs themselves: each
step is a set of bowed copies of the slats it reaches, every one built from the same rib profile
as `parts.slat` and wearing the same DoorKit UVs, its points pushed out toward the hall by one
field, `field()`, read at that point's place on the shut door. Neighbouring ribs read the field at
the same valley line, so the bowed ribs meet each other and the plain ones exactly, and the rig
just swaps them into the chain by index (`RollUpDoor`, `DentKit` in Specs). A bowed rib shows
only while it hangs below the doorway's top: rolling up, each pops flat as it passes behind the
header, so the coil never grows lumps that would poke through the header or the unit's top.

Steps, worst last; each bows every point at least as far as the one before (`check_monotonic`),
so a step landing never pulls any part of the door back in:
    1 dented     the first blow: a fist-sized pocket at chest height, ~0.34 out
    2 bowed      the ribs bowed from guide to guide, the pocket deeper, a second fist and a
                 first fold across the ribs, ~0.68 out: level with the corridor wall's face
    3 buckling   ~1 out, well proud of the wall's face (0.55 in front of the curtain), so it
                 breaks the wall's line down the hall; the fold sharp over the pocket and a third
                 blow landed high, as if its head hit. Its peak passes the door's collider (0.6
                 out) by about 0.4; the collider stays as it is (the ticket)

Why so deep: from a player's eye at chest height the bow doesn't bend the ribs' lines in view;
it reads only by light, the ribs above the fold tipped up toward the hall's lights and those
below tipped down into shadow. Roblox's lighting is flatter than the sheets' renders, so the
slopes are steep enough to read there (judged in Studio, not just in Blender).
"""

import math

from geo import Mesh
import parts

# Where the blows land, door-local studs: x across (Blender +X, the hallway viewer's right), y up
# from the floor. The Mannequin stands 6.3 tall; its chest is about 4.6 up. It faces the door
# from inside, so its right fist lands on the hall's left (-X).
CENTRE_Y = 4.6

# step: reach (half-height of the rows it bends), bow (how far the ribs bow out from guide to
# guide at the middle), pockets (x, y, out, half-width, half-height: a fist or shoulder landing),
# crease (out, y, half-height: a fold across the ribs, sharp at y).
STEPS = [
    dict(name="dented", reach=1.5, bow=0.05,
         pockets=[(-0.5, 4.7, 0.3, 0.75, 0.45)], crease=None),
    dict(name="bowed", reach=2.3, bow=0.38,
         pockets=[(-0.5, 4.7, 0.26, 0.95, 0.6), (1.1, 4.05, 0.1, 0.8, 0.5)],
         crease=(0.08, 4.98, 0.5)),
    dict(name="buckling", reach=2.5, bow=0.58,
         pockets=[(-0.5, 4.7, 0.3, 1.0, 0.65), (1.1, 4.05, 0.15, 0.85, 0.5),
                  (-1.5, 5.65, 0.12, 0.7, 0.4)],
         crease=(0.16, 4.98, 0.55)),
]

# Across the door, where a bowed rib's points sit: closer over the pockets, so they read round.
ACROSS = [-3.3, -2.5, -1.8, -1.2, -0.75, -0.3, 0.15, 0.65, 1.25, 2.1, 3.1]
# The rib's back, seen only from inside the unit, follows its profile at fewer points (indices
# into `parts.rib_profile`), so a bowed rib costs about 450 triangles, not 720.
BACK = [0, 2, 4, 5, 7, 9]
# A rib the dent moves less than this (studs) stays plain: the step where it meets a bowed one
# is under the steel's thickness.
LEAST = 0.01


def field(s, step, x, y):
    """How far the door's point at (x, y) is pushed out toward the hall at `step` (1-based)."""
    st = STEPS[step - 1]
    hold = s.door_width / 2  # the guides hold each rib's ends: nothing bows past the opening
    if abs(x) >= hold:
        return 0.0
    dy = y - CENTRE_Y
    if abs(dy) >= st["reach"]:
        return 0.0
    across = math.cos(0.5 * math.pi * x / hold)
    upright = math.cos(0.5 * math.pi * dy / st["reach"]) ** 2
    d = st["bow"]
    for px, py, out, sx, sy in st["pockets"]:
        d += out * math.exp(-((x - px) / sx) ** 2 - ((y - py) / sy) ** 2)
    if st["crease"]:
        out, cy, w = st["crease"]
        d += out * max(0.0, 1.0 - abs(y - cy) / w)
    return d * across * upright


def band(s, step):
    """Chain indices (0-based, bottom first) of the ribs `step` bends, in one unbroken run."""
    out = []
    for i in range(s.slat_count):
        y0 = s.bottom_closed + i * s.pitch
        most = max(field(s, step, xi * 0.1, y0 + yi * s.pitch / 6)
                   for xi in range(-40, 41) for yi in range(7))
        if most >= LEAST:
            out.append(i)
    assert out == list(range(out[0], out[-1] + 1)), f"dent step {step}: its ribs aren't one run"
    return out


def stations(s):
    """X stations across one rib: its ends in the guides, the opening's edges, then ACROSS."""
    hold, cw2 = s.door_width / 2, s.curtain_width / 2
    xs = {-cw2, cw2, -hold, hold}
    xs.update(x for x in ACROSS if abs(x) < hold - 0.25)
    return sorted(xs)


def bowed_slat(s, step, index):
    """Chain rib `index` (0-based) at `step`, in the same local frame as `parts.slat`: x across,
    -Y out toward the hall, +Z up the curtain, the hinge chord centred on the origin."""
    variant = s.slat_variant(index, 7)
    m = Mesh(f"Dent{step}_{index + 1}")  # the game counts the chain from 1
    prof = parts.rib_profile(s)
    cw2, th = s.curtain_width / 2, s.sheet
    fv0, fv1 = parts.SLAT_BANDS[(variant, "front")]
    bv0, bv1 = parts.SLAT_BANDS[(variant, "back")]
    lens = [0.0]
    for (ta, na), (tb, nb) in zip(prof, prof[1:]):
        lens.append(lens[-1] + math.hypot(tb - ta, nb - na))
    L = lens[-1]
    inset = 0.004
    u0, u1 = s.u_across()
    mid = s.bottom_closed + (index + 0.5) * s.pitch  # the rib hangs straight here when shut
    xs = stations(s)

    def band_v(v0, v1, f):
        return v0 + inset + (v1 - v0 - 2 * inset) * f

    def u_at(x):
        return u0 + (u1 - u0) * (x + cw2) / (2 * cw2)

    def out_at(x, t):
        return field(s, step, x, mid + t)

    def row(t, n, back):
        """Points across the rib at profile place (t, n), bowed out; shared by the quads either
        side, so the bow shades smoothly across the door (along the profile the rib stays
        faceted, as the plain ribs are)."""
        lift = th if back else 0.0
        return [m.vert((x, -n + lift - out_at(x, t), t)) for x in xs]

    def strip(a, b, va, vb, back):
        for c in range(len(xs) - 1):
            ua, ub = u_at(xs[c]), u_at(xs[c + 1])
            if back:  # faces +Y
                m.face([a[c], b[c], b[c + 1], a[c + 1]], [(ua, va), (ua, vb), (ub, vb), (ub, va)], True)
            else:  # faces -Y, the hall
                m.face([a[c], a[c + 1], b[c + 1], b[c]], [(ua, va), (ub, va), (ub, vb), (ua, vb)], True)

    for k in range(len(prof) - 1):
        (ta, na), (tb, nb) = prof[k], prof[k + 1]
        strip(row(ta, na, False), row(tb, nb, False),
              band_v(fv0, fv1, lens[k] / L), band_v(fv0, fv1, lens[k + 1] / L), False)
    # the back, the sheet's thickness behind, at the BACK points
    for ka, kb in zip(BACK, BACK[1:]):
        (ta, na), (tb, nb) = prof[ka], prof[kb]
        strip(row(ta, na, True), row(tb, nb, True),
              band_v(bv0, bv1, lens[ka] / L), band_v(bv0, bv1, lens[kb] / L), True)
    # hinge edges at the valleys
    for (t, n), sgn in ((prof[0], -1), (prof[-1], 1)):
        vv = band_v(bv0, bv1, 0.0 if sgn < 0 else 1.0)
        f, bk = row(t, n, False), row(t, n, True)
        for c in range(len(xs) - 1):
            ua, ub = u_at(xs[c]), u_at(xs[c + 1])
            if sgn < 0:
                m.face([f[c], bk[c], bk[c + 1], f[c + 1]], [(ua, vv), (ua, vv), (ub, vv), (ub, vv)], False)
            else:
                m.face([f[c + 1], bk[c + 1], bk[c], f[c]], [(ub, vv), (ub, vv), (ua, vv), (ua, vv)], False)
    return m


def check(s):
    """The rules the game leans on, checked on every build."""
    frames, _ = s.curtain.slats(0.0)
    hanging = s.guide_top - s.bottom_closed
    for step in range(1, len(STEPS) + 1):
        for i in band(s, step):
            assert abs(frames[i][2]) < 1e-6, f"dent step {step}: rib {i} isn't hanging straight"
            assert (i + 1) * s.pitch <= hanging, f"dent step {step}: rib {i} reaches the coil"
    # never back: each step bows every point at least as far as the one before
    for step in range(2, len(STEPS) + 1):
        for xi in range(-40, 41):
            for yi in range(0, 81):
                x, y = xi * 0.1, yi * 0.1
                assert field(s, step, x, y) >= field(s, step - 1, x, y) - 1e-9, \
                    f"dent step {step} pulls ({x:.1f}, {y:.1f}) back in"
    lo = min(band(s, len(STEPS)))
    assert s.bottom_closed + lo * s.pitch > 1.0, "the dent reaches the bottom bar"


def peak(s, step):
    best = 0.0
    for xi in range(-40, 41):
        for yi in range(0, 81):
            best = max(best, field(s, step, xi * 0.1, yi * 0.1))
    return best
