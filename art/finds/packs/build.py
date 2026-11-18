"""The packs: the packaging a sealed find still sits in (art/finds/packs/README.md), built with the
finds kit.

    scripts/art.sh set packs [textures|export|renders|quick] [Blister|WindowBox|Carton]
    blender -b --factory-startup -P art/finds/packs/build.py -- --stage sheets

`export` also writes src/shared/Finds/PackFit.luau (each pack's room for a find, for the game's
fit); `sheets` renders every pack round a real find from the windups set, in the studio, held on
a phone and on a unit's floor from its doorway (art/sheets/packs-*.png).
"""

import importlib.util
import math
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "kit"))
sys.path.insert(0, HERE)

import bpy  # noqa: E402
from mathutils import Matrix, Vector  # noqa: E402

import kit  # noqa: E402
import render  # noqa: E402
import spec as K  # noqa: E402
from look import Coat, hexc  # noqa: E402
from shapes import Shape  # noqa: E402

# What a face is, for the looks.
(BOARD, FILM, TAPE, KRAFT) = range(4)


def segs(hi, lo_n):
    return lo_n * 2 if hi else lo_n


# --- masks the prints are drawn with -------------------------------------------------------------

def rect(L, a, a0, a1, b, b0, b1, soft=0.002):
    nb = L.nb
    return nb.mul(nb.band(a, a0, a1, soft), nb.band(b, b0, b1, soft))


def disc(L, a, ac, b, bc, r, soft=0.003, sa=1.0, sb=1.0):
    """1 inside the ellipse round (ac, bc), r across scaled by sa and sb."""
    nb = L.nb
    da, db = nb.mul(nb.sub(a, ac), 1.0 / sa), nb.mul(nb.sub(b, bc), 1.0 / sb)
    d = nb.pw(nb.add(nb.mul(da, da), nb.mul(db, db)), 0.5)
    return nb.inv(nb.ss(d, r - soft, r + soft))


def facing(L, n, sign):
    """1 on faces turned toward axis n's `sign` end (n: L.nx, L.ny or L.nz)."""
    nb = L.nb
    return nb.ss(nb.mul(n, sign), 0.5, 0.8)


def outward(L, c):
    """1 on a panel's outer face, 0 on its inner one: the normal points away from the middle c."""
    nb = L.nb
    d = nb.add(nb.add(nb.mul(L.nx, nb.sub(L.x, c[0])), nb.mul(L.ny, nb.sub(L.y, c[1]))),
               nb.mul(L.nz, nb.sub(L.z, c[2])))
    return nb.ss(d, -0.004, 0.004)


def barcode(L, a, a0, b, b0, w=0.09, h=0.05):
    """A block of bars, the way every box's back carries one (no number under it)."""
    nb = L.nb
    bars = nb.ss(nb.mul(nb.sin(nb.mul(a, 610.0)), nb.sin(nb.mul(a, 233.0))), -0.05, 0.05)
    return nb.mul(rect(L, a, a0, a0 + w, b, b0, b0 + h, 0.001), bars)


# --- the card-backed blister (Small) -------------------------------------------------------------

B = K.BLISTER
BB = B["bubble"]
B_D = B["t"] + BB["d"]                 # the whole pack front to back
B_BACK = B_D / 2                       # the card's back face
B_CARD = B_BACK - B["t"]               # the card's front face, where the bubble is sealed
B_FRONT = -B_D / 2                     # the bubble's front


def bl_card(hi):
    """The printed card, its hang slot cut through the header."""
    s = Shape()
    w, h, sl = B["w"] / 2, B["h"], B["slot"]
    z0, z1, sx = sl["z"] - sl["h"] / 2, sl["z"] + sl["h"] / 2, sl["w"] / 2
    for lo, hi_ in (((-w, B_CARD, 0.0), (w, B_BACK, z0)), ((-w, B_CARD, z1), (w, B_BACK, h)),
                    ((-w, B_CARD, z0), (-sx, B_BACK, z1)), ((sx, B_CARD, z0), (w, B_BACK, z1))):
        s.box(lo, hi_, BOARD)
    return s


