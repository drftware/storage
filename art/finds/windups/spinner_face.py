"""The farm-animal spinner's printed face (F-04g), drawn in code.

Eight farm animals round a dial, each a bold flat print with a dark keyline, the way a 1960s
lithographed toy face was printed: flat colours, a warm black key over them, the colours laid
a hair off the key. Pure numpy, so build.py prints it on the face (an image the look samples by
position) and `blender -b --factory-startup -P art/finds/windups/spinner_face.py -- <out.png>`
writes it alone, for judging each animal up close.

The face's frame: millimetres from the dial's middle, x right, y up, as you look at it.
"""

import math
import sys

import numpy as np

R = 100.0                 # the printed disc's radius (mm); the bezel's lip covers it past 97
PIC_R = 68.5              # the animals' middles, this far out (mm)
RING = (38.0, 43.5)       # the red ring round the sunburst, inner and outer radius (mm)
SCALE = 1.12              # the pictures, drawn in a 44 x 36 mm box, printed this much bigger
RIM = 93.0                # the red rim round the outside starts here (mm)
SPOKE = 0.85              # half the white spokes' width between the wedges (mm)
LW = 1.15                 # the key's width round each shape (mm)
SHIFT = (0.22, -0.16)     # the colours printed this far off the key (mm): a real litho's tell

# pictures moved off a spoke they'd touch (mm on the face)
NUDGE = {"duck": (-1.6, 0.0), "horse": (1.2, -0.4), "dog": (-0.6, 0.0)}

# the eight, clockwise from the top: what each is and which way it faces (1 right, -1 left)
ORDER = [("cow", 1), ("pig", 1), ("sheep", 1), ("horse", 1),
         ("duck", 1), ("cat", 1), ("rooster", -1), ("dog", -1)]


def hexc(h):
    h = h.lstrip("#")
    return np.array([int(h[i:i + 2], 16) / 255.0 for i in (0, 2, 4)])


KEY = hexc("#2A201B")
CREAM = hexc("#FBF4E2")
BLUE = hexc("#8DCBE6")
YELLOW = hexc("#F6C843")
RED = hexc("#C2382B")


# --- distances (negative inside), on arrays of points ---------------------------------------------

def circle(X, Y, cx, cy, r):
    return np.hypot(X - cx, Y - cy) - r


def ellipse(X, Y, cx, cy, a, b, rot=0.0):
    """An ellipse's distance (Inigo Quilez's estimate: good for the modest ratios drawn here)."""
    c, s = math.cos(math.radians(rot)), math.sin(math.radians(rot))
    x = (X - cx) * c + (Y - cy) * s
    y = -(X - cx) * s + (Y - cy) * c
    k0 = np.hypot(x / a, y / b)
    k1 = np.hypot(x / (a * a), y / (b * b))
    return k0 * (k0 - 1.0) / np.maximum(k1, 1e-9)


def capsule(X, Y, a, b, ra, rb=None):
    """A stroke from a to b, ra wide at a tapering to rb at b."""
    rb = ra if rb is None else rb
    ex, ey = b[0] - a[0], b[1] - a[1]
    wx, wy = X - a[0], Y - a[1]
    h = np.clip((wx * ex + wy * ey) / (ex * ex + ey * ey), 0.0, 1.0)
    return np.hypot(wx - ex * h, wy - ey * h) - (ra + (rb - ra) * h)


def curve(X, Y, pts, ra, rb=None, n=10):
    """A smooth stroke through pts (Catmull-Rom), tapering from ra to rb."""
    rb = ra if rb is None else rb
    P = [np.array(p, dtype=float) for p in pts]
    path = []
    for i in range(len(P) - 1):
        p0, p1, p2, p3 = P[max(i - 1, 0)], P[i], P[i + 1], P[min(i + 2, len(P) - 1)]
        for k in range(n):
            t = k / n
            path.append(0.5 * (2 * p1 + (p2 - p0) * t + (2 * p0 - 5 * p1 + 4 * p2 - p3) * t * t
                               + (3 * p1 - p0 - 3 * p2 + p3) * t ** 3))
    path.append(P[-1])
    d = None
    m = len(path) - 1
    for i in range(m):
        r0 = ra + (rb - ra) * i / m
        r1 = ra + (rb - ra) * (i + 1) / m
        e = capsule(X, Y, path[i], path[i + 1], r0, r1)
        d = e if d is None else np.minimum(d, e)
    return d


