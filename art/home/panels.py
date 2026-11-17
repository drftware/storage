"""The home's wall and floor panels and a swatch of each look's set (S5-03g2a, D-325).

What a home's looks land on (idea 18: the paint or paper you pick, the floor you lay). The lobby's
unit walls and floor are merged meshes the game can't repaint one home at a time, so each home
gets its own panels a hair proud of them (PANEL_PROUD), the lobby's walls staying under:

    PanelFloor   Wood     the floor inside the walls, from the front wall to the back
    PanelLeft    Plaster  the left partition as you walk in (-x)
    PanelBack    Plaster  the back wall
    PanelRight   Plaster  the right partition (+x)
    PanelFront   Plaster  the front wall's inside, round the doorway

Each panel's UVs are in studs over its set's tile (home_spec FLOOR_TILE, PAPER_TILE), so any floor
set or paper wears it at its true size. A paper's rows run level all round the room (V is the
height over the tile) and its pattern carries round both back corners (U runs on round the room
from the back wall's middle); the floor's start square at the back wall and the room's middle, so
boards run from the door to the back wall. Each panel is its own part on its own origin, its
middle, its face toward -y; `placements` gives where it stands in the unit's frame and its turn.
Sized for the XL slot (S5-03h moves them).

    Swatch<Set>  a 2-stud square of each floor and paper set, half a tile on its face, so the
                 set's SurfaceAppearance reaches Studio: game scripts can't write a
                 SurfaceAppearance's maps, so the game clones a swatch's onto a panel
"""

import math

from mathutils import Matrix

import geo
from geo import Mesh
import home_spec as K


def room(s):
    """The unit's inside faces in its frame: the partitions' x, the front wall's inside y (the
    FacadeBack's face, front.py), the back wall's y, the walls' height."""
    w2 = K.SLOT[0] / 2 - K.PARTITION / 2
    return -w2, w2, s.facade + 0.04, K.SLOT[1] - K.PARTITION / 2, s.wall_height


def placements(s):
    """Each panel: (part, middle in the unit frame, turn about z in degrees: its face from -y)."""
    x0, x1, y0, y1, h = room(s)
    p = K.PANEL_PROUD
    xm, ym = (x0 + x1) / 2, (y0 + y1) / 2
    return (("PanelFloor", (xm, ym, p / 2), 0.0),
            ("PanelLeft", (x0 + p / 2, ym, h / 2), 90.0),
            ("PanelBack", (xm, y1 - p / 2, h / 2), 0.0),
            ("PanelRight", (x1 - p / 2, ym, h / 2), -90.0),
            ("PanelFront", (xm, y0 + p / 2, h / 2), 180.0))


def around(s):
    """How far round the room a point on each wall is (studs), from the back wall's middle and
    rightward as you face that wall, so a paper carries on round the back corners."""
    x0, x1, y0, y1, _ = room(s)
    return {"PanelBack": lambda v: v.x,
            "PanelRight": lambda v: x1 + (y1 - v.y),
            "PanelLeft": lambda v: x0 - (y1 - v.y),
            "PanelFront": lambda v: x1 + (y1 - y0) + (x1 - v.x)}


def boxes(s, name):
    """A panel's boxes in the unit frame."""
    x0, x1, y0, y1, h = room(s)
    p = K.PANEL_PROUD
    if name == "PanelFloor":
        return [((x0, y0, 0.0), (x1, y1, p))]
    if name == "PanelBack":
        return [((x0, y1 - p, 0.0), (x1, y1, h))]
    if name == "PanelLeft":   # between the front and back panels' faces, so no faces overlap
        return [((x0, y0 + p, 0.0), (x0 + p, y1 - p, h))]
    if name == "PanelRight":
        return [((x1 - p, y0 + p, 0.0), (x1, y1 - p, h))]
    o, top = s.door_width / 2 + K.LINER, s.door_height + K.LINER  # the doorway, as FacadeBack's
    return [((x0, y0, 0.0), (-o, y0 + p, h)), ((o, y0, 0.0), (x1, y0 + p, h)),
            ((-o, y0, top), (o, y0 + p, h))]


def panel(s, name, middle, turn):
    """One panel on its own origin, UVs taken where it stands in the unit frame."""
    _, _, _, y1, _ = room(s)
    if name == "PanelFloor":
        t = K.FLOOR_TILE
        uv = lambda vs, n: [(v.x / t, (v.y - y1) / t) for v in vs]
    else:
        t, u = K.PAPER_TILE, around(s)[name]
        uv = lambda vs, n: [(u(v) / t, v.z / t) for v in vs]
    placed = Mesh(name)
    for lo, hi in boxes(s, name):
        geo.box(placed, lo, hi, uv)
    m = Mesh(name)
    at = Matrix.Translation(middle) @ Matrix.Rotation(math.radians(turn), 4, "Z")
    m.extend(placed, at.inverted())
    return m


def swatch(set_name, tile):
    """A square of a set standing on its middle, its face toward -y showing half a tile."""
    a, t = K.SWATCH
    m = Mesh(f"Swatch{set_name}")
    geo.box(m, (-a / 2, -t / 2, -a / 2), (a / 2, t / 2, a / 2),
            lambda vs, n: [((v.x / a + 0.5) / 2, (v.z / a + 0.5) / 2) for v in vs])
    return m


def swatch_sets():
    """Every floor's and paper's set, once, in the looks' order, with its tile."""
    out = {}
    for _, set_name, _ in K.FLOORS:
        out.setdefault(set_name, K.FLOOR_TILE)
    for _, set_name in K.PAPERS:
        out.setdefault(set_name, K.PAPER_TILE)
    return out


def meshes(s):
    out = {name: panel(s, name, at, turn) for name, at, turn in placements(s)}
    out.update({f"Swatch{n}": swatch(n, t) for n, t in swatch_sets().items()})
    return out


def texsets():
    out = {name: "Plaster" for name in ("PanelLeft", "PanelBack", "PanelRight", "PanelFront")}
    out["PanelFloor"] = "Wood"
    out.update({f"Swatch{n}": n for n in swatch_sets()})
    return out