def bl_bubble(hi):
    """The clear bubble round the find, and the flat flange it's sealed to the card by."""
    s = Shape()
    w, f, z0, z1 = BB["w"] / 2, BB["flange"], BB["z0"], BB["z0"] + BB["h"]
    s.box((-w, B_FRONT, z0), (w, B_CARD - 0.001, z1), FILM, BB["round"], segs(hi, 3))
    y0, y1 = B_CARD - 0.004, B_CARD - 0.0005
    for lo, hi_ in (((-w - f, y0, z0 - f), (w + f, y1, z0)), ((-w - f, y0, z1), (w + f, y1, z1 + f)),
                    ((-w - f, y0, z0), (-w, y1, z1)), ((w, y0, z0), (w + f, y1, z1))):
        s.box(lo, hi_, FILM)
    return s


def film_look(C, L, mask, glare_at, alpha=0.17, col="#E9E3C9"):
    """Clear plastic gone a little yellow in storage, a diagonal glare across it."""
    nb = L.nb
    C.paint(mask, hexc(col), 0.05, 0.0, alpha=alpha)
    # broad and soft: a hard thin glare read as a white rod inside the box
    glare = nb.mul(mask, nb.band(nb.add(L.x, nb.mul(L.z, 0.55)), glare_at, glare_at + 0.1, 0.06))
    C.paint(glare, hexc("#F4F1E6"), 0.03, alpha=0.24)


def bl_look(L, f):
    nb = L.nb
    w, h = B["w"] / 2, B["h"]
    card = L.k(BOARD)
    front = nb.mul(card, facing(L, L.ny, -1.0))
    back = nb.mul(card, facing(L, L.ny, 1.0))
    # the board's grey core shows at every cut edge
    C = Coat(L, hexc("#D9D2C2"), 0.8)
    # the front: warm yellow, a glow of paler yellow behind the bubble, a red header with a white
    # burst, a red band along the foot and a white keyline round it all
    C.paint(front, hexc("#F3BE1C"), 0.45)
    bz = BB["z0"] + BB["h"] / 2
    C.paint(nb.mul(front, disc(L, L.x, 0.0, L.z, bz, 0.3, 0.12)), hexc("#FBE48A"))
    header = h - 0.19
    C.paint(nb.mul(front, nb.ss(L.z, header - 0.002, header + 0.002)), hexc("#C9261D"), 0.42)
    C.paint(nb.mul(front, nb.inv(nb.ss(L.z, 0.05, 0.054))), hexc("#C9261D"), 0.42)
    C.paint(nb.mul(front, disc(L, L.x, w - 0.07, L.z, header - 0.005, 0.06, 0.003)), hexc("#FFF6E0"))
    C.paint(nb.mul(front, disc(L, L.x, w - 0.07, L.z, header - 0.005, 0.04, 0.003)), hexc("#F3BE1C"))
    edge = 0.018
    keyline = nb.mul(rect(L, L.x, -w + edge, w - edge, L.z, edge, h - edge, 0.001),
                     nb.inv(rect(L, L.x, -w + edge + 0.008, w - edge - 0.008, L.z, edge + 0.008,
                                 h - edge - 0.008, 0.001)))
    C.paint(nb.mul(front, keyline), hexc("#FFF6E0"))
    # the back: plain board, a printed strip along the top and the bars
    C.paint(back, hexc("#E2DCCF"), 0.7)
    C.paint(nb.mul(back, nb.ss(L.z, h - 0.06, h - 0.056)), hexc("#C9261D"), 0.45)
    C.paint(nb.mul(back, barcode(L, nb.mul(L.x, -1.0), -0.2, L.z, 0.05)), hexc("#1E1C1A"))
    # handled: soft creases and scuffs on the board, worst at the corners
    C.enamel_wear(nb.mul(card, nb.inv(facing(L, L.ny, 1.0))), hexc("#E8DFC9"), s=3, amount=0.5)
    film_look(C, L, L.k(FILM), -0.05)
    C.finish(f.dust, grime=0.35)
    return C.surface(bump_dist=0.002, bump=0.3)


# --- panels: the window box and the carton -------------------------------------------------------