def poly(X, Y, pts, r=0.0):
    """A polygon's signed distance (any shape), grown by r to round its corners."""
    d = (X - pts[0][0]) ** 2 + (Y - pts[0][1]) ** 2
    s = np.ones_like(X)
    n = len(pts)
    for i in range(n):
        j = i - 1
        ex, ey = pts[j][0] - pts[i][0], pts[j][1] - pts[i][1]
        wx, wy = X - pts[i][0], Y - pts[i][1]
        h = np.clip((wx * ex + wy * ey) / (ex * ex + ey * ey), 0.0, 1.0)
        bx, by = wx - ex * h, wy - ey * h
        d = np.minimum(d, bx * bx + by * by)
        c1, c2, c3 = Y >= pts[i][1], Y < pts[j][1], ex * wy > ey * wx
        s = np.where((c1 & c2 & c3) | (~c1 & ~c2 & ~c3), -s, s)
    return s * np.sqrt(d) - r


def rbox(X, Y, cx, cy, hx, hy, r):
    qx = np.abs(X - cx) - hx + r
    qy = np.abs(Y - cy) - hy + r
    return np.hypot(np.maximum(qx, 0), np.maximum(qy, 0)) + np.minimum(np.maximum(qx, qy), 0) - r


def smin(a, b, k):
    h = np.clip(0.5 + 0.5 * (b - a) / k, 0.0, 1.0)
    return b * (1 - h) + a * h - k * h * (1 - h)


def union(*ds):
    out = ds[0]
    for d in ds[1:]:
        out = np.minimum(out, d)
    return out


def clip(d, inside):
    """d, only where `inside` (another distance) is."""
    return np.maximum(d, inside)


# --- the press ------------------------------------------------------------------------------------

class Press:
    """Two printings, as a litho press lays them: the colours, then the key over them. Each
    shape is laid in order, back to front; its key rings it, and its colour hides the key of
    whatever it lies over."""

    def __init__(self, n):
        self.n = n
        self.px = 2 * R / n
        c = -R + (np.arange(n) + 0.5) * self.px
        self.X, self.Y = np.meshgrid(c, c)          # row 0 is the bottom, as Blender stores it
        self.col = np.zeros((n, n, 3)) + CREAM
        self.key = np.zeros((n, n))
        self.s = 1.0                                # a picture's scale: its mm to the face's

    def cover(self, d, grow=0.0):
        return np.clip(0.5 - (d * self.s - grow) / self.px, 0.0, 1.0)

    def lay(self, win, d, colour, line=LW):
        """Lay a shape (its distance d over the window win) in colour, ringed by the key."""
        (r0, r1), (c0, c1) = win
        ring = self.cover(d, line) if line > 0 else self.cover(d)
        fill = self.cover(d)
        c = self.col[r0:r1, c0:c1]
        c += (colour - c) * ring[..., None]
        k = self.key[r0:r1, c0:c1]
        k *= 1.0 - ring
        k += ring - fill

    def ink(self, win, d, colour=KEY):
        """A shape printed in one ink with no key round it: eyes, nostrils, stripes, lines."""
        (r0, r1), (c0, c1) = win
        a = self.cover(d)
        c = self.col[r0:r1, c0:c1]
        c += (colour - c) * a[..., None]
        k = self.key[r0:r1, c0:c1]
        if colour is KEY:
            k += (1.0 - k) * a
        else:
            k *= 1.0 - a

    def window(self, cx, cy, half, face=1, rot=0.0):
        """The pixels round (cx, cy) and their coordinates in a picture's own frame: mm from its
        middle, x along its facing, y up."""
        px = self.px
        c0 = max(int((cx - half + R) / px), 0)
        c1 = min(int((cx + half + R) / px) + 1, self.n)
        r0 = max(int((cy - half + R) / px), 0)
        r1 = min(int((cy + half + R) / px) + 1, self.n)
        X = self.X[r0:r1, c0:c1] - cx
        Y = self.Y[r0:r1, c0:c1] - cy
        if rot:
            c, s = math.cos(math.radians(rot)), math.sin(math.radians(rot))
            X, Y = X * c + Y * s, -X * s + Y * c
        return ((r0, r1), (c0, c1)), X * face, Y

    def image(self):
        """RGBA (rows bottom up, 0 to 1, sRGB): the colours shifted off the key, the key over."""
        sx = int(round(SHIFT[0] / self.px))
        sy = int(round(SHIFT[1] / self.px))
        col = np.roll(np.roll(self.col, sy, axis=0), sx, axis=1)
        k = np.clip(self.key, 0.0, 1.0)[..., None]
        out = col * (1.0 - k) + KEY * k
        return np.concatenate([out, np.clip(self.key, 0.0, 1.0)[..., None]], axis=2)


def eye(P, w, X, Y, x, y, r, hl=True):
    P.ink(w, circle(X, Y, x, y, r))
    if hl:
        P.ink(w, circle(X, Y, x + 0.38 * r, y + 0.4 * r, 0.36 * r), CREAM)


