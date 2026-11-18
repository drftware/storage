"""Every number of the packs: the packaging a sealed find still sits in (ROADMAP S5-02b). Studs,
10 inches a stud, the boxes' scale. Change them here.

A pack's frame in Blender: X across its front, Y away from you (its front faces -Y), Z up, the
origin the middle of its bottom. One pack is shared by every find of a size (the finds' `size`):
the game fits it round the find it holds, the way `fit` below says, so each pack's `cavity` is
the room inside it for a find, at the pack's own size.

The packs are made-up retail packaging in the traditions toy shops used: no maker's name, no
words, no copied print. Their tells from a doorway: the blister's bright card standing up behind
its clear bubble; the window box's coloured frame round the find; the carton's brown board, its
tape and the cut window in its front.
"""

# --- the card-backed blister, for a Small find ---------------------------------------------------
# The card a toy car or a rubber duck hangs on in a shop: printed board with a hang slot in its
# header, a clear bubble sealed to its front round the find. Real cards for a 3 in toy run about
# 5 by 8 in; the bubble stands about 4 in proud.
BLISTER = dict(
    w=0.5,                  # the card's width
    h=0.8,                  # its height, the header with the hang slot included
    t=0.012,                # the card's board (thick stock, a touch bolder than life)
    slot=dict(z=0.715, w=0.11, h=0.032),   # the hang slot cut through the header
    # the bubble: a pillowy clear dome sealed to the card, its flange a flat rim round it
    bubble=dict(w=0.38, h=0.44, d=0.42, z0=0.1, round=0.07, flange=0.03, wall=0.004),
    pad=0.02,               # the gap kept round the find inside the bubble
    stretch=1.15,           # how far one axis may scale past another as it fits a find (fit)
    dust=0.35, seed=7.3,
)

# --- the window box, for a Medium find -----------------------------------------------------------
# The printed carton a wind-up toy or a lamp stood in on a shop shelf: a window cut in its front
# with clear film behind, a printed backdrop inside, a hang tab on top. A 10 in toy's box runs
# about 9 by 9 by 13.5 in.
WINDOW_BOX = dict(
    w=0.86, d=0.86, h=1.36,
    t=0.012,                # the board
    # the window cut in the front: its margin at the sides, its bottom and top edges
    window=dict(side=0.09, z0=0.12, z1=1.16),
    tab=dict(w=0.32, h=0.13, hole=0.035),   # the hang tab standing up off the top's back edge
    sky=dict(y0=0.07, y1=0.5),   # a window in the top over the find's front half: the bulb lights it
    pad=0.03,
    stretch=1.3,
    dust=0.45, seed=3.9,
)

# --- the taped carton, for a Large find ----------------------------------------------------------
# A brown corrugated carton (a regular slotted carton, its top flaps meeting in the middle) taped
# shut across the top and down both ends, a window cut in its front so the find shows, a hand
# hole in each end. Printed in one bold colour on a pale band, as cheap retail cartons are.
CARTON = dict(
    w=1.65, d=0.9, h=1.25,
    t=0.022,                # corrugated board, its flutes showing at every cut edge
    window=dict(side=0.17, z0=0.2, z1=1.02),
    tape=dict(w=0.2, down=0.24, t=0.003),   # 2 in tape along the flaps' seam, down each end
    hand=dict(w=0.36, h=0.12, z=0.84),      # the hand holes in the ends, under the tape
    pad=0.04,
    stretch=1.8,            # brown board stretches without showing it
    dust=0.7, seed=5.2,
)


def cavity(p, kind):
    """The room for a find inside a pack, as (lo, hi) in the pack's frame."""
    if kind == "Blister":
        b = p["bubble"]
        front = -(p["t"] + b["d"]) / 2
        return ((-b["w"] / 2 + b["wall"], front + b["wall"], b["z0"] + b["wall"]),
                (b["w"] / 2 - b["wall"], front + b["d"], b["z0"] + b["h"] - b["wall"]))
    t = p["t"]
    return ((-p["w"] / 2 + t, -p["d"] / 2 + t, t), (p["w"] / 2 - t, p["d"] / 2 - t, p["h"] - t))


def fit(find_size, room, pad, stretch):
    """How much a pack scales on each axis to hold a find of `find_size` (across, deep, up) in its
    `room` (the cavity's size): each axis at least what the find needs with `pad` round it, and
    none less than the largest over `stretch`, so the pack's print never squashes past that."""
    need = [(find_size[i] + 2 * pad) / room[i] for i in range(3)]
    top = max(need)
    return tuple(max(n, top / stretch) for n in need)


# The packs, by the finds' size they hold.
PACKS = [
    ("Small", "Blister", BLISTER),
    ("Medium", "WindowBox", WINDOW_BOX),
    ("Large", "Carton", CARTON),
]
