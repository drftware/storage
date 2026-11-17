"""The name card's four styles (S5-03g1b, D-322): a plate over each home's door, every style its
own parts on one origin, the card's middle on the wall's face (the lobby's R-panel), its front
toward -y. What the hall sees first: your friends' names glowing, chalked and stencilled over
their doors, and yours the one you chose (idea 20). Numbers in home_spec.py (CARD_*).

    CardSteel, CardSteelBolts       Stencil: a powder-coated steel sign blank, its edges folded
                                    back, a bead pressed round its face, on four bolted standoffs
                                    (Plaster: its stipple reads as powder coat, like the job box;
                                    plain graphite bolts). Every home's to start.
    CardBoard, CardBoardScrews      Painted: a sign-writer's board, brushed paint over the grain
                                    and a cream pinstripe (SignBoard, tinted), two brass screws
    CardSlate, CardChalkFrame,      Chalk: a slate (Chalkboard, baked) in a moulded oak frame
    CardChalkStick                  (Wood) with a chalk ledge under it, a stick of chalk on it
    CardNeonBack, CardNeonTube      Neon: a dark backing on polished standoffs, a glass tube round
                                    its edge on little posts (plain: the game makes the tube Neon
                                    in the glow colour and lights the wall round it)
"""

import math

from carpentry import plaster_uv, wood_box, wood_uv
import geo
from geo import Mesh
import home_spec as K
from furnish import ring

PLAIN = geo.map_floor(1.0)  # plain parts: the game sets their Material and Color


def card_uv(w, h, x0=0.0, z0=0.0, edge=(0.3, 0.7, 0.008, 0.018)):
    """A plate's front (facing -y) over its whole bake, (x, z) from its bottom-left corner at
    (x0, z0); every other face onto a strip of plain ground near the bake's bottom edge."""
    u0, u1, v0, v1 = edge
    def f(vs, n):
        if n[1] < -0.9:
            return [((v[0] - x0) / w, (v[2] - z0) / h) for v in vs]
        ax = 2 if abs(n[2]) < 0.9 else 0
        lo = min(v[ax] for v in vs)
        span = max(max(v[ax] for v in vs) - lo, 1e-6)
        return [(u0 + (u1 - u0) * (v[ax] - lo) / span, (v0 + v1) / 2) for v in vs]
    return f


def rounded(a, b, r, segs=6):
    """A rounded rectangle's outline (half sizes a, b, corner radius r), anticlockwise in x, z."""
    out = []
    for cx, cz, start in ((a - r, -b + r, -90), (a - r, b - r, 0), (-a + r, b - r, 90), (-a + r, -b + r, 180)):
        for k in range(segs + 1):
            t = math.radians(start + 90 * k / segs)
            out.append((cx + r * math.cos(t), cz + r * math.sin(t)))
    return out


def slab(m, outline, y0, y1, mapper=None):
    """`outline` [(x, z)] extruded from y0 (front) to y1 (back): faces, back and sides."""
    n = len(outline)
    front = [m.vert((x, y0, z)) for x, z in outline]
    back = [m.vert((x, y1, z)) for x, z in outline]
    def put(idx, normal):
        m.face(idx, mapper([m.verts[i] for i in idx], normal) if mapper else None, False)
    put(front, (0, -1, 0))           # anticlockwise in (x, z) looks toward -y
    put(list(reversed(back)), (0, 1, 0))
    for i in range(n):
        j = (i + 1) % n
        x0, z0 = outline[i]
        x1, z1 = outline[j]
        put([front[i], back[i], back[j], front[j]], (z1 - z0, 0, -(x1 - x0)))