def ground(P, w, X, Y, under):
    P.ink(w, ellipse(X, Y, 0.0, -16.3, 17.5, 1.9), under * 0.8)


# --- the animals: each drawn in a 44 x 36 mm box, facing right, standing on y = -16 -----------

def cow(P, w, X, Y, bg):
    ground(P, w, X, Y, bg)
    WHITE, SHADE, PINK, HORN = hexc("#FBF8F0"), hexc("#DAD5C8"), hexc("#F1A3A0"), hexc("#EADDB0")
    HOOF = hexc("#4A3B33")
    # the far legs, a shade darker, then the udder, the body over them
    for x in (-9.0, 8.0):
        P.lay(w, capsule(X, Y, (x, -2.0), (x + 0.3, -13.6), 2.4), SHADE)
        P.ink(w, clip(capsule(X, Y, (x, -2.0), (x + 0.3, -13.6), 2.4), (Y + 12.6)), HOOF)
    P.lay(w, ellipse(X, Y, -6.5, -6.6, 3.4, 2.5), PINK)
    for x in (-13.0, 4.0):
        leg = capsule(X, Y, (x, -2.5), (x, -14.6), 2.6)
        P.lay(w, leg, WHITE)
        P.ink(w, clip(leg, (Y + 13.4)), HOOF)
    tail = curve(X, Y, [(-16.0, 6.0), (-18.6, 3.5), (-19.3, -2.0), (-19.0, -6.0)], 0.75, 0.6)
    P.lay(w, tail, WHITE, 0.8)
    P.lay(w, ellipse(X, Y, -19.0, -7.6, 1.7, 2.5), KEY, 0.0)
    body = rbox(X, Y, -2.5, 1.0, 14.5, 7.6, 6.5)
    P.lay(w, body, WHITE)
    # black patches, as a Holstein's
    spots = union(smin(circle(X, Y, -9.5, 4.8, 4.2), circle(X, Y, -6.0, 1.0, 3.0), 2.0),
                  ellipse(X, Y, 1.5, 5.6, 3.6, 2.6, 15.0), ellipse(X, Y, -13.5, -3.5, 2.6, 3.4),
                  circle(X, Y, -2.5, -3.6, 1.7))
    P.ink(w, clip(spots, body))
    # the head, turned to look at you
    hx, hy = 11.0, 5.5
    for s in (-1, 1):
        P.lay(w, capsule(X, Y, (hx + 3.9 * s, hy + 7.5), (hx + 6.4 * s, hy + 11.3), 1.45, 0.65), HORN)
        P.lay(w, ellipse(X, Y, hx + 8.0 * s, hy + 4.6, 4.0, 2.0, -20.0 * s), WHITE)
        P.ink(w, ellipse(X, Y, hx + 8.6 * s, hy + 4.4, 2.4, 0.95, -20.0 * s), PINK)
    head = ellipse(X, Y, hx, hy + 2.0, 6.1, 7.2)
    P.lay(w, head, WHITE)
    P.ink(w, clip(ellipse(X, Y, hx - 3.4, hy + 5.0, 3.0, 3.4, 10.0), head))
    P.lay(w, ellipse(X, Y, hx, hy - 3.4, 6.3, 3.9), PINK)
    for s in (-1, 1):
        P.ink(w, ellipse(X, Y, hx + 2.5 * s, hy - 3.1, 0.95, 1.35, 15.0 * s), hexc("#6E3434"))
        eye(P, w, X, Y, hx + 3.1 * s, hy + 3.9, 1.25)