def panels(s, p, kind, top=True):
    """A box's six sides of board `t` thick, the front cut round its window."""
    w, d, h, t, win = p["w"] / 2, p["d"] / 2, p["h"], p["t"], p["window"]
    ch = 0.002
    s.box((-w, d - t, 0.0), (w, d, h), kind, ch)                       # back
    s.box((-w, -d, 0.0), (-w + t, d - t, h), kind, ch)                 # left end
    s.box((w - t, -d, 0.0), (w, d - t, h), kind, ch)                   # right end
    s.box((-w + t, -d + t, 0.0), (w - t, d - t, t), kind, ch)          # bottom
    if top and "sky" in p:
        # the top cut round a skylight over the find's front half, so the bulb lights it
        x, y0, y1 = w - win["side"], -d + p["sky"]["y0"], -d + p["sky"]["y1"]
        for lo, hi in (((-w + t, -d + t, h - t), (w - t, y0, h)), ((-w + t, y1, h - t), (w - t, d - t, h)),
                       ((-w + t, y0, h - t), (-x, y1, h)), ((x, y0, h - t), (w - t, y1, h))):
            s.box(lo, hi, kind, ch)
    elif top:
        s.box((-w + t, -d + t, h - t), (w - t, d - t, h), kind, ch)
    x = w - win["side"]
    for lo, hi in (((-w + t, -d, 0.0), (w - t, -d + t, win["z0"])),
                   ((-w + t, -d, win["z1"]), (w - t, -d + t, h)),
                   ((-w + t, -d, win["z0"]), (-x, -d + t, win["z1"])),
                   ((x, -d, win["z0"]), (w - t, -d + t, win["z1"]))):
        s.box(lo, hi, kind, ch)


def window_film(p):
    """The clear film glued behind the window."""
    w, d, t, win = p["w"] / 2, p["d"] / 2, p["t"], p["window"]
    x = w - win["side"] + 0.03

    def build(hi):
        s = Shape()
        s.box((-x, -d + t, win["z0"] - 0.03), (x, -d + t + 0.003, win["z1"] + 0.03), FILM)
        if "sky" in p:
            h, y0, y1 = p["h"], -d + p["sky"]["y0"], -d + p["sky"]["y1"]
            s.box((-x, y0 - 0.03, h - t - 0.003), (x, y1 + 0.03, h - t), FILM)
        return s
    return build, (0.0, -d + t + 0.0015, (win["z0"] + win["z1"]) / 2)


def cut_edge(L, p):
    """1 on the cut edges round the front's window."""
    nb = L.nb
    return nb.mul(nb.inv(nb.ss(nb.absf(L.ny), 0.4, 0.6)),
                  nb.inv(nb.ss(L.y, -p["d"] / 2 + p["t"] + 0.0005, -p["d"] / 2 + p["t"] + 0.002)))


# --- the window box (Medium) ---------------------------------------------------------------------

WB = K.WINDOW_BOX
WBW = WB["window"]


def wb_box(hi):
    s = Shape()
    panels(s, WB, BOARD)
    tb = WB["tab"]
    # the hang tab standing up off the top's back edge, a fold line where it bends
    s.box((-tb["w"] / 2, WB["d"] / 2 - WB["t"], WB["h"] - 0.001),
          (tb["w"] / 2, WB["d"] / 2, WB["h"] + tb["h"]), BOARD, 0.002)
    return s