def card_steel():
    """Stencil's plate: a sign blank of powder-coated steel, its four edges folded back toward the
    wall, a bead pressed round the face where the stencil's border would sit."""
    m = Mesh("CardSteel")
    w, h, t, off = K.CARD_STEEL
    f, bead = K.CARD_FOLD, K.CARD_BEAD
    pu = plaster_uv(2.0)
    y0, y1 = -off - t, -off
    geo.box(m, (-w / 2, y0, -h / 2), (w / 2, y1, h / 2), pu, bevel=0.02)
    r = 0.6 * t
    for sz in (-1, 1):                      # the folds, top and bottom, then the ends
        a, b = sorted((sz * h / 2, sz * (h / 2 - r)))
        geo.box(m, (-w / 2, y1, a), (w / 2, y1 + f, b), pu, bevel=0.008)
    for sx in (-1, 1):
        a, b = sorted((sx * w / 2, sx * (w / 2 - r)))
        geo.box(m, (a, y1, -h / 2 + r), (b, y1 + f, h / 2 - r), pu, bevel=0.008)
    bw, proud = 0.05, 0.016                 # the pressed bead
    x, z = w / 2 - bead, h / 2 - bead
    geo.box(m, (-x, y0 - proud, z - bw), (x, y0, z), pu, bevel=0.01)
    geo.box(m, (-x, y0 - proud, -z), (x, y0, -z + bw), pu, bevel=0.01)
    for sx in (-1, 1):
        a, b = sorted((sx * x, sx * (x - bw)))
        geo.box(m, (a, y0 - proud, -z + bw), (b, y0, z - bw), pu, bevel=0.01)
    return m


def steel_bolts():
    """Four dome-headed bolts through the blank's corners, each on a standoff back to the wall."""
    m = Mesh("CardSteelBolts")
    w, h, t, off = K.CARD_STEEL
    for sx in (-1, 1):
        for sz in (-1, 1):
            x, z = sx * (w / 2 - 0.065), sz * (h / 2 - 0.065)
            geo.cylinder(m, "y", (x, -off - t - 0.012, z), 0.04, 0.024, segs=10, mapper=PLAIN)
            geo.cylinder(m, "y", (x, -off / 2, z), 0.035, off, segs=8, mapper=PLAIN)
    return m


def card_board():
    """Painted: a sign-writer's board, its edges chamfered, screwed through its ends to two cleats
    behind. Its front wears the whole SignBoard bake (the pinstripe in from its edge)."""
    m = Mesh("CardBoard")
    w, h, t, cleat = K.CARD_BOARD
    uv = card_uv(w, h, -w / 2, -h / 2)
    geo.box(m, (-w / 2, -cleat - t, -h / 2), (w / 2, -cleat, h / 2), uv, bevel=0.03)
    for sx in (-1, 1):
        a, b = sorted((sx * (w / 2 - 0.02), sx * (w / 2 - 0.42)))
        geo.box(m, (a, -cleat, -h / 2 + 0.18), (b, 0.0, h / 2 - 0.18), uv)
    return m


def board_screws():
    """Two brass screw heads through the board's ends, outside the pinstripe."""
    m = Mesh("CardBoardScrews")
    w, h, t, cleat = K.CARD_BOARD
    for sx in (-1, 1):
        geo.cylinder(m, "y", (sx * (w / 2 - 0.055), -cleat - t - 0.006, 0.0), 0.034, 0.012,
                     segs=10, mapper=PLAIN)
    return m


def card_slate():
    """Chalk's slate, its edge tucked under the frame's lip."""
    m = Mesh("CardSlate")
    sw, sh = K.CARD_SLATE
    y = K.card_slate_y()
    tuck = 0.06
    geo.box(m, (-sw / 2 - tuck, -y, -sh / 2 - tuck), (sw / 2 + tuck, -y + 0.05, sh / 2 + tuck),
            card_uv(sw, sh, -sw / 2, -sh / 2))
    return m


FRAME = ((0.0, -0.12), (0.015, -0.145), (0.05, -0.156), (0.15, -0.156), (0.185, -0.146),
         (0.2, -0.12), (0.2, 0.0), (0.0, 0.0))  # the oak moulding: (out from the slate, y)


def chalk_frame():
    """The slate's oak frame, mitred, each side its own plank; the chalk ledge under it with a
    lip along its front."""
    m = Mesh("CardChalkFrame")
    sw, sh = K.CARD_SLATE
    cols = (3, 6, 8, 10)
    ring(m, FRAME, sw / 2, sh / 2, 0.0, lambda side, lo, hi: wood_uv(0 if side % 2 == 0 else 2, lo, hi, cols[side]))
    out, thick = K.CARD_LEDGE
    z1 = -sh / 2 - K.CARD_FRAME + 0.04
    front = -0.156 - out
    wood_box(m, (-sw / 2 + 0.2, front, z1 - thick), (sw / 2 - 0.2, -0.02, z1), 4, bevel=0.012)
    wood_box(m, (-sw / 2 + 0.2, front, z1), (sw / 2 - 0.2, front + 0.025, z1 + 0.035), 1, bevel=0.006)
    return m