def pig(P, w, X, Y, bg):
    ground(P, w, X, Y, bg)
    PINK, FAR, SNOUT, EAR = hexc("#F5A8B6"), hexc("#E28A9C"), hexc("#EC8EA2"), hexc("#E9879B")
    HOOF, MUD = hexc("#8E5560"), hexc("#94674A")
    for x in (-8.5, 7.0):
        leg = capsule(X, Y, (x, -2.0), (x, -13.5), 2.7)
        P.lay(w, leg, FAR)
        P.ink(w, clip(leg, (Y + 12.3)), HOOF)
    # the curly tail: a loop and a flick
    t = [(-15.5, 3.0), (-18.0, 4.4), (-19.4, 6.6), (-18.3, 8.6), (-16.6, 7.6), (-17.2, 5.6),
         (-19.6, 4.2), (-21.0, 4.8)]
    P.lay(w, curve(X, Y, t, 0.6, 0.45), PINK, 0.7)
    for x in (-12.5, 3.0):
        leg = capsule(X, Y, (x, -3.0), (x, -14.4), 2.8)
        P.lay(w, leg, PINK)
        P.ink(w, clip(leg, (Y + 13.1)), HOOF)
    body = smin(ellipse(X, Y, -3.0, 0.5, 14.5, 9.6), circle(X, Y, 10.0, 2.8, 7.4), 3.0)
    P.lay(w, body, PINK)
    P.ink(w, clip(ellipse(X, Y, -10.5, -1.5, 4.3, 3.2, 20.0), body), MUD)
    P.ink(w, clip(circle(X, Y, -6.5, -4.2, 1.1), body), MUD)
    P.lay(w, ellipse(X, Y, 17.4, 0.9, 2.6, 4.1), SNOUT)
    for y in (2.3, -0.5):
        P.ink(w, ellipse(X, Y, 17.9, y, 0.55, 1.0), hexc("#7A3446"))
    P.lay(w, poly(X, Y, [(6.2, 8.6), (11.8, 8.8), (13.6, 15.2)], 0.6), EAR)
    P.ink(w, ellipse(X, Y, 11.6, -0.6, 2.2, 1.3), hexc("#EF8297"))
    eye(P, w, X, Y, 12.1, 5.0, 1.15)
    P.ink(w, curve(X, Y, [(15.2, -2.0), (13.8, -3.0), (12.0, -3.1)], 0.3), KEY)


def sheep(P, w, X, Y, bg):
    ground(P, w, X, Y, bg)
    WOOL, CURL, FACE, PINK = hexc("#F7F1DF"), hexc("#DDD0B0"), hexc("#2F2724"), hexc("#D98A8E")
    for x in (-7.5, 6.5):
        P.lay(w, capsule(X, Y, (x, -2.0), (x, -14.0), 1.45), hexc("#4A403B"), 0.9)
    P.lay(w, circle(X, Y, -15.3, 3.6, 2.6), WOOL)
    for x in (-11.0, 3.5):
        P.lay(w, capsule(X, Y, (x, -4.0), (x, -14.8), 1.55), FACE, 0.9)
    # a cloud of wool: an oval with fourteen puffs round its edge
    wool = ellipse(X, Y, -2.5, 2.0, 12.0, 7.6)
    for i in range(14):
        a = 2 * math.pi * (i + 0.3) / 14
        r = 3.3 + 0.35 * math.sin(i * 2.7)
        wool = np.minimum(wool, circle(X, Y, -2.5 + 11.6 * math.cos(a), 2.0 + 7.2 * math.sin(a), r))
    P.lay(w, wool, WOOL)
    for cx, cy, a0 in ((-11.0, 5.0, 30), (-6.0, 7.5, 200), (-1.0, 4.0, 90), (3.5, 7.0, 260),
                       (-8.0, -1.5, 150), (-2.5, -3.5, 330), (2.5, 0.5, 20), (-13.5, 0.5, 240)):
        pts = [(cx + 1.4 * math.cos(math.radians(a0 + 50 * k)), cy + 1.4 * math.sin(math.radians(a0 + 50 * k)))
               for k in range(6)]
        P.ink(w, curve(X, Y, pts, 0.32, 0.25, n=4), CURL)
    # the dark face, nose down, ears out behind it, a tuft of wool on top
    P.lay(w, ellipse(X, Y, 9.6, 7.6, 3.4, 1.35, -12.0), FACE)
    P.ink(w, ellipse(X, Y, 9.2, 7.7, 2.2, 0.6, -12.0), PINK)
    P.lay(w, ellipse(X, Y, 13.6, 4.0, 4.0, 5.7, 38.0), FACE)
    for cx, cy, r in ((11.2, 8.9, 2.2), (13.4, 9.6, 2.3), (12.2, 11.2, 1.9), (15.2, 8.5, 1.7)):
        P.lay(w, circle(X, Y, cx, cy, r), WOOL, 0.9)
    P.ink(w, circle(X, Y, 14.6, 5.4, 1.15), CREAM)
    eye(P, w, X, Y, 14.9, 5.3, 0.62, hl=False)
    P.ink(w, curve(X, Y, [(17.2, 1.2), (16.4, 0.4), (15.5, 0.6)], 0.28), hexc("#8A7A72"))