def wb_look(L, f):
    nb = L.nb
    w, d, h, win = WB["w"] / 2, WB["d"] / 2, WB["h"], WBW
    board = L.k(BOARD)
    above = nb.ss(L.z, h + 0.001, h + 0.004)     # the hang tab, printed both sides
    out = nb.mul(board, nb.mx(outward(L, (0.0, 0.0, h / 2)), above))
    inside = nb.mul(nb.mul(board, nb.inv(outward(L, (0.0, 0.0, h / 2)))), nb.inv(above))
    front = nb.mul(out, facing(L, L.ny, -1.0))
    ends = nb.mul(out, facing(L, nb.absf(L.nx), 1.0))
    back = nb.mul(out, facing(L, L.ny, 1.0))
    C = Coat(L, hexc("#D7CFBF"), 0.8)
    # outside: a strong red, a yellow keyline framing the window, a yellow foot under it, a white
    # burst on the header
    C.paint(out, hexc("#C3291F"), 0.42)
    x = w - win["side"]
    ring = nb.mul(rect(L, L.x, -x - 0.045, x + 0.045, L.z, win["z0"] - 0.045, win["z1"] + 0.045),
                  nb.inv(rect(L, L.x, -x - 0.022, x + 0.022, L.z, win["z0"] - 0.022, win["z1"] + 0.022)))
    C.paint(nb.mul(front, ring), hexc("#F5C21D"))
    C.paint(nb.mul(front, nb.inv(nb.ss(L.z, win["z0"] - 0.07, win["z0"] - 0.066))), hexc("#F5C21D"))
    C.paint(nb.mul(front, disc(L, L.x, 0.0, L.z, (win["z1"] + h) / 2 + 0.01, 0.075)), hexc("#FFF4DC"))
    C.paint(nb.mul(front, disc(L, L.x, 0.0, L.z, (win["z1"] + h) / 2 + 0.01, 0.05)), hexc("#C3291F"))
    # the ends: a big pale disc and a yellow band low down, the same print both sides
    C.paint(nb.mul(ends, disc(L, L.y, 0.0, L.z, h * 0.58, 0.27, 0.004)), hexc("#FFF0CF"))
    C.paint(nb.mul(ends, disc(L, L.y, 0.0, L.z, h * 0.58, 0.2, 0.004)), hexc("#F5C21D"))
    C.paint(nb.mul(ends, nb.band(L.z, 0.12, 0.2, 0.002)), hexc("#F5C21D"))
    # the back: cream board, a red strip and the bars
    C.paint(back, hexc("#E6DDC8"), 0.7)
    C.paint(nb.mul(back, nb.band(L.z, h - 0.12, h - 0.06, 0.002)), hexc("#C3291F"), 0.45)
    C.paint(nb.mul(back, barcode(L, nb.mul(L.x, -1.0), -0.3, L.z, 0.08, 0.12, 0.07)), hexc("#1E1C1A"))
    # the hang tab's hole, dark through it
    tb = WB["tab"]
    C.paint(nb.mul(board, disc(L, L.x, 0.0, L.z, h + tb["h"] * 0.58, tb["hole"], 0.002)),
            hexc("#1A1512"), 0.9)
    # inside: the printed backdrop, pale with soft orange rays rising from behind the find
    rays = nb.ss(nb.sin(nb.mul(nb.add(L.x, nb.mul(L.z, 0.6)), 26.0)), 0.2, 0.5)
    C.paint(inside, hexc("#F4E4A8"), 0.6)
    C.paint(nb.mul(inside, rays), hexc("#EFB55A"))
    C.paint(cut_edge(L, WB), hexc("#DAD3C3"), 0.85)
    C.enamel_wear(nb.mul(out, nb.inv(facing(L, L.nz, 1.0))), hexc("#E9DDC6"), s=5, amount=0.6)
    film_look(C, L, L.k(FILM), -0.1, 0.14, "#BDB8A6")
    C.finish(f.dust, grime=0.45)
    return C.surface(bump_dist=0.002, bump=0.3)


# --- the taped carton (Large) --------------------------------------------------------------------

CT = K.CARTON
CTT = CT["tape"]


def ct_carton(hi):
    s = Shape()
    panels(s, CT, KRAFT, top=False)
    w, d, h, t = CT["w"] / 2, CT["d"] / 2, CT["h"], CT["t"]
    # the two long top flaps meeting along the middle, a hair apart
    s.box((-w + t, -d + t, h - t), (w - t, -0.003, h), KRAFT, 0.002)
    s.box((-w + t, 0.003, h - t), (w - t, d - t, h), KRAFT, 0.002)
    # the tape: along the seam and down both ends
    tw, tt, dn = CTT["w"] / 2, CTT["t"], CTT["down"]
    s.box((-w - tt, -tw, h), (w + tt, tw, h + tt), TAPE)
    s.box((-w - tt, -tw, h - dn), (-w, tw, h), TAPE)
    s.box((w, -tw, h - dn), (w + tt, tw, h), TAPE)
    return s