def chalk_stick():
    """A stick of chalk on the ledge, off to the right."""
    m = Mesh("CardChalkStick")
    sw, sh = K.CARD_SLATE
    out, _ = K.CARD_LEDGE
    z = -sh / 2 - K.CARD_FRAME + 0.04 + 0.032
    geo.cylinder(m, "x", (sw / 2 - 1.1, -0.156 - out / 2 - 0.01, z), 0.032, 0.42, segs=8, mapper=PLAIN)
    return m


def neon_path():
    """The tube's run: round the backing's edge from just right of the bottom's middle, back to
    just left of it, each end bending back into the backing."""
    nw, nh, nt, noff = K.CARD_NEON
    r, tin, toff = K.CARD_TUBE
    a, b = nw / 2 - tin, nh / 2 - tin
    y, face = -noff - nt - toff, -noff - nt
    loop = rounded(a, b, 0.24, 5)
    gap = 0.14
    start = [(gap, -b)]
    tail = [(-gap, -b)]
    pts = start + [p for p in loop if not (abs(p[1] + b) < 1e-6 and abs(p[0]) < gap + 0.05)] + tail
    # the outline starts at the bottom-right corner's foot: rotate so the path runs from the gap
    body = [(x, y, z) for x, z in pts]
    return ([(gap, face + 0.01, -b)] + body + [(-gap, face + 0.01, -b)]), (a, b, y, face)


def neon_tube():
    """The glass tube, one run round the border; the game makes it Neon in the glow colour."""
    m = Mesh("CardNeonTube")
    r, _, _ = K.CARD_TUBE
    path, _ = neon_path()
    geo.sweep(m, path, r, segs=8, mapper=PLAIN)
    return m


def neon_back():
    """The dark backing, its corners rounded, on four polished standoffs; the tube's little posts
    and the black sleeves where its ends go in."""
    m = Mesh("CardNeonBack")
    nw, nh, nt, noff = K.CARD_NEON
    slab(m, rounded(nw / 2, nh / 2, 0.2, 6), -noff - nt, -noff, PLAIN)
    for sx in (-1, 1):
        for sz in (-1, 1):
            x, z = sx * (nw / 2 - 0.26), sz * (nh / 2 - 0.26)
            geo.cylinder(m, "y", (x, -noff / 2, z), 0.04, noff, segs=8, mapper=PLAIN)
            geo.cylinder(m, "y", (x, -noff - nt - 0.012, z), 0.06, 0.024, segs=12, mapper=PLAIN)
    path, (a, b, y, face) = neon_path()
    for x, z in ((-a * 0.55, b), (a * 0.55, b), (-a, 0.0), (a, 0.0), (-a * 0.55, -b), (a * 0.55, -b)):
        geo.cylinder(m, "y", (x, (y + face) / 2, z), 0.018, face - y, segs=6, mapper=PLAIN)
    for sx in (-1, 1):
        geo.cylinder(m, "y", (sx * 0.14, face - 0.03, -b), 0.065, 0.06, segs=10, mapper=PLAIN)
    return m


BUILDERS = {"CardSteel": card_steel, "CardSteelBolts": steel_bolts, "CardBoard": card_board,
            "CardBoardScrews": board_screws, "CardSlate": card_slate, "CardChalkFrame": chalk_frame,
            "CardChalkStick": chalk_stick, "CardNeonBack": neon_back, "CardNeonTube": neon_tube}
TEXSET = {"CardSteel": "Plaster", "CardSteelBolts": None, "CardBoard": "SignBoard",
          "CardBoardScrews": None, "CardSlate": "Chalkboard", "CardChalkFrame": "Wood",
          "CardChalkStick": None, "CardNeonBack": None, "CardNeonTube": None}
PLAIN_COLOURS = {"CardSteelBolts": (0.16, 0.16, 0.17), "CardBoardScrews": (0.62, 0.48, 0.24),
                 "CardChalkStick": (0.93, 0.93, 0.9), "CardNeonBack": (0.03, 0.03, 0.04),
                 "CardNeonTube": (1.0, 0.31, 0.62)}
STYLES = {"Stencil": ("CardSteel", "CardSteelBolts"), "Painted": ("CardBoard", "CardBoardScrews"),
          "Chalk": ("CardSlate", "CardChalkFrame", "CardChalkStick"),
          "Neon": ("CardNeonBack", "CardNeonTube")}


def meshes():
    return {name: fn() for name, fn in BUILDERS.items()}