def horse(P, w, X, Y, bg):
    ground(P, w, X, Y, bg)
    COAT, FAR, MANE, NOSE = hexc("#B9682F"), hexc("#94511F"), hexc("#3E2416"), hexc("#8C4A22")
    SOCK, HOOF = hexc("#FAF6EC"), hexc("#3A2A20")
    for x in (-8.0, 6.5):
        leg = capsule(X, Y, (x, -1.0), (x, -14.6), 1.75)
        P.lay(w, leg, FAR, 0.95)
        P.ink(w, clip(leg, (Y + 13.6)), HOOF)
    P.lay(w, curve(X, Y, [(-14.0, 4.5), (-17.6, 2.0), (-18.6, -4.0), (-17.4, -10.0)], 2.1, 1.2), MANE)
    for x, sock in ((-12.0, True), (3.0, False)):
        leg = capsule(X, Y, (x, -1.5), (x, -15.0), 1.85)
        P.lay(w, leg, COAT, 0.95)
        if sock:
            P.ink(w, clip(leg, np.maximum(Y + 11.2, -(Y + 13.8))), SOCK)
        P.ink(w, clip(leg, (Y + 13.9)), HOOF)
    sil = smin(ellipse(X, Y, -3.0, 1.0, 12.8, 6.4),
               capsule(X, Y, (6.0, 3.0), (11.0, 11.0), 5.0, 3.6), 2.5)
    head = capsule(X, Y, (11.2, 12.8), (18.4, 7.4), 3.5, 2.5)
    sil = smin(sil, head, 1.2)
    P.lay(w, poly(X, Y, [(9.0, 14.6), (11.0, 15.4), (9.6, 18.4)], 0.5), COAT)
    P.lay(w, sil, COAT)
    P.ink(w, clip(circle(X, Y, 18.8, 7.0, 3.0), head), NOSE)
    P.ink(w, clip(capsule(X, Y, (12.8, 12.6), (17.0, 8.6), 0.75, 0.55), sil), SOCK)
    mane = union(*[circle(X, Y, 10.4 - 1.3 * i, 15.0 - 1.75 * i, 1.85 - 0.08 * i) for i in range(6)])
    mane = np.minimum(mane, ellipse(X, Y, 12.4, 14.7, 1.7, 1.0, -30.0))
    P.lay(w, mane, MANE, 0.9)
    eye(P, w, X, Y, 13.3, 11.4, 1.0)
    P.ink(w, ellipse(X, Y, 19.4, 7.4, 0.5, 0.75, -30.0), hexc("#2B1A12"))
    P.ink(w, curve(X, Y, [(19.6, 5.3), (18.3, 5.0), (17.2, 5.4)], 0.25), hexc("#2B1A12"))


def duck(P, w, X, Y, bg):
    ground(P, w, X, Y, bg)
    WHITE, WING, ORANGE = hexc("#FBF8EF"), hexc("#E4DFD0"), hexc("#F2962A")
    for x in (-4.0, 2.0):
        P.lay(w, capsule(X, Y, (x, -8.0), (x + 0.5, -12.8), 0.75), ORANGE, 0.8)
        P.lay(w, poly(X, Y, [(x - 1.6, -12.4), (x + 4.4, -15.4), (x - 1.4, -15.4)], 0.5), ORANGE, 0.9)
    body = ellipse(X, Y, -2.0, -3.0, 12.8, 7.8)
    body = smin(body, poly(X, Y, [(-11.0, -4.5), (-19.2, 5.4), (-12.5, 2.6)], 0.8), 2.2)
    body = smin(body, capsule(X, Y, (6.0, 0.5), (9.6, 6.8), 4.4, 3.9), 2.5)
    body = smin(body, circle(X, Y, 10.2, 9.0, 5.8), 1.5)
    P.lay(w, body, WHITE)
    P.lay(w, poly(X, Y, [(14.2, 9.7), (21.2, 8.8), (21.4, 6.6), (14.2, 6.4)], 1.0), ORANGE)
    P.ink(w, curve(X, Y, [(15.5, 8.0), (18.5, 7.85), (21.6, 7.6)], 0.28))
    P.ink(w, ellipse(X, Y, 16.4, 9.3, 0.55, 0.3), hexc("#9C5512"))
    wing = smin(ellipse(X, Y, -3.0, -2.2, 8.6, 4.4, 8.0),
                ellipse(X, Y, -10.4, -0.4, 3.2, 1.7, 25.0), 1.2)
    P.lay(w, wing, WING, 0.9)
    for y0 in (-0.6, -3.2):
        P.ink(w, curve(X, Y, [(-11.0, y0 + 1.0), (-7.0, y0), (-3.5, y0 - 0.2)], 0.25), hexc("#A39C8A"))
    eye(P, w, X, Y, 11.6, 10.6, 1.15)