def ct_look(L, f):
    nb = L.nb
    w, d, h, win = CT["w"] / 2, CT["d"] / 2, CT["h"], CT["window"]
    kraft = L.k(KRAFT)
    out = nb.mul(kraft, outward(L, (0.0, 0.0, h / 2)))
    inside = nb.mul(kraft, nb.inv(outward(L, (0.0, 0.0, h / 2))))
    front = nb.mul(out, facing(L, L.ny, -1.0))
    ends = nb.mul(out, facing(L, nb.absf(L.nx), 1.0))
    # kraft board: brown paper, mottled, the flutes under the liner just showing as ribs
    mottle = L.noise(9.0, 2, detail=5)
    ribs = nb.sin(nb.mul(nb.add(L.x, L.y), 260.0))
    C = Coat(L, nb.tint(hexc("#BC8C5C"), nb.mr(mottle, 0.3, 0.7, 0.9, 1.08)), 0.85, 0.0,
             nb.mul(ribs, 0.04))
    C.paint(inside, hexc("#A47A50"), 0.9)
    # the print: a pale band low on the front with two red stripes, a red keyline round the
    # window, a red ring on each end under its hand hole
    band = nb.band(L.z, 0.04, 0.15, 0.002)
    C.paint(nb.mul(front, band), hexc("#EFE6D2"), 0.7)
    for z in (0.07, 0.11):
        C.paint(nb.mul(front, nb.band(L.z, z, z + 0.018, 0.001)), hexc("#C2352A"), 0.6)
    x = w - win["side"]
    ring = nb.mul(rect(L, L.x, -x - 0.05, x + 0.05, L.z, win["z0"] - 0.05, win["z1"] + 0.05),
                  nb.inv(rect(L, L.x, -x - 0.032, x + 0.032, L.z, win["z0"] - 0.032, win["z1"] + 0.032)))
    C.paint(nb.mul(front, ring), hexc("#C2352A"), 0.6)
    stamp = nb.mul(disc(L, L.y, 0.0, L.z, 0.42, 0.2, 0.004),
                   nb.inv(disc(L, L.y, 0.0, L.z, 0.42, 0.165, 0.004)))
    C.paint(nb.mul(ends, stamp), hexc("#C2352A"), 0.6)
    # the hand holes: the cut flap pushed in, dark behind, a lighter cut rim round it
    hd = CT["hand"]
    C.paint(nb.mul(ends, disc(L, L.y, 0.0, L.z, hd["z"], 1.0, 0.02, hd["w"] / 2, hd["h"] / 2)),
            hexc("#D2AD80"), 0.9)
    C.paint(nb.mul(ends, disc(L, L.y, 0.0, L.z, hd["z"], 0.86, 0.02, hd["w"] / 2, hd["h"] / 2)),
            hexc("#20160F"), 0.95, height=-0.4)
    # the window's cut edge: the flutes' waves showing between the liners
    flutes = nb.ss(nb.sin(nb.mul(nb.add(L.x, L.z), 420.0)), -0.2, 0.4)
    edge = cut_edge(L, CT)
    C.paint(edge, hexc("#D6B07E"), 0.9)
    C.paint(nb.mul(edge, flutes), hexc("#8C6640"))
    # the flaps' seam, a dark hairline where the tape doesn't cover it
    C.paint(nb.mul(nb.mul(kraft, facing(L, L.nz, 1.0)), nb.band(L.y, -0.004, 0.004, 0.001)),
            hexc("#2A1D13"))
    C.enamel_wear(out, hexc("#D9B88C"), s=9, amount=0.8)
    # the tape: glossy tan, wrinkled where it was smoothed down by hand, lighter on its edges
    tape = L.k(TAPE)
    crinkle = L.noise(30.0, 6, stretch=(0.3, 1.0, 1.0), detail=4)
    C.paint(tape, nb.tint(hexc("#C99D57"), nb.mr(crinkle, 0.3, 0.7, 0.88, 1.08)), 0.22, 0.0,
            nb.mul(crinkle, 0.25))
    film_look(C, L, L.k(FILM), -0.4, 0.14, "#BDB8A6")
    C.finish(f.dust, grime=0.5)
    return C.surface(bump_dist=0.003, bump=0.4)


# --- the finds -----------------------------------------------------------------------------------

def _film_part(p):
    build, at = window_film(p)
    return build, at


WB_FILM, WB_FILM_AT = _film_part(WB)
CT_FILM, CT_FILM_AT = _film_part(CT)

BLISTER = kit.Find(
    "Blister",
    [kit.Part("Card", bl_card),
     kit.Part("Bubble", bl_bubble, (0.0, (B_FRONT + B_CARD) / 2, BB["z0"] + BB["h"] / 2), "Card",
              clear=True)],
    bl_look, dust=B["dust"], seed=B["seed"],
)

WINDOW_BOX = kit.Find(
    "WindowBox",
    [kit.Part("Box", wb_box),
     kit.Part("Film", WB_FILM, WB_FILM_AT, "Box", clear=True)],
    wb_look, dust=WB["dust"], seed=WB["seed"],
)

CARTON = kit.Find(
    "Carton",
    [kit.Part("Carton", ct_carton),
     kit.Part("Film", CT_FILM, CT_FILM_AT, "Carton", clear=True)],
    ct_look, dust=CT["dust"], seed=CT["seed"],
)

FINDS = [BLISTER, WINDOW_BOX, CARTON]
BY_KIND = {"Blister": BLISTER, "WindowBox": WINDOW_BOX, "Carton": CARTON}


# --- the game's fit data -------------------------------------------------------------------------

def write_fit():
    """src/shared/Finds/PackFit.luau: each pack's room for a find, in Roblox's axes."""
    path = os.path.join(kit.ROOT, "src", "shared", "Finds", "PackFit.luau")
    L = ["--!strict",
         "-- Generated by art/finds/packs/build.py (export) from art/finds/packs/spec.py: never edit",
         "-- by hand; change the spec and run `scripts/art.sh set packs export`. The packaging a",
         "-- sealed find still sits in (ROADMAP S5-02b), one per find size: its template in",
         "-- ReplicatedStorage.Props.Finds, the room inside it for a find (studs, Roblox axes, from",
         "-- the pack's pivot, the middle of its bottom), the gap kept round the find, and how far",
         "-- one axis may scale past another as the pack fits a find (spec.py's `fit`).",
         "",
         "export type Pack = {",
         "\ttemplate: string,",
         "\troom: Vector3,",
         "\troomCentre: Vector3,",
         "\tpad: number,",
         "\tstretch: number,",
         "}",
         "",
         "local PackFit: { [string]: Pack } = {"]
    for size, kind, p in K.PACKS:
        lo, hi = (Vector(v) for v in K.cavity(p, kind))
        L += [f"\t{size} = {{",
              f"\t\ttemplate = \"{kind}\",",
              f"\t\troom = {kit._v3(kit.extent(hi - lo))},",
              f"\t\troomCentre = {kit._v3(kit.to_roblox((lo + hi) / 2))},",
              f"\t\tpad = {p['pad']},",
              f"\t\tstretch = {p['stretch']},",
              "\t},"]
    L += ["}", "", "return PackFit", ""]
    with open(path, "w") as fh:
        fh.write("\n".join(L))
    print(f"SPEC {path}")


# --- the sheets: each pack round a real find -----------------------------------------------------

WINDUPS = os.path.join(HERE, "..", "windups")
SAMPLES = {"Blister": "RubberDuck", "WindowBox": "CymbalMonkey", "Carton": "SingingFish"}


def windups():
    """The windups set's finds, loaded beside this set (each set's build imports its own spec)."""
    mine = sys.modules.pop("spec")
    sys.path.insert(0, WINDUPS)
    try:
        sp = importlib.util.spec_from_file_location("windups_build", os.path.join(WINDUPS, "build.py"))
        mod = importlib.util.module_from_spec(sp)
        sp.loader.exec_module(mod)
    finally:
        sys.path.remove(WINDUPS)
        sys.modules["spec"] = mine
    return {f.name: f for f in mod.FINDS}


def rest_of(f):
    rest = {}
    for part, ch, ks in [t for a in f.motions for t in kit.tracks(f, a)[1]]:
        rest.setdefault((part, ch), ks[0][1])
    return rest


def packed(kind, p, find, coll, M):
    """The pack `kind` fitted round `find` as the game fits it, the pair placed by M; returns
    every object and the pack's outer size."""
    fobjs = kit.load_low(find, WINDUPS, coll)
    kit.wear(find, WINDUPS, fobjs, preview=True)
    kit.place(find, fobjs, Matrix(), coll, rest_of(find), lights=False)
    c, size = kit.frame_find(find, fobjs)
    lo, hi = (Vector(v) for v in K.cavity(p, kind))
    room = hi - lo
    sc = K.fit(tuple(size), tuple(room), p["pad"], p["stretch"])
    S = Matrix.Diagonal((*sc, 1.0))
    pack = BY_KIND[kind]
    pobjs = kit.load_low(pack, HERE, coll)
    kit.wear(pack, HERE, pobjs, preview=True)
    kit.place(pack, pobjs, M @ S, coll, {}, lights=False)
    at = S @ ((lo + hi) / 2)
    for ob in fobjs.values():
        ob.matrix_world = M @ Matrix.Translation(at - c) @ ob.matrix_world
    outer = Vector((p.get("w", 0.0), p.get("d", B_D), p.get("h", 0.0)))
    outer = Vector((outer.x * sc[0], outer.y * sc[1], outer.z * sc[2]))
    return list(fobjs.values()) + list(pobjs.values()), outer