def rooster(P, w, X, Y, bg):
    ground(P, w, X, Y, bg)
    BODY, WING, HACKLE = hexc("#C4552A"), hexc("#9E4220"), hexc("#EAA43C")
    TAIL, SHEEN, RED, YEL = hexc("#1E4A3B"), hexc("#3C7A5E"), hexc("#D8262B"), hexc("#F3B43B")
    for x in (-1.5, 2.5):
        P.lay(w, capsule(X, Y, (x, -6.0), (x + 0.3, -13.8), 0.95), YEL, 0.8)
        for dx, dy in ((2.6, -0.4), (1.7, -1.4), (-1.6, -0.2)):
            P.lay(w, capsule(X, Y, (x + 0.3, -13.8), (x + 0.3 + dx, -13.8 + dy - 0.6), 0.55), YEL, 0.7)
    # the sickle tail: three long arcs and their sheen
    for pts, r0 in (([(-7.0, -1.5), (-12.5, 1.5), (-17.0, 0.0), (-18.6, -4.2)], 2.1),
                    ([(-6.5, 1.0), (-11.5, 7.0), (-17.0, 7.6), (-20.2, 3.2)], 2.3),
                    ([(-5.5, 3.0), (-9.0, 10.5), (-14.6, 14.8), (-19.4, 13.0), (-21.0, 8.0)], 2.5)):
        f = curve(X, Y, pts, r0, 0.7)
        P.lay(w, f, TAIL, 1.0)
        P.ink(w, clip(curve(X, Y, [(x + 0.2, y + 0.6) for x, y in pts[:-1]], 0.45, 0.25), f), SHEEN)
    P.lay(w, ellipse(X, Y, -1.0, -0.8, 10.0, 7.6, -12.0), BODY)
    P.lay(w, ellipse(X, Y, -2.0, -0.5, 6.4, 4.0, -8.0), WING, 0.9)
    for y0 in (0.6, -1.7):
        P.ink(w, curve(X, Y, [(-7.5, y0 + 0.5), (-4.0, y0), (-0.5, y0 + 0.2)], 0.25), hexc("#6E2C15"))
    # the comb behind the head, the golden hackle down its neck, then the head
    comb = union(circle(X, Y, 6.4, 14.0, 1.7), circle(X, Y, 8.6, 15.1, 1.8),
                 circle(X, Y, 10.8, 14.3, 1.55), ellipse(X, Y, 8.5, 12.8, 3.6, 1.8))
    P.lay(w, comb, RED)
    hack = smin(capsule(X, Y, (4.0, 1.5), (7.6, 9.6), 5.0, 3.6),
                union(*[circle(X, Y, 1.6 + 1.7 * i, 0.4 - 0.3 * i, 1.6) for i in range(4)]), 1.0)
    P.lay(w, hack, HACKLE)
    P.lay(w, circle(X, Y, 8.6, 10.6, 3.7), hexc("#D9672E"))
    P.lay(w, poly(X, Y, [(11.4, 11.6), (15.6, 10.4), (11.4, 9.0)], 0.35), YEL, 0.9)
    P.lay(w, ellipse(X, Y, 11.0, 7.0, 1.3, 2.1, 10.0), RED, 0.9)
    P.ink(w, circle(X, Y, 9.7, 11.3, 1.05), hexc("#F09A2A"))
    eye(P, w, X, Y, 9.85, 11.3, 0.62, hl=False)


def cat(P, w, X, Y, bg):
    ground(P, w, X, Y, bg)
    GREY, STRIPE, WHITE, PINK = hexc("#9B9EA4"), hexc("#5C5F66"), hexc("#F6F3EB"), hexc("#F09FAC")
    GREEN = hexc("#A3CC4C")
    tail = curve(X, Y, [(6.0, -14.5), (12.6, -13.6), (14.6, -8.0), (13.2, -3.2), (11.4, -1.8)], 1.6, 1.2)
    P.lay(w, tail, GREY)
    for p, q in (((12.3, -14.8), (13.0, -12.4)), ((15.4, -9.0), (13.1, -8.6)), ((15.0, -5.0), (12.6, -5.4))):
        P.ink(w, clip(capsule(X, Y, p, q, 0.55), tail), STRIPE)
    body = clip(union(ellipse(X, Y, 0.0, -6.8, 9.2, 10.4), ellipse(X, Y, -6.0, -12.0, 4.8, 4.6),
                      ellipse(X, Y, 6.0, -12.0, 4.8, 4.6)), -(Y + 16.3))
    P.lay(w, body, GREY)
    for s in (-1, 1):
        for k in range(2):
            P.ink(w, clip(curve(X, Y, [(s * (10.5 - k * 1.2), -9.0 - k * 2.6), (s * (8.0 - k), -8.2 - k * 2.6),
                                         (s * (6.2 - k), -9.2 - k * 2.6)], 0.5), body), STRIPE)
    P.ink(w, clip(ellipse(X, Y, 0.0, -5.6, 4.2, 6.2), body), WHITE)
    for s in (-1, 1):
        P.lay(w, ellipse(X, Y, 3.0 * s, -15.5, 2.6, 1.6), WHITE, 0.9)
        P.ink(w, capsule(X, Y, (3.0 * s, -16.6), (3.0 * s, -15.6), 0.2))
    # the head: ears, the face, green eyes, a pink nose and whiskers
    for s in (-1, 1):
        P.lay(w, poly(X, Y, [(-7.6 * s, 8.6), (-2.6 * s, 11.6), (-6.4 * s, 16.4)][::s], 0.7), GREY)
        P.ink(w, poly(X, Y, [(-6.6 * s, 9.8), (-4.0 * s, 11.4), (-6.0 * s, 14.4)][::s], 0.3), PINK)
    head = ellipse(X, Y, 0.0, 6.6, 8.4, 6.8)
    P.lay(w, head, GREY)
    for x in (-1.6, 0.0, 1.6):
        P.ink(w, capsule(X, Y, (x, 10.2), (x * 0.8, 12.6), 0.45), STRIPE)
    for s in (-1, 1):
        P.ink(w, clip(capsule(X, Y, (8.6 * s, 7.2), (6.4 * s, 6.6), 0.45), head), STRIPE)
        P.ink(w, clip(capsule(X, Y, (8.4 * s, 5.0), (6.6 * s, 4.8), 0.4), head), STRIPE)
        P.ink(w, ellipse(X, Y, 1.75 * s, 3.4, 2.2, 1.6), WHITE)
        P.lay(w, ellipse(X, Y, 3.3 * s, 7.5, 1.9, 1.45, -8.0 * s), GREEN, 0.45)
        P.ink(w, ellipse(X, Y, 3.3 * s, 7.5, 0.45, 1.25))
        P.ink(w, circle(X, Y, 3.3 * s + 0.6, 8.0, 0.32), CREAM)
        for k, (yy, ty) in enumerate(((3.6, 4.6), (3.0, 2.9), (2.4, 1.2))):
            P.ink(w, capsule(X, Y, (3.6 * s, yy), (10.6 * s, ty), 0.17))
    P.lay(w, poly(X, Y, [(-1.2, 5.0), (1.2, 5.0), (0.0, 3.7)], 0.25), PINK, 0.35)
    P.ink(w, curve(X, Y, [(0.0, 3.7), (0.0, 3.0), (-0.9, 2.5), (-1.7, 2.9)], 0.2))
    P.ink(w, curve(X, Y, [(0.0, 3.0), (0.9, 2.5), (1.7, 2.9)], 0.2))


def dog(P, w, X, Y, bg):
    ground(P, w, X, Y, bg)
    BLACK, FAR, WHITE, TAN = hexc("#2D2827"), hexc("#3E3836"), hexc("#F7F4EC"), hexc("#C98A4B")
    PINK = hexc("#E8798A")
    for x in (-8.5, 7.0):
        leg = capsule(X, Y, (x, -2.0), (x, -13.8), 2.0)
        P.lay(w, leg, FAR, 0.9)
        P.ink(w, clip(leg, (Y + 11.6)), hexc("#E2DDD2"))
    tail = curve(X, Y, [(-13.0, 2.0), (-16.6, 5.0), (-18.6, 9.8)], 2.3, 1.3)
    P.lay(w, tail, BLACK, 0.9)
    P.ink(w, clip(circle(X, Y, -18.6, 10.2, 2.4), tail), WHITE)
    for x in (-12.0, 4.0):
        leg = capsule(X, Y, (x, -2.5), (x, -14.2), 2.1)
        P.lay(w, leg, BLACK, 0.9)
        P.ink(w, clip(leg, (Y + 11.8)), WHITE)
    body = smin(ellipse(X, Y, -2.5, 0.2, 12.0, 6.4), capsule(X, Y, (6.0, 1.5), (10.0, 7.5), 4.6, 4.0), 2.0)
    P.lay(w, body, BLACK)
    P.ink(w, clip(ellipse(X, Y, 8.6, 1.6, 4.4, 7.0, 14.0), body), WHITE)
    P.lay(w, ellipse(X, Y, 16.0, 2.5, 1.35, 2.0, -8.0), PINK, 0.8)
    head = smin(circle(X, Y, 11.0, 8.6, 5.2), capsule(X, Y, (13.0, 6.8), (18.8, 5.7), 3.1, 2.4), 1.6)
    P.lay(w, head, BLACK)
    P.ink(w, clip(capsule(X, Y, (13.0, 6.4), (19.4, 5.4), 3.0, 2.3), head), WHITE)
    P.ink(w, clip(capsule(X, Y, (13.4, 7.4), (11.4, 13.4), 1.0, 0.8), head), WHITE)
    P.lay(w, ellipse(X, Y, 8.4, 9.6, 2.0, 4.3, -22.0), BLACK, 0.9)
    P.ink(w, curve(X, Y, [(14.2, 4.0), (16.0, 3.4), (17.6, 3.8)], 0.25))
    P.lay(w, circle(X, Y, 19.6, 6.1, 1.5), hexc("#1C1817"), 0.6)
    P.ink(w, circle(X, Y, 19.9, 6.6, 0.45), hexc("#8C8480"))
    P.ink(w, circle(X, Y, 13.0, 11.6, 0.85), TAN)
    P.ink(w, circle(X, Y, 13.2, 9.7, 1.15), WHITE)
    eye(P, w, X, Y, 13.3, 9.6, 0.82)