def stage_sheets(quick=False):
    S = 48 if quick else 128
    sheet = lambda k: os.path.join(kit.SHEETS, f"packs-{k}.png")  # noqa: E731
    tmp = os.path.join(HERE, "out", "frames")
    os.makedirs(tmp, exist_ok=True)
    finds = windups()

    def scene(res):
        kit.reset()
        render.setup(S, res)
        return bpy.context.scene.collection

    # 1. the studio: the three side by side, front three quarters
    coll = scene((1600, 900))
    kit.studio(coll)
    xs = {"Blister": -1.55, "WindowBox": -0.55, "Carton": 1.05}
    for size, kind, p in K.PACKS:
        packed(kind, p, finds[SAMPLES[kind]], coll, Matrix.Translation((xs[kind], 0.0, 0.0)))
    c = Vector((-0.2, 0.0, 0.62))
    cam = render.camera(c + Vector((-1.2, -4.4, 1.2)), c, lens=50)
    kit.shoot(cam, sheet("studio"), (1600, 900), S)

    # 2. held, first person on a phone, each in your hands as a find is held (kit's held sheet)
    frames = []
    for size, kind, p in K.PACKS:
        coll = scene((844, 390))
        kit.studio(coll)
        objs, outer = packed(kind, p, finds[SAMPLES[kind]], coll, Matrix())
        c = Vector((0.0, 0.0, outer.z / 2))
        d = max(outer)
        eye = Vector((0.0, 1.6, 4.6))
        fwd = Vector((0.0, math.cos(math.radians(10)), -math.sin(math.radians(10))))
        right, up = Vector((1.0, 0.0, 0.0)), fwd.cross(Vector((1.0, 0.0, 0.0))) * -1.0
        reach = max(kit.HOLD[2], 0.6 + 0.9 * d)
        at = eye + right * kit.HOLD[0] + up * kit.HOLD[1] + fwd * reach
        M = (Matrix.Translation(at) @ Matrix.Rotation(math.radians(kit.HOLD_TURN), 4, "Z")
             @ Matrix.Translation(-c))
        for ob in objs:
            ob.matrix_world = M @ ob.matrix_world
        cam = render.camera(eye, eye + fwd, lens=12)
        out = os.path.join(tmp, f"held-{kind}.png")
        kit.shoot(cam, out, (844, 390), S)
        frames.append(out)
    kit.ffmpeg(*sum((["-i", fr] for fr in frames), []), "-filter_complex",
               f"vstack=inputs={len(frames)}", sheet("held"))

    # 3. a unit's floor from its doorway on a phone: the three set down where a box would stand
    coll = scene((844, 390))
    kit.unit_room(coll)
    # deeper than the bulb, as every find's doorway sheet stands it (CRAFT.md)
    spots = {"Blister": (-1.5, 6.0, 0.0), "WindowBox": (0.0, 6.3, 0.0), "Carton": (1.9, 6.8, 0.0)}
    turns = {"Blister": 12.0, "WindowBox": -8.0, "Carton": -18.0}
    for size, kind, p in K.PACKS:
        M = Matrix.Translation(spots[kind]) @ Matrix.Rotation(math.radians(turns[kind]), 4, "Z")
        packed(kind, p, finds[SAMPLES[kind]], coll, M)
    eye = Vector((0.0, -1.2, 4.6))
    cam = render.camera(eye, Vector((0.2, 6.2, 0.6)), lens=12)
    kit.shoot(cam, sheet("unit"), (844, 390), S)
    print(f"RENDERED {sheet('studio')} {sheet('held')} {sheet('unit')}")


if __name__ == "__main__":
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    if "sheets" in argv:
        stage_sheets(quick="--quick" in argv)
    else:
        kit.main("Packs", HERE, FINDS)
        if "export" in argv:
            write_fit()