ANIMALS = dict(cow=cow, pig=pig, sheep=sheep, horse=horse, duck=duck, cat=cat, rooster=rooster, dog=dog)


def wedge_at(k):
    """The kth wedge's middle, degrees anticlockwise from +x (k = 0 at the top, clockwise)."""
    return 90.0 - 45.0 * k


def draw(n=2048):
    """The whole face, n pixels across: RGBA rows bottom up, sRGB, the key's mask in alpha."""
    P = Press(n)
    X, Y = P.X, P.Y
    rr = np.hypot(X, Y)
    th = np.degrees(np.arctan2(Y, X))
    whole = ((0, n), (0, n))
    # eight wedges, sky blue and sunflower by turns, white spokes between them
    for k in range(8):
        d = (th - wedge_at(k) + 180.0) % 360.0 - 180.0
        inside = np.maximum(np.abs(np.radians(d)) * rr - (rr * math.radians(22.5)), rr - R - 1)
        P.ink(whole, inside, BLUE if k % 2 == 0 else YELLOW)
    spoke = None
    for k in range(8):
        a = math.radians(wedge_at(k) + 22.5)
        dd = np.abs(-X * math.sin(a) + Y * math.cos(a)) - SPOKE
        dd = np.maximum(dd, -(X * math.cos(a) + Y * math.sin(a)))
        spoke = dd if spoke is None else np.minimum(spoke, dd)
    P.ink(whole, spoke, CREAM)
    # the animals
    for k, (name, face) in enumerate(ORDER):
        a = math.radians(wedge_at(k))
        dx, dy = NUDGE.get(name, (0.0, 0.0))
        win, Xl, Yl = P.window(PIC_R * math.cos(a) + dx, PIC_R * math.sin(a) + dy, 27.0 * SCALE, face)
        P.s = SCALE
        ANIMALS[name](P, win, Xl / SCALE, Yl / SCALE, BLUE if k % 2 == 0 else YELLOW)
        P.s = 1.0
    # the red rim round the outside, a cream line in it
    P.lay(whole, -(rr - RIM), RED, 0.9)
    P.ink(whole, np.abs(rr - (RIM + 2.6)) - 0.35, CREAM)
    # the middle: a sunburst in two creams, a red ring with a white pointer mark at each wedge
    P.ink(whole, rr - RING[1], RED)
    sun = np.where((np.cos(np.radians(th) * 16.0) > 0)[..., None], hexc("#FAEBC4"), hexc("#F4D78E"))
    a = np.clip(0.5 - (rr - RING[0]) / P.px, 0, 1)[..., None]
    P.col += (sun - P.col) * a
    P.key *= 1.0 - a[..., 0]
    P.key += np.clip(0.5 - np.abs(rr - RING[0]) / P.px + 0.45 / P.px, 0, 1) * (1 - P.key)
    P.key += np.clip(0.5 - np.abs(rr - RING[1]) / P.px + 0.45 / P.px, 0, 1) * (1 - P.key)
    for k in range(8):
        a = math.radians(wedge_at(k))
        u, v = math.cos(a), math.sin(a)
        tip, base, hw = RING[1] - 0.6, RING[0] + 1.2, 2.2
        pts = [(u * tip, v * tip), (u * base - v * hw, v * base + u * hw), (u * base + v * hw, v * base - u * hw)]
        P.ink(whole, poly(X, Y, pts, 0.3), CREAM)
    return P.image()


if __name__ == "__main__":
    # judging the face alone: blender -b --factory-startup -P spinner_face.py -- out.png [px]
    import bpy

    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    out = argv[0] if argv else "spinner_face.png"
    n = int(argv[1]) if len(argv) > 1 else 2048
    rgba = draw(n)
    rgba[..., 3] = 1.0
    img = bpy.data.images.new("SpinnerFace", n, n, alpha=False)
    img.pixels.foreach_set(rgba.astype(np.float32).ravel())
    img.filepath_raw = out
    img.file_format = "PNG"
    img.save()
    print("FACE", out)
